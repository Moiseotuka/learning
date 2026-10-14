/**
 * Boîte d'envoi des notifications de classe.
 *
 * Le formateur planifie : le système prévient. Une ligne de `instructor_notices`
 * est un e-mail dû à une adresse, à une heure dite, avec une clé qui interdit le
 * doublon. La file absorbe les pannes : un envoi qui échoue reste dû et repart
 * plus tard, jamais deux fois la même annonce.
 *
 * Le contenu n'existe pas dans la file : il est composé à l'envoi à partir de
 * l'état réel de la classe. Un programme corrigé après sa mise en file part
 * corrigé.
 *
 * Deux horloges se partagent la file : l'action du formateur vide ce qui vient
 * de naître (`notifyNow`, pour qu'une invitation ou une annulation parte à la
 * minute), la tâche périodique du soir envoie ce qui a une heure dite — rappel
 * de la veille, rapport de présence, relance des absents.
 */

import { sendEmail, type EmailResult } from "@/lib/email/send";
import {
  agendaLines,
  agendaLink,
  classLink,
  emailButton,
  emailLayout,
  escapeHtml,
  LOW_CONNECTION_NOTE,
  sessionLink,
  siteUrl,
  trackLink,
} from "@/lib/instructor/email-templates";
import {
  academyDateLabel,
  academyDateTimeLabel,
  academyHourLabel,
  reminderInstant,
} from "@/lib/instructor/timezone";
import { createServiceSupabase } from "@/lib/supabase/service";

type Reader = NonNullable<ReturnType<typeof createServiceSupabase>>;

export const NOTICE_KINDS = [
  "program",
  "session_reminder",
  "session_cancelled",
  "session_rescheduled",
  "absent_followup",
  "attendance_report",
] as const;

export type NoticeKind = (typeof NOTICE_KINDS)[number];

/** Une séance telle que les convocations la racontent. */
export type NoticeSession = {
  id: string;
  title: string;
  agenda: string;
  startsAt: string;
  endsAt: string;
  status: string;
  previousStartsAt: string | null;
};

export type NoticeRoster = {
  classId: string;
  classTitle: string;
  academy: string;
  trackTitle: string;
  trackSlug: string;
  instructorId: string;
  instructorName: string;
  instructorEmail: string | null;
  members: { userId: string; fullName: string; email: string }[];
};

const DAY_MS = 86_400_000;

/** Le rappel d'une séance lontaine ne sert pas : trois semaines d'avance suffisent. */
const HORIZON_DAYS = 21;

/** Le rapport de présence part après la séance : l'heure de fin est atteinte. */
const REPORT_LAG_MS = 45 * 60_000;

function dedupKey(...parts: (string | number)[]): string {
  return parts.join("|");
}

/* -------------------------------------------------------------------------
 * Lecture du contexte
 * ---------------------------------------------------------------------- */

async function rosterOf(supabase: Reader, classId: string): Promise<NoticeRoster | null> {
  const { data: classRow } = await supabase
    .from("instructor_classes")
    .select("id,title,academy,instructor_id,track_id,tracks(slug,title)")
    .eq("id", classId)
    .maybeSingle<Record<string, unknown>>();

  if (!classRow) return null;

  const instructorId = String(classRow.instructor_id);
  const { data: members } = await supabase
    .from("instructor_class_members")
    .select("user_id")
    .eq("class_id", classId)
    .eq("status", "active");

  const memberIds = ((members as { user_id: string }[] | null) ?? []).map((row) => row.user_id);
  const ids = [...new Set([instructorId, ...memberIds])];

  const { data: people } = await supabase
    .from("profiles")
    .select("id,full_name,email")
    .in("id", ids);

  const byId = new Map(
    ((people as { id: string; full_name: string | null; email: string | null }[] | null) ?? []).map(
      (row) => [row.id, row],
    ),
  );

  const instructor = byId.get(instructorId);
  const tracks = (classRow.tracks as { slug: string; title: string } | null) ?? null;

  // Un élève sans adresse joignable n'est pas convoqué : il n'a pas de boîte.
  const enrolled: NoticeRoster["members"] = [];
  for (const id of memberIds) {
    const person = byId.get(id);
    if (!person?.email) continue;
    enrolled.push({
      userId: person.id,
      fullName: person.full_name?.trim() || "Apprenant",
      email: person.email.toLowerCase(),
    });
  }

  return {
    classId,
    classTitle: String(classRow.title),
    academy: String(classRow.academy ?? ""),
    trackTitle: tracks?.title ?? "",
    trackSlug: tracks?.slug ?? "",
    instructorId,
    instructorName: instructor?.full_name?.trim() || "Votre formateur",
    instructorEmail: instructor?.email ?? null,
    members: enrolled,
  };
}

async function sessionsOf(
  supabase: Reader,
  classId: string,
  from: Date,
): Promise<NoticeSession[]> {
  const { data } = await supabase
    .from("live_sessions")
    .select("id,title,agenda,starts_at,ends_at,status,previous_starts_at")
    .eq("class_id", classId)
    .gte("starts_at", from.toISOString())
    .in("status", ["scheduled", "live"])
    .order("starts_at")
    .limit(40);

  return ((data as Record<string, unknown>[] | null) ?? []).map((row) => ({
    id: String(row.id),
    title: String(row.title),
    agenda: String(row.agenda ?? ""),
    startsAt: String(row.starts_at),
    endsAt: String(row.ends_at),
    status: String(row.status),
    previousStartsAt: (row.previous_starts_at as string | null) ?? null,
  }));
}

async function sessionOf(supabase: Reader, sessionId: string): Promise<NoticeSession | null> {
  const { data } = await supabase
    .from("live_sessions")
    .select("id,class_id,title,agenda,starts_at,ends_at,status,previous_starts_at")
    .eq("id", sessionId)
    .maybeSingle<Record<string, unknown>>();
  if (!data) return null;
  return {
    id: String(data.id),
    title: String(data.title),
    agenda: String(data.agenda ?? ""),
    startsAt: String(data.starts_at),
    endsAt: String(data.ends_at),
    status: String(data.status),
    previousStartsAt: (data.previous_starts_at as string | null) ?? null,
  };
}

/* -------------------------------------------------------------------------
 * Composition des messages
 * ---------------------------------------------------------------------- */

/** Tableau du programme : la colonne heure est celle de l'académie, jamais UTC. */
function programTable(sessions: NoticeSession[]): string {
  const rows = sessions
    .map(
      (session, index) => `<tr style="border-bottom:1px solid #e2e8f0">
  <td style="padding:9px 10px;color:#64748b">${index + 1}</td>
  <td style="padding:9px 10px;font-weight:600">${escapeHtml(session.title)}</td>
  <td style="padding:9px 10px;white-space:nowrap">${escapeHtml(academyDateTimeLabel(session.startsAt))}</td>
</tr>`,
    )
    .join("");

  return `<table role="presentation" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;font-size:14px;margin-top:16px">
  <thead>
    <tr style="background:#f1f5f9;text-align:left">
      <th style="padding:9px 10px">#</th>
      <th style="padding:9px 10px">Séance</th>
      <th style="padding:9px 10px">Date et heure</th>
    </tr>
  </thead>
  <tbody>${rows}</tbody>
</table>`;
}

type NoticeRow = {
  id: string;
  kind: NoticeKind;
  class_id: string;
  session_id: string | null;
  recipient: string;
  dedup_key: string;
  scheduled_at: string;
  attempts: number;
};

type Draft = { subject: string; html: string; text: string };

function greeting(name: string): string {
  return `Bonjour ${escapeHtml(name)},`;
}

async function draftOf(
  supabase: Reader,
  notice: NoticeRow,
  now: Date,
): Promise<Draft | null> {
  const roster = await rosterOf(supabase, notice.class_id);
  if (!roster) return null;

  const member = roster.members.find((row) => row.email === notice.recipient);
  const name = notice.kind === "attendance_report" ? roster.instructorName : (member?.fullName ?? "Apprenant");
  const sign = roster.academy || roster.classTitle;
  const footer = `Message envoyé à ${roster.members.length} élève(s) de la classe « ${escapeHtml(roster.classTitle)} ».`;

  if (notice.kind === "program") {
    const sessions = await sessionsOf(supabase, roster.classId, now);
    const subject =
      sessions.length > 0
        ? `${sign} — votre calendrier de séances`
        : `${sign} — vous êtes inscrit(e) dans la classe ${roster.classTitle}`;
    return {
      subject,
      html: emailLayout({
        academy: roster.academy,
        title:
          sessions.length > 0
            ? `Calendrier des séances — ${roster.classTitle}`
            : `Bienvenue dans la classe ${roster.classTitle}`,
        intro: `${greeting(name)} Vous êtes inscrit(e) dans la classe <strong>« ${escapeHtml(roster.classTitle)} »</strong> de ${sign}, autour du parcours <strong>« ${escapeHtml(roster.trackTitle)} »</strong>. Les horaires ci-dessous sont donnés à l'heure de l'académie.`,
        body: `${sessions.length > 0 ? programTable(sessions) : `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Votre formateur n'a pas encore publié de séance. Le calendrier complet vous sera envoyé dès la première date posée, puis rappelé la veille de chaque cours.</p>`}
${LOW_CONNECTION_NOTE}`,
        actions: `${emailButton("Ouvrir ma classe", classLink(roster.classId))}${sessions.length > 0 ? ` &nbsp; <a href="${agendaLink(roster.classId)}" style="color:#0f766e;font-size:14px">Ajouter au calendrier</a>` : ""}`,
        footnote: footer,
      }),
      text:
        sessions.length > 0
          ? `${subject}\n\n${sessions
              .map((s, i) => `${i + 1}. ${s.title} — ${academyDateTimeLabel(s.startsAt)}`)
              .join("\n")}\n\n${classLink(roster.classId)}`
          : `${subject}\n\nClasse « ${roster.classTitle} » — parcours « ${roster.trackTitle} ».\n${classLink(roster.classId)}`,
    };
  }

  const session = notice.session_id ? await sessionOf(supabase, notice.session_id) : null;
  if (!session) return null;

  if (notice.kind === "session_reminder") {
    if (session.status === "cancelled") return null;
    const subject = `Rappel — ${session.title} demain à ${academyHourLabel(session.startsAt)}`;
    return {
      subject,
      html: emailLayout({
        academy: roster.academy,
        title: `Demain : ${session.title}`,
        intro: `${greeting(name)} Votre séance <strong>« ${escapeHtml(session.title)} »</strong> commence demain à <strong>${academyDateTimeLabel(session.startsAt)}</strong>, à l'heure de l'académie. La salle s'ouvre dix minutes avant l'heure dite.`,
        body: `${session.agenda ? agendaLines(session.agenda) : ""}
${LOW_CONNECTION_NOTE}`,
        actions: emailButton("Rejoindre la salle", sessionLink(session.id)),
        footnote: `Un empêchement ? Prévenez ${escapeHtml(roster.instructorName)} depuis votre classe.`,
      }),
      text: `${subject}\n\n${session.title}\n${academyDateTimeLabel(session.startsAt)}\nRejoindre : ${sessionLink(session.id)}`,
    };
  }

  if (notice.kind === "session_cancelled") {
    const subject = `Annulée — ${session.title}`;
    return {
      subject,
      html: emailLayout({
        academy: roster.academy,
        title: `Séance annulée : ${session.title}`,
        intro: `${greeting(name)} La séance <strong>« ${escapeHtml(session.title)} »</strong> prévue le ${academyDateTimeLabel(session.startsAt)} est annulée. Aucune présence n'est comptée pour cette date.`,
        body: `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Le programme restant à jour vous sera renvoyé. En attendant, les chapitres déjà ouverts de « ${escapeHtml(roster.trackTitle)} » restent accessibles.</p>`,
        actions: emailButton("Ouvrir ma classe", classLink(roster.classId)),
        footnote: footer,
      }),
      text: `${subject}\n\nLa séance « ${session.title} » du ${academyDateTimeLabel(session.startsAt)} est annulée.`,
    };
  }

  if (notice.kind === "session_rescheduled") {
    const before = session.previousStartsAt ? academyDateTimeLabel(session.previousStartsAt) : "";
    const subject = `Reportée — ${session.title} : ${academyDateTimeLabel(session.startsAt)}`;
    return {
      subject,
      html: emailLayout({
        academy: roster.academy,
        title: `Séance reportée : ${session.title}`,
        intro: `${greeting(name)} La séance <strong>« ${escapeHtml(session.title)} »</strong> est déplacée.${
          before
            ? ` Elle était prévue ${before} ; elle aura lieu <strong>${academyDateTimeLabel(session.startsAt)}</strong>, à l'heure de l'académie.`
            : ` Elle aura lieu <strong>${academyDateTimeLabel(session.startsAt)}</strong>, à l'heure de l'académie.`
        }`,
        body: `${session.agenda ? agendaLines(session.agenda) : ""}
<p style="margin:14px 0 0;font-size:13px;color:#64748b">Le lien de la salle ne change pas : il reste valable sur la nouvelle date.</p>`,
        actions: `${emailButton("Voir le nouveau créneau", sessionLink(session.id))} &nbsp; <a href="${agendaLink(roster.classId)}" style="color:#0f766e;font-size:14px">Mettre à jour mon calendrier</a>`,
        footnote: footer,
      }),
      text: `${subject}\n\n« ${session.title} » passe de ${before || "heure précédente"} à ${academyDateTimeLabel(session.startsAt)}.`,
    };
  }

  if (notice.kind === "absent_followup") {
    const subject = `Séance manquée — ${session.title}`;
    return {
      subject,
      html: emailLayout({
        academy: roster.academy,
        title: `Vous étiez absent(e) : ${session.title}`,
        intro: `${greeting(name)} Vous n'avez pas pu rejoindre la séance <strong>« ${escapeHtml(session.title)} »</strong> du ${academyDateTimeLabel(session.startsAt)}. Ne prenez pas de retard : le chapitre qui suit s'appuie sur ce qui y a été expliqué.`,
        body: `${session.agenda ? agendaLines(session.agenda) : ""}
<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Reprenez la leçon concernée dans le parcours, puis signalez-vous auprès de ${escapeHtml(roster.instructorName)} si un point reste obscur. Une question en cinq minutes par écrit évite souvent une séance de rattrapage.</p>`,
        actions: `${roster.trackSlug ? `${emailButton("Reprendre mes leçons", trackLink(roster.trackSlug))} &nbsp; ` : ""}<a href="${classLink(roster.classId)}" style="color:#0f766e;font-size:14px">Ouvrir ma classe</a>`,
        footnote: footer,
      }),
      text: `${subject}\n\nSéance du ${academyDateTimeLabel(session.startsAt)} manquée. Reprenez le parcours « ${roster.trackTitle} » : ${classLink(roster.classId)}`,
    };
  }

  if (notice.kind === "attendance_report") {
    const { data: marks } = await supabase
      .from("live_session_attendance")
      .select("user_id,seconds,joined_at,left_at")
      .eq("session_id", session.id);

    const attended = new Map(
      ((marks as { user_id: string; seconds: number }[] | null) ?? []).map((row) => [
        row.user_id,
        Number(row.seconds) || 0,
      ]),
    );
    const minutes = (seconds: number) => Math.max(1, Math.round(seconds / 60));
    const rows = roster.members
      .map((memberRow) => {
        const seconds = attended.get(memberRow.userId);
        const present = (seconds ?? 0) >= 120;
        return `<tr style="border-bottom:1px solid #e2e8f0">
  <td style="padding:9px 10px">${escapeHtml(memberRow.fullName)}</td>
  <td style="padding:9px 10px;color:#64748b">${escapeHtml(memberRow.email)}</td>
  <td style="padding:9px 10px;text-align:right;font-weight:600;color:${present ? "#0f766e" : "#b45309"}">${present ? `${minutes(seconds ?? 0)} min` : "absent"}</td>
</tr>`;
      })
      .join("");

    const presentCount = roster.members.filter((row) => (attended.get(row.userId) ?? 0) >= 120).length;
    const subject = `Présences — ${session.title} : ${presentCount}/${roster.members.length}`;
    return {
      subject,
      html: emailLayout({
        academy: roster.academy,
        title: `Feuille de présence — ${session.title}`,
        intro: `Séance du ${academyDateTimeLabel(session.startsAt)} : <strong>${presentCount} élève(s) présent(s) sur ${roster.members.length}</strong>. Les absents ont reçu une relance automatique.`,
        body: `<table role="presentation" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;border:1px solid #e2e8f0;font-size:14px;margin-top:16px">
  <thead><tr style="background:#f1f5f9;text-align:left"><th style="padding:9px 10px">Élève</th><th style="padding:9px 10px">Contact</th><th style="padding:9px 10px;text-align:right">Présence</th></tr></thead>
  <tbody>${rows}</tbody></table>`,
        actions: emailButton("Ouvrir la classe", `${siteUrl()}/app/formateur/classes/${roster.classId}`),
        footnote: `La présence est calculée automatiquement, minute par minute, pendant que l'élève reste en salle.`,
      }),
      text: `${subject}\n` + roster.members.map((m) => `- ${m.fullName} : ${(attended.get(m.userId) ?? 0) >= 120 ? `${minutes(attended.get(m.userId) ?? 0)} min` : "absent"}`).join("\n"),
    };
  }

  return null;
}

/* -------------------------------------------------------------------------
 * Alimentation de la file
 * ---------------------------------------------------------------------- */

type QueueEntry = {
  kind: NoticeKind;
  classId: string;
  sessionId?: string | null;
  recipients: string[];
  scheduledAt: Date;
  /** Deux placements du même évènement ne doivent pas envoyer deux fois. */
  stamp?: string;
};

export async function queueNotices(
  supabase: Reader,
  entries: QueueEntry[],
): Promise<number> {
  const rows: Record<string, unknown>[] = [];
  const seen = new Set<string>();

  for (const entry of entries) {
    for (const raw of entry.recipients) {
      const email = raw.trim().toLowerCase();
      if (!email) continue;
      const key = dedupKey(entry.kind, entry.sessionId ?? entry.classId, email, entry.stamp ?? "once");
      if (seen.has(key)) continue;
      seen.add(key);
      rows.push({
        kind: entry.kind,
        class_id: entry.classId,
        session_id: entry.sessionId ?? null,
        recipient: email,
        dedup_key: key,
        scheduled_at: entry.scheduledAt.toISOString(),
      });
    }
  }

  if (rows.length === 0) return 0;

  const { data, error } = await supabase
    .from("instructor_notices")
    .upsert(rows, { onConflict: "dedup_key", ignoreDuplicates: true })
    .select("id");

  if (error) {
    // Une file muette veut dire « aucun e-mail partira » : sans trace ici,
    // l'élève convoqué ne reçoit rien et rien ne le dit.
    console.error("[notices] mise en file", rows.length, error.code, error.message);
  }

  return ((data as { id: string }[] | null) ?? []).length;
}

/** Le programme part au placement d'une séance et à l'arrivée d'un élève. */
export async function queueProgram(
  supabase: Reader,
  roster: NoticeRoster,
  stamp: string,
): Promise<number> {
  const entries: QueueEntry[] = roster.members.map((member) => ({
    kind: "program" as const,
    classId: roster.classId,
    recipients: [member.email],
    scheduledAt: new Date(),
    stamp,
  }));
  return queueNotices(supabase, entries);
}

/** Rappel la veille à 19 h 30 de l'académie, pour chaque séance à venir. */
export async function queueReminders(
  supabase: Reader,
  classId: string,
  sessions: NoticeSession[],
  roster: NoticeRoster,
  now = new Date(),
): Promise<number> {
  const upcoming = sessions.filter(
    (session) =>
      session.status !== "cancelled" &&
      new Date(session.startsAt).getTime() > now.getTime() &&
      new Date(session.startsAt).getTime() - now.getTime() < HORIZON_DAYS * DAY_MS,
  );
  if (upcoming.length === 0 || roster.members.length === 0) return 0;

  const entries: QueueEntry[] = [];
  for (const session of upcoming) {
    entries.push({
      kind: "session_reminder",
      classId,
      sessionId: session.id,
      recipients: roster.members.map((member) => member.email),
      scheduledAt: reminderInstant(session.startsAt, now),
      // Une séance déplacée se rappelle une fois par nouveau créneau.
      stamp: session.startsAt,
    });
  }
  return queueNotices(supabase, entries);
}

/**
 * Retire les convocations qui attendent encore leur heure : une séance
 * déplacée ou annulée n'a plus à partir sous l'ancien créneau, et la ligne
 * suivante prend le relais.
 */
export async function retirePending(
  supabase: Reader,
  sessionId: string,
  reason: string,
): Promise<void> {
  await supabase
    .from("instructor_notices")
    .update({ sent_at: new Date().toISOString(), last_error: reason })
    .eq("session_id", sessionId)
    .is("sent_at", null)
    .in("kind", ["session_reminder", "session_cancelled", "session_rescheduled"]);
}

/** Annulation ou report : la file part à la minute, l'élève ne doit pas venir pour rien. */
export async function queueSessionChange(
  supabase: Reader,
  kind: Extract<NoticeKind, "session_cancelled" | "session_rescheduled">,
  roster: NoticeRoster,
  sessionId: string,
  stamp: string,
): Promise<number> {
  if (roster.members.length === 0) return 0;
  return queueNotices(supabase, [
    {
      kind,
      classId: roster.classId,
      sessionId,
      recipients: roster.members.map((member) => member.email),
      scheduledAt: new Date(),
      stamp,
    },
  ]);
}

/* -------------------------------------------------------------------------
 * Interface des actions serveur : le formateur agit, la classe est prévenue.
 * ---------------------------------------------------------------------- */

function service(): Reader | null {
  return createServiceSupabase();
}

/** Une nouvelle séance s'ajoute au calendrier : son rappel est posé. */
export async function announceSessionScheduled(
  classId: string,
  session: NoticeSession,
): Promise<void> {
  const supabase = service();
  if (!supabase) return;
  const roster = await rosterOf(supabase, classId);
  if (!roster) return;
  await queueReminders(supabase, classId, [session], roster);
}

/** Vidange complète demandée par la tâche périodique. */
export async function flushScheduledNotices(): Promise<FlushReport> {
  return flushNotices(new Date(), CRON_BUDGET_MS);
}

/**
 * Tableau complet du programme aux élèves de la classe.
 *
 * Sans `stamp`, la clé suit le jour et le nombre de séances posées : plusieurs
 * dates ajoutées le même jour ne partent pas en dix e-mails identiques, mais le
 * calendrier enrichi repart quand même une fois.
 */
export async function announceClassProgram(classId: string, stamp?: string): Promise<number> {
  const supabase = service();
  if (!supabase) return 0;
  const roster = await rosterOf(supabase, classId);
  if (!roster) return 0;

  const now = new Date();
  const key =
    stamp ??
    `calendrier ${academyDateLabel(now)} ${
      (await sessionsOf(supabase, classId, now)).length
    } séance(s)`;
  return queueProgram(supabase, roster, key);
}

/** Élève ajouté à la classe : il reçoit le programme et les dates de son cours. */
export async function announceJoin(classId: string, email: string): Promise<void> {
  const supabase = service();
  if (!supabase) return;
  await queueNotices(supabase, [
    {
      kind: "program",
      classId,
      recipients: [email],
      scheduledAt: new Date(),
      stamp: "arrivée",
    },
  ]);
}

/**
 * Séance annulée ou reportée : ce qui attendait encore à l'ancien créneau est
 * retiré, les élèves inscrits apprennent le changement avant de se connecter.
 */
export async function announceSessionChange(
  sessionId: string,
  kind: "cancelled" | "moved",
): Promise<void> {
  const supabase = service();
  if (!supabase) return;

  const session = await sessionOf(supabase, sessionId);
  if (!session) return;

  const { data: row } = await supabase
    .from("live_sessions")
    .select("class_id")
    .eq("id", sessionId)
    .maybeSingle<{ class_id: string | null }>();
  if (!row?.class_id) return;

  const roster = await rosterOf(supabase, row.class_id);
  if (!roster) return;

  await retirePending(supabase, sessionId, kind === "moved" ? "créneau déplacé" : "séance annulée");

  await queueSessionChange(
    supabase,
    kind === "cancelled" ? "session_cancelled" : "session_rescheduled",
    roster,
    sessionId,
    // Le même créneau déplacé deux fois n'annonce qu'un seul nouveau créneau.
    kind === "moved" ? session.startsAt : "une fois",
  );

  // Le nouveau créneau a droit à son propre rappel.
  if (kind === "moved") await queueReminders(supabase, row.class_id, [session], roster);
}

/* -------------------------------------------------------------------------
 * Vidange de la file
 * ---------------------------------------------------------------------- */

export type FlushReport = {
  due: number;
  sent: number;
  failed: number;
  deferred: number;
  enqueued: number;
};

/**
 * Place les lignes qui manquent : rappels des séances déjà inscrites au
 * calendrier, rapports de présence et relances des absants. Idempotent — les
 * lignes déjà posées sont ignorées par leur clé.
 */
async function syncQueue(supabase: Reader, now: Date): Promise<number> {
  const { data: upcoming } = await supabase
    .from("live_sessions")
    .select("id,class_id,starts_at,ends_at,status,previous_starts_at,title,agenda")
    .in("status", ["scheduled", "live"])
    .gt("starts_at", now.toISOString())
    .lte("starts_at", new Date(now.getTime() + HORIZON_DAYS * DAY_MS).toISOString())
    .order("starts_at")
    .limit(120);

  const sessionsByClass = new Map<string, NoticeSession[]>();
  for (const row of (upcoming as Record<string, unknown>[] | null) ?? []) {
    if (!row.class_id) continue;
    const list = sessionsByClass.get(String(row.class_id)) ?? [];
    list.push({
      id: String(row.id),
      title: String(row.title),
      agenda: String(row.agenda ?? ""),
      startsAt: String(row.starts_at),
      endsAt: String(row.ends_at),
      status: String(row.status),
      previousStartsAt: (row.previous_starts_at as string | null) ?? null,
    });
    sessionsByClass.set(String(row.class_id), list);
  }

  let enqueued = 0;
  for (const [classId, sessions] of sessionsByClass) {
    const roster = await rosterOf(supabase, classId);
    if (!roster || roster.members.length === 0) continue;
    enqueued += await queueReminders(supabase, classId, sessions, roster, now);
  }

  // Séances CLOSES par le formateur dont la présence n'a pas encore été mise
  // en file. `ends_at` n'est que l'heure annoncée : une salle encore ouverte
  // (`live`) n'est pas terminée, même passée son créneau, et son rapport ne
  // part pas tant que l'enseignant ne l'a pas clôturée.
  const { data: finished } = await supabase
    .from("live_sessions")
    .select("id,class_id,ends_at")
    .in("status", ["ended", "cancelled"])
    .lte("ends_at", new Date(now.getTime() - REPORT_LAG_MS).toISOString())
    .gte("ends_at", new Date(now.getTime() - 3 * DAY_MS).toISOString())
    .order("ends_at", { ascending: false })
    .limit(60);

  for (const row of (finished as { id: string; class_id: string | null; ends_at: string }[] | null) ?? []) {
    if (!row.class_id) continue;
    const roster = await rosterOf(supabase, row.class_id);
    if (!roster || roster.members.length === 0) continue;

    const { data: existing } = await supabase
      .from("instructor_notices")
      .select("id")
      .eq("session_id", row.id)
      .eq("kind", "attendance_report")
      .maybeSingle();
    if (existing) continue;

    const { data: marks } = await supabase
      .from("live_session_attendance")
      .select("user_id,seconds")
      .eq("session_id", row.id);
    const secondsByUser = new Map(
      ((marks as { user_id: string; seconds: number }[] | null) ?? []).map((mark) => [
        mark.user_id,
        Number(mark.seconds) || 0,
      ]),
    );

    const scheduledAt = new Date(new Date(row.ends_at).getTime() + REPORT_LAG_MS);
    const absentees = roster.members
      .filter((member) => (secondsByUser.get(member.userId) ?? 0) < 120)
      .map((member) => member.email);

    enqueued += await queueNotices(supabase, [
      {
        kind: "attendance_report",
        classId: row.class_id,
        sessionId: row.id,
        recipients: roster.instructorEmail ? [roster.instructorEmail] : [],
        scheduledAt,
      },
      {
        kind: "absent_followup",
        classId: row.class_id,
        sessionId: row.id,
        recipients: absentees,
        // Le rappel d'absence attend le rapport : l'enseignant répond d'abord.
        scheduledAt: new Date(scheduledAt.getTime() + 10 * 60_000),
      },
    ]);
  }

  return enqueued;
}

/** Une ligne due, telle que la file la stocke. */
const BATCH = 60;

/** Envois menés de front : vingt-cinq élèves partent en quelques secondes. */
const PARALLEL = 6;

/** Budget d'un envoi déclenché par une action du formateur : pas de formulaire bloqué. */
const INLINE_BUDGET_MS = 14_000;

/** Budget de la tâche de nuit : la file se vide jusqu'à la limite du serveur. */
const CRON_BUDGET_MS = 25_000;

type Delivery = "sent" | "void" | "failed";

async function deliver(
  supabase: Reader,
  notice: NoticeRow,
  now: Date,
): Promise<Delivery> {
  let result: EmailResult | null = null;
  try {
    const draft = await draftOf(supabase, notice, now);
    if (!draft) {
      // Plus rien à annoncer : séance supprimée, élève sorti de la classe.
      await supabase
        .from("instructor_notices")
        .update({ sent_at: now.toISOString(), last_error: "sans objet" })
        .eq("id", notice.id);
      return "void";
    }
    result = await sendEmail({ to: notice.recipient, ...draft });
  } catch (error) {
    console.error("[formateur] notification", notice.kind, error);
    result = null;
  }

  if (result?.sent || result?.demo) {
    // Le mode démo (clé d'envoi absente) consomme la ligne : elle est tracée en
    // log, et une file locale ne doit pas s'engorger de « non remis ».
    await supabase
      .from("instructor_notices")
      .update({
        sent_at: now.toISOString(),
        attempts: notice.attempts + 1,
        last_error: result.sent ? null : "mode démo",
      })
      .eq("id", notice.id);
    return "sent";
  }

  const reason = (result?.error ?? "envoi impossible").slice(0, 180);

  // Une clé d'envoi révoquée ou absente est un défaut du site, pas un destinataire
  // injoignable : le serveur refuse avant d'émettre. Brûler les tentatives ici
  // ferait perdre la convocation, alors qu'elle partira toute seule dès que la
  // clé sera remise en place.
  const siteBlocked = /api key|unauthorized|forbidden|401|sender|not valid|rejected/i.test(
    reason,
  );

  await supabase
    .from("instructor_notices")
    .update({
      attempts: siteBlocked ? notice.attempts : notice.attempts + 1,
      last_error: reason,
    })
    .eq("id", notice.id);
  return "failed";
}

/**
 * Envoie les lignes venues à l'heure, par poignées menées de front.
 *
 * Un échec réseau ne consomme pas la file : la ligne reste due et son compteur
 * d'essais la retire après quatre tentatives. Ce que le budget n'a pas atteint
 * reste en file — la tâche du soir le reprend.
 */
export async function flushNotices(
  now = new Date(),
  budgetMs = INLINE_BUDGET_MS,
): Promise<FlushReport> {
  const supabase = createServiceSupabase();
  const report: FlushReport = { due: 0, sent: 0, failed: 0, deferred: 0, enqueued: 0 };
  if (!supabase) return report;

  report.enqueued = await syncQueue(supabase, now);

  const { data: rows } = await supabase
    .from("instructor_notices")
    .select("id,kind,class_id,session_id,recipient,dedup_key,scheduled_at,attempts")
    .is("sent_at", null)
    .lte("scheduled_at", now.toISOString())
    .lt("attempts", 4)
    .order("scheduled_at")
    .limit(BATCH);

  const due = (rows as NoticeRow[] | null) ?? [];
  report.due = due.length;

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

  return report;
}

/**
 * Prévenue, la classe : les annonces déclenchées par une action du formateur
 * partent tout de suite, la tâche du soir ne servant plus que de filet.
 */
export async function notifyNow(): Promise<FlushReport> {
  return flushNotices(new Date(), INLINE_BUDGET_MS);
}

/** État de la file d'une classe, pour le tableau de bord du formateur. */
export async function noticesSummary(
  classId: string,
): Promise<{ kind: NoticeKind; due: number; sent: number; failed: number; error: string | null }[]> {
  const supabase = createServiceSupabase();
  if (!supabase) return [];

  const { data } = await supabase
    .from("instructor_notices")
    .select("kind,sent_at,last_error")
    .eq("class_id", classId);

  const byKind = new Map<string, { due: number; sent: number; failed: number; error: string | null }>();
  for (
    const row of
      (data as { kind: NoticeKind; sent_at: string | null; last_error: string | null }[] | null) ?? []
  ) {
    const bucket = byKind.get(row.kind) ?? { due: 0, sent: 0, failed: 0, error: null };
    if (row.sent_at) {
      // « sans objet » = ligne retirée avant l'envoi (séance annulée, élève sorti).
      // La compter comme envoyée ferait croire à l'enseignant que ses élèves ont
      // reçu un message qui n'est jamais parti.
      if (!row.last_error || row.last_error === "mode démo") bucket.sent += 1;
    } else {
      bucket.due += 1;
      // Une ligne en échec répété ne dit rien d'elle-même : le motif du
      // refus remonte ici plutôt que de rester dans les journaux du serveur.
      if (row.last_error) {
        bucket.failed += 1;
        bucket.error ??= row.last_error;
      }
    }
    byKind.set(row.kind, bucket);
  }

  return [...byKind.entries()].map(([kind, bucket]) => ({ kind: kind as NoticeKind, ...bucket }));
}
