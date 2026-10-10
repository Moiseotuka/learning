import type { Metadata } from "next";
import Link from "next/link";

import { AuthCard } from "@/components/auth/auth-card";
import { ConfigNotice } from "@/components/auth/config-notice";
import { SignupForm } from "@/components/auth/signup-form";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { isSupabaseConfigured } from "@/lib/supabase/config";

const t = messages.auth;

export const metadata: Metadata = {
  title: t.signupTitle,
  robots: { index: false },
};

export default function SignupPage() {
  return (
    <AuthCard
      title={t.signupTitle}
      subtitle={t.signupSubtitle}
      footer={
        <span>
          {t.hasAccount}{" "}
          <Link href={links.login} className="font-medium text-electric hover:underline">
            {t.loginLink}
          </Link>
        </span>
      }
    >
      {isSupabaseConfigured ? <SignupForm /> : <ConfigNotice />}
    </AuthCard>
  );
}
