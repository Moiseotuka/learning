-- easyLearn — examens de fin de niveau
-- Un examen se débloque quand tous les chapitres d'un niveau sont complétés ;
-- le premier chapitre du niveau suivant reste verrouillé tant que l'examen
-- n'est pas réussi. Les questions sont piochées (et mélangées) dans les quiz
-- des chapitres du niveau : aucune table de questions dédiée.
-- Écritures réservées au serveur (service role) : pas de policy insert/update
-- pour authenticated, contrairement à chapter_progress.
-- Idempotent : peut être réappliqué sans effet de bord.

create table if not exists public.level_exams (
  user_id uuid not null references auth.users (id) on delete cascade,
  track_id text not null references public.tracks (id) on delete cascade,
  level text not null check (level in ('debutant', 'intermediaire', 'avance', 'projet')),
  attempts integer not null default 0,
  best_score integer check (best_score between 0 and 100),
  status text not null default 'in_progress' check (status in ('in_progress', 'passed')),
  passed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, track_id, level)
);

create index if not exists level_exams_user_track_idx
  on public.level_exams (user_id, track_id);

drop trigger if exists level_exams_set_updated_at on public.level_exams;
create trigger level_exams_set_updated_at
  before update on public.level_exams
  for each row execute function public.set_updated_at();

-- Row Level Security ---------------------------------------------------------

alter table public.level_exams enable row level security;

drop policy if exists "exams_select_own" on public.level_exams;
create policy "exams_select_own" on public.level_exams
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());
