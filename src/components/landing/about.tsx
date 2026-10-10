import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { messages } from "@/i18n";

const t = messages;

export function About() {
  return (
    <Section id={t.about.id}>
      <div className="grid items-start gap-10 lg:grid-cols-2 lg:gap-16">
        <Reveal>
          <SectionHeading
            eyebrow={t.about.eyebrow}
            title={t.about.title}
            description={t.about.description}
            align="left"
            className="mb-0"
          />
        </Reveal>

        <div className="grid gap-4 sm:grid-cols-2">
          {t.about.points.map((point, index) => (
            <Reveal key={point.title} delay={index * 80}>
              <div className="h-full rounded-2xl border border-hairline bg-card p-5">
                <span
                  className="mb-3 block h-1 w-8 rounded-full bg-electric"
                  aria-hidden
                />
                <h3 className="text-sm font-semibold">{point.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                  {point.text}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </Section>
  );
}
