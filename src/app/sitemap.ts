import type { MetadataRoute } from "next";

import { legalDocs } from "@/config/legal";
import { site } from "@/config/site";
import { getSeoTracks, getTutorialEntries } from "@/lib/catalog/seo";
import { getCategories } from "@/lib/catalog/queries";

/**
 * Le sitemap est recalculé à la demande plutôt qu'au build : un parcours publié
 * par l'admin doit apparaître ici sans redéploiement. Une heure de cache suffit
 * à ne pas solliciter Supabase à chaque crawl.
 */
export const revalidate = 3600;

function url(
  path: string,
  lastModified: string | null,
  changeFrequency: MetadataRoute.Sitemap[number]["changeFrequency"],
  priority: number,
): MetadataRoute.Sitemap[number] {
  const date = lastModified ? new Date(lastModified) : null;
  return {
    url: `${site.url}${path}`,
    ...(date && !Number.isNaN(date.getTime()) ? { lastModified: date } : {}),
    changeFrequency,
    priority,
  };
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [categories, tracks, tutorials] = await Promise.all([
    getCategories(),
    getSeoTracks(),
    getTutorialEntries(),
  ]);

  return [
    url("/", null, "weekly", 1),
    url("/catalogue", null, "daily", 0.9),
    url("/formateurs", null, "weekly", 0.8),
    ...categories.map((category) =>
      url(`/formations/${category.slug}`, null, "weekly", 0.8),
    ),
    ...tracks.map((track) =>
      url(`/parcours/${track.slug}`, track.updatedAt, "weekly", 0.9),
    ),
    ...tutorials.map((tutorial) =>
      url(`/tutoriels/${tutorial.slug}`, tutorial.updatedAt, "monthly", 0.6),
    ),
    url("/verifier", null, "monthly", 0.5),
    ...legalDocs.map((doc) => url(`/${doc.slug}`, null, "yearly", 0.2)),
  ];
}
