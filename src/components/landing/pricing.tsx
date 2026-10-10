import { CheckIcon, ShieldCheckIcon } from "lucide-react";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

import Link from "next/link";

const t = messages;

export function Pricing() {
  return (
    <Section id={t.pricing.id}>
      <SectionHeading
        eyebrow={t.pricing.eyebrow}
        title={t.pricing.title}
        description={t.pricing.description}
      />

      <div className="mx-auto grid max-w-4xl gap-4 lg:grid-cols-2">
        {t.pricing.plans.map((plan, index) => (
          <Reveal key={plan.name} delay={index * 90}>
            <div
              className={cn(
                "relative flex h-full flex-col rounded-2xl border p-6",
                plan.highlighted
                  ? "border-electric bg-card shadow-lg"
                  : "border-hairline bg-card",
              )}
            >
              {plan.highlighted && (
                <span className="absolute -top-3 left-6 rounded-full bg-electric px-3 py-1 text-[11px] font-semibold text-primary-foreground">
                  {t.pricing.popularLabel}
                </span>
              )}

              <h3 className="text-base font-semibold">{plan.name}</h3>
              <p className="mt-1 text-sm text-muted-foreground">{plan.description}</p>

              <p className="mt-5 flex items-baseline gap-2">
                <span className="text-4xl font-semibold tracking-tight">{plan.price}</span>
                {plan.period && (
                  <span className="text-sm text-muted-foreground">{plan.period}</span>
                )}
              </p>

              <ul className="mt-6 flex-1 space-y-3">
                {plan.features.map((feature) => (
                  <li
                    key={feature}
                    className="flex items-start gap-2.5 text-sm text-foreground"
                  >
                    <span
                      className="mt-0.5 grid size-4.5 shrink-0 place-items-center rounded-full bg-electric/15 text-electric"
                      aria-hidden
                    >
                      <CheckIcon className="size-3" />
                    </span>
                    {feature}
                  </li>
                ))}
              </ul>

              <Button
                asChild
                size="lg"
                variant={plan.highlighted ? "default" : "outline"}
                className={cn(
                  "mt-7 h-11 w-full",
                  !plan.highlighted && "border-hairline",
                )}
              >
                <Link href={plan.href}>{plan.cta}</Link>
              </Button>

              {plan.note && (
                <p className="mt-3 text-center text-xs text-muted-foreground">
                  {plan.note}
                </p>
              )}
            </div>
          </Reveal>
        ))}
      </div>

      <Reveal delay={120}>
        <div className="mt-10 flex flex-col items-center gap-3 text-center">
          <p className="inline-flex items-center gap-2 text-sm text-muted-foreground">
            <ShieldCheckIcon className="size-4 text-vivid" aria-hidden />
            {t.pricing.guarantee}
          </p>
          <p className="text-xs tracking-wide text-muted-foreground uppercase">
            {t.pricing.paymentMethods}
          </p>
        </div>
      </Reveal>
    </Section>
  );
}
