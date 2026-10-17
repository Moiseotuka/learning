import { AwardIcon, ReceiptTextIcon, TrendingUpIcon, UsersIcon } from "lucide-react";

import { Kpi } from "@/components/admin/graphiques";
import { Carte } from "@/components/admin/carte";
import { TableauTriable, type Colonne } from "@/components/admin/tableau-triable";
import { messages } from "@/i18n";
import {
  STAGNATION_JOURS,
  joursInactif,
  lireComptes,
  type Compte,
} from "@/lib/admin/stats";
import { dateCourte, nomRole, nombre } from "@/lib/admin/libelles";

const u = messages.admin.utilisateurs;
const tc = messages.common.levels;

const COLONNES: Colonne[] = [
  { cle: "compte", titre: u.columnAccount },
  { cle: "role", titre: u.columnRole },
  { cle: "etat", titre: u.columnState },
  { cle: "niveau", titre: u.columnLevel },
  { cle: "progression", titre: u.columnProgress, nombre: true },
  { cle: "certificats", titre: u.columnCertificates, nombre: true },
  { cle: "achats", titre: u.columnPurchases, nombre: true },
  { cle: "dernier", titre: u.columnLastSeen },
  { cle: "inscrit", titre: u.columnJoined },
];

/** Libellé du niveau courant ; un compte qui n'a rien ouvert n'a pas de niveau. */
function niveauDe(compte: Compte): string {
  if (!compte.niveau) return u.nothingWatched;
  return tc[compte.niveau as keyof typeof tc] ?? compte.niveau;
}

/**
 * L'état que l'admin cherche à trier : terminé, décroché, en cours, ou jamais
 * commencé. Un compte sans aucune leçon ouverte n'est pas « en retard » — il n'a
 * pas démarré, et le distinguer évite d'appeler les mauvaises personnes.
 */
function etatDe(compte: Compte): { libelle: string; rang: number } {
  if (compte.parcoursTermine) return { libelle: u.states.finished, rang: 3 };
  const jours = joursInactif(compte);
  if (!compte.dernierPas) return { libelle: u.states.idle, rang: 0 };
  if (jours >= STAGNATION_JOURS)
    return { libelle: u.states.stalled(jours), rang: 1 };
  return { libelle: u.states.active, rang: 2 };
}

function depuisDe(compte: Compte): string {
  if (!compte.dernierPas) return u.never;
  const jours = joursInactif(compte);
  return jours <= 0 ? u.today : u.daysAgo(jours);
}

export default async function UtilisateursPage() {
  const lecture = await lireComptes();
  const comptes = lecture?.comptes ?? [];

  const payants = comptes.filter((l) => l.achats > 0).length;

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">{u.title}</h1>
        <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{u.intro}</p>
      </header>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Kpi
          titre={u.columnAccount}
          valeur={nombre(lecture?.total)}
          note={lecture ? u.count(lecture.total) : undefined}
          Icon={UsersIcon}
        />
        <Kpi titre={u.paying} valeur={nombre(payants)} Icon={ReceiptTextIcon} />
        <Kpi
          titre={u.certified}
          valeur={nombre(lecture?.certifies)}
          note={u.certifiedNote}
          Icon={AwardIcon}
        />
        <Kpi
          titre={u.stalled}
          valeur={nombre(lecture?.enSouffrance)}
          note={u.stalledNote}
          Icon={TrendingUpIcon}
        />
      </section>

      <Carte titre={u.title}>
        <TableauTriable
          colonnes={COLONNES}
          triInitial={{ cle: "etat", ascendant: false }}
          filtre={{ label: u.searchLabel, placeholder: u.searchPlaceholder }}
          vide={u.none}
          resume={lecture ? u.count(lecture.total) : undefined}
          lignes={comptes.map((l) => ({
            compte: {
              texte: l.nom || l.email || "—",
              note: l.nom ? l.email || undefined : undefined,
              lien: l.email ? `/admin/recherche?q=${encodeURIComponent(l.email)}` : undefined,
            },
            role: { texte: nomRole(l.role), valeur: l.role },
            etat: { texte: etatDe(l).libelle, valeur: etatDe(l).rang },
            niveau: {
              texte: niveauDe(l),
              valeur: l.niveau ?? "",
              note: l.formation ?? undefined,
            },
            progression: {
              texte: `${l.chapitresFinis} / ${l.chapitresVus}`,
              valeur: l.chapitresFinis,
            },
            certificats: {
              texte: nombre(l.certificats),
              valeur: l.certificats,
              note: l.dernierCertificat
                ? dateCourte(l.dernierCertificat)
                : undefined,
              lien: l.certificats > 0 ? "/admin/certificats" : undefined,
            },
            achats: { texte: nombre(l.achats), valeur: l.achats },
            dernier: {
              texte: l.dernierPas ? dateCourte(l.dernierPas) : u.never,
              note: depuisDe(l),
              valeur: l.dernierPas ?? "",
            },
            inscrit: { texte: dateCourte(l.inscrit), valeur: l.inscrit },
          }))}
        />
      </Carte>
    </div>
  );
}
