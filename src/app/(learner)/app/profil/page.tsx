import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowLeftIcon,
  DownloadIcon,
  GraduationCapIcon,
  ShieldCheckIcon,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ProfileHeader } from "@/components/learner/profile-header";
import { TestCertificateButton } from "@/components/learner/test-certificate-button";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { getProfile, requireUser } from "@/lib/auth/dal";
import { ensureCertificates } from "@/lib/certificates/issue";
import { isCertificateTestAccount } from "@/lib/certificates/test-accounts";
import { fill } from "@/lib/instructor/format";
import { getInstructorPlans } from "@/lib/instructor/plans";
import { getInstructorStatus, planOf } from "@/lib/instructor/queries";
import { createServerSupabase } from "@/lib/supabase/server";
import { cn } from "cn";

const t = messages.learner;
const ti = messages.formateur;

export const metadata: Metadata = {
  title: t.profil.title,
  robots: { index: false },
};

type CertificateRow = {
  id: string;
  code: string;
  level: string;
  title: string;
  issued_at: string;
};

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(iso));
}

function scopeOf(level: string): "niveau" | "parcours" {
  return level === "parcours" ? "parcours" : "niveau";
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

  const { data: certificateRows } = supabase
    ? await supabase
        .from("certificates")
        .select("id,code,level,title,issued_at")
        .eq("user_id", user.id)
        .order("issued_at", { ascending: false })
    : { data: [] as CertificateRow[] };

  const certificates = (certificateRows ?? []) as CertificateRow[];

  const metadataName =
    typeof user.user_metadata?.full_name === "string"
      ? user.user_metadata.full_name.trim()
      : "";
  const name =
    metadataName ||
    (profile?.full_name ?? "").trim() ||
    (user.email ?? "");
  const email = profile?.email ?? user.email ?? "";

  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:py-10">
      <Button
        asChild
        variant="ghost"
        className="-ml-2 mb-4 h-8 px-2 text-xs text-muted-foreground"
      >
        <Link href={links.dashboard}>
          <ArrowLeftIcon aria-hidden />
          {t.profil.backToDashboard}
        </Link>
      </Button>

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

          <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm">
            <p className="flex items-center gap-2 text-xs font-semibold tracking-wider text-electric uppercase">
              <GraduationCapIcon className="size-4" aria-hidden />
              {ti.dashboardTitle}
            </p>

            {instructor.isActive && instructor.subscription ? (
              <>
                <p className="mt-3 text-sm font-semibold text-foreground">
                  {fill(ti.planOf, { label: instructorPlan?.label ?? "—" })}
                </p>
                <ul className="mt-2 space-y-1 text-xs leading-relaxed text-muted-foreground">
                  <li>
                    {instructor.subscription.expiresAt
                      ? `${fill(ti.expiresOn, {
                          date: formatDate(instructor.subscription.expiresAt),
                        })} · `
                      : ""}
                    {fill(ti.daysLeft, { days: instructor.daysLeft })}
                  </li>
                  <li>
                    {ti.cardSeats} : {instructor.seatsUsed} /{" "}
                    {instructor.subscription.seatsLimit}
                  </li>
                  <li>
                    {ti.cardClasses} : {instructor.classCount} ·{" "}
                    {fill(ti.seatsLeft, { count: seatsLeft })}
                  </li>
                </ul>
                <Button asChild className="mt-4 h-10 w-full px-4">
                  <Link href="/app/formateur">{ti.dashboardTitle}</Link>
                </Button>
              </>
            ) : (
              <>
                <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                  {ti.benefits[0].text}
                </p>
                <Button asChild className="mt-4 h-10 w-full px-4">
                  <Link href="/app/formateur">
                    <GraduationCapIcon aria-hidden />
                    {instructor.subscription ? ti.reactivateCta : ti.cta}
                  </Link>
                </Button>
              </>
            )}
          </section>
        </div>

        <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
          <div className="flex items-center gap-3">
            <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              {t.profil.certificatesTitle}
            </h2>
            <span className="h-px flex-1 bg-hairline" />
            <span className="text-xs tabular-nums text-muted-foreground">
              {certificates.length}
            </span>
          </div>

          <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
            {t.profil.certificatesIntro}
          </p>

          {certificates.length === 0 ? (
            <div className="mt-4 rounded-2xl border border-dashed border-hairline bg-card/50 px-6 py-10 text-center">
              <p className="text-sm leading-relaxed text-muted-foreground">
                {t.profil.certificatesEmpty}
              </p>
            </div>
          ) : (
            <div className="mt-4 grid gap-4 sm:grid-cols-2">
              {certificates.map((certificate) => {
                const scope = scopeOf(certificate.level);
                return (
                  <article
                    key={certificate.id}
                    className="flex flex-col rounded-2xl border border-hairline bg-card p-5 transition-colors hover:border-electric/50"
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
                          ? t.profil.finalLabel
                          : messages.common.levels[
                              certificate.level as keyof typeof messages.common.levels
                            ] ?? certificate.level}
                      </Badge>
                      <span className="text-[11px] tabular-nums text-muted-foreground">
                        {t.profil.issuedOn(formatDate(certificate.issued_at))}
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
                          <DownloadIcon className="size-4" aria-hidden />
                          {t.profil.download}
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
                          {t.profil.verify}
                        </Link>
                      </Button>
                    </div>
                  </article>
                );
              })}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
