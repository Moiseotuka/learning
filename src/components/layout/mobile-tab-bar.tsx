"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { GraduationCapIcon, HomeIcon, LibraryBigIcon, UserIcon } from "lucide-react";

import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages.nav.mobile;

/**
 * Sur téléphone, l'en-tête ne peut pas tout contenir : ces quatre destinations
 * restent accessibles depuis n'importe quelle page, y compris au milieu d'un
 * parcours, pour que l'apprenant retrouve toujours une formation.
 */
const TABS = [
  { href: "/app", label: t.home, icon: HomeIcon, exact: true },
  { href: "/catalogue", label: t.catalogue, icon: LibraryBigIcon, exact: false },
  { href: "/app/classe", label: t.classe, icon: GraduationCapIcon, exact: false },
  { href: "/app/profil", label: t.profil, icon: UserIcon, exact: true },
];

export function MobileTabBar() {
  const pathname = usePathname();

  return (
    <nav
      aria-label={t.label}
      className="fixed inset-x-0 bottom-0 z-50 border-t border-hairline bg-card/95 pb-[env(safe-area-inset-bottom)] backdrop-blur lg:hidden"
    >
      <ul className="mx-auto grid max-w-lg grid-cols-4">
        {TABS.map((tab) => {
          const active = tab.exact
            ? pathname === tab.href
            : pathname.startsWith(tab.href);
          return (
            <li key={tab.href}>
              <Link
                href={tab.href}
                aria-current={active ? "page" : undefined}
                className={cn(
                  "flex h-14 flex-col items-center justify-center gap-0.5 text-[11px] font-medium transition-colors",
                  active ? "text-electric" : "text-muted-foreground",
                )}
              >
                <tab.icon className="size-5" aria-hidden />
                {tab.label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
