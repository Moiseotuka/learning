"use client";

import { Loader2Icon } from "lucide-react";
import Link from "next/link";
import { useActionState } from "react";

import { AuthField } from "@/components/auth/auth-field";
import { AuthDivider, GoogleButton } from "@/components/auth/google-button";
import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { links } from "@/config/site";
import { messages } from "@/i18n";
import { login } from "@/lib/actions/auth";

const t = messages.auth;

export type LoginNotice =
  | "confirmed"
  | "confirm-failed"
  | "login-failed"
  | "password-updated"
  | "google-unavailable";

export function LoginForm({ next, notice }: { next?: string; notice?: LoginNotice }) {
  const [state, action, pending] = useActionState(login, undefined);

  const pageNotice =
    notice === "confirmed"
      ? t.noticeConfirmed
      : notice === "confirm-failed"
        ? t.noticeConfirmFailed
        : notice === "password-updated"
          ? t.noticePasswordUpdated
          : notice === "login-failed"
            ? t.noticeLoginFailed
            : notice === "google-unavailable"
              ? t.noticeGoogleUnavailable
              : null;

  const emailError = state?.fieldErrors?.email;
  const passwordError = state?.fieldErrors?.password;

  return (
    <>
      <form action={action} className="space-y-4">
        <input type="hidden" name="next" value={next ?? ""} />

        {pageNotice ? <Notice tone="success">{pageNotice}</Notice> : null}
        {state?.message ? (
          <Notice tone={state.status === "error" ? "error" : "success"}>
            {state.message}
          </Notice>
        ) : null}

        <AuthField id="email" label={t.emailLabel} error={emailError}>
          <Input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            inputMode="email"
            placeholder={t.emailPlaceholder}
            required
            aria-invalid={Boolean(emailError)}
            aria-describedby={emailError ? "email-error" : undefined}
            className="h-11"
          />
        </AuthField>

        <AuthField id="password" label={t.passwordLabel} error={passwordError}>
          <Input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            placeholder="••••••••"
            required
            aria-invalid={Boolean(passwordError)}
            aria-describedby={passwordError ? "password-error" : undefined}
            className="h-11"
          />
        </AuthField>

        <div className="-mt-1 text-end">
          <Link
            href={links.forgotPassword}
            className="text-xs text-muted-foreground underline-offset-4 hover:text-foreground hover:underline"
          >
            {t.forgotPassword}
          </Link>
        </div>

        <Button type="submit" disabled={pending} className="h-11 w-full">
          {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
          {t.submitLogin}
        </Button>
      </form>

      <AuthDivider />
      <GoogleButton next={next} />
    </>
  );
}
