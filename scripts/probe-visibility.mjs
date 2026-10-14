import { chromium } from "playwright-core";

const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\";

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
  page.setDefaultTimeout(90000);
  const errors = [];
  page.on("console", (m) => {
    if (m.type() === "error") errors.push(m.text().slice(0, 250));
  });

  await page.goto("http://localhost:3000/connexion", { waitUntil: "domcontentloaded" });
  await page.fill("#email", "quiz-test@easylearn.dev");
  await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
  await page.click('button[type="submit"]');
  await page.waitForURL((u) => u.pathname === "/", { timeout: 60000 });

  // 1. Dashboard /app : les 6 parcours sont-ils listés ?
  await page.goto("http://localhost:3000/app", { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(3000);
  const dash = await page.innerText("body");
  console.log("=== /app (dashboard) ===");
  for (const t of ["Python :", "Développement web", "Cybersécurité", "Réseaux :", "Intelligence artificielle", "Arduino"])
    console.log(`  ${dash.includes(t) ? "VOIS  " : "PAS VU"} : ${t}`);
  await page.screenshot({ path: OUT + "dash.png" });

  // 2. Catalogue public
  await page.goto("http://localhost:3000/catalogue", { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(3000);
  const cat = await page.innerText("body");
  console.log("=== /catalogue ===");
  for (const t of ["Python", "Développement web", "Cybersécurité", "Réseaux", "Intelligence artificielle", "Arduino"])
    console.log(`  ${cat.includes(t) ? "VOIS  " : "PAS VU"} : ${t}`);
  await page.screenshot({ path: OUT + "catalogue.png" });

  // 3. Page vidéo cyb-c1 : état de l'embed YouTube
  await page.goto("http://localhost:3000/app/parcours/cybersecurite-fondamentaux/chapitres/paysage-menaces?etape=videos", { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(8000);
  const vids = await page.innerText("body");
  console.log("=== cyb-c1 vidéos ===");
  console.log("  progression:", (vids.match(/\d+ \/ \d+ vid[ée]os termin[ée]es/) || ["?"])[0]);
  console.log("  message indispo:", vids.includes("sera ajoutée par le formateur") ? "OUI" : "non");
  const ifr = page.frameLocator('iframe[src*="youtube"]').first();
  const playerBody = await ifr.locator("body").innerText({ timeout: 8000 }).catch(() => "");
  console.log("  texte dans l'iframe YouTube:", playerBody.slice(0, 200).replace(/\n/g, " | ") || "(illisible/cross-origin)");
  await page.screenshot({ path: OUT + "video-step.png" });

  console.log("=== erreurs console ===");
  for (const e of errors.slice(0, 8)) console.log("  !", e);
} finally {
  await browser.close();
}
