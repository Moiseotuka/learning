"use client";

import { Loader2Icon, PlayIcon, SaveIcon } from "lucide-react";
import { useTransition } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { runNowAction, saveCapAction } from "@/lib/actions/marketing";

const t = messages.admin.marketing;

export function MarketingControls({ cap }: { cap: number }) {
  const [saving, startSave] = useTransition();
  const [running, startRun] = useTransition();

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <form
        action={(formData) => startSave(() => saveCapAction(undefined, formData))}
        className="rounded-2xl border border-hairline bg-card p-5"
      >
        <h3 className="text-sm font-semibold text-foreground">{t.capTitle}</h3>
        <p className="mt-2 text-xs leading-relaxed text-muted-foreground">
          {t.capIntro}
        </p>
        <label
          htmlFor="cap"
          className="mt-4 block text-xs font-medium uppercase tracking-wide text-muted-foreground"
        >
          {t.capLabel}
        </label>
        <div className="mt-2 flex gap-2">
          <Input
            id="cap"
            name="cap"
            type="number"
            min={1}
            max={5000}
            step={1}
            defaultValue={cap}
            className="h-10 w-32"
            required
          />
          <Button type="submit" className="h-10 px-4" disabled={saving}>
            {saving ? (
              <Loader2Icon className="animate-spin" aria-hidden />
            ) : (
              <SaveIcon className="size-4" aria-hidden />
            )}
            {t.capSave}
          </Button>
        </div>
      </form>

      <div className="rounded-2xl border border-hairline bg-card p-5">
        <h3 className="text-sm font-semibold text-foreground">{t.runTitle}</h3>
        <p className="mt-2 text-xs leading-relaxed text-muted-foreground">
          {t.runIntro}
        </p>
        <form
          action={() => startRun(() => runNowAction())}
          className="mt-4"
        >
          <Button type="submit" variant="outline" className="h-10 px-4" disabled={running}>
            {running ? (
              <Loader2Icon className="animate-spin" aria-hidden />
            ) : (
              <PlayIcon className="size-4" aria-hidden />
            )}
            {t.run}
          </Button>
        </form>
      </div>
    </div>
  );
}
