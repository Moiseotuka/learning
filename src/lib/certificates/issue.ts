import { messages } from "@/i18n";
import { sendCertificateEmail } from "@/lib/email/certificate";
import { createServiceSupabase } from "@/lib/supabase/service";

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

/** Alphabet sans I, L, O, 0, 1 : le code est recopié à la main ou lu sur le PDF. */
const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

/**
 * Code non séquentiel : un numéro incrémenté se devine, et la page de
 * vérification publique affiche le nom du titulaire.
 */
function newCode(prefix: string, year: number): string {
  const bytes = new Uint8Array(8);
  crypto.getRandomValues(bytes);
  const suffix = Array.from(bytes, (b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join("");
  return `${prefix}-${year}-${suffix}`;
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
  const realName = (profile?.full_name ?? "").trim();
  const fullName = realName || (profile?.email ?? "").split("@")[0] || "Apprenant";

  const chaptersByTrack = new Map<string, ChapterRow[]>();
  for (const chapter of chapters) {
    const list = chaptersByTrack.get(chapter.track_id) ?? [];
    list.push(chapter);
    chaptersByTrack.set(chapter.track_id, list);
  }

  const { data: existingRows } = await supabase
    .from("certificates")
    .select("id,track_id,level,full_name")
    .eq("user_id", userId);

  const rows = (existingRows ?? []) as {
    id: string;
    track_id: string;
    level: string;
    full_name: string;
  }[];

  // Le nom est figé à l'émission : un certificat créé avant que l'apprenant
  // renseigne son nom (ou avec l'email en secours) est corrigé ici.
  if (realName) {
    for (const row of rows.filter((item) => item.full_name !== realName)) {
      const { error } = await supabase
        .from("certificates")
        .update({ full_name: realName })
        .eq("id", row.id);
      if (error) console.error("[certificates] rename", error.message);
    }
  }

  const existing = new Set(
    rows.map((row) => `${row.track_id}:${row.level}`),
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

    // Deux rendus simultanés peuvent tirer le même code : on en regénère un
    // autre (la ligne fautive est déjà en base).
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = newCode(prefix, year);
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
