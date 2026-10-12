import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Les tutoriels vidéo sont listés par l'onglet « Tutoriels » du catalogue :
  // /tutoriels reste valable pour les liens déjà partagés.
  async redirects() {
    return [
      {
        source: "/tutoriels",
        destination: "/catalogue?type=tutoriels",
        permanent: true,
      },
    ];
  },
  images: {
    remotePatterns: [
      // Vignettes des lecteurs vidéo intégrés (aucun téléchargement côté serveur)
      { protocol: "https", hostname: "i.ytimg.com" },
      { protocol: "https", hostname: "img.youtube.com" },
      // Médias hébergés (logos, avatars distants autorisés par le back-office)
      { protocol: "https", hostname: "**.supabase.co" },
      { protocol: "https", hostname: "images.unsplash.com" },
    ],
  },
};

export default nextConfig;
