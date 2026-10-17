import Link from "next/link";
import Image from "next/image";
import { ArrowRightIcon } from "lucide-react";

import { Counter } from "@/components/counter";
import { Reveal } from "@/components/reveal";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import type { CatalogNumbers } from "@/lib/catalog/queries";

const t = messages;

/**
 * Ouverture du landing, façon maquette validée : bande verte profonde, titre
 * blanc massif, CTA jaune unique, chiffres du catalogue soulignés, et à droite
 * l'apprenante (photo pleine, fond fondu dans la bande par un masque radial).
 */
export function Hero({ numbers }: { numbers: CatalogNumbers }) {
  const stats = [
    { value: numbers.tracks, label: t.stats.items.tracks },
    { value: numbers.chapters, label: t.stats.items.chapters },
    { value: numbers.lessons, label: t.stats.items.lessons },
  ].filter((stat) => stat.value > 0);

  return (
    <section className="relative overflow-hidden">
      <div
        aria-hidden
        className="anim-trame pointer-events-none absolute inset-0"
        style={{
          maskImage: "radial-gradient(ellipse 80% 60% at 50% 0%, black 40%, transparent 100%)",
          WebkitMaskImage: "radial-gradient(ellipse 80% 60% at 50% 0%, black 40%, transparent 100%)",
        }}
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2"
      >
        {/* L'anneau respire : le centrage est porté par le parent, l'animation par l'enfant,
            sinon la mise à l'échelle écraserait la translation. */}
        <div
          className="anim-halo h-[500px] w-[800px] rounded-full opacity-30 blur-3xl"
          style={{ background: "radial-gradient(ellipse, var(--electric) 0%, transparent 70%)" }}
        />
      </div>

      {/* Ondes concentriques du bas, façon maquette : des cercles fins qui
          rayonnent depuis le coin bas-droit, rognés par la section. */}
      <svg
        aria-hidden
        className="pointer-events-none absolute inset-0 h-full w-full"
        viewBox="0 0 1440 560"
        preserveAspectRatio="xMidYMax slice"
        fill="none"
      >
        {[160, 260, 360, 460, 560, 660, 760, 860, 960, 1060, 1160, 1260, 1360].map((r) => (
          <circle
            key={r}
            cx="1120"
            cy="640"
            r={r}
            stroke="#86efac"
            strokeOpacity="0.12"
            strokeWidth="1.5"
          />
        ))}
      </svg>

      <div className="relative mx-auto grid w-full max-w-6xl items-center gap-10 px-4 pt-10 pb-12 sm:px-6 lg:grid-cols-[1.08fr_0.92fr] lg:gap-6 lg:pt-14 lg:pb-14">
        <div>
          <Reveal delay={0}>
            <h1 className="text-4xl font-bold leading-[1.06] tracking-tight text-balance text-white sm:text-5xl lg:text-[3.5rem]">
              {t.hero.title1}
              <br />
              {t.hero.title2}
            </h1>
          </Reveal>

          <Reveal delay={110}>
            <p className="mt-5 max-w-lg text-sm leading-relaxed text-white/70 sm:text-base">
              {t.hero.subtitle}
            </p>
          </Reveal>

          <Reveal delay={190} className="mt-8">
            <Button
              asChild
              size="lg"
              className="group relative h-12 overflow-hidden rounded-xl bg-jaune px-8 text-base font-bold text-forest-deep shadow-xl shadow-black/30 hover:bg-jaune/85"
            >
              <Link href={links.signup}>
                <span aria-hidden className="anim-eclat pointer-events-none absolute inset-0" />
                {t.hero.primaryCta}
                <ArrowRightIcon
                  className="relative size-4 transition-transform duration-300 group-hover:translate-x-1"
                  aria-hidden
                />
              </Link>
            </Button>
          </Reveal>

          {stats.length > 0 && (
            <Reveal delay={260}>
              <dl className="mt-12 flex flex-wrap gap-x-12 gap-y-6">
                {stats.map((stat) => (
                  <div key={stat.label}>
                    <dd className="text-3xl font-bold text-white tabular-nums sm:text-4xl">
                      <Counter value={stat.value} />
                    </dd>
                    <span className="mt-2 block h-1 w-12 rounded-full bg-jaune" aria-hidden />
                    <dt className="mt-2 text-xs text-white/60">{stat.label}</dt>
                  </div>
                ))}
              </dl>
            </Reveal>
          )}
        </div>

        <Reveal variant="scale" delay={150} className="relative">
          {/* Le masque radial fond le fond vert de la photo dans la bande :
              la personne semble posée directement sur le dégradé. */}
          <figure
            className="relative mx-auto aspect-[0.92] w-full max-w-[560px]"
            style={{
              maskImage: "radial-gradient(ellipse 70% 66% at 50% 44%, black 55%, transparent 80%)",
              WebkitMaskImage:
                "radial-gradient(ellipse 70% 66% at 50% 44%, black 55%, transparent 80%)",
            }}
          >
            <Image
              src="/hero-apprenante.png"
              alt="Apprenante souriante, un ordinateur portable à la main, prête à commencer un parcours"
              fill
              priority
              sizes="(min-width: 1024px) 44vw, 100vw"
              className="object-cover object-top"
            />
          </figure>
        </Reveal>
      </div>
    </section>
  );
}
