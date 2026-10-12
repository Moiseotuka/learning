/**
 * Garde-fou du catalogue de leçons vidéo.
 *
 * Le catalogue est du contenu tiers : une vidéo peut être retirée, et un même
 * lien peut avoir été recopié dans plusieurs chapitres avec des titres
 * différents. Ces deux défauts rendent l'expérience cassée ou trompeuse, alors
 * qu'ils sont invisibles côté interface (l'iframe affiche simplement une erreur,
 * ou affiche la bonne vidéo sous un mauvais titre).
 *
 * Vérifications, via l'API oEmbed officielle (aucune clé nécessaire) :
 *   1. URL absente, non YouTube, ou vidéo retirée ;
 *   2. même vidéo utilisée dans plusieurs chapitres ;
 *   3. titre stocké qui ne ressemble plus au titre réel de la vidéo ;
 *   4. nom de chaîne stocké qui n'est pas le nom réel de la chaîne ;
 *   5. chapitre sans aucune leçon jouable.
 *
 * Usage : node scripts/check-video-catalogue.mjs [slug-de-parcours]
 * Sortie : code 1 dès qu'un défaut est détecté (prêt pour la CI).
 */
import { readFileSync } from "node:fs";

const envValue = (key) => {
  const raw = readFileSync(new URL("../.env.local", import.meta.url), "utf8");
  const match = raw.match(new RegExp(`^${key}=(.*)$`, "m"));
  return match ? match[1].trim() : "";
};

const url = envValue("NEXT_PUBLIC_SUPABASE_URL");
const key = envValue("SUPABASE_SERVICE_ROLE_KEY") || envValue("SUPABASE_SECRET_KEY");
if (!url || !key) {
  console.error("NEXT_PUBLIC_SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont requis dans .env.local");
  process.exit(2);
}

const trackFilter = process.argv[2];
const headers = { apikey: key, Authorization: `Bearer ${key}` };

const getJson = async (path) => {
  const res = await fetch(`${url}/rest/v1/${path}`, { headers });
  if (!res.ok) throw new Error(`REST ${path} ${res.status}: ${await res.text()}`);
  return res.json();
};

const tracks = await getJson("tracks?select=id,slug,title");
const trackSlug = new Map(tracks.map((track) => [track.id, track.slug]));
const wanted = trackFilter
  ? new Set(tracks.filter((track) => track.slug === trackFilter).map((track) => track.id))
  : null;

const rawChapters = await getJson("chapters?select=id,slug,title,position,videos,track_id");
const chapters = rawChapters
  .filter((chapter) => !wanted || wanted.has(chapter.track_id))
  .sort((a, b) =>
    `${trackSlug.get(a.track_id)}/${String(a.position).padStart(3, "0")}`.localeCompare(
      `${trackSlug.get(b.track_id)}/${String(b.position).padStart(3, "0")}`,
    ),
  );

const label = (chapter) => `${trackSlug.get(chapter.track_id) ?? "??"}/${chapter.slug}`;

/** Miroir de src/lib/embed-url.ts : seul un lien horodaté est une leçon. */
function videoId(rawUrl) {
  try {
    const parsed = new URL(String(rawUrl));
    const host = parsed.hostname.replace(/^www\./, "");
    if (host === "youtu.be") return parsed.pathname.slice(1) || null;
    if (host === "youtube.com" || host === "m.youtube.com") {
      return parsed.searchParams.get("v") ?? null;
    }
    if (host === "youtube-nocookie.com") {
      const parts = parsed.pathname.split("/").filter(Boolean);
      return parts[0] === "embed" ? (parts[1] ?? null) : null;
    }
    return null;
  } catch {
    return null;
  }
}

const norm = (value) =>
  String(value ?? "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();

const significant = (value) =>
  new Set(norm(value).split(" ").filter((word) => word.length > 2));

/**
 * Le titre affiché est réécrit pédagogiquement : on ne peut pas le comparer au
 * titre YouTube. On compare donc le titre d'origine consigné à l'ajout
 * (« source_title ») ; sans cette provenance, rien n'est signalé.
 */

const cache = new Map();
async function probe(id) {
  if (cache.has(id)) return cache.get(id);
  const res = await fetch(
    `https://www.youtube.com/oembed?format=json&url=${encodeURIComponent(`https://www.youtube.com/watch?v=${id}`)}`,
  ).catch(() => null);
  const body = res?.ok ? await res.json().catch(() => ({})) : {};
  const entry = { ok: Boolean(res?.ok), title: body.title ?? "", author: body.author_name ?? "" };
  cache.set(id, entry);
  await new Promise((resolve) => setTimeout(resolve, 150));
  return entry;
}

const dead = [];
const offTopic = [];
const wrongChannel = [];
const emptyChapters = [];
const byId = new Map();

for (const chapter of chapters) {
  const videos = Array.isArray(chapter.videos) ? chapter.videos : [];
  let playable = 0;

  for (const video of videos) {
    const id = videoId(video.url);
    if (!id) {
      dead.push(`${label(chapter)} — lien non intégrable : ${video.url}`);
      continue;
    }
    const meta = await probe(id);
    if (!meta.ok) {
      dead.push(`${label(chapter)} — vidéo retirée ou introuvable : ${id}`);
      continue;
    }
    playable += 1;

    if (!byId.has(id)) byId.set(id, []);
    byId.get(id).push(`${label(chapter)}`);

    if (video.source_title) {
      const stored = significant(video.source_title);
      const real = significant(meta.title);
      const shared = [...stored].filter((word) => real.has(word)).length;
      if (stored.size > 1 && shared === 0) {
        offTopic.push(
          `${id} ${label(chapter)} — consigné «${video.source_title}», YouTube affiche «${meta.title}»`,
        );
      }
    }
    if (meta.author && norm(video.channel) !== norm(meta.author)) {
      wrongChannel.push(`${id} — stocké «${video.channel}», réel «${meta.author}»`);
    }
  }

  if (videos.length === 0 || playable === 0) {
    emptyChapters.push(`${label(chapter)} (${videos.length} entrée(s))`);
  }
}

const reused = [...byId].filter(([, where]) => new Set(where).size > 1);

console.log(`Chapitres analysés : ${chapters.length}`);
const sections = [
  ["Vidéos mortes ou non intégrables", dead],
  ["Vidéos partagées entre chapitres", reused.map(([id, where]) => `${id} -> ${[...new Set(where)].join(", ")}`)],
  ["Titres qui ne correspondent pas à la vidéo", offTopic],
  ["Noms de chaîne inexacts", [...new Set(wrongChannel)]],
  ["Chapitres sans leçon jouable", emptyChapters],
];

let problems = 0;
for (const [label, list] of sections) {
  problems += list.length;
  console.log(`\n${label}: ${list.length}`);
  for (const line of list.slice(0, 40)) console.log(`  - ${line}`);
  if (list.length > 40) console.log(`  … ${list.length - 40} autres`);
}

console.log(`\n${problems === 0 ? "Catalogue sain." : `${problems} signal(s) à traiter.`}`);
process.exit(problems === 0 ? 0 : 1);
