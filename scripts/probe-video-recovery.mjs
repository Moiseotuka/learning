import { chromium } from "playwright-core";

const BASE = "http://localhost:3000";

const run = async () => {
  const browser = await chromium.launch({ executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe", headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.setDefaultTimeout(90000);

  // Simule un YouTube inaccessible (bot-check / réseau bloqué)
  await page.route("**://*.youtube.com/**", (route) => route.abort());
  await page.route("**://*.youtube-nocookie.com/**", (route) => route.abort());

  await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
  await page.fill("#email", "quiz-test@easylearn.dev");
  await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
  await page.click('button[type="submit"]');
  await page.waitForURL((u) => u.pathname === "/" || u.pathname === "/app", { timeout: 60000 });

  await page.goto(`${BASE}/app/parcours/cybersecurite-fondamentaux/chapitres/paysage-menaces?etape=videos`, { waitUntil: "domcontentloaded" });

  const markBtn = page.getByRole("button", { name: /Marquer la vidéo comme vue/i }).first();
  await markBtn.waitFor({ state: "visible", timeout: 30000 });
  console.log("✓ RecoveryActions visibles (YouTube bloqué simulé)");

  const counter = async () => {
    const text = await page.locator("body").innerText();
    return (text.match(/(\d+) \/ 3 vidéos terminées/) || [])[1];
  };
  console.log("Compteur initial :", (await counter()) || "0", "/ 3");

  for (let i = 1; i <= 3; i++) {
    await markBtn.click();
    await page.waitForTimeout(2000);
    const c = await counter();
    console.log(`Après clic ${i} :`, c, "/ 3", c === String(i) ? "✓" : "✗");
    if (i < 3) await markBtn.waitFor({ state: "visible", timeout: 15000 }).catch(() => console.log(`✗ Panneau absent pour la vidéo ${i + 1}`));
  }

  const text = await page.locator("body").innerText();
  console.log("3/3 affiché :", text.includes("3 / 3 vidéos terminées"));
  const docLink = page.getByRole("link", { name: /Voir le Cours|leçon|document/i }).first();
  console.log("Lien vers la leçon affiché :", await docLink.isVisible().catch(() => false));

  // accès à l'étape Cours (gate levé)
  await page.goto(`${BASE}/app/parcours/cybersecurite-fondamentaux/chapitres/paysage-menaces?etape=cours`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(2500);
  const cours = await page.locator("body").innerText();
  console.log("Étape Cours accessible après videos :", cours.includes("Page 1 sur") || cours.includes("Objectifs") === false);
  console.log("Redirigé vers vidéos ? :", cours.includes("0 / 3") || cours.includes("1 / 3") || cours.includes("2 / 3") || cours.includes("3 / 3"));

  await browser.close();
};

run().catch((e) => { console.error("ERREUR:", e.message); process.exit(1); });
