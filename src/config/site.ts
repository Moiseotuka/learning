export const site = {
  name: "easyLearn",
  tagline: "Apprenez la technologie, prouvez-le",
  description:
    "Plateforme e-learning francophone : des parcours structurés du Débutant au Projet final, des exercices pratiques, des quiz corrigés et un certificat vérifiable.",
  url: process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000",
  locale: "fr-FR",
  keywords: [
    "e-learning",
    "formation informatique",
    "apprendre la programmation",
    "cybersécurité",
    "réseaux",
    "intelligence artificielle",
    "Afrique francophone",
    "RDC",
    "certification",
  ],
  author: "easyLearn",
} as const;

/**
 * Liens de navigation.
 */
export const links = {
  home: "/",
  signup: "/inscription",
  login: "/connexion",
  forgotPassword: "/mot-de-passe-oublie",
  resetPassword: "/mot-de-passe-oublie/nouveau",
  catalogue: "/catalogue",
  pricing: "/#tarifs",
  verify: "/verifier",
  dashboard: "/app",
  admin: "/admin",
  forbidden: "/interdit",
} as const;

export const socials = [
  { name: "Facebook", href: "https://facebook.com" },
  { name: "X", href: "https://x.com" },
  { name: "LinkedIn", href: "https://linkedin.com" },
  { name: "YouTube", href: "https://youtube.com" },
  { name: "GitHub", href: "https://github.com" },
] as const;
