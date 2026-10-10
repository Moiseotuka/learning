import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import { getSupabaseEnv } from "@/lib/supabase/config";

let cached: SupabaseClient | null | undefined;

export function createPublicSupabase(): SupabaseClient | null {
  if (cached !== undefined) return cached;

  const env = getSupabaseEnv();
  cached = env
    ? createClient(env.url, env.anonKey, {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
          detectSessionInUrl: false,
        },
      })
    : null;

  return cached;
}
