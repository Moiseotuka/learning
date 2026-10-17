import Link from "next/link";

import { Kpi } from "@/components/admin/graphiques";
import { Carte } from "@/components/admin/carte";
import { TableauTriable, type Colonne } from "@/components/admin/tableau-triable";
import { messages } from "@/i18n";
import { argent, dateCourte, libelleStatut, nombre } from "@/lib/admin/libelles";
import { lireTransactions, lireVentes } from "@/lib/admin/stats";

const a = messages.admin.achats;
const d = messages.admin.dashboard;

const COLONNES_TRANSACTIONS: Colonne[] = [
  { cle: "client", titre: a.columnClient },
  { cle: "article", titre: a.columnItem },
  { cle: "montant", titre: a.columnAmount, nombre: true },
  { cle: "statut", titre: a.columnStatus },
  { cle: "fournisseur", titre: a.columnProvider },
  { cle: "ouverte", titre: a.columnCreated },
  { cle: "payee", titre: a.columnPaid },
];

const COLONNES_CATEGORIES: Colonne[] = [
  { cle: "categorie", titre: a.columnCategory },
  { cle: "niveau", titre: a.columnLevel },
  { cle: "payes", titre: a.columnPaidCount, nombre: true },
  { cle: "en_attente", titre: a.recap.pending, nombre: true },
  { cle: "montant", titre: a.columnAmount, nombre: true },
];

const COLONNES_ABONNEMENTS: Colonne[] = [
  { cle: "statut", titre: a.columnStatus },
  { cle: "nombre", titre: a.columnTrainers, nombre: true },
  { cle: "montant", titre: a.columnAmountFc, nombre: true },
];

export default async function AchatsPage({
  searchParams,
}: {
  searchParams: Promise<{ statut?: string }>;
}) {
  const { statut } = await searchParams;
  const [ventes, transactions] = await Promise.all([
    lireVentes(),
    lireTransactions(statut, 500),
  ]);

  const autres = ventes
    ? ventes.totalAchats - ventes.achatsPayes - ventes.achatsEnAttente
    : 0;

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">{a.title}</h1>
        <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{a.intro}</p>
      </header>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
        <Kpi titre={a.recap.records} valeur={nombre(ventes?.totalAchats)} />
        <Kpi titre={a.recap.paid} valeur={nombre(ventes?.achatsPayes)} />
        <Kpi titre={a.recap.pending} valeur={nombre(ventes?.achatsEnAttente)} />
        <Kpi
          titre={a.recap.revenue}
          valeur={ventes ? argent(ventes.montantPaye, ventes.devise) : d.unavailable}
        />
        <Kpi
          titre={a.recap.waiting}
          valeur={ventes ? argent(ventes.montantEnAttente, ventes.devise) : d.unavailable}
          note={autres > 0 ? `${nombre(autres)} ${a.recap.other.toLowerCase()}` : undefined}
        />
      </section>

      <nav aria-label={a.filterLabel} className="flex flex-wrap gap-1.5">
        {[undefined, ...new Set((ventes?.achats ?? []).map((l) => l.statut))].map((cle) => {
          const actif = (statut ?? "") === (cle ?? "");
          const href = cle ? `/admin/achats?statut=${encodeURIComponent(cle)}` : "/admin/achats";
          return (
            <Link
              key={cle ?? "tous"}
              href={href}
              aria-current={actif ? "page" : undefined}
              className={
                actif
                  ? "rounded-full bg-electric px-3 py-1 text-xs font-medium text-primary-foreground"
                  : "rounded-full border border-hairline px-3 py-1 text-xs font-medium text-muted-foreground transition-colors hover:border-electric/50 hover:text-foreground"
              }
            >
              {cle ? libelleStatut(cle) : a.filterAll}
            </Link>
          );
        })}
      </nav>

      <Carte titre={a.title}>
        <TableauTriable
          colonnes={COLONNES_TRANSACTIONS}
          triInitial={{ cle: "ouverte", ascendant: false }}
          vide={a.noData}
          resume={a.resume(transactions?.length ?? 0)}
          lignes={(transactions ?? []).map((l) => ({
            client: {
              texte: l.client || d.compteSupprime,
              note: l.email || undefined,
              lien: l.email ? `/admin/recherche?q=${encodeURIComponent(l.email)}` : undefined,
            },
            article: { texte: l.article || "—", note: `${l.niveau}` },
            montant: { texte: argent(l.montant, l.devise), valeur: l.montant },
            statut: { texte: libelleStatut(l.statut), valeur: l.statut },
            fournisseur: { texte: l.fournisseur, valeur: l.fournisseur },
            ouverte: { texte: dateCourte(l.cree), valeur: l.cree },
            payee: { texte: l.paye ? dateCourte(l.paye) : a.notPaid, valeur: l.paye ?? "" },
          }))}
        />
      </Carte>

      <section className="grid gap-4 lg:grid-cols-2">
        <Carte titre={a.byCategoryTitle} intro={a.byCategoryIntro}>
          <TableauTriable
            colonnes={COLONNES_CATEGORIES}
            triInitial={{ cle: "payes", ascendant: false }}
            vide={a.noData}
            lignes={(ventes?.parCategorie ?? []).map((l) => ({
              categorie: { texte: l.categorie, lien: "/admin/categories" },
              niveau: { texte: l.niveau },
              payes: { texte: nombre(l.payes), valeur: l.payes },
              en_attente: { texte: nombre(l.enAttente), valeur: l.enAttente },
              montant: { texte: argent(l.montant, l.devise), valeur: l.montant },
            }))}
          />
        </Carte>

        <Carte titre={a.subsTitle} intro={a.subsIntro}>
          <TableauTriable
            colonnes={COLONNES_ABONNEMENTS}
            triInitial={{ cle: "nombre", ascendant: false }}
            vide={a.noData}
            lignes={(ventes?.abonnements ?? []).map((l) => ({
              statut: { texte: libelleStatut(l.statut), valeur: l.statut },
              nombre: { texte: nombre(l.nombre), valeur: l.nombre },
              montant: { texte: argent(l.montant, "CDF"), valeur: l.montant },
            }))}
          />
          <Link
            href="/admin/formateurs"
            className="mt-4 inline-block text-xs font-medium text-electric hover:underline"
          >
            {messages.admin.rail.instructors}
          </Link>
        </Carte>
      </section>
    </div>
  );
}
