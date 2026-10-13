"use client";

import {
  ArrowRightIcon,
  CheckCircle2Icon,
  RotateCcwIcon,
  XCircleIcon,
} from "lucide-react";
import Link from "next/link";
import { useActionState, useEffect, useState } from "react";

import { Notice } from "@/components/auth/notice";
import { QuestionCarousel } from "@/components/learning/question-carousel";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { submitQuiz } from "@/lib/actions/learning";
import { MAX_ATTEMPTS } from "@/lib/learning/attempts";
import type { QuizQuestion } from "@/lib/learning/types";
import { cn } from "cn";

const t = messages.learner;

type QuizPlayerProps = {
  chapterId: string;
  trackSlug: string;
  chapterSlug: string;
  questions: QuizQuestion[];
  passingScore: number;
  attempts?: number;
  bestScore?: number | null;
  assessmentToken: string;
};

export function QuizPlayer(props: QuizPlayerProps) {
  const [attemptKey, setAttemptKey] = useState(0);

  return (
    <QuizAttempt
      key={attemptKey}
      {...props}
      onRetry={() => setAttemptKey((value) => value + 1)}
    />
  );
}

function QuizAttempt({
  chapterId,
  trackSlug,
  chapterSlug,
  questions,
  passingScore,
  attempts = 0,
  bestScore = null,
  assessmentToken,
  onRetry,
}: QuizPlayerProps & { onRetry: () => void }) {
  const [state, action, pending] = useActionState(submitQuiz, undefined);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [suspiciousActivity, setSuspiciousActivity] = useState(0);

  useEffect(() => {
    const handleBlur = () => setSuspiciousActivity((value) => value + 1);
    const handleVisibility = () => {
      if (document.visibilityState === "hidden") {
        setSuspiciousActivity((value) => value + 1);
      }
    };

    window.addEventListener("blur", handleBlur);
    document.addEventListener("visibilitychange", handleVisibility);

    return () => {
      window.removeEventListener("blur", handleBlur);
      document.removeEventListener("visibilitychange", handleVisibility);
    };
  }, []);

  const results = state?.results;
  const chapterHref = `/app/parcours/${trackSlug}/chapitres/${chapterSlug}`;
  const trackHref = `/app/parcours/${trackSlug}`;

  if (state?.status === "success" && results) {
    const passed = Boolean(state.passed);

    return (
      <div className="space-y-6">
        <div
          className={cn(
            "rounded-2xl border p-5",
            passed
              ? "border-emerald-500/40 bg-emerald-500/10"
              : "border-destructive/40 bg-destructive/10",
          )}
        >
          <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
            {t.quizScore}
          </p>
          <p
            className={cn(
              "mt-1 text-4xl font-semibold",
              passed
                ? "text-emerald-600 dark:text-emerald-400"
                : "text-destructive",
            )}
          >
            {state.score} %
          </p>
          <p className="mt-2 text-sm text-foreground">
            {passed
              ? t.quizPassed(state.score ?? 0)
              : t.quizFailed(state.score ?? 0, passingScore)}
          </p>
          <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
            <span>{t.quizAttempts(state.attempts ?? attempts)}</span>
            <span>{t.quizBest(state.bestScore ?? bestScore ?? 0)}</span>
            <span>{t.unlockNotice(passingScore)}</span>
          </div>

          <div className="mt-4 flex flex-wrap gap-3">
            {passed && state.next ? (
              <Button asChild className="h-10 px-4">
                <Link
                  href={`/app/parcours/${trackSlug}/chapitres/${state.next.slug}`}
                >
                  {t.nextChapter}
                  <ArrowRightIcon aria-hidden />
                </Link>
              </Button>
            ) : null}
            {passed && !state.next ? (
              <Button asChild className="h-10 px-4">
                <Link href={trackHref}>{t.backToTrack}</Link>
              </Button>
            ) : null}
            <Button asChild variant="outline" className="h-10 px-4">
              <Link href={chapterHref}>{t.reviewChapter}</Link>
            </Button>
            {!passed && (state.attempts ?? attempts) < MAX_ATTEMPTS ? (
              <Button
                variant="ghost"
                className="h-10 px-4"
                onClick={onRetry}
                disabled={pending}
              >
                <RotateCcwIcon aria-hidden />
                {t.quizRetake}
              </Button>
            ) : null}
            {!passed && (state.attempts ?? attempts) >= MAX_ATTEMPTS ? (
              <p className="text-xs leading-relaxed text-muted-foreground">
                {t.quizAttemptsExhausted}
              </p>
            ) : null}
          </div>
        </div>

        <div>
          <h3 className="text-sm font-semibold text-foreground">
            {t.quizResult}
          </h3>
          <ol className="mt-3 space-y-3">
            {results.map((result, index) => (
              <li
                key={result.id}
                className="rounded-2xl border border-hairline bg-card p-4"
              >
                <p className="text-sm font-medium text-foreground">
                  {index + 1}. {result.question}
                </p>
                <ul className="mt-3 space-y-1.5">
                  {result.choices.map((choice, choiceIndex) => {
                    const isCorrect = choiceIndex === result.correctIndex;
                    const isSelected = choiceIndex === result.selected;

                    return (
                      <li
                        key={choice}
                        className={cn(
                          "flex items-start gap-2 rounded-lg border px-3 py-2 text-sm",
                          isCorrect
                            ? "border-emerald-500/40 bg-emerald-500/10 text-emerald-700 dark:text-emerald-400"
                            : isSelected
                              ? "border-destructive/40 bg-destructive/10 text-destructive"
                              : "border-hairline text-muted-foreground",
                        )}
                      >
                        {isCorrect ? (
                          <CheckCircle2Icon
                            className="mt-0.5 size-4 shrink-0"
                            aria-hidden
                          />
                        ) : isSelected ? (
                          <XCircleIcon
                            className="mt-0.5 size-4 shrink-0"
                            aria-hidden
                          />
                        ) : (
                          <span className="mt-0.5 size-4 shrink-0" />
                        )}
                        <span>{choice}</span>
                        {isCorrect ? (
                          <span className="ml-auto text-xs font-medium">
                            {t.answerMissed}
                          </span>
                        ) : null}
                        {isSelected && !isCorrect ? (
                          <span className="ml-auto text-xs font-medium">
                            {t.answerWrong}
                          </span>
                        ) : null}
                      </li>
                    );
                  })}
                </ul>
                <p className="mt-2 text-xs leading-relaxed text-muted-foreground">
                  <span className="font-medium text-foreground">
                    {t.explanation} :
                  </span>{" "}
                  {result.explanation}
                </p>
              </li>
            ))}
          </ol>
        </div>
      </div>
    );
  }

  return (
    <QuestionCarousel
      questions={questions.map((question) => ({
        id: question.id,
        question: question.question,
        choices: question.choices.map((label, choiceIndex) => ({
          label,
          value: String(choiceIndex),
        })),
      }))}
      answers={answers}
      onSelect={(questionId, value) =>
        setAnswers((previous) => ({ ...previous, [questionId]: value }))
      }
      action={action}
      submitLabel={t.quizSubmit}
      submitting={pending}
      fields={
        <>
          <input type="hidden" name="chapterId" value={chapterId} />
          <input type="hidden" name="trackSlug" value={trackSlug} />
          <input type="hidden" name="assessmentToken" value={assessmentToken} />
          {suspiciousActivity > 0 ? (
            <Notice tone="info">
              Attention : la fenêtre a été mise en arrière-plan pendant le quiz.
              Une tentative de triche ou de navigation hors du test peut être
              refusée.
            </Notice>
          ) : null}
          <p className="text-sm leading-relaxed text-muted-foreground">
            {t.quizIntro(passingScore, questions.length)}
          </p>
          {state?.status === "error" && state.message ? (
            <Notice tone="error">{state.message}</Notice>
          ) : null}
        </>
      }
      footer={
        attempts > 0 ? (
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1 border-t border-hairline pt-3 text-xs text-muted-foreground">
            <span>{t.quizAttempts(attempts)}</span>
            {bestScore !== null ? <span>{t.quizBest(bestScore)}</span> : null}
            <span>
              {t.attemptsLeft(Math.max(0, MAX_ATTEMPTS - attempts), MAX_ATTEMPTS)}
            </span>
          </div>
        ) : null
      }
    />
  );
}
