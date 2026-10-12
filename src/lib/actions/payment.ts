"use server";

import { randomUUID } from "node:crypto";

import { requireUser } from "@/lib/auth/dal";
import { levelHasContent } from "@/lib/payments/availability";
import {
  CHECKOUT_CURRENCY,
  absoluteUrl,
  activePaymentProvider,
  amountMatches,
  createNyoleSession,
  getNyoleSessionStatus,
  nyoleCheckoutUrl,
} from "@/lib/payments/nyole";
import { processPaymentEvent } from "@/lib/payments/processor";
import { trackNoticeUrl } from "@/lib/payments/notice";
import { createServiceSupabase } from "@/lib/supabase/service";

export type CheckoutResult =
  /** Simulation locale : redirection immédiate (ancien comportement). */
  | { mode: "redirect"; redirect: string }
  /**
   * nyole : la session est créée côté serveur, le client ouvre la page de
   * paiement dans une boîte de dialogue — l'apprenant ne quitte jamais le site.
   */
  | {
      mode: "dialog";
      url: string;
      sessionId: string;
      purchaseId: string;
      redirect: string;
    }
  | { mode: "error"; reason: string };

type PurchaseRow = {
  id: string;
  status: string;
  provider: string | null;
  provider_reference: string | null;
  amount_usd: number | null;
};

type ServerSupabase = NonNullable<ReturnType<typeof createServiceSupabase>>;

async function priceOf(
  supabase: ServerSupabase,
  categoryId: string,
  level: string,
): Promise<number | null> {
  const { data } = await supabase
    .from("category_level_prices")
    .select("price_usd")
    .eq("category_id", categoryId)
    .eq("level", level)
    .maybeSingle<{ price_usd: number }>();
  return data?.price_usd ?? null;
}

async function findPurchase(
  supabase: ServerSupabase,
  userId: string,
  categoryId: string,
  level: string,
): Promise<PurchaseRow | null> {
  const { data } = await supabase
    .from("purchases")
    .select("id,status,provider,provider_reference,amount_usd")
    .eq("user_id", userId)
    .eq("category_id", categoryId)
    .eq("level", level)
    .maybeSingle<PurchaseRow>();
  return data ?? null;
}

/**
 * Démarre le paiement d'un niveau.
 * - `PAYMENT_PROVIDER=mock` : paiement simulé immédiat (tests, démo).
 * - `PAYMENT_PROVIDER=nyole` : session nyole créée ici (clé secrète serveur),
 *   le client ouvre l'URL de paiement dans un dialogue et reste sur le site.
 */
export async function startCheckout(
  _prevState: CheckoutResult | undefined,
  formData: FormData,
): Promise<CheckoutResult> {
  try {
    return await runCheckout(formData);
  } catch (error) {
    const digest = (error as { digest?: string } | null)?.digest;
    if (typeof digest === "string" && digest.startsWith("NEXT_REDIRECT")) {
      throw error;
    }
    console.error("[payment] checkout", error);
    return { mode: "error", reason: "failed" };
  }
}

async function runCheckout(formData: FormData): Promise<CheckoutResult> {
  const user = await requireUser("/app");

  const categoryId = String(formData.get("categoryId") ?? "").trim();
  const level = String(formData.get("level") ?? "").trim();
  if (!categoryId || !level || level === "debutant") {
    return { mode: "error", reason: "missing" };
  }

  const supabase = createServiceSupabase();
  if (!supabase) return { mode: "error", reason: "not-configured" };

  const price = await priceOf(supabase, categoryId, level);
  if (price === null) return { mode: "error", reason: "no-price" };

  const notice = await trackNoticeUrl(supabase, categoryId);
  const existing = await findPurchase(supabase, user.id, categoryId, level);

  if (existing?.status === "paid") {
    return { mode: "redirect", redirect: notice };
  }

  if (!(await levelHasContent(categoryId, level, supabase))) {
    return { mode: "error", reason: "no-content" };
  }

  if (activePaymentProvider() === "mock") {
    return runMockCheckout(supabase, user.id, categoryId, level, price, existing);
  }

  return runNyoleCheckout(
    supabase,
    user.id,
    categoryId,
    level,
    price,
    user.email ?? null,
    existing,
    notice,
  );
}

/**
 * Simulation : la purchase passe directement à `paid` (comme le ferait le
 * webhook nyole) puis l'apprenant est redirigé vers le parcours.
 */
async function runMockCheckout(
  supabase: ServerSupabase,
  userId: string,
  categoryId: string,
  level: string,
  price: number,
  existing: PurchaseRow | null,
): Promise<CheckoutResult> {
  const reference = existing?.provider_reference ?? `mock_${randomUUID()}`;

  if (existing) {
    const { error } = await supabase
      .from("purchases")
      .update({
        amount_usd: price,
        currency: CHECKOUT_CURRENCY,
        provider: "mock",
        provider_reference: reference,
        status: "pending",
      })
      .eq("id", existing.id);
    if (error) return { mode: "error", reason: "failed" };
  } else {
    const { error } = await supabase.from("purchases").insert({
      user_id: userId,
      category_id: categoryId,
      level,
      amount_usd: price,
      currency: CHECKOUT_CURRENCY,
      provider: "mock",
      provider_reference: reference,
      status: "pending",
    });
    if (error) return { mode: "error", reason: "failed" };
  }

  const processed = await processPaymentEvent({
    eventId: `mock:${reference}:${Date.now()}`,
    provider: "mock",
    reference,
    payload: { amount_usd: price, level, category_id: categoryId },
  });
  if (!processed.ok) return { mode: "error", reason: "failed" };

  return { mode: "redirect", redirect: await trackNoticeUrl(supabase, categoryId) };
}

/**
 * nyole : (ré)utilise la session de la purchase, sinon en crée une nouvelle.
 * La purchase reste `pending` : seul le webhook ou la vérification de statut
 * (retour / dialogue) la passe à `paid`.
 */
async function runNyoleCheckout(
  supabase: ServerSupabase,
  userId: string,
  categoryId: string,
  level: string,
  price: number,
  email: string | null,
  existing: PurchaseRow | null,
  notice: string,
): Promise<CheckoutResult> {
  // Achat déjà en attente : on réutilise la session tant qu'elle est payable
  // (PENDING) ET facturée au prix actuel. Une session créée avant un
  // changement de tarif est remplacée, sinon la page nyole afficherait
  // l'ancien montant. Une session échouée ou annulée l'est aussi.
  if (existing?.provider_reference && existing.provider === "nyole") {
    const status = await getNyoleSessionStatus(existing.provider_reference);

    if (
      status.ok &&
      status.status.paid &&
      amountMatches(price, status.status)
    ) {
      const processed = await processPaymentEvent({
        eventId: `nyole:${existing.provider_reference}`,
        provider: "nyole",
        reference: existing.provider_reference,
        purchaseId: existing.id,
      });
      if (processed.ok) return { mode: "redirect", redirect: notice };
    }

    if (
      status.ok &&
      status.status.status === "PENDING" &&
      amountMatches(price, status.status)
    ) {
      return {
        mode: "dialog",
        url: nyoleCheckoutUrl(existing.provider_reference),
        sessionId: existing.provider_reference,
        purchaseId: existing.id,
        redirect: notice,
      };
    }
  }

  const purchaseId = existing?.id ?? randomUUID();

  if (!existing) {
    const { error } = await supabase.from("purchases").insert({
      id: purchaseId,
      user_id: userId,
      category_id: categoryId,
      level,
      amount_usd: price,
      currency: CHECKOUT_CURRENCY,
      provider: "nyole",
      status: "pending",
    });
    if (error) return { mode: "error", reason: "failed" };
  } else {
    const { error } = await supabase
      .from("purchases")
      .update({
        amount_usd: price,
        currency: CHECKOUT_CURRENCY,
        provider: "nyole",
        status: "pending",
      })
      .eq("id", existing.id);
    if (error) return { mode: "error", reason: "failed" };
  }

  const session = await createNyoleSession({
    // nyole attend l'unité principale de la devise : 28000 pour 28 000 CDF.
    amount: price,
    currency: CHECKOUT_CURRENCY,
    description: `easyLearn — niveau ${level} (${categoryId})`,
    customerEmail: email,
    successUrl: absoluteUrl(`/paiement/retour?ref=${purchaseId}`),
    cancelUrl: absoluteUrl(`/paiement/retour?ref=${purchaseId}&cancelled=1`),
    metadata: {
      purchase_id: purchaseId,
      user_id: userId,
      category_id: categoryId,
      level,
    },
    idempotencyKey: `${purchaseId}:${Date.now()}`,
  });

  if (!session.ok) {
    return { mode: "error", reason: session.reason };
  }

  const { error } = await supabase
    .from("purchases")
    .update({ provider_reference: session.session.id })
    .eq("id", purchaseId);
  if (error) return { mode: "error", reason: "failed" };

  return {
    mode: "dialog",
    url: session.session.url,
    sessionId: session.session.id,
    purchaseId,
    redirect: notice,
  };
}
