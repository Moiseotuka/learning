import { CheckIcon } from "lucide-react";
import Link from "next/link";

import { Logo } from "@/components/logo";
import { links } from "@/config/site";
import { messages } from "@/i18n";

export function AuthCard({
  title,
  subtitle,
  children,
  footer,
  etapes,
  etapeActive = 0,
  sorties,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  /** Fil d'Ariane de la réinitialisation : celui qui a oublié son mot de passe doit
   *  savoir où il est, et surtout comment en sortir. */
  etapes?: string[];
  etapeActive?: number;
  sorties?: { label: string; href: string }[];
}) {
  return (
    <div className="flex min-h-[65vh] items-center px-4 py-16">
      <div className="mx-auto w-full max-w-md rounded-2xl border border-hairline bg-card p-6 sm:p-8">
        <Link href={links.home} aria-label={messages.meta.title} className="inline-flex">
          <Logo />
        </Link>

        {etapes?.length ? (
          <ol className="mt-6 flex items-center gap-2" aria-label={`${etapes[etapeActive]} — étape ${etapeActive + 1} sur ${etapes.length}`}>
            {etapes.map((etape, index) => {
              const faite = index < etapeActive;
              const courante = index === etapeActive;
              return (
                <li key={etape} className="flex flex-1 flex-col items-center gap-1.5">
                  <span
                    className={[
                      "flex size-7 items-center justify-center rounded-full border text-xs font-semibold",
                      faite || courante
                        ? "border-transparent bg-primary text-primary-foreground"
                        : "border-hairline text-muted-foreground",
                    ].join(" ")}
                    aria-current={courante ? "step" : undefined}
                  >
                    {faite ? <CheckIcon className="size-3.5" aria-hidden /> : index + 1}
                  </span>
                  <span
                    className={[
                      "text-center text-[11px] leading-tight",
                      courante ? "font-semibold text-foreground" : "text-muted-foreground",
                    ].join(" ")}
                  >
                    {etape}
                  </span>
                </li>
              );
            })}
          </ol>
        ) : null}

        <h1 className="mt-6 text-2xl font-semibold tracking-tight">{title}</h1>
        {subtitle ? (
          <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{subtitle}</p>
        ) : null}

        <div className="mt-6">{children}</div>

        {footer ? (
          <div className="mt-6 border-t border-hairline pt-4 text-sm text-muted-foreground">
            {footer}
          </div>
        ) : null}

        {sorties?.length ? (
          <div className="mt-4 rounded-xl bg-muted p-4">
            <p className="text-xs font-medium text-muted-foreground">
              {messages.auth.sortieBesoin}
            </p>
            <ul className="mt-2 space-y-1.5 text-sm">
              {sorties.map((sortie) => (
                <li key={sortie.href}>
                  <Link
                    href={sortie.href}
                    className="font-medium text-electric hover:underline"
                  >
                    {sortie.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ) : null}
      </div>
    </div>
  );
}
