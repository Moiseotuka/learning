import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { ArrowLeftIcon, CalendarClockIcon } from "lucide-react";

import { ActionForm } from "@/components/instructor/action-form";
import { LiveRoom } from "@/components/live/live-room";
import { Notice } from "@/components/auth/notice";
import { Button } from "@/components/ui/button";
import { messages } from "@/i18n";
import { getProfile, requireUser } from "@/lib/auth/dal";
import { fill, formatDateTime } from "@/lib/instructor/format";
import { getLiveSession } from "@/lib/instructor/queries";
import { setLiveSessionStatus } from "@/lib/actions/instructor";
import {
  buildRoomOptions,
  jitsiDomain,
  jitsiExternalApiUrl,
  joinWindow,
  untilLabel,
} from "@/lib/live/provider";

const t = messages.live;
const tf = messages.formateur;

export const metadata: Metadata = {
  title: t.room.title,
  robots: { index: false },
};

export default async function LiveRoomPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const user = await requireUser(`/app/live/${id}`);
  const [{ session, isHost, canJoin, roomName }, profile] = await Promise.all([
    getLiveSession(id, user.id),
    getProfile(),
  ]);

  if (!session) notFound();
  if (!canJoin) redirect("/interdit");

  const displayName =
    profile?.full_name?.trim() ||
    (typeof user.user_metadata?.full_name === "string"
      ? user.user_metadata.full_name.trim()
      : "") ||
    user.email?.split("@")[0] ||
    "Participant";
  const email = profile?.email ?? user.email ?? null;

  const window_ = joinWindow(session.startsAt, session.endsAt, session.status);

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-8 sm:px-6 lg:py-10">
      <Button
        asChild
        variant="ghost"
        className="-ml-2 mb-4 h-8 px-2 text-xs text-muted-foreground"
      >
        <Link href={isHost ? "/app/formateur" : "/app/classe"}>
          <ArrowLeftIcon aria-hidden />
          {isHost ? tf.dashboardTitle : messages.formateur.myClass.title}
        </Link>
      </Button>

      <header className="rounded-2xl border border-hairline bg-card p-5 shadow-sm sm:p-6">
        <p className="text-xs font-semibold tracking-wider text-electric uppercase">
          {t.eyebrow}
        </p>
        <h1 className="mt-1.5 text-2xl font-semibold tracking-tight text-balance">
          {session.title}
        </h1>

        <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
          <span className="flex items-center gap-1.5">
            <CalendarClockIcon className="size-3.5" aria-hidden />
            {fill(t.room.startsAt, { time: formatDateTime(session.startsAt) })}
          </span>
          <span>{fill(t.room.student, { name: session.instructorName })}</span>
          {session.className ? (
            <span>{fill(t.learner.inClass, { name: session.className })}</span>
          ) : null}
        </div>

        {session.agenda ? (
          <p className="mt-3 max-w-[70ch] text-sm leading-relaxed whitespace-pre-line text-muted-foreground">
            {session.agenda}
          </p>
        ) : null}

        {isHost ? (
          <div className="mt-4 flex flex-wrap gap-2 border-t border-hairline pt-4">
            {session.status !== "live" ? (
              <ActionForm
                action={setLiveSessionStatus}
                label={t.module.startNow}
                hidden={{ sessionId: session.id, status: "live" }}
                inline={false}
              />
            ) : null}
            {session.status !== "ended" ? (
              <ActionForm
                action={setLiveSessionStatus}
                label={t.module.end}
                variant="outline"
                hidden={{ sessionId: session.id, status: "ended" }}
                inline={false}
              />
            ) : null}
          </div>
        ) : null}
      </header>

      <div className="mt-6">
        {window_.openable && roomName ? (
          <LiveRoom
            sessionId={session.id}
            roomName={roomName}
            domain={jitsiDomain()}
            scriptUrl={jitsiExternalApiUrl()}
            subject={session.title}
            displayName={displayName}
            email={email}
            isHost={isHost}
            options={buildRoomOptions({
              roomName,
              displayName,
              email,
              isModerator: isHost,
              subject: session.title,
            })}
          />
        ) : window_.state === "closed" || session.status === "ended" || session.status === "cancelled" ? (
          <Notice tone="info">{t.room.closed}</Notice>
        ) : (
          <div className="rounded-2xl border border-hairline bg-card p-6 shadow-sm">
            <Notice tone="info">
              {fill(t.room.opensAt, { when: untilLabel(window_.opensAt) })}
            </Notice>
            <p className="mt-2 text-xs text-muted-foreground">{t.room.tooEarly}</p>
          </div>
        )}
      </div>

      {isHost ? null : (
        <p className="mt-4 text-xs leading-relaxed text-muted-foreground">
          {t.room.privacy}
        </p>
      )}
    </div>
  );
}
