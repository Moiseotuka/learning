import { randomUUID } from "node:crypto";

import { getInstructorPlan, type InstructorPlan } from "@/lib/instructor/plans";
import {
  CHECKOUT_CURRENCY,
  absoluteUrl,
  activePaymentProvider,
  amountMatches,
  createNyoleSession,
  getNyoleSessionStatus,
} from "@/lib/payments/nyole";
import { createServiceSupabase } from "@/lib/supabase/service";

type Client = NonNullable<ReturnType<typeof createServiceSupabase>>;

export type InstructorSubscriptionRow = {
  id: string;
  user_id: string;
  plan_id: string;
  status: string;
  amount_fc: number;
  currency: string | null;
  provider: string | null;
  provider_reference: string | null;
  seats_limit: number;
  track_limit: number;
  started_at: string | null;
  expires_at: string | null;
};

export type InstructorCheckout =
  | {
      mode: "dialog";
      url: string;
      sessionId: string;
      subscriptionId: string;
      redirect: string;
    }
  | { mode: "redirect"; redirect: string }
  | { mode: "error"; reason: string };

const DAY_MS = 86_400_000;

/**
 * Souscription à un abonnement formateur.
 *
 * Le parcours est volontairement le même que l'achat d'un niveau : session nyole
 * créée côté serveur, page de paiement dans le dialogue, confirmation par
 * sondage ou webhook. Un formateur ne doit pas avoir deux caisses différentes.
 */
export async function startInstructorSubscription(input: {
  userId: string;
  email: string | null;
  planId: string;
  trackIds: string[];
}): Promise<InstructorCheckout> {
  const supabase = createServiceSupabase();
  if (!supabase) return { mode: "error", reason: "not-configured" };

  const plan = await getInstructorPlan(input.planId);
  if (!plan) return { mode: "error", reason: "no-plan" };

  const trackIds = [...new Set(input.trackIds)].filter(Boolean);
  if (trackIds.length === 0) return { mode: "error", reason: "no-track" };
  if (trackIds.length > plan.trackLimit) {
    return { mode: "error", reason: "too-many-tracks" };
  }

  const { data: published } = await supabase
    .from("tracks")
    .select("id")
    .in("id", trackIds)
    .eq("published", true);
  if ((published as { id: string }[] | null)?.length !== trackIds.length) {
    return { mode: "error", reason: "unknown-track" };
  }

  // Un renouvellement avant échéance ne fait pas perdre les jours déjà payés :
  // la nouvelle période démarre à la fin de l'abonnement en cours (activate()).
  const subscriptionId = randomUUID();

  const { error: insertError } = await supabase
    .from("instructor_subscriptions")
    .insert({
      id: subscriptionId,
      user_id: input.userId,
      plan_id: plan.id,
      status: "pending",
      amount_fc: plan.priceFc,
      currency: CHECKOUT_CURRENCY,
      provider: activePaymentProvider(),
      seats_limit: plan.seatsLimit,
      track_limit: plan.trackLimit,
    });
  if (insertError) return { mode: "error", reason: "failed" };

  const { error: tracksError } = await supabase
    .from("instructor_subscription_tracks")
    .insert(trackIds.map((trackId) => ({ subscription_id: subscriptionId, track_id: trackId })));
  if (tracksError) {
    await supabase.from("instructor_subscriptions").delete().eq("id", subscriptionId);
    return { mode: "error", reason: "failed" };
  }

  if (activePaymentProvider() === "mock") {
    const settled = await settleInstructorSubscription(supabase, {
      subscriptionId,
      provider: "mock",
    });
    if (!settled.ok) return { mode: "error", reason: settled.reason ?? "failed" };
    return { mode: "redirect", redirect: "/app/formateur?notice=actif" };
  }

  const session = await createNyoleSession({
    amount: plan.priceFc,
    currency: CHECKOUT_CURRENCY,
    description: `easyTech — abonnement formateur (${plan.label})`,
    customerEmail: input.email,
    successUrl: absoluteUrl(`/paiement/retour?ref=${subscriptionId}&kind=formateur`),
    cancelUrl: absoluteUrl(
      `/paiement/retour?ref=${subscriptionId}&kind=formateur&cancelled=1`,
    ),
    metadata: {
      subscription_id: subscriptionId,
      user_id: input.userId,
      plan_id: plan.id,
    },
    idempotencyKey: `${subscriptionId}:${Date.now()}`,
  });

  if (!session.ok) return { mode: "error", reason: session.reason };

  const { error: refError } = await supabase
    .from("instructor_subscriptions")
    .update({ provider_reference: session.session.id })
    .eq("id", subscriptionId);
  if (refError) return { mode: "error", reason: "failed" };

  return {
    mode: "dialog",
    url: session.session.url,
    sessionId: session.session.id,
    subscriptionId,
    redirect: "/app/formateur?notice=actif",
  };
}

async function activeSubscriptionOf(
  supabase: Client,
  userId: string,
): Promise<InstructorSubscriptionRow | null> {
  const { data } = await supabase
    .from("instructor_subscriptions")
    .select(
      "id,user_id,plan_id,status,amount_fc,currency,provider,provider_reference,seats_limit,track_limit,started_at,expires_at",
    )
    .eq("user_id", userId)
    .eq("status", "active")
    .gt("expires_at", new Date().toISOString())
    .order("expires_at", { ascending: false })
    .limit(1)
    .maybeSingle<InstructorSubscriptionRow>();
  return data ?? null;
}

export type SettleResult = {
  ok: boolean;
  paid: boolean;
  status: string;
  reason?: string;
  expiresAt?: string | null;
};

/**
 * Vérifie et applique le paiement d'une souscription (idempotent).
 * Source de vérité : le statut renvoyé par nyole, jamais un message du client.
 * Un renouvellement souscrit avant l'échéance démarre à la date d'expiration en
 * cours : aucun jour payé n'est perdu.
 */
export async function settleInstructorSubscription(
  supabase: Client | null,
  input: {
    subscriptionId?: string;
    reference?: string;
    provider?: "mock" | "nyole";
    /** Quand un utilisateur est connecté, sa souscription est la seule traitable. */
    expectUserId?: string;
  },
): Promise<SettleResult> {
  const client = supabase ?? createServiceSupabase();
  if (!client) return { ok: false, paid: false, status: "PENDING", reason: "not-configured" };

  let query = client
    .from("instructor_subscriptions")
    .select(
      "id,user_id,plan_id,status,amount_fc,currency,provider,provider_reference,seats_limit,track_limit,started_at,expires_at",
    );
  query = input.subscriptionId
    ? query.eq("id", input.subscriptionId)
    : query.eq("provider_reference", input.reference ?? "");

  const { data, error } = await query.maybeSingle<InstructorSubscriptionRow>();
  if (error) return { ok: false, paid: false, status: "PENDING", reason: error.message };
  if (!data) return { ok: false, paid: false, status: "PENDING", reason: "unknown" };
  if (input.expectUserId && data.user_id !== input.expectUserId) {
    return { ok: false, paid: false, status: "PENDING", reason: "unknown" };
  }

  if (data.status === "active" && data.expires_at && new Date(data.expires_at) > new Date()) {
    return { ok: true, paid: true, status: "SUCCESS", expiresAt: data.expires_at };
  }

  if (input.provider === "mock" || data.provider === "mock") {
    return activate(client, data);
  }

  if (data.provider !== "nyole" || !data.provider_reference) {
    return { ok: true, paid: false, status: "PENDING" };
  }

  const result = await getNyoleSessionStatus(data.provider_reference);
  if (!result.ok) {
    return { ok: true, paid: false, status: "PENDING", reason: result.reason };
  }
  if (!result.status.paid) {
    return { ok: true, paid: false, status: result.status.status };
  }
  if (!amountMatches(data.amount_fc, result.status, CHECKOUT_CURRENCY)) {
    console.warn(
      "[formateur] montant incohérent —",
      JSON.stringify({
        subscriptionId: data.id,
        expected: data.amount_fc,
        currency: result.status.currency,
        amount: result.status.amount,
      }),
    );
    return { ok: false, paid: false, status: result.status.status, reason: "amount-mismatch" };
  }

  return activate(client, data);
}

/**
 * Bascule la souscription en actif pour la durée du barème, en repoussant
 * l'échéance existante plutôt qu'en la remplaçant.
 *
 * Idempotent par construction : `payment_events` porte la clé unique, et un
 * évènement déjà appliqué ne prolonge jamais une deuxième fois — sans ce garde,
 * deux sondes simultanées du dialogue offriraient deux périodes pour un paiement.
 */
async function activate(
  supabase: Client,
  subscription: InstructorSubscriptionRow,
): Promise<SettleResult> {
  const isNyole = subscription.provider === "nyole" && Boolean(subscription.provider_reference);
  const eventId = isNyole
    ? `nyole:${subscription.provider_reference}`
    : `mock:${subscription.id}`;

  const { error: eventError } = await supabase.from("payment_events").insert({
    event_id: eventId,
    provider: isNyole ? "nyole" : "mock",
    payload: {
      reference: subscription.provider_reference,
      subscription_id: subscription.id,
      kind: "instructor",
    },
  });

  if (eventError && eventError.code !== "23505") {
    return { ok: false, paid: false, status: "PENDING", reason: eventError.message };
  }

  if (eventError) {
    const { data: prior } = await supabase
      .from("payment_events")
      .select("processed_at")
      .eq("event_id", eventId)
      .maybeSingle<{ processed_at: string | null }>();

    if (prior?.processed_at) {
      return {
        ok: true,
        paid: true,
        status: "SUCCESS",
        expiresAt: subscription.expires_at,
      };
    }
  }

  const plan = await getInstructorPlan(subscription.plan_id);
  const durationDays = plan?.durationDays ?? 30;

  const running = await activeSubscriptionOf(supabase, subscription.user_id);
  const runningEnd = running?.expires_at ? new Date(running.expires_at) : null;
  const start = runningEnd && runningEnd > new Date() ? runningEnd : new Date();
  const expiresAt = new Date(start.getTime() + durationDays * DAY_MS);

  const { error } = await supabase
    .from("instructor_subscriptions")
    .update({
      status: "active",
      started_at: running?.started_at ?? start.toISOString(),
      expires_at: expiresAt.toISOString(),
      paid_at: new Date().toISOString(),
    })
    .eq("id", subscription.id);

  if (error) return { ok: false, paid: false, status: "PENDING", reason: error.message };

  // L'abonnement précédent ferme : la place des élèves doit être comptée sur la
  // période en cours, pas additionnée aux périodes déjà soldées.
  if (running && running.id !== subscription.id) {
    await supabase
      .from("instructor_subscriptions")
      .update({ status: "expired" })
      .eq("id", running.id);
  }

  await supabase
    .from("payment_events")
    .update({ processed_at: new Date().toISOString() })
    .eq("event_id", eventId);

  return { ok: true, paid: true, status: "SUCCESS", expiresAt: expiresAt.toISOString() };
}

/** Barème de référence pour l'affichage du prix mensuel (plan d'un mois). */
export function basePlan(plans: InstructorPlan[]): InstructorPlan | undefined {
  return plans.find((plan) => plan.durationDays <= 31) ?? plans[0];
}
