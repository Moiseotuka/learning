import type { Metadata } from "next";
import Link from "next/link";
import { CalendarDaysIcon, DownloadIcon, VideoIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import { fill, formatDateTime, relativeFromNow } from "@/lib/instructor/format";
import {
  getLearnerClasses,
  getUpcomingSessionsForLearner,
  type LiveSession,
} from "@/lib/instructor/queries";
import { ACADEMY_TZ_LABEL, academyDateLabel } from "@/lib/instructor/timezone";

const t = messages.live;

export const metadata: Metadata = {
  title: t.learner.agendaTitle,
  robots: { index: false },
};

/** Regroupé par jour : un élève lit « mardi : telle séance », pas une liste plats. */
function byDay(sessions: LiveSession[]): [string, LiveSession[]][] {
  const groups = new Map<string, LiveSession[]>();
  for (const session of sessions) {
    const key = academyDateLabel(session.startsAt);
    const list = groups.get(key) ?? [];
    list.push(session);
    groups.set(key, list);
  }
  return [...groups.entries()];
}

export default async function LearnerAgendaPage({
  searchParams,
}: {
  searchParams: Promise<{ class?: string }>;
}) {
  const user = await requireUser("/app/classe");
  const { class: classId } = await searchParams;

  const [classes, sessions] = await Promise.all([
    getLearnerClasses(user.id),
    getUpcomingSessionsForLearner(user.id, {
      classId: classId || undefined,
      limit: 60,
    }),
  ]);

  const klass = classId ? classes.find((row) => row.classId === classId) : null;
  const days = byDay(sessions);

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-8 sm:px-6 lg:py-10">
      <header className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
        <p className="text-xs font-semibold tracking-wider text-electric uppercase">
          {t.eyebrow}
        </p>
        <h1 className="mt-1.5 text-2xl font-semibold tracking-tight text-balance">
          {klass ? `${t.learner.agendaTitle} — ${klass.title}` : t.learner.agendaTitle}
        </h1>
        <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
          {t.learner.agendaIntro}
        </p>
        <p className="mt-2 text-xs text-muted-foreground">
          {fill(t.learner.tzNote, { tz: ACADEMY_TZ_LABEL })}
        </p>

        <div className="mt-4 flex flex-wrap gap-2 border-t border-hairline pt-4">
          <Button asChild variant="outline" size="sm" className="h-9 px-4">
            <Link
              href={
                klass
                  ? `/app/classe/agenda/ics?class=${klass.classId}`
                  : "/app/classe/agenda/ics"
              }
              download
            >
              <DownloadIcon aria-hidden />
              {klass ? t.learner.download : t.learner.downloadAll}
            </Link>
          </Button>
          {klass ? (
            <Button asChild variant="ghost" size="sm" className="h-9 px-4">
              <Link href="/app/classe/agenda">{t.learner.title}</Link>
            </Button>
          ) : null}
        </div>
        <p className="mt-2 text-xs leading-relaxed text-muted-foreground">
          {t.learner.downloadHint}
        </p>
      </header>

      {days.length === 0 ? (
        <div className="mt-6 rounded-2xl border border-dashed border-hairline px-6 py-12 text-center">
          <CalendarDaysIcon className="mx-auto size-6 text-muted-foreground" aria-hidden />
          <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
            {t.learner.emptyAgenda}
          </p>
        </div>
      ) : (
        <ul className="mt-6 space-y-6">
          {days.map(([day, list]) => (
            <li key={day}>
              <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                {day}
              </h2>
              <ul className="mt-2 space-y-3">
                {list.map((session) => (
                  <li
                    key={session.id}
                    className="rounded-2xl border border-hairline bg-card p-4 shadow-sm sm:p-5"
                  >
                    <div className="flex flex-wrap items-start justify-between gap-3">
                      <div className="min-w-0">
                        <Link
                          href={`/app/live/${session.id}`}
                          className="text-sm font-semibold text-foreground hover:text-electric"
                        >
                          {session.title}
                        </Link>
                        <p className="mt-1 text-xs text-muted-foreground">
                          {formatDateTime(session.startsAt)} ·{" "}
                          {fill(t.learner.inClass, {
                            name: session.className ?? session.academy ?? "",
                          })}
                        </p>
                      </div>
                      <Badge
                        variant="secondary"
                        className="rounded-full bg-electric/10 px-2.5 py-0.5 text-[11px] text-electric"
                      >
                        {relativeFromNow(session.startsAt)}
                      </Badge>
                    </div>

                    {session.agenda ? (
                      <p className="mt-2 line-clamp-3 text-sm leading-relaxed whitespace-pre-line text-muted-foreground">
                        {session.agenda}
                      </p>
                    ) : null}

                    <div className="mt-3 flex items-center gap-2 border-t border-hairline pt-3">
                      <Button asChild size="sm" className="h-9 px-4">
                        <Link href={`/app/live/${session.id}`}>
                          <VideoIcon aria-hidden />
                          {t.room.join}
                        </Link>
                      </Button>
                    </div>
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
