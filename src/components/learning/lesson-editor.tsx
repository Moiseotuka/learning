"use client";

import { RotateCcwIcon } from "lucide-react";
import dynamic from "next/dynamic";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { cn } from "cn";

const t = messages.learner.lessonEditor;

const fallback = (
  <div
    className="h-72 animate-pulse rounded-xl border border-hairline bg-muted/30"
    aria-hidden
  />
);

const ExecutableEditor = dynamic(
  () => import("@/components/practice/executable-editor"),
  {
    ssr: false,
    loading: () => fallback,
  },
);
const HtmlPlayground = dynamic(
  () => import("@/components/practice/html-playground"),
  { ssr: false, loading: () => fallback },
);

export function LessonEditor({
  language,
  code,
  className,
}: {
  language: string;
  code: string;
  className?: string;
}) {
  const [value, setValue] = useState(code);
  const isHtml = language === "html";

  return (
    <div className={cn("mt-6", className)}>
      <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
        <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
          {t.label}
        </p>
        {isHtml || value === code ? null : (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className="gap-1 text-xs text-muted-foreground"
            onClick={() => setValue(code)}
          >
            <RotateCcwIcon aria-hidden />
            {t.reset}
          </Button>
        )}
      </div>

      {isHtml ? (
        <HtmlPlayground initialCode={code} />
      ) : (
        <ExecutableEditor
          language={language}
          value={value}
          onChange={setValue}
          minHeight="18rem"
        />
      )}

      <p className="mt-2 text-xs leading-5 text-muted-foreground">{t.hint}</p>
    </div>
  );
}
