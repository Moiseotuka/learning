"use client";

import {
  GraduationCapIcon,
  LayoutDashboardIcon,
  LibraryBigIcon,
  PresentationIcon,
  SearchIcon,
  UserIcon,
} from "lucide-react";

import { RailNav, type EntreeRail } from "@/components/console/rail";
import { messages } from "@/i18n";

const t = messages.learner.rail;

/**
 * Les mêmes icônes, la même colonne, le même trait sur l'entrée active que dans le
 * back-office : un apprenant qui un jour ouvre l'administration, ou l'inverse, ne
 * découvre pas une deuxième interface. « Mes formations » vient en deuxième parce
 * que c'est la page où l'on revient quand on a oublié où on en était.
 *
 * L'entrée formateur reste visible même sans abonnement : c'est par là qu'un
 * apprenant qui a terminé un parcours découvre qu'il peut enseigner à son tour, et
 * le vérifier coûte une requête de plus sur chacune de ces pages.
 */
export function AppRail() {
  const entrees: EntreeRail[] = [
    { href: "/app", label: t.dashboard, Icon: LayoutDashboardIcon, exact: true },
    { href: "/app/formations", label: t.formations, Icon: LibraryBigIcon },
    { href: "/app/classe", label: t.classe, Icon: GraduationCapIcon },
    { href: "/catalogue", label: t.catalogue, Icon: SearchIcon },
    { href: "/app/profil", label: t.profil, Icon: UserIcon },
    { href: "/app/formateur", label: t.formateur, Icon: PresentationIcon },
  ];

  return <RailNav entrees={entrees} label={t.label} />;
}
