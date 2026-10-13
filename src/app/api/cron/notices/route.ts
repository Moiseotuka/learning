import { flushScheduledNotices } from "@/lib/instructor/notices";

/**
 * File des notifications de classe, côté horloge.
 *
 * Une action du formateur envoie ce qui la suit tout de suite ; cette tâche
 * périodique prend ce qui a une heure dite : rappel de la veille à 19 h 30 de
 * l'académie, rapport de présence après la séance, relance des absents, et les
 * lignes qu'un incident réseau a laissées en file.
 *
 * Le secret est obligatoire : sans lui, la route refuse de courir plutôt que
 * de laisser un inconnu déclencher les envois.
 */
export const dynamic = "force-dynamic";

function authorized(request: Request): boolean {
  const secret = process.env.CRON_SECRET ?? "";
  if (!secret) return false;
  return request.headers.get("authorization") === `Bearer ${secret}`;
}

export async function GET(request: Request): Promise<Response> {
  if (!authorized(request)) {
    return Response.json({ ok: false, reason: "unauthorized" }, { status: 401 });
  }

  const report = await flushScheduledNotices();
  return Response.json({ ok: true, ...report });
}
