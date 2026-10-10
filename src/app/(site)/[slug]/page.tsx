import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { Reveal } from "@/components/reveal";
import { Section } from "@/components/section";
import { Button } from "@/components/ui/button";
import { legalDocs } from "@/config/legal";
import { links } from "@/config/site";

export function generateStaticParams() {
  return legalDocs.map((doc) => ({ slug: doc.slug }));
}

export async function generateMetadata(
  props: PageProps<"/[slug]">,
): Promise<Metadata> {
  const { slug } = await props.params;
  const doc = legalDocs.find((item) => item.slug === slug);
  if (!doc) return { title: "Page introuvable" };
  return {
    title: doc.title,
    description: doc.intro,
    alternates: { canonical: `/${doc.slug}` },
  };
}

export default async function LegalPage(props: PageProps<"/[slug]">) {
  const { slug } = await props.params;
  const doc = legalDocs.find((item) => item.slug === slug);
  if (!doc) notFound();

  return (
    <Section className="py-16 sm:py-20">
      <Reveal>
        <p className="text-xs font-semibold tracking-[0.18em] text-electric uppercase">
          Informations légales
        </p>
        <h1 className="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">
          {doc.title}
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">Mise à jour : {doc.updated}</p>
        <p className="mt-6 max-w-2xl text-sm leading-relaxed text-muted-foreground">
          {doc.intro}
        </p>

        <div className="mt-10 max-w-3xl space-y-8">
          {doc.sections.map((section) => (
            <section key={section.heading}>
              <h2 className="text-base font-semibold">{section.heading}</h2>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                {section.body}
              </p>
            </section>
          ))}
        </div>

        <Button asChild variant="outline" className="mt-10 h-11 border-hairline px-5">
          <Link href={links.home}>Retour à l&apos;accueil</Link>
        </Button>
      </Reveal>
    </Section>
  );
}
