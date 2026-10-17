import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { messages } from "@/i18n";

const t = messages;

export function HowItWorks() {
  return (
    <Section id={t.how.id} className="border-y border-hairline bg-elevated">
      <SectionHeading
        eyebrow={t.how.eyebrow}
        title={t.how.title}
        description={t.how.description}
      />

      <ol className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {t.how.steps.map((step, index) => (
          <Reveal key={step.n} delay={index * 90}>
            <li className="relative h-full hover-lift rounded-2xl border border-hairline bg-card p-5">
              <span className="text-3xl font-semibold text-electric/35">{step.n}</span>
              <h3 className="mt-3 text-base font-semibold">{step.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                {step.text}
              </p>
              {index < t.how.steps.length - 1 && (
                <span
                  aria-hidden
                  className="absolute top-1/2 -right-4 hidden h-px w-4 bg-hairline lg:block"
                />
              )}
            </li>
          </Reveal>
        ))}
      </ol>
    </Section>
  );
}
