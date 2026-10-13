-- easyTech — espace formateur : abonnement payant, classes d'apprenants et cours en direct.
--
-- Modèle économique décidé avec le produit :
--   * le statut de formateur est un abonnement à durée limitée (1, 3, 6 ou 12 mois) ;
--     plus la durée est longue, plus le prix monte mais plus le mois revient cher
--     bon marché (remises 0 % / 20 % / 30 % / 40 %) ;
--   * un formateur obtient l'accès complet (tous les niveaux) des parcours qu'il a
--     choisis pendant la durée de son abonnement ;
--   * chaque plan inclut un quota de places d'apprenants : un élève ajouté à une
--     classe ouvre le parcours de cette classe sans payer, tant que la place tient
--     dans le quota et que l'abonnement du formateur est valide ;
--   * à l'expiration, tout ce qui découle de l'abonnement est révoqué automatiquement
--     (les achats individuels des élèves, eux, survivent).
--
-- Écritures réservées au serveur (rôle service), comme pour `purchases` : aucune
-- policy insert/update/delete pour authenticated. Idempotent, réapplicable.

-- ---------------------------------------------------------------------------
-- Barème des abonnements
-- ---------------------------------------------------------------------------

create table if not exists public.instructor_plans (
  id text primary key,
  label text not null,
  duration_days integer not null check (duration_days > 0),
  price_fc integer not null check (price_fc >= 0),
  seats_limit integer not null default 25 check (seats_limit > 0),
  track_limit integer not null default 3 check (track_limit > 0),
  discount_pct integer not null default 0 check (discount_pct between 0 and 90),
  highlight text,
  published boolean not null default true,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.instructor_plans
  (id, label, duration_days, price_fc, seats_limit, track_limit, discount_pct, highlight, position)
values
  ('un_mois',   '1 mois',    30,  25000, 25, 3,  0, null,                  1),
  ('trois_mois','3 mois',    90,  60000, 25, 5, 20, 'Le plus choisi',      2),
  ('six_mois',  '6 mois',   180, 105000, 25, 8, 30, null,                  3),
  ('douze_mois','12 mois',  365, 180000, 25, 12, 40, 'Meilleur prix par mois', 4)
on conflict (id) do update set
  label = excluded.label,
  duration_days = excluded.duration_days,
  price_fc = excluded.price_fc,
  seats_limit = excluded.seats_limit,
  track_limit = excluded.track_limit,
  discount_pct = excluded.discount_pct,
  highlight = excluded.highlight,
  position = excluded.position;

-- ---------------------------------------------------------------------------
-- Abonnements souscrits
-- ---------------------------------------------------------------------------
-- seats_limit et track_limit sont recopiés au moment de l'achat : modifier un
-- barème ensuite ne doit jamais changer ce qui a déjà été facturé.

create table if not exists public.instructor_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_id text not null references public.instructor_plans (id),
  status text not null default 'pending'
    check (status in ('pending', 'active', 'expired', 'cancelled', 'failed')),
  amount_fc integer not null check (amount_fc >= 0),
  currency text not null default 'CDF',
  provider text not null default 'nyole' check (provider in ('mock', 'nyole')),
  provider_reference text,
  seats_limit integer not null default 25 check (seats_limit > 0),
  track_limit integer not null default 3 check (track_limit > 0),
  started_at timestamptz,
  expires_at timestamptz,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists instructor_subscriptions_user_idx
  on public.instructor_subscriptions (user_id, status, expires_at);

-- Un seul abonnement actif à la fois : la reconduction remplace l'ancien.
create unique index if not exists instructor_subscriptions_one_active
  on public.instructor_subscriptions (user_id)
  where status = 'active';

create table if not exists public.instructor_subscription_tracks (
  subscription_id uuid not null references public.instructor_subscriptions (id) on delete cascade,
  track_id text not null references public.tracks (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (subscription_id, track_id)
);

-- ---------------------------------------------------------------------------
-- Classes d'apprenants
-- ---------------------------------------------------------------------------

create table if not exists public.instructor_classes (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references auth.users (id) on delete cascade,
  track_id text not null references public.tracks (id) on delete cascade,
  title text not null,
  description text not null default '',
  join_code text not null unique,
  status text not null default 'active' check (status in ('active', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists instructor_classes_instructor_idx
  on public.instructor_classes (instructor_id, status);

create table if not exists public.instructor_class_members (
  class_id uuid not null references public.instructor_classes (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  source text not null default 'code' check (source in ('code', 'invite', 'admin')),
  status text not null default 'active' check (status in ('active', 'removed')),
  joined_at timestamptz not null default now(),
  primary key (class_id, user_id)
);

create index if not exists instructor_class_members_user_idx
  on public.instructor_class_members (user_id, status);

create table if not exists public.instructor_class_invites (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.instructor_classes (id) on delete cascade,
  email text not null,
  token text not null unique,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'expired', 'cancelled')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  expires_at timestamptz not null default now() + interval '14 days'
);

create index if not exists instructor_class_invites_class_idx
  on public.instructor_class_invites (class_id, status);

-- ---------------------------------------------------------------------------
-- Cours en direct
-- ---------------------------------------------------------------------------
-- room_name est l'identifiant de salle de l'infrastructure vidéo ; il n'apparaît
-- jamais à l'écran, seule l'URL de la salle intégrée est utilisée.

create table if not exists public.live_sessions (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references auth.users (id) on delete cascade,
  class_id uuid references public.instructor_classes (id) on delete set null,
  track_id text references public.tracks (id) on delete set null,
  title text not null,
  agenda text not null default '',
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  room_name text not null unique,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'live', 'ended', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint live_sessions_window check (ends_at > starts_at)
);

create index if not exists live_sessions_instructor_idx
  on public.live_sessions (instructor_id, starts_at);

create index if not exists live_sessions_start_idx
  on public.live_sessions (starts_at)
  where status in ('scheduled', 'live');

create table if not exists public.live_session_attendance (
  session_id uuid not null references public.live_sessions (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  seconds integer not null default 0 check (seconds >= 0),
  primary key (session_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Triggers updated_at
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
begin
  foreach t in array array[
    'instructor_plans', 'instructor_subscriptions', 'instructor_classes'
  ]
  loop
    execute format('drop trigger if exists %I_set_updated_at on public.%I', t, t);
    execute format(
      'create trigger %I_set_updated_at before update on public.%I
         for each row execute function public.set_updated_at()', t, t);
  end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- Source de vérité des droits accordés hors achat individuel
-- ---------------------------------------------------------------------------
-- Catégories ouvertes à un utilisateur par un abonnement de formateur :
--   1. les parcours que le formateur a choisis et qu'il enseigne ;
--   2. les parcours des classes dont il est élève, dans la limite du quota de
--      places de l'abonnement de son formateur.
-- Les places sont numérotées par ordre d'arrivée : au-delà du quota, la place
-- n'est pas accordée (le quinzième élève d'un plan de quinze places paiera son
-- propre accès, il n'est pas privé de cours pour autant).

create or replace function public.granted_category_ids(p_user uuid)
returns table (category_id text)
language sql
stable
security definer
set search_path = public
as $$
  with taught as (
    select k.category_id
    from public.instructor_subscription_tracks st
    join public.instructor_subscriptions s on s.id = st.subscription_id
    join public.tracks k on k.id = st.track_id
    where s.user_id = p_user
      and s.status = 'active'
      and s.expires_at > now()
  ),
  seated as (
    select
      m.user_id,
      k.category_id,
      row_number() over (
        partition by c.instructor_id
        order by m.joined_at, m.class_id, m.user_id
      ) as seat,
      s.seats_limit
    from public.instructor_class_members m
    join public.instructor_classes c on c.id = m.class_id
    join public.instructor_subscriptions s on s.user_id = c.instructor_id
    join public.tracks k on k.id = c.track_id
    where m.status = 'active'
      and c.status = 'active'
      and s.status = 'active'
      and s.expires_at > now()
  )
  select category_id from taught
  union
  select category_id from seated where user_id = p_user and seat <= seats_limit;
$$;

revoke all on function public.granted_category_ids(uuid) from public;
grant execute on function public.granted_category_ids(uuid) to anon, authenticated;

-- Vrai si l'utilisateur courant peut ouvrir `p_level` du domaine
-- `p_category_id` : débutant gratuit, achat payé, ou droit accordé par un
-- abonnement de formateur (les deux cas ci-dessus).
create or replace function public.has_level_access(p_category_id text, p_level text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_level = 'debutant'
    or exists (
      select 1
      from public.purchases
      where user_id = auth.uid()
        and category_id = p_category_id
        and level = p_level
        and status = 'paid'
    )
    or exists (
      select 1
      from public.granted_category_ids(auth.uid()) g
      where g.category_id = p_category_id
    );
$$;

revoke all on function public.has_level_access(text, text) from public;
grant execute on function public.has_level_access(text, text) to anon, authenticated;

-- Abonnement actif d'un utilisateur (null quand expiré ou jamais souscrit).
create or replace function public.active_instructor_subscription(p_user uuid)
returns public.instructor_subscriptions
language sql
stable
security definer
set search_path = public
as $$
  select s.*
  from public.instructor_subscriptions s
  where s.user_id = p_user
    and s.status = 'active'
    and s.expires_at > now()
  order by s.expires_at desc
  limit 1;
$$;

revoke all on function public.active_instructor_subscription(uuid) from public;
grant execute on function public.active_instructor_subscription(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.instructor_plans enable row level security;
alter table public.instructor_subscriptions enable row level security;
alter table public.instructor_subscription_tracks enable row level security;
alter table public.instructor_classes enable row level security;
alter table public.instructor_class_members enable row level security;
alter table public.instructor_class_invites enable row level security;
alter table public.live_sessions enable row level security;
alter table public.live_session_attendance enable row level security;

-- Le barème est public : la page d'accueil affiche les tarifs du formateur.
drop policy if exists "instructor_plans_select" on public.instructor_plans;
create policy "instructor_plans_select" on public.instructor_plans
  for select
  using (published = true or public.is_admin());

drop policy if exists "instructor_subscriptions_select_own" on public.instructor_subscriptions;
create policy "instructor_subscriptions_select_own" on public.instructor_subscriptions
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "instructor_subscription_tracks_select_own" on public.instructor_subscription_tracks;
create policy "instructor_subscription_tracks_select_own" on public.instructor_subscription_tracks
  for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.instructor_subscriptions s
      where s.id = subscription_id and s.user_id = (select auth.uid())
    )
  );

drop policy if exists "instructor_classes_select" on public.instructor_classes;
create policy "instructor_classes_select" on public.instructor_classes
  for select to authenticated
  using (
    public.is_admin()
    or instructor_id = (select auth.uid())
    or exists (
      select 1 from public.instructor_class_members m
      where m.class_id = id and m.user_id = (select auth.uid())
        and m.status = 'active'
    )
  );

drop policy if exists "instructor_class_members_select" on public.instructor_class_members;
create policy "instructor_class_members_select" on public.instructor_class_members
  for select to authenticated
  using (
    public.is_admin()
    or user_id = (select auth.uid())
    or exists (
      select 1 from public.instructor_classes c
      where c.id = class_id and c.instructor_id = (select auth.uid())
    )
  );

drop policy if exists "instructor_class_invites_select" on public.instructor_class_invites;
create policy "instructor_class_invites_select" on public.instructor_class_invites
  for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.instructor_classes c
      where c.id = class_id and c.instructor_id = (select auth.uid())
    )
  );

drop policy if exists "live_sessions_select" on public.live_sessions;
create policy "live_sessions_select" on public.live_sessions
  for select to authenticated
  using (
    public.is_admin()
    or instructor_id = (select auth.uid())
    or exists (
      select 1 from public.instructor_class_members m
      where m.class_id = live_sessions.class_id
        and m.user_id = (select auth.uid())
        and m.status = 'active'
    )
  );

drop policy if exists "live_session_attendance_select" on public.live_session_attendance;
create policy "live_session_attendance_select" on public.live_session_attendance
  for select to authenticated
  using (
    public.is_admin()
    or user_id = (select auth.uid())
    or exists (
      select 1 from public.live_sessions s
      where s.id = session_id and s.instructor_id = (select auth.uid())
    )
  );

-- Défense en profondeur : aucune écriture client sur le commercial et les classes.
revoke all on table public.instructor_plans from anon, authenticated;
grant select on table public.instructor_plans to anon, authenticated;

revoke all on table public.instructor_subscriptions from anon, authenticated;
grant select on table public.instructor_subscriptions to authenticated;

revoke all on table public.instructor_subscription_tracks from anon, authenticated;
grant select on table public.instructor_subscription_tracks to authenticated;

revoke all on table public.instructor_classes from anon, authenticated;
grant select on table public.instructor_classes to authenticated;

revoke all on table public.instructor_class_members from anon, authenticated;
grant select on table public.instructor_class_members to authenticated;

revoke all on table public.instructor_class_invites from anon, authenticated;
grant select on table public.instructor_class_invites to authenticated;

revoke all on table public.live_sessions from anon, authenticated;
grant select on table public.live_sessions to authenticated;

revoke all on table public.live_session_attendance from anon, authenticated;
grant select on table public.live_session_attendance to authenticated;
