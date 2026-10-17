"use client";

import { Loader2Icon, PlayIcon, XIcon } from "lucide-react";
import { useState } from "react";

import CodeEditor from "@/components/practice/code-editor";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import {
  executableLanguage,
  runCode,
  type RunOutcome,
} from "@/lib/practice/code-runner";
import { cn } from "cn";

const t = messages.learner.runner;

type ExecutableEditorProps = {
  language: string;
  value: string;
  onChange?: (value: string) => void;
  readOnly?: boolean;
  minHeight?: string;
  className?: string;
};

/**
 * Éditeur de code avec bouton « Exécuter » et console de sortie.
 * Python tourne via Pyodide (WebAssembly) dans un worker ; les autres
 * langages non exécutables affichent l'éditeur simple.
 */
export default function ExecutableEditor({
  language,
  value,
  onChange,
  readOnly = false,
  minHeight,
  className,
}: ExecutableEditorProps) {
  const runnable = executableLanguage(language);
  const [running, setRunning] = useState(false);
  const [outcome, setOutcome] = useState<RunOutcome | null>(null);
  const [firstRun, setFirstRun] = useState(true);

  if (!runnable) {
    return (
      <CodeEditor
        language={language}
        value={value}
        onChange={onChange}
        readOnly={readOnly}
        minHeight={minHeight}
      />
    );
  }

  async function handleRun() {
    if (running) return;
    setRunning(true);
    const isFirst = firstRun;
    const result = await runCode(
      language,
      value,
      isFirst ? 30000 : 15000,
    );
    if (isFirst) setFirstRun(false);
    setOutcome(result);
    setRunning(false);
  }

  const errorText = outcome?.timeout
    ? t.timeout
    : outcome?.error
      ? `${t.failed} ${outcome.error}`
      : null;
  const hasVisibleOutput =
    outcome !== null &&
    (outcome.stdout.length > 0 ||
      outcome.stderr.length > 0 ||
      errorText !== null);

  return (
    <div className={cn("space-y-2", className)}>
      <div className="flex items-center justify-end gap-2">
        {running && firstRun ? (
          <span className="text-xs text-muted-foreground">{t.loading}</span>
        ) : null}
        <Button
          type="button"
          size="sm"
          className="h-8 gap-1.5 px-3"
          disabled={running}
          onClick={handleRun}
        >
          {running ? (
            <Loader2Icon className="animate-spin" aria-hidden />
          ) : (
            <PlayIcon aria-hidden />
          )}
          {running ? t.running : t.run}
        </Button>
      </div>

      <CodeEditor
        language={language}
        value={value}
        onChange={onChange}
        readOnly={readOnly}
        minHeight={minHeight}
      />

      {outcome ? (
        <div className="overflow-hidden rounded-xl border border-hairline bg-muted/40">
          <div className="flex items-center justify-between border-b border-hairline px-3 py-1.5">
            <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
              {t.output}
            </p>
            <button
              type="button"
              onClick={() => setOutcome(null)}
              className="grid size-6 place-items-center rounded text-muted-foreground transition-colors hover:text-foreground"
              aria-label={t.clear}
            >
              <XIcon className="size-3.5" aria-hidden />
            </button>
          </div>
          <pre className="max-h-56 overflow-auto whitespace-pre-wrap break-words p-3 font-mono text-[13px] leading-5">
            {hasVisibleOutput ? (
              <>
                {outcome.stdout ? (
                  <span className="text-foreground/85">{outcome.stdout}</span>
                ) : null}
                {outcome.stderr ? (
                  <span className="text-emerald-600 dark:text-emerald-400">
                    {outcome.stderr}
                  </span>
                ) : null}
                {errorText ? (
                  <span className="text-destructive">{errorText}</span>
                ) : null}
              </>
            ) : (
              <span className="text-muted-foreground">{t.empty}</span>
            )}
          </pre>
        </div>
      ) : null}
    </div>
  );
}
