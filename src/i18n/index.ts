import { fr } from "./messages/fr";

export type Messages = typeof fr;

export const locales = ["fr", "en"] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = "fr";

/**
 * Dictionnaire actif.
 * Étape i18n : basculer sur `getMessages(locale)` avec `en.ts`
 * (même forme de données, typé par `Messages`).
 */
export const messages: Messages = fr;

const dictionaries: Partial<Record<Locale, Messages>> = { fr };

export function getMessages(locale: Locale): Messages {
  return dictionaries[locale] ?? fr;
}
