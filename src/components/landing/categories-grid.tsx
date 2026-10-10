"use client";

import { ArrowRightIcon, CheckIcon, LockIcon } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";

import { CategoryIcon } from "@/components/category-icon";
import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { levels, type Category, type LevelType } from "@/config/catalog";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages;

type Filter = "tous" | LevelType;

type CategoriesGridProps = {
  categories: Category[];
};

const levelBadgeLabel = (level: LevelType) =>
  level === "debutant" ? "Commencez ici" : t.categories.filters[level];

export function CategoriesGrid({ categories }: CategoriesGridProps) {
  const [filter, setFilter] = useState<Filter>("tous");

  const filtered = useMemo(
    () =>
      filter === "tous"
        ? categories
        : categories.filter((category) => category.levels.includes(filter)),
    [filter, categories],
  );

  const filters: Filter[] = ["tous", ...levels];

  return (
    <Section id={t.categories.id} className="bg-background">
      <SectionHeading
        eyebrow={t.categories.eyebrow}
        title={t.categories.title}
        description={t.categories.description}
      />

      <Reveal>
        <div
          role="group"
          aria-label={t.categories.filterLabel}
          className="mb-8 flex flex-wrap justify-center gap-2"
        >
          {filters.map((value) => {
            const active = filter === value;
            return (
              <button
                key={value}
                type="button"
                aria-pressed={active}
                onClick={() => setFilter(value)}
                className={cn(
                  "rounded-full border px-4 py-2 text-sm transition-colors",
                  active
                    ? "border-electric bg-electric text-primary-foreground"
                    : "border-hairline text-muted-foreground hover:border-electric/50 hover:text-foreground",
                )}
              >
                {t.categories.filters[value]}
              </button>
            );
          })}
        </div>
      </Reveal>

      {filtered.length === 0 ? (
        <p className="py-10 text-center text-sm text-muted-foreground">
          {t.categories.empty}
        </p>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.map((category, index) => (
            <Reveal key={category.id} delay={(index % 3) * 70}>
              <article className="group flex h-full flex-col rounded-2xl border border-hairline bg-card p-5 transition-all duration-300 hover:-translate-y-1 hover:border-electric/50 hover:shadow-md">
                <div className="flex items-start gap-4">
                  <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-electric/12 text-electric transition-colors group-hover:bg-electric group-hover:text-primary-foreground">
                    <CategoryIcon name={category.icon} className="size-5" />
                  </span>
                  <div className="min-w-0">
                    <h3 className="text-base font-semibold text-foreground">
                      {category.name}
                    </h3>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {t.categories.tracksLabel(category.trackCount)}
                    </p>
                  </div>
                </div>

                <p className="mt-4 flex-1 text-sm leading-relaxed text-muted-foreground">
                  {category.description}
                </p>

                <div className="mt-5 flex flex-wrap items-center gap-1.5">
                  {levels.map((level) => {
                    const available = category.levels.includes(level);
                    return (
                      <span
                        key={level}
                        title={t.categories.filters[level]}
                        className={cn(
                          "inline-flex items-center gap-1 rounded-md border px-2 py-1 text-[11px] font-medium",
                          available
                            ? "border-hairline text-foreground"
                            : "border-hairline/60 text-muted-foreground/50",
                        )}
                      >
                        {available ? (
                          <CheckIcon className="size-3 text-vivid" aria-hidden />
                        ) : (
                          <LockIcon className="size-3" aria-hidden />
                        )}
                        {levelBadgeLabel(level)}
                      </span>
                    );
                  })}
                </div>

                <div className="mt-5 flex items-center justify-between border-t border-hairline pt-4">
                  <Badge
                    variant="secondary"
                    className="rounded-full bg-electric/10 text-electric hover:bg-electric/15"
                  >
                    {t.categories.tracksLabel(category.trackCount)}
                  </Badge>
                  <Button
                    asChild
                    variant="ghost"
                    size="sm"
                    className="text-muted-foreground group-hover:text-electric"
                  >
                    <Link href={`/catalogue?tech=${category.id}`}>
                      {t.categories.cta}
                      <ArrowRightIcon className="size-3.5" aria-hidden />
                    </Link>
                  </Button>
                </div>
              </article>
            </Reveal>
          ))}
        </div>
      )}
    </Section>
  );
}
