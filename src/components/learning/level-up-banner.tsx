"use client";

import Link from "next/link";
import { ArrowRightIcon, TrendingUpIcon, XIcon } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";

import { Button } from "@/components/ui/button";
import { levels, type LevelType } from "@/config/catalog";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const lu = messages.levelUp;
const levelLabels = messages.common.levels;
const closeLabel = messages.common.close;

type LevelUpNotificationProps = {
  currentLevel?: LevelType;
  ctaHref?: string;
  ctaLabel?: string;
  showDelayMs?: number;
  visibleMs?: number;
  repeatMs?: number;
  snoozeMs?: number;
};

export function LevelUpNotification({
  currentLevel,
  ctaHref,
  ctaLabel,
  showDelayMs = 2500,
  visibleMs = 9000,
  repeatMs = 35000,
  snoozeMs = 45000,
}: LevelUpNotificationProps) {
  const [visible, setVisible] = useState(false);
  const [snoozed, setSnoozed] = useState(false);
  const timers = useRef<number[]>([]);

  const idx = currentLevel ? levels.indexOf(currentLevel) : -1;
  const nextLevel =
    idx >= 0 && idx < levels.length - 1 ? levels[idx + 1] : null;

  const title =
    currentLevel && nextLevel
      ? lu.title(levelLabels[currentLevel], levelLabels[nextLevel])
      : currentLevel === "projet"
        ? lu.finalTitle
        : lu.genericTitle;

  const defaultCta = currentLevel === "projet" ? lu.finalCta : lu.cta;

  const clearTimers = useCallback(() => {
    timers.current.forEach((id) => window.clearTimeout(id));
    timers.current = [];
  }, []);

  const schedule = useCallback(() => {
    const show = () => {
      setVisible(true);
      timers.current.push(
        window.setTimeout(() => {
          setVisible(false);
          timers.current.push(window.setTimeout(show, repeatMs));
        }, visibleMs),
      );
    };
    timers.current.push(window.setTimeout(show, showDelayMs));
  }, [showDelayMs, visibleMs, repeatMs]);

  useEffect(() => {
    schedule();
    return clearTimers;
  }, [schedule, clearTimers]);

  const dismiss = useCallback(() => {
    clearTimers();
    setVisible(false);
    setSnoozed(true);
    const id = window.setTimeout(() => {
      setSnoozed(false);
      schedule();
    }, snoozeMs);
    timers.current.push(id);
  }, [clearTimers, schedule, snoozeMs]);

  if (snoozed) return null;

  return (
    <div
      role="status"
      aria-live="polite"
      className={cn(
        // Sur téléphone le bandeau se pose au-dessus de la barre d'onglets et
        // reste sur deux lignes : il ne doit jamais couvrir la leçon en cours.
        "fixed inset-x-3 bottom-[calc(3.75rem+env(safe-area-inset-bottom))] z-[60] mx-auto w-full max-w-md transition-all duration-500 ease-out sm:inset-x-4 sm:bottom-6 lg:inset-x-auto lg:right-6 lg:mx-0 lg:w-96",
        visible
          ? "translate-y-0 opacity-100"
          : "pointer-events-none translate-y-6 opacity-0",
      )}
    >
      <div className="relative overflow-hidden rounded-2xl border border-electric/30 bg-card p-3 shadow-2xl shadow-electric/20 sm:p-4">
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-electric via-vivid to-electric" />
        <div className="flex items-start gap-3">
          <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-electric text-primary-foreground sm:size-10">
            <TrendingUpIcon className="size-4 sm:size-5" aria-hidden />
          </span>
          <div className="min-w-0 flex-1">
            <p className="hidden text-[10px] font-semibold uppercase tracking-wider text-electric sm:block">
              {lu.eyebrow}
            </p>
            <h2 className="mt-0.5 text-sm font-semibold text-foreground">
              {title}
            </h2>
            <p className="mt-1 hidden text-xs leading-relaxed text-muted-foreground sm:block">
              {lu.text}
            </p>
            <Button asChild size="sm" className="mt-2 h-8 px-3 text-xs sm:mt-3">
              <Link href={ctaHref ?? links.catalogue}>
                {ctaLabel ?? defaultCta}
                <ArrowRightIcon className="size-3.5" aria-hidden />
              </Link>
            </Button>
          </div>
          <button
            type="button"
            onClick={dismiss}
            aria-label={closeLabel}
            className="grid size-7 shrink-0 place-items-center rounded-full text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
          >
            <XIcon className="size-4" aria-hidden />
          </button>
        </div>
      </div>
    </div>
  );
}