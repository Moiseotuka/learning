"use client";

import { ExternalLinkIcon, Loader2Icon, ShieldCheckIcon } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { messages } from "@/i18n";
import { cn } from "cn";

const t = messages.payment;

const POLL_INTERVAL_MS = 3000;

export const PAYMENT_RESULT_MESSAGE = "easylearn:payment-result";

type StatusResponse = {
  ok?: boolean;
  paid?: boolean;
  status?: string;
  redirect?: string | null;
  reason?: string;
};

type CheckoutDialogProps = {
  url: string;
  purchaseId: string;
  /** Paiement confirmé : fermer le dialogue et ouvrir le parcours. */
  onSuccess: () => void;
  onClose: () => void;
};

/**
 * Boîte de dialogue contenant la page de paiement nyole (iframe) :
 * l'apprenant ne quitte jamais easyLearn.
 * La confirmation vient, dans l'ordre :
 *  1. d'un message posté par /paiement/retour (page atteinte à l'issue du
 *     paiement, dans l'iframe ou une fenêtre détachée) ;
 *  2. du sondage de /api/payments/status, qui vérifie le statut côté serveur
 *     et valide la purchase — source de vérité (le webhook nyole confirme
 *     ensuite de façon asynchrone).
 */
export function CheckoutDialog({
  url,
  purchaseId,
  onSuccess,
  onClose,
}: CheckoutDialogProps) {
  const [checking, setChecking] = useState(false);
  const doneRef = useRef(false);
  const onSuccessRef = useRef(onSuccess);

  useEffect(() => {
    onSuccessRef.current = onSuccess;
  }, [onSuccess]);

  const verify = useCallback(async () => {
    if (doneRef.current) return;
    setChecking(true);
    try {
      const response = await fetch(
        `/api/payments/status?purchase=${encodeURIComponent(purchaseId)}`,
        { cache: "no-store" },
      );
      const data = (await response.json().catch(() => null)) as
        | StatusResponse
        | null;
      if (data?.paid && !doneRef.current) {
        doneRef.current = true;
        onSuccessRef.current();
      }
    } catch {
      /* réseau indisponible : le sondage suivant réessaiera */
    } finally {
      setChecking(false);
    }
  }, [purchaseId]);

  // 1. Message de la page de retour (posté par la page enfant).
  useEffect(() => {
    function onMessage(event: MessageEvent) {
      if (event.origin !== window.location.origin) return;
      const data = event.data as
        | { type?: string; purchaseId?: string }
        | null;
      if (data?.type !== PAYMENT_RESULT_MESSAGE) return;
      if (data.purchaseId && data.purchaseId !== purchaseId) return;
      void verify();
    }
    window.addEventListener("message", onMessage);
    return () => window.removeEventListener("message", onMessage);
  }, [purchaseId, verify]);

  // 2. Sondage périodique du statut côté serveur.
  useEffect(() => {
    let active = true;
    const tick = () => {
      if (!active || doneRef.current) return;
      void verify();
    };
    void verify();
    const timer = setInterval(tick, POLL_INTERVAL_MS);
    return () => {
      active = false;
      clearInterval(timer);
    };
  }, [verify]);

  return (
    <Dialog open onOpenChange={(open) => (!open ? onClose() : undefined)}>
      <DialogContent fullscreen>
        <DialogHeader className="border-b border-hairline px-4 py-3 pr-12 text-left">
          <DialogTitle>{t.checkoutTitle}</DialogTitle>
          <DialogDescription className="text-xs">
            {t.checkoutIntro}
          </DialogDescription>
        </DialogHeader>

        <div className="relative min-h-0 w-full flex-1 bg-muted">
          <iframe
            src={url}
            title={t.checkoutTitle}
            className="h-full w-full border-0 bg-white"
            allow="payment *; clipboard-write"
          />
          <div
            className={cn(
              "pointer-events-none absolute inset-x-0 bottom-0 flex items-center justify-center gap-2 bg-background/90 px-4 py-2 text-xs text-muted-foreground transition-opacity",
              checking ? "opacity-100" : "opacity-0",
            )}
          >
            <Loader2Icon className="size-3.5 animate-spin" aria-hidden />
            {t.checkoutChecking}
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-hairline px-4 py-3">
          <p className="flex min-w-0 items-start gap-1.5 text-xs leading-relaxed text-muted-foreground">
            <ShieldCheckIcon
              className="mt-0.5 size-3.5 shrink-0 text-vivid"
              aria-hidden
            />
            {t.paySecureHint}
          </p>
          <div className="flex shrink-0 gap-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="h-9 px-3"
              onClick={() =>
                window.open(url, "_blank", "noopener,noreferrer")
              }
            >
              <ExternalLinkIcon aria-hidden />
              {t.checkoutNewWindow}
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="h-9 px-3"
              data-testid="checkout-close"
              onClick={onClose}
            >
              {t.returnClose}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
