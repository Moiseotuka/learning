import { cache } from "react";

import type { LevelType } from "@/config/catalog";
import { getUser } from "@/lib/auth/dal";
import { playableVideos, videoTokens } from "@/lib/learning/video-playability";
import type {
  ChapterPage,
  ChapterProgress,
  ChapterResource,
  ChapterVideo,
  GradedQuestion,
  LearnerChapter,
  LearnerChapterDetail,
  LearnerTrack,
  LevelExamInfo,
  LevelExamState,
  QuizQuestion,
  TrackResourceGroup,
} from "@/lib/learning/types";
import { createServerSupabase } from "@/lib/supabase/server";
import { createServiceSupabase } from "@/lib/supabase/service";

type TrackRow = {
  id: string;
  slug: string;
  title: string;
  description: string;
  level: LevelType;
  duration_hours: number;
  modules_count: number;
  price_usd: number | null;
  rating: number;
  students: number;
  passing_score: number;
  categories: { name: string } | null;
  category_id: string;
};

type ChapterRow = {
  id: string;
  track_id: string;
  slug: string;
  title: string;
  summary: string;
  level: LevelType;
  position: number;
  videos: ChapterVideo[] | null;
};

type ProgressRow = {
  chapter_id: string;
  attempts: number;
  best_score: number | null;
  status: string;
  practice_done?: boolean | null;
};

type ExamRow = {
  track_id: string;
  level: string;
  status: string;
  best_score: number | null;
  attempts: number;
  passed_at: string | null;
};

const trackSelect =
  "id,slug,title,description,level,duration_hours,modules_count,price_usd,rating,students,passing_score,category_id,categories(name)";

const chapterSelect = "id,track_id,slug,title,summary,level,position,videos";

const progressSelect = "chapter_id,attempts,best_score,status,practice_done";

function toProgress(row: ProgressRow | undefined): ChapterProgress | null {
  if (!row) return null;
  return {
    attempts: row.attempts ?? 0,
    bestScore: row.best_score,
    completed: row.status === "completed",
  };
}

function toExamState(row: ExamRow | undefined): LevelExamState {
  if (!row) {
    return { status: "none", bestScore: null, attempts: 0, passedAt: null };
  }
  return {
    status: row.status === "passed" ? "passed" : "in_progress",
    bestScore: row.best_score,
    attempts: row.attempts ?? 0,
    passedAt: row.passed_at,
  };
}

function toLearnerTrack(
  track: TrackRow,
  chapters: ChapterRow[],
  progress: Map<string, ProgressRow>,
  watched: Map<string, string[]>,
  isLevelPaid: (level: LevelType) => boolean,
  exams: Map<string, ExamRow>,
): LearnerTrack {
  let previousCompleted = true;
  let completedCount = 0;
  let nextChapterSlug: string | null = null;

  const levelOrder: LevelType[] = [];
  for (const chapter of chapters) {
    if (!levelOrder.includes(chapter.level)) levelOrder.push(chapter.level);
  }

  const levels: LevelExamInfo[] = levelOrder.map((level) => {
    const levelChapters = chapters.filter(
      (chapter) => chapter.level === level,
    );
    const completedChapters = levelChapters.filter(
      (chapter) => progress.get(chapter.id)?.status === "completed",
    ).length;
    return {
      level,
      totalChapters: levelChapters.length,
      completedChapters,
      allCompleted:
        levelChapters.length > 0 && completedChapters === levelChapters.length,
      exam: toExamState(exams.get(`${track.id}:${level}`)),
    };
  });
  const examByLevel = new Map(
    levels.map((info) => [info.level, info.exam] as const),
  );

  const learnerChapters: LearnerChapter[] = chapters.map((chapter) => {
    const row = progress.get(chapter.id);
    const unlocked = previousCompleted;
    const completed = row?.status === "completed";
    if (completed) completedCount += 1;
    previousCompleted = completed;

    const levelIndex = levelOrder.indexOf(chapter.level);
    const previousLevel = levelIndex > 0 ? levelOrder[levelIndex - 1] : null;
    const examLocked =
      previousLevel !== null &&
      examByLevel.get(previousLevel)?.status !== "passed";

    const levelLocked = !isLevelPaid(chapter.level);

    if (
      !completed &&
      unlocked &&
      !examLocked &&
      !levelLocked &&
      !nextChapterSlug
    ) {
      nextChapterSlug = chapter.slug;
    }

    const tokens = videoTokens(toVideos(chapter.videos));
    const watchedIds = new Set(watched.get(chapter.id) ?? []);

    return {
      id: chapter.id,
      slug: chapter.slug,
      title: chapter.title,
      summary: chapter.summary,
      level: chapter.level,
      position: chapter.position,
      unlocked,
      levelLocked,
      examLocked,
      progress: toProgress(row),
      videosDone: tokens.every((token) => watchedIds.has(token)),
      practiceDone: row?.practice_done === true,
    };
  });

  const totalChapters = learnerChapters.length;

  return {
    id: track.id,
    slug: track.slug,
    title: track.title,
    description: track.description,
    level: track.level,
    durationHours: track.duration_hours,
    modules: track.modules_count,
    rating: Number(track.rating ?? 0),
    students: track.students ?? 0,
    priceUsd: track.price_usd,
    passingScore: track.passing_score ?? 70,
    category: track.categories?.name ?? "",
    categoryId: track.category_id ?? "",
    chapters: learnerChapters,
    levels,
    completedCount,
    totalChapters,
    percent:
      totalChapters === 0
        ? 0
        : Math.round((completedCount / totalChapters) * 100),
    nextChapterSlug:
      nextChapterSlug ??
      learnerChapters.find(
        (chapter) => chapter.unlocked && !chapter.levelLocked,
      )?.slug ??
      null,
  };
}

const fetchLearnerData = cache(async function fetchLearnerData() {
  const supabase = await createServerSupabase();
  if (!supabase) return null;

  // Les colonnes `videos` des chapitres ne sont plus lisibles par le rôle
  // client : la fiche d'un chapitre est donc portée par la clé de service,
  // tandis que les lignes de progression du reste du dossier restent lues avec
  // la session, filtrées par la RLS.
  const service = createServiceSupabase();
  if (!service) return null;

  const user = await getUser();

  const [tracks, chapters, progress, watched, prices, purchases, exams, granted] =
    await Promise.all([
      supabase
        .from("tracks")
        .select(trackSelect)
        .eq("published", true)
        .order("position"),
      service
        .from("chapters")
        .select(chapterSelect)
        .eq("published", true)
        .order("position"),
      supabase.from("chapter_progress").select(progressSelect),
      supabase
        .from("chapter_progress")
        .select("chapter_id,videos_watched"),
      supabase
        .from("category_level_prices")
        .select("category_id,level,price_usd"),
      supabase.from("purchases").select("category_id,level").eq("status", "paid"),
      supabase
        .from("level_exams")
        .select("track_id,level,status,best_score,attempts,passed_at"),
      // Droits hors achat : abonnement de formateur et place de classe. La
      // fonction est `security definer` parce que le quota de places se calcule
      // sur les classes d'AUTRUI, que la RLS ne montre pas à l'élève.
      user
        ? supabase.rpc("granted_category_ids", { p_user: user.id })
        : Promise.resolve({ data: [], error: null }),
    ]);

  if (tracks.error || chapters.error || progress.error) {
    console.error(
      "[learning]",
      tracks.error?.message ??
        chapters.error?.message ??
        progress.error?.message ??
        "no data",
    );
    return null;
  }

  if (watched.error) {
    console.warn(
      "[learning] videos watched : colonne absente — coller la migration 202610020001_video_watch.sql",
      watched.error.message,
    );
  }

  if (prices.error) {
    console.warn(
      "[learning] tarifs : colonne absente — coller la migration 202610030001_payments.sql",
      prices.error.message,
    );
  }

  if (purchases.error) {
    console.warn(
      "[learning] achats : colonne absente — coller la migration 202610030001_payments.sql",
      purchases.error.message,
    );
  }

  if (exams.error) {
    console.warn(
      "[learning] examens : table absente — coller la migration 202610020002_level_exams.sql",
      exams.error.message,
    );
  }

  if (granted.error) {
    console.warn(
      "[learning] droits formateur : fonction absente — coller la migration 202610140001_instructor_live.sql",
      granted.error.message,
    );
  }

  const progressMap = new Map<string, ProgressRow>();
  for (const row of (progress.data ?? []) as ProgressRow[]) {
    progressMap.set(row.chapter_id, row);
  }

  const watchedMap = new Map<string, string[]>();
  for (const row of (watched.data ?? []) as {
    chapter_id: string;
    videos_watched?: string[] | null;
  }[]) {
    watchedMap.set(row.chapter_id, row.videos_watched ?? []);
  }

  const chaptersByTrack = new Map<string, ChapterRow[]>();
  for (const row of (chapters.data ?? []) as ChapterRow[]) {
    const list = chaptersByTrack.get(row.track_id) ?? [];
    list.push(row);
    chaptersByTrack.set(row.track_id, list);
  }

  const paidLevels = new Map<string, Set<string>>();
  for (const row of (purchases.data ?? []) as {
    category_id: string;
    level: string;
  }[]) {
    const set = paidLevels.get(row.category_id) ?? new Set<string>();
    set.add(row.level);
    paidLevels.set(row.category_id, set);
  }

  const priceLevels = new Map<string, Map<string, number>>();
  for (const row of (prices.data ?? []) as {
    category_id: string;
    level: string;
    price_usd: number;
  }[]) {
    const map = priceLevels.get(row.category_id) ?? new Map<string, number>();
    map.set(row.level, row.price_usd);
    priceLevels.set(row.category_id, map);
  }

  const examMap = new Map<string, ExamRow>();
  for (const row of (exams.data ?? []) as ExamRow[]) {
    examMap.set(`${row.track_id}:${row.level}`, row);
  }

  const grantedCategories = new Set<string>(
    ((granted.data ?? []) as { category_id: string }[]).map(
      (row) => row.category_id,
    ),
  );

  return {
    tracks: (tracks.data ?? []) as unknown as TrackRow[],
    chaptersByTrack,
    progressMap,
    watchedMap,
    paidLevels,
    priceLevels,
    examMap,
    grantedCategories,
  };
});

type LearnerData = NonNullable<Awaited<ReturnType<typeof fetchLearnerData>>>;

/** Règle métier : le niveau débutant est gratuit pour tous les domaines. */
function hasLevelAccess(data: LearnerData, categoryId: string, level: string) {
  if (level === "debutant") return true;
  if (data.grantedCategories.has(categoryId)) return true;
  return data.paidLevels.get(categoryId)?.has(level) ?? false;
}

export async function getLearnerTracks(): Promise<LearnerTrack[]> {
  const data = await fetchLearnerData();
  if (!data) return [];

  return data.tracks
    .filter((track) => hasLevelAccess(data, track.category_id, track.level))
    .map((track) =>
      toLearnerTrack(
        track,
        data.chaptersByTrack.get(track.id) ?? [],
        data.progressMap,
        data.watchedMap,
        (level) => hasLevelAccess(data, track.category_id, level),
        data.examMap,
      ),
    );
}

export async function getLearnerTrack(slug: string): Promise<LearnerTrack | null> {
  const data = await fetchLearnerData();
  if (!data) return null;

  const track = data.tracks.find((item) => item.slug === slug);
  if (!track) return null;

  return toLearnerTrack(
    track,
    data.chaptersByTrack.get(track.id) ?? [],
    data.progressMap,
    data.watchedMap,
    (level) => hasLevelAccess(data, track.category_id, level),
    data.examMap,
  );
}

/**
 * Prix et droits d'accès de chaque niveau d'un domaine
 * (bandeau d'achat de la vue parcours). Null si Supabase n'est pas configuré.
 */
export async function getLevelPricing(categoryId: string): Promise<{
  access: Record<LevelType, boolean>;
  prices: Record<string, number>;
} | null> {
  const data = await fetchLearnerData();
  if (!data) return null;

  const levels: LevelType[] = ["debutant", "intermediaire", "avance", "projet"];
  const access = {} as Record<LevelType, boolean>;
  for (const level of levels) {
    access[level] = hasLevelAccess(data, categoryId, level);
  }

  return {
    access,
    prices: Object.fromEntries(data.priceLevels.get(categoryId) ?? []),
  };
}

export async function getTrackResources(
  trackId: string,
): Promise<TrackResourceGroup[]> {
  const supabase = createServiceSupabase();
  if (!supabase) return [];

  const { data, error } = await supabase
    .from("chapters")
    .select("slug,title,position,resources")
    .eq("track_id", trackId)
    .eq("published", true)
    .order("position");

  if (error || !data) {
    console.error("[learning] resources", error?.message ?? "no data");
    return [];
  }

  const rows = data as {
    slug: string;
    title: string;
    position: number;
    resources: ChapterResource[] | null;
  }[];

  return rows
    .map((row) => ({
      chapterSlug: row.slug,
      chapterTitle: row.title,
      position: row.position,
      resources: row.resources ?? [],
    }))
    .filter((group) => group.resources.length > 0);
}

export async function getTrackVideoCounts(
  trackId: string,
): Promise<Record<string, number>> {
  const supabase = createServiceSupabase();
  if (!supabase) return {};

  const { data, error } = await supabase
    .from("chapters")
    .select("slug,videos")
    .eq("track_id", trackId)
    .eq("published", true);

  if (error || !data) {
    console.error("[learning] video counts", error?.message ?? "no data");
    return {};
  }

  const rows = data as { slug: string; videos: ChapterVideo[] | null }[];
  const counts: Record<string, number> = {};
  for (const row of rows) {
    counts[row.slug] = playableVideos(toVideos(row.videos)).length;
  }
  return counts;
}

/** Nombre de pages numérotées du Cours par chapitre (clé = slug du chapitre). */
export async function getTrackPageCounts(
  trackId: string,
): Promise<Record<string, number>> {
  const supabase = createServiceSupabase();
  if (!supabase) return {};

  const { data: chapters, error: chaptersError } = await supabase
    .from("chapters")
    .select("id,slug")
    .eq("track_id", trackId)
    .eq("published", true);

  if (chaptersError || !chapters) {
    console.error("[learning] page counts", chaptersError?.message ?? "no data");
    return {};
  }

  const rows = chapters as { id: string; slug: string }[];
  if (rows.length === 0) return {};
  const slugById = new Map(rows.map((row) => [row.id, row.slug]));

  const { data: pages, error } = await supabase
    .from("chapter_pages")
    .select("chapter_id")
    .in("chapter_id", [...slugById.keys()]);

  if (error) {
    console.warn(
      "[learning] chapter_pages : table absente — coller la migration 202610040004_chapter_pages.sql",
      error.message,
    );
    return {};
  }

  const counts: Record<string, number> = {};
  for (const row of (pages ?? []) as { chapter_id: string }[]) {
    const slug = slugById.get(row.chapter_id);
    if (!slug) continue;
    counts[slug] = (counts[slug] ?? 0) + 1;
  }
  return counts;
}

type ChapterDetailRow = ChapterRow & {
  objectives: string[] | null;
  videos: ChapterVideo[] | null;
  content: string;
  exercise: string;
  starter_code: string | null;
  solution_code: string | null;
  code_language: string | null;
  resources: ChapterResource[] | null;
};

/** Blob de reprise stocké dans `chapter_progress.resume` (jsonb, tolérant). */
type ResumeBlob = {
  video: Record<string, unknown>;
  scrolls: Record<string, number>;
  page: number | null;
  step: string | null;
};

const RESUME_STEPS = [
  "objectifs",
  "videos",
  "cours",
  "exercice",
  "ressources",
  "quiz",
];

function normalizeResume(value: unknown): ResumeBlob {
  if (!value || typeof value !== "object") {
    return { video: {}, scrolls: {}, page: null, step: null };
  }

  const blob = value as Record<string, unknown>;
  const video =
    blob.video && typeof blob.video === "object"
      ? (blob.video as Record<string, unknown>)
      : {};

  const positiveInt = (input: unknown, max: number) =>
    typeof input === "number" && Number.isFinite(input) && input > 0
      ? Math.min(Math.floor(input), max)
      : null;

  // `scroll` a pu être écrit en nombre simple : la valeur est alors partagée
  // entre toutes les étapes.
  const rawScrolls =
    blob.scroll && typeof blob.scroll === "object"
      ? (blob.scroll as Record<string, unknown>)
      : typeof blob.scroll === "number"
        ? { cours: blob.scroll }
        : {};
  const scrolls: Record<string, number> = {};
  for (const [key, input] of Object.entries(rawScrolls)) {
    const parsed = positiveInt(input, 200_000);
    if (parsed !== null && RESUME_STEPS.includes(key)) scrolls[key] = parsed;
  }

  const step =
    typeof blob.step === "string" && RESUME_STEPS.includes(blob.step)
      ? blob.step
      : null;

  return { video, scrolls, page: positiveInt(blob.page, 500), step };
}

function toVideos(value: ChapterVideo[] | null): ChapterVideo[] {
  if (!Array.isArray(value)) return [];
  return value.filter(
    (video) =>
      video &&
      typeof video.url === "string" &&
      video.url.length > 0 &&
      typeof video.title === "string" &&
      video.title.length > 0,
  );
}

export async function getLearnerChapter(
  trackSlug: string,
  chapterSlug: string,
): Promise<LearnerChapterDetail | null> {
  const track = await getLearnerTrack(trackSlug);
  if (!track) return null;

  // Les colonnes de contenu (vidéos, cours écrits, corrigés, ressources) ne se
  // lisent plus qu'avec la clé de service ; le droit d'accès, lui, reste décidé
  // ci-dessous avec les lignes de progression de l'apprenant.
  const supabase = createServiceSupabase();
  if (!supabase) return null;

  const index = track.chapters.findIndex((chapter) => chapter.slug === chapterSlug);
  if (index < 0) return null;

  const summary = track.chapters[index];
  const previous = index > 0 ? track.chapters[index - 1] : null;
  const next = index < track.chapters.length - 1 ? track.chapters[index + 1] : null;

  const userId = (await getUser())?.id ?? "";

  const [
    { data, error },
    { data: practiceRow, error: practiceError },
    { data: watchedRow, error: watchedError },
    { data: resumeRow, error: resumeError },
    { data: pageRows, error: pagesError },
  ] = await Promise.all([
    supabase
      .from("chapters")
      .select(
        "id,track_id,slug,title,summary,level,position,objectives,videos,content,exercise,starter_code,solution_code,code_language,resources",
      )
      .eq("id", summary.id)
      .maybeSingle(),
    supabase
      .from("chapter_progress")
      .select("practice_done,solution_viewed")
      .eq("user_id", userId)
      .eq("chapter_id", summary.id)
      .maybeSingle(),
    supabase
      .from("chapter_progress")
      .select("videos_watched")
      .eq("user_id", userId)
      .eq("chapter_id", summary.id)
      .maybeSingle(),
    supabase
      .from("chapter_progress")
      .select("resume")
      .eq("user_id", userId)
      .eq("chapter_id", summary.id)
      .maybeSingle(),
    supabase
      .from("chapter_pages")
      .select("position,title,content")
      .eq("chapter_id", summary.id)
      .order("position"),
  ]);

  if (practiceError) {
    console.error("[learning] practice state", practiceError.message);
  }
  if (watchedError) {
    console.warn(
      "[learning] videos watched : colonne absente — coller la migration 202610020001_video_watch.sql",
      watchedError.message,
    );
  }
  if (resumeError) {
    console.warn(
      "[learning] resume : colonne absente — coller la migration 202610120001_resume_position.sql",
      resumeError.message,
    );
  }
  if (pagesError) {
    console.warn(
      "[learning] chapter_pages : table absente — coller la migration 202610040004_chapter_pages.sql",
      pagesError.message,
    );
  }

  if (error || !data) {
    console.error("[learning] chapter", error?.message ?? "no data");
    return null;
  }

  const row = data as ChapterDetailRow;

  const pages: ChapterPage[] = (pageRows ?? [])
    .filter(
      (page): page is { position: number; title: string; content: string } =>
        typeof page?.position === "number" &&
        typeof page?.title === "string" &&
        typeof page?.content === "string",
    )
    .map((page) => ({
      position: page.position,
      title: page.title,
      content: page.content,
    }));

  const videos = playableVideos(toVideos(row.videos));
  const tokens = videoTokens(videos);
  const watchedIds = new Set(
    (watchedRow as { videos_watched?: string[] | null } | null)
      ?.videos_watched ?? [],
  );
  const videosDone = tokens.every((token) => watchedIds.has(token));
  const videoWatched = tokens.filter((token) => watchedIds.has(token));

  const resumeBlob = normalizeResume(
    (resumeRow as { resume?: unknown } | null)?.resume,
  );
  const videoSeconds: Record<string, number> = {};
  for (const token of tokens) {
    // Une leçon déjà vue repart du début : pas de reprise à sa dernière seconde.
    if (watchedIds.has(token)) continue;
    const value = resumeBlob.video[token];
    if (typeof value === "number" && Number.isFinite(value) && value > 10) {
      videoSeconds[token] = Math.min(Math.floor(value), 21_600);
    }
  }

  const levelIndex = track.levels.findIndex(
    (info) => info.level === summary.level,
  );
  const previousLevel =
    levelIndex > 0 ? track.levels[levelIndex - 1].level : null;
  const examHref =
    summary.examLocked && previousLevel
      ? `/app/parcours/${track.slug}/niveaux/${previousLevel}/examen`
      : null;

  // Marchandise verrouillée : niveau non acheté, examen de niveau précédent non
  // passé, ou chapitre encore fermé dans la séquence. La leçon n'est pas envoyée
  // au navigateur, même sérialisée dans la charge serveur — sans ce masque,
  // l'écran de verrou cachait un payload complet.
  const locked = summary.levelLocked || summary.examLocked || !summary.unlocked;

  return {
    id: row.id,
    slug: row.slug,
    trackId: row.track_id,
    trackSlug: track.slug,
    trackTitle: track.title,
    categoryId: track.categoryId,
    title: row.title,
    summary: row.summary,
    level: row.level,
    position: row.position,
    objectives: locked ? [] : row.objectives ?? [],
    videos: locked ? [] : videos,
    videoTokens: locked ? [] : tokens,
    videoWatched,
    videosDone,
    videoSeconds,
    resumePage: resumeBlob.page,
    resumeStep: resumeBlob.step,
    resumeScrolls: resumeBlob.scrolls,
    content: locked ? "" : row.content,
    pages: locked ? [] : pages,
    exercise: locked ? "" : row.exercise,
    starterCode: locked ? "" : row.starter_code ?? "",
    solutionCode: locked ? "" : row.solution_code ?? "",
    codeLanguage: locked ? "" : row.code_language ?? "",
    practice: {
      done: (practiceRow as { practice_done?: boolean } | null)?.practice_done ?? false,
      solutionViewed:
        (practiceRow as { solution_viewed?: boolean } | null)?.solution_viewed ?? false,
    },
    resources: locked ? [] : row.resources ?? [],
    passingScore: track.passingScore,
    chapterCount: track.totalChapters,
    unlocked: summary.unlocked,
    levelLocked: summary.levelLocked,
    examLocked: summary.examLocked,
    examHref,
    progress: summary.progress,
    prevSlug: previous?.slug ?? null,
    nextSlug: next?.slug ?? null,
    nextUnlocked: next ? next.unlocked && !next.examLocked : false,
  };
}

export async function getQuizQuestions(chapterId: string): Promise<GradedQuestion[]> {
  const supabase = createServiceSupabase();
  if (!supabase) return [];

  const { data, error } = await supabase
    .from("quiz_questions")
    .select("id,question,choices,answer_index,explanation,position")
    .eq("chapter_id", chapterId)
    .order("position");

  if (error || !data) {
    console.error("[learning] quiz", error?.message ?? "no data");
    return [];
  }

  return (data as {
    id: string;
    question: string;
    choices: string[];
    answer_index: number;
    explanation: string;
  }[]).map((row) => ({
    id: row.id,
    question: row.question,
    choices: row.choices ?? [],
    answerIndex: row.answer_index,
    explanation: row.explanation,
  }));
}

/** Questions graduées de plusieurs chapitres (examen — usage serveur seul). */
export async function getLevelGradedQuestions(
  chapterIds: string[],
): Promise<GradedQuestion[]> {
  if (chapterIds.length === 0) return [];
  const supabase = createServiceSupabase();
  if (!supabase) return [];

  const { data, error } = await supabase
    .from("quiz_questions")
    .select("id,question,choices,answer_index,explanation,position,chapter_id")
    .in("chapter_id", chapterIds)
    .order("position");

  if (error || !data) {
    console.error("[learning] exam questions", error?.message ?? "no data");
    return [];
  }

  return (data as {
    id: string;
    question: string;
    choices: string[];
    answer_index: number;
    explanation: string;
  }[]).map((row) => ({
    id: row.id,
    question: row.question,
    choices: row.choices ?? [],
    answerIndex: row.answer_index,
    explanation: row.explanation,
  }));
}

/**
 * Toutes les questions de l'examen de fin de niveau (sans réponse ni
 * explication) : le tirage aléatoire de 10 se fait côté client au montage,
 * l'action de soumission re-vérifie les réponses côté serveur.
 */
export async function getLevelExamQuestions(
  chapterIds: string[],
): Promise<QuizQuestion[]> {
  const graded = await getLevelGradedQuestions(chapterIds);
  return graded.map((question) => ({
    id: question.id,
    question: question.question,
    choices: question.choices,
  }));
}
