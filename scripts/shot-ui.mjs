import { chromium } from "playwright-core";
import { existsSync, mkdirSync } from "node:fs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD");
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT =
  process.env.SHOT_DIR ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}
mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

const shot = async (name) => {
  const path = `${OUT}\\${name}.png`;
  await page.screenshot({ path });
  console.log("shot:", path);
};

// 1. Landing
await page.goto(`${BASE}/`, { waitUntil: "networkidle" });
await shot("ui-landing");

// 2. Connexion (header minimal attendu)
await page.goto(`${BASE}/connexion`, { waitUntil: "networkidle" });
await shot("ui-connexion");

// 3. Dashboard apprenant (header app attendu)
await page.fill("#email", EMAIL);
await page.fill("#password", PASSWORD);
await page.click('button[type="submit"]');
await page.waitForURL((url) => url.pathname === "/", {
  timeout: 20000,
});
await page.goto(`${BASE}/app`, { waitUntil: "networkidle" });
await shot("ui-dashboard");

// 4. Catalogue (header marketing attendu)
await page.goto(`${BASE}/catalogue`, { waitUntil: "networkidle" });
await shot("ui-catalogue");

// 5. Chapitre (header player, pas d'app header)
await page.goto(
  `${BASE}/app/parcours/python-developpeur/chapitres/premiers-pas-variables`,
  { waitUntil: "networkidle" },
);
await shot("ui-chapitre");

await browser.close();
