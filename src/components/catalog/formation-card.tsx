import Link from "next/link";
import { ArrowRightIcon, ClockIcon, LayersIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { levelTone } from "@/components/catalog/level-tone";
import type { PopularTrack } from "@/config/catalog";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages;

export function FormationCard({ track }: { track: PopularTrack }) {
  return (
    <article className="group flex h-full flex-col rounded-2xl border border-hairline bg-card transition-all duration-300 hover:-translate-y-1 hover:border-electric/50 hover:shadow-md">
      <div className="flex flex-1 flex-col p-5">
        <div className="flex items-center justify-between gap-2">
          <span className="text-xs font-medium text-muted-foreground">
            {track.category}
          </span>
          <Badge
            className={cn(
              "rounded-full px-2 py-0.5 text-[11px] font-medium",
              levelTone[track.levelFrom],
            )}
            variant="secondary"
          >
            {t.tracks.levelLabels[track.levelFrom]}
          </Badge>
        </div>

        <h3 className="mt-3 text-base leading-snug font-semibold text-balance">
          {track.title}
        </h3>
        <p className="mt-2 line-clamp-2 flex-1 text-sm leading-relaxed text-muted-foreground">
          {track.bestFor}
        </p>

        <div className="mt-4 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs text-muted-foreground">
          <span className="inline-flex items-center gap-1.5">
            <ClockIcon className="size-3.5 text-electric" aria-hidden />
            {t.tracks.badges.duration(track.durationHours)}
          </span>
          <span className="inline-flex items-center gap-1.5">
            <LayersIcon className="size-3.5 text-electric" aria-hidden />
            {t.catalogue.cards.chapters(track.modules)}
          </span>
        </div>
      </div>

      <div className="mt-auto border-t border-hairline p-4">
        <Link
          href={`/parcours/${track.slug}`}
          className="inline-flex items-center gap-1.5 text-sm font-medium text-electric transition-colors hover:underline"
        >
          {t.tracks.cta}
          <ArrowRightIcon className="size-3.5" aria-hidden />
        </Link>
      </div>
    </article>
  );
}
