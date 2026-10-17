// Recoloration des logos easyTech : le bleu d'origine est remplace par le vert
// de la marque (tokens de src/app/globals.css), en conservent les contours
// anti-aliases. On ne touche qu'aux pixels de la famille bleue (teinte 190-260)
// : le triangle blanc, le texte « easy » et la transparence restent intacts.
//
//   node scripts/recolor-logo.mjs           # applique la recoloration
//   node scripts/recolor-logo.mjs --dry     # mesure sans ecrire
//
import { PNG } from "pngjs";
import { readFileSync, writeFileSync } from "node:fs";

const dryRun = process.argv.includes("--dry");

// Cible par fichier : clair = primary #15803d, sombre = primary #22c55e,
// icones seules = #16a34a (lisible sur fond clair comme sombre).
const JOBS = [
  { file: "public/easytech-logo-256.png", hex: "#16a34a" },
  { file: "public/easytech-logo-512.png", hex: "#16a34a" },
  { file: "public/easytech-logo-1024.png", hex: "#16a34a" },
  { file: "public/easytech-logo-texte-fonce.png", hex: "#15803d" },
  { file: "public/easytech-logo-texte-blanc.png", hex: "#22c55e" },
];

function rgbToHsl(r, g, b) {
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  if (max === min) return [0, 0, l];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  if (max === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
  else if (max === g) h = ((b - r) / d + 2) / 6;
  else h = ((r - g) / d + 4) / 6;
  return [h, s, l];
}

function hueToRgb(p, q, t) {
  if (t < 0) t += 1;
  if (t > 1) t -= 1;
  if (t < 1 / 6) return p + (q - p) * 6 * t;
  if (t < 1 / 2) return q;
  if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
  return p;
}

function hslToRgb(h, s, l) {
  if (s === 0) return [l, l, l];
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  return [hueToRgb(p, q, h + 1 / 3), hueToRgb(p, q, h), hueToRgb(p, q, h - 1 / 3)];
}

const hexToRgb = (hex) => {
  const n = parseInt(hex.slice(1), 16);
  return [((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255];
};

// Famille bleue du logo (le bleu d'origine tourne autour de 215 deg).
const isBleu = (h, s) => h >= 0.5 && h <= 0.75 && s >= 0.1;

for (const job of JOBS) {
  const png = PNG.sync.read(readFileSync(job.file));
  const { width, height, data } = png;

  // Luminance du bleu « plein » : mediane des pixels bleus opaques, pour
  // ancrer le remappage de luminosite sur la vraie couleur de base.
  const lumi = [];
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] < 240) continue;
    const [h, s, l] = rgbToHsl(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255);
    if (s > 0.6 && isBleu(h, s)) lumi.push(l);
  }
  lumi.sort((a, b) => a - b);
  const lCore = lumi[Math.floor(lumi.length / 2)];
  const [hCible, , lCible] = rgbToHsl(...hexToRgb(job.hex));

  let touches = 0;
  for (let i = 0; i < data.length; i += 4) {
    const [h, s, l] = rgbToHsl(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255);
    if (!isBleu(h, s)) continue;
    const lNouveau = Math.min(1, (l / lCore) * lCible);
    const [r, g, b] = hslToRgb(hCible, s, lNouveau);
    data[i] = Math.round(r * 255);
    data[i + 1] = Math.round(g * 255);
    data[i + 2] = Math.round(b * 255);
    touches += 1;
  }

  const part = ((touches / (width * height)) * 100).toFixed(1);
  console.log(`${dryRun ? "[dry] " : ""}${job.file} -> ${job.hex} (${touches} px, ${part}%)`);
  if (!dryRun) writeFileSync(job.file, PNG.sync.write(png));
}
