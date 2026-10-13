"use client";

import { useEffect, useRef } from "react";

import { saveResume } from "@/lib/actions/progress";

/** Le lecteur de parcours fait défiler une div, pas la fenêtre : `window.scrollY`
 *  reste à 0. On cherche donc le premier ancêtre réellement défilable. */
function findScrollHost(from: HTMLElement | null): HTMLElement | null {
  let node = from?.parentElement ?? null;
  while (node) {
    const overflow = window.getComputedStyle(node).overflowY;
    if (
      (overflow === "auto" || overflow === "scroll") &&
      node.scrollHeight > node.clientHeight
    ) {
      return node;
    }
    node = node.parentElement;
  }
  return null;
}

function positionOf(host: HTMLElement | null) {
  return host ? Math.round(host.scrollTop) : Math.round(window.scrollY);
}

/**
 * Repère de reprise du chapitre : mémorise l'étape ouverte, la page du cours
 * écrit et la position de défilement de cette étape, puis restaure cette
 * position à l'arrivée. Écriture débounceée : une requête quand l'apprenant
 * s'arrête, pas pendant la lecture.
 */
export function LessonResume({
  chapterId,
  step,
  page,
  initialScroll,
}: {
  chapterId: string;
  /** Étape du chapitre affichée : objectifs, vidéos, cours, exercice… */
  step: string;
  page?: number;
  initialScroll?: number | null;
}) {
  const anchorRef = useRef<HTMLDivElement>(null);
  const hostRef = useRef<HTMLElement | null>(null);
  const writtenRef = useRef(0);
  const stepRef = useRef(step);
  const pageRef = useRef(page);

  useEffect(() => {
    const target = initialScroll ?? 0;
    if (target <= 0) return;
    const id = window.setTimeout(() => {
      const host = findScrollHost(anchorRef.current);
      if (host) host.scrollTop = target;
    }, 140);
    return () => window.clearTimeout(id);
  }, [initialScroll, step]);

  // Étape courante : c'est elle que le serveur propose en reprise.
  useEffect(() => {
    stepRef.current = step;
    void saveResume({ chapterId, step }).catch(() => undefined);
  }, [chapterId, step]);

  useEffect(() => {
    pageRef.current = page;
    if (page === undefined) return;
    void saveResume({ chapterId, page }).catch(() => undefined);
  }, [chapterId, page]);

  useEffect(() => {
    // L'évènement `scroll` ne bulle pas : capture sur document attrape le
    // conteneur du lecteur quelle que soit sa profondeur.
    let timer = 0;
    const onScroll = (event: Event) => {
      const target = event.target;
      if (target instanceof HTMLElement) hostRef.current = target;
      window.clearTimeout(timer);
      timer = window.setTimeout(() => {
        const host =
          hostRef.current ?? findScrollHost(anchorRef.current) ?? undefined;
        hostRef.current = host ?? null;
        const value = positionOf(host ?? null);
        if (Math.abs(value - writtenRef.current) < 24) return;
        writtenRef.current = value;
        void saveResume({
          chapterId,
          step: stepRef.current,
          page: pageRef.current,
          scroll: value,
        }).catch(() => undefined);
      }, 1200);
    };

    document.addEventListener("scroll", onScroll, {
      capture: true,
      passive: true,
    });
    return () => {
      window.clearTimeout(timer);
      document.removeEventListener("scroll", onScroll, { capture: true });
    };
  }, [chapterId]);

  return <div ref={anchorRef} className="h-0" aria-hidden />;
}
