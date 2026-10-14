/**
 * Textes des relances automatiques.
 *
 * Une relance n'est pas une pub : elle parle de la leçon laissée en cours, du
 * niveau que l'apprenant a déjà en poche et de la prochaine étape concrète. Les
 * chiffres viennent de la base au moment de l'envoi — un pourcentage inventé à
 * la mise en file mentirait dès le lendemain.
 *
 * Deux règles de la plateforme s'y appliquent : aucune marque d'hébergeur
 * n'apparaît, et chaque message porte un lien de désinscription fonctionnel.
 */

import {
  emailButton,
  emailLayout,
  escapeHtml,
  siteUrl,
  trackLink,
} from "@/lib/instructor/email-templates";
import { createServiceSupabase } from "@/lib/supabase/service";

type Reader = NonNullable<ReturnType<typeof createServiceSupabase>>;

export const MARKETING_KINDS = ["resume", "level_up", "explore", "winback", "new_track"] as const;
export type MarketingKind = (typeof MARKETING_KINDS)[number];

const LEVEL_LABELS: Record<string, string> = {
  debutant: "Débutant",
  intermediaire: "Intermédiaire",
  avance: "Avancé",
  projet: "Projet",
};

const LEVEL_ORDER = ["debutant", "intermediaire", "avance", "projet"];

export function levelLabel(level: string): string {
  return LEVEL_LABELS[level] ?? level;
}

const NEXT_LEVEL: Record<string, string | null> = {
  debutant: "intermediaire",
  intermediaire: "avance",
  avance: "projet",
  projet: null,
};

export type MarketingRow = {
  id: string;
  kind: MarketingKind;
  user_id: string | null;
  track_id: string | null;
  recipient: string;
  attempts: number;
};

/* -------------------------------------------------------------------------
 * Morceaux de contexte relus à l'envoi
 * ---------------------------------------------------------------------- */

/** Le premier chapitre public non terminé, dans l'ordre pédagogique. */
async function nextChapter(
  supabase: Reader,
  trackId: string,
  userId: string,
): Promise<{ slug: string; title: string; level: string; position: number } | null> {
  const { data: chapters } = await supabase
    .from("chapters")
    .select("id,slug,title,level,position")
    .eq("track_id", trackId)
    .eq("published", true)
    .order("position");

  const rows = (chapters as { id: string; slug: string; title: string; level: string; position: number }[] | null) ?? [];
  if (rows.length === 0) return null;

  rows.sort((a, b) => {
    const la = LEVEL_ORDER.indexOf(a.level);
    const lb = LEVEL_ORDER.indexOf(b.level);
    return (la < 0 ? 99 : la) - (lb < 0 ? 99 : lb) || a.position - b.position;
  });

  const { data: done } = await supabase
    .from("chapter_progress")
    .select("chapter_id,status")
    .eq("user_id", userId)
    .eq("track_id", trackId)
    .eq("status", "completed");
  const finished = new Set(((done as { chapter_id: string }[] | null) ?? []).map((row) => row.chapter_id));

  return rows.find((row) => !finished.has(row.id)) ?? null;
}

async function trackInfo(
  supabase: Reader,
  trackId: string,
): Promise<{ slug: string; title: string; description: string; level: string; categoryId: string; modules: number } | null> {
  const { data } = await supabase
    .from("tracks")
    .select("slug,title,description,level,category_id,modules_count")
    .eq("id", trackId)
    .maybeSingle<Record<string, unknown>>();
  if (!data) return null;
  return {
    slug: String(data.slug),
    title: String(data.title),
    description: String(data.description ?? ""),
    level: String(data.level ?? "debutant"),
    categoryId: String(data.category_id),
    modules: Number(data.modules_count) || 0,
  };
}

async function progressCounts(
  supabase: Reader,
  trackId: string,
  userId: string,
): Promise<{ done: number; total: number }> {
  const { count } = await supabase
    .from("chapters")
    .select("id", { count: "exact", head: true })
    .eq("track_id", trackId)
    .eq("published", true);
  const { count: finished } = await supabase
    .from("chapter_progress")
    .select("chapter_id", { count: "exact", head: true })
    .eq("track_id", trackId)
    .eq("user_id", userId)
    .eq("status", "completed");
  return { done: finished ?? 0, total: count ?? 0 };
}

async function nameOf(supabase: Reader, userId: string | null, fallback: string): Promise<string> {
  if (!userId) return fallback;
  const { data } = await supabase
    .from("profiles")
    .select("full_name")
    .eq("id", userId)
    .maybeSingle<{ full_name: string | null }>();
  return data?.full_name?.trim() || fallback;
}

/** Un parcours publié que cette personne n'a pas encore ouvert, bien classé. */
async function suggestion(
  supabase: Reader,
  userId: string,
  categoryId: string | null,
): Promise<{ slug: string; title: string; level: string } | null> {
  const { data: opened } = await supabase
    .from("chapter_progress")
    .select("track_id")
    .eq("user_id", userId);
  const taken = new Set(((opened as { track_id: string }[] | null) ?? []).map((row) => row.track_id));

  let query = supabase
    .from("tracks")
    .select("id,slug,title,level,category_id,position")
    .eq("published", true);
  if (categoryId) query = query.neq("category_id", categoryId);

  const { data } = await query.order("position").limit(24);
  const rows = (data as { id: string; slug: string; title: string; level: string; category_id: string }[] | null) ?? [];
  const fresh = rows.find((row) => !taken.has(row.id));
  if (fresh) return { slug: fresh.slug, title: fresh.title, level: fresh.level };

  // Tout est déjà ouvert : on renvoie un parcours d'une autre famille quand même.
  const { data: anyRow } = await supabase
    .from("tracks")
    .select("slug,title,level")
    .eq("published", true)
    .in("level", ["intermediaire", "avance"])
    .limit(1);
  const one = (anyRow as { slug: string; title: string; level: string }[] | null)?.[0];
  return one ? { slug: one.slug, title: one.title, level: one.level } : null;
}

/* -------------------------------------------------------------------------
 * Liens et pied de message
 * ---------------------------------------------------------------------- */

export function unsubscribeLink(token: string): string {
  return `${siteUrl()}/desinscription?token=${encodeURIComponent(token)}`;
}

/** Jeton de consentement : créé au premier envoi, stable ensuite. */
export async function tokenFor(
  supabase: Reader,
  email: string,
): Promise<string | null> {
  const lower = email.trim().toLowerCase();
  const { data: existing } = await supabase
    .from("marketing_subscriptions")
    .select("token")
    .eq("email", lower)
    .maybeSingle<{ token: string }>();
  if (existing?.token) return existing.token;

  const { data: created } = await supabase
    .from("marketing_subscriptions")
    .insert({ email: lower })
    .select("token")
    .maybeSingle<{ token: string }>();
  return created?.token ?? null;
}

function footLine(email: string, token: string | null): string {
  const manage = token
    ? `<a href="${unsubscribeLink(token)}" style="color:#0f766e">Se désinscrire de ces relances</a>`
    : "Relances automatiques easyTech";
  return `Vous recevez ce message parce que votre compte easyTech (<strong>${escapeHtml(email)}</strong>) est actif. ${manage} — un seul clic, sans justification.`;
}

/* -------------------------------------------------------------------------
 * Composition
 * ---------------------------------------------------------------------- */

export type MarketingDraft = { subject: string; html: string; text: string };

export async function composeMarketing(
  supabase: Reader,
  notice: MarketingRow,
): Promise<MarketingDraft | null> {
  const token = await tokenFor(supabase, notice.recipient);
  const foot = footLine(notice.recipient, token);

  // Les relances portent le nom de la plateforme, pas celui d'une académie :
  // c'est easyTech qui suit l'apprenant, pas un formateur.
  const wrap = (title: string, intro: string, body: string, actions: string, subject: string) => ({
    subject,
    html: emailLayout({ academy: "easyTech", title, intro, body, actions, footnote: foot }),
  });

  if (notice.kind === "new_track") {
    if (!notice.track_id) return null;
    const track = await trackInfo(supabase, notice.track_id);
    if (!track) return null;
    const subject = `Nouveau sur easyTech : ${track.title}`;
    const built = wrap(
      `Un nouveau parcours vient d'ouvrir : ${track.title}`,
      `Bonjour,<br>Le parcours <strong>« ${escapeHtml(track.title)} »</strong> est disponible depuis aujourd'hui sur easyTech. ${track.description ? escapeHtml(track.description) : ""}`,
      `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Niveau d'entrée&nbsp;: <strong>${escapeHtml(levelLabel(track.level))}</strong>${track.modules ? ` · ${track.modules} chapitres` : ""}. Vous en faites ce que vous voulez : les chapitres s'ouvrent dans l'ordre, le certificat vient sanctionner la fin.</p>`,
      emailButton("Voir le parcours", trackLink(track.slug)),
      subject,
    );
    return { ...built, text: `${subject}\n\nNouveau parcours : ${track.title}\n${trackLink(track.slug)}` };
  }

  if (!notice.user_id) return null;
  const name = await nameOf(supabase, notice.user_id, "Bonjour");
  const hello = `Bonjour ${escapeHtml(name)},`;

  if (notice.kind === "resume") {
    if (!notice.track_id) return null;
    const track = await trackInfo(supabase, notice.track_id);
    if (!track) return null;
    const next = await nextChapter(supabase, notice.track_id, notice.user_id);
    const counts = await progressCounts(supabase, notice.track_id, notice.user_id);
    const percent = counts.total > 0 ? Math.round((counts.done / counts.total) * 100) : 0;
    const subject = next
      ? `Il vous reste « ${next.title} » dans ${track.title}`
      : `Reprenez ${track.title} où vous l'avez laissé`;
    const built = wrap(
      next ? `Prochaine étape : ${next.title}` : `Votre parcours vous attend`,
      `${hello} Vous avez ouvert <strong>« ${escapeHtml(track.title)} »</strong> et vous êtes à <strong>${percent}%</strong> (${counts.done}/${counts.total} chapitres). Plus de trois jours sans nouvelle leçon : un parcours laissé à moitié ouvert ne donne encore aucun certificat.`,
      next
        ? `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Le chapitre qui suit est <strong>« ${escapeHtml(next.title)} »</strong> (niveau ${escapeHtml(levelLabel(next.level))}). Comptez quinze minutes : la leçon reprend exactement là où vous vous étiez arrêté, vidéo et exercices déjà positionnés.</p>`
        : `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Il ne reste que les évaluations : terminez-les pour décrocher le certificat de ce parcours.</p>`,
      emailButton(next ? "Reprendre maintenant" : "Voir mon parcours", next ? `${trackLink(track.slug)}/chapitres/${next.slug}` : trackLink(track.slug)),
      subject,
    );
    return { ...built, text: `${subject}\n\n${track.title} — ${percent}% fait (${counts.done}/${counts.total}).\n${trackLink(track.slug)}` };
  }

  if (notice.kind === "level_up") {
    const track = notice.track_id ? await trackInfo(supabase, notice.track_id) : null;
    const certLevel = track ? await certificateLevel(supabase, notice) : null;
    const up = certLevel ? NEXT_LEVEL[certLevel] : "intermediaire";
    if (!up || !track) return null;
    const subject = `Niveau ${levelLabel(up)} de ${track.title} : ce que vous saurez faire après`;
    const built = wrap(
      `Après ${levelLabel(certLevel ?? "")}, le niveau ${levelLabel(up)}`,
      `${hello} Vous tenez le niveau <strong>${escapeHtml(levelLabel(certLevel ?? ""))}</strong> de <strong>« ${escapeHtml(track.title)} »</strong>. C'est le moment qui décide de tout : les bases sont en place, et c'est maintenant que le travail devient réel — construire plutôt que répéter.`,
      `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Le niveau <strong>${escapeHtml(levelLabel(up))}</strong> du même parcours s'ouvre sur ${track.modules || "des"} chapitres de pratique réelle : on ne vous demande plus de répéter, on vous demande de construire. Le certificat qui le termine porte les deux niveaux.</p>`,
      `${emailButton("Goûter au niveau supérieur", `${trackLink(track.slug)}`)} &nbsp; <a href="${siteUrl()}/app/acheter?cat=${encodeURIComponent(track.categoryId)}&level=${encodeURIComponent(up)}" style="color:#0f766e;font-size:14px">Voir le tarif de ce niveau</a>`,
      subject,
    );
    return { ...built, text: `${subject}\n\nCertificat ${levelLabel(certLevel ?? "")} en poche, le niveau ${levelLabel(up)} vous attend : ${trackLink(track.slug)}` };
  }

  if (notice.kind === "explore") {
    const best = await bestCategory(supabase, notice.user_id);
    const pick = await suggestion(supabase, notice.user_id, best);
    if (!pick) return null;
    const subject = `Un certificat, et si vous en cherchiez un deuxième ?`;
    const built = wrap(
      `Poursuivre : ${pick.title}`,
      `${hello} Vous avez terminé un parcours complet sur easyTech. Les apprenants qui s'arrêtent au premier certificat restent cantonnés à une seule famille de compétences ; ceux qui en ajoutent un deuxième se rendent employables sur deux métiers à la fois.`,
      `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Ce qui se rapproche le plus de ce que vous avez déjà réussi&nbsp;: <strong>« ${escapeHtml(pick.title)} »</strong>, niveau d'entrée ${escapeHtml(levelLabel(pick.level))}. Les bases que vous tenez vous font gagner les premiers chapitres.</p>`,
      emailButton("Ouvrir ce parcours", trackLink(pick.slug)),
      subject,
    );
    return { ...built, text: `${subject}\n\nParcours conseillé : ${pick.title} (${levelLabel(pick.level)}) — ${trackLink(pick.slug)}` };
  }

  // winback : le compte a payé puis disparu. On ne reparle pas d'argent.
  const last = await lastTrack(supabase, notice.user_id);
  const subject = last
    ? `${last.title} : votre place est encore prise`
    : `Vos cours easyTech vous attendent`;
  const built = wrap(
    last ? `Reprendre ${last.title}` : "Vos cours vous attendent",
    `${hello} Cela fait un moment que vous n'êtes pas revenu sur easyTech. Rien n'est perdu : vos chapitres terminés restent acquis, votre progression est exactement là où vous l'avez laissée.`,
    `<p style="margin:16px 0 0;font-size:14px;line-height:1.6;color:#334155">Après une pause, le plus dur tient en une minute. Ouvrez une leçon, lisez-la jusqu'au premier exercice — la suite vient seule.</p>`,
    emailButton(last ? "Reprendre mon parcours" : "Voir mes parcours", last ? trackLink(last.slug) : `${siteUrl()}/app`),
    subject,
  );
  return { ...built, text: `${subject}\n\n${siteUrl()}/app` };
}

/* -------------------------------------------------------------------------
 * Requêtes de détail
 * ---------------------------------------------------------------------- */

async function certificateLevel(
  supabase: Reader,
  notice: MarketingRow,
): Promise<string | null> {
  if (!notice.user_id || !notice.track_id) return null;
  const { data } = await supabase
    .from("certificates")
    .select("level,issued_at")
    .eq("user_id", notice.user_id)
    .eq("track_id", notice.track_id)
    .in("level", ["debutant", "intermediaire", "avance"])
    .order("issued_at", { ascending: false })
    .limit(1);
  const row = (data as { level: string }[] | null)?.[0];
  return row?.level ?? null;
}

/** La famille où l'apprenant a déjà le plus réussi, pour proposer près. */
async function bestCategory(supabase: Reader, userId: string): Promise<string | null> {
  const { data } = await supabase
    .from("certificates")
    .select("track_id")
    .eq("user_id", userId)
    .limit(20);
  const tracks = ((data as { track_id: string }[] | null) ?? []).map((row) => row.track_id);
  if (tracks.length === 0) return null;
  const { data: rows } = await supabase
    .from("tracks")
    .select("category_id")
    .in("id", tracks)
    .limit(20);
  const counts = new Map<string, number>();
  for (const row of (rows as { category_id: string }[] | null) ?? []) {
    counts.set(row.category_id, (counts.get(row.category_id) ?? 0) + 1);
  }
  return [...counts.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ?? null;
}

/** Le dernier parcours touché, pour la relance de compte endormi. */
async function lastTrack(
  supabase: Reader,
  userId: string,
): Promise<{ slug: string; title: string } | null> {
  const { data } = await supabase
    .from("chapter_progress")
    .select("track_id,updated_at")
    .eq("user_id", userId)
    .order("updated_at", { ascending: false })
    .limit(1);
  const trackId = (data as { track_id: string }[] | null)?.[0]?.track_id;
  if (!trackId) return null;
  const { data: track } = await supabase
    .from("tracks")
    .select("slug,title")
    .eq("id", trackId)
    .maybeSingle<{ slug: string; title: string }>();
  return track ?? null;
}
