import type { MetadataRoute } from "next";

import { site } from "@/config/site";

/**
 * Le nom déclaré ici est l'un des signaux que Google utilise pour le « nom du
 * site » affiché sous un résultat. Sans manifeste, un sous-domaine d'hébergeur
 * est rattaché au nom de l'hébergeur.
 */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: `${site.name} — ${site.tagline}`,
    short_name: site.name,
    description: site.description,
    lang: "fr",
    dir: "ltr",
    id: "/",
    start_url: "/",
    scope: "/",
    display: "standalone",
    background_color: "#f4f7fc",
    theme_color: "#050914",
    icons: [
      { src: "/icon.svg", sizes: "any", type: "image/svg+xml" },
      { src: "/apple-icon", sizes: "180x180", type: "image/png" },
      { src: "/favicon.ico", sizes: "256x256", type: "image/x-icon" },
    ],
  };
}
