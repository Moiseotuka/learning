import type { ReactNode } from "react";

import { cn } from "cn";

const tones = {
  info: "border-electric/30 bg-electric/10 text-electric",
  success: "border-emerald-500/30 bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
  error: "border-destructive/30 bg-destructive/10 text-destructive",
} as const;

export function Notice({
  tone = "info",
  children,
}: {
  tone?: keyof typeof tones;
  children: ReactNode;
}) {
  return (
    <p
      role={tone === "error" ? "alert" : "status"}
      className={cn(
        "rounded-xl border px-3.5 py-2.5 text-sm leading-relaxed",
        tones[tone],
      )}
    >
      {children}
    </p>
  );
}
