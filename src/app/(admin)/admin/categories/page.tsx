import { PlusIcon } from "lucide-react";
import Link from "next/link";

import { AdminNotice } from "@/components/admin/admin-notice";
import { DeleteCategoryButton } from "@/components/admin/delete-category-button";
import { CategoryIcon } from "@/components/category-icon";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { levels, type LevelType } from "@/config/catalog";
import { messages } from "@/i18n";
import { getAdminCategories } from "@/lib/catalog/queries";
import { cn } from "cn";

const t = messages.admin;

export default async function AdminCategoriesPage({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string }>;
}) {
  const [{ notice }, categories] = await Promise.all([
    searchParams,
    getAdminCategories(),
  ]);

  return (
    <div className="space-y-6">
      <AdminNotice notice={notice} />

      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold text-foreground">
            {t.categoriesTitle}
          </h2>
          <p className="mt-1 text-sm text-muted-foreground">
            {t.categoriesIntro}
          </p>
        </div>
        <Button asChild className="h-9 px-4">
          <Link href="/admin/categories/nouveau">
            <PlusIcon className="size-4" aria-hidden />
            {t.create}
          </Link>
        </Button>
      </div>

      {categories.length === 0 ? (
        <p className="rounded-2xl border border-hairline bg-card px-4 py-10 text-center text-sm text-muted-foreground">
          {t.empty}
        </p>
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-hairline bg-card">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-hairline text-left text-xs font-medium uppercase tracking-wide text-muted-foreground">
                <th className="px-4 py-3">{t.columns.name}</th>
                <th className="px-4 py-3">{t.columns.slug}</th>
                <th className="px-4 py-3">{t.columns.levels}</th>
                <th className="px-4 py-3">{t.columns.tracks}</th>
                <th className="px-4 py-3">{t.columns.status}</th>
                <th className="px-4 py-3 text-right">{t.columns.actions}</th>
              </tr>
            </thead>
            <tbody>
              {categories.map((category) => (
                <tr
                  key={category.id}
                  className="border-b border-hairline last:border-0"
                >
                  <td className="px-4 py-3">
                    <span className="flex items-center gap-3">
                      <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-electric/10 text-electric">
                        <CategoryIcon
                          name={category.icon}
                          className="size-4"
                        />
                      </span>
                      <span className="min-w-0">
                        <span className="block font-medium text-foreground">
                          {category.name}
                        </span>
                        <span className="block max-w-md truncate text-xs text-muted-foreground">
                          {category.description}
                        </span>
                      </span>
                    </span>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {category.slug}
                  </td>
                  <td className="px-4 py-3">
                    <span className="flex flex-wrap gap-1">
                      {levels.map((level: LevelType) => {
                        const available = category.levels.includes(level);
                        return (
                          <span
                            key={level}
                            className={cn(
                              "rounded-md border px-1.5 py-0.5 text-[11px] font-medium",
                              available
                                ? "border-hairline text-foreground"
                                : "border-hairline/60 text-muted-foreground/50",
                            )}
                          >
                            {messages.common.levels[level]}
                          </span>
                        );
                      })}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {category.trackCount}
                  </td>
                  <td className="px-4 py-3">
                    <Badge
                      variant="secondary"
                      className={cn(
                        "rounded-full",
                        category.published
                          ? "bg-emerald-500/12 text-emerald-600 dark:text-emerald-400"
                          : "bg-muted text-muted-foreground",
                      )}
                    >
                      {category.published
                        ? t.status.published
                        : t.status.draft}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <span className="flex items-center justify-end gap-1">
                      <Button asChild variant="ghost" size="sm">
                        <Link href={`/admin/categories/${category.id}`}>
                          {t.actions.edit}
                        </Link>
                      </Button>
                      <DeleteCategoryButton id={category.id} />
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
