-- easyLearn — étape 6 : page /catalogue dédiée
-- Table « tutorials » (vidéos YouTube curatées par catégorie) + seed.
-- Chaque URL/ titre / chaîne / miniature a été vérifié via l'API oEmbed YouTube.
-- Idempotent : peut être réappliqué sans effet de bord.

create table if not exists public.tutorials (
  id text primary key, -- identifiant de la vidéo YouTube
  category_id text not null references public.categories (id) on delete cascade,
  slug text not null unique,
  title text not null,
  summary text not null default '',
  url text not null,
  channel text not null default '',
  thumbnail text not null default '',
  level text not null default 'debutant' check (level in ('debutant', 'intermediaire', 'avance', 'projet')),
  position integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists tutorials_set_updated_at on public.tutorials;
create trigger tutorials_set_updated_at
  before update on public.tutorials
  for each row execute function public.set_updated_at();

create index if not exists tutorials_category_id_idx on public.tutorials (category_id);
create index if not exists tutorials_published_position_idx on public.tutorials (published, position);

alter table public.tutorials enable row level security;

drop policy if exists "tutorials_select" on public.tutorials;
create policy "tutorials_select" on public.tutorials
  for select
  using (published or public.is_admin());

drop policy if exists "tutorials_admin_write" on public.tutorials;
create policy "tutorials_admin_write" on public.tutorials
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Seed : 29 vidéos curatées (10 catégories) ----------------------------------

insert into public.tutorials (id, category_id, slug, title, summary, url, channel, thumbnail, level, position, published) values
  -- Développement web et mobile
  ('nf2XHSpI4WA', 'web', 'cours-web-debutant-moderne', 'Cours complet sur le développement Web moderne pour débutant (html,css,javascript) | tuto français', 'Un parcours complet HTML, CSS et JavaScript pour construire son premier site.', 'https://www.youtube.com/watch?v=nf2XHSpI4WA', 'Malakisi', 'https://i.ytimg.com/vi/nf2XHSpI4WA/hqdefault.jpg', 'debutant', 1, true),
  ('8FqZZrbnwkM', 'web', 'html-css-cours-complet', 'Cours Complet HTML CSS - Tutoriel pour Débutants et Confirmés [Partie 1/3]', 'Les fondations du web : structure HTML et mise en page CSS, pas à pas.', 'https://www.youtube.com/watch?v=8FqZZrbnwkM', 'Pierre Giraud', 'https://i.ytimg.com/vi/8FqZZrbnwkM/hqdefault.jpg', 'debutant', 2, true),
  ('Ew7KG2j8eII', 'web', 'javascript-bases-a-a-z', '[Cours / Tuto débutant] Apprendre Javascript de A à Z – Les bases (1/6)', 'Premiers pas en JavaScript : variables, conditions et boucles.', 'https://www.youtube.com/watch?v=Ew7KG2j8eII', 'From Scratch - Le développement Web de zéro', 'https://i.ytimg.com/vi/Ew7KG2j8eII/hqdefault.jpg', 'debutant', 3, true),
  ('TUc5BPDcvyg', 'web', 'stripe-nextjs-paiement', 'Stripe avec Next.js 15 : comment intégrer le paiement Stripe ?', 'Intégrer un tunnel de paiement Stripe dans une application Next.js.', 'https://www.youtube.com/watch?v=TUc5BPDcvyg', 'La minute de code', 'https://i.ytimg.com/vi/TUc5BPDcvyg/hqdefault.jpg', 'intermediaire', 4, true),
  ('h-noXGlrH84', 'web', 'lien-paiement-stripe', 'Créer un lien de paiement en plusieurs fois avec Stripe', 'Mettre en place des paiements échelonnés avec Stripe, sans code.', 'https://www.youtube.com/watch?v=h-noXGlrH84', 'Stripy', 'https://i.ytimg.com/vi/h-noXGlrH84/hqdefault.jpg', 'intermediaire', 5, true),

  -- Programmation
  ('QMb0fjH5Rjg', 'prog', 'python-cours-complet-debutants', '🐍APPRENDRE PYTHON : COURS COMPLET POUR DEBUTANTS👨‍💻', 'Le grand cours de Python pour démarrer de zéro.', 'https://www.youtube.com/watch?v=QMb0fjH5Rjg', 'ETC SCHOOL', 'https://i.ytimg.com/vi/QMb0fjH5Rjg/hqdefault.jpg', 'debutant', 1, true),
  ('nNZTy0286QA', 'prog', 'python-bases-en-1-heure', 'Apprends les bases de la programmation Python en 1 heure | Tutoriel Python 3 Kapylearn', 'Les bases essentielles de Python condensées en une heure.', 'https://www.youtube.com/watch?v=nNZTy0286QA', 'KapyGenius Tech', 'https://i.ytimg.com/vi/nNZTy0286QA/hqdefault.jpg', 'debutant', 2, true),
  ('5EnpNI2iCZA', 'prog', 'python-cours-1-heure', 'Apprendre Python en 1 heure - Cours Complet Débutant (4K)', 'Un cours intensif pour écrire ses premiers scripts Python.', 'https://www.youtube.com/watch?v=5EnpNI2iCZA', 'Comment Coder', 'https://i.ytimg.com/vi/5EnpNI2iCZA/hqdefault.jpg', 'debutant', 3, true),

  -- Intelligence artificielle et data
  ('IXONBCDbbTg', 'ai', 'introduction-machine-learning', 'Introduction au Machine Learning', 'Comprendre les grands principes de l''apprentissage automatique.', 'https://www.youtube.com/watch?v=IXONBCDbbTg', 'Liora', 'https://i.ytimg.com/vi/IXONBCDbbTg/hqdefault.jpg', 'debutant', 1, true),
  ('XUFLq6dKQok', 'ai', 'deep-learning-formation-complete', 'FORMATION DEEP LEARNING COMPLETE (2021)', 'Une formation complète au deep learning, des bases aux réseaux de neurones.', 'https://www.youtube.com/watch?v=XUFLq6dKQok', 'Machine Learnia', 'https://i.ytimg.com/vi/XUFLq6dKQok/hqdefault.jpg', 'intermediaire', 2, true),
  ('DLHyLNpMpac', 'ai', 'regression-intelligence-artificielle', 'Part 2  Intelligence Artificielle - REGRESSION', 'Régression linéaire et modèles prédictifs expliqués par le Professeur Mohamed Youssfi.', 'https://www.youtube.com/watch?v=DLHyLNpMpac', 'Professeur Mohamed YOUSSFI', 'https://i.ytimg.com/vi/DLHyLNpMpac/hqdefault.jpg', 'intermediaire', 3, true),

  -- Cybersécurité
  ('VLr0mTzYfRE', 'cyber', 'cybersecurite-guide-complet', 'Cybersécurité : guide COMPLET pour démarrer rapidement | Sécurité informatique débutant', 'Le guide complet pour démarrer en cybersécurité rapidement.', 'https://www.youtube.com/watch?v=VLr0mTzYfRE', 'Techno', 'https://i.ytimg.com/vi/VLr0mTzYfRE/hqdefault.jpg', 'debutant', 1, true),
  ('szM4VFsKG18', 'cyber', 'debuter-cybersecurite-ordre-apprentissage', 'Débuter en cybersécurité : Quoi apprendre, ou apprendre  et dans quel ordre ? (Guide 2026)', 'Quoi apprendre et dans quel ordre pour progresser en cybersécurité.', 'https://www.youtube.com/watch?v=szM4VFsKG18', 'Jodry', 'https://i.ytimg.com/vi/szM4VFsKG18/hqdefault.jpg', 'debutant', 2, true),
  ('VtCUt8_pVLA', 'cyber', 'plan-cybersecurite-2026', 'Si je DÉBUTAIS dans la CYBERSÉCURITÉ en 2026, voici ce que je ferais (plan complet)', 'Un plan d''apprentissage concret pour se lancer en cybersécurité.', 'https://www.youtube.com/watch?v=VtCUt8_pVLA', 'Michel Kartner', 'https://i.ytimg.com/vi/VtCUt8_pVLA/hqdefault.jpg', 'debutant', 3, true),

  -- Réseaux et télécommunications
  ('HRa31C7zfzk', 'net', 'recreer-internet-de-zero', 'vas-y, viens, on recrée TOUT internet... de zéro', 'Reconstruire Internet de zéro pour comprendre ses protocoles.', 'https://www.youtube.com/watch?v=HRa31C7zfzk', 'V2F', 'https://i.ytimg.com/vi/HRa31C7zfzk/hqdefault.jpg', 'debutant', 1, true),
  ('DI3xmtAKZJA', 'net', 'protocole-tcp-ip-introduction', 'Le protocole TCP-IP - SNT -Seconde - Les Bons Profs', 'Introduction au protocole TCP/IP et au modèle en couches.', 'https://www.youtube.com/watch?v=DI3xmtAKZJA', 'Les Bons Profs', 'https://i.ytimg.com/vi/DI3xmtAKZJA/hqdefault.jpg', 'debutant', 2, true),
  ('RnpSaDSSjR4', 'net', 'adresse-ip-masques-sous-reseaux', 'Réseaux : adresse IP et masques de sous-réseaux', 'Adressage IP, masques et calculs de sous-réseaux expliqués.', 'https://www.youtube.com/watch?v=RnpSaDSSjR4', 'Ludovic Guérin - Cours de SI', 'https://i.ytimg.com/vi/RnpSaDSSjR4/hqdefault.jpg', 'debutant', 3, true),

  -- Systèmes embarqués
  ('EL-cfOlMqPo', 'embedded', 'arduino-bases-programmation', '📚APPRENDRE ARDUINO : Les Bases de la Programmation🦾 | Pour les Débutants👨‍💻', 'Les bases de la programmation Arduino pour les débutants.', 'https://www.youtube.com/watch?v=EL-cfOlMqPo', 'ETC SCHOOL', 'https://i.ytimg.com/vi/EL-cfOlMqPo/hqdefault.jpg', 'debutant', 1, true),
  ('k0KYfGvZUCw', 'embedded', 'arduino-installation-premiere-led', 'TUTO ARDUINO #1 : INSTALLATION ET FAIRE CLIGNOTER UNE LED !', 'Installer l''IDE Arduino et faire clignoter sa première LED.', 'https://www.youtube.com/watch?v=k0KYfGvZUCw', 'Retrojeux', 'https://i.ytimg.com/vi/k0KYfGvZUCw/hqdefault.jpg', 'debutant', 2, true),
  ('dAck3bxzehA', 'embedded', 'pcb-kicad-debutant', '🔌 Concevoir un PCB de A à Z avec KiCad (débutant)', 'Concevoir son premier circuit imprimé avec le logiciel KiCad.', 'https://www.youtube.com/watch?v=dAck3bxzehA', 'Crazymakers', 'https://i.ytimg.com/vi/dAck3bxzehA/hqdefault.jpg', 'intermediaire', 3, true),

  -- Électronique
  ('NdWYOcvel2g', 'electronics', 'diode-roue-libre', 'TRONIK AVENTUR 144 - LA DIODE DE ROUE LIBRE - ELECTRONIQUE DEBUTANTS', 'Le rôle de la diode de roue libre expliqué pour débutants.', 'https://www.youtube.com/watch?v=NdWYOcvel2g', 'thonain', 'https://i.ytimg.com/vi/NdWYOcvel2g/hqdefault.jpg', 'debutant', 1, true),
  ('2iGSagh3kRI', 'electronics', 'cours-electronique-initiation', 'S1 - Thème TA1 - Département GEII2, IUT de Cachan - 2020', 'Cours d''introduction à l''électronique (IUT GEII).', 'https://www.youtube.com/watch?v=2iGSagh3kRI', 'Fabien Parrain', 'https://i.ytimg.com/vi/2iGSagh3kRI/hqdefault.jpg', 'intermediaire', 2, true),

  -- Physique appliquée
  ('27CWoMzUvGo', 'physics', 'force-et-mouvement', 'Force et mouvement - Physique-Chimie - Seconde - Les Bons Profs', 'Action mécanique, forces et influence sur le mouvement.', 'https://www.youtube.com/watch?v=27CWoMzUvGo', 'Les Bons Profs', 'https://i.ytimg.com/vi/27CWoMzUvGo/hqdefault.jpg', 'debutant', 1, true),
  ('Xi42ZJK74xQ', 'physics', 'energie-potentielle-pesanteur', 'Énergie POTENTIELLE de pesanteur - Énergie de POSITION - Explication | Physique | Collège - Lycée', 'Énergie potentielle de pesanteur et énergie de position.', 'https://www.youtube.com/watch?v=Xi42ZJK74xQ', 'e-profs - Physique Chimie', 'https://i.ytimg.com/vi/Xi42ZJK74xQ/hqdefault.jpg', 'debutant', 2, true),

  -- Mécatronique et robotique
  ('xQkPjDEbFoU', 'mecha', 'bras-robotique-arduino', 'Bras robotique', 'Construire et piloter un bras robotique avec Arduino.', 'https://www.youtube.com/watch?v=xQkPjDEbFoU', 'Électronique en Amateur', 'https://i.ytimg.com/vi/xQkPjDEbFoU/hqdefault.jpg', 'intermediaire', 1, true),
  ('riUD8jtw5Os', 'mecha', 'assemblage-robot-mbot', 'Tutoriel assemblage robot mBot option pince', 'Assembler le robot mBot et sa pince, pas à pas.', 'https://www.youtube.com/watch?v=riUD8jtw5Os', 'Technologie Services', 'https://i.ytimg.com/vi/riUD8jtw5Os/hqdefault.jpg', 'debutant', 2, true),
  ('a_MaWVosOE4', 'mecha', 'robot-mobile-trottinettes', 'Challenge sur la seconde vie des trottinettes électriques', 'Robot mobile Arduino construit à partir de trottinettes recyclées.', 'https://www.youtube.com/watch?v=a_MaWVosOE4', 'arduiblog', 'https://i.ytimg.com/vi/a_MaWVosOE4/hqdefault.jpg', 'intermediaire', 3, true),

  -- Cloud et DevOps
  ('BUJAI1ptUu8', 'cloud', 'dockerfile-docker-instructions', 'Docker : Le Dockerfile et ses instructions', 'Écrire un Dockerfile et comprendre ses instructions clés.', 'https://www.youtube.com/watch?v=BUJAI1ptUu8', 'xavki', 'https://i.ytimg.com/vi/BUJAI1ptUu8/hqdefault.jpg', 'intermediaire', 1, true),
  ('yFp_BxFnIO4', 'cloud', 'kubernetes-formation-complete', 'Kubernetes de A à Z – Formation Complète 7H', 'Formation complète Kubernetes : du premier pod à l''orchestration.', 'https://www.youtube.com/watch?v=yFp_BxFnIO4', 'Donald Programmeur', 'https://i.ytimg.com/vi/yFp_BxFnIO4/hqdefault.jpg', 'avance', 2, true)
on conflict (id) do nothing;
