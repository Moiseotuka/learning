"use client";

import { CheckIcon } from "lucide-react";
import { useState } from "react";

import { messages } from "@/i18n";
import type { PracticeChecklistItem } from "@/lib/practice/types";
import { cn } from "cn";

const t = messages.learner.practice;

export default function LabChecklist({ items }: { items: PracticeChecklistItem[] }) {
  const [checked, setChecked] = useState<boolean[]>(() =>
    items.map(() => false),
  );

  const doneCount = checked.filter(Boolean).length;

  function toggle(index: number) {
    setChecked((previous) =>
      previous.map((value, position) => (position === index ? !value : value)),
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <p className="text-xs leading-5 text-muted-foreground">
          {t.checklistHint}
        </p>
        <span className="text-xs tabular-nums text-muted-foreground">
          {t.checklistProgress(doneCount, items.length)}
        </span>
      </div>

      <ul className="grid gap-2">
        {items.map((item, index) => (
          <li key={item.label}>
            <button
              type="button"
              aria-pressed={checked[index] ?? false}
              onClick={() => toggle(index)}
              className={cn(
                "flex w-full items-start gap-3 rounded-xl border px-3 py-2.5 text-left transition-colors",
                checked[index]
                  ? "border-emerald-500/40 bg-emerald-500/[0.07]"
                  : "border-hairline bg-background hover:border-electric/50",
              )}
            >
              <span
                aria-hidden
                className={cn(
                  "mt-0.5 grid size-4 shrink-0 place-items-center rounded border",
                  checked[index]
                    ? "border-emerald-500/60 bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                    : "border-input bg-background",
                )}
              >
                {checked[index] ? (
                  <CheckIcon className="size-3" aria-hidden />
                ) : null}
              </span>
              <span className="min-w-0">
                <span className="block text-sm leading-6 text-foreground/90">
                  {item.label}
                </span>
                {item.hint ? (
                  <span className="block text-xs leading-5 text-muted-foreground">
                    {item.hint}
                  </span>
                ) : null}
              </span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
