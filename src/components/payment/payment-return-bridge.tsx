"use client";

import {
  CheckCircle2Icon,
  Loader2Icon,
  XCircleIcon,
  RotateCcwIcon,
} from "lucide-react";
import Link from "next/link";
import { useEffect } from "react";

import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { PAYMENT_RESULT_MESSAGE } from "@/components/payment/checkout-dialog";
import { cn } from "cn";

const t = messages.payment;

export type ReturnStatus = "success" | "pending" | "cancelled" | "failed";

/**
 * Fin du parcours de paiement :
 *  - informe l'onglet parent (dialogue) ou la fenêtre d'origine que la page
 *    de retour est atteinte → le dialogue déclenche aussitôt la vérification
 *    serveur du statut ;
 *  - si la page est ouverte seule (redirection top-level de nyole), elle
 *    redirige elle-même l'apprenant vers le parcours débloqué.
 */
export function PaymentReturnBridge({
  purchaseId,
  status,
  redirectUrl,
  retryUrl,
}: {
  purchaseId: string;
  status: ReturnStatus;
  redirectUrl: string;
  retryUrl: string;
}) {
  const embedded =
    typeof window !== "undefined" ? window.self !== window.top : true;

  useEffect(() => {
    const payload = {
      type: PAYMENT_RESULT_MESSAGE,
      purchaseId,
      status,
    };
    try {
      window.opener?.postMessage(payload, window.location.origin);
    } catch {
      /* pas de fenêtre d'origine */
    }
    try {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(payload, window.location.origin);
      }
    } catch {
      /* pas de parent exploitable */
    }

    if (window.self === window.top && status === "success") {
      const timer = setTimeout(() => window.location.replace(redirectUrl), 700);
      return () => clearTimeout(timer);
    }
    return undefined;
  }, [purchaseId, status, redirectUrl]);

  const tone =
    status === "success"
      ? "success"
      : status === "failed"
        ? "error"
        : "muted";

  const Icon =
    status === "success"
      ? CheckCircle2Icon
      : status === "failed"
        ? XCircleIcon
        : status === "pending"
          ? Loader2Icon
          : RotateCcwIcon;

  const message =
    status === "success"
      ? t.returnSuccess
      : status === "cancelled"
        ? t.cancelled
        : status === "failed"
          ? t.returnFailed
          : t.returnPending;

  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="w-full max-w-md rounded-2xl border border-hairline bg-card p-6 text-center">
        <span
          className={cn(
            "mx-auto grid size-12 place-items-center rounded-2xl",
            tone === "success"
              ? "bg-emerald-500/12 text-emerald-600"
              : tone === "error"
                ? "bg-destructive/10 text-destructive"
                : "bg-muted text-muted-foreground",
          )}
        >
          <Icon
            className={cn(
              "size-6",
              status === "pending" && "animate-spin",
            )}
            aria-hidden
          />
        </span>

        <h1 className="mt-4 text-lg font-semibold text-foreground">
          {t.checkoutTitle}
        </h1>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          {message}
        </p>

        <div className="mt-6 flex flex-col gap-2">
          {status === "success" ? (
            <Button asChild className="h-10 px-4">
              <Link href={redirectUrl}>{t.returnClose}</Link>
            </Button>
          ) : (
            <Button asChild className="h-10 px-4">
              <Link href={retryUrl}>{t.returnRetry}</Link>
            </Button>
          )}
          {embedded && status !== "success" ? (
            <p className="text-xs text-muted-foreground">
              {t.checkoutIntro}
            </p>
          ) : null}
        </div>
      </div>
    </main>
  );
}
