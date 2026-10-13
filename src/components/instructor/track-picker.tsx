"use client";

import { CheckIcon, SearchIcon } from "lucide-react";
import { useMemo, useState } from "react";

import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { cn } from "cn";

const t = messages.formateur;

export type PickerTrack = {
  id: string;
  title: string;
  domain: string;
};

/**
 * Sélecteur de parcours avec recherche : un formateur qui enseigne beaucoup de
 * domaines ne retrouve pas son parcours dans une liste déroulante de trente
 * lignes. Le champ filtre le titre et le domaine, la sélection reste un champ
 * de formulaire classique (`trackId`), donc l'action serveur ne change pas.
 */
export function TrackPicker({
  name,
  tracks,
  initialId,
}: {
  name: string;
  tracks: PickerTrack[];
  initialId?: string;
}) {
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState<string>(initialId ?? tracks[0]?.id ?? "");

  const chosen = tracks.find((track) => track.id === selected) ?? null;

  const grouped = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase("fr");
    const byDomain = new Map<string, PickerTrack[]>();
    for (const track of tracks) {
      if (
        needle &&
        !`${track.title} ${track.domain}`.toLocaleLowerCase("fr").includes(needle)
      ) {
        continue;
      }
      const list = byDomain.get(track.domain) ?? [];
      list.push(track);
      byDomain.set(track.domain, list);
    }
    return [...byDomain.entries()];
  }, [tracks, query]);

  return (
    <div className="w-full">
      <input type="hidden" name={name} value={selected} />

      <div className="relative">
        <SearchIcon
          className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground"
          aria-hidden
        />
        <Input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder={t.trackSearch}
          aria-label={t.trackSearch}
          className="h-10 pl-9"
        />
      </div>

      <p
        className={cn(
          "mt-2 truncate text-xs",
          chosen ? "font-medium text-electric" : "text-muted-foreground",
        )}
      >
        {chosen ? chosen.title : t.trackEmpty}
      </p>

      <div
        role="listbox"
        aria-label={t.classes.fieldTrack}
        className="mt-1 max-h-64 overflow-y-auto rounded-2xl border border-hairline bg-card"
      >
        {grouped.length === 0 ? (
          <p className="px-4 py-6 text-center text-sm text-muted-foreground">
            {t.trackEmpty}
          </p>
        ) : (
          grouped.map(([domain, list]) => (
            <div key={domain}>
              <p className="sticky top-0 border-b border-hairline bg-card/95 px-4 py-2 text-[11px] font-semibold tracking-wide text-muted-foreground uppercase backdrop-blur">
                {domain}
              </p>
              <ul className="divide-y divide-hairline">
                {list.map((track) => {
                  const active = track.id === selected;
                  return (
                    <li key={track.id}>
                      <button
                        type="button"
                        role="option"
                        aria-selected={active}
                        onClick={() => setSelected(track.id)}
                        className={cn(
                          "flex w-full items-center gap-3 px-4 py-2.5 text-left text-sm transition-colors",
                          active
                            ? "bg-electric/8 text-foreground"
                            : "text-muted-foreground hover:bg-muted/50",
                        )}
                      >
                        <span
                          className={cn(
                            "flex size-5 shrink-0 items-center justify-center rounded-full border",
                            active
                              ? "border-electric bg-electric text-white"
                              : "border-hairline",
                          )}
                          aria-hidden
                        >
                          {active ? <CheckIcon className="size-3.5" /> : null}
                        </span>
                        <span className="min-w-0 flex-1 truncate font-medium text-foreground">
                          {track.title}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
