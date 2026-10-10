import { cache } from "react";
import { redirect } from "next/navigation";

import { links } from "@/config/site";
import { createServerSupabase } from "@/lib/supabase/server";

export const getUser = cache(async () => {
  const supabase = await createServerSupabase();
  if (!supabase) return null;

  const { data } = await supabase.auth.getUser();
  return data.user;
});

export async function requireUser(path: string) {
  const user = await getUser();
  if (!user) {
    redirect(`${links.login}?next=${encodeURIComponent(path)}`);
  }
  return user;
}

export type Profile = {
  id: string;
  email: string | null;
  full_name: string | null;
  role: string;
  phone: string | null;
  avatar_url: string | null;
};

export const getProfile = cache(async (): Promise<Profile | null> => {
  const user = await getUser();
  if (!user) return null;

  const supabase = await createServerSupabase();
  if (!supabase) return null;

  const { data } = await supabase
    .from("profiles")
    .select("id,email,full_name,role,phone,avatar_url")
    .eq("id", user.id)
    .maybeSingle();

  return (data as Profile | null) ?? null;
});

export async function requireAdmin(path: string) {
  const user = await requireUser(path);
  const profile = await getProfile();

  if (profile?.role !== "admin") {
    redirect(links.forbidden);
  }

  return user;
}
