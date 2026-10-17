import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRightIcon, BookOpenIcon, SearchIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ProgressBar } from "@/components/learning/progress-bar";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import { getLearnerTracks } from "@/lib/learning/queries";
import type { LearnerChapter, LearnerTrack } from "@/lib/learning/types";
import { cn } from "@/lib/utils";

const t = messages.learner;
const tf = t.formations;
const tl = messages.common.levels;

export const metadata: Metadata = {
  title: tf.title,
  robots: { index: false },
};

/** Les accents ne doivent jamais empêcher de retrouver une formation : « reseau »
 *  porte sur « Réseau », et une recherche tapée à main levée sur téléphone est
 *  rarement accentuée. */
function normaliser(valeur: string): string {
  return valeur
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "");
}

type EtatFormation = "en cours" | "pas commencee" | "terminee";

function etatDe(track: LearnerTrack): EtatFormation {
  if (track.totalChapters > 0 && track.completedCount >= track.totalChapters) {
    return "terminee";
  }
  return track.completedCount > 0 || track.chapters.some((c) => c.progress)
    ? "en cours"
    : "pas commencee";
}

const RANG: Record<EtatFormation, number> = {
  "en cours": 0,
  "pas commencee": 1,
  terminee: 2,
};

/** Le chapitre à reprendre : celui que la base annonce comme suivant, s'il n'est
 *  pas déjà validé. À défaut, le premier chapitre non validé — un apprenant qui a
 *  sauté une étape doit pouvoir la retrouver. */
function aReprendre(track: LearnerTrack): LearnerChapter | null {
  return (
    track.chapters.find(
      (c) => c.slug === track.nextChapterSlug && !(c.progress?.completed ?? false),
    ) ??
    track.chapters.find((c) => !(c.progress?.completed ?? false)) ??
    null
  );
}

function niveauEnCours(track: LearnerTrack): string | null {
  const niveau = track.levels.find((l) => !l.allCompleted);
  return niveau ? (tl[niveau.level as keyof typeof tl] ?? niveau.level) : null;
}

function niveauADebloquer(track: LearnerTrack): string | null {
  const bloque = track.chapters.find((c) => c.levelLocked);
  return bloque ? (tl[bloque.level as keyof typeof tl] ?? bloque.level) : null;
}

function CarteFormation({
  track,
  etat,
  reprise,
}: {
  track: LearnerTrack;
  etat: EtatFormation;
  reprise: LearnerChapter | null;
}) {
  const niveau = niveauEnCours(track);
  const aDebloquer = niveauADebloquer(track);
  const href = reprise
    ? `/app/parcours/${track.slug}/chapitres/${reprise.slug}`
    : `/app/parcours/${track.slug}`;

  return (
    <article className="flex flex-col rounded-2xl border border-hairline bg-card p-5 shadow-sm transition-colors hover:border-electric/40">
      <div className="flex items-start justify-between gap-3">
        <h2 className="text-base font-semibold leading-snug text-foreground">
          {track.title}
        </h2>
        <Badge
          variant="secondary"
          className={cn(
            "shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium",
            etat === "terminee"
              ? "bg-electric/12 text-electric"
              : "bg-muted text-muted-foreground",
          )}
        >
          {etat === "terminee"
            ? tf.finished
            : etat === "en cours"
              ? tf.inProgress
              : tf.notStarted}
        </Badge>
      </div>

      <p className="mt-1.5 line-clamp-2 text-xs leading-relaxed text-muted-foreground">
        {track.description}
      </p>

      <div className="mt-4">
        <div className="flex items-end justify-between gap-3">
          <span className="text-lg font-semibold leading-none tabular-nums text-foreground">
            {track.percent} %
          </span>
          <span className="text-xs tabular-nums text-muted-foreground">
            {t.chaptersLabel(track.completedCount, track.totalChapters)}
          </span>
        </div>
        <div className="mt-2">
          <ProgressBar percent={track.percent} />
        </div>
      </div>

      <ul className="mt-4 space-y-1 border-t border-hairline pt-3 text-xs text-muted-foreground">
        {reprise ? (
          <li>{tf.whereYouAre(reprise.title)}</li>
        ) : (
          <li>{tf.nothingYet}</li>
        )}
        {niveau ? <li>{tf.nextLevel(niveau)}</li> : null}
        {aDebloquer ? <li>{tf.levelLocked(aDebloquer)}</li> : null}
      </ul>

      <div className="mt-4 flex flex-wrap gap-2">
        <Button asChild className="h-10 px-4">
          <Link href={href}>
            {reprise
              ? reprise.progress
                ? tf.continue
                : tf.start
              : tf.openTrack}
            <ArrowRightIcon aria-hidden />
          </Link>
        </Button>
        <Button
          asChild
          variant="outline"
          className="h-10 border-hairline bg-background px-4"
        >
          <Link href={`/app/parcours/${track.slug}`}>
            <BookOpenIcon aria-hidden />
            {tf.openTrack}
          </Link>
        </Button>
      </div>
    </article>
  );
}

export default async function MesFormationsPage(props: PageProps<"/app/formations">) {
  await requireUser(links.dashboard);
  const searchParams = await props.searchParams;
  const terme =
    typeof searchParams.q === "string" ? searchParams.q.trim().slice(0, 80) : "";

  const tracks = await getLearnerTracks();
  const aiguillon = normaliser(terme);
  const visibles = tracks
    .filter((track) =>
      !aiguillon
        ? true
        : normaliser(`${track.title} ${track.description}`).includes(aiguillon),
    )
    .sort((a, b) => {
      const rang = RANG[etatDe(a)] - RANG[etatDe(b)];
      if (rang !== 0) return rang;
      return b.percent - a.percent;
    });

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          {tf.title}
        </h1>
        <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{tf.intro}</p>
      </header>

      {/* Recherche en GET simple, sans JavaScript : le champ fonctionne sur un
          téléphone à 2 Go de RAM comme sur un poste fixe, et le résultat est une
          URL que l'on peut renvoyer à quelqu'un. */}
      <form method="get" role="search" className="max-w-md">
        <label className="relative block">
          <span className="sr-only">{t.search.label}</span>
          <SearchIcon
            aria-hidden
            className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <input
            type="search"
            name="q"
            defaultValue={terme}
            placeholder={t.search.placeholder}
            className="h-10 w-full rounded-full border border-hairline bg-card pl-9 pr-3 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-electric"
          />
        </label>
        <noscript>
          <Button type="submit" className="mt-2 h-9 px-4">
            {t.search.label}
          </Button>
        </noscript>
      </form>

      {tracks.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-hairline bg-card px-6 py-12 text-center">
          <p className="text-sm leading-relaxed text-muted-foreground">{tf.empty}</p>
          <Button asChild className="mt-4 h-10 px-5">
            <Link href={links.catalogue}>
              {tf.emptyCta}
              <ArrowRightIcon aria-hidden />
            </Link>
          </Button>
        </div>
      ) : visibles.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-hairline bg-card px-6 py-12 text-center">
          <p className="text-sm text-muted-foreground">{tf.none}</p>
          <div className="mt-4 flex flex-wrap justify-center gap-2">
            <Button asChild variant="outline" className="h-10 border-hairline px-4">
              <Link href="/app/formations">{tf.noneCta}</Link>
            </Button>
            <Button asChild className="h-10 px-4">
              <Link href={`${links.catalogue}?q=${encodeURIComponent(terme)}`}>
                {tf.catalogueOf(terme)}
                <ArrowRightIcon aria-hidden />
              </Link>
            </Button>
          </div>
        </div>
      ) : (
        <div className="grid gap-5 md:grid-cols-2">
          {visibles.map((track) => (
            <CarteFormation
              key={track.id}
              track={track}
              etat={etatDe(track)}
              reprise={aReprendre(track)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
