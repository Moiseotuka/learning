import type { Metadata } from "next";

/** Espace connecté : aucune de ces pages n'a de sens hors d'une session. */
export const metadata: Metadata = { robots: { index: false, follow: false } };

/**
 * La coquille n'est pas ici : l'apprenant qui pilote ses formations et l'apprenant
 * en pleine leçon n'ont pas les mêmes besoins. Le groupe `(console)` reprend le rail
 * et la barre du back-office ; le groupe `(immersive)` garde une page épurée, où la
 * leçon occupe tout l'écran.
 */
export default function LearnerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
