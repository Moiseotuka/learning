-- easyTech — académie nominative et notifications automatiques du formateur.
--
-- Deux besoins décidés avec le produit :
--   * chaque classe porte le nom de l'académie de l'enseignant (ex. « e-learning
--     (ISIPA) ») : c'est ce nom, pas easyTech, qui apparaît dans les invitations,
--     les convocations et la salle en direct ;
--   * le formateur programme ses séances sur un calendrier et le système prévient
--     les apprenants à leur place : convocation avec le tableau du programme,
--     rappel la veille de chaque séance, avis des annulations et reports, relance
--     des absents et rapport de présence au formateur.
--
-- Les envois passent par une boîte de sortie (`instructor_notices`) alimentée et
-- vidée par le serveur. Une ligne = un e-mail dû à une adresse, à une heure
-- précise, avec une clé d'anti-doublon : une planification rejouée deux fois ne
-- part jamais deux fois. Idempotent, réapplicable.

-- ---------------------------------------------------------------------------
-- Nom de l'académie
-- ---------------------------------------------------------------------------
-- Obligatoire à la création (contrôle dans l'action serveur), pas de valeur par
-- défaut en base : une classe sans académie est une classe incomplète.

alter table public.instructor_classes
  add column if not exists academy text not null default '';

comment on column public.instructor_classes.academy is
  'Nom affiché aux apprenants et dans les e-mails, choisi par l''enseignant.';

-- ---------------------------------------------------------------------------
-- Séances : repère de report
-- ---------------------------------------------------------------------------
-- Le calendrier envoyé aux apprenants doit rester honnête : si une séance est
-- déplacée, l'ancienne heure est conservée pour expliquer le report dans l'e-mail.

alter table public.live_sessions
  add column if not exists previous_starts_at timestamptz;

alter table public.live_sessions
  add column if not exists cancelled_at timestamptz;

-- ---------------------------------------------------------------------------
-- Boîte de sortie des notifications
-- ---------------------------------------------------------------------------
-- Le contenu n'est pas stocké : il est composé à l'envoi à partir de l'état réel
-- de la classe et du calendrier. Une convocation mise en file puis modifiée part
-- donc avec le programme corrigé, jamais avec un instantané périmé.

create table if not exists public.instructor_notices (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in (
    'program',
    'session_reminder',
    'session_cancelled',
    'session_rescheduled',
    'absent_followup',
    'attendance_report'
  )),
  class_id uuid not null references public.instructor_classes (id) on delete cascade,
  session_id uuid references public.live_sessions (id) on delete cascade,
  recipient text not null,
  -- Clé naturelle de l'envoi : empêche le rejeu d'une planification de doubler
  -- une convocation déjà partie (et rend la file reprisible après un échec).
  dedup_key text not null,
  scheduled_at timestamptz not null,
  sent_at timestamptz,
  attempts integer not null default 0 check (attempts between 0 and 12),
  last_error text,
  created_at timestamptz not null default now(),
  constraint instructor_notices_dedup unique (dedup_key)
);

create index if not exists instructor_notices_due_idx
  on public.instructor_notices (scheduled_at)
  where sent_at is null;

create index if not exists instructor_notices_class_idx
  on public.instructor_notices (class_id, kind, scheduled_at);

-- Écriture et lecture réservées au serveur : la file contient des adresses
-- e-mail d'apprenants, aucun utilisateur authentifié ne doit la parcourir.
alter table public.instructor_notices enable row level security;
revoke all on table public.instructor_notices from anon, authenticated;
