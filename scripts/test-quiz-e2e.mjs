/**
 * Test E2E du quiz (headless, Edge/Chrome système).
 *
 * Déroulé : login → quiz chapitre 1 → échec → « Recommencer » →
 * réponses correctes →100 % → chapitre suivant débloqué.
 *
 * Usage : npm run test:quiz
 * Prérequis : serveur dev lancé sur BASE_URL (défaut http://localhost:3000)
 * Compte de test : voir env QUIZ_TEST_EMAIL / QUIZ_TEST_PASSWORD
 */
import { chromium } from "playwright-core";
import { existsSync } from "node:fs";

import { markChapterVideosWatched } from "./e2e-setup.mjs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD");
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let failures = 0;
function check(label, ok, detail = "") {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
}

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE, "(définir QUIZ_TEST_BROWSER)");
  process.exit(1);
}

const browser = await chromium.launch({ executablePath: EDGE, headless: true });

try {
  const page = await browser.newPage();

  console.log("\n1. Connexion");
  await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
  await page.fill("#email", EMAIL);
  await page.fill("#password", PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", {
    timeout: 20000,
  });
  check("redirigé vers la landing page (avant navigation)", true);

  console.log("\n2. Quiz chapitre 1 — setup des vidéos pour débloquer la route");
  const videosReady = await markChapterVideosWatched({
    email: EMAIL,
    chapterId: "py-c1",
    trackId: "python-developpeur",
  });
  check(
    "vidéos du chapitre 1 marquées comme vues",
    videosReady.ok,
    videosReady.ok
      ? `${videosReady.tokens?.length ?? 0} vidéo(s)`
      : `${videosReady.reason}${videosReady.detail ? ` — ${videosReady.detail}` : ""}`,
  );

  await page.goto(
    `${BASE}/app/parcours/python-developpeur/chapitres/premiers-pas-variables/quiz`,
    { waitUntil: "networkidle" },
  );
  const names = await page.$$eval('input[type="radio"]', (els) => [
    ...new Set(els.map((el) => el.name)),
  ]);
  const initialRadios = await page.locator('input[type="radio"]').count();
  check("questions rendues", names.length === 4, `${names.length} questions`);
  check(
    "pas d'écran 'quiz indisponible'",
    (await page.innerText("main")).includes("Valider mes réponses"),
  );

  const answer = async (indexes) => {
    for (let i = 0; i < names.length; i++) {
      await page.locator(`input[name="${names[i]}"][value="${indexes[i]}"]`).click();
    }
  };

  await answer([0, 0, 1, 0]);
  await page.click('button:has-text("Valider mes réponses")');
  await page.waitForSelector("text=Corrigé des réponses", { timeout: 20000 });
  check("écran de score affiché après échec", true);

  console.log("\n3. Bouton « Recommencer le quiz »");
  await page
    .waitForSelector('button:has-text("Recommencer le quiz")', {
      timeout: 20000,
    })
    .catch(() => null);
  await page.click('button:has-text("Recommencer le quiz")');
  await page.waitForSelector('button:has-text("Valider mes réponses")', {
    timeout: 20000,
  });
  await sleep(800);
  const radiosBack = await page.locator('input[type="radio"]').count();
  const checkedBack = await page.locator('input[type="radio"]:checked').count();
  check("formulaire de retour", radiosBack === initialRadios, `${radiosBack} radios`);
  check("réponses réinitialisées", checkedBack === 0, `${checkedBack} cochés`);

  console.log("\n4. Bonnes réponses →100 %");
  await answer([2, 1, 0, 3]);
  await page.click('button:has-text("Valider mes réponses")');
  await page.waitForSelector("text=Corrigé des réponses", { timeout: 20000 });
  const main = await page.innerText("main");
  check("score validé", main.includes("Quiz validé"));
  check(
    "bouton 'Chapitre suivant' présent",
    (await page.locator('a:has-text("Chapitre suivant")').count()) > 0,
  );

  console.log("\n5. Chapitre suivant débloqué");
  await page.click('a:has-text("Chapitre suivant")');
  await page.waitForURL(/\/conditions-boucles$/, { timeout: 20000 });
  const chap2 = await page.innerText("main");
  check("chapitre 2 ouvert", !chap2.includes("Chapitre verrouillé"));
  const aside = await page.innerText("aside").catch(() => "");
  check(
    "progression mise à jour dans la sidebar",
    /Progression \d+ %/.test(aside),
    (aside.match(/Progression \d+ %/) || ["?"])[0],
  );
} finally {
  await browser.close();
}

console.log(
  failures === 0
    ? "\n=== TOUS LES TESTS PASSENT ===\n"
    : `\n=== ${failures} ÉCHEC(S) ===\n`,
);
process.exit(failures === 0 ? 0 : 1);
