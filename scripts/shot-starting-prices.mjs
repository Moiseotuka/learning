import { chromium } from "playwright-core";
import { existsSync } from "node:fs";

const BASE = "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD");
const EDGE =
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

// 1. Landing — section Parcours populaires
await page.goto(`${BASE}/`, { waitUntil: "networkidle" });
const section = page.locator("section#parcours");
await section.scrollIntoViewIfNeeded();
await page.waitForTimeout(1200);
await section.screenshot({ path: `${OUT}\\prices-landing.png` });
console.log("shot: prices-landing");

const landingPrices = await section.evaluate((el) =>
  [...el.querySelectorAll("p")].map((p) => p.textContent?.trim()).filter(Boolean),
);
console.log("texte section parcours :", JSON.stringify(landingPrices));

const cards = await section.evaluate((el) =>
  [...el.querySelectorAll(".rounded-2xl")].map((card) => ({
    titre: card.querySelector("h3")?.textContent?.trim(),
    prix: [...card.querySelectorAll("p")]
      .map((p) => p.textContent?.trim())
      .filter((t) => t && (t.includes("CDF") || t === "Gratuit" || t === "À partir de")),
  })),
);
for (const c of cards) console.log(`  carte: ${c.titre} → prix: ${JSON.stringify(c.prix)}`);

// 2. Vue détail parcours (connecté)
await page.goto(`${BASE}/connexion`, { waitUntil: "networkidle" });
await page.fill("#email", EMAIL);
await page.fill("#password", PASSWORD);
await page.click('button[type="submit"]');
await page.waitForURL((url) => url.pathname === "/", {
  timeout: 20000,
});
await page.goto(`${BASE}/app/parcours/python-developpeur`, {
  waitUntil: "networkidle",
});
await page.waitForTimeout(600);
const header = page.locator("header.rounded-2xl").first();
await header.screenshot({ path: `${OUT}\\prices-track.png` });
console.log("shot: prices-track");

const badges = await header.evaluate((el) =>
  [...el.querySelectorAll("span, p")].map((s) => s.textContent?.trim()).filter(Boolean),
);
const priceBadges = badges.filter((b) => b.includes("CDF") || b === "Gratuit");
console.log("badges prix détail :", JSON.stringify(priceBadges));

await browser.close();
