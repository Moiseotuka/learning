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

export default function ForgotPasswordPage() {
  return (
    <AuthCard
      title={t.forgotPasswordTitle}
      subtitle={t.forgotPasswordSubtitle}
      footer={
        <span>
          {t.hasAccount}{" "}
          <Link href={links.login} className="font-medium text-electric hover:underline">
            {t.loginLink}
          </Link>
        </span>
      }
    >
      {isSupabaseConfigured ? <ForgotPasswordForm /> : <ConfigNotice />}
    </AuthCard>
  );
}
