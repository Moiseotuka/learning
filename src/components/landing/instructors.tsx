import {
  GraduationCapIcon,
  TicketIcon,
  UsersIcon,
  VideoIcon,
} from "lucide-react";
import Link from "next/link";

import { OfferClosedPill } from "@/components/instructor/offer-closed-pill";
import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { fill, formatFc } from "@/lib/instructor/format";
import { instructorOfferOpen } from "@/lib/instructor/offer";
import { monthlyPriceFc, type InstructorPlan } from "@/lib/instructor/plans";
import { cn } from "@/lib/utils";

const t = messages.formateur;

const benefitIcons = [UsersIcon, VideoIcon, GraduationCapIcon, TicketIcon];

export function Instructors({
  plans,
  subscribeHref = "/formateurs",
  heading = true,
  closed = !instructorOfferOpen,
}: {
  plans: InstructorPlan[];
  subscribeHref?: string;
  /** Fausse sur /formateurs, dont le bandeau d'ouverture tient déjà ce rôle. */
  heading?: boolean;
  /** Offre en attente : les appels à souscrire deviennent inertes. */
  closed?: boolean;
}) {
  return (
    <Section id={t.id} className="border-y border-hairline bg-elevated">
      {heading ? (
        <SectionHeading eyebrow={t.eyebrow} title={t.title} description={t.subtitle} />
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2">
        {t.benefits.map((benefit, index) => {
          const Icon = benefitIcons[index] ?? UsersIcon;
          return (
            <Reveal key={benefit.title} delay={index * 70}>
              <div className="h-full hover-lift rounded-2xl border border-hairline bg-card p-5">
                <span className="grid size-10 place-items-center rounded-xl bg-electric/12 text-electric">
                  <Icon className="size-5" aria-hidden />
                </span>
                <h3 className="mt-4 text-base font-semibold text-foreground">
                  {benefit.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                  {benefit.text}
                </p>
              </div>
            </Reveal>
          );
        })}
      </div>

      {plans.length === 0 ? null : (
        <div className="mt-12">
          <Reveal>
            <h3 className="text-center text-lg font-semibold tracking-tight text-balance">
              {t.plansTitle}
            </h3>
            <p className="mx-auto mt-2 max-w-2xl text-center text-sm leading-relaxed text-muted-foreground">
              {t.plansHint}
            </p>
          </Reveal>

          <Reveal delay={90}>
            <ul className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {plans.map((plan, index) => (
                <li
                  key={plan.id}
                  className={cn(
                    "relative flex h-full flex-col rounded-2xl border bg-card p-5",
                    plan.highlight
                      ? "border-electric/45 shadow-lg shadow-electric/10"
                      : "border-hairline",
                  )}
                >
                  {plan.highlight ? (
                    <span className="absolute -top-2.5 left-5 rounded-full bg-electric px-2.5 py-0.5 text-[11px] font-semibold text-primary-foreground">
                      {plan.highlight}
                    </span>
                  ) : null}

                  <p className="text-sm font-semibold text-foreground">{plan.label}</p>
                  <p className="mt-3 text-2xl font-bold tabular-nums text-foreground">
                    {formatFc(plan.priceFc)}
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground tabular-nums">
                    {formatFc(monthlyPriceFc(plan))} · {t.perMonth}
                  </p>
                  {plan.discountPct > 0 ? (
                    <span className="mt-3 inline-flex w-fit rounded-full bg-emerald-500/12 px-2.5 py-1 text-[11px] font-semibold text-emerald-600 dark:text-emerald-400">
                      {fill(t.discount, { pct: plan.discountPct })}
                    </span>
                  ) : null}

                  <ul className="mt-4 space-y-1.5 border-t border-hairline pt-4 text-xs text-muted-foreground">
                    <li>{fill(t.seatsLabel, { count: plan.seatsLimit })}</li>
                    <li>{fill(t.tracksLabel, { count: plan.trackLimit })}</li>
                    <li>{fill(t.total, { duration: plan.label })}</li>
                  </ul>

                  {closed ? (
                    <OfferClosedPill
                      label={t.offer.short}
                      className="mt-5 h-9 w-full"
                    />
                  ) : (
                    <Button
                      asChild
                      variant={index === 0 ? "default" : "outline"}
                      className="mt-5 h-9 w-full"
                    >
                      <Link href={subscribeHref}>{t.ctaShort}</Link>
                    </Button>
                  )}
                </li>
              ))}
            </ul>
          </Reveal>
        </div>
      )}

      <Reveal delay={140}>
        <div className="mt-10 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-muted-foreground">
            {closed ? t.offer.text : t.chooseTracksHint}
          </p>
          {closed ? (
            <p className="shrink-0 text-sm font-semibold text-foreground">
              {t.offer.label}
            </p>
          ) : (
            <Button asChild size="lg" className="h-11 shrink-0 px-6">
              <Link href={subscribeHref}>{t.cta}</Link>
            </Button>
          )}
        </div>
      </Reveal>
    </Section>
  );
}
