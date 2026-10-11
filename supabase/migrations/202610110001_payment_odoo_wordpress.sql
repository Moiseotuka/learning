-- easyLearn — parcours e-commerce : paiement, Odoo, WordPress
-- Ajoute la catégorie E-commerce et les parcours de paiement / Odoo / WordPress.
-- Idempotent : on conflict do nothing pour les identifiants déjà présents.

insert into public.categories (id, slug, name, description, icon, levels, track_count, position)
values
  ('ecom', 'e-commerce', 'E-commerce et paiements', 'Paiements, WooCommerce, Odoo, WordPress et vente en ligne.', 'shopping-cart', array['debutant','intermediaire','avance'], 3, 11)
on conflict (id) do nothing;

insert into public.tracks (id, category_id, slug, title, description, level, duration_hours, modules_count, price_usd, rating, students, position, published)
values
  ('paiement-en-ligne', 'ecom', 'paiement-en-ligne', 'Paiement en ligne : PawaPay, CinetPay, WooCommerce', 'Mettre en place un checkout fiable, sécurisé et compatible mobile.', 'debutant', 26, 6, 79, 4.8, 980, 1, true),
  ('odoo-commerce', 'ecom', 'odoo-commerce', 'Odoo : vente, facturation et workflow commercial', 'Gérer les commandes, les clients et les paiements avec Odoo.', 'intermediaire', 30, 6, 89, 4.7, 720, 2, true),
  ('wordpress-commerce', 'ecom', 'wordpress-commerce', 'WordPress et WooCommerce : boutique, checkout et sécurité', 'Créer et sécuriser une boutique WordPress avec WooCommerce.', 'debutant', 24, 6, 69, 4.8, 840, 3, true)
on conflict (id) do nothing;

insert into public.chapters
  (id, track_id, level, slug, title, summary, objectives, videos, position, published)
values
  ('pmt-c1', 'paiement-en-ligne', 'debutant', 'paiement-introduction', 'Introduction aux paiements en ligne', 'Comprendre les flux de paiement, la chaîne de confiance et les risques.', array['Identifier les acteurs d''un paiement en ligne', 'Comprendre le rôle d''un PSP', 'Évaluer la sécurité d''un checkout'], '[]'::jsonb, 1, true),
  ('pmt-c2', 'paiement-en-ligne', 'debutant', 'paiement-pawapay', 'PawaPay et paiements mobiles', 'Configurer la collecte mobile, les callbacks et le UX checkout.', array['Évaluer un fournisseur mobile money', 'Mettre en place un flux de paiement mobile', 'Sécuriser les callbacks et les statuts'], '[]'::jsonb, 2, true),
  ('pmt-c3', 'paiement-en-ligne', 'intermediaire', 'paiement-cinetpay', 'CinetPay, WooCommerce et intégration storefront', 'Relier le magasin et les outils de paiement à un flow de commande fiable.', array['Brancher un portail de paiement', 'Relier le panier au paiement', 'Gérer les retours d''API et les erreurs'], '[]'::jsonb, 3, true),
  ('odo-c1', 'odoo-commerce', 'debutant', 'odoo-vente', 'Odoo : clients, produits et commandes', 'Découvrir la structure commerciale d''Odoo et la gestion du catalogue.', array['Créer un produit et un client', 'Gérer un bon de commande', 'Suivre le cycle de vente'], '[]'::jsonb, 1, true),
  ('odo-c2', 'odoo-commerce', 'intermediaire', 'odoo-facturation', 'Facturation, TVA et gestion des paiements', 'Automatiser la facturation et faire correspondre les paiements au bon document.', array['Produire une facture depuis une commande', 'Élaborer un workflow de paiement', 'Gérer les taxes et les échéances'], '[]'::jsonb, 2, true),
  ('odo-c3', 'odoo-commerce', 'intermediaire', 'odoo-workflow', 'Workflow d''expédition et de support', 'Relier la vente à la livraison, aux litiges et au service client.', array['Déclencher la livraison', 'Traiter les retours', 'Mesurer la satisfaction et le taux d''erreur'], '[]'::jsonb, 3, true),
  ('wp-c1', 'wordpress-commerce', 'debutant', 'wordpress-debut', 'WordPress pour une boutique', 'Mettre en place la base d''un site e-commerce WordPress.', array['Installer WordPress', 'Choisir un thème et un plugin de boutique', 'Configurer le site pour la vente'], '[]'::jsonb, 1, true),
  ('wp-c2', 'wordpress-commerce', 'debutant', 'wordpress-woocommerce', 'WooCommerce : catalogues, produits et checkout', 'Construire le catalogues et mieux comprendre le flux de paiement.', array['Créer des produits et variantes', 'Configurer les taxes et les livraisons', 'Optimiser le checkout'], '[]'::jsonb, 2, true),
  ('wp-c3', 'wordpress-commerce', 'intermediaire', 'wordpress-securite', 'Sécurité, maintenance et optimisation', 'Garder la boutique fonctionnelle, rapide et sûre.', array['Limiter les risques WordPress', 'Assurer la maintenance', 'Suivre la performance et la conversion'], '[]'::jsonb, 3, true)
on conflict (id) do nothing;

update public.chapters
set content = $lesson$
Bienvenue dans le chapitre sur les paiements en ligne. Un système de paiement n'est pas simplement un bouton « Payer » : c'est un flux de confiance qui relie le client, le site, le prestataire de paiement et la comptabilité. Pour que l'appareil de vente fonctionne, chaque étape doit être claire : choisir le produit, passer au panier, cliquer sur paiement, recevoir la confirmation côté serveur, puis délivrer le service ou le produit acheté. Toute rupture dans cette chaîne fait perdre de la confiance au client et crée des litiges coûteux.

La première règle est de ne jamais considérer le paiement comme un simple « externaliser la carte bleue ». En pratique, le client ne voit qu'une interface de checkout ; l'équipe technique doit gérer les erreurs, les callbacks, les confirmations et les retours de statut. Un système robuste garde le contrôle du montant, de la commande et de l'état de la transaction. C'est exactement sur ces points que les prestataires comme PawaPay, CinetPay, Stripe ou les intégrations WooCommerce imposent une discipline: une commande ne doit être validée que si le paiement a bien été confirmé par le serveur.

Pour un parcours d'apprentissage, il faut commencer par le principe : un paiement a trois états distincts. Le client demande une transaction, le système l'enregistre et la soumet au PSP, puis le PSP valide ou refuse la transaction. Le rôle du développeur est d'éviter les faux positifs, de sécuriser les callbacks, et de rendre la confirmation explicite pour l'utilisateur. Le code n'est pas la seule variable du succès : le design, le message d'erreur et la compatibilité mobile comptent autant que le backend.

## Les briques d'un système de paiement

Un flux de paiement fiable comprend un panier, l'authentification de l'utilisateur, un montant, un référentiel de commande, un prestataire et une confirmation. La commande doit rester stable entre le moment de l'achat et la confirmation du paiement. Le site ne peut pas simplement « croire » un clic du navigateur : il doit valider le statut côté serveur, en vérifiant l'identifiant de transaction, le montant et la signature ou le hash fournis par le prestataire.

Le contexte mobile ajoute une vraie contrainte. Un client peut ouvrir le site en Wi-Fi lent, fermer l'onglet au mauvais moment, ou se reconnecter à partir d'un autre appareil en fin de paiement. Le système doit donc être idempotent, c'est-à-dire qu'il ne crée pas plusieurs paiements pour une même commande en cas de répétition ou de retrait. L'expérience est meilleure quand le client reçoit des messages clairs : paiement en cours, paiement refusé, paiement validé, commande en attente.

- Un paiement demande un identifiant commande stable et un montant vérifiable.
- La confirmation doit venir du serveur, pas du navigateur.
- Le mobile impose un UX clair et une gestion robuste des retours.
- Les 3 états clés sont : init, en attente, confirmé.
- Le bon design réduit les abandons et les litiges.

## Le bon niveau de sécurité

Le risque principal n'est pas le bouton, c'est la confiance. Si le site pense qu'une commande a été payée alors qu'elle n'a pas été validée, le service ou le produit est livré sans recette. À l'inverse, si un paiement est accepté à tort, les remboursements deviennent coûteux et la réputation souffre. Les bonnes pratiques consistent à vérifier le montant, la devise, l'état de la transaction et la signature, puis à verrouiller l'accès à la commande tant que le statut n'est pas finalisé.

Ce chapitre sert surtout à poser les bons réflexes : le flux doit être lisible, les statuts explicites, les variables de transaction contrôlées, les logs centralisés. C'est ce qui permet ensuite d'intégrer PawaPay ou CinetPay sans créer de surprise pour l'utilisateur ou pour l'équipe support.

Les outils de paiement modernes permettent de tester un workflow complet sans toucher de vraie carte ou de monnaie électronique : vous pouvez simuler les retours, vérifier une signature, et valider l'UX sur un parcours complet. C'est là que la discipline de l'architecture apparaît : chaque bouton est la fin d'un flux métier, pas un simple élément de design.
$lesson$,
exercise = 'Construisez un petit schéma de flux de paiement pour une boutique en ligne : panier, sélection d''un moyen de paiement, confirmation côté serveur, délivrance du produit, gestion des cas refusé / annulé / confirmé. Ajoutez une liste des points de validation techniques et de sécurité.',
resources = '[{"label":"Guide de sécurisation des paiements en ligne","url":"https://www.pawa.tech/"},{"label":"Documentation CinetPay","url":"https://www.cinetpay.com/"},{"label":"WooCommerce : docs checkout","url":"https://woocommerce.com/document/"}]'::jsonb,
videos = $vid$[{"title":"Paiements en ligne : le flux complet expliqué simplement","url":"https://www.youtube.com/watch?v=5Dk4zKyrfL8","channel":"Le Designer du Web"},{"title":"Comment fonctionne un paiement en ligne ?","url":"https://www.youtube.com/watch?v=8N6aHsza0N8","channel":"Code Explained"}]$vid$::jsonb
where id = 'pmt-c1';

update public.chapters
set content = $lesson$
PawaPay est un exemple de solution populaire pour les paiements mobiles, surtout quand le client est plus à l'aise avec le mobile money qu'avec une carte bancaire. Le principe est simple : le site crée une transaction, le client valide sur un flux externe, puis le backend reçoit une confirmation avec le statut final. Une bonne intégration doit couvrir au minimum les éléments suivants : montant, devise, identifiant commande, signature ou webhook, et retour Soit accepté, soit refusé, soit en attente.

Le point le plus délicat est le callback. Si le site reçoit seulement un message du navigateur, il est vulnérable à des erreurs de fermeture d'onglet, de mauvaise redirection ou de double soumission. En production, le serveur doit être la source de vérité. Les statuts de paiement doivent être idempotents : si le client répète le retour cinq fois, le système doit reconnaître qu'il s'agit du même paiement et ne doit pas délivrer le produit plusieurs fois.

Dans un commerce mobile, la simplicité du parcours est un avantage concurrentiel. Il faut éviter les interfaces trop lourdes, les pièces jointes en trop grand nombre, et les messages trop techniques. Le client doit savoir en un coup d'œil qu'il a bien payé, qu'il peut attendre la confirmation, et qu'il peut demander de l'aide s'il n'est pas sûr.

## Bonnes pratiques pour PawaPay et les services mobiles

- Garder un journal par transaction avec montant, commande et fournisseur.
- Vérifier le montant avant de valider une commande.
- Ne pas accepter les callbacks sans le bon identifiant de transaction.
- Avoir un statut de commande explicite : pending, paid, failed, refunded.
- Prévoir un retour manuel si le portail de paiement ne répond pas.

Le coût d'un mauvais callback est souvent beaucoup plus élevé que le coût d'une logique de contrôle supplémentaire. Le support a alors à traiter les litiges et les achats « douteux », ce qui nuit à la conversion sans donner de valeur au client. Les meilleures boutiques en ligne traitent le paiement comme une partie du produit, pas comme une simple étape de technique.
$lesson$,
exercise = 'Dessinez le flux complet de paiement avec PawaPay pour une commande de 20 000 FC, en prenant en compte le client, le checkout, le callback serveur, la validation, et la délivrance du service.',
resources = '[{"label":"PawaPay developer docs","url":"https://www.pawapay.com/"},{"label":"Paiements mobiles et UX","url":"https://developer.mozilla.org/fr/docs/Web/Accessibility"}]'::jsonb,
videos = $vid$[{"title":"PawaPay expliqué pour les débutants","url":"https://www.youtube.com/watch?v=9uKjY3zk8AQ","channel":"Tech Africa"},{"title":"Mobile money checkout pour boutique","url":"https://www.youtube.com/watch?v=5OQ2rx4V5-I","channel":"Business Maker"}]$vid$::jsonb
where id = 'pmt-c2';

update public.chapters
set content = $lesson$
CinetPay et les portails de paiement tiers offrent un mécanisme de checkout rapide et un bon niveau de supervision pour les boutiques. L'objectif est d'intégrer le paiement sans perdre la logique métier du site : la commande doit rester associée à un client, un montant et un statut. Dans un cas standard, la commande est créée côté site, un identifiant de paiement est envoyé au portail, puis le client valide le paiement. Une fois la confirmation reçue, le backend marque la commande comme payée et délivre le service.

Le flux CinetPay se prête bien à un système de caisse, avec des scénarios tels qu'une commande, une réimputation, un remboursement ou un paiement refusé. Ce qui différencie une intégration solide d'une intégration fragile est la capacité à gérer les retours d'une API, sans blocage de l'utilisateur. Les messages d'erreur doivent être compréhensibles. Le site ne doit pas exposer des codes techniques bruts à l'acheteur, mais le backend doit les enregistrer dans les logs de support.

L'intégration dans WooCommerce s'appuie sur le même principe : le magasin représente le catalogue et le client, tandis qu'un plugin ou un système de paiement interrompt le chaîne de vente. Le plus important est le respect de l'ordre logique : commande créée, paiement confirmé, livraison ou activation. Lorsque cette règle est respectée, la caisse devient fiable et supportable.

## Ce qu'il faut valider avant de lancer

- `amount` et `currency` correspondent bien à la commande.
- L'ID de commande est unique et non réutilisable.
- Les retours de statut sont vérifiés côté serveur.
- Les erreurs sont journalisées avec l'ID transaction.
- Le bouton et le message de confirmation sont clairs pour le client.

Les intégrations réussies ne se distinguent pas par des scripts compliqués : elles se distinguent par leur ordre logique et leur niveau de vigilance. La chaîne de paiement est une zone de confiance et elle mérite le même soin que la connexion, la base de données ou la caisse.
$lesson$,
exercise = 'Rédigez un plan d''intégration CinetPay + WooCommerce pour une boutique simple : création de commande, appel au gateway, retour utilisateur, confirmation serveur, activation du produit, gestion des erreurs et sécurité.',
resources = '[{"label":"CinetPay docs","url":"https://www.cinetpay.com/"},{"label":"WooCommerce integration guide","url":"https://woocommerce.com/document/"},{"label":"Paiement sécurise et conversion","url":"https://www.shopify.com/learn/"}]'::jsonb,
videos = $vid$[{"title":"Intégrer CinetPay dans un site e-commerce","url":"https://www.youtube.com/watch?v=FTwTgZ3No9M","channel":"Web Academy"},{"title":"WooCommerce checkout expliqué","url":"https://www.youtube.com/watch?v=J7x3wq3t1jQ","channel":"Mikado Studio"}]$vid$::jsonb
where id = 'pmt-c3';

update public.chapters
set content = $lesson$
Odoo est un ERP complet qui couvre la gestion commerciale, la comptabilité, la vente, le stock et parfois la relation client. Pour un parcours de vente, l'intérêt est clair : au lieu d'assembler des outils éparpillés, on centralise le catalogue, les prospects, les devis, les commandes, les factures et les paiements. Cela réduit les erreurs de double saisie et améliore la visibilité sur le cycle de vente.

Dans le contexte d'un commerce, Odoo permet de créer un produit, un client, un devis, puis une commande. Une fois la commande validée, le système peut générer une facture, déclencher une expédition, et tenir le statut de paiement en cohérence avec les écritures comptables. Ce flux permet de mieux comprendre ce qu'un bon ERP apporte à un commerce : la donnée unique, la traçabilité et le support des opérations récurrentes.

Le point le plus important est le sens du workflow. On ne traite pas chaque action de façon isolée ; on suit la logique du cycle de vente jusqu'à la livraison et au règlement. L'équipe opérationnelle, le comptable et le service client voient la même source de vérité. C'est cette cohérence qui permet de mieux prévoir, mieux répondre, et surtout de limiter les erreurs de facturation ou de remboursement.

## A quoi ressemble le modèle de vente Odoo

- Client → commande → validation → facture → paiement.
- Produit → stock → disponibilité → livraison.
- Service client → suivi de litige → paiement / remboursement.
- Comptabilité → rapprochement des paiements avec les écritures.

Le vrai enjeu n'est pas la techno, c'est la qualité du flux métier. Un ERP réussi est d'abord un ERP bien modélisé, avec des rôles clairs, des statuts cohérents et des règles d'automatisation simples à expliquer.
$lesson$,
exercise = 'Rédigez un workflow Odoo pour un commerce de petit volume : création du client, création du produit, validation de la commande, génération de la facture, paiement, suivi du support.',
resources = '[{"label":"Odoo sales documentation","url":"https://www.odoo.com/documentation"},{"label":"Guide Odoo CRM & sales","url":"https://www.odoo.com/fr_FR"}]'::jsonb,
videos = $vid$[{"title":"Odoo pour la gestion commerciale","url":"https://www.youtube.com/watch?v=Tk1Q4gP1d4Y","channel":"Odoo Tutorials"},{"title":"Créer une commande Odoo en 10 minutes","url":"https://www.youtube.com/watch?v=bCFGaZPxy1M","channel":"ERP Academy"}]$vid$::jsonb
where id = 'odo-c1';

update public.chapters
set content = $lesson$
La facturation est souvent le point où les outils de commerce se cassent : un produit est vendu, la commande est validée, et pourtant la facture n'a pas le bon montant, ou le paiement est enregistré sur la mauvaise ligne. Odoo aide à corriger cette situation parce qu'il lie les objets de vente, de facture et de paiement dans un même système. La clé est de garantir que chaque facture est rattachée à une commande, que chaque paiement est rattaché à une facture, et que les taxes sont calculées selon les règles actives au moment de la vente.

Dans beaucoup d'entreprises, la difficulté n'est pas la technique mais la gestion des exceptions. Un acompte, un remboursement partiel, une remise manuelle ou un client en retard modifient le flux normal. La bonne pratique consiste à garder un statut très précis et à automatiser uniquement ce qui est stable. Les règles de calcul doivent être explicites, les montants détectables et les écarts visibles dans le tableau de bord. Une facture mal calculée produit des litiges, des relances et de la mauvaise volonté.

Une autre dimension importante est la conformité fiscale. Le système doit savoir quelle taxe s'applique, quel mode de paiement est autorisé, et quel document de suivi est requis. Sans cette sérénité, le service commercial ne sait plus quoi vendre ni comment facturer sans s'exposer. Un ERP permet en pratique d'absorber une grande partie de cette complexité, à condition que les paramètres soient bien définis.

- La facture doit refléter la commande de façon unique.
- Le paiement doit être liée à l'élément correct.
- Les taxes et les remises doivent être explicites.
- Les écarts doivent apparaître avant la clôture.
$lesson$,
exercise = 'Élaborez le cycle de facturation d''un produit vendu avec Odoo : devis, commande, facture, paiement, relance, puis règlement partiel et rapprochement comptable.',
resources = '[{"label":"Odoo invoicing","url":"https://www.odoo.com/documentation"},{"label":"Comptabilité et TVA","url":"https://www.odoo.com/fr_FR"}]'::jsonb,
videos = $vid$[{"title":"Odoo facturation et TVA","url":"https://www.youtube.com/watch?v=4S2mSOAZ4v4","channel":"Odoo Tips"},{"title":"Les paiements dans Odoo","url":"https://www.youtube.com/watch?v=68rpagFtW5M","channel":"ERP Channel"}]$vid$::jsonb
where id = 'odo-c2';

update public.chapters
set content = $lesson$
La vente ne s'arrête pas à la facture. Il faut aussi gérer ce qui suit : expédition, livraison, service client, retour, litige et éventuellement remboursement. Dans Odoo, c'est là que le risque de fragmentation apparaît si la relation entre le bon de commande, la livraison et le ticket support n'est pas claire. Le meilleur modèle est d'inscrire chaque événement dans la même chaîne commerciale pour qu'un agent de support puisse voir l'historique sans ouvrir plusieurs outils.

Les bons workflows introduisent des règles simples. Préparer la commande, confirmer l'envoi, notifier le client, valider le retour si besoin, rapprocher le paiement et la facture. En complétant ce cycle, l'entreprise gère aussi le service après-vente. Dans le commerce en ligne moderne, la satisfaction client naît autant de la qualité du service que de la qualité du produit. Une bonne commande ne suffit pas : la pilule de support doit être fiable et rapide.

Le travail sur les processus est souvent plus important que le travail sur les outils. Un système de gestion ne remplace pas une politique claire de traitement du retour, des annulations ou des paiements manquants. Ce que les équipes attendent est une vue claire, des statuts lisibles, des rôles propres et des messages de support compréhensibles. Cela donne de la stabilité à la relation client.
$lesson$,
exercise = 'Rédigez un workflow de support après vente dans Odoo : commande validée, livraison, retour, ticket, règlement et clôture. Mentionnez les statuts et les actions de chaque acteur.',
resources = '[{"label":"Odoo workflow support","url":"https://www.odoo.com/documentation"},{"label":"Gestion de la relation client","url":"https://www.odoo.com/fr_FR"}]'::jsonb,
videos = $vid$[{"title":"Workflow de vente Odoo complet","url":"https://www.youtube.com/watch?v=K8GvKxR2wJ0","channel":"Odoo Classes"},{"title":"Support client avec Odoo","url":"https://www.youtube.com/watch?v=6YQ1MZVh0-0","channel":"ERPHub"}]$vid$::jsonb
where id = 'odo-c3';

update public.chapters
set content = $lesson$
WordPress est souvent le point d'entrée le plus simple pour créer une boutique en ligne. Le CMS est connu, il suffit d'installer les bons plugins, puis de configurer les produits et le paiement. À l'atelier, la clé n'est pas la quantité de plugins mais la bonne architecture : un thème clair, des pages d'accueil cohérentes, un catalogue, un panier, un checkout, et des outils de sécurité.

Lorsque l'on met en place une boutique WordPress, l'équipe doit considérer la plateforme comme un système technique qu'il faudra maintenir. Un thème de qualité, un plugin de boutique, une configuration de taxes et des règles de sécurité sont indispensables. Pour un e-commerce, la conversion dépend de la simplicité du cours d'achat, du temps de chargement et de la qualité du checkout. Un site joli mais peu fiable ne transforme pas les visiteurs en clients.

Le plus important est donc la base. Le site doit être propre, les plugins limités, le stockage des produits bien structuré, les pages essentielles bien configurées. Une boutique WordPress réussie n'est pas un site qui contient dix extensions ; c'est un site qui rend le parcours d'achat simple et sécuritaire.

## Les étapes de base d'une boutique WordPress

- Installer WordPress et sécuriser l'administration.
- Choisir un thème compatible e-commerce.
- Configurer le catalogue et la structure produits.
- Définir les taxes, la livraison et les paiements.
- Préparer les pages essentielles : accueil, produit, panier, checkout, confirmation.
$lesson$,
exercise = 'Proposez la structure d''un site WordPress pour une boutique simple : accueil, catalogue, produit, panier, checkout, contact et mentions légales.',
resources = '[{"label":"WordPress documentation","url":"https://wordpress.org/documentation/"},{"label":"Sécurité WordPress","url":"https://wordpress.org/support/article/hardening-wordpress/"}]'::jsonb,
videos = $vid$[{"title":"Créer un site e-commerce WordPress","url":"https://www.youtube.com/watch?v=Vv4K8mPa1zE","channel":"WordPress France"},{"title":"WordPress débutant : installation et configuration","url":"https://www.youtube.com/watch?v=8Sgc4fKmkUs","channel":"Tutoriel WordPress"}]$vid$::jsonb
where id = 'wp-c1';

update public.chapters
set content = $lesson$
WooCommerce transforme WordPress en boutique e-commerce. Le moteur de l'outil repose sur des produits, des variantes, des catégories, des paramètres de livraison et un checkout prêt à l'emploi. L'objectif est de garder le parcours de vente très clair : le client trouve le produit, le choisit, passe en panier, valide la commande et reçoit une confirmation. Le système doit aussi permettre la gestion des stocks, des taxes et des variantes comme la taille, la couleur ou le type produit.

Le vrai défi est la simplicité. Une boutique fonctionne bien quand le client n'a pas à deviner le parcours. Les champs nécessaires doivent être limités, les erreurs expliquées, et les messages de validation lisibles. Il faut aussi distinguer la flexibilité qui vient de WooCommerce de la complexité qui vient d'un trop grand nombre de plugins. La plupart des boutiques problématiques ont intégré trop d'extensions sans avoir mis en place un plan de maintenance. Vous gagnez autant à garder un site propre qu'à ajouter des fonctions coûteuses.

## Ce qu'il faut surveiller

- Coherence entre stock, prix et statut de produit.
- Taxes et valeurs de livraison correctes.
- Checkout simple et compatible mobile.
- Gestion des erreurs sur la commande.
- Messages de confirmation clairs.

Le magasin ne doit pas devenir un labyrinthe de plugins. Les meilleurs projets WooCommerce choisissent une architecture simple et fondée sur des besoins métier concret.
$lesson$,
exercise = 'Décrivez le parcours de commande WooCommerce d''un produit physique : ajout au panier, réglage des options, calcul du montant, validation, paiement, confirmation et suivi.',
resources = '[{"label":"WooCommerce docs","url":"https://woocommerce.com/documentation/"},{"label":"Produits et variantes","url":"https://woocommerce.com/document/product-variations/"}]'::jsonb,
videos = $vid$[{"title":"WooCommerce tutorial pour boutique","url":"https://www.youtube.com/watch?v=q_vrH8n5tLc","channel":"WPTuts"},{"title":"Configurer WooCommerce","url":"https://www.youtube.com/watch?v=1jnTsWxBMA0","channel":"OpenClassrooms"}]$vid$::jsonb
where id = 'wp-c2';

update public.chapters
set content = $lesson$
La sécurité est le deuxième grand sujet d'une boutique en ligne, après le produit. WordPress et WooCommerce sont très puissants, mais la plateforme est aussi un système ouvert qui nécessite une maintenance sérieuse. Le thème, les plugins, les mises à jour, les utilisateurs administrateurs et les identifiants de paiement doivent être confiés à une politique claire. Sans ça, le site devient plus vulnérable que le produit qu'il vend.

La bonne posture consiste à concevoir le site comme une application business critique. Les mises à jour du cœur WordPress, du thème et des plugins doivent être surveillées, les comptes administrateurs limités, les accès de maintenance rangés, et les sauvegardes planifiées. Les paiements doivent aussi être protégés par des normes de sécurité : connexion HTTPS, validation des paiements côté serveur, contrôle des statuts, logs de support et traitement des erreurs de manière explicite.

Le dernier point est la performance. Une boutique lente abandonne les visiteurs. Un site WordPress bien optimisé combine cache, images réduites, plugin de performance et optimisation du checkout. En e-commerce, la stabilité des ventes dépend autant de la sécurité que de la vitesse. Ce sont deux dimensions d'un même objectif : faire confiance et convertir sans friction.

- Limiter les privilèges d'administration.
- Mettre à jour le CMS et les plugins régulièrement.
- Sauvegarder avant chaque changement critique.
- Garder une checklist de paiement et de sécurité.
- Mesurer le temps de chargement et les conversions.
$lesson$,
exercise = 'Préparez une checklist de sécurité et de maintenance pour une boutique WordPress/WooCommerce : sauvegardes, mises à jour, droits, paiement, performance, logs et support.',
resources = '[{"label":"Sécuriser WordPress","url":"https://wordpress.org/support/article/hardening-wordpress/"},{"label":"WooCommerce security","url":"https://woocommerce.com/document/"},{"label":"Performance WordPress","url":"https://developer.wordpress.org/"}]'::jsonb,
videos = $vid$[{"title":"Sécuriser WordPress e-commerce","url":"https://www.youtube.com/watch?v=ikQZPdaRjD0","channel":"WP Beginner"},{"title":"Performance WordPress pour boutique","url":"https://www.youtube.com/watch?v=0klN_6JZQ1s","channel":"WordPress Rocket"}]$vid$::jsonb
where id = 'wp-c3';

insert into public.quiz_questions
  (id, chapter_id, question, choices, answer_index, explanation, position)
values
  ('pmt-c1-q1', 'pmt-c1', 'Quel état doit être vérifié côté serveur avant de livrer un produit ?', '["Le bouton du client est cliqué", "Le montant est visible dans le navigateur", "Le statut du paiement est confirmé par le backend", "Le produit est déjà affiché dans le panier"]', 2, 'La confirmation du paiement doit bien venir du serveur et non du navigateur.', 1),
  ('pmt-c1-q2', 'pmt-c1', 'Quel principe évite les paiements dupliqués ?', '["La commande est créée chaque fois", "Le backend est idempotent sur la transaction", "Le client ne peut pas saisir d''ID", "Le checkout est ouvert en fenêtre popup"]', 1, 'L''idempotence garantit qu''une même commande ne se paie pas plusieurs fois.', 2),
  ('pmt-c1-q3', 'pmt-c1', 'Pourquoi les callbacks doivent être vérifiés ?', '["Pour ralentir le site", "Pour éviter les faux paiements et les erreurs de commande", "Parce que le client les voit", "Parce qu''ils sont sans danger"]', 1, 'Les callbacks doivent être validés pour éviter le faux positif et le double paiement.', 3),
  ('pmt-c2-q1', 'pmt-c2', 'Que doit contenir la transaction de paiement ?', '["Le montant, la devise et l''identifiant de commande", "Seulement le nom du client", "Seulement la couleur du produit", "Un message HTML"]', 0, 'Le paiement doit être relié à une commande unique et à son montant exact.', 1),
  ('pmt-c2-q2', 'pmt-c2', 'Quel risque est le plus important en cas de callback non vérifié ?', '["Le CSS ne s''affiche pas", "La commande peut être validée sans paiement réel", "L''image du produit ne charge pas", "Le thème WordPress est différent"]', 1, 'Un callback non vérifié peut créer des commandes sans paiement réel.', 2),
  ('pmt-c2-q3', 'pmt-c2', 'Quel message utile faut-il donner au client ?', '["Paiement refusé, veuillez réessayer", "Le service est bloqué", "Erreur technique inconnue", "Aucun message"]', 0, 'Un message clair réduit le stress et aide à la résolution de litige.', 3),
  ('pmt-c3-q1', 'pmt-c3', 'Quel objectif prioritaire d''une intégration WooCommerce ?', '["Mélanger tous les plugins", "Créer un parcours de commande fiable et fiable", "Supprimer les taxes", "Remplacer le site par un formulaire"]', 1, 'Le vrai objectif est de sécuriser et de fiabiliser le checkout.', 1),
  ('pmt-c3-q2', 'pmt-c3', 'Quand une commande doit-elle être validée ?', '["Dès l''affichage catégoriel", "Après confirmation de paiement côté serveur", "Avant l''ajout au panier", "Toujours en front"]', 1, 'La validation du paiement côté serveur protège le commerce.', 2),
  ('pmt-c3-q3', 'pmt-c3', 'Quel élément aide le support en cas de litige ?', '["Un journal avec ID transaction et statut", "L''absence de log", "Le message du navigateur uniquement", "Le nombre de produits dans le panier"]', 0, 'Les logs de transaction sont essentiels au support et à la traçabilité.', 3),
  ('odo-c1-q1', 'odo-c1', 'Que représente le cycle de vente dans Odoo ?', '["La liste de produits sans commande", "Le chemin client de commande à paiement", "Uniquement la livraison", "Le thème de la boutique"]', 1, 'Odoo vise à relier le client, la vente et le paiement dans le même flux.', 1),
  ('odo-c1-q2', 'odo-c1', 'Pourquoi Odoo est utile pour la gestion commerciale ?', '["Parce qu''il centralise les données métier", "Parce qu''il supprime les taxes", "Parce qu''il affiche un catalogue sans données", "Parce qu''il est seulement un thème"]', 0, 'Le vrai gain d''Odoo est la centralisation et la traçabilité commerciale.', 2),
  ('odo-c1-q3', 'odo-c1', 'Quel est le bon ordre métier ?', '["Commande → facture → paiement → livraison", "Facture → produit → retour", "Paiement → stock → commande", "Produit → blog → support"]', 0, 'Le flux commercial correct est de passer par la commande, la facture et le paiement.', 3),
  ('odo-c2-q1', 'odo-c2', 'Pourquoi la facturation doit être liée à la commande ?', '["Pour mieux vendre sans stock", "Pour assurer la bonne correspondance montant / client / produit", "Parce que Odoo le fait seul", "Parce que les remises sont inutiles"]', 1, 'La facture doit refléter la commande validée et le montant réel.', 1),
  ('odo-c2-q2', 'odo-c2', 'Que faut-il contrôler avant de clôturer une facture ?', '["Le style du thème", "Le montant, la taxe et le client", "Le nombre d''images du produit", "Le code couleur du site"]', 1, 'Les montants, taxes et client doivent être corrects avant clôture.', 2),
  ('odo-c2-q3', 'odo-c2', 'Que favorise un bon workflow comptable ?', '["La confusion entre paiements et produit", "La traçabilité et la réduction des litiges", "La suppression des tickets support", "L''absence de règles"]', 1, 'Un workflow comptable bien structuré réduit les erreurs et les litiges.', 3),
  ('odo-c3-q1', 'odo-c3', 'Qu''est-ce qui permet d''éviter les litiges après vente ?', '["Un support sans historique", "Un historique de commande, livraison et retour cohérent", "Un thème plus grand", "Un magasin avec plus de produits"]', 1, 'Un historique complet permet au support de traiter le retour ou le remboursement correctement.', 1),
  ('odo-c3-q2', 'odo-c3', 'Quel état du workflow est utile à suivre ?', '["Le statut de livraison et de ticket support", "Seulement le prix", "Seulement l''adresse e-mail", "Le nombre de clics"]', 0, 'Les statuts métier doivent être lisibles pour la livraison et le support.', 2),
  ('odo-c3-q3', 'odo-c3', 'Quel avantage d''un workflow centralisé ?', '["Il réduit la communication avec le client", "Il évite de multiplier les outils de suivi", "Il supprime la facture", "Il rend le site plus rapide"]', 1, 'Le workflow centralisé réduit la fragmentation et la confusion interne.', 3),
  ('wp-c1-q1', 'wp-c1', 'Pourquoi WordPress est souvent utilisé pour une boutique ?', '["Parce qu''il est livré avec un port de paiement", "Parce qu''il est simple à installer et extensible", "Parce qu''il n''a pas de maintenance", "Parce qu''il ne gère pas les pages"]', 1, 'WordPress est accessible, extensible et simple à mettre en place pour un premier magasin.', 1),
  ('wp-c1-q2', 'wp-c1', 'Quel élément est essentiel au démarrage ?', '["Un site avec un thème et des pages de vente", "Un lancement sans produit", "Un site entièrement codé en JavaScript", "Un plugin de paiement unique"]', 0, 'La base d''un site e-commerce est un catalogue et des pages de vente prêtes à être parcourues.', 2),
  ('wp-c1-q3', 'wp-c1', 'Quel point clé permet de convertir ?', '["Un thème trop chargé", "Un parcours de vente simple et clair", "Des pages très longues sans hiérarchie", "Un plugin qui remplace tout"]', 1, 'La clarté du parcours de commande influe directement sur la conversion.', 3),
  ('wp-c2-q1', 'wp-c2', 'Quel concept central dans WooCommerce ?', '["Le catalogue et le panier", "Le backend purement visuel", "La simple page d''accueil", "Le blog sans produits"]', 0, 'Le bon commerce repose sur les produits, les variantes et le panier.', 1),
  ('wp-c2-q2', 'wp-c2', 'Quel point touche le plus le client ?', '["Le checkout et la clarté du montant", "La couleur de la police", "Le nombre de catégories", "Le logo sur le menu"]', 0, 'Le checkout et le montant influent directement sur la confiance et le taux de conversion.', 2),
  ('wp-c2-q3', 'wp-c2', 'Pourquoi limiter le nombre de plugins ?', '["Pour réduire le temps de compréhension", "Pour éviter la complexité et la maintenance", "Parce que WooCommerce ne fonctionne qu''avec un seul plugin", "Pour bloquer les mises à jour"]', 1, 'Trop de plugins augmentent les risques et la complexité de maintenance.', 3),
  ('wp-c3-q1', 'wp-c3', 'Quel point clé pour les boutiques WordPress ?', '["La sécurité et la maintenance", "Le blog seul", "Le CMS sans mise à jour", "Le design unique uniquement"]', 0, 'La sécurité et l''entretien sont centraux pour une boutique en ligne.', 1),
  ('wp-c3-q2', 'wp-c3', 'Que faut-il surveiller en plus du paiement ?', '["La performance et la vitesse", "Le nombre de menu item", "L''absence de thème", "L''ordre des catégories"]', 0, 'La performance a un impact direct sur la conversion et la confiance.', 2),
  ('wp-c3-q3', 'wp-c3', 'Quelle bonne pratique évite les erreurs ?', '["Mettre à jour les composants régulièrement", "Ne jamais sauvegarder le site", "Supprimer les comptes qui ne sont pas utilisés", "Faire la maintenance seulement en cas de bug"]', 0, 'La maintenance régulière évite les failles et les incidents de paiement.', 3)
on conflict (id) do nothing;
