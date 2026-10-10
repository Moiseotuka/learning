/**
 * Fixtures E2E (setup uniquement) : marque les vidéos d'un chapitre comme
 * regardées dans chapter_progress.videos_watched via l'API REST avec la
 * service role — l'équivalent exact d'un visionnage complet côté serveur.
 *
 * Ne touche jamais au schéma : si la colonne videos_watched n'existe pas
 * (migrations Phase A non collées), retourne { ok:false, reason:"no-migration" }.
 */
import { readFileSync } from "node:fs";

function envValue(key) {
  const raw = readFileSync(new URL("../.env.local", import.meta.url), "utf8");
  const match = raw.match(new RegExp(`^${key}=(.*)$`, "m"));
  return match ? match[1].trim() : "";
}

/** Miroir de src/lib/embed-url.ts (extractYouTubeId). */
function extractYouTubeId(url) {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.replace(/^www\./, "");
    if (host === "youtu.be") {
      const id = parsed.pathname.slice(1);
      return id || null;
    }
    if (
      host === "youtube.com" ||
      host === "m.youtube.com" ||
      host === "music.youtube.com"
    ) {
      const id = parsed.searchParams.get("v");
      if (id) return id;
      const parts = parsed.pathname.split("/").filter(Boolean);
      if (parts[0] === "shorts" && parts[1]) return parts[1];
      return null;
    }
    if (host.endsWith("youtube-nocookie.com")) {
      const parts = parsed.pathname.split("/").filter(Boolean);
      if (parts[0] === "embed" && parts[1]) return parts[1];
      return null;
    }
    return null;
  } catch {
    return null;
  }
}

export function serviceEnv() {
  const url = envValue("NEXT_PUBLIC_SUPABASE_URL");
  const key =
    envValue("SUPABASE_SERVICE_ROLE_KEY") || envValue("SUPABASE_SECRET_KEY");
  return { url, key };
}

async function findUserByEmail(url, headers, email) {
  const usersRes = await fetch(
    `${url}/auth/v1/admin/users?page=1&per_page=200`,
    { headers },
  );
  if (!usersRes.ok) {
    return { error: { reason: "admin-users", detail: await usersRes.text() } };
  }
  const usersData = await usersRes.json();
  const user = (usersData.users ?? []).find(
    (item) => (item.email ?? "").toLowerCase() === email.toLowerCase(),
  );
  if (!user) return { error: { reason: "user-not-found" } };
  return { user };
}

async function probeMigration(url, headers) {
  const probe = await fetch(
    `${url}/rest/v1/chapter_progress?select=videos_watched&limit=1`,
    { headers },
  );
  if (!probe.ok) {
    return {
      error: { reason: "no-migration", detail: await probe.text() },
    };
  }
  return {};
}

/** Remet videos_watched à [] (fixture idempotente pour les assertions bloquées). */
export async function resetChapterVideosWatched({ email, chapterId }) {
  const { url, key } = serviceEnv();
  if (!url || !key) {
    return { ok: false, reason: "no-service-key" };
  }
  const headers = {
    apikey: key,
    Authorization: `Bearer ${key}`,
  };

  const probe = await probeMigration(url, headers);
  if (probe.error) return { ok: false, ...probe.error };

  const { user, error: userError } = await findUserByEmail(url, headers, email);
  if (userError) return { ok: false, ...userError };

  const patchRes = await fetch(
    `${url}/rest/v1/chapter_progress?user_id=eq.${user.id}&chapter_id=eq.${encodeURIComponent(chapterId)}`,
    {
      method: "PATCH",
      headers: {
        ...headers,
        "Content-Type": "application/json",
        Prefer: "return=representation",
      },
      body: JSON.stringify({ videos_watched: [] }),
    },
  );
  if (!patchRes.ok) {
    return {
      ok: false,
      reason: "reset-failed",
      detail: await patchRes.text(),
    };
  }
  const rows = await patchRes.json();
  return { ok: true, rows: rows.length };
}

export async function markChapterVideosWatched({
  email,
  chapterId,
  trackId,
}) {
  const { url, key } = serviceEnv();
  if (!url || !key) {
    return { ok: false, reason: "no-service-key" };
  }
  const headers = {
    apikey: key,
    Authorization: `Bearer ${key}`,
  };

  const probe = await probeMigration(url, headers);
  if (probe.error) return { ok: false, ...probe.error };

  const { user, error: userError } = await findUserByEmail(url, headers, email);
  if (userError) return { ok: false, ...userError };

  const chapterRes = await fetch(
    `${url}/rest/v1/chapters?select=videos&id=eq.${encodeURIComponent(chapterId)}`,
    { headers },
  );
  if (!chapterRes.ok) {
    return { ok: false, reason: "chapter", detail: await chapterRes.text() };
  }
  const chapterRows = await chapterRes.json();
  const videos = chapterRows[0]?.videos ?? [];
  const tokens = videos
    .map((video) =>
      typeof video?.url === "string"
        ? extractYouTubeId(video.url) ?? video.url
        : "",
    )
    .filter((token) => token.length > 0);

  const patchRes = await fetch(
    `${url}/rest/v1/chapter_progress?on_conflict=user_id,chapter_id`,
    {
      method: "POST",
      headers: {
        ...headers,
        "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
      body: JSON.stringify([
        {
          user_id: user.id,
          chapter_id: chapterId,
          track_id: trackId,
          videos_watched: tokens,
        },
      ]),
    },
  );
  if (!patchRes.ok) {
    return {
      ok: false,
      reason: "upsert-failed",
      detail: await patchRes.text(),
    };
  }

  return { ok: true, tokens };
}
