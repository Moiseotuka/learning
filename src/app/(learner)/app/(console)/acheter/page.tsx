import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeftIcon, CreditCardIcon, ShieldCheckIcon } from "lucide-react";

import { Notice } from "@/components/auth/notice";
import { BuyLevelForm } from "@/components/payment/buy-level-form";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { levels } from "@/config/catalog";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import { levelHasContent } from "@/lib/payments/availability";
import { activePaymentProvider } from "@/lib/payments/nyole";
import { createServerSupabase } from "@/lib/supabase/server";

const t = messages.payment;
const common = messages.common;

export const metadata: Metadata = {
  title: t.buyTitle,
  robots: { index: false },
};

export default async function BuyLevelPage({
  searchParams,
}: {
  searchParams: Promise<{ cat?: string; level?: string; error?: string }>;
}) {
  await requireUser("/app");
  const { cat, level, error } = await searchParams;
  const provider = activePaymentProvider();

  const categoryId = typeof cat === "string" ? cat : "";
  const levelKey = typeof level === "string" ? level : "";
  const levelLabel = (common.levels as Record<string, string>)[levelKey];
  const valid =
    categoryId &&
    levelLabel &&
    (levels as string[]).includes(levelKey) &&
    levelKey !== "debutant";

  const supabase = await createServerSupabase();
  const category = categoryId
    ? ((await supabase
        ?.from("categories")
        .select("id,name")
        .eq("id", categoryId)
        .maybeSingle())?.data ?? null)
    : null;
  const priceRow = valid
    ? ((await supabase
        ?.from("category_level_prices")
        .select("price_usd")
        .eq("category_id", categoryId)
        .eq("level", levelKey)
        .maybeSingle())?.data ?? null)
    : null;
  // Un tarif sans chapitres publiés derrière ne se vend pas (voir startCheckout).
  const sellable =
    valid &&
    Boolean(priceRow) &&
    (await levelHasContent(categoryId, levelKey));

  if (!supabase || !valid || !category || !priceRow || !sellable) {
    const notice = !supabase
      ? messages.admin.notConfigured
      : error && error in t.errors
        ? t.errors[error as keyof typeof t.errors]
        : valid && category && !priceRow
          ? // Paramètres valides mais aucun prix saisi dans le back-office.
            t.errors["no-price"]
          : !sellable
            ? t.errors["no-content"]
            : t.errors.missing;
    return (
      <div className="mx-auto w-full max-w-xl px-4 py-12 sm:px-6">
        <Notice tone="error">{notice}</Notice>
        <div className="mt-6">
          <Button asChild variant="outline" className="h-10 px-4">
            <Link href="/catalogue">
              <ArrowLeftIcon aria-hidden />
              {messages.nav.catalogue}
            </Link>
          </Button>
        </div>
      </div>
    );
  }

  const errorLabel =
    error && error in t.errors
      ? t.errors[error as keyof typeof t.errors]
      : error
        ? t.errors.failed
        : null;

  return (
    <div className="mx-auto w-full max-w-xl">
      <div className="rounded-2xl border border-hairline bg-card p-6">
        <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-electric">
          <CreditCardIcon className="size-4" aria-hidden />
          {t.buyTitle}
        </div>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          {t.buyIntro}
        </p>

        {errorLabel ? (
          <div className="mt-4">
            <Notice tone="error">{errorLabel}</Notice>
          </div>
        ) : null}

        <dl className="mt-6 space-y-3 border-t border-hairline pt-5 text-sm">
          <div className="flex items-center justify-between gap-4">
            <dt className="text-muted-foreground">{t.orderDomain}</dt>
            <dd className="font-medium text-foreground">{category.name}</dd>
          </div>
          <div className="flex items-center justify-between gap-4">
            <dt className="text-muted-foreground">{t.orderLevel}</dt>
            <dd>
              <Badge
                variant="secondary"
                className="rounded-full bg-electric/10 text-electric"
              >
                {levelLabel}
              </Badge>
            </dd>
          </div>
          <div className="flex items-center justify-between gap-4 border-t border-hairline pt-3">
            <dt className="font-medium text-foreground">{t.orderTotal}</dt>
            <dd className="text-xl font-semibold tabular-nums text-foreground">
              {priceRow.price_usd} CDF
            </dd>
          </div>
        </dl>

        <BuyLevelForm
          categoryId={categoryId}
          level={levelKey}
          priceUsd={priceRow.price_usd}
        />

        <p className="mt-4 flex items-start gap-2 text-xs leading-relaxed text-muted-foreground">
          <ShieldCheckIcon
            className="mt-0.5 size-3.5 shrink-0 text-vivid"
            aria-hidden
          />
          {provider === "mock" ? t.payMockHint : t.paySecureHint}
        </p>
        <p className="mt-2 text-center text-[11px] tracking-wide text-muted-foreground uppercase">
          {t.methods} : {messages.pricing.paymentMethods}
        </p>
      </div>
    </div>
  );
}
