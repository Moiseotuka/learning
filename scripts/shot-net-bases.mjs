import { chromium } from "playwright-core";

const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\";
const BASE = "http://localhost:3000/app/parcours/reseaux-protocoles-routage/chapitres/bases-reseaux?etape=cours&page=";

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
  page.setDefaultTimeout(30000);
  const errors = [];
  page.on("console", (m) => { if (m.type() === "error") errors.push(m.text().slice(0, 200)); });

  await page.goto("http://localhost:3000/connexion", { waitUntil: "domcontentloaded" });
  await page.fill("#email", "quiz-test@easylearn.dev");
  await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
  await page.click('button[type="submit"]');
  await page.waitForURL((u) => u.pathname === "/", { timeout: 60000 });

  let total = 0;
  let shots = 0;
  for (let n = 1; n <= 16; n++) {
    await page.goto(BASE + n, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    const imgs = await page.evaluate(() =>
      Array.from(document.querySelectorAll("main img")).map((i) => ({
        src: i.getAttribute("src") || "",
        alt: (i.getAttribute("alt") || "").slice(0, 90),
        w: i.naturalWidth,
        h: i.naturalHeight,
      }))
    );
    if (imgs.length) {
      console.log(`page ${n} : ${imgs.length} image(s)`);
      for (const im of imgs) {
        total++;
        const loaded = im.w > 0 ? "CHARGÉE" : "EN ATTENTE";
        console.log(`   [${loaded} ${im.w}x${im.h}] ${im.alt || "(sans alt)"}`);
        console.log(`      ${im.src.slice(0, 110)}`);
      }
      if (shots < 3) {
        await page.locator("main img").first().scrollIntoViewIfNeeded().catch(() => {});
        await page.waitForTimeout(600);
        await page.screenshot({ path: `${OUT}net-bases-page${n}.png` });
        console.log(`   -> capture net-bases-page${n}.png`);
        shots++;
      }
    }
  }
  console.log(`\nTOTAL images affichées dans le cours : ${total} (attendu 8)`);
  console.log("=== erreurs console ===");
  for (const e of errors.slice(0, 6)) console.log("  !", e);
} finally {
  await browser.close();
}
