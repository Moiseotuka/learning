/**
 * L'unique boîte réellement dépouillée par l'équipe easyTech.
 * Les adresses « contact@ », « aide@ », « support@ » sur un domaine non
 * réservé faisaient croire à un service de support qui n'existait pas : les
 * messages partaient dans le vide. Tout ce qui est affiché mène ici.
 */
export const CONTACT_EMAIL = "esaylearningrdc@gmail.com";

/** Lien mailto avec objet et corps pré-remplis ; la boîte est unique, l'objet trie les demandes. */
export function contactMailto(subject?: string, body?: string) {
  const query = [
    subject ? `subject=${encodeURIComponent(subject)}` : "",
    body ? `body=${encodeURIComponent(body)}` : "",
  ]
    .filter(Boolean)
    .join("&");
  return query ? `mailto:${CONTACT_EMAIL}?${query}` : `mailto:${CONTACT_EMAIL}`;
}
