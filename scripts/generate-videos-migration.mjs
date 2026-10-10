/**
 * Génère la migration « vidéos FR » à partir de content/videos.json
 * (source de vérité des vidéos des chapitres : FR, pédagogiques, embed vérifié).
 *
 * Sortie : supabase/migrations/202610060001_videos_fr.sql
 * Usage  : node scripts/generate-videos-migration.mjs
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const outputFile = join(process.cwd(), "supabase", "migrations", "202610060001_videos_fr.sql");
const data = JSON.parse(readFileSync(join(process.cwd(), "content", "videos.json"), "utf8"));

function delimiterFor(text) {
  for (const d of ["videos", "video", "data", "json", "content"]) {
    if (!text.includes(`$${d}$`)) return d;
  }
  throw new Error("Aucun délimiteur dollar-quote disponible");
}

const chapters = Object.entries(data).filter(([slug]) => !slug.startsWith("_"));
if (chapters.length === 0) {
  console.error("content/videos.json vide");
  process.exit(1);
}

const header = `-- easyLearn — vidéos FR des chapitres (remplace les URLs cassées/anglaises)
-- Source : content/videos.json (42 vidéos, embed vérifié oEmbed 200).
-- Idempotent : remplace intégralement le champ videos des chapitres listés.
-- Généré par scripts/generate-videos-migration.mjs — ne pas éditer à la main.

`;

const statements = chapters.map(([slug, videos]) => {
  const json = JSON.stringify(videos, null, 2);
  const tag = delimiterFor(json);
  return `update public.chapters
set videos = $${tag}$${json}$${tag}$::jsonb
where slug = '${slug}';`;
});

const sql = header + statements.join("\n\n") + "\n";
writeFileSync(outputFile, sql, "utf8");
console.log(`✓ ${chapters.length} chapitres (${chapters.reduce((n, [, v]) => n + v.length, 0)} vidéos) → ${outputFile} (${sql.length} caractères)`);
