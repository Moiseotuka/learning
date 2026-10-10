import { getSupabaseEnv } from "@/lib/supabase/config";

type AdminIdentity = {
  identity_data?: { email_verified?: boolean | null } | null;
};

type AdminUser = {
  email?: string | null;
  email_confirmed_at?: string | null;
  confirmed_at?: string | null;
  identities?: AdminIdentity[] | null;
};

export type ExistingAccount = { confirmed: boolean };

export async function findAccountByEmail(
  email: string,
): Promise<ExistingAccount | null> {
  const env = getSupabaseEnv();
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";
  if (!env || !serviceKey) return null;

  try {
    const response = await fetch(
      `${env.url}/auth/v1/admin/users?filter=${encodeURIComponent(email)}`,
      {
        headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
        cache: "no-store",
      },
    );
    if (!response.ok) return null;

    const payload = (await response.json()) as { users?: AdminUser[] };
    const target = email.trim().toLowerCase();
    const user = (payload.users ?? []).find(
      (candidate) => (candidate.email ?? "").toLowerCase() === target,
    );
    if (!user) return null;

    const confirmed =
      Boolean(user.email_confirmed_at ?? user.confirmed_at) ||
      (user.identities ?? []).some(
        (identity) => identity.identity_data?.email_verified === true,
      );

    return { confirmed };
  } catch {
    return null;
  }
}

export function isExistingAccountResponse(user: {
  identities?: unknown[] | null;
} | null): boolean {
  return !user || !Array.isArray(user.identities) || user.identities.length === 0;
}
