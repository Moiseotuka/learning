const DOC_STEPS = ["objectifs", "cours", "exercice", "ressources"] as const;
const DOC_STEPS_WITH_VIDEOS = [
  "objectifs",
  "videos",
  "cours",
  "exercice",
  "ressources",
] as const;

/**
 * Ordre canonique des étapes (indépendant du tirage aléatoire du jour) :
 * sert à numéroter le Cours comme dans Cisco NetAcad (chapitre.étape.page).
 */
export function canonicalStepOrder(hasVideos: boolean): string[] {
  return hasVideos ? [...DOC_STEPS_WITH_VIDEOS] : [...DOC_STEPS];
}

function hashString(value: string): number {
  let hash = 2166136261;
  for (let i = 0; i < value.length; i += 1) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return Math.abs(hash);
}

/**
 * Ordre des étapes d'un chapitre.
 *
 * Les chapitres sans vidéo suivent toujours l'ordre document
 * (Objectifs → Cours → Exercice → Ressources). Ceux qui ont des vidéos
 * alternent aléatoirement entre « Vidéos avant le Cours » et « Cours avant
 * les Vidéos » : le tirage dépend du chapitre et du jour (UTC), donc l'ordre
 * varie d'un chapitre à l'autre et d'un jour à l'autre, tout en restant
 * stable pendant la journée (rendu serveur et client identiques).
 */
export function chapterStepOrder(
  hasVideos: boolean,
  chapterId: string,
): string[] {
  if (!hasVideos) return [...DOC_STEPS];
  const day = new Date().toISOString().slice(0, 10);
  const videosFirst = hashString(`${chapterId}|${day}`) % 2 === 0;
  return videosFirst
    ? ["objectifs", "videos", "cours", "exercice", "ressources"]
    : ["objectifs", "cours", "videos", "exercice", "ressources"];
}

/**
 * Tant que les vidéos ne sont pas terminées, seules les étapes situées avant
 * (ou sur) l'étape Vidéos sont accessibles : tout ce qui vient après — dont le
 * quiz, absent de l'ordre — est bloqué.
 */
export function stepBlockedByVideos(
  step: string,
  order: string[],
  videosBlocked: boolean,
): boolean {
  if (!videosBlocked) return false;
  const videoIndex = order.indexOf("videos");
  if (videoIndex < 0) return false;
  const stepIndex = order.indexOf(step);
  return stepIndex < 0 || stepIndex > videoIndex;
}
