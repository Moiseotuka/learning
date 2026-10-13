import Link from "next/link";
import Image from "next/image";
import {
  ArrowRightIcon,
  BadgeCheckIcon,
  CheckIcon,
  LockIcon,
  PlayIcon,
  ShieldCheckIcon,
  SparklesIcon,
} from "lucide-react";

import { CatalogSearchForm } from "@/components/catalog/catalog-search-form";
import { Reveal } from "@/components/reveal";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";

const t = messages;

const studyPhotos = [
  "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=900&q=80",
];

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

      <div className="relative mx-auto grid w-full max-w-6xl items-center gap-12 px-4 pt-10 pb-12 sm:px-6 lg:grid-cols-[1.05fr_0.95fr] lg:gap-16 lg:pt-12 lg:pb-14">
        <div>
          <Reveal delay={0}>
            <div className="inline-flex items-center gap-2 rounded-full border border-hairline bg-card/80 px-3.5 py-1.5 text-xs font-medium text-muted-foreground backdrop-blur">
              <SparklesIcon className="size-3.5 text-electric" aria-hidden />
              100 % en français, du premier cours à la validation du niveau
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

          <Reveal delay={150}>
            <p className="mt-6 max-w-xl text-pretty text-base leading-relaxed text-muted-foreground sm:text-lg">
              {t.hero.subtitle}
            </p>
          </Reveal>

          <Reveal delay={220} className="mt-8">
            <CatalogSearchForm variant="hero" />
          </Reveal>

          <Reveal delay={290}>
            <div className="mt-7 flex flex-col gap-3 sm:flex-row sm:items-center">
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

          <Reveal delay={360}>
            <ul className="mt-5 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs text-muted-foreground">
              {[
                "Sans carte bancaire",
                "Mobile Money accepté",
                "Accès immédiat au premier niveau",
              ].map((item) => (
                <li key={item} className="inline-flex items-center gap-1.5">
                  <CheckIcon className="size-3.5 text-vivid" aria-hidden />
                  {item}
                </li>
              ))}
            </ul>
          </Reveal>
        </div>

        <Reveal variant="scale" delay={200} className="relative">
          <figure className="relative mx-auto w-full max-w-[520px]">
            <div className="overflow-hidden rounded-[28px] border border-hairline bg-card shadow-[0_30px_80px_rgba(2,20,12,0.5)] backdrop-blur">
              <div className="relative h-[300px] overflow-hidden">
                <Image
                  src={studyPhotos[0]}
                  alt="Apprenants qui suivent un cours en groupe"
                  fill
                  priority
                  sizes="(min-width: 1024px) 40vw, 100vw"
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-slate-950/85 via-slate-900/25 to-transparent" />

                <div className="absolute inset-x-4 bottom-4 rounded-2xl border border-white/15 bg-slate-950/60 p-4 backdrop-blur-sm">
                  <p className="text-[11px] uppercase tracking-[0.18em] text-slate-300">
                    {t.hero.preview.chapter}
                  </p>
                  <p className="mt-1 text-base font-semibold text-white">
                    {t.hero.preview.progress}
                  </p>
                  <div className="mt-3 flex items-center justify-between gap-3">
                    <div className="h-2.5 flex-1 overflow-hidden rounded-full bg-white/10">
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-electric to-vivid"
                        style={{ width: "75%" }}
                      />
                    </div>
                    <span className="shrink-0 rounded-full bg-emerald-400/15 px-2 py-1 text-[11px] font-semibold text-emerald-300">
                      {t.hero.preview.video}
                    </span>
                  </div>
                </div>
              </div>

              <div className="grid gap-4 border-t border-hairline p-5 sm:grid-cols-[1.15fr_0.85fr]">
                <div>
                  <p className="mb-3 text-xs text-muted-foreground">
                    {t.hero.preview.pathTitle}
                  </p>
                  <ul className="space-y-2.5">
                    {t.hero.preview.levels.map((level, index) => (
                      <li
                        key={level}
                        className="flex items-center gap-3 rounded-xl border border-hairline bg-elevated px-3 py-2.5"
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
                        <span className={`flex-1 text-sm ${index > 1 ? "text-muted-foreground" : "text-foreground"}`}>
                          {level}
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="flex flex-col gap-3">
                  <div className="rounded-2xl border border-hairline bg-emerald-500/10 p-3.5">
                    <p className="flex items-center gap-1.5 text-[10px] uppercase tracking-[0.18em] text-emerald-600 dark:text-emerald-400">
                      <BadgeCheckIcon className="size-3.5" aria-hidden />
                      {t.hero.preview.certLabel}
                    </p>
                    <p className="mt-2 font-mono text-sm font-semibold text-foreground">
                      {t.hero.preview.certValue}
                    </p>
                    <p className="mt-1 text-[11px] leading-relaxed text-muted-foreground">
                      {t.hero.preview.score}
                    </p>
                  </div>

                  <Link
                    href={links.verify}
                    className="mt-auto inline-flex items-center gap-1.5 rounded-xl border border-hairline bg-background/60 px-3 py-2.5 text-xs font-medium text-muted-foreground transition-colors hover:border-electric/50 hover:text-foreground"
                  >
                    <ShieldCheckIcon className="size-3.5 text-electric" aria-hidden />
                    {t.certificates.verifyLabel}
                    <ArrowRightIcon className="size-3.5" aria-hidden />
                  </Link>
                </div>
              </div>
            </div>

            <figcaption className="mt-3 text-center text-xs text-muted-foreground">
              {t.hero.preview.caption}
            </figcaption>
          </figure>
        </Reveal>
      </div>
    </section>
  );
}
