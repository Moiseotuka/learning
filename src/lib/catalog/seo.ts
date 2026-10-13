import { cache } from "react";

import { createPublicSupabase } from "@/lib/supabase/public";
import { createServiceSupabase } from "@/lib/supabase/service";
import type { LevelType } from "@/config/catalog";

/**
 * Lecture « moteur de recherche » du catalogue.
 *
 * Une fiche parcours publique doit exister sans session : c'est elle qui permet
 * à quelqu'un qui cherche « former cybersecurite en ligne » de tomber sur du
 * contenu réel. Elle n'expose que le programme — titre, résumé, objectifs —
 * jamais le corps de la leçon, l'exercice ni sa correction, qui restent derrière
 * l'accès payant. Les chapitres étant illisibles par un visiteur anonyme (RLS
 * `chapters_select to authenticated`), cette lecture passe par la clé de service,
 * colonne par colonne, avec une liste blanche.
 */

export type SeoTrack = {
  slug: string;
  title: string;
  description: string;
  categoryId: string;
  category: string;
  categorySlug: string;
  levelFrom: LevelType;
  durationHours: number;
  modules: number;
  updatedAt: string | null;
};

export type SeoChapter = {
  slug: string;
  title: string;
  summary: string;
  level: LevelType;
  objectives: string[];
};

export type SeoTrackDetail = SeoTrack & { chapters: SeoChapter[] };

const trackColumns =
  "slug,title,description,level,duration_hours,modules_count,updated_at,category_id,categories(id,slug,name)";

type TrackRow = {
  slug: string;
  title: string;
  description: string;
  level: LevelType;
  duration_hours: number;
  modules_count: number;
  updated_at: string | null;
  category_id: string;
  categories:
    | { id: string; slug: string; name: string }
    | { id: string; slug: string; name: string }[]
    | null;
};

type CategoryJoin = { id: string; slug: string; name: string };

function categoryRow(row: TrackRow): CategoryJoin | null {
  const joined = row.categories;
  if (!joined) return null;
  return Array.isArray(joined) ? (joined[0] ?? null) : joined;
}

function toSeoTrack(row: TrackRow): SeoTrack {
  const category = categoryRow(row);
  return {
    slug: row.slug,
    title: row.title,
    description: row.description,
    categoryId: row.category_id,
    category: category?.name ?? "",
    categorySlug: category?.slug ?? "",
    levelFrom: row.level,
    durationHours: row.duration_hours,
    modules: row.modules_count,
    updatedAt: row.updated_at,
  };
}

/** Toutes les fiches publiées, dans l'ordre du catalogue : source du sitemap. */
export async function getSeoTracks(): Promise<SeoTrack[]> {
  const supabase = createPublicSupabase();
  if (!supabase) return [];

  const { data, error } = await supabase
    .from("tracks")
    .select(trackColumns)
    .eq("published", true)
    .order("position");

  if (error) {
    console.error("[seo] tracks", error.message);
    return [];
  }

  return (data as unknown as TrackRow[]).map(toSeoTrack);
}

/**
 * Fiche publique d'un parcours : en-tête + programme.
 * Colonnes volontairement limitées ; ajouter « content » ici exposerait le cours
 * entier à un visiteur non payant.
 * `metadata` et le corps de la page lisent la même fiche : `cache` évite de
 * payer deux fois Supabase pour une seule requête HTTP.
 */
export const getSeoTrack = cache(readSeoTrack);

async function readSeoTrack(slug: string): Promise<SeoTrackDetail | null> {
  const supabase = createPublicSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase
    .from("tracks")
    .select(trackColumns)
    .eq("slug", slug)
    .eq("published", true)
    .maybeSingle();

  if (error) {
    console.error("[seo] track", error.message);
    return null;
  }
  if (!data) return null;

  const track = toSeoTrack(data as unknown as TrackRow);
  const service = createServiceSupabase();
  if (!service) return { ...track, chapters: [] };

  const { data: rows, error: chaptersError } = await service
    .from("chapters")
    .select("slug,title,summary,level,objectives")
    .eq("track_id", track.slug)
    .eq("published", true)
    .order("position");

  if (chaptersError) {
    console.error("[seo] chapters", chaptersError.message);
  }

  const chapters: SeoChapter[] = ((rows ?? []) as {
    slug: string;
    title: string;
    summary: string;
    level: LevelType;
    objectives: string[] | null;
  }[]).map((row) => ({
    slug: row.slug,
    title: row.title,
    summary: row.summary,
    level: row.level,
    objectives: row.objectives ?? [],
  }));

  return { ...track, chapters };
}

export type TutorialEntry = { slug: string; updatedAt: string | null };

/** Titre réel d'un chapitre, pour la liste longue traîne d'une page domaine. */
export type SeoChapterEntry = {
  slug: string;
  title: string;
  level: LevelType;
  trackSlug: string;
  trackTitle: string;
};

/**
 * Un échantillon de chapitres publiés du domaine : ce sont les requêtes exactes
 * que les apprenants tapent (« variables python débutant », « sous-réseau »),
 * donc le contenu qui fait remonter la page domaine.
 */
export async function getSeoCategoryChapters(
  categoryId: string,
  limit = 30,
): Promise<SeoChapterEntry[]> {
  const supabase = createPublicSupabase();
  if (!supabase) return [];

  const { data: tracks, error: tracksError } = await supabase
    .from("tracks")
    .select("slug,title")
    .eq("category_id", categoryId)
    .eq("published", true);

  if (tracksError || !tracks) {
    console.error("[seo] category tracks", tracksError?.message ?? "no data");
    return [];
  }

  const byTrack = new Map(
    (tracks as { slug: string; title: string }[]).map((row) => [row.slug, row.title]),
  );
  const ids = [...byTrack.keys()];
  if (ids.length === 0) return [];

  const service = createServiceSupabase();
  if (!service) return [];

  const { data, error } = await service
    .from("chapters")
    .select("slug,title,level,track_id")
    .in("track_id", ids)
    .eq("published", true)
    .order("position")
    .limit(limit);

  if (error) {
    console.error("[seo] category chapters", error.message);
    return [];
  }

  return (data as unknown as {
    slug: string;
    title: string;
    level: LevelType;
    track_id: string;
  }[]).map((row) => ({
    slug: row.slug,
    title: row.title,
    level: row.level,
    trackSlug: row.track_id,
    trackTitle: byTrack.get(row.track_id) ?? "",
  }));
}

/** Tous les tutoriels publiés, pour le sitemap. */
export async function getTutorialEntries(): Promise<TutorialEntry[]> {
  const supabase = createPublicSupabase();
  if (!supabase) return [];

  const { data, error } = await supabase
    .from("tutorials")
    .select("slug,updated_at")
    .eq("published", true)
    .order("position");

  if (error) {
    console.error("[seo] tutorials", error.message);
    return [];
  }

  return (data as unknown as { slug: string; updated_at: string | null }[]).map(
    (row) => ({ slug: row.slug, updatedAt: row.updated_at }),
  );
}
