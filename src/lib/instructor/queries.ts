import { cache } from "react";

import { site } from "@/config/site";
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
};

export type InstructorStatus = {
  subscription: InstructorSubscription | null;
  /** Abonnement encore valide à la seconde de la lecture. */
  isActive: boolean;
  daysLeft: number;
  seatsUsed: number;
  classCount: number;
  tracks: InstructorTrack[];
};

export type InstructorClass = {
  id: string;
  title: string;
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
  classId: string | null;
  className: string | null;
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

function daysLeft(expiresAt: string | null): number {
  if (!expiresAt) return 0;
  return Math.max(0, Math.ceil((new Date(expiresAt).getTime() - Date.now()) / 86_400_000));
}

/**
 * Situation commerciale d'un utilisateur : abonnement le plus récent, validité
 * recalculée à la lecture (une souscription jamais fermée par le serveur
 * reste `active` en base après son échéance, c'est `expires_at` qui tranche).
 */
export const getInstructorStatus = cache(
  async (userId: string): Promise<InstructorStatus> => {
    const empty: InstructorStatus = {
      subscription: null,
      isActive: false,
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

    if (!isActive || !subscription) {
      return { ...empty, subscription };
    }

    const [tracksResult, classesResult] = await Promise.all([
      supabase
        .from("instructor_subscription_tracks")
        .select("track_id, tracks(id,slug,title,category_id)")
        .eq("subscription_id", subscription.id),
      supabase
        .from("instructor_classes")
        .select("id, instructor_class_members(user_id)")
        .eq("instructor_id", userId)
        .eq("status", "active"),
    ]);

    const tracks: InstructorTrack[] = (
      (tracksResult.data as
        | { track_id: string; tracks: { id: string; slug: string; title: string; category_id: string } | null }[]
        | null) ?? []
    )
      .filter((row) => row.tracks)
      .map((row) => ({
        id: row.tracks!.id,
        slug: row.tracks!.slug,
        title: row.tracks!.title,
        categoryId: row.tracks!.category_id,
      }));

    const classes =
      (classesResult.data as
        | { id: string; instructor_class_members: { user_id: string }[] | null }[]
        | null) ?? [];

    return {
      subscription,
      isActive: true,
      daysLeft: daysLeft(subscription.expiresAt),
      seatsUsed: classes.reduce(
        (total, item) => total + (item.instructor_class_members?.length ?? 0),
        0,
      ),
      classCount: classes.length,
      tracks,
    };
  },
);

/** Le formateur doit un abonnement actif pour ouvrir l'espace d'enseignement. */
export async function requireActiveInstructor(userId: string) {
  const status = await getInstructorStatus(userId);
  return status.isActive ? status : null;
}

export async function getInstructorClasses(
  instructorId: string,
): Promise<InstructorClass[]> {
  const supabase = await createServerSupabase();
  if (!supabase) return [];

  const { data } = await supabase
    .from("instructor_classes")
    .select(
      "id,title,description,join_code,status,created_at,track_id,tracks(slug,title),instructor_class_members(user_id),live_sessions(id)",
    )
    .eq("instructor_id", instructorId)
    .order("created_at", { ascending: false });

  const rows =
    (data as
      | {
          id: string;
          title: string;
          description: string;
          join_code: string;
          status: string;
          created_at: string;
          track_id: string;
          tracks: { slug: string; title: string } | null;
          instructor_class_members: { user_id: string }[] | null;
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
    description: row.description,
    joinCode: row.join_code,
    status: row.status,
    createdAt: row.created_at,
    trackId: row.track_id,
    trackSlug: row.tracks?.slug ?? "",
    trackTitle: row.tracks?.title ?? "Parcours supprimé",
    memberCount: row.instructor_class_members?.length ?? 0,
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
    .select("id,title,description,join_code,status,created_at,track_id,instructor_id,tracks(slug,title)")
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
      "joined_at, instructor_classes(id,title,status,instructor_id,track_id,tracks(slug,title))",
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
    .select("id,title,starts_at,ends_at,status,class_id,instructor_id")
    .in(
      "class_id",
      classes.map((row) => row.klass.id),
    )
    .gte("ends_at", new Date().toISOString())
    .in("status", ["scheduled", "live"])
    .order("starts_at");

  const nextByClass = new Map<
    string,
    { id: string; title: string; startsAt: string; endsAt: string; status: string }
  >();
  for (const row of (sessions as
    | { id: string; title: string; starts_at: string; ends_at: string; status: string; class_id: string }[]
    | null) ?? []) {
    if (row.class_id && !nextByClass.has(row.class_id)) {
      nextByClass.set(row.class_id, {
        id: row.id,
        title: row.title,
        startsAt: row.starts_at,
        endsAt: row.ends_at,
        status: row.status,
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
      instructorName,
      trackId: klass.track_id,
      trackSlug: klass.tracks?.slug ?? "",
      trackTitle: klass.tracks?.title ?? "Parcours",
      joinedAt,
      nextSession: upcoming
        ? {
            ...upcoming,
            classId: klass.id,
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
      "id,title,agenda,starts_at,ends_at,status,room_name,class_id,instructor_id,track_id,instructor_classes(title)",
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

  const klass = data.instructor_classes as { title: string } | null;
  const people = await peopleOf(supabase, [String(data.instructor_id)]);

  return {
    session: {
      id: String(data.id),
      title: String(data.title),
      agenda: String(data.agenda ?? ""),
      startsAt: String(data.starts_at),
      endsAt: String(data.ends_at),
      status: String(data.status),
      classId: (data.class_id as string | null) ?? null,
      className: klass?.title ?? null,
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
    .select("id,title,agenda,starts_at,ends_at,status,class_id,instructor_id,track_id,instructor_classes(title)")
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
          class_id: string | null;
          instructor_id: string;
          track_id: string | null;
          instructor_classes: { title: string } | null;
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
    classId: row.class_id,
    className: row.instructor_classes?.title ?? null,
    trackId: row.track_id,
    instructorId: row.instructor_id,
    instructorName: "",
    attendance: counts.get(row.id) ?? 0,
  }));
}

/** Prochaines séances des classes de l'apprenant (tableau de bord). */
export async function getUpcomingSessionsForLearner(
  userId: string,
): Promise<LiveSession[]> {
  const supabase = createServiceSupabase();
  if (!supabase || !userId) return [];

  const { data: memberships } = await supabase
    .from("instructor_class_members")
    .select("class_id")
    .eq("user_id", userId)
    .eq("status", "active");

  const classIds = ((memberships as { class_id: string }[] | null) ?? []).map(
    (row) => row.class_id,
  );
  if (classIds.length === 0) return [];

  const { data } = await supabase
    .from("live_sessions")
    .select(
      "id,title,agenda,starts_at,ends_at,status,class_id,instructor_id,instructor_classes(title)",
    )
    .in("class_id", classIds)
    .gte("ends_at", new Date().toISOString())
    .in("status", ["scheduled", "live"])
    .order("starts_at")
    .limit(5);

  const rows =
    (data as
      | {
          id: string;
          title: string;
          agenda: string;
          starts_at: string;
          ends_at: string;
          status: string;
          class_id: string | null;
          instructor_id: string;
          instructor_classes: { title: string } | null;
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
    classId: row.class_id,
    className: row.instructor_classes?.title ?? null,
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
  trackTitle: string;
  instructorName: string;
  expiresAt: string;
} | null> {
  const supabase = createServiceSupabase();
  if (!supabase || !token) return null;

  const { data } = await supabase
    .from("instructor_class_invites")
    .select(
      "email,status,expires_at,instructor_classes(id,title,instructor_id,track_id,tracks(title))",
    )
    .eq("token", token)
    .maybeSingle<Record<string, unknown>>();

  if (!data || String(data.status) !== "pending") return null;
  if (new Date(String(data.expires_at)).getTime() <= Date.now()) return null;

  const klass = data.instructor_classes as
    | {
        id: string;
        title: string;
        instructor_id: string;
        tracks: { title: string } | null;
      }
    | null;
  if (!klass) return null;

  const people = await peopleOf(supabase, [klass.instructor_id]);

  return {
    classId: klass.id,
    email: String(data.email),
    className: klass.title,
    trackTitle: klass.tracks?.title ?? "",
    instructorName: people.get(klass.instructor_id)?.fullName || "Formateur",
    expiresAt: String(data.expires_at),
  };
}
