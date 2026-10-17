// Génère la famille de logos easyTech à partir d'un emblème vectoriel unique
// (globe + toque de diplômé, inspiré du visuel fourni) aux couleurs de la
// marque (tokens de src/app/globals.css). Les PNG de public/ sont rastérisés
// par Edge headless (playwright-core, même principe que les tests e2e) avec
// fond transparent.
//
//   node scripts/build-logo.mjs
//
import { chromium } from "playwright-core";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { tmpdir } from "node:os";
import { join } from "node:path";

const CANDIDATS = [
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
];
const EDGE = process.env.QUIZ_TEST_BROWSER ?? CANDIDATS.find(existsSync);
if (!EDGE) {
  console.error("Edge introuvable");
  process.exit(1);
}

/* Couleurs de marque (src/app/globals.css) */
const VERT_CLAIR = "#15803d"; // --primary clair
const VERT_SOMBRE = "#22c55e"; // --primary sombre
const VERT_ICONE = "#16a34a"; // --vivid clair, lisible sur les deux fonds
const VERT_VIF = "#16a34a"; // accent « Tech » du logotype clair

/* Emblème vectoriel dans un viewBox 0 0 100 100 : toque (plateau + bandeau +
   bouton évidé + dragonne à pompon) posée sur un globe filaire, le tout cerclé
   d'une orbite. La couleur est injectée directement (pas de currentColor :
   le générateur d'images de next/og ne le suit pas toujours). */
const EMBLEME = (c) => /* svg */ `
  <g fill="none" stroke="${c}" stroke-linecap="round">
    <path d="M19 73 A 36 32 0 0 0 83 71" stroke-width="6"/>
    <circle cx="50" cy="60" r="25" stroke-width="5.5"/>
    <ellipse cx="50" cy="60" rx="11.5" ry="25" stroke-width="4.5"/>
    <path d="M28 49 H72 M28 71 H72" stroke-width="4.5"/>
  </g>
  <path d="M37 32 h26 v8 a3 3 0 0 1 -3 3 h-20 a3 3 0 0 1 -3 -3 Z" fill="${c}"/>
  <path d="M50 7 L91 21 L50 35 L9 21 Z M50 7.6 a3.4 3.4 0 1 0 0.01 0" fill-rule="evenodd" fill="${c}"/>
  <path d="M50 11 C60 4 73 9 75 20 L75 30" fill="none" stroke="${c}" stroke-width="3.5" stroke-linecap="round"/>
  <circle cx="75" cy="34.5" r="5" fill="${c}"/>
`;

const embleme = (couleur, px) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="${px}" height="${px}">${EMBLEME(couleur)}</svg>`;

/* Icône seule : carré arrondi vert, emblème blanc — cohérent avec icon.svg */
const icone = (px) => {
  const cote = px;
  const echelle = (cote * 0.59) / 100;
  const marge = (cote - 100 * echelle) / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${cote} ${cote}" width="${cote}" height="${cote}">
    <rect width="${cote}" height="${cote}" rx="${cote * 0.225}" fill="${VERT_ICONE}"/>
    <g transform="translate(${marge} ${marge + cote * 0.03}) scale(${echelle})">${EMBLEME("#ffffff")}</g>
  </svg>`;
};

/* Logotype horizontal 960x256 : emblème à gauche, « easyTech » à droite —
   tout en verts de marque : easy dans le vert primaire, Tech dans un vert
   plus vif (le noir d'origine tranchait avec l'identité verte du site). */
const logotype = (couleurEmbleme, couleurEasy, couleurTech) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 256" width="960" height="256">
    <g transform="translate(28 37) scale(2.0)">${EMBLEME(couleurEmbleme)}</g>
    <text x="248" y="134" font-family="Inter, 'Segoe UI', Arial, sans-serif" font-size="122"
      font-weight="800" letter-spacing="-2" dominant-baseline="central">
      <tspan fill="${couleurEasy}">easy</tspan><tspan fill="${couleurTech}">Tech</tspan>
    </text>
  </svg>`;

const sections = [
  ["icon-256", icone(256), 256, 256],
  ["icon-512", icone(512), 512, 512],
  ["icon-1024", icone(1024), 1024, 1024],
  ["type-fonce", logotype(VERT_CLAIR, VERT_CLAIR, VERT_VIF), 960, 256],
  ["type-blanc", logotype(VERT_SOMBRE, "#ffffff", VERT_SOMBRE), 960, 256],
];

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  body { margin: 0; background: transparent; }
  section { display: block; width: fit-content; }
</style></head><body>
${sections
  .map(
    ([id, svg, l, h]) =>
      `<section id="${id}" style="width:${l}px;height:${h}px">${svg}</section>`,
  )
  .join("\n")}
</body></html>`;

const cheminHtml = join(tmpdir(), "easytech-logo.html");
writeFileSync(cheminHtml, html);

const SORTIES = {
  "icon-256": "public/easytech-logo-256.png",
  "icon-512": "public/easytech-logo-512.png",
  "icon-1024": "public/easytech-logo-1024.png",
  "type-fonce": "public/easytech-logo-texte-fonce.png",
  "type-blanc": "public/easytech-logo-texte-blanc.png",
};

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1100, height: 2400 } });
await page.goto(pathToFileURL(cheminHtml).href);
for (const [id, sortie] of Object.entries(SORTIES)) {
  await page.locator(`#${id}`).screenshot({ path: sortie, omitBackground: true });
  console.log("ok:", sortie);
}
await browser.close();

/* favicon.ico (src/app/favicon.ico) : conteneur ICO avec le PNG 256 embarqué
   (format valide depuis Vista, accepté par tous les navigateurs). */
const pngIcone = readFileSync("public/easytech-logo-256.png");
const entete = Buffer.alloc(6);
entete.writeUInt16LE(0, 0); // réservé
entete.writeUInt16LE(1, 2); // type = icône
entete.writeUInt16LE(1, 4); // 1 image
const entree = Buffer.alloc(16);
entree[0] = 0; // 256 px (0 = 256)
entree[1] = 0;
entree[2] = 0; // palette
entree[3] = 0; // réservé
entree.writeUInt16LE(1, 4); // plans
entree.writeUInt16LE(32, 6); // bits par pixel
entree.writeUInt32LE(pngIcone.length, 8);
entree.writeUInt32LE(22, 12); // décalage des données PNG
writeFileSync("src/app/favicon.ico", Buffer.concat([entete, entree, pngIcone]));
console.log("ok: src/app/favicon.ico");
