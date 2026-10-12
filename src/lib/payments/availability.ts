import { createServiceSupabase } from "@/lib/supabase/service";

type Client = NonNullable<ReturnType<typeof createServiceSupabase>>;

/**
 * Un niveau ne se vend que s'il existe du contenu derrière : un tarif saisi au
 * back-office avant la publication des chapitres ne doit jamais déboucher sur un
 * paiement sans leçon.
 */
export async function levelHasContent(
  categoryId: string,
  level: string,
  supabase: Client | null = createServiceSupabase(),
): Promise<boolean> {
  if (!supabase || !categoryId || !level) return false;

  const { data: tracks } = await supabase
    .from("tracks")
    .select("id")
    .eq("category_id", categoryId)
    .eq("published", true);
  const ids = (tracks ?? []).map((track) => track.id);
  if (ids.length === 0) return false;

  const { count } = await supabase
    .from("chapters")
    .select("id", { count: "exact", head: true })
    .in("track_id", ids)
    .eq("level", level)
    .eq("published", true);
  return (count ?? 0) > 0;
}
