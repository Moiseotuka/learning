/**
 * Test E2E de l'examen final de niveau (headless, Edge/Chrome système).
 *
 * Déroulé (compte quiz-test, chapitres Débutant validés) :
 *  0. seed défensif des chapitres Débutant + achat simulé du niveau
 *     Intermédiaire (pour que le verrou affiché soit bien celui de l'examen)
 *  1. page examen → tirage de 10 questions sur le niveau
 *  2. échec volontaire → level_exams (in_progress) + niveau suivant verrouillé
 *  3. nouvelle tentative avec les bonnes réponses → examen réussi
 *  4. parcours : badge « Examen réussi » + niveau suivant débloqué,
 *     aucun certificat nouveau (déjà délivré / parcours non terminé)
 *  5. cleanup : examen, achat et progressions restaurés
 *
 * Usage : npm run test:exam
 * Prérequis : serveur dev sur BASE_URL + migrations
 * supabase/migrations/202610020002_level_exams.sql et 202610030001_payments.sql.
 * Compte de test : QUIZ_TEST_EMAIL / QUIZ_TEST_PASSWORD.
 */
import { chromium } from "playwright-core";
import { existsSync } from "node:fs";
import { serviceEnv } from "./e2e-setup.mjs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? "QuizTest2026!";
const TRACK = "python-developpeur";
const LEVEL = "debutant";
const NEXT_LEVEL = "intermediaire";
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";

let failures = 0;
function check(label, ok, detail = "") {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
}

const { url, key } = serviceEnv();
if (!url || !key) {
  console.error("SUPABASE_SERVICE_ROLE_KEY absente de .env.local");
  process.exit(1);
}
const headers = {
  apikey: key,
  Authorization: `Bearer ${key}`,
  "Content-Type": "application/json",
};

async function rest(path, init = {}) {
  return fetch(`${url}/rest/v1/${path}`, {
    ...init,
    headers: { ...headers, ...(init.headers ?? {}) },
  });
}

async function restJson(path, init = {}) {
  const res = await rest(path, init);
  if (!res.ok) {
    throw new Error(`REST ${path} ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

// --- 0. Serveur dev + migrations ------------------------------------------
try {
  const probe = await fetch(BASE, { redirect: "manual" });
  if (!probe.ok && probe.status >= 500) throw new Error(`HTTP ${probe.status}`);
} catch (error) {
  console.error("Serveur dev injoignable sur", BASE, "— lancez `npm run dev`.");
  console.error(error.message);
  process.exit(1);
}

{
  const res = await rest("level_exams?select=level&limit=1");
  if (res.status === 404) {
    console.error(
      "Table `level_exams` absente — collez la migration supabase/migrations/202610020002_level_exams.sql puis relancez.",
    );
    process.exit(2);
  }
  if (!res.ok) {
    console.error("Probe level_exams:", res.status, await res.text());
    process.exit(1);
  }
}

// --- 1. Fixtures ------------------------------------------------------------
const usersRes = await fetch(`${url}/auth/v1/admin/users?page=1&per_page=200`, {
  headers: { apikey: key, Authorization: `Bearer ${key}` },
});
const usersData = await usersRes.json();
const user = (usersData.users ?? []).find(
  (item) => (item.email ?? "").toLowerCase() === EMAIL.toLowerCase(),
);
if (!user) {
  console.error("Compte introuvable :", EMAIL);
  process.exit(1);
}

const chapters = await restJson(
  `chapters?published=eq.true&track_id=eq.${TRACK}&select=id,slug,title,level,position&order=position`,
);
const beginnerIds = chapters
  .filter((chapter) => chapter.level === LEVEL)
  .map((chapter) => chapter.id);
if (beginnerIds.length === 0) {
  console.error("Aucun chapitre publié pour", TRACK, LEVEL);
  process.exit(1);
}
const nextLevelChapter = chapters.find(
  (chapter) => chapter.level === NEXT_LEVEL,
);
if (!nextLevelChapter) {
  console.error("Aucun chapitre publié pour", TRACK, NEXT_LEVEL);
  process.exit(1);
}

const questions = await restJson(
  `quiz_questions?chapter_id=in.(${beginnerIds.map((id) => `"${id}"`).join(",")})&select=id,choices,answer_index`,
);
const questionById = new Map(questions.map((row) => [row.id, row]));
if (questions.length < 10) {
  console.error(
    `Quiz insuffisant pour un tirage de 10 : ${questions.length} questions.`,
  );
  process.exit(1);
}

const snapshotExams = await restJson(
  `level_exams?user_id=eq.${user.id}&select=track_id,level,status,best_score,attempts,passed_at`,
);
const snapshotExam = snapshotExams.find(
  (row) => row.track_id === TRACK && row.level === LEVEL,
);
const snapshotPurchases = await restJson(
  `purchases?user_id=eq.${user.id}&select=id,category_id,level,status`,
);
const snapshotNextLevelPurchases = snapshotPurchases.filter(
  (row) => row.category_id === "prog" && row.level === NEXT_LEVEL,
);
const snapshotCerts = await restJson(
  `certificates?user_id=eq.${user.id}&select=code,track_id,level`,
);
const certKeys = () =>
  snapshotCerts.map((row) => `${row.track_id}:${row.level}`).sort();
const snapshotProgress = await restJson(
  `chapter_progress?user_id=eq.${user.id}&select=chapter_id,status,attempts,best_score,completed_at`,
);

let seededPurchaseId = null;

/**
 * État propre au démarrage : examen de niveau remis à zéro et achat du
 * niveau suivant retiré (les deux sont restaurés dans cleanup), quel que soit
 * l'état laissé par une exécution précédente.
 */
async function resetExamAndPurchase() {
  await rest(
    `level_exams?user_id=eq.${user.id}&track_id=eq.${TRACK}&level=eq.${LEVEL}`,
    { method: "DELETE" },
  );
  for (const row of snapshotNextLevelPurchases) {
    await rest(`purchases?id=eq.${row.id}`, { method: "DELETE" });
  }
}

async function seedBeginnerChapters() {
  const missing = beginnerIds.filter((id) => {
    const row = snapshotProgress.find((item) => item.chapter_id === id);
    return !row || row.status !== "completed";
  });
  if (missing.length === 0) return;
  const now = new Date().toISOString();
  const res = await rest(`chapter_progress?on_conflict=user_id,chapter_id`, {
    method: "POST",
    headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
    body: JSON.stringify(
      missing.map((id) => ({
        user_id: user.id,
        chapter_id: id,
        track_id: TRACK,
        status: "completed",
        attempts: 1,
        best_score: 100,
        completed_at: now,
      })),
    ),
  });
  if (!res.ok) throw new Error(`seed chapters ${res.status}: ${await res.text()}`);
}

async function seedPurchase() {
  const res = await rest("purchases", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify([
      {
        user_id: user.id,
        category_id: "prog",
        level: NEXT_LEVEL,
        amount_usd: 10,
        provider: "mock",
        status: "paid",
        paid_at: new Date().toISOString(),
      },
    ]),
  });
  if (!res.ok) throw new Error(`seed purchase ${res.status}: ${await res.text()}`);
  const rows = await res.json();
  seededPurchaseId = rows[0]?.id ?? null;
}

async function cleanup() {
  // Examen : suppression de la ligne de test puis restauration de l'état initial.
  await rest(
    `level_exams?user_id=eq.${user.id}&track_id=eq.${TRACK}&level=eq.${LEVEL}`,
    { method: "DELETE" },
  );
  if (snapshotExam) {
    await rest("level_exams", {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify([{ ...snapshotExam, user_id: user.id }]),
    }).then(async (res) => {
      if (!res.ok) {
        console.error("restore exam:", res.status, await res.text());
      }
    });
  }

  // Achat : suppression du seed puis restauration des lignes initiales.
  if (seededPurchaseId) {
    await rest(`purchases?id=eq.${seededPurchaseId}`, { method: "DELETE" });
  }
  if (snapshotNextLevelPurchases.length > 0) {
    await rest("purchases", {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify(snapshotNextLevelPurchases),
    }).then(async (res) => {
      if (!res.ok) {
        console.error("restore purchases:", res.status, await res.text());
      }
    });
  }

  // Progressions : restauration des chapitres débutant si modifiés.
  const liveProgress = await restJson(
    `chapter_progress?user_id=eq.${user.id}&select=chapter_id,status,attempts,best_score,completed_at`,
  ).catch(() => []);
  const before = new Map(snapshotProgress.map((row) => [row.chapter_id, row]));
  for (const row of liveProgress) {
    if (!beginnerIds.includes(row.chapter_id)) continue;
    const original = before.get(row.chapter_id);
    if (!original) {
      await rest(
        `chapter_progress?user_id=eq.${user.id}&chapter_id=eq.${row.chapter_id}`,
        { method: "DELETE" },
      );
    } else if (
      original.status !== row.status ||
      original.attempts !== row.attempts ||
      original.best_score !== row.best_score
    ) {
      await rest(
        `chapter_progress?user_id=eq.${user.id}&chapter_id=eq.${row.chapter_id}`,
        {
          method: "PATCH",
          headers: { Prefer: "return=minimal" },
          body: JSON.stringify({
            status: original.status,
            attempts: original.attempts,
            best_score: original.best_score,
            completed_at: original.completed_at,
          }),
        },
      );
    }
  }

  // Certificats : suppression de ceux créés pendant le test.
  const liveCerts = await restJson(
    `certificates?user_id=eq.${user.id}&select=code`,
  ).catch(() => []);
  const keep = new Set(snapshotCerts.map((row) => row.code));
  for (const row of liveCerts) {
    if (keep.has(row.code)) continue;
    await rest(
      `certificates?user_id=eq.${user.id}&code=eq.${encodeURIComponent(row.code)}`,
      { method: "DELETE" },
    );
  }
}

// --- 2. Navigateur ----------------------------------------------------------
if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE, "(définir QUIZ_TEST_BROWSER)");
  process.exit(1);
}

await resetExamAndPurchase();
await seedBeginnerChapters();
await seedPurchase();

const examUrl = `${BASE}/app/parcours/${TRACK}/niveaux/${LEVEL}/examen`;
const trackUrl = `${BASE}/app/parcours/${TRACK}`;
const browser = await chromium.launch({ executablePath: EDGE, headless: true });

try {
  const page = await browser.newPage();

  console.log("\n1. Connexion");
  await page.goto(`${BASE}/connexion`, { waitUntil: "networkidle" });
  await page.fill("#email", EMAIL);
  await page.fill("#password", PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", {
    timeout: 20000,
  });
  check("redirigé vers la landing page (avant navigation)", true);

  console.log("\n2. Page examen → tirage de 10 questions");
  await page.goto(examUrl, { waitUntil: "networkidle" });
  const examText = await page.innerText("main");
  check("titre « Examen de fin de niveau »", examText.includes("Examen de fin de niveau"));
  check(
    "intro annonce le seuil",
    examText.includes("10 questions") || examText.includes(`${10} questions`),
  );
  const drawnInput = page.locator('input[name="questionIds"]');
  check("champ questionIds présent", (await drawnInput.count()) === 1);
  const drawnIds = ((await drawnInput.inputValue()) || "").split(",").filter(Boolean);
  check("10 questions tirées", drawnIds.length === 10, `${drawnIds.length}`);
  check(
    "tirage issu du quiz du niveau",
    drawnIds.every((id) => questionById.has(id)),
  );
  const fieldsetCount = await page.locator("form fieldset").count();
  check("10 blocs de questions affichés", fieldsetCount === 10, `${fieldsetCount}`);

  // Mélange des choix : chaque radio conserve l'index d'origine (scoring
  // serveur inchangé) mais l'ordre affiché est réordonné par question.
  const renderedChoices = await page.$$eval("form fieldset", (fieldsets) =>
    fieldsets.map((fieldset) =>
      [...fieldset.querySelectorAll('input[type="radio"]')].map((input) => {
        const match = /^exam-(.+)-(\d+)$/.exec(input.id);
        return {
          questionId: match ? match[1] : "",
          originalIndex: match ? Number(match[2]) : -1,
          label: (input.closest("label")?.textContent ?? "").trim(),
        };
      }),
    ),
  );
  const mappingOk = renderedChoices.every((radios) =>
    radios.every((radio) => {
      const question = questionById.get(radio.questionId);
      return (
        question &&
        radio.originalIndex >= 0 &&
        radio.originalIndex < question.choices.length &&
        question.choices[radio.originalIndex].trim() === radio.label
      );
    }),
  );
  check(
    "chaque choix affiché porte son index d'origine (valeur soumise correcte)",
    mappingOk,
    `${renderedChoices.length} questions`,
  );
  const shuffled = renderedChoices.filter((radios) =>
    radios.some((radio, position) => radio.originalIndex !== position),
  ).length;
  check(
    "choix mélangés (au moins une question réordonnée)",
    shuffled > 0,
    `${shuffled}/${renderedChoices.length}`,
  );

  console.log("\n3. Échec volontaire → level_exams (in_progress)");
  for (const id of drawnIds) {
    const question = questionById.get(id);
    const wrong = (question.answer_index + 1) % question.choices.length;
    await page.check(`#exam-${id}-${wrong}`);
  }
  await page.click('button[type="submit"]');
  await page.waitForSelector("text=Score insuffisant", { timeout: 20000 });
  check("écran d'échec affiché", true);
  const failedText = await page.innerText("main");
  check("score 0 % affiché", failedText.includes("0 %"));

  const examAfterFail = await restJson(
    `level_exams?user_id=eq.${user.id}&track_id=eq.${TRACK}&level=eq.${LEVEL}&select=status,attempts,best_score`,
  );
  check(
    "ligne level_exams en in_progress",
    examAfterFail[0]?.status === "in_progress",
    JSON.stringify(examAfterFail[0] ?? null),
  );
  check("1 tentative enregistrée", examAfterFail[0]?.attempts === 1);
  check("best_score 0", examAfterFail[0]?.best_score === 0);

  console.log("\n4. Parcours : niveau suivant verrouillé par l'examen");
  await page.goto(trackUrl, { waitUntil: "networkidle" });
  const beforeText = await page.innerText("main");
  check(
    "verrou examen affiché sur le niveau suivant",
    beforeText.includes(
      "Réussissez l'examen du niveau précédent pour débloquer ce niveau.",
    ),
  );
  check(
    "carte d'examen « Passer l'examen » présente",
    beforeText.includes("Passer l'examen"),
  );

  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${nextLevelChapter.slug}`,
    { waitUntil: "networkidle" },
  );
  const chapterLockText = await page.innerText("main");
  check(
    "accès direct au chapitre suivant verrouillé par l'examen",
    chapterLockText.includes(
      "Réussissez l'examen du niveau précédent pour débloquer ce niveau.",
    ),
  );
  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${nextLevelChapter.slug}/quiz`,
    { waitUntil: "networkidle" },
  );
  check(
    "quiz du chapitre suivant verrouillé par l'examen",
    (await page.innerText("main")).includes(
      "Réussissez l'examen du niveau précédent pour débloquer ce niveau.",
    ),
  );

  console.log("\n5. Nouvelle tentative → examen réussi");
  await page.goto(examUrl, { waitUntil: "networkidle" });
  const retryIds = ((await page.locator('input[name="questionIds"]').inputValue()) || "")
    .split(",")
    .filter(Boolean);
  check("nouveau tirage (10 questions)", retryIds.length === 10, `${retryIds.length}`);
  for (const id of retryIds) {
    const question = questionById.get(id);
    await page.check(`#exam-${id}-${question.answer_index}`);
  }
  await page.click('button[type="submit"]');
  await page.waitForSelector("text=Examen réussi", { timeout: 20000 });
  const passedText = await page.innerText("main");
  check("score 100 % affiché", passedText.includes("100 %"));

  const examAfterPass = await restJson(
    `level_exams?user_id=eq.${user.id}&track_id=eq.${TRACK}&level=eq.${LEVEL}&select=status,attempts,best_score,passed_at`,
  );
  check(
    "statut passed",
    examAfterPass[0]?.status === "passed",
    JSON.stringify(examAfterPass[0] ?? null),
  );
  check("2 tentatives", examAfterPass[0]?.attempts === 2);
  check("best_score 100", examAfterPass[0]?.best_score === 100);
  check("passed_at renseigné", Boolean(examAfterPass[0]?.passed_at));

  console.log("\n6. Parcours : badge réussi + niveau suivant débloqué");
  await page.goto(trackUrl, { waitUntil: "networkidle" });
  const afterText = await page.innerText("main");
  check(
    "badge « Examen réussi »",
    afterText.includes("Examen réussi"),
  );
  check(
    "verrou examen disparu",
    !afterText.includes(
      "Réussissez l'examen du niveau précédent pour débloquer ce niveau.",
    ),
  );

  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${nextLevelChapter.slug}`,
    { waitUntil: "networkidle" },
  );
  const chapterUnlockedText = await page.innerText("main");
  check(
    "accès direct au chapitre suivant déverrouillé après l'examen",
    !chapterUnlockedText.includes(
      "Réussissez l'examen du niveau précédent pour débloquer ce niveau.",
    ) && !chapterUnlockedText.toLowerCase().includes("niveau verrouillé"),
  );

  const liveCerts = await restJson(
    `certificates?user_id=eq.${user.id}&select=code,track_id,level`,
  );
  const liveKeys = liveCerts.map((row) => `${row.track_id}:${row.level}`).sort();
  check(
    "aucun certificat nouveau (déjà délivré, parcours non terminé)",
    JSON.stringify(liveKeys) === JSON.stringify(certKeys()),
    `${liveKeys.length} certificats`,
  );

  console.log("\n7. Capture");
  await page.goto(examUrl, { waitUntil: "networkidle" });
  const shot = `${
    process.env.TEMP ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode"
  }\\examen-niveau.png`;
  await page.screenshot({ path: shot, fullPage: true });
  console.log("  capture :", shot);
} finally {
  await browser.close();
  await cleanup();
  console.log("  cleanup : examen, achat, progressions et certificats restaurés");
}

console.log(
  failures === 0
    ? "\n=== TOUS LES TESTS PASSENT ===\n"
    : `\n=== ${failures} ÉCHEC(S) ===\n`,
);
process.exit(failures === 0 ? 0 : 1);
