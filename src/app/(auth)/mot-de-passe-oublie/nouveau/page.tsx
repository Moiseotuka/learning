import type { Metadata } from "next";
import Link from "next/link";

import { AuthCard } from "@/components/auth/auth-card";
import { NewPasswordForm } from "@/components/auth/new-password-form";
import { links } from "@/config/site";
import { messages } from "@/i18n";

const t = messages.auth;

export const metadata: Metadata = {
  title: t.resetTitle,
  robots: { index: false },
};

const ETAPES = [t.resetStep1, t.resetStep2, t.resetStep3];

export default function NewPasswordPage() {
  return (
    <AuthCard
      title={t.resetTitle}
      subtitle={t.resetSubtitle}
      etapes={ETAPES}
      etapeActive={2}
      footer={
        <span>
          {t.hasAccount}{" "}
          <Link href={links.login} className="font-medium text-electric hover:underline">
            {t.loginLink}
          </Link>
        </span>
      }
      sorties={[
        { label: t.forgotPasswordTitle, href: links.forgotPassword },
        { label: t.sortieCatalogue, href: links.catalogue },
        { label: t.backHome, href: links.home },
      ]}
    >
      <NewPasswordForm />
    </AuthCard>
  );
}
