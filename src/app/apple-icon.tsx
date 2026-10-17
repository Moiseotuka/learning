import { ImageResponse } from "next/og";

/**
 * `favicon.ico` ne pèse que 32 px une fois décodé par les moteurs : sans
 * version 180 px, Google et iOS retombent sur une icône générique — et
 * l'icône générique d'un sous-domaine `vercel.app`, c'est le logo de Vercel.
 *
 * La marque est reprise de `src/app/icon.svg` à l'identique : emblème blanc
 * (globe + toque de diplômé) sur carré arrondi vert. Le générateur d'images
 * (satori) ne gère ni `transform` sur <g> ni tous les attributs SVG : les
 * coordonnées de l'emblème sont donc pré-multipliées ici (échelle 0.3776,
 * décalage 13.12/15.04 dans le viewBox 64).
 */
export const size = { width: 180, height: 180 };
export const contentType = "image/png";

const BLANC = "#ffffff";

export default function AppleIcon() {
  return new ImageResponse(
    (
      <svg
        width={180}
        height={180}
        viewBox="0 0 64 64"
        xmlns="http://www.w3.org/2000/svg"
      >
        <rect width={64} height={64} rx={14} fill="#16a34a" />
        {/* orbite */}
        <path
          d="M20.29 42.62 A13.59 12.08 0 0 0 44.46 41.86"
          fill="none"
          stroke={BLANC}
          strokeWidth={2.27}
          strokeLinecap="round"
        />
        {/* globe */}
        <circle
          cx={32}
          cy={37.7}
          r={9.44}
          fill="none"
          stroke={BLANC}
          strokeWidth={2.08}
        />
        {/* méridien (ellipse tracée en deux arcs) */}
        <path
          d="M32 28.26 A4.34 9.44 0 1 0 32.01 28.26 M32 28.26 A4.34 9.44 0 1 1 32.01 28.26"
          fill="none"
          stroke={BLANC}
          strokeWidth={1.7}
        />
        {/* parallèles */}
        <path
          d="M23.69 33.54 H40.31 M23.69 41.86 H40.31"
          fill="none"
          stroke={BLANC}
          strokeWidth={1.7}
          strokeLinecap="round"
        />
        {/* dragonne */}
        <path
          d="M32 19.2 C35.78 16.55 40.68 18.44 41.44 22.59 L41.44 26.37"
          fill="none"
          stroke={BLANC}
          strokeWidth={1.32}
          strokeLinecap="round"
        />
        {/* bandeau de la toque */}
        <path d="M27.09 27.12 h9.82 v3.02 a1.13 1.13 0 0 1 -1.13 1.13 h-7.55 a1.13 1.13 0 0 1 -1.13 -1.13 Z" fill={BLANC} />
        {/* plateau (le bouton est redessiné en vert par-dessus) */}
        <path
          d="M32 17.68 L47.47 22.97 L32 28.26 L16.52 22.97 Z"
          fill={BLANC}
        />
        <circle cx={32} cy={19.2} r={1.28} fill="#16a34a" />
        {/* pompon */}
        <circle cx={41.44} cy={28.07} r={1.89} fill={BLANC} />
      </svg>
    ),
    size,
  );
}
