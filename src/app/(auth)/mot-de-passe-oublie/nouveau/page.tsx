import type { Metadata } from "next";

import { AuthCard } from "@/components/auth/auth-card";
import { NewPasswordForm } from "@/components/auth/new-password-form";
import { messages } from "@/i18n";

const t = messages.auth;

export const metadata: Metadata = {
  title: t.resetTitle,
  robots: { index: false },
};

export default function NewPasswordPage() {
  return (
    <AuthCard title={t.resetTitle} subtitle={t.resetSubtitle}>
      <NewPasswordForm />
    </AuthCard>
  );
}
