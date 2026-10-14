/**
 * Moteur des relances automatiques.
 *
 * Deux temps, comme pour les notifications de classe : `syncMarketing` pose en
 * base les lignes dues (les règles vivent dans la migration, pour que le calcul
 * de la progression reste près des données), `flushMarketing` envoie ce qui est
 * à l'heure dans la limite du budget du jour.
 *
 * Le plafond quotidien est partagé avec les convocations des formateurs : le
 * fournisseur d'e-mails compte les deux. Sans cette discipline, une campagne de
 * relance épuiserait la réserve et les élèves convoqués le même soir ne
 * recevraient rien.
 */

import { sendEmail, type EmailResult } from "@/lib/email/send";
import {
  composeMarketing,
  type MarketingKind,
  type MarketingRow,
} from "@/lib/marketing/templates";
import { createServiceSupabase } from "@/lib/supabase/service";

type Reader = NonNullable<ReturnType<typeof createServiceSupabase>>;

/** Plafond par défaut : sous les 300 e-mails/jour du compte d'envoi actuel. */
export const DEFAULT_DAILY_CAP = 220;

const BATCH = 40;
const PARALLEL = 5;
const MAX_ATTEMPTS = 4;

/** Budget de la tâche du soir ; le reste consomme la fenêtre du serveur. */
const CRON_BUDGET_MS = 12_000;

/** Ordre d'importance : ce qui rattache un apprenant passe avant l'annonce. */
const PRIORITY: MarketingKind[] = ["resume", "level_up", "winback", "explore", "new_track"];

export type MarketingReport = {
  enqueued: number;
  due: number;
  sent: number;
  failed: number;
  deferred: number;
  cap: number;
  used: number;
};

async function usedToday(supabase: Reader, now: Date): Promise<number> {
  const dayStart = new Date(now);
  dayStart.setUTCHours(0, 0, 0, 0);
  const stamp = dayStart.toISOString();

  const [{ count: marketing }, { count: classNotices }] = await Promise.all([
    supabase
      .from("marketing_notices")
      .select("id", { count: "exact", head: true })
      .gte("sent_at", stamp),
    supabase
      .from("instructor_notices")
      .select("id", { count: "exact", head: true })
      .gte("sent_at", stamp),
  ]);

  return (marketing ?? 0) + (classNotices ?? 0);
}

async function dailyCap(supabase: Reader): Promise<number> {
  const { data } = await supabase
    .from("marketing_state")
    .select("value")
    .eq("key", "daily_cap")
    .maybeSingle<{ value: string }>();
  const parsed = Number(data?.value);
  return Number.isFinite(parsed) && parsed > 0 ? Math.round(parsed) : DEFAULT_DAILY_CAP;
}

/** Pose en file tout ce qui est dû ; renvoie le nombre de lignes ajoutées. */
export async function syncMarketing(supabase: Reader, now: Date): Promise<number> {
  const { data, error } = await supabase.rpc("marketing_queue_sync", { p_now: now.toISOString() });
  if (error) {
    console.error("[marketing] mise en file", error.code, error.message);
    return 0;
  }
  return Number(data) || 0;
}

async function deliver(
  supabase: Reader,
  notice: MarketingRow,
  now: Date,
): Promise<"sent" | "void" | "failed"> {
  let result: EmailResult | null = null;
  try {
    const draft = await composeMarketing(supabase, notice);
    if (!draft) {
      // La situation n'existe plus : parcours retiré, apprenant sans profil.
      await supabase
        .from("marketing_notices")
        .update({ sent_at: now.toISOString(), last_error: "sans objet" })
        .eq("id", notice.id);
      return "void";
    }
    result = await sendEmail({ to: notice.recipient, ...draft });
  } catch (error) {
    console.error("[marketing] envoi", notice.kind, error);
    result = null;
  }

  if (result?.sent || result?.demo) {
    await supabase
      .from("marketing_notices")
      .update({
        sent_at: now.toISOString(),
        attempts: notice.attempts + 1,
        last_error: result.sent ? null : "mode démo",
      })
      .eq("id", notice.id);
    return "sent";
  }

  const reason = (result?.error ?? "envoi impossible").slice(0, 180);

  // Un refus du fournisseur (clé absente, expéditeur non validé) est un défaut du
  // site : la relance partira d'elle-même dès que l'envoi sera rétabli, si les
  // tentatives ne sont pas brûlées pendant la coupure.
  const siteBlocked = /api key|unauthorized|forbidden|401|sender|not valid|rejected/i.test(
    reason,
  );

  await supabase
    .from("marketing_notices")
    .update({
      attempts: siteBlocked ? notice.attempts : notice.attempts + 1,
      last_error: reason,
    })
    .eq("id", notice.id);
  return "failed";
}

/**
 * Envoie les relances dues, dans la limite du plafond du jour et du budget de la
 * tâche. Ce qui reste en file n'est pas perdu : la passe suivante le reprend, et
 * un apprenant déjà servi dans les cinq jours n'en reçoit pas une deuxième.
 */
export async function flushMarketing(
  now = new Date(),
  budgetMs = CRON_BUDGET_MS,
): Promise<MarketingReport> {
  const supabase = createServiceSupabase();
  const report: MarketingReport = {
    enqueued: 0,
    due: 0,
    sent: 0,
    failed: 0,
    deferred: 0,
    cap: 0,
    used: 0,
  };
  if (!supabase) return report;

  report.enqueued = await syncMarketing(supabase, now);
  report.cap = await dailyCap(supabase);
  report.used = await usedToday(supabase, now);

  const room = Math.max(0, report.cap - report.used);
  if (room === 0) {
    const { count } = await supabase
      .from("marketing_notices")
      .select("id", { count: "exact", head: true })
      .is("sent_at", null);
    report.deferred = count ?? 0;
    return report;
  }

  const { data: rows } = await supabase
    .from("marketing_notices")
    .select("id,kind,user_id,track_id,recipient,attempts")
    .is("sent_at", null)
    .lte("scheduled_at", now.toISOString())
    .lt("attempts", MAX_ATTEMPTS)
    .order("scheduled_at")
    .limit(Math.min(BATCH, room));

  const due = (rows as MarketingRow[] | null) ?? [];
  report.due = due.length;
  due.sort((a, b) => PRIORITY.indexOf(a.kind) - PRIORITY.indexOf(b.kind));

  const deadline = Date.now() + budgetMs;
  for (let index = 0; index < due.length; index += PARALLEL) {
    if (Date.now() > deadline) {
      report.deferred += due.length - index;
      break;
    }
    const outcomes = await Promise.all(
      due.slice(index, index + PARALLEL).map((notice) => deliver(supabase, notice, now)),
    );
    for (const outcome of outcomes) {
      if (outcome === "sent") report.sent += 1;
      else if (outcome === "void") report.deferred += 1;
      else report.failed += 1;
    }
  }

  report.used = await usedToday(supabase, now);
  return report;
}

/* -------------------------------------------------------------------------
 * Consentement
 * ---------------------------------------------------------------------- */

export type ConsentState = {
  email: string;
  optedOut: boolean;
  fullName: string | null;
};

async function byToken(supabase: Reader, token: string): Promise<ConsentState | null> {
  const { data } = await supabase
    .from("marketing_subscriptions")
    .select("email,opted_out_at")
    .eq("token", token)
    .maybeSingle<{ email: string; opted_out_at: string | null }>();
  if (!data) return null;

  const { data: profile } = await supabase
    .from("profiles")
    .select("full_name")
    .ilike("email", data.email)
    .maybeSingle<{ full_name: string | null }>();

  return {
    email: data.email,
    optedOut: data.opted_out_at !== null,
    fullName: profile?.full_name ?? null,
  };
}

/**
 * Le lien du message pointe ici sans session : le jeton seul prouve qu'on tient
 * l'e-mail. On peut s'inscrire comme se retirer — le clic inverse est prévu,
 * sinon une désinscription devenue invisible serait un piège.
 */
export async function setConsent(
  token: string,
  optedOut: boolean,
): Promise<ConsentState | null> {
  const supabase = createServiceSupabase();
  if (!supabase || !token) return null;

  const { error } = await supabase
    .from("marketing_subscriptions")
    .update({ opted_out_at: optedOut ? new Date().toISOString() : null, updated_at: new Date().toISOString() })
    .eq("token", token);
  if (error) {
    console.error("[marketing] consentement", error.code, error.message);
    return null;
  }
  return byToken(supabase, token);
}

export async function consentFor(token: string): Promise<ConsentState | null> {
  const supabase = createServiceSupabase();
  if (!supabase || !token) return null;
  return byToken(supabase, token);
}

/* -------------------------------------------------------------------------
 * Suivi demandé par l'administrateur
 * ---------------------------------------------------------------------- */

export type MarketingBoard = {
  cap: number;
  used: number;
  queued: number;
  sentToday: number;
  failedRows: number;
  optedOut: number;
  byKind: { kind: MarketingKind; queued: number; sent: number }[];
  errors: { recipient: string; kind: string; error: string; attempts: number }[];
};

export async function marketingBoard(): Promise<MarketingBoard> {
  const supabase = createServiceSupabase();
  const empty: MarketingBoard = {
    cap: DEFAULT_DAILY_CAP,
    used: 0,
    queued: 0,
    sentToday: 0,
    failedRows: 0,
    optedOut: 0,
    byKind: [],
    errors: [],
  };
  if (!supabase) return empty;

  const now = new Date();
  const dayStart = new Date(now);
  dayStart.setUTCHours(0, 0, 0, 0);

  const { data: rows } = await supabase
    .from("marketing_notices")
    .select("kind,sent_at,last_error,attempts,recipient");
  const list =
    (rows as { kind: MarketingKind; sent_at: string | null; last_error: string | null; attempts: number; recipient: string }[] | null) ?? [];

  const byKind = new Map<MarketingKind, { queued: number; sent: number }>();
  let sentToday = 0;
  let queued = 0;
  let failedRows = 0;
  const errors: MarketingBoard["errors"] = [];

  for (const row of list) {
    const bucket = byKind.get(row.kind) ?? { queued: 0, sent: 0 };
    if (row.sent_at) {
      if (!row.last_error || row.last_error === "mode démo") bucket.sent += 1;
      if (new Date(row.sent_at) >= dayStart) sentToday += 1;
    } else {
      bucket.queued += 1;
      queued += 1;
      if (row.last_error) {
        failedRows += 1;
        if (errors.length < 6) {
          errors.push({ recipient: row.recipient, kind: row.kind, error: row.last_error, attempts: row.attempts });
        }
      }
    }
    byKind.set(row.kind, bucket);
  }

  const { count: optedOut } = await supabase
    .from("marketing_subscriptions")
    .select("email", { count: "exact", head: true })
    .not("opted_out_at", "is", null);

  return {
    cap: await dailyCap(supabase),
    used: await usedToday(supabase, now),
    queued,
    sentToday,
    failedRows,
    optedOut: optedOut ?? 0,
    byKind: [...byKind.entries()].map(([kind, bucket]) => ({ kind, ...bucket })),
    errors,
  };
}

/** Le plafond se règle ici parce qu'il dépend du fournisseur d'e-mails, pas du code. */
export async function setDailyCap(cap: number): Promise<boolean> {
  const supabase = createServiceSupabase();
  if (!supabase) return false;
  const value = Math.max(1, Math.min(5000, Math.round(cap)));
  const { error } = await supabase.from("marketing_state").upsert(
    { key: "daily_cap", value: String(value), updated_at: new Date().toISOString() },
    { onConflict: "key" },
  );
  return !error;
}

/** Relance immédiate, pour le bouton de contrôle de l'administrateur. */
export async function runMarketingNow(): Promise<MarketingReport> {
  return flushMarketing(new Date(), 20_000);
}
