import { ArrowLeftIcon } from "lucide-react";
import Link from "next/link";

import { CategoryForm } from "@/components/admin/category-form";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";

const t = messages.admin;

export default function NewCategoryPage() {
  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h2 className="text-lg font-semibold text-foreground">
          {t.createTitle}
        </h2>
        <Button asChild variant="outline" className="h-9 px-4">
          <Link href="/admin/categories">
            <ArrowLeftIcon className="size-4" aria-hidden />
            {t.backToList}
          </Link>
        </Button>
      </div>

      <div className="rounded-2xl border border-hairline bg-card p-5 sm:p-6">
        <CategoryForm />
      </div>
    </div>
  );
}
