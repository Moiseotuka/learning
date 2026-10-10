"use server";

import { revalidatePath } from "next/cache";

import { messages } from "@/i18n";
import { getUser } from "@/lib/auth/dal";
import { isValidEmail } from "@/lib/auth/validation";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { createServerSupabase } from "@/lib/supabase/server";

const t = messages.learner.profil.form;

export type ProfileField = "fullName" | "email" | "phone";

export type ProfileFormState = {
  status: "idle" | "success" | "error" | "email-pending";
  message?: string;
  fieldErrors?: Partial<Record<ProfileField, string>>;
};

export type AvatarResult = {
  status: "success" | "error";
  message?: string;
  avatarUrl?: string;
};

const MAX_AVATAR_BYTES = 2 * 1024 * 1024;
const AVATAR_TYPES: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

function readText(formData: FormData, key: string): string {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

export async function updateProfile(
  _prevState: ProfileFormState | undefined,
  formData: FormData,
): Promise<ProfileFormState> {
  const fullName = readText(formData, "fullName");
  const email = readText(formData, "email");
  const phone = readText(formData, "phone");

  const fieldErrors: Partial<Record<ProfileField, string>> = {};
  if (!fullName) fieldErrors.fullName = t.errors.required;
  else if (fullName.length > 100) fieldErrors.fullName = t.errors.tooLong;
  if (!email) fieldErrors.email = t.errors.required;
  else if (!isValidEmail(email)) fieldErrors.email = t.errors.emailInvalid;
  if (phone && !/^[+0-9][0-9\s().-]{4,24}$/.test(phone)) {
    fieldErrors.phone = t.errors.phoneInvalid;
  }

  if (Object.keys(fieldErrors).length > 0) {
    return { status: "error", fieldErrors };
  }

  if (!isSupabaseConfigured) {
    return { status: "error", message: t.errors.generic };
  }

  const user = await getUser();
  const supabase = await createServerSupabase();
  if (!user || !supabase) {
    return { status: "error", message: t.errors.generic };
  }

  const currentEmail = user.email ?? "";

  const { error: metaError } = await supabase.auth.updateUser({
    data: { full_name: fullName },
  });
  if (metaError) {
    return { status: "error", message: t.errors.generic };
  }

  const { error: profileError } = await supabase
    .from("profiles")
    .update({
      full_name: fullName,
      phone: phone || null,
      ...(email === currentEmail ? { email } : {}),
    })
    .eq("id", user.id);
  if (profileError) {
    return { status: "error", message: t.errors.generic };
  }

  if (email !== currentEmail) {
    const { data, error } = await supabase.auth.updateUser({ email });
    if (error) {
      const code = typeof error === "object" && "code" in error ? String(error.code) : "";
      if (code === "user_already_exists") {
        return {
          status: "error",
          message: t.errors.emailTaken,
          fieldErrors: { email: t.errors.emailTaken },
        };
      }
      if (code === "over_email_send_rate_limit") {
        return {
          status: "error",
          message: t.errors.emailRateLimit,
          fieldErrors: { email: t.errors.emailRateLimit },
        };
      }
      return { status: "error", message: t.errors.generic };
    }

    if (data.user?.email !== email) {
      revalidatePath("/app/profil");
      return { status: "email-pending", message: t.emailPending(email) };
    }
  }

  revalidatePath("/app/profil");
  return { status: "success", message: t.saved };
}

export async function uploadAvatar(file: File): Promise<AvatarResult> {
  if (!isSupabaseConfigured) {
    return { status: "error", message: t.errors.generic };
  }

  const ext = AVATAR_TYPES[file.type];
  if (!ext) {
    return { status: "error", message: t.errors.photoInvalid };
  }
  if (file.size > MAX_AVATAR_BYTES) {
    return { status: "error", message: t.errors.photoTooLarge };
  }

  const user = await getUser();
  const supabase = await createServerSupabase();
  if (!user || !supabase) {
    return { status: "error", message: t.errors.generic };
  }

  const path = `${user.id}/avatar-${Date.now()}.${ext}`;
  const { error: uploadError } = await supabase.storage
    .from("avatars")
    .upload(path, file, { upsert: true, contentType: file.type });
  if (uploadError) {
    return { status: "error", message: t.errors.generic };
  }

  const {
    data: { publicUrl },
  } = supabase.storage.from("avatars").getPublicUrl(path);

  const { error: updateError } = await supabase
    .from("profiles")
    .update({ avatar_url: publicUrl })
    .eq("id", user.id);
  if (updateError) {
    return { status: "error", message: t.errors.generic };
  }

  revalidatePath("/app/profil");
  return { status: "success", avatarUrl: publicUrl };
}
