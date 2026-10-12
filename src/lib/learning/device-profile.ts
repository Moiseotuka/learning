export interface DeviceProfile {
  /** Réseau ou matériel limité : l'intégration du lecteur peut être très lente. */
  slow: boolean;
  /** Attente avant de renoncer à l'API du lecteur et passer au cadre simple. */
  apiTimeoutMs: number;
  /** Attente avant de conclure « la vidéo ne se lance pas ». */
  blockMs: number;
  /** Attente après un clic « Lire » sans réaction du lecteur. */
  playGuardMs: number;
  /** Vignette d'accueil : la petite image pèse moins lourd sur une ligne lente. */
  poster: "mq" | "hq";
}

const STANDARD: DeviceProfile = {
  slow: false,
  apiTimeoutMs: 8000,
  blockMs: 4000,
  playGuardMs: 3500,
  poster: "hq",
};

/** Rendu serveur : le réseau du téléphone n'est pas encore connu. */
export const DEFAULT_PROFILE = STANDARD;

const LIMITED: DeviceProfile = {
  slow: true,
  apiTimeoutMs: 25000,
  blockMs: 14000,
  playGuardMs: 12000,
  poster: "mq",
};

interface ConnectionLike {
  effectiveType?: string;
  saveData?: boolean;
}

/** Les téléphones anciens et les connexions 3G ne téléchargent pas l'API du
 *  lecteur aux mêmes vitesses : les délais d'un poste rapide font croire à une
 *  vidéo bloquée alors qu'elle est seulement en train d'arriver. */
export function readDeviceProfile(): DeviceProfile {
  if (typeof navigator === "undefined") return STANDARD;
  const nav = navigator as Navigator & {
    connection?: ConnectionLike;
    deviceMemory?: number;
  };
  const connection = nav.connection;
  const slow =
    Boolean(connection?.saveData) ||
    /(^|\b)(2g|3g)\b/.test(connection?.effectiveType ?? "") ||
    (typeof nav.deviceMemory === "number" && nav.deviceMemory <= 2);
  return slow ? LIMITED : STANDARD;
}
