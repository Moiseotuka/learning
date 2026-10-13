import { ImageResponse } from "next/og";

import { site } from "@/config/site";

/**
 * Image de partage par défaut : sans elle, un lien partagé sur WhatsApp ou
 * Facebook — les canaux réels de diffusion ici — n'affiche aucun visuel, et la
 * plate-forme n'existe pas pour celui qui le reçoit.
 */
export const alt = `${site.name} — ${site.tagline}`;
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OGImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "72px",
          background: "linear-gradient(150deg, #0a3b28 0%, #06291c 100%)",
          color: "#ffffff",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div
            style={{
              width: 54,
              height: 54,
              borderRadius: 14,
              background: "#f7b32b",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#06291c",
              fontSize: 30,
              fontWeight: 700,
            }}
          >
            e
          </div>
          <div style={{ fontSize: 34, fontWeight: 700, letterSpacing: -0.5 }}>
            {site.name}
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 22 }}>
          <div style={{ fontSize: 62, fontWeight: 700, lineHeight: 1.1 }}>
            {site.tagline}
          </div>
          <div style={{ fontSize: 30, color: "#cde3d8", lineHeight: 1.35 }}>
            Formations en ligne en français : programmation, cybersécurité,
            réseaux, IA, électronique.
          </div>
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            fontSize: 26,
            color: "#cde3d8",
          }}
        >
          <div style={{ display: "flex", gap: 14 }}>
            {["Du Débutant au Projet", "Certificat vérifiable", "Mobile Money"].map(
              (item) => (
                <div
                  key={item}
                  style={{
                    padding: "10px 20px",
                    borderRadius: 999,
                    border: "2px solid rgba(247,179,43,0.55)",
                    color: "#f7b32b",
                  }}
                >
                  {item}
                </div>
              ),
            )}
          </div>
          {/* Pas le nom d'hôte : un visuel qui montre l'URL d'hébergement
              contredit la règle du site, et n'apprend rien à celui qui le voit. */}
          <div style={{ fontWeight: 600 }}>RDC · Afrique francophone</div>
        </div>
      </div>
    ),
    { ...size },
  );
}
