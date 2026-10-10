import { chromium } from "playwright-core";
import { existsSync } from "node:fs";

const BASE = "http://localhost:3000";
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT =
  process.env.SHOT_DIR ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";

let failures = 0;
const check = (label, ok, detail) => {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
};

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

try {
  // ---- 1. Landing → « Voir la catégorie » ---------------------------------
  console.log("1. Voir la catégorie (landing)");
  await page.goto(`${BASE}/`, { waitUntil: "networkidle" });
  const firstCta = page.getByRole("link", { name: /Voir la catégorie/ }).first();
  const ctaText = (await firstCta.evaluate((a) => a.closest("article")?.querySelector("h3")?.textContent)) ?? "";
  console.log(`   catégorie cliquée : ${ctaText}`);
  await firstCta.click();
  await page.waitForURL(/\/catalogue\?tech=/, { timeout: 15000 });
  const tech = new URL(page.url()).searchParams.get("tech");
  check("URL filtrée ?tech=", Boolean(tech), page.url());

  await page.waitForLoadState("networkidle");
  const results = await page.locator('section[aria-label] a, section[aria-label] article').count();
  const resultsText = await page.locator("text=/résultat/i").first().innerText().catch(() => "");
  console.log(`   résultats : ${resultsText.trim()} — cartes : ${results}`);
  check("au moins 1 carte de parcours affichée", results >= 1, `${results}`);

  const active = await page
    .locator('aside a.bg-electric\\/10, aside a[class*="text-electric"]')
    .first()
    .innerText()
    .catch(() => "");
  console.log(`   sidebar active : ${active.replace(/\s+/g, " ").trim()}`);
  check("catégorie active en surbrillance dans la sidebar", active.toLowerCase().length > 0, active.trim());
  await page.screenshot({ path: `${OUT}\\catalog-filtered.png` });
  console.log("  shot: catalog-filtered");

  // ---- 2. « Tout » restaure la liste complète ------------------------------
  console.log("2. Filtre Tout");
  await page.getByRole("link", { name: /Tout/i }).first().click();
  await page.waitForURL(/\/catalogue$/, { timeout: 15000 });
  check("retour sans paramètre", !page.url().includes("tech="), page.url());

  // ---- 3. Landing → « Détail du parcours » --------------------------------
  console.log("3. Détail du parcours (landing)");
  await page.goto(`${BASE}/`, { waitUntil: "networkidle" });
  const trackCta = page.getByRole("link", { name: /Détail du parcours/ }).first();
  await trackCta.click();
  await page.waitForURL(/\/catalogue\?tech=/, { timeout: 15000 });
  check(
    "URL filtrée par la catégorie du parcours",
    page.url().includes("tech="),
    page.url(),
  );
  await page.waitForLoadState("networkidle");
  const trackResults = await page.locator("section[aria-label] article").count();
  check("cartes affichées", trackResults >= 1, `${trackResults}`);

  // ---- 4. Onglet Tutoriels conserve le filtre ------------------------------
  console.log("4. Bascule Tutoriels conserve le filtre");
  const tech2 = new URL(page.url()).searchParams.get("tech");
  await page.getByRole("tab", { name: /Tutoriels/i }).click();
  await page.waitForURL(/type=tutoriels/, { timeout: 15000 });
  const url = new URL(page.url());
  check(
    "type=tutoriels + tech conservé",
    url.searchParams.get("type") === "tutoriels" &&
      url.searchParams.get("tech") === tech2,
    page.url(),
  );
} catch (error) {
  console.error("ERREUR:", error.message);
  failures += 1;
  await page
    .screenshot({ path: `${OUT}\\catalog-links-error.png` })
    .catch(() => undefined);
} finally {
  await browser.close();
}

console.log(
  failures === 0
    ? "\n=== LIENS CATALOGUE : TOUS LES TESTS PASSENT ==="
    : `\n=== ${failures} ÉCHEC(S) ===`,
);
process.exit(failures === 0 ? 0 : 1);
