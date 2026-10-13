-- Niveaux contigus dans chaque parcours.
--
-- Un chapitre ne s'ouvre qu'une fois le précédent validé (`unlocked = chapitre
-- précédent terminé`). Quand un chapitre « debutant » était numéroté après un
-- chapitre « intermediaire », la partie gratuite du parcours devenait
-- inatteignable sans payer. On renumérote donc `position` par rang de niveau,
-- en conservant l'ordre interne de chaque niveau.
--
-- Parcours concernés avant correction : informatique-generale (ig-c4..c6 après
-- ig-c3), maintenance-informatique (mt-c6 après mt-c4/c5),
-- mobile-flutter-react-native (mob-c4 après mob-c3).

with ordered as (
  select
    c.id,
    row_number() over (
      partition by c.track_id
      order by
        case c.level
          when 'debutant' then 1
          when 'intermediaire' then 2
          when 'avance' then 3
          else 9
        end,
        c.position,
        c.id
    ) as new_position
  from public.chapters c
)
update public.chapters c
set position = ordered.new_position
from ordered
where c.id = ordered.id
  and c.position <> ordered.new_position;
