-- Certificat signé par le formateur qui a suivi l'élève.
--
-- Un parcours suivi dans la classe d'une académie n'est pas le même acte qu'un
-- parcours suivi seul : quelqu'un a répondu des questions, tenu la feuille de
-- présence, corrigé le projet. Le nom de ce quelqu'un est donc figé sur le
-- certificat, comme le sont déjà `full_name` et `track_title` : un formateur qui
-- change de nom ou ferme sa classe ne doit pas réécrire l'histoire des diplômes
-- déjà délivrés.
--
-- Les blocs « Jean Dubois » et « Clara Moreau » imprimés sur le fond du PDF
-- n'ont jamais été personne de réel ; ils sont désormais recouverts et remplacés
-- par des signatures vraies (le formateur, puis la plateforme).

alter table public.certificates
  add column if not exists instructor_id uuid references auth.users (id) on delete set null,
  add column if not exists instructor_name text,
  add column if not exists academy text;

comment on column public.certificates.instructor_name is
  'Formateur qui suivait l''élève à l''émission du certificat ; null pour un parcours suivi seul.';
comment on column public.certificates.academy is
  'Académie citée sur le certificat, reprise de la classe de l''élève.';

-- Rattrapage des certificats déjà délivrés : la classe active de l'élève pour le
-- même parcours porte la signature qui aurait dû être écrite à l'émission.
with signed as (
  select
    m.user_id,
    c.track_id,
    c.instructor_id,
    p.full_name as instructor_name,
    c.academy,
    row_number() over (
      partition by m.user_id, c.track_id
      order by c.created_at desc
    ) as newest
  from public.instructor_class_members m
  join public.instructor_classes c
    on c.id = m.class_id and c.status = 'active' and c.track_id is not null
  left join public.profiles p on p.id = c.instructor_id
  where m.status = 'active'
)
update public.certificates ct
set
  instructor_id = s.instructor_id,
  instructor_name = nullif(trim(coalesce(s.instructor_name, '')), ''),
  academy = nullif(trim(coalesce(s.academy, '')), '')
from signed s
where
  s.newest = 1
  and ct.user_id = s.user_id
  and ct.track_id = s.track_id
  and ct.instructor_name is null;
