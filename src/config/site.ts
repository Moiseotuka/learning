const normalizeSiteUrl = (value: string | undefined | null) => {
  if (!value || !value.trim()) return null;

  const trimmed = value.trim().replace(/\/$/, "");
  if (!trimmed || trimmed.includes("[SENSITIVE]") || trimmed.includes("VOTRE_") || trimmed.includes("YOUR_")) {
    return null;
  }

  try {
    const parsed = new URL(trimmed.includes("://") ? trimmed : `https://${trimmed}`);
    if (!/^https?:$/.test(parsed.protocol)) return null;
    return parsed.origin;
  } catch {
    return null;
  }
};

const isLocalhostUrl = (value: string | null | undefined) => {
  if (!value) return false;
  try {
    const url = new URL(value);
    return /^(localhost|127\.0\.0\.1|0\.0\.0\.0)$/i.test(url.hostname);
  } catch {
    return false;
  }
};

export const resolveSiteUrl = (requestOrigin?: string) => {
  const isProductionLike = Boolean(process.env.VERCEL || process.env.NODE_ENV === "production");

  const pickPublicCandidate = (candidate: string | undefined | null) => {
    const normalized = normalizeSiteUrl(candidate);
    if (!normalized) return null;
    if (isProductionLike && isLocalhostUrl(normalized)) return null;
    return normalized;
  };

  const configuredCandidates = [
    process.env.NEXT_PUBLIC_SITE_URL,
    process.env.APP_URL,
    process.env.SITE_URL,
    process.env.NEXT_PUBLIC_APP_URL,
  ];

  for (const candidate of configuredCandidates) {
    const normalized = pickPublicCandidate(candidate);
    if (normalized) return normalized;
  }

  const vercelCandidates = [
    process.env.VERCEL_PROJECT_PRODUCTION_URL,
    process.env.VERCEL_PROJECT_PRODUCTION_URL && `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`,
    process.env.VERCEL_URL,
    process.env.VERCEL_BRANCH_URL,
    process.env.NEXT_PUBLIC_VERCEL_URL,
    process.env.PUBLIC_URL,
  ];

  for (const candidate of vercelCandidates) {
    const normalized = pickPublicCandidate(candidate);
    if (normalized) return normalized;
  }

  const requestOriginUrl = normalizeSiteUrl(requestOrigin);
  if (requestOriginUrl && !isLocalhostUrl(requestOriginUrl)) {
    return requestOriginUrl;
  }

  if (isProductionLike) {
    return process.env.VERCEL_PROJECT_PRODUCTION_URL
      ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
      : "https://elearning-three-phi.vercel.app";
  }

  return "http://localhost:3000";
};

export const site = {
  name: "easyTech",
  tagline: "Apprenez la technologie, prouvez-le",
  description:
    "Plateforme e-learning francophone : des parcours structurés du Débutant au niveau Avancé, des exercices pratiques, des quiz corrigés et un certificat vérifiable.",
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
  author: "easyTech",
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
  verify: "/verifier",
  dashboard: "/app",
  admin: "/admin",
  forbidden: "/interdit",
} as const;
