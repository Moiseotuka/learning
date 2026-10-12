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
