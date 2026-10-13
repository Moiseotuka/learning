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

const plansPath = `${links.admin}/formateur-plans`;
const planCodePattern = /^[a-z][a-z0-9_]{1,30}$/;

function readIntValue(formData: FormData, key: string, max: number) {
  const parsed = Number.parseInt(readTextValue(formData, key), 10);
  if (!Number.isInteger(parsed) || parsed < 0 || parsed > max) return null;
  return parsed;
}

/**
 * Le barème formateur est éditable ici : aucune redeploiement pour changer une
 * durée ou un prix. Écritures en service role, `instructor_plans` étant
 * en lecture seule côté client.
 */
export async function saveInstructorPlans(formData: FormData) {
  await requireAdmin(links.admin);

  const supabase = createServiceSupabase();
  if (!supabase) {
    redirect(`${plansPath}?notice=error`);
  }

  const ids = String(formData.get("plans") ?? "")
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);

  const rows: Record<string, unknown>[] = [];
  for (const id of ids) {
    const label = readTextValue(formData, `label:${id}`);
    const durationDays = readIntValue(formData, `days:${id}`, 3650);
    const priceFc = readIntValue(formData, `price:${id}`, 100_000_000);
    const seatsLimit = readIntValue(formData, `seats:${id}`, 2000);
    const trackLimit = readIntValue(formData, `tracks:${id}`, 200);
    const discountPct = readIntValue(formData, `discount:${id}`, 90);

    if (label.length < 1 || !durationDays || priceFc === null || !seatsLimit || !trackLimit || !discountPct) {
      console.error("[admin] barème formateur invalide", { id });
      redirect(`${plansPath}?notice=error`);
    }

    rows.push({
      id,
      label,
      duration_days: durationDays,
      price_fc: priceFc,
      seats_limit: seatsLimit,
      track_limit: trackLimit,
      discount_pct: discountPct,
      highlight: readTextValue(formData, `highlight:${id}`) || null,
      published: formData.get(`published:${id}`) === "on",
    });
  }

  if (rows.length === 0) {
    redirect(`${plansPath}?notice=error`);
  }

  const { error } = await supabase
    .from("instructor_plans")
    .upsert(rows, { onConflict: "id" });
  if (error) {
    console.error("[admin] barème formateur", error.code, error.message);
    redirect(`${plansPath}?notice=error`);
  }

  revalidatePath("/", "layout");
  redirect(`${plansPath}?notice=plansSaved`);
}

export async function createInstructorPlan(
  _prevState: AdminFormState | undefined,
  formData: FormData,
): Promise<AdminFormState> {
  await requireAdmin(links.admin);

  const code = readTextValue(formData, "code").toLowerCase();
  const label = readTextValue(formData, "label");
  const durationDays = readIntValue(formData, "days", 3650);
  const priceFc = readIntValue(formData, "price", 100_000_000);
  const seatsLimit = readIntValue(formData, "seats", 2000);
  const trackLimit = readIntValue(formData, "tracks", 200);

  const fieldErrors: Record<string, string> = {};
  if (!planCodePattern.test(code)) fieldErrors.code = t.plans.codeHint;
  if (label.length < 2) fieldErrors.label = messages.auth.errors.required;
  if (!durationDays) fieldErrors.days = messages.auth.errors.required;
  if (priceFc === null) fieldErrors.price = messages.auth.errors.required;
  if (!seatsLimit) fieldErrors.seats = messages.auth.errors.required;
  if (!trackLimit) fieldErrors.tracks = messages.auth.errors.required;
  if (Object.keys(fieldErrors).length > 0) {
    return { status: "error", fieldErrors };
  }

  const supabase = createServiceSupabase();
  if (!supabase) {
    return { status: "error", message: t.notConfigured };
  }

  const { count } = await supabase
    .from("instructor_plans")
    .select("id", { count: "exact", head: true });

  const { error } = await supabase.from("instructor_plans").insert({
    id: code,
    label,
    duration_days: durationDays,
    price_fc: priceFc,
    seats_limit: seatsLimit,
    track_limit: trackLimit,
    discount_pct: readIntValue(formData, "discount", 90) ?? 0,
    highlight: readTextValue(formData, "highlight") || null,
    published: true,
    position: (count ?? 0) + 1,
  });
  if (error) {
    if (error.code === "23505") {
      return { status: "error", fieldErrors: { code: t.plans.codeHint } };
    }
    console.error("[admin] formule formateur", error.code, error.message);
    return { status: "error", message: t.saveFailed };
  }

  revalidatePath("/", "layout");
  redirect(`${plansPath}?notice=planCreated`);
}
