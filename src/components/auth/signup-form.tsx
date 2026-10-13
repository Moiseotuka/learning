"use client";

import { Loader2Icon } from "lucide-react";
import { useActionState } from "react";

import { AuthField } from "@/components/auth/auth-field";
import { AuthDivider, GoogleButton } from "@/components/auth/google-button";
import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { fill } from "@/lib/instructor/format";
import { signup } from "@/lib/actions/auth";

const t = messages.auth;

export type SignupInvitation = {
  token: string;
  email: string;
  academy: string;
  className: string;
  trackTitle: string;
  instructorName: string;
};

export function SignupForm({
  next,
  invitation,
}: {
  next?: string;
  invitation?: SignupInvitation | null;
}) {
  const [state, action, pending] = useActionState(signup, undefined);

  const fullNameError = state?.fieldErrors?.fullName;
  const emailError = state?.fieldErrors?.email;
  const passwordError = state?.fieldErrors?.password;
  const confirmError = state?.fieldErrors?.confirm;

  return (
    <>
      {invitation ? (
        <div className="rounded-xl border border-electric/40 bg-electric/6 p-4">
          <p className="text-sm font-semibold text-foreground">
            {fill(t.invitedTitle, { academy: invitation.academy })}
          </p>
          <p className="mt-1.5 text-xs leading-relaxed text-muted-foreground">
            {fill(t.invitedBody, {
              instructor: invitation.instructorName,
              klass: invitation.className,
              track: invitation.trackTitle,
            })}
          </p>
        </div>
      ) : null}

      {state?.message ? (
        <Notice tone={state.status === "error" ? "error" : "success"}>
          {state.message}
          {state.status === "success" ? (
            <span className="mt-1 block text-xs opacity-80">{t.confirmSentHint}</span>
          ) : null}
        </Notice>
      ) : null}

      {/* Google en tête, sauf sur invitation : là l'adresse est imposée par le
          formateur et un compte Google ouvrirait une classe vide. */}
      {invitation ? null : (
        <>
          <div className={state?.message ? "mt-4" : undefined}>
            <GoogleButton next={next} label={t.googleSignup} />
          </div>
          <AuthDivider label={t.orEmail} />
        </>
      )}

      <form action={action} className="space-y-4">
        <input type="hidden" name="next" value={next ?? ""} />
        {invitation ? (
          <input type="hidden" name="invitation" value={invitation.token} />
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

        <AuthField
          id="email"
          label={invitation ? t.invitedAccountField : t.emailLabel}
          hint={invitation ? t.invitedEmailLocked : undefined}
          error={emailError}
        >
          <Input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            inputMode="email"
            placeholder={t.emailPlaceholder}
            defaultValue={invitation?.email}
            readOnly={Boolean(invitation)}
            required
            aria-invalid={Boolean(emailError)}
            aria-describedby={
              emailError ? "email-error" : invitation ? "email-hint" : undefined
            }
            className={
              invitation
                ? "h-11 bg-muted font-medium text-muted-foreground cursor-default"
                : "h-11"
            }
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
          {invitation ? t.invitedCta : t.submitSignup}
        </Button>
      </form>
    </>
  );
}
