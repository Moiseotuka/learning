-- 2026-10-23 : suivi des apprenants pour l'administration.
--
-- Pourquoi ici et pas dans `lireComptes()` : la page des comptes doit répondre à trois questions
-- — qui a un certificat, où en est chacun, et depuis combien de temps il n'a plus rien fait. Y
-- répondre depuis l'application obligerait à sortir toutes les lignes de progression, puis à
-- paginer à 1 000 lignes comme le fait PostgREST : les compteurs étaient déjà annoncés comme des
-- « minimums » sur la page. Le regroupement se fait donc dans la base, en une passe.
--
-- Sécurité : `security definer`, propriétaire = la table, exécution retirée à `public`, `anon` et
-- `authenticated`. Seul `service_role`, côté serveur, peut les appeler.
--
-- Rollback : drop function public.admin_suivi_comptes(); drop function public.admin_certificats();

create or replace function public.admin_suivi_comptes()
returns table (
  id uuid,
  nom text,
  email text,
  role text,
  inscrit timestamptz,
  chapitres_ouverts bigint,
  chapitres_reussis bigint,
  achats_payes bigint,
  derniere_activite timestamptz,
  niveau text,
  formation text,
  certificats bigint,
  dernier_certificat timestamptz,
  parcours_termine boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    coalesce(nullif(btrim(p.full_name), ''), p.email, '—') as nom,
    p.email,
    coalesce(p.role, 'learner') as role,
    p.created_at as inscrit,
    coalesce(prog.ouverts, 0) as chapitres_ouverts,
    coalesce(prog.reussis, 0) as chapitres_reussis,
    coalesce(ach.achats, 0) as achats_payes,
    prog.derniere as derniere_activite,
    -- Le « niveau courant » est le chapitre en cours le plus récent ; à défaut, le dernier
    -- réussi. Un apprenant qui a tout validé affiche donc son dernier chapitre fait plutôt
    -- qu'une ligne vide.
    cour.niveau,
    cour.formation,
    coalesce(cert.nombre, 0) as certificats,
    cert.dernier as dernier_certificat,
    coalesce(cert.termine, false) as parcours_termine
  from public.profiles p
  left join lateral (
    select
      count(*) as ouverts,
      count(*) filter (where cp.status = 'completed') as reussis,
      max(cp.updated_at) as derniere
    from public.chapter_progress cp
    where cp.user_id = p.id
  ) prog on true
  left join lateral (
    -- Aucun lien étranger n'existe entre purchases.user_id et profiles : le comptage se fait
    -- à la main, avec les mêmes statuts encaissés que le tableau de bord.
    select count(*) as achats
    from public.purchases pu
    where pu.user_id = p.id
      and pu.status in ('paid', 'success', 'completed')
  ) ach on true
  left join lateral (
    select c.level as niveau, t.title as formation
    from public.chapter_progress cp
    join public.chapters c on c.id = cp.chapter_id
    join public.tracks t on t.id = cp.track_id
    where cp.user_id = p.id
    order by (cp.status = 'completed') asc, cp.updated_at desc
    limit 1
  ) cour on true
  left join lateral (
    select
      count(*) as nombre,
      max(ce.issued_at) as dernier,
      bool_or(ce.level = 'parcours') as termine
    from public.certificates ce
    where ce.user_id = p.id
  ) cert on true
  order by p.created_at desc;
$$;


create or replace function public.admin_certificats()
returns table (
  id uuid,
  code text,
  titulaire text,
  email text,
  niveau text,
  formation text,
  intitule text,
  delivre timestamptz,
  formateur text,
  academie text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ce.id,
    ce.code,
    coalesce(nullif(btrim(p.full_name), ''), ce.full_name, '—') as titulaire,
    p.email,
    ce.level as niveau,
    ce.track_title as formation,
    ce.title as intitule,
    ce.issued_at as delivre,
    nullif(btrim(coalesce(ce.instructor_name, '')), '') as formateur,
    nullif(btrim(coalesce(ce.academy, '')), '') as academie
  from public.certificates ce
  left join public.profiles p on p.id = ce.user_id
  order by ce.issued_at desc;
$$;


alter function public.admin_suivi_comptes() owner to postgres;
alter function public.admin_certificats() owner to postgres;

revoke all on function
  public.admin_suivi_comptes(),
  public.admin_certificats()
from public, anon, authenticated;

grant execute on function
  public.admin_suivi_comptes(),
  public.admin_certificats()
to service_role;
