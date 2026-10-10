import { createServiceSupabase } from "@/lib/supabase/service";

export type ServiceSupabase = NonNullable<
  ReturnType<typeof createServiceSupabase>
>;

/**
 * Cible après un paiement confirmé : premier parcours publié de la catégorie,
 * avec la bannière « niveau débloqué ». À défaut, l'espace apprenant.
 */
export async function trackNoticeUrl(
  supabase: ServiceSupabase,
  categoryId: string,
): Promise<string> {
  const { data: track } = await supabase
    .from("tracks")
    .select("slug")
    .eq("category_id", categoryId)
    .eq("published", true)
    .order("position")
    .limit(1)
    .maybeSingle<{ slug: string }>();

  return track ? `/app/parcours/${track.slug}?notice=paiement` : "/app";
}
