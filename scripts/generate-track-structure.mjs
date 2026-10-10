/**
 * Structure des 5 parcours vides : chapitres (titres, résumés, objectifs,
 * positions, niveaux) — SANS contenu (leçons, exercices, quiz, ressources =
 * rédigés chapitre par chapitre ensuite).
 *
 * Émet supabase/migrations/202610040007_track_structure.sql (idempotent :
 * on conflict do nothing — ne touche jamais aux contenus déjà écrits).
 *
 * Usage : node scripts/generate-track-structure.mjs           (SQL uniquement)
 *         node scripts/generate-track-structure.mjs --apply   (SQL + REST dev)
 */
import { writeFileSync } from "node:fs";
import { resolve } from "node:path";

import { serviceEnv } from "./e2e-setup.mjs";

const ROOT = resolve(new URL("..", import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, "$1"));
const OUT = resolve(ROOT, "supabase/migrations/202610040007_track_structure.sql");

const T = {
  web: "developpement-web-moderne",
  cyb: "cybersecurite-fondamentaux",
  net: "reseaux-protocoles-routage",
  ia: "ia-data-science",
  ard: "arduino-esp32-embarque",
};

/** prefixe, total, positions débutant (n premières) */
const TRACKS = {
  [T.web]: { prefix: "web-c", levelBreak: 4 },
  [T.cyb]: { prefix: "cyb-c", levelBreak: 4 },
  [T.net]: { prefix: "net-c", levelBreak: 4 },
  [T.ia]: { prefix: "ia-c", levelBreak: 4 },
  [T.ard]: { prefix: "ard-c", levelBreak: 4 },
};

const CHAPTERS = [
  // --- Développement web moderne (8) ---
  { track: T.web, n: 1, slug: "html-semantique", title: "HTML sémantique : structurer une page", summary: "Balises structurantes, formulaires et bases de l'accessibilité.", objectives: ["Structurer une page avec les balises sémantiques", "Construire un formulaire accessible", "Renseigner rôles et textes alternatifs"] },
  { track: T.web, n: 2, slug: "css-mise-en-page", title: "CSS moderne : mise en page et composants", summary: "Flexbox, grid, variables CSS et adaptation aux écrans.", objectives: ["Composer une mise en page avec flexbox et grid", "Créer un thème avec les variables CSS", "Adapter l'affichage aux petits écrans"] },
  { track: T.web, n: 3, slug: "javascript-dom", title: "JavaScript et DOM : rendre une page vivante", summary: "Sélectionner, modifier le DOM et gérer les événements.", objectives: ["Modifier le contenu de la page avec JavaScript", "Attacher des gestionnaires d'événements", "Valider une saisie côté client"] },
  { track: T.web, n: 4, slug: "javascript-asynchrone", title: "JavaScript applicatif : données et asynchrone", summary: "Tableaux, fonctions et appels d'API avec fetch.", objectives: ["Transformer des données avec map, filter et reduce", "Écrire des fonctions asynchrones avec async/await", "Consommer une API REST avec fetch"] },
  { track: T.web, n: 5, slug: "git-npm", title: "Git et npm : outiller son développement", summary: "Versionner son code et gérer les dépendances.", objectives: ["Committer et pousser avec Git", "Travailler en branches et résoudre un conflit", "Initialiser un projet npm"] },
  { track: T.web, n: 6, slug: "react-fondamentaux", title: "React : composants, état et props", summary: "Décomposer une interface en composants réutilisables.", objectives: ["Découper une interface en composants", "Passer des données avec les props", "Gérer l'état local avec useState"] },
  { track: T.web, n: 7, slug: "react-applications", title: "React avancé : routes, formulaires et API", summary: "Navigation, formulaires contrôlés et données distantes.", objectives: ["Structurer une navigation avec le routeur", "Lier formulaires et état", "Charger des données au montage du composant"] },
  { track: T.web, n: 8, slug: "projet-web", title: "Projet : du design au déploiement", summary: "Livrer une application complète prête en ligne.", objectives: ["Préparer la mise en production", "Améliorer performances et référencement", "Déployer le projet en ligne"] },

  // --- Cybersécurité fondamentaux (7) ---
  { track: T.cyb, n: 1, slug: "paysage-menaces", title: "Paysage des menaces : attaquants et vecteurs", summary: "Motivations, acteurs et principales familles d'attaques.", objectives: ["Identifier les principales familles de malwares", "Reconnaître les étapes d'une cyberattaque", "Distinguer phishing et ingénierie sociale"] },
  { track: T.cyb, n: 2, slug: "identites-acces", title: "Identités et accès : mots de passe et MFA", summary: "Authentifier les utilisateurs et limiter les privilèges.", objectives: ["Appliquer les règles d'un mot de passe robuste", "Configurer une double authentification", "Pratiquer le moindre privilège"] },
  { track: T.cyb, n: 3, slug: "reseau-defense", title: "Réseau défensif : pare-feu, TLS et VPN", summary: "Fermer les ports, chiffrer les échanges et segmenter.", objectives: ["Lire et écrire des règles de pare-feu", "Vérifier le chiffrement TLS d'un service", "Distinguer les usages d'un VPN"] },
  { track: T.cyb, n: 4, slug: "durcissement-systeme", title: "Durcissement d'un système", summary: "Mettre à jour, restreindre les accès et journaliser.", objectives: ["Prioriser les mises à jour de sécurité", "Réduire la surface d'attaque", "Collecter et exploiter les journaux"] },
  { track: T.cyb, n: 5, slug: "securite-applicative", title: "Sécurité applicative : OWASP Top 10", summary: "Injection, XSS, CSRF : les pièges et leurs parades.", objectives: ["Prévenir les injections de requêtes et de commandes", "Neutraliser les failles XSS", "Protéger les formulaires contre le CSRF"] },
  { track: T.cyb, n: 6, slug: "detection-reponse", title: "Détection et réponse à incident", summary: "Surveiller, alerter, contenir et rétablir.", objectives: ["Mettre en place des alertes utiles", "Constituer la chronologie d'un incident", "Appliquer les étapes de la réponse"] },
  { track: T.cyb, n: 7, slug: "conformite-continuite", title: "Conformité, sauvegardes et continuité", summary: "Politiques, sauvegarde 3-2-1 et reprise d'activité.", objectives: ["Écrire une politique de sécurité exploitable", "Organiser une sauvegarde 3-2-1 testée", "Préparer un plan de reprise d'activité"] },

  // --- Réseaux, protocoles, routage (7) ---
  { track: T.net, n: 1, slug: "osi-adressage", title: "Modèle OSI et adressage IP", summary: "Les couches, IPv4/IPv6 et le calcul de sous-réseaux.", objectives: ["Situer un protocole dans le modèle OSI", "Calculer masque et plage d'adresses", "Planifier des sous-réseaux en VLSM"] },
  { track: T.net, n: 2, slug: "ethernet-vlan", title: "Ethernet, VLAN et ARP", summary: "Commutation, segmentation et résolution d'adresses.", objectives: ["Segmenter un réseau en VLAN", "Décrire le fonctionnement d'ARP", "Maîtriser les orages de broadcast"] },
  { track: T.net, n: 3, slug: "transport-applicatif", title: "TCP, UDP et services applicatifs", summary: "Ports, DNS, DHCP, HTTP/TLS de bout en bout.", objectives: ["Comparer les mécanismes de TCP et UDP", "Diagnostiquer une résolution DNS", "Suivre un bail DHCP et une session TLS"] },
  { track: T.net, n: 4, slug: "routage-ospf", title: "Routage statique et OSPF", summary: "Tables de routage et protocole à état de lien.", objectives: ["Écrire des routes statiques précises", "Établir une adjacence OSPF", "Interpréter une table de routage"] },
  { track: T.net, n: 5, slug: "routage-avance", title: "Routage avancé : ACL, NAT et redondance", summary: "Filtrer le trafic, traduire les adresses et basculer.", objectives: ["Rédiger des ACL filtrantes", "Configurer NAT et PAT", "Assurer la redondance de la passerelle"] },
  { track: T.net, n: 6, slug: "supervision-depannage", title: "Supervision et dépannage réseau", summary: "Mesurer, tracer, alerter et diagnostiquer.", objectives: ["Exploiter ping, traceroute et tcpdump", "Mettre en place SNMP et des alertes", "Suivre une méthode de dépannage structurée"] },
  { track: T.net, n: 7, slug: "securite-reseau", title: "Sécurité réseau opérationnelle", summary: "802.1X, VPN site-à-site et durcissement des équipements.", objectives: ["Contrôler l'accès avec 802.1X", "Administrer un VPN site-à-site", "Durcir un switch et un routeur"] },

  // --- IA et Data Science (8) ---
  { track: T.ia, n: 1, slug: "exploration-donnees", title: "Exploration et nettoyage des données", summary: "pandas, qualité des données et visualisation.", objectives: ["Charger et inspecter un jeu de données", "Nettoyer valeurs manquantes et doublons", "Produire des graphiques exploratoires"] },
  { track: T.ia, n: 2, slug: "statistiques-ml", title: "Statistiques pour le machine learning", summary: "Distributions, corrélations et pièges de mesure.", objectives: ["Résumer une distribution par ses mesures", "Interpréter une corrélation sans la surinterpréter", "Éviter les fuites de données"] },
  { track: T.ia, n: 3, slug: "regression", title: "Régression : prédire une valeur continue", summary: "Modèle linéaire, erreurs et interprétation.", objectives: ["Entraîner une régression linéaire", "Interpréter coefficients et R²", "Comparer RMSE et MAE"] },
  { track: T.ia, n: 4, slug: "classification", title: "Classification : prédire une catégorie", summary: "Régression logistique, arbres et matrice de confusion.", objectives: ["Entraîner un classifieur de base", "Lire une matrice de confusion", "Choisir un bon seuil de décision"] },
  { track: T.ia, n: 5, slug: "clustering-acp", title: "Clustering et réduction de dimension", summary: "k-means, ACP et lecture des groupes.", objectives: ["Segmenter des données avec k-means", "Réduire la dimensionnalité par ACP", "Valider la pertinence des clusters"] },
  { track: T.ia, n: 6, slug: "validation-robustesse", title: "Validation et robustesse des modèles", summary: "Surapprentissage, validation croisée et régularisation.", objectives: ["Découper train, validation et test", "Pratiquer la validation croisée", "Détecter et corriger le surapprentissage"] },
  { track: T.ia, n: 7, slug: "mise-en-production", title: "Mise en production d'un modèle", summary: "API de prédiction, versionnage et suivi en continu.", objectives: ["Sérialiser un modèle entraîné", "Exposer une API de prédiction", "Suivre la dérive des données"] },
  { track: T.ia, n: 8, slug: "ia-generative", title: "IA générative : LLM et recherche augmentée", summary: "Prompt, embeddings et pipeline RAG.", objectives: ["Structurer un prompt efficace", "Comprendre le rôle des embeddings", "Construire un pipeline RAG simple"] },

  // --- Arduino et ESP32 (6) ---
  { track: T.ard, n: 1, slug: "gpio-premiers-pas", title: "Premiers pas : GPIO, LED et bouton", summary: "Câblage, clignotement et lecture d'une entrée.", objectives: ["Câbler une LED avec sa résistance", "Programmer un clignotement", "Lire un bouton sans rebond"] },
  { track: T.ard, n: 2, slug: "capteurs-actionneurs", title: "Capteurs et actionneurs", summary: "Lecture analogique, PWM et capteurs usuels.", objectives: ["Lire un capteur analogique", "Régler un duty cycle en PWM", "Afficher une mesure sur le moniteur série"] },
  { track: T.ard, n: 3, slug: "afficheurs-bus", title: "Afficheurs et bus de communication", summary: "Écran LCD, I2C, SPI et port série.", objectives: ["Afficher du texte sur un LCD", "Échanger en I2C avec un capteur", "Distinguer les usages de I2C et SPI"] },
  { track: T.ard, n: 4, slug: "automates-etats", title: "Automates : machine à états et interruptions", summary: "Programmer comme un automate industriel.", objectives: ["Modéliser une machine à états", "Gérer des interruptions matérielles", "Planifier des temporisations non bloquantes"] },
  { track: T.ard, n: 5, slug: "esp32-connecte", title: "ESP32 connecté : Wi-Fi, web et MQTT", summary: "Mettre l'objet sur le réseau.", objectives: ["Connecter l'ESP32 en Wi-Fi", "Servir une page web depuis la puce", "Publier des mesures en MQTT"] },
  { track: T.ard, n: 6, slug: "projet-connecte", title: "Projet connecté : du capteur au tableau de bord", summary: "Automate complet, publication et supervision.", objectives: ["Concevoir l'architecture du système", "Publier et stocker les mesures", "Présenter un tableau de bord simple"] },
];

const rows = CHAPTERS.map((chapter) => {
  const conf = TRACKS[chapter.track];
  const level = chapter.n <= conf.levelBreak ? "debutant" : "intermediaire";
  return {
    id: `${conf.prefix}${chapter.n}`,
    track_id: chapter.track,
    level,
    slug: chapter.slug,
    title: chapter.title,
    summary: chapter.summary,
    objectives: chapter.objectives,
    position: chapter.n,
  };
});

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
      `(${q(row.id)}, ${q(row.track_id)}, ${q(row.level)}, ${q(row.slug)}, ${q(row.title)}, ${q(row.summary)}, ${arr(row.objectives)}, '[]'::jsonb, ${row.position})`,
  )
  .join(",\n");

const sql = `-- easyLearn — structure des 5 parcours (chapitres squelette)
-- Titres, résumés, objectifs, positions, niveaux — contenus (leçons, exercices,
-- quiz, ressources) rédigés chapitre par chapitre ensuite.
-- Idempotent : on conflict (id) do nothing — ne touche jamais aux contenus
-- déjà écrits. Vidéos : '[]' → pas de bloc « Vidéos » (5 étapes par chapitre).
-- Généré par scripts/generate-track-structure.mjs — ne pas éditer à la main.

update public.tracks set passing_score = 70
where id in (${Object.values(T).map(q).join(", ")});

insert into public.chapters
  (id, track_id, level, slug, title, summary, objectives, videos, position, published)
values
${values}
on conflict (id) do nothing;
`;

writeFileSync(OUT, sql, "utf8");
console.log(`✓ ${rows.length} chapitres → ${OUT} (${sql.length} octets)`);

if (process.argv.includes("--apply")) {
  const { url, key } = serviceEnv();
  if (!url || !key) {
    console.error("Environnement REST absent de .env.local");
    process.exit(1);
  }
  const payload = rows.map((row) => ({ ...row, videos: [], published: true }));
  const response = await fetch(`${url}/rest/v1/chapters?on_conflict=id`, {
    method: "POST",
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      Prefer: "resolution=ignore-duplicates",
    },
    body: JSON.stringify(payload),
  });
  if (!response.ok && response.status !== 201) {
    console.error("✗ insertion REST :", response.status, (await response.text()).slice(0, 300));
    process.exit(1);
  }
  console.log("✓ chapitres insérés via REST (conflits ignorés)");
}
