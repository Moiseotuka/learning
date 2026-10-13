import { CheckIcon, XIcon } from "lucide-react";

import { Reveal } from "@/components/reveal";
import { Section, SectionHeading } from "@/components/section";

const comparisons = [
  {
    label: "Structure pédagogique",
    traditional: "Catalogue de vidéos sans progression",
    easyTech: "Parcours ordonnés, du Débutant au niveau Avancé",
  },
  {
    label: "Pratique",
    traditional: "Théorie uniquement, pas d'exercices",
    easyTech: "Éditeur de code intégré, quiz et exercices notés",
  },
  {
    label: "Suivi",
    traditional: "Aucune visibilité sur la progression",
    easyTech: "Progression chapitre par chapitre, scores, séries",
  },
  {
    label: "Certification",
    traditional: "Attestations sans vérification",
    easyTech: "Certificats vérifiables en ligne avec numéro unique",
  },
  {
    label: "Paiement",
    traditional: "Abonnements mensuels forcés",
    easyTech: "Paiement unique par niveau, Mobile Money accepté",
  },
  {
    label: "Langue",
    traditional: "Contenu en anglais majoritairement",
    easyTech: "Français natif, pensé pour l'Afrique francophone",
  },
];

export function Method() {
  return (
    <Section id="methode" className="bg-background">
      <SectionHeading
        eyebrow="Notre méthode"
        title="Pourquoi easyTech est différent"
        description="Nous ne vendons pas des vidéos. Nous vendons un parcours structuré qui mène à un résultat vérifiable."
      />

      <Reveal>
        <div className="overflow-hidden rounded-2xl border border-hairline bg-card">
          <div className="grid grid-cols-[1fr_1fr_1fr] border-b border-hairline bg-muted/50 text-xs font-semibold sm:text-sm">
            <div className="px-4 py-3 text-muted-foreground">Critère</div>
            <div className="border-x border-hairline px-4 py-3 text-center text-muted-foreground">
              Formation traditionnelle
            </div>
            <div className="bg-electric/10 px-4 py-3 text-center text-electric">easyTech</div>
          </div>
          {comparisons.map((row, index) => (
            <div
              key={row.label}
              className={`grid grid-cols-[1fr_1fr_1fr] ${index < comparisons.length - 1 ? "border-b border-hairline" : ""}`}
            >
              <div className="px-4 py-3.5 text-xs font-medium text-foreground sm:text-sm">
                {row.label}
              </div>
              <div className="flex items-center gap-2 border-x border-hairline px-4 py-3.5 text-xs text-muted-foreground sm:text-sm">
                <XIcon className="size-3.5 shrink-0 text-red-500" aria-hidden />
                <span className="hidden sm:inline">{row.traditional}</span>
                <span className="sm:hidden">Non</span>
              </div>
              <div className="flex items-center gap-2 bg-electric/5 px-4 py-3.5 text-xs text-foreground sm:text-sm">
                <CheckIcon className="size-3.5 shrink-0 text-emerald-500" aria-hidden />
                {row.easyTech}
              </div>
            </div>
          ))}
        </div>
      </Reveal>
    </Section>
  );
}
