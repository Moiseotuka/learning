import type { Metadata } from "next";
import Link from "next/link";
import {
  AwardIcon,
  CalendarClockIcon,
  CheckCircle2Icon,
  GraduationCapIcon,
  ShieldCheckIcon,
  TrendingUpIcon,
} from "lucide-react";

import { Carte } from "@/components/admin/carte";
import { Kpi } from "@/components/admin/graphiques";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ProfileHeader } from "@/components/learner/profile-header";
import { SecurityCard } from "@/components/learner/security-card";
import { TestCertificateButton } from "@/components/learner/test-certificate-button";
import { OfferClosedPill } from "@/components/instructor/offer-closed-pill";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { getProfile, requireUser } from "@/lib/auth/dal";
import { ensureCertificates } from "@/lib/certificates/issue";
import { isCertificateTestAccount } from "@/lib/certificates/test-accounts";
import { fill } from "@/lib/instructor/format";
import { instructorOfferOpen } from "@/lib/instructor/offer";
import { getInstructorPlans } from "@/lib/instructor/plans";
import { getInstructorStatus, planOf } from "@/lib/instructor/queries";
import { createServerSupabase } from "@/lib/supabase/server";
import { cn } from "@/lib/utils";

const t = messages.learner;
const tp = t.profil;
const ti = messages.formateur;
const tl = messages.common.levels;

export const metadata: Metadata = {
  title: tp.title,
  robots: { index: false },
};

type CertificateRow = {
  id: string;
  code: string;
  level: string;
  title: string;
  issued_at: string;
};

/**
 * Ordre des niveaux tels qu'ils existent en base. Un certificat « parcours » porte
 * le niveau `parcours`, donc le maximum atteint se lit directement sur le plus haut
 * niveau certifié, sans avoir à recalculer la progression.
 */
const NIVEAUX = ["debutant", "intermediaire", "avance", "parcours", "projet"];

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(iso));
}

function formatDateCourte(iso: string | null): string {
  if (!iso) return "—";
  return new Intl.DateTimeFormat("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(iso));
}

function scopeOf(level: string): "niveau" | "parcours" {
  return level === "parcours" ? "parcours" : "niveau";
}

/** Libellé du plus haut niveau certifié ; `null` quand aucun certificat n'existe. */
function niveauAtteint(certificates: CertificateRow[]): string | null {
  let meilleur = -1;
  for (const c of certificates) {
    const rang = NIVEAUX.indexOf(c.level);
    if (rang > meilleur) meilleur = rang;
  }
  if (meilleur < 0) return null;
  const niveau = NIVEAUX[meilleur];
  // Le certificat de fin de parcours n'est pas un niveau : c'est le label final.
  if (niveau === "parcours") return tp.finalLabel;
  return tl[niveau as keyof typeof tl] ?? niveau;
}

function moisDepuis(iso: string | null): number | null {
  if (!iso) return null;
  const debut = Date.parse(iso);
  if (Number.isNaN(debut)) return null;
  return Math.max(0, Math.floor((Date.now() - debut) / (30.44 * 86_400_000)));
}

export default async function ProfilePage() {
  const user = await requireUser(links.dashboard);

  // Les certificats dus (examens réussis depuis la dernière visite) sont émis
  // avant la lecture : sinon le tout nouveau certificat n'apparaît qu'à la
  // visite suivante.
  await ensureCertificates(user.id).catch((error) => {
    console.error("[certificates] profile sync", error);
  });

  const profile = await getProfile();
  const supabase = await createServerSupabase();

  const [instructor, instructorPlans] = await Promise.all([
    getInstructorStatus(user.id),
    getInstructorPlans(),
  ]);
  const instructorPlan = planOf(instructorPlans, instructor.subscription?.planId);
  const seatsLeft = instructor.subscription
    ? Math.max(
        0,
        instructor.subscription.seatsLimit - instructor.seatsUsed,
      )
    : 0;

  // Trois lectures en base, menées en parallèle : elles alimentent les indicateurs du
  // haut de page. `chapter_progress` n'a pas de colonne `id` (la clé est le couple
  // user_id/chapter_id) : le comptage porte donc sur `chapter_id`. Une erreur de
  // lecture est affichée en console au lieu de se déguiser en « 0 ».
  const [certificats, valides, inscription] = supabase
    ? await Promise.all([
        supabase
          .from("certificates")
          .select("id,code,level,title,issued_at")
          .eq("user_id", user.id)
          .order("issued_at", { ascending: false }),
        supabase
          .from("chapter_progress")
          .select("chapter_id", { count: "exact", head: true })
          .eq("user_id", user.id)
          .eq("status", "completed"),
        supabase
          .from("profiles")
          .select("created_at")
          .eq("id", user.id)
          .maybeSingle(),
      ])
    : [
        { data: [] as CertificateRow[], error: null },
        { count: 0, error: null },
        { data: null as { created_at: string } | null, error: null },
      ];

  const certificates = (certificats.data ?? []) as CertificateRow[];
  const chapitresValides = valides.count ?? 0;
  const inscritLe = inscription.data?.created_at ?? null;
  for (const [nom, erreur] of [
    ["certificats", certificats.error],
    ["chapitres validés", valides.error],
    ["inscription", inscription.error],
  ] as const) {
    if (erreur) console.error(`[profil] ${nom}`, erreur.message);
  }

  const metadataName =
    typeof user.user_metadata?.full_name === "string"
      ? user.user_metadata.full_name.trim()
      : "";
  const name =
    metadataName ||
    (profile?.full_name ?? "").trim() ||
    (user.email ?? "");
  const email = profile?.email ?? user.email ?? "";

  const niveau = niveauAtteint(certificates);
  const mois = moisDepuis(inscritLe);

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          {tp.title}
        </h1>
        <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{tp.intro}</p>
      </header>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Kpi
          titre={tp.kpiCertificates}
          valeur={String(certificates.length)}
          note={tp.kpiCertificatesNote}
          Icon={AwardIcon}
        />
        <Kpi
          titre={tp.kpiLevel}
          valeur={niveau ?? tp.kpiLevelNone}
          Icon={TrendingUpIcon}
        />
        <Kpi
          titre={tp.kpiChapters}
          valeur={String(chapitresValides)}
          note={tp.kpiChaptersNote}
          Icon={CheckCircle2Icon}
        />
        <Kpi
          titre={tp.kpiMember}
          valeur={formatDateCourte(inscritLe)}
          note={mois === null ? undefined : tp.kpiMemberNote(mois)}
          Icon={CalendarClockIcon}
        />
      </section>

      <div className="grid grid-cols-[minmax(0,1fr)] gap-5 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)] lg:gap-6">
        <div className="flex flex-col gap-5">
          <ProfileHeader
            name={name}
            email={email}
            phone={profile?.phone ?? null}
            avatarUrl={profile?.avatar_url ?? null}
            role={profile?.role ?? "learner"}
          />

          {isCertificateTestAccount(email) ? <TestCertificateButton /> : null}

          <Carte titre={ti.eyebrow}>
            {instructor.canHost && instructor.subscription ? (
              <>
                <p className="text-sm font-semibold text-foreground">
                  {instructor.tier === "free"
                    ? ti.tier.free
                    : fill(ti.planOf, { label: instructorPlan?.label ?? "—" })}
                </p>
                <ul className="mt-2 space-y-1 text-xs leading-relaxed text-muted-foreground">
                  {instructor.subscription.expiresAt ? (
                    <li>
                      {fill(
                        instructor.tier === "free" ? ti.expiredOn : ti.expiresOn,
                        { date: formatDate(instructor.subscription.expiresAt) },
                      )}
                    </li>
                  ) : null}
                  {instructor.tier !== "free" ? (
                    <li>{fill(ti.daysLeft, { days: instructor.daysLeft })}</li>
                  ) : null}
                  <li>
                    {ti.cardSeats} : {instructor.seatsUsed} /{" "}
                    {instructor.subscription.seatsLimit}
                  </li>
                  <li>
                    {ti.cardClasses} : {instructor.classCount} ·{" "}
                    {fill(
                      instructor.tier === "free" ? ti.seatsLeftFree : ti.seatsLeft,
                      { count: seatsLeft },
                    )}
                  </li>
                </ul>
                <Button asChild className="mt-4 h-10 w-full px-4">
                  <Link href="/app/formateur">{ti.dashboardTitle}</Link>
                </Button>
              </>
            ) : (
              <>
                <p className="mt-0.5 text-sm leading-relaxed text-muted-foreground">
                  {instructorOfferOpen ? ti.benefits[0].text : ti.offer.text}
                </p>
                {instructorOfferOpen ? (
                  <Button asChild className="mt-4 h-10 w-full px-4">
                    <Link href="/app/formateur">
                      <GraduationCapIcon aria-hidden />
                      {instructor.subscription ? ti.reactivateCta : ti.cta}
                    </Link>
                  </Button>
                ) : (
                  <OfferClosedPill
                    label={ti.offer.label}
                    className="mt-4 h-10 w-full px-4"
                  />
                )}
              </>
            )}
          </Carte>

          <SecurityCard
            managedByProvider={
              typeof user.app_metadata?.provider === "string" &&
              user.app_metadata.provider !== "email"
            }
          />
        </div>

        <Carte titre={tp.certificatesTitle} intro={tp.certificatesIntro}>
          {certificates.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-hairline px-6 py-10 text-center">
              <p className="text-sm leading-relaxed text-muted-foreground">
                {tp.certificatesEmpty}
              </p>
              <Button asChild variant="outline" className="mt-4 h-10 px-4">
                <Link href={links.catalogue}>{t.tracksEmptyCta}</Link>
              </Button>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {certificates.map((certificate) => {
                const scope = scopeOf(certificate.level);
                return (
                  <article
                    key={certificate.id}
                    className="flex flex-col rounded-2xl border border-hairline bg-elevated p-5 transition-colors hover:border-electric/50"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <Badge
                        variant="secondary"
                        className={cn(
                          "shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium",
                          scope === "parcours"
                            ? "bg-electric/12 text-electric"
                            : "bg-muted text-muted-foreground",
                        )}
                      >
                        {scope === "parcours"
                          ? tp.finalLabel
                          : tl[
                              certificate.level as keyof typeof tl
                            ] ?? certificate.level}
                      </Badge>
                      <span className="text-[11px] tabular-nums text-muted-foreground">
                        {tp.issuedOn(formatDate(certificate.issued_at))}
                      </span>
                    </div>

                    <h3 className="mt-3 text-base font-semibold leading-snug text-foreground">
                      {certificate.title}
                    </h3>
                    <p className="mt-1 text-xs tabular-nums text-muted-foreground">
                      {certificate.code}
                    </p>

                    <div className="mt-4 flex flex-wrap gap-2 border-t border-hairline pt-4">
                      <Button asChild size="sm" className="h-9">
                        <a href={`/api/certificats/${certificate.code}`}>
                          {tp.download}
                        </a>
                      </Button>
                      <Button
                        asChild
                        variant="outline"
                        size="sm"
                        className="h-9 border-hairline bg-background"
                      >
                        <Link
                          href={`/verifier?code=${encodeURIComponent(certificate.code)}`}
                          target="_blank"
                        >
                          <ShieldCheckIcon className="size-4" aria-hidden />
                          {tp.verify}
                        </Link>
                      </Button>
                    </div>
                  </article>
                );
              })}
            </div>
          )}
        </Carte>
      </div>
    </div>
  );
}
