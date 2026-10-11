import Image from "next/image";
import { QuoteIcon, StarIcon } from "lucide-react";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { messages } from "@/i18n";

const t = messages;

const studentPortraits = [
  "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=500&q=80",
  "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=500&q=80",
  "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=500&q=80",
  "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=500&q=80",
];

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
                <div className="relative h-12 w-12 overflow-hidden rounded-full border border-hairline bg-muted">
                  <Image
                    src={studentPortraits[index % studentPortraits.length]}
                    alt={item.name}
                    fill
                    sizes="48px"
                    className="object-cover"
                  />
                </div>
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
