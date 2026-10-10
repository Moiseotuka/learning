import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeftIcon, ExternalLinkIcon, PlayIcon } from "lucide-react";

import { levelTone } from "@/components/catalog/level-tone";
import { Badge } from "@/components/ui/badge";
import { messages } from "@/i18n";
import { getTutorialBySlug, getTutorials } from "@/lib/catalog/queries";
import { extractYouTubeId, toEmbedUrl } from "@/lib/embed-url";
import { YouTubePlayer } from "@/components/learning/youtube-player";

const t = messages;

function catalogueHref(categoryId: string) {
  const params = new URLSearchParams({ type: "tutoriels" });
  if (categoryId) params.set("tech", categoryId);
  return `/catalogue?${params.toString()}`;
}

export async function generateMetadata(
  props: PageProps<"/tutoriels/[slug]">,
): Promise<Metadata> {
  const { slug } = await props.params;
  const tutorial = await getTutorialBySlug(slug);

  if (!tutorial) {
    return { title: t.catalogue.empty.tutoriels, robots: { index: false } };
  }

  return {
    title: tutorial.title,
    description: tutorial.summary || t.catalogue.description,
  };
}

export default async function TutorialViewerPage(
  props: PageProps<"/tutoriels/[slug]">,
) {
  const { slug } = await props.params;
  const tutorial = await getTutorialBySlug(slug);

  if (!tutorial) notFound();

  const embed = toEmbedUrl(tutorial.url);
  const videoId = extractYouTubeId(tutorial.url);
  const related = (await getTutorials(tutorial.categoryId)).filter(
    (item) => item.id !== tutorial.id,
  );

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-10 sm:px-6 lg:py-14">
      <Link
        href={catalogueHref(tutorial.categoryId)}
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-electric"
      >
        <ArrowLeftIcon className="size-4" aria-hidden />
        {t.catalogue.viewer.back}
      </Link>

      <div className="mt-6 grid gap-8 lg:grid-cols-[minmax(0,1fr)_280px]">
        <div className="min-w-0">
          <div className="overflow-hidden rounded-2xl border border-hairline bg-card">
            {videoId ? (
              <YouTubePlayer videoId={videoId} title={tutorial.title} />
            ) : embed ? (
              <div className="relative aspect-video w-full bg-black">
                <iframe
                  src={embed}
                  title={tutorial.title}
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                  allowFullScreen
                  className="absolute inset-0 h-full w-full"
                />
              </div>
            ) : (
              <a
                href={tutorial.url}
                target="_blank"
                rel="noreferrer"
                className="grid aspect-video w-full place-items-center gap-2 bg-muted text-sm text-muted-foreground transition-colors hover:text-electric"
              >
                <PlayIcon className="size-8" aria-hidden />
                {t.catalogue.cards.watch}
              </a>
            )}

            <div className="p-5">
              <div className="flex flex-wrap items-center gap-2">
                <Badge
                  className={`rounded-full px-2 py-0.5 text-[11px] font-medium ${levelTone[tutorial.level]}`}
                  variant="secondary"
                >
                  {t.tracks.levelLabels[tutorial.level]}
                </Badge>
                <Link
                  href={catalogueHref(tutorial.categoryId)}
                  className="text-xs font-medium text-muted-foreground transition-colors hover:text-electric"
                >
                  {tutorial.category}
                </Link>
              </div>

              <h1 className="mt-3 text-balance text-xl font-semibold leading-snug sm:text-2xl">
                {tutorial.title}
              </h1>

              <p className="mt-2 text-sm text-muted-foreground">
                {t.catalogue.viewer.channel} : {tutorial.channel}
              </p>

              <p className="mt-4 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
                {tutorial.summary}
              </p>

              <a
                href={tutorial.url}
                target="_blank"
                rel="noreferrer"
                className="mt-5 inline-flex items-center gap-1.5 text-sm font-medium text-electric transition-colors hover:underline"
              >
                <ExternalLinkIcon className="size-4" aria-hidden />
                YouTube
              </a>
            </div>
          </div>
        </div>

        <aside aria-label={t.catalogue.viewer.related} className="min-w-0">
          <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
            {t.catalogue.viewer.related}
          </p>

          {related.length === 0 ? (
            <p className="mt-3 text-sm text-muted-foreground">
              {t.catalogue.empty.tutoriels}
            </p>
          ) : (
            <ul className="mt-3 space-y-3">
              {related.map((item) => (
                <li key={item.id}>
                  <Link
                    href={`/tutoriels/${item.slug}`}
                    className="group flex gap-3 rounded-xl border border-hairline bg-card p-2 transition-colors hover:border-electric/50"
                  >
                    <span className="relative aspect-video w-24 shrink-0 overflow-hidden rounded-lg bg-muted">
                      {item.thumbnail ? (
                        <Image
                          src={item.thumbnail}
                          alt=""
                          fill
                          sizes="96px"
                          className="object-cover"
                        />
                      ) : null}
                      <span className="absolute inset-0 grid place-items-center bg-foreground/40 opacity-0 transition-opacity group-hover:opacity-100">
                        <PlayIcon className="size-4 text-background" aria-hidden />
                      </span>
                    </span>
                    <span className="min-w-0">
                      <span className="line-clamp-2 text-xs leading-snug font-medium text-foreground">
                        {item.title}
                      </span>
                      <span className="mt-1 block truncate text-[11px] text-muted-foreground">
                        {item.channel}
                      </span>
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </aside>
      </div>
    </div>
  );
}
