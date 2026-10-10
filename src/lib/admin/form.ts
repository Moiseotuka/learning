import { levels as allLevels, type LevelType } from "@/config/catalog";
import { messages } from "@/i18n";

const t = messages.admin;

export type AdminFormState = {
  status: "success" | "error";
  message?: string;
  fieldErrors?: Record<string, string>;
};

export type CategoryInput = {
  name: string;
  slug: string;
  description: string;
  icon: string;
  levels: LevelType[];
  position: number;
  published: boolean;
};

export const slugPattern = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export function readTextValue(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

export function parseCategoryForm(
  formData: FormData,
): { ok: true; value: CategoryInput } | { ok: false; fieldErrors: Record<string, string> } {
  const name = readTextValue(formData, "name");
  const slug = readTextValue(formData, "slug");
  const description = readTextValue(formData, "description");
  const icon = readTextValue(formData, "icon") || "terminal";
  const positionRaw = readTextValue(formData, "position");
  const position = Number(positionRaw || 0);

  const levels = formData
    .getAll("levels")
    .filter((value): value is LevelType =>
      typeof value === "string" && allLevels.includes(value as LevelType),
    );

  const fieldErrors: Record<string, string> = {};
  if (name.length < 2) fieldErrors.name = messages.auth.errors.required;
  if (!slugPattern.test(slug)) fieldErrors.slug = t.fields.slugHint;
  if (levels.length === 0) fieldErrors.levels = messages.auth.errors.required;
  if (!Number.isInteger(position) || position < 0)
    fieldErrors.position = messages.auth.errors.required;

  if (Object.keys(fieldErrors).length > 0) {
    return { ok: false, fieldErrors };
  }

  return {
    ok: true,
    value: {
      name,
      slug,
      description,
      icon,
      levels,
      position,
      published: formData.get("published") === "on",
    },
  };
}
