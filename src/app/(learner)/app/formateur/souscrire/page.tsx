import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeftIcon } from "lucide-react";

import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import {
  SubscribeForm,
  type PlanCard,
} from "@/components/instructor/subscribe-form";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import { fill, formatFc } from "@/lib/instructor/format";
import {
  getInstructorPlans,
  monthlyPriceFc,
  type InstructorPlan,
} from "@/lib/instructor/plans";
import { getInstructorStatus, getTrackOptions } from "@/lib/instructor/queries";
import { activePaymentProvider } from "@/lib/payments/nyole";

const t = messages.formateur;

export const metadata: Metadata = {
  title: t.cta,
  robots: { index: false },
};

/**
 * Les montants sont formatés côté serveur : la locale du navigateur ne doit pas
 * changer un prix engagé.
 */
function toCard(plan: InstructorPlan): PlanCard {
  return {
    id: plan.id,
    label: plan.label,
    durationDays: plan.durationDays,
    priceFc: plan.priceFc,
    priceLabel: formatFc(plan.priceFc),
    monthlyLabel: formatFc(monthlyPriceFc(plan)),
    saveLabel:
      plan.discountPct > 0 ? fill(t.discount, { pct: plan.discountPct }) : null,
    seatsLimit: plan.seatsLimit,
    trackLimit: plan.trackLimit,
    highlight: plan.highlight,
    seatsText: fill(t.seatsLabel, { count: plan.seatsLimit }),
    tracksText: fill(t.tracksLabel, { count: plan.trackLimit }),
    totalText: fill(t.total, { duration: plan.label }),
  };
}

export default async function InstructorSubscribePage({
  searchParams,
}: {
  searchParams: Promise<{ plan?: string; notice?: string }>;
}) {
  const user = await requireUser("/app/profil");
  const { plan, notice } = await searchParams;

  const [plans, tracks, status] = await Promise.all([
    getInstructorPlans(),
    getTrackOptions(),
    getInstructorStatus(user.id),
  ]);

  if (plans.length === 0 || tracks.length === 0) {
    return (
      <div className="mx-auto w-full max-w-xl px-4 py-12 sm:px-6">
        <Notice tone="error">{t.errors.failed}</Notice>
        <div className="mt-6">
          <Button asChild variant="outline" className="h-10 px-4">
            <Link href="/app/profil">
              <ArrowLeftIcon aria-hidden />
              {t.backToProfile}
            </Link>
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-8 sm:px-6 lg:py-10">
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
          {status.isActive ? t.renewCta : t.title}
        </h1>
        <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
          {t.subtitle}
        </p>

        {notice === "expire" ? (
          <div className="mt-5">
            <Notice tone="error">{t.expiredNotice}</Notice>
          </div>
        ) : null}

        <div className="mt-7">
          <SubscribeForm
            plans={plans.map(toCard)}
            tracks={tracks}
            initialPlanId={typeof plan === "string" ? plan : undefined}
            initialTrackIds={status.tracks.map((track) => track.id)}
          />
        </div>

        <p className="mt-5 text-xs leading-relaxed text-muted-foreground">
          {activePaymentProvider() === "mock"
            ? messages.payment.payMockHint
            : messages.payment.paySecureHint}
        </p>
      </div>
    </div>
  );
}
