"use server";

import { refresh } from "next/cache";
import { redirect } from "next/navigation";

import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import { chapterLevelLocked } from "@/lib/actions/learning";
import { getLearnerTrack } from "@/lib/learning/queries";
import type { QuizState } from "@/lib/learning/types";
import { createServerSupabase } from "@/lib/supabase/server";
import { createServiceSupabase } from "@/lib/supabase/service";

const t = messages.learner;

const LEVELS = ["debutant", "intermediaire", "avance", "projet"] as const;

/** Garde-fous des valeurs de reprise : le client est une source non fiable. */
const MAX_PAGE = 500;
const MAX_SCROLL = 200_000;

function readText(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

function clampNumber(value: number | undefined, max: number) {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    return null;
  }
  return Math.min(Math.floor(value), max);
}

const STEPS = [
  "objectifs",
  "videos",
  "cours",
  "exercice",
  "ressources",
  "quiz",
] as const;

export type ResumeInput = {
  chapterId: string;
  /** Étape du chapitre affichée : c'est elle que l'apprenant retrouve en revenant. */
  step?: string;
  page?: number;
  scroll?: number;
};

/**
 * Enregistre la position d'un cours écrit (étape, page, défilement) pour que
 * l'apprenant reprenne où il s'était arrêté. Les secondes de vidéo ne passent
 * plus par ici : la reprise de lecture est déduite de la preuve de visionnage,
 * que seul le serveur sait écrire (`recordVideoTick`).
 * Écriture tolérante : une anomalie n'est jamais remontée à l'interface.
 */
export async function saveResume(input: ResumeInput): Promise<void> {
  const chapterId = typeof input.chapterId === "string" ? input.chapterId : "";
  if (!chapterId) return;

  const user = await requireUser(links.login);
  const supabase = await createServerSupabase();
  if (!supabase) return;

  const { data: chapter } = await supabase
    .from("chapters")
    .select("id,track_id,published,level")
    .eq("id", chapterId)
    .maybeSingle();

  if (!chapter?.published) return;

  // La reprise n'ouvre aucun contenu : elle ne se justifie que sur un niveau
  // que l'apprenant possède déjà.
  if (await chapterLevelLocked(supabase, user.id, chapter)) return;

  const { data: row } = await supabase
    .from("chapter_progress")
    .select("resume")
    .eq("user_id", user.id)
    .eq("chapter_id", chapterId)
    .maybeSingle();

  const previous =
    row?.resume && typeof row.resume === "object"
      ? (row.resume as Record<string, unknown>)
      : {};

  const resume: Record<string, unknown> = { ...previous };

  const step =
    typeof input.step === "string" &&
    (STEPS as readonly string[]).includes(input.step)
      ? input.step
      : "";
  if (step) resume.step = step;

  const page = clampNumber(input.page, MAX_PAGE);
  if (page !== null) resume.page = page;

  const scroll = clampNumber(input.scroll, MAX_SCROLL);
  if (scroll !== null && step) {
    // Défilement par étape : la position d'un cours écrit ne se restaure pas
    // sur l'étape Vidéos.
    const previousScrolls =
      previous.scroll && typeof previous.scroll === "object"
        ? (previous.scroll as Record<string, unknown>)
        : {};
    resume.scroll = { ...previousScrolls, [step]: scroll };
  }

  const { error } = await supabase
    .from("chapter_progress")
    .upsert(
      {
        user_id: user.id,
        chapter_id: chapterId,
        track_id: chapter.track_id,
        resume,
      },
      { onConflict: "user_id,chapter_id" },
    );

  if (error) {
    console.warn("[learning] reprise", error.message);
  }
}

type RestartOutcome = { target: string } | { refused: string };

async function runRestart(
  trackSlug: string,
  level: string,
  userId: string,
): Promise<RestartOutcome> {
  const track = await getLearnerTrack(trackSlug);
  if (!track) return { refused: t.notConfigured };

  const levelInfo = track.levels.find((item) => item.level === level);
  if (!levelInfo) return { refused: t.notConfigured };
  if (levelInfo.exam.status === "passed") {
    return { refused: t.restartLevelRefused };
  }

  const chapters = track.chapters
    .filter((chapter) => chapter.level === level)
    .sort((a, b) => a.position - b.position);

  if (chapters.length === 0) return { refused: t.notConfigured };

  // Remise à zéro d'une progression que seul le serveur sait écrire.
  const service = createServiceSupabase();
  if (!service) return { refused: t.notConfigured };

  const { error } = await service
    .from("chapter_progress")
    .update({
      attempts: 0,
      best_score: null,
      status: "in_progress",
      completed_at: null,
      videos_watched: [],
      practice_done: false,
      solution_viewed: false,
      watch_proof: {},
      resume: {},
    })
    .eq("user_id", userId)
    .in(
      "chapter_id",
      chapters.map((chapter) => chapter.id),
    );

  if (error) {
    console.error("[learning] reprise de niveau", error.message);
    return { refused: t.quizError };
  }

  // level_exams n'autorise aucune écriture côté apprenant : la ligne est
  // supprimée avec le rôle service, sinon l'examen resterait « in_progress ».
  const { error: examError } = await service
    .from("level_exams")
    .delete()
    .eq("user_id", userId)
    .eq("track_id", track.id)
    .eq("level", level);

  if (examError) {
    console.error("[learning] reprise examen", examError.message);
  }

  try {
    refresh();
  } catch {
    void 0;
  }

  return {
    target: `/app/parcours/${track.slug}/chapitres/${chapters[0].slug}?notice=reprise`,
  };
}

/**
 * Quand les trois tentatives sont épuisées, l'apprenant doit reprendre tout le
 * niveau : leçons vidéo, pages lues, exercices et quiz repartent de zéro.
 */
export async function restartLevel(
  _prevState: QuizState | undefined,
  formData: FormData,
): Promise<QuizState> {
  const trackSlug = readText(formData, "trackSlug");
  const level = readText(formData, "level");

  if (!trackSlug || !(LEVELS as readonly string[]).includes(level)) {
    return { status: "error", message: t.notConfigured };
  }

  let outcome: RestartOutcome;

  try {
    const user = await requireUser(links.dashboard);
    outcome = await runRestart(trackSlug, level, user.id);
  } catch (error) {
    const digest = (error as { digest?: string } | null)?.digest;
    if (typeof digest === "string" && digest.startsWith("NEXT_REDIRECT")) {
      throw error;
    }
    console.error("[learning] restart level", error);
    return { status: "error", message: t.quizError };
  }

  if ("refused" in outcome) {
    return { status: "error", message: outcome.refused };
  }

  redirect(outcome.target);
}
