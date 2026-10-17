import type { Metadata } from "next";
import type { ReactNode } from "react";

/** Back-office : jamais indexable, jamais crawlable. */
export const metadata: Metadata = { robots: { index: false, follow: false } };

/**
 * Le back-office a sa propre coquille (rail d'icônes, barre d'outils, recherche) posée par
 * `admin/layout.tsx`. Ce groupe ne doit donc rien ajouter : l'ancien entête du site y ferait
 * apparaître deux barres de compte superposées.
 */
export default function AdminRootLayout({ children }: { children: ReactNode }) {
  return children;
}
