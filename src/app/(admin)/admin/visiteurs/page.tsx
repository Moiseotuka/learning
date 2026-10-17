import { EyeIcon, SmartphoneIcon, TrendingUpIcon } from "lucide-react";

import { Kpi } from "@/components/admin/graphiques";
import { Carte, NavPeriode, periodeDemandee } from "@/components/admin/carte";
import { TableauTriable, type Cellule, type Colonne } from "@/components/admin/tableau-triable";
import { messages } from "@/i18n";
import {
  heureCourte,
  nomAppareil,
  nomCanal,
  nomMedium,
  nomPays,
  nombre,
} from "@/lib/admin/libelles";
import { lireTrafic, lireVisitesRecentes } from "@/lib/admin/stats";

const v = messages.admin.visiteurs;
const d = messages.admin.dashboard;

const COLONNES_CANAUX: Colonne[] = [
  { cle: "canal", titre: v.columnSource },
  { cle: "medium", titre: v.columnMedium },
  { cle: "visiteurs", titre: v.columnVisitors, nombre: true },
  { cle: "vues", titre: v.columnViews, nombre: true },
];

const COLONNES_APPAREILS: Colonne[] = [
  { cle: "appareil", titre: v.columnAppareil },
  { cle: "visiteurs", titre: v.columnVisitors, nombre: true },
  { cle: "vues", titre: v.columnViews, nombre: true },
];

const COLONNES_PAYS: Colonne[] = [
  { cle: "pays", titre: v.columnPays },
  { cle: "visiteurs", titre: v.columnVisitors, nombre: true },
];

const COLONNES_PAGES: Colonne[] = [
  { cle: "page", titre: v.columnPage },
  { cle: "vues", titre: v.columnViews, nombre: true },
  { cle: "visiteurs", titre: v.columnVisitors, nombre: true },
];

const COLONNES_JOURS: Colonne[] = [
  { cle: "jour", titre: v.columnDay },
  { cle: "vues", titre: v.columnViews, nombre: true },
  { cle: "visiteurs", titre: v.columnVisitors, nombre: true },
  { cle: "inscrits", titre: v.columnSignups, nombre: true },
];

const COLONNES_ARRIVEES: Colonne[] = [
  { cle: "heure", titre: v.columnHeure },
  { cle: "canal", titre: v.columnSource },
  { cle: "campagne", titre: v.columnCampagne },
  { cle: "page", titre: v.columnPage },
  { cle: "appareil", titre: v.columnAppareil },
  { cle: "pays", titre: v.columnPays },
];

function texte(valeur: string): Cellule {
  return { texte: valeur };
}

function compteur(valeur: number): Cellule {
  return { texte: nombre(valeur), valeur };
}

export default async function VisiteursPage({
  searchParams,
}: {
  searchParams: Promise<{ periode?: string }>;
}) {
  const { periode } = await searchParams;
  const [trafic, recentes] = await Promise.all([
    lireTrafic(periodeDemandee(periode)),
    lireVisitesRecentes(50),
  ]);

  const jours = trafic?.parJour ?? [];
  const telephone = trafic?.parAppareil.find((l) => l.appareil === "telephone");
  const partTelephone =
    telephone && trafic && trafic.visiteurs > 0
      ? `${Math.round((telephone.visiteurs / trafic.visiteurs) * 100)} %`
      : "—";
  const premiereSource = trafic?.parSource[0];

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-foreground">{v.title}</h1>
          <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{v.intro}</p>
        </div>
        <NavPeriode
          base="/admin/visiteurs"
          choisie={periodeDemandee(periode)}
          label={d.periods}
          libelles={d.periodLabels}
        />
      </header>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
        <Kpi
          titre={v.today}
          valeur={nombre(jours.length ? jours[jours.length - 1].visiteurs : 0)}
          note={v.todayNote}
          Icon={EyeIcon}
        />
        <Kpi titre={d.visitors} valeur={nombre(trafic?.visiteurs)} Icon={TrendingUpIcon} />
        <Kpi titre={d.pageViews} valeur={nombre(trafic?.vues)} Icon={EyeIcon} />
        <Kpi
          titre={v.topSource}
          valeur={premiereSource ? nomCanal(premiereSource.source) : "—"}
          note={
            premiereSource
              ? `${nombre(premiereSource.visiteurs)} ${v.columnVisitors.toLowerCase()}`
              : undefined
          }
          Icon={TrendingUpIcon}
        />
        <Kpi titre={v.phoneShare} valeur={partTelephone} Icon={SmartphoneIcon} />
      </section>

      <Carte titre={v.bySourceTitle} intro={v.bySourceIntro}>
        <TableauTriable
          colonnes={COLONNES_CANAUX}
          triInitial={{ cle: "visiteurs", ascendant: false }}
          vide={v.noData}
          lignes={(trafic?.parSource ?? []).map((l) => ({
            canal: texte(nomCanal(l.source)),
            medium: texte(nomMedium(l.medium)),
            visiteurs: compteur(l.visiteurs),
            vues: compteur(l.vues),
          }))}
        />
      </Carte>

      <section className="grid gap-4 lg:grid-cols-2">
        <Carte titre={v.byDeviceTitle} intro={v.byDeviceIntro}>
          <TableauTriable
            colonnes={COLONNES_APPAREILS}
            triInitial={{ cle: "visiteurs", ascendant: false }}
            vide={v.noData}
            lignes={(trafic?.parAppareil ?? []).map((l) => ({
              appareil: texte(nomAppareil(l.appareil)),
              visiteurs: compteur(l.visiteurs),
              vues: compteur(l.vues),
            }))}
          />
        </Carte>

        <Carte titre={v.byCountryTitle}>
          <TableauTriable
            colonnes={COLONNES_PAYS}
            triInitial={{ cle: "visiteurs", ascendant: false }}
            vide={v.noData}
            lignes={(trafic?.pays ?? []).map((l) => ({
              pays: texte(nomPays(l.pays)),
              visiteurs: compteur(l.visiteurs),
            }))}
          />
        </Carte>
      </section>

      <Carte titre={v.pagesTitle} intro={v.pagesIntro}>
        <TableauTriable
          colonnes={COLONNES_PAGES}
          triInitial={{ cle: "vues", ascendant: false }}
          vide={v.noData}
          lignes={(trafic?.pages ?? []).map((l) => ({
            page: texte(l.path),
            vues: compteur(l.vues),
            visiteurs: compteur(l.visiteurs),
          }))}
        />
      </Carte>

      <Carte titre={v.daysTitle}>
        <TableauTriable
          colonnes={COLONNES_JOURS}
          triInitial={{ cle: "jour", ascendant: false }}
          vide={v.noData}
          lignes={jours.map((l) => ({
            jour: texte(l.jour),
            vues: compteur(l.vues),
            visiteurs: compteur(l.visiteurs),
            inscrits: compteur(l.inscrits),
          }))}
        />
      </Carte>

      <Carte titre={v.recentTitle} intro={v.recentIntro}>
        <TableauTriable
          colonnes={COLONNES_ARRIVEES}
          triInitial={{ cle: "heure", ascendant: false }}
          vide={v.noData}
          lignes={(recentes ?? []).map((l) => ({
            heure: { texte: heureCourte(l.vue), valeur: l.vue },
            canal: { texte: nomCanal(l.source), note: l.connectee ? v.connecte : undefined },
            campagne: texte(l.campagne || "—"),
            page: texte(l.path),
            appareil: texte(nomAppareil(l.appareil)),
            pays: texte(l.pays ? nomPays(l.pays) : "—"),
          }))}
        />
        <p className="mt-3 text-xs text-muted-foreground">{v.noteVie}</p>
      </Carte>
    </div>
  );
}
