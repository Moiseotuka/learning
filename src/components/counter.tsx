"use client";

import { useEffect, useRef, useState } from "react";

type CounterProps = {
  value: number;
  suffix?: string;
  durationMs?: number;
  decimals?: number;
};

/** Compteur animé déclenché à l'entrée dans le viewport. */
export function Counter({ value, suffix = "", durationMs = 1600, decimals = 0 }: CounterProps) {
  const ref = useRef<HTMLSpanElement>(null);
  const [display, setDisplay] = useState(0);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    if (reduceMotion || typeof IntersectionObserver === "undefined") {
      // Rendu final sans animation : différé pour ne pas setState dans l'effet.
      const fallback = window.setTimeout(() => setDisplay(value), 0);
      return () => window.clearTimeout(fallback);
    }

    let frame = 0;
    const observer = new IntersectionObserver(
      (entries) => {
        if (!entries.some((entry) => entry.isIntersecting)) return;
        observer.disconnect();

        const start = performance.now();
        const tick = (now: number) => {
          const progress = Math.min((now - start) / durationMs, 1);
          const eased = 1 - Math.pow(1 - progress, 3);
          setDisplay(Number((value * eased).toFixed(decimals)));
          if (progress < 1) frame = requestAnimationFrame(tick);
        };
        frame = requestAnimationFrame(tick);
      },
      { threshold: 0.4 },
    );

    observer.observe(node);
    return () => {
      observer.disconnect();
      cancelAnimationFrame(frame);
    };
  }, [value, durationMs, decimals]);

  return (
    <span ref={ref} className="tabular-nums">
      {display.toLocaleString("fr-FR")}
      {suffix}
    </span>
  );
}
