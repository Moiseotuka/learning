import {
  CalendarClockIcon,
  HandIcon,
  MessageSquareIcon,
  MicIcon,
  MonitorIcon,
  UsersIcon,
  VideoIcon,
} from "lucide-react";
import Link from "next/link";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";

const t = messages.live;

const stepIcons = [CalendarClockIcon, VideoIcon, UsersIcon];

const tiles = [
  { label: "Formateur", Icon: MicIcon, primary: true },
  { label: "Élève", Icon: VideoIcon, primary: false },
  { label: "Élève", Icon: MicIcon, primary: false },
  { label: "Élève", Icon: UsersIcon, primary: false },
];

const toolbar = [
  { label: "Micro", Icon: MicIcon },
  { label: "Caméra", Icon: VideoIcon },
  { label: "Partage d'écran", Icon: MonitorIcon },
  { label: "Chat", Icon: MessageSquareIcon },
  { label: "Lever la main", Icon: HandIcon },
];

export function LiveClasses() {
  return (
    <Section id={t.landing.id}>
      <SectionHeading eyebrow={t.eyebrow} title={t.title} description={t.subtitle} />

      <div className="grid items-start gap-10 lg:grid-cols-[0.95fr_1.05fr] lg:gap-14">
        <Reveal>
          <ol className="space-y-4">
            {t.landing.steps.map((step, index) => {
              const Icon = stepIcons[index] ?? CalendarClockIcon;
              return (
                <li
                  key={step.title}
                  className="flex gap-4 hover-lift rounded-2xl border border-hairline bg-card p-5"
                >
                  <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-electric/12 text-electric">
                    <Icon className="size-5" aria-hidden />
                  </span>
                  <div className="min-w-0">
                    <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                      {index + 1}
                    </p>
                    <h3 className="mt-0.5 text-base font-semibold text-foreground">
                      {step.title}
                    </h3>
                    <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
                      {step.text}
                    </p>
                  </div>
                </li>
              );
            })}
          </ol>
        </Reveal>

        <Reveal variant="scale" delay={120}>
          <figure className="hover-lift rounded-2xl border border-hairline bg-card p-4 shadow-sm sm:p-5">
            <div className="flex items-center justify-between gap-3">
              <p className="truncate text-sm font-semibold text-foreground">
                {t.room.title}
              </p>
              <span className="shrink-0 rounded-full bg-emerald-500/12 px-2.5 py-1 text-[11px] font-semibold text-emerald-600 dark:text-emerald-400">
                {t.eyebrow}
              </span>
            </div>

            <div className="mt-3 grid grid-cols-2 gap-2.5">
              {tiles.map((tile, index) => (
                <div
                  key={`${tile.label}-${index}`}
                  className={`relative grid aspect-video place-items-center rounded-xl border border-hairline ${
                    tile.primary ? "bg-electric/10" : "bg-elevated"
                  }`}
                >
                  <tile.Icon
                    className={`size-6 ${tile.primary ? "text-electric" : "text-muted-foreground"}`}
                    aria-hidden
                  />
                  <span className="absolute bottom-1.5 left-1.5 rounded-md bg-background/80 px-1.5 py-0.5 text-[10px] font-medium text-foreground">
                    {tile.label}
                  </span>
                </div>
              ))}
            </div>

            <div className="mt-3 flex flex-wrap items-center justify-center gap-2 border-t border-hairline pt-3.5">
              {toolbar.map((item) => (
                <span
                  key={item.label}
                  title={item.label}
                  className="inline-flex items-center gap-1.5 rounded-lg border border-hairline bg-background/60 px-2.5 py-1.5 text-[11px] font-medium text-muted-foreground"
                >
                  <item.Icon className="size-3.5" aria-hidden />
                  {item.label}
                </span>
              ))}
            </div>

            <figcaption className="mt-4 text-center text-xs leading-relaxed text-muted-foreground">
              {t.room.privacy}
            </figcaption>
          </figure>
        </Reveal>
      </div>

      <Reveal delay={160}>
        <ul className="mt-10 grid gap-3 sm:grid-cols-2">
          {t.landing.bullets.map((bullet) => (
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

      <Reveal delay={200}>
        <div className="mt-8 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
          <Button asChild size="lg" className="h-11 px-6">
            <Link href="/formateurs">{t.cta}</Link>
          </Button>
          <Button asChild variant="outline" size="lg" className="h-11 px-6">
            <Link href="/catalogue">{messages.hero.secondaryCta}</Link>
          </Button>
        </div>
      </Reveal>
    </Section>
  );
}
