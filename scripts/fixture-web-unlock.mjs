/**
 * Fixture de déverrouillage pour la validation de contenu (dev) :
 * marque TOUS les chapitres d'un parcours comme « completed », crée l'examen
 * de niveau passé (sauf pour le dernier niveau) et les achats des niveaux
 * payants — pour que l'apprenant de test puisse visiter chaque chapitre.
 *
 * Dev/staging uniquement. Idempotent (upserts).
 *
 * Usage : node scripts/fixture-web-unlock.mjs <track-slug> <category-id>
 * Ex.   : node scripts/fixture-web-unlock.mjs developpement-web-moderne web
 */
import { createClient } from "@supabase/supabase-js";
import { serviceEnv } from "./e2e-setup.mjs";

const [trackSlug, categoryId] = process.argv.slice(2);
if (!trackSlug || !categoryId) {
  console.error("Usage : node scripts/fixture-web-unlock.mjs <track-slug> <category-id>");
  process.exit(1);
}

const { url, key } = serviceEnv();
const admin = createClient(url, key, { auth: { persistSession: false } });

async function findUserByEmail(email) {
  const res = await fetch(
    `${url}/auth/v1/admin/users?page=1&per_page=200`,
    { headers: { apikey: key, Authorization: `Bearer ${key}` } },
  );
  if (!res.ok) throw new Error(`admin users: ${res.status}`);
  const body = await res.json();
  const user = (body.users ?? []).find((u) => (u.email ?? "").toLowerCase() === email);
  if (!user) throw new Error(`utilisateur introuvable : ${email}`);
  return user.id;
}

const userId = await findUserByEmail("quiz-test@easylearn.dev");

const { data: track, error: trackErr } = await admin
  .from("tracks")
  .select("id")
  .eq("slug", trackSlug)
  .single();
if (trackErr) throw new Error(trackErr.message);

const { data: chapters, error: chErr } = await admin
  .from("chapters")
  .select("id,level,position")
  .eq("track_id", track.id)
  .eq("published", true)
  .order("position");
if (chErr) throw new Error(chErr.message);

const now = new Date().toISOString();
const progress = chapters.map((chapter) => ({
  user_id: userId,
  chapter_id: chapter.id,
  track_id: track.id,
  attempts: 1,
  best_score: 100,
  status: "completed",
  completed_at: now,
  practice_done: true,
}));
const { error: pErr } = await admin
  .from("chapter_progress")
  .upsert(progress, { onConflict: "user_id,chapter_id" });
if (pErr) throw new Error(`chapter_progress : ${pErr.message}`);

const levels = [];
for (const chapter of chapters) {
  if (!levels.includes(chapter.level)) levels.push(chapter.level);
}
const exams = levels.slice(0, -1).map((level) => ({
  user_id: userId,
  track_id: track.id,
  level,
  attempts: 1,
  best_score: 100,
  status: "passed",
  passed_at: now,
}));
if (exams.length > 0) {
  const { error: eErr } = await admin
    .from("level_exams")
    .upsert(exams, { onConflict: "user_id,track_id,level" });
  if (eErr) throw new Error(`level_exams : ${eErr.message}`);
}

const paidLevels = levels
  .filter((level) => level !== "debutant")
  .map((level) => ({
    user_id: userId,
    category_id: categoryId,
    level,
    amount_usd: 0,
    provider: "mock",
    status: "paid",
    paid_at: now,
  }));
if (paidLevels.length > 0) {
  const { error: bErr } = await admin
    .from("purchases")
    .upsert(paidLevels, { onConflict: "user_id,category_id,level" });
  if (bErr) throw new Error(`purchases : ${bErr.message}`);
}

console.log(
  `✓ ${trackSlug} déverrouillé — ${progress.length} chapitre(s) completed, ` +
    `${exams.length} examen(s) passed, ${paidLevels.length} achat(s) payé(s)`,
);
