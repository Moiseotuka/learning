import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowRightIcon,
  BadgeCheckIcon,
  GraduationCapIcon,
  SmartphoneIcon,
  WalletIcon,
} from "lucide-react";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import {
  JsonLd,
  breadcrumbLd,
  faqLd,
  itemListLd,
} from "@/components/seo/json-ld";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { getCatalogNumbers } from "@/lib/catalog/queries";
import { getSeoTracks } from "@/lib/catalog/seo";

const t = messages.afrique;

/** Quatre icônes, quatre arguments : l'ordre de `t.why` est celui de la promesse. */
const whyIcons = [GraduationCapIcon, WalletIcon, SmartphoneIcon, BadgeCheckIcon];

/** Affiché en dur dans le titre : c'est la requête que la page doit gagner. */
const metaTitle = "Formation informatique en ligne en Afrique francophone";

const metaDescription =
  "Parcours d'informatique en français, du niveau débutant à l'avancé : leçons sur téléphone, paiement Mobile Money en francs congolais, quiz corrigés et certificat vérifiable par code public.";

const keywords = [
  "formation informatique en afrique",
  "apprendre à coder en afrique",
  "cours en ligne afrique francophone",
  "formation développeur web afrique",
  "apprendre python en français",
  "formation cybersécurité en français",
  "certification informatique en ligne afrique",
  "payer une formation par mobile money",
];

export const metadata: Metadata = {
  // Le gabarit global ajoute déjà « · easyTech » : l'écrire ici le dupliquerait.
  title: metaTitle,
  description: metaDescription,
  keywords,
  alternates: { canonical: "/formation-informatique-afrique" },
};

const numberFormat = new Intl.NumberFormat("fr-FR");

export default async function AfriquePage() {
  const [numbers, tracks] = await Promise.all([
    getCatalogNumbers(),
    getSeoTracks(),
  ]);

  const stats = [
    { value: numbers.tracks, label: t.stats.tracks },
    { value: numbers.chapters, label: t.stats.chapters },
    { value: numbers.lessons, label: t.stats.lessons },
    { value: numbers.categories, label: t.stats.categories },
  ];

  const picked = tracks.slice(0, 12);

  return (
    <>
      <JsonLd
        data={[
          breadcrumbLd([
            { name: "Accueil", path: "/" },
            { name: t.eyebrow, path: "/formation-informatique-afrique" },
          ]),
          itemListLd(
            picked.map((track) => ({
              name: track.title,
              path: `/parcours/${track.slug}`,
              description: track.description,
            })),
            t.tracksTitle,
          ),
          faqLd(t.faq),
        ]}
      />

      <div className="forest forest-band -mt-16 pt-16 pb-14">
        <div className="mx-auto w-full max-w-4xl px-4 pt-10 text-center sm:px-6 lg:pt-12">
          <Reveal>
            <p className="text-xs font-semibold tracking-[0.18em] text-electric uppercase">
              {t.eyebrow}
            </p>
            <h1 className="mt-4 text-4xl leading-[1.06] font-bold tracking-tight text-balance sm:text-5xl">
              {t.title}
            </h1>
            <p className="mx-auto mt-5 max-w-2xl text-pretty text-base leading-relaxed text-muted-foreground sm:text-lg">
              {t.subtitle}
            </p>
          </Reveal>

          <Reveal delay={140}>
            <div className="mt-8 flex flex-col justify-center gap-3 sm:flex-row">
              <Button asChild size="lg" className="h-12 px-6 text-base">
                <Link href={links.catalogue}>
                  {t.ctaPrimary}
                  <ArrowRightIcon className="size-4" aria-hidden />
                </Link>
              </Button>
              <Button
                asChild
                variant="outline"
                size="lg"
                className="h-12 bg-background/40 px-6 text-base"
              >
                <Link href={links.signup}>{t.ctaSecondary}</Link>
              </Button>
            </div>
          </Reveal>

          <Reveal variant="scale" delay={210}>
            <dl className="mx-auto mt-10 grid max-w-3xl grid-cols-2 gap-px overflow-hidden rounded-2xl border border-hairline bg-hairline/60 sm:grid-cols-4">
              {stats.map((stat) => (
                <div key={stat.label} className="bg-card px-4 py-5">
                  <dd className="text-2xl font-bold tabular-nums text-foreground">
                    {numberFormat.format(stat.value)}
                  </dd>
                  <dt className="mt-1 text-xs leading-snug text-muted-foreground">
                    {stat.label}
                  </dt>
                </div>
              ))}
            </dl>
            <p className="mt-3 text-xs text-muted-foreground">{t.statsIntro}</p>
          </Reveal>
        </div>
      </div>

      <Section>
        <SectionHeading
          eyebrow={t.whyEyebrow}
          title={t.whyTitle}
          description={t.tracksCountLabel(stats[0].value)}
        />

        <div className="grid gap-4 sm:grid-cols-2">
          {t.why.map((point, index) => {
            const Icon = whyIcons[index] ?? GraduationCapIcon;
            return (
              <Reveal key={point.title} delay={index * 70}>
                <div className="h-full rounded-2xl border border-hairline bg-card p-5">
                  <span className="grid size-10 place-items-center rounded-xl bg-electric/12 text-electric">
                    <Icon className="size-5" aria-hidden />
                  </span>
                  <h3 className="mt-4 text-base font-semibold text-foreground">
                    {point.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                    {point.text}
                  </p>
                </div>
              </Reveal>
            );
          })}
        </div>
      </Section>

      <Section className="border-y border-hairline bg-elevated">
        <SectionHeading
          eyebrow={t.tracksEyebrow}
          title={t.tracksTitle}
          description={t.tracksIntro}
        />

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {picked.map((track, index) => (
            <Reveal key={track.slug} delay={(index % 3) * 70}>
              <Link
                href={`/parcours/${track.slug}`}
                className="flex h-full flex-col rounded-2xl border border-hairline bg-card p-5 transition-colors hover:border-electric/50"
              >
                <p className="text-xs font-semibold tracking-wider text-electric uppercase">
                  {track.category}
                </p>
                <h3 className="mt-2 text-base font-semibold text-balance text-foreground">
                  {track.title}
                </h3>
                <p className="mt-2 line-clamp-3 text-sm leading-relaxed text-muted-foreground">
                  {track.description}
                </p>
                <p className="mt-auto pt-4 text-xs text-muted-foreground tabular-nums">
                  {track.modules} chapitres · {track.durationHours} h
                </p>
              </Link>
            </Reveal>
          ))}
        </div>

        <div className="mt-8 text-center">
          <Button asChild variant="outline" size="lg" className="h-11 px-6">
            <Link href={links.catalogue}>
              {t.tracksMore}
              <ArrowRightIcon className="size-4" aria-hidden />
            </Link>
          </Button>
        </div>
      </Section>

      <Section>
        <div className="grid items-start gap-8 lg:grid-cols-[0.9fr_1.1fr]">
          <SectionHeading
            align="left"
            eyebrow={t.priceEyebrow}
            title={t.priceTitle}
            className="mb-0"
          />
          <div>
            <ul className="space-y-3">
              {t.pricePoints.map((point) => (
                <li
                  key={point}
                  className="flex gap-2.5 text-sm leading-relaxed text-muted-foreground"
                >
                  <BadgeCheckIcon
                    className="mt-0.5 size-4 shrink-0 text-vivid"
                    aria-hidden
                  />
                  {point}
                </li>
              ))}
            </ul>
            <p className="mt-4 text-xs leading-relaxed text-muted-foreground">
              {t.priceNote}
            </p>
            <div className="mt-6">
              <Button asChild className="h-10 px-5">
                <Link href={links.catalogue}>{t.priceCta}</Link>
              </Button>
            </div>
          </div>
        </div>
      </Section>

      <Section id={t.id} className="border-t border-hairline bg-elevated">
        <SectionHeading title={t.faqTitle} />
        <div className="mx-auto max-w-3xl divide-y divide-hairline rounded-2xl border border-hairline bg-card px-5">
          {t.faq.map((item) => (
            <details key={item.q} className="group py-4">
              <summary className="flex cursor-pointer list-none items-center justify-between gap-4 text-sm font-semibold text-foreground marker:content-none">
                {item.q}
                <ArrowRightIcon
                  className="size-4 shrink-0 text-muted-foreground transition-transform group-open:rotate-90"
                  aria-hidden
                />
              </summary>
              <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                {item.a}
              </p>
            </details>
          ))}
        </div>
      </Section>

      <Section className="text-center">
        <Reveal>
          <h2 className="mx-auto max-w-2xl text-2xl font-semibold tracking-tight text-balance sm:text-3xl">
            {t.finalTitle}
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-sm leading-relaxed text-muted-foreground sm:text-base">
            {t.finalText}
          </p>
          <div className="mt-8 flex flex-col justify-center gap-3 sm:flex-row">
            <Button asChild size="lg" className="h-12 px-6 text-base">
              <Link href={links.signup}>{t.finalCta}</Link>
            </Button>
            <Button
              asChild
              variant="outline"
              size="lg"
              className="h-12 px-6 text-base"
            >
              <Link href={links.catalogue}>{t.finalSecondary}</Link>
            </Button>
          </div>
        </Reveal>
      </Section>
    </>
  );
}
