import type { ReactNode } from "react";

import { AdminNav } from "@/components/admin/admin-nav";
import { links, site } from "@/config/site";
import { messages } from "@/i18n";
import { requireAdmin } from "@/lib/auth/dal";

const t = messages.admin;

export default async function AdminLayout({
  children,
}: {
  children: ReactNode;
}) {
  await requireAdmin(links.admin);

  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
      <header className="border-b border-hairline pb-6">
        <p className="text-xs font-semibold uppercase tracking-wider text-electric">
          {site.name} · {t.title}
        </p>
        <h1 className="mt-2 text-2xl font-semibold tracking-tight text-foreground">
          {t.title}
        </h1>
        <p className="mt-2 max-w-2xl text-sm leading-relaxed text-muted-foreground">
          {t.subtitle}
        </p>
        <div className="mt-5">
          <AdminNav />
        </div>
      </header>
      <div className="pt-6">{children}</div>
    </div>
  );
}
