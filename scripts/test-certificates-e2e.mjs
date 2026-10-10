/**
 * Test E2E des certificats (headless, Edge/Chrome système) — TOUS les
 * parcours publiés de la plateforme.
 *
 * Déroulé : seed REST des progressions (niveau Débutant de chaque parcours)
 * + examens de fin de niveau réussis → /app/profil génère un certificat de
 * niveau par parcours → téléchargement PDF + vérification publique → seed
 * 100 % + examens de tous les niveaux → certificats « Parcours complet »
 * pour chaque parcours → cleanup (restauration de l'état initial).
 *
 * Usage : npm run test:certificates
 * Prérequis : serveur dev sur BASE_URL + migration
 * supabase/migrations/202610040001_certificates.sql collée.
 * Compte de test : QUIZ_TEST_EMAIL / QUIZ_TEST_PASSWORD.
 */
import { chromium } from "playwright-core";
import { existsSync } from "node:fs";
import { serviceEnv } from "./e2e-setup.mjs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? "QuizTest2026!";
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";

let failures = 0;
function check(label, ok, detail = "") {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
}

/** Les cartes peuvent arriver après le premier rendu : on attend, puis on
 *  recharge une fois (un rendu concurrent peut avoir manqué une insertion). */
async function waitForCards(page, expected, timeoutMs = 15000) {
  const deadline = Date.now() + timeoutMs;
  let count = await page.locator("article").count();
  while (count < expected && Date.now() < deadline) {
    await page.waitForTimeout(400);
    count = await page.locator("article").count();
  }
  if (count < expected) {
    await page.reload({ waitUntil: "networkidle" });
    const retryDeadline = Date.now() + timeoutMs;
    while (count < expected && Date.now() < retryDeadline) {
      await page.waitForTimeout(400);
      count = await page.locator("article").count();
    }
  }
  return count;
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

// --- 0. Serveur dev + migration ------------------------------------------
try {
  const probe = await fetch(BASE, { redirect: "manual" });
  if (!probe.ok && probe.status >= 500) throw new Error(`HTTP ${probe.status}`);
} catch (error) {
  console.error("Serveur dev injoignable sur", BASE, "— lancez `npm run dev`.");
  console.error(error.message);
  process.exit(1);
}

{
  const res = await rest("certificates?select=id&limit=1");
  if (res.status === 404) {
    console.error(
      "Table `certificates` absente — collez la migration supabase/migrations/202610040001_certificates.sql puis relancez.",
    );
    process.exit(2);
  }
  if (!res.ok) {
    console.error("Probe certificates:", res.status, await res.text());
    process.exit(1);
  }
}

// --- 1. Découverte des parcours + fixtures --------------------------------
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

const trackRows = await restJson(
  "tracks?published=eq.true&select=id,slug,title&order=position",
);
const chapterRows = await restJson(
  "chapters?published=eq.true&select=id,track_id,level,position&order=position",
);

const chaptersByTrack = new Map();
for (const chapter of chapterRows) {
  const list = chaptersByTrack.get(chapter.track_id) ?? [];
  list.push(chapter);
  chaptersByTrack.set(chapter.track_id, list);
}
const tracks = trackRows.filter(
  (track) => (chaptersByTrack.get(track.id) ?? []).length > 0,
);
if (tracks.length === 0) {
  console.error("Aucun parcours publié avec chapitres.");
  process.exit(1);
}
const topicOf = (track) =>
  (track.title.split(":")[0] || track.title).trim();
const allChapterIds = tracks.flatMap((track) =>
  (chaptersByTrack.get(track.id) ?? []).map((chapter) => chapter.id),
);
const beginnerIds = tracks.flatMap((track) =>
  (chaptersByTrack.get(track.id) ?? [])
    .filter((chapter) => chapter.level === "debutant")
    .map((chapter) => chapter.id),
);

const snapshotProgress = await restJson(
  `chapter_progress?user_id=eq.${user.id}&select=chapter_id,status,attempts,best_score,completed_at`,
);
const snapshotCerts = await restJson(
  `certificates?user_id=eq.${user.id}&select=code,track_id,level`,
);
const snapshotExams = await restJson(
  `level_exams?user_id=eq.${user.id}&select=track_id,level,status,best_score,attempts,passed_at`,
).catch(() => []);
const snapshotKeys = new Set(
  snapshotCerts.map((row) => `${row.track_id}:${row.level}`),
);
const snapshotCodes = new Set(snapshotCerts.map((row) => row.code));
const passedExamKeys = new Set(
  snapshotExams
    .filter((row) => row.status === "passed")
    .map((row) => `${row.track_id}:${row.level}`),
);
const completed0 = new Set(
  snapshotProgress
    .filter((row) => row.status === "completed")
    .map((row) => row.chapter_id),
);

const levelsByTrack = new Map();
for (const track of tracks) {
  levelsByTrack.set(
    track.id,
    [
      ...new Set(
        (chaptersByTrack.get(track.id) ?? []).map((chapter) => chapter.level),
      ),
    ],
  );
}

function candidatesOf(completedSet, examsSet) {
  const keys = [];
  for (const track of tracks) {
    const trackChapters = chaptersByTrack.get(track.id) ?? [];
    const levels = levelsByTrack.get(track.id) ?? [];
    if (
      trackChapters.every((chapter) => completedSet.has(chapter.id)) &&
      levels.every((level) => examsSet.has(`${track.id}:${level}`))
    ) {
      keys.push(`${track.id}:parcours`);
    }
    for (const level of levels) {
      const done = trackChapters
        .filter((chapter) => chapter.level === level)
        .every((chapter) => completedSet.has(chapter.id));
      if (done && examsSet.has(`${track.id}:${level}`)) {
        keys.push(`${track.id}:${level}`);
      }
    }
  }
  return keys;
}
const totalFor = (completedSet, examsSet) =>
  new Set([...candidatesOf(completedSet, examsSet), ...snapshotKeys]).size;

const examsBeginner = new Set(passedExamKeys);
for (const track of tracks) examsBeginner.add(`${track.id}:debutant`);
const examsAll = new Set(passedExamKeys);
for (const track of tracks) {
  for (const level of levelsByTrack.get(track.id) ?? []) {
    examsAll.add(`${track.id}:${level}`);
  }
}

const completedA = new Set([...completed0, ...beginnerIds]);
const expectedA = totalFor(completedA, examsBeginner);
const expectedB = totalFor(new Set([...completed0, ...allChapterIds]), examsAll);

async function seedCompleted(chapterIds) {
  const rows = chapterIds.map((id) => ({
    user_id: user.id,
    chapter_id: id,
    track_id:
      chapterRows.find((chapter) => chapter.id === id)?.track_id ?? null,
    status: "completed",
    attempts: 1,
    best_score: 100,
    completed_at: new Date().toISOString(),
  }));
  const res = await rest(`chapter_progress?on_conflict=user_id,chapter_id`, {
    method: "POST",
    headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
    body: JSON.stringify(rows),
  });
  if (!res.ok) throw new Error(`seed ${res.status}: ${await res.text()}`);
}

/** Simule la réussite des examens de fin de niveau (condition de délivrance). */
async function seedExams(keys) {
  const rows = [...keys].map((key) => {
    const separator = key.lastIndexOf(":");
    return {
      user_id: user.id,
      track_id: key.slice(0, separator),
      level: key.slice(separator + 1),
      attempts: 1,
      best_score: 100,
      status: "passed",
      passed_at: new Date().toISOString(),
    };
  });
  if (rows.length === 0) return;
  const res = await rest(
    `level_exams?on_conflict=user_id,track_id,level`,
    {
      method: "POST",
      headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify(rows),
    },
  );
  if (!res.ok) throw new Error(`seed exams ${res.status}: ${await res.text()}`);
}

async function cleanup() {
  const current = await restJson(
    `certificates?user_id=eq.${user.id}&select=code`,
  ).catch(() => []);
  for (const row of current) {
    if (snapshotCodes.has(row.code)) continue;
    await rest(
      `certificates?user_id=eq.${user.id}&code=eq.${encodeURIComponent(row.code)}`,
      { method: "DELETE" },
    );
  }

  const idList = allChapterIds.map((id) => `"${id}"`).join(",");
  const live = idList
    ? await restJson(
        `chapter_progress?user_id=eq.${user.id}&chapter_id=in.(${idList})&select=chapter_id,status,attempts,best_score,completed_at`,
      ).catch(() => [])
    : [];
  const before = new Map(snapshotProgress.map((row) => [row.chapter_id, row]));
  for (const row of live) {
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

  const liveExams = await restJson(
    `level_exams?user_id=eq.${user.id}&select=track_id,level,status,best_score,attempts,passed_at`,
  ).catch(() => []);
  const examBefore = new Map(
    snapshotExams.map((row) => [`${row.track_id}:${row.level}`, row]),
  );
  for (const row of liveExams) {
    const key = `${row.track_id}:${row.level}`;
    const original = examBefore.get(key);
    if (!original) {
      await rest(
        `level_exams?user_id=eq.${user.id}&track_id=eq.${row.track_id}&level=eq.${row.level}`,
        { method: "DELETE" },
      );
    } else if (
      original.status !== row.status ||
      original.attempts !== row.attempts ||
      original.best_score !== row.best_score
    ) {
      await rest(
        `level_exams?user_id=eq.${user.id}&track_id=eq.${row.track_id}&level=eq.${row.level}`,
        {
          method: "PATCH",
          headers: { Prefer: "return=minimal" },
          body: JSON.stringify({
            status: original.status,
            attempts: original.attempts,
            best_score: original.best_score,
            passed_at: original.passed_at,
          }),
        },
      );
    }
  }
}

// --- 2. Navigateur ---------------------------------------------------------
if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE, "(définir QUIZ_TEST_BROWSER)");
  process.exit(1);
}

console.log(
  `\nParcours couverts : ${tracks.map((t) => `${t.id} (${topicOf(t)})`).join(", ")}`,
);

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

  console.log("\n2. Débutant de chaque parcours → certificat de niveau");
  check(
    "chapitres débutant sur tous les parcours",
    beginnerIds.length > 0,
    `${beginnerIds.length} chapitres / ${tracks.length} parcours`,
  );
  await seedCompleted(beginnerIds);
  await seedExams(
    new Set([...examsBeginner].filter((key) => !passedExamKeys.has(key))),
  );

  await page.goto(`${BASE}/app/profil`, { waitUntil: "networkidle" });
  const countA = await waitForCards(page, expectedA);
  const profil = await page.innerText("main");
  // Le titre de section est en majuscules à l'écran (text-transform).
  check(
    "section « Mes certificats »",
    profil.toLowerCase().includes("mes certificats"),
  );
  check(
    `${expectedA} cartes après phase Débutant`,
    countA === expectedA,
    `${countA} / ${expectedA}`,
  );
  let levelCardsOk = true;
  for (const track of tracks) {
    const has = profil.includes(`${topicOf(track)} : niveau Débutant`);
    if (!has) levelCardsOk = false;
    if (!has) console.log(`    ! certificat débutant absent : ${topicOf(track)}`);
  }
  check("certificat de niveau Débutant pour chaque parcours", levelCardsOk);
  const codeMatch = profil.match(/[A-Z]{3}-\d{4}-\d{6}/);
  check("code au format PREFIX-AAAA-NNNNNN", Boolean(codeMatch));

  console.log("\n3. Téléchargement du PDF (niveau)");
  const levelCode = codeMatch ? codeMatch[0] : "";
  const pdfRes = await page.request.get(
    `${BASE}/api/certificats/${encodeURIComponent(levelCode)}`,
  );
  const pdfHeaders = pdfRes.headers();
  const pdfBody = await pdfRes.body();
  check("HTTP 200", pdfRes.status() === 200, `${pdfRes.status()}`);
  check(
    "content-type application/pdf",
    (pdfHeaders["content-type"] ?? "").includes("application/pdf"),
    pdfHeaders["content-type"] ?? "?",
  );
  check(
    "en-tête %PDF",
    pdfBody.subarray(0, 4).toString("latin1") === "%PDF",
    `${pdfBody.length} octets`,
  );
  check(
    "Content-Disposition: attachment",
    (pdfHeaders["content-disposition"] ?? "").includes("attachment"),
  );

  console.log("\n4. Vérification publique (niveau)");
  await page.goto(`${BASE}/verifier?code=${encodeURIComponent(levelCode)}`, {
    waitUntil: "networkidle",
  });
  const verifyText = await page.innerText("main");
  check("certificat valide", verifyText.includes("Certificat valide"));
  check("code affiché", verifyText.includes(levelCode));

  await page.goto(`${BASE}/verifier?code=AAA-2026-000000`, {
    waitUntil: "networkidle",
  });
  check(
    "code inconnu refusé",
    (await page.innerText("main")).includes("Certificat introuvable"),
  );

  console.log("\n5. 100 % de chaque parcours → « Parcours complet »");
  await seedCompleted(allChapterIds);
  await seedExams(
    new Set([...examsAll].filter((key) => !passedExamKeys.has(key))),
  );
  await page.goto(`${BASE}/app/profil`, { waitUntil: "networkidle" });
  const countB = await waitForCards(page, expectedB);
  const full = await page.innerText("main");
  check(
    `${expectedB} cartes après 100 %`,
    countB === expectedB,
    `${countB} / ${expectedB}`,
  );
  const finalTitles = await page.locator("article h3").allInnerTexts();
  let finalsOk = true;
  for (const track of tracks) {
    const expected = `${topicOf(track)} : Parcours complet`;
    if (!finalTitles.includes(expected)) {
      finalsOk = false;
      console.log(`    ! carte absente : ${expected}`);
    }
  }
  check(
    `« Parcours complet » pour les ${tracks.length} parcours`,
    finalsOk,
  );

  const finalCodes = [...full.matchAll(/[A-Z]{3}-\d{4}-\d{6}/g)].map(
    (m) => m[0],
  );
  const finalCode = finalCodes[finalCodes.length - 1] ?? "";
  const finalPdf = await page.request.get(
    `${BASE}/api/certificats/${encodeURIComponent(finalCode)}`,
  );
  const finalBody = await finalPdf.body();
  check(
    "PDF du certificat parcours",
    finalPdf.status() === 200 &&
      finalBody.subarray(0, 4).toString("latin1") === "%PDF",
    `${finalPdf.status()} ${finalBody.length} octets`,
  );
  await page.goto(`${BASE}/verifier?code=${encodeURIComponent(finalCode)}`, {
    waitUntil: "networkidle",
  });
  check(
    "vérification du parcours",
    (await page.innerText("main")).includes("Certificat valide"),
  );

  console.log("\n6. Capture du profil");
  await page.goto(`${BASE}/app/profil`, { waitUntil: "networkidle" });
  const shot = `${
    process.env.TEMP ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode"
  }\\profil-certificats.png`;
  await page.screenshot({ path: shot, fullPage: true });
  console.log("  capture :", shot);
} finally {
  await browser.close();
  await cleanup();
  console.log("  cleanup : certificats, progressions et examens restaurés");
}

console.log(
  failures === 0
    ? "\n=== TOUS LES TESTS PASSENT ===\n"
    : `\n=== ${failures} ÉCHEC(S) ===\n`,
);
process.exit(failures === 0 ? 0 : 1);
