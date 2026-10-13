"use client";

/**
 * Observation du réseau du navigateur.
 *
 * La mesure passe par `useSyncExternalStore` plutôt que par un effet : l'état
 * serveur ignore `navigator.connection`, donc un effet devrait écrire dans un
 * état déjà rendu et ferait vaciller les boutons de qualité au premier affichage.
 * React lit ici la valeur du serveur pendant l'hydratation, puis la valeur réelle
 * dès que le store est monté.
 */

import { useSyncExternalStore } from "react";

import { detectBandwidthMode, networkConnection, type LiveBandwidthMode } from "./provider";

const listeners = new Set<() => void>();
let cached: LiveBandwidthMode | null = null;

function snapshot(): LiveBandwidthMode {
  cached ??= detectBandwidthMode();
  return cached;
}

function serverSnapshot(): LiveBandwidthMode {
  return "hd";
}

function notify(): void {
  cached = null;
  for (const listener of listeners) listener();
}

function subscribe(listener: () => void): () => void {
  listeners.add(listener);
  const connection = networkConnection();
  connection?.addEventListener?.("change", notify);
  return () => {
    listeners.delete(listener);
    connection?.removeEventListener?.("change", notify);
  };
}

export function useBandwidthMode(): LiveBandwidthMode {
  return useSyncExternalStore(subscribe, snapshot, serverSnapshot);
}
