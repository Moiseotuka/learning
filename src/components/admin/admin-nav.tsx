"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { messages } from "@/i18n";
import { cn } from "cn";

const t = messages.admin;

const items = [
  { href: "/admin", label: t.nav.dashboard },
  { href: "/admin/categories", label: t.nav.categories },
  { href: "/admin/tarifs", label: t.nav.pricing },
];

export function AdminNav() {
  const pathname = usePathname();

  return (
    <nav aria-label={t.title} className="flex flex-wrap gap-2">
      {items.map((item) => {
        const active =
          item.href === "/admin"
            ? pathname === item.href
            : pathname === item.href || pathname.startsWith(`${item.href}/`);

        return (
          <Link
            key={item.href}
            href={item.href}
            aria-current={active ? "page" : undefined}
            className={cn(
              "rounded-full border px-4 py-1.5 text-sm transition-colors",
              active
                ? "border-electric bg-electric text-primary-foreground"
                : "border-hairline text-muted-foreground hover:border-electric/50 hover:text-foreground",
            )}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
