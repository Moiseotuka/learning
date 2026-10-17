/**
 * Politique de facturation d'une séance en direct.
 *
 * Le modèle est celui de Zoom, transposé ici : on facture l'animateur, jamais
 * les participants, et le palier gratuit ne se paie pas en volume mais en
 * TEMPS de séance. Quarante minutes suffisent à découvrir un cours ; passer
 * ce seuil est l'acte d'achat.
 *
 * Deux écarts assumés avec Zoom, dictés par la caisse disponible :
 * - NYOLE ne prélève aucune carte en automatique, donc un abonnement qui expire
 *   ne se renouvelle pas tout seul. Plutôt que de couper la classe en plein
 *   cours, l'hôte expiré retombe sur le palier gratuit : il finit ce qu'il a
 *   commencé, à l'envers des minutes.
 * - Le palier gratuit n'est pas ouvert à tout le monde : l'éligibilité
 *   (certificat ou projet) reste exigée, sinon n'importe quelle adresse
 *   pourrait publier un cours au nom de l'académie.
 */

export type HostTier = "free" | "paid";

/** Durée maximale d'une séance au palier gratuit, en minutes. */
export const FREE_SESSION_MINUTES = 40;

/** Élèves accueillis par classe au palier gratuit. */
export const FREE_CLASS_SEATS = 10;

/** Le formateur a toujours quelques minutes de marge après son quota. */
export const CAP_GRACE_MS = 5 * 60_000;

/** Un abonnement expiré redescend au palier gratuit au lieu d'être éjecté. */
export const DOWNGRADE_AFTER_EXPIRY = true;

export function sessionCapMinutes(tier: HostTier): number | null {
  return tier === "free" ? FREE_SESSION_MINUTES : null;
}

/**
 * Durée réellement annoncée pour une séance : le palier gratuit tronque, le
 * palier payant garde la saisie du formateur dans la seule borne de lisibilité
 * (24 h) posée pour empêcher un créneau aberrant dans une convocation.
 */
export function clampedMinutes(minutes: number, tier: HostTier): number {
  const value = Math.round(Number(minutes));
  const safe = Number.isFinite(value) && value > 0 ? value : 60;
  const cap = sessionCapMinutes(tier) ?? 1_440;
  return Math.min(safe, cap, 1_440);
}

/** Heure de coupure dure d'une séance à quota, ou `null` si sans limite. */
export function capClosesAt(
  startsAt: string | Date,
  capMinutes: number | null,
): Date | null {
  if (capMinutes === null) return null;
  return new Date(
    new Date(startsAt).getTime() + capMinutes * 60_000 + CAP_GRACE_MS,
  );
}

/**
 * Tranches de durée proposées au formulaire. Un palier ne doit jamais proposer
 * une durée qu'il refuserait : sinon le formateur choisit « 2 heures », obtient
 * 40 minutes sans comprendre, et croit que la plateforme casse.
 */
export function durationOptions(tier: HostTier): number[] {
  return tier === "free"
    ? [20, 30, FREE_SESSION_MINUTES]
    : [30, 45, 60, 90, 120, 180, 240, 300];
}

/** Durée pré-sélectionnée : celle d'un cours, jamais la plus longue de la liste. */
export function defaultMinutes(tier: HostTier): number {
  return tier === "free" ? FREE_SESSION_MINUTES : 60;
}
