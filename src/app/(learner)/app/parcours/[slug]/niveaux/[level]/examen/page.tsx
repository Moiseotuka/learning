import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeftIcon, AwardIcon, LockIcon } from "lucide-react";
import { notFound } from "next/navigation";

import { QuizErrorBoundary } from "@/components/learning/quiz-error-boundary";
import { ExamPlayer } from "@/components/learning/exam-player";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import {
  getLearnerTrack,
  getLevelExamQuestions,
} from "@/lib/learning/queries";
import { createAssessmentToken, drawExamQuestions } from "@/lib/security/assessment";

const t = messages.learner;

export const metadata: Metadata = {
  title: t.examTitle,
  robots: { index: false },
};

export default async function LevelExamPage({
  params,
}: {
  params: Promise<{ slug: string; level: string }>;
}) {
  const { slug, level } = await params;
  const user = await requireUser(links.dashboard);
  const track = await getLearnerTrack(slug);
  if (!track) notFound();

  const levelInfo = track.levels.find((item) => item.level === level);
  if (!levelInfo) notFound();

  const trackHref = `/app/parcours/${track.slug}`;
  const levelChapters = track.chapters.filter(
    (chapter) => chapter.level === levelInfo.level,
  );
  const levelLocked = levelChapters.some((chapter) => chapter.levelLocked);
  const ready = levelInfo.allCompleted && !levelLocked;

  const questions = ready
    ? await getLevelExamQuestions(levelChapters.map((chapter) => chapter.id))
    : [];
  const examScope = `exam:${track.id}:${level}`;
  const examQuestions = drawExamQuestions(questions, examScope, user.id, 10);
  const assessmentToken =
    examQuestions.length > 0
      ? createAssessmentToken(
          examScope,
          user.id,
          examQuestions.map((question) => question.id),
        )
      : "";
  const empty = questions.length === 0;

  return (
    <div>
      <header>
        <Button
          asChild
          variant="ghost"
          className="-ml-2 -mt-1 h-8 px-2 text-xs text-muted-foreground"
        >
          <Link href={trackHref}>
            <ArrowLeftIcon aria-hidden />
            {track.title}
          </Link>
        </Button>

        <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
          <span>{messages.common.levels[levelInfo.level]}</span>
          <span>
            {t.chaptersLabel(
              levelInfo.completedChapters,
              levelInfo.totalChapters,
            )}
          </span>
        </div>

        <h1 className="mt-2 text-2xl font-semibold tracking-tight text-foreground">
          {t.examTitle}
        </h1>
        <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
          {track.title}
        </p>

        <dl className="mt-3 flex flex-wrap gap-x-6 gap-y-2 border-t border-hairline pt-3 text-xs">
          <div className="flex items-center gap-2">
            <dt className="text-muted-foreground">{t.metricQuizzes}</dt>
            <dd className="font-semibold tabular-nums text-foreground">
              {t.quizAttempts(levelInfo.exam.attempts)}
            </dd>
          </div>
          <div className="flex items-center gap-2">
            <dt className="text-muted-foreground">{t.metricBest}</dt>
            <dd className="font-semibold tabular-nums text-foreground">
              {levelInfo.exam.bestScore !== null
                ? `${levelInfo.exam.bestScore} %`
                : t.noScore}
            </dd>
          </div>
          <div className="flex items-center gap-2">
            <dt className="text-muted-foreground">{t.passingLabel}</dt>
            <dd className="font-semibold tabular-nums text-foreground">
              {track.passingScore} %
            </dd>
          </div>
          {levelInfo.exam.status === "passed" ? (
            <div className="flex items-center gap-2">
              <dt className="text-muted-foreground">{t.status.completed}</dt>
              <dd className="font-semibold text-emerald-600 dark:text-emerald-400">
                <AwardIcon className="inline size-3.5" aria-hidden />{" "}
                {t.examPassedBadge}
              </dd>
            </div>
          ) : null}
        </dl>
      </header>

      <div className="mt-4">
        {!ready || empty ? (
          <div className="rounded-2xl border border-hairline bg-card p-6 text-center">
            <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-muted text-muted-foreground">
              <LockIcon className="size-6" aria-hidden />
            </span>
            <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
              {levelLocked
                ? t.levelLockedMsg
                : !levelInfo.allCompleted
                  ? t.examLocked
                  : t.examEmpty}
            </p>
            <Button asChild className="mt-5 h-10 px-4">
              <Link
                href={
                  levelLocked
                    ? `/app/acheter?cat=${track.categoryId}&level=${levelInfo.level}`
                    : trackHref
                }
              >
                {levelLocked ? messages.payment.unlockCta : t.backToTrack}
              </Link>
            </Button>
          </div>
        ) : (
          <QuizErrorBoundary>
            <ExamPlayer
              trackSlug={track.slug}
              level={levelInfo.level}
              questions={examQuestions}
              passingScore={track.passingScore}
              attempts={levelInfo.exam.attempts}
              bestScore={levelInfo.exam.bestScore}
              passed={levelInfo.exam.status === "passed"}
              assessmentToken={assessmentToken}
            />
          </QuizErrorBoundary>
        )}
      </div>
    </div>
  );
}
