import { AppHeader } from "@/components/layout/app-header";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <AppHeader showAuth={false} />
      <main className="flex-1">{children}</main>
    </>
  );
}
