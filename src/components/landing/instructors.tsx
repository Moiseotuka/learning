import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";
import { messages } from "@/i18n";

const t = messages;

export function Instructors() {
  return (
    <Section id="formateurs">
      <SectionHeading
        eyebrow={t.instructors.eyebrow}
        title={t.instructors.title}
        description={t.instructors.description}
      />

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {t.instructors.items.map((instructor, index) => (
          <Reveal key={instructor.name} delay={index * 80}>
            <article className="h-full rounded-2xl border border-hairline bg-card p-5 transition-colors hover:border-electric/45">
              <span
                className="grid size-12 place-items-center rounded-xl bg-electric/12 text-base font-semibold text-electric"
                aria-hidden
              >
                {instructor.initials}
              </span>
              <h3 className="mt-4 text-base font-semibold">{instructor.name}</h3>
              <p className="text-sm text-muted-foreground">{instructor.role}</p>
              <p className="mt-3 rounded-lg bg-muted px-3 py-2 text-xs text-electric">
                {instructor.expertise}
              </p>
              <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                {instructor.bio}
              </p>
            </article>
          </Reveal>
        ))}
      </div>
    </Section>
  );
}
