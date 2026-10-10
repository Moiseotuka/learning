"use client";

import { RotateCwIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";

import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import CodeEditor from "@/components/practice/code-editor";

const t = messages.learner.practice;

const PREVIEW_DELAY = 700;

export default function HtmlPlayground({ initialCode }: { initialCode: string }) {
  const [code, setCode] = useState(initialCode);
  const [preview, setPreview] = useState(initialCode);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setPreview(code), PREVIEW_DELAY);
    return () => {
      if (timer.current) clearTimeout(timer.current);
    };
  }, [code]);

  return (
    <div className="space-y-3">
      <div className="grid gap-3 lg:grid-cols-2">
        <div className="min-w-0">
          <p className="mb-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
            {t.editorLabel}
          </p>
          <CodeEditor
            language="html"
            value={code}
            onChange={setCode}
            minHeight="16rem"
          />
        </div>

        <div className="min-w-0">
          <div className="mb-1.5 flex items-center justify-between gap-2">
            <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
              {t.preview}
            </p>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => setPreview(code)}
            >
              <RotateCwIcon aria-hidden />
              {t.previewRefresh}
            </Button>
          </div>
          <iframe
            title={t.previewTitle}
            srcDoc={preview}
            sandbox="allow-scripts"
            className="h-64 w-full rounded-xl border border-hairline bg-white lg:h-[calc(16rem-1.5rem)]"
          />
        </div>
      </div>

      <p className="text-xs leading-5 text-muted-foreground">{t.previewHint}</p>
    </div>
  );
}
