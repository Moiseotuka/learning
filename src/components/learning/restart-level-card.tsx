"use client";

import { RotateCcwIcon } from "lucide-react";
import Link from "next/link";
import { useActionState } from "react";

import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { restartLevel } from "@/lib/actions/progress";
import type { QuizState } from "@/lib/learning/types";

const t = messages.learner;

/**
 * Cartes affichées quand les trois tentatives sont consommées : la seule
 * issue est de reprendre le niveau, dont la progression est effacée.
 */
export function RestartLevelCard({
  trackSlug,
  level,
  levelLabel,
  message,
  trackHref,
}: {
  trackSlug: string;
  level: string;
  levelLabel: string;
  message: string;
  trackHref: string;
}) {
  const [state, action, pending] = useActionState(
    restartLevel,
    undefined as QuizState | undefined,
  );

  return (
    <div className="rounded-2xl border border-destructive/40 bg-destructive/5 p-6 text-center">
      <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-muted text-muted-foreground">
        <RotateCcwIcon className="size-6" aria-hidden />
      </span>

      <h2 className="mt-4 text-base font-semibold text-foreground">
        {t.attemptsExhaustedTitle}
      </h2>
      <p className="mx-auto mt-2 max-w-[52ch] text-sm leading-relaxed text-muted-foreground">
        {message}
      </p>
      <p className="mx-auto mt-2 max-w-[52ch] text-xs leading-relaxed text-muted-foreground">
        {t.restartLevelWarning(levelLabel)}
      </p>

      {state?.status === "error" && state.message ? (
        <div className="mt-4 text-left">
          <Notice tone="error">{state.message}</Notice>
        </div>
      ) : null}

      <form action={action} className="mt-5 flex flex-wrap justify-center gap-3">
        <input type="hidden" name="trackSlug" value={trackSlug} />
        <input type="hidden" name="level" value={level} />
        <Button type="submit" disabled={pending} className="h-10 px-4">
          <RotateCcwIcon aria-hidden />
          {t.restartLevelCta}
        </Button>
        <Button asChild variant="outline" className="h-10 px-4">
          <Link href={trackHref}>{t.backToTrack}</Link>
        </Button>
      </form>
    </div>
  );
}
