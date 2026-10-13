/**
 * Formatage partagé entre le serveur et le client : les montants et les dates
 * d'un abonnement sont calculés côté serveur, mais les libellés de date des
 * listes (séances, inscriptions) le sont aussi côté client.
 */

export function fill(template: string, values: Record<string, string | number>) {
  return template.replace(/\{(\w+)\}/g, (match, key: string) =>
    key in values ? String(values[key]) : match,
  );
}

export function formatDate(value: string | Date): string {
  return new Intl.DateTimeFormat("fr-FR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  }).format(new Date(value));
}

/** Montant en francs congolais, arrondi et espacé à la française. */
export function formatFc(value: number): string {
  return `${new Intl.NumberFormat("fr-FR").format(Math.round(value))} FC`;
}

export function formatDateTime(value: string | Date): string {
  return new Intl.DateTimeFormat("fr-FR", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

/** « dans 3 h », « dans 12 min », « il y a 2 j » — du plus proche au plus large. */
export function relativeFromNow(value: string | Date): string {
  const diffMs = new Date(value).getTime() - Date.now();
  const past = diffMs < 0;
  const minutes = Math.round(Math.abs(diffMs) / 60_000);
  const unit = (amount: number, singular: string, plural: string) =>
    `${amount} ${amount > 1 ? plural : singular}`;

  const label =
    minutes < 1
      ? "moins d'une minute"
      : minutes < 60
        ? unit(minutes, "minute", "minutes")
        : minutes < 1_440
          ? unit(Math.round(minutes / 60), "heure", "heures")
          : unit(Math.round(minutes / 1_440), "jour", "jours");

  return past ? `il y a ${label}` : `dans ${label}`;
}
