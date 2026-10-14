-- easyTech — relances automatiques : la plateforme va chercher l'apprenant.
--
-- Un apprenant qui ouvre un parcours puis disparaît ne revient pas tout seul.
-- Trois horloges le rappellent : la leçon laissée en cours (3 jours), le niveau
-- suivant à goûter (dès qu'un certificat est en poche), et le parcours d'à côté
-- quand le premier est fini. S'y ajoutent le rappel d'un compte qui s'est éteint
-- et l'annonce, à toute la base, de chaque parcours ajouté par l'admin.
--
-- Comme pour les notifications de classe, la file ne stocke pas le contenu : une
-- ligne dit « tel e-mail dû, à telle heure, à propos de tel parcours ». Le texte
-- se compose à l'envoi, à partir de la progression réelle — une relance mise en
-- file puis réglée entre-temps part réglée.
--
-- Deux garde-fous, parce que le marketing massif détruit la réputation d'envoi :
--   * un apprenant ne reçoit pas deux e-mails automatiques en moins de cinq jours ;
--   * le volume du jour est borné (clé `daily_cap`), l'administrateur le baisse
--     s'il change de fournisseur.
-- Et une adresse désinscrite n'est jamais remise en file : `opted_out_at`.
--
-- Idempotent, réapplicable.

-- ---------------------------------------------------------------------------
-- Boîte de sortie des relances
-- ---------------------------------------------------------------------------

create table if not exists public.marketing_notices (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('resume', 'level_up', 'explore', 'winback', 'new_track')),
  user_id uuid references public.profiles (id) on delete cascade,
  track_id text references public.tracks (id) on delete cascade,
  recipient text not null,
  dedup_key text not null,
  scheduled_at timestamptz not null default now(),
  sent_at timestamptz,
  attempts integer not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  constraint marketing_notices_dedup unique (dedup_key)
);

comment on column public.marketing_notices.dedup_key is
  'Clé anti-doublon : une règle rejouée le même jour ne part jamais deux fois à la même adresse.';

create index if not exists marketing_notices_due
  on public.marketing_notices (sent_at, scheduled_at);
create index if not exists marketing_notices_recipient
  on public.marketing_notices (recipient, coalesce(sent_at, scheduled_at) desc);

-- Seul le serveur écrit ici : aucune politique RLS, donc ni lecture ni écriture
-- depuis le navigateur, même authentifié.
alter table public.marketing_notices enable row level security;

-- ---------------------------------------------------------------------------
-- Consentement, par adresse
-- ---------------------------------------------------------------------------
-- Le lien de désinscription porte un jeton, pas une session : l'apprenant doit
-- pouvoir se retirer d'un e-mail reçu il y a trois semaines, même sans compte
-- connecté. Une ligne sans `opted_out_at` = encore abonné (la ligne naît au
-- premier envoi).

create table if not exists public.marketing_subscriptions (
  email text primary key,
  token text not null unique default substr(md5(random()::text || clock_timestamp()::text), 1, 24),
  opted_out_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.marketing_subscriptions enable row level security;

-- ---------------------------------------------------------------------------
-- Réglages persistés et repère des annonces
-- ---------------------------------------------------------------------------
-- `new_track_watermark` empêche la catastrophe du premier lancement : sans repère,
-- chacun des parcours déjà publiés du catalogue serait annoncé à toute la base
-- d'un seul coup. Il ne pointe que vers l'avant.

create table if not exists public.marketing_state (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

alter table public.marketing_state enable row level security;

insert into public.marketing_state (key, value)
values
  ('daily_cap', '220'),
  ('new_track_watermark',
   coalesce((select extract(epoch from max(created_at))::text from public.tracks), '0'))
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Ce qui s'achète après un certificat
-- ---------------------------------------------------------------------------

create or replace function public.next_level(p_level text)
returns text
language sql
immutable
as $$
  select case p_level
    when 'debutant' then 'intermediaire'
    when 'intermediaire' then 'avance'
    when 'avance' then 'projet'
    else null
  end;
$$;

-- ---------------------------------------------------------------------------
-- Les adresses joignables, avec leurs deux repos obligatoires
-- ---------------------------------------------------------------------------
-- Confirmée côté Auth (une adresse jamais validée rebondirait et plomberait la
-- réputation d'envoi), non désinscrite, silencieuse depuis cinq jours, et sans
-- relance déjà en attente : une file qui grossirait d'un coup de dix messages
-- pour la même personne partait en dix e-mails le même soir.

create or replace function public.marketing_recipients(p_now timestamptz default now())
returns table (user_id uuid, email text)
language sql
security definer
set search_path = public, pg_temp
as $$
  select pr.id, lower(pr.email)
  from public.profiles pr
  join auth.users au on au.id = pr.id
  where pr.email is not null and pr.email <> ''
    and au.email_confirmed_at is not null
    and not exists (
      select 1 from public.marketing_subscriptions s
      where s.email = lower(pr.email) and s.opted_out_at is not null)
    and not exists (
      select 1 from public.marketing_notices m
      where m.recipient = lower(pr.email)
        and coalesce(m.sent_at, m.scheduled_at) > p_now - interval '5 days')
    and not exists (
      select 1 from public.marketing_notices q
      where q.recipient = lower(pr.email) and q.sent_at is null);
$$;

revoke execute on function public.marketing_recipients(timestamptz) from public, anon, authenticated;
grant execute on function public.marketing_recipients(timestamptz) to service_role;

-- ---------------------------------------------------------------------------
-- Alimentation de la file
-- ---------------------------------------------------------------------------
-- Une passe d'horloge pose toutes les lignes dues. Chaque règle est autonome :
-- ses clés anti-doublon portent la fenêtre de temps qui l'autorise à repartir.

create or replace function public.marketing_queue_sync(p_now timestamptz default now())
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  inserted integer := 0;
  added integer := 0;
  wm double precision;
  newest timestamptz;
begin
  -- 1. Reprise : parcours ouvert, plus rien depuis trois jours, des chapitres
  --    encore à faire. La relance revient une fois par semaine tant que le
  --    parcours traîne, puis s'arrête à trente jours — au-delà, « winback »
  --    prend le relais avec un tout autre message.
  insert into public.marketing_notices (kind, user_id, track_id, recipient, dedup_key, scheduled_at)
  select distinct on (d.email)
         'resume', a.user_id, a.track_id, d.email,
         'resume|' || a.track_id || '|' || to_char(date_trunc('week', p_now), 'IYYY-IW') || '|' || d.email,
         p_now
  from (
    select cp.user_id, cp.track_id,
           max(cp.updated_at) as dernier,
           count(*) filter (where cp.status = 'completed') as faits
    from public.chapter_progress cp
    group by cp.user_id, cp.track_id
  ) a
  join public.marketing_recipients(p_now) d on d.user_id = a.user_id
  join (
    select c.track_id, count(*) as total
    from public.chapters c
    where c.published
    group by c.track_id
  ) f on f.track_id = a.track_id
  where a.dernier < p_now - interval '3 days'
    and a.dernier > p_now - interval '30 days'
    and a.faits < f.total
  -- Un seul parcours relancé par passe : celui laissé le plus récemment.
  order by d.email, a.dernier desc
  on conflict (dedup_key) do nothing;
  get diagnostics inserted = row_count;

  -- 2. Goût du niveau supérieur : certificat de niveau en poche, le niveau
  --    d'après existe dans la même catégorie et n'est pas encore acheté.
  insert into public.marketing_notices (kind, user_id, track_id, recipient, dedup_key, scheduled_at)
  select distinct on (d.email)
         'level_up', c.user_id, c.track_id, d.email,
         'levelup|' || c.user_id || '|' || c.track_id || '|' || c.level,
         p_now
  from public.certificates c
  join public.marketing_recipients(p_now) d on d.user_id = c.user_id
  join public.tracks t on t.id = c.track_id
  join public.categories cat on cat.id = t.category_id
  where c.level in ('debutant', 'intermediaire', 'avance')
    and public.next_level(c.level) is not null
    and public.next_level(c.level) = any (cat.levels)
    and not exists (
      select 1 from public.purchases p
      where p.user_id = c.user_id
        and p.category_id = t.category_id
        and p.level = public.next_level(c.level)
        and p.status = 'paid')
  -- Le certificat le plus récent prime : c'est lui qui donne envie de la suite.
  order by d.email, c.issued_at desc
  on conflict (dedup_key) do nothing;
  get diagnostics added = row_count;
  inserted := inserted + added;

  -- 3. Parcours terminé, mais un seul : proposer la suite. C'est l'apprenant le
  --    plus facile à reprendre — il a déjà tenu jusqu'au certificat.
  insert into public.marketing_notices (kind, user_id, track_id, recipient, dedup_key, scheduled_at)
  select 'explore', d.user_id, null, d.email,
         'explore|' || to_char(date_trunc('month', p_now), 'IYYY-MM') || '|' || d.email,
         p_now
  from public.marketing_recipients(p_now) d
  where exists (
    select 1 from public.certificates c
    where c.user_id = d.user_id and c.level = 'parcours')
    and coalesce((
      select count(distinct cp.track_id)
      from public.chapter_progress cp
      where cp.user_id = d.user_id), 0) < 2
  on conflict (dedup_key) do nothing;
  get diagnostics added = row_count;
  inserted := inserted + added;

  -- 4. Compte endormi : payé un jour, plus rien depuis trois semaines. Une fois
  --    par mois, et sans parler d'achat — il parle de la leçon laissée en cours.
  insert into public.marketing_notices (kind, user_id, track_id, recipient, dedup_key, scheduled_at)
  select 'winback', d.user_id, null, d.email,
         'winback|' || to_char(date_trunc('month', p_now), 'IYYY-MM') || '|' || d.email,
         p_now
  from public.marketing_recipients(p_now) d
  join (
    select cp.user_id, max(cp.updated_at) as dernier
    from public.chapter_progress cp
    group by cp.user_id
  ) a on a.user_id = d.user_id
  where a.dernier < p_now - interval '21 days'
    and a.dernier > p_now - interval '6 months'
    and exists (
      select 1 from public.purchases p
      where p.user_id = d.user_id and p.status = 'paid')
  on conflict (dedup_key) do nothing;
  get diagnostics added = row_count;
  inserted := inserted + added;

  -- 5. Nouveau parcours : l'annonce part chez tout le monde, sans exception,
  --    dans la seule limite du consentement. Le repère n'avance jamais en
  --    arrière, donc un parcours n'est annoncé qu'une fois.
  select coalesce(nullif(value, '')::double precision, extract(epoch from p_now - interval '1 day'))
  into wm
  from public.marketing_state
  where key = 'new_track_watermark';

  insert into public.marketing_notices (kind, user_id, track_id, recipient, dedup_key, scheduled_at)
  select distinct on (d.email)
         'new_track', d.user_id, n.id, d.email,
         'newtrack|' || n.id || '|' || d.email,
         p_now
  from (
    select t.id, t.created_at
    from public.tracks t
    where t.published
      and t.created_at > to_timestamp(wm)
  ) n
  cross join public.marketing_recipients(p_now) d
  -- Plusieurs parcours ajoutés d'un coup ? Le plus récent seulement, les autres
  -- suivront aux passes d'horloge suivantes.
  order by d.email, n.created_at desc
  on conflict (dedup_key) do nothing;
  get diagnostics added = row_count;
  inserted := inserted + added;

  select max(t.created_at) into newest from public.tracks t where t.published;
  if newest is not null and extract(epoch from newest) > coalesce(wm, 0) then
    insert into public.marketing_state (key, value, updated_at)
    values ('new_track_watermark', extract(epoch from newest)::text, p_now)
    on conflict (key) do update set value = excluded.value, updated_at = excluded.updated_at;
  end if;

  return inserted;
end;
$$;

comment on function public.marketing_queue_sync(timestamptz) is
  'Pose en file les relances dues. Idempotent grâce aux clés anti-doublon.';

revoke execute on function public.marketing_queue_sync(timestamptz) from public, anon, authenticated;
revoke execute on function public.next_level(text) from public;
grant execute on function public.marketing_queue_sync(timestamptz) to service_role;
