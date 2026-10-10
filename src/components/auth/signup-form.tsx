"use client";

import { Loader2Icon } from "lucide-react";
import { useActionState } from "react";

import { AuthField } from "@/components/auth/auth-field";
import { AuthDivider, GoogleButton } from "@/components/auth/google-button";
import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { signup } from "@/lib/actions/auth";

const t = messages.auth;

export function SignupForm({ next }: { next?: string }) {
  const [state, action, pending] = useActionState(signup, undefined);

  const fullNameError = state?.fieldErrors?.fullName;
  const emailError = state?.fieldErrors?.email;
  const passwordError = state?.fieldErrors?.password;
  const confirmError = state?.fieldErrors?.confirm;

  return (
    <>
      <form action={action} className="space-y-4">
        <input type="hidden" name="next" value={next ?? ""} />

        {state?.message ? (
          <Notice tone={state.status === "error" ? "error" : "success"}>
            {state.message}
            {state.status === "success" ? (
              <span className="mt-1 block text-xs opacity-80">{t.confirmSentHint}</span>
            ) : null}
          </Notice>
        ) : null}

        <AuthField id="fullName" label={t.fullNameLabel} error={fullNameError}>
          <Input
            id="fullName"
            name="fullName"
            autoComplete="name"
            placeholder={t.fullNamePlaceholder}
            required
            aria-invalid={Boolean(fullNameError)}
            aria-describedby={fullNameError ? "fullName-error" : undefined}
            className="h-11"
          />
        </AuthField>

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
          {t.submitSignup}
        </Button>
      </form>

      <AuthDivider />
      <GoogleButton next={next} />
    </>
  );
}
