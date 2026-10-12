# Checklist de déploiement Vercel - easyLearn

## ✅ Pré-requis

- [ ] Compte Vercel connecté à GitHub/GitLab
- [ ] Projet Supabase créé et accessible
- [ ] Compte Nyole configuré (Mobile Money + Carte)
- [ ] Compte Resend pour les emails
- [ ] Repo GitHub/GitLab à jour

## 🔧 Configuration Vercel

### 1. Import du projet
- [ ] Importer le repo depuis Vercel Dashboard
- [ ] Framework détecté : Next.js (auto)
- [ ] Build Command: `npm run build` (auto)
- [ ] Output Directory: `.next` (auto)
- [ ] Install Command: `npm ci` (auto)

### 2. Variables d'environnement (Settings > Environment Variables)

Ajouter pour **Production**, **Preview**, **Development** :

#### Supabase (REQUIS)
```
NEXT_PUBLIC_SUPABASE_URL=https://gmgmrywvloszxlqmellw.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Application
```
NEXT_PUBLIC_SITE_URL=https://VOTRE_APP.vercel.app
NEXT_PUBLIC_APP_NAME=easyLearn
```

#### Paiement Nyole
```
PAYMENT_PROVIDER=nyole
NYOLE_SECRET_KEY=af_live_sec_...
NYOLE_PUBLIC_KEY=af_live_pub_...
NYOLE_WEBHOOK_URL=https://VOTRE_APP.vercel.app/api/webhooks/payment
```

#### Email Resend
```
RESEND_API_KEY=re_...
EMAIL_FROM="easyLearn <bonjour@votre-domaine.com>"
```

#### Sécurité
```
PAYMENT_WEBHOOK_SECRET=<openssl rand -hex 32>
```
La route webhook refuse la valeur d'exemple et rend un 503 tant qu'un secret
aléatoire n'a pas été configuré — sinon n'importe qui connaissant le dépôt
pourrait déclarer un paiement confirmé.

### 3. Build & Deploy

```bash
# Test build local
npm run build
npm run lint
npm run typecheck

# Push et déploiement automatique via Vercel
git push origin main
```

## 🔄 Post-déploiement

### 1. Mettre à jour l'URL réelle
```bash
# Dans Vercel Dashboard > Settings > Domains
# Copier l'URL réelle (ex: https://easylearn-xxx.vercel.app)
# Mettre à jour NEXT_PUBLIC_SITE_URL
# Mettre à jour NYOLE_WEBHOOK_URL = https://VOTRE_APP.vercel.app/api/webhooks/payment
```

### 2. Configurer le webhook Nyole
- Aller dans Dashboard Nyole > Webhooks
- Ajouter : `https://VOTRE_APP.vercel.app/api/webhooks/payment`
- Événements : `payment.completed` (confirmation), puis `payment.failed`,
  `payment.cancelled`, `payment.updated` pour le suivi

### 3. Configurer Supabase Auth
- Authentication > URL Configuration
- Site URL: `https://VOTRE_APP.vercel.app`
- Redirect URLs: `https://VOTRE_APP.vercel.app/**`

### 4. Configurer Resend
- Ajouter domaine vérifié dans Resend
- Mettre à jour `EMAIL_FROM` avec domaine vérifié

## ✅ Tests post-déploiement

- [ ] Page d'accueil charge
- [ ] Inscription / Connexion fonctionne
- [ ] Catalogue affiche les parcours publiés
- [ ] Inscription gratuite (niveau Débutant)
- [ ] Paiement Nyole (mode test) fonctionne
- [ ] Webhook Nyole reçu (logs Vercel Functions)
- [ ] Examen niveau fonctionne
- [ ] Certificat généré + email envoyé
- [ ] Profil affiche certificats
- [ ] Page `/verifier?code=XXX` fonctionne

## 🔧 Commandes utiles

```bash
# Build local
npm run build

# Lint
npm run lint

# Type check
npm run typecheck

# Dev local
npm run dev

# Vérifier variables d'env
vercel env ls

# Logs fonctions
vercel logs
```

## 📋 Fichiers de config créés

- `vercel.json` - Config Vercel (headers, rewrites, functions)
- `.env.example` - Template variables d'environnement

## 🚨 Points d'attention

1. **SUPABASE_SERVICE_ROLE_KEY** : Jamais dans `NEXT_PUBLIC_` !
2. **NYOLE_WEBHOOK_URL** : Doit matcher exactement l'URL Vercel + `/api/webhooks/payment`
3. **Domaine Resend** : Doit être vérifié avant envoi emails
3. **Supabase Auth** : Site URL + Redirect URLs doivent matcher l'URL Vercel
4. **Build** : `npm run build` doit passer en local avant push

## 🆘 Dépannage

| Problème | Solution |
|----------|----------|
| Build échoue | `npm run build` local, vérifier erreurs TypeScript |
| Auth ne marche pas | Vérifier Supabase Auth URLs + clés anon/service |
| Paiement échoue | Logs Vercel Functions > nyole webhook |
| Email non envoyé | Vérifier domaine Resend + RESEND_API_KEY |
| Certificat non généré | Vérifier `level_exams` + `certificates` tables + `ensureCertificates` |

## 📞 Support

- Vercel Docs: https://vercel.com/docs
- Supabase Docs: https://supabase.com/docs
- Nyole Docs: https://nyole.com/docs
- Resend Docs: https://resend.com/docs