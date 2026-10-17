import Link from "next/link";
import type { ReactNode } from "react";

import { cn } from "@/lib/utils";
import type { Periode } from "@/lib/admin/stats";

/** Carte de contenu du tableau de bord : titre, explication courte, données, lien de sortie. */
export function Carte({
  titre,
  intro,
  children,
  lien,
  className,
}: {
  titre: string;
  intro?: string;
  children: ReactNode;
  lien?: { href: string; libelle: string };
  className?: string;
}) {
  return (
    <section
      className={cn(
        "min-w-0 rounded-2xl border border-hairline bg-card p-5",
        className,
      )}
    >
      <h2 className="text-sm font-semibold text-foreground">{titre}</h2>
      {intro ? <p className="mt-0.5 text-xs text-muted-foreground">{intro}</p> : null}
      <div className={cn("min-w-0", intro && "mt-4")}>{children}</div>
      {lien ? (
        <Link
          href={lien.href}
          className="mt-4 inline-block text-xs font-medium text-electric hover:underline"
        >
          {lien.libelle}
        </Link>
      ) : null}
    </section>
  );
}

/** Sélecteur de période : trois liens, aucun JavaScript, donc utilisable sur téléphone modeste. */
export function NavPeriode({
  base,
  choisie,
  label,
  libelles,
}: {
  base: string;
  choisie: Periode;
  label: string;
  libelles: Record<Periode, string>;
}) {
  return (
    <nav aria-label={label} className="flex gap-1 rounded-full border border-hairline p-1">
      {(["7", "30", "90"] as const).map((cle) => (
        <Link
          key={cle}
          href={`${base}?periode=${cle}`}
          aria-current={choisie === cle ? "page" : undefined}
          className={
            choisie === cle
              ? "rounded-full bg-electric px-3 py-1 text-xs font-medium text-primary-foreground"
              : "rounded-full px-3 py-1 text-xs font-medium text-muted-foreground transition-colors hover:text-foreground"
          }
        >
          {libelles[cle]}
        </Link>
      ))}
    </nav>
  );
}

export function periodeDemandee(brut: string | undefined): Periode {
  return brut === "7" || brut === "90" ? brut : "30";
}
