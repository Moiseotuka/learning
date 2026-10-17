import type { NextRequest } from "next/server";

import {
  appareil,
  attribuer,
  estUnePage,
  estUnRobot,
  identifiantVisiteur,
  jourDe,
} from "@/lib/analytics/visite";
import { supabaseEnv } from "@/lib/supabase/config";

/**
 * Journalise une page vue, sans service de mesure tiers.
 *
 * Le tableau de bord admin lit la table `site_visits` pour répondre à « combien de visiteurs, et
 * depuis quel lien ». Rien n'est envoyé à un tiers, aucun cookie n'est posé : sur une connexion
 * 3G au franc congolais, un script de mesure ne fait que retarder la leçon.
 *
 * L'écriture part en arrière-plan, après l'envoi de la réponse : une visite ne doit jamais rendre
 * le visiteur plus lent, et une visite perdue ne doit jamais casser une page.
 */
export async function journaliserVisite(request: NextRequest): Promise<void> {
  if (request.method !== "GET") return;

  const url = request.nextUrl;
  if (!estUnePage(url.pathname)) return;

  const userAgent = request.headers.get("user-agent") ?? "";
  const prefetch =
    request.headers.get("next-router-prefetch") ||
    request.headers.get("purpose") === "prefetch" ||
    request.headers.get("sec-fetch-purpose")?.includes("prefetch");

  if (estUnRobot(userAgent) || prefetch) return;

  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";
  if (!supabaseEnv.url || !serviceKey) return;

  // `hostname` et non `host` : en local ou sur un prévisualiseur, `host` porte le port
  // (« 127.0.0.1:3141 ») et ne correspond jamais au référent, ce qui ferait apparaître un canal
  // fantôme « 127 » pour de simples navigations internes.
  const attribution = attribuer(url.searchParams, request.headers.get("referer"), url.hostname);
  const maintenant = new Date();
  const ip = (request.headers.get("x-forwarded-for") ?? "inconnue").split(",")[0].trim();

  try {
    const reponse = await fetch(`${supabaseEnv.url}/rest/v1/site_visits`, {
      method: "POST",
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        path: url.pathname.slice(0, 120),
        source: attribution.source,
        medium: attribution.medium,
        campaign: attribution.campaign,
        referrer: attribution.referrer,
        country: (request.headers.get("x-vercel-ip-country") ?? "").slice(0, 2) || null,
        device: appareil(userAgent),
        visitor_id: await identifiantVisiteur(ip, userAgent, jourDe(maintenant)),
        signed_in: request.cookies.getAll().some((c) => c.name.startsWith("sb-")),
      }),
    });

    if (!reponse.ok) {
      console.error("[analytics] visite", reponse.status, url.pathname);
    }
  } catch (erreur) {
    console.error("[analytics] visite", erreur);
  }
}

/** Deuxième paramètre du `proxy` de Next : c'est lui qui porte `waitUntil`, pas la requête. */
export type EvenementProxy = {
  waitUntil?: (promesse: Promise<unknown>) => void;
};

/** Une tâche lancée après l'envoi de la réponse ; sur un runtime qui ne la connaîtrait pas, elle court quand même. */
export function tacheArrierePlan(event: EvenementProxy | undefined, tache: () => Promise<void>) {
  if (typeof event?.waitUntil === "function") {
    event.waitUntil(tache());
    return;
  }

  void tache();
}
