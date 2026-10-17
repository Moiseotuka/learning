// Découpe l'apprenante du hero : le fond vert uni de la photo générée devient
// transparent (clé chromatique sur la dominance de vert du fond), puis l'image
// est rognée sur son contenu. La personne peut ainsi flotter sur la bande verte
// du hero, comme sur la maquette de référence, sans bord rectangulaire.
//
//   node scripts/cutout-hero.mjs
//
import { readFileSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";

const SOURCE = "public/hero-apprenante.png";

const png = PNG.sync.read(readFileSync(SOURCE));
const { width, height, data } = png;

/* Couleur de fond = moyenne des quatre coins (5 px vers l'intérieur). */
const coins = [
  [5, 5],
  [width - 6, 5],
  [5, height - 6],
  [width - 6, height - 6],
];
const fond = coins
  .map(([x, y]) => {
    const i = (y * width + x) * 4;
    return [data[i], data[i + 1], data[i + 2]];
  })
  .reduce((a, c) => [a[0] + c[0] / 4, a[1] + c[1] / 4, a[2] + c[2] / 4], [0, 0, 0]);
console.log("fond detecte :", fond.map((v) => Math.round(v)).join(","));

/* Alpha : le fond est vert (G nettement au-dessus de R et B). On ne rend
   transparents que les pixels à la fois verts et proches du fond — les cheveux
   sombres neutres et le pull orange restent opaques. Rampe de 25 à 110 pour
   conserver un liseré adouci sur les contours. */
const SEUIL_BAS = 25;
const SEUIL_HAUT = 110;

for (let i = 0; i < width * height; i++) {
  const o = i * 4;
  const [r, g, b] = [data[o], data[o + 1], data[o + 2]];
  const dr = r - fond[0];
  const dg = g - fond[1];
  const db = b - fond[2];
  const distance = Math.sqrt(dr * dr + dg * dg + db * db);
  const vert = g > r + 12 && g > b + 12;

  if (distance < 12 || (vert && distance < SEUIL_BAS)) {
    data[o + 3] = 0;
  } else if (vert && distance < SEUIL_HAUT) {
    data[o + 3] = Math.round(((distance - SEUIL_BAS) / (SEUIL_HAUT - SEUIL_BAS)) * 255);
  }
}

/* Rognage : boîte englobante des pixels visibles, +6 px de marge. */
let xMin = width;
let yMin = height;
let xMax = 0;
let yMax = 0;
for (let y = 0; y < height; y++) {
  for (let x = 0; x < width; x++) {
    if (data[(y * width + x) * 4 + 3] > 10) {
      if (x < xMin) xMin = x;
      if (x > xMax) xMax = x;
      if (y < yMin) yMin = y;
      if (y > yMax) yMax = y;
    }
  }
}
xMin = Math.max(0, xMin - 6);
yMin = Math.max(0, yMin - 6);
xMax = Math.min(width - 1, xMax + 6);
yMax = Math.min(height - 1, yMax + 6);

const largeur = xMax - xMin + 1;
const hauteur = yMax - yMin + 1;
const rogne = new PNG({ width: largeur, height: hauteur });
for (let y = 0; y < hauteur; y++) {
  const source = ((yMin + y) * width + xMin) * 4;
  data.copy(rogne.data, y * largeur * 4, source, source + largeur * 4);
}

writeFileSync(SOURCE, PNG.sync.write(rogne));
console.log(`ok: ${SOURCE} ${largeur}x${hauteur} (aspect ${(largeur / hauteur).toFixed(3)})`);
