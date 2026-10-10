import Link from "next/link";

import { Logo } from "@/components/logo";
import { links } from "@/config/site";
import { messages } from "@/i18n";

export function AuthCard({
  title,
  subtitle,
  children,
  footer,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
}) {
  return (
    <div className="flex min-h-[65vh] items-center px-4 py-16">
      <div className="mx-auto w-full max-w-md rounded-2xl border border-hairline bg-card p-6 sm:p-8">
        <Link href={links.home} aria-label={messages.meta.title} className="inline-flex">
          <Logo />
        </Link>

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
      </div>
    </div>
  );
}
