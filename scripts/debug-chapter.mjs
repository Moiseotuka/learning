import { chromium } from "playwright-core";
import { existsSync } from "node:fs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD");
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage();

const logs = [];
page.on("console", (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));
page.on("pageerror", (err) => logs.push(`[pageerror] ${err.message}`));

await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
await page.fill("#email", EMAIL);
await page.fill("#password", PASSWORD);
await page.click('button[type="submit"]');
await page.waitForURL((url) => url.pathname === "/", {
  timeout: 20000,
});

const r1 = await page.goto(`${BASE}/app/parcours/python-developpeur`, {
  waitUntil: "domcontentloaded",
});
console.log("OVERVIEW STATUS:", r1?.status());
const r2 = await page.goto(
  `${BASE}/app/parcours/python-developpeur/chapitres/premiers-pas-variables`,
  { waitUntil: "domcontentloaded" },
);
console.log("CHAPTER STATUS:", r2?.status());
const text = await page.innerText("body").catch(() => "(no body)");
console.log("BODY:", text.slice(0, 400).replace(/\n+/g, " | "));
console.log("URL:", page.url());
console.log("--- console/page logs ---");
for (const l of logs.slice(-30)) console.log(l);

await browser.close();
