-- easyLearn — curation vidéo : règle stricte « aucun lien site créateur »
-- Migration unique et réappliquable (remplace la version « tour 1 »).
--
-- Règle retenue par validation utilisateur : toute description contenant un
-- lien vers le domaine / site / blog / formation du créateur est ÉCARTÉE.
-- Garde : GitHub / GitLab (code), profils sociaux (twitter, facebook, discord,
-- t.me, tiktok, linkedin, instagram, twitch), documentation tierce officielle
-- (python.org, jetbrains.com, netacad.com, docs.python.org), plateformes de
-- dons (tipeee, utip, ko-fi, buymeacoffee), ressources tierces (drive.google,
-- trinket.io, numworks, codesandbox, online-python, tally.so). Priorité aux
-- descriptions sans aucun lien externe.
-- Contrôles inchangés : aucun prix / coupon / affiliation / funnel, lecture
-- (playability) OK sur toutes les retenues.
-- Limite assumée : les publicités SERVIES par YouTube et les placements dans
-- le corps de la vidéo ne sont pas détectables sans visionnage.
--
-- Étapes : screening de49 vidéos (description originale), audit strict des
-- liens, recherche de remplacements, vérification oEmbed (titre + chaîne
-- exacts) des48 vidéos retenues.
-- Idempotent : suppressions par id, inserts ON CONFLICT DO NOTHING,
-- réécriture complète des tableaux de chapitres, renumérotation déterministe.

-- 1) Suppressions —23 ids ------------------------------------------------------
-- Tour1, critère A2 bis (prix / affiliation / funnel / pub) :10 vidéos
--   8FqZZrbnwkM  (web     ) — produit PDF payant en 1re ligne + vidéo obsolète
--   Ew7KG2j8eII  (web     ) — funnel de vente Podia
--   h-noXGlrH84  (web     ) — la vidéo EST une pub du SaaS stripy.fr
--   nNZTy0286QA  (prog    ) — coupons WELCOMEKAPYLEARN, -30 % formations
--   5EnpNI2iCZA  (prog    ) — offre -66 % / 49,99 € par an
--   VLr0mTzYfRE  (cyber   ) — lien bootcamp payant (funnel formation)
--   szM4VFsKG18  (cyber   ) — guide Gumroad payant + communauté Skool + coaching
--   HRa31C7zfzk  (net     ) — pubs pour les événements d'un tiers (école Oteria)
--   k0KYfGvZUCw  (embedded) — lien affilié Amazon + code promo 20 %
--   dAck3bxzehA  (embedded) — sponsor NextPCB avec codes promo (?code=crazymaker)
-- Tour strict, lien site créateur :7 vidéos
--   XUFLq6dKQok  — site du créateur (machinelearnia.com)
--   DI3xmtAKZJA  — site du créateur (lesbonsprofs)
--   Xi42ZJK74xQ  — site du créateur (eprofs)
--   xQkPjDEbFoU  — blog du créateur (blogspot)
--   riUD8jtw5Os  — page produit du site du créateur
--   a_MaWVosOE4  — site du créateur (arduiblog.fr)
--   BUJAI1ptUu8  — site du créateur (xavki.blog)
-- Remplacements tour1 eux-mêmes écartés au strict :6 vidéos
--   2H602-zG62w  (web     ) — site du créateur (Grafikart)
--   ldxt9FNUc50  (web     ) — site du créateur (Comment Coder)
--   xnd00otyESo  (web     ) — site du créateur (Comment Coder)
--   oUJolR5bX6g  (prog    ) — site du créateur (CodeAvecJonathan)
--   JQUHIDhjvnk  (prog    ) — site du créateur (Comment Coder)
--   kiw1g6GrGJ0  (net     ) — blog du créateur (IT-Connect)
delete from public.tutorials
where id in (
  '8FqZZrbnwkM', 'Ew7KG2j8eII', 'h-noXGlrH84', 'nNZTy0286QA', '5EnpNI2iCZA', 'VLr0mTzYfRE', 'szM4VFsKG18', 'HRa31C7zfzk', 'k0KYfGvZUCw', 'dAck3bxzehA', 'XUFLq6dKQok', 'DI3xmtAKZJA', 'Xi42ZJK74xQ', 'xQkPjDEbFoU', 'riUD8jtw5Os', 'a_MaWVosOE4', 'BUJAI1ptUu8', '2H602-zG62w', 'ldxt9FNUc50', 'xnd00otyESo', 'oUJolR5bX6g', 'JQUHIDhjvnk', 'kiw1g6GrGJ0'
);

-- 2) Remplacements curatés — catalogue (15 ids, dont4 hérités du tour1) -------
-- Vérifiés : oEmbed (titre + chaîne), description auditée sous la règle
-- stricte, playability OK. Positions initialisées à99 puis renumérotées.
insert into public.tutorials (id, category_id, slug, title, summary, url, channel, thumbnail, level, position, published) values
  ('GeIFHYVTyik', 'web', 'reactjs-cours-complet-5h', 'Cours complet sur ReactJS dans 5 heures | tuto fr', 'Cours complet ReactJS en 5 heures : composants, hooks et mise en pratique.', 'https://www.youtube.com/watch?v=GeIFHYVTyik', 'Malakisi', 'https://i.ytimg.com/vi/GeIFHYVTyik/hqdefault.jpg', 'intermediaire', 99, true),
  ('iNeqb-URBj4', 'prog', 'algorithmie-python-120-exercices', '[Bonus] - Plus de 120 exercices d''algorithmie en Python', 'Plus de 120 exercices corrigés pour entraîner sa logique en Python.', 'https://www.youtube.com/watch?v=iNeqb-URBj4', 'Foxxpy - Mathématiques et algorithmie', 'https://i.ytimg.com/vi/iNeqb-URBj4/hqdefault.jpg', 'debutant', 99, true),
  ('kv5qChtWg5k', 'prog', 'python-saisie-donnees-exercices', 'Python débutant : l''erreur qui fait amateur devant un client (+3 exercices)', 'Recevoir, nettoyer et afficher une donnée en Python, avec trois exercices corrigés.', 'https://www.youtube.com/watch?v=kv5qChtWg5k', 'DuCodeAuClient', 'https://i.ytimg.com/vi/kv5qChtWg5k/hqdefault.jpg', 'debutant', 99, true),
  ('4Kf2BlL1boQ', 'ai', 'machine-learning-seance-introduction', 'Formation IA: Séance 1 – Introduction au Machine Learning – Apprentissage Supervisé vs Non Supervisé', 'Séance introductive au machine learning : concepts et premiers pas.', 'https://www.youtube.com/watch?v=4Kf2BlL1boQ', 'Prof. Sabri', 'https://i.ytimg.com/vi/4Kf2BlL1boQ/hqdefault.jpg', 'intermediaire', 99, true),
  ('EBPLEbi4OkE', 'net', 'bases-reseau-debutants-1h30', 'Les bases du réseau pour débutants – Le guide complet en 1h30', 'Les bases du réseau en 1h30 : adresses IP, masques et modèle OSI.', 'https://www.youtube.com/watch?v=EBPLEbi4OkE', 'InfraNerdFR', 'https://i.ytimg.com/vi/EBPLEbi4OkE/hqdefault.jpg', 'debutant', 99, true),
  ('pcevzxG9Jc0', 'net', 'reseau-lan-formation-complete', 'Réseaux Informatiques – Formation Complète Réseau Local (LAN) de Zéro à Avancé | 2H', 'Concevoir, configurer et dépanner un réseau local de A à Z.', 'https://www.youtube.com/watch?v=pcevzxG9Jc0', 'HooYia', 'https://i.ytimg.com/vi/pcevzxG9Jc0/hqdefault.jpg', 'intermediaire', 99, true),
  ('zxMjM2bWiyo', 'physics', 'forces-interaction-gravitationnelle', 'Les Forces / Interaction gravitationnelle Poids Action Réaction / Physique Chimie Seconde', 'Forces, poids, action et réaction : les interactions gravitationnelles.', 'https://www.youtube.com/watch?v=zxMjM2bWiyo', 'nicolas galiot', 'https://i.ytimg.com/vi/zxMjM2bWiyo/hqdefault.jpg', 'debutant', 99, true),
  ('MLBbtfj_jyQ', 'mecha', 'fabriquer-robot-arduino-part1', 'Comment fabriquer un robot - part 1  | Arduino #9', 'Fabriquer une voiture téléguidée avec Arduino, montage pas à pas.', 'https://www.youtube.com/watch?v=MLBbtfj_jyQ', 'Rim Robotique', 'https://i.ytimg.com/vi/MLBbtfj_jyQ/hqdefault.jpg', 'projet', 99, true),
  ('BCvXOPih2zo', 'mecha', 'servomoteur-arduino', 'Utiliser un ServoMoteur | ARDUINO #17', 'Piloter un servomoteur avec Arduino : programme et schéma fournis.', 'https://www.youtube.com/watch?v=BCvXOPih2zo', 'ElectroCodeur', 'https://i.ytimg.com/vi/BCvXOPih2zo/hqdefault.jpg', 'debutant', 99, true),
  ('wzyMk82zKng', 'mecha', 'bras-robotise-arduino', 'Arduino - Bras robotisé', 'Construire et piloter un bras robotisé avec Arduino.', 'https://www.youtube.com/watch?v=wzyMk82zKng', 'julien-d', 'https://i.ytimg.com/vi/wzyMk82zKng/hqdefault.jpg', 'intermediaire', 99, true),
  ('mspEJzb8LC4', 'cloud', 'docker-explication-5-min', 'Docker expliqué en 5 minutes', 'Images, conteneurs et Docker Compose expliqués en cinq minutes.', 'https://www.youtube.com/watch?v=mspEJzb8LC4', 'Bande de Codeurs', 'https://i.ytimg.com/vi/mspEJzb8LC4/hqdefault.jpg', 'debutant', 99, true),
  ('uoogZrxncqY', 'cyber', 'cybersecurite-les-metiers', '🔐C''est quoi la CyberSécurité | 👮Les Métiers de la CyberSécurité', 'Découvrir les grands métiers de la cybersécurité.', 'https://www.youtube.com/watch?v=uoogZrxncqY', 'ETC SCHOOL', 'https://i.ytimg.com/vi/uoogZrxncqY/hqdefault.jpg', 'debutant', 99, true),
  ('3DNFySkd_v8', 'cyber', 'apprendre-hacking-guide-2026', 'Comment Apprendre le Hacking : Tout Ce Que Vous Devez Savoir (Guide 2026)', 'Un guide structuré pour apprendre le hacking efficacement.', 'https://www.youtube.com/watch?v=3DNFySkd_v8', 'Parlons Cyber', 'https://i.ytimg.com/vi/3DNFySkd_v8/hqdefault.jpg', 'debutant', 99, true),
  ('s6_8PEm3u-I', 'embedded', 'esp32-debuter-wroom32', 'Débuter avec ESP32 - Constitution et fonctionnalités - WROOM-32E et Devkitc_v4', 'Prendre en main la carte ESP32 WROOM-32E pas à pas.', 'https://www.youtube.com/watch?v=s6_8PEm3u-I', 'Hervé Discours', 'https://i.ytimg.com/vi/s6_8PEm3u-I/hqdefault.jpg', 'intermediaire', 99, true),
  ('akN5nyKiCOw', 'embedded', 'esp32-prise-en-main', 'Présentation et prise en main de l''ESP32/Tutoriel complet ', 'Introduction complète à l''ESP32 pour bien démarrer.', 'https://www.youtube.com/watch?v=akN5nyKiCOw', 'Freddie l''électro-programmeur ', 'https://i.ytimg.com/vi/akN5nyKiCOw/hqdefault.jpg', 'debutant', 99, true)
on conflict do nothing;

-- 3) Re-numérotation des positions par catégorie (aucun trou) ----------------
with ranked as (
  select id,
         row_number() over (partition by category_id order by position, created_at) as new_pos
  from public.tutorials
)
update public.tutorials t
set position = r.new_pos
from ranked r
where t.id = r.id
  and t.position is distinct from r.new_pos;

-- 4) Chapitres Python : tableaux complets sous la règle stricte ---------------
-- Retraits : SimpleTech / Comment Coder / ISC / Mayas Nova (liens site
-- créateur), bUI4MsOu_9I (py-c5 + py-c6), remplacements tour1 écartés.

-- py-c1 : Premiers pas : installation, variables et premier programme
update public.chapters set videos = '[
  {"title": "Comment télécharger et installer  FACILEMENT Python et PyCharm sur PC", "url": "https://www.youtube.com/watch?v=XhUsgTjPDZA", "channel": "Âme du Dev Consulting"},
  {"title": "#19 Tuto Python Débutant - Variables globales et locales", "url": "https://www.youtube.com/watch?v=2ryiScv26Ys", "channel": "Science avec Mat"},
  {"title": "Premier Programme Python : Hello World ! - Tutoriel Débutant 2025", "url": "https://www.youtube.com/watch?v=2m0fWQCUCY4", "channel": "CharlyInCode"}
]'::jsonb where id = 'py-c1';

-- py-c2 : Conditions et boucles : décider et répéter
update public.chapters set videos = '[
  {"title": "Apprendre Python - Structures conditionnelles (if elif else)", "url": "https://www.youtube.com/watch?v=eHn4BPQ7ON4", "channel": "Mohamed Chiny"},
  {"title": "Python #4 Les conditions et les boucles", "url": "https://www.youtube.com/watch?v=x1SXpdDitLA", "channel": "SOSMathInfo"},
  {"title": "Boucles for en Python : Un tutoriel étape par étape", "url": "https://www.youtube.com/watch?v=MtP8HsMt_Gg", "channel": "Mycode - Développement"}
]'::jsonb where id = 'py-c2';

-- py-c3 : Fonctions : découper son code
update public.chapters set videos = '[
  {"title": "Leçon 6 : Les fonctions en Python — explication simple pour débutants", "url": "https://www.youtube.com/watch?v=GMJubPpHPsw", "channel": "Wissen corporation"},
  {"title": "Python pour débutants : comprendre les fonctions en 20 minutes", "url": "https://www.youtube.com/watch?v=E-1vlEvBSXQ", "channel": "Adama Programmeur"},
  {"title": "Fonction python avec parametre par défaut - Python 49", "url": "https://www.youtube.com/watch?v=ODfpzt-VwLI", "channel": "La Hauteur de la Profondeur"}
]'::jsonb where id = 'py-c3';

-- py-c4 : Listes, dictionnaires et boucler sur les données
update public.chapters set videos = '[
  {"title": "Collections en Python : liste, tuple, set et dictionnaire | Python pour la Science #3", "url": "https://www.youtube.com/watch?v=Cx2vIe-lZwM", "channel": "EpiMed Open Course"},
  {"title": "Listes et dictionnaires en Python | LinfaTech #42", "url": "https://www.youtube.com/watch?v=kk-D8XKSX5k", "channel": "Linfatech "},
  {"title": "Apprendre Python - Les dictionnaires", "url": "https://www.youtube.com/watch?v=swC1nXTub2U", "channel": "Mohamed Chiny"}
]'::jsonb where id = 'py-c4';

-- py-c5 : Lire et écrire des fichiers
update public.chapters set videos = '[
  {"title": "Créer, ouvrir et lire des fichiers avec Python", "url": "https://www.youtube.com/watch?v=41ktr2ZYVY8", "channel": "Ingénieur IA"},
  {"title": "Lire et écrire des données dans un fichier texte avec Python", "url": "https://www.youtube.com/watch?v=-FQN4oQkJfU", "channel": "Professeur Cot"},
  {"title": "Apprendre Python - Les fichiers", "url": "https://www.youtube.com/watch?v=qSYvF4GJWac", "channel": "Mohamed Chiny"}
]'::jsonb where id = 'py-c5';

-- py-c6 : Erreurs et exceptions : anticiper les pannes
update public.chapters set videos = '[
  {"title": "Apprendre Python 3 - 10.2. Les exceptions | try, except, finally, raise", "url": "https://www.youtube.com/watch?v=_TtLO6MaJhA", "channel": "SimpleTech par Sergio"},
  {"title": "Gérer les Erreurs et exceptions en Python : try, except, else, finally et raise (Exemples Pratiques)", "url": "https://www.youtube.com/watch?v=HSegdTU-uBE", "channel": "Stat&ML pour tous"},
  {"title": "Maîtriser la Gestion des Erreurs en Python : try, except, finally, else", "url": "https://www.youtube.com/watch?v=FSJXzjP-XkE", "channel": "CharlyInCode"}
]'::jsonb where id = 'py-c6';

-- py-c8 : Mini-projet : analyseur de notes
update public.chapters set videos = '[
  {"title": "Formation Python Complète pour Débutants (2h) — De Zéro au Projet", "url": "https://www.youtube.com/watch?v=PSE-Q7ndR6w", "channel": "ItSkillsMaker"},
  {"title": "[2/25] Mini Projet Python, 1h pour solidifier vos connaissances [Débutants].", "url": "https://www.youtube.com/watch?v=CNZ6Cfzi97I", "channel": "Mastering AI"},
  {"title": "Python - Jeu du type Morpion avec la tortue (Part 1)", "url": "https://www.youtube.com/watch?v=QVyLvrK-FUw", "channel": "Schraf : Maths-info"}
]'::jsonb where id = 'py-c8';

-- 5) Résultat final :27 vidéos de catalogue (10 catégories) + chapitres
--    py-c1 à py-c8 à3 vidéos chacun — zéro lacune, zéro écart à la règle.
