import type { Metadata } from "next";
import Link from "next/link";
import { UsersIcon } from "lucide-react";

import { ActionForm } from "@/components/instructor/action-form";
import { Notice } from "@/components/auth/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { messages } from "@/i18n";
import { requireUser } from "@/lib/auth/dal";
import {
  acceptInvitation,
  joinClassByCode,
  leaveClass,
} from "@/lib/actions/instructor";
import { fill, formatDate, formatDateTime } from "@/lib/instructor/format";
import { getInvitation, getLearnerClasses } from "@/lib/instructor/queries";

const t = messages.formateur;
const tc = t.myClass;

export const metadata: Metadata = {
  title: tc.title,
  robots: { index: false },
};

export default async function MyClassPage({
  searchParams,
}: {
  searchParams: Promise<{ invitation?: string; joined?: string }>;
}) {
  const params = await searchParams;
  const token = typeof params.invitation === "string" ? params.invitation : "";
  // Le jeton d'invitation est reporté dans l'URL de connexion : sinon
  // l'élève newly inscrit tombe sur /app et perd le lien reçu par e-mail.
  const user = await requireUser(
    token ? `/app/classe?invitation=${encodeURIComponent(token)}` : "/app/classe",
  );

  const [classes, invitation] = await Promise.all([
    getLearnerClasses(user.id),
    token ? getInvitation(token) : Promise.resolve(null),
  ]);

  const alreadyInvited = invitation
    ? classes.some((klass) => klass.classId === invitation.classId)
    : false;

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-8 sm:px-6 lg:py-10">
      <header className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
        <p className="text-xs font-semibold tracking-wider text-electric uppercase">
          {t.eyebrow}
        </p>
        <h1 className="mt-1.5 text-2xl font-semibold tracking-tight text-balance">
          {tc.title}
        </h1>
        <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
          {tc.intro}
        </p>
      </header>

      {token ? (
        <section className="mt-6 rounded-2xl border border-electric/40 bg-electric/6 p-5 shadow-sm sm:p-6">
          {invitation ? (
            <>
              <h2 className="text-base font-semibold text-foreground">
                {fill(tc.inviteTitle, { name: invitation.instructorName })}
              </h2>
              <p className="mt-2 max-w-[70ch] text-sm leading-relaxed text-muted-foreground">
                {fill(tc.inviteBody, {
                  instructor: invitation.instructorName,
                  klass: invitation.className,
                  track: invitation.trackTitle,
                })}
              </p>
              {alreadyInvited ? (
                <div className="mt-4">
                  <Notice tone="info">{tc.alreadyIn}</Notice>
                </div>
              ) : (
                <ActionForm
                  action={acceptInvitation}
                  label={tc.acceptCta}
                  hidden={{ token }}
                  className="mt-4"
                  buttonClassName="h-10 px-5"
                  redirectTo="/app/classe"
                />
              )}
            </>
          ) : (
            <Notice tone="error">{tc.inviteUnknown}</Notice>
          )}
        </section>
      ) : null}

      <section className="mt-6 rounded-2xl border border-hairline bg-card p-5 shadow-sm">
        <h2 className="text-sm font-semibold text-foreground">{tc.joinTitle}</h2>
        <ActionForm
          action={joinClassByCode}
          label={tc.joinCta}
          className="mt-3"
          buttonClassName="h-10 px-5"
        >
          <label className="w-full max-w-xs">
            <span className="mb-1.5 block text-xs font-medium text-muted-foreground">
              {tc.codeField}
            </span>
            <Input
              name="code"
              required
              minLength={6}
              autoComplete="off"
              spellCheck={false}
              className="h-10 font-mono tracking-widest uppercase"
              placeholder={tc.codePlaceholder}
            />
          </label>
        </ActionForm>
        <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
          {tc.joinHint}
        </p>
      </section>

      <section className="mt-6">
        <div className="flex items-center gap-3">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {tc.title}
          </h2>
          <span className="h-px flex-1 bg-hairline" />
          <Link
            href="/app/classe/agenda"
            className="shrink-0 text-xs font-medium text-electric hover:underline"
          >
            {tc.agendaAll}
          </Link>
          <span className="text-xs tabular-nums text-muted-foreground">
            {classes.length}
          </span>
        </div>

        {classes.length === 0 ? (
          <div className="mt-4 rounded-2xl border border-dashed border-hairline px-6 py-12 text-center">
            <UsersIcon className="mx-auto size-6 text-muted-foreground" aria-hidden />
            <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
              {tc.empty}
            </p>
          </div>
        ) : (
          <ul className="mt-4 space-y-4">
            {classes.map((klass) => (
              <li
                key={klass.classId}
                className="rounded-2xl border border-hairline bg-card p-5 shadow-sm"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0">
                    <h3 className="text-base font-semibold text-foreground">
                      {klass.title}
                    </h3>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {klass.academy ? `${klass.academy} · ` : ""}
                      {fill(tc.taughtBy, { name: klass.instructorName })} ·{" "}
                      {fill(tc.joinedOn, { date: formatDate(klass.joinedAt) })}
                    </p>
                  </div>
                  <Badge
                    variant="secondary"
                    className="rounded-full bg-electric/10 px-2.5 py-0.5 text-[11px] text-electric"
                  >
                    {klass.trackTitle}
                  </Badge>
                </div>

                {klass.nextSession ? (
                  <p className="mt-3 text-xs text-muted-foreground">
                    {fill(tc.nextSession, {
                      when: formatDateTime(klass.nextSession.startsAt),
                    })}
                  </p>
                ) : null}

                <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-hairline pt-4">
                  <Button asChild size="sm" className="h-9 px-4">
                    <Link href={`/app/parcours/${klass.trackSlug}`}>
                      {tc.openTrack}
                    </Link>
                  </Button>
                  {klass.nextSession ? (
                    <Button asChild variant="outline" size="sm" className="h-9 px-4">
                      <Link href={`/app/live/${klass.nextSession.id}`}>
                        {messages.live.room.join}
                      </Link>
                    </Button>
                  ) : null}
                  <Button asChild variant="outline" size="sm" className="h-9 px-4">
                    <Link
                      href={`/app/classe/agenda?class=${klass.classId}`}
                    >
                      {tc.agendaForClass}
                    </Link>
                  </Button>
                  <ActionForm
                    action={leaveClass}
                    label={tc.leave}
                    variant="ghost"
                    className="ml-auto"
                    hidden={{ classId: klass.classId }}
                    redirectTo="/app/classe"
                  />
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
