"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

import { AuthActions } from "@/components/auth/auth-actions";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import { messages } from "@/i18n";
import { links } from "@/config/site";
import { cn } from "@/lib/utils";

const t = messages;

export type AppHeaderItem = { label: string; href: string };

export function AppHeader({
  navItems,
  showAuth = true,
}: {
  navItems?: AppHeaderItem[];
  showAuth?: boolean;
}) {
  const pathname = usePathname();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  if (pathname.startsWith("/app/parcours")) return null;

  return (
    <header
      className={cn(
        "sticky top-0 z-50 w-full transition-all duration-300",
        scrolled
          ? "bg-background border-b border-hairline shadow-sm"
          : "border-b border-transparent bg-transparent",
      )}
    >
      <div className="mx-auto flex h-16 w-full max-w-6xl items-center gap-3 px-4 sm:px-6 lg:gap-6">
        <Link href={links.home} aria-label={t.meta.title} className="shrink-0">
          <Logo />
        </Link>

        {navItems && navItems.length > 0 ? (
          <nav
            aria-label="Navigation"
            className="hidden min-w-0 items-center gap-0.5 sm:flex"
          >
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="whitespace-nowrap rounded-md px-2.5 py-2 text-sm text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
              >
                {item.label}
              </Link>
            ))}
          </nav>
        ) : null}

        <div className="ml-auto flex shrink-0 items-center gap-2">
          <ThemeToggle />
          {showAuth ? <AuthActions /> : null}
        </div>
      </div>
    </header>
  );
}
