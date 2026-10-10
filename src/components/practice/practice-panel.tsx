"use client";

import {
  CheckIcon,
  EyeIcon,
  EyeOffIcon,
  Loader2Icon,
} from "lucide-react";
import dynamic from "next/dynamic";
import { useState, useTransition } from "react";

import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { setPracticeState } from "@/lib/actions/learning";
import type { PracticeTool } from "@/lib/practice/types";
import { cn } from "cn";

const t = messages.learner.practice;

const ExecutableEditor = dynamic(
  () => import("@/components/practice/executable-editor"),
  {
    ssr: false,
    loading: () => <EditorFallback />,
  },
);
const HtmlPlayground = dynamic(
  () => import("@/components/practice/html-playground"),
  { ssr: false, loading: () => <EditorFallback /> },
);
const LabChecklist = dynamic(
  () => import("@/components/practice/lab-checklist"),
  { ssr: false, loading: () => <EditorFallback /> },
);

function EditorFallback() {
  return (
    <div
      className="h-40 animate-pulse rounded-xl border border-hairline bg-muted/30"
      aria-hidden
    />
  );
}

type PracticePanelProps = {
  tool: PracticeTool;
  chapterId: string;
  language: string;
  starterCode: string;
  solutionCode: string;
  initialDone: boolean;
  initialSolutionViewed: boolean;
};

export function PracticePanel({
  tool,
  chapterId,
  language,
  starterCode,
  solutionCode,
  initialDone,
  initialSolutionViewed,
}: PracticePanelProps) {
  const [done, setDone] = useState(initialDone);
  const [solutionViewed, setSolutionViewed] = useState(initialSolutionViewed);
  const [showSolution, setShowSolution] = useState(false);
  const [saveError, setSaveError] = useState(false);
  const [starterValue, setStarterValue] = useState(starterCode);
  const [pending, startTransition] = useTransition();

  const editorLanguage = language || tool.language;
  const hasSolution = solutionCode.trim().length > 0;

  function persistDone(value: boolean) {
    const previous = done;
    setDone(value);
    setSaveError(false);
    startTransition(async () => {
      const result = await setPracticeState(chapterId, { done: value });
      if (!result.ok) {
        setDone(previous);
        setSaveError(true);
      }
    });
  }

  function revealSolution() {
    setShowSolution(true);
    if (solutionViewed) return;
    setSolutionViewed(true);
    setSaveError(false);
    startTransition(async () => {
      const result = await setPracticeState(chapterId, { solutionViewed: true });
      if (!result.ok) {
        setSolutionViewed(false);
        setSaveError(true);
      }
    });
  }

  return (
    <section
      aria-label={t.label}
      className="mt-4 overflow-hidden rounded-xl border border-hairline bg-muted/20"
    >
      <header className="flex flex-wrap items-center justify-between gap-2 border-b border-hairline px-4 py-3">
        <div className="min-w-0">
          <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
            {t.label}
          </p>
          <p className="truncate text-sm font-medium text-foreground">
            {tool.label}
          </p>
        </div>
        <span
          className={cn(
            "rounded-full px-2 py-0.5 text-[11px] font-medium",
            done
              ? "bg-emerald-500/12 text-emerald-600 dark:text-emerald-400"
              : "bg-electric/12 text-electric",
          )}
        >
          {done ? t.statusDone : t.statusTodo}
        </span>
      </header>

      <div className="space-y-3 p-4">
        <p className="text-xs leading-5 text-muted-foreground">{t.hint}</p>

        {tool.kind === "code_editor" ? (
          <div className="space-y-3">
            <div>
              <p className="mb-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                {t.startCode}
              </p>
              <ExecutableEditor
                language={editorLanguage}
                value={starterValue}
                onChange={setStarterValue}
                minHeight="13rem"
              />
            </div>

            {hasSolution && showSolution ? (
              <div>
                <p className="mb-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                  {t.solutionTitle}
                </p>
                <ExecutableEditor
                  language={editorLanguage}
                  value={solutionCode}
                  readOnly
                  minHeight="11rem"
                />
                <p className="mt-1.5 text-xs leading-5 text-muted-foreground">
                  {t.solutionNote}
                </p>
              </div>
            ) : null}
          </div>
        ) : null}

        {tool.kind === "html_playground" ? (
          <HtmlPlayground initialCode={starterCode} />
        ) : null}

        {tool.kind === "lab_checklist" ? (
          <LabChecklist items={tool.items} />
        ) : null}

        {saveError ? (
          <p className="text-xs leading-5 text-destructive">{t.saveError}</p>
        ) : null}

        <div className="flex flex-wrap items-center gap-2 pt-1">
          {hasSolution ? (
            <Button
              type="button"
              variant="outline"
              size="lg"
              className="border-hairline"
              disabled={pending}
              onClick={() => {
                if (showSolution) {
                  setShowSolution(false);
                } else {
                  revealSolution();
                }
              }}
            >
              {showSolution ? (
                <EyeOffIcon aria-hidden />
              ) : (
                <EyeIcon aria-hidden />
              )}
              {showSolution ? t.solutionHide : t.solutionShow}
            </Button>
          ) : null}

          <Button
            type="button"
            variant={done ? "outline" : "default"}
            size="lg"
            className={done ? "border-hairline" : "px-4"}
            disabled={pending}
            onClick={() => persistDone(!done)}
          >
            {pending ? (
              <Loader2Icon className="animate-spin" aria-hidden />
            ) : done ? (
              <CheckIcon aria-hidden />
            ) : null}
            {done ? t.undone : t.done}
          </Button>
        </div>
      </div>
    </section>
  );
}
