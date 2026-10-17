import type { ReactNode } from "react";
import { notFound } from "next/navigation";

import { TrackPlayer } from "@/components/learning/track-player";
import {
  getLearnerTrack,
  getTrackPageCounts,
  getTrackResources,
  getTrackVideoCounts,
} from "@/lib/learning/queries";

export default async function TrackLayout({
  children,
  params,
}: {
  children: ReactNode;
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const track = await getLearnerTrack(slug);
  if (!track) notFound();

  const [allResources, videoCounts, pageCounts] = await Promise.all([
    getTrackResources(track.id),
    getTrackVideoCounts(track.id),
    getTrackPageCounts(track.id),
  ]);

  // Verrou strict : les ressources d'un chapitre fermé (niveau non payé,
  // chapitre non atteint ou examen requis) n'apparaissent pas dans l'onglet.
  const accessible = new Set(
    track.chapters
      .filter(
        (chapter) =>
          chapter.unlocked && !chapter.levelLocked && !chapter.examLocked,
      )
      .map((chapter) => chapter.slug),
  );
  const resources = allResources.filter((group) =>
    accessible.has(group.chapterSlug),
  );

  return (
    <TrackPlayer
      track={track}
      resources={resources}
      videoCounts={videoCounts}
      pageCounts={pageCounts}
    >
      {children}
    </TrackPlayer>
  );
}
