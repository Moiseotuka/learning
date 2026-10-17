"use client";

import {
  BarChart3Icon,
  BellRingIcon,
  LayoutDashboardIcon,
  LibraryBigIcon,
  ReceiptTextIcon,
  SearchIcon,
  ShieldCheckIcon,
  SlidersHorizontalIcon,
  UserCogIcon,
  UsersIcon,
  WalletIcon,
} from "lucide-react";

import { RailNav, RailNavMobile, type EntreeRail } from "@/components/console/rail";
import { messages } from "@/i18n";

const t = messages.admin;

/**
 * Les cinq pages de pilotage (aperçu, visiteurs, achats, comptes, recherche) viennent
 * devant, parce que c'est ce que l'admin regarde tous les jours ; la gestion du
 * catalogue suit. La mécanique, elle, est celle de l'espace apprenant.
 */
const ENTREES: EntreeRail[] = [
  { href: "/admin", label: t.rail.dashboard, Icon: LayoutDashboardIcon, exact: true },
  { href: "/admin/visiteurs", label: t.rail.visitors, Icon: BarChart3Icon, exact: false },
  { href: "/admin/achats", label: t.rail.purchases, Icon: ReceiptTextIcon, exact: false },
  { href: "/admin/utilisateurs", label: t.rail.users, Icon: UsersIcon, exact: false },
  { href: "/admin/certificats", label: t.rail.certificates, Icon: ShieldCheckIcon, exact: false },
  { href: "/admin/recherche", label: t.rail.search, Icon: SearchIcon, exact: false },
  { href: "/admin/categories", label: t.rail.catalog, Icon: LibraryBigIcon, exact: false },
  { href: "/admin/tarifs", label: t.rail.pricing, Icon: WalletIcon, exact: false },
  {
    href: "/admin/formateurs",
    label: t.rail.instructors,
    Icon: UserCogIcon,
    exact: false,
  },
  {
    href: "/admin/formateur-plans",
    label: t.rail.instructorPlans,
    Icon: SlidersHorizontalIcon,
    exact: false,
  },
  { href: "/admin/marketing", label: t.rail.marketing, Icon: BellRingIcon, exact: false },
];

export function AdminRail() {
  return <RailNav entrees={ENTREES} label={t.title} />;
}

/** Sur téléphone, le rail ne tient pas : les entrées deviennent une barre horizontale. */
export function AdminRailMobile() {
  return <RailNavMobile entrees={ENTREES} label={t.title} />;
}
