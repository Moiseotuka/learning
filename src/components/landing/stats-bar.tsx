import { Reveal } from "@/components/reveal";
import { Counter } from "@/components/counter";
import { messages } from "@/i18n";
import type { CatalogNumbers } from "@/lib/catalog/queries";

const t = messages.stats;

export function StatsBar({ numbers }: { numbers: CatalogNumbers }) {
  const items = [
    { value: numbers.tracks, label: t.items.tracks },
    { value: numbers.chapters, label: t.items.chapters },
    { value: numbers.lessons, label: t.items.lessons },
    { value: numbers.categories, label: t.items.categories },
  ].filter((item) => item.value > 0);

  return (
    <section className="border-t border-hairline py-10 lg:py-12">
      <div className="mx-auto w-full max-w-6xl px-4 sm:px-6">
        <Reveal>
          <p className="text-center text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {t.eyebrow}
          </p>
        </Reveal>

        <Reveal delay={100}>
          <dl className="mt-6 grid grid-cols-2 gap-6 sm:grid-cols-4">
            {items.map((item) => (
              <div key={item.label} className="text-center">
                <dd className="text-3xl font-bold text-foreground tabular-nums sm:text-4xl">
                  <Counter value={item.value} />
                </dd>
                <span
                  className="mx-auto mt-2.5 block h-0.5 w-9 rounded-full bg-electric"
                  aria-hidden
                />
                <dt className="mt-2.5 text-xs text-muted-foreground">
                  {item.label}
                </dt>
              </div>
            ))}
          </dl>
        </Reveal>

        <Reveal delay={180}>
          <p className="mt-6 text-center text-xs text-muted-foreground">{t.note}</p>
        </Reveal>
      </div>
    </section>
  );
}
