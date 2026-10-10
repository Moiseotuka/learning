import { QuoteIcon, StarIcon } from "lucide-react";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { messages } from "@/i18n";

const t = messages;

export function Testimonials() {
  return (
    <Section>
      <SectionHeading
        eyebrow={t.testimonials.eyebrow}
        title={t.testimonials.title}
      />

      <div className="grid gap-4 sm:grid-cols-2">
        {t.testimonials.items.map((item, index) => (
          <Reveal key={item.name} delay={(index % 2) * 90}>
            <figure className="flex h-full flex-col rounded-2xl border border-hairline bg-card p-5 transition-colors hover:border-electric/40">
              <div className="flex items-center justify-between">
                <span className="flex gap-0.5" aria-label={`${item.rating} / 5`}>
                  {Array.from({ length: 5 }).map((_, star) => (
                    <StarIcon
                      key={star}
                      aria-hidden
                      className={
                        star < item.rating
                          ? "size-4 fill-amber-400 text-amber-400"
                          : "size-4 text-muted-foreground/40"
                      }
                    />
                  ))}
                </span>
                <QuoteIcon className="size-5 text-electric/40" aria-hidden />
              </div>

              <blockquote className="mt-4 flex-1 text-sm leading-relaxed text-foreground">
                « {item.quote} »
              </blockquote>

              <figcaption className="mt-5 flex items-center gap-3 border-t border-hairline pt-4">
                <span
                  className="grid size-10 shrink-0 place-items-center rounded-full bg-electric/12 text-sm font-semibold text-electric"
                  aria-hidden
                >
                  {item.initials}
                </span>
                <span>
                  <span className="block text-sm font-medium">{item.name}</span>
                  <span className="block text-xs text-muted-foreground">{item.role}</span>
                </span>
              </figcaption>
            </figure>
          </Reveal>
        ))}
      </div>
    </Section>
  );
}
