import Link from "next/link";
import { MessagesSquareIcon, UsersIcon, VideoIcon } from "lucide-react";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";

const t = messages;

const channelIcons = [MessagesSquareIcon, UsersIcon, VideoIcon];

export function Community() {
  return (
    <Section id={t.community.id} className="border-y border-hairline bg-elevated">
      <SectionHeading
        eyebrow={t.community.eyebrow}
        title={t.community.title}
        description={t.community.description}
      />

      <div className="grid gap-4 sm:grid-cols-3">
        {t.community.channels.map((channel, index) => {
          const Icon = channelIcons[index] ?? UsersIcon;
          return (
            <Reveal key={channel.name} delay={index * 90}>
              <div className="h-full rounded-2xl border border-hairline bg-card p-5">
                <span
                  className="grid size-10 place-items-center rounded-lg bg-electric/12 text-electric"
                  aria-hidden
                >
                  <Icon className="size-5" />
                </span>
                <h3 className="mt-4 text-base font-semibold">{channel.name}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                  {channel.text}
                </p>
              </div>
            </Reveal>
          );
        })}
      </div>

      <Reveal delay={140}>
        <div className="mt-8 flex flex-col items-center justify-between gap-6 rounded-2xl border border-hairline bg-card p-6 sm:flex-row">
          <dl className="grid grid-cols-3 gap-6 text-center sm:text-start">
            {t.community.stats.map((stat) => (
              <div key={stat.label}>
                <dd className="text-xl font-semibold text-electric sm:text-2xl">
                  {stat.value}
                </dd>
                <dt className="mt-1 text-xs text-muted-foreground">{stat.label}</dt>
              </div>
            ))}
          </dl>

          <Button asChild size="lg" className="h-11 shrink-0 px-6">
            <Link href={links.signup}>{t.community.cta}</Link>
          </Button>
        </div>
      </Reveal>
    </Section>
  );
}
