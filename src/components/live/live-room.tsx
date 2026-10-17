"use client";

import { Loader2Icon, VideoIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";

import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { reportLivePresence } from "@/lib/actions/instructor";
import { fill } from "@/lib/instructor/format";
import {
  bandwidthConfig,
  type LiveBandwidthMode,
} from "@/lib/live/provider";
import { useBandwidthMode } from "@/lib/live/bandwidth-store";
import { cn } from "cn";

const t = messages.live;

const HEARTBEAT_SECONDS = 30;

const BANDWIDTH_MODES: LiveBandwidthMode[] = ["hd", "eco", "audio"];

function labelOf(mode: LiveBandwidthMode): string {
  if (mode === "eco") return t.room.bandwidthEco;
  if (mode === "audio") return t.room.bandwidthAudio;
  return t.room.bandwidthHd;
}

function noteOf(mode: LiveBandwidthMode): string {
  if (mode === "eco") return t.room.bandwidthNoteEco;
  if (mode === "audio") return t.room.bandwidthNoteAudio;
  return t.room.bandwidthNoteHd;
}

type JitsiApi = {
  addListener: (event: string, handler: (...args: unknown[]) => void) => void;
  executeCommand: (command: string, ...args: unknown[]) => void;
  dispose: () => void;
};

declare global {
  interface Window {
    JitsiMeetExternalAPI?: new (domain: string, options: Record<string, unknown>) => JitsiApi;
  }
}

/** Le script n'est chargé qu'une fois par page, même en développement. */
const scriptLoads = new Map<string, Promise<boolean>>();

function loadExternalApi(scriptUrl: string, domain: string): Promise<boolean> {
  if (window.JitsiMeetExternalAPI) return Promise.resolve(true);
  const key = `${domain}|${scriptUrl}`;
  const existing = scriptLoads.get(key);
  if (existing) return existing;

  const loading = new Promise<boolean>((resolve) => {
    const script = document.createElement("script");
    script.src = scriptUrl;
    script.async = true;
    script.onload = () => resolve(Boolean(window.JitsiMeetExternalAPI));
    script.onerror = () => resolve(false);
    document.head.appendChild(script);
  });

  scriptLoads.set(key, loading);
  return loading;
}

export type LiveRoomProps = {
  sessionId: string;
  /** Nom de salle opaque stocké en base, jamais affiché. */
  roomName: string;
  domain: string;
  scriptUrl: string;
  subject: string;
  displayName: string;
  email: string | null;
  isHost: boolean;
  options: Record<string, unknown>;
  /**
   * Heure de coupure d'une séance à quota (palier gratuit), ou `null`.
   * Le flux WebRTC ne passe pas par nos serveurs : cette borne ferme la page
   * et `joinWindow` refuse toute réentrée ensuite, mais elle ne peut pas
   * couper le média chez un élève déjà dans la salle.
   */
  hardClosesAt: string | null;
};

/**
 * Salle de cours en direct. L'écran d'avant-jointure sert de filtre : caméra et
 * micro ne sont sollicités qu'au moment où l'apprenant décide d'entrer, et le
 * nom présenté est celui du profil — jamais l'identifiant technique de la salle.
 */
export function LiveRoom({
  sessionId,
  roomName,
  domain,
  scriptUrl,
  subject,
  displayName,
  email,
  isHost,
  options,
  hardClosesAt,
}: LiveRoomProps) {
  const holderRef = useRef<HTMLDivElement>(null);
  const apiRef = useRef<JitsiApi | null>(null);
  const beatRef = useRef<number | null>(null);
  const [name, setName] = useState(displayName);
  const measured = useBandwidthMode();
  const [pickedMode, setPickedMode] = useState<LiveBandwidthMode | null>(null);
  const mode = pickedMode ?? measured;
  const [status, setStatus] = useState<"before" | "loading" | "open" | "failed">(
    "before",
  );
  const [left, setLeft] = useState(false);
  const [cappedOut, setCappedOut] = useState(false);

  const stopHeartbeat = () => {
    if (beatRef.current !== null) {
      window.clearInterval(beatRef.current);
      beatRef.current = null;
    }
  };

  const enter = async () => {
    setStatus("loading");
    const loaded = await loadExternalApi(scriptUrl, domain);
    const holder = holderRef.current;
    if (!loaded || !window.JitsiMeetExternalAPI || !holder) {
      setStatus("failed");
      return;
    }

    const config = (options.configOverwrite ?? {}) as Record<string, unknown>;
    const api = new window.JitsiMeetExternalAPI(domain, {
      ...options,
      configOverwrite: { ...config, ...bandwidthConfig(mode) },
      parentNode: holder,
      roomName,
      userInfo: {
        displayName: name.trim() || displayName,
        email: email || undefined,
      },
    });
    apiRef.current = api;
    setStatus("open");

    void reportLivePresence(sessionId, 0);
    beatRef.current = window.setInterval(() => {
      void reportLivePresence(sessionId, HEARTBEAT_SECONDS);
    }, HEARTBEAT_SECONDS * 1000);

    const leave = () => {
      stopHeartbeat();
      setLeft(true);
      void reportLivePresence(sessionId, 0, true);
    };
    api.addListener("videoConferenceLeft", leave);
    api.addListener("readyToClose", leave);
  };

  useEffect(
    () => () => {
      // Navigation pendant la séance : le départ est porté, la salle fermée.
      stopHeartbeat();
      if (apiRef.current) {
        apiRef.current.dispose();
        apiRef.current = null;
        void reportLivePresence(sessionId, 0, true);
      }
    },
    [sessionId],
  );

  useEffect(() => {
    if (!hardClosesAt || status !== "open") return;
    const closesAt = new Date(hardClosesAt).getTime();

    const check = () => {
      if (Date.now() < closesAt) return;
      if (beatRef.current !== null) {
        window.clearInterval(beatRef.current);
        beatRef.current = null;
      }
      if (apiRef.current) {
        apiRef.current.dispose();
        apiRef.current = null;
      }
      void reportLivePresence(sessionId, 0, true);
      setCappedOut(true);
    };

    check();
    const ticker = window.setInterval(check, 15_000);
    return () => window.clearInterval(ticker);
  }, [hardClosesAt, status, sessionId]);

  // Le reste à vivre d'une séance à quota se lit après montage : `Date.now()` à
  // chaque rendu figerait un chiffre différent à chaque re-render.
  const [minutesLeft, setMinutesLeft] = useState<number | null>(null);

  useEffect(() => {
    if (!hardClosesAt) return;
    const closesAt = new Date(hardClosesAt).getTime();
    const tick = () =>
      setMinutesLeft(Math.max(0, Math.round((closesAt - Date.now()) / 60_000)));
    tick();
    const ticker = window.setInterval(tick, 30_000);
    return () => window.clearInterval(ticker);
  }, [hardClosesAt]);

  /**
   * Le conteneur de la salle est monté en toutes les étapes, y compris avant le
   * premier clic : `enter()` y accroche l'iframe au moment où il construit
   * l'API, donc avant tout re-render. Rendu seulement visible quand la salle
   * tourne — un cadre noir vide sur l'écran d'avant-jointure serait une promesse
   * non tenue. Il garde la même place dans l'arbre pour que React ne le
   * recrée pas entre « connexion » et « salle ouverte », ce qui tuerait l'iframe.
   */
  const shell = (
    <div
      ref={holderRef}
      className={cn(
        "overflow-hidden rounded-2xl border border-hairline bg-black",
        status === "open" ? "aspect-video w-full min-h-[360px]" : "hidden",
      )}
    />
  );

  if (status === "failed") {
    return (
      <>
        {shell}
        <Notice tone="error">{t.room.unsupported}</Notice>
      </>
    );
  }

  if (cappedOut) {
    return (
      <>
        {shell}
        <Notice tone="info">{t.room.capClosed}</Notice>
      </>
    );
  }

  if (status === "open") {
    return (
      <>
        {shell}
        {left ? <Notice tone="info">{t.room.closed}</Notice> : null}
      </>
    );
  }

  return (
    <>
      {shell}
      <div className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
      <h2 className="text-sm font-semibold text-foreground">{subject}</h2>
      {isHost ? (
        <p className="mt-1 text-[11px] font-semibold tracking-wide text-electric uppercase">
          {t.room.host}
        </p>
      ) : null}
      <p className="mt-1.5 max-w-[70ch] text-xs leading-relaxed text-muted-foreground">
        {t.room.prejoin}
      </p>
      {minutesLeft !== null ? (
        <p className="mt-2 text-[11px] leading-relaxed text-electric">
          {fill(t.room.capLeft, { minutes: minutesLeft })}
        </p>
      ) : null}

      <label className="mt-4 block max-w-sm">
        <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
          {t.room.yourName}
        </span>
        <Input
          value={name}
          onChange={(event) => setName(event.target.value)}
          maxLength={60}
          autoComplete="name"
          className="h-10"
        />
        <span className="mt-1.5 block text-[11px] text-muted-foreground">
          {t.room.nameHint}
        </span>
      </label>

      <div className="mt-5">
        <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
          {t.room.bandwidthTitle}
        </span>
        <div
          role="radiogroup"
          aria-label={t.room.bandwidthTitle}
          className="flex flex-wrap gap-2"
        >
          {BANDWIDTH_MODES.map((value) => (
            <Button
              key={value}
              type="button"
              size="sm"
              role="radio"
              aria-checked={mode === value}
              variant={mode === value ? "default" : "outline"}
              className="h-9 px-4"
              onClick={() => setPickedMode(value)}
            >
              {labelOf(value)}
            </Button>
          ))}
        </div>
        <p className="mt-2 max-w-[60ch] text-[11px] leading-relaxed text-muted-foreground">
          {t.room.bandwidthHint}
        </p>
        <p className="mt-1 max-w-[60ch] text-[11px] leading-relaxed text-muted-foreground">
          {noteOf(mode)}
        </p>
        {pickedMode === null && measured !== "hd" ? (
          <p className="mt-1 text-[11px] leading-relaxed text-electric">
            {fill(t.room.bandwidthAuto, { mode: labelOf(measured) })}
          </p>
        ) : null}
      </div>

      <div className="mt-5 flex flex-wrap items-center gap-3">
        <Button
          type="button"
          className="h-11 px-6"
          onClick={enter}
          disabled={status === "loading"}
        >
          {status === "loading" ? (
            <Loader2Icon className="animate-spin" aria-hidden />
          ) : (
            <VideoIcon aria-hidden />
          )}
          {status === "loading" ? t.room.loading : t.room.join}
        </Button>
        <p className="max-w-[46ch] text-[11px] leading-relaxed text-muted-foreground">
          {t.room.privacy}
        </p>
      </div>

      </div>
    </>
  );
}
