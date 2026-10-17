import { SearchIcon } from "lucide-react";

import { Carte } from "@/components/admin/carte";
import { TableauTriable, type Colonne } from "@/components/admin/tableau-triable";
import { messages } from "@/i18n";
import { argent, dateCourte, libelleStatut, nomRole } from "@/lib/admin/libelles";
import { rechercher } from "@/lib/admin/stats";

const r = messages.admin.recherche;
const u = messages.admin.utilisateurs;
const a = messages.admin.achats;
const d = messages.admin.dashboard;

const COLONNES_COMPTES: Colonne[] = [
  { cle: "compte", titre: u.columnAccount },
  { cle: "role", titre: u.columnRole },
  { cle: "inscrit", titre: u.columnJoined },
];

const COLONNES_TRANSACTIONS: Colonne[] = [
  { cle: "client", titre: a.columnClient },
  { cle: "article", titre: a.columnItem },
  { cle: "montant", titre: a.columnAmount, nombre: true },
  { cle: "statut", titre: a.columnStatus },
  { cle: "ouverte", titre: a.columnCreated },
];

const COLONNES_PARCOURS: Colonne[] = [
  { cle: "titre", titre: r.columnTrack },
  { cle: "categorie", titre: r.columnCategory },
  { cle: "niveau", titre: r.columnTrackLevel },
  { cle: "publie", titre: r.columnTrackPublished },
];

export default async function RecherchePage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const terme = (q ?? "").trim();
  const resultat = terme.length >= 2 ? await rechercher(terme) : null;

  const total = resultat
    ? resultat.comptes.length + resultat.transactions.length + resultat.parcours.length
    : 0;

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">{r.title}</h1>
        <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{r.intro}</p>
      </header>

      <form action="/admin/recherche" method="get" role="search" className="flex gap-2">
        <label className="flex-1 sm:max-w-md">
          <span className="sr-only">{r.placeholder}</span>
          <input
            type="search"
            name="q"
            defaultValue={terme}
            placeholder={r.placeholder}
            className="h-10 w-full rounded-full border border-hairline bg-card px-4 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-electric"
          />
        </label>
        <button
          type="submit"
          className="inline-flex h-10 items-center gap-2 rounded-full bg-electric px-4 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
        >
          <SearchIcon className="size-4" aria-hidden />
          {r.go}
        </button>
      </form>

      {!terme ? <p className="text-sm text-muted-foreground">{r.noQuery}</p> : null}
      {terme && terme.length < 2 ? (
        <p className="text-sm text-muted-foreground">{r.tooShort}</p>
      ) : null}
      {terme.length >= 2 && !resultat ? (
        <p className="text-sm text-muted-foreground">{d.unavailable}</p>
      ) : null}

      {resultat ? (
        <>
          <p className="text-sm text-muted-foreground">{r.resultCount(terme, total)}</p>

          <div className="space-y-4">
            <Carte titre={r.accounts}>
              <TableauTriable
                colonnes={COLONNES_COMPTES}
                triInitial={{ cle: "inscrit", ascendant: false }}
                vide={r.noResults}
                lignes={resultat.comptes.map((l) => ({
                  compte: {
                    texte: l.nom || l.email || "—",
                    note: l.nom ? l.email || undefined : undefined,
                    lien: `/admin/utilisateurs`,
                  },
                  role: { texte: nomRole(l.role), valeur: l.role },
                  inscrit: { texte: dateCourte(l.inscrit), valeur: l.inscrit },
                }))}
              />
            </Carte>

            <Carte titre={r.purchases}>
              <TableauTriable
                colonnes={COLONNES_TRANSACTIONS}
                triInitial={{ cle: "ouverte", ascendant: false }}
                vide={r.noResults}
                lignes={resultat.transactions.map((l) => ({
                  client: { texte: l.client || d.compteSupprime, note: l.email || undefined },
                  article: { texte: l.article || "—", note: l.niveau || undefined },
                  montant: { texte: argent(l.montant, l.devise), valeur: l.montant },
                  statut: { texte: libelleStatut(l.statut), valeur: l.statut },
                  ouverte: { texte: dateCourte(l.cree), valeur: l.cree },
                }))}
              />
            </Carte>

            <Carte titre={r.catalog}>
              <TableauTriable
                colonnes={COLONNES_PARCOURS}
                triInitial={{ cle: "titre" }}
                vide={r.noResults}
                lignes={resultat.parcours.map((l) => ({
                  titre: { texte: l.titre, lien: "/admin/categories" },
                  categorie: { texte: l.categorie || "—" },
                  niveau: { texte: l.niveau || "—" },
                  publie: {
                    texte: l.publie ? r.yes : r.no,
                    valeur: l.publie ? 1 : 0,
                  },
                }))}
              />
            </Carte>
          </div>
        </>
      ) : null}
    </div>
  );
}
