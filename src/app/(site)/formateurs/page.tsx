import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRightIcon, CheckIcon } from "lucide-react";

import { FinalCta } from "@/components/landing/final-cta";
import { Instructors } from "@/components/landing/instructors";
import { LiveClasses } from "@/components/landing/live-classes";
import { Reveal } from "@/components/reveal";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { fill, formatFc } from "@/lib/instructor/format";
import { getInstructorPlans, monthlyPriceFc } from "@/lib/instructor/plans";

const t = messages.formateur;

export const metadata: Metadata = {
  title: t.title,
  description: t.subtitle,
};

const subscribeHref = "/app/formateur/souscrire";

export default async function TrainersPage() {
  const plans = await getInstructorPlans();
  const cheapestMonthly =
    plans.length === 0
      ? null
      : Math.min(...plans.map((plan) => monthlyPriceFc(plan)));

  const facts = [
    plans[0] ? fill(t.seatsLabel, { count: plans[0].seatsLimit }) : null,
    cheapestMonthly === null ? null : `${formatFc(cheapestMonthly)} · ${t.perMonth}`,
    plans.length > 1 ? fill(t.durationsCount, { count: plans.length }) : null,
    t.benefits[1].title,
  ].filter((fact): fact is string => Boolean(fact));

  return (
    <>
      <div className="forest forest-band -mt-16 pt-16 pb-14">
        <div className="mx-auto grid w-full max-w-6xl items-center gap-10 px-4 pt-10 sm:px-6 lg:grid-cols-[1.05fr_0.95fr] lg:pt-12">
          <div>
            <Reveal>
              <p className="text-xs font-semibold tracking-[0.18em] text-electric uppercase">
                {t.eyebrow}
              </p>
            </Reveal>
            <Reveal delay={70}>
              <h1 className="mt-4 text-4xl leading-[1.06] font-bold tracking-tight text-balance sm:text-5xl">
                {t.title}
              </h1>
            </Reveal>
            <Reveal delay={130}>
              <p className="mt-5 max-w-xl text-pretty text-base leading-relaxed text-muted-foreground sm:text-lg">
                {t.subtitle}
              </p>
            </Reveal>
            <Reveal delay={190}>
              <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
                <Button asChild size="lg" className="h-12 px-6 text-base">
                  <Link href={subscribeHref}>
                    {t.cta}
                    <ArrowRightIcon className="size-4" aria-hidden />
                  </Link>
                </Button>
                <Button
                  asChild
                  variant="outline"
                  size="lg"
                  className="h-12 bg-background/40 px-6 text-base"
                >
                  <Link href={links.catalogue}>{messages.hero.secondaryCta}</Link>
                </Button>
              </div>
            </Reveal>
            <Reveal delay={250}>
              <Link
                href="/app/formateur"
                className="inline-flex items-center gap-1.5 text-sm font-medium text-electric hover:underline"
              >
                {t.spaceCta}
                <ArrowRightIcon className="size-3.5" aria-hidden />
              </Link>
            </Reveal>
          </div>

          <Reveal variant="scale" delay={160}>
            <div className="rounded-2xl border border-hairline bg-card p-6">
              <p className="text-sm font-semibold text-foreground">{t.heroFacts}</p>
              <ul className="mt-4 space-y-2.5">
                {facts.map((fact) => (
                  <li key={fact} className="flex items-center gap-2.5 text-sm text-muted-foreground">
                    <CheckIcon className="size-4 shrink-0 text-vivid" aria-hidden />
                    {fact}
                  </li>
                ))}
              </ul>
            </div>
          </Reveal>
        </div>
      </div>

      <Instructors plans={plans} subscribeHref={subscribeHref} heading={false} />
      <LiveClasses />
      <FinalCta />
    </>
  );
}
