import { notFound, redirect } from "next/navigation";

import { getLearnerChapter } from "@/lib/learning/queries";

export default async function TutorialPage({
  params,
}: {
  params: Promise<{ slug: string; chapterSlug: string }>;
}) {
  const { slug, chapterSlug } = await params;
  const chapter = await getLearnerChapter(slug, chapterSlug);
  if (!chapter) notFound();

  const chapterHref = `/app/parcours/${chapter.trackSlug}/chapitres/${chapter.slug}`;

  if (chapter.levelLocked || !chapter.unlocked || chapter.examLocked) {
    redirect(chapterHref);
  }

  redirect(
    chapter.videos.length > 0
      ? `${chapterHref}?etape=videos`
      : chapterHref,
  );
}
