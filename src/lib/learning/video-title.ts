import type { ChapterVideo } from "@/lib/learning/types";

/**
 * Les leçons vidéo proviennent de chaînes externes : leurs titres bruts portent
 * des numéros d'épisode, le nom de la chaîne et du marketing. Ils sont réécrits
 * ici pour que l'apprenant lise une leçon easyTech.
 *
 * Filet de sécurité seulement : la source de vérité reste le titre saisi en
 * base, donc la réécriture ne doit jamais abîmer une phrase correcte.
 */

const EMOJI = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}\u{200B}-\u{200F}\u{202A}-\u{202E}]/gu;

const BRACKETS = /[[([]{1,2}[^\])]{0,44}[\])]{1,2}/g;

const EPISODE_MARK = /(?:^|\s)#\w+/g;

/** Phrases de marketing. Limites unicode (voir NOISE_TOKENS) : avec `\b`,
 *  « débutant » ne se detectait plus apres un espace et « complète » rognait
 *  « complètement ». */
const NOISE_PHRASES =
  /(?<![\p{L}\p{N}])(?:pour (?:les )?(?:débutant|débutants|debutant|debutants?)(?:e)?s?|débutant(?:e)?s?|pas[- ]à[- ]pas|tuto(?:riel|rial|rielle|s)?s?|cours? complet|complète|vostfr|facilement?|gratuitement?|en français)(?![\p{L}\p{N}])/giu;

/** Marqueurs techniques. Les limites doivent être unicode : `\b` considère
 *  « é » comme non-mot, ce qui rognait « fréquentes » en « équentes ». */
const NOISE_TOKENS =
  /(?<![\p{L}\p{N}])(?:hd|fhd|uhd|4k|1080p|720p|vostfr)(?![\p{L}\p{N}])/giu;

const LEADING_MARKER =
  /^(?:(?:[#]?\s*)?(?:le[çc]on|lesson|[ée]pisode|episode|parti(?:e|tie)|chapitre|module|s[ée]quence|section|tuto(?:riel)?|vid[ée]o|video|cours|part)\b[\s:.\-–—()/]*|\d{1,3}\s*(?:[./]\s*\d{1,3}\s*)?[\s:.\-–—()/]+|#\s*\d{1,4}[\s:.\-–—()/]+)/i;

/** « pour », « les »… restés seuls après une suppression. */
const TRAILING_DANGLING =
  /\s+(?:pour|avec|de|des|du|la|le|les|en|et|à|au|aux|sur|dans|par|sans|vers|que|qui|ou|ni|plus|très|tres)\b\s*$/i;

const LEADING_SEPARATOR = /^[\s:.\-–—|•·,]+/;

const TRAILING_EPISODE =
  /\s*[-–—|:•·]\s*(?:\p{L}[\p{L}\s+]{0,14})?\s*\d{1,3}\s*$/u;

const TRAILING_YEAR = /\b(?:19|20)\d{2}\b[\s:.\-–—|]*$/;

const TRAILING_SEPARATOR = /[\s:.\-–—|•·,]+$/;

const DOUBLE_SEPARATOR = /\s([-–—|:•·])\s*[-–—|:•·]\s*/g;

const DANGLING_TAIL =
  /\s+(?:pour|avec|de|des|du|la|le|les|en|et|à|au|aux|sur|dans|par|sans|sous|vers|que|qui|ou|ni|plus|tr[èe]s|comment|introduction|[ée]tape)\b[^-—]{0,3}$/i;

const MAX_LENGTH = 72;

/** Classe « séparateur » pour les regex construites à la volée ; le `-` doit
 *  rester en fin de classe, sinon il devient une plage de caractères. */
const SEP = "[\\s:.–—|•·-]";

function escapeForRegex(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** « | Grafikart », « - Grafikart » ou le premier mot de la chaîne en fin de titre. */
function channelCandidates(channel: string): string[] {
  const clean = channel.replace(/\s+/g, " ").trim();
  const words = clean
    .replace(/[^\p{L}\p{N} ]/gu, " ")
    .split(/\s+/)
    .filter((word) => word.length > 2);
  return [clean, words.join(" "), words[0] ?? ""].filter(Boolean);
}

export function cleanVideoTitle(raw: string, channel?: string): string {
  let title = raw
    .replace(EMOJI, " ")
    .replace(/\/{2,}/g, " - ")
    .replace(/\s+/g, " ")
    .trim();
  const untouched = title;

  title = title.replace(BRACKETS, " ");
  title = title.replace(EPISODE_MARK, " ");
  title = title.replace(NOISE_PHRASES, " ");
  title = title.replace(NOISE_TOKENS, " ");
  title = title.replace(/\s+/g, " ").replace(DOUBLE_SEPARATOR, " $1").trim();

  for (let pass = 0; pass < 3; pass += 1) {
    const stripped = title.replace(LEADING_MARKER, "").trim();
    if (stripped === title) break;
    title = stripped;
  }

  if (channel) {
    for (const candidate of channelCandidates(channel)) {
      const stripped = title
        .replace(
          new RegExp(`${SEP}+${escapeForRegex(candidate)}${SEP}*$`, "iu"),
          " ",
        )
        .trim();
      if (stripped === title) continue;
      title = stripped;
      break;
    }
  }

  title = title
    .replace(TRAILING_EPISODE, "")
    .replace(TRAILING_YEAR, "")
    .replace(TRAILING_SEPARATOR, "")
    .replace(LEADING_SEPARATOR, "")
    .replace(/\s+/g, " ")
    .trim();

  for (let pass = 0; pass < 3; pass += 1) {
    const trimmed = title.replace(TRAILING_DANGLING, "").trim();
    if (trimmed === title) break;
    title = trimmed;
  }

  if (title.length < 3) title = untouched;

  if (title.length > MAX_LENGTH) {
    const window = title.slice(0, MAX_LENGTH + 8);
    const cut = window.slice(0, MAX_LENGTH);
    const lastSpace = cut.lastIndexOf(" ");
    const base = lastSpace > 30 ? window.slice(0, lastSpace) : cut;
    title = `${base.replace(DANGLING_TAIL, "").replace(TRAILING_SEPARATOR, "")}…`;
  }

  return title.charAt(0).toUpperCase() + title.slice(1);
}

/** Titre affiché d'une leçon, avec repli numéroté si le brut est inutilisable. */
export function videoDisplayTitle(
  video: ChapterVideo,
  position: number,
  index: number,
): string {
  const cleaned = cleanVideoTitle(video.title, video.channel);
  return cleaned.length > 2 ? cleaned : `Leçon ${position}.${index + 1}`;
}
