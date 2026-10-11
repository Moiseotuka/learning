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

/**
 * Ordre des étapes d'un chapitre.
 *
 * La progression pédagogique doit rester cohérente : on explique d'abord le
 * concept dans le cours, puis on propose les vidéos associées, ensuite l'exercice
 * et enfin les ressources. Les chapitres sans vidéo gardent l'ordre document.
 */
export function chapterStepOrder(
  hasVideos: boolean,
  _chapterId: string,
): string[] {
  if (!hasVideos) return [...DOC_STEPS];
  return ["objectifs", "cours", "videos", "exercice", "ressources"];
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
