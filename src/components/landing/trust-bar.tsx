import { messages } from "@/i18n";

const t = messages.trust;

/**
 * Bandeau défilant en CSS pur : deux groupes identiques côte à côte, et la boucle
 * avance de exactement 50 % de la piste, donc sans raccord visible. Aucun JavaScript
 * à charger sur une connexion 3G. Le second groupe est `aria-hidden` et une liste
 * `sr-only` garde les technologies lisibles pour un lecteur d'écran.
 */
export function TrustBar() {
  const rangees = [t.items, [...t.items].reverse()];

  return (
    <section aria-label={t.title} className="border-y border-hairline bg-elevated py-8">
      <p className="mx-auto mb-5 w-full max-w-6xl px-4 text-center text-xs tracking-[0.18em] text-muted-foreground uppercase sm:px-6">
        {t.title}
      </p>

      <div className="space-y-3 overflow-hidden [mask-image:linear-gradient(to_right,transparent,black_9%,black_91%,transparent)]">
        {rangees.map((rangee, index) => (
          <div
            key={index}
            className="flex w-max anim-defile"
            style={{
              animationDuration: index === 0 ? "38s" : "46s",
              animationDirection: index === 1 ? "reverse" : "normal",
            }}
          >
            {[0, 1].map((copie) => (
              <div
                key={copie}
                aria-hidden={copie === 1 || undefined}
                className="flex shrink-0 gap-3 pr-3"
              >
                {rangee.map((item) => (
                  <span
                    key={item}
                    className="inline-flex items-center gap-2.5 rounded-full border border-hairline bg-card px-4 py-2 text-sm font-medium whitespace-nowrap text-muted-foreground"
                  >
                    <span className="size-1.5 rounded-full bg-electric" aria-hidden />
                    {item}
                  </span>
                ))}
              </div>
            ))}
          </div>
        ))}
      </div>

      <ul className="sr-only">
        {t.items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </section>
  );
}
