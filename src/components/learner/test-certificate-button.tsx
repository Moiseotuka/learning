"use client";

import { FlaskConicalIcon, Loader2Icon } from "lucide-react";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { issueTestCertificate } from "@/lib/actions/certificates";

const t = messages.learner.profil;

export function TestCertificateButton() {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function handleClick() {
    setPending(true);
    setError("");
    try {
      const result = await issueTestCertificate();
      if (!result.ok || !result.code) {
        setError(t.testError);
        return;
      }
      const response = await fetch(
        `/api/certificats/${encodeURIComponent(result.code)}?inline=1`,
      );
      if (!response.ok) {
        setError(t.testError);
        return;
      }
      const blob = await response.blob();
      const objectUrl = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = objectUrl;
      link.download = `${result.code}.pdf`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      setTimeout(() => URL.revokeObjectURL(objectUrl), 10_000);
    } catch {
      setError(t.testError);
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="rounded-2xl border border-dashed border-hairline bg-card/50 p-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="min-w-0">
          <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {t.testTitle}
          </p>
          <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
            {t.testHint}
          </p>
        </div>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={handleClick}
          disabled={pending}
          className="shrink-0 border-hairline bg-background"
        >
          {pending ? (
            <Loader2Icon className="size-4 animate-spin" aria-hidden />
          ) : (
            <FlaskConicalIcon className="size-4" aria-hidden />
          )}
          {t.testButton}
        </Button>
      </div>
      {error ? (
        <p className="mt-2 text-xs text-destructive">{error}</p>
      ) : null}
    </div>
  );
}
