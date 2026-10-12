export type LevelType = "debutant" | "intermediaire" | "avance" | "projet";

export type Category = {
  id: string;
  slug: string;
  name: string;
  description: string;
  icon: string;
  /** Niveaux dont les parcours sont publiés (permet le filtre par niveau). */
  levels: LevelType[];
  trackCount: number;
};

export const levels: LevelType[] = ["debutant", "intermediaire", "avance", "projet"];

/**
 * Repli hors ligne du catalogue : miroir des catégories publiées en base.
 * La source de vérité reste Supabase (back-office) ; ces valeurs ne servent que
 * lorsque Supabase n'est pas configuré, et sont donc alignées sur la production.
 */
export const categories: Category[] = [
  {
    id: "prog",
    slug: "programmation",
    name: "Programmation",
    description:
      "Algorithmique, Python, Java, C#, C++, C, Pascal, JavaScript, HTML, CSS, SQL, PHP.",
    icon: "terminal",
    levels: ["debutant", "intermediaire", "avance"],
    trackCount: 7,
  },
  {
    id: "web",
    slug: "developpement-web-mobile",
    name: "Développement web et mobile",
    description:
      "Interfaces responsive, APIs, frameworks front-end et applications mobiles.",
    icon: "layout",
    levels: ["debutant", "intermediaire", "avance"],
    trackCount: 8,
  },
  {
    id: "ai",
    slug: "ia-data",
    name: "Intelligence artificielle et data",
    description: "Machine learning, data science, analyse et modèles prédictifs.",
    icon: "brain",
    levels: ["debutant", "intermediaire", "avance"],
    trackCount: 3,
  },
  {
    id: "cyber",
    slug: "cybersecurite",
    name: "Cybersécurité",
    description:
      "Menaces, durcissement des systèmes, investigation et bonnes pratiques.",
    icon: "shield",
    levels: ["debutant", "intermediaire", "avance"],
    trackCount: 2,
  },
  {
    id: "net",
    slug: "reseaux-telecoms",
    name: "Réseaux et télécommunications",
    description: "Câblage, adressage, routage, wireless et supervision.",
    icon: "network",
    levels: ["debutant", "intermediaire", "avance"],
    trackCount: 1,
  },
  {
    id: "embedded",
    slug: "systemes-embarques",
    name: "Systèmes embarqués",
    description: "Arduino, ESP32, STM32, capteurs et interfaçage temps réel.",
    icon: "cpu",
    levels: ["debutant", "intermediaire", "avance"],
    trackCount: 2,
  },
  {
    id: "electronics",
    slug: "electronique",
    name: "Électronique",
    description: "Composants, schémas, mesure et prototypage de circuits.",
    icon: "circuit",
    levels: ["debutant", "intermediaire"],
    trackCount: 1,
  },
  {
    id: "physics",
    slug: "physique-appliquee",
    name: "Physique appliquée",
    description: "Mécanique, électricité et expérimentation guidée.",
    icon: "atom",
    levels: [],
    trackCount: 0,
  },
  {
    id: "mecha",
    slug: "mecatronique-robotique",
    name: "Mécatronique et robotique",
    description: "Automatisme, actionneurs, capteurs et robotique mobile.",
    icon: "robot",
    levels: [],
    trackCount: 0,
  },
  {
    id: "cloud",
    slug: "cloud-devops",
    name: "Cloud et DevOps",
    description: "Conteneurs, CI/CD, infrastructure as code et observabilité.",
    icon: "cloud",
    levels: ["debutant", "intermediaire"],
    trackCount: 1,
  },
  {
    id: "ecom",
    slug: "e-commerce",
    name: "E-commerce et paiements",
    description: "Paiements, WooCommerce, Odoo, WordPress et vente en ligne.",
    icon: "shopping-cart",
    levels: ["debutant", "intermediaire"],
    trackCount: 3,
  },
  {
    id: "db",
    slug: "bases-de-donnees",
    name: "Bases de données",
    description: "Modélisation, SQL, optimisation et administration de données.",
    icon: "database",
    levels: ["debutant", "intermediaire"],
    trackCount: 1,
  },
];

export type PopularTrack = {
  slug: string;
  title: string;
  categoryId: string;
  category: string;
  levelFrom: LevelType;
  durationHours: number;
  modules: number;
  priceUsd: number | null;
  bestFor: string;
};

export const popularTracks: PopularTrack[] = [
  {
    slug: "python-developpeur",
    title: "Python : du premier script au projet complet",
    categoryId: "prog",
    category: "Programmation",
    levelFrom: "debutant",
    durationHours: 48,
    modules: 32,
    priceUsd: 49,
    bestFor: "Débuter en programmation avec une langue demandée partout",
  },
  {
    slug: "developpement-web-moderne",
    title: "Développement web moderne : HTML, CSS, JavaScript, React",
    categoryId: "web",
    category: "Développement web",
    levelFrom: "debutant",
    durationHours: 60,
    modules: 40,
    priceUsd: 59,
    bestFor: "Concevoir des sites et applications web prêts pour le terrain",
  },
  {
    slug: "cybersecurite-fondamentaux",
    title: "Cybersécurité : fondamentaux et défense des systèmes",
    categoryId: "cyber",
    category: "Cybersécurité",
    levelFrom: "debutant",
    durationHours: 42,
    modules: 28,
    priceUsd: 69,
    bestFor: "Sécuriser un réseau, un serveur ou une application",
  },
  {
    slug: "reseaux-protocoles-routage",
    title: "Réseaux : protocoles, routage et supervision",
    categoryId: "net",
    category: "Réseaux",
    levelFrom: "intermediaire",
    durationHours: 55,
    modules: 36,
    priceUsd: 59,
    bestFor: "Administrer un réseau d'entreprise de bout en bout",
  },
  {
    slug: "ia-data-science",
    title: "Intelligence artificielle et Data Science appliquées",
    categoryId: "ai",
    category: "IA et Data",
    levelFrom: "intermediaire",
    durationHours: 70,
    modules: 44,
    priceUsd: 89,
    bestFor: "Construire et évaluer des modèles sur de vraies données",
  },
  {
    slug: "arduino-esp32-embarque",
    title: "Arduino et ESP32 : systèmes embarqués pratiques",
    categoryId: "embedded",
    category: "Systèmes embarqués",
    levelFrom: "debutant",
    durationHours: 38,
    modules: 26,
    priceUsd: 45,
    bestFor: "Prototyper des objets connectés et des automates",
  },
  {
    slug: "paiement-en-ligne",
    title: "Paiement en ligne : PawaPay, CinetPay, WooCommerce",
    categoryId: "ecom",
    category: "E-commerce et paiements",
    levelFrom: "debutant",
    durationHours: 26,
    modules: 6,
    priceUsd: 79,
    bestFor: "Mettre en place un flux de paiement mobile et sécuritaire",
  },
  {
    slug: "odoo-commerce",
    title: "Odoo : vente, facturation et workflow commercial",
    categoryId: "ecom",
    category: "E-commerce et paiements",
    levelFrom: "intermediaire",
    durationHours: 30,
    modules: 6,
    priceUsd: 89,
    bestFor: "Gérer les commandes, factures et paiements dans un ERP",
  },
  {
    slug: "wordpress-commerce",
    title: "WordPress et WooCommerce : boutique, checkout et sécurité",
    categoryId: "ecom",
    category: "E-commerce et paiements",
    levelFrom: "debutant",
    durationHours: 24,
    modules: 6,
    priceUsd: 69,
    bestFor: "Créer une boutique WordPress fiable et convertissante",
  },
];
