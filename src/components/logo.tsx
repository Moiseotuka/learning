import { cn } from "@/lib/utils";

/** Marque easyTech : chevron d'apprentissage + barre de progression. */
export function Logo({ className, compact = false }: { className?: string; compact?: boolean }) {
  return (
    <span className={cn("inline-flex items-center gap-2", className)}>
      <span
        aria-hidden
        className="grid size-8 shrink-0 place-items-center rounded-lg bg-electric"
      >
        <svg viewBox="0 0 24 24" fill="none" className="size-5">
          <path
            d="M9 6.5 16.5 12 9 17.5V6.5Z"
            fill="white"
            fillOpacity="0.95"
          />
          <rect x="4" y="19" width="16" height="2" rx="1" fill="white" fillOpacity="0.55" />
        </svg>
      </span>
      {!compact && (
        <span className="text-lg font-semibold tracking-tight">
          easy<span className="text-electric">Tech</span>
        </span>
      )}
    </span>
  );
}
