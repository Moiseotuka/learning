"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { links } from "@/config/site";
import { requireAdmin } from "@/lib/auth/dal";
import { runMarketingNow, setConsent, setDailyCap } from "@/lib/marketing/queue";

/**
 * Consentement aux relances, et pilotage administratif de la file.
 *
 * Le choix de l'apprenant passe par un jeton porté par le lien de son e-mail :
 * il doit pouvoir se retirer sans avoir à se reconnecter, trois semaines après
 * avoir reçu le message. Les deux actions d'administration exigent le rôle
 * admin — déclencher une campagne au hasard ne se laisse pas à un visiteur.
 */

export type ConsentState = { message: string; failed?: boolean };

export async function consentAction(
  _prev: ConsentState | undefined,
  formData: FormData,
): Promise<ConsentState> {
  const token = String(formData.get("token") ?? "");
  const optOut = formData.get("choice") === "out";
  if (!token) {
    return { message: "Lien incomplet : reprenez le message reçu.", failed: true };
  }

  const state = await setConsent(token, optOut);
  if (!state) return { message: "Ce lien n'est plus valable.", failed: true };

  return {
    message: optOut
      ? `Retiré. Vous ne recevrez plus de relance de progression sur ${state.email}; les convocations de votre formateur et vos certificats continuent d'arriver.`
      : `C'est noté : les relances de progression repartent sur ${state.email}.`,
  };
}

export async function saveCapAction(_prev: ConsentState | undefined, formData: FormData): Promise<void> {
  await requireAdmin(links.admin);
  const raw = Number(String(formData.get("cap") ?? "").replace(/[^\d]/g, ""));
  if (!Number.isFinite(raw) || raw < 1) {
    redirect(`${links.admin}/marketing?notice=cap_invalid`);
  }
  await setDailyCap(raw);
  revalidatePath(`${links.admin}/marketing`);
  redirect(`${links.admin}/marketing?notice=cap_saved`);
}

export async function runNowAction(): Promise<void> {
  await requireAdmin(links.admin);
  const report = await runMarketingNow();
  revalidatePath(`${links.admin}/marketing`);
  redirect(
    `${links.admin}/marketing?notice=ran&sent=${report.sent}&failed=${report.failed}&queued=${report.deferred}`,
  );
}
