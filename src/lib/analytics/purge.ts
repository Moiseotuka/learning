import { createServiceSupabase } from "@/lib/supabase/service";

/**
 * Les visites ne sont conservées que deux ans.
 *
 * Le tableau de bord n'a besoin que des 90 derniers jours, et promettre une durée de conservation
 * ne veut rien dire si personne ne la tient : cette purge est donc appelée par la tâche
 * périodique, pas par la bonne volonté de l'admin. La table ne contient ni nom, ni e-mail, ni
 * adresse IP (voir `src/lib/analytics/visite.ts`), mais un condensat quotidien : purger efface
 * malgré tout l'historique d'audience, ce qui est l'objet de la promesse.
 */
const JOURS_CONSERVATION = 730;

export async function purgerVieuxVisites(): Promise<{ supprimes: number }> {
  const supabase = createServiceSupabase();
  if (!supabase) return { supprimes: 0 };

  const limite = new Date(Date.now() - JOURS_CONSERVATION * 86_400_000).toISOString();
  const { count, error } = await supabase
    .from("site_visits")
    .delete({ count: "exact" })
    .lt("seen_at", limite);

  if (error) {
    console.error("[analytique] purge des visites", error.message);
    return { supprimes: 0 };
  }

  return { supprimes: count ?? 0 };
}
