import { AppHeader } from "@/components/layout/app-header";
import { messages } from "@/i18n";

export default function LearnerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <AppHeader
        homeHref="/app"
        navItems={[
          { label: messages.nav.catalogue, href: "/catalogue" },
          { label: messages.learner.profil.title, href: "/app/profil" },
        ]}
      />
      <main className="flex-1">{children}</main>
    </>
  );
}
