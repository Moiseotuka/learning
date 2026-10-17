import type { ReactNode } from "react";

import { AdminRail, AdminRailMobile } from "@/components/admin/admin-rail";
import { Coquille } from "@/components/console/coquille";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { requireAdmin } from "@/lib/auth/dal";

const t = messages.admin;

/**
 * Coquille du back-office : celle que l'espace apprenant reprend à l'identique.
 * Le titre et la description de chaque page vivent dans la page elle-même, pour que la barre
 * du haut reste à taille constante quelle que soit la section.
 */
export default async function AdminLayout({
  children,
}: {
  children: ReactNode;
}) {
  const user = await requireAdmin(links.admin);

  return (
    <Coquille
      rail={<AdminRail />}
      mobile={<AdminRailMobile />}
      email={user.email}
      recherche={{
        action: "/admin/recherche",
        label: t.searchLabel,
        placeholder: t.searchPlaceholder,
      }}
      sortie={{ href: links.home, label: t.viewSite }}
    >
      {children}
    </Coquille>
  );
}
