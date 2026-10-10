/**
 * Lecture des leçons (content/lessons/*.txt) et découpage en pages numérotées
 * du Cours. Partagé par generate-pages-migration.mjs et apply-chapter-pages.mjs.
 */
import { readFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const LESSONS_DIR = resolve(
  fileURLToPath(new URL("../../content/lessons", import.meta.url)),
);

/** Marqueur dollar-quoting des migrations (interdit dans les leçons validées). */
export const TAG = "$lesson$";

/**
 * Une leçon devient une suite de pages : chaque section « ## » ouvre une page
 * titrée ; le chapô d'introduction (texte avant la première section) rejoint
 * la première page. Retourne [{ title, content }].
 */
export function splitPages(content) {
  const lines = content.replace(/\r\n/g, "\n").split("\n");
  const sections = [];
  const intro = [];
  let current = null;

  for (const line of lines) {
    const match = line.match(/^##\s+(.*)$/);
    if (match) {
      if (current) sections.push(current);
      current = { title: match[1].trim(), body: [] };
    } else if (current) {
      current.body.push(line);
    } else {
      intro.push(line);
    }
  }
  if (current) sections.push(current);

  if (sections.length === 0) {
    sections.push({ title: "Introduction", body: intro });
  } else if (intro.join("").trim()) {
    sections[0].body = [...intro, "", ...sections[0].body];
  }

  return sections.map((section) => ({
    title: section.title,
    content: section.body.join("\n").trim(),
  }));
}

function assertSafe(label, value) {
  if (value.includes(TAG)) {
    throw new Error(`${label} contient le marqueur ${TAG}`);
  }
  if (value.includes("$$")) {
    throw new Error(`${label} contient $$ (dollar-quoting invalide)`);
  }
}

/** Charge toutes les leçons validées : [{ id, content, pages }]. */
export function loadLessons(dir = LESSONS_DIR) {
  const files = readdirSync(dir)
    .filter((name) => name.endsWith(".txt"))
    .sort();
  if (files.length === 0) {
    throw new Error(`Aucun fichier .txt dans ${dir}`);
  }

  const chapters = [];
  for (const name of files) {
    const id = name.replace(/\.txt$/, "");
    const content = readFileSync(resolve(dir, name), "utf8").replace(
      /\r\n/g,
      "\n",
    );
    assertSafe(name, content);
    const pages = splitPages(content);
    if (pages.length < 2) {
      throw new Error(`${name} : ${pages.length} page(s) seulement`);
    }
    pages.forEach((page, index) =>
      assertSafe(`${name} page ${index + 1}`, page.title),
    );
    chapters.push({ id, content, pages });
  }
  return chapters;
}
