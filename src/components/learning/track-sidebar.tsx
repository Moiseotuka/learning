"use client";

import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import {
  BookOpenIcon,
  CheckIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  EyeIcon,
  ListIcon,
  LockIcon,
  PlayCircleIcon,
  SearchIcon,
} from "lucide-react";

import { ResourceLink } from "@/components/learning/resource-viewer";
import { ProgressBar } from "@/components/learning/progress-bar";
import {
  readStoredStep,
  readVisitedPages,
  readVisitedSteps,
  stepStorageKey,
  writeVisitedPages,
  writeVisitedSteps,
} from "@/components/learning/steps-nav";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import {
  chapterStepOrder,
  stepBlockedByVideos,
} from "@/lib/learning/steps-order";
import type {
  LearnerChapter,
  LearnerTrack,
  TrackResourceGroup,
} from "@/lib/learning/types";
import { cn } from "cn";

const t = messages.learner;

function normalize(value: string) {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

type StepItem = {
  key: string;
  label: string;
  href: string;
  done: boolean;
  /** Compteur x / y affiché à droite (pages du Cours, etc.). */
  count?: { done: number; total: number };
};

function buildStepItems(
  base: string,
  chapter: LearnerChapter,
  videoCount: number,
  visited: Set<string>,
  pagesTotal = 0,
  visitedPages: number[] = [],
): StepItem[] {
  const labels: Record<string, string> = {
    objectifs: t.stepLabels.objectives,
    videos: t.stepLabels.videos,
    cours: t.stepLabels.lesson,
    exercice: t.stepLabels.exercise,
    ressources: t.stepLabels.resources,
  };
  const order = chapterStepOrder(videoCount > 0, chapter.id);
  const visitedPageSet = new Set(visitedPages);
  const pagesDone = Array.from({ length: pagesTotal }, (_, index) => index + 1)
    .filter((position) => visitedPageSet.has(position)).length;

  const items: StepItem[] = order.map((key) => {
    const item: StepItem = {
      key,
      label: labels[key] ?? key,
      href: `${base}?etape=${key}`,
      done:
        key === "videos"
          ? chapter.videosDone
          : key === "exercice"
            ? chapter.practiceDone || visited.has(key)
            : visited.has(key),
    };
    if (key === "cours" && pagesTotal > 0) {
      item.count = { done: pagesDone, total: pagesTotal };
      item.done = pagesDone >= pagesTotal;
    }
    return item;
  });
  items.push({
    key: "quiz",
    label: t.stepLabels.quiz,
    href: `${base}/quiz`,
    done: chapter.progress?.completed ?? false,
  });
  return items;
}

function StatusCircle({ done }: { done: boolean }) {
  return (
    <span
      className={cn(
        "mt-0.5 grid size-4 shrink-0 place-items-center rounded-full border",
        done
          ? "border-emerald-500 bg-emerald-500 text-white"
          : "border-hairline bg-card",
      )}
      aria-hidden
    >
      {done ? <CheckIcon className="size-2.5" /> : null}
    </span>
  );
}

function ChevronButton({
  expanded,
  onToggle,
  ariaLabel,
}: {
  expanded: boolean;
  onToggle: () => void;
  ariaLabel: string;
}) {
  return (
    <button
      type="button"
      onClick={onToggle}
      aria-expanded={expanded}
      aria-label={ariaLabel}
      className="grid size-6 shrink-0 cursor-pointer place-items-center rounded text-muted-foreground transition-colors hover:text-foreground"
    >
      {expanded ? (
        <ChevronUpIcon className="size-3.5" aria-hidden />
      ) : (
        <ChevronDownIcon className="size-3.5" aria-hidden />
      )}
    </button>
  );
}

function ChapterTimeline({
  chapterTitle,
  items,
  activeStep,
  onNavigate,
}: {
  chapterTitle: string;
  items: StepItem[];
  activeStep: string | null;
  onNavigate?: () => void;
}) {
  if (items.length === 0) return null;

  return (
    <div className="pb-2.5 pr-2">
      <ol aria-label={`${chapterTitle} — ${t.stepsLabel}`} className="relative">
        <span
          aria-hidden
          className="absolute bottom-2 left-[28px] top-0 w-px bg-hairline"
        />
        {items.map((item) => {
          const isActive = item.key === activeStep;
          return (
            <li key={item.key}>
              <Link
                href={item.href}
                onClick={onNavigate}
                aria-current={isActive ? "step" : undefined}
                className={cn(
                  "flex items-start gap-2.5 py-1.5 pl-5 pr-2 text-[12.5px] leading-snug transition-colors",
                  isActive
                    ? "font-medium text-electric"
                    : "text-foreground/75 hover:text-foreground",
                )}
              >
                <span
                  className={cn(
                    "relative mt-0.5 grid size-4 shrink-0 place-items-center rounded-full border",
                    item.done
                      ? "border-emerald-500 bg-emerald-500 text-white"
                      : isActive
                        ? "border-electric bg-card"
                        : "border-hairline bg-card",
                  )}
                >
                  {item.done ? (
                    <CheckIcon className="size-2.5" aria-hidden />
                  ) : null}
                </span>
                <span className="min-w-0 flex-1">{item.label}</span>
                {item.count ? (
                  <span className="ml-1 shrink-0 text-[11px] tabular-nums text-muted-foreground">
                    {" "}
                    {item.count.done} / {item.count.total}
                  </span>
                ) : null}
              </Link>
            </li>
          );
        })}
      </ol>
    </div>
  );
}

function LockedChapterRow({ chapter }: { chapter: LearnerChapter }) {
  return (
    <div className="flex items-center gap-2.5 py-2 pl-5 pr-3 opacity-60">
      <LockIcon
        className="size-4 shrink-0 text-muted-foreground/50"
        aria-hidden
      />
      <span className="min-w-0 flex-1 text-[12.5px] leading-snug text-foreground/85">
        {chapter.title}
      </span>
    </div>
  );
}

function ChapterRow({
  chapter,
  trackSlug,
  items,
  doneCount,
  active,
  expanded,
  activeStep,
  onToggle,
  onNavigate,
}: {
  chapter: LearnerChapter;
  trackSlug: string;
  items: StepItem[];
  doneCount: number;
  active: boolean;
  expanded: boolean;
  activeStep: string | null;
  onToggle: (slug: string) => void;
  onNavigate?: () => void;
}) {
  const router = useRouter();
  const base = `/app/parcours/${trackSlug}/chapitres/${chapter.slug}`;
  const allDone = items.length > 0 && doneCount === items.length;

  const handleClick = (event: React.MouseEvent<HTMLAnchorElement>) => {
    if (
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      event.button !== 0
    ) {
      return;
    }
    const step = readStoredStep(trackSlug, chapter.slug);
    if (step && step !== "objectifs") {
      event.preventDefault();
      router.push(`${base}?etape=${step}`);
    }
    onNavigate?.();
  };

  if (!chapter.unlocked || chapter.levelLocked) {
    return <LockedChapterRow chapter={chapter} />;
  }

  return (
    <div
      className={cn(
        "rounded-lg transition-colors",
        active ? "bg-electric/10" : "hover:bg-muted/50",
      )}
    >
      <div className="flex items-start gap-2 py-2 pl-5 pr-1.5">
        <Link
          href={base}
          onClick={handleClick}
          aria-current={active ? "page" : undefined}
          className="flex min-w-0 flex-1 items-start gap-2.5 text-left"
        >
          <StatusCircle done={allDone} />
          <span
            className={cn(
              "min-w-0 flex-1 text-[12.5px] leading-snug",
              active ? "font-medium text-electric" : "text-foreground/85",
            )}
          >
            {chapter.title}
          </span>
          <span className="mt-0.5 shrink-0 text-[11px] tabular-nums text-muted-foreground">
            {doneCount} / {items.length}
          </span>
        </Link>
        <ChevronButton
          expanded={expanded}
          onToggle={() => onToggle(chapter.slug)}
          ariaLabel={`${expanded ? t.player.sidebarCollapse : t.player.sidebarExpand} : ${chapter.title}`}
        />
      </div>

      {expanded ? (
        <ChapterTimeline
          chapterTitle={chapter.title}
          items={items}
          activeStep={activeStep}
          onNavigate={onNavigate}
        />
      ) : null}
    </div>
  );
}

export function TrackSidebar({
  track,
  resources,
  videoCounts,
  pageCounts,
  onNavigate,
}: {
  track: LearnerTrack;
  resources: TrackResourceGroup[];
  videoCounts?: Record<string, number>;
  pageCounts?: Record<string, number>;
  onNavigate?: () => void;
}) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [sub, setSub] = useState<"chapters" | "resources">("chapters");
  const [query, setQuery] = useState("");
  const [visitedMap, setVisitedMap] = useState<Record<string, string[]>>({});
  const [pagesMap, setPagesMap] = useState<Record<string, number[]>>({});
  const [closedLevels, setClosedLevels] = useState<Set<string>>(new Set());

  const activeChapter = track.chapters.find((chapter) =>
    pathname.includes(`/chapitres/${chapter.slug}`),
  );
  const activeSlug = activeChapter?.slug ?? null;

  const resumeChapter = track.chapters.find(
    (chapter) => chapter.slug === track.nextChapterSlug,
  );

  const etape = searchParams.get("etape");
  const quizActive = /\/chapitres\/[^/]+\/quiz\/?$/.test(pathname);
  const activeVideoCount = activeChapter
    ? videoCounts?.[activeChapter.slug] ?? 0
    : 0;
  const stepKeys = chapterStepOrder(
    activeVideoCount > 0,
    activeChapter?.id ?? "",
  );
  const requested = quizActive
    ? "quiz"
    : stepKeys.includes(etape ?? "")
      ? (etape as string)
      : stepKeys[0];
  const videosBlocked =
    activeVideoCount > 0 && !(activeChapter?.videosDone ?? false);
  const activeStep =
    activeChapter &&
    stepBlockedByVideos(requested, stepKeys, videosBlocked)
      ? "videos"
      : activeChapter
        ? requested
        : null;

  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const [pinned, setPinned] = useState<Set<string>>(new Set());

  const isExpanded = (slug: string) =>
    slug === activeSlug ? !collapsed.has(slug) : pinned.has(slug);

  const toggleChapter = (slug: string) => {
    const update = (prev: Set<string>) => {
      const next = new Set(prev);
      if (next.has(slug)) next.delete(slug);
      else next.add(slug);
      return next;
    };
    if (slug === activeSlug) setCollapsed(update);
    else setPinned(update);
  };

  const toggleLevel = (label: string) => {
    setClosedLevels((prev) => {
      const next = new Set(prev);
      if (next.has(label)) next.delete(label);
      else next.add(label);
      return next;
    });
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      const initial: Record<string, string[]> = {};
      const initialPages: Record<string, number[]> = {};
      for (const chapter of track.chapters) {
        initial[chapter.slug] = readVisitedSteps(track.slug, chapter.slug);
        initialPages[chapter.slug] = readVisitedPages(track.slug, chapter.slug);
      }
      setVisitedMap(initial);
      setPagesMap(initialPages);
    }, 0);
    return () => clearTimeout(timer);
  }, [track.slug, track.chapters]);

  useEffect(() => {
    if (!activeSlug || activeStep !== "cours") return;
    const total = pageCounts?.[activeSlug] ?? 0;
    if (total <= 0) return;
    const stored = readVisitedPages(track.slug, activeSlug);
    const raw = searchParams.get("page");
    const parsed = raw === null ? Number.NaN : Number.parseInt(raw, 10);
    const page =
      Number.isFinite(parsed) && parsed >= 1 && parsed <= total
        ? parsed
        : (stored[stored.length - 1] ?? 1);
    if (stored.includes(page)) return;
    const next = [...stored, page];
    writeVisitedPages(track.slug, activeSlug, next);
    const timer = setTimeout(
      () => setPagesMap((prev) => ({ ...prev, [activeSlug]: next })),
      0,
    );
    return () => clearTimeout(timer);
  }, [track.slug, activeSlug, activeStep, pageCounts, searchParams]);

  useEffect(() => {
    if (!activeSlug || !activeStep) return;
    const current = readVisitedSteps(track.slug, activeSlug);
    if (current.includes(activeStep)) return;
    const next = [...current, activeStep];
    writeVisitedSteps(track.slug, activeSlug, next);
    const timer = setTimeout(
      () =>
        setVisitedMap((prev) => ({ ...prev, [activeSlug]: next })),
      0,
    );
    return () => clearTimeout(timer);
  }, [track.slug, activeSlug, activeStep]);

  useEffect(() => {
    if (!activeSlug || !activeStep || quizActive) return;
    try {
      localStorage.setItem(
        stepStorageKey(track.slug, activeSlug),
        activeStep,
      );
    } catch {
      /* stockage indisponible : la dernière étape ne sera pas mémorisée */
    }
  }, [track.slug, activeSlug, activeStep, quizActive]);

  const normalizedQuery = normalize(query.trim());
  const filtered = normalizedQuery
    ? track.chapters.filter((chapter) =>
        normalize(chapter.title).includes(normalizedQuery),
      )
    : track.chapters;

  const groups: { label: string; chapters: LearnerChapter[] }[] = [];
  for (const chapter of filtered) {
    const label = messages.common.levels[chapter.level];
    const last = groups[groups.length - 1];
    if (last && last.label === label) last.chapters.push(chapter);
    else groups.push({ label, chapters: [chapter] });
  }

  const subTabs = [
    { key: "chapters" as const, label: t.player.subChapters, Icon: ListIcon },
    {
      key: "resources" as const,
      label: t.player.subResources,
      Icon: BookOpenIcon,
    },
  ];

  return (
    <div className="flex min-h-0 flex-1 flex-col bg-card">
      <div
        role="tablist"
        aria-label={t.player.subResources}
        className="flex shrink-0 gap-1.5 border-b border-hairline px-3 py-2"
      >
        {subTabs.map(({ key, label, Icon }) => (
          <button
            key={key}
            type="button"
            role="tab"
            aria-selected={sub === key}
            onClick={() => setSub(key)}
            className={cn(
              "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-[11px] font-medium transition-colors",
              sub === key
                ? "border-electric bg-electric/10 text-electric"
                : "border-hairline text-muted-foreground hover:text-foreground",
            )}
          >
            <Icon className="size-3 shrink-0" aria-hidden />
            {label}
          </button>
        ))}
      </div>

      {sub === "chapters" ? (
        <>
          <div className="shrink-0 border-b border-hairline p-3">
            <div className="relative">
              <SearchIcon
                className="pointer-events-none absolute left-2.5 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground"
                aria-hidden
              />
              <Input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder={t.player.searchPlaceholder}
                aria-label={t.player.searchLabel}
                className="h-9 pl-8 text-[13px]"
              />
            </div>
          </div>

          <div className="min-h-0 flex-1 overflow-y-auto p-3">
            {filtered.length === 0 ? (
              <p className="px-1 py-8 text-center text-xs text-muted-foreground">
                {t.player.searchEmpty}
              </p>
            ) : (
              groups.map((group) => {
                const chapterData = group.chapters.map((chapter) => {
                  const visited = new Set(visitedMap[chapter.slug] ?? []);
                  const items = buildStepItems(
                    `/app/parcours/${track.slug}/chapitres/${chapter.slug}`,
                    chapter,
                    videoCounts?.[chapter.slug] ?? 0,
                    visited,
                    pageCounts?.[chapter.slug] ?? 0,
                    pagesMap[chapter.slug] ?? [],
                  );
                  const doneCount = items.filter((item) => item.done).length;
                  return { chapter, items, doneCount };
                });
                const totalItems = chapterData.reduce(
                  (sum, data) => sum + data.items.length,
                  0,
                );
                const totalDone = chapterData.reduce(
                  (sum, data) => sum + data.doneCount,
                  0,
                );
                const percent =
                  totalItems > 0
                    ? Math.round((totalDone / totalItems) * 100)
                    : 0;
                const levelOpen = !closedLevels.has(group.label);

                return (
                  <div
                    key={group.label}
                    className="mb-4 border-t border-hairline pt-4 first:border-t-0 first:pt-0 last:mb-0"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="min-w-0 flex-1 text-[13.5px] font-semibold leading-snug text-foreground">
                        {group.label}
                      </h3>
                      <ChevronButton
                        expanded={levelOpen}
                        onToggle={() => toggleLevel(group.label)}
                        ariaLabel={`${levelOpen ? t.player.sidebarCollapse : t.player.sidebarExpand} : ${group.label}`}
                      />
                    </div>
                    <div
                      role="progressbar"
                      aria-valuenow={percent}
                      aria-valuemin={0}
                      aria-valuemax={100}
                      aria-label={group.label}
                      className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-muted"
                    >
                      <div
                        className="h-full rounded-full bg-electric transition-all"
                        style={{ width: `${percent}%` }}
                      />
                    </div>
                    <p className="mt-0.5 text-right text-[11px] tabular-nums text-muted-foreground">
                      {percent} %
                    </p>

                    {levelOpen ? (
                      <div className="mt-2 space-y-1.5">
                        {chapterData.map(
                          ({ chapter, items, doneCount }) => (
                            <ChapterRow
                              key={chapter.id}
                              chapter={chapter}
                              trackSlug={track.slug}
                              items={items}
                              doneCount={doneCount}
                              active={chapter.slug === activeSlug}
                              expanded={isExpanded(chapter.slug)}
                              activeStep={
                                chapter.slug === activeSlug ? activeStep : null
                              }
                              onToggle={toggleChapter}
                              onNavigate={onNavigate}
                            />
                          ),
                        )}
                      </div>
                    ) : null}
                  </div>
                );
              })
            )}
          </div>
        </>
      ) : (
        <div className="min-h-0 flex-1 overflow-y-auto p-3">
          {resources.length === 0 ? (
            <p className="px-1 py-8 text-center text-xs text-muted-foreground">
              {t.player.resourcesEmpty}
            </p>
          ) : (
            resources.map((group) => (
              <div key={group.chapterSlug} className="mb-4 last:mb-0">
                <p className="px-1 pb-1.5 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground/70">
                  {group.position}. {group.chapterTitle}
                </p>
                <ul className="divide-y divide-hairline">
                  {group.resources.map((resource) => (
                    <li key={resource.url}>
                      <ResourceLink
                        label={resource.label}
                        url={resource.url}
                        className="group flex w-full items-center justify-between gap-2 px-3 py-2.5 text-[13px] text-foreground/85 transition-colors hover:bg-muted/70"
                      >
                        <span className="min-w-0 truncate">
                          {resource.label}
                        </span>
                        <EyeIcon
                          className="size-3.5 shrink-0 text-muted-foreground transition-colors group-hover:text-electric"
                          aria-hidden
                        />
                      </ResourceLink>
                    </li>
                  ))}
                </ul>
              </div>
            ))
          )}
        </div>
      )}

      <footer className="shrink-0 border-t border-hairline p-4">
        <div className="flex items-baseline justify-between gap-3 text-xs">
          <span className="font-medium text-foreground">
            {t.progressLabel(track.percent)}
          </span>
          <span className="tabular-nums text-muted-foreground">
            {t.progressTotal(track.completedCount, track.totalChapters)}
          </span>
        </div>
        <ProgressBar percent={track.percent} className="mt-2" />

        {resumeChapter ? (
          <Button asChild className="mt-3 h-9 w-full px-3">
            <Link
              href={`/app/parcours/${track.slug}/chapitres/${resumeChapter.slug}`}
              onClick={onNavigate}
            >
              <PlayCircleIcon aria-hidden />
              {track.completedCount > 0 ? t.resume : t.start}
            </Link>
          </Button>
        ) : null}
      </footer>
    </div>
  );
}
