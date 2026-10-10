import { chromium } from "playwright-core";

const BASE = "http://localhost:3000";
const slug = process.argv[2] ?? "premiers-pas-variables";
const track = process.argv[3] ?? "python-developpeur";

const run = async () => {
  const browser = await chromium.launchPersistentContext(
    "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\yt-fresh-profile",
    { executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe", headless: false, viewport: { width: 1280, height: 800 } },
  );
  const page = browser.pages()[0] ?? (await browser.newPage());
  page.on("console", (m) => { if (m.text().includes("[youtube-player]")) console.log("CONSOLE:", m.text()); });
  page.setDefaultTimeout(60000);

  await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1500);
  if (await page.locator("#email").count()) {
    await page.fill("#email", "quiz-test@easylearn.dev");
    await page.fill("#password", "QuizTest2026!");
    await page.click('button[type="submit"]');
  }
  await page.waitForURL((u) => u.pathname === "/" || u.pathname === "/app", { timeout: 60000 });

  await page.goto(`${BASE}/app/parcours/${track}/chapitres/${slug}?etape=videos`, { waitUntil: "domcontentloaded" });

  const state = async () => {
    const t = await page.locator("body").innerText();
    const pause = await page.locator('button[aria-label="Pause"]').count();
    const play = await page.locator('button[aria-label="Lecture"]').count();
    const spinner = await page.locator(".animate-spin").count();
    const time = await page.locator("text=/\\d+:\\d\\d \\/ \\d+:\\d\\d/").count();
    return `blocked=${t.includes("Lecture impossible")} | play=${play} | pause=${pause} | spinner=${spinner} | timecode=${time}`;
  };

  // attend l'état « prêt » (bouton Lecture OU lecture déjà en cours)
  let ready = false;
  for (let i = 0; i < 20 && !ready; i++) {
    await page.waitForTimeout(1000);
    const s = await state();
    if (s.includes("play=1") || s.includes("play=2") || s.includes("pause=1")) ready = true;
  }
  console.log(`état prêt: ${ready} | ${await state()}`);

  if (ready && !(await page.locator('button[aria-label="Pause"]').count())) {
    const play = page.locator('button[aria-label="Lecture"]').last();
    await play.click();
    console.log("clic Lire");
  }
  for (let i = 1; i <= 5; i++) {
    await page.waitForTimeout(2500);
    console.log(`t+${i * 2.5}s | ${await state()}`);
  }
  await page.screenshot({ path: `C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\play-${slug}.png` });
  console.log(`screenshot play-${slug}.png`);
  await browser.close();
};

run().catch((e) => { console.error("ERREUR:", e.message); process.exit(1); });
