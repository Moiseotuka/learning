import Link from "next/link";
import { ArrowRightIcon, GraduationCapIcon, LockIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { levels, type LevelType } from "@/config/catalog";
import { messages } from "@/i18n";
import { getLearnerTrack, getLevelPricing } from "@/lib/learning/queries";

const t = messages.learner;
const up = t.upsell;

/**
 * Relais d'achat pour l'apprenant d'un niveau gratuit : il liste les niveaux
 * réellement payants du domaine, avec le nombre de chapitres en attente et le
 * prix enregistré en base. Aucune donnée inventée — la carte disparaît si le
 * domaine n'a pas de tarif.
 */
export async function LevelUpsellCard({
  trackSlug,
  categoryId,
  currentLevel,
}: {
  trackSlug: string;
  categoryId: string;
  currentLevel: LevelType;
}) {
  const index = levels.indexOf(currentLevel);
  if (index < 0 || index >= levels.length - 1) return null;

  const [pricing, track] = await Promise.all([
    getLevelPricing(categoryId),
    getLearnerTrack(trackSlug),
  ]);
  if (!pricing || !track) return null;

  const locked = levels
    .slice(index + 1)
    .filter(
      (level) =>
        !pricing.access[level] &&
        pricing.prices[level] !== undefined &&
        track.chapters.some((chapter) => chapter.level === level),
    );
  if (locked.length === 0) return null;

  const next = locked[0];
  const nextChapters = track.chapters.filter(
    (chapter) => chapter.level === next,
  ).length;
  const nextPrice = pricing.prices[next];

  return (
    <section className="rounded-2xl border border-electric/30 bg-electric/[0.04] p-5">
      <div className="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-electric">
        <GraduationCapIcon className="size-4" aria-hidden />
        {up.eyebrow}
      </div>

      <h2 className="mt-2 text-base font-semibold tracking-tight text-foreground">
        {up.title(messages.common.levels[next], nextChapters)}
      </h2>
      <p className="mt-1.5 max-w-[68ch] text-xs leading-relaxed text-muted-foreground">
        {up.intro}
      </p>

      <div className="mt-4 flex flex-wrap items-center gap-3">
        <Button asChild className="h-10 px-4">
          <Link href={`/app/acheter?cat=${categoryId}&level=${next}`}>
            {up.cta(nextPrice)}
            <ArrowRightIcon aria-hidden />
          </Link>
        </Button>
        <span className="text-[11px] leading-relaxed text-muted-foreground">
          {up.paidWith}
        </span>
      </div>

      {locked.length > 1 ? (
        <div className="mt-4 border-t border-electric/20 pt-4">
          <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
            {up.alsoLocked}
          </p>
          <ul className="mt-2 flex flex-wrap gap-2">
            {locked.slice(1).map((level) => (
              <li key={level}>
                <Link
                  href={`/app/acheter?cat=${categoryId}&level=${level}`}
                  className="inline-flex items-center gap-1.5 rounded-full border border-hairline bg-card px-3 py-1 text-[11px] font-medium text-muted-foreground transition-colors hover:border-electric/50 hover:text-electric"
                >
                  <LockIcon className="size-3" aria-hidden />
                  {up.levelChip(
                    messages.common.levels[level],
                    track.chapters.filter(
                      (chapter) => chapter.level === level,
                    ).length,
                    pricing.prices[level] ?? 0,
                  )}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
    </section>
  );
}
