-- 2026-10-16 : deux agrégations de plus pour le tableau de bord.
--
-- `admin_visites_par_appareil` répond à une question d'exploitation : est-ce que le trafic vient
-- surtout de téléphones ? Le site doit rester léger là-dessus, donc l'admin a besoin du chiffre
-- réel, et « réel » veut dire distinct : on compte des visiteurs différents, pas des pages vues.
--
-- `admin_achats_par_categorie` évite de ramener 200 lignes de transactions pour les sommer dans
-- Node : le total payé par domaine et par niveau est calculé dans la base.
--
-- Sécurité : mêmes règles que 202610160002 — `security definer`, propriétaire de la table,
-- exécution réservée à `service_role`. Aucune de ces fonctions n'est appelable depuis le navigateur.
--
-- Rollback : drop function public.admin_visites_par_appareil(timestamptz);
--            drop function public.admin_achats_par_categorie();

create or replace function public.admin_visites_par_appareil(depuis timestamptz)
returns table (appareil text, vues bigint, visiteurs bigint)
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(nullif(v.device, ''), 'inconnu') as appareil,
         count(*) as vues,
         count(distinct v.visitor_id) as visiteurs
  from public.site_visits v
  where v.seen_at >= depuis
  group by appareil
  order by visiteurs desc;
$$;

create or replace function public.admin_achats_par_categorie()
returns table (categorie text, niveau text, payes bigint, en_attente bigint, montant bigint, devise text)
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(c.name, 'parcours supprimé') as categorie,
         coalesce(nullif(p.level, ''), '—') as niveau,
         count(*) filter (where p.status in ('paid', 'success', 'completed')) as payes,
         count(*) filter (where p.status not in ('paid', 'success', 'completed')) as en_attente,
         coalesce(sum(p.amount_usd) filter (where p.status in ('paid', 'success', 'completed')), 0) as montant,
         max(p.currency) as devise
  from public.purchases p
  left join public.categories c on c.id = p.category_id
  group by categorie, niveau
  order by montant desc, payes desc;
$$;

alter function public.admin_visites_par_appareil(timestamptz) owner to postgres;
alter function public.admin_achats_par_categorie() owner to postgres;

revoke all on function
  public.admin_visites_par_appareil(timestamptz),
  public.admin_achats_par_categorie()
from public, anon, authenticated;

grant execute on function
  public.admin_visites_par_appareil(timestamptz),
  public.admin_achats_par_categorie()
to service_role;
