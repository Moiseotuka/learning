import { chromium } from "playwright-core";
const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\";
const T = [
  { n: "ard-c7", p: 18, u: "http://localhost:3000/app/parcours/arduino-esp32-embarque/chapitres/temps-reel-freertos?etape=cours&page=" },
  { n: "cyb-c8", p: 17, u: "http://localhost:3000/app/parcours/cybersecurite-fondamentaux/chapitres/investigation-numerique?etape=cours&page=" },
  { n: "ia-c10", p: 16, u: "http://localhost:3000/app/parcours/ia-data-science/chapitres/series-temporelles?etape=cours&page=" },
  { n: "net-c11", p: 18, u: "http://localhost:3000/app/parcours/reseaux-protocoles-routage/chapitres/haute-dispo-reseau?etape=cours&page=" },
  { n: "web-c9", p: 16, u: "http://localhost:3000/app/parcours/developpement-web-moderne/chapitres/react-hooks-avances?etape=cours&page=" },
];
const b = await chromium.launch({ executablePath: EDGE, headless: true });
try {
  const p = await b.newPage({ viewport: { width: 1400, height: 1000 } });
  p.setDefaultTimeout(30000);
  const errs = [];
  p.on("console", (m) => { if (m.type() === "error") errs.push(m.text().slice(0, 140)); });
  await p.goto("http://localhost:3000/connexion", { waitUntil: "domcontentloaded" });
  await p.fill("#email", "quiz-test@easylearn.dev");
  await p.fill("#password", "QuizTest2026!");
  await p.click('button[type="submit"]');
  await p.waitForURL((u) => u.pathname === "/", { timeout: 60000 });
  for (const t of T) {
    let total = 0, loaded = 0, shots = 0;
    for (let n = 1; n <= t.p; n++) {
      await p.goto(t.u + n, { waitUntil: "networkidle" });
      await p.waitForTimeout(600);
      const imgs = await p.evaluate(() => Array.from(document.querySelectorAll("main img")).map((i) => ({ w: i.naturalWidth, alt: (i.alt || "").slice(0, 60) })));
      if (imgs.length) {
        for (const im of imgs) { total++; if (im.w > 0) loaded++; else console.log(`   EN ATTENTE ${t.n} p${n}: ${im.alt}`); }
        if (shots < 1) {
          await p.locator("main img").first().scrollIntoViewIfNeeded().catch(() => {});
          await p.waitForTimeout(500);
          await p.screenshot({ path: `${OUT}${t.n}-p${n}.png` });
          shots++;
        }
      }
    }
    console.log(`${t.n} : ${total} images, ${loaded} chargées`);
  }
  console.log("erreurs console:", errs.slice(0, 5));
} finally { await b.close(); }
