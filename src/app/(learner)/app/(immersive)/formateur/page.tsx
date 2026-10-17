import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowLeftIcon,
  CalendarClockIcon,
  GraduationCapIcon,
  LayersIcon,
  UsersIcon,
  VideoIcon,
} from "lucide-react";

import { Notice } from "@/components/auth/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import {
  FREE_CLASS_SEATS,
  FREE_SESSION_MINUTES,
  type HostTier,
} from "@/lib/live/policy";
import { fill, formatDate, formatDateTime } from "@/lib/instructor/format";
import { instructorOfferOpen } from "@/lib/instructor/offer";
import { getInstructorPlans } from "@/lib/instructor/plans";
import {
  getInstructorClasses,
  getInstructorSessions,
  getInstructorStatus,
  planOf,
  type LiveSession,
} from "@/lib/instructor/queries";
import { cn } from "cn";

const t = messages.formateur;
const tl = messages.live;

export const metadata: Metadata = {
  title: t.dashboardTitle,
  robots: { index: false },
};

const NOTICE_KEYS = {
  actif: t.notices.actif,
  renouvelle: t.notices.renouvelle,
  classeCreee: t.notices.classeCreee,
} as const;

/** Hors composant : l'horloge rendrait le rendu du serveur non pur. */
function upcomingOnly(sessions: LiveSession[]) {
  const now = Date.now();
  return sessions.filter(
    (session) =>
      // Une salle ouverte reste « à venir » après son heure annoncée : c'est
      // la clôture par le formateur qui termine la séance, pas l'horloge.
      session.status === "live" ||
      (session.status === "scheduled" && new Date(session.endsAt).getTime() > now),
  );
}

function Stat({
  icon: Icon,
  label,
  value,
  hint,
}: {
  icon: typeof UsersIcon;
  label: string;
  value: string;
  hint?: string;
}) {
  return (
    <article className="rounded-2xl border border-hairline bg-card p-4">
      <p className="flex items-center gap-2 text-[11px] font-semibold tracking-wide text-muted-foreground uppercase">
        <Icon className="size-3.5 text-electric" aria-hidden />
        {label}
      </p>
      <p className="mt-2 text-xl font-semibold tabular-nums text-foreground">
        {value}
      </p>
      {hint ? (
        <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
          {hint}
        </p>
      ) : null}
    </article>
  );
}

/**
 * Bandeau de palier : c'est ici que l'abonnement se regrette. Un hôte expiré
 * voit ce que le palier gratuit lui laisse faire, un hôte proche de l'échéance
 * voit ses jours restants — dans les deux cas le renouvellement est à un clic,
 * pré-sélectionné sur son ancienne formule.
 */
function TierBanner({
  tier,
  daysLeft,
  planId,
}: {
  tier: HostTier;
  daysLeft: number;
  planId: string | null;
}) {
  const free = tier === "free";
  // Au palier payant, on ne parle d'échéance que lorsqu'elle approche : un
  // formateur à dix mois de son abonnement n'a rien à renouveler.
  if (!free && daysLeft > 7) return null;

  const query = planId ? `?plan=${encodeURIComponent(planId)}` : "";

  return (
    <section
      className={cn(
        "mt-6 rounded-2xl border p-4 sm:p-5",
        free
          ? "border-emerald-400/60 bg-emerald-500/8"
          : "border-hairline bg-card",
      )}
    >
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="min-w-0 max-w-[70ch]">
          <p
            className={cn(
              "text-xs font-semibold tracking-wider uppercase",
              free ? "text-emerald-700 dark:text-emerald-400" : "text-electric",
            )}
          >
            {free ? t.tier.free : t.tier.paid}
          </p>
          <p className="mt-2 text-sm leading-relaxed text-foreground">
            {free
              ? t.tier.expiredDowngrade
              : fill(t.tier.expiring, { days: daysLeft })}
          </p>
          {free ? (
            <p className="mt-1.5 text-xs leading-relaxed text-muted-foreground">
              {fill(t.tier.limits, {
                minutes: FREE_SESSION_MINUTES,
                seats: FREE_CLASS_SEATS,
              })}
            </p>
          ) : null}
        </div>

        {/* Offre fermée : aucun bouton désactivé. Un contrôle qui refuse le
            clic n'apprend rien, il fait croire que la page est cassée. */}
        {instructorOfferOpen ? (
          <div className="shrink-0">
            <Button asChild size="sm" className="h-9 px-4">
              <Link href={`/app/formateur/souscrire${query}`}>
                <GraduationCapIcon aria-hidden />
                {t.tier.renew}
              </Link>
            </Button>
          </div>
        ) : null}
      </div>
    </section>
  );
}

/**
 * Tableau de bord du formateur. Un abonné inactif (jamais souscrit ou période
 * écoulée) n'entre pas dans les chiffres : on lui présente l'offre, ce qui doit
 * le convertir plutôt que lui afficher un espace vide.
 */
export default async function InstructorDashboard({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string }>;
}) {
  const user = await requireUser("/app/profil");
  const { notice } = await searchParams;

  const status = await getInstructorStatus(user.id);
  const banner =
    notice && notice in NOTICE_KEYS
      ? NOTICE_KEYS[notice as keyof typeof NOTICE_KEYS]
      : null;

  if (!status.canHost) {
    const expired = Boolean(status.subscription?.expiresAt);

    return (
      <div className="mx-auto w-full max-w-4xl px-4 py-8 sm:px-6 lg:py-10">
        <Button
          asChild
          variant="ghost"
          className="-ml-2 mb-4 h-8 px-2 text-xs text-muted-foreground"
        >
          <Link href="/app/profil">
            <ArrowLeftIcon aria-hidden />
            {t.backToProfile}
          </Link>
        </Button>

        <div className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-7">
          <p className="text-xs font-semibold tracking-wider text-electric uppercase">
            {t.eyebrow}
          </p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-balance">
            {t.title}
          </h1>
          <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
            {t.subtitle}
          </p>

          {expired ? (
            <div className="mt-5">
              <Notice tone="error">
                {fill(t.expiredOn, {
                  date: formatDate(status.subscription?.expiresAt ?? ""),
                })}
                {" — "}
                {t.expiredNotice}
              </Notice>
            </div>
          ) : null}

          <ul className="mt-6 grid gap-4 sm:grid-cols-2">
            {t.benefits.map((benefit) => (
              <li
                key={benefit.title}
                className="rounded-2xl border border-hairline bg-card/60 p-4"
              >
                <h2 className="text-sm font-semibold text-foreground">
                  {benefit.title}
                </h2>
                <p className="mt-1.5 text-xs leading-relaxed text-muted-foreground">
                  {benefit.text}
                </p>
              </li>
            ))}
          </ul>

          <div className="mt-7 flex flex-wrap gap-3 border-t border-hairline pt-5">
            {instructorOfferOpen ? (
              <Button asChild size="lg" className="h-11 px-6">
                <Link href="/app/formateur/souscrire">
                  <GraduationCapIcon aria-hidden />
                  {expired ? t.reactivateCta : t.cta}
                </Link>
              </Button>
            ) : (
              <div className="w-full">
                <Notice tone="info">{t.offer.text}</Notice>
                <Button
                  asChild
                  variant="outline"
                  size="lg"
                  className="mt-3 h-11 px-6"
                >
                  <Link href="/app/profil">{t.offer.cta}</Link>
                </Button>
              </div>
            )}
            <Button asChild variant="outline" size="lg" className="h-11 px-5">
              <Link href="/formateurs">
                <UsersIcon aria-hidden />
                {t.eyebrow}
              </Link>
            </Button>
          </div>
        </div>
      </div>
    );
  }

  const [plans, classes, sessions] = await Promise.all([
    getInstructorPlans(),
    getInstructorClasses(user.id),
    getInstructorSessions(user.id),
  ]);

  const upcoming = upcomingOnly(sessions);
  const plan = planOf(plans, status.subscription?.planId);
  const seatsLeft = Math.max(0, status.subscription!.seatsLimit - status.seatsUsed);

  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:py-10">
      <Button
        asChild
        variant="ghost"
        className="-ml-2 mb-4 h-8 px-2 text-xs text-muted-foreground"
      >
        <Link href="/app/profil">
          <ArrowLeftIcon aria-hidden />
          {t.backToProfile}
        </Link>
      </Button>

      {banner ? (
        <div className="mb-5">
          <Notice tone="success">{banner}</Notice>
        </div>
      ) : null}

      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs font-semibold tracking-wider text-electric uppercase">
            {t.eyebrow}
          </p>
          <h1 className="mt-1.5 text-2xl font-semibold tracking-tight text-balance">
            {t.dashboardTitle}
          </h1>
          <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
            {t.dashboardIntro}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button asChild size="sm" className="h-9 px-4">
            <Link href="/app/formateur/classes">
              <UsersIcon aria-hidden />
              {t.classes.title}
            </Link>
          </Button>
          <Button asChild variant="outline" size="sm" className="h-9 px-4">
            <Link href="/app/formateur/live">
              <VideoIcon aria-hidden />
              {tl.module.title}
            </Link>
          </Button>
        </div>
      </div>

      <TierBanner
        tier={status.tier}
        daysLeft={status.daysLeft}
        planId={status.subscription?.planId ?? null}
      />

      <div className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Stat
          icon={GraduationCapIcon}
          label={t.cardSubscription}
          value={
            status.tier === "free"
              ? t.tier.free
              : plan
                ? fill(t.planOf, { label: plan.label })
                : "—"
          }
          hint={
            status.tier === "free" && status.subscription!.expiresAt
              ? fill(t.expiredOn, {
                  date: formatDate(status.subscription!.expiresAt),
                })
              : status.subscription!.expiresAt
                ? fill(t.expiresOn, {
                    date: formatDate(status.subscription!.expiresAt),
                  })
                : undefined
          }
        />
        <Stat
          icon={UsersIcon}
          label={t.cardSeats}
          value={`${status.seatsUsed} / ${status.subscription!.seatsLimit}`}
          hint={
            status.tier === "free"
              ? fill(t.seatsLeftFree, { count: seatsLeft })
              : fill(t.seatsLeft, { count: seatsLeft })
          }
        />
        <Stat
          icon={LayersIcon}
          label={t.cardClasses}
          value={String(status.classCount)}
        />
        <Stat
          icon={CalendarClockIcon}
          label={t.cardSessions}
          value={String(upcoming.length)}
          hint={upcoming[0] ? formatDateTime(upcoming[0].startsAt) : tl.module.empty}
        />
      </div>

      <section className="mt-8 rounded-2xl border border-hairline bg-card p-5">
        <div className="flex items-center gap-3">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {t.chooseTracks}
          </h2>
          <span className="h-px flex-1 bg-hairline" />
          <span className="text-xs tabular-nums text-muted-foreground">
            {/* Le plafond de parcours ne se joue qu'à la souscription : afficher
                « 3 / 1 » à un hôte redescendu au palier gratuit lui ferait croire
                qu'il est hors les règles. */}
            {status.tier === "paid"
              ? `${status.tracks.length} / ${status.subscription!.trackLimit}`
              : status.tracks.length}
          </span>
        </div>
        {status.tracks.length === 0 ? (
          <p className="mt-3 text-sm text-muted-foreground">{t.errors.noTrack}</p>
        ) : (
          <ul className="mt-3 flex flex-wrap gap-2">
            {status.tracks.map((track) => (
              <li key={track.id} className="max-w-full">
                <Link href={`/app/parcours/${track.slug}`} className="block">
                  <Badge
                    variant="secondary"
                    className="h-auto max-w-full rounded-xl px-3 py-1 text-left text-xs font-medium leading-snug whitespace-normal bg-electric/10 text-electric transition-colors hover:bg-electric/16"
                  >
                    {track.title}
                  </Badge>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="mt-6 rounded-2xl border border-hairline bg-card p-5">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {t.classes.title}
          </h2>
          <Button asChild variant="outline" size="sm" className="h-8 px-3">
            <Link href="/app/formateur/classes">{t.classes.create}</Link>
          </Button>
        </div>

        {classes.length === 0 ? (
          <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
            {t.classes.empty}
          </p>
        ) : (
          <ul className="mt-4 divide-y divide-hairline">
            {classes.slice(0, 5).map((klass) => (
              <li key={klass.id} className="flex flex-wrap items-center justify-between gap-3 py-3">
                <div className="min-w-0">
                  <Link
                    href={`/app/formateur/classes/${klass.id}`}
                    className="text-sm font-semibold text-foreground hover:text-electric"
                  >
                    {klass.title}
                  </Link>
                  <p className="mt-0.5 truncate text-xs text-muted-foreground">
                    {klass.trackTitle} · {fill(t.classes.students, { count: klass.memberCount })}
                  </p>
                </div>
                <Button asChild variant="ghost" size="sm" className="h-8 px-3">
                  <Link href={`/app/formateur/classes/${klass.id}`}>
                    {t.classes.open}
                  </Link>
                </Button>
              </li>
            ))}
          </ul>
        )}
      </section>

      {upcoming.length > 0 ? (
        <section className="mt-6 rounded-2xl border border-hairline bg-card p-5">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {tl.module.upcoming}
          </h2>
          <ul className="mt-4 divide-y divide-hairline">
            {upcoming.slice(0, 4).map((session) => (
              <li key={session.id} className="flex flex-wrap items-center justify-between gap-3 py-3">
                <div className="min-w-0">
                  <Link
                    href={`/app/live/${session.id}`}
                    className="text-sm font-semibold text-foreground hover:text-electric"
                  >
                    {session.title}
                  </Link>
                  <p className="mt-0.5 text-xs text-muted-foreground">
                    {formatDateTime(session.startsAt)}
                    {session.className ? ` · ${session.className}` : ""}
                  </p>
                </div>
                <Button asChild size="sm" className="h-8 px-3">
                  <Link href={`/app/live/${session.id}`}>{tl.room.join}</Link>
                </Button>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
