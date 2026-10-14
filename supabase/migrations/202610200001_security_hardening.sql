-- ===========================================================================
-- Durcissement : un jeton d'apprenant ne doit plus pouvoir écrire ni lire
-- plus que ce que l'interface lui permet
-- ===========================================================================
-- Trois exploits ont été reproduits en production avec un vrai compte
-- apprenant, sans passer par l'interface, en appelant PostgREST directement :
--
--   1. `PATCH /rest/v1/profiles?id=eq.<soi> {"role":"admin"}` → compte
--      administrateur. La politique `profiles_update_own` autorise n'importe
--      quelle colonne de sa propre ligne, y compris `role`.
--   2. `POST /rest/v1/chapter_progress` avec `videos_watched`, `best_score`,
--      `status` → leçon déclarée vue et niveau réussi sans visionner. La règle
--      de visionnage stricte était donc contournable sans aucune interface.
--   3. `GET /rest/v1/chapters?select=videos,content` → leçons et cours écrits
--      des niveaux non achetés. La politique `chapters_select` ne filtre que
--      les lignes (`published`), jamais les colonnes.
--
-- Le remède est en deux couches. D'abord les privilèges de colonnes : le rôle
-- `authenticated` ne peut plus toucher les colonnes sensibles, et l'erreur est
-- renvoyée par Postgres, pas par notre code. Ensuite les écritures légitimes
-- de ces colonnes passent par la clé de service (`service_role`), côté
-- serveur, là où le contrôle d'accès du niveau est déjà fait.
--
-- Ce qui reste inchangé : les politiques RLS existantes, les tables que
-- l'interface d'administration écrit encore avec le client de session
-- (`categories`, `category_level_prices`, `instructor_*`), et la visibilité
-- des fiches du catalogue — titres et résumés restent lisibles pour montrer le
-- verrou et déclencher l'achat.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 0. Privilèges de schéma que personne n'utilise et qui n'ont rien à faire là
-- ---------------------------------------------------------------------------
-- TRUNCATE ignore totalement la RLS : un seul privilège accordé suffirait à
-- vider une table. REFERENCES et TRIGGER ne servent à aucune requête de
-- l'application.
revoke truncate, references, trigger
  on all tables in schema public
  from anon, authenticated;

-- L'application ne supprime jamais de profil, et n'insère pas non plus : la
-- ligne est créée par le déclencheur d'inscription.
revoke insert, delete on public.profiles from anon, authenticated;
revoke delete on public.chapter_progress from anon, authenticated;

-- Pas d'écriture directe dans les journaux de paiement ni dans les certificats
-- depuis un rôle client : tout passe par le serveur.
revoke insert, update, delete on public.certificates from anon, authenticated;
revoke insert, update, delete on public.payment_events from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 1. profiles : plus personne ne se promeut administrateur
-- ---------------------------------------------------------------------------
-- Le contrôle est double. La colonne n'est plus inscriptible par le rôle
-- client, et un déclencheur réécrit la valeur même si un droit venait à être
-- élargi plus tard (ou si une requête passait par un autre chemin).
create or replace function public.guard_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Le serveur (clé de service) et la console SQL gèrent les rôles ; une
  -- fonction `security definer` rend CURRENT_USER trompeur, c'est SESSION_USER
  -- qui désigne l'appelant réel de la requête.
  if session_user::text in
    ('service_role', 'postgres', 'supabase_admin', 'supabase_auth_admin') then
    return new;
  end if;

  -- Un administrateur légitime peut promouvoir ou rétrograder un compte.
  if public.is_admin() then
    return new;
  end if;

  if new.role is distinct from old.role then
    raise exception 'profils.role ne peut pas être modifié par ce compte';
  end if;

  return new;
end;
$$;

revoke all on function public.guard_profile_role() from public;

drop trigger if exists profiles_guard_role on public.profiles;
create trigger profiles_guard_role
  before update on public.profiles
  for each row execute function public.guard_profile_role();

-- Le profil d'un nouveau compte est `learner` : personne ne peut naître
-- administrateur, pas même par un INSERT que nous avons pourtant révoqué.
create or replace function public.guard_profile_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if session_user::text in
    ('service_role', 'postgres', 'supabase_admin', 'supabase_auth_admin')
    or public.is_admin() then
    return new;
  end if;

  new.role := 'learner';
  return new;
end;
$$;

revoke all on function public.guard_profile_insert() from public;

drop trigger if exists profiles_guard_insert on public.profiles;
create trigger profiles_guard_insert
  before insert on public.profiles
  for each row execute function public.guard_profile_insert();

-- Colonnes que l'apprenant peut éditer sur sa propre ligne. `email` en est
-- absent volontairement : l'adresse se change via l'authentification, et elle
-- sert d'identifiant aux invitations de classe comme aux certificats — un
-- apprenant qui l'écrirait directement pourrait se faire passer pour un autre.
revoke update on public.profiles from authenticated;
grant update (full_name, phone, avatar_url, updated_at)
  on public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- 2. chapter_progress : la preuve de visionnage devient serveur
-- ---------------------------------------------------------------------------
-- Les battements de montre étaient stockés dans `resume`, colonne que le
-- client écrit lui-même : il suffisait d'y poser soi-même un faux
-- `{seconds, duration, first, last, ticks}` pour obtenir la validation de la
-- leçon. La preuve déménage dans une colonne que le rôle client ne peut pas
-- écrire, et l'horloge employée pour la construire est celle du serveur.
alter table public.chapter_progress
  add column if not exists watch_proof jsonb not null default '{}'::jsonb;

-- Reprendre les preuves déjà accumulées : aucun apprenant ne doit perdre sa
-- leçon sous prétexte qu'elle a changé de colonne.
update public.chapter_progress
  set watch_proof = coalesce(resume -> 'proof', '{}'::jsonb)
  where resume ? 'proof';

-- Le client ne garde que la reprise de position : seconde de lecture, page,
-- défilement, étape.
revoke update on public.chapter_progress from authenticated;
grant update (resume, updated_at) on public.chapter_progress to authenticated;

revoke insert on public.chapter_progress from authenticated;
grant insert (
  user_id,
  chapter_id,
  track_id,
  resume,
  created_at,
  updated_at
) on public.chapter_progress to authenticated;

-- Un verrouillage complet, même pour le serveur : seule la colonne `resume`
-- est concernée par la révocation ci-dessus. Les colonnes de résultat
-- (`videos_watched`, `best_score`, `attempts`, `status`, `completed_at`,
-- `practice_done`, `solution_viewed`, `watch_proof`) ne s'écrivent donc plus
-- que via la clé de service.

-- ---------------------------------------------------------------------------
-- 3. level_exams : l'examen de niveau n'est pas déclaratif
-- ---------------------------------------------------------------------------
revoke insert, update, delete on public.level_exams from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Contenu payant : les colonnes, pas seulement les lignes
-- ---------------------------------------------------------------------------
-- `videos`, `content`, `exercise`, les corrigés et les ressources sont la
-- marchandise. Un apprenant qui n'a pas acheté le niveau ne doit pas pouvoir
-- les obtenir avec son propre jeton, même en ignorant l'interface. Les pages
-- de l'application qui en ont besoin les lisent désormais avec la clé de
-- service, après avoir vérifié le droit d'accès côté serveur.
revoke select on public.chapters from anon, authenticated;
grant select on public.chapters to service_role;
grant select (
  id,
  track_id,
  slug,
  title,
  summary,
  level,
  position,
  published,
  created_at,
  updated_at
) on public.chapters to authenticated;

revoke select on public.chapter_pages from anon, authenticated;
grant select on public.chapter_pages to service_role;
grant select (
  id,
  chapter_id,
  position,
  title,
  created_at,
  updated_at
) on public.chapter_pages to authenticated;

-- Les réponses des quiz n'étaient déjà accessibles qu'à la clé de service ;
-- on le verrouille explicitement plutôt que de le laisser par omission.
revoke all on public.quiz_questions from anon, authenticated;
grant select, insert, update, delete on public.quiz_questions to service_role;

-- Les fiches publiques du catalogue restent consultables (c'est le but
-- commercial), mais la politique ne dit plus « tout est visible » : une page
-- de cours n'appartient à la lumière que si son chapitre est publié.
drop policy if exists chapter_pages_select on public.chapter_pages;
create policy chapter_pages_select on public.chapter_pages
  for select to authenticated
  using (
    exists (
      select 1
      from public.chapters c
      where c.id = chapter_id
        and (c.published or public.is_admin())
    )
  );

-- idem pour le catalogue : un chapitre publié seulement, sauf pour l'admin.
drop policy if exists chapters_select on public.chapters;
create policy chapters_select on public.chapters
  for select to authenticated
  using (published or public.is_admin());
