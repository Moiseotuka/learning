/**
 * Applique le contenu des leçons à Supabase via l'API REST (service role) :
 * équivalent exact de 202610040005_chapter_pages_seed.sql (pages) et
 * 202610040006_chapter_pages_content.sql (chapters.content), pour contourner
 * la limite de taille de l'éditeur SQL Supabase (~0,98 Mo).
 *
 * Prérequis : table chapter_pages créée — coller une seule fois le petit
 * fichier supabase/migrations/202610040004_chapter_pages.sql dans l'éditeur.
 *
 * Usage : node scripts/apply-chapter-pages.mjs          (applique + vérifie)
 *         node scripts/apply-chapter-pages.mjs --check  (vérifie seulement)
 */
import { serviceEnv } from "./e2e-setup.mjs";
import { loadLessons } from "./lib/lesson-pages.mjs";

const checkOnly = process.argv.includes("--check");
const { url, key } = serviceEnv();
if (!url || !key) {
  console.error("NEXT_PUBLIC_SUPABASE_URL / service key absents de .env.local");
  process.exit(1);
}

const headers = {
  apikey: key,
  Authorization: `Bearer ${key}`,
  "Content-Type": "application/json",
};

async function rest(pathname, options = {}) {
  const response = await fetch(`${url}/rest/v1/${pathname}`, {
    ...options,
    headers: { ...headers, ...options.headers },
  });
  const text = await response.text();
  return {
    ok: response.ok,
    status: response.status,
    body: text,
    json: () => {
      try {
        return JSON.parse(text);
      } catch {
        return null;
      }
    },
  };
}

const chapters = loadLessons();

// 0. La table chapter_pages existe-t-elle ? ----------------------------------

const probe = await rest("chapter_pages?select=id&limit=1");
if (!probe.ok) {
  console.error(
    "✗ Table chapter_pages absente — coller supabase/migrations/202610040004_chapter_pages.sql dans l'éditeur SQL, puis relancer.",
  );
  console.error(`  (${probe.status}) ${probe.body.slice(0, 200)}`);
  process.exit(1);
}

if (checkOnly) {
  let failures = 0;
  for (const chapter of chapters) {
    const rows = await rest(
      `chapter_pages?select=id&chapter_id=eq.${chapter.id}`,
    );
    const count = rows.json()?.length ?? 0;
    const ok = count === chapter.pages.length;
    if (!ok) failures += 1;
    console.log(
      `${ok ? "✓" : "✗"} ${chapter.id} — ${count} page(s) en base (attendu ${chapter.pages.length})`,
    );
  }
  const content = await rest(
    "chapters?select=id,content&id=in.(py-c1,py-c2,py-c3,py-c4,py-c5,py-c6,py-c7,py-c8)",
  );
  const rows = content.json() ?? [];
  for (const chapter of chapters) {
    const row = rows.find((item) => item.id === chapter.id);
    const len = row?.content?.length ?? 0;
    const ok = len > chapter.content.length * 0.9;
    if (!ok) failures += 1;
    console.log(
      `${ok ? "✓" : "✗"} ${chapter.id} — chapters.content = ${len} octets (attendu ~${chapter.content.length})`,
    );
  }
  console.log(
    failures === 0 ? "\n=== CONTENU CONFORME ===\n" : `\n=== ${failures} ÉCHEC(S) ===\n`,
  );
  process.exit(failures === 0 ? 0 : 1);
}

// 1. Application -------------------------------------------------------------

for (const chapter of chapters) {
  const del = await rest(`chapter_pages?chapter_id=eq.${chapter.id}`, {
    method: "DELETE",
  });
  if (!del.ok) {
    console.error(`✗ ${chapter.id} — suppression impossible`, del.body.slice(0, 200));
    process.exit(1);
  }

  const rows = chapter.pages.map((page, index) => ({
    id: `${chapter.id}-p${index + 1}`,
    chapter_id: chapter.id,
    position: index + 1,
    title: page.title,
    content: page.content,
  }));
  const ins = await rest("chapter_pages", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify(rows),
  });
  if (!ins.ok) {
    console.error(`✗ ${chapter.id} — insertion impossible`, ins.body.slice(0, 300));
    process.exit(1);
  }

  const patch = await rest(`chapters?id=eq.${chapter.id}`, {
    method: "PATCH",
    body: JSON.stringify({ content: chapter.content }),
  });
  if (!patch.ok) {
    console.error(`✗ ${chapter.id} — chapters.content impossible`, patch.body.slice(0, 200));
    process.exit(1);
  }

  console.log(
    `✓ ${chapter.id} — ${rows.length} pages insérées, content = ${chapter.content.length} octets`,
  );
}

// 2. Vérification post-application -------------------------------------------

const total = await rest("chapter_pages?select=id");
const count = total.json()?.length ?? 0;
const expected = chapters.reduce((sum, chapter) => sum + chapter.pages.length, 0);
console.log(`\npages en base : ${count} (attendu ${expected})`);
if (count !== expected) {
  console.error("✗ Nombre de pages inattendu");
  process.exit(1);
}
console.log("=== CONTENU APPLIQUÉ ===\n");
