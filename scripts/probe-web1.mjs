import { chromium } from "playwright-core";

const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const base =
  "http://localhost:3000/app/parcours/developpement-web-moderne/chapitres/html-semantique";

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
  await page.goto("http://localhost:3000/connexion", { waitUntil: "domcontentloaded" });
  await page.fill("#email", "quiz-test@easylearn.dev");
  await page.fill("#password", "QuizTest2026!");
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", { timeout: 20000 });

  await page.goto(`${base}/quiz`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(2000);
  const body1 = await page.innerText("body");
  console.log(
    "quiz — radios:", await page.locator("input[type=radio]").count(),
    "| q1 visible:", body1.includes("Combien de balises"),
  );

  await page.goto(`${base}?etape=ressources`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1500);
  const body2 = await page.innerText("body");
  console.log(
    "ressources — MDN:", body2.includes("MDN"),
    "| w3.org:", body2.includes("w3.org"),
    "| liens http:", await page.locator('main a[href^="http"]').count(),
    "| boutons:", await page.locator("main button").count(),
  );

  await page.goto(`${base}?etape=exercice`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1500);
  const body3 = await page.innerText("body");
  console.log(
    "exercice — Pratiquer:", body3.includes("Pratiquer"),
    "| éditeurs:", await page.locator(".cm-editor").count(),
    "| consigne:", body3.includes("Exercice"),
  );
} finally {
  await browser.close();
}
