import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowRightIcon } from "lucide-react";

import { FormationCard } from "@/components/catalog/formation-card";
import { Badge } from "@/components/ui/badge";
import { JsonLd, breadcrumbLd, itemListLd } from "@/components/seo/json-ld";
import { levelTone } from "@/components/catalog/level-tone";
import { messages } from "@/i18n";
import { getSeoCategoryChapters } from "@/lib/catalog/seo";
import { getCategories, getTracks } from "@/lib/catalog/queries";
import { domainPageDescription, domainPageTitle, seoFor } from "@/config/seo";

const t = messages;

export const revalidate = 3600;

export function generateStaticParams() {
  return getCategories().then((categories) =>
    categories.map((category) => ({ slug: category.slug })),
  );
}

async function readDomain(slug: string) {
  const [categories, tracks] = await Promise.all([getCategories(), getTracks()]);
  const category = categories.find((item) => item.slug === slug);
  if (!category) return null;

  const domainTracks = tracks.filter((track) => track.categoryId === category.id);
  return { category, tracks: domainTracks };
}

export async function generateMetadata(
  props: PageProps<"/formations/[slug]">,
): Promise<Metadata> {
  const { slug } = await props.params;
  const domain = await readDomain(slug);

  if (!domain) {
    return { title: t.catalogue.empty.formations, robots: { index: false, follow: true } };
  }

  const keyword = seoFor(domain.category.id, domain.category.name);
  const chapters = domain.tracks.reduce((sum, track) => sum + track.modules, 0);

  return {
    title: domainPageTitle(keyword),
    description: domainPageDescription({
      intro: keyword.intro,
      tracks: domain.tracks.length,
      chapters,
      levelsLabel: domain.category.levels
        .map((level) => t.tracks.levelLabels[level])
        .join(", "),
    }),
    keywords: [keyword.primary, ...keyword.variants, domain.category.name],
    alternates: { canonical: `/formations/${domain.category.slug}` },
    openGraph: {
      type: "website",
      url: `/formations/${domain.category.slug}`,
      title: domainPageTitle(keyword),
      description: domain.category.description,
    },
  };
}

export default async function DomainPage(props: PageProps<"/formations/[slug]">) {
  const { slug } = await props.params;
  const domain = await readDomain(slug);

  if (!domain) notFound();

  const { category, tracks } = domain;
  const keyword = seoFor(category.id, category.name);
  const chaptersCount = tracks.reduce((sum, track) => sum + track.modules, 0);
  const subjects = await getSeoCategoryChapters(category.id, 30);
  const others = (await getCategories()).filter((item) => item.id !== category.id);

  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-10 sm:px-6 lg:py-14">
      <nav aria-label={t.domaine.catalogue} className="text-xs text-muted-foreground">
        <ol className="flex flex-wrap items-center gap-1.5">
          <li>
            <Link href="/" className="transition-colors hover:text-electric">
              {t.domaine.home}
            </Link>
          </li>
          <li aria-hidden>/</li>
          <li>
            <Link href="/catalogue" className="transition-colors hover:text-electric">
              {t.domaine.catalogue}
            </Link>
          </li>
          <li aria-hidden>/</li>
          <li className="text-foreground">{category.name}</li>
        </ol>
      </nav>

      <header className="mt-6 max-w-3xl">
        <p className="text-xs font-semibold uppercase tracking-wider text-electric">
          {category.name}
        </p>
        <h1 className="mt-2 text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
          {domainPageTitle(keyword)}
        </h1>
        <p className="mt-4 text-sm leading-relaxed text-muted-foreground sm:text-base">
          {keyword.intro}
        </p>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground sm:text-base">
          {category.description}
        </p>

        <div className="mt-6 flex flex-wrap items-center gap-2">
          <Badge variant="secondary" className="rounded-full px-2.5 py-0.5 text-[11px]">
            {t.domaine.tracksCount(tracks.length)}
          </Badge>
          <Badge variant="secondary" className="rounded-full px-2.5 py-0.5 text-[11px]">
            {t.domaine.chaptersCount(chaptersCount)}
          </Badge>
          <span className="text-xs text-muted-foreground">
            {t.domaine.levelsLabel} :{" "}
            {category.levels.map((level) => t.tracks.levelLabels[level]).join(", ")}
          </span>
        </div>

        <Link
          href={`/inscription?next=${encodeURIComponent(
            tracks[0]?.slug ? `/app/parcours/${tracks[0].slug}` : "/catalogue",
          )}`}
          className="mt-6 inline-flex h-11 items-center gap-2 rounded-xl bg-electric px-5 text-sm font-semibold text-primary-foreground shadow-lg shadow-electric/25 transition-opacity hover:opacity-90"
        >
          {t.domaine.cta}
          <ArrowRightIcon className="size-4" aria-hidden />
        </Link>
      </header>

      <section className="mt-12">
        <h2 className="text-lg font-semibold sm:text-xl">{t.domaine.tracksTitle}</h2>

        {tracks.length === 0 ? (
          <p className="mt-4 rounded-2xl border border-dashed border-hairline bg-card/50 px-5 py-10 text-center text-sm text-muted-foreground">
            {t.catalogue.empty.formations}
          </p>
        ) : (
          <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {tracks.map((track) => (
              <FormationCard key={track.slug} track={track} />
            ))}
          </div>
        )}
      </section>

      {subjects.length > 0 ? (
        <section className="mt-12">
          <h2 className="text-lg font-semibold sm:text-xl">{t.domaine.subjectsTitle}</h2>
          <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
            {t.domaine.subjectsIntro(category.name)}
          </p>
          <ul className="mt-5 grid gap-2 sm:grid-cols-2">
            {subjects.map((subject) => (
              <li key={subject.slug}>
                <Link
                  href={`/parcours/${subject.trackSlug}`}
                  className="group flex items-start justify-between gap-3 rounded-xl border border-hairline bg-card px-4 py-3 transition-colors hover:border-electric/50"
                >
                  <span className="min-w-0">
                    <span className="block truncate text-sm font-medium text-foreground">
                      {subject.title}
                    </span>
                    <span className="mt-0.5 block truncate text-[11px] text-muted-foreground">
                      {subject.trackTitle}
                    </span>
                  </span>
                  <Badge
                    className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-medium ${levelTone[subject.level]}`}
                    variant="secondary"
                  >
                    {t.tracks.levelLabels[subject.level]}
                  </Badge>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {others.length > 0 ? (
        <section className="mt-12">
          <h2 className="text-lg font-semibold sm:text-xl">{t.domaine.otherDomains}</h2>
          <ul className="mt-4 flex flex-wrap gap-2">
            {others.map((item) => (
              <li key={item.id}>
                <Link
                  href={`/formations/${item.slug}`}
                  className="inline-flex h-9 items-center rounded-full border border-hairline bg-card px-4 text-sm text-foreground transition-colors hover:border-electric/50 hover:text-electric"
                >
                  {item.name}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      <JsonLd
        data={[
          itemListLd(
            tracks.map((track) => ({
              name: track.title,
              path: `/parcours/${track.slug}`,
              description: track.bestFor,
            })),
            `${category.name} — ${t.domaine.tracksTitle}`,
          ),
          breadcrumbLd([
            { name: t.domaine.home, path: "/" },
            { name: t.domaine.catalogue, path: "/catalogue" },
            { name: category.name, path: `/formations/${category.slug}` },
          ]),
        ]}
      />
    </div>
  );
}
