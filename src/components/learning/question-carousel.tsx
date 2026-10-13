"use client";

import {
  ChevronLeftIcon,
  ChevronRightIcon,
  Loader2Icon,
  SendIcon,
} from "lucide-react";
import {
  type ReactNode,
  type RefObject,
  useEffect,
  useRef,
  useState,
} from "react";

import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { cn } from "cn";

const t = messages.learner;

export type CarouselChoice = { label: string; value: string };
export type CarouselQuestion = {
  id: string;
  question: string;
  choices: CarouselChoice[];
};

type QuestionCarouselProps = {
  questions: CarouselQuestion[];
  answers: Record<string, string>;
  onSelect: (questionId: string, value: string) => void;
  action: (formData: FormData) => void | Promise<void>;
  submitLabel: string;
  submitting: boolean;
  formRef?: RefObject<HTMLFormElement | null>;
  /** Champs cachés (jeton, identifiants) et avis placés dans le formulaire. */
  fields?: ReactNode;
  header?: ReactNode;
  footer?: ReactNode;
  /** Emplacement de la minuterie, à droite de l'en-tête. */
  aside?: ReactNode;
};

export function QuestionCarousel({
  questions,
  answers,
  onSelect,
  action,
  submitLabel,
  submitting,
  formRef,
  fields,
  header,
  footer,
  aside,
}: QuestionCarouselProps) {
  const [step, setStep] = useState(0);
  const headingRef = useRef<HTMLParagraphElement>(null);
  const current = questions[step];
  const isLast = step === questions.length - 1;
  const answeredCount = questions.filter(
    (question) => (answers[question.id] ?? "") !== "",
  ).length;
  const remaining = questions.length - answeredCount;
  const currentAnswered = current
    ? (answers[current.id] ?? "") !== ""
    : false;

  useEffect(() => {
    headingRef.current?.focus({ preventScroll: true });
  }, [step]);

  const onFormAction = (formData: FormData) => {
    if (remaining > 0) {
      const firstMissing = questions.findIndex(
        (question) => (answers[question.id] ?? "") === "",
      );
      if (firstMissing >= 0) setStep(firstMissing);
      return;
    }
    void action(formData);
  };

  if (!current) return null;

  return (
    <form
      ref={formRef}
      action={onFormAction}
      className="space-y-4"
      onContextMenu={(event) => event.preventDefault()}
    >
      {fields}

      <div className="flex items-center justify-between gap-3">
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
          {t.questionOf(step + 1, questions.length)}
        </p>
        {aside}
      </div>

      <div
        className="h-1.5 w-full overflow-hidden rounded-full bg-muted"
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={questions.length}
        aria-valuenow={answeredCount}
        aria-label={t.answersFilled(answeredCount, questions.length)}
      >
        <div
          className="h-full rounded-full bg-electric transition-[width] duration-300"
          style={{ width: `${(answeredCount / questions.length) * 100}%` }}
        />
      </div>

      {header}

      {/* Toutes les questions restent montées : la soumission doit continuer
          de transporter chaque réponse, y compris celles des questions déjà
          passées. Seule l'affichage avance. */}
      <ol className="space-y-4">
        {questions.map((question, index) => (
          <li key={question.id} className={cn(index !== step && "hidden")}>
            <fieldset className="rounded-2xl border border-hairline bg-card p-4 sm:p-5">
              <legend className="sr-only">
                {t.questionOf(index + 1, questions.length)}
              </legend>
              <p
                ref={index === step ? headingRef : null}
                tabIndex={-1}
                className="text-base font-semibold leading-relaxed text-foreground outline-none sm:text-lg"
              >
                {question.question}
              </p>
              <div className="mt-4 space-y-2">
                {question.choices.map((choice) => {
                  const checked = answers[question.id] === choice.value;
                  const inputId = `${question.id}-${choice.value}`;

                  return (
                    <label
                      key={choice.value}
                      htmlFor={inputId}
                      className={cn(
                        "flex cursor-pointer items-start gap-3 rounded-xl border px-3.5 py-3 text-sm leading-relaxed text-foreground transition-colors hover:border-electric/50",
                        checked &&
                          "border-electric/70 bg-electric/[0.07] font-medium",
                      )}
                    >
                      <input
                        id={inputId}
                        type="radio"
                        name={question.id}
                        value={choice.value}
                        checked={checked}
                        onChange={() => onSelect(question.id, choice.value)}
                        className="mt-0.5 size-4 shrink-0 accent-electric"
                      />
                      <span>{choice.label}</span>
                    </label>
                  );
                })}
              </div>
            </fieldset>
          </li>
        ))}
      </ol>

      <div className="flex items-center gap-2 border-t border-hairline pt-4">
        <Button
          type="button"
          variant="outline"
          className="h-10 gap-1 px-3.5"
          disabled={step === 0}
          onClick={() => setStep((value) => Math.max(0, value - 1))}
        >
          <ChevronLeftIcon aria-hidden />
          <span className="hidden sm:inline">{t.previousQuestion}</span>
        </Button>

        <ol className="mx-auto flex flex-wrap items-center justify-center gap-1.5">
          {questions.map((question, index) => {
            const answered = (answers[question.id] ?? "") !== "";

            return (
              <li key={question.id}>
                <button
                  type="button"
                  onClick={() => setStep(index)}
                  aria-current={index === step ? "step" : undefined}
                  aria-label={t.questionOf(index + 1, questions.length)}
                  className={cn(
                    "size-6 rounded-full border text-[10px] font-semibold tabular-nums transition-colors",
                    index === step
                      ? "border-electric bg-electric text-white"
                      : answered
                        ? "border-electric/40 bg-electric/10 text-electric"
                        : "border-hairline text-muted-foreground hover:border-electric/50",
                  )}
                >
                  {index + 1}
                </button>
              </li>
            );
          })}
        </ol>

        {isLast ? (
          <Button
            type="submit"
            className="h-10 gap-1.5 px-4"
            disabled={submitting}
          >
            {submitting ? (
              <Loader2Icon className="animate-spin" aria-hidden />
            ) : (
              <SendIcon aria-hidden />
            )}
            {submitLabel}
          </Button>
        ) : (
          <Button
            type="button"
            className="h-10 gap-1 px-4"
            disabled={!currentAnswered}
            onClick={() =>
              setStep((value) => Math.min(questions.length - 1, value + 1))
            }
          >
            <span className="hidden sm:inline">{t.nextQuestion}</span>
            <ChevronRightIcon aria-hidden />
          </Button>
        )}
      </div>

      <p className="text-right text-xs text-muted-foreground">
        {!currentAnswered && !isLast
          ? t.chooseAnswerToContinue
          : remaining > 0
            ? t.questionsRemaining(remaining)
            : t.allAnswered}
      </p>

      {footer}
    </form>
  );
}
