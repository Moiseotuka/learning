import { timingSafeEqual } from "node:crypto";

import { flushScheduledNotices } from "@/lib/instructor/notices";
import { flushMarketing } from "@/lib/marketing/queue";

/**
 * File des e-mails automatiques, côté horloge.
 *
 * Une action du formateur envoie ce qui la suit tout de suite ; cette tâche
 * périodique prend ce qui a une heure dite : rappel de la veille à 19 h 30 de
 * l'académie, rapport de présence après la séance, relance des absents, et les
 * lignes qu'un incident réseau a laissées en file.
 *
 * Elle porte aussi les relances marketing : parcours laissé en cours, niveau
 * suivant à goûter, annonce d'un nouveau parcours. Les deux files se partagent
 * le même plafond d'envoi du jour — c'est le fournisseur de mails qui compte les
 * deux ensemble.
 *
 * Le secret est obligatoire : sans lui, la route refuse de courir plutôt que
 * de laisser un inconnu déclencher les envois.
 */
export const dynamic = "force-dynamic";

function authorized(request: Request): boolean {
  const secret = process.env.CRON_SECRET ?? "";
  if (!secret) return false;

  const header = request.headers.get("authorization") ?? "";
  const provided = `Bearer ${secret}`;
  // Comparaison à temps constant : une égalité testée préfixe par préfixe
  // laisserait reconstituer le secret depuis l'extérieur. Les longueurs
  // diffèrent sans risque — `timingSafeEqual` lève sinon.
  const sent = Buffer.from(header);
  const expected = Buffer.from(provided);
  return sent.length === expected.length && timingSafeEqual(sent, expected);
}

export async function GET(request: Request): Promise<Response> {
  if (!authorized(request)) {
    return Response.json({ ok: false, reason: "unauthorized" }, { status: 401 });
  }

  const classes = await flushScheduledNotices();
  const marketing = await flushMarketing();
  return Response.json({ ok: true, ...classes, marketing });
}
