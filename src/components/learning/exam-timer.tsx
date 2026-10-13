"use client";

import { ClockIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";

import { messages } from "@/i18n";
import { cn } from "cn";

const t = messages.learner;

/**
 * La soumission est déclenchée un peu avant l'expiration réelle du jeton :
 * une validation envoyée à la seconde limite serait refusée par le serveur.
 */
const SUBMIT_BUFFER_MS = 20_000;
const WARN_MS = 5 * 60 * 1000;
const URGENT_MS = 60 * 1000;

function clock(ms: number) {
  const total = Math.ceil(ms / 1000);
  const minutes = Math.floor(total / 60);
  const seconds = total % 60;
  return `${minutes}:${String(seconds).padStart(2, "0")}`;
}

export function ExamTimer({
  expiresAt,
  durationMs,
  onExpire,
}: {
  expiresAt: number;
  durationMs: number;
  onExpire: () => void;
}) {
  const deadline = expiresAt - SUBMIT_BUFFER_MS;
  const [left, setLeft] = useState(durationMs - SUBMIT_BUFFER_MS);
  const expireRef = useRef(onExpire);

  useEffect(() => {
    expireRef.current = onExpire;
  });

  useEffect(() => {
    let fired = false;

    const tick = () => {
      const value = Math.max(0, deadline - Date.now());
      setLeft(value);
      if (value === 0 && !fired) {
        fired = true;
        expireRef.current();
      }
    };

    tick();
    const id = window.setInterval(tick, 1000);
    return () => window.clearInterval(id);
  }, [deadline]);

  const urgent = left <= URGENT_MS;
  const low = !urgent && left <= WARN_MS;

  return (
    <div
      className={cn(
        "flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-semibold tabular-nums",
        urgent
          ? "animate-pulse border-destructive/50 bg-destructive/10 text-destructive"
          : low
            ? "border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400"
            : "border-hairline text-muted-foreground",
      )}
      role="timer"
      aria-live={urgent ? "assertive" : "off"}
    >
      <ClockIcon className="size-3.5" aria-hidden />
      <span className="sr-only">{t.examTimeLeft} : </span>
      <span>{clock(left)}</span>
    </div>
  );
}
