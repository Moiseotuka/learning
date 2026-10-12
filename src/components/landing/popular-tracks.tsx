import { ArrowRightIcon, ClockIcon, LayersIcon } from "lucide-react";
import Link from "next/link";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { levelTone } from "@/components/catalog/level-tone";
import type { LevelType, PopularTrack } from "@/config/catalog";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages;

const HIGHLIGHTED = 6;

const startLabel = (level: LevelType) =>
  level === "debutant" ? "Commencez ici" : t.tracks.levelLabels[level];

export function PopularTracks({
  tracks,
  prices = new Map<string, number>(),
}: {
  tracks: PopularTrack[];
  prices?: Map<string, number>;
}) {
  const highlighted = tracks.slice(0, HIGHLIGHTED);

  return (
    <Section id={t.tracks.id}>
      <SectionHeading
        eyebrow={t.tracks.eyebrow}
        title={t.tracks.title}
        description={t.tracks.description}
      />

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {highlighted.map((track, index) => {
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
                      className={cn(
                        "rounded-full px-2 py-0.5 text-[11px] font-medium",
                        levelTone[track.levelFrom],
                      )}
                      variant="secondary"
                    >
                      {startLabel(track.levelFrom)}
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
                      <Link href={`/app/parcours/${track.slug}`}>
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

      {tracks.length > HIGHLIGHTED ? (
        <Reveal delay={120}>
          <div className="mt-8 flex justify-center">
            <Button asChild variant="outline" size="lg" className="h-11 border-hairline px-6">
              <Link href={links.catalogue}>
                {t.tracks.allTracks(tracks.length)}
                <ArrowRightIcon className="size-4" aria-hidden />
              </Link>
            </Button>
          </div>
        </Reveal>
      ) : null}
    </Section>
  );
}
