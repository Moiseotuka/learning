-- 2026-10-16 : la journée du tableau de bord est celle de Kinshasa, et plus une journée de demain.
--
-- Deux défauts corrigés ici :
-- 1. `generate_series(0, ceil((now() - depuis)/86400))` produisait 31 lignes pour une période de
--    30 jours : la courbe se terminait sur une journée vide, celle de demain.
-- 2. Le regroupement était fait en UTC. À Kinshasa (UTC+2), la journée basculait à 02 h 00 du
--    matin : les visiteurs arrivés entre minuit et deux heures étaient comptés sur la veille.
--
-- Les jours sont donc calculés en date calendaire « Africa/Lubumbashi », bornés au jour courant.
-- L'identifiant de visiteur tourne sur la même date (voir src/lib/analytics/visite.ts), sinon un
-- même visiteur serait compté deux fois le même jour affiché.
--
-- Rollback : re-exécuter le bloc `admin_visites_par_jour` de 202610160002_admin_stats.sql.

create or replace function public.admin_visites_par_jour(depuis timestamptz)
returns table (jour date, vues bigint, visiteurs bigint, inscrits bigint)
language sql
stable
security definer
set search_path = public
as $$
  select
    d.jour,
    coalesce(v.vues, 0) as vues,
    coalesce(v.visiteurs, 0) as visiteurs,
    coalesce(p.inscrits, 0) as inscrits
  from (
    select (select (depuis at time zone 'Africa/Lubumbashi')::date) + s as jour
    from generate_series(
      0,
      greatest(
        0,
        ((select (now() at time zone 'Africa/Lubumbashi')::date)
         - (select (depuis at time zone 'Africa/Lubumbashi')::date))::int
      )
    ) as s
  ) d
  left join (
    select (seen_at at time zone 'Africa/Lubumbashi')::date as jour,
           count(*) as vues,
           count(distinct visitor_id) as visiteurs
    from public.site_visits
    where seen_at >= depuis
    group by 1
  ) v on v.jour = d.jour
  left join (
    select (created_at at time zone 'Africa/Lubumbashi')::date as jour, count(*) as inscrits
    from public.profiles
    where created_at >= depuis
    group by 1
  ) p on p.jour = d.jour
  order by d.jour;
$$;

alter function public.admin_visites_par_jour(timestamptz) owner to postgres;

revoke all on function public.admin_visites_par_jour(timestamptz) from public, anon, authenticated;
grant execute on function public.admin_visites_par_jour(timestamptz) to service_role;
