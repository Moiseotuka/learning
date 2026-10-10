import { AdminNotice } from "@/components/admin/admin-notice";
import { PricingGrid } from "@/components/admin/pricing-grid";
import { type LevelType } from "@/config/catalog";
import { messages } from "@/i18n";
import { createServerSupabase } from "@/lib/supabase/server";

const t = messages.admin.pricing;

export default async function AdminPricingPage({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string }>;
}) {
  const { notice } = await searchParams;

  const supabase = await createServerSupabase();

  if (!supabase) {
    return (
      <div className="space-y-6">
        <AdminNotice notice={notice} />
        <div>
          <h2 className="text-lg font-semibold text-foreground">{t.title}</h2>
          <p className="mt-1 text-sm text-muted-foreground">{t.intro}</p>
        </div>
        <p className="rounded-2xl border border-hairline bg-card px-4 py-10 text-center text-sm text-muted-foreground">
          {messages.admin.notConfigured}
        </p>
      </div>
    );
  }

  const [{ data: categories }, { data: priceRows, error: priceError }] =
    await Promise.all([
      supabase.from("categories").select("id,name").order("position").order("name"),
      supabase.from("category_level_prices").select("category_id,level,price_usd"),
    ]);

  if (priceError) {
    return (
      <div className="space-y-6">
        <AdminNotice notice={notice} />
        <div>
          <h2 className="text-lg font-semibold text-foreground">{t.title}</h2>
          <p className="mt-1 text-sm text-muted-foreground">{t.intro}</p>
        </div>
        <p className="rounded-2xl border border-hairline bg-card px-4 py-10 text-center text-sm text-muted-foreground">
          {t.missingMigration}
        </p>
      </div>
    );
  }

  const prices: Record<string, Partial<Record<LevelType, number>>> = {};
  for (const row of (priceRows ?? []) as {
    category_id: string;
    level: LevelType;
    price_usd: number;
  }[]) {
    prices[row.category_id] = {
      ...prices[row.category_id],
      [row.level]: row.price_usd,
    };
  }

  return (
    <div className="space-y-6">
      <AdminNotice notice={notice} />

      <div>
        <h2 className="text-lg font-semibold text-foreground">{t.title}</h2>
        <p className="mt-1 max-w-2xl text-sm text-muted-foreground">
          {t.intro}
        </p>
      </div>

      <PricingGrid
        categories={(categories ?? []) as { id: string; name: string }[]}
        prices={prices}
      />
    </div>
  );
}
