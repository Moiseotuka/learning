-- easyLearn — certificats de réussite
-- Un certificat est délivré automatiquement quand l'apprenant termine un
-- niveau (tous les chapitres du niveau validés) ou le parcours complet
-- (100 % des chapitres validés), puis envoyé par email.
-- level = 'debutant'|'intermediaire'|'avance'|'projet' (certificat de niveau)
--       | 'parcours' (certificat final du parcours).
-- code  = identifiant public unique, format AAA-AAAA-NNNNNN (ex. PYT-2026-000123),
--         vérifiable sur /verifier?code=… — URL QR encodée côté PDF.
-- full_name / track_title / title sont figés au moment de la délivrance
-- (snapshot) : le certificat reste stable même si le parcours change.
-- Écritures réservées au serveur (service role), comme category_level_prices :
-- aucune policy insert/update client. Lecture : l'apprenant voit ses lignes,
-- /verifier lit via service role.
-- Idempotent : contrainte unique (user_id, track_id, level) + on conflict do nothing.

create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  track_id text not null references public.tracks (id) on delete cascade,
  level text not null check (
    level in ('debutant', 'intermediaire', 'avance', 'projet', 'parcours')
  ),
  code text not null unique,
  title text not null,
  track_title text not null,
  full_name text not null,
  issued_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, track_id, level)
);

create index if not exists certificates_user_idx
  on public.certificates (user_id, issued_at desc);

alter table public.certificates enable row level security;

drop policy if exists "certificates_select_own" on public.certificates;
create policy "certificates_select_own" on public.certificates
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

-- Défense en profondeur : aucune écriture client sur les certificats.
revoke all on table public.certificates from anon, authenticated;
grant select on table public.certificates to authenticated;
