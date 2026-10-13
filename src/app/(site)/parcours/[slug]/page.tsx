import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  ArrowRightIcon,
  CheckIcon,
  ClockIcon,
  LayersIcon,
  ListChecksIcon,
  ShieldCheckIcon,
} from "lucide-react";

import { levelTone } from "@/components/catalog/level-tone";
import { Badge } from "@/components/ui/badge";
import { JsonLd, breadcrumbLd, courseLd } from "@/components/seo/json-ld";
import { levels, type LevelType } from "@/config/catalog";
import { messages } from "@/i18n";
import { getSeoTrack, getSeoTracks } from "@/lib/catalog/seo";
import { getStartingPrices } from "@/lib/catalog/queries";
import {
  seoFor,
  trackPageDescription,
  trackPageTitle,
} from "@/config/seo";

const t = messages;

export const revalidate = 3600;

function priceLabel(price: number | null | undefined) {
  if (price === null || price === undefined) return null;
  return price === 0 ? t.tracks.badges.free : t.tracks.badges.price(price);
}

function levelsCovered(chapters: { level: LevelType }[], fallback: LevelType) {
  const covered = levels.filter((level) => chapters.some((chapter) => chapter.level === level));
  return covered.length > 0 ? covered : [fallback];
}

export function generateStaticParams() {
  return getSeoTracks().then((tracks) =>
    tracks.map((track) => ({ slug: track.slug })),
  );
}

export async function generateMetadata(
  props: PageProps<"/parcours/[slug]">,
): Promise<Metadata> {
  const { slug } = await props.params;
  const track = await getSeoTrack(slug);

  if (!track) {
    return { title: t.catalogue.empty.formations, robots: { index: false, follow: true } };
  }

  const keyword = seoFor(track.categoryId, track.category);
  const covered = levelsCovered(track.chapters, track.levelFrom);
  const prices = await getStartingPrices();
  const price = priceLabel(prices.get(track.categoryId));

  return {
    title: trackPageTitle(track.title),
    description: trackPageDescription({
      title: track.title,
      category: track.category,
      chapters: track.chapters.length,
      levelLabel: t.tracks.levelLabels[covered[0] ?? track.levelFrom],
      priceFrom: price ?? "une inscription gratuite",
    }),
    keywords: [keyword.primary, ...keyword.variants, track.title, track.category],
    alternates: { canonical: `/parcours/${track.slug}` },
    openGraph: {
      type: "website",
      url: `/parcours/${track.slug}`,
      title: trackPageTitle(track.title),
      description: track.description,
    },
  };
}

export default async function TrackSheetPage(props: PageProps<"/parcours/[slug]">) {
  const { slug } = await props.params;
  const track = await getSeoTrack(slug);

  if (!track) notFound();

  const keyword = seoFor(track.categoryId, track.category);
  const covered = levelsCovered(track.chapters, track.levelFrom);
  const [prices, allTracks] = await Promise.all([getStartingPrices(), getSeoTracks()]);
  const price = priceLabel(prices.get(track.categoryId));

  const related = allTracks
    .filter((item) => item.categoryId === track.categoryId && item.slug !== track.slug)
    .slice(0, 6);

  const skills = Array.from(
    new Set(track.chapters.flatMap((chapter) => chapter.objectives)),
  ).slice(0, 12);

  const range =
    covered.length > 1
      ? t.fiche.levelFromTo(
          t.tracks.levelLabels[covered[0]],
          t.tracks.levelLabels[covered[covered.length - 1]],
        )
      : t.fiche.levelSingle(t.tracks.levelLabels[covered[0]]);

  // Numérotation continue sur tout le parcours : un chapitre « 7 » reste le
  // septième, même quand il ouvre le niveau Intermédiaire.
  const programmeGroups = (() => {
    let vus = 0;
    return levels
      .map((level) => {
        const chapters = track.chapters.filter((chapter) => chapter.level === level);
        const offset = vus;
        vus += chapters.length;
        return { level, chapters, offset };
      })
      .filter((group) => group.chapters.length > 0);
  })();

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-10 sm:px-6 lg:py-14">
      <nav aria-label={t.fiche.catalogue} className="text-xs text-muted-foreground">
        <ol className="flex flex-wrap items-center gap-1.5">
          <li>
            <Link href="/" className="transition-colors hover:text-electric">
              {t.fiche.home}
            </Link>
          </li>
          <li aria-hidden>/</li>
          <li>
            <Link href="/catalogue" className="transition-colors hover:text-electric">
              {t.fiche.catalogue}
            </Link>
          </li>
          <li aria-hidden>/</li>
          <li>
            <Link
              href={`/formations/${track.categorySlug}`}
              className="transition-colors hover:text-electric"
            >
              {track.category}
            </Link>
          </li>
          <li aria-hidden>/</li>
          <li className="text-foreground">{track.title}</li>
        </ol>
      </nav>

      <header className="mt-6">
        <p className="text-xs font-semibold uppercase tracking-wider text-electric">
          {track.category}
        </p>
        <h1 className="mt-2 text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
          {track.title}
        </h1>
        <p className="mt-4 max-w-[72ch] text-sm leading-relaxed text-muted-foreground sm:text-base">
          {track.description}
        </p>
        <p className="mt-3 max-w-[72ch] text-sm leading-relaxed text-muted-foreground sm:text-base">
          {keyword.intro}
        </p>
      </header>

      <dl className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          {
            icon: LayersIcon,
            term: t.fiche.facts.chapters,
            value: t.catalogue.cards.chapters(track.chapters.length),
          },
          {
            icon: ClockIcon,
            term: t.fiche.facts.duration,
            value: t.tracks.badges.duration(track.durationHours),
          },
          { icon: ListChecksIcon, term: t.fiche.facts.levels, value: range },
          {
            icon: ShieldCheckIcon,
            term: t.fiche.facts.price,
            value: price ?? t.tracks.badges.free,
          },
        ].map((item) => (
          <div
            key={item.term}
            className="rounded-2xl border border-hairline bg-card p-4"
          >
            <dt className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
              <item.icon className="size-3.5 text-electric" aria-hidden />
              {item.term}
            </dt>
            <dd className="mt-2 text-sm font-medium text-foreground">{item.value}</dd>
          </div>
        ))}
      </dl>

      <div className="mt-8 flex flex-wrap items-center gap-3">
        <Link
          href="/inscription"
          className="inline-flex h-11 items-center gap-2 rounded-xl bg-electric px-5 text-sm font-semibold text-primary-foreground shadow-lg shadow-electric/25 transition-opacity hover:opacity-90"
        >
          {t.fiche.ctaStart}
          <ArrowRightIcon className="size-4" aria-hidden />
        </Link>
        <Link
          href="/catalogue"
          className="inline-flex h-11 items-center gap-2 rounded-xl border border-hairline bg-card px-5 text-sm font-medium transition-colors hover:border-electric/50"
        >
          {t.fiche.ctaCompare}
        </Link>
      </div>

      <p className="mt-5 max-w-[72ch] text-sm leading-relaxed text-muted-foreground">
        {price && price !== t.tracks.badges.free
          ? `${t.fiche.freeIntro} ${t.fiche.paidIntro(price)}`
          : t.fiche.freeIntro}
      </p>

      {skills.length > 0 ? (
        <section className="mt-12">
          <h2 className="text-lg font-semibold sm:text-xl">{t.fiche.objectivesTitle}</h2>
          <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
            {t.fiche.objectivesIntro}
          </p>
          <ul className="mt-4 grid gap-2 sm:grid-cols-2">
            {skills.map((skill) => (
              <li
                key={skill}
                className="flex items-start gap-2 text-sm leading-relaxed text-foreground"
              >
                <CheckIcon className="mt-0.5 size-4 shrink-0 text-electric" aria-hidden />
                {skill}
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      <section className="mt-12">
        <h2 className="text-lg font-semibold sm:text-xl">
          {t.fiche.programmeTitle} — {track.title}
        </h2>
        <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
          {t.fiche.programmeIntro(track.chapters.length)}
        </p>

        {track.chapters.length === 0 ? (
          <p className="mt-6 rounded-2xl border border-dashed border-hairline bg-card/50 px-5 py-10 text-center text-sm text-muted-foreground">
            {t.catalogue.empty.formations}
          </p>
        ) : (
          <div className="mt-6 space-y-10">
            {programmeGroups.map((group) => (
                <section key={group.level}>
                  <div className="flex flex-wrap items-center gap-3">
                    <Badge
                      className={`rounded-full px-2 py-0.5 text-[11px] font-medium ${levelTone[group.level]}`}
                      variant="secondary"
                    >
                      {t.tracks.levelLabels[group.level]}
                    </Badge>
                    <h3 className="text-sm font-semibold text-foreground">
                      {t.fiche.levelCount(
                        t.tracks.levelLabels[group.level],
                        group.chapters.length,
                      )}
                    </h3>
                  </div>

                  <ol className="mt-4 space-y-4">
                    {group.chapters.map((chapter, index) => (
                      <li
                        key={chapter.slug}
                        className="rounded-2xl border border-hairline bg-card p-4"
                      >
                        <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                          {t.fiche.chapterIndex(group.offset + index + 1)}
                        </p>
                        <h4 className="mt-1.5 text-base leading-snug font-semibold text-balance">
                          {chapter.title}
                        </h4>
                        {chapter.summary ? (
                          <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                            {chapter.summary}
                          </p>
                        ) : null}
                        {chapter.objectives.length > 0 ? (
                          <ul className="mt-3 space-y-1.5">
                            {chapter.objectives.map((objective) => (
                              <li
                                key={objective}
                                className="flex items-start gap-2 text-xs leading-relaxed text-muted-foreground"
                              >
                                <CheckIcon
                                  className="mt-0.5 size-3.5 shrink-0 text-electric"
                                  aria-hidden
                                />
                                {objective}
                              </li>
                            ))}
                          </ul>
                        ) : null}
                      </li>
                    ))}
                  </ol>
                </section>
              ))}
          </div>
        )}

        <p className="mt-8 max-w-[70ch] rounded-2xl border border-hairline bg-elevated px-5 py-4 text-sm leading-relaxed text-muted-foreground">
          {t.fiche.quizNote}
        </p>
      </section>

      {related.length > 0 ? (
        <section className="mt-12">
          <h2 className="text-lg font-semibold sm:text-xl">{t.fiche.relatedTitle}</h2>
          <ul className="mt-4 grid gap-3 sm:grid-cols-2">
            {related.map((item) => (
              <li key={item.slug}>
                <Link
                  href={`/parcours/${item.slug}`}
                  className="group flex h-full flex-col rounded-2xl border border-hairline bg-card p-4 transition-colors hover:border-electric/50"
                >
                  <span className="text-xs font-medium text-muted-foreground">
                    {t.tracks.levelLabels[item.levelFrom]}
                  </span>
                  <span className="mt-1.5 text-sm leading-snug font-semibold text-balance">
                    {item.title}
                  </span>
                  <span className="mt-2 inline-flex items-center gap-1.5 text-xs font-medium text-electric">
                    {t.tracks.cta}
                    <ArrowRightIcon className="size-3.5 transition-transform group-hover:translate-x-0.5" aria-hidden />
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      <JsonLd
        data={[
          courseLd({
            title: track.title,
            description: `${keyword.primary} : ${track.description}`,
            category: track.category,
            levelLabel: range,
            durationHours: track.durationHours,
            chapterCount: track.chapters.length,
            price: prices.get(track.categoryId) ?? null,
            path: `/parcours/${track.slug}`,
            chapters: track.chapters.slice(0, 30),
          }),
          breadcrumbLd([
            { name: t.fiche.home, path: "/" },
            { name: t.fiche.catalogue, path: "/catalogue" },
            { name: track.category, path: `/formations/${track.categorySlug}` },
            { name: track.title, path: `/parcours/${track.slug}` },
          ]),
        ]}
      />
    </div>
  );
}
