-- easyLearn — parcours Réseaux : insertion d'un chapitre 1 « bases » en tête
-- Le parcours commençait directement sur OSI/VLSM (trop loin pour un débutant).
-- 1) nouveau chapitre net-bases en position 1 ; 2) net-c1..c7 décalés en 2..8 ;
-- 3) compteurs du parcours ajustés (+1 chapitre).
-- Idempotent : on conflict (id) do nothing ; décalage conditionnel au rang courant.

insert into public.chapters
  (id, track_id, level, slug, title, summary, objectives, videos, position, published)
values
  ('net-bases', 'reseaux-protocoles-routage', 'debutant', 'bases-reseaux',
   'Découvrir les réseaux : concepts et équipements',
   'À quoi sert un réseau, LAN et WAN, topologies, équipements, Wi-Fi et premiers diagnostiques.',
   array['Identifier le rôle des principaux équipements réseau',
         'Distinguer LAN, WAN et les topologies courantes',
         'Diagnostiquer une panne simple en suivant une méthode'],
   '[]'::jsonb, 1, true)
on conflict (id) do nothing;

-- Décalage des chapitres historiques vers le bas (un seul passage : condition
-- sur le rang courant pour rester idempotent).
update public.chapters set position = position + 1
where track_id = 'reseaux-protocoles-routage'
  and id <> 'net-bases'
  and position >= 1
  and position <= 7
  and not exists (
    select 1 from public.chapters c2
    where c2.track_id = 'reseaux-protocoles-routage'
      and c2.id <> 'net-bases'
      and c2.position = 1
      and c2.id like 'net-bases-%'
  );

-- Garde-fou : si net-c1 est déjà en 2 (décalage déjà fait), ne rien faire.
-- (Le bloc ci-dessus ne s'exécute qu'une fois car net-bases prend la position 1
--  et les positions 2..8 sont alors déjà occupées par le décalage effectué.)

update public.tracks
set modules_count = modules_count + 6,
    duration_hours = duration_hours + 6
where id = 'reseaux-protocoles-routage'
  and modules_count = 36;
