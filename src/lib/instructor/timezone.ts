/**
 * Heure de l'académie.
 *
 * Les séances sont saisies en heures de Kinshasa (GMT+1, sans changement
 * d'heure) : c'est le fuseau des classes, pas celui du serveur ni celui du
 * navigateur de l'élève. Sans cette règle, un formateur qui écrit « 19 h 30 »
 * ouvrirait sa salle à une heure différente selon la machine qui l'héberge, et
 * les convocations partiraient à contretemps.
 *
 * Le décalage est mesuré avec `Intl` plutôt que supposé : la règle resterait
 * juste pour une académie soumise à l'heure d'été.
 */

export const ACADEMY_TIME_ZONE = "Africa/Kinshasa";
export const ACADEMY_TZ_LABEL = "Kinshasa (GMT+1)";

/** Les rappels partent la veille, à cette heure de l'académie. */
export const REMINDER_HOUR = 19;
export const REMINDER_MINUTE = 30;

type ZoneParts = {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
};

function zoneParts(at: Date, timeZone: string): ZoneParts {
  const raw = new Map(
    new Intl.DateTimeFormat("en-GB", {
      timeZone,
      hourCycle: "h23",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    })
      .formatToParts(at)
      .filter((part) => part.type !== "literal")
      .map((part) => [part.type, part.value]),
  );

  return {
    year: Number(raw.get("year")),
    month: Number(raw.get("month")),
    day: Number(raw.get("day")),
    hour: Number(raw.get("hour")) % 24,
    minute: Number(raw.get("minute")),
    second: Number(raw.get("second")),
  };
}

/** Décalage local − UTC, en minutes, mesuré à l'instant demandé. */
function zoneOffsetMinutes(at: Date, timeZone: string): number {
  const p = zoneParts(at, timeZone);
  const wallAsUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  return Math.round((wallAsUtc - at.getTime()) / 60_000);
}

/** Instant UTC d'une date et d'une heure écrites dans le fuseau de l'académie. */
export function zonedInstant(
  date: string,
  time: string,
  timeZone = ACADEMY_TIME_ZONE,
): Date | null {
  const day = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  const clock = /^(\d{1,2}):(\d{2})$/.exec(time);
  if (!day || !clock) return null;

  const wall = Date.UTC(
    Number(day[1]),
    Number(day[2]) - 1,
    Number(day[3]),
    Number(clock[1]),
    Number(clock[2]),
  );
  if (Number.isNaN(wall)) return null;

  // Deux passes : la première ignore si l'heure demandée tombe de part et
  // d'autre d'une bascule d'heure, la seconde corrige le décalage.
  const first = wall - zoneOffsetMinutes(new Date(wall), timeZone) * 60_000;
  const instant = new Date(wall - zoneOffsetMinutes(new Date(first), timeZone) * 60_000);
  return Number.isNaN(instant.getTime()) ? null : instant;
}

/**
 * Rappel d'une séance : 19 h 30 de la veille à l'heure de l'académie.
 * Une planification trop tardive ne doit pas faire taire le rappel : il part
 * alors dans la minute, l'élève est prévenu avant l'ouverture de la salle.
 */
export function reminderInstant(
  startsAt: string | Date,
  now = new Date(),
  timeZone = ACADEMY_TIME_ZONE,
): Date {
  const p = zoneParts(new Date(startsAt), timeZone);
  const eveningWall =
    Date.UTC(p.year, p.month - 1, p.day, REMINDER_HOUR, REMINDER_MINUTE) - 86_400_000;
  const scheduled = new Date(
    eveningWall - zoneOffsetMinutes(new Date(eveningWall), timeZone) * 60_000,
  );
  return scheduled.getTime() > now.getTime()
    ? scheduled
    : new Date(now.getTime() + 60_000);
}

/** « mardi 21 octobre, 19:30 » — lu à l'heure de l'académie. */
export function academyDateTimeLabel(
  value: string | Date,
  timeZone = ACADEMY_TIME_ZONE,
): string {
  return new Intl.DateTimeFormat("fr-FR", {
    timeZone,
    weekday: "long",
    day: "2-digit",
    month: "long",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

export function academyDateLabel(
  value: string | Date,
  timeZone = ACADEMY_TIME_ZONE,
): string {
  return new Intl.DateTimeFormat("fr-FR", {
    timeZone,
    weekday: "long",
    day: "2-digit",
    month: "long",
    year: "numeric",
  }).format(new Date(value));
}

export function academyHourLabel(
  value: string | Date,
  timeZone = ACADEMY_TIME_ZONE,
): string {
  return new Intl.DateTimeFormat("fr-FR", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

/** Heure locale de l'académie au format compact d'un fichier .ics. */
export function icsLocalStamp(value: string | Date, timeZone = ACADEMY_TIME_ZONE): string {
  const p = zoneParts(new Date(value), timeZone);
  const n = (amount: number) => String(amount).padStart(2, "0");
  return `${p.year}${n(p.month)}${n(p.day)}T${n(p.hour)}${n(p.minute)}${n(p.second)}`;
}

/**
 * Bloc `VTIMEZONE` du fuseau de l'académie : les agendas externes placent la
 * séance à l'heure locale dite plutôt que de la recalculer depuis UTC.
 */
export function icsTimeZone(timeZone = ACADEMY_TIME_ZONE): string {
  const offset = zoneOffsetMinutes(new Date(), timeZone);
  const sign = offset < 0 ? "-" : "+";
  const abs = Math.abs(offset);
  const hh = String(Math.floor(abs / 60)).padStart(2, "0");
  const mm = String(abs % 60).padStart(2, "0");
  return [
    "BEGIN:VTIMEZONE",
    `TZID:${timeZone}`,
    "BEGIN:STANDARD",
    `TZOFFSETFROM:${sign}${hh}${mm}`,
    `TZOFFSETTO:${sign}${hh}${mm}`,
    "DTSTART:19700101T000000",
    "END:STANDARD",
    "END:VTIMEZONE",
  ].join("\r\n");
}
