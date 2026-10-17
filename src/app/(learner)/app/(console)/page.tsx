import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowRightIcon,
  AwardIcon,
  CheckCircle2Icon,
  ListChecksIcon,
  TargetIcon,
} from "lucide-react";

import { Carte } from "@/components/admin/carte";
import { Kpi } from "@/components/admin/graphiques";
import { ProgressBar } from "@/components/learning/progress-bar";
import { LevelUpsellCard } from "@/components/learning/level-upsell-card";
import { LevelUpNotification } from "@/components/learning/level-up-banner";
import { TrackCarousel } from "@/components/learning/track-carousel";
import { Badge } from "@/components/ui/badge";
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
import { fill, formatDateTime } from "@/lib/instructor/format";
import {
  getLearnerClasses,
  getUpcomingSessionsForLearner,
} from "@/lib/instructor/queries";
import { createServerSupabase } from "@/lib/supabase/server";
import { cn } from "@/lib/utils";

const t = messages.learner;
const tc = messages.formateur.myClass;
const tl = messages.common.levels;

export const metadata: Metadata = {
  title: t.dashboardTitle,
  robots: { index: false },
};

function niveauDe(chapitre: LearnerChapter): string {
  return tl[chapitre.level] ?? chapitre.level;
}

export default async function DashboardPage() {
  const user = await requireUser(links.dashboard);
  const [tracks, myClasses, liveSoon] = await Promise.all([
    getLearnerTracks(),
    getLearnerClasses(user.id),
    getUpcomingSessionsForLearner(user.id),
  ]);

  const supabase = await createServerSupabase();
  const { count: certificats } = supabase
    ? await supabase
        .from("certificates")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id)
    : { count: 0 };

  const metadataName =
    typeof user.user_metadata?.full_name === "string"
      ? user.user_metadata.full_name.trim()
      : "";
  const name = metadataName || user.email?.split("@")[0] || "";

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
  const repriseHref = primary
    ? `/app/parcours/${primary.track.slug}/chapitres/${primary.chapter.slug}`
    : links.catalogue;
  const isFirstRun =
    tracks.length > 0 && completedChapters === 0 && attempted.length === 0;

  return (
    <>
      <div className="space-y-6">
        <header>
          <h1 className="text-2xl font-semibold tracking-tight text-foreground">
            {t.welcome(name)}
          </h1>
          <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{t.intro}</p>
        </header>

        <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <Kpi
            titre={t.progressTitle}
            valeur={`${globalPercent} %`}
            note={t.progressTotal(completedChapters, totalChapters)}
            Icon={TargetIcon}
          />
          <Kpi
            titre={t.metricChapters}
            valeur={`${completedChapters} / ${totalChapters}`}
            Icon={ListChecksIcon}
          />
          <Kpi
            titre={t.metricQuizzes}
            valeur={String(attempted.length)}
            note={
              averageScore === null
                ? t.noScore
                : `${t.metricAverage} · ${averageScore} %`
            }
            Icon={CheckCircle2Icon}
          />
          <Kpi
            titre={t.profil.certificatesTitle}
            valeur={String(certificats ?? 0)}
            note={t.profil.certificatesNote}
            Icon={AwardIcon}
          />
        </section>

        {/* Le premier geste attendu n'est pas « choisir » mais « reprendre » : un
            apprenant qui revient de deux semaines de coupure doit trouver sa leçon
            sans ouvrir un seul menu. */}
        <Carte
          titre={t.todoTitle}
          intro={primary ? t.unlockNotice(primary.track.passingScore) : undefined}
        >
          {primary ? (
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="min-w-0">
                <p className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                  <span className="truncate">{primary.track.title}</span>
                  <Badge
                    variant="secondary"
                    className="shrink-0 rounded-full bg-electric/12 px-2 py-0.5 text-[11px] font-medium text-electric"
                  >
                    {niveauDe(primary.chapter)}
                  </Badge>
                  <span className="shrink-0 tabular-nums">
                    {t.positionOf(primary.chapter.position, primary.track.totalChapters)}
                  </span>
                </p>
                <p className="mt-1 truncate text-base font-semibold text-foreground">
                  {primary.chapter.title}
                </p>
                <div className="mt-3 max-w-xs">
                  <ProgressBar percent={primary.track.percent} />
                </div>
              </div>
              <Button asChild className="h-11 shrink-0 px-5">
                <Link href={repriseHref}>
                  {primary.chapter.progress ? t.resume : t.start}
                  <ArrowRightIcon aria-hidden />
                </Link>
              </Button>
            </div>
          ) : tracks.length === 0 ? (
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-sm text-muted-foreground">{t.tracksEmpty}</p>
              <Button asChild className="h-11 shrink-0 px-5">
                <Link href={links.catalogue}>
                  {t.tracksEmptyCta}
                  <ArrowRightIcon aria-hidden />
                </Link>
              </Button>
            </div>
          ) : (
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-sm font-medium text-foreground">{t.allDone}</p>
              <Button asChild variant="outline" className="h-11 shrink-0 border-hairline px-5">
                <Link href="/app/profil">
                  {t.profil.certificatesTitle}
                  <ArrowRightIcon aria-hidden />
                </Link>
              </Button>
            </div>
          )}
        </Carte>

        <Carte
          titre={t.tracksTitle}
          intro={t.formations.sortHint}
          lien={{ href: "/app/formations", libelle: t.formations.title }}
        >
          {tracks.length === 0 ? (
            <div className="rounded-xl border border-dashed border-hairline p-6 text-center">
              <p className="text-sm text-muted-foreground">{t.tracksEmpty}</p>
              <Button asChild className="mt-3 h-9 px-4">
                <Link href={links.catalogue}>
                  {t.tracksEmptyCta}
                  <ArrowRightIcon aria-hidden />
                </Link>
              </Button>
            </div>
          ) : (
            <TrackCarousel tracks={tracks} primaryTrackId={primary?.track.id} />
          )}
        </Carte>

        {/* Relais d'achat : l'apprenant a commencé le niveau gratuit, on lui montre
            ce que le niveau payant suivant ouvre vraiment (chapitres et prix en base). */}
        {primary && (completedChapters > 0 || attempted.length > 0) ? (
          <LevelUpsellCard
            trackSlug={primary.track.slug}
            categoryId={primary.track.categoryId}
            currentLevel={primary.chapter.level}
          />
        ) : null}

        {/* Repère de première visite : le rythme d'un chapitre n'est évident qu'après en avoir fait un. */}
        {isFirstRun ? (
          <Carte titre={t.firstRun.title} intro={t.firstRun.intro}>
            <ol className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
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
          </Carte>
        ) : null}

        <div className="grid gap-6 lg:grid-cols-2">
          <Carte
            titre={t.nextSteps}
            lien={
              pending.length > 6
                ? { href: "/app/formations", libelle: t.formations.title }
                : undefined
            }
          >
            {pending.length === 0 ? (
              <p className="text-xs leading-relaxed text-muted-foreground">
                {tracks.length === 0 ? t.tracksEmpty : t.todoEmpty}
              </p>
            ) : (
              <ul className="-mx-2 space-y-0.5">
                {/* Six lignes suffisent pour savoir quoi faire ensuite. Un apprenant
                    qui a souscrit à plusieurs parcours n'a pas à dérouler vingt cartes
                    pour retrouver le sien : la page « Mes formations » les liste. */}
                {pending.slice(0, 6).map(({ track, chapter }) => (
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
          </Carte>

          <Carte titre={t.recentQuizzes}>
            {attempted.length === 0 ? (
              <p className="text-xs leading-relaxed text-muted-foreground">
                {t.recentEmpty}
              </p>
            ) : (
              <ul className="-mx-2 space-y-0.5">
                {attempted.slice(0, 4).map(({ track, chapter, progress }) => {
                  const passe = (progress.bestScore ?? 0) >= track.passingScore;
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
                            passe
                              ? "bg-electric/12 text-electric"
                              : "bg-destructive/12 text-destructive",
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
          </Carte>
        </div>

        {myClasses.length > 0 || liveSoon.length > 0 ? (
          <div className="grid gap-6 lg:grid-cols-2">
            {myClasses.length > 0 ? (
              <Carte
                titre={tc.title}
                lien={{ href: "/app/classe", libelle: messages.nav.seeAll }}
              >
                <ul className="-mx-2 space-y-0.5">
                  {myClasses.slice(0, 3).map((klass) => (
                    <li key={klass.classId}>
                      <Link
                        href={`/app/parcours/${klass.trackSlug}`}
                        className="flex items-center justify-between gap-3 rounded-lg px-2 py-2 transition-colors hover:bg-muted/70"
                      >
                        <span className="min-w-0 truncate text-xs font-medium text-foreground">
                          {klass.title}
                        </span>
                        <span className="shrink-0 text-[11px] text-muted-foreground">
                          {fill(tc.taughtBy, { name: klass.instructorName })}
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              </Carte>
            ) : null}

            {liveSoon.length > 0 ? (
              <Carte titre={messages.live.learner.title}>
                <ul className="-mx-2 space-y-0.5">
                  {liveSoon.map((session) => (
                    <li key={session.id}>
                      <Link
                        href={`/app/live/${session.id}`}
                        className="flex items-center justify-between gap-3 rounded-lg px-2 py-2 transition-colors hover:bg-muted/70"
                      >
                        <span className="min-w-0 truncate text-xs font-medium text-foreground">
                          {session.title}
                        </span>
                        <span className="shrink-0 text-[11px] tabular-nums text-muted-foreground">
                          {formatDateTime(session.startsAt)}
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              </Carte>
            ) : null}
          </div>
        ) : null}
      </div>

      {!isFirstRun ? (
        <LevelUpNotification
          currentLevel={primary?.chapter.level}
          ctaHref={repriseHref}
        />
      ) : null}
    </>
  );
}
