"use client";

import Link from "next/link";
import { useMemo, useRef, useState } from "react";
import {
  ArrowRightIcon,
  CheckCircle2Icon,
  FileTextIcon,
  LockIcon,
  PlayCircleIcon,
} from "lucide-react";

import { attestVideoWatched, recordVideoTick } from "@/lib/actions/learning";
import { messages } from "@/i18n";
import { playableVideos, videoToken } from "@/lib/learning/video-playability";
import { videoDisplayTitle } from "@/lib/learning/video-title";
import type { ChapterVideo } from "@/lib/learning/types";
import { cn } from "cn";
import { YouTubePlayer } from "@/components/learning/youtube-player";

const t = messages.learner;

export function TutorialPlayer({
  chapterId,
  chapterPosition,
  videos,
  initialWatched = [],
  initialSeconds,
  documentHref,
  onAllWatched,
}: {
  chapterId: string;
  /** Position du chapitre dans le parcours : sert à numéroter les leçons. */
  chapterPosition: number;
  videos: ChapterVideo[];
  initialWatched?: string[];
  /** Seconde de reprise par jeton de vidéo (position de la dernière sortie). */
  initialSeconds?: Record<string, number>;
  documentHref: string;
  onAllWatched?: () => void;
}) {
  const playlist = useMemo(() => playableVideos(videos), [videos]);
  const tokens = useMemo(
    () => playlist.map((video) => videoToken(video) ?? video.url),
    [playlist],
  );
  const titles = useMemo(
    () =>
      playlist.map((video, index) =>
        videoDisplayTitle(video, chapterPosition, index),
      ),
    [playlist, chapterPosition],
  );

  const [watched, setWatched] = useState<Set<string>>(
    () => new Set(initialWatched),
  );
  const [positions, setPositions] = useState<Record<string, number>>(
    () => ({ ...initialSeconds }),
  );
  const [active, setActive] = useState(() => {
    const first = tokens.findIndex((token) => !initialWatched.includes(token));
    return first >= 0 ? first : 0;
  });
  const [notice, setNotice] = useState<string | null>(null);
  /** Battement de lecture en vol, par leçon : attendu avant l'attestation. */
  const pendingWrites = useRef<Record<string, Promise<{ ok: boolean }>>>({});

  const current = playlist[active];
  const currentToken = tokens[active];
  const watchedCount = tokens.filter((token) => watched.has(token)).length;
  const allDone =
    playlist.length > 0 && tokens.every((token) => watched.has(token));
  const firstUnwatched = tokens.findIndex((token) => !watched.has(token));

  const reportProgress =
    (token: string | undefined) => (seconds: number, duration: number) => {
      if (!token) return;
      setPositions((prev) =>
        prev[token] === seconds ? prev : { ...prev, [token]: seconds },
      );
      // Le battement alimente la preuve côté serveur ; sans lui, l'attestation
      // refuserait une leçon légitimement terminée. Cette fonction est appelée
      // par l'événement de lecture du lecteur, jamais pendant le rendu.
      // eslint-disable-next-line react-hooks/refs
      pendingWrites.current[token] = recordVideoTick({
        chapterId,
        videoToken: token,
        seconds,
        duration,
      });
    };

  /**
   * Une leçon n'est comptée terminée que si le serveur l'a vérifiée : la fin de
   * la vidéo ne suffit plus, il faut la trace des battements de lecture.
   */
  const complete = async (token: string | undefined) => {
    if (!token || watched.has(token)) return true;
    await pendingWrites.current[token];
    const result = await attestVideoWatched(chapterId, token).catch(() => ({
      ok: false,
    }));
    if (!result.ok) {
      setNotice(t.videoNotRecorded);
      return false;
    }
    setNotice(null);
    setWatched((prev) => {
      const next = new Set(prev);
      next.add(token);
      return next;
    });
    // Leçon terminée : un nouveau visionnage repart du début, pas de la fin.
    setPositions((prev) => {
      if (!(token in prev)) return prev;
      const next = { ...prev };
      delete next[token];
      return next;
    });
    return true;
  };

  const handleEnded = () => {
    void complete(currentToken).then((done) => {
      if (!done) return;
      if (active < playlist.length - 1) {
        setActive(active + 1);
      } else {
        onAllWatched?.();
      }
    });
  };

  const selectVideo = (index: number) => {
    if (index === active) return;
    const token = tokens[index];
    if (!(index <= firstUnwatched || (token && watched.has(token)))) return;
    setActive(index);
  };

  if (playlist.length === 0 || !current) {
    return (
      <div className="py-8 text-center">
        <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-muted text-muted-foreground">
          <PlayCircleIcon className="size-6" aria-hidden />
        </span>
        <p className="mx-auto mt-4 max-w-[52ch] text-sm leading-relaxed text-muted-foreground">
          {t.tutorial.empty}
        </p>
        <Link
          href={documentHref}
          className="mt-4 inline-flex items-center gap-2 text-sm font-medium text-electric transition-colors hover:underline"
        >
          <FileTextIcon className="size-4" aria-hidden />
          {t.switchToDocument}
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3 text-xs">
        <p className="font-medium tabular-nums text-muted-foreground">
          {t.videosProgress(watchedCount, playlist.length)}
        </p>
        {allDone ? (
          <Link
            href={documentHref}
            className="inline-flex items-center gap-2 font-medium text-electric transition-colors hover:underline"
          >
            {t.switchToDocument}
            <ArrowRightIcon className="size-4" aria-hidden />
          </Link>
        ) : (
          <p className="text-[11px] text-muted-foreground">{t.videoAutoNext}</p>
        )}
      </div>

      <div className="overflow-hidden rounded-xl">
        <YouTubePlayer
          key={current.url}
          videoId={videoToken(current) ?? current.url}
          title={titles[active] ?? current.title}
          autoplay={active > 0}
          startAt={positions[currentToken] ?? 0}
          onEnded={handleEnded}
          onProgress={reportProgress(currentToken)}
        />

        {notice ? (
          <p className="mt-2 text-xs leading-relaxed text-emerald-600 dark:text-emerald-400">
            {notice}
          </p>
        ) : null}

        <div className="pt-3">
          <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
            {t.videoLabel(chapterPosition, active + 1)} · {t.tutorial.nowPlaying}
          </p>
          <h2 className="mt-1 text-base font-semibold leading-snug text-foreground">
            {titles[active] ?? current.title}
          </h2>
        </div>
      </div>

      <section>
        <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
          {t.tutorial.playlist}
        </p>
        <ul className="mt-1.5">
          {playlist.map((video, index) => {
            const isActive = index === active;
            const isWatched = watched.has(tokens[index]);
            const isBlocked =
              index > firstUnwatched && !isWatched && index !== active;
            const row = (
              <>
                <span
                  className={cn(
                    "grid size-5 shrink-0 place-items-center rounded-full text-[10px] font-medium tabular-nums",
                    isWatched
                      ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                      : isActive
                        ? "bg-electric text-primary-foreground"
                        : "bg-muted text-muted-foreground",
                  )}
                >
                  {isWatched ? (
                    <CheckCircle2Icon className="size-3.5" aria-hidden />
                  ) : isBlocked ? (
                    <LockIcon className="size-3" aria-hidden />
                  ) : (
                    index + 1
                  )}
                </span>
                <span className="min-w-0 flex-1">
                  <span
                    className={cn(
                      "block truncate text-[13px] leading-snug",
                      isActive
                        ? "font-medium text-electric"
                        : "text-foreground/85",
                    )}
                  >
                    {titles[index] ?? video.title}
                  </span>
                  <span className="mt-0.5 block truncate text-xs tabular-nums text-muted-foreground">
                    {isBlocked
                      ? t.tutorial.sequential
                      : t.videoLabel(chapterPosition, index + 1)}
                  </span>
                </span>
                <PlayCircleIcon
                  className={cn(
                    "size-4 shrink-0",
                    isActive ? "text-electric" : "text-muted-foreground/60",
                  )}
                  aria-hidden
                />
              </>
            );
            const shell =
              "-mx-2 flex w-[calc(100%+1rem)] items-center gap-3 rounded-lg px-2 py-2 text-left";
            return (
              <li key={`${tokens[index]}-${index}`}>
                {isBlocked ? (
                  // Une ligne verrouillée n'est pas un bouton qui refuse de
                  // répondre : elle explique ce qu'il reste à regarder.
                  <div className={cn(shell, "opacity-70")}>{row}</div>
                ) : (
                  <button
                    type="button"
                    onClick={() => selectVideo(index)}
                    aria-current={isActive ? "true" : undefined}
                    className={cn(
                      shell,
                      "cursor-pointer transition-colors hover:bg-muted/70",
                      isActive && "bg-electric/10",
                    )}
                  >
                    {row}
                  </button>
                )}
              </li>
            );
          })}
        </ul>
      </section>
    </div>
  );
}
