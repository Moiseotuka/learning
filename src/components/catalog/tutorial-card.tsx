import Image from "next/image";
import Link from "next/link";
import { ArrowRightIcon, PlayIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { levelTone } from "@/components/catalog/level-tone";
import type { CatalogTutorial } from "@/lib/catalog/queries";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages;

export function TutorialCard({ tutorial }: { tutorial: CatalogTutorial }) {
  return (
    <article className="group flex h-full flex-col overflow-hidden rounded-2xl border border-hairline bg-card transition-all duration-300 hover:-translate-y-1 hover:border-electric/50 hover:shadow-md">
      <Link
        href={`/tutoriels/${tutorial.slug}`}
        className="flex flex-1 flex-col focus-visible:outline-none"
        aria-label={`${t.catalogue.cards.watch} — ${tutorial.title}`}
      >
        <div className="relative aspect-video w-full overflow-hidden bg-muted">
          {tutorial.thumbnail ? (
            <Image
              src={tutorial.thumbnail}
              alt=""
              fill
              sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
              className="object-cover transition-transform duration-300 group-hover:scale-[1.03]"
            />
          ) : null}
          <span className="absolute right-2 top-2 grid size-8 place-items-center rounded-full bg-background/85 text-foreground opacity-0 transition-opacity duration-300 group-hover:opacity-100">
            <PlayIcon className="size-4 fill-current" aria-hidden />
          </span>
        </div>

        <div className="flex flex-1 flex-col p-4">
          <div className="flex items-center justify-between gap-2">
            <span className="truncate text-[11px] font-medium text-muted-foreground">
              {tutorial.category}
            </span>
            <Badge
              className={cn(
                "shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium",
                levelTone[tutorial.level],
              )}
              variant="secondary"
            >
              {t.tracks.levelLabels[tutorial.level]}
            </Badge>
          </div>

          <h3 className="mt-2 line-clamp-2 text-sm leading-snug font-semibold text-foreground">
            {tutorial.title}
          </h3>
          <p className="mt-1.5 line-clamp-2 flex-1 text-xs leading-relaxed text-muted-foreground">
            {tutorial.summary}
          </p>

          <div className="mt-3 flex items-center justify-between gap-2 border-t border-hairline pt-3">
            <span className="min-w-0 truncate text-xs text-muted-foreground">
              {tutorial.channel}
            </span>
            <span className="inline-flex shrink-0 items-center gap-1 text-xs font-medium text-electric">
              {t.catalogue.cards.watch}
              <ArrowRightIcon className="size-3.5" aria-hidden />
            </span>
          </div>
        </div>
      </Link>
    </article>
  );
}
