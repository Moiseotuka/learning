"use client";

import {
  AwardIcon,
  CheckCircle2Icon,
  Loader2Icon,
  RotateCcwIcon,
  XCircleIcon,
} from "lucide-react";
import Link from "next/link";
import { useMemo, useActionState, useEffect, useRef, useState } from "react";

import { Notice } from "@/components/auth/notice";
import { ExamTimer } from "@/components/learning/exam-timer";
import { QuestionCarousel } from "@/components/learning/question-carousel";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { submitLevelExam } from "@/lib/actions/exam";
import { MAX_ATTEMPTS } from "@/lib/learning/attempts";
import type { QuizQuestion, QuizState } from "@/lib/learning/types";
import { cn } from "cn";

const t = messages.learner;

/**
 * Mélange reproductible : le serveur et le client doivent produire le même
 * ordre des choix, sinon l'hydratation échoue. La graine vient du jeton
 * d'évaluation, unique par session d'examen.
 */
function seedFrom(token: string) {
  let hash = 2166136261;
  for (let index = 0; index < token.length; index += 1) {
    hash ^= token.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function seededShuffle<T>(items: T[], seed: number): T[] {
  let state = seed >>> 0;
  const next = () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let value = state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };

  const pool = [...items];
  for (let i = pool.length - 1; i > 0; i -= 1) {
    const j = Math.floor(next() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool;
}

type ExamPlayerProps = {
  trackSlug: string;
  level: string;
  questions: QuizQuestion[];
  passingScore: number;
  attempts?: number;
  bestScore?: number | null;
  passed?: boolean;
  assessmentToken: string;
  /** Fin de validité du jeton d'évaluation, en millisecondes depuis l'époque. */
  expiresAt: number;
  durationMs: number;
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
  expiresAt,
  durationMs,
  onRetry,
}: ExamPlayerProps & { onRetry: () => void }) {
  const [state, action, pending] = useActionState(
    submitLevelExam,
    undefined as QuizState | undefined,
  );
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [expired, setExpired] = useState(false);
  const [suspiciousActivity, setSuspiciousActivity] = useState(0);
  const formRef = useRef<HTMLFormElement>(null);

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

  // ordre figé par jeton : le carrousel re-rend à chaque question, et un nouvel
  // ordre à ce moment-là ferait bouger les choix sous la main.
  const drawn = useMemo(() => {
    const seed = seedFrom(assessmentToken);
    return questions.map((question, questionIndex) => ({
      ...question,
      choiceOrder: seededShuffle(
        question.choices.map((_, index) => index),
        seed + questionIndex * 7919,
      ),
    }));
  }, [questions, assessmentToken]);

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
            {!succeeded && (state.attempts ?? attempts) < MAX_ATTEMPTS ? (
              <Button
                variant="ghost"
                className="h-10 px-4"
                onClick={onRetry}
                disabled={pending}
              >
                <RotateCcwIcon aria-hidden />
                {t.examRetake}
              </Button>
            ) : null}
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
                        ) : isSelected && !isCorrect ? (
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
    <>
      {expired ? (
        <Notice tone="info">
          <span className="flex items-center gap-2">
            {pending ? (
              <Loader2Icon className="size-4 animate-spin" aria-hidden />
            ) : null}
            {t.examTimeUp}
          </span>
        </Notice>
      ) : null}

      <QuestionCarousel
        formRef={formRef}
        questions={drawn.map((question) => ({
          id: question.id,
          question: question.question,
          choices: question.choiceOrder.map((originalIndex) => ({
            label: question.choices[originalIndex] ?? "",
            value: String(originalIndex),
          })),
        }))}
        answers={answers}
        onSelect={(questionId, value) =>
          setAnswers((previous) => ({ ...previous, [questionId]: value }))
        }
        action={action}
        submitLabel={t.examSubmit}
        submitting={pending}
        aside={
          <ExamTimer
            expiresAt={expiresAt}
            durationMs={durationMs}
            onExpire={() => {
              setExpired(true);
              formRef.current?.requestSubmit();
            }}
          />
        }
        fields={
          <>
            <input type="hidden" name="trackSlug" value={trackSlug} />
            <input type="hidden" name="level" value={level} />
            <input
              type="hidden"
              name="assessmentToken"
              value={assessmentToken}
            />
            <input
              type="hidden"
              name="questionIds"
              value={questions.map((question) => question.id).join(",")}
            />
            {suspiciousActivity > 0 ? (
              <Notice tone="info">
                Attention : le navigateur a été détourné hors du test pendant
                l’examen. Les tentatives de triche ou de consultation externe
                peuvent invalider la soumission.
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
          </>
        }
        footer={
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1 border-t border-hairline pt-3 text-xs text-muted-foreground">
            <Button asChild variant="ghost" className="h-8 px-2 text-xs">
              <Link href={trackHref}>{t.backToTrack}</Link>
            </Button>
            {attempts > 0 ? (
              <>
                <span>{t.quizAttempts(attempts)}</span>
                {bestScore !== null ? (
                  <span>{t.quizBest(bestScore)}</span>
                ) : null}
              </>
            ) : null}
            <span>
              {t.attemptsLeft(Math.max(0, MAX_ATTEMPTS - attempts), MAX_ATTEMPTS)}
            </span>
          </div>
        }
      />
    </>
  );
}
