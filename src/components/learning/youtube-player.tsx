"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  ExternalLinkIcon,
  MaximizeIcon,
  MinimizeIcon,
  PauseIcon,
  PlayIcon,
  RotateCcwIcon,
  VideoOffIcon,
  Volume2Icon,
  VolumeXIcon,
} from "lucide-react";

import { messages } from "@/i18n";
import { toEmbedUrl } from "@/lib/embed-url";
import { cn } from "cn";

const t = messages.learner;

interface YTPlayer {
  destroy(): void;
  playVideo(): void;
  pauseVideo(): void;
  seekTo(seconds: number, allowSeekAhead: boolean): void;
  mute(): void;
  unMute(): void;
  isMuted(): boolean;
  getDuration(): number;
  getCurrentTime(): number;
  getIframe(): HTMLIFrameElement;
}

interface YTPlayerEvents {
  onReady?: (event: { target: YTPlayer }) => void;
  onStateChange?: (event: { target: YTPlayer; data: number }) => void;
  onError?: (event: { data: number }) => void;
}

declare global {
  interface Window {
    YT?: {
      Player: new (
        target: HTMLElement,
        options: {
          videoId: string;
          playerVars?: Record<string, string | number | boolean>;
          events?: YTPlayerEvents;
        },
      ) => YTPlayer;
    };
    onYouTubeIframeAPIReady?: () => void;
  }
}

const STATE_PLAYING = 1;
const STATE_ENDED = 0;
const STATE_BUFFERING = 3;
/** Délai avant d'afficher le secours « vidéo qui ne se lance pas » (bot-check). */
const BLOCKED_DELAY_MS = 4000;
/** Un clic « Lire » sans réaction du lecteur dans ce délai déclenche le secours. */
const PLAY_START_TIMEOUT_MS = 3500;

let apiPromise: Promise<boolean> | null = null;

function loadYouTubeApi(): Promise<boolean> {
  if (typeof window === "undefined") return Promise.resolve(false);
  if (window.YT?.Player) return Promise.resolve(true);
  if (!apiPromise) {
    apiPromise = new Promise<boolean>((resolve) => {
      const timer = window.setTimeout(() => resolve(false), 5000);
      const previous = window.onYouTubeIframeAPIReady;
      window.onYouTubeIframeAPIReady = () => {
        window.clearTimeout(timer);
        previous?.();
        resolve(true);
      };
      const script = document.createElement("script");
      script.src = "https://www.youtube.com/iframe_api";
      script.async = true;
      script.onerror = () => {
        window.clearTimeout(timer);
        resolve(false);
      };
      document.head.appendChild(script);
    });
    apiPromise.then((ok) => {
      if (!ok) apiPromise = null;
    });
  }
  return apiPromise;
}

function formatTime(total: number): string {
  const seconds = Math.max(0, Math.floor(total || 0));
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  const mm = h > 0 ? String(m).padStart(2, "0") : String(m);
  return `${h > 0 ? `${h}:` : ""}${mm}:${String(s).padStart(2, "0")}`;
}

/** Actions de secours quand la vidéo intégrée ne se lance pas (bot-check,
 *  vidéo supprimée, API indisponible) : réessayer, ouvrir dans YouTube,
 *  marquer comme vue pour débloquer la suite du chapitre. */
function RecoveryActions({
  watchUrl,
  onRetry,
  onMarkWatched,
}: {
  watchUrl: string;
  onRetry?: () => void;
  onMarkWatched?: () => void;
}) {
  return (
    <div className="flex flex-wrap items-center justify-center gap-2">
      {onRetry ? (
        <button
          type="button"
          onClick={onRetry}
          className="inline-flex cursor-pointer items-center gap-1.5 rounded-md bg-white px-3 py-1.5 text-xs font-semibold text-black transition-colors hover:bg-white/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-electric"
        >
          <RotateCcwIcon className="size-3.5" aria-hidden />
          {t.videoRetry}
        </button>
      ) : null}
      <a
        href={watchUrl}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center gap-1.5 rounded-md border border-white/30 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-electric"
      >
        {t.videoOpenTab}
        <ExternalLinkIcon className="size-3.5" aria-hidden />
      </a>
      {onMarkWatched ? (
        <button
          type="button"
          onClick={onMarkWatched}
          className="inline-flex cursor-pointer items-center gap-1.5 rounded-md bg-white/15 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-white/25 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-electric"
        >
          {t.markWatched}
        </button>
      ) : null}
    </div>
  );
}

export function YouTubePlayer({
  videoId,
  title,
  fill = false,
  className,
  autoplay = false,
  onEnded,
}: {
  videoId: string;
  title: string;
  fill?: boolean;
  className?: string;
  autoplay?: boolean;
  onEnded?: () => void;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const playerRef = useRef<YTPlayer | null>(null);
  const playingRef = useRef(false);
  const barHoveredRef = useRef(false);
  const hideTimer = useRef<number | undefined>(undefined);
  const flashTimer = useRef<number | undefined>(undefined);
  const endedNotified = useRef(false);
  const onEndedRef = useRef<(() => void) | undefined>(undefined);
  const autoplayRef = useRef(false);
  const blockTimer = useRef<number | undefined>(undefined);
  const playGuardTimer = useRef<number | undefined>(undefined);
  const startedRef = useRef(false);

  const [readyId, setReadyId] = useState<string | null>(null);
  const [fallbackId, setFallbackId] = useState<string | null>(null);
  const [errorId, setErrorId] = useState<string | null>(null);
  const [blockedId, setBlockedId] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);
  const [startedId, setStartedId] = useState<string | null>(null);
  const [playing, setPlaying] = useState(false);
  const [duration, setDuration] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const [watchedMax, setWatchedMax] = useState(0);
  const [muted, setMuted] = useState(false);
  const [barVisible, setBarVisible] = useState(true);
  const [startFlash, setStartFlash] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);

  const isReady = readyId === videoId;
  const isFallback = !isReady && fallbackId === videoId;
  const hasError = errorId === videoId;
  const started = startedId === videoId;
  const blocked = isReady && !started && blockedId === videoId;
  const watchUrl = `https://www.youtube.com/watch?v=${videoId}`;

  useEffect(() => {
    playingRef.current = playing;
  }, [playing]);

  useEffect(() => {
    onEndedRef.current = onEnded;
  }, [onEnded]);

  useEffect(() => {
    autoplayRef.current = autoplay;
  }, [autoplay]);

  const showBar = useCallback(() => {
    setBarVisible(true);
    window.clearTimeout(hideTimer.current);
    if (playingRef.current && !barHoveredRef.current) {
      hideTimer.current = window.setTimeout(() => setBarVisible(false), 3000);
    }
  }, []);

  const clearBlockWatch = useCallback(() => {
    window.clearTimeout(blockTimer.current);
    window.clearTimeout(playGuardTimer.current);
  }, []);

  /** Démarre le détecteur « vidéo qui ne se lance pas » (vérification YouTube). */
  const armBlockWatch = useCallback(() => {
    window.clearTimeout(blockTimer.current);
    blockTimer.current = window.setTimeout(() => {
      if (startedRef.current) return;
      const time = playerRef.current?.getCurrentTime() ?? 0;
      if (time > 0) return;
      setBlockedId(videoId);
    }, BLOCKED_DELAY_MS);
  }, [videoId]);

  /** Après un clic « Lire » : si le lecteur ne réagit ni en lecture ni en
   *  mise en tampon sous 3,5 s, on bascule sur le panneau de secours. */
  const armPlayGuard = useCallback(() => {
    window.clearTimeout(playGuardTimer.current);
    playGuardTimer.current = window.setTimeout(() => {
      if (playingRef.current) return;
      setBlockedId(videoId);
    }, PLAY_START_TIMEOUT_MS);
  }, [videoId]);

  /** Recrée le lecteur : nouvelle tentative d'intégration après un blocage. */
  const retryPlayback = useCallback(() => {
    window.clearTimeout(blockTimer.current);
    startedRef.current = false;
    setBlockedId(null);
    setErrorId(null);
    setFallbackId(null);
    setStartedId(null);
    setReadyId(null);
    setPlaying(false);
    setAttempt((value) => value + 1);
  }, []);

  useEffect(() => {
    let cancelled = false;
    let created: YTPlayer | null = null;
    let slot: HTMLElement | null = null;

    startedRef.current = false;

    void loadYouTubeApi().then((ok) => {
      if (cancelled) return;
      if (!ok || !containerRef.current || !window.YT) {
        setFallbackId(videoId);
        return;
      }
      slot = document.createElement("div");
      slot.style.cssText = "position:absolute;inset:0";
      containerRef.current.appendChild(slot);
      created = new window.YT.Player(slot, {
        videoId,
        playerVars: {
          controls: 0,
          rel: 0,
          playsinline: 1,
          iv_load_policy: 3,
          origin: window.location.origin,
          host: 'https://www.youtube.com',
        },
        events: {
          onReady: (event) => {
            if (cancelled) return;
            playerRef.current = event.target;
            event.target.getIframe().title = title;
            setDuration(event.target.getDuration() || 0);
            setCurrentTime(0);
            setWatchedMax(0);
            endedNotified.current = false;
            playingRef.current = false;
            setPlaying(false);
            setMuted(event.target.isMuted());
            setReadyId(videoId);
            if (autoplayRef.current) {
              event.target.playVideo();
              armBlockWatch();
              armPlayGuard();
            }
            showBar();
          },
          onStateChange: (event) => {
            if (cancelled) return;
            const isPlaying = event.data === STATE_PLAYING;
            const isEnded = event.data === STATE_ENDED;
            playingRef.current = isPlaying;
            setPlaying(isPlaying);
            const d = event.target.getDuration();
            if (d) setDuration(d);
            if (isPlaying || event.data === STATE_BUFFERING) {
              // Lecture (ou mise en tampon acceptée) : le lecteur a réagi.
              window.clearTimeout(playGuardTimer.current);
            }
            if (isPlaying) {
              startedRef.current = true;
              clearBlockWatch();
              setBlockedId(null);
              setStartedId(videoId);
              showBar();
              window.clearTimeout(flashTimer.current);
              setStartFlash(true);
              flashTimer.current = window.setTimeout(
                () => setStartFlash(false),
                8000,
              );
            } else {
              const time = event.target.getCurrentTime() || 0;
              const markTo = Math.max(time, isEnded ? d || 0 : 0);
              setWatchedMax((w) => (markTo > w ? markTo : w));
              window.clearTimeout(hideTimer.current);
              window.clearTimeout(flashTimer.current);
              setStartFlash(false);
              setBarVisible(true);
              if (isEnded && !endedNotified.current) {
                endedNotified.current = true;
                onEndedRef.current?.();
              }
            }
          },
          onError: (event) => {
            if (cancelled) return;
            if (process.env.NODE_ENV !== "production") {
              console.warn(`[youtube-player] onError code=${event.data} video=${videoId}`);
            }
            // Retire l'iframe de YouTube : sans cela, le lecteur en erreur
            // continuait d'afficher la vérification « pas un robot » par-dessus
            // le message de remplacement.
            clearBlockWatch();
            try {
              playerRef.current?.destroy();
            } catch {
              // joueur déjà détruit
            }
            playerRef.current = null;
            slot?.remove();
            slot = null;
            setReadyId(null);
            setErrorId(videoId);
          },
        },
      });
      playerRef.current = created;
    });

    return () => {
      cancelled = true;
      window.clearTimeout(hideTimer.current);
      window.clearTimeout(flashTimer.current);
      window.clearTimeout(blockTimer.current);
      window.clearTimeout(playGuardTimer.current);
      try {
        created?.destroy();
      } catch {
        // joueur déjà détruit
      }
      slot?.remove();
      playerRef.current = null;
    };
  }, [videoId, showBar, title, attempt, armBlockWatch, armPlayGuard, clearBlockWatch]);

  useEffect(() => {
    if (!isReady || !playing) return;
    const id = window.setInterval(() => {
      const player = playerRef.current;
      if (!player) return;
      const time = player.getCurrentTime() || 0;
      setCurrentTime(time);
      setWatchedMax((w) => (time > w ? time : w));
      setDuration((d) => d || player.getDuration() || 0);
    }, 500);
    return () => window.clearInterval(id);
  }, [isReady, playing]);

  useEffect(() => {
    const onChange = () => setIsFullscreen(Boolean(document.fullscreenElement));
    document.addEventListener("fullscreenchange", onChange);
    return () => document.removeEventListener("fullscreenchange", onChange);
  }, []);

  const togglePlay = () => {
    const player = playerRef.current;
    if (!player || !isReady) return;
    const next = !playingRef.current;
    playingRef.current = next;
    if (next) {
      try {
        player.playVideo();
        armPlayGuard();
      } catch {
        // Lecteur refusé (bot-check / vidéo inembeddable) : secours immédiat.
        setBlockedId(videoId);
        return;
      }
    } else {
      try {
        player.pauseVideo();
      } catch {
        // lecteur déjà détruit
      }
      window.clearTimeout(playGuardTimer.current);
    }
    showBar();
  };

  const toggleMute = () => {
    const player = playerRef.current;
    if (!player || !isReady) return;
    if (player.isMuted()) {
      player.unMute();
      setMuted(false);
    } else {
      player.mute();
      setMuted(true);
    }
    showBar();
  };

  const toggleFullscreen = () => {
    if (document.fullscreenElement) {
      void document.exitFullscreen();
    } else {
      void containerRef.current?.requestFullscreen();
    }
  };

  const seekCap =
    duration > 0 ? Math.min(duration, watchedMax) : watchedMax;

  const onSeek = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = Math.min(Number(event.target.value), seekCap);
    setCurrentTime(value);
    playerRef.current?.seekTo(value, true);
    showBar();
  };

  const fallbackSrc = isFallback
    ? toEmbedUrl(`https://www.youtube.com/watch?v=${videoId}`)
    : null;

  if (hasError) {
    return (
      <div
        className={cn(
          "w-full overflow-hidden bg-black",
          fill ? "absolute inset-0 h-full w-full" : "relative aspect-video",
          className,
        )}
      >
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 px-6 text-center">
          <VideoOffIcon className="size-6 text-muted-foreground" aria-hidden />
          <p className="max-w-sm text-sm leading-relaxed text-muted-foreground">
            {t.videoPlaybackFailed}
          </p>
          <RecoveryActions
            watchUrl={watchUrl}
            onRetry={retryPlayback}
            onMarkWatched={onEnded ? () => onEndedRef.current?.() : undefined}
          />
        </div>
      </div>
    );
  }

  const max = seekCap;

  return (
    <div
      ref={containerRef}
      className={cn(
        "w-full overflow-hidden bg-black",
        fill ? "absolute inset-0 h-full w-full" : "relative aspect-video",
        "[&_iframe]:absolute [&_iframe]:inset-0 [&_iframe]:h-full [&_iframe]:w-full",
        className,
      )}
      onMouseMove={isReady ? showBar : undefined}
      onMouseLeave={() => {
        window.clearTimeout(hideTimer.current);
        if (isReady && playingRef.current) setBarVisible(false);
      }}
      onTouchStart={isReady ? showBar : undefined}
    >
      {fallbackSrc ? (
        <iframe
          src={fallbackSrc}
          title={title}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
          loading="lazy"
        />
      ) : null}

      {isFallback ? (
        <div className="absolute right-3 top-3 z-20">
          <RecoveryActions
            watchUrl={watchUrl}
            onRetry={retryPlayback}
            onMarkWatched={onEnded ? () => onEndedRef.current?.() : undefined}
          />
        </div>
      ) : null}

      {blocked ? (
        <div className="pointer-events-none absolute inset-0 z-30 flex flex-col items-center justify-center gap-3 bg-black/75 px-6 text-center">
          <p className="text-sm font-semibold text-white">
            {t.videoBlockedTitle}
          </p>
          <p className="max-w-md text-xs leading-relaxed text-white/75">
            {t.videoBlockedHint}
          </p>
          <div className="pointer-events-auto">
            <RecoveryActions
              watchUrl={watchUrl}
              onRetry={retryPlayback}
              onMarkWatched={onEnded ? () => onEndedRef.current?.() : undefined}
            />
          </div>
        </div>
      ) : null}

      {isReady ? (
        <>
          {!playing || startFlash ? (
            <div
              aria-hidden
              className="pointer-events-none absolute inset-x-0 top-0 z-20 h-14 bg-black"
            />
          ) : null}

          <button
            type="button"
            onClick={togglePlay}
            aria-label={playing ? t.player.pause : t.player.play}
            className={cn(
              "group/overlay absolute inset-0 z-10 grid cursor-pointer place-items-center focus-visible:outline-none",
              blocked && "pointer-events-none",
            )}
          >
            {playing ? (
              <span
                className={cn(
                  "grid size-14 place-items-center rounded-full bg-black/55 text-white opacity-0 transition-opacity duration-200 group-hover/overlay:opacity-100",
                  barVisible && "opacity-100",
                )}
                aria-hidden
              >
                <PauseIcon className="size-6" />
              </span>
            ) : (
              <span
                className={cn(
                  "grid place-items-center rounded-full bg-white text-electric-strong transition-opacity duration-200",
                  started ? "size-16" : "aspect-square w-[15%] min-w-24",
                )}
                aria-hidden
              >
                <PlayIcon className="size-6 fill-current" />
              </span>
            )}
          </button>

          <div
            className={cn(
              "absolute inset-x-0 bottom-0 z-20 bg-black px-3 pt-7 pb-2 transition-opacity duration-200",
              barVisible ? "opacity-100" : "pointer-events-none opacity-0",
            )}
            onMouseEnter={() => {
              barHoveredRef.current = true;
              window.clearTimeout(hideTimer.current);
            }}
            onMouseLeave={() => {
              barHoveredRef.current = false;
              showBar();
            }}
          >
            <input
              type="range"
              min={0}
              max={max}
              step={0.1}
              value={Math.min(currentTime, max)}
              onChange={onSeek}
              aria-label={t.player.seek}
              aria-valuetext={`${formatTime(currentTime)} / ${formatTime(duration)}`}
              className="block h-1.5 w-full cursor-pointer appearance-none rounded-full bg-white/30 accent-electric"
            />
            <div className="mt-1.5 flex items-center gap-2 text-white">
              <button
                type="button"
                onClick={togglePlay}
                aria-label={playing ? t.player.pause : t.player.play}
                className="grid size-7 cursor-pointer place-items-center rounded-md transition-colors hover:bg-white/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-electric"
              >
                {playing ? (
                  <PauseIcon className="size-4" aria-hidden />
                ) : (
                  <PlayIcon className="size-4 fill-current" aria-hidden />
                )}
              </button>
              <button
                type="button"
                onClick={toggleMute}
                aria-label={muted ? t.player.unmute : t.player.mute}
                className="grid size-7 cursor-pointer place-items-center rounded-md transition-colors hover:bg-white/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-electric"
              >
                {muted ? (
                  <VolumeXIcon className="size-4" aria-hidden />
                ) : (
                  <Volume2Icon className="size-4" aria-hidden />
                )}
              </button>
              <span className="text-[11px] tabular-nums text-white/85">
                {formatTime(currentTime)} / {formatTime(duration)}
              </span>
              <button
                type="button"
                onClick={toggleFullscreen}
                aria-label={
                  isFullscreen ? t.player.exitFullscreen : t.player.fullscreen
                }
                className="ml-auto grid size-7 cursor-pointer place-items-center rounded-md transition-colors hover:bg-white/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-electric"
              >
                {isFullscreen ? (
                  <MinimizeIcon className="size-4" aria-hidden />
                ) : (
                  <MaximizeIcon className="size-4" aria-hidden />
                )}
              </button>
            </div>
          </div>
        </>
      ) : null}

      {!isReady && !fallbackSrc ? (
        <div className="absolute inset-0 z-10 grid place-items-center">
          <span
            className="size-9 animate-spin rounded-full border-2 border-white/30 border-t-white"
            aria-hidden
          />
        </div>
      ) : null}
    </div>
  );
}
