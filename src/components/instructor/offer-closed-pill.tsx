import { ClockIcon } from "lucide-react";

import { cn } from "@/lib/utils";

/**
 * L'offre formateur est gelée : on l'annonce, mais sans poser un contrôle que
 * l'apprenant cliquerait dans le vide.
 */
export function OfferClosedPill({
  label,
  className,
}: {
  label: string;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center justify-center gap-2 rounded-lg border border-dashed border-hairline bg-card/60 px-4 text-xs font-medium text-muted-foreground",
        className,
      )}
    >
      <ClockIcon aria-hidden className="size-4 shrink-0" />
      {label}
    </span>
  );
}
