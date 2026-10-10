import { AppHeader } from "@/components/layout/app-header";
import { messages } from "@/i18n";

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <AppHeader
        homeHref="/admin"
        navItems={[{ label: messages.auth.mySpace, href: "/app" }]}
      />
      <main className="flex-1">{children}</main>
    </>
  );
}
