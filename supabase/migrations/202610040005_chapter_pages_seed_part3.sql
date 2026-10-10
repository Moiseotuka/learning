-- easyLearn — seed des pages numérotées du Cours (678 pages, 44 chapitres)
-- Chaque section « ## » d'une leçon devient une page titrée.
-- Idempotent : remplace les pages des chapitres listés.
-- Généré par scripts/generate-pages-migration.mjs — ne pas éditer à la main.
-- Prérequis : 202610040004_chapter_pages.sql (table chapter_pages).



insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('net-c7-p1', 'net-c7', 1, $lesson$Ce que l'on protège, et contre qui$lesson$, $lesson$
Bienvenue dans le septième et dernier chapitre du parcours Réseaux, consacré à la sécurité réseau opérationnelle : contrôle d'accès au port avec 802.1X, VPN site-à-site chiffré, et durcissement des équipements. Les six chapitres précédents ont fait tout le travail de fond : vous savez segmenter un réseau en VLAN, faire dialoguer TCP et UDP, installer des routes statiques et des adjacences OSPF, filtrer avec des ACL, traduire des adresses avec le NAT, mesurer la latence et capturer des paquets avec tcpdump. Toute cette infrastructure suppose toutefois une hypothèse commode et dangereuse : que celui qui se branche sur un port, qui atteint une adresse de gestion ou qui traverse un lien mérite d'être là. Ce dernier chapitre retire cette hypothèse. Il vous apprend à exiger une identité avant d'ouvrir un port, à chiffrer les échanges entre deux sites distants, et à retirer aux équipements tout ce qui n'est pas nécessaire à leur fonctionnement. C'est la différence entre un réseau qui fonctionne et un réseau qui tient devant un test, un audit ou un incident.

À la fin de cette leçon, vous saurez faire trois groupes d'opérations très concrètes. Sur le contrôle d'accès, vous décrirez le dialogue complet entre un supplicant, un commutateur authenticateur et un serveur RADIUS, vous choisirez la méthode d'authentification adaptée à chaque population (EAP-TLS pour les postes certifiés, PEAP-MSCHAPv2 pour les comptes, MAB pour les imprimantes et les objets connectés), vous configurerez le VLAN dynamique renvoyé par le serveur, le VLAN invité de repli et la journalisation des sessions, puis vous testerez un poste non autorisé qui doit se retrouver confiné. Sur le VPN, vous établirez un tunnel IPsec IKEv2 entre deux pare-feux, en choisissant les algorithmes, le groupement de clés, la détection de pair mort et l'exemption de NAT, puis vous vérifierez le tunnel avec les commandes de diagnostic avant de tester le trafic réel de bout en bout. Sur le durcissement, vous appliquerez une checklist complète à un commutateur, à un routeur et à un pare-feu : services désactivés, gestion en SSH seul, comptes locaux hachés, journalisation horodatée, horloge authentifiée, SNMPv3 en lecture seule, protection des ports d'accès et filtrage anti-spoofing en bordure.

Le fil rouge de la leçon reste le site Lilas de la fiction du parcours : un cœur R1 et R2, un pare-feu de bordure, trois commutateurs d'accès dans les bâtiments A, B et C, un serveur RADIUS situé en VLAN de gestion 10.10.0.10, et un site distant, le siège, relié par Internet public sur le réseau 192.168.100.0/24. Deux conseils avant de commencer, parce qu'ils valent plus que toute la théorie. Le premier concerne 802.1X : déployez-le toujours sur un seul port de test, avec un port de secours connu et joignable, avant de l'étendre à un bâtiment entier, car une mauvaise configuration isole tout le monde et vous pouvez vous enfermer dehors de votre propre réseau. Le second concerne le durcissement : prenez toujours une sauvegarde de la configuration avant d'appliquer quoi que ce soit, et documentez chaque exception, car un contrôle de sécurité qui interrompt un service métier est un contrôle qui sera annulé le jour même.



La sécurité réseau ne se résume pas à installer un produit : elle commence par savoir ce que l'on protège et contre qui. Sur un réseau d'entreprise, quatre catégories de biens méritent une attention particulière. Les identifiants d'administration, car ils ouvrent la main courante de toute l'infrastructure. Les données en transit, car elles traversent des liens que l'on ne possède pas, en particulier Internet entre deux sites. Les points d'entrée physiques, car un port Ethernet libre dans une salle de réunion est une connexion réseau gratuite pour un visiteur. Enfin la disponibilité, car un commutateur saturé par un orage de paquets de diffusion, ou un routeur dont la table de routage a été corrompue par une annonce frauduleuse, cesse de faire son travail pour tout le monde. Chacun de ces biens est attaquable par une voie différente, et chacun appelle un mécanisme différent : c'est pourquoi ce chapitre enchaîne trois mécanismes au lieu d'en présenter un seul en longueur.

L'adversaire de référence n'est pas seulement l'attaquant distant qui expédie des exploits depuis un autre continent. Il commence souvent à quelques mètres, dans le couloir, dans la salle de réunion ou chez le prestataire qui passe un après-midi dans le local technique. Le modèle de menace le plus utile est donc celui-ci : une personne capable de se brancher sur un port libre, un utilisateur dont le poste est compromis, un tiers de passage qui cherche une adresse de gestion, et enfin l'erreur humaine, qui reste de loin la première cause d'incident. Face à ces voies d'accès, les mécanismes que vous allez configurer jouent quatre rôles distincts : prouver une identité avant d'ouvrir un port, chiffrer les flux qui quittent le site, réduire la surface offerte au réseau, et rendre chaque action traçable pour qu'une anomalie soit détectée avant qu'elle ne devienne un incident déclaré.

Le tableau suivant relie chaque menace typique au mécanisme du chapitre qui la traite. Servez-vous-en comme d'une carte : à chaque ligne correspond une configuration que vous écrirez dans les sections suivantes, et un test que vous pourrez réaliser immédiatement pour vérifier que la protection est réelle plutôt que déclarative.

| Menace | Ce qu'elle exploite | Mécanisme du chapitre | Test de validation |
| --- | --- | --- | --- |
| Poste parasite branché sur un port libre | Ports d'accès ouverts à tous | 802.1X, repli invité, port-security | Brancher un poste sans certificat et vérifier son confinement |
| Fuite d'identifiants d'administration | Protocoles de gestion non chiffrés | SSH version 2 seul, comptes hachés, ACL de gestion | Tenter une session Telnet et une connexion HTTP |
| Écoute des flux entre deux sites | Liens publics non chiffrés | Tunnel IPsec IKEv2 site-à-site | Capturer le trafic sur le lien et vérifier le chiffrement ESP |
| Empoisonnement de table d'adresses | ARP sans validation | Inspection dynamique d'ARP | Injecter une fausse réponse ARP sur un port d'accès |
| Orage de diffusion saturant le commutateur | Émission excessive de trames de diffusion | Limitation de tempête et isolation de l'arbre | Émettre des paquets de diffusion en rafale et observer la coupure |
| Spoofing d'adresses source en bordure | Absence de contrôle de cohérence | Filtrage anti-spoofing et uRPF | Envoyer un paquet depuis une adresse privée sur l'interface WAN |
| Équipement laissé aux valeurs d'usine | Services et comptes par défaut | Durcissement : services, AAA, secrets changés | Auditer la configuration avec une commande d'inclusion |

Une remarque sur la portée de ces protections : elles ne sont pas décoratives, mais elles ne sont pas non plus absolues. Un contrôle d'accès au port empêche le branchement sauvage, pas l'utilisateur malveillant déjà authentifié. Un tunnel IPsec protège le transit, pas les postes en bout de chaîne. Un durcissement réduit la surface d'attaque, il ne la supprime pas. L'objectif de ce chapitre est que vous sachiez associer à chaque risque résiduel le contrôle qui le réduit le plus, puis le superviser pour savoir s'il fonctionne encore. Cette logique de couche se retrouvera tout au long de la leçon : chaque mécanisme que vous configurerez répond à une question précise, et chacun laisse subsister une question à laquelle le suivant répond.
$lesson$),
  ('net-c7-p2', 'net-c7', 2, $lesson$802.1X : l'authentification au port$lesson$, $lesson$
802.1X est une norme IEEE de contrôle d'accès au port. Son principe tient en une phrase : un port de commutateur reste fermé tant que celui qui s'y connecte n'a pas prouvé une identité acceptée. Concrètement, la norme définit trois rôles. Le supplicant est le client qui demande l'accès, généralement le système d'exploitation du poste accompagné de son client 802.1X, parfois un téléphone ou un point d'accès. L'authenticateur est l'équipement qui maîtrise le port, un commutateur ou un point d'accès : il ne décide pas lui-même, il relaie. Le serveur d'authentification est le serveur RADIUS, seul juge capable de dire si l'identité présentée est acceptable, et surtout seul à détenir la liste des identités et des règles associées. Cette séparation des rôles est la grande force du mécanisme : la logique métier reste centralisée dans un serveur, tandis que les centaines de commutateurs du réseau ne gardent qu'une commande de bascule à appliquer.

Le langage commun entre le supplicant et l'authenticateur s'appelle EAP, l'Extensible Authentication Protocol, transporté dans les trames Ethernet par le protocole EAPOL. L'échange se déroule en six temps. Le supplicant signale qu'il veut s'authentifier, soit spontanément, soit à la demande du commutateur qui lui envoie une requête d'identité. Le commutateur encapsule ensuite les messages EAP dans des requêtes RADIUS et les transmet au serveur. Le serveur choisit une méthode, par exemple un défi avec certificat ou un défi avec identifiant et mot de passe, et le supplicant répond. Si la réponse est conforme, le serveur renvoie une acceptation accompagnée d'attributs : le VLAN à affecter, le temps de session maximal, parfois une liste d'accès. Le commutateur applique alors ces attributs et ouvre le port. En cas de refus, le port reste fermé ou bascule dans un VLAN de repli selon la configuration locale. L'ensemble dure quelques secondes dans le meilleur des cas, et c'est ce délai qui conditionne le confort perçu par l'utilisateur final.

```text
DEMONSTRATION : échange 802.1X entre les trois acteurs

 Poste (supplicant)         Commutateur (authenticateur)     Serveur RADIUS
 -----------------          --------------------------      --------------
 EAPOL-Start    --------------------------------->
                             EAP-Request/Identity  -------->
 EAP-Response/Identity  <----------------------------
                             Access-Request (EAP)  -------->
                                                         EAP-Request/TLS
                             EAP-Request/TLS       <--------
 EAP-Response/TLS (certificat) <------------------
                             Access-Request (EAP)  -------->
                                                         vérification CA
                                                         puis Access-Accept
                             Access-Accept (EAP)   <--------
 EAP-Success   <---------------------------------
                             port ouvert, VLAN 10 appliqué
                             Accounting-Start      -------->
```

Deux choix de méthode structurent réellement les déploiements. EAP-TLS exige un certificat côté client et un certificat côté serveur : c'est l'option la plus robuste, car aucun mot de passe n'est présenté et donc aucune réutilisation n'est possible, mais elle suppose une infrastructure de clés publique et une distribution de certificats sur chaque poste. PEAP-MSCHAPv2 ne demande un certificat qu'au serveur ; le poste, lui, présente un identifiant et un mot de passe enfermés dans un tunnel TLS établi avec le serveur. C'est l'option la plus courante pour les ordinateurs portables qui ne sont pas gérés par une autorité de certification, et elle reste largement acceptable à condition que les mots de passe soient robustes. Entre les deux, on trouve EAP-TTLS et EAP-FAST, moins répandus, mais utiles quand un équipement tiers ne sait faire ni l'un ni l'autre.

Une question de vocabulaire vous évitera des heures de lecture : le supplicant ne parle jamais RADIUS, il parle EAPOL, et le commutateur traduit. Si vous capturez le trafic sur un port d'accès, vous voyez des trames EAPOL encapsulant EAP ; si vous capturez le lien entre le commutateur et le serveur, vous voyez des paquets UDP vers les ports 1812 pour l'authentification et 1813 pour la comptabilité. Retenir cette distinction vous aide à décider où poser un filtre d'analyse quand un utilisateur annonce, un matin, que network ne fonctionne plus après la mise à jour de son client.

Le périmètre de déploiement se réfléchit port par port. On active 802.1X sur les ports d'accès aux utilisateurs, jamais sur les liens montants entre commutateurs, car un lien interne doit transporter plusieurs VLAN sans s'authentifier. On l'active en mode dynamique plutôt qu'en mode forcé, ce qui laisse le port ouvert pour le trafic de découverte tout en exigeant l'authentification pour le reste. On prévoit un mécanisme de repli pour les équipements incapables de dialoguer en EAP. Et surtout, on commence par un port de test : un poste de labo, un câble de secours, un compte dédié, avant de déployer par bâtiment. Un déploiement mondial conduit depuis un poste unique, sans retour arrière possible, est la seule méthode véritablement risquée ici.

- 802.1X ferme le port tant qu'aucune identité acceptée n'a été présentée.
- Trois rôles : supplicant sur le poste, authenticateur sur le commutateur, serveur RADIUS au centre.
- EAP circule dans les trames Ethernet sous forme d'EAPOL ; le commutateur l'encapsule ensuite en RADIUS.
- EAP-TLS utilise des certificats des deux côtés ; PEAP-MSCHAPv2 protège un mot de passe dans un tunnel TLS.
- Le serveur renvoie avec l'acceptation le VLAN, la durée de session et éventuellement une ACL.
- Le port de test et le port de secours précèdent toujours le déploiement à grande échelle.
- Les liens montants entre commutateurs ne doivent jamais exiger d'authentification.
$lesson$),
  ('net-c7-p3', 'net-c7', 3, $lesson$EAP, RADIUS et les VLAN dynamiques$lesson$, $lesson$
Le serveur RADIUS est le cerveau du dispositif. Il reçoit sur le port 1812 des requêtes d'authentification, les compare à sa base d'identités, puis répond par une acceptation ou un rejet. Sur le port 1813, il reçoit les messages de comptabilité qui notent l'ouverture, la reconduction et la fermeture de chaque session. Trois logiciels couvrent l'essentiel des besoins : FreeRADIUS sous Linux, très flexible et entièrement piloté par des fichiers texte ; Cisco ISE, la solution intégrée des environnements Cisco, qui ajoute de la visibilité et de la posture ; et Microsoft NPS, naturellement branché sur l'Active Directory quand vos comptes sont déjà hébergés là. Quel que soit celui que vous choisissez, le rôle reste identique : centraliser les identités, décider, renvoyer des attributs, tracer.

Ces attributs méritent une attention particulière, car c'est eux qui transforment un simple contrôle d'accès en segmentation dynamique. Le VLAN n'est plus écrit dans la configuration du commutateur : il est envoyé par le serveur dans les attributs de tunnel, à savoir Tunnel-Type de valeur VLAN, Tunnel-Medium-Type de valeur 802, et Tunnel-Private-Group-ID contenant l'identifiant du VLAN sous forme de chaîne. Le commutateur prend cet identifiant et l'applique au port. On peut aussi renvoyer un temps de session maximal, de sorte qu'une authentification soit reconduite périodiquement, et une action de terminaison qui referme le port si l'utilisateur ne se ré-authentifie pas. Le même mécanisme permet de faire atterrir une population entière dans un VLAN de production, une autre dans un VLAN invité, sans jamais toucher aux commutateurs lorsqu'un nouveau service apparaît.

```text
EXEMPLE : AAA, serveur RADIUS et 802.1X global sur un commutateur Cisco IOS

! Serveur RADIUS et groupe de serveurs
radius server RADIUS_ISE
 address ipv4 10.10.0.10 auth-port 1812 acct-port 1813
 key 0 <CLE_RADIUS_FORT>

aaa group server radius RADIUS_GROUP
 server name RADIUS_ISE

! Chaîne AAA : authentification, autorisation, comptabilité
aaa authentication dot1x default group RADIUS_GROUP
aaa authorization network default group RADIUS_GROUP
aaa accounting dot1x default start-stop group RADIUS_GROUP

! Activation globale du contrôle d'accès
dot1x system-auth-control

! Compte local de secours (panne du serveur RADIUS)
username admin privilege 15 algorithm-type scrypt secret <HACHAGE_SCRYPT>
aaa authentication login default local group RADIUS_GROUP
```

Le bloc suivant s'applique port par port. Il force le mode d'accès, demande l'authentification, fixe les temporisations de re-authentification et de reprise, et décide du comportement en cas de violation. Notez la commande qui autorise le trafic avant authentification : elle est utile pour les équipements qui doivent émettre avant de parler EAP, comme un téléphone VoIP qui a besoin d'obtenir son adresse par DHCP, mais elle affaiblit mécaniquement la protection et doit être réservée aux cas documentés. La commande qui limite les violations évite le comportement par défaut qui fait tomber le port à la première anomalie, ce qui se révèle pénible pendant une phase de déploiement où l'on cherche encore les supplicants mal configurés.

```text
EXEMPLE : port utilisateur 802.1X, imprimante en MAB et VLAN invité

! Port utilisateur standard
interface GigabitEthernet1/0/5
 description Poste bureau
 switchport mode access
 switchport access vlan 10
 authentication port-control auto
 authentication periodic
 authentication timer reauthenticate 3600
 authentication timer inactivity 60
 authentication violation restrict
 authentication open
 dot1x pae authenticator
 dot1x timeout tx-period 30
 dot1x max-reauth-req 3

! Imprimante sans supplicant : contournement par adresse MAC
interface GigabitEthernet1/0/20
 description Imprimante etage 2
 switchport mode access
 switchport access vlan 30
 authentication port-control auto
 authentication order mab dot1x
 authentication priority mab dot1x
 mab
 dot1x pae authenticator

! Repli en cas d'echec : VLAN 99 sans acces au reseau interne
fallback profile GUEST_VLAN
 access-group name GUEST_ACL

ip access-list extended GUEST_ACL
 permit udp any any eq 67
 permit udp any any eq 68
 permit icmp any any
 deny   ip any any log
```

La comptabilité clôt le sujet. Chaque session produit un départ, des relevés périodiques et une fin, chacun associé à l'identité, au port, au VLAN et à la durée. Cette trace répond en pratique à trois questions d'incident : d'où partait la machine qui a généré l'alerte, à quel moment exact l'utilisateur s'est connecté, et combien de temps le port est resté ouvert. Sans comptabilité, 802.1X contrôle l'accès mais n'écrit rien ; avec elle, vous disposez d'un registre consultable lors d'un audit. Pensez à dimensionner la conservation des journaux en conséquence : quelques semaines suffisent pour l'exploitation courante, plusieurs mois sont souvent exigés pour un audit annuel.

- Le serveur RADIUS décide sur le port 1812 et trace les sessions sur le port 1813.
- Le VLAN dynamique est envoyé par Tunnel-Private-Group-ID et appliqué par le commutateur.
- FreeRADIUS, Cisco ISE et Microsoft NPS répondent au même rôle, avec des niveaux de confort différents.
- La re-authentification périodique limite le temps d'une session volée.
- Le compte local de secours évite de se verrouiller hors de l'équipement lors d'une panne RADIUS.
- La comptabilité transforme un contrôle d'accès en preuve exploitable.
$lesson$),
  ('net-c7-p4', 'net-c7', 4, $lesson$Choisir les populations et déployer sans coupure$lesson$, $lesson$
Avant d'écrire la moindre ligne de configuration, il faut répondre à une question simple : qui se trouve derrière chaque port ? La réponse se décline en quatre populations, et chaque population appelle un traitement différent. Les postes de bureau gérés par l'entreprise reçoivent un certificat et s'authentifient en EAP-TLS, la méthode la plus sûre. Les portables personnels ou les postes hors domaine passent par PEAP-MSCHAPv2 avec identifiant et mot de passe. Les imprimantes, les bornes d'accès, les téléphones et les objets connectés ne savent généralement pas parler EAP : on les laisse passer en contournement par adresse MAC, ce qui authentifie l'équipement et non l'utilisateur. Enfin les visiteurs atterrissent dans un VLAN de repli, sans accès au réseau interne, avec une durée de vie courte. Dessiner ce tableau avant toute configuration vous évite de découvrir, en production, qu'une imprimante silencieuse a cessé d'imprimer parce que personne ne lui avait expliqué la notion de contournement.

La planification des VLAN vient ensuite, et il doit rester stable : les identifiants envoyés par le serveur sont référencés dans des règles de gestion, et les changer revient à déplacer des populations entières. Sur le site Lilas, le découpage est le suivant : VLAN 10 pour les postes publics, VLAN 20 pour le Wi-Fi, VLAN 30 pour les imprimantes, VLAN 60 pour la gestion des équipements, VLAN 99 pour le repli invité. Le serveur RADIUS lui-même vit en VLAN 60, car il doit être atteignable par tous les commutateurs, y compris par ceux dont les ports sont encore fermés. C'est un point qu'on oublie facilement : un commutateur qui n'arrive pas à joindre le serveur ne peut pas authentifier, et si votre serveur est placé derrière un port qu'il contrôle lui-même, vous venez de créer une dépendance circulaire.

Le déploiement se fait en trois phases, chacune mesurable. La phase de labo utilise un commutateur, un poste de test, une imprimante et un compte invité : vous y validez chaque méthode, le délai d'ouverture du port, le comportement en cas d'arrêt du serveur. La phase pilote couvre un bâtiment ou un étage avec un port de secours physique, c'est-à-dire un port configuré en accès permanent sur un VLAN de gestion, relié à un switch de secours ou à un ordinateur de maintenance. La phase générale étend ensuite la configuration par lots, un commutateur à la fois, en surveillant en continu les journaux du serveur et les compteurs d'échecs. À chaque étape, on mesure : combien de sessions ouvertes, combien de rejets, combien d'échecs de méthode, combien d'équipements tombés en repli. Un pic d'échecs signale un supplicant mal configuré, pas un problème de câblage.

```text
EXEMPLE : suivi du déploiement depuis un commutateur

show dot1x summary
show dot1x interface GigabitEthernet1/0/5 detail
show authentication sessions interface GigabitEthernet1/0/5
show authentication sessions
show vlan brief
show logging | include DOT1X
```

La question la plus importante reste celle du comportement en l'absence du serveur. Deux écoles s'affrontent. L'école permissive ouvre les ports quand le serveur ne répond pas, au nom de la continuité de service : le réseau reste utilisable pendant une panne, mais le contrôle d'accès disparaît au moment précis où il serait le plus utile. L'école stricte ferme les ports ou les bascule dans le VLAN invité, au nom du principe de moindre privilège : une panne du serveur devient un incident visible plutôt qu'une faille silencieuse. En pratique, on choisit en fonction de la criticité : les locaux techniques et les zones publiques peuvent accepter la fermeture, une salle de crise ne le supportera pas. Dans tous les cas, la décision doit être écrite, et non subie le jour de la panne.

- Cartographiez d'abord les populations : certificats, mots de passe, contournement par adresse MAC, repli invité.
- Fixez le plan de VLAN une fois pour toutes et placez le serveur RADIUS hors de tout port contrôlé par lui-même.
- Déployez en trois phases : labo, pilote avec port de secours, généralisation par lots.
- Surveillez les compteurs d'échecs : pic d'erreurs, mauvaise méthode, mauvais serveur, VLAN inconnu.
- Décidez à l'avance du comportement en cas d'indisponibilité du serveur et notez-le dans la documentation.
- Gardez un port de secours physique accessible, car c'est le seul remède à une erreur de règles.
$lesson$),
  ('net-c7-p5', 'net-c7', 5, $lesson$VPN site-à-site : chiffrer le lien entre deux réseaux$lesson$, $lesson$
Un VPN site-à-site relie deux réseaux d'entreprise par un tunnel chiffré traversant un réseau que l'on ne contrôle pas, Internet dans la quasi-totalité des cas. Du point de vue des utilisateurs, le site distant ressemble à un sous-réseau accessible directement : un poste du site Lilas tape une adresse du siège et la connexion aboutit, sans rien demander au poste. Tout le chiffrement se joue dans les équipements, aux deux extrémités du tunnel. Le protocole de référence s'appelle IPsec, et il s'organise en deux phases. La phase 1, assurée par IKE, authentifie les deux équipements et se met d'accord sur les algorithmes et les clés qui protégeront les échanges de négociation. La phase 2 définit ensuite les paramètres du tunnel lui-même, c'est-à-dire la façon dont les paquets utiles seront chiffrés avant de quitter le site et recomposés à l'arrivée.

La version moderne du protocole d'échange de clés est IKEv2, définie par la RFC 7296. Elle réduit le nombre de messages nécessaires à l'établissement, autorise la reconstruction asynchrone du tunnel quand l'un des deux côtés redémarre, supporte la détection de mouvement pour les liens mobiles et permet une authentification extensible. Sur un lien fixe entre deux sites, sa principale qualité est la sobriété : un échange complet tient en quatre messages, contre dix-huit pour son ancêtre. Deux modes d'authentification coexistent. La clé pré-partagée consiste en un secret long et aléatoire partagé par les deux équipements ; elle convient parfaitement quand le nombre de sites reste faible, à condition que le secret fasse au moins trente-deux caractères tirés au sort et qu'il soit conservé avec soin. Les certificats, eux, scales bien au-delà de quelques tunnels et apportent une révocation propre, au prix d'une infrastructure de clés à maintenir.

À la phase 2, chaque paquet utile est protégé par le protocole ESP, qui chiffre le contenu et, dans les modes modernes, en protège aussi l'intégrité. On choisit une suite d'algorithmes qui combine chiffrement et authentification de message ; les constructions récentes privilégient les algorithmes authentifiés de chiffrement à la volée, qui réalisent les deux opérations en un seul passage et vont donc plus vite. La notion de transparence parfaite en avant ajoute un échange de clés supplémentaire pour la phase 2 : la compromission de la clé de phase 1 ne permet alors pas de déchiffrer les sessions passées. Le tableau ci-dessous récapitule ce qu'il faut retenir, ce qu'il faut éviter et pourquoi.

| Choix | Recommandation | Raison |
| --- | --- | --- |
| Chiffrement | AES-GCM-256 en priorité | Chiffrement et intégrité en un seul passage, rapide sur les équipements récents |
| Chiffrement à accepter en second recours | AES-128 ou AES-256 en mode CBC avec HMAC dédié | Compatibilité avec les équipements plus anciens |
| Chiffrement à proscrire | 3DES et DES | Bloc trop court, dépréciés depuis longtemps |
| Intégrité | SHA-384 ou SHA-256 | Fonctions modernes, coût négligeable sur les liens Gbit |
| Intégrité à proscrire | MD5 et SHA-1 | Collisions connues, plus acceptées par aucune norme récente |
| Échange de clés | Groupe Diffie-Hellman 14 ou 19 | Modularité suffisante pour les années à venir |
| Échange à proscrire | Groupes 1, 2 et 5 | Tailles insuffisantes ou historiquement fragiles |
| Durées de vie | 8 heures en phase 1, 2 heures en phase 2 | Compromis entre re-cléage fréquent et stabilité du tunnel |

Le trajet d'un paquet mérite d'être visualisé avant de configurer quoi que ce soit. Un poste du réseau 10.10.0.0/22 envoie un paquet vers le siège. Le routeur de bordure consulte sa table, trouve une route vers 192.168.100.0/24 par l'interface du tunnel. L'équipement consulte la liste d'accès qui définit le trafic à protéger, l'enveloppe dans ESP, y ajoute l'en-tête IP externe vers l'adresse publique du pair, puis transmet le paquet chiffré sur son interface physique. De l'autre côté, l'équipement reconnaît le paquet ESP, le déchiffre, vérifie l'intégrité, retire l'en-tête externe et remet le paquet original sur le réseau local. Si un routeur intermédiaire du chemin est derrière un translation d'adresse, l'enveloppe est encapsulée dans un paquet UDP sur le port 4500, mécanisme connu sous le nom de traversée de NAT.

```text
DEMONSTRATION : trajet d'un paquet a travers le tunnel IPsec

 Site Lilas                                   Site Siege
 +-------------------+                        +-------------------+
 | Poste             |                        | Serveur           |
 | 10.10.0.25        |                        | 192.168.100.50    |
 +---------+---------+                        +---------+---------+
           |                                          |
           v                                          v
 +-------------------+      ESP chiffre le paquet  +-------------------+
 | Commutateur       | ========================> | Commutateur       |
 +---------+---------+   Internet (reseau public) +---------+---------+
           |                                          |
           v                                          v
 +-------------------+                        +-------------------+
 | Pare-feu Lilas    |   IKEv2 negocie les     | Pare-feu Siege    |
 | 203.0.113.10      | <---------------------> | 198.51.100.10     |
 +-------------------+   SA, cles, algorithmes  +-------------------+

 En-tete externe : 203.0.113.10  -->  198.51.100.10   UDP 4500 si NAT
 Charge utile     : 10.10.0.25   -->  192.168.100.50  chiffree par ESP
```

Deux détails de mise en œuvre reviennent systématiquement dans les déploiements réussis. Le premier concerne le MTU : le chiffrement ajoute des octets d'en-tête, et un paquet déjà à pleine taille devient alors non fragmentable, ce qui se traduit par des sessions web qui se bloquent et des transferts qui n'aboutissent jamais. On réduit donc le MTU de l'interface de tunnel et on ajuste la taille maximale de segment TCP pour rester sous la limite. Le second concerne le routage : le trafic destiné au site distant doit trouver une route vers l'interface du tunnel, sinon il part directement sur Internet et disparaît. Une route statique suffit pour un seul lien, une session de routage protégée par le tunnel est préfable dès qu'un second chemin existe.

- Un VPN site-à-site chiffre le transit entre deux réseaux sans rien changer aux postes.
- IKEv2 authentifie les équipements et négocie les paramètres ; ESP protège les paquets utiles.
- La clé pré-partagée convient à peu de sites ; les certificats aux grands déploiements.
- Privilégiez AES-GCM avec SHA-384 et un échange de clés de groupe 14 ou 19.
- Le PFS rend les clés de phase 2 indépendantes de la clé de phase 1.
- Réduisez le MTU et ajustez le TCP pour éviter les blocages de paquets non fragmentables.
$lesson$),
  ('net-c7-p6', 'net-c7', 6, $lesson$IKEv2 pas à pas : du pair au tunnel VTI$lesson$, $lesson$
La configuration d'un tunnel se lit comme une pile de briques, chacune référençant la précédente. On commence par la proposition de phase 1, qui liste les algorithmes que l'équipement accepte de négocier : chiffrement, intégrité et groupe de clés. On l'insère dans une politique, puis on crée un anneau de clés qui associe l'adresse publique du pair à sa clé pré-partagée. On déclare ensuite un profil IKEv2 qui dit à l'équipement à quel moment ce profil s'applique, c'est-à-dire quand un paquet arrive d'une adresse donnée, et avec quel mode d'authentification on se présentera. Rien n'est encore actif à ce stade : ces éléments sont des ingrédients, qui ne prennent vie que lorsqu'une interface de tunnel les référence.

La seconde pile construit le tunnel lui-même. Une suite de transformation décrit comment les paquets seront protégés : protocole ESP, algorithme de chiffrement choisi, mode tunnel. Un profil IPsec associe cette suite au profil IKEv2, ajoute l'échange de clés supplémentaire si l'on souhaite la transparence parfaite en avant, puis fixe les durées de vie du tunnel. Reste l'interface : on peut appliquer la protection directement sur l'interface physique, méthode historique fondée sur une carte cryptographique, ou créer une interface de tunnel virtuelle. La seconde approche est aujourd'hui préférée, car l'interface de tunnel se comporte comme une interface réseau ordinaire : elle porte une adresse, accepte des routes, participe à une session de routage et se prête aux diagnostics classiques.

```text
EXEMPLE : phase 1 IKEv2 entre le pare-feu Lilas et le siège

! Proposition et politique de phase 1
crypto ikev2 proposal IKEV2_PROP
 encryption aes-gcm-256
 integrity sha384
 group 14

crypto ikev2 policy IKEV2_POL
 proposal IKEV2_PROP

! Anneau de clés : un secret par pair
crypto ikev2 keyring KEYRING_SIEGE
 peer SIEGE
  address 198.51.100.10
  pre-shared-key <SECRET_32_CARACTERES>

! Profil : quand s'applique-t-il, et comment s'authentifie-t-on
crypto ikev2 profile IKEV2_PROF_SIEGE
 match identity remote address 198.51.100.10 255.255.255.255
 identity local address 203.0.113.10
 authentication remote pre-share
 authentication local pre-share
 keyring local KEYRING_SIEGE
 dpd 10 30 on-demand
```

La détection de pair mort mérite une ligne à elle seule. Sans elle, un équipement continue de croire que le tunnel est vivant alors que le lien distant est coupé, et il laisse ainsi des sessions suspendues pendant plusieurs minutes. Le mécanisme envoie régulièrement des messages de contrôle ; si aucune réponse n'arrive après un nombre défini de tentatives, l'équipement déclare le tunnel mort et purge les associations de sécurité, ce qui libère le routage alternatif. Le réglage typique envoie une demande toutes les dix secondes dès qu'il y a du trafic, avec une seconde de délai entre les tentatives, et marque le tunnel mort après trois échecs.

```text
EXEMPLE : phase 2, interface de tunnel et routage

! Suite de transformation ESP chiffre et authentifie
crypto ipsec transform-set IPSEC_TSET esp-aes-256-gcm
 mode tunnel

! Profil IPsec : suite, profil IKEv2, cle supplementaire, durees de vie
crypto ipsec profile IPSEC_PROF_SIEGE
 set transform-set IPSEC_TSET
 set ikev2-profile IKEV2_PROF_SIEGE
 set pfs group14
 set security-association lifetime seconds 7200
 set security-association lifetime kilobytes 4608000

! Interface de tunnel virtuelle
interface Tunnel0
 description VPN Lilas vers Siege
 ip address 10.255.255.1 255.255.255.252
 ip mtu 1400
 ip tcp adjust-mss 1360
 tunnel source GigabitEthernet0/0
 tunnel destination 198.51.100.10
 tunnel mode ipsec ipv4
 tunnel protection ipsec profile IPSEC_PROF_SIEGE

! Routage du site distant par le tunnel
ip route 192.168.100.0 255.255.255.0 Tunnel0
```

L'exemption de NAT constitue la dernière pièce, et son absence est la panne la plus fréquente de tous les tunnels IPsec. Sur une interface soumise à la traduction d'adresses, le trafic destiné au pair est traduit avant d'être chiffré, si bien que l'équipement distant reçoit une annonce d'origine inattendue et rejette la négociation. La correction tient en quelques lignes : une liste d'accès qui écarte explicitement le trafic entre les deux réseaux internes de la traduction, puis l'application de cette liste à la règle de traduction. Vérifiez ensuite que la traduction est bien absente pour les adresses du tunnel, sinon vous corrigerez dans le mauvais sens pendant une heure.

Les certificats remplacent la clé pré-partagée quand le nombre de sites croît. On déclare un point de confiance, on y inscrit l'équipement par terminal ou par fichier, on exige la vérification de révocation, puis on demande au profil IKEv2 d'utiliser une signature RSA pour l'authentification locale et distante. L'avantage devient évident dès le deuxième tunnel : ajouter un site revient alors à lui émettre un certificat, sans jamais partager un nouveau secret par un canal parallèle.

- Décrivez d'abord les algorithmes de phase 1, puis l'anneau de clés, puis le profil IKEv2.
- L'interface de tunnel virtuelle se comporte comme une interface normale et se prête au routage.
- Configurez la détection de pair mort pour purger les associations obsolètes en quelques secondes.
- Pensez systématiquement à l'exemption de NAT avant de chercher ailleurs la cause d'un tunnel absent.
- Réduisez le MTU et ajustez le segment TCP pour éviter les blocages de transferts.
- Passez aux certificats dès que le nombre de tunnels dépasse quelques unités.
$lesson$),
  ('net-c7-p7', 'net-c7', 7, $lesson$Vérifier et dépanner le tunnel$lesson$, $lesson$
Un tunnel déclaré à la configuration n'existe pas tant qu'il n'a pas été observé en fonctionnement. La vérification suit un ordre précis, et cet ordre compte : on commence par la phase 1, on poursuit par la phase 2, puis on teste le routage, et seulement ensuite le trafic utile. Si vous inversez les étapes, vous passerez une heure à diagnostiquer un routage parfaitement correct alors que la négociation n'a jamais abouti. Les commandes de consultation diffèrent légèrement d'une plateforme à l'autre, mais la logique est universelle : état de la négociation, associations de sécurité actives, compteurs de chiffrement et de déchiffrement, puis test de bout en bout avec une adresse du réseau distant.

Le premier réflexe consiste à afficher l'association de phase 1. L'état doit être prêt, et l'affichage doit montrer les algorithmes réellement retenus, ce qui vous permet de vérifier que votre proposition n'a pas été écartée au profit d'une valeur par défaut. Le second réflexe affiche les associations de phase 2, où l'on attend des compteurs de paquets chiffrés qui augmentent à chaque test. Un compteur de chiffrement qui monte tandis que le compteur de déchiffrement reste figé signale que le paquet part mais n'arrive pas utile : mauvaise adresse de destination, mauvaise route ou filtrage en travers. L'inverse, déchiffrement sans chiffrement, arrive quand l'autre extrémité envoie vers la mauvaise adresse de tunnel.

```text
EXEMPLE : commande de vérification du tunnel

! Phase 1 : la négociation est-elle établie
show crypto ikev2 sa detail
show crypto ikev2 sa

! Phase 2 : les associations de sécurité vivent-elles
show crypto ipsec sa
show crypto session detail

! Routage et interface
show ip route 192.168.100.0
show ip interface brief | include Tunnel
show interface Tunnel0

! Test de bout en bout, depuis une adresse source explicite
ping 192.168.100.1 source 10.10.0.1
traceroute 192.168.100.1 source 10.10.0.1

! Traduction d'adresses : le trafic du tunnel doit en être exclu
show ip nat translations
```

La panne la plus fréquente, on l'a dit, tient à la traduction d'adresses : le trafic chiffré est traduit, l'autre côté rejette, et le tunnel ne s'établit jamais. La seconde en fréquence est une incohérence de clé pré-partagée, qui se manifeste par un rejet en phase 1 avec un message d'authentification. La troisième est une route manquante : le tunnel est établi, les compteurs bougent, mais le trafic part par l'interface par défaut parce que personne n'a écrit la route vers le réseau distant. Viennent ensuite les MTU mal réglés, qui laissent passer le ping mais bloquent les transferts, et enfin les listes d'accès de bordure qui oublient d'autoriser le trafic IKE et ESP vers l'équipement local.

- Vérifiez toujours dans l'ordre : phase 1, phase 2, routage, trafic utile.
- Des compteurs de chiffrement qui augmentent sans déchiffrement indiquent un problème côté récepteur.
- Traduction d'adresses, clé incohérente, route absente et MTU mal réglé couvrent la majorité des cas.
- Une capture sur l'interface physique tranche entre un problème local et un problème distant.
- Testez avec une adresse source explicite pour éliminer les ambiguïtés de routage.
$lesson$),
  ('net-c7-p8', 'net-c7', 8, $lesson$Durcir le commutateur : services, comptes et gestion$lesson$, $lesson$
Le durcissement part d'un constat banal mais décisif : un équipement réseau neuf est ouvert. Il écoute plusieurs protocoles d'annonce qui révèlent son identité, il propose une interface web, il accepte une connexion de gestion sans chiffrement, il embarque des services historiques qui n'ont jamais servi personne, et il conserve des comptes d'usine dont les mots de passe sont publics. Chacune de ces ouvertures est inutile au fonctionnement du réseau et utile à quiconque veut le connaître ou le reprendre. La règle du durcissement se résume donc en une phrase : désactiver tout ce qui n'est pas nécessaire, puis restreindre et chiffrer ce qui l'est. Chaque service que l'on coupe est une surface de recherche en moins pour l'adversaire, et aucun utilisateur ne remarquera jamais leur absence.

La première famille de commandes retire les protocoles d'annonce et les services d'accompagnement. Les annonces réseau permettent à un voisin de dresser l'inventaire complet des équipements, de leurs adresses et de leurs versions ; elles sont précieuses pendant les travaux et dangereuses une fois le réseau stabilisé. L'interface web, elle, a été la source d'un nombre considérable de failles ; si votre processus d'administration passe par la ligne de commande, elle n'a aucune raison d'être active. Les services historiques de diagnostic, hérités des premiers systèmes UNIX, acceptent des requêtes sans authentification. Enfin la résolution de noms sortante depuis la ligne de commande, si elle n'est pas nécessaire, transforme une simple faute de frappe en tentative de connexion sortante vers un domaine inconnu.

```text
EXEMPLE : durcissement des services, des comptes et de la gestion

! Retirer les annonces et les services inutiles
no cdp run
no lldp run
no ip http server
no ip http secure-server
no service tcp-small-servers
no service udp-small-servers
no ip finger
no service pad
no ip domain-lookup
no ip source-route
no ip gratuitous-arps

! Comptes locaux hachés, jamais de mots de passe en clair
username admin privilege 15 algorithm-type scrypt secret <HACHAGE_SCRYPT>
username auditor privilege 3 algorithm-type scrypt secret <HACHAGE_SCRYPT>

! SSH version 2 seule, algorithmes modernes
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3
ip ssh algorithm encryption aes256-ctr aes192-ctr aes128-ctr
ip ssh algorithm mac hmac-sha2-256 hmac-sha2-512
ip ssh algorithm kex curve25519-sha256 diffie-hellman-group14-sha256

! Lignes de gestion : SSH uniquement, filtre d'acces, delai d'inactivite
line vty 0 15
 transport input ssh
 access-class MGMT_ACL in
 exec-timeout 10 0
 logging synchronous
 login authentication default

ip access-list standard MGMT_ACL
 permit 10.10.0.0 0.0.0.255
 deny   any log
```

La gestion à distance mérite d'être traitée comme un accès physique sensible. On n'autorise que SSH version 2, on retire Telnet même derrière une liste d'accès, on impose un délai d'inactivité court afin qu'une session oubliée ne reste pas ouverte toute la journée, et on filtre les lignes de gestion sur le VLAN de management uniquement. L'idéal va plus loin : un accès de gestion par une adresse de source explicite, une porte d'accès physique au cas où, et l'interdiction faite aux équipements de se connecter entre eux pour la gestion, de sorte qu'un commutateur compromis ne puisse pas en rejoindre un autre. Les algorithmes de chiffrement et de clé échangée sont modernes par défaut sur les versions récentes, mais il est bon de les expliciter, car une plateforme héritée peut encore proposer des valeurs faibles.

L'authentification elle-même se structure en trois couches : une chaîne par défaut pour l'ouverture de session, une chaîne pour la commande d'autorisation, et une chaîne de comptabilité qui trace ce que chaque compte a exécuté. Le principe de moindre privilège appliqué aux comptes est essentiel : l'administrateur quotidien n'a pas besoin d'un niveau de privilège maximal, l'auditeur n'a besoin que de lecture, et le compte de service qui pousse les configurations n'a besoin que des commandes de sauvegarde. Prévoyez toujours un compte local de secours haché, car une panne du serveur d'authentification central ne doit jamais vous laisser sans moyen de reprendre la main.

La sauvegarde de configuration termine cette section, et elle n'est pas facultative. Un équipement durci sans sauvegarde est un équipement qu'on n'ose plus toucher ; un équipement sauvegardé automatiquement se modifie sans anxiété. Le mécanisme d'archive natif conserve les dernières versions, horodatées, à intervalle régulier et après chaque écriture en mémoire. Lorsqu'une modification casse l'accès, la restauration prend alors trente secondes au lieu d'une demi-journée passée à reconstituer la configuration à la main.

- Désactivez les annonces, l'interface web, les services historiques et la résolution de noms inutile.
- Hachez tous les comptes locaux et évitez tout mot de passe en clair dans la configuration.
- N'acceptez que SSH version 2 sur les lignes de gestion, filtrées par une liste d'accès.
- Structurez l'authentification, l'autorisation et la comptabilité, avec un compte local de secours.
- Appliquez le moindre privilège aux comptes : lecture pour l'audit, niveau minimal pour l'exploitation.
- Activez l'archive automatique de configuration avant toute modification à risque.
$lesson$),
  ('net-c7-p9', 'net-c7', 9, $lesson$Protéger les ports d'accès$lesson$, $lesson$
Le port d'accès est l'endroit où le réseau rencontre le monde réel : un câble, une prise murale, un visiteur, un objet connecté, parfois un commutateur posé en catastrophe sous une table. C'est aussi l'endroit où les attaques locales sont les plus simples à mener, car aucune exploitation complexe n'est nécessaire pour exploiter une prise ouverte. La défense repose sur une poignée de mécanismes complémentaires, chacun ciblant un angle différent : l'arbre de couverture, les orages de paquets, le nombre d'adresses acceptées, l'origine des annonces d'adresse et la cohérence des réponses d'adresse. Aucun de ces mécanismes ne remplace 802.1X, mais chacun rattrape une faille que 802.1X ne voit pas.

Commençons par l'arbre de couverture. Les commutateurs échangent des messages de prévention de boucle pour construire une topologie sans cycles ; un port directement relié à un terminal n'a aucun besoin de ces messages, et il ne doit surtout pas en émettre, car un poste qui envoie de faux messages peut réorganiser la topologie à son profit. On active donc l'activation rapide du port, qui saute l'état d'attente, et la garde de ces messages, qui ferme immédiatement le port s'il en reçoit. À mesure que 802.1X s'étend, on remplace progressivement ces protections par une isolation dynamique de port, mécanisme plus fin qui n'autorise qu'une seule adresse visible par port le temps de l'authentification.

```text
EXEMPLE : protections des ports d'accès d'un commutateur

! Arbre de couverture et stabilite de topologie
interface range GigabitEthernet1/0/1 - 48
 description Port acces utilisateur
 switchport mode access
 spanning-tree portfast
 spanning-tree bpduguard enable
 storm-control broadcast level 1.00
 storm-control multicast level 2.00
 storm-control action shutdown

! Nombre limite d'adresses et vieillissement
 switchport port-security maximum 2
 switchport port-security violation shutdown
 switchport port-security aging time 10
 switchport port-security aging type inactivity

! Anti-empoisonnement DHCP et ARP
 ip dhcp snooping limit rate 10
 ip arp inspection limit rate 10

! Isolation dynamique, compatible avec un deploiement 802.1X progressif
 access session port-control auto
```

La limitation de tempête mérite une explication : elle compte les paquets de diffusion et de multidiffusion émis par un port et coupe l'émission lorsqu'un seuil est dépassé. Un poste compromis qui inonde le réseau, un commutateur défectueux en boucle logique ou un simple branchement fautif créent alors une coupure locale au lieu d'un incident généralisé. Le réglage en pourcentage de débit doit être basé sur la connaissance de votre trafic : trop bas, il coupe les annonces légitimes de négociation ; trop haut, il ne protège plus. Le mode de coupure est préférable au mode de plainte, car une alerte sans action laisse l'inondation se poursuivre.

Les mécanismes d'anti-empoisonnement travaillent en binôme. L'inspection des baux DHCP vérifie que les réponses d'attribution proviennent bien d'un serveur autorisé sur un port autorisé, ce qui empêche quiconque de se faire passer pour le serveur et d'attribuer une passerelle de son choix. L'inspection dynamique d'adresse fait de même pour l'adresse : elle mémorise les paires adresse et adresse matérielle apprises de façon légitime, puis rejette toute tentative de changer d'identité sans accord. Leur activation globale est sans effet tant que les ports individuels ne sont pas déclarés comme sujets ou fiables, erreur classique qui laisse croire à une protection alors qu'elle est inactive.

La limitation du nombre d'adresses par port referme la boucle. Un port utilisateur n'a aucune raison d'abriter plus d'un ou deux terminaux ; au-delà, il s'agit d'un commutateur non autorisé, d'un pont fait maison ou d'un partage de connexion. En imposant une limite et une action de coupure, on transforme ce scénario en incident local immédiatement visible. Le vieillissement inactif permet en revanche de libérer la place après un départ, ce qui évite qu'un utilisateur changeant de prise ne soit bloqué le lendemain matin.

- Activez l'activation rapide du port et la garde des messages de prévention de boucle.
- Limitez les orages de diffusion et de multidiffusion avec une action de coupure.
- Limitez le nombre d'adresses par port et faites vieillir les entrées inactives.
- Inspectez les baux DHCP et les adresses après avoir déclaré chaque port comme sujet.
- Remplacez progressivement les protections statiques par l'isolation dynamique à mesure que 802.1X avance.
- Mesurez vos seuils sur du trafic réel avant de les abaisser.
$lesson$),
  ('net-c7-p10', 'net-c7', 10, $lesson$Routeur et pare-feu en bordure : filtrer, absorber, taire$lesson$, $lesson$
La bordure d'un réseau concentre deux fonctions contradictoires : laisser passer ce qui est légitime et refuser tout le reste, sans jamais ralentir le premier ni saturer le second. Le durcissement d'un routeur ou d'un pare-feu suit donc trois axes. On réduit ce que l'équipement accepte, on protège son propre processeur contre les paquets qui le visent, et on supprime les comportements historiques qui aident l'adversaire à explorer le réseau. Ces trois axes se concrétisent en un petit nombre de commandes, dont la plupart sont sans effet secondaire et devraient figurer dans toute configuration de référence.

Le premier axe traite les adresses qui ne devraient jamais arriver. Les réseaux privés, les adresses de bouclage, les adresses de diffusion et les adresses non attribuées n'ont aucune raison d'être reçues sur une interface externe : leur présence signifie soit une erreur de routage, soit une tentative d'usurpation d'origine. La même logique s'applique aux messages de redirection et de réponse d'adresse diffusés par le routeur vers le réseau local : ils informent les hôtes d'un chemin plus direct vers une destination, ce qui, sur un réseau malveillant, se transforme en redirection de trafic. Chaque commande ci-dessous retire une pièce inutile du protocole.

```text
EXEMPLE : durcissement d'une interface externe et filtrage d'origine

! Ne pas aider les hotes a choisir leur propre chemin
interface GigabitEthernet0/0
 description Lien operateur
 no ip redirects
 no ip proxy-arp
 no ip directed-broadcast
 ip verify unicast source reachable-via rx
 ip access-group INGRESS_FILTER in

! Anti-spoofing : rien ne doit arriver depuis les reseaux internes en externe
ip access-list extended INGRESS_FILTER
 deny ip 10.0.0.0 0.255.255.255 any
 deny ip 172.16.0.0 0.15.255.255 any
 deny ip 192.168.0.0 0.0.255.255 any
 deny ip 127.0.0.0 0.255.255.255 any
 deny ip 224.0.0.0 15.255.255.255 any
 deny ip host 0.0.0.0 any
 deny ip host 255.255.255.255 any
 permit ip any any

! Le plan de controle ne doit pas etre noye par le trafic utile
class-map type control-plane match-any CPP_ICMP
 match protocol icmp
class-map type control-plane match-any CPP_SSH
 match protocol ssh
class-map type control-plane match-any CPP_ROUTING
 match protocol ospf
 match protocol bgp

policy-map type control-plane CPP_POLICY
 class CPP_ICMP
  police rate 100 pps
 class CPP_SSH
  police rate 500 pps
 class CPP_ROUTING
  police rate 1000 pps
 class class-default
  police rate 200 pps

control-plane
 service-policy input CPP_POLICY
```

La vérification d'origine unicast, notée uRPF, demande au routeur de vérifier que la table de routage contient bien une route vers l'adresse source du paquet reçu. Un paquet qui prétend venir d'un réseau interne en arrivant par l'interface externe est rejeté immédiatement, sans autre consultation. Le mode strict convient aux interfaces où chaque voisin est connu à l'avance ; le mode lâche convient aux liens où le routage asymétrique pourrait faire tomber des paquets légitimes. Sur une bordure, le mode strict est la bonne réponse tant que votre propre plan de routage est symétrique.

Le plan de contrôle constitue le second axe. Il désigne l'ensemble des tâches exécutées par le processeur de l'équipement : recevoir les protocoles de routage, répondre aux demandes de gestion, traiter les paquets qui ne peuvent pas être délégués à la carte de commutation. Un flood de paquets adressés au processeur fait monter sa charge jusqu'à ce que l'équipement cesse de router correctement, sans qu'aucun service ne paraisse en panne. Le filtrage du plan de contrôle impose des taux à chaque famille de trafic : quelques dizaines de réponses par seconde pour les demandes d'écho, une bande passante réservée pour la gestion, une marge large pour les échanges de routage, et une part plafonnée pour tout le reste.

Le pare-feu complète ces mécanismes par ses propres règles, et sa configuration par défaut mérite la même méfiance que celle d'un commutateur. On part d'une politique de refus explicite, on autorise les flux documentés, on évite les règles trop larges qui acceptent n'importe quelle source vers n'importe quelle destination, et on retire les règles devenues sans objet après une migration. Chaque règle reçoit une justification et une date ; une règle sans propriétaire est une règle qui ne sera jamais supprimée. La journalisation des rejets, enfin, transforme ces règles en capteurs : un flux qui heurte sans cesse la même règle signale souvent une erreur de configuration ou un scan en cours.

- Rejetez en entrée les réseaux privés, le bouclage, la multidiffusion et les adresses non attribuées.
- Désactivez les redirections, les réponses d'adresse diffusées et la diffusion dirigée.
- Activez la vérification d'origine unicast en mode strict sur les interfaces de confiance.
- Protégez le plan de contrôle avec des taux limités par famille de trafic.
- Basez les règles de pare-feu sur une politique de refus explicite et des règles justifiées.
- Journalisez les rejets : ils sont vos meilleurs capteurs de reconnaissance.
$lesson$),
  ('net-c7-p11', 'net-c7', 11, $lesson$Journaliser, synchroniser et superviser$lesson$, $lesson$
Un équipement durci mais muet est un équipement qu'on ne peut pas défendre. Les journaux racontent ce qui s'est passé, l'horloge donne au récit une date fiable, et la supervision transforme ces éléments en alerte. Ces trois pièces forment un ensemble indivisible : des journaux horodatés par une horloge fausse racontent une histoire décalée, impossible à recouper avec celle des autres équipements, et une supervision qui n'interroge rien laisse ces journaux s'accumuler sans jamais être lus. Chacune des trois se configure en quelques lignes, mais l'ordre compte : on aligne d'abord l'horloge, ensuite on horodate, enfin on centralise.

La synchronisation d'horloge commence par le choix des sources. On utilise une ou deux sources situées sur le réseau de gestion, de préférence un serveur local lui-même synchronisé sur des sources externes de confiance, car dépendre directement d'un serveur public expose votre horloge à une indisponibilité que vous ne contrôlez pas. On authentifie ensuite les échanges avec une clé partagée, ce qui empêche quiconque sur le chemin de renvoyer une heure falsifiée et de décaler ainsi toutes vos corrélations d'incident. Enfin on ne fait confiance qu'aux sources authentifiées : une source qui ne répond pas avec la bonne clé doit être ignorée, pas acceptée par défaut.

```text
EXEMPLE : horloge authentifiee, journaux centraux et supervision

! Sources de temps authentifiees
ntp server 10.10.0.10 key 1 prefer
ntp server 10.10.0.11 key 1
ntp authenticate
ntp authentication-key 1 md5 <CLE_NTP>
ntp trusted-key 1
ntp source Vlan60

! Horodatage de tous les messages, avec fuseau lisible
service timestamps log datetime msec localtime show-timezone
service timestamps debug datetime msec localtime show-timezone

! Tampon local abondant puis export vers le serveur de journaux
logging buffered 1000000
logging host 10.10.0.10 transport udp 514
logging source-interface Vlan60
logging facility local7
logging trap notifications
archive
 path flash:config-archive
 maximum 14
 time-period 1440
 write-memory
```

Le choix de la source d'export des journaux n'est pas anodin. Si vous la faites passer par le VLAN d'administration, vous conservez la séparation entre le réseau de production et le réseau de gestion ; si vous la faites sortir par une interface de service, vous devez vous assurer que le pare-feu autorise exactement ce flux et rien d'autre. Le protocole de transfert classique n'offre aucune protection : les journaux circulent en clair et peuvent être modifiés en chemin. Sur un réseau sensible, on les chiffre, on les signe, ou au minimum on restreint l'accès au serveur de collecte à quelques sources. Quoi qu'il en soit, dimensionnez le tampon local pour absorber plusieurs heures d'activité, car c'est ce qui vous reste quand le lien ou le serveur tombe.

La supervision s'appuie sur ces mêmes journaux et y ajoute l'interrogation périodique des compteurs. La version 3 du protocole de gestion à distance est la seule qui doive rester activée : elle authentifie et chiffre les échanges, et permet de n'accorder qu'un droit de lecture à l'outil de surveillance. Les versions antérieures transmettent une communauté, c'est-à-dire un mot de passe non chiffré, et la communauté en écriture équivaut à un accès administrateur complet. On retire donc toute communauté résiduelle, on limite la vue exposée aux seuls objets utiles, et on associe la supervision à une adresse de gestion, jamais à une adresse accessible depuis les postes.

Le tableau de vérification suivant condense les commandes que vous exécuterez après chaque modification. Prenez l'habitude de les enchaîner dans cet ordre : elles confirment en moins d'une minute que l'horloge est alignée, que les journaux partent bien vers la collecte, que l'agent de supervision répond en version 3 et que rien d'interdit ne subsiste dans la configuration.

| Vérification | Commande attendue | Signe d'anomalie |
| --- | --- | --- |
| Synchronisation | Association d'horloge à la strate attendue | Aucune source sélectionnée ou statut rejeté |
| Horodatage | Dates cohérentes entre plusieurs équipements | Décalage constant indiquant une source fausse |
| Export des journaux | Flux reçu par le serveur de collecte | Tampon local qui déborde sans réception |
| Supervision | Agent accessible en version 3 avec droits limités | Réponse en version 1 ou communauté en écriture |
| Configuration propre | Résultat vide pour les services interdits | Une ligne résiduelle signalant un oubli |

- Alignez l'horloge avant d'horodater, et n'acceptez que des sources authentifiées.
- Dimensionnez le tampon local pour survivre à une coupure de la collecte.
- N'exportez jamais les journaux sur un réseau qui ne les protège pas.
- N'autorisez que la version 3 de la supervision, en lecture seule, depuis la gestion.
- Vérifiez la propreté de la configuration avec une commande d'inclusion après chaque changement.
- Écrivez la durée de conservation des journaux et revoyez-la avec le responsable du respect des obligations.
$lesson$),
  ('net-c7-p12', 'net-c7', 12, $lesson$Déployer : le mini-projet du site Lilas$lesson$, $lesson$
Tout ce qui précède n'a de valeur qu'assemblé. Le mini-projet de fin de chapitre reprend les trois mécanismes et les applique au site Lilas comme on le ferait en mission, c'est-à-dire avec des livrables identifiés, un ordre de réalisation justifié et une validation signée. Trois livrables constituent le dossier complet. Le premier décrit le contrôle d'accès du site, du serveur aux ports, en passant par les populations et les replis. Le second décrit le tunnel vers le siège, de la négociation au routage. Le troisième décrit le durcissement des six équipements, avec la même checklist appliquée à chacun mais des exceptions propres à chaque rôle.

L'ordre de réalisation n'est pas arbitraire. On commence par la journalisation et l'horloge, car toute modification ultérieure doit être traçable et datée. On poursuit par le durcissement de la gestion, qui réduit le risque pendant les travaux eux-mêmes. Le tunnel arrive ensuite, car il faut pouvoir rejoindre le site distant pour vérifier son propre déploiement. Le contrôle d'accès vient en dernier, une fois les autres protections en place, précisément parce qu'il a le plus fort impact sur les utilisateurs et qu'il doit pouvoir être réversible rapidement. Cette séquence garantit que chaque étape est observée par un dispositif déjà en place, et non par rien.

```text
MODÈLE : checklist de validation post-déploiement

CONTROLE D'ACCES AU PORT
[ ] Poste certifie : EAP-TLS accepte, VLAN 10 applique, passerelle atteignable
[ ] Poste hors domaine : PEAP accepte, VLAN 10 applique
[ ] Imprimante : contournement par adresse MAC, VLAN 30 applique
[ ] Poste non autorise : rejet, bascule en VLAN 99, DHCP seul, aucun reseau interne
[ ] Comptabilite : depart et arrivee de session visibles sur le serveur
[ ] Reconduction horaire observee sur un port de test
[ ] Extinction du serveur : comportement conforme a la decision documentee

VPN SITE A SITE
[ ] Association de phase 1 etablie avec les algorithmes attendus
[ ] Associations de phase 2 actives, compteurs qui augmentent
[ ] Route vers 192.168.100.0/24 par l'interface de tunnel
[ ] Ping de bout en bout depuis et vers chaque site
[ ] Aucune traduction d'adresses pour le trafic du tunnel
[ ] Extinction du lien distant : purge du tunnel en moins de 30 secondes

DURCISSEMENT, PAR EQUIPEMENT
[ ] Services d'annonce et services inutiles desactives
[ ] SSH version 2 seule, listes d'acces sur les lignes de gestion
[ ] Comptes locaux haches, moindre privilege applique
[ ] Journaux horodates exportes, horloge authentifiee
[ ] Supervision en version 3, lecture seule
[ ] Ports d'accès : arbre, tempete, baux et adresses controles
[ ] Bordure : redirections et diffusion dirigee desactives, origine verifiee
[ ] Archive de configuration activee et derniere sauvegarde recuperee
[ ] Commande d'inclusion ne retourne aucune ligne interdite

EXCEPTIONS DOCUMENTÉES
Equipement | Exception | Justification | Revu le | Par
Switch-A   | Annonce reseau active sur le lien VoIP | Passerelle telephonique qui l'exige | 2026-10-01 | Admin
Switch-C   | Contournement sur deux ports laboratoire | Appareils de mesure sans supplicant | 2026-10-01 | Admin
```

Chaque ligne de cette checklist correspond à une observation, jamais à une affirmation. On ne coche pas un contrôle parce qu'il est écrit dans la configuration, on le coche parce qu'on l'a vu se produire. Cette distinction paraît subtile et elle est tout le sujet de la validation : une configuration peut être parfaite sur le papier et ne pas fonctionner, parce qu'un réseau de management inaccessible rend le serveur injoignable, parce qu'un VLAN manquant dans la base du serveur rejette tout le monde, ou parce qu'un simple oubli de route empêche le tunnel de porter le trafic utile. Le contrôle signé engage son auteur : il dit que l'effet a été observé, pas seulement écrit.

La gestion des exceptions mérite la même rigueur. Aucun réseau réel ne respecte la checklist sans écart : une passerelle téléphonique exige une annonce réseau, un appareil de mesure ne sait pas s'authentifier, un fournisseur impose un accès distant. L'art du durcissement consiste à transformer chaque écart en décision explicite, avec une justification, un responsable et une date de réexamen. Un écart documenté est une exception ; le même écart découvert en audit sans explication est une non-conformité. Tenez ce tableau à jour et faites-le relire, car c'est lui qui convainc un auditeur que le dispositif est piloté et non subi.

Un dernier point concerne l'exploitation quotidienne, celle qui commence le lendemain de la recette. Le déploiement se termine, la sécurité elle non. Les journaux doivent être lus, les alertes analysées, les certificats renouvelés avant leur expiration, les comptes revus, les exceptions réexaminées, les sauvegardes testées en restauration. Un dispositif qui n'est pas réévalué perd de sa valeur à mesure que l'environnement change autour de lui. Planifiez ces revues, associez-y des dates, et mesurez le temps réellement consacré : dans la pratique, une heure par mois suffit à maintenir un site de cette taille en état, tant que rien n'est laissé s'accumuler.

- Réalisez dans l'ordre : horloge et journaux, gestion, tunnel, contrôle d'accès.
- Livrez trois dossiers : contrôle d'accès, tunnel, durcissement des six équipements.
- Ne cochez une ligne de validation que si l'effet a été observé, pas seulement configuré.
- Documentez chaque exception avec justification, responsable et date de réexamen.
- Testez réellement la restauration d'une sauvegarde, sinon vous ne la possédez pas.
- Planifiez les revues périodiques : lecture des journaux, comptes, certificats, exceptions.
$lesson$),
  ('net-c7-p13', 'net-c7', 13, $lesson$Tester, mesurer et dépanner$lesson$, $lesson$
La sécurité se mesure comme tout le reste du parcours l'a déjà fait pour la performance : avec des tests reproductibles, des compteurs et une méthode. Le test de référence du contrôle d'accès tient en trois gestes. Vous branchez un poste en règle et vous vérifiez qu'il obtient son adresse dans le bon VLAN. Vous branchez un poste sans identité et vous vérifiez qu'il est confiné. Vous éteignez le serveur d'authentification et vous vérifiez que le comportement correspond à la décision prise à l'avance. Chacun de ces tests prend moins d'une minute, et ensemble ils valident la chaîne complète, du supplicant jusqu'au repli, en passant par l'attribution d'adresses qui échoue souvent quand le VLAN de repli n'a pas de serveur.

Le test de référence du tunnel se décline de la même façon. Vous établissez le tunnel, vous observez les compteurs de chiffrement et de déchiffrement, vous traffic du réseau local vers le réseau distant, puis vous coupez le lien partenaire pour vérifier que la détection de mort purge les associations. Le retour à la normale doit être automatique, sans intervention. Enfin vous capturez quelques paquets sur le lien externe et vous confirmez que seuls des paquets chiffrés y circulent : cette capture est la seule preuve recevable que le chiffrement est réellement actif et pas seulement déclaré.

```text
EXEMPLE : protocole de test apres chaque modification

! Controle d'accès
show authentication sessions
show dot1x interface GigabitEthernet1/0/5 detail
test aaa server radius RADIUS_ISE

! Tunnel
show crypto ikev2 sa
show crypto ipsec sa
ping 192.168.100.1 source 10.10.0.1 repeat 100

! Hygiène generale
show running-config | include http|telnet|snmp-server community|finger
show ntp association detail
show snmp user
show archive
```

Le tableau suivant condense les symptômes les plus fréquents et la cause qui leur correspond le plus souvent. Servez-vous-en comme d'une table de tri : commencez toujours par la vérification la moins coûteuse et la plus discriminante, puis remontez. Dans la grande majorité des cas, le problème n'est pas dans le mécanisme lui-même mais dans une pièce périphérique oubliée : une route, un VLAN absent de la base du serveur, une clé qui a changé d'un seul côté, une liste d'accès qui bloque le port d'authentification.

| Symptôme | Cause probable | Première vérification |
| --- | --- | --- |
| Port qui reste fermé pour tout le monde | Serveur injoignable depuis le commutateur | Test de port UDP 1812 et journal du serveur |
| Tous les postes atterrissent en invité | Vlan inconnu du serveur ou attribut absent | Journal d'acceptation et attributs renvoyés |
| Imprimante hors service après déploiement | Contournement non activé sur le port | État de session du port et adresse de l'imprimante |
| Tunnel qui n'établit pas en phase 1 | Clé incohérente ou adresse du pair erronée | Message de rejet et comparaison des deux configurations |
| Tunnel établi mais trafic absent | Route manquante ou filtrage d'entrée | Table de routage et liste d'accès de bordure |
| Transferts web qui bloquent | Taille de segment trop grande | Test de taille de paquet à travers le tunnel |
| Gestion impossible après durcissement | Ligne de gestion filtrée trop étroitement | Liste d'accès appliquée aux lignes de gestion |
| Dates incohérentes dans les journaux | Source d'horloge non authentifiée | Association d'horloge et clé utilisée |

Les outils du dépanneur restent d'ailleurs les mêmes que ceux des chapitres précédents, auxquels s'ajoutent les journaux du serveur d'authentification. La capture de paquets confirme ce qui circule réellement. Le suivi de session montre l'état d'authentification port par port. La commande d'inclusion sur la configuration révèle les services qu'on croyait éteints. Et la comparaison côte à côte de deux configurations, celle qui fonctionne et celle qui ne fonctionne pas, reste la méthode la plus rapide qui soit : la différence se lit presque toujours en quelques lignes, une clé, un VLAN, une route, une temporisation.

- Testez chaque contrôle par l'observation d'un effet, jamais par la lecture de la configuration.
- Capturez le lien externe : c'est la preuve que le chiffrement est réellement actif.
- Employez la table de tri à partir de la vérification la plus discriminante.
- Une modification à la fois, avec un test et une sauvegarde entre chacune.
- Cherchez d'abord les pièces périphériques : route, VLAN, clé, liste d'accès, port UDP.
$lesson$),
  ('net-c7-p14', 'net-c7', 14, $lesson$À retenir$lesson$, $lesson$
Ce chapitre a posé les trois verrous de la sécurité réseau opérationnelle : prouver une identité avant d'ouvrir un port, chiffrer les liens entre sites, et retirer aux équipements tout ce qui n'est pas nécessaire à leur fonctionnement. Chaque mécanisme se vérifie par un effet observé, jamais par une configuration seulement écrite, et chacun laisse une trace exploitable quand la journalisation et l'horloge ont été mises en place avant lui.

- 802.1X oppose un supplicant, un authenticateur et un serveur RADIUS ; le port reste fermé sans identité acceptée.
- EAP-TLS utilise des certificats des deux côtés, PEAP-MSCHAPv2 protège un mot de passe, le contournement par adresse MAC couvre les objets.
- Le VLAN dynamique arrive dans les attributs de tunnel du serveur, le repli invité prend le relais en cas d'échec.
- La comptabilité transforme chaque session en preuve datée : identité, port, VLAN, durée.
- Le déploiement se fait en trois phases, avec un port de secours physique et une décision écrite pour la panne du serveur.
- IKEv2 authentifie en quatre messages, ESP chiffre les paquets utiles, la transparence parfaite en avant protège les clés de phase 2.
- AES-GCM, SHA-384 et un échange de clés de groupe 14 ou 19 constituent la référence ; 3DES, MD5 et les groupes courts sont proscrits.
- L'exemption de NAT, la réduction de taille de paquet et la route vers le réseau distant règlent la majorité des tunnels qui ne montent pas.
- Le durcissement retire les annonces et les services inutiles, impose SSH version 2, hache les comptes et archive la configuration.
- Les ports d'accès gagnent une activation rapide, une garde de messages, une limite de tempête, un plafond d'adresses et l'inspection des baux.
- La bordure rejette les origines incohérentes, coupe les redirections et protège son plan de contrôle par des taux limités.
- L'horloge authentifiée, les journaux centralisés et la supervision en lecture seule forment un ensemble indivisible.
$lesson$),
  ('net-c7-p15', 'net-c7', 15, $lesson$Erreurs fréquentes$lesson$, $lesson$
La première erreur est de déployer le contrôle d'accès avant d'avoir testé le chemin du serveur : le port se ferme pour tout le monde et personne ne sait pourquoi. La deuxième est d'oublier la traduction d'adresses sur le trafic du tunnel, alors que tout le reste est juste. Viennent ensuite les exceptions tacites, les comptes conservés en clair, les communautés de supervision résiduelles et les sauvegardes jamais restaurées.

- Ouvrir le contrôle d'accès à tous les ports d'un coup, sans port de secours ni première phase de test.
- Oublier d'exclure le trafic du tunnel de la traduction d'adresses, ce qui empêche la négociation de se terminer.
- Laisser une interface web, Telnet ou une communauté de gestion résiduelle après le durcissement.
- Placer le serveur d'authentification derrière un port que le commutateur doit lui-même authentifier.
- Activer l'inspection des baux sans déclarer les ports concernés, et croire à une protection inactive.
- Cocher une ligne de validation sur la foi d'une configuration plutôt que d'un effet observé.
- Conserver des exceptions sans responsable ni date de réexamen, jusqu'à ce qu'un audit les découvre.
- Déployer sans sauvegarde, puis hésiter à corriger par peur de ne pas pouvoir revenir en arrière.
$lesson$),
  ('net-c7-p16', 'net-c7', 16, $lesson$Pour aller plus loin$lesson$, $lesson$
Les trois références officielles ci-dessous suffisent pour approfondir sans vous perdre dans la documentation constructeur. La norme IEEE 802.1X décrit le mécanisme d'authentification au port dans sa version complète, y compris les échanges EAPOL que vous avez vus en schéma : https://www.ieee802.org/1/pages/802.1X.html. La RFC 7296 définit IKEv2, la négociation, la reprise automatique et les extensions d'authentification : https://datatracker.ietf.org/doc/html/rfc7296. La RFC 4301 expose l'architecture de sécurité IPsec, les associations de sécurité et les modes de transport et tunnel : https://datatracker.ietf.org/doc/html/rfc4301.

Pour le filtrage de bordure, la recommandation opérationnelle la plus citée reste la RFC 2827, qui décrit le contrôle des adresses source en entrée : https://datatracker.ietf.org/doc/html/rfc2827. Complétez ensuite par le guide de configuration de votre propre plateforme, mais seulement après avoir compris les mécanismes ici : la documentation d'équipement dit comment écrire une commande, elle dit rarement dans quel ordre la valider ni quel test la confirme.
$lesson$),
  ('net-c7-p17', 'net-c7', 17, $lesson$Et maintenant : passez à l'exercice pratique du site Lilas$lesson$, $lesson$
Vous avez parcouru le dernier chapitre du parcours Réseaux : contrôle d'accès, chiffrement site à site et durcissement des équipements referment la boucle commencée par le modèle OSI. Passez à l'exercice pratique du site Lilas — il mobilise l'ensemble du parcours, des sous-réseaux jusqu'aux règles de filtrage. Avant de valider le niveau, relisez la section erreurs fréquentes : la plupart des incidents réseau viennent d'une règle oubliée ou d'un service non durci, jamais d'un protocole incompris.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('py-c1-p1', 'py-c1', 1, $lesson$Comprendre : ce qu'est vraiment un programme Python$lesson$, $lesson$
Bienvenue dans ce premier chapitre du parcours Python : du premier script au projet complet. Si vous n'avez jamais écrit une seule ligne de code, vous êtes exactement au bon endroit : rien de ce qui suit ne suppose de connaissances techniques préalables, ni un bagage particulier en mathématiques, ni un logiciel exotique à installer. Python est aujourd'hui l'un des langages les plus utilisés au monde, non seulement pour développer des applications web ou des jeux, mais aussi pour automatiser des tâches répétitives, analyser des données, prototyper une idée en quelques minutes ou piloter des machines. Sa réputation de langage simple à apprendre n'est pas un hasard : sa syntaxe a été pensée pour ressembler à une phrase en français, ce qui vous permet de vous concentrer sur la logique du programme plutôt que sur des symboles obscurs. Ce chapitre est votre porte d'entrée dans cette discipline : il vous apprendra à écrire un programme, à le lancer sur votre machine, à y stocker des informations et surtout à comprendre ce que votre code manipule réellement. Tous les exemples sont courts et exécutables tels quels, afin que vous puissiez les recopier, les modifier et les observer vivre sur votre écran.

À la fin de cette leçon, vous saurez faire quatre choses concrètes, et vous les aurez déjà manipulées dans du vrai code. Premièrement, vous écrirez un fichier Python et vous l'exécuterez pour afficher du texte à l'écran avec la fonction print(). Deuxièmement, vous créerez des variables, c'est-à-dire des noms qui retiennent une valeur, et vous identifierez leur type avec la fonction type(). Troisièmement, vous lirez une saisie au clavier avec input() et vous comprendrez pourquoi elle arrive toujours sous forme de texte, même lorsque l'utilisateur tape un nombre. Quatrièmement, vous convertirez cette saisie en nombre avec int() ou float() afin de pouvoir effectuer des calculs, puis vous afficherez le résultat dans une phrase complète. Ces quatre compétences forment le socle de tout le reste du parcours : les conditions et les boucles du chapitre suivant, les fonctions, les listes, la lecture de fichiers, la gestion des erreurs, les modules et enfin votre premier mini-projet complet, l'analyseur de notes. Chaque objectif est illustré par du code complet, puis repris dans un exemple pas à pas, de sorte que vous ne resterez jamais dans l'abstrait. À la fin du chapitre, un quiz de quatre questions vous permettra de vérifier que les notions essentielles sont bien installées, et l'exercice pratique vous fera réécrire seul le programme vedette de la leçon.

Un dernier conseil avant de commencer, sur la manière d'aborder ce cours. Python s'apprend comme on apprend un sport : en faisant, pas en regardant. Rien ne remplace le geste de taper soi-même chaque ligne de code dans votre éditeur, de lancer l'exécution, de voir le résultat apparaître et, parfois, de provoquer une erreur. Une erreur n'est pas un échec : c'est le langage qui vous explique précisément où vous vous êtes trompé, et plus vous la lirez attentivement, plus vous progresserez vite. Nous avancerons par petits pas, en alternant explications détaillées, exemples de code commentés et bonnes pratiques issues de l'expérience professionnelle. Le fil rouge du chapitre sera un programme simple mais utile : il demandera votre âge à l'utilisateur, calculera votre âge dans dix ans, affichera une phrase complète et détectera les saisies invalides. Vous le construirez pas à pas dans la section Exemple guidé, puis vous le récrirez seul dans l'exercice pratique qui suit immédiatement cette leçon.



Un programme Python est, tout simplement, un fichier texte contenant une liste d'instructions que la machine doit exécuter dans l'ordre. Ce fichier porte d'ordinaire l'extension .py, par exemple bonjour.py, et vous le créez avec n'importe quel éditeur de texte ou éditeur de code. Ce qui distingue Python de nombreux autres langages, c'est la façon dont ces instructions sont traitées : Python est un langage interprété. Concrètement, vous n'avez pas de phase de compilation à lancer avant de voir votre code fonctionner ; vous écrivez des instructions dans le fichier .py, puis l'interpréteur, c'est-à-dire le programme chargé de comprendre et d'exécuter le langage, les lit et les exécute une par une, de la première à la dernière. C'est un avantage décisif pour débuter : vous modifiez une ligne, vous relancez l'exécution, vous voyez aussitôt le résultat ou le message d'erreur. Votre code reste lisible directement par un humain, ce qui le rend particulièrement pédagogique, et cette lisibilité explique aussi pourquoi Python est si répandu pour l'automatisation et l'enseignement de la programmation.

Pour exécuter votre premier script, trois étapes suffisent. Premièrement, écrivez le code de l'exemple suivant dans un fichier nommé bonjour.py, en utilisant votre éditeur de code : VS Code, PyCharm, Thonny ou l'éditeur IDLE livré avec Python conviennent tous. Deuxièmement, ouvrez un terminal : l'invite de commandes sous Windows, le terminal sous macOS ou sous Linux. Troisièmement, placez-vous dans le dossier qui contient votre fichier, par exemple avec la commande cd, puis lancez l'exécution. Sous Windows, la commande ressemble à python bonjour.py ; sous macOS ou Linux, elle est souvent python3 bonjour.py, l'installation pouvant réserver la commande python à une autre version. L'interpréteur lit alors votre fichier ligne à ligne et affiche le résultat directement dans le terminal. Si rien n'apparaît, votre programme ne contient probablement aucune instruction d'affichage : c'est une situation fréquente au départ, et la section suivante va vous apprendre à la résoudre. Pour vérifier que Python est installé et connaître sa version, tapez python --version.

```python
print("Bonjour, monde !")
print("Bienvenue dans mon premier programme.")
```

La fonction print() est souvent la première que l'on apprend, et elle reste utile tout au long de votre vie de développeur, y compris lorsque vous serez expérimenté. Son rôle est simple : afficher une valeur à l'écran, dans l'endroit où le programme s'exécute. On l'utilise d'abord pour voir ce que fait un programme, puis tout au long du débogage : quand un résultat n'est pas celui qu'on attend, la première réflexion consiste à afficher les valeurs intermédiaires afin de repérer exactement où le calcul déraille. Notez que print() affiche ce qu'on lui donne, sans préjugé sur la nature de cette valeur : du texte, un nombre, le résultat d'un calcul ou le type d'une variable. C'est un outil d'observation autant qu'un outil d'affichage final. Un programme qui n'affiche rien semble souvent ne rien faire aux débutants, alors qu'il exécute peut-être parfaitement son travail en interne : apprenez dès maintenant à rendre cette exécution visible, c'est le réflexe le plus rentable du débutant.

L'interpréteur parcourt votre fichier de haut en bas, une instruction après l'autre, dans l'ordre exact où vous les avez écrites. Cet ordre est significatif : si vous demandez d'afficher une variable avant de lui donner une valeur, le programme s'arrête et signale une erreur, car l'instruction ne peut pas être comprise à ce moment-là. Chaque instruction occupe en principe sa propre ligne, et Python se passe des points-virgules de fin de ligne, contrairement à d'autres langages : une fin de ligne suffit à marquer la fin d'une instruction. En revanche, Python est strictement sensible à la casse. La fonction s'écrit print, en minuscules : appeler Print ou PRINT déclenche une erreur du type `name 'Print' is not defined`. Il en va de même pour les valeurs True et False et pour tous les noms que vous créerez. Cette rigueur peut surprendre les premiers jours, mais elle devient vite un réflexe, à condition de lire attentivement les messages d'erreur plutôt que de les subir.

Une variable est un nom qui pointe vers une valeur. Pour en créer une, on écrit un nom, un signe égal, puis la valeur à mémoriser ; le signe égal est un opérateur d'affectation et non une égalité mathématique : age = 15 se lit « donne au nom age la valeur 15 » et non « age est égal à 15 ». Une fois l'affectation effectuée, chaque fois que vous utilisez le nom age ensuite, Python le remplace par la valeur qu'il désigne : vous n'avez plus jamais à réécrire le nombre lui-même. Vous pouvez réaffecter autant de fois que nécessaire : age = 15 puis age = 16 fait passer le nom à la nouvelle valeur, l'ancienne étant simplement abandonnée. L'analogie la plus parlante est celle d'une étiquette collée sur une boîte : le nom est l'étiquette, la valeur est le contenu de la boîte, et vous pouvez déplacer l'étiquette sur une autre boîte. Python ne vous demande jamais de déclarer à l'avance l'existence d'une variable : elle naît au moment où vous lui donnez pour la première fois une valeur.

Python ne déclare pas le type d'une variable : il le déduit automatiquement à partir de la valeur que vous affectez. Vous écrivez age = 15, Python reconnaît un nombre entier ; vous écrivez prenom = "Alice", il reconnaît un texte. Pour connaître le type d'une valeur ou d'une variable, on utilise la fonction type(), qui renvoie le type sous forme d'un objet que print() sait afficher. Ainsi, print(type(3.14)) vous montre un message où l'on lit float, print(type(7)) contient int, print(type("bonjour")) contient str et print(type(True)) contient bool. Cette déduction automatique est confortable au départ, mais elle a une contrepartie : c'est à vous de savoir ce que contient réellement chaque variable, car les opérations disponibles dépendent du type. Deux nombres entiers s'additionnent, deux textes se collent l'un à l'autre, mais un nombre et un texte ne se combinent pas sans conversion explicite. Le type n'est donc pas un détail cosmétique : c'est la clé pour anticiper le comportement de vos instructions.

Parmi les types de base, le type str stocke du texte : on l'appelle chaîne de caractères, ou string en anglais. Une chaîne s'écrit entre guillemets simples ou doubles, et les deux écritures sont équivalentes à condition de rester cohérent ; les guillemets doubles sont pratiques quand le texte contient une apostrophe. On peut additionner deux chaînes avec le signe plus, ce qui les colle l'une à l'autre, et mesurer leur longueur avec la fonction len(). Le type int stocke les nombres entiers, sans virgule : c'est le type des compteurs, des âges, des quantités. Les opérations usuelles fonctionnent naturellement : addition, soustraction et multiplication produisent un entier quand les deux termes sont des entiers. En revanche, la division est un cas particulier en Python 3 : le signe slash renvoie toujours un décimal, même quand le résultat tient dans un entier. Par exemple, 7 divisé par 2 donne 3.5, et non 3. Si vous voulez la partie entière du quotient, il existe un opérateur dédié que nous verrons dans la section sur les types.

Le type float stocke les nombres décimaux. Sa particularité dans votre langue : le séparateur décimal est le point et jamais la virgule, sous peine de provoquer une erreur de syntaxe. On écrit donc 3.14 et non 3,14. Attention aussi à une subtilité fréquente : 7.0 est un float au même titre que 3.14, car c'est la présence du point qui fait le type, pas le nombre de décimales affichées. Le type bool stocke les valeurs de vérité True et False, toujours avec une majuscule, comme des noms propres. Dans la vie courante, un booléen correspond à une réponse oui ou non : un nombre est-il positif, deux chaînes sont-elles identiques, l'utilisateur a-t-il saisi la bonne clé. Les booléens apparaissent surtout lorsque vous écrirez vos premières conditions et vos premières boucles au chapitre suivant, mais il est utile de savoir dès maintenant que Python distingue les nombres, les textes et les affirmations vraies ou fausses, car chaque catégorie se comporte différemment dans les calculs et les comparaisons.

Il reste une pièce maîtresse à découvrir avant de pouvoir écrire un programme qui interagit avec l'utilisateur : la saisie clavier. La fonction input() est le pendant exact de print() : là où print() envoie une valeur vers l'écran, input() récupère une valeur depuis le clavier et la remet dans votre programme, sous forme de valeur que vous pourrez affecter à une variable. Le détail capital, que nous détaillerons dans sa section propre, tient en une phrase : tout ce qui arrive au clavier arrive sous forme de texte. Même si l'utilisateur tape 15, votre programme reçoit la chaîne "15" et non le nombre 15. Toute la difficulté des premiers programmes interactifs vient de là, et la solution est toujours la même : convertir explicitement la saisie en nombre avant de calculer. Vous allez apprendre à le faire sans vous tromper, à anticiper les conversions qui échouent, puis à assembler l'ensemble dans un programme complet et robuste.

Une distinction pratique vous sera utile dès la première heure : l'interpréteur peut s'utiliser de deux manières. Dans un fichier .py, vous écrivez l'intégralité de votre programme, vous l'enregistrez, puis vous le lancez depuis un terminal ; l'interpréteur lit le fichier du premier au dernier caractère et s'arrête de lui-même quand il l'a épuisé. En mode interactif, vous lancez simplement la commande python sans lui donner de nom de fichier : une invite composée de trois chevrons apparaît, et chaque ligne que vous tapez est exécutée aussitôt, avant de vous rendre la main. Cette seconde forme est idéale pour tester une idée en deux secondes : on vérifie qu'une conversion fonctionne, on repère le type d'une valeur, on referme la fenêtre, puis on revient à son fichier. L'inverse existe aussi : de nombreux éditeurs exécutent le fichier courant avec un simple raccourci clavier, ce qui donne le confort du terminal sans quitter la fenêtre d'édition. Quelle que soit la méthode, le résultat est le même : le même interpréteur, les mêmes règles, les mêmes messages d'erreur. À vous de choisir celle qui vous rend le plus à l'aise, l'essentiel étant de ne jamais perdre de temps à configurer au détriment de la pratique.

- Un programme est une suite d'instructions exécutées de la première à la dernière.
- Python exécute un fichier .py ligne à ligne grâce à son interpréteur.
- L'ordre des instructions compte : on ne peut pas utiliser une valeur avant de l'affecter.
- Le nom d'une fonction est sensible à la casse : print oui, Print non.
- Une instruction se termine à la fin de la ligne ; le point-virgule est inutile.
- Une erreur de syntaxe arrête immédiatement l'exécution du fichier.

- str : le texte, entre guillemets, par exemple "Alice" ou "Bonjour !".
- int : les nombres entiers sans virgule, par exemple 15 ou -3.
- float : les nombres décimaux, toujours avec un point, par exemple 3.14.
- bool : les valeurs True et False, toujours avec une majuscule.
$lesson$),
  ('py-c1-p2', 'py-c1', 2, $lesson$Afficher du texte avec print$lesson$, $lesson$
Afficher quelque chose à l'écran est si courant en programmation que la fonction dédiée fait partie des rares mots que vous retiendrez par cœur dès la première semaine. print() est ce qu'on appelle une fonction : c'est une action toute prête que vous déclenchez en écrivant son nom suivi de parenthèses. Ce que vous placez à l'intérieur des parenthèses s'appelle un argument : c'est la valeur que la fonction doit traiter, ici la chose à afficher. On dit qu'on appelle la fonction, comme on appellerait un service. Une ligne comme print("Bonjour") contient donc trois éléments à retenir : le nom de la fonction, les parenthèses qui délimitent l'appel, et l'argument situé entre ces parenthèses. Python exécute cette ligne, affiche le contenu à l'écran, puis poursuit avec la ligne suivante. Aucune configuration n'est nécessaire, aucun import n'est requis : la fonction est dite intégrée, elle est disponible partout dès la première ligne de votre script.

Pour afficher du texte, il faut l'écrire entre guillemets : c'est ce qu'on appelle une chaîne de caractères, et les guillemets sont le signal qui indique à Python de ne pas chercher à exécuter ce qui est écrit, mais simplement à le recopier tel quel. Les guillemets simples et les guillemets doubles sont strictement équivalents ; l'usage le plus pratique du double est de contenir une apostrophe à l'intérieur, par exemple "C'est l'heure !" ; l'inverse fonctionne aussi, avec un texte écrit entre apostrophes qui contient des guillemets. Vos accents fonctionnent sans réglage particulier, car Python 3 lit les fichiers en UTF-8 par défaut : vous pouvez écrire ë, à, ç ou é sans la moindre crainte. Enfin, attention à une confusion classique : les guillemets ne sont pas décoratifs. print(Bonjour) sans guillemets provoque une erreur, car Python cherche alors une variable nommée Bonjour, qui n'existe pas, au lieu d'un simple texte à afficher.

print() ne se limite pas au texte : elle accepte un nombre, une variable ou le résultat d'un calcul. La nuance importante est que la fonction affiche la valeur qu'on lui transmet, après éventuel calcul. Ainsi print(2 + 3) affiche 5, tandis que print("2 + 3") affiche exactement le texte 2 + 3, sans calcul, parce que les guillemets annoncent du texte à recopier. Cette distinction résume à elle seule la différence entre une donnée et sa représentation affichée, une notion qui vous suivra tout au long du parcours. print() accepte également plusieurs arguments séparés par des virgules : Python les affiche alors les uns après les autres, en insérant un espace entre chacun. C'est la forme la plus confortable pour produire une phrase mêlant du texte et des valeurs, comme dans l'exemple ci-dessous, où le résultat du calcul s'insère naturellement au milieu d'une phrase lisible.

```python
print("Bonjour, Alice !")
print("2 + 3 =", 2 + 3)
print("Votre âge dans 10 ans :", 15 + 10)
```

Il existe une dernière forme d'appel utile dès maintenant : print() sans argument, qui n'affiche rien d'autre qu'une ligne vide. Elle sert à espacer visuellement la sortie, par exemple pour séparer deux étapes d'un calcul affiché pas à pas. Du côté des réglages, print() propose deux paramètres discrets mais pratiques : sep définit le texte inséré entre les arguments, et end ce qui est affiché à la toute fin, une fin de ligne par défaut. En écrivant print("A", "B", sep=" - "), vous obtenez A - B, et en remplaçant end par une chaîne vide, la sortie suivante continuera sur la même ligne. Ces options ne sont pas indispensables pour débuter, mais elles montrent une qualité essentielle de print() : c'est un outil paramétrable que vous adapterez selon le contexte. N'oubliez pas enfin son rôle de débogage : afficher une valeur au milieu d'un programme reste la méthode la plus rapide pour comprendre un résultat inattendu.

Un point subtil mérite votre attention quand vous affichez des variables : print() montre la valeur, jamais son type. Le nombre 7 et le texte "7" se ressemblent parfaitement à l'écran, et pourtant ils n'obéissent pas aux mêmes règles. Si votre programme affiche 7, vous ne pouvez pas deviner s'il s'agit d'un entier, d'un décimal ou d'un texte, et cette ambiguité est la source de la majorité des surprises rencontrées au début. C'est précisément pour cette raison que la fonction type() existe : devant un affichage suspect, vous interrogez d'abord le type, puis vous corrigez la chaîne de traitement en amont, souvent au niveau de la saisie ou de la conversion. Une autre habitude utile consiste à afficher des messages de contrôle pendant le développement, par exemple `print("age reçu :", age)`, puis à les retirer ou à les commenter une fois le programme stabilisé. Ces lignes de traçage coûtent quelques secondes à écrire et vous font gagner de longues minutes de réflexion à chaque débogage. Elles vous préparent aussi aux affichages plus structurés que vous mettrez en place dans les projets du second tiers du parcours, où un même programme affichera successivement des en-têtes, des valeurs et des bilans.

- print() affiche une valeur puis termine la ligne.
- Du texte s'écrit toujours entre guillemets simples ou doubles.
- print("2 + 3") affiche du texte, alors que print(2 + 3) affiche 5.
- Plusieurs arguments sont séparés par des virgules et affichés avec un espace.
- print() sans argument produit une ligne vide, utile pour aérer la sortie.
- Un appel de fonction se termine toujours par des parenthèses.
- print() convertit automatiquement chaque argument en texte pour l'afficher.
- Une phrase construite avec plusieurs arguments se lit mieux qu'une longue concaténation.
$lesson$),
  ('py-c1-p3', 'py-c1', 3, $lesson$Créer des variables et bien les nommer$lesson$, $lesson$
Créer une variable revient à donner un nom à une valeur pour pouvoir la retrouver ensuite. L'opération s'écrit en trois morceaux : le nom choisi, le signe égal, puis la valeur. Python exécute cette ligne en rangeant la valeur en mémoire et en associant le nom que vous avez écrit ; à partir de ce moment, utiliser ce nom dans le programme revient à utiliser la valeur. Les espaces autour du signe égal sont une convention de style fortement recommandée : age = 15 se lit mieux que age=15, et votre code gagne en lisibilité immédiate. Une même ligne peut contenir plusieurs affectations, mais la pratique courante est d'en écrire une par ligne, pour que chaque instruction reste lisible et facile à commenter. Remarquez enfin que la valeur peut être de n'importe quel type : du texte entre guillemets, un nombre entier, un nombre décimal ou un booléen. Le nom, lui, n'a aucun type : c'est simplement l'étiquette que vous collerez sur la valeur.

Une variable créée reste utilisable jusqu'à la fin du fichier, et vous pouvez la réutiliser autant de fois que vous voulez. Si vous lui donnez une nouvelle valeur, la précédente est remplacée : Python ne conserve pas les anciennes versions du nom, il ne retient que la valeur la plus récemment associée. Cette propriété est à l'origine de la plupart des calculs progressifs : on mémorise une somme, on y ajoute un nouveau montant, puis on réaffecte le résultat au même nom. Le nom désigne alors toujours l'état le plus récent du calcul. C'est aussi ce qui rend possibles les compteurs et les accumulations que vous écrirez très vite dans les chapitres sur les boucles. L'exemple ci-dessous montre les deux situations : d'abord un nom réaffecté, puis un nom qui s'enrichit lui-même à partir de sa propre valeur, ce qui peut surprendre au premier abord mais devient naturel en quelques lignes.

```python
age = 15
print(age)
age = 16
print(age)
total = 100
total = total + 50
print(total)
```

Deux pièges de nommage méritent votre attention dès maintenant. Le premier concerne la casse : Python différencie les majuscules et les minuscules, donc Age, AGE et age désignent trois variables potentiellement différentes. Si vous affectez age = 15 puis tentez d'afficher Age, Python signalera que ce nom n'existe pas, ce qui surprend souvent au début. Le second piège concerne le signe égal : dans un programme, il affecte, il ne compare pas. L'écriture age = 15 affecte la valeur 15 au nom age, tandis que la comparaison, qui demande à savoir si deux valeurs sont égales, utilise un double signe égal et sera abordée en détail dans le chapitre sur les conditions. Retenez dès maintenant cette opposition : un égal pour donner, deux égaux pour vérifier. Cette distinction vous évitera une classe entière d'erreurs incompréhensibles lorsque vous écrirez vos premiers tests.

Pour qu'un nom soit accepté, il doit respecter quelques règles strictes, simples mais non négociables. Un nom peut contenir des lettres, des chiffres et le caractère souligné, et il ne peut pas commencer par un chiffre : 2nom est refusé, tandis que nom2 est accepté. Il ne doit contenir ni espace ni signe de ponctuation : prix total, avec un espace, est invalide, alors que prix_total est parfait. Les accents sont techniquement acceptés par Python 3, mais on les évite par convention, pour rester lisible dans tous les environnements et éviter les mauvaises surprises d'encodage. Les mots réservés du langage, tels que print, if ou for, ne peuvent pas non plus servir de nom de variable, car Python les réserve à sa propre grammaire ; en pratique, le simple bon sens suffit à éviter ce cas. Une bonne vérification avant de valider un nom : peut-on le prononcer à voix haute comme un mot unique, sans espace et sans caractère parasite ?

La dernière règle de création de variable est moins syntaxique que culturelle : une variable doit porter un nom qui dit ce qu'elle contient. age est un bon nom pour un âge, prenom pour un prénom, prix_total pour une somme d'argent, nombre_de_tentatives pour un compteur d'essais. À l'inverse, des noms comme x, t1 ou machin obligent à relire le code pour comprendre ce qu'ils recouvrent, et cette dette s'accumule très vite. Quand vous débutez, la tentation est grande d'écrire le nom le plus court possible, parce qu'il est rapide à taper ; l'expérience montre que vous passerez beaucoup plus de temps à relire votre code qu'à l'écrire, et qu'un nom court mais bien choisi vaut mieux qu'un nom long mal choisi. Une bonne pratique complémentaire : n'utilisez une variable que pour une seule chose dans un même programme. Réutiliser un même nom pour stocker un âge puis un prix fonctionne techniquement, mais rend le programme immédiatement difficile à suivre.

Une bonne habitude complémentaire consiste à donner dès la création une valeur de départ à chaque variable, ce qu'on appelle l'initialisation. Python crée bien une variable au premier moment où vous l'affectez, mais un programme un peu plus long manipule souvent des valeurs calculées plus tard, et utiliser un nom avant toute affectation provoque une erreur du type `name 'compteur' is not defined` qui arrête l'exécution. En initialisant compteur = 0 ou total = 0 en haut du fichier, vous donnez à ces noms un état connu dès la première ligne, et les calculs suivants s'appuient sur une base stable. Cette précaution devient indispensable dès que des variables seront modifiées à l'intérieur de conditions ou de boucles, au chapitre suivant : vous vous souviendrez alors avoir rencontré le concept dès le premier chapitre. Pour l'instant, retenez la règle simple : avant d'ajouter quoi que ce soit à une variable, vérifiez qu'elle existe déjà, et si elle n'existe pas, créez-la avec une valeur de départ adaptée à son rôle, zéro pour un compteur, une chaîne vide pour un texte accumulé.

- L'affectation s'écrit nom = valeur, avec des espaces autour du signe égal.
- Une variable naît à sa première affectation ; aucune déclaration préalable n'est nécessaire.
- Réaffecter remplace la valeur précédente, qui n'est plus conservée.
- Un nom valide combine lettres, chiffres et soulignés, sans commencer par un chiffre.
- Ni espace ni signe : privilégiez prix_total à prix total.
- La casse compte : age et Age sont deux variables différentes.
- Un nom explicite, utilisé pour un seul rôle, rend le code beaucoup plus facile à relire.
$lesson$),
  ('py-c1-p4', 'py-c1', 4, $lesson$Les types de base en pratique$lesson$, $lesson$
Connaître le type d'une valeur, c'est savoir ce que Python autorise à en faire. Une valeur n'est jamais « nue » : elle est toujours accompagnée de son type, qui décide des opérations possibles, du rendu à l'écran et de la façon dont elle est mémorisée. La fonction type() répond à cette question en une ligne : donnez-lui une valeur ou un nom de variable, affichez ce qu'elle renvoie avec print(), et Python vous annonce str, int, float ou bool. C'est un réflexe de débutant excellent, et d'ailleurs un réflexe de développeur confirmé : devant un résultat incompréhensible, on affiche d'abord le type, ensuite la valeur. L'exemple ci-dessous illustre les quatre cas fondamentaux du chapitre. Prenez l'habitude de le relancer après chaque modification, en changeant une valeur par une autre, pour observer comment Python déduit le type à partir de ce que vous écrivez, et non à partir de ce que vous aviez l'intention d'écrire.

```python
print(type("bonjour"))
print(type(7))
print(type(3.14))
print(type(True))
```

Le type str représente toute donnée textuelle, ce que l'on appelle une chaîne de caractères. Tout ce qui est écrit entre guillemets est du str, même s'il ne contient qu'un seul caractère ou s'il ressemble à un nombre : "7" est du texte, tandis que 7 est un entier. Deux chaînes peuvent être concaténées avec le signe plus, ce qui les colle bout à bout sans rien ajouter entre elles ; si vous voulez un espace, il faut l'écrire explicitement, car Python n'en insère jamais spontanément. La fonction len() renvoie le nombre de caractères d'une chaîne, espaces compris, ce qui est utile pour valider une saisie ou afficher un compteur. Méfiez-vous enfin de la sensibilité aux espaces : "Alice" et "Alice " sont deux chaînes différentes, et une comparaison les distinguerait. Ces détails peuvent sembler anodins, mais ils expliquent la majorité des résultats surprenants obtenus avec du texte.

Le type int regroupe les nombres entiers, positifs ou négatifs, sans partie décimale. Les quatre opérations arithmétiques de base fonctionnent avec lui : addition, soustraction, multiplication et division. Attention à cette dernière : en Python 3, le signe slash renvoie toujours un résultat décimal, même quand il n'y a aucune décimale à afficher, de sorte que 7 divisé par 2 donne 3.5 et non 3. Si vous cherchez la partie entière du quotient, l'opérateur double slash la fournit directement, avec un comportement particulier pour les négatifs que vous découvrirez en cas de besoin. L'opérateur pourcentage, appelé modulo, donne le reste de la division : 7 % 2 vaut 1, ce qui permet notamment de vérifier si un nombre est pair. Le double astérisque calcule une puissance, pratique pour les carrés et les cubes. Toutes ces opérations renvoient un nouvel entier quand les deux termes en sont : Python ne modifie jamais la valeur d'origine, il crée un résultat que vous pouvez afficher ou affecter à une variable.

```python
print(7 + 2)
print(7 * 2)
print(7 / 2)
print(7 // 2)
print(7 % 2)
```

Le type float désigne les nombres à virgule, que l'on écrit en Python avec un point : 3.14, 0.5 ou -12.75 sont des flottants. Deux précautions reviennent sans cesse chez les débutants. La première : la virgule française est interdite dans le code, écrire 3,14 provoque une erreur de syntaxe, car la virgule sert à séparer les arguments. La seconde : la présence du point détermine le type, pas le nombre de décimales visible, si bien que 7.0 est bien un float, affiché avec son point. Un float peut résulter d'une division, comme 7 / 2, ou d'une conversion avec float("3.5"). Les décimaux sont en réalité des approximations binaires, ce qui produit parfois de légères erreurs d'arrondi sur de très grands calculs ; pour l'instant, contentez-vous de savoir que tout résultat de division est un float, et que cela change le comportement des comparaisons et des affichages.

Le type bool n'a que deux valeurs possibles : True et False, toujours écrites avec une majuscule, comme des noms propres. Dans un premier temps, considérez-les comme la réponse à une question fermée : est-ce que l'âge saisi est supérieur à dix-huit, est-ce que le mot de passe correspond, est-ce que le fichier existe. La plupart des booléens naîtront de comparaisons, que vous écrirez dès le chapitre suivant avec les conditions et les boucles ; pour l'instant, retenez surtout que Python distingue ce qui est vrai de ce qui est faux, et que cette distinction pilote les décisions d'un programme. Un détail pratique : les booléens s'affichent avec print() sous la forme exacte True ou False, et ils possèdent une particularité mathématique, puisque Python les traite volontiers comme 1 pour True et 0 pour False dans certains calculs.

```table
Type | Littéral typique | Résultat de `type()` | Remarque d'usage
--- | --- | --- | ---
`str` | `"bonjour"` ou `"7"` | `str` | texte entre guillemets, concaténé avec `+`, longueur avec `len()`
`int` | `7` | `int` | entiers sans virgule, `//` donne la partie entière et `%` le reste
`float` | `3.14` ou `7.0` | `float` | point obligatoire, une division `/` produit toujours un float
`bool` | `True` ou `False` | `bool` | deux valeurs avec majuscule, affichées telles quelles par `print()`
```

Un dernier principe résume la relation entre les noms et les types : le type appartient à la valeur, pas à la variable. Une variable n'est qu'une étiquette, et vous pouvez parfaitement lui donner d'abord un nombre puis un texte, auquel cas Python suit sans protester, puisque c'est la valeur qui dicte le type à chaque affectation. Cette souplesse est précieuse, mais elle interdit de raisonner à l'aveugle : rien ne vous garantit qu'une variable contient encore, à la ligne que vous exécutez, le type qu'elle possédait quelques lignes plus haut. D'où l'intérêt de type() comme outil de diagnostic, et d'une discipline simple : ne réutilisez pas un même nom pour un rôle de nature différente. Si age contient un entier, qu'il continue de contenir un entier jusqu'à la fin du programme. Cette règle, purement conventionnelle, n'interdit rien, mais elle élimine une catégorie entière de doutes. Quand un calcul échoue de façon incompréhensible, la méthode en trois temps reste toujours la même : affichez la valeur avec print(), affichez son type avec type(), puis remontez jusqu'à la ligne où cette valeur a été produite. Cette démarche, appliquée sans exception, résout la très grande majorité des blocages des premières semaines.

- str : vérifiez du texte avec type("bonjour"), int : un entier comme 7.
- float : un décimal comme 3.14, bool : soit True, soit False.
- Le séparateur décimal de Python est le point, jamais la virgule.
- Le texte "7" et le nombre 7 sont deux valeurs de types différents.
- La division avec un seul slash produit toujours un float.
- Les opérateurs // et % donnent la partie entière et le reste d'une division.
- type() est un outil de diagnostic : interrogez-le avant de douter d'un calcul.
$lesson$),
  ('py-c1-p5', 'py-c1', 5, $lesson$Lire une saisie avec input()$lesson$, $lesson$
La fonction input() est le point d'entrée des données humaines dans votre programme. Là où print() envoie une information vers l'écran, input() va la chercher auprès de l'utilisateur : elle affiche une invite, met le programme en attente, puis reprend dès que la personne appuie sur la touche Entrée. La valeur retournée est exactement ce qui a été tapé, sans le retour à la ligne final. On l'affecte presque toujours immédiatement à une variable, car une valeur retournée par une fonction et aussitôt oubliée ne sert à rien : c'est le nom de variable qui donne une seconde vie à la saisie. L'argument passé entre les parenthèses est l'invite, un texte de consigne affiché pour guider l'utilisateur ; il doit lui aussi être écrit entre guillemets. Un programme sans invite semble bloqué au moment de la saisie, alors qu'il attend patiemment : soignez ce texte, il fait partie de l'interface.

Le caractère fondamental à retenir, et celui que le quiz du chapitre vérifiera, tient en une phrase : input() renvoie toujours du texte, de type str. Il n'existe pas de variante qui devine que l'utilisateur voulait saisir un nombre : la frappe clavier produit des caractères, et Python vous rend ces caractères tels quels. Tapez 15, input() vous donne "15" ; tapez 3.5, elle vous donne "3.5" ; tapez rien du tout, elle vous donne une chaîne vide. Pour vous en convaincre définitivement, affichez le type de la saisie avec type() : le résultat affichera str, quelle que soit la forme du contenu. Cette règle est un avantage, pas une contrainte : elle rend le comportement du langage prévisible. Vous savez toujours ce que vous recevez, et vous savez toujours que la conversion en nombre, si vous en avez besoin, sera une étape explicite de votre code.

```python
age_texte = input("Quel âge avez-vous ? ")
print(age_texte)
print(type(age_texte))
print("Vous avez saisi :", age_texte)
```

Les conséquences de cette règle sont immédiates, et elles surprennent tout le monde au début. Si vous additionnez directement la saisie avec un nombre, Python refuse de deviner votre intention et signale une erreur, car il ne sait pas additionner du texte et un entier. Si vous additionnez deux saisies, il ne les additionne pas : il les colle, ce qui transforme la saisie 10 et la saisie 20 en chaîne 1020, un résultat parfaitement valide mais absurde pour un calcul. Même une opération apparemment inoffensive comme multiplier une saisie par trois répète trois fois le texte au lieu de tripler un nombre. Le remède est unique : convertir la saisie en nombre avant toute opération arithmétique, puis, si vous devez afficher du texte mélangeant mots et nombre, afficher le nombre avec print() en argument séparé ou le reconvertir avec str(). Vous disposez maintenant de toutes les pièces du puzzle ; la section suivante va les assembler pour de bon.

Un programme demande parfois plusieurs informations, et input() s'appelle alors autant de fois que nécessaire, dans l'ordre où vous souhaitez les poser. L'utilisateur répond à la première invite, appuie sur Entrée, puis la seconde invite apparaît : le programme ne reprend que lorsque chaque saisie est complète. Il faut alors être attentif à l'ordre des affectations, car c'est l'ordre des lignes qui détermine quelle variable reçoit quelle réponse. Un décalage, où l'on affecterait la première réponse à la seconde variable, produit un programme parfaitement fonctionnel mais faux, ce qui est le type d'erreur le plus difficile à détecter en relisant simplement le code. Pour vous en prémunir, affichez chaque valeur aussitôt après sa saisie pendant les tests : vous vérifiez du même coup que l'invite correspond bien à la donnée reçue. Une invite doit en outre être formulée sans ambiguïté, en mentionnant l'unité ou le format attendu quand cela peut prêter à confusion : « Quel âge avez-vous ? », « Quel est votre prénom ? », « Entrez le prix en euros ». L'utilisateur ne voit jamais votre code, seulement vos invites et vos affichages : elles constituent à elles seules l'interface de votre programme, et leur qualité se juge au premier contact.

- input() affiche l'invite, attend une saisie, puis renvoie ce qui a été tapé.
- La valeur retournée est toujours une chaîne de caractères, de type str.
- On affecte la saisie à une variable pour pouvoir l'utiliser ensuite.
- input() ne convertit jamais en nombre : cette étape revient à votre code.
- Une saisie laissée vide renvoie une chaîne vide, sans provoquer d'erreur.
- L'invite est un texte ordinaire : elle doit s'écrire entre guillemets.
$lesson$),
  ('py-c1-p6', 'py-c1', 6, $lesson$Convertir sans se tromper$lesson$, $lesson$
Convertir une saisie en nombre, c'est traduire un texte vers un type avec lequel le calcul est possible. Python fournit pour cela deux fonctions de conversion, int() et float(), qui transforment une chaîne en entier ou en décimal. Le principe est simple : on lit au clavier avec input(), on convertit immédiatement, puis on calcule. Tout autre ordre conduit à un échec. La raison en tient aux règles d'opération : l'addition n'est autorisée qu'entre deux valeurs de types compatibles, et Python préfère refuser une opération douteuse plutôt que d'inventer un résultat. Notez que la conversion ne modifie pas la saisie d'origine : int("15") renvoie un nouveau nombre 15, tandis que la chaîne "15" continue d'exister en mémoire. C'est pourquoi il est d'usage d'affecter le résultat de la conversion à une variable distincte, par exemple age_texte pour la saisie et age pour le nombre obtenu, afin que la suite du programme ne manipule plus que des nombres.

Les deux conversions n'acceptent pas les mêmes contenus, et c'est là que se cachent les erreurs les plus fréquentes. int("15") réussit, mais int("3.5") échoue, parce que "3.5" n'est pas la représentation d'un entier : Python refuse de tronquer silencieusement une valeur, par crainte de vous faire perdre une information. float() est plus tolérant : elle accepte "3.5" mais aussi "3", puisque tout entier peut être lu comme un décimal. Quand vous partez d'une saisie dont la forme exacte est inconnue, une séquence sûre consiste à convertir en float puis, si vous avez besoin d'un entier, à appeler int() sur ce décimal ; int(3.7) donne 3, car cette conversion tronque la partie décimale au lieu d'arrondir. Pour un âge saisi au clavier, la conversion directe avec int() reste la plus naturelle, à condition d'anticiper le cas d'une saisie invalide.

```python
age_texte = input("Quel âge avez-vous ? ")
age = int(age_texte)
dans_dix_ans = age + 10
print("Dans 10 ans, vous aurez", dans_dix_ans, "ans.")
```

L'inverse est tout aussi important : str() transforme une valeur non textuelle en chaîne de caractères. C'est indispensable dès que vous voulez concaténer un nombre avec du texte, par exemple pour produire une phrase du type "J'ai 25 ans". L'écriture "J'ai " + age + " ans" échoue, car elle mélange du texte et un entier ; l'écriture correcte est "J'ai " + str(age) + " ans", où str(age) fabrique la version textuelle du nombre. Dans la pratique, une alternative plus simple existe presque toujours : confier les éléments séparés à print() en les listant entre virgules, car la fonction convertit elle-même chaque argument pour l'afficher, d'où print("J'ai", age, "ans.") qui produit exactement la même phrase. Retenez donc deux réflexes : str() pour construire délibérément du texte, et print() multi-arguments pour afficher simplement. Les deux s'appuient sur la même mécanique, la conversion vers le texte, que vous réutiliserez chaque fois que vous afficherez un résultat.

Que se passe-t-il quand la conversion échoue, par exemple si l'utilisateur tape pluie ou 12a ? int("pluie") déclenche une erreur de conversion appelée ValueError, qui arrête immédiatement le programme avec un message expliquant que la chaîne n'est pas convertible en entier. Deux approches permettent d'anticiper ce cas. La première consiste à protéger la conversion avec un bloc try et except, présenté ci-dessous : les instructions risquées sont placées entre try et except, et si une erreur survient, Python n'arrête pas le programme, il exécute le bloc except à la place. Vous en verrez la mécanique complète dans le chapitre consacré aux erreurs et exceptions ; pour l'instant, retenez le squelette, qui suffit à l'exercice de fin de chapitre. La seconde approche consiste à tester la saisie avant de la convertir avec une condition, ce que vous apprendrez au chapitre sur les conditions et les boucles. Dans les deux cas, l'idée est la même : une conversion peut échouer, un bon programme le prévoit.

```python
saisie = input("Quel âge avez-vous ? ")
try:
    age = int(saisie)
except ValueError:
    print("Saisie invalide")
```

La chaîne complète d'un programme interactif respecte donc toujours le même ordre, quelle que soit sa complexité future. On interroge l'utilisateur avec input(), on reçoit du texte, on convertit ce texte en nombre avec int() ou float(), on effectue les calculs sur des nombres, puis on affiche les résultats, soit directement avec print() et plusieurs arguments, soit après reconversion avec str() si la sortie doit être une phrase unique construite par concaténation. Cet enchaînement, lisible à l'œil dans l'exemple précédent, est le schéma de tous les petits programmes utilitaires que vous écrirez désormais. L'ordre n'est pas négociable : inverser deux étapes, calculer avant de convertir ou concaténer avant de convertir, suffit à faire échouer le programme. Une fois ce réflexe installé, la manipulation des nombres au clavier ne vous posera plus de difficulté, et vous pourrez vous concentrer sur la logique métier de vos futurs projets.

Trois réflexes de conversion restent à emporter avec vous avant de passer à la suite. Le premier : convertissez une seule fois, au plus près de la saisie, puis ne manipulez plus que des nombres. Répéter int() à chaque ligne de calcul signale que l'étape de conversion a été oubliée quelque part dans le programme. Le second : choisissez le type cible en fonction de l'usage, pas en fonction de l'affichage. Un âge se compte en années entières et se convertit donc en int, tandis qu'un prix, une moyenne ou une durée exprimée en heures appelle float, lequel accepte d'ailleurs toute valeur entière sans perte d'information. Enfin, méfiez-vous des conversions effectuées trop tôt : int(3.9) donne 3 et non 4, car cette conversion tronque au lieu d'arrondir, de sorte qu'une moyenne transformée en entier perd ses décimales. Gardez donc les valeurs précises aussi longtemps que possible et n'arrivez à un entier qu'au moment où le résultat doit l'être, par exemple pour afficher un âge, un numéro d'étape ou un effectif de personnes.

```table
Fonction | Exemple | Résultat | Cas d'usage typique
--- | --- | --- | ---
`int()` | `int("15")` | entier `15` | une saisie d'âge convertie une seule fois, au plus près du clavier
`int()` | `int("3.5")` | échoue, le texte n'est pas un entier | Python refuse de tronquer silencieusement une valeur
`float()` | `float("3.5")` | décimal `3.5` | un prix, une moyenne ou une durée en heures ; accepte aussi `"3"`
`float()` puis `int()` | `int(3.7)` | `3` | séquence sûre si la saisie a une forme inconnue, mais elle tronque
`str()` | `str(15)` | texte `"15"` | construire du texte, sinon `print()` avec plusieurs arguments
```

- int("15") transforme le texte 15 en nombre entier 15.
- float("3.5") transforme le texte 3.5 en nombre décimal 3.5.
- str(15) transforme l'entier 15 en texte "15".
- int("3.5") échoue : le texte doit représenter un entier sans décimale.
- int("abc") provoque une erreur de conversion, de type ValueError.
- Une conversion crée une nouvelle valeur ; la saisie d'origine reste du texte.
- Convertissez avant de calculer, jamais après : c'est l'ordre qui fait réussir le programme.
- Pour afficher un nombre dans une phrase, privilégiez print() avec plusieurs arguments.
$lesson$),
  ('py-c1-p7', 'py-c1', 7, $lesson$Écrire un code lisible$lesson$, $lesson$
Un programme est d'abord écrit pour un humain, et seulement ensuite pour un ordinateur. L'ordinateur ne se soucie pas de l'endroit où vous placez vos espaces ni du nom que vous choisissez : il exécutera avec le même zèle un fichier bien structuré et un fichier illisible. Vous, en revanche, passerez l'essentiel de votre temps de développeur à relire du code, le vôtre, celui d'autres personnes, et surtout le vôtre d'il y a trois mois. C'est pourquoi la lisibilité n'est pas un luxe réservé aux grands projets : c'est un investissement qui commence dès la première ligne que vous écrivez. Une bonne formule résume l'essentiel : un code lisible est un code que vous pourrez encore comprendre dans trois mois. À l'inverse, un code comprimé, avec des noms abrégiés et aucune structure, vous obligera à reconstituer votre propre raisonnement à chaque relecture, ce qui coûte infiniment plus cher que quelques espaces et quelques lettres en plus.

Le premier levier de lisibilité est le nom des variables. Un nom doit dire ce qu'il contient, de façon à rendre le commentaire presque inutile. Comparez deux versions d'un même calcul : la première, avec a et t, oblige à remonter dans le fichier pour deviner ce que représentent ces lettres ; la seconde, avec age et age_dix_ans, se lit comme une phrase et se comprend sans effort. Les noms composés gagnent à être explicites jusque dans leur rôle : prix_total pour une somme, moyenne_classe pour une moyenne, saisie_utilisateur pour une donnée clavier, compteur_essais pour un nombre de tentatives. Quand un nom vous semble trop long, demandez-vous s'il existe une formulation plus courte tout aussi claire, plutôt que de tomber dans l'abréviation. Un bon équilibre se juge à la lecture à voix haute : si vous pouvez prononcer le nom comme un mot du langage courant et que la phrase garde un sens, il est bon.

```python
a = 15
t = a + 10
print(t)
```

```python
age = 15
age_dans_dix_ans = age + 10
print("Dans 10 ans, vous aurez", age_dans_dix_ans, "ans.")
```

La convention de nommage à adopter sans attendre s'appelle snake_case : lettres minuscules, mots séparés par le caractère souligné. C'est le style recommandé par la communauté Python, consacré par son guide de style, et il s'applique aux variables comme, plus tard, aux fonctions et aux noms de fichiers. L'alternative hongrois ou camelCase, qui enchaîne des mots en alternant majuscules et minuscules, existe dans d'autres langages, mais elle prête à confusion sous Windows, où la casse des fichiers n'est pas toujours respectée, et elle s'accorde moins bien avec les mots français composés. Retenez donc la règle toute simple : minuscules partout, soulignés entre les mots, aucun chiffre en tête, aucun espace. L'uniformité a plus de valeur que le style personnel : dans une équipe, tout le monde écrit de la même façon, et votre futur collaborateur retrouve immédiatement le nom que vous avez choisi.

Au-delà des noms, quelques habitudes rendent un fichier instantanément plus clair. Espacez toujours les opérateurs, en écrivant age = age + 10 plutôt qu'une version collée qui fatigue l'œil. Réservez une instruction par ligne : Python le permet naturellement, et chaque ligne devient une unité de pensée que l'on peut commenter ou déplacer séparément. Utilisez le signe dièse pour insérer un commentaire, mais réservez-le à l'explication du pourquoi, jamais du quoi : si une ligne nécessite une explication sur ce qu'elle fait, c'est probablement son nom qui doit changer. Gardez les lignes raisonnables en longueur, aérez les groupes d'instructions qui remplissent une étape distincte du programme, et n'utilisez une variable que pour un seul rôle. Enfin, pendant que vous apprenez, affichez volontiers les valeurs intermédiaires avec print() : c'est un excellent moyen de vérifier que le résultat est celui attendu à chaque étape, et ces lignes de contrôle se suppriment ensuite en un instant.

Python possède enfin une règle qui tient à la fois de la syntaxe et de la lisibilité : l'indentation. Contrairement à d'autres langages, qui délimitent un bloc d'instructions avec des accolades, Python se fie à l'espacement des lignes. Toutes les instructions qui appartiennent au même bloc doivent commencer exactement au même niveau, et l'on entre dans un bloc en décalant d'un cran vers la droite. Dans l'exemple guidé de ce chapitre, les lignes placées sous try, sous except et sous else sont décalées, ce qui indique visuellement, sans commentaire ni symbole supplémentaire, à quel cas elles appartiennent. Une indentation fautive ne produit pas de résultat faux en silence : elle déclenche une erreur d'indentation qui arrête le programme, ce qui est en réalité une protection bienvenue pour un débutant. Choisissez d'ores et déjà de taper quatre espaces par niveau, et surtout ne mélangez jamais tabulations et espaces, une pratique recommandée par le guide de style de Python. Le résultat tient dans une promesse : un code indenté régulièrement se lit comme une structure, et l'œil repère immédiatement les blocs sans avoir à chercher où commence et où finit chaque groupe d'instructions.

- Donnez des noms explicites : prix_total plutôt que pt, age_dix_ans plutôt que t.
- Respectez la convention snake_case : minuscules et soulignés entre les mots.
- Espacez les opérateurs : age = age + 10, jamais age=age+10.
- Réservez une instruction par ligne et commentez le pourquoi avec #.
- Une variable porte un seul rôle dans un même programme.
- Relisez votre code à voix haute : si une phrase sonne mal, renommez.
$lesson$),
  ('py-c1-p8', 'py-c1', 8, $lesson$Exemple guidé : votre âge dans dix ans$lesson$, $lesson$
Il est temps d'assembler toutes les pièces du chapitre dans un programme complet, exécutable tel quel, qui correspond exactement à l'exercice pratique qui suivra cette leçon. Le voici en un seul bloc : il salue l'utilisateur, demande son âge, protège la conversion contre les saisies invalides, calcule l'âge dans dix ans, puis affiche une phrase complète. Vous pouvez le recopier dans un fichier .py et le lancer immédiatement, puis le modifier pour vérifier que vous en maîtrisez chaque ligne.

```python
print("Bienvenue dans le calculateur d'âge !")
saisie = input("Quel âge avez-vous ? ")
try:
    age = int(saisie)
except ValueError:
    print("Saisie invalide")
else:
    dans_dix_ans = age + 10
    print("Dans 10 ans, vous aurez", dans_dix_ans, "ans.")
```

La première ligne utilise print() pour afficher un message d'accueil. Elle ne sert à rien pour la logique du calcul, mais elle rend l'interface plus accueillante et elle vous confirme que le programme a bien démarré : si ce message apparaît, l'exécution est lancée et le fichier est correct. Notez que le texte contient une apostrophe à l'intérieur de guillemets doubles, un cas que nous avons vu dans la section sur print(), et qu'aucune variable n'est nécessaire ici, puisque ce message ne dépend de rien. C'est volontairement la ligne la plus simple du programme, pour commencer en douceur : elle introduit l'invite visuelle qui annonce à l'utilisateur que son tour est venu d'intervenir.

La deuxième ligne est le cœur de l'interaction avec l'utilisateur. La fonction input() affiche l'invite « Quel âge avez-vous ? », met le programme en pause et attend la frappe suivie de la touche Entrée. La valeur retournée est ensuite affectée à la variable saisie, nommée ainsi parce qu'elle contient exactement ce que la personne a tapé, ni plus ni moins. Retenez bien la nature de cette donnée : elle est de type str, même si l'utilisateur compose le chiffre 25. Aucun calcul n'est encore possible à ce stade, et c'est normal. Le nom saisie plutôt que s est un choix délibéré de lisibilité : en lisant la ligne, on comprend immédiatement d'où vient la valeur et ce qu'elle représente, sans avoir à consulter la suite du fichier.

Le bloc try et except assure la robustesse du programme. Les instructions placées sous try sont tentées d'abord : Python essaie de convertir saisie en nombre avec int(). Si la conversion réussit, tout continue normalement et le bloc except est ignoré. Si elle échoue, parce que l'utilisateur a tapé du texte, du vide ou un nombre décimal, Python déclenche l'exception ValueError, interrompt le bloc try et exécute aussitôt les instructions de except : le message « Saisie invalide » s'affiche, puis le programme se termine proprement au lieu de planter avec une pile d'erreurs incompréhensible. Cette structure répond donc exactement à la consigne de l'exercice : n'importe quelle saisie qui n'est pas un entier produit le message attendu. Le chapitre sur les erreurs et les exceptions explorera ce mécanisme en profondeur ; pour l'instant, retenez le squelette en trois temps : on essaie, on attrape l'échec, on prévient l'utilisateur.

Le bloc else s'exécute uniquement quand aucune exception n'a eu lieu, c'est-à-dire quand la conversion a réussi et que la variable age contient un vrai entier. C'est là que le calcul est effectué : age + 10 produit une nouvelle valeur que l'on affecte à dans_dix_ans, nom explicite qui dit exactement ce que la variable contient. Remarquez que l'opération utilise deux entiers, donc le résultat est lui-même un entier, sans conversion supplémentaire. La variable age reste intacte : Python ne modifie jamais la valeur d'origine lors d'une addition, il crée un résultat que l'on range sous un autre nom. Si vous préférez réutiliser le même nom, écrire age = age + 10 fonctionne aussi et exprime l'idée d'une mise à jour, mais garder les deux noms distincts facilite ici la lecture de la phrase finale et évite toute confusion entre l'âge actuel et l'âge projeté.

La dernière ligne assemble la phrase de sortie en confiant plusieurs éléments à print(), séparés par des virgules. Python convertit automatiquement chaque argument pour l'affichage, de sorte que le nombre dans_dix_ans s'insère dans la phrase sans avoir besoin de str() : c'est l'alternative pratique à la concaténation que nous avons vue dans la section sur les conversions. L'avantage de cette forme est qu'elle reste lisible et qu'elle ne casse pas si le résultat devient un float, par exemple si vous remplacez l'addition par une division. Pour produire une phrase unique stockée dans une variable, la concaténation avec str() resterait nécessaire, mais pour de l'affichage pur, le multi-arguments est la solution recommandée. Prenez l'habitude de choisir la forme la plus courte qui respecte la lisibilité, plutôt que celle qui vous vient en premier.

Pour vérifier que votre programme fonctionne réellement, il faut le tester avec plusieurs saisies, pas seulement avec la plus simple. Avec 20, vous devez obtenir « Dans 10 ans, vous aurez 30 ans. » Avec 7, la phrase affiche 17. Avec abc, avec un espace seul, ou avec 3.5, la conversion int() échoue et le programme affiche « Saisie invalide » puis s'arrête sans erreur fatale. Testez aussi une valeur limite, comme 0 ou 99, pour constater que le calcul tient toujours. Cette habitude de tester les cas normaux, les cas limites et les cas invalides est la même que celle des professionnels : un programme n'est pas terminé quand il fonctionne une fois, mais quand il se comporte comme prévu dans toutes les situations prévisibles. Notez au passage que 3.5 est rejeté non pas parce que le nombre est absurde, mais parce qu'il n'est pas un entier, ce qui est exactement la règle demandée dans l'exercice.

Une fois convaincu que le programme répond à la consigne, amusez-vous à le modifier : demandez l'âge dans vingt ans, affichez l'âge en mois en multipliant par douze, ajoutez un message de remerciement après le résultat, ou changez le texte d'invite pour le rendre plus convivial. Chaque modification est un petit laboratoire où vous appliquez ce que la leçon vient de vous apprendre : variable, type, conversion, affichage, nommage. Quand vous vous sentirez à l'aise, fermez cette page et récrivez le programme de mémoire dans un fichier neuf, en vous interdisant de regarder la solution. C'est précisément ce que demandera l'exercice pratique, et c'est à ce moment-là que vous mesurerez ce que vous avez réellement acquis. Les erreurs éventuelles ne sont pas un échec : lisez-les, corrigez-les, relancez, et observez le programme revenir à la vie.
$lesson$),
  ('py-c1-p9', 'py-c1', 9, $lesson$À retenir$lesson$, $lesson$
- Python est un langage interprété : vos instructions d'un fichier .py sont exécutées une par une.
- print() affiche une valeur à l'écran ; c'est aussi votre principal outil de débogage.
- Une variable est un nom qui pointe vers une valeur ; le signe égal affecte, il ne compare pas.
- Le type d'une valeur est déduit automatiquement ; type() permet de l'afficher.
- str stocke du texte, int des entiers, float des décimaux, bool les valeurs True et False.
- 3.14 est de type float, 7 est de type int, "7" est de type str.
- input() affiche une invite et renvoie toujours du texte, jamais un nombre.
- int() et float() convertissent un texte en nombre ; str() fait l'inverse.
- int("abc") et int("3.5") échouent : prévoyez un garde-fou try et except.
- Affichez un nombre dans une phrase avec print("...", age, "...") ou avec str(age).
- Respectez snake_case et donnez des noms explicites : age, prix_total, saisie_utilisateur.
- Un code lisible est un code que vous pourrez encore comprendre dans trois mois.
$lesson$),
  ('py-c1-p10', 'py-c1', 10, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : écrire 10 + "5" et se faire arrêter, car Python refuse d'additionner un entier et un texte → Correction : convertissez d'abord, par exemple 10 + int("5").
- Piège : oublier int() après une saisie, puis écrire saisie + 10 qui colle du texte à un nombre → Correction : age = int(input("Quel âge avez-vous ? ")).
- Piège : appeler Print("Bonjour") et recevoir l'erreur name 'Print' is not defined → Correction : le nom de la fonction s'écrit en minuscules, print, et Python est sensible à la casse.
- Piège : nommer une variable 2nom ou prix total, avec un chiffre en tête ou un espace → Correction : écrivez nom2 et prix_total, lettres, chiffres et soulignés seulement.
- Piège : écrire print(Bonjour) sans guillemets, ce qui déclenche une erreur sur un nom inconnu → Correction : tout texte littéral s'écrit entre guillemets, print("Bonjour").
- Piège : croire que input() renvoie un nombre parce que l'utilisateur a tapé des chiffres → Correction : input() renvoie toujours du texte, vérifiez avec type() puis convertissez.
- Piège : écrire 3,14 dans le code et provoquer une erreur de syntaxe → Correction : le séparateur décimal de Python est le point, écrivez 3.14.
- Piège : lancer un script qui semble ne rien faire et conclure qu'il ne marche pas → Correction : ajoutez des print() pour rendre l'exécution visible, étape par étape.
$lesson$),
  ('py-c1-p11', 'py-c1', 11, $lesson$Pour aller plus loin$lesson$, $lesson$
Le tutoriel officiel de Python en français reste la référence pour approfondir ce chapitre, et vous y retrouverez chaque notion abordée ici, avec des exemples supplémentaires et des exercices progressifs. L'adresse est https://docs.python.org/fr/3/tutorial/ : le chapitre consacré aux types fondamentaux, aux chaînes de caractères et à l'entrée-sortie reprend point par point les sujets traités dans cette leçon. Pour avoir sous la main la description détaillée de chaque type, consultez la page des types intégrés sur https://docs.python.org/fr/3/library/stdtypes.html, qui décrit les opérations disponibles sur str, int, float et bool, ainsi que leurs méthodes, que vous découvrirez au fil des prochains chapitres.

Deux autres documents vous seront utiles au fur et à mesure. Le premier liste toutes les fonctions intégrées de Python, donc print(), input(), type(), int(), float() et str(), avec leur syntaxe exacte et des exemples : https://docs.python.org/fr/3/library/functions.html. Le second est le guide de style de la communauté Python, qui codifie notamment la convention snake_case employée dans cette leçon : https://peps.python.org/pep-0008/. Collez simplement ces adresses dans la barre d'adresse de votre navigateur. N'essayez pas de tout mémoriser : ouvrez plutôt ces pages le jour où une question précise se pose, et revenez-y quand vous voulez vérifier un détail de syntaxe.
$lesson$),
  ('py-c1-p12', 'py-c1', 12, $lesson$Et maintenant : la vidéo du chapitre$lesson$, $lesson$
La vidéo du chapitre prolonge cette leçon pas à pas, en reprenant les mêmes notions dans l'ordre : exécution d'un premier script, création de variables, inspection des types avec type(), puis lecture d'une saisie et conversion vers un nombre. Regardez-la avec votre éditeur ouvert à côté de vous et rejouez chaque exemple à l'écran, en pause si nécessaire : la manipulation en direct consolide la lecture. Une fois la visionnage terminé, passez à l'exercice pratique, où vous écrirez seul le programme complet de l'exemple guidé : demander l'âge, calculer l'âge dans dix ans, afficher la phrase complète et afficher « Saisie invalide » si la saisie n'est pas un nombre.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('py-c2-p1', 'py-c2', 1, $lesson$Comprendre : le programme qui choisit et qui recommence$lesson$, $lesson$
Jusqu'ici, vos programmes avaient une allure bien régulière : une instruction après l'autre, du haut vers le bas, dans un ordre fixé une fois pour toutes. C'est parfait pour apprendre à créer une variable, à afficher un texte, à calculer un prix TTC ou à convertir une chaîne en nombre, mais un script qui ne décide de rien et qui ne répète rien reste bien modeste face aux besoins réels. Or les deux gestes qui donnent leur puissance aux logiciels sont exactement ceux que vous allez maîtriser dans ce chapitre : décider, c'est-à-dire choisir une conduite selon une situation, et répéter, c'est-à-dire exécuter la même tâche dix fois, mille fois, ou jusqu'à ce qu'un état soit atteint. Une caisse qui refuse un paiement faute de provision, un site qui affiche chaque article d'un catalogue, un jeu qui relance une partie jusqu'à la victoire : derrière ces comportements, il n'y a presque toujours que des conditions et des boucles, enchaînées avec soin.

Décider sans boucler suffit parfois : un seul test, une seule action, puis le programme reprend sa marche normale. Répéter sans décider suffit aussi, quand la tâche est strictement mécanique, comme afficher les nombres de 1 à 100. La vraie force apparaît quand les deux se combinent : répéter une opération et, à chaque tour, décider si l'on continue, si l'on change de comportement ou si l'on s'arrête. C'est exactement la structure du jeu « devinez le nombre » que vous coderez en fin de chapitre : on répète les essais tant que la réponse est fausse, on décide à chaque fois d'afficher « plus » ou « moins », et l'on sort de la boucle dès que le joueur a trouvé le nombre. Toute la difficulté pratique se joue donc sur un point précis : savoir formuler le test juste, choisir la boucle adaptée, et surtout garantir que la répétition se terminera un jour.

Ce chapitre s'inscrit directement à la suite du précédent. Vous savez créer des variables de type int, float, str et bool, les afficher, les faire évoluer grâce aux opérateurs arithmétiques. Vous allez maintenant les mettre au service de décisions. La même variable qui, au chapitre 1, servait simplement à mémoriser un score devient ici le cœur d'un test : si le score dépasse le record, alors on affiche une médaille. Rien de neuf sur la variable elle-même, tout est neuf sur l'usage que vous en faites. La progression du parcours reste volontairement linéaire : après avoir appris à décider et à répéter, vous découvrirez les fonctions pour découper votre code, puis les listes et les dictionnaires pour organiser des données, et enfin les fichiers, les exceptions et les modules. Chaque brique s'appuie sur la précédente, et les conditions et les boucles réapparaîtront dans tous vos exercices, jusqu'au mini-projet du dernier chapitre.



Une condition, en Python, est une question à laquelle le langage répond soit par vrai, soit par faux, et par rien d'autre. Lorsque vous écrivez `note >= 10`, vous ne demandez pas à Python de produire une note : vous lui demandez de comparer deux valeurs et de prononcer un jugement. Ce jugement prend la forme d'un objet booléen, de type bool, dont il n'existe que deux valeurs, True et False, avec la majuscule initiale obligatoire. Cette propriété est précieuse, car elle rend le comportement du programme prévisible : un test est soit satisfait, soit insatisfait, sans zone grise. Python évalue l'expression de gauche à droite, applique les règles de priorité que vous connaissez déjà, puis rend son verdict. Vous pouvez d'ailleurs vérifier cette mécanique dans votre interpréteur en tapant simplement note >= 10 après avoir donné une valeur à note : la réponse affichée sera True ou False, rien de plus. Comprendre ce fonctionnement est la clé de tout le chapitre, car une condition mal construite produit un mauvais jugement, et un mauvais jugement produit un programme qui se trompe silencieusement.

L'instruction if est le mécanisme qui transforme ce jugement en action. Elle se compose du mot-clé if, suivi d'une expression booléenne, puis d'un deux-points, puis d'un bloc d'instructions indenté. Si l'expression est vraie, le bloc est exécuté ; sinon, Python saute directement au premier niveau qui suit, sans jamais l'exécuter. Le mot-clé else est facultatif : il introduit un bloc de repli qui ne s'exécute que lorsque le test de if est faux, ce qui permet de couvrir explicitement l'autre cas. On écrit donc une alternative complète : si la condition est vraie, une conduite ; sinon, une autre. L'absence de else n'est pas une erreur, elle signifie simplement que rien ne doit se passer dans le cas contraire, ce qui est un choix de programme tout à fait légitime. Un même fichier peut contenir autant de if indépendants que nécessaire, chacun évalué pour lui-même, et il est tout à fait normal d'en empiler plusieurs lorsque les décisions sont sans rapport les unes avec les autres.

L'instruction elif, contraction de else if, ajoute des cas alternatifs entre le if initial et le else final. Elle permet de tester une seconde expression uniquement si la première s'est révélée fausse, puis une troisième, puis une quatrième, sans limite de nombre. La grande règle à retenir est que Python évalue les branches dans l'ordre et s'arrête dès la première dont le test est vrai : tout le reste est ignoré. L'ordre des tests n'est donc jamais anodin. Si vous placez un cas général avant un cas particulier, le cas particulier devient inaccessible, et votre programme semble ignorer une situation pourtant prévue. On écrit volontiers les cas les plus restrictifs en premier et le cas de base en dernier, de sorte que chaque branche reste joignable. Le else final n'est pas obligatoire, mais lorsqu'il est présent, il capte toutes les situations non mentionnées explicitement, ce qui sécurise le raisonnement : à la fin de la structure, chaque possibilité a été entendue.

L'indentation n'est pas une question de style en Python, c'est la grammaire même du langage. Les quatre espaces qui débutent le bloc associé à if, elif ou else délimitent précisément ce qui dépend du test et ce qui en est indépendant. Une seule instruction mal indentée suffit à faire comprendre à l'interpréteur un programme que vous n'aviez pas écrit, ou à déclencher une erreur IndentationError. La convention universellement adoptée consiste à indenter de quatre espaces, sans mélanger tabulations et espaces, et à aligner else exactement sous le if auquel il répond. Cette alignement visuel n'a aucun effet pour l'ordinateur, mais il rend la structure immédiatement lisible pour un humain. Retenez également que le bloc s'interrompt dès que l'indentation revient à gauche : si vous ajoutez une instruction à peine décalée, vous sortez du if sans vous en rendre compte, et cette instruction s'exécutera dans tous les cas. Si votre éditeur affiche les caractères invisibles, profitez-en : les espaces de fin de ligne et les tabulations se repèrent d'un coup d'œil, et il ne faut jamais les mélanger au sein d'un même fichier, sous peine de voir l'interpréteur protester là où vous croyiez voir un bloc parfaitement valide. Un bon réglage d'éditeur, quatre espaces automatiques et l'affichage des caractères de tabulation, vous épargnera la majorité de ces accidents.

Une boucle, elle, ne juge pas une situation, elle organise la répétition. Plutôt que de copier-coller dix fois le même print, vous écrivez le travail une seule fois et vous demandez à Python de l'exécuter plusieurs fois. Il existe deux grandes familles, et leur distinction est simple à retenir. La boucle for parcourt une séquence : elle sait d'avance ce qu'elle va visiter, que ce soit un ensemble de nombres généré par range, les éléments d'une liste ou les clés d'un dictionnaire. La boucle while, quant à elle, répète son bloc tant qu'une condition reste vraie : elle ne sait pas à l'avance combien de tours seront nécessaires, ce qui en fait l'outil des attentes et des durées inconnues. Les deux syntaxes se ressemblent, mais leur logique diffère : l'une déroule une collection, l'autre surveille un état. Choisir la bonne boucle dès la première ligne de code évite les contorsions de fin de programme.

La boucle for est de loin la plus utilisée, parce qu'elle gère elle-même la mécanique de la répétition. Vous n'avez pas à créer de compteur, à l'incrémenter, ni à vérifier que vous ne dépassez pas la fin : Python avance d'un élément à l'autre et vous expose chaque valeur à son tour. L'instruction range génère une séquence de nombres entiers, et c'est souvent la solution la plus claire pour répéter un nombre fixe de fois. La boucle for sait aussi parcourir directement une liste, un dictionnaire ou une chaîne de caractères, auquel cas la variable de boucle reçoit successivement chaque élément, sans que vous ayez à manipuler d'index. C'est ce comportement qui la rend si robuste : moins vous gérez vous-même la position dans la collection, moins vous avez d'occasions de vous tromper. Un décompte hors bornes, un oubli d'incrément, une erreur sur la longueur de la liste : autant de bugs que la boucle for rend structurellement impossibles.

La boucle while, elle, repose entièrement sur une expression booléenne placée après son mot-clé. Tant que cette expression vaut True, le bloc se ré-exécute ; dès qu'elle devient False, la boucle se termine et le programme continue. Cette mécanique est redoutablement puissante, car elle permet d'attendre un événement, de relancer une saisie jusqu'à obtenir une réponse correcte, ou de répéter un calcul jusqu'à atteindre une précision suffisante. Elle est aussi la source des boucles infinies, le défaut classique des débutants : si la condition reste vraie à jamais, le programme ne rend jamais la main. La parade tient en une discipline simple : toute boucle while doit modifier, à chaque tour, quelque chose qui rapproche la condition de sa valeur de sortie. Sans cette évolution, la condition ne change jamais, le verdict ne change jamais, et la boucle tourne en rond jusqu'à ce que vous l'interrompiez manuellement. Avant de lancer un tel programme, lisez la condition à voix haute et posez la question suivante : qu'est-ce qui devrait la rendre fausse au bout d'un moment ? Si la réponse est rien, corrigez le code avant même de l'exécuter, vous vous épargnerez une session de débogage où l'on regarde un écran se remplir sans fin sans savoir quelle ligne arrêter.

Les instructions break et continue complètent le dispositif en permettant d'interrompre le déroulement normal d'une boucle. break sort immédiatement de la boucle en cours, comme si le programme avait trouvé ce qu'il cherchait ; continue saute directement à la fin du tour en cours, ce qui entraîne l'oubli du reste du bloc et le passage au tour suivant. Tous deux se placent à l'intérieur d'une condition, car une interruption inconditionnelle n'aurait aucun sens. Utilisés avec mesure, ils rendent la lecture plus claire : une recherche peut s'arrêter dès la première correspondance, un filtre peut écarter un cas particulier sans imbriquer trois niveaux d'indentation. Abusés, ils produisent l'inverse : le flux devient difficile à suivre, les sorties se multiplient et personne ne sait plus à quel endroit exact la boucle termine son travail. La bonne pratique consiste à réserver break aux sorties anticipées justifiées et continue aux exclusions rares, en gardant à l'esprit que la majorité des boucles n'en a pas besoin.

Conditions et boucles forment un couple indissociable dans la pratique, car un programme réel combine presque toujours les deux. Un compteur qui s'incrémente, un cumul qui s'additionne, un élément que l'on recherche : voici trois motifs qui reviennent sans cesse et qui naissent de la rencontre d'une boucle et d'un test. Le motif du compteur incrémente une variable à chaque tour, par exemple le nombre d'essais dans un jeu. Le motif du cumul ajoute chaque valeur à un total, par exemple la somme des notes d'un relevé. Le motif de recherche examine chaque élément et déclenche une action dès qu'une condition correspond, par exemple le premier prix supérieur à un budget. Ces trois schémas se retrouveront dans vos exercices, dans le chapitre sur les listes, puis dans le mini-projet final. Les maîtriser dès maintenant vous fait gagner un temps considérable : vous ne verrez plus des lignes de code, mais des structures que vous saurez reproduire.

- Les opérateurs de comparaison : `==` pour l'égalité, `!=` pour l'inégalité, `<`, `<=`, `>`, `>=` pour l'ordre, `in` pour tester l'appartenance à une séquence, `not in` pour son contraire.
- Les opérateurs logiques : `and` exige que les deux membres soient vrais, `or` exige qu'au moins un le soit, `not` inverse un test booléen.
- Les mots-clés de structure : `if` ouvre un test, `elif` ajoute un cas alternatif, `else` couvre le reste, `for` parcourt une séquence, `while` répète tant que la condition tient.
- Les mots-clés de flux : `break` interrompt la boucle en cours, `continue` passe au tour suivant, `else` peut aussi accompagner une boucle pour s'exécuter lorsque celle-ci va au bout.
- Le mot-clé `pass`, qui ne fait rien et sert uniquement à garder une structure syntaxiquement valide en attendant d'y placer du code.

- Choisissez `for` lorsque la répétition est finie et connue : un nombre fixe de tours ou une collection à parcourir.
- Choisissez `while` lorsque la durée est inconnue : une saisie à valider, une attente, un calcul conduit jusqu'à un seuil.
- Préférez `for` dans tous les cas où la liste des éléments est déjà disponible : le code en est plus court et plus sûr.
- Réservez `while` aux situations où c'est l'état du programme qui commande la poursuite, et non le contenu d'une collection.
- Dans tous les cas, vérifiez mentalement la fin de boucle avant de lancer le programme : savez-vous nommer l'événement qui l'arrêtera ?
$lesson$),
  ('py-c2-p2', 'py-c2', 2, $lesson$Les tests booléens : composer des conditions précises$lesson$, $lesson$
Tout commence par la comparaison. Python met à votre disposition six opérateurs qui comparent deux valeurs et renvoient un booléen : `==` teste l'égalité, `!=` teste l'inégalité, puis viennent `<`, `<=`, `>`, `>=` pour l'ordre. Le premier piège, rencontré par tous les débutants, est de confondre `==` et `=` : le signe `=` est l'affectation, celui qui écrit une valeur dans une variable, tandis que `==` est le comparateur qui pose la question « ces deux valeurs sont-elles égales ? ». Écrire `if x = 5` provoque une erreur de syntaxe en Python 3, et c'est une chance, car une version silencieuse aurait modifié votre variable au lieu de la tester. Une habitude utile consiste à lire à voix haute toute condition : « si x est égal à 5 », jamais « si x reçoit 5 ». Cette petite discipline linguistique élimine la grande majorité des confusions avant même que le programme ne s'exécute.

Les comparaisons fonctionnent sur presque tous les types que vous avez manipulés. Deux entiers se comparent par leur valeur numérique, deux nombres décimaux de la même manière, et deux chaînes de caractères par ordre alphabétique, ce qui permet d'affirmer que "abc" < "abd". Deux booléens se comparent également, même si cette situation est rare, puisque l'on préfère tester directement l'expression qui produit le booléen. Une précaution concerne les nombres décimaux : à cause de l'arrondi en virgule flottant, la comparaison d'une somme calculée avec des floats par une égalité stricte peut échouer alors que l'affichage semble identique. En pratique, on compare alors avec une tolérance, en vérifiant que l'écart entre les deux valeurs reste inférieur à un très petit seuil. Ce point détaillé ne vous servira qu'au fil des projets, mais il vaut mieux savoir dès maintenant que `==` sur des floats se manie avec prudence, et qu'un test d'égalité sur des montants en euros se formule préférentiellement en centimes, avec des entiers.

Les opérateurs logiques `and`, `or` et `not` permettent de combiner plusieurs tests en une seule condition. Avec `and`, l'ensemble n'est vrai que si les deux membres le sont ; avec `or`, il suffit qu'un seul le soit ; `not` inverse un test, transformant un vrai en faux et inversement. Python évalue les membres de gauche à droite et s'arrête dès que le résultat est certain : dans un `and`, dès qu'un membre est faux, l'autre n'est même pas examiné, et dans un `or`, dès qu'un membre est vrai, la recherche est terminée. Cette évaluation paresseuse a une conséquence pratique intéressante : vous pouvez enchaîner des tests en toute sécurité, par exemple vérifier qu'une liste n'est pas vide avant d'en demander le premier élément. Lorsque la logique se complique, n'hésitez pas à utiliser des parenthèses pour rendre votre intention explicite, même si la priorité des opérateurs suffit souvent : un code lisible vaut toujours mieux qu'un code malin.

L'opérateur `in` mérite une attention particulière, car il exprime l'appartenance de manière naturelle et très fidèle au français. `if "a" in mot` se lit « si a fait partie de mot », et la même syntaxe fonctionne sur les chaînes, les listes et, plus loin dans le parcours, tous les ensembles de données. Son contraire, `not in`, exprime l'absence : `if "secret" not in journal` se comprend sans un instant d'hésitation. Ce comparisonneur rend certains tests remarquablement concis : vérifier qu'un nom figure dans une liste d'autorisés, qu'un mot-clé apparaît dans une ligne de texte, ou qu'une extension appartient à une liste de formats acceptés. Il évite ainsi les enchaînements pénibles de `==` reliés par `or`, qui alourdissent le code et multiplient les occasions d'oublier un cas. Retenez toutefois qu'il teste l'appartenance exacte : "an" in "danse" renvoie True, alors que la recherche porte sur la sous-chaîne, pas sur un mot entier.

Une notion complémentaire vous sera utile dès les premiers tests : en dehors des expressions de comparaison, Python accepte n'importe quelle valeur dans un `if` et la juge selon sa vérité intrinsèque. Les valeurs numériques nulles, les chaînes vides et les séquences sans contenu sont considérées comme fausses, tandis que tout le reste passe pour vrai. Ainsi, `if texte:` signifie littéralement « si la chaîne n'est pas vide », et `if liste:` signifie « si la liste contient au moins un élément ». Cette écriture est plus courte et plus idiomatique que de comparer explicitement à une valeur vide, et vous la rencontrerez souvent dans du code existant. Il reste préférable d'être explicite lorsque la lecture pourrait prêter à confusion : si votre test porte sur un nombre qui peut légitimement valoir zéro, comparez-le à une variable booléenne nommée clairement plutôt que de parier sur le comportement implicite. Cette règle possède d'ailleurs un nom : on parle de valeur de vérité implicite. Elle est parfaitement standard en Python, vous la rencontrerez donc souvent dans le code des bibliothèques que vous utiliserez, et savoir la reconnaître vous évitera de chercher une comparaison qui n'existe pas dans un test pourtant correct.

- `stock = 12; if stock < 0 :` signale une rupture de stock, tandis que `if stock == 0 :` signale une rupture exacte et non un stock négatif.
- `if prix <= budget and livraison_offerte :` n'achète que si les deux exigences sont satisfaites simultanément.
- `if jour == "samedi" or jour == "dimanche" :` accepte deux jours, mais exige d'écrire chaque membre en entier.
- `if "mp3" in formats :` remplace avantageusement une série de comparaisons reliées par `or`.
- `if not est_connecte :` inverse le test et permet d'écrire le cas urgent en premier.
- `if villes:` teste la présence d'au moins un élément sans avoir à comparer à une liste vide.
$lesson$),
  ('py-c2-p3', 'py-c2', 3, $lesson$if, elif, else sans confusion$lesson$, $lesson$
Voici la structure complète telle qu'on la rencontre dans un programme réel. Le mot-clé `if` ouvre la structure, l'expression de test se termine par un deux-points, et chaque branche introduit un bloc indenté que Python n'exécute que si la condition correspondante est satisfaite. Le cas particulier se glisse dans `elif`, et le repli général dans `else`, aligné exactement sous le `if` initial. Trois détails méritent d'être fixés dès maintenant. Le deux-points n'est jamais facultatif : il commande le bloc qui suit et son absence provoque une erreur de syntaxe. La variable testée peut être n'importe laquelle, y compris le résultat d'une expression combinée plusieurs opérateurs. Enfin, chaque branche ne contient qu'un seul bloc, même s'il comporte dix instructions, et toute instruction placée après le dernier `else`, revenue à l'indentation de départ, s'exécute quoi qu'il arrive. Une bonne habitude consiste à relire la structure à voix haute en français en lançant : si aucun des cas ne convient, alors… Laissez la phrase ouverte un instant. Si elle ne mène nulle part, il manque un cas explicite ou un `else` ; si deux branches se terminent par la même phrase, c'est que deux conditions disent la même chose et que l'une d'elles est de trop. Cette relecture vérifie d'un coup que chaque branche exprime bien une situation distincte et compréhensible.

```python
age = int(input("Votre âge : "))
if age < 12:
    print("Tarif enfant")
elif age < 18:
    print("Tarif adolescent")
elif age < 60:
    print("Tarif adulte")
else:
    print("Tarif senior")
```

Chaque âge est examiné une seule fois : dès qu'une branche est choisie, Python ignore toutes les autres. Pour un visiteur de quinze ans, le premier test est faux, le second est vrai, et le programme affiche « Tarif adolescent » avant de sortir immédiatement de la structure, sans même examiner les conditions suivantes. C'est ce mécanisme de court-circuit qui rend elif si efficace : il exprime une succession de cas exclusifs sans jamais répéter le même contrôle. Notez au passage que `else` n'a aucune condition à évaluer : il représente par construction tout ce qui n'a pas été traité plus haut, ce qui garantit qu'au moins une branche sera exécutée, à condition bien sûr que la structure contienne un `if` initial. Lisez ensuite la structure comme une décomposition d'intervalle : le premier test attrape tout ce qui est inférieur à 12, le second tout ce qui reste entre 12 et 18, le troisième la tranche suivante, et `else` rattrape le surplus. Cette lecture en tranches est la clé pour vérifier qu'aucune valeur n'est oubliée et qu'aucune n'est traitée deux fois, ce qui se fait en imaginant deux ou trois cas concrets et en les faisant glisser mentalement dans la structure.

Les comparaisons de chaînes méritent une attention particulière, car elles respectent scrupuleusement la casse et les accents : « Python » et « python » sont deux valeurs différentes, et le test d'égalité renverra False alors que l'œil humain n'y voit qu'un seul mot. Pour comparer une saisie quel que soit la façon dont elle a été tapée, on normalise d'abord les deux côtés, par exemple en appliquant la méthode lower qui ramène tout en minuscules, ou la méthode upper qui met tout en majuscules. La même technique permet d'ignorer les espaces superflus grâce à la méthode strip, très pratique lorsque le texte vient du clavier. Ces transformations ne changent rien à la logique du test : elles garantissent seulement que la comparaison porte sur ce que vous vouliez réellement comparer, et non sur les détails de frappe. Attention toutefois à ne pas écraser la valeur d'origine si vous en avez besoin plus loin : créez plutôt une variable normalisée que vous comparez ensuite.

La première erreur de raisonnement concerne l'ordre des tests. Puisque Python s'arrête à la première branche vraie, une condition générale placée trop tôt dévore les cas particuliers destinés à suivre. Prenez ce bloc incorrect, où l'on veut distinguer les admis, les rattrapages possibles et les ajournés : si l'on teste d'abord `note >= 8`, un étudiant noté 15 satisfait ce test et se voit annoncer un rattrapage, alors qu'il était admis. La bonne écriture place les seuils les plus élevés en tête, ou formule les cas avec des intervalles explicites. Une méthode fiable consiste, avant même de coder, à écrire sur un papier chaque cas possible avec sa valeur de test, puis à les trier du plus restrictif au plus général. Vous obtenez ainsi l'ordre exact des branches, et vous évitez ce type de bug d'autant plus vicieux qu'il ne déclenche aucune erreur : le programme tourne, mais il répond faux.

```python
note = 15
if note >= 10:
    print("Admis")
elif note >= 8:
    print("Rattrapage possible")
else:
    print("Ajourné")
```

L'autre écueil classique est l'enchaînement de `if` indépendants là où il aurait fallu une seule structure alternative. Tester successivement `if age < 12`, puis `if age < 18`, puis `if age < 60` revient à évaluer plusieurs conditions pour un même sujet, sans garantie que le programme s'arrête après la première réponse, et avec le risque d'exécuter deux blocs incompatibles. Le remède est systématique : dès que deux ou trois tests portent sur la même variable et que leurs cas sont exclusifs, remplacez-les par `if`, `elif`, `else`. Python ne teste alors que ce qui reste à éclaircir, et le lecteur voit d'un coup d'œil qu'il s'agit d'une seule décision décomposée. La même logique s'applique aux imbrications : plutôt que d'entasser un `if` dans un `if`, ce qui décale l'indentation et noie le message principal, préférez une condition combinée avec `and` ou une structure elif linéaire. Un indice pour repérer ce défaut : dès que vous voyez le même nom de variable revenir dans plusieurs `if` écrits à la suite, la structure alternative est presque toujours la bonne réponse, car ces tests portent en réalité sur un seul et même sujet que vous avez découpé artificiellement en morceaux indépendants.

Il est également légitime de laisser une branche vide lorsque rien ne doit se passer. Si votre programme n'a d'action à déclencher que dans un cas, il suffit d'écrire le `if` et de reporter le bloc d'instructions plus loin dans le flux, à condition de conserver l'indentation correcte. En revanche, si la syntaxe exige absolument une instruction à cet emplacement, Python fournit le mot-clé `pass`, qui ne fait rien du tout et sert uniquement de marque-place. Préférez toutefois une formulation positive : regrouper les actions dans la branche utile et laisser l'autre vide est généralement plus clair qu'un `if` suivi d'un `else` vide. Enfin, pour les cas simples, l'expression conditionnelle de Python offre une écriture compacte, mais elle n'apporte rien à la compréhension quand la logique se complique : gardez les structures if, elif, else tant que votre décision comporte plus d'une dizaine de lignes. Un dernier réflexe utile : les tests négatifs se lisent souvent mieux que les tests positifs, et `if not est_valide` permet de traiter d'abord le cas qui bloque, puis de laisser la suite du programme dans sa version nominale, plus simple à relire.
$lesson$),
  ('py-c2-p4', 'py-c2', 4, $lesson$for et range : répéter un nombre fixe de fois$lesson$, $lesson$
La boucle for se lit simplement : pour chaque élément de la séquence, exécute le bloc. Sa syntaxe comporte trois parties indissociables : le mot-clé `for`, une variable qui reçoit successivement chaque valeur produite par la séquence, et le mot-clé `in` qui introduit cette séquence, le tout se terminant par un deux-points. Le bloc qui suit est indenté, exactement comme pour une condition, et c'est ce décalage à gauche qui marque la fin du tour. À chaque passage, Python fournit une nouvelle valeur à la variable de boucle, exécute le bloc, puis revient chercher la valeur suivante ; quand la séquence est épuisée, la boucle s'achève naturellement et le programme reprend la ligne qui la suit. Contrairement à ce que vous feriez dans d'autres langages, vous n'avez aucun compteur à déclarer, aucune incrémentation à écrire et aucune borne de fin à surveiller : la mécanique de progression appartient entièrement au langage, ce qui supprime d'un coup toute une famille d'erreurs classiques.

L'objet le plus courant à mettre après `in` est la fonction range, qui génère une séquence d'entiers consécutifs. Appelée avec un seul argument, range(n) produit les nombres de 0 à n - 1 inclus, soit exactement n valeurs. C'est ici que se cache le piège le plus fréquent du chapitre : range(3) ne contient pas 1, 2 et 3, mais bien 0, 1 et 2. La logique est celle d'un intervalle ouvert à droite : la borne de départ est comprise, la borne d'arrivée ne l'est pas. L'avantage de cette convention, que vous retrouverez avec les slices des listes au chapitre suivant, est de garantir que la longueur de la séquence vaut exactement le nombre demandé : range(5) contient cinq nombres, point final. Si vous voulez répéter trois fois l'affichage d'un message, écrivez donc `for i in range(3)`, et attendez-vous à voir le bloc s'exécuter trois fois, avec i valant successivement 0, 1 puis 2.

```python
for i in range(3):
    print("Tour numéro", i)
```

range accepte également trois paramètres : un point de départ, un point d'arrêt et un pas, sous la forme range(debut, fin, pas). La borne d'arrivée reste toujours exclue, ce qui demande un ajustement mental lorsque vous pensez « jusqu'à 10 inclus » : écrivez alors range(1, 11). Le pas peut être négatif, et c'est ainsi qu'on parcourt une plage en ordre décroissant : range(10, 0, -2) produit 10, 8, 6, 4, 2. Le pas peut aussi être supérieur à un pour sauter des valeurs, ou égal à zéro, ce qui déclenche une erreur puisque la séquence ne progresserait jamais. Prenez l'habitude de lire une telle séquence à voix haute : « de 1 jusqu'à 5 non compris, de 2 en 2 ». Ce petit exercice verbal suffit à faire coïncider ce que vous vouliez écrire et ce que Python comprendra, et il vous évite de corriger décalage après décalage un affichage qui ne démarre jamais au bon endroit.

```python
for i in range(1, 7):
    print(i, end=" ")
print()
for i in range(10, 0, -2):
    print(i, end=" ")
print()
```

Il arrive que vous souhaitiez répéter une action un certain nombre de fois sans vous intéresser au numéro du tour. Dans ce cas, il est d'usage d'utiliser le tiret bas comme variable de boucle : `for _ in range(5)`. Ce nom spécial n'a rien de magique, c'est simplement la convention universelle pour dire « cette valeur ne me sert à rien », et elle indique au lecteur que le compteur est volontairement ignoré. Vous l'utiliserez pour poser une pause artificielle, relancer une saisie un nombre limité de fois ou générer des données de test. À l'inverse, dès que le numéro du tour vous intéresse, gardez un nom explicite comme `i`, `numero` ou `tour`, et utilisez cette valeur dans le bloc : un compteur que l'on ne lit jamais n'a pas besoin d'exister, mais un compteur dont dépend le traitement doit porter un nom compréhensible. Une remarque analogue vaut pour la séquence parcourue : si elle porte un nom au pluriel comme notes ou prenoms, la variable de boucle doit évoquer un élément singulier, note ou prenom, et non reprendre le nom de la collection, ce qui laisserait entendre qu'on traite la liste entière à chaque tour.

La variable de boucle survit à la boucle : après l'exécution, elle conserve la dernière valeur reçue et reste accessible dans le reste du script. Ce comportement est utile lorsque vous voulez réutiliser le dernier indice, mais il devient dangereux si vous réutilisez ensuite ce nom pour un autre usage, car le lecteur du code ne saura plus s'il s'agit d'une valeur de boucle ou d'une variable métier. Préférez donc un nom réservé au déroulement, et un autre nom pour tout ce qui est calculé en dehors. Une seconde précaution concerne la collection parcourue : ne modifiez pas une liste pendant que vous la parcourez avec for, car les ajouts et suppressions déplacent les éléments sous les pieds de la boucle et produisent des résultats incomplets. Pour transformer ou filtrer un contenu, attendez la fin de la boucle, ou construisez une nouvelle liste à partir de l'ancienne, comme vous le verrez au chapitre sur les séquences.

Enfin, for sait parcourir bien plus que range. Toute séquence en Python peut lui être confiée : une chaîne de caractères fournit ses lettres une à une, une liste fournit ses éléments, un dictionnaire fournit ses clés. C'est cette polyvalence qui fait de for la boucle la plus fréquente du langage. Pour un nombre fixe de répétitions, range est la réponse ; pour un ensemble de données déjà constitué, la collection elle-même est la réponse. Dans les deux cas, la boucle reste la même : Python se charge de l'avancée, vous vous occupez du travail à faire à chaque étape. Retenez cette division des tâches, car elle vous évitera de recréer manuellement une mécanique que le langage vous offre gratuitement. Avant de conclure, testez votre compréhension avec un cas simple : afficher les nombres pairs de 1 à 10 demande soit un range assorti d'un pas de deux, soit un range complet assorti d'un test de parité, et les deux réponses sont justes. Le choix entre les deux dépend de ce qui se lit le plus naturellement dans votre code.

```table
Appel | Valeurs obtenues | Nombre d'itérations
--- | --- | ---
`range(n)` | `0` à `n - 1` | exactement `n`
`range(3)` | `0`, `1`, `2` | 3
`range(5)` | `0` à `4` | 5
`range(1, 11)` | `1` à `10` | 10
`range(10, 0, -2)` | `10`, `8`, `6`, `4`, `2` | 5
```
$lesson$),
  ('py-c2-p5', 'py-c2', 5, $lesson$Parcourir des données : listes, chaînes et dictionnaires$lesson$, $lesson$
Lorsqu'une collection de valeurs existe déjà, la boucle for la parcourt directement, sans index ni calcul de longueur. La variable de boucle reçoit successivement chaque élément, exactement comme le ferait un relecteur qui feuillette une liste de noms. Cette écriture est non seulement la plus courte, mais aussi la plus sûre : il est impossible de dépasser les bornes de la collection, d'oublier un élément ou de se tromper d'indice, puisque c'est Python qui décide de l'ordre et du nombre de tours. Elle correspond au geste mental que vous faites spontanément : pour chaque note du relevé, additionne-la ; pour chaque prénom de la liste, affiche-le. Traduire cette phrase française en code devient alors presque mécanique, ce qui réduit drastiquement les erreurs de logique. La seule limite de cette approche est que vous ne connaissez pas la position de l'élément traité : si vous avez besoin de son numéro, il faudra un dispositif complémentaire, et c'est précisément le sujet du chapitre suivant sur les séquences.

```python
notes = [12, 15, 9, 18, 13]
total = 0
for note in notes:
    total = total + note
print("Moyenne :", total / len(notes))
```

Ce bloc illustre le motif du cumul, l'un des trois schémas qui reviennent sans exception dans tous les programmes. On initialise un total avant la boucle, hors du bloc, afin qu'il existe avant le premier tour ; on l'augmente ensuite à chaque passage, en ajoutant la valeur courante ; enfin, après la boucle, on exploite le résultat. L'ordre des trois étapes est crucial : si vous créez le total à l'intérieur de la boucle, il repart de zéro à chaque tour et seul le dernier élément subsiste. Ce type d'erreur produit un résultat plausible mais faux, donc particulièrement difficile à repérer à l'œil nu. Le même schéma sert à compter les éléments qui satisfont un critère, en additionnant 1 au lieu de la valeur, ou à retenir le maximum, en comparant à chaque tour le meilleur score trouvé jusque-là. Ces trois variantes, cumul, compteur et maximum, constituent la grammaire de base de tout traitement de données.

Les chaînes de caractères se parcourent de la même manière : chaque tour fournit un caractère, de gauche à droite. C'est la structure idéale pour examiner un mot lettre par lettre, compter les voyelles, rechercher un caractère interdit ou afficher un mot à l'envers en accumulant les lettres dans un ordre inversé. Attention toutefois à ne pas confondre la chaîne elle-même et la liste de ses caractères : la boucle lit les lettres, mais la variable d'origine reste intacte. Si vous devez transformer le contenu, construisez une nouvelle chaîne à partir de ce que vous accumulez. Cette distinction entre parcourir et modifier est un réflexe à acquérir dès maintenant : la boucle est un outil de lecture et de décision, tandis que la production d'un nouveau résultat passe par une variable de résultat que vous alimentez tour après tour. Une variante fréquente consiste à afficher un compteur à côté de chaque lettre, mais cela exigerait de connaître la position, que la boucle ne fournit pas : pour l'instant, contentez-vous du parcours simple, et sachez seulement que la position sera disponible au chapitre suivant, lorsque vous aborderez les techniques d'indexation des séquences.

```python
mot = "python"
for lettre in mot:
    print(lettre)
```

Les dictionnaires, enfin, se parcourent en livrant leurs clés, et non leurs valeurs. Pour un dictionnaire d'étudiant contenant les clés nom, ville et groupe, une boucle `for cle in etudiant` produira successivement ces trois chaînes ; la valeur associée s'obtient alors par accès avec les crochets, `etudiant[cle]`. Cette particularité surprend souvent au début, parce que l'on s'attend naturellement à recevoir des paires clé-valeur. Python propose bien d'autres formes, notamment une méthode qui livre les deux à la fois, mais nous les détaillerons intégralement au chapitre consacré aux conteneurs, où vous verrez aussi comment trier les clés ou ne parcourir qu'un sous-ensemble. Pour l'instant, retenez la règle simple : parcourir un dictionnaire avec for, c'est parcourir son index, et la valeur se demande ensuite explicitement. Si l'ordre des clés vous intéresse, sachez qu'il est celui de l'insertion dans la version actuelle du langage, mais que rien ne vous interdit de trier les clés avant de les parcourir, auquel cas l'affichage suit l'ordre alphabétique. Ces raffinements attendent le chapitre sur les conteneurs ; notez seulement dès maintenant que la valeur ne vient jamais toute seule et qu'elle s'obtient toujours par une requête explicite.

```table
Structure | Création | Itération | Accès et méthode clé
--- | --- | --- | ---
Liste | `notes = [12, 15, 9, 18, 13]` | `for note in notes:` reçoit chaque élément | longueur avec `len(notes)`, sans index
Chaîne | `mot = "python"` | `for lettre in mot:` livre une lettre par tour | la position n'est pas fournie et la chaîne reste intacte
Dictionnaire | clés `nom`, `ville` et `groupe` | `for cle in etudiant` livre les clés | `etudiant[cle]` donne la valeur associée
```

La dernière grande utilisation de for consiste à répéter une action pour chaque élément d'une collection affichée, comme dans un catalogue. On construit une liste de prix, puis on affiche chacun avec un libellé, en laissant la boucle gérer la progression. Ce motif devient puissant dès que l'affichage dépend d'une condition : si le prix dépasse un budget, on l'annonce, sinon on le passe. Vous retrouverez cette combinaison, boucle plus test, dans presque tous les exercices du parcours, de la vérification d'un inventaire jusqu'à l'analyse d'un relevé de notes du projet final. Le réflexe à prendre est le suivant : repérez d'abord ce qui se répète, cherchez la collection sur laquelle porter la répétition, puis ajoutez le test à l'intérieur du bloc. Cette ordonnance des étapes vous fait gagner un temps considérable, car elle transforme un problème de programme en simple question de structure. Prenez un instant pour formuler votre cas en français avant d'écrire la moindre ligne : « pour chaque prix du panier, si le prix dépasse le budget, signale-le ». Vous obtenez ainsi le nom de la collection, le travail commun à tous les éléments et le test particulier, ce qui suffit généralement à faire apparaître la structure complète sans autre réflexion.
$lesson$),
  ('py-c2-p6', 'py-c2', 6, $lesson$while : répéter tant que la condition tient$lesson$, $lesson$
La boucle while se présente comme la plus directe des deux : elle place une expression booléenne après son mot-clé, et répète son bloc tant que cette expression vaut True. Dès qu'elle devient False, la boucle se ferme et le programme reprend sa marche. Cette mécanique en fait l'outil des situations dont la durée n'est pas connue à l'avance, puisque vous ne pouvez pas écrire range si vous ignorez combien de tours seront nécessaires. Le cas typique est l'attente : demander une saisie jusqu'à obtenir une valeur correcte, relancer une connexion tant qu'elle échoue, ajouter des crédits tant que le solde est insuffisant, ou poursuivre un calcul jusqu'à ce que la différence entre deux approximations devienne négligeable. Dans tous ces cas, ce n'est pas une collection qui commande la répétition, c'est l'état du programme. C'est cette nuance qui doit guider votre choix : si vous pouvez nommer la liste des éléments à traiter, préférez for ; si c'est une condition de fin que vous surveillez, utilisez while.

```python
reponse = -1
essais = 0
while reponse != 42:
    reponse = int(input("Votre proposition : "))
    essais = essais + 1
print("Trouvé en", essais, "essais")
```

Le secret d'une boucle while correcte tient en une seule règle : la condition de sortie doit évoluer à chaque tour. Quelque chose dans le bloc doit modifier la situation de manière à rapprocher la condition de sa valeur d'arrêt. Dans l'exemple précédent, chaque saisie remplace la valeur de reponse, et c'est précisément cette réaffectation qui permet, un jour ou l'autre, que la condition devienne fausse. Si vous oubliez cette mise à jour, la condition ne change jamais, le verdict identique se répète à l'infini et le programme cesse de répondre, jusqu'à ce que vous l'interrompiez avec la combinaison de touches appropriée à votre système. Ce défaut, appelé boucle infinie, est de loin l'erreur la plus fréquente des débutants avec while, et il est toujours imputable à la même cause : la condition est vérifiée, mais rien ne la fait changer. Toute boucle while se décompose donc en trois temps qu'il faut vérifier dans l'ordre : l'état initial qui rend la condition vraie, le travail effectué pendant le tour, et la modification qui rapproche l'état de la sortie. Si l'un des trois manque, la boucle est incorrecte, même si elle semble fonctionner sur les premiers tours.

```python
compteur = 1
while compteur <= 5:
    print("Tour numéro", compteur)
    compteur = compteur + 1
```

Lorsque vous voulez répéter un nombre fixe de fois avec while, la structure se décompose toujours en trois pièces à écrire dans cet ordre. Une variable de compteur est initialisée avant la boucle ; la condition compare ce compteur à la borne d'arrivée ; le bloc contient le travail et, en dernier, l'incrémentation du compteur. Oublier l'une des trois casse la boucle : sans initialisation, la variable n'existe pas et Python lève une erreur ; sans incrémentation, la boucle tourne à l'infini ; sans borne, la condition reste vraie indéfiniment. Cette mécanique manuelle explique d'ailleurs pourquoi for est préférée dès que la séquence est connue : elle exécute exactement les trois étapes pour vous, sans qu'aucune ne puisse être oubliée. Comparez les deux écritures, elles produisent le même résultat, mais l'une laisse trois occasions de se tromper. Le choix devient alors un choix de clarté, et non une contrainte technique : for dit « je parcours une liste de choses », while dit « je continue tant que l'état ne convient pas ». Dès que cette distinction est claire, la lecture d'un programme devient immédiatement plus aisée.

Il existe pourtant une forme de while qui n'a pas de condition de sortie dans sa tête de ligne : la boucle `while True`. Elle paraît contradictoire, et pourtant elle est légitime lorsqu'elle est associée à un break qui interrompt le corps du bloc dès qu'un événement se produit. On l'emploie notamment pour des menus, où l'on propose des choix tant que l'utilisateur n'a pas demandé de quitter, ou pour des saisies dont le format valide est difficile à exprimer en une seule expression. La sécurité de la boucle repose alors entièrement sur la présence et la position du break : s'il devient inaccessible, la boucle redevient infinie. C'est pourquoi cette écriture doit rester l'exception, toujours accompagnée d'un `break` facile à repérer et d'un commentaire qui nomme l'événement attendu. Pour les traitements de données, la version explicite avec une condition lisible reste préférable, car le lecteur identifie immédiatement l'événement qui mettra fin au travail. Dans les deux cas, gardez à l'esprit que la boucle infinie n'est pas une fatalité ni un bug mystérieux : c'est toujours une condition qui n'atteint jamais sa valeur de sortie, et le débogage consiste donc à relever les valeurs de cette condition tour après tour jusqu'à apercevoir le moment où elle aurait dû basculer.

Une dernière précaution concerne la logique de fin de boucle. Vérifiez mentalement votre while avant de lancer l'exécution, en répondant à deux questions : dans quel état le programme entre-t-il dans la boucle, et quel événement précis l'en fera sortir ? Si la seconde question n'a pas de réponse nette, le code n'est pas prêt. Un réflexe efficace consiste à simuler le premier tour à la main sur papier, en suivant les valeurs des variables, puis à imaginer le dernier tour possible. Si vous ne parvenez pas à décrire ce dernier tour, c'est que la condition de sortie dépend d'une variable que rien ne modifie. Cette vérification de quelques secondes vous épargne les sessions de débogage interminables où l'on regarde un programme s'afficher sans fin, faute d'avoir posé la question de sa fin dès l'écriture. Pour les boucles dont le fonctionnement n'est pas évident, affichez la valeur de la condition de sortie à chaque tour : voir la variable évoluer, ou constater au contraire qu'elle ne bouge pas, suffit le plus souvent à révéler le défaut en quelques secondes.

Un autre usage très répandu de while consiste à valider une saisie, c'est-à-dire à redemander une information tant qu'elle n'est pas exploitable. La structure reste identique : on lit une première valeur avant la boucle, on la teste, et lorsqu'elle ne convient pas, on la relit à l'intérieur du bloc, ce qui met à jour la condition de sortie. Le programme ci-dessous insiste jusqu'à obtenir une chaîne réellement composée de chiffres, puis convertit cette chaîne validée en entier. Cette fois, la boucle ne dépend ni d'une collection ni d'un compteur : elle dépend uniquement du format de la réponse, dont on ne peut pas prédire le nombre d'essais. Vous noterez que la condition est écrite sous sa forme négative, ce qui signifie qu'on répète tant que la saisie reste invalide, et que la conversion int n'intervient qu'une fois la sortie garantie, puisqu'elle échouerait sur une chaîne non numérique. Si le joueur tape une lettre, l'exécution s'interrompt sur une erreur : vous verrez au chapitre sur les exceptions comment prévenir ce cas sans alourdir la boucle.

```python
reponse = input("Entrez un nombre entre 1 et 50 : ")
while not reponse.isdigit():
    print("Saisie invalide, recommencez.")
    reponse = input("Entrez un nombre entre 1 et 50 : ")
valeur = int(reponse)
print("Vous avez saisi", valeur)
```
$lesson$),
  ('py-c2-p7', 'py-c2', 7, $lesson$break et continue : garder la main sur le flux$lesson$, $lesson$
L'instruction `break` sort immédiatement de la boucle la plus proche, sans attendre que la condition de fin soit réunie. Elle exprime une découverte : l'objet recherché a été trouvé, une limite a été franchie, une situation critique impose l'arrêt. Le bloc qui suit break dans la boucle n'est pas exécuté pour ce tour, et le programme reprend la première instruction située après la boucle. C'est le comportement attendu d'une recherche : parcourir des éléments un par un et cesser dès la correspondance, plutôt que de continuer à examiner inutilement tout le reste de la collection. Cette sortie anticipée est aussi une question d'efficacité, mais surtout une question de clarté : elle dit au lecteur que la boucle a accompli son objectif avant l'épuisement de la séquence. Une recherche interrompue trop tôt reste dangereuse si l'on oublie de vérifier le résultat : après la boucle, contrôlez toujours que la variable contient réellement une valeur trouvée, et non celle qu'elle portait avant le parcours, faute de quoi un échec passerait pour un succès.

```python
prenoms = ["Ali", "Bea", "Carla", "Damien"]
for prenom in prenoms:
    if prenom == "Carla":
        break
    print(prenom)
```

Exécuté, ce bloc affiche Ali puis Bea et s'arrête : Carla déclenche la sortie avant son affichage, et Damien n'est jamais atteint. C'est exactement le comportement recherché lorsqu'on cherche un élément dans une liste ou qu'on scanne un fichier ligne à ligne jusqu'à trouver un marqueur. Notez que break ne touche qu'à la boucle immédiatement englobante : si vos boucles sont imbriquées, seule la plus interne se ferme, ce qui oblige à une vigilance particulière lorsque vous ajoutez un break dans une structure à plusieurs niveaux. Dans ce cas de figure, une fonction de traitement, que vous découvrirez au chapitre suivant, offre souvent une solution plus lisible qu'un empilement de sorties conditionnelles. Un autre piège consiste à placer le break dans une branche sans rapport avec l'objectif de la boucle : la sortie se produit alors pour une raison inattendue. Relisez la condition qui déclenche l'interruption et demandez-vous si elle exprime vraiment la fin logique du traitement, ou si elle ne capte qu'un accident de parcours.

L'instruction `continue`, elle, ne met pas fin à la boucle : elle saute directement à la fin du tour en cours et lance le suivant. Tout ce qui est écrit après continue dans le bloc est ignoré pour l'élément traité. Son usage typique est l'exclusion d'un cas particulier : on examine chaque note d'un relevé et l'on passe à la suivante dès qu'elle est négative, avant de l'ajouter au total. Sans continue, il faudrait envelopper tout le reste du bloc dans un if de sens opposé, ce qui ajoute un niveau d'indentation et décale l'ensemble du traitement. Attention cependant à ne pas inverser la logique : si vous placez continue dans le cas courant plutôt que dans le cas d'exception, vous risquez d'exécuter le traitement une fois sur deux sans vous en apercevoir, car le programme continue de fonctionner et produit des résultats partiels. Si votre boucle a pour rôle de filtrer des éléments, relisez ensuite le corps du bloc et vérifiez qu'aucune instruction ne peut s'exécuter à la fois dans le cas courant et dans le cas d'exception.

```python
notes = [12, -3, 15, 0, 9]
total = 0
for note in notes:
    if note < 0:
        continue
    total = total + note
print("Somme des notes valides :", total)
```

La discipline d'usage se résume à une idée : break et continue sont des exceptions, pas des outils de structure. Utilisés avec parcimonie, ils raccourcissent le code et en facilitent la lecture ; abusés, ils multiplient les chemins possibles et rendent le flux difficile à suivre, car le lecteur doit désormais deviner à quel endroit exact la boucle s'interrompt ou saute une étape. Une bonne mesure consiste à n'autoriser qu'une sortie anticipée par boucle, placée le plus près possible de sa condition logique. Si vous découvrez que votre boucle comporte plusieurs break dispersés, c'est souvent le signe que la décision pourrait être reformulée en une condition unique, ou extraite dans une fonction dédiée. Relisez votre code à froid quelques heures après l'avoir écrit : si le trajet du contrôle vous paraît confus, réécrivez-le maintenant plutôt que de le corriger plus tard en pleine panique. Le même réflexe s'applique aux conditions : une expression que vous relisez deux fois sans en être sûr mérite d'être remplacée par une variable intermédiaire nommée, ce qui coûte une ligne et vous fait gagner une relecture.
$lesson$),
  ('py-c2-p8', 'py-c2', 8, $lesson$Structurer un flux lisible et robuste$lesson$, $lesson$
Choisir entre for et while n'est qu'une première décision ; la seconde consiste à organiser le code pour qu'il se lise comme une explication. Un programme clair suit l'ordre naturel du raisonnement : on prépare les données, on déroule la répétition, on prend les décisions à l'intérieur, puis on exploite le résultat. Cette séparation se matérialise par la placement des initialisations avant la boucle et des traitements finaux après elle. Le lecteur qui découvre votre code doit pouvoir identifier en un coup d'œil trois zones : ce qui est préparé, ce qui tourne, ce qui est conclu. Plus cette frontière est nette, plus le débogage devient simple, car une valeur fausse se situe immédiatement dans l'une des trois. À l'inverse, mélanger initialisation, calcul et affichage au sein du même bloc oblige à relire tout le programme pour comprendre d'où vient un chiffre. Surveillez aussi les blocs trop longs : une boucle qui remplit plus d'un écran de ligne gagnerait à être découpée, et vous verrez au chapitre suivant comment extraire son corps dans une fonction pour le relire comme un algorithme autonome.

L'imbrication est le principal ennemi de cette lisibilité. Une condition à l'intérieur d'une boucle, elle-même à l'intérieur d'une autre condition, produit des blocs de plus en plus décalés vers la droite et une largeur de code qui devient difficile à afficher. Deux remèdes existent. Le premier consiste à reformuler les tests avec les opérateurs logiques, afin de supprimer un niveau d'indentation sans changer le sens. Le second, plus puissant, consiste à sortir une partie du traitement dans une fonction séparée, ce qui réduit la boucle à une seule ligne d'appel ; c'est la technique que vous explorerez intégralement au chapitre 3. En attendant, appliquez une limite simple : au-delà de trois niveaux d'indentation, arrêtez-vous et cherchez comment aplatir la structure, car l'œil humain cesse alors de suivre la logique avec fiabilité. Une imbrication profonde signale presque toujours qu'une décision mérite son propre nom : reformulez-la, et la structure se révélera souvent plus simple que son décalage ne le laissait penser.

Une dernière bonne pratique porte sur la nommage. Les variables de boucle, les compteurs et les indicateurs d'état sont lus et relus plus souvent que tout le reste du code : nommez-les pour ce qu'elles signifient et non pour ce qu'elles contiennent. `compteur_essais` se comprend sans contexte, alors que `c` impose une relecture du bloc pour deviner son rôle. De même, une variable booléenne qui porte un nom explicite, comme `trouve` ou `est_valide`, transforme une condition opaque en phrase compréhensible. Cette attention au vocabulaire n'est pas cosmétique : elle réduit les erreurs d'inversion, elle aide les relecteurs et votre futur vous-même, et elle rend les bugs de logique bien plus visibles, puisque le code faux devient immédiatement bizarre à lire. Un programme qui se lit facilement est un programme qui se corrige vite. Pensez-y la prochaine fois que vous hésiterez entre deux noms possibles : le nom le plus long est presque toujours celui qui vous fera gagner du temps lors de la relecture.
$lesson$),
  ('py-c2-p9', 'py-c2', 9, $lesson$Exemple guidé : le jeu devinez le nombre$lesson$, $lesson$
L'idée du jeu tient en une phrase : l'ordinateur choisit un nombre entier compris entre 1 et 50, vous proposez le vôtre, et à chaque essai il vous indique s'il faut monter ou descendre, jusqu'à ce que vous ayez trouvé. Tout repose sur une boucle à durée inconnue, puisque le nombre d'essais dépend de votre méthode, et sur une décision à trois branches à chaque tour. Le programme complet tient en quelques lignes : il génère le nombre secret, initialise le compteur d'essais, puis entre dans une boucle qui redemande une proposition tant que la bonne n'a pas été donnée. La sortie de la boucle correspond exactement au moment de la réussite, ce qui fait du bilan final l'endroit naturel pour afficher le score. Cet exemple concentre toutes les notions du chapitre : une condition composée avec les opérateurs de comparaison, une alternative à plusieurs branches, une boucle while, et une sortie anticipée avec break.

```python
import random

nombre_secret = random.randint(1, 50)
essais = 0

print("Je pense à un nombre compris entre 1 et 50.")

while True:
    proposition = int(input("Votre proposition : "))
    essais = essais + 1
    if proposition == nombre_secret:
        break
    if proposition < nombre_secret:
        print("Plus !")
    else:
        print("Moins !")

print("Bravo ! Vous avez trouvé en", essais, "essais.")
```

La première ligne importe le module random, qui fournit des fonctions de génération de nombres pseudo-aléatoires ; la fonction randint produit un entier compris dans les deux bornes, celles-ci étant incluses des deux côtés. Vous découvrirez les modules au chapitre 7, mais leur utilisation ici se limite à un appel : tant que vous savez ce que la fonction renvoie, vous pouvez l'utiliser sans en connaître le mécanisme interne. Le nombre obtenu est stocké dans une variable nommée clairement, ce qui donne à tout le reste du programme une référence stable. Notez que le nombre secret est tiré une seule fois, avant la boucle : s'il était tiré à l'intérieur du bloc, chaque essai affronterait un nouveau nombre et le jeu serait impossible à gagner. Ce déplacement de l'initialisation hors de la boucle est l'une des décisions structurantes du programme. Si vous souhaitez offrir la possibilité de rejouer, cette génération redeviendra alors le premier pas d'une boucle extérieure, et vous verrez que le même principe s'applique à un niveau supérieur.

Le compteur d'essais est initialisé à zéro exactement au même endroit, pour une raison symétrique : il doit exister avant le premier tour et persister d'un tour à l'autre. Si vous le créiez à l'intérieur de la boucle, il repartirait de zéro à chaque proposition et l'affichage final annoncerait systématiquement un essai. L'incrémentation se fait dès la saisie, avant la comparaison, afin que toute proposition validée soit comptée, y compris la bonne. Ce choix évite de devoir ajouter un essai supplémentaire après la sortie de boucle, ce qui serait facile à oublier. Vous l'aurez reconnu : il s'agit du motif compteur vu plus haut, avec une variable de résultat qui s'accumule pendant la répétition et qui n'est lue qu'une fois, à la toute fin. Si le joueur ne parvient jamais à trouver, cette variable devient le seul indicateur de performance du programme : elle permet de comparer des stratégies et, plus tard, de fixer un nombre maximal d'essais.

La boucle while True peut surprendre, puisqu'elle ne teste rien. Elle signifie en réalité : travaille tant que le programme ne t'a pas dit d'arrêter, et cet ordre est donné par le break placé au cœur du bloc. Tant que la proposition est fausse, le break n'est jamais atteint, l'indication « Plus ! » ou « Moins ! » s'affiche, et un nouveau tour commence. Dès que la proposition correspond au nombre secret, le break interrompt immédiatement la boucle : les instructions situées après lui dans le bloc sont ignorées, et le programme se rend directement à la ligne d'affichage du bilan. Cette structure est idéale ici, car la condition de fin, une égalité sur une saisie, se formule plus naturellement à l'intérieur du corps qu'en tête de boucle. Elle reste encadrée : la sortie est explicite, unique, et placée au moment exact où l'objectif est atteint. Une alternative consisterait à écrire la condition dans l'en-tête de la boucle, mais elle deviendrait alors plus longue et moins lisible qu'un simple test d'égalité posé au cœur du corps.

Le cœur de la décision est la séquence de tests qui suit la saisie : un if d'égalité, puis un couple if, else pour les deux cas d'ordre. Le premier test cherche l'égalité exacte et déclenche la sortie ; il est placé en tête parce que c'est le cas le plus important, celui qui termine le jeu. Le second teste la proposition inférieure au secret et annonce « Plus ! » ; le else capte tous les cas restants, c'est-à-dire les propositions supérieures. Toutes les branches sont exclusives, donc l'ordre des deux dernières est ici indifférent, mais l'habitude de commencer par le cas terminal vous servira dans tous les jeux et tous les validateurs de saisie. Remarquez enfin l'asymétrie volontaire : la comparaison d'égalité ouvre son propre if, tandis que les deux comparaisons d'ordre partagent un if, else, parce qu'elles constituent une seule alternative. Si vous retirez le premier if, plus rien n'interrompt la boucle : dès que le joueur propose le bon nombre, le programme annonce « Moins ! » puis tourne à l'infini, ce qui illustre concrètement l'importance de la sortie anticipée et du court-circuit qui suit chaque branche.

La saisie elle-même mérite une observation. input renvoie toujours une chaîne de caractères, et comparer une chaîne à un entier avec == produirait systématiquement False, ce qui rendrait le jeu interminable : la conversion int avant la comparaison est donc indispensable. Elle introduit toutefois un risque nouveau, une saisie non numérique déclenchant une erreur d'exécution, et la gestion de ce cas précis fait l'objet du chapitre sur les exceptions. En attendant, le programme suppose que le joueur respecte les consignes, ce qui est raisonnable pour un premier exemple. Après la boucle, le bilan utilise essais, variable restée vivante grâce à sa position hors du bloc, pour annoncer le score final. Cette place vaut pour tout message de conclusion : l'afficher après la boucle évite d'interrompre le jeu avec un bilan prématuré, et l'on retrouve le principe énoncé plus haut, le corps de la boucle se charge du travail répété pendant que les conclusions se tirent à sa sortie.

Deux variantes vous permettront de consolider le raisonnement. La première remplace le break par un indicateur booléen, une variable trouve initialisée à False, mise à True lorsque la réponse est juste, et testée dans la condition de la boucle : le programme fonctionne à l'identique, mais la fin de boucle devient explicite dans l'en-tête. La deuxième ajoute un plafond d'essais, par exemple un maximum de dix tentatives, en complétant la condition de sortie ; le jeu se termine alors aussi en cas d'échec, et il faut prévoir une seconde décision après la boucle pour distinguer victoire et défaite. Ces deux pistes constituent d'excellents entraînements avant de passer à l'exercice pratique : elles ne demandent aucune notion nouvelle, seulement la réorganisation de celles que vous maîtrisez maintenant. Commencez par la première : elle vous fera toucher du doigt la différence entre une fin annoncée dans l'en-tête de la boucle et une fin déclenchée au milieu du corps, qui sont les deux grandes familles de sorties que vous rencontrerez dans tous les programmes.

- Pour rejouer, placez la génération du nombre secret dans une boucle extérieure et réinitialisez le compteur à chaque partie.
- Pour encadrer la saisie, testez que la proposition reste bien entre 1 et 50 avant de lancer la comparaison, sinon le joueur peut gagner en une tentative illégitime.
- Pour afficher la progression, conservez les propositions dans une liste et affichez-les à la fin, ce que vous saurez faire avec les listes du chapitre 4.
- Pour mesurer la difficulté, comparez le nombre d'essais avec la stratégie de dichotomie, qui divise l'intervalle à chaque proposition et garantit la trouvaille en moins de six essais.
$lesson$),
  ('py-c2-p10', 'py-c2', 10, $lesson$À retenir$lesson$, $lesson$
- Une condition produit toujours un booléen, True ou False, et `if` n'exécute son bloc que si ce booléen vaut True.
- `elif` ajoute des cas alternatifs, `else` couvre tout ce qui reste ; les deux sont facultatifs et `else` ferme toujours la structure.
- Python évalue les branches dans l'ordre et s'arrête à la première vraie : placez les cas les plus restrictifs en premier.
- L'indentation de quatre espaces délimite le bloc, et `else` s'aligne exactement sous le `if` auquel il répond.
- `==` compare, `=` affecte : dans un test, utilisez toujours le double égal.
- `and`, `or` et `not` combinent les tests ; `in` et `not in` vérifient l'appartenance à une séquence.
- La boucle `for` parcourt une séquence connue et gère elle-même l'avancée, ce qui évite tout travail de compteur manuel.
- `range(n)` produit 0, 1, 2 jusqu'à n - 1, soit exactement n valeurs ; `range(a, b)` exclut toujours b.
- La boucle `while` répète tant que sa condition reste vraie et impose une mise à jour à chaque tour.
- Sans évolution de la condition de sortie, `while` devient une boucle infinie ; `while True` n'est sûr que s'il contient un `break`.
- `break` interrompt la boucle en cours, `continue` saute au tour suivant : réservez-les aux cas justifiés.
- Cumuler, compter et retenir le maximum sont les trois motifs qui reviennent dans presque tous les traitements de données.
$lesson$),
  ('py-c2-p11', 'py-c2', 11, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Affectation au lieu de comparaison, `if x = 5` → écrivez `if x == 5` ; le signe unique modifie la variable au lieu de la tester, et Python 3 signale l'erreur.
- Oubli de mise à jour dans `while`, `while compteur <= 5` sans incrémentation → ajoutez `compteur = compteur + 1` à la fin du bloc, sinon la condition ne change jamais et la boucle tourne à l'infini.
- Indentation absente ou hétérogène → indentez le bloc de quatre espaces et alignez `else` sous son `if` ; mélanger tabulations et espaces provoque des erreurs de syntaxe.
- Limite de `range` incluse par erreur → retenez que la borne d'arrivée est exclue : pour inclure 3, écrivez `range(1, 4)` et non `range(1, 3)`.
- Départ de `range` supposé à 1 → `range(3)` vaut 0, 1, 2 ; si vous voulez afficher des numéros à partir de 1, utilisez `range(1, 4)`.
- Compteur de résultat créé dans la boucle → initialisez `total = 0` avant le `for`, sinon la variable repart à zéro à chaque tour et seul le dernier élément est retenu.
- Plusieurs `if` successifs sur la même variable → remplacez-les par `if`, `elif`, `else` pour ne tester que ce qui reste et éviter d'exécuter deux branches incompatibles.
- `break` placé dans une boucle imbriquée → il ne ferme que la boucle la plus interne ; extrayez le traitement dans une fonction ou reformulez la condition de sortie.
$lesson$),
  ('py-c2-p12', 'py-c2', 12, $lesson$Pour aller plus loin$lesson$, $lesson$
Les tutoriels officiels de Python consacrent un chapitre complet au flux de contrôle : c'est l'endroit idéal pour revoir côte à côte les conditions, les boucles et les instructions de saut, avec les exemples de syntaxe de référence. L'adresse est https://docs.python.org/fr/3/tutorial/controlflow.html et vous y retrouverez notamment la documentation de range et les formes avancées des boucles. Le tutoriel contient également des sections sur les boucles imbriquées, sur l'instruction pass et sur la façon dont un bloc peut rester vide sans être invalide, des détails qui complètent utilement ce cours lorsque votre code se compliquera. Pour les définitions exactes, la grammaire des instructions composées et les règles d'évaluation, la référence du langage reste la source la plus précise, à lire quand vous voulez lever un doute : https://docs.python.org/fr/3/reference/compound_stmts.html. Enfin, la page de référence des fonctions intégrées, https://docs.python.org/fr/3/library/functions.html, décrit range et les fonctions de conversion comme int et len, que vous utiliserez constamment dans vos conditions et vos boucles.

Un conseil de méthode plutôt qu'une liste de lecture : revenez sur ces pages après avoir codé, et non avant. Effectuez d'abord l'exercice pratique avec vos seules notes de cours, puis confrontez votre solution à la documentation pour vérifier que vous avez bien choisi la boucle, correctement délimité l'intervalle de range et garanti la sortie de votre while. Cette alternance entre pratique et référence consolide la mémorisation bien plus efficacement qu'une lecture linéaire, et elle vous habitue à utiliser la documentation comme un outil de travail quotidien, ce qui est la compétence la plus rentable à long terme. Si vous ne deviez en retenir qu'une seule, choisissez celle-ci : commencez par le cas d'usage dans le tutoriel, poursuivez dans la référence pour la forme exacte, et surtout n'apprenez pas les syntaxes par cœur, apprenez plutôt à retrouver le bon endroit en moins d'une minute. Cette discipline vous évitera de mémoriser des pages entières que vous ne relirez plus une fois le projet terminé.
$lesson$),
  ('py-c2-p13', 'py-c2', 13, $lesson$Et maintenant : la vidéo du chapitre$lesson$, $lesson$
La vidéo du chapitre reprend ces mêmes notions pas à pas, en montrant à l'écran l'exécution ligne à ligne d'une condition puis d'une boucle, jusqu'à la construction complète du jeu devinez le nombre ; elle prolonge ainsi la leçon que vous venez de lire, avec la possibilité de suivre le code en direct et de voir les erreurs se produire puis se corriger. Le geste le plus utile reste de reproduire le code sur votre machine plutôt que de le regarder défiler : tapez les lignes une à une, cassez volontairement une condition pour observer le comportement défectueux, puis rétablissez-la et constatez le retour à la normale. Une fois cette étape franchie, l'exercice pratique vous met en application : vous coderez votre propre version du jeu, en choisissant vos variables, votre structure de boucle et votre façon de sortir, avant de passer au quiz du chapitre qui valide les quatre points essentiels.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('py-c3-p1', 'py-c3', 1, $lesson$Comprendre : une fonction est un nom donné à une tâche$lesson$, $lesson$
Après les variables, les conditions et les boucles des deux premiers chapitres, vous savez faire répéter votre programme et le faire choisir. Il vous reste un défi nouveau : la lisibilité. Un script de cinquante lignes où les calculs, les conversions et les messages s'enchaînent sans structure fonctionne souvent au premier abord, puis devient pénible à corriger dès que quelque chose cloche. Le moindre changement vous oblige à relire tout le fichier, à vérifier que la modification n'a pas cassé une autre partie, et à relancer le programme à chaque essai. La difficulté ne vient plus de la logique, qui est correcte, mais de l'organisation : tout est mélangé dans un même bloc. Découper son code, c'est exactement la réponse à ce problème. Au lieu d'une longue ligne droite, vous construisez une petite collection de briques nommées, chacune responsable d'une seule tâche. Le script principal devient alors une phrase courte qui raconte ce que fait votre programme, tandis que les détails se cachent derrière des noms que vous lisez comme du français.

Pensez à la dernière boucle que vous avez écrite. Elle répétait une opération utile : additionner des valeurs, afficher chaque élément, chercher le plus grand nombre. Une fonction pousse ce même réflexe un peu plus loin. La boucle répète une action ; la fonction lui donne un nom et la range dans un tiroir que vous n'ouvrez que si besoin. Tant que votre programme doit calculer une moyenne à deux endroits différents, vous écrivez le calcul deux fois ; si vos données changent, vous devrez corriger deux endroits, et il suffit d'oublier l'un des deux pour créer un bug silencieux. En regroupant le calcul dans une fonction moyenne, vous ne l'écrivez qu'une fois et vous l'utilisez autant de fois que nécessaire. Le code raccourcit, mais surtout il gagne en confiance : une seule version du calcul à vérifier, une seule version à améliorer, une seule version à documenter. Les boucles et les conditions du chapitre 2 ne disparaissent pas pour autant : elles se rangent à l'intérieur des fonctions. C'est ce rangement qui transforme un empilement d'instructions en programme structuré.

Ce chapitre vous apprend trois gestes simples qui, assemblés, changent votre façon de programmer. D'abord, définir une fonction avec `def` : vous écrivez une en-tête suivie d'un bloc indenté qui contient les instructions de la tâche, et vous résumez cette tâche en une phrase dans un docstring. Ensuite, transmettre des informations avec des paramètres : la fonction reçoit des valeurs sous des noms qu'elle utilise à l'intérieur, avec la possibilité de prévoir des valeurs par défaut pour les cas les plus courants. Enfin, renvoyer un résultat avec `return` : la fonction termine son travail et envoie la réponse à l'appelant, qui décide ensuite de l'afficher, de la conserver dans une variable ou de la réutiliser dans un autre calcul. À la fin du chapitre, vous écrirez un petit programme complet qui calcule une moyenne, en déduit une mention et affiche le tout depuis une fonction main. Vous verrez alors que séparer le calcul de l'affichage n'est pas un raffinement d'architecte : c'est précisément ce qui rend le code testable, corrigeable et réutilisable.



Une fonction regroupe un bloc d'instructions derrière un nom que vous choisissez. Une fois définie, elle reste disponible dans tout le reste du fichier et vous pouvez la rappeler aussi souvent que vous le souhaitez, sans jamais réécrire son contenu. Concrètement, une fonction, c'est une recette de cuisine : les ingrédients correspondent aux données que vous lui donnez, les étapes correspondent aux instructions du corps, et le plat final correspond au résultat qu'elle vous rend. Deux personnes peuvent suivre la même recette avec des ingrédients différents et obtenir un plat adapté à chacune : c'est exactement ce que permettent les paramètres. L'intérêt de ranger une tâche dans une fonction, c'est que vous cessez de penser à ses détails dès qu'elle est écrite et vérifiée. Vous n'avez plus qu'à retenir son nom, son rôle et la manière de l'utiliser. Cette abstraction légère est le premier outil de structuration de Python : un script bien découpé se lit comme une table des matières, et chacune de ses entrées ouvre un chapitre autonome que l'on peut relire, corriger ou remplacer indépendamment des autres.

Vous manipulez déjà des fonctions depuis le premier jour, sans que cela vous ait été signalé. `print()` affiche du texte, `len()` calcule la taille d'une séquence, `input()` lit une saisie clavier, `range()` prépare des valeurs pour une boucle, `int()` et `float()` convertissent des nombres. Toutes ces fonctions sont fournies par Python : on les appelle des fonctions intégrées, ou built-ins en anglais. La nouveauté de ce chapitre n'est donc pas d'apprendre à en utiliser, mais d'apprendre à en fabriquer. Vous passerez du rôle d'utilisateur au rôle d'auteur. Cette distinction est importante : quand vous appelez `print("bonjour")`, vous ne vous souciez pas de la façon dont Python écrit réellement les caractères à l'écran, vous utilisez simplement un service identifié par un nom. À l'inverse, quand vous définissez votre propre fonction, vous devenez responsable de la manière dont ce service fonctionne. Heureusement, le mécanisme d'appel est rigoureusement le même dans les deux cas : un nom suivi de parenthèses, dans lequel vous placez éventuellement des valeurs.

Une définition et une exécution sont deux événements distincts, et comprendre cette différence évite la plupart des incompréhensions du début. Écrire un bloc `def` ne lance aucune instruction : Python lit simplement l'en-tête, mémorise le nom de la fonction et le corps associé, puis continue au programme suivant. Le corps n'est exécuté que lorsqu'une ligne prononce le nom de la fonction avec des parenthèses, ce que l'on appelle un appel. À ce moment précis, Python saute dans le corps, exécute ses instructions une à une, puis revient automatiquement à la ligne qui a lancé l'appel pour continuer. C'est pour cela qu'une fonction peut être définie à la fin d'un fichier alors qu'elle est utilisée au début : tant que l'exécution atteint l'appel après que la définition a été enregistrée, tout fonctionne. En revanche, appeler une fonction avant toute définition lève une erreur du type NameError, car le nom n'existe pas encore à cet instant. Cette règle se résume ainsi : définir range, appeler déclenche.

L'anatomie d'une fonction tient en trois éléments faciles à repérer visuellement. L'en-tête commence par le mot-clé `def`, suivi du nom de la fonction, de parenthèses éventuellement remplies de paramètres, puis d'un deux-points. Le corps est le bloc indenté qui suit, généralement de quatre espaces, contenant les instructions écrites en dessous et alignées entre elles. Enfin, la documentation facultative mais fortement conseillée, le docstring, se place tout de suite après l'en-tête entre triples guillemets et explique en une phrase ce que fait la fonction. L'indentation n'est pas décorative : en Python, elle délimite le bloc. Si vous décalez une ligne de trop ou pas assez, vous modifiez la structure du programme, et l'interpréteur vous le fera savoir avec une erreur d'indentation. Une fonction peut être vide avec le mot-clé `pass`, utile comme gabarit provisoire, mais dans un code réel elle contient toujours au moins une instruction utile, souvent un `return`. Notez enfin que le nom choisi pour la fonction doit rester unique dans le fichier : si vous définissez deux fois le même nom, la seconde définition remplace silencieusement la première, et tous vos anciens appels exécuteront alors le nouveau corps sans le moindre avertissement.

Le vocabulaire de ce chapitre repose sur une distinction que les débutants confondent souvent, alors qu'elle est simple : un paramètre est le nom figurant dans la définition, un argument est la valeur réellement envoyée lors de l'appel. Les paramètres sont les cases vides de la recette, étiquetées ; les arguments sont les produits que vous y déposez. Ainsi, dans `def saluer(nom)`, `nom` est un paramètre, et dans l'appel `saluer("Lina")`, `"Lina"` est un argument. On peut retenir la règle par la sonorité : le paramètre appartient à la définition, l'argument appartient à l'appel. Cette distinction a une conséquence pratique : le nombre et l'ordre des arguments doivent correspondre à ceux des paramètres, sinon Python ne sait pas quelle valeur attribuer à quel nom et lève une erreur de type. Plus loin, vous verrez qu'il est également possible de nommer explicitement les arguments à l'appel, ce qui rend le code plus clair lorsque plusieurs paramètres partagent le même type.

Le troisième pilier du chapitre est `return`, le mécanisme par lequel une fonction communique un résultat à celui qui l'a appelée. Une fonction qui calcule quelque chose doit envoyer ce calcul, pas seulement l'afficher : `return` transmet une valeur et marque immédiatement la fin de la fonction, tandis que `print()` se contente d'écrire sur l'écran et de rendre ensuite `None`. Cette différence est cruciale. Si une fonction affiche une moyenne, seule une personne assise devant le programme peut la voir ; si elle retourne cette moyenne, le reste du code peut la conserver, la comparer, l'ajouter à une autre ou la passer à une fonction qui déduit une mention. L'affichage est une décision de présentation qui appartient généralement à la fin du programme, alors que le calcul est une décision de logique qui appartient à la fonction. D'ailleurs, le titre de votre futur exercice repose exactement sur ce principe : une fonction qui calcule, une autre qui transforme, une troisième qui affiche.

Une fonction qui fait une seule chose est la brique la plus utile que vous puissiez fabriquer. Si vous écrivez une fonction qui lit des notes, calcule leur moyenne, en déduit une mention, formate un message et l'affiche, vous obtenez un bloc impossible à tester partiellement : impossible de vérifier uniquement le calcul de la moyenne sans déclencher l'affichage, impossible de changer le format du message sans toucher à la logique des notes. En découpant cette tâche en fonctions courtes, chacune vérifie une seule idée, vous pouvez appeler moyenne sur une liste inventée et regarder immédiatement si le résultat est juste. Cette propriété, qu'on appelle testabilité, n'est pas un luxe réservé aux grands projets : elle vous fait gagner du temps dès le premier bug. Chaque fois que vous hésitez à ajouter une étape dans une fonction existante, demandez-vous si cette étape mérite son propre nom. La réponse est presque toujours oui, et votre code principal n'en devient que plus lisible.

Enfin, une fonction se documente dès sa création, dans un docstring placé juste après l'en-tête. Ce docstring est une chaîne de caractères non affectée à aucune variable : elle décrit la fonction pour un lecteur humain, et Python sait même la retrouver avec l'aide intégrée. Rédiger une phrase du type Calcule la moyenne d'une liste de notes vous prend cinq secondes au moment de l'écriture, alors qu'il vous faudra plusieurs minutes de relecture trois semaines plus tard, lorsque vous aurez oublié pourquoi ce bloc existait. Le docstring répond à trois questions : que fait la fonction, quelles données attend-elle, que renvoie-t-elle. Il ne répète pas le code, il explique l'intention. Un lecteur pressé lit les en-têtes et les docstrings de votre fichier, comprend l'architecture globale, puis descend dans les détails seulement là où c'est nécessaire. C'est la différence entre un script que l'on subit et un script que l'on transmet.

Voici ce que votre code gagne concrètement en adoptant les fonctions, une fois la démarche devenue habituelle. Le premier bénéfice est l'économie : une tâche écrite une seule fois remplace toutes les copies que vous auriez eu à maintenir à jour, et une seule correction suffit alors à réparer l'ensemble. Le deuxième est la clarté du programme principal, qui se lit comme une suite d'étapes nommées plutôt que comme un empilement d'instructions techniques. Le troisième est l'isolement de la logique, condition indispensable pour tester un calcul avec des valeurs connues avant de brancher de vraies données. S'y ajoutent une correction localisée, une lecture facilitée pour toute autre personne, vous compris dans quelques semaines, et une base naturelle pour la suite du parcours : les modules que vous découvrirez au chapitre 7 ne sont rien d'autre que des collections de fonctions écrites par d'autres. Chacun de ces gains se mesure en minutes économisées lors du prochain débogage.

- Une tâche écrite une seule fois et réutilisable autant de fois que nécessaire dans le même fichier.
- Un programme principal court, qui se lit comme un résumé en français plutôt qu'en détails techniques.
- Une logique isolée, que vous pouvez tester seule avec des valeurs inventées avant de brancher les vraies données.
- Une correction localisée : le correctif s'applique à la fonction fautive sans parcourir tout le script.
- Une lecture facilitée pour toute autre personne, vous compris dans quelques semaines.
- Une base naturelle pour la suite du parcours, car les modules et les bibliothèques ne sont que des collections de fonctions écrites par d'autres.

Voici le vocabulaire minimal à maîtriser avant d'écrire votre première fonction. Ces quelques mots reviendront dans chaque exercice du chapitre, dans la vidéo, puis dans le quiz de validation ; il vaut donc mieux les fixer dès maintenant que de les retrouver, un jour, au détour d'un message d'erreur un peu obscur. Chacun désigne une pièce précise du mécanisme : certains décrivent le code que vous écrivez, d'autres ce qui se passe pendant l'exécution, et d'autres encore la façon dont les données circulent entre le programme principal et les fonctions que vous appelez. Lisez la liste ci-dessous à voix haute, en donnant pour chaque terme un exemple concret tiré d'un script que vous avez déjà écrit : cette petite gymnastique vous fera retenir les définitions bien plus sûrement qu'une relecture silencieuse. Si un seul de ces termes reste flou, revenez au paragraphe correspondant de la section Comprendre avant de poursuivre.

- Définition : le bloc qui commence par `def` et qui enregistre la fonction en mémoire.
- Appel : l'emploi du nom de la fonction suivi de parenthèses, à un endroit du programme.
- Paramètre : le nom placé entre les parenthèses de la définition, servant de variable locale.
- Argument : la valeur transmise entre les parenthèses lors d'un appel.
- Return : le mot-clé qui renvoie un résultat à l'appelant et termine la fonction.
- Docstring : la documentation placée dans les premières lignes du corps de la fonction.
$lesson$),
  ('py-c3-p2', 'py-c3', 2, $lesson$Définir et appeler une fonction avec def$lesson$, $lesson$
La définition d'une fonction commence toujours par le mot-clé `def`, suivi d'un nom, de parenthèses, d'un éventuel liste de paramètres et d'un deux-points. Le nom doit être un identifiant valide : lettres minuscules, chiffres et underscores, sans espace, et il ne doit pas commencer par un chiffre. Par convention, on écrit les fonctions en minuscules avec des underscores pour séparer les mots, par exemple calculer_moyenne. Les parenthèses restent obligatoires même lorsqu'aucun paramètre n'est prévu, car c'est elles qui signalent qu'il s'agit d'une fonction et non d'une simple variable. Le corps, indenté de quatre espaces, contient les instructions réellement exécutées à chaque appel. Une même fonction peut être rappelée un nombre illimité de fois : sa définition n'est écrite qu'une fois, son exécution autant de fois que nécessaire. C'est cette économie qui justifie l'effort de découpage. Pensez-y la prochaine fois que vous hésiterez à copier un bloc d'instructions : avant de dupliquer, demandez-vous si ce bloc ne mériterait pas plutôt un nom, des parenthèses et une documentation.

L'appel d'une fonction s'écrit avec son nom, des parenthèses et, le cas échéant, les arguments séparés par des virgules. Python interrompt alors le flux normal, exécute le corps ligne à ligne, puis revient exactement à l'endroit où l'appel a été formulé pour poursuivre l'instruction suivante. Le résultat éventuellement renvoyé par `return` peut être ignoré, affiché ou conservé dans une variable, au gré de vos besoins. Si la fonction ne contient aucun `return`, l'appel vaut `None`, une valeur spéciale qui signifie l'absence de résultat. Il est courant, dans un script débutant, d'appeler une fonction uniquement pour l'effet qu'elle produit : afficher un message, enregistrer une valeur, déclencher un calcul. On parle alors de fonction sans retour utile, dont le rôle est d'accomplir une action plutôt que de fournir une donnée. Les deux usages sont légitimes, à condition de savoir lequel vous mettez en œuvre. Dans la pratique, une fonction se contente souvent de faire les deux à la fois : elle renvoie une valeur utile et laisse derrière elle un effet visible, comme un message affiché ou un compteur incrémenté.

L'ordre des instructions dans le fichier compte : une fonction doit être définie avant d'être appelée. Python exécute le fichier de haut en bas, et lorsqu'il rencontre une ligne d'appel, il a besoin que le nom soit déjà enregistré en mémoire. Si vous appelez une fonction définie plus bas, l'exécution s'arrête avec un message du type name 'calculer' is not defined. Deux solutions s'offrent à vous. La première consiste à placer toutes les définitions en haut du fichier, puis le code principal en dessous : c'est l'organisation la plus claire pour un script court. La seconde consiste à ranger le code principal dans une fonction main, elle-même appelée tout à la fin du fichier, après toutes les autres définitions. Cette seconde approche devient indispensable dès que les définitions se multiplient, car elle garantit qu'aucun appel ne survient avant l'enregistrement des fonctions concernées. Dans un fichier court, les deux organisations fonctionnent parfaitement ; dans un fichier long, seule la seconde reste confortable à maintenir et à faire relire à quelqu'un d'autre.

La fonction main constitue une convention répandue que vous retrouverez dans de très nombreux scripts Python. Son rôle est unique : orchestrer le programme. Elle déclare les données, appelle les fonctions de calcul, récupère les résultats et commande l'affichage. Elle ne contient pas de logique métier détaillée, seulement la séquence des opérations. Avantages : le fichier se lit en deux temps, d'abord les définitions, ensuite la fonction principale ; vous pouvez tester chaque fonction indépendamment en appelant main ou en l'évitant complètement ; et vous disposez d'un point d'entrée unique. Il suffit alors d'écrire `main()` sur la dernière ligne du fichier pour lancer le programme. Cette ligne n'est exécutée que lorsque le fichier est lancé directement, ce qui prépare naturellement le terrain pour les modules du chapitre 7. À partir de maintenant, adoptez ce réflexe dès votre premier script d'exercice. En lisant d'autres programmes, vous remarquerez d'ailleurs que cette fonction est presque toujours nommée main, ce qui rend la comparaison entre deux scripts immédiate : on sait en un coup d'œil où commence le travail réel.

Une même fonction peut être appelée plusieurs fois, avec des arguments différents, et chaque appel possède ses propres variables internes. Les paramètres et les variables créées dans le corps n'existent que pendant l'exécution de l'appel : on les dit locales. Un appel ne se souvient pas des valeurs du précédent, sauf si vous les stockez vous-même dans une variable extérieure. Cette indépendance est ce qui rend la fonction fiable : deux appels successifs ne peuvent pas se contaminer mutuellement. Elle explique aussi pourquoi vous pouvez appeler moyenne sur dix listes différentes sans jamais vous demander quel état la fonction a laissé derrière elle. Retenez le principe suivant : une fonction est un petit programme autonome qui reçoit tout ce dont il a besoin par ses arguments et qui rend tout ce qu'il produit par son `return`. Ce contrat réduit aussi la surface des erreurs : pour modifier le comportement d'une fonction, vous ne touchez que son corps, et pour changer les données traitées, vous ne touchez que l'appel.

```python
def saluer(nom):
    """Affiche un message de bienvenue personnalisé."""
    print("Bonjour," , nom)
def doubler(valeur):
    """Renvoie le double du nombre reçu."""
    return valeur * 2
saluer("Lina")
saluer("Karim")
print(doubler(5))
print(doubler(12))
```

Ce petit exemple contient déjà toute la mécanique du chapitre. La fonction saluer reçoit un nom, affiche un message et ne renvoie rien d'exploitable ; elle accomplit une action. La fonction doubler reçoit un nombre et renvoie son double par `return` ; elle fournit une donnée. Lorsque le fichier s'exécute, Python commence par enregistrer les deux définitions, puis il rencontre les appels : saluer est exécuté deux fois avec deux arguments différents, doubler l'est également, et la valeur renvoyée est envoyée vers `print` pour être affichée. Vous pouvez essayer de commenter les lignes d'appel : le programme ne produira alors aucune sortie, car définir ne suffit pas, il faut appeler. C'est la première règle à retenir de ce chapitre : une fonction inappelée est une fonction qui n'existe pas pour l'utilisateur. Essayez également d'ajouter un troisième appel avec un nombre décimal : vous constaterez que doubler s'adapte à tout type numérique sans que sa définition change, ce qui est précisément la promesse d'un paramètre bien pensé.
$lesson$),
  ('py-c3-p3', 'py-c3', 3, $lesson$Paramètres et arguments : le contrat de la fonction$lesson$, $lesson$
Les paramètres sont les noms que vous placez entre les parenthèses de la définition : ils jouent le rôle de variables temporaires, créées à chaque appel, et reçoivent les valeurs que vous lui transmettez. Ils constituent le contrat de la fonction : ce qu'elle attend pour fonctionner. Une fonction moyenne qui prend un paramètre notes s'engage à n'avoir besoin que de cette liste pour produire un résultat, et vous, appelant, vous vous engagez à lui fournir une liste. Ce contrat est ce qui rend la fonction indépendante du reste du script : elle ne va pas chercher ses données ailleurs, elle les reçoit. Tant que vous respectez le contrat, vous pouvez déplacer la définition n'importe où dans le fichier, la renommer légèrement ou en améliorer l'intérieur sans rien casser dans le code qui l'appelle. Avoir formalisé ce besoin en un nom unique change radicalement la façon dont on conçoit un programme : on ne se demande plus comment je vais fabriquer ce résultat ici, mais quelle fonction connais-je qui fabrique ce résultat à partir de ces données.

Le nombre et l'ordre des arguments doivent correspondre exactement à ceux des paramètres, car Python associe les valeurs aux noms par position, du premier au dernier. Si la fonction attend deux paramètres et que vous en envoyez un seul, l'exécution s'arrête avec un message du type TypeError: moyenne() missing 1 required positional argument. Si vous en envoyez trois, Python signale un argument en trop. Si vous inversez l'ordre, le programme ne plante pas nécessairement, ce qui est bien plus dangereux : la fonction reçoit des valeurs cohérentes en type mais inversées en sens, et produit un résultat faux. Par exemple, passer le nom à une fonction qui attend d'abord la note inverse silencieusement vos données. Cette asymétrie est la source d'une grande partie des bugs de débutant. Pour vous en prémunir, donnez aux paramètres des noms explicites, relisez l'appel à voix haute en associant chaque argument à son paramètre, et préférez les arguments nommés lorsque vous hésitez sur l'ordre, comme nous le verrons dans la section suivante.

Un paramètre se comporte comme une variable locale : il n'existe que pendant l'exécution de la fonction et il n'est visible nulle part ailleurs. Ainsi, dans une fonction doubler(valeur), le nom valeur est inconnu du reste du fichier ; une tentative d'imprimer valeur après la fin de l'appel provoque une erreur NameError. Inversement, une variable créée à l'extérieur de la fonction n'est pas accessible à l'intérieur par simple affectation. Ce cloisonnement volontaire protège votre code : une fonction ne peut pas modifier par accident une variable du programme principal, et le programme principal ne peut pas voir les variables intermédiaires d'une fonction. Chaque appel repart d'une feuille blanche, avec ses propres paramètres et ses propres variables de travail. Cette règle a une conséquence rassurante : quand une fonction renvoie un résultat correct, vous n'avez pas à vous demander quel état elle a modifié à côté, car elle ne touche, de toute façon, qu'à son propre espace de travail.

Le choix des noms de paramètres est un investissement. Un paramètre appelé x ou a fonctionne techniquement, mais force le lecteur à remonter à la définition pour comprendre l'appel, tandis que moyenne_score ou notes_eleves exprime directement l'intention. Utilisez des noms au singulier quand la fonction travaille sur une valeur, au pluriel quand elle s'attend à une séquence, et préférez des noms qui décrivent le rôle plutôt que le type : nom plutôt que chaîne, moyenne plutôt que nombre. Ce dernier point mérite attention, car un même paramètre accepte souvent plusieurs types différents sans changer de rôle. Lorsque une fonction prend plusieurs paramètres, respectez un ordre logique : d'abord les données principales, ensuite les options ou les seuils. Une signature comme mention(moyenne, seuil_a, seuil_b) se lit comme une phrase, alors que mention(seuil_a, seuil_b, moyenne) impose un effort de mémoire à chaque appel. Ces détails coûtent quelques secondes à l'écriture et font gagner des minutes à chaque relecture.

Grâce aux paramètres, une fonction devient générique : le même code s'applique à des données qu'on ne connaît pas encore. Sans paramètre, vous écririez une fonction calculer_notes_classe_2024 durcie autour de valeurs figées ; avec un paramètre notes, vous obtenez une fonction qui fonctionnera pour n'importe quelle liste, aujourd'hui et dans trois mois. C'est exactement la différence entre une règle à modèle unique et une règle réglable. Vous pouvez alors tester la fonction avec des listes minimales que vous maîtrisez, vérifier le comportement aux extrêmes, puis la brancher sur de vraies données saisies au clavier ou lues dans un fichier, comme vous le ferez au chapitre 5. Plus important encore, la fonction devient réutilisable hors de son contexte d'origine : elle peut être copiée dans un autre script, ou importée depuis un module, sans rien modifier à son intérieur. Avoir prévu les bons paramètres est donc la condition de réutilisation d'un code.

```python
def surface_rectangle(longueur, largeur):
    """Calcule l'aire d'un rectangle à partir de deux dimensions."""
    return longueur * largeur
def est_admis(score, seuil):
    """Indique si un score atteint le seuil demandé."""
    return score >= seuil
print(surface_rectangle(4, 7))
print(surface_rectangle(10, 3))
print(est_admis(15, 12))
print(est_admis(9, 12))
```

Les deux fonctions de cet exemple illustrent le contrat au travail. Surface_rectangle exige deux arguments, toujours dans cet ordre, et ne fonctionne pas du tout sans eux : le calcul dépend entièrement des valeurs reçues. Est_admis, elle, renvoie un booléen, ce qui montre qu'une fonction peut renvoyer autre chose qu'un nombre, y compris une réponse de type vrai ou faux directement exploitable dans une condition. Notez que l'appel est_admis(15, 12) renvoie True, tandis que est_admis(9, 12) renvoie False : le résultat est transmis à l'appelant, qui peut l'afficher ou, mieux, l'utiliser dans un `if`. Vous pouvez également constater qu'aucune variable extérieure n'est nécessaire : les deux fonctions n'utilisent que leurs paramètres. Elles sont donc parfaitement autonomes, déplaçables et testables isolément. Notez aussi que chaque appel utilise des valeurs différentes sans jamais modifier la définition : le programme reste stable tant que vous ne changez pas le corps d'une fonction. C'est cette stabilité qui vous permettra, au chapitre 5, de remplacer la liste saisie en dur par des données lues dans un fichier sans réécrire une seule ligne de calcul.
$lesson$),
  ('py-c3-p4', 'py-c3', 4, $lesson$Valeurs par défaut et arguments par mot-clé$lesson$, $lesson$
Une valeur par défaut s'écrit directement dans la définition, après le signe égal, dans l'en-tête : `def saluer(nom="ami")` indique que le paramètre nom vaut par défaut la chaîne ami. L'appel saluer() devient alors possible : Python n'a rien reçu, il utilise la valeur prévue. L'appel saluer("Lina") fonctionne aussi et remplace temporairement cette valeur. L'intérêt est d'éviter de multiplier les variantes de la même fonction : au lieu de écrire saluer_ami(), saluer_collègue() et saluer_par_defaut(), vous disposez d'une seule fonction couvrant les cas courants, tout en restant ouverte aux cas particuliers. C'est un raccourci très fréquent dans les bibliothèques standard, où une fonction propose une dizaine de paramètres avec des valeurs de convenance. Attention toutefois à ne pas en abuser : une valeur par défaut doit représenter un choix vraiment standard, pas une donnée qui varie selon les situations. Sinon, l'appelant croit avoir le bon comportement alors qu'il obtient simplement la valeur silencieusement prévue.

Les arguments par mot-clé permettent de préciser, lors de l'appel, le nom du paramètre auquel vous assignez une valeur, sous la forme cle="valeur". L'appel saluer(nom="Lina") est strictement équivalent à saluer("Lina") lorsqu'un seul paramètre existe, mais l'écriture nommée devient précieuse dès que la signature se complexifie. Elle supprime toute ambiguïté d'ordre, rend le code lisible même plusieurs semaines plus tard et autorise l'envoi d'arguments dans n'importe quel ordre. Elle permet aussi d'ignorer volontairement certains paramètres tout en en renseignant un autre, sans avoir à fournir les précédents. Python accepte de mélanger arguments positionnels et arguments par mot-clé, à une condition : tous les arguments positionnels doivent venir en premier. À partir du moment où un argument nommé apparaît, plus aucun argument sans nom ne peut suivre, sous peine de SyntaxError. Pratiquez les deux écritures : positionnelle pour les cas évidents, nominative dès que vous doutez. Vous rencontrerez ce style dans les bibliothèces standard, où une même fonction propose souvent plusieurs options facultatives à n'importe quelle position.

Les valeurs par défaut obéissent à deux règles syntaxiques qu'il faut connaître avant de se faire surprendre. La première concerne l'ordre : un paramètre sans valeur par défaut ne peut pas suivre un paramètre qui en une. Dans def saluer(nom, salutation="Bonjour"), l'ordre est correct, mais dans def saluer(nom="Bonjour", salutation), Python refuse la définition, car il ne pourrait pas attribuer de valeur à salutation lorsque l'appelant ne fournit qu'un seul argument. La correction consiste soit à donner une valeur par défaut à tous les paramètres qui suivent, soit à remettre les paramètres obligatoires en premier. La deuxième règle est temporelle : la valeur par défaut est calculée une seule fois, au moment où la fonction est définie, et non à chaque appel. Pour une chaîne ou un nombre, cela ne change rien, car ces objets sont immuables. Pour une liste, en revanche, la même instance serait réutilisée d'un appel à l'autre, et les éléments ajoutés persisteraient : c'est un piège classique que nous détaillerons au chapitre 4 sur les structures de données, mais il est bon de savoir dès maintenant que la valeur par défaut appartient à la fonction, pas à l'appel.

Les valeurs par défaut deviennent particulièrement utiles lorsqu'une fonction possède plusieurs paramètres et que seuls quelques-aux varient réellement. Imaginez une fonction formater_note(note, decimales=1, mentionnelle=False) : l'appelant lambda qui veut juste un affichage appelle formater_note(14.67), tandis que l'utilisateur exigeant appelle formater_note(14.67, decimales=2, mentionnelle=True). Une seule définition couvre tous les usages, et la signature elle-même documente les possibilités. Le revers de cette mécanique est la tentation d'accumuler les paramètres par défaut pour éviter d'écrire plusieurs fonctions. Si votre fonction en compte plus de quatre ou cinq, c'est souvent le signe qu'elle fait plusieurs choses à la fois et qu'un découpage en fonctions plus petites serait plus clair. Retenez l'équilibre : les valeurs par défaut servent à simplifier les appels courants, pas à masquer un découpage insuffisant. Une signature qui déborde sur plusieurs lignes ou que vous devez relire deux fois pour la comprendre est le signe qu'une ou deux fonctions supplémentaires rendraient le code plus lisible, y compris pour la personne qui vous appellera.

```python
def saluer(nom="ami", salutation="Bonjour"):
    """Salue une personne avec un message personnalisable."""
    print(salutation + ", " + nom + " !")
saluer()
saluer("Lina")
saluer(salutation="Bonsoir", nom="Karim")
saluer("Nina", "Hello")
```

Examinez les quatre appels de cet exemple : le premier n'envoie rien et obtient les deux valeurs par défaut ; le second fournit seulement le nom positionnellement ; le troisième nomme explicitement les deux paramètres, ce qui lui permet d'inverser l'ordre sans ambiguïté ; le quatrième utilise deux arguments positionnels, la salutation venant donc en second. Tous produisent une sortie différente avec une seule et même définition. C'est exactement l'effet recherché : une fonction unique, des appels adaptés à chaque situation. Notez que les noms des paramètres apparaissent dans l'en-tête, dans le docstring et éventuellement dans les appels : trois endroits où la même information se répète, ce qui vous oblige à choisir des noms cohérents. Une incohérence entre le nom du paramètre et son usage dans le corps est souvent le premier symptôme d'une fonction mal nommée ou trop chargée. Modifiez la valeur par défaut de salutation et relancez le script : le premier appel change aussitôt, tandis que les trois autres, qui fournissent leurs propres valeurs, restent strictement identiques.

```table
Forme d'appel | Exemple d'appel | Effet
--- | --- | ---
Valeur par défaut | `saluer()` | n'envoie rien et obtient les deux valeurs par défaut
Positionnel | `saluer("Lina")` | fournit seulement le nom
Par mot-clé | `saluer(salutation="Bonsoir", nom="Karim")` | nomme explicitement les deux paramètres et permet d'inverser l'ordre sans ambiguïté
Positionnel | `saluer("Nina", "Hello")` | utilise deux arguments positionnels, la salutation venant en second
```
$lesson$),
  ('py-c3-p5', 'py-c3', 5, $lesson$Return versus print : afficher et transmettre sont deux métiers$lesson$, $lesson$
La confusion la plus fréquente chez les débutants consiste à utiliser `print()` là où `return` serait attendu. Les deux mots-clés produisent une forme de communication, mais leur destination diffère radicalement. `print()` écrit sur l'écran de l'utilisateur : c'est une action visible, définitive, destinée à un humain qui regarde le programme s'exécuter. `return` écrit dans le programme : c'est une transmission de valeur vers l'appelant, invisible, que celui-ci peut stocker, comparer, transformer ou afficher plus tard. Une fonction qui affiche ses résultats n'est utilisable que si quelqu'un observe l'écran ; une fonction qui les renvoie est utilisable partout. Cette distinction est si importante qu'elle structure l'ensemble de votre futur exercice pratique : moyenne doit renvoyer un nombre, mention doit renvoyer une lettre, et seul main doit se charger d'afficher quoi que ce soit. Une fonction de calcul qui affiche impose sa décision de présentation à tout appelant, y compris ceux qui souhaiteraient afficher autrement ou pas du tout.

Sans `return`, une fonction renvoie implicitement `None`, la valeur Python qui représente l'absence de résultat. Cela ne provoque aucune erreur : le programme continue tranquillement, mais la variable qui devait recevoir la valeur contient `None`, et toute opération ultérieure sur cette valeur échouera. Exemple classique : vous écrivez total = ajouter_notes(notes) alors que la fonction ajouter_notes ne contient que des `print`, puis vous obtenez un message du type TypeError: unsupported operand type(s) for +: 'int' and 'NoneType' lorsque vous utilisez total. L'erreur semble venir de l'addition, alors qu'elle vient en réalité de l'absence de `return` plusieurs lignes plus haut. Heureusement, Python offre une vérification immédiate : afficher le type d'un résultat avec print(type(moyenne(...))) vous indique en une seconde si vous manipulez un nombre ou un None. Cette habitude de vérifier le type de ce qu'une fonction renvoie vaut souvent dix minutes de débogage, et elle devrait devenir un réflexe dès que vous récupérez la valeur d'une fonction nouvellement écrite.

`return` possède un second effet, souvent découvert trop tard : il met fin immédiatement à l'exécution de la fonction. Toute instruction placée après lui dans le même corps ne sera jamais exécutée, car le programme est déjà revenu vers l'appelant. Cette propriété est très pratique dans les fonctions de validation : on teste une condition, on renvoie une valeur d'erreur, puis on poursuit le traitement normal. On obtient ainsi une lecture verticale où les cas particuliers sont traités en haut et où le cas standard occupe le reste du corps, sans lourdeur de conditions imbriquées. Attention cependant à ne pas placer `return` au milieu d'un bloc que vous pensiez exécuter ensuite : si vos instructions de fin de fonction ne s'exécutent jamais, c'est probablement qu'un `return` anticipé les a devancées. Une fonction peut contenir plusieurs `return`, répartis dans différentes branches d'une condition : c'est même la façon la plus claire d'écrire une fonction qui renvoie des valeurs selon des cas, comme la fonction mention que vous allez implémenter tout à l'heure.

Un résultat renvoyé n'a pas besoin d'être affiché immédiatement : il peut d'abord être conservé dans une variable, ce qui permet de l'utiliser plusieurs fois ou de le transmettre à une autre fonction. C'est le principe de composition, et c'est la raison d'être du découpage en fonctions. La moyenne calculée par moyenne peut être envoyée à mention pour obtenir la lettre, puis les deux résultats peuvent être affichés ensemble dans main. Si moyenne avait affiché le nombre au lieu de le renvoyer, mention n'aurait jamais pu l'utiliser : on ne transmet pas un écran à une fonction. En traçant le chemin des données, de l'entrée vers la sortie, votre programme principal devient une chaîne de transformations lisibles : les notes entrent, la moyenne sort ; la moyenne entre, la mention sort ; tout s'affiche à la fin. Chaque maillon est indépendant, testable et remplaçable. C'est ce chemin clair qui distingue un script structuré d'un empilement d'instructions.

Il est tentant d'écrire `print` à l'intérieur d'une fonction de calcul parce que l'on veut voir immédiatement si le résultat est juste. Le réflexe est compréhensible pendant l'apprentissage, mais il corrompt la fonction : elle devient incapable de servir à autre chose qu'à l'affichage. La bonne pratique consiste à séparer soigneusement les deux responsabilités. La fonction de calcul fait son travail et retourne une valeur ; la fonction de présentation, appelée depuis main, reçoit cette valeur et décide de la mise en forme. Pour tester le calcul, vous appelez la fonction avec des valeurs connues et vous comparez le résultat à l'attendu, sans jamais lancer d'affichage. Pour tester l'affichage, vous passez une valeur déjà calculée. Cette séparation est exactement ce que le quiz de ce chapitre vérifie : savoir que découper calcul et affichage permet de tester et de réutiliser le calcul indépendamment du reste du programme. Prenez l'habitude dès maintenant, et votre code deviendra beaucoup plus facile à corriger.

```python
def moyenne_brouillon(notes):
    """Version faible : affiche au lieu de renvoyer."""
    total = 0
    for note in notes:
        total = total + note
    print(total / len(notes))
def moyenne(notes):
    """Version correcte : renvoie le résultat."""
    total = 0
    for note in notes:
        total = total + note
    return total / len(notes)
resultat = moyenne([10, 12, 14])
print("Résultat capté :", resultat)
print("Type renvoyé :", type(resultat))
moyenne_brouillon([10, 12, 14])
print("Retour de la version brouillon :", moyenne_brouillon([10, 12, 14]))
```

Comparez attentivement les deux définitions de cet exemple. Moyenne_brouillon produit exactement le même affichage que moyenne, et pourtant sa valeur exploitable vaut `None` : la dernière ligne l'affiche explicitement, prouvant que `print` ne transmet aucune donnée exploitable. Moyenne, elle, n'affiche rien du tout et confie le nombre à l'appelant, qui décide de l'afficher, de le stocker ou de le passer à une autre fonction. La variable resultat contient bien 12.0, et type(resultat) confirme qu'il s'agit d'un flottant. Ces deux lignes de vérification constituent votre meilleur allié contre les oublis de `return` : si vous vous attendez à un nombre et que vous obtenez NoneType, la cause est certainement un `return` manquant ou placé après un `print`. Gardez aussi à l'esprit qu'une fonction peut faire les deux à la fois, afficher et renvoyer, mais que ce mélange rend ensuite le code plus difficile à réutiliser : l'appelant reçoit une valeur tout en étant soumis à un affichage qu'il n'a pas demandé. Préférez séparer les deux responsabilités.

```table
Comparaison | `print()` | `return`
--- | --- | ---
Destination | sur l'écran de l'utilisateur | dans le programme, vers l'appelant
Ce qui est transmis | une action visible et définitive | une transmission de valeur, invisible
Réception par l'appelant | rien d'exploitable : sans `return`, la fonction renvoie `None` | la valeur est reçue et peut être stockée, comparée, transformée ou affichée plus tard
Utilisation | utilisable seulement si quelqu'un observe l'écran | utilisable partout, y compris dans un autre calcul
Cas d'usage | seul main se charge d'afficher | moyenne renvoie un nombre, mention renvoie une lettre
```
$lesson$),
  ('py-c3-p6', 'py-c3', 6, $lesson$Portée des variables : locale, globale, et pourquoi hésiter$lesson$, $lesson$
La portée d'une variable désigne la portion du programme où son nom est accessible. Dans une fonction, toutes les variables créées dans le corps, y compris les paramètres, sont locales : elles naissent à l'appel, vivent pendant toute l'exécution du corps, puis disparaissent. Une fonction moyenne qui déclare une variable total ne pollue pas l'espace de noms du fichier, et ce total n'est pas visible après le retour. Cette isolation a deux avantages décisifs. Elle empêche les collisions : deux fonctions peuvent chacune utiliser une variable nommée i, total ou résultat sans jamais se perturber. Et elle facilite le raisonnement : pour comprendre une fonction, vous n'avez à examiner que son corps et ses paramètres, sans avoir à reconstituer l'état du reste du programme. Le prix à payer est simple : une fonction ne peut pas communiquer avec l'extérieur autrement que par ses arguments en entrée et son `return` en sortie. Dès que vous ressentez le besoin d'une variable partagée, c'est en général le signe qu'un paramètre manque ou qu'un résultat devrait être renvoyé.

Python autorise une fonction à lire une variable définie à l'extérieur, dans le module, ce qu'on appelle une variable globale. La lecture fonctionne sans préparation : si une variable compteur existe avant l'appel, une fonction peut l'utiliser dans une expression. En revanche, une simple affectation à l'intérieur de la fonction crée une nouvelle variable locale du même nom, sans jamais modifier la globale. Ce comportement surprend souvent : vous modifiez ce que vous croyez être la variable globale, et le programme principal continue d'afficher l'ancienne valeur. Pour qu'une fonction modifie réellement une globale, il faut écrire le mot-clé global compteur en tête du corps, ce qui autorise ensuite l'affectation. Techniquement, cela fonctionne ; pédagogiquement, c'est rarement souhaitable, car une fonction qui modifie l'état extérieur devient difficile à tester : son résultat dépend alors de ce qui a été modifié avant, et non plus uniquement de ses arguments. Préférez systématiquement passer les données par paramètre et renvoyer le résultat par `return`.

Le shadowing, ou ombre portée, survient lorsqu'un nom local masque temporairement un nom global. Si un paramètre s'appelle notes alors qu'une liste notes existe déjà dans le programme principal, le corps de la fonction ne verra que le paramètre. C'est un comportement normal, souvent utile, mais il devient source de confusion lorsque vous pensiez accéder à la variable extérieure : elle est alors invisible sans précaution. La parade est simple et recommandée : choisissez des noms de paramètres suffisamment précis pour ne jamais entrer en conflit, par exemple notes_eleves plutôt que notes, et évitez de réutiliser dans une fonction les noms des variables principales de votre script. En lisant un appel, le lecteur doit immédiatement identifier quelles valeurs entrent et quelle variable reçoit le résultat. Une convention claire, comme utiliser des noms distincts par rôle, supprime toute ambiguïté sans aucun coût à l'exécution. Si vous avez besoin de lire une variable extérieure depuis l'intérieur d'une fonction, elle reste accessible en lecture seule : le conflit ne naît qu'au moment d'affecter.

Une fonction main, lorsqu'elle est appelée depuis la dernière ligne du fichier, possède une portée particulière : ses variables sont locales à main et disparaissent après son exécution, ce qui est parfait puisque le programme se termine à ce moment-là. Si vous avez besoin d'une valeur calculée dans main plus tard, conservez-la dans une variable de main ou renvoyez-la. Plus largement, le principe à retenir est le suivant : le flux de données passe par les arguments et par `return`, pas par les variables partagées. Une fonction qui lit trois globales, en modifie deux et renvoie une quatrième est une fonction dont le comportement réel n'est écrit nulle part, car il dépend du contexte. À l'inverse, une fonction dont la signature résume toutes les entrées et dont le `return` résume la sortie se comprend en une lecture. Cette discipline vous semblera rigide au début, mais elle vous évitera des heures de recherche d'état quand le programme grossira.

```python
compteur = 0
def incrementer():
    """Modifie la variable globale, avec le mot-clé global."""
    global compteur
    compteur = compteur + 1
def total_local(valeur):
    """Travaille uniquement sur sa variable locale."""
    total = 0
    for i in range(valeur):
        total = total + i
    return total
incrementer()
incrementer()
print("Compteur global :", compteur)
print("Total local :", total_local(5))
print("Le nom total existe-t-il ici ?")
try:
    print(total)
except NameError:
    print("Non : total a disparu avec la fin de l'appel.")
```

Cet exemple montre les deux situations côte à côte. La fonction incrementer utilise le mot-clé global pour toucher réellement la variable définie hors fonction : après deux appels, compteur vaut bien 2. La fonction total_local, elle, crée un total strictement local, le calcule, le renvoie et l'oublie : dès la fin de l'appel, le nom total n'existe plus, comme le prouve le bloc de vérification final. Vous y découvrez également les expressions try et except, qui permettent d'attraper une erreur plutôt que de laisser le programme s'arrêter : nous les détaillerons au chapitre 6 consacré aux exceptions. Pour l'instant, retenez surtout le principe : la portée suit l'indentation, une variable locale naît et meurt avec l'appel, et la communication entre le monde extérieur et l'intérieur d'une fonction passe par les arguments et par `return`. Remplacez ensuite la fonction incrementer par une version qui renvoie la nouvelle valeur au lieu de modifier une globale, et vous obtiendrez un code plus facile à raisonner, testable appel après appel.
$lesson$),
  ('py-c3-p7', 'py-c3', 7, $lesson$Docstrings, nommage et style : signer son code$lesson$, $lesson$
Le docstring est une chaîne de caractères placée dans les toutes premières lignes du corps d'une fonction, juste après l'en-tête, entre triples guillemets. Contrairement à une simple chaîne posée dans le code, elle n'est affectée à aucune variable : elle reste attachée à la fonction et peut être relue plus tard, par vous, par un collègue, ou par Python lui-même à travers l'aide intégrée. Un docstring utile tient en une ou deux phrases et répond à trois questions : que fait cette fonction, quelles valeurs attend-elle en entrée, que renvoie-t-elle en sortie. Il ne détaille pas le comment, qui est lisible dans le corps, mais le pourquoi, qui n'apparaît nulle part ailleurs. Commencez toujours par une phrase courte qui se lit comme un titre, puis ajoutez des précisions seulement si elles apportent quelque chose. Un docstring vide ou un mot recopié depuis le nom de la fonction n'aide personne ; à l'inverse, préciser que la fonction attend une liste de notes comprises entre 0 et 20 peut vous éviter une recherche de bug de dix minutes.

Python conserve les docstrings dans un attribut accessible en dynamique, et la fonction help les affiche. Après avoir défini une fonction dans un environnement interactif ou dans un script, appeler help(moyenne) restitue la documentation exactement comme pour les fonctions intégrées que vous avez utilisées depuis le premier chapitre. Vous retrouvez ainsi le même confort que pour print ou len : une information disponible sans rouvrir le fichier source. C'est aussi la raison pour laquelle les bibliothèques de Python sont si agréables à utiliser : chaque fonction documente son contrat. En écrivant vos propres docstrings, vous vous offrez le même confort sur votre propre code. N'attendez pas la fin du développement : rédigez le docstring au moment où vous écrivez la fonction, alors que l'intention est encore fraîche dans votre esprit. Le coût est négligeable, le bénéfice est permanent, et c'est le geste qui sépare un code jetable d'un code transmissible.

Il ne faut pas confondre docstring et commentaire. Un commentaire, précédé du diègre, s'adresse au lecteur du code et n'est visible qu'en ouvrant le fichier ; il sert à expliquer une ligne difficile, un choix arbitraire ou un raccourci. Un docstring, lui, est une donnée du programme, accessible à l'exécution, et il documente l'ensemble de la fonction plutôt qu'une instruction précise. Les deux sont utiles, mais ils ne remplacent pas l'autre : un docstring ne doit pas répéter mot pour mot la ligne qui suit, et un commentaire qui réexplique une évidence vaut mieux supprimé. Rédigez un commentaire quand la raison d'être d'une instruction n'est pas déductible du code, par exemple pour justifier un seuil ou une décision métier, et comptez sur le docstring pour l'identité de la fonction. Une fonction bien nommée, documentée d'une phrase et contenant quelques commentaires ciblés atteint un équilibre de lecture confortable, sans surcharge inutile.

Le style de vos fonctions obéit à des conventions rassemblées dans la proposition d'amélioration Python numéro 8, connue sous le nom de PEP 8, que vous retrouverez en fin de chapitre. Les conventions essentielles pour les fonctions sont les suivantes : nom en minuscules avec des underscores pour séparer les mots, jamais d'espaces ni de majuscules en début de nom ; verbe ou groupe verbal pour exprimer l'action, parce qu'une fonction fait quelque chose ; signature courte, idéalement cinq paramètres au plus ; corps lisible sans recourir à des astuces ; docstring présent. Une fonction qui porte un nom comme calculer, traiter ou faire_un_truc est trop vague pour être utile : le lecteur ne sait pas ce qui sera calculé ni à partir de quoi. Préférez des noms précis et orientés vers le domaine, comme moyenne_des_notes ou convertir_en_pourcentage. Ces choix ne coûtent rien à l'interpréteur, mais ils changent radicalement la vitesse à laquelle un humain comprend votre fichier.

```python
def moyenne(notes):
    """Renvoie la moyenne arithmétique d'une liste de notes.
    Paramètre notes : séquence de nombres positifs ou nuls.
    Retour : un flottant, sauf si la liste est vide.
    """
    total = 0
    for note in notes:
        total = total + note
    return total / len(notes)
def mention(moy):
    """Transforme une moyenne numérique en lettre de mention."""
    if moy > 16:
        return "A"
    elif moy > 14:
        return "B"
    elif moy > 12:
        return "C"
    else:
        return "D"
help(moyenne)
print(moyenne([10, 12, 14]))
```

Ce bloc montre le niveau de documentation attendu dans vos exercices : une phrase de synthèse, puis seulement les informations qui ne se devinent pas, comme le type des paramètres et la nature du résultat. La fonction moyenne conserve son corps inchangé, ce qui prouve qu'un docstring n'affecte jamais l'exécution : effacez-le, le calcul fonctionne exactement de la même manière, mais votre code perd sa documentation. La fonction mention, plus courte, se contente d'une seule ligne, ce qui suffit pour une logique limpide. Enfin, la ligne help(moyenne) affiche la documentation complète à l'écran, puis moyenne([10, 12, 14]) rappelle que toute cette mécanique se termine par un résultat utile : ici 12.0, une moyenne que vous pouvez immédiatement passer à mention pour obtenir la correspondance de lettre. Si vous retirez les lignes de documentation, l'exécution reste strictement identique, preuve qu'un docstring n'appartient pas au flux d'exécution. En revanche, supprimez une instruction du corps et le résultat change : c'est toute la différence entre documenter et programmer.
$lesson$),
  ('py-c3-p8', 'py-c3', 8, $lesson$Combiner les fonctions : l'art de s'appeler entre elles$lesson$, $lesson$
Une fonction peut appeler une autre fonction, et c'est même là que réside toute la puissance du découpage. L'appel se place n'importe où dans le corps, y compris directement à l'intérieur des parenthèses d'un autre appel ou d'une expression. Ainsi, mention(moyenne(notes)) exécute d'abord moyenne, récupère la valeur renvoyée, puis la transmet immédiatement à mention : deux briques indépendantes s'assemblent en une seule lecture. Python évalue les appels de l'intérieur vers l'extérieur, le plus profond d'abord, puis remonte avec le résultat. Cette possibilité de composition signifie que vous n'avez jamais besoin d'une fonction géante : chaque exigence nouvelle devient une petite fonction qui s'ajoute à votre collection et qui, si elle a besoin d'un calcul existant, le réutilise au lieu de le réécrire. C'est le même principe que les briques de construction : plus les briques sont simples et standardisées, plus les ouvrages qu'elles autorisent sont variés, et plus il devient rare d'inventer une forme entièrement nouvelle.

Cependant, superposer les appels réduit la lisibilité lorsque la chaîne s'allonge. Une expression comme mention(moyenne(somme_divisee_par(len(notes)))) devient illisible, et surtout impossible à tester séparément : si le résultat est faux, vous ne savez pas quel maillon a failli. La solution consiste à matérialiser les étapes intermédiaires dans des variables bien nommées, quitte à occuper deux lignes de plus. moy = moyenne(notes) puis lettre = mention(moy) offre trois avantages décisifs. Vous pouvez afficher la moyenne pour vérifier le calcul avant de passer à la mention, vous pouvez réutiliser la moyenne pour un autre usage, et vous pouvez nommer clairement chaque étape du raisonnement. Réservez l'imbrication aux cas courts et évidents, un ou deux appels imbriqués au maximum, et préférez toujours des variables intermédiaires dès que la chaîne comporte trois niveaux ou plus. Lisez ensuite votre expression à voix haute : si vous devez ajouter un et entre deux appels pour la comprendre, c'est qu'elle mérite d'être découpée en deux instructions nommées.

Un autre avantage de la composition est la réduction de la duplication. Lorsque deux fonctions ont besoin du même calcul intermédiaire, elles appellent la même fonction auxiliaire plutôt que de recopier son code. Si vous découvrez ensuite une erreur dans ce calcul, une seule correction suffit et se propage automatiquement à tous les appelants. Ce mécanisme est à l'origine de la qualité des bibliothèques standard : elles reposent sur des fonctions courtes qui appellent d'autres fonctions courtes, formant une pyramide où chaque niveau ne connaît que celui immédiatement inférieur. Pour votre part, une bonne organisation de script ressemble à une pyramide plate : main en haut, quelques fonctions de calcul au milieu, et si besoin de petites fonctions utilitaires en bas. Dès que vous avez l'impression de réécrire deux fois la même suite d'instructions, c'est le signal qu'une fonction commune mérite d'exister. Ce réflexe est d'ailleurs celui des bibliothèques standard, où de petites fonctions utilitaires reviennent constamment d'un fichier à l'autre.

Trois réflexes pratiques vous aideront à composer proprement. Premièrement, définissez les fonctions appelées avant celles qui les appellent, ou placez l'appel de démarrage tout à la fin du fichier, afin que chaque nom soit déjà enregistré. Deuxièmement, gardez des signatures cohérentes : si moyenne prend une liste de notes et renvoie un nombre, toute fonction qui l'appelle doit fournir une liste et récupérer un nombre, sans conversion cachée. Troisièmement, ne faites pas faire à une fonction deux responsabilités distinctes au prétexte qu'elles se touchent ; composez plutôt deux fonctions spécialisées. Vous obtiendrez alors un code où chaque ligne se lit indépendamment, où les erreurs se localisent en un coup d'œil, et où l'ajout d'une fonctionnalité consiste presque toujours à brancher une nouvelle brique existante. Prenez également l'habitude d'ouvrir votre fichier par la fonction main pour en dérouler la logique : si cette lecture ne suffit pas à raconter ce que fait le programme, c'est que le découpage manque d'un niveau. Un test rapide, une correction ponctuelle et un docstring court suffisent ensuite à maintenir chaque brique en bon état.

```python
def somme(notes):
    """Renvoie la somme de toutes les notes."""
    total = 0
    for note in notes:
        total = total + note
    return total
def moyenne(notes):
    """Renvoie la moyenne en déléguant le calcul de la somme."""
    return somme(notes) / len(notes)
def mention(moy):
    """Renvoie la lettre correspondant à une moyenne."""
    if moy > 16:
        return "A"
    elif moy > 14:
        return "B"
    elif moy > 12:
        return "C"
    else:
        return "D"
def bilan(notes):
    """Prépare le message complet à partir des seules notes."""
    moy = moyenne(notes)
    return "Moyenne : " + str(round(moy, 2)) + " sur 20, mention " + mention(moy)
print(bilan([12, 15, 9, 17, 14]))
print(bilan([18, 19, 16]))
```

L'exemple précédent montre quatre briques qui s'emboîtent. Somme ne connaît que l'addition, moyenne lui délègue ce travail et ne fait que diviser, mention traduit un nombre en lettre, et bilan n'utilise que les trois autres pour fabriquer une phrase prête à afficher. Notez que bilan retourne une chaîne au lieu d'afficher elle-même : la décision de présentation reste ouverte à l'appelant, qui peut imprimer, enregistrer ou traduire le message. La fonction round, également fournie par Python, limite l'affichage à deux décimales pour éviter une suite de chiffres parasites. Exécutez ce bloc : la première ligne affiche la moyenne 13.4 et la mention C, la seconde une moyenne de 17.67 et la mention A. Modifiez une note et observez comment le changement se propage de somme vers bilan sans toucher à une seule autre ligne. C'est exactement le comportement attendu : chaque fonction ne connaît que son contrat, et pourtant l'ensemble du traitement évolue au moindre changement de données d'entrée.
$lesson$),
  ('py-c3-p9', 'py-c3', 9, $lesson$Exemple guidé : moyenne, mention et main$lesson$, $lesson$
Voici le programme complet qui conclut ce chapitre. Il calcule la moyenne d'une liste de notes, en déduit une lettre de mention, puis affiche le bilan. Lisez d'abord la fonction main, qui résume l'intention de l'ensemble, puis descendez dans les deux fonctions de calcul qu'elle appelle. Cette lecture de haut en bas, du plus synthétique vers le plus détaillé, est exactement le réflexe que le découpage en fonctions rend possible : vous comprenez le programme sans encore savoir comment la moyenne est calculée. Cette page contient trois définitions et un appel final, rien de plus. Repérez d'abord les noms : moyenne transforme une liste en nombre, mention transforme un nombre en lettre, et main relie les deux puis commande l'affichage. Si vous deviez expliquer ce script à un camarade en une seule phrase, vous diriez qu'il calcule la moyenne de cinq notes et qu'il en donne la mention, ce qui est exactement le rôle de la fonction principale. Aucun commentaire n'est nécessaire pour comprendre l'enchaînement, car les noms choisis et les docstrings suffisent déjà à raconter l'histoire.

```python
def moyenne(notes):
    """Renvoie la moyenne arithmétique des notes reçues."""
    total = 0
    for note in notes:
        total = total + note
    return total / len(notes)
def mention(moy):
    """Transforme une moyenne numérique en lettre de mention."""
    if moy > 16:
        return "A"
    elif moy > 14:
        return "B"
    elif moy > 12:
        return "C"
    else:
        return "D"
def main():
    """Declare les notes, calcule la moyenne et affiche le bilan."""
    notes = [12, 15, 9, 17, 14]
    moy = moyenne(notes)
    lettre = mention(moy)
    print("Notes prises en compte :", notes)
    print("Moyenne :", moy)
    print("Mention :", lettre)
main()
```

La première fonction, moyenne, reçoit une liste de notes et renvoie un nombre. Son corps reprend directement la boucle apprise au chapitre 2 : on parcourt la séquence, on accumule chaque valeur dans une variable totale, puis on divise la somme par le nombre d'éléments avec la fonction intégrée len. Rien de nouveau dans la logique, seul le rangement a changé : le calcul vit désormais dans un bloc nommé. Vous pouvez remarquer que la version raccourcie total = sum(notes) / len(notes) produirait exactement le même résultat, la fonction sum faisant elle aussi partie des fonctions intégrées de Python ; la forme en boucle a l'avantage de montrer explicitement le lien avec le chapitre précédent. Notez également que nous supposons ici que la liste n'est jamais vide, car diviser par zéro provoquerait une erreur : la détection des entrées invalides relève des exceptions, que vous étudierez au chapitre 6. Pour l'instant, contentez-vous de fournir une liste contenant au moins une valeur.

La deuxième fonction, mention, transforme un nombre en une lettre et illustre parfaitement l'utilisation de plusieurs `return`. Chaque branche de la condition renvoie immédiatement une valeur et termine la fonction : si la moyenne dépasse 16, on renvoie A sans jamais examiner les cas suivants ; sinon, on teste le seuil de 14, puis celui de 12 ; sinon encore, on renvoie D. L'ordre des tests est essentiel : en plaçant d'abord la condition la plus exigeante, on évite d'imbriquer des conditions et on obtient une lecture descendante, du cas le plus favorable au cas par défaut. Les seuils sont stricts, comme l'énonce l'énoncé : supérieur à 16 donne A, supérieur à 14 donne B, supérieur à 12 donne C, tout le reste donne D. Une moyenne de 16 pile ne rentre donc pas dans A, mais dans B. Enfin, notez que le paramètre s'appelle moy et non notes : cette fonction ne travaille pas sur une liste, elle travaille sur un nombre déjà calculé, et son nom le dit.

La fonction main joue le rôle de chef d'orchestre. Elle déclare la liste de notes, saisie en dur comme le demande l'exercice, appelle moyenne, conserve le résultat dans une variable, appelle mention avec ce résultat, puis commande les trois affichages. Vous constatez que main ne contient aucune logique de calcul : elle assemble et présente. Cette séparation est la clé de tout le chapitre. Si demain vous voulez changer la manière d'afficher, vous modifiez uniquement main ; si vous découvrez une erreur dans le calcul de la moyenne, vous corrigez uniquement moyenne sans toucher à l'affichage. La dernière ligne, main(), lance le programme : elle est placée après toutes les définitions, ce qui garantit que chaque fonction existe déjà au moment où on l'appelle. Si vous souhaitez tester plusieurs jeux de notes, il vous suffira d'ajouter un paramètre à main et de placer ce paramètre dans l'appel final : le corps de la fonction restera inchangé, seules les données d'entrée varieront.

Suivons l'exécution pas à pas avec la liste proposée. Python commence par enregistrer les trois définitions, puis il atteint l'appel main(). La fonction locale notes prend les valeurs 12, 15, 9, 17 et 14 ; moyenne est appelée, son total devient successivement 12, 27, 36, 53 puis 67, et le `return` transmet 67 divisé par 5, soit 13.4. Cette valeur est rangée dans moy, puis envoyée à mention, qui teste 13.4 contre 16, contre 14, puis contre 12 : le troisième test réussit, et la fonction renvoie la chaîne C. Les affichages interviennent en dernier, puisque c'est la décision de main, et affichent la liste, 13.4 et C. Aucun `print` n'a été exécuté pendant les calculs : les fonctions de logique sont restées silencieuses, seules les fonctions de présentation se sont fait entendre. Insérez un `print` temporaire au milieu de moyenne pour voir exactement à quel moment le total intermédiaire prend sa valeur, puis retirez-le : c'est un excellent moyen de visualiser la façon dont Python circule d'une fonction à l'autre.

Cette structure vous permet de tester chaque brique isolément, sans relancer tout le programme. Remplacez la dernière ligne main() par des appels directs, par exemple print(moyenne([10, 20])) ou print(mention(17)), et vérifiez les résultats attendus à la main avant même de relancer l'interpréteur. Vous pouvez aussi tester les cas limites, qui sont souvent les plus révélateurs : moyenne([0, 20]) doit donner 10.0, mention(16) doit donner B, mention(12.01) doit donner C et mention(12) doit donner D. Ce travail de vérification, que l'on appelle tests, devient rapide et fiable précisément parce que le calcul est séparé de l'affichage : vous appelez une fonction, vous observez la valeur renvoyée, vous comparez à l'attendu. Aucun écran superflu, aucune donnée extérieure, aucune dépendance au reste du script. Rangez ces appels de vérification dans un fichier à part, ou commentez-les une fois les valeurs confirmées : ils constituent votre première suite de tests, et vous la ferez grossir au fur et à mesure du parcours.

La réutilisation est la dernière vertu de ce découpage. Une fois moyenne écrite et vérifiée, vous pouvez l'appeler dans un autre script, la brancher sur une liste saisie au clavier avec input et des conversions float, ou l'utiliser pour comparer deux classes. La fonction mention, indépendante de toute liste, s'appliquera à n'importe quelle moyenne, y compris une valeur lue dans un fichier au chapitre 5. Si vous ajoutez une nouvelle exigence, par exemple une médiane, vous écrirez une fonction mediane sans rien changer à moyenne ni à mention : le nouveau bloc rejoint la collection. C'est ainsi qu'un projet grandit sans devenir ingouvernable, et c'est exactement l'état d'esprit qui vous sera demandé dans le mini-projet final du parcours. N'oubliez pas non plus que ce découpage se lit aussi par-dessus : une personne qui ouvre votre fichier pour la première fois parcourt les en-têtes et les docstrings, saisit l'architecture globale, puis ne descend dans les détails que là où c'est nécessaire.

Observez enfin ce que ce programme ne fait pas : il ne valide pas ses entrées, il n'attrape aucune erreur, il ne lit aucun fichier et il n'utilise aucun module. Chacune de ces responsabilités correspond à un chapitre à venir. Les fonctions que vous venez d'écrire sont la fondation sur laquelle tout le reste s'appuiera : des listes au chapitre 4, des fichiers au chapitre 5, des exceptions au chapitre 6 et des modules au chapitre 7. Prenez le temps de retaper ce code à la main plutôt que de le copier, puis modifiez la liste de notes et relisez le résultat. L'objectif n'est pas d'obtenir trois lignes de sortie, mais d'intérioriser le mouvement suivant : déclarer, calculer, transmettre, afficher. Une fois ce réflexe acquis et solidement ancré, vous aborderez le chapitre suivant avec une question nouvelle : comment représenter efficacement des groupes de données à l'intérieur des fonctions que vous écrivez.
$lesson$),
  ('py-c3-p10', 'py-c3', 10, $lesson$À retenir$lesson$, $lesson$
- Une fonction regroupe un bloc réutilisable derrière un nom : on la définit avec `def`, puis on l'appelle autant de fois que nécessaire.
- Définir range la fonction en mémoire, appeler l'exécute : définir sans appeler ne produit aucun effet visible.
- `print()` est une fonction fournie par Python, comme `len()` ou `round()` : vous ne faites qu'écrire la vôtre.
- Un paramètre est le nom figurant dans la définition, un argument est la valeur envoyée lors de l'appel.
- L'ordre et le nombre des arguments doivent correspondre à ceux des paramètres, sans quoi Python lève une erreur.
- Une valeur par défaut, comme dans `def saluer(nom="ami")`, évite de multiplier les variantes d'une même fonction.
- Un argument par mot-clé, du type nom="Lina", précise à quel paramètre l'envoyer et supprime toute ambiguïté d'ordre.
- `return` transmet un résultat à l'appelant et met fin immédiatement à la fonction.
- Sans `return`, la fonction renvoie `None`, ce qui provoque une erreur plus tard si on l'utilise comme un nombre.
- L'affichage montre à l'utilisateur, le retour transmet au code : le calcul retourne, l'affichage se décide dans main.
- Une variable créée dans une fonction y est locale et disparaît dès la fin de l'appel.
- Une fonction qui fait une seule chose se teste, se corrige et se réutilise facilement, et un docstring court en explique le rôle.
$lesson$),
  ('py-c3-p11', 'py-c3', 11, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Oublier les deux-points à la fin de l'en-tête `def` → SyntaxError ; un en-tête de fonction se termine toujours par ` :` avant le corps indenté.
- Appeler une fonction avant sa définition dans le fichier → NameError ; placez toutes les définitions au-dessus du code principal ou appelez depuis une fonction main écrite à la fin.
- Utiliser `print` au lieu de `return` dans une fonction de calcul → la variable reçoit `None` et le programme plante plus loin ; renvoyez la valeur et affichez-la depuis main.
- Oublier `return` ou le placer après `print` → la fonction rend `None` sans prévenir ; vérifiez le type du résultat avec `type()` et corrigez l'ordre des instructions.
- Envoyer le mauvais nombre d'arguments ou les inverser → TypeError dans le premier cas, résultat faux dans le second ; relisez la signature et nommez les arguments pour lever l'ambiguïté.
- Attendre une valeur d'une fonction sans la récupérer par `return` → elle reste locale et disparaît ; stockez le retour dans une variable à l'appel.
- Modifier une variable extérieure depuis une fonction sans `global` → une nouvelle variable locale est créée et la globale reste inchangée ; préférez passer la donnée en paramètre et renvoyer le résultat.
- Placer le docstring après le code ou mal indenter le corps → SyntaxError ou documentation invisible ; le docstring se situe immédiatement après l'en-tête, indenté comme le reste du corps.
$lesson$),
  ('py-c3-p12', 'py-c3', 12, $lesson$Pour aller plus loin$lesson$, $lesson$
Le tutoriel officiel de Python consacre un chapitre complet à la définition des fonctions : il y détaille la syntaxe `def`, les arguments positionnels, les valeurs par défaut, les arguments par mot-clé et la distinction entre affichage et retour, avec de nombreux exemples exécutables. C'est la lecture la plus directe pour consolider ce que vous venez de pratiquer, et vous y retrouverez exactement les notions abordées dans ce chapitre, expliquées par l'équipe Python elle-même. Vous y trouverez notamment les arguments de longueur variable, les fonctions lambda et quelques exercices de synthèse qui prolongent naturellement cette leçon. Prenez le temps de taper les exemples dans votre interpréteur plutôt que de les lire passivement : une règle de langage ne se fixe vraiment que lorsqu'on l'applique à un cas que l'on a choisi soi-même. Le tutoriel suppose que vous maîtrisez les conditions et les boucles, ce qui est votre cas depuis le chapitre 2, et il n'exige aucune connaissance des structures de données, que vous découvrirez dans le chapitre suivant. Adressez-vous à : https://docs.python.org/fr/3/tutorial/controlflow.html#defining-functions

Pour les aspects plus formels, la référence du langage décrit la grammaire exacte des définitions de fonctions, les règles de portée des noms et le comportement précis de `return`, y compris les cas particuliers comme une fonction sans paramètre ou plusieurs retours dans une même fonction. Quant à la proposition d'amélioration numéro 8, elle rassemble les conventions de style adoptées par toute la communauté Python : noms de fonctions en bas de casse avec des underscores, docstrings soignées, espaces autour des opérateurs et la lisibilité placée avant tout. Gardez ces deux documents à portée de main, ils vous serviront dès vos premiers modules. La première lecture de la référence peut sembler aride : elle s'adresse en priorité à ceux qui cherchent une règle précise, et non un cours. Servez-vous-en plutôt comme d'un dictionnaire, à la manière d'un tableau de correspondance entre ce que vous observez dans un script et la règle officielle qui l'explique. Le PEP 8, lui, se lit d'une traite et propose de nombreux exemples de code commenté ; il constitue une excellente liste de vérification pour relire vos exercices avant de les soumettre. Adressez-vous à : https://docs.python.org/fr/3/reference/compound_stmts.html#function-definitions et https://peps.python.org/pep-0008/
$lesson$),
  ('py-c3-p13', 'py-c3', 13, $lesson$Et maintenant : la vidéo du chapitre$lesson$, $lesson$
La vidéo du chapitre reprend la même progression, mais en la montrant s'écrire sous vos yeux : la définition d'une fonction avec `def`, l'ajout de paramètres et de valeurs par défaut, puis le passage de `print` à `return` pour transformer un simple affichage en un résultat réellement réutilisable. Regardez-la en gardant à côté de vous le programme moyenne, mention, main de cette leçon, puis passez à l'exercice pratique qui vous demande d'écrire ces trois fonctions vous-même, avec une liste de notes saisie en dur : c'est là que les notions deviennent des réflexes. Ensuite, ferez varier cette liste pour vérifier que les mentions attendues apparaissent bien aux seuils de 16, 14 et 12, et le quiz final reprendra les quatre points essentiels du chapitre : le rôle de `def`, le comportement de `None` en l'absence de `return`, la différence entre paramètre et argument, et l'intérêt de séparer le calcul de l'affichage.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('py-c4-p1', 'py-c4', 1, $lesson$Comprendre : des données rangées pour les traiter$lesson$, $lesson$
Un programme qui calcule la moyenne de trois nombres tient en cinq lignes, et vous avez sûrement déjà écrit celui-ci sans difficulté. Un programme qui doit gérer les notes de trente élèves, les présences d'une semaine ou le catalogue d'une boutique, en revanche, ne tient plus dans une suite de variables nommées note1, note2, note3, et ainsi de suite jusqu'à note30. À ce stade du parcours, après avoir écrit des variables, des conditions, des boucles et des fonctions, vous rencontrez le quotidien réel du développeur : des données nombreuses, répétées, de même nature, qu'il faut ranger, chercher, trier et résumer sans jamais perdre le fil. C'est précisément l'objet de ce quatrième chapitre, qui constitue un jalon important du niveau Débutant. La bonne nouvelle, c'est que Python a été conçu pour ce travail : il propose deux structures de données si simples et si puissantes que la quasi-totalité des programmes les utilisent des milliards de fois par jour, la liste et le dictionnaire.

La liste vous servira à ranger une suite d'éléments dans un ordre explicite, du premier au dernier, et à les retrouver grâce à leur position. C'est la structure idéale pour tout ce qui forme une séquence : une playlist, un historique de mesures, une liste de courses, les lignes d'un tableau de résultats. Le dictionnaire, lui, ne répond pas par une position mais par un nom : au lieu de demander l'élément numéro 2, vous demandez la note attachée à l'élève Amina. Cette façon de nommer les informations transforme vos données en véritables fiches lisibles, dont le code se comprend presque comme du français, y compris six mois plus tard quand vous ouvrirez à nouveau ce projet. Enfin, les compréhensions de liste vous permettront de filtrer et de transformer une collection entière en une seule ligne, sans écrire de boucle apparente, tout en gardant un code net et rapide à relire. Ces trois outils constituent le cœur du chapitre.

Pourquoi cette organisation arrive-t-elle juste après les fonctions du chapitre 3 ? Parce qu'une fonction qui reçoit une liste ou un dictionnaire en paramètre devient un vrai outil réutilisable : une fonction moyenne(notes) fonctionne sur trois valeurs comme sur trois cents, du moment que les données sont bien rangées. Les structures de données et les fonctions se nourrissent donc mutuellement, et c'est leur combinaison qui vous mènera jusqu'au mini-projet final. L'objectif de ce chapitre est triple : savoir ajouter, trier et filtrer les éléments d'une liste ; savoir accéder et mettre à jour un dictionnaire par clé ; savoir écrire une compréhension de liste lisible. Vous verrez aussi comment les imbrications décrivent des objets réels, et comment une simple affectation peut créer un piège subtil avec les références. À la fin, vous serez prêt à lire ces données depuis un fichier au chapitre 5 et à gérer les erreurs de structure au chapitre 6.



Une liste est une collection ordonnée et modifiable, et ces deux mots résument tout son comportement. Ordonnée signifie que chaque élément possède une position, appelée index, qui commence à zéro et ne bouge pas tant que vous ne touchez pas à la liste. Modifiable signifie que vous pouvez ajouter, remplacer ou supprimer des éléments après la création, sans avoir à en réécrire une nouvelle : c'est ce qui distingue une liste d'une chaîne de caractères, elle aussi séquentielle mais immutable. On écrit une liste entre crochets, avec des virgules entre les éléments : notes = [14, 11, 18, 9]. Une liste peut contenir des nombres entiers, des nombres décimaux, des chaînes, des booléens et bien sûr d'autres listes. Elle peut aussi contenir des doublons : la valeur 14 peut apparaître deux fois, ce qui est parfaitement normal, par exemple pour les notes d'une classe où deux élèves ont obtenu la même mention.

Pour créer une liste, le plus simple est d'écrire ses éléments entre crochets, mais vous pouvez aussi partir de rien avec notes = [] puis remplir la liste au fil de l'exécution, ce qui est la méthode la plus courante dans un programme qui lit des données une par une. Il existe aussi la fonction list() qui copie une séquence existante, par exemple list("bonjour") qui produit ["b", "o", "n", "j", "o", "u", "r"], ou list(range(1, 6)) qui fabrique [1, 2, 3, 4, 5] à partir d'un intervalle. Retenez que la variable notes ne contient pas les valeurs elle-même : elle contient une référence vers un objet liste posé quelque part en mémoire. Cette nuance, anodine en apparence, explique la plupart des bugs de copie rencontrés plus loin dans ce chapitre. Tant que vous modifiez la liste avec ses méthodes, tout va bien ; le trouble commence quand vous l'affectez à une seconde variable en croyant la dupliquer.

L'ordre d'une liste n'est pas un détail de présentation, c'est une garantie d'accès, et il faut en comprendre les conséquences pratiques. Grâce à l'index, vous récupérez n'importe quel élément avec une écriture constante : notes[0] donne le premier, notes[1] donne le deuxième, notes[-1] donne le dernier, et notes[-2] l'avant-dernier. La fonction len(notes) vous donne le nombre d'éléments, et cet outil vous sert constamment, notamment pour calculer une moyenne ou pour vérifier qu'un index reste dans les bornes avant de l'utiliser. L'ordre préserve aussi la stabilité : si vous parcourez la liste avec une boucle for, l'élément A vient avant l'élément B à chaque exécution, ce qui rend vos résultats reproductibles d'un lancement à l'autre. Notez enfin qu'une liste peut être vide : elle possède alors un len() égal à 0, et c'est une situation tout à fait légitime, par exemple au début d'une accumulation ou après un filtre très restrictif.

Le dictionnaire suit une logique différente : il associe une clé à une valeur, comme une fiche cartonnée où chaque champ porte un nom précis. On l'écrit entre accolades, avec deux points entre clé et valeur : eleve = {"nom": "Amina", "note": 14}. Ici, "nom" et "note" sont des clés, tandis que "Amina" et 14 sont les valeurs correspondantes. Contrairement à la liste, le dictionnaire n'a pas d'ordre d'accès utile : on ne demande jamais l'élément numéro 1, on demande la valeur de la clé "nom". Les clés doivent être uniques, ce qui évite toute ambiguïté : si vous donnez deux fois la clé "note", la seconde valeur remplace silencieusement la première. Les clés doivent également être immuables : des chaînes, des nombres ou des tuples conviennent parfaitement, mais une liste ne peut pas servir de clé, car sa valeur pourrait changer après le stockage. Cette contrainte a un indéniable avantage : elle garantit qu'une recherche par clé ne dépend jamais de l'état d'un objet mutable, et que le dictionnaire reste cohérent même si ses valeurs évoluent au fil de l'exécution.

Décrire une entité avec un dictionnaire est un réflexe de programmeur expérimenté, car il rend le code auto-documenté. La ligne eleve = {"nom": "Amina", "notes": [14, 15]} se lit sans commentaire : il s'agit d'une personne et de ses résultats, sans avoir à deviner la signification d'une variable opaque comme a1. La valeur d'une clé peut être de n'importe quel type, y compris une liste : c'est ainsi qu'on représente un élève ayant passé plusieurs contrôles. Vous pouvez aussi imbriquer des dictionnaires dans des dictionnaires pour décrire des objets à plusieurs niveaux, par exemple un élève dont la clé "contacts" contient elle-même les clés "email" et "telephone". Cette capacité à composer des structures arborescentes est ce qui distingue les programmes jouets des programmes capables de représenter un vrai problème métier, comme un catalogue de produits ou un historique de commandes. Pensez-y comme à une fiche métier : les champs survivent aux réorganisations, se lisent aussi bien dans le code que dans les journaux d'exécution, et se prêtent merveilleusement bien à l'affichage tabulaire que vous construirez dans le mini-projet final.

Une distinction fondamentale guide toutes les opérations de ce chapitre : certaines méthodes modifient la structure sur place, d'autres en créent une nouvelle. La méthode notes.append(16) ajoute directement un élément à la liste existante, sans en retourner une autre : l'objet d'origine est transformé. À l'inverse, la fonction sorted(notes) laisse votre liste intacte et vous renvoie une copie triée, que vous devez affecter s'il vous faut la conserver. Comprendre cette frontière vous évite deux catégories d'erreurs : perdre le résultat d'une méthode qui renvoie None, ou croire qu'une structure a été modifiée alors qu'elle ne l'a pas été. Le même principe vaut pour les dictionnaires : d["note"] = 15 modifie le dictionnaire existant, tandis que la concaténation de deux listes avec l'opérateur plus produit un objet entièrement neuf, laissé libre à vous de l'utiliser ou non. Le meilleur moyen de trancher reste de se demander si la structure d'origine doit rester intacte pour un traitement ultérieur : si oui, préférez une opération qui renvoie un nouvel objet ; sinon, modifiez en place pour éviter une copie inutile.

Par ailleurs, listes et dictionnaires ne sont pas les seules structures de Python. La chaîne de caractères est séquentielle mais immutable, un tuple se comporte comme une liste qu'on ne peut plus modifier après sa création, et l'ensemble regroupe des valeurs uniques sans les ordonner. Ces trois formes répondent à des besoins précis : on crée un tuple pour figer une coordonnée, on transforme une liste en ensemble pour éliminer des doublons en un instant, et on découpe une chaîne comme on le ferait avec une liste. Vous les rencontrerez de plus en plus souvent au fil du parcours, et leurs règles de fonctionnement restent très proches de celles apprises ici : accès par index pour les séquences, méthode copy() pour les structures modifiables, et même logique de référence dès qu'une affectation entre en jeu. Le seul mot de prudence qui s'impose concerne la performance, un sujet que vous aborderez avec les modules : au-delà de quelques milliers d'éléments, la structure choisie commence à compter.

Les données ne prennent de la valeur que lorsqu'on les résume, et c'est là que tout votre apprentissage précédent se rejoigne. Une liste de notes brute ne vous dit presque rien tant que vous ne la parcourez pas pour en calculer la moyenne, le maximum, le nombre d'insuffisances ou la meilleure progression. C'est ici que réapparaissent les boucles du chapitre 2 et les fonctions du chapitre 3 : une boucle for parcourt la collection élément par élément, une fonction moyenne(notes) encapsule le calcul pour le rendre réutilisable, et le dictionnaire sert souvent à rassembler le résultat sous des libellés explicites comme {"moyenne": 13.4, "maximum": 18}. Le motif est toujours le même : vous partez d'une collection, vous la parcourez une fois, vous accumulez une ou deux valeurs de synthèse, puis vous restituez un dictionnaire de résultats. Ce schéma, que vous répèterez tout au long du parcours, se retrouve jusque dans l'analyseur de notes du chapitre 8.

Choisir entre liste et dictionnaire tient en une question simple : vos données forment-elles une suite ordonnée, ou un ensemble de champs nommés ? Si les éléments sont de même nature et que leur position a un sens, préférez la liste, par exemple notes = [14, 11, 18] pour une série de résultats. Si chaque élément porte plusieurs informations que vous voulez nommer, préférez le dictionnaire, par exemple {"nom": "Amina", "note": 14} pour une fiche. Si vous devez décrire plusieurs personnes, combinez les deux : une liste de dictionnaires, qui se lit comme un tableau dont chaque ligne est un enregistrement homogène. Cette combinaison est tellement courante qu'elle devient le format de prédilection pour représenter un résultat d'analyse. En pratique, la plupart des programmes alternent constamment entre les deux : on lit une liste, on transforme chaque élément en dictionnaire, on trie, on filtre, puis on restitue une nouvelle liste.

Le modèle mental le plus utile consiste à se représenter une liste comme une rangée de cases numérotées, qu'on ouvre par leur numéro, et un dictionnaire comme un tiroir de fiches, qu'on ouvre par l'étiquette écrite dessus. Ce changement de métaphore a des conséquences très concrètes : dans la rangée, déplacer une case en modifie toutes les suivantes, alors que dans le tiroir, ajouter une fiche ne dérange aucune autre. Une bonne pratique consiste à standardiser vos clés et vos noms de variables dès le début du projet : si vous écrivez "nom" et "note" au premier enregistrement, n'employez jamais "nom_complet" ou "Note" ailleurs, car une différence de casse ou d'accroche crée une entrée différente que personne ne vous signalera. Ces réflexes de rigueur, adoptés tôt, vous feront gagner un temps considérable lors des phases de débogage. Gardez ensuite les règles suivantes sous la main, elles rythment toutes les manipulations de ce chapitre :

- Une liste est ordonnée, modifiable, et peut contenir des doublons ainsi que des éléments de types différents.
- Le premier élément d'une liste porte l'index 0, le dernier peut se lire avec l'index -1.
- La fonction len() donne le nombre d'éléments et permet de contrôler les bornes avant tout accès par index.
- La méthode append() ajoute un élément à la fin de la liste, c'est le moyen le plus rapide de l'agrandir.
- Un dictionnaire associe une clé unique à une valeur ; donner deux fois la même clé écrase la première valeur.
- On lit une valeur avec d["cle"] et on écrit avec d["cle"] = valeur.
- L'expression "cle" in d teste la présence d'une clé, jamais celle d'une valeur.
- La méthode items() fournit des paires clé-valeur idéales pour une boucle for à deux variables.
- Modifier une structure sur place agit immédiatement sur la variable, tandis que sorted() ou l'opérateur plus créent un nouvel objet.
- Une affectation comme b = a ne copie pas une liste : elle crée un second nom pointant vers le même objet.

Choisir entre liste et dictionnaire est un exercice qui devient rapide dès que vous acceptez de poser la question avant d'écrire la moindre ligne. Beaucoup de débutants construisent d'abord la structure, puis se rendent compte qu'ils doivent chercher un élément par son nom ou, à l'inverse, le traiter dans l'ordre de réception. Ce retour en arrière coûte toujours plus cher qu'une réflexion de trente secondes en amont. Prenez également l'habitude de décrire votre besoin à voix haute, comme si vous expliquiez le problème à un collègue : si votre phrase commence par alors il faut ranger, une liste s'impose ; si elle commence par il me faut le champ, un dictionnaire s'impose. Cette reformulation en français naturel est souvent plus décisive qu'un long examen de la documentation, et elle vous accompagnera bien au-delà de ce chapitre, y compris lors du mini-projet. Une fois ce choix posé, suivez ce raisonnement en trois temps :

1. Mes données forment-elles une suite où la position compte ? Alors utilisez une liste, et pensez à la trier ou la filtrer selon le besoin.
2. Un élément mêle-t-il plusieurs informations à nommer ? Alors utilisez un dictionnaire, une clé par champ, en veillant à nommer ces clés de façon constante.
3. Dois-je décrire plusieurs éléments de ce type ? Alors utilisez une liste de dictionnaires, chaque ligne représentant un enregistrement complet.

```python
notes = [14, 11, 18, 9]
print(notes[0], notes[-1])
print(len(notes))
eleve = {"nom": "Amina", "note": 14}
print(eleve["nom"])
eleve["notes"] = [14, 15]
print(eleve)
```
$lesson$),
  ('py-c4-p2', 'py-c4', 2, $lesson$Les opérations de base sur les listes$lesson$, $lesson$
Ajouter un élément est l'opération la plus fréquente, et elle se fait avec append(). Cette méthode place systématiquement la nouvelle valeur à la fin de la liste, sans jamais modifier l'ordre des éléments déjà présents : si vous aviez [14, 11] et que vous appelez notes.append(18), vous obtenez [14, 11, 18]. Elle renvoie None, car son seul rôle est de transformer la liste, pas de vous donner un résultat à conserver. C'est pourquoi on l'appelle une méthode de modification en place. Concrètement, quand vous lisez les notes d'une classe une par une, vous écrivez une boucle qui appelle notes.append(note) à chaque tour, et la liste grossit doucement jusqu'à contenir l'ensemble des inscrits. Retenez cette phrase, elle revient dans le quiz du chapitre : append() ajoute en fin. Cette précision distingue append() de insert(), qui permet au contraire de choisir la position d'insertion, et évite bien des surprises lors de la lecture du code.

Insérer et supprimer donnent un contrôle plus fin sur la composition de la liste. La méthode notes.insert(1, 15) place la valeur 15 à l'index 1, ce qui décale vers la droite tous les éléments suivants : c'est l'opération à utiliser quand l'ordre initial doit être respecté à la lettre, par exemple pour classer des dossiers reçus. Pour supprimer, vous disposez de trois approches complémentaires. La méthode notes.remove(11) cherche la valeur 11 et efface la première occurrence trouvée, en laissant les doublons intacts ; si la valeur est absente, Python lève une erreur ValueError, que vous apprendrez à anticiper au chapitre 6. La méthode notes.pop() sans argument retire et renvoie le dernier élément, tandis que notes.pop(0) retire et renvoie celui d'index 0 : elle convient donc très bien pour traiter une liste comme une file d'attente. Enfin, del notes[2] supprime directement l'élément d'index 2 sans en renvoyer la valeur, ce qui est la syntaxe la plus rapide quand vous n'avez pas besoin du contenu supprimé.

Chercher dans une liste repose sur trois outils complémentaires, dont il faut connaître les limites. L'expression 14 in notes renvoie un booléen et vous indique si la valeur est présente, sans lever d'erreur si elle est absente : c'est le test à préférer dans la grande majorité des cas. La méthode notes.index(14) renvoie, elle, la position de la première occurrence ; attention, si la valeur manque, elle lève une ValueError contrairement à l'opérateur in, ce qui impose de tester avant d'indexer. La méthode notes.count(14) vous dit combien de fois la valeur apparaît, utile pour repérer les doublons ou construire un histogramme simple. À ces outils s'ajoute la découpe, ou slicing : notes[1:4] extrait les éléments d'index 1, 2 et 3, en excluant l'index 4 de façon systématique. La découpe renvoie toujours une nouvelle liste, elle ne modifie jamais l'originale, et elle accepte une troisième valeur pour le pas, par exemple notes[0:6:2] qui prend un élément sur deux.

Deux opérateurs méritent d'être connus sans en abuser, car ils créent tous les deux un nouvel objet. L'opérateur plus concatène deux listes : [1, 2] + [3] donne [1, 2, 3], sans modifier aucun des deux opérandes. L'opérateur étoile répète une liste : [0] * 5 donne [0, 0, 0, 0, 0], ce qui est commode pour initialiser une grille ou un tableau de zéros à remplir ensuite. Pour les statistiques de base, Python fournit les fonctions len(), min(), max() et sum(), qui s'appliquent directement à une liste de nombres dont le résultat est immédiatement exploitable : la moyenne se calcule en un rien de temps avec sum(notes) / len(notes). Préférez ces fonctions natives à des boucles manuelles, elles sont plus courtes, plus lisibles et nettement plus rapides, car leur boucle interne est implémentée en C dans l'interpréteur lui-même. N'optimisez pas à l'aveugle, mais sachez que remplacer une boucle Python par l'une de ces fonctions intégrées est l'un des gains de performance les plus simples qui soient, sans jamais nuire à la lisibilité du code.

La bonne pratique consiste à traiter une liste comme une boîte que vous manipulez par ses méthodes, et non comme une valeur que vous reconstruisez à chaque fois. Pour ajouter un élément, append(). Pour insérer à un endroit précis, insert(). Pour retirer par valeur, remove(). Pour extraire une tranche, la syntaxe entre crochets. Pour compter, len(). Chaque cas a une écriture idéale, et utiliser la bonne au bon moment est ce qui distingue un code de débutant d'un code sûr. Une seule méfiance s'impose : plusieurs méthodes de modification renvoient None, notamment sort(), reverse(), append() et clear(). Les affecter à une variable, comme trié = notes.sort(), vous laisse une variable égale à None qui provoquera une erreur déroutante beaucoup plus loin dans le programme. Le remède tient en une ligne : n'affectez jamais le résultat d'une méthode qui modifie la structure. Si vous avez besoin d'un résultat, écrivez l'appel sur sa propre ligne, puis utilisez la liste elle-même : cette habitude élimine d'un seul geste toute une famille d'erreurs silencieuses, les plus détestables qui soient, car elles ne se manifestent que beaucoup plus loin.

```table
Méthode | Effet sur la liste | Valeur retournée
--- | --- | ---
`append()` | ajoute la nouvelle valeur à la fin, sans modifier l'ordre des éléments déjà présents | `None`
`insert()` | place la valeur à l'index choisi et décale vers la droite les éléments suivants | non précisée
`remove()` | efface la première occurrence de la valeur cherchée, en laissant les doublons intacts | non précisée
`pop()` | retire le dernier élément, ou celui de l'index donné en argument | l'élément retiré
`del notes[2]` | supprime l'élément d'index 2 | aucune, la valeur n'est pas renvoyée
```

```python
notes = []
notes.append(14)
notes.append(11)
notes.append(18)
notes.insert(1, 15)
print(notes)
notes.remove(11)
derniere = notes.pop()
print(notes, derniere)
print(len(notes), 15 in notes, notes.count(14))
```
$lesson$),
  ('py-c4-p3', 'py-c4', 3, $lesson$Trier, filtrer, extraire$lesson$, $lesson$
Trier une liste se fait de deux manières très différentes, et les confondre est une erreur classique de débutant. La méthode notes.sort() trie la liste sur place, c'est-à-dire qu'elle réorganise directement l'objet existant, et elle renvoie None. La fonction sorted(notes), en revanche, laisse la liste d'origine intacte et vous renvoie une nouvelle liste triée, prête à être affichée ou passée à une fonction. Toutes deux utilisent le même algorithme et le même ordre par défaut : les nombres du plus petit au plus grand, les chaînes dans l'ordre alphabétique selon leur valeur Unicode. Si vous voulez conserver le tri, écrivez notes.sort() sans affectation, ou trié = sorted(notes) si vous avez besoin de préserver la liste brute pour une comparaison ou un second traitement. Dans un programme d'analyse de notes, cette seconde option est souvent préférable : vous gardez les notes dans l'ordre d'appel et vous produisez une version triée uniquement pour l'affichage.

Le tri s'adapte à vos besoins grâce à deux paramètres complémentaires. Avec reverse=True, l'ordre est inversé, ce qui donne immédiatement les notes décroissantes : sorted(notes, reverse=True) place le maximum en tête de liste, idéal pour afficher un podium. Avec la clé key, vous triez selon une fonction de transformation appliquée à chaque élément. Par exemple, sorted(noms, key=str.lower) classe des prénoms indépendamment de la casse, ce qui évite de placer toutes les majuscules avant toutes les minuscules, un défaut classique du tri par défaut sur du texte. Le paramètre key accepte toute fonction à un argument : len pour trier par longueur, une lambda pour une règle personnalisée, ou encore dict.get quand on trie une liste de dictionnaires, comme dans l'exemple guidé de ce chapitre. L'important est de comprendre que la fonction key est appelée une fois par élément pour produire une valeur de comparaison, sans jamais modifier les données elles-mêmes.

Filtrer, c'est sélectionner les éléments qui satisfont une condition, et la méthode classique reste indispensable à maîtriser. Elle consiste à créer une liste vide, à parcourir la source avec une boucle for, à tester chaque élément avec une condition if, puis à appeler append() si le test est vrai. Ce code est correct, explicite, et vous devez savoir l'écrire : il montre exactement ce que fait Python à chaque étape, ce qui facilite grandement le débogage quand une condition se révèle trop large ou trop étroite. Le résultat est toujours une nouvelle liste, la collection d'origine restant parfaitement intacte, si bien que vous pouvez la filtrer plusieurs fois avec des critères différents. Ce motif d'accumulation conditionnelle est tellement répandu que Python lui consacre une syntaxe raccourcie, la compréhension de liste, que nous étudierons en détail plus loin : [n for n in notes if n >= 10]. Les deux écritures produisent exactement le même contenu, mais la seconde tient en une ligne.

Extraire des informations se fait avec les fonctions statistiques et avec la découpe, qui travaillent toutes sans modifier la source. min(notes) et max(notes) vous donnent les valeurs extrêmes, sum(notes) la somme, len(notes) l'effectif, et le quotient sum(notes) / len(notes) la moyenne exacte. Pour regarder une portion de la liste, utilisez la syntaxe entre crochets : notes[0] pour le premier élément, notes[-1] pour le dernier, notes[1:4] pour la tranche centrale, et notes[:3] pour les trois premiers, la borne de fin étant facultative. Ces extractions renvoient toujours des listes neuves, vous pouvez donc les trier, les filtrer ou les afficher sans jamais risquer d'altérer la collection de départ. Un conseil de lecture : quand vous manipulez plusieurs listes dérivées, nommez-les explicitement, par exemple notes_triees ou admissibles, plutôt que de réutiliser une variable générique comme nouvelle_liste qui finit par perdre tout sens dès que le programme s'allonge. Le débogueur, notamment, affiche ces noms tels quels, sans contexte ni explication.

Le tri possède enfin des limites qu'il vaut mieux connaître avant de les rencontrer. Trier une liste mélangeant nombres et chaînes, par exemple [12, "dix", 5], provoque une erreur TypeError : Python ne sait pas comparer un nombre à un texte, et refuse donc d'ordonner le tout. De même, trier une liste de dictionnaires sans préciser de clé key ne donne aucun sens, car l'ordre entre deux fiches n'existe pas. Pour un dictionnaire, la parade la plus simple reste sorted(d), qui classe ses clés et renvoie une liste prête à l'emploi. Sachez aussi que le tri de Python est stable : deux éléments égaux conservent leur ordre relatif d'origine, ce qui permet des tris successifs, d'abord par matière puis par note, sans jamais remettre en cause le premier critère. Cette stabilité, discrète, est une vraie aide à la lecture des résultats, et vous pouvez vous y fier pour construire des tris successifs sans jamais reprendre le premier critère.

```python
notes = [12, 9, 17, 14, 9, 18]
notes.sort()
print(notes)
print(sorted(notes, reverse=True))
print(min(notes), max(notes), sum(notes), len(notes))
print(sum(notes) / len(notes))
print(notes[0], notes[-1], notes[1:4])
admissibles = []
for n in notes:
    if n >= 10:
        admissibles.append(n)
print(admissibles)
```
$lesson$),
  ('py-c4-p4', 'py-c4', 4, $lesson$Dictionnaires : clés, valeurs, items$lesson$, $lesson$
Un dictionnaire se déclare entre accolades, avec des paires clé-valeur séparées par des virgules : eleve = {"nom": "Amina", "note": 14}. Pour repartir de zéro, écrivez d = {}, car la fonction dict() sans argument, elle aussi, produit un dictionnaire vide. Deux règles régissent les clés et méritent d'être gravées. Premièrement, une clé est unique : si vous écrivez deux fois la clé "note", la seconde valeur écrase silencieusement la première, sans le moindre message d'erreur. Deuxièmement, une clé doit être immuable : une chaîne, un nombre ou un tuple conviennent, mais une liste est refusée car son contenu pourrait changer après le stockage, ce qui rendrait la clé introuvable. Les valeurs, elles, n'ont aucune restriction : elles peuvent être des nombres, des chaînes, des booléens, des listes, voire d'autres dictionnaires. C'est cette liberté qui permet de décrire des objets complexes avec une seule structure. À l'inverse, si vos données sont homogènes et sans nom, une liste restera plus légère et plus simple à parcourir qu'un dictionnaire dont les clés répéteraient inlassablement les mêmes mots.

Lire et écrire une valeur utilise la même syntaxe, ce qui rend le dictionnaire très simple à manipuler : d["note"] pour lire, d["note"] = 15 pour écrire. L'affectation crée la clé si elle n'existe pas encore et la remplace si elle existe déjà, ce qui en fait l'outil universel de mise à jour. Attention en revanche à la lecture d'une clé absente : d["absente"] lève une erreur KeyError, qui arrête le programme net et empêche tout ce qui suit. C'est une protection, pas un caprice du langage : Python refuse de deviner ce que vous vouliez dire quand le nom demandé n'existe pas. Pour interroger une clé dont l'existence est incertaine, la méthode get() est votre alliée : d.get("absente") renvoie None, et d.get("absente", "non renseignee") renvoie la valeur de remplacement que vous indiquez en second argument. C'est particulièrement pratique pour afficher un bulletin complet sans risquer de planter si un champ a été oublié lors de la saisie.

Tester la présence d'une clé s'exprime avec l'opérateur in : "nom" in eleve renvoie True, et cette expression porte uniquement sur les clés, jamais sur les valeurs. Chercher une valeur demanderait de parcourir d.values() entièrement, ce qui est plus coûteux et beaucoup moins naturel. Autres outils de base : len(d) donne le nombre de paires, d.keys() fournit la liste des clés, d.values() celle des valeurs, et les trois s'utilisent dans une boucle for ou avec sorted() pour un affichage ordonné. La méthode d.update({"note": 16, "rang": 3}) fusionne en une seule fois plusieurs paires, ce qui est commode pour appliquer un lot de modifications sans répéter l'affectation. Pour supprimer une entrée, utilisez del d["note"] si vous êtes sûr de la clé, ou d.pop("note", None) si vous voulez éviter l'erreur quand elle est absente, la seconde forme renvoyant alors None au lieu de lever une exception. Quel que soit l'outil choisi, lisez toujours le type de retour attendu : une méthode de suppression renvoie parfois la valeur retirée, parfois rien du tout, et cette différence change la façon dont vous écrivez la ligne suivante.

La méthode d.items() est la porte d'entrée du parcours de dictionnaires : elle produit des paires clé-valeur que la boucle for peut décomposer directement en deux variables, nom et note. Cette écriture se lit presque comme du français et supprime tout appel manuel à d[key] à l'intérieur de la boucle, ce qui allège considérablement le corps du traitement. Elle est d'autant plus précieuse que les dictionnaires modernes conservent l'ordre d'insertion : si vous ajoutez les élèves dans l'ordre alphabétique, ils s'affichent dans cet ordre, sans tri supplémentaire. Attention toutefois, cet ordre n'est pas celui d'un tri automatique : il reflète simplement votre chronologie d'écriture. Si vous voulez un ordre alphabétique garanti quoi qu'il arrive, appliquez sorted() sur les clés, par exemple sorted(d) pour obtenir la liste des noms classée, puis reconstruisez ou affichez les valeurs dans cet ordre. Cette petite gymnastique suffit pour un affichage alphabétique sûr et immédiatement explicable, sans jamais toucher au dictionnaire d'origine.

Un dictionnaire se comporte comme une fiche que l'on remplit progressivement, puisque chaque étape de sa vie suit le même schéma : créer, écrire, lire, tester, parcourir. On commence par créer la structure, on ajoute les champs au fur et à mesure, on corrige une valeur devenue obsolète, on supprime un champ inutile, puis on parcourt l'ensemble pour produire un affichage ou un calcul. Une bonne pratique consiste à standardiser vos clés dès le début du projet : si vous choisissez "nom" et "note", n'écrivez jamais "nom_complet" ou "Note" ailleurs dans le code, car une clé différente crée une entrée différente et le dictionnaire ne vous préviendra pas. Une convention de nommage stricte, appliquée à tous les enregistrements, est ce qui rend un traitement de données fiable sur la durée, surtout lorsque plusieurs personnes contribuent au même script. C'est aussi ce qui rend la relecture d'un ancien projet si rapide.

Un dernier usage du dictionnaire mérite d'être signalé dès maintenant, car il change la façon d'écrire des conditions : la table de correspondance. Plutôt que d'empiler des if, des elif et des else pour traduire une mention en une phrase, vous décrivez une fois pour toutes le dictionnaire {"admis": "félicitations", "ajourne": "rattrapage"} puis vous demandez table[mention]. Le résultat est plus court, plus clair, et l'ajout d'une nouvelle mention ne demande qu'une ligne supplémentaire au lieu d'une branche entière. Ce motif se généralise : codes postaux et villes, noms de couleurs et valeurs hexadécimales, clés d'API et fonctions de traitement. Retenez néanmoins que l'accès par clé suppose que la clé existe : dans un tel cas, la méthode get() avec une valeur de repli reste votre meilleure assurance contre les données inattendues. Vous gagnerez en robustesse bien avant de penser à la performance, et votre code restera plus court qu'une longue cascade de conditions imbriquées.

```table
Écriture | Ce qu'elle fait | Clé absente
--- | --- | ---
`d["note"]` | lit la valeur attachée à la clé | lève une erreur `KeyError` qui arrête le programme
`d["note"] = 15` | écrit la valeur : crée la clé si elle manque, la remplace sinon | la clé absente est créée
`d.get("note")` | interroge une clé dont l'existence est incertaine | renvoie `None` au lieu de lever une erreur
`d.get("note", "non renseignee")` | renvoie la valeur de remplacement donnée en second argument | renvoie cette valeur de remplacement
`d.pop("note", None)` | supprime l'entrée et évite l'erreur quand la clé manque | renvoie `None` au lieu de lever une exception
`d.keys()`, `d.values()`, `d.items()` | fournissent les clés, les valeurs et les paires clé-valeur à parcourir | non concernées
```

```python
eleve = {"nom": "Amina", "note": 14}
print(eleve["nom"])
eleve["note"] = 15
eleve["present"] = True
print(eleve)
print("nom" in eleve, "absente" in eleve)
print(eleve.get("absente", "non renseignee"))
del eleve["present"]
```

```python
classe = {"Amina": 14, "Bruno": 9, "Chloe": 17}
for nom, note in classe.items():
    if note >= 10:
        print(nom, note, "admis")
print(len(classe), sorted(classe))
```
$lesson$),
  ('py-c4-p5', 'py-c4', 5, $lesson$Imbrication : des listes et des dictionnaires imbriqués$lesson$, $lesson$
La vraie puissance des structures apparaît quand on les compose, car les valeurs d'un dictionnaire peuvent elles-mêmes être des listes. On écrit alors {"nom": "Amina", "notes": [14, 15]} pour décrire un élève ayant passé plusieurs contrôles, et cette écriture reste d'une lisibilité remarquable : on sait immédiatement qu'Amina possède une collection de résultats, et on peut l'agrandir sans toucher au reste de la fiche avec eleve["notes"].append(16). À l'inverse, une liste peut contenir des dictionnaires, ce qui donne un tableau dont chaque ligne est un enregistrement homogène : [{"nom": "Amina", "note": 14}, {"nom": "Bruno", "note": 9}]. C'est le format que vous utiliserez tout au long de ce chapitre et du mini-projet final, car il se transpose naturellement vers les fichiers tabulés du chapitre 5 et vers n'importe quel tableau de bord. Retenez que l'imbrication ne change aucune règle : elle ne fait que les multiplier. Le seul piège nouveau tient à la profondeur : plus les niveaux s'empilent, plus il est facile de se tromper de chemin, d'où l'utilité de conserver un petit jeu d'exemple tant que vous apprenez.

L'accès à une valeur imbriquée suit le chemin des clés et des index, de gauche à droite. Pour lire la deuxième note d'Amina dans eleve = {"nom": "Amina", "notes": [14, 15]}, vous écrivez eleve["notes"][1] : on ouvre d'abord le dictionnaire avec la clé "notes", puis on ouvre la liste obtenue avec l'index 1. Chaque crochet ouvre un niveau, et chaque niveau doit être du bon type : si "notes" contenait un nombre au lieu d'une liste, l'indexation provoquerait une erreur TypeError. Ce chemin unique est aussi ce qui rend les structures fragiles si les données sont incomplètes, d'où l'importance, au chapitre 6, d'apprendre à vérifier un type ou à utiliser get() avant d'approfondir un accès. Pour écrire, le schéma est identique : eleve["notes"][0] = 15 remplace la première note, et eleve["notes"].append(18) l'agrandit sans jamais recréer la liste. Lisez toujours le chemin de gauche à droite et demandez-vous, à chaque crochet, si vous ouvrez un dictionnaire ou une liste : ce réflexe suffit à déchiffrer n'importe quelle structure imbriquée, aussi profonde soit-elle.

Parcourir une liste de dictionnaires suit toujours le même rythme : une boucle for sur la liste, puis un accès par clé à l'intérieur de la boucle. Le corps du traitement reste ainsi très court, car tout le travail d'itération est pris en charge par la structure elle-même. C'est exactement ce que fera l'exemple guidé de ce chapitre : une boucle pour sommer les notes, une autre pour repérer le maximum, une compréhension pour retenir les noms au-dessus de la moyenne. Notez que cette architecture sépare nettement les données, la liste de dictionnaires, et la logique, les fonctions et boucles qui les analysent. Cette séparation est précieuse : vous pourrez remplacer la source de données par un fichier lu au chapitre 5 sans réécrire une seule ligne de traitement, et tester votre algorithme sur un petit échantillon avant de le lancer sur la classe entière. Cette séparation est la condition de toute évolution sereine : elle vous permet de changer de source de données sans jamais toucher à la logique de calcul.

Pour sécuriser une structure imbriquée, gardez deux réflexes permanents. Le premier consiste à nommer les niveaux avec des clés explicites, car eleve["infos"][0][2] devient illisible après quelques semaines, alors que eleve["identite"]["prenom"] se devine au premier coup d'œil et se corrige facilement. Le second consiste à documenter la structure attendue au début du programme, sous forme d'exemple concret en commentaire, afin que toute personne qui rejoint le projet sache quelles clés sont disponibles et de quel type est chaque valeur. Vous pouvez aussi consolider une entrée à la volée avec eleve.setdefault("notes", []) avant d'appeler append : la clé est alors créée avec une liste vide si elle manque, et votre ligne de code reste identique quel que soit l'état de la donnée d'entrée. Vous découvrirez au chapitre 6 une alternative plus stricte, les exceptions, mais cette habitude de consolider la structure avant de la remplir reste un excellent réflexe de prévention, que vous retrouverez dans tous les scripts bien écrits.

L'imbrication se prête également très bien au comptage, une opération que vous rencontrerez dans presque tous les programmes de traitement. Pour connaître le nombre d'élèves ayant obtenu chaque note, on initialise un dictionnaire vide, puis on parcourt la liste : si la note est déjà utilisée comme clé, on incrémente sa valeur, sinon on la crée avec la valeur un. Ce motif, que vous écrirez certainement en compréhension plus tard, transforme une collection en répartition, et il illustre parfaitement le rôle de complémentarité entre les deux structures : la liste donne l'ensemble des enregistrements, le dictionnaire mémorise les résultats intermédiaires associés à des noms explicites. Faites attention à ne pas utiliser la méthode setdefault de façon abusive dans une boucle très longue, et préférez une logique if claire quand vous apprenez : la lisibilité du compte vaut bien deux lignes de plus. Ce compteur vous sera demandé dans presque tous les exercices de statistique.

```python
eleve = {"nom": "Amina", "notes": [14, 15]}
eleve["notes"].append(18)
print(eleve["notes"])
print(eleve["notes"][1])
classe = [
    {"nom": "Amina", "note": 14},
    {"nom": "Bruno", "note": 9},
    {"nom": "Chloe", "note": 17},
]
total = 0
for e in classe:
    total = total + e["note"]
print(total / len(classe))
```
$lesson$),
  ('py-c4-p6', 'py-c4', 6, $lesson$Compréhensions de liste lisibles$lesson$, $lesson$
La compréhension de liste condense une boucle et son filtre en une seule ligne, et c'est l'une des écritures les plus appréciées de Python dès qu'on la maîtrise. La forme complète s'écrit [expression for element in sequence if condition], et elle produit exactement le même résultat qu'une boucle for suivie d'un append(). Prenez notes = [12, 9, 17, 14] et demandez la liste des notes admissibles : la boucle classique demande quatre lignes, la compréhension tient en une, [n for n in notes if n >= 10]. L'objectif n'est pas de faire court à tout prix, mais de dire ce que vous voulez obtenir plutôt que la manière dont vous allez le construire. C'est cette déclaration d'intention qui rend la syntaxe si claire une fois le réflexe pris, et la rédaction d'une compréhension lisible fait d'ailleurs l'objet d'un objectif explicite de ce chapitre. Relisez la ligne à voix haute : si vous devez vous reprendre en cours de route, elle est probablement trop longue.

L'ordre de lecture d'une compréhension est contre-intuitif au début, alors fixez-le une bonne fois pour toutes : on lit de droite à gauche, mais on écrit de gauche à droite. On lit d'abord le mot for, qui indique la source, puis le in qui nomme cette source, ensuite le if qui filtre, et enfin l'expression de tête qui décrit ce qui doit être stocké dans la nouvelle liste. Autrement dit, le résultat est écrit en premier, la règle ensuite, ce qui correspond exactement à la façon dont vous formuleriez la demande à un collègue : donne-moi les notes, celles d'au moins dix. Pour transformer chaque note en pourcentage, vous écrivez [n * 100 / 20 for n in notes] ; pour ne garder que les noms des admis, [e["nom"] for e in classe if e["note"] >= 10] ; pour obtenir des phrases prêtes à afficher, vous enrichissez simplement l'expression de tête avec un formatage.

Les compréhensions se déclinent aussi pour les dictionnaires et les ensembles, avec une syntaxe voisine qui élargit considérablement votre jeu d'outils. Une compréhension de dictionnaire s'écrit entre accolades, par exemple {e["nom"]: e["note"] for e in classe}, et elle construit un dictionnaire qui associe chaque nom à sa note : l'accès par nom devient alors immédiat, au prix d'une perte d'ordre d'origine. Une compréhension d'ensemble s'écrit également entre accolades, mais sans paires clé-valeur : {e["note"] for e in classe} élimine les doublons et vous donne instantanément la liste des notes réellement observées, ce qui est très utile pour vérifier la diversité des résultats. Il existe enfin la compréhension de générateur, écrite entre parenthèses, qui ne construit rien en mémoire mais produit les valeurs à la demande, idéal quand la suite est très longue. Pour ce chapitre, maîtrisez la forme en liste : les autres vous viendront naturellement ensuite. Notez enfin que chaque forme renvoie un itérable, ce qui signifie qu'on peut les enchaîner pour construire des transformations successives d'une grande concision.

La lisibilité reste la règle absolue, et elle passe avant le gain de place. Une compréhension convient quand la règle tient en une ligne et se lit à voix haute : pour chaque élève, s'il est admis, son nom. Dès que vous devez imbriquer deux conditions, appliquer plusieurs transformations ou gérer des cas particuliers, revenez à une boucle for explicite, bien plus facile à déboguer pas à pas. Autre piège à connaître : la variable d'accumulation disparaît, mais le coût mémoire reste. Une compréhension construit toute la liste en mémoire d'un coup, ce qui pose problème sur des millions d'éléments ; dans ce cas, privilégiez une boucle qui traite une donnée à la fois ou une compréhension de générateur. Enfin, gardez les noms de variables courts, comme n, e ou nom : ils n'existent que le temps de la compréhension et n'empiètent pas sur le reste du programme. En cas de doute sur la portée d'une variable, sortez de la compréhension et vérifiez que votre éditeur ne signale aucun nom résiduel oublié.

Appliquons ces règles à un cas concret pour bien ancrer la réflexe. Sur une classe de dictionnaires, vous voudrez sans doute la liste des noms des élèves admis, la liste des notes triées en ordre décroissant, et le dictionnaire qui associe chaque nom à sa mention. Chacune de ces demandes se formule en une seule compréhension, à condition de savoir exactement quelle donnée vous voulez en sortie. C'est la question à vous poser avant d'écrire quoi que ce soit : est-ce que je veux des noms, des notes, des paires ou des phrases ? La réponse détermine l'expression de tête, la condition détermine le filtre, et la source détermine la boucle. Une fois ce trio identifié, la ligne s'écrit presque d'elle-même, et vous constaterez que les trois exemples ci-dessous suivent rigoureusement le même modèle. Cette régularité est volontaire : elle vous permet de traiter toute demande à venir comme une variation d'un modèle déjà maîtrisé, plutôt que comme un problème neuf à résoudre de zéro.

```python
notes = [12, 9, 17, 14, 18]
admissibles = [n for n in notes if n >= 10]
doubles = [n * 2 for n in notes]
classe = {"Amina": 14, "Bruno": 9, "Chloe": 17}
admis = [nom for nom, note in classe.items() if note >= 10]
mentions = {nom: "admis" if note >= 10 else "ajourne" for nom, note in classe.items()}
print(admissibles)
print(doubles)
print(admis)
print(mentions)
```
$lesson$),
  ('py-c4-p7', 'py-c4', 7, $lesson$Référence versus copie : le piège de l'affectation$lesson$, $lesson$
Voici le piège le plus subtil de ce chapitre, et celui qui surprend le plus souvent les programmeurs en devenir. Quand vous écrivez b = a avec deux listes, vous ne dupliquez pas la liste : vous créez un second nom qui pointe vers le même objet. Il n'y a alors qu'une seule liste en mémoire, mais deux façons de l'appeler, et chacune voit exactement le même contenu. Si vous modifiez la liste par a.append(5), la variable b voit également l'élément apparaître, puisque c'est le même objet qui a changé. Ce comportement s'explique par les références : une variable contient une adresse, et l'affectation copie l'adresse, pas le contenu. Ce n'est pas un défaut de Python, c'est le fonctionnement normal des objets modifiables, et il vous évite de recopier inutilement de grosses collections à chaque passage de paramètre. C'est d'ailleurs pour cette raison que Python préfère passer les objets par référence plutôt que par valeur : recopier une liste de plusieurs milliers d'éléments à chaque appel coûterait très cher en temps machine.

Pour mettre les choses à l'épreuve, exécutez le petit programme de ce chapitre et observez la longueur de b après l'append : vous constaterez que b compte désormais deux éléments, alors que vous n'avez jamais écrit b.append. Le même phénomène se produit quand vous passez une liste en paramètre de fonction : la fonction reçoit le même objet que l'appelant, et toute modification qu'elle y fait est visible en dehors. C'est tantôt un avantage, quand votre fonction doit justement enrichir une collection partagée, tantôt une source de bugs silencieux, quand elle pensait travailler sur une copie de travail. La règle à retenir tient en une phrase, et elle figure au quiz : après b = a, a.append modifie aussi b. Aucun message d'erreur ne vous préviendra jamais de cette confusion, ce qui en fait l'une des plus fréquentes dans les programmes réels. Les symptômes sont trompeurs : le programme continue de fonctionner, seule une liste semble grossir sans raison, et le vrai responsable se trouve souvent plusieurs dizaines de lignes plus haut.

Heureusement, la copie explicite tient en une ligne, et vous disposez de plusieurs écritures équivalentes. Pour obtenir une liste indépendante, utilisez list(a), a.copy() ou encore une compréhension [x for x in a] : ces trois formes produisent un nouvel objet qui partage les mêmes éléments mais pas le même destin. Si vous modifiez la copie, l'original ne bouge pas, et vice versa. Toute opération qui renvoie une nouvelle liste joue le même rôle : sorted(a) vous donne une version triée sans toucher à la source, a + [] vous donne une liste vide concaténée, et la découpe a[:] extrait la totalité dans un objet neuf. Pour les dictionnaires, le principe est identique : d2 = d.copy() crée une seconde fiche indépendante, à condition toutefois de ne pas modifier les valeurs imbriquées, comme nous allons le voir immédiatement. Une bonne méthode consiste à se demander systématiquement si une structure contient encore une liste ou un dictionnaire quelque part en elle : dès que la réponse est oui, la copie de premier niveau ne suffit plus.

Attention, la copie de premier niveau, dite superficielle, ne duplique pas les structures internes. Si votre dictionnaire contient une liste, la copie pointe vers cette même liste : modifier d2["notes"] modifie aussi d["notes"], et la variable d'origine est altérée sans prévenir. Pour séparer complètement deux structures imbriquées, il faut une copie profonde, obtenue avec la fonction deepcopy du module copy, que vous découvrirez au chapitre 7 consacré aux modules. Concrètement, appliquez ce réflexe simple : quand une structure quitte votre fonction, soit vous la modifiez volontairement et vous le documentez dans le docstring, soit vous la copiez d'abord avant de la travailler. Une affectation seule n'est jamais une copie, et ce principe vaut pour toutes les structures modifiables du langage, listes, dictionnaires et ensembles compris. Retenez enfin que les structures immuables, comme les tuples ou les chaînes de caractères, échappent complètement à ce problème : les affecter crée toujours une indépendance réelle.

```python
a = [1, 2, 3]
b = a
a.append(4)
print(a, b)
c = list(a)
c.append(5)
print(a, c)
d = {"nom": "Amina", "notes": [14, 15]}
e = d.copy()
e["notes"].append(16)
print(d["notes"], e["notes"])
```
$lesson$),
  ('py-c4-p8', 'py-c4', 8, $lesson$Exemple guidé : l'analyse des notes de classe$lesson$, $lesson$
Voici le programme complet que vous allez étudier ligne à ligne : il prend une classe entière, calcule la moyenne, repère la note maximale et produit la liste triée des noms situés au-dessus de la moyenne. Tout le chapitre s'y retrouve, ce qui en fait le meilleur résumé possible avant l'exercice pratique. Vous y voyez une liste de dictionnaires servant de source, une compréhension pour extraire la colonne de notes, les fonctions sum(), len() et max() pour les statistiques, une seconde compréhension avec condition pour filtrer, et enfin sorted() pour classer les noms. Prenez le temps d'exécuter ce code dans votre interpréteur avant de lire la suite : constater vous-même les résultats, puis les relire avec l'explication, double la puissance de l'apprentissage et ancre chaque notion à sa place exacte. Gardez aussi à portée la liste des résultats attendus, une moyenne de 13.4, un maximum de 17 et trois noms retenus, afin de comparer immédiatement la sortie réelle à votre propre prévision.

```python
classe = [
    {"nom": "Amina", "note": 14},
    {"nom": "Bruno", "note": 9},
    {"nom": "Chloé", "note": 17},
    {"nom": "David", "note": 12},
    {"nom": "Élise", "note": 15},
]
notes = [eleve["note"] for eleve in classe]
moyenne = sum(notes) / len(notes)
note_max = max(notes)
au_dessus = [eleve["nom"] for eleve in classe if eleve["note"] > moyenne]
noms_tries = sorted(au_dessus)
print("Moyenne de la classe :", round(moyenne, 2))
print("Note maximale :", note_max)
print("Noms au-dessus de la moyenne :", noms_tries)
```

La donnée de départ est une liste de dictionnaires, et ce choix n'est pas anodin. Chaque ligne représente un enregistrement complet, un élève, dont les champs sont nommés "nom" et "note" : vous comprenez le contenu sans légende, et vous pourrez ajouter un champ "prenom" ou "absences" plus tard sans rien casser dans le traitement. L'ordre de la liste reflète celui de la saisie, ce qui rend l'affichage prévisible, mais il n'a aucune importance pour les calculs : la moyenne ne dépend pas de l'ordre dans lequel on additionne. Notez enfin le nom de la variable, classe, plutôt qu'un nom vague comme data ou liste : nommer la collection selon ce qu'elle contient réellement rend le reste du code immédiatement lisible et évite les malentendus dès que le programme s'allonge ou que d'autres personnes le rejoignent. Précisons également pourquoi l'ordre n'a aucune incidence sur les calculs : les opérations statistiques additionnent ou comparent, sans jamais se fier à la position, contrairement à un accès par index qui suppose une liste stable.

La première étape du traitement extrait la colonne de notes dans une liste dédiée, grâce à la compréhension [eleve["note"] for eleve in classe]. Cette opération est idéale car elle isole la donnée numérique dont ont besoin les statistiques, sans jamais modifier la liste d'origine : vous obtenez [14, 9, 17, 12, 15], une collection homogène de nombres sur laquelle les fonctions min, max et sum deviennent directement applicables. Si vous aviez laissé les notes mélangées aux noms, chaque calcul aurait exigé une boucle avec accès par clé et filtrage du bon type : c'est précisément le rôle de cette première ligne que de vous épargner ce travail répétitif. Le calcul de moyenne combine ensuite deux notions de base : sum(notes) additionne les cinq valeurs, soit 67, et len(notes) donne l'effectif, soit 5, donc la moyenne vaut 13.4. La division produit obligatoirement un nombre décimal, ce qui évite les erreurs d'arrondi tardives.

La note maximale s'obtient en une seule fonction : max(notes) parcourt la liste et renvoie 17 sans la modifier. Cette fonction travaille sur les nombres comme sur les chaînes, en comparant les éléments deux à deux selon les règles habituelles de Python, et elle ne renvoie qu'une valeur, contrairement à sort() qui réorganise toute la collection. Si vous préfériez l'approche manuelle, vous pourriez écrire une boucle qui compare chaque note à un maximum provisoire, mais vous perdriez en clarté pour gagner en complexité : la fonction native est plus rapide, testée depuis des années et sans bug. Utiliser les outils intégrés plutôt que de réinventer leur logique est le premier réflexe d'un développeur qui va vite et juste. Rappelez-vous toutefois qu'une moyenne suppose un effectif au moins égal à un : sur une liste vide, len() vaudrait 0 et Python lèverait une erreur ZeroDivisionError, un cas que vous saurez anticiper au chapitre 6.

Le filtre retient les noms des élèves dont la note dépasse la moyenne : [eleve["nom"] for eleve in classe if eleve["note"] > moyenne]. Se lit, de droite à gauche : pour chaque élève, si sa note est strictement supérieure à 13.4, garde son nom. Le choix de l'inégalité stricte dépend du règlement pédagogique retenu : avec supérieur ou égal, un élève noté exactement 13.4 serait inclus, ce qui changerait le résultat. Ici, les notes 14, 17 et 15 franchissent la barre, tandis que 9 et 12 échouent, si bien que le filtre produit ["Amina", "Chloé", "Élise"]. Cette étape illustre parfaitement l'intérêt des compréhensions : la condition et l'extraction tiennent ensemble, dans un ordre qui se lit comme une phrase, et le reste du programme n'a plus qu'à consommer cette petite liste de noms prête à l'emploi. Si vous préférez une écriture plus explicite, la même intention se formule avec une boucle et un append(), mais la version compacte expose d'un seul regard la condition de sélection et le champ extrait.

Le tri alphabétique s'applique ensuite avec sorted(au_dessus), qui renvoie une nouvelle liste sans toucher à celle du filtre, laquelle reste disponible pour un éventuel second traitement. L'ordre par défaut compare les chaînes caractère par caractère selon leur valeur Unicode : "Amina" précède "Chloé", et "Chloé" précède "Élise" car le code de la lettre c est inférieur à celui de la lettre é. Dans ce cas précis, le résultat est donc déjà le bon, mais méfiez-vous des listes plus longues où un nom accentué pourrait se glisser après un nom commençant par z. Deux parades existent : trier avec la clé key=str.lower pour ignorer la casse, ou normaliser les accents avant le tri avec les outils du module unicodedata que vous verrez au chapitre 7. Si vous vouliez conserver les notes attachées aux noms, vous auriez trié la classe entière avec sorted(classe, key=lambda eleve: eleve["nom"]). La fonction lambda sert ici de clé éphémère : elle indique au tri quels éléments comparer, sans avoir à définir une fonction nommée pour un usage unique.

Regrouper les résultats dans un dictionnaire final achève le travail et rend le programme explicable à quelqu'un d'autre : la moyenne, le maximum et la liste des admis sont rangés sous des clés explicites, prêts à être affichés, enregistrés ou retournés par une fonction. La ligne d'affichage utilise round(moyenne, 2) pour n'afficher que deux décimales, ce qui est plus agréable qu'un flottant interminable. Avant même de lire la suite, vérifiez mentalement les valeurs attendues : 14 + 9 + 17 + 12 + 15 vaut 67, divisé par 5 donne 13.4, le maximum est bien 17, et seules Amina, Chloé et Élise dépassent la moyenne. Ce réflexe de vérification préalable, pris avant de faire confiance au code, vous épargnera de nombreuses heures de débogage. Pour finir, voici la même logique rangée dans une fonction réutilisable, un avant-goût du programme final que vous construirez au chapitre 8 : elle introduit notamment la vérification des cas limites, absente du premier jet.

```python
def resumer_notes(notes):
    if len(notes) == 0:
        return {"erreur": "aucune note"}
    return {
        "moyenne": sum(notes) / len(notes),
        "maximum": max(notes),
        "minimum": min(notes),
    }
classe = [
    {"nom": "Amina", "note": 14},
    {"nom": "Bruno", "note": 9},
    {"nom": "Chloé", "note": 17},
]
notes = [eleve["note"] for eleve in classe]
print(resumer_notes(notes))
```

Cette version montre trois bonnes pratiques à généraliser dès maintenant. La fonction reçoit une liste simple en paramètre et non la classe complète : elle reste ainsi utilisable avec n'importe quel jeu de notes, y compris celui que vous lirez dans un fichier au chapitre 5, ce qui respecte le principe d'indépendance vu avec les fonctions. Le contrôle de longueur en tête de fonction renvoie un dictionnaire d'erreur au lieu de planter, ce qui anticipe déjà la réflexion menée au chapitre 6 sur les exceptions et rend la fonction tolérante aux données manquantes. Enfin, le dictionnaire de retour porte des clés explicites, "moyenne", "maximum" et "minimum", que l'appelant peut exploiter sans jamais lire le corps de la fonction. Appelez resumer_notes([]) pour observer le comportement de repli, puis resumer_notes(notes) pour comparer avec votre calcul manuel : cette habitude de tester les cas limites autant que le cas nominal est ce qui transforme un script fragile en outil durable.
$lesson$),
  ('py-c4-p9', 'py-c4', 9, $lesson$À retenir$lesson$, $lesson$
- Une liste est ordonnée, modifiable, accepte les doublons et les éléments de types différents.
- L'index commence à 0, -1 désigne le dernier élément, et len() donne le nombre d'éléments.
- append() ajoute en fin, insert() insère à une position, remove() supprime la première occurrence d'une valeur.
- sort() modifie la liste et renvoie None ; sorted() renvoie une nouvelle liste triée en laissant l'original intact.
- min(), max(), sum() et len() fournissent les statistiques de base, dont la moyenne obtenue par somme divisée par effectif.
- Un dictionnaire associe une clé unique à une valeur : lecture et écriture avec d["cle"], test de présence avec "cle" in d.
- d.items() parcourt les paires clé-valeur, idéal dans une boucle for décomposée en deux variables.
- d.get("cle", valeur_par_defaut) évite le KeyError d'une clé absente.
- Une liste de dictionnaires représente un tableau : chaque ligne est un enregistrement nommé par ses champs.
- Une compréhension [expr for x in seq if cond] condense boucle et filtre, à condition de rester d'une seule ligne lisible.
- b = a ne copie pas : les deux noms partagent le même objet, et a.append modifie aussi b.
- list(a), a.copy() ou a[:] créent une copie indépendante de premier niveau.
- Toute structure imbriquée partage encore ses valeurs internes tant que vous n'avez pas fait de copie profonde.
$lesson$),
  ('py-c4-p10', 'py-c4', 10, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : lire une clé absente avec d["absente"], ce qui lève KeyError → correction : utilisez d.get("absente", valeur_par_defaut) ou testez "absente" in d avant toute lecture.
- Piège : affecter le tri avec trié = notes.sort(), ce qui donne None → correction : écrivez notes.sort() seul, ou trié = sorted(notes) pour conserver l'original.
- Piège : confondre = et == sur une liste → correction : a == b compare les contenus et renvoie un booléen, tandis que a = b ne fait que copier la référence.
- Piège : index hors bornes avec notes[len(notes)] → correction : le dernier élément s'obtient avec notes[-1], et l'index maximum valide vaut len(notes) - 1.
- Piège : appeler remove() sur une valeur absente, ce qui lève ValueError → correction : testez d'abord avec if valeur in notes avant de supprimer.
- Piège : croire que b = a.copy() isole une structure imbriquée → correction : les valeurs internes restent partagées, il faut une copie profonde avec deepcopy.
- Piège : écrire une compréhension surchargée, avec plusieurs conditions et calculs imbriqués → correction : revenez à une boucle for explicite, plus facile à lire et à déboguer.
- Piège : tester la présence d'une valeur avec "Amina" in d.values(), ce qui parcourt tout le dictionnaire → correction : inversez la structure pour que les noms servent de clés, ou bouclez sur items().
- Piège : modifier une liste pendant que vous la parcourez avec for → correction : parcourez une copie avec for e in list(notes), ou construisez une nouvelle liste par compréhension.
$lesson$),
  ('py-c4-p11', 'py-c4', 11, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation officielle de Python consacre un tutoriel entier aux structures de données, et c'est la référence à ouvrir en premier après ce chapitre. Les listes, les dictionnaires, les ensembles et toutes leurs méthodes y sont expliqués avec des exemples exécutables, notamment les méthodes de liste, le paramètre key du tri, le tri de listes de dictionnaires et la concaténation. Les compréhensions y ont également droit à leur section dédiée, avec les formes imbriquées et l'utilisation du mot clé if en fin d'expression. L'adresse de ce tutoriel est la suivante : https://docs.python.org/fr/3/tutorial/datastructures.html. Lisez-la progressivement, chapitre par chapitre : vous y reconnaîtrez chaque notion de cette leçon, exposée avec la rigueur de référence qui caractérise les documents officiels. Les sections y sont courtes et densement illustrées, ce qui en fait une lecture idéale en fin de chapitre pour vérifier que vous n'avez rien laissé passer, sans jamais vous noyer dans le détail d'implémentation.

Pour comprendre en profondeur pourquoi certaines méthodes modifient une liste alors que d'autres en renvoient une nouvelle, consultez la page du type séquence mutable dans la référence de la bibliothèque standard : https://docs.python.org/fr/3/library/stdtypes.html#mutable-sequence-types. Elle détaille le comportement de append, extend, insert, remove, pop, reverse et sort, ainsi que leurs effets de bord respectifs, ce qui lève définitivement la confusion entre méthode en place et fonction de copie. La page consacrée aux compréhensions de liste complète le tableau : https://docs.python.org/fr/3/tutorial/datastructures.html#list-comprehensions. Ces deux pages sont denses, mais inépuisables : revenez-y après chaque exercice pratique, une notion différente vous sautera aux yeux à chaque relecture, et c'est ainsi que la référence devient un outil de travail quotidien plutôt qu'une lecture subie. Gardez ces adresses dans vos favoris : elles constituent la source la plus fiable qui soit, bien au-dessus des forums et des extraits de code trouvés au hasard sur le web, y compris lorsque l'urgence est grande.
$lesson$),
  ('py-c4-p12', 'py-c4', 12, $lesson$Et maintenant : la vidéo du chapitre$lesson$, $lesson$
La vidéo du chapitre reprend exactement le même parcours que cette leçon, mais en le montrant à l'écran : vous verrez une liste se remplir avec append(), un dictionnaire se construire clé par clé, puis le programme d'analyse de notes s'écrire et s'exécuter devant vous, bloc après bloc. Regardez-la en gardant ce texte sous la main, et n'hésitez pas à mettre la lecture en pause pour rejouer chaque séquence dans votre propre interpréteur, en modifiant au passage une note ou un nom pour observer le résultat changer. Une fois la vidéo terminée, l'exercice pratique vous mettra au travail sur une liste de dictionnaires de votre choix : vous y calculerez une moyenne, une note maximale et une liste triée par ordre alphabétique, en appliquant seul toutes les techniques vues ici. Ce passage à l'action est la clé du chapitre : relisez les sections À retenir et Erreurs fréquentes si vous bloquez, puis lancez-vous sans attendre.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('py-c5-p1', 'py-c5', 1, $lesson$Comprendre : un fichier, c'est une conversation avec le disque$lesson$, $lesson$
Depuis le premier chapitre, vos programmes fonctionnent tous de la même façon : ils créent des variables, des listes, des dictionnaires, puis tout disparaît dès que l'exécution s'arrête. Si vous calculez la moyenne d'une classe dans une liste, cette moyenne existe tant que le script tourne, et seulement pendant les quelques millisecondes qui séparent l'affichage du premier mot de l'exécution de la dernière ligne. Pour qu'un résultat survive à la fin du programme, il faut le confier à quelque chose de plus durable que la mémoire vive : le disque. C'est exactement le rôle des fichiers. Un fichier est une suite d'octets associée à un nom, rangée dans un dossier, et qui attend sagement votre prochaine session. En apprenant à lire et à écrire des fichiers, vous donnez à vos scripts une mémoire qui leur survit, et vous franchissez la frontière entre un exercice scolaire et un outil réellement utile.

Ce déplacement change aussi la nature des données sur lesquelles vous travaillez. Au chapitre 4, vous avez appris à manipuler des listes et des dictionnaires : des structures vivantes, organisées, que vous modifiez à loisir, que vous triez, que vous parcourez avec des boucles for. Un fichier texte, lui, est plus rustique : ce n'est qu'une longue suite de caractères découpée en lignes, sans structure, sans type, sans mémoire de ce que vous aviez fait la dernière fois. Le travail du programmeur consiste donc à construire le pont dans les deux sens. Lire, c'est transformer des lignes de caractères en listes, en nombres, en dictionnaires que votre code saura exploiter. Écrire, c'est l'inverse : prendre des structures Python et les aplatir en lignes de texte que l'œil humain ou un autre programme pourra relire. Tout ce que vous allez apprendre aujourd'hui est au service de ce double passage, et vous verrez qu'il repose sur un nombre remarquablement petit de concepts.

Concrètement, nous partirons d'un cas simple et très courant : un fichier notes.csv dans lequel chaque ligne contient le nom d'un élève et sa note. Votre mission, en fin de chapitre, sera de le lire, de calculer la moyenne de la classe, puis de produire un fichier rapport.txt qui récapitule la moyenne, la meilleure note et la mention de chaque élève. Pour y arriver, nous verrons dans un premier temps comment ouvrir un fichier en toute sécurité avec le bloc with et le bon encodage, puis comment lire du contenu avec les trois stratégies à votre disposition. Nous aborderons ensuite l'écriture : créer un fichier, y ajouter des lignes sans écraser l'existant, comprendre pourquoi le mode w disparaît tout ce qu'il trouve. Enfin, nous utiliserons le module csv et son lecteur de dictionnaires pour parcourir un tableau exporté depuis un tableur. La vidéo du chapitre prolongera cette leçon pas à pas, avant l'exercice pratique et le quiz qui valident vos acquis.



Un fichier texte est, au plus simple, une suite ordonnée de caractères enregistrée sous un nom unique dans un dossier de votre ordinateur. Ce que le système d'exploitation stocke réellement, ce sont des octets, mais lorsque vous travaillez avec du texte, Python s'occupe de la traduction entre les caractères que vous lisez à l'écran et les octets posés sur le disque. Pour référencer ce fichier, vous indiquez un chemin, c'est-à-dire une adresse : relatif, il est apprécié depuis le dossier où tourne votre script, par exemple notes.csv ; absolu, il part de la racine du disque, par exemple C:\donnees\notes.csv sur Windows ou /home/moi/notes.csv sur Linux. Une même instruction open peut donc désigner deux fichiers différents selon l'endroit d'où vous lancez votre programme, ce qui explique la plupart des fichiers introuvables que vous rencontrerez. Prenez l'habitude d'afficher le chemin que votre script va ouvrir, par exemple avec `print(chemin)`, pendant toute la phase de développement : cette seconde suffit à révéler un dossier de lancement inattendu, un nom de fichier mal orthographié ou une extension oubliée, trois causes qui reviennent sans cesse dans les premiers programmes.

Pour dialoguer avec ce fichier, Python met à votre disposition la fonction open, que vous avez sans doute déjà aperçue. Elle prend au minimum le chemin du fichier, renvoie un objet fichier, souvent appelé descripteur, et ce descripteur est votre unique porte d'accès au contenu : vous demanderez à cet objet de lire, d'écrire, de se déplacer. L'analogie conversationnelle est utile. Ouvrir, c'est saluer et obtenir la parole ; lire, c'est écouter ; écrire, c'est parler ; fermer, c'est raccrocher. Tant que vous n'avez pas raccroché, la conversation consomme une ressource système, et sur certains systèmes, notamment Windows, le fichier reste verrouillé : un autre programme, ou une seconde ouverture depuis votre propre script, se verra refuser l'accès. C'est la raison profonde pour laquelle la fermeture n'est pas une formalité cosmétique, mais une étape obligatoire du cycle de vie d'un fichier. Concrètement, une ouverture non fermée consomme un descripteur, c'est-à-dire une ressource limitée par le système : au bout de quelques centaines d'ouvertures oubliées, même un programme correct se verra refuser la parole. Vous mesurerez cette règle le jour où votre script devra traiter un dossier entier, parce qu'alors chaque fichier oublié se paie cash.

Le second argument de open est le mode, qui décrit ce que vous comptez faire de la conversation. Trois modes couvrent l'essentiel du travail quotidien en Python, et leur comportement mérite d'être mémorisé précisément, car ils ne sont pas symétriques. Le mode lecture vous donne accès au contenu existant sans pouvoir le modifier, le mode écriture crée ou remplace entièrement le fichier, et le mode ajout crée ou complète le fichier en écrivant uniquement après le contenu déjà présent. Attention à une subtilité importante : si le mode lecture échoue quand le fichier n'existe pas, ce qui est une bonne chose car il protège vos données, le mode écriture, lui, crée un fichier vide au besoin, et le mode ajout fait de même. Ainsi, un simple oubli de nom de fichier en lecture vous alerte, tandis qu'une faute de frappe en écriture fabrique silencieusement un fichier parasite. Il est donc de bon ton, pendant l'apprentissage, d'afficher le mode retenu juste avant l'ouverture, quitte à supprimer ce petit message une fois vos habitudes installées.

Trois modes ne suffisent cependant pas à décrire toutes les situations, et Python prévoit des variantes pour les cas particuliers. Vous pouvez cumuler les préfixes, par exemple a pour ajouter, mais aussi ouvrir en mode binaire avec rb ou wb lorsque vous manipulez des images, des archives ou tout fichier qui n'est pas du texte, ou encore combiner a et plus pour forcer l'ajout. Pour ce chapitre, nous resterons volontairement sur le texte et les trois modes principaux, car ils suffisent à lire des données, à produire des rapports et à tenir un journal d'exécution. La règle à retenir est simple : avant d'ouvrir un fichier, demandez-vous ce que vous voulez faire de son contenu existant. Voulez-vous le conserver et le consulter ? Ouvrez en lecture. Voulez-vous le remplacer par quelque chose de neuf ? Ouvrez en écriture. Voulez-vous compléter un historique ? Ouvrez en ajout. Cette question, posée une seconde avant chaque appel à open, vous fera gagner non seulement du temps, mais aussi la tranquillité de savoir que vous ne détruirez jamais par inadvertance des données produites avant la session en cours.

La lecture elle-même se décline en plusieurs stratégies, et le choix entre elles n'est pas un détail d'implémentation. La méthode read charge la totalité du fichier en une seule chaîne de caractères, commode pour un petit fichier de configuration mais risqué pour un journal de plusieurs centaines de mégaoctets, car tout atterrit en mémoire vive. La méthode readline récupère la ligne suivante, une seule fois, ce qui permet d'avancer à votre rythme. Enfin, itérer directement sur l'objet fichier, avec une boucle for, parcourt le fichier ligne à ligne en ne gardant en mémoire que la ligne courante : c'est la stratégie recommandée pour les fichiers volumineux, et elle s'exprime avec la syntaxe la plus naturelle de Python. Vous verrez dans la suite comment mesurer concrètement ces différences et pourquoi l'itération gagne presque toujours. Le mot presque n'est pas là par hasard : si vous devez accéder plusieurs fois à des lignes éparses, ou récupérer la dernière ligne d'un fichier, la lecture d'un fragment précis devient plus naturelle avec read. Mais dès qu'il s'agit de parcourir une seule fois un fichier de taille inconnue, l'itération reste imbattable, et c'est elle que vous utiliserez dans l'exercice pratique du chapitre.

L'écriture, de son côté, présente une astuce de débutant que beaucoup de gens découvrent à leurs dépens : la méthode write n'ajoute jamais de retour à la ligne automatiquement. Si vous appelez successivement write("Bonjour") et write("Au revoir"), vous obtenez une seule ligne BonjourAu revoir. Il faut donc glisser vous-même le caractère \n là où vous voulez une césure, ou utiliser writelines, qui reçoit une liste de chaînes mais qui, lui non plus, n'ajoute rien entre les éléments. Cette liberté est utile : elle vous permet de produire exactement le format que vous voulez, y compris des fichiers CSV dont chaque ligne se termine par \n. Elle demande simplement de devenir systématique. Quant aux nombres, ils ne sont pas des chaînes : vous devrez les convertir avec str ou, bien plus agréablement, avec les f-strings que vous maîtrisez déjà. Pensez-y dès que vous écrirez un rapport : un nombre brut est un obstacle, une chaîne formatée est un livrable. La même règle vaut pour les booléens et les dates, dont la conversion en texte demande elle aussi une manipulation explicite.

Un dernier concept clôt le tableau avant d'ouvrir un vrai fichier : l'encodage. Une lettre accentuée comme é ne tient pas sur un seul octet dans la plupart des encodages modernes, et deux ordinateurs ne s'entendent sur le bon caractère que s'ils emploient la même table de correspondance. Python 3 travaille par défaut en UTF-8, un encodage universel qui sait représenter toutes les écritures, mais le fichier que vous lisez peut avoir été produit par un autre logiciel avec une autre table. Le symptôme est alors une erreur à l'ouverture ou, pire, des caractères illisibles qui s'affichent sans la moindre protestation. La parade tient en trois mots que vous ajouterez systématiquement : encoding="utf-8". Vous verrez plus loin pourquoi ce détail vous épargnera des heures de débogage. Un dernier point mérite d'être souligné : le paramètre encoding s'applique aux deux sens du flux. En lecture, il décrit la table utilisée pour interpréter les octets présents sur le disque ; en écriture, il indique la table dans laquelle Python doit convertir vos caractères avant de les enregistrer. Si vous oubliez le paramètre lors de l'écriture, le fichier sera créé, mais son contenu ne sera pas lisible partout. Un seul oubli suffit donc à casser un échange de données entre deux machines.

Toutes ces idées convergent vers un usage particulier et très répandu : le fichier CSV, pour comma-separated values. Un CSV n'est rien d'autre qu'un fichier texte dont chaque ligne est un enregistrement et dont les champs sont séparés par une virgule, avec une première ligne qui nomme les colonnes. C'est le format d'échange par excellence entre un tableur comme Excel ou LibreOffice et un programme Python. Plutôt que d'éclater vous-même chaque ligne avec la méthode split, ce qui fonctionne tant que vos données ne contiennent ni virgule ni guillemet, Python fournit le module csv, et plus précisément la classe DictReader, qui transforme chaque ligne en dictionnaire indexé par les en-têtes. Vous récupérez alors des structures familières, exactement de celles que vous manipulez depuis le chapitre 4, et votre code devient à la fois plus court et plus lisible. Vous verrez d'ailleurs dans la section suivante à quel point DictReader supprime tout le code de désérialisation que beaucoup de débutants écrivent à la main, souvent avec des bugs subtils sur les champs vides, les espaces parasites ou les guillemets mal refermés.

- Mode "r" : lecture seule, échoue avec FileNotFoundError si le fichier n'existe pas.
- Mode "w" : écriture, crée le fichier s'il manque et efface intégralement son contenu précédent.
- Mode "a" : ajout, crée le fichier s'il manque et écrit uniquement à la fin du contenu existant.
- Mode "r+" : lecture et écriture sur un fichier existant, utile mais moins courant que les trois précédents.
- Suffixe "b" : ouverture en binaire, à réserver aux fichiers qui ne sont pas du texte.
- Paramètre encoding : précise la table de caractères utilisée, encoding="utf-8" étant le choix sûr.

- Utilisez toujours le bloc with pour ouvrir un fichier : la fermeture est alors garantie, même si une erreur survient au milieu du traitement.
- Précisez systématiquement encoding="utf-8" à l'ouverture, à la lecture comme à l'écriture, pour éviter les surprises d'accents.
- Préférez l'itération ligne à ligne avec une boucle for plutôt que read sur les fichiers dont vous ne maîtrisez pas la taille.
- Rappelez-vous que le mode "w" écrase : vérifiez le chemin avant toute ouverture en écriture.
- Convertissez toujours les nombres en chaînes avant de les écrire, et terminez chaque ligne écrite par \n.
- Pour les tableaux, utilisez le module csv plutôt que de découper les lignes à la main.
$lesson$),
  ('py-c5-p2', 'py-c5', 2, $lesson$Ouvrir un fichier : chemins et modes$lesson$, $lesson$
Avant d'ouvrir quoi que ce soit, il faut décider de quoi ouvrir, et c'est ici que se loge la première difficulté pratique du chapitre. Python distingue deux familles de chemins. Un chemin absolu décrit l'emplacement complet du fichier depuis la racine du système : C:\donnees\notes.csv sous Windows, /home/moi/notes.csv sous Linux ou macOS. Un chemin relatif, plus court, est apprécié par rapport au dossier courant, c'est-à-dire le répertoire depuis lequel vous avez lancé Python. Ce détail a une conséquence contre-intuitive : le dossier courant n'est pas celui où se trouve votre script, mais celui où se trouve votre terminal. Si vous lancez python cours/analyse.py depuis la racine d'un projet, un appel open("notes.csv") cherchera notes.csv à la racine du projet, et non dans le dossier cours. Le remède tient en deux habitudes simples : lancer toujours vos scripts depuis le même dossier, et regrouper les chemins en constantes en tête de fichier, afin de ne les modifier qu'à un seul endroit si l'arborescence change.

Un second écueil attend les utilisateurs de Windows : le caractère antislash. Dans une chaîne de caractères, `\n` est un retour à la ligne et `\t` une tabulation, si bien que le chemin `C:\donnees\notes.csv` est en réalité interprété comme C: suivi d'une tabulation, puis de ondates, d'un saut de ligne et enfin de otes.csv, un chemin qui n'existe nulle part. Trois solutions simples existent. Vous pouvez doubler chaque barre inversée, `C:\\donnees\\notes.csv`, utiliser une chaîne brute, `r"C:\donnees\notes.csv"`, qui désactive toute interprétation des barres inverses, ou, plus proprement encore, employer le caractère slash, `C:/donnees/notes.csv`, que Python accepte parfaitement sur tous les systèmes d'exploitation. Précisons enfin que le chemin peut être construit à partir de l'emplacement même du script grâce à l'attribut `__file__`, une technique commode lorsque le programme doit retrouver ses données quel que soit l'endroit d'où on le lance. Quel que soit l'approche retenue, gardez à l'esprit une seule chose : un chemin est une donnée comme une autre. Affichez-le pendant le développement, centralisez-le en tête de script, et vérifiez qu'il pointe bien vers le dossier que vous croyez, parce qu'un chemin faux reste, de très loin, la première cause d'échec avec les fichiers.

Une fois le chemin stabilisé, l'appel devient presque mécanique : la fonction open reçoit le chemin, le mode, puis l'encodage, et renvoie l'objet fichier avec lequel vous converserez. Trois informations suffisent donc à décrire entièrement votre intention, et le code en devient immédiatement lisible pour un tiers : on voit d'un coup d'œil quel fichier est ouvert, dans quel but, et avec quelle table de caractères. Si l'un de ces éléments manque, Python se rabat sur une valeur par défaut, ce qui est commode pour un script de démonstration mais risqué pour un programme déployé, car ce défaut peut varier d'une machine à l'autre. Voici la forme la plus simple, celle que vous écrirez des dizaines de fois, avec la lecture complète du contenu et la fermeture explicite demandée à la main. Gardez ce modèle en mémoire pour le comparer, dans la section suivante, à la version sécurisée que vous adopterez en définitive : la seule différence tiendra dans le bloc with qui entoure l'ensemble.

```python
fichier = open("notes.csv", "r", encoding="utf-8")
contenu = fichier.read()
fichier.close()
print(contenu)
```

Ce petit script contient les trois gestes de base : ouvrir, exploiter, fermer. Le mode "r" indique que vous ne voulez que consulter le fichier, et le paramètre encoding="utf-8" dit à Python de décoder les octets avec la table UTF-8, celle qui restitue correctement les accents français. Si notes.csv n'existe pas, Python lève FileNotFoundError dès la première ligne, ce qui est un comportement souhaitable : le mode lecture ne fabrique jamais de fichier vide. Retenez toutefois que le même appel en mode "w" aurait créé un fichier notes.csv vide, écrasant au passage tout contenu antérieur sans poser la moindre question. C'est précisément pour éviter ces accidents de parcours qu'il faut décider du mode en réfléchissant, jamais en copiant-colant la ligne précédente. Si vous voulez vérifier par vous-même ce qui se passe en cas de chemin erroné, supprimez temporairement le fichier ou modifiez son nom, puis relancez : l'erreur levée vous montrera exactement le message que vous recevrez en production, et vous prendrez l'habitude de le lire au lieu de le subir.

L'écriture suit la même mécanique, avec un mode différent. Voici un exemple que vous pouvez exécuter tel quel dans un dossier vierge : le premier bloc crée le fichier et y écrit une ligne, le second rouvre le même fichier en mode ajout et y greffe une ligne supplémentaire, puis le troisième relit le résultat pour vérification. Comparez attentivement ce que fait chaque mode avec le contenu déjà présent. Ce minuscule programme contient déjà tout le chapitre : une ouverture en écriture qui crée et vide, une seconde ouverture en ajout qui complète, une troisième en lecture qui vérifie. Notez que chaque opération referme son fichier avant que la suivante ne commence, ce qui évite tout conflit d'accès entre deux descripteurs. Exécutez-le une première fois, puis une seconde : le résultat de la seconde exécution vous confirmera que le mode ajout a bien préservé la ligne du lundi. Si vous préférez expérimenter avec vos propres données, remplacez librement les textes et conservez le même enchaînement des trois modes, car c'est le mode, et lui seul, qui décide du sort des données déjà présentes.

```python
fichier = open("journal.txt", "w", encoding="utf-8")
fichier.write("Lundi : premier essai\n")
fichier.close()
fichier = open("journal.txt", "a", encoding="utf-8")
fichier.write("Mardi : second essai\n")
fichier.close()
fichier = open("journal.txt", "r", encoding="utf-8")
print(fichier.read())
fichier.close()
```

L'affichage attendu contient les deux lignes, car le mode "a" a bien écrit à la fin du fichier existant. Si vous remplacez le second mode "a" par "w" et que vous relancez, le fichier ne contiendra plus que la ligne du mardi : le lundi a été effacé dès la réouverture. C'est la différence la plus importante entre ces deux modes, et elle mérite d'être testée une fois par vous-même pour ne jamais être oubliée. Trois bonnes pratiques complètent cette section. Regroupez tous les chemins de votre programme en constantes nommées en haut du fichier, de sorte qu'un changement d'arborescence ne se répercute pas sur vingt lignes dispersées. Demandez-vous systématiquement si votre programme doit conserver l'existant avant de choisir "w" ou "a". Enfin, gardez à l'esprit que ouvrir un fichier est une opération qui peut échouer, car elle dépend du disque, des droits d'accès et de l'arborescence : cette réalité reviendra au chapitre 6, quand nous apprendrons à anticiper les pannes avec les exceptions.

```table
Mode | Fichier existant | Fichier absent | Exemple d'appel
--- | --- | --- | ---
`"r"` | lit le contenu sans pouvoir le modifier | échoue avec FileNotFoundError, aucun fichier créé | `open("notes.csv", "r", encoding="utf-8")`
`"w"` | vide intégralement le contenu avant d'écrire | crée un fichier vide | `open("journal.txt", "w", encoding="utf-8")`
`"a"` | écrit uniquement à la fin du contenu présent | crée le fichier s'il manque | `open("journal.txt", "a", encoding="utf-8")`
```
$lesson$),
  ('py-c5-p3', 'py-c5', 3, $lesson$Le bloc with et la fermeture garantie$lesson$, $lesson$
La forme à la main que vous venez d'utiliser est correcte, mais fragile, et elle ne résiste pas à la moindre difficulté. Tant que tout se passe bien, la méthode close est bien appelée. Dès qu'une erreur survient entre l'ouverture et la fermeture, une division par zéro, une clé de dictionnaire introuvable, une chaîne convertie en nombre ratée, l'exécution s'interrompt immédiatement et la ligne close n'est jamais exécutée. Le fichier reste alors ouvert : il consomme une ressource système, il peut rester verrouillé jusqu'à la fin du programme, et sur Windows, un autre logiciel qui tentera de l'ouvrir recevra un refus parfois très étrange à comprendre. Un script de traitement de données qui enchaîne des centaines de fichiers peut ainsi accumuler des dizaines d'ouvertures non fermées et finir par échouer pour une raison qui n'a rien à voir avec la logique métier. Ces fichiers orphelins sont d'autant plus insidieux qu'aucun message ne signale leur présence : le programme semble fonctionner, jusqu'au jour où une ressource manque et où l'erreur finale ne rappelle en rien sa véritable cause.

Python propose à cette situation une solution élégante et définitive : le bloc with. Il s'écrit avec le mot-clé with suivi de l'appel à open, d'une clause as et d'un nom de variable, puis d'un bloc indenté qui reçoit tout le travail à faire sur le fichier. À la sortie de ce bloc, qu'il se termine normalement ou brutalement à cause d'une erreur, Python referme le fichier automatiquement. La fermeture devient une garantie du langage, pas une discipline à laquelle vous devez penser. C'est la forme à retenir par cœur, celle que vous utiliserez dans cent pour cent de vos futurs programmes, et celle que vous verrez dans tous les exemples de cette leçon. Dès maintenant, considérez l'ouverture manuelle suivie de close comme un exercice pédagogique que vous ne réemployerez plus. Concrètement, la clause as associe l'objet fichier à un nom local, et Python s'occupe d'appeler close automatiquement à la sortie du bloc, en toutes circonstances, y compris lorsqu'une exception interrompt l'exécution.

```python
with open("notes.csv", "r", encoding="utf-8") as fichier:
    contenu = fichier.read()
```

La lecture ci-dessus mérite d'être décortiquée. L'indentation n'est pas décorative : elle définit la durée de vie de la ressource. Toutes les lignes situées à l'intérieur du bloc disposent d'un fichier ouvert et disponible sous le nom fichier. Dès que l'indentation revient à gauche, le fichier est fermé, et toute tentative d'accès ultérieure provoquera une erreur du type I/O operation on closed file. Notez que la variable fichier reste techniquement accessible après le bloc : c'est l'objet qui est clos, pas la variable qui disparaît. Cette distinction explique un message d'erreur souvent déroutant pour les débutants qui tentent, par mégarde, de lire encore une ligne après la fin du with, en dehors de l'indentation où la ressource existe. Cette erreur, loin d'être anodine, est la preuve que la fermeture a bien eu lieu au moment prévu : elle vous protège d'une écriture fantôme dans un fichier que vous croyiez encore ouvert. Prenez l'habitude de placer toute la logique de traitement sous le with, y compris l'affichage du résultat, et de ne garder après lui que des données déjà copiées en mémoire.

Le bloc with brille particulièrement dans le traitement de plusieurs fichiers simultanément, par exemple lors d'une copie ou d'une fusion. Vous pouvez ouvrir autant de fichiers que nécessaire dans la même ligne, en les séparant par des virgules, et tout sera fermé en même temps à la sortie du bloc. Le code suivant copie le contenu d'un fichier vers un autre en une seule passe, sans jamais appeler close, et il refermera les deux descripteurs même si la boucle échoue en cours de route. Le bloc with accepte autant de gestionnaires que nécessaire, et Python les fermera tous à la sortie, dans l'ordre inverse de leur ouverture. Remarquez en outre que le mode "w" de sortie crée copie.txt s'il n'existe pas, et l'écraserait s'il existait déjà : pour une copie prudente, vous pourriez d'abord vérifier son absence. L'intérêt de cette écriture compacte est qu'aucune ressource ne peut rester ouverte si une erreur survient pendant la lecture ou l'écriture, et que le code reste d'une seule traînée, facile à relire. C'est le motif que vous réemployerez pour tout traitement par lots.

```python
with open("source.txt", "r", encoding="utf-8") as entree, open("copie.txt", "w", encoding="utf-8") as sortie:
    for ligne in entree:
        sortie.write(ligne)
```

Trois remarques pratiques terminent cette section. Premièrement, l'expression as est facultative sur le plan syntaxique si vous n'avez pas besoin de nommer l'objet, mais elle est quasiment toujours nécessaire puisque c'est par ce nom que vous lisez ou écrivez. Deuxièmement, le bloc with fonctionne avec tout autre type de ressource qui se ferme d'elle-même : connexions réseau, bases de données, fichiers ouverts en écriture. Vous retrouverez ce motif dans de nombreux exemples que vous lirez ailleurs. Troisièmement, et c'est le point le plus important, le with n'empêche pas les erreurs : il garantit simplement que la fermeture aura lieu quoi qu'il arrive. Anticiper, isoler et traiter ces erreurs, c'est précisément le sujet du chapitre suivant. Attendez-vous également à rencontrer cette syntaxe dans des bibliothèques tierces : le bloc with y sert à garantir la libération d'une connexion, d'un verrou ou d'un tampon d'écriture, et sa présence immédiate vous signalera que vous avez affaire à du code soigné.
$lesson$),
  ('py-c5-p4', 'py-c5', 4, $lesson$Lire : read, readline et itération ligne à ligne$lesson$, $lesson$
La méthode la plus immédiate pour récupérer le contenu d'un fichier est read, qui charge la totalité du texte dans une seule chaîne de caractères. Cette approche a deux avantages indéniables : elle tient en une ligne, et elle vous donne immédiatement la main sur l'ensemble du contenu, que vous pouvez ensuite découper à loisir avec split, chercher avec in ou mesurer avec len. Elle convient parfaitement aux fichiers de configuration, aux petits fichiers de données, aux textes courts que vous manipulez en entier. Sa limite est quantitative : tout le fichier atterrit en mémoire vive à la fois. Sur un fichier de quelques kilo-octets, cela ne se voit pas ; sur un journal de serveur de plusieurs centaines de mégaoctets, cela peut faire échouer votre programme avant même la première ligne de traitement. Une petite estimation mentale suffit : un fichier de cent mégaoctets chargé intégralement en mémoire peut en occuper autant dans votre ordinateur, alors que le traitement ligne à ligne n'en retiendra jamais plus d'une seule à la fois.

La deuxième technique s'appelle readline : elle ne renvoie que la ligne sur laquelle se trouve un curseur interne, puis avance ce curseur d'un cran. Appelez-la une fois, vous obtenez la première ligne ; rappelez-la, vous obtenez la suivante ; continuez ainsi jusqu'à ce qu'elle renvoie une chaîne vide, ce qui signifie que vous avez atteint la fin du fichier. La troisième technique, readlines, renvoie directement la liste de toutes les lignes restantes, une opération commode pour indexer, trier ou compter, mais qui recharge tout en mémoire avec le même inconvénient que read. Observez enfin que chaque ligne conservée contient encore son retour à la ligne final, ce qui surprend souvent lors des premiers affichages et explique les lignes vides apparentes dans vos impressions. Vous pouvez vous en rendre compte en affichant `repr(premiere)` : le caractère \n apparaîtra clairement entre guillemets, ce qui vous confirmera sa présence invisible à l'écran. Cette démarche est utile chaque fois qu'un résultat d'affichage vous surprend : demandez toujours à Python ce que la chaîne contient réellement, plutôt que de corriger au hasard.

```python
with open("notes.csv", "r", encoding="utf-8") as fichier:
    premiere = fichier.readline()
    seconde = fichier.readline()
    print(premiere.strip())
    print(seconde.strip())
```

Notez bien que les deux appels readline sont indentés à l'intérieur du bloc with : c'est là, et uniquement là, que le fichier est ouvert. Une tentative de lecture après la fin du bloc lèverait une erreur du type I/O operation on closed file, et ce message vous indiquera exactement ce qu'il fallait corriger : replacer l'instruction sous le with. Si vous préférez travailler avec une liste complète, vous écrirez lignes = fichier.readlines() au centre du bloc, puis vous manipulerez lignes comme n'importe quelle liste Python, avec un index, une compréhension, un tri ou une boucle for. Le choix entre lire une ligne à la fois et tout charger dépend donc de ce que vous comptez faire ensuite, et non de la syntaxe la plus courte : c'est une décision de conception, pas un détail de style. Gardez cette idée en tête lorsque vous devrez traiter un export de plusieurs mégaoctets : la technique choisie avant même la première ligne détermine souvent la mémoire consommée par l'ensemble du programme, donc sa capacité à tenir face à de vraies données.

L'approche recommandée, celle que vous emploierez dans la grande majorité des cas, consiste à itérer directement sur l'objet fichier. Une boucle for sur un fichier ouvert parcourt les lignes une par une, ne charge en mémoire que la ligne en cours d'itération, et libère la précédente dès que la suivante est lue. Le code reste d'une lisibilité parfaite, la consommation de mémoire devient constante quelle que soit la taille du fichier, et Python gère lui-même les détails d'entrée-sortie. C'est ce que l'on appelle un accès paresseux : les lignes ne sont produites que lorsqu'on les demande. Cette mécanique présente un avantage supplémentaire, rarement évoqué : elle démarre immédiatement. Votre programme peut afficher la première ligne alors que le fichier compte encore des millions de lignes à venir, ce qui est précieux lorsqu'il alimente une interface ou un traitement long. En contrepartie, vous ne pouvez pas revenir en arrière : une ligne consommée est perdue, sauf à rouvrir le fichier. Pour un parcours unique et séquentiel, c'est exactement ce que vous voulez.

```python
with open("notes.csv", "r", encoding="utf-8") as fichier:
    for ligne in fichier:
        print(ligne.strip())
```

Dans la boucle ci-dessus, la méthode strip retire les espaces superflus et surtout le retour à la ligne final, ce qui évite les affichages avec une ligne vide entre chaque résultat. Une fois la ligne nettoyée, vous la traitez comme n'importe quelle chaîne : split la découpe en champs, len vous donne son nombre de caractères, in permet de chercher un mot. Il est également fréquent d'avoir besoin du numéro de ligne, et pour cela, on combine l'itération avec la fonction enumerate, qui fournit un compteur démarrant à zéro. Pensez à ajouter 1 si vous voulez un affichage humain, car personne ne compte ses lignes à partir de zéro. Autre usage classique du même motif : filtrer les lignes qui vous intéressent, en combinant un if avec une condition de recherche, puis en accumulant les résultats dans une liste que vous traiterez une fois le fichier entièrement parcouru. Le fichier lui-même n'est jamais modifié : votre programme ne fait que le consulter, et la liste construite vit jusqu'à la fin de l'exécution.

La dernière question est celle du choix : laquelle de ces techniques employer, et quand ? La réponse tient en une règle simple. Si vous devez traiter le fichier entier, itérez : c'est plus rapide à écrire, plus économique en mémoire, et tout aussi lisible. Si vous avez besoin d'un fragment précis, comme la première ligne d'en-tête d'un CSV, utilisez readline une fois, à l'intérieur du bloc with. Si le fichier est suffisamment petit pour tient dans votre tête, read reste un raccourci commode, notamment pour tester si une chaîne donnée s'y trouve. Réservez readlines aux cas où vous voulez indexer les lignes, les trier ou les compter sans les re-parcourir. Dans tous les cas, gardez à l'esprit que la mémoire est une ressource limitée, alors que le disque, lui, est généralement bien plus vaste : bon programmeur, c'est programmer en ne supposant jamais que tout tiendra en RAM. Appliquez ce principe dès maintenant : testez vos lecteurs de fichiers sur un fichier volontairement volumineux, par exemple un export de plusieurs milliers de lignes, et observez la mémoire consommée pendant l'exécution.

```table
Méthode | Ce qui est retourné | Cas d'usage
--- | --- | ---
`read()` | la totalité du texte du fichier dans une seule chaîne | un petit fichier de configuration, ou tester si une chaîne s'y trouve
`readline()` | la ligne suivante, puis une chaîne vide à la fin du fichier | récupérer un fragment précis, par exemple l'en-tête d'un CSV
`readlines()` | la liste de toutes les lignes restantes | indexer, trier ou compter les lignes sans les re-parcourir
boucle `for` sur le fichier | une ligne à la fois, en mémoire constante | parcourir une seule fois tout un fichier, même volumineux
```
$lesson$),
  ('py-c5-p5', 'py-c5', 5, $lesson$Écrire : modes w et a, ajouter du contenu$lesson$, $lesson$
L'écriture reprend la mécanique de l'ouverture, mais elle impose deux contraintes que la lecture ne connaissait pas. La première est typographique : la méthode write attend exclusivement une chaîne de caractères. Si vous lui faites passer un entier ou un nombre décimal, Python lèvera une erreur du type write() argument must be str, et il faudra convertir la valeur avec str ou, bien plus commodément, construire la chaîne entière avec une f-string. La deuxième contraste est celui du retour à la ligne : write n'en ajoute jamais automatiquement. Deux appels consécutifs produisent donc un texte collé, sauf si vous glissez vous-même le caractère \n à la fin de chaque segment. Cette liberté est volontaire : elle vous permet de générer exactement le format attendu, texte courant, log structuré ou export tabulaire, mais elle déplace sur vos épaules une responsabilité que beaucoup de débutants oublient au premier jet. Comptez donc une ligne de plus par ligne de texte produite : c'est le prix d'un format maîtrisé. Cette discipline devient automatique après quelques rapports écrits, et elle vous évite les textes collés si fréquents au premier essai, quand toutes les phrases se retrouvent bout à bout sur une même ligne.

La méthode writelines résout partiellement ce problème en acceptant directement une liste de chaînes. Elle ne met cependant rien entre les éléments : c'est à vous d'inclure le retour à la ligne dans chaque ligne de la liste, sinon tout sera fusionné en une seule et même ligne. C'est d'ailleurs la méthode que nous utiliserons pour fabriquer le fichier d'exemple du chapitre. Le bloc suivant crée notes.csv dans le dossier courant, avec son en-tête et quatre élèves, en une seule ouverture. Exécutez-le une fois : vous disposerez du fichier que tout le reste de cette leçon va lire. Notez le choix du mode "w" : il convient parfaitement ici, car vous créez un fichier de démonstration dont le contenu est connu d'avance, et qu'il est légitime de régénérer à chaque exécution. Si le fichier avait déjà existé et contenait vos propres relevés, ce même bloc les aurait détruits sans prévenir, ce qui illustre à nouveau la nécessité de réfléchir au mode avant de taper la ligne.

```python
lignes = [
    "nom,note\n",
    "Camille,15.5\n",
    "Yanis,8\n",
    "Amina,17\n",
    "Lucas,12.5\n",
]
with open("notes.csv", "w", encoding="utf-8") as fichier:
    fichier.writelines(lignes)
```

Le mode employé ici, "w", mérite qu'on s'y attarde une seconde fois, car il est le seul réellement dangereux du trio. Écrire en "w" ne se contente pas d'ajouter du texte : il vide intégralement le fichier existant avant d'écrire la première ligne, et il le fait sans confirmation, sans corbeille, sans possibilité d'annulation. Si votre programme doit générer un rapport hebdomadaire et que le chemin visé pointe par erreur vers un fichier contenant vos données brutes, l'opération sera destructrice et définitive. Trois réflexes vous protègent. Vérifiez toujours la valeur du chemin avant l'ouverture, idéalement en l'affichant une fois pendant le développement. Réfléchissez à deux fois avant d'utiliser "w" sur un fichier que vous n'avez pas vous-même créé. Et rappelez-vous que "a" produit exactement le même résultat que "w" lorsque le fichier n'existe pas, puisqu'il le crée, mais qu'il vous épargne toute destruction s'il existe déjà. Un simple affichage du chemin juste avant l'ouverture constitue déjà une sauvegarde mentale appréciable pendant que vos réflexes se forment.

C'est ce qui fait la force du mode ajout, littéralement append. Il ouvre le fichier, place le curseur à la fin du contenu présent, puis écrit à cet endroit exact. Si le fichier n'existe pas, il le crée, si bien que le même programme peut tourner le premier jour comme le centième sans aucune adaptation. C'est le mode des journaux d'exécution, des historiques de connexion, des sauvegardes successives : on appelle ce motif un log, et votre script peut très bien tenir le sien. Le bloc suivant crée un journal, y ajoute une première entrée, puis ajoute une seconde entrée lors d'une exécution ultérieure : relisez le fichier et vous constaterez que les deux sessions y cohabitent. Ce motif d'ajout présente un autre atout : le fichier grandit lentement et garde une trace consultable de l'activité passée, exactement comme un journal de bord. Vous pouvez y faire figurer des horodatages, des compteurs ou des messages d'état, et vous y habituerez vite comme à un réflexe de développement, car une trace écrite est souvent le seul moyen de comprendre ce qui s'est passé la veille.

```python
with open("journal.txt", "a", encoding="utf-8") as fichier:
    fichier.write("2026-10-05 09:00 : analyse lancée\n")
with open("journal.txt", "a", encoding="utf-8") as fichier:
    fichier.write("2026-10-06 14:30 : analyse relancée\n")
with open("journal.txt", "r", encoding="utf-8") as fichier:
    print(fichier.read())
```

Un dernier conseil de praticité : après avoir écrit, relisez systématiquement votre fichier, au moins pendant que vous apprenez. C'est la seule façon de vérifier que les retours à la ligne sont bien placés, que les accents sont corrects et que le mode choisi a produit l'effet attendu. Vous pouvez également déléguer l'affichage à la fonction print en lui passant le paramètre file, par exemple print("terminé", file=fichier), qui écrit dans le fichier au lieu de la sortie standard, mais sans ajouter de retour à la ligne automatique non plus. Enfin, gardez à l'esprit que Python tamponne les écritures : dans un bloc with, le contenu est systématiquement écrit et le fichier fermé à la sortie, mais si vous utilisez encore l'ouverture manuelle, une interruption prématurée peut laisser une partie du texte en attente. Une raison de plus de préférer le bloc with. Relire ce que l'on vient d'écrire coûte une demi-seconde et vous fait souvent gagner dix minutes de recherche d'erreur, surtout lorsque le format produit doit ensuite être relu par un autre programme.
$lesson$),
  ('py-c5-p6', 'py-c5', 6, $lesson$Encodage UTF-8 sans mauvaise surprise$lesson$, $lesson$
Un fichier texte n'enregistre pas des lettres, mais des nombres : chaque caractère est codé en une séquence d'octets selon une table de correspondance appelée encodage. Le mot été occupe trois octets en UTF-8, deux en ISO-8859-1, et un seul si vous utilisez l'ancien code page 437 du DOS. Rien dans le fichier lui-même n'indique systématiquement la table utilisée, ce qui signifie que deux logiciels peuvent interpréter les mêmes octets et afficher des caractères totalement différents. Le phénomène est familièrement appelé mojibake : vous ouvrez un fichier et vous lisez Ã©tÃ© au lieu de été, ou pire, votre programme s'arrête net avec une erreur du type UnicodeDecodeError. Comprendre cette couche vous évitera de croire, à tort, que vos données sont corrompues alors qu'elles sont parfaitement intactes. Le plus fréquent est de voir apparaître des séquences comme Ã© ou Ã¨ : ce sont les octets d'un accent interprétés avec la mauvaise table, parfois deux fois de suite, ce qui donne ces doubles caractères si caractéristiques. Aucune donnée n'a été perdue, seule la lecture est fausse.

Python 3 simplifie la vie en choisissant par défaut l'encodage UTF-8, universel et capable de représenter toutes les écritures connues. Ce défaut n'est cependant pas une garantie absolue : il peut dépendre des réglages de votre système, et surtout, il ne s'applique qu'à Python lui-même. Le fichier que vous ouvrez, lui, peut parfaitement avoir été écrit par un tableur configuré en code page Windows-1252, par un vieil export de base de données ou par un autre langage. Si vous ouvrez un fichier ANSI avec la table attendue par défaut, la lecture échoue sur le premier accent rencontré. À l'inverse, écrire un fichier en ANSI alors que votre collègue s'attend à du UTF-8 produira chez lui des caractères bizarres. Le symptôme varie, la cause est unique : un décalage entre la table utilisée pour écrire et celle utilisée pour lire. C'est la raison pour laquelle on ne répare jamais un fichier en modifiant ses octets : on corrige le paramètre de lecture, ce qui suffit dans l'écrasante majorité des cas.

La parade tient en trois mots que vous ajouterez à chaque appel à open, à l'écriture comme à la lecture : encoding="utf-8". Ce paramètre ne coûte rien, ne ralentit pas votre programme, et il aligne explicitement les deux extrémités de la chaîne sur la même table. Notez que l'encodage s'applique uniquement en mode texte ; si vous ouvrez un fichier en mode binaire, les octets sont tels quels et la question ne se pose pas. Le bloc suivant illustre le cycle complet : il écrit un texte accentué en UTF-8, puis le relit avec la même spécification, et les deux opérations se font sans la moindre surprise. Essayez maintenant de relire ce même fichier avec un éditeur configuré en code page occidental, ou de l'ouvrir sans spécifier l'encodage sur une machine dont la locale n'est pas UTF-8 : le contraste vous convaincra mieux que n'importe quel discours. Notez enfin que les noms de fichiers eux-mêmes peuvent poser problème hors de Python : pour une portabilité maximale, préférez des noms sans accent, par exemple notes_classe.csv.

```python
with open("accents.txt", "w", encoding="utf-8") as fichier:
    fichier.write("Déjà vu : ça marche, à côté, été et hiver\n")
with open("accents.txt", "r", encoding="utf-8") as fichier:
    texte = fichier.read()
print(texte)
```

Les choses se compliquent lorsque vous héritez d'un fichier produit par un autre logiciel. Les exports CSV d'Excel sous Windows contiennent souvent un marqueur d'ordre de bits, dit BOM, en tête de fichier : quatre octets invisibles qui deviennent des caractères Ã¯Â»Â¿ visibles si vous lisez en UTF-8 simple. Python prévoit pour cela l'alias utf-8-sig, qui lit et écrit le UTF-8 en ignorant ou en ajoutant proprement ce marqueur. Si le fichier est réellement ancien et codé en une table 8 bits, une dernière solution de secours consiste à ouvrir avec errors="replace", ce qui remplace les octets illisibles par un caractère d'erreur plutôt que de faire échouer tout le programme, quitte à perdre quelques accents. Vous verrez au chapitre 6 comment capturer proprement ces erreurs ; pour l'instant, retenez surtout la règle : UTF-8 par défaut, utf-8-sig pour les fichiers venant d'Excel, et ne lisez jamais un fichier sans avoir réfléchi à son origine.

Un mot sur les retours à la ligne, car ils font partie des mêmes surprises. Windows utilise deux caractères, le retour de chariot puis le passage à la ligne, alors que Linux et macOS n'en utilisent qu'un. Python normalise automatiquement cette différence en lecture et se charge de produire le bon format en écriture, si bien que votre code fonctionne à l'identique partout. La seule situation où vous devrez y penser concerne le module csv, qui réclame par convention l'ouverture avec newline="" pour éviter l'apparition de lignes vides parasites dans les fichiers produits sous Windows. Nous reviendrons sur ce détail dans la section consacrée aux tableaux. Cette normalisation vous épargne de devoir comparer des chaînes contenant des caractères de fin de ligne différents selon la plateforme, un piège classique lorsqu'on écrit des fichiers à la main depuis un programme transféré d'un système à un autre. Retenez simplement la règle pratique : `newline=""` pour tout ce qui concerne le module csv.
$lesson$),
  ('py-c5-p7', 'py-c5', 7, $lesson$Parcourir un CSV avec csv.DictReader$lesson$, $lesson$
Le format CSV, pour comma-separated values, est devenu le lingua franca des exports de données tabulaires. Son principe est d'une simplicité extrême : chaque ligne du fichier représente un enregistrement, chaque champ d'un enregistrement est séparé par une virgule, et la première ligne nomme les colonnes. Un fichier notes.csv contenant l'en-tête nom,note puis Camille,15.5 décrit donc une petite table de deux colonnes. Ce format présente un avantage décisif : il est lisible par un humain, parsable par n'importe quel langage, et exportable depuis n'importe quel tableur. Tous les logiciels de gestion, les bases de données et les services en ligne savent produire et consommer des CSV, ce qui en fait le pont naturel entre Excel et vos scripts Python. Sa contrepartie tient dans la pauvreté même du format : aucun type n'y est stocké, tout y est du texte, et c'est au lecteur de réinterpréter chaque champ. C'est exactement le travail que vous allez déléguer au module csv dans un instant, plutôt que de le réécrire vous-même à chaque nouveau fichier.

La tentation des débutants consiste à découper les lignes soi-même avec la méthode split(","). Cela fonctionne tant que vos données sont simples, puis échoue silencieusement dès qu'un champ contient une virgule, par exemple un nom composé ou une adresse, ou un guillemet, qui est justement le caractère réservé du format pour entourer un tel champ. Le module csv de la bibliothèque standard sait gérer tous ces cas : il reconnaît les champs entre guillemets, les virgules qu'il ne faut pas utiliser comme séparateurs, les échappements et même les fins de ligne présentes à l'intérieur d'un champ. Son utilisation se limite à importer le module et à créer un lecteur, le reste du travail ressemblant à une simple boucle for. Le module s'occupe également des fins de ligne, y compris celles qui changent selon que le fichier a été produit sous Windows, Linux ou macOS, ce qui vous dispense d'une couche de gestion que vous auriez sinon à écrire et à déboguer pour rien.

```python
import csv

with open("notes.csv", encoding="utf-8") as fichier:
    for ligne in csv.reader(fichier):
        print(ligne)
```

La classe csv.reader renvoie chaque enregistrement sous forme de liste de chaînes. C'est déjà très pratique, mais l'outil vraiment confortable est la classe csv.DictReader, qui transforme chaque ligne en dictionnaire dont les clés sont les en-têtes de la première ligne. Vous accédez donc aux champs par leur nom plutôt que par leur position, ce qui rend le code beaucoup plus résistant : si l'ordre des colonnes change dans le fichier, ou si une colonne supplémentaire apparaît, votre programme continue de fonctionner. C'est exactement le type de structure que vous manipulez depuis le chapitre 4, et c'est aussi la raison pour laquelle les imports et les exports deviennent si simples avec cette approche. Cette résistance aux changements de format est un critère de qualité à part entière : un script d'analyse qui survit à l'ajout d'une colonne par le service comptable vous rendra service bien au-delà de la démonstration actuelle. Comparez cela avec un accès par index, où un simple réordonnancement des colonnes suffit à inverser silencieusement vos données.

```python
import csv

with open("notes.csv", encoding="utf-8") as fichier:
    lecteur = csv.DictReader(fichier)
    for ligne in lecteur:
        nom = ligne["nom"]
        note = float(ligne["note"])
        print(f"{nom} : {note} points")
```

Deux précautions accompagnent systématiquement DictReader. La première est typologique : chaque valeur reste une chaîne de caractères, même si elle représente un nombre. Il faut donc convertir explicitement avec float ou int dès que vous devez calculer, et c'est précisément cette conversion qui fera échouer proprement un fichier mal rempli, par exemple une note écrite avec une virgule française. La deuxième est structurelle : les clés du dictionnaire sont exactement les en-têtes du fichier, espaces compris. Si votre tableur a produit nom , note, l'accès ligne["note"] lèvera une KeyError. L'habitude de vérifier les clés disponibles, par exemple avec print(ligne.keys()) lors de la première exécution, vous fera gagner un temps précieux. Une variante prudente consiste à lire la première ligne du lecteur avant la boucle, à l'afficher, puis à décider des accès à effectuer. Enfin, si une valeur peut être absente, la méthode get du dictionnaire vous évitera l'erreur fatale en renvoyant une chaîne vide par défaut, que vous convertirez ensuite en nombre avec prudence.

La même logique s'applique à l'écriture, avec les classes csv.writer et csv.DictWriter. Ces objets prennent en paramètre le fichier ouvert, puis une liste de noms de colonnes pour DictWriter, qui fournit d'ailleurs une méthode dédiée pour produire la ligne d'en-tête. Vous remarquerez que l'ouverture du fichier demande alors le paramètre supplémentaire newline="", purement technique mais indispensable sous Windows pour éviter qu'une ligne vide n'apparaisse entre chaque enregistrement. Une dernière remarque concerne les tableurs français : ils utilisent volontiers le point-virgule comme séparateur de champs, faute de quoi la virgule décimale des notes entrerait en conflit avec le séparateur. Le paramètre delimiter=";" de DictReader et DictWriter répond exactement à ce cas de figure. Pensez également à conserver la première ligne d'en-tête lorsque vous modifiez un fichier existant : DictReader en a besoin à chaque nouvelle lecture, et son oublier transformerait votre première donnée en titre de colonne absurde. Avec ces quelques précautions, l'aller-retour complet entre un tableur et Python devient un jeu d'enfant.

```python
import csv

with open("export.csv", "w", encoding="utf-8", newline="") as fichier:
    champ = csv.DictWriter(fichier, fieldnames=["nom", "note"])
    champ.writeheader()
    champ.writerow({"nom": "Camille", "note": 15.5})
    champ.writerow({"nom": "Yanis", "note": 8})
```
$lesson$),
  ('py-c5-p8', 'py-c5', 8, $lesson$Exemple guidé : de notes.csv à rapport.txt$lesson$, $lesson$
Nous voici arrivés au cœur du chapitre : le script complet qui lit un fichier de notes, en calcule les statistiques, puis produit un rapport exploitable. Avant de le lire, assurez-vous simplement que le fichier notes.csv existe dans le dossier courant, en exécutant le bloc writelines de la section Écrire si ce n'est pas déjà fait. Le programme est organisé en trois fonctions, conformément à ce que vous avez appris au chapitre 3 : une fonction qui traduit une note en mention, une qui lit le fichier et renvoie une liste de dictionnaires, une qui rédige le rapport. L'exécution finale tient en deux lignes. Prenez le temps de taper ce code vous-même plutôt que de le copier : les détails de syntaxe, les retours à la ligne et les formats de nombres sont exactement ce qu'il faut ancrer par les doigts. Vous disposerez ensuite d'un modèle réutilisable pour tout autre tableau de même forme, et le fichier produit pourra être ouvert directement dans un éditeur de texte, puis transmis à votre enseignant sans aucune retouche.

```python
import csv

def mention_pour(note):
    if note >= 16:
        return "Très bien"
    if note >= 14:
        return "Bien"
    if note >= 12:
        return "Assez bien"
    if note >= 10:
        return "Passable"
    return "Insuffisant"

def lire_notes(chemin):
    notes = []
    with open(chemin, encoding="utf-8") as fichier:
        lecteur = csv.DictReader(fichier)
        for ligne in lecteur:
            eleve = {"nom": ligne["nom"], "note": float(ligne["note"])}
            notes.append(eleve)
    return notes

def ecrire_rapport(chemin, notes):
    total = sum(eleve["note"] for eleve in notes)
    moyenne = total / len(notes)
    meilleure = max(eleve["note"] for eleve in notes)
    with open(chemin, "w", encoding="utf-8") as fichier:
        fichier.write("Rapport de notes de la classe\n")
        fichier.write("=============================\n\n")
        fichier.write(f"Élèves pris en compte : {len(notes)}\n")
        fichier.write(f"Moyenne de la classe : {moyenne:.2f} / 20\n")
        fichier.write(f"Meilleure note : {meilleure:.2f} / 20\n\n")
        fichier.write("Détail par élève :\n")
        for eleve in notes:
            note = eleve["note"]
            ligne = f"- {eleve['nom']} : {note:.1f} -> {mention_pour(note)}\n"
            fichier.write(ligne)

eleves = lire_notes("notes.csv")
ecrire_rapport("rapport.txt", eleves)
print(f"rapport.txt mis à jour pour {len(eleves)} élèves")
```

Commençons par lire_notes, la fonction qui fait le pont entre le disque et vos structures Python. Elle reçoit un chemin, ce qui la rend réutilisable pour n'importe quel fichier de même forme, puis ouvre ce chemin en mode lecture avec le bloc with et encoding="utf-8". La ligne suivante crée un lecteur DictReader, qui sait que la première ligne du fichier contient les noms des colonnes. La boucle for parcourt alors le fichier ligne à ligne, sans jamais charger plus d'un enregistrement en mémoire, et chaque itération fournit un dictionnaire dont les clés sont nom et note. C'est la concrétisation de tout ce que la section précédente décrivait : la structure tabulaire du fichier se transforme en dictionnaires familiers, prêts à être consommés par le reste du programme. Rien dans cette fonction ne dépend du contenu réel des notes : elle se borne à convertir, ce qui la rend réutilisable telle quelle pour une autre classe, un autre devoir ou un autre tableau partageant les mêmes colonnes.

La construction du dictionnaire eleve mérite une attention particulière. Les valeurs lues dans le CSV sont des chaînes, y compris les notes : DictReader ne devine pas que 15.5 est un nombre. L'appel float(ligne["note"]) effectue donc la conversion indispensable, et c'est lui qui garantit que le calcul de moyenne sera arithmétique et non lexicographique. Sans cette conversion, la moyenne n'aurait aucun sens et le max comparerait des textes. Notez également que la liste notes est créée en dehors du with et retournée après la fermeture du fichier : les données ont été copiées en mémoire, le fichier n'est plus nécessaire. C'est une distinction importante, car garder une référence à un fichier clos ne servirait à rien, alors que la liste, elle, reste parfaitement utilisable. Si vous préférez, vous pouvez construire la liste par compréhension à l'intérieur du bloc with, ce qui raccourcit encore la fonction sans rien changer à son comportement ni à sa robustesse.

La fonction mention_pour illustre un classique des chaînes de conditions apprises au chapitre 2, mais avec une subtilité de logique : les tests sont écrits du seuil le plus élevé au plus bas, avec des retours précoces. Si vous inversiez l'ordre et que vous testiez d'abord note >= 10, un élève de 17 obtiendrait Passable, car ce premier test serait vrai et la fonction s'arrêterait là. L'ordre des branches est donc partie intégrante de l'algorithme, pas un détail de présentation. Pour vos propres programmes, gardez cette habitude d'écrire les cas généraux après les cas particuliers, ou de placer un return à chaque branche, afin qu'aucune trajectoire ne puisse traverser la fonction sans produire une valeur. Cette fonction n'a par ailleurs aucun effet de bord : elle ne lit rien, n'écrit rien, et renvoie simplement une chaîne. C'est ce que l'on attend d'une fonction utilitaire, et cette pureté la rend aisément testable, par exemple en vérifiant qu'une note de 16 renvoie bien la mention Très bien.

Passons aux calculs. La somme des notes est obtenue par une compréhension dans l'appel à sum, une forme compacte que vous connaissez déjà, puis la moyenne s'obtient en divisant cette somme par len. La variable meilleure utilise la fonction intégrée max, qui parcourt la même collection et renvoie l'élément le plus grand : inutile d'écrire une boucle pour cela. Deux hypothèses méritent d'être signalées honnêtement : la liste n'est jamais vide, sinon len vaudrait zéro et la division échouerait, et chaque note est convertible en nombre, sinon float aurait levé une erreur dès la lecture. Ces deux situations sont exactement celles que le chapitre 6 vous apprendtra à détecter et à traiter proprement, avec des exceptions et des messages d'erreur explicites pour l'utilisateur. Pour l'instant, le contrat est implicite : notes.csv existe et respecte le format décrit. Assurez-vous que votre fichier de démonstration remplit bien ces deux conditions avant de lancer le script, et tout se passera comme prévu.

L'écriture du rapport se fait en mode "w", puisqu'il s'agit de remplacer intégralement le rapport de la session précédente. Chaque bloc de texte est produit par un appel à write, avec un retour à la ligne explicite à la fin, et les valeurs numériques sont insérées dans des f-strings. Observez les formats : :.2f affiche la moyenne et la meilleure note avec deux décimales, ce qui donne une présentation lisible et régulière, tandis que :.1f suffit pour les notes individuelles. Le tiret de début de ligne dans la chaîne détail forme une liste simple à l'œil sans avoir besoin d'un vrai formatage de tableau. Si le fichier de sortie n'existait pas, il serait créé ; s'il existait, il serait vidé puis réécrit, ce qui garantit qu'un double lancement ne produira jamais deux rapports collés l'un à l'autre. Si vous souhaitez conserver l'historique des sessions, ouvrez plutôt un fichier de journal en mode "a" et ajoutez-y la moyenne du jour, de sorte que les bilans successifs s'accumulent au lieu de se remplacer.

Une fois le script exécuté, le fichier rapport.txt contient un en-tête, le nombre d'élèves traités, la moyenne de la classe, la meilleure note, puis une ligne par élève associant sa note à sa mention. Avec l'exemple de quatre élèves utilisé tout au long du chapitre, la moyenne affichée sera 13.25 sur 20, la meilleure note 17.00, et les mentions se répartiront entre Très bien pour Amina, Bien pour Camille, Assez bien pour Lucas et Insuffisant pour Yanis. Ouvrez le fichier avec n'importe quel éditeur de texte pour vérifier que les accents y figurent correctement : c'est la preuve concrète que la spécification d'encodage a produit son effet. Cette vérification manuelle, que vous ferez les premiers jours, deviendra un réflexe : elle vous confirme en une seconde que le fichier attendu a bien été créé, à l'emplacement voulu, avec le contenu escompté. Ouvrez aussi le dossier de travail pour constater que rapport.txt y figure : les chemins relatifs ont bien été résolus depuis le dossier de lancement.

Si vous voulez prolonger l'exercice, plusieurs extensions sont à portée de main et n'exigent aucune connaissance nouvelle. Vous pouvez trier les élèves par note décroissante avant d'écrire le rapport, ce qui donne un classement naturel sans effort particulier : la fonction intégrée sorted accepte une clé de tri sous forme de fonction lambda, et le paramètre reverse inverse l'ordre pour faire remonter les meilleures notes en tête. Le résultat est une nouvelle liste, laissant la liste d'origine parfaitement intacte, ce qui vous permet d'afficher un classement tout en conservant l'ordre de lecture du fichier si besoin. Le tri s'effectue sur la note convertie en nombre et non sur la chaîne, ce qui garantit un classement réellement numérique. Une seule ligne suffit donc à transformer un rapport simple en véritable palmarès, et vous enchaînez ensuite sur l'affichage, le formatage ou l'écriture d'un second fichier. Notez enfin que sorted fonctionne sur n'importe quelle collection, ce qui vous sera utile bien au-delà de ce chapitre.

```python
classement = sorted(eleves, key=lambda eleve: eleve["note"], reverse=True)
premier = classement[0]
print(f"Premier de la classe : {premier['nom']}")
```

Vous pouvez aussi compter les mentions dans un dictionnaire, ce qui vous ramène directement aux compétences du chapitre 4, ou encore enregistrer l'historique des moyennes en ouvrant un fichier journal en mode "a" plutôt qu'en réécrivant toujours le même rapport. Chaque variante utilise les mêmes briques : un with, une lecture ou une écriture, un encodage explicite. C'est la démonstration que la maîtrise des fichiers ne demande pas un répertoire immense de connaissances, mais une poignée de gestes correctement compris et systématiquement appliqués. Avant de passer à la vidéo, essayez donc de modifier le script pour qu'il produise un second fichier, mentions.csv, contenant le nom de l'élève et sa mention, avec DictWriter. Vous retrouverez ainsi, dans un seul programme, les trois compétences du chapitre : lire un fichier, calculer sur ses données, écrire un résultat. C'est exactement le geste professionnel que vous accomplirez chaque fois qu'un collègue vous enverra un export et vous demandera un bilan. Le passage de l'exercice au projet se joue souvent là.
$lesson$),
  ('py-c5-p9', 'py-c5', 9, $lesson$À retenir$lesson$, $lesson$
- Un fichier se référence par un chemin, absolu ou relatif au dossier depuis lequel vous lancez Python.
- La fonction open prend le chemin, le mode, puis l'encodage, et renvoie l'objet fichier avec lequel vous travaillez.
- Mode "r" pour lire, mode "w" pour écrire en effaçant l'existant, mode "a" pour ajouter à la fin du fichier.
- Le bloc with ferme le fichier automatiquement, même si une erreur survient au milieu du traitement : c'est la forme à retenir par cœur.
- Précisez systématiquement encoding="utf-8", à la lecture comme à l'écriture, pour éviter les surprises d'accents.
- read() charge tout le fichier en mémoire, readline() lit une ligne, une boucle for sur le fichier parcourt ligne à ligne avec une empreinte minimale.
- write() n'ajoute aucun retour à la ligne : ajoutez \n vous-même, et rappelez que seules les chaînes sont acceptées.
- writelines() reçoit une liste de chaînes mais n'insère rien entre les éléments.
- En mode "w", l'ancien contenu disparaît définitivement : utilisez "a" pour compléter un journal ou un historique.
- Un chemin comme C:\donnees\notes.csv doit être écrit en chaîne brute ou avec des barres doubles sur Windows.
- Le module csv gère les séparateurs et les champs entre guillemets bien mieux qu'un split fait à la main.
- csv.DictReader transforme chaque ligne en dictionnaire indexé par les en-têtes, et ses valeurs restent des chaînes à convertir.
$lesson$),
  ('py-c5-p10', 'py-c5', 10, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : ouvrir un fichier puis oublier close, surtout en cas d'erreur en cours de traitement → correction : utilisez le bloc with, qui referme la ressource à la sortie du bloc dans tous les cas.
- Piège : ouvrir en mode "w" pour compléter un fichier existant → correction : passez en mode "a", seul mode qui écrit à la fin sans effacer le contenu précédent.
- Piège : FileNotFoundError dès la première ligne → correction : le chemin est faux ou le dossier courant n'est pas celui attendu ; affichez le chemin avant l'ouverture et vérifiez le dossier depuis lequel vous lancez le script.
- Piège : UnicodeDecodeError ou caractères illisibles du type Ã© à l'affichage → correction : précisez encoding="utf-8" à l'ouverture, ou utf-8-sig si le fichier provient d'un export Excel contenant un marqueur d'ordre de bits.
- Piège : un CSV lu d'un bloc donne une seule colonne de texte bizarre → correction : utilisez le module csv et csv.DictReader au lieu de découper les lignes avec split.
- Piège : KeyError du type "note" en accédant au dictionnaire d'une ligne → correction : les en-têtes ne correspondent pas exactement, souvent à cause d'un espace ou d'une casse ; affichez lecteur.fieldnames pour inspecter les clés réelles.
- Piège : TypeError indiquant que write() attend une chaîne → correction : convertissez la valeur avec str ou insérez-la directement dans une f-string.
- Piège : lignes vides entre les enregistrements d'un CSV écrit sous Windows → correction : ouvrez le fichier avec newline="" en plus de encoding="utf-8" lorsque vous utilisez le module csv.
$lesson$),
  ('py-c5-p11', 'py-c5', 11, $lesson$Pour aller plus loin$lesson$, $lesson$
Le tutoriel officiel de Python consacre un chapitre entier à l'entrée-sortie, avec de nombreux exemples de lecture, d'écriture et de formats structurés : https://docs.python.org/fr/3/tutorial/inputoutput.html. Vous y trouverez notamment les détails avancés sur la gestion des retours à la ligne et sur les chaînes de formatage, qui complètent utilement ce que vous venez d'apprendre. La page de référence de la fonction open, quant à elle, décrit exhaustivement tous les modes, tous les paramètres, dont encoding, errors et newline, ainsi que les méthodes de l'objet fichier : https://docs.python.org/fr/3/library/functions.html#open. Gardez cette page en signet, car elle répond à presque toutes les questions précises que vous vous poserez en écrivant vos propres scripts. La documentation est également disponible hors connexion dans la distribution Python, sous la forme d'une aide accessible avec la fonction intégrée help, à laquelle vous pouvez passer open ou csv. Prenez l'habitude de la consulter avant d'inventer une solution, parce que la plupart des questions ont déjà été posées.

Pour approfondir les tableaux, la documentation du module csv présente à la fois DictReader et DictWriter, les options de délimiteur, la gestion des champs multi-lignes et quelques pièges classiques du format : https://docs.python.org/fr/3/library/csv.html. Un aller-retour vers cette page vous évitera de réinventer un parseur, ce qui reste, même expérimenté, une mauvaise idée. Vous pouvez aussi explorer le module pathlib, qui propose une approche orientée objet des chemins de fichiers et rend vos programmes plus lisibles lorsque l'arborescence se complique. Dans la même famille, le module json sert aux données structurées imbriquées, et le module os.path aux opérations sur les dossiers : ces trois-là, avec csv, couvrent la quasi-totalité des besoins quotidiens en entrée-sortie. Une soirée de lecture dans la documentation vous suffira pour les découvrir, et vous constaterez alors que la plupart des exemples y ressemblent étrangement à ceux de cette leçon, ce qui est le meilleur signe que vous avez bien compris l'essentiel. N'hésitez pas à les essayer sur de petits fichiers de test.
$lesson$),
  ('py-c5-p12', 'py-c5', 12, $lesson$Et maintenant : la vidéo du chapitre$lesson$, $lesson$
La vidéo du chapitre reprend exactement le même chemin que cette leçon, mais en le montrant à l'écran : vous verrez un fichier s'ouvrir, se lire ligne à ligne, se compléter en mode ajout, puis se transformer en rapport, tout au long d'une démonstration commentée pas à pas. Regardez-la avec ce texte à côté de vous, en relançant les exemples sur votre propre machine au fur et à mesure. Ensuite, l'exercice pratique vous mettra en main le projet du chapitre : partir d'un fichier notes.csv, calculer la moyenne, déterminer la note maximale et les mentions, puis écrire le tout dans un rapport.txt. Le quiz de quatre questions viendra enfin vérifier que la fermeture garantie, le mode ajout, le lecteur de dictionnaires CSV et la spécification de l'encodage UTF-8 sont bien ancrés. Entraînez-vous ensuite sur vos propres données : un export de notes, un relevé de dépenses, une liste de contacts suffisent à vous convaincre que ces quelques lignes de code vous suivront partout, dans tous vos futurs projets Python.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('py-c6-p1', 'py-c6', 1, $lesson$Comprendre : ce qui se passe quand Python s'arrête net$lesson$, $lesson$
Après le chapitre 5, votre programme sait lire un fichier de notes : il ouvre le fichier, parcourt ses lignes, transforme chaque ligne en nombre puis calcule une moyenne. Cette chaîne fonctionne parfaitement tant que tout se passe comme prévu. Or, dans la vraie vie, presque rien ne se passe comme prévu : l'utilisateur renomme le fichier, une ligne contient une virgule au lieu d'un point, le disque est plein, la connexion tombe au milieu d'un téléchargement. Programmer, ce n'est donc pas seulement écrire du code qui marche quand tout va bien, c'est surtout écrire du code qui sait réagir quand quelque chose ne se passe pas comme prévu. Les exceptions sont exactement le mécanisme que Python a conçu pour cette situation : elles signalent qu'une opération a échoué, interrompent le flux normal d'exécution et permettent de rattraper la panne au bon endroit, pour proposer une réponse compréhensible à l'utilisateur plutôt qu'un écran de traceback brut que personne n'a envie de voir apparaître.

Quand une exception traverse toutes les fonctions sans jamais être attrapée, Python arrête le programme, affiche un traceback et rend la main au système. Cette réaction est saine : mieux vaut s'arrêter net que d'écrire des données corrompues dans un fichier ou d'afficher une moyenne inventée de toutes pièces. Le problème tient au moment et au destinataire de ce message : l'arrêt arrive souvent après dix minutes de traitement, et le texte affiché s'adresse au programmeur alors que c'est l'utilisateur qui est devant l'écran. Deux compétences suffisent à transformer complètement cette situation. La première consiste à lire un traceback pour localiser précisément l'erreur : la ligne fautive, la chaîne d'appels qui y mène, le type d'erreur. La seconde consiste à anticiper les pannes attendues avec try et except, au seul endroit où elles peuvent survenir, afin de transformer une panne en message utile sans jamais masquer les vrais bugs de votre logique.

C'est exactement le programme de ce chapitre, sixième étape sur huit du parcours Python, et chaque objectif correspond à une compétence que le mini-projet exigera de vous. Vous apprendrez d'abord à décoder un traceback, de la dernière ligne remontée jusqu'à la ligne fautive, même lorsque plusieurs fonctions s'enchaînent les unes après les autres. Vous verrez ensuite comment encadrer un code risqué avec un bloc try assorti d'un except précis, ce qui vous permet d'attraper l'erreur attendue sans avaler toutes les autres. Enfin, vous verrez que vos propres fonctions peuvent lever des erreurs explicites avec raise, par exemple une ValueError pour une note hors bornes : c'est souvent plus honnête que de renvoyer None et de laisser l'appelant deviner ce qui s'est passé. À la fin de ce chapitre, votre calculateur de moyenne sera prêt pour le mini-projet, avec des messages clairs pour l'utilisateur, un mode debug intact pour vous, et des ressources toujours libérées, même en cas de panne.



Une exception n'est pas un simple message d'erreur affiché à l'écran : c'est un véritable objet, avec un type, un message et un contexte d'exécution. Python possède toute une famille d'objets issus de BaseException, et chaque problème attendu ou inattendu possède son type : FileNotFoundError, ValueError, TypeError, KeyError, et bien d'autres. Quand une condition anormale est détectée, Python crée une instance du type correspondant et la lance, ce que le code exprime avec le mot-clé raise. L'instruction en cours est alors interrompue immédiatement, et Python entame une recherche de l'endroit du programme capable de traiter cet événement. L'essentiel à comprendre est que l'erreur n'est pas écrite dans le fichier source à l'avance : elle est produite pendant l'exécution, à une ligne précise, alors que les lignes précédentes ont toutes réussi leur mission. Une exception, c'est donc un événement dans la vie du programme, pas une faute de frappe dans votre texte.

Il faut distinguer soigneusement les erreurs de syntaxe, repérées avant même l'exécution, et les exceptions survenues pendant l'exécution. Une accolade oubliée ou un deux-points manquant produit une SyntaxError : Python refuse de démarrer le fichier, aucune instruction n'est exécutée, et le correcteur indique immédiatement la ligne fautive. À l'inverse, une division par zéro, un fichier introuvable ou un mot converti en nombre plantent le programme alors qu'il tourne déjà, parfois depuis plusieurs secondes. Cette distinction a une conséquence pratique très utile : si votre script affiche un traceback alors qu'il était en pleine exécution, tout ce qui précède le dernier cadre a parfaitement fonctionné. L'erreur est donc locale à une instruction précise, et non le symptôme d'un programme entièrement cassé. Cette lecture optimiste du plantage, c'est le point de départ du débogage efficace, et elle vous évite de conclure trop vite que l'ensemble du script est à réécrire. Gardez cette distinction en tête, car elle oriente toutes les décisions qui suivent dans ce chapitre.

Le traceback expose la chaîne d'appels qui mène à l'erreur, et cette chaîne n'est pas décorative : elle raconte l'histoire complète de l'accident. Chaque appel de fonction empile un nouveau cadre sur la pile d'exécution, ce cadre contenant les variables locales et la ligne en cours d'évaluation. Quand une exception surgit, Python parcourt cette pile vers le haut à la recherche d'un bloc except compatible avec le type levé. Si aucun gestionnaire n'est trouvé, Python abandonne, arrête le programme et compose le rapport que vous connaissez sous le nom de traceback. Ce rapport liste les cadres depuis l'appel le plus ancien jusqu'à l'appel le plus récent, d'où la mention anglophone most recent call last qui ouvre presque toujours l'affichage. Lire un traceback, c'est donc remonter un fil : partir du symptôme affiché en bas et remonter la pelote des fonctions appelées jusqu'à trouver l'endroit exact où la réalité a divergé de vos attentes.

Pour être efficace, il faut savoir que le traceback contient trois catégories d'information, et que leur ordre de lecture n'est pas anodin. La dernière ligne donne le type de l'exception et son message : c'est le diagnostic, la cause déclarée de l'arrêt, et c'est toujours par elle qu'il faut commencer. Au-dessus, chaque cadre indique un nom de fichier, un numéro de ligne, le nom de la fonction et le code source de l'instruction incriminée : c'est la localisation. Entre le bas et le haut, la liste des cadres montre comment le programme est arrivé là : c'est le récit. Un lecteur pressé commence souvent par le haut du rapport, là où se trouve le nom d'un fichier de bibliothèque qu'il ne connaît pas, et s'y perd. Le lecteur averti lit d'abord la dernière ligne, puis le cadre le plus bas de ses propres fichiers, puis remonte la chaîne tant que la question pourquoi reste sans réponse. Ce mouvement en zigzag, du bas vers le haut et retour, fait gagner des heures.

Un arrêt brutal n'est pas forcément un échec de conception, c'est parfois la réponse la plus honnête que votre programme puisse donner. Lorsque l'état interne devient incohérent, continuer revient à fabriquer des résultats douteux en silence : une moyenne calculée sur trois notes au lieu de vingt, un fichier réécrit à moitié, une sauvegarde vidée puis remplacée par du vide. Python vous pousse donc vers une philosophie d'échec rapide : si vous ne savez pas réparer la situation, arrêtez net et expliquez pourquoi, plutôt que de poursuivre avec des données fausses. Le traceback, dans ce cas, est un outil de transparence : il refuse de faire semblant que tout va bien. La difficulté commence lorsque vous savez réparer, ou du moins lorsque vous pouvez transformer la panne en un message utile : c'est là que le bloc try entre en jeu, et c'est aussi là que le risque de masquer un vrai bug devient réel.

Toutes les exceptions ne méritent pas le même traitement, et leur origine guide votre décision. On distingue couramment deux grandes familles. La première regroupe les échecs liés à l'environnement ou aux données : fichier absent, format inattendu, valeur hors bornes saisie par un humain, connexion refusée. Ces pannes sont normales, prévisibles, et souvent hors de votre contrôle : elles doivent être attrapées, transformées en message clair, puis traitées. La deuxième famille regroupe les incohérences de votre propre logique : un indice calculé à tort, une variable initialisée dans une branche oubliée, un dictionnaire interrogé avec une clé que votre algorithme devait garantir. Ces erreurs révèlent un défaut de programme, pas un défaut de données : les attraper revient à cacher votre propre faute sous le tapis, souvent pour la redécouvrir beaucoup plus loin, sous une forme encore plus obscure et bien plus coûteuse à corriger. C'est l'origine de l'échec, et non sa gravité apparente, qui détermine la conduite à tenir.

Cette distinction conduit à une règle de placement très concrète : on protège les points d'entrée externes, on laisse les incohérences de logique exploser. Un point d'entrée externe, c'est une frontière entre votre programme et le reste du monde : la saisie clavier, la lecture d'un fichier, un appel réseau, le parsing d'un format écrit par quelqu'un d'autre. À ces endroits, une erreur est une information précieuse qu'il faut intercepter pour décider quoi faire. À l'intérieur de vos algorithmes, en revanche, une exception signale presque toujours que votre raisonnement a un trou : en la rattrapant trop tôt, vous transformez un bug bruyant en résultat silencieusement faux. Concrètement, la logique métier d'une fonction de calcul doit rester sans protection : elle lève, elle ne décide pas de ce qu'on fera de l'échec. C'est l'appelant, au niveau de l'interface ou du script principal, qui choisira d'afficher un message, de proposer une nouvelle saisie ou d'arrêter le traitement.

Cette façon de voir les exceptions change le statut du message d'erreur : il devient un contrat entre les couches de votre programme. Une fonction bas niveau signale un problème avec un type précis et un message explicite ; la couche supérieure décide s'elle sait traiter le problème ou si elle doit le relayer vers son propre appelant. Le type choisi est le vocabulaire de ce contrat : ValueError pour une valeur qui respecte le type mais pas le domaine attendu, TypeError pour un type incorrect, FileNotFoundError pour une ressource absente. Un message de qualité se lit comme une phrase adressée à quelqu'un, avec le contexte nécessaire pour agir : la valeur reçue, la plage attendue, le nom du fichier concerné. C'est d'ailleurs une des raisons pour lesquelles lever vos propres erreurs vaut mieux que renvoyer un code d'échec anonyme : un message bien écrit est de la documentation que le programme exécute lui-même, et que vous relisez inévitablement trois semaines plus tard au détour d'un traceback. Retenez enfin, avant d'entrer dans le détail des mécanismes, les règles essentielles qui gouvernent tout le reste de ce chapitre : elles forment le résumé opérationnel de la philosophie que vous venez de lire, et chaque section suivante en développera une face pratique, avec du code exécutable et des erreurs volontairement provoquées.

- Une exception est un objet levé à l'exécution : son type décrit la nature du problème, son message apporte le contexte.
- Un traceback non intercepté arrête le programme et décrit la chaîne d'appels jusqu'à la ligne fautive : c'est une information, pas une insulte.
- On lit la dernière ligne d'abord, puis le cadre le plus bas du code que vous possédez, puis on remonte la chaîne.
- On attrape les erreurs attendues aux frontières du programme, avec un type précis correspondant au problème.
- On laisse les incohérences de logique remonter jusqu'à vous, surtout pendant les tests, plutôt que de les masquer.
- Un except vide ou trop large transforme un bug visible en résultat faux silencieux : c'est le pire des scénarios.
- Une erreur métier mérite d'être levée explicitement, avec un message que l'appelant peut afficher tel quel.
- finally s'exécute toujours, même quand une exception remonte : c'est l'endroit réservé au nettoyage.

Pour visualiser la frontière entre ce que vous protégez et ce que vous laissez parler, voici les situations typiques d'un script qui lit des fichiers, classées selon la conduite à tenir. La première catégorie correspond aux points d'entrée externes : ce sont des zones où une panne est normale, parce qu'elles dépendent de données ou d'un équipement que vous ne contrôlez pas, et où un except précis transforme l'accident en message utile pour l'utilisateur. La deuxième catégorie correspond aux incohérences de logique : ces défauts proviennent de votre propre code, ils signifient que votre raisonnement a un trou, et les attraper reviendrait à cacher ce trou au lieu de le réparer. La liste suivante réunit les deux familles, chaque ligne indiquant explicitement la catégorie à laquelle elle appartient, afin que vous puissiez l'utiliser comme une checklist lors de la relecture d'un script qui touche à des fichiers ou à des saisies.

- Point d'entrée à protéger : la saisie utilisateur, qui peut fournir un texte là où un nombre était attendu.
- Point d'entrée à protéger : l'ouverture et la lecture d'un fichier, dont le nom, le format et l'existence ne sont pas garantis.
- Point d'entrée à protéger : les conversions de données, comme float sur une ligne mal formée.
- Point d'entrée à protéger : les appels réseau ou les accès à des ressources partagées, sujets aux pannes temporaires.
- Point d'entrée à protéger : le parsing de toute structure produite par un programme tiers.
- Logique à laisser exploser : un indice ou une clé que votre algorithme promettait d'avoir préparé.
- Logique à laisser exploser : une variable oubliée dans une des branches d'une condition.
- Logique à laisser exploser : un type inattendu produit par votre propre code interne, pas par l'extérieur.
- Logique à laisser exploser : une règle métier violée par vos calculs, par exemple une somme négative de notes.
- Logique à laisser exploser : un appel de fonction avec des arguments que vous maîtrisez entièrement.
$lesson$),
  ('py-c6-p2', 'py-c6', 2, $lesson$Lire un traceback : du symptôme à la ligne fautive$lesson$, $lesson$
Prenons un scénario tout simple, directement issu du chapitre 5 : un script lit un fichier de notes, additionne chaque ligne convertie en nombre et affiche le total. Le fichier a été rédigé par un utilisateur habitué aux tableurs, qui a saisi 14,5 avec une virgule, conforme à ses habitudes mais pas au format attendu par float. Ce genre d'écart est si banal qu'aucun test unitaire ne le prévoit forcément, et pourtant il suffit à interrompre un traitement qui tournait depuis plusieurs minutes. Plutôt que de spéculer sur ce qui a mal tourné, la méthode consiste à laisser parler Python : relancez le script dans un terminal, sans redirection ni enveloppe, et lisez attentivement ce qu'il affiche avant de toucher à la moindre ligne de code. C'est ce que nous allons faire ensemble, en gardant le programme le plus court possible, non par paresse, mais parce qu'un traceback se lit d'autant plus vite que la chaîne d'appels est réduite.

```python
def moyenne_lignes(chemin):
    total = 0
    with open(chemin, encoding="utf-8") as fichier:
        for ligne in fichier:
            total += float(ligne)
    return total

def rapport():
    notes = moyenne_lignes("notes.txt")
    return notes

print(rapport())
```

L'exécution s'interrompt brutalement au moment de la conversion, aucune moyenne n'est affichée, et Python imprime sur la sortie standard un rapport détaillé. Ce rapport n'est pas un simple message : c'est une structure codée, dont la forme est strictement la même d'un système à l'autre, ce qui vous permet de le lire où que vous travailliez. Nous le reproduisons ci-dessous tel quel, légèrement tronqué en haut pour rester lisible sur la page : la seule différence avec votre écran est la première ligne remplacée par trois points, qui correspond au cadre du niveau module, c'est-à-dire à la ligne qui a déclenché l'appel initial. Prenez le temps de le détailler ligne à ligne avant de poursuivre, car toute la suite du chapitre consiste précisément à apprendre à le décoder rapidement, sans vous disperser dans les détails qui n'apportent rien. Vous constaterez qu'aucun mot n'y est décoratif : chaque ligne correspond à une information précise que vous saurez réclamer plus tard.

```text
Traceback (most recent call last):
  ...
  File "moyenne.py", line 10, in rapport
    notes = moyenne_lignes("notes.txt")
  File "moyenne.py", line 5, in moyenne_lignes
    total += float(ligne)
ValueError: could not convert string to float: '14,5'
```

Les trois points de la première ligne remplacent le cadre du niveau module, celui qui a lancé l'appel initial : on l'ignore presque toujours au début d'une investigation, car il se contente de répéter la ligne print du programme. Tout le reste du rapport se lit comme un récit à l'envers. Le programme a appelé rapport, qui a appelé moyenne_lignes, qui a tenté de convertir une ligne en nombre, et c'est là que tout s'est arrêté. Aucune de ces étapes n'est suspecte en soi : le suspect, c'est la donnée que la dernière instruction a reçue. Remarquez aussi que le rapport ne contient aucune interprétation de la part de Python : il se contente de décrire les faits, l'ordre des appels et la phrase prononcée au moment de l'échec, ce qui fait de lui un témoin fiable, là où un message résumé, affiché par un code de secours mal pensé, aurait nécessairement perdu une partie du contexte utile à la reconstitution.

La compétence la plus rentable du débogueur débutant consiste à lire ce rapport de bas en haut. Commencez par la toute dernière ligne : elle donne le type de l'exception, ici ValueError, et son message, qui cite même la chaîne fautive, '14,5'. Vous savez déjà quelle famille de problème vous affrontez et quelle donnée l'a déclenché. Remontez ensuite d'un cran : le cadre indiqué, la ligne 5 de moyenne_lignes, est l'endroit exact où Python a constaté l'échec. C'est souvent la bonne localisation, mais pas toujours la cause profonde, comme nous le verrons plus bas. Enfin, remontez la chaîne des cadres tant que votre question pourquoi reste sans réponse : chaque cadre vous dit qui a appelé qui, avec quelles valeurs concrètes. Trois cadres, trois questions, et l'histoire de l'accident se reconstitue comme un fil que l'on tire. Ne cherchez pas à tout comprendre d'emblée : la dernière ligne et le cadre du bas suffisent dans la grande majorité des cas.

Une nuance importante distingue l'endroit où l'exception a été détectée de l'endroit où la donnée défaillante a été fabriquée. Dans l'exemple précédent, la valeur '14,5' n'a pas été créée à la ligne 5, elle est arrivée là tout droit depuis le fichier. Si vous corrigez aveuglément la ligne 5, le problème suivant surgira à la ligne suivante du fichier. Le bon réflexe est donc de remonter d'un cran dans la chaîne pour comprendre d'où viennent les valeurs entrantes, puis de décider où agir : corriger la donnée, corriger la conversion, ou refuser proprement le fichier. Ce mouvement explique pourquoi la chaîne d'appels n'est pas une liste de coupables, mais une liste de témoins : elle indique le trajet de la donnée fautive, et ce trajet, une fois reconstitué, désigne presque toujours l'étape où une validation aurait dû avoir lieu. Cherchez cette étape plutôt que le coupable : c'est là que le correctif sera durable.

Le premier exemple restait volontairement court, avec deux fonctions seulement. Pour mesurer toute l'utilité de la chaîne d'appels, il faut une structure plus réaliste, où le travail est découpé en plusieurs petites fonctions, comme le recommandait le chapitre 3 : chacune se charge d'une tâche précise et délègue à la suivante. Voici donc un programme en quatre fonctions, toujours très simple, mais suffisamment profond pour que l'erreur apparaisse loin de l'endroit où la donnée a été préparée : la panne se produit au troisième élément d'une liste mêlant des nombres et un texte, alors que cette liste est fournie par l'appelant du haut de la chaîne. Avant de lire le rapport, essayez de deviner le nom de l'exception que Python va prononcer, puis vérifiez votre intuition : cette petite étape de prévision transforme une lecture passive en exercice d'analyse, et c'est exactement l'habitude que vous développerez en visionnant la vidéo du chapitre.

```python
def additionner(total, valeur):
    return total + valeur

def total_notes(notes):
    total = 0
    for note in notes:
        total = additionner(total, note)
    return total

def moyenne_classe(notes):
    return total_notes(notes) / len(notes)

def afficher(notes):
    return moyenne_classe(notes)

print(afficher([12, 15, "absent"]))
```

Voici le rapport produit par cette exécution. Il comporte désormais quatre étages, un pour chaque appel empilé depuis le niveau module jusqu'à l'instruction en échec, et sa lecture de bas en haut se déroule sans ambiguïté une fois que vous savez quelles lignes regarder en premier. Notez la régularité de la structure : chaque cadre répète le même triplet nom de fichier, numéro de ligne, nom de fonction, puis cite le code source de l'instruction incriminée, ce qui vous évite même d'ouvrir l'éditeur pour situer le problème. Entraînez-vous à repérer d'abord la toute dernière ligne, puis le cadre immédiatement au-dessus : cette seule habitude vous fera gagner les deux tiers du temps habituellement consacré à un débogage, car dans la très grande majorité des cas, ces deux informations suffisent à désigner la cause et la localisation exacte du dysfonctionnement. Le reste du rapport ne sert que dans les cas têtus, où l'origine du problème se cache plusieurs appels plus haut.

```text
Traceback (most recent call last):
  ...
  File "classe.py", line 15, in afficher
    return moyenne_classe(notes)
  File "classe.py", line 11, in moyenne_classe
    return total_notes(notes) / len(notes)
  File "classe.py", line 7, in total_notes
    total = additionner(total, note)
  File "classe.py", line 2, in additionner
    return total + valeur
TypeError: unsupported operand type(s) for +: 'int' and 'str'
```

Dernière ligne d'abord : TypeError, et le message dit explicitement que Python ne sait pas additionner un entier et une chaîne. Cadre du bas ensuite : la ligne 2 tente d'additionner total et valeur. Puis on remonte : c'est total_notes qui a envoyé la troisième valeur, et c'est donc dans sa boucle que se cache la vraie leçon, à savoir que la liste pouvait contenir autre chose que des nombres. Une fois corrigée la cause, à savoir la composition de la liste, plus aucun des quatre cadres ne se manifestera jamais. Retenez cette habitude : lisez le diagnostic, localisez la ligne, remontez jusqu'à l'origine des données, puis ne revenez en bas que pour appliquer le correctif au bon niveau. Si vous appliquez cette méthode trois ou quatre fois de suite, vous constaterez qu'elle se transforme en réflexe : en quelques secondes, vous saurez si le problème vient d'une donnée, d'un type ou d'une règle, et vous aurez déjà en tête le bout de code à corriger avant même d'avoir ouvert votre éditeur.
$lesson$),
  ('py-c6-p3', 'py-c6', 3, $lesson$Les exceptions courantes de Python$lesson$, $lesson$
La bibliothèque standard définit des dizaines d'exceptions, mais un script qui lit des fichiers, transforme des nombres et calcule des moyennes n'en rencontrera qu'une poignée. Apprendre ce petit répertoire par cœur vous fait gagner un temps considérable, car le nom de l'exception correspond presque toujours au mot que vous utiliseriez pour décrire le problème à un collègue : on ne dit pas « plantage », on dit « valeur hors domaine » ou « fichier manquant ». Cette correspondance entre le vocabulaire de l'erreur et le vocabulaire du métier est ce qui rend le débogage rapide, puisque le type suffit à orienter l'investigation avant même que vous n'ayez lu le message détaillé. Les exceptions que vous rencontrerez le plus souvent dans ce parcours sont réunies ci-dessous, avec pour chacune la situation typique qui la déclenche dans un programme de traitement de notes. Relisez la liste une première fois en diagonal, puis une seconde fois en cherchant, pour chaque type, l'erreur analogue que vous avez déjà rencontrée depuis le début du parcours.

- ValueError : le type est bon, mais la valeur est hors du domaine attendu, comme float("14,5") ou une note de 25 sur un barème de 20.
- TypeError : le type lui-même est inapproprié, comme l'addition d'un nombre et d'une chaîne, ou l'appel d'une fonction avec le mauvais nombre d'arguments.
- IndexError : une liste est consultée à un indice qui n'existe pas, par exemple notes[7] quand la liste en contient trois.
- KeyError : un dictionnaire est interrogé avec une clé absente, par exemple eleve["prenom"] quand seule la clé nom est renseignée.
- FileNotFoundError : on demande à ouvrir un fichier qui n'existe pas à l'emplacement indiqué, typique après un renommage ou un changement de dossier.
- OSError : la famille des erreurs système, qui regroupe notamment les problèmes de permission, de disque plein ou de chemin invalide.
- ZeroDivisionError : une division dont le dénominateur vaut zéro, souvent le symptôme d'une liste vide dont on calcule la moyenne.
- AttributeError : une propriété ou une méthode demandée n'existe pas sur l'objet, par exemple une faute de frappe dans le nom d'une variable.
- StopIteration : un itérateur est épuisé prématurément, ce que vous rencontrerez surtout en écrivant vos propres générateurs.
- ImportError : un module ou un nom importé est introuvable, annonce du chapitre 7 sur les packages.

```table
Exception | Déclencheur | Exemple
--- | --- | ---
`ValueError` | le type est bon, mais la valeur est hors du domaine attendu | `float("14,5")` ou une note de 25 sur un barème de 20
`TypeError` | le type lui-même est inapproprié | l'addition d'un nombre et d'une chaîne
`IndexError` | une liste consultée à un indice qui n'existe pas | `notes[7]` quand la liste en contient trois
`KeyError` | un dictionnaire interrogé avec une clé absente | `eleve["prenom"]` alors que seule la clé nom est renseignée
`FileNotFoundError` | ouverture d'un fichier absent à l'emplacement indiqué | après un renommage ou un changement de dossier
`ZeroDivisionError` | une division dont le dénominateur vaut zéro | une liste vide dont on calcule la moyenne
```

Ces types ne flottent pas en liberté : ils s'organisent dans une hiérarchie, et comprendre cette arborescence vous évite trois erreurs classiques. Toutes les exceptions de ce tableau descendent de Exception, qui descend lui-même de BaseException. En revanche, deux événements très particuliers, KeyboardInterrupt levé par le fameux Ctrl+C et SystemExit levé par sys.exit, descendent directement de BaseException sans passer par Exception. Résultat concret : un bloc except Exception n'interceptera jamais votre Interruption clavier, ce qui est une bonne nouvelle, car un programme qui refuse de s'arrêter avec Ctrl+C est un programme que l'on doit tuer depuis le gestionnaire de tâches. Pour cette raison, on utilise except Exception comme filet de sécurité de dernier recours, et jamais except BaseException. Pratique supplémentaire : quand vous voulez savoir quels types une exception possède, tapez `type(erreur).__mro__` dans votre interpréteur, ou consultez simplement la dernière ligne du traceback, qui donne toujours le type exact, sans ambiguïté possible.

Choisir le bon type quand vous écrivez votre propre code suit la même logique que choisir le bon mot dans une phrase. Si le problème vient de la forme, c'est-à-dire du type reçu, levez un TypeError. Si la forme est correcte mais que la valeur sort du domaine autorisé, levez un ValueError. Si une recherche dans une structure associative a échoué, laissez Python lever un KeyError ou levez un FileNotFoundError pour une ressource absente. Si l'échec vient du système d'exploitation, laissez remonter l'exception OSError d'origine plutôt que d'inventer un message vague. Ce vocabulaire précis a un effet immédiat sur vos blocs except : chaque type déclenche un traitement différent, donc chaque erreur appelle la réponse appropriée, sans que vous ayez besoin d'analyser des chaînes de caractères pour comprendre ce qui s'est passé. C'est aussi ce qui rend vos messages lisibles pour l'utilisateur final : le type interne est traduit par votre gestionnaire en une phrase du domaine, tandis que le détail technique part dans le journal, à destination de celui qui corrigera le code.

Un dernier point rassurant avant de coder : vous n'avez pas besoin de connaître la liste exhaustive pour écrire du code correct, pas plus qu'on n'a besoin de tout savoir en orthographe pour écrire une lettre. En pratique, on mémorise d'abord cinq ou six types, on apprend à lire le message que Python fournit, et on remonte le reste en consultant la documentation au fil des besoins. Cette montée en compétence est progressive : au début, vous chercherez le type dans un tableau, puis vous le reconnaîtriez au premier regard dans un traceback. Un exercice extrêmement utile consiste à provoquer volontairement chaque erreur une fois, dans un environnement contrôlé, pour observer le comportement exact de votre interpréteur et vérifier que votre bloc except attrape bien le type attendu. Le bloc de code suivant est conçu pour cela : il déclenche les erreurs les plus courantes, les attrape immédiatement et les affiche, de sorte que le programme se termine sans jamais planter.

```python
def demonstrer():
    try:
        int("12a")
    except ValueError as erreur:
        print("ValueError :", erreur)
    try:
        [12, 15, 18][7]
    except IndexError as erreur:
        print("IndexError :", erreur)
    try:
        {"nom": "Ada"}["prenom"]
    except KeyError as erreur:
        print("KeyError :", erreur)
    try:
        open("fichier_inexistant.txt", encoding="utf-8")
    except FileNotFoundError as erreur:
        print("FileNotFoundError :", erreur)
    try:
        10 / 0
    except ZeroDivisionError as erreur:
        print("ZeroDivisionError :", erreur)
    try:
        12 + "absent"
    except TypeError as erreur:
        print("TypeError :", erreur)

demonstrer()
```
$lesson$),
  ('py-c6-p4', 'py-c6', 4, $lesson$try, except, else, finally : l'anatomie d'une protection$lesson$, $lesson$
Le bloc try délimite ce que l'on appelle une zone de risque : Python exécute ses instructions une à une, dans l'ordre, et à la première exception survenue, il abandonne immédiatement le reste du bloc pour rechercher un except correspondant. Cette mécanique a une conséquence directe sur la façon dont vous devez écrire votre code : la zone try doit être la plus petite possible. Chaque instruction supplémentaire placée sous la garde de try est une instruction dont l'erreur légitime pourra être capturée à tort par un gestionnaire conçu pour un autre problème. Si vous enserrez cinquante lignes dans un seul try destiné à attraper un fichier manquant, une simple faute de frappe survenant à la quarantième ligne sera avalée par le même except, qui renverra alors un résultat inventé au lieu de vous alerter. La bonne pratique consiste à n'encadrer que l'opération réellement risquée, à savoir l'ouverture, la lecture ou la conversion, et à laisser tout le reste du programme travailler hors protection.

Le ou les clauses except constituent le cœur de la protection. Chaque clause commence par le type d'exception qu'elle accepte de traiter, éventuellement suivi de as pour capturer l'objet erreur et l'utiliser ensuite dans le message ou dans un journal. Lorsqu'une exception est levée, Python les examine dans l'ordre où vous les avez écrites et s'arrête à la première dont le type correspond. Cet ordre n'est pas anodin : placez toujours les types les plus précis avant les types généraux, car Python ne les classe pas automatiquement du plus spécifique au plus large. Si aucun except ne correspond, l'exception n'est pas perdue pour autant : elle continue de remonter la pile d'appels, à la recherche d'un gestionnaire dans l'appelant, puis dans son propre appelant, jusqu'à ce qu'un bloc la prenne en charge ou que Python affiche le traceback et arrête le programme. Votre bloc n'est donc jamais obligé de tout absorber : il peut décider, au contraire, de laisser passer ce qu'il ne comprend pas.

La clause else, souvent méconnue, s'exécute uniquement quand le bloc try s'est terminé sans lever la moindre exception. Son intérêt est double. D'abord, elle matérialise visuellement la séparation entre la zone risquée et la suite normale du traitement : on lit un fichier sous protection, puis on exploite le résultat hors protection. Ensuite, elle réduit encore la taille du try, conformément au principe énoncé plus haut : tout ce qui transforme, trie ou calcule à partir de données déjà lues n'a rien à faire dans la zone de risque. Le contenu du else n'est pas protégé : si une erreur logique s'y produit, elle remonte normalement, ce qui est exactement le comportement souhaité, puisque cette erreur révèle un défaut de votre code et non un défaut de l'environnement. On retient la règle simple : ce qui dépend de l'extérieur se place sous try, ce qui dépend de votre raisonnement se place sous else ou après le bloc.

La clause finally est la promesse la plus facile à vérifier : son contenu s'exécute toujours, dans tous les cas. Que le bloc try se termine normalement, qu'une exception soit attrapée par un except, qu'une exception non attrapée poursuive sa remontée, qu'un return interrompt la fonction ou qu'une boucle break : finally passe à l'exécution quand même. C'est l'emplacement réservé au nettoyage, c'est-à-dire aux opérations qui doivent avoir lieu quelle que soit l'issue : libérer un verrou, fermer une connexion qui échappe à votre gestionnaire de contexte, afficher un bilan final, remettre un drapeau à zéro. Dans l'exemple ci-dessous, la fermeture du fichier est déjà assurée par le mot-clé with, aussi finally sert-il uniquement à produire un message de fin. Notez qu'un bloc try suivi de finally, sans aucun except, est parfaitement valide : c'est la façon idiomatique d'ajouter un nettoyage tout en laissant l'exception continuer sa route vers votre appelant.

```table
Bloc | Quand il s'exécute | Rôle
--- | --- | ---
`try` | instruction par instruction, jusqu'à la première exception | délimite la zone de risque, à garder la plus petite possible
`except` | quand le type levé correspond à celui d'une clause | traite le problème attendu, sinon l'exception continue de remonter
`else` | uniquement si le `try` n'a rien levé | sépare la suite normale du traitement de la zone de risque
`finally` | toujours, dans tous les cas, même si une exception remonte | le nettoyage : libérer une ressource ou annoncer la fin
```

La théorie est utile, mais elle ne prend tout son sens qu'appliquée à un code complet que l'on peut exécuter, modifier et casser à volonté. L'exemple suivant réunit les quatre clauses dans un ordre de lecture naturel, avec une fonction qui reçoit un chemin de fichier, le lit sous protection, signale ses échecs par des messages explicites et produit à la fin la liste des notes converties. Prenez le temps de repérer visuellement chaque bloc avant de lire l'analyse : la zone try tient en trois lignes, chaque except traite un seul type de problème, la clause else affiche le bilan de la lecture et la clause finally annonce la fin de l'opération, quel qu'en soit le résultat. Cette grille de lecture vous servira pour tous les exemples qui suivent. Après la lecture, vous verrez que chaque clause répond à une question précise que vous vous poserez naturellement en écrivant votre propre code.

```python
def lire_notes(chemin):
    try:
        with open(chemin, encoding="utf-8") as fichier:
            lignes = [ligne.strip() for ligne in fichier]
    except FileNotFoundError:
        print(f"Le fichier {chemin} est introuvable.")
        return None
    except OSError as erreur:
        print(f"Lecture impossible : {erreur}")
        return None
    else:
        print(f"{len(lignes)} lignes lues avec succes.")
    finally:
        print("Bloc finally : execute dans tous les cas.")
    return [float(ligne) for ligne in lignes if ligne]

print(lire_notes("notes.txt"))
```

Suivons le parcours d'une exécution heureuse, fichier présent et bien formé : le try se termine sans encombre, la clause FileNotFoundError est ignorée, la clause else affiche le nombre de lignes lues, finally annonce la fin, puis la fonction renvoie la liste convertie. Maintenant supprimez le fichier : le open lève une FileNotFoundError, Python saute directement à la clause correspondante, affiche le message, et avant de renvoyer None, il exécute quand même finally. Troisième scénario, le fichier existe mais le disque est inaccessible : c'est une OSError, un autre except prend le relais, puis finally passe là aussi. Quatrième scénario, vous interrompez le programme avec Ctrl+C pendant la lecture : KeyboardInterrupt n'est couvert par aucun except, donc elle traverse le bloc, mais finally s'exécute sur son passage avant que l'exception ne continue sa remontée. Cette couverture complète est précisément ce qui justifie l'existence de finally. Notez enfin que le return situé après la clause finally ne s'exécute que si aucun except n'a renvoyé la fonction avant : l'ordre des clauses dicte le flux, et le dernier return n'est jamais atteint en cas d'échec.
$lesson$),
  ('py-c6-p5', 'py-c6', 5, $lesson$Attraper juste ce qu'il faut$lesson$, $lesson$
Le réflexe du débutant face à un plantage consiste à écrire un bloc try entourant tout le programme et à refermer avec un except sans type. Ce code compile, il s'exécute, et il est dangereux : un except nu équivaut à attraper n'importe quelle exception, y compris KeyboardInterrupt et SystemExit. Votre programme devient alors impossible à interrompre proprement avec Ctrl+C, et surtout, toute erreur inattendue disparaît sans laisser de trace, y compris les NameError et AttributeError qui trahissent vos propres fautes de frappe. Si une instruction mal orthographiée se trouve dans la zone protégée, votre gestionnaire, conçu pour signaler un fichier manquant, affichera un message sur le fichier manquant alors que la vraie cause est une variable inexistante. Le bug n'a pas été corrigé, il a été habillé, et vous passerez une heure à chercher un problème de fichier qui n'existe pas. C'est si fréquent qu'il existe un nom pour ce travers : on parle d'erreur masquée, la plus coûteuse de toutes, puisqu'elle transforme un échec bruyant en résultat silencieusement faux.

C'est pour cette raison qu'on enseigne la règle suivante : on attrape toujours un type précis. Si votre opération risquée est la lecture d'un fichier, écrivez un except pour FileNotFoundError, un pour OSError, éventuellement un pour ValueError si vous convertissez les lignes. Chaque type déclenche un message adapté au problème réellement survenu, et toute erreur qui n'entre pas dans cette liste continue sa route pour devenir visible, sous forme de traceback si personne d'autre ne la gère. Le filet large `except Exception` n'est pas interdit, mais il est réservé à un usage unique : le point d'entrée de votre script, où il sert de dernière chance pour transformer une panne inattendue en message propre et en code de retour, à condition de journaliser l'erreur complète au préalable. Partout ailleurs, il produit exactement le même effet qu'un except nu, avec une simple illusion de rigueur. Le test que vous pouvez vous poser est toujours le même : cette clause distingue-t-elle le problème attendu d'une faute de frappe dans votre propre code.

Le mot-clé as transforme l'exception en une variable que vous pouvez exploiter. En écrivant `except ValueError as erreur`, vous obtenez un objet dont le contenu varie selon le type : pour une ValueError, str(erreur) donne le message que vous avez fourni au moment du raise ou celui que la bibliothèque a généré. C'est cette variable qui vous permet d'afficher une phrase complète incluant la valeur fautive, de remplir un journal avec le détail exact, ou de décider d'une récupération selon le contenu du message. Lorsque plusieurs types appellent exactement la même réaction, Python accepte un tuple : `except (ValueError, TypeError)` évite de dupliquer le corps du gestionnaire. Réservez néanmoins cette commodité aux cas où le traitement est réellement identique ; si une erreur mérite un message différent, écrivez deux clauses distinctes, dans l'ordre du plus spécifique au plus général. Dans tous les cas, gardez à l'esprit que la variable capturée n'existe que dans le corps de la clause : elle ne vous suivra pas après le bloc try.

Un gestionnaire d'exception a trois devoirs : informer l'utilisateur, consigner le détail pour vous, puis décider de la suite. Informer, c'est produire une phrase qui dit ce qui s'est passé et ce que l'utilisateur peut faire, sans jargon Python. Consigner, c'est écrire l'erreur complète, traceback compris, dans un journal ou sur la console de développement, pour que l'information ne soit pas perdue au moment où vous en aurez besoin. Décider, c'est choisir explicitement entre trois issues : abandonner proprement avec un code retour ou une exception relancée, proposer une nouvelle tentative, ou proposer un repli avec des données partielles clairement signalées. Le corps `except ...: pass` ne fait rien de tout cela : l'exception est avalée, l'opération échoue silencieusement, et votre programme poursuit avec un résultat qu'il croit valide. C'est la pire des solutions, bien pire que laisser le programme planter, car un plantage au moins se voit, attire l'attention et déclenche immédiatement une investigation.

La dernière décision à prendre concerne le périmètre de la protection, surtout à l'intérieur des boucles. Si vous traitez mille lignes de fichier et que la dixième est mal formée, deux réponses sont défendables selon votre contrat. Si une seule ligne invalide doit invalider tout le lot, placez le try autour de l'ensemble de la boucle : le premier échec interrompt tout, vous signalez le fichier fautif, et vous ne traitez jamais un résultat partiel présenté comme complet. Si au contraire vous voulez signaler les lignes invalides tout en traitant les autres, placez le try dans la boucle, mais comptez les échecs, affichez le détail des lignes rejetées et restituez un rapport honnête. Ce qu'il ne faut jamais faire, c'est croire avoir choisi alors qu'on a simplement déplacé un try par réflexe : le périmètre du try est une décision de conception, pas une habitude de placement. Formulez-la d'ailleurs à voix haute avant d'écrire le bloc : quelle ressource externe est en jeu ici, et quelle réaction dois-je avoir si elle échoue.

Avant de passer à l'exemple comparatif de la fin de section, récapitulons les règles de placement qui résument tout ce que la pratique a confirmé. Elles tiennent en quelques lignes, mais chacune correspond à un travers réel rencontré par de nombreux débutants, souvent plusieurs fois de suite : imprimez-les ou recopiez-les près de votre écran jusqu'à ce qu'elles deviennent des automatismes de lecture et d'écriture du code. L'objectif n'est pas d'apprendre une liste par cœur, mais de vous doter d'un contrôle rapide à effectuer en relisant un bloc try : le type est-il nommé, la zone est-elle minimale, le gestionnaire agit-il concrètement, le nettoyage est-il confié à finally. Si vous répondez oui à ces quatre questions, votre protection est saine ; si une seule réponse hésite, relisez la section correspondante avant d'aller plus loin. Ces quelques secondes de relecture valent souvent mieux qu'une demi-heure de débogage ultérieur, précisément parce qu'elles déplacent la vérification au moment où le code est encore frais dans votre tête.

- Toujours nommer un type précis dans le except, en plaçant les types spécifiques avant les types généraux.
- Jamais de except nu : il attrape les interruptions clavier et masque vos propres fautes de frappe.
- Réserver except Exception à la frontière du script, avec journalisation complète avant tout message propre.
- Capturer l'erreur avec as pour enrichir le message affiché et la ligne de journal, plutôt que d'afficher un texte figé.
- Ne jamais écrire pass dans un gestionnaire : au minimum afficher un message, idéalement journaliser le traceback.
- Placer le try autour de l'opération qui dépend de l'extérieur, jamais autour de votre logique interne.
- Entourer un try sans except avec finally lorsqu'il s'agit uniquement de libérer une ressource.
- Signaler à l'utilisateur ce qu'il peut corriger, et consigner pour vous ce dont vous aurez besoin pour déboguer.

Il n'y a pas de meilleur moyen de mesurer l'écart entre une protection mal conçue et une protection ciblée que de les observer côte à côte, appliquées exactement à la même opération : lire un fichier supposé contenir un nombre unique et le convertir en virgule flottant. Les deux fonctions ci-dessous compilent toutes deux, toutes deux renvoient une valeur, et pourtant l'une produit des résultats trompeurs là où l'autre communique honnêtement. Examinez-les ligne à ligne en vous demandant, pour chacune, ce qui se passerait si le fichier n'existait pas, s'il contenait du texte ou s'il était illisible. Puis déroulez mentalement le cas où le chemin pointe vers un dossier au lieu d'un fichier, et celui où le disque répond par une erreur de permission. Vous constaterez que la deuxième fonction possède une réponse claire pour chacune de ces situations, tandis que la première les confond toutes dans un unique comportement silencieux.

```python
def lecture_insecuree(chemin):
    try:
        return float(open(chemin, encoding="utf-8").read())
    except:
        return 0.0

def lecture_protegee(chemin):
    try:
        with open(chemin, encoding="utf-8") as fichier:
            contenu = fichier.read()
        return float(contenu.strip())
    except FileNotFoundError:
        print(f"Le fichier {chemin} est introuvable.")
        return None
    except ValueError:
        print("Le fichier ne contient pas un nombre unique.")
        return None
    except OSError as erreur:
        print(f"Lecture impossible : {erreur}")
        return None

print(lecture_protegee("moyenne.txt"))
```

La première fonction présente trois défauts cumulés. Son except nu avale tout, donc une faute de frappe interne renverrait 0.0 en faisant croire que le fichier contenait zéro. Sa zone try englobe la conversion float comme l'ouverture, alors que seules ces deux opérations risquent réellement quelque chose, mais le gestionnaire unique ne peut pas distinguer les deux causes. Enfin, le fichier ouvert n'est jamais fermé, parce que le résultat de open n'est pas affecté à une variable gérée par with : en cas d'exception après l'ouverture, le descripteur fuit. La deuxième fonction sépare les responsabilités, nomme chaque type, restitue un message utile, renvoie None comme signal d'échec explicite et garantit la fermeture du fichier. C'est exactement le niveau d'exigence que le mini-projet du chapitre 8 attendra de vous. Vous pouvez le vérifier d'ailleurs en appelant lecture_insecuree avec un chemin inexistant : la fonction renverra 0.0 sans un mot d'explication, transformant une absence de donnée en donnée plausible, et le calcul suivant s'appuiera dessus comme si de rien n'était.
$lesson$),
  ('py-c6-p6', 'py-c6', 6, $lesson$Lever ses propres erreurs avec raise$lesson$, $lesson$
Le mot-clé raise est le miroir exact de except : là où un bloc except reçoit une erreur, un raise en crée une, à l'endroit de votre choix, avec le type et le message de votre choix. Une fonction qui détecte une situation interdite n'a pas à renvoyer un code d'échec particulier, n'a pas à imprimer elle-même un message, et n'a surtout pas à continuer avec des données qu'elle sait invalides : elle lève une exception, s'arrête sur-le-champ, et laisse le soin à son appelant de décider quoi faire. Concrètement, la ligne raise ValueError("note hors bornes") fabrique une instance de ValueError et la lance dans la pile d'appels. Si aucun except ne la retient, le programme s'arrête et le traceback pointera exactement cette ligne, c'est-à-dire l'endroit où la règle métier a été enfreinte. C'est cette localisation immédiate qui fait de raise l'outil le plus honnête à votre disposition pour exprimer un refus.

Un bon message d'erreur se juge au critère suivant : peut-on corriger le problème sans rouvrir le code source. Dans le cas d'une note saisie par un humain, la personne a besoin de connaître la valeur rejetée et le domaine autorisé ; dans le cas d'un fichier, elle a besoin du nom du fichier et de la ligne fautive. Écrivez donc des messages composés de trois éléments : ce qui a été refusé, la valeur réellement reçue, et la règle attendue. La différence entre raise ValueError("erreur") et raise ValueError(f"note {note} hors bornes : le barème autorise {bas} à {haut}") est la différence entre une impasse et une indication. Ces messages sont aussi votre meilleure documentation vivante : relus dans un traceback trois semaines plus tard, ils rappellent la contrainte exacte que vous aviez en tête au moment d'écrire la fonction, sans que vous ayez besoin de reconstituer le contexte. Une bonne habitude consiste à relire ses messages à voix haute en simulant la personne qui les recevra : si la phrase sonne comme un reproche technique plutôt qu'une indication actionnable, réécrivez-la.

L'alternative historique consiste à renvoyer None quand quelque chose ne va pas, et cette alternative est une mauvaise idée presque toujours. Le None n'est pas un message, c'est une valeur ambiguë : elle peut être une absence légitime ou un échec, et rien dans son apparence n'invite l'appelant à vérifier quoi que ce soit. Résultat, un appelant pressé oublie le contrôle, multiplie la moyenne par un coefficient, et obtient un TypeError incompréhensible à dix lignes de la cause réelle. Pire encore, si None se trouve dans une liste ou un dictionnaire, l'erreur remontera encore plus loin, à un endroit où plus personne n'évoquera le fichier d'origine. La fonction qui lève, elle, impose sa vérification : l'appelant doit placer un try, et s'il ne le fait pas, le traceback l'indique en clair dès la première exécution. Une erreur qui ne peut pas être oubliée vaut mieux qu'un code d'échec qu'on peut ignorer.

Choisir le bon type, c'est aussi respecter un contrat que vous documentez dans la docstring de la fonction. Une fonction de calcul qui promet une moyenne entre deux bornes peut annoncer, en une phrase de sa documentation, les situations qui déclenchent une ValueError pour des données hors domaine et une TypeError pour des éléments non numériques. L'appelant sait alors exactement quels except préparer, sans deviner en lisant tout le corps du code. Ce contrat a une portée large : si vous décidez un jour de changer le mécanisme interne, par exemple en lisant un fichier au lieu de recevoir une liste, les exceptions levées restent les mêmes et votre appelant n'a rien à modifier. C'est la même logique que les valeurs de retour documentées du chapitre 3, avec en plus la garantie que l'échec ne peut pas passer inaperçu. Ce contrat vit donc à deux endroits : dans la docstring, pour celui qui appelle, et dans le code de la fonction, pour celui qui la maintient.

Lorsque vous attrapez une erreur existante pour la traduire en vocabulaire de votre domaine, conservez l'information d'origine grâce à la formation d'une chaîne d'exceptions. Le mécanisme est simple : rattraper une erreur, puis relancer votre propre exception à l'aide du mot-clé from. Le traceback affichera alors deux sections reliées, la cause initiale et la conséquence métier, au lieu de vous forcer à choisir l'une ou l'autre. Pour aller plus loin, vous pouvez définir vos propres classes d'exceptions : quelques lignes suffisent, et faire hériter votre classe de ValueError conserve la compatibilité avec tous les blocs except ValueError déjà écrits. Le bloc suivant illustre les deux techniques dans un convertisseur de notes qui refuse proprement les lignes illisibles tout en gardant la trace de l'erreur de conversion initiale. Notez que from conserve les deux niveaux d'information dans le traceback : Python affiche d'abord la cause d'origine, puis un lien explicite vers l'exception que vous avez levée, de sorte qu'aucune des deux ne se substitue à l'autre.

```python
class NoteHorsBornes(ValueError):
    pass

def convertir_notes(brut, bas=0, haut=20):
    notes = []
    for position, texte in enumerate(brut, start=1):
        try:
            note = float(texte)
        except ValueError as erreur:
            raise NoteHorsBornes(
                f"ligne {position} illisible : {texte!r}"
            ) from erreur
        if note < bas or note > haut:
            raise NoteHorsBornes(f"note {note} hors bornes")
        notes.append(note)
    return notes

try:
    print(convertir_notes(["12", "abc"]))
except NoteHorsBornes as probleme:
    print("Donnees invalides :", probleme)
```

Cette fonction illustre aussi un principe de placement : la conversion d'une ligne reste sous protection parce qu'elle dépend d'une donnée extérieure, mais la règle métier de bornes est appliquée par un raise placé hors de tout try. La fonction ne décide pas de ce qu'on fera d'une note de 25, elle le signale, et c'est l'appelant qui choisit d'afficher un message, de proposer une nouvelle saisie ou d'arrêter le traitement. En cas d'oubli du try côté appelant, le traceback s'arrêtera sur la ligne raise, avec le message complet : vous saurez en un coup d'œil que la règle violée est celle des bornes, et non celle de la conversion. Ajoutez que l'appelant peut traiter NoteHorsBornes comme un ValueError, puisque l'une est une sous-classe de l'autre : votre code existant continue donc de fonctionner. Le rôle de chaque couche reste ainsi net : la couche basse sait que la règle est enfreinte, la couche haute sait comment la présenter, et aucune des deux n'empiète sur le territoire de l'autre.
$lesson$),
  ('py-c6-p7', 'py-c6', 7, $lesson$Déboguer sans se mentir$lesson$, $lesson$
Il existe deux publics pour le même événement, et votre code doit servir l'un sans trahir l'autre. En développement, vous voulez tout voir : le type, le message, la chaîne complète des appels, les valeurs locales de chaque cadre. En production, l'utilisateur final veut une phrase claire et l'absence de jargon. Plutôt que d'écrire deux programmes, on utilise un drapeau, souvent nommé DEBUG, qui décide du comportement du gestionnaire. Si le drapeau est activé, le bloc except relance simplement l'exception avec un raise nu : l'original, traceback intact, remonte jusqu'au sommet et s'affiche. Si le drapeau est désactivé, le même bloc affiche un message lisible et se termine. Le point essentiel est que le relancement se fait dans la clause except elle-même, ce qui préserve le contexte complet de l'erreur initiale plutôt que d'en créer une nouvelle dénuée d'historique. En pratique, vous basculez entre les deux modes sans jamais modifier le code métier : un simple changement de valeur dans le drapeau suffit à faire apparaître ou disparaître le traceback.

La seconde règle du débogage honnête est de ne jamais perdre l'information au moment de la simplifier. Traduire une erreur en message utilisateur, c'est très bien, à condition de conserver quelque part la version détaillée. Le module logging fournit pour cela une méthode particulièrement adaptée : appelée depuis l'intérieur d'un except, elle écrit dans le journal non seulement le message, mais tout le traceback associé, sans que vous ayez à le reconstruire. Vous gagnez ainsi les deux mondes : l'utilisateur lit une phrase, et si le problème se répète, vous disposez de la pile d'appels exacte dans le journal, datée et localisée. Une variante manuelle existe avec le module traceback et sa fonction format_exc, utile quand vous voulez incorporer le rapport dans une chaîne de caractères, par exemple pour l'envoyer dans un fichier de rapport. Dans les deux cas, la discipline est la même : simplifier pour afficher, jamais simplifier pour oublier.

Il faut enfin garder à l'esprit qu'attraper une erreur ne corrige rien : cela ne change que le symptôme visible. Le cycle de débogage reste le même qu'il y a vingt ans : reproduire le problème, lire le diagnostic, isoler l'instruction, comprendre la cause, corriger, puis revérifier que l'erreur a disparu. Attraper l'exception pour faire taire le message saute directement à la fin du cycle, avec un résultat faux. Pour les invariants internes de votre code, Python propose l'instruction assert, qui lève une AssertionError quand une condition n'est pas respectée, par exemple une moyenne qui sortirait de son barème après calcul. Attention toutefois à sa limite : les assertions sont entièrement retirées quand Python est lancé avec l'option -O, donc elles servent à vérifier vos propres hypothèses en développement, jamais à valider des données venues de l'extérieur, qui doivent passer par des if et des raise. Retenez cette frontière : assert pour vos invariants, raise pour les données du monde réel.

Bâtir une habitude de vérification des chemins d'échec demande un petit effort d'imagination, mais épargne des heures plus tard. Avant de considérer une fonction terminée, testez-la au moins une fois dans chacune de ses pannes : fichier absent, ligne mal formée, liste vide, valeur hors bornes. Vérifiez que le message affiché est compréhensible par quelqu'un qui n'a pas lu votre code, et que le journal contient assez de détails pour retrouver la cause si le message revient en production. Ce faisant, vous découvrirez presque toujours un cas non prévu, une clause manquante ou un message trop vague : c'est le signe que le test a fait son travail. Le programme final que vous recherchez échoue bruyamment quand vous le développez et parle clairement quand on l'utilise : ces deux comportements ne s'opposent pas, ils se complètent. C'est d'ailleurs le critère que vous pourrez invoquer pour déclarer le chapitre acquis : si vous arrivez à faire planter votre script volontairement, à lire le traceback sans hésiter et à remettre ensuite le programme sur pied, vous maîtrisez l'essentiel.

```python
import logging

logging.basicConfig(level=logging.INFO)
JOURNAL = logging.getLogger("notes")
DEBUG = False

def lire_notes(chemin):
    try:
        with open(chemin, encoding="utf-8") as fichier:
            return [float(ligne) for ligne in fichier if ligne.strip()]
    except ValueError:
        if DEBUG:
            raise
        JOURNAL.exception("format invalide dans %s", chemin)
        print("Une ligne du fichier ne contient pas un nombre.")
        return []
    except OSError:
        if DEBUG:
            raise
        JOURNAL.exception("impossible de lire %s", chemin)
        print("Le fichier n'a pas pu etre lu.")
        return []

print(lire_notes("notes.txt"))
```
$lesson$),
  ('py-c6-p8', 'py-c6', 8, $lesson$Exemple guidé : valider des notes de 0 à 20$lesson$, $lesson$
Réunissons maintenant tout ce que le chapitre a présenté dans un programme unique, tel qu'on pourrait le retrouver dans le mini-projet du chapitre 8. Le cahier des charges tient en trois points : accepter des notes comprises entre 0 et 20, lever une ValueError explicite dès qu'une note sort du barème, et entourer l'exécution d'un try/except qui affiche une phrase compréhensible sans jamais perdre le traceback lorsque l'on développe en mode debug. Le programme se découpe donc en deux parties nettement séparées. La première est une fonction de calcul pur, celle du chapitre 3 enrichie d'une règle métier du chapitre 6 : elle ne lit aucun fichier, n'affiche rien, et signale ses refus par des exceptions. La seconde est le script principal, seul responsable des entrées sorties, du choix du message affiché et du comportement en cas de panne. Cette séparation n'est pas décorative : elle vous permet de tester la règle métier sans fichier, et de tester la lecture sans jamais toucher au calcul.

Commençons par la première partie : la fonction qui établit le contrat sur les données. Elle reste délibérément indépendante de tout ce qui est extérieur : ni fichier, ni affichage, ni drapeau de configuration, seulement une liste reçue en argument et une moyenne renvoyée en retour. C'est cette indépendance qui la rend si facile à tester, car vous pouvez l'appeler depuis un simple prompt Python avec n'importe quelle liste, y compris une liste vide ou volontairement invalide, sans préparer le moindre fichier préalable. Lisez-la en vous posant une question à chaque ligne : que se passe-t-il si l'argument est vide, si l'élément n'est pas un nombre, si la valeur sort du barème. Les trois questions trouvent leur réponse dans un raise, et ces trois raises constituent l'intégralité du contrat que la fonction impose à ses appelants, ni plus ni moins. C'est aussi cette séparation qui rendra les tests du chapitre 8 si simples à écrire.

```python
def moyenne_notes(notes, bas=0, haut=20):
    if not notes:
        raise ValueError("aucune note a calculer")
    total = 0
    for position, note in enumerate(notes, start=1):
        if not isinstance(note, (int, float)):
            raise TypeError(f"la note numero {position} n'est pas un nombre")
        if note < bas or note > haut:
            raise ValueError(
                f"note {note} hors bornes : le barème autorise {bas} à {haut}"
            )
        total += note
    return total / len(notes)
```

La deuxième partie est le script principal : il reçoit un chemin, lit le fichier, convertit les lignes et protège l'ensemble de l'exécution. Toute la théorie des sections précédentes y trouve sa place, dans un ordre que vous devriez désormais reconnaître : une zone try minimale, trois clauses except nommant chacune un seul type, une clause else réservée à l'affichage du succès et une clause finally pour le message de fin. Le drapeau DEBUG est déclaré au niveau module afin d'être modifiable en une ligne, en haut du fichier, sans toucher au reste du code. Notez que la conversion float et l'appel à la fonction de calcul se trouvent toutes deux sous try : toutes deux dépendent de données extérieures, l'une du contenu du fichier, l'autre du respect du barème par ces mêmes données extérieures. Tout le reste, affichage et configuration, se trouve relégué aux bords du bloc. Vous ne le modifieriez d'ailleurs jamais pour traiter un autre fichier.

```python
DEBUG = False

def principal(chemin):
    try:
        with open(chemin, encoding="utf-8") as fichier:
            lignes = [ligne.strip() for ligne in fichier if ligne.strip()]
        notes = [float(ligne) for ligne in lignes]
        moyenne = moyenne_notes(notes)
    except FileNotFoundError:
        print(f"Le fichier {chemin} est introuvable : verifiez son nom.")
    except ValueError as erreur:
        if DEBUG:
            raise
        print(f"Moyenne impossible a calculer : {erreur}")
    except OSError as erreur:
        if DEBUG:
            raise
        print(f"Erreur de lecture du fichier : {erreur}")
    else:
        print(f"Moyenne de la classe : {moyenne:.2f} / 20")
    finally:
        print("Traitement des notes termine.")

principal("notes.txt")
```

Voici ce que le terminal affiche selon le contenu du fichier, sans aucun autre changement de code. Les trois scénarios se terminent par le message de la clause finally, preuve visible que ce bloc passe à l'exécution quelle que soit l'issue du traitement. Reproduisez-les chez vous dans cet ordre : d'abord le cas nominal où tout fonctionne, puis le cas d'un fichier absent, enfin le cas d'une note hors barème, car c'est ce dernier que l'exercice pratique du chapitre vous demandera d'implémenter et de vérifier à votre tour. Observez aussi la précision des messages : aucun ne mentionne de nom de variable interne, aucun ne réclame la lecture du code source, et chacun laisse entrevoir une action corrective concrète pour la personne qui le reçoit à l'écran. Comparez ensuite ces sorties à ce qu'afficherait un programme dépourvu de tout try : un traceback brut présenté à l'utilisateur, ou pire, aucune sortie du tout parce que le traitement se serait arrêté en chemin.

```text
Cas 1 : fichier absent
Le fichier notes.txt est introuvable : verifiez son nom.
Traitement des notes termine.
Cas 2 : note hors bornes
Moyenne impossible a calculer : note 23.0 hors bornes : le barème autorise 0 à 20
Traitement des notes termine.
Cas 3 : fichier valide
Moyenne de la classe : 15.67 / 20
Traitement des notes termine.
```

Commençons par la fonction de calcul, qui est le véritable cœur de l'exercice. Elle applique le principe de validation à l'entrée : rien n'est calculé tant que la liste n'est pas déclarée recevable. L'ordre des contrôles n'est pas arbitraire. Le test sur la liste vide arrive en premier, parce qu'il supprime d'un coup la possibilité d'une division par zéro, qui surviendrait à la toute dernière ligne. Le contrôle de type arrive ensuite, avant toute comparaison : si vous compariez directement une chaîne à l'entier 0, Python lèverait bien une TypeError, mais avec un message technique et à une ligne qui ne correspondrait pas à la règle que vous vouliez faire respecter. Enfin vient le contrôle des bornes, le vrai objet du chapitre, qui déclenche une ValueError portant à la fois la valeur rejetée et le barème attendu. Chaque refus est donc signalé au moment exact où il est constaté, avec tout le contexte nécessaire pour le corriger. Cette séquence illustre une idée forte du chapitre : une fonction ne doit pas subir des données douteuses, elle doit les examiner avant de travailler, et refuser explicitement celles qu'elle ne saurait pas interpréter.

Passons au script principal, dont la zone try contient exactement ce qui dépend de l'extérieur. L'ouverture du fichier, la lecture de ses lignes et leur conversion en nombres sont trois opérations qui peuvent échouer pour des raisons qui n'appartiennent pas à votre logique : le fichier peut manquer, une ligne peut contenir du texte, le disque peut refuser l'accès. L'appel à moyenne_notes se trouve lui aussi sous try, car c'est lui qui applique la règle métier sur des données venues de la rue. Notez en revanche ce qui n'est protégé par rien : une faute de frappe produisant un NameError, une AttributeError ou n'importe quelle erreur que vous n'avez pas nommée dans un except remontera jusqu'au sommet et affichera un traceback complet. C'est volontaire : ces pannes signaleraient un défaut de votre code, pas un défaut des données, et vous avez intérêt à les voir clairement dès les premiers tests.

Les trois clauses except se lisent comme un tri par nature de problème. La première, FileNotFoundError, traite le cas le plus courant et le plus facile à corriger : un chemin erroné, un fichier renommé, un dossier de travail différent. Son message cite le chemin, donc l'utilisateur peut vérifier l'orthographe sans ouvrir le code. Attention à l'ordre des clauses : FileNotFoundError fait partie de la famille OSError, donc si vous placiez un except OSError avant, il avalerait le fichier manquant et afficherait un message générique qui perdrait l'information la plus utile. Les types spécifiques passent toujours en premier. La deuxième clause, ValueError avec as erreur, couvre deux situations distinctes mais appelant la même réaction : la conversion d'une ligne invalide et la note hors barème levée par la fonction de calcul. Grâce à as, le message affiché contient la précision exacte remontée du cœur métier, sans que le script ait besoin de deviner de quoi il s'agit.

Le drapeau DEBUG illustre la façon de servir deux publics sans dupliquer le code. En mode normal, le gestionnaire affiche une phrase claire et l'exécution se poursuit proprement. En mode debug, la ligne raise seule, placée au début de la clause, relance l'exception telle qu'elle a été capturée : Python conserve le type, le message et toute la chaîne d'appels qui a mené jusqu'à ce point. C'est la solution idéale pour examiner un problème de format dont vous ne connaissez pas encore l'origine exacte, puis repasser en mode normal une fois la cause identifiée. Notez que le relancement s'effectue depuis l'intérieur du gestionnaire : le rapport final affichera d'abord l'erreur d'origine, puis l'endroit où elle a été relancée, de sorte qu'aucune information intermédiaire n'est perdue au passage. C'est la même mécanique que vous utiliserez pour déboguer le mini-projet : un drapeau, deux comportements, un seul et même code métier. En cas de doute, conservez toujours la possibilité de repasser en mode trace.

La clause else n'accueille qu'une seule instruction, l'affichage du résultat, et c'est exactement ce que la théorie recommande. Afficher une moyenne déjà calculée et correctement formatée n'engage aucune ressource extérieure : si cette ligne échoue, c'est que votre code est en faute, et l'erreur mérite alors de remonter sans filtre. La clause finally, elle, imprime son message dans les trois cas de figure, y compris quand une exception vient d'être relancée en mode debug, puisque le nettoyage s'exécute avant que l'exception ne quitte définitivement la fonction. Pour l'utilisateur, l'avantage est immédiat : il sait toujours que le traitement a été mené jusqu'au bout et qu'aucune étape n'a été abandonnée en route, même quand le résultat n'a pas pu être produit. C'est exactement le rôle d'un bilan de fin d'opération : annoncer la fin avant de disparaître, plutôt que de laisser l'utilisateur se demander si le programme a encore une chance de répondre.

Reste une dernière vérification, celle que tout développeur responsable fait avant de rendre son travail : tester volontairement les chemins d'échec. Créez un fichier notes.txt contenant trois nombres valides, relancez, vérifiez le formatage sur deux décimales. Remplacez un nombre par 23, constatez le message hors bornes. Effacez le fichier, constatez le message d'absence. Puis passez DEBUG à True avec le cas invalide et observez le traceback complet vous désigner la ligne du raise dans la fonction de calcul. Si les trois scénarios produisent le comportement attendu, votre programme passe du statut de script fragile à celui de composant fiable, prêt à être importé par d'autres modules. C'est exactement l'étape que l'exercice pratique du chapitre vous demande de franchir ensuite, en partant du même calcul de moyenne que celui du chapitre 4. Conservez cette habitude au-delà du chapitre : chaque nouvelle fonction qui touche un fichier, une saisie ou un réseau mérite ses trois tests de panne avant même d'être branchée au reste du programme.
$lesson$),
  ('py-c6-p9', 'py-c6', 9, $lesson$À retenir$lesson$, $lesson$
- Une exception est un objet levé pendant l'exécution : son type nomme le problème, son message apporte le contexte.
- Sans gestionnaire, Python arrête le programme et affiche un traceback : l'arrêt est une information, pas un échec de votre part.
- Le traceback se lit de bas en haut : la dernière ligne donne le type et le message, le cadre du bas donne la ligne fautive.
- La chaîne d'appels décrit qui a appelé qui jusqu'à la ligne fautive : elle raconte le trajet de la donnée fautive.
- Le bloc try délimite la zone de risque, que l'on garde volontairement la plus petite possible.
- Le bloc except doit nommer un type précis : un except nu masque les erreurs inattendues et les interruptions clavier.
- La clause as donne l'objet erreur, dont le message enrichit à la fois l'affichage utilisateur et la ligne de journal.
- La clause else s'exécute uniquement quand le try n'a rien levé ; la clause finally s'exécute toujours, dans tous les cas.
- finally est réservé au nettoyage : libérer une ressource ou annoncer la fin, jamais renvoyer un résultat.
- On protège les points d'entrée externes, comme la saisie, les fichiers ou le réseau, et on laisse les incohérences de logique exploser.
- raise ValueError("note hors bornes") crée une erreur métier explicite, préférable au renvoi d'un None que l'appelant peut oublier de tester.
- En mode debug, un raise nu dans le except relance l'erreur d'origine avec sa chaîne d'appels intacte.
$lesson$),
  ('py-c6-p10', 'py-c6', 10, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : écrire `except:` nu pour faire disparaître un plantage. Correction : nommer les types attendus, par exemple `except ValueError:` puis `except OSError:`.
- Piège : attraper `except Exception` au cœur d'une boucle ou d'une fonction interne. Correction : réserver ce filet au point d'entrée du script, avec journalisation avant tout message propre.
- Piège : terminer un gestionnaire par pass. Correction : informer l'utilisateur, consigner l'erreur complète, puis décider explicitement de la suite : abandon, nouvelle tentative ou repli signalé.
- Piège : afficher un message sympathique sans conserver le détail, et perdre ainsi le traceback. Correction : appeler JOURNAL.exception ou traceback.format_exc avant de produire le message utilisateur.
- Piège : écrire un return dans une clause finally. Correction : ne placer dans finally que du nettoyage, car un return là supprime l'exception en cours et écrase la valeur de retour normale.
- Piège : entourer tout le programme d'un seul try. Correction : encadrer uniquement l'opération risquée, puis laisser la logique qui exploite le résultat travailler hors protection.
- Piège : lever une exception générique du type Exception("problème"). Correction : choisir le type le plus précis, ValueError pour le domaine, TypeError pour la forme, FileNotFoundError pour la ressource absente.
- Piège : renvoyer None quand une règle métier est violée. Correction : lever une erreur explicite, pour que l'appelant ne puisse pas ignorer l'échec et que le traceback désigne la règle enfreinte.
$lesson$),
  ('py-c6-p11', 'py-c6', 11, $lesson$Pour aller plus loin$lesson$, $lesson$
Pour approfondir la mécanique complète des exceptions, la documentation officielle de Python consacre un chapitre entier du tutoriel au sujet, sous le titre « Errors and Exceptions ». Vous y retrouverez, dans un ordre pédagogique proche de cette leçon, la lecture des tracebacks, la hiérarchie des objets d'exception, l'usage combiné de try, except, else et finally, ainsi que la levée d'exceptions personnalisées. Les exemples y sont courts et directement exécutables : ouvrez un interpréteur à côté de votre navigateur, recopiez chacun d'eux, puis cassez-le volontairement pour observer le résultat. Le paragraphe consacré aux actions de nettoyage vous confirmera le comportement de finally que nous avons décrit, et celui sur la formation des exceptions vous donnera des précisions supplémentaires sur le mot-clé from. Une relecture attentive de ce chapitre, une deuxième fois après avoir écrit vos premiers blocs try, vous surprendra par le nombre de détails que vous aurez alors envie de vérifier. Adresse à consulter avec votre navigateur habituel : https://docs.python.org/fr/3/tutorial/errors.html

Pour connaître la liste exhaustive des exceptions fournies par la bibliothèque standard, avec pour chacune la condition exacte de sa levée et sa place dans la hiérarchie des classes, la référence officielle des types intégrés fait foi. Elle est présentée sous forme d'un index alphabétique des classes, chacune décrivant en une phrase la situation qui la déclenche, les attributs utiles qu'elle porte éventuellement et les exceptions qu'elle englobe. Elle est particulièrement utile quand un traceback vous affiche un type que vous n'avez jamais rencontré : une lecture rapide du paragraphe correspondant vous indique en général la cause en une phrase. Gardez cette page en favori pendant toute la durée du parcours et prenez l'habitude de cliquer sur chaque nom de type apparaissant dans votre terminal. Vous y découvrirez aussi des exceptions que ce chapitre n'a pas citées, comme ArithmeticError ou LookupError, qui regroupent des familles entières dont les membres descendent. Adresse : https://docs.python.org/fr/3/library/exceptions.html
$lesson$),
  ('py-c6-p12', 'py-c6', 12, $lesson$Et maintenant : la vidéo du chapitre$lesson$, $lesson$
La vidéo du chapitre reprend exactement le même parcours, pas à pas et à l'écran : elle ouvre un traceback volontairement cassé, le lit ligne à ligne, construit ensuite un bloc try ciblé autour d'une lecture de fichier, puis termine sur la validation des notes 0 à 20 avec raise et le passage en mode debug. Regardez-la avec cette leçon à portée de main, en vous arrêtant à chaque pause pour comparer le code affiché avec celui que vous venez de lire. Une fois la lecture terminée, passez à l'exercice pratique : vous reproduirez le calcul de moyenne protégé, vous afficherez une phrase compréhensible en cas de note hors bornes et vous vérifierez que votre traceback reste intact lorsque vous activez le debug. Prenez le temps de casser volontairement votre propre version, car c'est en lisant vos propres tracebacks que la méthode de ce chapitre deviendra un réflexe durable. Vous aborderez alors les modules avec un code capable de survivre aux pannes ordinaires.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('py-c7-p1', 'py-c7', 1, $lesson$Comprendre : de la ligne de code au projet structuré$lesson$, $lesson$
Jusqu'ici, tout votre code tenait dans un seul fichier Python, ou presque. L'analyseur de notes que vous avez construit au chapitre 5 lisait un fichier de notes, calculait des moyennes et affichait le rapport : quelques centaines de lignes, une seule page à défiler, une impression de maîtrise totale. Or voici ce qui arrive toujours un peu plus tôt qu'on ne le croit : le fichier grossit, les fonctions s'empilent, les constantes s'entassent en haut du script, et vous commencez à faire défiler l'écran en cherchant « où était déjà la fonction qui calcule la mention ? ». À deux cents lignes, on s'y retrouve encore. À mille, on cherche. À deux mille, on duplique le code plutôt que de le retrouver, et la lisibilité devient la première victime collatérale du projet. Le chapitre 7 est donc le moment de changer d'échelle : vous ne construisez plus un script, vous construisez un projet, c'est-à-dire un ensemble de fichiers qui se parlent, se réutilisent et survivent à vos humeurs de développeur.

Vous connaissez déjà ce réflexe, mais à une échelle plus petite : au chapitre 3, vous avez appris à découper un long script en fonctions, parce qu'une fonction qui fait une seule chose se relit, se teste et se corrige plus facilement qu'un bloc de mille lignes. Les modules appliquent exactement la même idée un niveau au-dessus : au lieu de découper à l'intérieur d'un fichier, vous découpez le projet entre plusieurs fichiers. Une fonction regroupe des instructions qui se répondent ; un module regroupe des fonctions, des constantes et des structures de données qui se répondent. Le chapitre 5 vous a appris autre chose d'essentiel : un programme sérieux ne fabrique pas ses données, il les lit et les écrit dans des fichiers textuels. Il est temps de faire la même chose avec son propre code : votre programme doit désormais pouvoir être lu, copié, partagé et réinstallé sur une autre machine, à l'identique.

C'est précisément l'objectif de ce chapitre, qui se décline en trois compétences. D'abord, importer un module et choisir la bonne convention d'import, car la manière dont vous écrivez `import math` ou `from math import sqrt` change la lisibilité de tout le reste du fichier. Ensuite, découper un projet en plusieurs fichiers Python, avec une arborescence lisible et un point d'entrée unique. Enfin, installer et figer des dépendances avec pip, pour que votre projet tourne à l'identique sur l'ordinateur de votre collègue, sur une machine neuve ou dans six mois, après que votre environnement a été mis à jour. À la fin du chapitre, votre analyseur de notes sera réellement scindé en deux fichiers, `calc.py` et `main.py`, accompagnés d'un `requirements.txt` qui déclare la bibliothèque `rich` utilisée pour l'affichage. Tout ce que vous apprendrez ici servira directement le mini-projet du chapitre 8, où cette architecture deviendra le cadre dans lequel s'inscrira toute votre démarche.



Un module, en Python, c'est d'abord une réalité très concrète : un fichier portant l'extension .py. Dès que ce fichier contient du code exécutable, il est lui-même un module, sans aucune déclaration particulière à écrire, sans aucun registre à remplir. Vos fichiers `calculs.py` ou `lire_notes.py` des chapitres précédents étaient déjà des modules, vous ne le saviez simplement pas encore. Le nom du module est le nom du fichier sans l'extension .py, et il doit pouvoir être utilisé comme identifiant Python : c'est pourquoi l'on écrit des noms en minuscules, sans accent ni espace, éventuellement séparés par des underscores. Le contenu d'un module peut être tout ce que vous savez déjà écrire : définitions de fonctions, constantes, chaînes de caractères, appels à `print`, tests conditionnels. La seule différence, c'est que ce contenu n'est plus rangé dans le script principal : il est rangé dans un endroit nommé, ce qui change tout, car un endroit nommé se retrouve, se cite et se réutilise.

Importer un module, ce n'est pas copier son code dans votre fichier : c'est exécuter ce module une seule fois, puis mettre à disposition dans votre espace de noms un objet auquel vous accéderez. Concrètement, quand vous écrivez `import math` en tête de votre script, Python cherche le module `math`, l'exécute de haut en bas, ce qui définit toutes ses fonctions et ses constantes, puis vous donne accès au nom `math`. Vous appelez ensuite `math.sqrt(2)` pour solliciter la fonction `sqrt` qui vit dans ce module. Cette mécanique a une conséquence pratique importante : si vous importez deux fois le même module, ou si deux modules de votre projet l'importent, il n'est exécuté qu'une seule fois et tout le monde partage la même copie en mémoire. C'est ce que garantit le dictionnaire `sys.modules`, qui mémorise chaque module déjà chargé. Un import revient donc cher une fois, puis devient gratuit, et vous pouvez appeler la même ligne autant de fois que nécessaire sans jamais ralentir votre programme.

À quoi bon séparer le code en modules ? Pour quatre raisons qui se vérifient dès la première ligne écrite. La réutilisation : une fonction de calcul de moyenne placée dans `calc.py` sert au script principal, aux tests éventuels et au projet du chapitre suivant, sans jamais être recopiée. La lisibilité : un fichier de deux cents lignes qui fait une seule chose se relit en une minute, quand un fichier de deux mille lignes impose de chercher pendant dix. La testabilité : vous pouvez exécuter `calc.py` seul, avec des valeurs connues, sans lancer toute l'application ni lire le fichier de notes sur le disque. Enfin, la collaboration : deux personnes peuvent modifier `services.py` et `cli.py` en parallèle sans se marcher sur les pieds, alors qu'un fichier unique produit un conflit garanti à chaque sauvegarde. La règle est simple : quand vous hésitez à créer un module, c'est généralement que le moment est venu.

Un module n'est pas l'ennemi de la fonction, il l'héberge. Les fonctions que vous avez apprises au chapitre 3 restent l'unité de travail, celle qu'on lit, qu'on teste et qu'on réutilise ; le module devient simplement l'adresse où elles vivent ensemble. La conséquence est l'apparition d'une notion nouvelle, celle d'interface : un module bien conçu expose peu de noms, mais des noms bien choisis, documentés par une phrase de docstring. L'appelant n'a pas besoin de savoir comment la moyenne est calculée, seulement qu'elle existe, quels arguments elle attend et ce qu'elle renvoie. Une règle pratique vous aidera à dessiner cette frontière : si un nom n'est utilisé que dans son propre fichier, il reste en interne et peut garder un nom court ; s'il doit être appelé depuis un autre fichier, il mérite un nom explicite, stable, et une entrée dans la documentation du projet. C'est cette discipline qui fait la différence entre un empilement de fichiers et une petite bibliothèque personnelle.

Quand un projet grandit, des fichiers isolés ne suffisent plus : il faut les regrouper. Un package est un dossier qui contient des modules Python apparentés, signalé comme tel par la présence d'un fichier `__init__.py`. Ce fichier marque la frontière : Python sait que le dossier `notes/` est un package importable, et non un simple répertoire de travail où traînent des fichiers. Dans un package `notes`, vous rangerez par exemple `models.py` pour les structures de données, `services.py` pour la logique métier, `cli.py` pour la ligne de commande et l'affichage. L'import prend alors une forme hiérarchique : `from notes.services import moyenne`. L'intérêt n'est pas seulement esthétique : un package se nomme, se documente, se teste, se publie, et peut contenir lui-même des sous-packages, ce qui permet d'organiser un projet de cent modules sans jamais perdre le fil de son architecture. C'est aussi l'unité que l'on partage avec les autres, puisque l'on publie un package, jamais un fichier isolé.

Un projet structuré pose aussitôt une question pratique : quand on importe `calc.py` depuis `main.py`, faut-il que `calc.py` exécute quelque chose ? La réponse est non, et c'est exactement le rôle du garde `if __name__ == "__main__":`. Ce bloc ne s'exécute que lorsque le fichier est lancé directement par l'interpréteur, jamais lorsqu'il est importé par un autre. Grâce à lui, `calc.py` peut contenir à la fois des fonctions réutilisables et un petit script de démonstration ou de vérification, sans que la démonstration se déclenche à chaque import, au milieu du travail du fichier voisin. C'est la condition pour que vos modules restent silencieux et prévisibles, deux qualités que vous apprécierez dès que votre projet comptera cinq ou six fichiers qui s'importent les uns les autres dans plusieurs sens. Un chargement prévisible se débogue en quelques secondes, quand un enchaînement d'effets de bord oblige, lui, à relire le programme en entier.

Un projet n'utilise pas que son propre code : il s'appuie aussi sur des bibliothèques extérieures. C'est là qu'intervient pip, le gestionnaire de paquets officiel de Python, qui installe depuis Python Package Index des bibliothèques comme `rich` pour de belles sorties en terminal, `requests` pour les échanges HTTP ou `pytest` pour les tests automatisés. Installer est facile, presque trop : une ligne `pip install rich` et la bibliothèque est là, disponible partout sur votre machine. La difficulté commence ensuite, six mois plus tard, quand il faut reproduire l'environnement exact d'un autre développeur ou d'une machine neuve. La solution tient dans un fichier texte, `requirements.txt`, obtenu avec `pip freeze > requirements.txt`, qui liste chaque dépendance avec sa version exacte. Une commande `pip install -r requirements.txt` restaure alors l'environnement à l'identique. Vous en déduirez qu'une dépendance est un engagement de maintenance, que vous assumerez aussi longtemps que votre projet vivra avec elle.

Réunissons les pièces. Un projet Python bien organisé répond à trois questions en trois secondes : où est le code métier, où est le point d'entrée, quelles bibliothèques faut-il installer ? La première trouve sa réponse dans une arborescence claire, souvent `models.py` pour les données, `services.py` pour les traitements, `cli.py` ou `main.py` pour l'interface avec l'utilisateur. La deuxième, dans un fichier unique dédié au lancement, qui lit les saisies, affiche les résultats et appelle vos fonctions. La troisième, dans `requirements.txt`, versionné avec le reste du code. Cette organisation n'est pas une cérémonie administrative : elle vous fait gagner du temps dès la deuxième semaine, lorsque vous reprenez le code après une interruption et que vous retrouvez immédiatement l'endroit où modifier le calcul de la mention. La suite du chapitre suit ce chemin dans l'ordre : les trois formes d'import, la bibliothèque standard, le garde `__name__`, le découpage concret, les packages, puis pip et la discipline des dépendances. Chaque section contient des exemples exécutables tels quels : lancez-les, modifiez-les, cassez-les volontairement, c'est en manipulant que l'on retient. Voici d'abord une liste de règles pour nommer et organiser vos modules sans regret.

- Un module porte un nom court, en minuscules, sans accent ni espace : `calculs.py`, jamais `Mon Module.py`.
- Le nom d'un module ne doit pas entrer en conflit avec les noms réservés ni avec les fonctions intégrées : évitez `types.py`, `token.py`, `print.py` ou `id.py`.
- Un module a une responsabilité : s'il contient des fonctions sans lien les unes avec les autres, il en masque plusieurs à la fois.
- Les constantes globales du projet vivent dans un module dédié, souvent `config.py` ou `constants.py`.
- Un fichier qui dépasse deux à trois cents lignes mérite d'être examiné : presque toujours, deux modules distincts sortent de là.
- Chaque dossier qui contient du code Python de votre projet gagne à être un package, donc à posséder son `__init__.py`.

Ces conventions ne sont pas des caprices de style : elles rendent vos fichiers prévisibles pour toute personne qui les ouvrira, y compris pour vous dans six mois. Elles servent aussi à éviter deux écueils récurrents chez le débutant, à savoir des imports dispersés au milieu du code et des noms importés qui masquent silencieusement d'autres noms. Un autre écueil est l'oubli d'une conséquence bénigne en apparence : renommer un fichier, déplacer un dossier, et les imports qui pointaient vers l'ancien emplacement se mettent à lever une erreur au démarrage. Appliquez ces règles dès le premier fichier du projet, avant même d'avoir écrit une ligne de logique, car il est toujours plus simple d'installer une bonne habitude que de réécrire trente fichiers pour la remettre en place. Celles qui concernent les imports sont tout aussi courtes et tout aussi contraignantes : six lignes suffisent à résumer la discipline attendue dans tout fichier Python. Les voici.

- Regroupez les imports en trois blocs ordonnés : bibliothèque standard, bibliothèques tierces, puis vos modules locaux.
- Préférez `import numpy as np` pour les alias consacrés par l'usage, mais gardez le nom complet pour vos propres modules.
- Évitez `from module import *`, qui remplit votre espace de noms de manière invisible et peut masquer un nom sans prévenir.
- Les imports se placent en haut du fichier, avant toute définition de fonction ou de constante.
- Un import local s'écrit sans extension ni chemin : `import calc`, jamais `import calc.py`.
- Un import local ne dépend jamais du répertoire depuis lequel vous lancez Python : lancez vos scripts depuis la racine du projet.
$lesson$),
  ('py-c7-p2', 'py-c7', 2, $lesson$Les trois formes d'import$lesson$, $lesson$
Python connaît trois écritures principales pour accéder à un module, et le choix entre elles n'est pas qu'une affaire de goût : il détermine la longueur de vos lignes, la lisibilité de votre code et le risque de collisions de noms. La première forme importe le module sous son nom complet, la seconde importe directement les objets dont vous avez besoin, la troisième ajoute un alias quand le nom d'origine est long ou peu parlant. Commençons par la forme la plus courante et la plus prudente, celle que vous utiliserez par défaut. Avec `import math`, le module entier est chargé et accessible sous un seul nom, celui du module. Vous écrivez ensuite `math.sqrt(2)` ou `math.pi`, et il est toujours évident, en lisant la ligne, que la fonction vient de la bibliothèque mathématique. C'est l'avantage décisif de cette convention : l'origine de chaque appel est explicite, ce qui évite toute confusion lorsque deux modules proposent une fonction du même nom. Regardez la forme complète d'un tel fichier :

```python
import math
import random
rayon = 5
aire = math.pi * rayon * rayon
tirage = random.randint(1, 6)
print(aire)
print(tirage)
```

La deuxième forme, `from math import sqrt`, extrait un objet précis du module et le place directement dans l'espace de noms du fichier courant. Vous écrivez `sqrt(2)` au lieu de `math.sqrt(2)` : c'est plus court, plus fluide, et surtout utile lorsque vous n'avez besoin que d'une seule fonction sur les centaines qu'un module propose. L'inconvénient est symétrique : en lisant `sqrt(2)` seul, on ne devine pas d'où vient la fonction, et si un autre import fournit une autre `sqrt`, l'un écrase silencieusement l'autre. C'est d'ailleurs la raison pour laquelle de nombreux style guides recommandent d'importer le module complet dès lors que vous utilisez trois fonctions ou plus : au-delà de ce seuil, l'écriture devient plus courte, mais la lecture devient plus obscure, et c'est la lecture qui doit primer dans un code que vous relirez dans six mois. La forme courte convient donc aux besoins ponctuels, à une ou deux fonctions tirées d'un module riche. Concrètement :

```python
from math import sqrt, ceil
print(sqrt(16))
print(ceil(3.2))
print(sqrt(16) + ceil(3.2))
```

Cette seconde forme reste excellente pour vos propres modules, car elle exprime l'intention avec précision : `from calc import moyenne` dit clairement que vous avez besoin de la fonction `moyenne`, et rien d'autre. C'est aussi l'écriture employée par la plupart des bibliothèques tierces pour exposer leur API principale, par exemple `from rich import print`. Le point délicat est la portée : la fonction importée devient une variable locale du fichier, indépendante de la suite du module d'origine. Si vous testez votre code avec des outils qui remplacent une fonction par un double, ces outils préfèrent justement la forme `module.fonction`, car elle laisse la porte ouverte au remplacement, tandis que la forme courte fige la référence au moment de l'import. La troisième forme introduit un alias avec le mot-clé `as`, et sert à deux usages bien distincts. Le premier est l'abréviation de confort : `import numpy as np` est devenu la convention universelle pour la bibliothèque NumPy, `import pandas as pd` pour Pandas, et ces alias sont compris par tous les lecteurs. Le second est le renommage d'un objet venu de la bibliothèque standard, lorsque son nom est trop générique ou trop long, ou lorsqu'il risque de heurter un nom existant. L'exemple suivant est exécutable tel quel et montre les deux cas :

```python
import datetime as dt
from math import sqrt as racine_carrée
aujourdhui = dt.date.today()
print(aujourdhui.isoformat())
print(racine_carrée(144))
```

Pour choisir sans hésiter, appliquez cette hiérarchie simple. Par défaut, utilisez `import module`, surtout pour la bibliothèque standard et pour vos propres fichiers, car l'origine reste visible. Utilisez `from module import objet` lorsque vous ne tirez du module que deux ou trois symboles, ou lorsque le module est l'un de vos fichiers locaux et que le nom de la fonction suffit à la repérer. Utilisez l'alias pour reprendre une abréviation consacrée ou pour éviter un nom trop long, mais ne rebaptisez jamais vos propres modules, car un lecteur qui rencontre `import services as s` devra remonter en haut du fichier pour comprendre ce que `s` désigne. Dans le doute, choisissez la forme la plus explicite, celle qui se lit correctement à voix haute. Une seule ligne d'import ne doit jamais vous coûter trois secondes de réflexion à la lecture. Les trois écritures réunies, cette fois avec de vrais modules, donnent ceci :

```python
import math
from math import sqrt
import datetime as dt
```

Il existe une quatrième écriture, `from module import *`, qui importe tout le contenu du module. Évitez-la dans un projet : elle remplit votre espace de noms sans le dire, rend impossible l'origine d'un nom, et peut écraser une fonction du même nom sans le moindre avertissement. Elle ne se justifie que dans un contexte d'exploration rapide en interpréteur, jamais dans un fichier destiné à être relu. Avant même de choisir une forme d'import, il arrive qu'il faille découvrir ce qu'un module contient. Trois outils suffisent, et tous trois sont déjà présents sur votre machine. La fonction `dir(module)` renvoie la liste alphabétique de tous les noms qu'il expose, y compris ceux qui commencent par un underscore, lesquels désignent en général des détails d'implémentation : un simple filtre sur le début du nom suffit à les écarter. La fonction `help(module)` affiche la documentation intégrée, souvent un résumé suivi des signatures des fonctions principales. Enfin, l'attribut `__doc__` d'un objet contient sa docstring, ce qui permet d'afficher une aide ciblée depuis un script. Le bloc suivant explore le module `statistics` sans rien installer :

```python
import statistics
print([nom for nom in dir(statistics) if not nom.startswith("_")][:6])
print(statistics.mean.__doc__)
print(statistics.median([1, 2, 3, 4]))
```

Cette exploration préalable a un avantage pédagogique décisif : elle vous évite de chercher sur le web une fonction que la bibliothèque standard propose déjà, à quelques secondes de distance. L'habitude de taper `dir` et `help` dans un interpréteur avant d'écrire une ligne de code fait gagner un temps considérable, surtout lorsque vous découvrez une bibliothèque tierce dont la documentation semble trop longue à parcourir. Notez au passage que `dir` est elle-même une fonction intégrée, vivant sans module : certains outils appartiennent au langage, d'autres à des modules, et cette frontière se repère avec l'usage. Il reste à comprendre ce qui se passe exactement en coulisses d'un import, car ce détail expliquera la plupart de vos futurs cafouillages. Python maintient un dictionnaire appelé `sys.modules`, qui contient chaque module déjà chargé, indexé par son nom. Au premier `import statistics`, le module est trouvé, exécuté, puis rangé dans ce dictionnaire ; aux imports suivants, Python n'exécute plus rien, il renvoie simplement l'objet déjà présent. D'où une conséquence très utile pour le débogage : si vous corrigez le contenu d'un module en cours de session, un nouvel import ne prend pas en compte votre correction, car la version en mémoire est jugée suffisante. Il faut alors redémarrer l'interpréteur, ou purger manuellement l'entrée correspondante. Le code suivant montre le mécanisme en trois lignes :

```python
import sys
import statistics
print("statistics" in sys.modules)
print(sys.modules["statistics"] is statistics)
```

Les deux affichages renvoient `True`, ce qui prouve que la même instance circule partout. Cette mécanique unique présente deux avantages très concrets. Le premier est la vitesse : après le premier chargement, un import se contente de renvoyer un objet déjà construit, si bien qu'importer un module lourd en début de programme ne se paie qu'une seule fois. Le second est la cohérence : deux modules qui importent `statistics` partagent exactement les mêmes définitions, donc les mêmes constantes et les mêmes fonctions, sans qu'aucun d'eux ait besoin de recopier le moindre code. Si vous modifiez une valeur dans le module, tous les utilisateurs voient la même modification, car il n'existe qu'une seule copie en mémoire. C'est aussi la raison pour laquelle un import n'est pas un moyen de dupliquer du code, mais une manière de le partager. Gardez ce mécanisme à l'esprit : la prochaine fois qu'une correction apportée à un module ne semblera pas avoir d'effet, vous saurez que la faute n'en est pas à votre code, mais à la copie que l'interpréteur a déjà en mémoire.

```table
Forme | Écriture | Appel ensuite | Quand l'utiliser
--- | --- | --- | ---
Import du module | `import math` | `math.sqrt(2)` | Par défaut, surtout la bibliothèque standard et vos fichiers
Import d'un objet | `from math import sqrt` | `sqrt(2)` | Une ou deux fonctions seulement, ou vos modules locaux
Import avec alias | `import datetime as dt` | `dt.date.today()` | Une abréviation consacrée ou un nom trop long
```
$lesson$),
  ('py-c7-p3', 'py-c7', 3, $lesson$La bibliothèque standard : un module pour presque tout$lesson$, $lesson$
Avant de chercher une bibliothèque à installer, regardez ce que Python fournit déjà. La bibliothèque standard, appelée souvent « batteries included », est livrée avec chaque installation de Python, ne nécessite aucune connexion réseau, aucune autorisation et aucune ligne dans votre `requirements.txt`. Elle contient des centaines de modules couvrant l'essentiel du travail quotidien : `math` pour le calcul numérique, `random` pour le hasard contrôlable, `datetime` pour les dates et durées, `json` et `csv` pour les formats de données, `re` pour les expressions régulières, `pathlib` pour les chemins de fichiers, `statistics` pour les statistiques descriptives, `collections` pour les conteneurs spécialisés, `sys` pour le lien avec l'interpréteur, `unittest` pour les tests. Connaître cette liste, même imparfaitement, vous fait gagner des heures et vous évite d'ajouter une dépendance pour une fonction qui existe déjà sous vos doigts. Le module `statistics` en est la démonstration parlante pour votre analyseur de notes. Tant que vous n'avez que la moyenne, un simple `somme / len` suffit, mais dès que vous voulez la médiane, le mode ou l'écart-type, la bibliothèque standard vous évite d'installer NumPy. L'exemple suivant calcule trois indicateurs sur une liste de notes et s'exécute sans rien installer :

```python
import statistics
notes = [12, 15, 9, 17, 14, 14, 11]
print(statistics.mean(notes))
print(statistics.median(notes))
print(statistics.stdev(notes))
```

`pathlib` illustre un autre intérêt de la bibliothèque standard : moderniser des tâches anciennes. Dans le chapitre 5, vous avez manipulé des chemins sous forme de chaînes de caractères, par exemple `os.path.join(dossier, "notes.txt")`. Avec `pathlib`, le chemin devient un objet doté de méthodes, ce qui se lit comme une phrase : `dossier / "notes.txt"`. L'objet sait se décomposer en nom, en dossier parent et en extension, il sait vérifier si le fichier existe, s'il est absolu ou relatif, et il produit le même résultat sous Windows, macOS et Linux, sans que vous ayez à penser aux barres obliques ou aux antislashs. C'est le type de confort qui transforme un code fragile en code sûr : l'objet refuse de vous laisser concaténer deux chaînes oubliées. Le bloc ci-dessous lit le nom d'un fichier, vérifie si le fichier existe sur le disque et affiche son extension, sans une seule barre obliques à écrire :

```python
from pathlib import Path
fichier = Path("notes.txt")
print(fichier.name)
print(fichier.suffix)
print(fichier.exists())
```

Le module `sys` mérite une attention particulière, car il vous donne accès à ce que fait l'interpréteur lui-même : `sys.argv` contient les arguments passés en ligne de commande, `sys.exit` termine le programme avec un code de retour, `sys.path` indique la liste des dossiers où Python recherche les modules importés, et `sys.version` affiche la version exacte en cours. Comprendre `sys.path` vous sera directement utile : c'est la raison pour laquelle un script lancé depuis un autre dossier ne trouve pas vos modules. Un dernier réflexe à acquérir : avant `pip install`, tapez le nom du module qui vous manque dans la documentation officielle de Python ; si vous le trouvez dans la bibliothèque standard, vous venez d'économiser une dépendance et son entretien futur. Deux modules supplémentaires méritent votre attention pour l'analyseur de notes, car ils relient directement ce chapitre au précédent. Le module `json` écrit et relit des structures Python dans un fichier texte, ce qui en fait l'outil naturel pour conserver un résumé calculé, un historique de notes ou une préférence d'affichage. Les fonctions `json.dump` et `json.load` travaillent sur un objet fichier, exactement comme les fonctions `open` du chapitre 5, et le paramètre `ensure_ascii=False` garantit que les accents sont conservés tels quels. Le bloc suivant écrit un résumé puis le relit pour vérification :

```python
import json
resume = {"moyenne": 13.4, "mention": "Assez bien"}
with open("resume.json", "w", encoding="utf-8") as fichier:
    json.dump(resume, fichier, ensure_ascii=False, indent=2)
with open("resume.json", "r", encoding="utf-8") as fichier:
    print(json.load(fichier))
```

Le second apporte le hasard, mais un hasard maîtrisé. La bibliothèque `random` est précieuse pour simuler des notes, tirer un élève au sort ou générer des données de démonstration ; en revanche, un hasard qui change à chaque exécution rend un test impossible à reproduire. C'est là qu'intervient `random.seed`, qui fixe la suite aléatoire et rend l'exécution parfaitement reproductible. À la même graine correspond toujours la même séquence, ce qui vous permet de relancer votre script en cas de doute et de retrouver exactement les mêmes valeurs, y compris pour comparer deux exécutions ligne à ligne. Sans cette fixation, un écart de moyenne entre deux lancements resterait inexplicable, et vous perdriez du temps à chercher une faute qui n'existe pas. Le module `collections.Counter` complète le tableau en comptant les occurrences d'une note, ce qui donne immédiatement la ou les notes les plus fréquentes, sans tri ni boucle supplémentaire à écrire vous-même :

```python
import random
from collections import Counter
random.seed(7)
notes = [random.randint(8, 20) for _ in range(10)]
print(notes)
print(Counter(notes).most_common(3))
```

Ces deux exemples illustrent la même leçon : la bibliothèque standard n'est pas un résidu de l'histoire de Python, c'est un outillage mûr, stable et documenté, qui couvre le calcul, les dates, les fichiers, les formats d'échange, le hasard, les conteneurs et le lien avec l'interpréteur. Une bibliothèque installée, elle, change de version, se déprécie parfois, impose sa propre façon d'écrire et demande à être mise à jour avec le reste de l'environnement. Celle qui est fournie avec l'installation, en revanche, est exactement la même sur la machine de votre collègue, sur le poste de l'examinateur et sur votre ordinateur trois ans plus tard. C'est pourquoi la bonne question n'est jamais « quelle bibliothèque installer pour résoudre ceci ? », mais « quel module Python résout déjà ceci ? ». Plus vous l'utiliserez, moins vous installerez, et moins vous installerez, moins vous entretenirez, et plus votre projet survivra aux années.
$lesson$),
  ('py-c7-p4', 'py-c7', 4, $lesson$if __name__ == "__main__"$lesson$, $lesson$
Voici une ligne que vous croiserez dans presque tous les projets Python sérieux, et qui mérite d'être comprise en profondeur plutôt que copiée machinalement : `if __name__ == "__main__":`. Chaque module exécuté par Python dispose d'une variable spéciale nommée `__name__`, dont la valeur dépend de la manière dont le fichier a été démarré. Si vous lancez le fichier directement avec la commande `python calc.py`, alors `__name__` vaut la chaîne `"__main__"`. Si un autre fichier écrit `import calc`, alors `__name__` vaut `"calc"`, c'est-à-dire le nom du module tel qu'il est importé. Le bloc conditionnel n'est donc rien d'autre qu'un test sur la façon dont le programme a été appelé. Le mécanisme devient limpide si vous l'affichez. Créez un fichier `demo.py` contenant la ligne `print(__name__)` : lancez-le, et la sortie sera `__main__`. Créez ensuite un second fichier qui importe `demo`, et la sortie sera `demo`. C'est tout le principe, et il est robuste jusqu'aux packages imbriqués, où la variable prend le nom qualifié, par exemple `notes.cli`. Le bloc suivant illustre les deux comportements dans un seul fichier, que vous pouvez tester en le lançant directement puis en l'important depuis un autre script :

```python
print("Chargement du module demo, __name__ =", __name__)
if __name__ == "__main__":
    print("Le fichier demo.py est exécuté directement")
```

L'intérêt pratique est considérable : ce garde permet de ranger dans un même fichier deux choses qui ne doivent jamais se déclencher en même temps, à savoir la bibliothèque de fonctions réutilisables et le petit programme de démonstration ou de vérification. Sans ce garde, importer `calc.py` déclencherait immédiatement la saisie au clavier, l'affichage du rapport ou la lecture d'un fichier, en plein milieu du chargement du fichier voisin. C'est la cause numéro un des bugs incompréhensibles au début d'un projet structuré, celui où lancer `main.py` provoque l'exécution de trois autres scripts dans un ordre apparemment aléatoire. Un module bien conçu est silencieux au chargement : il définit des noms et se tait. La convention complète consiste à écrire une fonction `main()` qui contient tout le comportement du script, puis à l'appeler uniquement sous le garde. Cette structure a trois avantages : le fichier reste lisible en le parcourant, la fonction `main()` peut être rappelée depuis un test ou depuis l'interpréteur, et les variables temporaires de lancement ne viennent pas polluer l'espace de noms du module. Voici le squelette que vous réutiliserez tout au long de ce chapitre :

```python
def traiter(notes):
    return sum(notes) / len(notes)
def main():
    valeurs = [12, 15, 9, 17]
    print(traiter(valeurs))
if __name__ == "__main__":
    main()
```

Une précaution demeure : le garde ne protège que le code placé à l'intérieur du bloc. Tout ce qui se trouve au niveau supérieur d'un module, c'est-à-dire toutes les lignes qui ne sont ni dans une fonction ni dans ce bloc, s'exécute dès l'import. Définir une constante comme `SEUIL = 10` est parfaitement sûr, car l'opération est instantanée et sans effet, mais appeler `input()`, ouvrir un fichier ou lancer une boucle de calcul au niveau supérieur revient à exécuter ce travail au chargement. Gardez donc en tête cette distinction : les définitions et les constantes en haut de fichier, les actions dans des fonctions, et l'exécution réelle sous le garde `__name__`. Un dernier point de vocabulaire : le nom `"__main__"` n'a rien de magique pour l'interpréteur, c'est une simple convention universellement adoptée, exactement comme la fonction `main()` héritée du langage C. Écrire `"main"` ou `"principal"` au lieu de `"__main__"` ne produirait aucune erreur de syntaxe, mais le bloc ne s'exécuterait jamais, car Python affecte `"__main__"` et rien d'autre. Même si la mécanique reste simple, c'est précisément ce détail qui rend possible le découpage de votre analyseur en deux fichiers : l'un expose des fonctions, l'autre pilote la saisie et l'affichage.

Le garde ne s'active pas seulement quand vous tapez `python calc.py`. La commande `python -m calc` produit exactement le même effet : le module indiqué devient le script principal, son `__name__` vaut `"__main__"`, et son bloc de lancement s'exécute. L'option `-m` présente toutefois un avantage supplémentaire, puisqu'elle ajoute le dossier courant au chemin de recherche et permet de lancer un module appartenant à un package, comme `python -m notes.cli`. La règle reste donc unique et mémorisable : quel que soit le moyen de lancement, le bloc gouverné par le test sur `__name__` ne s'exécute que pour le fichier désigné comme principal, jamais pour ceux qu'il importe.
Ce schéma permet d'écrire des fichiers réellement polyvalents, à la fois bibliothèque pour les autres et outil en ligne de commande pour l'utilisateur. L'exemple suivant, à enregistrer sous le nom `stats.py`, se comporte différemment selon la manière dont on le lance : importé, il se contente d'exposer sa fonction ; lancé directement, il convertit les arguments passés après le nom du script et affiche la moyenne calculée.

```python
import sys
def moyenne(notes):
    if not notes:
        return 0.0
    return sum(notes) / len(notes)
if __name__ == "__main__":
    valeurs = [float(arg) for arg in sys.argv[1:]]
    print(moyenne(valeurs))
```

Exécutez `python stats.py 10 12 14` et le programme affiche `12.0` ; exécutez `import stats` dans un autre fichier et le même module reste muet, prêt à servir via `stats.moyenne`. Une seule source, deux comportements maîtrisés. Pour garder cette distinction nette, appliquez une recette constante : les imports et les définitions en haut de fichier, le code exécutable entièrement rangé dans une fonction `main()`, et un unique bloc `if __name__ == "__main__":` en dernière ligne qui appelle cette fonction. Un fichier qui respecte ce plan peut être importé par n'importe quel autre, y compris par un futur outil de test, sans jamais déclencher de saisie, d'affichage ou d'écriture sur le disque. C'est la condition d'un code réutilisable, et vous la retrouverez dans tous les projets Python que vous ouvrirez par la suite, du script le plus modeste au plus gros projet que vous mènerez un jour. Cette habitude deviendra vite un réflexe.
$lesson$),
  ('py-c7-p5', 'py-c7', 5, $lesson$Découper un projet en plusieurs fichiers$lesson$, $lesson$
Le découpage d'un projet ne se décrète pas à partir d'une théorie abstraite, il part d'un symptôme très concret : le moment où vous ne trouvez plus rien. Reprenons votre analyseur de notes et imaginons qu'il ait grossi jusqu'à mille lignes : lecture du fichier, nettoyage des données, calcul des moyennes et des mentions, formatage du tableau, saisie du nom d'un élève, gestion des erreurs de saisie, écriture du rapport en sortie. Tout se tient, tout se répond, et pourtant tout se télescope, car ces responsabilités n'ont rien à faire dans le même fichier. La première question à vous poser n'est donc pas « comment couper ? » mais « quelles sont les frontières naturelles ? ». Répondez en nommant les grands blocs du programme : des données à décrire, des calculs à effectuer, une interface à afficher. Ces trois réponses donnent déjà trois fichiers, et le reste du chapitre ne fera qu'affiner ces frontières plutôt que de les déplacer.

Un critère simple guidera presque toujours vos décisions : séparez ce qui calcule de ce qui communique avec l'extérieur. Les fonctions purement calculatoires, comme moyenne, médiane ou mention, prennent des valeurs en entrée et renvoient un résultat sans rien lire, rien écrire, rien afficher. Elles sont donc testables en une seconde, dans un interpréteur ou avec un script de vérification, et elles ne dépendent d'aucun fichier sur le disque. À l'inverse, tout ce qui touche au monde réel, c'est-à-dire la lecture d'un fichier avec la bibliothèque du chapitre 5, la saisie au clavier avec `input()`, l'affichage avec `print()` ou `rich`, appartient à un autre fichier. Le résultat s'exprime souvent avec trois noms qui reviennent dans la plupart des projets : `models.py` pour les structures de données, `services.py` pour la logique métier, `cli.py` pour la ligne de commande. Le fichier `calc.py`, qui héberge les seuls calculs de votre analyseur, commence ainsi :

```python
def moyenne(notes):
    """Renvoie la moyenne arithmétique des notes.
    >>> moyenne([10, 12, 14])
    12.0
    >>> moyenne([])
    0.0
    """
    if not notes:
        return 0.0
    return sum(notes) / len(notes)
def mention(notes):
    moy = moyenne(notes)
    if moy >= 16:
        return "Très bien"
    if moy >= 14:
        return "Bien"
    if moy >= 12:
        return "Assez bien"
    if moy >= 10:
        return "Passable"
    return "Insuffisant"
```

Un des bénéfices les plus concrets de ce découpage est la possibilité de vérifier un morceau de programme sans déclencher tout le reste. Tant que votre analyseur était un seul fichier, la moindre vérification passait par l'exécution complète : saisie au clavier, lecture du fichier, affichage du rapport. Dès que les calculs vivent dans `calc.py`, vous pouvez les éprouver directement, avec des valeurs choisies, sans toucher au clavier ni au disque. La méthode la plus rapide porte un nom informel, le quick check : un petit script posé dans le même dossier, qui importe le module et appelle ses fonctions avec des valeurs connues. Il reste écrit en Python, ne demande aucune installation, et documente en même temps l'usage attendu du module : une personne qui découvre le projet peut lire ce fichier pour comprendre comment appeler vos fonctions, avec quels types d'arguments et quel format de retour attendu. Voici celui de votre analyseur :

```python
import calc
print(calc.moyenne([12, 15, 9]))
print(calc.mention([16, 15, 17]))
print(calc.moyenne([]))
```

Quand le contrôle échoue, l'erreur Python vous indique exactement la ligne fautive, ce qui suffit amplement tant que votre module reste petit et autonome. Un autre réflexe consiste à faire produire des preuves par le module lui-même : Python embarque le module `doctest`, qui extrait les exemples contenus dans les docstrings et les rejoue comme un test, si le résultat affiché diffère de celui attendu, le contrôle échoue. L'avantage est double, puisque la documentation et la vérification sont rédigées au même endroit, dans la même phrase, et que la docstring ne peut plus mentir sur le comportement réel de la fonction. La commande `python -m doctest calc.py` exécute alors tous les exemples du fichier, et la variante `python -m doctest -v calc.py` liste chaque contrôle réussi. C'est une introduction parfaite aux tests automatisés que le chapitre suivant mettra en place pour de bon, avec un outil dédié et une convention de nommage de fichiers.

Le second point à comprendre est le mécanisme même d'un import local. Lorsque `main.py` écrit `import calc`, Python ne recherche pas le fichier n'importe où sur le disque : il parcourt une liste de dossiers appelée `sys.path`, et cette liste contient notamment le dossier du script que vous lancez. Si les deux fichiers sont dans le même répertoire, l'import fonctionne immédiatement, sans configuration, sans variable d'environnement, sans installation. C'est la raison pour laquelle un petit projet se lance simplement avec `python main.py`, depuis son propre dossier. Si vous le lancez depuis un autre répertoire en donnant un chemin complet, le dossier de recherche ne sera plus le bon et l'import échouera avec une erreur du type `ModuleNotFoundError` ; ce cas reviendra dans la section des erreurs fréquentes, avec sa correction exacte. Placez à présent `main.py` dans ce même dossier : il appelle les fonctions de `calc` sans rien recalculer lui-même :

```python
import calc
notes = [12, 15, 9, 17, 14]
print("Moyenne :", calc.moyenne(notes))
print("Mention :", calc.mention(notes))
```

Un troisième principe vient compléter la réflexion : gardez un point d'entrée unique. Dans un projet bien découpé, un seul fichier a pour rôle de démarrer le programme, de lire les arguments, de demander les saisies et d'afficher les résultats ; tous les autres fichiers se contentent d'exposer des fonctions et des constantes, et ne font jamais rien d'autre au moment où on les importe. Ce fichier d'entrée est celui qui porte le fameux garde `if __name__ == "__main__":`, tandis que les modules importés restent muets. Testez votre découpage avec une question très simple : « mon collègue veut-il modifier le calcul de la mention, dans quel fichier va-t-il ouvrir ? ». Si la réponse n'est pas évidente en trois secondes, un fichier cumule encore trop de responsabilités et mérite d'être fendu en deux. Une racine de projet bien découpée ressemble alors à ceci, avec les cinq fichiers qui constituent le squelette de votre futur projet :

```python
mon_projet/
    models.py
    services.py
    cli.py
    requirements.txt
    notes.txt
```

Le nommage mérite une attention particulière, car il conditionne toute la lecture future du projet. Le piège classique s'appelle `utils.py` : un fichier sans métier précis où l'on dépose au fur et à mesure tout ce qui ne trouve pas sa place, une fonction de formatage, une constante de seuil, une conversion de date, une vérification de saisie. Au bout de quelques mois, ce fichier rassemble trois cents lignes hétérogènes et redevient exactement le monolithe que vous cherchiez à éviter, avec en plus un nom qui ne dit rien. Préférez nommer par domaine plutôt que par mécanisme : `calcul_notes.py`, `formatage_bulletin.py`, `saisie_clavier.py` disent au lecteur ce qu'il trouvera, tandis que `utils.py`, `helpers.py` ou `misc.py` lui demandent d'ouvrir le fichier pour le savoir. Un second principe découle de cette exigence : les noms de modules doivent durer. Renommer un module n'est pas une opération anodine, car chaque fichier qui l'importe doit être modifié en conséquence, et un import oublié casse le programme au démarrage avec un message qui ne mentionne pas toujours le fichier fautif. Réfléchissez donc au nom avant de créer le fichier, en le prononçant à voix haute dans une phrase d'usage : « le module de calcul des notes renvoie la moyenne ». Si la phrase sonne juste, le nom convient. Si vous devez ajouter « enfin, c'est le fichier où il y a aussi... », le découpage n'est pas terminé.

Enfin, évitez deux écueils classiques du découpage. Le premier est l'import circulaire : `a` importe `b`, qui importe `a`, et Python vous délivre alors une erreur redoutée, `ImportError: cannot import name ...`. Il apparaît presque toujours parce que deux modules ont été coupés au mauvais endroit, chacun contenant un bout de l'autre ; la correction consiste à extraire la partie commune dans un troisième module, souvent `models.py` ou un module de domaine clairement nommé. Le second écueil est la fragmentation : multiplier les fichiers de quinze lignes au nom d'une propreté théorique rend le projet plus difficile à parcourir qu'un seul gros fichier. Visez des modules de quelques dizaines à quelques centaines de lignes, chacun capable de se lire de bout en bout sans retour en arrière. Retenez surtout le principe qui court sous tout ce chapitre : un module qui fait une seule chose se teste en une ligne, et un module testable se corrige sans risque.
$lesson$),
  ('py-c7-p6', 'py-c7', 6, $lesson$Packages et __init__.py$lesson$, $lesson$
Un dossier de modules devient un package dès lors qu'il contient un fichier nommé `__init__.py`, et ce nom, underscores compris, se tape exactement. Ce fichier peut être vide, sa présence suffit : elle indique à Python que le répertoire n'est pas un dépôt de fichiers quelconque mais un ensemble organisé de modules importables. Dans un projet nommé `notes`, le dossier `notes/` contiendra `models.py`, `services.py`, `cli.py` et, pour clore l'ensemble, `notes/__init__.py`. On peut alors écrire `import notes.services` ou `from notes.services import moyenne`, et Python parcourt la hiérarchie des dossiers comme il parcourt celle des modules. L'import se lit alors comme une adresse postale : le package d'abord, le module ensuite, l'objet enfin. Retenez cette image : elle vous évitera d'hésiter, dans deux sections, entre écrire `notes.services.moyenne` ou `from notes.services import moyenne`, car vous saurez toujours où vous vous situez dans l'adresse, quelle que soit la taille de l'arborescence et le nombre de sous-packages qu'elle contient.

```python
notes/
    __init__.py
    models.py
    services.py
    cli.py
```

Au chargement, `import notes.services` produit deux opérations successives : Python exécute d'abord `notes/__init__.py`, puis `notes/services.py`. C'est une occasion en or de comprendre ce que contient réellement un `__init__.py`. Souvent, on y laisse le fichier vide, ce qui en fait une simple étiquette. Parfois, on l'utilise pour exposer une API réduite, c'est-à-dire les quelques symboles que les autres fichiers du projet doivent utiliser au quotidien. Si `services.py` propose dix fonctions mais que le projet n'en appelle qu'une seule au quotidien, votre `__init__.py` peut la réexporter, de sorte que les clients écrivent `from notes import moyenne` au lieu de connaître l'arborescence interne. L'arborescence reste ainsi libre de changer du tout au tout sans casser les fichiers qui utilisent votre package : seuls les responsables du package voient la répartition interne des modules. C'est exactement le mécanisme qui rend les bibliothèques tierces agréables à utiliser, elles qui exposent deux ou trois noms au sommet et cachent le reste de leur organisation. Voici la forme minimale de ce fichier :

```python
from .services import moyenne
__all__ = ["moyenne"]
```

Le point délicat de cet extrait est le point placé devant `services` : il s'agit d'un import relatif, qui signifie « depuis le package courant ». Python 3 encourage cette écriture à l'intérieur d'un package, car elle rend l'import indépendant du nom absolu du projet : si vous renommez le dossier `notes` en `analyseur`, les imports internes continuent de fonctionner. La contrepartie est qu'un import relatif n'a de sens que dans un package, jamais dans un fichier isolé lancé directement. Par mesure de sécurité, beaucoup d'équipes préfèrent malgré tout les imports absolus, `from notes.services import moyenne`, qui se comprennent sans contexte et fonctionnent partout, à condition que le dossier parent soit dans le chemin de recherche. Les deux écritures cohabitent d'ailleurs souvent : imports absolus entre packages, imports relatifs à l'intérieur d'un même package. Le fichier `notes/models.py` décrit alors la donnée élémentaire du domaine, et `notes/services.py` exploite ces objets en important la classe depuis le module voisin :

```python
class Note:
    def __init__(self, matiere, valeur):
        self.matiere = matiere
        self.valeur = valeur
```

```python
from .models import Note
def moyenne(notes):
    """Moyenne des valeurs d'une liste d'objets Note."""
    if not notes:
        return 0
    return sum(note.valeur for note in notes) / len(notes)
```

Lancer un module d'un package se fait de préférence avec l'option `-m` de Python, que vous exécutez depuis le dossier parent : `python -m notes.cli`. Cette forme indique à l'interpréteur de traiter `notes.cli` comme un module d'un package, et elle laisse les imports relatifs intacts. La commande alternative `python notes/cli.py`, elle, lance le fichier comme un script autonome : Python ne lui connaît alors aucun parent, et le premier import relatif provoque une erreur `ImportError: attempted relative import with no known parent package`. Ce n'est pas un caprice de l'interpréteur, c'est la conséquence directe du fait qu'un script lancé par son chemin n'a pas d'identité de package.
Il existe une variante élégante pour rendre un package entièrement exécutable. Si vous ajoutez dans le dossier `notes/` un fichier nommé `__main__.py`, alors la commande `python -m notes` devient valide : Python traite ce fichier comme le script d'entrée du package. Dans ce fichier, on importe généralement la fonction principale du module d'interface et on l'appelle, ce qui évite de dupliquer la moindre logique :

```python
from .cli import main
main()
```

Le résultat est une commande courte, mémorisable et indépendante de l'arborescence : l'utilisateur tape `python -m notes` depuis la racine du projet, et le package déroule lui-même son chemin d'exécution. C'est la même mécanique que la commande `python -m pip` que vous avez déjà utilisée, ou de `python -m doctest` employée au début de ce chapitre : ces outils sont eux aussi des packages, dotés d'un point d'entrée dédié. Notez que ce `__main__.py` n'est jamais importé par un autre fichier, il n'existe que pour le lancement, et il peut rester très court puisque tout le travail est délégué aux modules du package. Reste une question pratique : comment Python choisit-il entre votre package local et les packages installés ? Il parcourt dans l'ordre les dossiers listés dans `sys.path`, qui commence par le dossier du script lancé, puis les emplacements de l'installation Python où se trouvent la bibliothèque standard et les paquets installés par pip. Vos modules de projet sont donc cherchés en premier, ce qui est exactement ce que vous voulez : votre `notes/` locale est prioritaire sur un éventuel paquet du même nom téléchargé depuis Internet. Cette priorité peut toutefois jouer des tours, si un fichier local porte le nom d'une bibliothèque standard, car il prend alors la place de cette dernière.

Pour conclure, retenez que le package est l'unité de nommage et de partage de Python. Un dossier avec ses modules et son `__init__.py` peut être copié tel quel dans un autre projet, déposé sur un dépôt de code, ou publié sur Python Package Index pour être installé avec pip par d'autres développeurs. C'est exactement ce qui sépare un empilement de fichiers d'un projet structuré : chacun des éléments a un nom, une place, un rôle connu de l'interpréteur. D'ailleurs, la plupart des bibliothèques que vous avez installées avec pip sont des packages de cette forme, enrichis d'un fichier de métadonnées et d'une documentation, mais le principe de base est exactement celui que vous venez d'étudier. Vous savez donc reconnaître un package au premier regard, le construire, lancer son contenu et le partager : reste à voir comment ajouter au projet les bibliothèques qui ne sont pas de vous, et comment les garder figées.
$lesson$),
  ('py-c7-p7', 'py-c7', 7, $lesson$pip et requirements.txt$lesson$, $lesson$
pip accompagne toute installation récente de Python et son rôle est simple : aller chercher une bibliothèque publiée sur Python Package Index, la télécharger, la construire si nécessaire, puis la déposer dans le dossier partagé de votre interpréteur, généralement nommé site-packages. Concrètement, la commande `pip install rich` suffit à rendre disponible la bibliothèque d'affichage élégante que vous utiliserez dans l'exercice de ce chapitre. Vérifiez l'installation avec `pip list`, qui énumère tout ce qui est installé, ou avec `pip show rich`, qui affiche la version exacte, l'emplacement et la description. Sur certaines machines, il faut écrire `python -m pip install rich` pour être certain que l'installation vise bien l'interpréteur que vous utilisez : si deux versions de Python cohabitent sur la même machine, pip et python peuvent ne pas désigner la même installation. Le point décisif, c'est que pip installe par défaut une version flottante, c'est-à-dire la plus récente qu'il trouve compatible avec votre Python. Si vous exécutez `pip install rich` en janvier et votre collègue en juillet, il est fort possible que vous n'ayez pas le même code dans vos dossiers site-packages, donc pas tout à fait le même comportement. Or un logiciel qui fonctionne chez vous et pas chez votre collègue est un logiciel qui ne fonctionne nulle part ailleurs. Chaque dépendance doit donc être déclarée avec sa version exacte dans un fichier texte nommé `requirements.txt`, qui accompagne le code source du projet. Voici le contenu typique d'un tel fichier pour l'analyseur de notes :

```python
rich==13.7.0
```

Ce fichier se génère automatiquement avec la commande `pip freeze > requirements.txt`, qui liste toutes les bibliothèques installées dans l'environnement courant avec leur version exacte, en suivant le format nom du paquet, double égal, version. Vous pouvez aussi figer une seule dépendance, avec `pip freeze rich`, lorsque le reste de l'environnement ne vous intéresse pas. Le résultat se place à la racine du projet, à côté de vos fichiers Python, et se versionne avec eux, car il décrit une part essentielle de l'application. À l'inverse, sur une machine neuve, une seule commande restaure l'environnement complet : `pip install -r requirements.txt` lit le fichier ligne à ligne et installe chaque dépendance à la version indiquée. Notez que `pip freeze` liste aussi vos outils de développement, tests et formatage, ce qui est souvent souhaitable pour garantir la reproductibilité, mais vous pouvez éditer le fichier à la main pour ne conserver que ce dont le projet a réellement besoin au démarrage.

Une pratique professionnelle vient encadrer tout cela : l'environnement virtuel, créé avec le module `venv` de la bibliothèque standard. Il s'agit d'un dossier autonome qui contient sa propre copie de l'interpréteur et ses propres bibliothèques, isolées de celles de votre machine et des autres projets. On le crée une fois pour toutes dans le dossier du projet, on l'active au début de chaque session de travail, puis on y installe les dépendances déclarées. Le dossier ainsi créé se nomme en général `.venv` ou `env`, et il doit être ajouté à votre fichier d'ignore de versionnement, car personne d'autre n'a besoin de vos bibliothèques installées. Sans cet isolement, deux projets qui réclament des versions incompatibles de la même bibliothèque se marchent dessus, et vous passez plus de temps à résoudre des conflits d'installation qu'à coder. La boucle complète tient en trois commandes, à exécuter depuis la racine du projet, et vous les répéterez pour chaque nouveau projet, presque sans y penser :

```python
python -m venv .venv
pip install -r requirements.txt
pip freeze > requirements.txt
```

Au-delà de la technique, une discipline de fond s'impose : une dépendance est un engagement de maintenance. Chaque bibliothèque que vous installez entre dans votre chaîne de responsabilité. Elle peut être abandonnée par son auteur, contenir une faille de sécurité, changer d'API dans une version majeure, ou traîner derrière elle dix autres paquets qu'elle appelle en cascade. Avant `pip install`, posez-vous donc une série de questions : existe-t-il un équivalent dans la bibliothèque standard, comme `statistics` au lieu de NumPy pour des moyennes simples ? Le projet est-il maintenu, documenté, utilisé par une communauté importante ? Sa licence est-elle compatible avec votre usage ? A-t-il besoin d'un compilateur ou de bibliothèques système pour s'installer ? Un projet qui s'en sort seul, sans dépendance, reste toujours le plus facile à maintenir, à déployer et à comprendre dans deux ans, et c'est la raison pour laquelle la bibliothèque standard mérite d'être inspectée avant tout appel à pip.

La mise à jour d'une dépendance obéit à la même exigence de méthode. Une commande comme `pip list --outdated` énumère les paquets installés dont une version plus récente existe, et `pip install --upgrade paquet` procède à la mise à jour d'un seul d'entre eux. Résistez à la tentation de tout mettre à jour d'un coup : une version majeure peut renommer une fonction, changer un comportement par défaut ou abandonner la compatibilité avec votre version de Python. La conduite raisonnable consiste à isoler la modification, mettre à jour une bibliothèque, relancer vos vérifications, puis figer à nouveau l'environnement avec `pip freeze > requirements.txt`. Si quelque chose casse, vous savez exactement quel paquet en est la cause, et le retour arrière reste simple. Une précision importante sur le contenu de ce fichier : `pip freeze` liste toutes les bibliothèques effectivement présentes, y compris celles que vos dépendances ont installées automatiquement en chemin. Ces bibliothèques indirectes font partie de l'environnement, et les omettre priverait la reconstruction d'un élément nécessaire. C'est pourquoi un fichier figé est si fidèle, et c'est aussi pourquoi il faut se méfier des listes recopiées depuis un tutoriel : elles décrivent l'environnement d'un autre, pas le vôtre. Enfin, gardez à l'esprit que `requirements.txt` ne s'applique pas tout seul, il ne sert qu'à documenter et à alimenter une commande d'installation explicite. Et si une dépendance devient inutile, désinstallez-la avec `pip uninstall paquet` avant de régénérer le fichier, sinon elle continuera de paraître indispensable aux yeux de vos collègues.

```table
Commande | Effet | Exemple d'usage
--- | --- | ---
`pip install rich` | Ajoute une bibliothèque depuis Python Package Index | Installer `rich` pour l'affichage
`pip list` | Énumère tout ce qui est installé | Vérifier que `rich` est bien installé
`pip show rich` | Affiche la version exacte, l'emplacement et la description | Consulter la version de `rich`
`pip freeze > requirements.txt` | Liste les bibliothèques installées avec leur version exacte | Figer l'environnement du projet
`pip install -r requirements.txt` | Installe chaque dépendance à la version indiquée | Restaurer l'environnement sur une machine neuve
`pip uninstall paquet` | Désinstalle une dépendance devenue inutile | Avant de régénérer le fichier
```

La méthode complète tient en six gestes qui forment la boucle normale d'un projet Python, du début à la reproductibilité. Ce n'est pas de la bureaucratie : chacun des gestes répond à une défaillance précise que vous rencontrerez tôt ou tard, à savoir l'installation qui ne se reproduit pas, la version qui change en cours de route, l'oubli de documenter l'installation pour un nouveau venu, et l'environnement mondial où s'entassent les bibliothèques de tous vos projets à la fois. Exécutés dans l'ordre, ces gestes transforment une installation fragile en une opération reproductible à l'identique, chez vous comme chez n'importe qui. Un nouveau venu arrive alors sur votre projet, tape deux commandes, et dispose exactement du même environnement que vous, sans appel téléphonique ni copie de dossier à la main. Répétez-les à chaque nouvelle idée de bibliothèque, et vous ne vous tromperez plus jamais d'environnement, même en changeant de machine :

1. Créez l'environnement virtuel du projet avec `python -m venv .venv`.
2. Activez-le, puis vérifiez avec `pip list` que vous partez d'une base connue.
3. Installez la dépendance choisie avec `pip install nom_de_la_bibliotheque`.
4. Testez la bibliothèque dans un interpréteur avant de l'intégrer au code.
5. Figez les versions avec `pip freeze > requirements.txt` et versionnez ce fichier.
6. Documentez dans le README la commande exacte pour installer le projet ailleurs.
$lesson$),
  ('py-c7-p8', 'py-c7', 8, $lesson$Exemple guidé : l'analyseur de notes en deux fichiers$lesson$, $lesson$
Vous avez toutes les pièces : les formes d'import, le garde `__name__`, le découpage en modules, les packages et pip. Place au montage. L'exemple suivant transforme votre analyseur de notes en un mini-projet réellement structuré, composé de deux fichiers Python, d'un fichier de dépendances et d'un dossier de données. Les deux fichiers doivent se trouver dans le même dossier, à côté de `notes.txt` que vous aviez créé au chapitre 5. La responsabilité de chaque fichier est délibérément tranchée : `calc.py` ne fait que du calcul, sans saisie ni affichage, tandis que `main.py` pilote la saisie, appelle les calculs et met en forme le résultat avec la bibliothèque `rich`. Ce partage n'est pas décoratif : il vous permettra de tester les calculs sans toucher au clavier, et de changer l'affichage sans jamais rouvrir la moindre formule. Rien de nouveau n'apparaît dans les deux fichiers qui suit : tout y puise dans ce que les sections précédentes ont posé.

```python
import statistics
def moyenne(notes):
    if not notes:
        return 0.0
    return sum(notes) / len(notes)
def mention(notes):
    moy = moyenne(notes)
    if moy >= 16:
        return "Très bien"
    if moy >= 14:
        return "Bien"
    if moy >= 12:
        return "Assez bien"
    if moy >= 10:
        return "Passable"
    return "Insuffisant"
def note_sur20(note, bareme):
    if bareme <= 0:
        raise ValueError("le barème doit être strictement positif")
    return round(note * 20 / bareme, 2)
def resume(notes):
    if not notes:
        return {"moyenne": 0.0, "mediane": 0.0, "mention": "Insuffisant"}
    return {"moyenne": round(moyenne(notes), 2),
            "mediane": statistics.median(notes),
            "mention": mention(notes)}
if __name__ == "__main__":
    essai = [12, 15, 9, 17, 14]
    print(resume(essai))
```

Le fichier ci-dessus, à enregistrer sous le nom `calc.py`, est un module au sens exact du terme. Il importe un module de la bibliothèque standard, définit quatre fonctions et se termine par un garde qui déclenche une vérification minimale uniquement si vous tapez `python calc.py`. Si un autre fichier écrit `import calc`, aucune impression n'a lieu : les quatre fonctions sont simplement mises à disposition. Notez l'absence totale d'appel à `input()`, `print()` ou ouverture de fichier hors du garde : ce module ne dépend que des listes de nombres qu'on lui transmet, ce qui le rend immédiatement réutilisable, y compris depuis le projet du chapitre suivant. C'est là toute la différence entre un script et un module : le script attend ses ordres de l'utilisateur, le module attend ses données de l'appelant, et cette indépendance complète est la condition de tout ce qui suit désormais dans ce chapitre, et de chaque module que vous écrirez par la suite.

```python
from rich.console import Console
from rich.table import Table
import calc
console = Console()
def demander_notes():
    notes = []
    print("Saisissez les notes décimales, une par ligne.")
    print("Laissez vide puis validez pour terminer.")
    while True:
        saisie = input("Note : ").strip()
        if not saisie:
            return notes
        try:
            notes.append(float(saisie))
        except ValueError:
            print("Cette saisie n'est pas un nombre, réessayez.")
def afficher(resultat):
    table = Table(title="Bulletin de l'élève")
    table.add_column("Indicateur")
    table.add_column("Valeur", justify="right")
    table.add_row("Moyenne", str(resultat["moyenne"]))
    table.add_row("Médiane", str(resultat["mediane"]))
    table.add_row("Mention", resultat["mention"])
    console.print(table)
def main():
    notes = demander_notes()
    afficher(calc.resume(notes))
if __name__ == "__main__":
    main()
```

Ce second fichier, à enregistrer sous le nom `main.py`, est le point d'entrée unique du programme. Les trois premières lignes montrent l'ordre d'import recommandé : d'abord la bibliothèque tierce `rich`, puis votre module local `calc`, toujours rangés dans cet ordre en haut du fichier. La boucle `while True` de `demander_notes` illustre le chapitre 2, le bloc `try except` rappelle le chapitre 6, et l'appel `calc.resume(notes)` met en œuvre le chapitre 3 : tout ce que vous avez appris converge enfin dans un fichier court, organisé et lisible. Notez que `main()` ne fait que trois lignes, car le travail réel y est délégué à des fonctions nommées, chacune chargée d'une seule tâche précise. Pour installer la dépendance d'affichage puis figer l'environnement, exécutez les commandes suivantes depuis le dossier du projet, dans cet ordre ; la dernière sert à vérifier que le fichier généré suffit bien à reconstituer l'environnement à l'identique :

```python
pip install rich
pip freeze > requirements.txt
pip install -r requirements.txt
```

Le fichier `requirements.txt` généré contient alors une ligne du type `rich==13.7.0`, qui fixe la version exacte avec laquelle votre programme a été écrit et vérifié. C'est ce fichier que vous joignez au code, dans le dépôt du projet, pour que n'importe qui puisse reconstituer votre environnement à l'identique. Prenez l'habitude de le mettre à jour chaque fois que vous ajoutez ou retirez une bibliothèque : un `requirements.txt` périmé est pire qu'absent, car il laisse croire à un collègue que l'installation va fonctionner alors qu'elle installera une version qui n'a jamais servi à valider votre code. Une équipe qui néglige ce fichier passe en effet son temps à reconstituer à la main l'environnement de chacun, au lieu de travailler sur le projet lui-même. Pensez-y dès la toute première bibliothèque installée : le fichier est alors déjà à jour, et personne n'a jamais à reconstituer votre historique d'installation pas à pas, y compris longtemps après la sortie du projet.

Le démarrage tient désormais en une commande, exécutée depuis le dossier du projet : `python main.py`. Le programme vous invite à saisir les notes une par ligne, accepte une ligne vide pour terminer, rejette les saisies non numériques grâce au bloc `try except` du chapitre 6, puis affiche un tableau coloré produit par `rich`. Lancez aussi `python calc.py` : le garde déclenche alors la vérification intégrée et affiche le résumé des cinq notes d'essai, sans jamais demander quoi que ce soit au clavier. Ces deux comportements, identiques au code mais différents à l'exécution, sont exactement ceux annoncés dans la section sur `__name__`, et les observer vous-même en une minute vaut mieux que n'importe quelle explication théorique. Pourquoi deux fichiers plutôt qu'un ? Faisons l'expérience de pensée inverse : remettez tout dans `main.py` et demandez-vous où modifier le calcul de la mention, où ajouter l'écart-type, où brancher l'export JSON du rapport. Chaque modification vous obligera à rouvrir un fichier mêlant saisie, formatage et calcul, et à relire mille lignes pour retrouver le bon endroit. Avec le découpage, la mention se change dans `calc.py`, l'affichage se change dans `main.py`, et l'export s'ajoutera comme un troisième fichier sans toucher aux deux premiers. Le test reste le même que précédemment : si votre collègue doit corriger un calcul, doit-il ouvrir le fichier qui gère la saisie et l'affichage ? Ici, la réponse est non, et c'est toute la valeur de l'exercice.

Ce découpage est volontairement minimal, mais il est extensible sans remise en cause. Dès que la lecture du fichier de notes devient plus complexe, avec plusieurs formats ou des contrôles d'intégrité, elle gagne son propre module, souvent nommé `io_notes.py` ou `lire_notes.py`. Les structures de données du domaine, élève, note, matière, migrent vers `models.py`. À cinq ou six modules, le projet devient un package : vous créez un dossier `notes/`, vous y déplacez les fichiers, vous ajoutez `__init__.py`, et le lancement passe de `python main.py` à `python -m notes.cli`. Aucune fonction n'a besoin d'être réécrite, seuls les imports changent, et c'est précisément la trajectoire que vous suivrez au chapitre 8. Avant de passer à l'exercice, vérifiez quatre points : `calc.py` se lance seul et affiche sa vérification ; `main.py` importe `calc` sans provoquer la moindre impression ni saisie au chargement ; `requirements.txt` est présent, à jour et contient la version exacte de `rich` ; aucun fichier n'importe un autre qui l'importe en retour. Si ces quatre conditions sont réunies, votre projet est déjà plus propre que la majorité des scripts trouvés en ligne, et vous disposez d'une base saine pour la suite du parcours.
$lesson$),
  ('py-c7-p9', 'py-c7', 9, $lesson$À retenir$lesson$, $lesson$
- Un module est un fichier .py : tout fichier Python en est déjà un, sans déclaration particulière.
- `import math` donne accès à `math.sqrt`, l'origine de l'appel reste visible.
- `from math import sqrt` importe directement l'objet, code plus court mais origine implicite.
- `as` crée un alias, comme `import numpy as np` ou `from math import sqrt as racine`.
- La bibliothèque standard offre `statistics`, `pathlib`, `datetime`, `json`, `sys` sans rien installer.
- `if __name__ == "__main__":` n'exécute le bloc que si le fichier est lancé directement.
- Un module importé ne doit rien faire d'autre que définir des noms et des constantes.
- Découpez entre calcul et communication : `calc.py` calcule, `main.py` saisit et affiche.
- Un package est un dossier avec `__init__.py` qui rassemble des modules apparentés.
- Point d'entrée unique : un seul fichier pilote le lancement du programme.
- `pip install` ajoute une bibliothèque, `pip freeze > requirements.txt` fige les versions.
- Une dépendance est un engagement de maintenance : vérifiez la bibliothèque standard d'abord.
$lesson$),
  ('py-c7-p10', 'py-c7', 10, $lesson$Erreurs fréquentes$lesson$, $lesson$
- ModuleNotFoundError: No module named 'calc' → le dossier courant n'est pas celui du projet ; lancez la commande depuis le dossier contenant `calc.py`, ou vérifiez que les deux fichiers sont bien dans le même répertoire.
- Votre module affiche des résultats ou réclame une saisie dès qu'un autre fichier l'importe → tout le code placé en dehors des fonctions s'exécute au chargement ; déplacez-le sous `if __name__ == "__main__":`.
- ImportError: attempted relative import with no known parent package → vous avez lancé un module de package par son chemin ; utilisez `python -m notes.cli` depuis le dossier parent.
- ImportError: cannot import name ... → import circulaire entre deux modules ; extrayez les éléments communs dans un troisième module comme `models.py`.
- Le programme fonctionne chez vous et pas chez votre collègue → `requirements.txt` absent ou périmé ; régénérez-le avec `pip freeze > requirements.txt` et versionnez-le avec le code.
- pip répond que tout est installé mais l'import échoue → deux interpréteurs cohabitent ; écrivez `python -m pip install paquet` pour cibler le bon Python.
- Un import de la bibliothèque standard renvoie vos propres fichiers → un module local porte le même nom, comme `random.py` ou `email.py` ; renommez votre fichier.
- Un nom disparaît sans explication après un import → vous avez utilisé `from module import *` ; remplacez-le par des imports explicites.
$lesson$),
  ('py-c7-p11', 'py-c7', 11, $lesson$Pour aller plus loin$lesson$, $lesson$
Le tutoriel officiel de Python consacre un chapitre entier aux modules : il détaille la recherche des modules dans `sys.path`, la différence entre import absolu et relatif, le rôle exact de `__init__.py`, l'organisation des packages et les usages du garde `__name__`. La page du module `sys` de la bibliothèque standard complète ce tableau en décrivant de l'intérieur les mécanismes évoqués ici : `sys.path`, la liste des dossiers parcourus lors d'un import, `sys.modules`, le dictionnaire des modules déjà chargés, et `sys.argv`, la liste des arguments de la ligne de commande. Ces deux lectures suffisent à approfondir chaque notion de cette leçon, à expliquer la quasi-totalité des messages d'erreur d'import que vous rencontrerez, et à trouver des exemples complets que vous pourrez exécuter tel quels dans un interpréteur, avant de les adapter à vos propres modules. Commencez par le tutoriel, puis gardez la page `sys` en signet : vous la relirez bien plus souvent que vous ne le pensez. Adresses : https://docs.python.org/fr/3/tutorial/modules.html et https://docs.python.org/fr/3/library/sys.html

La documentation officielle de pip, elle, décrit la gestion des installations, le format des fichiers de dépendances, les options de `pip freeze` et les bonnes pratiques d'environnement isolé. Elle répondra à vos questions sur les contraintes de version, sur les installations effectuées depuis un dépôt privé, et sur la mise à jour contrôlée d'une dépendance sans casser un projet en production. Vous y trouverez aussi la référence complète des commandes, la description des options avancées et des exemples de fichiers de dépendances, ce qui vous évitera de recopier une configuration venue d'un tutoriel qui ne correspond pas à votre machine. Lisez-la le moment venu, c'est-à-dire au premier problème réel d'installation, plutôt que d'avance : une documentation de référence se mémorise mal, mais se consulte remarquablement bien dès que vous savez quelle question vous posez. Gardez aussi cette habitude de lire la version installée plutôt que la version supposée, car les deux diffèrent souvent. Adresse : https://pip.pypa.io/en/stable/
$lesson$),
  ('py-c7-p12', 'py-c7', 12, $lesson$Et maintenant : la vidéo du chapitre$lesson$, $lesson$
La vidéo prolonge cette leçon pas à pas : vous verrez le découpage d'un script unique en modules, la navigation entre fichiers dans un éditeur de code, l'effet concret du garde `__name__`, puis la création d'un `requirements.txt` et son utilisation sur une machine neuve. Regardez-la en gardant vos propres fichiers sous la main, puis passez à l'exercice pratique : vous découpererez l'analyseur de notes en `calc.py` et `main.py`, et vous ajouterez le `requirements.txt` avec `rich`, la dépendance réellement utilisée pour l'affichage. Avant de lancer la vidéo, rouvrez vos fichiers des chapitres précédents et repérez ceux qui mériteraient déjà d'être scindés en deux : ce petit examen préparatoire vous fera suivre les étapes du montage avec votre propre code en tête, ce qui vaut cent fois la recette copiée sans réflexion. Notez au passage les instants où l'instructeur hésite ou corrige une erreur : ils valent eux aussi le détour, car c'est exactement ainsi que se comporte un projet réel en cours de construction.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('py-c8-p1', 'py-c8', 1, $lesson$Comprendre : la méthode d'un projet Python$lesson$, $lesson$
Vous voici au huitième et dernier chapitre du parcours « Python : du premier script au projet complet ». Sept étapes vous ont chacune apporté une pièce indispensable : le premier chapitre vous a appris à créer des variables et à manipuler les types de base, le deuxième à prendre des décisions avec les conditions et à répéter des actions avec les boucles, le troisième à découper votre code en fonctions claires et réutilisables, le quatrième à représenter des données groupées avec les listes et les dictionnaires, le cinquième à conserver l'information d'une exécution à l'autre en lisant et en écrivant des fichiers, le sixième à prévoir l'imprévisible grâce aux exceptions, et le septième à sortir du script unique en créant des modules, des packages et en installant des bibliothèques avec pip. Prises une à une, ces notions forment un programme de cours ; assemblées avec méthode, elles forment un outil que quelqu'un peut réellement utiliser.

La différence entre un exercice et un projet tient à trois choses. Le point de départ n'est plus une consigne écrite par un formateur, mais un besoin explicite que vous devez traduire en comportements observables. Les données ne sont plus des valeurs idéales saisies dans le code, mais un fichier réel dont personne ne vous garantit la propreté : une colonne manquante, une note laissée vide, un encodage bizarre. Et la fin n'est plus un affichage à l'écran que vous seul regardez, mais un livrable que quelqu'un d'autre doit pouvoir ouvrir, lire et comprendre sans vous poser de question. Une part importante du travail de projet est d'ailleurs invisible dans le code : nommer les fichiers, choisir l'ordre des traitements, décider ce qui mérite une erreur fatale et ce qui mérite seulement un avertissement, formuler des messages que l'utilisateur finira par lire un vendredi soir. Ces décisions ne s'apprennent pas en mémorisant de la syntaxe, elles s'apprennent en les prenant une fois, en les assumant, puis en les revoyant.

Votre mission tient en une phrase : produire un analyseur de notes qui lit un fichier CSV contenant les notes d'un groupe d'étudiants, calcule les indicateurs attendus, affiche un résumé clair, puis écrit un fichier rapport.txt que vous pourriez envoyer à un formateur sans le modifier. Les objectifs de ce chapitre sont triples : structurer un petit projet en modules distincts, calculer moyenne, rang et mentions de façon fiable, et générer un rapport lisible à partir d'un fichier. Pour y arriver, vous commencerez par cadrer le travail avant d'ouvrir l'éditeur, puis vous répartirez le code en trois responsabilités, vous écrivrez les calculs, vous traiterez les cas limites avec des messages clairs, vous brancherez une option --csv en ligne de commande et vous testerez l'ensemble comme le ferait un professionnel. Tout ce que vous avez appris est déjà dans votre boîte à outils, il ne reste plus qu'à s'en servir.



Un projet commence rarement par une ligne de code, et presque toujours par une phrase à transformer. « Je veux analyser les notes d'une classe » est une envie ; « le programme lit un fichier de notes, en calcule la moyenne et la médiane, classe les étudiants, attribue une mention à chacun, affiche un résumé et écrit un rapport » est un cadrage. La différence est énorme : la première phrase ne se vérifie pas, la seconde se coche point par point. Avant d'écrire quoi que ce soit, transformez donc votre envie en comportements observables, c'est-à-dire en actions que l'utilisateur peut déclencher et en résultats qu'il peut constater. Cette discipline vous évite les trois écueils classiques du débutant : commencer par l'interface et se perdre, ajouter des fonctionnalités que personne n'a demandées, ou découvrir à la fin que le fichier d'entrée ne contient pas les informations supposées.

La deuxième étape consiste à écrire le flux en pseudo-code, dans l'ordre exact où les choses doivent se produire. Le pseudo-code n'est pas du Python : c'est une phrase par étape, en langage naturel, avec les décisions et les sorties d'urgence. Il sert de fil rouge pendant tout le développement et de contrat écrit quand vous reviendrez sur le projet dans trois semaines. Surtout, il vous force à apercevoir les branches avant qu'elles n'existent : que se passe-t-il si le fichier n'est pas là, si la colonne note manque, si la liste des étudiants est vide ? Si vous ne savez pas l'écrire en pseudo-code, vous ne saurez pas l'écrire en Python non plus. Prenez cinq minutes pour cette étape, vous en gagnerez une heure plus tard. Le support n'a aucune importance : un papier, un fichier texte, le commentaire en tête du fichier principal ou un tableau blanc conviennent, à condition que le flux soit lisible par quelqu'un d'autre que vous. Et le pseudo-code continue de vivre pendant le développement : dès qu'une hypothèse se révèle fausse, on corrige l'étape concernée avant de corriger le code, sinon la documentation ment et devient plus nuisible qu'utile. Gardez-le simple : des verbes d'action, des noms de variables qui seront ceux du programme, aucune phrase qui ne décrive une opération réelle.

Le flux que vous venez d'écrire se décompose presque toujours en quatre temps qui reviennent dans la quasi-totalité des programmes de traitement de données. Charger : ouvrir le fichier, lire les lignes, produire une structure de données en mémoire. Valider : vérifier que ce qui est arrivé correspond à ce que vous attendiez, colonnes présentes, notes exploitables, aucun doublon incohérent. Calculer : appliquer les règles métier sur des données déjà saines, moyennes, médianes, rangs, mentions. Restituer : rendre le résultat à l'utilisateur, dans le terminal ou dans un fichier. Ce découpage a une conséquence pratique très agréable : chaque étape peut échouer séparément, avec son propre message, au lieu de produire une pile d'appels que personne ne comprend.

Une fois les quatre temps identifiés, séparez les responsabilités dans des fichiers distincts : un module de chargement qui sait lire le CSV, un module de calcul qui sait raisonner sur les notes, un module de rendu qui sait produire du texte. Cette séparation n'est pas une coquetterie d'architecte, elle répond à un besoin concret : dans six mois, si le format du fichier change, vous n'ouvrirez que le module de chargement ; si la grille des mentions est révisée, vous n'ouvrirez que le module de calcul ; si le rapport doit devenir un PDF, vous n'ouvrirez que le module de rendu. Chaque fichier devient un endroit précis où aller chercher, et le reste du code continue de fonctionner. C'est cette résistance au changement qui distingue un assemblage fragile d'une petite architecture saine.

La conséquence directe de ce découpage, c'est la testabilité. Quand une fonction ne dépend que de ses paramètres, vous pouvez l'appeler toute seule, avec une valeur que vous avez choisie, et vérifier le résultat sans créer de fichier, sans ouvrir de terminal, sans attendre la fin du programme. C'est exactement le principe des fonctions que vous avez vu au chapitre trois, poussé à sa conséquence logique : une fonction de calcul qui va chercher elle-même le fichier CSV est impossible à tester proprement, car il faut à chaque fois fabriquer ce fichier. Une fonction qui reçoit une liste de notes en argument se vérifie en une ligne. Gardez cette idée en tête à chaque fois que vous écrivez une signature : que faut-il lui donner pour qu'elle puisse répondre ? Cette vérification tient en deux lignes : vous ouvrez une fenêtre de terminal, vous tapez `from calcul import moyenne` puis `moyenne([12, 14, 16])`, et vous voyez 14 apparaître sans rien installer ni préparer. Si le résultat est bon, la formule est bonne, et le reste du projet ne fera que l'appliquer à des données venues d'un fichier. Vous venez de tester votre logique métier là où c'est le moins cher du monde à tester, avant même que le chargement n'existe.

Le fichier principal, main.py, ne fait alors qu'orchestrer. Il appelle le chargement, vérifie le résultat, appelle les calculs, puis remet le tout au module de rendu. Il ne contient aucune formule, aucune règle métier, aucune lecture de fichier ligne à ligne : il donne l'ordre des opérations, c'est tout. Cette contrainte a un effet magique sur la lisibilité : en lisant uniquement main.py, on comprend le déroulement général du projet en dix secondes, sans se perdre dans les détails. Et quand un bug apparaît, la question « est-ce un problème de données, de calcul ou d'affichage ? » se tranche en regardant dans quel module se trouve la faute. L'orchestrateur reste court, les spécialistes font le travail.

Un projet digne de ce nom se construit par itérations, jamais d'un seul bloc. Vous écrivez d'abord la version la plus simple qui fonctionne, vous la testez, puis vous ajoutez une couche, puis une autre. L'alternative consiste à tout écrire pendant deux heures et à découvrir à la fin que rien ne tourne : vous ne savez alors plus quelle des vingt dernières lignes a cassé l'ensemble. Chaque itération doit se terminer sur un programme qui tourne et qui fait quelque chose d'utile, même si c'est peu de chose. Vous partez d'une lecture brute qui affiche les lignes, vous passez à des notes correctement converties, puis aux statistiques, puis au classement, puis au rapport, et enfin aux options en ligne de commande. À aucun moment vous n'avez un gros tas de code inutilisable.

Un mini-projet se protège aussi contre lui-même, en interdisant certaines tentations. Base de données, interface graphique, comptes d'utilisateurs, export PDF, connexion réseau : toutes ces idées sont légitimes, et toutes sortent du périmètre de l'analyseur. Le périmètre est la liste de ce que le programme doit faire, écrite noir sur blanc dans le cahier des charges, et tout ce qui n'y figure pas est reporté à une version ultérieure, dans une liste à part que l'on appelle parfois le parking. Cette discipline a une raison pratique : chaque fonctionnalité supplémentaire multiplie les cas limites à traiter, les messages à formuler et les tests à écrire, si bien qu'un projet qui veut tout faire ne finit jamais, tandis qu'un projet au périmètre clair atteint son point d'arrêt et devient utilisable. Elle vous donne aussi le droit de dire non à un ajout de dernière minute, en montrant que cette demande ne figurait pas au contrat initial. Et si l'idée est bonne, elle n'est pas perdue : notez-la dans un fichier TODO posé à côté du code, elle fera l'objet d'une prochaine version. L'énergie gagnée en refusant le superflu se voit immédiatement dans la qualité du livrable.

La robustesse, elle, se joue sur les bords. Le cas nominal où tout se passe bien prend rarement plus de vingt lignes ; c'est tout ce qui se passe quand les données ne sont pas conformes qui fait la qualité d'un projet. Colonne manquante, note vide, note écrite avec une virgule au lieu d'un point, doublon d'un même étudiant, fichier absent, encodage inconnu, fichier existant mais totalement vide : chacun de ces cas mérite un message clair, formulé en français, qui dit ce qui ne va pas et ce que l'utilisateur peut faire, plutôt qu'un traceur Python qui affiche une erreur interne dans un vocabulaire que vous seul comprenez. Prévoir ces cas n'est pas du pessimisme, c'est du respect pour la personne qui utilisera votre programme sans vous. Une méthode simple pour ne rien oublier : prenez votre pseudo-code et regardez chaque étape à l'envers. Que se passe-t-il si cette étape ne reçoit rien, si elle reçoit l'inverse de ce qu'on attend, si elle reçoit une valeur en texte à la place d'un nombre, si elle reçoit un doublon ? Chaque réponse devient un cas limite à traiter, et vous obtenez gratuitement la liste exhaustive des messages que votre programme devra afficher. Les développeurs expérimentés passent dix minutes à cette réflexion, parce qu'ils savent qu'une heure de débogage coûte toujours plus cher.

Le dernier point mérite d'être affirmé : un projet se juge à son livrable. Un affichage dans le terminal disparaît dès que la fenêtre se ferme ; un fichier rapport.txt, lui, reste, se copie, s'envoie, s'imprime. Il constitue la preuve concrète que le programme a fait son travail, et il force à soigner la mise en forme, les en-têtes, l'ordre des informations et l'arrondi des valeurs. Produire un résultat exploitable, compréhensible par une personne qui n'a jamais lancé le programme, est exactement ce qui distingue un exercice scolaire d'un projet dont vous pouvez être fier. C'est aussi le critère que retiendra un recruteur : pas le nombre de lignes, mais la capacité à livrer quelque chose d'utile.

Voici le déroulé de méthode que vous allez appliquer, dans l'ordre, du début à la fin du chapitre.

1. Écrire le besoin en une phrase, puis le décomposer en comportements observables que l'on peut cocher un par un.
2. Rédiger le flux complet en pseudo-code, en incluant les cas d'échec : fichier absent, donnée invalide, liste vide.
3. Découper ce flux en trois responsabilités : chargement, calcul, rendu, avec un fichier Python pour chacune.
4. Choisir la structure de données qui circule entre les modules : ici une liste de dictionnaires, un par étudiant.
5. Implémenter et tester le module de chargement à partir d'un petit fichier de quelques lignes, avant de penser aux statistiques.
6. Implémenter les calculs sur des listes de nombres fournies en dur, puis les relier aux données réellement chargées.
7. Ajouter le rendu : un résumé dans le terminal et un rapport.txt aux valeurs alignées et arrondies.
8. Brancher la ligne de commande avec --csv, puis vérifier que le même code traite plusieurs fichiers différents.
9. Attaquer les cas limites un par un, en transformant chaque erreur possible en message clair.
10. Relire l'ensemble, exécuter la passe de tests finale, et comparer le rapport produit au cahier des charges.

Pour garder le cap pendant tout le projet, revenez régulièrement à ces repères.

- Un fichier, une responsabilité : ne placez jamais la lecture du CSV et le calcul d'une moyenne dans la même fonction.
- Une fonction, une question : charger_notes demande où sont les données, moyenne demande quel est le niveau du groupe.
- Les valeurs en dur, comme les chemins, les seuils de mention et le séparateur CSV, sont regroupées au même endroit pour être modifiées une seule fois.
- La fonction qui calcule ignore où son résultat sera affiché : elle retourne une valeur et laisse le soin du reste à son appelant.
- Aucun échec ne produit un message incompréhensible : chaque erreur est traduite en une phrase que l'utilisateur peut agir immédiatement.
- On avance par petites étapes fonctionnelles : à la fin de chaque étape, le programme tourne et fait quelque chose d'utile.
- On teste d'abord avec de mauvaises données : c'est là que se cachent les vrais bugs, bien avant le cas nominal.
- Les constantes du projet, comme les seuils de mention ou le séparateur du fichier, portent un nom explicite et ne sont jamais répétées ailleurs.
- Chaque fonction tient sur un écran ; au-delà, elle réclame un découpage ou une simplification.
- Les messages d'erreur sont écrits du point de vue de l'utilisateur, en français, et jamais dans le vocabulaire de l'exception Python.
$lesson$),
  ('py-c8-p2', 'py-c8', 2, $lesson$Le cahier des charges de l'analyseur$lesson$, $lesson$
Tout commence par la définition précise de l'entrée. Votre analyseur accepte un fichier nommé notes.csv, dont la première ligne est un en-tête comportant au minimum les colonnes nom et note, puis une ligne par étudiant. Le séparateur est le point-virgule, parce que c'est celui qu'exporte naturellement un tableur francophone, et l'encodage est UTF-8. Cette convention doit être écrite quelque part, dans le cahier des charges puis dans le code, car elle constitue le contrat entre votre programme et le monde extérieur : si le contrat change, c'est le module de chargement qui s'adapte, pas le reste du projet. Notez que rien ne vous interdit d'accepter aussi la virgule décimale, très fréquente dans les exports français, au moment de convertir la note en nombre.

```csv
nom;note
Dupont;15.5
Martin;12
Durand;8.5
Leroy;17
Petit;11,5
```

La sortie attendue, elle, se décompose en deux formes : un résumé affiché dans le terminal pour la consultation immédiate, et un fichier rapport.txt pour la trace durable. Le rapport contient, dans cet ordre, le titre de l'analyse, le nom du fichier analysé, le nombre d'étudiants, la moyenne et la médiane du groupe, le top 3 des étudiants, puis la liste complète de chaque étudiant avec sa note arrondie à une décimale et sa mention. Toutes les valeurs numériques sont formatées de façon homogène, sans ces longues traînées de décimales que produit naturellement la machine. Ce format n'a rien d'anodin : il répond à la question que se posera le formateur, à savoir où en est le groupe et qui se distingue.

Les exigences se lisent ensuite en deux couches. Les exigences fonctionnelles décrivent ce que le programme fait : lire le fichier indiqué, valider son contenu, calculer moyenne, médiane, rang et mentions, afficher le top 3, écrire le rapport. Les exigences non fonctionnelles décrivent comment il le fait : il doit se terminer sans traceur quand les données sont mauvaises, afficher un message compréhensible en cas de fichier manquant, fonctionner depuis n'importe quel dossier d'exécution, et accepter un chemin de fichier fourni en ligne de commande sans aucune modification du code. Ces deux couches sont traitées à égalité dans un vrai projet ; ignorer la seconde produit des programmes qui marchent en démonstration et cassent dès qu'un collègue les utilise.

Ce cahier des charges n'exige aucun outil particulier : quelques lignes posées dans un fichier README à côté du code suffisent. Il y est écrit le format d'entrée attendu, colonnes nom et note, séparateur point-virgule, encodage UTF-8, la commande de lancement avec ses options, et le nom du fichier produit. Ce document fait partie du livrable : un projet sans README impose à quiconque ouvre le dossier de deviner l'usage, de chercher le nom du fichier d'entrée et de supposer quelles options existent. Il sert aussi de référence objective pendant le développement, car dès que deux personnes travaillent sur le même outil, ou dès que vous reviendrez au projet après un mois de pause, la question de savoir si la colonne peut s'appeler Note avec une majuscule se posera. Une décision prise une fois, écrite une fois, cesse de redevenir un débat à chaque exécution, et le lecteur du rapport lui-même sait alors quel contrat le fichier respecte.

L'exercice pratique de ce chapitre est la mise en œuvre littérale de ce cahier des charges : vous livrez un analyseur complet qui lit notes.csv, affiche le top 3 des étudiants, la moyenne et la médiane du groupe, puis la mention de chaque étudiant, et écrit enfin un fichier rapport.txt. Deux exigences supplémentaires sont attendues : le chemin du fichier se passe en ligne de commande avec l'option --csv chemin, et la disparition du fichier provoque une erreur gérée avec un message clair plutôt qu'un traceur Python. Pour réussir dans les temps, avancez dans l'ordre de cette leçon : le pseudo-code, puis les modules, puis les calculs vérifiés à la main sur cinq notes, puis le rendu, et seulement ensuite les options et les cas limites. Le rendu compte autant que le calcul : un rapport brouillon, aux valeurs mal arrondies et aux colonnes de travers, donne l'impression d'un projet bâclé alors même que les formules sont justes.

On considère enfin le projet terminé, ou « fait », lorsque tous les critères suivants sont cochés. Cette liste sert de checklist avant de dire que l'analyseur est livrable, et vous découvrirez qu'elle est plus exigeante qu'elle n'en a l'air : chaque point renvoie à un comportement vérifiable en une exécution, sans lecture du code.

- Le programme lit le fichier passé avec --csv, ou notes.csv par défaut s'aucune option n'est donnée.
- Un fichier absent provoque un message clair en français et un code de retour non nul, sans traceur Python.
- Une note vide, non numérique ou mal placée provoque un message indiquant le numéro de ligne concerné.
- La moyenne, la médiane, le classement et les mentions sont corrects sur un jeu de données que vous avez vérifié à la main.
- Le top 3 s'affiche dans le terminal avec les trois premiers étudiants dans l'ordre décroissant.
- Le rapport.txt est créé, relisible, avec toutes les valeurs arrondies de façon uniforme et chaque étudiant suivi de sa mention.
- Aucun traceur Python n'apparaît dans le terminal, quel que soit le fichier fourni, y compris un fichier vide ou corrompu.
- Le même jeu de données produit strictement le même rapport d'une exécution à l'autre, sans heure ni valeur variable.
- L'option --help s'affiche sans erreur et décrit chaque option en une phrase compréhensible.
$lesson$),
  ('py-c8-p3', 'py-c8', 3, $lesson$Architecture en modules : chargement, calcul et rendu$lesson$, $lesson$
Le projet tient physiquement en quatre fichiers Python, plus le jeu de données et le rapport produit. main.py orchestre l'ensemble, chargement.py sait transformer un fichier CSV en structure de données, calcul.py sait raisonner sur des notes, rendu.py sait transformer des résultats en texte lisible. À côté de ces fichiers se trouve notes.csv, l'entrée, et rapport.txt, la sortie durable, qui n'est pas un fichier source mais le résultat d'une exécution. Vous pourriez ajouter un cinquième fichier de configuration pour les seuils de mention, mais avec un projet de cette taille, une constante en haut du module de calcul suffit. La règle à retenir est simple : un fichier a une seule raison de changer, et cette raison dicte son nom. Les noms eux-mêmes suivent des règles triviales mais utiles : des minuscules et des soulignés, sans accent ni espace, parce que tout nom importé doit être tapé exactement tel quel par la personne qui appellera vos fonctions. Un module nommé calcul.py s'écrit facilement à n'importe quel clavier, un nom orné d'accents se transforme en erreur d'import au bout de trois essais. La même logique s'applique aux fonctions : charger_notes dit ce qu'elle fait, tandis que data ou truc signifient quelque chose que vous seul comprenez le jour où vous reviendrez au projet.

Le module de chargement est le seul à savoir ce qu'est un fichier CSV. Il reçoit un chemin en paramètre, retourne une liste de dictionnaires, un par étudiant, et lève une exception quand le contenu ne respecte pas le contrat. Il ne calcule aucune moyenne, n'imprime rien, ne décide pas de la suite : il transforme un fichier en données, c'est tout. Cette pureté de rôle a une conséquence précieuse, c'est que la même fonction sert aussi bien pour notes.csv que pour un fichier de 500 lignes ou un fichier cassé. L'encodage utf-8-sig mérite votre attention : il lit aussi bien un UTF-8 classique qu'un UTF-8 avec BOM, ce que produit souvent un export de tableur, et il évite ainsi un premier caractère invisible au début de la première colonne.

```python
import csv
ENCODAGE = "utf-8-sig"
SEPARATEUR = ";"
def charger_notes(chemin):
    with open(chemin, encoding=ENCODAGE, newline="") as fichier:
        lignes = list(csv.reader(fichier, delimiter=SEPARATEUR))
    if not lignes:
        raise ValueError("le fichier est vide : aucune ligne à analyser")
    entete = [colonne.strip().lower() for colonne in lignes[0]]
    if "nom" not in entete or "note" not in entete:
        raise ValueError("en-tête invalide : les colonnes nom et note sont attendues")
    index_nom = entete.index("nom")
    index_note = entete.index("note")
    etudiants = []
    for numero, ligne in enumerate(lignes[1:], start=2):
        if len(ligne) <= max(index_nom, index_note):
            raise ValueError(f"ligne {numero} : colonne manquante")
        brut = ligne[index_note].strip().replace(",", ".")
        if brut == "":
            raise ValueError(f"ligne {numero} : note vide")
        try:
            note = float(brut)
        except ValueError:
            raise ValueError(f"ligne {numero} : note illisible ({brut})")
        etudiants.append({"nom": ligne[index_nom].strip(), "note": note})
    return etudiants
```

Le module de calcul ne contient que des fonctions pures : elles reçoivent des valeurs, en retournent d'autres, et n'ont aucun effet visible sur le monde. Pas d'ouverture de fichier, pas d'impression, pas d'écriture sur le disque. Cette contrainte volontaire fait de lui le module le plus facile du projet à vérifier, puisqu'une seule ligne suffit pour appeler moyenne avec les nombres 12, 15 et 9 et constater que le résultat vaut 12. Vous pouvez même tester ces fonctions avant d'avoir écrit la moindre ligne de chargement, ce qui vous permet de valider les formules sur des cas simples avant de les confronter à de vraies données. Si vous ajoutez des docstrings, gardez-les courtes : une phrase qui dit ce que la fonction calcule, et ce qu'elle suppose sur ses entrées, comme la présence d'au moins une note.

Le module de rendu joue un rôle que l'on oublie souvent : il fabrique du texte. Plutôt que d'imprimer ligne à ligne depuis plusieurs endroits du programme, il construit d'abord la chaîne complète du rapport, puis la retourne ; l'écriture sur disque n'est qu'une opération finale, dans une petite fonction dédiée. L'avantage est double : vous pouvez afficher le rapport dans le terminal sans créer de fichier, vous pouvez l'écrire dans rapport.txt sans dupliquer la logique de mise en forme, et vous pouvez vérifier le rendu avec un petit jeu de données de test sans toucher au disque dur. C'est aussi l'endroit unique où l'on gère l'arrondi, les accents et l'ordre des sections, ce qui garantit que l'écran et le fichier racontent exactement la même histoire.

```python
def construire_rapport(etudiants, moyenne, mediane, chemin):
    lignes = []
    lignes.append("Rapport d'analyse des notes")
    lignes.append(f"Fichier analysé : {chemin}")
    lignes.append(f"Nombre d'étudiants : {len(etudiants)}")
    lignes.append(f"Moyenne du groupe : {moyenne:.2f}")
    lignes.append(f"Médiane du groupe : {mediane:.2f}")
    lignes.append("")
    for etudiant in etudiants:
        lignes.append(f"- {etudiant['nom']} : {etudiant['note']:.1f} ({etudiant['mention']})")
    return "\n".join(lignes)
def ecrire_rapport(chemin, texte):
    with open(chemin, "w", encoding="utf-8") as fichier:
        fichier.write(texte)
```

main.py, enfin, se contente d'orchestrer. Il importe les trois modules, récupère le chemin du fichier depuis la ligne de commande, appelle le chargement dans un bloc try, attrape les erreurs attendues pour les traduire, lance les calculs, enrichit chaque étudiant de sa mention, puis remet le texte au module de rendu et affiche le résumé. Aucune formule, aucune règle de métier, aucune lecture de fichier ligne à ligne n'apparaît dans ce fichier. Si vous parvenez à lire main.py de haut en bas en dix secondes et à comprendre le déroulement complet, l'architecture est bonne ; si vous devez décortiquer des boucles pour savoir ce qui se passe, c'est qu'une responsabilité a fui dans l'orchestrateur.

Quelques habitudes complètent cette architecture. Les imports se placent en haut du fichier, dans l'ordre bibliothèques standard puis modules du projet, et jamais au milieu du code. Aucun module ne déclenche d'action au moment de l'import : tout code exécutable se place dans des fonctions, ou derrière la garde if __name__ == "__main__": dans le fichier principal. Il n'y a pas d'import circulaire, calcul.py n'important ni chargement ni rendu, parce que les dépendances vont toujours dans un seul sens, des données vers l'affichage. Enfin, les noms sont explicites et sans abréviation obscure : charger_notes, classement, construire_rapport se comprennent seuls dans une liste de fonctions.

```table
Module | Rôle | Entrées | Sorties
--- | --- | --- | ---
`chargement.py` | Transforme un fichier CSV en structure de données | Un chemin de fichier | Une liste de dictionnaires, un par étudiant
`calcul.py` | Raisonne sur des notes avec des fonctions pures | Une liste de notes | Des valeurs, comme la moyenne et la médiane
`rendu.py` | Transforme des résultats en texte lisible | Étudiants, moyenne, médiane, chemin | La chaîne complète du rapport
```
$lesson$),
  ('py-c8-p4', 'py-c8', 4, $lesson$Métriques : moyenne, médiane, rang et mentions$lesson$, $lesson$
La moyenne est le calcul le plus connu et le plus trompeur, parce qu'il semble trop simple pour être mal fait. Elle s'obtient en additionnant toutes les notes puis en divisant par leur nombre, et en Python la bibliothèque standard statistics.mean fait exactement cela pour vous. Deux précautions changent pourtant la qualité du résultat. D'abord, on ne divise jamais par zéro : une liste vide doit être refusée en amont, avec un message clair, plutôt que de laisser remonter une StatisticsError au beau milieu du rapport. Ensuite, on arrondit tard : la valeur retournée reste un nombre complet, et c'est seulement au moment d'afficher ou d'écrire le rapport que l'on formatte avec deux décimales, pour ne pas accumuler des erreurs d'arrondi intermédiaires. Si vous voulez obtenir systématiquement un flottant, statistics.fmean le garantit : là où statistics.mean([2, 4]) renvoie l'entier 3, fmean renvoie 3.0, ce qui évite qu'un affichage non formaté ne montre une valeur entière là où vous attendiez une décimale. Quelle que soit la variante choisie, employez la même d'un bout à l'autre du projet : c'est en formatant une seule fois, au moment d'afficher, que le terminal et rapport.txt montreront des valeurs rigoureusement identiques.

La médiane complète la moyenne et protège votre analyse des extrêmes. Pour la calculer, on trie les notes puis on prend celle du milieu, ou la moyenne des deux valeurs centrales quand il y a un nombre pair de notes : statistics.median fait les deux cas. Son intérêt ressort immédiatement sur une classe où un étudiant a eu 2 et les autres entre 14 et 16 : la moyenne descend sous 14 alors que la médiane reste à 15, ce qui décrit beaucoup mieux le niveau réel du groupe. Présenter les deux valeurs dans votre rapport n'est donc pas de la redondance, c'est de l'honnêteté analytique, et cela montre que vous comprenez ce que vous produisez.

Le rang introduce la notion de classement, et avec elle la question des ex æquo. Deux étudiants notés 14 exactement doivent partager le même rang, et le suivant doit être classé juste après, au rang 3, et non au rang 2. L'implémentation consiste à trier une copie de la liste par note décroissante, puis à parcourir le résultat en comparant chaque note à la précédente : si elles sont égales, le rang reste inchangé, sinon il prend la valeur de la position courante. Attention à ne pas modifier la liste d'origine en la triant, car votre rapport affichera ensuite les étudiants dans l'ordre alphabétique ou dans l'ordre du fichier ; triez une copie avec sorted, qui en retourne une nouvelle.

```python
import statistics
def moyenne(notes):
    if not notes:
        raise ValueError("impossible de calculer la moyenne sans note")
    return statistics.mean(notes)
def mediane(notes):
    if not notes:
        raise ValueError("impossible de calculer la mediane sans note")
    return statistics.median(notes)
def classement(etudiants):
    tries = sorted(etudiants, key=lambda etudiant: etudiant["note"], reverse=True)
    rangs = []
    rang = 0
    for position, etudiant in enumerate(tries, start=1):
        if position == 1 or etudiant["note"] != tries[position - 2]["note"]:
            rang = position
        rangs.append({"nom": etudiant["nom"], "note": etudiant["note"], "rang": rang})
    return rangs
def top(etudiants, nombre=3):
    return sorted(etudiants, key=lambda etudiant: etudiant["note"], reverse=True)[:nombre]
```

Les mentions traduisent une note en appréciation textuelle, selon une grille de seuils que vous devez définir explicitement avant de coder. Une grille classique en établissement francophone retient Félicitations du jury à partir de 16, Très bien à partir de 14, Bien à partir de 12, Assez bien à partir de 10, Passable à partir de 8, et Insuffisant en deçà. Plutôt que d'écrire une cascade de conditions imbriquées, stockez ces seuils dans une liste de couples, du plus grand au plus petit, et parcourez-la en renvoyant le libellé dès que la note atteint le seuil courant : le premier seuil atteint gagne, et aucune condition n'est oubliée. Cette forme de données, une liste de tuples parcourue par une boucle, vous vient directement du chapitre sur les structures, et elle rend la grille modifiable en une seule ligne.

```python
MENTIONS = [
    (16, "Félicitations du jury"),
    (14, "Très bien"),
    (12, "Bien"),
    (10, "Assez bien"),
    (8, "Passable"),
    (0, "Insuffisant"),
]
def mention(note):
    for seuil, libelle in MENTIONS:
        if note >= seuil:
            return libelle
    return "Insuffisant"
```

Le classement des trois premiers, la meilleure note et la plus faible se déduisent ensuite sans effort de la même liste triée : un découpage avec [:3] donne le podium, max et min donnent les extrêmes, et une boucle sur le résultat enrichit chaque étudiant de sa mention avant l'affichage. Attention cependant à une subtilité d'affichage : les notes sont des nombres flottants, et une valeur comme 11.999999 affichée brute casse la présentation. Formatez systématiquement avec un nombre fixe de décimales, deux pour les moyennes et médianes, une pour les notes individuelles, de sorte que les colonnes du rapport s'alignent visuellement. Cette obsession de la présentation n'est pas cosmétique : un rapport illisible sera lu par personne.

Ces deux calculs ont un périmètre volontairement étroit, et c'est précisément ce qui les rend extensibles. Si votre classe demande la note la plus élevée, la plus basse, l'écart-type ou le nombre d'étudiants au-dessus de 14, vous écrivez une nouvelle fonction dans calcul.py, vous l'ajoutez à la liste des imports de main.py, et vous demandez à rendu.py d'afficher le résultat : aucun autre fichier n'est modifié, et les fonctions existantes continuent de fonctionner à l'identique. La bibliothèque statistics met d'ailleurs à disposition l'écart-type avec statistics.stdev, à condition d'au moins deux valeurs, ce qui vous oblige à traiter le cas d'une note unique. Gardez toutefois le réflexe inverse : résistez à l'envie d'ajouter une statistique au seul prétexte qu'elle est facile à coder. Une métrique qui ne répond à aucune question posée par l'utilisateur du rapport est du bruit, et le bruit finit par masquer les chiffres qui comptent.

```table
Métrique | Définition ou seuil | Exemple
--- | --- | ---
`moyenne` | Somme des notes divisée par leur nombre | `statistics.mean([2, 4])` renvoie 3
`médiane` | Note du milieu après tri, ou moyenne des deux valeurs centrales si le nombre de notes est pair | Avec un 2 et le reste entre 14 et 16, la médiane reste à 15
`rang` | Position après tri décroissant, une note égale partageant le même rang | Deux étudiants notés 14 sont rang 1, le suivant est rang 3
`mention` | Félicitations du jury à partir de 16, Très bien à partir de 14, Bien à partir de 12, Assez bien à partir de 10, Passable à partir de 8, Insuffisant en deçà | La note 16 donne Félicitations du jury
```
$lesson$),
  ('py-c8-p5', 'py-c8', 5, $lesson$Cas limites et messages clairs$lesson$, $lesson$
La robustesse d'un projet ne se mesure pas à la longueur de son cas nominal, mais à la qualité de ses refus. Le chemin heureux, où le fichier existe, où l'en-tête est parfait et où toutes les notes sont des nombres, tient en quelques lignes et fonctionne du premier coup ; tout le reste, ce sont les bords : fichier absent, fichier vide, colonne manquante, note laissée blanche, note saisie avec une virgule, note hors bornes, même étudiant présent deux fois, encodage inconnu, dossier en lecture seule. Chacun de ces cas existe réellement, et si vous ne les traitez pas, ils se manifestent par une pile d'appels que l'utilisateur ne comprendra pas. Le travail consiste donc à transformer chaque bord identifié dans votre pseudo-code en une phrase claire qui dit trois choses : ce qui s'est passé, où cela s'est passé, et ce que l'utilisateur peut faire ensuite.

La méthode que vous adopterez repose sur une séparation nette entre deux niveaux. En bas, dans le module de chargement, on lève une exception dès qu'une donnée contredit le contrat : ValueError accompagné d'un message précis, avec le numéro de ligne quand il est connu. Ce niveau ne décide de rien d'autre, il signale. En haut, dans main.py, on attrape ces exceptions et on les traduit en langage utilisateur, puis on interrompt le programme proprement. Cette répartition évite les deux écueils contraires : des modules qui appellent exit au milieu d'une boucle et rendent le code impossible à tester, et un orchestrateur qui laisse remonter un traceur brut jusqu'à l'utilisateur final.

L'inventaire des bords de votre analyseur tient en peu de lignes, mais il doit être écrit avant le code. Le fichier indiqué par --csv n'existe pas, ou pointe vers un dossier : FileNotFoundError. Il existe mais est vide, ou ne contient que l'en-tête : aucune donnée exploitable. L'en-tête ne contient pas les colonnes nom et note : le contrat d'entrée est rompu. Une ligne a moins de champs que prévu, ou sa note est vide, ou sa note n'est pas convertible en nombre : la ligne est illisible et son numéro doit être affiché. Le fichier est enregistré dans un encodage que Python ne reconnaît pas : UnicodeDecodeError. Enfin, un étudiant apparaît deux fois : ce n'est pas bloquant, mais cela mérite d'être signalé plutôt que d'être ignoré en silence.

Une décision délicate consiste à choisir ce qui interrompt le programme et ce qui se contente d'un avertissement. La règle la plus saine pour un projet de cette taille est d'échouer vite et clairement dès que la suite serait mensongère : sans fichier, sans colonnes, sans note exploitable, calculer une moyenne n'aurait aucun sens, autant s'arrêter avec un message. À l'inverse, un doublon ou une note hors bornes ne remet pas en cause l'ensemble : signalez-les, puis poursuivez. Cette frontière entre fatal et toléré doit être assumée, pas subie, et elle se lit directement dans le rapport que vous produisez.

- Fichier absent → le fichier indiqué est introuvable : vérifiez le chemin passé avec --csv.
- Dossier ou fichier illisible → impossible de lire ce chemin : vérifiez vos droits d'accès.
- Encodage inconnu → encodage non reconnu : enregistrez le fichier en UTF-8 depuis votre éditeur.
- En-tête incomplet → en-tête invalide : les colonnes nom et note sont attendues.
- Ligne incomplète → ligne 7 : moins de champs que l'en-tête n'annonce.
- Note vide → ligne 4 : note manquante pour l'étudiant Dupont.
- Note illisible → ligne 9 : note illisible (vingt-cinq) : saisissez un nombre.
- Aucune donnée → aucune note exploitable : le fichier ne contient aucune ligne de données.
- Note hors bornes → ligne 5 : note hors de l'intervalle 0-20 (35) : vérifiez la saisie.
- Étudiant en double → avertissement : Dupont apparaît 2 fois dans le fichier, la deuxième occurrence est conservée.
- Chemin pointant vers un dossier → erreur : ce chemin désigne un dossier, attendez le chemin d'un fichier CSV.

Le point d'entrée illustre cette traduction. Notez l'ordre des branches : UnicodeDecodeError est placé avant ValueError, car il en est une sous-classe, et une exception placée après une de ses classes parentes ne serait jamais atteinte.

```python
import sys
from chargement import charger_notes
def traiter(chemin):
    try:
        etudiants = charger_notes(chemin)
    except FileNotFoundError:
        sys.exit(f"Erreur : le fichier {chemin} est introuvable. Vérifiez l'option --csv.")
    except PermissionError:
        sys.exit(f"Erreur : impossible de lire {chemin} (droits d'accès insuffisants).")
    except UnicodeDecodeError:
        sys.exit(f"Erreur : encodage non reconnu dans {chemin}. Enregistrez-le en UTF-8.")
    except ValueError as erreur:
        sys.exit(f"Erreur de données dans {chemin} : {erreur}")
    if not etudiants:
        sys.exit("Erreur : aucune note exploitable dans le fichier.")
    return etudiants
```

La fonction sys.exit mérite qu'on s'y attarde : appelée avec une chaîne, elle affiche ce texte sur la sortie d'erreur et termine le programme avec le code 1, ce qui évite d'écrire print puis exit en deux temps et signale aux scripts et aux outils automatisés que l'exécution a échoué. Inversement, une terminaison naturelle produit le code 0, donc la commande echo $? sous Linux ou echo %ERRORLEVEL% sous Windows vous permet de vérifier la réussite d'une exécution sans lire une seule ligne de sortie. Ce détail devient crucial dès que vous enchaînez les tests en une seule commande : un programme qui renvoie toujours le code 0, même face à une entrée invalide, ne vous prévient de rien.

Reste le cas de l'encodage, le plus fréquent quand un fichier vient d'un tableur ou d'un autre ordinateur. Lire avec utf-8-sig résout le problème du BOM, ce caractère invisible ajouté en tête du fichier par certains logiciels, mais pas celui d'un fichier réellement enregistré dans un autre jeu de caractères. Plutôt que d'empiler cinq encodages dans une chaîne d'essais successifs, affichez le message qui indique la solution : le problème se règle en trente secondes dans l'éditeur de texte, et votre programme reste lisible. Préférez toujours une erreur qui oriente vers une solution qu'une logique défensive qui masque le vrai problème.
$lesson$),
  ('py-c8-p6', 'py-c8', 6, $lesson$Ligne de commande : l'option --csv chemin$lesson$, $lesson$
Tant que le chemin du fichier est écrit en dur dans le code, chaque test nouveau exige une modification de la source, avec le risque classique d'oublier de remettre la valeur par défaut avant de livrer. L'option --csv met fin à cette mauvaise habitude : le même exécutable traite n'importe quel fichier, et l'on passe d'un jeu de données à l'autre en changeant simplement la commande tapée. C'est aussi la frontière entre un script personnel et un outil que d'autres personnes peuvent utiliser. Un collègue lance l'analyseur sur son propre export, un formateur le lance sur trois classes différentes, et personne n'a besoin d'ouvrir votre code pour cela. Cette séparation a un effet secondaire très apprécié : la commande devient reproductible. Vous pouvez la noter dans le README, la copier dans un ticket, l'encadrer dans une documentation interne, et tout le monde obtient exactement le résultat que vous aviez obtenu. Elle devient aussi la brique élémentaire de vos vérifications : une suite de tests n'est rien d'autre qu'une liste de commandes exécutées dans l'ordre, chacune avec l'entrée qu'on lui a donnée et le code de retour qu'on attendait d'elle.

La forme la plus simple consiste à lire la liste sys.argv, qui contient les mots tapés après le nom du script, le premier élément étant toujours le nom du script lui-même. Le parsing à la main est pédagogique : on cherche l'option, on vérifie qu'une valeur la suit, puis on retourne le chemin ou la valeur par défaut. Notez la garde sur la longueur de la liste : sans elle, une option placée en dernière position provoquerait un index hors bornes, exactement le genre d'erreur que vous vous efforcez d'éviter ailleurs.

```python
import sys
def obtenir_chemin():
    if "--csv" in sys.argv:
        position = sys.argv.index("--csv")
        if position + 1 >= len(sys.argv):
            sys.exit("Erreur : l'option --csv doit être suivie d'un chemin de fichier.")
        return sys.argv[position + 1]
    return "notes.csv"
```

Cette version fonctionne, mais elle se dégrade vite : pas d'aide intégrée, pas de gestion des options inconnues, pas de message quand l'utilisateur oublie la valeur, et un code à maintenir dès que l'on ajoute une seconde option. La bibliothèque standard argparse fait tout cela en six lignes, et elle fournit gratuitement la commande --help qui liste les options avec leur description. C'est un excellent exemple de la leçon du chapitre sept : avant d'écrire vous-même un utilitaire, vérifiez qu'il n'existe pas déjà dans la bibliothèque standard ou dans un paquet pip.

```python
import argparse
def lire_arguments():
    analyseur = argparse.ArgumentParser(description="Analyseur de notes d'une classe")
    analyseur.add_argument("--csv", default="notes.csv", help="chemin du fichier CSV à analyser")
    analyseur.add_argument("--rapport", default="rapport.txt", help="chemin du rapport à écrire")
    return analyseur.parse_args()
```

Avec ce module, la ligne `python main.py --csv notes_classe_b.csv` analyse un autre fichier sans toucher au code, tandis que `python main.py` seul continue d'utiliser notes.csv, et `python main.py --help` affiche l'aide. Si l'utilisateur tape --csv sans valeur, argparse produit lui-même un message d'erreur et termine avec un code de retour non nul ; s'il tape une option inconnue, il signale aussi l'erreur au lieu d'ignorer silencieusement un argument. Le paramètre default porte la valeur par défaut, et c'est le seul endroit du projet où cette valeur est écrite.

L'option --csv appartient à l'interface publique de votre outil, et un nom d'interface se choisit comme un nom de variable : court, en minuscules, explicite, devinable sans ouvrir le code. On écrira --csv, ni un nom à rallonge comme --fichier-entrant, ni une abréviation comme -c, dont la signification obligerait de lire l'aide. Pensez aussi aux formes que l'utilisateur emploiera réellement : argparse accepte indifféremment `--csv notes.csv` et `--csv=notes.csv`, accepte `--help` en toutes lettres comme `-h`, et refuse les arguments inconnus au lieu de les ignorer silencieusement, ce qui évite un résultat calculé sur un fichier que personne n'avait demandé. Une dernière précaution tient en une ligne : un chemin contenant des espaces doit être entouré de guillemets dans le terminal, par exemple `python main.py --csv "notes classe B.csv"`. Il vaut mieux vérifier une fois ce cas de figure que de recevoir un message de fichier introuvable que l'utilisateur ne comprend pas.

Ajoutez à cela une conséquence pratique pour vos tests : chaque scénario devient une commande distincte, exécutable à la suite de l'autre, et vérifiable par son code de retour. On teste le fichier valide, puis un fichier absent, puis un fichier dont l'en-tête est cassé, sans jamais rouvrir l'éditeur. Les chemins relatifs fonctionnent par rapport au dossier d'où vous lancez la commande, ce qui vous oblige à penser à cette question de répertoire, une compétence qui vous servira dans tous vos projets futurs. Rien, dans cette approche, ne vous empêche d'ailleurs de créer un petit fichier .bat ou .sh qui lance la suite complète de ces vérifications.
$lesson$),
  ('py-c8-p7', 'py-c8', 7, $lesson$Tester son projet comme un pro$lesson$, $lesson$
Tester ne consiste pas à relancer le programme en regardant défiler le texte en espérant que rien ne casse. Un test, c'est une affirmation précise sur le comportement attendu, exécutée automatiquement, qui échoue bruyamment quand la réalité contredit le code. Pour un projet modulaire, cette vérification se fait à trois niveaux distincts : les fonctions de calcul, le chargement des données, puis l'exécution complète en ligne de commande. Tester chaque niveau séparément vous fait gagner un temps considérable, car un résultat inattendu vous indique immédiatement la couche fautive au lieu de vous laisser fouiller l'ensemble du projet.

Le premier niveau est à portée de main dès maintenant, car les fonctions de calcul sont pures et ne demandent aucun fichier. Un fichier test_analyseur.py de quelques lignes suffit : on importe les fonctions, on les appelle avec des valeurs que vous avez vérifiées mentalement, et on place des assert qui lèvent une AssertionError en cas d'écart. C'est la version minimale d'une suite de tests, et elle se lance avec `python test_analyseur.py`, sans framework ni installation. Ajoutez-y les cas limites : liste d'une seule note, notes égales pour vérifier les ex æquo du classement, note exactement sur un seuil de mention pour vérifier que la borne est bien incluse.

```python
from calcul import moyenne, mediane, mention, classement
assert moyenne([12, 14, 16]) == 14
assert mediane([1, 2, 3]) == 2
assert mediane([2, 4, 6, 8]) == 5
assert mention(16) == "Félicitations du jury"
assert mention(7.5) == "Insuffisant"
etudiants = [{"nom": "A", "note": 14}, {"nom": "B", "note": 14}, {"nom": "C", "note": 10}]
rangs = classement(etudiants)
assert rangs[0]["rang"] == 1 and rangs[1]["rang"] == 1
assert rangs[2]["rang"] == 3
print("Tous les tests passent")
```

Le deuxième niveau vérifie le chargement, et il a besoin de vrais fichiers : créez dans un dossier dédié un exemplaire valide, un fichier vide, un fichier sans la colonne note, un fichier avec une note manquante et un fichier dont le nom n'existe pas. Chaque cas doit produire soit la liste de dictionnaires attendue, soit l'exception prévue avec son message. Ce travail de préparation est le plus rentable du projet : ces petits fichiers vous serviront toute la vie de l'application, y compris pour reproduire un bug rapporté plus tard par un utilisateur, car un problème qu'on ne peut pas reproduire est un problème qu'on ne peut pas corriger.

Le troisième niveau est l'exécution complète, telle qu'un utilisateur la ferait : on tape la commande avec --csv, on lit le résumé affiché, on ouvre rapport.txt et on le compare à ce que le cahier des charges annonce. Puis on tape la commande avec un fichier inexistant et on vérifie que le message est clair et que le code de retour vaut bien 1. Cette passe finale se déroule toujours dans le même ordre : d'abord les données valides, puis chaque cas d'erreur, un par un, en corrigeant au fur et à mesure.

- Exécutez d'abord les tests unitaires : tant qu'ils échouent, inutile de lancer le programme complet.
- Testez le fichier valide de bout en bout, puis vérifiez chaque valeur du rapport à la main sur un petit jeu de cinq notes.
- Testez le fichier absent, le dossier à la place du fichier, et l'option --csv sans valeur.
- Testez le fichier vide, l'en-tête incomplet, la note manquante et la note non convertible.
- Testez un fichier avec des noms accentués et des notes en virgule pour valider l'encodage et la conversion.
- Relisez rapport.txt comme le ferait un tiers : titres, alignement, arrondis, cohérence des mentions.
- Relancez la suite complète après chaque modification, même celle qui vous paraît anodine.
- Comparez le rapport produit à une version de référence conservée : toute différence inattendue est une régression, même quand le programme ne plante pas.
- Vérifiez le code de retour de chaque exécution, pas seulement le texte affiché à l'écran.

Un dernier raffinement concerne la lisibilité des échecs. Un assert nu renvoie une AssertionError qui vous dit que quelque chose ne va pas, sans préciser quoi, ni la valeur attendue, ni la valeur obtenue ; sur une suite de vingt vérifications, vous perdez alors un temps précieux à retrouver celle qui a échoué. Préférez une petite fonction d'aide, à placer en tête du fichier de tests, qui reçoit un nom de cas, la valeur produite et la valeur attendue, affiche les trois en cas d'écart, puis lève une exception. Le message devient alors explicite, et il vous dispense d'ouvrir le code pour comprendre l'échec. Une règle accompagne cette pratique : un test qui échoue doit être corrigé, ou le code doit être corrigé, jamais simplement commenté au nom de l'urgence, car un test neutralisé ne prévient plus de rien et finit toujours par être oublié.

Cette discipline produit un effet rare et précieux : la confiance. Quand une suite de vérifications automatisées vous dit en une seconde que les quinze dernières modifications n'ont rien cassé, vous cessez d'avoir peur de toucher au code, et vous commencez à le simplifier, à le renommer, à le réorganiser. C'est exactement le moment où un projet cesse d'être une accumulation de lignes pour devenir un programme que vous maîtrisez. Gardez cette habitude bien au-delà du parcours : elle sépare les personnes qui livrent une première version de celles qui savent la maintenir.
$lesson$),
  ('py-c8-p8', 'py-c8', 8, $lesson$Exemple guidé : l'analyseur complet, fichier par fichier$lesson$, $lesson$
Voici maintenant le squelette complet de l'analyseur assemblé, présenté dans l'ordre où vous avez intérêt à le lire. On commence par calcul.py, parce qu'il est pur et qu'on peut le comprendre sans rien d'autre ; on enchaîne sur rendu.py, qui ne fait que du texte ; on aborde ensuite chargement.py, qui touche au disque ; et on termine par main.py, le plus court, qui relie tout. Les données circulent sous une forme unique d'un bout à l'autre du programme : une liste de dictionnaires, un par étudiant, avec les clés nom et note au départ, puis rang après le classement, puis mention avant le rendu. Cette convention unique évite de convertir les structures en permanence et rend chaque fonction immédiatement lisible, car elle sait exactement ce qu'elle reçoit.

Le module de calcul est le cœur tranquille du projet. Il importe la bibliothèque statistics, déclare la table des mentions sous forme de constante placée en tête du fichier pour qu'on la trouve sans chercher, puis expose cinq fonctions courtes : moyenne, mediane, mention, classement et top. Les deux premières refusent explicitement une liste vide, parce qu'un résultat faux serait pire qu'une erreur. La fonction classement travaille sur une copie triée et ne modifie jamais la liste reçue, ce qui vous permet d'afficher ensuite les étudiants dans l'ordre du fichier. Notez qu'aucune ligne ne lit un fichier ni n'imprime quelque chose : ce module est utilisable depuis n'importe quel autre programme, y compris un notebook ou un script de vérification.

```python
import statistics
MENTIONS = [
    (16, "Félicitations du jury"),
    (14, "Très bien"),
    (12, "Bien"),
    (10, "Assez bien"),
    (8, "Passable"),
    (0, "Insuffisant"),
]
def moyenne(notes):
    if not notes:
        raise ValueError("impossible de calculer la moyenne sans note")
    return statistics.mean(notes)
def mediane(notes):
    if not notes:
        raise ValueError("impossible de calculer la médiane sans note")
    return statistics.median(notes)
def mention(note):
    for seuil, libelle in MENTIONS:
        if note >= seuil:
            return libelle
    return "Insuffisant"
def classement(etudiants):
    tries = sorted(etudiants, key=lambda etudiant: etudiant["note"], reverse=True)
    rangs = []
    rang = 0
    for position, etudiant in enumerate(tries, start=1):
        if position == 1 or etudiant["note"] != tries[position - 2]["note"]:
            rang = position
        rangs.append({"nom": etudiant["nom"], "note": etudiant["note"], "rang": rang})
    return rangs
def top(etudiants, nombre=3):
    return sorted(etudiants, key=lambda etudiant: etudiant["note"], reverse=True)[:nombre]
```

Le détail du classement mérite une lecture attentive. sorted retourne une nouvelle liste, laissant l'ordre d'origine intact, et le paramètre key indique sur quelle clé trier, ici la note en ordre décroissant. La boucle parcourt ensuite ce résultat avec enumerate, dont l'index commence à 1 pour correspondre au rang humain : la première personne est première, pas zéro. À chaque position, on compare la note courante à celle de la précédente ; si elles sont égales, le rang reste celui calculé plus tôt, sinon il prend la position courante. Le résultat est exactement la règle d'ex æquo attendue : deux étudiants à 14 partagent le rang 1 et le suivant se retrouve troisième. Le paramètre nombre de top, avec sa valeur par défaut, vous permet d'afficher un top 5 en changeant un argument, sans toucher à la fonction.

rendu.py suit le principe énoncé plus haut : une fonction construit le rapport, l'autre l'écrit sur le disque. La signature de construire_rapport a été enrichie d'un paramètre podium depuis la première version que vous avez vue plus haut, et c'est précisément le genre de retombée positive que l'on attend d'une architecture découpée : ajouter une section au rapport n'a obligé à modifier que ce fichier, tandis que calcul.py et chargement.py sont restés intacts. Le rapport est assemblé dans une liste de lignes puis joint en une seule chaîne, ce qui évite d'appeler print ou write vingt fois et permet d'afficher le résultat à l'écran avant de l'enregistrer, pour vérification.

```python
def construire_rapport(etudiants, moyenne, mediane, podium, chemin):
    lignes = []
    lignes.append("Rapport d'analyse des notes")
    lignes.append(f"Fichier analysé : {chemin}")
    lignes.append(f"Nombre d'étudiants : {len(etudiants)}")
    lignes.append(f"Moyenne du groupe : {moyenne:.2f}")
    lignes.append(f"Médiane du groupe : {mediane:.2f}")
    lignes.append("")
    lignes.append("Podium des trois meilleurs :")
    for rang, etudiant in enumerate(podium, start=1):
        lignes.append(f"  {rang}. {etudiant['nom']} ({etudiant['note']:.1f})")
    lignes.append("")
    lignes.append("Détail par étudiant, du meilleur rang au dernier :")
    for etudiants_rang in etudiants:
        ligne = f"  {etudiants_rang['rang']}. {etudiants_rang['nom']}"
        lignes.append(f"{ligne} : {etudiants_rang['note']:.1f} ({etudiants_rang['mention']})")
    return "\n".join(lignes)
def ecrire_rapport(chemin, texte):
    with open(chemin, "w", encoding="utf-8") as fichier:
        fichier.write(texte)
```

main.py est volontairement le plus bref du projet. Il importe les modules voisins, lit les options, appelle le chargement dans un bloc try dont chaque branche se termine par un message et un arrêt, puis orchestre : extraction des notes dans une liste de nombres, classement, ajout de la mention à chaque étudiant, calcul des agrégats, construction du texte, affichage, enfin écriture. Si vous cherchez une formule dans ce fichier, vous ne la trouverez pas, et c'est exactement le but. La seule subtilité réside dans la garde if __name__ == "__main__":, qui lance main uniquement quand on exécute le script directement : en l'absence de cette ligne, importer main dans un test déclencherait immédiatement l'analyse complète.

```python
import sys
import argparse
from chargement import charger_notes
from calcul import moyenne, mediane, classement, top, mention
from rendu import construire_rapport, ecrire_rapport
def lire_arguments():
    analyseur = argparse.ArgumentParser(description="Analyseur de notes d'une classe")
    analyseur.add_argument("--csv", default="notes.csv", help="chemin du fichier CSV à analyser")
    analyseur.add_argument("--rapport", default="rapport.txt", help="chemin du rapport à écrire")
    return analyseur.parse_args()
def traiter(chemin):
    try:
        etudiants = charger_notes(chemin)
    except FileNotFoundError:
        sys.exit(f"Erreur : le fichier {chemin} est introuvable. Vérifiez l'option --csv.")
    except PermissionError:
        sys.exit(f"Erreur : impossible de lire {chemin} (droits d'accès insuffisants).")
    except UnicodeDecodeError:
        sys.exit(f"Erreur : encodage non reconnu dans {chemin}. Enregistrez-le en UTF-8.")
    except ValueError as erreur:
        sys.exit(f"Erreur de données dans {chemin} : {erreur}")
    if not etudiants:
        sys.exit("Erreur : aucune note exploitable dans le fichier.")
    return etudiants
def main():
    arguments = lire_arguments()
    etudiants = traiter(arguments.csv)
    notes = [etudiant["note"] for etudiant in etudiants]
    classement_etudiants = classement(etudiants)
    for etudiant in classement_etudiants:
        etudiant["mention"] = mention(etudiant["note"])
    texte = construire_rapport(
        classement_etudiants,
        moyenne(notes),
        mediane(notes),
        top(classement_etudiants),
        arguments.csv,
    )
    print(texte)
    ecrire_rapport(arguments.rapport, texte)
if __name__ == "__main__":
    main()
```

Suivez maintenant une exécution heureuse, de la première à la dernière seconde. Vous tapez `python main.py`, argparse retourne les valeurs par défaut, traiter appelle charger_notes, qui ouvre notes.csv en utf-8-sig, vérifie l'en-tête, convertit chaque note et renvoie la liste des étudiants. Les notes sont extraites dans une liste de nombres, le classement est produit, chaque étudiant reçoit sa mention, moyenne et médiane sont calculées, puis le rapport est construit une seule fois, affiché dans le terminal et écrit dans rapport.txt avec le même contenu. Deux exécutions, un seul texte : impossible que l'écran et le fichier se contredisent, puisqu'ils partagent la même chaîne.

Enchaînez avec une exécution ratée : vous tapez `python main.py --csv cours_de_grec.csv`, le fichier n'existe pas, Python lève FileNotFoundError, la branche correspondante de traiter l'attrape et affiche une phrase contenant le nom du fichier et la remarque sur l'option --csv, puis le programme se termine avec le code 1. Aucune traceur, aucun vocabulaire interne, aucune ambiguïté sur la cause. C'est ce contraste entre les deux exécutions qui fait la qualité perçue du projet : l'utilisateur n'a jamais besoin de deviner ce qui s'est passé.

Le squelette reste volontairement incomplet, et c'est normal. Il ne détecte pas les doublons, ne vérifie pas que la note est comprise entre 0 et 20, n'offre pas d'option pour choisir le nom du rapport sans modifier le code, et ne dispose pas encore de sa suite de tests automatisés. Chacune de ces améliorations se fait en un fichier, sans remettre en cause l'ensemble. Sachez cependant vous arrêter : un projet livré et utilisé vaut toujours mieux qu'un projet parfait jamais terminé, et le critère de réussite de ce chapitre, c'est le fichier rapport.txt que vous pouvez envoyer en l'état.
$lesson$),
  ('py-c8-p9', 'py-c8', 9, $lesson$À retenir$lesson$, $lesson$
- Un projet commence par un besoin traduit en comportements observables, jamais par l'ouverture de l'éditeur.
- Le pseudo-code décrit d'abord le succès, puis tous les cas d'échec, avant la première ligne de Python.
- Trois responsabilités, trois modules : chargement, calcul et rendu, un fichier par raison de changer.
- main.py orchestre : ni formule, ni lecture ligne à ligne, ni règle métier à l'intérieur.
- Les fonctions de calcul sont pures : elles reçoivent des valeurs et en retournent, sans effet de bord.
- Moyenne et médiane viennent de la bibliothèque standard statistics, après une vérification de liste non vide.
- Le rang se construit sur une copie triée, en comparant chaque note à la précédente pour gérer les ex æquo.
- Les mentions proviennent d'une table de seuils parcourue par une boucle, et non d'une cascade de conditions.
- Chaque cas limite devient un message qui dit quoi, où, et quoi faire ensuite, plutôt qu'un traceur.
- FileNotFoundError, UnicodeDecodeError et ValueError sont attrapés en haut du programme, dans le bon ordre.
- L'option --csv permet de tester plusieurs fichiers sans jamais rouvrir le code source.
- Le projet est terminé quand rapport.txt peut être envoyé tel quel à un formateur.
$lesson$),
  ('py-c8-p10', 'py-c8', 10, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Tout le projet dans main.py → découpez en chargement, calcul et rendu : un fichier qui grossit sans fin empêche de localiser un bug.
- Ignorer FileNotFoundError → attrapez-la dans le point d'entrée, affichez le nom du fichier et le conseil sur --csv, puis terminez avec un code 1.
- Tester uniquement avec un fichier valide → créez un dossier de cas limites : fichier vide, en-tête incomplet, note manquante, nom inexistant.
- Options non validées et chemins en dur → utilisez argparse avec --csv et une valeur par défaut, pour que l'oubli d'argument devienne un message d'aide.
- Ouvrir le fichier sans préciser l'encodage → lisez en utf-8-sig afin d'avaler le BOM des exports de tableur et d'éviter un UnicodeDecodeError obscur.
- Trier la liste d'origine avec sort → utilisez sorted, qui retourne une copie, sinon l'ordre du rapport est modifié sans que vous vous en rendiez compte.
- Afficher un nombre brut comme 11.999999 → formatez uniquement à l'affichage, avec :.2f pour les agrégats et :.1f pour les notes individuelles.
- Laisser remonter un traceur Python jusqu'à l'utilisateur → traduisez l'exception en phrase française avec sys.exit et vérifiez le code de retour.
$lesson$),
  ('py-c8-p11', 'py-c8', 11, $lesson$Pour aller plus loin$lesson$, $lesson$
Le tutoriel officiel de Python reste la référence pour consolider tout ce que ce projet met en œuvre, et il se lit aussi bien en suivant l'ordre des chapitres qu'en revenant sur un point précis : https://docs.python.org/fr/3/tutorial/index.html. Les chapitres consacrés aux entrées-sorties de fichiers et aux modules y sont directement applicables à votre analyseur, et la version française vous permet de vérifier la terminologie sans traduction intermédiaire.

Pour la partie ligne de commande, la documentation du module argparse détaille les types d'arguments, les valeurs par défaut, les arguments obligatoires et la génération automatique de l'aide : https://docs.python.org/fr/3/library/argparse.html. C'est une lecture courte qui vous évitera de réinventer un parseur à la main dès le prochain projet. Enfin, le chapitre du tutoriel consacré à la gestion des erreurs et des exceptions, https://docs.python.org/fr/3/tutorial/errors.html, explique la hiérarchie des exceptions et la construction de vos propres types d'erreur, utile quand un message générique comme ValueError ne suffit plus à décrire le problème.
$lesson$),
  ('py-c8-p12', 'py-c8', 12, $lesson$Et maintenant : la vidéo du chapitre$lesson$, $lesson$
La vidéo du chapitre vous montre ce projet construit de bout en bout, du fichier notes.csv vide jusqu'au rapport.txt final, en passant par la création des modules, les premiers tests et les cas limites rencontrés en direct. Regardez-la après avoir lu cette leçon, elle sert de contrepoint pratique à chaque décision théorique que vous venez d'étudier. Immédiatement après, l'exercice pratique devient votre livrable : livrez l'analyseur complet, qui lit notes.csv, affiche le top 3, la moyenne, la médiane et la mention de chaque étudiant, écrit rapport.txt, accepte --csv en ligne de commande et signale proprement un fichier manquant.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('web-c1-p1', 'web-c1', 1, $lesson$Ce que fait le HTML (et ce qu'il ne fait pas)$lesson$, $lesson$
Bienvenue dans le premier chapitre du parcours Développement web moderne, un chapitre entièrement consacré au HTML. Si vous n'avez jamais ouvert qu'un fichier texte, vous êtes exactement au bon endroit : ce cours ne suppose aucune connaissance technique préalable, aucun logiciel exotique à installer, seulement un ordinateur, un navigateur que vous utilisez déjà chaque jour et l'envie de comprendre comment les sites que vous visitez sont construits. Le HTML est le langage qui structure toutes les pages du web : chaque site que vous consultez, du service le plus modeste à la plateforme la plus élaborée, repose sur un fichier HTML que quelqu'un a écrit à la main ou que son outil a généré. Apprendre le HTML, ce n'est donc pas apprendre un détail parmi d'autres, c'est apprendre la langue dans laquelle le web s'exprime, la couche sur laquelle tout le reste, le design comme les interactions, vient se poser. Ce chapitre est votre porte d'entrée : il vous apprendra à décrire la structure d'une page, à choisir les bonnes balises selon le sens du contenu, et à livrer un document compréhensible aussi bien par un navigateur, par un lecteur d'écran que par un moteur de recherche.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées dans du vrai code. Vous comprendrez le rôle exact du HTML et la part qu'il laisse au CSS et au JavaScript. Vous écrirez le squelette complet d'une page, avec sa déclaration de type, son élément racine, sa zone d'en-tête technique et sa zone de contenu visible. Vous positionnerez les grandes régions sémantiques que sont header, nav, main, section, article, aside et footer, et vous saurez pourquoi elles valent mieux que la succession de conteneurs génériques que tout le monde utilisait il y a quinze ans. Vous construirez une hiérarchie de titres cohérente de h1 à h6, vous mettrez en forme le texte avec des paragraphes, des listes ordonnées ou non et des citations, vous insérerez des images décrites correctement, vous créerez des liens internes et externes avec des chemins relatifs ou absolus, vous construirez des formulaires accessibles et des tableaux de données enfin lisibles. Le tout sera assemblé dans un mini-projet guidé : la page complète d'un événement associatif, que vous pourrez réécrire seul juste après la leçon.

Une dernière recommandation sur la manière d'aborder ce chapitre, avant d'entrer dans le vif du sujet. Le HTML s'apprend comme on apprend à écrire : en formant soi-même les lettres, pas en regardant quelqu'un d'autre écrire. Rien ne remplace le geste de recopier chaque exemple dans un fichier, d'enregistrer ce fichier avec l'extension .html, de l'ouvrir dans votre navigateur et de regarder ce qui apparaît. Modifiez ensuite une balise, changez un texte, supprimez une fermeture : l'observation des conséquences est ce que vous fixerez le plus durablement en mémoire. Une page cassée n'est pas un échec, c'est une information : le navigateur vous dit alors exactement où votre structure ne tient pas, et plus vous lirez ces signaux attentivement, plus vous progresserez vite. Nous avancerons par étapes, en alternant explications détaillées, exemples de code commentés et bonnes pratiques issues du développement professionnel. Le fil rouge du chapitre sera une page d'événement complète : vous la construirez section par section dans l'exemple guidé, puis vous la récrirez seul dans l'exercice pratique qui suit cette leçon.



Le HTML signifie HyperText Markup Language, ce qui se traduit par langage de balisage hypertexte. Le mot important est balisage : un document HTML n'est pas un programme, c'est un texte ordinaire auquel on a ajouté des marqueurs, appelés balises, qui indiquent le rôle de chaque morceau. Quand vous écrivez un titre suivi d'un paragraphe puis d'une liste, vous n'ordonnez pas à la machine d'effectuer des calculs, vous décrivez la nature de l'information : ceci est un titre, ceci est un paragraphe, ceci est une liste d'éléments, ceci est un lien vers une autre page. Le navigateur prend ce texte, interprète les balises, construit en mémoire une structure en arbre de la page et se charge de l'afficher à l'écran. Contrairement à des langages comme Python ou JavaScript, le HTML ne connaît ni variable, ni condition, ni boucle : il décrit, il n'ordonne pas. Cette nuance est fondamentale, parce qu'elle délimite d'emblée ce que vous allez apprendre à faire et ce que vous laisserez à d'autres technologies.

L'analogie la plus parlante est celle du squelette d'un corps, ou mieux encore, celle d'un plan de bâtiment. Un plan indique où sont les murs, les portes, les fenêtres, les étages et les pièces ; il ne dit pas de quelle couleur seront les murs ni quel mobilier on y rangera. De la même façon, le HTML indique qu'une page contient un en-tête, une zone de navigation, un contenu principal, un encart latéral et un pied de page, sans rien décider de l'apparence de ces zones. Vous pouvez aussi comparer une page web à un livre imprimé : le livre a une couverture, une table des matières, des chapitres, des paragraphes, des notes de bas de page et des index. Chacun de ces éléments a un rôle que tout lecteur comprend instantanément, indépendamment de la police utilisée. Le HTML transcrit exactement cette logique : il donne un nom à chaque partie du contenu pour que chacune puisse être comprise, retrouvée, reprise et restituée, y compris par des outils que vous n'avez pas encore imaginés.

Cette description du sens est la moitié du travail. L'autre moitié revient à deux technologies voisines qu'il est utile de situer dès maintenant, sans les apprendre encore. Le CSS, ou Cascading Style Sheets, s'occupe de l'apparence : couleurs, polices, tailles, espacements, mise en page, animations. Le JavaScript s'occupe du comportement : réagir à un clic, afficher un menu, envoyer un formulaire sans recharger la page, charger un contenu supplémentaire à mesure que l'on défile. La répartition des responsabilités est nette : le HTML dit ce que c'est, le CSS dit à quoi ça ressemble, le JavaScript dit ce que ça fait. Pour reprendre l'image d'une recette de cuisine, le HTML liste les ingrédients et les étapes, le CSS compose l'assiette et choisie les couleurs de la table, le JavaScript met le minuteur en route. Cette séparation n'est pas une convention arbitraire : elle est la raison pour laquelle un site reste utilisable quand le CSS ne se charge pas, quand le JavaScript est désactivé ou quand un lecteur d'écran remplace l'écran.

```html
 class="carte-evenement">
  <h2>Atelier initiation au HTML</h2>
  >Samedi 18 octobre, de 14 h à 17 h, en médiathèque.>
  >
    >Ordinateur fourni>
    >Places limitées à 12 participants>
  >
   class="lien-inscription" href="inscription.html">S'inscrire>
>
```

L'exemple ci-dessus résume à lui seul tout ce que ce chapitre va détailler. Chaque ligne contient une balise : article pour un contenu autonome, h2 pour un titre de section, p pour un paragraphe, ul et li pour une liste non ordonnée, a pour un lien hypertexte. Les balises s'emboîtent, c'est-à-dire qu'une balise peut en contenir d'autres, et cet emboîtement dessine la structure de la page. Certaines balises, comme les balises de contenu, portent un texte entre leur ouverture et leur fermeture ; d'autres, dites éléments vides comme les images ou les retours à la ligne, n'ont pas de fermeture puisqu'elles ne contiennent rien. On trouve également des attributs : ce sont des informations complémentaires écrits dans la balise d'ouverture, sous la forme d'un nom et d'une valeur entre guillemets, comme l'attribut href qui indique la destination d'un lien ou l'attribut class qui sert à regrouper des éléments pour le style. Retenez ces trois mots, balise, contenu et attribut, car tout le vocabulaire du chapitre s'appuie dessus.

Le navigateur ne se contente pas d'afficher les balises les unes après les autres : il les empile dans une structure en arbre qu'on appelle le modèle de document, ou DOM pour Document Object Model. Chaque balise ouvrante crée une branche, tout ce qui se trouve à l'intérieur devient ses enfants, et la balise fermante referme la branche. De cette construction découlent deux règles de bon sens que vous appliquerez sans y penser après quelques exemples. La première : les balises doivent être correctement imbriquées, c'est-à-dire que si vous ouvrez un élément à l'intérieur d'un autre, vous devez fermer le plus récent avant de fermer l'autre. La seconde : l'ordre dans le fichier est l'ordre du contenu, et l'indentation, ces espaces que l'on ajoute en début de ligne pour montrer les niveaux, n'a aucun effet sur le rendu mais transforme la lecture du code. Un fichier HTML indenté se lit comme une arborescence, et votre futur collaborateur perçoit la structure d'un coup d'œil.

- Le HTML décrit la structure et le sens d'un document, il ne programme rien.
- Un élément combine une balise d'ouverture, un contenu et une balise de fermeture.
- Les attributs, écrits dans la balise d'ouverture, précisent un rôle ou une destination.
- Le HTML s'occupe du sens, le CSS de l'apparence, le JavaScript du comportement.
- Les balises s'emboîtent et forment un arbre, appelé DOM, que le navigateur construit.
- Une page reste utilisable sans CSS ni JavaScript si son HTML est bien construit.
- Privilégiez toujours la forme moderne des balises, maintenue par les spécifications.
$lesson$),
  ('web-c1-p2', 'web-c1', 2, $lesson$Le squelette d'une page : html, head et body$lesson$, $lesson$
Toute page web commence par une première ligne particulière, la déclaration de type de document, qu'on écrit avec le mot DOCTYPE précédé d'un point d'exclamation. Elle ne représente pas un élément visible : c'est un message adressé au navigateur pour lui indiquer que le fichier qui suit est du HTML moderne. Sans cette ligne, beaucoup de navigateurs basculent en mode historique, ancien mode de rendu conservé pour afficher correctement des pages très anciennes, et appliquent alors des règles d'interprétation surannées. Avec la déclaration, le navigateur bascule en mode standard, c'est-à-dire qu'il applique les règles actuelles de la spécification. La s'écrit exactement ainsi, sans espace ni variante : `!DOCTYPE html`. Comme elle est identique sur tous les sites, vous la copierez telle quelle dans chacun de vos fichiers, et vous ne l'écrirez presque plus réfléchir au bout de quelques pages.

Juste après cette déclaration commence le véritable document, délimité par la balise racine. Celle-ci porte le nom html et englobe tout le reste : sa balise de fermeture est la toute dernière ligne du fichier. La balise racine emporte presque toujours l'attribut lang, dont la valeur indique la langue principale du contenu, par exemple fr pour le français. Cet attribut a trois usages concrets qui justifient qu'on ne l'oublie jamais. Il aide le lecteur d'écran à choisir la voix et la prononciation correctes, il guide les navigateurs pour l'affichage des césures et des guillemets, et il renseigne les moteurs de recherche sur la langue de la page, ce qui évite d'envoyer un visiteur francophone sur une page qu'il ne comprendra pas. À l'intérieur de la racine, le document se divise en deux grandes zones qui se partagent la totalité du fichier : l'en-tête technique, qui décrit la page sans s'afficher, et le corps, qui contient tout ce que l'utilisateur verra.

L'en-tête technique rassemble les métadonnées, ces informations destinées aux navigateurs, aux systèmes et aux moteurs de recherche plutôt qu'aux lecteurs humains. Sa première tâche est de déclarer l'encodage des caractères, qu'on écrit avec la balise meta et l'attribut charset. La valeur utf-8 est le standard universel : elle couvre tous les alphabets du monde et garantit que vos accents, vos cédilles et vos guillemets français s'afficheront correctement partout. Sans elle, il arrive que la page affiche des caractères bizarres dès le premier é accollé à un guillemet. La deuxième tâche est de décrire la page pour les autres : le titre, un résumé pour les moteurs de recherche, éventuellement l'auteur ou la couleur du thème. La troisième consiste à relier la page à ses ressources externes, comme une feuille de style CSS ou une icône, par l'intermédiaire de la balise link. On verra plus loin comment la bibliothèque de styles s'intègre ; pour l'instant, retenez que l'en-tête technique est le tableau de bord invisible de votre page.

```html
<!DOCTYPE html>
 lang="fr">
>
  <!-- Métadonnées invisibles : elles décrivent la page -->
   charset="utf-8">
   name="viewport" content="width=device-width, initial-scale=1">
  >Atelier HTML du samedi — Médiathèque>
   name="description" content="Initiation gratuite au HTML, samedi 18 octobre.">
>
>
  <!-- Tout ce qui suit s'affiche à l'écran -->
  <h1>Bienvenue à l'atelier HTML</h1>
  >Cette page est votre premier document web.>
>
>
```

Le corps de la page, délimité par la balise body, contient tout ce qui s'affiche : titres, paragraphes, images, listes, boutons, formulaires, bref, l'intégralité du contenu visible. C'est dans cette zone que vous écrirez le travail qui remplit tout le reste du chapitre. Deux habitudes sont à prendre dès la première page. La première : ne placez jamais de contenu directement entre la balise racine et la balise du corps, car tout ce qui se trouve là risque d'être ignoré ou mal interprété. La seconde : le corps commence souvent par une ou plusieurs régions structurantes, comme l'en-tête de site, la zone de navigation et le contenu principal, que la section suivante introduit en détail. Un corps bien organisé se lit de haut en bas comme un plan : on y reconnaît immédiatement le bandeau, le menu, le contenu et le pied de page, sans avoir à deviner où l'on se trouve.

Deux autres métadonnées modernes valent le détour pour un débutant. La balise viewport, visible dans l'exemple, indique au navigateur mobile d'utiliser la largeur réelle de l'écran plutôt que de simuler un écran d'ordinateur réduit : sans elle, une page reste parfaitement lisible sur ordinateur mais illisible sur téléphone, où le texte apparaît minuscule et où il faut pincer sans cesse pour zoomer. La balise description, quant à elle, fournit le résumé affiché sous le titre dans les résultats de recherche. Elle ne fait pas grimper votre page dans les classements par magie, mais elle augmente fortement les chances que quelqu'un clique sur votre résultat plutôt que sur un autre, parce qu'elle répond à la question « est-ce que cette page parle de ce que je cherche ? ». Ces deux lignes coûtent quelques secondes d'écriture et produisent un gain durable de confort et de visibilité.

Avant de passer aux régions du contenu, fixons les conventions d'écriture qui rendent un fichier HTML professionnel. Chaque élément occupant une ligne, sa balise d'ouverture, son contenu éventuel et sa balise de fermeture se répartissent de manière lisible : les éléments imbriqués sont décalés d'un niveau, généralement de deux espaces ou d'une tabulation, de sorte que l'indentation dessine visuellement l'arborescence. Les balises s'écrivent en minuscules, par convention universelle, même si le navigateur accepte la majuscule. Les valeurs d'attributs sont mises entre guillemets droits, ce qui permet d'utiliser des apostrophes à l'intérieur sans ambiguïté. Les commentaires servent à laisser une note destinée à l'humain qui relira le fichier : le navigateur les ignore totalement et ils n'apparaissent jamais à l'écran, ce que vous verrez concrètement dans le squelette complet de cette section. Enfin, gardez les lignes raisonnables et aérez les grandes parties du document : votre fichier sera relu bien plus souvent qu'il ne sera écrit.

- La déclaration `!DOCTYPE html` bascule le navigateur en mode standard.
- La balise racine englobe tout le document et porte l'attribut `lang`.
- La zone d'en-tête technique décrit la page sans s'afficher à l'écran.
- Déclarez toujours l'encodage `utf-8` pour afficher correctement les accents.
- La balise `title` alimente l'onglet, les favoris et le titre des résultats de recherche.
- Le corps contient tout le contenu visible et commence par les régions structurantes.
- Indentez l'imbrication des balises : l'indentation reflète la structure, pas le rendu.
- Vérifiez toujours votre page en comparant le code source et l'affichage.
$lesson$),
  ('web-c1-p3', 'web-c1', 3, $lesson$Les régions d'une page : header, nav, main, section, article, aside, footer$lesson$, $lesson$
Pendant plus d'une décennie, les pages web ont été construites avec deux balises génériques seulement : une boîte appelée div, et une boîte pour du texte en ligne appelée span. On empilait des div à l'intérieur de div, on leur donnait des identifiants comme entete, menu, contenu ou bas, puis on demandait au CSS de deviner le rôle de chacune. Cette approche fonctionnait à l'affichage, mais elle était silencieuse : pour un navigateur, un lecteur d'écran ou un robot d'indexation, entete n'était qu'une boîte anonyme parmi d'autres. La révolution apportée par les balises sémantiques consiste précisément à remplacer ces boîtes muettes par des balises qui portent leur nom sur l'étiquette. Désormais, la balise header dit elle-même qu'elle contient un en-tête, nav dit qu'elle contient une navigation, main dit qu'elle contient le contenu principal. Le document devient auto-descriptif, et cette auto-description est le point de départ de l'accessibilité et du référencement que nous aborderons en fin de chapitre.

La première région est l'en-tête de page. Elle regroupe le contenu de présentation du début de document : le logo ou le nom du site, le titre du site, parfois un slogan, une zone de recherche ou une image d'ambiance. Attention à une confusion fréquente : la balise header n'a rien à voir avec la balise head, sa voisine de nom. La première s'affiche, la seconde décrit. On peut rencontrer header à plusieurs endroits dans un même fichier, par exemple un bandeau principal en haut de page et un second en-tête au sommet d'un article, mais il n'y en a qu'un par rôle : on ne répète pas l'en-tête du site au milieu d'un contenu. La balise se ferme elle-même avec la balise de fermeture du même nom, comme tous les éléments du chapitre, et son contenu reste libre : on y place autant de balises qu'il le faut, puisqu'un en-tête contient souvent un titre, une image et un lien.

La deuxième région est la navigation, réservée aux ensembles de liens qui font circuler l'utilisateur d'une page à l'autre : le menu principal, le fil d'Ariane qui montre le chemin parcouru, les liens vers la page précédente et la page suivante d'un tutoriel, ou la liste des articles d'une même catégorie. Sa particularité tient à sa valeur pour l'accessibilité : les lecteurs d'écran proposent une commande permettant de sauter directement d'une zone de navigation à l'autre, sans écouter toute la page. Un utilisateur aveugle pressé n'a pas envie d'entendre cinquante liens avant d'atteindre le contenu : avec une balise navigation identifiée, il saute au menu quand il le souhaite et au contenu quand il veut lire. Placez donc dans cette balise les vrais liens de circulation, et seulement ceux-là : un lien isolé en bas de page, comme la mention mentions légales, n'a pas besoin d'être englobé dans une navigation entière.

La troisième région est la plus importante de la page : le contenu principal. Elle porte le nom main et obéit à une règle absolue : il n'en existe qu'une seule par document. Cette unicité a une raison pratique, puisqu'elle permet au lecteur d'écran et aux technologies d'assistance d'ignorer tout le reste, bandeau, menu et pied de page, pour se rendre directement à la substance de la page. C'est aussi la zone que recherchent en priorité les moteurs de recherche, qui cherchent à distinguer le contenu du gabarit répété sur toutes les pages. La balise main ne doit jamais être imbriquée dans une autre balise structurante : elle est fille directe du corps, sœur de l'en-tête, de la navigation et du pied de page. À l'intérieur, tout est permis : titres, paragraphes, images, formulaires, tableaux, sections et articles que les sections suivantes vont détailler.

```html
>
  >
     src="logo.svg" alt="Retour à l'accueil — Médiathèque des Lilas">
    <h1>Médiathèque des Lilas</h1>
  >
   aria-label="Navigation principale">
    >
      > href="index.html">Accueil>>
      > href="ateliers.html">Ateliers>>
      > href="horaires.html">Horaires>>
    >
  >
  >
    >
      <h2>Atelier HTML du samedi</h2>
      >Une initiation de trois heures ouverte à tous les publics.>
    >
    >
      <h3>À retenir</h3>
      >Apportez votre ordinateur portable si vous en avez un.>
    >
  >
  >
    >© 2026 Médiathèque des Lilas — Mentions légales>
  >
>
```

La quatrième famille de régions sert à découper le contenu lui-même. La balise section regroupe un ensemble d'éléments qui traitent d'un même thème, et elle contient presque toujours un titre qui annonce ce thème : si vous hésitez à placer une section, demandez-vous si vous pourriez lui écrire un titre ; si la réponse est non, il s'agit probablement d'une simple boîte de mise en forme, donc d'un cas pour la balise div réservée au style. La balise article, elle, désigne un contenu autonome, c'est-à-dire un morceau qui garde tout son sens si on l'extrait de la page pour l'afficher ailleurs : une nouvelle, un commentaire de lecteur, une fiche de produit, une carte d'événement, un billet de blog. La différence entre les deux tient à cette autonomie : un article peut contenir plusieurs sections, une section peut contenir plusieurs articles, et les deux peuvent coexister dans le même document sans se nuire.

La cinquième région est l'encart latéral, matérialisé par la balise aside. Elle accueille du contenu secondaire qui prolonge le texte principal sans en faire partie intégrante : une définition, un lien vers un article connexe, une citation de contexte, une publicité, les caractéristiques techniques d'un produit, le sommaire d'une page longue. Le critère de choix est simple à formuler : retirez cet encart, la page reste compréhensible ; retirez le contenu principal, il ne reste rien. Attention toutefois à ne pas confondre aside avec la colonne latérale de votre mise en page. Une mise en page peut placer n'importe quelle balise à droite ou à gauche avec le CSS ; aside, lui, parle du sens et non de la position géographique. Un encart considéré comme secondaire peut parfaitement s'afficher au-dessus du texte sur un écran de téléphone étroit, sans perdre son rôle.

La sixième et dernière région régulière est le pied de page. La balise footer rassemble ce qui clôt une page ou une section : la mention d'auteur ou de copyright, le nom et l'adresse de l'organisation, les liens vers les mentions légales et la politique de confidentialité, la date de dernière mise à jour, les liens de partage ou les raccourcis de contact. Comme header, elle peut apparaître plusieurs fois dans un document, par exemple un pied de page global en bas de page et un pied de page local sous un article, qui portera alors la date de publication et l'auteur. À l'instar des autres régions, elle se distingue de la balise div uniquement par le sens qu'elle apporte : visuellement, l'une comme l'autre peut être stylée exactement à la même manière, mais seul footer annonce à l'outil qui lit la page qu'il s'agit d'une fin de document.

```table
Balise | Rôle principal | Exemple de contenu
--- | --- | ---
header | Bandeau d'identification | Logo, nom du site, titre principal
nav | Zones de circulation | Menu principal, fil d'Ariane, pagination
main | Contenu unique de la page | Article, formulaire, résultats de recherche
article | Contenu autonome | Nouvelle, commentaire, fiche d'événement
aside | Contenu secondaire | Définition, lien connexe, encart d'information
footer | Clôture de page ou de section | Copyright, contacts, mentions légales
```

Pour choisir parmi toutes ces balises, un raisonnement en trois questions suffit. D'abord : est-ce que ce morceau a un sens propre, indépendant du reste de la page ? Si oui, c'est un article. Ensuite : est-ce un thème qui mérite son titre dans le fil du document ? Si oui, c'est une section. Enfin : s'agit-il d'une région identifiée du gabarit, en-tête, menu, contenu principal, encart ou pied de page ? Si oui, prenez la balise correspondante. Si la réponse aux trois questions est non, et que vous cherchez uniquement une boîte pour appliquer un style, utilisez une div : cette balise n'a pas disparu, elle est simplement réservée aux cas où le style, et rien d'autre, justifie une boîte. La tentation est grande, au début, d'utiliser partout des div parce que cela semble plus général ; résistez-y, car chaque balise sémantique que vous omettez est une information que vous jetez.

- Remplacez autant que possible les div génériques par les balises qui décrivent le sens.
- Il n'existe qu'une seule balise `main` par page, fille directe du corps du document.
- `header` présente le contenu ; `head`, dans l'en-tête technique, le décrit sans l'afficher.
- `nav` regroupe les liens de circulation, pas chaque lien isolé du document.
- `article` désigne un contenu autonome ; `section` regroupe un thème assorti d'un titre.
- `aside` marque le contenu secondaire, quelle que soit sa position à l'écran.
- `footer` clôt une page ou une section : copyright, contacts, informations légales.
- Une `div` reste légitime quand la seule raison de la boîte est le style.
$lesson$),
  ('web-c1-p4', 'web-c1', 4, $lesson$Hiérarchie et titres : de h1 à h6$lesson$, $lesson$
Le titre est sans doute l'élément le plus sous-estimé du HTML, parce qu'il ressemble à du texte comme un autre alors qu'il porte à lui seul la moitié de la structure de votre page. Quand un lecteur arrive sur une page, il ne la lit pas ligne à ligne : il la balaye du regard, repère les blocs sombres qui annoncent les grandes parties, puis plonge dans celle qui l'intéresse. Les titres sont ces blocs visibles, et leur ordre raconte le plan du document. Quand un lecteur d'écran prend le relais, la situation est encore plus net : la personne peut demander la liste de tous les titres de la page et sauter directement du chapitre qui l'intéresse au suivant, sans écouter un seul paragraphe intermédiaire. Le moteur de recherche, de son côté, utilise les titres pour reconstituer la hiérarchie du contenu et comprendre de quoi parle réellement la page. Un titre n'est donc jamais un simple mot en gros : c'est un point de navigation, une promesse de contenu et un repère de structure.

Le HTML propose six niveaux de titres, numérotés de un à six, et ils s'imbriquent comme les titres d'un livre. Le premier niveau, noté `h1`, représente le titre principal de la page, l'équivalent du titre d'un ouvrage. Le second, `h2`, découpe le document en grandes parties, à l'image des chapitres. Le troisième, `h3`, sous-divise un chapitre, puis `h4` entre encore plus en détail, et ainsi de suite jusqu'au sixième niveau, qui reste rarement utile en pratique. L'image mentale à retenir est celle d'une table des matières : on descend d'un cran à chaque fois qu'on entre dans un sous-ensemble du sujet. Un document bien titré se lit même si l'on efface tout le reste : les seuls titres, lus à la suite, doivent déjà raconter l'histoire complète de la page.

```html
>
  <h1>Guide du nouvel arrivant</h1>

  >
    <h2>Préparer son arrivée</h2>
    >Rassemblez les documents nécessaires avant le premier jour.>

    <h3>Documents d'identité</h3>
    >Pièce d'identité, justificatif de domicile et photo d'identité.>

    <h3>Documents professionnels</h3>
    >Dernier diplôme obtenu et lettre de motivation éventuelle.>
  >

  >
    <h2>Premiers pas sur le site</h2>
    >Créez votre compte, puis complétez votre profil.>
  >
>
```

Trois règles simples régissent le choix du niveau, et il est préférable de les installer dès la première page. La première : un seul `h1` par document, qui porte le titre exact de la page. La deuxième : ne jamais sauter de niveau pour des raisons de mise en forme, c'est-à-dire ne pas passer de `h2` à `h4` parce que le quatre vous semblait mieux adapté visuellement. Si vous sautez un niveau, la table des matières automatique perd un échelon et l'arborescence devient faussée aux yeux des outils qui la lisent. La troisième : chaque section commence par son titre, placé au début et non à la fin du bloc, de sorte que le titre annonce réellement ce qui suit. Une section sans titre est un indice que le découpage mérite d'être revu ; un titre sans section est un vestige à supprimer.

La question de la taille mérite d'être traitée explicitement, car elle est à l'origine de la majorité des hiérarchies bancales. Par défaut, un navigateur affiche `h1` en très gros, `h2` un peu moins, et ainsi de suite, mais cette échelle n'est qu'un style par défaut, réversible à volonté. Si vous voulez un titre de section plus grand que le titre principal, vous le ferez avec le CSS, jamais en choisissant un niveau plus élevé. Le niveau dit la profondeur dans le plan ; l'apparence dit le rendu à l'écran ; les deux se commandent séparément. De même, un mot en gras au milieu d'un paragraphe n'est pas un titre : si l'information mérite d'être repérée dans le plan de la page, c'est qu'elle mérite d'être écrite avec une balise de titre. Réserver le gras à l'insistance et les balises de titre à la structure, voilà la frontière à ne pas franchir.

- Un seul `h1` par page, portant le titre exact du document.
- Les niveaux s'enchaînent sans saut : `h2` puis `h3`, jamais `h2` puis `h4`.
- Le niveau exprime la profondeur, le CSS exprime la taille : ne confondez pas les deux.
- Chaque section commence par un titre qui annonce son contenu.
- Des titres uniques, courts et écrits avec les mots du public.
- Un mot en gras n'est pas un titre : une information repérable mérite une balise de titre.
- Relisez la suite des titres seule : elle doit former un sommaire complet.
$lesson$),
  ('web-c1-p5', 'web-c1', 5, $lesson$Structurer le texte : paragraphes, listes et citations$lesson$, $lesson$
Le paragraphe est l'unité de base du texte écrit sur le web, et sa balise est sans doute la plus utilisée de tout le HTML. Un paragraphe regroupe un nombre raisonnable de phrases qui développent une même idée ; il se ferme automatiquement à la ligne suivante, comme dans un livre. Une subtilité mérite d'être connue dès maintenant : le navigateur compresse les espaces et les retours à la ligne du fichier source. Que vous écriviez trois espaces entre deux mots ou une seule, l'affichage est identique ; que vous coupiez une ligne au milieu d'une phrase pour respecter une largeur de colonne, le texte s'affiche sans coupure. Cette règle explique pourquoi l'indentation et les retours à la ligne du code n'ont aucune influence sur le rendu, et pourquoi vous pouvez formater votre fichier comme vous le souhaitez sans jamais changer l'apparence de la page. En revanche, une ligne vide sépare réellement deux blocs, et une balise vide comme `br` force un retour à la ligne, par exemple dans une adresse postale ou un poème.

Les listes constituent la deuxième grande famille de mise en forme textuelle, et il en existe deux à connaître. La liste non ordonnée regroupe des éléments dont l'ordre n'importe pas : les équipements d'une salle, les conditions de participation, les rubriques d'un menu. La liste ordonnée, elle, marque une séquence où l'ordre porte du sens : des étapes à suivre dans l'ordre, un classement, un historique, un mode d'emploi. Dans les deux cas, chaque entrée est portée par la balise de liste, et les éléments s'écrivent dans l'ordre où ils doivent apparaître. Les listes s'imbriquent aussi les unes dans les autres : il suffit d'ouvrir une sous-liste à l'intérieur d'un élément parent pour créer un sous-ensemble, ce qui est parfaitement normal et fréquent dans les sommaires. Ce groupement est un bon réflexe, car annoncer une liste à un lecteur d'écran, c'est lui donner en une commande le nombre d'éléments et la possibilité de sauter d'un élément au suivant.

```html
<h2>Programme de la journée</h2>

>
  >Découvrir le squelette complet d'une page>
  >Écrire ses premières balises de structure
    >
      >Titres et paragraphes>
      >Listes et liens>
    >
  >
  >Tester le résultat dans le navigateur>
>

>Dans cet atelier, >chaque balise porte un sens> et
l'animateeur insiste : >le sens précède toujours l'apparence>.>

>
  >Le HTML décrit la structure et la sémantique du contenu.>
  >Documentation MDN sur les éléments HTML>
>

>La balise >section> regroupe un thème assorti d'un titre, 
selon la définition de la spécification.>

>>&lt;section&gt;
  &lt;h2&gt;Titre de la section&lt;/h2&gt;
&lt;/section&gt;>>
```

Au milieu du texte courant, quelques balises servent à marquer l'emphasis et la mise en valeur. La balise `strong` indique une importance forte, celle que le lecteur doit repérer d'abord ; la balise `em` marque une insistance oratoire, une nuance qui change le sens de la phrase si on l'oublie. Toutes deux se prononcent à voix haute par les lecteurs d'écran, qui appliquent une intonation particulière, ce que le simple gras ne déclenche jamais. Les balises historiques `b` et `i`, elles, ne parlent que de l'apparence : elles restent tolérées mais sont déconseillées, sauf cas typographique précis comme les termes en langue étrangère. Quand vous voulez juste changer l'apparence d'un morceau de texte sans lui attribuer de rôle, la bonne solution est de lui attribuer une classe avec une balise neutre, puis de laisser le CSS s'en occuper. La règle tient en une phrase : dites le rôle, laissez le style au CSS.

Les citations forment une famille à part, souvent maltraitée au début. Pour une citation longue, qui constitue un bloc à part entière, on utilise la balise `blockquote` : elle marque l'origine du propos et permet d'y placer un paragraphe complet ainsi que l'attribution dans une balise `cite`, visible à l'écran. Pour une citation courte enchâssée dans une phrase, on emploie la balise `q`, qui ajoute automatiquement les guillemets dans la langue de la page. Quand vous citez une œuvre, un livre ou un article, la balise `cite` sert aussi à nommer le titre de cette œuvre. Ces éléments ont une valeur sémantique réelle : les lecteurs d'écran savent annoncer une citation, les outils de traitement de texte l'extraient, et les moteurs de recherche comprennent que le contenu appartient à quelqu'un d'autre. Le simple décalage de marge dessiné au CSS, lui, ne dit rien à personne.

Le code mérite enfin une attention particulière, parce que le HTML a la particularité de devoir afficher du HTML. Deux balises se partagent ce travail : la balise `code` marque un fragment de code court à l'intérieur d'une phrase, et la balise `pre` préserve la mise en forme du texte brut, espaces et retours à la ligne compris. Superposées, elles affichent un bloc de code tel qu'il a été écrit, avec son indentation. Attention à la règle qui sous-tend l'ensemble : à l'intérieur d'une page web, tout signe inférieur suivi d'un nom de balise doit être écrit sous la forme d'une entité, c'est-à-dire le symbole suivi de hash, de lt et du point-virgule pour ouvrir, et du même principe avec gt pour fermer. Sans cette précaution, le navigateur interpréterait votre exemple comme une vraie balise au lieu de l'afficher. Nous y reviendrons lorsque nous parlerons des caractères spéciaux.

- Choisissez `ol` quand l'ordre change le sens, `ul` sinon, et `li` pour chaque entrée.
- Une idée par paragraphe : le lecteur repère les blocs avant de lire les phrases.
- `strong` et `em` expriment un rôle ; `b` et `i` ne parlent que de l'apparence.
- Utilisez `blockquote` pour une citation longue et `q` pour une citation courte.
- Préservez la mise en forme du code avec `pre` puis `code`.
- Les espaces du fichier source sont ignorés à l'affichage, sauf dans `pre`.
- Annoncez toujours la nature d'un contenu avant de chercher à le décorer.
$lesson$),
  ('web-c1-p6', 'web-c1', 6, $lesson$Images : alt, figure et figcaption$lesson$, $lesson$
Une page web sans image est rare, et l'image est souvent l'élément qui porte le message : une photographie, un graphique, un logo, une capture d'écran, une carte. La balise qui l'insère est dite vide, car elle ne contient rien entre une ouverture et une fermeture : elle se résume à un nom d'image et à ses attributs. Le premier attribut, `src`, donne l'adresse du fichier image, soit un chemin relatif depuis la page, soit une adresse complète. Le second attribut, `alt`, est si important qu'il justifie à lui seul cette section : il fournit une description textuelle de l'image. Il sert à trois destinataires à la fois, et comprendre chacun d'eux vous aidera à l'écrire correctement. Le premier est la personne dont l'image ne s'affiche pas, parce que le fichier est introuvable ou la connexion a lâché. Le deuxième est la personne qui utilise un lecteur d'écran et n'a accès à rien d'autre qu'au texte. Le troisième est le moteur de recherche, qui ne voit pas l'image mais lit sa description.

Écrire un bon texte de remplacement est un savoir-faire qui s'apprend en quelques règles. La description doit dire ce que l'image montre ou ce qu'elle permet de faire, pas annoncer qu'il s'agit d'une image : écrire image de l'atelier est inutile, alors que douze participants devant un écran de projection apporte l'information manquante. Soyez concis : deux phrases suffisent en général, et il ne s'agit pas de transcrire chaque détail, mais de donner l'essentiel, la même information qu'un titre donne à un texte. Si l'image contient du texte, comme une affiche ou un capture d'écran d'interface, transcrivez ce texte, car personne d'autre ne peut l'atteindre. Enfin, une image purement décorative, qui n'apporte rien au sens, doit recevoir une description volontairement vide : c'est la seule façon d'indiquer au lecteur d'écran de passer l'image sans la lire à voix haute. Un attribut alt manquant n'a pas du tout le même effet : l'outil risque alors d'annoncer le nom du fichier, une suite de caractères incompréhensible.

```html
 src="images/atelier-html.jpg"
     alt="Douze participants devant un écran de projection"
     width="800" height="500">

<!-- Image décorative : description vide pour ne pas encombrer la lecture -->
 src="images/filet-decoration.svg" alt="" width="600" height="8">

>
   src="images/plan-mediatheque.png"
       alt="Plan du rez-de-chaussée de la médiathèque"
       width="640" height="480">
  >Entrée ouest, à côté du parking, au rez-de-chaussée.>
>
```

La paire `figure` et `figcaption` répond à un besoin différent de celui de la simple image. Elle sert à associer visuellement une illustration et sa légende, de manière indissociable : le lecteur comprend que la phrase de légende appartient bien à l'image qui la précède, et non au paragraphe suivant. On emploie ce couple pour les photographies annotées, les schémas, les graphiques, les extraits de code, les citations longues ou les tableaux, bref tout contenu illustré qui mérite son explication. La légende s'écrit dans la balise `figcaption`, presque toujours placée juste après l'image, et elle se lit comme une phrase complète, avec un point final. Attention à ne pas confondre figure avec la balise `aside` : la légende appartient au contenu principal, elle n'est pas un encart secondaire. Une figure peut aussi contenir plusieurs images ou un contenu plus riche, à condition de garder une seule légende qui couvre l'ensemble.

Deux attributs complémentaires méritent d'entrer dans vos réflexes dès maintenant. Les attributs de largeur et de hauteur déclarent les dimensions intrinsèques de l'image, même si le CSS les modifiera ensuite : leur seul effet est de réserver la place à l'avance, ce qui évite le décalage désagréable où le texte saute vers le bas au moment où l'image finit par se charger. C'est un détail de confort qui se voit immédiatement sur une connexion lente. L'attribut de chargement différé, dont la valeur est lazy, indique au navigateur de ne charger l'image que lorsqu'elle approche de la zone visible : sur une page comptant trente illustrations, la différence de vitesse est franche. Aucun des deux attributs ne remplace l'attribut de description, qui reste obligatoire, y compris et surtout pour les images de décoratives chargées en différé.

Les erreurs les plus fréquentes sur les images tiennent en trois. La première consiste à laisser l'attribut alt absent, souvent par légèreté, au nom du fichier sert alors de description calamiteuse. La deuxième consiste à écrire un alt générique, comme image ou photo1, qui n'apporte rien à personne. La troisième consiste à placer du texte entier dans une image, typiquement un visuel de promotion contenant une date et un tarif : ce texte devient alors inaccessible aux personnes malvoyantes, non indexé par les moteurs de recherche et impossible à corriger sans retoucher l'image. Quand le message est textuel, écrivez-le en texte et servez-vous de l'image pour l'illustrer, jamais pour le cacher. Cette seule habitude rendra vos pages plus rapides, plus indexables et plus inclusives.

- Chaque image porte un attribut `alt`, même quand il est volontairement vide.
- Décrivez le contenu ou la fonction de l'image, pas le fait que c'est une image.
- Une image décorative reçoit une description vide, jamais un attribut oublié.
- Associez illustration et légende avec `figure` et `figcaption`.
- Déclarez largeur et hauteur pour éviter les décalages pendant le chargement.
- Utilisez le chargement différé pour les longues pages illustrées.
- Préférez du texte réel à du texte peint dans une image.
$lesson$),
  ('web-c1-p7', 'web-c1', 7, $lesson$Liens et ancres : href, chemins relatifs et absolus$lesson$, $lesson$
Le lien hypertexte est l'élément qui a donné son nom au langage : c'est lui qui transforme un document isolé en un réseau de documents reliés. Il se écrit avec la balise `a`, pour ancre, et porte un attribut obligatoire, `href`, qui indique la destination. Ce que beaucoup de débutants ignorent, c'est que cette balise peut envelopper n'importe quoi : un mot, bien sûr, mais aussi une phrase entière, une image, une liste, voire toute une carte d'article. Quand un élément entier devient cliquable, c'est ce lien qu'il faut écrire, et non ajouter un lien séparé à côté, car la zone cliquable élargie améliore le confort de tous, en particulier sur écran tactile. Une seule règle encadre le texte du lien : il doit garder son sens lorsqu'on le lit hors contexte. Si votre lien s'intitule en savoir plus ou cliquez ici, le lecteur qui parcourt la page avec un outil de liste des liens n'entend plus rien ; écrivez plutôt en savoir plus sur l'inscription à l'atelier.

Les destinations se répartissent en deux grandes catégories, et la distinction commande toute votre manière de nommer les fichiers. Une adresse absolue contient le protocole, le nom de domaine et souvent le chemin complet : elle fonctionne depuis n'importe où, mais elle pointe toujours vers le même serveur. Un chemin relatif, lui, décrit la position d'un fichier par rapport à la page courante, ce qui rend l'ensemble déplaçable : vous pouvez copier votre dossier de travail sur une clé, l'envoyer à un collègue ou le basculer sur un serveur de test, et tous les liens internes continuent de fonctionner. Les conventions sont simples : le nom seul désigne un fichier du même dossier, un chemin avec barre oblique descend dans un sous-dossier, deux points suivis d'une barre remonte d'un niveau, et une barre au début part de la racine du site. Nommez vos fichiers sans accent ni espace, en minuscules, et tout devient prévisible.

```html
 aria-label="Fil d'Ariane">
  >
    > href="index.html">Accueil>>
    > href="../ateliers/index.html">Ateliers>>
    > href="atelier-html.html">Atelier HTML du samedi>>
  >
>

 id="programme">14 h, accueil des participants ; 14 h 30, prise en main de l'éditeur ; 16 h 30, pause.>

>Consulter  href="#programme">le programme de la journée>.>

>Contact par courriel :  href="mailto:atelier@mediatheque.fr">atelier@mediatheque.fr>>

>En savoir plus sur la
 href="https://www.w3.org/TR/html52/" target="_blank" rel="noopener">
spécification HTML du W3C>.>
```

Les ancres méritent une section à part, car elles font fonctionner la navigation à l'intérieur d'une seule page. Le mécanisme repose sur deux pièces : une cible, qui est n'importe quel élément portant un attribut `id` unique dans la page, et un lien dont la destination commence par le symbole réservé des identifiants. Quand l'utilisateur clique, le navigateur fait défiler la page jusqu'à la cible. Les cas d'usage sont nombreux : une table des matières en tête de page longue, un lien vers le formulaire de contact placé en bas de page, ou encore le lien d'évitement, cette première ligne invisible qui permet d'aller directement au contenu principal sans traverser le menu. Cette dernière pratique est un gain d'accessibilité considérable et figure presque toujours dans les audits : elle se résume à un lien vers l'attribut `id` de la zone principale, masqué à l'écran mais disponible au clavier.

Les destinations particulières ouvrent quelques possibilités complémentaires. Un lien vers une adresse de courrier électronique utilise le protocole dédié, suivi de l'adresse, et ouvre logiciel de messagerie ; un lien vers un numéro de téléphone, de plus en plus utile sur mobile, emploie le protocole téléphonique. Un lien de téléchargement ajoute un attribut qui ordonne d'enregistrer le fichier plutôt que de l'afficher, pratique pour un PDF de programme. L'ouverture d'un nouvel onglet, obtenue avec l'attribut `target` valorisé blank, s'utilise avec parcimonie : elle dépossède l'utilisateur de la touche retour, et lorsqu'elle est employée, elle doit être assortie de l'attribut de relations valorisé noopener, qui empêche la page ouverte d'accéder à votre page d'origine. Enfin, une destination interne au site reste toujours relative, et une destination externe est toujours complète, protocole compris : mélanger ces deux conventions est la première cause de liens cassés lors d'un déplacement de projet.

- Un lien se compose de la balise `a`, de l'attribut `href` et d'un libellé explicite.
- Évitez en savoir plus et cliquez ici : le libellé doit survivre hors contexte.
- Les chemins relatifs rendent un projet déplaçable, les adresses absolues pointent un serveur.
- Deux points et barre remontent d'un niveau, une barre au début part de la racine.
- Les identifiants sont uniques : ils servent d'ancres de navigation interne.
- Ajoutez l'étiquette de sécurité quand vous ouvrez un lien dans un nouvel onglet.
- Testez vos liens après chaque déplacement de fichiers.
$lesson$),
  ('web-c1-p8', 'web-c1', 8, $lesson$Des formulaires accessibles à tous$lesson$, $lesson$
Le formulaire est l'endroit où le visiteur cesse d'être un lecteur pour devenir un acteur : il inscrit son nom, choisit une date, coche des cases, envoie une demande. Sa balise englobe l'ensemble des champs et porte deux attributs historiques, `action`, qui indique l'adresse qui recevra les données, et `method`, qui précise la manière dont elles sont transmises. Dans la pratique moderne, le JavaScript intercepte souvent l'envoi, mais la structure de base reste la même, et c'est elle qui décide de l'ergonomie réelle du formulaire. La première règle à intégrer est simple : un champ sans étiquette est un champ illisible. Un internaute doit savoir, avant de taper, ce qu'on attend de lui, et une personne qui utilise un lecteur d'écran doit pouvoir faire le même constat sans deviner. Toute la difficulté des formulaires tient dans cette association entre le libellé visible et le champ, et le HTML fournit un mécanisme natif pour l'obtenir.

Ce mécanisme s'appelle l'étiquette, portée par la balise `label`, et elle se relie au champ par un couple d'attributs : l'attribut `for` de l'étiquette reprend exactement la valeur de l'attribut `id` du champ. L'identifiant, lui, doit être unique dans la page, ce que vous avez déjà appris dans la section sur les ancres. L'avantage de cette liaison va bien au-delà de la lisibilité : quand l'étiquette est correctement associée, cliquer sur le texte sélectionne le champ, ce qui élargit la zone cliquable de moitié pour tout le monde, et le lecteur d'écran annonce le libellé chaque fois que le champ reçoit le focus. À l'inverse, l'attribut d'invite, celui qui affiche un texte gris dans le champ, n'est pas une étiquette : il disparaît dès la première frappe et sert uniquement à montrer un exemple de saisie. L'erreur classique consiste à s'en contenter ; la correction consiste à écrire une vraie étiquette, éventuellement complétée par l'invite.

```html
 action="/inscription" method="post">
  >
    >Inscription à l'atelier>

     for="prenom">Prénom>
     type="text" id="prenom" name="prenom" autocomplete="given-name" required>

     for="courriel">Adresse électronique>
     type="email" id="courriel" name="courriel" autocomplete="email" required>

     for="naissance">Date de naissance>
     type="date" id="naissance" name="naissance" autocomplete="bday">

    >
      >Session souhaitée>
      > type="radio" name="session" value="matin"> Le matin>
      > type="radio" name="session" value="aprem"> L'après-midi>
    >

     for="message">Message à l'organisateur>
     id="message" name="message" rows="4">>

     type="submit">Envoyer mon inscription>
  >
>
```

Au-delà de l'étiquette, plusieurs habitudes rendent un formulaire immédiatement plus confortable. Le regroupement se fait avec la balise `fieldset`, qui englobe des champs apparentés, et sa balise de titre `legend`, qui nomme le groupe : c'est la seule façon d'indiquer qu'un ensemble de cases à cocher appartient à la même question, et le lecteur d'écran annonce le groupe avant chaque champ, ce qui évite les réponses au hasard. Le bon choix du type de champ apporte lui aussi un gain direct : le type courriel déclenche la vérification de format sur mobile, le type date ouvre un calendrier, le type numérique restreint le clavier à chiffres et signes, le type mot de passe masque la saisie. Ajoutez l'attribut `required` aux champs obligatoires et le navigateur refusera l'envoi tant qu'ils sont vides, avec un message dans la langue de la page. Enfin, l'attribut d'autocomplétion aide le navigateur à proposer les valeurs déjà connues, ce qui transforme un formulaire de six champs en deux gestes sur téléphone.

- Associez chaque champ à une étiquette grâce à `for` et `id`, jamais au seul placeholder.
- Regroupez les questions liées avec `fieldset` et nommez-les avec `legend`.
- Choisissez le bon type d'input : courriel, date, nombre, mot de passe, texte.
- Marquez le champ obligatoire avec `required` pour profiter de la validation native.
- Les identifiants restent uniques dans la page : c'est la clé des associations.
- Un libellé de bouton décrit l'action, pas le mot bouton.
$lesson$),
  ('web-c1-p9', 'web-c1', 9, $lesson$Tableaux de données : thead, tbody et th scope$lesson$, $lesson$
Le tableau HTML sert à une seule chose : présenter des données réellement tabulaires, c'est-à-dire des informations qui se lisent à la fois en ligne et en colonne. Horaires de train, comparatif de tarifs, résultats de match, grille de programme : là où la lecture croisée apporte quelque chose, le tableau est l'élément juste. En revanche, il ne sert jamais à mettre en page une page web. Pendant des années, des générations entières de sites ont utilisé des tableaux pour dessiner des colonnes et des rangées, au prix d'un code monstrueux et d'un contenu illisible pour les technologies d'assistance ; le CSS assure aujourd'hui cette mission, et le tableau est redevenu ce qu'il doit être, un outil de données. Si votre besoin est purement visuel, utilisez des balises de structure ; si votre besoin est de faire lire des chiffres alignés par colonnes, le tableau est parfait.

La structure d'un tableau se compose de trois couches. La balise `table` ouvre l'ensemble et peut porter un titre dans la balise `caption`, qui décrit l'objet du tableau en une phrase et dont se sert notamment le lecteur d'écran pour annoncer de quoi il s'agit. À l'intérieur, la balise `thead` regroupe la ou les lignes d'en-tête, et la balise `tbody` le corps des données ; une troisième zone, `tfoot`, permet de placer un pied de tableau, par exemple un total. Chaque ligne est portée par `tr`, et l'on y alterne deux types de cellules : l'en-tête de cellule, qui porte le nom de la colonne ou de la ligne, et la cellule de donnée, qui porte la valeur. La distinction n'est pas cosmétique : seules les cellules d'en-tête sont annoncées comme telles, et c'est sur elles que repose toute la lecture accessible du tableau.

```html
>
  >Programme de l'atelier HTML du samedi 18 octobre>
  >
    >
       scope="col">Horaire>
       scope="col">Intervenant>
       scope="col">Sujet>
    >
  >
  >
    >
       scope="row">14 h 00>
      >Nadia Benali>
      >Squelette d'une page et régions sémantiques>
    >
    >
       scope="row">15 h 15>
      >Marc Lefèvre>
      >Titres, listes, images et liens>
    >
    >
       scope="row">16 h 30>
      >Atelier pratique>
      >Écriture d'une page complète en autonomie>
    >
  >
>
```

L'attribut `scope` est la pièce qui rend le tableau réellement accessible, et son absence est l'erreur la plus fréquente. Il dit à l'outil de lecture si la cellule d'en-tête s'applique à toute la colonne ou à toute la ligne : la valeur col pour une en-tête de colonne, la valeur row pour une en-tête de ligne. Grâce à cela, une personne aveugle qui parcourt une cellule de données entend immédiatement de quelle colonne et de quelle ligne il s'agit, sans jamais perdre le fil. Sans cet attribut, le lecteur annonce une suite de chiffres et de mots sans contexte, et le tableau devient incompréhensible. Pour les tableaux complexes, plusieurs colonnes ou lignes d'en-tête, il existe des attributs d'extension qui relient chaque cellule à ses en-têtes, mais pour la grande majorité des tableaux du web, `scope` suffit amplement.

- Réservez `table` aux données croisées, jamais à la mise en page.
- Annoncez le tableau avec `caption` placée juste après l'ouverture.
- Distinguez les en-têtes avec `th` et les valeurs avec `td`.
- Renseignez `scope` sur chaque en-tête : `col` pour une colonne, `row` pour une ligne.
- Utilisez `thead`, `tbody` et `tfoot` pour séparer les zones logiques.
- Gardez une structure régulière : même nombre de cellules à chaque ligne.
$lesson$),
  ('web-c1-p10', 'web-c1', 10, $lesson$Attributs globaux : lang, id, class et data-*$lesson$, $lesson$
Toutes les balises du HTML partagent un jeu d'attributs communs, dit globaux, qui fonctionnent partout et qui portent une part importante de la puissance du langage. Le premier, `lang`, que vous avez déjà employé à la racine du document, déclare la langue du contenu. Il peut aussi s'utiliser au sein d'une page : si une phrase ou un paragraphe est rédigé dans une autre langue, on déclare cette langue sur l'élément concerné, et le lecteur d'écran change de voix, la prononciation devient correcte, le navigateur applique les règles typographiques de cette langue. Déclarer une citation anglaise dans une page française, par exemple, n'est pas un détail de politesse : c'est la différence entre une phrase prononcée correctement et une phrase accentuée de travers. L'attribut accepte un code de langue normalisé, composé d'un code de base éventuellement suivi d'un territoire.

Le deuxième attribut, `id`, désigne un élément de manière unique dans toute la page. Vous en connaissez déjà deux usages : l'ancrage d'un lien et l'association entre une étiquette et son champ. Le troisième, `class`, sert exactement à l'inverse : il regroupe. Un même élément peut porter plusieurs classes séparées par des espaces, ce qui permet de combiner des styles ou des comportements, par exemple une classe de forme et une couleur de fond. La discipline à adopter est celle du vocabulaire : nommez les classes d'après ce que l'élément est ou fait, et non d'après son apparence. Une classe nommée gris-clair devient fausse dès que le design change, alors que la classe prix-total reste vraie quoi qu'il advienne. Les deux attributs se complètent : l'identifiant repère un exemplaire, la classe rassemble une famille.

```html
 lang="fr">
  >
     id="programme" class="bloc bloc-emphase">
       class="carte carte-vedette" data-duree="180" data-complet="non">
        <h2>Atelier HTML du samedi</h2>
        >Trois heures d'initiation, en petit groupe.>
          class="note">Places encore disponibles.>
      >
       lang="en">Registration closes on Friday.>
    >
  >
>
```

Le dernier membre du quatuor, l'attribut de données, ouvre une porte intéressante : écrire des informations dans le HTML lui-même, sous une forme structurée, sans inventer d'attribut maison. On utilise `data-` suivi d'un nom libre, minuscules et tirets, et la valeur reste du texte. Ces attributs ne sont pas affichés et n'ont aucun effet visuel : ils sont faits pour être lus par le CSS ou, plus souvent, par le JavaScript, qui peut ainsi configurer un composant sans dupliquer l'information. Exemple : un bouton porte `data-etat="ouvert"` et le script ajuste son comportement en fonction de cette valeur. L'avantage est que la donnée reste visible dans le code source, donc débogable, et qu'elle reste attachée à l'élément concerné plutôt que dispersée dans un fichier de script. Il ne faut pas en abuser pour des informations destinées à l'utilisateur : celles-là s'écrivent en texte visible.

- `lang` déclare la langue, y compris localement pour une phrase étrangère.
- `id` repère un élément une seule fois dans la page ; `class` regroupe plusieurs éléments.
- Nommez les classes d'après le rôle ou le contenu, jamais d'après la couleur.
- `data-` suivi d'un nom libre stocke des informations lisibles par les scripts.
- Évitez `title` comme unique aide et `style` pour toute mise en forme durable.
- Un attribut global fonctionne sur toutes les balises : à vous d'en choisir le bon.
$lesson$),
  ('web-c1-p11', 'web-c1', 11, $lesson$Accessibilité et SEO : les retombées du sémantique$lesson$, $lesson$
À plusieurs reprises dans ce chapitre, les balises sémantiques ont été justifiées par deux destinataires : la personne qui consulte la page avec une technologie d'assistance et le robot qui l'indexe. Il est temps de résumer ces retombées, parce qu'elles transforment une contrainte apparente en avantage concurrentiel. L'accessibilité, au sens du web, c'est la possibilité pour toute personne de percevoir, comprendre, naviguer et interagir avec une page, quelle que soit sa situation : déficience visuelle, auditive, motrice ou cognitive, connexion lente, écran petit, clavier seulement. Un HTML sémantique n'est qu'une partie de la réponse, mais c'est la fondation : les régions rendent la navigation possible, les titres dessinent le plan, les descriptions d'images transmettent l'information visuelle, les étiquettes de formulaire rendent la saisie devinable, les en-têtes de tableau rendent les données navigables. Chacune de ces décisions a été prise au fil du chapitre ; ensemble, elles font la différence entre une page utilisable par tout le monde et une page réservée à ceux qui voient l'écran et manipulent une souris.

Le référencement naturel, pour sa part, profite de la même base pour une raison simple : le moteur de recherche est un lecteur aveugle pressé, qui analyse le texte, la structure et les liens pour deviner le sujet d'une page. Un document dont les titres découpent le contenu, dont les liens ont des libellés précis, dont les images sont décrites et dont les régions distinguent le fond du gabarit se comprend en une passe. Ajoutez-y un titre d'onglet explicite, une description de métadonnée rédigée à la main et des liens internes cohérents, et vous avez posé les bases d'un bon positionnement sans technique obscure. Inversement, aucune de ces qualités ne compense un contenu pauvre : le HTML expose le mérite du contenu, il ne le crée pas. Retenez la formule qui résume le chapitre : on optimise d'abord la structure et le sens, ensuite seulement les détails.

```table
Pratique sémantique | Bénéfice pour l'utilisateur | Bénéfice pour la recherche
--- | --- | ---
Balise main unique | Aller au contenu en une commande | Isoler le fond du gabarit
Hiérarchie de titres | Parcourir la page par chapitres | Comprendre le plan du sujet
Alt descriptif | Comprendre l'image sans la voir | Indexer le sujet illustré
Label associé | Saisir sans deviner le champ | Lire un formulaire cohérent
```

Au-delà du code, deux démarches valent la peine d'être mentionnées pour ne pas rester dans la théorie. La première est la vérification au clavier : débranchez la souris et parcourez votre page avec la touche de tabulation. Les liens et les champs doivent s'activer dans l'ordre logique du visuel, une zone de focus visible doit apparaître, et le lien d'évitement doit vous mener au contenu principal. Si vous vous perdez, un utilisateur malvoyant se perd aussi. La seconde est l'écoute de votre page avec un lecteur d'écran, disponible gratuitement sur tous les systèmes : en trente secondes, vous entendrez si les images sont décrites, si les listes sont annoncées, si les boutons ont un nom et si vos titres racontent une histoire cohérente. Ces deux contrôles coûtent presque rien et détectent la majorité des problèmes que la validation automatique ne voit pas.

Ces notions s'appuient sur des références publiques et gratuites, consultables sans inscription. Les critères officiels d'accessibilité sont publiés par le W3C dans son initiative pour l'accessibilité du web, et les tutoriels pratiques qu'il publie, consacrés aux formulaires, aux images et aux tableaux, correspondent exactement aux sections que vous venez de lire. Côté français, les obligations légales de l'accessibilité numérique s'inspirent de ces mêmes références, si bien que les réflexes acquis dans ce chapitre vous serviront aussi bien pour un site personnel que pour un projet professionnel soumis au contrôle. Le mot de la fin n'appartient pas à un outil de validation automatique mais à l'utilisateur : testez auprès de vraies personnes, corrigez, puis testez à nouveau.

- L'accessibilité repose sur une fondation HTML : régions, titres, descriptions, étiquettes.
- Le moteur de recherche lit le texte et la structure, pas l'apparence de votre page.
- Titre de page, description, hiérarchie et liens internes forment la base du référencement.
- Vérifiez votre page au clavier : tabulation, focus visible, lien d'évitement.
- Écoutez votre page avec un lecteur d'écran : c'est le test le plus rentable.
- La structure expose la qualité du contenu, elle ne la remplace jamais.
$lesson$),
  ('web-c1-p12', 'web-c1', 12, $lesson$Mini-projet guidé : la page d'un événement$lesson$, $lesson$
Il est temps d'assembler toutes les pièces du chapitre dans un document unique et complet : la page d'un événement, l'atelier HTML du samedi, qui servira de modèle à l'exercice pratique suivant. Ce projet mobilise chacune des notions abordées : en-tête technique complet, régions sémantiques, hiérarchie de titres, paragraphe, liste, image légendée, liens relatifs, ancre interne, tableau de programme, formulaire avec étiquettes et groupes, pied de page. Le fil conducteur reste le même depuis le début : chaque balise est choisie pour le sens qu'elle apporte, jamais pour l'apparence qu'on imagine. Écrivez ce fichier dans votre éditeur, enregistrez-le avec un nom simple comme atelier.html, ouvrez-le dans votre navigateur, puis modifiez-le : c'est en changeant un texte, une destination ou un niveau de titre que vous consoliderez chaque règle.

```html
<!DOCTYPE html>
 lang="fr">
>
   charset="utf-8">
   name="viewport" content="width=device-width, initial-scale=1">
  >Atelier HTML du samedi — Médiathèque des Lilas>
   name="description" content="Initiation gratuite au HTML, samedi 18 octobre, places limitées.">
>
>
  >
     src="logo.svg" alt="Médiathèque des Lilas — accueil" width="160" height="48">
    <h1>Atelier HTML du samedi</h1>
  >

   aria-label="Navigation principale">
    >
      > href="index.html">Accueil>>
      > href="#programme">Programme>>
      > href="#inscription">Inscription>>
    >
  >

  >
    >
      <h2>Trois heures pour écrire votre première page</h2>
      >L'atelier ouvre à tout public débutant, sans prérequis technique.>

      >
         src="images/atelier.jpg"
             alt="Participants écrivant du code sur leurs ordinateurs portables"
             width="800" height="500">
        >Atelier précédent, salle informatique du rez-de-chaussée.>
      >

       id="programme">
        <h3>Programme de la journée</h3>
        >
          >Découvrir le squelette d'une page>
          >Écrire titres, listes, images et liens>
          >Construire un formulaire accessible>
        >
      >

       id="inscription">
        <h3>Inscription</h3>
         action="/inscription" method="post">
          >
            >Vos coordonnées>
             for="nom">Nom complet>
             type="text" id="nom" name="nom" autocomplete="name" required>
             for="courriel">Adresse électronique>
             type="email" id="courriel" name="courriel" autocomplete="email" required>
             type="submit">Confirmer ma place>
          >
        >
      >
    >

    >
      <h3>Informations pratiques</h3>
      >Samedi 18 octobre, de 14 h à 17 h, salle 2. Entrée gratuite sur inscription.>
    >
  >

  >
    >© 2026 Médiathèque des Lilas —  href="mentions.html">Mentions légales>>
  >
>
>
```

Chaque région de ce fichier correspond à une décision précise, et il est utile de les reprendre une dernière fois. L'en-tête technique porte le titre de l'onglet, la description destinée aux moteurs de recherche, l'encodage et la mise à l'échelle mobile : quatre lignes qui coûtent peu et se vérifient d'un coup d'œil. Le bandeau contient un logo décrit et le titre principal de la page, seul `h1` du document. La navigation, délimitée et étiquetée, contient un lien relatif vers l'accueil du site et deux liens d'ancre vers les sections de la même page : c'est la combinaison exacte des deux types de liens vus dans le chapitre. Le contenu principal enferme un article autonome, lui-même découpé en deux sections titrées, et l'encart latéral porte les informations pratiques que l'on peut retirer sans que la page perde son sens.

Voici enfin la liste de contrôle à exécuter avant de considérer votre page comme terminée. Ouvrez le code source et vérifiez la déclaration de type, la langue de la racine, l'encodage et le titre de l'onglet. Parcourez la page au clavier et confirmez que chaque zone est atteignable dans l'ordre. Demandez au navigateur d'afficher la structure : un seul `h1`, aucun niveau de titre sauté, chaque section annoncée. Désactivez temporairement le chargement des images, ou imaginez-le : le texte de remplacement doit suffire à comprendre la page. Relisez enfin vos libellés de liens et vos étiquettes de champs, hors contexte, un à un : s'ils se comprennent seuls, votre page est prête à être partagée.

- Assemblez dans un seul fichier toutes les notions du chapitre, puis modifiez-les une par une.
- Vérifiez l'en-tête technique : type, langue, encodage, titre, description.
- Comptez les titres : un seul `h1` et aucun niveau sauté.
- Testez la page au clavier et, si possible, avec un lecteur d'écran.
- Lisez chaque libellé et chaque étiquette isolément, hors de la page.
- Travaillez d'abord sur le sens, laissez le style au chapitre suivant.
$lesson$),
  ('web-c1-p13', 'web-c1', 13, $lesson$À retenir$lesson$, $lesson$
- Le HTML décrit la structure et le sens ; le CSS l'apparence et le JavaScript le comportement.
- Une page commence par la déclaration `!DOCTYPE html`, puis par la balise racine portant `lang`.
- L'en-tête technique décrit la page, le corps contient tout le contenu visible.
- Les régions sémantiques sont `header`, `nav`, `main`, `section`, `article`, `aside` et `footer`.
- Une seule balise `main` par page, fille directe du corps du document.
- La hiérarchie de titres va de `h1` à `h6` sans saut de niveau et avec un seul `h1`.
- Le navigateur ignore les espaces et retours à la ligne du source, sauf dans `pre`.
- `ol` pour l'ordre qui a du sens, `ul` pour l'ensemble indifférencié, `li` pour chaque entrée.
- `strong` et `em` marquent un rôle ; `b` et `i` ne marquent que l'apparence.
- Chaque image porte un attribut `alt` : descriptif si elle informe, vide si elle décore.
- `figure` et `figcaption` associent une illustration à sa légende visible.
- Un lien a un libellé qui se comprend hors contexte et un chemin relatif pour le site.
- Les identifiants sont uniques : ils servent d'ancres et d'étiquettes de formulaire.
- Un champ a toujours une étiquette associée par `for` et `id`, jamais le seul placeholder.
- Un tableau de données utilise `caption`, `th` et `scope`, et ne sert jamais de mise en page.
- `lang`, `id`, `class` et `data-` sont des attributs globaux : déclarer, repérer, grouper, configurer.
$lesson$),
  ('web-c1-p14', 'web-c1', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : empiler des div génériques en se disant que le style suffira → Correction : remplacez-les par `header`, `nav`, `main`, `section`, `article`, `aside` ou `footer` selon le rôle.
- Piège : écrire plusieurs balises `h1` ou sauter de `h2` à `h4` pour la taille du texte → Correction : un seul `h1`, niveaux enchaînés, taille commandée par le CSS.
- Piège : oublier l'attribut `alt` sur une image → Correction : décrivez le contenu ou la fonction ; si l'image ne sert à rien, écrivez une description vide.
- Piège : utiliser le placeholder comme étiquette de champ → Correction : ajoutez une balise `label` dont l'attribut `for` reprend l'attribut `id` du champ.
- Piège : construire la mise en page avec des tableaux → Correction : le tableau est réservé aux données ; le placement relève du CSS.
- Piège : laisser un tableau sans `th` ni `scope` → Correction : les en-têtes de colonne et de ligne portent `th` avec `scope` valorisé col ou row.
- Piège : écrire des liens du type en savoir plus ou cliquez ici → Correction : nommez la destination, par exemple en savoir plus sur l'inscription à l'atelier.
- Piège : mélanger chemins relatifs et adresses absolues dans un même site → Correction : absolu pour le protocole et le domaine, relatif pour tout ce qui vit dans le projet.
- Piège : ne pas tester la page au clavier et découvrir un ordre de tabulation incohérent → Correction : débranchez la souris et parcourez la page avec la touche de tabulation.
- Piège : écrire du texte important dans une image de synthèse → Correction : écrivez ce texte en HTML et servez-vous de l'image pour l'illustrer.
$lesson$),
  ('web-c1-p15', 'web-c1', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La référence la plus pratique pour approfondir ce chapitre reste la documentation de Mozilla, qui décrit chaque élément avec des exemples concrets, des cas d'usage et des mises en garde d'accessibilité. Commencez par la page https://developer.mozilla.org/docs/Web/HTML, qui dresse l'inventaire des éléments et de leurs attributs, puis descendez vers les pages individuelles des balises que vous avez utilisées, notamment https://developer.mozilla.org/docs/Web/HTML/Element/form pour les formulaires et https://developer.mozilla.org/docs/Web/HTML/Element/table pour les tableaux. Ces pages évoluent avec les navigateurs et signalent systématiquement ce qui est obsolète : c'est l'endroit où vérifier un doute plutôt que de recopier un vieux snippet trouvé ailleurs.

Deux autres sources officielles complètent utilement la lecture. Le cours Learn HTML de web.dev, accessible à l'adresse https://web.dev/learn/html/, propose des leçons progressives avec des démonstrations interactives et un accent particulier sur les bonnes pratiques de rendu et de performance. Côté W3C, les tutoriels de l'initiative pour l'accessibilité du web, rassemblés sur https://www.w3.org/WAI/tutorials/, détaillent avec un soin pédagogique les formulaires, les images et les tableaux, exactement les trois domaines où les détails font la différence pour les personnes en situation de handicap. Prenez le temps de feuilleter ces ressources plutôt que de les lire d'un bout à l'autre : revenez-y au moment où une question précise se pose, et gardez-les en favori pour le jour où vous rédigerez votre premier vrai projet.
$lesson$),
  ('web-c1-p16', 'web-c1', 16, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
Vous avez maintenant les fondations : un document complet, décrit, structuré et navigable, capable de se lire au clavier comme à l'œil ou au lecteur d'écran. La suite logique est l'exercice pratique qui suit cette leçon : vous y récrirez seul la page d'événement de l'exemple guidé, sans regarder la solution, puis vous la corrigerez avec la liste de contrôle de la section précédente. C'est à ce moment-là que vous mesurerez ce que vous avez réellement retenu de la hiérarchie des titres, des chemins de liens et des associations d'étiquettes. Le quiz de quatre questions qui accompagne le chapitre vous permet en parallèle de vérifier les notions essentielles en quelques minutes.

Passé cet exercice, le parcours bascule sur la seconde grande technologie du web : le CSS, qui prend le relais pour habiller la structure que vous venez de bâtir. Vous verrez alors que bien nommer ses classes dans ce chapitre, choisir des balises stables et garder une hiérarchie claire rend la mise en forme infiniment plus simple, parce que le style vient se poser sur une ossature déjà lisible. Conservez donc ce fichier d'événement : vous le stylerez page entière au chapitre suivant, et le contraste entre la page brute d'aujourd'hui et sa version mise en forme sera la meilleure démonstration de la complémentarité entre les deux langages.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('web-c2-p1', 'web-c2', 1, $lesson$Le rôle du CSS et la cascade$lesson$, $lesson$
Bienvenue dans le second chapitre du parcours Développement web moderne, le chapitre où votre page cesse d'être un document brut pour devenir une page que l'on a envie de regarder. Le chapitre précédent vous a appris à décrire la structure d'un document : régions sémantiques, hiérarchie de titres, listes, images, liens, formulaires, tableaux. Tout cela forme une ossature parfaitement lisible par un navigateur, par un lecteur d'écran et par un moteur de recherche, mais une ossature encore uniforme, grise, alignée tout à gauche comme un manuscrit tapé à la machine. Ce second chapitre lui donne une apparence : des couleurs, des polices agréables, des espacements réguliers, des colonnes, des cartes, un menu disposé horizontalement, et surtout une mise en page qui tient debout aussi bien sur l'écran large d'un poste de travail que sur le téléphone d'un visiteur debout dans une file d'attente. Le langage qui accomplie tout cela s'appelle CSS, acronyme de Cascading Style Sheets, traduit en français par feuilles de style en cascade. Le mot cascade n'est pas un ornement de vocabulaire : il désigne le mécanisme par lequel le navigateur arbitre entre toutes les règles qui prétendent s'appliquer à un même élément, et comprendre ce mécanisme, c'est comprendre pour de bon pourquoi votre style se joue là où vous l'attendiez, et parfois ailleurs.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées dans du vrai code. Vous comprendrez le rôle exact du CSS, la manière dont le navigateur arbitre entre plusieurs règles concurrentes et la part que l'héritage joue dans ce calcul. Vous écrirez du CSS dans ses trois formes possibles, en sachant pourquoi l'une d'elles domine les deux autres. Vous maîtriserez les sélecteurs, depuis le sélecteur de type le plus simple jusqu'aux pseudo-classes et à la spécificité chiffrée. Vous modelerez la boîte qui contient chaque élément : marges, bordures, espacements intérieurs, dimensions. Vous composerez ensuite une mise en page avec flexbox, puis avec grid, deux modes de pensée différents pour deux familles de besoins. Vous créerez un thème complet avec les variables CSS, vous adapterez l'affichage aux petits écrans avec des media queries et la fonction clamp, vous fabriquerez des composants réutilisables, et vous vérifierez le contraste, le focus clavier et le respect des préférences de mouvement réduit. Le tout sera assemblé dans un mini-projet guidé : habiller page entière le fichier atelier.html que vous avez écrit au chapitre précédent.

Le fil rouge du chapitre est donc celui-là même que vous connaissez déjà : l'atelier de la Médiathèque des Lilas. Au chapitre précédent, vous avez produit la page atelier.html, squelette sémantique complet mais visuellement nu. Nous allons la reprendre telle qu'elle est, sans toucher à une seule balise, et lui appliquer une feuille de style. Ce choix n'est pas pratique : il illustre la promesse centrale de la séparation des responsabilités. Le contenu reste exactement le même, le sens ne bouge pas, l'accessibilité structurelle est conservée, et pourtant la page va changer de visage. Vous pourrez aller plus loin encore : désactiver la feuille de style dans votre navigateur et voir la page redevenir instantanément le document du chapitre précédent. Cette expérience, à faire une fois, explique mieux que tout discours pourquoi l'on sépare le contenu du style.

Une recommandation sur la manière d'aborder ce chapitre, avant d'entrer dans le vif du sujet. Le CSS s'apprend comme on apprend à peindre : en mettant la main à la pâte, en se trompant, en regardant ce que la couleur du geste précédent a changé. Rien ne remplace le fait de recopier chaque exemple dans un fichier, de l'enregistrer avec l'extension .css ou de l'insérer dans une balise style, d'ouvrir la page dans le navigateur et d'observer le rendu. Modifiez ensuite une valeur, changez un sélecteur, supprimez un point-virgule : l'observation des conséquences est ce que vous fixerez le plus durablement en mémoire. Un rendu bancale n'est pas un échec, c'est une information. Nous avancerons par étapes, en alternant explications détaillées, schémas en texte, exemples de code commentés et bonnes pratiques issues du développement professionnel.



Le CSS est un langage de déclarations, et non un langage de programmation. Il ne calcule rien, il ne décide de rien, il ne se répète pas : il décrit un état visuel que le navigateur se charge de produire. Concrètement, un fichier CSS est une suite de règles. Chaque règle associe un sélecteur, c'est-à-dire un motif décrivant quels éléments viser, à un bloc de déclarations qui donne les propriétés à changer. Une propriété est un nom connu du navigateur, comme la couleur du texte ou la marge extérieure ; sa valeur est ce que vous lui assignez. Le navigateur lit la feuille de style, associe chaque règle aux éléments correspondants, calcule pour chacun un style effectif, puis dessine. Aucune de ces étapes n'est visible pour l'utilisateur : il ne voit que le résultat, ce qui explique pourquoi une simple virgule mal placée peut suffire à faire disparaître tout un bloc de styles.

```css
/* Une règle : un sélecteur, puis un bloc de déclarations entre accolades */
p {
  color: #1f2937;
  line-height: 1.6;
}

/* Plusieurs sélecteurs séparés par des virgules partagent le même bloc */
.carte h2,
.titre-de-section {
  color: #0f766e;
  margin-block-end: 0.5rem;
}

/* Chaque déclaration est un couple propriété : valeur, terminé par un point-virgule */
.bandeau {
  background-color: #f5f5f4;
  padding: 1.5rem;
  border-radius: 0.5rem;
}
```

La cascade est la règle d'or du navigateur face à une situation fréquente : plusieurs règles visent le même élément et se contredisent. Une règle vient du navigateur lui-même, une autre de votre feuille de style, une troisième d'une extension installée par l'utilisateur, une quatrième s'applique seulement quand la souris survole l'élément. Il faut bien choisir. Le navigateur tranche selon un ordre précis qu'il est utile de connaître par cœur, car il explique la majorité des surprises. En premier vient l'origine et l'importance : les styles du navigateur passent avant les vôtres, vos styles passent avant ceux de l'utilisateur, et une déclaration marquée comme importante renverse temporairement cet ordre. En second vient la spécificité, qui mesure à quel point un sélecteur vise précisément. En troisième, à spécificité égale, l'ordre dans le fichier : la dernière règle écrite gagne.

La spécificité se chiffre, et ce chiffre se lit comme un triplet. Un sélecteur d'identifiant l'emporte sur un sélecteur de classe, qui l'emporte sur un sélecteur de type. Concrètement, le navigateur compte trois composantes : le nombre d'identifiants dans le sélecteur, le nombre de classes, d'attributs et de pseudo-classes, puis le nombre de types d'éléments et de pseudo-éléments. Le triplet obtenu se compare de gauche à droite : la première composante non nulle décide. Ainsi, un sélecteur unique en tête de fichier écrase souvent une règle soigneusement rédigée plus bas, sans que la lecture du fichier ne le suggère. C'est la première raison pour laquelle il faut écrire des sélecteurs de classe modestes et éviter d'accumuler des identifiants dans vos règles.

L'héritage est le complément qui rend le tout praticable. Certaines propriétés se transmettent automatiquement du parent à l'enfant : la couleur du texte, la famille de police, la taille, l'interligne, la direction d'écriture. Vous pouvez donc fixer la couleur du corps du document une seule fois et voir tous les paragraphes, listes et liens non colorés explicitement en hériter. D'autres propriétés ne s'héritent pas du tout : les marges, les bordures, les dimensions, les fonds. Elles décrivent la boîte elle-même, et une boîte enfant n'a aucune raison de reprendre celle de son parent. Pour forcer le comportement, trois mots suffisent : hériter, valeur initiale, ou annulation locale, écrits en anglais dans le code. Retenez surtout le principe : l'héritage rend le style compact, la non-héritée rend la mise en page prévisible.

- Le HTML décrit le sens, le CSS décrit l'apparence, le JavaScript décrit le comportement.
- Une règle CSS associe un sélecteur à un bloc de déclarations entre accolades.
- La cascade tranche dans l'ordre : origine et importance, puis spécificité, puis ordre du fichier.
- La spécificité se chiffre en trois composantes : identifiants, classes, types.
- Une déclaration importante renverse la cascade : à réserver aux recours extrêmes.
- Les propriétés de texte s'héritent ; les propriétés de boîte ne s'héritent pas.
- Une seule feuille de style peut habiller cent pages : c'est le gain de la séparation.
$lesson$),
  ('web-c2-p2', 'web-c2', 2, $lesson$Écrire du CSS : fichier externe, balise style, attribut style$lesson$, $lesson$
Il existe exactement trois endroits où écrire du CSS dans un projet web, et ils ne se valent pas. Le premier est un fichier à part, portant l'extension .css, relié à la page par une balise link placée dans l'en-tête technique. Le deuxième est une balise style insérée elle aussi dans l'en-tête technique, qui contient les règles directement. Le troisième est l'attribut style posé sur une balise du corps du document. Ces trois formes produisent le même résultat visuel, mais elles diffèrent par leur portée, leur réutilisation et leur coût de maintenance, et le choix entre elles est l'un des premiers arbitrages d'un développeur.

Le fichier externe est la forme dominante, et de loin. On écrit les règles dans un fichier nommé avec soin, par exemple atelier.css ou styles/theme.css, puis on le relie avec la balise link dont les deux attributs essentiels sont rel, qui vaut stylesheet, et href, qui donne le chemin du fichier. La syntaxe des chemins est exactement celle des liens HTML du chapitre précédent : un nom seul pour un fichier voisin, un chemin avec barre oblique pour descendre dans un sous-dossier, deux points pour remonter. Les avantages sont immédiats. Le fichier est mis en cache par le navigateur après le premier chargement, donc les pages suivantes le récupèrent sans le retélécharger. Il est partagé par toutes les pages du site, donc une correction de couleur s'applique partout d'un coup. Il est édité avec coloration syntaxique CSS, ce qui rend les erreurs bien plus visibles. Enfin, il matérialise la séparation des responsabilités dans l'arborescence du projet : le contenu dans un dossier, la présentation dans un autre.

```html
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Atelier HTML du samedi — Médiathèque des Lilas</title>
  <link rel="stylesheet" href="styles/atelier.css">
</head>
```

La balise style trouve sa place dans des cas plus restreints : une page destinée au courrier électronique, où un fichier externe n'est pas référençable, un fichier unique déposé sur une clé, ou un prototype que l'on teste rapidement. Dès que le projet grandit, ses inconvénients apparaissent : les règles ne se mettent pas en cache à part, elles se mélangent au balisage, et retrouver une couleur dans cent pages revient à relire cent pages. Placez-la toujours dans l'en-tête technique, après le titre : le navigateur l'interprète alors avant de dessiner le corps, et l'utilisateur n'assiste pas à une page qui se teinte ligne à ligne.

```html
<head>
  <title>Atelier du samedi</title>
  <style>
    :root {
      --encre: #1f2937;
      --accent: #0f766e;
    }
    body {
      font-family: system-ui, sans-serif;
      color: var(--encre);
      max-width: 60rem;
      margin-inline: auto;
      padding: 1rem;
    }
  </style>
</head>
```

L'attribut style constitue la troisième forme, et il faut l'aborder avec méfiance. Il ne concerne que l'élément qu'il habille, il ne se réutilise nulle part ailleurs, et sa spécificité est si haute qu'il écrase presque tout le reste de la feuille de style. Son usage professionnel se limite aux valeurs calculées à l'exécution, comme la largeur d'une barre de progression que le script ajuste ; pour tout le reste, il y a une classe.

```html
<!-- À éviter : la règle vaut pour ce paragraphe, et pour aucun autre -->
<p style="color: #b91c1c; font-weight: 600;">Complet : dernière session sold out.</p>

<!-- Acceptable : une valeur que le script mettra à jour -->
<div role="progressbar" aria-valuenow="65" style="width: 65%;"></div>
```

Quelle que soit la forme retenue, la syntaxe reste identique et mérite d'être fixée dès maintenant. Les déclarations s'écrivent entre accolades, séparées par des points-virgules ; le point-virgule de la dernière déclaration est facultatif mais recommandé, car il transforme toute erreur de syntaxe suivante en erreur bénigne. Le navigateur ignore les espaces, les tabulations et les retours à la ligne : vous pouvez formater votre code comme vous le souhaitez sans changer un pixel du rendu. Les commentaires, eux, s'ouvrent avec une accolade ouvrante précédée d'un oblique et se ferment avec l'inverse ; ils sont destinés à l'humain qui relira le fichier et ils n'apparaissent jamais à l'écran. Une convention simple vaut pour tout le chapitre : une déclaration par ligne, deux espaces d'indentation, une ligne vide entre deux règles.

- Le fichier externe relié par la balise link domine : cache, réutilisation, séparation.
- L'attribut rel vaut stylesheet et l'attribut href donne le chemin, comme pour les liens.
- La balise style reste réservée au courrier électronique, au fichier unique et au prototype.
- L'attribut style n'est à l'aise que pour les valeurs calculées par un script.
- Une déclaration par ligne, des point-virgules complets, des commentaires pour le lecteur.
- Les erreurs de CSS sont silencieuses : l'inspecteur d'éléments les révèle en une seconde.
$lesson$),
  ('web-c2-p3', 'web-c2', 3, $lesson$Sélecteurs et spécificité$lesson$, $lesson$
Un sélecteur est un motif : il décrit quels éléments une règle doit concerner. Le navigateur construit l'arbre de la page, parcourt chaque élément et applique les règles dont le sélecteur correspond. Ce lien entre motif et arbre est la clé de tout le chapitre, parce que la puissance du CSS vient moins de l'inventaire des propriétés que de la précision avec laquelle vous ciblez les éléments. Un mauvais sélecteur n'ignore pas seulement un élément : il en déborde sur d'autres et déteint là où vous ne le vouliez pas. Le choix du sélecteur est donc un choix de portée.

Le sélecteur le plus simple porte le nom d'une balise et vaut pour tous les éléments de ce type : écrire le nom du paragraphe vise tous les paragraphes du document. Vient ensuite le sélecteur de classe, précédé d'un point, qui vaut pour tous les éléments portant cette classe dans leur attribut class ; il est le cheval de bâtage du CSS, parce qu'une même classe peut être posée sur autant d'éléments qu'on veut et qu'il reste d'une faible spécificité. Le sélecteur d'identifiant, précédé d'un dièse, vise l'élément dont l'attribut id correspond ; il n'en existe qu'un exemplaire par page, sa spécificité est haute, et il convient aux cibles d'ancres et aux cas où une règle ne doit jamais viser qu'un seul exemplaire. Le sélecteur universel, une simple étoile, vise tous les éléments : il sert aux remises à zéro globales, jamais à la mise en forme d'un composant.

```css
/* Sélecteurs de base : type, classe, identifiant, universel */
p { text-align: justify; }
.carte { border: 1px solid #d6d3d1; padding: 1rem; }
#programme { scroll-margin-top: 5rem; }
* { box-sizing: border-box; }

/* Sélecteur d'attribut et combinateurs */
input[type="email"] { width: 100%; }
.carte h3 { margin-block-start: 0; }          /* descendant */
.carte > .titre { color: #0f766e; }           /* enfant direct */
.bouton + .bouton { margin-inline-start: 0.5rem; } /* suivant adjoint */
.sommaire ~ .contenu { padding-block-start: 1rem; } /* suivant quelconque */

/* Pseudo-classes et pseudo-éléments */
.bouton:hover { background-color: #115e59; }
.bouton:focus-visible { outline: 3px solid #f59e0b; }
.sommaire li:nth-child(even) { background-color: #f5f5f4; }
.prix::before { content: "À partir de "; color: #57534e; }
```

Les combinateurs élargissent la portée sans toucher au balisage. Un sélecteur d'attribut, lui, vise une valeur précise : le type d'un champ de saisie, l'extension d'un lien, ou la simple présence d'un attribut sans s'attacher à sa teneur. L'espace entre deux termes désigne les descendants, c'est-à-dire tous les éléments correspondants situés n'importe où à l'intérieur. La flèche supérieure désigne les enfants directs, un seul niveau de profondeur. Le signe plus désigne l'élément qui suit immédiatement, et deux signes désigne un frère suivant quelconque, à condition qu'ils partagent le même parent. Ces quatre outils couvrent la grande majorité des besoins, et leur intérêt est de laisser le HTML intact : vous hiérarchisez le style à l'aide de la structure que vous avez déjà écrite au chapitre précédent.

Les pseudo-classes décrivent un état, non un endroit. Les plus usitées sont le survol et la prise de focus au clavier ; d'autres décrivent la position dans l'arbre, comme le premier, le dernier ou un rang pair d'enfants ; d'autres encore expriment une négation, ce qui est commode pour viser tous les éléments qui ne portent pas une classe donnée. Le focus visible mérite une mention particulière : contrairement au focus simple, qui s'active aussi à la souris, il ne se déclenche que lorsqu'un utilisateur navigue au clavier, ce qui donne un indicateur pertinent sans troubler les autres.

Les pseudo-éléments, eux, n'existent pas dans le HTML : ils inventent une partie imaginaire de l'élément, sur laquelle vous pouvez écrire. Les deux plus utiles créent un contenu avant et après le texte réel, à partir de la propriété content. On les emploie pour une puce décorative, une étiquette de prix, un guillemet ouvrant un extrait, jamais pour placer une information indispensable, puisque ce texte n'appartient pas au document et n'est pas lu comme du contenu par les technologies d'assistance. D'autres pseudo-éléments ciblent la première ligne d'un paragraphe, la sélection à la souris ou le texte indicatif d'un champ.

La spécificité transforme ces choix en arithmétique. Chaque sélecteur se décompose en trois nombres : le premier compte les identifiants, le second les classes, attributs et pseudo-classes, le troisième les types d'éléments et pseudo-éléments. On compare le triplet de gauche à droite, et la première composante qui diffère tranche. Quand deux règles ont exactement le même triplet, c'est l'ordre dans le fichier qui décide : la dernière écrite l'emporte. Le tableau suivant donne les ordres de grandeur utiles à mémoriser, avec un calcul d'exemple pour chaque ligne.

```table
| Sélecteur | Identifiants | Classes | Types | Spécificité |
| --- | --- | --- | --- | --- |
| p | 0 | 0 | 1 | 0,0,1 |
| .carte | 0 | 1 | 0 | 0,1,0 |
| .carte .prix | 0 | 2 | 0 | 0,2,0 |
| #programme | 1 | 0 | 0 | 1,0,0 |
| .carte .prix strong | 0 | 2 | 1 | 0,2,1 |
| style en ligne sur la balise | 1 | 0 | 0 | au-dessus de tout |
```

Trois conséquences pratiques découlent de cette arithmétique. Premièrement, écrivez vos règles avec des sélecteurs de classe, parce qu'ils restent faibles et réutilisables : une règle difficile à surclasser devient impossible à corriger. Deuxièmement, gardez vos sélecteurs courts : un sélecteur de six termes est une règle qui ne sera jamais remplacée, seulement contredite. Troisièmement, quand deux règles se disputent un même élément, cherchez d'abord l'ordre du fichier avant d'augmenter la spécificité : réordonner coûte moins cher qu'empiler des identifiants. La méthode professionnelle consiste à écrire les règles générales en premier, les exceptions ensuite, de sorte que la cascade travaille pour vous.

- Un sélecteur de type vise une balise, un sélecteur de classe vise un rôle, un sélecteur d'identifiant vise un exemplaire.
- La classe est le cheval de bât du CSS : faible spécificité, réutilisation illimitée.
- Les combinateurs décrivent descendant, enfant direct, suivant adjoint et suivant quelconque.
- Les pseudo-classes décrivent un état ou une position ; les pseudo-éléments inventent une partie imaginaire.
- La spécificité se compare en trois composantes, puis par ordre d'apparition.
- Un sélecteur long se surclasse rarement bien : préférez réordonner plutôt qu'empiler.
- Le focus visible se limite au clavier : n'adoptez pas un état qui gêne la souris.
$lesson$),
  ('web-c2-p4', 'web-c2', 4, $lesson$Le modèle de boîte$lesson$, $lesson$
Avant de composer une mise en page, il faut comprendre ce que l'on déplace. Tout élément rendu par le navigateur occupe un rectangle, appelé boîte, et ce rectangle est composé de quatre couches concentriques que la spécification nomme le modèle de boîte. Du centre vers l'extérieur : le contenu, qui reçoit le texte ou l'image ; l'espacement intérieur, qui pousse le contenu vers l'intérieur en gardant le fond visible ; la bordure, qui dessine le contour ; enfin la marge extérieure, qui écarte la boîte de ses voisines et reste transparente. Ces quatre couches se règlent séparément, et la majorité des mises en page bancales viennent d'une confusion entre elles : on augmente l'espacement intérieur quand il fallait de la marge, ou l'inverse, et les décalages s'accumulent.

Le schéma suivant résume le modèle. Chaque ligne représente une frontière, et la flèche des commentaires indique la couche correspondante. Observez que la marge est la seule couche qui ne possède pas de fond : elle ne fait qu'éloigner, alors que l'espacement intérieur et la bordure appartiennent à la boîte et se colorent avec elle.

```text
+------------------------------------------+  <- marge extérieure (transparente)
|  +------------------------------------+  |  <- bordure (contour coloré)
|  |  +--------------------------------+  |  |  <- espacement intérieur
|  |  |                                |  |  |
|  |  |        contenu du texte        |  |  |  <- largeur et hauteur
|  |  |                                |  |  |
|  |  +--------------------------------+  |  |
|  +------------------------------------+  |
+------------------------------------------+
```

La propriété de dimensionnement décide de ce que mesure la largeur. Par défaut, elle mesure le contenu seul : ajouter quatre pixels d'espacement intérieur et deux pixels de bordure à un élément de largeur cent pixels donne un rectangle total de cent douze pixels, ce qui déborde invariablement de sa colonne. L'alternative, universellement adoptée, consiste à déclarer que la largeur demandée inclut espacement et bordure ; la boîte reste alors exactement large comme annoncé, et le contenu se retrousse à l'intérieur. Cette déclaration se place une seule fois, en tête de fichier, sur le sélecteur universel, et ne se remet plus en question. Tous les exemples du chapitre supposent qu'elle est en place.

```css
/* En tête de fichier : la largeur annoncée comprend tout */
*,
*::before,
*::after {
  box-sizing: border-box;
}

.carte {
  width: 20rem;
  padding: 1.25rem;
  border: 1px solid #d6d3d1;
  margin-block-end: 1.5rem;
  /* total réel : toujours 20 rem de large */
}

.encart {
  margin-inline: auto;   /* centre horizontalement dans son conteneur */
  max-width: 60rem;      /* ne s'étire jamais au-delà */
  overflow-wrap: break-word;
}
```

Les marges obéissent à deux comportements qu'il faut connaître avant toute mise en page verticale. Le premier est leur annulation : deux marges verticales voisines ne s'additionnent pas, elles fusionnent en la plus grande des deux. Un titre suivi d'un paragraphe n'accumule donc pas leurs marges, ce qui évite les trous ridicules ; mais cette fusion disparaît dès que les éléments sont disposés côte à côte, et disparaît aussi dès qu'un bordure ou un espacement intérieur sépare les deux boîtes. Le second comportement est le centrage horizontal : une boîte de largeur définie, à marges extérieures automatiques de part et d'autre, se place au milieu de sa colonne. Ce raccourci reste le plus court moyen de centrer un bloc, et il fonctionne dès le premier navigateur.

Les dimensions se déclarent avec des propriétés complémentaires plutôt que par une seule valeur. On fixe une largeur pour la boîte, puis une largeur minimale et maximale pour encadrer son comportement ; on laisse la hauteur libre le plus souvent, car le contenu la décide, et on ne la fige que pour les boîtes dont le contenu doit être aligné, comme les cartes d'une même rangée. La propriété de rapport de forme permet enfin d'imposer un ratio, par exemple quatre sur trois, sans jamais calculer de hauteur à la main : c'est la solution moderne pour les vignettes d'images et les zones de lecture vidéo. La propriété d'environnement, celle qui décide que faire quand le contenu dépasse, accepte quatre réponses : laisser déborder, rogner, ajouter une barre de défilement ou afficher un débordement en deux dimensions. Pour un conteneur de mise en page, rogner est rarement la bonne réponse, car un texte coupé est un texte perdu.

La propriété de disposition, enfin, décide du type de boîte, et deux valeurs suffisent pour la quasi-totalité des cas. En bloc, un élément occupe toute la largeur disponible et passe à la ligne suivante : titres, paragraphes, conteneurs de section. En ligne, il se glisse dans le flux du texte sans jamais forcer de retour : liens, mots en gras, étiquettes. Une valeur supplémentaire supprime la boîte de l'affichage, y compris pour les technologies d'assistance ; pour masquer un contenu en le gardant lisible par un lecteur d'écran, on préfère la propriété de visibilité, dont la valeur masquée fait exactement cela.

- Tout élément est une boîte : contenu, espacement intérieur, bordure, marge.
- Déclarez le mode de dimensionnement à la bordure une fois pour toutes, en tête de fichier.
- Les marges verticales voisines fusionnent ; les marges automatiques centrent un bloc.
- Fixez une largeur, encadrez-la avec un minimum et un maximum, laissez la hauteur suivre le contenu.
- Réservez le rognage au décor, jamais au texte qu'un utilisateur doit lire.
- Un élément en bloc occupe la ligne, un élément en ligne s'y glisse.
$lesson$),
  ('web-c2-p5', 'web-c2', 5, $lesson$Flexbox$lesson$, $lesson$
La boîte de base est seule dans sa ligne. Le vrai travail commence quand plusieurs boîtes doivent se répartir dans une même direction, et la première famille d'outils pour cela est celle de la disposition flexible, dite flexbox. Son principe tient en une phrase : vous désignez un élément comme conteneur flexible, et ses enfants directs deviennent des objets flexibles que le conteneur répartit selon des règles que vous écrivez. Concrètement, il suffit d'ajouter une propriété de disposition au parent ; aucun enfant ne change de nom, aucune balise n'est ajoutée, et le HTML reste intact. C'est l'illustration la plus nette de la séparation entre le sens et l'apparence.

La disposition flexible travaille sur une seule dimension à la fois, celle que la spécification appelle l'axe principal. L'axe perpendiculaire est l'axe transversal. Le choix de l'axe principal se fait avec une propriété de direction, dont la valeur par défaut dispose les enfants de gauche à droite ; la valeur inverse inverse le sens, et les valeurs de colonne empilent les enfants de haut en bas, l'axe principal devenant vertical. Ce vocabulaire est essentiel, car toutes les propriétés qui suivent s'y réfèrent : l'une répartit le long de l'axe principal, l'autre le long de l'axe transversal. Se tromper d'axe est l'erreur la plus fréquente chez le débutant, et elle se diagnostique en une question : est-ce que j'essaie d'aligner dans le sens de la pile ou perpendiculairement à elle ?

```text
     axe principal  (justify-content : la répartition)
  <---------------------------------------------->
  +--------+  +--------+  +--------+  +--------+
  |  un    |  |  deux  |  | trois  |  | quatre |
  +--------+  +--------+  +--------+  +--------+
  ^
  axe transversal (align-items : l'alignement)
```

Les deux propriétés de répartition se retiennent en pair. Celle de l'axe principal décide comment l'espace excédentaire se partage entre les éléments : au début, à la fin, centré, avec des éléments répartis en parts égales ou espacés régulièrement, y compris au voisinage des bords. Celle de l'axe transversal décide comment chaque élément se place dans la bande dont il dispose : collé au haut, centré, à la basse, ou étiré sur toute la hauteur. L'alignement sur toute la hauteur est particulièrement utile pour des cartes de hauteurs différentes : chaque carte remplit sa bande et les bordures inférieures s'alignent. L'espacement entre éléments, enfin, se déclare une fois sur le conteneur plutôt que par des marges sur chacun, ce qui évite la marge parasite au premier et au dernier enfant.

```css
.navigation ul {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
  padding: 0;
  margin: 0;
  list-style: none;
}

.grille-de-carte {
  display: flex;
  flex-wrap: wrap;
  gap: 1.25rem;
}
.grille-de-carte > .carte {
  flex: 1 1 18rem;      /* pousse, se rétracte, base : 18 rem */
  min-width: 0;
}
```

La propriété d'enroulement décide ce qui arrive quand les éléments dépassent la largeur du conteneur. Par défaut, ils se compriment ; déclaré, le conteneur passe à la ligne et dessine une nouvelle bande, à la manière d'un paragraphe de mots. Cette propriété transforme une rangée de cartes en une grille qui s'adapte naturellement à la largeur disponible, sans aucune media query. Elle s'accompagne de deux réglages d'alignement des bandes, qui traitent chaque bande comme un conteneur secondaire. Attention à une subtilité : l'ordre des enfants suit le document, et une carte passée à la ligne suivante se cale à gauche de sa bande, pas forcément sous la colonne où elle se trouverait si tout tenait.

Les propriétés de chaque enfant complètent le dispositif. Elles se résument en trois valeurs, souvent écrites en une seule. La première dit à quel point l'élément peut grandir pour occuper l'espace disponible ; la seconde dit à quel point il peut se rétracter avant de déborder ; la troisième donne la taille de départ à partir de laquelle ces deux calculs partent. Une valeur de grandir égale à zéro fige la taille, pratique pour un logo ; une valeur élevée absorbe tout l'espace excédentaire, pratique pour une zone de contenu face à un encart fixe. S'y ajoutent l'alignement individuel, qui surcharge l'alignement du conteneur pour un seul enfant, et la propriété d'ordre, qui modifie la position visuelle sans changer le document : elle doit rester exceptionnelle, car elle crée un écart entre l'ordre de lecture au clavier et l'ordre à l'écran.

Trois patrons suffisent à 90 % des besoins et méritent d'être mémorisés tels quels. Le menu horizontal : conteneur flexible, alignement centré, espacement automatique, enroulement autorisé. La carte à pied poussé : conteneur flexible en colonne, zone de contenu qui grandit, pied collé en bas. Le centrage parfait : conteneur flexible, les deux alignements centrés, et rien d'autre. Ce dernier cas remplace avantageusement les anciens raccourcis de centrage, qui exigeaient des transformations et des calculs de décalage. Notez au passage que flexbox centre aussi verticalement une boîte dans la fenêtre elle-même, ce qui suffit pour un écran de connexion ou une fenêtre de dialogue.

La flexbox a des limites, et les connaître évite les contorsions. Elle ne dessine pas de vraies colonnes : deux éléments côte à côte ne savent pas que le troisième, en dessous, doit s'aligner sur les mêmes bords. Elle ne place pas non plus un élément à une intersection précise d'une grille de lignes et de colonnes. Dès que vous avez besoin de deux dimensions à la fois, c'est-à-dire d'aligner simultanément des rangées et des colonnes, la famille d'outils suivante prend le relais. La règle empirique tient en une phrase : flexbox répartit dans une direction, grid organise dans deux.

- Le conteneur flexible travaille sur un axe principal et un axe transversal.
- La direction se choisit sur le conteneur ; les enfants ne changent rien.
- Répartir se fait avec la propriété de l'axe principal, aligner avec celle de l'axe transversal.
- L'espacement entre éléments se déclare sur le conteneur, pas par des marges individuelles.
- L'enroulement transforme une rangée en bandes adaptatives, sans media query.
- Trois valeurs par enfant commandent grandir, rétrécir et taille de départ.
- Deux dimensions à la fois : passez à la grille.
$lesson$),
  ('web-c2-p6', 'web-c2', 6, $lesson$Grid$lesson$, $lesson$
La disposition en grille est l'outil natif pour ce que le HTML ne savait pas faire pendant vingt ans : positionner simultanément des lignes et des colonnes. Son fonctionnement rappelle celui de la flexbox, avec une différence décisive. Vous déclarez sur le conteneur le nombre et la nature des colonnes, éventuellement des lignes, puis chaque enfant se place dans une cellule que vous désignez. Là où la flexbox répartit des objets le long d'un axe, la grille dessine un repère dans lequel ces objets se logent. Ce repère existe même quand une cellule est vide, et c'est précisément ce qui permet d'aligner un contenu de la première colonne avec un contenu de la quatrième ligne de rangée suivante.

La déclaration de base se limite à donner des colonnes. Chaque entrée décrit une piste, et les unités les plus utiles sont l'unité de fraction, qui représente une part de l'espace disponible après réservation des pistes fixes, la longueur, pour une taille constante, et le mot automatique, qui prend exactement la taille de son contenu. Plusieurs pistes de même nature s'écrivent en une seule instruction avec une fonction de répétition. L'espacement entre les cellules se règle par la propriété d'écartement, comme en flexbox, et il s'applique aux lignes comme aux colonnes à la fois.

```css
.agenda {
  display: grid;
  grid-template-columns: 1fr 3fr;
  gap: 1.5rem;
}

.programme {
  display: grid;
  grid-template-columns: repeat(3, minmax(12rem, 1fr));
  grid-auto-rows: minmax(8rem, auto);
  gap: 1rem;
}
```

```text
   colonne 1 (1fr)      colonne 2 (3fr)
+-----------------+---------------------------+
|   en-tête       |        en-tête            |  ligne 1 : auto
+-----------------+---------------------------+
|   navigation    |                           |
+-----------------+        contenu            |  ligne 2 : 1fr
|   encart        |                           |
+-----------------+---------------------------+
|   pied de page  |        pied de page       |  ligne 3 : auto
+-----------------+---------------------------+
```

Le placement des enfants s'exprime avec des plages de lignes et de colonnes. Sans indication, les éléments suivent l'ordre du document et remplissent les cellules une à une, colonne après colonne ou ligne après ligne selon le sens de flux choisi. Pour placer un élément explicitement, on donne sa ligne de départ puis sa ligne de fin ; la valeur qui signifie la piste suivante économie l'écriture. Un élément peut couvrir plusieurs colonnes, par exemple un titre sur toute la largeur puis deux cartes côte à côte. Les numéros de lignes comptent à partir de un et se terminent par une ligne ajoutée après la dernière piste implicite : garder cette numérotation en tête évite la moitié des décalages observés au début.

La fonction qui prend la taille minimale et maximale d'une piste est la clé des grilles fluides. Elle autorise une colonne à rétrécir jusqu'à une limite, puis à cesser de rétrécir, ce qui empêche le contenu d'être écrasé sur un écran étroit. Combinée avec le mot qui signifie adapter au nombre de places disponibles, elle produit en trois mots une rangée de cartes qui passe de quatre colonnes sur un poste large à une seule colonne sur un téléphone, sans une seule media query. La variante qui force au moins une piste se distingue de la précédente par un détail : la seconde préfère créer une colonne supplémentaire vide plutôt que d'étirer les cartes au-delà d'une taille raisonnable. Dans la pratique, la première convient aux cartes, la seconde aux compositions décoratives.

```css
/* Rangée de cartes fluide : quatre colonnes, deux, puis une */
.carte-grille {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 16rem), 1fr));
  gap: 1.25rem;
}

/* Placement explicite : bandeau pleine largeur, puis deux colonnes */
.page {
  display: grid;
  grid-template-columns: minmax(12rem, 1fr) minmax(0, 3fr);
  grid-template-areas:
    "entete  entete"
    "menu    contenu"
    "pied    pied";
  gap: 1rem 2rem;
}
.entete  { grid-area: entete; }
.menu    { grid-area: menu; }
.contenu { grid-area: contenu; }
.pied    { grid-area: pied; }
```

La nomination de zone est la déclaration la plus lisible de tout le chapitre. Plutôt que de manipuler des numéros de lignes, on donne un nom à chaque région, on écrit le plan de la page sous forme de mots entre guillemets, et chaque enfant déclare simplement le nom de sa région. Le bloc de déclarations devient un plan de bâtiment : on voit la composition entière sans calculer quoi que ce soit. Changer l'encart de gauche à droite consiste alors à permuter deux mots dans le plan, pas à reprendre une dizaine de règles. C'est exactement la structure qui convient à la page d'atelier : un bandeau en haut, une navigation à gauche, le contenu à droite, un pied de page en bas.

Pour choisir entre les deux familles, un raisonnement simple suffit. Si votre besoin se formule en une phrase contenant deux directions, un alignement de rangées et un alignement de colonnes, la grille est l'outil juste. Si votre besoin se formule en une seule direction, une liste de liens à disposition horizontale, un pied de carte poussé en bas, un texte centré, la flexbox est plus courte. Les deux se mélangent sans aucun problème, et la combinaison la plus courante consiste à poser une grille pour la structure de page, puis à disposer en flexbox les éléments à l'intérieur de chaque cellule. C'est cette combinaison que vous écrirez dans le mini-projet.

- La grille dessine un repère de lignes et de colonnes, la flexbox répartit sur un axe.
- L'unité de fraction répartit l'espace restant, le mot automatique prend la taille du contenu.
- minmax limite une piste entre une taille minimale et maximale, et rend la grille résistante.
- auto-fit avec une piste minimale produit une rangée de cartes fluide, sans media query.
- Le plan de zones nommées décrit la page en mots et rend les réglages immédiats.
- Une cellule aligne son contenu, elle ne dilate pas la colonne.
- Grille pour deux dimensions, flexbox pour une seule, les deux à l'intérieur l'une de l'autre.
$lesson$),
  ('web-c2-p7', 'web-c2', 7, $lesson$Variables CSS et thème$lesson$, $lesson$
Les variables CSS, officiellement appelées propriétés personnalisées, sont l'innovation qui a rendu le langage enfin paramétrable. Pendant vingt ans, un style écrit une fois se répétait : la même couleur de rappel apparaissait dans quarante règles, et en changer exigeait quarante corrections. Les variables suppriment ce travail : on déclare une valeur une fois, sous un nom que l'on choisit, puis on la référence partout où elle est nécessaire. Le navigateur remplace les références au moment de calculer le style effectif, ce qui signifie qu'une seule modification en tête de fichier rejaillit sur la page entière.

La déclaration se compose de deux pièces. Le nom commence toujours par deux traits d'union, suivi d'un nom libre en minuscules ; il se place à l'intérieur d'un bloc de déclarations, exactement comme une propriété ordinaire. La lecture, elle, prend la forme d'une fonction qui reçoit le nom, et s'emploie à la place d'une valeur. Les deux opérations se distinguent par les deux traits d'union pour l'une, les deux traits d'union à nouveau pour l'autre, et c'est là que se loge l'essentiel de la pratique : on déclare dans un bloc, on lit dans une valeur. La fonction admet un argument facultatif de secours, appliqué si le nom n'est pas défini, ce qui protège des erreurs de nommage sans casser le rendu.

```css
:root {
  --encre: #1c1917;
  --fond: #ffffff;
  --fond-doux: #f5f5f4;
  --accent: #0f766e;
  --accent-fonce: #115e59;
  --trait: #d6d3d1;
  --rayon: 0.5rem;
  --espace: 1.25rem;
  --mesure: 62rem;
}

body {
  background-color: var(--fond);
  color: var(--encre);
}

.titre-section {
  color: var(--accent);
  border-block-end: 2px solid var(--accent);
  padding-block-end: calc(var(--espace) / 2);
}

.bouton-principal {
  background-color: var(--accent, #0f766e);
  color: var(--fond);
  border-radius: var(--rayon);
}
```

L'endroit naturel de la déclaration est le sélecteur racine, celui qui désigne l'élément racine du document, donc la balise qui porte tout le reste. Toutes les variables qui y sont déclarées sont visibles partout dans la page, parce que les propriétés personnalisées héritent, comme la couleur du texte. Cette héritance est une arme à double tranchant : elle permet de redéfinir une variable sur une sous-arborescence entière, par exemple dans un encart sombre ou dans un formulaire, et de voir tous les descendants changer de palette sans écrire une règle supplémentaire. Elle explique aussi pourquoi une variable mal placée se propage là où on ne l'attendait pas.

Cette capacité de redéfinition est précisément le mécanisme des thèmes. On définit dans la racine une palette claire, puis on écrit un second bloc de déclarations qui remplace les valeurs du même nom. Deux façons de déclencher ce basculement existent. La première repose sur une classe posée sur la racine, commandée par un bouton ou par un script, ce qui laisse l'utilisateur en contrôle. La second repose sur la préférence système, déclarée dans une requête média qui détecte le choix mode sombre du visiteur : aucun script, aucune intervention, la page suit l'habitude de la machine. Dans les deux cas, le reste du CSS ne change pas d'une ligne, puisqu'il ne connaît que les noms de variables.

```css
/* Thème par préférence système : aucune ligne de JavaScript nécessaire */
@media (prefers-color-scheme: dark) {
  :root {
    --encre: #e7e5e4;
    --fond: #1c1917;
    --fond-doux: #292524;
    --trait: #44403c;
    --accent: #2dd4bf;
  }
}

/* Thème commandé par une classe sur la racine */
:root.sombre {
  --encre: #e7e5e4;
  --fond: #1c1917;
  --accent: #2dd4bf;
}
```

Une discipline de nommage rend la pratique durable. Nommez les variables d'après leur rôle dans l'interface, jamais d'après leur valeur : le nom qui dit couleur-verte devient faux dès que la charte change, alors que le nom qui dit couleur-d-accent reste vrai quoi qu'il arrive. Regroupez les déclarations par famille, avec une ligne commentée par groupe, de sorte qu'un nouveau contributeur trouve la palette en une seconde. Limitez le nombre de variables : une dizaine de valeurs sémantiques suffisent pour un projet de ce type, une centaine transforme le fichier en table de correspondance indéchiffrable. Enfin, souvenez-vous que la variable ne possède pas de type : elle peut contenir une couleur, une longueur, une famille de police, un écho de mise en page, ou même une liste complète de propriétés, tant que la syntaxe reste valide à l'endroit où elle est lue.

- Déclarez chaque valeur sémantique une fois dans le sélecteur racine, lisez-la avec la fonction var.
- La fonction admet un argument de secours, appliqué seulement si le nom n'existe pas.
- Les propriétés personnalisées héritent : elles se redéfinissent sur n'importe quelle sous-arborescence.
- Un thème clair et un thème sombre ne diffèrent que par le jeu de valeurs déclarées.
- Nommez d'après le rôle dans l'interface, jamais d'après la couleur ou la taille.
- La préférence système évite tout script ; la classe commande laisse le choix au visiteur.
- Une dizaine de variables sémantiques suffisent à un projet complet.
$lesson$),
  ('web-c2-p8', 'web-c2', 8, $lesson$Mise en page responsive : media queries et clamp$lesson$, $lesson$
Une page web ne possède pas de largeur. Elle possède des largeurs, autant qu'il y a d'écrans, et la première erreur de mise en page consiste à concevoir pour un seul. Le visiteur arrive sur un téléphone tenu à la verticale, sur une tablette tenue à l'horizontale, sur un poste de travail large, parfois sur un téléviseur ou un projecteur de salle. Il zoome aussi, volontairement, parce qu'il lit mal ce jour-là ou parce qu'il est loin de l'écran. La mise en page moderne répond à tout cela par un principe unique : on ne conçoit pas une mise en page pour un appareil, on conçoit des règles qui se réorganisent quand l'espace manque. C'est ce que le mot responsive désigne, et la technique qui l'implémente est devenue en quelques années le socle de tout travail web.

Deux éléments rendent l'adaptation possible. Le premier, que vous avez déjà écrit au chapitre précédent, est la déclaration d'échelle dans l'en-tête technique : sans elle, le téléphone simule un écran large et affiche une page miniature que l'on doit pincer pour lire. Avec elle, la largeur réelle de l'appareil devient la largeur de travail, et chaque règle que vous écrivez s'applique à la bonne échelle. Le second est la requête média : une condition posée devant un bloc de déclarations, qui n'est appliquée que si la caractéristique correspondante est vraie. La plus courante compare la largeur de la fenêtre à un seuil ; d'autres interrogent l'orientation, la densité de pixels, la préférence de couleur ou la préférence de mouvement réduit que vous verrez dans la section sur l'accessibilité.

```css
/* Base : conçue pour le plus petit écran d'abord */
.titre-principal {
  font-size: clamp(1.75rem, 4vw + 1rem, 3rem);
  line-height: 1.15;
  margin-block-end: 0.75rem;
}

.groupe-de-champs {
  display: grid;
  gap: 1rem;
}

/* Ajout d'une colonne quand l'espace le permet */
@media (min-width: 40rem) {
  .groupe-de-champs {
    grid-template-columns: 1fr 1fr;
  }
  .champ-large {
    grid-column: 1 / -1;
  }
}

@media (min-width: 64rem) {
  .page {
    grid-template-columns: 16rem minmax(0, 1fr);
    gap: 2rem;
  }
}
```

La manière la plus saine d'écrire ces règles est de partir de l'écran le plus étroit et de n'ajouter que des conditions de type seuil minimal. On évite ainsi le double travail de deux versions, une pour mobile et une pour ordinateur, qui finit toujours par diverger. On évite aussi l'écueil symétrique, écrire d'abord pour le grand écran puis devoir défaire la mise en page : dans ce second modèle, chaque media query réécrit ce qui précède, alors que dans le premier, elle enrichit ce qui précède. Le choix du seuil, enfin, ne se décide pas d'après un catalogue d'appareils, mais d'après le contenu : on place une rupture à l'endroit exact où la composition commence à se gêner elle-même, quand les cartes deviennent trop étroites pour leur texte ou quand l'encart chasse le contenu principal.

La fonction de valeur bornée résout l'autre moitié du problème : ce qui doit grandir sans jamais dépasser. Elle prend trois arguments, une valeur minimale, une valeur souhaitée qui peut dépendre de la largeur de fenêtre, et une valeur maximale. Appliquée aux tailles de titre, elle donne des titres qui suivent doucement la largeur de l'écran au lieu de rester figés ou d'exploser. Appliquée aux espacements, elle produit des marges respirables sur grand écran et compactes sur petit. On l'emploie aussi pour les largeurs de boîte : une mesure maximale empêche un paragraphe de s'étirer sur mille pixels, où l'œil perd le fil en fin de ligne, et un minimum empêche une colonne d'être étranglée par son voisinage.

- Conception d'abord pour l'écran étroit, puis enrichissement par seuils minimaux.
- La déclaration d'échelle de l'en-tête est la condition préalable de toute adaptation.
- Les ruptures se choisissent d'après le contenu, jamais d'après un modèle d'appareil.
- La fonction bornée fait grandir un texte ou un espacement entre un plancher et un plafond.
- Une mesure maximale garde les lignes de texte d'une longueur lisible.
- Regroupez les requêtes média et ne modifiez qu'un seul concept par bloc.
$lesson$),
  ('web-c2-p9', 'web-c2', 9, $lesson$Composants réutilisables : bouton, carte, formulaire$lesson$, $lesson$
Un composant est un morceau d'interface que l'on peut poser n'importe où dans la page et qui se comporte de la même manière partout : un bouton, une carte, un champ de formulaire, un encart d'information, un message d'état. LeCSS ne connaît pas cette notion, mais il la rend possible par une convention : une classe nomme le composant, d'autres classes nomment ses variantes, et les états sont exprimés par des pseudo-classes. Le gain est considérable. Une correction faite au composant s'applique à toutes ses occurrences, un nouveau membre d'équipe retrouve la règle en cherchant simplement le nom du composant, et la page gagne en cohérence visuelle parce que deux boutons différents ne peuvent plus exister sans que cela soit écrit.

Le bouton illustre la méthode. On écrit d'abord la base, commune à tous : dimensions, espacement intérieur, arrondi, typographie, fond, absence de bordure par défaut. Puis on ajoute les variantes, qui ne changent qu'un ou deux critères : la variante secondaire garde un fond transparent et une bordure, la variante discrète retire le fond. Puis on laisse les états au navigateur : le survol assombrit le fond, l'activation l'assombrit un peu plus, le focus dessine un anneau, l'inactivité grise tout. L'ordre d'écriture compte : la base en premier, les variantes ensuite, les états en dernier, de sorte que la cascade fasse le tri sans que vous ayez à augmenter la spécificité.

```css
.bouton {
  display: inline-block;
  padding: 0.6rem 1.1rem;
  border: 2px solid var(--accent);
  border-radius: var(--rayon);
  background-color: var(--accent);
  color: var(--fond);
  font: inherit;
  font-weight: 600;
  text-decoration: none;
  cursor: pointer;
}
.bouton:hover { background-color: var(--accent-fonce); }
.bouton:active { transform: translateY(1px); }
.bouton[disabled] { opacity: 0.5; cursor: not-allowed; }

.bouton-secondaire {
  background-color: transparent;
  color: var(--accent);
}
.bouton-secondaire:hover { background-color: var(--fond-doux); }
```

La carte est le composant qui justifie à lui seul la disposition flexible. Sa structure attendue est la suivante : une image ou un bandeau en haut, un titre, un texte, éventuellement une ligne d'actions en bas. Sa difficulté est que les cartes d'une même rangée ont des hauteurs différentes, et que l'on veut pourtant que leurs pieds s'alignent. La solution combine les deux familles de mise en page du chapitre : la grille répartit les cartes dans la rangée, la disposition flexible empile leur contenu en colonne et pousse la zone qui grandit, de sorte que le pied reste collé en bas quelle que soit la longueur du texte. Ajoutez-y un débordement de texte coupé proprement, et la carte devient résistante à n'importe quel contenu.

```css
.carte {
  display: flex;
  flex-direction: column;
  border: 1px solid var(--trait);
  border-radius: var(--rayon);
  overflow: hidden;
  background-color: var(--fond);
}
.carte-titre { margin: var(--espace) 0 0.5rem; font-size: 1.25rem; }
.carte-texte { margin: 0; flex-grow: 1; color: #44403c; }
.carte-pied {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  margin-block-start: var(--espace);
  padding-block-start: 0.75rem;
  border-block-start: 1px solid var(--trait);
}
.carte-etiquette {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--accent);
}
```

Le formulaire réclame une attention particulière, parce qu'il concentre les trois endroits où l'interface échoue le plus souvent : l'identification du champ, la lisibilité de la saisie et la compréhension de l'erreur. Le chapitre précédent a posé la structure avec des étiquettes associées ; le CSS vient renforcer le résultat. On donne aux champs une largeur totale sur petit écran pour faciliter la saisie au pouce, on espace les champs d'un cran pour éviter les frappes à côté, on réserve une taille de touche confortable, et surtout on ne colore jamais le champ en rouge sans message textuel : la couleur est un renfort, jamais l'information unique. L'état de focus doit être nettement plus visible que l'état au repos, car c'est lui qui dit à l'utilisateur où il se trouve.

```css
.champ { display: grid; gap: 0.35rem; margin-block-end: 1rem; }
.champ label { font-weight: 600; }
.champ input,
.champ textarea {
  width: 100%;
  padding: 0.6rem 0.75rem;
  border: 1px solid var(--trait);
  border-radius: var(--rayon);
  font: inherit;
  background-color: var(--fond);
  color: var(--encre);
}
.champ input:focus-visible {
  outline: 3px solid var(--accent);
  outline-offset: 2px;
  border-color: var(--accent);
}
.champ .aide { font-size: 0.85rem; color: #57534e; }
.champ .erreur { color: #b91c1c; font-weight: 600; }
```

- Une classe nomme le composant, d'autres classes nomment les variantes, les pseudo-classes les états.
- Écrivez base, variantes, états dans cet ordre : la cascade fait le reste.
- La grille dispose les cartes, la disposition flexible empile leur contenu et aligne leur pied.
- Une carte résiste à n'importe quel texte : hauteur libre, débordement coupé proprement.
- Un champ de saisie est large, espacé, et son focus est plus visible que son repos.
- Ne faites jamais reposer une information sur la seule couleur.
- Nommez d'après le rôle, gardez les sélecteurs courts, annotez vos composants.
$lesson$),
  ('web-c2-p10', 'web-c2', 10, $lesson$Accessibilité visuelle$lesson$, $lesson$
L'accessibilité visuelle n'est pas une couche ajoutée en fin de projet, c'est un jeu de contraintes qui accompagne chaque décision de couleur et de mise en page. Elle ne demande aucun outil particulier : elle demande de savoir ce que voit une personne malvoyante, une personne qui navigue au clavier, une personne sensible aux mouvements, ou simplement quelqu'un qui consulte la page en plein soleil sur un écran de faible qualité. Les critères sont publics, mesurables et pour la plupart automatisables ; les intégrer dès la première ligne de CSS coûte moins cher que de les corriger après coup, et la page en est presque toujours plus claire.

Le contraste est le critère le plus facile à mesurer et le plus souvent négligé. Il exprime le rapport de luminance entre le texte et son fond, et la règle tient en deux seuils : un texte courant doit atteindre un rapport de quatre virgule cinq pour un, un texte grand, donc gras ou de taille supérieure à un certain corps, doit atteindre trois pour un. Un gris clair sur blanc échoue dans la très grande majorité des cas, de même qu'un jaune sur blanc ou un bleu foncé sur fond coloré. Les outils de navigateur fournissent un sélecteur de couleur qui affiche instantanément le rapport sous le curseur ; en trente secondes, vous auditez une page entière. Le tableau ci-dessous rappelle les seuils applicables aux usages les plus courants d'une page d'atelier.

```table
| Usage | Rapport minimal | Exemple de contrôle |
| --- | --- | --- |
| Texte courant | 4,5 pour 1 | paragraphe, libellé, lien dans le texte |
| Grand texte | 3 pour 1 | titre au-dessus de 18,66 px gras ou 24 px |
| Icône et bordure utile | 3 pour 1 | contour d'un champ, séparateur porteur |
| Zone non textuelle | 3 pour 1 | barre d'état, étiquette de graphique |
| État repos d'un champ | 3 pour 1 | bordure visible sur son fond |
```

La deuxième exigence est celle du focus. Au chapitre précédent, vous avez parcouru la page au clavier ; cette fois, il s'agit de s'assurer que l'on voie où l'on est. Le navigateur fournit par défaut un anneau de focus, et le réflexe le plus dommageable consiste à le supprimer parce qu'il défigure la mise en page. La correction n'est pas de le retirer, mais de le dessiner mieux : un anneau épais, décalé de deux pixels par rapport au bord, dans une couleur à fort contraste. La pseudo-classe qui ne se déclenche que pour le clavier permet en plus de garder un rendu sobre pour les utilisateurs de souris, sans jamais priver personne de l'indication. Autour de cette anneau, prévoyez des cibles de clic suffisamment grandes : un élément interactif ne devrait pas descendre en dessous d'une taille carrée confortable, et deux actions voisines doivent rester séparées pour éviter la frappe à côté.

```css
/* Un focus net, visible sur tous les fonds, sans gêner la souris */
:where(a, button, input, textarea, select):focus-visible {
  outline: 3px solid var(--accent);
  outline-offset: 2px;
  border-radius: 2px;
}

/* Les cibles restent spacieuses, y compris sur écran tactile */
a, button { min-block-size: 2.75rem; padding-inline: 0.75rem; }

/* Respect de la préférence système : pas d'animation non essentielle */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

La troisième exigence concerne le mouvement. Certaines personnes ressentent malaise, nausée ou confusion face à des animations, des défilements automatiques ou des transitions rapides, et le système d'exploitation le leur signale par une préférence qu'ils peuvent activer une fois pour toutes. La requête média qui la détecte permet de répondre en une règle globale : neutraliser les transitions et animations non essentielles. Une discipline complémentaire produit le même résultat avec plus d'élégance : n'animer que les propriétés de transformation et d'opacité, n'animer que ce qui aide à comprendre un changement d'état, et ne jamais faire défiler un contenu à la place de l'utilisateur.

- Un texte courant exige un rapport de contraste de quatre virgule cinq pour un.
- Ne supprimez jamais l'anneau de focus : dessinez-le mieux, épais et décalé.
- Préférez le focus visible au focus permanent, pour ne pas troubler la souris.
- Agrandissez les cibles de clic et séparez les actions voisines.
- Détectez la préférence de mouvement réduit et neutralisez les animations non essentielles.
- Testez à deux cents pour cent, en fenêtre étroite et en nuances de gris.
- Une information portée par la couleur doit être doublée d'un texte ou d'une forme.
$lesson$),
  ('web-c2-p11', 'web-c2', 11, $lesson$Organiser son CSS$lesson$, $lesson$
À mesure que le fichier grossit, l'ordre devient le vrai sujet. Le CSS n'affiche aucun message d'erreur, ne bloque jamais l'exécution et accepte les contradictions : un fichier désordonné continue donc de fonctionner, tout en devenant impossible à corriger. Organiser son CSS, ce n'est pas faire joli, c'est maintenir une seule garantie : à tout moment, on sait quelle règle gagne et pourquoi. Heureusement, la structure qui offre cette garantie est simple à décrire et se met en place en quelques lignes.

La première décision est la découpe en fichiers. On sépare ce qui est permanent de ce qui est propre à une page : un fichier de base qui contient la remise à zéro, la typographie et les variables ; un fichier de composants qui contient boutons, cartes et champs ; un fichier de page qui contient la structure propre à l'écran en cours. Chaque page relie alors trois fichiers dans cet ordre, et l'ordre de liaison devient l'ordre de prééminence, ce qui correspond exactement à la troisième règle de la cascade. L'arborescence reste lisible parce que les noms de fichiers reflètent les noms de classes : on retrouve la règle d'un composant en cherchant le composant, pas en fouillant mille lignes.

```css
/* couches explicites : l'ordre est déclaré, pas subi */
@layer base, composants, pages, utilitaires;

@layer base {
  :root { --accent: #0f766e; --encre: #1c1917; }
  body { font-family: system-ui, sans-serif; color: var(--encre); }
  * { box-sizing: border-box; }
}

@layer composants {
  .bouton { background-color: var(--accent); border-radius: var(--rayon); }
  .carte { border: 1px solid var(--trait); border-radius: var(--rayon); }
}

@layer pages {
  .page { display: grid; grid-template-columns: 1fr; gap: 1.5rem; }
}

@layer utilitaires {
  .texte-centre { text-align: center; }
  .masque-visuellement { position: absolute; inset-block-start: -9999px; }
}
```

La seconde décision concerne les raccourcis d'urgence. La déclaration importante est un outil de contournement, pas un outil de conception ; son usage répété signale qu'un sélecteur est trop précis ou que l'ordre des fichiers est mauvais. Quand elle apparaît, cherchez d'abord la cause, puis retirez-la. Le même raisonnement vaut pour les sélecteurs qui nomment des identifiants dans les règles de style : ils fonctionnent, ils sont seulement trop puissants pour ce qu'on leur demande. Enfin, gardez une ligne commentée au-dessus de chaque bloc de règles qui nomme ce que le bloc fait ; un commentaire n'est pas de la documentation perdue, c'est le seul marqueur qui survit à un copier-coller.

- Découpez en fichiers : base, composants, pages, puis reliez-les dans cet ordre.
- Les couches explicites déclarent l'ordre de prééminence au lieu de le faire deviner.
- Un sélecteur de classe par règle, une imbrication au maximum.
- Refusez l'escalade de spécificité : réordonnez ou extrayez une classe.
- Réservez la déclaration importante au contournement exceptionnel, et notez pourquoi.
- Une ligne de commentaire au-dessus de chaque bloc nomme ce qu'il fait.
- Relisez l'ordre réel des règles dans l'inspecteur, pas seulement le fichier.
$lesson$),
  ('web-c2-p12', 'web-c2', 12, $lesson$Mini-projet guidé : habiller la page de l'atelier$lesson$, $lesson$
Il est temps d'appliquer tout le chapitre à la page que vous possédez déjà. Ouvrez le fichier atelier.html du chapitre précédent, tel qu'il est : régions sémantiques, hiérarchie de titres, liste, tableau, formulaire, pied de page. Vous n'y toucherez pas. Vous créerez à côté un dossier de styles et un fichier nommé atelier.css, puis vous relierez les deux avec la balise link dans l'en-tête technique de la page. L'expérience de départ est celle promise en introduction : rechargez la page après avoir posé le lien, et vous verrez un document brut ; désactivez la feuille de style dans l'inspecteur, et il redevient ce document. Tout ce qui suit se passe dans le seul fichier CSS.

La première étape pose les fondations : le jeu de variables, la remise à zéro minimale, la typographie et la mesure du texte. Déclarez d'abord les noms sémantiques dans le sélecteur racine, en regroupant couleurs, espacements et rayons. Ensuite, retirez les marges par défaut que le navigateur applique aux paragraphes et aux titres, puis rétablissez une rythmique verticale cohérente : c'est cette uniformité qui fait le plus grand effet visuel d'un document sans pourtant changer une seule couleur. Enfin, bornez la mesure du texte et centrez l'ensemble dans la fenêtre, si bien que la page reste confortable sur un écran large.

```css
/* atelier.css — habillage de la page atelier.html */
:root {
  --encre: #1c1917;
  --fond: #ffffff;
  --fond-doux: #f5f5f4;
  --accent: #0f766e;
  --accent-fonce: #115e59;
  --trait: #d6d3d1;
  --rayon: 0.5rem;
  --espace: 1.25rem;
  --mesure: 62rem;
}

*, *::before, *::after { box-sizing: border-box; }

body {
  margin: 0 auto;
  max-width: var(--mesure);
  padding: clamp(1rem, 3vw, 2.5rem);
  font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
  line-height: 1.6;
  color: var(--encre);
  background-color: var(--fond);
}

h1, h2, h3 { line-height: 1.2; margin-block-end: 0.5rem; }
h1 { font-size: clamp(1.75rem, 4vw + 1rem, 2.75rem); }
h2 { color: var(--accent); }
p, ul, ol, table, figure, form { margin-block-end: 1.25rem; }
img { max-width: 100%; height: auto; display: block; }
a { color: var(--accent); }
```

La seconde étape construit le squelette de la page avec la grille. Déclarez un conteneur sur l'élément racine du contenu, nommez les quatre régions du plan, puis laissez la grille faire l'alignement. Sur grand écran, l'encart latéral passe à droite et le contenu occupe la colonne restante ; sur écran étroit, le plan se replie en une seule colonne, l'encart venant juste après le contenu, sans qu'une ligne supplémentaire ne soit nécessaire. La troisième étape habille les composants : la navigation passe sur une seule ligne avec espacement automatique et enroulement, le tableau reçoit une bordure et un défilement horizontal étroit, le formulaire gagne des champs pleine largeur et un bouton d'action aligné à droite.

```css
/* Structure de page : plan nommé puis repli mobile */
.page {
  display: grid;
  grid-template-areas:
    "entete"
    "menu"
    "contenu"
    "encart"
    "pied";
  gap: 1.5rem;
}
.entete  { grid-area: entete; }
.menu    { grid-area: menu; }
.contenu { grid-area: contenu; }
.encart  { grid-area: encart; }
.pied    { grid-area: pied; }

@media (min-width: 56rem) {
  .page {
    grid-template-columns: minmax(0, 3fr) minmax(14rem, 1fr);
    grid-template-areas:
      "entete entete"
      "menu   menu"
      "contenu encart"
      "pied   pied";
    gap: 1.5rem 2rem;
  }
}

.navigation ul {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem 1.5rem;
  margin: 0;
  padding: 0;
  list-style: none;
}
.navigation a {
  display: inline-block;
  min-block-size: 2.75rem;
  padding-inline: 0.5rem;
  font-weight: 600;
  text-decoration: none;
  border-block-end: 2px solid transparent;
}
.navigation a:hover { border-block-end-color: var(--accent); }
```

La quatrième étape referme le travail avec l'accessibilité et les finitions. Posez l'anneau de focus sur tous les éléments interactifs, ajoutez la règle de mouvement réduit, vérifiez les contrastes de chaque couleur de texte sur son fond, et donnez au tableau une largeur maximale avec défilement pour qu'il ne fasse pas sortir la page de son cadre. La dernière étape est la vérification, et elle se déroule toujours dans le même ordre : parcourez la page au clavier seule, confirmez que le focus se voit partout et suit l'ordre de lecture ; réduisez la fenêtre à la largeur d'un téléphone et cherchez le point de rupture ; zoomez à deux cents pour cent ; désactivez enfin la feuille de style et vérifiez que la page reste lisible, parce qu'elle est toujours le document HTML du chapitre précédent.

- Reliez un seul fichier CSS : le HTML de l'atelier ne change pas d'une ligne.
- Posez variables, remise à zéro et typographie avant toute mise en page.
- Nommez les régions et laissez la grille assurer la structure, avec repli en une colonne.
- Habillez ensuite les composants : navigation, tableau, formulaire, bouton.
- Terminez par le focus, le mouvement réduit, le contraste et le défilement du tableau.
- Vérifiez dans cet ordre : clavier, largeur étroite, zoom, feuille de style désactivée.
$lesson$),
  ('web-c2-p13', 'web-c2', 13, $lesson$À retenir$lesson$, $lesson$
- Le CSS décrit un état visuel ; la cascade choisit la règle qui s'applique, par origine, spécificité puis ordre.
- Une règle associe un sélecteur à un bloc de déclarations ; chaque déclaration est terminée par un point-virgule.
- Le fichier externe relié par la balise link domine : cache, réutilisation, séparation du contenu et du style.
- La balise style sert au courrier électronique et au prototype ; l'attribut style, aux valeurs calculées par un script.
- Les sélecteurs de classe sont faibles et réutilisables ; les identifiants sont puissants et rarement utiles.
- La spécificité se chiffre en trois composantes, puis c'est l'ordre du fichier qui tranche.
- Tout élément est une boîte : contenu, espacement intérieur, bordure, marge ; le mode à la bordure évite les débordements.
- La flexbox répartit les enfants sur un axe principal, avec répartition, alignement, enroulement et écartement.
- La grille organise deux dimensions à la fois : pistes, unités de fraction, plages et plans de zones nommées.
- Les propriétés personnalisées se déclarent avec deux traits d'union et se lisent avec la fonction var, argument de secours compris.
- Un thème sombre ne diffère que par le jeu de valeurs, déclenché par une classe ou par la préférence système.
- On conçoit pour l'écran étroit puis on enrichit par seuils minimaux ; les ruptures suivent le contenu.
- Un composant combine une classe de base, des variantes et des états pilotés par pseudo-classes.
- Texte courant à quatre virgule cinq pour un de contraste, focus visible permanent, cibles de clic spacieuses.
- La préférence de mouvement réduit neutralise les animations non essentielles.
$lesson$),
  ('web-c2-p14', 'web-c2', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : augmenter la spécificité pour vaincre une règle qui gagne → Correction : vérifiez d'abord l'ordre des fichiers et des blocs, puis extrayez une classe plutôt que d'empiler des identifiants.
- Piège : multiplier les déclarations importantes → Correction : elles sont un recours exceptionnel ; cherchez la cause, réordonnez, retirez-la.
- Piège : oublier le point-virgule entre deux déclarations → Correction : écrivez systématiquement un point-virgule à chaque ligne, y compris la dernière.
- Piège : laisser une propriété inconnue sans effet, sans jamais regarder la console → Correction : l'inspecteur barre en grisé les déclarations rejetées ; corrigez la coquille immédiate.
- Piège : conserver le dimensionnement par défaut, où la largeur ignore bordure et espacement → Correction : posez le mode à la bordure sur le sélecteur universel en tête de fichier.
- Piège : se tromper d'axe en flexbox et chercher pourquoi rien n'aligne → Correction : rappelez-vous que la répartition suit l'axe principal et l'alignement l'axe transversal.
- Piège : écrire une media query pour chaque appareil du tiroir → Correction : deux ou trois seuils, choisis là où le contenu commence à se gêner.
- Piège : masquer l'anneau de focus parce qu'il défigure la page → Correction : redessinez-le, épais et décalé, et ne le remplacez jamais par rien.
- Piège : faire porter une information par la seule couleur → Correction : ajoutez un texte, une forme ou un libellé, puis revérifiez le contraste.
- Piège : laisser la feuille de style désactivée révéler une page vide → Correction : écrivez le HTML pour lui-même, le CSS vient seulement l'habiller.
$lesson$),
  ('web-c2-p15', 'web-c2', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation de Mozilla reste la référence la plus pratique pour approfondir ce chapitre, parce qu'elle décrit chaque propriété avec des exemples, des tableaux de compatibilité et des liens croisés entre techniques. Commencez par la page https://developer.mozilla.org/docs/Web/CSS, qui dresse l'inventaire des propriétés et des sélecteurs, puis descendez vers les guides consacrés aux deux familles de mise en page : https://developer.mozilla.org/docs/Web/CSS/CSS_flexible_box_layout pour la disposition flexible et https://developer.mozilla.org/docs/Web/CSS/CSS_grid_layout pour la grille. Pour les requêtes média et les préférences système, la page https://developer.mozilla.org/docs/Web/CSS/@media réunit toutes les caractéristiques interrogables, mouvement réduit et thème sombre compris. Ces pages évoluent avec les navigateurs et signalent ce qui est obsolète : c'est l'endroit où trancher un doute plutôt que de recopier un vieux fragment trouvé ailleurs.

Le cours Learn CSS de web.dev, à l'adresse https://web.dev/learn/css/, propose une progression comparable à celle de ce chapitre, avec des démonstrations interactives sur la cascade, la boîte, la flexbox, la grille et les couleurs, et un accent particulier sur les bonnes pratiques de rendu. Côté W3C, la page https://www.w3.org/Style/CSS/ présente le rôle du consortium, l'historique des spécifications et les documents de référence ; c'est là que se publient les évolutions du langage avant qu'elles n'arrivent dans les navigateurs. Prenez le temps de feuilleter ces ressources au moment où une question précise se pose plutôt que de les lire d'un bout à l'autre : gardez-les en favori pour le jour où vous rédigerez votre premier vrai projet.
$lesson$),
  ('web-c2-p16', 'web-c2', 16, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
Vous disposez maintenant de l'essentiel du langage de présentation : une cascade que vous comprenez, des sélecteurs que vous choisissez, un modèle de boîte que vous maîtrisez, deux familles de mise en page que vous savez réunir, un thème piloté par des variables, une adaptation aux petits écrans et un jeu de règles d'accessibilité visuelle. La suite logique est l'exercice pratique qui accompagne ce chapitre : vous habillerez seul la page de l'atelier, en partant de votre propre fichier de styles, avec les variables, le plan en grille, la carte, la navigation, la media query et l'état de focus, puis vous comparerez votre résultat à la correction et vous vérifierez votre page avec la liste de contrôle de la section précédente. Le quiz de quatre questions qui accompagne le chapitre vous permet en parallèle de vérifier les notions essentielles en quelques minutes.

Passé cet exercice, le parcours abordera la troisième grande technologie du web, le JavaScript, qui prend le relais pour donner un comportement à la page que vous venez d'habiller. Vous verrez alors que la frontière que vous avez tracée, structure en HTML, apparence en CSS, comportement en JavaScript, n'était pas une règle de style mais la condition même d'un projet qui reste lisible, modifiable et accessible à mesure qu'il grandit. Conservez donc votre feuille de style : vous la ferez réagir aux actions de l'utilisateur au chapitre suivant, et la différence entre un style statique et un composant vivant sera la meilleure démonstration de la complémentarité des trois langages.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('web-c3-p1', 'web-c3', 1, $lesson$Le rôle du JavaScript dans une page$lesson$, $lesson$
Vous entrez dans le troisième chapitre du parcours Développement web moderne, le chapitre où votre page cesse d'être immobile. Les deux précédents vous ont appris à décrire un document avec du HTML et à le mettre en forme avec du CSS : votre fichier atelier.html présente désormais l'atelier de la Médiathèque des Lilas, son programme, ses informations pratiques et son formulaire d'inscription. Jusqu'ici pourtant, la page reste muette. Si un visiteur appuie sur un bouton, rien ne se passe ; s'il saisit une adresse électronique mal formée, il ne l'apprend qu'au moment de l'envoi ; si le nombre de places disponibles change, il faut rouvrir le fichier, le corriger à la main et recharger l'onglet. Le JavaScript est la technologie qui comble exactement cet écart : il écoute les gestes de l'utilisateur, il modifie ce qui s'affiche à l'écran et il prend des décisions pendant que la page reste ouverte. C'est la troisième couche du web, celle du comportement, et c'est celle que vous allez écrire vous-même, ligne après ligne, dans ce chapitre.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez manipulées dans du vrai code exécuté par votre navigateur. Vous comprendrez le rôle exact du JavaScript et la frontière qu'il partage avec le HTML et le CSS. Vous écrirez votre premier script, vous le placerez au bon endroit de la page et vous ouvrirez la console pour en observer la sortie. Vous découvrirez que le navigateur transforme votre fichier HTML en une structure en arbre, appelée DOM, et que ce document vivant est l'objet sur lequel tous vos scripts travaillent. Vous sélectionnerez des éléments avec les sélecteurs CSS que vous connaissez déjà, vous modifierez leur texte, leurs classes et leurs attributs, vous créerez de nouveaux éléments à la volée et vous en supprimerez d'autres. Vous attacherez des gestionnaires d'événements, vous comprendrez comment les événements remontent dans l'arbre, et vous en profiterez pour écrire une délégation propre. Enfin, vous validerez une saisie en direct dans le formulaire d'inscription, avec un message d'erreur annoncé correctement aux technologies d'assistance.

Une recommandation sur la manière d'aborder ce chapitre, avant d'entrer dans le vif du sujet. Le JavaScript ne s'apprend pas en le regardant : il s'apprend en le cassant. Rien ne remplace le geste de recopier un exemple dans votre fichier, d'enregistrer, de recharger l'onglet et d'observer ce qui change. Modifiez ensuite une ligne, supprimez un mot, échangez deux fonctions : c'est dans l'écart entre ce que vous attendiez et ce qui s'est produit que le langage se fixe. Quand quelque chose ne marche pas, et cela ne manquera pas d'arriver, la console est votre première alliée : elle écrit en rouge ce que le navigateur refuse de faire, et la majorité des messages qu'elle affiche nomment la ligne exacte où votre raisonnement a dérapé. Le fil rouge du chapitre reste le même depuis le début du parcours : l'atelier de la Médiathèque des Lilas. Vous avez écrit sa structure, vous l'avez habillé, et vous allez maintenant l'animer : compter les places restantes, vérifier les adresses électroniques au fil de la saisie, ajouter une séance au programme, permettre à un inscrit de se retirer.



Le JavaScript est le langage qui donne un comportement à une page. Là où le HTML décrit ce que chaque morceau est et où le CSS décrit à quoi il ressemble, le JavaScript décrit ce qu'il fait quand on l'aborde. Concrètement, la liste de ces comportements est celle que vous croisez chaque jour : un menu qui s'ouvre au clic, un carrousel qui avance tout seul, un champ qui vérifie sa valeur pendant que vous tapez, un panier qui se met à jour sans recharger, une liste qui s'allonge quand on atteint le bas de l'écran, un message d'erreur qui apparaît sous un formulaire. Toutes ces réactions ont un point commun : elles surviennent après le chargement de la page, en réponse à quelque chose qui s'est produit. Sans JavaScript, la page reste exactement telle que le fichier HTML la décrit, figée à l'instant où le navigateur a fini de l'afficher.

Techniquement, le JavaScript est un langage de programmation complet : il possède des variables, des conditions, des boucles, des fonctions, des tableaux et des objets. Il est standardisé sous le nom d'ECMAScript, ce qui signifie que la syntaxe de base est la même dans tous les navigateurs modernes, au même titre que le HTML et le CSS sont des standards du W3C et de l'Organisation des spécifications. Contrairement au HTML, il ne se contente pas de décrire : il exécute. Contrairement à Python ou à d'autres langages de serveur, il ne s'exécute pas sur une machine que vous configurez, mais dans l'environnement que le visiteur possède déjà, le navigateur. Cette exécution est dite interprétée : vous écrivez du texte, vous rechargez la page, et le moteur JavaScript du navigateur traduit et exécute ce texte à la volée. Il n'y a aucune étape de compilation à configurer, aucun outil à installer : un fichier, un navigateur, et le résultat.

La grande particularité du JavaScript côté navigateur tient à son modèle de réaction, appelé modèle événementiel. Une page ne tourne pas en boucle en attendant vos instructions : elle reste en veille, affichée, et elle ne fait quelque chose que lorsqu'un événement survient. L'utilisateur clique, appuie sur une touche, envoie un formulaire, déplace le curseur, la fenêtre se redimensionne, la page finit de charger, une requête réseau aboutit : chacun de ces faits est un événement que le code peut écouter. Vous déclarez alors ce que vous souhaitez faire, et vous laissez le navigateur vous prévenir au moment opportun. Pour reprendre une image de la Médiathèque, votre script est l'agent d'accueil qui reste derrière son guichet prêt à intervenir, plutôt que celui qui visiterait une par une les tables de la salle en espérant deviner qui a besoin de quoi. Cette inversion du contrôle est la clé de tout le chapitre : vous n'écrivez plus ce qui arrive, vous écrivez ce que vous ferez quand cela arrive.

Cette responsabilité a des limites qu'il faut poser d'emblée, parce qu'elles protègent votre page. Le JavaScript ne sert pas à dessiner : une couleur, une police, une animation de survol, un espacement relèvent du CSS, qui fait ce travail de façon plus rapide, plus lisible et accessible même sans script. Le JavaScript ne sert pas non plus à structurer : si une information est essentielle, elle appartient au HTML et doit exister dans le fichier, pas naître d'un script au moment où quelqu'un la réclame. Enfin, le JavaScript ne doit jamais être le seul moyen d'accéder à une fonctionnalité essentielle : un visiteur dont le script ne se charge pas, qui navigue au clavier ou qui utilise un lecteur d'écran doit pouvoir lire le programme, remplir le formulaire et joindre l'organisateur. Cette discipline porte un nom, le renforcement progressif : on écrit d'abord une page complète et utilisable telle quelle, puis on ajoute le confort et l'interactivité. Le résultat est un site plus robuste, plus rapide et plus inclusif, et vous le constaterez dès le mini-projet, où le HTML reste la source de vérité et le JavaScript le gadget qui l'anime.

- Le HTML dit ce que c'est, le CSS dit à quoi ça ressemble, le JavaScript dit ce que ça fait.
- Le JavaScript s'exécute dans le navigateur du visiteur, sans installation ni compilation.
- Une page réagit à des événements : clic, touche, envoi, redimensionnement, chargement.
- Dessiner et mettre en forme relèvent du CSS, structurer relève du HTML.
- Une information essentielle existe dans le HTML, elle n'est pas fabriquée par un script.
- Le renforcement progressif garantit une page utilisable même si aucun script ne s'exécute.
$lesson$),
  ('web-c3-p2', 'web-c3', 2, $lesson$Écrire et exécuter du JavaScript : script, defer et console$lesson$, $lesson$
Il existe trois façons d'insérer du JavaScript dans une page, et il vaut mieux trancher tout de suite. La première consiste à écrire directement le code dans un attribut d'événement d'une balise, par exemple un attribut onclick sur un bouton. Cette pratique est aujourd'hui déconseillée : elle mélange le contenu et le comportement, elle encombre le balisage, elle interdit de réutiliser la fonction ailleurs et elle pose des problèmes d'accessibilité. La deuxième façon est d'ouvrir un bloc script à l'intérieur du fichier HTML et d'y écrire le code. Elle est commode pour un exemple court, pour un apprentissage ou pour une page unique, mais elle mélange à nouveau deux responsabilités. La troisième est la bonne dans la quasi-totalité des cas : écrire le code dans un fichier externe portant l'extension .js, puis le relier à la page avec la balise script et son attribut src. Votre atelier.html reste alors lisible, votre logique vit dans son propre fichier, et le navigateur peut mettre le script en cache pour les visites suivantes.

```html
<!-- Dans l'en-tête technique : chargement différé -->
<script src="js/atelier.js" defer></script>

<!-- À la fin du corps : exécution après l'analyse du document -->
<script src="js/atelier.js"></script>

<!-- Bloc interne : utile pour un exemple court -->
<script>
  console.log("Exécution au moment de la lecture");
</script>
```

La question de l'emplacement mérite d'être comprise plutôt que mémorisée, car elle explique la majorité des scripts qui ne marchent pas au premier essai. Quand le navigateur rencontre une balise script ordinaire au milieu du corps, il suspend l'analyse de la page, exécute le fichier entier, puis reprend l'affichage. Si votre script cherche un élément situé plus bas dans le fichier, cet élément n'existe pas encore : la sélection renvoie la valeur vide, et votre première instruction échoue. Trois solutions existent. Placer le script à la toute fin du corps, ce qui garantit que le document est déjà construit. Ajouter l'attribut defer à la balise script placée dans l'en-tête, ce qui ordonne au navigateur de télécharger le fichier pendant qu'il analyse la page puis de l'exécuter une seule fois, juste après la fin de l'analyse, en respectant l'ordre des fichiers déclarés. La troisième option, l'attribut async, déclenche l'exécution dès que le fichier arrive, sans attendre la fin de l'analyse, ce qui convient à des scripts autonomes comme une statistique de fréquentation mais pas à votre code d'interface. Pour un débutant, defer est le choix le plus sûr et le plus lisible : il se déclare en haut, il ne dépend pas de la position dans le corps et il s'exécute toujours après la mise en place de la page.

Une fois le script en place, la console devient votre table de bord. Ouvrez-la avec la touche F12 ou avec le raccourci du navigateur, puis rendez-vous dans l'onglet Console. Chaque appel à la fonction console.log écrit une ligne dans cette zone : le nom d'une variable, la valeur d'un champ, le résultat d'un calcul, l'étape atteinte dans une fonction. C'est le moyen le plus rapide de savoir ce que votre code voit réellement, et non ce que vous croyez qu'il voit. L'habitude à prendre est celle du développeur : une ligne par point de décision, retirée une fois le comportement vérifié. La console affiche aussi les erreurs, signalées en rouge avec un numéro de ligne, ainsi que les avertissements. Un mot sur la lecture des erreurs : le message est souvent rédigé dans un vocabulaire technique intimidant, mais il contient presque toujours deux informations exploitables, la nature du problème et l'endroit où il s'est produit.

```javascript
console.log("Début du script");

let places = 12;
console.log("Type du compteur :", typeof places);

places = places - 1;
console.log("Places restantes :", places);
console.table({ libelle: "Accueil", duree: 30 });

debugger;
```

L'ordre d'exécution suit l'ordre d'écriture, ligne après ligne, de haut en bas. Les fonctions déclarées sont mises en mémoire avant d'être appelées, mais un appel inexistant provoque immédiatement une erreur et arrête l'exécution du bloc : les lignes qui suivent ne s'exécutent pas. C'est la première raison d'un script qui semble muet après une erreur pourtant visible plus haut. Une erreur de syntaxe, une parenthèse oubliée ou un mot mal orthographié empêche même le chargement du fichier, tandis qu'une erreur d'exécution, comme une tentative d'accès à un élément absent, survient pendant la marche. Dans les deux cas, le message de la console nomme la ligne : lisez-la d'abord, regardez le code ensuite.

- Privilégiez un fichier .js externe relié par la balise script, plutôt que des attributs d'événement en ligne.
- Ajoutez defer à la balise script de l'en-tête pour exécuter le code après l'analyse de la page.
- Placez le script à la fin du corps si vous n'utilisez ni defer ni module.
- Ouvrez la console avec F12 et utilisez console.log pour observer les valeurs réelles.
- Une erreur rouge arrête le reste du bloc : corrigez-la avant de chercher ailleurs.
- Retirez vos journaux de débogage une fois le comportement vérifié.
$lesson$),
  ('web-c3-p3', 'web-c3', 3, $lesson$L'arbre DOM et la fenêtre$lesson$, $lesson$
Le navigateur ne conserve pas votre fichier HTML comme un simple texte : il l'analyse et le transforme en une structure en arbre, conservée en mémoire et accessible depuis vos scripts. Cette structure porte le nom de modèle de document, ou DOM pour Document Object Model. Chaque balise ouvrante devient un objet appelé élément, chaque morceau de texte devient un nœud de texte, chaque commentaire devient un nœud de commentaire. Les attributs deviennent des propriétés accessibles sur l'élément, et les relations d'imbriquation du fichier deviennent des relations de parenté dans l'arbre : ce qui était à l'intérieur devient enfant, ce qui suit devient frère. Le point d'entrée de tout script est l'objet document, qui représente la page entière. Sélectionner un élément, c'est demander à l'arbre de vous en remettre une référence ; modifier un élément, c'est changer une propriété de cet objet, et le navigateur redessine la zone concernée.

```text
document
└── html                    (élément racine)
    ├── head
    │   ├── meta
    │   ├── title
    │   │   └── "Atelier HTML du samedi"
    │   └── script
    └── body
        ├── header
        │   └── h1
        │       └── "Atelier HTML du samedi"
        ├── main
        │   └── section#programme
        │       ├── h2
        │       │   └── "Programme de la journée"
        │       ├── p
        │       │   └── "Trois heures d'initiation."
        │       └── form
        │           ├── label
        │           └── input#courriel
        └── footer
```

Il faut distinguer deux objets qui portent souvent confusion, la fenêtre et le document. L'objet window représente l'onglet : sa taille, son adresse, son historique, ses timers, ses messageurs. Il contient le document, de sorte que window.document désigne la page, et que la plupart des raccourcis comme document ou setTimeout sont en réalité des propriétés de la fenêtre mises à votre portée sans écrire son nom. La fenêtre sait aussi ce que la page ignore : la largeur de l'écran, la langue du système, la connexion réseau, la position dans l'historique. Retenez l'image d'un cadre et de son contenu : la fenêtre est le cadre avec la barre d'adresse et les flèches de navigation, le document est la feuille affichée dedans. Un script d'interface travaille presque toujours sur le document ; un script qui réagit au défilement ou au redimensionnement travaille sur la fenêtre.

Pour vous orienter dans l'arbre, un petit vocabulaire suffit. Chaque élément connaît son parent avec la propriété parentNode et sa collection d'enfants avec children. Les éléments voisins se rejoignent par nextElementSibling et previousElementSibling. Les raccourcis firstElementChild et lastElementChild donnent le premier et le dernier enfant élément, ce qui évite de tomber sur un nœud de texte. Une subtilité utile à connaître : dans le fichier source, les espaces et les retours à la ligne entre les balises créent de vrais nœuds de texte, souvent vides. Si vous parcourez les enfants bruts d'un élément, vous verrez alterner des éléments et des bouts de texte invisibles. C'est pourquoi les propriétés qui se terminent par Element, comme children ou firstElementChild, filtrent automatiquement ces nœuds et vous font gagner un temps considérable. Enfin, chaque nœud possède une nature, lisible avec nodeType : un élément porte le numéro un, un nœud de texte le numéro trois, un commentaire le numéro huit, et la propriété nodeName donne son nom en majuscules pour un élément.

- L'objet document représente la page et sert de porte d'entrée à tous vos scripts.
- Chaque balise devient un élément, chaque texte devient un nœud, chaque attribut devient une propriété.
- L'objet window représente l'onglet et contient le document, la position et l'historique.
- Parcourez l'arbre avec parentNode, children, nextElementSibling et firstElementChild.
- Préférez les propriétés qui se terminent par Element : elles ignorent les nœuds de texte parasite.
- nodeType et nodeName indiquent la nature de nœud sur lequel vous vous trouvez.
$lesson$),
  ('web-c3-p4', 'web-c3', 4, $lesson$Sélectionner des éléments$lesson$, $lesson$
Avant de modifier quoi que ce soit, il faut tenir l'élément. Une sélection est une référence, un pointeur vers l'objet que le navigateur a construit dans l'arbre, et toutes les opérations qui suivent passeront par lui. La méthode la plus directe est getElementById, qui accepte l'identifiant d'un élément et renvoie l'objet correspondant, ou la valeur vide si aucun élément ne porte cet identifiant. Elle est rapide, elle s'exprime en une ligne et elle convient parfaitement quand l'identifiant existe déjà dans votre page, par exemple le compteur de places ou le champ de courriel de l'atelier. Sa limite est son unicité même : un identifiant désigne un exemplaire, et vous ne pouvez pas en sélectionner plusieurs d'un coup.

```javascript
const compteur = document.getElementById("compteur");
const champCourriel = document.querySelector("#courriel");

const boutons = document.querySelectorAll("ul#programme li button");
const premierLibelle = document.querySelector("li button");

for (const bouton of boutons) {
  console.log(bouton.textContent);
}

const saisie = document.getElementById("courriel");
if (saisie) {
  console.log("Le champ existe :", saisie.value);
}
```

La méthode querySelector change de perspective : elle accepte n'importe quel sélecteur CSS, ceux-là mêmes que vous utilisez dans vos feuilles de style. Vous pouvez viser une classe, un type, un attribut, une chaîne de combinaisons, une pseudo-classe même. querySelector renvoie le premier élément qui correspond, tandis que querySelectorAll renvoie la liste complète des correspondances. Cette dernière ne renvoie pas un tableau JavaScript mais une liste de nœuds, un objet de type NodeList, que vous parcourez avec une boucle for...of, une méthode forEach ou une simple décomposition. La grande différence entre les deux méthodes tient à un détail qui a beaucoup d'importance : la liste renvoyée par querySelectorAll est statique. Elle est calculée une fois pour toutes et ne change pas si l'arbre évolue ensuite. Si vous ajoutez un élément correspondant au sélecteur plus tard dans l'exécution, votre liste d'origine ne l'inclura pas. Inversement, les méthodes qui portent le nom getElementsByClassName ou getElementsByTagName renvoient une collection vivante, mise à jour en temps réel à chaque nouvel élément. Pour un débutant, la règle tient en une phrase : retenez querySelector et querySelectorAll, leur comportement est prévisible et identique à celui du CSS.

```table
Méthode | Ce qu'elle renvoie | Référence
--- | --- | ---
getElementById | Un seul élément | Statique, liée à l'identifiant
querySelector | Le premier élément correspondant | Statique, sélecteur CSS complet
querySelectorAll | Une liste de nœuds | Statique, à parcourir avec for...of
getElementsByClassName | Une collection vivante | Mise à jour à chaque changement
getElementsByTagName | Une collection vivante | Mise à jour à chaque changement
closest | L'ancêtre correspondant le plus proche | Part d'un élément vers le haut
```

Un mot sur les cas limites, parce qu'ils occupent une grande part du débogage quotidien. Toute sélection qui échoue renvoie la valeur vide, et la tentative d'accéder à une propriété de cette valeur provoque une erreur immédiate, généralement libellée ainsi : impossible de lire les propriétés de null. Vérifiez donc la sélection avant de l'utiliser lorsque son existence n'est pas garantie, avec une condition simple qui teste la présence de l'objet. Par ailleurs, un sélecteur mal écrit ne provoque aucune erreur : il renvoie simplement rien, et votre script semble fonctionner sans effet. Vérifiez la sélection dans la console avant d'écrire la moitié de votre logique. Enfin, la méthode closest mérite d'entrer dans votre boîte à outils dès maintenant : partant d'un élément, elle remonte l'arbre jusqu'au premier ancêtre qui correspond au sélecteur. Elle deviendra indispensable dans la section sur la délégation d'événements, où elle sert à retrouver la carte ou la ligne qui contient le bouton cliqué.

- Toute opération commence par une sélection, c'est-à-dire une référence vers un élément.
- getElementById cible un identifiant unique, querySelector accepte n'importe quel sélecteur CSS.
- querySelectorAll renvoie une liste statique, à parcourir avec for...of.
- Les collections vivantes changent quand l'arbre change : leur nom contient ByTag ou ByClass.
- Une sélection ratée renvoie la valeur vide, et accéder à ses propriétés déclenche une erreur.
- La méthode closest remonte l'arbre depuis un élément jusqu'au premier ancêtre correspondant.
$lesson$),
  ('web-c3-p5', 'web-c3', 5, $lesson$Modifier le contenu, les classes et les attributs$lesson$, $lesson$
Une fois la référence obtenue, les modifications se répartissent en trois familles : ce que l'élément affiche, l'apparence qu'il revêt et les informations qu'il porte. Chacune possède ses propres méthodes, et choisir la bonne est une question de sécurité autant que de confort. Le texte visible se lit avec la propriété textContent, qui renvoie l'intégralité du contenu textuel d'un élément, y compris celui de ses descendants, et qui l'écrit en remplaçant tout ce qui se trouvait dedans. Cette propriété est la plus sûre des trois : ce que vous y affectez est traité comme du texte et jamais comme du balisage, si bien qu'une chaîne contenant des caractères de balisage s'affiche littéralement au lieu d'être interprétée. C'est celle qu'il faut utiliser dès qu'il s'agit d'afficher une valeur saisie par un utilisateur, un nom de participant ou un message d'erreur.

```javascript
const compteur = document.getElementById("compteur");
compteur.textContent = "8 places restantes";

const champ = document.getElementById("courriel");
champ.value = "camille@example.fr";
champ.setAttribute("placeholder", "prenom@exemple.fr");
champ.setAttribute("aria-invalid", "true");

const carte = document.querySelector(".carte");
carte.classList.add("carte-complete");
carte.classList.remove("carte-ouverte");
carte.classList.toggle("carte-selectionnee");

if (carte.classList.contains("carte-complete")) {
  console.log("La carte est complète");
}
```

Deux propriétés voisines complètent textContent, et il est utile de savoir ce qui les distingue. innerText renvoie le texte tel qu'il est affiché, c'est-à-dire en ignorant ce qui est masqué par le style et en respectant les retours visibles ; son accès force le navigateur à recalculer la mise en page, ce qui le rend plus lent sur une grande page. innerHTML, lui, interprète la chaîne comme du balisage : c'est le seul moyen d'insérer des éléments d'un seul geste, et c'est aussi le seul à présenter un risque réel. Si la chaîne provient de l'utilisateur, par exemple d'un champ de saisie ou d'une réponse réseau, il devient possible d'y glisser du code qui sera exécuté dans la page, une faille classique appelée injection de script. La règle professionnelle tient en une phrase : affichez du texte avec textContent, réservez innerHTML à du balisage que vous avez écrit vous-même et que vous maîtrisez de bout en bout.

Les classes, elles, se gèrent avec la liste des classes de l'élément. L'attribut class peut être lu et écrit directement, mais il est global : lui affecter une chaîne efface toutes les classes existantes, accident fréquent chez le débutant qui ajoute un style et efface tout le reste. La méthode classList offre une API complète : add ajoute, remove retire, toggle bascule selon la présence, contains vérifie. Elle accepte plusieurs valeurs à la fois et refuse silencieusement les chaînes contenant des espaces, ce qui vous épargne les erreurs de découpage. L'intérêt de passer par les classes plutôt que par le style en ligne est architectural : votre CSS conserve la maîtrise de l'apparence, votre JavaScript ne décide que de l'état, et vous pouvez changer toute la charte graphique sans toucher à une ligne de script. C'est exactement la séparation des rôles que vous aviez posée dans le premier chapitre, ici appliquée en mouvement.

Les attributs forment la troisième famille, et ils méritent une attention particulière parce que certaines propriétés d'interface ne sont pas des attributs. getAttribute lit une valeur déclarée dans le HTML, setAttribute l'écrit, removeAttribute la supprime. En revanche, des états comme la valeur d'un champ, l'état coché d'une case ou l'inactivité d'un bouton se manipulent directement en propriétés : champ.value, case.checked, bouton.disabled. La différence se voit immédiatement dans l'arbre : affecter la valeur false à l'attribut disabled ne rend pas le bouton actif, parce que la propriété reste vraie tant qu'elle n'est pas corrigée. Autre piège du même ordre : la propriété style, qui écrit du CSS depuis le JavaScript. Elle convient à une valeur calculée, par exemple une largeur déduite d'un pourcentage, mais elle doit rester l'exception. Si plusieurs lignes de style changent selon un état, créez une classe dans votre feuille de style et basculez-la depuis votre script.

- Modifiez le texte avec textContent : il traite toujours la chaîne comme du texte, jamais comme du balisage.
- Évitez innerHTML avec des données venues de l'utilisateur : c'est la porte d'entrée de l'injection de script.
- Utilisez classList pour ajouter, retirer ou basculer une classe sans écraser les autres.
- Préférez toujours une classe à du style en ligne : le CSS garde la maîtrise de l'apparence.
- La valeur d'un champ, l'état coché et l'inactivité se règlent en propriétés, pas en attributs.
- Retirez un élément du balisage avec removeAttribute plutôt qu'en lui affectant une valeur vide.
$lesson$),
  ('web-c3-p6', 'web-c3', 6, $lesson$Créer, déplacer et supprimer des nœuds$lesson$, $lesson$
Le DOM n'est pas une photographie : il se modifie en temps réel, on y fabrique des éléments, on y déplace des blocs entiers, on en retire ce qui ne doit plus s'afficher. La fabrication commence par createElement, qui accepte le nom d'une balise et renvoie un élément neuf, vide et encore détaché de l'arbre. À ce stade, il n'apparaît nulle part : vous le remplissez, puis vous le posez. Remplir se fait avec textContent pour le texte, avec append si le contenu est plus riche, avec setAttribute pour les identifiants, les classes et les descriptions. Poser se fait avec une méthode d'insertion, et c'est là que se joue la différence entre les nœuds voisins que l'on combine.

```javascript
const liste = document.getElementById("liste-programme");

const item = document.createElement("li");
item.className = "programme-item";
item.dataset.id = "4";
item.textContent = "16 h 30 — Atelier pratique";

const bouton = document.createElement("button");
bouton.type = "button";
bouton.className = "desinscription";
bouton.textContent = "Se désinscrire";
item.append(" ", bouton);

liste.append(item);
liste.prepend(item);
item.before(liste.children[1]);
item.after(document.createTextNode(" "));
item.remove();
```

La famille des méthodes d'insertion se lit comme un vocabulaire de position. append ajoute à la fin et accepte plusieurs contenus à la fois, des nœuds comme des fragments de texte, sans mettre à la chaîne. prepend insère au début. before et after placent le contenu avant ou après l'élément lui-même, ce qui permet d'insérer au cœur d'une structure sans connaître le parent. replaceWith substitue. appendChild reste valable, mais elle n'accepte qu'un seul nœud et renvoie ce nœud, ce qui la rend plus rigide que append. Une méthode à manier avec précaution est insertAdjacentHTML, qui interprète une chaîne de balisage à une position donnée : pratique pour un gabarit écrit par vous, à éviter absolument avec une donnée extérieure, pour les raisons de sécurité évoquées à la section précédente.

Le déplacement mérite une démonstration parce qu'il contredit l'intuition. Quand vous insérez dans l'arbre un élément qui appartient déjà ailleurs, le navigateur ne le copie pas : il l'extrait de son ancien foyer et le repose au nouveau. Le même geste sert donc à déplacer, à réordonner et à ramener dans le flux un élément temporairement mis de côté. C'est ainsi que l'on trie une liste, que l'on fait passer un élément d'une colonne à une autre ou que l'on réutilise un élément conservé en mémoire plutôt que d'en recréer un. Si vous souhaitez en revanche conserver l'original, demandez une copie avec cloneNode en lui passant la valeur true, qui duplique l'élément et toute sa descendance. Sans cet argument, seul l'élément lui-même est reproduit, enfants compris rien.

La suppression est la plus simple des opérations : un appel à remove retire l'élément de l'arbre et le laisse pour de bon, à moins que vous n'en ayez conservé une référence ailleurs. Une référence vers un élément supprimé reste valide en mémoire, mais l'élément n'apparaît plus à l'écran et n'est plus touché par les événements de la page. Pour vider un conteneur entier, deux approches coexistent : retirer ses enfants un par un, ou remplacer le contenu par une chaîne vide. La seconde est plus courte, la première préserve les écouteurs attachés aux enfants si vous les réinsérez plus tard. Dans tous les cas, pensez à la conséquence visible d'une suppression : si l'élément retiré portait le focus, la personne qui utilisait le clavier se retrouve nulle part, et c'est à vous de rendre la main à l'utilisateur en donnant le focus à un élément voisin.

- Fabriquez avec createElement, remplissez, puis insérez : un élément neuf n'apparaît nulle part.
- append, prepend, before et after couvrent toutes les positions d'insertion.
- Insérer un élément existant le déplace, il n'est jamais dupliqué.
- cloneNode avec l'argument true duplique l'élément et toute sa descendance.
- remove détache définitivement : gardez une référence si vous prévoyez de réinsérer.
- Après une suppression, rendez le focus à un élément voisin pour ne pas perdre l'utilisateur au clavier.
$lesson$),
  ('web-c3-p7', 'web-c3', 7, $lesson$Événements : addEventListener, propagation et délégation$lesson$, $lesson$
Attacher un gestionnaire d'événements, c'est déclarer au navigateur : quand ce fait se produit sur cet élément, appelle cette fonction. La méthode addEventListener prend le nom de l'événement, puis la fonction à exécuter, puis éventuellement un objet d'options. La fonction reçoit automatiquement un objet qui décrit ce qui vient de se produire, et c'est cet objet qui rend votre code réactif plutôt qu'aveugle. Deux habitudes à prendre immédiatement. D'abord, nommez vos gestionnaires : une fonction déclarée puis réutilisée reste récupérable, ce qui devient indispensable si vous devez retirer l'écouteur. Ensuite, souvenez-vous que le retrait exige exactement la même référence : passer une nouvelle fonction de même corps ne retire rien, et votre écouteur continue de tourner.

```javascript
const boutonInscription = document.getElementById("inscrire");

function gererInscription(event) {
  console.log("Bouton pressé :", event.target.id);
  console.log("Touche :", event.key);
}

boutonInscription.addEventListener("click", gererInscription);

document.getElementById("courriel").addEventListener(
  "input",
  function (event) {
    console.log("Valeur en cours :", event.target.value);
  },
  { once: false }
);
```

L'objet d'événement transporte les informations utiles. La propriété target désigne l'élément d'origine, celui qui a déclenché le fait, tandis que currentTarget désigne l'élément sur lequel vous avez attaché l'écouteur : la distinction devient capitale dès que vous montez d'un niveau dans l'arbre. La propriété type donne le nom de l'événement, et pour les claviers la propriété key indique la touche, sous la forme d'une chaîne comme Escape ou Enter. Quand l'événement porte une action par défaut, comme la soumission d'un formulaire ou le suivi d'un lien, la méthode preventDefault l'annule : le formulaire cesse d'envoyer, le lien cesse de naviguer, et votre script prend la main. Cette méthode n'empêche pas la remontée de l'événement, elle désactive seulement le comportement natif. Parmi les options, once déclenche l'écouteur une seule puis le retire, et capture déplace l'écouteur sur le premier passage de l'événement, celui qui descend.

Pour comprendre ce que recouvre cette idée de passage, il faut savoir comment un événement circule dans l'arbre. Quand vous cliquez sur un bouton enfoui dans une section, l'événement n'apparaît pas magiquement sur la section : il est d'abord délivré à la cible, puis il remonte vers le haut en touchant chaque ancêtre, jusqu'à la racine. Ce trajet comporte trois phases : la descente, où l'événement descend des racines vers la cible en activant les écouteurs captifs ; la cible, où il est remis à l'élément visé ; la remontée, dite phase de bulles, où il revient vers le haut et déclenche les écouteurs ordinaires. Le schéma suivant résume le trajet complet.

```text
Descente (capture) :   document -> html -> body -> section -> bouton
Cible :                bouton   (l'événement est délivré)
Remontée (bulles) :    bouton -> section -> body -> html -> document

Par défaut, un écouteur posé sur section s'exécute APRÈS celui du bouton,
car il appartient à la phase de bulles. L'option { capture: true } inverse
l'ordre : l'écouteur de section s'exécute alors AVANT celui du bouton.
```

Cette remontée n'est pas un détail de spécification : elle est le fondement de la délégation d'événements. Plutôt que d'attacher un écouteur sur chacun des boutons d'une liste, vous en attachez un seul sur le conteneur, et à chaque exécution vous déterminez à partir de la cible quel élément a réellement été visé. L'opérateur closest fait ce travail proprement : appliqué à l'événement, il remonte l'arbre jusqu'au premier ancêtre qui correspond au sélecteur, ce qui vous donne le bouton ou la ligne concernés même si le clic est tombé sur une icône à l'intérieur. Les avantages sont triples, et ils se vérifient d'un coup d'œil dans le mini-projet. Le nombre d'écouteurs reste constant, donc la mémoire consommée aussi. Les éléments ajoutés plus tard fonctionnent immédiatement, sans réattachement. Et la logique reste concentrée dans une seule fonction, plus facile à relire et à corriger.

```javascript
const liste = document.getElementById("liste-inscriptions");

liste.addEventListener("click", function (event) {
  const bouton = event.target.closest("button.desinscription");
  if (!bouton || !liste.contains(bouton)) return;

  const ligne = bouton.closest("li");
  ligne.remove();
  majCompteur();
});
```

Il reste à connaître les événements que vous utiliserez le plus souvent, et leur domaine respectif. Le clic convient à tout ce qui se déclenche avec une souris ou un doigt. L'événement input se déclenche à chaque modification de la valeur d'un champ, y compris au collage, ce qui en fait le bon outil pour une validation en direct. L'événement change ne survient qu'au moment où la valeur est validée, typiquement quand on quitte un champ ou qu'on coche une case. L'événement submit porte la tentative d'envoi d'un formulaire. keydown capte l'enfoncement d'une touche, ce qui permet de répondre à la touche d'échappement pour fermer une zone. focus et blur suivent l'entrée et la sortie du clavier. Enfin, l'événement DOMContentLoaded annonce la fin de l'analyse du document : c'est le signal que votre script attend s'il doit fonctionner même sans l'attribut defer.

- Attachez avec addEventListener, en conservant la fonction pour pouvoir la retirer.
- target désigne l'élément d'origine, currentTarget celui qui porte l'écouteur.
- preventDefault annule le comportement natif sans empêcher la remontée de l'événement.
- Un événement descend en capture, est délivré à la cible, puis remonte en bulles.
- La délégation pose un écouteur sur un ancêtre et identifie la cible avec closest.
- Un écouteur délégué couvre aussi les éléments créés après coup, sans réattachement.
- input pour la saisie en direct, change pour la validation, submit pour l'envoi, keydown pour le clavier.
$lesson$),
  ('web-c3-p8', 'web-c3', 8, $lesson$Le formulaire d'inscription : validation en direct$lesson$, $lesson$
Le formulaire de votre atelier possède déjà la validation native du navigateur : le type courriel vérifie le format, l'attribut required refuse un champ vide, et l'envoi est bloqué tant que les règles ne sont pas satisfaites. Cette protection reste indispensable, mais elle intervient trop tard pour être confortable : elle se déclenche au moment de l'objectif, quand la personne a fini de saisir et appuie sur le bouton. La validation en direct inverse le rythme. Elle vérifie pendant la frappe, elle affiche un message explicite sous le champ, elle met à jour l'état du champ lui-même, et elle laisse la personne corriger avant même d'avoir pensé à envoyer. Pour la médiathèque, cela signifie qu'un visiteur sait immédiatement s'il a oublié l'arobase ou terminé son adresse par point-net au lieu de point-fr, sans jamais subir une page rechargée.

```javascript
const champ = document.getElementById("courriel");
const message = document.getElementById("erreur-courriel");
const form = document.getElementById("form-inscription");

const motif = /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i;

function validerCourriel() {
  const valeur = champ.value.trim();

  if (valeur === "") {
    message.textContent = "";
    champ.removeAttribute("aria-invalid");
    return false;
  }

  if (!motif.test(valeur)) {
    message.textContent = "Adresse incomplète : vérifiez l'arobase et le domaine.";
    champ.setAttribute("aria-invalid", "true");
    return false;
  }

  message.textContent = "Adresse valide.";
  champ.removeAttribute("aria-invalid");
  return true;
}

champ.addEventListener("input", validerCourriel);

form.addEventListener("submit", function (event) {
  if (!validerCourriel()) {
    event.preventDefault();
    champ.focus();
  }
});
```

Trois détails de cet extrait demandent une explication, parce qu'ils font la différence entre une validation qui paraît écrite et une validation réellement utilisable. Le premier concerne le champ vide : dès que la valeur nettoyée est vide, aucun message ne s'affiche et l'attribut d'invalidité est retiré. Signaler une erreur à chaque fois qu'une personne commence à taper serait à la fois faux et agressif ; on réserve donc l'alerte à un contenu présent mais incorrect, tout en laissant l'attribut required se charger de l'obligation à l'envoi. Le deuxième tient à la fonction qui renvoie un booléen : elle sert à la fois au déclenchement pendant la frappe et à la vérification finale dans le gestionnaire d'envoi, sans dupliquer la logique. Le troisième est la ligne qui empêche l'envoi : tant que la vérification échoue, l'action par défaut est annulée, le focus revient au champ fautif, et l'utilisateur reste exactement là où il faut corriger.

Le message d'erreur mérite lui aussi une construction particulière, car un texte qui apparaît et disparaît à l'écran n'est pas automatiquement entendu. La zone de message porte une région live, déclarée par l'attribut aria-live valorisé polite, accompagné d'un rôle de statut. La conséquence concrète : quand le contenu change, l'outil de lecture annonce la nouvelle version après la phrase en cours, sans interrompre ce que la personne était en train d'écouter. Un autre attribut relie le champ à son message : aria-describedby, dont la valeur reprend l'identifiant de la zone de message, fait de ce texte la description annoncée à chaque prise de focus sur le champ. Ajoutez aria-invalid, déjà utilisé dans l'exemple, qui déclare l'état du champ aux technologies d'assistance, et vous obtenez un formulaire dont l'état est aussi lisible à l'oreille qu'à l'œil.

```html
<div class="champ">
  <label for="courriel">Adresse électronique</label>
  <input type="email" id="courriel" name="courriel"
         autocomplete="email" aria-describedby="erreur-courriel">
  <p id="erreur-courriel" role="status" aria-live="polite"></p>
</div>
```

Une dernière précaution porte sur la confiance. La validation côté client est une aide à la saisie, jamais une garantie : n'importe qui peut désactiver son script, envoyer le formulaire à la main ou appeler votre adresse directement. Toute règle de sécurité, tout contrôle d'autorisation, tout calcul qui engage des ressources doit être revérifié côté serveur. Dans le cas de votre atelier, le serveur contrôlera à nouveau le format de l'adresse, l'unicité de l'inscription et le nombre de places restantes avant d'enregistrer quoi que ce soit. La validation en direct n'en reste pas moins utile : elle réduit les erreurs, elle raccourcit les échanges, elle améliore l'expérience, mais elle ne remplace pas la vérification d'origine.

- Validez pendant la frappe avec l'événement input, pas seulement à l'envoi.
- Ignorez le champ vide : l'obligation appartient à l'attribut required, l'erreur à un contenu mal formé.
- Annoncez le message avec aria-live valorisé polite et décrivez le champ avec aria-describedby.
- Marquez l'état du champ avec aria-invalid pour les lecteurs d'écran.
- Dans le gestionnaire d'envoi, annulez l'action par défaut tant que la vérification échoue.
- La validation côté client aide l'utilisateur ; elle ne garantit jamais rien au serveur.
$lesson$),
  ('web-c3-p9', 'web-c3', 9, $lesson$dataset et états d'interface$lesson$, $lesson$
Le HTML permet d'écrire des données directement dans les balises sous forme d'attributs libres préfixés par data-. Le script les relit par la propriété dataset, qui transforme automatiquement les tirets du nom en majuscules : l'attribut data-etat devient dataset.etat, l'attribut data-place-ouverte devient dataset.placeOuverte. Cette mécanique sert à deux usages distincts. Elle configure un composant : un bouton porte data-cible="programme" et sait ainsi quelle zone ouvrir. Elle mémorise un état : une carte garde data-etat="ouverte" ou data-etat="fermee", et votre code décide de la suite en lisant cette valeur. L'avantage de passer par le balisage plutôt que par une variable isolée est que l'information reste attachée à l'élément, visible dans l'inspecteur, survivre à la destruction d'une variable locale et se retrouver au bon endroit quand plusieurs zones de la page cohabitent.

```javascript
const bouton = document.getElementById("bascule-programme");
const zone = document.getElementById("programme");

bouton.addEventListener("click", function () {
  const ouvert = bouton.dataset.etat === "ouvert";
  const prochainEtat = ouvert ? "ferme" : "ouvert";

  bouton.dataset.etat = prochainEtat;
  bouton.setAttribute("aria-expanded", String(!ouvert));
  bouton.textContent = ouvert ? "Afficher le programme" : "Masquer le programme";

  zone.hidden = ouvert;
});
```

Les états d'interface forment un second vocabulaire, aussi important que le premier, parce qu'ils sont le seul canal par lequel un outil de lecture comprend ce que vos yeux perçoivent. L'attribut aria-expanded, porté par un bouton ou un lien qui déplie une zone, dit à la personne si la zone correspondante est actuellement ouverte. Il doit être mis à jour à chaque bascule : un bouton qui ouvre mais annonce toujours la fermeture ment plus qu'il n'aide. L'attribut hidden retire complètement un élément de l'affichage et de l'arbre d'accessibilité, ce qui convient à une zone réellement absente. L'attribut disabled rend un bouton inactif et l'écarte de l'ordre de tabulation, idéal pour un envoi impossible tant que la saisie est invalide ; son équivalent tolérant, aria-disabled valorisé false ou true, conserve l'élément focalisable tout en signalant l'inactivité, ce qui permet d'expliquer la raison plutôt que de faire disparaître le contrôle.

```table
Attribut ou propriété | Ce qu'il exprime | Quand le mettre à jour
--- | --- | ---
data- dans le balisage, dataset en JavaScript | Donnée de configuration ou état mémorisé | À chaque changement d'état
aria-expanded | Zone dépliée ou repliée | À chaque bascule d'ouverture
hidden | Élément absent de l'affichage | Quand la zone disparaît complètement
disabled | Contrôle inactif et non focalisable | Quand la saisie devient invalide ou épuisée
aria-invalid | Champ sais incorrectement | À chaque contrôle de validité
aria-pressed | Bouton bascule actif ou non | À chaque appui sur la bascule
```

Cette discipline a une conséquence positive sur l'architecture de votre code : elle vous oblige à nommer les états. Plutôt que de tester simultanément la classe, la visibilité et le libellé d'un bouton, vous décidez d'une source de vérité unique, dataset ou attribut, et vous dérivez tout le reste. Le script met à jour cette source, puis une fonction unique répercute les conséquences visuelles et accessibles. Le code devient plus court, les incohérences disparaissent, et l'inspecteur du navigateur affiche l'état réel de la page en un coup d'œil. Notez enfin que les boutons et les liens sont déjà des contrôles natifs : ils répondent à la souris, au clavier et aux écrans tactiles, ils sont annoncés comme des commandes, et ils n'exigent aucun gestionnaire supplémentaire pour réagir à la touche Entrée ou à la barre d'espace. C'est une raison de plus de préférer un vrai bouton à une div habillée en bouton.

- Les attributs data- deviennent dataset, avec les tirets convertis en majuscules.
- dataset convient à la configuration d'un composant et à la mémorisation de son état.
- aria-expanded doit être réactualisé à chaque ouverture ou fermeture.
- hidden retire l'élément de l'affichage, disabled l'écarte de l'ordre de tabulation.
- Gardez une source de vérité unique pour l'état et dérivez-en le reste.
- Utilisez de vrais boutons : ils gèrent nativement clavier, tactile et lecteur d'écran.
$lesson$),
  ('web-c3-p10', 'web-c3', 10, $lesson$Bonnes pratiques : performance, accessibilité et séparation des rôles$lesson$, $lesson$
Écrire du JavaScript qui marche est la première étape ; écrire du JavaScript qui tient dans la durée suppose quelques réflexes installés dès le début. Le premier concerne les performances, et il repose sur un fait simple : lire la géométrie d'un élément, sa position ou sa largeur, force le navigateur à figer la mise en page, et écrire juste après déclenche un nouveau calcul. Alterner lectures et écritures au sein d'une boucle multiplie ces recalculs et ralentit l'interface, surtout sur une page longue. La correction consiste à séparer les deux temps : on lit d'abord toutes les valeurs nécessaires, on les garde en mémoire, puis on écrit. Le second réflexe est le coût des sélections : interroger l'arbre au sein d'une boucle qui s'exécute cent fois revient à cent recherches inutiles, alors qu'une seule constante en dehors de la boucle suffit. Cachez les références que vous réutilisez, composez vos modifications, et laissez la feuille de style faire ce qu'elle sait faire mieux que le script.

```table
Pratique | Bénéfice concret | Symptôme en cas d'oubli
--- | --- | ---
Lire puis écrire en deux temps | Un seul recalcul de mise en page | Interface saccadée pendant les mises à jour
Mettre les références en constante | Une seule recherche dans l'arbre | Code lent dans les boucles
Déléguer un écouteur au conteneur | Mémoire et écouteurs constants | Lenteur quand la liste grandit
Décrire l'état avec des classes | Le CSS décide, le script commande | Styles en ligne dispersés et introuvables
Préférer textContent | Aucune interprétation de balisage | Faille d'injection avec les saisies
```

Le second réflexe porte sur l'accessibilité, et il s'articule autour d'une idée : tout ce que vous ajoutez doit rester utilisable sans souris et perceptible sans voir l'écran. Un contrôle ajouté dynamiquement doit être de vraie balise de commande, jamais une boîte habillée, pour que la touche Entrée et la barre d'espace le déclenchent. Un élément qui apparaît doit recevoir le focus ou être annoncé, sinon la personne qui navigue au clavier ne sait pas que quelque chose a changé. Un contenu qui se met à jour en continu, comme votre compteur de places, doit être déclaré comme région live, ce qui fait annoncer la nouvelle valeur sans voler la parole. Vérifiez enfin chaque état visuel : si la seule indication d'un champ invalide est un liseré rouge, une personne qui ne distingue pas les couleurs ne verra rien ; associez toujours le signe visuel à un texte, et ce texte est précisément celui que votre validation en direct affiche déjà.

Le troisième réflexe concerne l'organisation du code, là où la plupart des premiers scripts finissent par devenir ingérables. Séparez les responsabilités comme vous l'avez fait entre le HTML et le CSS : une fonction ne devrait faire qu'une chose, sélectionner et attacher ne devrait pas se mélanger au calcul métier, et la présentation reste dans la feuille de style. Nommez vos fonctions avec un verbe à l'infinitif qui décrit l'action, majCompteur ou validerCourriel, et vos variables avec un nom qui dit ce qu'elles contiennent plutôt que leur type. Évitez les variables globales, qui peuvent être écrasées depuis n'importe quel autre fichier de la page : regroupez votre logique dans un bloc, utilisez des constantes pour les valeurs fixes comme le nombre total de places, et reliez vos fichiers avec l'attribut defer ou avec un module. Enfin, gardez les attributs d'événement hors du balisage : ils appartiennent au HTML autant que les couleurs appartiennent au CSS.

- Séparez les lectures et les écritures pour ne déclencher qu'un seul recalcul de mise en page.
- Stockez les références réutilisées en constante, hors des boucles.
- Tout contrôle ajouté doit être une balise de commande réellement utilisable au clavier.
- Annoncez les changements importants avec une région live, en particulier le compteur.
- Ne faites jamais reposer une information essentielle sur la seule couleur.
- Une fonction fait une chose, un nom de fonction commence par un verbe, les globales sont proscrites.
$lesson$),
  ('web-c3-p11', 'web-c3', 11, $lesson$Déboguer : console, point d'arrêt et outils$lesson$, $lesson$
Déboguer n'est pas un aveu d'échec, c'est le métier quotidien du développeur : un script qui ne se comporte pas comme prévu vous donne une information, et votre travail consiste à la recueillir méthodiquement. La première règle est de résister à la tentation de relire tout le fichier en cherchant l'erreur à l'œil. Ouvrez la console, lisez le message, repérez la ligne, puis revenez au code avec une hypothèse précise. Le navigateur est généralement bavard : il nomme la propriété incriminée, donne le type de valeur trouvé et indique le numéro de ligne. Une erreur non interceptée arrête l'exécution du bloc en cours, si bien que les symptômes que vous observez, un compteur qui ne bouge pas ou un bouton qui ne répond pas, proviennent souvent d'un échec survenu bien avant, dans un fichier ou sur une ligne que vous n'observiez même plus.

```javascript
console.log("Valeur saisie :", champ.value, "type :", typeof champ.value);
console.warn("Sélecteur introuvable : #compteur-2");
console.error("Échec de la validation");
console.table([
  { nom: "Camille", statut: "inscrite" },
  { nom: "Moussa", statut: "en attente" }
]);

try {
  const element = document.getElementById("inexistant");
  element.textContent = "boom";
} catch (erreur) {
  console.error("Rattrapé :", erreur.message);
}
```

La console possède d'autres outils que le simple journal. console.table rend un tableau de données lisible d'un coup d'œil, console.dir développe un objet dans son détail alors que console.log en donne une représentation condensée, et console.time puis console.timeEnd mesurent le temps écoulé entre deux points, indispensable pour comparer deux approches d'une même opération. Essayez la vérification inverse avant de conclure : affichez le type d'une valeur, affichez la sélection elle-même plutôt que ce que vous en tirez, et vérifiez que la fonction que vous croyez appeler existe bien. Une part écrasante des erreurs de débutant se résume à trois situations : une sélection qui renvoie rien parce que le sélecteur comporte une faute, une tentative d'appeler une fonction mal orthographiée, et un accès à une propriété d'un objet absent.

Quand la console ne suffit plus, un outil plus précis attend dans l'onglet des sources : le point d'arrêt. Placez la ligne debugger dans votre code, rechargez la page, et l'exécution se fige à cet endroit exact. Vous pouvez alors avancer ligne à ligne, entrer dans une fonction pour voir ce qu'elle fait réellement ou en sortir d'un pas, et surtout observer le panneau des portées, qui affiche la valeur courante de chaque variable accessible à ce moment précis. C'est la réponse à la question que se posent tous les débutants : au moment où le code s'arrête, que contiennent mes variables ? Le même effet s'obtient en cliquant dans la gouttière de l'éditeur de code, et un point d'arrêt conditionnel, qui ne déclenche que si une expression est vraie, permet de n'interrompre que les cas qui posent problème. Une fois le comportement compris, retirez le point d'arrêt : un code qui s'arrête en plein parcours lors d'une démonstration n'est jamais très impressionnant.

Deux onglets complètent utilement le diagnostic. L'onglet des éléments montre l'arbre réel de la page pendant que vous interagissez : vous voyez la classe apparaître, l'attribut d'état basculer, le texte se remplacer, ce qui vous confirme que le script agit bien sur l'élément attendu. L'onglet réseau répond à une autre question : votre fichier de script a-t-il été demandé, et avec quel résultat ? Un chemin de fichier erroné renvoie une erreur quatre cent quatre et votre code n'est jamais exécuté, sans que rien d'autre ne signale le problème. Ces deux contrôles, combinés à la lecture attentive du message, résolvent la grande majorité des incidents que vous rencontrerez dans ce chapitre.

- Lisez d'abord le message de la console, regardez le code ensuite : il nomme souvent la ligne.
- Une erreur arrête la suite du bloc : les symptômes visibles ne sont pas toujours la cause.
- console.table, console.dir et console.time donnent des vues plus parlantes qu'un simple journal.
- Le mot debugger fige l'exécution et révèle la valeur de chaque variable à cet instant.
- Vérifiez dans l'onglet réseau que le fichier de script est bien chargé.
- Inspectez l'arbre dans l'onglet éléments pour confirmer que la modification atteint le bon élément.
- Retirez journaux et points d'arrêt une fois le comportement corrigé.
$lesson$),
  ('web-c3-p12', 'web-c3', 12, $lesson$Mini-projet guidé : les inscriptions de l'atelier en direct$lesson$, $lesson$
Toutes les pièces sont sur la table : sélection, modification, création, suppression, événements, délégation, validation et états. Le moment est venu de les assembler dans un seul script qui rend votre atelier.html réellement vivant. Le cahier des charges tient en cinq exigences, et chacune correspond à une section de cette leçon. Un compteur annonce les places restantes et se met à jour à chaque inscription ou désinscription. La saisie de l'adresse électronique est vérifiée à chaque frappe, avec un message affiché sous le champ et annoncé aux technologies d'assistance. Une nouvelle ligne peut être ajoutée au programme sans recharger la page. Chaque inscrit dispose d'un bouton de retrait, et ces boutons sont gérés par un écouteur unique posé sur la liste plutôt que par autant d'écouteurs que de lignes. Enfin, le bouton d'envoi se désactive quand plus aucune place ne reste.

```html
<main>
  <section id="suivi">
    <h2>Suivi des inscriptions</h2>
    <p id="compteur" role="status" aria-live="polite">12 places restantes sur 12</p>
    <ul id="liste-inscriptions"></ul>
  </section>

  <section id="inscription">
    <h2>Inscription</h2>
    <form id="form-inscription">
      <label for="courriel">Adresse électronique</label>
      <input type="email" id="courriel" name="courriel"
             autocomplete="email" required aria-describedby="erreur-courriel">
      <p id="erreur-courriel" role="status" aria-live="polite"></p>
      <button type="submit" id="inscrire">S'inscrire</button>
    </form>
  </section>

  <section id="programme">
    <h2>Programme</h2>
    <ul id="liste-programme">
      <li>14 h — Accueil des participants</li>
      <li>14 h 30 — Prise en main du langage</li>
    </ul>
    <label for="intitule">Nouvelle séance</label>
    <input type="text" id="intitule" name="intitule">
    <button type="button" id="ajouter-programme">Ajouter au programme</button>
  </section>
</main>
```

Le balisage ci-dessus apporte déjà une part du travail. La région live du compteur et celle du message d'erreur sont déclarées, ce qui suffit pour que leurs changements soient annoncés. Les étiquettes sont associées à leurs champs, les boutons sont de vrais boutons, et la liste d'inscriptions est vide au départ : elle se remplira par le script, ce qui vous donne immédiatement l'occasion d'appliquer la délégation à des éléments qui n'existaient pas au chargement. Le choix du validateur natif reste en place, avec l'attribut required sur le champ : un champ laissé vide sera refusé par le navigateur lui-même, tandis que votre vérification, plus stricte, prend le relais pour les adresses présentes mais mal formées.

```javascript
const TOTAL_PLACES = 12;

const compteur = document.getElementById("compteur");
const listeInscriptions = document.getElementById("liste-inscriptions");
const listeProgramme = document.getElementById("liste-programme");
const champCourriel = document.getElementById("courriel");
const message = document.getElementById("erreur-courriel");
const form = document.getElementById("form-inscription");
const champIntitule = document.getElementById("intitule");
const boutonInscrire = document.getElementById("inscrire");

const motif = /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i;

function majCompteur() {
  const restantes = TOTAL_PLACES - listeInscriptions.querySelectorAll("li").length;
  compteur.textContent = restantes + " places restantes sur " + TOTAL_PLACES;
  boutonInscrire.disabled = restantes === 0;
}

function validerCourriel() {
  const valeur = champCourriel.value.trim();
  if (valeur === "") {
    message.textContent = "";
    champCourriel.removeAttribute("aria-invalid");
    return false;
  }
  const valide = motif.test(valeur);
  message.textContent = valide
    ? "Adresse valide, vous pouvez envoyer."
    : "Adresse incomplète : vérifiez l'arobase et le domaine.";
  if (valide) {
    champCourriel.removeAttribute("aria-invalid");
  } else {
    champCourriel.setAttribute("aria-invalid", "true");
  }
  return valide;
}

function creerLigneInscription(adresse) {
  const item = document.createElement("li");
  item.dataset.adresse = adresse;
  item.append(adresse + " ");

  const bouton = document.createElement("button");
  bouton.type = "button";
  bouton.className = "desinscription";
  bouton.textContent = "Se désinscrire";
  item.append(bouton);

  listeInscriptions.append(item);
}

champCourriel.addEventListener("input", validerCourriel);

form.addEventListener("submit", function (event) {
  event.preventDefault();
  if (!validerCourriel()) {
    champCourriel.focus();
    return;
  }
  creerLigneInscription(champCourriel.value.trim());
  champCourriel.value = "";
  message.textContent = "Inscription enregistrée.";
  majCompteur();
});

listeInscriptions.addEventListener("click", function (event) {
  const bouton = event.target.closest("button.desinscription");
  if (!bouton) return;
  bouton.closest("li").remove();
  majCompteur();
});

document.getElementById("ajouter-programme").addEventListener("click", function () {
  const texte = champIntitule.value.trim();
  if (texte === "") return;

  const item = document.createElement("li");
  item.textContent = texte;

  const bouton = document.createElement("button");
  bouton.type = "button";
  bouton.className = "retirer";
  bouton.textContent = "Retirer";
  item.append(" ", bouton);

  listeProgramme.append(item);
  champIntitule.value = "";
  champIntitule.focus();
});

listeProgramme.addEventListener("click", function (event) {
  const bouton = event.target.closest("button.retirer");
  if (bouton) bouton.closest("li").remove();
});

majCompteur();
```

Lisez ce script en suivant le fil des responsabilités plutôt que sa longueur. Le haut du fichier déclare les références et le motif de validation, en dehors de toute fonction, pour ne les chercher qu'une fois. Trois petites fonctions assument chacune une tâche : mettre le compteur à jour, valider la saisie, fabriquer une ligne d'inscription. Le reste n'est que des attachements d'écouteurs, tous posés au chargement du document, ce qui est sans risque puisque le script s'exécute après l'analyse de la page, que l'attribut defer le place en tête de fichier ou que le bloc figure à la fin du corps. Les deux listes sont gérées par délegation : un seul écouteur chacune, une recherche avec closest, une action. Les lignes créées après coup fonctionnent sans rien réattacher, et c'est exactement l'avantage que vous constaterez en ajoutant plusieurs inscriptions d'affilée.

La dernière étape est la vérification, qui se fait en trois minutes et en cinq gestes. Saisissez une adresse sans arobase et observez le message apparaître, puis corrigez et voyez-le passer au vert : pendant ce temps, l'outil de lecture doit annoncer les deux changements. Envoyez, et vérifiez que la ligne rejoint la liste et que le compteur décrémente. Retirez un inscrit et constatez que le compteur remonte. Ajoutez une séance au programme, retirez-la, puis retirez-la aussi avec le bouton de retrait, ce qui vous confirmera que chaque liste possède bien son propre écouteur délégué. Enfin, atteignez zéro place et confirmez que le bouton d'envoi s'inactive, avant de recharger la page pour repartir de zéro. Si les cinq gestes passent, le chapitre est acquis.

- Regroupez en haut du script les références réutilisées et les valeurs constantes.
- Isolez la logique dans de petites fonctions nommées par l'action qu'elles font.
- Attachez les écouteurs une fois au chargement, pas à chaque nouvelle ligne créée.
- Utilisez closest pour remonter de la cible jusqu'au bouton ou à la ligne visés.
- Annoncez les changements d'état dans les régions live déjà déclarées dans le balisage.
- Testez le cas limite : zéro place, adresse vide, adresse mal formée, ligne créée puis retirée.
$lesson$),
  ('web-c3-p13', 'web-c3', 13, $lesson$À retenir$lesson$, $lesson$
- Le HTML décrit, le CSS habille, le JavaScript anime : chaque technologie garde son rôle.
- Le script s'exécute après l'analyse de la page : attribut defer en tête, ou balise script en fin de corps.
- La console est le premier outil de diagnostic : un message rouge nomme souvent la ligne fautive.
- Le navigateur construit un arbre en mémoire, le DOM, dont document est la porte d'entrée.
- La fenêtre contient le document : la fenêtre parle de l'onglet, le document parle de la page.
- Une opération commence toujours par une sélection : getElementById, querySelector, querySelectorAll.
- Une sélection ratée renvoie la valeur vide, et accéder à ses propriétés déclenche une erreur.
- Modifiez le texte avec textContent ; réservez innerHTML au balisage que vous maîtrisez.
- Gérez les classes avec classList : add, remove, toggle et contains remplacent l'écriture directe.
- La valeur d'un champ, l'état coché et l'inactivité se règlent en propriétés, pas en attributs.
- createElement fabrique, append et prepend placent, remove détache, cloneNode copie.
- Insérer un élément existant le déplace : un seul geste sert à déplacer et à réordonner.
- addEventListener reçoit la cible dans target et l'élément écouté dans currentTarget.
- Un événement descend en capture, est délivré à la cible, puis remonte en bulles.
- La délégation pose un écouteur sur un conteneur et retrouve la cible avec closest.
- Validez pendant la frappe avec input, annulez l'envoi dans submit, annoncez avec aria-live.
- dataset reflète les attributs data- ; aria-expanded, hidden et disabled décrivent les états visibles.
- La validation côté client améliore l'expérience, elle ne remplace jamais le contrôle serveur.
$lesson$),
  ('web-c3-p14', 'web-c3', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : placer un script dans l'en-tête sans defer et sélectionner un élément situé plus bas → Correction : ajoutez defer, ou déplacez le script à la fin du corps.
- Piège : supprimer un gestionnaire en lui passant une nouvelle fonction du même corps → Correction : conservez la référence dans une constante et rendez exactement cette référence.
- Piège : utiliser une propriété de la valeur vide après une sélection ratée → Correction : testez la présence de l'élément avant de le modifier, et vérifiez le sélecteur dans la console.
- Piège : remplacer tout le contenu d'un élément en écrivant dans l'attribut class → Correction : passez par classList, qui n'ajoute ou ne retire que la classe demandée.
- Piège : injecter dans innerHTML une chaîne provenant d'un champ de saisie → Correction : affichez-la avec textContent, qui traite toujours le contenu comme du texte.
- Piège : construire des balises avec des chaînes concaténées et perdre les guillemets → Correction : fabriquez avec createElement et remplissez avec textContent.
- Piège : attacher un écouteur à chaque ligne d'une liste qui grandit → Correction : déléuez au conteneur et identifiez la cible avec closest.
- Piège : oublier preventDefault sur un formulaire et recharger la page à chaque envoi → Correction : annulez l'action par défaut au début du gestionnaire d'envoi.
- Piège : afficher une erreur d'un simple trait rouge, invisible pour certaines personnes → Correction : associez l'état visuel à un texte annoncé dans une région live.
- Piège : changer aria-expanded lors de l'ouverture mais laisser aria-invalid à l'ancienne valeur → Correction : centralisez les mises à jour d'état dans une fonction unique appelée à chaque bascule.
- Piège : croire qu'une validation réussie côté client protège le serveur → Correction : revérifiez toujours au serveur, la saisie pouvant être contournée sans script.
- Piège : laisser des console.log et des points d'arrêt dans le code livré → Correction : retirez les journaux de débogage après vérification, gardez les commentaires utiles.
$lesson$),
  ('web-c3-p15', 'web-c3', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation de Mozilla reste l'endroit où revenir chaque fois qu'un doute se présente sur une méthode du DOM. La page https://developer.mozilla.org/docs/Web/API/Document_Object_Model explique la construction de l'arbre, les types de nœuds et les opérations de parcours, avec des exemples exécutables et des indications à jour sur le support par les navigateurs. Pour les événements, la fiche https://developer.mozilla.org/docs/Web/API/Event décrit l'objet transmis au gestionnaire, les phases de capture et de bulles ainsi que les options avancées, et la fiche https://developer.mozilla.org/docs/Web/API/EventTarget/addEventListener détaille l'attachement et le retrait des écouteurs. Ces pages sont longues : n'essayez pas de les lire d'un bout à l'autre, revenez-y avec une question précise, à la façon d'un dictionnaire.

Côté pratique, le cours Learn JavaScript de web.dev, accessible à l'adresse https://web.dev/learn/javascript/, propose des leçons progressives qui reprennent exactement les notions abordées ici, avec des exercices interactifs et un soin constant porté aux bonnes pratiques. Deux pages MDN complètent utilement la sélection : https://developer.mozilla.org/docs/Web/API/Document/querySelector pour les sélecteurs, y compris les cas particuliers des listes statiques, et https://developer.mozilla.org/docs/Web/Accessibility pour tout ce qui touche à l'interaction au clavier, aux régions live et aux rôles. Prenez enfin l'habitude de conserver la page des événements en favori : la liste des types d'événements disponibles et de leur compatibilité est consultée régulièrement tout au long d'un projet.
$lesson$),
  ('web-c3-p16', 'web-c3', 16, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
L'exercice pratique qui suit cette leçon vous demande d'animer seul la page atelier.html : compteur de places restantes, validation en direct du courriel avec un message annoncé, ajout dynamique d'une ligne au programme, bouton de désinscription piloté par un écouteur délégué. Récrivez le script sans regarder la solution, puis comparez : c'est en confrontant votre version à une version qui fonctionne que vous verrez les habitudes qui vous manquent encore. Le quiz de quatre questions vous permet de vérifier en quelques minutes les notions essentielles, de la place du defer jusqu'à la phase de bulles. Si une question vous surprend, revenez à la section correspondante plutôt que de mémoriser la réponse.

Le parcours se poursuit avec le chapitre suivant, JavaScript applicatif : données et asynchrone, où le même langage quitte l'interface pour traiter des informations. Vous y verrez comment transformer une liste de participants avec map et filter, comment écrire des fonctions réutilisables, puis comment interroger une API avec fetch et async/await pour que votre page affiche un programme réellement alimenté par un serveur. Les sélections et les gestionnaires que vous venez d'écrire serviront de socle : une application moderne n'est rien d'autre qu'un arbre DOM que l'on met à jour en réaction à des données qui arrivent. Gardez donc précieusement votre fichier atelier.html, vous le ferez dialoguer avec un vrai service au chapitre suivant.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('web-c4-p1', 'web-c4', 1, $lesson$Manipuler des tableaux : map, filter, reduce et sort$lesson$, $lesson$
Bienvenue dans le quatrième chapitre du parcours Développement web moderne, le chapitre où le JavaScript cesse d'être un exercice de synthaxe pour devenir un véritable outil de travail. Dans l'atelier de la Médiathèque des Lilas, vous avez jusqu'ici écrit des pages structurées en HTML, habillées en CSS, puis animées par de petits scripts qui réagissaient à des cliccs, affichaient un message et mettaient à jour un compteur. Toutes ces pages partageaient une même limite, discrète mais décisive : leurs données étaient écrites à la main dans le fichier, figées au moment où vous l'aviez enregistré. Un tableau d'inscriptions recopié caractère par caractère, un horaire dupliqué à trois endroits, une liste de séances qui devient fausse dès qu'on ajoute un atelier. Ce chapitre change la donne : vous allez apprendre à faire venir les données de l'extérieur, au moment exact où la page en a besoin, puis à les transformer en information affichable.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées dans du vrai code. Vous transformerez des listes de données avec les méthodes map, filter, reduce et sort, en comprenant précisément laquelle crée un nouveau tableau et laquelle modifie celui que vous lui donnez. Vous écrirez des objets riches, avec déstructuration et propriétés calculées, et vous utiliserez les fonctions fléchées là où elles apportent réellement de la clarté. Vous écrirez des fonctions asynchrones avec async et await, vous consommerez une API REST avec fetch, vous lirez une réponse, vous la convertirez en objet JavaScript et vous gérerez les quatre états qui rythment toute interface connectée : chargement, succès, absence de données et erreur. Vous verrez enfin comment sécuriser un appel avec un délai maximum et une annulation, et vous assembleras le tout dans un mini-projet guidé : le tableau des inscriptions de l'atelier, alimenté par une source de données distante.

Une recommandation sur la manière d'aborder ce chapitre, avant d'entrer dans le vif du sujet. Le JavaScript asynchrone s'apprend comme on apprend à nager : en entrant dans l'eau, pas en lisant un manuel au bord du bassin. Rien ne remplace le geste de recopier chaque exemple dans un fichier, de l'ouvrir dans le navigateur et d'observer ce qui se passe réellement. Ouvrez l'onglet des outils de développement, regardez la console, déclenchez la fonction plusieurs fois, cassez-la volontairement : supprimez un await, oubliez un return, renvoyez une promesse là où on attendait une valeur. Une erreur dans la console n'est pas un échec, c'est un message : le navigateur vous dit exactement où votre raisonnement ne tient pas, et plus vous lirez ces signaux attentivement, plus vous progresserez vite. Nous avancerons par étapes, en alternant explications détaillées, exemples de code commentés et bonnes pratiques issues du développement professionnel.

Le fil rouge reste celui des chapitres précédents : l'atelier de la Médiathèque des Lilas. Jusqu'ici, la page de l'atelier affichait un programme écrit à la main. À partir de maintenant, elle va demander sa liste de séances à un service, attendre la réponse, vérifier qu'elle est correcte, la reformater pour l'écran, filtrer les séances pleines, afficher un indicateur pendant l'attente et proposer un bouton réessayer si le réseau lâche. Chaque notion de ce chapitre correspondra à une brique de ce tableau final. Le projet n'est donc pas un exercice de synthèse posé à la fin : c'est le réceptacle progressif de tout ce que vous allez lire, et vous le reconstruirez seul dans l'exercice pratique qui suit cette leçon.



Les tableaux sont au cœur du développement JavaScript applicatif, pour une raison simple : presque toutes les données qui arrivent d'un service distant se présentent sous la forme d'une liste. Une réponse d'API vous rend un tableau d'objets, un, chacun représentant un enregistrement : une séance, un adhérent, une réservation, une mesure. Votre travail ne consiste presque jamais à afficher cette liste brute telle quelle, mais à la transformer : reformater les dates, ne garder que les séances ouvertes, compter les participants, classer le résultat par ordre alphabétique. Quatre méthodes suffisent à couvrir la très grande majorité de ces besoins, et elles forment un vocabulaire que vous réutiliserez dans chaque projet.

La première est map, la méthode de transformation par excellence. Elle reçoit une fonction, l'applique à chaque élément du tableau, et renvoie un tout nouveau tableau contenant le résultat de cette fonction, longueur pour longueur. Le tableau d'origine n'est jamais touché : vous pouvez appeler map dix fois de suite sur les mêmes données sans les alturer, ce qui rend le code prévisible et facile à déboguer. L'erreur classique consiste à utiliser map pour ses effets de bord, par exemple pour afficher chaque élément dans la page, alors que sa vocation est de produire une valeur. Retenez la question à se poser : est-ce que je veux transformer chaque élément pour obtenir une autre liste ? Si oui, c'est map. Si vous voulez seulement exécuter une action sans résultat, préférez forEach, qui ne renvoie rien.

La seconde est filter, la méthode de sélection. Elle reçoit également une fonction, mais celle-ci doit renvoyer un nombre impair... non, doit renvoyer un booléen : vrai pour garder l'élément, faux pour l'écarter. Le résultat est un nouveau tableau, parfois vide, contenant strictement les éléments pour lesquels la condition est vraie. filter est votre allié dès qu'un écran doit montrer une partie d'un ensemble : les séances encore disponibles, les inscrits ayant réellement participé, les relevés supérieurs à un seuil. La beauté de la combinaison map et filter tient à ce qu'elles s'enchaînent sans effort, puisque chacune renvoie un tableau sur lequel on peut rappeler la méthode suivante. On dit qu'on compose les opérations, et cette composition est le cœur de la programmation fonctionnelle moderne.

La troisième est reduce, la méthode qui surprend toujours un peu au premier abord, parce qu'elle ne renvoie ni un tableau transformé ni un tableau filtré, mais une valeur unique : un nombre, une chaîne, un objet, un total. Elle reçoit une fonction prenant en premier paramètre un accumulateur, c'est-à-dire le résultat partial construit jusqu'ici, et en second paramètre l'élément en cours. On lui passe en plus une valeur initiale pour l'accumulateur, et la fonction est rappelée pour chaque élément jusqu'à épuisement de la liste. On l'utilise pour sommer des montants, pour compter les occurrences d'un statut, pour regrouper des éléments par catégorie, ou pour construire un index. Réduit à sa forme la plus simple, reduce remplace une boucle avec variable d'accumulation, mais il l'explicite : la règle d'accumulation est isolée dans une fonction nommée, ce qui rend le calcul réutilisable et testable.

La quatrième est sort, et elle mérite une mise en garde particulière. À la différence des trois précédentes, elle modifie le tableau sur lequel on l'appelle : elle trie en place, c'est-à-dire qu'elle réordonne réellement les éléments de votre tableau d'origine. De plus, sans fonction de comparaison, elle trie par défaut en convertissant les éléments en chaînes de caractères, ce qui produit un tri alphabétique déroutant pour des nombres : 10 se retrouve avant 2. Pour un tri numérique ou une comparaison sur une propriété, on lui fournit un comparateur recevant deux éléments et renvoyant un nombre négatif, nul ou positif. Si vous ne voulez pas toucher à vos données, copiez le tableau avant de le trier, par exemple avec le spreading entre crochets. La règle tient en une phrase : les trois méthodes de transformation créent, la méthode de tri détruit l'ordre d'origine.

```js
const inscriptions = [
  { prenom: "Nadia", present: true, heures: 3 },
  { prenom: "Marc", present: false, heures: 3 },
  { prenom: "Leila", present: true, heures: 2 },
  { prenom: "Samir", present: true, heures: 4 }
];

const noms = inscriptions.map((i) => i.prenom);
// ["Nadia", "Marc", "Leila", "Samir"]

const presents = inscriptions.filter((i) => i.present);
// trois objets : ceux qui ont réellement participé

const total = inscriptions.reduce((somme, i) => somme + i.heures, 0);
// 12

const parHeures = [...inscriptions].sort((a, b) => a.heures - b.heures);
// tri croissant, sans modifier le tableau de départ

const unPresent = inscriptions.find((i) => !i.present);
// renvoie le premier objet correspondant, ou undefined
```

Il existe enfin un petit jeu de méthodes de lecture que l'on utilise constamment et qu'il vaut mieux connaître dès maintenant. find renvoie le premier élément satisfaisant une condition, ou undefined si aucun ne correspond. some renvoie un booléen qui indique si au moins un élément correspond ; every, si tous correspondent sans exception. Il en existe d'autres, mais cette famille obéit toutes au même contrat : elles reçoivent une fonction de rappel, elles ne modifient pas le tableau, et elles renvoient une valeur exploitable immédiatement. Le tableau ci-dessous résume les quatre méthodes principales et sert de mémo tant que leur comportement n'est pas devenu un réflexe.

```table
Methode | Ce qu'elle renvoie | Modifie le tableau d'origine | Usage principal
--- | --- | --- | ---
map | Un nouveau tableau, même longueur | Non | Reformater chaque ligne avant affichage
filter | Un nouveau tableau, éventuellement vide | Non | Ne garder que les séances disponibles
reduce | Une seule valeur : nombre, texte ou objet | Non | Compter, additionner, regrouper
sort | Le tableau lui-même, réordonné | Oui | Classer par date ou par alphabétique
```

Un conseil de lecture pour vous approprier ces méthodes : reformulez toujours chaque appel en français complet. Devant un filtre, dites à voix haute : je prends la liste des séances et je ne garde que celles dont le nombre d'inscrits est inférieur au nombre de places. Devant un reduce, dites : je pars de zéro et j'ajoute les heures de chaque participant. Cette habitude vous protège des deux écueils classiques, l'oubli de la valeur initiale dans reduce et l'utilisation de map pour un simple effet de bord.

- `map` transforme et renvoie un tableau de même longueur, sans jamais modifier l'original.
- `filter` sélectionne et peut renvoyer un tableau vide : prévoyez cet état dans l'affichage.
- `reduce` agrège en une seule valeur et exige presque toujours une valeur initiale.
- `sort` modifie le tableau : copiez d'abord si vos données doivent rester intactes.
- `find`, `some` et `every` répondent à une question ponctuelle sur la liste.
- Chaque méthode reçoit une fonction de rappel : c'est elle qui porte votre règle métier.
- Enchaînez les méthodes plutôt que d'imbriquer des boucles : le code se lit de gauche à droite.
$lesson$),
  ('web-c4-p2', 'web-c4', 2, $lesson$Objets, déstructuration et propriétés calculées$lesson$, $lesson$
Les données qui arrivent d'un service distant sont presque toujours des objets : une séance possède un identifiant, un titre, une date, un nombre de places ; un relevé météo possède une température, une heure, une vitesse de vent. Comprendre comment lire, copier et enrichir ces objets est donc aussi important que savoir les tableaux. Un objet regroupe des propriétés nommées, chacune associée à une valeur qui peut être un nombre, du texte, un booléen, un tableau, un autre objet ou une fonction. On accède à une propriété avec la notation par point quand le nom est connu à l'écriture, et avec la notation par crochets quand le nom est calculé à l'exécution, par exemple lorsqu'il vient d'une variable ou de la saisie de l'utilisateur.

La déstructuration est le raccourci qui rend le code lisible. Elle permet de déclarer en une seule ligne autant de variables qu'il y a de propriétés à extraire, en écrivant les noms souhaités entre crochets à gauche de l'affectation. Elle accepte deux extensions que vous utiliserez souvent : l'alias, qui renomme la variable au moment de l'extraction, et la valeur par défaut, qui prend le relais quand la propriété est absente de l'objet. Cette seconde extension est précieuse avec des données externes, dont vous ne contrôlez pas la complétude : plutôt que de tester chaque propriété avec une condition, vous laissez la déstructuration fournir un repli raisonnable.

```js
const seance = {
  id: "S-101",
  titre: "Initiation HTML",
  places: 12,
  inscrits: 9,
  meta: { salle: "Salle 2", duree: 180 }
};

const { titre, places, inscrits = 0 } = seance;
const { titre: libelle } = seance;
const { meta: { salle } } = seance;

const restantes = places - inscrits;
const complet = inscrits >= places;

const fiche = {
  ...seance,
  restantes,
  complet,
  ["ligne_" + seance.id]: true
};

console.log(libelle, salle, restantes, complet);
```

Les propriétés calculées, écrites entre crochets dans la définition d'un objet, résolvent un problème très concret : construire une clé qui dépend d'une valeur. Sans elles, on écrirait une affectation séparée, par exemple en assignant la propriété après la création de l'objet. Avec elles, la clé est produite au moment de la déclaration, ce qui donne des structures régulières : un index par identifiant, un compteur par statut, un regroupement par jour. Elles sont particulièrement utiles en combinaison avec reduce, quand vous voulez transformer une liste en un dictionnaire consultable.

Le spreading d'objet, noté avec trois points, sert à copier ou à fusionner sans altérer l'original. C'est le pendant, pour les objets, du spreading que vous avez utilisé dans le tableau précédent pour trier sans détruire. Attention toutefois à une nuance importante : le spreading copie uniquement le premier niveau. Si une propriété contient un tableau ou un objet, la copie partage cette propriété imbriquée avec l'original. Pour un clonage profond, on sérialise puis on désérialise l'objet avec les fonctions JSON.stringify et JSON.parse, à condition que les valeurs soient simples, sans fonction ni date native.

Enfin, deux réflexes vous feront gagner du temps. Le premier : préférez les littéraux d'objet aux affectations ligne à ligne, la syntaxe abrégée permet d'écrire le nom de la propriété une seule fois quand la variable porte exactement le même nom. Le second : vérifiez l'existence d'une propriété avant de l'utiliser, soit avec l'opérateur de chaînage optionnel qui renvoie undefined au lieu de provoquer une erreur, soit avec la méthode hasOwnProperty. Les données externes sont par nature imprévisibles, et une propriété manquante ne doit jamais faire tomber votre page.

- L'accès par point est rapide et lisible quand le nom est fixe ; l'accès par crochets sert aux noms calculés.
- La déstructuration extrait plusieurs propriétés en une ligne, avec alias et valeurs par défaut.
- Le spreading copie et fusionne les objets sans modifier l'original, mais seulement au premier niveau.
- Les propriétés calculées construisent une clé à la volée, idéales pour indexer une liste.
- Le chaînage optionnel évite une erreur quand une propriété imbriquée est absente.
- Sérialisez puis désérialisez pour obtenir une copie profonde d'un objet simple.
- Nommez vos propriétés d'après ce qu'elles représentent, jamais d'après leur couleur d'affichage.
$lesson$),
  ('web-c4-p3', 'web-c4', 3, $lesson$Fonctions fléchées et portée$lesson$, $lesson$
Depuis le début du parcours, vous écrivez des fonctions, mais le chapitre d'aujourd'hui en fait un usage intensif : elles sont le second argument de map, de filter et de reduce, le corps d'une promesse, le cœur d'un gestionnaire d'erreur. Il faut donc que leur comportement soit limpide. Une fonction est une valeur comme une autre : on peut la stocker dans une variable, la passer en argument, la renvoyer depuis une autre fonction. Cette propriété, qu'on appelle première classe, est ce qui rend possibles toutes les méthodes que vous venez de voir, puisqu'elles n'attendent rien d'autre qu'une fonction à appliquer à chaque élément.

La fonction fléchée est la forme concise introduite par les versions récentes du langage. Elle s'écrit avec une flèche entre les paramètres et le corps, admet un retour implicite quand le corps tient en une seule expression, et convient parfaitement aux rappels courts. Sa particularité la plus importante, et la plus subtile, concerne le mot-clé this : une fonction fléchée n'a pas de this propre, elle hérite de celui de son contexte englobant au moment où elle est créée. Dans la pratique, cela supprime une source d'erreurs classique dans les gestionnaires d'événements et les callbacks, mais cela signifie aussi qu'une fonction fléchée ne convient pas lorsque vous avez justement besoin d'un this lié à l'élément qui appelle. Deux autres limites à connaître : elle ne peut pas être utilisée comme constructeur, et elle ne possède pas son propre objet arguments.

```js
const double = (n) => n * 2;
const bonjour = (prenom) => "Bonjour " + prenom;
const parDefaut = (valeur = 0) => valeur;

const pairs = [1, 2, 3, 4].filter((n) => n % 2 === 0);

const creerCompteur = () => {
  let total = 0;
  return () => {
    total += 1;
    return total;
  };
};

const incr = creerCompteur();
incr(); // 1
incr(); // 2

function déclarée() {
  return typeof fléchée;
}
const fléchée = () => "ok";
déclarée(); // erreur à l'exécution si appelée avant la déclaration const
```

La portée, elle, décrit l'espace dans lequel une variable est visible. Elle est lexicale, c'est-à-dire qu'elle se décrit en regardant le fichier : une variable déclarée à l'intérieur d'un bloc, délimité par des accolades, n'existe qu'à l'intérieur de ce bloc. Les mots-clés let et const respectent cette règle strictement, alors que var, héritage d'une époque antérieure, ignore les accolades et se propage jusqu'à la fonction entière. La conséquence pratique est considérable dans une boucle : déclarer une constante dans chaque itération donne à chaque tour sa propre variable, ce qui lève beaucoup de confusion. Préférez toujours let ou const, et accordez la préférence à const quand la variable n'est jamais réassignée.

Deux phénomènes expliquent la plupart des surprises rencontrées en débogage. Le premier est le passage de la zone morte temporelle : une variable déclarée avec let ou const est réservée dès le début du bloc, mais illisible tant que l'exécution n'a pas atteint la ligne de déclaration. Lire trop tôt ne renvoie pas undefined comme avec var, cela provoque une erreur. Le second phénomène est la fermeture, ou closure : une fonction mémorise l'environnement dans lequel elle a été créée, y compris les variables de cet environnement, même après la fin de l'exécution du contexte parent. C'est exactement ce qui permet au compteur de l'exemple de garder son total entre deux appels. Les fermetures sont au cœur des gestionnaires d'état, des fabriques de fonctions et de la plupart des composants modernes.

Une dernière distinction, souvent négligée, entre déclaration et expression. Une fonction déclarée avec le mot-clé function est hissée, pour simplifier disponible dès le début de son bloc, alors qu'une fonction stockée dans une constante n'existe qu'à partir de sa ligne de déclaration. Dans un module, cette différence se voit rarement, car le code s'exécute de haut en bas, mais elle devient trompeuse quand on déplace du code. La règle de conduite est simple : choisissez une forme par fichier, et restez-y. Les fonctions fléchées pour les rappels, les déclarations pour les fonctions principales nommées, un seul style qui se lit sans hésitation.

- Une fonction est une valeur : on peut la stocker, la passer en argument et la renvoyer.
- La fonction fléchée offre un retour implicite et n'a pas de `this` propre.
- Préférez `let` et `const` à `var` : la portée est celle du bloc, pas de la fonction entière.
- `const` par défaut, `let` seulement quand la variable change réellement de valeur.
- Une fermeture mémorise l'environnement d'où la fonction a été créée.
- Une fonction déclarée est disponible avant sa ligne, une fonction assignée ne l'est pas.
- Gardez un style unique de fonctions dans un même fichier.
$lesson$),
  ('web-c4-p4', 'web-c4', 4, $lesson$Modules ES : import et export$lesson$, $lesson$
À mesure qu'un projet grossit, un seul fichier JavaScript devient vite illisible : les fonctions de formatage, les appels réseau et le code d'affichage s'entassent, les noms se multiplient, et personne ne sait plus qui appelle qui. Les modules ES répondent à ce problème en découpant le code en fichiers autonomes, chacun exposant un vocabulaire explicite et n'accédant qu'à ce qui lui a été transmis. C'est l'équivalent, côté JavaScript, de la séparation entre le HTML, le CSS et le script que vous avez apprise dans le premier chapitre : une responsabilité, un fichier, un nom.

Un fichier devient module dès qu'il contient une instruction d'export ou d'export. Il se charge ensuite avec l'attribut type de valeur module sur la balise de script, ce qui déclenche plusieurs changements de comportement. Le fichier est exécuté en mode strict, qui interdit notamment les variables non déclarées, une sécurité appréciée. Il est chargé de manière différée, après l'analyse du document, sans avoir besoin de la balise différée en plus. Enfin, chaque module possède sa propre portée : deux fichiers peuvent déclarer la même variable sans se marcher dessus. Une conséquence pratique mérite d'être signalée : un module chargé depuis le disque dur, par un simple double-clic sur le fichier, est bloqué par la politique de sécurité des navigateurs ; pour le tester, il faut un serveur local, même minimal.

```js
// formatage.js
export const formaterDate = (iso) => {
  const [annee, mois, jour] = iso.split("-");
  return `${jour}/${mois}/${annee}`;
};

export const estComplete = (s) => s.inscrits >= s.places;

export default function resume(liste) {
  return `${liste.length} séance(s)`;
}
```

```js
// app.js
import resume, { formaterDate, estComplete as complet } from "./formatage.js";

const liste = [{ inscrits: 12, places: 12 }];
console.log(resume(liste));
console.log(formaterDate("2026-10-17"));
console.log(liste.filter(complet).length);
```

La syntaxe offre deux formes d'export. L'export nommé désigne chaque élément par son nom à l'importation, ce qui rend le code lisible et permet d'en importer seulement une partie ; on peut aussi regrouper plusieurs exports dans une seule instruction. L'export par défaut en désigne un seul, sans nom imposé à la réception, ce qui est pratique pour une API simple : un module, une fonction principale. On peut les combiner, mais l'usage courant recommande de réserver l'export par défaut à un composant ou à une fonction dominante et d'utiliser les exports nommés pour tout le reste, la raison étant que les exports nommés restent vérifiables par les outils d'analyse statique.

Les importations se placent obligatoirement en haut de fichier, avant toute instruction exécutée. On peut y apporter un alias, ce qui évite les collisions de noms entre deux modules, ou charger tout un espace de noms sous une variable unique, pratique quand plusieurs fonctions proviennent de la même source. L'importation dynamique, sous la forme d'une fonction appelée avec un chemin, renvoie une promesse et permet de charger un fichier seulement au moment où il devient utile : une fenêtre modale rarement ouverte, une table de traduction, un gabarit particulier. Elle fait le pont entre les modules et l'asynchrone que les sections suivantes vont détailler.

Un point de vigilance sur les chemins : dans un module, un chemin relatif doit toujours commencer par une barre oblique pointée devant le nom du fichier, sinon le navigateur le résout par rapport à la page courante et non par rapport au module appelant. Ce détail provoque l'erreur la plus fréquente des débutants en modules, qui voient un chemin pourtant juste refuser de se charger. Ajoutez-y l'extension .js, obligatoire dans la plupart des navigateurs, et vérifiez d'abord que votre serveur local répond avant de chercher une erreur dans le code.

- Un fichier avec `export` devient un module et se charge avec l'attribut `type` valorisé `module`.
- Chaque module a sa portée propre : aucune variable ne fuite d'un fichier à l'autre.
- L'export nommé se reprend à l'identique, l'export par défaut se prend tel quel.
- Les importations se placent en haut du fichier, avant toute instruction exécutée.
- Un chemin de module relatif commence par une barre oblique et porte son extension.
- Importez dynamiquement ce qui n'est qu'occasionnellement nécessaire.
- Un module ne se charge pas depuis le disque : servez-le depuis un serveur local.
$lesson$),
  ('web-c4-p5', 'web-c4', 5, $lesson$Le temps d'exécution : pile d'appels et setTimeout$lesson$, $lesson$
Avant de consommer la moindre donnée distante, il faut comprendre comment JavaScript exécute votre code, car tout le reste découle de ce modèle. Le navigateur n'exécute pas votre script sur plusieurs voies en même temps : il dispose d'un seul fil d'exécution, matérialisé par une structure de type pile, qu'on appelle la pile d'appels. Cette pile fonctionne exactement comme une pile d'assiettes : on dépose une nouvelle assiette au dessus quand on entre dans une fonction, on la retire quand la fonction a terminé, et on ne peut manipuler que celle du sommet. Le programme démarre en haut du fichier, exécute ligne à ligne, et chaque appel de fonction ajoute un étage à la pile.

Cette architecture a une conséquence immédiate et importante : tant qu'une fonction n'a pas rendu la main, rien d'autre ne peut se passer. Le navigateur ne peut pas rafraîchir l'écran, répondre à un clic ou afficher une animation tant que la pile n'est pas vide de nouveau. Si votre fonction met trois secondes à calculer, la page gèle pendant trois secondes : aucune saisie n'est prise en compte, le curseur cesse de clignoter, l'utilisateur croit que l'onglet a planté. C'est précisément ce qui motive l'existence de l'asynchrone : plutôt que d'attendre une réponse du réseau en gardant la pile occupée, on confie l'attente à un autre mécanisme et on rend la main immédiatement.

```text
Pile d'appels, exécution de haut en bas

    +----------------------+
    | executerEnsuite()    |  <-- sommet : c'est elle qui tourne
    +----------------------+
    | afficherListe()      |
    +----------------------+
    | chargerInscriptions()|
    +----------------------+
    | demarrage()          |
    +----------------------+
    | script du module     |
    +----------------------+

Quand afficherListe() finit, son étage disparaît
et le contrôle revient à executerEnsuite().
```

La pile explique aussi le comportement de setTimeout, une fonction que vous avez probablement déjà utilisée sans en mesurer la portée. Elle ne déclenche pas immédiatement l'appel : elle enregistre la fonction ainsi qu'un délai, remet la main au code suivant, et laisse le moteur décider de l'exécution ultérieure. Même avec un délai de zéro milliseconde, la fonction ne s'exécute jamais au milieu de la ligne en cours : elle attend que la pile soit vide. C'est pourquoi, dans un script séquentiel, un message planifié avec un délai nul apparaît toujours après tous les messages écrits sans délai. Le délai indique un minimum, pas une garantie de ponctualité : sous charge, une attente promise de dix millisecondes peut en prendre cent.

Pour coordonner ces retours différés, le navigateur s'appuie sur deux files d'attente distinctes et un orchestrateur appelé boucle d'événements. La boucle observe en permanence : quand la pile d'appels est vide, elle prend le premier élément de la file des tâches, celui qui contient les callbacks de setTimeout et les événements de saisie, et l'exécute. Elle passe ensuite aux tâches de priorité supérieure, qui contiennent les callbacks de promesses : celles-ci sont toujours vidées avant les tâches ordinaires, même si une tâche ordinaire était inscrite plus tôt. Cette règle a un effet direct sur votre code : une promesse résolue s'exécutera avant un setTimeout de zéro milliseconde.

```text
Boucle d'évenements : ordre observe en pratique

   file des taches           file des priorites hautes
  +----------------+         +--------------------+
  | setTimeout 0   |         | then d'une promesse|
  | clic souris    |         | corps d'un await   |
  | saisie clavier |         +--------------------+
  +----------------+                   ^
          ^                            |
          |          +-------------+   |
          +----------|  pile vide  |---+
                     +-------------+
                            |
                     la boucle choisit la
                     file prioritaire d'abord
```

Cette mécanique produit deux réflexes utiles. Le premier : ne comptez jamais sur une durée précise pour synchroniser deux opérations, comptez sur l'ordre de résolution. Le second : pour regrouper plusieurs appels indépendants et n'attendre que le plus lent, ne les enchaînez pas avec des délais, utilisez les promesses de la section suivante. En pratique, setTimeout sert surtout à décaler un rafraîchissement, à afficher un message temporaire ou à simuler un délai de réseau dans un exercice, jamais à coordonner un vrai traitement.

- JavaScript exécute sur un seul fil : la pile d'appels ne contient qu'une chose à la fois.
- Tant qu'une fonction n'a pas rendu la main, le navigateur ne peut rien afficher ni saisir.
- `setTimeout` décale, il ne synchronise pas : le délai promis est un minimum.
- Même avec zéro milliseconde, le rappel attend que la pile soit vide.
- La boucle d'événements vide la file des promesses avant celle des tâches ordinaires.
- Une opération longue et synchrone fige la page : c'est le symptôme à rechercher d'abord.
- Pour attendre plusieurs opérations en même temps, utilisez les promesses, pas des délais.
$lesson$),
  ('web-c4-p6', 'web-c4', 6, $lesson$Promesses : then, catch et enchaînements$lesson$, $lesson$
Avant les promesses, l'asynchrone s'écrivait avec des fonctions de rappel imbriquées : une première fonction recevait une autre, qui en recevait une troisième, et le code s'enfonçait vers la droite en escalier. Cette forme, dite pyramide, devient vite illisible et rend le traitement des erreurs pénible, car il faut prévoir un rappel d'erreur à chaque niveau. La promesse résout ce problème en ramenant l'asynchrone vers une forme séquentielle : une promesse représente une valeur qui n'existe pas encore mais qui existera, ou une erreur qui interviendra, et elle se comporte dans le code comme une valeur que l'on peut passer de main en main.

Une promesse connaît exactement trois états au cours de sa vie : en attente, tenue ou rompue. Elle démarre en attente, puis bascule une seule fois et définitivement vers l'une des deux dernières, au moment où l'opération aboutit ou échoue. Cette transition est irréversible : une promesse déjà rompue ne deviendra jamais tenue, et une promesse tenue ne pourra plus signaler d'erreur. Cette immutabilité est une garantie précieuse : vous pouvez transmettre la même promesse à plusieurs parties du programme, chacune peut la consulter, et toutes obtiendront exactement le même résultat, qu'elle s'y soit prise immédiatement ou bien plus tard.

```text
Cycle de vie d'une promesse

      appel de fetch ou de resolveApres
                      |
                      v
              +---------------+
              |   en attente  |
              +---------------+
               |             |
     resolution|             |rejet
               v             v
       +-------------+   +-------------+
       |    tenue    |   |   rompue    |
       +-------------+   +-------------+
               |             |
          then/catch     then/catch
               |             |
               v             v
        nouvelle promesse  nouvelle promesse
```

La méthode then est la porte d'entrée de consultation. Elle reçoit une fonction qui sera appelée avec la valeur tenue, et elle renvoie immédiatement une nouvelle promesse, qui sera tenue avec le retour de cette fonction. C'est ce mécanisme qui permet l'enchaînement : puisque then renvoie une promesse, on peut appeler then dessus, puis encore dessus, et dérouler une opération complexe en étapes nettes, une par ligne. Si l'une des étapes lève une erreur, ou si la promesse initiale était rompue, les then suivants sont sautés et le contrôle file jusqu'au premier catch, qui reçoit l'erreur. Le rattrapage est donc latéral et unique, au lieu d'être dupliqué à chaque niveau.

```js
resolveApres(400, { id: "S-101" })
  .then((seance) => {
    if (!seance) throw new Error("Aucune séance");
    return { ...seance, affichee: true };
  })
  .then((seance) => console.log(seance.id))
  .catch((erreur) => console.error("Échec :", erreur.message))
  .finally(() => console.log("Terminé, dans tous les cas"));

const tous = await Promise.all([appelA(), appelB()]);
const etats = await Promise.allSettled([appelA(), appelB()]);
const premier = await Promise.race([appelA(), appelB()]);
```

La famille Promise apporte en complément quatre opérateurs d'assemblage qu'il vaut mieux connaître dès maintenant. Promise.all attend la résolution de tous les éléments fournis et renvoie un tableau de valeurs dans l'ordre d'origine, indépendamment de l'ordre de résolution ; au moindre rejet, elle se rompt et transmet la première erreur. Promise.allSettled attend tout le monde sans jamais se rompre et renvoie le détail de chaque issue, ce qui convient quand une partie des chargements peut échouer sans devoir faire échouer l'écran entier. Promise.race renvoie l'issue de la première promesse à trancher, tenue ou rompue, ce qui est la base d'un délai maximum. Promise.any renvoie la première issue tenue et ne se rompt que si toutes ont échoué, utile quand plusieurs sources sont interchangeables.

Un dernier point sur l'ordre d'exécution, qui lève beaucoup de confusions. Les fonctions passées à then ne s'exécutent pas immédiatement, même si la promesse est déjà tenue : elles sont inscrites dans la file des priorités hautes et traitées quand la pile devient vide, mais avant les rappels de setTimeout. Deux promesses déjà résolues s'exécutent donc dans l'ordre où then a été appelé, et ce toujours avant tout délai planifié. Cette règle, très régulière, vous permet de raisonner sur l'ordre affiché en console sans jamais ajouter d'artifice de synchronisation.

- Une promesse passe une fois, et définitivement, de l'état d'attente à tenu ou rompu.
- `then` renvoie une nouvelle promesse : c'est ce qui rend les enchaînements possibles.
- Une erreur non rattrapée saute tous les `then` suivants jusqu'au premier `catch`.
- `finally` s'exécute dans tous les cas, idéal pour libérer un indicateur de chargement.
- `Promise.all` échoue au premier rejet, `Promise.allSettled` n'échoue jamais.
- `Promise.race` tranche sur le premier terme, c'est la base d'un délai maximum.
- Les rappels de promesse passent avant les rappels de `setTimeout`.
$lesson$),
  ('web-c4-p7', 'web-c4', 7, $lesson$async / await$lesson$, $lesson$
async et await sont la couche de confort qui a fait triompher le modèle des promesses. Ils ne remplacent rien : tout ce que fait une chaîne de then se fait aussi avec eux, et ils produisent exactement les mêmes promesses sous le capot. Leur apport est purement rédactionnel, mais il est considérable : écrire une opération asynchrone comme on écrit du code ordinaire, avec des lignes qui s'enchaînent de haut en bas, des variables que l'on peut réutiliser à la ligne suivante et des erreurs attrapées avec le mécanisme try catch que vous connaissez déjà.

La règle de départ est brève : une fonction marquée async renvoie toujours une promesse, quoi qu'elle contienne. Si son corps renvoie une valeur ordinaire, la fonction l'embrasse dans une promesse tenue ; si elle lance une erreur, la promesse est rompue. À l'intérieur, le mot-clé await ne fonctionne que dans une fonction async, ou au plus haut niveau d'un module. Il suspend l'exécution de cette fonction unique jusqu'à ce que la promesse soit tranchée, puis en reprend la valeur tenue ou relance l'erreur. Tout le reste du programme continue de tourner : la pile n'est jamais bloquée, puisque l'attente repose sur le même mécanisme que then.

```js
async function chargerInscriptions() {
  try {
    afficherEtat("chargement");
    const reponse = await fetch("/api/seances");
    if (!reponse.ok) {
      throw new Error("HTTP " + reponse.status);
    }
    const donnees = await reponse.json();
    const utiles = donnees.filter((s) => s.statut === "ouverte");
    afficherEtat("succes");
    return utiles;
  } catch (erreur) {
    afficherEtat("erreur", erreur.message);
    return [];
  } finally {
    masquerIndicateur();
  }
}
```

L'erreur mérite une attention particulière, parce que c'est là que se joue la qualité du code asynchrone. Un await sur une promesse rompue se comporte exactement comme une instruction throw : l'exécution saute au bloc catch le plus proche. Si aucun catch n'existe, la promesse retourne à l'état non rattrapée et le navigateur affiche un avertissement dans la console, tandis que votre fonction n'a rien renvoyé. Trois erreurs reviennent donc sans cesse : oublier le bloc try catch autour d'un appel réseau, attraper l'erreur sans jamais l'afficher à l'utilisateur, ou renvoyer une valeur de secours dans le catch sans signaler que le résultat est incomplet. Le bon réflexe consiste à afficher un état d'erreur lisible et à garder le détail technique pour la console.

La deuxième question de qualité concerne la sérialité inutile. Écrire un await à l'intérieur d'une boucle revient à attendre chaque itération avant de lancer la suivante, même quand les opérations sont indépendantes : si chaque appel prend une seconde et que la boucle en fait dix, l'utilisateur attendra dix secondes. La correction consiste à lancer tous les appels d'un coup, en construisant d'abord un tableau de promesses, puis à attendre le résultat groupé. Cette distinction entre dépendance et indépendance est le premier réflexe à prendre dès qu'une fonction contient plus d'un await : demandez-vous si la ligne suivante a réellement besoin du résultat de la ligne précédente.

```js
// lent : dix appels enchainees
for (const id of identifiants) {
  const donnees = await chargerUn(id);
  resultats.push(donnees);
}

// rapide : les dix partent ensemble
const promesses = identifiants.map((id) => chargerUn(id));
const resultats = await Promise.all(promesses);
```

Enfin, les modules autorisent l'await au plus haut niveau, c'est-à-dire directement dans le corps du fichier, sans l'enfermer dans une fonction. C'est extrêmement pratique pour le démarrage d'une application : on déclare l'état initial, on attend la première source de données, puis on construit l'écran. Cette forme reste réservée aux modules ; dans un script classique, elle provoque une erreur de syntaxe. Une dernière habitude recommandée : n'enveloppez jamais tout votre fichier dans un unique try catch global, car vous perdriez la distinction entre une erreur d'affichage, qui peut être locale, et une erreur de réseau, qui concerne l'ensemble de l'écran.

- Une fonction `async` renvoie toujours une promesse, même si son corps renvoie une valeur simple.
- `await` suspend la fonction appelante, jamais le navigateur ni les autres scripts.
- Un `await` sur promesse rompue se comporte comme un `throw` : prévoyez un `try catch`.
- Signalez l'écran en erreur et gardez le détail technique pour la console.
- Enchaînez deux `await` seulement s'ils sont réellement dépendants.
- Pour des appels indépendants, lancez-les ensemble puis attendez avec `Promise.all`.
- L'`await` de haut niveau est réservé aux fichiers modules.
$lesson$),
  ('web-c4-p8', 'web-c4', 8, $lesson$fetch, Response et JSON$lesson$, $lesson$
Le navigateur met à disposition une interface dédiée aux requêtes HTTP, nommée fetch, et c'est elle que vous utiliserez pour alimenter l'atelier de la Médiathèque des Lilas. Elle s'appelle avec une adresse, renvoie immédiatement une promesse, et cette promesse se tient avec un objet représentant la réponse du serveur. L'erreur la plus répandue chez les débutants vient d'un malentendu sur ce second point : fetch ne renvoie pas les données, il renvoie la réponse. Vous devez encore demander à cette réponse de lire son contenu, et cette lecture est elle-même asynchrone.

L'objet Response est une enveloppe, pas le paquet. Il expose d'abord les métadonnées de la transaction : la propriété ok, un booléen qui est vrai si le code de statut se situe entre deux cents et deux cent quatre-vingt-dix-neuf, la propriété status qui donne le code exact, la propriété url qui indique l'adresse réellement contactée après redirection éventuelle, et la méthode headers qui donne accès aux en-têtes. La distinction entre ok et status est le cœur de la vérification correcte : un service peut répondre avec le code quatre cent quatre quand la ressource est absente, ou cinq cents quand son serveur a un problème, et ces deux cas doivent être traités par votre code avant toute lecture de contenu.

La lecture se fait avec une méthode qui renvoie une promesse : json pour un corps au format JSON, text pour du texte brut, blob pour un binaire comme une image, et formData pour un envoi de formulaire. Ces méthodes sont exclusives : une fois le corps lu, il est consommé et une seconde lecture échoue. C'est pourquoi on ne lit jamais la réponse deux fois, ou alors on la copie d'abord. Dans la pratique, la séquence standard tient en trois lignes : appeler fetch, vérifier ok, puis attendre la conversion. C'est cette même séquence que vous retrouverez dans chaque exemple du chapitre et dans le mini-projet.

```js
const url = "https://api.open-meteo.com/v1/forecast";
const params = new URLSearchParams({
  latitude: "48.88",
  longitude: "2.42",
  current: "temperature_2m,wind_speed_10m",
  timezone: "Europe/Paris"
});

async function lireReponse() {
  const reponse = await fetch(url + "?" + params.toString());
  if (!reponse.ok) {
    throw new Error("Statut " + reponse.status);
  }
  const contenu = await reponse.json();
  return contenu.current;
}
```

fetch accepte également un second argument qui décrit la requête. On y précise la méthode, le plus souvent get ou post, les en-têtes, par exemple pour déclarer que le corps est au format JSON, et le corps lui-même, sérialisé avec JSON.stringify. Pour un envoi de données, la forme courante est une requête post accompagnée de l'en-tête de type de contenu et d'un corps converti en texte. Un détail qui surprend : même quand le serveur répond avec une erreur applicative, la promesse de fetch se tient, puisque la requête elle-même a abouti. Seul un problème de réseau, coupure ou domaine injoignable, provoque un rejet. La vérification de ok n'est donc jamais facultative.

Un mot sur les règles d'accès entre origines, car elles expliquent une bonne partie des échecs en environnement de développement. Un script ne peut interroger que les services qui acceptent explicitement sa provenance ; sinon, le navigateur bloque la lecture de la réponse et signale une erreur de politique de sécurité. Les grands services publics ouvrent cet accès, c'est le cas du service de météorologie que vous utiliserez, mais votre serveur d'entraînement, lui, n'envoie peut-être pas l'en-tête adéquat. Quand une requête fonctionne depuis un site tiers mais échoue depuis votre machine, vérifiez d'abord la console et le statut de la réponse, avant de soupçonner votre code.

- `fetch` renvoie une promesse de réponse, jamais les données directement.
- Vérifiez `ok` avant de lire : un statut d'échec est une erreur métier, pas une exception.
- Lisez le corps une seule fois avec `json`, `text`, `blob` ou `formData`.
- Un rejet de promesse signale un problème réseau ; les erreurs applicatives passent par `status`.
- Les requêtes modifiantes précisent méthode, en-têtes et corps sérialisé.
- Une réponse peut être redirigée : la propriété `url` donne l'adresse finale.
- Une erreur de politique de sécurité entre origines se lit dans la console du navigateur.
$lesson$),
  ('web-c4-p9', 'web-c4', 9, $lesson$Gérer les erreurs réseau et les états$lesson$, $lesson$
Une page connectée a une particularité que la page statique n'avait pas : elle peut échouer, et elle doit le dire. Le réseau tombe, le serveur est en maintenance, la réponse est vide, le format a changé, l'utilisateur a coupé le wifi en pleine attente. Si votre code ne prévoit que le chemin heureux, l'écran reste figé sur un indicateur de chargement que plus rien ne terminera, ou affiche un tableau vide que l'utilisateur comprendra comme une absence de séance. La qualité d'une application se juge précisément à la façon dont elle raconte ses échecs.

Le premier point à intégrer est la différence entre deux familles d'erreurs. Une erreur de réseau, coupure complète, domaine injoignable, provoque le rejet de la promesse de fetch et se rattrape avec try catch. Une erreur applicative, ressource introuvable, paramètre invalide, échec d'authentification, arrive dans une réponse parfaitement lisible dont le statut n'est pas dans la plage de succès : elle ne déclenche rien d'automatique, et c'est à votre code de la détecter en testant ok. Rater cette distinction produit le bug le plus fréquent des applications connectées : une page qui reste en chargement éternel parce que personne n'a prévu le cas d'un quatre cent quatre.

```text
Les quatre etats d'un ecran connecte

  +-----------+   donnees non vides   +---------+
  | chargement | ---------------------->| succes  |
  +-----------+                        +---------+
        |                                    |
        | rejet ou statut                    | liste vide
        v                                    v
  +-----------+                        +---------+
  |  erreur   |                        |  vide   |
  +-----------+                        +---------+
        |                                    |
        | bouton essayer a nouveau           | filtre ou recherche
        +-------------> chargement <---------+
```

Les quatre états se traitent avec la même discipline : un seul est visible à la fois, et l'écran indique toujours lequel. Pendant le chargement, affichez un message explicite et désactivez le bouton qui déclenche l'appel, faute de quoi l'utilisateur double-clique et multiplie les requêtes. En cas de succès avec données, rendez le tableau et masquez tout message réservé aux autres états. En cas de succès sans données, ne montez pas une erreur : annoncez que la liste est vide et proposez l'action pertinente, lever un filtre ou élargir la recherche. L'absence de résultat n'est pas une panne, et traiter les deux de la même manière est une faute d'ergonomie.

```table
Etat | Condition | Message affiche | Action proposee
--- | --- | --- | ---
chargement | appel en cours | Chargement des seances... | Aucune, bouton inactif
succes | donnees non vides | Titre et tableau remplis | Tri et filtres
vide | donnees vides | Aucune seance pour ce filtre | Reinitialiser les filtres
erreur | rejet ou statut invalide | Le chargement a echoue | Bouton Reessayer
```

L'état d'erreur mérite deux précautions supplémentaires. La première concerne le texte destiné à l'utilisateur : il doit dire ce qui s'est passé et quoi faire maintenant, sans exposer de détails techniques incompréhensibles ni la pile d'appels complète. Le second niveau d'information, en revanche, doit être complet dans la console, avec le message d'origine et le statut, car c'est là que vous viendrez déboguer. La deuxième précaution concerne la reprise : le bouton réessayer doit relancer exactement la même opération, avec la même logique de validation, et non se contenter de vider la liste. Idéalement, on conserve les dernières données valides à l'écran pendant le rechargement, ce qui évite à l'utilisateur de perdre sa place.

Un dernier réflexe, à installer avant même le premier vrai appel : valider la forme des données reçues. Un service peut renvoyer un objet où vous attendiez un tableau, une propriété renommée, une valeur nulle là où vous espériez un nombre. Plutôt que de laisser votre fonction de rendu planter sur une propriété absente, vérifiez au point d'entrée que le tableau est bien un tableau, que les champs obligatoires existent, et convertissez les formats au passage. Ce travail de traduction entre la forme distante et la forme d'affichage est exactement le sujet de la prochaine section, où un service public réel servira de terrain d'exercice.

- Une erreur réseau rejette la promesse ; une réponse invalide se détecte avec `ok`.
- Chaque écran connecté affiche exactement un des quatre états décrits ici.
- Une liste vide n'est pas une erreur : elle affiche un message et une action.
- Désactivez le déclencheur pendant le chargement pour éviter les appels en double.
- Montrez à l'utilisateur ce qu'il peut faire, gardez le détail technique pour la console.
- Le bouton réessayer relance l'appel complet, validation comprise.
- Validez la forme des données reçues avant de les confier au rendu.
$lesson$),
  ('web-c4-p10', 'web-c4', 10, $lesson$Un exemple réel : l'API publique Open-Meteo$lesson$, $lesson$
Il est temps de sortir des exemples fabriqués et d'interroger un vrai service. Le choix s'est porté sur Open-Meteo, un service de prévision météorologique documenté publiquement, consultable à l'adresse https://open-meteo.com/, qui présente trois qualités précieuses pour apprendre : il ne demande aucune clé d'accès, aucune inscription et aucun paiement, il renvoie du JSON directement exploitable, et il accepte des requêtes très simples à construire dans une URL. Pour l'atelier de la Médiathèque des Lilas, l'usage est concret : afficher la prévision du jour de chaque séance en extérieur, afin que l'animateur sache s'il faut prévoir la salle couverte.

La première étape d'un appel sérieux consiste à construire l'adresse plutôt qu'à la taper en dur. Le type URLSearchParams du navigateur prend un objet de paramètres, l'assemble correctement en encodant les caractères spéciaux, et produit une chaîne prête à être accolée à l'adresse de base. C'est considérablement plus sûr qu'une concaténation manuelle : une valeur contenant une esperluette ou un espace est encodée automatiquement, et l'adresse reste lisible dans le code. Attention à bien séparer l'adresse du service et ses paramètres : les coordonnées, la liste des mesures demandées et le fuseau horaire sont trois informations distinctes, et un oubli dans cette liste se traduit par une réponse incomplète plutôt que par une erreur.

```js
const base = "https://api.open-meteo.com/v1/forecast";

function construireUrl(latitude, longitude) {
  const params = new URLSearchParams({
    latitude: String(latitude),
    longitude: String(longitude),
    current: "temperature_2m,precipitation,wind_speed_10m",
    daily: "temperature_2m_max,temperature_2m_min",
    timezone: "Europe/Paris",
    forecast_days: "7"
  });
  return base + "?" + params.toString();
}

async function prevoir(latitude, longitude) {
  const reponse = await fetch(construireUrl(latitude, longitude));
  if (!reponse.ok) {
    throw new Error("Statut " + reponse.status);
  }
  const brut = await reponse.json();
  if (!brut || !Array.isArray(brut.daily?.time)) {
    throw new Error("Forme de réponse inattendue");
  }
  return brut;
}
```

La deuxième étape est le mappage, c'est-à-dire la traduction de la forme distante en forme d'affichage. Le service renvoie des tableaux parallèles, un tableau de dates, un tableau de températures maximales, un tableau de températures minimales, ce qui est efficace pour lui mais pénible à afficher. La méthode map permet de les réassembler en une liste d'objets, un par jour, chacun portant les champs dont votre écran a besoin. C'est exactement la même opération que vous ferez pour les séances dans le mini-projet : on ne présente jamais la donnée brute telle qu'elle arrive, on la reformate d'abord. Le mappage est aussi l'endroit naturel pour arrondir, convertir une unité, produire un libellé prêt à imprimer ou fournir une valeur de repli quand la mesure est absente.

```js
const jours = brut.daily.time.map((date, index) => ({
  date,
  max: Math.round(brut.daily.temperature_2m_max[index]),
  min: Math.round(brut.daily.temperature_2m_min[index]),
  amplitude: Math.round(
    brut.daily.temperature_2m_max[index] - brut.daily.temperature_2m_min[index]
  )
}));

const tièdes = jours.filter((j) => j.max >= 18);
const moyenneMax = jours.reduce((somme, j) => somme + j.max, 0) / jours.length;
const lePlusChaud = [...jours].sort((a, b) => b.max - a.max)[0];
```

La troisième étape met en œuvre les trois méthodes du début de chapitre sur des données réelles. On filtre pour ne garder que les journées suffisamment clémentes, on réduit pour calculer une moyenne, on trie pour trouver la journée la plus chaude. Notez à nouveau que le tri porte sur une copie, afin que la liste affichée reste dans l'ordre chronologique. Notez aussi le soin apporté à la division par zéro : si le tableau est vide, la moyenne doit renvoyer une valeur expliquée plutôt qu'un résultat invalide. Ce genre de détail est invisible tant que tout va bien, et devient le premier message d'erreur visible dès que le service change de forme.

Un point sur les valeurs nulles, fréquentes dans ce type de réponse : le service marque souvent une mesure absente par une valeur nulle plutôt que par une erreur. Une température nulle est une information valable, mais une absence de mesure traduite en zéro produit un graphique trompeur. Le mappage est donc l'endroit où l'on distingue les deux cas, en testant la présence réelle de la valeur avant de l'utiliser, et en renvoyant un état explicite que le rendu saura afficher. Cette discipline prépare directement la section suivante : une donnée douteuse doit être signalée, pas silencieusement convertie en donnée plausible.

Enfin, une remarque sur la réplication des appels. Le service accepte des dizaines de requêtes par minute sans limite rigide pour un usage raisonnable, mais votre page n'a aucune raison de reinterroger la même adresse à chaque affichage. Pour un exercice, un appel simple suffit ; pour un vrai projet, on conserve la réponse quelques minutes, on mémorise l'adresse déjà contactée, et on évite surtout de relancer un appel en cours de traitement. Vous allez voir dans la section suivante les garde-fous qui transforment un appel naïf en appel responsable.

- Construisez les adresses avec `URLSearchParams` plutôt qu'en les concaténant à la main.
- Toujours vérifier `ok` avant de lire, puis contrôler la forme du contenu reçu.
- Le mappage traduit la structure distante en objets d'affichage prêts à être montrés.
- Réassemblez les tableaux parallèles avec `map` avant de traiter quoi que ce soit.
- Distinguez une mesure absente d'une mesure réellement nulle.
- Protégez les calculs de moyenne contre le cas d'un tableau vide.
- Une même adresse interrogée deux fois se met en cache plutôt que d'être rappelée.
$lesson$),
  ('web-c4-p11', 'web-c4', 11, $lesson$Sécuriser l'appel : timeout, annulation et défenses$lesson$, $lesson$
Un appel réseau non encadré est une promesse qui peut rester suspendue pour toujours. Le serveur répond lentement, le réseau bascule en 4G dégradée, l'utilisateur change de page pendant l'attente : sans garde-fou, votre indicateur de chargement tourne indéfiniment et votre bouton reste inactif. Sécuriser l'appel consiste à donner une durée maximum, la possibilité d'interrompre, et des règles claires pour décider de ce qui se passe ensuite. Ces défenses ne sont pas des raffinements de professionnel, ce sont les garde-fous qui séparent une démonstration d'un outil utilisable.

L'outil natif s'appelle AbortController. On crée un contrôleur, on passe son signal à fetch, et on appelle la méthode abort du contrôleur pour annuler la requête en cours. Une annulation provoque le rejet de la promesse avec une erreur identifiable, qu'il faut distinguer des vrais échecs : si l'utilisateur a lui-même déclenché l'interruption, afficher un message d'erreur serait trompeur, il faut simplement ne rien afficher du tout. Le test se fait en comparant la propriété name de l'erreur à la valeur attendue, ce qui vous permet de traiter l'annulation comme un cas neutre et de réserver l'affichage d'erreur aux vraies pannes.

```js
let controleur = null;

async function chargerAvecGardeFou(url, delaiMs = 8000) {
  if (controleur) {
    controleur.abort();
  }
  controleur = new AbortController();
  const minuteur = setTimeout(() => controleur.abort(), delaiMs);

  try {
    const reponse = await fetch(url, { signal: controleur.signal });
    if (!reponse.ok) {
      throw new Error("Statut " + reponse.status);
    }
    return await reponse.json();
  } catch (erreur) {
    if (erreur.name === "AbortError") {
      return null;
    }
    throw erreur;
  } finally {
    clearTimeout(minuteur);
  }
}
```

Le délai maximum se règle en armant un minuteur qui déclenche l'annulation, comme le montre l'exemple. La version moderne du langage propose une forme abrégée, une fonction qui renvoie directement un signal expirant après la durée indiquée, mais le principe reste identique. Choisissez la durée en fonction de l'attente raisonnable pour un utilisateur : quelques secondes pour une liste d'écran, un peu plus pour un traitement lourd. Sous ce seuil, l'annulation et le rejet de fetch se ressemblent beaucoup, et la distinction par le nom de l'erreur reste la manière la plus fiable de les séparer.

La deuxième défense concerne la course entre deux appels. Si l'utilisateur tape dans un champ de recherche et que chaque frappe déclenche une requête, la réponse de la première peut arriver après celle de la troisième : l'écran affiche alors un résultat obsolète que plus rien ne corrige. Deux parades existent, et elles se combinent. La première consiste à annuler la requête précédente avant d'en lancer une nouvelle, exactement comme dans l'exemple. La seconde consiste à ignorer les réponses qui ne proviennent pas de la dernière requête, en comparant un numéro d'appel au moment de l'affichage. Les deux procédés évitent le même défaut : que l'ordre d'arrivée des réponses décide du contenu affiché.

```text
Sans garde-fou : deux appels qui se croisent

  utilisateur tape  --->  appel A part  --->  appel B part
                             |                   |
                             |        reponse B arrive en premier
                             |                   |
                             |             ecran = B   (correct)
                             |
                       reponse A arrive en retard
                             |
                       ecran = A   (obsolete !)

Avec annulation : B annule A, seule la derniere reponse compte.
```

La troisième famille de défenses relève des bonnes mœurs côté client. Un délai entre deux déclenchements successifs, souvent appelé anti-rebond, évite de lancer une requête à chaque frappe : on attend une courte pause de silence avant d'appeler, si bien que seules les saisies stabilisées déclenchent une requête. Un nombre maximum d'essais, deux ou trois en général, avec un intervalle croissant, permet de traverser une coupure brève sans harceler le service. Une copie locale de la dernière réponse valide évite de repasser par le réseau à chaque retour sur un écran déjà chargé. Enfin, et surtout : toute clé secrète appartient au serveur. Une API sans accès restreint peut être appelée depuis la page, une API privée doit l'être via votre propre serveur, faute de quoi la clé se lit dans le code source de n'importe quel visiteur.

- Un délai maximum empêche l'indicateur de chargement de tourner pour toujours.
- `AbortController` interrompt la requête et produit une erreur identifiable.
- Une annulation déclenchée par l'utilisateur n'appelle aucun message d'erreur.
- Avant de lancer un nouvel appel, annulez le précédent ou ignorez sa réponse tardive.
- Un anti-rebond évite une requête par frappe dans un champ de recherche.
- Limitez le nombre d'essais et laissez un intervalle croissant entre eux.
- Conservez la dernière réponse valide et gardez vos clés côté serveur.
$lesson$),
  ('web-c4-p12', 'web-c4', 12, $lesson$Mini-projet guidé : le tableau des inscriptions$lesson$, $lesson$
Toutes les pièces sont prêtes : transformation de tableaux, objets d'affichage, fonctions fléchées, promesses, async et fetch, gestion des quatre états et garde-fous. Le moment est venu de les assembler en un seul écran qui fonctionne : le tableau des inscriptions de l'atelier de la Médiathèque des Lilas, alimenté par une source de données distante. La consigne de l'exercice pratique reprend ce même cahier des charges ; ici, nous le construisons ensemble, étape par étape, en veillant à ce que chaque brique corresponde à une section précise de la leçon.

L'étape initiale consiste à définir l'état de l'application, c'est-à-dire la petite mémoire unique dont dépend l'écran. Plutôt que de faire lire des variables éparpillées par plusieurs fonctions, on centralise quatre informations : la liste actuellement affichée, l'état courant parmi les quatre, un message éventuel à montrer, et le nombre d'appels déjà lancés. Cette centralisation change tout : pour rafraîchir l'écran, une seule fonction est nécessaire, celle qui lit l'état et écrit le DOM. Ajouter un filtre, c'est modifier l'état puis rappeler cette fonction ; recevoir une erreur, c'est modifier l'état puis la rappeler encore. Le flux reste toujours le même, dans un seul sens.

```js
const etat = {
  phase: "chargement",
  message: "",
  seances: [],
  essais: 0
};

const SEANCES_LOCALES = [
  { id: "S-101", titre: "Initiation HTML", date: "2026-10-17", places: 12, inscrits: 9 },
  { id: "S-102", titre: "Mise en forme CSS", date: "2026-10-24", places: 12, inscrits: 12 },
  { id: "S-103", titre: "Boucles et tableaux", date: "2026-11-07", places: 10, inscrits: 4 },
  { id: "S-104", titre: "Fonctions et portee", date: "2026-11-14", places: 10, inscrits: 0 }
];

async function resolveApres(ms, valeur) {
  await new Promise((faire) => setTimeout(faire, ms));
  return valeur;
}

async function chargerInscriptions() {
  etat.phase = "chargement";
  etat.message = "";
  dessiner();
  etat.essais += 1;
  try {
    const brutes = await resolveApres(600, SEANCES_LOCALES);
    if (!Array.isArray(brutes)) {
      throw new Error("Format de liste inattendu");
    }
    etat.seances = brutes
      .filter((s) => s.places > 0)
      .map((s) => ({
        id: s.id,
        libelle: s.titre,
        jour: formaterDate(s.date),
        restantes: s.places - s.inscrits,
        complet: s.inscrits >= s.places
      }));
    etat.phase = etat.seances.length === 0 ? "vide" : "succes";
  } catch (erreur) {
    etat.phase = "erreur";
    etat.message = erreur.message;
  }
  dessiner();
}
```

L'étape suivante est le rendu. Elle reçoit l'état et n'écrit que du DOM, sans rien calculer sur les données, puisque le calcul a été fait au moment du chargement. L'ordre des instructions suit celui des quatre états : on vide la zone, on écrit le message correspondant à la phase, on ne construit les lignes du tableau que si la phase est un succès, et on n'affiche le bouton réessayer que si la phase est une erreur. Une précaution indispensable s'ajoute : le texte des données, même interne, ne doit jamais être injecté avec la propriété qui écrit du HTML brut, car une donnée contenant un signe inférieur pourrait être interprétée comme une balise. On préfère créer les éléments et assigner le contenu textuel, qui est toujours lu comme du texte.

```js
function formaterDate(iso) {
  const [annee, mois, jour] = iso.split("-");
  return jour + "/" + mois + "/" + annee;
}

function dessiner() {
  const message = document.getElementById("message");
  const corps = document.getElementById("corps");
  const bouton = document.getElementById("reessayer");
  corps.replaceChildren();

  if (etat.phase === "chargement") {
    message.textContent = "Chargement des seances...";
    bouton.hidden = true;
    return;
  }

  if (etat.phase === "erreur") {
    message.textContent = "Le chargement a echoue : " + etat.message;
    bouton.hidden = false;
    return;
  }

  if (etat.phase === "vide") {
    message.textContent = "Aucune seance disponible pour le moment.";
    bouton.hidden = true;
    return;
  }

  message.textContent = etat.seances.length + " seance(s)";
  bouton.hidden = true;
  for (const seance of etat.seances) {
    const ligne = document.createElement("tr");
    for (const valeur of [seance.libelle, seance.jour, String(seance.restantes)]) {
      const cellule = document.createElement("td");
      cellule.textContent = valeur;
      ligne.appendChild(cellule);
    }
    corps.appendChild(ligne);
  }
}
```

Le raccordement final tient en peu de lignes, mais il détermine la qualité perçue de l'écran. On déclenche le premier chargement au démarrage du module, on branche le bouton réessayer sur la même fonction, et on prévoit que deux clics rapides ne déclenchent pas deux traitements concurrents, en testant la phase avant de repartir. Si la phase est déjà un chargement en cours, on sort immédiatement. Cette petite garde-fou, associée à l'annulation de la section précédente, suffit à éliminer la majorité des double-envois rencontrés en pratique.

```js
const bouton = document.getElementById("reessayer");
bouton.addEventListener("click", () => {
  if (etat.phase === "chargement") {
    return;
  }
  chargerInscriptions();
});

chargerInscriptions();
```

La dernière étape consiste à basculer de la source locale vers la source réelle sans toucher au reste. Il suffit de remplacer l'appel de complaisance par un appel fetch, de vérifier ok, de lire la réponse en JSON, puis de confier le résultat aux mêmes filtres et transformations. Le rendu, les états et le bouton réessayer n'ont pas bougé d'une ligne : c'est la preuve que la séparation entre chargement, transformation et affichage était la bonne. Gardez la version locale sous la main, elle vous servira à tester les cas d'erreur et de liste vide sans jamais dépendre de la disponibilité du réseau.

Avant de passer à l'exercice pratique, voici la liste de contrôle de ce projet. L'écran affiche un message de chargement immédiatement, avant tout appel. Les données reçues sont vérifiées puis traduites en objets d'affichage avec map après un filtre. Le tableau n'est construit que dans la phase de succès, et les cellules reçoivent du contenu textuel, jamais du HTML. L'absence de résultat affiche une phrase explicite, différente de l'erreur. L'échec affiche un message et un bouton réessayer qui relance la fonction complète. Aucun appel ne peut démarrer pendant qu'un autre est en cours. Enfin, le même code fonctionne hors réseau avec la source locale, et fonctionne en ligne dès que vous rétablissez l'appel distant.

- Centralisez l'état de l'écran dans un seul objet : état, message, liste, compteur.
- Une fonction de chargement qui calcule, une fonction de rendu qui affiche, rien de plus.
- Validez la forme des données avant de les transformer, puis reformatez avec `map`.
- N'injectez jamais de données externes dans du HTML interprété : écrivez du contenu textuel.
- N'affichez les lignes que dans la phase de succès, le message adapté dans les trois autres.
- Le bouton réessayer rappelle la même fonction et refuse un double déclenchement.
- Passez de la source locale à `fetch` en ne changeant que la fonction de chargement.
$lesson$),
  ('web-c4-p13', 'web-c4', 13, $lesson$À retenir$lesson$, $lesson$
- `map` transforme, `filter` sélectionne, `reduce` agrège : les trois créent un résultat neuf.
- `sort` modifie le tableau d'origine et trie par défaut comme des textes : copiez avant de trier.
- Les données d'une API sont des objets : déstructurez-les, ajoutez des valeurs par défaut, recopiez-les avec le spreading.
- Les propriétés calculées construisent une clé à la volée, idéales pour indexer une liste avec `reduce`.
- Une fonction fléchée n'a pas de `this` propre et renvoie implicitement son expression.
- Préférez `let` et `const`, bloqués au bloc, à `var` hérité de l'ancien modèle de portée.
- Une fermeture garde en mémoire l'environnement où elle a été créée : c'est la base des compteurs et des états.
- Un fichier avec `export` devient un module, chargé en différé et en mode strict.
- La pile d'appels ne contient qu'une seule chose à la fois : une opération longue fige la page.
- `setTimeout` décale, ne synchronise pas ; la boucle d'événements traite les promesses avant les tâches ordinaires.
- Une promesse change une seule fois d'état, et `then` renvoie toujours une nouvelle promesse.
- `Promise.all` s'arrête au premier rejet, `Promise.allSettled` ne s'arrête jamais, `Promise.race` tranche sur le premier.
- Une fonction `async` renvoie toujours une promesse et `await` suspend cette seule fonction.
- Enchaînez des `await` uniquement s'ils dépendent réellement l'un de l'autre.
- `fetch` renvoie une réponse : vérifiez `ok`, puis lisez le corps une fois avec `json`.
- Une erreur réseau rejette la promesse, une réponse en échec se détecte par le statut.
- Tout écran connecté affiche un des quatre états : chargement, succès, vide, erreur.
- Sécurisez chaque appel avec un délai maximum, une annulation et un anti-rebond.
$lesson$),
  ('web-c4-p14', 'web-c4', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : utiliser `map` pour ses effets de bord, par exemple afficher chaque élément → Correction : `map` produit une liste ; pour agir sans résultat, utilisez `forEach`.
- Piège : oublier la valeur initiale de `reduce` sur un calcul de somme → Correction : fournissez toujours le point de départ, notamment `0` pour un total numérique.
- Piège : trier un tableau de nombres sans comparateur → Correction : passez un comparateur soustraitif ou copiez le tableau avant de trier.
- Piège : attendre un objet de `fetch` alors qu'il renvoie une réponse → Correction : vérifiez `ok` puis appelez `json`, qui renvoie lui-même une promesse.
- Piège : ne tester que le rejet et oublier les statuts d'échec → Correction : contrôlez `ok` avant toute lecture, sinon la page reste bloquée sur le chargement.
- Piège : écrire des `await` successifs pour des appels indépendants → Correction : lancez tous les appels puis attendez-les avec `Promise.all`.
- Piège : attraper l'écran entier dans un seul `try` global → Correction : localisez l'erreur et affichez un état dédié, le détail restant pour la console.
- Piège : confondre liste vide et panne, et afficher une erreur quand il n'y a simplement pas de résultat → Correction : une phase vide a son message et son action propre.
- Piège : laisser le bouton actif pendant le chargement → Correction : désactivez-le ou testez la phase avant de relancer l'appel.
- Piège : ignorer l'annulation et laisser une réponse tardive écraser l'écran → Correction : annulez l'appel précédent ou rejetez la réponse qui n'est plus la dernière.
- Piège : injecter des données reçues avec une écriture de HTML brut → Correction : créez les éléments et assignez le contenu textuel.
- Piège : placer une clé secrète dans le script du navigateur → Correction : passez par votre serveur, toute clé lue par le visiteur n'est plus secrète.
$lesson$),
  ('web-c4-p15', 'web-c4', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation de Mozilla reste la référence la plus pratique pour approfondir ce chapitre. Commencez par la page https://developer.mozilla.org/docs/Web/API/Fetch_API, qui détaille la requête, la réponse et les options, puis par https://developer.mozilla.org/docs/Web/JavaScript/Reference/Statements/async_function, qui couvre async, await et la gestion des erreurs associée. Pour les méthodes de tableaux, la page https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Array/map donne des exemples renouvelés et signale les cas particuliers ; ses pages voisines pour filter et reduce suivent exactement le même plan. Ces pages sont mises à jour à chaque évolution des navigateurs : c'est l'endroit où trancher un doute plutôt que de recopier un extrait ancien trouvé ailleurs.

Le cours Learn JavaScript de web.dev, accessible à l'adresse https://web.dev/learn/javascript/, propose des leçons progressives avec des démonstrations interactives et un accent particulier sur les promesses et l'asynchrone. Côté service de données, la documentation d'Open-Meteo, rassemblée sur https://open-meteo.com/, explique chaque paramètre avec des exemples d'adresse complets : c'est le terrain idéal pour vos essais, puisque rien ne demande de compte. Prenez le temps de feuilleter ces ressources plutôt que de les lire d'un bout à l'autre : revenez-y quand une question précise se pose, gardez-les en favori pour le jour où vous brancherez votre premier vrai service.

Un dernier conseil de pratique : ouvrez toujours la console des développeurs pendant vos essais. Filtrez les messages, regardez le réseau réel des requêtes, inspectez la forme exacte de la réponse avant d'écrire la ligne qui la transforme. Une bonne partie du débogage asynchrone consiste à regarder ce qui circule réellement, plutôt qu'à relire son propre code à la recherche d'une faute invisible.
$lesson$),
  ('web-c4-p16', 'web-c4', 16, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
Vous avez franchi le passage le plus important du parcours : votre page ne se contente plus d'afficher ce qui est écrit dans le fichier, elle va chercher ses informations au moment où elle en a besoin, elle les vérifie, les reformate et les présente dans un état clairement assumé. Reprenez immédiatement la consigne de l'exercice pratique qui suit cette leçon : vous y construirez seul le tableau des inscriptions, avec sa fonction de chargement asynchrone, ses quatre états, son rendu et son bouton réessayer, d'abord sur la source locale puis sur un appel réel. C'est à ce moment-là que vous mesurerez ce que vous avez réellement retenu de map, de reduce, de await et de la distinction entre rejet de promesse et statut en échec. Le quiz de quatre questions qui accompagne le chapitre vous permet de vérifier les notions essentielles en quelques minutes.

Passé cet exercice, le parcours aborde sa dernière ligne droite : la mise en production de ce que vous avez construit. Vous verrez comment structurer un projet pour qu'il reste modifiable, comment tester les cas d'erreur sans dépendre du réseau, et comment présenter un travail qui se lit aussi bien dans la console que sur l'écran. Conservez donc précieusement le tableau des inscriptions : vous le reprendrez comme socle, et le contraste entre la version filaire d'aujourd'hui et sa version affinée vous montrera combien la qualité d'une application tient autant à la façon dont elle échoue qu'à la façon dont elle réussit.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('web-c5-p1', 'web-c5', 1, $lesson$Pourquoi versionner son code$lesson$, $lesson$
Bienvenue dans le cinquième chapitre du parcours Développement web moderne, un chapitre consacré à deux outils que l'on ne voit jamais dans une page web mais dont dépend tout ce que vous écrivez : Git pour la sauvegarde et le partage du code, npm pour la gestion des bibliothèques. Pendant les quatre chapitres précédents, vous avez construit, ligne après ligne, le site de l'atelier de la Médiathèque des Lilas : un squelette HTML sémantique, une mise en forme, des interactions, un formulaire d'inscription. À chaque enregistrement, vous avez remplacé la version d'avant par la nouvelle, sans autre trace que votre mémoire. Si demain un changement casse la page, si vous voulez retrouver la mise en forme d'il y a deux semaines, si un collègue reprend votre travail, il n'y a rien à quoi revenir. Ce chapitre comble ce vide avec deux logiciels gratuits, installables sur tous les systèmes et employés par la quasi-totalité des développeurs professionnels : Git conserve l'historique complet de votre code, npm gère les dépendances de votre projet. Aucun des deux ne modifie vos pages : ils changent votre manière de travailler, et ce changement-là est celui qui sépare un amateur fragile d'un développeur qui peut se tromper sans craindre de tout perdre.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, que vous aurez déjà exécutées dans un vrai terminal. Vous initialiserez un dépôt, lirez l'état que Git vous renvoie, ajouterez des fichiers à l'index et créerez vos premiers commits avec des messages explicites. Vous pousserez votre travail sur un serveur distant, le clonerez sur une autre machine, créerez des branches pour isoler une évolution, fusionnerez ces branches et résoudrez vous-même un conflit, marqueur par marqueur, sans paniquer. Du côté de npm, vous initialiserez un projet, écrirez un fichier package.json, installerez des paquets, comprenarez la différence exacte entre une installation souple et une installation fidèle, écrierez des scripts de démarrage et de compilation, et appliquerez la gestion des versions sémantiques. Le tout sera assemblé dans un mini-projet guidé : le site de l'atelier, versionné, organisé en dossiers et outillé de ses scripts npm, prêt à être poussé sur un service d'hébergement de code.

Une dernière recommandation avant d'ouvrir le terminal. Git s'apprend comme on apprend à conduire : en exécutant soi-même les commandes, pas en les regardant défiler chez quelqu'un d'autre. Rien ne remplace le geste de créer un dossier jetable, de taper git init, de lire la réponse, de commettre une erreur volontaire et de constater que rien n'est perdu. Contrairement à ce que laisserait croire le mot version, Git n'écrase jamais : chaque instantané reste accessible, chaque opération se raconte, chaque désastre se répare. Nous avancerons par étapes, en alternant explications, transcriptions de terminal et bonnes pratiques de terrain. Le fil rouge reste le site de l'atelier : vous le versionnerez d'abord en miniature dans les exemples, puis vous le rendrez complet et outillé dans le mini-projet de fin de chapitre.



La première raison de versionner est la mémoire. Un logiciel de gestion de versions, ce n'est pas un simple dossier de sauvegarde : c'est un carnet qui garde chaque état du projet, horodaté, signé et consultable à volonté. Vous pouvez demander à voir le contenu exact d'un fichier tel qu'il était mardi dernier, comparer deux versions ligne à ligne, ou revenir en arrière si une modification s'est révélée mauvaise. L'analogie la plus proche est celle du traitement de texte qui conserve l'historique des révisions, mais avec une précision bien supérieure : ici, chaque enregistrement porte un message qui explique l'intention, chaque auteur est identifié, et la comparaison porte sur l'ensemble du dossier, pas sur un seul document. Pour un site web, cela signifie que votre HTML, votre CSS et votre JavaScript avancent ensemble : vous ne pouvez plus vous retrouver avec un fichier à jour et deux fichiers oubliés.

La deuxième raison est la collaboration. Le jour où une autre personne touche au même projet que vous, le simple dossier partagé devient un piège : qui a modifié tel bloc ? à quel moment ? peut-on combiner les deux modifications ? Le système de versions répond à ces questions par construction, puisqu'il enregistre chaque changement avec son auteur et son horodatage, puis fusionne automatiquement les parties qui ne se chevauchent pas. Même en travaillant seul, cette trajectoire a une valeur immense : six mois plus tard, vous relisez l'historique et vous comprenez pourquoi vous avez pris telle décision, ce que votre mémoire, elle, aura depuis longtemps effacée. La plupart des offres d'emploi en développement citent cette compétence parmi les premières, précisément parce qu'elle conditionne toute vie en équipe.

La troisième raison est la sécurité, et elle est souvent la moins évidente au début. Avec Git, tester une idée risquée ne demande plus de copier tout le dossier en double : on ouvre une branche, on expérimente, on regarde le résultat, et si l'idée échoue on supprime la branche en revenant à ce qui fonctionnait. Rien n'est perdu, rien n'est cassé pour les autres, et le courage de se tromper augmente d'autant. À l'inverse, quand une régression apparaît, l'historique permet de localiser précisément le commit qui l'a introduite, au lieu de fouiller au hasard dans trois mois de fichiers. Ajoutez-y l'archivage : votre dépôt constitue une preuve de travail, transférable, consultable hors ligne, qui ne dépend d'aucun service payant.

- Chaque état du projet devient consultable et restaurable à volonté.
- L'historique dit qui a changé quoi, quand, et pour quelle raison.
- Les branches permettent d'essayer sans risquer le fonctionnel.
- Une régression se localise à un instant précis plutôt que dans tout le dossier.
- Le dépôt se transfère, s'archive et se partage indépendamment des machines.
- Versionner dès le premier fichier coûte zéro effort ; rattraper un an de travail, beaucoup.
$lesson$),
  ('web-c5-p2', 'web-c5', 2, $lesson$Les concepts : dépôt, index, commit, historique$lesson$, $lesson$
Git repose sur quatre idées qu'il faut bien distinguer, parce que toutes les commandes du chapitre se lisent à travers elles. La première est le dépôt, c'est-à-dire le dossier de travail augmenté d'un répertoire caché nommé .git. Ce répertoire contient toute la mémoire : les instantanés, les références, la configuration. Le supprimer revient à jeter l'historique tout en gardant les fichiers courants ; le conserver, c'est garder tout. La deuxième idée est le dossier de travail, qui est simplement le contenu visible de votre projet : vos fichiers HTML, CSS et JavaScript, exactement ce que vous ouvrez dans votre éditeur. La troisième est l'index, une zone intermédiaire où l'on dépose ce que l'on souhaite figurer dans le prochain enregistrement. La quatrième est l'historique, la suite ordonnée des enregistrements déjà validés, chaque renvoi au précédent formant une chaîne ininterrompue.

Ces quatre idées dessinent un flux qu'il faut visualiser comme un circuit fermé. Vous modifiez un fichier dans le dossier de travail. Vous le placez dans l'index avec git add, ce qui fige son état pour la prochaine capture. Vous figez l'index lui-même avec git commit, ce qui crée un instantané permanent dans l'historique. L'index se vide alors, le dossier de travail reste tel quel, et vous recommencez. Cette séparation en deux étapes, ajout puis validation, peut paraître superflue au début : en réalité, elle permet de composer une capture cohérente. Vous pouvez retoucher cinq fichiers, n'en garder que trois pour l'instant, laisser les deux autres en attente, puis recommencer le lendemain. Le commit rassemble donc des changements choisis, pas tout ce qui traîne.

Un commit est un instantané complet du projet, et non une simple difference. Il porte un identifiant unique dérivé de son contenu, un auteur, une date, un message et le pointeur vers son parent. C'est ce pointeur qui crée la chronologie : remonter d'un commit, c'est suivre le fil parent par parent jusqu'au tout premier. Cette structure en chaîne explique deux comportements que vous observerez vite. D'abord, l'identifiant d'un commit change dès que son contenu ou celui de son ancêtre change : Git calcule une empreinte, ce qui rend toute altération détectable. Ensuite, la référence d'une branche n'est rien d'autre qu'un étiquette mobile posée sur le dernier commit ; créer une branche coûte donc presque rien, puisqu'il s'agit seulement de poser une nouvelle étiquette à l'endroit où l'on se trouve.

La dernière pièce est HEAD, le pointeur qui indique l'endroit où vous êtes actuellement. En général, HEAD désigne la branche sur laquelle vous travaillez, et cette branche désigne elle-même le dernier commit. Quand vous créez une branche, HEAD reste sur l'ancienne, vous la déplacez avec git switch, et tout le monde s'accorde sur votre position courante. Si vous vous perdez un jour, deux commandes suffisent à vous repérer : git status pour l'état courant et git log pour la chronologie. Retenez que Git ne devine jamais : il vous dit toujours ce que vous avez demandé et ce qu'il attend de vous.

```bash
$ git status
Sur la branche main
Votre branche est à jour avec 'origin/main'.

rien à commiter, la copie de travail est propre

$ git status --short
 M atelier.html
?? formulaire.css
```

- Le dépôt est le dossier de travail augmenté du répertoire caché .git.
- L'index prépare le contenu du prochain commit ; le dossier de travail contient vos fichiers.
- Un commit fige l'index et porte un identifiant, un auteur, une date et un message.
- Les commits s'enchaînent par un pointeur vers leur parent : c'est l'historique.
- Une branche est une étiquette mobile posée sur un commit.
- HEAD désigne l'endroit où vous êtes : en général, la branche courante.
- Lisez toujours git status avant et après une opération : c'est votre boussole.
$lesson$),
  ('web-c5-p3', 'web-c5', 3, $lesson$Premier dépôt : init, status, add, commit, log$lesson$, $lesson$
Tout commence par un dossier. Créez-en un vide, par exemple site-atelier, placez-y les fichiers des chapitres précédents, puis lancez-y git init. La commande ne modifie aucun de vos fichiers : elle crée uniquement le répertoire .git et transforme le dossier en dépôt local, encore strictement privé, sans rien envoyer nulle part. Si c'est la première fois que vous utilisez Git sur cette machine, deux renseignements personnels restent à fournir : votre nom et votre adresse électronique, qui seront inscrits dans chaque commit. Ils ne servent qu'à l'identification, ils peuvent être globaux, et vous les saisirez une seule fois.

La commande suivante est celle que vous utiliserez le plus : git status. Elle répond à trois questions : sur quelle branche suis-je, qu'ai-je modifié sans encore l'ajouter à l'index, et qu'y a-t-il dans mon dossier que Git ne suit pas du tout ? Les fichiers non suivis apparaissent en rouge, les fichiers modifiés mais non ajoutés en rouge également, ceux qui attendent dans l'index en vert. Prenez l'habitude de la lire avant chaque étape : elle vous évite la majorité des accidents, et après quelques jours elle devient un réflexe aussi naturel que regarder le rétroviseur. Notez qu'un dossier entier peut être ignoré, ce que la section sur les exclusions détaillera.

Vient le moment de composer la première capture. Vous ajoutez les fichiers à l'index un par un ou l'ensemble du dossier, puis vous validez avec un message qui explique l'intention. Pour un premier commit, la convention universelle est d'écrire quelque chose comme version initiale du site de l'atelier. Le message n'est pas une formalité : c'est la seule chose que lira votre futur collègue, ou vous-même dans six mois, pour comprendre pourquoi cette capture existe. Un commit rassemble idéalement une seule idée cohérente, et ce premier enregistrement devrait contenir exactement ce que vous êtes prêt à considérer comme une base stable.

Enfin, vous consultez la chronologie. La forme la plus lisible associe le raccourci d'identifiant, l'aperçu du message et le graphe des branches : chaque ligne est un commit, les flèches implicites remontent vers les parents, et les astérisques dessinent les divergences de branches. Pour examiner le détail d'une capture, on ajoute l'option qui affiche la totalité, et pour mesurer ce qui a changé depuis la dernière capture, on demande la différence. Ces trois lectures, liste, détail et écart, forment le trio de navigation que vous utiliserez chaque semaine.

```bash
$ cd site-atelier
$ git init
Initialized empty Git repository in C:/projets/site-atelier/.git/

$ git config --global user.name "Camille Bernard"
$ git config --global user.email "camille@exemple.fr"

$ git add index.html atelier.html styles.css script.js
$ git commit -m "Version initiale du site de l'atelier"
[main (root-commit) 8f3c2a1] Version initiale du site de l'atelier
 4 files changed, 214 insertions(+)
 create mode 100644 atelier.html
 create mode 100644 index.html
 create mode 100644 script.js
 create mode 100644 styles.css
```

```bash
$ git log --oneline --graph --all
* 8f3c2a1 (HEAD -> main) Version initiale du site de l'atelier

$ git show --stat 8f3c2a1
commit 8f3c2a1a4d9e7b3c5f2a8d1e6b4c9f0a7d3e5b2c
Author: Camille Bernard <camille@exemple.fr>
 Date:   Fri Oct 2 10:14:07 2026 +0200

    Version initiale du site de l'atelier

 atelier.html   |  62 +++++++++++++++++
 index.html     |  48 ++++++++++++
 script.js      |  35 +++++++++
 styles.css     |  69 ++++++++++++++
 4 files changed, 214 insertions(+)

$ git diff styles.css
-  body { font-family: Arial, sans-serif; }
+  body { font-family: Georgia, serif; }
```

- git init transformne un dossier en dépôt local, sans rien envoyer.
- Renseignez une fois votre nom et votre adresse électronique avec git config.
- git status répond à trois questions : branche, modifications, fichiers non suivis.
- git add place dans l'index ce qui entrera dans le prochain commit.
- git commit -m fige l'index et exige un message explicite.
- git log --oneline --graph --all offre la vue la plus lisible de l'historique.
- git diff montre l'écart entre le dossier de travail et la dernière capture.
$lesson$),
  ('web-c5-p4', 'web-c5', 4, $lesson$Pousser : remote, push, cloner$lesson$, $lesson$
Un dépôt local est déjà précieux, mais il reste fragile : il vit sur une seule machine, il ne se sauvegarde nulle part ailleurs, et personne d'autre ne peut le lire. La manipulation qui corrige cela s'appelle distant, ou remote. Un distant est l'adresse d'un dépôt Git accessible sur un serveur, que l'on relie au nôtre sous un nom court. L'usage universel est de nommer le premier distant origin, parce que ce nom circule dans toutes les commandes et dans toutes les documentation. Ajouter un distant n'envoie rien : cela enregistre seulement l'adresse dans la configuration locale, prête à être utilisée.

L'envoi lui-même porte le nom de poussée. La première fois, on précise la branche à suivre avec l'option qui établit le lien, puis les commandes suivantes se contentent du mot simple. Après la poussée, votre code existe à deux endroits : sur votre machine et sur le serveur, à jour l'un comme l'autre. Le geste se répète ensuite à chaque avancée, souvent plusieurs fois par jour. Deux précisions pratiques s'imposent. La première : Git refuse une poussée qui écraserait du travail distant non récupéré, et ce refus est une protection, pas un bug. La seconde : l'authentification dépend du service choisi, par mot de passe ou par clé, et une fois configurée, elle ne vous redemande plus rien.

Le mouvement inverse vaut autant d'être connu. Cloner, c'est recopier un dépôt existant avec la totalité de son historique, ce qui donne sur votre machine un dossier immédiatement fonctionnel et déjà versionné. C'est ainsi qu'intervient tout nouveau membre d'une équipe, ou tout développeur qui reprend un projet ouvert. Une fois le clonage effectué, le dépôt distant d'origine s'appelle automatiquement origin et votre branche locale suit la branche distante correspondante. Pour récupérer les travaux des autres sans fusionner immédiatement, on utilise le téléchargement, qui met à jour les références distantes sans toucher à vos fichiers ; pour intégrer réellement ces travaux dans votre branche courante, on utilise la récupération, qui mélange les deux. Ces trois mots, pousser, cloner, récupérer, couvrent 95 pour cent des échanges quotidiens avec un serveur.

```bash
$ git remote add origin https://github.com/camille/site-atelier.git
$ git push -u origin main
Enumerating objects: 12, done.
Counting objects: 100% (12/12), done.
Writing objects: 100% (12/12), 2.14 KiB | 2.14 MiB/s, done.
To https://github.com/camille/site-atelier.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.

$ git push

$ git fetch origin
remote: Enumerating objects: 9, done.
 * [new branch]      main -> origin/main
```

```bash
$ git clone https://github.com/mediatheque-lilas/site-atelier.git
Cloning into 'site-atelier'...
remote: Enumerating objects: 34, done.
remote: Total 34 (delta 0), reused 0 (delta 0), pack-reused 34
Receiving objects: 100% (34/34), 8.61 KiB | 4.30 MiB/s, done.
Resolving deltas: 100% (9/9), done.

$ cd site-atelier
$ git status
Sur la branche main
Votre branche est à jour avec 'origin/main'.
```

- Un distant est l'adresse d'un dépôt serviteur ; le premier s'appelle origin.
- git remote add enregistre l'adresse, git push envoie les commits.
- L'option -u lie la branche locale à la branche distante pour les fois suivants.
- git clone recopie un dépôt complet, historique compris, dans un nouveau dossier.
- git fetch met à jour les références distantes sans modifier vos fichiers.
- Une poussée refusée protège du travail distant : récupérez avant de réessayer.
- L'authentification se règle une fois, puis Git s'en souvient.
$lesson$),
  ('web-c5-p5', 'web-c5', 5, $lesson$Travailler en branches : branch, switch, merge$lesson$, $lesson$
Une branche est, en définitive, un post-it collé sur un commit. Elle ne copie pas le projet, elle ne multiplie pas les fichiers : elle mémorise un point de l'historique, et ce post-it avance à chaque fois que vous enregistrez sur cette branche. C'est pourquoi les branchements sont instantanés et pourquoi il est bon d'en ouvrir une dès qu'une idée mérite d'être isolée. L'usage courant réserve la branche principale, souvent nommée main, à un état jugé stable, et confie à des branches de travail les évolutions en cours : une fonctionnalité, un correctif, un essai. Tant que la branche de travail n'est pas fusionnée, la branche principale reste utilisable par tout le monde.

Le cycle de travail suit toujours le même schéma en quatre temps. On crée et bascule dessus en une seule commande. On travaille normalement : modification, ajout, commit, autant de fois que nécessaire. On revient à la branche stable, qui n'a pas bougé d'une ligne. Et on fusionne la branche de travail dans la stable, ce qui rejoue les enregistrements de la première sur la seconde. Si la branche principale n'a pas bougé depuis la création de la branche de travail, la fusion est un simple déplacement de pointeur : Git aligne l'étiquette et tout est dit. Si, au contraire, la principale a avancé, Git doit réellement combiner les deux lignes d'historique, ce qui l'oblige à comparer les fichiers.

Ce mode de comparaison mérite d'être compris avant d'en sentir les limites. Pour deux zones différentes d'un même fichier, ou deux fichiers différents, la fusion est automatique : Git empile les changements et personne n'a rien à faire. Le problème naît uniquement quand les deux branches ont modifié exactement les mêmes lignes. Git ne peut pas deviner laquelle des deux intentions prévaut, et il refuse de choisir par peur de détruire du travail. Il déclenche alors un conflit, qu'il vous signale et qu'il laisse entièrement entre vos mains. La règle à intégrer dès maintenant : un conflit n'est pas une erreur, c'est une demande de décision.

Avant de conclure, une vue synthétique de tout ce que vous venez de lire. Le schéma suivant dessine une branche principale, une branche de fonctionnalité qui en part, les deux enregistrements réalisés de chaque côté, puis la fusion qui referme la boucle. Prenez le temps de le lire de gauche à droite : c'est exactement ce que git log --graph vous montrera dans votre terminal.

```text
main        A -------- B ----------- D
             \                  /
feature-form  C -------- E ----

A  première version du site (commit initial)
B  correctif de titre sur main
C  début du formulaire sur feature-formulaire
E  fin du formulaire sur feature-formulaire
D  fusion de feature-formulaire dans main

$ git log --oneline --graph --all
*   f2a91c0 (HEAD -> main) Fusion du formulaire d'inscription
|\
| * e7b4d13 Formulaire : champ courriel et bouton d'envoi
| * c1d88f5 Formulaire : structure de base
* | 93af602 Correction du titre de l'atelier
|/
* 8f3c2a1 Version initiale du site de l'atelier
```

```bash
$ git switch -c feature-formulaire
Branche 'feature-formulaire' créée et basculée dessus.

$ git add atelier.html
$ git commit -m "Formulaire : structure de base"
[feature-formulaire c1d88f5] Formulaire : structure de base

$ git switch main
$ git switch feature-formulaire
$ git merge feature-formulaire
Auto-merging atelier.html
CONFLICT (content): Merge conflict in atelier.html
Automatic merge failed; fix conflicts and then commit the result.
```

- Une branche est une étiquette sur un commit : sa création est instantanée.
- Créez et basculez avec git switch -c, revenez avec git switch.
- Fusionnez avec git merge : alignement simple ou combinaison des lignes.
- Les zones non concernées fusionnent automatiquement, sans intervention.
- Un conflit apparaît uniquement sur les lignes modifiées des deux côtés.
- Un conflit est une demande de décision, pas une erreur de votre part.
- Consultez le graphe avec git log --oneline --graph --all.
$lesson$),
  ('web-c5-p6', 'web-c5', 6, $lesson$Résoudre un conflit à la main$lesson$, $lesson$
Reprenez le scénario du mini-projet : vous avez ouvert une branche feature-formulaire pour ajouter le formulaire d'inscription, et vous avez modifié la fin du fichier atelier.html. Pendant ce temps, sur la branche principale, un correctif a été appliqué au même endroit du fichier, par exemple la reformulation du paragraphe qui annonce l'événement. Vous revenez sur la branche principale, vous fusionnez la branche de fonctionnalité, et Git s'arrête net. Il annonce que la fusion automatique a échoué, il liste les fichiers concernés, et il vous laisse le travail à faire. Rien n'a été détruit : les deux versions existent encore, l'une dans l'historique, l'autre dans le dossier de travail, et c'est à vous de dire laquelle doit survivre.

Ouvrez alors le fichier dans votre éditeur. Vous y découvrez trois zones séparées par des marqueurs que Git a insérés lui-même. La première zone, encadrée par une ligne de chevrons suivie du nom de la branche courante, contient votre version locale. Une ligne de signes égaux sépare les deux camps. La deuxième zone contient la version apportée par la branche fusionnée, fermée par une ligne de chevrons suivie du nom de cette branche. Ces marqueurs ne sont pas du code : ce sont des annotations temporaires, et leur présence dans un fichier publié signifierait qu'on a oublié de résoudre. La décision elle-même se prend ligne par ligne : vous gardez la version de gauche, ou celle de droite, ou les deux dans l'ordre qui vous convient, ou une réécriture qui combine les mérites des deux.

La procédure complète tient en six gestes, toujours dans le même ordre. D'abord, vous demandez l'état pour connaître la liste exacte des fichiers en conflit. Ensuite, vous ouvrez chaque fichier et vous éditez les zones marquées. Ensuite, vous supprimez tous les marqueurs, y compris les lignes de séparation, de sorte que le fichier redevienne un document valide. Ensuite, vous enregistrez et vous relisez le fichier en entier, parce qu'une fusion peut laisser un paragraphe vide ou un titre dupliqué. Ensuite, vous ajoutez le fichier à l'index : cette étape marque la résolution comme acquise. Enfin, vous validez la fusion, Git créant alors un commit à deux parents qui referme l'opération. Le message proposé par défaut convient très bien, on le conserve en général tel quel.

Si la situation vous semble trop confuse, une commande d'urgence existe : elle annule la fusion en cours et rend le dépôt exactement à l'état qu'il avait avant, sans laisser de trace. Elle est préciseuse tant que vous n'avez rien ajouté à l'index, et elle vaut mieux que de continuer à improviser sur un fichier confus. À l'inverse, une fois la résolution terminée, la chronologie affiche un commit de fusion relié aux deux parents, ce qui documente à jamais le moment où les deux lignes de travail ont été réunies. Un conflit bien résolu est donc un événement normal du cycle de vie d'un projet, et la pratique vous rendra sa résolution mécanique en quelques minutes.

```text
<<<<<<< HEAD
Trois heures d'initiation au HTML, ouvertes à tous les publics,
samedi 18 octobre, dans la salle 2 de la médiathèque.
=======
Trois heures d'initiation au HTML, gratuites et sur inscription,
samedi 18 octobre, de 14 h à 17 h, dans la salle 2 de la médiathèque.
>>>>>>> feature-formulaire
```

```bash
$ git merge feature-formulaire
Auto-merging atelier.html
CONFLICT (content): Merge conflict in atelier.html
Automatic merge failed; fix conflicts and then commit the result.

$ git status --short
UU atelier.html

$ git add atelier.html
$ git commit -m "Fusion du formulaire d'inscription"
[main f2a91c0] Fusion du formulaire d'inscription

$ git log --oneline --graph --all
*   f2a91c0 (HEAD -> main) Fusion du formulaire d'inscription
|\
| * e7b4d13 Formulaire : champ courriel et bouton d'envoi
| * c1d88f5 Formulaire : structure de base
* | 93af602 Correction du titre de l'atelier
|/
* 8f3c2a1 Version initiale du site de l'atelier

$ git merge --abort
```

- Un conflit naît de deux modifications des mêmes lignes : Git refuse de choisir.
- Les marqueurs ouvrent la version locale, séparent les versions, ferment avec le nom de la branche apportée.
- Supprimez les marqueurs en gardant le texte voulu, puis relisez le fichier en entier.
- La sortie abrégée signale les conflits avec les deux lettres UU.
- git add marque la résolution comme acquise, git commit valide la fusion.
- git merge --abort annule proprement une fusion devenue trop confuse.
- Un commit de fusion porte deux parents : l'historique garde la trace des deux lignes.
$lesson$),
  ('web-c5-p7', 'web-c5', 7, $lesson$Bonnes pratiques : messages, petits commits, .gitignore$lesson$, $lesson$
Un historique n'a de valeur que s'il se lit. La qualité des messages est donc la première compétence à acquérir après la mécanique de base, et elle se résume à deux principes. Le premier : écrivez à l'impératif présent, comme un titre d'action, par exemple ajouter le formulaire d'inscription plutôt que formulaire ajouté ou ajout de formulaire. Le second : la première ligne doit tenir en une phrase courte qui annonce l'intention, pas la technique ; quand le contexte l'exige, laissez une ligne vide puis développez le pourquoi, parce que le comment se lit dans le diff. Certains projets adoptent un préfixe de catégorie, par exemple fonctionnalité, correctif ou documentation, pour que l'historique se trie automatiquement ; ce n'est pas obligatoire, mais l'exigence elle l'est : un message vague comme mise à jour ou corrections multiples est illisible six mois plus tard.

Le deuxième principe concerne la taille des commits. Un commit doit contenir une idée complète et indépendante : soit tout le correctif, soit rien. Mélanger dans une même capture la réparation d'un lien, la refonte d'une couleur et l'ajout d'une page revient à rendre impossible le retour en arrière ciblé, puisque vous devrez alors tout défaire ensemble. À l'inverse, un commit trop fin, qui enregistre la moitié d'une phrase, noie le message dans le bruit. La bonne échelle se mesure à une question simple : puis-je expliquer ce changement en une phrase sans utiliser le mot et ? Si la réponse est non, séparez. Avant de changer de branche ou de partager votre travail, validez aussi ce qui traîne : Git refuse de perdre des modifications, mais un dossier de travail sale rend chaque opération suivante plus confuse.

La troisième pratique est la liste d'exclusions. Tout dossier de travail contient des fichiers qui ne doivent jamais entrer dans l'historique : les bibliothèques installées, les secrets, les fichiers temporaires du système, les dossiers de sortie d'une compilation. La liste s'écrit une fois dans un fichier texte nommé .gitignore, placé à la racine du dépôt et versionné lui aussi, de sorte que la règle soit la même pour tous. Chaque ligne est un motif : un nom de dossier suivi d'une barre oblique signifie ce dossier et tout son contenu, un astérisque remplace n'importe quelle suite de caractères, et une ligne commençant par le signe exclu signifie sauf. Deux familles méritent une attention particulière : les fichiers d'environnement, qui contiennent des mots de passe et ne doivent jamais quitter votre machine, et le dossier des dépendances, si volumineux qu'il noierait l'historique en quelques commits.

```text
# Fichiers d'environnement et secrets
.env
.env.local

# Dépendances installées
node_modules/

# Sorties de compilation
dist/
build/

# Éditeurs et système
.vscode/
.idea/
.DS_Store
Thumbs.db
*.log
```

Le dernier réflexe à prendre est la consultation régulière. Avant d'ajouter, regardez ce que l'ajout contient réellement ; avant de commiter, relisez la différence ; après le commit, vérifiez la liste. Ces trois vérifications, qui coûtent quelques secondes, vous évitent d'archiver un mot de passe, un dossier de mille fichiers ou un fichier de notes personnelles. Le tableau suivant rassemble les commandes que vous utiliserez chaque jour, avec le moment juste de les employer.

```table
| Commande | Ce qu'elle fait | Moment utile |
| --- | --- | --- |
| git status | Affiche branche, modifications et fichiers non suivis | Avant et après chaque opération |
| git add fichier | Déplace un fichier dans l'index | Quand la modification est prête |
| git commit -m message | Fige l'index dans un commit | Une idée complète réalisée |
| git diff | Montre l'écart non indexé | Avant d'ajouter à l'index |
| git log --oneline --graph | Affiche la chronologie lisible | Pour se repérer dans l'historique |
| git switch -c nom | Crée et rejoint une branche | Avant toute évolution non triviale |
| git merge nom | Fusionne une branche dans la courante | Quand le travail est terminé et testé |
| git push | Envoie les commits sur le distant | Après chaque avancée validée |
```

- Les messages s'écrivent à l'impératif, en une phrase courte, avec le pourquoi si besoin.
- Un commit contient une idée complète et reste autonome par rapport aux autres.
- Versionnez toujours un .gitignore : il rend la règle identique pour toute l'équipe.
- Excluez les secrets, les dépendances installées et les dossiers de sortie.
- Relisez la différence avant chaque ajout, l'état avant chaque opération partagée.
- Ne laissez jamais traîner de modification non validée avant de changer de branche.
$lesson$),
  ('web-c5-p8', 'web-c5', 8, $lesson$Le problème des dépendances$lesson$, $lesson$
Votre site a grandi depuis le premier chapitre : le HTML structure, le CSS habille, et le JavaScript anime le menu, vérifie le formulaire, fait défiler le programme de la journée. À mesure que les besoins se multiplient, une question se pose : faut-il tout réécrire soi-même, ou s'appuyer sur du code déjà écrit et éprouvé ? La deuxième réponse est presque toujours la bonne, et elle pose immédiatement un problème logistique. Une bibliothèque externe amène avec elle ses propres besoins, qui amènent eux-mêmes d'autres bibliothèques : on se retrouve vite avec une dizaine de dossiers qui ne sont pas les vôtres, à mettre à jour, à garder compatibles entre eux, et dont chacun peut casser votre page le jour où il change.

C'est là qu'intervient la notion de dépendance. Une dépendance, c'est un morceau de code extérieur dont votre projet a besoin pour fonctionner : une bibliothèque d'animations, un utilitaire de dates, un outil de compilation pour votre feuille de style. Le mot est honnête : votre projet dépend effectivement de ces paquets, et s'ils disparaissent ou changent, vous êtes concerné. La gestion manuelle, consistant à télécharger une archive, à la décompresser dans le dossier, à noter la version dans un commentaire, fonctionne jusqu'au premier changement. Ensuite vient le jour où la mise à jour casse un appel, où personne ne sait plus quelle version est installée, et où la reprise du projet sur une autre machine devient une enquête.

Le gestionnaire de paquets répond à cela par trois mécanismes complémentaires. Le premier est la déclaration : un fichier unique liste nommément les dépendances avec les versions acceptables, ce qui rend le besoin du projet lisible d'un coup d'œil. Le deuxième est le téléchargement automatique : une commande suffit à reconstruire la totalité de l'installation à partir de cette déclaration, sur n'importe quelle machine. Le troisième est la traçabilité : une seconde ligne de commande fige exactement ce qui a été installé, y compris les dépendances indirectes, de sorte que demain reproduise aujourd'hui. C'est ce triple contrat, déclarer, installer, verrouiller, qui distingue une équipe professionnelle d'un dossier rempli d'archives copiées à la main.

npm est le nom de cet outil pour l'écosystème JavaScript. Il se présente à la fois comme un catalogue public où des millions de paquets sont publiés, et comme une commande locale qui y puise ce dont vous avez besoin. Il est livré avec l'environnement d'exécution de JavaScript côté serveur, si bien que l'installation de ce dernier vous donne npm gratuitement. Notez que le catalogue est public : publier un paquet, c'est le rendre disponible pour tout le monde, ce qui sera justement l'une des dernières étapes du mini-projet de fin de chapitre.

- Une dépendance est un code extérieur dont votre projet a besoin pour fonctionner.
- La gestion manuelle des bibliothèques tient jusqu'à la première mise à jour.
- Un gestionnaire de paquets déclare, télécharge automatiquement et verrouille.
- npm associe un catalogue public de paquets et une commande locale.
- Les dépendances directes amènent des dépendances indirectes, elles aussi versionnées.
- Lire le fichier de déclaration, c'est comprendre le projet sans ouvrir le code.
$lesson$),
  ('web-c5-p9', 'web-c5', 9, $lesson$npm : package.json, npm init, npm install$lesson$, $lesson$
Avant toute chose, vérifiez votre installation en demandant les deux versions : celle de l'environnement d'exécution et celle du gestionnaire. Si les commandes répondent, vous disposez de tout ce qu'il faut, sans rien d'autre à installer. Si elles répondent qu'introuvable, rendez-vous sur la documentation officielle de npm, à l'adresse https://docs.npmjs.com, qui détaille l'installation selon votre système d'exploitation. Cette vérification mérite d'être faite maintenant plutôt qu'au milieu d'une séance de travail : elle évite de devoir dénouer deux problèmes à la fois.

L'initialisation est un geste unique. Placez-vous à la racine de votre projet et lancez l'assistant en mode non interactif, qui accepte les valeurs par défaut et écrit immédiatement le fichier de déclaration. Ce fichier, nommé package.json, est un document structuré qui décrit le projet : son nom, sa version, son titre, sa licence, ses commandes automatiques et, surtout, la liste de ses dépendances. Il est court, il se lit entièrement en une minute, et il devient dès lors le tableau de bord du dépôt. Prenez l'habitude de l'ouvrir après chaque installation : c'est la seule façon de vérifier que le projet demande bien ce que vous croyez qu'il demande.

L'installation comporte deux gestes distincts qu'il ne faut pas confondre. Exécuter la commande d'installation sans argument reconstruit l'ensemble des dépendances déclarées : c'est ce que vous ferez sur une machine neuve, après un clonage. Exécuter la même commande avec le nom d'un paquet ajoute ce paquet au projet : le téléchargement a lieu, le fichier de déclaration est mis à jour, et deux éléments apparaissent. Le premier est un dossier local contenant le code récupéré, volumineux et destiné à être ignoré par Git. Le second est un fichier de verrouillage qui enregistre l'arborescence exacte résolue, dépendances indirectes comprises. L'option qui précise que le paquet est un outil de développement, et non une nécessité de production, le classe dans une famille distincte : les outils de compilation ou de vérification n'ont aucune raison d'être embarqués dans un site publié.

```bash
$ node -v
v22.11.0
$ npm -v
10.9.0

$ cd site-atelier
$ npm init -y
Wrote to C:/projets/site-atelier/package.json:
{
  "name": "site-atelier",
  "version": "1.0.0",
  "description": "Site de l'atelier de la Mediatheque des Lilas",
  "main": "index.html",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "license": "MIT"
}

$ npm install date-fns
added 3 packages in 1s

$ npm install --save-dev serveur-local
added 12 packages, and audited 15 packages in 2s
```

```json
{
  "name": "site-atelier",
  "version": "1.0.0",
  "description": "Site de l'atelier de la Mediatheque des Lilas",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "npx serve public",
    "build": "node scripts/build.js"
  },
  "dependencies": {
    "date-fns": "^4.1.0"
  },
  "devDependencies": {
    "serveur-local": "^14.1.0"
  },
  "license": "MIT"
}
```

Trois champs de ce fichier méritent une explication avant d'aller plus loin. Le champ nom doit être unique dans tout le catalogue si vous comptez publier votre paquet, d'où l'usage fréquent d'un préfixe d'organisation ; il doit également éviter les majuscules, les accents et les espaces, ce qui explique les tirets. Le champ version suit une règle précise que la section suivante détaillera. Le champ privé, quand il vaut vrai, empêche par sécurité une publication accidentelle : pour un site web interne, c'est le bon réflexe. Quant aux commandes automatiques, elles constituent la moitié la plus utile du fichier, et la section sur les scripts leur consacre tout son développement.

- Vérifiez votre installation avec les commandes de version avant de commencer.
- npm init -y écrit le fichier de déclaration à la racine du projet.
- Le fichier de déclaration liste projet, commandes automatiques et dépendances.
- Installer sans argument reconstruit tout ; installer avec un nom ajoute un paquet.
- Les outils de développement vont dans la famille des dépendances de développement.
- Le dossier local des dépendances ne se versionne jamais ; le fichier de verrouillage, si.
$lesson$),
  ('web-c5-p10', 'web-c5', 10, $lesson$npm ci et npm install : le verrouillage$lesson$, $lesson$
Voici un phénomène qui surprend toujours à ses débuts. Vous conservez précieusement votre fichier de déclaration, vous le transmettez à un collègue, il exécute l'installation, et le résultat diffère du vôtre : une bibliothèque a changé de version mineure et comporte désormais un comportement légèrement différent. La cause tient à la façon dont les versions sont écrites dans le fichier. On n'y indique presque jamais un numéro exact, mais une plage acceptable, marquée par un symbole qui autorise les évolutions compatibles ou les simples correctifs. Tant que personne n'installe, la plage est une promesse ; le jour de l'installation, elle se résout en la version la plus récente qui la satisfait, c'est-à-dire une version qui n'existait peut-être pas au moment où vous avez écrit le fichier.

C'est précisément le rôle du fichier de verrouillage. Généré automatiquement à chaque installation, il contient la liste exhaustive de chaque paquet résolu, avec son numéro de version exact, son empreinte d'intégrité et l'arbre complet de ses propres dépendances. Là où le fichier de déclaration dit ce qui est acceptable, le fichier de verrouillage dit ce qui est réellement en place. Les deux se complètent et les deux se versionnent : le premier exprime l'intention, le second fige la réalité. Une conséquence pratique en découle : la suppression de ce fichier, souvent tentée quand il paraît encombrant, prive l'équipe de toute reproductibilité et doit être considérée comme un incident.

Face à ce constat, deux commandes coexistent, et leur distinction est l'une des questions les plus posées aux débutants. La commande d'installation classique est souple : elle examine le fichier de déclaration, résout les plages, met à jour le fichier de verrouillage en conséquence et installe le résultat. C'est la bonne commande quand vous ajoutez, retirez ou montez une dépendance, puisque l'objectif est justement de faire évoluer la résolution. La commande dédiée à la réplication, elle, est rigide : elle supprime le dossier local, lit le fichier de verrouillage et installe exactement, à la version près, tout ce qui y est écrit, en refusant de continuer si le fichier de déclaration et le fichier de verrouillage divergent. Cette rigidité est un atout : elle transforme une divergence en échec visible plutôt qu'en différence silencieuse.

En pratique, la règle tient en une ligne : développement avec la commande souple, intégration et mise en production avec la commande rigide. Sur votre machine, quand vous faites évoluer le projet, vous utilisez la première ; sur le serveur qui construit ou publie le site, vous utilisez la seconde, après avoir récupéré les deux fichiers par Git. Le tableau suivant récapitule les différences exactes, et la commande suivante illustre le couple dans un terminal.

```table
| Critère | Installation classique | Installation stricte |
| --- | --- | --- |
| Source de vérité | Fichier de déclaration | Fichier de verrouillage |
| Mise à jour du verrou | Oui, résout les plages à nouveau | Non, refuse toute divergence |
| Dossier local | Ajoute et met à jour | Supprime puis reconstruit |
| Vitesse sur un dossier vide | Correcte | Supérieure, installations groupées |
| Usage recommandé | Développement, ajout d'un paquet | Intégration continue, production |
| Conséquence d'une divergence | Résolution implicite | Échec explicite |
```

```bash
# Développement : on accepte la mise à jour des versions
$ npm install
added 15 packages, and audited 16 packages in 3s

# Production : on reproduit l'installation à la lettre
$ npm ci
added 15 packages in 2s
audited 15 packages in 2s

# Les deux fichiers sont suivis par Git
$ git status --short
 M package.json
 M package-lock.json
```

- Les versions déclarées sont des plages, elles se résolvent au moment de l'installation.
- Le fichier de déclaration exprime l'intention ; le fichier de verrouillage fige la réalité.
- Versionnez toujours le fichier de verrouillage : c'est votre reproductibilité.
- La commande souple met à jour la résolution : développement et ajout de paquets.
- La commande rigide reconstruit à l'identique : intégration et production.
- Une divergence entre les deux fichiers provoque un échec explicite, pas une surprise.
- Ne supprimez jamais le verrouillage pour dépanner : c'est supprimer la preuve.
$lesson$),
  ('web-c5-p11', 'web-c5', 11, $lesson$Scripts npm et versions sémantiques$lesson$, $lesson$
Le champ des commandes automatiques est l'endroit où npm devient un lanceur de tâches. Chaque entrée associe un nom court à une ligne de commande shell : au lieu de retenir une syntaxe longue et variable, vous tapez le nom que vous avez défini. Les deux entrées les plus répandues sont celle du démarrage, qui lance le site en local avec un serveur de développement, et celle de la construction, qui transforme vos sources en fichiers prêts à publier. D'autres équipes y ajoutent la vérification du code, le formatage, le lancement des contrôles ou la génération de la documentation. L'intérêt dépasse le raccourci : le fichier de déclaration devient alors la documentation exécutable du projet. Quiconque le clone sait immédiatement comment démarrer, sans chercher la commande dans un fichier readme.

L'invocation suit une règle simple mais utile à connaître : les commandes définies par l'utilisateur passent par le mot run, tandis que quatre commandes historiques, dont celles du démarrage, des tests, de l'arrêt et du redémarrage, s'élident. Une autre commodité tient à la recherche : si la commande n'est pas définie chez vous, npm cherche un exécutable portant ce nom dans les outils installés, ce qui évite d'indiquer un chemin complet. C'est ainsi que de nombreux projets invoquent des outils de compilation sans jamais les lister dans leur chemin système. Attention toutefois à la commande qui affiche un message d'erreur par défaut : tant que vous ne l'avez pas remplacée, elle rappelle avec insistance qu'aucun contrôle n'est encore prévu.

La construction mérite une attention particulière pour le site de l'atelier. Vos sources vivent dans un dossier d'origine, avec des commentaires et une lisibilité maximale ; la commande de construction écrit dans un dossier de sortie des fichiers compactés, parfois regroupés, prêts à être servis par un hébergeur. Cette séparation a deux avantages : le dossier publié reste identique quelle que soit l'outil, et l'on peut le supprimer puis le régénérer à volonté, donc ne jamais le versionner. Une fois le script écrit, la publication se résume à deux commandes, celle qui construit puis celle qui copie le dossier de sortie, exactement la séquence que le mini-projet vous fera éprouver.

La dernière notion du chapitre concerne les numéros de version. Ils suivent le schéma sémantique, composé de trois nombres séparés par des points. Le premier est la version majeure : il change quand une évolution casse la compatibilité avec les versions précédentes. Le second est la version mineure : il progresse quand des fonctionnalités sont ajoutées sans casser rien d'existant. Le troisième est le correctif : il s'incrémente pour une réparation sans changement de comportement. La règle d'or pour le consommateur d'un paquet tient en une phrase : tant que l'outillage n'annonce pas de changement majeur, une mise à jour rétrocompatible ne devrait rien briser ; si elle casse quelque chose, le numéro majeur l'aura signalé à l'avance.

```json
"scripts": {
  "start": "npx serve public",
  "dev": "npx serve public --watch",
  "build": "node scripts/build.js",
  "check": "node scripts/check-lessons.mjs --dir content/lessons",
  "prebuild": "node scripts/clean.js",
  "postbuild": "node scripts/report.js"
}
```

```bash
$ npm start
> site-atelier@1.0.0 start
> npx serve public
  Local:    http://localhost:3000
  press h + enter to show help

$ npm run build
> site-atelier@1.0.0 prebuild
> node scripts/clean.js
> site-atelier@1.0.0 build
> node scripts/build.js
  4 pages copiées dans public/, 12 octets économisés
> site-atelier@1.0.0 postbuild
> node scripts/report.js
  Rapport : build OK

$ npm outdated
Package     Current  Wanted  Latest
date-fns    4.1.0    4.2.0   4.2.0
```

Les plages de versions écrites dans le fichier de déclaration s'appuient sur deux symboles qu'il faut distinguer. Le circonflexe placé devant le numéro autorise tout ce qui est compatible avec la version indiquée : pour un paquet à la version un point quatre, il acceptera les versions mineures et correctifs suivants, mais jamais la version deux. Le tilde est plus strict : il n'accepte que les correctifs. Un projet peu exigeant peut vivre avec la première écriture ; un projet qui doit se reproduire à l'identique s'appuie sur le verrouillage, quelle que soit la plage choisie. La mise à jour d'une dépendance se déroule alors simplement : on affiche ce qui est périmé, on monte la version voulue dans le fichier de déclaration, on relance l'installation souple, puis on committe les deux fichiers ensemble.

```text
1.4.2
| | |
| | +-- correctif : réparation sans changement de comportement
| +---- mineure : fonctionnalité ajoutée, rétrocompatible
+------ majeure : évolution cassant la compatibilité

^1.4.2  accepte jusqu'à 1.x.x, refuse 2.0.0
~1.4.2  accepte jusqu'à 1.4.x, refuse 1.5.0
```

- Les scripts associent un nom court à une commande, documentées dans la déclaration.
- Les commandes personnalisées s'invoquent avec run ; quatre noms historiques s'élident.
- La construction sépare les sources versionnées du dossier de sortie ignoré.
- Le schéma sémantique distingue majeure, mineure et correctif.
- Le circonflexe autorise l'évolution compatible, le tilde se limite aux correctifs.
- Mettez à jour avec la commande souple, puis versionnez déclaration et verrouillage ensemble.
$lesson$),
  ('web-c5-p12', 'web-c5', 12, $lesson$Organiser un projet : src, public$lesson$, $lesson$
Jusqu'ici, le site de l'atelier vivait à plat : pages, feuilles de style et scripts côte à côte à la racine du dossier. Cette simplicité fonctionne tant que le projet tient sur une poignée de fichiers, mais elle vieillit mal. Le jour où vous ajoutez des images, des polices, un formulaire, des notes de conception et un outil de vérification, le dossier devient une pile où personne ne sait plus ce qui se publie, ce qui se transforme et ce qui ne doit jamais partir sur un serveur. La structure d'un projet n'est donc pas de la cosmétique : c'est la première information que liront votre futur collaborateur, le moteur de déploiement et vous-même dans six mois. Une arborescence claire réduit les erreurs de chemin, simplifie les exclusions de versionnement et rend la commande de construction trivialement simple.

La convention la plus répandue repose sur deux dossiers principaux, auxquels s'ajoutent quelques fichiers de configuration à la racine. Le dossier des sources rassemble tout ce que vous écrivez et relisez : vos pages, vos styles, vos scripts, vos données. Le dossier public rassemble tout ce que le navigateur peut recevoir tel quel : les fichiers finaux, les images optimisées, les polices embarquées, le fichier des exclusions versionné. Entre les deux, la commande de construction fait le pont : elle lit les sources, applique les transformations que vous avez déclarées dans vos scripts, et écrit le résultat dans le dossier de sortie. À la racine restent les documents de pilotage, à savoir le fichier de déclaration du projet, la liste d'exclusions, un éventuel fichier de présentation et le dossier d'outillage où vivent les scripts de transformation.

Un troisième dossier, souvent oublié, mérite sa place dès que le projet automate quoi que ce soit : celui des outils. Y sont rangés les petits programmes que vous exécutez pendant la construction, par exemple celui qui copie les pages, celui qui vérifie les liens ou celui qui contrôle la hiérarchie des titres. Les garder séparés des sources évite une confusion pénible : un fichier présent dans les sources est candidat à la publication, un fichier présent dans les outils ne l'est jamais. Le même raisonnement s'applique aux données : un dossier de contenu distinct permet de publier le site sans emporter les brouillons, et de sauvegarder les brouillons sans reconstruire le site.

La discipline de nommage accompagne cette arborescence. Écrivez tous les noms en minuscules, séparez les mots par des tirets, bannissez les accents, les espaces et les majuscules : ces quatre règles suppriment d'un coup les problèmes de casse entre systèmes d'exploitation, les chemins cassés lors d'un transfert et les liens qui fonctionnent chez vous seulement. Nommez les fichiers d'après ce qu'ils contiennent, pas d'après leur apparence ou leur date, et gardez une seule convention pour tous les dossiers. Enfin, testez la structure en la montrant à quelqu'un sans commentaire : si la personne devine sans explication où se trouvent les pages publiées et où se trouvent les dépendances, l'organisation est bonne ; sinon, elle doit être revue avant que l'habitude ne s'installe.

```text
site-atelier/
|-- .gitignore              exclusions versionnées
|-- package.json            dépendances et commandes automatiques
|-- package-lock.json       résolution exacte, versionnée elle aussi
|-- README.md               présentation du projet
|-- public/                 ce qui part sur le serveur
|   |-- index.html          page d'accueil
|   |-- atelier.html        page de l'événement
|   |-- styles.css          feuille de style publiée
|   |-- script.js           interactions publiées
|   \-- images/
|       |-- logo.svg
|       \-- atelier.jpg
|-- src/                    ce que vous écrivez et relisez
|   |-- pages/
|   |-- styles/
|   \-- scripts/
\-- scripts/                outils de construction
    |-- build.js            copie les sources vers public/
    \-- check-lessons.mjs   vérifie les liens et les titres
```

- Séparez les sources, que vous écrivez, du dossier public, que le navigateur reçoit.
- Rangez les outils de construction dans leur propre dossier, jamais dans les sources.
- Gardez à la racine les documents de pilotage : déclaration, exclusions, présentation.
- Nommez en minuscules, sans accent ni espace, avec des tirets comme séparateur.
- Versionnez la structure : elle fait partie de la documentation du projet.
- Vérifiez l'arborescence avec une personne qui ne connaît pas le projet.
$lesson$),
  ('web-c5-p13', 'web-c5', 13, $lesson$Mini-projet guidé : initialiser et publier le site de l'atelier$lesson$, $lesson$
Il est temps d'assembler tout le chapitre sur votre vrai dossier. Reprenez le site de l'atelier de la Médiathèque des Lilas, celui que les chapitres précédents ont construit, et placez-vous à sa racine. L'objectif de cette séance est double : mettre l'intégralité du travail sous Git, poussée comprise, puis outiller le projet de son fichier de déclaration et de ses commandes automatiques. Ayez sous la main un terminal, votre éditeur et, si vous souhaitez tester la poussée, un compte sur un service d'hébergement de code tel que github.com ; à défaut, vous exécuterez toutes les étapes en local et vous pousserez plus tard, le résultat étant rigoureusement identique.

La première moitié de la séance installe la mémoire du projet. Vous créez le dépôt, vous écrivez la liste d'exclusions en y faisant figurer le dossier des dépendances et les fichiers sensibles, vous vérifiez l'état pour découvrir ce que Git a l'intention de suivre, puis vous réalisez la capture initiale avec un message qui annonce une base stable. Immédiatement après, vous enregistrez l'adresse de votre distant et vous poussez la branche principale en établissant le lien. Si tout se passe bien, le serveur répond en confirmant la réception d'une nouvelle branche. Cette séquence, exécutée une fois, devient un rituel : vous la rejouerez pour chaque nouveau projet, et elle vous prendra moins de deux minutes.

La seconde moitié met le mécanisme des branches à l'épreuve, parce qu'un chapitre sur Git qui n'aboutit jamais à un conflit est un chapitre incomplet. Ouvrez une branche dédiée au formulaire, modifiez le paragraphe d'introduction de la page d'événement, validez votre travail, puis revenez sur la branche principale et modifiez exactement la même zone avec une autre intention, par exemple la date et l'horaire. La fusion qui suit provoque mécaniquement le conflit. Réglez-le en suivant la procédure en six gestes : état, ouverture, suppression des marqueurs, relecture, ajout, validation. Contrôlez ensuite le graphe de l'historique : vous verrez les deux lignes se rejoindre sur un commit de fusion, preuve que les deux contributions ont été conservées et réunies.

La dernière étape outille le projet. Vous initialisez la déclaration npm avec les valeurs par défaut, vous la retouchez pour ajouter la mention qui interdit la publication accidentelle, puis vous remplacez les commandes automatiques proposées par les vôtres : une pour démarrer un serveur local sur le dossier public, une pour construire le dossier public à partir des sources, une pour vérifier les fichiers de contenu. Vous testez chaque commande dans le terminal et vous observez le résultat. Enfin, vous relancez l'installation souple pour générer le fichier de verrouillage, vous vérifiez l'état du dépôt et vous validez le tout dans un dernier commit qui unit outillage et configuration. Le projet est alors complet : mémorisé, outillé, reproductible.

```bash
# --- 1. Mémoriser le projet ---------------------------------
$ cd site-atelier
$ git init
$ git status

$ git add .gitignore
$ git commit -m "Ignorer les dependances et les fichiers sensibles"

$ git add .
$ git commit -m "Version initiale du site de l'atelier"

$ git remote add origin https://github.com/camille/site-atelier.git
$ git push -u origin main
```

```bash
# --- 2. Éprouver les branches --------------------------------
$ git switch -c feature-formulaire
$ git add atelier.html
$ git commit -m "Formulaire : structure de base"

$ git switch main
$ git add atelier.html
$ git commit -m "Correction de l'horaire de l'atelier"

$ git merge feature-formulaire
CONFLICT (content): Merge conflict in atelier.html
$ git add atelier.html
$ git commit -m "Fusion du formulaire d'inscription"

# --- 3. Outils npm et dernier commit ------------------------
$ npm init -y
$ npm install --save-dev serveur-local
$ git add package.json package-lock.json
$ git commit -m "Outils npm : demarrage et construction"
$ git push
```

```bash
# --- 4. Vérifier que tout fonctionne -------------------------
$ npm start
  Local:    http://localhost:3000

$ npm run build
  3 pages copiées dans public/

$ git log --oneline --graph --all
*   4d7e1b2 (HEAD -> main, origin/main) Outils npm : demarrage et construction
|\
| * c9a05f7 Fusion du formulaire d'inscription
| * 1b6e8d4 Formulaire : structure de base
* | 7f2a3c9 Correction de l'horaire de l'atelier
|/
* 0a5c8e1 Version initiale du site de l'atelier
* 3e9b1d0 Ignorer les dependances et les fichiers sensibles

$ git status
Sur la branche main
Votre branche est à jour avec 'origin/main'.
rien à commiter, la copie de travail est propre
```

Voici la liste de contrôle à exécuter, dans cet ordre, avant de considérer la séance comme terminée. Chaque ligne correspond à une commande que vous avez déjà vue dans ce chapitre, et aucune n'est optionnelle : c'est leur enchaînement qui constitue la compétence.

- Créez le dépôt, écrivez les exclusions, puis réalisez la capture initiale.
- Relisez git status après chaque étape : l'état raconte ce qui s'est passé.
- Enregistrez le distant et poussez la branche principale avec le lien automatique.
- Ouvrez une branche, modifiez, validez, revenez, modifiez la même zone, fusionnez.
- Résolvez le conflit à la main : état, édition, suppression des marqueurs, relecture, ajout, validation.
- Consultez le graphe : un commit de fusion doit relier les deux lignes d'historique.
- Initialisez npm, remplacez les commandes automatiques, testez-les dans le terminal.
- Générez le verrouillage, versionnez déclaration et verrouillage ensemble, poussez.
$lesson$),
  ('web-c5-p14', 'web-c5', 14, $lesson$À retenir$lesson$, $lesson$
- Versionner, c'est conserver chaque état du projet, signé, daté et consultable.
- Un dépôt est le dossier de travail augmenté du répertoire caché .git.
- L'index prépare le prochain commit ; le dossier de travail contient vos fichiers courants.
- Un commit fige l'index, porte un message, un auteur, une date et un pointeur vers son parent.
- Une branche est une étiquette mobile : sa création est instantanée et sans risque.
- HEAD désigne votre position ; git status est la boussole à consulter sans cesse.
- git add compose la capture, git commit la valide, git log la raconte.
- Un distant porte le nom origin ; on pousse, on clone, on récupère, on télécharge.
- Les zones différentes fusionnent seules ; les mêmes lignes modifiées déclenchent un conflit.
- Un conflit se résout en six gestes : état, édition, suppression des marqueurs, relecture, ajout, validation.
- Les messages s'écrivent à l'impératif et les commits restent petits et autonomes.
- Le fichier .gitignore est versionné et exclut secrets, dépendances et dossiers de sortie.
- Une dépendance se déclare, se télécharge et se verrouille : ce triple contrat rend le projet reproductible.
- Le fichier de déclaration donne l'intention, le fichier de verrouillage fige la résolution exacte.
- L'installation souple sert au développement, la commande rigide sert à l'intégration et à la production.
- Les scripts automatiques font du fichier de déclaration la documentation exécutable du projet.
- Le schéma sémantique distingue version majeure, version mineure et correctif.
- Sources, dossier public et outils vivent chacun dans leur dossier, avec des noms en minuscules.
$lesson$),
  ('web-c5-p15', 'web-c5', 15, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : hésiter à initialiser un dépôt par peur de mal faire → Correction : initialisez dans un dossier jetable, exécutez, observez ; rien n'est perdu, tout se réitère.
- Piège : commiter avec un message du type mise à jour → Correction : écrivez à l'impératif une phrase qui annonce l'intention, développez le pourquoi si nécessaire.
- Piège : créer un commit géant qui mélange cinq idées différentes → Correction : un commit, une idée ; séparez avant de valider, jamais après.
- Piège : oublier d'ajouter un fichier sensible, puis le pousser → Correction : vérifiez git status avant le commit et tenez la liste des exclusions à jour.
- Piège : versionner le dossier des dépendances installées → Correction : excluez-le dans .gitignore et ne versionnez que la déclaration et le verrouillage.
- Piège : supprimer le fichier de verrouillage parce qu'il paraît inutile → Correction : conservez-le et versionnez-le, c'est lui qui garantit la reproductibilité.
- Piège : paniquer face à un conflit et annuler tout le travail → Correction : suivez la procédure en six gestes, ou annulez proprement avec la commande d'abandon.
- Piège : résoudre un conflit en laissant une ligne de marqueurs dans le fichier → Correction : relisez le fichier en entier avant de l'ajouter à l'index.
- Piège : fusionner une branche sans l'avoir testée → Correction : testez sur la branche de travail, fusionnez seulement une fois l'évolution vérifiée.
- Piège : confondre la commande souple et la commande rigide d'installation → Correction : souple pour ajouter, rigide pour reproduire sur un autre environnement.
- Piège : publier accidentellement le projet sur le catalogue → Correction : renseignez la mention qui interdit la publication dans la déclaration.
- Piège : publier le dossier de sortie alors qu'il se régénère → Correction : ne versionnez que les sources, laissez la construction écrire le dossier de sortie.
$lesson$),
  ('web-c5-p16', 'web-c5', 16, $lesson$Pour aller plus loin$lesson$, $lesson$
La référence la plus fiable reste le site officiel de Git, accessible à l'adresse https://git-scm.com/doc. On y trouve le manuel complet, un guide de démarrage rapide et, surtout, le guide illustré des branches, qui mérite d'être lu une fois en entier : il explique avec des schémas ce que ce chapitre vous a fait pratiquer. La page des commandes de base, consultable sur le même domaine, est idéale pour réviser un geste précis avant de l'exécuter : imprimez-la ou gardez-la en favori, car elle remplace avantageusement la mémoire pendant les premières semaines.

Côté npm, la documentation officielle, regroupée sur https://docs.npmjs.com, va bien au-delà de l'installation des paquets. Les pages consacrées aux scripts, au fichier de déclaration et au fichier de verrouillage répondent exactement aux questions soulevées par ce chapitre, avec des exemples recopiables. Prenez également le temps de feuilleter le catalogue lui-même sur https://github.com, où vivent la plupart des projets open source et où l'on observe comment de vrais dépôts organisent leurs fichiers, écrivent leurs messages et documentent leurs commandes : la lecture d'un historique bien tenu enseigne autant qu'un tutoriel.

Enfin, deux exercices de consolidation valent la peine d'être ajoutés à votre routine. Le premier consiste à reprendre un ancien projet, sans versionnement, à l'initialiser et à le découper rétrospectivement en une dizaine de commits cohérents, ce qui force à reformuler l'intention de chaque étape. Le deuxième consiste à provoquer volontairement un conflit, sur un dossier jetable, puis à le résoudre dix fois de suite jusqu'à ce que la procédure devienne un automatisme. Aucun des deux n'exige un serveur distant ni une équipe : tout se joue sur votre machine, et c'est précisément ce qui les rend faciles à pratiquer chaque semaine.
$lesson$),
  ('web-c5-p17', 'web-c5', 17, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
Vous disposez désormais d'un double outillage qui change la donne pour tout ce que vous écrirez à partir d'ici. Git vous donne une mémoire infaillible et la liberté d'essayer, parce que chaque étape est datée, signée et restaurable ; npm vous donne la possibilité de vous appuyer sur le travail des autres sans perdre le contrôle de ce qui est réellement installé. L'exercice pratique qui accompagne ce chapitre est à réaliser sans regarder la leçon : il vous demande d'initialiser un dépôt, de poser les exclusions, d'ouvrir une branche de fonctionnalité, de provoquer et résoudre un conflit, de fusionner, de pousser, puis d'écrire la déclaration npm avec ses commandes de démarrage et de construction. C'est le même scénario que le mini-projet, mais exécuté seul, et c'est exactement à ce moment-là que les commandes deviennent des réflexes. Le quiz de quatre questions qui accompagne le chapitre vous permet en parallèle de vérifier les distinctions essentielles en quelques minutes.

Après l'exercice, gardez deux habitudes, et seulement deux. D'abord, initialisez un dépôt dès la création de tout nouveau dossier de travail, même vide : ce geste, pris la première minute, ne coûte rien, alors qu'il devient fastidieux de rattraper six mois de fichiers. Ensuite, validez votre travail en fin de session avec un message honnête : un historique quotidien de trois commits vaut mieux qu'un commit monumental du dimanche soir. Ces deux réflexes, répétées quelques semaines, suffisent à ancrer Git dans votre pratique et à rendre l'exercice suivant presque mécanique.

Le reste du parcours n'inventera rien de nouveau : chaque projet que vous aborderez désormais, quelle que soit la technologie, attendra que son code soit versionné, que ses dépendances soient déclarées et que son démarrage tienne en une commande. La rigueur acquise ici se transfère telle quelle, seules les commandes changent de nom. Reprenez donc le site de l'atelier, poussez-le, outillez-le, puis continuez : ce site va bientôt changer de nature, puisqu'on va le découper en composants réutilisables, et un tel chantier n'est envisageable que sur un projet versionné, outillé et reproductible. Vos futurs projets vous sauront gré d'avoir pris cette habitude au cinquième chapitre plutôt qu'au cinquantième.
$lesson$);
