import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { links } from "@/config/site";
import { PaymentReturnBridge } from "@/components/payment/payment-return-bridge";
import type { ReturnStatus } from "@/components/payment/payment-return-bridge";
import { getUser } from "@/lib/auth/dal";
import {
  CHECKOUT_CURRENCY,
  absoluteUrl,
  amountMatches,
  getNyoleSessionStatus,
} from "@/lib/payments/nyole";
import { trackNoticeUrl } from "@/lib/payments/notice";
import { processPaymentEvent } from "@/lib/payments/processor";
import { settleInstructorSubscription } from "@/lib/instructor/checkout";
import { createServiceSupabase } from "@/lib/supabase/service";

export const metadata: Metadata = {
  title: "Paiement",
  robots: { index: false },
};

type PurchaseRow = {
  id: string;
  user_id: string;
  category_id: string;
  level: string;
  status: string;
  provider: string | null;
  provider_reference: string | null;
  amount_usd: number | null;
  currency: string | null;
};

/**
 * Page de retour nyole (success_url / cancel_url).
 * Ouvrable dans l'iframe du dialogue comme dans une fenêtre détachée :
 *  - elle vérifie le statut côté serveur (la seule source de vérité) et
 *    valide la purchase si le paiement est confirmé ;
 *  - elle prévient le dialogue (postMessage) puis, en ouverture directe,
 *    redirige elle-même l'apprenant.
 * Aucune authentification n'est exigée : la vérification repose sur l'identifiant
 * de purchase non devinable + le statut nyole + le contrôle du montant.
 */
export default async function PaymentReturnPage({
  searchParams,
}: {
  searchParams: Promise<{ ref?: string; cancelled?: string; kind?: string }>;
}) {
  const params = await searchParams;
  const purchaseId = typeof params.ref === "string" ? params.ref : "";
  const cancelled = params.cancelled === "1" || params.cancelled === "true";

  if (!purchaseId) redirect("/catalogue");

  const supabase = createServiceSupabase();
  if (!supabase) redirect("/catalogue");

  // Une souscription d'abonnement formateur revient ici avec le même bridge :
  // le dialogue de paiement reste unique pour toute la plateforme.
  if (params.kind === "formateur") {
    const settled = await settleInstructorSubscription(supabase, {
      subscriptionId: purchaseId,
    });
    const instructorStatus: ReturnStatus = cancelled
      ? "cancelled"
      : settled.paid
        ? "success"
        : settled.status === "FAILED"
          ? "failed"
          : "pending";

    return (
      <PaymentReturnBridge
        purchaseId={purchaseId}
        status={instructorStatus}
        redirectUrl="/app/formateur?notice=actif"
        retryUrl={absoluteUrl("/app/formateur/souscrire")}
      />
    );
  }

  const { data: purchase } = await supabase
    .from("purchases")
    .select(
      "id,user_id,category_id,level,status,provider,provider_reference,amount_usd,currency",
    )
    .eq("id", purchaseId)
    .maybeSingle<PurchaseRow>();

  if (!purchase) redirect("/catalogue");

  // Le lien de retour peut se retrouver collé ailleurs (historique, capture,
  // messagerie). Si un compte est connecté sur ce navigateur, il doit être
  // celui qui a lancé l'achat ; sinon la page reste un simple pont de
  // vérification pour le paiement déjà engagé.
  const sessionUser = await getUser();
  if (sessionUser && sessionUser.id !== purchase.user_id) {
    redirect(links.dashboard);
  }

  let status: ReturnStatus = "pending";

  if (cancelled) {
    status = "cancelled";
  } else if (purchase.status === "paid") {
    status = "success";
  } else if (purchase.provider === "nyole" && purchase.provider_reference) {
    const result = await getNyoleSessionStatus(purchase.provider_reference);

    if (!result.ok) {
      console.warn(
        "[paiement] retour : statut nyole injoignable",
        result.reason,
      );
      status = "pending";
    } else if (!result.status.paid) {
      status = result.status.status === "FAILED" ? "failed" : "pending";
    } else if (
      !amountMatches(purchase.amount_usd, result.status, CHECKOUT_CURRENCY)
    ) {
      console.warn(
        "[paiement] retour : montant incohérent —",
        JSON.stringify({
          purchaseId: purchase.id,
          expectedUsd: purchase.amount_usd,
          currency: result.status.currency,
          amount: result.status.amount,
        }),
      );
      status = "failed";
    } else {
      const processed = await processPaymentEvent({
        eventId: `nyole:${purchase.provider_reference}`,
        provider: "nyole",
        reference: purchase.provider_reference,
        purchaseId: purchase.id,
      });
      if (processed.ok) {
        status = "success";
      } else {
        console.warn("[paiement] retour : validation impossible", processed.reason);
        status = "pending";
      }
    }
  }

  const redirectUrl = await trackNoticeUrl(supabase, purchase.category_id);
  const retryUrl = absoluteUrl(
    `/app/acheter?cat=${purchase.category_id}&level=${purchase.level}`,
  );

  return (
    <PaymentReturnBridge
      purchaseId={purchase.id}
      status={status}
      redirectUrl={redirectUrl}
      retryUrl={retryUrl}
    />
  );
}
