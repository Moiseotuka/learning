import { chromium } from "playwright-core";

const BASE = "http://localhost:3000";
const EDGE =
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });

await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
await page.fill("#email", "quiz-test@easylearn.dev");
await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
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

const metrics = await page.evaluate(() => {
  const ol = document.querySelector(
    'aside ol[aria-label*="Étapes du chapitre"]',
  );
  const line = ol?.querySelector("span[aria-hidden]");
  const circles = [...(ol?.querySelectorAll("li a > span") ?? [])].map((s) => {
    const r = s.getBoundingClientRect();
    return { center: r.x + r.width / 2, left: r.x, w: r.width };
  });
  const lineRect = line ? line.getBoundingClientRect() : null;
  const olRect = ol.getBoundingClientRect();
  const parentCircle = document.querySelector(
    'aside a[aria-current="page"] > span:first-child',
  );
  const pc = parentCircle?.getBoundingClientRect();
  const rowLink = document.querySelector('aside a[aria-current="page"]');
  const rowRect = rowLink?.getBoundingClientRect();
  return {
    olX: olRect.x,
    lineX: lineRect?.x ?? null,
    circles,
    parentCircleCenter: pc ? pc.x + pc.width / 2 : null,
    parentRowX: rowRect?.x ?? null,
    lineTop: lineRect?.y ?? null,
    lineBottom: lineRect ? lineRect.y + lineRect.height : null,
    olTop: olRect.y,
    olBottom: olRect.y + olRect.height,
    firstCircleTop: circles[0] ? ol.querySelector("li a > span").getBoundingClientRect().y : null,
    lastCircleBottom: circles.length
      ? (() => {
          const all = ol.querySelectorAll("li a > span");
          const r = all[all.length - 1].getBoundingClientRect();
          return r.y + r.height;
        })()
      : null,
  };
});
console.log(JSON.stringify(metrics, null, 2));
await browser.close();
