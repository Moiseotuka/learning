import Link from "next/link";
import Image from "next/image";
import { ArrowRightIcon, BadgeCheckIcon, CheckIcon, LockIcon, PlayIcon, SparklesIcon } from "lucide-react";

import { Counter } from "@/components/counter";
import { Reveal } from "@/components/reveal";
import { Button } from "@/components/ui/button";
import { keyStats } from "@/config/catalog";
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
          <div className="relative mx-auto w-full max-w-[520px]">
            <div className="overflow-hidden rounded-[28px] border border-hairline bg-card/90 shadow-[0_30px_80px_rgba(11,18,32,0.28)] backdrop-blur">
              <div className="relative h-[340px] overflow-hidden">
                <Image
                  src={studyPhotos[0]}
                  alt="Étudiants qui suivent un cours en groupe"
                  fill
                  priority
                  sizes="(min-width: 1024px) 40vw, 100vw"
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-slate-950/80 via-slate-900/10 to-transparent" />

                <div className="absolute left-4 top-4 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-[11px] font-medium text-white backdrop-blur-sm">
                  Apprenants actifs
                </div>

                <div className="absolute right-4 top-4 rounded-2xl border border-white/15 bg-slate-950/60 px-3 py-2 text-left backdrop-blur-sm">
                  <p className="text-[10px] uppercase tracking-[0.18em] text-slate-300">Progression</p>
                  <p className="mt-1 text-lg font-semibold text-white">42%</p>
                </div>

                <div className="absolute inset-x-4 bottom-4 rounded-2xl border border-white/15 bg-slate-950/55 p-4 backdrop-blur-sm">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <p className="text-[11px] uppercase tracking-[0.18em] text-slate-300">{t.hero.preview.chapter}</p>
                      <p className="mt-1 text-base font-semibold text-white">{t.hero.preview.progress}</p>
                    </div>
                    <span className="rounded-full bg-emerald-400/15 px-2 py-1 text-xs font-semibold text-emerald-300">
                      +16 this week
                    </span>
                  </div>

                  <div className="mt-4 h-2.5 overflow-hidden rounded-full bg-white/10">
                    <div
                      className="h-full rounded-full bg-gradient-to-r from-electric to-vivid"
                      style={{ width: "42%" }}
                    />
                  </div>
                </div>
              </div>

              <div className="grid gap-4 border-t border-hairline bg-card/90 p-5 sm:grid-cols-[1.2fr_0.8fr]">
                <div>
                  <div className="mb-3 flex items-center justify-between">
                    <p className="text-xs text-muted-foreground">Parcours actuels</p>
                    <span className="rounded-full bg-electric/15 px-2.5 py-1 text-[10px] font-semibold text-electric">
                      LIVE
                    </span>
                  </div>

                  <ul className="space-y-3">
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
                        {index === 1 && (
                          <span className="text-[10px] text-vivid">{t.hero.preview.video}</span>
                        )}
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="space-y-3">
                  <div className="rounded-2xl border border-hairline bg-background/60 p-3">
                    <div className="flex -space-x-2">
                      {studyPhotos.map((photo, index) => (
                        <div
                          key={photo}
                          className="relative h-10 w-10 overflow-hidden rounded-full border-2 border-card bg-muted"
                          style={{ zIndex: 10 - index }}
                        >
                          <Image
                            src={photo}
                            alt={`Étudiant ${index + 1}`}
                            fill
                            sizes="40px"
                            className="object-cover"
                          />
                        </div>
                      ))}
                    </div>
                    <p className="mt-3 text-xs text-muted-foreground">+380 apprenants actifs</p>
                    <p className="mt-1 text-lg font-semibold text-foreground">4.8/5</p>
                  </div>

                  <div className="rounded-2xl border border-hairline bg-emerald-500/10 p-3">
                    <p className="text-[10px] uppercase tracking-[0.18em] text-emerald-500">Certification</p>
                    <p className="mt-2 text-xl font-bold text-foreground">{t.hero.preview.certValue}</p>
                    <div className="mt-2 flex items-center gap-2 text-xs text-emerald-600">
                      <BadgeCheckIcon className="size-3.5" aria-hidden />
                      {t.hero.preview.score}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="absolute -top-5 -left-4 hidden rounded-xl border border-hairline bg-card px-3.5 py-2.5 text-xs shadow-lg sm:block">
              <span className="text-muted-foreground">{t.hero.preview.projectLabel}</span>
              <p className="font-semibold">{t.hero.preview.projectValue}</p>
            </div>
            <div
              className="absolute -right-4 -bottom-5 hidden rounded-xl border border-hairline bg-card px-3.5 py-2.5 text-xs shadow-lg sm:block"
            >
              <span className="text-muted-foreground">{t.hero.preview.certLabel}</span>
              <p className="font-semibold">{t.hero.preview.certValue}</p>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
