"use client";

import Link from "next/link";
import { MailIcon } from "lucide-react";

import { Logo } from "@/components/logo";
import { Separator } from "@/components/ui/separator";
import { links, site } from "@/config/site";
import { messages } from "@/i18n";

const t = messages;

export function SiteFooter() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-hairline bg-elevated">
      <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:px-6">
        <div className="grid gap-10 lg:grid-cols-12">
          <div className="lg:col-span-4">
            <Link href={links.home} aria-label={site.name}>
              <Logo />
            </Link>
            <p className="mt-4 max-w-xs text-sm leading-relaxed text-muted-foreground">
              {t.footer.tagline}
            </p>

            <p className="mt-6 flex items-center gap-2 text-xs text-muted-foreground">
              <MailIcon className="size-3.5 shrink-0 text-electric" aria-hidden />
              {t.footer.paymentNote}
            </p>
          </div>

          <div className="grid grid-cols-2 gap-8 sm:grid-cols-4 lg:col-span-8">
            {t.footer.columns.map((column) => (
              <nav key={column.title} aria-label={column.title}>
                <h3 className="text-sm font-semibold text-foreground">{column.title}</h3>
                <ul className="mt-4 space-y-2.5">
                  {column.links.map((link) => (
                    <li key={link.label}>
                      <Link
                        href={link.href}
                        className="text-sm text-muted-foreground transition-colors hover:text-foreground"
                      >
                        {link.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </nav>
            ))}
          </div>
        </div>

        <Separator className="my-10 bg-hairline" />

        <div className="flex flex-col gap-3 text-xs text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
          <p>{t.footer.rights(year)}</p>
          <p>{t.footer.madeIn}</p>
        </div>
      </div>
    </footer>
  );
}
