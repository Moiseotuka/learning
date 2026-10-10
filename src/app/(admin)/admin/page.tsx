import { ArrowRightIcon, LayersIcon, LayoutGridIcon } from "lucide-react";
import Link from "next/link";

import { AdminNotice } from "@/components/admin/admin-notice";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { getCatalogStats } from "@/lib/catalog/queries";

const t = messages.admin;

export default async function AdminDashboardPage({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string }>;
}) {
  const [{ notice }, stats] = await Promise.all([
    searchParams,
    getCatalogStats(),
  ]);

  const cards = [
    { label: t.stats.categories, value: stats.categories },
    { label: t.stats.publishedCategories, value: stats.publishedCategories },
    { label: t.stats.tracks, value: stats.tracks },
    { label: t.stats.publishedTracks, value: stats.publishedTracks },
  ];

  return (
    <div className="space-y-6">
      <AdminNotice notice={notice} />

      <p className="text-sm text-muted-foreground">{t.dashboardIntro}</p>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map((card) => (
          <div
            key={card.label}
            className="rounded-2xl border border-hairline bg-card p-5"
          >
            <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
              {card.label}
            </p>
            <p className="mt-2 text-3xl font-semibold text-foreground">
              {card.value}
            </p>
          </div>
        ))}
      </div>

      <div className="rounded-2xl border border-hairline bg-card p-5">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <span className="grid size-10 place-items-center rounded-xl bg-electric/12 text-electric">
              <LayoutGridIcon className="size-5" aria-hidden />
            </span>
            <div>
              <p className="text-sm font-semibold text-foreground">
                {t.categoriesTitle}
              </p>
              <p className="text-xs text-muted-foreground">
                {t.categoriesIntro}
              </p>
            </div>
          </div>
          <Button asChild className="h-9 px-4">
            <Link href="/admin/categories">
              {t.manageCategories}
              <ArrowRightIcon className="size-4" aria-hidden />
            </Link>
          </Button>
        </div>
      </div>

      <div className="flex items-center gap-2 text-xs text-muted-foreground">
        <LayersIcon className="size-3.5" aria-hidden />
        {t.stats.tracks} : {stats.tracks}
      </div>
    </div>
  );
}
