/**
 * Couche « salle en direct ».
 *
 * Le produit ne doit pas dépendre de l'infrastructure vidéo : toute la
 * configuration est ici, et un futur prestataire payant (enregistrement
 * côté serveur, salle aux couleurs d'easyTech) ne demanderait que le
 * remplacement de ce module, jamais celui des écrans.
 *
 * Jitsi est utilisé sans compte ni clé : `NEXT_PUBLIC_JITSI_DOMAIN` pointe sur
 * l'instance publique par défaut, ou sur une instance auto-hébergée dès que le
 * projet en aura une. La marque de l'outil est masquée par configuration — même
 * discipline que pour les leçons vidéo : l'apprenant n'a aucune raison de
 * connaître le fournisseur technique.
 */

export type LiveProviderName = "jitsi";

export const JOIN_BEFORE_MINUTES = 10;
export const JOIN_AFTER_MINUTES = 15;

export function liveProvider(): LiveProviderName {
  return "jitsi";
}

export function jitsiDomain(): string {
  const configured = process.env.NEXT_PUBLIC_JITSI_DOMAIN?.trim();
  return (configured && configured.replace(/^https?:\/\//, "").replace(/\/$/, "")) || "meet.jit.si";
}

export function jitsiExternalApiUrl(domain = jitsiDomain()): string {
  return `https://${domain}/external_api.js`;
}

/** Nom de salle opaque : l'identifiant de séance ne se lit jamais à l'écran. */
export function roomNameFor(sessionId: string, title: string): string {
  const slug = title
    .toLowerCase()
    .normalize("NFD")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 28);
  return `easytech-${sessionId.replace(/-/g, "").slice(0, 12)}${slug ? `-${slug}` : ""}`;
}

export type RoomIdentity = {
  roomName: string;
  displayName: string;
  email?: string | null;
  /** Le formateur peut éjecter et verrouiller la salle ; les élèves non. */
  isModerator: boolean;
  /** Titre de la séance, affiché à la place d'un nom de salle technique. */
  subject: string;
};

const LEARNER_TOOLS = [
  "microphone",
  "camera",
  "chat",
  "raisehand",
  "participants-pane",
  "tile-view",
  "fullscreen",
  "settings",
];

const HOST_TOOLS = [
  "microphone",
  "camera",
  "chat",
  "raisehand",
  "participants-pane",
  "desktop",
  "stage-film",
  "fullscreen",
  "toggle-camera",
  "invite",
  "settings",
  "security",
];

/**
 * Options passées à `new JitsiMeetExternalAPI(...)`. Les clés inconnues de
 * l'instance sont ignorées silencieusement par Jitsi : rien ici ne peut casser
 * une salle si l'instance est plus ancienne.
 */
export function buildRoomOptions(identity: RoomIdentity) {
  return {
    roomName: identity.roomName,
    userInfo: {
      displayName: identity.displayName,
      email: identity.email || undefined,
    },
    configOverwrite: {
      subject: identity.subject,
      defaultLanguage: "fr",
      prejoinConfig: { enabled: true, hideExtraChains: true },
      startWithAudioMuted: !identity.isModerator,
      startWithVideoMuted: false,
      startWithScreenShare: false,
      disableDeepLinking: true,
      showJitsiBrandName: false,
      hideJitsiBrandName: true,
      toolbarButtons: identity.isModerator ? HOST_TOOLS : LEARNER_TOOLS,
      disableKeyboardShortcuts: false,
      roomPasswordReadOnly: true,
      e2ee: { labels: { description: "" } },
    },
    interfaceConfigOverwrite: {
      SHOW_JITSI_WATERMARK: false,
      SHOW_WATERMARK_FOR_GUESTS: false,
      SHOW_BRAND_WATERMARK: false,
      SHOW_POWERED_BY: false,
      SHOW_CHROME_EXTENSION_BANNER: false,
      MOBILE_APP_PROMO: false,
      DEFAULT_LOGO_URL: "",
      JITSI_WATERMARK_LINK: "",
      HIDE_INVITE_MORE_HEADER: true,
      DISABLE_JOIN_LEAVE_NOTIFICATIONS: true,
      RECENT_LIST_ENABLED: false,
      SETTINGS_MENU_ITEMS: { items: [] },
      APP_NAME: "easyTech",
      INITIAL_TOOLBAR_TIMEOUT: 20000,
      TOOLBAR_TIMEOUT: 4000,
    },
  };
}

export type JoinWindow = {
  openable: boolean;
  state: "too_early" | "live_now" | "closed";
  opensAt: Date;
};

export function joinWindow(startsAt: string, endsAt: string, now = new Date()): JoinWindow {
  const start = new Date(startsAt);
  const end = new Date(endsAt);
  const opensAt = new Date(start.getTime() - JOIN_BEFORE_MINUTES * 60_000);
  const closesAt = new Date(end.getTime() + JOIN_AFTER_MINUTES * 60_000);

  if (now < opensAt) return { openable: false, state: "too_early", opensAt };
  if (now > closesAt) return { openable: false, state: "closed", opensAt };
  return { openable: true, state: now < start ? "too_early" : "live_now", opensAt };
}

/** Compte à rebours lisible jusqu'au début de la séance. */
export function untilLabel(target: Date, now = new Date()): string {
  const minutes = Math.round((target.getTime() - now.getTime()) / 60_000);
  if (minutes <= 0) return "maintenant";
  if (minutes < 60) return `dans ${minutes} min`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `dans ${hours} h`;
  return `dans ${Math.round(hours / 24)} j`;
}
