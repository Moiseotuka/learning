"use server";

import { randomUUID } from "node:crypto";

import { requireUser } from "@/lib/auth/dal";
import { roomNameFor } from "@/lib/live/provider";
import {
  settleInstructorSubscription,
  startInstructorSubscription,
  type InstructorCheckout,
} from "@/lib/instructor/checkout";
import {
  activeSeatLimit,
  getInstructorStatus,
  invitationLink,
} from "@/lib/instructor/queries";
import {
  invitationEmail,
  invitationSignupLink,
} from "@/lib/instructor/email-templates";
import {
  announceClassProgram,
  announceJoin,
  announceSessionChange,
  announceSessionScheduled,
  notifyNow,
  type NoticeSession,
} from "@/lib/instructor/notices";
import { zonedInstant } from "@/lib/instructor/timezone";
import { findAccountByEmail } from "@/lib/supabase/admin";
import { sendEmail } from "@/lib/email/send";
import { createServiceSupabase } from "@/lib/supabase/service";
import { messages } from "@/i18n";

const t = messages.formateur;

export type FormState = {
  status: "idle" | "success" | "error";
  message?: string;
  notice?: string;
  field?: string;
};

function readTextValue(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

/** Code d'accès lisible à la voix : sans 0/O ni 1/I. */
function newJoinCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = new Uint32Array(8);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (byte) => alphabet[byte % alphabet.length]).join("");
}

/**
 * Places prises chez ce formateur. Seuls les élèves encore dans la classe
 * comptent : un apprenant sorti ou renvoyé libère sa place, sinon le formateur
 * ne pourrait plus jamais en accueillir d'autre sur un plan plein.
 */
async function seatsUsed(supabase: NonNullable<ReturnType<typeof createServiceSupabase>>, instructorId: string) {
  const { data: classes } = await supabase
    .from("instructor_classes")
    .select("id")
    .eq("instructor_id", instructorId)
    .eq("status", "active");

  const classIds = (classes as { id: string }[] | null) ?? [];
  if (classIds.length === 0) return 0;

  const { count } = await supabase
    .from("instructor_class_members")
    .select("user_id", { count: "exact", head: true })
    .in("class_id", classIds.map((row) => row.id))
    .eq("status", "active");

  return count ?? 0;
}

/** La souscription passe par le même dialogue que l'achat d'un niveau. */
export async function subscribeAsInstructor(
  _prevState: InstructorCheckout | undefined,
  formData: FormData,
): Promise<InstructorCheckout> {
  try {
    const user = await requireUser("/app/profil");
    const planId = readTextValue(formData, "planId");
    const trackIds = formData
      .getAll("trackIds")
      .filter((value): value is string => typeof value === "string" && value.length > 0);

    return await startInstructorSubscription({
      userId: user.id,
      email: user.email ?? null,
      planId,
      trackIds,
    });
  } catch (error) {
    const digest = (error as { digest?: string } | null)?.digest;
    if (typeof digest === "string" && digest.startsWith("NEXT_REDIRECT")) throw error;
    console.error("[formateur] souscription", error);
    return { mode: "error", reason: "failed" };
  }
}

/** Reprise d'une souscription interrompue : le paiement a eu lieu, la table non. */
export async function resumeInstructorSubscription(subscriptionId: string) {
  const user = await requireUser("/app/profil");
  const supabase = createServiceSupabase();
  if (!supabase) return { ok: false, paid: false, status: "PENDING" };
  return settleInstructorSubscription(supabase, {
    subscriptionId,
    expectUserId: user.id,
  });
}

export async function createClass(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app/profil");
    const status = await getInstructorStatus(user.id);
    if (!status.isActive) return { status: "error", message: t.errors.notInstructor };

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const title = readTextValue(formData, "title");
    const academy = readTextValue(formData, "academy");
    const trackId = readTextValue(formData, "trackId");
    const description = readTextValue(formData, "description");
    // L'académie signe les invitations et les convocations : une classe sans nom
    // d'école enverrait des e-mails au nom de la plateforme, ce que le formateur
    // ne veut pas.
    if (title.length < 3 || academy.length < 2 || !trackId) {
      return { status: "error", message: t.errors.missingAcademy, field: academy.length < 2 ? "academy" : "title" };
    }

    // La classe doit porter un parcours que le formateur a le droit d'enseigner.
    if (!status.tracks.some((track) => track.id === trackId)) {
      return { status: "error", message: t.errors.forbidden, field: "trackId" };
    }

    const { error } = await supabase.from("instructor_classes").insert({
      instructor_id: user.id,
      track_id: trackId,
      title,
      academy,
      description,
      join_code: newJoinCode(),
    });
    if (error) return { status: "error", message: t.errors.failed };

    return { status: "success", notice: "classeCreee" };
  } catch (error) {
    console.error("[formateur] classe", error);
    return { status: "error", message: t.errors.failed };
  }
}

export async function archiveClass(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app/profil");
    const classId = readTextValue(formData, "classId");
    if (!classId) return { status: "error", message: t.errors.failed };

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { data, error } = await supabase
      .from("instructor_classes")
      .update({ status: "archived" })
      .eq("id", classId)
      .eq("instructor_id", user.id)
      .select("id");
    if (error || !data || data.length === 0) {
      return { status: "error", message: t.errors.forbidden };
    }
    return { status: "success", notice: "archivee" };
  } catch (error) {
    console.error("[formateur] archivage", error);
    return { status: "error", message: t.errors.failed };
  }
}

export async function inviteStudent(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app/profil");
    const status = await getInstructorStatus(user.id);
    if (!status.isActive) return { status: "error", message: t.errors.notInstructor };

    const classId = readTextValue(formData, "classId");
    const email = readTextValue(formData, "email").toLowerCase();
    if (!classId || !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) {
      return { status: "error", message: t.errors.invalidEmail, field: "email" };
    }

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { data: klass } = await supabase
      .from("instructor_classes")
      .select("id,title,academy,instructor_id,track_id,tracks(title)")
      .eq("id", classId)
      .eq("instructor_id", user.id)
      .maybeSingle<{
        id: string;
        title: string;
        academy: string;
        instructor_id: string;
        track_id: string;
        tracks: { title: string } | null;
      }>();
    if (!klass) return { status: "error", message: t.errors.forbidden };

    if (status.seatsUsed >= (status.subscription?.seatsLimit ?? 0)) {
      return {
        status: "error",
        message: t.students.seatsFull.replace(
          "{limit}",
          String(status.subscription?.seatsLimit ?? 0),
        ),
      };
    }

    const { data: duplicate } = await supabase
      .from("instructor_class_invites")
      .select("id")
      .eq("class_id", classId)
      .eq("email", email)
      .eq("status", "pending")
      .maybeSingle();
    if (duplicate) return { status: "error", message: t.errors.alreadyInvited };

    const token = randomUUID();
    const { error } = await supabase
      .from("instructor_class_invites")
      .insert({ class_id: classId, email, token });
    if (error) return { status: "error", message: t.errors.failed };

    const trackTitle = klass.tracks?.title ?? klass.title;
    const academy = klass.academy || klass.title;

    const { data: profile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", user.id)
      .maybeSingle<{ full_name: string | null }>();
    const instructorName = profile?.full_name ?? academy;

    // L'adresse connaît déjà la plateforme : inutile de lui faire refuser une
    // inscription. La place est prise tout de suite, l'e-mail n'annonce plus
    // qu'une entrée en classe déjà faite.
    const account = await findAccountByEmail(email);

    if (account?.confirmed) {
      const { data: existingUser } = await supabase
        .from("profiles")
        .select("id")
        .eq("email", email)
        .maybeSingle<{ id: string }>();
      const studentId = existingUser?.id;
      if (!studentId) {
        await supabase.from("instructor_class_invites").delete().eq("token", token);
        return { status: "error", message: t.errors.failed };
      }

      const added = await attachStudent(
        supabase,
        classId,
        klass.instructor_id,
        studentId,
        "invite",
        email,
      );
      if (!added.ok) {
        await supabase.from("instructor_class_invites").delete().eq("token", token);
        return { status: "error", message: attachRefusal(added, "formateur") };
      }

      await supabase
        .from("instructor_class_invites")
        .update({ status: "accepted", accepted_at: new Date().toISOString() })
        .eq("token", token);

      // `attachStudent` a mis le programme à la file : l'élève reçoit la
      // convocation de sa classe, pas un second e-mail redondant.
      return { status: "success", notice: "eleveInscrit" };
    }

    // Compte créé mais adresse non confirmée : on ne peut pas l'inscrire à
    // sa place. Le lien mène à la classe, l'élève confirmera d'abord son compte.
    const ctaHref =
      account === null ? invitationSignupLink(token) : invitationLink(token);

    const mail = await sendEmail({
      to: email,
      subject: `${academy} — invitation à la classe « ${klass.title} »`,
      html: invitationEmail({
        academy,
        className: klass.title,
        trackTitle,
        instructorName,
        body:
          account === null
            ? `<p><strong>${academy}</strong> vous invite dans sa classe « ${klass.title} », autour du parcours « ${trackTitle} ».</p>
<p>Vous n'avez pas encore de compte ? Créez-le avec <strong>${email}</strong> — c'est l'adresse que votre formateur a saisie, et la classe s'ouvrira dessus tout de suite.</p>`
            : `<p><strong>${academy}</strong> vous inscrit dans sa classe « ${klass.title} », autour du parcours « ${trackTitle} ».</p>
<p>Votre compte existe mais n'est pas encore confirmé : confirmez-le, puis ouvrez le lien ci-dessous pour rejoindre la classe.</p>`,
        ctaLabel: "Rejoindre la classe",
        ctaHref,
      }),
      text: `Rejoignez la classe « ${klass.title} » de ${academy} : ${ctaHref}`,
    });

    return {
      status: "success",
      notice: mail.sent ? "inviteEnvoye" : "inviteSansEmail",
    };
  } catch (error) {
    console.error("[formateur] invitation", error);
    return { status: "error", message: t.errors.failed };
  }
}

export async function removeStudent(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app/profil");
    const classId = readTextValue(formData, "classId");
    const studentId = readTextValue(formData, "studentId");
    if (!classId || !studentId) return { status: "error", message: t.errors.failed };

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { data: klass } = await supabase
      .from("instructor_classes")
      .select("instructor_id")
      .eq("id", classId)
      .maybeSingle<{ instructor_id: string }>();
    if (klass?.instructor_id !== user.id) {
      return { status: "error", message: t.errors.forbidden };
    }

    const { error } = await supabase
      .from("instructor_class_members")
      .update({ status: "removed" })
      .eq("class_id", classId)
      .eq("user_id", studentId);
    if (error) return { status: "error", message: t.errors.failed };

    return { status: "success", notice: "eleveRetire" };
  } catch (error) {
    console.error("[formateur] retrait", error);
    return { status: "error", message: t.errors.failed };
  }
}

/** Un apprenant rejoint avec le code donné par son formateur. */
export async function joinClassByCode(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app");
    const code = readTextValue(formData, "code").toUpperCase();
    if (code.length < 6) return { status: "error", message: t.errors.codeUnknown };

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { data: klass } = await supabase
      .from("instructor_classes")
      .select("id,instructor_id,status")
      .eq("join_code", code)
      .maybeSingle<{ id: string; instructor_id: string; status: string }>();
    if (!klass || klass.status !== "active") {
      return { status: "error", message: t.errors.codeUnknown };
    }

    const added = await attachStudent(
      supabase,
      klass.id,
      klass.instructor_id,
      user.id,
      "code",
      user.email ?? null,
    );
    if (!added.ok) return { status: "error", message: attachRefusal(added, "eleve") };
    return { status: "success", notice: "rejoint" };
  } catch (error) {
    console.error("[classe] code d'accès", error);
    return { status: "error", message: t.errors.failed };
  }
}

/** Un apprenant rejoint depuis le lien reçu par e-mail. */
export async function acceptInvitation(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app");
    const token = readTextValue(formData, "token");
    if (!token) return { status: "error", message: t.errors.inviteExpired };

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { data: invite } = await supabase
      .from("instructor_class_invites")
      .select("id,class_id,status,expires_at,email,instructor_classes(instructor_id,status)")
      .eq("token", token)
      .maybeSingle<{
        id: string;
        class_id: string;
        status: string;
        expires_at: string;
        email: string;
        instructor_classes: { instructor_id: string; status: string } | null;
      }>();

    if (!invite || invite.status !== "pending") {
      return { status: "error", message: t.errors.inviteExpired };
    }
    if (new Date(invite.expires_at) < new Date()) {
      await supabase
        .from("instructor_class_invites")
        .update({ status: "expired" })
        .eq("id", invite.id);
      return { status: "error", message: t.errors.inviteExpired };
    }
    if (!invite.instructor_classes) {
      return { status: "error", message: t.errors.codeUnknown };
    }

    const added = await attachStudent(
      supabase,
      invite.class_id,
      invite.instructor_classes.instructor_id,
      user.id,
      "invite",
      user.email ?? invite.email,
    );
    if (!added.ok) return { status: "error", message: attachRefusal(added, "eleve") };

    await supabase
      .from("instructor_class_invites")
      .update({ status: "accepted", accepted_at: new Date().toISOString() })
      .eq("id", invite.id);

    return { status: "success", notice: "rejoint" };
  } catch (error) {
    console.error("[classe] invitation", error);
    return { status: "error", message: t.errors.failed };
  }
}

export async function leaveClass(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app");
    const classId = readTextValue(formData, "classId");
    if (!classId) return { status: "error", message: t.errors.failed };

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { error } = await supabase
      .from("instructor_class_members")
      .update({ status: "removed" })
      .eq("class_id", classId)
      .eq("user_id", user.id)
      .eq("status", "active");
    if (error) return { status: "error", message: t.errors.failed };

    return { status: "success", notice: "partie" };
  } catch (error) {
    console.error("[classe] départ", error);
    return { status: "error", message: t.errors.failed };
  }
}

type ServiceClient = NonNullable<ReturnType<typeof createServiceSupabase>>;

type AttachFailure = {
  reason: "already" | "lapsed" | "full" | "failed";
  seatsLimit?: number;
};

/**
 * Le même refus ne se dit pas de la même façon : la place manquée est un
 * problème d'abonnement pour le formateur, alors que l'élève, lui, n'a aucun
 * abonnement — la lui reprocher lui ferait croire qu'il doit payer.
 */
function attachRefusal(failure: AttachFailure, who: "formateur" | "eleve"): string {
  if (failure.reason === "already") return t.errors.alreadyMember;
  if (failure.reason === "failed") return t.errors.failed;
  if (failure.reason === "full") {
    const limit = String(failure.seatsLimit ?? 0);
    return who === "formateur"
      ? t.students.seatsFull.replace("{limit}", limit)
      : t.myClass.classFull.replace("{limit}", limit);
  }
  return who === "formateur" ? t.students.seatsLapsed : t.myClass.classClosed;
}

/**
 * Inscrit un apprenant dans la limite des places de l'abonnement du formateur.
 * La place est vérifiée ici et dans `granted_category_ids()` : l'une sans
 * l'autre laisserait passer un quinzième élève sur un plan de quatorze.
 *
 * L'entrée en classe met le programme à la file (`announceJoin`) : l'élève sait
 * quand il entre, sans que le formateur ait à penser à l'e-mail.
 */
async function attachStudent(
  supabase: ServiceClient,
  classId: string,
  instructorId: string,
  studentId: string,
  source: "code" | "invite",
  email: string | null,
): Promise<{ ok: true } | ({ ok: false } & AttachFailure)> {
  const { data: already } = await supabase
    .from("instructor_class_members")
    .select("status")
    .eq("class_id", classId)
    .eq("user_id", studentId)
    .maybeSingle<{ status: string }>();

  if (already?.status === "active") {
    return { ok: false, reason: "already" };
  }

  const seatsLimit = await activeSeatLimit(instructorId);
  if (seatsLimit === null) {
    return { ok: false, reason: "lapsed" };
  }
  const used = await seatsUsed(supabase, instructorId);
  if (used >= seatsLimit) {
    return { ok: false, reason: "full", seatsLimit };
  }

  if (already) {
    const { error } = await supabase
      .from("instructor_class_members")
      .update({ status: "active", joined_at: new Date().toISOString(), source })
      .eq("class_id", classId)
      .eq("user_id", studentId);
    if (error) {
      console.error("[classe] réintégration d'élève", classId, error.code, error.message);
      return { ok: false, reason: "failed" };
    }
    if (email) {
      await announceJoin(classId, email);
      await notifyNow();
    }
    return { ok: true };
  }

  const { error } = await supabase.from("instructor_class_members").insert({
    class_id: classId,
    user_id: studentId,
    source,
  });
  if (error) {
    console.error("[classe] ajout d'élève par code", classId, error.code, error.message);
    return { ok: false, reason: "failed" };
  }
  if (email) {
    await announceJoin(classId, email);
    await notifyNow();
  }
  return { ok: true };
}

/**
 * Durée ANNONCÉE d'une séance, en millisecondes.
 *
 * L'heure n'est pas limitée : la valeur saisie sert à la convocation et au
 * calendrier, elle ne clôt pas la salle — c'est le formateur qui la ferme.
 * Seule une borne de lisibilité est posée (24 h), pour qu'aucun créneau
 * aberrant ne soit envoyé aux élèves.
 */
function announcedDurationMs(minutes: number): number {
  const value = Math.round(Number(minutes));
  const safe = Number.isFinite(value) && value > 0 ? value : 60;
  return Math.min(safe, 1_440) * 60_000;
}

export async function createLiveSession(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app/formateur");
    const status = await getInstructorStatus(user.id);
    if (!status.isActive) return { status: "error", message: t.errors.notInstructor };

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const title = readTextValue(formData, "title");
    const classId = readTextValue(formData, "classId");
    const date = readTextValue(formData, "date");
    const time = readTextValue(formData, "time");
    const minutes = Number(readTextValue(formData, "minutes") || 60);
    const agenda = readTextValue(formData, "agenda");

    if (title.length < 3 || !date || !time || !Number.isFinite(minutes)) {
      return { status: "error", message: t.errors.missingFields, field: "title" };
    }

    // L'horaire est dit à l'heure de l'académie, pas à celle du serveur :
    // sinon la salle ouvrirait à contretemps de la convocation envoyée.
    const startsAt = zonedInstant(date, time);
    if (!startsAt) {
      return { status: "error", message: t.errors.badDateTime, field: "date" };
    }
    if (startsAt.getTime() < Date.now() - 12 * 3_600_000) {
      return { status: "error", message: t.errors.pastDate, field: "time" };
    }
    const endsAt = new Date(
      startsAt.getTime() + announcedDurationMs(minutes),
    );

    let trackId: string | null = null;
    if (classId) {
      const { data: klass } = await supabase
        .from("instructor_classes")
        .select("track_id,instructor_id")
        .eq("id", classId)
        .maybeSingle<{ track_id: string; instructor_id: string }>();
      if (!klass || klass.instructor_id !== user.id) {
        return { status: "error", message: t.errors.forbidden, field: "classId" };
      }
      trackId = klass.track_id;
    }

    const id = randomUUID();
    const { error } = await supabase.from("live_sessions").insert({
      id,
      instructor_id: user.id,
      class_id: classId || null,
      track_id: trackId,
      title,
      agenda,
      starts_at: startsAt.toISOString(),
      ends_at: endsAt.toISOString(),
      room_name: roomNameFor(id, title),
    });
    if (error) return { status: "error", message: t.errors.failed };

    if (classId) {
      const session: NoticeSession = {
        id,
        title,
        agenda,
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        status: "scheduled",
        previousStartsAt: null,
      };
      // Le calendrier complet repart, puis le rappel de la veille est posé.
      await announceClassProgram(classId);
      await announceSessionScheduled(classId, session);
      await notifyNow();
    }

    return { status: "success", notice: "seancePlanifiee" };
  } catch (error) {
    console.error("[live] planification", error);
    return { status: "error", message: t.errors.failed };
  }
}

/** Déplacer une séance : l'ancien créneau est retiré, le nouveau est annoncé. */
export async function updateLiveSession(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app/formateur");
    const sessionId = readTextValue(formData, "sessionId");
    const title = readTextValue(formData, "title");
    const date = readTextValue(formData, "date");
    const time = readTextValue(formData, "time");
    const minutes = Number(readTextValue(formData, "minutes") || 60);
    const agenda = readTextValue(formData, "agenda");

    if (!sessionId || title.length < 3 || !date || !time) {
      return { status: "error", message: t.errors.missingFields, field: "title" };
    }

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { data: current } = await supabase
      .from("live_sessions")
      .select("id,class_id,starts_at,status")
      .eq("id", sessionId)
      .eq("instructor_id", user.id)
      .maybeSingle<{ id: string; class_id: string | null; starts_at: string; status: string }>();
    if (!current) return { status: "error", message: t.errors.forbidden };
    if (current.status === "cancelled") {
      return { status: "error", message: t.errors.sessionCancelled };
    }

    const startsAt = zonedInstant(date, time);
    if (!startsAt) {
      return { status: "error", message: t.errors.badDateTime, field: "date" };
    }

    const endsAt = new Date(
      startsAt.getTime() + announcedDurationMs(minutes),
    );

    const { error } = await supabase
      .from("live_sessions")
      .update({
        title,
        agenda,
        starts_at: startsAt.toISOString(),
        ends_at: endsAt.toISOString(),
        previous_starts_at: current.starts_at,
        status: "scheduled",
      })
      .eq("id", sessionId)
      .eq("instructor_id", user.id);
    if (error) return { status: "error", message: t.errors.failed };

    if (current.class_id) {
      await announceSessionChange(sessionId, "moved");
      await announceClassProgram(current.class_id);
      await notifyNow();
    }

    return { status: "success", notice: "seanceDeplacee" };
  } catch (error) {
    console.error("[live] déplacement de séance", error);
    return { status: "error", message: t.errors.failed };
  }
}

export async function setLiveSessionStatus(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app/formateur");
    const sessionId = readTextValue(formData, "sessionId");
    const next = readTextValue(formData, "status");
    if (!sessionId || !["live", "ended", "cancelled"].includes(next)) {
      return { status: "error", message: t.errors.failed };
    }

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { data: current } = await supabase
      .from("live_sessions")
      .select("id,class_id,status")
      .eq("id", sessionId)
      .eq("instructor_id", user.id)
      .maybeSingle<{ id: string; class_id: string | null; status: string }>();
    if (!current) return { status: "error", message: t.errors.forbidden };

    const { error } = await supabase
      .from("live_sessions")
      .update({
        status: next,
        cancelled_at: next === "cancelled" ? new Date().toISOString() : null,
      })
      .eq("id", sessionId)
      .eq("instructor_id", user.id);
    if (error) return { status: "error", message: t.errors.failed };

    if (next === "cancelled" && current.class_id) {
      await announceSessionChange(sessionId, "cancelled");
      await notifyNow();
    }

    const notice =
      next === "live" ? "seanceOuverte" : next === "ended" ? "seanceClose" : "seanceAnnulee";
    return { status: "success", notice };
  } catch (error) {
    console.error("[live] statut de séance", error);
    return { status: "error", message: t.errors.failed };
  }
}

/** Le formateur renvoie le calendrier complet de sa classe, à la demande. */
export async function sendClassProgram(
  _prevState: FormState | undefined,
  formData: FormData,
): Promise<FormState> {
  try {
    const user = await requireUser("/app/formateur");
    const classId = readTextValue(formData, "classId");
    if (!classId) return { status: "error", message: t.errors.failed };

    const supabase = createServiceSupabase();
    if (!supabase) return { status: "error", message: t.errors.failed };

    const { data: klass } = await supabase
      .from("instructor_classes")
      .select("id")
      .eq("id", classId)
      .eq("instructor_id", user.id)
      .maybeSingle<{ id: string }>();
    if (!klass) return { status: "error", message: t.errors.forbidden };

    const queued = await announceClassProgram(
      classId,
      `manuel ${new Date().toISOString().slice(0, 16)}`,
    );
    if (queued === 0) return { status: "error", message: t.errors.noStudents };

    await notifyNow();
    return { status: "success", notice: "programmeEnvoye" };
  } catch (error) {
    console.error("[formateur] envoi du programme", error);
    return { status: "error", message: t.errors.failed };
  }
}

/**
 * Présence en séance : battement toutes les 30 secondes pendant que la salle
 * est ouverte, départ à la fermeture. Le total est porté côté serveur pour
 * qu'un apprenant ne se déclare pas présent sans être entré.
 */
export async function reportLivePresence(
  sessionId: string,
  seconds: number,
  leaving = false,
): Promise<{ ok: boolean }> {
  try {
    const user = await requireUser("/app");
    const supabase = createServiceSupabase();
    if (!supabase) return { ok: false };

    const { data: session } = await supabase
      .from("live_sessions")
      .select("id,instructor_id,class_id")
      .eq("id", sessionId)
      .maybeSingle<{ id: string; instructor_id: string; class_id: string | null }>();
    if (!session) return { ok: false };

    if (session.instructor_id !== user.id) {
      if (!session.class_id) return { ok: false };
      const { data: member } = await supabase
        .from("instructor_class_members")
        .select("user_id")
        .eq("class_id", session.class_id)
        .eq("user_id", user.id)
        .eq("status", "active")
        .maybeSingle();
      if (!member) return { ok: false };
    }

    const delta = Math.min(Math.max(Math.round(seconds) || 0, 0), 120);
    const { data: existing } = await supabase
      .from("live_session_attendance")
      .select("seconds")
      .eq("session_id", sessionId)
      .eq("user_id", user.id)
      .maybeSingle<{ seconds: number }>();

    if (existing) {
      const { error } = await supabase
        .from("live_session_attendance")
        .update({
          seconds: existing.seconds + delta,
          left_at: leaving ? new Date().toISOString() : null,
        })
        .eq("session_id", sessionId)
        .eq("user_id", user.id);
      if (error) return { ok: false };
      return { ok: true };
    }

    const { error } = await supabase.from("live_session_attendance").insert({
      session_id: sessionId,
      user_id: user.id,
      seconds: delta,
      left_at: leaving ? new Date().toISOString() : null,
    });
    return { ok: !error };
  } catch (error) {
    console.error("[live] présence", error);
    return { ok: false };
  }
}

