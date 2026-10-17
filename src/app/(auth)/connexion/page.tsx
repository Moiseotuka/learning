import type { Metadata } from "next";
import Link from "next/link";

import { AuthCard } from "@/components/auth/auth-card";
import { ConfigNotice } from "@/components/auth/config-notice";
import { LoginForm, type LoginNotice } from "@/components/auth/login-form";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { isSupabaseConfigured } from "@/lib/supabase/config";

const t = messages.auth;

export const metadata: Metadata = {
  title: t.loginTitle,
  robots: { index: false },
};

export default async function LoginPage(props: PageProps<"/connexion">) {
  const searchParams = await props.searchParams;
  const next =
    typeof searchParams.next === "string" ? searchParams.next : undefined;

  const notice: LoginNotice | undefined =
    searchParams.confirmation === "reussie"
      ? "confirmed"
      : searchParams.confirmation === "echec"
        ? "confirm-failed"
        : searchParams.confirmation === "motdepasse"
          ? "password-updated"
          : searchParams.erreur === "connexion"
            ? "login-failed"
            : searchParams.erreur === "google"
              ? "google-unavailable"
              : searchParams.erreur === "oauth-state"
                ? "oauth-state-used"
                : undefined;

  return (
    <AuthCard
      title={t.loginTitle}
      subtitle={t.loginSubtitle}
      footer={
        <span>
          {t.noAccount}{" "}
          <Link
            href={next ? `${links.signup}?next=${encodeURIComponent(next)}` : links.signup}
            className="font-medium text-electric hover:underline"
          >
            {t.signupLink}
          </Link>
        </span>
      }
      sorties={[
        { label: t.sortieCatalogue, href: links.catalogue },
        { label: t.backHome, href: links.home },
      ]}
    >
      {isSupabaseConfigured ? (
        <LoginForm next={next} notice={notice} />
      ) : (
        <ConfigNotice />
      )}
    </AuthCard>
  );
}
