"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import {
  ArrowRightIcon,
  CheckCircle2Icon,
  FileTextIcon,
  PlayCircleIcon,
} from "lucide-react";

import { markVideoWatched } from "@/lib/actions/learning";
import { messages } from "@/i18n";
import { extractYouTubeId, toEmbedUrl } from "@/lib/embed-url";
import type { ChapterVideo } from "@/lib/learning/types";
import { cn } from "cn";
import { YouTubePlayer } from "@/components/learning/youtube-player";

const t = messages.learner;

function toToken(video: ChapterVideo) {
  return extractYouTubeId(video.url) ?? video.url;
}

export function TutorialPlayer({
  chapterId,
  videos,
  initialWatched = [],
  documentHref,
  onAllWatched,
}: {
  chapterId: string;
  videos: ChapterVideo[];
  initialWatched?: string[];
  documentHref: string;
  onAllWatched?: () => void;
}) {
  const tokens = useMemo(() => videos.map(toToken), [videos]);
  const [watched, setWatched] = useState<Set<string>>(
    () => new Set(initialWatched),
  );
  const [active, setActive] = useState(() => {
    const first = tokens.findIndex((token) => !initialWatched.includes(token));
    return first >= 0 ? first : 0;
  });

  const current = videos[active];
  const src = current ? toEmbedUrl(current.url) : null;
  const videoId = current ? extractYouTubeId(current.url) : null;
  const hasEmbeddableVideo = Boolean(videoId || src);
  const watchedCount = tokens.filter((token) => watched.has(token)).length;
  const allDone =
    videos.length > 0 && tokens.every((token) => watched.has(token));
  const firstUnwatched = tokens.findIndex((token) => !watched.has(token));

  const handleEnded = () => {
    const token = tokens[active];
    if (!token) return;
    setWatched((prev) => {
      if (prev.has(token)) return prev;
      const next = new Set(prev);
      next.add(token);
      return next;
    });
    void markVideoWatched(chapterId, token).catch(() => undefined);
    if (active < videos.length - 1) {
      setActive(active + 1);
    } else {
      onAllWatched?.();
    }
  };

  const selectVideo = (index: number) => {
    if (index === active) return;
    const token = tokens[index];
    const isWatched = Boolean(token) && watched.has(token as string);
    if (!(index <= firstUnwatched || isWatched)) return;
    setActive(index);
  };

  if (videos.length === 0 || !current) {
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
          {t.videosProgress(watchedCount, videos.length)}
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
          <p className="text-[11px] text-muted-foreground">
            {t.videoAutoNext}
          </p>
        )}
      </div>

      <div className="overflow-hidden rounded-xl">
        {videoId && current ? (
          <YouTubePlayer
            key={current.url}
            videoId={videoId}
            title={current.title}
            autoplay={active > 0}
            onEnded={handleEnded}
          />
        ) : src ? (
          <div className="relative aspect-video w-full bg-black">
            <iframe
              key={current.url}
              src={src}
              title={current.title}
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowFullScreen
              className="absolute inset-0 h-full w-full"
            />
          </div>
        ) : current ? (
          <div className="grid aspect-video w-full place-items-center bg-muted p-6 text-center text-sm text-muted-foreground">
            <div className="max-w-md space-y-3">
              <p className="text-base font-medium text-foreground">
                Vidéo non intégrable directement.
              </p>
              <p>
                Cette URL ne correspond pas à une vidéo YouTube exploitable par l’embed. Ouvrez-la dans un nouvel onglet.
              </p>
              <button
                type="button"
                className="inline-flex items-center justify-center rounded-md bg-electric px-3 py-2 text-sm font-medium text-primary-foreground hover:opacity-95"
                onClick={() => {
                  window.open(current.url, "_blank", "noopener,noreferrer");
                }}
              >
                Ouvrir la vidéo
              </button>
            </div>
          </div>
        ) : null}

        <div className="pt-3">
          <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
            {t.tutorial.nowPlaying}
          </p>
          <h2 className="mt-1 text-base font-semibold leading-snug text-foreground">
            {current.title}
          </h2>
          {current.channel ? (
            <p className="mt-0.5 text-xs text-muted-foreground">
              {current.channel}
            </p>
          ) : null}
        </div>
      </div>

      <section>
        <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
          {t.tutorial.playlist}
        </p>
        <ul className="mt-1.5">
          {videos.map((video, index) => {
            const isActive = index === active;
            const isWatched = watched.has(tokens[index]);
            const isBlocked =
              index > firstUnwatched && !isWatched && index !== active;
            return (
              <li key={`${video.url}-${index}`}>
                <button
                  type="button"
                  onClick={() => selectVideo(index)}
                  aria-current={isActive ? "true" : undefined}
                  aria-disabled={isBlocked || undefined}
                  className={cn(
                    "-mx-2 flex w-[calc(100%+1rem)] items-center gap-3 rounded-lg px-2 py-2 text-left transition-colors",
                    isActive
                      ? "bg-electric/10"
                      : isBlocked
                        ? "cursor-not-allowed opacity-55"
                        : "cursor-pointer hover:bg-muted/70",
                  )}
                >
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
                      {video.title}
                    </span>
                    {video.channel ? (
                      <span className="mt-0.5 block truncate text-xs text-muted-foreground">
                        {video.channel}
                      </span>
                    ) : null}
                  </span>
                  <PlayCircleIcon
                    className={cn(
                      "size-4 shrink-0",
                      isActive
                        ? "text-electric"
                        : "text-muted-foreground/60",
                    )}
                    aria-hidden
                  />
                </button>
              </li>
            );
          })}
        </ul>
      </section>
    </div>
  );
}
