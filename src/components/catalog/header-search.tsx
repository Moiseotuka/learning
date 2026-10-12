"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type FormEvent,
  type KeyboardEvent,
} from "react";
import {
  ArrowRightIcon,
  BookOpenIcon,
  GraduationCapIcon,
  LoaderCircleIcon,
  PlayIcon,
  SearchIcon,
} from "lucide-react";

import { messages } from "@/i18n";
import type { CatalogSearchKind } from "@/lib/catalog/search";
import { cn } from "@/lib/utils";

const s = messages.catalogue.search;
const ta = s.typeahead;

type Suggestion = {
  kind: CatalogSearchKind;
  title: string;
  context: string;
  level: string;
  href: string;
};

const KIND_ICON = {
  formation: GraduationCapIcon,
  chapitre: BookOpenIcon,
  tutoriel: PlayIcon,
} as const;

const LIST_ID = "header-search-suggestions";
const INPUT_IDS = { header: "header-search", sheet: "sheet-search" } as const;

/**
 * Champ de recherche de l'en-tête : suggestions du catalogue pendant la frappe.
 * Le `<form method="get">` reste le chemin sans JavaScript — la liste déroulante
 * n'est qu'une accélération, jamais le seul accès aux résultats.
 */
export function HeaderSearch({
  variant = "header",
  className,
  onNavigate,
}: {
  variant?: "header" | "sheet";
  className?: string;
  onNavigate?: () => void;
}) {
  const router = useRouter();
  const inputId = INPUT_IDS[variant];
  const wrapRef = useRef<HTMLFormElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const controllerRef = useRef<AbortController | null>(null);

  const [value, setValue] = useState("");
  // Les résultats portent la requête qui les a produits : une réponse en retard
  // ne peut jamais s'afficher sous un mot-clé déjà modifié.
  const [result, setResult] = useState<{
    query: string;
    items: Suggestion[];
    loading: boolean;
  }>({ query: "", items: [], loading: false });
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);

  const trimmed = value.trim();
  const fresh = result.query === trimmed;
  const items = fresh ? result.items : [];
  const loading = fresh ? result.loading : false;
  const showList = open && trimmed.length >= 2;

  useEffect(() => {
    if (trimmed.length < 2) return;
    const timer = setTimeout(() => {
      controllerRef.current?.abort();
      const controller = new AbortController();
      controllerRef.current = controller;
      setResult({ query: trimmed, items: [], loading: true });
      fetch(`/api/recherche?q=${encodeURIComponent(trimmed)}&limit=7`, {
        signal: controller.signal,
      })
        .then((response) => (response.ok ? response.json() : { items: [] }))
        .then((data: { items: Suggestion[] }) => {
          setResult({ query: trimmed, items: data.items ?? [], loading: false });
          setActive(-1);
        })
        .catch(() => {
          if (!controller.signal.aborted) {
            setResult({ query: trimmed, items: [], loading: false });
          }
        });
    }, 220);

    return () => clearTimeout(timer);
  }, [trimmed]);

  useEffect(() => {
    const onPointerDown = (event: PointerEvent) => {
      if (!wrapRef.current?.contains(event.target as Node)) setOpen(false);
    };
    document.addEventListener("pointerdown", onPointerDown);
    return () => document.removeEventListener("pointerdown", onPointerDown);
  }, []);

  // « / » hors d'une zone de saisie : le réflexe habituel des outils de recherche.
  useEffect(() => {
    if (variant !== "header") return;
    const onKeyDown = (event: globalThis.KeyboardEvent) => {
      const tag = (event.target as HTMLElement | null)?.tagName;
      if (event.key !== "/" || tag === "INPUT" || tag === "TEXTAREA") return;
      event.preventDefault();
      inputRef.current?.focus();
      setOpen(true);
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [variant]);

  const close = useCallback(() => setOpen(false), []);

  function go(href: string) {
    close();
    onNavigate?.();
    router.push(href);
  }

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    if (active >= 0 && items[active]) {
      event.preventDefault();
      go(items[active].href);
      return;
    }
    close();
    onNavigate?.();
  }

  function onKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key === "Escape") {
      setOpen(false);
      return;
    }
    if (!showList || items.length === 0) return;
    if (event.key === "ArrowDown") {
      event.preventDefault();
      setActive((index) => (index + 1) % items.length);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      setActive((index) => (index <= 0 ? items.length - 1 : index - 1));
    }
  }

  return (
    <form
      ref={wrapRef}
      action="/catalogue"
      method="get"
      role="search"
      onSubmit={onSubmit}
      className={cn("relative min-w-0", className)}
    >
      <label className="sr-only" htmlFor={inputId}>
        {s.label}
      </label>
      <SearchIcon
        className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        aria-hidden
      />
      <input
        ref={inputRef}
        id={inputId}
        name="q"
        type="text"
        role="combobox"
        autoComplete="off"
        spellCheck={false}
        aria-expanded={showList}
        aria-controls={LIST_ID}
        aria-autocomplete="list"
        aria-activedescendant={
          active >= 0 && items[active] ? `${LIST_ID}-${active}` : undefined
        }
        aria-describedby={variant === "header" ? `${inputId}-hint` : undefined}
        placeholder={s.headerPlaceholder}
        value={value}
        onChange={(event) => {
          setValue(event.target.value);
          setOpen(true);
        }}
        onFocus={() => setOpen(true)}
        onKeyDown={onKeyDown}
        className={cn(
          "h-9 w-full rounded-full border border-hairline bg-background/70 pl-9 text-sm outline-none transition-[padding,border-color,box-shadow,background-color] placeholder:text-muted-foreground focus-visible:border-electric/60 focus-visible:ring-2 focus-visible:ring-electric/25",
          variant === "header" ? "pr-3 lg:pr-9" : "pr-3",
        )}
      />
      {variant === "header" ? (
        <kbd
          id="header-search-hint"
          title={ta.shortcut}
          className="pointer-events-none absolute right-3 top-1/2 hidden h-5 min-w-5 -translate-y-1/2 items-center justify-center rounded border border-hairline px-1 text-[10px] font-medium text-muted-foreground lg:flex"
          aria-hidden
        >
          /
        </kbd>
      ) : null}

      {showList ? (
        <ul
          id={LIST_ID}
          role="listbox"
          aria-label={ta.listLabel}
          className="absolute right-0 top-11 z-50 max-h-[min(70vh,26rem)] w-[min(26rem,calc(100vw-2rem))] overflow-y-auto rounded-2xl border border-hairline bg-popover p-1.5 text-popover-foreground shadow-xl"
        >
          {loading && items.length === 0 ? (
            <li className="flex items-center gap-2 px-3 py-3 text-sm text-muted-foreground">
              <LoaderCircleIcon className="size-3.5 animate-spin" aria-hidden />
              {ta.loading}
            </li>
          ) : items.length === 0 ? (
            <li className="px-3 py-3 text-sm text-muted-foreground">
              {ta.empty(trimmed)}
            </li>
          ) : (
            items.map((item, index) => {
              const Icon = KIND_ICON[item.kind];
              return (
                <li key={`${item.kind}-${item.href}`} id={`${LIST_ID}-${index}`} role="option" aria-selected={index === active}>
                  <Link
                    href={item.href}
                    onMouseEnter={() => setActive(index)}
                    onClick={() => onNavigate?.()}
                    className={cn(
                      "flex items-center gap-2.5 rounded-xl px-2.5 py-2 transition-colors",
                      index === active ? "bg-electric/10" : "hover:bg-muted",
                    )}
                  >
                    <span
                      className="grid size-7 shrink-0 place-items-center rounded-lg bg-electric/12 text-electric"
                      aria-hidden
                    >
                      <Icon className="size-3.5" />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-[13px] leading-snug font-medium">
                        {item.title}
                      </span>
                      <span className="mt-0.5 block truncate text-[11px] text-muted-foreground">
                        {ta.kinds[item.kind]}
                        {item.context ? ` · ${item.context}` : ""}
                      </span>
                    </span>
                    <ArrowRightIcon
                      className="size-3.5 shrink-0 text-muted-foreground"
                      aria-hidden
                    />
                  </Link>
                </li>
              );
            })
          )}

          <li className="mt-1 border-t border-hairline pt-1">
            <Link
              href={`/catalogue?q=${encodeURIComponent(trimmed)}`}
              onClick={() => onNavigate?.()}
              className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 text-[13px] font-medium text-electric transition-colors hover:bg-muted"
            >
              {ta.all(trimmed)}
              <ArrowRightIcon className="size-3.5 shrink-0" aria-hidden />
            </Link>
          </li>
        </ul>
      ) : null}
    </form>
  );
}
