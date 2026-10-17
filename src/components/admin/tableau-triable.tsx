"use client";

import { ArrowDownIcon, ArrowUpIcon, ChevronsUpDownIcon } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";

import { cn } from "@/lib/utils";

/**
 * Tableau de pilotage triable, comme les studios de création : on clique une entête de colonne,
 * les lignes se rangent. Le tri est local parce que les données tiennent dans la page (au plus
 * quelques centaines de lignes) : rien n'est redemandé à la base à chaque clic, donc la page
 * reste utilisable sur une connexion lente.
 */

export type Cellule = {
  /** Ce que l'admin lit dans la case. */
  texte: string;
  /** Ce qui sert à ranger la colonne. Défaut : `texte`. */
  valeur?: number | string;
  /** Deuxième ligne, plus discète : un e-mail sous un nom, un niveau sous un parcours. */
  note?: string;
  /** Lien optionnel, pour atteindre la fiche concernée depuis la liste. */
  lien?: string;
};

export type Colonne = {
  cle: string;
  titre: string;
  /** Les colonnes de compteurs sont alignées à droite et triées numériquement. */
  nombre?: boolean;
  className?: string;
};

function sansAccent(valeur: string): string {
  return valeur.toLowerCase().normalize("NFD").replace(/\p{Diacritic}/gu, "");
}

function cleDeTri(ligne: Record<string, Cellule>, colonne: Colonne): number | string {
  const cellule = ligne[colonne.cle];
  if (!cellule) return "";
  if (cellule.valeur !== undefined) return cellule.valeur;
  return colonne.nombre ? Number(sansAccent(cellule.texte.replace(/[^\d,.-]/g, ""))) || 0 : cellule.texte;
}

export function TableauTriable({
  colonnes,
  lignes,
  triInitial,
  filtre,
  vide,
  resume,
}: {
  colonnes: Colonne[];
  lignes: Record<string, Cellule>[];
  triInitial?: { cle: string; ascendant?: boolean };
  filtre?: { label: string; placeholder: string };
  vide: string;
  resume?: string;
}) {
  const [tri, setTri] = useState<{ cle: string; ascendant: boolean } | null>(
    triInitial ? { cle: triInitial.cle, ascendant: triInitial.ascendant ?? true } : null,
  );
  const [terme, setTerme] = useState("");

  const visibles = useMemo(() =>
    lignes.filter((ligne) => {
      if (!terme) return true;
      const aiguillon = sansAccent(terme);
      return Object.values(ligne).some(
        (cellule) => sansAccent(cellule.texte).includes(aiguillon) || sansAccent(cellule.note ?? "").includes(aiguillon),
      );
    }),
    [lignes, terme],
  );

  const rangees = useMemo(() => {
    if (!tri) return visibles;
    const colonne = colonnes.find((c) => c.cle === tri.cle);
    if (!colonne) return visibles;
    const signe = tri.ascendant ? 1 : -1;
    return [...visibles].sort((a, b) => {
      const gauche = cleDeTri(a, colonne);
      const droite = cleDeTri(b, colonne);
      if (typeof gauche === "number" && typeof droite === "number") return (gauche - droite) * signe;
      return String(gauche).localeCompare(String(droite), "fr") * signe;
    });
  }, [visibles, tri, colonnes]);

  function basculer(cle: string) {
    setTri((actuel) =>
      actuel?.cle === cle ? { cle, ascendant: !actuel.ascendant } : { cle, ascendant: false },
    );
  }

  return (
    <div>
      {filtre ? (
        <div className="mb-3 flex items-center gap-2">
          <label className="flex-1 sm:max-w-xs">
            <span className="sr-only">{filtre.label}</span>
            <input
              type="search"
              value={terme}
              onChange={(event) => setTerme(event.target.value)}
              placeholder={filtre.placeholder}
              className="h-9 w-full rounded-full border border-hairline bg-card px-3 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-electric"
            />
          </label>
          <span className="text-xs text-muted-foreground">
            {rangees.length} / {lignes.length}
          </span>
        </div>
      ) : null}

      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="text-[11px] uppercase tracking-wide text-muted-foreground">
            <tr className="border-b border-hairline">
              {colonnes.map((colonne) => {
                const actif = tri?.cle === colonne.cle;
                const Icon = !actif
                  ? ChevronsUpDownIcon
                  : actif && tri?.ascendant
                    ? ArrowUpIcon
                    : ArrowDownIcon;
                return (
                  <th key={colonne.cle} className={cn("px-4 py-2 font-medium", colonne.nombre && "text-right")} aria-sort={actif ? (tri?.ascendant ? "ascending" : "descending") : "none"}>
                    <button
                      type="button"
                      onClick={() => basculer(colonne.cle)}
                      className={cn(
                        "inline-flex items-center gap-1 rounded px-1 py-0.5 transition-colors hover:text-foreground",
                        actif && "text-foreground",
                        colonne.nombre && "flex-row-reverse",
                      )}
                    >
                      <Icon className="size-3" aria-hidden />
                      {colonne.titre}
                    </button>
                  </th>
                );
              })}
            </tr>
          </thead>
          <tbody>
            {rangees.map((ligne, index) => (
              <tr
                key={`${Object.values(ligne)[0]?.texte ?? ""}-${index}`}
                className="border-b border-hairline/60 text-foreground last:border-0"
              >
                {colonnes.map((colonne) => {
                  const cellule = ligne[colonne.cle];
                  return (
                    <td
                      key={colonne.cle}
                      className={cn(
                        "px-4 py-2.5 align-middle",
                        colonne.nombre && "text-right tabular-nums",
                        colonne.className,
                      )}
                    >
                      {cellule ? (
                        <>
                          {cellule.lien ? (
                            <Link href={cellule.lien} className="font-medium text-electric hover:underline">
                              {cellule.texte}
                            </Link>
                          ) : (
                            <span className={colonne.nombre ? "" : "font-medium"}>{cellule.texte}</span>
                          )}
                          {cellule.note ? (
                            <span className="block truncate text-xs text-muted-foreground">
                              {cellule.note}
                            </span>
                          ) : null}
                        </>
                      ) : (
                        "—"
                      )}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>

        {rangees.length === 0 ? (
          <p className="px-4 py-6 text-xs text-muted-foreground">{vide}</p>
        ) : null}
      </div>

      {resume ? <p className="mt-2 text-xs text-muted-foreground">{resume}</p> : null}
    </div>
  );
}
