# easyTech

Plateforme e-learning professionnelle pour l'apprentissage de la technologie,
destinée aux étudiants, autodidactes et professionnels francophones (RDC et
Afrique francophone en priorité), optimisée pour le mobile et les connexions
lentes.

## État du projet

| Étape | Contenu | Statut |
| ----- | ------- | ------ |
| 0 | Scaffold, design system, thèmes clair/sombre, i18n (`fr`), lint | ✅ |
| 1 | Landing page complète | ✅ |
| 2 | Authentification Supabase (email + Google) | ✅ |
| 3 | Catalogue + back-office de base | ✅ |
| 4 | Espace apprenant (chapitres, quiz, progression) | ✅ |
| 5 | Paiement (`PaymentProvider` + nyole) | ✅ |
| 6 | Certificats PDF + vérification publique | ⬜ |
| 7 | Back-office complet + statistiques | ⬜ |
| 8 | Communauté, badges, affiliation, notifications | ⬜ |
| 9 | Sécurité, performance, SEO, accessibilité | ⬜ |

## Stack

- **Front** : Next.js 16 (App Router, Turbopack), React 19, TypeScript, Tailwind CSS v4, shadcn/ui
- **Back / données** : Supabase (PostgreSQL, Auth, Storage, Row Level Security) — auth, catalogue (`profiles`, `categories`, `tracks`) et espace apprenant (`chapters`, `quiz_questions`, `chapter_progress`) en place
- **Emails** : Supabase Auth (modèles configurés dans la console)
- **Paiement** : nyole (`src/lib/payments/`), page de paiement chargée dans une
  boîte de dialogue — l'apprenant ne quitte jamais le site
- **Déploiement** : Vercel

## Démarrage

```bash
npm install
cp .env.example .env.local   # puis renseigner les valeurs
npm run dev
```

Ouvrir <http://localhost:3000>.

### Commandes

| Commande | Rôle |
| -------- | ---- |
| `npm run dev` | Serveur de développement (Turbopack) |
| `npm run build` | Build de production |
| `npm run lint` | ESLint (Next 16 a retiré `next lint`) |
| `npm run typecheck` | Vérification TypeScript (`tsc --noEmit`) |

## Structure

```
src/
  proxy.ts                  # rafraîchit la session + protège /app et /admin
  app/
    layout.tsx              # polices, thèmes, métadonnées SEO, JSON-LD
    not-found.tsx
    auth/
      callback/             # retour OAuth (Google)
      confirm/              # confirmation d'e-mail (lien reçu)
      confirmation/         # message de confirmation
    (site)/                 # pages publiques (header + footer)
      page.tsx              # landing
      inscription/ connexion/ verifier/ mot-de-passe-oublie/
      app/                  # espace apprenant (protégé)
        page.tsx            # tableau de bord (raccourcis, progression)
        parcours/[slug]/    # chapitres groupés par niveau
          chapitres/[chapterSlug]/        # leçon, exercice, ressources
            quiz/                         # quiz du chapitre
      admin/                # back-office (layout avec garde admin)
        categories/         # CRUD des catégories
      interdit/             # page « accès réservé »
      [slug]/               # pages légales
  components/
    admin/                  # formulaires et navigation du back-office
    auth/                   # cartes, formulaires, menu utilisateur
    landing/                # sections de la landing
    layout/                 # header, footer
    learning/               # barre de progression, lecteur vidéo, quiz
    ui/                     # composants shadcn/ui
  config/                   # site, catalogue, contenus légaux
  i18n/                     # dictionnaire fr (structure prête pour en)
  lib/
    actions/                # server actions (auth, admin, apprentissage, …)
    admin/                  # typage et validation des formulaires admin
    auth/                   # validation, accès aux données protégées
    catalog/                # requêtes catalogue (lectures publiques/admin)
    learning/               # requêtes apprenant (chapitres, progression)
    supabase/               # clients navigateur / serveur / public / service
supabase/migrations/        # schéma SQL (profils, rôles, catalogue, apprentissage, RLS)
```

## Configuration Supabase

Variables dans `.env.local` (voir `.env.example`) :

| Variable | Rôle |
| -------- | ---- |
| `NEXT_PUBLIC_SUPABASE_URL` | URL du projet Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Clé anonyme (client + serveur, exposée) |
| `SUPABASE_SERVICE_ROLE_KEY` | Clé service role — **serveur uniquement** |

Dans la console Supabase (Authentication → URL Configuration) :

1. **Site URL** : `http://localhost:3000` en local, puis l'URL de production.
2. **Redirect URLs** : `http://localhost:3000/*` (puis `https://…/*`).
   Sans le `*`, Supabase ignore les sous-chemins (`/auth/*`, `/mot-de-passe-oublie/nouveau`)
   et redirige vers la Site URL : `EmailLinkRedirect` (`src/components/auth/email-link-redirect.tsx`)
   rattrape alors le lien de récupération et l'affiche de confirmation sur la racine.
3. **Emails** : modèle de confirmation pointant vers `{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=email`.
   Le lien « mot de passe oublié » fonctionne aussi avec le modèle par défaut :
   Supabase redirige vers la Site URL, d'où `EmailLinkRedirect` renvoie vers
   `/mot-de-passe-oublie/nouveau`, qui valide la session de récupération côté
   navigateur avant l'enregistrement du nouveau mot de passe.
4. **Expéditeur** : Authentication → Emails → renseigner **Sender name**
   (`easyTech`) et **Sender email** — sinon les mails partent avec le nom de
   Supabase. Le texte des modèles se règle dans le même écran.
5. **Google** : activer le fournisseur Google, renseigner client ID/secret
   (console Google Cloud), et autoriser l'origine `http://localhost:3000`.
   L'URI de redirection à déclarer dans Google Cloud est
   `https://<ref>.supabase.co/auth/v1/callback`. Tant que le fournisseur est
   désactivé, Supabase répond `Unsupported provider: provider is not enabled`
   et la page de connexion affiche un message explicite.

Sans ces variables, les pages d'auth affichent un message de configuration
au lieu de planter.

## Base de données

Schéma appliqué depuis `supabase/migrations/202609300001_catalogue.sql` et
`supabase/migrations/202609300002_apprenant.sql`
(SQL Editor Supabase, ou API management `POST /v1/projects/<ref>/database/query`).

| Table | Rôle |
| ----- | ---- |
| `profiles` | profil + rôle (`learner` / `admin`), créé par trigger à l'inscription |
| `categories` | catalogue de la landing (slug, icône, niveaux, ordre, publication) |
| `tracks` | parcours rattachés à une catégorie (niveau, durée, prix, notes) |
| `chapters` | chapitres d'un parcours (position, niveau, leçon, vidéo, exercice) |
| `quiz_questions` | questions d'un chapitre (choix, réponse, explication) — **lecture serveur uniquement** |
| `chapter_progress` | progression de l'utilisateur (tentatives, meilleur score, statut) |

- `public.is_admin()` (SECURITY DEFINER) lit le rôle sans récursion de RLS.
- RLS : lecture publique des lignes `published`, écriture réservée aux admins ;
  `profiles` lisible par son titulaire ou par un admin.
- Espace apprenant : `chapters` lisible par les utilisateurs connectés,
  `chapter_progress` limitée à ses propres lignes, et `quiz_questions` n'a
  **aucun grant** pour `anon`/`authenticated` (les réponses ne quittent jamais
  le serveur : elles sont lues avec la clé service role et corrigées dans
  `submitQuiz`).
- Seed : les 10 catégories, les 6 parcours de démonstration, le parcours
  **Python** complet (8 chapitres publiés, 32 questions de quiz), et le rôle
  `admin` pour `otukaotukamo@gmail.com`. Rejouer les fichiers est sans effet
  (`if not exists` + `on conflict do nothing`).

### Back-office

- `/admin` : tableau de bord (compteurs) ; `/admin/categories` : création,
  édition, publication et suppression des catégories.
- Garde double : `src/proxy.ts` (session) puis `requireAdmin()` dans
  `src/lib/auth/dal.ts` (rôle) — la même garde est rappelée dans chaque
  server action ; les non-admins sont redirigés vers `/interdit`.
- Chaque écriture appelle `revalidatePath("/", "layout")` : la landing
  statique reflète la base sans redéploiement.
- Sans base configurée, le catalogue retombe sur `src/config/catalog.ts`.

### Espace apprenant

- `/app` : tableau de bord (bienvenue, raccourci back-office pour les admins,
  « Reprendre », une carte par parcours avec sa barre de progression).
- `/app/parcours/[slug]` : chapitres groupés par niveau avec l'état
  **verrouillé / disponible / validé** ; `/app/parcours/[slug]/chapitres/[chapterSlug]`
  : objectifs, vidéo intégrée (`youtube-nocookie`), leçon, exercice, ressources,
  navigation précédent/suivant ; `…/quiz` : quiz du chapitre.
- **Déblocage** : un chapitre n'est accessible qu'après validation
  (score ≥ `tracks.passing_score`, 70 par défaut) du précédent. La vérification
  est faite côté serveur à deux endroits — lecture (`getLearnerChapter`) et
  soumission (`submitQuiz`) — le chapitre verrouillé n'affiche aucun contenu.
- **Correction** : `submitQuiz` (server action) relit les réponses avec la clé
  service role, calcule le score, cumule `attempts` / `best_score`, écrit
  `chapter_progress` puis renvoie le détail question par question au client
  (`QuizPlayer` affiche score, explications et lien vers la suite).
- Contenu de démonstration : 1 parcours complet (Python, 2 niveaux × 4
  chapitres), ajouté par seed SQL — l'édition admin des chapitres arrive à
  l'étape 7.

### Paiements (nyole)

- **Fournisseur** : `PAYMENT_PROVIDER` (`mock` = simulation locale pour les
  tests, `nyole` = paiement réel). `src/lib/payments/nyole.ts` encapsule l'API
  (création de session, statut, contrôle de signature, montants en unité
  principale).
- **Parcours apprenant** : `/app/acheter` → `startCheckout` (server action) →
  la page `https://app.nyole.com/checkout/<id>` s'ouvre dans une **boîte de
  dialogue** (`CheckoutDialog`, iframe) ; « Ouvrir dans une nouvelle
  fenêtre » reste proposé en repli. L'apprenant ne quitte jamais easyTech.
- **Confirmation** (idempotente, `processPaymentEvent`) par trois canaux
  serveur complémentaires :
  1. webhook `payment.completed` signé `X-Afriflow-Timestamp` /
     `X-Afriflow-Signature` (HMAC-SHA256 du corps brut, tolérance 5 min) —
     `POST /api/webhooks/payment` ;
  2. sondage `GET /api/payments/status?purchase=…` (apprenant authentifié,
     achat vérifié, montant contrôlé) toutes les 3 s depuis le dialogue ;
  3. page de retour `/paiement/retour?ref=<purchase id>` (statut de la session
     vérifié), qui referme aussi le dialogue via `postMessage`.
  Toutes les sources partagent le même `event_id` (`nyole:<session id>`) :
  un envoi multiple ne valide qu'une fois.
- **Devise : tout est en CDF.** Les tarifs saisis dans `/admin/tarifs` sont
  des francs congolais (aucun signe `$` dans l'interface), les sessions nyole
  sont créées avec `currency: "CDF"` et chaque purchase stocke
  `currency = "CDF"` (colonnes historiques `price_usd` / `amount_usd`
  conservées telles quelles, valeurs en CDF).
- **Montants** : entiers dans l'**unité principale** de la devise — 28 000 CDF
  est envoyé en `28000` avec `currency: "CDF"` (nyole n'attend pas de cents ;
  le franc congolais n'en a pas). Un montant inférieur au prix affiché
  est refusé ; une session `PENDING` créée à un autre prix n'est jamais
  réutilisée (le prix a peut-être changé depuis).
- **Webhook** : `npm run nyole:webhook https://mon-domaine/api/webhooks/payment`
  (PATCH `/v1/config/webhook`). L'URL doit être publique et en HTTPS : en
  local, passez par un tunnel (ngrok, cloudflared) et renseignez
  `NYOLE_WEBHOOK_URL`. Sans webhook, le dialogue confirme quand même par la
  vérification de statut.
- **Tests** : `npm run test:payment` couvre les deux modes — mock (achat
  immédiat) et nyole (dialogue ouvert, session créée, statut `PENDING`,
  webhook signé accepté, signature invalide refusée, niveau débloqué).

## Conventions

- **Design** : thème sombre par défaut, palette bleu électrique + accent cyan,
  tokens centralisés dans `src/app/globals.css`.
- **i18n** : tous les textes sont dans `src/i18n/messages/fr.ts` ; ajouter
  `messages/en.ts` typé par `Messages` pour l'anglais.
- **Contenu** : les catégories et parcours vivent dans Supabase
  (`categories`, `tracks`) et se gèrent depuis `/admin/categories` ;
  `src/config/catalog.ts` ne sert plus que de repli hors ligne.
- **Vidéos** : uniquement des liens intégrés via le lecteur officiel
  (`youtube-nocookie.com`), avec crédit visible ; aucun hébergement ni
  téléchargement de vidéos tierces. Les ressources externes restent dans une
  section « Ressources recommandées » séparée du contenu propriétaire.
- **Paiement** : la confirmation vient uniquement de canaux serveur (webhook
  signé, vérification du statut de la session, page de retour), dédupliquée par
  `event_id` — jamais de la seule navigation du navigateur. Toutes les clés
  restent côté serveur (`.env.local`).

## Sécurité

- Aucune clé secrète dans le code client (prefixe `NEXT_PUBLIC_` réservé aux
  valeurs publiques).
- Les contenus payants seront verrouillés côté serveur (RLS PostgreSQL +
  vérification de droits avant toute ressource).
- Les webhooks de paiement sont vérifiés par HMAC-SHA256 sur le corps brut,
  avec tolérance d'horodatage de 5 minutes et déduplication.

## Licence

Tous droits réservés — easyTech.
