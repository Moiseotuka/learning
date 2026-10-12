import Link from "next/link";
import {
  ArrowRightIcon,
  BookOpenIcon,
  GraduationCapIcon,
  PlayIcon,
} from "lucide-react";

import { levelTone } from "@/components/catalog/level-tone";
import { Badge } from "@/components/ui/badge";
import type { CatalogSearchItem, CatalogSearchKind } from "@/lib/catalog/search";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages;
const s = messages.catalogue.search;

const KIND_ICON = {
  formation: GraduationCapIcon,
  chapitre: BookOpenIcon,
  tutoriel: PlayIcon,
} as const;

const GROUP_ORDER: CatalogSearchKind[] = ["formation", "chapitre", "tutoriel"];

function SearchResultRow({ item }: { item: CatalogSearchItem }) {
  const Icon = KIND_ICON[item.kind];

  return (
    <li>
      <Link
        href={item.href}
        className="group flex items-start gap-3 rounded-xl border border-hairline bg-card p-4 transition-all hover:-translate-y-0.5 hover:border-electric/50 hover:shadow-md"
      >
        <span
          className="grid size-9 shrink-0 place-items-center rounded-lg bg-electric/12 text-electric"
          aria-hidden
        >
          <Icon className="size-4" />
        </span>

        <span className="min-w-0 flex-1">
          <span className="flex flex-wrap items-center gap-2">
            <span className="text-sm leading-snug font-semibold group-hover:text-electric">
              {item.title}
            </span>
            <Badge
              variant="secondary"
              className={cn(
                "rounded-full px-2 py-0.5 text-[11px] font-medium",
                levelTone[item.level],
              )}
            >
              {t.tracks.levelLabels[item.level]}
            </Badge>
          </span>

          <span className="mt-1 block text-xs text-muted-foreground">
            {item.kind === "chapitre"
              ? item.context
                ? s.inTrack(item.context)
                : t.tracks.levelLabels[item.level]
              : item.context}
          </span>

          {item.summary ? (
            <span className="mt-1.5 line-clamp-2 block text-xs leading-relaxed text-muted-foreground/90">
              {item.summary}
            </span>
          ) : null}
        </span>

        <ArrowRightIcon
          className="mt-1 size-4 shrink-0 text-muted-foreground transition-colors group-hover:text-electric"
          aria-hidden
        />
      </Link>
    </li>
  );
}

export function SearchResults({
  query,
  items,
}: {
  query: string;
  items: CatalogSearchItem[];
}) {
  const groups = GROUP_ORDER.map((kind) => ({
    kind,
    rows: items.filter((item) => item.kind === kind),
  })).filter((group) => group.rows.length > 0);

  if (groups.length === 0) {
    return (
      <div className="mt-6 rounded-2xl border border-dashed border-hairline bg-card/50 px-6 py-14 text-center">
        <p className="text-sm font-medium text-foreground">{s.none(query)}</p>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          {s.noneHint}
        </p>
        <ul className="mt-6 flex flex-wrap items-center justify-center gap-1.5">
          {s.suggestions.map((suggestion) => (
            <li key={suggestion}>
              <Link
                href={`/catalogue?q=${encodeURIComponent(suggestion)}`}
                className="inline-block rounded-full border border-hairline bg-card px-3 py-1.5 text-xs text-muted-foreground transition-colors hover:border-electric/50 hover:text-foreground"
              >
                {suggestion}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    );
  }

  return (
    <div className="mt-6 space-y-8">
      {groups.map((group) => (
        <section key={group.kind} aria-labelledby={`search-${group.kind}`}>
          <h2
            id={`search-${group.kind}`}
            className="text-xs font-semibold uppercase tracking-wider text-muted-foreground"
          >
            {s.groups[group.kind](group.rows.length)}
          </h2>
          <ul className="mt-3 space-y-3">
            {group.rows.map((item) => (
              <SearchResultRow key={`${item.kind}-${item.id}`} item={item} />
            ))}
          </ul>
        </section>
      ))}
    </div>
  );
}
