import {
  BanknoteIcon,
  MousePointerClickIcon,
  ReceiptTextIcon,
  TrendingUpIcon,
  UsersIcon,
  EyeIcon,
} from "lucide-react";
import Link from "next/link";

import { AdminNotice } from "@/components/admin/admin-notice";
import { Anneau, Barres, Courbe, Kpi } from "@/components/admin/graphiques";
import { Carte, NavPeriode, periodeDemandee } from "@/components/admin/carte";
import { messages } from "@/i18n";
import {
  argent,
  dateCourte,
  jourCourt,
  libelleStatut,
  nomCanal,
  nomMedium,
  nomPays,
  nombre,
} from "@/lib/admin/libelles";
import {
  countRegisteredUsers,
  lireTransactions,
  lireTrafic,
  lireVentes,
} from "@/lib/admin/stats";

const d = messages.admin.dashboard;

export default async function AdminDashboardPage({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string; periode?: string }>;
}) {
  const { notice, periode } = await searchParams;
  const [trafic, ventes, transactions, inscrits] = await Promise.all([
    lireTrafic(periodeDemandee(periode)),
    lireVentes(),
    lireTransactions(),
    countRegisteredUsers(),
  ]);

  const jours = trafic?.parJour ?? [];
  const joursRecents = jours.slice(-7);
  const joursPrecedents = jours.slice(-14, -7);
  const visiteurs7 = joursRecents.reduce((somme, l) => somme + l.visiteurs, 0);
  const visiteursAvant = joursPrecedents.reduce((somme, l) => somme + l.visiteurs, 0);

  // Le ratio visiteur → compte n'a de sens que sur les journées où la capture des visites a
  // réellement tourné : sinon une inscription de la veille, arrivée avant la mesure, ferait
  // apparaître un « 275 % » invraisemblable.
  const joursCaptures = jours.filter((l) => l.visiteurs > 0);
  const visiteursCaptes = joursCaptures.reduce((somme, l) => somme + l.visiteurs, 0);
  const inscritsCaptes = joursCaptures.reduce((somme, l) => somme + l.inscrits, 0);
  const conversion =
    visiteursCaptes > 0 ? `${((inscritsCaptes / visiteursCaptes) * 100).toFixed(1)} %` : "—";

  return (
    <div className="space-y-6">
      <AdminNotice notice={notice} />

      <header className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-foreground">{d.title}</h1>
          <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{d.intro}</p>
        </div>

        <NavPeriode
          base="/admin"
          choisie={periodeDemandee(periode)}
          label={d.periods}
          libelles={d.periodLabels}
        />
      </header>

      <section aria-label={d.kpis} className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        <Kpi
          titre={d.signups}
          valeur={nombre(inscrits)}
          variation={
            trafic
              ? { valeur: trafic.inscrits, libelle: d.newOnPeriod }
              : null
          }
          Icon={UsersIcon}
        />
        <Kpi
          titre={d.visitors}
          valeur={nombre(trafic?.visiteurs)}
          variation={
            trafic
              ? { valeur: visiteurs7 - visiteursAvant, libelle: d.vsPreviousWeek }
              : null
          }
          note={d.uniquePerDay}
          Icon={EyeIcon}
        />
        <Kpi
          titre={d.pageViews}
          valeur={nombre(trafic?.vues)}
          note={d.viewsNote}
          Icon={MousePointerClickIcon}
        />
        <Kpi
          titre={d.purchases}
          valeur={`${nombre(ventes?.achatsPayes)} / ${nombre(ventes?.totalAchats)}`}
          note={d.purchasesNote}
          Icon={ReceiptTextIcon}
        />
        <Kpi
          titre={d.revenue}
          valeur={ventes ? argent(ventes.montantPaye, ventes.devise) : d.unavailable}
          note={
            ventes
              ? `${argent(ventes.montantEnAttente, ventes.devise)} ${d.pendingSuffix}`
              : undefined
          }
          Icon={BanknoteIcon}
        />
        <Kpi
          titre={d.conversion}
          valeur={conversion}
          note={d.conversionNote}
          Icon={TrendingUpIcon}
        />
      </section>

      <section className="grid gap-4 xl:grid-cols-3">
        <Carte
          titre={d.trafficOverTime}
          intro={d.trafficOverTimeIntro}
          className="rounded-2xl border border-hairline bg-card p-5 xl:col-span-2"
        >
          {jours.length ? (
            <Courbe
              etiquettes={jours.map((l) => jourCourt(l.jour))}
              legende={d.trafficOverTime}
              series={[
                { nom: d.pageViews, points: jours.map((l) => l.vues), classe: "text-electric" },
                {
                  nom: d.visitors,
                  points: jours.map((l) => l.visiteurs),
                  classe: "text-emerald-500",
                },
                {
                  nom: d.signups,
                  points: jours.map((l) => l.inscrits),
                  classe: "text-emerald-500",
                },
              ]}
            />
          ) : (
            <p className="text-xs text-muted-foreground">{d.noTraffic}</p>
          )}
        </Carte>

        <Carte titre={d.purchaseStatus} intro={d.purchaseStatusIntro}>
          {ventes && ventes.achats.length ? (
            <Anneau
              centre={nombre(ventes.totalAchats)}
              libelleCentre={d.purchases}
              parts={ventes.achats.map((l) => ({
                nom: libelleStatut(l.statut),
                valeur: l.nombre,
              }))}
            />
          ) : (
            <p className="text-xs text-muted-foreground">{d.noPurchase}</p>
          )}
          <Link
            href="/admin/achats"
            className="mt-4 inline-block text-xs font-medium text-electric hover:underline"
          >
            {d.seeAllPurchases}
          </Link>
        </Carte>
      </section>

      <section className="grid gap-4 lg:grid-cols-2 xl:grid-cols-3">
        <Carte
          titre={d.bySource}
          intro={d.bySourceIntro}
          lien={{ href: "/admin/visiteurs", libelle: d.seeAllVisitors }}
        >
          <Barres
            lignes={(trafic?.parSource ?? []).map((l) => ({
              source: `${nomCanal(l.source)} · ${nomMedium(l.medium)}`,
              visiteurs: l.visiteurs,
              vues: l.vues,
            }))}
            cle="source"
            valeur="visiteurs"
            secondaires={[{ cle: "vues", libelle: d.viewsShort }]}
          />
        </Carte>

        <Carte titre={d.topPages} intro={d.topPagesIntro}>
          <Barres
            lignes={(trafic?.pages ?? []).slice(0, 8).map((l) => ({
              path: l.path,
              vues: l.vues,
            }))}
            cle="path"
            valeur="vues"
          />
        </Carte>

        <Carte titre={d.byCountry} intro={d.byCountryIntro}>
          <Barres
            lignes={(trafic?.pays ?? []).map((l) => ({
              pays: nomPays(l.pays),
              visiteurs: l.visiteurs,
            }))}
            cle="pays"
            valeur="visiteurs"
          />
        </Carte>
      </section>

      <section className="rounded-2xl border border-hairline bg-card">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-hairline px-5 py-4">
          <div>
            <h2 className="text-sm font-semibold text-foreground">{d.recentTransactions}</h2>
            <p className="mt-0.5 text-xs text-muted-foreground">{d.recentTransactionsIntro}</p>
          </div>
          <Link href="/admin/achats" className="text-xs font-medium text-electric hover:underline">
            {d.seeAllPurchases}
          </Link>
        </div>

        {transactions && transactions.length ? (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="text-[11px] uppercase tracking-wide text-muted-foreground">
                <tr className="border-b border-hairline">
                  <th className="px-5 py-2 font-medium">{d.columnClient}</th>
                  <th className="px-5 py-2 font-medium">{d.columnItem}</th>
                  <th className="px-5 py-2 font-medium">{d.columnAmount}</th>
                  <th className="px-5 py-2 font-medium">{d.columnStatus}</th>
                  <th className="px-5 py-2 font-medium">{d.columnDate}</th>
                </tr>
              </thead>
              <tbody>
                {transactions.slice(0, 8).map((ligne) => (
                  <tr key={ligne.id} className="border-b border-hairline/60 last:border-0">
                    <td className="px-5 py-2.5">
                      <span className="block truncate font-medium text-foreground">
                        {ligne.client || d.compteSupprime}
                      </span>
                      <span className="block truncate text-xs text-muted-foreground">
                        {ligne.email || "—"}
                      </span>
                    </td>
                    <td className="px-5 py-2.5 text-muted-foreground">
                      {ligne.article}
                      <span className="block text-xs">
                        {ligne.niveau} · {ligne.fournisseur}
                      </span>
                    </td>
                    <td className="px-5 py-2.5 tabular-nums text-foreground">
                      {argent(ligne.montant, ligne.devise)}
                    </td>
                    <td className="px-5 py-2.5">
                      <span className="rounded-full border border-hairline px-2 py-0.5 text-xs text-muted-foreground">
                        {libelleStatut(ligne.statut)}
                      </span>
                    </td>
                    <td className="px-5 py-2.5 text-xs tabular-nums text-muted-foreground">
                      {dateCourte(ligne.cree)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="px-5 py-6 text-xs text-muted-foreground">{d.noTransaction}</p>
        )}
      </section>
    </div>
  );
}
