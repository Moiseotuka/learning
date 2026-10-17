import type { ReactNode } from "react";

import { Coquille } from "@/components/console/coquille";
import { AppRail } from "@/components/learner/app-rail";
import { MobileTabBar } from "@/components/layout/mobile-tab-bar";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";

const t = messages.learner;

/**
 * L'espace de pilotage de l'apprenant : exactement la coquille du back-office — rail
 * d'icônes, barre du haut, contenu centré — pour que les deux interfaces se
 * reconnaissent d'un coup d'œil. La recherche du bandeau porte sur SES formations,
 * pas sur le catalogue : c'est la question qu'on se pose en ouvrant l'espace.
 */
export default async function ConsoleLayout({
  children,
}: {
  children: ReactNode;
}) {
  const user = await requireUser(links.dashboard);

  return (
    <Coquille
      rail={<AppRail />}
      bas={<MobileTabBar />}
      email={user.email}
      recherche={{
        action: "/app/formations",
        label: t.search.label,
        placeholder: t.search.placeholder,
      }}
      sortie={{ href: links.home, label: t.rail.site }}
      largeur="max-w-6xl"
    >
      {children}
    </Coquille>
  );
}
