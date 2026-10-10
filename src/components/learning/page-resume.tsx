"use client";

import { useEffect, useRef } from "react";

import { readVisitedPages } from "@/components/learning/steps-nav";

/**
 * Reprise de lecture : quand l'apprenant arrive sur l'étape Cours sans
 * paramètre `page` (clic sidebar, lien vidéos, actualisation), on le renvoie
 * vers la dernière page mémorisée — comme la reprise de Cisco NetAcad.
 * Rechargement document assumé : un `router.replace` déclenché au montage
 * entre en concurrence avec les navigations `<Link>` et bloque le routeur.
 */
export function PageResume({
  trackSlug,
  chapterSlug,
  total,
}: {
  trackSlug: string;
  chapterSlug: string;
  total: number;
}) {
  const firedRef = useRef(false);

  useEffect(() => {
    if (firedRef.current) return;
    const params = new URLSearchParams(window.location.search);
    if (params.has("page")) return;
    const visited = readVisitedPages(trackSlug, chapterSlug);
    const last = visited[visited.length - 1];
    if (!last || last < 2 || last > total) return;
    firedRef.current = true;
    params.set("page", String(last));
    window.location.replace(
      `${window.location.pathname}?${params.toString()}`,
    );
  }, [trackSlug, chapterSlug, total]);

  return null;
}
