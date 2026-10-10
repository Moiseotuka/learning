import Link from "next/link";
import { ArrowRightIcon } from "lucide-react";

import { Reveal } from "@/components/reveal";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";

const t = messages;

export function FinalCta() {
  return (
    <section className="relative overflow-hidden border-t border-hairline">
      <div className="relative mx-auto w-full max-w-4xl px-4 py-20 text-center sm:px-6 lg:py-24">
        <Reveal>
          <h2 className="text-balance-tight text-3xl font-semibold tracking-tight text-balance sm:text-4xl lg:text-5xl">
            {t.cta.title}
          </h2>
          <p className="mx-auto mt-5 max-w-2xl text-pretty text-sm leading-relaxed text-muted-foreground sm:text-base">
            {t.cta.text}
          </p>

          <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <Button asChild size="lg" className="h-12 px-6 text-base">
              <Link href={links.signup}>
                {t.cta.primary}
                <ArrowRightIcon className="size-4" aria-hidden />
              </Link>
            </Button>
            <Button
              asChild
              variant="outline"
              size="lg"
              className="h-12 border-hairline bg-background/40 px-6 text-base"
            >
              <Link href={links.catalogue}>{t.cta.secondary}</Link>
            </Button>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
