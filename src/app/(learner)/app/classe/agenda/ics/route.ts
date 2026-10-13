import { requireUser } from "@/lib/auth/dal";
import { getLearnerClasses, getUpcomingSessionsForLearner } from "@/lib/instructor/queries";
import {
  ACADEMY_TIME_ZONE,
  icsLocalStamp,
  icsTimeZone,
} from "@/lib/instructor/timezone";

/**
 * Agenda des séances d'une classe, en fichier .ics.
 *
 * Les élèves n'ont pas tous un smartphone ni une connexion constante : le
 * calendrier de l'académie s'importe dans celui du téléphone et la date reste
 * lisible hors ligne. Les heures sont écrites dans le fuseau de l'académie avec
 * son bloc `VTIMEZONE`, pour qu'aucun agenda ne les décale d'une heure.
 */
export const dynamic = "force-dynamic";

function esc(value: string): string {
  return value
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\r?\n/g, "\\n");
}

/** Une ligne d'un fichier .ics ne doit pas dépasser 75 octets. */
function fold(line: string): string {
  if (line.length <= 74) return line;
  const head = line.slice(0, 74);
  return `${head}\r\n ${fold(line.slice(74))}`;
}

function event(input: {
  id: string;
  title: string;
  className: string;
  academy: string;
  agenda: string;
  startsAt: string;
  endsAt: string;
  url: string;
}): string {
  const description = [
    `Classe : ${input.className}`,
    input.academy ? `Académie : ${input.academy}` : "",
    input.agenda ? `Ordre du jour : ${input.agenda}` : "",
    `Lien de la salle : ${input.url}`,
  ]
    .filter(Boolean)
    .join("\n");

  return [
    "BEGIN:VEVENT",
    `UID:${input.id}@easylearn`,
    `DTSTAMP:${icsLocalStamp(new Date())}Z`,
    `DTSTART;TZID=${ACADEMY_TIME_ZONE}:${icsLocalStamp(input.startsAt)}`,
    `DTEND;TZID=${ACADEMY_TIME_ZONE}:${icsLocalStamp(input.endsAt)}`,
    `SUMMARY:${esc(`${input.academy ? `${input.academy} — ` : ""}${input.title}`)}`,
    `DESCRIPTION:${esc(description)}`,
    `URL:${input.url}`,
    "LOCATION:easyTech",
    "STATUS:CONFIRMED",
    "END:VEVENT",
  ].join("\r\n");
}

export async function GET(request: Request): Promise<Response> {
  const user = await requireUser("/app/profil");
  const url = new URL(request.url);
  const classId = url.searchParams.get("class") ?? "";

  const [classes, sessions] = await Promise.all([
    getLearnerClasses(user.id),
    getUpcomingSessionsForLearner(user.id, {
      classId: classId || undefined,
      limit: 60,
    }),
  ]);

  if (classId && !classes.some((klass) => klass.classId === classId)) {
    return new Response("Classe introuvable pour cet élève.", { status: 403 });
  }

  const own = classId
    ? sessions.filter((session) => session.classId === classId)
    : sessions;

  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//easyTech//Calendrier des classes//FR",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${esc(own[0]?.academy || own[0]?.className || "Cours easyTech")}`,
    `X-WR-TIMEZONE:${ACADEMY_TIME_ZONE}`,
    icsTimeZone(),
    ...own.map((session) =>
      event({
        id: session.id,
        title: session.title,
        className: session.className ?? "",
        academy: session.academy ?? "",
        agenda: session.agenda,
        startsAt: session.startsAt,
        endsAt: session.endsAt,
        url: `${url.origin}/app/live/${session.id}`,
      }),
    ),
    "END:VCALENDAR",
  ];

  const body = `${lines.map(fold).join("\r\n")}\r\n`;
  const name = (own[0]?.className || "cours").replace(/[^\p{L}\p{N}-]/gu, "-");

  return new Response(body, {
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": `attachment; filename="agenda-${name}.ics"`,
      "Cache-Control": "no-store",
    },
  });
}
