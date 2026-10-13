-- Reprise de position : seconde de vidéo atteinte, page et défilement du cours.
-- Une seule colonne jsonb évite d'ajouter trois colonnes scalaires pour un état
-- purement de confort, lu et écrit par les actions d'apprentissage.

alter table public.chapter_progress
  add column if not exists resume jsonb not null default '{}'::jsonb;

comment on column public.chapter_progress.resume is
  'Position de reprise : { "video": { token: secondes }, "page": entier, "scroll": entier }';
