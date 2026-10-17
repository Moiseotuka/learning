"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { LucideIcon } from "lucide-react";

import { cn } from "@/lib/utils";

/** Une destination du rail : adresse, étiquette lisible, icône, et le cas échéant
 *  l'exigence d'une correspondance exacte (le tableau de bord ne doit pas rester
 *  actif sur toutes les pages qui partagent son préfixe). */
export type EntreeRail = {
  href: string;
  label: string;
  Icon: LucideIcon;
  exact?: boolean;
};

function estActive(chemin: string, entree: EntreeRail) {
  return entree.exact
    ? chemin === entree.href
    : chemin === entree.href || chemin.startsWith(`${entree.href}/`);
}

/**
 * Rail d'icônes du back-office et de l'espace apprenant : les deux utilisent la
 * même coquille pour que quelqu'un qui a appris l'un retrouve l'autre sans
 * réapprendre. Une colonne fixe, l'étiquette sous l'icône, un trait sur l'entrée
 * courante.
 */
export function RailNav({
  entrees,
  label,
}: {
  entrees: EntreeRail[];
  label: string;
}) {
  const pathname = usePathname();

  return (
    <nav
      aria-label={label}
      className="fixed inset-y-0 left-0 z-40 hidden w-20 flex-col border-r border-hairline bg-card py-4 lg:flex"
    >
      <ul className="flex flex-1 flex-col gap-1 overflow-y-auto px-2">
        {entrees.map((entree) => {
          const active = estActive(pathname, entree);

          return (
            <li key={entree.href}>
              <Link
                href={entree.href}
                aria-current={active ? "page" : undefined}
                className={cn(
                  "relative flex flex-col items-center gap-1 rounded-xl px-1 py-2.5 text-[10px] font-medium transition-colors",
                  active
                    ? "bg-electric/12 text-electric"
                    : "text-muted-foreground hover:bg-muted/60 hover:text-foreground",
                )}
              >
                {active ? (
                  <span
                    aria-hidden
                    className="absolute inset-y-2 -left-2 w-0.5 rounded-full bg-electric"
                  />
                ) : null}
                <entree.Icon className="size-5" aria-hidden />
                {entree.label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

/** Sur téléphone, le rail ne tient pas : les entrées deviennent une barre horizontale. */
export function RailNavMobile({
  entrees,
  label,
}: {
  entrees: EntreeRail[];
  label: string;
}) {
  const pathname = usePathname();

  return (
    <nav
      aria-label={label}
      className="sticky top-0 z-40 -mx-4 border-b border-hairline bg-card/95 px-4 backdrop-blur lg:hidden"
    >
      <ul className="flex gap-1 overflow-x-auto py-2">
        {entrees.map((entree) => {
          const active = estActive(pathname, entree);

          return (
            <li key={entree.href} className="shrink-0">
              <Link
                href={entree.href}
                aria-current={active ? "page" : undefined}
                className={cn(
                  "flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium transition-colors",
                  active
                    ? "bg-electric text-primary-foreground"
                    : "text-muted-foreground hover:bg-muted/60 hover:text-foreground",
                )}
              >
                <entree.Icon className="size-3.5" aria-hidden />
                {entree.label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
