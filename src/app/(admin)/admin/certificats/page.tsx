import { AwardIcon, Building2Icon, CalendarClockIcon, UsersIcon } from "lucide-react";

import { Carte } from "@/components/admin/carte";
import { Kpi } from "@/components/admin/graphiques";
import { TableauTriable, type Colonne } from "@/components/admin/tableau-triable";
import { messages } from "@/i18n";
import { dateCourte, heureCourte, nombre } from "@/lib/admin/libelles";
import { lireCertificats } from "@/lib/admin/stats";

const c = messages.admin.certificats;

const COLONNES: Colonne[] = [
  { cle: "titulaire", titre: c.columnHolder },
  { cle: "portee", titre: c.columnScope },
  { cle: "formation", titre: c.columnTrack },
  { cle: "delivre", titre: c.columnIssued },
  { cle: "formateur", titre: c.columnInstructor },
  { cle: "code", titre: c.columnCode },
];

/** Un certificat de « parcours complet » n'a pas le même poids qu'un certificat de niveau. */
function portee(niveau: string): string {
  return c.scopes[niveau as keyof typeof c.scopes] ?? niveau;
}

export default async function CertificatsPage() {
  const lignes = (await lireCertificats()) ?? [];

  const titulaires = new Set(lignes.map((l) => l.email || l.titulaire)).size;
  const formations = new Set(lignes.map((l) => l.formation)).size;
  const dernier = lignes[0]?.delivre ?? null;

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">{c.title}</h1>
        <p className="mt-1 max-w-2xl text-sm text-muted-foreground">{c.intro}</p>
      </header>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Kpi
          titre={c.title}
          valeur={nombre(lignes.length)}
          note={c.count(lignes.length)}
          Icon={AwardIcon}
        />
        <Kpi titre={c.holders} valeur={nombre(titulaires)} Icon={UsersIcon} />
        <Kpi titre={c.tracks} valeur={nombre(formations)} Icon={Building2Icon} />
        <Kpi
          titre={c.last}
          valeur={dernier ? dateCourte(dernier) : "—"}
          note={dernier ? c.lastNote : undefined}
          Icon={CalendarClockIcon}
        />
      </section>

      <Carte titre={c.title}>
        {lignes.length === 0 ? (
          <p className="text-sm text-muted-foreground">{c.empty}</p>
        ) : (
          <TableauTriable
            colonnes={COLONNES}
            triInitial={{ cle: "delivre", ascendant: false }}
            filtre={{ label: c.columnHolder, placeholder: c.columnHolder }}
            vide={c.none}
            resume={c.count(lignes.length)}
            lignes={lignes.map((l) => ({
              titulaire: {
                texte: l.titulaire,
                note: l.email || undefined,
                lien: l.email
                  ? `/admin/recherche?q=${encodeURIComponent(l.email)}`
                  : undefined,
              },
              portee: { texte: portee(l.niveau), valeur: l.niveau },
              formation: {
                texte: l.formation,
                note: l.intitule !== l.formation ? l.intitule : undefined,
              },
              delivre: { texte: heureCourte(l.delivre), valeur: l.delivre },
              formateur: {
                texte: l.formateur ?? "—",
                note: l.academie ?? undefined,
              },
              code: {
                texte: l.code,
                lien: `/verifier?code=${encodeURIComponent(l.code)}`,
              },
            }))}
          />
        )}
      </Carte>
    </div>
  );
}
