import { ImageResponse } from "next/og";

/**
 * `favicon.ico` ne pèse que 32 px une fois décodé par les moteurs : sans
 * version 180 px, Google et iOS retombent sur une icône générique — et
 * l'icône générique d'un sous-domaine `vercel.app`, c'est le logo de Vercel.
 *
 * La marque est reprise de `src/app/icon.svg` à l'identique. Un triangle en
 * CSS à bordures ne rend pas ici (le générateur d'image le remplace par un
 * carré), d'où le SVG.
 */
export const size = { width: 180, height: 180 };
export const contentType = "image/png";

export default function AppleIcon() {
  return new ImageResponse(
    (
      <svg
        width={180}
        height={180}
        viewBox="0 0 64 64"
        xmlns="http://www.w3.org/2000/svg"
      >
        <rect width={64} height={64} rx={14} fill="#2563eb" />
        <path d="M24 16.5 44 32 24 47.5V16.5Z" fill="#ffffff" />
        <rect
          x={16}
          y={51}
          width={32}
          height={5}
          rx={2.5}
          fill="#ffffff"
          fillOpacity={0.55}
        />
      </svg>
    ),
    size,
  );
}
