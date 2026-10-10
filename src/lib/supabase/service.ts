import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import { supabaseEnv } from "@/lib/supabase/config";

let cached: SupabaseClient | null | undefined;

export function createServiceSupabase(): SupabaseClient | null {
  if (cached !== undefined) return cached;

  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";
  cached =
    supabaseEnv.url && serviceKey
      ? createClient(supabaseEnv.url, serviceKey, {
          auth: {
            persistSession: false,
            autoRefreshToken: false,
            detectSessionInUrl: false,
          },
        })
      : null;

  return cached;
}
