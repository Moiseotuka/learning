/**
 * Gabarits des e-mails d'une académie.
 *
 * Le formateur donne des cours, l'e-mail doit porter son nom d'académie avant
 * celui de la plateforme : une convocation signée « easyTech » ressemble à une
 * pub, signée « e-learning (ISIPA) » ressemble à un cours. La marque de
 * l'infrastructure vidéo n'apparaît jamais — même discipline que pour les
 * leçons.
 *
 * Les liens sont construits ici et partagés entre la boîte d'envoi
 * (`notices.ts`) et les actions du formateur, pour qu'une invitation et un
 * rappel conduisent exactement au même endroit.
 */

import { site } from "@/config/site";

export function siteUrl(): string {
  return site.url.startsWith("http") ? site.url : `https://${site.url}`;
}

/** Ancre sur la carte de la classe : l'élève arrive à la bonne classe. */
export function classLink(classId?: string): string {
  return classId
    ? `${siteUrl()}/app/classe#c-${encodeURIComponent(classId)}`
    : `${siteUrl()}/app/classe`;
}

export function sessionLink(sessionId: string): string {
  return `${siteUrl()}/app/live/${sessionId}`;
}

export function agendaLink(classId: string): string {
  return `${siteUrl()}/app/classe/agenda?class=${encodeURIComponent(classId)}`;
}

export function trackLink(slug: string): string {
  return `${siteUrl()}/app/parcours/${slug}`;
}

export function signupLink(next: string): string {
  return `${siteUrl()}/inscription?next=${encodeURIComponent(next)}`;
}

/**
 * Lien d'une invitation pour une adresse qui n'a pas encore de compte :
 * l'inscription est passée par le jeton, la page verrouille l'e-mail invité et
 * renvoie l'élève dans sa classe dès qu'il existe.
 */
export function invitationSignupLink(token: string): string {
  return `${siteUrl()}/inscription?invitation=${encodeURIComponent(token)}`;
}

export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function emailButton(label: string, href: string): string {
  return `<a href="${href}" style="display:inline-block;background:#0f766e;color:#ffffff;text-decoration:none;padding:12px 22px;border-radius:10px;font-weight:600;font-size:15px">${escapeHtml(label)}</a>`;
}

/** Un ordre du jour saisi en lignes devient une liste lisible, pas un pavé. */
export function agendaLines(agenda: string): string {
  const items = agenda
    .split(/\r?\n|•|;/)
    .map((line) => line.replace(/^[-*\d.)\s]+/, "").trim())
    .filter(Boolean)
    .slice(0, 8);
  if (items.length === 0) return "";
  return `<ul style="margin:14px 0 0;padding-left:20px">${items
    .map((item) => `<li style="margin:3px 0">${escapeHtml(item)}</li>`)
    .join("")}</ul>`;
}

/**
 * Bandeau commun : sur une connexion faible, la voix suffit et l'écran partagé
 * reste lisible. La consigne vaut pour toutes les convocations, pas seulement
 * pour la salle.
 */
export const LOW_CONNECTION_NOTE = `<p style="margin:18px 0 0;font-size:13px;line-height:1.6;color:#475569;background:#f1f5f9;border-left:3px solid #0f766e;padding:10px 12px;border-radius:6px">
Connexion faible ? Entrez en salle et choisissez le mode <strong>voix seule</strong> : vous entendez le formateur et vous suivez son partage d'écran sans la vidéo des participants. Le cours continue même si le réseau coupe, la salle se rouvre avec le même lien.</p>`;

export type EmailLayoutInput = {
  /** Nom de l'académie, affiché en tête ; à défaut, la plateforme signe. */
  academy: string;
  title: string;
  /** Fragment HTML : l'expéditeur compose, l'échappement est fait en amont. */
  intro: string;
  body: string;
  actions: string;
  footnote?: string;
};

export function emailLayout(input: EmailLayoutInput): string {
  const brand = escapeHtml(input.academy || "easyTech");
  return `<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f8fafc;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#0f172a">
<table role="presentation" cellpadding="0" cellspacing="0" style="width:100%;background:#f8fafc;padding:26px 12px">
<tr><td align="center">
  <table role="presentation" cellpadding="0" cellspacing="0" style="max-width:560px;width:100%;background:#ffffff;border:1px solid #e2e8f0;border-radius:16px;overflow:hidden">
    <tr><td style="background:#0b3b2e;padding:18px 24px">
      <div style="color:#7ee7c7;font-size:11px;letter-spacing:1.4px;text-transform:uppercase">Espace cours en ligne</div>
      <div style="color:#ffffff;font-size:17px;font-weight:700;margin-top:3px">${brand}</div>
    </td></tr>
    <tr><td style="padding:26px 24px">
      <h1 style="margin:0;font-size:19px;line-height:1.35">${escapeHtml(input.title)}</h1>
      <p style="margin:12px 0 0;font-size:15px;line-height:1.6;color:#334155">${input.intro}</p>
      ${input.body}
      <div style="margin-top:26px">${input.actions}</div>
    </td></tr>
    <tr><td style="padding:16px 24px;background:#f8fafc;border-top:1px solid #e2e8f0;font-size:12px;color:#64748b;line-height:1.6">
      ${input.footnote ?? ""}
      Cours hébergé sur <a href="${siteUrl()}" style="color:#0f766e">easyTech</a> — vous n'avez rien à installer.
    </td></tr>
  </table>
</td></tr></table>
</body></html>`;
}

export type InvitationEmailInput = {
  academy: string;
  className: string;
  trackTitle: string;
  instructorName: string;
  /** Paragraphe d'ouverture : déjà inscrit, ou invitation à créer le compte. */
  body: string;
  ctaLabel: string;
  ctaHref: string;
};

/** Invitation d'entrée en classe : le nom de l'académie porte le message. */
export function invitationEmail(input: InvitationEmailInput): string {
  return emailLayout({
    academy: input.academy,
    title: `Classe « ${input.className} »`,
    intro: `Bonjour,<br>${input.body}`,
    body: `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Parcours suivi&nbsp;: <strong>${escapeHtml(input.trackTitle)}</strong>. Votre formateur&nbsp;: ${escapeHtml(input.instructorName)}. Lien valable 14 jours, à usage unique.</p>
${LOW_CONNECTION_NOTE}`,
    actions: emailButton(input.ctaLabel, input.ctaHref),
    footnote: `Message envoyé par ${escapeHtml(input.academy)} à travers easyTech.`,
  });
}
