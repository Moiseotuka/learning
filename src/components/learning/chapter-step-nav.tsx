import Link from "next/link";
import {
  CheckIcon,
  LockIcon,
} from "lucide-react";

import { messages } from "@/i18n";
import { cn } from "cn";

const t = messages.learner;

export type ChapterStep = {
  key: string;
  label: string;
  href: string;
  done: boolean;
  locked: boolean;
  current: boolean;
};

/**
 * Fil d'étapes du chapitre, affiché dans la zone de lecture : l'apprenant voit
 * d'où il part, où il est et ce qui reste. Indispensable sur téléphone, où le
 * sommaire du parcours est replié derrière un bouton.
 */
export function ChapterStepNav({
  steps,
  percent,
}: {
  steps: ChapterStep[];
  percent: number;
}) {
  const position = Math.max(
    steps.findIndex((step) => step.current) + 1,
    1,
  );

  return (
    <nav aria-label={t.stepsLabel} className="mt-4">
      <ol className="flex snap-x gap-1.5 overflow-x-auto pb-1">
        {steps.map((step, index) => (
          <li key={step.key} className="shrink-0 snap-start">
            <Link
              href={step.href}
              aria-current={step.current ? "step" : undefined}
              aria-disabled={step.locked || undefined}
              className={cn(
                "flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs transition-colors",
                step.current
                  ? "border-electric bg-electric text-primary-foreground"
                  : step.locked
                    ? "border-hairline bg-card/60 text-muted-foreground"
                    : step.done
                      ? "border-emerald-500/40 bg-emerald-500/10 text-emerald-700 hover:bg-emerald-500/15 dark:text-emerald-400"
                      : "border-hairline bg-card text-foreground/80 hover:border-electric/50",
              )}
            >
              <span
                className={cn(
                  "grid size-4 shrink-0 place-items-center rounded-full text-[10px] font-semibold tabular-nums",
                  step.current
                    ? "bg-primary-foreground/20"
                    : step.done
                      ? "bg-emerald-500/20"
                      : "bg-muted text-muted-foreground",
                )}
                aria-hidden
              >
                {step.done && !step.current ? (
                  <CheckIcon className="size-2.5" />
                ) : step.locked && !step.current ? (
                  <LockIcon className="size-2.5" />
                ) : (
                  index + 1
                )}
              </span>
              <span className="whitespace-nowrap font-medium">{step.label}</span>
            </Link>
          </li>
        ))}
      </ol>
      <div className="mt-2 flex items-center gap-3">
        <span className="h-1 flex-1 overflow-hidden rounded-full bg-muted">
          <span
            className="block h-full rounded-full bg-electric"
            style={{ width: `${Math.min(Math.max(percent, 0), 100)}%` }}
          />
        </span>
        <span className="shrink-0 text-[11px] tabular-nums text-muted-foreground">
          {t.stepOf(position, steps.length)}
        </span>
      </div>
    </nav>
  );
}
