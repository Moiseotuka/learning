import { popularTracks as staticTracks, type LevelType } from "@/config/catalog";
import { cleanVideoTitle } from "@/lib/learning/video-title";
import { createServiceSupabase } from "@/lib/supabase/service";

export type CatalogSearchKind = "formation" | "chapitre" | "tutoriel";

export type CatalogSearchItem = {
  kind: CatalogSearchKind;
  id: string;
  title: string;
  /** Catégorie d'un parcours, ou titre du parcours pour un chapitre. */
  context: string;
  categoryId: string;
  summary: string;
  level: LevelType;
  href: string;
  score: number;
};

type Source = {
  kind: CatalogSearchKind;
  id: string;
  title: string;
  context: string;
  categoryId: string;
  summary: string;
  level: LevelType;
  href: string;
};

const STOPWORDS = new Set([
  "le", "la", "les", "un", "une", "des", "du", "au", "aux", "de", "d", "et",
  "en", "dans", "sur", "pour", "par", "avec", "sans", "ou", "a", "ce", "cette",
  "que", "qui", "il", "elle", "on", "se", "son", "ses", "plus", "tres",
  "cours", "apprendre", "formation", "formations", "tutoriel", "tutoriels",
  "video", "videos", "module", "modules", "the", "and", "for", "with", "how",
]);

/** Le vocabulaire des apprenants ne recoupe pas toujours celui du catalogue. */
const ALIASES: Record<string, string[]> = {
  reseau: ["reseau", "reseaux", "lan", "wan", "routage", "switch"],
  reseaux: ["reseau", "reseaux", "routage", "lan"],
  cyber: ["cyber", "cybersecurite", "securite", "hacking"],
  cybersecurite: ["cyber", "cybersecurite", "securite", "reseau"],
  securite: ["securite", "cybersecurite", "pentest"],
  hacking: ["hacking", "pentest", "cyber", "offensif"],
  ml: ["ml", "machine", "apprentissage", "ia"],
  ai: ["ai", "ia", "intelligence"],
  ia: ["ia", "intelligence", "machine"],
  intelligence: ["intelligence", "ia", "artificielle"],
  apprentissage: ["apprentissage", "machine", "ml", "ia"],
  automatique: ["automatique", "machine", "ml", "deep"],
  data: ["data", "donnees", "analyse", "sql"],
  developpeur: ["developpeur", "developpement", "dev"],
  developpement: ["developpement", "developpeur", "dev", "code"],
  code: ["code", "programmation", "developpement"],
  programmation: ["programmation", "code", "developpement", "python"],
  web: ["web", "site", "html", "css"],
  site: ["site", "web", "html"],
  frontend: ["frontend", "front", "react", "web"],
  backend: ["backend", "back", "api", "serveur"],
  base: ["base", "notions", "debutant", "fondamentaux"],
  debutant: ["debutant", "base", "notions", "fondamentaux"],
  donnee: ["donnee", "donnees", "sql", "database"],
  donnees: ["donnees", "donnee", "sql", "data"],
  sql: ["sql", "donnees", "database", "requete"],
  boutique: ["boutique", "ecommerce", "woocommerce", "wordpress"],
  ecommerce: ["ecommerce", "boutique", "paiement", "woocommerce"],
  paiement: ["paiement", "mobile", "ecommerce", "pay"],
  embarque: ["embarque", "arduino", "esp32", "stm32", "microcontroleur"],
  microcontroleur: ["microcontroleur", "arduino", "esp32", "embarque"],
  domotique: ["domotique", "raspberry", "esp32", "maison"],
  linux: ["linux", "ubuntu", "bash", "shell", "serveur"],
  serveur: ["serveur", "linux", "docker", "devops"],
  devops: ["devops", "docker", "kubernetes", "ci", "serveur"],
  maintenance: ["maintenance", "materiel", "pc", "reparation"],
  materiel: ["materiel", "maintenance", "pc", "composant"],
  iot: ["iot", "objet", "objets", "esp32", "arduino", "capteur"],
  objet: ["objet", "objets", "iot", "esp32", "arduino", "capteur"],
  objets: ["objets", "objet", "iot", "esp32", "arduino", "capteur"],
  mobile: ["mobile", "flutter", "android", "ios", "telephone", "smartphone"],
  telephone: ["telephone", "smartphone", "mobile", "reparation", "deblocage"],
  smartphone: ["smartphone", "telephone", "mobile", "reparation"],
  reparation: ["reparation", "panne", "depannage", "atelier", "telephone"],
  depannage: ["depannage", "reparation", "panne", "maintenance", "telephone"],
  deblocage: ["deblocage", "code", "operateur", "imei", "telephone"],
  flash: ["flash", "firmware", "restauration", "telephone"],
  atelier: ["atelier", "reparation", "devis", "client"],
  application: ["application", "app", "site", "logiciel"],
};

/** Une expression entière du langage courant vaut mieux que trois mots obligatoires. */
const PHRASES: Record<string, string[]> = {
  "internet des objets": ["iot", "objet", "connecte", "esp32", "arduino", "capteur"],
  "objet connecte": ["iot", "objet", "connecte", "esp32", "arduino", "capteur"],
  "objets connectes": ["iot", "objet", "connecte", "esp32", "arduino", "capteur"],
  "machine learning": ["ml", "machine", "apprentissage", "ia", "intelligence"],
  "deep learning": ["ml", "machine", "apprentissage", "ia", "intelligence"],
  "apprentissage automatique": ["ml", "machine", "apprentissage", "ia", "intelligence"],
  "intelligence artificielle": ["ia", "intelligence", "machine", "apprentissage"],
  "science des donnees": ["data", "donnees", "data science", "analyse", "sql"],
  "securite informatique": ["cyber", "cybersecurite", "securite", "pentest"],
  "reparation d ordinateur": ["maintenance", "materiel", "pc", "diagnostiquer"],
  "reparation de telephone": ["reparation", "telephone", "smartphone", "panne", "ecran", "batterie"],
  "reparation smartphone": ["reparation", "smartphone", "telephone", "panne", "ecran", "batterie"],
  "deblocage telephone": ["deblocage", "telephone", "imei", "operateur", "code"],
  "creation de site web": ["web", "site", "html", "css", "wordpress"],
  "application mobile": ["mobile", "flutter", "react native", "android"],
};

const KIND_WEIGHT: Record<CatalogSearchKind, number> = {
  formation: 14,
  chapitre: 5,
  tutoriel: 2,
};

/** « Réseau » se cherche aussi sans accent : on plie accents et ponctuation. */
export function foldText(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9+# ]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/** Un mot de la requête = un groupe de variantes équivalentes (alias OR, non ET). */
type SearchTerm = { word: string; variants: string[] };

function tokenize(query: string): { terms: SearchTerm[]; phrase: string } {
  const phrase = foldText(query);
  const expression = PHRASES[phrase];
  if (expression) return { terms: [{ word: phrase, variants: expression }], phrase };

  const terms: SearchTerm[] = [];
  const seen = new Set<string>();

  for (const word of phrase.split(" ")) {
    if (word.length < 2 || STOPWORDS.has(word) || seen.has(word)) continue;
    seen.add(word);
    const variants: string[] = [];
    for (const variant of [word, ...(ALIASES[word] ?? [])]) {
      if (variant.length >= 2 && !variants.includes(variant)) variants.push(variant);
    }
    terms.push({ word, variants });
  }

  return { terms, phrase };
}

/** « ml » ne doit pas se contenter du « ml » de « html » : les mots courts s'ancrent sur un mot entier. */
function contains(haystack: string, needle: string): boolean {
  if (needle.length < 4) {
    const escaped = needle.replace(/[+]/g, "\\$&");
    return new RegExp(`(^| )${escaped}(s|es)?( |$)`).test(haystack);
  }
  if (haystack.includes(needle)) return true;
  const stem = needle.replace(/(s|es)$/, "");
  return stem.length >= 4 && haystack.includes(stem);
}

function termStrength(
  term: SearchTerm,
  title: string,
  context: string,
  summary: string,
): number {
  let best = 0;

  for (const variant of term.variants) {
    let hit = 0;
    if (title === variant) hit = 20;
    else if (title.startsWith(variant)) hit = 15;
    else if (contains(title, variant)) hit = 11;
    else if (contains(context, variant)) hit = 7;
    else if (contains(summary, variant)) hit = 4;
    if (hit > best) best = hit;
  }

  return best;
}

function scoreSource(source: Source, terms: SearchTerm[], phrase: string): number {
  const title = foldText(source.title);
  const context = foldText(`${source.context} ${source.level}`);
  const summary = foldText(source.summary);

  let score = phrase.length >= 3 && title.includes(phrase) ? 40 : 0;

  for (const term of terms) {
    const hit = termStrength(term, title, context, summary);
    // Un mot absent du titre, du domaine et du résumé écarte le résultat.
    if (hit === 0) return 0;
    score += hit;
  }

  return score + KIND_WEIGHT[source.kind];
}

type CategoryRef = { id?: string; name?: string } | null;
type TrackRef = {
  slug?: string;
  title?: string;
  category_id?: string;
  categories?: CategoryRef | CategoryRef[] | null;
} | null;

function unwrap<T>(value: unknown): T | null {
  const ref = value as T | T[] | undefined;
  if (ref === undefined || ref === null) return null;
  return Array.isArray(ref) ? (ref[0] ?? null) : ref;
}

const TRACK_SELECT = "slug,title,description,level,categories(id,name)";
const CHAPTER_SELECT =
  "id,slug,title,summary,level,track:tracks(slug,title,category_id,categories(id,name))";
const TUTORIAL_SELECT = "slug,title,summary,level,channel,categories(id,name)";

function category(value: unknown): { id: string; name: string } {
  const ref = unwrap<CategoryRef>(value);
  return { id: ref?.id ?? "", name: ref?.name ?? "" };
}

function toTrackSource(row: Record<string, unknown>): Source | null {
  const slug = typeof row.slug === "string" ? row.slug : "";
  const title = typeof row.title === "string" ? row.title : "";
  if (!slug || !title) return null;

  const cat = category(row.categories);

  return {
    kind: "formation",
    id: slug,
    title,
    context: cat.name,
    categoryId: cat.id,
    summary: typeof row.description === "string" ? row.description : "",
    level: (row.level as LevelType) ?? "debutant",
    href: `/app/parcours/${slug}`,
  };
}

function toChapterSource(row: Record<string, unknown>): Source | null {
  const title = typeof row.title === "string" ? row.title : "";
  if (!title) return null;

  const track = unwrap<TrackRef>(row.track);
  // Le parcours disparaît de l'embed quand il n'est pas publié : rien à lier.
  if (!track?.slug) return null;

  const chapterSlug = typeof row.slug === "string" ? row.slug : String(row.id ?? "");
  const cat = category(track.categories);

  return {
    kind: "chapitre",
    id: String(row.id ?? chapterSlug),
    title,
    context: track.title ?? cat.name,
    categoryId: track.category_id ?? cat.id,
    summary: typeof row.summary === "string" ? row.summary : "",
    level: (row.level as LevelType) ?? "debutant",
    href: `/app/parcours/${track.slug}/chapitres/${chapterSlug}`,
  };
}

function toTutorialSource(row: Record<string, unknown>): Source | null {
  const slug = typeof row.slug === "string" ? row.slug : "";
  const rawTitle = typeof row.title === "string" ? row.title : "";
  if (!slug || !rawTitle) return null;

  const channel = typeof row.channel === "string" ? row.channel : undefined;
  const title = cleanVideoTitle(rawTitle, channel) || rawTitle;
  const cat = category(row.categories);

  return {
    kind: "tutoriel",
    id: slug,
    title,
    context: cat.name,
    categoryId: cat.id,
    summary: typeof row.summary === "string" ? row.summary : "",
    level: (row.level as LevelType) ?? "debutant",
    href: `/tutoriels/${slug}`,
  };
}

async function fetchSources(): Promise<Source[]> {
  // Les politiques RLS de `chapters` ne couvrent pas le rôle anon : la recherche
  // publique passe par la clé de service et filtre explicitement sur `published`.
  const supabase = createServiceSupabase();
  if (!supabase) {
    return staticTracks.map<Source>((track) => ({
      kind: "formation",
      id: track.slug,
      title: track.title,
      context: track.category,
      categoryId: track.categoryId,
      summary: track.bestFor,
      level: track.levelFrom,
      href: `/app/parcours/${track.slug}`,
    }));
  }

  const [tracks, chapters, tutorials] = await Promise.all([
    supabase
      .from("tracks")
      .select(TRACK_SELECT)
      .eq("published", true)
      .limit(400),
    supabase
      .from("chapters")
      .select(CHAPTER_SELECT)
      .eq("published", true)
      .limit(1200),
    supabase
      .from("tutorials")
      .select(TUTORIAL_SELECT)
      .eq("published", true)
      .limit(400),
  ]);

  if (tracks.error) console.error("[search] tracks", tracks.error.message);
  if (chapters.error) console.error("[search] chapters", chapters.error.message);
  if (tutorials.error) console.error("[search] tutorials", tutorials.error.message);

  const map = (
    data: unknown,
    convert: (row: Record<string, unknown>) => Source | null,
  ) =>
    ((data ?? []) as Record<string, unknown>[]).flatMap((row) => {
      const source = convert(row);
      return source ? [source] : [];
    });

  return [
    ...map(tracks.data, toTrackSource),
    ...map(chapters.data, toChapterSource),
    ...map(tutorials.data, toTutorialSource),
  ];
}

/**
 * Le catalogue ne change que depuis le back-office : une minute de mise en cache
 * par instance suffit, et évite 1 600 lignes relues à chaque frappe du champ.
 */
const SOURCES_TTL_MS = 60_000;
let cachedSources: { at: number; items: Source[] } | null = null;

async function loadSources(): Promise<Source[]> {
  if (cachedSources && Date.now() - cachedSources.at < SOURCES_TTL_MS) {
    return cachedSources.items;
  }
  const items = await fetchSources();
  if (items.length > 0) cachedSources = { at: Date.now(), items };
  return items;
}

/**
 * Moteur de recherche interne : parcours, chapitres et tutoriels du catalogue.
 * Insensible aux accents, chaque terme de la requête doit être présent.
 */
export async function searchCatalog(
  query: string,
  limit = 80,
): Promise<CatalogSearchItem[]> {
  const { terms, phrase } = tokenize(query);
  if (terms.length === 0) return [];

  const sources = await loadSources();

  return sources
    .map<CatalogSearchItem>((source) => ({
      kind: source.kind,
      id: source.id,
      title: source.title,
      context: source.context,
      categoryId: source.categoryId,
      summary: source.summary,
      level: source.level,
      href: source.href,
      score: scoreSource(source, terms, phrase),
    }))
    .filter((item) => item.score > 0)
    .sort((a, b) => b.score - a.score || a.title.localeCompare(b.title, "fr"))
    .slice(0, limit);
}
