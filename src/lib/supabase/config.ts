export const supabaseEnv = {
  url: process.env.NEXT_PUBLIC_SUPABASE_URL ?? "",
  anonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "",
};

export const isSupabaseConfigured = Boolean(
  supabaseEnv.url && supabaseEnv.anonKey,
);

export function getSupabaseEnv() {
  if (!isSupabaseConfigured) return null;
  return supabaseEnv;
}
