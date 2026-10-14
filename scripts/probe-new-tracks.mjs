import { chromium } from "playwright-core";

const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\";

const TRACKS = [
  { slug: "cybersecurite-fondamentaux", chapter: "paysage-menaces" },
  { slug: "reseaux-protocoles-routage", chapter: "osi-adressage" },
  { slug: "ia-data-science", chapter: "exploration-donnees" },
  { slug: "arduino-esp32-embarque", chapter: "gpio-premiers-pas" },
];

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
  page.setDefaultTimeout(90000);

  await page.goto("http://localhost:3000/connexion", { waitUntil: "domcontentloaded" });
  await page.fill("#email", "quiz-test@easylearn.dev");
  await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
  await page.click('button[type="submit"]');
  await page.waitForURL((u) => u.pathname === "/", { timeout: 60000 });

  // dashboard
  await page.goto("http://localhost:3000/app", { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(4000);
  const dash = await page.innerText("body");
  console.log("=== /app dashboard ===");
  for (const t of ["Développement web", "Cybersécurité", "Réseaux", "Intelligence artificielle", "Arduino", "Python"])
    console.log(`  ${dash.includes(t) ? "VOIS " : "PAS VU"} ${t}`);
  await page.screenshot({ path: OUT + "dash2.png" });

  for (const t of TRACKS) {
    const url = `http://localhost:3000/app/parcours/${t.slug}/chapitres/${t.chapter}?etape=cours`;
    await page.goto(url, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(3500);
    let body = await page.innerText("body");
    let href = page.url();

    const checks = {
      url: href.replace("http://localhost:3000", ""),
      pagination: (body.match(/\d+ \/ \d+/) || ["?"])[0],
      a_retenir: /À retenir/.test(body),
      mots_corps: body.split(/\s+/).length,
    };
    console.log(`=== ${t.slug} ===`);
    console.log(" ", JSON.stringify(checks));
    await page.screenshot({ path: OUT + `track-${t.slug}.png` });
  }
} finally {
  await browser.close();
}
