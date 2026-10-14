import { createServiceSupabase } from "@/lib/supabase/service";

/**
 * Un formateur doit avoir prouvé son niveau avant d'enseigner : les deux
 * extrémités hautes du catalogue (avancé, projet de fin de parcours) et le
 * parcours complet sont les seuls certificats qui donnent ce droit. Débuter un
 * niveau ne suffit pas — la plateforme engage sa réputation sur chaque diplôme
 * qu'elle laisse délivrer.
 */
const QUALIFYING_LEVELS = ["avance", "projet", "parcours"];

export type InstructorEligibility = {
  /** Vrai quand l'utilisateur peut souscrire un abonnement formateur. */
  allowed: boolean;
  /** Le certificat qui ouvre le droit, pour l'afficher sur la page. */
  certificate: { title: string; level: string } | null;
};

export async function getInstructorEligibility(
  userId: string,
): Promise<InstructorEligibility> {
  const none: InstructorEligibility = { allowed: false, certificate: null };
  if (!userId) return none;

  const supabase = createServiceSupabase();
  if (!supabase) return none;

  // L'administrateur est la seule exception : il doit pouvoir ouvrir une classe
  // de test sans avoir à repasser les examens de la plateforme.
  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", userId)
    .maybeSingle<{ role: string }>();
  if (profile?.role === "admin") {
    return { allowed: true, certificate: null };
  }

  const { data } = await supabase
    .from("certificates")
    .select("title,level")
    .eq("user_id", userId)
    .in("level", QUALIFYING_LEVELS)
    .order("issued_at", { ascending: false })
    .limit(1)
    .maybeSingle<{ title: string; level: string }>();

  if (!data) return none;
  return { allowed: true, certificate: data };
}
