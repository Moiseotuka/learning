import type { Metadata } from "next";
import type { ReactNode } from "react";

import { AppHeader } from "@/components/layout/app-header";
import { MobileTabBar } from "@/components/layout/mobile-tab-bar";
import { links } from "@/config/site";
import { messages } from "@/i18n";

const t = messages.nav;

/** Ces pages ne sont pas indexables, et la leçon n'a de sens qu'en session. */
export const metadata: Metadata = { robots: { index: false, follow: false } };

/**
 * Les pages de lecture — un parcours, une séance en direct, l'espace formateur —
 * gardent une coquille effacée : pas de rail qui rogne la largeur de la leçon, et
 * un en-tête qui disparaît dès qu'on entre dans un chapitre. Le rail de `(console)`
 * sert aux pages où l'on choisit, ici on est déjà en train d'apprendre.
 */
export default function ImmersiveLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <AppHeader
        navItems={[
          { label: t.catalogue, href: links.catalogue },
          { label: messages.learner.profil.title, href: "/app/profil" },
        ]}
      />
      <main className="flex-1 pb-14 lg:pb-0">{children}</main>
      <MobileTabBar />
    </>
  );
}
