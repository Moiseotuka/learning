export function stepStorageKey(trackSlug: string, chapterSlug: string) {
  return `easylearn:step:${trackSlug}:${chapterSlug}`;
}

export function readStoredStep(
  trackSlug: string,
  chapterSlug: string,
): string | null {
  try {
    return localStorage.getItem(stepStorageKey(trackSlug, chapterSlug));
  } catch {
    return null;
  }
}

function visitedStorageKey(trackSlug: string, chapterSlug: string) {
  return `easylearn:visited:${trackSlug}:${chapterSlug}`;
}

/** Étapes déjà ouvertes par l'apprenant (mémoire locale, hors serveur). */
export function readVisitedSteps(
  trackSlug: string,
  chapterSlug: string,
): string[] {
  try {
    const raw = localStorage.getItem(visitedStorageKey(trackSlug, chapterSlug));
    if (!raw) return [];
    const parsed: unknown = JSON.parse(raw);
    return Array.isArray(parsed)
      ? parsed.filter((item): item is string => typeof item === "string")
      : [];
  } catch {
    return [];
  }
}

export function writeVisitedSteps(
  trackSlug: string,
  chapterSlug: string,
  steps: string[],
): void {
  try {
    localStorage.setItem(
      visitedStorageKey(trackSlug, chapterSlug),
      JSON.stringify(steps),
    );
  } catch {
    /* stockage indisponible : les coches de visite ne seront pas mémorisées */
  }
}

function visitedPagesKey(trackSlug: string, chapterSlug: string) {
  return `easylearn:pages:${trackSlug}:${chapterSlug}`;
}

/** Pages du Cours déjà ouvertes, dans l'ordre de visite (mémoire locale). */
export function readVisitedPages(
  trackSlug: string,
  chapterSlug: string,
): number[] {
  try {
    const raw = localStorage.getItem(visitedPagesKey(trackSlug, chapterSlug));
    if (!raw) return [];
    const parsed: unknown = JSON.parse(raw);
    return Array.isArray(parsed)
      ? parsed.filter(
          (item): item is number => typeof item === "number" && item >= 1,
        )
      : [];
  } catch {
    return [];
  }
}

export function writeVisitedPages(
  trackSlug: string,
  chapterSlug: string,
  pages: number[],
): void {
  try {
    localStorage.setItem(
      visitedPagesKey(trackSlug, chapterSlug),
      JSON.stringify(pages),
    );
  } catch {
    /* stockage indisponible : les coches de pages ne seront pas mémorisées */
  }
}
