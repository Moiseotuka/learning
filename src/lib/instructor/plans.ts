import { cache } from "react";

import { createServerSupabase } from "@/lib/supabase/server";

export type InstructorPlan = {
  id: string;
  label: string;
  durationDays: number;
  priceFc: number;
  seatsLimit: number;
  trackLimit: number;
  discountPct: number;
  highlight: string | null;
};

type PlanRow = {
  id: string;
  label: string;
  duration_days: number;
  price_fc: number;
  seats_limit: number;
  track_limit: number;
  discount_pct: number;
  highlight: string | null;
};

function toPlan(row: PlanRow): InstructorPlan {
  return {
    id: row.id,
    label: row.label,
    durationDays: row.duration_days,
    priceFc: row.price_fc,
    seatsLimit: row.seats_limit,
    trackLimit: row.track_limit,
    discountPct: row.discount_pct,
    highlight: row.highlight,
  };
}

/** Barème publié, dans l'ordre commercial (du plus court au plus long). */
export const getInstructorPlans = cache(async (): Promise<InstructorPlan[]> => {
  const supabase = await createServerSupabase();
  if (!supabase) return [];

  const { data } = await supabase
    .from("instructor_plans")
    .select(
      "id,label,duration_days,price_fc,seats_limit,track_limit,discount_pct,highlight",
    )
    .eq("published", true)
    .order("position");

  return ((data as PlanRow[] | null) ?? []).map(toPlan);
});

export async function getInstructorPlan(
  planId: string,
): Promise<InstructorPlan | null> {
  const plans = await getInstructorPlans();
  return plans.find((plan) => plan.id === planId) ?? null;
}

/** Prix ramené à un mois de 30 jours : c'est ce chiffre qui baisse avec la durée. */
export function monthlyPriceFc(plan: InstructorPlan): number {
  return Math.round((plan.priceFc / plan.durationDays) * 30);
}
