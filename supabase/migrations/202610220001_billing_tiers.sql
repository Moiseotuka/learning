-- Paliers de facturation de l'hôte d'une séance (modèle Zoom) + relance d'expiration.
-- La durée annoncée d'une séance ne borne plus la salle ; `cap_minutes` est le
-- budget réellement concédé à l'hôte, lu à chaque ouverture de la salle.

alter table public.live_sessions
  add column if not exists cap_minutes integer;

alter table public.live_sessions
  drop constraint if exists live_sessions_cap_minutes_check;

alter table public.live_sessions
  add constraint live_sessions_cap_minutes_check
  check (cap_minutes is null or cap_minutes between 5 and 1440);

comment on column public.live_sessions.cap_minutes is
  'Budget de minutes concédé à l''hôte au moment de la planification ; null = séance sans quota.';

-- Une relance d'abonnement ne concerne aucune classe : la file doit pouvoir
-- porter une échéance qui tient à l'abonné, pas à un cours.
alter table public.instructor_notices
  alter column class_id drop not null;

alter table public.instructor_notices
  drop constraint if exists instructor_notices_kind_check;

alter table public.instructor_notices
  add constraint instructor_notices_kind_check
  check (kind = any (array[
    'program',
    'session_reminder',
    'session_cancelled',
    'session_rescheduled',
    'absent_followup',
    'attendance_report',
    'subscription_expiry'
  ]));
