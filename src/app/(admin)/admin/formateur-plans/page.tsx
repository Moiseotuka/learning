import { AdminNotice } from "@/components/admin/admin-notice";
import { InstructorPlanForm } from "@/components/admin/instructor-plan-form";
import { InstructorPlanGrid, type AdminPlan } from "@/components/admin/instructor-plan-grid";
import { messages } from "@/i18n";
import { createServerSupabase } from "@/lib/supabase/server";

const t = messages.admin;

export default async function AdminInstructorPlansPage({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string }>;
}) {
  const [{ notice }, supabase] = await Promise.all([
    searchParams,
    createServerSupabase(),
  ]);

  const rows = supabase
    ? (
        await supabase
          .from("instructor_plans")
          .select(
            "id,label,duration_days,price_fc,seats_limit,track_limit,discount_pct,highlight,published",
          )
          .order("position")
          .order("duration_days")
      ).data
    : null;

  const plans: AdminPlan[] = ((rows ?? []) as Record<string, unknown>[]).map(
    (row) => ({
      id: String(row.id),
      label: String(row.label ?? ""),
      durationDays: Number(row.duration_days ?? 30),
      priceFc: Number(row.price_fc ?? 0),
      seatsLimit: Number(row.seats_limit ?? 25),
      trackLimit: Number(row.track_limit ?? 3),
      discountPct: Number(row.discount_pct ?? 0),
      highlight: (row.highlight as string | null) ?? null,
      published: row.published === true,
    }),
  );

  return (
    <div className="space-y-6">
      <AdminNotice notice={notice} />

      <div>
        <h2 className="text-lg font-semibold text-foreground">{t.plans.title}</h2>
        <p className="mt-1 max-w-2xl text-sm leading-relaxed text-muted-foreground">
          {t.plans.intro}
        </p>
      </div>

      {plans.length === 0 ? null : <InstructorPlanGrid plans={plans} />}

      <section className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
        <h3 className="text-sm font-semibold text-foreground">{t.plans.addTitle}</h3>
        <div className="mt-4">
          <InstructorPlanForm />
        </div>
      </section>
    </div>
  );
}
