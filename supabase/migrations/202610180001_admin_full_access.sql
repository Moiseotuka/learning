-- ===========================================================================
-- Compte administrateur : accès complet sans achat, pour tester la plateforme
-- ===========================================================================
-- Règle unique : un profil `role = 'admin'` se voit accorder TOUS les domaines
-- publiés. Elle est posée dans `granted_category_ids()`, la fonction que les
-- deux chemins d'accès consultent déjà (la lecture des parcours et les actions
-- serveur qui verrouillent leçon, quiz et examen). Corriger un seul endroit
-- évite qu'un chemin laisse passer l'admin pendant que l'autre le bloque.
--
-- Ce n'est pas une remise commerciale : les achats restent intacts, le tarif
-- affiché ne change pas, et un admin qui crée une commande paie comme les
-- autres. Seule la porte s'ouvre.
-- ===========================================================================

-- Rôle d'un utilisateur donné. La version existante, is_admin(), ne sait
-- répondre que pour auth.uid() ; celle-ci prend un identifiant en paramètre,
-- ce qu'il faut dans une fonction appelée avec p_user.
create or replace function public.is_admin_user(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = p_user
      and role = 'admin'
  );
$$;

revoke all on function public.is_admin_user(uuid) from public;
grant execute on function public.is_admin_user(uuid) to anon, authenticated, service_role;

-- Droits accordés hors achat individuel : abonnement de formateur, place de
-- classe, et désormais tous les domaines pour un administrateur.
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
  ),
  -- L'admin teste la plateforme : il doit pouvoir ouvrir n'importe quelle
  -- leçon, n'importe quel niveau, sans simuler d'achat.
  admin_all as (
    select c.id as category_id
    from public.categories c
    where public.is_admin_user(p_user)
  ),
  -- Une classe ouverte par un administrateur n'a pas d'abonnement payant derrière
  -- elle : ses élèves entrent néanmoins en cours, sinon la classe de test serait
  -- vide et le parcours « formateur » impossible à éprouver de bout en bout.
  admin_class as (
    select k.category_id
    from public.instructor_class_members m
    join public.instructor_classes c on c.id = m.class_id
    join public.tracks k on k.id = c.track_id
    where m.user_id = p_user
      and m.status = 'active'
      and c.status = 'active'
      and public.is_admin_user(c.instructor_id)
  )
  select category_id from taught
  union
  select category_id from seated where user_id = p_user and seat <= seats_limit
  union
  select category_id from admin_all
  union
  select category_id from admin_class;
$$;

revoke all on function public.granted_category_ids(uuid) from public;
grant execute on function public.granted_category_ids(uuid) to anon, authenticated, service_role;

-- has_level_access() lit granted_category_ids(auth.uid()) : elle hérite de la
-- règle sans changement. Redéfinée ici seulement pour garder la documentation
-- du serveur alignée sur le comportement réel.
create or replace function public.has_level_access(p_category_id text, p_level text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_level = 'debutant'
    or public.is_admin()
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
