import { messages } from "@/i18n";

const t = messages.admin;

const NOMBRES = new Intl.NumberFormat("fr-FR");

/** Fuseau de l'exploitation : les chiffres que regarde l'admin sont ceux de Kinshasa. */
export const FUSEAU = "Africa/Lubumbashi";

export function nombre(valeur: number | null | undefined): string {
  return valeur === null || valeur === undefined
    ? t.dashboard.unavailable
    : NOMBRES.format(valeur);
}

export function argent(valeur: number, devise: string): string {
  return `${NOMBRES.format(valeur)} ${devise}`;
}

export function jourCourt(iso: string): string {
  const [, mois, jour] = iso.slice(0, 10).split("-");
  return `${jour}/${mois}`;
}

export function dateCourte(iso: string): string {
  return new Date(iso).toLocaleDateString("fr-FR", { timeZone: FUSEAU });
}

export function heureCourte(iso: string): string {
  return new Date(iso).toLocaleString("fr-FR", {
    timeZone: FUSEAU,
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/** Les canaux connus sont traduits ; un utm_source inventé reste affiché tel quel. */
export function nomCanal(source: string): string {
  return t.canaux[source as keyof typeof t.canaux] ?? source;
}

export function nomMedium(medium: string): string {
  return t.mediums[medium as keyof typeof t.mediums] ?? medium;
}

export function nomAppareil(appareil: string): string {
  return t.appareils[appareil as keyof typeof t.appareils] ?? appareil;
}

let affichagePays: Intl.DisplayNames | null = null;

/** Un code pays de Vercel (« CD ») se lit « République démocratique du Congo » ; le reste passe tel quel. */
export function nomPays(code: string): string {
  if (code.length !== 2) return code;
  const affichage = (affichagePays ??= new Intl.DisplayNames(["fr"], { type: "region" }));
  try {
    return affichage.of(code.toUpperCase()) ?? code.toUpperCase();
  } catch {
    return code.toUpperCase();
  }
}

export function libelleStatut(statut: string): string {
  return t.dashboard.statusLabels[statut as keyof typeof t.dashboard.statusLabels] ?? statut;
}

export function nomRole(role: string): string {
  return t.utilisateurs.roles[role as keyof typeof t.utilisateurs.roles] ?? role;
}
