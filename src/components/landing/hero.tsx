import Link from "next/link";
import { ArrowRightIcon, BadgeCheckIcon, CheckIcon, LockIcon, PlayIcon, SparklesIcon } from "lucide-react";

import { Counter } from "@/components/counter";
import { Reveal } from "@/components/reveal";
import { Button } from "@/components/ui/button";
import { keyStats } from "@/config/catalog";
import { links } from "@/config/site";
import { messages } from "@/i18n";

const t = messages;

export function Hero() {
  return (
    <section className="relative overflow-hidden">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{
          backgroundImage:
            "linear-gradient(var(--hairline) 1px, transparent 1px), linear-gradient(90deg, var(--hairline) 1px, transparent 1px)",
          backgroundSize: "56px 56px",
          maskImage: "radial-gradient(ellipse 80% 60% at 50% 0%, black 40%, transparent 100%)",
          WebkitMaskImage: "radial-gradient(ellipse 80% 60% at 50% 0%, black 40%, transparent 100%)",
        }}
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -top-40 left-1/2 h-[500px] w-[800px] -translate-x-1/2 rounded-full opacity-30 blur-3xl"
        style={{ background: "radial-gradient(ellipse, var(--electric) 0%, transparent 70%)" }}
      />

      <div className="relative mx-auto grid w-full max-w-6xl items-center gap-12 px-4 pt-14 pb-16 sm:px-6 lg:grid-cols-[1.05fr_0.95fr] lg:gap-16 lg:pt-24 lg:pb-24">
        <div>
          <Reveal delay={0}>
            <div className="inline-flex items-center gap-2 rounded-full border border-hairline bg-card/80 px-3.5 py-1.5 text-xs font-medium text-muted-foreground backdrop-blur">
              <SparklesIcon className="size-3.5 text-electric" aria-hidden />
              Plateforme n°1 en Afrique francophone
            </div>
          </Reveal>

          <Reveal delay={80}>
            <h1 className="mt-5 text-4xl leading-[1.05] font-bold tracking-tight text-balance sm:text-5xl lg:text-6xl">
              {t.hero.title1}
              <br />
              <span className="bg-gradient-to-r from-electric via-vivid to-electric bg-clip-text text-transparent">
                {t.hero.title2}
              </span>
            </h1>
          </Reveal>

          <Reveal delay={160}>
            <p className="mt-6 max-w-xl text-pretty text-base leading-relaxed text-muted-foreground sm:text-lg">
              {t.hero.subtitle}
            </p>
          </Reveal>

          <Reveal delay={240}>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
              <Button asChild size="lg" className="h-12 px-6 text-base shadow-lg shadow-electric/25">
                <Link href={links.signup}>
                  {t.hero.primaryCta}
                  <ArrowRightIcon className="size-4" aria-hidden />
                </Link>
              </Button>
              <Button
                asChild
                variant="outline"
                size="lg"
                className="h-12 border-hairline bg-card/60 px-6 text-base backdrop-blur"
              >
                <Link href={links.catalogue}>{t.hero.secondaryCta}</Link>
              </Button>
            </div>
          </Reveal>

          <Reveal delay={320}>
            <div className="mt-5 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs text-muted-foreground">
              <span className="inline-flex items-center gap-1.5">
                <CheckIcon className="size-3.5 text-emerald-500" aria-hidden />
                Sans carte bancaire
              </span>
              <span className="inline-flex items-center gap-1.5">
                <CheckIcon className="size-3.5 text-emerald-500" aria-hidden />
                Mobile Money accepté
              </span>
              <span className="inline-flex items-center gap-1.5">
                <CheckIcon className="size-3.5 text-emerald-500" aria-hidden />
                Accès immédiat
              </span>
            </div>
          </Reveal>

          <Reveal delay={400}>
            <dl className="mt-10 grid grid-cols-2 gap-x-6 gap-y-6 border-t border-hairline pt-8 sm:grid-cols-4">
              {keyStats.map((stat) => (
                <div key={stat.label}>
                  <dd className="text-2xl font-bold text-foreground sm:text-3xl">
                    <Counter value={stat.value} suffix={stat.suffix} />
                  </dd>
                  <dt className="mt-1 text-xs leading-snug text-muted-foreground">
                    {stat.label}
                  </dt>
                </div>
              ))}
            </dl>
          </Reveal>
        </div>

        <Reveal variant="scale" delay={200} className="relative">
          <div className="relative rounded-2xl border border-hairline bg-card/90 p-5 shadow-2xl shadow-electric/10 backdrop-blur sm:p-6">
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="text-xs text-muted-foreground">{t.hero.preview.chapter}</p>
                <p className="mt-1 text-base font-semibold">{t.hero.preview.progress}</p>
              </div>
              <span className="rounded-full bg-electric/15 px-2.5 py-1 text-xs font-semibold text-electric">
                42 %
              </span>
            </div>

            <div className="mt-4 h-2 overflow-hidden rounded-full bg-muted">
              <div
                className="h-full rounded-full bg-gradient-to-r from-electric to-vivid"
                style={{ width: "42%" }}
              />
            </div>

            <ul className="mt-6 space-y-3">
              {t.hero.preview.levels.map((level, index) => (
                <li
                  key={level}
                  className="flex items-center gap-3 rounded-lg border border-hairline bg-elevated px-3.5 py-3"
                >
                  <span
                    className={`grid size-6 shrink-0 place-items-center rounded-full ${
                      index === 0
                        ? "bg-emerald-500/15 text-emerald-500"
                        : index === 1
                          ? "bg-electric/15 text-electric"
                          : "bg-muted text-muted-foreground"
                    }`}
                    aria-hidden
                  >
                    {index === 0 ? (
                      <CheckIcon className="size-3.5" />
                    ) : index === 1 ? (
                      <PlayIcon className="size-3.5" />
                    ) : (
                      <LockIcon className="size-3.5" />
                    )}
                  </span>
                  <span
                    className={`flex-1 text-sm ${index > 1 ? "text-muted-foreground" : "text-foreground"}`}
                  >
                    {level}
                  </span>
                  {index === 1 && (
                    <span className="text-xs text-vivid">{t.hero.preview.video}</span>
                  )}
                </li>
              ))}
            </ul>

            <div className="mt-5 flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/12 px-3 py-1.5 text-xs font-medium text-emerald-500">
                <BadgeCheckIcon className="size-3.5" aria-hidden />
                {t.hero.preview.score}
              </span>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-hairline px-3 py-1.5 text-xs text-muted-foreground">
                {t.hero.preview.streak}
              </span>
            </div>
          </div>

          <div className="absolute -top-5 -left-4 hidden rounded-xl border border-hairline bg-card px-3.5 py-2.5 text-xs shadow-lg sm:block">
            <span className="text-muted-foreground">{t.hero.preview.projectLabel}</span>
            <p className="font-semibold">{t.hero.preview.projectValue}</p>
          </div>
          <div
            className="absolute -right-4 -bottom-5 hidden rounded-xl border border-hairline bg-card px-3.5 py-2.5 text-xs shadow-lg sm:block"
            style={{ animationDelay: "1.4s" }}
          >
            <span className="text-muted-foreground">{t.hero.preview.certLabel}</span>
            <p className="font-semibold">{t.hero.preview.certValue}</p>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
