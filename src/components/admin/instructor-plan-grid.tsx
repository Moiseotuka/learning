"use client";

import { useState } from "react";

import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { saveInstructorPlans } from "@/lib/actions/admin";
import { formatFc } from "@/lib/instructor/format";
import { cn } from "cn";

const t = messages.admin;

export type AdminPlan = {
  id: string;
  label: string;
  durationDays: number;
  priceFc: number;
  seatsLimit: number;
  trackLimit: number;
  discountPct: number;
  highlight: string | null;
  published: boolean;
};

const cellInput =
  "h-9 w-full min-w-16 rounded-md border border-input bg-background/60 px-2 text-sm tabular-nums text-foreground focus:border-electric/60 focus:outline-none";

export function InstructorPlanGrid({ plans }: { plans: AdminPlan[] }) {
  const [dirty, setDirty] = useState(false);

  return (
    <form
      action={saveInstructorPlans}
      onChange={() => setDirty(true)}
      className="space-y-4"
    >
      <input
        type="hidden"
        name="plans"
        value={plans.map((plan) => plan.id).join(",")}
      />

      <div className="overflow-x-auto rounded-2xl border border-hairline bg-card">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-hairline text-left text-xs font-medium uppercase tracking-wide text-muted-foreground">
              <th className="px-3 py-3">{t.plans.fields.code}</th>
              <th className="px-3 py-3">{t.plans.fields.label}</th>
              <th className="px-3 py-3">{t.plans.fields.days}</th>
              <th className="px-3 py-3">{t.plans.fields.price}</th>
              <th className="px-3 py-3">{t.plans.fields.seats}</th>
              <th className="px-3 py-3">{t.plans.fields.tracks}</th>
              <th className="px-3 py-3">{t.plans.fields.discount}</th>
              <th className="px-3 py-3">{t.plans.fields.highlight}</th>
              <th className="px-3 py-3">{t.plans.fields.published}</th>
            </tr>
          </thead>
          <tbody>
            {plans.map((plan) => (
              <tr key={plan.id} className="border-b border-hairline last:border-0">
                <td className="px-3 py-2.5 font-mono text-xs text-muted-foreground">
                  {plan.id}
                </td>
                <td className="px-3 py-2.5">
                  <input
                    name={`label:${plan.id}`}
                    defaultValue={plan.label}
                    required
                    aria-label={`${plan.label} · ${t.plans.fields.label}`}
                    className={cn(cellInput, "w-32")}
                  />
                </td>
                <td className="px-3 py-2.5">
                  <input
                    type="number"
                    min={1}
                    max={3650}
                    step={1}
                    name={`days:${plan.id}`}
                    defaultValue={plan.durationDays}
                    required
                    aria-label={`${plan.label} · ${t.plans.fields.days}`}
                    className={cn(cellInput, "w-20")}
                  />
                </td>
                <td className="px-3 py-2.5">
                  <input
                    type="number"
                    min={0}
                    step={500}
                    name={`price:${plan.id}`}
                    defaultValue={plan.priceFc}
                    required
                    aria-label={`${plan.label} · ${t.plans.fields.price}`}
                    className={cn(cellInput, "w-28")}
                  />
                  <span className="mt-1 block text-[11px] text-muted-foreground tabular-nums">
                    {formatFc(plan.priceFc)}
                  </span>
                </td>
                <td className="px-3 py-2.5">
                  <input
                    type="number"
                    min={1}
                    max={2000}
                    step={1}
                    name={`seats:${plan.id}`}
                    defaultValue={plan.seatsLimit}
                    required
                    aria-label={`${plan.label} · ${t.plans.fields.seats}`}
                    className={cn(cellInput, "w-20")}
                  />
                </td>
                <td className="px-3 py-2.5">
                  <input
                    type="number"
                    min={1}
                    max={200}
                    step={1}
                    name={`tracks:${plan.id}`}
                    defaultValue={plan.trackLimit}
                    required
                    aria-label={`${plan.label} · ${t.plans.fields.tracks}`}
                    className={cn(cellInput, "w-20")}
                  />
                </td>
                <td className="px-3 py-2.5">
                  <input
                    type="number"
                    min={0}
                    max={90}
                    step={1}
                    name={`discount:${plan.id}`}
                    defaultValue={plan.discountPct}
                    required
                    aria-label={`${plan.label} · ${t.plans.fields.discount}`}
                    className={cn(cellInput, "w-16")}
                  />
                </td>
                <td className="px-3 py-2.5">
                  <input
                    name={`highlight:${plan.id}`}
                    defaultValue={plan.highlight ?? ""}
                    aria-label={`${plan.label} · ${t.plans.fields.highlight}`}
                    className={cn(cellInput, "w-40")}
                  />
                </td>
                <td className="px-3 py-2.5">
                  <input
                    type="checkbox"
                    name={`published:${plan.id}`}
                    defaultChecked={plan.published}
                    aria-label={`${plan.label} · ${t.plans.fields.published}`}
                    className="size-4 accent-electric"
                  />
                  {plan.published ? null : (
                    <span className="ml-2 text-[11px] text-muted-foreground">
                      {t.plans.unpublished}
                    </span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-xs text-muted-foreground">{t.plans.currencyHint}</p>
        <Button type="submit" className="h-9 px-4" disabled={!dirty}>
          {t.plans.save}
        </Button>
      </div>
    </form>
  );
}
