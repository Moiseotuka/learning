import { site } from "@/config/site";

/**
 * Client HTTP minimal pour l'API nyole (côté serveur uniquement).
 * Docs : https://nyole.com/docs/
 *  - POST  /v1/checkout/sessions            → crée la session, renvoie l'URL
 *  - GET   /v1/checkout/sessions/{id}/status→ statut fait foi (PENDING/SUCCESS/…)
 *  - PATCH /v1/config/webhook               → enregistre l'URL du webhook
 * La clé secrète (NYOLE_SECRET_KEY) ne quitte jamais le serveur.
 */

export const NYOLE_API = "https://app.nyole.com/api";

/**
 * Devise de facturation d'easyTech : le prix affiché à l'apprenant est en CDF,
 * la session nyole est créée dans cette devise et `purchases.currency` doit
 * rester alignée. La vérification du montant compare la session à cette devise
 * — jamais à `purchases.currency`, colonne restée à son défaut `USD` sur les
 * lignes anciennes, ce qui faisait rejeter un paiement réel.
 */
export const CHECKOUT_CURRENCY = "CDF";

export type NyoleSessionStatus =
  | "PENDING"
  | "SUCCESS"
  | "FAILED"
  | "CANCELLED"
  | "REFUNDED";

export type NyoleSession = {
  id: string;
  url: string;
  order_id?: string;
  amount?: number;
  currency?: string;
  status?: string;
  livemode?: boolean;
};

export type NyoleStatus = {
  id: string;
  status: NyoleSessionStatus;
  paid: boolean;
  amount: number;
  currency: string;
  order_id?: string;
  provider?: string | null;
  provider_reference?: string | null;
  failure_message?: string | null;
  livemode?: boolean;
};

export function nyoleSecretKey(): string | null {
  const key = process.env.NYOLE_SECRET_KEY?.trim();
  return key && key.startsWith("af_") ? key : null;
}

/**
 * Provider actif. En production hébergée, `PAYMENT_PROVIDER=nyole` fait foi :
 * une clé absente ou mal formée doit bloquer l'achat, surtout pas basculer sur
 * le mode simulé, qui ouvre les niveaux payés sans le moindre paiement.
 */
export function activePaymentProvider(): "mock" | "nyole" {
  if (process.env.PAYMENT_PROVIDER === "nyole" && nyoleSecretKey()) {
    return "nyole";
  }

  // Le mode simulé ouvre les niveaux payés sans le moindre paiement : il reste
  // donc confiné aux environnements de test. En production, une variable mal
  // réglée ou une clé absente ferme la caisse au lieu de l'ouvrir.
  const vercelEnv = process.env.VERCEL_ENV;
  const testEnvironment =
    (vercelEnv === "preview" || vercelEnv === "development") ||
    process.env.NODE_ENV !== "production";

  if (!testEnvironment) {
    console.error(
      "[nyole] production sans fournisseur de paiement exploitable : achat " +
        "refusé plutôt que simulé (PAYMENT_PROVIDER=nyole et NYOLE_SECRET_KEY " +
        "requis ; une valeur masquée type « [SENSITIVE] » a pu être recopiée).",
    );
    return "nyole";
  }

  return "mock";
}

export function isNyoleTestKey(key: string | null = nyoleSecretKey()): boolean {
  return Boolean(key?.startsWith("af_test_"));
}

/** URL de la page de paiement hébergée, reconstituée à partir de l'id. */
export function nyoleCheckoutUrl(sessionId: string): string {
  return `https://app.nyole.com/checkout/${sessionId}`;
}

export function absoluteUrl(path: string): string {
  return new URL(path, site.url).toString();
}

async function nyoleFetch<T>(
  path: string,
  init: RequestInit & { idempotencyKey?: string } = {},
): Promise<{ ok: true; data: T } | { ok: false; reason: string }> {
  const secret = nyoleSecretKey();
  if (!secret) return { ok: false, reason: "not-configured" };

  const headers: Record<string, string> = {
    Authorization: `Bearer ${secret}`,
    "Content-Type": "application/json",
    ...(init.headers as Record<string, string> | undefined),
  };
  if (init.idempotencyKey) headers["Idempotency-Key"] = init.idempotencyKey;

  try {
    const response = await fetch(`${NYOLE_API}${path}`, {
      ...init,
      headers,
      signal: AbortSignal.timeout(20_000),
      cache: "no-store",
    });
    const text = await response.text();
    let data: unknown = null;
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = null;
    }
    if (!response.ok) {
      const error = (data as { error?: { message?: string } } | null)?.error;
      const detail = error?.message ?? text.slice(0, 300);
      console.warn(
        "[nyole]",
        init.method ?? "GET",
        path,
        response.status,
        detail,
      );
      // 401/403 = clé API refusée : un probleme de configuration, pas un refus
      // de paiement. Sans ce distinguishing, l'apprenant lit « le service a
      // refusé la demande » alors que rien n'a ete envoye.
      return {
        ok: false,
        reason:
          response.status === 401 || response.status === 403
            ? "nyole-auth"
            : "nyole-error",
      };
    }
    return { ok: true, data: data as T };
  } catch (error) {
    console.warn(
      "[nyole]",
      path,
      error instanceof Error ? error.message : "network error",
    );
    return { ok: false, reason: "nyole-unavailable" };
  }
}

export type CreateSessionInput = {
  amount: number;
  currency: string;
  description: string;
  customerEmail?: string | null;
  customerName?: string | null;
  successUrl: string;
  cancelUrl: string;
  metadata: Record<string, string>;
  idempotencyKey: string;
};

export async function createNyoleSession(
  input: CreateSessionInput,
): Promise<{ ok: true; session: NyoleSession } | { ok: false; reason: string }> {
  const body = {
    amount: input.amount,
    currency: input.currency,
    description: input.description,
    success_url: input.successUrl,
    cancel_url: input.cancelUrl,
    metadata: input.metadata,
    merchant_name: site.name,
    ...(input.customerEmail ? { customer_email: input.customerEmail } : {}),
    ...(input.customerName ? { customer_name: input.customerName } : {}),
  };

  const result = await nyoleFetch<NyoleSession>("/v1/checkout/sessions", {
    method: "POST",
    body: JSON.stringify(body),
    idempotencyKey: input.idempotencyKey,
  });

  if (!result.ok) return { ok: false, reason: result.reason };
  if (!result.data?.id || !result.data.url) {
    return { ok: false, reason: "nyole-error" };
  }
  return { ok: true, session: result.data };
}

export async function getNyoleSessionStatus(
  sessionId: string,
): Promise<{ ok: true; status: NyoleStatus } | { ok: false; reason: string }> {
  if (!sessionId) return { ok: false, reason: "nyole-error" };
  const result = await nyoleFetch<NyoleStatus>(
    `/v1/checkout/sessions/${encodeURIComponent(sessionId)}/status`,
  );
  if (!result.ok) return { ok: false, reason: result.reason };
  if (!result.data?.status) return { ok: false, reason: "nyole-error" };
  return { ok: true, status: result.data };
}

/**
 * Contrôle d'intégrité avant de marquer une purchase `paid`.
 * nyole exprime `amount` dans l'unité principale de la devise
 * (`28000` pour 28 000 CDF, `5000` pour 5 000 XOF) : vérifié sur la page
 * hébergée, qui affiche « 28 000 CDF » pour `amount: 28000, currency: "CDF"`.
 * La devise doit être celle attendue et le montant au moins égal au prix
 * affiché (les frais de passerelle peuvent être refacturés au client selon le
 * réglage de l'espace nyole). Un sous-paiement est refusé.
 */
export function amountMatches(
  priceUsd: number | null,
  status: { amount: number; currency: string },
  expectedCurrency = CHECKOUT_CURRENCY,
): boolean {
  if (priceUsd === null) return true;
  if (status.currency !== expectedCurrency) return false;
  return status.amount >= priceUsd;
}
