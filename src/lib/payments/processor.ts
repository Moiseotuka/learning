import { createServiceSupabase } from "@/lib/supabase/service";

export type PaymentProviderName = "mock" | "nyole";

export type PaymentEventInput = {
  /** Identifiant unique de l'évènement (déduplication). */
  eventId: string;
  provider: PaymentProviderName;
  /** provider_reference de la purchase concernée. */
  reference: string;
  /**
   * Recherche prioritaire de la purchase par identifiant (métadonnées nyole),
   * plus robuste que la référence si une nouvelle session a été créée entre
   *temps. La signature du webhook garantit que ce vient de nyole.
   */
  purchaseId?: string;
  payload?: Record<string, unknown>;
};

export type ProcessResult = {
  ok: boolean;
  duplicate?: boolean;
  reason?: string;
};

/**
 * Applique un évènement de paiement de façon idempotente :
 * 1. insert payment_events (conflit = évènement déjà traité → duplicate) ;
 * 2. passe la purchase correspondante à `paid` (service role).
 * Utilisé par la route webhook et par le simulateur mock.
 */
export async function processPaymentEvent(
  input: PaymentEventInput,
): Promise<ProcessResult> {
  const supabase = createServiceSupabase();
  if (!supabase) return { ok: false, reason: "not-configured" };

  const { error: eventError } = await supabase.from("payment_events").insert({
    event_id: input.eventId,
    provider: input.provider,
    payload: {
      reference: input.reference,
      ...(input.payload ?? {}),
    },
  });

  if (eventError) {
    if (eventError.code === "23505") {
      return { ok: true, duplicate: true };
    }
    return { ok: false, reason: eventError.message };
  }

  let query = supabase
    .from("purchases")
    .update({
      status: "paid",
      paid_at: new Date().toISOString(),
    })
    .eq("provider", input.provider);

  query = input.purchaseId
    ? query.eq("id", input.purchaseId)
    : query.eq("provider_reference", input.reference);

  const { data, error } = await query.select("id,user_id,category_id,level");

  if (error) return { ok: false, reason: error.message };
  if (!data || data.length === 0) {
    return { ok: false, reason: "unknown-reference" };
  }

  await supabase
    .from("payment_events")
    .update({ processed_at: new Date().toISOString() })
    .eq("event_id", input.eventId);

  return { ok: true };
}
