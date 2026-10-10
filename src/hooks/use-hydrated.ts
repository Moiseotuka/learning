"use client";

import { useSyncExternalStore } from "react";

const emptySubscribe = () => () => {};

/**
 * Détecte si le composant est hydraté côté client, sans effet ni désynchronisation.
 * (Le thème résolu ne peut être lu qu'après hydratation pour éviter le flash.)
 */
export function useHydrated() {
  return useSyncExternalStore(
    emptySubscribe,
    () => true,
    () => false,
  );
}
