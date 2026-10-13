import type { Metadata } from "next";
import type { ReactNode } from "react";
import Link from "next/link";
import { ArrowRightIcon, TargetIcon } from "lucide-react";

import { ProgressBar } from "@/components/learning/progress-bar";
import { LevelUpsellCard } from "@/components/learning/level-upsell-card";
import { LevelUpNotification } from "@/components/learning/level-up-banner";
import { TrackCarousel } from "@/components/learning/track-carousel";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import type {
  ChapterProgress,
  LearnerChapter,
  LearnerTrack,
} from "@/lib/learning/types";
import { getLearnerTracks } from "@/lib/learning/queries";
import { cn } from "@/lib/utils";

const t = messages.learner;

export const metadata: Metadata = {
  title: t.dashboardTitle,
  robots: { index: false },
};

function SectionTitle({
  children,
  meta,
}: {
  children: ReactNode;
  meta?: string;
}) {
  return (
    <div className="flex items-center gap-3">
      <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
        {children}
      </h2>
      <span className="h-px flex-1 bg-hairline" />
      {meta ? (
        <span className="text-xs tabular-nums text-muted-foreground">
          {meta}
        </span>
      ) : null}
    </div>
  );
}

function StatRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 text-xs">
      <span className="shrink-0 text-muted-foreground">{label}</span>
      <span className="min-w-0 truncate font-semibold tabular-nums text-foreground">
        {value}
      </span>
    </div>
  );
}

export default async function DashboardPage() {
  const user = await requireUser(links.dashboard);
  const tracks = await getLearnerTracks();

  const metadataName =
    typeof user.user_metadata?.full_name === "string"
      ? user.user_metadata.full_name.trim()
      : "";
  const name = metadataName || user.email?.split("@")[0] || "";
  const initials = (name || user.email || "?").trim().slice(0, 1).toUpperCase();

  const totalChapters = tracks.reduce((sum, track) => sum + track.totalChapters, 0);
  const completedChapters = tracks.reduce(
    (sum, track) => sum + track.completedCount,
    0,
  );
  const globalPercent =
    totalChapters === 0
      ? 0
      : Math.round((completedChapters / totalChapters) * 100);

  const pending: { track: LearnerTrack; chapter: LearnerChapter }[] = [];
  for (const track of tracks) {
    const chapter = track.chapters.find(
      (item) =>
        item.slug === track.nextChapterSlug &&
        !(item.progress?.completed ?? false),
    );
    if (chapter) pending.push({ track, chapter });
  }

  const attempted: {
    track: LearnerTrack;
    chapter: LearnerChapter;
    progress: ChapterProgress;
  }[] = [];
  for (const track of tracks) {
    for (const chapter of track.chapters) {
      if (chapter.progress && chapter.progress.attempts > 0) {
        attempted.push({ track, chapter, progress: chapter.progress });
      }
    }
  }

  const averageScore =
    attempted.length === 0
      ? null
      : Math.round(
          attempted.reduce(
            (sum, item) => sum + (item.progress.bestScore ?? 0),
            0,
          ) / attempted.length,
        );

  const primary = pending[0] ?? null;
  const isFirstRun =
    tracks.length > 0 && completedChapters === 0 && attempted.length === 0;

  return (
    <>
    <div className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:py-10">
      {/* Ligne 1 : Bienvenue | Carousel parcours */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-[minmax(0,0.5fr)_minmax(0,1.5fr)] lg:gap-6">
        {/* Petite card Bienvenue */}
        <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
          <div className="flex items-center gap-3">
            <span className="grid size-11 shrink-0 place-items-center rounded-full bg-electric/12 text-base font-semibold text-electric">
              {initials}
            </span>
            <div className="min-w-0">
              <p className="truncate text-base font-semibold text-foreground">
                {t.welcome(name)}
              </p>
              <p className="truncate text-xs text-muted-foreground">
                {user.email ?? ""}
              </p>
            </div>
          </div>

          <div className="mt-5">
            <div className="flex items-end justify-between gap-3">
              <span className="text-4xl font-bold leading-none tabular-nums text-foreground">
                {globalPercent} %
              </span>
              <span className="text-xs text-muted-foreground">
                {t.progressTotal(completedChapters, totalChapters)}
              </span>
            </div>
            <div className="mt-3">
              <ProgressBar percent={globalPercent} />
            </div>
          </div>

          <div className="mt-5 space-y-2.5 border-t border-hairline pt-4">
            <StatRow
              label={t.metricChapters}
              value={`${completedChapters}/${totalChapters}`}
            />
            <StatRow label={t.metricQuizzes} value={String(attempted.length)} />
            <StatRow
              label={t.metricAverage}
              value={averageScore === null ? t.noScore : `${averageScore} %`}
            />
            <StatRow
              label={t.metricBest}
              value={
                attempted.length > 0
                  ? `${Math.max(...attempted.map((a) => a.progress.bestScore ?? 0))} %`
                  : t.noScore
              }
            />
          </div>

          <div className="mt-5 rounded-xl border border-electric/30 bg-electric/[0.05] p-4">
            <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-electric">
              <TargetIcon className="size-4" aria-hidden />
              {t.todoTitle}
            </div>
            {primary ? (
              <div className="mt-2.5">
                <p className="text-[11px] text-muted-foreground">
                  {primary.track.title} ·{" "}
                  {messages.common.levels[primary.chapter.level]}
                </p>
                <p className="mt-0.5 truncate text-sm font-semibold text-foreground">
                  {primary.chapter.title}
                </p>
                <Button asChild className="mt-3 h-9 w-full px-4">
                  <Link
                    href={`/app/parcours/${primary.track.slug}/chapitres/${primary.chapter.slug}`}
                  >
                    {primary.chapter.progress ? t.resume : t.start}
                    <ArrowRightIcon aria-hidden />
                  </Link>
                </Button>
              </div>
            ) : tracks.length === 0 ? (
              <div className="mt-2.5">
                <p className="text-xs text-muted-foreground">{t.tracksEmpty}</p>
                <Button asChild className="mt-3 h-9 w-full px-4">
                  <Link href="/catalogue">
                    {t.tracksEmptyCta}
                    <ArrowRightIcon aria-hidden />
                  </Link>
                </Button>
              </div>
            ) : (
              <p className="mt-2.5 text-xs text-muted-foreground">{t.allDone}</p>
            )}
          </div>
        </section>

        {/* Carousel parcours */}
        <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
          <div className="flex items-end justify-between gap-3">
            <h2 className="text-lg font-semibold tracking-tight text-foreground">
              {t.tracksTitle}
            </h2>
            <span className="shrink-0 text-xs tabular-nums text-muted-foreground">
              {t.chaptersLabel(completedChapters, totalChapters)}
            </span>
          </div>
          <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
            {primary
              ? t.unlockNotice(primary.track.passingScore)
              : tracks.length === 0
                ? t.tracksEmpty
                : t.allDone}
          </p>

          {tracks.length === 0 ? (
            <div className="mt-4 rounded-xl border border-dashed border-hairline p-6 text-center">
              <p className="text-sm text-muted-foreground">{t.tracksEmpty}</p>
              <Button asChild className="mt-3 h-9 px-4">
                <Link href="/catalogue">
                  {t.tracksEmptyCta}
                  <ArrowRightIcon aria-hidden />
                </Link>
              </Button>
            </div>
          ) : (
            <TrackCarousel tracks={tracks} primaryTrackId={primary?.track.id} />
          )}
        </section>
      </div>

      {/* Relais d'achat : l'apprenant a commencé le niveau gratuit, on lui montre
          ce que le niveau payant suivant ouvre vraiment (chapitres et prix en base). */}
      {primary && (completedChapters > 0 || attempted.length > 0) ? (
        <div className="mt-5">
          <LevelUpsellCard
            trackSlug={primary.track.slug}
            categoryId={primary.track.categoryId}
            currentLevel={primary.chapter.level}
          />
        </div>
      ) : null}

      {/* Repère de première visite : le rythme d'un chapitre n'est évident qu'après en avoir fait un. */}
      {isFirstRun ? (
        <section className="mt-5 rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
          <h2 className="text-lg font-semibold tracking-tight text-foreground">
            {t.firstRun.title}
          </h2>
          <p className="mt-1 max-w-3xl text-xs leading-relaxed text-muted-foreground">
            {t.firstRun.intro}
          </p>
          <ol className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {t.firstRun.steps.map((step, index) => (
              <li key={step.name} className="rounded-xl border border-hairline p-3">
                <span className="grid size-6 place-items-center rounded-full bg-electric/12 text-[11px] font-semibold tabular-nums text-electric">
                  {index + 1}
                </span>
                <p className="mt-2 text-sm font-semibold text-foreground">
                  {step.name}
                </p>
                <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
                  {step.detail}
                </p>
              </li>
            ))}
          </ol>
          <p className="mt-4 text-xs leading-relaxed text-muted-foreground">
            {t.firstRun.tip}
          </p>
        </section>
      ) : null}

      {/* Ligne 2 : Prochaines étapes + Derniers quiz */}
      <div className="mt-5 grid grid-cols-1 gap-5 md:grid-cols-2">
        <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm">
          <SectionTitle meta={pending.length > 0 ? String(pending.length) : undefined}>
            {t.nextSteps}
          </SectionTitle>

          {pending.length === 0 ? (
            <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
              {tracks.length === 0 ? t.tracksEmpty : t.todoEmpty}
            </p>
          ) : (
            <ul className="mt-2 space-y-0.5">
              {pending.map(({ track, chapter }) => (
                <li key={chapter.id}>
                  <Link
                    href={`/app/parcours/${track.slug}/chapitres/${chapter.slug}`}
                    className="flex items-center gap-2.5 rounded-lg px-2 py-2 transition-colors hover:bg-muted/70"
                  >
                    <span className="grid size-5 shrink-0 place-items-center rounded-full bg-electric/12 text-electric">
                      <span className="text-[10px] font-semibold tabular-nums">
                        {chapter.position}
                      </span>
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-xs font-medium text-foreground">
                        {chapter.title}
                      </span>
                      <span className="block truncate text-[11px] text-muted-foreground">
                        {track.title}
                      </span>
                    </span>
                    <ArrowRightIcon
                      className="size-3.5 shrink-0 text-muted-foreground"
                      aria-hidden
                    />
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm">
          <SectionTitle>{t.recentQuizzes}</SectionTitle>

          {attempted.length === 0 ? (
            <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
              {t.recentEmpty}
            </p>
          ) : (
            <ul className="mt-2 space-y-0.5">
              {attempted.slice(0, 4).map(({ track, chapter, progress }) => {
                const passed = (progress.bestScore ?? 0) >= track.passingScore;
                return (
                  <li key={chapter.id}>
                    <Link
                      href={`/app/parcours/${track.slug}/chapitres/${chapter.slug}`}
                      className="flex items-center gap-3 rounded-lg px-2 py-2 transition-colors hover:bg-muted/70"
                    >
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-xs font-medium text-foreground">
                          {chapter.title}
                        </span>
                        <span className="block text-[11px] text-muted-foreground">
                          {t.quizAttempts(progress.attempts)}
                        </span>
                      </span>
                      <span
                        className={cn(
                          "shrink-0 rounded-full px-2 py-0.5 text-[11px] font-semibold tabular-nums",
                          passed
                            ? "bg-emerald-500/12 text-emerald-600 dark:text-emerald-400"
                            : "bg-amber-500/12 text-amber-600 dark:text-amber-400",
                        )}
                      >
                        {progress.bestScore ?? 0} %
                      </span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          )}
        </section>
      </div>
    </div>

    {!isFirstRun ? (
      <LevelUpNotification
        currentLevel={primary?.chapter.level}
        ctaHref={
          primary
            ? `/app/parcours/${primary.track.slug}/chapitres/${primary.chapter.slug}`
            : links.catalogue
        }
      />
    ) : null}
    </>
  );
}