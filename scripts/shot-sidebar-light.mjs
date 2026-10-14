import { chromium } from "playwright-core";

const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\sidebar-light.png";

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });

await page.goto("http://localhost:3000/connexion", {
  waitUntil: "domcontentloaded",
});
await page.fill("#email", "quiz-test@easylearn.dev");
await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
await page.click('button[type="submit"]');
await page.waitForURL((url) => url.pathname === "/", {
  timeout: 20000,
});
await page.goto(
  "http://localhost:3000/app/parcours/python-developpeur/chapitres/premiers-pas-variables",
  { waitUntil: "domcontentloaded" },
);
await page.evaluate(() => localStorage.setItem("theme", "light"));
await page.reload({ waitUntil: "domcontentloaded" });
await page
  .locator('aside ol[aria-label*="Étapes du chapitre"]')
  .first()
  .waitFor({ timeout: 20000 });
await page.waitForTimeout(600);
const m = await page.evaluate(() => {
  const ol = document.querySelector(
    'aside ol[aria-label*="Étapes du chapitre"]',
  );
  const line = ol.querySelector("span[aria-hidden]").getBoundingClientRect();
  const circle = ol.querySelector("li a > span").getBoundingClientRect();
  const parent = document
    .querySelector('aside a[aria-current="page"] > span:first-child')
    .getBoundingClientRect();
  return {
    lineCenter: line.x + line.width / 2,
    childCircleCenter: circle.x + circle.width / 2,
    parentCircleCenter: parent.x + parent.width / 2,
  };
});
console.log(JSON.stringify(m));
await page.locator("aside").first().screenshot({ path: OUT });
console.log("capture :", OUT);
await browser.close();
