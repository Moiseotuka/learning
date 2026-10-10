import { Reveal } from "@/components/reveal";
import { Counter } from "@/components/counter";

const partnerLogos = [
  "Université de Kinshasa",
  "ISIPA",
  "Cisco Academy",
  "Microsoft",
  "Google",
  "UNESCO",
];

const extraStats = [
  { value: 94, suffix: "%", label: "Taux de complétion" },
  { value: 48, suffix: "", label: "Partenaires" },
  { value: 12, suffix: "", label: "Pays couverts" },
  { value: 4.8, suffix: "/5", label: "Satisfaction apprenants", decimals: 1 },
];

export function StatsBar() {
  return (
    <section className="border-y border-hairline bg-elevated py-10">
      <div className="mx-auto w-full max-w-6xl px-4 sm:px-6">
        <Reveal>
          <div className="grid grid-cols-2 gap-6 sm:grid-cols-4">
            {extraStats.map((stat) => (
              <div key={stat.label} className="text-center">
                <p className="text-3xl font-bold text-electric sm:text-4xl">
                  <Counter value={stat.value} suffix={stat.suffix} decimals={stat.decimals ?? 0} />
                </p>
                <p className="mt-1 text-xs text-muted-foreground">{stat.label}</p>
              </div>
            ))}
          </div>
        </Reveal>

        <Reveal delay={120}>
          <div className="mt-10 border-t border-hairline pt-8">
            <p className="text-center text-xs tracking-[0.18em] text-muted-foreground uppercase">
              Ils nous font confiance
            </p>
            <div className="mt-5 flex flex-wrap items-center justify-center gap-x-10 gap-y-4">
              {partnerLogos.map((logo) => (
                <span
                  key={logo}
                  className="text-sm font-semibold whitespace-nowrap text-muted-foreground/60"
                >
                  {logo}
                </span>
              ))}
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
