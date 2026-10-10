import { CheckIcon, SearchIcon } from "lucide-react";
import Image from "next/image";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";

const t = messages;

export function Certificates() {
  return (
    <Section id={t.certificates.id} className="border-y border-hairline bg-elevated">
      <SectionHeading
        eyebrow={t.certificates.eyebrow}
        title={t.certificates.title}
        description={t.certificates.description}
      />

      <div className="grid items-center gap-10 lg:grid-cols-2 lg:gap-14">
        <Reveal>
          <ul className="space-y-3">
            {t.certificates.features.map((feature) => (
              <li
                key={feature}
                className="flex items-start gap-3 rounded-xl border border-hairline bg-card px-4 py-3.5"
              >
                <span
                  className="mt-0.5 grid size-5 shrink-0 place-items-center rounded-full bg-vivid/15 text-vivid"
                  aria-hidden
                >
                  <CheckIcon className="size-3" />
                </span>
                <span className="text-sm leading-relaxed text-foreground">{feature}</span>
              </li>
            ))}
          </ul>

          <form
            action="/verifier"
            method="get"
            className="mt-6 rounded-2xl border border-hairline bg-card p-5"
          >
            <label
              htmlFor="certificate-code"
              className="text-sm font-medium text-foreground"
            >
              {t.certificates.verifyLabel}
            </label>
            <div className="mt-3 flex flex-col gap-2 sm:flex-row">
              <Input
                id="certificate-code"
                name="code"
                required
                placeholder={t.certificates.verifyPlaceholder}
                className="h-11 border-hairline bg-background/70"
              />
              <Button type="submit" size="lg" className="h-11 shrink-0 px-5">
                <SearchIcon className="size-4" aria-hidden />
                {t.certificates.verifyCta}
              </Button>
            </div>
            <p className="mt-2.5 text-xs text-muted-foreground">
              {t.certificates.verifyNote}
            </p>
          </form>
        </Reveal>

        <Reveal variant="scale" delay={120}>
          <figure className="relative overflow-hidden rounded-2xl border border-hairline bg-card p-4 sm:p-6">
            <div className="overflow-hidden rounded-xl border border-hairline bg-background/60 p-3 sm:p-4">
              <Image
                src="/certificat.jpg"
                alt={t.certificates.preview.alt}
                width={1232}
                height={864}
                sizes="(min-width: 1024px) 40vw, (min-width: 640px) 60vw, calc(100vw - 5rem)"
                className="h-auto w-full rounded-lg"
              />
            </div>

            <figcaption className="mt-4 text-center text-sm text-muted-foreground">
              {t.certificates.preview.title}
            </figcaption>
          </figure>
        </Reveal>
      </div>
    </Section>
  );
}
