-- 2026-10-14 : retirer les droits d'écriture hérités des privilèges par défaut de Supabase.
--
-- Pourquoi : ces droits ne servent à rien. Toutes les écritures de catalogue passent par
-- `createServiceSupabase()` (server actions), donc ni `anon` ni `authenticated` n'ont besoin
-- d'INSERER/MODIFIER/SUPPRIMER une ligne de contenu. Seule exception vérifiée dans le code :
-- l'éditeur de catégories (`src/lib/actions/admin.ts`) écrit `categories` avec le client
-- authentifié, protégé par la politique `is_admin()` — ce droit-là est conservé.
--
-- L'état précédent n'était pas exploitable (aucune politique RLS ne laissait `anon` écrire),
-- mais un seul `create policy` mal rédigé demain l'aurait devenu. C'est de la défense en
-- profondeur, pas un correctif d'incident.
--
-- Rollback : rejouer les `grant insert, update, delete ... to anon, authenticated;` retirés.

-- 1) Contenu pédagogique : lecture publique conservée, écriture retirée aux rôles publics.
revoke insert, update, delete on table
  public.chapters,
  public.chapter_pages,
  public.tracks,
  public.tutorials,
  public.practice_tools
from anon, authenticated;

-- 2) Catégories : `anon` ne doit rien pouvoir écrire ; l'admin garde `authenticated`.
revoke insert, update, delete on table public.categories from anon;

-- 3) Profils : un visiteur anonyme n'a rien à écrire, pas même le champ `role`.
revoke insert, update, delete on table public.profiles from anon;

-- 4) Progression : `anon` n'a aucun rôle à jouer ; l'apprenant garde ses colonnes étroites.
revoke insert, update, delete on table public.chapter_progress from anon;

-- 5) Relances marketing : le moteur tourne côté serveur, jamais depuis le navigateur.
revoke insert, update, delete on table
  public.marketing_notices,
  public.marketing_state,
  public.marketing_subscriptions
from anon, authenticated;

-- 6) Les prochaines tables ne réhéritent pas des droits d'écriture publics.
--    Volontairement limité au rôle `postgres` : c'est le propriétaire réel de toutes les tables
--    de `public` (vérifié par pg_class.relacl), et `supabase_admin` n'est pas un rôle dont
--    `postgres` est membre — son ALTER echoue en 42501.
alter default privileges for role postgres in schema public
  revoke insert, update, delete on tables from anon, authenticated;
