const normalizeSiteUrl = (value: string | undefined | null) => {
  if (!value || !value.trim()) return null;

  const trimmed = value.trim().replace(/\/$/, "");
  if (!trimmed) return null;

  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  return `https://${trimmed}`;
};

const resolveSiteUrl = () => {
  const explicit =
    process.env.NEXT_PUBLIC_SITE_URL ??
    process.env.APP_URL ??
    process.env.SITE_URL ??
    process.env.NEXT_PUBLIC_APP_URL ??
    null;

  const explicitUrl = normalizeSiteUrl(explicit);
  if (explicitUrl) return explicitUrl;

  const vercelCandidates = [
    process.env.VERCEL_PROJECT_PRODUCTION_URL,
    process.env.VERCEL_PROJECT_PRODUCTION_URL && `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`,
    process.env.VERCEL_URL,
    process.env.VERCEL_BRANCH_URL,
    process.env.NEXT_PUBLIC_VERCEL_URL,
    process.env.PUBLIC_URL,
  ];

  for (const candidate of vercelCandidates) {
    const normalized = normalizeSiteUrl(candidate);
    if (normalized) return normalized;
  }

  return "http://localhost:3000";
};

export const site = {
  name: "easyLearn",
  tagline: "Apprenez la technologie, prouvez-le",
  description:
    "Plateforme e-learning francophone : des parcours structurés du Débutant au Projet final, des exercices pratiques, des quiz corrigés et un certificat vérifiable.",
  url: resolveSiteUrl(),
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
