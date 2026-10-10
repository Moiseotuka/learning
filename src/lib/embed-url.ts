/**
 * Convertit une URL externe en URL d'intégration (iframe).
 * Retourne null si le lien n'est pas une vidéo intégrable.
 */

/** Intégration YouTube : rel=0 coupe les suggestions tierces,
 *  playsinline=1 évite le renvoi vers l'app mobile.
 *  Utilise youtube.com (pas nocookie) pour éviter le blocage "connexion requise". */
const yt = (id: string) =>
  `https://www.youtube.com/embed/${id}` +
  `?rel=0&playsinline=1`;

/** Identifiant de vidéo YouTube extrait d'une URL (null si ce n'est pas YouTube). */
export function extractYouTubeId(url: string): string | null {
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

export function toEmbedUrl(url: string): string | null {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.replace(/^www\./, "");

    if (host.endsWith("youtube-nocookie.com")) {
      const embed = new URL(url);
      embed.searchParams.set("rel", "0");
      embed.searchParams.set("playsinline", "1");
      return embed.toString();
    }

    const id = extractYouTubeId(url);
    if (id) return yt(id);

    if (host === "player.vimeo.com") return url;

    if (host === "vimeo.com") {
      const parts = parsed.pathname.split("/").filter(Boolean);
      const id = parts.pop();
      return id && /^\d+$/.test(id)
        ? `https://player.vimeo.com/video/${id}`
        : null;
    }

    return null;
  } catch {
    return null;
  }
}
