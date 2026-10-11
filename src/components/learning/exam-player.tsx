"use client";

import {
  AwardIcon,
  CheckCircle2Icon,
  Loader2Icon,
  RotateCcwIcon,
  XCircleIcon,
} from "lucide-react";
import Link from "next/link";
import { useActionState, useEffect, useState } from "react";

import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { submitLevelExam } from "@/lib/actions/exam";
import type { QuizQuestion, QuizState } from "@/lib/learning/types";
import { cn } from "cn";

const t = messages.learner;

function shuffle<T>(items: T[]): T[] {
  const pool = [...items];
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool;
}

/**
 * Mélange des choix affichés pour chaque question, sans toucher à la
 * sélection serveur des questions validées dans l’examen.
 */
type DrawnQuestion = QuizQuestion & { choiceOrder: number[] };

type ExamPlayerProps = {
  trackSlug: string;
  level: string;
  questions: QuizQuestion[];
  passingScore: number;
  attempts?: number;
  bestScore?: number | null;
  passed?: boolean;
  assessmentToken: string;
};

export function ExamPlayer(props: ExamPlayerProps) {
  const [attemptKey, setAttemptKey] = useState(0);

  return (
    <ExamAttempt
      key={attemptKey}
      {...props}
      onRetry={() => setAttemptKey((value) => value + 1)}
    />
  );
}

function ExamAttempt({
  trackSlug,
  level,
  questions,
  passingScore,
  attempts = 0,
  bestScore = null,
  passed = false,
  assessmentToken,
  onRetry,
}: ExamPlayerProps & { onRetry: () => void }) {
  const [state, action, pending] = useActionState(
    submitLevelExam,
    undefined as QuizState | undefined,
  );
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

  const drawn: DrawnQuestion[] = questions.map((question) => ({
    ...question,
    choiceOrder: shuffle(question.choices.map((_, index) => index)),
  }));

  const results = state?.results;
  const trackHref = `/app/parcours/${trackSlug}`;

  if (state?.status === "success" && results) {
    const succeeded = Boolean(state.passed);

    return (
      <div className="space-y-6">
        <div
          className={cn(
            "rounded-2xl border p-5",
            succeeded
              ? "border-emerald-500/40 bg-emerald-500/10"
              : "border-destructive/40 bg-destructive/10",
          )}
        >
          <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
            {t.examScore}
          </p>
          <p
            className={cn(
              "mt-1 text-4xl font-semibold",
              succeeded
                ? "text-emerald-600 dark:text-emerald-400"
                : "text-destructive",
            )}
          >
            {state.score} %
          </p>
          <p className="mt-2 text-sm text-foreground">
            {succeeded
              ? t.examPassed(state.score ?? 0)
              : t.examFailed(state.score ?? 0, passingScore)}
          </p>
          <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
            <span>{t.quizAttempts(state.attempts ?? attempts)}</span>
            <span>{t.quizBest(state.bestScore ?? bestScore ?? 0)}</span>
            <span>{t.unlockNotice(passingScore)}</span>
          </div>

          <div className="mt-4 flex flex-wrap gap-3">
            {succeeded ? (
              <Button asChild className="h-10 px-4">
                <Link href="/app/profil">
                  <AwardIcon aria-hidden />
                  {t.examCertificateNotice}
                </Link>
              </Button>
            ) : null}
            <Button asChild variant="outline" className="h-10 px-4">
              <Link href={trackHref}>{t.backToTrack}</Link>
            </Button>
            <Button
              variant="ghost"
              className="h-10 px-4"
              onClick={onRetry}
              disabled={pending}
            >
              <RotateCcwIcon aria-hidden />
              {t.examRetake}
            </Button>
          </div>
          {succeeded ? (
            <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
              {t.examRetakeHint}
            </p>
          ) : null}
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
    <form
      action={action}
      className="space-y-6"
      onContextMenu={(event) => event.preventDefault()}
    >
      <input type="hidden" name="trackSlug" value={trackSlug} />
      <input type="hidden" name="level" value={level} />
      <input type="hidden" name="assessmentToken" value={assessmentToken} />
      <input
        type="hidden"
        name="questionIds"
        value={questions.map((question) => question.id).join(",")}
      />

      {suspiciousActivity > 0 ? (
        <Notice tone="info">
          Attention : le navigateur a été détourné hors du test pendant l’examen.
          Les tentatives de triche ou de consultation externe peuvent invalider la
          soumission.
        </Notice>
      ) : null}

      <p className="text-sm leading-relaxed text-muted-foreground">
        {t.examIntro(passingScore, drawn.length)}
      </p>

      {passed ? (
        <Notice tone="success">{t.examCertificateNotice}</Notice>
      ) : null}

      {state?.status === "error" && state.message ? (
        <Notice tone="error">{state.message}</Notice>
      ) : null}

      <ol className="space-y-5">
        {drawn.map((question, index) => (
          <li
            key={question.id}
            className="rounded-2xl border border-hairline bg-card p-4 sm:p-5"
          >
            <fieldset>
              <legend className="text-sm font-semibold text-foreground">
                <span className="mr-2 text-xs font-medium text-electric">
                  {index + 1} / {drawn.length}
                </span>
                {question.question}
              </legend>
              <div className="mt-3 space-y-2">
                {question.choiceOrder.map((originalIndex) => {
                  const choice = question.choices[originalIndex];
                  const value = String(originalIndex);
                  const checked = answers[question.id] === value;
                  const inputId = `exam-${question.id}-${originalIndex}`;

                  return (
                    <label
                      key={originalIndex}
                      htmlFor={inputId}
                      className={cn(
                        "flex cursor-pointer items-start gap-3 rounded-lg border px-3 py-2 text-sm text-foreground transition-colors hover:border-electric/50",
                        checked && "border-electric/60 bg-electric/[0.06]",
                      )}
                    >
                      <input
                        id={inputId}
                        type="radio"
                        name={question.id}
                        value={value}
                        checked={checked}
                        onChange={() =>
                          setAnswers((previous) => ({
                            ...previous,
                            [question.id]: value,
                          }))
                        }
                        className="mt-0.5 size-4 accent-electric"
                      />
                      <span>{choice}</span>
                    </label>
                  );
                })}
              </div>
            </fieldset>
          </li>
        ))}
      </ol>

      <div className="flex flex-wrap items-center gap-3 border-t border-hairline pt-4">
        <Button type="submit" disabled={pending} className="h-10 px-5">
          {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
          {t.examSubmit}
        </Button>
        <Button asChild variant="ghost" className="h-10 px-4">
          <Link href={trackHref}>{t.backToTrack}</Link>
        </Button>
        {attempts > 0 ? (
          <span className="text-xs text-muted-foreground">
            {t.quizAttempts(attempts)}
            {bestScore !== null ? ` · ${t.quizBest(bestScore)}` : ""}
          </span>
        ) : null}
      </div>
    </form>
  );
}
