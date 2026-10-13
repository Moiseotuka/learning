"use server";

import { refresh } from "next/cache";

import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import { ensureCertificates } from "@/lib/certificates/issue";
import { MAX_ATTEMPTS } from "@/lib/learning/attempts";
import { EXAM_SIZE } from "@/lib/learning/exam-size";
import {
  getLearnerTrack,
  getLevelGradedQuestions,
} from "@/lib/learning/queries";
import type { QuizState } from "@/lib/learning/types";
import { verifyAssessmentToken } from "@/lib/security/assessment";
import { createServiceSupabase } from "@/lib/supabase/service";

const t = messages.learner;

const LEVELS = ["debutant", "intermediaire", "avance", "projet"] as const;

function readTextValue(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Examen final de niveau : 10 questions tirées des quiz du niveau, scoring
 * côté serveur, écriture level_exams (service role — la table n'a pas de
 * policy d'écriture pour authenticated) puis délivrance des certificats dus.
 */
export async function submitLevelExam(
  _prevState: QuizState | undefined,
  formData: FormData,
): Promise<QuizState> {
  try {
    return await runLevelExamSubmission(formData);
  } catch (error) {
    const digest = (error as { digest?: string } | null)?.digest;
    if (typeof digest === "string" && digest.startsWith("NEXT_REDIRECT")) {
      throw error;
    }
    console.error("[learning] exam submit", error);
    return { status: "error", message: t.quizError };
  }
}

async function runLevelExamSubmission(formData: FormData): Promise<QuizState> {
  const user = await requireUser(links.dashboard);

  const trackSlug = readTextValue(formData, "trackSlug");
  const level = readTextValue(formData, "level");
  if (!trackSlug || !(LEVELS as readonly string[]).includes(level)) {
    return { status: "error", message: t.notConfigured };
  }

  const track = await getLearnerTrack(trackSlug);
  if (!track) {
    return { status: "error", message: t.notConfigured };
  }

  const levelChapters = track.chapters.filter(
    (chapter) => chapter.level === level,
  );
  if (levelChapters.length === 0) {
    return { status: "error", message: t.examEmpty };
  }

  if (levelChapters.some((chapter) => chapter.levelLocked)) {
    return { status: "error", message: t.levelLockedMsg };
  }

  if (!levelChapters.every((chapter) => chapter.progress?.completed)) {
    return { status: "error", message: t.examLocked };
  }

  const service = createServiceSupabase();
  if (!service) {
    return { status: "error", message: t.notConfigured };
  }

  const { data: existing, error: readError } = await service
    .from("level_exams")
    .select("attempts,best_score,status,passed_at")
    .eq("user_id", user.id)
    .eq("track_id", track.id)
    .eq("level", level)
    .maybeSingle();

  if (readError) {
    console.error("[learning] exam read", readError.message);
    return { status: "error", message: t.notConfigured };
  }

  // Même règle que le quiz : trois tentatives, puis le niveau est à reprendre.
  if ((existing?.attempts ?? 0) >= MAX_ATTEMPTS && existing?.status !== "passed") {
    return { status: "error", message: t.examAttemptsExhausted };
  }

  const graded = await getLevelGradedQuestions(
    levelChapters.map((chapter) => chapter.id),
  );
  const byId = new Map(graded.map((question) => [question.id, question]));
  if (byId.size === 0) {
    return { status: "error", message: t.examEmpty };
  }

  const assessmentToken = readTextValue(formData, "assessmentToken");
  const rawIds = readTextValue(formData, "questionIds")
    .split(",")
    .map((id) => id.trim())
    .filter((id) => id.length > 0);
  const ids = [...new Set(rawIds)];
  const expected = Math.min(EXAM_SIZE, byId.size);
  if (
    ids.length !== expected ||
    ids.some((id) => !byId.has(id)) ||
    !verifyAssessmentToken(
      assessmentToken,
      `exam:${track.id}:${level}`,
      user.id,
      ids,
    )
  ) {
    return { status: "error", message: t.notConfigured };
  }

  let answered = 0;
  let correct = 0;
  const results = ids.map((id) => {
    const question = byId.get(id)!;
    const raw = readTextValue(formData, id);
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

  if (answered < ids.length) {
    return { status: "error", message: t.examUnanswered };
  }

  const score = Math.round((correct / ids.length) * 100);
  const passingScore = track.passingScore;
  const passedNow = score >= passingScore;

  const attempts = (existing?.attempts ?? 0) + 1;
  const bestScore = Math.max(existing?.best_score ?? 0, score);
  const wasPassed = existing?.status === "passed";
  const passed = passedNow || wasPassed;

  const { error } = await service.from("level_exams").upsert(
    {
      user_id: user.id,
      track_id: track.id,
      level,
      attempts,
      best_score: bestScore,
      status: passed ? "passed" : "in_progress",
      passed_at: passed
        ? (existing?.passed_at ?? new Date().toISOString())
        : null,
    },
    { onConflict: "user_id,track_id,level" },
  );

  if (error) {
    console.error("[learning] exam write", error.message);
    return { status: "error", message: t.notConfigured };
  }

  if (passedNow && !wasPassed) {
    try {
      await ensureCertificates(user.id, track.id);
    } catch (certError) {
      console.error("[certificates] issue", certError);
    }
  }

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
    next: null,
  };
}
