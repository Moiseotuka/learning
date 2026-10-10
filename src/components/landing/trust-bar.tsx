import { messages } from "@/i18n";

const t = messages;

export function TrustBar() {
  const items = t.trust.items;

  return (
    <section aria-label={t.trust.title} className="border-y border-hairline bg-elevated py-5">
      <div className="mx-auto mb-3 w-full max-w-6xl px-4 sm:px-6">
        <p className="text-center text-xs tracking-[0.18em] text-muted-foreground uppercase">
          {t.trust.title}
        </p>
      </div>

      <div className="mx-auto w-full max-w-6xl px-4 sm:px-6">
        <ul className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3 sm:gap-x-12">
          {items.map((item) => (
            <li
              key={item}
              className="flex items-center gap-3 text-sm font-medium whitespace-nowrap text-muted-foreground"
            >
              <span className="size-1.5 rounded-full bg-electric" aria-hidden />
              {item}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
