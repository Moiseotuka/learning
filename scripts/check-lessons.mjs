/**
 * Contrôle des fichiers de leçon destinés à `chapters.content`.
 *
 * Vérifie le format LessonBody, le volume exigé (~10 000 mots,
 * ≥ 45 paragraphes de prose) et les sections obligatoires.
 *
 * Usage :
 *   node scripts/check-lessons.mjs <fichier...>
 *   node scripts/check-lessons.mjs --dir <dossier>
 *
 * Code retour : 0 si tout passe, 1 sinon.
 */

import { readdirSync, readFileSync, statSync } from "node:fs";
import { resolve } from "node:path";

const MIN_WORDS = 9000;
const MIN_PARAGRAPHS = 45;
const MIN_HEADINGS = 8;

const REQUIRED_HEADINGS = [
  "## À retenir",
  "## Erreurs fréquentes",
  "## Pour aller plus loin",
];
const LAST_HEADING_PREFIX = "## Et maintenant";

const FORBIDDEN = [
  { label: "gras **", re: /\*\*/ },
  { label: "lien markdown ](", re: /\]\(/ },
  { label: "titre # unique", re: /^# /m },
  { label: "délimiteur SQL $$", re: /\$\$/ },
  { label: "filet ---", re: /^-{3,}\s*$/m },
  { label: "balise HTML", re: /<\/?[a-z]+[ >]/i },
];

function splitBlocks(content) {
  const blocks = [];
  let current = [];
  let inFence = false;
  for (const line of content.split("\n")) {
    if (line.trimStart().startsWith("```")) inFence = !inFence;
    if (!inFence && line.trim() === "") {
      if (current.length > 0) {
        blocks.push(current.join("\n").trim());
        current = [];
      }
      continue;
    }
    current.push(line);
  }
  if (current.length > 0) blocks.push(current.join("\n").trim());
  return blocks.filter(Boolean);
}

function checkFile(path) {
  const content = readFileSync(path, "utf8");
  const errors = [];

  const words = content.split(/\s+/).filter(Boolean).length;
  if (words < MIN_WORDS) errors.push(`${words} mots (minimum ${MIN_WORDS})`);

  const blocks = splitBlocks(content);
  const prose = blocks.filter(
    (block) =>
      !block.startsWith("#") &&
      !block.startsWith("```") &&
      !block.split("\n").every((line) => line.trim().startsWith("- ")) &&
      !block.split("\n").every((line) => /^\d+\.\s+/.test(line.trim())),
  );
  if (prose.length < MIN_PARAGRAPHS) {
    errors.push(`${prose.length} paragraphes (minimum ${MIN_PARAGRAPHS})`);
  }

  const headings = content.match(/^##\s+.*$/gm) ?? [];
  if (headings.length < MIN_HEADINGS) {
    errors.push(`${headings.length} sections ## (minimum ${MIN_HEADINGS})`);
  }
  for (const required of REQUIRED_HEADINGS) {
    if (!headings.some((heading) => heading.trim() === required)) {
      errors.push(`section absente : ${required}`);
    }
  }
  const lastHeading = headings[headings.length - 1] ?? "";
  if (!lastHeading.startsWith(LAST_HEADING_PREFIX)) {
    errors.push(
      `dernière section inattendue : « ${lastHeading} » (attendu : ${LAST_HEADING_PREFIX}…)`,
    );
  }

  const fences = content.match(/^\s*```/gm)?.length ?? 0;
  if (fences > 0 && fences % 2 !== 0) errors.push("blocs ``` non équilibrés");
  if (fences === 0) errors.push("aucun bloc de code ```");

  const backticks = (content.match(/`/g) ?? []).length;
  if (backticks % 2 !== 0) errors.push("backticks non équilibrés");

  // Les interdits s'appliquent au PROSE : les blocs de code ``` sont retirés
  // (un exemple HTML contient légitimement des balises <...>, des #, ---…).
  let proseContent = "";
  let inFence = false;
  for (const line of content.split("\n")) {
    if (line.trimStart().startsWith("```")) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) proseContent += `${line}\n`;
  }

  for (const { label, re } of FORBIDDEN) {
    if (re.test(proseContent)) errors.push(`contenu interdit : ${label}`);
  }

  const name = path.split(/[\\/]/).pop();
  console.log(
    `${errors.length === 0 ? "✓" : "✗"} ${name} — ${words} mots, ${prose.length} paragraphes, ${headings.length} sections, ${fences / 2} bloc(s) de code`,
  );
  for (const error of errors) console.log(`    ! ${error}`);
  return errors.length === 0;
}

const args = process.argv.slice(2);
let files = [];
if (args[0] === "--dir" && args[1]) {
  const dir = resolve(args[1]);
  files = readdirSync(dir)
    .filter((name) => name.endsWith(".txt"))
    .map((name) => `${dir}\\${name}`);
} else {
  files = args;
}

if (files.length === 0) {
  console.error("Aucun fichier. Usage : node scripts/check-lessons.mjs <fichier...> | --dir <dossier>");
  process.exit(1);
}

const results = files.map((file) => {
  let isFile = false;
  try {
    isFile = statSync(file).isFile();
  } catch {
    isFile = false;
  }
  if (!isFile) {
    console.log(`✗ ${file} — fichier introuvable`);
    return { file, ok: false };
  }
  return { file, ok: checkFile(file) };
});

const failed = results.filter((result) => !result.ok);
console.log(
  failed.length === 0
    ? "\n=== TOUTES LES LEÇONS PASSENT ===\n"
    : `\n=== ${failed.length} LEÇON(S) EN ÉCHEC ===\n`,
);
process.exit(failed.length === 0 ? 0 : 1);
