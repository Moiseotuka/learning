import type { Metadata } from "next";

import {
  CatalogSidebar,
  type CatalogType,
} from "@/components/catalog/catalog-sidebar";
import { FormationCard } from "@/components/catalog/formation-card";
import { SearchResults } from "@/components/catalog/search-results";
import { TutorialCard } from "@/components/catalog/tutorial-card";
import { messages } from "@/i18n";
import { getCategories, getTracks, getTutorials } from "@/lib/catalog/queries";
import { searchCatalog } from "@/lib/catalog/search";

const t = messages;

export const metadata: Metadata = {
  title: t.catalogue.title,
  description: t.catalogue.description,
};

function countByCategory(ids: string[], entries: { categoryId: string }[]) {
  const counts: Record<string, number> = {};
  for (const id of ids) counts[id] = 0;
  for (const entry of entries) {
    if (entry.categoryId in counts) counts[entry.categoryId] += 1;
  }
  return counts;
}

function readParam(value: string | string[] | undefined): string {
  if (Array.isArray(value)) return value[0] ?? "";
  return typeof value === "string" ? value : "";
}

export default async function CataloguePage(
  props: PageProps<"/catalogue">,
) {
  const searchParams = await props.searchParams;
  const type: CatalogType =
    readParam(searchParams.type) === "tutoriels" ? "tutoriels" : "formations";
  const techParam = readParam(searchParams.tech);
  const query = readParam(searchParams.q).trim().slice(0, 80);

  const [categories, tracks, tutorials, hits] = await Promise.all([
    getCategories(),
    getTracks(),
    getTutorials(),
    query ? searchCatalog(query) : Promise.resolve([]),
  ]);

  const tech = categories.some((category) => category.id === techParam)
    ? techParam
    : "";

  const formationsCounts = countByCategory(
    categories.map((category) => category.id),
    tracks,
  );
  const tutorielsCounts = countByCategory(
    categories.map((category) => category.id),
    tutorials,
  );

  const matchingHits = tech
    ? hits.filter((hit) => hit.categoryId === tech)
    : hits;

  const visibleTracks = tech
    ? tracks.filter((track) => track.categoryId === tech)
    : tracks;
  const visibleTutorials = tech
    ? tutorials.filter((tutorial) => tutorial.categoryId === tech)
    : tutorials;

  const resultCount =
    type === "tutoriels" ? visibleTutorials.length : visibleTracks.length;

  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-12 sm:px-6 lg:py-16">
      <header className="max-w-3xl">
        <p className="text-xs font-semibold uppercase tracking-wider text-electric">
          {t.catalogue.eyebrow}
        </p>
        <h1 className="mt-2 text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
          {query ? t.catalogue.search.resultsFor(query) : t.catalogue.title}
        </h1>
        <p className="mt-3 max-w-[68ch] text-sm leading-relaxed text-muted-foreground sm:text-base">
          {query ? t.catalogue.search.intro : t.catalogue.description}
        </p>
      </header>

      <div className="mt-10 grid gap-8 lg:grid-cols-[260px_minmax(0,1fr)] lg:gap-10">
        <CatalogSidebar
          activeType={type}
          activeTech={tech}
          activeQuery={query}
          categories={categories.map((category) => ({
            id: category.id,
            name: category.name,
            icon: category.icon,
          }))}
          counts={{ formations: formationsCounts, tutoriels: tutorielsCounts }}
          totals={{ formations: tracks.length, tutoriels: tutorials.length }}
        />

        <section aria-label={query ? t.catalogue.search.label : t.catalogue.tabs[type]}>
          {query ? (
            <SearchResults query={query} items={matchingHits} />
          ) : (
            <>
              <p className="text-sm text-muted-foreground">
                {t.catalogue.results(resultCount)}
              </p>

              {resultCount === 0 ? (
                <div className="mt-6 rounded-2xl border border-dashed border-hairline bg-card/50 px-6 py-14 text-center">
                  <p className="text-sm leading-relaxed text-muted-foreground">
                    {type === "tutoriels"
                      ? t.catalogue.empty.tutoriels
                      : t.catalogue.empty.formations}
                  </p>
                </div>
              ) : (
                <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                  {type === "tutoriels"
                    ? visibleTutorials.map((tutorial) => (
                        <TutorialCard key={tutorial.id} tutorial={tutorial} />
                      ))
                    : visibleTracks.map((track) => (
                        <FormationCard key={track.slug} track={track} />
                      ))}
                </div>
              )}
            </>
          )}
        </section>
      </div>
    </div>
  );
}
