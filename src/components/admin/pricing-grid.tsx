"use client";

import { useState } from "react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { levels, type LevelType } from "@/config/catalog";
import { messages } from "@/i18n";
import { savePricing } from "@/lib/actions/admin";
import { cn } from "cn";

const t = messages.admin.pricing;

export function PricingGrid({
  categories,
  prices,
}: {
  categories: { id: string; name: string }[];
  prices: Record<string, Partial<Record<LevelType, number>>>;
}) {
  const [dirty, setDirty] = useState(false);

  return (
    <form action={savePricing} onChange={() => setDirty(true)}>
      <input
        type="hidden"
        name="categories"
        value={categories.map((category) => category.id).join(",")}
      />

      <div className="overflow-x-auto rounded-2xl border border-hairline bg-card">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-hairline text-left text-xs font-medium uppercase tracking-wide text-muted-foreground">
              <th className="px-4 py-3">{t.domainColumn}</th>
              {levels.map((level) => (
                <th key={level} className="px-4 py-3">
                  {messages.common.levels[level]}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {categories.map((category) => (
              <tr
                key={category.id}
                className="border-b border-hairline last:border-0"
              >
                <td className="px-4 py-3 font-medium text-foreground">
                  {category.name}
                </td>
                {levels.map((level) => {
                  if (level === "debutant") {
                    return (
                      <td key={level} className="px-4 py-3">
                        <Badge
                          variant="secondary"
                          className="rounded-full bg-emerald-500/12 text-emerald-600 dark:text-emerald-400"
                        >
                          {t.free}
                        </Badge>
                      </td>
                    );
                  }

                  const value = prices[category.id]?.[level];
                  return (
                    <td key={level} className="px-4 py-3">
                      <span className="flex items-center gap-1.5">
                        <span className="text-xs text-muted-foreground">
                          CDF
                        </span>
                        <input
                          type="number"
                          min={0}
                          step={1}
                          inputMode="numeric"
                          name={`price:${category.id}:${level}`}
                          defaultValue={value ?? ""}
                          placeholder="—"
                          aria-label={`${category.name} · ${messages.common.levels[level]}`}
                          className={cn(
                            "h-9 w-24 rounded-md border border-input bg-background/60 px-2.5 text-sm tabular-nums text-foreground",
                            "focus:border-electric/60 focus:outline-none",
                          )}
                        />
                      </span>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
        <p className="text-xs text-muted-foreground">{t.currencyHint}</p>
        <Button type="submit" className="h-9 px-4" disabled={!dirty}>
          {t.save}
        </Button>
      </div>
    </form>
  );
}
