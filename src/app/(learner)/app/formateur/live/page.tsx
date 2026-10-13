import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { ArrowLeftIcon, VideoIcon } from "lucide-react";

import { ActionForm } from "@/components/instructor/action-form";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import {
  createLiveSession,
  setLiveSessionStatus,
} from "@/lib/actions/instructor";
import { fill, formatDateTime, relativeFromNow } from "@/lib/instructor/format";
import {
  getInstructorClasses,
  getInstructorSessions,
  getInstructorStatus,
  type LiveSession,
} from "@/lib/instructor/queries";

const t = messages.live;
const durations = [30, 45, 60, 90, 120, 180];

export const metadata: Metadata = {
  title: t.module.title,
  robots: { index: false },
};

const fieldClass =
  "w-full rounded-lg border border-input bg-transparent px-2.5 py-2 text-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50";

function isUpcoming(session: LiveSession, now: number): boolean {
  if (session.status === "cancelled" || session.status === "ended") return false;
  return new Date(session.endsAt).getTime() >= now;
}

function partitionSessions(sessions: LiveSession[]) {
  const now = Date.now();
  return {
    now,
    upcoming: sessions.filter((session) => isUpcoming(session, now)),
    past: sessions.filter((session) => !isUpcoming(session, now)),
  };
}

export default async function InstructorLivePage({
  searchParams,
}: {
  searchParams: Promise<{ class?: string }>;
}) {
  const user = await requireUser("/app/profil");
  const status = await getInstructorStatus(user.id);
  if (!status.isActive) redirect("/app/formateur");

  const [classes, sessions, { class: presetClass }] = await Promise.all([
    getInstructorClasses(user.id),
    getInstructorSessions(user.id),
    searchParams,
  ]);
  const teachable = classes.filter((klass) => klass.status === "active");
  const preset = teachable.find((klass) => klass.id === presetClass)?.id;
  const { now, upcoming, past } = partitionSessions(sessions);

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-8 sm:px-6 lg:py-10">
      <Button
        asChild
        variant="ghost"
        className="-ml-2 mb-4 h-8 px-2 text-xs text-muted-foreground"
      >
        <Link href="/app/formateur">
          <ArrowLeftIcon aria-hidden />
          {messages.formateur.dashboardTitle}
        </Link>
      </Button>

      <div>
        <p className="text-xs font-semibold tracking-wide text-electric uppercase">
          {t.eyebrow}
        </p>
        <h1 className="mt-1.5 text-2xl font-semibold tracking-tight">{t.module.title}</h1>
        <p className="mt-1.5 max-w-2xl text-sm leading-relaxed text-muted-foreground">
          {t.subtitle}
        </p>
      </div>

      <section className="mt-6 rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
        <h2 className="text-sm font-semibold">{t.module.newTitle}</h2>
        {teachable.length === 0 ? (
          <p className="mt-2 text-sm text-muted-foreground">
            {messages.formateur.classes.empty}{" "}
            <Link
              href="/app/formateur/classes"
              className="font-medium text-electric hover:underline"
            >
              {messages.formateur.classes.newTitle}
            </Link>
          </p>
        ) : (
          <ActionForm
            action={createLiveSession}
            label={t.module.create}
            className="mt-4"
            buttonClassName="h-10 px-5"
          >
            <div className="grid w-full gap-3 sm:grid-cols-2">
              <label className="block">
                <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                  {t.module.fieldTitle}
                </span>
                <Input name="title" required minLength={3} className="h-10" />
              </label>
              <label className="block">
                <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                  {t.module.fieldClass}
                </span>
                <select name="classId" required defaultValue={preset} className={fieldClass}>
                  {teachable.map((klass) => (
                    <option key={klass.id} value={klass.id}>
                      {klass.title} · {klass.memberCount}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                  {t.module.fieldDate}
                </span>
                <Input name="date" type="date" required className={fieldClass} />
              </label>
              <div className="grid gap-3 sm:grid-cols-2">
                <label className="block">
                  <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                    {t.module.fieldTime}
                  </span>
                  <Input name="time" type="time" required className={fieldClass} />
                </label>
                <label className="block">
                  <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                    {t.module.fieldDuration}
                  </span>
                  <select name="minutes" defaultValue="60" className={fieldClass}>
                    {durations.map((minutes) => (
                      <option key={minutes} value={minutes}>
                        {fill(t.module.minutes, { count: minutes })}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
              <label className="block sm:col-span-2">
                <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                  {t.module.fieldAgenda}
                </span>
                <textarea name="agenda" rows={3} className={fieldClass} />
              </label>
            </div>
          </ActionForm>
        )}
      </section>

      <SessionList title={t.module.upcoming} sessions={upcoming} now={now} />
      <SessionList title={t.module.past} sessions={past} now={now} showAttendance hideWhenEmpty />
    </div>
  );
}

function SessionList({
  title,
  sessions,
  now,
  showAttendance = false,
  hideWhenEmpty = false,
}: {
  title: string;
  sessions: LiveSession[];
  now: number;
  showAttendance?: boolean;
  hideWhenEmpty?: boolean;
}) {
  if (sessions.length === 0) {
    if (hideWhenEmpty) return null;
    return (
      <div className="mt-6 rounded-2xl border border-dashed border-hairline px-6 py-12 text-center">
        <VideoIcon className="mx-auto size-6 text-muted-foreground" aria-hidden />
        <p className="mt-3 text-sm text-muted-foreground">{t.module.empty}</p>
      </div>
    );
  }

  return (
    <section className="mt-8">
      <h2 className="text-sm font-semibold text-foreground">{title}</h2>
      <ul className="mt-3 space-y-4">
        {sessions.map((session) => {
          const startsIn = new Date(session.startsAt).getTime() - now;
          return (
            <li
              key={session.id}
              className="rounded-2xl border border-hairline bg-card p-5 shadow-sm transition-colors hover:border-electric/40"
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="min-w-0">
                  <Link
                    href={`/app/live/${session.id}`}
                    className="text-base font-semibold text-foreground hover:text-electric"
                  >
                    {session.title}
                  </Link>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {formatDateTime(session.startsAt)}
                    {session.className ? ` · ${session.className}` : ""}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  {session.status === "live" ? (
                    <Badge className="rounded-full bg-emerald-500/12 px-2.5 py-1 text-emerald-600 dark:text-emerald-400">
                      {t.eyebrow}
                    </Badge>
                  ) : null}
                  {showAttendance && session.attendance !== undefined ? (
                    <Badge variant="secondary" className="rounded-full tabular-nums">
                      {fill(t.module.attendance, { count: session.attendance })}
                    </Badge>
                  ) : null}
                </div>
              </div>

              {session.agenda ? (
                <p className="mt-2 line-clamp-2 text-sm leading-relaxed whitespace-pre-line text-muted-foreground">
                  {session.agenda}
                </p>
              ) : null}

              <div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-hairline pt-4">
                <span className="text-xs text-muted-foreground">
                  {session.status === "scheduled" && startsIn > 0
                    ? relativeFromNow(session.startsAt)
                    : null}
                </span>
                <div className="flex flex-wrap items-center gap-2">
                  {session.status === "scheduled" ? (
                    <ActionForm
                      action={setLiveSessionStatus}
                      label={t.module.cancel}
                      variant="ghost"
                      inline={false}
                      hidden={{ sessionId: session.id, status: "cancelled" }}
                    />
                  ) : null}
                  {session.status === "scheduled" ? (
                    <ActionForm
                      action={setLiveSessionStatus}
                      label={t.module.startNow}
                      variant="outline"
                      inline={false}
                      hidden={{ sessionId: session.id, status: "live" }}
                    />
                  ) : null}
                  {session.status === "live" ? (
                    <ActionForm
                      action={setLiveSessionStatus}
                      label={t.module.end}
                      variant="outline"
                      inline={false}
                      hidden={{ sessionId: session.id, status: "ended" }}
                    />
                  ) : null}
                  <Button asChild size="sm" className="h-8 px-3">
                    <Link href={`/app/live/${session.id}`}>{t.room.title}</Link>
                  </Button>
                </div>
              </div>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
