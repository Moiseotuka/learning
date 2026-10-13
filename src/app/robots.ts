import type { MetadataRoute } from "next";

import { site } from "@/config/site";

/**
 * Un preview Vercel qui s'indexe crée un doublon concurrent de la production :
 * sur ce poste, seul l'environnement production ouvre ses pages aux robots.
 */
const isProduction = process.env.VERCEL_ENV === "production" || !process.env.VERCEL;

export default function robots(): MetadataRoute.Robots {
  if (!isProduction) {
    return { rules: [{ userAgent: "*", disallow: "/" }] };
  }

  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        // Espace connecté, API et routeurs d'authentification : rien d'indexable,
        // et une page de paiement dans les résultats serait une fuite d'image.
        disallow: ["/app/", "/admin/", "/api/", "/auth/", "/paiement/", "/interdit"],
      },
    ],
    sitemap: `${site.url}/sitemap.xml`,
    host: site.url,
  };
}
