import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { ArrowLeftIcon, MailIcon, VideoIcon } from "lucide-react";

import { ActionForm } from "@/components/instructor/action-form";
import { CopyCode } from "@/components/instructor/copy-code";
import { Notice } from "@/components/auth/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import {
  inviteStudent,
  removeStudent,
} from "@/lib/actions/instructor";
import { fill, formatDate, formatDateTime } from "@/lib/instructor/format";
import {
  getClassStudents,
  getInstructorSessions,
  getInstructorStatus,
  getPendingInvites,
} from "@/lib/instructor/queries";

const t = messages.formateur;
const tl = messages.live;

export const metadata: Metadata = {
  title: t.classes.title,
  robots: { index: false },
};

const DAYS_AT_RISK = 10;

function isAtRisk(lastActivity: string | null): boolean {
  if (!lastActivity) return true;
  return Date.now() - new Date(lastActivity).getTime() > DAYS_AT_RISK * 86_400_000;
}

export default async function InstructorClassPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const user = await requireUser("/app/profil");
  const status = await getInstructorStatus(user.id);
  if (!status.isActive) redirect("/app/formateur");

  const { id } = await params;
  const [{ class: klass, students }, sessions, pending] = await Promise.all([
    getClassStudents(id, user.id),
    getInstructorSessions(user.id),
    getPendingInvites(id),
  ]);

  if (!klass) notFound();

  const classSessions = sessions.filter((session) => session.classId === klass.id);
  const seatsLimit = status.subscription?.seatsLimit ?? 0;
  const seatsLeft = Math.max(0, seatsLimit - status.seatsUsed);

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-8 sm:px-6 lg:py-10">
      <Button
        asChild
        variant="ghost"
        className="-ml-2 mb-4 h-8 px-2 text-xs text-muted-foreground"
      >
        <Link href="/app/formateur/classes">
          <ArrowLeftIcon aria-hidden />
          {t.classes.title}
        </Link>
      </Button>

      <div className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="text-xs font-semibold tracking-wider text-electric uppercase">
              {t.classes.assignedTrack}
            </p>
            <h1 className="mt-1 text-2xl font-semibold tracking-tight text-balance">
              {klass.title}
            </h1>
            <Link
              href={`/app/parcours/${klass.trackSlug}`}
              className="mt-1 inline-block text-sm text-muted-foreground hover:text-electric"
            >
              {klass.trackTitle}
            </Link>
          </div>
          {klass.status === "active" ? null : (
            <Badge variant="outline" className="rounded-full">
              {t.classes.archived}
            </Badge>
          )}
        </div>

        {klass.description ? (
          <p className="mt-3 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
            {klass.description}
          </p>
        ) : null}

        <div className="mt-5 flex flex-wrap items-center gap-3 border-t border-hairline pt-5">
          <span className="text-[11px] font-semibold tracking-wide text-muted-foreground uppercase">
            {t.classes.joinCode}
          </span>
          <code className="rounded-lg bg-muted px-2.5 py-1 font-mono text-sm tracking-widest text-foreground">
            {klass.joinCode}
          </code>
          <CopyCode
            code={klass.joinCode}
            label={t.classes.copyCode}
            copied={t.classes.copied}
          />
        </div>
        <p className="mt-2 max-w-[70ch] text-xs leading-relaxed text-muted-foreground">
          {t.classes.joinHint}
        </p>

        <div className="mt-5 flex flex-wrap gap-2 border-t border-hairline pt-5">
          <Button asChild size="sm" className="h-9 px-4">
            <Link href={`/app/formateur/live?class=${klass.id}`}>
              <VideoIcon aria-hidden />
              {messages.live.cta}
            </Link>
          </Button>
          <Button asChild variant="outline" size="sm" className="h-9 px-4">
            <Link href="/app/formateur/souscrire">
              {t.renewCta}
            </Link>
          </Button>
        </div>
      </div>

      <section className="mt-6 rounded-2xl border border-hairline bg-card p-5 shadow-sm">
        <h2 className="text-sm font-semibold text-foreground">
          {t.students.inviteTitle}
        </h2>
        {seatsLeft === 0 ? (
          <div className="mt-3">
            <Notice tone="error">
              {fill(t.students.seatsFull, { limit: seatsLimit })}
            </Notice>
          </div>
        ) : (
          <ActionForm
            action={inviteStudent}
            label={t.students.inviteCta}
            hidden={{ classId: klass.id }}
            className="mt-3"
            buttonClassName="h-10 px-5"
          >
            <label className="w-full max-w-sm">
              <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                {t.students.inviteField}
              </span>
              <Input
                type="email"
                name="email"
                required
                autoComplete="email"
                className="h-10"
                placeholder="eleve@exemple.com"
              />
            </label>
          </ActionForm>
        )}
        {pending.length === 0 ? null : (
          <div className="mt-4 border-t border-hairline pt-4">
            <p className="text-[11px] font-semibold tracking-wide text-muted-foreground uppercase">
              {t.students.pendingTitle}
            </p>
            <ul className="mt-2 space-y-1.5">
              {pending.map((invite) => (
                <li
                  key={invite.link}
                  className="flex flex-wrap items-center gap-x-3 gap-y-1 text-sm"
                >
                  <span className="font-medium text-foreground">{invite.email}</span>
                  <span className="text-xs text-muted-foreground">
                    {fill(t.students.pendingUntil, {
                      date: formatDate(invite.expiresAt),
                    })}
                  </span>
                  <CopyCode
                    code={invite.link}
                    label={t.students.pendingCopy}
                    copied={t.students.pendingCopied}
                  />
                </li>
              ))}
            </ul>
          </div>
        )}
        <p className="mt-3 flex items-start gap-1.5 text-xs leading-relaxed text-muted-foreground">
          <MailIcon className="mt-0.5 size-3.5 shrink-0" aria-hidden />
          {t.students.inviteHint}
        </p>
      </section>

      <section className="mt-6 rounded-2xl border border-hairline bg-card p-5 shadow-sm">
        <div className="flex items-center gap-3">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {t.students.title}
          </h2>
          <span className="h-px flex-1 bg-hairline" />
          <span className="text-xs tabular-nums text-muted-foreground">
            {students.length}
          </span>
        </div>

        {students.length === 0 ? (
          <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
            {t.students.empty}
          </p>
        ) : (
          <ul className="mt-4 space-y-3">
            {students.map((student) => {
              const ratio =
                student.totalChapters > 0
                  ? Math.min(
                      100,
                      Math.round(
                        (student.completedChapters / student.totalChapters) * 100,
                      ),
                    )
                  : 0;
              return (
                <li
                  key={student.userId}
                  className="rounded-xl border border-hairline p-4"
                >
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-foreground">
                        {student.fullName}
                      </p>
                      <p className="mt-0.5 text-xs text-muted-foreground">
                        {fill(t.students.joined, { date: formatDate(student.joinedAt) })}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      {isAtRisk(student.lastActivity) && student.completedChapters < student.totalChapters ? (
                        <Badge
                          variant="secondary"
                          className="rounded-full bg-amber-500/12 px-2 py-0.5 text-[11px] text-amber-600 dark:text-amber-400"
                        >
                          {t.students.atRisk}
                        </Badge>
                      ) : null}
                      <ActionForm
                        action={removeStudent}
                        label={t.students.remove}
                        variant="ghost"
                        hidden={{ classId: klass.id, studentId: student.userId }}
                        inline={false}
                      />
                    </div>
                  </div>

                  <div className="mt-3">
                    <div className="flex items-center justify-between text-xs text-muted-foreground">
                      <span>
                        {t.students.columnChapters} : {student.completedChapters} /{" "}
                        {student.totalChapters}
                      </span>
                      <span>
                        {student.averageScore === null
                          ? t.students.columnScore
                          : `${t.students.columnScore} ${student.averageScore} %`}
                      </span>
                    </div>
                    <div
                      className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-muted"
                      role="progressbar"
                      aria-valuenow={ratio}
                      aria-valuemin={0}
                      aria-valuemax={100}
                    >
                      <div
                        className="h-full rounded-full bg-electric transition-width"
                        style={{ width: `${ratio}%` }}
                      />
                    </div>
                    <p className="mt-1.5 text-[11px] text-muted-foreground">
                      {student.lastActivity
                        ? `${t.students.columnActivity} · ${formatDateTime(student.lastActivity)}`
                        : t.students.never}
                    </p>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      <section className="mt-6 rounded-2xl border border-hairline bg-card p-5 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {messages.live.module.title}
          </h2>
          <Button asChild variant="outline" size="sm" className="h-8 px-3">
            <Link href={`/app/formateur/live?class=${klass.id}`}>
              {messages.live.cta}
            </Link>
          </Button>
        </div>
        {classSessions.length === 0 ? (
          <p className="mt-3 text-sm text-muted-foreground">
            {messages.live.module.empty}
          </p>
        ) : (
          <ul className="mt-4 divide-y divide-hairline">
            {classSessions.slice(0, 6).map((session) => (
              <li
                key={session.id}
                className="flex flex-wrap items-center justify-between gap-3 py-3"
              >
                <div className="min-w-0">
                  <Link
                    href={`/app/live/${session.id}`}
                    className="text-sm font-semibold text-foreground hover:text-electric"
                  >
                    {session.title}
                  </Link>
                  <p className="mt-0.5 text-xs text-muted-foreground">
                    {formatDateTime(session.startsAt)} ·{" "}
                    {tl.module.statuses[session.status as keyof typeof tl.module.statuses] ??
                      tl.module.statuses.scheduled}
                  </p>
                </div>
                <Button asChild variant="ghost" size="sm" className="h-8 px-3">
                  <Link href={`/app/live/${session.id}`}>{messages.live.room.join}</Link>
                </Button>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
