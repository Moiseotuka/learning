import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowLeftIcon,
  ArrowRightIcon,
  AwardIcon,
  CheckCircle2Icon,
  ChevronRightIcon,
  CreditCardIcon,
  LockIcon,
} from "lucide-react";
import { notFound } from "next/navigation";

import { Notice } from "@/components/auth/notice";
import { LevelUpNotification } from "@/components/learning/level-up-banner";
import { ProgressBar } from "@/components/learning/progress-bar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { type LevelType } from "@/config/catalog";
import { messages } from "@/i18n";
import { getLearnerTrack, getLevelPricing } from "@/lib/learning/queries";
import { startingPrice } from "@/lib/pricing";
import { cn } from "cn";

const t = messages.learner;
const pay = messages.payment;

export const metadata: Metadata = {
  title: t.chapterList,
  robots: { index: false },
};

export default async function TrackPage({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ notice?: string }>;
}) {
  const { slug } = await params;
  const { notice } = await searchParams;
  const track = await getLearnerTrack(slug);
  if (!track) notFound();

  const pricing = await getLevelPricing(track.categoryId);
  const starting = startingPrice(pricing?.prices);

  const resumeChapter = track.chapters.find(
    (chapter) => chapter.slug === track.nextChapterSlug,
  );

  const levelOrder: LevelType[] = [];
  for (const chapter of track.chapters) {
    if (!levelOrder.includes(chapter.level)) levelOrder.push(chapter.level);
  }

  const chapterNumbers = new Map(
    track.chapters.map((chapter, index) => [chapter.id, index + 1]),
  );

  return (
    <>
    <div>
      <header className="rounded-2xl border border-hairline bg-card p-5 sm:p-6">
        <Button
          asChild
          variant="ghost"
          className="-ml-2 -mt-1 h-8 px-2 text-xs text-muted-foreground"
        >
          <Link href="/app">
            <ArrowLeftIcon aria-hidden />
            {t.dashboardTitle}
          </Link>
        </Button>

        <p className="mt-2 text-xs font-medium text-muted-foreground">
          {track.category}
        </p>
        <h1 className="mt-1 text-2xl font-semibold tracking-tight text-foreground">
          {track.title}
        </h1>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          {track.description}
        </p>

        <div className="mt-4 flex flex-wrap gap-2">
          <Badge
            variant="secondary"
            className="rounded-full bg-electric/10 text-electric hover:bg-electric/15"
          >
            {messages.common.levels[track.level]}
          </Badge>
          <Badge
            variant="secondary"
            className="rounded-full bg-muted text-muted-foreground"
          >
            {t.trackMeta.duration(track.durationHours)}
          </Badge>
          <Badge
            variant="secondary"
            className="rounded-full bg-muted text-muted-foreground"
          >
            {t.trackMeta.modules(track.modules)}
          </Badge>
          <Badge
            variant="secondary"
            className="rounded-full bg-muted text-muted-foreground"
          >
            {t.trackMeta.rating(track.rating)}
          </Badge>
          {starting === null ? null : (
            <Badge
              variant="secondary"
              className="rounded-full bg-muted text-muted-foreground"
            >
              {starting === 0
                ? t.trackMeta.free
                : `${messages.tracks.from} ${t.trackMeta.paid(starting)}`}
            </Badge>
          )}
        </div>

        <div className="mt-5 border-t border-hairline pt-5">
          <div className="mb-2 flex items-center justify-between text-xs text-muted-foreground">
            <span>{t.progressLabel(track.percent)}</span>
            <span>
              {t.chaptersLabel(track.completedCount, track.totalChapters)}
            </span>
          </div>
          <ProgressBar percent={track.percent} />

          {resumeChapter ? (
            <div className="mt-4 flex flex-wrap gap-3">
              <Button asChild className="h-10 px-4">
                <Link
                  href={`/app/parcours/${track.slug}/chapitres/${resumeChapter.slug}`}
                >
                  {track.completedCount > 0
                    ? t.resumeLabel(resumeChapter.title)
                    : t.start}
                  <ArrowRightIcon aria-hidden />
                </Link>
              </Button>
            </div>
          ) : null}
        </div>
      </header>

      {notice === "paiement" ? (
        <div className="mt-4">
          <Notice tone="success">{pay.success}</Notice>
        </div>
      ) : null}

      {pricing
        ? (() => {
            const lockedLevels = levelOrder.filter(
              (level) =>
                !pricing.access[level] && pricing.prices[level] !== undefined,
            );
            if (lockedLevels.length === 0) return null;

            return (
              <div className="mt-4 rounded-2xl border border-electric/30 bg-electric/[0.04] p-4 sm:p-5">
                <div className="flex items-center gap-2 text-sm font-semibold text-electric">
                  <CreditCardIcon className="size-4" aria-hidden />
                  {pay.bannerTitle}
                </div>
                <p className="mt-1 max-w-[70ch] text-xs leading-relaxed text-muted-foreground">
                  {pay.bannerNotice}
                </p>
                <ul className="mt-3 flex flex-wrap gap-2">
                  {lockedLevels.map((level) => (
                    <li key={level}>
                      <Button
                        asChild
                        className="h-9 rounded-full px-4 text-xs"
                      >
                        <Link
                          href={`/app/acheter?cat=${track.categoryId}&level=${level}`}
                        >
                          {messages.common.levels[level]} ·{" "}
                          {pricing.prices[level]} CDF
                          <ArrowRightIcon aria-hidden />
                        </Link>
                      </Button>
                    </li>
                  ))}
                </ul>
              </div>
            );
          })()
        : null}

      <div className="mt-8 space-y-8">
        {levelOrder.map((level) => (
          <section key={level}>
            <div className="flex items-center gap-3">
              <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                {messages.common.levels[level]}
              </h2>
              <span className="h-px flex-1 bg-hairline" />
            </div>

            <ol className="mt-3 space-y-2">
              {track.chapters
                .filter((chapter) => chapter.level === level)
                .map((chapter) => {
                  const position = chapterNumbers.get(chapter.id) ?? 0;
                  const completed = chapter.progress?.completed ?? false;
                  const current =
                    !completed && chapter.slug === track.nextChapterSlug;

                  if (!chapter.unlocked || chapter.levelLocked || chapter.examLocked) {
                    const levelLock = chapter.levelLocked;
                    const examLock = chapter.examLocked;
                    const levelIndex = levelOrder.indexOf(chapter.level);
                    const previousLevel =
                      levelIndex > 0 ? levelOrder[levelIndex - 1] : null;
                    return (
                      <li key={chapter.id}>
                        <div className="flex items-center gap-4 rounded-xl border border-hairline/70 bg-card/60 p-4 opacity-75">
                          <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-muted text-muted-foreground">
                            <LockIcon className="size-4" aria-hidden />
                          </span>
                          <span className="min-w-0 flex-1">
                            <span className="flex flex-wrap items-center gap-2">
                              <span className="text-sm font-semibold text-muted-foreground">
                                {chapter.title}
                              </span>
                              <span className="rounded-full bg-muted px-2 py-0.5 text-[11px] font-medium text-muted-foreground">
                                {t.status.locked}
                              </span>
                            </span>
                            <span className="mt-1 block text-xs leading-relaxed text-muted-foreground">
                              {levelLock
                                ? messages.common.levels[chapter.level]
                                : examLock
                                  ? t.examNextLockedNotice
                                  : t.lockedNotice}
                            </span>
                          </span>
                          {levelLock ? (
                            <Button
                              asChild
                              variant="outline"
                              className="h-8 shrink-0 rounded-full border-electric/40 px-3 text-xs text-electric hover:bg-electric/10 hover:text-electric"
                            >
                              <Link
                                href={`/app/acheter?cat=${track.categoryId}&level=${chapter.level}`}
                              >
                                {pay.unlockCta}
                              </Link>
                            </Button>
                          ) : examLock && previousLevel ? (
                            <Button
                              asChild
                              variant="outline"
                              className="h-8 shrink-0 rounded-full border-electric/40 px-3 text-xs text-electric hover:bg-electric/10 hover:text-electric"
                            >
                              <Link
                                href={`/app/parcours/${track.slug}/niveaux/${previousLevel}/examen`}
                              >
                                {t.examCta}
                              </Link>
                            </Button>
                          ) : null}
                        </div>
                      </li>
                    );
                  }

                  return (
                    <li key={chapter.id}>
                      <Link
                        href={`/app/parcours/${track.slug}/chapitres/${chapter.slug}`}
                        className={cn(
                          "group flex items-center gap-4 rounded-xl border p-4 transition-colors",
                          current
                            ? "border-electric/50 bg-electric/[0.04]"
                            : "border-hairline bg-card hover:border-electric/50",
                        )}
                      >
                        <span
                          className={cn(
                            "grid size-9 shrink-0 place-items-center rounded-xl text-sm font-semibold tabular-nums",
                            completed
                              ? "bg-emerald-500/12 text-emerald-600 dark:text-emerald-400"
                              : current
                                ? "bg-electric text-primary-foreground"
                                : "bg-muted text-muted-foreground",
                          )}
                        >
                          {completed ? (
                            <CheckCircle2Icon className="size-5" aria-hidden />
                          ) : (
                            position
                          )}
                        </span>

                        <span className="min-w-0 flex-1">
                          <span className="flex flex-wrap items-center gap-2">
                            <span className="text-sm font-semibold text-foreground group-hover:text-electric">
                              {chapter.title}
                            </span>
                            <span
                              className={cn(
                                "rounded-full px-2 py-0.5 text-[11px] font-medium",
                                completed
                                  ? "bg-emerald-500/12 text-emerald-600 dark:text-emerald-400"
                                  : current
                                    ? "bg-electric/12 text-electric"
                                    : "bg-muted text-muted-foreground",
                              )}
                            >
                              {completed
                                ? t.status.completed
                                : current
                                  ? t.status.current
                                  : t.status.available}
                            </span>
                          </span>
                          <span className="mt-1 block text-xs leading-relaxed text-muted-foreground">
                            {chapter.summary}
                          </span>
                          {chapter.progress &&
                          chapter.progress.bestScore !== null ? (
                            <span className="mt-1.5 block text-xs text-muted-foreground">
                              {t.quizBest(chapter.progress.bestScore)} ·{" "}
                              {t.quizAttempts(chapter.progress.attempts)}
                            </span>
                          ) : null}
                        </span>

                        <ChevronRightIcon
                          className="size-4 shrink-0 text-muted-foreground transition-colors group-hover:text-electric"
                          aria-hidden
                        />
                      </Link>
                    </li>
                  );
                })}
            </ol>

            {(() => {
              const info = track.levels.find((item) => item.level === level);
              if (!info) return null;

              const examHref = `/app/parcours/${track.slug}/niveaux/${level}/examen`;
              const passed = info.exam.status === "passed";

              if (passed) {
                return (
                  <div className="mt-3 rounded-xl border border-emerald-500/40 bg-emerald-500/10 p-4">
                    <div className="flex flex-wrap items-center gap-3">
                      <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-emerald-500/15 text-emerald-600 dark:text-emerald-400">
                        <AwardIcon className="size-4" aria-hidden />
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="flex flex-wrap items-center gap-2">
                          <span className="text-sm font-semibold text-foreground">
                            {t.examTitle}
                          </span>
                          <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 text-[11px] font-medium text-emerald-700 dark:text-emerald-400">
                            {t.examPassedBadge}
                          </span>
                        </span>
                        <span className="mt-1 block text-xs leading-relaxed text-muted-foreground">
                          {t.examPassed(info.exam.bestScore ?? 0)} ·{" "}
                          {t.examCertificateNotice}
                        </span>
                      </span>
                      <Button
                        asChild
                        variant="outline"
                        className="h-8 shrink-0 rounded-full px-3 text-xs"
                      >
                        <Link href={examHref}>{t.examRetake}</Link>
                      </Button>
                    </div>
                  </div>
                );
              }

              if (info.allCompleted) {
                return (
                  <div className="mt-3 rounded-xl border border-electric/40 bg-electric/[0.05] p-4">
                    <div className="flex flex-wrap items-center gap-3">
                      <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-electric/15 text-electric">
                        <AwardIcon className="size-4" aria-hidden />
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block text-sm font-semibold text-foreground">
                          {t.examTitle}
                        </span>
                        <span className="mt-1 block text-xs leading-relaxed text-muted-foreground">
                          {t.examIntro(track.passingScore, 10)}
                        </span>
                      </span>
                      <Button
                        asChild
                        className="h-9 shrink-0 rounded-full px-4 text-xs"
                      >
                        <Link href={examHref}>{t.examCta}</Link>
                      </Button>
                    </div>
                  </div>
                );
              }

              return (
                <div className="mt-3 flex items-center gap-3 rounded-xl border border-hairline bg-card/60 p-4">
                  <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-muted text-muted-foreground">
                    <AwardIcon className="size-4" aria-hidden />
                  </span>
                  <p className="min-w-0 flex-1 text-xs leading-relaxed text-muted-foreground">
                    {t.examProgressHint(
                      info.completedChapters,
                      info.totalChapters,
                    )}
                  </p>
                </div>
              );
            })()}
          </section>
        ))}
      </div>
    </div>

    <LevelUpNotification
      currentLevel={track.level}
      ctaHref={
        resumeChapter
          ? `/app/parcours/${track.slug}/chapitres/${resumeChapter.slug}`
          : `/app/parcours/${track.slug}`
      }
    />
    </>
  );
}
