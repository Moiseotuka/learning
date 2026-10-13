import type { Metadata } from "next";
import Link from "next/link";

import { AuthCard } from "@/components/auth/auth-card";
import { ConfigNotice } from "@/components/auth/config-notice";
import { Notice } from "@/components/auth/notice";
import { SignupForm } from "@/components/auth/signup-form";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { sanitizeInternalPath } from "@/lib/auth/validation";
import { fill } from "@/lib/instructor/format";
import { getInvitation } from "@/lib/instructor/queries";
import { findAccountByEmail } from "@/lib/supabase/admin";
import { isSupabaseConfigured } from "@/lib/supabase/config";

const t = messages.auth;

export const metadata: Metadata = {
  title: t.signupTitle,
  robots: { index: false },
};

export default async function SignupPage({
  searchParams,
}: {
  searchParams: Promise<{ invitation?: string; next?: string }>;
}) {
  const params = await searchParams;
  const token = typeof params.invitation === "string" ? params.invitation : "";
  const invitation = token ? await getInvitation(token) : null;

  // Une invitation porte son propre chemin : l'élève n'a rien à chercher après
  // la confirmation de son compte, il tombe dans la classe de son formateur.
  const classPath = token ? `/app/classe?invitation=${encodeURIComponent(token)}` : null;
  const next =
    classPath ?? sanitizeInternalPath(typeof params.next === "string" ? params.next : null);

  // Le lien a pu devancer une inscription déjà faite : inutile de créer un
  // doublon, la connexion suffit à ouvrir la classe.
  const existing = invitation ? await findAccountByEmail(invitation.email) : null;
  const settled = Boolean(existing?.confirmed);

  return (
    <AuthCard
      title={invitation ? fill(t.invitedTitle, { academy: invitation.academy || t.signupTitle }) : t.signupTitle}
      subtitle={t.signupSubtitle}
      footer={
        <span>
          {t.hasAccount}{" "}
          <Link
            href={next ? `${links.login}?next=${encodeURIComponent(next)}` : links.login}
            className="font-medium text-electric hover:underline"
          >
            {t.loginLink}
          </Link>
        </span>
      }
    >
      {!isSupabaseConfigured ? (
        <ConfigNotice />
      ) : settled && invitation ? (
        <div className="space-y-4">
          <Notice tone="info">{t.invitedAccountExists}</Notice>
          <Link
            href={`${links.login}?next=${encodeURIComponent(classPath ?? links.dashboard)}`}
            className="inline-flex h-11 w-full items-center justify-center rounded-xl bg-electric px-5 text-sm font-semibold text-white"
          >
            {t.invitedLogin}
          </Link>
        </div>
      ) : (
        <>
          {token && !invitation ? <Notice tone="error">{t.invitedExpired}</Notice> : null}
          <SignupForm
            next={next ?? undefined}
            invitation={
              invitation
                ? {
                    token,
                    email: invitation.email,
                    academy: invitation.academy,
                    className: invitation.className,
                    trackTitle: invitation.trackTitle,
                    instructorName: invitation.instructorName,
                  }
                : null
            }
          />
        </>
      )}
    </AuthCard>
  );
}
