import { chromium } from "playwright-core";

const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\cours.png";

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });

await page.goto("http://localhost:3000/connexion", {
  waitUntil: "domcontentloaded",
});
await page.fill("#email", "quiz-test@easylearn.dev");
await page.fill("#password", "QuizTest2026!");
await page.click('button[type="submit"]');
await page.waitForURL((url) => url.pathname === "/", {
  timeout: 20000,
});
await page.goto(
  "http://localhost:3000/app/parcours/python-developpeur/chapitres/premiers-pas-variables?etape=cours&page=4",
  { waitUntil: "domcontentloaded" },
);
await page.waitForSelector("main table", { timeout: 20000 });
await page.waitForTimeout(500);
await page.locator("main table").first().screenshot({ path: OUT });
console.log("capture :", OUT);
await browser.close();
