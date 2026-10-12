import type { Metadata } from "next";
import type { ReactNode } from "react";
import Link from "next/link";
import {
  ArrowLeftIcon,
  ArrowRightIcon,
  CheckIcon,
  EyeIcon,
  LockIcon,
} from "lucide-react";
import { notFound } from "next/navigation";

import { LessonBody } from "@/components/learning/lesson-body";
import { LevelUpNotification } from "@/components/learning/level-up-banner";
import { LessonEditor } from "@/components/learning/lesson-editor";
import { PageResume } from "@/components/learning/page-resume";
import { ResourceLink } from "@/components/learning/resource-viewer";
import { PracticePanel } from "@/components/practice/practice-panel";
import { TutorialPlayer } from "@/components/learning/tutorial-player";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { getLearnerChapter } from "@/lib/learning/queries";
import {
  chapterStepOrder,
  stepBlockedByVideos,
} from "@/lib/learning/steps-order";
import {
  getPracticeTool,
  practiceToolHasContent,
} from "@/lib/practice/queries";

const t = messages.learner;

export const metadata: Metadata = {
  title: t.lesson,
  robots: { index: false },
};

type StepKey = "objectifs" | "videos" | "cours" | "exercice" | "ressources";

function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
      {children}
    </p>
  );
}

export default async function ChapterPage({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string; chapterSlug: string }>;
  searchParams: Promise<{ etape?: string; page?: string }>;
}) {
  const { slug, chapterSlug } = await params;
  const { etape, page } = await searchParams;
  const chapter = await getLearnerChapter(slug, chapterSlug);
  if (!chapter) notFound();

  const practiceTool = await getPracticeTool(chapter.categoryId);
  const showPracticeTool =
    !!practiceTool &&
    practiceToolHasContent(
      practiceTool,
      chapter.starterCode,
      chapter.solutionCode,
    );

  const trackHref = `/app/parcours/${chapter.trackSlug}`;
  const chapterHref = `${trackHref}/chapitres/${chapter.slug}`;
  const quizHref = `${chapterHref}/quiz`;

  if (!chapter.unlocked) {
    return (
      <div className="rounded-2xl border border-hairline bg-card p-6 text-center sm:p-8">
        <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-muted text-muted-foreground">
          <LockIcon className="size-6" aria-hidden />
        </span>
        <h1 className="mt-4 text-xl font-semibold text-foreground">
          {t.chapterLockedTitle}
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
          {t.lockedNotice}
        </p>
        <Button asChild className="mt-6 h-10 px-4">
          <Link href={trackHref}>{t.backToTrack}</Link>
        </Button>
      </div>
    );
  }

  if (chapter.levelLocked) {
    return (
      <div className="rounded-2xl border border-hairline bg-card p-6 text-center sm:p-8">
        <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-electric/10 text-electric">
          <LockIcon className="size-6" aria-hidden />
        </span>
        <p className="mt-4 text-xs font-semibold uppercase tracking-wider text-electric">
          {messages.common.levels[chapter.level]}
        </p>
        <h1 className="mt-1 text-xl font-semibold text-foreground">
          {t.levelLockedTitle}
        </h1>
        <p className="mx-auto mt-3 max-w-[52ch] text-sm leading-relaxed text-muted-foreground">
          {t.levelLockedNotice}
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          <Button asChild className="h-10 px-4">
            <Link
              href={`/app/acheter?cat=${chapter.categoryId}&level=${chapter.level}`}
            >
              {messages.payment.unlockCta}
              <ArrowRightIcon aria-hidden />
            </Link>
          </Button>
          <Button asChild variant="outline" className="h-10 px-4">
            <Link href={trackHref}>{t.backToTrack}</Link>
          </Button>
        </div>
      </div>
    );
  }

  if (chapter.examLocked) {
    return (
      <div className="rounded-2xl border border-hairline bg-card p-6 text-center sm:p-8">
        <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-muted text-muted-foreground">
          <LockIcon className="size-6" aria-hidden />
        </span>
        <p className="mt-4 text-xs font-semibold uppercase tracking-wider text-electric">
          {messages.common.levels[chapter.level]}
        </p>
        <h1 className="mt-1 text-xl font-semibold text-foreground">
          {t.examLockedTitle}
        </h1>
        <p className="mx-auto mt-3 max-w-[52ch] text-sm leading-relaxed text-muted-foreground">
          {t.examNextLockedNotice}
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          {chapter.examHref ? (
            <Button asChild className="h-10 px-4">
              <Link href={chapter.examHref}>
                {t.examCta}
                <ArrowRightIcon aria-hidden />
              </Link>
            </Button>
          ) : null}
          <Button asChild variant="outline" className="h-10 px-4">
            <Link href={trackHref}>{t.backToTrack}</Link>
          </Button>
        </div>
      </div>
    );
  }

  const hasVideos = chapter.videos.length > 0;
  const videosBlocked = hasVideos && !chapter.videosDone;
  const stepKeys = chapterStepOrder(hasVideos) as StepKey[];

  const requested = (stepKeys as string[]).includes(etape ?? "")
    ? (etape as StepKey)
    : stepKeys[0];
  const current: StepKey = stepBlockedByVideos(
    requested,
    stepKeys,
    videosBlocked,
  )
    ? "videos"
    : requested;
  const forcedVideos = current !== requested;
  const currentIndex = stepKeys.indexOf(current);

  const navSteps: { key: StepKey | "quiz"; href: string }[] = [
    ...stepKeys.map((key) => ({ key, href: `${chapterHref}?etape=${key}` })),
    { key: "quiz", href: quizHref },
  ];

  const prevStep = currentIndex > 0 ? navSteps[currentIndex - 1] : null;
  const nextStep =
    currentIndex < stepKeys.length - 1
      ? navSteps[currentIndex + 1]
      : navSteps[navSteps.length - 1];

  // Pages numérotées du Cours (organisation type Cisco NetAcad).
  const pages = chapter.pages;
  const pageCount = pages.length;
  const requestedPage = Number.parseInt(page ?? "", 10);
  const pageNo =
    pageCount > 0
      ? Math.min(
          Math.max(Number.isFinite(requestedPage) ? requestedPage : 1, 1),
          pageCount,
        )
      : 0;
  const currentPage = pageCount > 0 ? pages[pageNo - 1] : null;
  const coursStepNumber = stepKeys.indexOf("cours") + 1;
  const pageCode = `${chapter.position}.${coursStepNumber}.${pageNo}`;

  const onPagedCours = current === "cours" && currentPage !== null;
  const prevIsPage = onPagedCours && pageNo > 1;
  const nextIsPage = onPagedCours && pageNo < pageCount;
  const prevHref = prevIsPage
    ? `${chapterHref}?etape=cours&page=${pageNo - 1}`
    : (prevStep?.href ?? "");
  const nextHref = nextIsPage
    ? `${chapterHref}?etape=cours&page=${pageNo + 1}`
    : nextStep.href;

  return (
    <>
    <div className="space-y-4">
      <header>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <Button
            asChild
            variant="ghost"
            className="-ml-2 -mt-1 h-8 px-2 text-xs text-muted-foreground"
          >
            <Link href={trackHref}>
              <ArrowLeftIcon aria-hidden />
              {t.backToTrack}
            </Link>
          </Button>
        </div>

        <h1 className="mt-2 text-2xl font-semibold tracking-tight text-foreground">
          {chapter.title}
        </h1>
        <p className="mt-1.5 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
          {chapter.summary}
        </p>
      </header>

      <article>
        <div className="pb-4">
          {current === "videos" ? (
            <section>
              <SectionLabel>{t.stepLabels.videos}</SectionLabel>
              {forcedVideos ? (
                <p className="mt-3 text-sm font-medium leading-relaxed text-electric">
                  {t.videosRequiredNotice}
                </p>
              ) : null}
              <div className="mt-3">
                <TutorialPlayer
                  chapterId={chapter.id}
                  chapterPosition={chapter.position}
                  videos={chapter.videos}
                  initialWatched={chapter.videoWatched}
                  documentHref={`${chapterHref}?etape=cours`}
                />
              </div>
            </section>
          ) : null}

          {current === "objectifs" ? (
            <section>
              <SectionLabel>{t.objectives}</SectionLabel>
              <ul className="mt-3 grid gap-x-6 gap-y-2.5 sm:grid-cols-2">
                {chapter.objectives.map((objective) => (
                  <li
                    key={objective}
                    className="flex items-start gap-2.5 text-sm leading-6 text-foreground/85"
                  >
                    <CheckIcon
                      className="mt-1 size-4 shrink-0 text-vivid"
                      aria-hidden
                    />
                    <span>{objective}</span>
                  </li>
                ))}
              </ul>
            </section>
          ) : null}

          {current === "cours" ? (
            <section>
              <SectionLabel>{t.lesson}</SectionLabel>
              {currentPage ? (
                <>
                  <div className="mt-3 flex items-baseline justify-between gap-3">
                    <span className="text-sm font-semibold tabular-nums text-electric">
                      {pageCode}
                    </span>
                    <span className="text-xs tabular-nums text-muted-foreground">
                      {t.pageOf(pageNo, pageCount)}
                    </span>
                  </div>
                  <h2 className="mt-1 text-xl font-semibold text-foreground">
                    {currentPage.title}
                  </h2>
                  <LessonBody content={currentPage.content} className="mt-3" />
                  <PageResume
                    trackSlug={chapter.trackSlug}
                    chapterSlug={chapter.slug}
                    total={pageCount}
                  />
                </>
              ) : (
                <LessonBody content={chapter.content} className="mt-3" />
              )}
              {chapter.codeLanguage &&
              chapter.starterCode.trim().length > 0 ? (
                <LessonEditor
                  language={chapter.codeLanguage}
                  code={chapter.starterCode}
                />
              ) : null}
            </section>
          ) : null}

          {current === "exercice" ? (
            <section>
              <SectionLabel>{t.exercise}</SectionLabel>
              {chapter.exercise ? (
                <p className="mt-3 max-w-[68ch] text-[15px] leading-7 text-foreground/85">
                  {chapter.exercise}
                </p>
              ) : (
                <p className="mt-3 max-w-[68ch] text-sm leading-relaxed text-muted-foreground">
                  {t.exerciseEmpty}
                </p>
              )}

              {showPracticeTool && practiceTool ? (
                <PracticePanel
                  tool={practiceTool}
                  chapterId={chapter.id}
                  language={chapter.codeLanguage}
                  starterCode={chapter.starterCode}
                  solutionCode={chapter.solutionCode}
                  initialDone={chapter.practice.done}
                  initialSolutionViewed={chapter.practice.solutionViewed}
                />
              ) : null}
            </section>
          ) : null}

          {current === "ressources" ? (
            <section>
              <SectionLabel>{t.resources}</SectionLabel>
              {chapter.resources.length > 0 ? (
                <ul className="mt-3 grid gap-1">
                  {chapter.resources.map((resource) => (
                    <li key={resource.url}>
                      <ResourceLink
                        label={resource.label}
                        url={resource.url}
                        className="group flex w-full items-center justify-between gap-3 rounded-lg px-2 -mx-2 py-2 text-left text-sm text-foreground transition-colors hover:bg-muted/70"
                      >
                        <span className="min-w-0 truncate">
                          {resource.label}
                        </span>
                        <EyeIcon
                          className="size-4 shrink-0 text-muted-foreground transition-colors group-hover:text-electric"
                          aria-hidden
                        />
                      </ResourceLink>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="mt-3 text-sm text-muted-foreground">
                  {t.player.resourcesEmpty}
                </p>
              )}
            </section>
          ) : null}
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-hairline py-4">
          <div className="flex items-center gap-3">
            {prevStep || prevIsPage ? (
              <Button
                asChild
                variant="outline"
                className="h-9 border-hairline px-4"
              >
                <Link href={prevHref}>
                  <ArrowLeftIcon aria-hidden />
                  {prevIsPage ? t.previousPage : t.previousStep}
                </Link>
              </Button>
            ) : (
              <Button
                variant="outline"
                disabled
                className="h-9 border-hairline px-4"
              >
                <ArrowLeftIcon aria-hidden />
                {t.previousStep}
              </Button>
            )}
            <span className="hidden text-xs tabular-nums text-muted-foreground sm:inline">
              {onPagedCours
                ? `${pageCode} · ${t.pageOf(pageNo, pageCount)}`
                : t.stepOf(currentIndex + 1, stepKeys.length)}
            </span>
          </div>

          {current === "videos" && videosBlocked ? (
            <Button disabled className="h-9 px-5">
              {t.nextStep}
              <ArrowRightIcon aria-hidden />
            </Button>
          ) : nextIsPage ? (
            <Button asChild className="h-9 px-5">
              <Link href={nextHref}>
                {t.nextPage}
                <ArrowRightIcon aria-hidden />
              </Link>
            </Button>
          ) : (
            <Button asChild className="h-9 px-5">
              <Link href={nextHref}>
                {currentIndex === stepKeys.length - 1
                  ? t.readQuiz
                  : t.nextStep}
                <ArrowRightIcon aria-hidden />
              </Link>
            </Button>
          )}
        </div>
      </article>
    </div>

    <LevelUpNotification
      currentLevel={chapter.level}
      ctaHref={nextHref || trackHref}
    />
    </>
  );
}
