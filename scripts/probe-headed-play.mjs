import { chromium } from "playwright-core";

const BASE = "http://localhost:3000";

const run = async () => {
  // Fenêtre visible + profil vierge = proche d'un vrai apprenant
  const browser = await chromium.launchPersistentContext(
    "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\yt-fresh-profile",
    {
      executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
      headless: false,
      viewport: { width: 1280, height: 800 },
    },
  );
  const page = browser.pages()[0] ?? (await browser.newPage());
  page.on("console", (m) => {
    if (m.text().includes("[youtube-player]")) console.log("CONSOLE:", m.text());
  });
  page.setDefaultTimeout(60000);

  await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1500);
  if (await page.locator("#email").count()) {
    await page.fill("#email", "quiz-test@easylearn.dev");
    await page.fill("#password", "QuizTest2026!");
    await page.click('button[type="submit"]');
  }
  await page.waitForURL((u) => u.pathname === "/" || u.pathname === "/app", { timeout: 60000 });

  await page.goto(`${BASE}/app/parcours/cybersecurite-fondamentaux/chapitres/paysage-menaces?etape=videos`, { waitUntil: "domcontentloaded" });

  // attend l'état « prêt » (bouton Lire), rechargements multiples si erreur
  const play = page.locator('button[aria-label="Lecture"]').last();
  let ok = false;
  for (let attempt = 1; attempt <= 4 && !ok; attempt++) {
    if (attempt > 1) {
      await page.goto(`${BASE}/app/parcours/cybersecurite-fondamentaux/chapitres/paysage-menaces?etape=videos`, { waitUntil: "domcontentloaded" });
      console.log(`rechargement ${attempt}…`);
    }
    for (let i = 0; i < 12; i++) {
      await page.waitForTimeout(1000);
      if ((await play.count()) > 0) { ok = true; break; }
    }
  }
  console.log("état prêt atteint:", ok);

  const snap = async (label) => {
    const t = await page.locator("body").innerText();
    const pause = await page.locator('button[aria-label="Pause"]').count();
    const times = await page.locator("span.tabular-nums").allInnerTexts().catch(() => []);
    console.log(`${label} | err=${t.includes("Lecture impossible") || t.includes("sera ajout")} | blocked=${t.includes("La vidéo ne se lance pas")} | pauseBtn=${pause} | t=${JSON.stringify(times.slice(0, 2))}`);
  };

  await snap("avant clic");
  if (ok) {
    await play.click();
    console.log("→ clic Lire");
    for (let i = 1; i <= 5; i++) {
      await page.waitForTimeout(2500);
      await snap(`t+${i * 2.5}s`);
    }
  }

  await page.screenshot({ path: "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\headed-play.png" });
  console.log("Screenshot: headed-play.png");
  await browser.close();
};

run().catch((e) => { console.error("ERREUR:", e.message); process.exit(1); });
