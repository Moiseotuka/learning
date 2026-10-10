import { ArrowRightIcon, ClockIcon, LayersIcon, StarIcon, UsersIcon } from "lucide-react";
import Link from "next/link";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { popularTracks, type LevelType, type PopularTrack } from "@/config/catalog";
import { messages } from "@/i18n";
import { cn } from "cn";

const t = messages;

const levelTone: Record<LevelType, string> = {
  debutant: "bg-emerald-500/12 text-emerald-600 dark:text-emerald-400",
  intermediaire: "bg-electric/12 text-electric",
  avance: "bg-violet-500/12 text-violet-600 dark:text-violet-400",
  projet: "bg-amber-500/12 text-amber-600 dark:text-amber-400",
};

const startLabel = (level: LevelType) =>
  level === "debutant" ? "Commencez ici" : t.tracks.levelLabels[level];

export function PopularTracks({
  tracks = popularTracks,
  prices = new Map<string, number>(),
}: {
  tracks?: PopularTrack[];
  prices?: Map<string, number>;
}) {
  return (
    <Section id={t.tracks.id}>
      <SectionHeading
        eyebrow={t.tracks.eyebrow}
        title={t.tracks.title}
        description={t.tracks.description}
      />

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {tracks.map((track, index) => {
          const starting = prices.get(track.categoryId);

          return (
          <Reveal key={track.slug} delay={(index % 3) * 80}>
            <Card className="group h-full rounded-2xl border-hairline bg-card transition-all duration-300 hover:-translate-y-1 hover:border-electric/50 hover:shadow-md">
              <CardContent className="flex h-full flex-col p-5">
                <div className="flex items-center justify-between gap-2">
                  <span className="text-xs font-medium text-muted-foreground">
                    {track.category}
                  </span>
                  <Badge
                    className={`rounded-full px-2 py-0.5 text-[11px] font-medium ${levelTone[track.levelFrom]}`}
                    variant="secondary"
                  >
                    {startLabel(track.levelFrom)}
                  </Badge>
                </div>

                <h3 className="mt-3 text-base leading-snug font-semibold text-balance">
                  {track.title}
                </h3>
                <p className="mt-2 flex-1 text-sm leading-relaxed text-muted-foreground">
                  {track.bestFor}
                </p>

                <div className="mt-4 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs text-muted-foreground">
                  <span className="inline-flex items-center gap-1.5">
                    <ClockIcon className="size-3.5 text-electric" aria-hidden />
                    {t.tracks.badges.duration(track.durationHours)}
                  </span>
                  <span className="inline-flex items-center gap-1.5">
                    <LayersIcon className="size-3.5 text-electric" aria-hidden />
                    {t.tracks.badges.modules(track.modules)}
                  </span>
                  <span className="inline-flex items-center gap-1.5">
                    <StarIcon className="size-3.5 fill-amber-400 text-amber-400" aria-hidden />
                    {t.tracks.badges.rating(track.rating)}
                  </span>
                  <span className="inline-flex items-center gap-1.5">
                    <UsersIcon className="size-3.5 text-electric" aria-hidden />
                    {t.tracks.badges.students(track.students)}
                  </span>
                </div>

                <div
                  className={cn(
                    "mt-5 flex items-center justify-between border-t border-hairline pt-4",
                    starting === undefined && "justify-end",
                  )}
                >
                  {starting !== undefined ? (
                    <div>
                      {starting !== 0 ? (
                        <p className="text-[11px] text-muted-foreground">
                          {t.tracks.from}
                        </p>
                      ) : null}
                      <p className="text-lg font-semibold text-foreground">
                        {starting === 0
                          ? t.tracks.badges.free
                          : t.tracks.badges.price(starting)}
                      </p>
                    </div>
                  ) : null}
                  <Button
                    asChild
                    variant="outline"
                    size="sm"
                    className="border-hairline group-hover:border-electric group-hover:text-electric"
                  >
                    <Link href={`/catalogue?tech=${track.categoryId}`}>
                      {t.tracks.cta}
                      <ArrowRightIcon className="size-3.5" aria-hidden />
                    </Link>
                  </Button>
                </div>
              </CardContent>
            </Card>
          </Reveal>
          );
        })}
      </div>
    </Section>
  );
}
