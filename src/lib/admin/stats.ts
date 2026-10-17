import { createServiceSupabase } from "@/lib/supabase/service";

/**
 * Nombre d'apprenants inscrits. Le comptage passe par la clé de service :
 * la politique RLS de `profiles` est `is_admin()`, donc une simple régression
 * de cette fonction afficherait « 1 » au lieu du réel total.
 */
export async function countRegisteredUsers(): Promise<number | null> {
  const supabase = createServiceSupabase();
  if (!supabase) return null;

  const { count, error } = await supabase
    .from("profiles")
    .select("id", { count: "exact", head: true });

  if (error) {
    console.error("[admin] comptage des inscrits", error.message);
    return null;
  }
  return count ?? 0;
}

/* ---------------------------------------------------------------------------
 * Lectures du tableau de bord.
 *
 * Tout passe par la clé de service et par les six fonctions `admin_*` créées par
 * `202610160002_admin_stats.sql` : le regroupement se fait dans la base, et ces
 * fonctions sont retirées à `anon`/`authenticated`, donc aucune page publique
 * ne peut les appeler.
 * ------------------------------------------------------------------------ */

export type Periode = "7" | "30" | "90";

export const PERIODES: { cle: Periode; jours: number }[] = [
  { cle: "7", jours: 7 },
  { cle: "30", jours: 30 },
  { cle: "90", jours: 90 },
];

/**
 * Départ de la période, aligné sur la journée de Kinshasa (UTC+2, sans changement d'heure).
 * On part de midi UTC : cet instant appartient toujours à la journée locale visée, et les
 * fonctions SQL regroupent sur la même date calendaire.
 */
function depuisISO(periode: Periode): string {
  const { jours } = PERIODES.find((p) => p.cle === periode) ?? PERIODES[1];
  const aujourdhui = new Intl.DateTimeFormat("fr-CA", {
    timeZone: "Africa/Lubumbashi",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
  const base = new Date(`${aujourdhui}T12:00:00Z`);
  base.setUTCDate(base.getUTCDate() - (jours - 1));
  return base.toISOString();
}

export type LigneSource = {
  source: string;
  medium: string;
  vues: number;
  visiteurs: number;
};

export type LigneJour = {
  jour: string;
  vues: number;
  visiteurs: number;
  inscrits: number;
};

export type LignePage = { path: string; vues: number; visiteurs: number };
export type LignePays = { pays: string; visiteurs: number };
export type LigneAppareil = { appareil: string; vues: number; visiteurs: number };
export type LigneStatut = {
  statut: string;
  nombre: number;
  montant: number;
  devise: string | null;
};

export type Trafic = {
  vues: number;
  visiteurs: number;
  inscrits: number;
  parJour: LigneJour[];
  parSource: LigneSource[];
  parAppareil: LigneAppareil[];
  pages: LignePage[];
  pays: LignePays[];
};

/** Les lignes renvoyées par PostgREST, réduites à un tableau exploitable quelle que soit la réponse. */
function brutes(valeur: unknown): Record<string, unknown>[] {
  return Array.isArray(valeur) ? (valeur as Record<string, unknown>[]) : [];
}

/** `null` quand la base ne répond pas : la page affiche « indisponible » plutôt que 0. */
export async function lireTrafic(periode: Periode): Promise<Trafic | null> {
  const supabase = createServiceSupabase();
  if (!supabase) return null;

  const depuis = depuisISO(periode);
  const [jours, sources, appareils, pages, pays] = await Promise.all([
    supabase.rpc("admin_visites_par_jour", { depuis }),
    supabase.rpc("admin_visites_par_source", { depuis }),
    supabase.rpc("admin_visites_par_appareil", { depuis }),
    supabase.rpc("admin_pages_visitees", { depuis }),
    supabase.rpc("admin_visites_par_pays", { depuis }),
  ]);

  const echec = [jours, sources, appareils, pages, pays].find((r) => r.error);
  if (echec?.error) {
    console.error("[admin] trafic", echec.error.message);
    return null;
  }

  const parJour: LigneJour[] = brutes(jours.data).map((l) => ({
    jour: String(l.jour),
    vues: Number(l.vues ?? 0),
    visiteurs: Number(l.visiteurs ?? 0),
    inscrits: Number(l.inscrits ?? 0),
  }));
  const parSource: LigneSource[] = brutes(sources.data).map((l) => ({
    source: String(l.source),
    medium: String(l.medium),
    vues: Number(l.vues ?? 0),
    visiteurs: Number(l.visiteurs ?? 0),
  }));
  const parAppareil: LigneAppareil[] = brutes(appareils.data).map((l) => ({
    appareil: String(l.appareil),
    vues: Number(l.vues ?? 0),
    visiteurs: Number(l.visiteurs ?? 0),
  }));
  const pagesLignes: LignePage[] = brutes(pages.data).map((l) => ({
    path: String(l.path),
    vues: Number(l.vues ?? 0),
    visiteurs: Number(l.visiteurs ?? 0),
  }));
  const paysLignes: LignePays[] = brutes(pays.data).map((l) => ({
    pays: String(l.pays),
    visiteurs: Number(l.visiteurs ?? 0),
  }));

  return {
    // Un identifiant de visiteur est redéfini chaque jour : additionner les visiteurs
    // quotidiens donne bien des « visiteurs-jours », ce que l'admin veut voir.
    vues: parJour.reduce((somme, l) => somme + l.vues, 0),
    visiteurs: parJour.reduce((somme, l) => somme + l.visiteurs, 0),
    inscrits: parJour.reduce((somme, l) => somme + l.inscrits, 0),
    parJour,
    parSource,
    parAppareil,
    pages: pagesLignes,
    pays: paysLignes,
  };
}

export type LigneCategorieAchat = {
  categorie: string;
  niveau: string;
  payes: number;
  enAttente: number;
  montant: number;
  devise: string;
};

export type Ventes = {
  achats: LigneStatut[];
  abonnements: LigneStatut[];
  parCategorie: LigneCategorieAchat[];
  totalAchats: number;
  achatsPayes: number;
  achatsEnAttente: number;
  montantPaye: number;
  montantEnAttente: number;
  devise: string;
};

/**
 * Statuts considérés comme payés. `refunded` en est absent : un remboursement n'est pas du revenu
 * encaissé. Le webhook Nyole écrit `paid`, le traitement interne peut écrire `success`/`completed`.
 */
const STATUTS_PAYES = new Set(["paid", "success", "completed"]);
const STATUTS_EN_ATTENTE = new Set([
  "pending",
  "processing",
  "requires_action",
  "initiated",
  "created",
  "started",
]);

export async function lireVentes(): Promise<Ventes | null> {
  const supabase = createServiceSupabase();
  if (!supabase) return null;

  const [achats, abonnements, parCategorie] = await Promise.all([
    supabase.rpc("admin_achats", {}),
    supabase.rpc("admin_abonnements_formateur", {}),
    supabase.rpc("admin_achats_par_categorie", {}),
  ]);

  const echec = [achats, abonnements, parCategorie].find((r) => r.error);
  if (echec?.error) {
    console.error("[admin] ventes", echec.error.message);
    return null;
  }

  const lignes: LigneStatut[] = (achats.data ?? []).map((l: Record<string, unknown>) => ({
    statut: String(l.statut),
    nombre: Number(l.nombre ?? 0),
    montant: Number(l.montant ?? 0),
    devise: l.devise ? String(l.devise) : null,
  }));

  const payees = lignes.filter((l) => STATUTS_PAYES.has(l.statut));
  const enAttente = lignes.filter((l) => STATUTS_EN_ATTENTE.has(l.statut));

  return {
    achats: lignes,
    abonnements: (abonnements.data ?? []).map((l: Record<string, unknown>) => ({
      statut: String(l.statut),
      nombre: Number(l.nombre ?? 0),
      montant: Number(l.montant ?? 0),
      devise: "CDF",
    })),
    parCategorie: (parCategorie.data ?? []).map((l: Record<string, unknown>) => ({
      categorie: String(l.categorie),
      niveau: String(l.niveau),
      payes: Number(l.payes ?? 0),
      enAttente: Number(l.en_attente ?? 0),
      montant: Number(l.montant ?? 0),
      devise: String(l.devise ?? "CDF"),
    })),
    totalAchats: lignes.reduce((somme, l) => somme + l.nombre, 0),
    achatsPayes: payees.reduce((somme, l) => somme + l.nombre, 0),
    achatsEnAttente: enAttente.reduce((somme, l) => somme + l.nombre, 0),
    montantPaye: payees.reduce((somme, l) => somme + l.montant, 0),
    montantEnAttente: enAttente.reduce((somme, l) => somme + l.montant, 0),
    devise: lignes.find((l) => l.devise)?.devise ?? "CDF",
  };
}

export type Transaction = {
  id: string;
  client: string;
  email: string;
  article: string;
  niveau: string;
  montant: number;
  devise: string;
  fournisseur: string;
  statut: string;
  cree: string;
  paye: string | null;
};

/**
 * Noms des clients d'une liste de transactions.
 *
 * `purchases.user_id` n'a pas de clé étrangère vers `profiles` (il pointe sur les comptes
 * d'authentification), donc PostgREST ne peut pas embarquer le profil dans la même requête :
 * une erreur `PGRST200` viderait toute la liste. On relit donc les profils en une seconde
 * requête, par paquets d'identifiants.
 */
async function nomsClients(
  supabase: NonNullable<ReturnType<typeof createServiceSupabase>>,
  identifiants: string[],
): Promise<Map<string, { nom: string; email: string }>> {
  const parId = new Map<string, { nom: string; email: string }>();
  if (!identifiants.length) return parId;

  const { data, error } = await supabase
    .from("profiles")
    .select("id, full_name, email")
    .in("id", identifiants);

  if (error) {
    console.error("[admin] noms des clients", error.message);
    return parId;
  }

  for (const ligne of data ?? []) {
    parId.set(String(ligne.id), {
      nom: String(ligne.full_name ?? ""),
      email: String(ligne.email ?? ""),
    });
  }
  return parId;
}

/** Toutes les transactions, payées ou non : l'admin veut aussi les échecs et les abandons. */
export async function lireTransactions(
  statut?: string,
  limite = 200,
): Promise<Transaction[] | null> {
  const supabase = createServiceSupabase();
  if (!supabase) return null;

  let requete = supabase
    .from("purchases")
    .select("id, user_id, status, amount_usd, currency, provider, created_at, paid_at, level, categories(name)")
    .order("created_at", { ascending: false })
    .limit(limite);

  if (statut) requete = requete.eq("status", statut);

  const { data, error } = await requete;

  if (error) {
    console.error("[admin] transactions", error.message);
    return null;
  }

  const lignes = data ?? [];
  const noms = await nomsClients(
    supabase,
    [...new Set(lignes.map((l: Record<string, unknown>) => String(l.user_id)))],
  );

  return lignes.map((ligne: Record<string, unknown>) => {
    const categorie = (ligne.categories ?? {}) as { name?: string };
    const client = noms.get(String(ligne.user_id));

    return {
      id: String(ligne.id),
      client: client?.nom ?? "",
      email: client?.email ?? "",
      article: categorie.name ?? String(ligne.level ?? "niveau"),
      niveau: String(ligne.level ?? "—"),
      montant: Number(ligne.amount_usd ?? 0),
      devise: String(ligne.currency ?? "CDF"),
      fournisseur: String(ligne.provider ?? "—"),
      statut: String(ligne.status),
      cree: String(ligne.created_at),
      paye: ligne.paid_at ? String(ligne.paid_at) : null,
    };
  });
}

export type Compte = {
  id: string;
  nom: string;
  email: string;
  role: string;
  inscrit: string;
  chapitresVus: number;
  chapitresFinis: number;
  achats: number;
  dernierPas: string | null;
  /** Niveau du chapitre où l'apprenant est arrêté, `null` s'il n'a rien ouvert. */
  niveau: string | null;
  /** Formation correspondante, pour ne pas afficher un niveau sans savoir lequel. */
  formation: string | null;
  certificats: number;
  dernierCertificat: string | null;
  /** Vrai dès qu'un certificat « parcours complet » existe : le niveau terminal est atteint. */
  parcoursTermine: boolean;
};

export type LectureComptes = {
  comptes: Compte[];
  /** Total des comptes de la base. L'agrégation se faisant en base, ce chiffre est exact. */
  total: number;
  /**
   * Comptes ayant regardé quelque chose dans les sept derniers jours. Le calcul est fait ici et
   * non dans la page : `Date.now()` n'a rien à faire dans un composant, dont le rendu doit
   * rester prévisible.
   */
  actifs7Jours: number;
  /** Combien de personnes tiennent au moins un certificat. */
  certifies: number;
  /** Comptes décrochés : une leçon ouverte un jour, puis rien depuis deux semaines. */
  enSouffrance: number;
};

/**
 * Les comptes avec ce qu'ils ont réellement fait : où ils sont arrêtés, depuis quand, et ce
 * qu'ils ont obtenu. Tout est agrégé par `admin_suivi_comptes()` dans la base, en une passe,
 * pour que les compteurs soient exacts même quand la progression dépasse une page PostgREST.
 */
export async function lireComptes(): Promise<LectureComptes | null> {
  const supabase = createServiceSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase.rpc("admin_suivi_comptes");
  if (error) {
    console.error("[admin] comptes", error.message);
    return null;
  }

  const comptes: Compte[] = brutes(data).map((ligne) => {
    const dernierPas = ligne.derniere_activite
      ? String(ligne.derniere_activite)
      : null;

    return {
      id: String(ligne.id),
      nom: String(ligne.nom ?? ""),
      email: String(ligne.email ?? ""),
      role: String(ligne.role ?? "learner"),
      inscrit: String(ligne.inscrit),
      chapitresVus: Number(ligne.chapitres_ouverts ?? 0),
      chapitresFinis: Number(ligne.chapitres_reussis ?? 0),
      achats: Number(ligne.achats_payes ?? 0),
      dernierPas,
      niveau: ligne.niveau ? String(ligne.niveau) : null,
      formation: ligne.formation ? String(ligne.formation) : null,
      certificats: Number(ligne.certificats ?? 0),
      dernierCertificat: ligne.dernier_certificat
        ? String(ligne.dernier_certificat)
        : null,
      parcoursTermine: ligne.parcours_termine === true,
    };
  });

  const maintenant = Date.now();

  return {
    comptes,
    total: comptes.length,
    actifs7Jours: comptes.filter(
      (c) => c.dernierPas !== null && Date.parse(c.dernierPas) >= maintenant - 7 * 86_400_000,
    ).length,
    certifies: comptes.filter((c) => c.certificats > 0).length,
    enSouffrance: comptes.filter((c) => joursInactif(c) >= STAGNATION_JOURS).length,
  };
}

/**
 * Depuis combien de jours un apprenant n'a rien ouvert. `null` quand il n'a jamais
 * commencé : ce n'est pas une stagnation, c'est un compte qui attend encore sa
 * première leçon, et l'afficher comme tel fausserait le tri de la liste.
 */
export function joursInactif(compte: Pick<Compte, "dernierPas">): number {
  if (!compte.dernierPas) return 0;
  return Math.floor((Date.now() - Date.parse(compte.dernierPas)) / 86_400_000);
}

/**
 * Seuil au-delà duquel on considère que l'apprenant a décroché. Quatorze jours :
 * un rythme hebdomadaire reste normal ici, où la connexion et le budget sont
 * comptés, et c'est le délai auquel la relance automatique est utile sans être
 * harcelante.
 */
export const STAGNATION_JOURS = 14;

export type LigneCertificat = {
  id: string;
  code: string;
  titulaire: string;
  email: string;
  niveau: string;
  formation: string;
  intitule: string;
  delivre: string;
  formateur: string | null;
  academie: string | null;
};

/**
 * Tous les certificats délivrés, avec leur titulaire. La question posée par
 * l'exploitation est simple : qui peut-on appeler « formé » sur easyTech, et pour
 * quelle formation.
 */
export async function lireCertificats(): Promise<LigneCertificat[] | null> {
  const supabase = createServiceSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase.rpc("admin_certificats");
  if (error) {
    console.error("[admin] certificats", error.message);
    return null;
  }

  return brutes(data).map((ligne) => ({
    id: String(ligne.id),
    code: String(ligne.code),
    titulaire: String(ligne.titulaire ?? "—"),
    email: String(ligne.email ?? ""),
    niveau: String(ligne.niveau ?? ""),
    formation: String(ligne.formation ?? ""),
    intitule: String(ligne.intitule ?? ""),
    delivre: String(ligne.delivre),
    formateur: ligne.formateur ? String(ligne.formateur) : null,
    academie: ligne.academie ? String(ligne.academie) : null,
  }));
}

export type VisiteRecente = {
  id: string;
  vue: string;
  path: string;
  source: string;
  medium: string;
  campagne: string;
  pays: string;
  appareil: string;
  connectee: boolean;
};

/** Les dernières arrivées, telles qu'enregistrées : c'est ce qui rend les totaux crédibles. */
export async function lireVisitesRecentes(limite = 50): Promise<VisiteRecente[] | null> {
  const supabase = createServiceSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase
    .from("site_visits")
    .select(
      "id, seen_at, path, source, medium, campaign, country, device, signed_in",
    )
    .order("seen_at", { ascending: false })
    .limit(limite);

  if (error) {
    console.error("[admin] visites recentes", error.message);
    return null;
  }

  return (data ?? []).map((ligne: Record<string, unknown>) => ({
    id: String(ligne.id),
    vue: String(ligne.seen_at),
    path: String(ligne.path),
    source: String(ligne.source ?? "direct"),
    medium: String(ligne.medium ?? "autre"),
    campagne: String(ligne.campaign ?? ""),
    pays: String(ligne.country ?? ""),
    appareil: String(ligne.device ?? ""),
    connectee: Boolean(ligne.signed_in),
  }));
}

/**
 * Ce que la recherche croisée sait d'un compte : l'identité et la date d'inscription.
 * Les compteurs de suivi demandent une agrégation en base (`admin_suivi_comptes`) que
 * la recherche ne fait pas : les afficher à zéro ferait croire à un apprenant inactif
 * alors qu'il ne figure simplement pas dans cette requête.
 */
export type CompteResume = Pick<Compte, "id" | "nom" | "email" | "role" | "inscrit">;

export type ResultatsRecherche = {
  comptes: CompteResume[];
  transactions: Transaction[];
  parcours: { id: string; titre: string; categorie: string; niveau: string; publie: boolean }[];
};

/**
 * Les jetons de filtre PostgREST ne connaissent pas d'échappement : une virgule ou une parenthèse
 * dans la saisie changerait la structure du filtre `.or()`. On les remplace par des espaces, ce
 * qui ne peut casser aucune recherche réelle (ni un nom, ni un e-mail, ni un titre de cours n'en
 * contient).
 */
function jetonRecherche(term: string): string {
  return term.replace(/[(),"\\]/g, " ").replace(/%/g, "").trim().slice(0, 60);
}

/** Recherche croisée du back-office : comptes, transactions et catalogue en une saisie. */
export async function rechercher(
  terme: string,
): Promise<ResultatsRecherche | null> {
  const supabase = createServiceSupabase();
  const jeton = jetonRecherche(terme);
  if (!supabase || jeton.length < 2) return null;

  const comptes = await supabase
    .from("profiles")
    .select("id, full_name, email, role, created_at")
    .or(`full_name.ilike.%${jeton}%,email.ilike.%${jeton}%`)
    .order("created_at", { ascending: false })
    .limit(30);

  if (comptes.error) {
    console.error("[admin] recherche comptes", comptes.error.message);
    return null;
  }

  // Les transactions n'ont pas de nom de client dans `purchases` : on passe par les identifiants
  // trouvés côté profils pour qu'une recherche sur « Otuka » sorte aussi les paiements d'Otuka.
  const identifiants = (comptes.data ?? []).map((l: Record<string, unknown>) => String(l.id));
  const [transactions, parcours] = await Promise.all([
    supabase
      .from("purchases")
      .select(
        "id, user_id, status, amount_usd, currency, provider, created_at, paid_at, level, categories(name)",
      )
      .or(
        identifiants.length
          ? `level.ilike.%${jeton}%,user_id.in.(${identifiants.join(",")})`
          : `level.ilike.%${jeton}%`,
      )
      .order("created_at", { ascending: false })
      .limit(30),
    supabase
      .from("tracks")
      .select("id, title, level, published, categories(name)")
      .ilike("title", `%${jeton}%`)
      .order("title")
      .limit(30),
  ]);

  const echec = [transactions, parcours].find((r) => r.error);
  if (echec?.error) {
    console.error("[admin] recherche", echec.error.message);
    return null;
  }

  const lignesTransactions = transactions.data ?? [];
  const noms = await nomsClients(
    supabase,
    [...new Set(lignesTransactions.map((l: Record<string, unknown>) => String(l.user_id)))],
  );

  return {
    comptes: (comptes.data ?? []).map((ligne: Record<string, unknown>) => ({
      id: String(ligne.id),
      nom: String(ligne.full_name ?? ""),
      email: String(ligne.email ?? ""),
      role: String(ligne.role ?? "learner"),
      inscrit: String(ligne.created_at),
    })),
    transactions: lignesTransactions.map((ligne: Record<string, unknown>) => {
      const categorie = (ligne.categories ?? {}) as { name?: string };
      const client = noms.get(String(ligne.user_id));
      return {
        id: String(ligne.id),
        client: client?.nom ?? "",
        email: client?.email ?? "",
        article: categorie.name ?? String(ligne.level ?? ""),
        niveau: String(ligne.level ?? ""),
        montant: Number(ligne.amount_usd ?? 0),
        devise: String(ligne.currency ?? "CDF"),
        fournisseur: String(ligne.provider ?? ""),
        statut: String(ligne.status ?? ""),
        cree: String(ligne.created_at),
        paye: ligne.paid_at ? String(ligne.paid_at) : null,
      };
    }),
    parcours: (parcours.data ?? []).map((ligne: Record<string, unknown>) => {
      const categorie = (ligne.categories ?? {}) as { name?: string };
      return {
        id: String(ligne.id),
        titre: String(ligne.title),
        categorie: categorie.name ?? "",
        niveau: String(ligne.level ?? ""),
        publie: Boolean(ligne.published),
      };
    }),
  };
}
