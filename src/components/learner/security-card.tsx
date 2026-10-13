"use client";

import { Loader2Icon, LockIcon } from "lucide-react";
import { useActionState } from "react";

import { AuthField } from "@/components/auth/auth-field";
import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { updatePassword } from "@/lib/actions/profil";

const t = messages.learner.profil.security;

export function SecurityCard({ managedByProvider }: { managedByProvider: boolean }) {
  const [state, action, pending] = useActionState(updatePassword, undefined);

  return (
    <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
      <p className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-electric">
        <LockIcon className="size-4" aria-hidden />
        {t.title}
      </p>
      <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
        {managedByProvider ? t.oauthHint : t.intro}
      </p>

      {managedByProvider ? null : (
        <form action={action} className="mt-4 space-y-4">
          <AuthField
            id="new-password"
            label={t.newPassword}
            hint={t.hint}
            error={state?.fieldErrors?.password}
          >
            <Input
              id="new-password"
              name="password"
              type="password"
              autoComplete="new-password"
              minLength={8}
              required
              aria-invalid={Boolean(state?.fieldErrors?.password)}
              className="h-11"
            />
          </AuthField>

          <AuthField
            id="new-password-confirm"
            label={t.confirm}
            error={state?.fieldErrors?.confirm}
          >
            <Input
              id="new-password-confirm"
              name="confirm"
              type="password"
              autoComplete="new-password"
              minLength={8}
              required
              aria-invalid={Boolean(state?.fieldErrors?.confirm)}
              className="h-11"
            />
          </AuthField>

          {state?.message ? (
            <Notice tone={state.status === "error" ? "error" : "success"}>
              {state.message}
            </Notice>
          ) : null}

          <Button type="submit" disabled={pending} className="h-11 px-5">
            {pending ? (
              <Loader2Icon className="size-4 animate-spin" aria-hidden />
            ) : null}
            {t.save}
          </Button>
        </form>
      )}
    </section>
  );
}
