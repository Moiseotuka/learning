export type AuthField = "fullName" | "email" | "password" | "confirm";

export type AuthFormState =
  | {
      status: "error" | "success";
      message?: string;
      fieldErrors?: Partial<Record<AuthField, string>>;
    }
  | undefined;

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

export function isValidEmail(value: string) {
  return EMAIL_PATTERN.test(value);
}

export function isStrongPassword(value: string) {
  return value.length >= 8 && /[a-zA-Z]/.test(value) && /[0-9]/.test(value);
}

export function sanitizeInternalPath(value: FormDataEntryValue | string | null) {
  const raw = typeof value === "string" ? value.trim() : "";
  if (!raw.startsWith("/")) return null;
  if (raw.startsWith("//") || raw.startsWith("/\\")) return null;
  if (raw.includes("..") || raw.includes("\\")) return null;
  return raw;
}
