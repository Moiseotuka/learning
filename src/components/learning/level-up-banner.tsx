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
        "fixed inset-x-4 bottom-4 z-[60] mx-auto w-full max-w-md transition-all duration-500 ease-out sm:inset-x-auto sm:bottom-6 sm:right-6 sm:mx-0 sm:w-96",
        visible
          ? "translate-y-0 opacity-100"
          : "pointer-events-none translate-y-6 opacity-0",
      )}
    >
      <div className="relative overflow-hidden rounded-2xl border border-electric/30 bg-card p-4 shadow-2xl shadow-electric/20">
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-electric via-vivid to-electric" />
        <div className="flex items-start gap-3">
          <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-electric text-primary-foreground">
            <TrendingUpIcon className="size-5" aria-hidden />
          </span>
          <div className="min-w-0 flex-1">
            <p className="text-[10px] font-semibold uppercase tracking-wider text-electric">
              {lu.eyebrow}
            </p>
            <h2 className="mt-0.5 text-sm font-semibold text-foreground">
              {title}
            </h2>
            <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
              {lu.text}
            </p>
            <Button asChild size="sm" className="mt-3 h-8 px-3 text-xs">
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