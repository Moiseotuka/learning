import { chromium } from "playwright-core";

const BASE = "http://localhost:3000";

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
    await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
    await page.click('button[type="submit"]');
  }
  await page.waitForURL((u) => u.pathname === "/" || u.pathname === "/app", { timeout: 60000 });

  // Vidéo Python FR (même chaîne avant/après : chaîne inconnue du "bot-check"?)
  await page.goto(`${BASE}/app/parcours/python-developpeur/chapitres/premiers-pas-variables?etape=videos`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(6000);
  const t0 = await page.locator("body").innerText();
  console.log(`avant | err=${t0.includes("Lecture impossible")}`);

  const play = page.locator('button[aria-label="Lecture"]').last();
  if (await play.count()) {
    await play.click();
    console.log("clic Lire");
    for (let i = 1; i <= 4; i++) {
      await page.waitForTimeout(2500);
      const t = await page.locator("body").innerText();
      const pause = await page.locator('button[aria-label="Pause"]').count();
      console.log(`t+${i * 2.5}s | blocked=${t.includes("Lecture impossible")} | pauseBtn=${pause}`);
    }
  } else console.log("pas de bouton Lecture");

  await page.screenshot({ path: "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\py-c1-play.png" });
  console.log("screenshot py-c1-play.png");
  await browser.close();
};

run().catch((e) => { console.error("ERREUR:", e.message); process.exit(1); });
