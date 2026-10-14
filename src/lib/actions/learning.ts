"use server";

import { refresh } from "next/cache";

import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import { MAX_ATTEMPTS } from "@/lib/learning/attempts";
import { getQuizQuestions } from "@/lib/learning/queries";
import { videoTokens } from "@/lib/learning/video-playability";
import type { QuizQuestionResult, QuizState } from "@/lib/learning/types";
import { verifyAssessmentToken } from "@/lib/security/assessment";
import { createServerSupabase } from "@/lib/supabase/server";
import { createServiceSupabase } from "@/lib/supabase/service";
import type { SupabaseClient } from "@supabase/supabase-js";

const t = messages.learner;

/** Client de Supabase côté serveur, session ou clé de service. */
type Reader = SupabaseClient;

/**
 * Vrai si le niveau du chapitre n'est pas payé.
 * Débutant toujours gratuit. Verrou strict (fail-closed) : toute anomalie
 * (catégorie introuvable, table purchases absente, erreur de lecture)
 * bloque l'accès plutôt que de l'ouvrir.
 */
export async function chapterLevelLocked(
  supabase: Reader,
  userId: string,
  chapter: { track_id: string; level: string },
): Promise<boolean> {
  if (chapter.level === "debutant") return false;

  const { data: track, error: trackError } = await supabase
    .from("tracks")
    .select("category_id")
    .eq("id", chapter.track_id)
    .maybeSingle();

  if (trackError) {
    console.warn(
      "[learning] paywall : catégorie du chapitre illisible — accès refusé (strict)",
      trackError.message,
    );
    return true;
  }

  const categoryId = track?.category_id;
  if (!categoryId) {
    console.warn(
      "[learning] paywall : catégorie introuvable pour le track",
      chapter.track_id,
      "— accès refusé (strict)",
    );
    return true;
  }

  // Abonnement de formateur ou place de classe : le domaine est ouvert en
  // entier. La règle vit dans granted_category_ids(), partagée avec la lecture
  // des parcours (src/lib/learning/queries.ts) pour qu'aucun des deux chemins
  // ne puisse dévier de l'autre.
  const { data: granted } = await supabase.rpc("granted_category_ids", {
    p_user: userId,
  });
  const grantedHere = ((granted as { category_id: string }[] | null) ?? []).some(
    (row) => row.category_id === categoryId,
  );
  if (grantedHere) return false;

  const { data, error } = await supabase
    .from("purchases")
    .select("id")
    .eq("user_id", userId)
    .eq("category_id", categoryId)
    .eq("level", chapter.level)
    .eq("status", "paid")
    .maybeSingle();

  if (error) {
    console.warn(
      "[learning] paywall : table absente ou illisible — accès refusé (strict). Coller la migration 202610030001_payments.sql",
      error.message,
    );
    return true;
  }

  return !data;
}

function readTextValue(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

export type PracticeStatePatch = {
  done?: boolean;
  solutionViewed?: boolean;
};

export type PracticeStateResult = {
  ok: boolean;
  done?: boolean;
  solutionViewed?: boolean;
};

export async function setPracticeState(
  chapterId: string,
  patch: PracticeStatePatch,
): Promise<PracticeStateResult> {
  try {
    return await runPracticeStateUpdate(chapterId, patch);
  } catch (error) {
    const digest = (error as { digest?: string } | null)?.digest;
    if (typeof digest === "string" && digest.startsWith("NEXT_REDIRECT")) {
      throw error;
    }
    console.error("[learning] practice state", error);
    return { ok: false };
  }
}

async function runPracticeStateUpdate(
  chapterId: string,
  patch: PracticeStatePatch,
): Promise<PracticeStateResult> {
  if (!chapterId || typeof chapterId !== "string") {
    return { ok: false };
  }

  const user = await requireUser(links.dashboard);

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { ok: false };
  }

  const { data: chapter } = await supabase
    .from("chapters")
    .select("id,track_id,published,level")
    .eq("id", chapterId)
    .maybeSingle();

  if (!chapter || !chapter.published) {
    return { ok: false };
  }

  if (await chapterLevelLocked(supabase, user.id, chapter)) {
    return { ok: false };
  }

  const service = createServiceSupabase();
  if (!service) {
    console.error("[learning] cle de service absente — ecritures de progression refusees");
    return { ok: false };
  }

  const { data: current, error: currentError } = await service
    .from("chapter_progress")
    .select("practice_done,solution_viewed")
    .eq("user_id", user.id)
    .eq("chapter_id", chapterId)
    .maybeSingle();

  if (currentError) {
    console.error("[learning] practice read", currentError.message);
    return { ok: false };
  }

  const row = {
    user_id: user.id,
    chapter_id: chapterId,
    track_id: chapter.track_id,
    practice_done: patch.done ?? current?.practice_done ?? false,
    solution_viewed: patch.solutionViewed ?? current?.solution_viewed ?? false,
  };

  const { error } = await service
    .from("chapter_progress")
    .upsert(row, { onConflict: "user_id,chapter_id" });

  if (error) {
    console.error("[learning] practice write", error.message);
    return { ok: false };
  }

  try {
    refresh();
  } catch {
    void 0;
  }

  return {
    ok: true,
    done: row.practice_done,
    solutionViewed: row.solution_viewed,
  };
}

function toVideoTokens(videos: unknown): string[] {
  if (!Array.isArray(videos)) return [];
  return videoTokens(
    videos.filter(
      (video): video is { url: string } =>
        typeof (video as { url?: unknown } | null)?.url === "string",
    ),
  );
}

export type VideoWatchResult = {
  ok: boolean;
  /** `unverified` : la preuve de visionnage est absente ou insuffisante. */
  reason?: "unverified";
  watched?: string[];
};

/** Fraction du temps réel minimum face aux secondes revendiquées (anti-2×). */
const WATCH_CREDIT_RATIO = 0.6;
/** Battements serveur minimum : un seul appel ne suffit jamais. */
const WATCH_MIN_TICKS = 3;
/** Marge tolérée avant la toute fin de la leçon. */
const WATCH_TAIL_SECONDS = 25;

type ProofEntry = {
  seconds: number;
  duration: number;
  first: string;
  last: string;
  ticks: number;
};

/**
 * La leçon n'est comptée vue que si l'horloge du serveur a vu arriver la
 * progression : assez de battements, la fin réellement atteinte, et autant de
 * temps écoulé en réel qu'affiché à l'écran. Une leçon déclarée vue d'une
 * seule requête, ou lue en accéléré, échoue ici plutôt qu'en base.
 */
function proofSufficient(entry: ProofEntry | null): boolean {
  if (!entry || entry.duration <= 0 || entry.seconds <= 0) return false;

  const tail = Math.max(WATCH_TAIL_SECONDS, entry.duration * 0.05);
  if (entry.seconds < entry.duration - tail) return false;

  const ticksNeeded = Math.min(
    WATCH_MIN_TICKS + 1,
    Math.max(WATCH_MIN_TICKS, Math.ceil(entry.duration / 20)),
  );
  if (entry.ticks < ticksNeeded) return false;

  const span = (Date.parse(entry.last) - Date.parse(entry.first)) / 1000;
  if (!Number.isFinite(span)) return false;
  return span >= entry.seconds * WATCH_CREDIT_RATIO;
}

export async function attestVideoWatched(
  chapterId: string,
  videoId: string,
): Promise<VideoWatchResult> {
  try {
    return await runVideoWatchUpdate(chapterId, videoId);
  } catch (error) {
    const digest = (error as { digest?: string } | null)?.digest;
    if (typeof digest === "string" && digest.startsWith("NEXT_REDIRECT")) {
      throw error;
    }
    console.error("[learning] video watch", error);
    return { ok: false };
  }
}

export type VideoTickInput = {
  chapterId: string;
  videoToken: string;
  seconds: number;
  duration: number;
};

/** Deux battements plus rapprochés que cela ne comptent qu'une fois. */
const TICK_MIN_GAP_MS = 5_000;
/** Tolérance entre l'horloge serveur et la seconde affichée par le lecteur. */
const TICK_GRACE_SECONDS = 20;
const MAX_TICK_SECONDS = 6 * 60 * 60;

function tickNumber(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    return null;
  }
  return Math.min(Math.floor(value), MAX_TICK_SECONDS);
}

function proofEntries(value: unknown): Record<string, ProofEntry> {
  if (!value || typeof value !== "object") return {};
  const entries: Record<string, ProofEntry> = {};
  for (const [token, raw] of Object.entries(value as Record<string, unknown>)) {
    if (!raw || typeof raw !== "object") continue;
    const blob = raw as Record<string, unknown>;
    const seconds = tickNumber(blob.seconds);
    const duration = tickNumber(blob.duration);
    const first = typeof blob.first === "string" ? blob.first : "";
    const last = typeof blob.last === "string" ? blob.last : "";
    const ticks = tickNumber(blob.ticks) ?? 0;
    if (seconds === null || duration === null || !first || !last) continue;
    entries[token] = { seconds, duration, first, last, ticks };
  }
  return entries;
}

/**
 * Battement de lecture : l'unique source de la preuve de visionnage.
 *
 * Les horodatages viennent du serveur, et les secondes revendiquées sont
 * bornées par le temps réel écoulé depuis le premier battement. Un navigateur
 * qui enverrait `seconds: 600` au premier appel n'obtient que la seconde
 * autorisée par l'horloge ; il ne peut plus écrire lui-même une leçon « vue ».
 * La colonne `watch_proof` est fermée au rôle client, donc rien de tout ceci
 * n'est atteignable sans passer par cette fonction.
 */
export async function recordVideoTick(
  input: VideoTickInput,
): Promise<{ ok: boolean }> {
  try {
    return await runVideoTick(input);
  } catch (error) {
    const digest = (error as { digest?: string } | null)?.digest;
    if (typeof digest === "string" && digest.startsWith("NEXT_REDIRECT")) {
      throw error;
    }
    console.error("[learning] video tick", error);
    return { ok: false };
  }
}

async function runVideoTick(input: VideoTickInput): Promise<{ ok: boolean }> {
  const chapterId = typeof input.chapterId === "string" ? input.chapterId : "";
  const token = typeof input.videoToken === "string" ? input.videoToken : "";
  if (!chapterId || !token) return { ok: false };

  const user = await requireUser(links.login);

  const service = createServiceSupabase();
  if (!service) {
    console.error("[learning] cle de service absente — battement de lecture ignore");
    return { ok: false };
  }

  const { data: chapter } = await service
    .from("chapters")
    .select("id,track_id,published,videos,level")
    .eq("id", chapterId)
    .maybeSingle();

  if (!chapter || !chapter.published) return { ok: false };
  if (await chapterLevelLocked(service, user.id, chapter)) return { ok: false };
  if (!toVideoTokens(chapter.videos).includes(token)) return { ok: false };

  const claimed = tickNumber(input.seconds);
  const duration = tickNumber(input.duration);
  if (claimed === null || duration === null || duration <= 0) return { ok: false };

  const { data: row } = await service
    .from("chapter_progress")
    .select("watch_proof,resume")
    .eq("user_id", user.id)
    .eq("chapter_id", chapterId)
    .maybeSingle();

  const entries = proofEntries(row?.watch_proof);
  const previous = entries[token];
  const now = Date.now();
  const first = previous?.first ?? new Date(now).toISOString();
  const startedAt = Date.parse(first);
  const elapsed = Number.isFinite(startedAt)
    ? Math.max(0, (now - startedAt) / 1000)
    : 0;

  const fresh = !previous || now - Date.parse(previous.last) >= TICK_MIN_GAP_MS;

  const entry: ProofEntry = {
    seconds: Math.max(
      Math.min(claimed, Math.floor(elapsed) + TICK_GRACE_SECONDS),
      previous?.seconds ?? 0,
    ),
    duration: Math.max(duration, previous?.duration ?? 0),
    first,
    last: new Date(now).toISOString(),
    ticks: (previous?.ticks ?? 0) + (fresh ? 1 : 0),
  };

  const resume =
    row?.resume && typeof row.resume === "object"
      ? (row.resume as Record<string, unknown>)
      : {};
  const resumeVideos =
    resume.video && typeof resume.video === "object"
      ? (resume.video as Record<string, unknown>)
      : {};
  const knownSeconds = Number(resumeVideos[token]);
  const position = Math.max(
    Number.isFinite(knownSeconds) ? knownSeconds : 0,
    entry.seconds,
  );

  const { error } = await service
    .from("chapter_progress")
    .upsert(
      {
        user_id: user.id,
        chapter_id: chapterId,
        track_id: chapter.track_id,
        watch_proof: { ...entries, [token]: entry },
        resume: { ...resume, video: { ...resumeVideos, [token]: position } },
      },
      { onConflict: "user_id,chapter_id" },
    );

  if (error) {
    console.warn("[learning] battement de lecture", error.message);
    return { ok: false };
  }

  return { ok: true };
}

async function runVideoWatchUpdate(
  chapterId: string,
  videoId: string,
): Promise<VideoWatchResult> {
  if (
    !chapterId ||
    typeof chapterId !== "string" ||
    !videoId ||
    typeof videoId !== "string"
  ) {
    return { ok: false };
  }

  const user = await requireUser(links.dashboard);

  const service = createServiceSupabase();
  if (!service) {
    console.error("[learning] cle de service absente — attestation refusee");
    return { ok: false };
  }

  const { data: chapter } = await service
    .from("chapters")
    .select("id,track_id,published,videos,level")
    .eq("id", chapterId)
    .maybeSingle();

  if (!chapter || !chapter.published) {
    return { ok: false };
  }

  if (await chapterLevelLocked(service, user.id, chapter)) {
    return { ok: false };
  }

  const tokens = toVideoTokens(chapter.videos);
  if (!tokens.includes(videoId)) {
    return { ok: false };
  }

  const { data: siblingRows } = await service
    .from("chapters")
    .select("id")
    .eq("track_id", chapter.track_id)
    .eq("published", true)
    .order("position");

  const siblings = siblingRows ?? [];
  const index = siblings.findIndex((item) => item.id === chapterId);
  if (index < 0) {
    return { ok: false };
  }

  if (index > 0) {
    const previousIds = siblings.slice(0, index).map((item) => item.id);
    const { data: previousProgress } = await service
      .from("chapter_progress")
      .select("chapter_id,status")
      .eq("user_id", user.id)
      .in("chapter_id", previousIds);

    const completedIds = new Set(
      (previousProgress ?? [])
        .filter((row) => row.status === "completed")
        .map((row) => row.chapter_id),
    );

    if (previousIds.some((id) => !completedIds.has(id))) {
      return { ok: false };
    }
  }

  const { data: current, error: currentError } = await service
    .from("chapter_progress")
    .select("videos_watched,watch_proof")
    .eq("user_id", user.id)
    .eq("chapter_id", chapterId)
    .maybeSingle();

  if (currentError) {
    console.warn(
      "[learning] video read : colonne absente — coller la migration 202610020001_video_watch.sql et 202610200001_security_hardening.sql",
      currentError.message,
    );
    return { ok: false };
  }

  const watchedAlready = new Set<string>(
    (current?.videos_watched as string[] | null) ?? [],
  );
  if (watchedAlready.has(videoId)) {
    return { ok: true, watched: [...watchedAlready] };
  }

  // La preuve ne se lit que dans `watch_proof` : column fermée au rôle client,
  // alimentée uniquement par `recordVideoTick` avec l'horloge du serveur.
  const entry = proofEntries(current?.watch_proof)[videoId];

  if (!entry || !proofSufficient(entry)) {
    console.warn(
      `[learning] visionnage refusé chapitre=${chapterId} leçon=${videoId} ` +
        `secondes=${entry?.seconds ?? 0}/${entry?.duration ?? 0} battements=${entry?.ticks ?? 0}`,
    );
    return { ok: false, reason: "unverified" };
  }

  const watched = watchedAlready;
  watched.add(videoId);
  const list = [...watched];

  const { error } = await service
    .from("chapter_progress")
    .upsert(
      {
        user_id: user.id,
        chapter_id: chapterId,
        track_id: chapter.track_id,
        videos_watched: list,
      },
      { onConflict: "user_id,chapter_id" },
    );

  if (error) {
    console.warn(
      "[learning] video write : colonne absente — coller la migration 202610020001_video_watch.sql",
      error.message,
    );
    return { ok: false };
  }

  try {
    refresh();
  } catch {
    void 0;
  }

  return { ok: true, watched: list };
}

export async function submitQuiz(
  _prevState: QuizState | undefined,
  formData: FormData,
): Promise<QuizState> {
  try {
    return await runQuizSubmission(formData);
  } catch (error) {
    const digest = (error as { digest?: string } | null)?.digest;
    if (typeof digest === "string" && digest.startsWith("NEXT_REDIRECT")) {
      throw error;
    }
    console.error("[learning] quiz submit", error);
    return { status: "error", message: t.quizError };
  }
}

async function runQuizSubmission(formData: FormData): Promise<QuizState> {
  const user = await requireUser(links.dashboard);

  const chapterId = readTextValue(formData, "chapterId");
  if (!chapterId) {
    return { status: "error", message: t.notConfigured };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { status: "error", message: t.notConfigured };
  }

  // `videos` n'est plus lisible par le rôle client, et `attempts`/`best_score`
  // ne sont plus inscriptibles : la clé de service porte ces écritures, après
  // que le verrou de niveau a été vérifié ci-dessous.
  const service = createServiceSupabase();
  if (!service) {
    console.error("[learning] cle de service absente — quiz refuse");
    return { status: "error", message: t.notConfigured };
  }

  const { data: chapter } = await service
    .from("chapters")
    .select("id,track_id,slug,title,position,published,videos,level")
    .eq("id", chapterId)
    .maybeSingle();

  if (!chapter || !chapter.published) {
    return { status: "error", message: t.notConfigured };
  }

  if (await chapterLevelLocked(service, user.id, chapter)) {
    return { status: "error", message: t.levelLockedMsg };
  }

  const { data: existing } = await service
    .from("chapter_progress")
    .select("attempts,best_score,status,completed_at")
    .eq("user_id", user.id)
    .eq("chapter_id", chapterId)
    .maybeSingle();

  // Trois tentatives seulement : au-delà, il faut reprendre le niveau entier,
  // ce qui remet la progression à zéro. Vérifié ici et non dans l'interface,
  // l'apprenant pouvant écrire lui-même ses lignes de progression.
  if (
    (existing?.attempts ?? 0) >= MAX_ATTEMPTS &&
    existing?.status !== "completed"
  ) {
    return { status: "error", message: t.quizAttemptsExhausted };
  }

  const videoTokens = toVideoTokens(chapter.videos);
  if (videoTokens.length > 0) {
    const { data: watchedRow, error: watchedError } = await service
      .from("chapter_progress")
      .select("videos_watched")
      .eq("user_id", user.id)
      .eq("chapter_id", chapterId)
      .maybeSingle();

    if (watchedError) {
      console.warn(
        "[learning] videos gate : colonne absente — coller la migration 202610020001_video_watch.sql",
        watchedError.message,
      );
    } else {
      const watched = new Set<string>(
        (watchedRow?.videos_watched as string[] | null) ?? [],
      );
      if (!videoTokens.every((token) => watched.has(token))) {
        return { status: "error", message: t.videosLocked };
      }
    }
  }

  const { data: track } = await supabase
    .from("tracks")
    .select("id,slug,passing_score")
    .eq("id", chapter.track_id)
    .maybeSingle();

  const passingScore = track?.passing_score ?? 70;

  const { data: siblingRows } = await supabase
    .from("chapters")
    .select("id,slug,title,position,level")
    .eq("track_id", chapter.track_id)
    .eq("published", true)
    .order("position");

  const siblings = siblingRows ?? [];
  const index = siblings.findIndex((item) => item.id === chapterId);
  if (index < 0) {
    return { status: "error", message: t.notConfigured };
  }

  if (index > 0) {
    const previousIds = siblings.slice(0, index).map((item) => item.id);
    const { data: previousProgress } = await supabase
      .from("chapter_progress")
      .select("chapter_id,status")
      .eq("user_id", user.id)
      .in("chapter_id", previousIds);

    const completedIds = new Set(
      (previousProgress ?? [])
        .filter((row) => row.status === "completed")
        .map((row) => row.chapter_id),
    );

    if (previousIds.some((id) => !completedIds.has(id))) {
      return { status: "error", message: t.quizLocked };
    }
  }

  // Verrou d'examen : le niveau suivant reste fermé tant que l'examen de fin
  // du niveau précédent n'est pas réussi.
  const levelOrder: string[] = [];
  for (const item of siblings) {
    if (item.level && !levelOrder.includes(item.level)) {
      levelOrder.push(item.level);
    }
  }
  const levelIndex = levelOrder.indexOf(chapter.level);
  if (levelIndex > 0) {
    const previousLevel = levelOrder[levelIndex - 1];
    const { data: exam } = await supabase
      .from("level_exams")
      .select("status")
      .eq("user_id", user.id)
      .eq("track_id", chapter.track_id)
      .eq("level", previousLevel)
      .maybeSingle();

    if (exam?.status !== "passed") {
      return { status: "error", message: t.examNextLockedNotice };
    }
  }

  const questions = await getQuizQuestions(chapterId);
  if (questions.length === 0) {
    return { status: "error", message: t.quizEmpty };
  }

  const assessmentToken = readTextValue(formData, "assessmentToken");
  const expectedQuestionIds = questions.map((question) => question.id);
  if (
    !verifyAssessmentToken(
      assessmentToken,
      `quiz:${chapter.id}`,
      user.id,
      expectedQuestionIds,
    )
  ) {
    return { status: "error", message: t.notConfigured };
  }

  let answered = 0;
  let correct = 0;
  const results: QuizQuestionResult[] = questions.map((question) => {
    const raw = readTextValue(formData, question.id);
    const selected = Number.parseInt(raw, 10);
    const isValid =
      raw !== "" &&
      Number.isInteger(selected) &&
      selected >= 0 &&
      selected < question.choices.length;
    const isCorrect = isValid && selected === question.answerIndex;
    if (isValid) answered += 1;
    if (isCorrect) correct += 1;

    return {
      id: question.id,
      question: question.question,
      choices: question.choices,
      selected: isValid ? selected : -1,
      correctIndex: question.answerIndex,
      correct: isCorrect,
      explanation: question.explanation,
    };
  });

  if (answered < questions.length) {
    const missing = questions
      .filter((question) => {
        const raw = readTextValue(formData, question.id);
        return raw === "";
      })
      .map((question) => question.id);
    console.error(
      "[learning] quiz incomplet",
      JSON.stringify({
        missing,
        received: [...formData.keys()],
        expected: questions.map((question) => question.id),
      }),
    );
    return { status: "error", message: t.quizUnanswered };
  }

  const score = Math.round((correct / questions.length) * 100);
  const passedNow = score >= passingScore;

  const attempts = (existing?.attempts ?? 0) + 1;
  const bestScore = Math.max(existing?.best_score ?? 0, score);
  const wasCompleted = existing?.status === "completed";
  const completed = passedNow || wasCompleted;

  const row: Record<string, unknown> = {
    user_id: user.id,
    chapter_id: chapterId,
    track_id: chapter.track_id,
    attempts,
    best_score: bestScore,
    status: completed ? "completed" : "in_progress",
  };

  if (completed && !wasCompleted) {
    row.completed_at = new Date().toISOString();
  } else if (!completed) {
    row.completed_at = null;
  }

  const { error } = await service
    .from("chapter_progress")
    .upsert(row, { onConflict: "user_id,chapter_id" });

  if (error) {
    console.error("[learning] progress", error.message);
    return { status: "error", message: t.notConfigured };
  }

  const next = passedNow ? siblings[index + 1] : undefined;

  try {
    refresh();
  } catch {
    void 0;
  }

  return {
    status: "success",
    score,
    passed: passedNow,
    attempts,
    bestScore,
    results,
    next: next ? { slug: next.slug, title: next.title } : null,
  };
}
