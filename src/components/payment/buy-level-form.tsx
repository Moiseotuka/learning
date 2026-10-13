"use client";

import { Loader2Icon } from "lucide-react";
import { useRouter } from "next/navigation";
import { useActionState, useEffect, useState } from "react";

import { Notice } from "@/components/auth/notice";
import { CheckoutDialog } from "@/components/payment/checkout-dialog";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { startCheckout, type CheckoutResult } from "@/lib/actions/payment";

const t = messages.payment;

/**
 * CTA de paiement. Le serveur décide du mode :
 *  - simulation locale → redirection immédiate vers le parcours ;
 *  - nyole → la page de paiement s'ouvre dans une boîte de dialogue (iframe)
 *    et l'apprenant reste sur easyTech.
 * Le résultat de l'action sert de source de vérité : le dialogue est ouvert
 * tant que le serveur répond `dialog` et n'est pas fermé manuellement.
 */
export function BuyLevelForm({
  categoryId,
  level,
  priceUsd,
}: {
  categoryId: string;
  level: string;
  priceUsd: number;
}) {
  const router = useRouter();
  const [state, action, pending] = useActionState<
    CheckoutResult | undefined,
    FormData
  >(startCheckout, undefined);
  const [dismissedSession, setDismissedSession] = useState<string | null>(
    null,
  );

  useEffect(() => {
    if (state?.mode === "redirect") {
      router.push(state.redirect);
    }
  }, [state, router]);

  const checkout = state?.mode === "dialog" ? state : null;
  // Tant qu'une nouvelle tentative est en vol (`pending`), le dernier résultat
  // est périmé : on garde le dialogue fermé jusqu'à la réponse du serveur.
  const dialogOpen = Boolean(
    checkout && !pending && checkout.sessionId !== dismissedSession,
  );
  const error =
    state?.mode === "error"
      ? (t.errors[state.reason as keyof typeof t.errors] ??
        t.errors.failed)
      : null;

  const succeed = () => {
    if (!checkout) return;
    setDismissedSession(checkout.sessionId);
    router.push(checkout.redirect);
    router.refresh();
  };

  return (
    <>
      <form
        action={action}
        className="mt-6"
        onSubmit={() => setDismissedSession(null)}
      >
        <input type="hidden" name="categoryId" value={categoryId} />
        <input type="hidden" name="level" value={level} />
        <Button type="submit" className="h-11 w-full px-5" disabled={pending}>
          {pending ? (
            <Loader2Icon className="animate-spin" aria-hidden />
          ) : null}
          {t.payCta} · {priceUsd} CDF
        </Button>
      </form>

      {error ? (
        <div className="mt-4">
          <Notice tone="error">{error}</Notice>
        </div>
      ) : null}

      {checkout && dialogOpen ? (
        <CheckoutDialog
          url={checkout.url}
          purchaseId={checkout.purchaseId}
          onSuccess={succeed}
          onClose={() => setDismissedSession(checkout.sessionId)}
        />
      ) : null}
    </>
  );
}
