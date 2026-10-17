import { ExternalLinkIcon, SearchIcon } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";

import { AuthActions } from "@/components/auth/auth-actions";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import { cn } from "@/lib/utils";

/**
 * Coquille commune au back-office et à l'espace apprenant : rail d'icônes fixe à
 * gauche, barre d'outils collante en haut (recherche, accès au site, thème,
 * compte), contenu qui défile au centre.
 *
 * Les deux espaces partagent la même mécanique volontairement : une personne qui a
 * appris l'un retrouve l'autre sans avoir à réapprendre, et le titre de chaque page
 * vit dans la page elle-même pour que la barre du haut garde une taille constante.
 */
export function Coquille({
  rail,
  mobile,
  bas,
  email,
  recherche,
  sortie,
  children,
  largeur = "max-w-7xl",
}: {
  /** Rail d'icônes (composant client) passé en enfant : il lit l'URL courante. */
  rail: ReactNode;
  /** Variante téléphone du rail, ou barre d'onglets basse. */
  mobile?: ReactNode;
  /** Barre d'onglets collée en bas de l'écran sur téléphone. */
  bas?: ReactNode;
  email?: string | null;
  recherche?: { action: string; label: string; placeholder: string } | null;
  /** Lien de sortie, par exemple « Voir le site ». */
  sortie?: { href: string; label: string } | null;
  children: ReactNode;
  largeur?: string;
}) {
  return (
    <div className="min-h-screen lg:pl-20">
      {rail}

      <header className="sticky top-0 z-30 border-b border-hairline bg-background/95 backdrop-blur">
        <div className={`mx-auto flex h-14 w-full ${largeur} items-center gap-3 px-4 sm:px-6`}>
          <Logo compact className="lg:hidden" />

          {recherche ? (
            <form
              action={recherche.action}
              method="get"
              role="search"
              className="hidden max-w-md flex-1 sm:block"
            >
              <label className="relative block">
                <span className="sr-only">{recherche.label}</span>
                <SearchIcon
                  aria-hidden
                  className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                />
                <input
                  type="search"
                  name="q"
                  placeholder={recherche.placeholder}
                  className="h-9 w-full rounded-full border border-hairline bg-card pl-9 pr-3 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-electric"
                />
              </label>
            </form>
          ) : null}

          <div className="ml-auto flex items-center gap-1 sm:gap-2">
            {sortie ? (
              <Link
                href={sortie.href}
                className="hidden items-center gap-1.5 rounded-full border border-hairline px-3 py-1.5 text-xs font-medium text-muted-foreground transition-colors hover:border-electric/50 hover:text-foreground sm:inline-flex"
              >
                <ExternalLinkIcon className="size-3.5" aria-hidden />
                {sortie.label}
              </Link>
            ) : null}
            <ThemeToggle />
            {email ? (
              <span className="hidden max-w-40 truncate text-xs text-muted-foreground md:inline">
                {email}
              </span>
            ) : null}
            <AuthActions />
          </div>
        </div>
      </header>

      {mobile ? <div className="px-4 sm:px-6 lg:hidden">{mobile}</div> : null}

      <main
        className={cn(
          "mx-auto w-full px-4 py-6 sm:px-6",
          largeur,
          bas && "pb-20 lg:pb-6",
        )}
      >
        {children}
      </main>

      {bas}
    </div>
  );
}
