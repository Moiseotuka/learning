"use client";

import Link from "next/link";
import { ChevronDownIcon, SearchIcon } from "lucide-react";
import { useMemo, useState } from "react";

import { CategoryIcon } from "@/components/category-icon";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages.catalogue;

export type CatalogType = "formations" | "tutoriels";

type SidebarCategory = {
  id: string;
  name: string;
  icon: string;
};

const VISIBLE_BY_DEFAULT = 8;

function catalogueHref(type: CatalogType, tech: string) {
  const params = new URLSearchParams();
  if (type !== "formations") params.set("type", type);
  if (tech) params.set("tech", tech);
  const query = params.toString();
  return query ? `/catalogue?${query}` : "/catalogue";
}

export function CatalogSidebar({
  activeType,
  activeTech,
  categories,
  counts,
  totals,
}: {
  activeType: CatalogType;
  activeTech: string;
  categories: SidebarCategory[];
  counts: Record<CatalogType, Record<string, number>>;
  totals: Record<CatalogType, number>;
}) {
  const [query, setQuery] = useState("");
  const [expanded, setExpanded] = useState(false);

  const countsForType = counts[activeType];

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return categories;
    return categories.filter((category) =>
      category.name.toLowerCase().includes(needle),
    );
  }, [categories, query]);

  const showAll = expanded || query.trim().length > 0;
  const visible = showAll ? filtered : filtered.slice(0, VISIBLE_BY_DEFAULT);
  const remaining = filtered.length - visible.length;

  const itemClass = (active: boolean) =>
    cn(
      "flex w-full items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm transition-colors",
      active
        ? "bg-electric/10 font-medium text-electric"
        : "text-muted-foreground hover:bg-muted hover:text-foreground",
    );

  return (
    <aside className="space-y-6 lg:sticky lg:top-24 lg:self-start">
      <div className="relative">
        <SearchIcon
          className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          aria-hidden
        />
        <Input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder={t.searchPlaceholder}
          aria-label={t.searchLabel}
          className="pl-9"
        />
      </div>

      <div
        role="tablist"
        aria-label={t.tabLabel}
        className="flex gap-1 rounded-xl border border-hairline bg-muted/60 p-1"
      >
        {(["formations", "tutoriels"] as const).map((type) => {
          const active = type === activeType;
          return (
            <Link
              key={type}
              role="tab"
              aria-selected={active}
              href={catalogueHref(type, activeTech)}
              className={cn(
                "flex-1 rounded-lg px-3 py-2 text-center text-sm transition-colors",
                active
                  ? "bg-background font-medium text-foreground shadow-sm"
                  : "text-muted-foreground hover:text-foreground",
              )}
            >
              {t.tabs[type]}
              <span className="ml-1.5 text-xs tabular-nums text-muted-foreground">
                {totals[type]}
              </span>
            </Link>
          );
        })}
      </div>

      <nav aria-label={t.technologies}>
        <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
          {t.technologies}
        </p>

        <ul className="mt-2 space-y-0.5">
          <li>
            <Link href={catalogueHref(activeType, "")} className={itemClass(!activeTech)}>
              <span className="min-w-0 flex-1 truncate">{t.all}</span>
              <span className="text-xs tabular-nums">{totals[activeType]}</span>
            </Link>
          </li>

          {visible.map((category) => {
            const count = countsForType[category.id] ?? 0;
            return (
              <li key={category.id}>
                <Link
                  href={catalogueHref(activeType, category.id)}
                  className={itemClass(activeTech === category.id)}
                >
                  <CategoryIcon
                    name={category.icon}
                    className="size-4 shrink-0"
                  />
                  <span className="min-w-0 flex-1 truncate">{category.name}</span>
                  <span
                    className={cn(
                      "text-xs tabular-nums",
                      count === 0 && "opacity-50",
                    )}
                  >
                    {count}
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>

        {remaining > 0 ? (
          <button
            type="button"
            onClick={() => setExpanded(true)}
            className="mt-2 inline-flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-medium text-muted-foreground transition-colors hover:text-electric"
          >
            {t.showMore(remaining)}
            <ChevronDownIcon className="size-3.5" aria-hidden />
          </button>
        ) : null}
      </nav>
    </aside>
  );
}
