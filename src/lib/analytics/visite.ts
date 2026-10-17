/**
 * Attribution d'une visite, sans service de mesure tiers.
 *
 * Le site est utilisé par des apprenants qui paient au franc congolais depuis leur téléphone :
 * coller un traceur publicitaire dans la page serait à la fois invisible pour eux sur 3G, et
 * contraire à la règle du produit (on ne montre pas les coulisses). Tout est donc déduit de ce
 * que la requête HTTP contient déjà : `utm_*`, le référent, l'agent utilisateur et le pays
 * attaché par l'hébergeur.
 *
 * Aucun nom, aucun e-mail, aucune adresse IP n'est stocké : `visiteur` est un condensat
 * (adresse IP + agent + jour), donc il ne survit pas à la journée et ne permet pas de suivre
 * une personne d'un jour à l'autre. Il répond exactement à la question posée par le tableau de
 * bord : combien de personnes différentes sont venues par ce lien.
 */

const SOURCE_ALIASES: Record<string, string> = {
  tt: "tiktok",
  tiktok: "tiktok",
  wa: "whatsapp",
  whatsapp: "whatsapp",
  fb: "facebook",
  facebook: "facebook",
  fbad: "facebook",
  ig: "instagram",
  instagram: "instagram",
  yt: "youtube",
  youtube: "youtube",
  x: "x",
  twitter: "x",
  li: "linkedin",
  linkedin: "linkedin",
  tg: "telegram",
  telegram: "telegram",
  google: "google",
  g: "google",
  bing: "bing",
  duckduckgo: "duckduckgo",
  email: "e-mail",
  mail: "e-mail",
  sms: "sms",
};

/** Famille de canaux, pour regrouper proprement dans le tableau de bord. */
const SOURCE_MEDIUM: Record<string, string> = {
  tiktok: "reseaux sociaux",
  facebook: "reseaux sociaux",
  instagram: "reseaux sociaux",
  x: "reseaux sociaux",
  linkedin: "reseaux sociaux",
  youtube: "reseaux sociaux",
  whatsapp: "messagerie",
  telegram: "messagerie",
  sms: "messagerie",
  "e-mail": "e-mail",
  google: "recherche",
  bing: "recherche",
  duckduckgo: "recherche",
  direct: "direct",
};

const BOT =
  /bot|crawler|spider|slurp|curl|wget|python-|okhttp|java\/|headless|lighthouse|pagepeeker|status\/|phpcrawl|simplepie|feedfetcher|facebookexternalhit|whatsapp|telegrambot|discordbot|slackbot|preview|monitor/i;

export function estUnRobot(userAgent: string): boolean {
  return BOT.test(userAgent);
}

/**
 * Routes Next qui rendent un fichier (image Open Graph, icône, manifeste PWA) sans extension
 * dans l'URL : le navigateur les télécharge à chaque page ouverte, ce qui fausserait le trafic.
 */
const ROUTES_TECHNIQUES = new Set([
  "/icon",
  "/apple-icon",
  "/opengraph-image",
  "/twitter-image",
  "/manifest",
]);

/** Les fichiers et les routes techniques ne sont pas des pages vues. */
export function estUnePage(pathname: string): boolean {
  if (pathname.startsWith("/api")) return false;
  if (pathname.startsWith("/_next")) return false;
  // Le back-office et l'espace de travail ne sont pas du trafic : ce que l'admin veut mesurer,
  // ce sont les gens qui découvrent le site, pas les clics de celui qui le pilote.
  if (pathname.startsWith("/admin") || pathname.startsWith("/app")) return false;
  if (ROUTES_TECHNIQUES.has(pathname)) return false;
  // Un point dans le dernier segment signifie « fichier » : .webmanifest, .svg, .ico, .txt ...
  // La longueur de l'extension ne doit jamais être une condition, sinon `manifest.webmanifest`
  // (11 lettres) repasse dans les pages les plus vues et pollue le tableau de bord.
  return !pathname.split("/").pop()?.includes(".");
}

function normaliserSource(brut: string): string | null {
  const cle = brut.toLowerCase().replace(/[^a-z0-9]/g, "");
  if (!cle) return null;
  if (SOURCE_ALIASES[cle]) return SOURCE_ALIASES[cle];

  for (const [indice, source] of Object.entries(SOURCE_ALIASES)) {
    if (cle.includes(indice)) return source;
  }
  return brut.toLowerCase().slice(0, 40);
}

export type Attribution = {
  source: string;
  medium: string;
  campaign: string | null;
  referrer: string | null;
};

/**
 * `utm_source` fait foi quand il est présent : c'est le lien que l'admin a publié. Sinon on
 * remonte au domaine référent, ce qui couvre les partages WhatsApp et TikTok qui perdent les
 * paramètres de l'URL.
 */
export function attribuer(params: URLSearchParams, referer: string | null, hote: string): Attribution {
  const ref = referer ? safeUrl(referer) : null;
  const refHote = ref?.hostname.replace(/^www\./, "") ?? "";
  const depuisNotreSite = refHote === hote.replace(/^www\./, "");

  const depuisParam = params.get("utm_source");
  const source =
    (depuisParam && normaliserSource(depuisParam)) ||
    (ref && !depuisNotreSite && normaliserSource(refHote.split(".")[0])) ||
    "direct";

  const campagne = params.get("utm_campaign")?.trim().slice(0, 60) || null;

  return {
    source,
    medium:
      params.get("utm_medium")?.trim().slice(0, 40) ||
      SOURCE_MEDIUM[source] ||
      (depuisNotreSite ? "navigation interne" : "autre"),
    campaign: campagne,
    referrer: referer ? referer.slice(0, 200) : null,
  };
}

function safeUrl(brut: string): URL | null {
  try {
    return new URL(brut);
  } catch {
    return null;
  }
}

export function appareil(userAgent: string): string {
  const ua = userAgent.toLowerCase();
  if (/ipad|tablet|kindle|silk/.test(ua)) return "tablette";
  if (/mobi|iphone|android|windows phone/.test(ua)) return "telephone";
  return "ordinateur";
}

/** Condensat quotidien du navigateur : ni cookie, ni IP persistée. */
export async function identifiantVisiteur(ip: string, userAgent: string, jour: string): Promise<string> {
  const donnees = new TextEncoder().encode(`${ip}|${userAgent}|${jour}`);
  const empreinte = await crypto.subtle.digest("SHA-256", donnees);
  return Array.from(new Uint8Array(empreinte))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .slice(0, 24);
}

/**
 * Date calendaire de Kinshasa, pas celle d'UTC : le condensat de visiteur tourne à minuit ici,
 * ce qui doit être le même minuit que celui des agrégations du tableau de bord. Sinon un visiteur
 * arrivé entre 0 h et 2 h serait compté deux fois sur la même journée affichée.
 */
export function jourDe(date: Date): string {
  return new Intl.DateTimeFormat("fr-CA", {
    timeZone: "Africa/Lubumbashi",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}
