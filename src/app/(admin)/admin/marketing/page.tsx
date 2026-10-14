import {
  AlertTriangleIcon,
  InboxIcon,
  MailCheckIcon,
  MailXIcon,
  SendIcon,
  SlidersHorizontalIcon,
} from "lucide-react";

import { AdminNotice } from "@/components/admin/admin-notice";
import { MarketingControls } from "@/components/admin/marketing-controls";
import { messages } from "@/i18n";
import { marketingBoard } from "@/lib/marketing/queue";
import { MARKETING_KINDS, type MarketingKind } from "@/lib/marketing/templates";

const t = messages.admin.marketing;

/** Les compteurs suivent la file, la page ne peut donc pas être mise en cache. */
export const dynamic = "force-dynamic";

export default async function AdminMarketingPage({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string; sent?: string; failed?: string; queued?: string }>;
}) {
  const { notice, sent, failed, queued } = await searchParams;
  const board = await marketingBoard();

  const cards = [
    { label: t.cards.used, value: `${board.used} / ${board.cap}`, Icon: SendIcon },
    { label: t.cards.queued, value: board.queued, Icon: InboxIcon },
    { label: t.cards.sent, value: board.sentToday, Icon: MailCheckIcon },
    { label: t.cards.failed, value: board.failedRows, Icon: AlertTriangleIcon },
    { label: t.cards.optedOut, value: board.optedOut, Icon: MailXIcon },
  ];

  const counts = new Map<MarketingKind, { queued: number; sent: number }>(
    board.byKind.map((row) => [row.kind, { queued: row.queued, sent: row.sent }]),
  );

  return (
    <div className="space-y-6">
      <AdminNotice notice={notice} />

      {notice === "ran" ? (
        <p className="rounded-2xl border border-electric/40 bg-electric/[0.06] px-4 py-3 text-sm text-foreground">
          {t.ranSummary(
            Number(sent ?? 0),
            Number(failed ?? 0),
            Number(queued ?? 0),
          )}
        </p>
      ) : null}

      <div>
        <h2 className="text-lg font-semibold text-foreground">{t.title}</h2>
        <p className="mt-1 max-w-2xl text-sm leading-relaxed text-muted-foreground">
          {t.intro}
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        {cards.map((card) => (
          <div key={card.label} className="rounded-2xl border border-hairline bg-card p-4">
            <p className="flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-muted-foreground">
              <card.Icon className="size-3.5 text-electric" aria-hidden />
              {card.label}
            </p>
            <p className="mt-2 text-2xl font-semibold text-foreground tabular-nums">
              {card.value}
            </p>
          </div>
        ))}
      </div>

      <MarketingControls cap={board.cap} />

      <section className="rounded-2xl border border-hairline bg-card p-5">
        <h3 className="flex items-center gap-2 text-sm font-semibold text-foreground">
          <SlidersHorizontalIcon className="size-4 text-electric" aria-hidden />
          {t.byKindTitle}
        </h3>
        <table className="mt-4 w-full text-sm">
          <thead>
            <tr className="border-b border-hairline text-left text-xs uppercase tracking-wide text-muted-foreground">
              <th className="py-2 pr-4 font-medium">{t.columnKind}</th>
              <th className="py-2 pr-4 text-right font-medium">{t.columnQueued}</th>
              <th className="py-2 text-right font-medium">{t.columnSent}</th>
            </tr>
          </thead>
          <tbody>
            {MARKETING_KINDS.map((kind) => {
              const row = counts.get(kind) ?? { queued: 0, sent: 0 };
              return (
                <tr key={kind} className="border-b border-hairline/60 last:border-0">
                  <td className="py-2 pr-4 text-foreground">{t.kinds[kind]}</td>
                  <td className="py-2 pr-4 text-right tabular-nums text-muted-foreground">
                    {row.queued}
                  </td>
                  <td className="py-2 text-right tabular-nums text-muted-foreground">
                    {row.sent}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </section>

      {board.errors.length > 0 ? (
        <section className="rounded-2xl border border-destructive/40 bg-destructive/[0.04] p-5">
          <h3 className="flex items-center gap-2 text-sm font-semibold text-foreground">
            <AlertTriangleIcon className="size-4 text-destructive" aria-hidden />
            {t.errorsTitle}
          </h3>
          <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
            {t.errorsIntro}
          </p>
          <ul className="mt-4 space-y-2 text-xs">
            {board.errors.map((error) => (
              <li key={`${error.recipient}-${error.kind}`} className="flex flex-wrap gap-x-3 gap-y-1">
                <span className="font-medium text-foreground">{error.recipient}</span>
                <span className="text-muted-foreground">{t.kinds[error.kind as MarketingKind] ?? error.kind}</span>
                <span className="text-muted-foreground">
                  {error.attempts} × {error.error}
                </span>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
