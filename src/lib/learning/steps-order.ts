/**
 * Ordre pédagogique des étapes d'un chapitre.
 *
 * L'apprenant découvre d'abord la leçon en vidéo, puis en lit la version écrite
 * (cours), la consolide par l'exercice et approfondit avec les ressources. Cet
 * ordre unique sert aussi à numéroter les pages du cours (chapitre.étape.page).
 */
const DOC_STEPS = ["objectifs", "cours", "exercice", "ressources"] as const;
const DOC_STEPS_WITH_VIDEOS = [
  "objectifs",
  "videos",
  "cours",
  "exercice",
  "ressources",
] as const;

export function chapterStepOrder(hasVideos: boolean): string[] {
  return hasVideos ? [...DOC_STEPS_WITH_VIDEOS] : [...DOC_STEPS];
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
