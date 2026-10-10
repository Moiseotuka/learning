-- easyLearn — niveau « avancé » : 3 chapitres par parcours existant (18)
-- Idempotent : on conflict (id) do nothing ; compteurs relatifs gardés par snapshot.
-- Généré par scripts/generate-advanced-structure.mjs — ne pas éditer à la main.

insert into public.chapters
  (id, track_id, level, slug, title, summary, objectives, videos, position, published)
values
  ('web-c9', 'developpement-web-moderne', 'avance', 'react-hooks-avances', 'React avancé : hooks, contexte et performance', 'Hooks personnalisés, contexte, mémoïsation et profils React.', array['Extraire un hook personnalisé réutilisable', 'Partager l''état avec le contexte sans provoquer de rendus inutiles', 'Diagnostiquer un rendu avec le profiler React'], '[]'::jsonb, 9, true),
  ('web-c10', 'developpement-web-moderne', 'avance', 'qualite-front', 'Qualité front : tests, typage et accessibilité', 'Testing Library, TypeScript strict, audit accessibilité.', array['Écrire des tests de composant orientés comportement', 'Typer un composant et ses props sans tout laisser en any', 'Corriger les erreurs d''accessibilité d''un audit'], '[]'::jsonb, 10, true),
  ('web-c11', 'developpement-web-moderne', 'avance', 'performance-seo', 'Performance, SEO et livraison continue', 'Core Web Vitals, métadonnées, bundle et déploiement auto.', array['Mesurer et améliorer les Core Web Vitals', 'Rédiger métadonnées et balisage structuré', 'Mettre en place un déploiement à chaque merge'], '[]'::jsonb, 11, true),
  ('cyb-c8', 'cybersecurite-fondamentaux', 'avance', 'investigation-numerique', 'Investigation numérique : collecter et analyser les traces', 'Preuves, chronologie, journaux et rapport d''enquête.', array['Collecter des preuves sans les altérer', 'Reconstituer la chronologie d''un incident', 'Rédiger un constat opposable'], '[]'::jsonb, 8, true),
  ('cyb-c9', 'cybersecurite-fondamentaux', 'avance', 'securite-cloud-conteneurs', 'Sécurité cloud et conteneurs', 'Responsabilités partagées, images, secrets et identités.', array['Appliquer le modèle de responsabilité partagées', 'Durcir images et clés de conteneurs', 'Gérer secrets et rôles au moindre privilège'], '[]'::jsonb, 9, true),
  ('cyb-c10', 'cybersecurite-fondamentaux', 'avance', 'soc-detection-avancee', 'SOC : détection avancée et réponse automatisée', 'Règles, corrélation, playbooks et mesure de la couverture.', array['Écrire une règle de détection sans faux positifs', 'Corréler plusieurs alertes en un incident', 'Automatiser une réponse avec un playbook'], '[]'::jsonb, 10, true),
  ('net-c9', 'reseaux-protocoles-routage', 'avance', 'ipv6', 'IPv6 : adressage, SLAAC et transition', 'Adressage 128 bits, autoconfiguration et cohabitation avec IPv4.', array['Lire et écrire une adresse IPv6', 'Configurer l''autoconfiguration SLAAC', 'Choisir une stratégie de transition'], '[]'::jsonb, 9, true),
  ('net-c10', 'reseaux-protocoles-routage', 'avance', 'sans-fil-professionnel', 'Sans-fil professionnel : WLAN et 802.1X', 'Plan radio, sécurité WPA2-Entreprise et supervision.', array['Concevoir un plan radio sans chevauchement', 'Déployer l''authentification 802.1X', 'Diagnostiquer une couverture dégradée'], '[]'::jsonb, 10, true),
  ('net-c11', 'reseaux-protocoles-routage', 'avance', 'haute-dispo-reseau', 'Load balancing, SD-WAN et haute disponibilité', 'Redondance, équilibrage et liens multiples.', array['Configurer un équilibrateur de charge', 'Comprendre les bénéfices d''un SD-WAN', 'Éliminer les points de défaillance uniques'], '[]'::jsonb, 11, true),
  ('ia-c9', 'ia-data-science', 'avance', 'vision-ordinateur', 'Vision par ordinateur : CNN et augmentation', 'Classification d''images, convolution et robustesse.', array['Entraîner un classifieur d''images', 'Augmenter les données pour éviter le surapprentissage', 'Interpréter les cartes de caractéristiques'], '[]'::jsonb, 9, true),
  ('ia-c10', 'ia-data-science', 'avance', 'series-temporelles', 'Séries temporelles : prévision et anomalies', 'Décomposition, lissage, saisonnalité et détection.', array['Décomposer une série en tendance et saisonnalité', 'Construire une prévision de référence', 'Détecter une anomalie sans faux positifs'], '[]'::jsonb, 10, true),
  ('ia-c11', 'ia-data-science', 'avance', 'mlops-industrialisation', 'MLOps : industrialiser un modèle', 'Pipeline reproductible, versionnage, dérive et service.', array['Reproductibiliser l''entraînement', 'Versionner données et modèles', 'Surveiller la dérive en production'], '[]'::jsonb, 11, true),
  ('ard-c7', 'arduino-esp32-embarque', 'avance', 'temps-reel-freertos', 'Temps réel et FreeRTOS sur ESP32', 'Tâches, priorités, files et synchronisation.', array['Découper une application en tâches', 'Ordonnancer avec priorités et files', 'Éviter les blocages mutuels'], '[]'::jsonb, 7, true),
  ('ard-c8', 'arduino-esp32-embarque', 'avance', 'protocoles-embarques', 'Protocoles industriels : CAN, RS-485 et Modbus', 'Communiquer robustement entre automate et capteurs.', array['Choisir le bus selon la distance et le bruit', 'Échanger en Modbus RTU', 'Diagnostiquer un lien série industriel'], '[]'::jsonb, 8, true),
  ('ard-c9', 'arduino-esp32-embarque', 'avance', 'prototype-production', 'Du prototype à la production', 'Autonomie, veille, encadrement et mise à jour à distance.', array['Réduire la consommation en veille', 'Protéger le code et les données', 'Préparer une mise à jour OTA'], '[]'::jsonb, 9, true),
  ('py-c9', 'python-developpeur', 'avance', 'asynchrone-parallele', 'Asynchrone et parallélisme en Python', 'asyncio, threads, processus et bons usage.', array['Écrire un programme asyncio correct', 'Distinguer threads et processus', 'Paralléliser sans corrompre l''état partagé'], '[]'::jsonb, 9, true),
  ('py-c10', 'python-developpeur', 'avance', 'architecture-qualite', 'Architecture, tests et qualité de code', 'Packages, pytest, outillage et revue de code.', array['Structurer un package installable', 'Écrire des tests fiables et rapides', 'Automatiser le linter et le formateur'], '[]'::jsonb, 10, true),
  ('py-c11', 'python-developpeur', 'avance', 'performance-python', 'Python performant : profiler et optimiser', 'Profiling, structures adaptées et extension natif.', array['Profiler avant d''optimiser', 'Choisir les bonnes structures de données', 'Sortir du pur Python au besoin'], '[]'::jsonb, 11, true)
on conflict (id) do nothing;

with target(id, modules0, duration0) as (
  values
  ('developpement-web-moderne', 40, 60),
  ('cybersecurite-fondamentaux', 28, 42),
  ('reseaux-protocoles-routage', 42, 61),
  ('ia-data-science', 44, 70),
  ('arduino-esp32-embarque', 26, 38),
  ('python-developpeur', 32, 48)
)
update public.tracks t
set modules_count = t.modules_count + 12,
    duration_hours = t.duration_hours + 6
from target
where t.id = target.id
  and t.modules_count = target.modules0
  and t.duration_hours = target.duration0;
