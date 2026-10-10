import type { Metadata } from "next";
import Link from "next/link";

import { AuthCard } from "@/components/auth/auth-card";
import { Button } from "@/components/ui/button";
import { links } from "@/config/site";
import { messages } from "@/i18n";

const t = messages.auth;

export const metadata: Metadata = {
  title: t.confirmationTitle,
  robots: { index: false },
};

export default async function ConfirmationPage(
  props: PageProps<"/auth/confirmation">,
) {
  const searchParams = await props.searchParams;
  const success = searchParams.statut !== "echec";

  return (
    <AuthCard
      title={success ? t.confirmationTitle : t.confirmationFailedTitle}
      subtitle={success ? t.confirmationText : t.confirmationFailedText}
    >
      <div className="flex flex-col gap-3">
        <Button asChild className="h-11">
          <Link href={success ? links.dashboard : links.signup}>
            {success ? t.mySpace : t.signupLink}
          </Link>
        </Button>
        <Button asChild variant="outline" className="h-11 border-hairline">
          <Link href={links.login}>{t.loginLink}</Link>
        </Button>
      </div>
    </AuthCard>
  );
}
