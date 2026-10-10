import {
  categories as staticCategories,
  popularTracks as staticTracks,
  type Category,
  type LevelType,
  type PopularTrack,
} from "@/config/catalog";
import { startingPrice } from "@/lib/pricing";
import { createPublicSupabase } from "@/lib/supabase/public";
import { createServerSupabase } from "@/lib/supabase/server";

export type AdminCategory = Category & {
  published: boolean;
  position: number;
};

type CategoryRow = {
  id: string;
  slug: string;
  name: string;
  description: string;
  icon: string;
  levels: LevelType[];
  track_count: number;
  position: number;
  published: boolean;
};

type TrackRow = {
  category_id: string;
  slug: string;
  title: string;
  description: string;
  level: LevelType;
  duration_hours: number;
  modules_count: number;
  price_usd: number | null;
  rating: number;
  students: number;
  categories: { id: string; name: string } | null;
};

const categorySelect =
  "id,slug,name,description,icon,levels,track_count,position,published";

const trackSelect =
  "category_id,slug,title,description,level,duration_hours,modules_count,price_usd,rating,students,categories(id,name)";

function toCategory(row: CategoryRow): Category {
  return {
    id: row.id,
    slug: row.slug,
    name: row.name,
    description: row.description,
    icon: row.icon,
    levels: row.levels ?? [],
    trackCount: row.track_count ?? 0,
  };
}

function toAdminCategory(row: CategoryRow): AdminCategory {
  return { ...toCategory(row), published: row.published, position: row.position };
}

function toTrack(row: TrackRow): PopularTrack {
  return {
    slug: row.slug,
    title: row.title,
    categoryId: row.category_id,
    category: row.categories?.name ?? "",
    levelFrom: row.level,
    durationHours: row.duration_hours,
    modules: row.modules_count,
    priceUsd: row.price_usd,
    rating: Number(row.rating ?? 0),
    students: row.students ?? 0,
    bestFor: row.description,
  };
}

export async function getCategories(): Promise<Category[]> {
  const supabase = createPublicSupabase();
  if (!supabase) return staticCategories;

  const { data, error } = await supabase
    .from("categories")
    .select(categorySelect)
    .eq("published", true)
    .order("position");

  if (error || !data) {
    console.error("[catalog] categories", error?.message ?? "no data");
    return staticCategories;
  }

  return (data as CategoryRow[]).map(toCategory);
}

export async function getTracks(): Promise<PopularTrack[]> {
  const supabase = createPublicSupabase();
  if (!supabase) return staticTracks;

  const { data, error } = await supabase
    .from("tracks")
    .select(trackSelect)
    .eq("published", true)
    .order("position");

  if (error || !data) {
    console.error("[catalog] tracks", error?.message ?? "no data");
    return staticTracks;
  }

  return (data as unknown as TrackRow[]).map(toTrack);
}

export type StartingPrices = Map<string, number>;

export async function getStartingPrices(): Promise<StartingPrices> {
  const prices: StartingPrices = new Map();
  const supabase = createPublicSupabase();
  if (!supabase) return prices;

  const { data, error } = await supabase
    .from("category_level_prices")
    .select("category_id,level,price_usd")
    .eq("published", true);

  if (error || !data) {
    console.warn(
      "[catalog] tarifs par niveau indisponibles — coller la migration 202610030001_payments.sql",
      error?.message ?? "no data",
    );
    return prices;
  }

  const byCategory = new Map<string, Record<string, number>>();
  for (const row of data as {
    category_id: string;
    level: string;
    price_usd: number;
  }[]) {
    const record = byCategory.get(row.category_id) ?? {};
    record[row.level] = row.price_usd;
    byCategory.set(row.category_id, record);
  }

  for (const [categoryId, record] of byCategory) {
    const price = startingPrice(record);
    if (price !== null) prices.set(categoryId, price);
  }

  return prices;
}

export type CatalogTutorial = {
  id: string;
  slug: string;
  title: string;
  summary: string;
  url: string;
  channel: string;
  thumbnail: string;
  level: LevelType;
  categoryId: string;
  category: string;
};

type TutorialRow = {
  id: string;
  slug: string;
  title: string;
  summary: string;
  url: string;
  channel: string;
  thumbnail: string;
  level: LevelType;
  category_id: string;
  categories: { id: string; name: string } | null;
};

const tutorialSelect =
  "id,slug,title,summary,url,channel,thumbnail,level,category_id,categories(id,name)";

function toTutorial(row: TutorialRow): CatalogTutorial {
  const category = Array.isArray(row.categories)
    ? (row.categories[0]?.name ?? "")
    : (row.categories?.name ?? "");

  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    summary: row.summary,
    url: row.url,
    channel: row.channel,
    thumbnail: row.thumbnail,
    level: row.level,
    categoryId: row.category_id,
    category,
  };
}

export async function getTutorials(categoryId?: string): Promise<CatalogTutorial[]> {
  const supabase = createPublicSupabase();
  if (!supabase) return [];

  let query = supabase
    .from("tutorials")
    .select(tutorialSelect)
    .eq("published", true)
    .order("position");

  if (categoryId) query = query.eq("category_id", categoryId);

  const { data, error } = await query;

  if (error || !data) {
    console.error("[catalog] tutorials", error?.message ?? "no data");
    return [];
  }

  return (data as unknown as TutorialRow[]).map(toTutorial);
}

export async function getTutorialBySlug(
  slug: string,
): Promise<CatalogTutorial | null> {
  const supabase = createPublicSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase
    .from("tutorials")
    .select(tutorialSelect)
    .eq("slug", slug)
    .eq("published", true)
    .maybeSingle();

  if (error) {
    console.error("[catalog] tutorial", error.message);
    return null;
  }

  return data ? toTutorial(data as unknown as TutorialRow) : null;
}

export async function getAdminCategories(): Promise<AdminCategory[]> {
  const supabase = await createServerSupabase();
  if (!supabase) {
    return staticCategories.map((category, index) => ({
      ...category,
      published: true,
      position: index + 1,
    }));
  }

  const { data, error } = await supabase
    .from("categories")
    .select(categorySelect)
    .order("position");

  if (error || !data) {
    console.error("[catalog] admin categories", error?.message ?? "no data");
    return staticCategories.map((category, index) => ({
      ...category,
      published: true,
      position: index + 1,
    }));
  }

  return (data as CategoryRow[]).map(toAdminCategory);
}

export type CatalogStats = {
  categories: number;
  tracks: number;
  publishedCategories: number;
  publishedTracks: number;
};

export async function getCatalogStats(): Promise<CatalogStats> {
  const fallback: CatalogStats = {
    categories: staticCategories.length,
    tracks: staticTracks.length,
    publishedCategories: staticCategories.length,
    publishedTracks: staticTracks.length,
  };

  const supabase = await createServerSupabase();
  if (!supabase) return fallback;

  const [categories, tracks] = await Promise.all([
    supabase
      .from("categories")
      .select("id,published", { count: "exact" }),
    supabase.from("tracks").select("id,published", { count: "exact" }),
  ]);

  if (categories.error || tracks.error) {
    console.error(
      "[catalog] stats",
      categories.error?.message ?? tracks.error?.message ?? "no data",
    );
    return fallback;
  }

  const categoryRows = (categories.data ?? []) as { published: boolean }[];
  const trackRows = (tracks.data ?? []) as { published: boolean }[];

  return {
    categories: categoryRows.length,
    tracks: trackRows.length,
    publishedCategories: categoryRows.filter((row) => row.published).length,
    publishedTracks: trackRows.filter((row) => row.published).length,
  };
}
