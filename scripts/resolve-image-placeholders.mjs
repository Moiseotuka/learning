/**
 * Remplace dans content/lessons/*.txt les placeholders d'images de la forme
 *
 *   ```image
 *   cle-manifeste
 *   | Légende
 *   ```
 *
 * par l'URL publique correspondante (content/image-manifest.json).
 * Les blocs déjà en https:// sont laissés intacts. Code 1 si une clé est inconnue
 * ou si un bloc image est mal formé.
 *
 * Usage : node scripts/resolve-image-placeholders.mjs [--dry]
 */
import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(new URL("..", import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, "$1"));
const LESSONS = resolve(ROOT, "content/lessons");
const MANIFEST = resolve(ROOT, "content/image-manifest.json");
const dry = process.argv.includes("--dry");

const manifest = JSON.parse(readFileSync(MANIFEST, "utf8"));
const errors = [];
let replaced = 0;
let kept = 0;

for (const name of readdirSync(LESSONS).filter((n) => n.endsWith(".txt"))) {
  const path = resolve(LESSONS, name);
  const text = readFileSync(path, "utf8");
  const out = text.replace(/```image\n([\s\S]*?)```/g, (block, body) => {
    const lines = body.replace(/\r/g, "").split("\n");
    while (lines.length && lines[0].trim() === "") lines.shift();
    while (lines.length && lines[lines.length - 1].trim() === "") lines.pop();
    const first = (lines[0] ?? "").trim();
    if (first.startsWith("https://")) { kept++; return block; }
    const entry = manifest[first];
    if (!entry?.url) {
      errors.push(`${name} : clé image inconnue « ${first} »`);
      return block;
    }
    const rest = lines.slice(1);
    const captionIdx = rest.findIndex((l) => l.trim().startsWith("|"));
    if (captionIdx === -1) {
      errors.push(`${name} : bloc image sans légende (« | … ») pour la clé ${first}`);
      return block;
    }
    replaced++;
    return "```image\n" + [entry.url, ...rest].join("\n") + "\n```";
  });
  if (out !== text) {
    if (dry) console.log(`(dry) ${name} : mise à jour`);
    else { writeFileSync(path, out, "utf8"); console.log(`✓ ${name} : images résolues`); }
  }
}

if (errors.length) {
  console.error(`\n${errors.length} erreur(s) :`);
  for (const e of errors) console.error("  ✗ " + e);
  process.exit(1);
}
console.log(`\n${replaced} placeholder(s) résolu(s), ${kept} URL déjà présentes.`);
