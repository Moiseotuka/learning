-- easyLearn — étape 3 : catalogue + back-office de base
-- À appliquer sur le projet Supabase (SQL Editor ou API management).
-- Idempotent : peut être réappliqué sans effet de bord.

-- 1. Profils et rôles -------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'learner' check (role in ('learner', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Fonction sûre (SECURITY DEFINER) utilisable dans les politiques RLS
-- sans risque de récursion sur public.profiles.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated, service_role;

-- 2. Catalogue --------------------------------------------------------------

create table if not exists public.categories (
  id text primary key,
  slug text not null unique,
  name text not null,
  description text not null default '',
  icon text not null default 'terminal',
  levels text[] not null default '{debutant}',
  track_count integer not null default 0,
  position integer not null default 0,
  published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categories_levels_valid check (
    levels <@ array['debutant', 'intermediaire', 'avance', 'projet']
  )
);

drop trigger if exists categories_set_updated_at on public.categories;
create trigger categories_set_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

create table if not exists public.tracks (
  id text primary key,
  category_id text not null references public.categories (id) on delete cascade,
  slug text not null unique,
  title text not null,
  description text not null default '',
  level text not null check (level in ('debutant', 'intermediaire', 'avance', 'projet')),
  duration_hours integer not null default 0,
  modules_count integer not null default 0,
  price_usd integer,
  rating numeric(2, 1) not null default 0,
  students integer not null default 0,
  position integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists tracks_set_updated_at on public.tracks;
create trigger tracks_set_updated_at
  before update on public.tracks
  for each row execute function public.set_updated_at();

create index if not exists tracks_category_id_idx on public.tracks (category_id);
create index if not exists tracks_published_position_idx on public.tracks (published, position);

-- 3. Row Level Security -----------------------------------------------------

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.tracks enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or public.is_admin());

drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin" on public.profiles
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "categories_select" on public.categories;
create policy "categories_select" on public.categories
  for select
  using (published or public.is_admin());

drop policy if exists "categories_admin_write" on public.categories;
create policy "categories_admin_write" on public.categories
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "tracks_select" on public.tracks;
create policy "tracks_select" on public.tracks
  for select
  using (published or public.is_admin());

drop policy if exists "tracks_admin_write" on public.tracks;
create policy "tracks_admin_write" on public.tracks
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- 4. Rôles admins ------------------------------------------------------------

insert into public.profiles (id, email, full_name, role)
select u.id,
       u.email,
       coalesce(u.raw_user_meta_data ->> 'full_name', ''),
       'admin'
from auth.users u
where u.email = 'otukaotukamo@gmail.com'
on conflict (id) do nothing;

update public.profiles
set role = 'admin'
where email = 'otukaotukamo@gmail.com';

-- 5. Seed du catalogue -------------------------------------------------------

insert into public.categories (id, slug, name, description, icon, levels, track_count, position) values
  ('prog', 'programmation', 'Programmation', 'Algorithmique, Python, Java, C#, C++, C, Pascal, JavaScript, HTML, CSS, SQL, PHP.', 'terminal', array['debutant','intermediaire','avance','projet'], 14, 1),
  ('web', 'developpement-web-mobile', 'Développement web et mobile', 'Interfaces responsive, APIs, frameworks front-end et applications mobiles.', 'layout', array['debutant','intermediaire','avance','projet'], 9, 2),
  ('ai', 'ia-data', 'Intelligence artificielle et data', 'Machine learning, data science, analyse et modèles prédictifs.', 'brain', array['debutant','intermediaire','avance'], 6, 3),
  ('cyber', 'cybersecurite', 'Cybersécurité', 'Menaces, durcissement des systèmes, investigation et bonnes pratiques.', 'shield', array['debutant','intermediaire','avance','projet'], 5, 4),
  ('net', 'reseaux-telecoms', 'Réseaux et télécommunications', 'Câblage, adressage, routage, wireless et supervision.', 'network', array['debutant','intermediaire','avance','projet'], 7, 5),
  ('embedded', 'systemes-embarques', 'Systèmes embarqués', 'Arduino, ESP32, STM32, capteurs et interfaçage temps réel.', 'cpu', array['debutant','intermediaire','avance','projet'], 4, 6),
  ('electronics', 'electronique', 'Électronique', 'Composants, schémas, mesure et prototypage de circuits.', 'circuit', array['debutant','intermediaire','avance'], 4, 7),
  ('physics', 'physique-appliquee', 'Physique appliquée', 'Mécanique, électricité et expérimentation orientée projets.', 'atom', array['debutant','intermediaire'], 3, 8),
  ('mecha', 'mecatronique-robotique', 'Mécatronique et robotique', 'Automatisme, actionneurs, capteurs et robotique mobile.', 'robot', array['debutant','intermediaire','avance'], 3, 9),
  ('cloud', 'cloud-devops', 'Cloud et DevOps', 'Conteneurs, CI/CD, infrastructure as code et observabilité.', 'cloud', array['intermediaire','avance','projet'], 4, 10)
on conflict (id) do nothing;

insert into public.tracks (id, category_id, slug, title, description, level, duration_hours, modules_count, price_usd, rating, students, position, published) values
  ('python-developpeur', 'prog', 'python-developpeur', 'Python : du premier script au projet complet', 'Débuter en programmation avec une langue demandée partout', 'debutant', 48, 32, 49, 4.8, 2340, 1, true),
  ('developpement-web-moderne', 'web', 'developpement-web-moderne', 'Développement web moderne : HTML, CSS, JavaScript, React', 'Concevoir des sites et applications web prêts pour le terrain', 'debutant', 60, 40, 59, 4.9, 3120, 2, true),
  ('cybersecurite-fondamentaux', 'cyber', 'cybersecurite-fondamentaux', 'Cybersécurité : fondamentaux et défense des systèmes', 'Sécuriser un réseau, un serveur ou une application', 'debutant', 42, 28, 69, 4.7, 1470, 3, true),
  ('reseaux-protocoles-routage', 'net', 'reseaux-protocoles-routage', 'Réseaux : protocoles, routage et supervision', 'Administrer un réseau d''entreprise de bout en bout', 'intermediaire', 55, 36, 59, 4.8, 1890, 4, true),
  ('ia-data-science', 'ai', 'ia-data-science', 'Intelligence artificielle et Data Science appliquées', 'Construire et évaluer des modèles sur de vraies données', 'intermediaire', 70, 44, 89, 4.9, 960, 5, true),
  ('arduino-esp32-embarque', 'embedded', 'arduino-esp32-embarque', 'Arduino et ESP32 : systèmes embarqués pratiques', 'Prototyper des objets connectés et des automates', 'debutant', 38, 26, 45, 4.6, 1210, 6, true)
on conflict (id) do nothing;
