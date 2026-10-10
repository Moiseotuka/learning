/**
 * Niveau « avancé » : 3 chapitres avancés pour chacun des 6 parcours existants
 * (18 chapitres squelette, level = 'avance'). Contenus rédigés ensuite en vagues.
 *
 * Émet supabase/migrations/202610070003_advanced_chapters.sql
 * (idempotent : on conflict do nothing + compteurs conditionnels).
 *
 * Usage : node scripts/generate-advanced-structure.mjs
 */
import { writeFileSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(new URL("..", import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, "$1"));
const OUT = resolve(ROOT, "supabase/migrations/202610070003_advanced_chapters.sql");

/** track → { prefix, start (n° du 1er chapitre avancé), modules, duration } */
const TRACKS = {
  "developpement-web-moderne": { prefix: "web-c", start: 9, modules: 40, duration: 60 },
  "cybersecurite-fondamentaux": { prefix: "cyb-c", start: 8, modules: 28, duration: 42 },
  "reseaux-protocoles-routage": { prefix: "net-c", start: 8, modules: 42, duration: 61 },
  "ia-data-science": { prefix: "ia-c", start: 9, modules: 44, duration: 70 },
  "arduino-esp32-embarque": { prefix: "ard-c", start: 7, modules: 26, duration: 38 },
  "python-developpeur": { prefix: "py-c", start: 9, modules: 32, duration: 48 },
};

const CHAPTERS = [
  // --- Développement web moderne — avancé ---
  { track: "developpement-web-moderne", n: 9, slug: "react-hooks-avances", title: "React avancé : hooks, contexte et performance", summary: "Hooks personnalisés, contexte, mémoïsation et profils React.", objectives: ["Extraire un hook personnalisé réutilisable", "Partager l'état avec le contexte sans provoquer de rendus inutiles", "Diagnostiquer un rendu avec le profiler React"] },
  { track: "developpement-web-moderne", n: 10, slug: "qualite-front", title: "Qualité front : tests, typage et accessibilité", summary: "Testing Library, TypeScript strict, audit accessibilité.", objectives: ["Écrire des tests de composant orientés comportement", "Typer un composant et ses props sans tout laisser en any", "Corriger les erreurs d'accessibilité d'un audit"] },
  { track: "developpement-web-moderne", n: 11, slug: "performance-seo", title: "Performance, SEO et livraison continue", summary: "Core Web Vitals, métadonnées, bundle et déploiement auto.", objectives: ["Mesurer et améliorer les Core Web Vitals", "Rédiger métadonnées et balisage structuré", "Mettre en place un déploiement à chaque merge"] },

  // --- Cybersécurité fondamentaux — avancé ---
  { track: "cybersecurite-fondamentaux", n: 8, slug: "investigation-numerique", title: "Investigation numérique : collecter et analyser les traces", summary: "Preuves, chronologie, journaux et rapport d'enquête.", objectives: ["Collecter des preuves sans les altérer", "Reconstituer la chronologie d'un incident", "Rédiger un constat opposable"] },
  { track: "cybersecurite-fondamentaux", n: 9, slug: "securite-cloud-conteneurs", title: "Sécurité cloud et conteneurs", summary: "Responsabilités partagées, images, secrets et identités.", objectives: ["Appliquer le modèle de responsabilité partagées", "Durcir images et clés de conteneurs", "Gérer secrets et rôles au moindre privilège"] },
  { track: "cybersecurite-fondamentaux", n: 10, slug: "soc-detection-avancee", title: "SOC : détection avancée et réponse automatisée", summary: "Règles, corrélation, playbooks et mesure de la couverture.", objectives: ["Écrire une règle de détection sans faux positifs", "Corréler plusieurs alertes en un incident", "Automatiser une réponse avec un playbook"] },

  // --- Réseaux — avancé ---
  { track: "reseaux-protocoles-routage", n: 9, slug: "ipv6", title: "IPv6 : adressage, SLAAC et transition", summary: "Adressage 128 bits, autoconfiguration et cohabitation avec IPv4.", objectives: ["Lire et écrire une adresse IPv6", "Configurer l'autoconfiguration SLAAC", "Choisir une stratégie de transition"] },
  { track: "reseaux-protocoles-routage", n: 10, slug: "sans-fil-professionnel", title: "Sans-fil professionnel : WLAN et 802.1X", summary: "Plan radio, sécurité WPA2-Entreprise et supervision.", objectives: ["Concevoir un plan radio sans chevauchement", "Déployer l'authentification 802.1X", "Diagnostiquer une couverture dégradée"] },
  { track: "reseaux-protocoles-routage", n: 11, slug: "haute-dispo-reseau", title: "Load balancing, SD-WAN et haute disponibilité", summary: "Redondance, équilibrage et liens multiples.", objectives: ["Configurer un équilibrateur de charge", "Comprendre les bénéfices d'un SD-WAN", "Éliminer les points de défaillance uniques"] },

  // --- IA et Data Science — avancé ---
  { track: "ia-data-science", n: 9, slug: "vision-ordinateur", title: "Vision par ordinateur : CNN et augmentation", summary: "Classification d'images, convolution et robustesse.", objectives: ["Entraîner un classifieur d'images", "Augmenter les données pour éviter le surapprentissage", "Interpréter les cartes de caractéristiques"] },
  { track: "ia-data-science", n: 10, slug: "series-temporelles", title: "Séries temporelles : prévision et anomalies", summary: "Décomposition, lissage, saisonnalité et détection.", objectives: ["Décomposer une série en tendance et saisonnalité", "Construire une prévision de référence", "Détecter une anomalie sans faux positifs"] },
  { track: "ia-data-science", n: 11, slug: "mlops-industrialisation", title: "MLOps : industrialiser un modèle", summary: "Pipeline reproductible, versionnage, dérive et service.", objectives: ["Reproductibiliser l'entraînement", "Versionner données et modèles", "Surveiller la dérive en production"] },

  // --- Arduino et ESP32 — avancé ---
  { track: "arduino-esp32-embarque", n: 7, slug: "temps-reel-freertos", title: "Temps réel et FreeRTOS sur ESP32", summary: "Tâches, priorités, files et synchronisation.", objectives: ["Découper une application en tâches", "Ordonnancer avec priorités et files", "Éviter les blocages mutuels"] },
  { track: "arduino-esp32-embarque", n: 8, slug: "protocoles-embarques", title: "Protocoles industriels : CAN, RS-485 et Modbus", summary: "Communiquer robustement entre automate et capteurs.", objectives: ["Choisir le bus selon la distance et le bruit", "Échanger en Modbus RTU", "Diagnostiquer un lien série industriel"] },
  { track: "arduino-esp32-embarque", n: 9, slug: "prototype-production", title: "Du prototype à la production", summary: "Autonomie, veille, encadrement et mise à jour à distance.", objectives: ["Réduire la consommation en veille", "Protéger le code et les données", "Préparer une mise à jour OTA"] },

  // --- Python — avancé ---
  { track: "python-developpeur", n: 9, slug: "asynchrone-parallele", title: "Asynchrone et parallélisme en Python", summary: "asyncio, threads, processus et bons usage.", objectives: ["Écrire un programme asyncio correct", "Distinguer threads et processus", "Paralléliser sans corrompre l'état partagé"] },
  { track: "python-developpeur", n: 10, slug: "architecture-qualite", title: "Architecture, tests et qualité de code", summary: "Packages, pytest, outillage et revue de code.", objectives: ["Structurer un package installable", "Écrire des tests fiables et rapides", "Automatiser le linter et le formateur"] },
  { track: "python-developpeur", n: 11, slug: "performance-python", title: "Python performant : profiler et optimiser", summary: "Profiling, structures adaptées et extension natif.", objectives: ["Profiler avant d'optimiser", "Choisir les bonnes structures de données", "Sortir du pur Python au besoin"] },
];

const rows = CHAPTERS.map((c) => ({
  id: `${TRACKS[c.track].prefix}${c.n}`,
  track_id: c.track,
  level: "avance",
  slug: c.slug,
  title: c.title,
  summary: c.summary,
  objectives: c.objectives,
  position: c.n,
}));

const seen = new Set();
for (const row of rows) {
  if (seen.has(row.id) || seen.has(`slug:${row.slug}`)) {
    console.error(`Collision : ${row.id} / ${row.slug}`);
    process.exit(1);
  }
  seen.add(row.id);
  seen.add(`slug:${row.slug}`);
}

const q = (value) => `'${String(value).replaceAll("'", "''")}'`;
const arr = (items) => `array[${items.map(q).join(", ")}]`;

const values = rows
  .map(
    (row) =>
      `  (${q(row.id)}, ${q(row.track_id)}, ${q(row.level)}, ${q(row.slug)}, ${q(row.title)}, ${q(row.summary)}, ${arr(row.objectives)}, '[]'::jsonb, ${row.position}, true)`,
  )
  .join(",\n");

const counters = Object.entries(TRACKS)
  .map(([track, c]) => `  (${q(track)}, ${c.modules}, ${c.duration})`)
  .join(",\n");

const sql = `-- easyLearn — niveau « avancé » : 3 chapitres par parcours existant (18)
-- Idempotent : on conflict (id) do nothing ; compteurs relatifs gardés par snapshot.
-- Généré par scripts/generate-advanced-structure.mjs — ne pas éditer à la main.

insert into public.chapters
  (id, track_id, level, slug, title, summary, objectives, videos, position, published)
values
${values}
on conflict (id) do nothing;

with target(id, modules0, duration0) as (
  values
${counters}
)
update public.tracks t
set modules_count = t.modules_count + 12,
    duration_hours = t.duration_hours + 6
from target
where t.id = target.id
  and t.modules_count = target.modules0
  and t.duration_hours = target.duration0;
`;

writeFileSync(OUT, sql, "utf8");
console.log(`✓ ${rows.length} chapitres avancés → ${OUT} (${sql.length} octets)`);
