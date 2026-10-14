"use client";

import { Loader2Icon } from "lucide-react";
import { useActionState } from "react";

import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { consentAction } from "@/lib/actions/marketing";

const t = messages.relances;

/**
 * Le clic inverse est proposé sur le même formulaire : une désinscription sans
 * retour possible serait un piège, et l'apprenant n'a pas à se reconnecter pour
 * reprendre ses relances.
 */
export function ConsentForm({ token }: { token: string }) {
  const [state, action, pending] = useActionState(consentAction, undefined);
  const notice = state?.message;

  return (
    <form action={action} className="mt-6 space-y-4">
      <input type="hidden" name="token" value={token} />

      {notice ? (
        <Notice tone={state?.failed ? "error" : "success"}>{notice}</Notice>
      ) : null}

      <div className="flex flex-wrap gap-2">
        <Button
          type="submit"
          name="choice"
          value="out"
          className="h-11 px-5"
          disabled={pending}
        >
          {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
          {t.leave}
        </Button>
        <Button
          type="submit"
          name="choice"
          value="in"
          variant="outline"
          className="h-11 px-5"
          disabled={pending}
        >
          {t.resume}
        </Button>
      </div>
    </form>
  );
}
