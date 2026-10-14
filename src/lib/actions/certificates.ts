"use server";

import { links } from "@/config/site";
import { requireUser } from "@/lib/auth/dal";
import { ensureCertificates } from "@/lib/certificates/issue";
import { isCertificateTestAccount } from "@/lib/certificates/test-accounts";
import { createServerSupabase } from "@/lib/supabase/server";
import { createServiceSupabase } from "@/lib/supabase/service";

export type TestCertificateResult = {
  ok: boolean;
  code?: string;
  error?: string;
};

const TRACK_ID = "python-developpeur";

/**
 * Bouton de démonstration (dev + comptes de test uniquement) : valide le
 * niveau Débutant du parcours Python puis renvoie le code du certificat à
 * télécharger. Ne touche jamais à l'état d'un compte hors liste blanche.
 */
export async function issueTestCertificate(): Promise<TestCertificateResult> {
  const user = await requireUser(links.dashboard);
  if (!isCertificateTestAccount(user.email)) {
    return { ok: false, error: "unavailable" };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { ok: false, error: "no-db" };
  }

  // Le compte de test est sur liste blanche, mais l'écriture reste celle du
  // serveur : un apprenant ne peut déclarer lui-même un chapitre terminé.
  const service = createServiceSupabase();
  if (!service) {
    return { ok: false, error: "no-db" };
  }

  const { data: chapters, error: chaptersError } = await supabase
    .from("chapters")
    .select("id")
    .eq("track_id", TRACK_ID)
    .eq("level", "debutant")
    .eq("published", true)
    .order("position");

  if (chaptersError || !chapters || chapters.length === 0) {
    return { ok: false, error: "no-chapters" };
  }

  const { data: progress } = await supabase
    .from("chapter_progress")
    .select("chapter_id,status")
    .eq("user_id", user.id)
    .in("chapter_id", chapters.map((chapter) => chapter.id));

  const statusByChapter = new Map(
    (progress ?? []).map((row) => [row.chapter_id, row.status]),
  );
  const now = new Date().toISOString();

  const missing = chapters.filter((chapter) => !statusByChapter.has(chapter.id));
  const unfinished = chapters.filter(
    (chapter) =>
      statusByChapter.has(chapter.id) &&
      statusByChapter.get(chapter.id) !== "completed",
  );

  if (unfinished.length > 0) {
    const { error } = await service
      .from("chapter_progress")
      .update({ status: "completed", completed_at: now })
      .eq("user_id", user.id)
      .in("chapter_id", unfinished.map((chapter) => chapter.id));
    if (error) {
      console.error("[certificates] test complete", error.message);
      return { ok: false, error: error.message };
    }
  }

  if (missing.length > 0) {
    const { error } = await service.from("chapter_progress").upsert(
      missing.map((chapter) => ({
        user_id: user.id,
        chapter_id: chapter.id,
        track_id: TRACK_ID,
        status: "completed",
        attempts: 1,
        best_score: 100,
        completed_at: now,
      })),
      { onConflict: "user_id,chapter_id" },
    );
    if (error) {
      console.error("[certificates] test seed", error.message);
      return { ok: false, error: error.message };
    }
  }

  // L'examen final conditionne la délivrance : le bouton de test simule sa
  // réussite (compte de test uniquement, au même titre que les chapitres).
  const { data: exam } = await service
    .from("level_exams")
    .select("attempts,status")
    .eq("user_id", user.id)
    .eq("track_id", TRACK_ID)
    .eq("level", "debutant")
    .maybeSingle();

  if (!exam || exam.status !== "passed") {
    const { error: examError } = await service.from("level_exams").upsert(
      {
        user_id: user.id,
        track_id: TRACK_ID,
        level: "debutant",
        attempts: (exam?.attempts ?? 0) + 1,
        best_score: 100,
        status: "passed",
        passed_at: now,
      },
      { onConflict: "user_id,track_id,level" },
    );
    if (examError) {
      console.error("[certificates] test exam", examError.message);
      return { ok: false, error: examError.message };
    }
  }

  try {
    await ensureCertificates(user.id, TRACK_ID);
  } catch (error) {
    console.error("[certificates] test issue", error);
  }

  const { data: certificate } = await supabase
    .from("certificates")
    .select("code")
    .eq("user_id", user.id)
    .eq("track_id", TRACK_ID)
    .eq("level", "debutant")
    .maybeSingle();

  if (!certificate) {
    return { ok: false, error: "not-issued" };
  }
  return { ok: true, code: certificate.code };
}
