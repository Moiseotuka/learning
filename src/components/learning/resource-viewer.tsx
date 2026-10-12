"use client";

import { createContext, useContext, useState } from "react";
import { EyeIcon, GlobeIcon, XIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogTitle,
} from "@/components/ui/dialog";
import { messages } from "@/i18n";
import { extractYouTubeId, toEmbedUrl } from "@/lib/embed-url";
import type { ChapterResource } from "@/lib/learning/types";
import { cleanVideoTitle } from "@/lib/learning/video-title";
import { YouTubePlayer } from "@/components/learning/youtube-player";
import { cn } from "cn";

const t = messages.learner;

type ResourceItem = ChapterResource;

type OpenResource = (resource: ResourceItem) => void;

const ResourceViewerContext = createContext<OpenResource>(() => undefined);

export function useResourceViewer() {
  return useContext(ResourceViewerContext);
}

function hostnameOf(url: string) {
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch {
    return url;
  }
}

function ResourceFrame({
  resource,
  onClose,
}: {
  resource: ResourceItem | null;
  onClose: () => void;
}) {
  const src = resource ? toEmbedUrl(resource.url) : null;
  const videoId = resource ? extractYouTubeId(resource.url) : null;
  const hasEmbeddableContent = Boolean(videoId || src);
  const label = resource
    ? videoId
      ? cleanVideoTitle(resource.label ?? "") || t.player.resourceVideo
      : (resource.label ?? "")
    : "";

  return (
    <Dialog
      open={resource !== null}
      onOpenChange={(open) => {
        if (!open) onClose();
      }}
    >
      <DialogContent
        showCloseButton={false}
        className="top-0 left-0 h-[100dvh] w-screen max-w-none translate-x-0 translate-y-0 grid-rows-[auto_minmax(0,1fr)] gap-0 rounded-none border-0 p-0"
      >
        <div className="flex h-14 shrink-0 items-center gap-3 border-b border-hairline bg-card px-3 sm:px-4">
          <span className="grid size-8 shrink-0 place-items-center rounded-lg bg-electric/10 text-electric">
            <EyeIcon className="size-4" aria-hidden />
          </span>
          <div className="min-w-0 flex-1">
            <DialogTitle className="truncate text-sm font-semibold">
              {label}
            </DialogTitle>
            <DialogDescription className="flex items-center gap-1 truncate text-xs text-muted-foreground">
              <GlobeIcon className="size-3 shrink-0" aria-hidden />
              {resource
                ? videoId
                  ? t.player.resourceVideo
                  : hostnameOf(resource.url)
                : ""}
            </DialogDescription>
          </div>

          <p className="hidden max-w-xs text-right text-[11px] leading-snug text-muted-foreground lg:block">
            {t.player.resourceBlockedHint}
          </p>

          <Button
            variant="ghost"
            size="icon-sm"
            aria-label={t.player.resourceClose}
            onClick={onClose}
          >
            <XIcon aria-hidden />
          </Button>
        </div>

        <div className="relative min-h-0 bg-muted/40">
          {videoId && resource ? (
            <YouTubePlayer
              key={resource.url}
              videoId={videoId}
              title={label}
              fill
            />
          ) : src ? (
            <iframe
              key={src}
              src={src}
              title={label}
              loading="eager"
              className="absolute inset-0 size-full border-0 bg-background"
            />
          ) : resource && !hasEmbeddableContent ? (
            <div className="grid h-full place-items-center p-6 text-center text-sm text-muted-foreground">
              <div className="max-w-md space-y-3">
                <p className="text-base font-medium text-foreground">
                  {t.player.resourceNotPlayableTitle}
                </p>
                <p>{t.player.resourceNotPlayableHint}</p>
              </div>
            </div>
          ) : null}
        </div>
      </DialogContent>
    </Dialog>
  );
}

export function ResourceViewerProvider({ children }: { children: React.ReactNode }) {
  const [resource, setResource] = useState<ResourceItem | null>(null);

  return (
    <ResourceViewerContext.Provider value={setResource}>
      {children}
      <ResourceFrame resource={resource} onClose={() => setResource(null)} />
    </ResourceViewerContext.Provider>
  );
}

export function ResourceLink({
  label,
  url,
  className,
  children,
}: {
  label: string;
  url: string;
  className?: string;
  children: React.ReactNode;
}) {
  const openResource = useResourceViewer();

  return (
    <button
      type="button"
      onClick={() => openResource({ label, url })}
      className={cn("text-left", className)}
    >
      {children}
    </button>
  );
}
