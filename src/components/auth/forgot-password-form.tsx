"use client";

import { Loader2Icon } from "lucide-react";
import { useActionState } from "react";

import { AuthField } from "@/components/auth/auth-field";
import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { requestPasswordReset } from "@/lib/actions/auth";

const t = messages.auth;

export function ForgotPasswordForm() {
  const [state, action, pending] = useActionState(requestPasswordReset, undefined);

  const emailError = state?.fieldErrors?.email;

  return (
    <form action={action} className="space-y-4">
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

      <Button type="submit" disabled={pending} className="h-11 w-full">
        {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
        {t.submitReset}
      </Button>
    </form>
  );
}
