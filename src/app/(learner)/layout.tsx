import type { Metadata } from "next";

import { AppHeader } from "@/components/layout/app-header";
import { messages } from "@/i18n";

/** Espace connecté : aucune de ces pages n'a de sens hors d'une session. */
export const metadata: Metadata = { robots: { index: false, follow: false } };

export default function LearnerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <AppHeader
        navItems={[
          { label: messages.nav.catalogue, href: "/catalogue" },
          { label: messages.learner.profil.title, href: "/app/profil" },
        ]}
      />
      <main className="flex-1">{children}</main>
    </>
  );
}
