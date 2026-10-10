export type LevelPriceRecord = Record<string, number> | Map<string, number>;

const UPGRADE_LEVELS = ["intermediaire", "avance", "projet"] as const;

/**
 * Prix d'entrée public pour une catégorie.
 * - null : aucun tarif publié → ne rien afficher
 * - 0 : uniquement le niveau débutant (gratuit par règle) → « Gratuit »
 * - n : prix du niveau payant le moins cher (« À partir de n $ »)
 */
export function startingPrice(
  prices: LevelPriceRecord | null | undefined,
): number | null {
  if (!prices) return null;

  const get = (level: string): number | undefined =>
    prices instanceof Map ? prices.get(level) : prices[level];

  let min: number | undefined;
  for (const level of UPGRADE_LEVELS) {
    const price = get(level);
    if (typeof price === "number" && (min === undefined || price < min)) {
      min = price;
    }
  }
  if (min !== undefined) return min;

  return typeof get("debutant") === "number" ? 0 : null;
}
