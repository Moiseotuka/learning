import { createHmac, timingSafeEqual } from "node:crypto";

import {
  CHECKOUT_CURRENCY,
  amountMatches,
  nyoleSecretKey,
} from "@/lib/payments/nyole";
import { processPaymentEvent } from "@/lib/payments/processor";
import { settleInstructorSubscription } from "@/lib/instructor/checkout";
import { createServiceSupabase } from "@/lib/supabase/service";

const MAX_TOLERANCE_SECONDS = 300;

/**
 * Secret d'exemple présent dans `.env.example` : refusé, sinon n'importe qui
 * peut signer un faux « paiement confirmé » avec une valeur publiée dans le
 * dépôt.
 */
const PUBLIC_DEMO_SECRET = "easylearn-webhook-secret-2024";

function safeEqualHex(a: string, b: string): boolean {
  const bufferA = Buffer.from(a, "utf8");
  const bufferB = Buffer.from(b, "utf8");
  if (bufferA.length !== bufferB.length) return false;
  return timingSafeEqual(bufferA, bufferB);
}

/**
 * Webhook nyole : `POST /api/webhooks/payment` signé avec
 * `X-Afriflow-Timestamp` + `X-Afriflow-Signature: t=<ts>,v1=<HMAC-SHA256>`,
 * HMAC-SHA256 de `${ts}.${corpsBrut}` avec la clé secrète nyole.
 * Idempotent : `payment.completed` partage le même event_id que la vérification
 * de statut serveur (`nyole:<session id>`), un double traitement est ignoré.
 */
type NyoleWebhookBody = {
  event?: string;
  livemode?: boolean;
  data?: {
    id?: string;
    status?: string;
    amount?: number;
    currency?: string;
    metadata?: Record<string, unknown> | null;
  };
  timestamp?: string;
};

async function handleNyole(
  request: Request,
  rawBody: string,
): Promise<Response> {
  const secret = nyoleSecretKey();
  if (!secret) {
    return Response.json(
      { ok: false, reason: "not-configured" },
      { status: 503 },
    );
  }

  const timestamp = request.headers.get("x-afriflow-timestamp") ?? "";
  const signature = (
    request.headers.get("x-afriflow-signature") ?? ""
  )
    .split(",")
    .find((part) => part.startsWith("v1="))
    ?.slice(3);

  if (!timestamp || !signature) {
    return Response.json(
      { ok: false, reason: "bad-signature" },
      { status: 401 },
    );
  }

  const age = Math.abs(Date.now() / 1000 - Number(timestamp));
  if (!Number.isFinite(age) || age > MAX_TOLERANCE_SECONDS) {
    return Response.json({ ok: false, reason: "expired" }, { status: 401 });
  }

  const expected = createHmac("sha256", secret)
    .update(`${timestamp}.${rawBody}`)
    .digest("hex");
  if (!safeEqualHex(expected, signature)) {
    return Response.json(
      { ok: false, reason: "bad-signature" },
      { status: 401 },
    );
  }

  let payload: NyoleWebhookBody;
  try {
    payload = JSON.parse(rawBody) as NyoleWebhookBody;
  } catch {
    return Response.json(
      { ok: false, reason: "bad-payload" },
      { status: 400 },
    );
  }

  if (
    payload.event !== "payment.completed" ||
    payload.data?.status !== "SUCCESS" ||
    !payload.data?.id
  ) {
    return Response.json({
      ok: true,
      skipped: payload.event ?? payload.data?.status ?? "unknown",
    });
  }

  const supabase = createServiceSupabase();
  if (!supabase) {
    return Response.json(
      { ok: false, reason: "not-configured" },
      { status: 503 },
    );
  }

  const sessionId = payload.data.id;
  const metadata = payload.data.metadata ?? null;
  const purchaseId =
    typeof metadata?.purchase_id === "string" ? metadata.purchase_id : null;
  const subscriptionId =
    typeof metadata?.subscription_id === "string" ? metadata.subscription_id : null;

  if (subscriptionId) {
    const settled = await settleInstructorSubscription(supabase, {
      subscriptionId,
      reference: sessionId,
    });
    if (!settled.ok && settled.reason === "unknown") {
      console.warn("[webhook] nyole : souscription introuvable pour", sessionId);
      return Response.json({ ok: true, skipped: "unknown-subscription" });
    }
    if (!settled.ok) {
      return Response.json(settled, { status: 500 });
    }
    return Response.json({ ok: true, paid: settled.paid });
  }

  const lookup = purchaseId
    ? supabase.from("purchases").select("id,status,amount_usd,currency").eq("id", purchaseId)
    : supabase
        .from("purchases")
        .select("id,status,amount_usd,currency")
        .eq("provider", "nyole")
        .eq("provider_reference", sessionId);

  const { data: purchase, error: purchaseError } =
    await lookup.maybeSingle<{
      id: string;
      status: string;
      amount_usd: number | null;
      currency: string | null;
    }>();

  if (purchaseError) {
    return Response.json(
      { ok: false, reason: purchaseError.message },
      { status: 500 },
    );
  }
  if (!purchase) {
    console.warn("[webhook] nyole : achat introuvable pour", sessionId);
    return Response.json({ ok: true, skipped: "unknown-purchase" });
  }

  if (
    payload.data.amount !== undefined &&
    payload.data.currency !== undefined &&
    !amountMatches(
      purchase.amount_usd,
      { amount: payload.data.amount, currency: payload.data.currency },
      CHECKOUT_CURRENCY,
    )
  ) {
    console.warn(
      "[webhook] nyole : montant incohérent —",
      JSON.stringify({
        purchaseId: purchase.id,
        expectedUsd: purchase.amount_usd,
        currency: payload.data.currency,
        amount: payload.data.amount,
      }),
    );
    return Response.json({ ok: true, skipped: "amount-mismatch" });
  }

  const result = await processPaymentEvent({
    eventId: `nyole:${sessionId}`,
    provider: "nyole",
    reference: sessionId,
    purchaseId: purchase.id,
    payload: payload as unknown as Record<string, unknown>,
  });

  if (!result.ok) {
    return Response.json(result, { status: 500 });
  }
  return Response.json(result);
}

export async function POST(request: Request): Promise<Response> {
  if (request.headers.get("x-afriflow-signature")) {
    const rawBody = await request.text();
    return handleNyole(request, rawBody);
  }

  const secret = process.env.PAYMENT_WEBHOOK_SECRET;
  if (!secret || secret === PUBLIC_DEMO_SECRET) {
    return Response.json(
      { ok: false, reason: "not-configured" },
      { status: 503 },
    );
  }

  const rawBody = await request.text();
  const signature = request.headers.get("x-payment-signature") ?? "";
  const expected = createHmac("sha256", secret).update(rawBody).digest("hex");

  if (!signature || !safeEqualHex(signature, expected)) {
    return Response.json({ ok: false, reason: "bad-signature" }, { status: 401 });
  }

  let payload: {
    event_id?: string;
    provider?: string;
    reference?: string;
    status?: string;
    timestamp?: number;
  };
  try {
    payload = JSON.parse(rawBody) as typeof payload;
  } catch {
    return Response.json({ ok: false, reason: "bad-payload" }, { status: 400 });
  }

  if (!payload.event_id || !payload.reference || !payload.provider) {
    return Response.json({ ok: false, reason: "bad-payload" }, { status: 400 });
  }

  if (payload.timestamp !== undefined) {
    const age = Math.abs(Date.now() / 1000 - payload.timestamp);
    if (age > MAX_TOLERANCE_SECONDS) {
      return Response.json({ ok: false, reason: "expired" }, { status: 401 });
    }
  }

  if (payload.status && payload.status !== "paid") {
    return Response.json({ ok: true, skipped: payload.status });
  }

  const result = await processPaymentEvent({
    eventId: payload.event_id,
    provider: payload.provider === "nyole" ? "nyole" : "mock",
    reference: payload.reference,
    payload: payload as Record<string, unknown>,
  });

  if (!result.ok) {
    return Response.json(result, { status: 500 });
  }

  return Response.json(result);
}
