"use client";

import { CheckIcon, Loader2Icon, SearchIcon } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState, useActionState } from "react";

import { Notice } from "@/components/auth/notice";
import { CheckoutDialog } from "@/components/payment/checkout-dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { subscribeAsInstructor } from "@/lib/actions/instructor";
import type { InstructorCheckout } from "@/lib/instructor/checkout";
import { fill } from "@/lib/instructor/format";
import { cn } from "cn";

const t = messages.formateur;
const pay = messages.payment;

export type PlanCard = {
  id: string;
  label: string;
  durationDays: number;
  priceFc: number;
  priceLabel: string;
  monthlyLabel: string;
  saveLabel: string | null;
  seatsLimit: number;
  trackLimit: number;
  highlight: string | null;
  seatsText: string;
  tracksText: string;
  totalText: string;
};

export type TrackChoice = {
  id: string;
  title: string;
  category: string;
};


/** Motifs renvoyés par la caisse, traduits côté formateur plutôt que côté achat. */
const PLAN_REASONS: Record<string, string> = {
  "no-plan": t.errors.noPlan,
  "no-track": t.errors.noTrack,
  "too-many-tracks": t.errors.tooManyTracks,
  "unknown-track": t.errors.noTrack,
};

/**
 * Souscription formateur : la durée choisie fixe le prix, le nombre de
 * parcours enseignables et les places d'élèves incluses. Le paiement réutilise
 * le dialogue de l'achat de niveau — une seule caisse dans la plateforme.
 */
export function SubscribeForm({
  plans,
  tracks,
  initialPlanId,
  initialTrackIds = [],
}: {
  plans: PlanCard[];
  tracks: TrackChoice[];
  initialPlanId?: string;
  initialTrackIds?: string[];
}) {
  const router = useRouter();
  const [state, action, pending] = useActionState<
    InstructorCheckout | undefined,
    FormData
  >(subscribeAsInstructor, undefined);
  const [dismissed, setDismissed] = useState<string | null>(null);
  const [planId, setPlanId] = useState(
    () => plans.find((plan) => plan.id === initialPlanId)?.id ?? plans[0]?.id ?? "",
  );
  const [selected, setSelected] = useState<string[]>(() =>
    initialTrackIds.filter((id) => tracks.some((track) => track.id === id)),
  );
  const [query, setQuery] = useState("");

  const plan = plans.find((item) => item.id === planId) ?? plans[0] ?? null;
  const limit = plan?.trackLimit ?? 0;

  const grouped = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase("fr");
    const byCategory = new Map<string, TrackChoice[]>();
    for (const track of tracks) {
      if (needle && !track.title.toLocaleLowerCase("fr").includes(needle)) continue;
      const list = byCategory.get(track.category) ?? [];
      list.push(track);
      byCategory.set(track.category, list);
    }
    return [...byCategory.entries()];
  }, [tracks, query]);

  const toggle = (trackId: string) => {
    setSelected((current) => {
      if (current.includes(trackId)) {
        return current.filter((id) => id !== trackId);
      }
      if (current.length >= limit) return current;
      return [...current, trackId];
    });
  };

  // Sélection conservée quand la formule la plus courte est choisie après coup :
  // on tronque plutôt que de laisser partir une souscription invalide.
  const visibleIds = selected.filter((id) => tracks.some((track) => track.id === id));
  const chosen = visibleIds.slice(0, limit);

  useEffect(() => {
    if (state?.mode === "redirect") router.push(state.redirect);
  }, [state, router]);

  const checkout = state?.mode === "dialog" ? state : null;
  const dialogOpen = Boolean(
    checkout && !pending && checkout.sessionId !== dismissed,
  );
  const error =
    state?.mode === "error"
      ? (PLAN_REASONS[state.reason] ??
        ((pay.errors as Record<string, string>)[state.reason] ?? t.errors.failed))
      : null;

  const succeed = () => {
    if (!checkout) return;
    setDismissed(checkout.sessionId);
    router.push(checkout.redirect);
    router.refresh();
  };

  return (
    <>
      <form action={action} onSubmit={() => setDismissed(null)}>
        <input type="hidden" name="planId" value={planId} />
        {chosen.map((trackId) => (
          <input key={trackId} type="hidden" name="trackIds" value={trackId} />
        ))}

        <fieldset className="border-0 p-0">
          <legend className="text-sm font-semibold text-foreground">
            {t.plansTitle}
          </legend>
          <p className="mt-1 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
            {t.plansHint}
          </p>

          <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            {plans.map((item) => {
              const active = item.id === planId;
              return (
                <label
                  key={item.id}
                  className={cn(
                    "relative flex cursor-pointer flex-col rounded-2xl border p-4 text-left transition-colors",
                    active
                      ? "border-electric bg-electric/8 shadow-sm"
                      : "border-hairline bg-card hover:border-electric/50",
                  )}
                >
                  <input
                    type="radio"
                    name="planChoice"
                    value={item.id}
                    checked={active}
                    onChange={() => setPlanId(item.id)}
                    className="sr-only"
                  />
                  {item.highlight ? (
                    <span className="absolute -top-2 right-3 rounded-full bg-electric px-2 py-0.5 text-[10px] font-semibold text-white uppercase">
                      {item.highlight}
                    </span>
                  ) : null}
                  <span className="text-sm font-semibold text-foreground">
                    {item.label}
                  </span>
                  <span className="mt-2 text-2xl font-semibold tabular-nums text-foreground">
                    {item.priceLabel}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {item.totalText}
                  </span>
                  <span className="mt-3 flex items-center gap-2 text-xs font-medium text-electric">
                    {item.saveLabel ? (
                      <span className="rounded-full bg-emerald-500/12 px-2 py-0.5 text-emerald-600 dark:text-emerald-400">
                        {item.saveLabel}
                      </span>
                    ) : null}
                    <span className="tabular-nums">
                      {item.monthlyLabel} {t.perMonth}
                    </span>
                  </span>
                  <span className="mt-3 space-y-1 border-t border-hairline pt-3 text-[11px] leading-relaxed text-muted-foreground">
                    <span className="block">{item.seatsText}</span>
                    <span className="block">{item.tracksText}</span>
                  </span>
                </label>
              );
            })}
          </div>
        </fieldset>

        <div className="mt-8">
          <div className="flex flex-wrap items-baseline justify-between gap-2">
            <h3 className="text-sm font-semibold text-foreground">
              {t.chooseTracks}
            </h3>
            <span
              className={cn(
                "text-xs tabular-nums",
                chosen.length >= limit ? "text-electric" : "text-muted-foreground",
              )}
            >
              {fill(t.selectedCount, { count: chosen.length, limit })}
            </span>
          </div>
          <p className="mt-1 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
            {t.chooseTracksHint}
          </p>

          <div className="relative mt-3">
            <SearchIcon
              className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden
            />
            <Input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder={t.trackSearch}
              className="pl-9"
              aria-label={t.trackSearch}
            />
          </div>

          <div className="mt-3 max-h-80 overflow-y-auto rounded-2xl border border-hairline bg-card">
            {grouped.length === 0 ? (
              <p className="px-4 py-8 text-center text-sm text-muted-foreground">
                {t.trackEmpty}
              </p>
            ) : (
              grouped.map(([category, list]) => (
                <div key={category}>
                  <p className="sticky top-0 border-b border-hairline bg-card/95 px-4 py-2 text-[11px] font-semibold tracking-wide text-muted-foreground uppercase backdrop-blur">
                    {category}
                  </p>
                  <ul className="divide-y divide-hairline">
                    {list.map((track) => {
                      const checked = chosen.includes(track.id);
                      const locked = !checked && chosen.length >= limit;
                      return (
                        <li key={track.id}>
                          <button
                            type="button"
                            onClick={() => toggle(track.id)}
                            disabled={locked}
                            aria-pressed={checked}
                            className={cn(
                              "flex w-full items-center gap-3 px-4 py-2.5 text-left text-sm transition-colors",
                              checked
                                ? "bg-electric/8 text-foreground"
                                : "text-muted-foreground hover:bg-muted/50",
                              locked && "cursor-not-allowed opacity-50",
                            )}
                          >
                            <span
                              className={cn(
                                "flex size-5 shrink-0 items-center justify-center rounded-md border",
                                checked
                                  ? "border-electric bg-electric text-white"
                                  : "border-hairline",
                              )}
                              aria-hidden
                            >
                              {checked ? (
                                <CheckIcon className="size-3.5" />
                              ) : null}
                            </span>
                            <span className="min-w-0 flex-1 truncate font-medium text-foreground">
                              {track.title}
                            </span>
                          </button>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="mt-6 flex flex-wrap items-end justify-between gap-4 border-t border-hairline pt-5">
          <div>
            <p className="text-xs text-muted-foreground">
              {plan ? fill(t.planOf, { label: plan.label }) : null}
            </p>
            <p className="text-2xl font-semibold tabular-nums text-foreground">
              {plan?.priceLabel ?? "—"}
            </p>
          </div>
          <Button
            type="submit"
            size="lg"
            className="h-11 px-6"
            disabled={pending || chosen.length === 0 || !plan}
          >
            {pending ? <Loader2Icon className="animate-spin" aria-hidden /> : null}
            {pending ? t.paying : t.subscribeCta}
          </Button>
        </div>
      </form>

      {error ? (
        <div className="mt-4">
          <Notice tone="error">{error}</Notice>
        </div>
      ) : null}

      {checkout && dialogOpen ? (
        <CheckoutDialog
          url={checkout.url}
          purchaseId={checkout.subscriptionId}
          param="subscription"
          onSuccess={succeed}
          onClose={() => setDismissed(checkout.sessionId)}
        />
      ) : null}
    </>
  );
}
