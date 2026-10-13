import { messages } from "@/i18n";

const t = messages.formateur;

/**
 * Les actions serveur renvoient un code de succès, jamais une phrase : la
 * traduction se fait ici, côté affichage, pour que le message reste dans le
 * dictionnaire et que l'action ne dépende pas de la locale.
 */
export const SUCCESS_NOTICES: Record<string, string> = {
  actif: t.notices.actif,
  renouvelle: t.notices.renouvelle,
  classeCreee: t.notices.classeCreee,
  archivee: t.notices.archivee,
  eleveRetire: t.students.removed,
  inviteEnvoye: t.notices.inviteEnvoye,
  inviteSansEmail: t.notices.inviteSansEmail,
  rejoint: t.notices.rejoint,
  partie: t.notices.partie,
  seancePlanifiee: t.notices.seancePlanifiee,
  seanceOuverte: t.notices.seanceOuverte,
  seanceClose: t.notices.seanceClose,
  seanceAnnulee: t.notices.seanceAnnulee,
  seanceDeplacee: t.notices.seanceDeplacee,
  eleveInscrit: t.notices.eleveInscrit,
  programmeEnvoye: t.notices.programmeEnvoye,
};

export function successNotice(notice: string | undefined): string | undefined {
  return notice ? SUCCESS_NOTICES[notice] : undefined;
}
