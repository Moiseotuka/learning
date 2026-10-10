"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { links } from "@/config/site";
import { messages } from "@/i18n";
import { parseCategoryForm, readTextValue } from "@/lib/admin/form";
import type { AdminFormState } from "@/lib/admin/form";
import { requireAdmin } from "@/lib/auth/dal";
import { createServiceSupabase } from "@/lib/supabase/service";
import { createServerSupabase } from "@/lib/supabase/server";

const t = messages.admin;

const listPath = `${links.admin}/categories`;

export async function saveCategory(
  _prevState: AdminFormState | undefined,
  formData: FormData,
): Promise<AdminFormState> {
  await requireAdmin(links.admin);

  const parsed = parseCategoryForm(formData);
  if (!parsed.ok) {
    return { status: "error", fieldErrors: parsed.fieldErrors };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { status: "error", message: t.notConfigured };
  }

  const id = readTextValue(formData, "id");
  const row = { ...parsed.value, levels: parsed.value.levels };

  if (id) {
    const { error } = await supabase.from("categories").update(row).eq("id", id);
    if (error) {
      return { status: "error", message: errorText(error.code) };
    }

    revalidatePath("/", "layout");
    redirect(`${listPath}/${id}?notice=updated`);
  }

  const { error } = await supabase
    .from("categories")
    .insert({ ...row, id: row.slug, track_count: 0 });

  if (error) {
    if (error.code === "23505") {
      return {
        status: "error",
        fieldErrors: { slug: t.fields.slugHint },
      };
    }
    return { status: "error", message: errorText(error.code) };
  }

  revalidatePath("/", "layout");
  redirect(`${listPath}?notice=created`);
}

export async function deleteCategory(formData: FormData) {
  await requireAdmin(links.admin);

  const id = readTextValue(formData, "id");
  if (!id) {
    redirect(`${listPath}?notice=error`);
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    redirect(`${listPath}?notice=error`);
  }

  const { error } = await supabase.from("categories").delete().eq("id", id);
  if (error) {
    redirect(`${listPath}?notice=error`);
  }

  revalidatePath("/", "layout");
  redirect(`${listPath}?notice=deleted`);
}

const pricingPath = `${links.admin}/tarifs`;
const PRICED_LEVELS = ["intermediaire", "avance", "projet"] as const;

export async function savePricing(formData: FormData) {
  await requireAdmin(links.admin);

  // Écritures réservées au service role : la migration 202610030001_payments.sql
  // révoque tout droit d'écriture client sur category_level_prices.
  const supabase = createServiceSupabase();
  if (!supabase) {
    redirect(`${pricingPath}?notice=error`);
  }

  const categoryIds = String(formData.get("categories") ?? "")
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);

  const upserts: { category_id: string; level: string; price_usd: number }[] =
    [];
  const clears = new Map<string, string[]>();

  for (const categoryId of categoryIds) {
    for (const level of PRICED_LEVELS) {
      const raw = formData.get(`price:${categoryId}:${level}`);
      const text = typeof raw === "string" ? raw.trim() : "";

      if (text === "") {
        const list = clears.get(level) ?? [];
        list.push(categoryId);
        clears.set(level, list);
        continue;
      }

      const price = Number.parseInt(text, 10);
      if (!Number.isInteger(price) || price < 0) {
        console.error("[admin] pricing: prix invalide", { categoryId, text });
        redirect(`${pricingPath}?notice=error`);
      }
      upserts.push({ category_id: categoryId, level, price_usd: price });
    }
  }

  if (upserts.length > 0) {
    const { error } = await supabase
      .from("category_level_prices")
      .upsert(upserts, { onConflict: "category_id,level" });
    if (error) {
      console.error("[admin] pricing upsert", error.code, error.message);
      redirect(`${pricingPath}?notice=error`);
    }
  }

  for (const [level, ids] of clears) {
    const { error } = await supabase
      .from("category_level_prices")
      .delete()
      .eq("level", level)
      .in("category_id", ids);
    if (error) {
      console.error("[admin] pricing clear", error.code, error.message);
      redirect(`${pricingPath}?notice=error`);
    }
  }

  revalidatePath("/", "layout");
  redirect(`${pricingPath}?notice=saved`);
}

function errorText(code?: string) {
  if (code === "23505") return t.fields.slugHint;
  return t.saveFailed;
}
