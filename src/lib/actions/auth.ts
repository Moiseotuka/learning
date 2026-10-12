"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { links, resolveSiteUrl } from "@/config/site";
import { messages } from "@/i18n";
import {
  isStrongPassword,
  isValidEmail,
  sanitizeInternalPath,
  type AuthFormState,
} from "@/lib/auth/validation";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { findAccountByEmail, isExistingAccountResponse } from "@/lib/supabase/admin";
import { createServerSupabase } from "@/lib/supabase/server";

const t = messages.auth;

function readText(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

function authErrorCode(error: unknown) {
  return typeof error === "object" && error !== null && "code" in error
    ? String((error as { code: unknown }).code)
    : "";
}

function authErrorMessage(error: unknown, fallback: string) {
  switch (authErrorCode(error)) {
    case "invalid_credentials":
      return t.errors.invalidCredentials;
    case "email_not_confirmed":
      return t.errors.emailNotConfirmed;
    case "user_already_exists":
      return t.errors.emailTaken;
    case "too_many_requests":
    case "rate_limit_exceeded":
      return t.errors.tooManyRequests;
    case "over_email_send_rate_limit":
    case "email_rate_limit_exceeded":
      return t.errors.emailTooManyRequests;
    case "weak_password":
      return t.errors.passwordWeak;
    default:
      return fallback;
  }
}

export async function login(
  _prevState: AuthFormState,
  formData: FormData,
): Promise<AuthFormState> {
  const email = readText(formData, "email");
  const password = readText(formData, "password");
  const next = sanitizeInternalPath(formData.get("next"));

  const fieldErrors: NonNullable<AuthFormState>["fieldErrors"] = {};
  if (!email) fieldErrors.email = t.errors.required;
  else if (!isValidEmail(email)) fieldErrors.email = t.errors.emailInvalid;
  if (!password) fieldErrors.password = t.errors.required;

  if (Object.keys(fieldErrors).length > 0) {
    return { status: "error", fieldErrors };
  }

  if (!isSupabaseConfigured) {
    return { status: "error", message: t.errors.notConfigured };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { status: "error", message: t.errors.notConfigured };
  }

  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    return { status: "error", message: authErrorMessage(error, t.errors.generic) };
  }

  revalidatePath("/", "layout");
  // Un apprenant qui se connecte vient travailler : il atterrit sur son espace,
  // pas sur la page d'accueil marketing.
  redirect(next ?? links.dashboard);
}

export async function signup(
  _prevState: AuthFormState,
  formData: FormData,
): Promise<AuthFormState> {
  const fullName = readText(formData, "fullName");
  const email = readText(formData, "email");
  const password = readText(formData, "password");
  const confirm = readText(formData, "confirm");

  const fieldErrors: NonNullable<AuthFormState>["fieldErrors"] = {};
  if (fullName.length < 2) fieldErrors.fullName = t.errors.nameTooShort;
  if (!email) fieldErrors.email = t.errors.required;
  else if (!isValidEmail(email)) fieldErrors.email = t.errors.emailInvalid;
  if (!password) fieldErrors.password = t.errors.required;
  else if (!isStrongPassword(password)) fieldErrors.password = t.errors.passwordWeak;
  if (confirm !== password) fieldErrors.confirm = t.errors.passwordMismatch;

  if (Object.keys(fieldErrors).length > 0) {
    return { status: "error", fieldErrors };
  }

  if (!isSupabaseConfigured) {
    return { status: "error", message: t.errors.notConfigured };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { status: "error", message: t.errors.notConfigured };
  }

  const existing = await findAccountByEmail(email);
  if (existing?.confirmed) {
    return { status: "error", message: t.errors.emailTaken };
  }

  const publicUrl = resolveSiteUrl();

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { full_name: fullName },
      emailRedirectTo: `${publicUrl}/auth/confirm`,
    },
  });

  if (error) {
    return { status: "error", message: authErrorMessage(error, t.errors.generic) };
  }

  if (isExistingAccountResponse(data.user)) {
    const account = existing ?? (await findAccountByEmail(email));
    if (account?.confirmed) {
      return { status: "error", message: t.errors.emailTaken };
    }
    if (account === null) {
      return { status: "error", message: t.errors.emailExists };
    }
    return { status: "success", message: t.confirmSent(email) };
  }

  if (data.session) {
    revalidatePath("/", "layout");
    redirect(links.dashboard);
  }

  return { status: "success", message: t.confirmSent(email) };
}

export async function loginWithGoogle(formData: FormData): Promise<void> {
  const next = sanitizeInternalPath(formData.get("next")) ?? links.dashboard;

  if (!isSupabaseConfigured) redirect(links.login);

  const supabase = await createServerSupabase();
  if (!supabase) redirect(links.login);

  const publicUrl = resolveSiteUrl();

  let destination: string;
  try {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${publicUrl}/auth/callback?next=${encodeURIComponent(next)}` },
    });
    if (error) throw error;
    destination = data.url;
  } catch {
    redirect(`${links.login}?erreur=google`);
  }

  redirect(destination);
}

export async function signOut(): Promise<void> {
  const supabase = await createServerSupabase();
  if (supabase) await supabase.auth.signOut();

  revalidatePath("/", "layout");
  redirect(links.home);
}

export async function requestPasswordReset(
  _prevState: AuthFormState,
  formData: FormData,
): Promise<AuthFormState> {
  const email = readText(formData, "email");

  const fieldErrors: NonNullable<AuthFormState>["fieldErrors"] = {};
  if (!email) fieldErrors.email = t.errors.required;
  else if (!isValidEmail(email)) fieldErrors.email = t.errors.emailInvalid;

  if (Object.keys(fieldErrors).length > 0) {
    return { status: "error", fieldErrors };
  }

  if (!isSupabaseConfigured) {
    return { status: "error", message: t.errors.notConfigured };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { status: "error", message: t.errors.notConfigured };
  }

  const publicUrl = resolveSiteUrl();

  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${publicUrl}${links.resetPassword}`,
  });

  if (error) {
    return {
      status: "error",
      message: authErrorMessage(error, t.errors.generic),
    };
  }

  return { status: "success", message: t.resetSent };
}

export async function updatePassword(
  _prevState: AuthFormState,
  formData: FormData,
): Promise<AuthFormState> {
  const password = readText(formData, "password");
  const confirm = readText(formData, "confirm");

  const fieldErrors: NonNullable<AuthFormState>["fieldErrors"] = {};
  if (!password) fieldErrors.password = t.errors.required;
  else if (!isStrongPassword(password)) fieldErrors.password = t.errors.passwordWeak;
  if (confirm !== password) fieldErrors.confirm = t.errors.passwordMismatch;

  if (Object.keys(fieldErrors).length > 0) {
    return { status: "error", fieldErrors };
  }

  if (!isSupabaseConfigured) {
    return { status: "error", message: t.errors.notConfigured };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { status: "error", message: t.errors.notConfigured };
  }

  const { error } = await supabase.auth.updateUser({ password });

  if (error) {
    const code = authErrorCode(error);
    if (
      code === "session_missing" ||
      code === "session_not_found" ||
      code === "session_expired"
    ) {
      return { status: "error", message: t.noticeResetLinkInvalid };
    }
    return { status: "error", message: authErrorMessage(error, t.errors.generic) };
  }

  await supabase.auth.signOut();
  revalidatePath("/", "layout");
  redirect(`${links.login}?confirmation=motdepasse`);
}
