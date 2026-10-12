export type LegalDoc = {
  slug: string;
  title: string;
  updated: string;
  intro: string;
  sections: { heading: string; body: string }[];
};

/** Contenus légaux de base — à faire valider par un conseil juridique avant mise en ligne. */
export const legalDocs: LegalDoc[] = [
  {
    slug: "mentions-legales",
    title: "Mentions légales",
    updated: "30 septembre 2026",
    intro:
      "Les informations ci-dessous identifient l'éditeur de la plateforme easyLearn. Elles doivent être complétées avec les coordonnées juridiques définitives avant la mise en production.",
    sections: [
      {
        heading: "Éditeur du site",
        body: "easyLearn est une plateforme d'apprentissage en ligne éditée par [raison sociale], immatriculée au [registre de commerce], dont le siège est situé à [adresse], Kinshasa, République démocratique du Congo.",
      },
      {
        heading: "Directeur de publication",
        body: "Le directeur de la publication est [nom du responsable], en qualité de représentant légal de l'éditeur.",
      },
      {
        heading: "Hébergement",
        body: "Le site est hébergé par Vercel Inc., 440 N Barranca Ave #4133, Covina, CA 91723, États-Unis, dont les services de base de données et d'authentification sont fournis par Supabase Inc.",
      },
      {
        heading: "Paiements",
        body: "Les paiements Mobile Money et par carte bancaire sont traités par le prestataire nyole. easyLearn ne stocke aucune donnée de carte bancaire.",
      },
      {
        heading: "Propriété intellectuelle",
        body: "Les quiz, exercices, corrections, projets, certificats, textes pédagogiques et éléments graphiques de la plateforme sont la propriété d'easyLearn ou de ses formateurs partenaires. Les ressources externes sont uniquement référencées par lien.",
      },
      {
        heading: "Contact",
        body: "Toute question peut être adressée à contact@easylearn.cd.",
      },
    ],
  },
  {
    slug: "cgu",
    title: "Conditions générales d'utilisation",
    updated: "30 septembre 2026",
    intro:
      "Ces conditions régissent l'accès à la plateforme easyLearn. Elles doivent être relues par un conseil juridique avant publication.",
    sections: [
      {
        heading: "Objet",
        body: "easyLearn fournit des parcours de formation en ligne structurés par niveau, assortis d'exercices, de quiz, de projets et de certificats. L'inscription est gratuite et ouvre l'accès au premier niveau de chaque parcours.",
      },
      {
        heading: "Compte utilisateur",
        body: "L'utilisateur est responsable de la confidentialité de ses identifiants et s'engage à fournir des informations exactes. Un seul compte par personne.",
      },
      {
        heading: "Accès payant",
        body: "Le paiement d'un parcours ou d'un abonnement ouvre l'accès aux niveaux correspondants. Le paiement est confirmé par notre serveur après notification signée du prestataire de paiement.",
      },
      {
        heading: "Résiliation",
        body: "L'abonnement peut être résilié à tout moment ; l'accès reste actif jusqu'à la fin de la période payée. Les conditions de remboursement sont indiquées au moment de l'achat.",
      },
      {
        heading: "Conduite attendue",
        body: "Toute tentative de contournement des mécanismes de déblocage, de partage illicite des accès ou de reproduction des contenus est susceptible d'entraîner la fermeture du compte.",
      },
      {
        heading: "Limitation de responsabilité",
        body: "easyLearn s'efforce d'assurer la disponibilité et l'exactitude du contenu, sans garantir l'obtention d'un emploi ou d'un résultat particulier.",
      },
    ],
  },
  {
    slug: "confidentialite",
    title: "Politique de confidentialité",
    updated: "30 septembre 2026",
    intro:
      "Cette politique décrit les données collectées, leur usage et vos droits. Elle sera alignée sur les exigences locales et internationales applicables avant la mise en production.",
    sections: [
      {
        heading: "Données collectées",
        body: "Nom, adresse e-mail, éventuel numéro de téléphone, progression pédagogique, résultats de quiz, commandes et journaux techniques de connexion.",
      },
      {
        heading: "Finalités",
        body: "Fournir l'accès aux formations, suivre la progression, délivrer les certificats, traiter les paiements, envoyer les notifications pédagogiques et améliorer la plateforme.",
      },
      {
        heading: "Sous-traitants",
        body: "Supabase (base de données, authentification, stockage), Vercel (hébergement), Resend (e-mails transactionnels), nyole (paiements).",
      },
      {
        heading: "Conservation",
        body: "Les données de compte sont conservées tant que le compte est actif ; les données de paiement sont conservées pendant la durée légale applicable.",
      },
      {
        heading: "Vos droits",
        body: "Vous pouvez demander l'accès, la rectification ou la suppression de vos données en écrivant à confidentialite@easylearn.cd.",
      },
      {
        heading: "Cookies",
        body: "Seuls des cookies strictement nécessaires au fonctionnement (session, préférences de thème) sont utilisés à ce stade.",
      },
    ],
  },
  {
    slug: "accessibilite",
    title: "Accessibilité",
    updated: "30 septembre 2026",
    intro:
      "easyLearn vise une expérience utilisable par tous, y compris sur mobile et avec une connexion limitée.",
    sections: [
      {
        heading: "Engagements",
        body: "Contrastes vérifiés dans les deux thèmes, navigation complète au clavier, états de focus visibles, libellés ARIA sur les éléments interactifs.",
      },
      {
        heading: "Respect des préférences",
        body: "Les animations sont désactivées lorsque votre système demande un mouvement réduit, et le mode clair ou sombre suit votre préférence.",
      },
      {
        heading: "Performance",
        body: "Chargement paresseux des vidéos et des images, mise en page mobile d'abord, cible de score Lighthouse supérieur à 90.",
      },
      {
        heading: "Signalement",
        body: "Un obstacle d'accessibilité peut être signalé à accessibilite@easylearn.cd ; nous nous engageons à répondre sous 10 jours ouvrés.",
      },
    ],
  },
  {
    slug: "credits",
    title: "Crédits des leçons vidéo",
    updated: "12 octobre 2026",
    intro:
      "Dans le parcours d'apprentissage, les leçons vidéo sont lues dans notre lecteur : l'apprenant reste sur easyLearn, sans suggestion externe ni lien sortant. Cette intégration sobre ne transfère aucune propriété : les images, le son et la mise en scène restent la propriété de leurs auteurs.",
    sections: [
      {
        heading: "Ce que nous faisons de la vidéo d'un tiers",
        body: "Nous sélectionnons une vidéo dont le sujet correspond à un chapitre, nous l'intégrons dans notre lecteur, puis nous lui donnons un titre pédagogique propre à notre progression. Le chapitre, ses objectifs, son cours écrit, son exercice et son quiz restent notre production.",
      },
      {
        heading: "Ce que nous ne revendiquons pas",
        body: "Le contenu filmé, la voix, les démonstrations et la chaîne qui les publie appartiennent à leurs auteurs. Aucun droit d'exploitation, de reproduction ni de rediffusion n'est revendiqué par easyLearn sur ces vidéos.",
      },
      {
        heading: "Auteurs et chaînes référencés",
        body: "Grafikart, Graven - Développement, Docstring, SimpleTech par Sergio, Yvan Monka, jaicompris Maths, Informatique Sans Complexe !, NOVELCLASS, Hassan EL BAHI, Mohamed Chiny, xavki, MaxCode, Donald Programmeur, Justin Joel Takodjou, Raphaël's Coding Club, Sophiaplustech TV, Laurent Praly, ENGP, MOOC NSI, ETC SCHOOL, Hervé Discours, Liora, Fabien Parrain, DuCodeAuClient, thonain, julien-d, ElectroCodeur, Freddie l'électro-programmeur, Rim Robotique, Parlons Cyber, Bande de Codeurs, Prof. Sabri, Professeur Mohamed YOUSSFI, Les Bons Profs, La minute de code, Malakisi, Michèle Kartner, InfraNerdFR, Foxxpy, Nicolas Galiot, Ludovic Guérin, Odoo, WooCommerce, PawaPay, Stripe, Harvard CS50 et MIT OpenCourseWare.",
      },
      {
        heading: "Retirer une vidéo",
        body: "Un auteur qui souhaite apparaître sous son nom dans le parcours, voir sa vidéo remplacée ou retirée de la sélection peut écrire à credits@easylearn.cd. La modification est appliquée sous 72 heures.",
      },
    ],
  },
];
