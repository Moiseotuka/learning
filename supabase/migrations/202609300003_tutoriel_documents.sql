-- easyLearn — étape 5 : tutoriel vidéo (YouTube) + documents guidés
-- Colonnes « videos » sur les chapitres + seed curaté pour le parcours Python.
-- Chaque URL a été vérifiée via l'API oEmbed YouTube (titre + chaîne exacts).
-- Idempotent : peut être réappliqué sans effet de bord.

alter table public.chapters
  add column if not exists videos jsonb not null default '[]';

-- Chapitre 1 : Premiers pas en Python : variables et types
update public.chapters set videos = '[
  {"title": "Python Débutant 2026 – Installation & Premier Programme | ép. 1", "url": "https://www.youtube.com/watch?v=AyHHn9PKEZA", "channel": "SimpleTech par Sergio"},
  {"title": "Python Débutant 2026 – Variables, Types et Opérateurs | ép. 2", "url": "https://www.youtube.com/watch?v=7AllMFZKdMM", "channel": "SimpleTech par Sergio"},
  {"title": "Apprendre Python en 1 heure - Cours Complet Débutant (4K)", "url": "https://www.youtube.com/watch?v=5EnpNI2iCZA", "channel": "Comment Coder"}
]'::jsonb where id = 'py-c1';

-- Chapitre 2 : Conditions et boucles : décider et répéter
update public.chapters set videos = '[
  {"title": "Python - Cours complet pour débutants (2026)", "url": "https://www.youtube.com/watch?v=ePMU6MGOJOM", "channel": "SimpleTech par Sergio"},
  {"title": "La Fonction Python RANGE Expliquée", "url": "https://www.youtube.com/watch?v=Doi6uJEJwwA", "channel": "Comment Coder"},
  {"title": "Apprendre Python en 1 heure - Cours Complet Débutant (4K)", "url": "https://www.youtube.com/watch?v=5EnpNI2iCZA", "channel": "Comment Coder"}
]'::jsonb where id = 'py-c2';

-- Chapitre 3 : Fonctions : découper son code
update public.chapters set videos = '[
  {"title": "Leçon 6 : Les fonctions en Python — explication simple pour débutants", "url": "https://www.youtube.com/watch?v=GMJubPpHPsw", "channel": "Wissen corporation"},
  {"title": "Python pour débutants : comprendre les fonctions en 20 minutes", "url": "https://www.youtube.com/watch?v=E-1vlEvBSXQ", "channel": "Adama Programmeur"},
  {"title": "Apprendre Python en 1 heure - Cours Complet Débutant (4K)", "url": "https://www.youtube.com/watch?v=5EnpNI2iCZA", "channel": "Comment Coder"}
]'::jsonb where id = 'py-c3';

-- Chapitre 4 : Listes, dictionnaires et boucler sur les données
update public.chapters set videos = '[
  {"title": "Python Débutant 2026 – les listes | ép. 6", "url": "https://www.youtube.com/watch?v=e16Ty-RNeVI", "channel": "SimpleTech par Sergio"},
  {"title": "Python : Les dictionnaires", "url": "https://www.youtube.com/watch?v=a10AeJ_o-44", "channel": "Docstring"},
  {"title": "Listes et dictionnaires en Python | LinfaTech #42", "url": "https://www.youtube.com/watch?v=kk-D8XKSX5k", "channel": "Linfatech"}
]'::jsonb where id = 'py-c4';

-- Chapitre 5 : Lire et écrire des fichiers
update public.chapters set videos = '[
  {"title": "Créer, ouvrir et lire des fichiers avec Python", "url": "https://www.youtube.com/watch?v=41ktr2ZYVY8", "channel": "Ingénieur IA"},
  {"title": "Lire et écrire des données dans un fichier texte avec Python", "url": "https://www.youtube.com/watch?v=-FQN4oQkJfU", "channel": "Professeur Cot"},
  {"title": "Python Débutant : 32 Bases Essentielles en 5 Minutes", "url": "https://www.youtube.com/watch?v=bUI4MsOu_9I", "channel": "Comment Coder"}
]'::jsonb where id = 'py-c5';

-- Chapitre 6 : Erreurs et exceptions : anticiper les pannes
update public.chapters set videos = '[
  {"title": "Apprendre Python 3 - 10.2. Les exceptions | try, except, finally, raise", "url": "https://www.youtube.com/watch?v=_TtLO6MaJhA", "channel": "SimpleTech par Sergio"},
  {"title": "Gérer les Erreurs et exceptions en Python : try, except, else, finally et raise (Exemples Pratiques)", "url": "https://www.youtube.com/watch?v=HSegdTU-uBE", "channel": "Stat&ML pour tous"},
  {"title": "Python Débutant : 32 Bases Essentielles en 5 Minutes", "url": "https://www.youtube.com/watch?v=bUI4MsOu_9I", "channel": "Comment Coder"}
]'::jsonb where id = 'py-c6';

-- Chapitre 7 : Modules, packages et pip
update public.chapters set videos = '[
  {"title": "Apprendre Python 3 - 9. Les modules et les packages | Structurer son code", "url": "https://www.youtube.com/watch?v=-jCOScsPsmg", "channel": "SimpleTech par Sergio"},
  {"title": "Leçon 7 : Modules et bibliothèques en Python — explication simple pour débutants", "url": "https://www.youtube.com/watch?v=gaSpfq2xtyc", "channel": "Wissen corporation"},
  {"title": "Comment utiliser un fichier requirements.txt en Python ? (Tuto Complet)", "url": "https://www.youtube.com/watch?v=ytcjo2IpV2Y", "channel": "Âme du Dev Consulting"}
]'::jsonb where id = 'py-c7';

-- Chapitre 8 : Mini-projet : analyseur de notes
update public.chapters set videos = '[
  {"title": "Créer un Vrai Projet Python de A à Z (Débutants Bienvenus !)", "url": "https://www.youtube.com/watch?v=ZP5U751bvkg", "channel": "Mayas Nova • Code & Freelance"},
  {"title": "Formation Python Complète pour Débutants (2h) — De Zéro au Projet", "url": "https://www.youtube.com/watch?v=PSE-Q7ndR6w", "channel": "ItSkillsMaker"},
  {"title": "Cours Python Complet pour Débutants - 10h de Formation de A à Z", "url": "https://www.youtube.com/watch?v=5KtsO0sVu_o", "channel": "Sébastien Daviot - Expertise Data"}
]'::jsonb where id = 'py-c8';
