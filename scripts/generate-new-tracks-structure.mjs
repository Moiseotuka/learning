/**
 * Structure des 8 NOUVEAUX parcours (chapitres squelette, 6 chapitres chacun)
 * + catégorie « Bases de données » + lignes tracks. Contenus (leçons, exercices,
 * quiz, ressources) rédigés chapitre par chapitre ensuite (vagues).
 *
 * Émet supabase/migrations/202610070001_new_tracks_structure.sql
 * (idempotent : on conflict do nothing — ne touche jamais aux contenus).
 *
 * Usage : node scripts/generate-new-tracks-structure.mjs
 */
import { writeFileSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(new URL("..", import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, "$1"));
const OUT = resolve(ROOT, "supabase/migrations/202610070001_new_tracks_structure.sql");

const T = {
  algo: "algorithmique-fondamentaux",
  sql: "bases-donnees-sql",
  do: "devops-cloud",
  off: "cybersecurite-offensive",
  mob: "mobile-flutter-react-native",
  jv: "java-spring-backend",
  php: "php-modern",
  dj: "django-web",
};

/** position : niveau de départ, levelBreak : n derniers chapitres intermédiaires */
const TRACKS = {
  [T.algo]: { prefix: "algo-c", level: "debutant", levelBreak: 3, position: 7, duration: 40, modules: 24, price: 49, rating: 4.7, students: 520, description: "Maîtriser la complexité, les structures de données et les grands paradigmes" },
  [T.sql]: { prefix: "db-c", level: "debutant", levelBreak: 3, position: 8, duration: 36, modules: 24, price: 49, rating: 4.7, students: 480, description: "Modéliser, interroger et optimiser une base relationnelle" },
  [T.do]: { prefix: "do-c", level: "intermediaire", levelBreak: 2, position: 9, duration: 50, modules: 28, price: 69, rating: 4.8, students: 410, description: "Automatiser le livrable, conteneuriser et exploiter en production" },
  [T.off]: { prefix: "off-c", level: "intermediaire", levelBreak: 2, position: 10, duration: 46, modules: 26, price: 79, rating: 4.8, students: 380, description: "Penser comme un attaquant pour renforcer la défense (laboratoires dédiés)" },
  [T.mob]: { prefix: "mob-c", level: "debutant", levelBreak: 3, position: 11, duration: 55, modules: 28, price: 59, rating: 4.6, students: 450, description: "Concevoir des applications mobiles avec Flutter et React Native" },
  [T.jv]: { prefix: "jv-c", level: "debutant", levelBreak: 3, position: 12, duration: 52, modules: 26, price: 59, rating: 4.7, students: 640, description: "Construire des back-ends robustes avec Java et Spring Boot" },
  [T.php]: { prefix: "php-c", level: "debutant", levelBreak: 3, position: 13, duration: 38, modules: 24, price: 45, rating: 4.5, students: 520, description: "Développer des sites et APIs avec PHP moderne et sécurisé" },
  [T.dj]: { prefix: "dj-c", level: "debutant", levelBreak: 3, position: 14, duration: 42, modules: 24, price: 49, rating: 4.6, students: 430, description: "Livrer des applications web complètes avec Django" },
};

const CHAPTERS = [
  // --- Algorithmique fondamentaux (6) ---
  { track: T.algo, n: 1, slug: "complexite-analyse", title: "Complexité : analyser un algorithme", summary: "Big-O, cas pires et amortis, mesure du coût réel.", objectives: ["Exprimer la complexité d'une boucle et d'une récursion", "Comparer deux algorithmes en Big-O", "Choisir la solution adaptée au volume de données"] },
  { track: T.algo, n: 2, slug: "structures-donnees", title: "Structures de données : piles, files, hachage", summary: "Implémenter et exploiter les conteneurs de base.", objectives: ["Implémenter une pile et une file", "Choisir entre liste chaînée et tableau", "Raisonner sur les coût d'accès d'un tableau de hachage"] },
  { track: T.algo, n: 3, slug: "recherche-tris", title: "Recherche et tri : dichotomie, fusion, rapide", summary: "Les tris classiques et leur mise en œuvre.", objectives: ["Implémenter la recherche dichotomique", "Décrire le tri fusion et le tri rapide", "Analyser la stabilité et le coût d'un tri"] },
  { track: T.algo, n: 4, slug: "graphes-parcours", title: "Graphes : parcours et plus courts chemins", summary: "BFS, DFS, dijkstra et représentations.", objectives: ["Représenter un graphe en matrice et en listes", "Parcourir en largeur et en profondeur", "Calculer un plus court chemin pondéré"] },
  { track: T.algo, n: 5, slug: "recursivite-dp", title: "Récursivité et programmation dynamique", summary: "Décomposer, mémoïser et optimiser.", objectives: ["Écrire une récursion correcte avec cas d'arrêt", "Mémoïser un sous-problème répété", "Résoudre un problème type sac à dos en DP"] },
  { track: T.algo, n: 6, slug: "projet-algorithmique", title: "Projet : résoudre, mesurer, présenter", summary: "Choisir une stratégie, coder, benchmark et expliquer.", objectives: ["Choisir l'algorithme selon les contraintes", "Construire un banc de mesure simple", "Justifier sa solution à l'oral"] },

  // --- Bases de données & SQL (6) ---
  { track: T.sql, n: 1, slug: "modele-donnees", title: "Modéliser : entités, relations, normalisation", summary: "Du besoin métier au schéma relationnel.", objectives: ["Modéliser un cas en entités et associations", "Poser cardinalités et clés", "Normaliser jusqu'à la 3FN"] },
  { track: T.sql, n: 2, slug: "sql-select", title: "SQL : SELECT, filtres, tri et agrégats", summary: "Lire des données avec précision.", objectives: ["Écrire filtres, tris et sous-requêtes simples", "Agréger avec GROUP BY et HAVING", "Formater les résultats avec CASE"] },
  { track: T.sql, n: 3, slug: "jointures-vues", title: "Jointures, sous-requêtes et vues", title2: null, summary: "Relier les tables et réutiliser les requêtes.", objectives: ["Joinner plusieurs tables sans doublons", "Écrire une vue réutilisable", "Résoudre les requêtes en étapes"] },
  { track: T.sql, n: 4, slug: "ecritures-transactions", title: "Écritures et transactions", summary: "INSERT, UPDATE, DELETE et cohérence.", objectives: ["Écrire des mises à jour fiables", "Encadrer plusieurs écritures en transaction", "Gérer les conflits de concurrence"] },
  { track: T.sql, n: 5, slug: "index-optimisation", title: "Index et plans d'exécution", summary: "Comprendre pourquoi une requête est lente.", objectives: ["Lire un plan d'exécution", "Choisir les bons index", "Éliminer les requêtes en sélectivité nulle"] },
  { track: T.sql, n: 6, slug: "projet-sql", title: "Projet : schéma complet et analyses", summary: "Modéliser, peupler, interroger de bout en bout.", objectives: ["Concevoir un schéma normalisé complet", "Peupler avec des données crédibles", "Produire un jeu de rapports métier"] },

  // --- DevOps & Cloud (6) ---
  { track: T.do, n: 1, slug: "linux-automatisation", title: "Linux et automatisation de base", summary: "Shell, services, journaux et SSH au quotidien.", objectives: ["Automatiser une tâche avec un script shell", "Diagnostiquer un service systemd", "Travailler à distance en SSH sûr"] },
  { track: T.do, n: 2, slug: "git-cicd", title: "Git avancé et intégration continue", summary: "Flux de travail, revue et pipeline.", objectives: ["Structurer des branches et tags", "Éviter les conflits de fusion", "Construire un pipeline CI qui teste à chaque push"] },
  { track: T.do, n: 3, slug: "docker-conteneurs", title: "Docker : images, volumes, réseaux", summary: "Conteneuriser une application de bout en bout.", objectives: ["Écrire un Dockerfile efficace", "Persister les données avec des volumes", "Composer plusieurs services"] },
  { track: T.do, n: 4, slug: "kubernetes-deploiements", title: "Kubernetes : déploiements et services", summary: "Orchestrer, faire évoluer et réparer.", objectives: ["Déployer une application en pods", "Exposer et répartir la charge", "Effectuer un déploiement sans interruption"] },
  { track: T.do, n: 5, slug: "infra-as-code", title: "Infrastructure as code : Terraform", summary: "Décrire le cloud en code versionné.", objectives: ["Déclarer des ressources Terraform", "Gérer l'état et les variables", "Appliquer un changement de façon reproductible"] },
  { track: T.do, n: 6, slug: "observabilite-sre", title: "Observabilité et SRE", summary: "Métriques, alertes utiles et objectifs de service.", objectives: ["Poser des métriques et tableaux de bord", "Configurer des alertes non bruyantes", "Définir SLO et pratiquer les post-mortems"] },

  // --- Cybersécurité offensive (6) ---
  { track: T.off, n: 1, slug: "reconnaissance", title: "Reconnaissance et cartographie", summary: "Collecter l'information sans se déclarer.", objectives: ["Recenser les surfaces exposées d'une cible", "Distinguer OSINT passive et active", "Documenter la méthodologie"] },
  { track: T.off, n: 2, slug: "analyse-vulnerabilites", title: "Analyse de vulnérabilités web", summary: "Scanner, valider, hiérarchiser sans faux positifs.", objectives: ["Scanner une application en environnement de test", "Valider manuellement un signalement", "Classer selon CVSS et contexte"] },
  { track: T.off, n: 3, slug: "exploitation-lab", title: "Exploitation contrôlée en laboratoire", summary: "Passer du signalement au proof-of-concept (lab dédié).", objectives: ["Reproduire une faille OWASP en local", "Écrire un preuve de concept minimale", "Rester strictement dans un périmètre autorisé"] },
  { track: T.off, n: 4, slug: "post-exploitation", title: "Post-exploitation : privilèges et latéral", summary: "Après l'accès initial, en environnement simulé.", objectives: ["Diagnostiquer un vecteur d'élévation", "Cartographier le mouvement latéral", "Appliquer la règle du moindre mouvement"] },
  { track: T.off, n: 5, slug: "rapport-remediation", title: "Rapport de pentest et remédiation", summary: "Transformer une découverte en correctif priorisé.", objectives: ["Rédiger un rapport exploitable par l'équipe", "Proposer un correctif concret", "Présenter les risques à un décideur"] },
  { track: T.off, n: 6, slug: "offensive-defense", title: "Offensive au service de la défense", summary: "Tests d'intrusion réguliers, purple team, veille.", objectives: ["Planifier des campagnes régulières", "Retourner les découvertes en règles de détection", "Maintenir un programme de test continu"] },

  // --- Mobile Flutter & React Native (6) ---
  { track: T.mob, n: 1, slug: "fondamentaux-mobile", title: "Fondamentaux du développement mobile", summary: "Écrans, navigation, état et contraintes tactiles.", objectives: ["Structurer la navigation entre écrans", "Gérer l'état partagé simplement", "Adapter aux gestes et au clavier virtuel"] },
  { track: T.mob, n: 2, slug: "flutter-bases", title: "Flutter : layout, listes, thème", summary: "Construire des interfaces avec les widgets.", objectives: ["Composer un layout avec Row/Column/Stack", "Afficher des listes performantes", "Unifier le style avec un thème"] },
  { track: T.mob, n: 3, slug: "flutter-avance", title: "Flutter : état, formulaires et API", summary: "Données distantes et gestion d'erreurs.", objectives: ["Piloter l'état avec un pattern clair", "Valider des formulaires", "Consommer une API et gérer l'offline"] },
  { track: T.mob, n: 4, slug: "react-native-bases", title: "React Native : composants et navigation", summary: "Le même métier avec l'écosystème JS.", objectives: ["Composer des composants React Native", "Structurer l'application avec un routeur", "Styler avec StyleSheet"] },
  { track: T.mob, n: 5, slug: "react-native-avance", title: "React Native : données, perf, publication", summary: "Rendre l'app fluide et la publier.", objectives: ["Optimiser les listes longues", "Gérer stockage local et API", "Préparer la publication sur les stores"] },
  { track: T.mob, n: 6, slug: "projet-mobile", title: "Projet : une app sur les deux écosystèmes", summary: "Livrer la même fonctionnalité en Flutter et RN.", objectives: ["Extraire le périmètre commun", "Livrer l'app sur un écosystème", "Comparer objectivement les deux retours d'expérience"] },

  // --- Java / Spring backend (6) ---
  { track: T.jv, n: 1, slug: "java-moderne", title: "Java moderne : types, classes, records", summary: "Syntaxe, objet et bibliothèque standard.", objectives: ["Modéliser avec classes et records", "Exploiter la portée et l'initialisation", "Utiliser Optional avec mesure"] },
  { track: T.jv, n: 2, slug: "java-avance", title: "Collections, génériques, exceptions", summary: "La boîte à outils du développeur Java.", objectives: ["Choisir la bonne collection", "Écrire du code générique sûr", "Gérer les exceptions de façon exploitable"] },
  { track: T.jv, n: 3, slug: "spring-boot-api", title: "Spring Boot : créer une API REST", summary: "Contrôleurs, validation et documentation.", objectives: ["Exposer des endpoints propres", "Valider les entrées", "Structurer service/contrôleur"] },
  { track: T.jv, n: 4, slug: "jpa-persistance", title: "Persistance avec JPA et Hibernate", summary: "Entités, requêtes et transactions.", objectives: ["Mapper des entités relationnelles", "Écrire des requêtes JPQL/Criteria", "Gérer les transactions"] },
  { track: T.jv, n: 5, slug: "securite-tests", title: "Sécurité, validation et tests", summary: "Protéger l'API et la vérifier.", objectives: ["Sécuriser avec Spring Security", "Écrire des tests unitaires et WebMvc", "Tester la couche persistance"] },
  { track: T.jv, n: 6, slug: "projet-spring", title: "Projet : service complet", summary: "Une API de bout en bout avec base de données.", objectives: ["Concevoir l'architecture du service", "Livrer CRUD + sécurité + tests", "Dockeriser et documenter"] },

  // --- PHP moderne (6) ---
  { track: T.php, n: 1, slug: "php-bases", title: "PHP moderne : syntaxe, types, tableaux", summary: "Langage, typage strict et structures de données.", objectives: ["Écrire du PHP typé et lisible", "Manipuler tableaux et fonctions fléchées", "Comprendre la gestion mémoire des scripts"] },
  { track: T.php, n: 2, slug: "formulaires-securite", title: "Formulaires, sessions et sécurité", summary: "Recevoir des saisies sans s'exposer.", objectives: ["Valider et assainir les saisies", "Protéger contre CSRF et XSS", "Gérer sessions et authentification"] },
  { track: T.php, n: 3, slug: "poo-mvc", title: "POO et architecture MVC", summary: "Sortir du script plat.", objectives: ["Découper en contrôleurs, modèles, vues", "Appliquer SPL et interfaces utiles", "Structurer un projet MVC"] },
  { track: T.php, n: 4, slug: "pdo-base-donnees", title: "Base de données avec PDO", summary: "Requêtes préparées et transactions.", objectives: ["Se connecter en PDO", "Écrire des requêtes préparées", "Encadrer les écritures en transaction"] },
  { track: T.php, n: 5, slug: "api-composer", title: "API PHP, Composer et outillage", summary: "Autoloading, dépendances et tests.", objectives: ["Gérer les dépendances avec Composer", "Exposer une API JSON propre", "Lancer PHPUnit"] },
  { track: T.php, n: 6, slug: "projet-php", title: "Projet : CRUD complet sécurisé", summary: "Application avec auth, CRUD et tests.", objectives: ["Assembler auth et CRUD", "Appliquer le pare-feu applicatif", "Préparer la mise en ligne"] },

  // --- Django (6) ---
  { track: T.dj, n: 1, slug: "django-bases", title: "Django : projet, apps et ORM", summary: "Convention, modèles et migrations.", objectives: ["Structurer un projet en applications", "Modéliser avec l'ORM", "Appliquer et lire des migrations"] },
  { track: T.dj, n: 2, slug: "vues-templates", title: "Vues, templates et formulaires", summary: "Rendu serveur et saisies validées.", objectives: ["Écrire des vues fonctionnelles et class-based", "Composer des templates réutilisables", "Valider avec Django Forms"] },
  { track: T.dj, n: 3, slug: "api-drf", title: "API avec Django REST Framework", summary: "Serializers, routes et permissions.", objectives: ["Exposer un modèle en API REST", "Paginer et filtrer", "Tester l'API"] },
  { track: T.dj, n: 4, slug: "admin-auth", title: "Administration, rôles et authentification", summary: "Back-office et droits.", objectives: ["Personnaliser l'admin", "Gérer groupes et permissions", "Brancher l'auth par jeton"] },
  { track: T.dj, n: 5, slug: "tests-performance", title: "Tests, performance et cache", summary: "Vérifier et accélérer.", objectives: ["Écrire des tests de vues", "Profiler les requêtes N+1", "Mettre en place le cache"] },
  { track: T.dj, n: 6, slug: "projet-django", title: "Projet : application complète", summary: "Du modèle à la mise en ligne.", objectives: ["Livrer CRUD + API + droits", "Sécuriser les en-têtes et formulaires", "Déployer derrière un serveur WSGI"] },
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

const trackRows = Object.entries(TRACKS)
  .map(
    ([id, c]) =>
      `  (${q(id)}, ${q(id === T.sql ? "db" : id === T.algo || id === T.jv ? "prog" : id === T.do ? "cloud" : id === T.off ? "cyber" : "web")}, ${q(id)}, ${q(titleOf(id))}, ${q(c.description)}, ${q(c.level)}, ${c.duration}, ${c.modules}, ${c.price}, ${c.rating}, ${c.students}, ${c.position}, true)`,
  )
  .join(",\n");

function titleOf(id) {
  return {
    [T.algo]: "Algorithmique : structures de données et complexité",
    [T.sql]: "Bases de données et SQL : de la maquette aux rapports",
    [T.do]: "DevOps et Cloud : livrer et exploiter en production",
    [T.off]: "Cybersécurité offensive : tester pour mieux défendre",
    [T.mob]: "Mobile : Flutter et React Native en pratique",
    [T.jv]: "Java et Spring Boot : back-ends professionnels",
    [T.php]: "PHP moderne : sites et APIs sécurisés",
    [T.dj]: "Django : applications web complètes",
  }[id];
}

const values = rows
  .map(
    (row) =>
      `(${q(row.id)}, ${q(row.track_id)}, ${q(row.level)}, ${q(row.slug)}, ${q(row.title)}, ${q(row.summary)}, ${arr(row.objectives)}, '[]'::jsonb, ${row.position}, true)`,
  )
  .join(",\n");

const sql = `-- easyLearn — structure des 8 nouveaux parcours (48 chapitres squelette)
-- + catégorie « Bases de données » (db). Contenus rédigés ensuite par vagues.
-- Idempotent : on conflict (id) do nothing — ne touche jamais aux contenus.
-- Généré par scripts/generate-new-tracks-structure.mjs — ne pas éditer à la main.

insert into public.categories (id, slug, name, description, icon, levels, track_count, position) values
  ('db', 'bases-de-donnees', 'Bases de données', 'Modélisation, SQL, optimisation et administration de données.', 'database', array['debutant','intermediaire','avance'], 1, 11)
on conflict (id) do nothing;

insert into public.tracks (id, category_id, slug, title, description, level, duration_hours, modules_count, price_usd, rating, students, position, published) values
${trackRows}
on conflict (id) do nothing;

insert into public.chapters
  (id, track_id, level, slug, title, summary, objectives, videos, position, published)
values
${values}
on conflict (id) do nothing;
`;

writeFileSync(OUT, sql, "utf8");
console.log(`✓ ${Object.keys(TRACKS).length} tracks + ${rows.length} chapitres → ${OUT} (${sql.length} octets)`);
