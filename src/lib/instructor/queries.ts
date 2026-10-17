import { cache } from "react";

import { site } from "@/config/site";
import {
  DOWNGRADE_AFTER_EXPIRY,
  FREE_CLASS_SEATS,
  type HostTier,
} from "@/lib/live/policy";
import type { InstructorPlan } from "@/lib/instructor/plans";
import { createServerSupabase } from "@/lib/supabase/server";
import { createServiceSupabase } from "@/lib/supabase/service";

type Reader = NonNullable<ReturnType<typeof createServiceSupabase>>;

type Person = { fullName: string; email: string | null };

/**
 * `profiles` n'est relié par aucune clé étrangère aux tables du lot formateur
 * (leurs colonnes d'utilisateur pointent sur `auth.users`) : PostgREST refuse
 * de l'embarquer et renvoie PGRST200, ce qui vide la requête entière. Les
 * identités se lisent donc dans une seconde requête.
 */
async function peopleOf(supabase: Reader, ids: string[]): Promise<Map<string, Person>> {
  const unique = [...new Set(ids.filter(Boolean))];
  const people = new Map<string, Person>();
  if (unique.length === 0) return people;

  const { data } = await supabase
    .from("profiles")
    .select("id,full_name,email")
    .in("id", unique);

  for (const row of (data as
    | { id: string; full_name: string | null; email: string | null }[]
    | null) ?? []) {
    people.set(row.id, {
      // Le profil peut être sans nom : l'appelant choisit le libellé de repli,
      // « Apprenant » ou « Formateur » selon le rôle qu'il affiche.
      fullName: row.full_name?.trim() ?? "",
      email: row.email ?? null,
    });
  }
  return people;
}

export type InstructorSubscription = {
  id: string;
  planId: string;
  status: string;
  amountFc: number;
  seatsLimit: number;
  trackLimit: number;
  startedAt: string | null;
  expiresAt: string | null;
};

export type InstructorTrack = {
  id: string;
  slug: string;
  title: string;
  categoryId: string;
  /** Nom du domaine, pour chercher un parcours à enseigner par matière. */
  categoryName: string;
};

export type InstructorStatus = {
  subscription: InstructorSubscription | null;
  /** Abonnement encore valide à la seconde de la lecture. */
  isActive: boolean;
  /** Palier de facturation appliqué à l'hôte : payant, ou gratuit par descente. */
  tier: HostTier;
  /** Ouvrable une classe ou une séance, payant ou non : le quota change, pas le droit. */
  canHost: boolean;
  daysLeft: number;
  seatsUsed: number;
  classCount: number;
  tracks: InstructorTrack[];
};

export type InstructorClass = {
  id: string;
  title: string;
  /** Nom de l'académie de l'enseignant, tel qu'il le signe à ses élèves. */
  academy: string;
  description: string;
  joinCode: string;
  status: string;
  createdAt: string;
  trackId: string;
  trackSlug: string;
  trackTitle: string;
  memberCount: number;
  nextSessionAt: string | null;
};

export type ClassStudent = {
  userId: string;
  fullName: string;
  email: string | null;
  joinedAt: string;
  completedChapters: number;
  totalChapters: number;
  averageScore: number | null;
  lastActivity: string | null;
};

export type LiveSession = {
  id: string;
  title: string;
  agenda: string;
  startsAt: string;
  endsAt: string;
  status: string;
  /** Budget de minutes de l'hôte ; `null` = séance payante sans quota. */
  capMinutes: number | null;
  classId: string | null;
  className: string | null;
  /** Académie de rattachement, signataire des convocations. */
  academy: string | null;
  trackId: string | null;
  instructorId: string;
  instructorName: string;
  /** Élèves entrés en salle, quand la séance a été chargée pour le formateur. */
  attendance?: number;
};

function subscriptionOf(row: Record<string, unknown> | null): InstructorSubscription | null {
  if (!row) return null;
  return {
    id: String(row.id),
    planId: String(row.plan_id),
    status: String(row.status),
    amountFc: Number(row.amount_fc ?? 0),
    seatsLimit: Number(row.seats_limit ?? 0),
    trackLimit: Number(row.track_limit ?? 0),
    startedAt: (row.started_at as string | null) ?? null,
    expiresAt: (row.expires_at as string | null) ?? null,
  };
}

/**
 * Un administrateur qui éprouve la plateforme enseigne sans souscrire : il joue
 * tous les rôles pour tester, y compris la salle live et les places d'élève.
 * Ces valeurs ne passent jamais dans une facture, elles bornent seulement les
 * affichages « places utilisées » et « parcours choisis ».
 */
const ADMIN_SEATS = 200;
const ADMIN_DAYS = 3650;

const isAdministrator = cache(async (userId: string): Promise<boolean> => {
  if (!userId) return false;

  const supabase = createServiceSupabase();
  if (!supabase) return false;

  const { data } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", userId)
    .maybeSingle<{ role: string }>();

  return data?.role === "admin";
});

function adminSubscriptionOf(trackCount: number): InstructorSubscription {
  const now = Date.now();
  return {
    id: "acces_test",
    planId: "acces_test",
    status: "active",
    amountFc: 0,
    seatsLimit: ADMIN_SEATS,
    trackLimit: Math.max(trackCount, 1),
    startedAt: new Date(now).toISOString(),
    expiresAt: new Date(now + ADMIN_DAYS * 86_400_000).toISOString(),
  };
}

function daysLeft(expiresAt: string | null): number {
  if (!expiresAt) return 0;
  return Math.max(0, Math.ceil((new Date(expiresAt).getTime() - Date.now()) / 86_400_000));
}

/**
 * Situation commerciale d'un utilisateur : abonnement le plus récent, validité
 * recalculée à la lecture (une souscription jamais fermée par le serveur
 * reste `active` en base après son échéance, c'est `expires_at` qui tranche).
 *
 * Exception assumée : sans abonnement actif, un administrateur est traité comme
 * un formateur illimité. La règle est la même que celle du paywall — le compte
 * admin teste toute la plateforme sans payer.
 */
export const getInstructorStatus = cache(
  async (userId: string): Promise<InstructorStatus> => {
    const empty: InstructorStatus = {
      subscription: null,
      isActive: false,
      tier: "free",
      canHost: false,
      daysLeft: 0,
      seatsUsed: 0,
      classCount: 0,
      tracks: [],
    };
    const supabase = await createServerSupabase();
    if (!supabase || !userId) return empty;

    const { data: subRow } = await supabase
      .from("instructor_subscriptions")
      .select(
        "id,plan_id,status,amount_fc,seats_limit,track_limit,started_at,expires_at",
      )
      .eq("user_id", userId)
      .order("expires_at", { ascending: false, nullsFirst: false })
      .limit(1)
      .maybeSingle<Record<string, unknown>>();

    const subscription = subscriptionOf(subRow ?? null);
    const isActive =
      subscription?.status === "active" &&
      Boolean(subscription.expiresAt) &&
      new Date(subscription.expiresAt as string).getTime() > Date.now();

    const asAdmin = !isActive && (await isAdministrator(userId));
    // Une souscription fermée sans échéance (achat jamais soldé) n'ouvre rien :
    // seule une échéance dépassée donne droit au palier gratuit.
    const lapsed =
      !isActive &&
      !asAdmin &&
      DOWNGRADE_AFTER_EXPIRY &&
      subscription?.status === "active" &&
      Boolean(subscription.expiresAt);
    if (!isActive && !asAdmin && !lapsed) {
      return { ...empty, subscription };
    }

    const paid = isActive || asAdmin;

    const [tracksResult, classesResult] = await Promise.all([
      asAdmin
        ? supabase
            .from("tracks")
            .select("id,slug,title,category_id,categories(name)")
            .eq("published", true)
            .order("position")
        : supabase
            .from("instructor_subscription_tracks")
            .select("track_id, tracks(id,slug,title,category_id,categories(name))")
            .eq("subscription_id", subscription!.id),
      supabase
        .from("instructor_classes")
        .select("id, instructor_class_members(user_id,status)")
        .eq("instructor_id", userId)
        .eq("status", "active"),
    ]);

    type TrackJoin = {
      id: string;
      slug: string;
      title: string;
      category_id: string;
      categories: { name: string } | null;
    };

    const tracks: InstructorTrack[] = asAdmin
      ? (((tracksResult.data as TrackJoin[] | null) ?? []).map((row) => ({
          id: row.id,
          slug: row.slug,
          title: row.title,
          categoryId: row.category_id,
          categoryName: row.categories?.name ?? "",
        })))
      : (
          (tracksResult.data as { track_id: string; tracks: TrackJoin | null }[] | null) ?? []
        )
          .filter((row) => row.tracks)
          .map((row) => ({
            id: row.tracks!.id,
            slug: row.tracks!.slug,
            title: row.tracks!.title,
            categoryId: row.tracks!.category_id,
            categoryName: row.tracks!.categories?.name ?? "",
          }));

    const classes =
      (classesResult.data as
        | { id: string; instructor_class_members: { status: string }[] | null }[]
        | null) ?? [];

    // Une place libérée par un départ compte libérée : le compteur du tableau
    // de bord doit annoncer la même disponibilité que le contrôle d'inscription.
    const activeMembers = (item: { instructor_class_members: { status: string }[] | null }) =>
      (item.instructor_class_members ?? []).filter((member) => member.status === "active").length;

    const record = asAdmin ? adminSubscriptionOf(tracks.length) : subscription!;

    return {
      // Un hôte du palier gratuit lit le plafond du palier, pas celui de son
      // ancien plan : sinon le tableau de bord promettrait 25 places que la
      // caisse n'a plus payées.
      subscription: paid
        ? record
        : { ...record, seatsLimit: FREE_CLASS_SEATS, trackLimit: 1 },
      isActive: paid,
      canHost: true,
      tier: paid ? "paid" : "free",
      daysLeft: asAdmin ? ADMIN_DAYS : daysLeft(subscription!.expiresAt),
      seatsUsed: classes.reduce((total, item) => total + activeMembers(item), 0),
      classCount: classes.length,
      tracks,
    };
  },
);

/**
 * Places consenties à un formateur, lues avec la clé de service.
 *
 * Un élève qui rejoint par code doit vérifier l'abonnement d'un autre : la
 * lecture au nom de l'appelant renverrait une ligne vide, donc « plus de places
 * disponibles », et aucune classe ne pourrait jamais être rejointe.
 */
export async function activeSeatLimit(instructorId: string): Promise<number | null> {
  const supabase = createServiceSupabase();
  if (!supabase || !instructorId) return null;

  const { data } = await supabase
    .from("instructor_subscriptions")
    .select("status,expires_at,seats_limit")
    .eq("user_id", instructorId)
    .order("expires_at", { ascending: false, nullsFirst: false })
    .limit(1)
    .maybeSingle<{ status: string; expires_at: string; seats_limit: number }>();

  if (data?.status === "active" && new Date(data.expires_at).getTime() > Date.now()) {
    return Number(data.seats_limit) || 0;
  }

  // Classe tenue par un administrateur en test : les places ne dépendent
  // d'aucun abonnement payé, sinon personne ne pourrait jamais y entrer.
  if (await isAdministrator(instructorId)) return ADMIN_SEATS;

  // Abonnement expiré : le palier gratuit conserve de quoi finir le cours,
  // sans laisser un trimestre entier sans salle ni places.
  if (DOWNGRADE_AFTER_EXPIRY && data) return FREE_CLASS_SEATS;

  return null;
}

export async function getInstructorClasses(
  instructorId: string,
): Promise<InstructorClass[]> {
  const supabase = await createServerSupabase();
  if (!supabase) return [];

  const { data } = await supabase
    .from("instructor_classes")
    .select(
      "id,title,academy,description,join_code,status,created_at,track_id,tracks(slug,title),instructor_class_members(user_id,status),live_sessions(id)",
    )
    .eq("instructor_id", instructorId)
    .order("created_at", { ascending: false });

  const rows =
    (data as
      | {
          id: string;
          title: string;
          academy: string;
          description: string;
          join_code: string;
          status: string;
          created_at: string;
          track_id: string;
          tracks: { slug: string; title: string } | null;
          instructor_class_members: { status: string }[] | null;
          live_sessions: { id: string }[] | null;
        }[]
      | null) ?? [];

  if (rows.length === 0) return [];

  const { data: upcoming } = await supabase
    .from("live_sessions")
    .select("class_id,starts_at")
    .in("class_id", rows.map((row) => row.id))
    .gte("starts_at", new Date().toISOString())
    .in("status", ["scheduled", "live"])
    .order("starts_at");

  const nextByClass = new Map<string, string>();
  for (const row of (upcoming as { class_id: string; starts_at: string }[] | null) ?? []) {
    if (row.class_id && !nextByClass.has(row.class_id)) {
      nextByClass.set(row.class_id, row.starts_at);
    }
  }

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    academy: row.academy ?? "",
    description: row.description,
    joinCode: row.join_code,
    status: row.status,
    createdAt: row.created_at,
    trackId: row.track_id,
    trackSlug: row.tracks?.slug ?? "",
    trackTitle: row.tracks?.title ?? "Parcours supprimé",
    memberCount: (row.instructor_class_members ?? []).filter(
      (member) => member.status === "active",
    ).length,
    nextSessionAt: nextByClass.get(row.id) ?? null,
  }));
}

/**
 * Liste nominative des élèves d'une classe avec leur progression.
 * Rôle service obligatoire : la progression d'un apprenant ne est lisible que
 * par lui-même, c'est l'appartenance à la classe qui autorise ce croisement —
 * d'où le contrôle d'accès explicite avant la lecture.
 */
export async function getClassStudents(
  classId: string,
  viewerId: string,
): Promise<{ class: InstructorClass | null; students: ClassStudent[] }> {
  const supabase = createServiceSupabase();
  if (!supabase) return { class: null, students: [] };

  const { data: classRow } = await supabase
    .from("instructor_classes")
    .select("id,title,academy,description,join_code,status,created_at,track_id,instructor_id,tracks(slug,title)")
    .eq("id", classId)
    .maybeSingle<Record<string, unknown>>();

  if (!classRow) return { class: null, students: [] };

  const isOwner = String(classRow.instructor_id) === viewerId;

  if (!isOwner) {
    const { data: membership } = await supabase
      .from("instructor_class_members")
      .select("user_id")
      .eq("class_id", classId)
      .eq("user_id", viewerId)
      .eq("status", "active")
      .maybeSingle();
    if (!membership) return { class: null, students: [] };
  }

  const trackId = String(classRow.track_id);
  const { data: members } = await supabase
    .from("instructor_class_members")
    .select("user_id,joined_at")
    .eq("class_id", classId)
    .eq("status", "active")
    .order("joined_at");

  const memberRows =
    (members as { user_id: string; joined_at: string }[] | null) ?? [];

  const people = await peopleOf(
    supabase,
    memberRows.map((row) => row.user_id),
  );

  if (memberRows.length === 0) {
    return { class: toClass(classRow), students: [] };
  }

  const { data: progress } = await supabase
    .from("chapter_progress")
    .select("user_id,best_score,status,updated_at")
    .eq("track_id", trackId)
    .in("user_id", memberRows.map((row) => row.user_id));

  const { count: totalChapters } = await supabase
    .from("chapters")
    .select("id", { count: "exact", head: true })
    .eq("track_id", trackId)
    .eq("published", true);

  const byUser = new Map<
    string,
    { completed: number; scores: number[]; last: string | null }
  >();
  for (const row of (progress as
    | { user_id: string; best_score: number | null; status: string; updated_at: string }[]
    | null) ?? []) {
    const bucket = byUser.get(row.user_id) ?? { completed: 0, scores: [], last: null };
    if (row.status === "completed") bucket.completed += 1;
    if (typeof row.best_score === "number") bucket.scores.push(row.best_score);
    if (!bucket.last || row.updated_at > bucket.last) bucket.last = row.updated_at;
    byUser.set(row.user_id, bucket);
  }

  return {
    class: toClass(classRow),
    students: memberRows.map((row) => {
      const bucket = byUser.get(row.user_id);
      const person = people.get(row.user_id);
      const scores = bucket?.scores ?? [];
      return {
        userId: row.user_id,
        fullName: person?.fullName || "Apprenant",
        email: person?.email ?? null,
        joinedAt: row.joined_at,
        completedChapters: bucket?.completed ?? 0,
        totalChapters: totalChapters ?? 0,
        averageScore:
          scores.length > 0
            ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length)
            : null,
        lastActivity: bucket?.last ?? null,
      };
    }),
  };
}

function toClass(row: Record<string, unknown>): InstructorClass {
  const tracks = row.tracks as { slug: string; title: string } | null;
  return {
    id: String(row.id),
    title: String(row.title),
    academy: String(row.academy ?? ""),
    description: String(row.description ?? ""),
    joinCode: String(row.join_code),
    status: String(row.status),
    createdAt: String(row.created_at),
    trackId: String(row.track_id),
    trackSlug: tracks?.slug ?? "",
    trackTitle: tracks?.title ?? "Parcours supprimé",
    memberCount: 0,
    nextSessionAt: null,
  };
}

/** Classes auxquelles appartient l'apprenant (vue « Ma classe »). */
export async function getLearnerClasses(userId: string): Promise<{
  classId: string;
  title: string;
  academy: string;
  instructorName: string;
  trackId: string;
  trackSlug: string;
  trackTitle: string;
  joinedAt: string;
  nextSession: LiveSession | null;
}[]> {
  const supabase = createServiceSupabase();
  if (!supabase || !userId) return [];

  const { data } = await supabase
    .from("instructor_class_members")
    .select(
      "joined_at, instructor_classes(id,title,academy,status,instructor_id,track_id,tracks(slug,title))",
    )
    .eq("user_id", userId)
    .eq("status", "active")
    .order("joined_at", { ascending: false });

  const rows =
    (data as
      | {
          joined_at: string;
          instructor_classes: {
            id: string;
            title: string;
            academy: string;
            status: string;
            instructor_id: string;
            track_id: string;
            tracks: { slug: string; title: string } | null;
          } | null;
        }[]
      | null) ?? [];

  const classes = rows
    .map((row) => ({ joinedAt: row.joined_at, klass: row.instructor_classes }))
    .filter(
      (row): row is { joinedAt: string; klass: NonNullable<typeof row.klass> } =>
        Boolean(row.klass) && row.klass!.status === "active",
    );

  if (classes.length === 0) return [];

  const { data: sessions } = await supabase
    .from("live_sessions")
    .select("id,title,starts_at,ends_at,status,cap_minutes,class_id,instructor_id")
    .in(
      "class_id",
      classes.map((row) => row.klass.id),
    )
    .in("status", ["scheduled", "live"])
    // La séance qui déborre de son heure annoncée reste « à venir » tant
    // qu'elle n'est pas clôturée : `ends_at` n'est qu'une indication.
    .or(`status.eq.live,ends_at.gte.${new Date().toISOString()}`)
    .order("starts_at");

  const nextByClass = new Map<
    string,
    { id: string; title: string; startsAt: string; endsAt: string; status: string; capMinutes: number | null }
  >();
  for (const row of (sessions as
    | { id: string; title: string; starts_at: string; ends_at: string; status: string; cap_minutes: number | null; class_id: string }[]
    | null) ?? []) {
    if (row.class_id && !nextByClass.has(row.class_id)) {
      nextByClass.set(row.class_id, {
        id: row.id,
        title: row.title,
        startsAt: row.starts_at,
        endsAt: row.ends_at,
        status: row.status,
        capMinutes: row.cap_minutes,
      });
    }
  }

  const people = await peopleOf(
    supabase,
    classes.map((row) => row.klass.instructor_id),
  );

  return classes.map(({ klass, joinedAt }) => {
    const upcoming = nextByClass.get(klass.id);
    const instructorName = people.get(klass.instructor_id)?.fullName || "Formateur";
    return {
      classId: klass.id,
      title: klass.title,
      academy: klass.academy ?? "",
      instructorName,
      trackId: klass.track_id,
      trackSlug: klass.tracks?.slug ?? "",
      trackTitle: klass.tracks?.title ?? "Parcours",
      joinedAt,
      nextSession: upcoming
        ? {
            ...upcoming,
            classId: klass.id,
            academy: klass.academy ?? "",
            agenda: "",
            className: klass.title,
            trackId: klass.track_id,
            instructorId: klass.instructor_id,
            instructorName,
          }
        : null,
    };
  });
}

/** Séance visible par `viewerId` : l'hôte, un élève de la classe, ou un admin. */
export async function getLiveSession(
  sessionId: string,
  viewerId: string,
): Promise<{
  session: LiveSession | null;
  isHost: boolean;
  canJoin: boolean;
  roomName: string | null;
}> {
  const supabase = createServiceSupabase();
  if (!supabase || !sessionId) {
    return { session: null, isHost: false, canJoin: false, roomName: null };
  }

  const { data } = await supabase
    .from("live_sessions")
    .select(
      "id,title,agenda,starts_at,ends_at,status,cap_minutes,room_name,class_id,instructor_id,track_id,instructor_classes(title,academy)",
    )
    .eq("id", sessionId)
    .maybeSingle<Record<string, unknown>>();

  if (!data) return { session: null, isHost: false, canJoin: false, roomName: null };

  const isHost = String(data.instructor_id) === viewerId;
  let canJoin = isHost;

  if (!canJoin && data.class_id) {
    const { data: membership } = await supabase
      .from("instructor_class_members")
      .select("user_id")
      .eq("class_id", String(data.class_id))
      .eq("user_id", viewerId)
      .eq("status", "active")
      .maybeSingle();
    canJoin = Boolean(membership);
  }

  if (!canJoin) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", viewerId)
      .maybeSingle<{ role: string }>();
    canJoin = profile?.role === "admin";
  }

  const klass = data.instructor_classes as { title: string; academy: string } | null;
  const people = await peopleOf(supabase, [String(data.instructor_id)]);

  return {
    session: {
      id: String(data.id),
      title: String(data.title),
      agenda: String(data.agenda ?? ""),
      startsAt: String(data.starts_at),
      endsAt: String(data.ends_at),
      status: String(data.status),
      capMinutes:
        data.cap_minutes === null || data.cap_minutes === undefined
          ? null
          : Number(data.cap_minutes),
      classId: (data.class_id as string | null) ?? null,
      className: klass?.title ?? null,
      academy: klass?.academy ?? null,
      trackId: (data.track_id as string | null) ?? null,
      instructorId: String(data.instructor_id),
      instructorName: people.get(String(data.instructor_id))?.fullName || "Formateur",
    },
    isHost,
    canJoin,
    roomName: (data.room_name as string | null) ?? null,
  };
}

export async function getInstructorSessions(
  instructorId: string,
): Promise<LiveSession[]> {
  const supabase = await createServerSupabase();
  if (!supabase) return [];

  const { data } = await supabase
    .from("live_sessions")
    .select("id,title,agenda,starts_at,ends_at,status,cap_minutes,class_id,instructor_id,track_id,instructor_classes(title,academy)")
    .eq("instructor_id", instructorId)
    .order("starts_at", { ascending: false });

  const rows =
    (data as
      | {
          id: string;
          title: string;
          agenda: string;
          starts_at: string;
          ends_at: string;
          status: string;
          cap_minutes: number | null;
          class_id: string | null;
          instructor_id: string;
          track_id: string | null;
          instructor_classes: { title: string; academy: string } | null;
        }[]
      | null) ?? [];
  if (rows.length === 0) return [];

  const { data: marks } = await supabase
    .from("live_session_attendance")
    .select("session_id")
    .in(
      "session_id",
      rows.map((row) => row.id),
    );

  const counts = new Map<string, number>();
  for (const mark of (marks as { session_id: string }[] | null) ?? []) {
    counts.set(mark.session_id, (counts.get(mark.session_id) ?? 0) + 1);
  }

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    agenda: row.agenda,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
    status: row.status,
    capMinutes: row.cap_minutes,
    classId: row.class_id,
    className: row.instructor_classes?.title ?? null,
    academy: row.instructor_classes?.academy ?? null,
    trackId: row.track_id,
    instructorId: row.instructor_id,
    instructorName: "",
    attendance: counts.get(row.id) ?? 0,
  }));
}

/**
 * Prochaines séances des classes de l'apprenant.
 * `classId` borne le calendrier d'une seule classe (vue « Mon emploi du temps »
 * et fichier .ics), `limit` suit l'usage : cinq cartes au tableau de bord,
 * soixante dates dans l'agenda.
 */
export async function getUpcomingSessionsForLearner(
  userId: string,
  options: { classId?: string; limit?: number } = {},
): Promise<LiveSession[]> {
  const supabase = createServiceSupabase();
  if (!supabase || !userId) return [];

  const membershipFilter = supabase
    .from("instructor_class_members")
    .select("class_id")
    .eq("user_id", userId)
    .eq("status", "active");

  const { data: memberships } = options.classId
    ? await membershipFilter.eq("class_id", options.classId)
    : await membershipFilter;

  const classIds = ((memberships as { class_id: string }[] | null) ?? []).map(
    (row) => row.class_id,
  );
  if (classIds.length === 0) return [];

  const { data } = await supabase
    .from("live_sessions")
    .select(
      "id,title,agenda,starts_at,ends_at,status,cap_minutes,class_id,instructor_id,instructor_classes(title,academy)",
    )
    .in("class_id", classIds)
    .in("status", ["scheduled", "live"])
    // Séance en cours = séance encore à venir, heure annoncée dépassée ou non.
    .or(`status.eq.live,ends_at.gte.${new Date().toISOString()}`)
    .order("starts_at")
    .limit(options.limit ?? 5);

  const rows =
    (data as
      | {
          id: string;
          title: string;
          agenda: string;
          starts_at: string;
          ends_at: string;
          status: string;
          cap_minutes: number | null;
          class_id: string | null;
          instructor_id: string;
          instructor_classes: { title: string; academy: string } | null;
        }[]
      | null) ?? [];

  const people = await peopleOf(
    supabase,
    rows.map((row) => row.instructor_id),
  );

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    agenda: row.agenda,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
    status: row.status,
    capMinutes: row.cap_minutes,
    classId: row.class_id,
    className: row.instructor_classes?.title ?? null,
    academy: row.instructor_classes?.academy ?? null,
    trackId: null,
    instructorId: row.instructor_id,
    instructorName: people.get(row.instructor_id)?.fullName || "Formateur",
  }));
}

export function planOf(
  plans: InstructorPlan[],
  planId: string | null | undefined,
): InstructorPlan | null {
  if (!planId) return null;
  return plans.find((plan) => plan.id === planId) ?? null;
}

export type TrackOption = {
  id: string;
  slug: string;
  title: string;
  category: string;
};

/**
 * Parcours enseignables : ceux publiés, regroupés par domaine. La liste alimente
 * le sélecteur de parcours de la souscription formateur et celui d'une classe.
 */
export const getTrackOptions = cache(async (): Promise<TrackOption[]> => {
  const supabase = await createServerSupabase();
  if (!supabase) return [];

  const { data } = await supabase
    .from("tracks")
    .select("id,slug,title,category_id,categories(name)")
    .eq("published", true)
    .order("position");

  return (
    (data as
      | {
          id: string;
          slug: string;
          title: string;
          category_id: string;
          categories: { name: string } | null;
        }[]
      | null) ?? []
  ).map((row) => ({
    id: row.id,
    slug: row.slug,
    title: row.title,
    category: row.categories?.name ?? "Domaine",
  }));
});

/** Lien d'invitation : « Ma classe » l'accepte via ?invitation=. */
export function invitationLink(token: string): string {
  return new URL(`/app/classe?invitation=${encodeURIComponent(token)}`, site.url).toString();
}

/** Invitations encore valables d'une classe, avec le lien à transmettre. */
export async function getPendingInvites(
  classId: string,
): Promise<{ email: string; link: string; expiresAt: string }[]> {
  const supabase = createServiceSupabase();
  if (!supabase || !classId) return [];

  const { data } = await supabase
    .from("instructor_class_invites")
    .select("email,token,expires_at")
    .eq("class_id", classId)
    .eq("status", "pending")
    .gt("expires_at", new Date().toISOString())
    .order("expires_at");

  return (
    (data as { email: string; token: string; expires_at: string }[] | null) ?? []
  ).map((row) => ({
    email: row.email,
    link: invitationLink(row.token),
    expiresAt: row.expires_at,
  }));
}

/**
 * Invitation présentée à l'apprenant avant qu'il ne l'accepte. Le jeton est la
 * seule preuve d'autorisation : non devinable, à usage unique, et l'action
 * d'acceptation re-vérifie son état côté serveur.
 */
export async function getInvitation(token: string): Promise<{
  classId: string;
  email: string;
  className: string;
  academy: string;
  trackTitle: string;
  instructorName: string;
  instructorEmail: string | null;
  expiresAt: string;
} | null> {
  const supabase = createServiceSupabase();
  if (!supabase || !token) return null;

  const { data } = await supabase
    .from("instructor_class_invites")
    .select(
      "email,status,expires_at,instructor_classes(id,title,academy,instructor_id,track_id,tracks(title))",
    )
    .eq("token", token)
    .maybeSingle<Record<string, unknown>>();

  if (!data || String(data.status) !== "pending") return null;
  if (new Date(String(data.expires_at)).getTime() <= Date.now()) return null;

  const klass = data.instructor_classes as
    | {
        id: string;
        title: string;
        academy: string;
        instructor_id: string;
        tracks: { title: string } | null;
      }
    | null;
  if (!klass) return null;

  const people = await peopleOf(supabase, [klass.instructor_id]);
  const instructor = people.get(klass.instructor_id);

  return {
    classId: klass.id,
    email: String(data.email),
    className: klass.title,
    academy: klass.academy ?? "",
    trackTitle: klass.tracks?.title ?? "",
    instructorName: instructor?.fullName || "Formateur",
    instructorEmail: instructor?.email ?? null,
    expiresAt: String(data.expires_at),
  };
}
