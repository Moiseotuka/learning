"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { MenuIcon, SearchIcon } from "lucide-react";
import { useEffect, useState } from "react";

import { AuthActions } from "@/components/auth/auth-actions";
import { HeaderSearch } from "@/components/catalog/header-search";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { cn } from "@/lib/utils";

const t = messages;

/** Liens de second plan : la barre desktop n'a pas la place de les afficher avec
 *  le champ de recherche. Ils restent accessibles depuis le menu mobile et le pied de page. */
const SECONDARY_HREFS = ["/#communaute", "/#apropos"];
const BAR_ITEMS = t.nav.items.filter(
  (item) => !SECONDARY_HREFS.includes(item.href),
);

// L'accueil et la page formateur s'ouvrent sur un bandeau vert forêt : l'entête
// prend les mêmes tokens que le bandeau tant qu'il est posé dessus, puis
// redevient neutre dès qu'il se détache au défilement.
const FOREST_PATHS = ["/", "/formateurs"];

export function SiteHeader() {
  const pathname = usePathname();
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const forest = FOREST_PATHS.includes(pathname) && !scrolled;

  return (
    <header
      className={cn(
        "sticky top-0 z-50 w-full transition-all duration-300",
        forest && "forest",
        scrolled
          ? "bg-background border-b border-hairline shadow-sm"
          : "border-b border-transparent bg-transparent",
      )}
    >
      <div className="mx-auto flex h-16 w-full max-w-7xl items-center gap-3 px-4 sm:px-6 lg:gap-5">
        <Link href={links.home} aria-label={t.meta.title} className="shrink-0">
          <Logo />
        </Link>

        <nav
          aria-label="Navigation principale"
          className="hidden shrink-0 items-center gap-0.5 lg:flex"
        >
          {BAR_ITEMS.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="whitespace-nowrap rounded-md px-2.5 py-2 text-sm text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="ml-auto flex min-w-0 grow items-center justify-end gap-2 lg:gap-3">
          <HeaderSearch className="hidden w-40 grow md:block md:max-w-56 lg:w-56 lg:max-w-64 xl:max-w-72 2xl:max-w-80" />

          <div className="flex shrink-0 items-center gap-2">
            <Link
              href="/catalogue"
              title={t.nav.search}
              aria-label={t.nav.search}
              className="flex h-9 w-9 items-center justify-center rounded-lg border border-input bg-background/60 text-muted-foreground transition-colors hover:border-electric/50 hover:text-foreground md:hidden"
            >
              <SearchIcon className="size-4 shrink-0" aria-hidden />
            </Link>

            <ThemeToggle />

            <AuthActions />

            <Sheet open={open} onOpenChange={setOpen}>
              <SheetTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon-sm"
                  className="lg:hidden"
                  aria-label={t.nav.menu}
                >
                  <MenuIcon className="size-5" aria-hidden />
                </Button>
              </SheetTrigger>
              <SheetContent side="right" className="w-80 gap-0">
                <SheetHeader className="border-b border-border pb-4">
                  <SheetTitle>
                    <Logo />
                  </SheetTitle>
                  <SheetDescription className="sr-only">
                    Navigation mobile de easyTech
                  </SheetDescription>
                </SheetHeader>

                <div className="px-4 pt-4">
                  <HeaderSearch
                    variant="sheet"
                    onNavigate={() => setOpen(false)}
                  />
                </div>

                <nav
                  aria-label="Navigation mobile"
                  className="flex flex-col gap-1 px-4 py-4"
                >
                  {t.nav.items.map((item) => (
                    <Link
                      key={item.href}
                      href={item.href}
                      onClick={() => setOpen(false)}
                      className="rounded-md px-3 py-3 text-base text-foreground transition-colors hover:bg-muted"
                    >
                      {item.label}
                    </Link>
                  ))}
                </nav>

                <div className="mt-auto flex flex-col gap-2 border-t border-border p-4">
                  <AuthActions variant="sheet" onNavigate={() => setOpen(false)} />
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </div>
      </div>
    </header>
  );
}
