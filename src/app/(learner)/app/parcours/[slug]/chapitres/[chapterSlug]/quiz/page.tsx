import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeftIcon, LockIcon } from "lucide-react";
import { notFound } from "next/navigation";

import { QuizErrorBoundary } from "@/components/learning/quiz-error-boundary";
import { QuizPlayer } from "@/components/learning/quiz-player";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import { getLearnerChapter, getQuizQuestions } from "@/lib/learning/queries";
import { createAssessmentToken } from "@/lib/security/assessment";

const t = messages.learner;

export const metadata: Metadata = {
  title: t.quizTitle,
  robots: { index: false },
};

export default async function QuizPage({
  params,
}: {
  params: Promise<{ slug: string; chapterSlug: string }>;
}) {
  const { slug, chapterSlug } = await params;
  const user = await requireUser(links.dashboard);
  const chapter = await getLearnerChapter(slug, chapterSlug);
  if (!chapter) notFound();

  const trackHref = `/app/parcours/${chapter.trackSlug}`;
  const chapterHref = `${trackHref}/chapitres/${chapter.slug}`;

  // Verrou strict : niveau non payé (levelLocked), chapitre non atteint
  // (unlocked) ou examen de fin de niveau précédent non réussi (examLocked).
  const levelLocked = chapter.levelLocked;
  const locked = levelLocked || !chapter.unlocked || chapter.examLocked;
  const videosPending = chapter.videos.length > 0 && !chapter.videosDone;

  // Les questions ne sont tirées (service role) que si le chapitre est
  // réellement ouvert : aucun quiz d'un niveau non payé n'est chargé.
  const questions =
    locked || videosPending ? [] : await getQuizQuestions(chapter.id);
  const assessmentToken =
    questions.length > 0
      ? createAssessmentToken(`quiz:${chapter.id}`, user.id, questions.map((question) => question.id))
      : "";
  const empty = questions.length === 0;
  const attempts = chapter.progress?.attempts ?? 0;

  return (
    <div>
      <header>
        <Button
          asChild
          variant="ghost"
          className="-ml-2 -mt-1 h-8 px-2 text-xs text-muted-foreground"
        >
          <Link href={chapterHref}>
            <ArrowLeftIcon aria-hidden />
            {chapter.title}
          </Link>
        </Button>

        <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
          <span>{messages.common.levels[chapter.level]}</span>
          <span>
            {t.chapterList} · {chapter.position}
          </span>
        </div>

        <h1 className="mt-2 text-2xl font-semibold tracking-tight text-foreground">
          {t.quizTitle}
        </h1>
        <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
          {chapter.title}
        </p>

        <dl className="mt-3 flex flex-wrap gap-x-6 gap-y-2 border-t border-hairline pt-3 text-xs">
          <div className="flex items-center gap-2">
            <dt className="text-muted-foreground">{t.metricQuizzes}</dt>
            <dd className="font-semibold tabular-nums text-foreground">
              {t.quizAttempts(attempts)}
            </dd>
          </div>
          <div className="flex items-center gap-2">
            <dt className="text-muted-foreground">{t.metricBest}</dt>
            <dd className="font-semibold tabular-nums text-foreground">
              {chapter.progress?.bestScore !== null &&
              chapter.progress?.bestScore !== undefined
                ? `${chapter.progress.bestScore} %`
                : t.noScore}
            </dd>
          </div>
          <div className="flex items-center gap-2">
            <dt className="text-muted-foreground">{t.passingLabel}</dt>
            <dd className="font-semibold tabular-nums text-foreground">
              {chapter.passingScore} %
            </dd>
          </div>
        </dl>
      </header>

      <div className="mt-4">
        {locked || videosPending || empty ? (
          <div className="rounded-2xl border border-hairline bg-card p-6 text-center">
            <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-muted text-muted-foreground">
              <LockIcon className="size-6" aria-hidden />
            </span>
            <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
              {levelLocked
                ? t.levelLockedNotice
                : locked
                  ? chapter.examLocked
                    ? t.examNextLockedNotice
                    : t.quizLocked
                  : videosPending
                    ? t.videosLocked
                    : t.quizEmpty}
            </p>
            <Button asChild className="mt-5 h-10 px-4">
              <Link
                href={
                  levelLocked
                    ? `/app/acheter?cat=${chapter.categoryId}&level=${chapter.level}`
                    : locked
                      ? chapter.examLocked
                        ? (chapter.examHref ?? trackHref)
                        : trackHref
                      : videosPending
                        ? `${chapterHref}?etape=videos`
                        : chapterHref
                }
              >
                {levelLocked
                  ? messages.payment.unlockCta
                  : locked
                    ? chapter.examLocked && chapter.examHref
                      ? t.examCta
                      : t.backToTrack
                    : videosPending
                      ? t.reviewVideos
                      : t.reviewChapter}
              </Link>
            </Button>
          </div>
        ) : (
          <QuizErrorBoundary>
            <QuizPlayer
              chapterId={chapter.id}
              trackSlug={chapter.trackSlug}
              chapterSlug={chapter.slug}
              questions={questions.map((question) => ({
                id: question.id,
                question: question.question,
                choices: question.choices,
              }))}
              passingScore={chapter.passingScore}
              attempts={chapter.progress?.attempts ?? 0}
              bestScore={chapter.progress?.bestScore ?? null}
              assessmentToken={assessmentToken}
            />
          </QuizErrorBoundary>
        )}
      </div>
    </div>
  );
}
