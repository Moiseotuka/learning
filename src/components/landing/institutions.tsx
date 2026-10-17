import {
  BadgeCheckIcon,
  LandmarkIcon,
  LineChartIcon,
  PresentationIcon,
  TicketIcon,
  UsersIcon,
} from "lucide-react";
import Link from "next/link";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Button } from "@/components/ui/button";
import { contactMailto } from "@/config/contact";
import { messages } from "@/i18n";

const t = messages.institutions;

const cardIcons = [
  LandmarkIcon,
  TicketIcon,
  PresentationIcon,
  UsersIcon,
  LineChartIcon,
  BadgeCheckIcon,
];

/**
 * Le discours « établissement » ne promet que ce que la plateforme fait déjà :
 * nom d'académie sur les convocations, places partagées entre classes, cours en
 * direct avec rapport de présence et relance des absents. Rien qui n'existe pas
 * n'est annoncé — un établissement qui découvre la limite après signature le
 * vivrait comme une faute.
 */
export function Institutions() {
  const mailto = contactMailto(t.mailSubject, t.mailBody);

  return (
    <Section id={t.id} className="border-y border-hairline bg-elevated">
      <SectionHeading eyebrow={t.eyebrow} title={t.title} description={t.subtitle} />

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {t.cards.map((card, index) => {
          const Icon = cardIcons[index] ?? LandmarkIcon;
          return (
            <Reveal key={card.title} delay={index * 60}>
              <div className="h-full hover-lift rounded-2xl border border-hairline bg-card p-5">
                <span className="grid size-10 place-items-center rounded-xl bg-electric/12 text-electric">
                  <Icon className="size-5" aria-hidden />
                </span>
                <h3 className="mt-4 text-base font-semibold text-foreground">{card.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                  {card.text}
                </p>
              </div>
            </Reveal>
          );
        })}
      </div>

      <Reveal delay={120}>
        <ul className="mt-10 grid gap-3 sm:grid-cols-2">
          {t.bullets.map((bullet) => (
            <li
              key={bullet}
              className="flex items-start gap-2.5 hover-lift rounded-xl border border-hairline bg-card px-4 py-3 text-sm leading-relaxed text-foreground"
            >
              <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-electric" aria-hidden />
              {bullet}
            </li>
          ))}
        </ul>
      </Reveal>

      <Reveal delay={180}>
        <div className="mt-10 flex flex-col items-center gap-4 rounded-2xl border border-electric/30 bg-electric/[0.05] p-6 text-center">
          <p className="max-w-2xl text-sm leading-relaxed text-muted-foreground">{t.note}</p>
          <div className="flex flex-col gap-3 sm:flex-row">
            <Button asChild size="lg" className="h-11 px-6">
              <Link href={mailto}>{t.cta}</Link>
            </Button>
            <Button asChild variant="outline" size="lg" className="h-11 px-6">
              <Link href="/formateurs">{t.ctaSecondary}</Link>
            </Button>
          </div>
        </div>
      </Reveal>
    </Section>
  );
}
