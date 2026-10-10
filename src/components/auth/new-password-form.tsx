"use client";

import { Loader2Icon } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useActionState } from "react";

import { AuthField } from "@/components/auth/auth-field";
import { ConfigNotice } from "@/components/auth/config-notice";
import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { updatePassword } from "@/lib/actions/auth";
import { createBrowserSupabase } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";

const t = messages.auth;

type LinkState = "checking" | "ready" | "missing";

export function NewPasswordForm() {
  const [linkState, setLinkState] = useState<LinkState>("checking");
  const [state, action, pending] = useActionState(updatePassword, undefined);

  useEffect(() => {
    if (!isSupabaseConfigured) return;

    const supabase = createBrowserSupabase();
    if (!supabase) return;

    let active = true;

    supabase.auth
      .getSession()
      .then(({ data }) => {
        if (active) setLinkState(data.session ? "ready" : "missing");
      })
      .catch(() => {
        if (active) setLinkState("missing");
      });

    const { data } = supabase.auth.onAuthStateChange((_event, session) => {
      if (active && session) setLinkState("ready");
    });

    return () => {
      active = false;
      data.subscription.unsubscribe();
    };
  }, []);

  const passwordError = state?.fieldErrors?.password;
  const confirmError = state?.fieldErrors?.confirm;

  if (!isSupabaseConfigured) return <ConfigNotice />;

  if (linkState === "checking") {
    return <Notice>{t.resetChecking}</Notice>;
  }

  if (linkState === "missing") {
    return (
      <div className="space-y-4">
        <Notice tone="error">{t.noticeResetLinkInvalid}</Notice>
        <Button asChild variant="outline" className="h-11 w-full border-hairline">
          <Link href={links.forgotPassword}>{t.submitReset}</Link>
        </Button>
      </div>
    );
  }

  return (
    <form action={action} className="space-y-4">
      {state?.message ? (
        <Notice tone="error">{state.message}</Notice>
      ) : null}

      <AuthField
        id="password"
        label={t.passwordLabel}
        hint={t.passwordHint}
        error={passwordError}
      >
        <Input
          id="password"
          name="password"
          type="password"
          autoComplete="new-password"
          placeholder={t.passwordPlaceholder}
          required
          aria-invalid={Boolean(passwordError)}
          aria-describedby={passwordError ? "password-error" : "password-hint"}
          className="h-11"
        />
      </AuthField>

      <AuthField id="confirm" label={t.confirmPasswordLabel} error={confirmError}>
        <Input
          id="confirm"
          name="confirm"
          type="password"
          autoComplete="new-password"
          placeholder="••••••••"
          required
          aria-invalid={Boolean(confirmError)}
          aria-describedby={confirmError ? "confirm-error" : undefined}
          className="h-11"
        />
      </AuthField>

      <Button type="submit" disabled={pending} className="h-11 w-full">
        {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
        {t.submitNewPassword}
      </Button>
    </form>
  );
}
