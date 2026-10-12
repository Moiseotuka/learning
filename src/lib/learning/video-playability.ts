import { extractYouTubeId } from "@/lib/embed-url";
import type { ChapterVideo } from "@/lib/learning/types";

/**
 * Une vidéo n'est « jouable » que si l'on peut la lire dans le lecteur intégré.
 *
 * Le jeton calculé ici sert à la fois au suivi de visionnage, au déblocage du
 * quiz et à la playlist : les trois doivent employer la même règle, sinon une
 * URL invalide en base verrouille le chapitre entier sans aucun recours.
 */

const DIRECT_FILE = /\.(mp4|webm|ogg|ogv)(\?.*)?$/i;

type VideoUrl = Pick<ChapterVideo, "url">;

/** Jeton de suivi : identifiant YouTube, ou URL de fichier direct. */
export function videoToken(video: VideoUrl): string | null {
  const url = typeof video.url === "string" ? video.url.trim() : "";
  if (!url) return null;
  const id = extractYouTubeId(url);
  if (id) return id;
  return DIRECT_FILE.test(url) ? url : null;
}

export function isPlayableVideo(video: VideoUrl): boolean {
  return videoToken(video) !== null;
}

export function playableVideos<T extends VideoUrl>(videos: T[]): T[] {
  return videos.filter(isPlayableVideo);
}

export function videoTokens(videos: VideoUrl[]): string[] {
  return videos.reduce<string[]>((tokens, video) => {
    const token = videoToken(video);
    if (token) tokens.push(token);
    return tokens;
  }, []);
}
