import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { ArrowLeftIcon, UsersIcon } from "lucide-react";

import { ActionForm } from "@/components/instructor/action-form";
import { CopyCode } from "@/components/instructor/copy-code";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import {
  archiveClass,
  createClass,
} from "@/lib/actions/instructor";
import { fill, formatDateTime } from "@/lib/instructor/format";
import {
  getInstructorClasses,
  getInstructorStatus,
} from "@/lib/instructor/queries";

const t = messages.formateur;

export const metadata: Metadata = {
  title: t.classes.title,
  robots: { index: false },
};

const fieldClass =
  "w-full rounded-lg border border-input bg-transparent px-2.5 py-2 text-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50";

export default async function InstructorClassesPage() {
  const user = await requireUser("/app/profil");
  const status = await getInstructorStatus(user.id);
  if (!status.isActive) redirect("/app/formateur");

  const classes = await getInstructorClasses(user.id);
  const active = classes.filter((klass) => klass.status === "active");
  const archived = classes.filter((klass) => klass.status !== "active");

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-8 sm:px-6 lg:py-10">
      <Button
        asChild
        variant="ghost"
        className="-ml-2 mb-4 h-8 px-2 text-xs text-muted-foreground"
      >
        <Link href="/app/formateur">
          <ArrowLeftIcon aria-hidden />
          {t.dashboardTitle}
        </Link>
      </Button>

      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">{t.classes.title}</h1>
          <p className="mt-1.5 text-sm text-muted-foreground">
            {t.cardSeats} : {status.seatsUsed} /{" "}
            {status.subscription?.seatsLimit ?? 0}
          </p>
        </div>
        <Badge
          variant="secondary"
          className="rounded-full bg-electric/10 px-3 py-1 text-electric"
        >
          {fill(t.classes.students, { count: active.length })}
        </Badge>
      </div>

      <section className="mt-6 rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
        <h2 className="text-sm font-semibold text-foreground">
          {t.classes.newTitle}
        </h2>
        {status.tracks.length === 0 ? (
          <p className="mt-2 text-sm text-muted-foreground">{t.errors.noTrack}</p>
        ) : (
          <ActionForm
            action={createClass}
            label={t.classes.create}
            className="mt-4"
            buttonClassName="h-10 px-5"
            variant="default"
          >
            <div className="grid w-full gap-3 sm:grid-cols-2">
              <label className="block">
                <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                  {t.classes.fieldAcademy}
                </span>
                <Input
                  name="academy"
                  required
                  minLength={2}
                  className="h-10"
                  autoComplete="organization"
                  placeholder={t.classes.academyPlaceholder}
                />
              </label>
              <label className="block">
                <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                  {t.classes.fieldName}
                </span>
                <Input name="title" required minLength={3} className="h-10" />
              </label>
              <label className="block sm:col-span-2">
                <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                  {t.classes.fieldTrack}
                </span>
                <select name="trackId" required className={fieldClass}>
                  {status.tracks.map((track) => (
                    <option key={track.id} value={track.id}>
                      {track.title}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block sm:col-span-2">
                <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
                  {t.classes.fieldDescription}
                </span>
                <textarea name="description" rows={2} className={fieldClass} />
              </label>
            </div>
            <p className="mt-3 max-w-[70ch] text-xs leading-relaxed text-muted-foreground">
              {t.classes.academyHint}
            </p>
          </ActionForm>
        )}
      </section>

      {classes.length === 0 ? (
        <div className="mt-6 rounded-2xl border border-dashed border-hairline px-6 py-12 text-center">
          <UsersIcon className="mx-auto size-6 text-muted-foreground" aria-hidden />
          <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
            {t.classes.empty}
          </p>
        </div>
      ) : (
        <ul className="mt-6 space-y-4">
          {[...active, ...archived].map((klass) => (
            <li
              key={klass.id}
              className="rounded-2xl border border-hairline bg-card p-5 shadow-sm transition-colors hover:border-electric/40"
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="min-w-0">
                  <Link
                    href={`/app/formateur/classes/${klass.id}`}
                    className="text-base font-semibold text-foreground hover:text-electric"
                  >
                    {klass.title}
                  </Link>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {klass.academy || klass.trackTitle} ·{" "}
                    {fill(t.classes.students, { count: klass.memberCount })}
                  </p>
                </div>
                {klass.status === "active" ? (
                  <ActionForm
                    action={archiveClass}
                    label={t.classes.archive}
                    variant="ghost"
                    hidden={{ classId: klass.id }}
                  />
                ) : (
                  <Badge variant="outline" className="rounded-full">
                    {t.classes.archived}
                  </Badge>
                )}
              </div>

              {klass.description ? (
                <p className="mt-2 line-clamp-2 text-sm leading-relaxed text-muted-foreground">
                  {klass.description}
                </p>
              ) : null}

              <div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-hairline pt-4">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-[11px] font-semibold tracking-wide text-muted-foreground uppercase">
                    {t.classes.joinCode}
                  </span>
                  <code className="rounded-lg bg-muted px-2 py-1 font-mono text-xs tracking-widest text-foreground">
                    {klass.joinCode}
                  </code>
                  <CopyCode code={klass.joinCode} label={t.classes.copyCode} copied={t.classes.copied} />
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-xs text-muted-foreground">
                    {klass.nextSessionAt
                      ? `${t.classes.nextSession} · ${formatDateTime(klass.nextSessionAt)}`
                      : t.classes.noSession}
                  </span>
                  <Button asChild size="sm" className="h-8 px-3">
                    <Link href={`/app/formateur/classes/${klass.id}`}>
                      {t.classes.open}
                    </Link>
                  </Button>
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
