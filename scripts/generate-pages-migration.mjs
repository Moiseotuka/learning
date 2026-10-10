/**
 * Génère les migrations chapter_pages à partir des leçons (content/lessons).
 *
 * - 202610040004_chapter_pages.sql        : DDL (table + index + RLS)
 * - 202610040005_chapter_pages_seed.sql   : seed des pages (delete + insert)
 *   → si dépassement de la limite éditeur : _part2.sql, _part3.sql…
 * - 202610040006_chapter_pages_content.sql: chapters.content (repli)
 *   → mêmes découpage _partN si nécessaire
 *
 * Chaque section « ## » d'une leçon devient une page titrée ; le chapô
 * d'introduction rejoint la première page (voir scripts/lib/lesson-pages.mjs).
 * Contenu encodé en dollar-quoting $lesson$ (les leçons validées ne
 * contiennent ni $$ ni $lesson$).
 *
 * Déploiement : l'éditeur SQL Supabase rejette les requêtes d'environ
 * 0,98 Mo — coller les petits fichiers un par un, ou appliquer le contenu
 * via REST : node scripts/apply-chapter-pages.mjs
 *
 * Usage : node scripts/generate-pages-migration.mjs
 */
import { readdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { TAG, loadLessons } from "./lib/lesson-pages.mjs";

const OUT_DDL = fileURLToPath(
  new URL("../supabase/migrations/202610040004_chapter_pages.sql", import.meta.url),
);
const OUT_SEED = fileURLToPath(
  new URL(
    "../supabase/migrations/202610040005_chapter_pages_seed.sql",
    import.meta.url,
  ),
);
const OUT_CONTENT = fileURLToPath(
  new URL(
    "../supabase/migrations/202610040006_chapter_pages_content.sql",
    import.meta.url,
  ),
);
/** Limite de l'éditeur SQL Supabase : 0,98 * 1024 * 1024 octets. */
const MAX_BYTES = Math.floor(0.98 * 1024 * 1024);

const chapters = loadLessons();
const ids = chapters.map((chapter) => `'${chapter.id}'`).join(", ");

for (const chapter of chapters) {
  const words = chapter.content.split(/\s+/).filter(Boolean).length;
  console.log(
    `✓ ${chapter.id} — ${chapter.pages.length} pages, ${words} mots, ${chapter.content.length} octets`,
  );
}

const ddl = `-- easyLearn — pages numérotées du Cours (organisation type Cisco NetAcad)
-- La leçon d'un chapitre est découpée en pages navigables : chaque section
-- « ## » devient une page titrée, le chapô d'introduction rejoint la première
-- page. Numérotation affichée : chapitre.étape.page (ex. 1.3.4).
-- Idempotent.
-- Généré par scripts/generate-pages-migration.mjs — ne pas éditer à la main.
-- Suite : 202610040005_chapter_pages_seed.sql (pages) puis
-- 202610040006_chapter_pages_content.sql (repli chapters.content).

-- 1. Table des pages ---------------------------------------------------------

create table if not exists public.chapter_pages (
  id text primary key,
  chapter_id text not null references public.chapters (id) on delete cascade,
  position integer not null check (position >= 1),
  title text not null,
  content text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (chapter_id, position)
);

drop trigger if exists chapter_pages_set_updated_at on public.chapter_pages;
create trigger chapter_pages_set_updated_at
  before update on public.chapter_pages
  for each row execute function public.set_updated_at();

create index if not exists chapter_pages_chapter_position_idx
  on public.chapter_pages (chapter_id, position);

-- 2. Row Level Security ------------------------------------------------------
-- Lecture pour tout apprenant connecté : le déverrouillage (chapitre payé,
-- vidéos regardées) reste appliqué côté application, comme pour chapters.

alter table public.chapter_pages enable row level security;

drop policy if exists "chapter_pages_select" on public.chapter_pages;
create policy "chapter_pages_select" on public.chapter_pages
  for select to authenticated
  using (true);

drop policy if exists "chapter_pages_admin_write" on public.chapter_pages;
create policy "chapter_pages_admin_write" on public.chapter_pages
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());
`;

const totalPages = chapters.reduce((sum, chapter) => sum + chapter.pages.length, 0);

const seedHeader = `-- easyLearn — seed des pages numérotées du Cours (${totalPages} pages, ${chapters.length} chapitres)
-- Chaque section « ## » d'une leçon devient une page titrée.
-- Idempotent : remplace les pages des chapitres listés.
-- Généré par scripts/generate-pages-migration.mjs — ne pas éditer à la main.
-- Prérequis : 202610040004_chapter_pages.sql (table chapter_pages).
${chapters.length > 0 ? `\ndelete from public.chapter_pages where chapter_id in (${ids});\n` : ""}
`;

const seedStatements = chapters.map((chapter) => {
  const rows = chapter.pages
    .map((page, index) => {
      const position = index + 1;
      const id = `${chapter.id}-p${position}`;
      return `  ('${id}', '${chapter.id}', ${position}, ${TAG}${page.title}${TAG}, ${TAG}\n${page.content}\n${TAG})`;
    })
    .join(",\n");

  return `
insert into public.chapter_pages (id, chapter_id, position, title, content) values
${rows};
`;
});

const contentHeader = `-- easyLearn — chapters.content : leçons complètes (${chapters.length} chapitres)
-- Source de repli si chapter_pages est vide (pagination absente) ; le contenu
-- affiché reste chapter_pages quand il existe.
-- Généré par scripts/generate-pages-migration.mjs — ne pas éditer à la main.
`;

const contentStatements = chapters.map(
  (chapter) => `
update public.chapters set content = ${TAG}
${chapter.content}
${TAG} where id = '${chapter.id}';
`,
);

/** Découpe des statements en fichiers < MAX_BYTES (le 1er porte le header). */
function splitStatements(headerFirst, headerRest, statements) {
  const chunks = [];
  let current = headerFirst;
  for (const statement of statements) {
    if (
      Buffer.byteLength(current + statement, "utf8") > MAX_BYTES &&
      current !== headerFirst
    ) {
      chunks.push(current);
      current = headerRest;
    }
    current += statement;
  }
  chunks.push(current);
  return chunks;
}

function partPath(basePath, partNumber) {
  return partNumber === 1
    ? basePath
    : basePath.replace(/\.sql$/, `_part${partNumber}.sql`);
}

/** Supprime les parts d'un précédent tirage, écrit chaque part, contrôle la taille. */
function writeChunked(label, basePath, headerFirst, headerRest, statements) {
  const dir = resolve(basePath, "..");
  const baseName = basePath.split(/[\\/]/).pop().replace(/\.sql$/, "");
  for (const name of readdirSync(dir)) {
    if (new RegExp(`^${baseName}_part\\d+\\.sql$`).test(name)) {
      unlinkSync(join(dir, name));
    }
  }

  const chunks = splitStatements(headerFirst, headerRest, statements);
  let total = 0;
  chunks.forEach((text, index) => {
    const size = Buffer.byteLength(text, "utf8");
    if (size > MAX_BYTES) {
      throw new Error(
        `${label} part${index + 1} : ${size} octets > limite éditeur SQL (${MAX_BYTES})`,
      );
    }
    const path = partPath(basePath, index + 1);
    writeFileSync(path, text, "utf8");
    total += size;
    console.log(
      `✓ ${label}${chunks.length > 1 ? ` part${index + 1}/${chunks.length}` : ""} — ${size} octets → ${resolve(path)}`,
    );
  });
  return total;
}

function checkSize(label, path, text) {
  const size = Buffer.byteLength(text, "utf8");
  if (size > MAX_BYTES) {
    throw new Error(
      `${label} : ${size} octets > limite éditeur SQL (${MAX_BYTES})`,
    );
  }
  writeFileSync(path, text, "utf8");
  console.log(`✓ ${label} — ${size} octets → ${resolve(path)}`);
}

checkSize("DDL (à coller en premier)", OUT_DDL, ddl);
const seedHeaderRest = seedHeader
  .split("\n")
  .filter((line) => !line.startsWith("delete from"))
  .join("\n");
const seedTotal = writeChunked(
  "seed des pages",
  OUT_SEED,
  seedHeader,
  seedHeaderRest,
  seedStatements,
);
const contentTotal = writeChunked(
  "chapters.content (repli)",
  OUT_CONTENT,
  contentHeader,
  contentHeader,
  contentStatements,
);
console.log(`\nTotal : ${Buffer.byteLength(ddl, "utf8") + seedTotal + contentTotal} octets`);
