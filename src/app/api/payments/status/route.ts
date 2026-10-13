import {
  CHECKOUT_CURRENCY,
  amountMatches,
  getNyoleSessionStatus,
} from "@/lib/payments/nyole";
import { trackNoticeUrl } from "@/lib/payments/notice";
import { processPaymentEvent } from "@/lib/payments/processor";
import { settleInstructorSubscription } from "@/lib/instructor/checkout";
import { createServerSupabase } from "@/lib/supabase/server";
import { createServiceSupabase } from "@/lib/supabase/service";

type PurchaseRow = {
  id: string;
  user_id: string;
  category_id: string;
  status: string;
  provider: string | null;
  provider_reference: string | null;
  amount_usd: number | null;
  currency: string | null;
};

/**
 * Statut d'un achat pour l'apprenant (dialogue de paiement).
 * Chemin principal de confirmation côté client : la page de paiement reste
 * dans une iframe, l'onglet parent sonde cette route ; le webhook nyole
 * confirme de toute façon de façon asynchrone.
 * Contrôle : session authentifiée + achat appartenant à l'apprenant +
 * statut nyole + montant/devise. Idempotent (processPaymentEvent).
 */
export async function GET(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const purchaseId = url.searchParams.get("purchase") ?? "";
  const subscriptionId = url.searchParams.get("subscription") ?? "";
  if (!purchaseId && !subscriptionId) {
    return Response.json(
      { ok: false, reason: "missing" },
      { status: 400 },
    );
  }

  const auth = await createServerSupabase();
  const user = auth
    ? (await auth.auth.getUser()).data.user ?? null
    : null;
  if (!user) {
    return Response.json(
      { ok: false, reason: "unauthenticated" },
      { status: 401 },
    );
  }

  const supabase = createServiceSupabase();
  if (!supabase) {
    return Response.json(
      { ok: false, reason: "not-configured" },
      { status: 503 },
    );
  }

  // Abonnement formateur : même dialogue, même sondage, table séparée.
  if (subscriptionId) {
    const settled = await settleInstructorSubscription(supabase, {
      subscriptionId,
      expectUserId: user.id,
    });
    return Response.json(
      settled.ok && settled.paid
        ? {
            ok: true,
            paid: true,
            status: "SUCCESS",
            redirect: "/app/formateur?notice=actif",
          }
        : {
            ok: settled.ok,
            paid: false,
            status: settled.status,
            reason: settled.reason,
          },
    );
  }

  const { data: purchase } = await supabase
    .from("purchases")
    .select(
      "id,user_id,category_id,status,provider,provider_reference,amount_usd,currency",
    )
    .eq("id", purchaseId)
    .maybeSingle<PurchaseRow>();

  if (!purchase || purchase.user_id !== user.id) {
    return Response.json(
      { ok: false, reason: "unknown" },
      { status: 404 },
    );
  }

  const redirect = () => trackNoticeUrl(supabase, purchase.category_id);

  if (purchase.status === "paid") {
    return Response.json({
      ok: true,
      paid: true,
      status: "SUCCESS",
      redirect: await redirect(),
    });
  }

  if (purchase.provider !== "nyole" || !purchase.provider_reference) {
    return Response.json({ ok: true, paid: false, status: "PENDING" });
  }

  const result = await getNyoleSessionStatus(purchase.provider_reference);
  if (!result.ok) {
    console.warn(
      "[paiement] statut : nyole injoignable",
      result.reason,
      purchase.provider_reference,
    );
    return Response.json({ ok: true, paid: false, status: "PENDING" });
  }

  const info = result.status;
  if (!info.paid) {
    return Response.json({ ok: true, paid: false, status: info.status });
  }

  if (!amountMatches(purchase.amount_usd, info, CHECKOUT_CURRENCY)) {
    console.warn(
      "[paiement] statut : montant incohérent —",
      JSON.stringify({
        purchaseId: purchase.id,
        expectedUsd: purchase.amount_usd,
        currency: info.currency,
        amount: info.amount,
      }),
    );
    return Response.json({
      ok: true,
      paid: false,
      status: info.status,
      reason: "amount-mismatch",
    });
  }

  const processed = await processPaymentEvent({
    eventId: `nyole:${purchase.provider_reference}`,
    provider: "nyole",
    reference: purchase.provider_reference,
    purchaseId: purchase.id,
    payload: { source: "status" },
  });

  if (!processed.ok) {
    console.warn(
      "[paiement] statut : validation impossible",
      processed.reason,
    );
    return Response.json({ ok: true, paid: false, status: info.status });
  }

  return Response.json({
    ok: true,
    paid: true,
    status: "SUCCESS",
    redirect: await redirect(),
  });
}
