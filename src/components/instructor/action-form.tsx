"use client";

import { Loader2Icon } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useActionState, type ReactNode } from "react";

import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import type { FormState } from "@/lib/actions/instructor";
import { successNotice } from "@/lib/instructor/success";
import { cn } from "cn";

const t = messages.formateur;

type ActionFormProps = {
  action: (
    prevState: FormState | undefined,
    formData: FormData,
  ) => Promise<FormState>;
  label: string;
  /** Champs portés sans saisie : identifiant de la classe, de l'élève… */
  hidden?: Record<string, string>;
  variant?: "default" | "outline" | "ghost" | "destructive";
  size?: "sm" | "default" | "lg";
  className?: string;
  buttonClassName?: string;
  /** Champs de saisie additionnels (titre, e-mail, code…). */
  children?: ReactNode;
  /** Navigation après succès — création de séance, souscription… */
  redirectTo?: string;
  /** Le succès doit être lu dans la page, pas sous le bouton. */
  inline?: boolean;
};

/**
 * Enveloppe commune des actions du formateur : le résultat du serveur est la
 * seule source de vérité, puis la page est rechargée pour refléter l'état réel
 * (places consommées, membre ajouté, séance ouverte).
 */
export function ActionForm({
  action,
  label,
  hidden,
  variant = "default",
  size = "sm",
  className,
  buttonClassName,
  children,
  redirectTo,
  inline = true,
}: ActionFormProps) {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const [state, formAction, pending] = useActionState<
    FormState | undefined,
    FormData
  >(action, undefined);

  const succeeded = state?.status === "success";
  const message = succeeded
    ? (state.message ?? successNotice(state.notice))
    : state?.message;

  useEffect(() => {
    if (!succeeded) return;
    formRef.current?.reset();
    if (redirectTo) router.push(redirectTo);
    router.refresh();
    // `state` ne change qu'à la soumission suivante : un seul effet par succès.
  }, [succeeded, state, redirectTo, router]);

  return (
    <form ref={formRef} action={formAction} className={cn("min-w-0", className)}>
      {hidden
        ? Object.entries(hidden).map(([name, value]) => (
            <input key={name} type="hidden" name={name} value={value} />
          ))
        : null}
      <div
        className={cn(
          "flex flex-wrap items-center gap-2",
          children && "w-full",
        )}
      >
        {children}
        <Button
          type="submit"
          variant={variant}
          size={size}
          disabled={pending}
          className={cn("shrink-0", buttonClassName)}
        >
          {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
          {pending ? t.paying : label}
        </Button>
      </div>

      {inline && state && message ? (
        <div className="mt-2">
          <Notice tone={succeeded ? "success" : "error"}>{message}</Notice>
        </div>
      ) : null}
    </form>
  );
}
