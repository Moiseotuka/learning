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
 * Utilisé par la route webhook et par le simulateur mock. Un évènement déjà
 * inséré mais jamais appliqué (`processed_at` nul) est représenté, donc une
 * validation interrompue peut être reprise plus tard.
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
    if (eventError.code !== "23505") {
      return { ok: false, reason: eventError.message };
    }
    // Evenement deja vu : le raccourci « déjà traité » n'est valable que si une
    // tentative précédente est allée jusqu'au bout. Sinon (achat jamais débloqué
    // alors que la clé d'idempotence était consommée), on reprend la validation.
    const { data: prior } = await supabase
      .from("payment_events")
      .select("processed_at")
      .eq("event_id", input.eventId)
      .maybeSingle<{ processed_at: string | null }>();

    if (prior?.processed_at) return { ok: true, duplicate: true };
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
