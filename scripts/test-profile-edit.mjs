/**
 * Vérification de la page Profil modifiable :
 * bouton « Modifier » → upload photo → champs (téléphone) → enregistrement
 * → rafraîchissement du header → capture.
 *
 * Nécessite la migration 202610040002_profil_editable.sql collée en base.
 */
import { chromium } from "playwright-core";
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? "QuizTest2026!";
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT =
  process.env.TEMP ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";

let failures = 0;
const check = (label, ok, detail = "") => {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
};

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}
mkdirSync(OUT, { recursive: true });

const png = new PNG({ width: 96, height: 96 });
for (let y = 0; y < 96; y++) {
  for (let x = 0; x < 96; x++) {
    const i = (y * 96 + x) * 4;
    const border = x < 6 || y < 6 || x > 89 || y > 89;
    png.data[i] = border ? 16 : 46;
    png.data[i + 1] = border ? 185 : 200;
    png.data[i + 2] = border ? 129 : 150;
    png.data[i + 3] = 255;
  }
}
const avatarPath = `${OUT}\\test-avatar.png`;
writeFileSync(avatarPath, PNG.sync.write(png));

const PHONE = "+33 6 11 22 33 44";

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });

  console.log("\n1. Connexion + page Profil");
  await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
  await page.fill("#email", EMAIL);
  await page.fill("#password", PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", {
    timeout: 20000,
  });
  await page.goto(`${BASE}/app/profil`, { waitUntil: "networkidle" });

  const body0 = (await page.innerText("body")).toLowerCase();
  check("en-tête profil (nom + rôle)", body0.includes("apprenant") || body0.includes("administrateur"));
  check("bouton « Modifier » visible", await page.locator('button:has-text("Modifier")').isVisible());
  check(
    "état vide téléphone",
    body0.includes("téléphone non renseigné") || /\+\d/.test(body0),
  );

  console.log("\n2. Ouverture du formulaire");
  await page.click('button:has-text("Modifier")');
  await page.waitForSelector('[data-slot="dialog-content"]', { timeout: 10000 });
  check("dialog « Modifier mon compte » ouvert", (await page.innerText('[data-slot="dialog-content"]')).toLowerCase().includes("modifier mon compte"));

  console.log("\n3. Upload de la photo");
  const srcBefore = await page.evaluate(
    () =>
      document
        .querySelector('[data-slot="dialog-content"] img')
        ?.getAttribute("src") ?? "",
  );
  await page.setInputFiles("#avatar-file", avatarPath);
  // Le téléversement est asynchrone : on attend que l'aperçu change de src
  // (chaque upload produit un nom de fichier horodaté).
  const srcAfter = await page
    .waitForFunction(
      (before) => {
        const src =
          document
            .querySelector('[data-slot="dialog-content"] img')
            ?.getAttribute("src") ?? "";
        return src && src !== before ? src : false;
      },
      srcBefore,
      { timeout: 30000 },
    )
    .then((handle) => handle.jsonValue())
    .catch(() => "");
  const hasImage =
    typeof srcAfter === "string" &&
    srcAfter.includes("avatars") &&
    srcAfter !== srcBefore;
  check(
    "photo téléversée + aperçu",
    hasImage,
    typeof srcAfter === "string" && srcAfter ? srcAfter.slice(-40) : "aucun changement",
  );

  console.log("\n4. Modification du téléphone");
  await page.fill("#phone", PHONE);
  await page.click('[data-slot="dialog-content"] button[type="submit"]');
  await page
    .waitForFunction(
      () => document.body.innerText.toLowerCase().includes("modifications enregistrées"),
      { timeout: 30000 },
    )
    .catch(() => undefined);
  const dialogText = await page.innerText('[data-slot="dialog-content"]');
  check(
    "message de succès",
    dialogText.toLowerCase().includes("modifications enregistrées") ||
      dialogText.toLowerCase().includes("enregistrement"),
    dialogText.split("\n").slice(-1)[0]?.slice(0, 80) ?? "",
  );

  console.log("\n5. Vérification du header rafraîchi");
  await page.keyboard.press("Escape");
  await page.waitForTimeout(1500);
  const headerImg = await page.evaluate(() =>
    Boolean(document.querySelector('img[src*="avatars"]')),
  );
  check("photo affichée dans l'en-tête", headerImg);
  const body1 = await page.innerText("body");
  check("téléphone affiché dans l'en-tête", body1.includes(PHONE));
  check("rôle affiché", /Apprenant|Administrateur/.test(body1));

  const shot = `${OUT}\\profil-edit.png`;
  await page.screenshot({ path: shot, fullPage: true });
  console.log("  capture :", shot);
} finally {
  await browser.close();
}

console.log(
  failures === 0
    ? "\n=== PROFIL MODIFIABLE : OK ===\n"
    : `\n=== ${failures} ÉCHEC(S) ===\n`,
);
process.exit(failures === 0 ? 0 : 1);
