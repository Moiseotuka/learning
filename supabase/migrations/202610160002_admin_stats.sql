-- 2026-10-16 : agrégations du tableau de bord admin.
--
-- Pourquoi des fonctions SQL et pas des `select` depuis l'application : le tableau de bord doit
-- compter des milliers de lignes de visites sans les faire voyager jusqu'au serveur Node. Le
-- regroupement se fait donc dans la base, une seule fois par chargement de page.
--
-- Sécurité : ces fonctions sont `security definer` et exécutées par le propriétaire de la table.
-- Elles sont retirées à `anon` et `authenticated` : seul `service_role`, côté serveur, peut les
-- appeler. Un apprenant qui devinerait leur nom obtient une erreur 403, jamais le trafic du site.
--
-- Rollback : drop function public.<nom>(...) pour chacune des six fonctions créées ici.

create or replace function public.admin_visites_par_source(depuis timestamptz)
returns table (source text, medium text, vues bigint, visiteurs bigint)
language sql
stable
security definer
set search_path = public
as $$
  select
    v.source,
    coalesce(nullif(v.medium, ''), 'autre') as medium,
    count(*) as vues,
    count(distinct v.visitor_id) as visiteurs
  from public.site_visits v
  where v.seen_at >= depuis
  group by v.source, medium
  order by visiteurs desc, vues desc;
$$;

create or replace function public.admin_visites_par_jour(depuis timestamptz)
returns table (jour date, vues bigint, visiteurs bigint, inscrits bigint)
language sql
stable
security definer
set search_path = public
as $$
  select
    d.jour::date as jour,
    coalesce(v.vues, 0) as vues,
    coalesce(v.visiteurs, 0) as visiteurs,
    coalesce(p.inscrits, 0) as inscrits
  from (
    select (date_trunc('day', depuis) + make_interval(days => s))::date as jour
    from generate_series(0, ceil(extract(epoch from (now() - depuis)) / 86400)::int) as s
  ) d
  left join (
    select date_trunc('day', seen_at)::date as jour,
           count(*) as vues,
           count(distinct visitor_id) as visiteurs
    from public.site_visits
    where seen_at >= depuis
    group by 1
  ) v on v.jour = d.jour
  left join (
    select date_trunc('day', created_at)::date as jour, count(*) as inscrits
    from public.profiles
    where created_at >= depuis
    group by 1
  ) p on p.jour = d.jour
  order by d.jour;
$$;

create or replace function public.admin_pages_visitees(depuis timestamptz)
returns table (path text, vues bigint, visiteurs bigint)
language sql
stable
security definer
set search_path = public
as $$
  select v.path, count(*) as vues, count(distinct v.visitor_id) as visiteurs
  from public.site_visits v
  where v.seen_at >= depuis
  group by v.path
  order by vues desc
  limit 20;
$$;

create or replace function public.admin_visites_par_pays(depuis timestamptz)
returns table (pays text, visiteurs bigint)
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(nullif(v.country, ''), 'inconnu') as pays,
         count(distinct v.visitor_id) as visiteurs
  from public.site_visits v
  where v.seen_at >= depuis
  group by pays
  order by visiteurs desc
  limit 12;
$$;

-- Les achats et les abonnements formateur sont comptés séparément : ils n'ont ni le même
-- montant, ni le même cycle de vie, et l'admin veut voir les deux sans les additionner.
create or replace function public.admin_achats()
returns table (statut text, nombre bigint, montant bigint, devise text)
language sql
stable
security definer
set search_path = public
as $$
  select p.status,
         count(*) as nombre,
         coalesce(sum(p.amount_usd), 0) as montant,
         max(p.currency) as devise
  from public.purchases p
  group by p.status
  order by nombre desc;
$$;

create or replace function public.admin_abonnements_formateur()
returns table (statut text, nombre bigint, montant bigint)
language sql
stable
security definer
set search_path = public
as $$
  select s.status,
         count(*) as nombre,
         coalesce(sum(s.amount_fc), 0) as montant
  from public.instructor_subscriptions s
  group by s.status
  order by nombre desc;
$$;

alter function public.admin_visites_par_source(timestamptz) owner to postgres;
alter function public.admin_visites_par_jour(timestamptz) owner to postgres;
alter function public.admin_pages_visitees(timestamptz) owner to postgres;
alter function public.admin_visites_par_pays(timestamptz) owner to postgres;
alter function public.admin_achats() owner to postgres;
alter function public.admin_abonnements_formateur() owner to postgres;

revoke all on function
  public.admin_visites_par_source(timestamptz),
  public.admin_visites_par_jour(timestamptz),
  public.admin_pages_visitees(timestamptz),
  public.admin_visites_par_pays(timestamptz),
  public.admin_achats(),
  public.admin_abonnements_formateur()
from public, anon, authenticated;

grant execute on function
  public.admin_visites_par_source(timestamptz),
  public.admin_visites_par_jour(timestamptz),
  public.admin_pages_visitees(timestamptz),
  public.admin_visites_par_pays(timestamptz),
  public.admin_achats(),
  public.admin_abonnements_formateur()
to service_role;
