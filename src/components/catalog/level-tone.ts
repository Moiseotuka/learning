import type { LevelType } from "@/config/catalog";

/**
 * Un seul vert, quatre profondeurs : le palier se lit à l'intensité, pas à la teinte.
 */
export const levelTone: Record<LevelType, string> = {
  debutant: "bg-emerald-500/12 text-emerald-700 dark:text-emerald-400",
  intermediaire: "bg-electric/12 text-electric",
  avance: "bg-emerald-800/14 text-emerald-800 dark:text-emerald-300",
  projet: "bg-forest/12 text-forest dark:text-emerald-200",
};
