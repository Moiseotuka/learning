import type { Metadata } from "next";
import { CalendarClockIcon, UsersIcon, WalletIcon } from "lucide-react";

import { AdminNotice } from "@/components/admin/admin-notice";
import { Badge } from "@/components/ui/badge";
import { messages } from "@/i18n";
import { formatFc, formatDate } from "@/lib/instructor/format";
import { createServerSupabase } from "@/lib/supabase/server";

const t = messages.admin;

export const metadata: Metadata = {
  title: t.instructors.title,
  robots: { index: false },
};

type Row = {
  id: string;
  name: string;
  email: string;
  planLabel: string;
  status: string;
  expiresAt: string | null;
  amountFc: number;
  paid: boolean;
  seatsUsed: number;
  seatsLimit: number;
  classCount: number;
  sessionCount: number;
};

function statusLabel(status: string): string {
  if (status === "active") return t.instructors.status.active;
  if (status === "expired") return t.instructors.status.expired;
  if (status === "cancelled") return t.instructors.status.cancelled;
  return t.instructors.status.pending;
}

function isActive(row: Row, now: number): boolean {
  return (
    row.status === "active" &&
    Boolean(row.expiresAt) &&
    new Date(row.expiresAt as string).getTime() > now
  );
}

async function loadRows() {
  const supabase = await createServerSupabase();
  if (!supabase) return null;

  const [{ data: subscriptions }, { data: plans }] = await Promise.all([
    supabase
      .from("instructor_subscriptions")
      .select(
        "id,user_id,plan_id,status,amount_fc,seats_limit,expires_at,paid_at",
      )
      .order("created_at", { ascending: false })
      .limit(100),
    supabase.from("instructor_plans").select("id,label"),
  ]);

  const subs = (subscriptions ?? []) as Record<string, unknown>[];
  if (subs.length === 0) return [];

  const userIds = Array.from(new Set(subs.map((row) => String(row.user_id))));
  const [profiles, classes, sessions] = await Promise.all([
    supabase.from("profiles").select("id,full_name,email").in("id", userIds),
    supabase
      .from("instructor_classes")
      .select("id,instructor_id,status")
      .in("instructor_id", userIds),
    supabase
      .from("live_sessions")
      .select("id,instructor_id,status,ends_at")
      .in("instructor_id", userIds),
  ]);

  const names = new Map(
    ((profiles.data ?? []) as { id: string; full_name: string | null; email: string | null }[]).map(
      (profile) => [profile.id, profile],
    ),
  );
  const labels = new Map(
    ((plans ?? []) as { id: string; label: string }[]).map((plan) => [
      plan.id,
      plan.label,
    ]),
  );

  const classRows = (classes.data ?? []) as {
    id: string;
    instructor_id: string;
    status: string;
  }[];
  const seatsByOwner = new Map<string, number>();
  const classesByOwner = new Map<string, number>();
  for (const klass of classRows) {
    classesByOwner.set(klass.instructor_id, (classesByOwner.get(klass.instructor_id) ?? 0) + 1);
  }

  const activeClassIds = classRows
    .filter((klass) => klass.status === "active")
    .map((klass) => klass.id);
  if (activeClassIds.length > 0) {
    const { data: members } = await supabase
      .from("instructor_class_members")
      .select("class_id")
      .in("class_id", activeClassIds)
      .eq("status", "active");
    const ownerByClass = new Map(classRows.map((klass) => [klass.id, klass.instructor_id]));
    for (const member of (members ?? []) as { class_id: string }[]) {
      const owner = ownerByClass.get(member.class_id);
      if (!owner) continue;
      seatsByOwner.set(owner, (seatsByOwner.get(owner) ?? 0) + 1);
    }
  }

  const now = Date.now();
  const upcomingByOwner = new Map<string, number>();
  for (const session of (sessions.data ?? []) as {
    id: string;
    instructor_id: string;
    status: string;
    ends_at: string;
  }[]) {
    if (session.status === "cancelled" || session.status === "ended") continue;
    // Une séance encore ouverte compte même si son heure annoncée est passée.
    if (session.status !== "live" && new Date(session.ends_at).getTime() < now) {
      continue;
    }
    upcomingByOwner.set(
      session.instructor_id,
      (upcomingByOwner.get(session.instructor_id) ?? 0) + 1,
    );
  }

  return subs.map<Row>((sub) => {
    const userId = String(sub.user_id);
    const profile = names.get(userId);
    const expiresAt = (sub.expires_at as string | null) ?? null;
    const storedStatus = String(sub.status);
    const expired =
      storedStatus === "active" &&
      expiresAt !== null &&
      new Date(expiresAt).getTime() <= now;

    return {
      id: String(sub.id),
      name: profile?.full_name?.trim() || userId.slice(0, 8),
      email: profile?.email ?? "",
      planLabel: labels.get(String(sub.plan_id)) ?? String(sub.plan_id),
      status: expired ? "expired" : storedStatus,
      expiresAt,
      amountFc: Number(sub.amount_fc ?? 0),
      paid: Boolean(sub.paid_at),
      seatsUsed: seatsByOwner.get(userId) ?? 0,
      seatsLimit: Number(sub.seats_limit ?? 0),
      classCount: classesByOwner.get(userId) ?? 0,
      sessionCount: upcomingByOwner.get(userId) ?? 0,
    };
  });
}

export default async function AdminInstructorsPage({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string }>;
}) {
  const [{ notice }, rows] = await Promise.all([searchParams, loadRows()]);

  if (rows === null) {
    return (
      <div className="space-y-6">
        <AdminNotice notice={notice} />
        <p className="rounded-2xl border border-hairline bg-card px-4 py-10 text-center text-sm text-muted-foreground">
          {t.notConfigured}
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <AdminNotice notice={notice} />

      <div>
        <h2 className="text-lg font-semibold text-foreground">{t.instructors.title}</h2>
        <p className="mt-1 max-w-2xl text-sm leading-relaxed text-muted-foreground">
          {t.instructors.intro}
        </p>
      </div>

      <Summary summary={summarize(rows)} />

      {rows.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-hairline px-6 py-12 text-center">
          <UsersIcon className="mx-auto size-6 text-muted-foreground" aria-hidden />
          <p className="mt-3 text-sm text-muted-foreground">{t.instructors.empty}</p>
        </div>
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-hairline bg-card">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-hairline text-left text-xs font-medium uppercase tracking-wide text-muted-foreground">
                <th className="px-4 py-3">{t.instructors.columns.trainer}</th>
                <th className="px-4 py-3">{t.instructors.columns.plan}</th>
                <th className="px-4 py-3">{t.instructors.columns.status}</th>
                <th className="px-4 py-3">{t.instructors.columns.expires}</th>
                <th className="px-4 py-3">{t.instructors.columns.amount}</th>
                <th className="px-4 py-3">{t.instructors.columns.seats}</th>
                <th className="px-4 py-3">{t.instructors.columns.classes}</th>
                <th className="px-4 py-3">{t.instructors.columns.sessions}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id} className="border-b border-hairline last:border-0">
                  <td className="px-4 py-3">
                    <p className="font-medium text-foreground">{row.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {row.email || t.instructors.noEmail}
                    </p>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{row.planLabel}</td>
                  <td className="px-4 py-3">
                    <Badge
                      variant="outline"
                      className={
                        row.status === "active"
                          ? "rounded-full border-emerald-500/30 bg-emerald-500/12 text-emerald-600 dark:text-emerald-400"
                          : "rounded-full"
                      }
                    >
                      {statusLabel(row.status)}
                    </Badge>
                  </td>
                  <td className="px-4 py-3 tabular-nums text-muted-foreground">
                    {row.expiresAt ? formatDate(row.expiresAt) : "—"}
                  </td>
                  <td className="px-4 py-3 tabular-nums text-muted-foreground">
                    {formatFc(row.amountFc)}
                  </td>
                  <td className="px-4 py-3 tabular-nums text-muted-foreground">
                    {row.seatsUsed} / {row.seatsLimit}
                  </td>
                  <td className="px-4 py-3 tabular-nums text-muted-foreground">{row.classCount}</td>
                  <td className="px-4 py-3 tabular-nums text-muted-foreground">
                    {row.sessionCount}
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

function summarize(rows: Row[]) {
  const now = Date.now();
  let active = 0;
  let expiring = 0;
  let revenue = 0;
  for (const row of rows) {
    if (isActive(row, now)) {
      active += 1;
      const days = new Date(row.expiresAt as string).getTime() - now;
      if (days <= 7 * 86_400_000) expiring += 1;
    }
    if (row.paid) revenue += row.amountFc;
  }
  return { total: rows.length, active, expiring, revenue };
}

function Summary({
  summary,
}: {
  summary: { total: number; active: number; expiring: number; revenue: number };
}) {
  const cards = [
    { label: t.instructors.stats.subscribers, value: String(summary.total), Icon: UsersIcon },
    { label: t.instructors.stats.active, value: String(summary.active), Icon: CalendarClockIcon },
    { label: t.instructors.stats.expiring, value: String(summary.expiring), Icon: CalendarClockIcon },
    { label: t.instructors.stats.revenue, value: formatFc(summary.revenue), Icon: WalletIcon },
  ];

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      {cards.map((card) => (
        <div key={card.label} className="rounded-2xl border border-hairline bg-card p-5">
          <p className="flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-muted-foreground">
            <card.Icon className="size-3.5 text-electric" aria-hidden />
            {card.label}
          </p>
          <p className="mt-2 text-2xl font-semibold tabular-nums text-foreground">{card.value}</p>
        </div>
      ))}
    </div>
  );
}
