-- easyLearn — étape vidéo : suivi des vidéos regardées jusqu'au bout
-- Phase anti-skip : une vidéo n'est marquée comme vue que lorsque l'apprenant
-- l'a parcourue intégralement (fin réelle atteinte, aucun saut en avant).
-- Idempotent : peut être réappliqué sans effet de bord.

alter table public.chapter_progress
  add column if not exists videos_watched text[] not null default '{}';
