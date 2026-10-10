import { ArrowLeftIcon } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

import { AdminNotice } from "@/components/admin/admin-notice";
import { CategoryForm } from "@/components/admin/category-form";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { getAdminCategories } from "@/lib/catalog/queries";

const t = messages.admin;

export default async function EditCategoryPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ notice?: string }>;
}) {
  const [{ id }, { notice }] = await Promise.all([params, searchParams]);

  const categories = await getAdminCategories();
  const category = categories.find((item) => item.id === id);
  if (!category) notFound();

  return (
    <div className="space-y-6">
      <AdminNotice notice={notice} />

      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold text-foreground">
            {t.editTitle}
          </h2>
          <p className="mt-1 text-sm text-muted-foreground">{category.name}</p>
        </div>
        <Button asChild variant="outline" className="h-9 px-4">
          <Link href="/admin/categories">
            <ArrowLeftIcon className="size-4" aria-hidden />
            {t.backToList}
          </Link>
        </Button>
      </div>

      <div className="rounded-2xl border border-hairline bg-card p-5 sm:p-6">
        <CategoryForm category={category} />
      </div>
    </div>
  );
}
