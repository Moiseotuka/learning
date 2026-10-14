import { chromium } from "playwright-core";

const BASE = "http://localhost:3000";

const run = async () => {
  const browser = await chromium.launch({ executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe", headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.setDefaultTimeout(60000);

  const logs = [];
  page.on("pageerror", (e) => logs.push(`[pageerror] ${e.message.slice(0, 200)}`));

  await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
  await page.fill("#email", "quiz-test@easylearn.dev");
  await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
  await page.click('button[type="submit"]');
  await page.waitForURL((u) => u.pathname === "/" || u.pathname === "/app", { timeout: 60000 });

  let ready = false;
  for (let attempt = 1; attempt <= 6 && !ready; attempt++) {
    await page.goto(`${BASE}/app/parcours/cybersecurite-fondamentaux/chapitres/paysage-menaces?etape=videos`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(7000);
    const plays = await page.locator('button[aria-label="Lecture"]').count();
    const missing = (await page.locator("body").innerText()).includes("sera ajoutée par le formateur");
    console.log(`essai ${attempt}: boutonLire=${plays} erreur=${missing}`);
    if (plays > 0) ready = true;
  }
  if (!ready) { console.log("✗ jamais passé en état prêt"); await browser.close(); return; }

  const snap = async (label) => {
    const t = await page.locator("body").innerText();
    const pause = await page.locator('button[aria-label="Pause"]').count();
    const times = await page.locator("span.tabular-nums").allInnerTexts().catch(() => []);
    console.log(`${label} | blocked=${t.includes("La vidéo ne se lance pas")} | err=${t.includes("sera ajoutée")} | pauseBtn=${pause} | t=${JSON.stringify(times)}`);
  };

  await snap("avant clic");
  await page.locator('button[aria-label="Lecture"]').last().click();
  console.log("→ clic Lire");
  for (let i = 1; i <= 6; i++) {
    await page.waitForTimeout(2500);
    await snap(`t+${i * 2.5}s`);
  }
  await page.screenshot({ path: "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\play-after-click.png" });
  console.log("Screenshot pris", logs.length ? logs : "");
  await browser.close();
};

run().catch((e) => { console.error("ERREUR:", e.message); process.exit(1); });
