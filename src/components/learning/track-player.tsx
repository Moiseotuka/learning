"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { useEffect, useState } from "react";
import {
  BookOpenIcon,
  Maximize2Icon,
  Minimize2Icon,
  PanelLeftCloseIcon,
  PanelLeftIcon,
  XIcon,
} from "lucide-react";

import { ResourceViewerProvider } from "@/components/learning/resource-viewer";
import { TrackSidebar } from "@/components/learning/track-sidebar";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { messages } from "@/i18n";
import type { LearnerTrack, TrackResourceGroup } from "@/lib/learning/types";

const t = messages.learner;

export function TrackPlayer({
  track,
  resources,
  videoCounts,
  pageCounts,
  children,
}: {
  track: LearnerTrack;
  resources: TrackResourceGroup[];
  videoCounts: Record<string, number>;
  pageCounts?: Record<string, number>;
  children: ReactNode;
}) {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);
  const [sheetOpen, setSheetOpen] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);

  useEffect(() => {
    const onChange = () => setIsFullscreen(Boolean(document.fullscreenElement));
    document.addEventListener("fullscreenchange", onChange);
    return () => document.removeEventListener("fullscreenchange", onChange);
  }, []);

  const activeChapter =
    track.chapters.find((chapter) =>
      pathname.includes(`/chapitres/${chapter.slug}`),
    ) ?? null;

  const sectionTitle = activeChapter
    ? `${activeChapter.position}. ${activeChapter.title}`
    : track.title;

  const toggleFullscreen = () => {
    if (document.fullscreenElement) {
      void document.exitFullscreen();
    } else {
      void document.documentElement.requestFullscreen?.();
    }
  };

  return (
    <ResourceViewerProvider>
      <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
        <div className="flex h-[100dvh] flex-col bg-background">
          <header className="flex h-16 shrink-0 items-center gap-3 border-b border-hairline bg-card px-4 sm:px-5">
            <Link
              href="/"
              aria-label={messages.meta.title}
              className="shrink-0"
            >
              <Logo />
            </Link>
            <span
              className="hidden h-6 w-px bg-hairline sm:block"
              aria-hidden
            />
            <h1 className="min-w-0 flex-1 truncate text-base font-semibold tracking-tight text-foreground sm:text-lg">
              {track.title}
            </h1>
            <Button
              asChild
              variant="ghost"
              size="icon-sm"
              aria-label={t.player.backToOverview}
            >
              <Link href={`/app/parcours/${track.slug}`}>
                <BookOpenIcon aria-hidden />
              </Link>
            </Button>
            <Button
              asChild
              variant="ghost"
              size="icon"
              aria-label={t.player.quit}
            >
              <Link href="/app">
                <XIcon aria-hidden />
              </Link>
            </Button>
          </header>

          <div className="flex min-h-0 flex-1">
            {!collapsed ? (
              <aside className="hidden w-80 shrink-0 flex-col border-r border-hairline bg-card lg:flex">
                <TrackSidebar
                  track={track}
                  resources={resources}
                  videoCounts={videoCounts}
                  pageCounts={pageCounts}
                />
              </aside>
            ) : null}

            <div className="flex min-w-0 flex-1 flex-col">
              <div className="flex h-12 shrink-0 items-center gap-2 border-b border-hairline px-3 sm:px-4">
                <SheetTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon-sm"
                    className="lg:hidden"
                    aria-label={t.player.sidebarToggle}
                  >
                    <PanelLeftIcon aria-hidden />
                  </Button>
                </SheetTrigger>

                <Button
                  variant="ghost"
                  size="icon-sm"
                  className="hidden lg:inline-flex"
                  aria-label={t.player.sidebarToggle}
                  aria-expanded={!collapsed}
                  onClick={() => setCollapsed((value) => !value)}
                >
                  {collapsed ? (
                    <PanelLeftIcon aria-hidden />
                  ) : (
                    <PanelLeftCloseIcon aria-hidden />
                  )}
                </Button>

                <p className="min-w-0 flex-1 truncate text-sm font-medium text-foreground">
                  {sectionTitle}
                </p>

                <div className="flex shrink-0 items-center gap-1">
                  <ThemeToggle />
                  <Button
                    variant="ghost"
                    size="icon-sm"
                    aria-label={
                      isFullscreen
                        ? t.player.shellFullscreenExit
                        : t.player.shellFullscreen
                    }
                    onClick={toggleFullscreen}
                  >
                    {isFullscreen ? (
                      <Minimize2Icon aria-hidden />
                    ) : (
                      <Maximize2Icon aria-hidden />
                    )}
                  </Button>
                </div>
              </div>

              <div className="min-h-0 flex-1 overflow-y-auto">
                <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 lg:py-8">
                  {children}
                </div>
              </div>
            </div>
          </div>

          <SheetContent side="left" className="w-80 gap-0 p-0 sm:max-w-80">
            <SheetHeader className="sr-only">
              <SheetTitle>{track.title}</SheetTitle>
              <SheetDescription>{t.sidebarTitle}</SheetDescription>
            </SheetHeader>
            <TrackSidebar
              track={track}
              resources={resources}
              videoCounts={videoCounts}
              pageCounts={pageCounts}
              onNavigate={() => setSheetOpen(false)}
            />
          </SheetContent>
        </div>
      </Sheet>
    </ResourceViewerProvider>
  );
}
