import { chromium } from "playwright-core";
import { existsSync } from "node:fs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD");
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT =
  process.env.SHOT_PATH ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\sidebar.png";

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });

await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
await page.fill("#email", EMAIL);
await page.fill("#password", PASSWORD);
await page.click('button[type="submit"]');
await page.waitForURL((url) => url.pathname === "/", {
  timeout: 20000,
});
await page.goto(
  `${BASE}/app/parcours/python-developpeur/chapitres/premiers-pas-variables`,
  { waitUntil: "domcontentloaded" },
);
await page
  .locator('aside ol[aria-label*="Étapes du chapitre"]')
  .first()
  .waitFor({ timeout: 20000 });
await page.waitForTimeout(600);
await page.locator("aside").first().screenshot({ path: OUT });
console.log("capture :", OUT);
await browser.close();
