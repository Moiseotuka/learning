"use client";

import Link from "next/link";
import { ArrowRightIcon, ChevronLeftIcon, ChevronRightIcon } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";

import { ProgressBar } from "@/components/learning/progress-bar";
import { Badge } from "@/components/ui/badge";
import { messages } from "@/i18n";
import type { LearnerTrack } from "@/lib/learning/types";
import { cn } from "@/lib/utils";

const t = messages.learner;

type TrackCarouselProps = {
  tracks: LearnerTrack[];
  primaryTrackId?: string;
};

export function TrackCarousel({ tracks, primaryTrackId }: TrackCarouselProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [current, setCurrent] = useState(0);
  const [canPrev, setCanPrev] = useState(false);
  const [canNext, setCanNext] = useState(true);

  const update = useCallback(() => {
    const el = containerRef.current;
    if (!el) return;
    const card = el.querySelector<HTMLElement>("[data-slide]");
    const step = card ? card.getBoundingClientRect().width + 12 : el.clientWidth;
    const max = el.scrollWidth - el.clientWidth;
    const idx = Math.round(el.scrollLeft / step);
    setCurrent(Math.min(Math.max(idx, 0), tracks.length - 1));
    setCanPrev(el.scrollLeft > 4);
    setCanNext(el.scrollLeft < max - 4);
  }, [tracks.length]);

  useEffect(() => {
    update();
    const el = containerRef.current;
    if (!el) return;
    el.addEventListener("scroll", update, { passive: true });
    window.addEventListener("resize", update);
    return () => {
      el.removeEventListener("scroll", update);
      window.removeEventListener("resize", update);
    };
  }, [update, tracks.length]);

  const scrollBy = (dir: 1 | -1) => {
    const el = containerRef.current;
    if (!el) return;
    const card = el.querySelector<HTMLElement>("[data-slide]");
    const step = card ? card.getBoundingClientRect().width + 12 : el.clientWidth;
    el.scrollBy({ left: dir * step, behavior: "smooth" });
  };

  if (tracks.length === 0) return null;

  return (
    <div className="relative">
      <div
        ref={containerRef}
        role="region"
        aria-roledescription="carousel"
        aria-label={t.tracksTitle}
        className="flex snap-x snap-mandatory gap-3 overflow-x-auto pb-1 [scrollbar-width:none] touch-pan-x [&::-webkit-scrollbar]:hidden"
      >
        {tracks.map((track, index) => {
          const resumeChapter = track.chapters.find(
            (chapter) => chapter.slug === track.nextChapterSlug,
          );
          const started =
            track.completedCount > 0 ||
            track.chapters.some((chapter) => chapter.progress);
          const href = resumeChapter
            ? `/app/parcours/${track.slug}/chapitres/${resumeChapter.slug}`
            : `/app/parcours/${track.slug}`;
          const selected = primaryTrackId === track.id;

          return (
            <article
              key={track.id}
              data-slide
              role="group"
              aria-roledescription="slide"
              aria-label={`${index + 1} / ${tracks.length}`}
              className={cn(
                "snap-start flex min-w-0 shrink-0 flex-col overflow-hidden rounded-xl border p-4 transition-all duration-200",
                "w-[85%] sm:w-[calc(50%-0.375rem)] lg:w-[calc(33.333%-0.5rem)] xl:w-[calc(25%-0.5625rem)]",
                selected
                  ? "border-electric/60 bg-electric/[0.05] ring-1 ring-electric/30"
                  : "border-hairline bg-card hover:-translate-y-0.5 hover:border-electric/50 hover:shadow-md",
              )}
            >
              <div className="flex min-w-0 items-center justify-between gap-2">
                <p className="min-w-0 truncate text-[10px] text-muted-foreground">
                  {track.category}
                </p>
                <Badge
                  variant="secondary"
                  className="shrink-0 rounded-full bg-electric/10 px-2 py-0.5 text-[10px] font-medium text-electric hover:bg-electric/15"
                >
                  {messages.common.levels[track.level]}
                </Badge>
              </div>
              <h3 className="mt-2 min-w-0 line-clamp-2 break-words text-sm font-semibold leading-snug text-foreground">
                <Link
                  href={`/app/parcours/${track.slug}`}
                  className="transition-colors hover:text-electric"
                >
                  {track.title}
                </Link>
              </h3>

              <div className="mt-auto min-w-0 pt-3">
                <div className="mb-1.5 flex min-w-0 items-center justify-between gap-2 text-[10px] text-muted-foreground">
                  <span className="shrink-0">{t.progressLabel(track.percent)}</span>
                  <span className="min-w-0 truncate tabular-nums">
                    {t.chaptersLabel(track.completedCount, track.totalChapters)}
                  </span>
                </div>
                <ProgressBar percent={track.percent} />
              </div>

              <div className="mt-3 flex min-w-0 items-center justify-between gap-2 border-t border-hairline pt-3">
                <Link
                  href={href}
                  className="inline-flex min-w-0 items-center gap-1 truncate text-xs font-medium text-electric transition-colors hover:text-electric/80"
                >
                  <span className="truncate">{started ? t.resume : t.start}</span>
                  <ArrowRightIcon className="size-3.5 shrink-0" aria-hidden />
                </Link>
              </div>
            </article>
          );
        })}
      </div>

      <div className="pointer-events-none absolute inset-y-0 left-0 w-6 rounded-l-xl bg-gradient-to-r from-card to-transparent sm:w-10" />
      <div className="pointer-events-none absolute inset-y-0 right-0 w-6 rounded-r-xl bg-gradient-to-l from-card to-transparent sm:w-10" />

      <div className="mt-3 flex items-center justify-between gap-2">
        <span className="text-xs tabular-nums text-muted-foreground">
          {current + 1} / {tracks.length}
        </span>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => scrollBy(-1)}
            disabled={!canPrev}
            aria-label="Parcours précédent"
            className="grid size-8 place-items-center rounded-full border border-hairline bg-card text-foreground transition-colors hover:border-electric/50 hover:text-electric disabled:cursor-not-allowed disabled:opacity-40"
          >
            <ChevronLeftIcon className="size-4" aria-hidden />
          </button>
          <button
            type="button"
            onClick={() => scrollBy(1)}
            disabled={!canNext}
            aria-label="Parcours suivant"
            className="grid size-8 place-items-center rounded-full border border-hairline bg-card text-foreground transition-colors hover:border-electric/50 hover:text-electric disabled:cursor-not-allowed disabled:opacity-40"
          >
            <ChevronRightIcon className="size-4" aria-hidden />
          </button>
        </div>
      </div>
    </div>
  );
}