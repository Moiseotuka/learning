import { createBrowserClient } from "@supabase/ssr";

import { isSupabaseConfigured, supabaseEnv } from "@/lib/supabase/config";

export function createBrowserSupabase() {
  if (!isSupabaseConfigured) return null;
  return createBrowserClient(supabaseEnv.url, supabaseEnv.anonKey);
}
