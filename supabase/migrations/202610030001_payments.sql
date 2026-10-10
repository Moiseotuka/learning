-- easyLearn — paiement par niveau pour tous les domaines
-- Grille tarifaire : une ligne (catégorie, niveau) = un prix en USD.
-- Règle métier : le niveau « débutant » est gratuit pour tous les domaines ;
-- intermédiaire, avancé et projet sont payants (prix saisis dans le back-office).
-- purchases = droits d'achat par (utilisateur, catégorie, niveau).
-- payment_events = déduplication idempotente des webhooks (voir README :
-- HMAC-SHA256 sur le corps brut, tolérance 5 min, déduplication).
-- Écritures réservées au serveur (service role) : pas de policy insert/update
-- pour authenticated, contrairement à chapter_progress.
-- Idempotent : peut être réappliqué sans effet de bord.

create table if not exists public.category_level_prices (
  category_id text not null references public.categories (id) on delete cascade,
  level text not null check (level in ('debutant', 'intermediaire', 'avance', 'projet')),
  price_usd integer not null check (price_usd >= 0),
  published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (category_id, level)
);

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category_id text not null references public.categories (id) on delete cascade,
  level text not null check (level in ('debutant', 'intermediaire', 'avance', 'projet')),
  amount_usd integer not null check (amount_usd >= 0),
  currency text not null default 'USD',
  provider text not null default 'mock' check (provider in ('mock', 'nyole')),
  provider_reference text,
  status text not null default 'pending' check (status in ('pending', 'paid', 'refunded', 'failed')),
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, category_id, level)
);

create table if not exists public.payment_events (
  event_id text primary key,
  provider text not null check (provider in ('mock', 'nyole')),
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists purchases_user_category_idx
  on public.purchases (user_id, category_id);

drop trigger if exists category_level_prices_set_updated_at on public.category_level_prices;
create trigger category_level_prices_set_updated_at
  before update on public.category_level_prices
  for each row execute function public.set_updated_at();

drop trigger if exists purchases_set_updated_at on public.purchases;
create trigger purchases_set_updated_at
  before update on public.purchases
  for each row execute function public.set_updated_at();

-- Row Level Security ---------------------------------------------------------

alter table public.category_level_prices enable row level security;
alter table public.purchases enable row level security;
alter table public.payment_events enable row level security;

drop policy if exists "prices_select" on public.category_level_prices;
create policy "prices_select" on public.category_level_prices
  for select
  using (published = true or public.is_admin());

drop policy if exists "purchases_select_own" on public.purchases;
create policy "purchases_select_own" on public.purchases
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

-- Défense en profondeur : aucune écriture client sur le commerce.
revoke all on table public.category_level_prices from anon, authenticated;
grant select on table public.category_level_prices to anon, authenticated;
revoke all on table public.purchases from anon, authenticated;
grant select on table public.purchases to authenticated;
revoke all on table public.payment_events from anon, authenticated;

-- Accès par niveau -------------------------------------------------------------
-- Retourne vrai si l'utilisateur courant a le droit d'ouvrir le niveau
-- « p_level » du domaine « p_category_id » : niveau débutant toujours
-- gratuit, sinon un achat payé correspondant est exigé.
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
    );
$$;

revoke all on function public.has_level_access(text, text) from public;
grant execute on function public.has_level_access(text, text) to anon, authenticated;
