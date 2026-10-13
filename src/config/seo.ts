/**
 * Stratégie de mots-clés.
 *
 * L'objectif n'est pas de « remplir des balises » : un internaute qui tape
 * « apprendre cybersécurité en français » doit trouver une page dont le premier
 * paragraphe répond à exactement cette intention, avec un contenu réel derrière.
 * Chaque catégorie du catalogue porte donc la requête principale que son public
 * francophone utilise vraiment, ses variantes longue traîne (là où un site jeune
 * peut réellement se classer), et une phrase d'accroche qui pose le mot-clé dans
 * le premier paragraphe sans sonner comme du remplissage.
 */

export type CategorySeo = {
  /** Requête cible principale. */
  primary: string;
  /** Variantes longue traîne couvertes par le corps de la page. */
  variants: string[];
  /** Accroche indexable : le mot-clé apparaît dans les 200 premiers caractères. */
  intro: string;
};

export const categorySeo: Record<string, CategorySeo> = {
  prog: {
    primary: "apprendre la programmation en français",
    variants: [
      "cours de programmation débutant",
      "apprendre Python sans expérience",
      "algorithme et structure de données cours",
      "formation programmation Kinshasa",
    ],
    intro:
      "Apprendre la programmation en français, du premier « print » jusqu'au code qu'on ose montrer : algorithmique, Python, Java, C, C++, JavaScript et SQL, avec un exercice corrigé à chaque étape.",
  },
  web: {
    primary: "formation développement web et mobile",
    variants: [
      "apprendre HTML CSS JavaScript débutant",
      "formation React en français",
      "développement application mobile cours",
      "créer un site web de zéro",
    ],
    intro:
      "Une formation développement web et mobile complète : HTML, CSS, JavaScript, puis React, Next.js, Vue ou Laravel, jusqu'à mettre en ligne un site que des clients peuvent ouvrir.",
  },
  ai: {
    primary: "formation intelligence artificielle en français",
    variants: [
      "apprendre la data science débutant",
      "cours machine learning français",
      "formation Python data analysis",
      "devenir data analyst sans diplôme",
    ],
    intro:
      "Formation intelligence artificielle et data en français : manipuler des données, entraîner un modèle, lire un résultat et expliquer ce qu'un algorithme décide — en Python, du niveau débutant.",
  },
  cyber: {
    primary: "formation cybersécurité en français",
    variants: [
      "apprendre la cybersécurité débutant",
      "cours sécurité informatique réseau",
      "ethical hacking formation francophone",
      "protéger son système d'exploitation",
    ],
    intro:
      "Apprendre la cybersécurité en français : comprendre une attaque, durcir un système, lire des journaux et mener une analyse méthodique, avec des laboratoires faisables sur une machine ordinaire.",
  },
  net: {
    primary: "formation réseaux et télécommunications",
    variants: [
      "cours réseau informatique débutant",
      "apprendre le routage et le switching",
      "certification réseau francophone",
      "administration réseau d'entreprise",
    ],
    intro:
      "Formation réseaux et télécommunications : câbler, adresser, router, superviser. Le vocabulaire technique et les gestes d'un administrateur réseau, expliqués en français.",
  },
  embedded: {
    primary: "apprendre les systèmes embarqués",
    variants: [
      "cours Arduino en français",
      "programmation ESP32 débutant",
      "formation STM32 francophone",
      "projets capteurs et actionneurs",
    ],
    intro:
      "Apprendre les systèmes embarqués avec Arduino, ESP32 et STM32 : câbler un capteur, écrire le firmware, mesurer le résultat et débugger ce qui ne démarre pas.",
  },
  electronics: {
    primary: "cours d'électronique en français",
    variants: [
      "apprentissage des composants électroniques",
      "lire un schéma électronique",
      "exercices loi d'Ohm et montages",
      "prototypage sur breadboard",
    ],
    intro:
      "Cours d'électronique en français : reconnaître un composant, lire un schéma, calculer, mesurer et monter un circuit qui fonctionne réellement.",
  },
  physics: {
    primary: "physique appliquée en français",
    variants: [
      "cours de mécanique appliqué",
      "électricité et magnétisme exercices",
      "expérimentation physique guidée",
      "physique pour ingénieurs débutants",
    ],
    intro:
      "Physique appliquée : les lois qui expliquent une machine, un circuit ou un mouvement, avec les calculs et l'expérience qui vont avec.",
  },
  mecha: {
    primary: "formation mécatronique et robotique",
    variants: [
      "cours robotique en français",
      "automatisme et capteurs industriels",
      "construire un robot débutant",
      "programmation d'actionneurs",
    ],
    intro:
      "Formation mécatronique et robotique : mécanique, électronique et code réunis sur un même projet, du premier moteur pas à pas jusqu'à un robot mobile qui se déplace.",
  },
  cloud: {
    primary: "formation cloud et DevOps en français",
    variants: [
      "apprendre Docker et Kubernetes",
      "cours CI/CD débutant",
      "administration Linux en français",
      "infrastructures as code Terraform",
    ],
    intro:
      "Formation cloud et DevOps en français : conteneuriser une application, automatiser le déploiement, superviser un serveur Linux et documenter l'infrastructure comme dans une équipe réelle.",
  },
  ecom: {
    primary: "formation e-commerce en français",
    variants: [
      "créer une boutique WooCommerce",
      "cours WordPress boutique en ligne",
      "vendre en ligne avec Odoo",
      "paiement mobile money boutique en ligne",
    ],
    intro:
      "Formation e-commerce et paiements : monter une boutique WordPress ou WooCommerce, encaisser par Mobile Money et carte, gérer stock, livraison et service client.",
  },
  db: {
    primary: "apprendre SQL et les bases de données",
    variants: [
      "cours de base de données débutant",
      "requêtes SQL exercices corrigés",
      "modélisation Merise et diagramme E-A",
      "administrateur de bases de données formation",
    ],
    intro:
      "Apprendre SQL et la modélisation de données : écrire une requête juste, dessiner un schéma qui tient, éviter les doublons et optimiser ce qui traîne.",
  },
};

/** Repli pour une catégorie ajoutée par l'admin sans fiche mots-clés. */
const fallbackSeo = (name: string): CategorySeo => ({
  primary: `formation ${name.toLowerCase()} en français`,
  variants: [`cours ${name.toLowerCase()} débutant`, `apprendre ${name.toLowerCase()}`],
  intro: `Formation ${name.toLowerCase()} en français, structurée par niveaux, avec exercices corrigés, quiz et certificat.`,
});

export function seoFor(categoryId: string, categoryName: string): CategorySeo {
  return categorySeo[categoryId] ?? fallbackSeo(categoryName);
}

/** Titre au gabarit indexable : la requête d'abord, la promesse ensuite. */
export function trackPageTitle(title: string): string {
  return `${title} — formation en ligne en français`;
}

/**
 * Description de 155 caractères environ : Google tronque au-delà, et une
 * description coupée en pleine phrase fait perdre le clic plutôt qu'elle ne le
 * gagne.
 */
export function trackPageDescription(input: {
  title: string;
  category: string;
  chapters: number;
  levelLabel: string;
  priceFrom: string;
}): string {
  const parts = [
    `${input.title} : ${input.chapters} chapitres du niveau ${input.levelLabel.toLowerCase()}, exercices corrigés, quiz obligatoire et certificat vérifiable.`,
    `Accès à partir de ${input.priceFrom}, paiement Mobile Money ou carte.`,
  ];
  return parts.join(" ");
}

/** Filtrages du catalogue : même page, contenu different — à fermer à l'index. */
export const catalogueCanonical = "/catalogue";

/** Titre d'une page domaine : la requête cible, telle qu'elle est tapée. */
export function domainPageTitle(seo: CategorySeo): string {
  return seo.primary.charAt(0).toUpperCase() + seo.primary.slice(1);
}

export function domainPageDescription(input: {
  intro: string;
  tracks: number;
  chapters: number;
  levelsLabel: string;
}): string {
  return `${input.intro} ${input.tracks} ${
    input.tracks > 1 ? "parcours publiés" : "parcours publié"
  }, ${input.chapters} chapitres, ${input.levelsLabel}.`;
}
