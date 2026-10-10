import { chromium } from "playwright-core";
import { existsSync } from "node:fs";

const BASE = "http://localhost:3000";
const EDGE =
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}

const browser = await chromium.launch({ executablePath: EDGE, headless: true });

// Desktop full page (scroll d'abord pour déclencher les animations de révélation)
const desktop = await browser.newPage({ viewport: { width: 1440, height: 900 } });
await desktop.goto(`${BASE}/`, { waitUntil: "networkidle" });
const height = await desktop.evaluate(() => document.body.scrollHeight);
for (let y = 0; y < height; y += 700) {
  await desktop.evaluate((v) => window.scrollTo(0, v), y);
  await desktop.waitForTimeout(150);
}
await desktop.evaluate(() => window.scrollTo(0, 0));
await desktop.waitForTimeout(800);
await desktop.screenshot({ path: `${OUT}\\land-desktop-full.png`, fullPage: true });
console.log("shot: land-desktop-full");

// Sections repérées
const ids = await desktop.evaluate(() =>
  [...document.querySelectorAll("section[id], [id]")].map((el) => el.id).filter(Boolean),
);
console.log("ids:", JSON.stringify([...new Set(ids)]));

// Liens internes de la page
const links = await desktop.evaluate(() =>
  [...document.querySelectorAll("a[href]")]
    .map((a) => `${a.textContent?.trim().slice(0, 40)} → ${a.getAttribute("href")}`)
    .slice(0, 60),
);
console.log("links:");
for (const l of links) console.log("  ", l);
await desktop.close();

// Mobile full page
const mobile = await browser.newPage({ viewport: { width: 390, height: 844 } });
await mobile.goto(`${BASE}/`, { waitUntil: "networkidle" });
await mobile.waitForTimeout(1200);
await mobile.screenshot({ path: `${OUT}\\land-mobile-full.png`, fullPage: true });
console.log("shot: land-mobile-full");
await mobile.close();

await browser.close();
