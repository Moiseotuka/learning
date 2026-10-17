-- 2026-10-16 : journaliser les visites du site public avec leur source réelle.
--
-- Pourquoi : l'admin ne sait pas aujourd'hui d'où viennent les visiteurs. Il publie des liens
-- sur TikTok, WhatsApp et Facebook, et aucun outil ne lui dit combien de personnes sont arrivées
-- par chacun. Cette table répond à « 10 visiteurs depuis TikTok » sans dépendre d'un service de
-- mesure tiers, qui montrerait par ailleurs à l'apprenant que le site est tracé.
--
-- Choix assumés :
-- - aucune politique RLS : ni `anon` ni `authenticated` ne lisent ni n'écrivent ici. Le site
--   écrit avec la clé de service, le tableau de bord lit avec la clé de service. Un visiteur ne
--   peut donc pas se compter lui-même ni lire le trafic des autres ;
-- - `visitor_id` est un identifiant de navigateur (jeton httpOnly), pas un cookie publicitaire :
--   il sert uniquement à décompter des visiteurs uniques et ne quitte pas notre infrastructure ;
-- - pas de nom, pas d'e-mail, pas d'adresse IP : la question posée est « combien, depuis où »,
--   pas « qui ». Le pays vient de l'en-tête régional de l'hébergeur, jamais d'une base externe.
--
-- Rollback : drop table public.site_visits;

create table if not exists public.site_visits (
  id bigint generated always as identity primary key,
  seen_at timestamptz not null default now(),

  -- Page visitée, sans la chaîne de requête : /catalogue, /formations/web, /connexion.
  path text not null,

  -- Source déclarée par le lien (`utm_source`) ou déduite du domaine référent, en minuscules :
  -- tiktok, whatsapp, facebook, google, youtube, instagram, direct...
  source text not null default 'direct',
  medium text,
  campaign text,

  -- Référent brut, tronqué à 200 caractères, gardé pour auditer une déduction de source.
  referrer text,

  -- Pays au moment du chargement, code ISO 3166-1 alpha-2, et type d'appareil déduit de l'agent.
  country text,
  device text,

  -- Jeton de navigateur (anonyme) et compte si le visiteur est connecté.
  visitor_id text not null,
  user_id uuid references public.profiles (id) on delete set null,

  -- Le visiteur a-t-il un compte ? Permet de séparer curieux et apprenant déjà inscrit.
  signed_in boolean not null default false
);

create index if not exists site_visits_seen_at_idx on public.site_visits (seen_at desc);
create index if not exists site_visits_source_idx on public.site_visits (source, seen_at desc);
create index if not exists site_visits_path_idx on public.site_visits (path, seen_at desc);
create index if not exists site_visits_visitor_idx on public.site_visits (visitor_id, seen_at desc);

alter table public.site_visits enable row level security;

-- Défense en profondeur : la table n'a aucune politique, donc tout est refusé ; ces révocations
-- empêchent surtout un futur `grant` hérité des privilèges par défaut de Supabase.
revoke all on table public.site_visits from anon, authenticated;
revoke usage on sequence public.site_visits_id_seq from anon, authenticated;
