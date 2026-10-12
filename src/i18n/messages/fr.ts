export const fr = {
  meta: {
    title: "easyLearn — Apprenez la technologie, prouvez-le",
    description:
      "Plateforme e-learning francophone : parcours structurés du Débutant au Projet final, exercices pratiques, quiz corrigés et certificats vérifiables. Pensée pour l'Afrique francophone et les connexions mobiles.",
  },

  nav: {
    search: "Rechercher un parcours",
    login: "Connexion",
    signup: "S'inscrire",
    menu: "Ouvrir le menu",
    close: "Fermer le menu",
    theme: "Changer de thème",
    catalogue: "Catalogue",
    items: [
      { label: "Catalogue", href: "/catalogue" },
      { label: "Parcours", href: "/#parcours" },
      { label: "Certifications", href: "/#certifications" },
      { label: "Tarifs", href: "/#tarifs" },
      { label: "Communauté", href: "/#communaute" },
      { label: "À propos", href: "/#apropos" },
    ],
  },

  hero: {
    title1: "Apprenez la technologie.",
    title2: "Prouvez-le.",
    subtitle:
      "Des parcours structurés du Débutant au Projet final, des exercices pratiques corrigés, des quiz qui débloquent chaque chapitre et un certificat vérifiable. Conçu pour les apprenants d'Afrique francophone, léger sur mobile.",
    primaryCta: "Commencer gratuitement",
    secondaryCta: "Explorer les parcours",
    note: "Sans carte bancaire · Paiement Mobile Money disponible · Accès immédiat au premier niveau",
    preview: {
      chapter: "Chapitre 3 · Boucles et conditions",
      progress: "Progression du parcours",
      video: "Vidéo 90 % · Quiz débloqué",
      score: "Quiz réussi · 85 %",
      levels: ["Fondamentaux", "Intermédiaire", "Avancé", "Projet"],
      streak: "Série : 12 jours",
      projectLabel: "Projet noté",
      projectValue: "18 / 20 · accepté",
      certLabel: "Certificat émis",
      certValue: "EL-2026-7K3Q-9F2M",
    },
  },

  stats: {
    note: "Chiffres de la plateforme, mis à jour chaque mois.",
  },

  trust: {
    title: "Les technologies que vous apprendrez",
    items: [
      "Python",
      "JavaScript",
      "SQL",
      "Linux",
      "Cisco & réseaux",
      "Arduino",
      "ESP32",
      "STM32",
      "Cybersécurité",
      "Machine learning",
      "Docker",
      "Git",
      "HTML & CSS",
      "PHP",
      "Java",
      "C++",
    ],
  },

  categories: {
    id: "catalogue",
    eyebrow: "Catalogue",
    title: "Dix univers technologiques, quatre niveaux chacun",
    description:
      "Chaque catégorie suit la même progression : Débutant, Intermédiaire, Avancé, puis un Projet noté. Filtrez par niveau pour voir les parcours déjà publiés.",
    filterLabel: "Filtrer par niveau",
    filters: {
      tous: "Tous",
      debutant: "Débutant",
      intermediaire: "Intermédiaire",
      avance: "Avancé",
      projet: "Projet",
    },
    tracksLabel: (n: number) => `${n} parcours`,
    empty: "Aucune catégorie pour ce niveau pour le moment.",
    cta: "Voir la catégorie",
  },

  how: {
    id: "comment-ca-marche",
    eyebrow: "Comment ça marche",
    title: "Quatre étapes, du choix du parcours au certificat",
    description:
      "Rien n'est laissé au hasard : chaque chapitre a des objectifs, une vidéo, un résumé, un exercice et un quiz obligatoire.",
    steps: [
      {
        n: "01",
        title: "Choisir un parcours",
        text: "Parcourez le catalogue, filtrez par niveau et lisez le programme complet avant de vous engager.",
      },
      {
        n: "02",
        title: "Apprendre par niveau",
        text: "Un chapitre se termine par un quiz. Le suivant ne s'ouvre qu'après un score minimal validé.",
      },
      {
        n: "03",
        title: "Pratiquer sur des projets",
        text: "Éditeur de code intégré, exercices guidés et, en fin de parcours, un projet noté avec grille de correction.",
      },
      {
        n: "04",
        title: "Obtenir son certificat",
        text: "Un certificat PDF avec numéro unique, vérifiable en ligne par tout recruteur.",
      },
    ],
  },

  tracks: {
    id: "parcours",
    eyebrow: "Parcours populaires",
    title: "Les formations les plus suivies",
    description:
      "Chaque parcours contient quatre niveaux, des dizaines de chapitres et un projet final corrigé.",
    cta: "Détail du parcours",
    badges: {
      duration: (h: number) => `${h} h`,
      modules: (m: number) => `${m} modules`,
      rating: (r: number) => `${r.toFixed(1)}`,
      students: (s: number) => s.toLocaleString("fr-FR") + " apprenants",
      price: (p: number) => `${p} CDF`,
      free: "Gratuit",
      popular: "Populaire",
    },
    levelLabels: {
      debutant: "Débutant",
      intermediaire: "Intermédiaire",
      avance: "Avancé",
      projet: "Projet",
    },
    from: "À partir de",
  },

  catalogue: {
    eyebrow: "Catalogue",
    title: "Formations et tutoriels, au même endroit",
    description:
      "Les formations structurées du Débutant au Projet final et les tutoriels vidéo libres, classés par technologie.",
    tabLabel: "Type de contenu",
    tabs: {
      formations: "Formations",
      tutoriels: "Tutoriels",
    },
    searchPlaceholder: "Chercher une technologie",
    searchLabel: "Chercher une technologie",
    technologies: "Technologie",
    all: "Toutes",
    showMore: (n: number) => `Voir plus (${n})`,
    tabsCount: {
      formations: (n: number) => (n > 1 ? `${n} formations` : `${n} formation`),
      tutoriels: (n: number) => (n > 1 ? `${n} tutoriels` : `${n} tutoriel`),
    },
    results: (n: number) => (n > 1 ? `${n} résultats` : `${n} résultat`),
    cards: {
      chapters: (n: number) => (n > 1 ? `${n} chapitres` : `${n} chapitre`),
      course: "Cours vidéo",
      watch: "Regarder",
      openChannel: (channel: string) => `Chaîne ${channel}`,
    },
    empty: {
      formations:
        "Aucune formation publiée pour cette technologie pour le moment.",
      tutoriels:
        "Aucun tutoriel vidéo pour cette technologie pour le moment.",
    },
    viewer: {
      back: "Retour au catalogue",
      channel: "Chaîne",
      related: "Dans la même technologie",
      level: "Niveau",
    },
  },

  certificates: {
    id: "certifications",
    eyebrow: "Certifications",
    title: "Un certificat que l'on peut vérifier en ligne",
    description:
      "Chaque certificat porte un numéro unique, le score obtenu, les compétences validées et la date de délivrance. N'importe qui peut le vérifier, sans compte.",
    features: [
      "PDF généré côté serveur, téléchargeable à vie",
      "Numéro de vérification unique et révocable",
      "Détail des niveaux et des projets validés",
      "Lien de partage vers la page de vérification publique",
    ],
    verifyLabel: "Vérifier un certificat",
    verifyPlaceholder: "Ex. EL-2026-7K3Q-9F2M",
    verifyCta: "Vérifier",
    verifyNote: "La vérification est publique et gratuite.",
    preview: {
      title: "Certificat de réalisation",
      alt: "Aperçu d'un certificat easyLearn",
    },
  },

  testimonials: {
    eyebrow: "Témoignages",
    title: "Ils ont transformé leur parcours",
    items: [
      {
        name: "Grâce Mbuyi",
        role: "Développeuse web junior, Kinshasa",
        quote:
          "La structure par niveaux m'a évité d'abandonner. Le quiz obligatoire à chaque chapitre fait toute la différence : on ne passe pas au suivant sans avoir compris.",
        initials: "GM",
        rating: 5,
      },
      {
        name: "Aïcha Traoré",
        role: "Étudiante en réseaux, Abidjan",
        quote:
          "Les exercices pratiques dans le navigateur, même avec une connexion moyenne, sont utilisables. J'ai décroché mon premier certificat en trois mois.",
        initials: "AT",
        rating: 5,
      },
      {
        name: "Patrick Ilunga",
        role: "Technicien informatique, Lubumbashi",
        quote:
          "Le niveau Projet m'a forcé à livrer quelque chose de réel. Mon portfolio a convaincu mon employeur avant même que je finisse le parcours.",
        initials: "PI",
        rating: 5,
      },
      {
        name: "Fatou Ndiaye",
        role: "Autodidacte, Dakar",
        quote:
          "Enfin une formation en français qui ne se contente pas de traduire des tutos. Les résumés écrits et le glossaire me font gagner un temps fou.",
        initials: "FN",
        rating: 4,
      },
    ],
  },

  faq: {
    eyebrow: "Questions fréquentes",
    title: "Tout ce qu'il faut savoir avant de commencer",
    items: [
      {
        q: "Comment fonctionne le déblocage des chapitres ?",
        a: "Chaque chapitre se termine par un quiz obligatoire. Vous devez atteindre le score minimum (70 % par défaut, ajustable par le formateur) pour ouvrir le chapitre suivant. Les échecs déclenchent une explication détaillée de chaque erreur et un lien de révision vers la vidéo concernée.",
      },
      {
        q: "Les vidéos sont-elles produites par easyLearn ?",
        a: "Non. Nous n'hébergeons ni ne revendons aucune vidéo tierce. Les ressources externes sont référencées par lien dans une section « Ressources recommandées », clairement séparée du contenu propriétaire : quiz, exercices, corrections, projets, suivi et certificats.",
      },
      {
        q: "Puis-je suivre la formation sur mobile avec une connexion lente ?",
        a: "Oui. Le lecteur vidéo se charge uniquement quand vous appuyez sur lecture, les pages sont optimisées pour le mobile et les leçons écrites restent consultables même en connexion instable.",
      },
      {
        q: "Quels moyens de paiement sont acceptés ?",
        a: "Mobile Money (M-Pesa, Airtel Money, Orange Money) et carte bancaire. Le paiement d'un niveau est unique : votre accès est permanent, sans abonnement.",
      },
      {
        q: "Le certificat a-t-il une valeur ?",
        a: "C'est une attestation de compétences délivrée par easyLearn, avec score, compétences validées et numéro de vérification public. Vos réalisations et votre projet final restent consultables par le recruteur.",
      },
      {
        q: "Qui peut créer un parcours ?",
        a: "L'équipe easyLearn et les formateurs partenaires accrédités. Tout le contenu, les quiz et les projets sont diffusés depuis la plateforme ; aucun compte sur un site vidéo externe n'est requis pour suivre une formation.",
      },
      {
        q: "Puis-je essayer avant de payer ?",
        a: "Oui, l'inscription est gratuite et ouvre le niveau Débutant de chaque domaine. Les niveaux suivants se débloquent à l'unité, quand vous êtes prêt.",
      },
    ],
  },

  pricing: {
    id: "tarifs",
    eyebrow: "Tarifs",
    title: "Un prix par niveau, payé comme vous voulez",
    description:
      "Prix en francs congolais (CDF). Le niveau Débutant est gratuit dans tous les domaines ; débloquez ensuite Intermédiaire, Avancé ou Projet, domaine par domaine. Paiement Mobile Money ou carte bancaire, confirmation sécurisée côté serveur, accès débloqué automatiquement.",
    plans: [
      {
        name: "Découverte",
        price: "Gratuit",
        period: "",
        description: "Pour commencer sans payer, dans tous les domaines.",
        features: [
          "Inscription gratuite",
          "Niveau Débutant de chaque domaine",
          "Suivi de progression et série d'étude",
          "Accès à la communauté",
        ],
        cta: "Créer un compte",
        href: "/inscription",
        highlighted: false,
        note: "",
      },
      {
        name: "À l'unité",
        price: "Par niveau",
        period: "",
        description:
          "Débloquez le niveau dont vous avez besoin, quand vous voulez.",
        features: [
          "Intermédiaire, Avancé ou Projet",
          "Prix affiché sur chaque domaine",
          "Quiz, exercices et corrections",
          "Accès permanent, sans abonnement",
          "Certificat vérifiable en fin de parcours",
        ],
        cta: "Voir le catalogue",
        href: "/catalogue",
        highlighted: true,
        note: "Vous ne payez que les niveaux qui comptent pour vous.",
      },
    ],
    guarantee: "Satisfait ou remboursé sous 7 jours, sans justification.",
    popularLabel: "Le plus choisi",
    paymentMethods: "M-Pesa · Airtel Money · Orange Money · Carte bancaire",
  },

  payment: {
    buyTitle: "Débloquer ce niveau",
    buyIntro:
      "Paiement unique pour ce niveau du domaine. L'accès est ouvert immédiatement après confirmation.",
    orderDomain: "Domaine",
    orderLevel: "Niveau",
    orderTotal: "Total à payer",
    methods: "Moyens de paiement acceptés",
    payCta: "Payer",
    payMockHint:
      "Mode démonstration : le paiement est simulé, aucune somme ne sera débitée.",
    paySecureHint:
      "Paiement sécurisé par nyole (Mobile Money ou carte) — l'apprenant reste sur easyLearn.",
    checkoutTitle: "Paiement sécurisé",
    checkoutIntro:
      "La page de paiement nyole s'affiche dans cette fenêtre : vous restez sur easyLearn. Ne la fermez pas avant la confirmation.",
    checkoutNewWindow: "Ouvrir dans une nouvelle fenêtre",
    checkoutChecking: "Vérification du paiement…",
    cancelled: "Paiement annulé. Vous pouvez réessayer à tout moment.",
    returnSuccess: "Paiement confirmé. Le niveau est débloqué.",
    returnPending: "Paiement en cours de confirmation…",
    returnFailed: "Le paiement n'a pas abouti. Vous pouvez réessayer.",
    returnClose: "Fermer la fenêtre",
    returnRetry: "Réessayer le paiement",
    success: "Paiement confirmé. Le niveau est débloqué.",
    unlockCta: "Débloquer ce niveau",
    bannerTitle: "Ce niveau n'est pas encore débloqué",
    bannerNotice:
      "Le niveau débutant est gratuit. Débloquez un niveau payant pour ouvrir tous ses chapitres, vidéos et quiz.",
    lockBadge: "Verrouillé",
    errors: {
      "no-price": "Ce niveau n'a pas encore de prix défini par l'administrateur.",
      "not-configured": "Base Supabase non configurée.",
      failed: "Le paiement a échoué. Réessayez dans un instant.",
      missing: "Domaine ou niveau introuvable.",
      "nyole-unavailable":
        "Le service de paiement est momentanément injoignable. Réessayez dans un instant.",
      "nyole-error":
        "Le service de paiement a refusé la demande. Réessayez dans un instant.",
      "nyole-auth":
        "Le service de paiement refuse la clé configurée : le paiement est temporairement indisponible. Prévenez l'administrateur du site.",
    },
  },

  instructors: {
    eyebrow: "Formateurs",
    title: "Appris avec des praticiens, pas des slides",
    description:
      "Nos formateurs partenaires sont issus des entreprises et des écoles techniques francophones. Ils conçoivent les chapitres, corrigent les projets et animent leurs communautés.",
    items: [
      {
        name: "David Kasongo",
        role: "Ingénieur logiciel",
        expertise: "Python · Django · API",
        bio: "12 ans de développement backend, formateur de plus de 4 000 apprenants.",
        initials: "DK",
      },
      {
        name: "Aminata Diallo",
        role: "Ingénieure réseau & sécurité",
        expertise: "Réseaux · Linux · Pentest",
        bio: "Ancienne administratrice réseau dans l'opérateur télécom, certifiée sécurité.",
        initials: "AD",
      },
      {
        name: "Samuel Mputu",
        role: "Data scientist",
        expertise: "Machine learning · Python",
        bio: "Conçoit des modèles prédictifs pour l'agriculture et la santé en RDC.",
        initials: "SM",
      },
      {
        name: "Nadège Oyono",
        role: "Ingénieure embarquée",
        expertise: "Arduino · ESP32 · STM32",
        bio: "Conception d'objets connectés et d'automates industriels depuis 8 ans.",
        initials: "NO",
      },
    ],
  },

  community: {
    id: "communaute",
    eyebrow: "Communauté",
    title: "Vous n'apprenez pas seul",
    description:
      "Chaque parcours dispose de son espace d'entraide : forum sur la plateforme, groupe WhatsApp et salon Discord animés par le formateur. Les questions trouvent une réponse, les projets trouvent des relecteurs.",
    channels: [
      {
        name: "Forum par parcours",
        text: "Questions techniques, corrections partagées, recherche dans l'historique.",
      },
      {
        name: "Groupes WhatsApp",
        text: "Rappels de révision, sessions de questions-réponses hebdomadaires.",
      },
      {
        name: "Salons Discord",
        text: "Pair-programming, revues de code et veille technologique.",
      },
    ],
    stats: [
      { value: "18 000+", label: "Messages utiles classés" },
      { value: "48 h", label: "Délai moyen de réponse" },
      { value: "120+", label: "Sessions de révision par mois" },
    ],
    cta: "Rejoindre la communauté",
  },

  about: {
    id: "apropos",
    eyebrow: "À propos",
    title: "Notre méthode : structurer, faire pratiquer, certifier",
    description:
      "easyLearn ne vend pas des vidéos. Nous vendons l'ordonnancement pédagogique, les exercices, les quiz, les projets corrigés, le suivi, la communauté et les certificats. Les ressources externes restent des liens recommandés, jamais du contenu revendu.",
    points: [
      {
        title: "Contenu structuré",
        text: "Parcours, niveaux, modules, chapitres : un ordre qui mène au résultat.",
      },
      {
        title: "Pratique obligatoire",
        text: "Éditeur de code intégré et projets notés, pas seulement de la théorie.",
      },
      {
        title: "Preuve de compétence",
        text: "Certificats vérifiables et portfolio consultable par les recruteurs.",
      },
      {
        title: "Pensé pour l'Afrique",
        text: "Mobile d'abord, léger en data, paiement Mobile Money, français natif.",
      },
    ],
  },

  cta: {
    title: "Votre prochain niveau commence maintenant",
    text: "Créez un compte gratuit, lancez le test de positionnement et ouvrez votre premier chapitre en moins de deux minutes.",
    primary: "Commencer gratuitement",
    secondary: "Explorer les parcours",
  },

  footer: {
    tagline:
      "Plateforme d'apprentissage de la technologie pour les francophones. Structurée, pratique, certifiante.",
    columns: [
      {
        title: "Apprendre",
        links: [
          { label: "Catalogue", href: "/catalogue" },
          { label: "Parcours", href: "/#parcours" },
          { label: "Certifications", href: "/#certifications" },
          { label: "Tarifs", href: "/#tarifs" },
        ],
      },
      {
        title: "Plateforme",
        links: [
          { label: "Formateurs", href: "/#formateurs" },
          { label: "Communauté", href: "/#communaute" },
          { label: "À propos", href: "/#apropos" },
          { label: "Vérifier un certificat", href: "/verifier" },
          { label: "Espace apprenant", href: "/app" },
        ],
      },
      {
        title: "Support",
        links: [
          { label: "FAQ", href: "/#faq" },
          { label: "Contact", href: "mailto:contact@easylearn.cd" },
          { label: "Aide", href: "mailto:aide@easylearn.cd" },
          { label: "Signaler un problème", href: "mailto:support@easylearn.cd" },
        ],
      },
      {
        title: "Légal",
        links: [
          { label: "Mentions légales", href: "/mentions-legales" },
          { label: "CGU", href: "/cgu" },
          { label: "Confidentialité", href: "/confidentialite" },
          { label: "Accessibilité", href: "/accessibilite" },
          { label: "Crédits des leçons", href: "/credits" },
        ],
      },
    ],
    follow: "Suivez-nous",
    rights: (y: number) => `© ${y} easyLearn. Tous droits réservés.`,
    madeIn: "Conçu à Kinshasa, pour l'Afrique francophone.",
    paymentNote: "Paiements sécurisés : Mobile Money et carte bancaire.",
  },

  auth: {
    loginTitle: "Connexion",
    signupTitle: "Créer un compte",
    verifyTitle: "Vérification de certificat",
    backHome: "Retour à l'accueil",
    verifyArrival:
      "La vérification publique par numéro de certificat sera disponible prochainement.",
    verifyForm: {
      label: "Numéro de certificat",
      placeholder: "Ex. PYT-2026-000123",
      submit: "Vérifier",
      hint: "Le numéro figure en bas à droite de chaque certificat.",
    },
    verifyValid: "Certificat valide",
    verifyInvalid: "Certificat introuvable",
    verifyInvalidText:
      "Ce numéro ne correspond à aucun certificat délivré par easyLearn.",
    verifyHolder: "Bénéficiaire",
    verifyFormation: "Formation",
    verifyIssued: (date: string) => `Délivré le ${date}`,
    verifyIssuedLabel: "Délivré le",
    verifyCode: "Numéro",

    loginSubtitle:
      "Accédez à votre espace apprenant et reprenez votre parcours là où vous l'avez arrêté.",
    signupSubtitle:
      "Compte gratuit : profil, progression, quiz corrigés et certificat vérifiable.",
    fullNameLabel: "Nom complet",
    fullNamePlaceholder: "Ex. Marie Kabeya",
    emailLabel: "Adresse e-mail",
    emailPlaceholder: "vous@exemple.com",
    passwordLabel: "Mot de passe",
    passwordPlaceholder: "8 caractères minimum",
    passwordHint: "8 caractères minimum, avec au moins une lettre et un chiffre.",
    confirmPasswordLabel: "Confirmer le mot de passe",
    submitLogin: "Se connecter",
    submitSignup: "Créer mon compte",
    submitReset: "Recevoir le lien",
    submitNewPassword: "Enregistrer le nouveau mot de passe",
    forgotPassword: "Mot de passe oublié ?",
    forgotPasswordTitle: "Réinitialiser le mot de passe",
    forgotPasswordSubtitle:
      "Indiquez votre e-mail : vous recevrez un lien valable une heure pour choisir un nouveau mot de passe.",
    resetTitle: "Nouveau mot de passe",
    resetSubtitle:
      "Choisissez un nouveau mot de passe : il remplace l'ancien pour toutes vos sessions.",
    resetChecking: "Vérification du lien de réinitialisation…",
    resetSent:
      "Si un compte existe pour cette adresse, un lien de réinitialisation vient d'être envoyé. Vérifiez votre boîte mail et vos spams.",
    noticePasswordUpdated:
      "Mot de passe mis à jour. Connectez-vous avec votre nouveau mot de passe.",
    noticeResetLinkInvalid:
      "Ce lien est invalide ou a expiré. Demandez un nouveau lien depuis la page « Mot de passe oublié ».",
    google: "Continuer avec Google",
    or: "ou",
    noAccount: "Pas encore de compte ?",
    hasAccount: "Déjà un compte ?",
    signupLink: "Créer un compte",
    loginLink: "Se connecter",
    mySpace: "Mon espace",
    signOut: "Se déconnecter",
    signOutTitle: "Se déconnecter ?",
    signOutDescription:
      "Vous quitterez votre session sur cet appareil et devrez vous reconnecter pour retrouver votre espace.",
    signOutConfirm: "Oui, se déconnecter",
    signOutCancel: "Annuler",
    signedInAs: "Connecté en tant que",
    confirmSent: (email: string) =>
      `Un e-mail de confirmation a été envoyé à ${email}. Cliquez sur le lien pour activer votre compte.`,
    confirmSentHint: "Pensez à vérifier vos spams si le message n'arrive pas.",
    noticeConfirmed: "Adresse e-mail confirmée. Vous pouvez vous connecter.",
    noticeConfirmFailed:
      "Lien de confirmation invalide ou expiré. Demandez un nouvel e-mail depuis la page d'inscription.",
    noticeLoginFailed:
      "La connexion a échoué. Vérifiez vos identifiants puis réessayez.",
    noticeGoogleUnavailable:
      "La connexion Google n'est pas encore activée sur ce projet Supabase : à configurer dans Authentication → Providers → Google.",
    noticeGoogleStateUsed:
      "Le lien de connexion Google a déjà été utilisé. Merci de réessayer une seule fois, sans double-clic, puis videz les cookies du site si nécessaire.",
    confirmationTitle: "E-mail confirmé",
    confirmationFailedTitle: "Confirmation impossible",
    confirmationText:
      "Votre adresse e-mail a bien été validée. Il ne reste qu'à accéder à votre espace.",
    confirmationFailedText:
      "Ce lien de confirmation est invalide ou a expiré. Créez à nouveau un compte pour recevoir un message.",
    appTitle: "Mon espace",
    appWelcome: (name: string) => `Bienvenue, ${name}.`,
    appIntro:
      "Votre espace apprenant arrive à l'étape 4 : chapitres, quiz, progression et certificats.",
    appSignOutHint: "Vous pouvez vous déconnecter à tout moment.",

    errors: {
      required: "Ce champ est obligatoire.",
      emailInvalid: "Saisissez une adresse e-mail valide.",
      passwordWeak:
        "Le mot de passe doit contenir au moins 8 caractères, une lettre et un chiffre.",
      passwordMismatch: "Les deux mots de passe ne correspondent pas.",
      nameTooShort: "Indiquez votre nom complet (2 caractères minimum).",
      invalidCredentials: "E-mail ou mot de passe incorrect.",
      emailNotConfirmed:
        "Cette adresse e-mail n'est pas encore confirmée. Ouvrez le lien reçu par e-mail.",
      emailTaken:
        "Un compte est déjà actif avec cet e-mail. Connectez-vous, ou réinitialisez votre mot de passe si vous l'avez oublié.",
      emailExists:
        "Un compte existe déjà avec cet e-mail. Connectez-vous ou demandez un mot de passe oublié.",
      tooManyRequests:
        "Trop de tentatives. Patientez une minute avant de réessayer.",
      emailTooManyRequests:
        "Trop de demandes d'e-mail en peu de temps. Patientez quelques minutes, puis réessayez.",
      generic: "Une erreur est survenue. Réessayez dans un instant.",
      notConfigured:
        "Authentification non configurée : renseignez NEXT_PUBLIC_SUPABASE_URL et NEXT_PUBLIC_SUPABASE_ANON_KEY dans .env.local.",
    },
  },

  learner: {
    dashboardTitle: "Mon espace",
    welcome: (name: string) => `Bienvenue, ${name}.`,
    intro:
      "Reprenez un chapitre, validez son quiz et débloquez le suivant. Votre progression est enregistrée à chaque tentative.",
    resume: "Reprendre le parcours",
    resumeLabel: (chapter: string) => `Reprendre : ${chapter}`,
    start: "Commencer le parcours",
    tracksTitle: "Vos parcours",
    tracksEmpty: "Aucun parcours publié pour le moment.",
    tracksEmptyCta: "Parcourir le catalogue",
    profil: {
      title: "Mon profil",
      identity: "Compte",
      certificatesTitle: "Mes certificats",
      certificatesIntro:
        "Chaque niveau terminé et chaque parcours complet délivrent un certificat PDF, téléchargeable ici.",
      certificatesEmpty:
        "Aucun certificat pour le moment. Terminez un niveau ou un parcours pour en obtenir un.",
      issuedOn: (date: string) => `Délivré le ${date}`,
      download: "Télécharger le PDF",
      verify: "Vérifier",
      scope: {
        niveau: "Niveau",
        parcours: "Parcours",
      },
      finalLabel: "Parcours complet",
      backToDashboard: "Retour à mon espace",
      testTitle: "Démonstration",
      testHint:
        "Compte de test (mode développement) : valide le niveau Débutant de Python et télécharge le certificat généré.",
      testButton: "Certificat de test",
      testError: "Impossible de générer le certificat de test.",
      edit: "Modifier",
      role: {
        learner: "Apprenant",
        admin: "Administrateur",
      },
      noPhone: "Téléphone non renseigné",
      form: {
        title: "Modifier mon compte",
        description:
          "Corrigez vos identifiants et ajoutez votre photo de profil.",
        photo: "Photo de profil",
        photoHint: "JPG, PNG ou WebP — 2 Mo maximum.",
        photoChoose: "Choisir une photo",
        photoUploading: "Envoi en cours…",
        fullName: "Nom complet",
        email: "Adresse email",
        emailHint:
          "Un lien de confirmation sera envoyé à la nouvelle adresse.",
        emailPending: (email: string) =>
          `Lien de confirmation envoyé à ${email}. Vérifiez votre boîte de réception.`,
        phone: "Téléphone",
        save: "Enregistrer",
        cancel: "Annuler",
        saved: "Modifications enregistrées.",
        errors: {
          required: "Ce champ est requis.",
          tooLong: "100 caractères maximum.",
          emailInvalid: "Adresse email invalide.",
          emailTaken: "Cette adresse email est déjà utilisée.",
          emailRateLimit:
            "Trop de demandes. Réessayez dans quelques minutes.",
          phoneInvalid: "Numéro de téléphone invalide.",
          photoInvalid: "Format non accepté (JPG, PNG ou WebP).",
          photoTooLarge: "Fichier trop volumineux (2 Mo maximum).",
          generic: "Impossible d'enregistrer. Réessayez.",
        },
      },
    },
    notConfigured:
      "Base Supabase non configurée : renseignez les variables dans .env.local.",
    chapterWord: "chapitres",
    chaptersLabel: (done: number, total: number) =>
      `${done} / ${total} chapitres validés`,
    progressLabel: (percent: number) => `Progression ${percent} %`,
    status: {
      locked: "Verrouillé",
      available: "Disponible",
      completed: "Validé",
      current: "À faire",
    },
    chapterList: "Chapitres du parcours",
    sidebarTitle: "Sommaire du parcours",
    progressTitle: "Votre progression",
    overviewTitle: "Vue d'ensemble",
    todoTitle: "À faire maintenant",
    todoEmpty: "Aucun chapitre en attente : tout est validé. Bravo !",
    allDone: "Parcours terminé, bravo !",
    nextSteps: "Prochains chapitres",
    recentQuizzes: "Derniers quiz",
    recentEmpty: "Aucun quiz tenté pour l'instant.",
    metricChapters: "Chapitres",
    metricQuizzes: "Quiz",
    metricAverage: "Score moyen",
    metricBest: "Meilleur score",
    passingLabel: "Seuil",
    noScore: "—",
    progressTotal: (done: number, total: number) => `${done} / ${total} chapitres`,
    positionOf: (index: number, total: number) =>
      `Chapitre ${index} sur ${total}`,
    overallPercent: (percent: number) => `${percent} % du parcours`,
    trackMeta: {
      duration: (hours: number) => `${hours} h`,
      modules: (count: number) => `${count} modules`,
      rating: (rating: number) => `${rating.toFixed(1)} / 5`,
      students: (count: number) => `${count} apprenants`,
      free: "Gratuit",
      paid: (price: number) => `${price} CDF`,
    },
    objectives: "Objectifs du chapitre",
    summary: "Résumé",
    video: "Vidéo du chapitre",
    videoPlaybackFailed:
      "Cette leçon vidéo refuse de se lancer sur votre poste. Réessayez, ou marquez-la comme vue pour continuer : le texte du cours ci-dessous suffit à progresser.",
    lesson: "Leçon",
    exercise: "Exercice pratique",
    exerciseEmpty:
      "Cet exercice pratique sera ajouté par le formateur prochainement.",
    practice: {
      label: "Pratiquer",
      hint: "Appliquez la leçon dans l'outil ci-dessous : votre progression reste enregistrée sur ce parcours.",
      startCode: "Code de départ",
      editorLabel: "Éditeur",
      solutionShow: "Voir la solution",
      solutionHide: "Masquer la solution",
      solutionTitle: "Solution proposée",
      solutionNote: "Comparez avec votre code, puis masquez la solution.",
      done: "Exercice terminé",
      undone: "Marquer à refaire",
      statusDone: "Terminé",
      statusTodo: "À faire",
      preview: "Aperçu",
      previewRefresh: "Rafraîchir l'aperçu",
      previewHint: "L'aperçu se met à jour automatiquement après votre saisie.",
      previewTitle: "Aperçu de votre page",
      checklistProgress: (done: number, total: number) =>
        `${done} / ${total} étapes`,
      checklistHint: "Cochez chaque étape une fois vérifiée sur votre poste.",
      saving: "Enregistrement…",
      saveError:
        "Enregistrement impossible : vérifiez votre connexion puis réessayez.",
    },
    runner: {
      run: "Exécuter",
      running: "Exécution…",
      output: "Sortie du script",
      clear: "Effacer la sortie",
      loading: "Chargement de Python (première exécution)…",
      empty: "Le script s'est exécuté sans afficher de texte.",
      timeout: "Exécution interrompue : trop longue ou boucle infinie.",
      failed: "Échec de l'exécution :",
    },
    resources: "Ressources recommandées",
    readQuiz: "Passer le quiz",
    quizLocked: "Quiz indisponible : terminez le chapitre précédent.",
    quizEmpty:
      "Ce chapitre n'a pas encore de quiz. Le formateur va l'ajouter prochainement.",
    quizError: "La soumission a échoué. Vérifiez votre connexion et réessayez.",
    quizInterrupted:
      "La connexion au serveur a été interrompue pendant la soumission. Rechargez la page puis réessayez : votre progression enregistrée n'est pas perdue.",
    reload: "Recharger la page",
    quizTitle: "Quiz du chapitre",
    quizIntro: (passing: number, count: number) =>
      `${count} questions, ${passing} % minimum pour valider le chapitre et débloquer le suivant.`,
    quizUnanswered: "Répondez à toutes les questions avant de valider.",
    quizSubmit: "Valider mes réponses",
    quizRetake: "Recommencer le quiz",
    quizScore: "Votre score",
    quizPassed: (score: number) => `Quiz validé : ${score} %.`,
    quizFailed: (score: number, passing: number) =>
      `Score insuffisant : ${score} %. Il faut atteindre ${passing} %.`,
    quizAttempts: (count: number) =>
      count <= 0
        ? "Aucune tentative"
        : count > 1
          ? `${count} tentatives`
          : "1 tentative",
    quizBest: (score: number) => `Meilleur score : ${score} %`,
    quizResult: "Corrigé des réponses",
    answerCorrect: "Bonne réponse",
    answerWrong: "Votre réponse",
    answerMissed: "Bonne réponse",
    explanation: "Explication",
    nextChapter: "Chapitre suivant",
    previousChapter: "Chapitre précédent",
    backToTrack: "Retour au parcours",
    reviewChapter: "Revoir le chapitre",
    lockedNotice:
      "Ce chapitre se débloque automatiquement après le quiz du chapitre précédent.",
    unlockNotice: (passing: number) =>
      `Validez le quiz avec ${passing} % pour ouvrir le chapitre suivant.`,
    examTitle: "Examen de fin de niveau",
    examIntro: (passing: number, count: number) =>
      `${count} questions tirées des quiz du niveau, ${passing} % minimum pour réussir l'examen et obtenir votre certificat.`,
    examUnanswered: "Répondez à toutes les questions avant de valider.",
    examSubmit: "Valider mes réponses",
    examRetake: "Recommencer l'examen",
    examScore: "Votre score",
    examPassed: (score: number) => `Examen réussi : ${score} %.`,
    examFailed: (score: number, passing: number) =>
      `Score insuffisant : ${score} %. Il faut atteindre ${passing} %.`,
    examLockedTitle: "Examen indisponible",
    examLocked:
      "Terminez tous les chapitres du niveau pour passer l'examen final.",
    examEmpty:
      "Cet examen n'a pas encore de questions. Le formateur va les ajouter prochainement.",
    examNextLockedNotice:
      "Réussissez l'examen du niveau précédent pour débloquer ce niveau.",
    examCta: "Passer l'examen",
    examProgressHint: (done: number, total: number) =>
      `Examen débloqué après les ${total} chapitres du niveau (${done} validés).`,
    examPassedBadge: "Examen réussi",
    examPendingBadge: "Examen à passer",
    examRetakeHint:
      "Vous pouvez retenter l'examen pour améliorer votre meilleur score.",
    examCertificateNotice:
      "Examen réussi : votre certificat de niveau est disponible sur votre profil.",
    chapterLockedTitle: "Chapitre verrouillé",
    levelLockedTitle: "Niveau verrouillé",
    levelLockedMsg:
      "Ce niveau n'est pas débloqué. Débloquez-le pour continuer.",
    levelLockedNotice:
      "Ce chapitre appartient à un niveau payant. Débloquez ce niveau pour accéder à toutes ses vidéos, son cours et son quiz.",
    switchToTutorial: "Voir le tutoriel",
    switchToDocument: "Lire le document",
    videosCount: (count: number) => (count <= 1 ? "1 vidéo" : `${count} vidéos`),
    videosLocked:
      "Regardez toutes les vidéos du chapitre avant de passer le quiz.",
    videosRequiredTitle: "Vidéos à terminer",
    videosRequiredNotice:
      "Regardez toutes les vidéos du chapitre pour débloquer la suite du chapitre et le quiz.",
    videosDoneNotice:
      "Toutes les vidéos sont terminées. La suite du chapitre est débloquée.",
    videosProgress: (done: number, total: number) =>
      `${done} / ${total} leçon${total <= 1 ? "" : "s"} terminée${
        total <= 1 ? "" : "s"
      }`,
    markWatched: "Marquer la leçon comme vue",
    videoBlockedTitle: "La leçon ne se lance pas ?",
    videoBlockedHint:
      "Il lui arrive de refuser la lecture intégrée (contrôle de sécurité ou connexion instable). Patientez quelques secondes puis réessayez ; vous pouvez aussi marquer la leçon comme vue pour poursuivre votre chapitre.",
    videoRetry: "Réessayer",
    videoFinished: "Leçon terminée",
    videoFinishedHint:
      "Vous avez atteint la fin de cette leçon. Revoyez-la si besoin, puis passez à la suite du chapitre.",
    videoRewatch: "Revoir la leçon",
    reviewVideos: "Voir les leçons",
    videoAutoNext: "La leçon suivante démarre automatiquement…",
    videoLabel: (position: number, index: number) =>
      `Leçon ${position}.${index}`,
    tutorial: {
      title: "Tutoriel vidéo",
      playlist: "Dans ce chapitre",
      nowPlaying: "Leçon en cours",
      empty:
        "Aucune leçon vidéo n'est encore publiée pour ce chapitre. Le document reste disponible pour apprendre.",
    },
    stepOf: (index: number, total: number) =>
      `Étape ${index} sur ${total}`,
    pageOf: (index: number, total: number) => `Page ${index} sur ${total}`,
    stepsLabel: "Étapes du chapitre",
    previousStep: "Étape précédente",
    nextStep: "Étape suivante",
    previousPage: "Page précédente",
    nextPage: "Page suivante",
    stepLabels: {
      videos: "Leçons vidéo",
      objectives: "Objectifs",
      lesson: "Cours",
      exercise: "Exercice",
      resources: "Ressources",
      quiz: "Quiz",
    },
    lessonEditor: {
      label: "Éditeur de code",
      hint: "Le code du chapitre est modifiable : testez vos idées sans quitter le cours.",
      reset: "Réinitialiser",
    },
    player: {
      tabTutorial: "Tutoriel",
      tabDocuments: "Documents",
      subChapters: "Chapitres",
      subResources: "Ressources",
      searchPlaceholder: "Rechercher un chapitre",
      searchLabel: "Rechercher un chapitre dans le sommaire",
      searchEmpty: "Aucun chapitre ne correspond à votre recherche.",
      resourcesEmpty: "Aucune ressource pour ce parcours.",
      sidebarToggle: "Afficher ou masquer le sommaire",
      sidebarExpand: "Déplier la section",
      sidebarCollapse: "Replier la section",
      fullscreen: "Agrandir la leçon",
      exitFullscreen: "Réduire la leçon",
      shellFullscreen: "Mode immersion",
      shellFullscreenExit: "Quitter le mode immersion",
      quit: "Quitter le parcours",
      backToOverview: "Vue d'ensemble du parcours",
      resourceClose: "Fermer la ressource",
      resourceVideo: "Leçon vidéo",
      resourceNotPlayableTitle:
        "Cette ressource ne peut pas s'afficher dans le lecteur.",
      resourceNotPlayableHint:
        "Le lien enregistré ne pointe vers aucune leçon exploitable depuis la plateforme.",
      resourceBlockedHint:
        "Certaines ressources refusent l'affichage intégré : fermez et réessayez, ou revenez au chapitre.",
      play: "Lecture",
      pause: "Pause",
      seek: "Progression",
      mute: "Couper le son",
      unmute: "Rétablir le son",
    },
  },

  admin: {
    title: "Back-office",
    subtitle:
      "Catalogue easyLearn : catégories, parcours et publications, sans toucher au code.",
    nav: {
      dashboard: "Tableau de bord",
      categories: "Catégories",
      pricing: "Tarifs",
    },
    dashboardIntro:
      "Vue d'ensemble des inscrits et du catalogue, avec les raccourcis de gestion.",
    pricing: {
      title: "Tarifs par niveau",
      intro:
        "Grille des prix par domaine et par niveau. Le niveau Débutant est gratuit pour tous les domaines ; laissez une case vide pour ne pas encore proposer ce niveau payant.",
      domainColumn: "Domaine",
      free: "Gratuit",
      currencyHint: "Prix en francs congolais (CDF), entier.",
      save: "Enregistrer les prix",
      saved: "Prix enregistrés.",
      missingMigration:
        "Table des tarifs introuvable : collez la migration supabase/migrations/202610030001_payments.sql dans l'éditeur SQL de Supabase.",
    },
    stats: {
      learners: "Apprenants inscrits",
      unavailable: "Indisponible",
      categories: "Catégories",
      tracks: "Parcours",
      publishedCategories: "Catégories publiées",
      publishedTracks: "Parcours publiés",
    },
    manageCategories: "Gérer les catégories",
    categoriesTitle: "Catégories",
    categoriesIntro:
      "Les catégories publiées apparaissent immédiatement sur la page d'accueil.",
    empty: "Aucune catégorie enregistrée pour le moment.",
    columns: {
      name: "Nom",
      slug: "Slug",
      levels: "Niveaux",
      tracks: "Parcours",
      status: "Statut",
      actions: "Actions",
    },
    status: {
      published: "Publiée",
      draft: "Brouillon",
    },
    create: "Nouvelle catégorie",
    createTitle: "Nouvelle catégorie",
    editTitle: "Modifier la catégorie",
    backToList: "Retour aux catégories",
    fields: {
      name: "Nom",
      namePlaceholder: "Ex. Programmation",
      slug: "Slug",
      slugPlaceholder: "programmation",
      slugHint: "URL en minuscules, sans espace : programmation, ia-data…",
      description: "Description",
      descriptionPlaceholder: "Ce que couvre cette catégorie.",
      icon: "Icône",
      levels: "Niveaux disponibles",
      position: "Ordre d'affichage",
      published: "Publier la catégorie",
      publishedHint: "Visible sur la page d'accueil sans relancer le site.",
    },
    actions: {
      edit: "Modifier",
      delete: "Supprimer",
      save: "Enregistrer",
      cancel: "Annuler",
      confirm: "Confirmer",
    },
    deleteTitle: "Supprimer la catégorie ?",
    deleteText:
      "La catégorie sera retirée du catalogue, ainsi que les parcours qui lui sont rattachés. Cette action est définitive.",
    created: "Catégorie créée et publiée sur le site.",
    updated: "Catégorie mise à jour.",
    deleted: "Catégorie supprimée.",
    notConfigured:
      "Base Supabase non configurée : renseignez les variables dans .env.local.",
    saveFailed: "Enregistrement impossible. Réessayez dans un instant.",
    forbiddenTitle: "Accès réservé",
    forbiddenText:
      "Ce compte n'a pas les droits administrateur requis pour le back-office.",
    forbiddenBack: "Retour à l'accueil",
  },

  emails: {
    certificate: {
      subject: (title: string) => `Votre certificat « ${title} » est prêt`,
      heading: (name: string) => `Félicitations ${name} !`,
      body: (title: string, date: string) =>
        `Vous avez terminé « ${title} » avec succès. Ce certificat, délivré le ${date}, est disponible dans votre profil, où il restera téléchargeable en PDF.`,
      cta: "Télécharger mon certificat",
      verify: "Vérifier ce certificat en ligne",
      footer: "Cet email a été envoyé automatiquement par easyLearn.",
    },
  },

  common: {
    levels: {
      debutant: "Débutant",
      intermediaire: "Intermédiaire",
      avance: "Avancé",
      projet: "Projet",
    },
    notFoundTitle: "Page introuvable",
    notFoundText: "Le contenu demandé n'existe pas ou a été déplacé.",
  },

  levelUp: {
    eyebrow: "Progression",
    title: (current: string, next: string) =>
      `Tu es au niveau « ${current} » — passe au niveau « ${next} » et débloque la suite du parcours.`,
    finalTitle:
      "Tu es au dernier niveau — termine ton projet final et décroche ton certificat !",
    genericTitle:
      "Ne t'arrête pas au premier niveau — passe au niveau supérieur !",
    text: "Chaque niveau supérieur débloque de nouveaux chapitres, quiz corrigés et projets notés. Ton certificat vérifiable t'attend à la fin du parcours.",
    cta: "Passer au niveau supérieur",
    finalCta: "Terminer mon projet",
  },
};
