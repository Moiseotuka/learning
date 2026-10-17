import type { Metadata } from "next";
import Link from "next/link";

import { AuthCard } from "@/components/auth/auth-card";
import { ConfigNotice } from "@/components/auth/config-notice";
import { ForgotPasswordForm } from "@/components/auth/forgot-password-form";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { isSupabaseConfigured } from "@/lib/supabase/config";

const t = messages.auth;

export const metadata: Metadata = {
  title: t.forgotPasswordTitle,
  robots: { index: false },
};

const ETAPES = [t.resetStep1, t.resetStep2, t.resetStep3];

export default function ForgotPasswordPage() {
  return (
    <AuthCard
      title={t.forgotPasswordTitle}
      subtitle={t.forgotPasswordSubtitle}
      etapes={ETAPES}
      etapeActive={0}
      footer={
        <span>
          {t.hasAccount}{" "}
          <Link href={links.login} className="font-medium text-electric hover:underline">
            {t.loginLink}
          </Link>
        </span>
      }
      sorties={[
        { label: t.sortieCompte, href: links.login },
        { label: t.sortieCatalogue, href: links.catalogue },
        { label: t.backHome, href: links.home },
      ]}
    >
      {isSupabaseConfigured ? <ForgotPasswordForm /> : <ConfigNotice />}
      <p className="mt-4 text-xs leading-relaxed text-muted-foreground">{t.resetSpam}</p>
    </AuthCard>
  );
}
