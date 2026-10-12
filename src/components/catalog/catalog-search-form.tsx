import Link from "next/link";
import { SearchIcon, XIcon } from "lucide-react";

import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages.catalogue.search;

type HiddenParams = Record<string, string | undefined>;

function buildAction(hidden?: HiddenParams) {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(hidden ?? {})) {
    if (value) params.set(key, value);
  }
  const query = params.toString();
  return query ? `/catalogue?${query}` : "/catalogue";
}

/**
 * Recherche interne du catalogue : un simple GET vers /catalogue?q=…,
 * fonctionnel même sans JavaScript.
 */
export function CatalogSearchForm({
  variant = "sidebar",
  defaultValue = "",
  hidden,
  className,
}: {
  variant?: "sidebar" | "header" | "hero";
  defaultValue?: string;
  hidden?: HiddenParams;
  className?: string;
}) {
  const placeholder =
    variant === "hero"
      ? t.heroPlaceholder
      : variant === "header"
        ? t.headerPlaceholder
        : t.placeholder;

  if (variant === "header") {
    return (
      <form
        action={buildAction(hidden)}
        method="get"
        role="search"
        className={cn("flex w-full items-center gap-1.5", className)}
      >
        <label className="sr-only" htmlFor="site-search">
          {t.label}
        </label>
        <div className="relative w-full min-w-0">
          <SearchIcon
            className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
            aria-hidden
          />
          <input
            id="site-search"
            name="q"
            type="search"
            defaultValue={defaultValue}
            placeholder={placeholder}
            aria-label={t.label}
            className="h-9 w-full rounded-full border border-hairline bg-background/70 pl-9 pr-3 text-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-electric/60 focus-visible:ring-2 focus-visible:ring-electric/25"
          />
        </div>
        <button
          type="submit"
          className="grid size-9 shrink-0 place-items-center rounded-full border border-hairline bg-background/70 text-muted-foreground transition-colors hover:border-electric/60 hover:text-electric"
          aria-label={t.submit}
        >
          <SearchIcon className="size-4" aria-hidden />
        </button>
      </form>
    );
  }

  if (variant === "hero") {
    return (
      <form
        action={buildAction(hidden)}
        method="get"
        role="search"
        className={cn("w-full", className)}
      >
        <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          {t.heading}
        </label>
        <div className="mt-2 flex gap-2">
          <input
            name="q"
            type="search"
            defaultValue={defaultValue}
            placeholder={placeholder}
            aria-label={t.label}
            className="h-12 min-w-0 flex-1 rounded-xl border border-hairline bg-card/80 px-4 text-sm backdrop-blur outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-electric/60 focus-visible:ring-2 focus-visible:ring-electric/25 sm:text-base"
          />
          <button
            type="submit"
            className="inline-flex h-12 shrink-0 items-center gap-2 rounded-xl bg-electric px-5 text-sm font-semibold text-primary-foreground shadow-lg shadow-electric/25 transition-opacity hover:opacity-90"
          >
            <SearchIcon className="size-4" aria-hidden />
            {t.submit}
          </button>
        </div>
        <ul className="mt-3 flex flex-wrap items-center gap-1.5">
          {t.suggestions.map((suggestion) => (
            <li key={suggestion}>
              <Link
                href={`/catalogue?q=${encodeURIComponent(suggestion)}`}
                className="inline-block rounded-full border border-hairline bg-card/60 px-2.5 py-1 text-xs text-muted-foreground backdrop-blur transition-colors hover:border-electric/50 hover:text-foreground"
              >
                {suggestion}
              </Link>
            </li>
          ))}
        </ul>
      </form>
    );
  }

  return (
    <form
      action={buildAction(hidden)}
      method="get"
      role="search"
      className={cn("relative", className)}
    >
      <SearchIcon
        className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        aria-hidden
      />
      <input
        name="q"
        type="search"
        defaultValue={defaultValue}
        placeholder={placeholder}
        aria-label={t.label}
        className="h-10 w-full rounded-xl border border-hairline bg-background pl-9 pr-9 text-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-electric/60 focus-visible:ring-2 focus-visible:ring-electric/25"
      />
      {hidden
        ? Object.entries(hidden).map(
            ([key, value]) =>
              value ? (
                <input key={key} type="hidden" name={key} value={value} />
              ) : null,
          )
        : null}
      {defaultValue ? (
        <Link
          href={buildAction(hidden)}
          aria-label={t.clear}
          className="absolute right-2 top-1/2 grid size-6 -translate-y-1/2 place-items-center rounded-full text-muted-foreground transition-colors hover:text-foreground"
        >
          <XIcon className="size-3.5" aria-hidden />
        </Link>
      ) : null}
    </form>
  );
}
