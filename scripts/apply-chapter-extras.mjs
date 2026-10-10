/**
 * Applique le contenu annexe des chapitres via l'API REST (service role) :
 * exercice, ressources, code (exercice éditable) depuis content/chapters/*.json
 * et questions de quiz depuis content/quizzes/*.json.
 *
 * Idempotent : PATCH des colonnes chapitres + remplacement complet des
 * questions du chapitre (delete puis insert).
 *
 * Usage : node scripts/apply-chapter-extras.mjs            (tout)
 *         node scripts/apply-chapter-extras.mjs --only web-c1
 *         node scripts/apply-chapter-extras.mjs --check
 */
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { serviceEnv } from "./e2e-setup.mjs";

const ROOT = resolve(fileURLToPath(new URL("..", import.meta.url)));
const CHAPTERS_DIR = resolve(ROOT, "content/chapters");
const QUIZZES_DIR = resolve(ROOT, "content/quizzes");

const checkOnly = process.argv.includes("--check");
const onlyIdx = process.argv.indexOf("--only");
const only = onlyIdx >= 0 ? process.argv[onlyIdx + 1] : null;

const { url, key } = serviceEnv();
if (!url || !key) {
  console.error("Environnement REST absent de .env.local");
  process.exit(1);
}
const headers = {
  apikey: key,
  Authorization: `Bearer ${key}`,
  "Content-Type": "application/json",
};

async function rest(pathname, options = {}) {
  const response = await fetch(`${url}/rest/v1/${pathname}`, {
    ...options,
    headers: { ...headers, ...options.headers },
  });
  const text = await response.text();
  return { ok: response.ok, status: response.status, body: text, json: () => {
    try { return JSON.parse(text); } catch { return null; }
  } };
}

function listIds(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((name) => name.endsWith(".json"))
    .map((name) => name.replace(/\.json$/, ""))
    .filter((id) => !only || id === only)
    .sort();
}

function validateExtras(id, data) {
  const errors = [];
  if (typeof data.exercise !== "string" || !data.exercise.trim()) errors.push("exercise manquant");
  if (!Array.isArray(data.resources)) errors.push("resources invalide");
  else for (const r of data.resources) {
    if (!r?.label || !r?.url) errors.push("ressource incomplète");
    if (r?.url && !/^https:\/\//.test(r.url)) errors.push(`URL non https : ${r.url}`);
  }
  for (const field of ["code_language", "starter_code", "solution_code"]) {
    if (typeof (data[field] ?? "") !== "string") errors.push(`${field} invalide`);
  }
  return errors;
}

function validateQuiz(id, data) {
  const errors = [];
  if (!Array.isArray(data) || data.length === 0) errors.push("quiz vide");
  else data.forEach((q, i) => {
    if (!q.question) errors.push(`q${i + 1} : question manquante`);
    if (!Array.isArray(q.choices) || q.choices.length !== 4) errors.push(`q${i + 1} : 4 choix attendus`);
    if (!Number.isInteger(q.answer_index) || q.answer_index < 0 || q.answer_index > 3) errors.push(`q${i + 1} : answer_index invalide`);
    if (q.choices && Number.isInteger(q.answer_index) && !q.choices[q.answer_index]) errors.push(`q${i + 1} : answer_index hors des choix`);
    if (!q.explanation) errors.push(`q${i + 1} : explication manquante`);
  });
  return errors;
}

const chapterIds = listIds(CHAPTERS_DIR);
const quizIds = listIds(QUIZZES_DIR);
const allIds = [...new Set([...chapterIds, ...quizIds])];

if (allIds.length === 0) {
  console.error("Aucun contenu annexe trouvé.");
  process.exit(1);
}

let failures = 0;

for (const id of allIds) {
  const extrasPath = resolve(CHAPTERS_DIR, `${id}.json`);
  const quizPath = resolve(QUIZZES_DIR, `${id}.json`);
  const extras = existsSync(extrasPath) ? JSON.parse(readFileSync(extrasPath, "utf8")) : null;
  const quiz = existsSync(quizPath) ? JSON.parse(readFileSync(quizPath, "utf8")) : null;

  const errors = [
    ...(extras ? validateExtras(id, extras) : ["extras absents"]),
    ...(quiz ? validateQuiz(id, quiz) : ["quiz absent"]),
  ];
  if (errors.length > 0) {
    console.log(`✗ ${id} — ${errors.join(" ; ")}`);
    failures += 1;
    continue;
  }
  if (checkOnly) {
    console.log(`✓ ${id} — exercice ${extras.exercise.length} car. + ${extras.resources.length} ressource(s) + ${quiz.length} question(s)`);
    continue;
  }

  const patch = await rest(`chapters?id=eq.${id}`, {
    method: "PATCH",
    body: JSON.stringify({
      exercise: extras.exercise,
      resources: extras.resources,
      code_language: extras.code_language ?? "",
      starter_code: extras.starter_code ?? "",
      solution_code: extras.solution_code ?? "",
      videos: extras.videos ?? [],
    }),
  });
  if (!patch.ok) {
    console.log(`✗ ${id} — PATCH chapitre ${patch.status} ${patch.body.slice(0, 200)}`);
    failures += 1;
    continue;
  }

  const del = await rest(`quiz_questions?chapter_id=eq.${id}`, { method: "DELETE" });
  if (!del.ok) {
    console.log(`✗ ${id} — DELETE quiz ${del.status} ${del.body.slice(0, 200)}`);
    failures += 1;
    continue;
  }
  const rows = quiz.map((q, index) => ({
    id: `${id}-q${index + 1}`,
    chapter_id: id,
    question: q.question,
    choices: q.choices,
    answer_index: q.answer_index,
    explanation: q.explanation,
    position: index + 1,
  }));
  const insert = await rest("quiz_questions", {
    method: "POST",
    body: JSON.stringify(rows),
  });
  if (!insert.ok) {
    console.log(`✗ ${id} — INSERT quiz ${insert.status} ${insert.body.slice(0, 200)}`);
    failures += 1;
    continue;
  }
  console.log(`✓ ${id} — exercice + ${extras.resources.length} ressource(s) + ${rows.length} question(s)`);
}

if (failures > 0) {
  console.log(`\n=== ${failures} ÉCHEC(S) ===`);
  process.exit(1);
}
console.log(checkOnly ? "\n=== EXTRAS CONFORMES ===" : "\n=== EXTRAS APPLIQUÉS ===");
