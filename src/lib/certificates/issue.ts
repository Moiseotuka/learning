import { messages } from "@/i18n";
import { sendCertificateEmail } from "@/lib/email/certificate";
import { createServiceSupabase } from "@/lib/supabase/service";
import type { SupabaseClient } from "@supabase/supabase-js";

export type IssuedCertificate = {
  id: string;
  code: string;
  level: string;
  title: string;
};

const LEVELS = ["debutant", "intermediaire", "avance", "projet"] as const;

type TrackRow = { id: string; slug: string; title: string };
type ChapterRow = { id: string; track_id: string; level: string };

function certificateTitle(trackTitle: string, level: string): string {
  const topic = trackTitle.split(":")[0].trim() || trackTitle;
  if (level === "parcours") {
    return `${topic} : Parcours complet`;
  }
  const label =
    messages.common.levels[level as keyof typeof messages.common.levels] ??
    level;
  return `${topic} : niveau ${label}`;
}

function codePrefix(trackSlug: string): string {
  const letters = trackSlug.replace(/[^a-z0-9]/gi, "").slice(0, 3).toUpperCase();
  return letters.padEnd(3, "X");
}

async function nextCode(
  supabase: SupabaseClient,
  prefix: string,
  year: number,
): Promise<string> {
  const { data } = await supabase
    .from("certificates")
    .select("code")
    .like("code", `${prefix}-${year}-%`);

  let max = 0;
  for (const row of (data ?? []) as { code: string }[]) {
    const suffix = Number.parseInt(row.code.split("-")[2] ?? "0", 10);
    if (Number.isFinite(suffix) && suffix > max) max = suffix;
  }

  return `${prefix}-${year}-${String(max + 1).padStart(6, "0")}`;
}

/**
 * Délivre automatiquement les certificats dus à l'apprenant :
 *  · un certificat par niveau dont TOUS les chapitres sont validés ET dont
 *    l'examen final (level_exams) est réussi ;
 *  · un certificat « parcours » quand 100 % des chapitres sont validés ET
 *    que TOUS les examens des niveaux du parcours sont réussis.
 * Idempotent (contrainte unique user/track/level + on conflict do nothing).
 * Chaque certificat nouvellement créé déclenche l'email de notification.
 */
export async function ensureCertificates(
  userId: string,
  trackId?: string,
): Promise<IssuedCertificate[]> {
  const supabase = createServiceSupabase();
  if (!supabase) return [];

  const [tracksResult, chaptersResult, progressResult, profileResult, examsResult] =
    await Promise.all([
      supabase
        .from("tracks")
        .select("id,slug,title")
        .eq("published", true)
        .order("position"),
      supabase
        .from("chapters")
        .select("id,track_id,level")
        .eq("published", true)
        .order("position"),
      supabase
        .from("chapter_progress")
        .select("chapter_id,status")
        .eq("user_id", userId)
        .eq("status", "completed"),
      supabase
        .from("profiles")
        .select("full_name,email")
        .eq("id", userId)
        .maybeSingle(),
      supabase
        .from("level_exams")
        .select("track_id,level,status")
        .eq("user_id", userId),
    ]);

  if (tracksResult.error || chaptersResult.error || progressResult.error) {
    console.error(
      "[certificates] lecture",
      tracksResult.error?.message ??
        chaptersResult.error?.message ??
        progressResult.error?.message ??
        "no data",
    );
    return [];
  }

  if (examsResult.error) {
    console.warn(
      "[certificates] examens : table absente — coller la migration 202610020002_level_exams.sql",
      examsResult.error.message,
    );
  }

  const tracks = (tracksResult.data ?? []) as TrackRow[];
  const chapters = (chaptersResult.data ?? []) as ChapterRow[];
  const completedIds = new Set(
    ((progressResult.data ?? []) as { chapter_id: string }[]).map(
      (row) => row.chapter_id,
    ),
  );
  if (completedIds.size === 0) return [];

  const examPassed = new Set(
    ((examsResult.data ?? []) as {
      track_id: string;
      level: string;
      status: string;
    }[])
      .filter((row) => row.status === "passed")
      .map((row) => `${row.track_id}:${row.level}`),
  );

  const profile = profileResult.data as {
    full_name: string | null;
    email: string | null;
  } | null;
  const fullName =
    (profile?.full_name ?? "").trim() ||
    (profile?.email ?? "").split("@")[0] ||
    "Apprenant";

  const chaptersByTrack = new Map<string, ChapterRow[]>();
  for (const chapter of chapters) {
    const list = chaptersByTrack.get(chapter.track_id) ?? [];
    list.push(chapter);
    chaptersByTrack.set(chapter.track_id, list);
  }

  const { data: existingRows } = await supabase
    .from("certificates")
    .select("track_id,level")
    .eq("user_id", userId);

  const existing = new Set(
    ((existingRows ?? []) as { track_id: string; level: string }[]).map(
      (row) => `${row.track_id}:${row.level}`,
    ),
  );

  type Candidate = { track: TrackRow; level: string };
  const candidates: Candidate[] = [];

  for (const track of tracks) {
    if (trackId && track.id !== trackId) continue;
    const trackChapters = chaptersByTrack.get(track.id);
    if (!trackChapters || trackChapters.length === 0) continue;

    const allCompleted = trackChapters.every((chapter) =>
      completedIds.has(chapter.id),
    );

    const levels = new Set(trackChapters.map((chapter) => chapter.level));
    const allExamsPassed = [...levels].every((level) =>
      examPassed.has(`${track.id}:${level}`),
    );

    if (
      allCompleted &&
      allExamsPassed &&
      !existing.has(`${track.id}:parcours`)
    ) {
      candidates.push({ track, level: "parcours" });
    }

    for (const level of LEVELS) {
      if (!levels.has(level)) continue;
      if (existing.has(`${track.id}:${level}`)) continue;
      const levelDone = trackChapters
        .filter((chapter) => chapter.level === level)
        .every((chapter) => completedIds.has(chapter.id));
      if (levelDone && examPassed.has(`${track.id}:${level}`)) {
        candidates.push({ track, level });
      }
    }
  }

  if (candidates.length === 0) return [];

  const issued: IssuedCertificate[] = [];
  const year = new Date().getFullYear();

  for (const candidate of candidates) {
    const title = certificateTitle(candidate.track.title, candidate.level);
    const prefix = codePrefix(candidate.track.slug);

    let row: {
      id: string;
      code: string;
      level: string;
      title: string;
      issued_at: string;
    } | null = null;

    // Deux rendus simultanés peuvent calculer le même code : en cas de
    // collision on recompte (la ligne fautive est déjà en base).
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = await nextCode(supabase, prefix, year);
      const result = await supabase
        .from("certificates")
        .upsert(
          {
            user_id: userId,
            track_id: candidate.track.id,
            level: candidate.level,
            code,
            title,
            track_title: candidate.track.title,
            full_name: fullName,
          },
          { onConflict: "user_id,track_id,level", ignoreDuplicates: true },
        )
        .select("id,code,level,title,issued_at")
        .maybeSingle();

      if (result.error) {
        if (
          result.error.code === "23505" &&
          result.error.message.includes("certificates_code_key")
        ) {
          continue;
        }
        console.error("[certificates] insert", result.error.message);
        break;
      }
      row = result.data;
      break;
    }

    if (!row) continue;

    issued.push(row);

    if (profile?.email) {
      try {
        await sendCertificateEmail({
          to: profile.email,
          name: fullName,
          title,
          code: row.code,
          issuedAt: row.issued_at,
        });
      } catch (error) {
        console.error("[certificates] email", error);
      }
    }
  }

  return issued;
}
