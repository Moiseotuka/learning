import type { Metadata } from "next";

import { AppHeader } from "@/components/layout/app-header";
import { messages } from "@/i18n";

/** Back-office : jamais indexable, jamais crawlable. */
export const metadata: Metadata = { robots: { index: false, follow: false } };

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <AppHeader
        navItems={[{ label: messages.auth.mySpace, href: "/app" }]}
      />
      <main className="flex-1">{children}</main>
    </>
  );
}
