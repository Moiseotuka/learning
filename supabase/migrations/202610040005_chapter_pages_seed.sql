-- easyLearn — seed des pages numérotées du Cours (678 pages, 44 chapitres)
-- Chaque section « ## » d'une leçon devient une page titrée.
-- Idempotent : remplace les pages des chapitres listés.
-- Généré par scripts/generate-pages-migration.mjs — ne pas éditer à la main.
-- Prérequis : 202610040004_chapter_pages.sql (table chapter_pages).

delete from public.chapter_pages where chapter_id in ('ard-c1', 'ard-c2', 'ard-c3', 'ard-c4', 'ard-c5', 'ard-c6', 'cyb-c1', 'cyb-c2', 'cyb-c3', 'cyb-c4', 'cyb-c5', 'cyb-c6', 'cyb-c7', 'ia-c1', 'ia-c2', 'ia-c3', 'ia-c4', 'ia-c5', 'ia-c6', 'ia-c7', 'ia-c8', 'net-c1', 'net-c2', 'net-c3', 'net-c4', 'net-c5', 'net-c6', 'net-c7', 'py-c1', 'py-c2', 'py-c3', 'py-c4', 'py-c5', 'py-c6', 'py-c7', 'py-c8', 'web-c1', 'web-c2', 'web-c3', 'web-c4', 'web-c5', 'web-c6', 'web-c7', 'web-c8');


insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('ard-c1-p1', 'ard-c1', 1, $lesson$De l'écran au monde physique : ce qu'est un microcontrôleur$lesson$, $lesson$
Bienvenue dans le premier chapitre du parcours Arduino et ESP32 : systèmes embarqués pratiques. Si vous n'avez jamais touché à un microcontrôleur, vous êtes exactement au bon endroit : rien de ce qui suit ne suppose de connaissances préalables en électronique, ni de pratique de la programmation C++, seulement l'envie de faire clignoter une LED, d'appuyer sur un bouton et de voir un programme réagir dans le monde réel. L'embarqué a cette particularité qui le rend si stimulant : votre code ne se contente pas d'afficher un résultat sur un écran, il agit sur la physique. Une ligne exécutée allume une lampe, fait tourner un moteur, ouvre une vanne, mesure une température ou déclenche une alarme. Ce chapitre pose les fondations de tout le parcours à travers trois gestes qui paraissent triviaux et qui contiennent l'essentiel : câbler une LED avec sa résistance, programmer un clignotement régulier, puis lire un bouton en assainissant son signal. Rien de spectaculaire en apparence, mais tous les chapitres suivants s'appuieront sur ces trois gestes, du capteur analogique jusqu'au projet connecté.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà réalisées sur une vraie carte posée devant vous. Vous comprendrez ce qu'est une broche d'entrée-sortie, la différence entre un niveau logique haut et un niveau logique bas, et pourquoi une carte Arduino Uno travaille en 5 volts quand un ESP32 travaille en 3,3 volts. Vous calculerez la résistance qui protège une LED avec la loi d'Ohm, vous la câblerez sur une breadboard sans la griller, vous écrirez votre premier sketch autour des fonctions setup() et loop(), puis vous remplacerez l'attente bloquante par une temporisation fondée sur millis(). Vous câblerez ensuite un bouton poussoir, vous découvrirez pourquoi une entrée laissée flottante est imprévisible, et vous mettrez en place un anti-rebond fiable, à la main puis avec la bibliothèque Bounce2. Chaque objectif est illustré par du code complet, puis repris dans un exemple pas à pas, de sorte que vous ne resterez jamais dans l'abstrait.

Un conseil sur la manière d'aborder ce cours, avant d'entrer dans le vif du sujet. L'embarqué s'apprend comme on apprend un geste manuel : en manipulant, pas en regardant. Rien ne remplace le fait de brancher soi-même les fils, de taper le code dans l'éditeur, d'appuyer sur le bouton de téléversement et d'observer ce qui se passe réellement sur la table. Les pannes font partie de l'apprentissage : une LED qui ne s'allume pas, un port série introuvable, un bouton qui déclenche trois fois au lieu d'une fois sont des situations normales, documentées dans la section consacrée aux erreurs fréquentes. Nous avancerons par étapes, en alternant explications détaillées, schémas de câblage, extraits de code commentés et tableaux de synthèse. Le fil rouge du chapitre est un programme concret qui clignote, compte les pressions sur un bouton et reste réactif pendant que le temps passe : vous le construirez pas à pas, puis vous le réécrirez seul dans l'exercice pratique qui conclut ce chapitre.



Un ordinateur classique est conçu pour dialoguer avec un humain : un écran, un clavier, une souris, des fichiers, une fenêtre. Un microcontrôleur, lui, est un ordinateur réduit à l'essentiel, dont le rôle est de surveiller des broches et de les commander en permanence. Il contient un processeur, un peu de mémoire vive, une mémoire non volatile où réside le programme, un oscillateur qui bat la mesure du temps, et une poignée de circuits appelés entrées-sorties générales, en anglais general purpose input/output, d'où l'acronyme GPIO qui désigne ces broches dans toute la documentation. Le programme que vous téléversez n'est pas une application que l'on ouvre depuis un bureau : il devient le comportement permanent de la puce. On ne clique pas dessus, on l'allume, et il tourne.

Dès que la carte est alimentée, le programme s'exécute en boucle, encore et encore, sans écran ni système d'exploitation, jusqu'à ce qu'on retire l'alimentation ou qu'on en téléverse un autre. Cette différence change tout dans la façon d'écrire le code. Votre programme ne peut pas afficher une fenêtre pour demander quoi que ce soit : il doit observer l'état des broches, décider, agir, puis observer à nouveau, sans jamais s'arrêter. Il n'y a pas d'utilisateur derrière chaque action, il y a un capteur qui devient actif, un bouton qui est enfoncé, une LED qui doit s'allumer à une heure précise. Le temps devient une ressource centrale : mesurer une durée, respecter une cadence, réagir en quelques millisecondes devient aussi important que la logique métier elle-même. C'est pour cette raison que la gestion du temps, d'abord avec des attentes simples puis avec millis(), occupe une place si importante dans ce premier chapitre, bien avant tout capteur ou tout afficheur.

La frontière entre le monde physique et le monde du programme est toujours la même : une tension mesurée ou appliquée sur une broche. Quand votre code lit une broche, il obtient l'une de deux valeurs seulement, HIGH ou LOW, c'est-à-dire un niveau haut ou un niveau bas. Sur une carte Arduino alimentée en 5 volts, le niveau haut correspond approximativement à 5 volts, le niveau bas à 0 volt, et la carte décide elle-même dans quelle catégorie ranger une tension intermédiaire, grâce à des seuils de décision internes. Quand votre code écrit HIGH sur une broche, la carte connecte cette broche à son alimentation ; quand il écrit LOW, elle la relie à la masse. Toute l'électronique du chapitre repose sur cette mécanique : forcer une tension pour commander un composant, ou observer une tension pour décider d'une action. LED, bouton, capteur, relais : ce sont des déclinaisons de ce même geste élémentaire, répété des milliers de fois par seconde.

Un point de vocabulaire vous suivra tout au long du parcours : la broche peut être configurée en sortie ou en entrée. En sortie, la broche est commandée par le programme, qui y applique une tension pour piloter un composant. En entrée, la broche est au contraire en observation : elle ne pousse rien, elle mesure ce qu'un circuit externe lui propose. Confondre les deux est l'une des erreurs de débutant les plus fréquentes, et elle se paie souvent par un composant qui ne réagit pas plutôt que par un message d'erreur : la carte ne vous préviendra pas que vous avez demandé à lire une broche que vous avez configurée en sortie. La règle est simple à retenir : tout ce qui est commandé, LED, moteur, relais, buzzeur, est en sortie ; tout ce qui est observé, bouton, capteur, signal, est en entrée.
$lesson$),
  ('ard-c1-p2', 'ard-c1', 2, $lesson$Les broches GPIO : entrées, sorties et niveaux logiques$lesson$, $lesson$
La configuration d'une broche se fait avec une seule fonction, `pinMode()`, qui attend un numéro de broche et un mode parmi les plus courants : OUTPUT pour commander, INPUT pour observer passivement, INPUT_PULLUP pour observer en activant une résistance interne de tirage vers le haut. Cette appel se place dans `setup()`, c'est-à-dire une seule fois au démarrage, parce que la configuration matérielle de la broche n'a pas de raison de changer en cours d'exécution. Une fois la broche déclarée en sortie, `digitalWrite()` y applique le niveau demandé, et `digitalRead()` renvoie HIGH ou LOW sur une broche d'entrée. Ces trois fonctions constituent l'essentiel de ce premier chapitre : tout le reste n'est qu'organisation du temps et assemblage.

Attention, un niveau logique n'est pas qu'une abstraction : c'est une tension réelle qu'un appareil de mesure peut constater. Une broche en sortie, quand elle écrit HIGH, fournit un courant limité, de l'ordre de quelques dizaines de milliampères au maximum selon les cartes. Au-delà, le circuit interne s'échauffe et finit par se détériorer, souvent sans avertissement visible. C'est la raison pour laquelle une LED ne se branche jamais directement entre une broche et la masse : une résistance en série limite le courant à une valeur sûre, généralement entre dix et trente milliampères. Le tableau suivant résume les différences principales entre les deux cartes que vous rencontrerez dans ce parcours.

| Caractéristique | Arduino Uno | ESP32 |
| --- | --- | --- |
| Tension d'alimentation logique | 5 volts | 3,3 volts |
| Niveau haut approximatif | 5 volts | 3,3 volts |
| Résistance interne de tirage | environ 20 à 50 kohms | environ 45 kohms |
| Tolérance aux entrées en 5 volts | oui | non, à proscrire |
| Broches utilisables en numérique | 14 broches numériques | plus de 20 broches numériques |

La différence de tension est le piège numéro un du débutant sur ce parcours. Une carte Arduino Uno supporte sans problème qu'on lui applique 5 volts sur une entrée, tandis qu'un ESP32 travaille strictement en 3,3 volts et n'apprécie pas qu'on lui envoie 5 volts : les broches n'ont pas de tolérance 5 volts, et un tel branchement endommage progressivement la puce. À l'inverse, une sortie ESP32 en 3,3 volts est généralement comprise comme un niveau haut par une entrée Arduino, ce qui fonctionne dans les deux sens pour les signaux de commande. Retenez la consigne simple : pour communiquer entre une carte 5 volts et une carte 3,3 volts, on redescend le signal, jamais l'inverse.

La troisième ligne du tableau mérite une attention particulière, car elle annonce le chapitre sur le bouton. Une entrée numérique n'est jamais parfaitement isolée : elle présente une impédance très élevée et capte, comme une antenne, les perturbations électriques ambiantes. Une broche d'entrée laissée sans rien brancher lit donc un état imprévisible, tantôt HIGH tantôt LOW, qui change avec l'humidité, avec le passage d'une main à proximité ou avec le simple fait de toucher le circuit. On dit alors que l'entrée flotte. Les résistances internes de tirage, activées par INPUT_PULLUP ou INPUT_PULLDOWN, existent précisément pour ancrer cette entrée à un niveau connu au repos.

Enfin, il est utile de savoir que certaines broches ne sont pas équivalentes. Sur un ESP32, quelques-unes sont liées au démarrage de la puce ou à la mémoire flash : les appeler à tort empêche la carte de démarrer correctement. D'autres ne peuvent être utilisées qu'en entrée, jamais en sortie. Sur un Arduino Uno, certaines broches partagent des fonctions spéciales, comme la réception série ou la génération d'ondes PWM. Pour ce premier chapitre, nous resterons sur des broches neutres et faciles, mais cette carte d'identité des broches vous sera demandée dès que le circuit se compliquera.
$lesson$),
  ('ard-c1-p3', 'ard-c1', 3, $lesson$Tension, courant et masse : le circuit minimal$lesson$, $lesson$
Un courant électrique ne circule jamais dans un sens unique et s'arrête quelque part : il faut un chemin complet, une boucle fermée, qui part de l'alimentation, traverse le composant, et revient à la masse. La masse, notée GND pour ground, est le point de référence commun de tout le circuit, celui dont on mesure les tensions. C'est la raison pour laquelle tout câblage de ce chapitre comporte au moins deux fils entre la carte et le composant : un fil de commande qui arrive sur la broche, et un fil de retour qui repart vers la masse. Négliger la masse est la panne de câblage la plus courante chez le débutant, qui pourtant a parfaitement inséré l'autre bout du fil dans la bonne rangée.

Voici à quoi ressemble le circuit minimal du chapitre, une LED pilotée par une broche numérique avec sa résistance de protection :

```text
Broche numérique 7 (sortie)
        |
        |
     [ R ]  résistance 220 ohms, en série
        |
        |  (+)  anode de la LED
      [>|]  LED, sens du courant : de l'anode vers la cathode
        |  (-)  cathode
        |
        |
       GND  masse de la carte
```

Suivez le trajet du courant dans ce schéma, ligne après ligne. Quand le programme écrit HIGH sur la broche 7, la broche se connecte à l'alimentation de la carte ; le courant traverse la résistance, qui en limite la valeur, puis traverse la LED dans le sens autorisé, s'allume enfin, et repart par la masse jusqu'à la source. Si l'un des maillons manque, si la masse n'est pas reliée, si la résistance est ouverte, si la LED est placée à l'envers, le courant ne circule pas et rien ne se produit. Le programme, lui, fonctionne parfaitement : c'est le circuit physique qui est incomplet. Cette distinction entre panne logique et panne de câblage vous fera gagner un temps considérable.

La LED impose elle-même son sens de circulation. C'est une diode : elle laisse passer le courant dans un seul sens et le bloque dans l'autre. Physiquement, on la reconnaît à deux indices, la jambe la plus courte qui désigne la cathode, et la partie aplatie du plastique au niveau de cette même borne. Dans un schéma électronique, son symbole est une flèche barrée, et le courant va de l'anode vers la cathode. Placée à l'envers, elle reste simplement éteinte, sans se détériorer, ce qui en fait une erreur facile à corriger une fois qu'on sait la chercher. Avant même d'allumer la carte, passez la main sur le circuit et vérifiez l'orientation de chaque LED : ce réflexe vous sauvera de nombreuses minutes perdues dans le code alors que le problème est sous vos doigts.

Pour finir, une règle de sécurité qui s'applique à tous les chapitres de ce parcours : ne reliez jamais une broche en sortie directement à la masse ni directement à l'alimentation, sans composant intermédiaire. Un tel court-circuit fait circuler un courant bien au-delà de ce que le circuit interne peut absorber, et c'est souvent le moyen le plus rapide de griller une carte. La résistance n'est pas un accessoire décoratif, c'est le fusible du circuit. Voici le matériel minimal à poser devant vous pour poursuivre, avant de passer à la breadboard :

- une carte Arduino Uno ou ESP32, alimentée par câble USB ;
- une breadboard compacte avec ses deux rails d'alimentation ;
- une LED, de préférence rouge ou verte, et une résistance de 220 ohms ;
- un bouton poussoir quatre pattes, celui qui se branche en travers d'une rainure ;
- une dizaine de fils Dupont mâle-femelle et mâle-mâle ;
- un multimètre, facultatif mais précieux, pour vérifier une tension en un instant.
$lesson$),
  ('ard-c1-p4', 'ard-c1', 4, $lesson$La breadboard : comprendre où passer le courant$lesson$, $lesson$
La breadboard, ou plaque de prototypage, est un support où l'on assemble un circuit sans souder le moindre fil. Elle est percée de trous espacés de 2,54 millimètres, le même pas que la plupart des composants et des fils Dupont, ce qui permet de tout brancher directement. Sous le plastique, chaque trou est relié à une lame métallique qui court verticalement : cinq trous alignés forment donc un seul point électrique. Toute la subtilité de la breadboard consiste à savoir quelles lames sont reliées entre elles, parce qu'une erreur de lecture transforme immédiatement deux connexions distinctes en un court-circuit involontaire.

Le principe se résume en deux zones. Au centre, la rainure centrale sépare deux moitiés : elle est conçue pour recevoir les circuits intégrés, dont les pattes des deux côtés ne doivent jamais se court-circuiter. Chaque côté de la rainure comporte des séries de cinq trous reliés horizontalement entre eux, et seulement entre eux. En haut et en bas de la plaque, deux rails longs courent sur toute la largeur : ce sont les rails d'alimentation, traditionnellement marqués d'une ligne rouge pour le positif et d'une ligne bleue pour la masse. On y amène le 5 volts et le GND de la carte, puis on puise partout ailleurs dans le circuit.

```text
   rail + (rouge)  ================================+
                                                   |
   A B C D E        rangees de 5 trous relies      |
   o o o o o  1     horizontalement seulement      |
   o o o o o  2                                   |
   o o o o o  3     --- rainure centrale ---       |
   o o o o o  4                                   |
   o o o o o  5                                   |
                                                   |
   rail - (bleu)  ================================+
```

Pour éviter toute confusion, adoptez dès maintenant une convention de couleur. Le fil rouge descend toujours du rail positif vers le composant, le fil noir ou bleu revient toujours vers la masse, et les fils de signal, eux, peuvent porter n'importe quelle autre couleur. Cette discipline n'a aucune incidence électrique, mais elle transforme la lecture d'un circuit : en jetant un œil, vous savez immédiatement où commence et où finit le courant, et vous pouvez vérifier un câblage sans avoir à suivre chaque fil à la loupe. Un circuit propre est un circuit diagnostiqué à moitié.

Un dernier conseil pratique avant d'y brancher quoi que ce soit. Insérez toujours les fils et les composants en appuyant franchement, à la verticale, sans les forcer de travers : une patte mal enfoncée produit un contact intermittent, c'est-à-dire une panne qui apparaît puis disparaît sans logique apparente, de loin le plus déroutant des défauts. Évitez également de faire traverser la rainure centrale à un fil qui n'a pas à la franchir, et n'appuyez pas sur la plaque une fois le circuit sous tension. Poser la breadboard sur une surface neutre, loin d'eau et de métal, suffit à prévenir la quasi-totalité des accidents de manipulation.
$lesson$),
  ('ard-c1-p5', 'ard-c1', 5, $lesson$Câbler une LED et calculer sa résistance$lesson$, $lesson$
La LED est un composant polarisé : elle ne fonctionne que dans un sens, et son fonctionnement dépend entièrement du courant qui la traverse. Contrairement à une lampe incandescente, elle ne se contente pas d'être alimentée, elle impose une tension propre, appelée tension directe ou tension de seuil, qui varie selon la couleur du composant. Une LED rouge tombe autour de 2 volts, une LED verte autour de 2,2 volts, une LED blanche ou bleue autour de 3 volts. Ce phénomène a une conséquence directe et redoutable si on l'ignore : branchée entre une broche et la masse sans résistance, la LED laisse passer un courant sans limite, devient très brillante un dixième de seconde, puis se détruit.

La résistance en série existe précisément pour imposer cette limite. Le courant circulant dans une boucle, la résistance consomme une partie de la tension disponible et réduit d'autant le courant qui atteint la LED. Le calcul est une simple application de la loi d'Ohm : la tension qui reste à dissiper est celle de l'alimentation moins la tension de la LED, et le courant visé, généralement 20 milliampères pour une LED standard, donne la valeur à résister. En chiffres, cela donne R égale à 5 moins 2 le tout divisé par 0,020, soit 150 ohms. On ne fabrique pas une résistance sur mesure : on prend la valeur normalisée supérieure la plus proche, 220 ohms, qui est disponible partout et qui offre une marge de sécurité.

| Couleur de la LED | Tension directe | Courant visé | Résistance sur 5 V | Résistance sur 3,3 V |
| --- | --- | --- | --- | --- |
| Rouge | environ 2 V | 15 à 20 mA | 150 à 220 ohms | 47 à 100 ohms |
| Vert ou jaune | environ 2,2 V | 15 à 20 mA | 150 à 220 ohms | 33 à 100 ohms |
| Bleu ou blanche | environ 3 V | 15 à 20 mA | 100 à 150 ohms | 10 à 33 ohms |

La tension reste-t-elle correcte dans tous les cas ? Pour vérifier autrement que par le calcul, on peut aussi partir du courant admissible, situé entre 10 et 30 milliampères selon les composants, et en déduire une plage de résistance tolérable. Une valeur trop faible laisse passer trop de courant et finit par griller la LED ou la broche ; une valeur trop haute diminue simplement la luminosité, sans aucun risque. En cas de doute, choisissez donc toujours la résistance la plus forte des deux candidates : votre œil ne verra presque aucune différence, et votre carte vivra plus longtemps.

Le câblage lui-même tient en quatre gestes. Insérez la résistance sur une rangée de cinq trous, puis la LED sur la même rangée en respectant le sens, jambe courte vers la masse. Reliez l'autre patte de la résistance à la broche numérique choisie, par exemple la broche 7, et la patte courte de la LED au rail de masse. Reliez enfin les rails de la breadboard aux bornes 5 volts et GND de la carte. Voici le résultat sous forme de schéma équivalent, à comparer avec le vôtre avant toute mise sous tension :

```text
   broche 7 ----[ 220 ohms ]----|>|---- GND
                                LED
                          (patte longue du cote
                           de la resistance)
```

Une vérification visuelle rapide suffit ensuite à valider le montage. La patte longue de la LED doit être du côté de la résistance, c'est-à-dire du côté de la broche, et la patte courte du côté de la masse. Si votre LED reste éteinte alors que le programme tourne, débranchez l'alimentation, inversez la LED, et relancez l'essai avant de soupçonner le moindre ligne de code. Sur les cartes récentes, une LED est déjà montée sur la carte elle-même sur la broche 13 : elle constitue le banc d'essai idéal pour valider votre premier sketch avant de toucher au moindre fil.
$lesson$),
  ('ard-c1-p6', 'ard-c1', 6, $lesson$Votre premier sketch : setup() et loop()$lesson$, $lesson$
Un programme Arduino se nomme un sketch, il est stocké dans un fichier à extension .ino, et il comporte obligatoirement deux fonctions : `setup()`, exécutée une seule fois au démarrage ou après un téléversement, et `loop()`, exécutée en boucle indéfiniment aussitôt après. Cette architecture reflète exactement ce que disait le début du chapitre : il n'y a pas de début ni de fin au programme, il y a une initialisation puis une répétition perpétuelle. Tout ce que vous écrivez en dehors de ces deux fonctions, déclarations globales et constantes, est disponible partout, mais l'exécution ne commence réellement que par `setup()`.

Le sketch le plus classique fait clignoter la LED de la carte, celle qui est déjà soudée sur la broche 13. Le voici complet, et il est censé fonctionner tel quel :

```cpp
const int LED_INTERNE = 13;

void setup() {
  pinMode(LED_INTERNE, OUTPUT);
}

void loop() {
  digitalWrite(LED_INTERNE, HIGH);
  delay(1000);
  digitalWrite(LED_INTERNE, LOW);
  delay(1000);
}
```

Lissons ce code ligne à ligne, parce qu'il concentre toutes les notions vues jusqu'ici. La première ligne déclare une constante : le numéro de broche est fixe, il ne changera jamais, et le placer dans un nom explicite évite de devoir chercher un chiffre perdu au milieu du code plus tard. Dans `setup()`, `pinMode()` configure la broche 13 en sortie, une seule fois. Dans `loop()`, `digitalWrite()` allume la broche, `delay()` attend une seconde, puis l'instruction suivante l'éteint et attend à nouveau. La boucle se referme, recommence, et la LED clignote indéfiniment à la cadence d'une seconde.

La fonction `delay()` mérite ici un avertissement que nous développerons au chapitre suivant : elle fige réellement l'exécution du sketch pendant toute la durée demandée. Pendant cette seconde d'attente, le microcontrôleur ne fait absolument rien d'autre : il ne lit aucun capteur, aucun bouton, aucun signal. Pour un clignotement isolé, cela n'a aucune importance. Dès que le programme doit réagir à un événement en même temps, cette approche devient intenable. Retenez donc dès maintenant qu'il s'agit d'un raccourci pédagogique, utile pour apprendre la syntaxe, que nous allons très vite remplacer par une mesure du temps non bloquante.

Le téléversement lui-même est un geste à connaître, parce qu'il échoue parfois. Sélectionnez votre carte et le bon port dans le menu de l'éditeur, cliquez sur téléverser, et patientez quelques secondes pendant que le code est compilé puis chargé dans la mémoire non volatile de la puce. Si l'opération échoue avec un message de port introuvable, le câble USB est souvent un simple câble d'alimentation qui ne transporte pas de données, ou le pilote du port série manque sur votre système. Si elle échoue avec une erreur de compilation, lisez la ligne indiquée : le compilateur signale presque toujours l'endroit exact où la syntaxe dévie de ce qu'attend le langage.

Une fois le sketch téléversé, observez ce qui se passe concrètement : la LED de la broche 13 clignote, la carte ne consomme presque rien, et le programme continue de tourner même si vous débranchez l'ordinateur, pourvu que l'alimentation reste présente. C'est toute la différence avec un programme de bureau. Pour modifier la cadence, changez une des deux durées de mille millisecondes, par exemple en cinq cents, puis téléversez à nouveau : la LED accélère. Ce cycle écrire, téléverser, observer, corriger est le rythme de travail du développeur embarqué, et vous le répétez des dizaines de fois dans ce seul chapitre.
$lesson$),
  ('ard-c1-p7', 'ard-c1', 7, $lesson$Le temps dans un programme embarqué : de delay() à millis()$lesson$, $lesson$
La fonction `delay()` est la première temporisation que l'on découvre, et elle est trompeuse : elle fait exactement ce qu'on lui demande, mais d'une manière qui paralyse le reste du programme. En interne, elle ne fait rien d'autre que tourner dans une boucle vide jusqu'à ce que la durée demandée se soit écoulée. Le microcontrôleur est disponible, le compteur de temps avance, mais aucune instruction de votre sketch n'est exécutée pendant cet intervalle. Si vous programmez un clignotement de deux secondes, votre carte est donc sourde pendant deux secondes entières : elle ne lit ni bouton, ni capteur, ni message série.

Considérons un exemple concret pour mesurer l'ampleur du problème. Vous écrivez un programme qui allume une LED pendant une seconde, l'éteint pendant une seconde, et qui doit en plus compter les pressions sur un bouton. Avec `delay()`, la lecture du bouton ne peut avoir lieu que pendant une fraction infinitésimale de la boucle, ou alors elle se trouve elle-même placée dans une attente. Le résultat est un programme qui paraît fonctionner, jusqu'au moment où l'on appuie sur le bouton pendant une pause et où rien ne se passe. Ce type de défaillance ne produit aucune erreur à l'écran : le code compile, la carte tourne, seule la réactivité disparaît.

```cpp
void loop() {
  digitalWrite(LED, HIGH);
  delay(1000);
  digitalWrite(LED, LOW);
  delay(1000);
  // Pendant les 2 secondes ecoulees, aucune lecture de bouton
  // n'a pu avoir lieu : le programme etait fige.
}
```

La solution consiste à demander l'heure au système au lieu de suspendre l'exécution. La fonction `millis()` renvoie le nombre de millisecondes écoulées depuis le démarrage de la carte, sous forme d'un entier non signé sur 32 bits. Elle ne bloque jamais, elle coûte presque rien, et elle peut être appelée autant de fois que nécessaire. Le patron de programmation qui en découle est toujours le même : on mémorise l'instant de la dernière action, puis, à chaque passage de la boucle, on vérifie si l'écart avec l'instant courant atteint la durée visée. Dès que c'est le cas, on déclenche l'action et on réinitialise la référence.

```cpp
unsigned long dernierClignotement = 0;
const unsigned long INTERVALLE = 1000;

void loop() {
  unsigned long maintenant = millis();

  if (maintenant - dernierClignotement >= INTERVALLE) {
    dernierClignotement = maintenant;
    etatLED = !etatLED;
    digitalWrite(LED, etatLED ? HIGH : LOW);
  }
  // Le reste de la boucle reste libre : on peut lire le bouton ici.
}
```

Pourquoi cette soustraction fonctionne-t-elle alors que les entiers finissent par déborder ? Parce que le type est non signé : la soustraction circule modulo 2 exposant 32, et la différence reste correcte tant que l'intervalle testé est inférieur à la durée maximale représentable, soit environ 49 jours. En pratique, on ne mesure jamais des durées de plusieurs jours, donc le patron ci-dessus est robuste, à condition de ne jamais comparer directement deux instants avec un opérateur de supériorité. C'est l'une des règles d'or de la programmation temps réel : on compare toujours des durées, jamais des dates absolues.

Une même boucle peut porter autant de temporisations indépendantes qu'il le faut, à condition de donner à chacune sa propre variable de référence. C'est ainsi que l'on fait clignoter une LED pendant que l'on relit un bouton, pendant qu'on envoie une trame série toutes les secondes et pendant qu'on surveille une entrée analogique. La structure reste rigoureusement identique d'un cas à l'autre : une variable globale de dernier déclenchement, un entier constant pour l'intervalle, un test de dépassement, puis l'action et la mise à jour de la référence. Une fois ce motif en main, le mot bloquant disparaît de votre vocabulaire.

Il reste un piège à connaître avant de passer au bouton : la durée d'une temporisation doit être calculée à partir de la référence, et non à partir de l'instant courant, sinon les dérives s'accumulent. Si chaque cycle prend une milliseconde de plus que prévu, une référence mise à jour avec `maintenant` plutôt qu'avec l'instant réel du déclenchement provoque une lente dérive de la cadence. Pour une LED, personne ne s'en apercevra ; pour une horloge ou une transmission série, l'erreur devient visible en quelques minutes. Gardez donc la formule courte : référence égale instant courant, écrite à l'intérieur du bloc de déclenchement, jamais en dehors.
$lesson$),
  ('ard-c1-p8', 'ard-c1', 8, $lesson$Lire un bouton : entrée, pull-up et logique inversée$lesson$, $lesson$
Le bouton poussoir est le composant d'entrée le plus simple qui existe : deux lames conductrices, séparées au repos, que l'on rapproche en appuyant. Électriquement, il ne fait rien d'autre que connecter ou déconnecter deux points du circuit. Toute la difficulté vient du fait qu'une broche d'entrée, elle, n'est jamais tout à fait isolée : avec une impédance très élevée, elle capte les perturbations ambiantes et son état devient imprévisible quand aucun circuit ne la dicte. C'est le phénomène de broche flottante, et il produit des lectures fantômes qui font croire à un programme correct qu'on appuie sur le bouton alors qu'il est posé seul sur la table.

```text
   Version a resistance externe (pull-down)
   5V ----[ 10 kohms ]----+---- broche d'entree
                           |
                        [ bouton ]
                           |
                          GND

   Version a pull-up interne (recommandee)
   broche d'entree ----+----[ bouton ]---- GND
                       |
                 resistance interne
                 activee par INPUT_PULLUP
```

Deux montages classiques ancrent l'entrée à un niveau déterminé. Le premier ajoute une résistance externe, dite de tirage, qui relie la broche soit à l'alimentation, soit à la masse ; le bouton fait alors l'inverse, ramenant la broche vers l'autre niveau quand on l'enfonce. Le second exploite une résistance intégrée dans la puce elle-même, activée par la commande `pinMode(pin, INPUT_PULLUP)` : elle tire la broche vers le haut en permanence, et le bouton, relié simplement entre la broche et la masse, la ramène vers le bas lorsqu'on appuie. Ce second montage est préférable, car il économise un composant et tire parti d'une fonctionnalité prévue pour cela.

La conséquence est une logique inversée qu'il faut intégrer dès le départ : avec un pull-up, la broche lit HIGH tant que le bouton n'est pas pressé, et LOW dès qu'on l'enfonce. Un débutant écrira naturellement la condition opposée, constatera que son programme fait exactement l'inverse de ce qu'il attend, puis cherchera la panne dans le câblage alors que tout est câblé correctement. Écrivez ce principe sur un adhésif posé sur votre écran : repos égal HIGH, appui égal LOW. Toute la suite du chapitre, y compris l'exercice pratique, repose sur cette convention.

La lecture elle-même tient en peu de lignes, mais l'organisation compte davantage que la syntaxe. Lire l'état brut à chaque passage de la boucle, le comparer à l'état précédent, et n'agir que lors d'un changement, permet de transformer un niveau en un événement. C'est la distinction fondamentale entre un niveau, qui décrit l'état actuel, et une frontière, qui marque le moment précis du passage. Un programme qui compte les pressions doit réagir aux frontières ; un programme qui pilote un moteur tant qu'on appuie doit, lui, observer le niveau.

```cpp
const int BOUTON = 2;
bool etatPrecedent = HIGH;

void loop() {
  bool etatActuel = digitalRead(BOUTON);

  if (etatActuel == LOW && etatPrecedent == HIGH) {
    compteur = compteur + 1;
    Serial.println(compteur);
  }

  etatPrecedent = etatActuel;
}
```

Ce fragment contient déjà la moitié du problème suivant. Une pression humaine dure entre cent et trois cents millisecondes, ce qui représente des dizaines de milliers de cycles de la boucle : sans filtrage, le front détecté peut être compté plusieurs fois si le signal oscille. La détection de front reste donc indispensable, mais elle ne suffit pas à elle seule. Il faut lui adjoindre un mécanisme qui considère que les transitions trop rapprochées sont de la même pression, et c'est exactement le rôle de l'anti-rebond que nous allons mettre en place à présent.
$lesson$),
  ('ard-c1-p9', 'ard-c1', 9, $lesson$Le rebond mécanique et l'anti-rebond$lesson$, $lesson$
Le rebond, ou rebondissement, est un phénomène purement physique. Au moment où les lames d'un bouton se rejoignent, elles ne s'établissent pas en une fois : elles se heurtent, s'écartent, se recontactent, pendant quelques millisecondes, avant de trouver un appui stable. À l'ouverture, le même phénomène se produit en sens inverse. Sur un oscilloscope, on observe une série d'impulsions erratiques là où l'on s'attendait à un front net. Le microcontrôleur, lui, voit exactement cela : des dizaines de fronts au lieu d'un seul, qu'il compte scrupuleusement si on lui a demandé de le faire.

Conséquence pratique, et elle est fréquente : vous appuyez une fois sur le bouton, et votre compteur affiche trois, cinq ou parfois dix pressions. Le câblage est bon, la logique est bonne, la lecture est bonne. C'est la granularité temporelle du programme qui est trop fine : là où l'œil humain voit un geste, la carte voit un événement complexe. Toute la difficulté d'anti-rebond consiste donc à décider, en se fondant sur le temps, ce qui constitue une pression distincte et ce qui n'en est qu'un écho.

La méthode la plus simple consiste à attendre, après la détection d'un front, que la situation se stabilise. On lit le bouton, dès qu'on détecte un appui on attend une vingtaine de millisecondes, on relit, et on n'accepte le changement que si l'état est toujours celui attendu. Cette approche fonctionne, mais elle repose sur `delay()` et bloque donc la boucle vingt millisecondes à chaque appui : acceptable quand rien d'autre n'est à faire, insupportable dès que le programme pilote autre chose.

```cpp
void loop() {
  if (digitalRead(BOUTON) == LOW) {
    delay(20);
    if (digitalRead(BOUTON) == LOW) {
      compteur = compteur + 1;
      while (digitalRead(BOUTON) == LOW) { /* attendre le relachement */ }
      Serial.println(compteur);
    }
  }
}
```

La version professionnelle remplace l'attente par un horodatage. On mémorise l'instant du dernier changement accepté, et on refuse tout nouvel état tant que moins de vingt millisecondes ne se sont pas écoulées depuis ce dernier. La boucle continue de tourner, les autres temporisations continuent de fonctionner, et l'anti-rebond devient invisible pour le reste du programme. C'est ce même patron non bloquant que nous appliquions déjà au clignotement, transposé du domaine de la cadence à celui de l'assainissement du signal.

```cpp
const unsigned long ANTI_REBOND = 20;
unsigned long dernierChangement = 0;
bool etatStable = HIGH;

void lireBouton() {
  bool lu = digitalRead(BOUTON);
  unsigned long maintenant = millis();

  if (lu != etatStable && maintenant - dernierChangement > ANTI_REBOND) {
    dernierChangement = maintenant;
    etatStable = lu;
  }
}
```

Il existe enfin une solution clé en main, la bibliothèque Bounce2, qui encapsule exactement la logique précédente et ajoute des commodités : détection de fronts, appui maintenu, durée d'appui mesurée. Elle s'utilise après avoir inclus l'en-tête, en déclarant un objet de type Bounce, en attachant la broche dans `setup()` avec la durée d'anti-rebond choisie, puis en appelant sa méthode d'actualisation à chaque passage de la boucle. Le coût d'apprentissage est minime et l'avantage devient réel dès que le circuit compte plusieurs boutons.

```cpp
#include <Bounce2.h>

Bounce bouton = Bounce();

void setup() {
  pinMode(BOUTON, INPUT_PULLUP);
  bouton.attach(BOUTON);
  bouton.interval(20);
}

void loop() {
  bouton.update();
  if (bouton.fallingEdge()) {
    compteur = compteur + 1;
    Serial.println(compteur);
  }
}
```

Quelle que soit la méthode retenue, la durée d'attente se règle entre dix et cinquante millisecondes. Trop courte, elle laisse passer des rebonds ; trop longue, elle avale des pressions rapides successives et donne au bouton une sensation de décalage. Vingt millisecondes constitue un excellent point de départ pour un bouton standard. Le choix final se vérifie toujours de la même façon : appuyez dix fois en enfilade, observez le compteur, et ajustez. Dix appuis doivent donner exactement dix, jamais sept ni onze.
$lesson$),
  ('ard-c1-p10', 'ard-c1', 10, $lesson$Assembler le programme complet non bloquant$lesson$, $lesson$
Toutes les pièces sont désormais sur la table : la LED protégée par sa résistance, le bouton avec son pull-up et son anti-rebond, les temporisations fondées sur millis(), et la distinction entre niveau et front. Le moment est venu de les rassembler dans un seul sketch, celui qui servira de modèle à l'exercice pratique de ce chapitre. L'objectif est double : faire clignoter la LED à cadence régulière, et réagir aux pressions sur le bouton pendant ce clignotement, sans qu'une action n'interfère jamais avec l'autre. Si le programme répond pendant que la LED clignote, c'est que la boucle n'est effectivement jamais bloquée.

La structure se lit en trois temps. Des constantes décrivent le câblage et les durées, puis viennent les variables d'état qui mémorisent ce que le programme retient d'une boucle à l'autre : le dernier clignotement, l'état stable du bouton, le dernier changement accepté, le compteur de pressions. Enfin, `setup()` configure les broches et démarre le port série, pendant que `loop()` lit, filtre, décide et agit. Ce découpage n'est pas une convention de style, il reflète la mécanique du microcontrôleur : tout ce qui doit survivre entre deux passages de la boucle doit être déclaré en dehors de cette boucle.

```cpp
const int LED = 7;
const int BOUTON = 2;

const unsigned long INTERVALLE = 500;
const unsigned long ANTI_REBOND = 20;

bool etatLED = false;
bool etatPrecedent = HIGH;
bool etatStable = HIGH;
unsigned long dernierClignotement = 0;
unsigned long dernierChangement = 0;
int compteur = 0;

void setup() {
  pinMode(LED, OUTPUT);
  pinMode(BOUTON, INPUT_PULLUP);
  Serial.begin(9600);
  Serial.println("Demarrage du programme");
}
```

La boucle proprement dite reste volontairement courte, et chaque bloc y a une responsabilité unique. Le premier lit l'état brut du bouton et le compare à l'état stable, en n'acceptant un changement que si l'anti-rebond est écoulé. Le second détecte la frontière d'appui, c'est-à-dire le passage du repos à l'enfoncement, et fait alors basculer la LED. Le troisième gère le clignotement sur son propre horloge. Aucun de ces blocs n'attend quoi que ce soit : ils testent, ils décident, ils passent la main.

```cpp
void loop() {
  bool lu = digitalRead(BOUTON);
  unsigned long maintenant = millis();

  if (lu != etatStable && maintenant - dernierChangement > ANTI_REBOND) {
    dernierChangement = maintenant;
    etatStable = lu;
  }

  if (etatStable == LOW && etatPrecedent == HIGH) {
    etatLED = !etatLED;
    compteur = compteur + 1;
    Serial.print("Pression ");
    Serial.println(compteur);
  }
  etatPrecedent = etatStable;

  if (maintenant - dernierClignotement >= INTERVALLE) {
    dernierClignotement = maintenant;
    etatLED = !etatLED;
    digitalWrite(LED, etatLED ? HIGH : LOW);
  }
}
```

Relisez attentivement l'interaction entre les deux temporisations : le bouton bascule l'état de la LED, et le clignotement le rebascule à son propre rythme. Au premier abord, cela peut sembler contradictoire, et c'est volontaire : le programme maintient deux sources d'événements concurrentes sans jamais les sérialiser, exactement comme le ferait un automate. Si vous souhaitez que le bouton prenne la priorité, il suffit de remplacer la bascule du clignotement par un test sur une variable d'autorisation, mais gardez d'abord à l'esprit que c'est la simultanéité qui doit être démontrée ici.

Un raffinement utile consiste à séparer le clignotement d'attente du clignotement d'erreur, ou à ajouter un état de veille : après trente secondes sans pression, la LED s'éteint et ne se rallume qu'au prochain appui. La logique est exactement la même, il n'y faut qu'une variable supplémentaire enregistrant le dernier appui et un test de dépassement dans la boucle. C'est ce genre d'extension, modeste en code mais décisive en confort d'usage, qui distingue un brouillon d'un objet réellement utilisable. Écrivez d'abord la version de base, validez-la sur la table, puis ajoutez une fonctionnalité à la fois.
$lesson$),
  ('ard-c1-p11', 'ard-c1', 11, $lesson$Sur ESP32 : 3,3 volts, broches dédiées et pull-ups$lesson$, $lesson$
La même leçon s'applique sur un ESP32, avec trois différences qu'il faut connaître avant le premier câblage, parce qu'elles ne se pardonnent pas. La première est la tension : l'ESP32 fonctionne en 3,3 volts, ses broches ne supportent pas les 5 volts d'une alimentation Arduino, et une entrée soumise à cette tension se détériore progressivement. La seconde est le courant : les broches peuvent délivrer quelques dizaines de milliampères au total, mais il ne faut pas cumuler dix LED en pleine puissance sur le même côté de la puce. La troisième tient aux broches particulières, liées au démarrage ou à la mémoire flash, qu'il convient d'éviter tant qu'on débute.

Le câblage d'une LED ne change quasiment pas, si ce n'est la valeur de la résistance. Avec 3,3 volts disponibles et une LED rouge tombant à 2 volts, la chute à dissiper n'est plus de 3 volts mais de 1,3 volt : pour un courant de 15 milliampères, la loi d'Ohm donne environ 87 ohms, soit une résistance de 100 ohms normalisée. Une LED bleue, elle, consomme presque toute la tension disponible et se comporte donc mieux sur ce voltage. Les valeurs du tableau du chapitre restent votre référence pour choisir sans calculer à chaque fois.

| Point d'attention | Arduino Uno | ESP32 |
| --- | --- | --- |
| Tension des broches | 5 volts | 3,3 volts, ne pas exposer à 5 V |
| Résistance pour une LED rouge | 220 ohms | 100 ohms |
| Broche LED intégrée | broche 13 | souvent broche 2, variable selon la carte |
| Résistance interne de tirage | 20 à 50 kohms | environ 45 kohms |
| Broches à éviter au démarrage | aucune en particulier | 0, 2, 12, 15 selon la carte |

Le pull-up interne, lui, fonctionne à l'identique : `INPUT_PULLUP` reste la bonne réponse, la résistance interne d'environ 45 kohms suffit amplement, et le câblage du bouton entre broche et masse reste inchangé. La logique inversée est donc toujours la même, et aucun ajustement de code n'est nécessaire au passage d'une carte à l'autre. C'est précisément l'intérêt de cette convention : elle rend le sketch portable, à condition de ne pas mélanger les numéros de broches, que l'on range dans des constantes en tête de fichier.

Enfin, si vous branchez un ESP32 sur un module 5 volts, comme un capteur ancien ou un afficheur alimenté en 5 volts, la sortie de celui-ci risque d'envoyer plus que la puce n'accepte. Dans ce cas, on utilise un pont diviseur de tension, deux résistances en série qui ramènent le signal dans la plage acceptable, ou bien l'on choisit directement un module compatible 3,3 volts. Cette précaution est la seule différence réellement structurelle entre les deux cartes du parcours : tout ce qui concerne la logique, le temps et l'organisation du programme se transpose sans modification.
$lesson$),
  ('ard-c1-p12', 'ard-c1', 12, $lesson$Déboguer avec le moniteur série$lesson$, $lesson$
Aucun programme embarqué ne se débogue à l'œil nu. Une LED éteinte peut signifier un câblage inversé, une broche configurée en entrée, un programme qui ne tourne pas, ou une condition fausse : sans message, tout est possible. Le port série est dès lors votre premier instrument de mesure. Il s'ouvre avec `Serial.begin()` dans `setup()`, à une vitesse appelée baudrate, puis reçoit du texte avec `print()` ou `println()` depuis n'importe où dans le programme. Ce texte arrive sur l'ordinateur, dans une fenêtre de l'éditeur, et raconte ce que fait réellement la carte.

```cpp
Serial.begin(9600);

void loop() {
  unsigned long maintenant = millis();
  Serial.print("boucle=");
  Serial.print(maintenant);
  Serial.print(" etat=");
  Serial.println(etatStable ? HIGH : LOW);
}
```

La vitesse doit être identique de part et d'autre, dans le code et dans la fenêtre du moniteur. Si elle diffère, le texte arrive mais paraît illisible, une suite de caractères apparemment aléatoires : c'est le signe classique d'un baudrate mal réglé, et non d'un problème de câble ou de mémoire. Choisissez 9600 ou 115200, notez votre choix en tête du sketch, et alignez toujours le moniteur sur cette valeur avant de conclure quoi que ce soit sur un comportement anormal.

Ce qu'il faut afficher, ce n'est pas tout, mais ce qui décide. Chaque changement d'état du bouton, chaque front accepté après anti-rebond, chaque déclenchement de temporisation, avec la valeur de `millis()` en préfixe. Ces trois informations suffisent presque toujours à localiser un défaut : si le front n'apparaît jamais, le problème est électrique ou de filtrage ; s'il apparaît plusieurs fois pour un appui, l'anti-rebond est trop court ; s'il apparaît une fois mais que la LED ne bouge pas, la faute est dans la logique ou dans le câblage de la sortie. Le moniteur série ne se contente pas d'afficher, il tranche entre les hypothèses.

Une erreur de raisonnement fréquente consiste à afficher en continu, à chaque passage de la boucle, sans aucun test. Le moniteur déborde alors, la boucle ralentit à cause du temps consacré à l'envoi, et le programme se retrouve ralenti par l'outil censé le diagnostiquer. Limitez vos affichages aux événements, gardez des messages courts, et préférez un log contextualisé à dix affichages isolés. Une trame du type pression numéro, suivie de l'instant en millisecondes, contient déjà toute l'information nécessaire pour comprendre ce qui s'est passé.
$lesson$),
  ('ard-c1-p13', 'ard-c1', 13, $lesson$Vérifier son montage avant même de téléverser$lesson$, $lesson$
La moitié du temps perdu en électronique s'explique par une question simple : on allume avant d'avoir regardé. Une vérification visuelle de trente secondes, menée méthodiquement, élimine la majorité des pannes avant qu'elles n'existent. Commencez par comparer votre montage au schéma, fil par fil, en suivant le chemin du courant à voix haute : de quelle broche part le fil, quelle rangée de la breadboard accueille la patte de la résistance, dans quel sens pointe la LED, quel rail reçoit la masse. Cette habitude paraît superstitieuse au premier abord, puis devient réflexe, et c'est à ce moment précis que vos circuits cessent de poser de problèmes inexpliqués.

Le premier contrôle porte sur les continuités, c'est-à-dire sur les points qui doivent être électriquement identiques. Un multimètre réglé en mode continuité émet un bip quand ses deux sondes sont reliées par un conducteur, et reste silencieux sinon. Vérifiez ainsi que la patte courte de la LED arrive bien jusqu'au rail de masse, que la broche de commande rejoint bien une patte de la résistance, et surtout qu'aucun fil ne court-circuite le rail positif avec la masse. Ce dernier contrôle se fait hors alimentation, toujours : un multimètre en mode continuité injecte lui-même un très faible courant de mesure, et il n'a aucun besoin que la carte soit sous tension pour faire son travail.

Une fois le circuit alimenté, on passe aux tensions, et l'on mesure alors de gauche à droite sur le trajet du courant. Sur un Arduino Uno, la tension entre le rail positif et la masse doit afficher environ 5 volts ; sur un ESP32, environ 3,3 volts. La différence entre les deux bornes de la résistance donne la chute réelle que cette dernière impose, et elle se compare avec le calcul de la loi d'Ohm : un écart important signale une mauvaise valeur, un mauvais contact ou une LED défectueuse. Enfin, la tension aux bornes de la LED doit rester proche de sa tension directe, 2 volts environ pour une LED rouge : si vous mesurez presque la tension d'alimentation, la LED n'est probablement pas conductrice dans ce sens.

Voici les points de mesure à parcourir dans l'ordre, avec l'interprétation de chaque résultat :

- entre le rail positif et la masse : l'alimentation est-elle réellement présente ;
- entre la broche configurée en sortie et la masse, LED débranchée : la broche écrit-elle bien HIGH ;
- aux deux bornes de la résistance : la chute de tension correspond-elle au calcul attendu ;
- aux deux bornes de la LED : la tension reste-t-elle dans la plage de fonctionnement ;
- entre la broche du bouton et la masse, appui maintenu : la tension tombe-t-elle bien à zéro ;
- entre le bouton et la masse, sans appui : la tension reste-t-elle à l'alimentation, signe d'un pull-up actif.

Ces mesures se lisent comme un diagnostic : la première réponse franche situe le défaut, et les suivantes ne sont plus nécessaires. Pour aller encore plus vite, un petit bloc de texte récapitule la correspondance entre symptôme et cause la plus probable, à consulter avant d'ouvrir l'éditeur :

```text
alimentation absente        -> cable USB, alimentation, rail non relie
broche toujours a 0 V       -> pinMode manquant, broche configuree en entree
resistance sans chute       -> court-circuit, contact court, fil de traverse
LED inversee                -> patte longue du cote masse au lieu de la broche
tension correcte, LED eteinte -> LED bouffee, ou fil non enfonce a fond
bouton toujours a 0 V       -> broche reliee a la masse au lieu de l'alimentation
bouton toujours a 5 V       -> bouton hors circuit, rangee de trop ou de trop peu
```

Une remarque de sécurité pour terminer cette méthode : ne mesurez jamais une tension alors que vous êtes en train de rebrancher un fil, et ne laissez pas les sondes du multimètre reposer sur le circuit sous tension une fois la mesure terminée. Une sonde qui glisse peut relier deux rangées voisines et provoquer un court-circuit là où votre doigt n'aurait jamais osé intervenir. Coupez l'alimentation pour chaque modification, même la plus petite, puis rallumez pour constater : c'est plus lent de trois secondes, et c'est incomparablement plus sûr pour la carte.
$lesson$),
  ('ard-c1-p14', 'ard-c1', 14, $lesson$Un rythme de travail qui va vite$lesson$, $lesson$
La vitesse, dans ce genre de projet, ne vient pas de la frappe au clavier mais de la taille des étapes. Un développeur embarqué expérimenté ne modifie jamais trois choses à la fois : il change un paramètre, téléverse, observe, puis décide. Si l'échec survient, il ne cherche pas dans les douze lignes qu'il vient d'écrire, mais dans l'unique variable qu'il vient de toucher. Ce discipline est la seule différence visible entre un débutant qui passe deux heures à chercher une faute de syntaxe et un collègue qui, en deux essais, a déjà isolé le problème.

Le téléversement lui-même fait partie du diagnostic. Une erreur de compilation indique une ligne précise : lisez-la telle quelle, sans paraphraser, parce que le message contient souvent le nom exact de l'identifiant fautif, un point-virgule oublié ou une parenthèse non fermée. Une erreur de port introuvable ne dit rien du code, elle parle du câble, du pilote ou du menu de sélection : elle ne doit donc jamais vous conduire à modifier votre programme. Distinguez d'emblée les messages qui accusent le code de ceux qui accusent la machine, et vous gagnerez les minutes que tout le monde perd à corriger ce qui n'était pas cassé.

L'organisation du fichier compte autant que la logique. Regroupez les constantes en tête de fichier, donnez-leur un nom qui décrit le rôle et non la valeur, et évitez les chiffres magiques disséminés dans la boucle. Une durée écrite sous forme de constante se modifie à un seul endroit, se relit comme une phrase, et se compare avec les autres durées du programme d'un coup d'œil. De même, gardez une seule convention pour les noms de variables, par exemple un adjectif d'état pour les booléens et un nom complet pour les compteurs : la lecture de votre propre code dans deux semaines en dépend entièrement.

Le travail se fait par cycles courts, et chaque cycle se referme sur une question unique : qu'est-ce que je viens de prouver. Tant que la réponse n'est pas claire, le cycle n'est pas terminé, et ajouter une fonctionnalité par-dessus une base non validée revient à construire sur du sable. Voici la séquence qui, reprise systématiquement, évite la majorité des impasses :

```text
1. formuler une seule chose a verifier
2. modifier uniquement ce qui sert a cette verification
3. televerser et observer le comportement reel
4. noter ce qui s'est passe, meme quand cela marche
5. constater, puis choisir : on garde, on corrige, on recule
6. ne jamais empiler deux fonctionnalites invalidees
```

Quand la recherche bloque, changez d'échelle au lieu de changer de solution. Commentez la moitié du programme jusqu'à ce qu'il ne reste que l'allumage de la LED : si cela fonctionne, réintroduisez les blocs un par un jusqu'à ce que le défaut réapparaisse, et vous saurez exactement quel bloc l'apporte. Si même l'allumage ne fonctionne plus, le problème n'est pas dans le code mais dans l'alimentation, le câblage ou la carte, et vous venez d'économiser une heure de lecture de code inutile. Cette descente par biseaux est la technique de dépannage la plus rentable qui soit, et elle s'applique à tous les chapitres qui suivent.

Ce chapitre vous a donné les gestes fondamentaux : configurer une broche, protéger un composant, mesurer le temps sans bloquer, lire une entrée ancrée et filtrer ses rebonds. Le prochain chapitre ajoute la lecture analogique, la modulation de largeur d'impulsion et les capteurs usuels, mais rien de tout cela n'a de sens si les bases de celui-ci ne sont pas solides. Prenez le temps de réécrire seul, sans copier, le programme de clignotement et de comptage : c'est l'exercice pratique du chapitre, et c'est aussi le premier test honnête de ce que vous avez réellement acquis.
$lesson$),
  ('ard-c1-p15', 'ard-c1', 15, $lesson$Mise en œuvre : une lampe de chevet à trois modes$lesson$, $lesson$
Pour conclure la partie pratique, assemblons le tout dans un objet identifiable, une petite lampe de chevet pilotée par un seul bouton. Trois modes suffisent à illustrer toutes les compétences du chapitre : le mode éteint, le mode allumé en continu, et le mode veilleuse où la LED clignote lentement. Une pression bref fait passer d'un mode au suivant, en tournant dans la liste. Une pression maintenue deux ramène la lampe à l'état éteint quel que soit le mode, ce qui simule l'interrupteur prioritaire d'un vrai objet. Pendant ce temps, le port série journalise chaque changement avec l'instant en millisecondes, ce qui permet de vérifier le comportement sans rien interrompre.

Cette description se traduit naturellement par une machine à états, même si le chapitre consacré aux automates ne viendra que plus tard. On déclare une variable qui mémorise le mode courant, on identifie les événements qui provoquent une transition, et on écrit une fonction unique chargée d'appliquer un nouvel état. L'avantage de ce découpage est qu'aucune logique de décision n'est mélangée à la logique d'exécution : lire le bouton reste d'un côté, décider du prochain mode de l'autre, agir sur la troisième. Le programme devient lisible à la lecture, et les ajouts futurs se font sans réécriture.

```cpp
enum Mode { ETEINT, ALLUME, VEILLEUSE };
Mode modeCourant = ETEINT;

void appliquerMode(Mode nouveau) {
  modeCourant = nouveau;
  Serial.print("Mode change, instant ");
  Serial.println(millis());
  if (modeCourant == ETEINT) digitalWrite(LED, LOW);
  if (modeCourant == ALLUME) digitalWrite(LED, HIGH);
}
```

La détection d'appui maintenu demande une information supplémentaire : la durée de l'appui en cours. On enregistre l'instant du front d'enfoncement, puis, à chaque boucle, on calcule l'écart avec l'instant courant. Si l'écart dépasse les deux secondes et que le bouton est toujours enfoncé, on déclenche une seule fois l'action prioritaire et on marque l'événement comme consommé, afin que la même pression ne redéclenche rien à la seconde suivante. Le seuil de la pression courte se place nettement en dessous, autour de quatre cents millisecondes, ce qui laisse une marge confortable entre les deux interprétations d'un même geste.

Le protocole de vérification, lui, se rédige avant le code et non après. Appuyez une fois, vérifiez que le mode change exactement une fois et qu'un message apparaît. Maintenez l'appui deux secondes, vérifiez que la lampe s'éteint une seule fois, puis relâchez : rien ne doit se déclencher à la remontée. Laissez la veilleuse tourner une minute entière et comptez les clignotements à l'œil pour vous assurer que la cadence ne dérive pas. Enfin, appuyez très brièvement dix fois de suite : le compteur de modes doit rester cohérent et aucun rebond ne doit s'être glissé entre les transitions. Ce protocole prend deux minutes et remplace une heure de doute.

Une fois ce comportement acquis, le lien avec la suite du parcours devient évident. Le mode veilleuse n'attend qu'une modulation de largeur d'impulsion pour se transformer en vraie luminosité réglable, ce que le chapitre suivant apporte avec l'entrée analogique et la PWM. La machine à états, elle, se généralisera aux automates du quatrième chapitre, où l'on modélisera un feu pour piétons avec exactement cette même mécanique. Et la journalisation série, enfin, deviendra le socle du chapitre connecté, où les mêmes messages remonteront sur un tableau de bord plutôt que dans une console. Rien de ce que vous venez d'écrire n'est donc jetable : chaque brique est un point d'ancrage pour la suite.
$lesson$),
  ('ard-c1-p16', 'ard-c1', 16, $lesson$À retenir$lesson$, $lesson$
Le chapitre tient en un petit nombre de principes qui, une fois installés, ne vous quitteront plus. Reprenez-les un par un, et vérifiez que vous pouvez les reformuler sans regarder le texte, c'est le seul test honnête de compréhension.

- Une broche se configure en sortie pour commander, en entrée pour observer, et `pinMode()` se place dans `setup()`.
- Le courant doit toujours former une boucle complète entre la broche et la masse, sinon le circuit ne fonctionne pas.
- Une LED se protège toujours par une résistance en série, calculée avec la loi d'Ohm, et placée dans le bon sens.
- Une entrée sans résistance de tirage flotte : on utilise `INPUT_PULLUP` et on relie le bouton à la masse.
- Avec un pull-up, le repos vaut HIGH et l'appui vaut LOW, ce qui inverse les conditions du programme.
- `delay()` fige la boucle : `millis()` permet de mesurer le temps sans jamais arrêter l'exécution.
- Le rebond mécanique multiplie les fronts : un anti-rebond de vingt millisecondes environ les filtre.
- Détecter un niveau sert à piloter, détecter une frontière sert à compter une pression.
- Une modification à la fois, un téléversement, une observation : c'est ainsi que les pannes se résolvent vite.
$lesson$),
  ('ard-c1-p17', 'ard-c1', 17, $lesson$Erreurs fréquentes$lesson$, $lesson$
La quasi-totalité des pannes rencontrées sur ce premier circuit relèvent de la liste suivante. Consultez-la avant de modifier votre code, parce que l'expérience montre que le problème est le plus souvent sous les doigts plutôt que dans l'éditeur.

- La LED ne s'allume jamais : vérifiez le sens de la LED, la présence du fil de masse et la valeur de la résistance.
- La LED reste allumée en permanence : la broche est peut-être configurée en sortie avec un niveau HIGH forcé, ou le câblage contourne la LED.
- Une carte 5 volts est reliée à une entrée ESP32 : retirez ce branchement, il endommage la puce.
- Le bouton déclenche plusieurs fois : augmentez la durée d'anti-rebond ou utilisez Bounce2.
- Le bouton déclenche à l'envers : votre logique est inversée, le repos vaut HIGH avec un pull-up.
- La carte n'est pas trouvée au téléversement : changez de câble USB, celui-ci doit transporter des données, puis resélectionnez le port.
- Le moniteur série affiche des caractères illisibles : la vitesse configurée dans le code et dans le moniteur diffèrent.
- Le programme compile mais ne réagit plus : cherchez un `delay()` resté dans la boucle.
- La LED grillait régulièrement : la résistance est trop faible ou absente du circuit.
- Rien ne fonctionne après un branlage : refaites le contrôle de continuité, un fil mal enfoncé produit un contact intermittent.
$lesson$),
  ('ard-c1-p18', 'ard-c1', 18, $lesson$Pour aller plus loin$lesson$, $lesson$
Une fois le circuit validé, la meilleure façon de fixer les acquis est de le modifier, toujours par petites touches et toujours en vérifiant l'effet d'un seul changement à la fois. Changez la durée du clignotement, ajoutez une seconde LED témoin, comptez les appuis maintenus séparément des appuis brefs, ou affichez la durée de chaque pression avec `millis()`. Chaque variante vous oblige à repasser par le raisonnement du chapitre, ce qui le transforme de connaissances lues en gestes acquis. Une fois ces variantes maîtrisées, les chapitres suivants sur les capteurs et les afficheurs n'utiliseront que des mécanismes que vous maîtriserez déjà.

Pour approfondir, quatre ressources officielles font autorité et couvrent tout ce qui a été vu. La référence Arduino détaille chaque fonction employée ici, avec ses paramètres et ses cas particuliers. La documentation Espressif décrit les broches de l'ESP32, leurs niveaux et leurs restrictions de démarrage. Le dépôt de la bibliothèque Bounce2 explique les options d'anti-rebond avancées. Enfin, un simulateur en ligne permet de tester un circuit sans le moindre matériel, ce qui est particulièrement pratique pour expérimenter un montage différent avant de le réaliser sur la table.

- https://www.arduino.cc/reference/en/ — la référence officielle des fonctions Arduino
- https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html — la documentation GPIO de l'ESP32
- https://github.com/thomasfredericks/Bounce2 — la bibliothèque d'anti-rebond utilisée dans ce chapitre
- https://www.tinkercad.com/ — un simulateur en ligne pour tester un circuit sans matériel
$lesson$),
  ('ard-c1-p19', 'ard-c1', 19, $lesson$Et maintenant : câblez votre LED et lancez le clignotant$lesson$, $lesson$
Vous avez posé les fondations : une LED câblée avec sa résistance, un premier sketch qui compile et se téléverse, puis un clignotement fondé sur millis() au lieu d'une attente bloquante. Passez maintenant à l'exercice pratique : reprenez le programme final, changez la fréquence, ajoutez une seconde LED sur une autre broche et vérifiez que les deux rythmes restent indépendants. Si quelque chose ne clignote pas, revenez à la section erreurs fréquentes : presque toutes les pannes de ce premier chapitre se résolvent en vérifiant le sens de la LED, la broche utilisée et la commune du breadboard.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('ard-c2-p1', 'ard-c2', 1, $lesson$De quoi est fait le monde : capteurs et actionneurs$lesson$, $lesson$
Bienvenue dans le deuxième chapitre du parcours Arduino et ESP32, entièrement consacré aux capteurs et aux actionneurs. Le chapitre précédent vous a permis de faire clignoter une LED et de lire un bouton : tout y était numérique, c'est-à-dire réduit à deux états, haut ou bas, 1 ou 0. Or le monde réel n'est pas fabriqué ainsi. La température d'une pièce varie de façon continue, la lumière d'un bureau s'ajuste par des degrés imperceptibles, la distance jusqu'à un obstacle se mesure en millimètres, la vitesse d'un moteur se règle entre l'arrêt total et la pleine puissance. Pour faire entrer cette continuité dans un microcontrôleur, il faut deux familles d'éléments : les capteurs, qui transforment une grandeur physique en signal électrique, et les actionneurs, qui transforment un ordre numérique en effet physique observable. C'est exactement le sujet de ce chapitre, et vous allez voir qu'il repose sur deux seuls mécanismes : convertir une tension en nombre, et produire une tension moyenne à partir d'un signal carré.

À la fin de cette leçon, vous saurez faire des choses très concrètes, et vous les aurez déjà manipulées dans du vrai code. Vous lirez un capteur analogique avec la fonction analogRead et vous comprendrez ce que renvoie réellement cette fonction : un entier compris entre 0 et 1023 sur un Arduino Uno, entre 0 et 4095 sur un ESP32. Vous convertirez cette lecture brute en tension, puis en grandeur physique, température, luminosité ou distance, en appliquant la formule propre à chaque capteur. Vous régulerez la puissance envoyée à une LED, à un moteur ou à un servomoteur avec la modulation de largeur d'impulsion, ce qu'on appelle le PWM, et vous saurez choisir la fréquence et le duty cycle adaptés à chaque actionneur. Enfin, vous afficherez des mesures formatées sur le moniteur série, avec un horodatage et des unités, de façon à pouvoir les relire, les copier dans un tableur ou les exploiter plus tard.

La méthode de ce chapitre est volontairement la même que celle du précédent : on avance par étapes courtes, chaque notion étant d'abord expliquée, puis illustrée par un code complet, puis reprise dans un exemple filé. Un seul conseil avant de commencer : testez toujours un capteur isolément, avant de l'intégrer à un programme plus ambitieux. Une borne inversée, une formule fausse ou une tension de référence inadaptée se repèrent en trois lignes quand le programme ne fait qu'afficher la valeur brute, et deviennent un casse-tête incompréhensible quand dix fonctionnalités sont entremêlées. Le fil rouge de la leçon sera une petite station climatique : un capteur de température, un ventilateur piloté en PWM, deux LED d'état et un affichage série structuré. Vous le construirez pas à pas dans les sections qui suivent, puis vous le récrirez seul dans l'exercice pratique.



Un capteur est un composant qui convertit une grandeur physique en une grandeur électrique, généralement une tension ou un courant qu'un microcontrôleur sait mesurer. Une photorésistance devient plus ou moins conductrice selon la lumière qu'elle reçoit ; un thermistor change de résistance avec la température ; un capteur ultrason émet une impulsion et renvoie une durée proportionnelle à la distance ; un accéléromètre produit une tension proportionnelle à l'accélération qu'il subit. Dans tous les cas, le capteur ne produit pas d'information prête à l'emploi : il produit un signal brut, qu'il faudra convertir, étalonner et interpréter. C'est pourquoi le premier réflexe à acquérir est d'afficher la valeur brute avant toute conversion : si la valeur brute ne bouge pas quand vous couvrez le capteur de votre main, aucun calcul ne réussira à lui infuser une variation.

Un actionneur fait l'inverse : il reçoit un ordre numérique et produit un effet physique. Une LED convertit un courant en lumière, un moteur convertit un courant en mouvement, un servomoteur convertit une impulsion en position angulaire, un relais convertit un signal en contact mécanique, un buzzer convertit une fréquence en son. La distinction fondamentale à garder en tête concerne les courants : les broches d'un microcontrôleur sont capables de délivrer quelques dizaines de milliampères seulement, ce qui suffit pour faire briller une petite LED, mais pas pour entraîner un moteur. Toute la partie actionneurs de ce chapitre tourne autour de cette contrainte, et vous verrez comment un transistor ou un MOSFET joue le rôle d'intermédiaire, petit signal pilotant grand courant.

La frontière entre analogique et numérique mérite d'être posée avec précision, car elle revient sans cesse. Un signal numérique ne connaît que deux états, et il encode une information par des séquences d'états : c'est ainsi que fonctionne le protocole série, où des 1 et des 0 se succèdent pour former un caractère. Un signal analogique, lui, peut prendre n'importe quelle valeur dans une plage continue : entre 0 V et 3,3 V sur un ESP32, il existe une infinité de tensions possibles, et c'est précisément ce qui permet de représenter une température de 23,4 degrés. Le microcontrôleur, lui, reste numérique : il ne sait raisonner qu'avec des entiers. Le convertisseur analogique-numérique est donc le pont obligatoire entre le monde continu et le monde du calcul, et comprendre ce pont, c'est comprendre l'essentiel de ce chapitre.

- Un capteur transforme une grandeur physique en signal électrique mesurable.
- Un actionneur transforme un ordre numérique en effet physique.
- Une sortie analogique est continue ; une sortie numérique n'a que deux états.
- Les broches d'un microcontrôleur délivrent peu de courant : prévoir un étage de puissance.
- Toujours afficher la valeur brute avant d'écrire la moindre formule.
- La distance de câblage décide entre capteur analogique court ou capteur numérique.
$lesson$),
  ('ard-c2-p2', 'ard-c2', 2, $lesson$Lire une tension : le convertisseur analogique-numérique$lesson$, $lesson$
Le convertisseur analogique-numérique, souvent appelé ADC pour son nom anglais, prend une tension continue en entrée et produit un nombre entier proportionnel. Son fonctionnement se résume en deux opérations. La première est l'échantillonnage : à intervalle régulier, le convertisseur mesure la tension présente à sa broche d'entrée. La seconde est la quantification : cette tension mesurée est arrondie à l'étage le plus proche d'une grille régulière dont le nombre de pas est fixé par la résolution. Quand vous appelez analogRead, tout ce travail est exécuté en quelques microsecondes et la fonction renvoie l'indice du pas correspondant. Ce qu'il faut retenir, c'est que la valeur renvoyée n'est pas une tension : c'est un compteur, un indice dans une échelle, et c'est à vous de la replacer sur cette échelle.

La résolution détermine la finesse de cette grille. Sur un Arduino Uno, l'ADC est codé sur 10 bits, ce qui donne 2 puissance 10, soit 1024 valeurs distinctes numérotées de 0 à 1023. Sur un ESP32, il est codé sur 12 bits, soit 4096 valeurs numérotées de 0 à 4095. À résolution égale, la référence d'alimentation définit la tension correspondant au sommet de l'échelle : 5 V sur un Uno alimenté en USB ou en 5 V, environ 3,3 V sur un ESP32. Le tableau ci-dessous réunit ces trois paramètres pour les deux cartes les plus courantes du parcours ; gardez-le sous la main, car toutes les formules de conversion de ce chapitre s'appuient sur lui.

| Carte | Résolution | Plaque de valeurs | Référence | Pas correspondant |
| --- | --- | --- | --- | --- |
| Arduino Uno | 10 bits | 0 à 1023 | 5,0 V | environ 4,89 mV |
| Arduino Nano | 10 bits | 0 à 1023 | 5,0 V | environ 4,89 mV |
| ESP32 | 12 bits | 0 à 4095 | environ 3,3 V | environ 0,81 mV |
| ESP32 en attenuation 11 dB | 12 bits | 0 à 4095 | jusqu'à 3,1 V utiles | environ 0,76 mV |

Le calcul de la tension à partir de la valeur brute suit toujours le même schéma : on multiplie la valeur brute par la référence, puis on divise par le maximum de la plage. Sur un Uno, la valeur 512 correspond donc à 512 multiplié par 5,0, divisé par 1023, soit environ 2,50 V. Sur un ESP32, la même valeur 512 donne 512 multiplié par 3,3, divisé par 4095, soit environ 0,41 V : à nombre brut identique, la tension réelle est totalement différente, et c'est la cause numéro un des programmes qui affichent des températures ridicules lorsqu'on les transfère d'une carte à l'autre. Notez aussi que la division doit se faire en nombres décimaux : écrire 512 fois 5 divisé par 1023 avec des entiers tronquerait le résultat, comme nous le verrons dans la section suivante.

```cpp
const int CAPTEUR_PIN = A0;      // broche analogique
const float VREF = 5.0;          // tension de référence en volts
const int ADC_MAX = 1023;        // 4095 sur un ESP32

void setup() {
  Serial.begin(115200);
  analogReference(DEFAULT);      // référence par défaut de la carte
}

void loop() {
  int brut = analogRead(CAPTEUR_PIN);
  float tension = brut * VREF / ADC_MAX;
  Serial.print("brut = ");
  Serial.print(brut);
  Serial.print("   tension = ");
  Serial.print(tension, 3);
  Serial.println(" V");
  delay(500);
}
```

- analogRead renvoie un entier, pas une tension : c'est un index dans une échelle.
- Uno : 0 à 1023 pour 0 à 5 V. ESP32 : 0 à 4095 pour 0 à 3,3 V environ.
- Tension égale à valeur brute multipliée par la référence, divisée par le maximum.
- Une broche libre en l'air bruite : cela ne signifie pas que la carte est hs.
- La résolution conditionne le pas : environ 4,89 mV sur Uno, 0,81 mV sur ESP32.
- Préférez toujours une conversion en flottants pour éviter toute troncature.
$lesson$),
  ('ard-c2-p3', 'ard-c2', 3, $lesson$De la lecture brute au nombre utile$lesson$, $lesson$
Convertir une tension en grandeur physique revient à appliquer la loi du capteur, c'est-à-dire la relation, souvent linéaire, qui relie sa sortie à la grandeur qu'il mesure. Le capteur de température LM35 est l'exemple le plus pédagogique car sa loi tient en une phrase : sa sortie vaut 0 mV à 0 degré, et augmente de 10 mV par degré supplémentaire. La tension mesurée est donc directement proportionnelle à la température, et l'inverse de la pente suffit pour l'obtenir : on divise la tension par 0,01. Sur un Uno, la chaîne complète s'écrit alors valeur brute multipliée par 5,0, divisée par 1023, le tout divisé par 0,01, ce qui se simplifie en valeur brute multipliée par environ 0,489. Un capteur à sortie 1 degré correspond donc à environ deux pas d'ADC, ce qui explique pourquoi la lecture brute oscille légèrement autour d'une valeur stable.

La photorésistance illustre un deuxième cas de figure, celui des capteurs dont la loi n'est pas fournie sous forme de tension mais de résistance. Sa résistance chute quand la lumière augmente, de quelques mégohms dans le noir à quelques centaines d'ohms en plein soleil, mais une résistance ne se mesure pas directement avec une broche analogique : il faut la convertir en tension. On le fait avec un pont diviseur, formé par la photorésistance et une résistance fixe de valeur connue, généralement 10 kΩ, branchées en série entre l'alimentation et la masse, la jonction étant reliée à la broche analogique. Plus la photorésistance devient conductrice, plus elle abaisse la tension au point de mesure : la lecture brute monte quand la lumière augmente. Le calcul inverse de la résistance se fait ensuite avec la formule du diviseur, et une table de correspondance approximative donne ensuite les lux.

Les capteurs de température à base de thermistance ajoutent une troisième variante, celle de la loi non linéaire. Un composant NTC est une résistance dont la valeur décroît quand la température augmente, mais selon une courbe exponentielle : doubler la résistance ne correspond pas à doubler l'écart de température. On l'utilise, lui aussi, dans un pont diviseur avec une résistance fixe, puis on convertit la tension lue en résistance, enfin cette résistance en température. Pour cette dernière étape, on emploie soit une approximation polynomiale simple, soit la formule de Steinhart-Hart, qui donne une précision remarquable avec seulement trois coefficients. Dans un projet débutant, une table de correspondance mesurée à deux ou trois points suffit souvent et a l'avantage d'intégrer automatiquement les tolérances de votre composant réel.

Tous ces calculs supposent une opération que l'on oublie trop vite : l'étalonnage. Deux LM35 sortis de la même boîte peuvent différer de quelques dixièmes de degré, deux résistances marquées 10 kΩ peuvent en valoir 9,8 ou 10,2, et la tension d'alimentation d'un panneau solaire ou d'un banc d'essai varie elle aussi. La méthode des deux points règle efficacement ces défauts : vous mesurez une référence fidèle, un multimètre étalonné ou un point de fusion glacial, vous notez la lecture brute correspondante, puis vous répétez l'opération à un deuxième point. Deux équations à deux inconnues donnent alors un gain et un décalage qui corrigent la chaîne complète, capteur et ADC compris. Même grossier, un tel étalonnage améliore nettement la crédibilité d'une mesure affichée.

```cpp
const int LDR_PIN = A1;
const int NTC_PIN = A2;
const float VREF = 5.0;
const int ADC_MAX = 1023;
const float R_FIXE = 10000.0;   // pont diviseur 10 kΩ

float lireTension(int broche) {
  int brut = analogRead(broche);
  return brut * VREF / ADC_MAX;
}

float lireResistance(int broche) {
  float v = lireTension(broche);
  if (v < 0.01) v = 0.01;                 // évite la division par zéro
  return R_FIXE * (VREF - v) / v;          // pont diviseur
}

void setup() { Serial.begin(115200); }

void loop() {
  float tempLM35 = lireTension(A0) / 0.01;
  Serial.print("LM35 = ");
  Serial.print(tempLM35, 1);
  Serial.print(" C   LDR = ");
  Serial.print(lireResistance(LDR_PIN), 0);
  Serial.print(" ohms   NTC = ");
  Serial.print(lireResistance(NTC_PIN), 0);
  Serial.println(" ohms");
  delay(1000);
}
```

| Grandeur | Capteur | Sortie | Conversion essentielle |
| --- | --- | --- | --- |
| Température | LM35 | tension 10 mV par degré | tension divisée par 0,01 |
| Température | NTC 10 kΩ | résistance variable | pont diviseur puis Steinhart-Hart |
| Lumière | photorésistance | résistance décroissante | pont diviseur puis approximation en lux |
| Distance | HC-SR04 | durée d'écho | durée multipliée par la vitesse du son, divisée par deux |
| Position | potentiomètre | tension de répartition | lecture brute normalisée entre 0 et 1023 |

Avant de passer au PWM, résumons la chaîne de traitement que vous appliquerez à tout capteur analogique. La valeur brute sort de l'ADC, sans unité. On la convertit en tension avec la référence et la résolution de la carte. On applique la loi du capteur pour obtenir la grandeur physique, en degrés, en lux, en ohms ou en centimètres. On corrige éventuellement avec un étalonnage. On affiche enfin avec une précision cohérente : afficher six décimales pour un capteur qui n'en a que deux est aussi trompeur que d'afficher zéro décimale pour une température qui fluctue de dixièmes. Cette discipline de conversion est le socle du mini-projet de fin de chapitre, où chaque mesure affichée devra pouvoir être reliée à sa formule en une seule ligne de code commentée.

Une valeur analogique lue telle quelle est rarement utilisable : elle oscille, elle dépend de l'alimentation, et elle porte le bruit électrique de tout ce qui est câblé autour. La section précédente vous a appris à convertir une tension en grandeur physique ; celle-ci vous apprend à fiabiliser la mesure avant de la convertir. Nous verrons d'abord d'où vient le bruit et pourquoi une lecture isolée ment presque toujours, puis trois techniques simples pour le maîtriser : la moyenne de plusieurs échantillons, le lissage exponentiel qui convient aux mesures en continu, et l'étalonnage qui corrige les défauts systématiques. Nous terminerons par un tour d'horizon des capteurs les plus courants, avec pour chacun leur principe, leurs besoins particuliers et le code de lecture qui lui correspond.

Le bruit de mesure a plusieurs origines, et les distinguer permet de choisir le bon remède. La première est intrinsèque au convertisseur : chaque conversion est arrondie à l'étage le plus proche, si bien que la vraie valeur peut hésiter entre deux codes voisins, ce qui produit l'oscillation d'une ou deux unités que vous avez observée sur une broche libre. La deuxième vient de l'alimentation : un moteur qui démarre, une LED qui s'allume ou l'étage haute fréquence d'un ESP32 en Wi-Fi font varier la tension de référence, et donc la mesure elle-même. La troisième est capacitivement induite : un long câble non blindé se comporte comme une antenne et capte les perturbations des câbles voisins, du moteur ou du réseau électrique. Enfin, certains capteurs sont eux-mêmes bruyants : un thermistor chauffé par son propre courant de mesure dérive lentement.

Face à ces causes, la moyenne arithmétique est le premier outil, parce qu'elle est simple et efficace contre le bruit aléatoire. L'idée est de prendre plusieurs lectures successives, de les additionner, puis de diviser par leur nombre : le bruit, qui varie de façon erratique, tend à s'annuler dans la somme, tandis que la composante utile, elle, reste stable. Huit lectures suffisent généralement à réduire l'amplitude du tremblement d'un facteur trois environ, et soixante-quatre lectures le réduisent d'un facteur huit. Le coût reste dérisoire : huit appels à analogRead représentent moins d'un milliseconde sur un Arduino Uno. Attention toutefois à la nature entière du résultat : diviser une somme d'entiers par huit avec l'opérateur slash produirait un entier tronqué ; convertissez la somme en nombre décimal avant de diviser.

```cpp
const int BROCHE = A0;
const int NB_ECHANTILLONS = 8;

float moyenneAnalogique(int broche, int n) {
  long somme = 0;
  for (int i = 0; i < n; i++) {
    somme += analogRead(broche);
    delayMicroseconds(200);        // laisse l'ADC se stabiliser
  }
  return (float)somme / n;         // cast obligatoire : sinon division entière
}

void setup() { Serial.begin(115200); }

void loop() {
  float brut = moyenneAnalogique(BROCHE, NB_ECHANTILLONS);
  float tension = brut * 5.0 / 1023.0;
  Serial.print("moyenne = ");
  Serial.print(brut, 1);
  Serial.print("   tension = ");
  Serial.print(tension, 3);
  Serial.println(" V");
  delay(250);
}
```

Le lissage exponentiel, appelé filtre mémoire, répond à un besoin différent : garder une mesure réactive sans qu'elle s'affole. Plutôt que de moyennner un paquet d'échantillons à chaque cycle, on met à jour la valeur affichée en la rapprochant de la nouvelle lecture, avec un facteur d'oubli. La formule la plus courante s'écrit : nouvelle valeur égale à l'ancienne valeur, plus le coefficient qui pondère l'écart entre la lecture et l'ancienne valeur. Avec un coefficient de 0,1, la mesure suit dix pour cent de l'écart à chaque passage : elle devient très stable mais un peu lente, avec 0,3 elle suit plus vite mais laisse passer plus de bruit. Ce compromis entre réactivité et stabilité est le cœur du réglage, et il se règle en observant la sortie dans le moniteur série plutôt qu'en choisissant au hasard.

Enfin, l'étalonnage transforme une mesure brute en mesure crédible. La méthode la plus pratique pour un débutant consiste à relever deux points de référence fiables : la température d'une glaçon pilée, théoriquement 0 °C, et celle d'une eau frémissante, proche de 100 °C au niveau de la mer. On note les lectures correspondantes, puis on calcule un gain et un décalage par une simple règle de trois à deux inconnues. Le même principe s'applique à une photorésistance étalonnée avec une luxomètre approximative, ou à un potentiomètre dont on vérifie les bornes mécaniques. L'étalonnage ne rend pas un capteur bon, mais il rend un capteur médiocre prévisible, et c'est souvent suffisant pour un banc d'essai ou un prototype.

- Le bruit vient du convertisseur, de l'alimentation, du câblage et du capteur lui-même.
- Moyenner huit lectures suffit généralement à stabiliser une mesure lente.
- Convertissez la somme en flottant avant de diviser pour éviter la troncature.
- Le filtre mémoire pondère réactivité et stabilité avec un seul coefficient.
- Limitez le courant de mesure pour éviter l'auto-échauffement des thermistances.
- Deux points de référence suffisent pour étalonner gain et décalage.
$lesson$),
  ('ard-c2-p4', 'ard-c2', 4, $lesson$Les capteurs usuels et leurs caractéristiques$lesson$, $lesson$
Le capteur de température LM35 reste le plus simple pour débuter : trois bornes, une sortie en tension, aucune communication à mettre en place. Il fonctionne de 0 à 150 degrés environ, avec une précision d'un demi-degré typique, et son courant de consommation est faible. On le câble avec la borne d'alimentation sur 5 V ou 3,3 V selon les versions, la masse sur la masse commune, et la sortie directement sur une broche analogique. Sa limite est qu'il ne va pas sous zéro degré avec une alimentation unique : pour les mesures négatives, on lui préfère une version comme le TMP36 ou le DS18B20 numérique. Quel que soit le capteur, gardez la règle : câblez-le seul, affichez la valeur brute, déplacez la main devant, vérifiez que la variation existe avant d'écrire la moindre ligne de conversion.

La famille DHT regroupe deux capteurs très répandus qui fournissent à la fois température et humidité relative. Le DHT11, moins cher, couvre 0 à 50 degrés avec une résolution d'un degré, tandis que le DHT22 couvre de -40 à 80 degrés avec une résolution de dixième. Tous deux partagent un protocole propriétaire à un seul fil : la carte abaisse la broche pendant environ une milliseconde, le capteur répond par une trame de 40 bits contenant humidité, température et somme de contrôle. C'est la raison pour laquelle une bibliothèque externe est nécessaire, et pourquoi il ne faut pas les interroger plus d'une fois toutes les deux secondes. Le BME280, lui, va plus loin en ajoutant la pression atmosphérique et en parlant en I2C ou SPI : un seul bus relie alors plusieurs capteurs, ce que vous découvrirez dans le chapitre suivant.

Le HC-SR04 mérite une section à lui seul parce qu'il introduit une grandeur nouvelle : le temps. Il fonctionne comme un sonar : on envoie une impulsion d'au moins dix microsecondes sur la broche de déclenchement, le module émet alors une salve d'ultrasons, puis il prolonge une broche d'écho pendant exactement la durée de l'aller-retour du signal. Il suffit de mesurer cette durée avec la fonction pulseIn et de la multiplier par la vitesse du son, 343 mètres par seconde, puis de diviser par deux pour obtenir la distance. Le silence renvoyé vaut environ 343 microsecondes par centimètre d'aller-retour, ce qui donne la règle pratique : durée divisée par 58, ou multipliée par 0,0343 puis divisée par deux. Prévoyez toujours un délai d'attente de sortie, une trentaine de millisecondes, sinon le module reste bloqué devant un obstacle trop lointain.

```cpp
const int TRIG = 7;
const int ECHO = 6;
const unsigned long TIMEOUT_ECHO = 30000UL;   // environ 5 mètres

float distanceEnCm() {
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  unsigned long duree = pulseIn(ECHO, HIGH, TIMEOUT_ECHO);
  if (duree == 0) return -1.0;                // rien détecté
  return duree * 0.0343 / 2.0;
}

void setup() {
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  Serial.begin(115200);
}

void loop() {
  float d = distanceEnCm();
  if (d < 0) Serial.println("pas d'echo");
  else { Serial.print(d, 1); Serial.println(" cm"); }
  delay(200);
}
```

Le détecteur de mouvement PIR constitue le cas le plus commode car il est presque entièrement analogique par nature, mais il se branche sur une broche numérique. Son dôme en plastique segmente le champ de visée en zones, et le mouvement d'une source de chaleur fait varier la tension produite par sa pyroélectricité ; l'électronique embarquée transforme cette variation en une sortie passant au niveau haut. Deux potentiomètres réglent la sensibilité, c'est-à-dire l'amplitude de variation nécessaire, et la durée de maintien après détection. La sortie reste active pendant cette durée, si bien que la broche ne dit pas tant où se trouve l'objet que si un mouvement vient d'être perçu. Ajoutez un délai à la lecture pour éviter les déclenchements en boucle, et souvenez-vous qu'un PIR ne détecte pas un objet immobile : il détecte un changement.

Le tableau suivant récapitule les capteurs que vous rencontrerez le plus souvent dans ce type de projet, avec la nature de leur sortie et la conséquence pratique qui en découle. La colonne de drooute est celle qui compte le plus quand on choisit un composant pour un prototype : elle indique si l'on peut se contenter d'une broche analogique, s'il faudra une bibliothèque, ou si l'on entre de plain-pied sur un bus de communication.

| Capteur | Grandeur | Sortie | Ce que cela implique |
| --- | --- | --- | --- |
| LM35 | température | analogique, 10 mV par degré | une broche analogique, conversion directe |
| NTC 10 kΩ | température | résistance variable | un pont diviseur, formule non linéaire |
| Photorésistance | lumière | résistance variable | un pont diviseur, étalonnage approximatif |
| DHT22 | température, humidité | numérique, un fil | une bibliothèque, une attente de 2 s |
| BME280 | température, pression | numérique, I2C | un bus, une adresse, plusieurs capteurs partagés |
| HC-SR04 | distance | impulsion de temps | pulseIn et calcul par la vitesse du son |
| PIR HC-SR501 | présence | binaire | une broche numérique, réglage au potentiomètre |

Quel que soit le capteur retenu, la démarche d'intégration reste identique et vaut la peine d'être ritualisée. Étape une : vérifier l'alimentation et la masse au multimètre. Étape deux : lire la valeur brute pendant qu'on provoque une variation nette, en chauffant, en couvrant ou en approchant la main. Étape trois : relier cette variation à la grandeur attendue et écrire la formule. Étape quatre : afficher les deux valeurs côte à côte, brute et convertie, pendant quelques minutes. Étape cinq seulement : intégrer la lecture au reste du programme. Ce protocole, fastidieux en apparence, vous fera gagner une heure dès la première panne, et il transforme un problème de code en problème d'étape identifiée.

- Le LM35 offre la sortie la plus directe : une tension proportionnelle à la température.
- Les capteurs DHT imposent un délai minimal entre deux lectures, de l'ordre de deux secondes.
- Le HC-SR04 mesure une durée et non une distance : à vous de faire le calcul.
- Un PIR détecte un changement, pas un objet immobile.
- Un bus comme I2C permet de relier plusieurs capteurs sur deux fils seulement.
- Suivez toujours les cinq étapes d'intégration avant de brancher un capteur au programme final.
$lesson$),
  ('ard-c2-p5', 'ard-c2', 5, $lesson$Potentiomètre et photorésistance : deux entrées pédagogiques$lesson$, $lesson$
Le potentiomètre est le capteur le plus simple qui existe, et pourtant il enseigne l'essentiel. Il s'agit d'une résistance dont on peut prendre la tension au niveau d'une cueillère mobile : deux bornes externes se branchent entre l'alimentation et la masse, la troisième, reliée au curseur, descend vers la broche analogique. On obtient alors un diviseur de tension réglable, dont la sortie varie linéairement entre les deux bornes quand on tourne le bouton. La lecture brute devient directement une position : zéro tourné à fond dans un sens, 1023 dans l'autre. C'est le principe du réglage de luminosité d'un écran, de la vitesse d'un ventilateur ou de l'angle d'un servomoteur, et c'est aussi le meilleur outil de simulation : avec un potentiomètre, vous pouvez piloter une valeur de consigne sans réécrire et re-téléverser le programme à chaque essai.

La photorésistance, ou LDR, se branche de la même manière, mais son rôle est inversé : au lieu d'être commandée par l'utilisateur, elle réagit à l'environnement. Sa résistance chute quand la lumière augmente, passant de plusieurs mégohms dans l'obscurité à quelques centaines d'ohms sous une lumière vive. Comme pour le NTC, on l'associe à une résistance fixe pour former un pont, et on lit la tension à leur jonction. Deux orientations sont possibles et donnent des sens opposés : si la LDR est placée vers l'alimentation, la tension monte quand la lumière augmente ; si elle est placée vers la masse, la tension baisse. Aucune n'est plus correcte que l'autre, mais il faut savoir laquelle on a choisie, car c'est elle qui décide si un seuil doit être écrit avec un plus ou un moins. Notez enfin que la sensibilité de l'œil et celle d'une LDR ne coïncident pas : l'espèce humaine est plus sensible au vert, la LDR est plus sensible au proche infrarouge.

```cpp
const int POT_PIN = A0;
const int LDR_PIN = A1;

void setup() {
  Serial.begin(115200);
}

void loop() {
  int pot = analogRead(POT_PIN);            // 0 à 1023
  int ldr = analogRead(LDR_PIN);            // 0 à 1023
  float ratio = pot / 1023.0;               // normalisé 0.0 à 1.0

  Serial.print("pot = ");
  Serial.print(pot);
  Serial.print(" (");
  Serial.print(ratio * 100.0, 0);
  Serial.print("%)   ldr = ");
  Serial.print(ldr);
  Serial.print("   lumi = ");
  Serial.println(ldr * 100.0 / 1023.0, 0);

  delay(200);
}
```

La normalisation, illustrée par le calcul du ratio ci-dessus, est une habitude de programmation à prendre très tôt. Plutôt que de traîner une valeur brute entre 0 et 1023 dans tout le programme, on la convertit immédiatement en fraction, entre 0,0 et 1,0, ou en pourcentage. Les seuils deviennent alors indépendants de la résolution de la carte : un seuil de 70 pour cent s'écrit de la même façon sur un Uno et sur un ESP32, alors qu'il vaudrait 717 sur l'un et 2866 sur l'autre. Ce petit réflexe de mise à l'échelle vous sauvera lorsque vous porterez un brouillon d'Uno vers un ESP32, et il prépare directement la lecture de la PWM où le même rapport, le duty cycle, décide de la puissance délivrée.

- Le potentiomètre fournit une position sous forme de tension réglable.
- La photorésistance est une résistance variable pilotée par la lumière.
- Le sens de variation dépend de l'orientation choisie dans le pont diviseur.
- Normalisez toujours une lecture entre 0,0 et 1,0 avant de la comparer à un seuil.
- Une hystérésis évite les basculements multiples autour d'une frontière.
- Utilisez un potentiomètre pour simuler une consigne pendant vos essais.

Nous avons jusqu'ici mesuré le monde : il reste à agir sur lui. La tension qu'une broche numérique peut fournir se limite à deux valeurs, plein courant ou rien, et cette brutalité convient mal à une LED que l'on veut atténuer, à un moteur dont on règle la vitesse ou à un servomoteur que l'on positionne au degré près. La modulation de largeur d'impulsion, abrégée PWM pour pulse width modulation, contourne cette limitation avec une astuce élégante : au lieu de produire une tension intermédiaire, on commute très vite entre la tension maximale et zéro, en faisant varier la part du temps passé dans chaque état. Le cerveau, l'œil et surtout l'inertie physique d'un moteur font le reste en percevant la moyenne. Cette section explique le principe, les réglages disponibles sur Arduino Uno et ESP32, puis les trois actionneurs classiques : la LED, le moteur DC et le servomoteur.
$lesson$),
  ('ard-c2-p6', 'ard-c2', 6, $lesson$Pourquoi une tension moyenne suffit : le principe du PWM$lesson$, $lesson$
Considérez une LED alimentée à 5 V avec sa résistance de protection. Si vous fermez le circuit une milliseconde sur deux, la LED ne reçoit ni 2,5 V, ni la moitié du courant : elle est soit allumée, soit éteinte, et elle parcourt ce cycle mille fois par seconde. Ce qui change n'est pas l'intensité instantanée, c'est la proportion du temps pendant laquelle elle brille. L'œil, incapable de suivre une variation aussi rapide, perçoit une luminosité proportionnelle à cette proportion, ce que l'on appelle le duty cycle ou rapport cyclique, exprimé en pourcentage. À 25 pour cent, la LED semble réduite au quart de sa puissance ; à 90 pour cent, elle paraît presque pleine, alors que le courant qui la traverse, lui, n'a jamais varié : toujours le même, simplement découpé.

Le moteur DC illustre le même principe par l'inertie mécanique. Sa masse en rotation ne peut pas s'arrêter ni démarrer instantanément ; entre deux impulsions, il conserve l'élan acquis, si bien qu'un enchaînement d'impulsions courtes se traduit par une rotation lente mais régulière. La vitesse devient ainsi proportionnelle au duty cycle, ce qui permet des démarrages doux, des arrêts progressifs et des régulations de vitesse sans aucun composant de puissance élaboré. Le servomoteur, lui, exploite la même idée à une fréquence précise et avec une sémantique différente : c'est la largeur de chaque impulsion, en microsecondes, qui commande la position, non le rapport en pour-cent. Les deux lectures du signal sont donc à distinguer soigneusement, car elles conduisent à des réglages opposés.

Le signal PWM est donc un signal carré caractérisé par deux paramètres : sa fréquence et son duty cycle. La fréquence décide de la finesse de l'approximation et du bruit perçu, le duty cycle décide de la puissance transmise. Une fréquence trop basse rend le clignotement visible sur une LED ou audible sur un moteur ; une fréquence trop élevée augmente les pertes dans l'étage de puissance et peut faire chauffer un transistor. Entre les deux, une plage confortable s'étend de quelques cents à quelques dizaines de kilohertz, valeur à laquelle un moteur chuinte encore légèrement mais où l'œil ne perçoit plus rien. Pour un servomoteur, la fréquence n'est pas un réglage libre : le standard exige 50 Hz, soit une période de 20 millisecondes.

```
        duty cycle = 25 %                    duty cycle = 75 %

  5 V ┌───┐   ┌───┐   ┌───┐   ┌───┐     ┌───────┐   ┌───────┐   ┌───┐
      │   │   │   │   │   │   │   │     │       │   │       │   │   │
  0 V ┘   └───┘   └───┘   └───┘   └───┘ ┘       └───┘       └───┘   └──

      |--|                                 |------|
      temps haut                           temps haut
      1/4 de la période                    3/4 de la période

  Tension moyenne : 1,25 V                Tension moyenne : 3,75 V
  sur une alimentation de 5 V             sur une alimentation de 5 V
```

La tension moyenne obtenue se calcule en multipliant la tension d'alimentation par le duty cycle exprimé en fraction. Pour 25 pour cent sur une alimentation de 5 V, on obtient 1,25 V ; pour 75 pour cent, 3,75 V. C'est ce calcul qui vous permet de prédire le comportement d'un actionneur avant même de l'allumer, et surtout de convertir une valeur voulue en valeur numérique à écrire. Si vous souhaitez une vitesse correspondant à 3 V sur une alimentation de 12 V, il vous faut un rapport de 25 pour cent, donc, sur une sortie de 8 bits, la valeur 64. Cette conversion proportionnelle, à ne jamais confondre avec la lecture analogique vue précédemment, est le geste mathématique central du PWM.

| Fréquence | Duty cycle | Tension moyenne sur 5 V | Usage typique |
| --- | --- | --- | --- |
| 490 Hz | 0 % | 0,0 V | extinction complète |
| 490 Hz | 50 % | 2,5 V | moitié de puissance |
| 490 Hz | 100 % | 5,0 V | pleine puissance |
| 5 kHz | 25 % | 1,25 V | LED faiblement lumineuse |
| 50 Hz | impulsion de 1,5 ms | position centrale | servomoteur à 90 degrés |
$lesson$),
  ('ard-c2-p7', 'ard-c2', 7, $lesson$Régler le duty cycle sur Arduino Uno avec analogWrite$lesson$, $lesson$
Sur l'Arduino Uno, la fonction analogWrite encapsule tout ce mécanisme. On lui donne une broche supportant la PWM, reconnaissable au signe tilde imprimé sur la carte, et une valeur entière de 0 à 255, soit une sortie de 8 bits. La valeur 0 correspond à l'arrêt total, la valeur 255 à la pleine puissance, et les valeurs intermédiaires se répartissent en 254 paliers. La fréquence est fixée par le cœur du système : environ 490 Hz sur la plupart des broches concernées, et environ 980 Hz sur les broches 5 et 6, dont le timer est déjà occupé par une autre fonction. Vous ne réglez donc pas la fréquence sur un Uno, seulement l'amplitude, ce qui convient parfaitement à l'éclairage et à la vitesse d'un moteur.

Un point important concerne les broches : seules celles marquées du tilde acceptent analogWrite. Sur un Uno, il s'agit des broches 3, 5, 6, 9, 10 et 11. Appeler analogWrite sur une broche ordinaire ne produit pas d'erreur d'exécution : la fonction se contente d'écrire un niveau haut ou bas selon que la valeur est supérieure à 127 ou non, ce qui donne une fausse bonne impression de fonctionnement, un binaire sec à la place d'une moyenne. Le moyen le plus sûr de détecter cette erreur est de mesurer la tension au multimètre ou d'observer le comportement d'une LED, dont la variation de luminosité sera nettement discontinue. Avant de câbler, repérez donc vos broches PWM sur le schéma de la carte.

```cpp
const int LED_PWM = 9;      // broche marquée du signe tilde
int valeur = 0;
int pas = 5;

void setup() {
  pinMode(LED_PWM, OUTPUT);
}

void loop() {
  analogWrite(LED_PWM, valeur);
  valeur += pas;
  if (valeur <= 0 || valeur >= 255) pas = -pas;   // marche arrière
  delay(20);
}
```

Le programme ci-dessus fait varier la valeur de 0 à 255 puis inverse le sens, créant un respiration continue de la LED. Notez la structure de l'inversion : quand la valeur atteint l'une des bornes, on change le signe du pas plutôt que d'écrire un embranchement complexe. Ce motif, très fréquent, se retrouve dans tous les balayages de luminosité, de température ou de position. Pour un usage plus sobre, remplacez la progression par une valeur fixe, par exemple analogWrite(LED_PWM, 64) pour un quart de puissance, ou reliez la lecture d'un potentiomètre à la fonction pour commander la luminosité à la main. Le second exercice du chapitre propose précisément cette montée.

- analogWrite prend une valeur de 0 à 255 sur une broche marquée du tilde.
- La fréquence par défaut est fixe, autour de 490 Hz, sauf exceptions de broche.
- Une broche non PWM traitée en binaire donne un résultat trompeur mais pas d'erreur.
- La valeur 0 éteint complètement, la valeur 255 correspond à la pleine puissance.
- Deux usages de timers peuvent entrer en conflit quand on cumule PWM et protocoles.
$lesson$),
  ('ard-c2-p8', 'ard-c2', 8, $lesson$Le périphérique LEDC de l'ESP32 : fréquence et résolution au choix$lesson$, $lesson$
L'ESP32 aborde le problème avec un matériel nettement plus riche : un périphérique nommé LEDC, pour LED controller, qui comprend seize canaux indépendants, chacun muni de son propre compteur et de son propre générateur de signal carré. Contrairement à analogWrite, on y choisit explicitement la fréquence et la résolution. La résolution peut aller de 1 à 16 bits, ce qui donne soit la finesse d'origine de 0 à 255, soit une échelle de 0 à 65535, très confortable pour une régulation de vitesse exigeante. La fréquence, elle, s'étend sur une plage considérable, de quelques hertz à plusieurs mégahertz, à condition de respecter une contrainte : le produit de la fréquence par le nombre de pas de la résolution ne doit pas dépasser la fréquence de l'horloge source divisée par un diviseur minimal.

La configuration s'effectue en trois appels. Le premier, ledcSetup, fixe pour un canal donné sa fréquence en hertz et sa résolution en bits. Le second, ledcAttachPin, associe ce canal à une broche physique, et l'on peut enchaîner plusieurs appels pour piloter plusieurs LED ou plusieurs moteurs sur des canaux distincts. Le troisième, ledcWrite, écrit la valeur de duty dans le canal, avec une plage allant de zéro à deux puissances de la résolution moins un. Sur les versions récentes du cœur ESP32, une API simplifiée existe, ledcAttach et ledcWrite par broche, mais comprendre l'ancienne forme reste utile car elle montre explicitement la séparation entre canal logique et broche physique.

```cpp
const int BROCHE_LED = 2;
const int CANAL = 0;
const int FREQUENCE = 5000;    // 5 kHz : inaudible sur un moteur
const int RESOLUTION = 8;      // 8 bits : 0 à 255, comme sur un Uno

void setup() {
  ledcSetup(CANAL, FREQUENCE, RESOLUTION);
  ledcAttachPin(BROCHE_LED, CANAL);
}

void loop() {
  for (int d = 0; d <= 255; d++) {
    ledcWrite(CANAL, d);
    delay(8);
  }
  for (int d = 255; d >= 0; d--) {
    ledcWrite(CANAL, d);
    delay(8);
  }
}
```

Un réglage mérite d'être mentionné pour les moteurs : choisir une fréquence trop basse fait claquer mécaniquement le moteur et produire un sifflement aigu à l'oreille humaine. Entre 5 et 20 kHz, le sifflement disparaît car il sort du champ auditif, et la vitesse reste bien régulée. Pour un servomoteur, en revanche, la fréquence doit être exactement 50 Hz et la période de 20 millisecondes, car c'est ce rythme que le circuit interne du servo attend ; en dehors de cette plage, il perd la position ou vibre. Enfin, pour un éclairage, une fréquence basse suffit et diminue les pertes. Bref, la fréquence n'est pas un réglage anodin : elle se choisit à partir de la physique de l'actionneur, avant même d'écrire la boucle.

Il existe une différence supplémentaire entre les deux cartes qui n'apparaît qu'en mesurant : la tension d'alimentation. L'ESP32 travaille à 3,3 V, et sa broche ne peut délivrer ni 5 V ni un courant important, de l'ordre de quelques dizaines de milliampères au maximum. Une LED blanche à 3,3 V s'allume correctement, mais un moteur de 5 V ou un servomoteur réclame une alimentation externe, reliée à la masse commune de la carte sans pour autant y puiser son courant. Cette règle de l'alimentation séparée, avec une masse commune obligatoire, revient pour tous les actionneurs puissants et sera détaillée dans la section suivante.

- LEDC offre 16 canaux, chacun avec sa fréquence et sa résolution propres.
- ledcSetup configure le canal, ledcAttachPin le relie à une broche, ledcWrite écrit le duty.
- Choisissez la fréquence en fonction de l'actionneur : 50 Hz pour un servo, 5 kHz ou plus pour un moteur.
- Une résolution de 16 bits permet des réglages de vitesse très fins.
- La sortie de l'ESP32 est en 3,3 V et très limitée en courant.
$lesson$),
  ('ard-c2-p9', 'ard-c2', 9, $lesson$Piloter un moteur DC : transistor, diode et puissance$lesson$, $lesson$
Un moteur DC est l'actionneur le plus utile et le plus dangereux pour une carte de développement, pour une raison simple : il consomme bien plus que ce qu'une broche peut délivrer, typiquement de quelques centaines de milliampères à plusieurs ampères, et il génère des phénomènes parasites en retour. Le transistor joue alors le rôle d'interrupteur commandé : un très faible courant appliqué à sa base, quelques milliampères venant de la broche, autorise un courant important entre ses deux autres bornes. Pour un petit moteur, un transistor NPN comme le 2N2222 convient, en l'alimentant par une résistance de base qui limite le courant demandé à la carte. Pour des moteurs plus puissants, on préfère un MOSFET à logique 3,3 V, dont la commande ne consomme presque rien et qui reste froid même à fort courant.

La diode de roue libre n'est pas une option de confort, c'est une pièce de sécurité obligatoire. Un moteur est une bobine, et une bobine s'oppose à toute variation brutale de courant : quand la commande se ferme, le champ magnétique s'effondre et le moteur devient brièvement un générateur, produisant une surtension inverse qui peut dépasser une centaine de volts. Cette impulsion trouve naturellement passage dans la jonction du transistor et le détruit, souvent de façon silencieuse, c'est-à-dire avec un composant devenu passant ou ouvert. La diode branchée en opposition aux bornes du moteur rattrape ce pic : elle conduit pendant la fraction de seconde où la tension inverse apparaît, la dissipe, puis se referme. Elle se pose donc cathode vers l'alimentation positive, et se teste au multimètre en deux secondes.

```
         alimentation moteur (+)
                │
                ├──────────────┐
                │              │
                │         ┌────┴────┐
                │         │  moteur │
                │         └────┬────┘
                │         ┌────┴────┐
                │         │   diode │  cathode vers le haut
                │         └────┬────┘
                │              │
                │         collecteur
                │            ┌─┴─┐
   broche PWM ──┴── R base ──┤ B   C  transistor NPN
                             │ E │
                             └─┬─┘
                               │
                              masse
```

Le câblage complet suit donc un trajet unique : masse commune, émetteur du transistor à la masse, base reliée à la broche PWM par une résistance, collecteur au bornier négatif du moteur, borne positive du moteur à l'alimentation moteur, et diode en travers du moteur. Le duty cycle appliqué à la base règle la vitesse, la résistance de base protège la carte, la diode protège le transistor. N'alimentez jamais un moteur depuis la broche d'alimentation régulée de la carte : les chutes de tension provoquées par les accélérations provoquent des redémarrages intempestifs du microcontrôleur, symptôme très reconnaissable puisque la carte se réinitialise à chaque démarrage du moteur.

```cpp
const int MOTEUR_PIN = 9;     // broche PWM, marque tilde obligatoire

void setup() {
  pinMode(MOTEUR_PIN, OUTPUT);
  analogWrite(MOTEUR_PIN, 0);   // démarrage à l'arrêt, toujours
}

void demarrerProgressif(int pin, int vitesseCible) {
  for (int v = 0; v <= vitesseCible; v += 5) {
    analogWrite(pin, v);
    delay(40);
  }
}

void setupEtArret() {
  for (int v = 255; v >= 0; v -= 5) {
    analogWrite(MOTEUR_PIN, v);
    delay(40);
  }
  analogWrite(MOTEUR_PIN, 0);
}
```

- Un transistor pilote un grand courant avec un tout petit courant de commande.
- La diode de roue libre absorbe la surtension générée à l'arrêt du moteur.
- Sa cathode se branche du côté de l'alimentation positive.
- Alimentez le moteur sur une source dédiée, jamais sur la sortie régulée de la carte.
- Démarrez toujours à zéro puis augmentez progressivement le duty cycle.
- Séparez physiquement câbles de puissance et câbles de mesure.
$lesson$),
  ('ard-c2-p10', 'ard-c2', 10, $lesson$Servomoteur et relais : deux commandes très différentes$lesson$, $lesson$
Le servomoteur se distingue des autres actionneurs parce qu'il ne reçoit pas une puissance mais une consigne de position. Son circuit interne reçoit une impulsion dont la largeur indique l'angle voulu : environ 1 milliseconde pour la position la plus à gauche, 1,5 milliseconde pour le centre, 2 millisecondes pour la position la plus à droite, le tout répété à une fréquence de 50 Hz. Un comparateur et un potentiomètre mécanique couplés à un petit moteur forment une boucle de régulation locale : le servo tourne jusqu'à ce que sa position corresponde à la commande, puis s'arrête. C'est cette boucle interne qui explique qu'un servo maintient une position contre une résistance modérée, et aussi qu'il consomme du courant dès qu'on le déplace.

Sur Arduino, la bibliothèque Servo masque entièrement ces détails. On déclare un objet, on l'attache à une broche avec la méthode attach, puis on écrit la position voulue avec write en degrés, de 0 à 180 par défaut. La bibliothèque gère elle-même la génération des impulsions à l'aide d'un timer, ce qui a deux conséquences pratiques : elle occupe ce timer, donc certaines lectures de durée deviennent indisponibles, et elle impose des durées de retour à zéro compatibles avec le standard. Pour affiner la course réelle de votre servo, que ses mécanismes font toujours varier d'un modèle à l'autre, la forme writeMicroseconds vous donne un contrôle direct en microsecondes et permet de recaler les bornes mécaniques.

```cpp
#include <Servo.h>

Servo monServo;
const int SERVO_PIN = 10;

void setup() {
  monServo.attach(SERVO_PIN, 500, 2500);   // recalage des bornes
}

void loop() {
  for (int angle = 0; angle <= 180; angle += 3) {
    monServo.write(angle);
    delay(25);
  }
  for (int angle = 180; angle >= 0; angle -= 3) {
    monServo.write(angle);
    delay(25);
  }
}
```

L'alimentation du servo est le piège classique de ce composant. Un petit servo comme le SG90 réclame plusieurs centaines de milliampères au démarrage, parfois près d'un ampère en charge, ce qui dépasse largement la capacité d'un régulateur de carte. Branché sur la sortie 5 V de l'Arduino, il provoque une chute de tension à chaque mouvement, et la carte redémarre au milieu de l'exécution, le programme recommençant alors indéfiniment depuis le début. La solution consiste à alimenter le servo sur une source externe dédiée, à relier les masses des deux alimentations en un point unique, et à éventuellement prévoir une capacité d'au moins 100 microfarads aux bornes du servo pour amortir les pointes.

Le relais, enfin, apporte une fonction que les autres actionneurs ne donnent pas : l'inversion mécanique et l'isolement. Un module de relais comporte une bobine, une paire de contacts et, dans les versions recommandées, un étage opto-isolé qui sépare électriquement la commande de la charge. On commande une broche numérique, la bobine aspire l'armature, les contacts commutent, et un appareil sous tension secteur peut alors être allumé. Deux précautions s'imposent. La première est que de nombreux modules sont actifs au niveau bas : leur broche de commande doit être mise à l'état bas pour activer le relais, ce qui inverse la logique de votre programme. La seconde concerne la sécurité : rien de ce qui se passe côté 220 V ne doit jamais être manipulé pendant les essais sans les précautions d'usage, le rôle de l'opto-isolateur n'étant pas de rendre l'opération anodine.

- Un servo reçoit une commande de position, pas une puissance : impulsion de 1 à 2 ms à 50 Hz.
- writeMicroseconds permet de recaler précisément la course mécanique.
- Alimentez un servo sur une source externe, avec masse commune à la carte.
- Un relais commande des charges élevées et isole galvaniquement la partie puissance.
- De nombreux modules de relais sont actifs à l'état bas : vérifiez la logique.
- Les deux familles d'actionneurs se pilotent en PWM ou en broche numérique selon le cas.

Une mesure que l'on ne voit pas n'existe pas. Jusqu'ici, vos programmes ont lu des tensions et piloté des puissances, mais la valeur obtenue restait enfermée dans la carte : pour l'exploiter, il faut l'envoyer vers l'extérieur, l'afficher, l'enregistrer, la comparer à une autre. C'est le rôle du port série, cette liaison qui relie la carte à votre ordinateur par le même câble qui la décharge et la programme. Cette dernière partie du chapitre vous montre à organiser cette sortie : choisir une vitesse de communication compatible, formater les valeurs avec un nombre de décimales cohérent, leur donner un horodatage, puis adopter un format structuré, clé-valeur, CSV ou JSON, que vous pourrez relire à tête reposée ou importer dans un tableur. Elle se termine par le mini-projet qui rassemble toutes les notions du chapitre.
$lesson$),
  ('ard-c2-p11', 'ard-c2', 11, $lesson$Afficher les mesures sur le moniteur série$lesson$, $lesson$
Tout commence par Serial.begin, appelé une seule fois dans setup avec la vitesse de communication exprimée en bauds, c'est-à-dire en bits par seconde. La valeur 9600 est l'héritage des premiers microcontrôleurs, où elle suffisait amplement ; 115200 est aujourd'hui le réglage le plus courant, car il permet d'envoyer de longs messages sans ralentir le programme. Cette valeur doit correspondre exactement à celle réglée dans le moniteur série de votre éditeur : en cas de désaccord, le texte arrive, mais déformé, en une succession de caractères indéchiffrables. Ce symptôme, très fréquent au départ, ne provient jamais du programme lui-même, seulement d'une vitesse mal assortie, et se répare en deux clics.

Les fonctions d'envoi s'utilisent en deux variantes. Serial.print envoie un fragment sans retour à la ligne, Serial.println ajoute le retour à la ligne, si bien que le style courant consiste à écrire un libellé, puis une valeur, puis à fermer la ligne avec println. Les nombres décimaux acceptent un second argument qui fixe le nombre de chiffres après la virgule : print(tension, 3) affiche trois décimales, ce qui évite d'afficher seize chiffres pour un résultat qui n'en mérite que deux. Toutes les valeurs, entières, décimales, textuelles, sont converties en caractères avant l'envoi : le port série ne transporte que du texte, et la conversion est prise en charge par la bibliothèque.

```cpp
const int BROCHE = A0;

void setup() {
  Serial.begin(115200);
  while (!Serial) { }        // attend l'ouverture du port sur certaines cartes
}

void loop() {
  int brut = analogRead(BROCHE);
  float tension = brut * 5.0 / 1023.0;
  float temp = tension / 0.01;

  Serial.print("brut=");
  Serial.print(brut);
  Serial.print("  V=");
  Serial.print(tension, 3);
  Serial.print("  T=");
  Serial.print(temp, 1);
  Serial.println(" C");
  delay(500);
}
```

Un second réflexe à acquérir concerne la fréquence d'affichage. Envoyer une ligne toutes les millisecondes sature le moniteur, ralentit le programme qui attend que le tampon se vide, et rend l'écran illisible. Pour une mesure lente comme la température, une ligne par seconde suffit largement ; pour observer une rampe de démarrage, on peut monter à dix lignes par seconde ; au-delà, c'est le graphique de l'éditeur qu'il faut utiliser. La solution consiste à séparer la période de mesure de la période d'affichage : on lit souvent, on affiche rarement, avec deux compteurs de temps indépendants fondés sur millis(). Ce découplage est exactement celui que vous utiliserez dans le mini-projet, et il évite le piège classique du delay() placé au mauvais endroit, qui ralentit toute la boucle.

Le moniteur série propose aussi deux fonctionnalités que l'on ignore trop longtemps. Le graphique intégré trace en temps réel les valeurs numériques envoyées, ce qui est incomparablement plus parlant qu'une colonne de chiffres défilant : une variation de quelques points devient immédiatement lisible comme une courbe, et l'on distingue le bruit d'une vraie évolution. La zone de saisie permet, elle, d'envoyer du texte vers la carte, ce qui ouvre la porte aux consignes à distance, la température cible d'un thermostat par exemple. Ces deux outils transforment le port série en véritable interface de laboratoire, sans rien ajouter au matériel.

- Serial.begin fixe la vitesse, qui doit correspondre à celle du moniteur.
- print envoie sans retour à la ligne, println le ferme.
- Un second argument limite le nombre de décimales affichées.
- Séparez la période de mesure de la période d'affichage avec millis().
- Le graphique intégré révèle le bruit que masque une colonne de chiffres.
- La zone de saisie permet d'envoyer des commandes vers la carte.
$lesson$),
  ('ard-c2-p12', 'ard-c2', 12, $lesson$Format structuré, unités et horodatage$lesson$, $lesson$
Un affichage lisible par un humain n'est pas nécessairement lisible par un programme. Dès que vous souhaitez enregistrer des mesures, les importer dans un tableur ou les faire consommer par un autre logiciel, il faut adopter un format structuré. Trois formes couvrent la quasi-totalité des besoins. Le format clé-valeur, par exemple temp=23.5 hum=48, se lit d'un coup d'œil et se parse avec quelques lignes. Le format CSV, séparé par des virgules, s'importe directement dans un tableur ou un langage d'analyse de données. Le format JSON, plus rigoureux, accepte les types imbriqués et bénéficie d'outils universels pour sa lecture. Pour un relevé de banc, choisissez CSV ; pour un dialogue entre programmes, choisissez JSON ; pour un affichage quotidien, le clé-valeur suffit.

L'horodatage donne son contexte à chaque mesure. La fonction millis() renvoie le nombre de millisecondes écoulées depuis le démarrage de la carte, sous forme d'un entier non signé sur 32 bits, ce qui couvre environ 49 jours de fonctionnement continu. Cette valeur n'est pas une date : c'est un temps relatif, parfait pour espacer des échantillons, mesurer des durées ou construire des séries temporelles à partir du démarrage. Pour une véritable date, il faut un module d'horloge temps réel, comme le DS3231, qui conserve l'heure à l'alimentation près. Dans la majorité des projets pédagogiques, millis() suffit amplement : il faut simplement garder à l'esprit que la première mesure porte la valeur zéro, non minuit.

```cpp
const int BROCHE = A0;
unsigned long dernierAffichage = 0;
const unsigned long PERIODE = 1000;   // une ligne par seconde

void setup() {
  Serial.begin(115200);
}

void loop() {
  unsigned long maintenant = millis();

  if (maintenant - dernierAffichage >= PERIODE) {
    dernierAffichage = maintenant;
    int brut = analogRead(BROCHE);
    float temp = brut * 5.0 / 1023.0 / 0.01;

    // format clé-valeur, une ligne, horodatée
    Serial.print("ts=");
    Serial.print(maintenant);
    Serial.print("ms temp=");
    Serial.print(temp, 1);
    Serial.println("C");
  }
}
```

Deux pièges d'affichage méritent d'être signalés, parce qu'ils coûtent toujours une heure de recherche. Le premier concerne les entiers non signés : comparer deux valeurs de millis() avec un simple plus est incorrect au moment du débordement, et la syntaxe soustraction puis comparaison, celle que l'exemple ci-dessus utilise, est la seule correcte. Le second concerne les chaînes construites à la main : la moindre virgule manquante ou le moindre guillemet oublié casse l'analyse d'un JSON en aval, sans que la carte elle-même signale la moindre erreur. C'est pourquoi on conseille de tester d'abord l'affichage à l'œil, puis de soumettre un exemplaire au parseur du langage de votre choix avant d'enchaîner des centaines de lignes.

Le tableau ci-dessous compare les trois formats sur une même mesure, afin que le choix soit fait en connaissance de cause. La ligne CSV se prête à l'import direct dans un tableur, la ligne clé-valeur à un débogage rapide, la ligne JSON à un échange entre programmes. Dans le mini-projet, vous produirez une de ces trois formes, avec pour chacune l'horodatage, la valeur, l'unité et l'état de l'actionneur, ce qui rend la mesure exploitable sans autre information d'accompagnement.

| Format | Exemple | Se lit à l'œil | Se parse automatiquement | Usage recommandé |
| --- | --- | --- | --- | --- |
| clé-valeur | ts=12540 temp=23.5C | très bien | facile | débogage quotidien |
| CSV | 12540,23.5,48,1 | bien | très facile | import tableur |
| JSON | ts de 12540 avec temp 23.5 | correct | très robuste | échange entre programmes |

- Horodatez chaque mesure avec millis(), temps relatif depuis le démarrage.
- CSV pour le tableur, JSON pour les échanges structurés, clé-valeur pour soi.
- Comparez toujours millis() par soustraction, jamais par addition.
- Séparez clairement unité et valeur : 23.5C vaut mieux que 23.5.
- Testez une ligne sur un parseur avant d'en produire des centaines.
- Limitez la fréquence d'envoi : une ligne par seconde pour une mesure lente.
$lesson$),
  ('ard-c2-p13', 'ard-c2', 13, $lesson$Mini-projet : la station climatique complète$lesson$, $lesson$
Nous voici réunis pour assembler le projet fil rouge du chapitre. L'appareil surveille la température d'une pièce, compare la valeur à une consigne réglable, pilote un ventilateur en PWM quand il faut rafraîchir, allume une LED d'état et publie régulièrement une mesure horodatée sur le port série. Il met donc en jeu toutes les notions vues jusqu'ici : lecture analogique et conversion, moyennage pour stabiliser, seuil avec hystérésis pour éviter les basculements, PWM pour commander la puissance, entrée série pour modifier la consigne à chaud, et affichage structuré. Comme toujours, nous commencerons par la chaîne de mesure, puis la chaîne de commande, puis le lien entre les deux.

La chaîne de mesure appelle la fonction de lecture moyennée de la section précédente. On lit huit échantillons, on les convertit en tension avec la référence de la carte, puis en température avec la pente du LM35. On stocke le résultat dans une variable flottante mise à jour une fois par seconde, et seulement elle : répéter la lecture à chaque passage de la boucle pour l'affichage produirait des valeurs différentes d'une ligne à l'autre, alors qu'il s'agit de la même mesure. La consigne et l'hystérésis sont déclarées en tête de fichier comme constantes nommées, ce qui rend le programme lisible et évite les nombres magiques dispersés dans le code.

La logique de commande repose sur l'hystérésis, ce mécanisme qui remonte au XIXe siècle et qui règle tous les thermostatiques. On fait démarrer le ventilateur quand la température dépasse la consigne plus un demi-degré, et on ne l'arrête qu'en dessous de la consigne moins un demi-degré. Entre ces deux seuils, l'état précédent se maintient. Sans cette marge, la mesure, qui oscille naturellement de quelques dixièmes, provoquerait un enchaînement de démarrages et d'arrêts, destructeur pour le moteur et incompréhensible à l'observation. La largeur de la bande morte se règle en pratique : un dixième de degré réagit vite mais claque, un degré est calme mais retarde l'action.

```cpp
const int LM35_PIN = A0;
const int VENTIL_PIN = 9;      // PWM, broche tilde
const int LED_VERTE = 7;
const int LED_ROUGE = 8;

const float VREF = 5.0;
const int ADC_MAX = 1023;
const float CONSIGNE_INIT = 25.0;
const float HYSTERESIS = 0.5;

float consigne = CONSIGNE_INIT;
bool ventilateur = false;
unsigned long dernierLux = 0;
unsigned long derniereLigne = 0;

float lireTemperature() {
  long somme = 0;
  for (int i = 0; i < 8; i++) somme += analogRead(LM35_PIN);
  float brut = (float)somme / 8.0;
  return brut * VREF / ADC_MAX / 0.01;
}

void setup() {
  pinMode(VENTIL_PIN, OUTPUT);
  pinMode(LED_VERTE, OUTPUT);
  pinMode(LED_ROUGE, OUTPUT);
  Serial.begin(115200);
  Serial.println("station prete");
}

void loop() {
  unsigned long now = millis();

  if (now - dernierLux >= 1000) {
    dernierLux = now;
    float t = lireTemperature();
    if (!ventilateur && t > consigne + HYSTERESIS) ventilateur = true;
    if (ventilateur && t < consigne - HYSTERESIS) ventilateur = false;

    analogWrite(VENTIL_PIN, ventilateur ? 200 : 0);
    digitalWrite(LED_VERTE, !ventilateur);
    digitalWrite(LED_ROUGE, ventilateur);
  }

  if (now - derniereLigne >= 5000) {
    derniereLigne = now;
    float t = lireTemperature();
    Serial.print("{\"ts\":");
    Serial.print(now);
    Serial.print(",\"temp\":");
    Serial.print(t, 1);
    Serial.print(",\"consigne\":");
    Serial.print(consigne, 1);
    Serial.print(",\"fan\":");
    Serial.print(ventilateur ? 1 : 0);
    Serial.println("}");
  }

  if (Serial.available()) {
    String commande = Serial.readStringUntil('\n');
    commande.trim();
    if (commande.startsWith("SET:")) {
      float valeur = commande.substring(4).toFloat();
      if (valeur > 5.0 && valeur < 45.0) {
        consigne = valeur;
        Serial.print("nouvelle consigne ");
        Serial.println(consigne, 1);
      }
    }
  }
}
```

Le programme ci-dessus est entièrement non bloquant : aucune attente ne fige la boucle, chaque tâche possède son propre compteur de temps. C'est cette structure qui vous permet de lire la série pendant que le ventilateur continue de se commander et que la consigne se modifie à la volée. Notez que la température est relue pour l'affichage plutôt que stockée depuis la dernière mesure : dans un vrai appareil, vous préférerez conserver la dernière valeur lue pour garantir que la ligne publiée correspond exactement à l'état commandé, arbitrage typique entre fraîcheur et cohérence. Notez aussi la validation de la consigne reçue : toute valeur hors plage plausible est rejetée, si bien qu'une saisie erronée dans le moniteur ne peut pas mettre l'appareil dans un état absurde.

La vérification du montage se fait en trois temps, dans cet ordre. D'abord, débranchez le ventilateur et observez uniquement la température affichée : elle doit évoluer doucement et refléter votre souffle ou votre main. Ensuite, réintroduisez la commande du ventilateur et vérifiez que les deux LED basculent aux bons seuils, en soufflant sur le capteur pour simuler une montée. Enfin, testez la commande série avec une consigne basse, par exemple une consigne de 20 degrés, qui doit déclencher le ventilateur immédiatement, puis remontez la consigne pour l'arrêter. Chaque étape isole une fonctionnalité : si l'une échoue, vous savez exactement laquelle corriger, sans jamais deviner.

- Séparez les trois chaînes : mesure, décision, commande.
- Appliquez l'hystérésis pour éviter les basculements en frontière.
- Conservez deux compteurs de temps indépendants pour mesurer et publier.
- Validez toute consigne reçue avant de l'appliquer.
- Vérifiez le système par étapes isolées, jamais en une seule tentative.
- Aucune attente bloquante : la boucle reste disponible pour toutes les tâches.
$lesson$),
  ('ard-c2-p14', 'ard-c2', 14, $lesson$À retenir$lesson$, $lesson$
- Un capteur convertit une grandeur physique en signal ; un actionneur convertit un ordre en effet.
- analogRead renvoie un indice dans une échelle : Uno de 0 à 1023, ESP32 de 0 à 4095.
- La conversion en tension s'écrit valeur brute multipliée par la référence, divisée par le maximum.
- Chaque capteur impose sa loi : 10 mV par degré pour le LM35, pont diviseur pour une LDR ou un NTC.
- Moyenner quelques échantillons réduit le bruit ; convertissez la somme en flottant avant de diviser.
- Le PWM produit une tension moyenne en faisant varier le duty cycle d'un signal carré.
- analogWrite accepte de 0 à 255 sur les broches tilde ; LEDC ajoute 16 canaux, fréquence et résolution réglables.
- Un moteur exige un transistor, une diode de roue libre et une alimentation dédiée.
- Un servo se commande par impulsion de 1 à 2 ms à 50 Hz et réclame son propre alimentation.
- Le port série exige des vitesses identiques des deux côtés et gagne à être horodaté et structuré.
- millis() fournit un temps relatif fiable pour espacer lectures et publications.
- L'hystérésis protège toute régulation contre les basculements en frontière de seuil.
$lesson$),
  ('ard-c2-p15', 'ard-c2', 15, $lesson$Erreurs fréquentes$lesson$, $lesson$
La première erreur, et de loin la plus fréquente, consiste à confondre la valeur brute et la tension. Une lecture de 512 ne vaut pas 512 volts ni 512 degrés : elle correspond à environ 2,50 V sur un Uno, et à peine 0,41 V sur un ESP32. Transférer un sketch d'une carte à l'autre sans reprendre la référence et la résolution produit des résultats absurdes qui semblent pourtant parfaitement cohérents en première lecture. Vérifiez toujours les deux constantes, référence et maximum, avant de chercher une faute dans le capteur.

La deuxième erreur est la division entière. Si vous écrivez la conversion avec des entiers, la partie décimale est tronquée et la mesure avance par paliers brutaux : une température reste bloquée à 23 degrés pendant que la tension réelle monte de dixièmes. Convertissez au moins un des termes en nombre décimal, ou lancez explicitement un cast, pour forcer l'arithmétique réelle. La même remarque vaut pour la moyenne : additionner des entiers puis diviser par huit reste une division entière tant que rien ne signale le contraire.

La troisième erreur vient des broches : appeler analogWrite sur une broche sans PWM, ou oublier que le pin 9 est bien concerné mais pas le pin 8, donne des comportements étranges sans message d'erreur. Sur ESP32, oubliez d'attacher le canal à la broche et votre ledcWrite modifie un canal qui ne commande rien. La quatrième est l'alimentation : un servo ou un moteur pris sur la sortie régulée de la carte provoque des redémarrages intempestifs, toujours au pire moment. Enfin, la cinquième concerne le moniteur série : une vitesse différente de celle du programme donne du texte indéchiffrable, et la simple modification d'un paramètre suffit alors à faire croire à une panne matérielle.

Un sixième point mérite attention parce qu'il est purement logique : l'oubli de l'hystérésis. Un simple test de température strictement supérieur au seuil, avec une mesure qui oscille de deux dixièmes, fait clignoter le relais ou le ventilateur plusieurs fois par seconde. Ajoutez une bande morte d'un demi-degré et le problème disparaît. Une septième erreur classique est de placer un delay() long au milieu de la boucle : pendant cette attente, la carte ne lit plus rien, n'exécute plus aucune commande et ne répond plus au port série. Remplacez toujours une attente par une comparaison de compteurs de temps, et gardez le delay pour les seuls cas où le programme n'a réellement rien d'autre à faire.
$lesson$),
  ('ard-c2-p16', 'ard-c2', 16, $lesson$Pour aller plus loin$lesson$, $lesson$
Pour approfondir, commencez par la documentation officielle des fonctions de la carte, qui détaille les constantes de chaque famille de microcontrôleurs, les timers occupés et les particularités des entrées analogiques. Elle répond à la plupart des questions que vous vous poserez en passant d'un matériel à l'autre. Les fiches techniques des capteurs, ensuite, valent le détour même si elles semblent techniques : une page consacrée aux caractéristiques électriques vous apprendra la sensibilité, la plage, la consommation et les tolérances, autant d'informations qui font la différence entre un prototype qui mesure et un prototype qui estime.

En pratique, le meilleur exercice suivant consiste à ajouter une deuxième grandeur à votre station : l'humidité avec un DHT22, ou la pression avec un BME280. Vous découvrirez alors la notion de bibliothèque externe, d'installation par gestionnaire, et la différence entre un capteur analogique qu'on lit en une ligne et un capteur numérique dont il faut mettre en place un protocole. Un second axe d'approfissage est l'enregistrement des données : au lieu d'afficher, écrire sur une carte mémoire, avec un format CSV, transforme l'appareil en station d'acquisition et vous apprend à gérer l'espace, les en-têtes de colonnes et la rotation des fichiers.

Le dernier prolongement concerne l'habillage : un écran local pour afficher la mesure sans ordinateur, puis une publication réseau pour la consulter à distance. Tous deux s'appuient sur la même chaîne de traitement que celle du mini-projet : la mesure reste la mesure, seule la sortie change. C'est la leçon principale de ce chapitre, et vous la retrouverez dans les suivants : si votre code sépare proprement la lecture, la décision et la sortie, chaque nouvelle fonctionnalité se greffe sans réécriture, et un projet devenu complexe reste lisible.
$lesson$),
  ('ard-c2-p17', 'ard-c2', 17, $lesson$Et maintenant : passez à la mesure réelle$lesson$, $lesson$
Vous disposez à présent de tout ce qu'il faut pour faire entrer le monde physique dans votre carte : convertir une tension en nombre, fiabiliser la mesure, commander une puissance et rendre le résultat observable. Le prochain pas ne demande aucune nouvelle théorie : branchez un capteur, lancez le programme d'affichage brut, déclenchez une variation avec votre main, puis écrivez la formule qui relie les deux. Une fois cette chaîne vérifiée, réécrivez seul le mini-projet du thermostat, sans regarder l'exemple, en structurant le code en trois fonctions : lire, décider, agir. C'est cet exercice, plus que la lecture, qui fixera les notions.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('ard-c3-p1', 'ard-c3', 1, $lesson$Pourquoi afficher et faire communiquer$lesson$, $lesson$
Bienvenue dans le troisième chapitre du parcours Arduino et ESP32, consacré aux afficheurs et aux bus de communication. Les deux chapitres précédents vous ont appris à faire réagir la carte à son environnement : faire clignoter une LED, lire un bouton, mesurer une tension avec un convertisseur analogique-numérique et piloter un actionneur en modulation de largeur d'impulsion. Tout cela se passait en silence, entre votre carte et vos composants. Ce chapitre change d'échelle : il ajoute deux capacités indispensables à tout objet connecté, la capacité de montrer quelque chose à l'humain et la capacité de discuter avec d'autres circuits. Vous y découvrirez l'écran LCD 16x2, dans sa version parallèle historique comme dans sa version I2C que vous rencontrerez partout, puis le bus I2C dans sa totalité, le bus SPI avec la carte mémoire qui l'illustre le mieux, et enfin le port série asynchrone qui reste l'outil de débogage le plus puissant à votre disposition.

À la fin de cette leçon, vous saurez faire des choses très concrètes, toutes testables sur votre paillasse en une dizaine de minutes. Vous câblerez un écran LCD 16x2 en mode parallèle avec six fils de données, puis vous le recâblerez en I2C avec deux fils seulement en utilisant un expandeur PCF8574. Vous écrirez du texte, positionnerez le curseur ligne par ligne, effacerez proprement un écran et créerez des caractères personnalisés tels qu'un cœur, une flèche ou une jauge de batterie. Vous balayerez le bus I2C pour découvrir les adresses des appareils présents, vous décoderez un capteur en lisant ses registres un par un, puis vous utiliserez le SPI pour écrire et relire un fichier sur une carte SD. Enfin, vous ferez dialoguer deux cartes par leur port série et vous choisirez le bon bus pour un projet donné en comparant leurs forces et leurs limites. Chaque compétence est montrée en code complet, puis réutilisée dans un exemple plus large.

La méthode de travail que nous suivrons est la même que dans les chapitres précédents, parce qu'elle a fait ses preuves : on comprend d'abord le principe physique ou protocolaire, on regarde ensuite un exemple minimal qui fonctionne tel quel, puis on l'enrichit jusqu'à obtenir un utilisateur réel. Rien dans ce chapitre suppose des connaissances en électronique avancée : les seules notions requises sont celles des deux premiers chapitres, à savoir câbler une résistance, configurer une broche en entrée ou en sortie, et écrire une boucle. Le fil rouge de la leçon sera une petite station d'affichage : un écran LCD qui montre des mesures, un capteur branché sur le même bus I2C que l'écran, une carte SD qui archive les mesures sur le bus SPI, et un moniteur série qui reçoit le tout. Vous construirez cette station bribe par bribe, et vous la retrouverez entière dans l'exercice pratique du chapitre. Une seule règle avant de commencer : testez chaque bus isolément avant de les assembler. Un bus I2C mal câblé qui refuse de démarrer se diagnostique en trente secondes avec un scanner, alors que le même bus couplé à quatre autres composants vous coûtera une heure.



Un système embarqué sans afficheur est un système muet. Il fonctionne peut-être parfaitement, il mesure juste, il commande bien, mais l'utilisateur n'en sait rien : ni l'état du programme, ni la valeur mesurée, ni le fait qu'une panne vient de se produire. Ajouter un écran transforme immédiatement la perception du projet : on passe d'une boîte noire à un appareil avec lequel on dialogue. C'est la raison pour laquelle l'affichage figure parmi les premières fonctions des objets que l'on rencontre au quotidien, du thermostat mural à l'étal de caisse, en passant par le compteur de kilomètres. Pour apprendre, l'afficheur joue un second rôle, tout aussi important : il rend vos programmes observables sans ordinateur. Vous pouvez débrancher le câble USB, alimenter la carte en pile, emporter votre montage et vérifier qu'il se comporte comme prévu. Cette autonomie est un véritable changement de posture.

Le deuxième motif qui pousse à ajouter un écran est temporaire mais décisif pendant l'apprentissage : remplacer le moniteur série. Le moniteur série reste votre meilleur allié, mais il exige un ordinateur relié, un logiciel ouvert et une fenêtre visible. Or de nombreux défauts n'apparaissent qu'une fois la carte autonome, précisément au moment où le moniteur n'est plus là. Un afficheur embarqué devient alors le journal de bord du système : il affiche les valeurs en continu, les compteurs d'exécution, les messages d'erreur et les étapes du démarrage. Le réflexe à acquérir est simple : affichez d'abord sur l'écran ce que vous cherchez à comprendre, puis, si le détail vous manque, basculez sur le port série pour voir les valeurs brutes à haute fréquence. Les deux se complètent au lieu de se concurrencer.

Passons au second thème du chapitre, les bus de communication. Le problème qu'ils résolvent est arithmétique et très simple à énoncer. Un microcontrôleur comme l'Arduino Uno dispose d'environ vingt broches utilisables, et certaines sont réservées à des fonctions spécifiques. Un écran LCD en mode parallèle en consomme déjà six. Un capteur numérique en demande quatre. Une carte mémoire en réclame quatre autres. Si chaque composant récluait son propre lot de fils, vous atteindriez la limite de la carte en branchant trois périphériques, et vous feriez face à un faisceau de câbles ingérable. Les bus résolvent ce problème en partageant un même jeu de fils entre plusieurs composants, à la manière d'une route unique desservant plusieurs maisons. Chaque composant reçoit une identité, un message lui est adressé, et tous les autres font semblant de ne rien entendre.

Trois grandes familles de bus structurent l'électronique amateur et industrielle, et chacune possède son territoire. Le bus I2C, prononcé i²c et littéralement inter-integrated circuit, utilise deux fils d'information, un pour l'horloge et un pour les données, et fait cohabiter une dizaine d'appareils grâce à un système d'adresses. Il est simple, économe en broches et suffisant pour la majorité des capteurs, des écrans, des horloges temps réel et des expandeurs d'entrées-sorties. Le bus SPI, pour serial peripheral interface, utilise quatre fils et va beaucoup plus vite, mais il faut une ligne de sélection distincte pour chaque appareil supplémentaire ; il est donc réservé aux échanges volumineux ou très rapides, comme une carte mémoire ou un écran graphique. Le port série asynchrone UART, enfin, ne relie que deux appareils, sans horloge partagée, et reste le moyen le plus universel de discuter avec un module externe ou avec l'ordinateur.

Voici, sous forme de repères rapides, ce que chaque solution apporte concrètement. Ces chiffres ne sont pas à apprendre par cœur, ils servent à orienter un choix de conception.

- I2C : deux fils de signal, adresses sur sept bits, fréquence courante de 100 kHz ou 400 kHz, idéal pour de nombreux capteurs lents.
- SPI : quatre fils de signal par appareil sélectionné, fréquences de plusieurs mégahertzs, échanges en pleine duplex, idéal pour la mémoire et les écrans.
- UART : deux fils croisés plus une masse commune, pas d'horloge partagée, vitesse convenue entre les deux parties, idéal pour le débogage et les modules sans fil.
- Bus parallèle d'écran : six à huit fils pour un seul appareil, historiquement répandu, aujourd'hui remplacé au profit de l'I2C dans les projets d'apprentissage.

Les sites officiels des fabricants, par exemple www.arduino.cc pour la documentation des bibliothèques et www.espressif.com pour la documentation de l'ESP32, décrivent chacun de ces protocoles avec des diagrammes de temporisation que vous pourrez consulter plus tard. Inutile de les lire maintenant : la pratique que vous allez faire vous donnera d'abord l'intuition, la théorie détaillée viendra se poser dessus beaucoup plus facilement.
$lesson$),
  ('ard-c3-p2', 'ard-c3', 2, $lesson$L'écran LCD 16x2 en mode parallèle$lesson$, $lesson$
L'écran que vous allez utiliser est un module LCD 16x2, c'est-à-dire un afficheur à cristaux liquides capable d'afficher seize caractères sur deux lignes. À l'intérieur, un contrôleur de type HD44780, devenu un standard de fait, prend en charge l'essentiel du travail : il contient une mémoire de caractères, un générateur qui transforme chaque code en motif de pixels, les circuits de gestion du rétroéclairage et les registres de commande. Vous n'écrivez jamais pixels par pixels. Vous envoyez des octets, et le contrôleur s'occupe du reste. Chaque caractère s'affiche sur une grille de cinq colonnes sur huit lignes, dont six lignes sont visibles, ce qui donne ce rendu légèrement anguleux si caractéristique des afficheurs industriels. Le contrôleur possède en mémoire une table complète de caractères romains, des flèches, les symboles japonais Kana, et réserve huit emplacements que vous pouvez redéfinir vous-même.

Le branchement d'un écran en mode parallèle comporte douze pistes, certaines absolument nécessaires, d'autres réglables. Les deux premières sont l'alimentation : la broche de masse et la broche de cinq volts. La troisième, souvent appelée V0 ou Vo, règle le contraste. Elle se connecte au curseur d'un potentiomètre de dix kiloohms, lui-même pris entre l'alimentation et la masse : c'est l'un des réglages les plus souvent oubliés, et pourtant un potentiomètre mal positionné donne un écran totalement vide alors que tout fonctionne. Viennent ensuite les commandes : RS distingue une donnée d'une commande, RW indique s'il s'agit d'une lecture ou d'une écriture, et E reçoit l'impulsion de validation. En pratique, RW est presque toujours relié à la masse, car on n'a que rarement besoin de lire ce que l'écran contient.

Les huit broches de données D0 à D7 transportent le contenu. Dans le mode historique, on les utilise toutes ; dans le mode courant, on ne se sert que des quatre hautes, ce qui fait passer le nombre de fils de commande de six à deux. Les deux dernières pistes sont le rétroéclairage : une anode et une cathode, entre lesquelles on place en série une résistance de deux cent vingt ohms pour limiter le courant. Voici la table complète des connexions pour un Arduino Uno.

| Broche de l'écran | Rôle | Connexion sur l'Uno |
| --- | --- | --- |
| VSS | masse | GND |
| VDD | alimentation | 5 V |
| V0 | contraste | curseur du potentiomètre 10 k |
| RS | sélection donnée ou commande | broche 12 |
| RW | lecture ou écriture | GND |
| E | impulsion de validation | broche 11 |
| D4 à D7 | données (mode 4 bits) | broches 5, 4, 3 et 2 |
| A et K | rétroéclairage | 5 V et GND via 220 ohms |

La bibliothèque LiquidCrystal livrée avec l'environnement Arduino prend en charge ce protocole. Vous l'incluez, vous déclarez un objet en lui indiquant l'ordre des broches, et vous disposez de méthodes très lisibles. L'exemple suivant affiche deux phrases puis les remplace après quatre secondes.

```cpp
#include <LiquidCrystal.h>

LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

void setup() {
  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("Bonjour !");
  lcd.setCursor(0, 1);
  lcd.print("Carte prete");
  delay(4000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Etape 2");
}

void loop() {
}
```

Le mot-clé begin reçoit le nombre de colonnes puis le nombre de lignes et prépare l'afficheur dans le bon mode. Le curseur s'exprime en colonnes de zéro à quinze, puis en lignes, zéro pour la ligne du haut et un pour celle du bas. L'instruction clear efface tout et ramène le curseur à la position zéro, ce qui explique pourquoi un appel clear suivi d'un setCursor redondant ne fait aucun mal mais reste inutile. Notez enfin que rien n'est affiché avant que vous n'écriviez quelque chose : l'alimentation allume le rétroéclairage, elle ne remplit pas l'écran.

Il existe une variante de ce branchement que l'on rencontre sur presque tous les kits vendus à distance : le mode 8 bits. Il utilise l'intégralité des broches D0 à D7 et ajoute deux fils de plus. Son intérêt historique tenait à la simplicité du logiciel, à une époque où la mémoire du microcontrôleur se comptait en octets. Aujourd'hui, la mémoire ne pose plus la question et le gain de deux broches est bien réel, si bien que le mode 4 bits est devenu la norme de fait. La bibliothèque s'en occupe elle-même : quand vous appelez begin avec six paramètres, elle configure automatiquement le transfert par nibbles.

Le passage en mode 4 bits mérite d'être compris plutôt que subi, car il illustre une idée que vous retrouverez partout dans ce chapitre : économiser des fils se paie toujours par un protocole un peu plus riche. Au lieu d'envoyer un octet complet en une fois, la bibliothèque découpe l'octet en deux moitiés de quatre bits, envoie la première, pulse la ligne de validation, envoie la seconde, puis pulse à nouveau. Deux impulsions au lieu d'une, mais deux fils de sauvés sur la carte. Le contrôleur HD44780 sait faire cela de naissance : il existe même une commande pour lui dire qu'il va désormais travailler en quatre bits.

```cpp
// Même montage, mais on déclare explicitement le mode 4 bits.
// Les quatre derniers paramètres sont D4, D5, D6 et D7.
#include <LiquidCrystal.h>

LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

void setup() {
  lcd.begin(16, 2, FOURBIT);
  lcd.print("Mode 4 bits");
}
```

Si votre montage est déjà câblé avec seulement les quatre broches de données, l'exemple ci-dessus fonctionne à l'identique à l'exemple précédent. C'est le même objet, le même appel, le même affichage. La seule différence se situe dans les impulsions envoyées par la bibliothèque, invisibles pour vous. Gardez néanmoins à l'esprit que quatre fils, cela reste quatre fils à raccorder, à suivre sur une nappe et à souder : c'est précisément cette comptabilité qui motive la version I2C de l'écran, à laquelle nous passons maintenant.
$lesson$),
  ('ard-c3-p3', 'ard-c3', 3, $lesson$Le LCD piloté en I2C : deux fils$lesson$, $lesson$
Le module LCD I2C que l'on trouve partout aujourd'hui n'est pas un écran fondamentalement différent. C'est exactement le même afficheur HD44780, avec la même dalle, le même rétroéclairage et les mêmes seize caractères sur deux lignes. Ce qui change se situe entre l'écran et votre carte : une petite carte de circuit imprimé soudée au dos, un expandeur d'entrées-sorties de type PCF8574, qui reçoit des octets par le bus I2C et les redistribue sur les huit pistes de l'afficheur. L'expandeur joue les interprètes. Votre carte lui dit, sur deux fils, l'équivalent de mets la broche RS à un niveau bas et envoie le mot 0x32, et l'expandeur se charge de produire physiquement les tensions sur les pistes correspondantes. Le câblage se réduit alors à quatre fils au total : masse, alimentation, horloge et données.

Le point délicat de cette architecture tient à l'adresse. Sur le bus I2C, chaque appareil possède un numéro, et ce numéro doit être unique tant que les appareils partagent le même bus. Les expandeurs PCF8574 proposent seize adresses possibles, obtenues en reliant ou non à la masse une famille de six broches de sélection présentes sur la puce. Sur les modules couramment vendus, ces broches sont soudées par défaut, si bien que deux adresses reviennent sans arrêt : 0x27 pour la variante PCF8574 classique et 0x3F pour la variante PCF8574A. Il arrive qu'un fournisseur propose 0x38 ou 0x20. Devant un écran qui n'affiche rien, la première question à se poser n'est donc pas quoi écrit au logiciel, mais quelle adresse l'appareil détient réellement, et la réponse s'obtient en balayant le bus, ce que nous verrons précisément dans la section consacrée au scanner.

Le câblage du module tient en un minuscule connecteur à quatre pins. VCC se branche sur l'alimentation, GND sur la masse, SDA sur la ligne de données I2C et SCL sur la ligne d'horloge. Sur un Arduino Uno, SDA correspond à la broche A4 et SCL à la broche A5. Sur un ESP32, les valeurs par défaut sont la broche 21 pour SDA et la broche 22 pour SCL, mais toute autre paire de broches compatibles convient si vous la déclarez au démarrage. Retenez une règle de câblage commune à tout le bus I2C : les deux lignes de signal ont besoin de résistances de rappel vers l'alimentation. Sur les cartes Arduino, ces résistances sont intégrées, sur les montages très extensifs il faut parfois les ajouter, et c'est l'une des causes classiques d'un bus muet.

La bibliothèque LiquidCrystal_I2C reprend exactement la même API que la précédente, ce qui est un vrai plaisir pédagogique : vous changez le câblage, pas vos habitudes de code. L'objet se déclare avec l'adresse, le nombre de colonnes et le nombre de lignes, puis begin initialise le contrôleur, backlight allume le rétroéclairage et les méthodes setCursor, print, clear fonctionnent à l'identique.

```cpp
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

void setup() {
  Wire.begin();
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("LCD sur I2C");
  lcd.setCursor(0, 1);
  lcd.print("Adresse 0x27");
}

void loop() {
}
```

Deux détails de cet exemple méritent votre attention. Le premier est l'appel à Wire.begin : la bibliothèque I2C du contrôleur, contenue dans le fichier Wire.h, doit être démarrée avant tout échange, sinon les appels suivants ne produisent rien. La plupart des bibliothèques d'afficheur le font en interne, mais l'expliciter évite des heures de débogage lorsque vous composez votre propre code. Le second détail est la ligne lcd.init, qui envoie une séquence précise de commandes pour réveiller le contrôleur, le passer en mode quatre bits, régler le nombre de lignes et effacer l'écran. Sans cette séquence, l'écran reste vide même si le câblage et l'adresse sont corrects, ce qui le rend redoutablement difficile à diagnostiquer pour un débutant.

La comparaison entre les deux approches se résume à un arbitrage. Le mode parallèle consomme six broches mais n'a besoin d'aucune bibliothèque extérieure et fonctionne sur n'importe quelle carte, y compris les plus anciennes. Le mode I2C consomme deux broches, ajoute une dépendance à une bibliothèque installée depuis le gestionnaire de bibliothèques, et impose de connaître l'adresse. Pour un projet qui doit garder ses doigts libres pour des capteurs, des actionneurs et des entrées, l'I2C s'impose. Pour un montage éducatif minimal, le parallèle reste excellent car il rend visibles les signaux sur un oscilloscope. Dans la suite de cette leçon, nous adoptons l'I2C comme référence, car il nous sert aussi à introduire le bus dans sa généralité.

Un dernier conseil pratique, tiré de l'expérience de terrain, concerne le contraste. Sur le dos du module I2C, un petit potentiomètre molette, souvent bleu, règle la tension de la broche V0. Si l'écran s'allume avec des carrés pleins sur toute la ligne, tournez doucement ce potentiomètre dans un sens puis dans l'autre jusqu'à ce que les caractères deviennent nets. Si rien ne change, c'est que l'alimentation ou l'horloge manque, et il faut revenir au câblage. Ce réglage n'apparaît dans aucun programme, il ne figure sur aucun schéma de logiciel, et il cause pourtant la moitié des premiers messages d'entraide sur les forums. Vous venez d'apprendre le plus important : dans un problème d'afficheur, on vérifie d'abord l'alimentation et le contraste, ensuite l'adresse, enfin le logiciel.

Vous savez maintenant brancher un écran et l'allumer. Il reste à en faire un véritable afficheur : y écrire des informations qui changent, les placer au bon endroit, effacer proprement entre deux mises à jour et ajouter quelques pictogrammes qui rendent la lecture immédiate. Cette première moitié de leçon développe ces réflexes, avant que la seconde moitié ne vous emmène à l'intérieur du bus I2C lui-même. La progression est volontaire : on apprend d'abord à se servir d'un périphérique, puis on comprend comment il reçoit vos ordres. Cette démarche, utilisée à l'envers, c'est-à-dire la théorie puis la pratique, fonctionne nettement moins bien dans l'embarqué, parce que rien de ce qui se passe entre la carte et le composant n'est visible sans instrument de mesure.
$lesson$),
  ('ard-c3-p4', 'ard-c3', 4, $lesson$Afficher comme un pro : texte, curseur et effacement$lesson$, $lesson$
L'instruction la plus utilisée reste l'affichage d'une valeur, et sa forme la plus robuste consiste à réécrire la même zone de l'écran à chaque mise à jour plutôt que d'effacer tout à chaque fois. L'effacement intégral produit un clignotement perceptible, car l'écran se vide puis se remplit à une vitesse que l'œil suit sans difficulté. La méthode professionnelle consiste à placer le curseur à une position fixe, à réécrire la chaîne complète sur une longueur connue, puis à terminer par des espaces qui balayent les caractères résiduels lorsque la nouvelle valeur est plus courte que l'ancienne. Si la température passait de 100.0 à 99.5, l'ancien zéro resterait visible sans cette manœuvre. Un espace de trop ne se voit jamais, un caractère orphelin se remarque aussitôt.

```cpp
#include <LiquidCrystal.h>

LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

float valeur = 123.45;

void setup() {
  lcd.begin(16, 2);
}

void loop() {
  lcd.setCursor(0, 0);
  lcd.print("Valeur : ");
  lcd.print(valeur);
  lcd.print("     ");
  valeur -= 10.0;
  delay(500);
}
```

Les autres méthodes de la bibliothèque méritent d'être passées en revue une fois pour toutes, car leur nom décrit exactement leur rôle. setCursor reçoit la colonne puis la ligne, toutes deux numérotées à partir de zéro, et déplace le curseur sans toucher au contenu. clear efface l'intégralité de l'écran et ramène le curseur en haut à gauche, ce qui la distingue d'un simple retour en début de ligne. home fait exactement ce dernier déplacement sans effacer. scrollDisplayLeft et scrollDisplayRight décalent tout le contenu d'une colonne, ce qui permet d'afficher des phrases plus longues que seize caractères en les faisant défiler. display allume l'afficheur et hide le rétail sans couper le rétroéclairage, une distinction utile pour économiser l'énergie sur un objet alimenté par pile. Enfin, autorscroll fait défiler automatiquement la ligne en cours, mais son rythme est difficile à maîtriser, si bien qu'un défilement manuel piloté par millis reste préférable dans un programme qui doit rester réactif.

La gestion du temps dans un programme d'affichage pose une question que vous avez déjà rencontrée : faut-il utiliser delay. La réponse est non dès que le programme doit faire autre chose en parallèle. Un délai bloquant pendant quatre secondes empêche le microcontrôleur de lire un capteur, de surveiller un bouton ou de répondre sur le port série. La bonne pratique consiste à mémoriser la date du dernier rafraîchissement avec millis, puis à comparer à chaque passage de la boucle. L'affichage se produit lorsqu'un intervalle est écoulé, et pendant l'intervalle la boucle reste libre. Ce motif, que le chapitre sur les automates traitera en profondeur, s'applique immédiatement ici et transforme un exemple pédagogique en code exploitable.

Un point sur la conversion des nombres s'impose également. La fonction print accepte un entier, un décimal et un texte, mais elle n'offre aucun contrôle sur le nombre de décimales affichées. Un flottant tel que 23,499999 s'affiche avec autant de chiffres que la représentation interne en produit, ce qui déborde instantanément d'une ligne de seize caractères. Les bibliothèques Arduino fournissent à cet effet la méthode print avec un second paramètre numérique, qui indique le nombre de décimales à conserver. Une température se lit très bien avec une décimale, une pression avec zéro, et la largeur de l'affichage reste maîtrisée. Vérifiez toujours que la ligne reste dans la largeur utile : au-delà de la seizième colonne, les caractères sont simplement perdus, sans message d'erreur et sans avertissement.

La deuxième ligne de l'écran mérite une attention particulière dans les interfaces simples. Elle accueille traditionnellement l'information secondaire, celle qui change rarement ou qui qualifie la première ligne : l'unité, l'état du système, le nom de la grandeur mesurée. Un bon réflexe d'ergonomie consiste à écrire cette ligne une seule fois au démarrage, puis à ne plus la toucher, en se contentant de rafraîchir la première. On réduit ainsi de moitié les écritures sur le bus, donc le temps passé hors boucle principale, et l'écran cesse de trembloter. Quand la seconde ligne doit elle-même varier, remplacez le contenu de manière atomique, c'est-à-dire en réécrivant toute la ligne d'un bloc avec remplissage d'espaces plutôt qu'en écrivant seulement les nouveaux caractères.

L'ordre d'écriture dans la mémoire de l'afficheur suit une contrainte physique qu'il est utile de connaître. L'écran possède deux zones correspondant aux deux lignes, et la mémoire du contrôleur réserve un emplacement de départ pour chacune d'elles. Les appels à setCursor expriment un index dans cette mémoire, pas une position géométrique sur la dalle. Pour une ligne de seize caractères, la correspondance est directe et vous n'aurez jamais à y penser. Si vous utilisiez un afficheur de vingt caractères ou une dalle de quatre lignes, il faudrait vérifier le mappage, car certains modèles physiques relient les lignes dans un ordre inattendu. Cette subtilité n'apparaît pas dans les tutoriels et constitue une des causes rares d'un affichage dont la troisième ligne s'affiche à la mauvaise place.
$lesson$),
  ('ard-c3-p5', 'ard-c3', 5, $lesson$Créer des caractères personnalisés$lesson$, $lesson$
Tous les afficheurs de cette famille partagent une table de caractères gravée en mémoire, mais ils offrent aussi huit emplacements modifiables par l'utilisateur. C'est un avantage sous-estimé : il suffit d'y décrire un motif pour disposer d'une flèche, d'un thermomètre, d'une cloche, d'un niveau de batterie ou d'un cœur, et d'obtenir une interface qui se lit sans traduction. Le motif se définit pixel par pixel sur une grille de cinq colonnes par huit lignes, dont la dernière ligne sert d'espace de séparation entre deux glyphes voisins. Chaque ligne est codée sur cinq bits, que l'on écrit commodément en binaire avec le préfixe 0b, et l'ensemble des huit lignes forme un tableau d'octets.

```cpp
#include <LiquidCrystal.h>

LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

byte coeur[8] = {
  0b00000,
  0b01010,
  0b11111,
  0b11111,
  0b01110,
  0b00100,
  0b00000,
  0b00000
};

byte fleche[8] = {
  0b00100,
  0b00110,
  0b11111,
  0b01110,
  0b00100,
  0b00100,
  0b00000,
  0b00000
};

void setup() {
  lcd.begin(16, 2);
  lcd.createChar(0, coeur);
  lcd.createChar(1, fleche);
  lcd.setCursor(0, 0);
  lcd.write(byte(0));
  lcd.print(" Tout va bien");
}
```

La fonction createChar reçoit l'identifiant, de zéro à sept, et l'adresse du tableau. Le motif est ensuite copié dans la mémoire vive du contrôleur, où il reste jusqu'à la prochaine réinitialisation électrique. Pour l'afficher, on utilise write et non print : write transmet un code brut, alors que print s'attend à recevoir du texte et interpréterait le nombre comme un caractère de la table standard. Comme les codes de caractères personnalisés se situent dans une plage que le compilateur interprète parfois comme un caractère spécial, il est plus sûr de convertir explicitement l'identifiant en octet avant de l'appeler. Cette différence entre print et write est l'une des plus fréquentes entre les débutants qui voient s'afficher un signe étrange à la place de leur jolie icône.

Dessiner un motif demande un peu de méthode. On commence par tracer la grille sur du papier, on coche les pixels allumés, puis on lit chaque ligne de gauche à droite en convertissant la suite de bits. Un cœur se dessine aisément parce qu'il est symétrique ; une flèche directionnelle gagne à être centrée sur les cinq colonnes ; une jauge horizontale se construit en remplissant progressivement les colonnes de gauche. L'astuce qui fait gagner du temps consiste à réutiliser un même motif pour plusieurs valeurs : une jauge de quatre états peut être simulée par quatre glyphes distincts numérotés de zéro à trois, ou par un seul glyph complété par des blocs pleins. Essayez d'abord avec le cœur de l'exemple, observez-le à l'écran, puis modifiez un bit et rechargez le programme : la boucle d'itération entre l'idée et l'écran est si courte qu'elle rend l'exercice presque ludique.

Un avertissement pratique concerne l'endroit où déclarer ces tableaux. Placés en dehors de toute fonction, ils sont initialisés au démarrage et occupent la mémoire de données disponible. Sur une carte à faible mémoire, une dizaine de motifs commence à se faire sentir, mais sur les cartes modernes vous disposez d'une marge confortable. Si vous créez plusieurs afficheurs, souvenez-vous qu'ils partagent la même mémoire de caractères physiques : créer un motif pour le second écrase le motif correspondant du premier, à moins de gérer soi-même les huit emplacements. Enfin, la fonction createChar doit être rappelée après chaque réinitialisation matérielle de l'écran, car init l'envoie, la mémoire vive du contrôleur repart à zéro et vos icônes disparaissent au profit des caractères d'origine.
$lesson$),
  ('ard-c3-p6', 'ard-c3', 6, $lesson$Anatomie du bus I2C$lesson$, $lesson$
Le bus I2C repose sur une idée à la fois élégante et très économique : deux fils suffisent pour faire converser une dizaine de circuits. Le premier porte l'horloge, étiqueté SCL pour serial clock, et le second porte les données, étiqueté SDA pour serial data. Aucun de ces fils n'est dédié à un composant particulier : ils sont connectés en parallèle sur tous les appareils présents. La difficulté que cette économie crée se règle par deux mécanismes complémentaires, l'adressage et la ligne ouverte. Le premier permet d'adresser un destinataire précis. Le second empêche deux circuits de se disputer le niveau électrique du même fil.

```text
        +5V
         |
        [4k7]   [4k7]          tensions de rappel
         |        |
 SDA  ---+--------+----------------+---------+---------
         |        |                |         |
       +---+    +---+            +---+     +---+
       |   |    |   |            |   |     |   |
       |27 |    |76 |            |3C |     |50 |
       |   |    |   |            |   |     |   |
       +---+    +---+            +---+     +---+
         |        |                |         |
 SCL  ---+--------+----------------+---------+---------
         |        |                |         |
       maitre   capteur          ecran     horloge
       (Uno)   (BME280)        (LCD I2C)  (DS3231)

 Adresses hexa : 0x27  0x76  0x3C  0x50
```

La ligne ouverte, appelée open drain en anglais, est le concept à assimiler si vous voulez comprendre les pannes de bus. Aucun appareil ne peut pousser activement un fil vers le haut : il peut seulement le tirer vers le bas ou le relâcher. Les résistances de rappel, les deux résistances vues en haut du schéma, ramènent le fil vers l'alimentation dès qu'aucun circuit ne l'appuie. Quand deux équipements veulent émettre en même temps, l'un tire vers le bas et l'autre relâche, sans jamais court-circuiter. C'est ce qui rend possibles les bus partagés et c'est aussi pourquoi un bus dont les résistances de rappel manquent reste bloqué à un niveau bas indéfiniment. Sur les cartes Arduino, ces résistances sont présentes sur la carte mère, mais sur un module extérieur ou un montage sur plaque à perfouser, il faut parfois les prévoir soi-même.

Les adresses se codent généralement sur sept bits, ce qui autorise cent vingt-huit combinaisons, dont une partie est réservée. En pratique, une centaine d'adresses est utilisable, ce qui semble beaucoup pour un hobbyiste mais se révèle vite insuffisant dans l'industrie, où deux composants identiques sur le même bus deviennent alors un problème de câblage et non de logiciel. La convention d'écriture mélange deux notations : en hexadécimal avec le préfixe 0x, par exemple 0x27, ou en décimal avec le suffixe décimal, par exemple 39 pour le même numéro. Les bibliothèques acceptent l'une comme l'autre. Un conseil : adoptez l'hexadécimal, car les tableaux techniques des fabricants sont tous exprimés ainsi, et convertir mentalement à chaque lecture est une source d'erreurs inutiles.

Le déroulement d'une transmission est toujours le même, et il vaut la peine d'être mémorisé sous forme de séquence. L'émetteur émet d'abord une condition de départ, caractérisée par la ligne de données qui tombe pendant que l'horloge reste haute. Il adresse ensuite le destinataire avec son numéro suivi d'un bit qui indique s'il veut lire ou écrire. L'esclave reconnu répond par un acquittement, appelé ACK, signalé par un niveau bas sur la donnée pendant un coup d'horloge. Les données suivantes voyagent octet par octet, chaque octet étant confirmé. Enfin, l'émetteur émet une condition d'arrêt, la remontée de la donnée pendant l'horloge haute. Toute une conversation tient dans cette trame, et les bibliothèques la gèrent intégralement : vous ne manipulez ces signaux à la main que lorsque vous cherchez à comprendre pourquoi rien ne fonctionne.

| Notion | Signification | Conséquence pratique |
| --- | --- | --- |
| SCL | ligne d'horloge partagée | une seule source d'horloge, le maître |
| SDA | ligne de données partagée | niveaux ouverts, rappel obligatoire |
| 0x27 | adresse d'un expandeur PCF8574 | l'écran LCD I2C répond souvent ici |
| 0x76 | adresse courante d'un BME280 | à confirmer par le scanner |
| ACK | accusé de réception | un octet envoyé ne prouve rien sans lui |

La fréquence du bus, appelée vitesse standard ou rapide selon les modèles, se situe le plus souvent à 100 kHz ou 400 kHz. Pour des capteurs et des écrans, ces débits sont largement suffisants : écrire seize caractères représente une vingtaine d'octets, donc quelques dizaines de microsecondes sur le fil. En revanche, la lecture d'un capteur à mesure rapide, l'échange avec un accéléromètre haute fréquence ou le pilotage d'une matrice de diodes commençent à saturer un bus à 100 kHz. Il est alors possible d'augmenter la vitesse, à condition que tous les appareils connectés la supportent. En cas de doute, restez à la vitesse standard : la fiabilité d'un bus vaut mieux que sa célérité.
$lesson$),
  ('ard-c3-p7', 'ard-c3', 7, $lesson$Premiers échanges avec la bibliothèque Wire$lesson$, $lesson$
La bibliothèque Wire embarquée dans l'environnement Arduino résume toute cette mécanique en six ou sept appels. Elle prend en charge les conditions de départ et d'arrêt, les accusés de réception, la gestion du maître et même le rôle d'esclave si votre carte doit elle-même recevoir des ordres. Pour écrire chez un appareil, vous remplissez un tampon d'octets avec beginTransmission suivi de l'adresse, vous ajoutez les octets avec write, puis vous clôturez avec endTransmission qui renvoie zéro si l'appareil a répondu. Pour lire, vous demandez un nombre d'octets avec requestFrom, puis vous les récupérez un par un avec available et read. C'est l'intégralité du vocabulaire nécessaire.

```cpp
#include <Wire.h>

void setup() {
  Wire.begin();
  Serial.begin(115200);
  delay(1000);

  Wire.beginTransmission(0x27);
  Wire.write(0x00);
  byte etat = Wire.endTransmission();
  Serial.print("Reponse du peripherique : ");
  Serial.println(etat);
}

void loop() {
}
```

Le code de retour d'endTransmission mérite que l'on s'y arrête, car il contient la moitié de l'information diagnostique. Le zéro signifie que l'appareil à cette adresse a acquitté l'octet d'adresse. Un code de deux indique qu'aucun accusé de réception n'a été reçu, ce qui correspond très souvent à une adresse incorrecte ou à un appareil absent. Un code de trois signale que le bus a vu apparaître un bit d'accusé invalide, souvent dû à une ligne parasite. Un code de quatre traduit une condition de start transmise illégalement, typiquement quand une autre bibliothèque tient le bus pendant votre tentative. Un code de cinq indique que le bus est resté bloqué jusqu'à l'expiration du délai, ce qui ramène toujours au câblage et aux résistances de rappel. Lire ce chiffre plutôt que de supposer le succès fait gagner un temps considérable.

L'ordre des appels comporte un piège classique : le tampon se vide à chaque clôture de transmission. Si vous appelez write plusieurs fois consécutivement sans endTransmission, tous les octets voyagent dans la même conversation, ce qui est souvent ce que vous voulez. En revanche, si vous intercalez une autre opération entre deux segments, le premier tampon est perdu. Une autre subtilité concerne la taille du tampon : la version Arduino classique accepte trente-deux octets par transmission, ce qui suffit largement pour un registre de capteur mais pas pour transférer une image ou un paquet volumineux. Lorsque vous manipulez des données plus longues, la découpez en plusieurs écritures adressées, ou vérifiez que la variante de la bibliothèque prévoit un tampon plus grand.

Pour lire, requestFrom demande l'adresse puis le nombre d'octets attendus. Les octets arrivent dans le tampon de réception et vous les consommez avec read, après avoir vérifié available. Cette vérification n'est pas un formalisme : si l'appareil a répondu moins d'octets que demandés, appeler read sans contrôle renvoie des valeurs aberrantes qui se propagent ensuite dans vos calculs. Une lecture robuste vérifie toujours le nombre réellement reçu avant d'utiliser les données. C'est exactement le réflexe à prendre lorsque vous décrypterez un capteur dont les valeurs vous semblent incohérentes : le capteur n'est peut-être pas en cause, c'est peut-être le nombre d'octets lus qui diffère de celui que vous supposiez.

Un dernier mot sur la cohabitation des bibliothèques. Une même carte peut piloter simultanément un écran LiquidCrystal_I2C, un capteur par une bibliothèque constructeur et une horloge temps réel, parce qu'ils partagent le même bus sans se gêner. Chacune appelle en interne les fonctions de Wire, ce qui suppose qu'aucune ne détient le bus indéfiniment. La plupart des bibliothèques bien écrites libèrent la transmission après chaque opération, mais certaines, anciennes ou mal conçues, laissent le bus verrouillé et bloquent toutes les suivantes. Si un composant cesse de répondre dès que vous en ajoutez un autre, testez-le isolément, puis testez-le à deux : le problème apparaissant seulement à l'assemblage désigne presque toujours une incompatibilité du logiciel de bibliothèque et non un défaut de câblage.

Vous savez écrire chez un périphérique I2C et vous savez lire sa réponse. Il manque deux étapes décisives : la première consiste à découvrir ce qui est réellement connecté, la seconde à décoder un appareil dont personne n'a publié le mode d'emploi sous forme de fonctions toutes faites. Nous aborderons ensuite le second grand bus de ce chapitre, le SPI, plus rapide et plus mécanique, que vous mettrez en pratique avec une carte mémoire. La progression reste la même qu'auparavant : un outil de diagnostic d'abord, un échange brut ensuite, puis un nouveau protocole présenté avec la même rigueur.
$lesson$),
  ('ard-c3-p8', 'ard-c3', 8, $lesson$Scanner le bus et diagnostiquer$lesson$, $lesson$
Le scanner I2C est l'outil le plus rentable du débutant en électronique communicante. Son principe tient en une ligne : pour chaque adresse de la plage utilisable, on tente une transmission et on observe si un accusé de réception revient. Si oui, un appareil est présent à cet endroit. Si non, l'adresse est libre. Trente lignes de code suffisent, et l'installation d'aucune bibliothèque n'est nécessaire. Le balayage part en général de la broche huit et va jusqu'à cent dix-neuf en décimal, ce qui couvre l'intégralité des adresses sur sept bits réservées aux composants usuels.

```cpp
#include <Wire.h>

void setup() {
  Wire.begin();
  Serial.begin(115200);
  Serial.println("Balayage du bus I2C...");
}

void loop() {
  for (byte adresse = 8; adresse < 120; adresse++) {
    Wire.beginTransmission(adresse);
    byte erreur = Wire.endTransmission();
    if (erreur == 0) {
      Serial.print("Peripherique trouve a 0x");
      if (adresse < 16) Serial.print("0");
      Serial.println(adresse, HEX);
    }
  }
  Serial.println("Balayage termine.");
  delay(5000);
}
```

L'interprétation des résultats suit un tableau simple. Une seule adresse révélée alors que vous avez branché deux appareils signale presque toujours un problème de câblage sur le second, une ligne coupée, deux fils inversés ou une alimentation manquante. Aucune adresse du tout oriente vers les trois coupables classiques : l'alimentation absente sur le module, les lignes SDA et SCL interverties, ou l'absence de tension de rappel sur un montage construit à la main. Enfin, une adresse qui apparaît puis disparaît d'un balayage à l'autre trahit un contact mécanique douteux ou un appareur qui redémarre en boucle, souvent par insuffisance d'alimentation lorsque l'ensemble est alimenté par un port USB faible. Un résultat stable et reproductible est le signe que le bus est sain.

Le balayage a aussi une limite qu'il faut connaître pour ne pas en faire un oracle. Certains appareils ne répondent à une tentative d'écriture pure que pendant une fraction de seconde, d'autres imposent une condition particulière avant d'acquitter, et d'autres encore n'utilisent qu'une partie de leur adresse. Si un appareil ne figure pas au relevé, cela ne prouve pas qu'il est défectueux : cela prouve seulement qu'il n'a pas acquitté l'adresse essayée dans l'instant du test. La vérification définitive consiste alors à écrire un exemple constructeur minimal fourni par le fabricant, qui met généralement l'appareil dans un état où il répond. C'est d'ailleurs la raison pour laquelle les bibliothèques de capteurs commencent presque toutes par une vérification d'identité en lecture au démarrage.

Une fois les adresses connues, il est bon de les écrire dans l'en-tête de votre sketch sous forme de constantes nommées. Un identifiant tel queAdresseEcran vaut de bien mieux que la suite de chiffres éparpillée dans le code, parce qu'il documente l'intention et parce qu'un changement de module ne touche qu'une seule ligne. Vérifiez aussi, dans les rares cas où deux appareils se disputent la même adresse, que la documentation ne prévoit pas une broche de sélection. La plupart des capteurs récents en disposent une : reliée à la masse, elle active telle adresse ; reliée à l'alimentation, elle en active une autre. C'est la solution privilégiée, bien préférable au recours à un multiplexeur.
$lesson$),
  ('ard-c3-p9', 'ard-c3', 9, $lesson$Lire un capteur octet par octet$lesson$, $lesson$
Passons au décodage réel. Supposons que vous deviez interroger un capteur dont la documentation fournit seulement une table de registres, ce qui est la situation la plus courante lorsqu'on utilise un composant industriel plutôt qu'un module grand public. Le protocole se lit alors comme une conversation très simple : on écrit dans un registre l'adresse de la donnée que l'on souhaite, on relance une lecture, on récupère les octets, puis on assemble. L'écriture de l'adresse de registre se fait par une transmission qui contient d'abord le numéro de registre, souvent suivi de la valeur à y inscrire. La lecture, elle, demande un transfert dans l'autre sens.

```cpp
#include <Wire.h>

const byte ADDR = 0x68;

void setup() {
  Wire.begin();
  Serial.begin(115200);
}

void loop() {
  Wire.beginTransmission(ADDR);
  Wire.write(0x00);
  Wire.endTransmission();

  Wire.requestFrom(ADDR, (byte)6);
  if (Wire.available() == 6) {
    int brut = (Wire.read() << 8) | Wire.read();
    Serial.println(brut);
  }
  delay(1000);
}
```

L'assemblage des octets est l'étape où se glissent le plus d'erreurs silencieuses. Quand une valeur est codée sur seize bits, elle arrive toujours en deux octets, d'abord le plus significatif puis le moins significatif dans la quasi-totalité des composants. Le décalage de huit positions sur le premier octet, réuni avec le second par un ou logique, reconstitue la valeur brute. Il faut ensuite appliquer le facteur d'échelle indiqué dans la fiche technique, par exemple un demi-degré par unité brute pour certains thermomètres. Ne sautez jamais cette dernière étape : une valeur brute cohérente mais non convertie se retrouve affichée telle quelle et paraît absurde, ce qui fait perdre un temps considérable avant qu'on ne pense à consulter la fiche technique.

La vérification du nombre d'octets reçus, montrée dans l'exemple, n'est pas décorative. Si l'appareil répond moins d'octets que demandé, la condition échoue et vous évitez d'utiliser des données incomplètes. Dans le cas contraire, vous auriez construit une valeur à partir d'un octet absent, donnant un résultat erroné mais crédible en apparence. Ce genre de défaillance, qui ne produit aucun message d'erreur, est le plus coûteux en temps de débogage. L'habitude de contrôler systématiquement la disponibilité avant chaque lecture est l'un des signes qui distinguent un script d'apprentissage d'un programme fiable.

Certains appareils exigent enfin que l'adresse de registre soit redémarrée avant chaque lecture, tandis que d'autres conservent le curseur interne et permettent des lectures multiples consécutives. C'est la différence entre une condition de redémarrage, émise par le maître sans relâcher le bus, et une simple continuité. Les bibliothèques gèrent cette nuance quand elles existent, mais quand vous écrivez votre propre échange, elle devient visible. Si vous lisez successivement plusieurs registres contigus et que les valeurs semblent décalées d'une position, pensez à ce détail de protocole avant de soupçonner le capteur.
$lesson$),
  ('ard-c3-p10', 'ard-c3', 10, $lesson$Le bus SPI : quatre fils, haute vitesse$lesson$, $lesson$
Le SPI aborde le problème de la communication sous un angle complètement différent. Là où I2C cherche l'économie, SPI cherche la vitesse et la simplicité mécanique. Il ne possède ni adresse, ni accusé de réception, ni condition d'horloge complexe. Il transporte simplement des octets sur un fil de données pendant que le maître tourne une horloge, et il impose une ligne de sélection par appareil esclave. Quatre signaux composent le socle, avec la particularité d'avoir deux lignes de données distinctes, une dans chaque sens, ce qui permet de recevoir et d'émettre simultanément.

```text
   MAITRE (Uno / ESP32)                   ESLAVES
  +---------------------+
  |  MOSI --------------+------------> MOSI  (entree esclave)
  |  MISO <-------------+------------< MISO  (sortie esclave)
  |  SCK  --------------+------------> SCK   (horloge)
  |  SS1  --------------+------------> CS    (carte SD)
  |  SS2  --------------+------------> CS    (ecran TFT)
  +---------------------+

  MOSI : master out, slave in  -> donnees maitre vers esclave
  MISO : master in, slave out  -> donnees esclave vers maitre
  SCK  : horloge generee par le maitre
  CS   : selection, active a l'etat bas
```

La sélection de l'esclave se fait par ligne dédiée, ce qui explique pourquoi le SPI ne s'adapte pas aussi bien que l'I2C à l'ajout d'appareils : chaque nouveau composant réclute une broche supplémentaire sur la carte. En contrepartie, aucune trame d'adressage ne pollue le flux : dès que la ligne de sélection tombe, tout ce qui circule sur les fils concerne l'appareil choisi. Cette mécanique explique les débits élevements atteints, de quelques mégahertzs pour un débutant à plusieurs dizaines de mégahertzs sur des montages soignés, très au-delà de ce qu'autorise un bus partagé avec ses résistances de rappel et ses accusés de réception.

| Signal | Direction | Rôle | Nombre par esclave |
| --- | --- | --- | --- |
| MOSI | maître vers esclave | données envoyées | un fil partagé |
| MISO | esclave vers maître | données reçues | un fil partagé |
| SCK | maître vers esclave | horloge | un fil partagé |
| CS | maître vers esclave | sélection de l'esclave | un fil dédié |

L'écran et la carte SD illustrent parfaitement cette architecture. Un écran graphique reçoit des milliers d'octets par image : le SPI lui envoie la totalité sans protocole superflu. Une carte mémoire doit écrire des secteurs entiers de données, souvent cinq cent douze octets à la fois, et supporter des débits qui rendraient l'I2C pénible. L'ordre de grandeur est facile à retenir : écrire une ligne de seize caractères sur un écran textuel relève de l'I2C, écrire une image complète ou archiver des milliers de mesures relève du SPI. Entre les deux, la frontière se place au volume d'octets et à la fréquence d'échange, pas à la sophistication du composant.

Le SPI présente également une particularité de synchronisation : il n'existe pas d'horloge partagée négociée, le maître génère l'horloge et l'esclave doit s'y conformer. Si l'esclave est trop lent, le résultat est corrompu sans avertissement. C'est pourquoi les bibliothèques exposent souvent un réglage de fréquence, et pourquoi il faut parfois ralentir l'horloge pour que la carte mémoire soit réceptive. La deuxième particularité tient à l'absence totale d'accusé de réception : rien ne vous dit qu'un octet est bien arrivé. Les cartes mémoire compensent ce manque en retournant des octets d'état que l'on relit ensuite, et c'est à ce prix que la fiabilité est obtenue.
$lesson$),
  ('ard-c3-p11', 'ard-c3', 11, $lesson$Une carte SD comme mémoire de masse$lesson$, $lesson$
Le passage à une carte SD se fait en deux temps, dont le premier est souvent oublié : le formatage. Une carte neuve livrée avec une système de fichiers incompatible, ou une carte réutilisée depuis un appareil photo, échouera à s'initialiser sans que la cause apparaisse dans le code. Utilisez un formatage en système de fichiers FAT32 avec une taille d'allocation par défaut, puis vérifiez l'opération en reliant la carte à l'ordinateur. Une carte qui se monte correctement sur l'ordinateur mais échoue dans la carte Arduino désigne presque toujours une incompatibilité de format ou un courant insuffisant au démarrage.

```cpp
#include <SPI.h>
#include <SD.h>

const int CS = 10;

void setup() {
  Serial.begin(115200);
  if (!SD.begin(CS)) {
    Serial.println("Carte SD absente ou non formatee");
    return;
  }
  File fichier = SD.open("mesures.csv", FILE_WRITE);
  if (fichier) {
    fichier.println("horodatage,temperature");
    fichier.println("1000,23.5");
    fichier.close();
  }
}

void loop() {
}
```

L'initialisation prend un argument unique, la broche de sélection, et renvoie un booléen qu'il faut impérativement tester. Un test omis conduit à écrire dans le vide pendant des heures avant de découvrir qu'aucun fichier n'a été créé. L'écriture d'un fichier suit elle aussi un schéma rigoureux : ouverture, écriture, fermeture. La fermeture est l'étape à laquelle les données sont réellement transférées vers la carte, et l'omettre provoque la perte des dernières lignes. Elle coûte quelques dizaines de millisecondes, ce qui n'a aucune importance pour un enregistrement périodique, mais interdit de la placer dans une boucle serrée.

Les deux erreurs de conception les plus fréquentes sur ce type de montage tiennent au partage du bus SPI et à la consommation. Le SPI, on l'a vu, utilise un fil de sélection par appareil : si vous ajoutez un écran à la carte mémoire, il faudra deux broches distinctes, une pour chacun, et veiller à ne sélectionner qu'un seul à la fois. Sinon, deux esclaves émettent simultanément sur la ligne MISO et se neutralisent. Du côté de l'alimentation, une carte SD peut puiser plusieurs dizaines de milliampères lors des écritures, avec des pics rapides. Alimentée par une source faible, elle provoque une chute de tension qui réinitialise la carte entière au moment précis de l'écriture. Un condensateur de cent microfarads placé aux bornes de la carte corrige ce défaut en tamponnant les pics.

Un mot sur la manière d'organiser les données, parce qu'il conditionne tout usage ultérieur. Le format texte séparé par des virgules est la valeur sûre : il s'ouvre dans un tableur, il se traite avec n'importe quel langage, il reste lisible en cas de panne. Conservez un en-tête en première ligne, écrivez les valeurs avec un nombre fixe de décimales, et horodatez chaque mesure, soit avec millis pour un intervalle relatif, soit avec une horloge temps réel pour un calendrier réel. Enfin, écrivez par blocs plutôt qu'octet par octet : ouvrir, écrire cent lignes puis fermer est infiniment plus rapide qu'un aller-retour par ligne, et réduit d'autant le temps pendant lequel votre boucle principale est occupée.

Il reste une pièce essentielle à ce chapitre : le port série. On pourrait le considérer comme un simple outil de débogage, et il l'est en effet, mais il constitue aussi un protocole de communication à part entière, celui que vos cartes utiliseront pour parler à un module Bluetooth, à un récepteur GPS, à un contrôleur de moteurs ou à un second microcontrôleur. Nous l'étudierons sous ses deux visages, puis nous comparerons l'ensemble des bus appris dans ce chapitre pour éclairer vos choix futurs. La leçon se terminera par un exemple guidé qui assemble écran, capteur, carte mémoire et moniteur, avant les sections de synthèse et les erreurs qui vous feront gagner du temps.
$lesson$),
  ('ard-c3-p12', 'ard-c3', 12, $lesson$Le port série UART : la fenêtre sur le programme$lesson$, $lesson$
Le port série asynchrone, universellement appelé UART pour universal asynchronous receiver transmitter, est le plus ancien et le plus simple des protocoles que vous manipulerez. Il ne possède ni adresse ni horloge partagée : deux broches, une pour émettre et une pour recevoir, et une vitesse convenue à l'avance par les deux extrémités. Comme il n'y a pas d'horloge commune, chaque appareil décompte lui-même le temps à l'aide de sa propre horloge interne, ce qui impose que les deux fréquences soient suffisamment proches. Si l'une des deux parties croit devoir communiquer à neuf mille six cents bauds et l'autre à cent quinze mille deux cents, la réception produit des octets corrompus sans le moindre avertissement.

```cpp
void setup() {
  Serial.begin(115200);
  Serial.println("Demarrage du programme");
}

void loop() {
  if (Serial.available()) {
    char c = Serial.read();
    Serial.print("Recu : ");
    Serial.println(c);
  }
}
```

La fonction begin fixe la vitesse en bauds, c'est-à-dire le nombre de symboles transmis par seconde. Pour les échanges avec l'ordinateur, la valeur cent mille deux cents est aujourd'hui la norme pratique : assez rapide pour afficher des volumes importants, assez lente pour rester fiable sur un simple fil de quelques dizaines de centimètres. Entre deux cartes, il suffit que les deux appels à begin reçoivent la même valeur. Pourquoi ce chiffre en particulier ? Parce que l'horloge interne des cartes les plus courantes le produit avec une erreur négligeable, alors que certaines vitesses anciennes, comme neuf mille six cents, deviennent imprécises sur des horloges rapides.

Les deux fonctions qui structurent l'utilisation sont simple d'apparence et méritent d'être bien distinguées. Serial available renvoie le nombre d'octets réellement disponibles dans le tampon de réception, et Serial read en retire un. Tester available avant de lire est obligatoire : appelé alors que rien n'est arrivé, read renvoie une valeur négative que vous transformerez peut-être en un caractère absurde. Le tampon interne, typiquement de soixante-quatre octets, enregistre les données pendant que votre programme fait autre chose, ce qui permet de ne pas perdre un caractère entre deux passages de la boucle. En revanche, il n'est pas illimité : si votre boucle reste bloquée plusieurs dizaines de millisecondes, le tampon déborde et les octets les plus anciens sont perdus sans remède.

L'impression elle-même connaît deux registres. Serial print convertit sa valeur en texte et l'envoie telle quelle, tandis que Serial println ajoute la fin de ligne, ce qui délimite les messages pour le moniteur. Dans un programme de débogage, la discipline la plus utile consiste à émettre une ligne unique et complète par événement plutôt que plusieurs fragments éparpillés : une ligne par mesure, une ligne par erreur, une ligne par changement d'état. Le moniteur série devient alors un journal filtrable. Ajoutez-y un préfixe par canal, par exemple le mot CARTE ou LCD au début du message, et vous pourrez suivre simultanément plusieurs sous-systèmes sans jamais vous perdre.

Un avertissement de conception concerne les attentes bloquantes. Il est tentant d'écrire une pause de quelques secondes après un envoi, mais pendant ce temps le port série continue de recevoir ce que l'ordinateur lui envoie, et le tampon peut déborder. De même, une boucle d'attente de la forme tant que Serial available est égale à zéro, sans autre tâche, fige le programme pendant une durée indéterminée. La bonne méthode reste la même que pour l'afficheur : mémoriser un état, avancer dans la boucle, revenir à la lecture quand quelque chose est disponible. Votre programme reste alors réactif au clavier, aux capteurs et à l'horloge, sans jamais attendre.
$lesson$),
  ('ard-c3-p13', 'ard-c3', 13, $lesson$Faire dialoguer deux cartes$lesson$, $lesson$
Brancher deux microcontrôleurs en port série obéit à une règle unique qu'on ne peut trahir : croiser les directions. La broche d'émission de l'un se relie à la broche de réception de l'autre, et inversement. S'y ajoute une masse commune, absolument indispensable, car les niveaux électriques se mesurent par rapport à cette référence commune. Sans masse partagée, les deux cartes n'ont aucun étalon de tension commun et la communication devient aléatoire, voire impossible même sur quelques centimètres de fil.

```text
   CARTE A                          CARTE B
  +--------+                      +--------+
  |     TX +----------------------> RX     |
  |     RX <----------------------+ TX     |
  |    GND +----------------------> GND    |
  +--------+                      +--------+

  Croisement obligatoire : TX d'un cote -> RX de l'autre.
  Masse commune indispensable : reference des niveaux TTL.
```

Sur les cartes qui exposent plusieurs ports matériels, la question se pose de savoir lequel utiliser. L'Arduino Uno ne possède qu'un seul UART matériel, et celui-ci est partagé avec le port USB : dès que vous branchez l'ordinateur, Serial et le moniteur se disputent la même ligne, si bien qu'un échange avec une seconde carte devient impossible tant que le câble USB est connecté. La solution consiste alors soit à utiliser deux broches en émulation logicielle, avec une bibliothèque de type logiciel, soit à basculer vers une carte disposant de plusieurs ports matériels. L'ESP32 en compte trois, ce qui lui permet de parler simultanément à l'ordinateur sur une port, à un module externe sur une autre, et à un automate voisin sur la troisième.

Le protocole que vous échangerez sur ce lien mérite d'être défini avant de coder. Deux familles s'offrent à vous. La première envoie du texte lisible, terminé par une fin de ligne : elle se débogue d'un coup d'œil dans le moniteur, elle se parseme facilement, mais elle impose des conversions et reste gourmande en octets. La seconde envoie des octets bruts dans un format compact, souvent un octet de tête, une charge utile puis un contrôle de somme : elle est rapide et économe, mais invisible à l'œil nu. Pour apprendre, commencez toujours par le texte. Passez au binaire seulement lorsque la bande passante devient réellement un problème, c'est-à-dire beaucoup plus tard que vous ne le pensez.

Voici un émetteur minimal qui envoie une mesure toutes les secondes, et son correspondant qui affiche ce qu'il reçoit. Le format choisi est une ligne de texte contenant un identifiant suivi d'une valeur, séparés par une virgule, parce qu'il reste lisible tout en se parcourant facilement.

```cpp
// Emetteur : carte A
void setup() {
  Serial.begin(9600);
}

void loop() {
  int mesure = analogRead(A0);
  Serial.print("T,");
  Serial.println(mesure);
  delay(1000);
}
```

Du côté récepteur, on lit ligne par ligne et on ne traite que les messages complets. L'accumulateur de caractères se remplit jusqu'à la fin de ligne, puis la ligne est examinée : si elle commence par le bon identifiant, la valeur est extraite et utilisée. Ce schéma, appelé protocole ligne par ligne, résiste aux fragments et aux réceptions coupées, car un message incomplet est simplement abandonné et la suivante reprend proprement. C'est la robustesse la plus importante à obtenir, et elle ne coûte que quelques lignes.

La vitesse doit être identique des deux côtés, et la notion de vitesse vaut aussi pour la configuration du moniteur lorsque vous branchez une seule carte. Un moniteur réglé à neuf mille six cents bauds devant une carte émettant à cent quinze mille deux cents affiche des caractères illisibles, ce qui fait figure d'énigme pour qui ne pense pas à ce réglage. Cette particularité est le premier réflexe à avoir face à du texte brouillé. Le second concerne la ligne de fin : certains environnements envoient un simple retour chariot, d'autres un retour à la ligne, d'autres les deux. Un programme qui compare à une chaîne complète échouera silencieusement si le suffixe diffère.
$lesson$),
  ('ard-c3-p14', 'ard-c3', 14, $lesson$Choisir le bon bus$lesson$, $lesson$
Vous disposez désormais de quatre outils : l'afficheur en parallèle, le bus I2C, le bus SPI et le port série. Aucun n'est supérieur aux autres, et le choix dépend de quatre critères qui reviennent toujours : le nombre de fils disponibles, le volume d'octets échangés, le nombre d'appareils à connecter et la nécessité ou non de réagir en temps réel. Le tableau ci-dessous résume les arbitrages auxquels vous serez confronté dans chacun de vos futurs projets.

| Critère | Parallèle | I2C | SPI | Série UART |
| --- | --- | --- | --- | --- |
| Fils de signal | 6 | 2 | 4 plus 1 par esclave | 2 |
| Nombre d'appareils | 1 | une dizaine | 1 par broche de sélection | 1 |
| Vitesse typique | moyenne | 100 à 400 kHz | plusieurs MHz | 9 600 à 115 200 bauds |
| Temps réel | non | correct | excellent | bon |
| Usage dominant | écrans historiques | capteurs et horloges | mémoire et écrans graphiques | débogage et modules |

Pour un capteur unique qui prend une mesure par seconde, l'I2C est le choix évident : deux fils, une adresse, une bibliothèque. Pour alimenter un écran graphique en couleur avec une image complète, le SPI s'impose, car la différence de débit se compte en secondes d'affichage. Pour garder une trace de tout ce qui se passe sans ordinateur, la carte SD en SPI reste imbattable. Et pour observer ce que votre programme fait réellement à chaque étape, rien ne remplace le port série, y compris lorsque vous travaillez sur un objet qui devra fonctionner seul.

Un projet réel combine presque toujours plusieurs de ces solutions en même temps, ce qui est la situation que l'exemple suivant met en œuvre. Le point de vigilance devient alors le partage des ressources : deux bibliothèques qui pilotent la même ligne d'horloge doivent se relâcher le bus entre chaque opération, deux périphériques sur le SPI doivent être sélectionnés l'un après l'autre, et deux sources de temporisation doivent coexister sans se gêner. Chaque bus possède son propre verrou de fonctionnement, et c'est en assemblant que l'on découvre le code qui l'oublie.
$lesson$),
  ('ard-c3-p15', 'ard-c3', 15, $lesson$Exemple guidé : la station d'affichage$lesson$, $lesson$
L'exemple de synthèse assemble les trois briques du chapitre. Un écran I2C montre la dernière mesure et un compteur d'exécution, une carte SD en SPI archive une ligne par mesure, et le port série renvoie les mêmes données en texte pour observation. Les trois cadences sont indépendantes : l'écran se rafraîchit souvent, le fichier s'écrit à intervalle plus long, le port série émet à son propre rythme. Aucune de ces opérations ne doit bloquer la boucle.

```cpp
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SPI.h>
#include <SD.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
const int CS_SD = 10;

unsigned long dernierAffichage = 0;
unsigned long dernierFichier = 0;
int compteur = 0;

void setup() {
  Serial.begin(115200);
  Wire.begin();
  lcd.init();
  lcd.backlight();
  if (SD.begin(CS_SD)) {
    File f = SD.open("j.csv", FILE_WRITE);
    if (f) { f.println("t,n"); f.close(); }
  }
  lcd.setCursor(0, 0);
  lcd.print("Station prete");
}

void loop() {
  unsigned long maintenant = millis();

  if (maintenant - dernierAffichage >= 500) {
    dernierAffichage = maintenant;
    compteur++;
    lcd.setCursor(0, 1);
    lcd.print(compteur);
    lcd.print("      ");
    Serial.print("m,");
    Serial.println(compteur);
  }

  if (maintenant - dernierFichier >= 10000) {
    dernierFichier = maintenant;
    File f = SD.open("j.csv", FILE_WRITE);
    if (f) {
      f.print(maintenant);
      f.print(",");
      f.println(compteur);
      f.close();
    }
  }
}
```

Observez la structure de ce sketch, car elle vaut bien les lignes de code elles-mêmes. Les variables de temporisation sont déclarées en dehors des fonctions pour conserver leur valeur d'un passage à l'autre. Les deux comparaisons d'intervalle utilisent la soustraction de deux nombres non signés, ce qui survit au rebouclage du compteur de millis sans produit particulier. Chaque bloc de travail se termine par la mise à jour de sa propre date, si bien que les trois rythmes ne se contrarient jamais. Aucun appel à delay ne figure dans la boucle, donc le programme pourrait à tout moment recevoir une commande sur le port série ou lire un bouton sans manquer son cadencement.

Pour améliorer cet exemple, la piste la plus fructueuse consiste à ajouter la gestion des erreurs, puisque la quasi-totalité des programmes d'apprentissage en sont dépourvus. Si la carte SD manque, affichez-le sur l'écran plutôt que de l'ignorer, et continuez malgré tout. Si l'écran ne répond pas au balayage, signalez-le sur le port série et poursuivez l'enregistrement fichier. Un système dont chaque sous-système peut échouer indépendamment reste utile quand l'un d'eux tombe en panne. C'est exactement le principe des systèmes industriels, et l'introduire dès l'apprentissage change radicalement la qualité du code que vous écrirez par la suite.

Un second enrichissement consiste à rendre les messages plus riches. Au lieu d'un compteur seul, envoyez plusieurs valeurs séparées par des virgules, ajoutez un identifiant de version et un horodatage, puis écrivez la même chaîne à la fois sur l'écran et dans le fichier. Vous découvrirez ainsi combien la mise en forme d'un message est une décision de conception : elle conditionne la lisibilité dans le moniteur, la facilité d'analyse dans un tableur et la capacité à faire évoluer le protocole sans casser les anciens enregistrements. Gardez toujours une version en tête, et refusez d'envoyer des données dont la signification pourrait devenir ambiguë dans six mois.
$lesson$),
  ('ard-c3-p16', 'ard-c3', 16, $lesson$À retenir$lesson$, $lesson$
- L'écran LCD 16x2 se pilote en parallèle avec six fils de données, ou en I2C avec deux fils grâce à un expandeur PCF8574.
- Les adresses I2C les plus courantes d'un écran sont 0x27 et 0x3F, et elles se confirment toujours par un balayage du bus.
- Le bus I2C se compose de deux lignes à niveau ouvert, SDA et SCL, qui exigent une résistance de rappel vers l'alimentation.
- Un retour égal à zéro de endTransmission signifie qu'un appareil a acquitté l'adresse testée.
- Le bus SPI utilise quatre signaux, MOSI, MISO, SCK et CS, et réserve une broche de sélection à chaque esclave.
- Une carte SD s'initialise avec la broche de sélection, s'ouvre, s'écrit puis se ferme : la fermeture est le moment où les données partent réellement.
- Le port série UART se croise, TX vers RX, et repose sur une masse commune ainsi qu'une vitesse identique aux deux extrémités.
- Dans la boucle, on lit seulement quand Serial available le signale, et on n'attend jamais passivement une donnée.
- Les trois cadences d'un programme se gèrent avec millis, jamais avec des appels bloquants.
- Le bon bus se choisit selon le nombre de fils, le volume de données et le nombre d'appareils, pas selon la mode.
$lesson$),
  ('ard-c3-p17', 'ard-c3', 17, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Écran blanc alors que tout semble câblé : le contraste n'est pas réglé, tournez le potentiomètre du module avant de soupçonner le code.
- Aucune adresse détectée lors du balayage : vérifiez l'alimentation du module, l'ordre de SDA et SCL, puis la présence des résistances de rappel.
- Adresse incorrecte dans le programme alors que le balayage en trouve une autre : recopiez le relevé du scanner dans une constante nommée.
- Écriture d'un caractère absurde à la place d'une icône : un motif personnalisé s'inscrit avec write et non avec print.
- Texte brouillé dans le moniteur : la vitesse du moniteur et celle de la carte ne sont pas identiques.
- Deux appareils qui ne répondent plus l'un après l'autre : une bibliothèque laisse le bus verrouillé, testez-les isolément puis ensemble.
- Réinitialisation de la carte lors des écritures sur la carte SD : ajoutez un condensateur d'au moins cent microfarads aux bornes de l'alimentation.
- Mesures farfelues sans aucun message d'erreur : le nombre d'octets lus ne correspond pas à la valeur attendue, contrôlez-le avant le calcul.
- Perte des dernières lignes d'un fichier : la fermeture du fichier a été oubliée.
- Deux esclaves SPI qui se neutralisent : leurs lignes de sélection sont toutes les deux actives en même temps.
$lesson$),
  ('ard-c3-p18', 'ard-c3', 18, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation officielle de la référence Arduino reste la source la plus fiable pour les fonctions de base, et elle se trouve sur le site www.arduino.cc dans la section consacrée à la référence et aux bibliothèques. Le site du fabricant d'écrans et de modules, par exemple www.adafruit.com, publie des didacticiels détaillés accompagnés de schémas de câblage que vous pourrez comparer aux vôtres. Pour l'ESP32, la documentation technique publiée sur le site www.espressif.com détaille les multiplexeurs de broches qui rendent ce microcontrôleur si souple dans l'affectation des bus. Les fiches techniques des composants, appelées datasheets, se trouvent sur les sites des fabricants ; elles contiennent les tables de registres dont vous avez eu besoin pour décoder un appareil, et leur lecture est l'étape naturelle qui suit ce chapitre.

Un exercice de consolidation particulièrement rentable consiste à réécrire l'exemple guidé en remplaçant l'écran par un afficheur OLED piloté en I2C, puis la carte SD par une mémoire flash du même bus. Vous constaterez alors que le nombre de broches utilisées ne change presque pas, alors que le nombre d'appareils augmente : c'est la promesse de l'I2C que vous venez de vérifier par vous-même. Une seconde piste consiste à ajouter un menu affiché sur l'écran et navigué par un bouton, ce qui vous forcera à appliquer les règles des machines à états que le chapitre suivant traite en détail.
$lesson$),
  ('ard-c3-p19', 'ard-c3', 19, $lesson$Et maintenant : passez à la pratique$lesson$, $lesson$
Vous avez parcouru l'essentiel des moyens qu'un objet embarqué utilise pour montrer ses états et pour converser avec d'autres circuits. Le moment est venu de sortir le fer à souder : commencez par le plus simple, allumez un écran en I2C et affichez une phrase, puis faites répondre le bus avec un balayage. Une fois ces deux étapes stables, branchez un capteur sur le même bus et affichez sa mesure. Ajoutez ensuite la carte SD en SPI, puis le port série. Chaque étape isolée se vérifie en quelques minutes, et l'ensemble construit pas à pas vous donnera une station complète, identique à celle de l'exercice pratique qui suit cette leçon. C'est en assemblant ces briques, une par une, que vous transformerez des connaissances acquises en réflexes durables.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('ard-c4-p1', 'ard-c4', 1, $lesson$Le piège du programme bloquant$lesson$, $lesson$
Bienvenue dans ce quatrième chapitre du parcours Arduino et ESP32, celui où votre code cesse d'être une suite d'instructions exécutées les unes après les autres pour devenir un véritable objet qui décide. Jusqu'ici, vos programmes suivaient un chemin unique : ils allumaient une LED, lisaient un capteur, affichaient une mesure, puis recommençaient à l'identique à chaque tour de boucle. C'est confortable pour apprendre, mais cela devient très vite insuffisant dès que votre appareil doit réagir à plusieurs événements en même temps, respecter des durées précises et rester disponible pendant ces durées. Le feu tricolore que vous avez peut-être déjà construit avec des appels à delay() fonctionne tant qu'on ne lui demande rien d'autre ; ajoutez un bouton piéton et l'appareil ne le voit plus, parce qu'il dort littéralement pendant ses temporisations. Ce chapitre vous donne les deux outils qui résolvent définitivement cette difficulté : la machine à états, qui structure les décisions, et les interruptions matérielles, qui captent les événements sans que votre programme ait à les guetter.

À la fin de cette leçon, vous saurez faire quatre choses concrètes, et vous les aurez déjà manipulées dans du vrai code. Premièrement, vous modéliserez un comportement complexe sous forme d'automate : un ensemble fini d'états, de transitions conditionnées et d'actions d'entrée et de sortie, décrit sur papier avant d'être écrit en C++. Deuxièmement, vous traduirez ce modèle en un sketch utilisant un enum, une variable d'état et une structure de branches claire, sans empiler les conditions imbriquées jusqu'à l'incompréhensible. Troisièmement, vous remplacerez les temporisations bloquantes par des compteurs fondés sur millis(), ce qui rendra votre boucle principale toujours réactive. Quatrièmement, vous déclencherez des actions depuis une interruption matérielle avec attachInterrupt(), en respectant les règles strictes qui s'imposent à une routine d'interruption. Ces quatre compétences sont exactement celles que l'on attend d'un développeur embarqué professionnel, et elles vous serviront dans tous les projets restants du parcours, du noeud connecté jusqu'au tableau de bord final.

Le fil rouge de la leçon sera un feu piéton complet, avec ses deux flux de circulation, son bouton d'appel et son affichage du temps restant. Nous le construirons par étapes : d'abord la modélisation sur papier, puis la structure d'automate en C++, ensuite les temporisations non bloquantes, enfin l'interruption du bouton et les timers matériels de l'ESP32. Chaque étape est illustrée par un extrait de code complet, commenté ligne à ligne, avant d'être réassemblée dans un exemple guidé final. Un quiz de quatre questions clôturera le chapitre pour vérifier que les notions essentielles sont bien installées, et l'exercice pratique vous demandera de réécrire seul un automate légèrement différent, afin de prouver que vous maîtrisez la méthode plutôt que le exemple précis. Avant de commencer, un conseil de méthode : les automates se conçoivent d'abord à la main, sur papier ou dans un tableur, parce qu'un modèle faux produira toujours un code faux, aussi élégant soit-il.



La fonction delay() est la première temporisation que l'on découvre en Arduino, et elle est parfaitement adaptée à un programme unique dont on veut simplement rythmer l'exécution. Elle a pourtant un défaut structurel qu'il faut comprendre en profondeur, et non simplement retenir comme une formule : pendant tout le temps où elle s'exécute, le processeur ne fait rien d'autre que compter. La boucle principale est figée, les lectures de broches sont suspendues, les messages série ne sont pas traités, et le programme devient sourd à ce qui se passe autour de lui. Ce n'est pas une mauvaise surprise ponctuelle, c'est la conséquence directe du fonctionnement de la fonction : elle occupe la boucle jusqu'à l'expiration du délai. Pour un clignotement simple, cela n'a aucune importance ; pour un objet qui doit surveiller un bouton, un capteur et un afficheur en même temps, cela rend le comportement erratique dès la première seconde.

Le sketch suivant est celui que tout le monde écrit un jour ou l'autre, et il contient le défaut que nous venons de décrire. Observez la structure : on allume, on attend, on éteint, on attend. L'intention est claire et le résultat visuel est correct, mais la boucle n'est jamais disponible pendant les deux mille millisecondes d'attente. Si un utilisateur appuie sur un bouton pendant ce laps de temps, l'appui est perdu, ou pire, il sera traité de manière aléatoire selon l'instant exact où il se produira. C'est la cause numéro un des bugs que l'on rencontre sur les premiers objets interactifs, et il est fréquent de voir un débutant chercher l'erreur dans le câblage alors que le câblage est parfaitement en ordre.

```cpp
const int LED = 13;

void setup() {
  pinMode(LED, OUTPUT);
}

void loop() {
  digitalWrite(LED, HIGH);
  delay(2000);              // pendant 2 s, le programme est sourd
  digitalWrite(LED, LOW);
  delay(2000);              // pendant 2 s, le programme est sourd
}
```

La situation devient intenable dès que l'on ajoute une seconde tâche. Supposons que vous vouliez faire clignoter la LED pendant qu'un capteur est interrogé et qu'un afficheur est rafraîchi : avec des appels à delay(), ces trois activités ne peuvent pas coexister, car elles se disputent le même temps unique de la boucle. Vous pouvez essayer d'intercaler les lectures entre les attentes, mais plus vous raccourcissez les délais, plus la lecture devient irrégulière, et plus vous les allongez, moins l'objet est réactif. Le deuxième exemple ci-dessous montre l'assemblage tenté : il paraît correct au premier regard, et pourtant il rate systématiquement les appuis courts, parce que le capteur n'est interrogé qu'une fois toutes les deux secondes.

```cpp
void loop() {
  digitalWrite(LED, HIGH);
  delay(1000);
  int valeur = analogRead(A0);   // lu trop tard, souvent
  Serial.println(valeur);
  digitalWrite(LED, LOW);
  delay(1000);                   // tout appui pendant cette seconde est perdu
}
```

Il existe une manière de mesurer concrètement ce phénomène avant d'essayer de le corriger. Branchez un bouton entre une broche et la masse, activez le pull-up interne, et écrivez dans le moniteur série un message à chaque appui détecté dans la boucle. Appuyez pendant que la LED est éteinte, votre message apparaît ; appuyez pendant qu'elle est allumée, rien ne se passe. Le matériel fonctionne, la broche fonctionne, le programme fonctionne, mais l'exécution n'est tout simplement pas au bon endroit au bon moment. Comprendre cette distinction est essentiel : le problème n'est pas dans ce que vous demandez, il est dans la façon dont votre temps est organisé. La suite de ce chapitre vous apprendra à réorganiser ce temps, d'abord en structurant les comportements, puis en supprimant les attentes inertes.
$lesson$),
  ('ard-c4-p2', 'ard-c4', 2, $lesson$Comprendre l'automate : états, transitions et actions$lesson$, $lesson$
Un automate, au sens où on l'utilise en électronique et en automatisme, est un modèle mathématique simple et redoutablement efficace : il décrit un système comme un ensemble fini d'états, dont un seul est actif à un instant donné, et comme un ensemble de règles qui autorisent le passage d'un état à un autre. L'intérêt de ce modèle n'est pas théorique, il est directement pratique. Dès que vous écrivez if puis else puis des conditions enchevêtrées pour représenter un objet qui a plusieurs modes, vous êtes en train de fabriquer un automate de manière désordonnée ; le formaliser, c'est rendre visible ce que le code cache déjà, puis écrire ce code à partir d'un dessin lisible plutôt qu'à partir d'une intuition fragile. C'est exactement la méthode employée dans l'industrie, où les automates programmables commandent les stations de production, les ascenseurs et les feux de signalisation.

Trois mots suffisent à décrire le modèle complet. L'état est la situation dans laquelle se trouve le système à un instant donné : le feu est au rouge, la porte est verrouillée, la machine est en attente d'un opérateur. Chaque état est stable, c'est-à-dire qu'il peut durer aussi longtemps que nécessaire sans que rien ne change tant qu'aucune condition ne se réalise. La transition est la règle de changement : elle relie un état de départ à un état d'arrivée et ne se déclenche que si sa condition devient vraie, le plus souvent une entrée physique, un écoulement de temps ou un message reçu. L'action est ce que l'automate fait en entrant ou en quittant un état, ou tant qu'il y reste : allumer une broche, écrire sur un afficheur, émettre un bip. Avec seulement ces trois idées, vous modélisez la quasi-totalité des objets du monde embarqué.

| Notion | Question à laquelle elle répond | Exemple concret |
|---|---|---|
| État | Où suis-je maintenant ? | L'état JAUNE du feu piéton |
| Transition | Pourquoi et quand est-ce que j'avance ? | Le compteur de trois secondes est dépassé |
| Condition | Qu'est-ce qui doit devenir vrai ? | millis() dépasse l'instant de fin |
| Action | Que fais-je concrètement ? | Éteindre la LED jaune, allumer la LED verte |
| Entrée | Qu'est-ce qui m'informe du monde ? | Un front descendant sur la broche du bouton |
| Sortie | Comment le monde me voit-il ? | Une broche PWM, un afficheur, un relais |

La discipline que cette modélisation impose est plus précieuse que le dessin lui-même. Elle vous oblige à répondre, pour chaque état, à quatre questions avant toute ligne de code : quelles sont les entrées qui m'intéressent ici, quelles sorties dois-je activer, vers quels états puis-je passer, et sous quelles conditions. Elle vous oblige aussi à lister ce qui n'est pas permis, ce qui est souvent plus utile : dans l'état OCCUPE, par exemple, un nouvel appui sur le bouton est ignoré, et cette règle, non écrite, est précisément celle qui déclenche les bugs les plus mystérieux. En formalisant les interdits, vous évitez les transitions fantômes et les réactions inattendues qui donnent à un objet l'impression d'avoir une vie propre.

- Un état actif unique à chaque instant, jamais deux à la fois.
- Des transitions explicitement listées, avec leur condition et leur action associée.
- Des entrées lues en continu, même pendant les attentes.
- Des sorties pilotées de façon déterministe, à l'entrée comme à la sortie d'un état.
- Aucune dépendance à la vitesse d'exécution du processeur.

Un dernier point mérite d'être souligné avant de passer à l'implémentation, parce qu'il distingue l'automate d'un simple empilement de conditions : l'automate est non déterministe dans sa forme, mais parfaitement déterministe dans son exécution. À chaque passage de boucle, vous examinez les transitions dans un ordre fixe, vous n'en retenez qu'une seule, et vous appliquez exactement les mêmes règles quel que soit l'historique. Cette prévisibilité est ce qui permet de tester un objet : si l'état de départ et la suite d'événements sont connus, l'état d'arrivée est connu lui aussi, avant même d'avoir branché la carte. C'est aussi ce qui rend le débogage simple, car il suffit d'imprimer l'état courant pour voir immédiatement où la logique déraille, au lieu de reconstituer un comportement à partir de dizaines de variables partiellement modifiées. Prenez l'habitude d'écrire sur papier, avant tout code, la liste des états et des transitions ; vous constaterez que la moitié des questions que vous vous posez trouve sa réponse dans ce tableau, et que le reste du programme se résume ensuite à une mécanique de transcription.
$lesson$),
  ('ard-c4-p3', 'ard-c4', 3, $lesson$Modéliser avant de coder$lesson$, $lesson$
La étape de modélisation se fait sur papier, et elle prend rarement plus de dix minutes pour un objet de la taille de ceux de ce parcours. On commence par écrire tous les états possibles, en les nommant avec des mots entiers et explicites plutôt que des chiffres : ATTENTE, DETECTION, OCCUPE, LIBERATION se lisent dans un logiciel de versionning six mois plus tard, alors que ETAT_3 n'y signifie plus rien. On dessine ensuite des flèches entre les états, en écrivant sur chaque flèche la condition qui la déclenche et, entre parenthèses, l'action effectuée à ce moment-là. On vérifie enfin qu'aucun état n'est orphelin, qu'aucune transition ne part de nulle part, et que l'objet sait toujours quoi faire, y compris dans les cas limites comme un appui simultané à la fin d'une temporisation.

Le schéma ci-dessous est celui du feu piéton que nous allons programmer. Il tient en quatre cases et quatre flèches, mais il contient déjà toute la logique du programme : le texte placé sur chaque flèche deviendra une condition dans votre code, et le texte placé à l'intérieur de chaque case deviendra le contenu d'une branche de la structure de décision. Ce passage direct du dessin au code est la raison pour laquelle les automates sont si populaires en embarqué : ils suppriment la phase de traduction où l'on perd la logique originale dans des conditions successives.

```text
                    bouton appui (bip)
        +-----------+  ------------>  +-----------+
        |  ATTENTE  |                 |  OCCUPE   |
        +-----------+                 +-----------+
             ^                            |
             |  distance < 50 cm          | compteur 20 s
             |                            v
        +-----------+    duree 3 s    +--------------+
        | DETECTION | <-------------- | LIBERATION   |
        +-----------+   (bip double)  +--------------+
```

Une fois le schéma validé, il reste une question de mise en forme qui paraît anodine et qui décide de la lisibilité de tout le reste : comment représenter les états dans le langage. La réponse correcte, en C++, est un enum, c'est-à-dire une liste de noms symboliques associés à des entiers. Le compilateur remplace chaque nom par son entier, mais votre code reste lisible, l'éditeur signale les noms inconnus, et l'ajout d'un état devient une ligne au lieu d'une recherche dans tout le fichier. Nous verrons dans la section suivante comment structurer la boucle autour de ce enum, et pourquoi il faut absolument éviter les chaines de comparaisons portant sur des textes.

Avant de fermer cette première étape, récapitulons le chemin parcouru. Vous savez maintenant pourquoi delay() rend un objet sourd, ce qu'est un état, ce qu'est une transition, et comment un dessin de quatre cases suffit à contenir la logique complète d'un programme. Vous savez aussi que l'ordre dans lequel vous examinez les transitions a son importance, et qu'un état sans règle de sortie est un piège dans lequel votre objet finira toujours par tomber. Toutes ces idées sont indépendantes du langage : vous les retrouveriez à l'identique en écrivant le même feu pour un automate industriel programmable, pour un microcontrôleur 8 bits ou pour un processeur de station de travail. C'est précisément ce qui fait leur valeur : elles vous accompagnent au-delà d'Arduino. La prochaine étape consiste à traduire fidèlement ce schéma en C++, en choisissant des formes de code qui rendent la structure visible d'un simple coup d'œil, puis à remplacer les attentes inertes par des compteurs de temps qui laissent la boucle libre de faire son travail.

La modélisation est faite, le schéma tient sur une demi-page, et il reste à la faire tourner dans un sketch. Cette étape est presque mécanique, à condition de choisir dès le départ des formes de code qui rendent la structure visible d'un simple coup d'œil : un enum pour les états, une variable unique pour l'état courant, une fonction d'entrée par transition et une fonction de sortie par état. Ces quatre conventions forment ce que l'on appelle parfois le patron d'automate, et elles existent depuis bien plus longtemps qu'Arduino : on les retrouve dans les automates programmables industriels, dans les pilotes de périphériques des systèmes d'exploitation et dans les interfaces graphiques de tous vos logiciels préférés. Une fois ces conventions posées, l'écriture du code devient rapide et, surtout, relecture trois semaines plus tard devient immédiate.
$lesson$),
  ('ard-c4-p4', 'ard-c4', 4, $lesson$Représenter les états en C++$lesson$, $lesson$
En C++, un enum est une liste de noms symboliques que le compilateur remplace par des entiers. Là où un débutant écrirait une variable entière et une série de commentaires du type trois égal rouge, quatre égal jaune, le enum donne un nom à chaque concept et laisse le compilateur vérifier que ce nom existe bien. Deux formes s'offrent à vous sur les cartes Arduino : l'enum classique, dont les valeurs sont disponibles sans qualification, et le enum class, plus strict, qui impose d'écrire le nom de l'enum devant chaque valeur. Pour un petit sketch, les deux conviennent ; le enum class a l'avantage de provoquer une erreur de compilation si vous comparez un état à un entier, ce qui attrape une classe entière de bugs silencieux. Quel que soit votre choix, nommez les états en majuscules ou en lettres capitales de début de mot, et employez des mots qui décrivent une situation, pas une durée.

```cpp
enum class FeuEtat {
  ROUGE_PIETON,     // piétons passent, voitures arrêtées
  JAUNE_PIETON,     // fin de passage, préparation
  ROUGE_VOITURE,    // voitures circulent, piétons attendent
  JAUNE_VOITURE     // voitures s'arrêtent
};

FeuEtat etatCourant = FeuEtat::ROUGE_VOITURE;
unsigned long debutEtat = 0;
```

Remarquez les deux variables qui accompagnent le enum. La première, etatCourant, contient l'état actif ; c'est elle que vous lisez à chaque tour de boucle. La seconde, debutEtat, mémorise l'instant où l'automate est entré dans cet état, ce qui permet de mesurer la durée écoulée sans bloquer personne. Ces deux variables constituent, avec la liste des transitions, l'intégralité de l'état mémoire de votre objet. Tout le reste peut être recalculé à la volée. Cette économie est précieuse : moins il y a de variables partagées entre les sections du programme, moins il y a de risques qu'une modification inattendue dans un coin du code altère le comportement d'un autre.

Un détail fréquent mérite d'être traité ici, parce qu'il apparaît dès le premier essai : que faire lorsqu'un état dépend lui-même d'une mesure, par exemple la distance lue par un capteur ? La réponse est de ne jamais stocker la mesure comme si elle faisait partie de l'état. La distance est une donnée d'entrée, l'état est une situation ; les deux vivent dans des catégories différentes. Vous relisez la donnée à chaque boucle, vous la lissez si nécessaire, puis vous la comparez à un seuil dans la condition de transition. Si vous commenciez à créer des états du type TROP_LOIN et TROP_PRES, votre nombre d'états exploserait avec la résolution du capteur et le programme deviendrait ingérable. Gardez un nombre d'états aussi petit que le permet le comportement à décrire : la plupart des objets du monde réel tiennent en trois à six états, et un automate de vingt états est presque toujours le signe qu'une décision a été rangée dans le mauvais endroit.
$lesson$),
  ('ard-c4-p5', 'ard-c4', 5, $lesson$La structure de la boucle d'automate$lesson$, $lesson$
La boucle d'un automate suit toujours le même enchaînement, et cet enchaînement ne varie pas d'un projet à l'autre : lire les entrées, déterminer si une transition doit avoir lieu, l'appliquer le cas échéant, puis mettre à jour les sorties. En C++, la représentation la plus lisible est une structure de branches sur l'état courant, suivie d'une fonction dédiée aux transitions. Chaque branche ne contient que ce qui est propre à l'état : les sorties à maintenir et les conditions de sortie. Les actions d'entrée, c'est-à-dire ce qui se passe juste après un changement d'état, sont regroupées dans une fonction unique, appelez-la entrerEtat, qui s'exécute une seule fois par transition. Ce partage évite le redoublement des codes d'allumage éparpillés dans tout le fichier, qui est la première cause d'oublis lorsqu'on ajoute un état.

```cpp
void entrerEtat(FeuEtat suivant) {
  etatCourant = suivant;
  debutEtat = millis();
  Serial.print("Etat -> ");
  Serial.println(nomEtat(etatCourant));
}

void gererTransitions() {
  unsigned long ecoule = millis() - debutEtat;

  if (etatCourant == FeuEtat::ROUGE_VOITURE && ecoule > 8000) {
    entrerEtat(FeuEtat::JAUNE_VOITURE);
  } else if (etatCourant == FeuEtat::JAUNE_VOITURE && ecoule > 2000) {
    entrerEtat(FeuEtat::ROUGE_PIETON);
  } else if (etatCourant == FeuEtat::ROUGE_PIETON && ecoule > 8000) {
    entrerEtat(FeuEtat::JAUNE_PIETON);
  } else if (etatCourant == FeuEtat::JAUNE_PIETON && ecoule > 2000) {
    entrerEtat(FeuEtat::ROUGE_VOITURE);
  }
}
```

Notez l'usage du calcul millis() - debutEtat plutôt que l'écriture millis() > debutEtat + duree. Les deux semblent équivalents, et ils le sont presque toujours, mais la première forme est robuste lorsque le compteur de millisecondes déborde, ce qui arrive après un peu plus de quarante-neuf jours de fonctionnement continu. L'arithmétique entière non signée fait que la soustraction reste correcte de part et d'autre du débordement, alors que la comparaison avec une somme peut échouer. Ce n'est pas un cas théorique pour un objet qui reste sous tension dans un tableau électrique ; c'est une ligne de code qui coûte rien et qui vous évite un mystère à réparer au pire moment. La règle d'or de la structure d'automate tient en une phrase : une branche par état, une fonction de transition, une fonction d'entrée, et aucun délai mort.

Il reste à écrire l'appel de tout cela dans loop, et cet appel doit être minimal, parce que tout ce que vous ajoutez dans la boucle ralentit la réactivité de l'ensemble. Trois appels suffisent : lire les entrées, mettre à jour les transitions, rafraîchir les sorties. La fonction de mise à jour des sorties, elle, peut être appelée à chaque tour de boucle sans inconvénient, car écrire la même valeur sur une broche deux fois de suite ne change rien pour le matériel. Cette tolérance vous simplifie la vie : vous n'avez pas à mémoriser si vous avez déjà piloté une broche, vous la pilotez simplement. En revanche, tout ce qui est émission série, calcul lourd ou attente doit rester hors de ce chemin critique, ou être limité par un compteur de temps lui aussi non bloquant.

| Élément du code | Rôle | Fréquence d'appel |
|---|---|---|
| lireEntrees() | Capteurs, boutons, messages série | Chaque tour de boucle |
| gererTransitions() | Compare état et conditions | Chaque tour de boucle |
| majSorties() | Écrit broches, afficheurs, PWM | Chaque tour de boucle |
| entrerEtat() | Actions d'entrée une seule fois | Une fois par transition |
| gérerTemporisations() | Compteurs non bloquants | Chaque tour de boucle |
$lesson$),
  ('ard-c4-p6', 'ard-c4', 6, $lesson$Temporisations non bloquantes avec millis()$lesson$, $lesson$
Vient maintenant la pièce maîtresse technique du chapitre : remplacer l'attente par une mesure. La fonction millis() renvoie le nombre de millisecondes écoulées depuis le démarrage de la carte, sous forme d'un entier non signé sur trente-deux bits. Elle ne s'arrête jamais et ne consomme aucun temps d'exécution notable : l'appeler revient simplement à lire un compteur matériel. L'idée est donc de noter l'instant de départ d'une action, puis de vérifier à chaque tour de boucle si l'instant présent a dépassé l'instant de départ augmenté de la durée voulue. Tant que le seuil n'est pas atteint, la boucle continue de faire tout le reste : lire les entrées, gérer les autres états, rafraîchir l'affichage. C'est exactement le contraire de delay, qui suspend tout le reste pendant l'attente.

```cpp
const int LED = 13;
bool allume = false;
unsigned long dernierChangement = 0;
const unsigned long INTERVALLE = 500;

void setup() {
  pinMode(LED, OUTPUT);
}

void loop() {
  unsigned long maintenant = millis();

  if (maintenant - dernierChangement >= INTERVALLE) {
    dernierChangement = maintenant;
    allume = !allume;
    digitalWrite(LED, allume ? HIGH : LOW);
  }

  // ici, le reste du programme reste entièrement disponible
}
```

La comparaison entre les deux approches mérite d'être posée noir sur blanc, car elle résume à elle seule toute la logique de ce chapitre. Le délai bloquant est simple à écrire et parfaitement suffisant pour un script unique ; il devient inutilisable dès que deux tâches doivent coexister. La temporisation non bloquante demande une variable de plus et une condition, mais elle conserve la boucle entièrement disponible et permet d'enchaîner autant de durées indépendantes qu'il le faut. Dans la pratique professionnelle, on ne rencontre quasiment jamais la première forme hors des esquisses pédagogiques.

| Critère | delay() | Compteur millis() |
|---|---|---|
| Réactivité de la boucle | Nulle pendant l'attente | Totale en permanence |
| Nombre de durées simultanées | Une seule | Autant que nécessaire |
| Lecture des entrées pendant l'attente | Impossible | Possible à chaque tour |
| Complexité du code | Une ligne | Une variable et une condition |
| Comportement après 49 jours | Non pertinent | Correct si l'on soustrait |

Un second avantage, rarement mentionné mais décisif dans un objet interactif, est que la temporisation non bloquante se règle pendant l'exécution sans recompiler. Si vous souhaitez prolonger l'état OCCUPE de deux secondes parce qu'un nouvel appui est arrivé, il vous suffit de décaler debutEtat ou d'ajouter une seconde variable d'échéance ; le programme s'adapte immédiatement. Avec delay, il faudrait interrompre l'attente en cours, ce qui n'a aucun sens une fois la fonction engagée. La temporisation non bloquante transforme donc le temps en une donnée que l'automate peut manipuler, et non plus en une contrainte subie.
$lesson$),
  ('ard-c4-p7', 'ard-c4', 7, $lesson$Plusieurs compteurs en parallèle$lesson$, $lesson$
Un objet réaliste n'a jamais une seule temporisation. Le feu piéton doit clignoter pendant qu'un afficheur se rafraîchit, pendant qu'un bip sonore se déclenche, pendant qu'un compteur d'inactivité tourne. Chacune de ces durées a sa propre échéance et sa propre logique : les regrouper dans une seule variable serait les rendre inséparables. La méthode consiste donc à donner à chaque temporisation son couple de variables, un instant de départ et une durée, puis à tester chacune de ces couples indépendamment dans la boucle. Aucun n'attend les autres, aucun ne les bloque, et leur ordre d'appel n'a aucune importance tant qu'ils sont tous traités avant le retour en haut de la boucle.

```cpp
unsigned long tClignote = 0;
unsigned long tAfficheur = 0;
unsigned long tBip = 0;
bool bipActif = false;

void gererTemporisations() {
  unsigned long m = millis();

  if (m - tClignote >= 500) {
    tClignote = m;
    digitalWrite(LED, !digitalRead(LED));
  }

  if (m - tAfficheur >= 250) {
    tAfficheur = m;
    afficherTempsRestant();
  }

  if (bipActif && m - tBip >= 150) {
    bipActif = false;
    digitalWrite(BUZZER, LOW);
  }
}
```

L'exemple montre une variante utile : certaines temporisations ne doivent se déclencher que si une condition est vraie, comme le bip qui ne sonne que pendant une transition. Plutôt que de multiplier les états pour cela, on utilise un drapeau, bipActif, mis à vrai au moment où l'action doit commencer et remis à faux à la fin. Le compteur continue de tourner, mais son effet n'est appliqué que si le drapeau l'autorise. Ce motif, drapeau plus échéance, se retrouve partout dans l'embarqué : transmission en cours, mesure en cours, changement d'état différé. Il vous évite de créer des états transitoires qui n'apportent rien à la modélisation et multiplient les branches à tester.

Un piège attend celui qui multiplie les compteurs : l'oubli d'initialisation. Si vous déclarez vos instants de départ à zéro sans les réinitialiser à l'entrée d'un état, la première échéance peut être dépassée dès le démarrage, ce qui déclenche une action immédiate et apparemment injustifiée. La parade est systématique : à chaque entrée dans un état, dans entrerEtat, vous réinitialisez tous les compteurs concernés à millis(). Cette ligne unique vous fait gagner des heures de débogage, et elle fait partie des habitudes à installer dès maintenant. De même, lorsque vous ajoutez une temporisation, écrivez d'abord sa condition, puis sa variable de départ, puis son action, dans cet ordre, et vérifiez-la immédiatement en observant le moniteur série plutôt qu'en attendant un comportement global anormal.

Les temporisations non bloquantes ont résolu le problème du temps : votre boucle ne dort plus, elle reste disponible en permanence. Reste une seconde catégorie d'événements, plus insidieuse, celle des instants brefs et imprévisibles. Un appui de bouton dure quelques dizaines de millisecondes ; une impulsion d'un capteur peut durer moins d'un milliseconde ; un front détecté par un photodiode se produit sans prévenir à aucun moment particulier. Si votre boucle est occupée à traiter un afficheur au moment où l'événement survient, il est perdu. Vous pourriez raccourcir le temps de la boucle, mais vous ne ferez que déplacer le problème sans le supprimer. La réponse consacrée par tous les systèmes embarqués s'appelle l'interruption : laisser le matériel vous prévenir, plutôt que d'aller guetter le matériel sans arrêt.
$lesson$),
  ('ard-c4-p8', 'ard-c4', 8, $lesson$Pourquoi une interruption plutôt qu'une lecture active$lesson$, $lesson$
La lecture active consiste à interroger une broche à intervalle régulier, dans la boucle, et à décider ensuite si un changement mérite une action. Cette méthode fonctionne tant que la boucle est rapide et dédiée à cette tâche, mais elle souffre de deux défauts structurels. Le premier est la dépendance au temps de la boucle : plus votre code fait de choses, plus l'espace entre deux lectures grandit, et plus la probabilité de manquer un événement bref augmente. Le second est le gaspillage : la grande majorité des lectures ne trouvent aucun changement, et pourtant elles occupent du processeur, de la mémoire et de la batterie. Sur un objet alimenté par batterie, cette différence n'est pas un détail d'optimisation, elle décide de l'autonomie. L'inverse exact se produit avec une interruption : la broche est surveillée en permanence par un circuit spécialisé du microcontrôleur, et le programme n'est sollicité que lorsque le front attendu apparaît réellement.

Concrètement, la fonction attachInterrupt demande au matériel de surveiller une broche et d'exécuter une fonction de votre choix dès qu'un événement se produit sur cette broche. Cette fonction porte un nom particulier : la routine d'interruption, souvent abrégée ISR pour interrupt service routine. Le principe d'exécution est simple à décrire et contre-intuitif à vivre : la boucle principale est en train de faire n'importe quoi, une interruption survient, le processeur suspend instantanément ce qu'il faisait, saute vers la routine, l'exécute en entier, puis revient exactement là où il s'était arrêté, comme si rien ne s'était passé. Votre code de boucle n'a donc aucune logique particulière à écrire pour accepter l'interruption, aucune file d'attente à gérer, aucun drapeau à scruter manuellement : la transition entre l'avant et l'après est automatique.

```cpp
const int BOUTON = 2;
volatile bool appuiDetecte = false;

void ISR_appui() {
  appuiDetecte = true;
}

void setup() {
  Serial.begin(115200);
  pinMode(BOUTON, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(BOUTON), ISR_appui, FALLING);
}

void loop() {
  if (appuiDetecte) {
    appuiDetecte = false;
    Serial.println("Appui !");
    // toute la logique métier se traite ici, hors interruption
  }
}
```

Le programme ci-dessus illustre le patron complet d'une interruption moderne. La routine elle-même ne fait qu'une chose : poser un drapeau. Toute la suite, l'affichage, le changement d'état, l'envoi d'un message, s'effectue dans la boucle, à un moment choisi par vous. Ce découpage n'est pas une simple élégance, il est imposé par la nature même de l'interruption, que la section suivante décrit précisément, et il constitue la règle la plus importante de ce chapitre après celle du non-blocage. Retenez d'ores et déjà la phrase de synthèse : une interruption signale un événement, elle ne le traite pas.
$lesson$),
  ('ard-c4-p9', 'ard-c4', 9, $lesson$Le fonctionnement matériel d'un GPIO en interruption$lesson$, $lesson$
Pour écrire des interruptions fiables, il faut savoir ce qui se passe physiquement dans la broche. Un GPIO moderne n'est pas un simple fil : c'est un circuit capable de comparer en continu son état à celui qu'il avait au tour précédent, de filtrer les rebonds les plus évidents et de signaler tout écart à la logique centrale. Quand vous appelez attachInterrupt, vous demandez à ce comparateur de déclencher une alerte selon un critère que vous choisissez, appelé mode de déclenchement. Le choix de ce mode découle directement du câblage, et le choisir à l'aveugle est l'erreur la plus fréquente chez les débutants, qui se retrouvent alors avec un déclenchement permanent ou, au contraire, aucun déclenchement du tout.

Le tableau des modes courants se lit facilement une fois le câblage compris. Le mode front montant se déclenche lorsque la broche passe du niveau bas au niveau haut ; le mode front descendant, l'inverse ; le mode changement, dans les deux sens. Les modes de niveau bas et de niveau haut sont plus dangereux, car ils maintiennent l'interruption active tant que la condition reste vraie, ce qui peut noyer le processeur sous les appels. Dans le cas le plus classique, un bouton relié entre la broche et la masse avec un pull-up interne, la broche est à l'état haut au repos et descend à zéro quand on appuie : le mode front descendant est donc exactement celui qui correspond à l'instant de l'appui.

| Mode | Condition de déclenchement | Câblage typique |
|---|---|---|
| RISING | Passage de 0 à 1 | Bouton relié à l'alimentation, résistance de rappel vers la masse |
| FALLING | Passage de 1 à 0 | Bouton relié à la masse, pull-up interne actif |
| CHANGE | Tout changement d'état | Compteur d'impulsions, capteur à frequency |
| LOW | Broche maintenue à 0 | Réveil périodique, cas particuliers |
| HIGH | Broche maintenue à 1 | Déconseillé, risque de tempête d'interruptions |

Trois précautions matérielles accompagnent toujours ce choix. La première est le pull-up : sans lui, la broche est flottante, c'est-à-dire qu'elle capte les parasites alentour et déclenche des interruptions au hasard ; activez le pull-up interne avec INPUT_PULLUP, ou placez une résistance externe de dix kilo-ohms. La seconde est l'antirebond : un contact mécanique rebondit plusieurs millisecondes avant de se stabiliser, ce qui produit une série de fronts au lieu d'un seul. La troisième est le numéro de broche : toutes les broches d'une carte ne sont pas reliées au module d'interruption, et la fonction digitalPinToInterrupt traduit le numéro de broche en le bon numéro de canal, ce qui rend votre code portable d'une carte à l'autre.

```cpp
const int BOUTON = 4;
volatile unsigned long derniereIsr = 0;

void ISR_front() {
  unsigned long m = millis();
  if (m - derniereIsr > 30) {   // filtre anti-rebond minimal
    derniereIsr = m;
    appuiDetecte = true;
  }
}

void setup() {
  pinMode(BOUTON, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(BOUTON), ISR_front, FALLING);
}
```

Le filtre anti-rebond placé dans la routine mérite une explication, car il enfreint apparemment la règle de brièveté que nous allons poser dans la section suivante. Comparer une variable à millis() reste une opération très courte, de l'ordre de quelques dizaines d'instructions, et il n'existe guère d'endroit plus fiable pour éliminer les rebonds : détecter le premier front, ignorer tout ce qui arrive pendant les trente millisecondes qui suivent, puis considérer l'appui comme consommé. Une alternative consiste à ne filtrer que dans la boucle, en conservant l'instant du dernier front, mais la boucle peut être occupée au moment du rebond, et le filtre perd alors son efficacité. Choisissez la méthode selon la sensibilité de votre objet, mais ne l'oubliez jamais : un bouton non filtré produit des dizaines d'appui pour une seule pression, et c'est la cause directe des automates qui semblent sauter plusieurs états d'un coup.
$lesson$),
  ('ard-c4-p10', 'ard-c4', 10, $lesson$Variables volatile et brièveté absolue$lesson$, $lesson$
Voici maintenant la règle qui sépare une interruption qui fonctionne de celle qui marche parfois, selon le niveau d'optimisation du compilateur. Une variable modifiée dans une routine d'interruption et lue dans la boucle doit obligatoirement être déclarée volatile. Ce mot n'ajoute aucune fonctionnalité au programme, il empêche seulement le compilateur d'optimiser les accès : sans lui, il est parfaitement en droit de charger la variable une seule fois dans un registre, de réutiliser cette valeur pendant tout le bloc de code, et d'ignorer ainsi indéfiniment les écritures survenues entre-temps. Le programme compile sans aucun avertissement, le comportement est correct pendant quelques exécutions, puis la boucle cesse de voir les appuis, sans que rien n'ait changé dans votre code. C'est l'un des bugs les plus déroutants du débutant, et il disparaît dès que le mot volatile est ajouté.

```cpp
volatile bool demande = false;
volatile unsigned long impulsions = 0;

void ISR_capteur() {
  impulsions++;              // lecture-modification-écriture protégée
}

void setup() {
  attachInterrupt(digitalPinToInterrupt(CAPTEUR), ISR_capteur, RISING);
}

void loop() {
  if (demande) {
    demande = false;
    Serial.println(impulsions);
  }
}
```

La seconde règle, tout aussi impérative, est la brièveté. Une interruption suspend toutes les autres activités du système, y compris les autres interruptions de priorité plus faible, jusqu'à son retour. Si votre routine met une dizaine de millisecondes à terminer, tout le reste du système est gelé pendant ce temps : l'afficheur ralentit, les communications se dégradent, les mesures manquent leur fenêtre. La pratique professionnelle consiste à ne faire dans une interruption que trois choses : lire le registre qui a déclenché l'événement, incrémenter un compteur ou poser un drapeau, puis rendre la main. Tout le traitement lourd — calculs, affichage, décisions d'automate, écriture série — appartient à la boucle, qui s'exécute à un moment choisi et sans contrainte de latence.

Un troisième point concerne les fonctions que l'on appelle depuis une interruption. Les fonctions digitalWrite et digitalRead sont parfaitement utilisables dans ce contexte sur les cartes Arduino classiques, mais les appels lourds, les transmissions série, les attentes et les bibliothèques qui font elles-mêmes des temporisations sont proscrits. Sur l'ESP32, certaines fonctions ne sont pas placées dans la mémoire rapide interne, ce qui provoque un échec silencieux si l'interruption survient au moment où le processeur exécute justement une fonction absente de cette mémoire. La macro IRAM_ATTR, que nous verrons dans la section suivante, sert précisément à garantir que le code de la routine est toujours accessible au moment critique. Au-delà de ces détails, gardez le réflexe de conception : d'abord écrire la routine la plus courte possible, puis seulement, si c'est indispensable, déplacer une partie du travail dans la boucle.

- Déclarez volatile toute variable partagée entre une interruption et la boucle.
- Limitez la routine à la pose d'un drapeau ou à l'incrémentation d'un compteur.
- Filtrez les rebonds, dans la routine ou immédiatement après dans la boucle.
- N'appelez jamais delay, Serial.print ni une bibliothèque lourde depuis une interruption.
- Utilisez digitalPinToInterrupt pour rester portable d'une carte à l'autre.
$lesson$),
  ('ard-c4-p11', 'ard-c4', 11, $lesson$Les timers matériels de l'ESP32$lesson$, $lesson$
Les interruptions déclenchées par une broche répondent à un événement imprévisible. L'ESP32 fournit une seconde famille d'interruptions, déclenchée non par une broche mais par le temps : les timers matériels. L'idée est exactement la même que celle du compteur millis(), mais le déclenchement n'est plus effectué par la boucle, il est effectué par un circuit horloge qui ne dépend d'aucun code. Votre boucle peut être occupée, en train d'envoyer des données ou de rafraîchir un écran, le timer déclenchera malgré tout sa routine à la milliseconde près. C'est l'outil de choix pour les clignotements réguliers, les échantillonnages périodiques et toutes les temporisations dont la précision doit être indépendante de la charge du programme.

L'API moderne de l'ESP32 organise ces timers en quatre opérations : créer le timer avec timerBegin, attacher sa routine avec timerAttachInterrupt, programmer sa fréquence avec timerAlarmWrite, puis l'activer ou l'arrêter selon les besoins. La fréquence s'exprime en hertz, et la valeur d'alarme en nombre de cycles de ce timer : pour un clignotement de cinq cents millisecondes sur un timer cadencé à un mégahertz, on demande une alarme tous les mille cycles. La fonction de rappel reçoit automatiquement l'attribut IRAM_ATTR lorsque vous le spécifiez, ce qui garantit que son code réside en mémoire rapide et reste exécutable même pendant une opération d'accès à la flash.

```cpp
hw_timer_t *timerClignote = NULL;
volatile bool tickTimer = false;

void IRAM_ATTR ISR_timer() {
  tickTimer = true;
}

void setup() {
  timerClignote = timerBegin(0, 80, true);              // timer 0, diviseur 80
  timerAttachInterrupt(timerClignote, &ISR_timer, true);
  timerAlarmWrite(timerClignote, 500000, true);         // 500 ms à 1 MHz
  timerAlarmEnable(timerClignote);
}

void loop() {
  if (tickTimer) {
    tickTimer = false;
    digitalWrite(LED, !digitalRead(LED));
  }
}
```

Observez que la boucle ne fait qu'attendre le drapeau et basculer la broche : elle pourrait passer dix secondes à faire autre chose, le clignotement resterait millimétriquement régulier. C'est la différence fondamentale avec la temporisation fondée sur millis, dont la régularité dépend de la fréquence à laquelle la boucle passe tester la condition. Pour un feu de signalisation ou un afficheur, les deux méthodes sont amplement suffisantes ; pour un échantillonnage de signal ou une communication temporisée, seul le timer matériel donne une garantie réelle. L'ESP32 en embarque plusieurs, indépendants les uns des autres, ce qui permet d'en réserver un à l'acquisition, un autre au clignotement, sans qu'ils se perturbent.

La question de l'accès concurrent se pose dès que deux contextes modifient la même donnée. Si la boucle lit un compteur d'impulsions pendant que la routine d'interruption l'incrémente, une lecture peut survenir au milieu de la mise à jour et renvoyer une valeur intermédiaire, fausse mais temporaire. Les compteurs de taille réduite, un booléen ou un entier de huit bits, sont écrits de manière atomique sur ce type de processeur et ne posent généralement pas de problème ; les valeurs de trente-deux bits demandent davantage de prudence, et les données de plus de quatre octets doivent être protégées en désactivant brièvement les interruptions autour de la lecture. La fonction noInterrupts et sa contrepartie interrupts entourent cette section critique, qui doit rester strictement minimale, car pendant son exécution, plus aucun événement n'est servi.

Il existe enfin une troisième source de déclencheur, à connaître pour ne pas en être victime : le watchdog, ou chien de garde logiciel. L'ESP32 dispose d'un timer de surveillance qui redémarre le microcontrôleur si la boucle cesse de le rafraîchir trop longtemps, signe habituel d'une boucle bloquée ou d'une deadlock. Dans un automate correctement construit, le rafraîchissement s'effectue naturellement en début de boucle et vous n'avez rien à faire ; en revanche, si vous introduisez à nouveau un délai long, le chien de garde déclenchera un redémarrage dont la cause sera difficile à relier à votre attente. Considérez ses réinitialisations inattendues comme le symptôme d'une temporisation qui serait revenue en bloc, pas comme un défaut matériel.

Toutes les pièces du puzzle sont maintenant sur la table : la modélisation par états, la structure de boucle, les temporisations fondées sur millis et les interruptions matériques. Cette section les assemble dans un programme complet, le feu piéton que nous avions dessiné au début de la leçon. Le but n'est pas de vous faire copier un listing, mais de vous montrer la méthode de construction dans l'ordre : on écrit d'abord le enum et les variables d'état, puis la fonction d'entrée, puis les transitions temporelles, ensuite les interruptions, enfin les affichages. Chaque étape est testable isolément, ce qui réduit considérablement le temps de mise au point, parce qu'une erreur est toujours localisée dans la partie que vous venez d'écrire et non quelque part dans un listing de deux cents lignes.
$lesson$),
  ('ard-c4-p12', 'ard-c4', 12, $lesson$Exemple guidé : le feu piéton non bloquant$lesson$, $lesson$
Le système comporte deux séquences principales. Pendant la première, les voitures circulent sur fond de vert pendant huit secondes, puis le feu jaune s'allume pendant deux secondes avant le passage piéton. Pendant la seconde, les piétons traversent sur fond de rouge voiture pendant huit secondes, le jaune piéton clignote pendant deux secondes, et le cycle recommence. Le bouton d'appel n'accélère rien pendant qu'un piéton traverse — c'est un choix de conception explicite, les transitions pendant une traversée seraient dangereuses — mais il est mémorisé et traité juste après la fin du cycle en cours. Le schéma ci-dessous reprend le modèle, en y ajoutant la branche du bouton, qui constitue la seule transition déclenchée par une interruption plutôt que par le temps.

```text
   +----------------+   8 s   +--------------+   2 s   +----------------+
   | VOIT VERT      | ------->| VOIT JAUNE   | ------->| PIETON ROUGE   |
   +----------------+         +--------------+         +----------------+
          ^                                                   |
          |                                    clignotement   |
          |                                    500 ms x 16    |
          |                                                   v
   +----------------+   2 s   +----------------+   8 s   +--------------+
   | PIETON JAUNE   | <-------| FIN CROSSE    | <------| (meme etat)   |
   +----------------+         +----------------+         +--------------+
          ^                         ^
          +-------------------------+  bouton memorise (interruption)
```

Le listing suivant est volontairement complet, mais il reste lisible parce que chaque responsabilité occupe sa propre fonction. La fonction entrerEtat assure les actions d'entrée, gererTransitions gère les échéances, la routine d'interruption ne pose qu'un drapeau, et loop se contente d'enchaîner les trois appels standards. Observez surtout la façon dont debutEtat est réinitialisé à chaque changement d'état : c'est cette ligne unique qui garantit que toutes les temporisations repartent de zéro, et son oubli est la panne la plus fréquente sur ce type de programme.

```cpp
const int LED_V = 4, LED_J = 5, LED_R = 6;
const int BTN = 2;

enum class Etat { VOIT_VERT, VOIT_JAUNE, PIETON, PIETON_JAUNE };
Etat courant = Etat::VOIT_VERT;
unsigned long debut = 0;
volatile bool demande = false;

void entrerEtat(Etat suivant) {
  courant = suivant;
  debut = millis();
  digitalWrite(LED_V, suivant == Etat::VOIT_VERT);
  digitalWrite(LED_J, suivant == Etat::VOIT_JAUNE || suivant == Etat::PIETON_JAUNE);
  digitalWrite(LED_R, suivant == Etat::PIETON || suivant == Etat::PIETON_JAUNE);
}

void gererTransitions() {
  unsigned long e = millis() - debut;
  switch (courant) {
    case Etat::VOIT_VERT:
      if (e > 8000) entrerEtat(Etat::VOIT_JAUNE);
      break;
    case Etat::VOIT_JAUNE:
      if (e > 2000) entrerEtat(Etat::PIETON);
      break;
    case Etat::PIETON:
      if (e > 8000) entrerEtat(Etat::PIETON_JAUNE);
      break;
    case Etat::PIETON_JAUNE:
      if (e > 2000) entrerEtat(Etat::VOIT_VERT);
      break;
  }
}
```

Deux détails de ce listing méritent une attention particulière. Le premier est l'absence totale de délai : aucune ligne du programme ne suspend l'exécution, ce qui signifie que la lecture du bouton, si vous en ajoutez une, reste possible pendant les huit secondes de traversée. Le deuxième est l'emploi du switch sur le enum, qui se lit comme une table de vérité et que l'éditeur signalera si vous oubliez un cas. Là où une succession de if imbriqués devient rapidement illisible, le switch conserve une structure plate, une branche par état, exactement comme le demandait le modèle. Le drapeau demande, posé par l'interruption, serait consommé en tête de gererTransitions : s'il est vrai et si l'état le permet, on force une transition, sinon on l'ignore en le réinitialisant simplement, sans perdre l'événement pour autant.

L'initialisation mérite elle aussi d'être écrite avec soin, car c'est souvent là que se cachent les démarrages bizarres. On configure les broches en sortie, on active le pull-up interne du bouton, on attache l'interruption sur le front descendant, on écrit l'état initial avec entrerEtat — et non par une affectation directe, afin que les sorties soient cohérentes dès la première milliseconde — puis on lance éventuellement une temporisation matérielle pour le clignotement. Un point fréquent sur l'ESP32 : certaines broches ont des niveaux d'appelage particuliers au démarrage et peuvent faire clignoter brièvement une LED connectée. Si cela gêne votre montage, choisissez une broche sans fonction strapping ou ajoutez une résistance de rappel : le logiciel ne peut pas toujours compenser une décision de câblage.
$lesson$),
  ('ard-c4-p13', 'ard-c4', 13, $lesson$Mémoriser les appuis sans en perdre aucun$lesson$, $lesson$
Le bouton est l'entrée la plus simple du projet et, paradoxalement, celle qui pose le plus de questions une fois que l'automate fonctionne. La première difficulté tient à la durée : un appui humain dure entre cinquante et trois cents millisecondes, ce qui est une éternité pour le processeur et un instant pour le programmeur qui vérifie sa broche une fois par tour de boucle. Si vous lisez l'entrée à une cadence suffisante, vous ne ratez rien ; si la boucle porte une tâche longue, l'appui entier peut se produire entre deux lectures. C'est précisément le cas que la résout l'interruption : elle mémorise l'événement au moment exact où il se produit, quelle que soit l'occupation du processeur, et la boucle en prend connaissance plus tard sans que l'information ait été perdue.

La difficulté suivante est sémantique et n'a rien d'automatique : que signifie un appui dans l'état courant ? Sur notre feu, un appel pendant la traversée ne doit pas provoquer de transition immédiate, mais il ne doit pas non plus être jeté, car l'usager qui appuie alors attend toujours que le passage suivant soit autorisé. On stocke donc la demande dans une variable, drapeau, et on la consomme au moment où elle devient utile, c'est-à-dire juste avant de quitter l'état où un nouvel appel a du sens. Ce décalage entre la détection et le traitement est un motif extrêmement courant : l'interruption capture l'instant, la boucle décide de l'opportunité. Il vous évite de créer des états supplémentaires purement mécaniques et conserve le modèle lisible.

```cpp
volatile bool appelMemorise = false;
unsigned long dernierFront = 0;

void ISR_bouton() {
  unsigned long m = millis();
  if (m - dernierFront > 30) {     // anti-rebond
    dernierFront = m;
    appelMemorise = true;
  }
}

void gererTransitions() {
  if (appelMemorise && peutAutoriserPassage()) {
    appelMemorise = false;
    forcerPassagePieton();
    return;
  }
  appelMemorise = false;           // appel hors période utile : on l'ignore
  // ... transitions temporelles habituelles
}
```

Le second bloc de code montre une variante utile lorsque l'appui doit être traité même s'il arrive pendant une attente : on conserve l'instant de l'appui dans une variable de données et on le compare ensuite à une échéance, ce qui permet de prolonger ou de raccourcir un état en cours sans interrompre quoi que ce soit. C'est la même mécanique que les temporisations, appliquée à une entrée plutôt qu'à une durée, et elle se combine naturellement avec elles : un état peut à la fois avoir une échéance propre et une échéance reportée par un appui. Pour garder la maîtrise du code, préférez toujours une règle unique par état, écrite en une ligne, du type si appel pendant cet état alors prolonger de deux secondes, plutôt qu'une accumulation de cas particuliers empilés les uns derrière les autres.

Enfin, testez le comportement du bouton indépendamment du reste de l'automate avant de l'intégrer. Un sketch minimal qui n'affiche sur le port série que le numéro et l'instant de chaque front filtré vous met en confiance en quelques secondes et fait apparaître les défauts de câblage, les rebonds trop longs ou le mauvais mode d'interruption, bien avant que vous n'ayiez à déboguer la logique complète. Ce réflexe de test isolé est celui des équipes qui livrent à temps : on valide chaque brique dans un banc de test dédié, puis on les assemble. Vous l'appliquerez tout naturellement au projet connecté du chapitre suivant, où le bouton deviendra peut-être une commande venue du réseau, mais où la règle restera inchangée : capturer l'événement tôt, le traiter au bon moment, ne jamais bloquer la boucle.
$lesson$),
  ('ard-c4-p14', 'ard-c4', 14, $lesson$Débogage de l'automate$lesson$, $lesson$
Un automate correctement modélisé se débogue d'une manière très particulière, beaucoup plus efficace que la débogage classique : on observe les transitions plutôt que les variables. Tant que vous cherchez pourquoi une LED ne s'allume pas, vous inspectez des niveaux logiques ; dès que vous imprimez l'état courant et l'instant de chaque changement, vous voyez immédiatement laquelle des transitions n'a pas eu lieu, ou a eu lieu trop tôt. La trace ci-dessous est produite par deux lignes de code ajoutées dans entrerEtat, et elle suffit presque toujours à localiser l'erreur en une seule lecture.

```text
1204 ms  etat -> VOIT_VERT    entree
9210 ms  etat -> VOIT_JAUNE   timeout 8000
11215 ms etat -> PIETON       timeout 2000
19220 ms etat -> PIETON_JAUNE timeout 8000
19222 ms bouton memorise pendant la traversee
21225 ms etat -> VOIT_VERT    timeout 2000
```

Les anomalies les plus courantes ont une signature facile à reconnaître. Si les durées observées sont systématiquement supérieures aux durées demandées, c'est que la boucle met du temps à repasser tester la condition : cherchez un appel long, une émission série abondante ou une lecture de capteur coûteuse. Si les transitions se produisent dès le démarrage, c'est que debut n'a pas été initialisé à millis() dans setup, et que le compteur part de zéro. Si l'automate semble sauter un état, comptez les fronts sur la broche du bouton : il y en a probablement plusieurs, et le filtre anti-rebond n'a pas été posé. Si rien ne se déclenche alors que les mêmes conditions fonctionnent dans un test isolé, vérifiez que vous comparez bien millis() - debut à la durée, et non millis() à debut + durée cumulée depuis le démarrage.

Une méthode de débogage particulièrement rentable consiste à rendre l'automate pilotable depuis le port série, temporairement. En ajoutant dans la boucle une lecture d'un caractère et en associant chaque lettre à une transition forcée, vous pouvez déclencher à la main chaque branche du schéma sans attendre les huit secondes du cycle réel. Cette technique transforme une attente de minutes en un test de quelques secondes, et elle permet de valider toutes les transitions, y compris les rares, comme la sortie d'une erreur ou la reprise après débordement, que le comportement normal ne déclenche qu'une fois par heure. Une fois les transitions vérifiées, vous retirez le pont série et votre objet redevient autonome.

Un réflexe complémentaire consiste à afficher non seulement l'état, mais aussi l'entrée qui a motivé le changement. Dire que l'automate est passé à l'état VOIT_JAUNE est utile ; dire qu'il y est passé parce que la durée de huit mille millisecondes est écoulée ou parce que le bouton a été enfoncé, c'est répondre à la question qui compte vraiment. Cette discipline paraît lourde au départ, mais elle réduit le temps total de mise au point de manière spectaculaire, et elle vous donne en outre un journal que vous pourrez joindre à la livraison de votre projet, exactement comme le demande l'exercice pratique de ce chapitre.
$lesson$),
  ('ard-c4-p15', 'ard-c4', 15, $lesson$Bonnes pratiques de conception$lesson$, $lesson$
Les règles qui suivent sont issues de projets réels et se vérifient toutes les fois où un automate a dû être réparé en production. Elles tiennent en peu de points, mais chacune correspond à une famille de pannes que vous éviterez intégralement en les appliquant.

- Écrivez le schéma d'états avant le code, et gardez-le à côté de vous pendant l'écriture.
- Nommez les états avec des mots entiers, jamais des nombres ni des lettres isolées.
- Centralisez les actions d'entrée dans une fonction unique, appelée à chaque transition.
- Affectez debut à millis() dans cette fonction, sans exception.
- Ne faites jamais appel à delay dans un objet interactif, même pour tester.
- Posez les drapeaux dans les interruptions, tranchez-les dans la boucle.
- Imprimez l'état et le motif de chaque transition lors de la mise au point.
- Limitez le nombre d'états : si vous dépassez six ou sept, une décision est mal rangée.

Une remarque sur l'évolution d'un projet : un automate grandit rarement tout seul, il grandit parce qu'on lui ajoute un comportement, une nouvelle entrée, un mode dégradé. Chaque ajout doit passer par la même question : quel est l'état supplémentaire, quelles transitions entrent et sortent, quelles actions sont concernées. Si la réponse tient en trois lignes sur papier, l'ajout au code tiendra en dix ; si la réponse est floue sur papier, le code sera bâclé et les régressions apparaîtront à l'usage. Cette rigueur est la différence entre un sketch qui fonctionne une fois et un firmware qui tourne pendant des années sans intervention, et c'est exactement l'état d'esprit attendu au chapitre suivant, où l'objet se connectera au réseau sans que sa logique interne change d'un iota.

Avant de conclure, il reste utile de réunir dans un même endroit les formes typiques d'automates que vous rencontrerez, afin que vous puissiez repérer au premier regard celle dont votre projet est proche. Trois structures couvrent la grande majorité des cas de l'embarqué débutant, et chacune se distingue par la nature de ses conditions de transition plutôt que par son code.

| Structure | Déclencheurs principaux | Exemple type |
|---|---|---|
| Automate temporel | Écoulement de millis, timers matériels | Feu tricolore, séquenceur de démarrage |
| Automate à événements | Fronts sur broches, messages série, interruptions | Bouton d'appel, détection de presence |
| Automate à données | Seuils sur capteurs, comparaisons de mesures | Thermostat, détection d'ouverture de porte |
| Automate hybride | Combinaison des trois | Feu piéton avec bouton, robot évitement d'obstacle |

La distinction pratique est la suivante : si vos transitions dépendent surtout du temps, un seul compteur et un switch suffisent ; si elles dépendent d'événements imprévisibles, prévoyez dès le départ des drapeaux posés par des interruptions ; si elles dépendent de mesures, ajoutez une couche de filtrage et de seuils hystérésis pour éviter que l'automate ne risque entre deux états à cause du bruit électrique. Dans tous les cas, la structure du programme reste identique : une variable d'état, une fonction de transition, une fonction d'entrée, et une boucle libre de toute attente. C'est cette uniformité qui rend la méthode si polyvalente : vous changez les conditions, jamais le squelette.

Un mot sur la manière de faire évoluer un automate sans casser ce qui existe déjà. L'erreur classique consiste à ajouter un état en dupliquant une branche existante, ce qui multiplie les risques de divergence entre deux parties du code qui devraient faire la même chose. Préférez extraire les actions récurrentes dans des fonctions nommées par leur intention, allumerPhasesJour, demarrerClignotement, arreterBuzzer, puis appeler ces fonctions depuis les branches concernées. Le listing reste court, l'intention reste lisible, et la correction d'un bug d'allumage est appliquée partout d'un seul coup. Cette extraction progressive est exactement la façon dont les projets industriels se maintiennent sur plusieurs années, avec des équipes successives et des demandes d'évolution imprévues.
$lesson$),
  ('ard-c4-p16', 'ard-c4', 16, $lesson$À retenir$lesson$, $lesson$
Les idées de ce chapitre forment un ensemble cohérent : elles partent toutes du même constat, un objet réactif ne doit jamais attendre, et elles aboutissent toutes à la même architecture, un état courant, des transitions testées à chaque tour de boucle, des interruptions qui signalent sans traiter. Voici l'essentiel, formulé pour être relu juste avant de commencer un projet.

- Un automate est un ensemble fini d'états, dont un seul est actif à la fois.
- Chaque transition associe une condition à un changement d'état et à ses actions.
- Représentez les états avec un enum, jamais avec des nombres bruts.
- Regroupez les actions d'entrée dans une fonction unique appelée à chaque transition.
- Replacez chaque delay par un couple debut plus duree testé avec millis().
- Soustrayez les instants plutôt que de les comparer à une somme, pour rester correct après débordement.
- Une interruption pose un drapeau volatile ; la boucle le consomme et applique la logique.
- Limitez la routine d'interruption à quelques instructions, sans affichage ni calcul.
- Utilisez attachInterrupt avec le mode qui correspond au câblage réel de votre entrée.
- Sur l'ESP32, confiez les temporisations critiques à un timer matériel et son rappel à IRAM_ATTR.
- Imprimez l'état et le motif de chaque transition : c'est le débogage le plus rentable.
$lesson$),
  ('ard-c4-p17', 'ard-c4', 17, $lesson$Erreurs fréquentes$lesson$, $lesson$
La première erreur, et de loin la plus répandue, est de conserver un delay quelque part dans la boucle, même bref, en se disant qu'il ne gênera personne. Les conséquences sont alors incompréhensibles : des appuis manqués qui ne se produisent que parfois, des mesures irrégulières, un afficheur qui ralentit. La seconde est l'oubli du mot volatile, qui produit un comportement apparemment aléatoire, correct sous le débogueur et faux en exécution optimisée. La troisième est un debutEtat non réinitialisé à l'entrée d'un état, d'où des transitions immédiates au démarrage ou des durées qui dépendent du chemin parcouru auparavant.

- Delay résiduel dans la boucle : le programme redevient sourd.
- Variable partagée non volatile : la boucle lit une valeur périmée.
- debut non remis à jour dans entrerEtat : les durées deviennent imprévisibles.
- Comparaison millis() > debut + durée : échec après débordement du compteur.
- Antirebond absent : un seul appui génère une série de transitions.
- Mode d'interruption inadapté au câblage : déclenchement permanent ou jamais.
- Routine d'interruption trop longue : le reste du système se fige.
- Compteur partagé de grande taille lu sans protection : lecture d'une valeur intermédiaire.
- États trop nombreux : la logique se disperse et devient difficile à tester.
- Sorties oubliées à l'entrée d'un état : une LED reste allumée d'un état à l'autre.

Une erreur plus subtile mérite d'être signalée, celle du faux positif dû au bruit électrique sur une broche non tirée. Le symptôme est un automate qui change d'état tout seul, sans cause apparente, surtout à proximité d'un moteur, d'un relais ou d'un câble long. La solution combine un pull-up ou un pull-down explicite, une résistance de filtrage si nécessaire, et un seuil de durée minimal exigé avant d'accepter la transition. En embarqué, la qualité du signal fait partie du programme : un code impeccable branché sur une broche flottante restera injustifiablement capricieux.
$lesson$),
  ('ard-c4-p18', 'ard-c4', 18, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation officielle reste la meilleure source pour approfondir, car elle décrit précisément le comportement de chaque fonction sur la carte que vous utilisez. Pour les interruptions Arduino, la page de référence de attachInterrupt récapitule les modes acceptés, la signification de digitalPinToInterrupt et les cartes concernées : https://www.arduino.cc/reference/en/language/functions/external-interrupts/attachinterrupt/ . Pour la gestion du temps non bloquant, la page de millis() explique la portée du compteur et son débordement : https://www.arduino.cc/reference/en/language/functions/time/millis/ . Du côté d'ESP32, les documents Espressif détaillent les timers matériels, leurs registres et leurs rappels : https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/timer.html , ainsi que la gestion des interruptions GPIO : https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html .

Au-delà de la documentation, deux lectures vous feront progresser rapidement. La première concerne les patrons de conception applicables à l'embarqué, et en particulier la séparation entre la partie qui décide et la partie qui exécute, qui est le prolongement naturel de ce chapitre lorsque votre programme dépasse quelques centaines de lignes. La deuxième concerne le temporisateur logiciel des systèmes d'exploitation, qui généralise l'idée du timer matériel en permettant à plusieurs tâches de partager le processeur selon des priorités : les notions de drapeau, de routine courte et de contexte d'exécution que vous venez d'apprendre s'y retrouvent à l'identique, avec en plus la notion de verrou. Pratiquez d'abord sur de petits objets : un feu, une porte, une alarme, un compteur d'objets. Chaque automate que vous écrirez ajoutera une transition à votre répertoire personnel et rendra le suivant plus rapide à concevoir.
$lesson$),
  ('ard-c4-p19', 'ard-c4', 19, $lesson$Et maintenant : modélisez votre propre machine à états$lesson$, $lesson$
Les schémas de ce chapitre — feux tricolores, portes, alarmes — ne sont que des variations d'une même idée : un état courant, des transitions et des actions. Dans l'exercice pratique, modélisez un objet de votre choix (un sèche-linge, un distributeur, une barrière de parking) sous forme de machine à états, en listant d'abord les états et les transitions sur papier avant d'écrire une seule ligne de code. La qualité d'un automate se juge à la clarté de sa table de transitions, pas à sa longueur.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('ard-c5-p1', 'ard-c5', 1, $lesson$Le réseau de votre objet : adresse IP, passerelle, DNS$lesson$, $lesson$
Bienvenue dans ce cinquième chapitre du parcours Arduino et ESP32 embarqué, celui où votre objet quitte enfin l'isolement. Jusqu'ici, vos programmes lisaient des capteurs, allumaient des LED et prenaient des décisions tout seuls, sur une seule carte posée sur votre bureau. À partir de maintenant, la même carte va parler au monde extérieur : elle se connectera à votre réseau local, exposera une page web que n'importe quel navigateur peut ouvrir, et publiera ses mesures vers un service de messagerie pensé pour les machines. C'est le saut qualitatif qui distingue une démonstration de tableur d'un véritable objet connecté : la mesure n'est plus seulement affichée sur un écran, elle devient disponible à distance, horodatée, lisible par un tableau de bord, une application mobile ou une règle d'alerte. Ce chapitre suppose que vous maîtrisez déjà les bases des chapitres précédents, en particulier les machines à états et les temporisations non bloquantes de la leçon sur les automates, car tout le code réseau que vous allez écrire repose sur cette discipline : une boucle principale qui tourne vite, jamais interrompue par un délai long.

À la fin de cette leçon, vous saurez faire quatre choses concrètes, et vous les aurez déjà écrites dans du code complet. Premièrement, vous connecterez l'ESP32 en Wi-Fi en mode station, c'est-à-dire en client de votre routeur, avec une stratégie de connexion qui ne fige pas le programme. Deuxièmement, vous ferez tourner un serveur web sur la puce elle-même, capable de servir une page HTML à un navigateur et de répondre à des routes d'API au format JSON. Troisièmement, vous publierez des mesures en MQTT sur un broker, puis vous vous abonnerez à un topic pour recevoir des commandes à distance. Quatrièmement, vous rendrez tout cela robuste : reconnexion automatique avec retard croissant, gestion de la perte de réseau, journal de débogage sur le port série et chien de garde logiciel. Ces quatre compétences sont exactement celles que l'on demande en production sur un microcontrôleur connecté, et le projet fil rouge du chapitre, une station météo connectée, les réunit toutes dans un seul sketch que vous récrirez seul dans l'exercice pratique.

Un mot sur la manière d'aborder ce chapitre, car le réseau est un domaine où les débutants se découragent vite. Un programme qui ne fonctionne pas alors qu'il « a l'air correct » est ici la norme, pas l'exception : le réseau ajoute une couche d'incertitude qui n'existe pas quand on lit une broche. Le routeur est-il joignable ? Le mot de passe est-il exact ? Le broker écoute-t-il sur cette adresse ? Le pare-feu bloque-t-il le port ? Plutôt que de subir ces questions, vous allez apprendre à les poser méthodiquement, dans l'ordre, en affichant chaque étape sur le moniteur série. La règle d'or du développeur d'objets connectés tient en une phrase : affichez toujours ce que vous faites, avant, pendant et après chaque étape réseau. Une ligne de journal qui dit wifi: connexion en cours puis wifi: IP obtenue 192.168.1.42 vous fait gagner une heure par rapport à un programme muet qui affiche simplement rien. Nous adopterons ce réflexe dès le premier exemple, et nous le conserverons jusqu'au dernier.



Avant d'écrire une seule ligne de code, il faut partager un vocabulaire. Un réseau local, typiquement celui de votre domicile ou de votre atelier, est un ensemble d'appareils qui peuvent s'envoyer des paquets. Le routeur, souvent la box fournie par votre opérateur, joue deux rôles à la fois : il distribue des adresses à chaque appareil qui se connecte, et il relaie le trafic vers l'extérieur, c'est-à-dire vers Internet. Chaque appareil du réseau local reçoit une adresse unique de la forme 192.168.1.34, appelée adresse IP. Cette adresse sert d'identifiant postale : pour parler à votre ESP32, un autre appareil doit connaître cette adresse, ou du moins un nom qui la désigne.

L'adresse IP est composée de deux parties, séparées par le masque de sous-réseau. Si le masque est 255.255.255.0, les trois premiers octets désignent le réseau, le dernier l'hôte. Ainsi 192.168.1.34 et 192.168.1.99 sont sur le même réseau et peuvent dialoguer directement, tandis que 192.168.2.50 en fait partie : il faudra passer par la passerelle, qui est l'adresse du routeur sur ce réseau, souvent 192.168.1.1. Enfin, pour rejoindre un serveur d'internet, il faut résoudre son nom en adresse avec le service DNS, généralement assuré par le routeur lui-même. Ces trois pièces, adresse locale, passerelle et DNS, sont exactement les trois informations que votre ESP32 devra obtenir du routeur lors de la connexion.

Le protocole qui distribue ces informations s'appelle DHCP. À chaque mise en route, l'ESP32 envoie une demande de broadcast, le routeur répond avec une offre, et la négociation se conclut par la concession d'une adresse pour une durée limitée, appelée bail. Ce mécanisme explique deux phénomènes que vous rencontrerez. D'abord, l'adresse de votre carte peut changer d'un redémarrage à l'autre si le bail n'est pas renouvelé à l'identique. Ensuite, si aucune adresse n'est attribuée, c'est que la demande DHCP n'a pas reçu de réponse : le réseau n'est pas joignable, ou le mot de passe était refusé. Un schéma résume la chaîne complète, du capteur jusqu'à l'utilisateur final.

```
   [ DHT22 ]--GPIO--> [ ESP32 192.168.1.42 ]
                           |
                           | Wi-Fi (station, DHCP)
                           v
                    [ Routeur 192.168.1.1 ] ---- Internet
                      |         |                    |
                      |         |                    +--> [ Broker MQTT ]
                      |         +--> [ PC, tableur ]         easylearn/...
                      +--> [ Smartphone, navigateur ]
```

Une dernière distinction vaut la peine d'être mémorisée, car elle revient dans toutes les documentation : le mode station et le mode point d'accès. En mode station, l'ESP32 est un client, exactement comme votre téléphone : il se connecte à un réseau existant et en obtient une adresse. En mode point d'accès, l'ESP32 devient lui-même un mini-routeur, il émet son propre réseau auquel d'autres appareils se raccordent. Les deux modes peuvent coexister, c'est le mode combiné, que nous utiliserons plus loin pour créer un portail de configuration de secours. Dans ce chapitre, le mode station est la base : c'est lui qui permet à votre objet de rejoindre le réseau que vous utilisez déjà au quotidien.

Voici un tableau des états renvoyés par la bibliothèque Wi-Fi après une tentative de connexion. Les connaître vous permet de transformer un silence incompréhensible en un diagnostic précis.

| Constante | Valeur | Signification pratique |
| --- | --- | --- |
| WL_IDLE_STATUS | 0 | La carte initialise le module, aucune décision prise |
| WL_NO_SSID_AVAIL | 1 | Le réseau annoncé n'est pas détecté : mauvais nom ou hors portée |
| WL_SCAN_COMPLETED | 2 | Une balayage s'est terminé, connexion encore à lancer |
| WL_CONNECTED | 3 | Connexion établie et adresse IP obtenue |
| WL_CONNECT_FAILED | 4 | Association refusée : mot de passe presque toujours en cause |
| WL_CONNECTION_LOST | 5 | Connexion établie puis perdue |
| WL_DISCONNECTED | 6 | Déconnecté, la carte retente selon sa configuration |
$lesson$),
  ('ard-c5-p2', 'ard-c5', 2, $lesson$Connecter l'ESP32 en Wi-Fi mode station$lesson$, $lesson$
La connexion elle-même tient en peu de lignes, mais chaque ligne mérite d'être comprise. On commence par fixer le mode avec WiFi.mode, puis on appelle WiFi.begin avec le nom du réseau et son mot de passe. Cette fonction est asynchrone : elle lance la procédure d'association et retourne immédiatement, sans attendre le résultat. Le programme doit donc interroger l'état jusqu'à ce que la connexion aboutisse.

```cpp
#include <WiFi.h>

const char* SSID     = "votre-reseau";
const char* MOTDEPASSE = "votre-mot-de-passe";

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, MOTDEPASSE);
  Serial.print("wifi: connexion a ");
  Serial.println(SSID);

  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("wifi: IP obtenue ");
  Serial.println(WiFi.localIP());
}

void loop() {}
```

Ce premier squelette est volontairement bloquant : le programme s'arrête dans la boucle while tant que la connexion n'est pas établie. Pour une carte dont le seul rôle est d'être connectée, cela peut suffire au démarrage. C'est en revanche inacceptable dès que vous avez des LED à faire clignoter, des capteurs à lire ou un afficheur à rafraîchir pendant la connexion. La version non bloquante, que nous construirons dans la section suivante, remplace ce while par un test périodique dans loop(), en conservant l'état de la procédure dans une variable d'état.

Quelques détails de bon usage méritent d'être signalés. Le nom du réseau et le mot de passe sont stockés dans des constantes de type chaîne, ce qui évite de les disperser dans le code : une seule modification à faire quand vous changez de réseau. L'adresse IP s'obtient avec WiFi.localIP() après connexion, et se présente sous la forme d'un objet que Serial.println sait afficher point par point. Pour connaître la puissance du signal reçu, WiFi.RSSI() renvoie un nombre négatif en décibels : au-delà de moins soixante-dix, la liaison devient peu fiable et il faut rapprocher l'antenne du routeur. Pour une carte encastrée dans une boîte métallique, ce simple indicateur vous évitera des heures d'investigation.

La gestion des erreurs commence par le refus des valeurs par défaut. Ne laissez jamais le nom de réseau en dur dans un fichier que vous partagerez publiquement, et méfiez-vous des chaînes vides : WiFi.begin avec un SSID vide renverra immédiatement un état d'échec. Une bonne pratique consiste à prévoir un repli : si la connexion échoue après un délai raisonnable, le programme continue en mode dégradé, en publiant par exemple ses mesures sur le port série seul, plutôt que de rester bloqué indéfiniment. Vous verrez dans la section sur la robustesse comment structurer ce repli proprement.
$lesson$),
  ('ard-c5-p3', 'ard-c5', 3, $lesson$Une connexion qui ne bloque jamais$lesson$, $lesson$
La discipline non bloquante est le cœur du chapitre, et elle prolonge directement ce que vous avez appris sur les machines à états. L'idée est simple : au lieu d'attendre dans une boucle fermée, on mémorise l'état de la procédure et on la fait progresser à chaque passage dans loop(). Pour la connexion Wi-Fi, quatre états suffisent : en attente de connexion, connecté, en attente de délai de nouveau essai, et déconnecté. Chaque état déclenche une action différente, et les transitions sont conditionnées par le temps écoulé, mesuré avec millis().

```cpp
enum EtatWifi { ATTENTE, CONNECTE, ATTENT_RETRY, HORS_RESEAU };
EtatWifi etatWifi = ATTENTE;
unsigned long debutAttente = 0;
unsigned long dernierEssai = 0;
const unsigned long DELAI_CONNEXION = 15000;
const unsigned long DELAI_RETRY    = 20000;

void demarrerConnexion() {
  WiFi.disconnect();
  WiFi.begin(SSID, MOTDEPASSE);
  debutAttente = millis();
  etatWifi = ATTENTE;
  Serial.println("wifi: nouvelle tentative");
}

void gererWifi() {
  unsigned long maintenant = millis();
  switch (etatWifi) {
    case ATTENTE:
      if (WiFi.status() == WL_CONNECTED) {
        etatWifi = CONNECTE;
        Serial.print("wifi: OK ");
        Serial.println(WiFi.localIP());
      } else if (maintenant - debutAttente > DELAI_CONNEXION) {
        etatWifi = HORS_RESEAU;
        dernierEssai = maintenant;
        Serial.println("wifi: echec, absence de reseau");
      }
      break;
    case CONNECTE:
      if (WiFi.status() != WL_CONNECTED) {
        etatWifi = HORS_RESEAU;
        dernierEssai = millis();
        Serial.println("wifi: liaison perdue");
      }
      break;
    case HORS_RESEAU:
      if (maintenant - dernierEssai > DELAI_RETRY) {
        demarrerConnexion();
      }
      break;
  }
}
```

Cette structure a trois avantages décisifs. Le programme reste libre pendant les quinze secondes d'attente : une LED peut clignoter, un afficheur peut se rafraîchir, un capteur peut être lu. La perte de connexion est détectée dans l'état CONNECTE, ce que l'approche naïve oublie toujours : une fois connecté, il faut continuer à surveiller. Enfin, le délai entre deux essais évite de marteler le routeur, ce qui consommerait de la batterie et pourrait même déclencher une protection anti brute force sur certains équipements.

Il existe un raccourci commode pour ceux qui préfèrent un style plus simple : WiFi.setAutoReconnect(true) demande au module de gérer seul la réassociation, et WiFi.reconnect() force une nouvelle tentative. Ces fonctions sont pratiques, mais elles ne remplacent pas l'affichage de l'état sur le port série, et elles rendent parfois le diagnostic plus obscur. La machine à états explicite que vous venez d'écrire reste la solution recommandée quand la visibilité prime, car elle vous dit exactement à quel moment la connexion a été perdue et combien de temps a duré chaque tentative.

Un point de vigilance sur millis(). Comme vous le savez depuis la leçon sur les automates, la variable déborde après environ cinquante jours de fonctionnement continu. Le pattern de comparaison maintenant - debut > delai reste correct même après le débordement, à condition de ne jamais écrire maintenant < debut. C'est une des raisons pour lesquelles on compare toujours des différences et jamais des dates absolues. Sur un objet connecté destiné à tourner des mois sans interruption, ce détail n'est pas théorique : il évite un redémerrage incompréhensible tous les cinquante jours.

Pour conclure cette première grande partie, voici l'ordre de démarrage que nous réutiliserons dans tout le chapitre. Le port série d'abord, pour pouvoir observer la suite. Le Wi-Fi ensuite, avec la machine à états de gestion. Le serveur web une fois l'adresse obtenue, puis le client MQTT enfin, car les deux dépendent d'une liaison établie. Chaque étape annonce sa naissance sur le port série et signale ses échecs avec un code exploitable. Ce canevas, répété à l'identique dans chaque projet connecté, est ce qui sépare un prototype qui fonctionne devant vous d'un objet qui fonctionne aussi quand vous n'êtes pas là.


Une fois l'adresse IP obtenue, votre ESP32 peut devenir à son tour un serveur, c'est-à-dire un programme à l'écoute de demandes entrantes. C'est une révolution de perspective : jusqu'ici, la carte initiait toujours la communication. Maintenant, c'est l'inverse : elle attend, et n'importe quel appareil du réseau local, ordinateur, téléphone ou tablette, peut venir la solliciter. Le cas le plus familier est celui du navigateur web, qui envoie une requête HTTP et attend en retour une page HTML. Comprendre ce mécanisme à la main, sans cadre abstrait, vous donnera une base solide pour toute l'architecture web moderne.
$lesson$),
  ('ard-c5-p4', 'ard-c5', 4, $lesson$Servir une page web depuis la puce$lesson$, $lesson$
Le protocole HTTP repose sur un modèle simple : un client envoie une ligne de commande textuelle, le serveur répond par un en-tête puis un corps. La requête la plus courante se lit GET /index.html HTTP/1.1, ce qui signifie : donne-moi la ressource située à l'emplacement /index.html. Le serveur répond par un code de statut, 200 pour le succès, 404 quand la ressource n'existe pas, puis un en-tête qui décrit le contenu, notamment son type, et enfin les données elles-mêmes. Quand vous tapez une adresse dans un navigateur, exactement ce dialogue se produit, en général en quelques millisecondes.

La bibliothèque WebServer incluse avec l'outil ESP32 encapsule tout cela. Vous déclarez un objet sur le port 80, le port standard du protocole HTTP, vous enregistrez des routes, puis vous appelez handleClient() en permanence dans loop(). Cette dernière appelée est indispensable : c'est elle qui accepte les connexions entrantes et déclenche le bon gestionnaire. L'oublier est l'erreur la plus fréquente du débutant, qui observe alors un port fermé malgré un code apparemment correct.

```cpp
#include <WebServer.h>

WebServer serveur(80);

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, MOTDEPASSE);
  while (WiFi.status() != WL_CONNECTED) delay(250);
  Serial.println(WiFi.localIP());

  serveur.on("/", HTTP_GET, []() {
    serveur.send(200, "text/html", PAGE_ACCUEIL);
  });
  serveur.onNotFound([]() {
    serveur.send(404, "text/plain", "Route inconnue");
  });
  serveur.begin();
}

void loop() {
  serveur.handleClient();
}
```

Le point-virgule manquant à la fin d'une déclaration n'est pas la seule source d'erreur dans ce genre de code. Il faut surtout saisir que les gestionnaires sont des fonctions anonymes, appelées lambdas, qui s'exécutent au moment exact où la requête arrive. Elles doivent donc être rapides et ne jamais bloquer : aucune attente longue, aucun délai de lecture de capteur dans le corps d'un gestionnaire. Si une mesure prend du temps, vous publierez plutôt la dernière valeur connue, mise à jour en dehors du serveur, dans le flux normal de loop(). Le serveur n'est qu'une vitrine, il expose l'état courant de l'objet, il ne le calcule pas.

La page elle-même est une chaîne de caractères stockée en mémoire flash, ce qui vous oblige à quelques précautions. Les guillemets à l'intérieur de la page doivent être échappés, et les accents sont autorisés si vous enregistrez le fichier en UTF-8. Pour éviter ce casse-tête, beaucoup de projets embarquent la page dans un fichier séparé ou utilisent un littéral brut. Quel que soit votre choix, gardez en tête que l'ESP32 dispose d'une mémoire vive limitée : une page de quelques kilo-octets est confortable, un site complet avec images ne l'est pas. La règle empirique tient en une phrase : le serveur embarqué sert des pages de supervision, pas un site de contenu.

Voici un exemple de page minimaliste, volontairement petite, qui affiche un titre et un lien vers l'API que nous construirons ensuite. Notez qu'il s'agit d'un bloc de code, la seule zone du fichier où les balises HTML sont autorisées.

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Station meteo</title>
</head>
<body>
  <h1>Station meteo easyLearn</h1>
  <p>Derniere mesure : <strong id="valeur">...</strong></p>
  <a href="/api/mesures">Voir le JSON</a>
</body>
</html>
```

L'attribut viewport mérite une explication : sans lui, le téléphone rend la page dans une fenêtre étroite et force l'utilisateur à zoomer. Avec lui, la page occupe toute la largeur de l'écran. C'est le détail qui fait la différence entre une page perçue comme bâclée et une page qui semble native sur mobile. Pour une supervision d'atelier consultée depuis un téléphone, ce simple attribut est indispensable.
$lesson$),
  ('ard-c5-p5', 'ard-c5', 5, $lesson$Routes, API JSON et lecture de capteurs à la demande$lesson$, $lesson$
Une page statique sert à l'œil, mais c'est l'API qui sert les machines. Le principe consiste à exposer des routes dont la réponse est du JSON, un format texte structuré que n'importe quel client sait interpréter. L'ESP32 produit alors deux sorties complémentaires : le HTML pour l'humain, le JSON pour le programme. C'est exactement la séparation des préoccupations que l'on retrouve dans toute application web professionnelle.

```cpp
#include <ArduinoJson.h>

void routeMesures() {
  StaticJsonDocument<192> doc;
  doc["temp"]  = derniereTemp;
  doc["hum"]   = derniereHum;
  doc["rssi"]  = WiFi.RSSI();
  doc["up"]    = millis() / 1000;
  String sortie;
  serializeJson(doc, sortie);
  serveur.send(200, "application/json", sortie);
}

// enregistrement dans setup()
serveur.on("/api/mesures", HTTP_GET, routeMesures);
```

Le choix de la bibliothèque ArduinoJson n'est pas anodin. Elle sérialise un document typé, évitant les chaînes concaténées à la main où une virgule oubliée casse tout le tableau de bord côté client. La taille déclarée, ici 192 octets, doit correspondre au contenu réel : trop petite, la sérialisation échoue silencieusement ; trop grande, vous gaspillez de la mémoire vive. Mesurez, ajustez, puis figez la valeur. Un JSON mal formé est le défaut le plus difficile à diagnostiquer, car le serveur répond 200 et c'est le client qui échoue, souvent sans message exploitable.

Pensez aussi au contenu de la réponse. Le type application/json indique au client comment parser le corps. Pour du HTML, c'est text/html. Pour un fichier téléchargé, il faudrait un type binaire. Ces en-têtes ne sont pas décoratifs : un JSON servi en text/plain sera refusé par certaines bibliothèques front-end, et une page HTML servi sans encodage affichera des accents cassés. Le protocole HTTP est un protocole de métadonnées autant que de données, et soigner ces métadonnées, c'est soigner l'interopérabilité.

Voici un schéma du cycle complet d'une requête, de la broche jusqu'au navigateur, en passant par les couches que vous venez d'écrire.

```
 Navigateur                ESP32                         Capteur
     |                        |                             |
     |  GET /api/mesures      |                             |
     |----------------------->|                             |
     |                        |  lecture valeur courante    |
     |                        |---------------------------->|
     |                        |  24.5 (memoire immediate)   |
     |                        |<----------------------------|
     |  200 OK {"temp":24.5}  |                             |
     |<-----------------------|                             |
     |                        |                             |
     |  GET /  (HTML)         |                             |
     |----------------------->|                             |
     |  200 OK <html>...</html>|                            |
     |<-----------------------|                             |
```

La distinction valeur courante et valeur fraîche est capitale. Le capteur n'est lu qu'une fois par cycle, hors du gestionnaire HTTP, et le serveur ne fait qu'exposer la dernière lecture. Si vous lisiez le capteur à l'intérieur du gestionnaire, vous exposeriez le bus matériel à des requêtes imprévisibles, et une lecture DHT22 trop rapprochée échouerait de toute façon. Le serveur ne doit jamais dépendre du matériel directement : il publie un état, il ne le produit pas.

Il reste à traiter la question des méthodes HTTP. GET sert à lire, POST à envoyer une création, PUT à remplacer, DELETE à supprimer. Pour un objet embarqué, deux suffisent en pratique : GET pour les lectures, POST pour les commandes, par exemple changer l'intervalle de publication ou forcer une calibration. Le corps d'une requête POST arrive dans la chaîne serveur.arg("body"), qu'il faut parser avec la même rigueur que la sortie JSON. Une commande mal formatée ne doit jamais modifier l'état : validez d'abord, appliquez ensuite, répondez toujours par un code de statut explicite.

Un dernier conseil d'architecture, issu de l'expérience. Exposez une route d'état globale qui répond en une ligne l'ensemble des informations de diagnostic : adresse IP, force du signal, état MQTT, temps de fonctionnement, compteur de redémarrages. Cette route, souvent nommée /api/etat, devient votre meilleur outil de dépannage à distance. Quand un objet cesse de répondre, la première question est toujours : est-ce que la carte tourne, ou est-ce que seul le réseau est tombé ? Une réponse JSON sur une page locale tranche la question en quelques secondes, sans ouvrir l'IDE ni brancher le câble USB.
$lesson$),
  ('ard-c5-p6', 'ard-c5', 6, $lesson$MQTT : le messager des objets connectés$lesson$, $lesson$
Le serveur web répond quand on lui demande. MQTT fait l'inverse : il pousse les informations vers quiconque s'est abonné, sans que l'émetteur ait à connaître ses destinataires. Ce modèle, appelé publication et abonnement, est né dans les années quatre-vingt-dix pour les télécoms mobiles, précisément pour des dispositifs qui doivent fonctionner sur des liens coûteux et instables. Il est devenu le protocole dominant de l'internet des objets, et ce n'est pas un hasard : sa sobriété et sa tolérance aux coupures correspondent exactement aux contraintes d'un microcontrôleur.

Au centre du système se trouve un broker, un serveur dédié qui reçoit les messages, les classe par sujet et les redistribue aux abonnés. Le sujet, ou topic, est une chaîne hiérarchique séparée par des barres obliques, par exemple easylearn/ardc5/mesures. La hiérarchie sert de filtre : s'abonner à easylearn/ardc5/# reçoit tous les sujets du chapitre, tandis que easylearn/+/alerte reçoit les alertes de tous les projets. Ce mécanisme de remplacement est d'une puissance remarquable pour organiser un parc d'objets sans modifier une ligne de code côté émetteur.

Comparons les deux approches pour bien saisir ce qui change. Avec un serveur web, l'ESP32 doit rester à l'écoute en permanence et le client doit connaître son adresse, qui peut changer. Avec MQTT, l'ESP32 publie une fois et continue son travail ; le broker, lui, est joignable sous un nom de domaine stable et conserve les messages destinés aux abonnés temporaires si la fonction est activée. Le coût de cette commodité, c'est la dépendance à un tiers : si le broker tombe, la chaîne s'interrompt. D'où l'importance capitale de la reconnexion, que nous traiterons dans la partie suivante.

Le protocole définit plusieurs niveaux de qualité de service, notés QoS. Le tableau ci-dessous résume leur portée et leur coût.

| QoS | Garantie | Comportement | Usage typique |
| --- | --- | --- | --- |
| 0 | Au plus une fois | Envoi sans accusé, le message peut se perdre | Télémétrie haute fréquence |
| 1 | Au moins une fois | Accusé de réception, doublons possibles | États, compteurs, alertes |
| 2 | Exactement une fois | Protocole à quatre phases, sans doublon | Commandes critiques, facturation |

En pratique sur un ESP32 avec la bibliothèque PubSubClient, seul le niveau 0 est disponible pour la publication. C'est largement suffisant pour des mesures régulières : si un relevé se perd, le suivant corrige l'information dans les dix secondes. En revanche, pour une commande qui ne doit jamais être perdue, vous ajouterez un accusé de réception applicatif dans votre propre message, par exemple un identifiant de série que le récepteur confirme. C'est une solution simple et déterministe, sans dépendre d'un niveau de service que l'implémentation ne propose pas.

Il existe plusieurs manières de démarrer un broker pour tester. En local, le paquet mosquitto fournit un serveur minimaliste et une paire d'outils en ligne de commande, mosquitto_sub et mosquitto_pub, qui permettent d'observer les messages sans écrire une ligne de code. En ligne, des services gratuits offrent un accès public, mais ils imposent souvent une authentification et une connexion chiffrée. Pour vos premiers pas, un broker local est préférable : le réseau reste sous votre contrôle, les journaux sont consultables, et vous éliminez une variable quand quelque chose ne fonctionne pas.

Voici la séquence complète d'une session MQTT depuis un terminal, telle que vous la verrez apparaître au débogage.

```
$ mosquitto_sub -h 127.0.0.1 -t "easylearn/#" -v
easylearn/ardc5/mesures {"temp":24.5,"hum":51.2}
easylearn/ardc5/mesures {"temp":24.6,"hum":51.0}
easylearn/ardc5/commande {"interval":20}
```

La ligne -v affiche le sujet avant le contenu, ce qui est précieux quand plusieurs flux se mêlent. Le filtre easylearn/# vous permet de surveiller d'un coup d'œil tout ce que vos objets publient pendant une session de développement. Gardez cette fenêtre ouverte en permanence pendant vos essais : elle vous dira, mieux que n'importe quel log, si l'ESP32 publie réellement ou s'il croit publier.


La théorie de MQTT est en place, il est temps d'écrire le code qui s'y connecte. La bibliothèque PubSubClient est le standard de l'écosystème Arduino pour cette tâche : elle est légère, éprouvée et suffisante pour la grande majorité des objets de supervision. Elle s'appuie sur le client TCP fourni par la bibliothèque Wi-Fi et implémente le sous-ensemble du protocole dont un objet a besoin : connexion, authentification, publication, abonnement et callback de réception.
$lesson$),
  ('ard-c5-p7', 'ard-c5', 7, $lesson$Publier et recevoir avec PubSubClient$lesson$, $lesson$
L'objet PubSubClient se construit autour d'une instance de client réseau que vous lui transmettez. Ensuite, trois appels structurent l'essentiel : setServer pour indiquer l'adresse et le port du broker, setCallback pour déclarer la fonction qui traitera les messages reçus, et connect pour ouvrir la session. Chacun de ces appels peut échouer, et c'est leur valeur de retour qu'il faut toujours vérifier.

```cpp
#include <PubSubClient.h>

WiFiClient lienWifi;
PubSubClient mqtt(lienWifi);

const char* BROKER = "192.168.1.10";
const int   PORT   = 1883;
const char* ID     = "ard-c5-001";

void surMessage(char* sujet, byte* donnees, unsigned long taille) {
  String charge;
  for (unsigned long i = 0; i < taille; i++) charge += (char)donnees[i];
  Serial.print("mqtt: recu ");
  Serial.print(sujet);
  Serial.print(" -> ");
  Serial.println(charge);
}

void demarrerMqtt() {
  mqtt.setServer(BROKER, PORT);
  mqtt.setCallback(surMessage);
}

void connecterMqtt() {
  if (!mqtt.connected()) {
    Serial.print("mqtt: connexion ");
    if (mqtt.connect(ID)) {
      Serial.println("ok");
      mqtt.publish("easylearn/ardc5/etat", "en ligne");
      mqtt.subscribe("easylearn/ardc5/commande");
    } else {
      Serial.print("echec, code=");
      Serial.println(mqtt.state());
    }
  }
}
```

La fonction de rappel surMessage mérite une attention particulière. Elle s'exécute à l'intérieur de client.loop(), donc dans le flux principal du programme : elle doit être courte, sans attente, sans appel bloquant. Elle reçoit le sujet, un tableau d'octets et sa longueur, car un message MQTT est binaire par nature. On convertit ce tableau en chaîne, on analyse, on déclenche éventuellement une action, puis on rend la main. Si vous devez traiter une charge volumineuse, mettez-la dans une file d'attente et traitez-la dans loop(), exactement comme vous l'auriez fait avec un drapeau posé par une interruption.

Les codes de retour de mqtt.state() sont votre principal outil de diagnostic. La valeur 0 signifie connecté. -4 correspond à une perte de connexion au réseau, -3 à une session refusée par le broker, -2 à une reconnexion en cours, -1 à une déconnexion propre, et les valeurs négatives plus basses à des erreurs de protocole ou de mémoire. Un code -3 quasi systématique signale presque toujours un identifiant déjà utilisé : si deux cartes se présentent avec le même nom, le broker déconnecte l'une des deux en boucle. Donnez un identifiant unique à chaque objet, par exemple en intégrant la fin de l'adresse MAC.

La publication est plus simple que la réception, car elle n'attend rien. On appelle publish avec le sujet, puis la charge utile convertie en chaîne, et éventuellement le drapeau de rétention qui demande au broker de conserver le dernier message pour les abonnés qui arriveront plus tard. Ce drapeau est précieux pour les états : un tableau de bord qui se connecte après l'objet voit immédiatement la dernière valeur connue au lieu d'attendre le prochain cycle.

```cpp
#include <ArduinoJson.h>

void publierMesure(float t, float h) {
  StaticJsonDocument<160> doc;
  doc["temp"] = t;
  doc["hum"]  = h;
  doc["id"]   = ID;
  char charge[160];
  serializeJson(doc, charge);

  if (mqtt.connected()) {
    bool ok = mqtt.publish("easylearn/ardc5/mesures", charge);
    Serial.print("mqtt: pub ");
    Serial.println(ok ? "ok" : "echec");
  } else {
    Serial.println("mqtt: publication sautee, hors ligne");
  }
}
```

Notez la précaution consistant à vérifier l'état avant de publier. Publier hors ligne renvoie false sans lever d'erreur, ce qui peut faire croire à un problème de broker alors que la connexion réseau est simplement tombée. En cas de coupure, vous avez deux stratégies à disposition. La première consiste à ignorer les mesures perdues : pour un relevé périodique, c'est la plus simple et la plus sage. La seconde consiste à conserver les valeurs dans un petit tampon circulaire et à les rejouer à la reconnexion, ce qui se justifie quand chaque point compte, par exemple pour des courbes de consommation. Choisissez délibérément, et documentez votre choix dans le code.

La réception, elle, se joue entièrement dans la boucle principale. Tant que vous n'appelez pas mqtt.loop(), aucun message n'arrive, même si l'abonnement est déclaré. Ce détail surprend régulièrement : on souscrit dans setup(), on ne rappelle jamais loop(), et on s'étonne que la callback ne se déclenche jamais. La règle est mécanique : dans loop(), appelez mqtt.loop() à chaque itération, sans exception et sans délai long juste avant.
$lesson$),
  ('ard-c5-p8', 'ard-c5', 8, $lesson$Robustesse : reconnexion, back-off et chien de garde$lesson$, $lesson$
Un objet connecté qui fonctionne devant vous pendant dix minutes n'a pas encore prouvé grand-chose. La vraie question est celle-ci : que se passe-t-il quand le routeur redémarre, quand le broker s'arrête pour une mise à jour, quand le point d'accès change de canal ? Si votre programme n'a pas de réponse à ces questions, il s'arrêtera définitivement au premier incident. La robustesse n'est donc pas une option de confort, c'est la condition de fonctionnement d'un objet qui tourne sans surveillance.

Le principe du back-off croissant est directement emprunté aux réseaux professionnels. Plutôt que de retenter toutes les cinq secondes, ce qui sature la bande passante et le broker, on augmente progressivement le délai : deux secondes, puis quatre, puis huit, jusqu'à un plafond de trente secondes. Dès qu'une connexion aboutit, le compteur repart à zéro. Ce simple mécanisme transforme une tempête de tentatives infructueuses en une respiration régulière, et il laisse au système le temps de se rétablir.

```cpp
unsigned long derniereTentative = 0;
unsigned long delaiTentative = 2000;
const unsigned long DELAI_MAX = 30000;

void gererReconnexion() {
  if (mqtt.connected()) {
    delaiTentative = 2000;
    return;
  }
  if (millis() - derniereTentative < delaiTentative) return;
  derniereTentative = millis();
  Serial.print("mqtt: tentative dans ");
  Serial.println(delaiTentative);

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("mqtt: reporte, pas de reseau");
    delaiTentative = min(delaiTentative * 2, DELAI_MAX);
    return;
  }
  if (mqtt.connect(ID)) {
    Serial.println("mqtt: reconnecte");
    mqtt.subscribe("easylearn/ardc5/commande");
    delaiTentative = 2000;
  } else {
    Serial.print("mqtt: echec code=");
    Serial.println(mqtt.state());
    delaiTentative = min(delaiTentative * 2, DELAI_MAX);
  }
}
```

Cette fonction est conçue pour être appelée en début de loop(), et pour revenir immédiatement quand rien n'a à faire. Elle ne bloque jamais : la vérification du délai s'effectue en une comparaison, puis elle rend la main. Notez aussi qu'elle refuse de tenter une connexion MQTT tant que le Wi-Fi est absent : tenter dans ces conditions gaspillerait du temps et produirait un code d'erreur trompeur. La dépendance entre les couches réseau est explicite, et c'est exactement ce qui rend le diagnostic lisible.

Le chien de garde logiciel est la dernière ligne de défense. L'ESP32 embarque un compteur que le programme doit réinitialiser régulièrement ; s'il n'expire pas avant, la puce redémarre d'elle-même. Ce mécanisme, hérité des systèmes industriels, transforme un blocage silencieux en un redémarrage contrôlé, souvent suffisant pour qu'un objet reparte tout seul après un incident imprévu. L'API se résume à trois appels, à placer dans setup(), et à un réarmement à placer en haut de loop().

```cpp
#include <esp_task_wdt.h>

void setup() {
  esp_task_wdt_init(10, true);
  esp_task_wdt_add(NULL);
  // ... reste de l'initialisation
}

void loop() {
  esp_task_wdt_reset();
  gererWifi();
  gererReconnexion();
  mqtt.loop();
  serveur.handleClient();
  lireCapteurSiTemps();
}
```

Le délai du chien de garde doit être nettement supérieur au temps maximal d'une itération normale de loop(), mais suffisamment court pour intervenir vite. Dix secondes est un bon point de départ quand aucune opération ne dépasse une seconde. Si vous ajoutez par la suite une lecture longue, un téléchargement ou une mise à jour firmware à distance, mesurez d'abord la durée réelle, puis ajustez, sous peine de voir la puce redémarrer en boucle au pire moment.

Un dernier aspect de robustesse concerne la persistance. L'ESP32 dispose d'une mémoire non volatile qu'on peut utiliser pour enregistrer des préférences, par exemple le nom du réseau, l'intervalle de publication ou un compteur de redémarrages. La bibliothèque Preferences encapsule ce mécanisme de façon très simple, avec des paires clé-valeur typées. Ce compteur de redémarrages, en particulier, est d'une grande valeur : affiché au démarrage sur le port série, il vous dit en une seconde si votre objet a redémarré cent fois pendant la nuit, ce qui est le symptôme le plus clair d'une instabilité résiduelle.
$lesson$),
  ('ard-c5-p9', 'ard-c5', 9, $lesson$Sécurité, secrets et bonnes pratiques$lesson$, $lesson$
Passer du prototype au déployable implique de traiter quelques questions que l'on repousse volontiers en phase de développement. La première concerne les secrets. Un mot de passe Wi-Fi en clair dans un fichier source est un risque réel si le code est partagé ou si la carte est perdue. La solution simple consiste à séparer les secrets du code dans un fichier local ignoré par le gestionnaire de versions, puis à l'inclure à la compilation. Une solution plus aboutie consiste à stocker les identifiants en mémoire non volatile lors d'une phase de configuration, et à ne jamais les réafficher sur le port série.

La deuxième question est la confiance dans les commandes reçues. Si votre objet écoute un topic pour changer un seuil ou redémarrer une pompe, n'importe qui ayant accès au broker peut envoyer cet ordre. Trois niveaux de protection se combinent, du plus simple au plus complet. D'abord, limitez l'exposition du broker : sur Internet, ne laissez jamais un port 1883 ouvert publiquement. Ensuite, utilisez l'authentification du protocole, un identifiant et un mot de passe transmis à la fonction connect. Enfin, validez chaque commande applicative : format, plage de valeurs, cohérence avec l'état courant. Une commande refusée doit recevoir une réponse explicite, pas un silence.

Le troisième point concerne la mise à jour du programme. Un objet déjà installé dans une boîte, sur un toit ou derrière un panneau n'est pas toujours accessible par câble. La mise à jour à distance, dite OTA, permet de reflasher l'ESP32 par le réseau. La bibliothèque Update s'utilise avec le serveur web : on téléverse un fichier binaire, on le vérifie, puis on redémarre. Deux précautions sont non négociables : n'autorisez le téléversement que derrière une authentification, et conservez toujours un moyen de récupération, car un firmware interrompu rend la carte inutilisable sans câble.

```cpp
#include <Update.h>

void routeMaj() {
  if (!authentifie()) {
    serveur.send(401, "text/plain", "Non autorise");
    return;
  }
  HTTPUpload& upload = serveur.upload();
  if (upload.status == UPLOAD_FILE_START) {
    Serial.println("maj: debut");
    if (!Update.begin(UPDATE_SIZE_UNKNOWN)) Update.printError(Serial);
  } else if (upload.status == UPLOAD_FILE_END) {
    if (Update.end(true)) {
      Serial.println("maj: OK, redemarrage");
      ESP.restart();
    } else {
      Update.printError(Serial);
    }
  }
}
```

Enfin, quelques bonnes pratiques de structure qui facilitent la maintenance. Nommez vos topics à partir d'une racine unique par projet, puis d'un identifiant d'objet, puis d'une grandeur : un préfixe stable, une carte, une mesure. Conservez les adresses de broker et de réseau dans une seule section de configuration en tête de fichier. Séparez les fonctions réseau des fonctions métier, de sorte qu'un remplacement de bibliothèque n'entraîne pas la réécriture de la logique de mesure. Et surtout, gardez le port série bavard en développement, sobre en production : un journal trop verbeux finit par ralentir la boucle principale, tandis qu'un journal muet empêche de diagnostiquer.


Toutes les pièces du puzzle sont désormais sur la table : connexion Wi-Fi non bloquante, serveur web avec routes d'API, client MQTT avec rappel de réception, reconnexion à délai croissant et chien de garde. Cette section les assemble en un seul programme cohérent, la station météo connectée qui constituera le fil rouge du chapitre. L'objectif n'est pas de vous livrer un code à recopier mécaniquement, mais de vous montrer comment les responsabilités se répartissent dans un fichier réel, dans quel ordre tout s'initialise et comment chaque appel sert une décision précise.
$lesson$),
  ('ard-c5-p10', 'ard-c5', 10, $lesson$Exemple guidé : la station météo complète$lesson$, $lesson$
Le programme découpe en quatre responsabilités nettes. La première est la configuration : constantes de réseau, identifiants MQTT, seuils et intervalles, regroupés en tête de fichier pour ne jamais chercher un identifiant au milieu de la logique. La seconde est l'état : les variables qui décrivent où en est la machine à chaque instant, à savoir l'état Wi-Fi, le compteur de back-off et la dernière mesure. La troisième est la couche réseau, composée des fonctions de gestion du Wi-Fi, du serveur et du MQTT que vous avez écrites dans les sections précédentes. La quatrième est la métier : lecture du capteur, calcul, publication planifiée. Toute la difficulté d'un projet connecté tient dans le maintien de cette séparation : dès qu'une lecture de capteur s'introduit dans un gestionnaire de route, ou qu'une adresse IP se retrouve noyée dans la logique de mesure, le programme devient impossible à faire évoluer.

L'ordre d'initialisation dans setup() n'est pas arbitraire. Le port série d'abord, car tout le reste dépend de sa capacité à vous raconter ce qui se passe. Le chien degarde ensuite, avant que quoi que ce soit d'autre puisse bloquer. Puis le capteur, puis le Wi-Fi, puis le serveur web, puis le MQTT enfin, car ce dernier exige une liaison IP établie. Si vous intervertissez deux étapes, vous obtiendrez un échec dont le message ne correspondra pas à la cause réelle, ce qui est la pire manière de perdre du temps. Chaque initialisation annonce sa réussite sur le port série, de sorte qu'une carte qui ne répond pas vous dise exactement à quelle ligne elle s'est arrêtée.

```cpp
#include <WiFi.h>
#include <WebServer.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <esp_task_wdt.h>

const char* SSID   = "votre-reseau";
const char* MDP    = "votre-mot-de-passe";
const char* BROKER = "192.168.1.10";
const int   PORT   = 1883;
const char* ID     = "ard-c5-meteo";

const int PIN_DHT = 4;
const unsigned long INTERVALLE = 10000;

DHT dht(PIN_DHT, DHT22);
WebServer serveur(80);
WiFiClient lien;
PubSubClient mqtt(lien);

float derniereTemp = 0.0, derniereHum = 0.0;
unsigned long dernierEnvoi = 0;
unsigned long intervalleActif = INTERVALLE;

void setup() {
  Serial.begin(115200);
  esp_task_wdt_init(10, true);
  esp_task_wdt_add(NULL);
  dht.begin();
  demarrerWifi();
  demarrerServeur();
  demarrerMqtt();
  Serial.println("setup: termine");
}

void loop() {
  esp_task_wdt_reset();
  gererWifi();
  serveur.handleClient();
  mqtt.loop();
  gererReconnexion();
  if (millis() - dernierEnvoi >= intervalleActif) {
    dernierEnvoi = millis();
    lireEtPublier();
  }
}
```

La boucle principale révèle la structure temporelle du programme. Chaque fonction appelée ici est non bloquante et revient en quelques millisecondes. La lecture du capteur n'a lieu que lorsque l'intervalle est écoulé, ce qui évite de saturer un DHT22, matériellement limité à une lecture toutes les deux secondes. La variable intervalleActif peut être modifiée à chaud par une commande MQTT reçue, ce qui transforme un réglage compilé en réglage exploitable à distance, sans reflash ni intervention physique sur la carte.

La fonction de lecture et de publication illustre le chemin complet de la donnée, du capteur jusqu'au réseau. La valeur est lue, contrôlée, mise en mémoire, puis sérialisée en JSON et poussée sur le broker. Le contrôle n'est pas une formalité : un DHT22 renvoie des valeurs hors plage lors d'une lecture ratée, et publier zéro degré par erreur déclencherait des alertes fantômes dans votre tableau de bord. Une mesure douteuse est donc simplement ignorée jusqu'à la suivante, et le programme continue de fonctionner. C'est cette philosophie qui caractérise un objet fiable : il préfère une donnée manquante à une donnée fausse.

```cpp
void lireEtPublier() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (isnan(t) || isnan(h)) {
    Serial.println("capteur: lecture invalide, ignoree");
    return;
  }
  derniereTemp = t;
  derniereHum = h;

  StaticJsonDocument<160> doc;
  doc["temp"] = t;
  doc["hum"]  = h;
  doc["rssi"] = WiFi.RSSI();
  doc["id"]   = ID;
  char charge[160];
  serializeJson(doc, charge);

  if (mqtt.connected()) {
    mqtt.publish("easylearn/ardc5/mesures", charge);
    Serial.print("mqtt: publie ");
    Serial.println(charge);
  } else {
    Serial.println("mqtt: hors ligne, mesure conservee");
  }
}
```

Le rappel de réception ferme la boucle en rendant l'objet commandable. Pour ce chapitre, une seule commande suffit à démontrer le principe : modifier l'intervalle de publication. La charge est analysée avec ArduinoJson, la valeur est validée contre une plage raisonnable, puis appliquée. Toute charge mal formée est rejetée avec un message clair envoyé sur un topic de retour. Ce réflexe de validation, appliqué dès le premier protocole que vous écrivez, vous épargnera les comportements absurds difficiles à comprendre plus tard, quand la carte sera installée et inaccessible.

```cpp
void surMessage(char* sujet, byte* donnees, unsigned long taille) {
  String charge;
  for (unsigned long i = 0; i < taille; i++) charge += (char)donnees[i];

  StaticJsonDocument<128> doc;
  if (deserializeJson(doc, charge)) {
    Serial.println("cmd: JSON invalide");
    mqtt.publish("easylearn/ardc5/retour", "erreur: format");
    return;
  }
  if (doc.containsKey("interval")) {
    long valeur = doc["interval"];
    if (valeur >= 2000 && valeur <= 300000) {
      intervalleActif = valeur;
      Serial.print("cmd: intervalle ");
      Serial.println(valeur);
      mqtt.publish("easylearn/ardc5/retour", "ok");
    } else {
      mqtt.publish("easylearn/ardc5/retour", "erreur: plage");
    }
  }
}
```

La couche serveur se limite, elle aussi, à exposer l'état courant. La route /api/mesures renvoie les valeurs mémorisées, la route /api/etat décrit la santé du système, et la racine sert la page de supervision. Aucune des trois ne déclenche une lecture de capteur : elles lisent des variables déjà à jour, ce qui garantit une réponse immédiate même si le réseau envoie cinq requêtes d'affilée. La page elle-même interroge périodiquement l'API et met à jour une zone de texte, ce qui suffit à obtenir un tableau de bord sans aucun service externe.

```cpp
void demarrerServeur() {
  serveur.on("/", HTTP_GET, []() {
    serveur.send(200, "text/html", PAGE_ACCUEIL);
  });
  serveur.on("/api/mesures", HTTP_GET, []() {
    StaticJsonDocument<192> doc;
    doc["temp"] = derniereTemp;
    doc["hum"]  = derniereHum;
    doc["rssi"] = WiFi.RSSI();
    doc["up"]   = millis() / 1000;
    String out;
    serializeJson(doc, out);
    serveur.send(200, "application/json", out);
  });
  serveur.on("/api/etat", HTTP_GET, []() {
    StaticJsonDocument<256> doc;
    doc["ip"]   = WiFi.localIP().toString();
    doc["wifi"] = WiFi.status() == WL_CONNECTED;
    doc["mqtt"] = mqtt.connected();
    doc["rss"]  = WiFi.RSSI();
    String out;
    serializeJson(doc, out);
    serveur.send(200, "application/json", out);
  });
  serveur.onNotFound([]() {
    serveur.send(404, "text/plain", "Route inconnue");
  });
  serveur.begin();
}
```

Pour valider l'ensemble, un client de bureau suffit : vous abonnez un terminal au filtre easylearn/# et vous observez les publications arriver à intervalle régulier. Notez la cadence : dix secondes entre chaque envoi est un rythme confortable pour l'œil et pour la bande passante, et il suffit largement à suivre une température de pièce. Pour une mesure plus rapide, réduisez l'intervalle, mais souvenez-vous que chaque message engage une requête réseau complète : au-delà d'une seconde, c'est le broker qui devient le goulot d'étranglement, pas la carte.

Le tableau suivant récapitule le parcours d'un cycle complet, de l'horloge jusqu'au topic, en indiquant pour chaque étape la fonction responsable et le signal attendu sur le port série. Servez-vous-en comme d'une check-list lors de vos premiers dépannages : si une ligne manque, c'est la fonction correspondante qu'il faut ouvrir.

| Étape | Fonction appelée | Signal sur le port série |
| --- | --- | --- |
| Démarrage | setup() | setup: termine |
| Réseau | demarrerWifi(), gererWifi() | wifi: IP obtenue 192.168.1.42 |
| Serveur | demarrerServeur() | http: pret sur le port 80 |
| Broker | gererReconnexion() | mqtt: reconnecte |
| Mesure | lireEtPublier() | mqtt: publie {"temp":24.5,...} |
| Commande | surMessage() | cmd: intervalle 20000 |

Une remarque finale sur la lisibilité. Un projet connecté se débogue toujours à distance, ou du moins avec un écran de terminal plutôt qu'avec un débogueur pas à pas : la liaison USB n'est pas toujours branchée, et un pas de débogueur dans une boucle réseau désynchronise souvent la machine à états. C'est pourquoi les libellés affichés sont courts, prévisibles et toujours en français : wifi:, mqtt:, http:, cmd:, capteur:. Le préfixe agit comme un namespace humain. En filtrant la sortie du moniteur série sur mqtt:, vous isolez instantanément tout ce qui concerne le broker, sans toucher au reste du programme.


Un dernier savoir-faire mérite sa place avant les bilans, car il décide de votre efficacité réelle : la méthode de diagnostic. Tôt ou tard, votre objet cesse de répondre, et la qualité de votre réflexion comptera davantage que la quantité de code écrit. La bonne nouvelle, c'est que la couche réseau se diagnostique de façon séquentielle : chaque question élimine la moitié des causes possibles. Cinq questions suffisent dans la très grande majorité des cas, à poser toujours dans le même ordre, depuis le câble jusqu'au broker.
$lesson$),
  ('ard-c5-p11', 'ard-c5', 11, $lesson$Déboguer la couche réseau, méthode en cinq questions$lesson$, $lesson$
Première question : la carte tourne-t-elle ? Si le port série reste muet à l'ouverture, le problème n'est pas réseau : c'est l'alimentation, le câble, le bon port sélectionné dans l'IDE ou un programme qui plante avant le premier affichage. Branchez, ouvrez le moniteur à 115200 bauds, redémarrez la carte. Le message setup: termine doit apparaître. S'il n'apparaît pas, tout le reste de ce chapitre est hors sujet pour l'instant : revenez à la ligne d'alimentation et vérifiez que le courant disponible suffit, une carte Wi-Fi transitoire demandant plusieurs centaines de milliampères lors de l'émission.

Deuxième question : le Wi-Fi est-il associé ? Le code d'état WiFi.status() tranche. Devant WL_NO_SSID_AVAIL, le nom du réseau est mal orthographié ou la carte est hors portée : testez en approchant l'antenne du routeur. Devant WL_CONNECT_FAILED, le mot de passe est presque toujours en cause, les deux étant refusés à l'association. Devant WL_CONNECTED sans communication utile, c'est l'adresse qui pose problème : affichez WiFi.localIP() et vérifiez que le masque correspond bien au réseau du routeur. Une adresse de la forme 169.254.x.x signifie qu'aucun serveur DHCP n'a répondu : la liaison physique existe, mais la configuration n'est pas arrivée.

Troisième question : le réseau local est-il joignable ? À partir d'un ordinateur du même réseau, lancez un ping vers l'adresse IP de la carte. Si le ping échoue, la carte est joignable au niveau radio mais votre programme ne répond pas, ce qui oriente vers un serveur non démarré ou une boucle principale bloquée. Si le ping aboutit, la pile réseau fonctionne et le problème se réduit à la couche applicative. Cette simple distinction, entre atteindre la machine et atteindre le programme, vous fera gagner un temps considérable.

Quatrième question : le port répond-il ? Un test direct sur le port 80, avec l'outil de ligne de commande intégré à votre système, suffit. La réponse attendue est un en-tête HTTP, et surtout pas un refus ou un délai d'attente, qui indiqueraient un pare-feu ou un serveur absent.

```
 Diagnostic ordonne, de la cause la plus matérielle
 vers la plus applicative :

     carte morte ?
         | non
     setup: termine absent ?
         | non
     WiFi.status() == WL_CONNECTED ?
         | non --> nom / mot de passe / portee / DHCP
         | oui
     ping 192.168.1.42 ?
         | non --> boucle principale bloquée
         | oui
     curl http://192.168.1.42/api/etat
         | echec --> handleClient() absent
         | ok
     mqtt.state() == 0 ?
         | non --> broker, port, identifiant
         | oui
     mosquitto_sub voit-il les messages ?
         non --> topic mal écrit, filtre d'abonnement
```

Cinquième question : le broker est-il atteignable et accepte-t-il la session ? Le code renvoyé par mqtt.state() vous le dira. Un code négatif persistant malgré un réseau sain signe presque toujours une erreur de paramètre : adresse du broker écrite avec le nom d'un ordinateur alors que le résolveur DNS n'est pas joignable, port différent de celui du serveur, ou mot de passe transmis à un broker qui n'en exige pas. Inversement, si la connexion aboutit mais qu'aucun message n'arrive côté abonné, vérifiez deux détails imbriqués : appelez-vous mqtt.loop() dans loop(), et votre abonnement porte-t-il exactement le même sujet que la publication, y compris la casse et les barres obliques ?

Les outils de terminal complètent avantageusement le moniteur série, car ils interrogent le système par l'extérieur plutôt que par votre propre code, ce qui élimine une source d'erreur possible. Trois commandes à connaître par cœur suffisent pour la plus grande partie du travail.

```bash
# 1. Que publie réellement la carte ?
mosquitto_sub -h 192.168.1.10 -t "easylearn/#" -v

# 2. Le serveur HTTP répond-il, et avec quoi ?
curl -i http://192.168.1.42/api/etat

# 3. La carte reçoit-elle une commande envoyée par un tiers ?
mosquitto_pub -h 192.168.1.10 \
  -t "easylearn/ardc5/commande" \
  -m "{\"interval\":20000}"
```

Le préfixe -i de curl affiche les en-têtes de réponse, ce qui révèle immédiatement un mauvais type MIME ou un code de statut inattendu. La troisième commande est particulièrement précieuse : elle démonte un doute classique, où la carte accuse une réception silencieuse alors que le message n'est jamais parvenu, ou l'inverse. En publiant vous-même la commande depuis le terminal, vous savez si le problème se situe côté émission ou côté traitement.

Un dernier réflexe, souvent négligé : la journalisation structurée. Plutôt que d'afficher des phrases complètes différentes à chaque endroit, préfixez chaque message par un espace de noms stable, puis un identifiant de cycle. La ligne mqtt: [42] publie 192 devient facilement filtrable, triable et comparable d'un essai au suivant. Quand vous devrez comparer un fonctionnement correct et un défaut, la différence entre deux journaux alignés se lit d'un coup d'œil, là où deux récits librement rédigés s'empilent sans se correspondre. Cette discipline, adoptée dès le premier projet, est celle que l'on retrouve dans tous les systèmes industriels, où l'analyse d'un incident commence toujours par la lecture des journaux dans l'ordre chronologique.

Le tableau ci-dessous referme cette méthode en associant chaque symptôme observable à sa cause la plus probable. Gardez-le sous la main pendant la mise au point du chapitre : il condense l'essentiel de cette section en un seul regard.

| Symptôme | Cause la plus probable | Vérification |
| --- | --- | --- |
| Port série muet | Alimentation ou mauvais port | Rebrancher, rouvrir à 115200 |
| État WL_NO_SSID_AVAIL | Nom du réseau ou portée | Rapprocher la carte, vérifier le SSID |
| Adresse 169.254.x.x | Aucune réponse DHCP | Tester avec un autre réseau |
| Ping refusé | Boucle principale bloquée | Repérer les delay() résiduels |
| HTTP en timeout | handleClient() non appelé | Contrôler loop() |
| mqtt.state() vaut -3 | Session refusée | Identifiant unique, port, mot de passe |
| Aucun message reçu | loop() oublié ou sujet faux | Comparer sujet publié et abonné |


Le programme fonctionne, les messages circulent, la page s'ouvre. Il reste deux sujets à approfondir avant de refermer le chapitre, parce qu'ils décident de la durée de vie réelle de votre objet : la configuration sans reprogrammation et l'observation à distance. Tous deux s'appuient sur les briques déjà en place, ce qui est le signe que l'architecture tient debout.
$lesson$),
  ('ard-c5-p12', 'ard-c5', 12, $lesson$Configurer l'objet sans le reprogrammer$lesson$, $lesson$
Le scénario est familier : vous installez la carte dans sa boîte, vous la branchez, et vous découvrez que le nom du réseau a changé depuis votre dernier essai sur le bureau. Sans portail de configuration, il faut ouvrir l'IDE, ressaisir les identifiants, reflasher, puis remonter le boîtier. Le mode combiné de l'ESP32 élimine cette corvée. Si la carte ne parvient pas à rejoindre un réseau en quelques secondes, elle devient à son tour un point d'accès éphémère auquel vous vous connectez depuis votre téléphone, et elle sert une page où vous saisissez les vrais identifiants. Ces identifiants sont ensuite écrits en mémoire non volatile, et la carte redémarre en mode station.

La séquence complète tient dans une machine à états que vous connaissez déjà, avec une branche supplémentaire. Pendant les quinze premières secondes, on tente la connexion en mode station. Si elle échoue, on bascule en point d'accès, on démarre le serveur sur l'adresse par défaut du mode point d'accès et on attend. Dès que la page de saisie a été soumise, on enregistre les valeurs, on éteint le point d'accès et on relance la tentative en station. Le même serveur sert les deux phases : seule l'adresse change, et les routes restent identiques.

```cpp
void basculerEnPointAcces() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP("easyLearn-Setup");
  Serial.print("ap: reseau emis, IP ");
  Serial.println(WiFi.softAPIP());
  serveur.on("/config", HTTP_POST, []() {
    String nom = serveur.arg("ssid");
    String mdp  = serveur.arg("mdp");
    prefs.putString("ssid", nom);
    prefs.putString("mdp", mdp);
    serveur.send(200, "text/html",
                 "<p>Enregistre, redemarrage...</p>");
    delay(500);
    ESP.restart();
  });
  serveur.begin();
}
```

L'écriture passe par la bibliothèque Preferences, qui expose des paires clé-valeur typées dans la mémoire non volatile de la puce. Les chaînes y sont conservées après un redémarrage et même une coupure d'alimentation. Deux habitudes à prendre immédiatement : n'écrivez les identifiants que lorsqu'ils ont été testés avec succès, et ne les réaffichez jamais sur le port série, pas même en développement, car un journal copié dans un dépôt reste un mot de passe divulgué. Une variable drapeau en mémoire RAM indique si une configuration valide existe, ce qui évite de lancer le Wi-Fi avec une chaîne vide au premier démarrage.

L'alternative, plus sobre, consiste à préserver la plage d'adresses 192.168.4.0 réservée au mode point d'accès et à n'ouvrir le portail qu'après trois échecs consécutifs. Le compteur de tentatives se remet à zéro dès qu'une connexion aboutit. Ainsi, une coupure brève du routeur ne déclenche pas inutilement l'émission d'un réseau ouvert : le portail reste une solution de secours, pas le mode normal de fonctionnement. C'est précisément ce genre de détail qui distingue un prototype de quelque chose que l'on peut laisser tourner dans un placard pendant un an.
$lesson$),
  ('ard-c5-p13', 'ard-c5', 13, $lesson$Observer à distance : tableau de bord et persistance$lesson$, $lesson$
À ce stade, vos mesures arrivent au broker, mais elles disparaissent dès qu'aucun abonné n'écoute. Pour transformer ce flux en histoire, il faut les conserver. Deux approches se complètent. La première consiste à laisser un abonné permanent enregistrer chaque message dans un fichier ou une base de données légère, par exemple un script Python de quelques dizaines de lignes qui tourne sur un vieux portable. La seconde consiste à faire réagir les données : un seuil dépassé déclenche une notification, un message de commande ou l'allumage d'un relais. Dans les deux cas, l'ESP32 reste inchangé : il publie, il ne stocke pas, il n'alerte pas. Cette séparation est un choix d'architecture délibéré, car la mémoire et le temps processeur d'un microcontrôleur sont trop précieux pour héberger un historique.

Le tableau de bord, lui, peut être aussi simple ou aussi riche que nécessaire. Pour commencer, une page unique servie par l'ESP32 qui interroge /api/mesures toutes les cinq secondes et dessine une courbe dans un élément canvas suffit à visualiser la tendance. Pour aller plus loin, une application séparée qui s'abonne aux topics et affiche plusieurs objets côte à côte devient pertinente dès que vous possédez deux ou trois cartes. Dans tous les cas, gardez à l'esprit la règle de la mémoire : une page lourde ne peut pas être servie par la puce, et un historique de plusieurs mois n'a pas sa place en mémoire vive. Le navigateur gère l'affichage, le broker relaie, la base conserve, la carte mesure.

Voici la logique de rafraîchissement côté page, telle qu'on l'intègre dans un littéral HTML servi par le serveur. Le code s'exécute dans le navigateur, jamais sur la carte, et c'est précisément l'intérêt de la séparation.

```html
<script>
async function maj() {
  const r = await fetch('/api/mesures');
  const d = await r.json();
  document.getElementById('temp').textContent = d.temp + ' C';
  document.getElementById('hum').textContent = d.hum + ' %';
}
setInterval(maj, 5000);
maj();
</script>
```

Un dernier point métrique vous sera utile pour dimensionner. Une publication MQTT typique de cent cinquante octets, toutes les dix secondes, représente moins d'un mégaoctet par mois : négligeable même sur une liaison partagée. En revanche, publier cent fois par seconde consommera du processeur, de la bande passante et de la batterie, sans apporter d'information sur une grandeur qui ne varie pas à cette vitesse. Mesurez la cadence réelle de votre phénomène avant de choisir l'intervalle : la fréquence d'échantillonnage est une décision physique, pas un réglage technique.
$lesson$),
  ('ard-c5-p14', 'ard-c5', 14, $lesson$À retenir$lesson$, $lesson$
- L'ESP32 se connecte en mode station avec WiFi.begin, mais l'état se relève avec WiFi.status jusqu'à WL_CONNECTED.
- Une connexion réseau ne doit jamais bloquer la boucle principale : on la pilote avec millis() et une machine à états.
- Le serveur web s'appuie sur WebServer, des routes enregistrées et un appel permanent à handleClient() dans loop().
- Le HTML sert l'humain, le JSON sert les applications : exposez une route par ressource, avec le bon type MIME.
- Un gestionnaire de route est court et ne lit jamais le capteur directement : il publie l'état courant, il ne le produit pas.
- MQTT repose sur un broker, des topics hiérarchiques et un modèle publication-abonnement indépendant des adresses IP.
- PubSubClient exige mqtt.loop() à chaque itération, sans quoi aucun message reçu n'arrive jamais en callback.
- La reconnexion suit un délai croissant, doublé jusqu'à trente secondes, remis à zéro dès que la liaison aboutit.
- Le chien de garde esp_task_wdt transforme un blocage silencieux en redémarrage contrôlé.
- Chaque étape réseau s'affiche sur le port série avec un libellé stable : c'est votre principal outil de diagnostic.
- Le mode combiné permet d'offrir un portail de configuration quand le réseau configuré est introuvable.
- Les identifiants se conservent en mémoire non volatile via Preferences, et ne reviennent jamais sur le port série.
$lesson$),
  ('ard-c5-p15', 'ard-c5', 15, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Oublier serveur.handleClient() ou mqtt.loop() dans loop(), ce qui donne un port fermé ou des messages jamais reçus.
- Utiliser un délai long juste avant d'attendre une requête : le serveur ne peut alors répondre que par à-coups.
- Publier sans vérifier mqtt.connected(), puis conclure à tort que le broker est en cause.
- Réutiliser le même identifiant MQTT pour deux cartes, ce qui provoque une déconnexion en alternance permanente.
- Lire un DHT22 toutes les cent millisecondes : le capteur renvoie alors des valeurs invalides ou nulles.
- Écrire du texte non échappé à la main dans une réponse JSON, et produire un document illisible pour le client.
- Laisser le mot de passe Wi-Fi en clair dans un fichier source destiné à être partagé.
- Oublier que millis() déborde après environ cinquante jours, et comparer des valeurs absolues au lieu de différences.
- Créer une machine à états Wi-Fi sans état de perte de liaison : la carte reste marquée connectée alors que le réseau est tombé.
- Augmenter le délai du chien de garde pour masquer une boucle réellement bloquante, au lieu de trouver la cause.
- Déclencher le portail de configuration à chaque démarrage raté, ce qui émet un réseau ouvert sans nécessité.
- Confondre la charge utile MQTT et son sujet : le filtre d'abonnement porte sur le sujet, jamais sur le contenu.
$lesson$),
  ('ard-c5-p16', 'ard-c5', 16, $lesson$Pour aller plus loin$lesson$, $lesson$
Les documents officiels d'Espressif sur l'API Wi-Fi détaillent les événements de connexion, les modes combinés station et point d'accès, ainsi que les options d'alimentation qui permettent de réveiller périodiquement une carte endormie. Le dépôt PubSubClient contient un guide d'utilisation et la liste exacte des codes renvoyés par la fonction d'état, à garder à portée de main pendant le débogage. Le site mqtt.org publie la spécification complète du protocole, courte à lire, qui explique les en-têtes, les niveaux de service et le mécanisme de maintien de session.

Pour consolider, trois pistes progressives. Premièrement, ajoutez le portail de configuration décrit ci-dessus, avec persistance dans Preferences et compteur d'échecs. Deuxièmement, ajoutez une persistance des mesures dans un petit tampon circulaire, rejoué à la reconnexion du broker, puis comparez le nombre de points récupérés pendant une coupure volontaire de trente secondes. Troisièmement, mettez en place la mise à jour à distance avec une authentification, puis testez-la volontairement avec un firmware dégradé pour vérifier que vous conservez un chemin de récupération. Chacune de ces pistes mobilise les mêmes briques que ce chapitre, ce qui est le signe que les fondamentaux sont acquis.

Des ressources officielles complètent utilement la lecture :

- Documentation ESP-IDF sur le Wi-Fi, espressif.com, section networking.
- Dépôt PubSubClient de Nick O'Leary sur GitHub, guide et exemples.
- Spécification MQTT sur mqtt.org, version 5.0 et retours en arrière.
- Exemples ESP32 de la carte Arduino, dossier WiFi et exemples WebServer.
- Bibliothèque Preferences de l'ESP32, gestion clé-valeur en mémoire non volatile.
$lesson$),
  ('ard-c5-p17', 'ard-c5', 17, $lesson$Et maintenant : passez à la supervision$lesson$, $lesson$
Le prochain chapitre transforme cette station isolée en système complet : vous concevrez l'architecture d'un ensemble de capteurs, vous stockerez les mesures publiées ici dans une base et vous construirez un tableau de bord qui les visualise. Avant de vous y aventurer, assurez-vous d'avoir obtenu les quatre résultats de ce chapitre sur votre propre matériel : une connexion Wi-Fi visible avec son adresse IP, une page ouverte depuis un navigateur, une ligne de JSON lue dans un client MQTT et une commande reçue qui modifie réellement le comportement de la carte. Si les quatre fonctionnent, vous maîtrisez la brique la plus décisive du parcours : votre objet parle au réseau, et le réseau lui répond.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('ard-c6-p1', 'ard-c6', 1, $lesson$Rappel : ce que les cinq chapitres précédents vous ont donné$lesson$, $lesson$
Bienvenue dans le sixième et dernier chapitre du parcours Arduino/ESP32 embarqué. Les cinq chapitres précédents vous ont appris à faire clignoter une LED, à lire un capteur analogique, à piloter un afficheur sur un bus, à écrire une machine à états avec interruptions, puis à connecter l'ESP32 en Wi-Fi et à publier des messages MQTT. Chacun de ces chapitres était délibérément clos sur lui-même : un exercice, une notion, un résultat visible sur l'établi. Ce dernier chapitre change d'échelle. Il ne vous apprend pas une nouvelle fonction de la bibliothèque Arduino, il vous apprend à assembler, à fiabiliser et à superviser : c'est-à-dire à transformer une accumulation de modules de démonstration en un système qui tourne pendant des semaines, seul, sans vous, et dont on peut lire les mesures depuis un tableau de bord. C'est la différence entre un prototype qui a marché une fois et un objet connecté réellement déployé.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées dans un exemple complet. Vous rédigerez un cahier des charges court mais réel : besoins, contraintes, interfaces, critères d'acceptation mesurables. Vous dessinerez l'architecture matérielle : composants, bus, pins, alimentation, protection, boîtier. Vous découperez le firmware en modules indépendants reliés par une structure de mesure unique, au lieu d'un fichier monolithique de deux mille lignes. Vous construirez la chaîne complète du flux de données : acquisition fiabilisée par échantillonnage et filtrage, publication sur des topics MQTT normalisés, stockage dans une base orientée temps, restitution sur un tableau de bord avec alertes. Vous ajouterez les mécanismes qui font la différence en production : watchdog matériel, reconnexion avec back-off exponentiel, journalisation, mise à jour à distance. Et vous verrez comment tout cela se vérifie : tests, banc d'essai, recette, puis mise en service et maintenance.

Le fil rouge de ce chapitre est une station météo connectée nommée, par commodité, Station. Elle mesure la température, l'humidité relative et la pression atmosphérique depuis un capteur I2C unique, affiche les valeurs sur un écran local, les enregistre dans un fichier CSV sur carte SD, les publie en MQTT vers un broker local, et les verse dans une base temporelle alimentant un tableau de bord. Un bouton force le publication immédiate, une LED signale l'état de la liaison, un watchdog surveille que la boucle principale tourne bien. Ce périmètre est volontairement modeste : il est réalisable en une semaine avec le matériel du parcours, mais il contient, à l'identique, tous les problèmes d'un projet professionnel. Vous pourrez ensuite élargir le champ : plus de capteurs, plus de stations, boîtier imprimé 3D, alimentation solaire. L'architecture que vous apprenez ici ne change pas quand le projet grossit ; seule la quantité de code augmente.



Le premier chapitre vous a appris le niveau bas : une broche numérique sortant un signal, une LED qui s'allume, un bouton dont le contact rebondit pendant quelques millisecondes et qu'il fallait débouncer pour lire une valeur stable. Ce détail, en apparence anecdotique, se retrouve partout dans un projet connecté : tout ce qui vient du monde physique est bruyant, mécanique, imprévisible. Le second chapitre a ajouté la mesure : entrée analogique convertie par un convertisseur analogique-numérique, rapport de conversion en tension, fonction de transfert d'un capteur, puis modulation de largeur d'impulsion pour commander un actionneur sans variation de tension. Vous y avez aussi découvert le moniteur série, premier outil de diagnostic d'un firmware.

Le troisième chapitre vous a fait franchir la frontière des bus de communication. Plutôt que de dédier une broche à chaque périphérique, on interroge plusieurs composants sur le même fil d'horloge et le même fil de données, en adressant chacun par une adresse fixée par fabricant. Ce déplacement conceptuel est essentiel : dans un projet connecté, le nombre de capteurs dépasse vite le nombre de broches disponibles, et l'extensibilité passe par des bus, pas par des câbles supplémentaires. Le quatrième chapitre a traité du temps : la machine à états qui découpe une tâche complexe en transitions, les interruptions qui réagissent à un événement sans interroger en permanence, et les temporisations non bloquantes qui évitent le piège de la fonction d'attente pendant laquelle le reste du programme s'arrête.

Le cinquième chapitre a enfin ouvert la porte au réseau : association à un point d'accès, requête DHCP, serveur web intégré répondant à un navigateur, puis protocole MQTT où un objet publie un message sur un topic et laisse un broker s'occuper de le distribuer à qui s'y est abonné. Ces deux modèles, requête-réponse et publication-diffusion, coexistent dans tout objet connecté : on interroge l'objet pour le piloter, il diffuse ses mesures pour les supervisionner. Ce qui manque maintenant, c'est l'assemblage. Aucun de ces chapitres n'a répondu à ces questions : comment choisir les composants sans se tromper, comment structurer vingt fichiers sources au lieu d'un seul, comment garantir que la station reparte toute seule après une coupure de réseau, comment stocker des mois de mesures et les relire utilement, comment savoir qu'un seuil est dépassé avant qu'un utilisateur ne se plaigne. C'est exactement le programme des pages qui suivent.

Voici les objectifs de ce chapitre, formulés comme des résultats vérifiables plutôt que comme des notions. Vous saurez rédiger un cahier des charges dont chaque exigence est mesurable. Vous saurez justifier le choix de chaque composant et de chaque broche, et produire un schéma de câblage lisible par quelqu'un d'autre. Vous saurez découper un firmware en modules avec des en-têtes explicites et une structure de mesure partagée. Vous saurez définir un schéma de topics MQTT et un format de message qui tiennent dans le temps. Vous saurez choisir une fréquence d'échantillonnage et une stratégie de filtrage adaptées à la grandeur mesurée. Vous saurez brancher un tableau de bord qui affiche l'état réel du système, pas des valeurs figées. Vous saurez écrire la procédure de mise à jour à distance et la tester. Et vous saurez écrire le court rapport de recette qui prouve que tout cela fonctionne selon les critères décidés au départ.
$lesson$),
  ('ard-c6-p2', 'ard-c6', 2, $lesson$Cadrer : pourquoi un cahier des charges avant le moindre code$lesson$, $lesson$
La première étape d'un projet connecté n'est pas technique, elle est administrative, et c'est précisément pour cela qu'on la néglige. Un cahier des charges, parfois appelé cahier des fonctions, est le document qui fixe d'accord entre vous et la personne qui vous commande, ou entre le vous d'aujourd'hui et le vous dans six mois, sur ce que le système doit faire et sur la manière dont on saura qu'il le fait bien. Il tient en quelques pages. Il ne contient aucune ligne de code, aucun schéma de câblage, aucun nom de bibliothèque. Il contient des besoins, des contraintes, des interfaces et des critères d'acceptation. Sa valeur n'est pas dans le document lui-même mais dans les décisions qu'il vous évite de prendre trois fois : chaque question à laquelle vous répondez une fois, à l'avance, est une question que vous ne rallumerez pas au milieu de la nuit.

Distinguez soigneusement les quatre catégories, car elles ne se remplissent pas de la même manière. Les besoins décrivent ce que l'utilisateur veut obtenir : connaître la température d'une pièce à distance, être alerté si un seuil est franchi, consulter l'historique d'une semaine. Les contraintes décrivent dans quelles limites le système doit vivre : tension d'alimentation, enveloppe physique, budget, autonomie, plage de température ambiante, norme d'étanchéité. Les interfaces décrivent les points de contact avec le reste du monde : le bus et les adresses des capteurs, les broches occupées, le format des messages publiés, le protocole et les ports utilisés, le format des fichiers produits. Les critères d'acceptation décrivent comment vous vérifierez, objectivement et à un instant donné, que tout le reste est respecté : une mesure de température à moins d'un demi-degré près, une reconnexion en moins de trente secondes, trente jours de journal sans un seul enregistrement manquant.

La règle d'or des critères d'acceptation est qu'ils doivent être mesurables, pas séduisants. Écrire « le système doit être fiable » ne permet pas de conclure. Écrire « sur une période de trente jours, le journal local contient 99,5 pour cent des échantillons attendus et le tableau de bord affiche une valeur datée de moins de deux minutes » permet de conclure, de signer, et de savoir quelle partie réparer quand ce n'est pas atteint. Prenez l'habitude, dès ce chapitre, de formuler chaque exigence avec un nombre, une unité et une durée. Le tableau suivant montre un extrait de cahier des charges où chaque ligne suit ce principe.

| Exigence | Mesure | Critère d'acceptation |
| --- | --- | --- |
| Précision de température | Comparaison avec un étalon étalonné | Écart inférieur à 0,5 °C entre -10 °C et +50 °C |
| Continuité de la publication | Messages reçus par le broker sur 30 jours | Plus de 99,5 pour cent des échantillons attendus |
| Temps de reconnexion | Débranchement puis rétablissement du point d'accès | Retour de la publication en moins de 30 secondes |
| Tenue de la boucle | Compteur de passages de la boucle principale | Zéro redémarrage non désiré sur 7 jours |
| Lisibilité locale | Afficheur pendant une coupure réseau | Dernière mesure visible et datée en moins de 2 secondes |

Notez au passage ce que ce tableau fait : il transforme des vagues aspirations en tests. Chaque ligne devient une manipulabilité vérifiable sur l'établi. C'est aussi ce tableau qui vous protège de la dérive de périmètre, ce fléau des projets connectés : au bout de deux semaines, quelqu'un, souvent vous, trouve qu'il serait sympathique d'ajouter un détecteur de pluie, une horloge à temps réel, une reconnaissance vocale et un écran tactile. Sans cahier des charges, chaque idée est discutée à chaud et finit dans le code. Avec un cahier des charges, vous demandez simplement laquelle des exigences existantes cette idée sert, et si elle n'en sert aucune, elle part dans la liste des évolutions possibles, pas dans le sprint en cours.
$lesson$),
  ('ard-c6-p3', 'ard-c6', 3, $lesson$Poser le périmètre du projet fil rouge$lesson$, $lesson$
Notre station météo, elle, commence par une phrase de cahier des charges qu'on peut écrire en une ligne : mesurer en continu la température, l'humidité et la pression d'un local, les afficher sur place, les enregistrer localement, les publier vers un broker, et alerter au-delà de seuils réglables, le tout en survivant à une coupure réseau sans intervention. Cette phrase fixe le périmètre. Tout ce qui n'y figure pas est hors sujet pour la version une : pas de contrôle de chauffage, pas d'application mobile, pas d'interface graphique riche sur l'écran, pas de multi-zones. Un périmètre étroit livré et documenté vaut infiniment plus qu'un périmètre large abandonné au troisième module.

Les fonctions attendues se déclinent ensuite en une liste courte. Acquisition à cadence fixe de trois grandeurs issues d'un capteur I2C unique, avec détection d'erreur de bus et valeur sentinelle plutôt qu'une mesure fausse. Affichage local des trois valeurs avec horodatage et état de la liaison. Journalisation horodatée sur carte mémoire au format texte, avec un fichier par jour pour limiter la taille des lectures. Publication MQTT d'un message JSON par échantillon sur un topic dont le nom encode l'identifiant de la station et la nature de la mesure. Réception des commandes à distance sur un topic dédié, permettant au moins de relire un seuil sans reflasher. Et publication de l'état de la station elle-même, de sorte qu'un tableau de bord puisse distinguer « la température est de vingt degrés » de « la station ne répond plus depuis vingt minutes ».

Les contraintes se formulent avec la même précision. Alimentation sur une source 5 volts stable, avec une consommation moyenne inférieure à cinq cents milliampères pour laisser la place à une extension sur batterie. Plage de fonctionnement de zéro à quarante degrés en intérieur, sans prétention extérieure pour cette version. Boîtier fermé ventilé, sans revendication d'étanchéité que nous ne pourrions pas mesurer. Budget matériel plafonné, en privilégiant des composants déjà présents dans le parcours afin de ne pas ajouter de délai d'approvisionnement. Et temps de réalisation borné : une semaine de travail effectif pour la version un, ce qui interdit d'emblée tout ce qui demanderait d'apprendre un nouveau framework de bout en bout.

Les interfaces, enfin, se figent par écrit avant le premier fichier source. Bus I2C pour le capteur, avec adresses lues à l'exécution et affichées au démarrage pour éviter les mauvaises surprises de soudure. Broches SPI pour la carte mémoire, avec un numéro de sélection d'esclave conservé dans la configuration. Port série pour le diagnostic, à un débit fixe documenté. Compteur de publications et compteur d'erreurs dans chaque message, pour que la supervision sache elle-même si elle est bien informée. Le format du message, ses noms de champs et leur unité sont écrits dans le cahier des charges eux aussi : c'est un contrat, et un contrat se respecte même quand on est seul.

```text
Extrait du cahier des charges - Station meteo v1

1. Besoins
   B1  Mesurer T, HR, P toutes les 10 secondes
   B2  Afficher les valeurs sur place avec horodatage
   B3  Journaliser sur carte SD, un fichier par jour
   B4  Publier en MQTT un JSON par echantillon
   B5  Alerter au-dela de trois seuils reglables

2. Contraintes
   C1  Alimentation 5 V, consommation moyenne < 500 mA
   C2  Budget materiel < 40 EUR
   C3  Redemarrage automatique apres panne reseau
   C4  Aucune intervention humaine attendue sur 30 jours

3. Interfaces
   I1  I2C  : capteur T/HR/P       (adresse lue au demarrage)
   I2  SPI  : carte microSD        (CS = 5)
   I3  UART : diagnostic           (115200 bauds)
   I4  MQTT : meteo/<id>/data      (publication)
   I5  MQTT : meteo/<id>/cmd       (commandes)

4. Criteres d'acceptation
   A1  Ecart T < 0.5 degre cote a cote avec etalon
   A2  > 99.5 % des echantillons recus sur 30 jours
   A3  Retour de publication < 30 s apres coupure WiFi
   A4  Zero redemarrage non desire sur 7 jours
```

Ce bloc de texte vaut à lui seul plusieurs heures de discussion ultérieures. Il est court, il est daté, il est versionné comme tout le reste du projet. Quand, au bout de la troisième journée, vous hésiterez sur l'utilité d'un écran couleur, vous le relirez et vous aurez votre réponse sans débat. Une dernière recommandation sur ce sujet avant de passer au matériel : écrivez ce document dans le dépôt du projet, à côté du code, et acceptez de le modifier par écrit quand le besoin évolue. Un cahier des charges vivant mais à jour vaut mieux qu'un cahier des charges parfait qu'on n'a jamais ouvert après le premier jour.
$lesson$),
  ('ard-c6-p4', 'ard-c6', 4, $lesson$Architecture matérielle : choisir, câbler, protéger$lesson$, $lesson$
Un projet connecté se joue autant sur l'établi que dans l'éditeur. Le firmware le plus soigné du monde ne sauvera pas une station dont l'alimentation tombe en dessous de la tension de seuil dès que le module radio émet, ou dont le bus de données montre une ligne haute paresseuse faute de résistance de traction. L'architecture matérielle, c'est l'ensemble des décisions physiques : quels composants, sur quels bus, alimentés comment, protégés comment, rangés où. Elle se décide sur le papier, avant l'achat, à partir du cahier des charges que vous venez d'écrire. Chaque composant retenu doit répondre à une exigence identifiable ; tout composant qui n'y répond pas est du poids, de la consommation et de surface de panne.

Notre station utilise un seul capteur intégré pour les trois grandeurs principales, ce qui est un choix d'architecture en soi : un composant unique sur un seul bus, une seule source d'horodatage, une seule procédure de lecture, une seule calibration. Le modèle courant pour ce rôle est un capteur combiné température, humidité et pression, interrogeable en I2C et consommant quelques milliamperes en fonctionnement. Au lieu de répartir trois mesures sur trois composants de trois fabricants, on gagne en cohérence : les trois valeurs partagent le même instant de prélèvement, ce qui simplifie la construction du message publié et évite les décalages artificiels entre grandeurs affichées côte à côte. La contrepartie, un point de défaillance unique, est acceptée et documentée : le cahier des charges annonce que la perte du capteur met la station hors service, et la logiciel signale l'erreur au lieu d'afficher des zéros trompeurs.

Le choix des broches suit trois règles simples. D'abord, respecter les broches dont la fonction est fixée par le silicium : certaines entrées sorties du microcontrôleur sont particulièrement adaptées aux communications série matérielles, d'autres servent au démarrage du processeur, d'autres encore sont reliées à un régulateur interne. Les datasheets des cartes de développement indiquent quelles broches éviter pour l'usage courant, et il est plus sage de les écarter même quand on ne les compte pas utiliser. Ensuite, limiter le nombre de points de configuration : un capteur I2C partagé, une carte mémoire sur SPI, un écran sur le même I2C, une LED et un bouton sur deux broches simples. Enfin, regrouper physiquement : garder les fils de bus courts, l'alimentation et la masse ensemble, et réserver une broche pour la diagnostique série afin de ne jamais se retrouver sans voix pour parler du firmware qui ne répond plus.

La question de l'alimentation mérite un paragraphe entière parce qu'elle cause la majorité des comportements inexpliqués en laboratoire. Une carte de développement se nourrit en général par une tension de cinq ou de trois volts trois, fournie par le câble de programmation ou par un régulateur externe. Le module radio de l'ESP32, lui, émet des pointes de courant brèves mais importantes lors de chaque connexion ou de chaque émission ; si l'alimentation ou le câble ne suit pas, la tension redescend, le processeur réinitialise silencieusement, et votre station redémarre en boucle sans jamais afficher la moindre erreur. Les remèdes sont connus : alimentation dimensionnée avec une marge généreuse, condensateur de découplage placé près de la carte, câble court et de bonne section, et mesure réelle de la tension avec un multimètre pendant une session de publication en rafale plutôt qu'au repos. Un banc de test d'alimentation coûte moins cher qu'une semaine de doute.

La protection mécanique et environnementale se pense aussi dès le départ, même pour une station destinée à rester sur une étagère. Prévoir des trous de fixation alignés avec le boîtier, un passage de câble avec presse-étoupe si le boîtier sort, un accès au bouton de remise à niveau et au connecteur de programmation sans démontage complet, et une ventilation qui évite la condensation sans laisser courir la poussière sur les pistes. Si la station doit finir à l'extérieur, la contrainte d'étanchéité devient un vrai sujet avec un indice IP, des joints et un test d'immersion ; pour cette version, nous l'évitons explicitement et le cahier des charges le dit, ce qui est préférable à promettre une résistance à la pluie qu'aucun de nous ne mesurera.

| Rôle | Broche ou bus | Justification |
| --- | --- | --- |
| Capteur T, HR, P | Bus I2C, SDA et SCL dédiées | Deux fils pour plusieurs capteurs, adressage par fabricant |
| Carte mémoire | Bus SPI, sélection sur broche 5 | Débit élevé pour l'écriture de journaux continus |
| Écran local | Sur le même bus I2C | Adresse distincte, aucun câble supplémentaire |
| État de liaison | Une broche numérique | Diode pilotée en écriture, visible de loin |
| Commande manuelle | Une broche numérique avec tirage interne | Bouton vers la masse, lecture sans résistance externe |
| Diagnostic | Port série matériel | Journal horodaté consultable depuis un ordinateur |

Le schéma de câblage qui en résulte tient dans un diagramme ASCII lisible par n'importe qui, y compris par la personne qui reprendra le projet dans six mois. Prenez l'habitude de le produire avant le câblage, puis de le corriger après, pour qu'il reste exactement fidèle à l'établi : un schéma faux est pire que pas de schéma du tout, car il inspire une confiance que la réalité ne justifie pas.

```text
                        +----------------------+
   5 V  +---------------|  Carte ESP32         |
        |   condensateur |                      |
        +---||-----------|  SDA --------+-------+---- SDA  [ Capteur T/HR/P ]
                        |  SCL --------|-------+---- SCL  |
        masse ----------+--------------+-------+-------- masse
                        |                      |
                        |  broche 5  ----------+---- CS   [ carte microSD ]
                        |  MOSI/MISO/SCK  -----+---- SPI bus
                        |                      |
                        |  broche 21 ----------+---- SDA  [ ecran local ]
                        |  broche 22  ----------+---- SCL  (partage bus I2C)
                        |                      |
                        |  broche 2   ---------|---- LED etat liaison
                        |  broche 0   ---------|---- bouton manuel
                        |                      |
                        |  TX/RX --------------|---- port serie diagnostic
                        +----------------------+
```
$lesson$),
  ('ard-c6-p5', 'ard-c6', 5, $lesson$Architecture logicielle : découper en modules$lesson$, $lesson$
La seconde architecture, celle du code, décide de tout ce qui arrivera après la première semaine. Deux façons de structurer un firmware Arduino s'offrent à vous. La première consiste à tout écrire dans le fichier principal, en empilant des variables globales et des appels dans la fonction de boucle, jusqu'à ce que le fichier devienne illisible et que la moindre modification casse un détail situé mille lignes plus haut. La seconde consiste à découper par responsabilité : un fichier d'en-tête et un fichier d'implémentation par rôle, avec des interfaces explicites, des responsabilités étroites et une circulation de données par une structure unique. Le second format demande vingt minutes d'effort supplémentaire au début, puis vous fait gagner des heures chaque semaine suivante. Pour un projet qui vit au-delà du banc de test, il n'y a pas d'hésitation.

Nos modules répondent chacun à une question précise. Le module de configuration rassemble les constantes : identifiant de station, adresses de bus, numéros de broches, cadence d'échantillonnage, seuils d'alerte, débit du port série, nom d'hôte réseau. Aucune autre partie du programme ne doit contenir de littéral numérique magique ; si vous changez un numéro de broche, vous ne modifiez qu'une ligne, et elle est au même endroit pour toutes les broches. Le module de mesure sait lire le capteur et retourner une structure d'échantillon complète, ou signaler un échec. Le module de liaison réseau maintient la connexion et sait publier un message préconstruit. Le module de stockage sait ouvrir le journal du jour et y ajouter une ligne. Le module d'affichage sait rendre les valeurs sur l'écran. Et le superviseur, seul détenteur de la boucle, décide de l'ordre des opérations et du moment où chaque action a lieu.

```text
station-meteo/
|-- platformio.ini          dependances, carte cible, options de build
|-- include/
|   |-- config.h             pins, adresses, seuils, identifiant
|   |-- echantillon.h        structure de mesure partagee
|   `-- versions.h           chaine de version du firmware
|-- src/
|   |-- main.cpp             setup() et loop() : l'orchestration seule
|   |-- mesures.cpp/.h       lecture capteur, filtrage, detection d'erreur
|   |-- liaison.cpp/.h       WiFi, MQTT, reconnexion, publication
|   |-- journal.cpp/.h       carte SD, rotation quotidienne, ecriture
|   |-- affichage.cpp/.h     rendu de l'ecran local
|   `-- veille.cpp/.h        watchdog, cadencement, compteurs d'etat
`-- test/
    `-- test_filtre/         tests unitaires du filtrage et des seuils
```

La pièce la plus importante de cette structure n'est pas un module mais une donnée : la structure d'échantillon qui circule d'un bout à l'autre du système. Elle contient l'horodatage, les trois mesures, l'état du capteur, un compteur de séquence et le drapeau d'erreur. Chaque module la reçoit ou la produit, mais aucun ne la reconstruit à sa façon. Cette discipline a trois effets immédiats. Le message publié, la ligne du journal et la chaîne affichée sur l'écran proviennent de la même source, donc ne peuvent pas divergir. L'ajout d'une quatrième grandeur se fait en ajoutant un champ à la structure et en l'affichant, sans rouvrir chaque fichier. Et les tests unitaires peuvent fabriquer un échantillon factice en trois lignes pour vérifier un seuil sans jamais toucher au matériel.

Une convention de nommage cohérente complète le découpage. Les fonctions publiques d'un module portent le nom du module devant l'action, de sorte qu'en lisant un appel dans le fichier principal, vous savez immédiatement quel fichier ouvrir. Les variables de configuration sont en majuscules ou en constantes, les états variables en minuscules. Les erreurs sont retournées sous forme d'un code ou d'un booléen explicite, jamais signalées par un affichage dispersé dans les profondeurs d'un module : c'est au superviseur de décider ce qu'on fait d'une erreur, car c'est lui qui connaît le contexte global. Aucun module n'affiche, n'envoie ni n'efface quoi que ce soit en silence.
$lesson$),
  ('ard-c6-p6', 'ard-c6', 6, $lesson$La boucle de mesure : échantillonner, filtrer, tolérer l'erreur$lesson$, $lesson$
Vient maintenant le cœur fonctionnel : le passage de la mesure brute à une valeur publiée digne de confiance. Trois questions se posent, dans cet ordre. À quelle fréquence lire ? Que faire des lectures aberrantes ? Que faire quand la lecture échoue ? La fréquence dépend de la grandeur et de l'usage : la température d'un local varie lentement, et lire dix fois par seconde ne produit que de la redondance, voire de la chaleur dégagée par le capteur lui-même si on le force en fréquence. Une cadence de dix secondes est largement suffisante pour un usage domestique et laisse du temps au reste des tâches. Le cahier des charges la fixe, et le code la respecte sans exception : une cadence décidée à l'écrit, pas au hasard d'une boucle trop rapide.

La question des valeurs aberrantes est plus subtile. Un bus I2C perturbé, une lecture prise pendant une transition d'alimentation ou une valeur retournée en virgule signée peuvent produire un échantillon complètement déraisonnable : moins quatre-vingts degrés dans un salon, ou une humidité de neuf cents pour cent. Publier une telle valeur, c'est empoisonner la base de données et le tableau de bord pendant des heures, car une moyenne glissante débordera longtemps après que la cause aura disparu. Deux défenses complémentaires s'appliquent. La première est la validation de domaine : toute valeur hors plage physiquement plausible est rejetée avant même d'être considérée. La seconde est la limitation de variation : un saut trop brutal d'un échantillon au suivant est traité comme suspect, car aucune grandeur thermique réelle ne décroche de vingt degrés en dix secondes.

Le filtrage lui-même se limite, pour ce projet, à une moyenne glissante pondérée : le nouvel échantillon pèse dans la valeur publiée, l'ancien s'efface progressivement, sans stocker d'historique long. Le paramètre de lissage se règle selon la réactivité souhaitée : un lissage fort donne une courbe calme mais retarde la perception d'un événement réel ; un lissage faible suit l'instant mais laisse passer les pic. Pour une station domestique, un facteur autour d'un dixième donne un bon compromis, et il est écrit dans la configuration pour pouvoir être essayé sans rouvrir le code. Surtout, le lissage s'applique à la valeur affichée et publiée, jamais à la détection d'erreur : c'est la valeur brute qui décide si le capteur répond.

L'échec, enfin, est un cas normal et non une exception à masquer. Quand la lecture échoue, la structure d'échantillon part quand même, avec son drapeau d'erreur posé et ses mesures conservées à leur dernière valeur connue ou marquées invalides selon ce que dit le cahier des charges. Le module de liaison peut alors publier un message dont le champ d'état indique la panne, le journal inscrit une ligne d'incident, et l'écran affiche une mention explicite. C'est la différence entre un système honnête et un système qui affiche trente-neuf degrés pendant que le capteur est débranché. La station reste en place, continue de tourner, continue d'alerter sur son propre dysfonctionnement, et se rétablit d'elle-même si le capteur revient.

```cpp
// Noyau de la boucle : cadencement, acquisition, publication.
// Les fonctions de module sont volontairement absentes de cet apercu.

void loop() {
  veilleAlimenter();                    // arrose le watchdog materiel

  if (!cadenceAtteinte(millis())) return;  // rien a faire avant la prochaine fenetre

  Echantillon e = lireCapteur();        // lecture + validation de domaine

  if (e.valide) {
    e.valeurFiltree = lisser(e.valeurFiltree, e.bruit, FACTEUR_LISSAGE);
    journalAjouter(e);                  // ecriture locale, priorite haute
    liaisonPublier(e);                  // publication MQTT en best effort
    ecranAfficher(e);
    seuilsVerifier(e);                  // alerte si depassement
    etatPublications++;
  } else {
    etatErreurs++;
    ecranAfficherErreur(e.cause);
    journalIncident(e.cause);
  }

  prochaineFenetre += CADENCE_MS;       // cadence fixe, pas de derive
}
```

Notez deux détails de cette boucle, tous deux issus de l'expérience plutôt que de la théorie. Le premier est que la cadence est calculée par addition d'une constante à un compteur, et non par un délai relatif : ainsi, même si une itération prend plus de temps que prévu, la station rattrape son retard par paliers au lieu de dériver lentement et d'afficher des intervalles de plus en plus irréguliers dans le journal. Le second est que les compteurs d'erreurs et de publications sont incrémentés dans la boucle eux aussi : ils deviennent les données d'entrée du tableau de bord, et c'est par eux que vous saurez, plus tard, si la station fonctionne réellement plutôt que de simplement publier.

Il reste une erreur classique à éviter à ce stade : la tentation de l'attente bloquante. Une fonction qui suspend l'exécution pendant une seconde paraît inoffensive, mais pendant cette seconde, le bouton n'est pas lu, l'écran n'est pas rafraîchi, la connexion n'est pas entretenue, et le watchdog, s'il est configuré en dessous de cette durée, redémarre la carte. La cadence doit toujours être gérée par comparaison d'horodatage, comme ci-dessus, jamais par pause. Ce réflexe, acquis au chapitre sur les automates, est ici décisif : la boucle doit rester courte, prévisible et toujours disponible pour réagir à ce qui arrive entre deux mesures.
$lesson$),
  ('ard-c6-p7', 'ard-c6', 7, $lesson$Publier : MQTT, topics et formats de message$lesson$, $lesson$
La donnée de capteur n'a de valeur que si elle quitte la pièce. Le chapitre précédent vous a présenté MQTT : un objet qui publie un message sur un topic, un broker qui le reçoit, et un ou plusieurs abonnés qui le récupèrent sans que l'émetteur ne sache ni qui ils sont, ni même s'il y en a. Ce modèle est parfaitement adapté à notre station, qui n'a rien à demander à personne et qui produit simplement un flux régulier. Reste à prendre les décisions qui, elles, engagent les années qui viennent : le nommage des topics, la forme du message, la qualité de service, et le comportement quand le broker n'est pas là.

Le nommage des topics est un sujet de gouvernance, pas de syntaxe. Un topic est une chaîne hiérarchique, séparée par des barres obliques, et sa structure dit comment on pourra s'y abonner plus tard. Écrire meteo/data revient à jeter tout sur une seule piste, ce qui devient vite intenable dès qu'une seconde station apparaît, car aucun abonné ne peut alors isoler une station sans filtrer le débit complet. Préférer une arborescence où le premier niveau décrit l'application, le second l'identifiant de la station et le troisième la nature du message laisse à chaque consommateur le choix de sa portée : s'abonner à tout pour un tableau de bord global, à une seule station pour le dépannage, ou à une seule catégorie pour une alerte. L'identifiant de station lui-même se dérive d'un identifiant matériel stable de la puce, afin qu'il ne dépende pas de la personne qui a flashé le dernier firmware.

```text
Arborescence des topics retenue pour le projet

meteo/
|-- <station>/data           echantillons periodiques (JSON)
|-- <station>/state          etat de la station (toutes les 60 s)
|-- <station>/cmd            commandes recues (JSON)
`-- <station>/alert          alertes de seuil (JSON, QoS 1)

Le stockeur s'abonne a  meteo/+/data     (toutes les stations)
L'operateur  s'abonne a  meteo/+/alert   (toutes les alertes)
Le debogueur s'abonne a  meteo/station-a/data  (une seule station)

Identifiant de station : derive de l'adresse MAC, lisible et stable.
Exemple : station-a3f2c1  (ne change jamais sans reflash intentionnel)
```

Le format du message lui-même oppose deux familles. Le format clé-valeur compact, séparateur fixe, tient en quelques octets et se parse en deux lignes de code, au prix d'une ambiguïté immédiate dès qu'un champ contient le séparateur. Le format structuré, type JavaScript Object Notation, s'auto-documente, porte ses unités dans les noms de champs, supporte les valeurs nulles et les champs supplémentaires sans casser les anciens abonnés. Pour un tableau de bord moderne, le second choix s'impose : la surcharge de quelques dizaines d'octets par message est dérisoire face au gain en robustesse. La règle à retenir n'est pas le format en soi, mais le fait qu'il soit écrit dans le cahier des charges et qu'il ne change jamais sans version, car c'est lui qui relie le firmware à tout le reste de l'écosystème.

```json
{
  "station": "station-a3f2c1",
  "seq": 48213,
  "ts": 1770000000,
  "mesures": { "t_c": 21.4, "hr_pct": 48.2, "p_hpa": 1013.6 },
  "filtre": { "t_lisse": 21.3 },
  "etat": { "capteur": "ok", "sd": "ok", "rssi_dbm": -61, "uptime_s": 92418 },
  "erreur": null
}
```

Lisez ce message comme un contrat. Chaque champ porte une unité dans son nom, ce qui supprime toute interprétation ultérieure. Le compteur de séquence permet au stockeur de détecter un trou dans la série, même en l'absence d'horodatage précis. L'état de la carte mémoire et le niveau de signal font partie de l'échantillon lui-même : la supervision doit pouvoir répondre à la question « la mesure est-elle fiable » sans croiser trois sources. Et le champ d'erreur, au format nul quand tout va bien, laisse la place à une cause explicite quand quelque chose ne va pas. Un message de ce type se relit dans un an sans documentation, ce qui est exactement le test qu'un format doit passer.

La qualité de service se choisit par intention. Au niveau zéro, le message est envoyé une fois, sans accusé de réception : c'est le choix par défaut pour un flux régulier où le message suivant répare le précédent, ce qui est le cas d'une mesure relevée toutes les dix secondes. Au niveau un, le broker confirme la réception et l'émetteur renvoie en cas d'absence de réponse, au prix d'un doublon possible que le stockeur doit savoir éliminer grâce au compteur de séquence. Au niveau deux, la garantie absolue existe mais le coût est disproportionné pour nos besoins. En pratique : mesures continues en niveau zéro, alertes et commandes en niveau un, jamais de niveau deux sur ce type de projet. Ajoutez à cela le testament MQTT, ce message de dernière volonté que le broker publie de lui-même quand la station cesse de répondre : c'est lui qui transforme un silence en information exploitable.

La reconnexion constitue le dernier point, et le plus important en termes de comportement réel. Quand le réseau tombe, une boucle naïve tente de se reconnecter en boucle serrée, ce qui sature la pile réseau, épuise l'alimentation et, dans le pire des cas, empêche physiquement le retour du service une fois le réseau rétabli. La stratégie correcte est un délai progressif : quelques secondes la première fois, puis un doublement, plafonné à une minute ou deux, avec une petite variation aléatoire pour éviter que toutes les stations du site ne reviennent à la même seconde et ne provoquent une tempête de connexions. Ce back-off, appliqué identiquement au Wi-Fi et à MQTT, est la différence entre un parc de stations qui se relève tout seul et un parc qui doit être relevé un par un.
$lesson$),
  ('ard-c6-p8', 'ard-c6', 8, $lesson$Stocker : base temporelle, rétention et honnêteté des séries$lesson$, $lesson$
Recevoir des messages ne suffit pas : il faut les conserver de manière à pouvoir les relire utilement. La question de stockage revient vite dans tout projet connecté, et la réponse dépend de la question posée aux données. Pour une recherche ponctuelle d'un événement précis, un fichier texte journalisé est parfait. Pour répondre à « quelle était la moyenne des quinze dernières minutes sur les trois stations » en quelques millisecondes, il faut un index temporel. Pour conserver dix ans de mesures sans que le disque ne cède, il faut de la compression et une politique de rétention. Une base de données orientée séries temporelles fait exactement cela : chaque point est identifié par un nom de mesure, un ensemble d'étiquettes et un horodatage, et les lectures se font par tranches de temps plutôt que par balayage complet.

L'étiquetage mérite attention, car c'est lui qui rend la donnée multi-stations exploitable. Chaque série est identifiée par son nom, par exemple meteo_temperature, et par des paires clé-valeur : la station, la pièce, l'unité, la version du firmware. Une bonne étiquette est stable et à faible cardinalité ; une mauvaise étiquette est un identifiant unique par mesure, ce qui multiplie le nombre de séries, explose la mémoire d'index et ralentit toutes les requêtes. On étiquette donc ce qui se répète : la station et son emplacement. On ne met jamais en étiquette ce qui varie à chaque point : la valeur, le compteur, l'horodatage. C'est une erreur classique qui se paie en performance au bout de quelques semaines.

```text
Chemin complet d'une mesure, de la salle a l'ecran

 [ capteur I2C ] --10 s--> [ firmware ]
                             |-- journal local (CSV, secours terrain)
                             `-- MQTT meteo/<id>/data
                                     |
                               [ broker ]
                                     |
                          +----------+-----------+
                          |                      |
                    [ stockeur ]            [ alerteur ]
                   ecrit dans la         publie vers le
                   base temporelle       canal d'alerte
                          |
                    [ base temps ]
                          |
                    [ tableau de bord ] --> [ regles d'alerte ]
```

La politique de rétention se décrit en deux temps : la durée de conservation des données brutes, puis la durée des agrégats. Garder chaque échantillon brut pendant quelques semaines permet les investigations fines ; au-delà, on remplace les séries par des moyennes horaires ou quotidiennes qui occupent une fraction de l'espace et suffisent à l'historique long. La plupart des bases temporelles gèrent cette rétention automatiquement, à condition de l'avoir configurée : une base sans rétention croît jusqu'à l'épuisement du disque, et la panne qui s'ensuit fait perdre l'intégralité des mesures, y compris celles que l'on croyait archivées. Trois jours de configuration valent mieux que trois mois de données perdues.

L'honnêteté des séries est une exigence de supervision autant que de stockage. Si le stockeur cesse d'écrire pendant une heure, que se passe-t-il-t-il sur le tableau de bord ? Les courbes se figent, et un observateur distrait conclura que la température est restée stable. La parade consiste à distinguer, dans le tableau de bord, l'absence de point et la valeur nulle, et à afficher l'état de la station à côté des mesures. Le testament MQTT mentionné plus haut alimente exactement cette information : dès que le broker détecte la disparition de la station, il publie l'état hors-ligne, et le tableau de bord peut afficher une mention explicite plutôt qu'un silence trompeur. Un système de mesure qui ne dit pas quand il est aveugle est plus dangereux qu'un système qui s'arrête.

En complément du stockage distant, le journal local garde une place défendue : c'est la source qui fonctionne quand le réseau est absent, et la seule accessible sur place sans aucun équipement. Le format texte horodaté, un fichier par jour, avec une ligne d'en-tête portant les unités, se relit dans n'importe quel tableur et se récupère sur une carte mémoire sortie de la station. La rotation quotidienne évite un fichier unique devenu illisible, et une durée de rétention locale de quelques semaines évite l'encodage des cartes. Le journal local ne remplace pas la base : il couvre le scénario inverse, celui où la base est injoignable et où quelqu'un doit comprendre ce qui s'est passé en se tenant devant l'appareil.
$lesson$),
  ('ard-c6-p9', 'ard-c6', 9, $lesson$Superviser : tableau de bord et alertes$lesson$, $lesson$
Le tableau de bord est la promesse faite à l'utilisateur final : une page qui répond, en moins de quelques secondes, aux questions « ça marche », « qu'est-ce que ça mesure » et « est-ce que ça a changé ». Un bon tableau de bord commence par l'état, pas par les courbes. En haut, la station, sa dernière mesure datée, son état de liaison, le nombre de publications depuis le dernier redémarrage et le nombre d'erreurs. Puis viennent les valeurs instantanées avec tendance, puis l'historique glissant, puis les alertes récentes. Cette hiérarchie n'est pas esthétique : elle suit l'ordre dans lequel un opérateur pose réellement ses questions lorsqu'il ouvre la page parce que quelque chose lui semble bizarre.

Trois courbes suffisent largement à la version un : la température sur vingt-quatre heures, l'humidité sur la même fenêtre, et la pression sur sept jours, car la pression est la seule des trois grandeurs qui apporte une information intéressante sur une durée longue. Ajoutez un graphique des compteurs internes, publications et erreurs, qui est la courbe la plus révélatrice de toutes : une mesure stable avec un compteur d'erreurs qui grimpe décrit un système en train de défaillir bien avant que la température n'affiche quoi que ce soit d'anormal. Les tableaux de bord les plus utiles sont rarement les plus fournis ; ils sont ceux dont chaque panneau répond à une question qu'on se pose vraiment.

| Panneau | Question à laquelle il répond | Source |
| --- | --- | --- |
| État de la station | La station répond-elle et depuis quand ? | Testament MQTT et dernier message d'état |
| Dernières valeurs | Que mesure-t-on à cet instant ? | Champ mesures du dernier échantillon |
| Tendance 24 heures | Comment évoluent les grandeurs ? | Série temporelle agrégée par minute |
| Publications et erreurs | Le flux est-il complet ? | Compteurs embarqués publiés avec l'échantillon |
| Alertes récentes | Un seuil a-t-il été franchi ? | Messages du topic d'alerte |

Les alertes se distinguent des affichages. Un affichage montre une valeur ; une alerte déclenche une action quand une condition est réunie, et elle doit être encadrée par trois réglages : le seuil, la durée pendant laquelle la condition doit rester vraie, et la destination. La durée, souvent oubliée, évite les alertes fantômes : un pic d'une seconde au moment d'ouvrir la fenêtre ne doit pas envoyer un message. La destination, enfin, doit être en double pour tout ce qui compte : un canal instantané pour le traitement rapide et un canal différé, comme un récapitulatif quotidien, pour ne rien laisser passer. Une alerte qui ne peut être ni acquittée ni historisée finit par être ignorée, et une alerte ignorée est pire que pas d'alerte du tout.

```json
{
  "station": "station-a3f2c1",
  "regle": "hr_haute",
  "mesure": "hr_pct",
  "valeur": 91.4,
  "seuil": 90.0,
  "persistance_s": 120,
  "canal": "alerte-meteo",
  "ts": 1770000360
}
```

Ce message d'alerte reprend l'identifiant de station et l'horodatage du flux normal, ce qui permet de le remettre en série avec les mesures et de savoir exactement à quel instant la condition est devenue vraie. Les trois champs essentiels sont la valeur mesurée, le seuil et la durée de persistance : ensemble, ils suffisent à comprendre l'événement sans rouvrir le firmware, et à répondre à la question que se pose toujours l'opérateur, à savoir si l'alerte décrit une situation nouvelle ou une situation déjà connue. Le nom de règle, enfin, identifie la règle plutôt que la destination, car une même règle peut être routée vers plusieurs canaux sans jamais changer de signification.

La boucle de rétroaction complète le tableau : depuis la page, l'opérateur doit pouvoir au moins relire un seuil ou forcer une publication sans reflasher. C'est là que le topic de commande entre en jeu, avec la même exigence de sécurité pragmatique que le reste : la station n'accepte que des commandes dont la structure est valide, ignore poliment le reste, journalise ce qu'elle applique, et ne change jamais rien qui ne soit pas réversible. Pour une station domestique, un mot de passe partagé sur le broker et une liste blanche de champs modifiables suffisent ; l'important est d'avoir décidé la règle plutôt que d'avoir laissé la porte grande ouverte par défaut. La supervision n'est alors plus une vitrine, mais un vrai outil de conduite du système.
$lesson$),
  ('ard-c6-p10', 'ard-c6', 10, $lesson$Tenir : watchdog, reconnexion et mise à jour à distance$lesson$, $lesson$
La phase de démonstration prouve que le système peut marcher ; la phase de maintien prouve qu'il continuera. Entre les deux, il y a les pannes réelles : le point d'accès redémarré pendant une mise à jour du routeur, le broker redémarré, la carte mémoire saturée, la boucle bloquée par une lecture réseau qui n'est jamais revenue, l'utilisateur qui a coupé l'alimentation au milieu d'une écriture. Un projet connecté se juge à sa manière de se relever, pas à sa manière de démarrer. Quatre mécanismes couvrent l'essentiel : le watchdog, la reconnexion progressive, le journal d'incidents et la mise à jour à distance. Aucun n'est exotique, tous sont intégrés au chapitre précédent ; leur mise en œuvre simultanée est le travail du présent.

Le watchdog matériel est une minuterie interne au processeur que le logiciel doit réarmer régulièrement. Si la boucle cesse de le réarmer, c'est qu'elle est bloquée ou morte : le compteur expire, le processeur est réinitialisé, et la station redémarre sans intervention. C'est la défense ultime contre les blocages réseau, les lectures de bus qui ne répondent plus et les débordements de pile. Deux précautions rendent ce mécanisme réellement utile. D'abord, le temps de déclenchement doit être nettement supérieur à la pire durée légitime de la boucle, sinon le watchdog redémarrera la carte pendant une simple écriture de journal un peu lente. Ensuite, l'événement doit laisser une trace : un compteur de redémarrages conservé en mémoire non volatile, affiché et publié, afin de distinguer un redémarrage planifié d'une chute en boucle. Un système qui redémarre parfois sans le dire est un système qu'on ne peut pas diagnostiquer.

La reconnexion combine Wi-Fi puis MQTT, avec le même principe de délai progressif appliqué aux deux étages. Le premier essai part après quelques secondes, puis le délai double à chaque échec jusqu'à un plafond, avec une composante aléatoire qui évite qu'un réseau ne soit subitement noyé par toutes les stations se reconnectant à la même fraction de seconde. Ce comportement est d'autant plus nécessaire que l'échec de connexion est souvent la cause de la surchauffe : une attente active qui tourne en boucle serrée consomme du courant, empêche la pile réseau de respirer et retarde mécaniquement le retour du service une fois la coupure terminée.

```cpp
// Retard exponentiel plafonne, identique pour WiFi et MQTT.
// Chaque etape attend plutot qu'elle ne tourne en boucle.

static uint32_t delaiMs = DELAI_INITIAL_MS;

bool tenterConnexion() {
  if (liaisonEtablie()) { delaiMs = DELAI_INITIAL_MS; return true; }

  if (millis() - dernierEssai < delaiMs) return false;

  dernierEssai = millis();
  bool ok = etablirLiaison();                 // WiFi puis MQTT

  if (!ok) {
    delaiMs = min(delaiMs * 2, DELAI_PLAFOND_MS);
    delaiMs += random(0, DELAI_JITTER_MS);    // evite l'effet de meute
    journalIncident("liaison absente, nouvel essai dans " + String(delaiMs));
  }
  return ok;
}
```

Deux détails de cette fonction méritent d'être soulignés parce qu'ils distinguent une implémentation naïve d'une implémentation éprouvée. Le plafond empêche la croissance infinie du délai, qui finirait par retarder indéfiniment le retour au service. La variation aléatoire, elle, répond à un problème de parc : quand un coupure de courant rend toutes les stations du site en même temps, des délais identiques provoquent une vague de connexions simultanées que le routeur et le broker absorbent mal. Le journalisation de chaque incident, enfin, transforme un comportement invisible en donnée exploitable lors du diagnostic suivant.

Le journal d'incidents complète le journal de mesures. Il ne contient pas des valeurs mais des événements : démarrage, identifiant et version du firmware, adresse IP obtenue, nombre de redémarrages depuis l'alimentation, perte de liaison, retour de liaison, erreur de carte mémoire, lecture de capteur échouée, commande appliquée. Ce fichier est le premier endroit où regarder quand quelqu'un annonce que la station fait n'importe quoi, et il est d'autant plus précieux qu'il subsiste quand le réseau est absent. La discipline à acquérir est de journaliser les transitions d'état, pas les boucles : mille messages identiques à la minute noient l'information dans le bruit, alors qu'un message par changement d'état se lit en trente secondes.

La mise à jour à distance ferme la boucle de maintien. Plutôt que de déplacer la station et de la rebrancher en USB pour chaque correction, on téléverse le nouveau firmware par le réseau. Deux stratégies coexistent : le téléversement direct, simple mais qui laisse la station indisponible pendant l'écriture et la rend inutilisable si l'interruption survient, et le téléversement vers une partition d'attente avec basculement, où l'ancien firmware reste intact jusqu'à ce que le nouveau prouve qu'il démarre. Pour un projet qui doit tenir, la seconde approche est la bonne : elle transforme une mise à jour risquée en opération réversible. Quel que soit le choix, deux règles s'imposent : la mise à jour ne se déclenche jamais pendant une écriture de journal, et le succès de la nouvelle version se vérifie par un critère objectif, par exemple la publication de plusieurs échantillons consécutifs, avant de considérer l'opération terminée.

```text
Procedure de mise a jour a distance - deroule type

1. Preparation
   - Recuperer le binaire et sa somme de controle depuis le serveur
   - Verifier l'espace libre en memoire et sur la partition cible
   - Forcer un dernier echantillon et une derniere ligne de journal

2. Televersement
   - Transfert vers la partition d'attente, avec progression publiee
   - Si interruption : l'ancien firmware reste actif, rien n'est perdu

3. Bascule et vigilance
   - Redemarrage sur la nouvelle version
   - Le nouveau firmware doit publier N echantillons valides en 120 s
   - Sinon : retour automatique sur la partition precedente

4. Constat
   - Version, duree de l'operation et resultat inscrits au journal
   - Le tableau de bord affiche la nouvelle version
```

Le dernier point du maintien est humain : la documentation d'exploitation. Un fichier court, daté, indiquant comment alimenter la station, comment la remettre à niveau, comment lire le journal, quels codes d'erreur signifient quoi et quelle est la marche à suivre pour une carte mémoire pleine. Ce document coûte une heure et en fait gagner une demi-journée à la première personne qui devra intervenir sur une station déjà installée, y compris vous. Dans tout projet connecté, la mémoire de l'auteur est le premier composant qui tombe en panne.
$lesson$),
  ('ard-c6-p11', 'ard-c6', 11, $lesson$Vérifier : tests, recette et mise en production$lesson$, $lesson$
La recette est l'acte qui sépare un prototype d'un système livré. Elle consiste à confronter, point par point, le comportement réel au cahier des charges rédigé au début, et à consigner les résultats dans un rapport court. Ce n'est pas une formalité administrative : c'est le moment où l'on découvre que la reconnexion met quarante-cinq secondes au lieu de trente, que le journal perd une ligne par changement de jour, ou que l'erreur de température atteint un degré près du capteur. Chacune de ces découvertes vaut mieux ici qu'au bout du premier mois de fonctionnement. Le travail se décompose en tests unitaires, tests d'intégration et tests de tenue, dans cet ordre, car chacun prépare le suivant.

Les tests unitaires portent sur ce qui peut être vérifié sans matériel : le filtrage, la validation de domaine, le calcul du retard progressif, le formatage du message, la rotation des fichiers. On les écrit avec un cadre de test léger intégré à l'outil de compilation du projet, on les exécute sur la machine de développement, et on les rend automatiques : à chaque modification du dépôt, une tâche de vérification compile et les lance. Le bénéfice dépasse largement le coût initial : ces tests détectent en secondes des régressions que la lecture attentive du code ne verrait pas, et ils documentent par la même occasion le comportement attendu de chaque fonction.

```cpp
// Exemple : le validateur de domaine doit rejeter l'impossible.
// Exécution sur la machine de développement, sans aucun capteur.

void test_rejet_temperature_impossible(void) {
  Echantillon e = { .t = -80.0, .hr = 48.0, .p = 1013.0 };
  TEST_ASSERT_FALSE(validerDomaine(e));
}

void test_rejet_saut_brutal(void) {
  Echantillon precedent = { .t = 21.0 };
  Echantillon courant   = { .t = 45.0 };
  TEST_ASSERT_FALSE(limiteVariation(precedent, courant, 5.0));
}

void test_publication_format_stable(void) {
  Echantillon e = echantillonDeTest();
  const char* json = formaterMessage(e);
  TEST_ASSERT_TRUE(contientCle(json, "\"station\""));
  TEST_ASSERT_TRUE(contientCle(json, "\"t_c\""));
  TEST_ASSERT_TRUE(contientCle(json, "\"seq\""));
}
```

Les tests d'intégration réunissent plusieurs modules sur le vrai matériel : le capteur réellement branché, la carte mémoire réellement insérée, un broker réellement accessible. On y vérifie les interactions, c'est-à-dire exactement ce que les tests unitaires ne couvrent pas : la cohabitation du port série et du Wi-Fi, le comportement du journal pendant une coupure, la réception d'une commande pendant qu'une publication est en cours. Un test d'intégration réussi répond à une question unique et écrite à l'avance ; un scénario qui en pose quinze à la fois ne dit rien de précis quand il échoue.

Le test de tenue, ou test de durée, est celui qui fait la différence entre un banc qui a marché un après-midi et un système déployé. Il laisse la station tourner pendant plusieurs jours consécutifs, avec des coupures de réseau provoquées à intervalles irréguliers, une carte mémoire presque pleine, et un relevé quotidien des compteurs. On y cherche deux choses : l'absence de redémarrage non désiré et la stabilité du taux de publications. Un test de tenue réussi ne prouve pas que le système ne tombera jamais en panne, mais il élimine les causes de panne les plus fréquentes, qui sont toujours d'ordre temporel : fuites de mémoire, compteurs qui débordent, fichiers qui grossissent, attentes qui s'accumulent.

| Étape de recette | Méthode | Preuve à conserver |
| --- | --- | --- |
| Précision des mesures | Comparaison côte à côte avec un étalon | Courbe d'écart sur la plage utile |
| Continuité du flux | Compteur de séquences côté stockeur | Taux de complétude sur 72 heures |
| Tenue de la reconnexion | Coupures provoquées toutes les heures | Durée médiane de retour en service |
| Stabilité | Journal des redémarrages sur 7 jours | Zéro redémarrage non planifié |
| Espace de stockage | Rotation et rétention vérifiées | Taille du journal stable en fin de période |
| Lisibilité opérateur | Relecture du tableau de bord | Chaque panneau répond à sa question |

La mise en service elle-même suit une check-list courte : alimenter et vérifier la tension sous charge, relever l'adresse obtenue, confirmer les premiers messages sur le broker, vérifier la première écriture de journal, forcer une coupure de réseau et mesurer le retour, déclencher une alerte artificiellement pour valider la chaîne d'notification, puis enfin laisser la station et revenir vingt-quatre heures plus tard comparer les compteurs. Ce dernier passage, le retour différé, est souvent omis et c'est lui qui révèle les problèmes de cadence et de fuite. Une fois la recette signée, la station entre en service avec deux documents à portée de main : le rapport de recette et la note d'exploitation. Toute la rigueur des sections précédentes trouve là sa justification.
$lesson$),
  ('ard-c6-p12', 'ard-c6', 12, $lesson$Exemple pas à pas : assembler le chemin complet$lesson$, $lesson$
Il reste à relier toutes les pièces dans un ordre de démarrage cohérent, car la séquence d'initialisation compte autant que le code lui-même. Le principe est d'aller du plus fiable au plus fragile : d'abord ce qui fonctionne sans rien d'autre, ensuite ce qui dépend du réseau. On initialise le port série et on affiche la version, puis on lit la configuration, puis on monte le stockage local, puis on démarre le capteur et on effectue une première lecture de contrôle, et seulement ensuite on tente la connexion réseau. Si le réseau est absent, la station reste utile localement ; si le capteur est absent, le défaut est annoncé immédiatement ; si la carte mémoire manque, le système continue en publiant sans journal. Chaque dépendance manquante dégrade une fonction, jamais l'ensemble.

```cpp
void setup() {
  Serial.begin(115200);
  afficherBanner();                 // version, identifiant, compteur de demarrages

  configCharger();                  // pins, seuils, cadence depuis la configuration
  journalDemarrer();                // carte SD : degrade proprement si absente
  capteurDemarrer();                // premiere lecture de controle
  veilleDemarrer(30000);            // watchdog a 30 s, superieur au pire cas

  ecranAfficherEtat("mise en route");
  liaisonDemarrer();                // WiFi puis MQTT, avec retard progressif

  journalIncident("demarrage OK, version " VERSION);
}

void loop() {
  veilleAlimenter();
  if (!cadenceAtteinte(millis())) return;

  liaisonMaintenir();               // reconnexion si necessaire, sans bloquer
  Echantillon e = lireCapteur();
  traiterEtPublier(e);
}
```

Le chemin d'un échantillon, de la broche du capteur au pixel affiché, se résume ainsi : la boucle détecte l'arrivée de la fenêtre de cadence, interroge le capteur, valide le domaine, limite la variation, lisse, horodate, puis fait trois choses en ordre de priorité décroissante. Le journal local d'abord, car il est réversible et rapide. L'affichage ensuite, car il sert l'observateur sur place. La publication en dernier, car c'est l'opération la plus lente et la plus susceptible d'échouer sans remettre en cause l'intégrité de la mesure. Ce classement des priorités n'est pas arbitraire : il place l'écriture la plus fiable la première, de sorte qu'une coupure de réseau au milieu du traitement laisse toujours une trace locale.

```text
Sequence de demarrage - ordre et degradations acceptees

  port serie        --> toujours disponible
        |
  configuration     --> valeurs par defaut si absente
        |
  stockage local    --> sans journal si carte absente
        |
  capteur           --> etat d'erreur publie si reponse fausse
        |
  afficheur local   --> derniere valeur connue si geler
        |
  reseau + broker   --> mode autonomie si inaccessible
        |
  veille (watchdog) --> redemarrage si la boucle se fige

Regle : une etape qui echoue degrade une fonction, jamais le systeme.
```

La dernière pièce d'assemblage est le tableau de bord lui-même, que l'on branche sur la base une fois les premiers messages reçus. Commencez par un unique panneau montrant la dernière valeur et l'état de la station : il vous servira de test de bout en bout dès la première minute. Ajoutez ensuite, un par un, les panneaux d'historique, puis les compteurs, puis les alertes, en vérifiant à chaque ajout qu'il répond à une question précise. Un tableau de bord se construit dans l'ordre des questions, pas dans l'ordre des disponibilités du logiciel de supervision. Quand chaque panneau a sa justification écrite, la supervision est terminée : il ne reste qu'à la regarder fonctionner.
$lesson$),
  ('ard-c6-p13', 'ard-c6', 13, $lesson$À retenir$lesson$, $lesson$
Un projet connecté se juge à sa capacité à tenir dans la durée sans intervention, pas à la brillance de sa démonstration. Le cahier des charges précède le code, et chaque exigence s'exprime avec un chiffre, une unité et une durée : c'est ce qui rend la recette possible et les désaccords rares. Le matériel se décide à partir de ce document, avec une alimentation dimensionnée pour les pointes du module radio, des bus plutôt que des fils multiples, et un schéma tenu à jour. Le logiciel se découpe en modules à responsabilité unique, reliés par une seule structure d'échantillon, de sorte que la valeur affichée, écrite et publiée ne peut pas diverger. La mesure passe par la validation de domaine et la limitation de variation avant tout filtrage, et un échec de lecture se publie comme un échec plutôt que d'être masqué par une valeur plausible.

Les topics MQTT suivent une arborescence stable qui permet de s'abonner à une station, à une catégorie ou à l'ensemble, et le format du message est un contrat versionné, avec unités dans les noms de champs et compteur de séquence pour détecter les trous. Le stockage temporel exige une étiquetage sobre et une rétention configurée, tandis que le journal local reste le secours qui fonctionne quand le réseau est absent. La supervision commence par l'état du système, pas par les courbes, et distingue l'absence de donnée de la donnée nulle. Le watchdog, le retard progressif de reconnexion, le journal d'incidents et la mise à jour réversible forment l'armature de maintien ; les tests unitaires automatiques, les tests d'intégration, le test de durée et le rapport de recette forment la preuve que tout cela fonctionne.
$lesson$),
  ('ard-c6-p14', 'ard-c6', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
La première erreur consiste à écrire du code avant d'avoir écrit les critères d'acceptation : le projet avance vite deux semaines, puis se perd dans des discussions sans fin sur ce qui est prioritaire, faute de référence commune. La seconde est de négliger l'alimentation, ce qui se traduit par des redémarrages en pleine publication que l'on met des jours à relier aux pointes de courant du module radio. La troisième est d'afficher ou de publier une valeur sans validation de domaine, ce qui empoisonne les séries avec des lectures impossibles qui faussent les moyennes pendant des heures. La quatrième est d'attendre de manière bloquante dans la boucle, ce qui fige l'affichage, empêche l'entretien de la liaison et déclenche le watchdog.

On voit ensuite des topics écrits sans structure, qui deviennent ingérables dès qu'une seconde station rejoint le site, et des formats de message modifiés sans version, cassant silencieusement le stockeur. La base de données sans rétention finit par saturer le disque et emporte avec elle les mesures que l'on croyait sauves. Le tableau de bord affiche des courbes mais jamais l'état de la liaison, de sorte qu'un système mort ressemble à un système stable. Enfin, les mises à jour à distance sont lancées pendant une écriture de journal ou sans mécanisme de retour arrière, et un simple coup de réseau transforme une correction en brique. La liste est courte : chacune de ces fautes se corrige en une heure si elle est identifiée tôt, et en une journée si elle ne l'est pas.
$lesson$),
  ('ard-c6-p15', 'ard-c6', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
Pour consolider, le meilleur exercice reste d'étendre le périmètre existant plutôt que de recommencer un nouveau projet : ajoutez un quatrième capteur sur le même bus, ce qui vous forcera à réviser la structure d'échantillon et le schéma de câblage ; ajoutez une deuxième station, ce qui validera l'arborescence des topics et l'étiquetage de la base ; ajoutez une alerte avec durée de persistance, ce qui vous fera toucher du doigt la différence entre seuil instantané et condition maintenue. Chaque extension est une vérification d'architecture : si elle demande de toucher à dix fichiers, le découpage est mauvais.

Les documents officiels restent les meilleures sources pour aller au fond : le guide du protocole MQTT explique les qualités de service et les testaments avec une précision qu'aucun tutoriel ne remplace, la documentation du fournisseur de votre base temporelle détaille l'étiquetage et les politiques de rétention, et la fiche technique de votre carte de développement contient les broches à éviter et le schématique d'alimentation. Côté méthode, lisez sur le cycle en V, sur les tests embarqués automatisés et sur les pratiques d'intégration continue : ce sont les mêmes principes que ceux appliqués ici, formulés de manière réutilisable pour tout projet. Enfin, la meilleure progression à ce stade est le dépôt versionné : apprenez à documenter, à taguer une version, à écrire un journal de modification, car c'est ce qui vous permettra, dans un an, de reprendre ce projet sans douleur.
$lesson$),
  ('ard-c6-p16', 'ard-c6', 16, $lesson$Et maintenant : votre premier déploiement$lesson$, $lesson$
Vous avez maintenant un projet complet : capteurs lus, décisions prises, sorties pilotées et interface accessible. Avant de le laisser tourner seul, parcourez la checklist du déploiement : alimentation protégée, broches non utilisées définies, valeurs par défaut si un capteur répond mal, et retries sur les lectures instables. L'exercice pratique vous demande de livrer ce travail sous forme de dépôt documenté : un README avec le schéma de câblage, le fichier de configuration et une section dédiée au dépannage. Un projet qu'un autre peut relancer sans vous vaut mieux qu'un projet qui ne tourne que sur votre bureau.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('cyb-c1-p1', 'cyb-c1', 1, $lesson$Le paysage des menaces : qui attaque et pourquoi$lesson$, $lesson$
Bienvenue dans le premier chapitre du parcours Cybersécurité fondamentaux. Si vous n'avez jamais approché la sécurité informatique, vous êtes exactement au bon endroit : ce cours ne suppose aucune connaissance technique préalable, seulement la curiosité de comprendre comment les systèmes sont attaqués et, surtout, comment on les défend. La cybersécurité n'est pas réservée aux experts en capuche : c'est une discipline rigoureuse, faite de principes simples appliqués avec constance, et tout professionnel, développeur, administrateur, responsable de projet ou simple usager, doit en maîtriser les bases pour ne pas devenir la faille par laquelle tout s'effondre. Ce chapitre pose les fondations du parcours : il vous apprendra à reconnaître qui attaque, pourquoi il attaque et par quelles voies il entre, pour que les chapitres suivants, identités et accès, réseau défensif, durcissement, détection, trouvent enfin leur sens dans une stratégie cohérente.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées sur un cas réel. Vous identifierez les principales familles de malwares et leurs effets respectifs, vous distinguerez les étapes d'une cyberattaque selon la chaîne de mise à mort, vous différencierez le phishing de l'ingénierie sociale au sens large, vous saurez lire la surface d'attaque d'un petit réseau et expliquer pourquoi la sécurité n'est pas un produit qu'on achète mais un processus qu'on entretient. Le tout sera assemblé dans un mini-projet guidé : l'analyse de risque d'un petit parc informatique associatif, que vous pourrez réécrire seul juste après la leçon, sans autre aide que vos notes.

Le fil rouge du chapitre sera le parc informatique de la Médiathèque des Lilas : une dizaine de postes publics en libre accès, un réseau Wi-Fi ouvert aux usagers, un petit serveur d'association qui héberge la gestion des adhérents, et un site web qui publie le programme des ateliers. Ce décor est volontairement banal, parce qu'il concentre tous les cas d'usage de ce parcours : des utilisateurs non techniques, des données personnelles, un service exposé sur internet, et un budget serré. Nous reprendrons ce décor chapitre après chapitre, afin que vous voyiez comment une même menace se traduit en gestes différents selon le lieu, le public et les moyens disponibles. Une recommandation avant de commencer : la cybersécurité s'apprend comme on apprend les premiers secours, en manipulant. Recopiez les exemples, testez les outils mentionnés sur une machine que vous pouvez vous permettre de casser, simulez une attaque chez vous avant de raisonner pour votre lieu de travail. Les notions sont accessibles, et elles ne deviennent utiles qu'une fois mises en pratique.

Un mot enfin sur la manière de lire ce chapitre. Chaque section suit la même progression : d'abord le phénomène vu du côté de l'attaquant, pour comprendre ce qui motive la manœuvre et quel levier elle presse ; ensuite les signes concrets, ceux que vous pourrez rechercher dans un journal, dans un courriel ou dans une configuration ; enfin les parades, exprimées en gestes vérifiables plutôt qu'en promesses. Des listes de résumé ferment chaque section, et vous verrez revenir les mêmes mots tout au long du parcours : actif, menace, vulnérabilité, impact, surface, journal, révision. Prenez-les dès maintenant comme un vocabulaire de métier : la sécurité progresse quand une équipe partage les mêmes mots pour décrire les mêmes situations.



La première erreur consiste à croire que personne ne s'intéresse à mon petit serveur. C'est une intuition humaine parfaitement compréhensible, et c'est aussi une erreur coûteuse : les attaquants ne choisissent pas leurs cibles une par une. Ils scannent l'internet entier, automatisent l'exploitation des failles connues, et monétisent tout ce qui a de la valeur, données personnelles, identifiants, puissance de calcul, bande passante, réputation de domaine. Un serveur oublié devient un relais de spam, un nœud de minage, une rampe de rebond pour attaquer une cible plus prestigieuse, ou une entrée dans une base revendue sur un forum. La taille de la structure ne protège donc pas : seul compte le niveau de soin apporté à la posture de défense, et ce niveau est une décision, pas une fatalité.

L'automation explique cette indifférence aux frontières. Un outil d'exploration part chaque nuit vers des millions d'adresses, repère les services qui répondent, compare les bannières aux bases de vulnérabilités connues, tente l'exploitation quand le motif correspond, puis range le résultat. L'opérateur humain n'intervient qu'une fois l'accès acquis, et souvent seulement pour revendre ce qu'un robot a trouvé. Pour vous, la conséquence est double : vous pouvez être visé sans le savoir, et vous pouvez être attaqué un dimanche soir par un processus qui ne vous connaît pas. D'où l'intérêt de raisonner en surface et en probabilité plutôt qu'en histoire individuelle : moins une machine est visible, moins elle entre dans le périmètre de ces balayages ; mieux elle est protégée, moins l'exploitation automatique aboutit.

Les acteurs se répartissent en quelques grandes familles, et comprendre leurs motivations aide à prioriser les défenses, parce qu'une motivation produit des méthodes et des rythmes prévisibles. Le cybercriminel cherche un gain financier direct : rançongiciel, vol de coordonnées bancaires, revente d'accès, chantage après exposition. Il raisonne en rendement et en délai de retour sur investissement, ce qui le rend pressé et opportuniste. L'activiste, ou hacktiviste, vise la visibilité : défiguration de site, fuite d'informations embarrassantes, perturbation de service ; il cherche un symbole plus que de l'argent. L'espion, étatique ou industriel, cherche la persistance : rester invisible le plus longtemps possible pour prélever de l'information stratégique, quitte à ne rien détruire. Le script kiddie, enfin, utilise des outils tout faits sans en comprendre le fonctionnement, pour le défi ou la nuisance ; son bilan est souvent disproportionné par rapport à son niveau.

```table
| Acteur | Motivation principale | Méthodes typiques | Cible privilégiée |
| --- | --- | --- | --- |
| Cybercriminel | Gain financier | Rançongiciel, phishing, vol d'identifiants, minage | Toute organisation non protégée |
| Hacktiviste | Visibilité, revendication | Défiguration, déni de service, fuite de données | Entités symboliques, médias |
| Espion (APT) | Information stratégique | Exploits rares, déplacement latéral, persistance | Gouvernements, industries critiques |
| Script kiddie | Défi, nuisance | Outils publics, scanners, exploits connus | Cibles faciles, mal configurées |
| Interne malveillant | Vengeance, profit | Abus de privilèges, exfiltration lente | Son propre employeur |
```

La frontière entre ces familles est poreuse, et c'est une leçon en soi. Un outil conçu pour l'espionnage finit dans la nature et sert au crime organisé ; un script kiddie déclenche une fuite majeure par accident ; un interne en colère utilise les droits qu'on lui avait confiés pour le travail. Les compétences circulent, les logiciels se copient, et les carrières changent de camp. Pour le défenseur, cela signifie qu'aucun profil ne peut être écarté d'avance : on ne protège pas contre un acteur précis, on protège contre les méthodes que ces acteurs emploient toutes, à des degrés divers.

Une deuxième lecture du paysage porte sur les cibles, et elle est plus utile encore que la liste des acteurs. Les données personnelles, les identifiants, les informations financières et les secrets professionnels ont une valeur marchande immédiate ; les comptes d'administration ont une valeur de levier, car ils ouvrent plusieurs portes à la fois ; les équipements ont une valeur d'usage, bande passante, calcul, stockage ; les noms de domaine ont une valeur de réputation, et leur détournement se paie cher. Classez vos ressources selon ces quatre valeurs, et vous saurez déjà où concentrer l'effort. Une base d'adhérents vaut plus que la page d'accueil ; un compte d'administration vaut plus qu'un compte de lecture ; une adresse de courrier professionnelle vaut plus qu'un poste public.

Le ciblage peut aussi se faire au hasard ou sur indication. Une campagne de masse envoie le même courriel à des centaines de milliers d'adresses et attend que quelques-unes mordent ; elle ne vous connaît pas, et son succès dépend uniquement de votre réflexe au moment du clic. À l'inverse, une attaque sur indication part d'une annonce, d'un concours, d'une situation de vulnérabilité humaine repérée en ligne, et s'adresse à une personne nommément. Entre les deux, l'approche opportuniste : l'attaquant découvre votre existence parce qu'un service mal configuré est apparu dans un index public, et décide alors de creuser. Dans les trois cas, la parade est la même en première ligne : réduire ce qui se voit, contrôler ce qui reste, journaliser ce qui se passe.

Il faut enfin mentionner la chaîne d'approvisionnement, devenue une voie privilégiée parce qu'elle exploite la confiance déjà établie. Au lieu d'attaquer la cible, on attaque son fournisseur, son agence, son prestataire de maintenance, son hébergeur de messagerie, et l'on gagne l'accès par la relation de confiance contractuelle. Un logiciel tiers compromis, un accès prestataire oublié après la mission, une mise à jour signée par une clé volée : autant de portes qui ne ressemblent pas à des portes. La question à vous poser est simple : qui, en dehors de mon équipe, dispose d'un chemin vers mes systèmes, et quand cette permission a-t-elle été revue pour la dernière fois ?

- Un attaquant ne cible pas personnellement : il automatise, puis il monétise tout accès.
- Quatre profils d'acteurs, quatre motivations : gain, visibilité, persistance, défi.
- La frontière entre ces profils est poreuse : les outils et les compétences circulent.
- Classez vos ressources par valeur : données, leviers, usage, réputation.
- Une campagne de masse ne vous connaît pas ; une attaque sur indication, si.
- La chaîne d'approvisionnement attaque la confiance, pas le pare-feu.
- La taille ne protège pas : l'automatisation rend toute cible rentable.
$lesson$),
  ('cyb-c1-p2', 'cyb-c1', 2, $lesson$La chaîne de mise à mort : sept phases d'une attaque$lesson$, $lesson$
Une attaque ne tombe pas du ciel : elle suit une séquence que les défenseurs appellent la chaîne de mise à mort, ou kill chain, popularisée par Lockheed Martin. L'intérêt de ce modèle n'est pas de classer les malveillants, c'est de montrer qu'une attaque est une succession d'opérations, chacune laissant des traces et pouvant être interrompue. L'idée maîtresse tient en une phrase : arrêtez l'attaque à n'importe quel maillon, et la chaîne entière casse. Un attaquant doit réussir toute la suite ; un défenseur peut gagner sept fois de suite. C'est ce déséquilibre qui rend l'exercice raisonnable, même avec peu de moyens.

La première phase est la reconnaissance : l'attaquant collecte des informations publiques, noms de domaine, adresses IP, employés visibles sur les réseaux professionnels, technologies utilisées, fuites passées, organigrammes, photos de badges. Une partie de ce travail est passive : elle ne touche jamais votre système, donc n'apparaît dans aucun de vos journaux. L'autre partie est active : requêtes envoyées, tentatives de connexion, sondages de services. C'est là que votre détection devient possible. La deuxième phase est l'armement : il prépare une charge adaptée au butin, un document piégé, un script d'exploitation, un installeur de rançongiciel, et il l'adapte à l'environnement qu'il a observé, version du logiciel, langue, horaires.

Vient la livraison, qui envoie la charge vers la cible : courriel de phishing, message instantané, site web compromis, publicité malveillante, clé USB abandonnée dans le hall, mise à jour falsifiée. Rien de spectaculaire, souvent un seul octet mal placé suffit. La phase d'exploitation déclenche ensuite la faille : exécution de code non voulu, contournement d'authentification, élévation de privilèges. C'est le moment le plus fragile pour l'attaquant, car une erreur se voit et une protection qui bloque fait échouer la manœuvre. La phase d'installation pose alors un moyen de persistance : porte dérobée, tâche planifiée, compte fantôme, clé de démarrage modifiée, sans quoi l'accès serait perdu au redémarrage suivant.

Les deux dernières phases transforment l'accès en valeur. Le commandement et contrôle établit un canal stable vers l'attaquant : requêtes vers un domaine algorithmique, détournement de service DNS, connexion HTTPS vers un serveur de commande, parfois simple messagerie chiffrée. Ce canal se reconnaît souvent à sa régularité : des appels réguliers, vers la même destination, indépendamment du travail réel de l'utilisateur. L'action sur l'objectif réalise enfin le but : chiffrement des données, exfiltration, sabotage, espionnage prolongé, détournement de ressources. Chaque phase a son rythme, ses artefacts et ses journaux, et c'est sur ces trois caractéristiques que se construira votre capacité de détection dans les chapitres à venir.

```text
 Schéma des sept phases - vue défensive, valeurs illustratives

  1 RECONNAISSANCE   2 ARMEMENT    3 LIVRAISON      4 EXPLOITATION
  | informations     | charge       | courriel,       | faille
  | publiques +      | adaptée      | site, support   | déclenchée
  | sondages         |              |                 |
  +------------------+--------------+-----------------+------------+
                                                              |
  7 ACTION          6 COMMANDE      5 INSTALLATION  <---------+
  | chiffrement,    | canal stable  | persistance
  | exfiltration,   | vers          | porte dérobée,
  | sabotage        | l'attaquant   | tâche, compte
  |
  Points de coupe possibles : filtrage, mise à jour, sensibilisation,
  contrôle d'exécution, journalisation, alerte sur anomalie de sortie.
```

Le schéma montre le point que les débutants oublient : la chaîne n'est pas une fatalité linéaire, c'est une suite d'obstacles. Le filtrage bloque la livraison, la mise à jour bloque l'exploitation, le contrôle des comptes bloque l'installation, l'alerte sur un flux sortant inhabituel bloque la phase finale. Un défenseur qui ne sait pas où il en est perd ce luxe : il ne peut pas dire s'il a vu une attaque s'arrêter à la phase trois ou ne jamais commencer. D'où l'importance des journaux, déjà, dès le premier chapitre, parce qu'une absence de trace n'est jamais une preuve d'absence d'attaque.

Le modèle a une limite qu'il faut connaître pour ne pas l'utiliser à l'envers : il décrit bien les attaques par infrastructure, moins bien les attaques qui commencent par un identifiant volé et ne passent par aucune faille logicielle. Complétez-le par une lecture par technique, celle que propose la base MITRE ATT&CK, consultable sur https://attack.mitre.org : au lieu d'une ligne droite en sept temps, vous obtenez un catalogue de comportements observables, correspondant aux mots-clés de vos outils de surveillance. Les deux lectures se complètent : la chaîne donne le récit et le sens, le catalogue donne la granularité et la testabilité. Pour votre analyse de risque, la première sert à expliquer à une direction ; la seconde sert à configurer une alerte.

Voici, à titre d'exemple, ce que donne une exploration légère menée depuis votre propre poste, sur votre propre réseau, avec autorisation. Elle illustre la phase de reconnaissance active et, surtout, la quantité d'informations qu'un inconnu peut obtenir sans jamais se connecter à l'un de vos comptes.

```text
# EXEMPLE ILLUSTRATIF - sortie d'outils de reconnaissance sur un réseau autorisé.
# Réseau de la médiathèque, plage 192.168.30.0/24, exécuté depuis le poste
# d'administration avec l'accord écrit du responsable du parc.

Nom du site : mediatheque-exemple.fr
Adresse IP  : 203.0.113.42          (plage de documentation)
Serveur de noms : ns1.hote-exemple.fr, ns2.hote-exemple.fr
Émetteur    : hébergeur commercial, contact masqué par un service de privacy
Certificat  : valide, émis par une autorité automatique, expire dans 61 jours
Technologies relevées : serveur web, moteur de catalogue, version affichée

Postes internes sondés (uniquement les adresses ouvertes par la politique)
192.168.30.10   443/tcp  ouvert   serveur de catalogue
192.168.30.15   80/tcp   ouvert   imprimante, interface d'administration
192.168.30.25   3306/tcp filtré   base de données, aucune réponse
```

Trois informations ressortent de ce relevé, et chacune mérite une ligne dans votre registre des risques : la version affichée par un service permet de chercher la faille correspondante ; l'interface d'administration d'une imprimante accessible depuis le réseau public élargit inutilement la surface ; la base de données correctement filtrée montre qu'une bonne pratique existe déjà et qu'il faut la conserver. Lire ainsi une sortie, c'est passer de l'outil au raisonnement : ce n'est pas la commande qui compte, c'est la décision qu'elle autorise.

- La kill chain compte sept phases : reconnaissance, armement, livraison, exploitation, installation, commandement, action.
- Chaque phase laisse des traces et peut être interrompue : un défenseur a sept occasions de gagner.
- Une partie de la reconnaissance est passive : elle n'apparaît dans aucun de vos journaux.
- La persistance est souvent plus préoccupante que l'intrusion initiale : elle survit au redémarrage.
- Un canal de commande se reconnaît à sa régularité, indépendante du travail réel.
- La chaîne raconte le récit ; le catalogue de techniques rend l'alerte testable.
- Une sortie d'outil ne vaut que par la décision qu'elle déclenche.
$lesson$),
  ('cyb-c1-p3', 'cyb-c1', 3, $lesson$Les vecteurs d'entrée : surface d'attaque et reconnaissance$lesson$, $lesson$
La surface d'attaque désigne l'ensemble des points qu'un attaquant peut tester sans avoir franchi le moindre obstacle : chaque port ouvert, chaque service exposé, chaque compte actif, chaque interface d'administration, chaque chaîne logicielle héritée d'un fournisseur. La notion est plus utile que celle de faille, parce qu'elle ne dépend d'aucune découverte nouvelle : elle existe dès maintenant, elle se cartographie aujourd'hui, et la réduire n'attend ni un budget ni une équipe. Une surface réduite ne rend pas invincible, elle rend l'attaque plus lente, plus bruyante et plus coûteuse, ce qui est exactement ce que cherche un défenseur sous-équipé.

La surface se lit comme une liste. Les ports et services exposés constituent la première couche : un service qui n'écoute nulle part est invisible, celui qui écoute sur une interface publique est joignable par des millions d'adresses. Les comptes forment la deuxième couche : comptes par défaut, comptes nominatifs partagés, comptes d'administration utilisés pour le travail quotidien, mots de passe réutilisés entre services. La troisième couche est logicielle : versions connues, composants tiers non suivis, certificats proches de l'expiration, mots de passe d'usine jamais changés sur un équipement. La quatrième est humaine et organisationnelle : droits hérités d'un ancien poste, prestataires dont l'accès n'a pas été révoqué, procédures écrites nulle part.

Cette surface se révèle de plusieurs manières, et toutes sont accessibles sans outil exotique. Les annuaires de noms de domaine publient les enregistrements de contact, parfois masqués, parfois non. Les transparences des certificats publient les noms pour lesquels un certificat a été délivré. Les moteurs d'indexation recueillent les pages oubliées derrière un formulaire. Les annuaires de services notent les versions affichées. Les fuites de mots de passe révèlent des identifiants encore actifs. Aucune de ces sources ne touche votre système : c'est pour cela qu'aucune d'entre elles n'apparaît dans vos journaux, et c'est pour cela qu'il faut les parcourir vous-même, périodiquement, pour voir ce qui se voit de l'extérieur.

```text
# EXEMPLE ILLUSTRATIF - ce que montre une exploration passive, sans connexion.
# Commandes prises dans la documentation officielle de chaque outil, valeurs
# fictives, à exécuter uniquement sur des domaines dont vous êtes responsable.

$ dig +short mediatheque-exemple.fr
203.0.113.42

$ dig +short TXT mediatheque-exemple.fr
"v=spf1 include:_spf.hote-exemple.fr -all"

$ whois mediatheque-exemple.fr
Registrar : hébergeur commercial
Creation Date : 2019-04-11
Registrant Contact : masqué (service de protection des données)

$ openssl s_client -connect mediatheque-exemple.fr:443 -servername mediatheque-exemple.fr
Protocol : TLSv1.2
Verify return code: 0 (ok)
subject = CN = mediatheque-exemple.fr
notAfter = Dec 11 23:59:59 2026 GMT
```

La lecture de ce relevé est simple et utile. L'enregistrement de politique d'envoi indique que le domaine se protège déjà contre l'usurpation de courrier, ce qui retire une porte d'entrée. La date de création ancienne et le contact masqué réduisent le renseignement disponible. La version du protocole de chiffrement mérite d'être portée à la plus récente. La date d'expiration du certificat, elle, se note au calendrier : un certificat qui tombe à l'arrêt affiche un avertissement à tous les usagers un lundi matin, et personne dans l'équipe ne doit être responsable d'un incident aussi visible et aussi évitable.

Réduire la surface se joue ensuite en gestes ordonnés, jamais en achat. Commencez par l'inventaire, y compris des objets que l'on oublie : imprimantes, bornes, caméras, lecteurs de badges, objets connectés apportés par un service. Fermez ce qui n'est pas utile, désactivez les comptes inactifs, remplacez les mots de passe d'usine, mettez à jour ce qui expose une version connue, limitez les interfaces de gestion aux seuls réseaux d'administration, et vérifiez qu'un service interne n'est pas publié par erreur sur l'interface exposée. Chaque élément retiré est un élément que l'attaquant doit reconquérir ailleurs, et un élément que votre journal devra gérer en moins.

- La surface d'attaque est ce qui se teste sans obstacle : ports, comptes, versions, droits hébergés.
- Une exploration passive ne laisse aucune trace chez vous : elle se pratique aussi de votre côté.
- Un inventaire honnête précède toute réduction : on ne ferme pas ce qu'on ne connaît pas.
- Les comptes oubliés et les prestataires non révoqués font partie de la surface.
- Datez les certificats, les renouvellements et les versions : chacun a une échéance.
- Réduire la surface ne coûte presque rien et ralentit l'attaque automatisée.
$lesson$),
  ('cyb-c1-p4', 'cyb-c1', 4, $lesson$Phishing et ingénierie sociale : l'humain comme faille$lesson$, $lesson$
L'ingénierie sociale n'est pas une technique informatique : c'est l'art de manipuler la confiance, l'urgence, la peur ou la curiosité pour obtenir un secret ou déclencher une action. Elle ne cherche pas la faille du logiciel, elle cherche le raccourci dans le comportement : la fatigue de fin de journée, le désir de rendre service, la peur d'une sanction, l'habitude de valider sans lire. Le phishing, ou hameçonnage, en est la forme industrialisée : un courriel, un SMS, un message instantané ou un appel qui imite un expéditeur légitime et pousse à cliquer, à saisir un identifiant, à ouvrir une pièce jointe ou à valider un virement.

Les variantes se distinguent par la visée et le canal, et il est utile de les nommer parce que chacune appelle une parade particulière. Le spear phishing cible une personne ou une organisation précise : le message cite un dossier réel, un nom de collègue, une facture attendue, une procédure interne. Le whaling vise les dirigeants et les responsables financiers : enjeux plus forts, préparation plus soignée, souvent une fausse signature de dirigeant en copie. Le BEC, ou fraude au président, se contente d'un courriel bref et crédible demandant un virement urgent, sans pièce jointe ni lien, ce qui le rend invisible aux filtres classiques. Le smishing utilise le SMS, le vishing la voix, le quishing un code QR imprimé sur un faux avis de stationnement. Tous reposent sur le même levier : court-circuiter la réflexion critique par l'émotion.

```text
EXEMPLE FICTIF : courriel de spear phishing ciblant la Médiathèque des Lilas
De : direction@lilas-biblio.fr          (adresse proche, non possessionnée)
À : accueil@mediatheque-exemple.fr
Objet : URGENT - Vérification des accès avant l'audit de vendredi
Corps : Bonjour, dans le cadre de l'audit annuel, nous devons valider les
accès au serveur de gestion. Merci de cliquer ici et de saisir vos identifiants
dans l'heure, l'audit ne peut pas être reporté : http://lilas-biblio-audit.fr/valider
Pièce jointe : liste_adherents_a_verifier.pdf   (en réalité un exécutable)
Signature : service informatique - réponse impérative avant 18 h
```

Analysez ce message ligne à ligne, car les signaux sont constants et se répètent d'une campagne à l'autre. L'adresse d'expéditeur n'est pas celle qu'elle prétend être : le domaine réel se lit après le dernier signe arobase, et un domaine proche mais différent suffit à tromper l'œil distrait. L'objet impose une urgence avec échéance, ce qui réduit le temps de réflexion. Le lien pointe vers un domaine créé pour l'occasion, sans rapport avec l'adresse officielle du service. La pièce jointe porte une extension trompeuse. La signature réclame une réponse impérative et fait référence à une autorité. Aucun de ces signaux n'est techniquement nouveau ; leur force vient de leur accumulation et de l'état dans lequel le lecteur se trouve.

Les leviers psychologiques sont remarquablement stables, ce qui permet de les enseigner en quelques minutes. L'autorité : un message qui vient d'en haut, d'un auditeur, d'un fournisseur, d'un service officiel. L'urgence : une échéance courte interdit la vérification. La peur : une sanction, une coupure, un contrôle, une fermeture de compte. La curiosité : une pièce jointe nommée comme un document attendu, une fuite annoncée. La sympathie : un collègue qui demande de l'aide, un dirigeant pressé, un nouveau qui ne connaît pas encore les procédures. Le filet de sécurité consiste à sortir du canal : on ne rappelle pas le numéro laissé dans le message, on compose le numéro de l'annuaire interne ; on ne clique pas le lien, on saisit l'adresse connue à la main.

```text
# EXEMPLE ILLUSTRATIF - réflexe de vérification en quatre gestes.
# Aucun de ces gestes ne demande d'outillage particulier.

1. Afficher l'adresse réelle de l'expéditeur, pas le nom affiché.
2. Survoler le lien sans cliquer et lire l'adresse complète affichée en bas
   de fenêtre ; comparer caractère par caractère au domaine officiel.
3. Ouvrir une nouvelle fenêtre et saisir soi-même l'adresse du service
   supposé ; y connecter comme d'habitude pour voir si la demande existe.
4. Signaler le message au service informatique sans le transférer en
   boucle, puis le supprimer après conservation éventuelle par l'équipe.
```

La défense technique complète le réflexe sans jamais le remplacer. Les filtres antispam repèrent les domaines fraîchement créés, les pièces jointes aux extensions suspectes et les patterns connus. L'authentification du domaine, avec les mécanismes SPF, DKIM et DMARC, déclare quels serveurs ont le droit d'envoyer en votre nom et instruit le destinataire sur la conduite à tenir en cas d'échec : refuser, mettre en attente ou accepter avec annotation. L'authentification multifacteur reste la mesure la plus rentable de toutes, parce qu'elle rend un identifiant volé insuffisant : le phishing peut réussir à voler le mot de passe, il ne peut pas voler le second facteur posé sur le téléphone de l'agent.

Reste la dimension humaine, qu'il ne faut jamais présenter comme un défaut des personnes. La formation n'élimine pas le risque : un expert fatigué clique, un agent sous pression saisit. Ce que la formation change, c'est le taux de réussite de l'attaque et surtout le délai de signalement, qui est le vrai indicateur à suivre. Un utilisateur qui signale en deux minutes un message douteux vaut mieux qu'un filtre parfait : il vous donne l'heure de début, la cible et la campagne en cours, ce qui permet d'avertir les collègues avant la vague suivante. Mesurez ce délai, publiez-le, améliorez-le : la sensibilisation devient alors une mesure de sécurité pilotable et non un exercice annuel à cocher.

- L'ingénierie sociale manipule l'autorité, l'urgence, la peur, la curiosité et la sympathie.
- Phishing de masse, spear phishing, whaling, BEC : même logique, visée et préparation différentes.
- Les canaux se diversifient : courriel, SMS, voix, QR code, message instantané.
- Sortez du canal pour vérifier : numéro composé soi-même, adresse saisie à la main.
- SPF, DKIM et DMARC déclarent qui a le droit d'envoyer en votre nom.
- La double authentification transforme un identifiant volé en tentative inutile.
- L'indicateur à suivre n'est pas le nombre de clics, c'est le délai de signalement.
$lesson$),
  ('cyb-c1-p5', 'cyb-c1', 5, $lesson$Les principales familles de malwares$lesson$, $lesson$
Le terme malware, contraction de logiciel malveillant, recouvre des réalités très différentes qu'il est important de distinguer, car la famille conditionne la parade. Le virus, au sens strict, s'insère dans un fichier hôte et ne se propage que lorsque ce fichier est exécuté : il a besoin d'une action humaine pour voyager. Le ver, lui, se propage seul à travers le réseau en exploitant une faille ou une partage mal protégé : aucun clic n'est nécessaire, une machine vulnérable suffit. Le cheval de Troie se déguise en logiciel légitime : l'utilisateur l'installe volontairement, croyant obtenir une fonction utile, et le code malveillant s'exécute en arrière-plan.

Le rançongiciel, ou ransomware, chiffre les données et réclame une rançon pour la clé. Les variantes contemporaines ont ajouté la menace de publication : on vole d'abord les documents, puis on chiffre, ce qui double la pression puisque même une sauvegarde correcte n'empêche pas la fuite. Certains opérateurs combinent désormais le chantage à la publication, la vente aux enchères et le chiffrement, sans même ménager l'attaquant pressé. Le spyware espionne en silence : frappe clavier, captures d'écran, microphone, localisation, harvesting de sessions. L'adware injecte de la publicité, souvent comme composant indésirable d'un installateur gratuit. Le rootkit s'enfonce dans le noyau ou le firmware pour masquer sa présence et celle des autres logiciels. Le botnet transforme la machine en zombie au service d'une armée contrôlée à distance : déni de service, spam, minage, relais.

```table
| Famille | Mode de propagation | Objectif principal | Parade prioritaire |
| --- | --- | --- | --- |
| Virus | Fichier hôte et action humaine | Infection, destruction | Contrôle d'exécution, sauvegarde |
| Ver | Réseau, faille distante | Propagation massive | Mise à jour, segmentation |
| Cheval de Troie | Installation volontaire | Accès distant, vol | Sensibilisation, contrôle des sources |
| Rançongiciel | Ver, cheval de Troie, phishing | Chiffrage puis extorsion | Sauvegarde testée, MFA administrateur |
| Spyware | Cheval de Troie, exploit | Surveillance, vol de données | Mises à jour, privilèges minimaux |
| Rootkit | Exploitation du noyau ou du firmware | Persistance, dissimulation | Réinstallation propre, chaîne de démarrage contrôlée |
| Botnet | Ver, cheval de Troie | Armée de zombies | Blocage des sorties, détection d'anomalies |
| Wiper | Accès légitime obtenu | Destruction, diversion | Sauvegarde hors ligne, séparation des réseaux |
```

La distinction n'est pas académique : elle dicte l'ordre de vos investissements. Un ver se coupe par la mise à jour rapide et la segmentation ; un cheval de Troie se coupe par la sensibilisation et le contrôle d'exécution ; un rançongiciel se coupe par les sauvegardes testées, l'authentification multifacteur sur les comptes d'administration et la séparation des sauvegardes du réseau qu'il infecte ; un spyware se coupe par les mises à jour et la réduction des privilèges ; un wiper ne se coupe que par une copie qui n'est pas joignable depuis le réseau attaqué. Connaître la famille, c'est savoir où mettre le premier euro et la première heure.

La question des vecteurs d'entrée revient alors, parce qu'un malware n'a aucun intérêt tant qu'il n'est pas arrivé. Quatre chemins suffisent à couvrir la majorité des cas : le courriel et ses pièces jointes ou ses liens, la navigation sur un site compromis ou une publicité malveillante, le support amovible échangé entre postes, et la faille non corrigée atteinte directement par le réseau. À ces chemins s'ajoute le logiciel gratuit téléchargé depuis une source non officielle, emballé avec un composant indésirable, et la mise à jour falsifiée, plus rare mais dévastatrice. La défense aligne exactement ces mêmes entrées : filtrage du courrier, navigation encadrée, contrôle des supports, mise à jour prioritaire, sources logicielles vérifiées.

La contre-mesure la plus efficace reste souvent la plus terne : reprendre la main sur l'exécution. Un poste qui ne peut lancer que les programmes signés et installés par l'administrateur perd la majorité de ses infections, parce que la charge utile doit alors franchir une décision humaine au lieu d'une simple ouverture de double clic. Combinée à la réduction des privilèges, l'agent d'exécution ne travaillant pas en administrateur, cette mesure casse la majorité des scénarios de propagation horizontale. Elle n'est pas confortable au début : certains logiciels métier refusent de démarrer, et il faut une période d'adaptation avec une liste d'exceptions documentées. Le confort revient vite, et l'inventaire des exceptions devient un atout de connaissance du parc.

- Virus et ver se distinguent par la présence ou l'absence d'une action humaine.
- Le rançongiciel moderne vole avant de chiffrer : la sauvegarde ne suffit plus seule.
- Chaque famille appelle une parade prioritaire : mise à jour, sensibilisation, sauvegarde, segmentation.
- Quatre vecteurs suffisent à expliquer la majorité des infections : courriel, web, support, faille.
- Une exécution restreinte aux programmes autorisés brise la propagation horizontale.
- Réduire les privilèges empêche l'infection de devenir administration.
- Documentez vos exceptions de contrôle d'exécution : elles décrivent votre parc réel.
$lesson$),
  ('cyb-c1-p6', 'cyb-c1', 6, $lesson$Vecteurs techniques : réseau, applications et identités$lesson$, $lesson$
Derrière les grandes familles de menaces se cachent trois terrains d'entrée très concrets, et chaque chapitre suivant du parcours en consacrera un entier : le réseau, les applications, les identités. Comprendre dès maintenant comment une attaque commence sur chacun d'eux vous évitera de croire que la sécurité est une affaire de produit. Le réseau ouvre la voie, l'application cède le passage, l'identité donne la clé ; les trois se rejoignent dans la même chaîne que vous avez étudiée, et les défenses se répondent d'un terrain à l'autre.

Sur le réseau, tout commence par la cartographie. Un attaquant cherche les hôtes vivants, puis les ports qui répondent, puis les services et leurs versions. L'opération est mécanique, rapide et parfaitement légale dès qu'elle vise vos propres machines avec votre accord, ce qui vous permet de la pratiquer chez vous avant de la subir. Les outils de balayage envoient des requêtes et interprètent les réponses ou leur absence : un service qui répond ouvre la discussion, un port qui refuse confirme qu'une machine est joignable, un port qui se tait indique souvent un filtrage. Cette différence d'attitude entre ouvert, fermé et filtré constitue déjà une information de sécurité, et vous l'apprendrez à exploiter dans le chapitre consacré au réseau défensif.

```bash
# EXEMPLE ILLUSTRATIF - cartographie d'un réseau que vous possédez.
# N'exécutez ces commandes que sur vos propres machines ou avec
# l'autorisation écrite du responsable. Les adresses sont fictives.

# Balayage léger : quels hôtes répondent sur la plage donnée ?
nmap -sn 192.168.30.0/24

# Balayage de ports courants avec détection de version, puis résultats bruts.
nmap -sV --top-ports 100 192.168.30.10 -oN catalogue-reseau.txt

# Balayage discret, utile pour vérifier l'effet réel d'un filtrage :
# les paquets SYN sont envoyés, la réponse est interprétée comme un état.
nmap -sS -p 22,80,443,3306 192.168.30.15
```

La sortie de ces commandes ne vous dit pas seulement quels ports sont ouverts : elle vous donne le logiciel, parfois sa version exacte, relevée dans la bannière du service. Une version datée devient immédiatement une hypothèse de travail à confronter aux bulletins de sécurité publiés par l'éditeur. C'est précisément cette chaîne de raisonnement, port ouvert, service identifié, version connue, correctif disponible ou non, qu'il faut retenir : l'outil fournit un relevé, la décision appartient à la comparaison avec l'état réel de vos mises à jour.

L'écoute de paquets constitue le second outil de terrain, et elle sert un objectif différent : non plus découvrir ce qui est exposé, mais observer ce qui circule. Sur un réseau où vous êtes administrateur, une capture de paquets vous montre les destinations contactées, la fréquence des échanges, les protocoles employés et les requêtes non chiffrées. Elle révèle rapidement un poste qui parle à une adresse inconnue à intervalle régulier, un service qui émet du clair ce qui devrait être chiffré, ou un protocole de partage de fichiers qui déborde du périmètre prévu.

```bash
# EXEMPLE ILLUSTRATIF - observation du trafic sur votre propre machine.
# Sous Windows, les équivalents se trouvent dans les outils de capture
# du système ; sous Linux et macOS, la commande ci-dessous est courante.

# Capturer sur l'interface filaire, filtrer sur le trafic entrant du port web.
sudo tcpdump -i eth0 -nn 'tcp port 80' -c 40

# Afficher les échanges avec un seul hôte, en résolvant les noms si possible.
sudo tcpdump -i eth0 -nn host 192.168.30.10 -w captures/exercice.pcap

# Relire une capture enregistrée, sans réexécuter le trafic en direct.
tcpdump -r captures/exercice.pcap -nn | head -30
```

Lire une capture, c'est poser trois questions au flux : d'où vient l'échange, vers où part-il, et à quelle fréquence. Un poste de la médiathèque qui interroge un serveur inconnu toutes les cinq minutes ne fait pas du travail courant : il communique, et l'anomalie se décrit en une phrase à soumettre à l'équipe. À l'inverse, un échange épars vers un service légitime, accompagné d'une résolution de nom attendue, relève normalement du fonctionnement courant. Notez que l'écoute sur un réseau ouvert sans chiffrement vous montre aussi le contenu : c'est une raison de plus pour exiger le chiffrement partout où le trafic quitte un réseau maîtrisé.

Le terrain applicatif obéit à une logique différente : il ne s'agit plus d'ouvrir un port, mais de fournir une entrée à un formulaire, un paramètre d'adresse, un fichier téléversé, une donnée de session. Les familles de failles qui en résultent sont stables depuis des années : injection de requêtes lorsque la saisie n'est pas distinguée de l'instruction, exécution de code lorsque le serveur interprète une requête malveillante, scripts injectés lorsque la page reflète un contenu non assaini, défaut de contrôle d'accès lorsqu'un identifiant suffit à atteindre la ressource d'autrui, protection insuffisante des formulaires et des sessions. La liste de référence reste celle de l'OWASP, consultable sur https://owasp.org, et la défense tient en un principe : distinguer les données des instructions, vérifier chaque entrée côté serveur, et appliquer la même autorisation à chaque requête.

Le terrain des identités, enfin, est celui où la chaîne se termine le plus souvent. Une application correctement écrite avec un compte partagé revient à verrouiller la porte puis à glisser la clé sous le tapis. Les vecteurs sont connus : mots de passe faibles ou réutilisés, identifiants extraits d'une fuite et rejoués sur d'autres services, comptes d'administration utilisés au quotidien, droits hérités quand un poste change de titulaire, absence de second facteur sur les comptes qui ouvrent vraiment quelque chose. Vous verrez au chapitre suivant que la défense tient à quatre gestes : secret unique par service rangé dans un gestionnaire, second facteur sur les comptes à risque, moindre privilège accordé au besoin réel, et révocation immédiate au départ.

- La cartographie réseau se pratique chez soi avant d'être subie : port ouvert, port fermé, port filtré.
- Une bannière de service livre une version, et une version appelle un correctif.
- L'écoute de paquets répond à une autre question : que se passe-t-il réellement en continu.
- Un flux régulier vers une destination inconnue se décrit en une phrase : c'est une alerte.
- Côté application, distinguez toujours les données des instructions, à chaque entrée.
- Un identifiant n'est pas un droit : chaque requête doit revérifier l'autorisation.
- Le terrain des identités referme la chaîne : c'est là que se joue l'impact final.
$lesson$),
  ('cyb-c1-p7', 'cyb-c1', 7, $lesson$Mesurer le risque : probabilité, impact et priorités$lesson$, $lesson$
Dire qu'un risque existe ne suffit pas à décider quoi en faire, et c'est précisément l'objet de l'analyse de risque : transformer une inquiétude en rang. Le modèle le plus courant multiplie trois éléments : l'actif concerné et sa valeur, la menace qui pèse sur lui, et la vulnérabilité qui permet à cette menace d'aboutir. Le résultat n'est pas un nombre magique mais un ordre de grandeur, suffisant pour arbitrer entre deux chantiers lorsque le budget n'en permet qu'un seul. Sans cette étape, la décision se prend au bruit le plus fort, c'est-à-dire au dernier incident entendu au café.

La probabilité combine trois facteurs qu'il faut peser séparément. L'exposition : le service est-il joignable depuis internet, accessible depuis un réseau ouvert, manipulé par un public non maîtrisé ? L'opportunisme de la méthode : une faille publiée, un outil automatique et une campagne de masse font monter la probabilité, tandis qu'une attaque sur indication, qui exige une motivation et une compétence, la baisse. La fréquence observée : combien de fois le phénomène s'est-il produit chez vous, chez un confrère, dans votre secteur au cours des douze derniers mois ? Un phénomène fréquent, peu coûteux à tenter et désastreux s'il aboutit mérite toujours plus d'attention qu'un risque spectaculaire mais rarissime.

L'impact se mesure sur l'activité, pas sur la technologie. Interrompre trois jours la prise de prêts n'a pas le même poids selon qu'il s'agit d'une activité accessoire ou du seul service ouvert au public. La perte de données personnelles engage une responsabilité, une notification et une relation de confiance avec les adhérents ; une fuite de documents internes touche l'image et parfois des obligations contractuelles ; une machine rendue inutilisable pendant une semaine coûte du temps de remise en état que personne n'a budgété. Posez toujours la question concrète : que se passe-t-il le lendemain matin, qui est empêché de travailler, que doit-on dire à qui.

```table
| Critère | Faible | Moyen | Élevé |
| --- | --- | --- | --- |
| Exposition | Réseau interne seul | Réseau invités ouverts | Service public sur internet |
| Opportunisme | Compétence rare exigée | Outil public disponible | Détection automatique, faille publiée |
| Fréquence observée | Jamais vu chez vous | Vu chez des confrères | Vu chez vous plusieurs fois |
| Impact activité | Gêne ponctuelle, récupérable | Activité dégradée un jour | Activité interrompue, obligation légale |
| Données concernées | Publiques déjà | Internes, sensibles | Personnelles, confidentielles |
| Priorité résultante | Surveiller | Traiter à échéance | Traiter sans délai, avec responsable |
```

Cette grille ne produit pas une vérité scientifique : elle produit une décision explicite et discutable, ce qui est tout ce qu'on demande à une analyse de risque. Si deux personnes arrivées indépendamment à la même ligne obtiennent la même priorité, l'analyse est robuste ; si elles divergent, la divergence révèle un désaccord sur la valeur d'un actif ou la réalité d'une menace, et ce désaccord doit être tranché par écrit plutôt que laissé flotter. C'est ainsi que l'exercice devient outil de management et non simple formalité technique.

Le résultat se range ensuite en trois ou quatre catégories de traitement, et la clarté du vocabulaire compte ici autant que la justesse des notes. Traiter sans délai signifie que le chantier démarre, avec un responsable et une échéance. Traiter à échéance signifie qu'il est planifié et financé, pas simplement souhaité. Accepter signifie qu'un décideur a pesé le risque et décidé de vivre avec, ce qui n'est envisageable que si l'impact est borné et si la décision est consignée. Transférer signifie qu'une assurance, un hébergeur ou un prestataire assume une partie de la charge, ce qui déplace le risque sans le supprimer. Une catégorie sans responsable ni date n'est pas une catégorie : c'est un vœu.

Le coût des mesures se compare enfin au coût du risque, sans prétendre à une précision comptable. Une sauvegarde testée chaque trimestre coûte quelques heures ; un chiffrement de données peut coûter une migration ; une sensibilisation régulière coûte du temps de formation, mais moins qu'un jour d'activité perdu. La comparaison devient particulièrement claire quand une mesure règle plusieurs risques à la fois : la double authentification neutralise la réutilisation de mots de passe, le phishing ciblé et l'accès distant compromis ; l'inventaire sert à l'analyse, au filtrage, à la mise à jour et à l'audit. Priorisez donc les mesures à effet large, elles font gagner deux fois.

- Le risque se décrit par l'actif, la menace et la vulnérabilité, jamais par l'intuition seule.
- Pesez séparément l'exposition, l'opportunisme et la fréquence observée.
- Mesurez l'impact sur l'activité et les personnes, pas sur la sophistication de l'outil.
- Une priorité sans responsable et sans échéance reste un vœu.
- Accepter un risque est une décision de direction, écrite et datée, pas un silence.
- Une mesure à effet large règle plusieurs risques : commencez par là.
$lesson$),
  ('cyb-c1-p8', 'cyb-c1', 8, $lesson$Prévention, détection, réponse : la sécurité comme processus$lesson$, $lesson$
Aucun pare-feu, aucun antivirus, aucune solution annoncée comme tout-en-un ne garantit la sécurité d'un système. La sécurité est un cycle continu, décrit sous des formes proches par la norme ISO 27001 et par le cadre du NIST, consultable sur https://www.nist.gov : identifier, protéger, détecter, répondre, améliorer. Ce cycle s'applique à une médiathèque comme à une banque, à l'échelle près, et son mérite est d'interdire l'illusion de l'état acquis. Un système sécurisé hier ne l'est pas aujourd'hui : le logiciel a vieilli, les personnes ont changé, les menaces ont évolué, les habitudes se sont relâchées.

La prévention réduit la surface et casse les chaînes les plus courantes : mises à jour appliquées dans des délais annoncés, configuration minimale, moindre privilège, séparation des réseaux, chiffrement des échanges sensibles, sauvegardes séparées du système d'origine, sensibilisation répétée, contrôle des accès au compte. Son efficacité est réelle mais partielle, et l'erreur classique consiste à y consacrer la totalité de l'effort, puis à constater l'intrusion des semaines plus tard faute d'avoir regardé. Une mesure de prévention qui n'est jamais vérifiée n'existe que sur le papier : il faut donc prévoir, pour chaque mesure, la manière dont on saura qu'elle fonctionne encore.

La détection assume que la prévention échouera, et cette phrase n'est pas un aveu d'échec : c'est le fondement d'une démarche adulte. Elle repose sur la collecte des journaux, leur centralisation, et des alertes calibrées sur des événements qui signifient quelque chose. Un journal que personne ne lit ne protège personne ; une alerte qui se déclenche cent fois par jour finit par ne plus être regardée. Le réglage est un travail continu : on part d'une alerte large, on l'observe une semaine, on la resserre, on documente ce qu'elle doit montrer, puis on la confie à quelqu'un avec un numéro d'ordre de traitement.

```text
# EXEMPLE ILLUSTRATIF - journal d'alerte mis en forme pour la leçon.
# Trois lignes d'un même jour sur le poste de la médiathèque.

07:12:44 host=poste-public-03 msg="tentative de connexion sortante refusee"
        dest=198.51.100.77 port=4444 regle=BLOCAGE-SORTIE src=10.0.30.14
07:12:49 host=poste-public-03 msg="tentative de connexion sortante refusee"
        dest=198.51.100.77 port=4444 regle=BLOCAGE-SORTIE src=10.0.30.14
07:13:31 host=poste-public-03 msg="processus lance hors liste autorisee"
        exe=C:\Users\Public\update.exe pid=4417 regle=CONTROLE-EXECUTION
```

Trois lignes suffisent pour raconter un incident naissant : une connexion vers une destination connue pour être un serveur de commande, répétée, bloquée par une règle ; puis un exécutable issu d'un répertoire public tentant de démarrer hors de la liste autorisée. La lecture appropriée n'est pas technique mais opérationnelle : le poste est-il isolé, qui en a l'usage, quel usager l'a manipulé à quelle heure, quels autres postes ont présenté le même motif ce matin. C'est cette série de questions qui transforme une ligne de journal en action de réponse.

La réponse se déroule dans un ordre qui s'apprend avant l'incident, jamais pendant. Confiner d'abord : isoler la machine concernée sans la rallumer inutilement, couvrir le vecteur identifié, protéger les sauvegardes. Constater ensuite : horodatage, périmètre, machines touchées, comptes utilisés, preuves conservées. Alerter les personnes qui doivent décider, avec un message court qui dit ce qui est su, ce qui est supposé et ce qui est demandé. Restaurer enfin sur une base saine, puis surveiller activement les jours suivants, parce qu'une première intrusion ratée revient souvent avec une autre méthode. La communication extérieure suit une préparation : qui parle, quand, avec quel texte, pour ne pas aggraver la situation par un silence ou une promesse intempestive.

L'amélioration referme le cycle et lui donne son sens. Après chaque événement, même mineur, même tentative bloquée, une relecture en trois questions : qu'est-ce qui a permis à l'attaque d'avancer, qu'est-ce qui l'a arrêtée, que faut-il changer pour que la prochaine fois elle s'arrête plus tôt. Les mêmes questions s'appliquent aux exercices de crise et aux tests d'intrusion, qui valent par les correctifs qu'ils déclenchent et non par le rapport produit. Une équipe qui écrit ses leçons devient plus rapide à chaque incident, et c'est cette courbe, plus que n'importe quel outil, qui fait la différence entre deux structures disposant du même budget.

Le pilotage du cycle se matérialise en quelques rendez-vous réguliers, faciles à tenir même dans une petite structure. Un point mensuel sur les mises à jour en retard et les comptes créés ou partis. Un point trimestriel sur les sauvegardes et leur restauration réelle. Une revue semestrielle de l'analyse de risque, avec mise à jour des priorités et du registre des décisions. Une veille continue, filtrée sur votre secteur et vos équipements, qui alimente la revue plutôt que l'inquiétude. Ce rythme crée la mémoire de l'organisation, et cette mémoire vaut mieux qu'un outil coûteux dont personne n'aurait le temps de lire les alertes.

- La sécurité est un cycle : identifier, protéger, détecter, répondre, améliorer.
- Chaque mesure de prévention doit être accompagnée du moyen de vérifier qu'elle tient.
- Une alerte qui sonne cent fois par jour cesse d'être une alerte.
- Trois lignes de journal peuvent suffire à raconter un incident : encore faut-il les lire.
- La réponse commence par confiner, constater, alerter, puis restaurer et surveiller.
- La relecture après événement écrit la leçon ; la leçon réduit le temps de la prochaine réponse.
- Des rendez-vous réguliers valent mieux qu'un outil puissant jamais regardé.
$lesson$),
  ('cyb-c1-p9', 'cyb-c1', 9, $lesson$Mini-projet guidé : l'analyse de risque du parc associatif$lesson$, $lesson$
Vous disposez maintenant des concepts pour produire, seul, une analyse de risque d'une page. Le livrable est volontairement court : un document que lira une direction, un bureau ou un conseil d'administration, et que vous pourrez défendre ligne par ligne. Sa structure est imposée, son contenu est le vôtre. Nous allons le construire ensemble, rubrique par rubrique, sur le parc de la Médiathèque des Lilas, puis vous le réécrirez pour votre propre structure, même modeste, surtout modeste : c'est là que l'exercice est le plus utile.

Première rubrique : les actifs critiques. Listez les actifs qui, s'ils étaient perdus ou compromis, arrêteraient l'activité ou engageraient la responsabilité de la structure. Pour chacun, donnez sa nature, données personnelles, service public, équipement, information financière ; sa criticité, haute, moyenne, basse ; et surtout la raison de ce classement, en une phrase que pourra contester un collègue. Sur le parc de la médiathèque, quatre actifs ressortent : le serveur de gestion des adhérents, qui contient des données personnelles et constitue une base unique ; le site web qui publie le programme et reçoit les inscriptions, exposé sur internet ; le réseau invités, réseau non authentifié hébergeant des machines que vous ne contrôlez pas ; et les postes publics, partagés entre des usagers successifs, faiblement criticables individuellement mais vecteur local le plus probable.

Deuxième rubrique : les menaces probables. Pour chaque actif, écrivez deux menaces réalistes, jamais plus, en nommant l'acteur probable et la voie d'attaque. Le vocabulaire que vous venez d'apprendre sert exactement à cela : un cybercriminel qui chiffre les données après un courriel d'hameçonnage, un interne malveillant qui exploite des droits hérités, un hacktiviste qui défigure un site pour la visibilité, un script kiddie qui tente un outil public contre un service mal à jour. Une menace sans acteur et sans voie est une phrase d'apocalypse : elle n'autorise aucune mesure. Au contraire, une menace décrite ainsi se traite : filtrez le courrier, révoquez les droits, corrigez la faille, surveillez la source.

```text
MODÈLE FICTIF : analyse de risque en une page - Médiathèque des Lilas

ACTIFS CRITIQUES
1. Serveur gestion adhérents   Données personnelles   HAUTE   Base unique, obligation de notification
2. Site web inscription        Service public         HAUTE   Exposé sur internet, image de la structure
3. Réseau invités Wi-Fi        Réseau non authentifié MOYENNE Accueil de machines non maîtrisées
4. Postes publics              Équipements partagés   BASSE   Vecteur local le plus probable

MENACES PROBABLES
- Serveur : rançongiciel (cybercriminel, courriel d'hameçonnage vers un agent)
- Serveur : abus de droits (interne malveillant, compte d'administration partagé)
- Site : injection de requêtes (cybercriminel, formulaire d'inscription non durci)
- Site : défiguration (hacktiviste, mot de passe d'administration faible)
- Réseau invités : pivot vers l'interne (attaquant, poste invité non isolé)
- Postes publics : infection par support ou navigation (usager, logiciel non à jour)

MESURES EXISTANTES ET MANQUANTES
- Pare-feu en entrée                     OUI   mais aucune revue depuis 18 mois
- Antivirus sur les postes               OUI   mais signatures seulement, pas de journalisation
- Double authentification sur l'admin    NON   manquant critique, à réaliser en priorité
- Sauvegarde du serveur                  QUOTIDIENNE   restauration jamais testée
- Séparation du réseau invités           NON   même plage d'adresses que le personnel

PLAN D'ACTION, TROIS ACTIONS MAXIMUM
1. Activer la double authentification sur les comptes d'administration
   Responsable : direction technique   Échéance : 7 jours   Indicateur : second facteur actif sur 100 pour cent des comptes
2. Créer et tester le réseau invités isolé, sans accès aux adresses internes
   Responsable : direction technique   Échéance : 14 jours   Indicateur : essai négatif consigné depuis un poste invité
3. Tester une restauration complète du serveur de gestion
   Responsable : agent référent       Échéance : 21 jours  Indicateur : date et durée de la restauration écrites

RÉVISION
Prochaine revue : dans six mois. Déclencheurs anticipés : incident survenu,
changement d'hébergeur, nouveau responsable, CVE critique sur un composant utilisé.
```

Troisième rubrique : les mesures existantes et manquantes. C'est la partie la plus honnête du document, et la plus rentable. Pour chaque menace, notez ce qui est déjà en place, avec sa limite réelle, puis ce qui manque. Le mot limite est important : un pare-feu existe, mais personne ne le relit depuis dix-huit mois ; une sauvegarde tourne, mais personne n'a jamais tenté une restauration ; un antivirus est installé, mais ses journaux ne vont nulle part. Notez les trous sans les arrondir, car une analyse qui embellit la situation produit un plan d'action faux, et c'est au moment du budget que ce défaut se paie.

Quatrième rubrique : le plan d'action, trois mesures maximum, pas plus. Une liste longue est une liste jamais finie. Pour chacune : le responsable nommé, l'échéance en jours, et l'indicateur de fin, ce fait précis qui prouvera que la mesure est réelle plutôt que déclarée. L'indicateur doit être observable par une tierce personne : second facteur actif sur tous les comptes d'administration, essai négatif consigné depuis un poste invité, date et durée de la restauration écrites au registre. Une action sans responsable nommé revient à espérer ; une action sans indicateur revient à ne jamais savoir qu'elle est terminée.

Cinquième rubrique : la révision. Date de la prochaine relecture, six mois est un rythme raisonnable pour une petite structure, et liste courte des événements qui déclenchent une revue anticipée : incident survenu, changement d'hébergeur ou de prestataire, arrivée d'un nouveau responsable, faille critique affectant un composant que vous utilisez, modification importante du périmètre. Cette rubrique est celle que l'on omet toujours, et pourtant c'est elle qui fait vivre le document : sans elle, votre analyse devient une photographie qui se pousse avec les meubles, exactement ce que vous voulez éviter.

```text
GRILLE DE CONTRÔLE - à compléter après la rédaction de votre analyse.
Cochez seulement si le fait est vérifiable par une autre personne.

[ ] Chaque actif a une criticité et une raison écrite en une phrase.
[ ] Chaque menace nomme un acteur et une voie d'attaque précise.
[ ] Chaque mesure existante indique sa limite réelle, pas seulement sa présence.
[ ] Le plan d'action contient trois actions au maximum.
[ ] Chaque action a un responsable nommé, une échéance et un indicateur de fin.
[ ] La date de prochaine revue et ses déclencheurs sont écrits.
[ ] Aucun mot vague ne subsiste : ni si nécessaire, ni selon les besoins,
    ni adaptation possible, ni renforcement à étudier.
[ ] Le document tient sur une page et se lit sans explication orale.
```

Dernier conseil de rédaction, valable pour tout document de ce type. Remplacez chaque adverbe flou par un fait : plutôt que les mises à jour sont assurées, écrivez les correctifs critiques sont appliqués sous sept jours, vérifiés le premier lundi de chaque mois. Relisez ensuite le texte en cherchant ce qu'un collègue pourrait vous demander de prouver, et ajoutez la preuve ou atténuez l'affirmation. Présentez enfin le document à voix haute, en trois minutes : si vous ne pouvez pas le raconter simplement, c'est que certaines rubriques expriment votre inquiétude plutôt que votre connaissance du parc. Cet exercice n'est pas un devoir académique : c'est la page que vous présenterez pour justifier les budgets et les chantiers des mois qui viennent.

- Cinq rubriques suffisent : actifs, menaces, mesures, plan d'action, révision.
- Deux menaces par actif, avec acteur et voie d'attaque : au-delà, la liste s'use.
- Notez les limites des mesures existantes, pas seulement leur présence.
- Trois actions maximum, responsable, échéance, indicateur de fin observable.
- Écrivez la date de prochaine revue et les événements qui l'accélèrent.
- Remplacez chaque adverbe flou par un fait daté et vérifiable.
- Une page honnête vaut mieux qu'un rapport parfait que personne ne lira.
$lesson$),
  ('cyb-c1-p10', 'cyb-c1', 10, $lesson$À retenir$lesson$, $lesson$
- Le paysage des menaces est automatisé : tout système exposé est scanné, testé, puis exploité s'il est vulnérable.
- Quatre profils d'acteurs : cybercriminel pour le gain, hacktiviste pour la visibilité, espion pour la persistance, script kiddie pour le défi.
- Les frontières entre profils sont poreuses : les outils et les compétences circulent d'un camp à l'autre.
- Classez vos ressources par valeur : données personnelles, leviers d'accès, usage quotidien, réputation.
- La chaîne de mise à mort compte sept phases : reconnaissance, armement, livraison, exploitation, installation, commandement et contrôle, action sur l'objectif.
- Chaque phase laisse des traces et peut être interrompue : un défenseur a sept occasions de gagner, l'attaquant doit réussir toute la suite.
- La reconnaissance passive ne laisse aucune trace chez vous : explorez aussi votre propre surface de l'extérieur.
- La surface d'attaque regroupe ports ouverts, comptes actifs, versions connues, droits hérités et accès prestataires oubliés.
- Le phishing manipule l'autorité, l'urgence, la peur, la curiosité et la sympathie ; ses signaux se répètent d'une campagne à l'autre.
- Sortez du canal pour vérifier : numéro composé soi-même, adresse saisie à la main, demande confirmée par un autre moyen.
- SPF, DKIM et DMARC déclarent qui a le droit d'envoyer du courrier en votre nom ; la double authentification rend le vol d'identifiant inutile.
- Malwares : virus et ver se distinguent par l'action humaine, le cheval de Troie par le déguisement, le rançongiciel par le chiffrage suivi du chantage.
- Le rançongiciel moderne vole avant de chiffrer : une sauvegarde joignable depuis le réseau attaqué ne suffit plus.
- Trois terrains d'entrée : le réseau qui ouvre la voie, l'application qui cède le passage, l'identité qui donne la clé.
- Le risque se décrit par l'actif, la menace et la vulnérabilité ; la probabilité mêle exposition, opportunisme et fréquence observée.
- L'impact se mesure sur l'activité et les personnes, jamais sur la sophistication de l'outil.
- Une priorité sans responsable et sans échéance reste un vœu ; accepter un risque est une décision écrite et datée.
- La sécurité est un cycle : identifier, protéger, détecter, répondre, améliorer, jamais un état acquis.
- Une alerte qui sonne cent fois par jour cesse d'être une alerte : le réglage fait partie de la détection.
- La réponse commence par confiner, constater, alerter, puis restaurer sur une base saine et surveiller.
$lesson$),
  ('cyb-c1-p11', 'cyb-c1', 11, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : croire que la taille de la structure protège → Correction : l'automatisation rend toute cible rentable, seule la posture compte.
- Piège : raisonner en acteur précis plutôt qu'en méthode → Correction : décrivez la voie d'attaque, elle est traitable ; le profil ne l'est pas.
- Piège : ignorer la reconnaissance passive, qui ne laisse aucune trace → Correction : parcourez régulièrement votre surface depuis l'extérieur.
- Piège : confondre port ouvert et port filtré dans un relevé → Correction : ouvert répond, fermé refuse, filtré se tait ; relisez l'état avant de conclure.
- Piège : traiter le phishing comme un problème de personnes peu attentives → Correction : combinez filtres, authentification du domaine, double authentification et signalement rapide.
- Piège : collectionner les mesures sans jamais vérifier qu'elles tiennent → Correction : pour chaque mesure, écrivez le test qui prouve son efficacité.
- Piège : sauvegarder sans tester la restauration → Correction : restaurez réellement, notez la date et la durée, corrigez ce qui a échoué.
- Piège : noter une priorité sans responsable ni échéance → Correction : nommez une personne, une date en jours et un indicateur de fin.
- Piège : produire une analyse de risque de dix pages que personne ne lira → Correction : tenez la page, remplacez les adverbes par des faits datés.
- Piège : ranger le document après la rédaction sans fixer de revue → Correction : écrivez la date de prochaine lecture et ses déclencheurs anticipés.
$lesson$),
  ('cyb-c1-p12', 'cyb-c1', 12, $lesson$Pour aller plus loin$lesson$, $lesson$
La référence de départ reste le cadre du NIST, publié sur https://www.nist.gov, qui décrit le cycle identifier, protéger, détecter, répondre et améliorer avec une précision que les résumés n'atteignent pas : lisez d'abord la présentation générale du cadre, puis revenez-y chaque fois que votre analyse de risque doit être justifiée devant une direction. Complétez par la base de techniques de l'MITRE, consultable sur https://attack.mitre.org, qui transforme votre lecture de la chaîne de mise à mort en une liste de comportements observables : cherchez-y les techniques correspondant aux journaux dont vous disposez déjà, et vous saurez exactement ce que vous êtes capable de détecter aujourd'hui.

Du côté des failles d'application, https://owasp.org rassemble les familles de risque, les listes de vérification et les bonnes pratiques de contrôle d'entrée ; le Top 10 y est décrit avec des exemples réels et des moyens de prévention concrets, à lire avant toute relecture d'un formulaire ou d'une interface d'administration. Pour les bulletins de sécurité et l'actualité des vulnérabilités, https://www.cisa.gov publie des consignes de durcissement et des listes de correctifs prioritaires, utiles quand il faut trier dans un flux d'alertes. En français, les publications de l'ANSSI sur https://www.ssi.gouv.fr offrent des guides d'exploitation directement applicables à une petite structure, avec des modèles de politiques et des checklists prêtes à l'emploi.

Une piste enfin, moins technique mais décisive : recopiez votre analyse de risque à la main, réécrivez-la avec vos propres mots, puis présentez-la à un collègue qui vous demandera pourquoi chaque ligne existe. Les questions qu'il vous posera révéleront les zones encore floues de votre compréhension, et cette révélation vaut mieux que n'importe quel quiz : elle vous dit où revenir dans le chapitre.
$lesson$),
  ('cyb-c1-p13', 'cyb-c1', 13, $lesson$Et maintenant : la suite du parcours$lesson$, $lesson$
Vous connaissez désormais le décor et les acteurs : les profils d'attaquants et leurs motivations, les sept phases d'une attaque, les vecteurs d'entrée, les familles de malwares, les mécanismes de l'ingénierie sociale et la manière de mesurer un risque pour en faire une décision. Avant de passer outre, l'exercice pratique qui suit cette leçon vous fera rédiger seul l'analyse de risque du parc associatif, avec vos propres acteurs, vos propres menaces et vos propres trois actions, en vous corrigeant à l'aide des listes de contrôle de chaque section. Le quiz de quatre questions qui accompagne le chapitre vérifie en quelques minutes les notions essentielles : familles de malwares, phases de la chaîne, distinction entre hameçonnage et ingénierie sociale, et lecture d'un risque.

Le chapitre suivant s'attaque au premier maillon de la défense concrète : les identités et les accès. Vous verrez que tout ce que vous venez d'apprendre s'y retrouve à l'identique, changeant seulement d'échelle, puisque voler un mot de passe revient à franchir une phase de la chaîne sans jamais toucher un logiciel. Retenez surtout la méthode : décrire la menace, mesurer le risque, choisir la mesure, vérifier qu'elle tient, programmer la revue. Cette méthode vous suivra du réseau au durcissement, de la détection à la continuité d'activité, et c'est elle, plus qu'aucun outil, qui fera de vous un praticien plutôt qu'un lecteur.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('cyb-c2-p1', 'cyb-c2', 1, $lesson$Ce qu'est (et n'est pas) une authentification$lesson$, $lesson$
Bienvenue dans le deuxième chapitre du parcours Cybersécurité fondamentaux, un chapitre entièrement consacré aux identités et aux accès : mots de passe, phrases de passe, double authentification et répartition des droits. Le chapitre précédent vous a appris à reconnaître les attaquants et leurs vecteurs ; celui-ci s'attaque à la porte d'entrée la plus sollicitée de tous les systèmes que vous utiliserez, des messageries personnelles jusqu'aux serveurs d'une association. Dans la très grande majorité des compromissions signalées chaque année, ce n'est pas une faille géniale qui donne l'accès à un système : c'est un identifiant volé, deviné ou réutilisé, et un mot de passe qui n'a jamais eu beaucoup de résistance. Apprendre à construire des secrets solides, à doubler l'authentification et à répartir les droits n'est donc pas un raffinement pour spécialistes, c'est le socle même de la défense, la partie du métier qui produit le plus d'effet pour le moins d'effort.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées sur un cas réel. Vous appliquerez les règles d'un mot de passe robuste en distinguant ce qui compte vraiment, la longueur et l'imprévisibilité, de ce qui compte moins, les rappels de complexité imposés pendant des années. Vous expliquerez ce qu'est une entropie de mot de passe et vous estimerez en quelques secondes combien de temps il faut pour épuiser un espace de candidats. Vous configurerez une double authentification de bout en bout, en choisissant le bon facteur selon le niveau de risque, en comprenant ce qu'un code à usage unique fait réellement et ce qu'une clé physique protège de mieux. Vous mettrez en pratique le moindre privilège en dessinant la matrice de droits de quatre comptes d'un établissement, et vous saurez répondre en vingt minutes à la découverte d'un compte compromis. Le tout sera assemblé dans un mini-projet guidé : la politique d'identité et d'accès de la Médiathèque des Lilas, un document d'une page que vous pourrez réécrire seul juste après la leçon.

Le fil rouge du chapitre est le parc informatique de la Médiathèque des Lilas : une dizaine de postes publics en libre accès, un réseau Wi-Fi ouvert aux usagers, un petit serveur d'association qui héberge la gestion des adhérents, et un site web qui publie le programme des ateliers. Ce décor est volontairement banal, parce qu'il concentre tous les cas d'usage de ce chapitre : un compte partagé que tout le monde utilise, des employés qui ont besoin d'aller plus loin que les visiteurs, un responsable technique qui détient les droits d'administration, et des services automatiques comme l'impression ou l'envoi de courriels qui se connectent sans être des personnes. Nous reprendrons ce décor section après section. Une recommandation avant de commencer : ce chapitre s'apprend comme on apprend à nager, en entrant dans l'eau. Recopiez les exemples, modifiez-les, testez vos propres phrases de passe dans l'estimateur d'entropie, activez la double authentification sur vos comptes pendant que vous lisez. Les notions y sont simples, et elles ne deviennent utiles qu'une fois appliquées à vos propres identifiants.



L'authentification est l'opération par laquelle un système vérifie que celui qui se présente est bien la personne ou l'entité qu'il prétend être. Il faut distinguer deux étapes que le langage courant confond sans cesse. L'identification consiste à annoncer un nom : vous tapez votre adresse de courrier électronique, vous badgez votre carte, vous donnez le nom de votre association. L'authentification consiste à prouver ce nom : vous donnez le mot de passe lié à cette adresse, vous présentez la carte dont la puce répond à un défi, vous signez un document dont la signature est enregistrée. Un système peut parfaitement recueillir une identification sans jamais l'authentifier, par exemple un formulaire de contact qui affiche « bonjour Madame Martin » parce que vous avez tapé ce nom. L'authentification est donc une preuve, et comme toute preuve, elle repose sur un moyen de vérification que l'imposteur ne peut pas fabriquer.

L'analogie la plus parlante est celle du comptoir d'un hôtel. Vous vous présentez en donnant votre nom, c'est l'identification. Le réceptionniste vous demande une pièce d'identité, vous la fournissez, il compare la photo et le nom : c'est l'authentification. On vous remet ensuite la clé de la chambre que vous avez réservée, c'est l'autorisation. Enfin, l'hôtel note dans son registre l'heure d'arrivée et de départ, c'est la journalisation. Ces quatre opérations forment la chaîne complète que tout système doit pouvoir dérouler, et la sécurité de l'ensemble repose sur la plus faible des quatre mailles : un hôtel qui remet une clé sans regarder la pièce d'identité a une porte d'entrée décorative, de même qu'un système qui journalise parfaitement des accès accordés trop facilement produit de belles traces d'incident inutiles.

Les moyens de preuve se répartissent traditionnellement en trois familles, qu'on appelle facteurs. Le premier facteur est ce que vous savez : un mot de passe, un code PIN, une réponse à une question personnelle, une phrase de passe. Le deuxième est ce que vous avez : un téléphone qui reçoit un code, une carte à puce, une clé physique branchée au port, une imprimante de jet d'encre qui sort un ticket. Le troisième est ce que vous êtes : une empreinte digitale, un visage, une voix, une rétine. L'authentification multifacteur, souvent appelée double authentification quand elle en combine deux, consiste à exiger des preuves appartenant à des familles différentes. La règle est simple à retenir et souvent mal appliquée : cumuler deux secrets, par exemple un mot de passe puis une question secrète dont la réponse est aussi un secret, ne donne pas deux facteurs, cela donne un seul facteur doublé, et les deux preuves tombent ensemble si le secret principal fuit.

```table
| Facteur | Ce que cela représente | Exemples concrets | Forces | Faiblesses |
| --- | --- | --- | --- | --- |
| Savoir | Une information mémorisée | Mot de passe, phrase de passe, code PIN | Gratuit, universel, fonctionne hors ligne | Peut être deviné, réutilisé, enregistré par un faux site |
| Avoir | Un objet en sa possession | Téléphone, clé physique, carte à puce | Résiste au vol de bases de données | Perte, vol, usurpation de carte SIM, obsolescence |
| Être | Une caractéristique biométrique | Empreinte, visage, voix | Aucun à retenir, difficile à transmettre | Variable selon les conditions, données sensibles, jamais révocables |
| Faire | Un comportement mesuré | Frappe sur un clavier, geste, style de navigation | Discret, complémentaire | Seul, trop faible pour authentifier |
```

Il est tout aussi important de savoir ce qu'une authentification n'est pas. Elle ne chiffre rien : chiffrer, c'est transformer un contenu pour qu'il soit illisible sans clé, et un mot de passe envoyé en clair sur un réseau reste volable même s'il est parfaitement résistant. Elle n'autorise rien : être authentifié ne dit pas ce que l'on a le droit de faire, c'est le sujet de la section sur le moindre privilège. Elle ne garantit pas l'anonymat : un identifiant authentifié est par définition traçable, et c'est précisément ce qui rend la journalisation utile. Enfin, même une authentification multifacteur solide ne protège pas contre tout : ni d'un poste empoisonné qui vole la session après votre connexion, ni d'un collègue qui abuse de droits trop larges, ni d'un phishing soigné qui vous ferait saisir le code à la minute où vous le recevez. La défense reste un empilement de mesures, jamais une seule.

- L'identification annonce un nom, l'authentification prouve ce nom, l'autorisation décide des droits.
- Un facteur appartient à une famille : savoir, avoir, être, faire ; deux secrets de la même famille ne font pas un MFA.
- L'authentification multifacteur exige des preuves de familles différentes et complémentaires.
- Un mot de passe fort ne chiffre rien et n'autorise rien : ce sont trois fonctions distinctes.
- L'authentification ne protège ni des sessions volées après coup, ni des abus de droits internes.
- Toute connexion authentifiée doit être journalisée pour rester auditable.
- La chaîne n'est jamais plus solide que son maillon le plus faible : identifiant partagé égale authentification inutile.
$lesson$),
  ('cyb-c2-p2', 'cyb-c2', 2, $lesson$Pourquoi les mots de passe faibles tombent$lesson$, $lesson$
Considérons le cas de la Médiathèque des Lilas depuis le point de vue d'un attaquant : personne n'a besoin de forcer la porte du bâtiment, il suffit d'obtenir une base de mots de passe. Les bases circulent par centaines de millions, issues de fuites de services commerciaux, de forums oubliés, d'applications abandonnées. Un attaquant n'essaie même pas de deviner votre mot de passe : il le cherche dans une liste et, s'il n'y est pas, il fabrique des variantes de ce qu'il sait déjà des humains. La majorité des mots de passe n'est pas cassée par la puissance de calcul mais par la psychologie appliquée : tous appliquent les mêmes règles de mémorisation, connues depuis des décennies.

L'attaque par dictionnaire consiste à tester un mot de passe après l'autre contre une liste de candidats. Le dictionnaire de base contient les mots du langage, les noms de famille, les prénoms, les villes, les équipes de sport, les dates de naissance, les mots de passe les plus couramment observés dans les fuites. À lui seul, un dictionnaire de quelques milliers d'entrées suffit à éliminer une fraction importante des comptes. Mais le dictionnaire ne s'arrête pas aux mots : il est augmenté par des règles de transformation systématiques que tout outil applique automatiquement. Mettre une majuscule à la première lettre, ajouter un chiffre à la fin, remplacer un a par un 4, doubler une voyelle, ajouter deux chiffres d'année, suffixer un symbole : chacune de ces transformations ne multiplie l'espace de recherche que par quelques dizaines, ce qui se compose en quelques secondes de plus.

Les règles de composition imposées pendant vingt ans ont produit exactement le résultat que la théorie prévoyait. Quand un système exige huit caractères, une majuscule, un chiffre et un symbole, tout le monde finit par obéir de la même manière : un mot courant, une majuscule en tête, un chiffre et un symbole en queue. Le prédicteur n'a même plus besoin de chercher : il applique le gabarit de l'utilisateur moyen. C'est pourquoi les listes de mots de passe les plus couramment observées ressemblent toutes à des variantes d'un même patron, avec une année à la fin qui donne le sentiment du renouvellement sans en avoir le fond. Une politique qui annonce ses règles publiquement et qui ne sanctionne pas les faiblesses revient à publier le gabarit que tous les comptes vont suivre.

```text
EXEMPLE FICTIF : règles appliquées automatiquement par un outil de test
Longueur minimale non atteinte ......................... éliminé
Mot du dictionnaire seul .............................. écarté en quelques secondes
Première lettre en majuscule + chiffre final .......... testé en priorité
Année en suffixe (4 chiffres) .......................... testé pour chaque année courante
Nom du site inséré dans le mot de passe ............... testé en priorité
Faute de frappe courante du clavier ................... testé après le dictionnaire
Mot de passe exactement réutilisé sur un autre service .. tentatives ciblées immédiates
```

D'autres familles de faiblesses reviennent sans exception dans les audits. Les motifs de clavier, comme la suite de touches qwertyuiop ou azertyuiop, sont dans tous les dictionnaires depuis longtemps. Les informations personnelles sont tout aussi exposées : le nom du club de foot, le nom d'un animal de compagnie, une date d'anniversaire, le nom d'une commune comme Lilas. Une attaque dirigée contre une personne connue n'a d'ailleurs même pas besoin de dictionnaire pour ce genre d'information : le nom, la date de naissance et la ville d'un employé sont souvent publics sur les réseaux sociaux et sur le site de l'organisation elle-même. Le mot de passe devient alors un simple assemblage de faits déjà connus de tous.

La longueur reste le premier levier, mais elle ne suffit pas si elle est mal utilisée. Un mot de passe de douze caractères pris dans un mot du dictionnaire suivi de chiffres est toujours devinable en un instant, alors qu'une phrase de passe de quatre mots ordinaires, qui paraît pourtant plus longue et plus banale, exige des milliards d'années de recherche. La différence ne tient pas à la présence d'un chiffre ou d'un symbole, elle tient à l'espace de candidats réellement couvert par le secret, et à savoir si ce secret a déjà été observé quelque part. C'est la notion d'entropie, expliquée plus loin dans ce chapitre, qui permet de quantifier ce que vos yeux ne voient pas quand vous lisez un mot de passe.

- Une base de mots de passe volée se travaille hors ligne : le système attaqué n'est plus en jeu, seulement son fichier d'empreintes.
- Les règles de composition classiques produisent des gabarits prévisibles que les outils testent en priorité.
- Majuscule en tête, chiffre et symbole en queue ajoutent beaucoup de frictions et très peu d'entropie.
- Les motifs de clavier, les dates et les informations personnelles figurent dans tous les dictionnaires.
- Une attaque ciblée part des informations publiques de la victime avant d'essayer quoi que ce soit d'exotique.
- Un mot de passe déjà utilisé sur un autre service est immédiatement tenté sur votre compte.
- La longueur compte davantage que la diversité obligatoire, à condition que les caractères soient réellement imprévisibles.
$lesson$),
  ('cyb-c2-p3', 'cyb-c2', 3, $lesson$Passphrases et gestionnaire de mots de passe$lesson$, $lesson$
Face à ce constat, la première solution est un changement de format plutôt qu'un changement de discipline : la phrase de passe, ou passphrase. Plutôt que d'inventer un mot illisible mêlant lettres, chiffres et symboles, vous choisissez plusieurs mots ordinaires, séparés par des tirets ou des espaces, et vous les mémorisez comme une phrase. Quatre mots de six lettres pris au hasard dans une liste de milliers d'entrées produisent un secret plus long, plus résistant et surtout beaucoup plus agréable à taper. Le gain ne vient pas du mot de passe lui-même mais du fait que vous cessez de le modifier chaque mois : un secret que l'on peut retenir est un secret que l'on n'a pas besoin d'écrire sur un post-it, et c'est la réutilisation, plus que la faiblesse ponctuelle, qui fait basculer les comptes.

La manière de construire une phrase de passe détermine tout son intérêt. Les méthodes sérieuses demandent de tirer les mots au hasard, un par un, dans une liste de quelques milliers de mots usuels, sans les relier par une histoire que vous inventeriez. Une phrase qui raconte une anecdote réelle, comme le nom de votre rue suivi de l'année de votre mariage, revient à replacer dans le secret des informations que tout le monde peut trouver. De même, une citation connue, un vers de poème ou les paroles d'une chanson populaire forment un candidat immédiatement présent dans les dictionnaires modernes, qui contiennent désormais des corpus littéraires entiers. Le bon compromis tient en trois gestes : tirez des mots au hasard, gardez-les dans l'ordre tiré, ajoutez si vous le souhaitez un séparateur et un chiffre que vous seul associez à ce secret.

```text
EXEMPLE FICTIF : méthode de construction d'une phrase de passe
Tirage au hasard de quatre mots d'une liste de 7 776 entrées
  mot 1 : couteau
  mot 2 : lampe
  mot 3 : hirondelle
  mot 4 : genou
Assemblage : couteau-lampe-hirondelle-genou
Longueur : 31 caractères, espace de candidats théorique : 7776 puissance 4
Ne jamais utiliser les exemples de ce document : ils sont publics.
```

Un secret neuf par service reste pourtant la seule règle vraiment efficace, et personne ne peut raisonnablement en retenir une dizaine. C'est là qu'intervient le gestionnaire de mots de passe, l'outil qui porte toutes vos identités chiffrées localement sous une seule phrase de passe maîtresse. Le fonctionnement se résume ainsi : vous ne retenez plus qu'une seule phrase, longue et unique ; le gestionnaire génère et stocke un secret différent pour chaque site ; il remplit le formulaire au bon endroit ; il vous prévient quand un mot de passe a été détecté dans une fuite. La base de données chiffrée peut être synchronisée entre vos appareils, mais elle n'est lisible qu'avec votre phrase maîtresse, et le fournisseur du service ne la détient pas en clair. Le modèle économique de la plupart de ces outils repose d'ailleurs sur cette promesse : si le gestionnaire devient public, la cryptographie rend le contenu inexploitable sans la phrase maîtresse.

Choisir un gestionnaire, c'est aussi choisir ses habitudes. Trois pratiques font toute la différence. D'abord, la phrase maîtresse est la seule que vous retenez : elle doit être longue, tirée au hasard, et jamais réutilisée ailleurs, sous peine de transformer votre coffre en boîte à clés oubliée sous le paillasson. Ensuite, vérifiez la saisie automatique à la main au début : un gestionnaire qui remplit le formulaire sur un faux site reste un risque, et le réflexe à installer consiste à regarder l'adresse affichée avant qu'elle n'agisse. Enfin, prévoyez la sortie de secours : exportez votre coffre régulièrement dans un fichier chiffré et gardez une copie de secours pour les comptes critiques. Un gestionnaire sans plan de secours est un coffre-fort dont vous auriez perdu la combinaison.

Pour une structure comme la Médiathèque des Lilas, l'usage collectif s'organise autrement que l'usage personnel. Le gestionnaire individuel convient aux comptes nominatifs, employés et responsable technique. Les comptes partagés, eux, exigent un dépôt commun contrôlé, avec historique des consultations et rotation planifiée, plutôt qu'une liste de mots de passe collée sous le clavier. Les mots de passe d'application, ceux que les logiciels utilisent sans intervention humaine, ne vivent pas dans le gestionnaire mais dans la configuration du service, avec une durée de vie limitée. Cette séparation évite l'erreur la plus répandue dans les petites structures : un seul secret qui circule par messagerie, sert à tout le monde et ne peut plus être révoqué sans faire tomber l'activité.

- Une phrase de passe combine plusieurs mots tirés au hasard, plus longue et plus facile à retenir qu'un mot de passe illisible de huit caractères.
- Une anecdote personnelle ou une citation connue annule l'avantage de la longueur : ces candidats sont déjà dans les dictionnaires.
- Un secret différent par service : c'est la règle qui limite le plus la casse, et elle n'est tenable qu'avec un gestionnaire.
- La phrase maîtresse du gestionnaire est le seul secret à retenir, et elle ne sert jamais ailleurs.
- Vérifiez l'adresse du site avant chaque saisie automatique : le gestionnaire ne devine pas vos intentions.
- Prévoyez un export chiffré et une copie de secours pour éviter de perdre l'accès à tout.
- Séparez les comptes nominatifs, les comptes partagés et les mots de passe d'application : ils n'ont pas le même cycle de vie.
$lesson$),
  ('cyb-c2-p4', 'cyb-c2', 4, $lesson$Cours de mots de passe : l'entropie expliquée simplement$lesson$, $lesson$
Dire d'un mot de passe qu'il est fort ou faible ne suffit pas à convaincre, parce que ces mots recouvrent des réalités très différentes selon les interlocuteurs. L'entropie est la mesure qui remplace l'adjectif par un nombre. Elle répond à une question précise : combien de bits d'information faut-il pour désigner un candidat parmi tous ceux que l'attaquant va tester ? Un secret entièrement imprévisible possède beaucoup d'entropie, un secret choisi selon une règle connue en possède très peu, même s'il est long et s'il contient un symbole. L'unité est le bit, et chaque bit double le nombre de combinaisons à essayer : ajouter un bit, c'est rendre le travail deux fois plus long pour l'attaquant.

Le calcul de référence est d'une simplicité déconcertante : on prend la taille de l'alphabet de caractères effectivement utilisés, on l'élève à la puissance de la longueur du secret, puis on calcule le logarithme base deux du résultat. Ce logarithme traduit une taille d'espace en nombre de bits : un alphabet de 26 lettres minuscules offre environ 4,7 bits par caractère, 10 chiffres en offrent 3,3, un mélange de lettres, chiffres et symboles imprimables environ 6,5. Multipliez ensuite par la longueur. Si vous tirez les caractères au hasard, l'estimation est exacte ; si vous les choisissez sous l'influence d'une règle ou d'une habitude, elle ne mesure que la taille théorique de l'espace, pas ce que l'attaquant sait déjà de vous.

```text
EXEMPLE FICTIF : estimation d'entropie en trois lignes
Formule : bits = longueur x log2(taille de l'alphabet)

8 caracteres pris au hasard dans 94 symboles ....... 8 x 6,55 = 52 bits
12 caracteres pris au hasard dans 94 symboles ...... 12 x 6,55 = 79 bits
8 caracteres pris dans 36 (lettres et chiffres) .... 8 x 5,17 = 41 bits
4 mots pris au hasard dans une liste de 7 776 mots . 4 x 12,92 = 52 bits
5 mots pris au hasard dans une liste de 7 776 mots . 5 x 12,92 = 65 bits
Mot courant + majuscule + chiffre + symbole ........ souvent moins de 20 bits
```

Traduire ces bits en durée de vie rend l'exercice parlant. L'attaquant hors ligne teste des milliards de candidats par seconde sur des cartes graphiques et s'arrête en général à mi-chemin, la moitié de l'espace suffisant. Avec dix milliards d'essais par seconde, un espace de 41 bits tombe en un peu plus de deux minutes, un espace de 52 bits demande plusieurs jours, un espace de 65 bits dépasse un siècle. Ces chiffres ne changent pas la nature du risque, ils en donnent l'échelle : ce qui distingue deux mots de passe n'est pas la présence d'un astérisque, c'est le nombre d'années de calcul qu'ils imposent.

```python
# Estimation rapide d'entropie (exemple de raisonnement, pas un outil de production)
import math

def bits(longueur, alphabet):
    return longueur * math.log2(alphabet)

print(bits(8, 94))    # mot de passe aléatoire court
print(bits(12, 94))   # mot de passe aléatoire confortable
print(bits(4, 7776))  # phrase de passe de quatre mots
print(bits(5, 7776))  # phrase de passe de cinq mots

# Un mot connu du dictionnaire ne vaut pas ses bits : il est testé en premier.
```

L'estimation a des limites qu'il faut connaître pour ne pas la surévaluer. Un secret déjà présent dans les dictionnaires d'attaquants a une entropie pratique quasi nulle, quelle que soit sa longueur apparente : il est testé au début de la recherche, pas réparti uniformément dans l'espace. De même, une date, un nom de commune ou le nom du club sportif ajoute des bits sur le papier alors qu'ils sont les premiers candidats essayés. C'est pourquoi les outils de vérification modernes croisent la longueur, qui donne l'entropie théorique, et la présence du secret dans des listes de fuites connues, qui donne son entropie réelle. Un site comme https://haveibeenpwned.com/ permet de vérifier si une adresse ou un mot de passe a déjà été observé dans une fuite publique, et ce test prend quelques secondes.

La conséquence pratique tient en quelques règles. Pour un compte personnel qui n'ouvre rien de sensible, quatre mots tirés au hasard suffisent amplement. Pour une messagerie, un compte bancaire ou un serveur d'association, visez cinq ou six mots, ou un mot de passe de douze caractères réellement aléatoires. Pour un compte d'administration qui protège d'autres comptes, ajoutez la double authentification plutôt que de chercher encore des caractères : au-delà d'un certain seuil, la complexité supplémentaire n'apporte presque rien, alors qu'un second facteur change radicalement l'équation. Enfin, changez un secret dès qu'il a pu être observé, et non par habitude tous les trois mois : un renouvellement subi produit des variantes prévisibles, ce que la section précédente a déjà montré.

- L'entropie mesure le nombre de bits qui distinguent un secret de tous les autres candidats.
- Chaque bit double le travail de l'attaquant, chaque caractère additif multiplie l'espace.
- Le calcul rapide est longueur multipliée par le logarithme base deux de l'alphabet utilisé.
- Un secret déjà présent dans les fuites a une entropie pratique proche de zéro.
- Une phrase de passe de quatre mots tirés au hasard égale un mot de passe de huit symboles aléatoires.
- Au-delà d'un seuil confortable, préférez ajouter un facteur plutôt que des caractères.
- Vérifiez vos secrets et vos adresses dans les fuites publiques avant de compter sur leur longueur.
$lesson$),
  ('cyb-c2-p5', 'cyb-c2', 5, $lesson$Attaques par force brute, credential stuffing, réutilisation$lesson$, $lesson$
Les attaques qui visent les identifiants se distinguent par le lieu où elles se déroulent, et cette distinction décide de ce qui les arrête. Une attaque en ligne frappe le service lui-même : l'attaquant envoie des tentatives de connexion, le système les examine et peut les compter, les ralentir ou les bloquer. Une attaque hors ligne, elle, travaille sur une copie volée du fichier des empreintes : plus aucune limite de débit ne s'applique, les cartes graphiques tournent à plein régime et le service attaqué n'est même pas au courant. La défense n'est donc pas la même : côté en ligne, on protège par des limites de tentatives ; côté hors ligne, on ne protège que par la qualité des secrets et par la difficulté à obtenir le fichier.

La force brute pure consiste à essayer toutes les combinaisons dans l'ordre, et elle n'a de sens que pour des espaces très petits, comme un code à quatre chiffres. Dans la pratique, on parle de force brute hybride : on part d'un dictionnaire, on applique des règles de transformation, on teste d'abord les combinaisons probables. Côté en ligne, les contre-mesures sont connues : limitation des tentatives par compte et par adresse source, temporisation croissante, captcha après quelques échecs, et surtout journalisation des échecs pour détecter l'attaque en cours. Une bonne politique ne verrouille pas immédiatement, car le verrouillage devient alors une arme : un attaquant peut verrouiller volontairement les comptes d'un service pour paralyser l'activité, c'est ce qu'on appelle un déni de service par verrouillage.

```text
EXEMPLE FICTIF : cycle de vie d'une attaque hors ligne
1. Obtention du fichier volé (fuite, sauvegarde oubliée, copie locale)
2. Identification du procédé de stockage (sel ou pas de sel, algorithme, itérations)
3. Déploiement d'un dictionnaire de base augmenté de règles de transformation
4. Essai des variantes personnelles de la victime (noms, dates, ville, équipe)
5. Fuite éventuelle réutilisée : paires identifiant et mot de passe testées ailleurs
6. Accès au compte, puis escalade vers les autres comptes de la même personne
```

Le rôle du sel mérite d'être précisé, car il est souvent mal compris. Un sel est une valeur aléatoire stockée à côté de chaque empreinte, calculée une fois pour chaque utilisateur, afin que deux personnes qui choisissent le même mot de passe n'aient pas la même empreinte. Son effet est immédiat : les tables précalculées, ces gigantesques dictionnaires d'empreintes déjà calculées, deviennent inutiles, et chaque mot de passe doit être recherché séparément. Ce que le sel ne fait pas, c'est rendre un mot de passe faible résistant : il ralentit la préparation de l'attaque, pas l'attaque elle-même contre un candidat précis. Seule la résistance du secret, combinée à un nombre d'itérations important du procédé de hachage, allonge réellement la durée de la recherche.

Le credential stuffing, littéralement bourrage d'identifiants, est l'attaque qui profite le plus directement de la réutilisation. L'attaquant dispose de paires identifiant et mot de passe issues d'une fuite d'un tout autre service, et il les teste automatiquement contre des milliers de sites : boutiques, réseaux sociaux, messageries, portails d'associations. Rien n'est deviné, rien n'est forcé : on se contente de rejouer des combinaisons connues. Les outils automatisent des dizaines de milliers de tentatives par heure depuis des réseaux de machines compromises, ce qui leur permet de contourner les limites simples par adresse. Le taux de succès reste faible en proportion, mais il suffit : sur un échantillon de plusieurs millions de paires, quelques milliers de comptes réellement vulnérables représentent des milliers d'intrusions exploitables.

Une variante complémentaire, le bourrage de mots de passe, inverse la stratégie : au lieu d'un identifiant et de nombreux mots de passe, on teste quelques mots de passe très communs contre un très grand nombre d'identifiants. Le motif évite les mécanismes de verrouillage par compte, puisque chaque compte ne subit qu'une seule tentative, et il obtient des résultats sur les comptes négligés : comptes techniques abandonnés, comptes de démonstration, comptes d'anciens employés jamais désactivés. La parade à ces deux familles d'attaques est la même : interdire la réutilisation avec un gestionnaire, exiger un second facteur, et détecter les volumétries inhabituelles dans les journaux de connexion.

Pour agir concrètement, deux vérifications suffisent. Premièrement, recherchez vos adresses de courrier électronique sur https://haveibeenpwned.com/ et traitez chaque fuite signalée comme un mot de passe à changer immédiatement, même si le service concerné vous semble secondaire. Deuxièmement, éliminez la réutilisation en premier : un gestionnaire vous permet d'obtenir un secret unique par service en quelques minutes, ce qui neutralise intégralement le credential stuffing pour vos comptes. Toute autre optimisation vient après. La meilleure politique de mot de passe du monde ne sert à rien si la même combinaison ouvre cinquante portes différentes.

- Une attaque en ligne se heurte aux limites de tentatives ; une attaque hors ligne ne se heurte à rien.
- La force brute réelle est rare : on teste d'abord les candidats probables, avec des règles de transformation.
- Le sel casse les tables précalculées mais ne rend pas un mot de passe faible plus résistant.
- Le credential stuffing rejoue des paires volées sur d'autres services, sans rien deviner.
- Le bourrage de mots de passe teste quelques mots communs contre beaucoup d'identifiants pour éviter les verrouillages.
- Les comptes techniques abandonnés sont la cible préférée : désactivez ce qui ne sert plus.
- Vérifiez vos adresses dans les fuites publiques, puis supprimez toute réutilisation avec un gestionnaire.
$lesson$),
  ('cyb-c2-p6', 'cyb-c2', 6, $lesson$La double authentification : TOTP, clé physique, SMS$lesson$, $lesson$
La double authentification change l'équation parce qu'elle retire au vol de mot de passe son effet décisif. Un attaquant qui dispose d'un identifiant et d'un mot de passe n'obtient plus l'accès : il lui manque une preuve d'une autre famille, un objet ou un appareil qui ne voyage pas avec le fichier volé. Le bénéfice est considérable face aux deux menaces dominantes, le credential stuffing et le vol de base de données, puisque l'une et l'autre ne fournissent que le premier facteur. En revanche, la double authentification n'est pas un talisman : elle déplace le risque vers la récupération du second facteur, vers les canaux de récupération, et vers l'utilisateur lui-même, que l'attaquant peut tenter de convaincre d'appuyer sur accepter.

Les codes reçus par message sont le moyen le plus répandu parce qu'ils fonctionnent partout : n'importe quel téléphone, même sans application, reçoit un message. Le principe est simple : le service envoie un code court, à usage unique, que vous saisissez pour compléter la connexion. Les limites sont bien documentées. L'usurpation de carte SIM permet à un attaquant de faire basculer votre numéro sur sa propre carte, la récupération passant souvent par ce même canal. Les protocoles de messagerie texte anciens peuvent être détournés, les codes arrivent en retard quand le réseau est saturé, et rien ne fonctionne sans couverture. Enfin, un code intercepté reste lisible, ce qui en fait le facteur le plus faible des trois, encore utile mais jamais idéal.

```text
EXEMPLE FICTIF : fonctionnement d'un code TOTP commenté
Etape 1 : le service et l'application partagent un secret aléatoire a l'enregistrement
Etape 2 : l'application découpe le temps en fenetres de 30 secondes
Etape 3 : elle calcule une empreinte du couple secret et numero de fenetre
Etape 4 : les six premiers chiffres de l'empreinte deviennent le code affiche
Etape 5 : le service refait le meme calcul avec la fenetre courante et les voisines
Etape 6 : si les chiffres correspondent, la connexion est acceptee
Etape 7 : le code ne sert qu'une fois : apres usage, la fenetre est refermee
Le secret du partage doit être regenere si quelqu'un le photographie.
```

Le code à usage unique basé sur le temps, souvent abrégé TOTP, fonctionne sans réseau : l'application et le service partagent un secret lors de l'enregistrement, puis calculent chacun de leur côté le même code à partir de l'heure. C'est ce qui explique son indépendance vis-à-vis de l'opérateur téléphonique et son adoption massive dans les applications d'authentification. Ses faiblesses sont d'un autre ordre. Un logiciel malveillant qui observe l'écran ou qui enregistre les frappes peut voler le code en même temps que vous le lisez, et un site frauduleux suffisamment convaincant peut vous demander votre code en direct, à la seconde où vous le recevez : le code n'a alors plus de valeur de preuve, puisque c'est vous qui le portez à l'attaquant. La fenêtre de validité, d'ordre d'une minute, limite la réutilisation mais pas la captation en temps réel.

Les clés physiques, fondées sur le standard FIDO2 et son volet WebAuthn, traitent ce défaut de fond en supprimant le secret partagé. Chaque site reçoit une paire de clés générée dans l'appareil : la clé privée ne quitte jamais l'objet, et l'objet ne répond qu'à une question posée par le domaine exact qui l'a enregistrée. Cette liaison au nom de domaine est ce qui rend l'approche résistante au phishing : une fausse adresse, même visuellement identique, ne déclenche aucune réponse de la clé, parce que le défi vient d'un domaine non reconnu. Le déroulement est physique en plus de cryptographique : la clé doit être présente, souvent activée par un toucher. Les inconvénients sont pratiques plutôt que techniques : un coût d'achat, la nécessité d'en posséder deux, dont une en réserve, et une couverture encore inégale sur les services anciens.

Les notifications d'application, celles où l'on valide une connexion sur son téléphone, occupent une position intermédiaire : agréables et résistantes au vol de mot de passe, elles exposent à la fatigue de demandes. Un attaquant qui tente des connexions répétées peut finir par déclencher chez l'utilisateur l'habitude de refuser, puis un jour l'acceptation par inadvertance. Les mécanismes modernes limitent ce risque en affichant un numéro à comparer, que l'attaquant ignore, et en refusant de répéter les demandes. Le réflexe à installer reste simple : une demande que vous n'avez pas déclenchée est toujours refusée, et si elle se répète, elle impose de changer le mot de passe.

```table
| Facteur | Usage courant | Résistance au phishing | Résistance au vol de base | Coût et contraintes | Recommandation |
| --- | --- | --- | --- | --- | --- |
| SMS | Partout, sans application | Faible | Bonne | Gratuit, dépend du réseau | Mieux que rien, à éviter comme unique facteur |
| TOTP | Application d'authentification | Faible en cas de faux site | Très bonne | Gratuit, hors ligne | Excellent choix par défaut |
| Notification | Application mobile du service | Moyenne, exposée à la fatigue | Bonne | Gratuit | À accompagner d'un numéro à comparer |
| Clé FIDO2 | Objet branché ou intégré | Très bonne grâce à la liaison au domaine | Excellente | Achat, deux objets minimum | Recommandé pour les comptes d'administration |
| Empreinte | Téléphone ou ordinateur | Variable selon l'implémentation | Bonne | Matériel récent | Pratique en complément d'un second facteur |
```

Choisir un facteur revient à répondre à deux questions : qui attaque, et que protège-t-on. Pour un compte personnel ordinaire, une application de codes à usage unique offre le meilleur rapport protection et effort, à condition d'enregistrer un second moyen de secours. Pour un compte d'administration qui ouvre l'accès au serveur ou au site de la médiathèque, une clé physique devient le choix de raison : ce sont précisément les comptes visés par les attaques ciblées. Pour un usager qui refuse toute installation, un code par message reste préférable à rien : on ne retarde jamais l'activation d'un facteur imparfait au motif qu'il n'est pas parfait.

- La double authentification retire au vol de mot de passe son effet immédiat en exigeant une preuve d'une autre famille.
- Un code par message est universel mais vulnérable à l'usurpation de carte SIM et aux délais de réseau.
- Un code TOTP fonctionne hors ligne, change toutes les trente secondes et se vole sur un faux site.
- Une clé FIDO2 ne répond qu'au domaine exact qui l'a enregistrée : c'est ce qui bloque le phishing.
- Une demande de validation non déclenchée est refusée, et sa répétition impose de changer le mot de passe.
- La sécurité d'un second facteur dépend aussi de ses canaux de récupération, souvent le maillon faible.
- Deux facteurs de secours valent mieux qu'un facteur unique, même excellent.
$lesson$),
  ('cyb-c2-p7', 'cyb-c2', 7, $lesson$Configurer la MFA pas à pas$lesson$, $lesson$
L'activation d'un second facteur est une opération de quinze minutes qui suit toujours le même squelette, quel que soit le service. Nous prenons ici des comptes grand public comme exemples généraux, ceux d'un fournisseur de messagerie ou de bureaux en ligne, parce que la logique est identique partout : ouvrir la page de sécurité du compte, choisir un facteur, l'enregistrer, conserver les moyens de secours, tester, puis vérifier les sessions existantes. L'enregistrement se fait une fois, l'usage se fait à chaque connexion, et c'est le service qui décide quand il redemande un facteur, selon la sensibilité de l'action.

La première étape consiste à rejoindre les paramètres de sécurité du compte et à activer la double authentification, souvent désactivée par défaut. Le service vous propose alors une liste de facteurs : application d'authentification, code par message, notification, clé physique, adresse de secours. Choisissez d'abord l'application de codes à usage unique : elle ne dépend pas de la couverture réseau et n'entraîne aucun coût. Le service affiche alors un code à deux dimensions à scanner ainsi qu'une clé de configuration, et il vous demande de saisir le premier code produit par l'application pour prouver que le partage est correct. Cette vérification n'est pas une formalité : elle garantit que votre application et le service calculent bien la même chose avant que vous ne refermiez la fenêtre.

La deuxième étape est celle que tout le monde bâcle : la génération des codes de secours. Ces codes, émis en une seule fois, servent à récupérer l'accès si vous perdez le téléphone. Le service les affiche sous forme de liste à télécharger ou à imprimer, et il ne les montrera jamais à nouveau. Conservez-les hors ligne, dans un endroit connu de vous seul, par exemple dans un pli de portefeuille. Ne les photographiez pas pour les envoyer à vous-même par messagerie : la copie se retrouverait dans votre boîte, exactement là où un attaquant compromis irait la chercher. Régénérez-les après chaque usage, ou au minimum une fois par an.

La troisième étape consiste à enregistrer un second moyen, distinct du premier. Si l'application est votre facteur principal, ajoutez une adresse de secours ou, mieux, une clé physique pour les comptes sensibles. L'erreur classique consiste à enregistrer un seul facteur et à se retrouver enfermé au premier changement de téléphone. Un facteur principal et un facteur de secours de nature différente couvrent les deux scénarios courants : la perte de l'appareil et le compromission du compte de récupération. Pour un compte partagé ou un compte de service, la logique change : il faut prévoir deux objets déposés physiquement dans un coffre, plutôt qu'un téléphone personnel qui partirait avec l'employé.

La quatrième étape est le test réel. Déconnectez-vous, reconnectez-vous, et constatez que le service réclame bien votre code. Vérifiez également que la saisie automatique de mot de passe ne comble pas le champ de code à votre place : l'application de codes reste à saisir manuellement, et c'est voulu. Terminez par l'examen des sessions ouvertes et des appareils reconnus, que la plupart des services listent sur la même page : révoquez ceux que vous ne reconnaissez pas, et profitez-en pour retirer l'accès aux applications tierces que vous n'utilisez plus, car ces autorisations prolongées constituent une porte latérale très prisée.

```text
Flux d'authentification avec double authentification

Utilisateur          Navigateur             Service              Facteur externe
    |                    |                      |                      |
    |-- identifiant ---->|                      |                      |
    |                    |-- verification ----->|                      |
    |<--- mot de passe --|<-- accepte le 1er ---|                      |
    |                    |     facteur          |                      |
    |-- code a usage unique (2e facteur) ------>|                      |
    |                    |                      |-- derive et verifie ->|
    |                    |                      |<-- resultat ---------|
    |<--- session ouverte et duree limitee ----|                      |
    |                    |                      |                      |
    |  en cas d'echec : tentative comptee, delai croissant, alerte    |

Ce schéma montre deux points de vigilance : le code voyage apres le mot de
passe, et la session ouverte reste valide meme si le mot de passe est change
plus tard, d'ou la necessite de revoquer les sessions.
```

```text
PLAN D'ACTIVATION MFA (modele a adapter)
1. Recenser les comptes du perimetre : personnels, partages, techniques, du site web
2. Classer chaque compte par sensibilite : public, courant, administrateur
3. Activer l'application de codes sur les comptes courants et personnels
4. Generer les codes de secours et les deposer hors ligne
5. Enregistrer une cle physique sur chaque compte administrateur
6. Tester une deconnexion puis une reconnexion sur chaque profil
7. Revoquer les sessions anciennes et les applications tierces inutiles
8. Programmer une revue trimestrielle des comptes et des droits
9. Former les utilisateurs au refus des demandes de validation non provoquees
```

Trois écueils reviennent après l'activation : la perte du téléphone sans code de secours, qui laisse le compte inaccessible ; le déni de la seconde étape par les logiciels anciens, qui réclament alors un mot de passe d'application, objet de la section suivante ; enfin l'activation incomplète : cocher la case sans vérifier que la seconde étape se déclenche vraiment et que les codes de secours existent.

- Ouvrez les paramètres de sécurité, activez la double authentification, choisissez d'abord l'application de codes.
- Vérifiez le partage en saisissant un premier code avant de fermer la page d'enregistrement.
- Téléchargez les codes de secours une seule fois et rangez-les hors de la messagerie.
- Enregistrez toujours un second moyen de nature différente, afin de couvrir perte et compromission.
- Testez une reconnexion complète et examinez la liste des sessions et des appareils reconnus.
- Révoquez les autorisations d'applications tierces qui ne servent plus.
- Un logiciel ancien exige un mot de passe d'application, jamais votre mot de passe principal.
$lesson$),
  ('cyb-c2-p8', 'cyb-c2', 8, $lesson$Le moindre privilège : comptes, droits, administration séparée$lesson$, $lesson$
Le moindre privilège est le principe le plus simple à énoncer et le plus souvent bafoué dans les petites structures : chaque compte ne dispose que des droits strictement nécessaires à sa tâche, ni plus, ni moins, et ces droits sont réexaminés dès que la tâche change. Là où un mot de passe fort protège la porte, le moindre privilège décide de ce que la porte ouvre. Un comptable qui dispose des droits d'administration sur tout le poste n'a pas besoin d'être lui-même victime d'une attaque : un simple logiciel malveillant lancé par inadvertance exécutera ses actions avec ses droits, et ils seront largement suffisants. La question à poser à chaque compte n'est donc pas seulement de savoir ce qu'il peut faire, mais de mesurer le préjudice maximal si ses droits tombaient entre de mauvaises mains.

Pour la Médiathèque des Lilas, l'inventaire tient en quatre comptes types qui se retrouvent dans presque toute organisation. Le compte public sert aux visiteurs en libre accès et ne doit rien pouvoir installer ni consulter. Le compte d'employé permet de gérer les adhérents et le catalogue, mais rien de plus. Le compte d'administration détient les droits élevés et sert uniquement à maintenir la machine. Le compte de service d'impression, enfin, n'est pas une personne : c'est une identité technique utilisée par le serveur d'impression pour accéder aux files d'attente. Décrire ces quatre comptes dans un tableau, puis remplir une case par ressource, produit instantanément une photographie des droits qui surprend presque toujours les responsables.

```table
| Ressource | Compte public | Employé | Administrateur | Service d'impression |
| --- | --- | --- | --- | --- |
| Poste en libre accès | Utilisation seule, aucune installation | Session nominative standard | Droits élevés, usage ponctuel | Aucun |
| Wi-Fi visiteurs | Accès internet filtré | Accès personnel | Accès gestion et technique | Accès réseau local vers le serveur |
| Serveur d'association | Aucun accès | Lecture et écriture sur ses dossiers | Accès complet, administration | Accès aux seules files d'impression |
| Site web de l'association | Consultation | Publication des contenus validés | Déploiement et comptes techniques | Aucun |
| Base des adhérents | Aucun accès | Consultation et mise à jour | Administration et sauvegarde | Aucun |
| Mots de passe d'autres comptes | Aucun | Jamais visibles | Chiffre et transmet par canal sûr | Jamais |
```

La conséquence la plus importante du tableau est la nécessité d'une administration séparée. Un compte d'administration n'est pas un compte ordinaire avec quelques cases cochées en plus : c'est une identité distincte, avec son propre nom, son propre secret et sa propre raison d'être. On ne navigue pas sur le web avec le compte d'administration, on n'ouvre pas sa messagerie avec ce compte, on n'y range pas ses fichiers personnels. Chaque utilisation au quotidien d'un compte administratif expose un privilège immense à la moindre erreur de clic. La bonne pratique consiste à conserver deux identités par personne habilitée : une identité de travail normale pour tout l'usage courant, et une identité d'administration utilisée uniquement pendant les opérations qui l'exigent, idéalement avec une élévation de droits au cas par cas plutôt qu'un compte toujours élevé.

La gestion par groupes achève le tableau. Plutôt que d'attribuer des droits un à un à chaque nouvel arrivant, on décrit des rôles, employé, responsable, administrateur, service, puis on place chaque compte dans les groupes correspondants. Lorsqu'un employé change de service, on déplace le compte d'un groupe, ce qui retire automatiquement les anciens droits et en accorde les nouveaux. Sans groupe, les droits s'accumulent, jamais personne ne retire, et au bout de trois ans personne ne sait plus qui peut quoi. La revue trimestrielle consiste à refaire le tableau de droite : un compte qui n'apparaît plus dans aucune tâche est désactivé, puis supprimé après un délai de sécurité, et un compte dont la liste des groupes a grossi sans justification est remis à niveau.

- Le moindre privilège limite chaque compte au strict nécessaire à sa tâche actuelle.
- Décrivez vos comptes dans une matrice de droits : la réalité apparaît en quelques minutes.
- Compte d'usage et compte d'administration sont deux identités distinctes, jamais la même.
- On n'ouvre pas de courriel ni de navigateur avec un compte administratif.
- Gérez les droits par groupes et par rôles, pas par accumulation d'exceptions manuelles.
- Un compte de service n'est pas une personne : il n'a pas de session interactive.
- Désactivez ce qui ne sert plus avant de le supprimer, et revenez au tableau chaque trimestre.
$lesson$),
  ('cyb-c2-p9', 'cyb-c2', 9, $lesson$Comptes de service et mots de passe d'application$lesson$, $lesson$
Tous les identifiants d'un système ne correspondent pas à des personnes, et c'est précisément ce qui les rend délicats. Un compte de service est une identité technique utilisée par un programme : le script de sauvegarde qui monte le dossier partagé, le serveur d'impression qui interroge la file d'attente, l'application web qui lit la base des adhérents, l'automatisme qui publie le programme des ateliers sur le site. Ces comptes ne se connectent jamais au clavier, ne reçoivent aucun courriel de bienvenue et n'ont aucun propriétaire physique. Leur risque est double : ils sont souvent dotés de droits élevés parce que c'est plus simple, et leur secret est souvent figé pour toujours parce que le programme qui l'utilise serait difficile à réparer.

Trois règles suffisent à dompter cette famille de comptes. La première est l'interdiction de la connexion interactive : un compte de service doit être refusé par l'écran de connexion, car il n'a aucune raison d'être utilisé par un humain, et cette restriction seule transforme un vol de secret en incident moins grave. La seconde est le moindre privilège strictement appliqué aux ressources que le programme touche réellement, vérifiable ligne par ligne dans le tableau précédent. La troisième est la rotation : le secret doit changer à échéance fixe, ce qui suppose une configuration unique et centralisée, plutôt que copiée dans trois scripts et une base de données.

```text
EXEMPLE FICTIF : configuration d'un compte de service
Nom du compte .......... impression-mediatheque
Usage .................. connexion automatique du serveur d'impression
Connexion interactive ... refusee
Droits .................. lecture et ecriture sur la file Locale-Ateliers uniquement
Secret .................. genere par le gestionnaire, 32 caracteres aleatoires
Rotation ................ trimestrielle, date inscrite au registre
Stockage ................ variable d'environnement du service, jamais dans le script
Responsable ............. le responsable technique, nomme dans le registre
Journalisation .......... tentatives refusees et succes enregistres
```

Le stockage du secret mérite une attention particulière parce qu'il est la faiblesse la plus fréquente. Un mot de passe écrit en clair dans un script de sauvegarde est découvert par quiconque peut lire le fichier, et ces fichiers ont souvent une longue vie. La bonne pratique consiste à placer le secret dans une variable d'environnement ou dans un fichier de configuration dont les droits de lecture sont restreints au compte du service, puis à ne jamais l'inclure dans un dépôt de code. Une rotation qui exige de modifier le code source à chaque changement ne se fera jamais : placez la valeur à un endroit unique et modifiable, et la rotation devient une opération de deux minutes.

Les mots de passe d'application relèvent d'un besoin voisin : celui des logiciels qui ne savent pas présenter un second facteur. Une messagerie sur un téléphone ancien, un client de courrier installé sur un poste de l'association, un script qui envoie des notifications, un périphérique réseau qui doit s'authentifier : aucun de ces outils ne peut saisir un code à usage unique à chaque connexion. La réponse universelle est de générer pour chacun un secret dédié, émis une seule fois par le service, limité à cet usage précis et révocable individuellement. L'avantage est considérable : si le secret d'un script fuit, vous le retirez sans toucher au mot de passe principal et sans déconnecter personne d'autre. L'inconvénient est que ces secrets s'accumulent, ce qui impose de les recenser avec les comptes de service dans le même registre.

Un registre d'identités techniques est donc le livret de ce chapitre. Il réunit, pour chaque compte de service et chaque mot de passe d'application, le nom, le propriétaire, la ressource touchée, la dernière rotation, la prochaine échéance et l'emplacement du secret. Tenu dans un tableur simple, il change la qualité des réponses en cas d'incident : savoir en deux minutes quel script utilise quel secret permet de le révoquer sans faire tomber le service, au lieu de couper tout le monde par sécurité. Il constitue aussi le point de départ du mini-projet de fin de chapitre.

- Un compte de service n'a pas de personne derrière : refusez-lui toute connexion interactive.
- Atteignez ses droits au plus juste sur les ressources qu'il touche réellement.
- Placez le secret dans une variable d'environnement ou un fichier restreint, jamais dans le code.
- Une rotation ne se fera jamais si elle impose de modifier le code source.
- Un mot de passe d'application est dédié, révocable individuellement et différent du mot de passe principal.
- Recensez comptes de service et mots de passe d'application dans un registre daté.
- Nommez un responsable humain pour chaque identité technique, sinon personne ne la révoquera.
$lesson$),
  ('cyb-c2-p10', 'cyb-c2', 10, $lesson$Le compte public de la médiathèque : verrouillage, kiosque, profils$lesson$, $lesson$
Le poste en libre accès pose un problème que le moindre privilège rend visible : qui est responsable de ce qui s'y passe ? Sur un compte unique partagé, la réponse est personne. Aucune journalisation n'est exploitable, aucun fichier ne sait à qui il appartient, et la dernière personne ayant utilisé le poste laisse derrière elle ses sauvegardes, ses mots de passe de session, ses historiques de navigation et parfois ses fichiers personnels. Ce n'est pas un détail d'organisation : l'absence de nominativité prive l'établissement de toute possibilité de comprendre un incident, et transforme chaque session en opportunité pour un visiteur mal intentionné d'installer quelque chose pour le suivant.

La réponse commence par la séparation des profils. Le visiteur dispose d'un compte local limité, créé pour l'usage public, sans droits d'installation ni accès aux dossiers des employés. Les employés disposent de leur propre compte nominatif, avec leurs droits sur le catalogue et les adhérents. Le responsable technique conserve son compte d'administration, utilisé à la demande et jamais laissé ouvert. Ce partage a un coût organisationnel minime et un bénéfice immédiat : les journaux deviennent lisibles, les fichiers deviennent attribuables, et la session publique peut être remise à zéro entre deux usagers sans risque de porter atteinte au travail des employés.

```text
EXEMPLE FICTIF : parametrage d'un poste public
Compte ................. utilisateur-public (local, droits limites)
Fermeture automatique .. apres 10 minutes d'inactivite
Verrouillage ........... touche dediee + ecran de veille protege par code
Profil .................. reinitialise a chaque deconnexion
Dossier personnel ...... chiffre et efface a la fin de session
Navigation ............. mode kiosque, page d'accueil verrouillee
Extensions .............. aucune installation possible
Installation de logiciel refusee (registre protege)
Copie sur cle USB ....... refusee pour les comptes publics
Journal ................ conservation 30 jours, consultable par l'administrateur
```

Le mode kiosque mérite d'être expliqué parce qu'il est souvent confondu avec un simple verrouillage d'écran. Dans un vrai mode kiosque, le navigateur démarre sur une adresse définie, s'ouvre en plein écran, ne propose ni installation d'extension ni téléchargement libre, et se ferme en effaçant toute la session lorsque l'usager se déconnecte ou que le délai expire. L'objectif n'est pas d'empêcher quelqu'un de consulter le catalogue, c'est de garantir que la prochaine personne trouve un poste vierge. Le verrouillage, lui, protège l'instant : il empêche quiconque de reprendre la session laissée ouverte pendant que l'employé va chercher un carton en réserve. Les deux mesures sont complémentaires, et l'une ne remplace pas l'autre.

L'habitude du verrouillage se déclenche en une seconde et se perd en une journée de tranquillité : la combinaison de touches dédiée s'enseigne dès la prise de poste, comme le code du local. Sur un poste public, le verrouillage automatique fait le travail à la place de l'humain, assez tôt pour être utile et assez tard pour ne pas gêner : dix minutes en libre accès, deux minutes pour un poste qui traite des données personnelles. Le même raisonnement vaut pour les écrans visibles depuis l'accueil, où une session laissée ouverte expose les informations des adhérents à quiconque passe.

Un dernier point concerne la fin de journée. Fermer la session ne suffit pas si le profil conserve des traces : téléchargements, historique, cookies de session, fichiers temporaires. Un script de remise à zéro qui efface le profil public et relance le poste en mode kiosque évite les oublis, en particulier ceux des soirs de fermeture pressée. Ajoutez-y la remise mécanique des périphériques : clés USB oubliées dans le port, documents imprimés laissés à la sortie. La sécurité des postes publics relève autant de la routine de fermeture que de la configuration, et cette routine mérite d'être écrite dans la même politique que les mots de passe.

- Un compte public partagé supprime toute responsabilité : séparez public, employé et administrateur.
- Le verrouillage protège l'instant présent, la réinitialisation de profil prépare la session suivante.
- Le mode kiosque verrouille la navigation, interdit les installations et repart d'une page imposée.
- Réglez la fermeture automatique assez tôt pour être utile, assez tard pour ne pas gêner.
- Les écrans visibles depuis l'accueil relèvent de la protection des données personnelles.
- Écrivez une routine de fin de jour : profil remis à zéro, périphériques retirés, session fermée.
- Conservez les journaux trente jours au minimum : ils sont inutiles le jour où on en a besoin.
$lesson$),
  ('cyb-c2-p11', 'cyb-c2', 11, $lesson$Réponse à la compromission$lesson$, $lesson$
Un compte se compromet rarement au moment où l'on s'y attend, et la qualité de la réponse se mesure en minutes plutôt qu'en jours. Les signes qui déclenchent l'action immédiate sont faciles à repérer : un courrier envoyé que vous n'avez pas écrit, une adresse de récupération que vous ne reconnaissez pas, une demande de code à usage unique que vous n'avez pas sollicitée, une connexion depuis une ville improbable, un fichier modifié sur le serveur. Le premier réflexe n'est pas de comprendre, c'est de couper l'accès de l'attaquant, puis de comprendre à loisir. Une compromission contenue en dix minutes est un incident mineur ; la même compromission découverte trois semaines plus tard est une crise.

L'ordre des opérations compte autant que les opérations elles-mêmes. Commencez par un appareil dont vous êtes certain, c'est-à-dire un poste sain ou un téléphone personnel, jamais le poste où le doute est né, puisque ce poste peut enregistrer ce que vous tapez. Changez le mot de passe du compte avec un secret généré et unique, ce qui ferme la porte principale. Révoquez ensuite toutes les sessions ouvertes, car un mot de passe modifié ne déconnecte pas toujours les sessions déjà établies, et c'est précisément ce que recherche un attaquant installé : rester connecté après que vous avez changé le secret. Si le service propose l'option, la révocation des sessions après changement de mot de passe fait les deux gestes en une opération.

```text
CHRONOLOGIE DE REPONSE (exemple adapte a la mediatheque)
T+0 min .... signalement ou constat, notation de l'heure et du compte concerne
T+2 min .... ouverture depuis un poste propre, changement du mot de passe
T+4 min .... revocation de toutes les sessions et des appareils reconnus
T+6 min .... examen des facteurs MFA : suppression de tout facteur inconnu
T+8 min .... suppression des regles de messagerie et des adresses de recuperation
T+10 min ... revocation des applications tierces et des mots de passe d'application
T+15 min ... verification des autres comptes reutilisant le meme ancien secret
T+20 min ... information du responsable, conservation des journaux, observation
T+1 j ...... revue des acces du serveur et du site, compte rendu ecrit
```

La vérification des annexes est l'étape que tout le monde oublie, alors qu'elle décide de la durée du trouble. Un attaquant qui a accédé à une messagerie laisse rarement la porte ouverte une fois le mot de passe modifié : il ajoute une règle qui copie discrètement les courriers, il enregistre un second facteur sur son propre téléphone, il mémorise les contacts importants. Parcourez méthodiquement les facteurs enregistrés, les adresses de récupération, les règles de tri, les applications tierces et les mots de passe d'application, puis retirez tout ce que vous ne reconnaissez pas. Prenez enfin la liste des services où l'ancien secret était réutilisé, que votre gestionnaire vous fournit en une seconde : c'est là que se joue la différence entre un incident isolé et une cascade.

La dernière étape est administrative et humaine. Consignez par écrit l'heure, les comptes concernés, les actions entreprises et les éléments observés dans les journaux : cette chronologie devient précieuse si l'incident doit être qualifié ou partagé avec le responsable. Signalez la compromission aux personnes concernées lorsqu'elle a touché des données d'adhérents, vérifiez ensuite si l'adresse apparaît dans une fuite publique, puis tirez-en une leçon datée : activez le second facteur manquant, supprimez la réutilisation, réglez les délais de session. Un incident traité sans correction est un incident qui reviendra.

- Réagissez depuis un appareil sûr, puis changez le secret avant de chercher à comprendre.
- Révoquez les sessions : changer le mot de passe ne déconnecte pas toujours les connexions établies.
- Examinez facteurs MFA, adresses de récupération et règles de messagerie, un par un.
- Retirez les applications tierces et les mots de passe d'application inconnus.
- Identifiez tous les services où l'ancien secret était réutilisé, avec votre gestionnaire.
- Conservez une chronologie écrite et notez les leçons retenues avec une date.
$lesson$),
  ('cyb-c2-p12', 'cyb-c2', 12, $lesson$Mini-projet guidé : politique d'identité de la médiathèque$lesson$, $lesson$
Il est temps d'assembler toutes les pièces du chapitre dans un document unique : la politique d'identité et d'accès de la Médiathèque des Lilas. Ce livrable n'est pas un texte de théorie, c'est une page que le responsable technique peut faire valider par la direction, remettre à un nouvel arrivant et reprendre lors d'un audit. Il mobilise toutes les notions abordées : inventaire des comptes, règles sur les secrets, double authentification, matrice des droits, comptes de service, routine des postes publics et procédure de réponse. Écrivez-le dans votre éditeur, gardez-le court, et remplissez-le avec vos propres valeurs : une politique générique que personne n'a adaptée à son parc est un document que personne n'appliquera.

Le document se compose de six rubriques qui suivent le chemin de ce chapitre. La première décrit le périmètre et inventorie les comptes, quatre types pour la médiathèque. La deuxième énonce les règles de secret : quatre mots minimum, un secret par service, gestionnaire obligatoire, réutilisation interdite. La troisième fixe le plan de double authentification : application de codes sur tous les comptes nominatifs, clé physique sur les comptes d'administration, codes de secours hors ligne, revue trimestrielle. Les trois autres rappellent la matrice des droits, la routine des postes publics et la procédure d'incident, exprimée en minutes et non en intentions.

```text
GABARIT DE POLITIQUE D'IDENTITE (exemple fictif, a completer)
1. Perimetre ......... postes publics, Wi-Fi, serveur d'association, site web
   Comptes ........... public (12 postes), employes (4), administration (2),
                       service d'impression (1), publication du site (1)
2. Secrets ........... phrase de passe de 4 mots minimum, unique par service
                       gestionnaire obligatoire pour les comptes nominatifs
                       aucun secret note en clair, aucun partage par messagerie
3. Double authentif ... application de codes pour tous les comptes nominatifs
                       cle physique pour les comptes d'administration
                       codes de secours imprimes et ranges hors ligne
                       revue des facteurs chaque trimestre
4. Droits ............ matrice par compte et par ressource, geree par groupes
                       compte d'administration distinct, jamais utilise au quotidien
                       comptes desactives des qu'une tache disparait
5. Postes publics .... compte local limite, profil reinitialise, mode kiosque
                       verrouillage apres 10 minutes, routine de fin de jour
6. Incident .......... chronometre de reponse en 20 minutes (section Incident)
                       responsable nomme, journalisation conservee 30 jours
   Revision .......... date de prochaine relecture et nom du responsable
```

Trois conditions séparent une politique appliquée d'une politique oubliée : tenir sur une page, nommer un responsable et une date de révision, et résister à une simulation chronométrée. Faites lire la procédure d'incident à l'employé qui ferme la médiathèque, puis chronométrez ensemble une révocation de session sur un compte de test. Ce qui échoue pendant la simulation révèle le point à corriger avant que la situation ne devienne urgente.

- Rassemblez le chapitre dans une page unique, écrite avec vos propres valeurs.
- Décrivez le périmètre, les secrets, la double authentification, les droits, les postes publics et l'incident.
- Nommez un responsable et une date de révision pour chaque rubrique.
- Validez la procédure par une simulation chronométrée plutôt que par une lecture.
- Diffusez la politique à l'ensemble des personnes habilitées, pas seulement à la direction.
- Réunissez dans la même page le registre des comptes de service et la matrice des droits.
$lesson$),
  ('cyb-c2-p13', 'cyb-c2', 13, $lesson$À retenir$lesson$, $lesson$
- L'identification annonce un nom, l'authentification le prouve, l'autorisation décide des droits, la journalisation conserve la trace.
- Un facteur appartient à une famille : savoir, avoir, être, faire ; deux secrets de la même famille ne font pas de double authentification.
- Les règles de composition classiques produisent des gabarits prévisibles que les outils testent en priorité.
- La longueur et l'imprévisibilité comptent davantage que la présence d'un symbole imposé.
- Une phrase de passe de quatre mots tirés au hasard égale un mot de passe aléatoire de huit symboles.
- Un gestionnaire permet un secret différent par service, seule parade réelle au credential stuffing.
- L'entropie se calcule en bits : longueur multipliée par le logarithme base deux de l'alphabet.
- Un secret déjà présent dans les fuites a une entropie pratique proche de zéro, quelle que soit sa longueur.
- Une attaque hors ligne ne rencontre aucune limite de débit : seul le secret résiste, pas le système.
- Un code par message est vulnérable à l'usurpation de carte SIM, un code TOTP à un faux site, une clé FIDO2 résiste au phishing grâce à la liaison au domaine.
- Une demande de validation que vous n'avez pas déclenchée est toujours refusée.
- Le moindre privilège limite chaque compte au strict nécessaire, et l'administration se fait avec un compte distinct.
- Comptes de service et mots de passe d'application ne sont pas des personnes : interdiction de connexion interactive, rotation planifiée, registre daté.
- Un poste public se protège par un compte limité, un mode kiosque, un verrouillage automatique et une routine de fin de jour.
- Une réponse efficace se déroule en vingt minutes : secret changé, sessions révoquées, annexes nettoyées, chronologie écrite.
$lesson$),
  ('cyb-c2-p14', 'cyb-c2', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : croire qu'un mot de passe long est forcément résistant parce qu'il contient un symbole → Correction : estimez son entropie et vérifiez s'il apparaît déjà dans les listes de fuites.
- Piège : obéir aux règles de composition de la même manière que tout le monde → Correction : choisissez des mots tirés au hasard, l'imprévisibilité remplace la complexité subie.
- Piège : faire varier un seul mot de passe d'un site à l'autre → Correction : un secret entièrement différent par service, généré et stocké par le gestionnaire.
- Piège : noter la phrase maîtresse du gestionnaire dans un fichier en clair sur le bureau → Correction : mémorisez-la ou rangez une copie papier hors de l'ordinateur et hors de la messagerie.
- Piège : activer un seul facteur de double authentification sans moyen de secours → Correction : enregistrez un second facteur de nature différente et imprimez les codes de secours.
- Piège : continuer à naviguer et à lire ses courriels avec le compte d'administration → Correction : gardez un compte de travail quotidien et une identité d'administration utilisée à la demande.
- Piège : laisser un mot de passe d'application en clair dans un script sauvegardé → Correction : placez-le dans une variable d'environnement ou un fichier restreint, et recensez-le au registre.
- Piège : compter sur la fermeture de session manuelle sur les postes en libre accès → Correction : verrouillage automatique, profil réinitialisé, routine de fin de jour écrite.
- Piège : changer le mot de passe et considérer l'incident comme clos → Correction : révoquez les sessions, examinez les règles de messagerie et les facteurs enregistrés, consignez la chronologie.
- Piège : écrire une politique de vingt pages que personne ne relira → Correction : une page, un responsable, une date de révision et une simulation chronométrée.
$lesson$),
  ('cyb-c2-p15', 'cyb-c2', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La référence fondatrice reste l'organisme de normalisation américain, dont les directives sur l'authentification ont redéfini les bonnes pratiques en insistant sur la longueur, la vérification des secrets dans les fuites et la modération des renouvellements forcés. Le site https://www.nist.gov/ publie ces documents, dont la série 800-63 consacrée à l'identité numérique : même si le texte est technique, la lecture de ses recommandations sur les mots de passe vaut les explications de ce chapitre et vous donne le vocabulaire officiel utilisé par les professionnels.

Deux ressources complémentaires servent ensuite à l'approfondissement. Le site https://haveibeenpwned.com/ vérifie en quelques secondes si une adresse de courrier électronique apparaît dans les fuites publiques et si un mot de passe a déjà été observé : servez-en lors du nettoyage des comptes de votre établissement, en n'entrant que des adresses dont vous êtes responsable. Le site https://owasp.org/ rassemble les ressources de la communauté qui publie le Top 10 des risques applicatifs, ainsi que ses fiches de recettes sur l'authentification, la gestion des sessions et la vérification des identifiants, exactement les sujets du chapitre sur la sécurité applicative. Conservez ces trois adresses en favori : normalisation, connaissance des fuites et bonnes pratiques de développement.
$lesson$),
  ('cyb-c2-p16', 'cyb-c2', 16, $lesson$Et maintenant : passez à l'exercice et à la pratique$lesson$, $lesson$
Vous avez les fondations : des secrets que l'on peut réellement défendre, un second facteur choisi plutôt que subi, des droits répartis avec méthode et une procédure qui tient en minutes. La suite logique est l'exercice pratique qui suit cette leçon : vous y auditez la politique de mots de passe de la médiathèque, vous réécrivez cinq mots de passe existants en phrases de passe robustes, vous dessinez la matrice de droits des quatre comptes et vous planifiez l'activation de la double authentification, sans regarder la solution. C'est à ce moment que vous mesurerez ce que vous avez réellement retenu de l'entropie, du moindre privilège et de l'ordre des opérations en cas d'incident. Le quiz de quatre questions qui accompagne le chapitre vous permet de vérifier en quelques minutes les notions essentielles.

Profitez-en aussi pour un geste concret immédiat : activez un second facteur sur votre propre messagerie et vérifiez vos adresses dans les fuites publiques pendant que les explications sont encore fraîches. Passé cet exercice, le parcours aborde le réseau défensif, avec pare-feu, chiffrement et VPN. Vous y retrouverez la même logique que dans ce chapitre : fermer ce qui n'est pas utile, n'autoriser que ce qui est nécessaire, et journaliser ce que l'on ne peut pas empêcher, de sorte que la défense reste cohérente d'un chapitre à l'autre.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('cyb-c3-p1', 'cyb-c3', 1, $lesson$Surface d'attaque réseau : ports, services exposés$lesson$, $lesson$
Bienvenue dans le troisième chapitre du parcours Cybersécurité fondamentaux, entièrement consacré au réseau vu du côté défensif. Les deux chapitres précédents vous ont appris à reconnaître les attaquants et leurs vecteurs, puis à protéger les identités et les accès ; nous attaquons aujourd'hui le terrain sur lequel tout cela circule. Un réseau est à la fois la voie de circulation indispensable de votre organisation et le chemin d'approche privilegié de quiconque veut lui faire du tort : c'est par le réseau qu'un fichier malveillant se propage, qu'un mot de passe est capté en clair, qu'un poste oublié devient une porte dérobée vers le serveur comptable. Comprendre ce qui traverse un câble, ce qui est exposé, ce qui est filtré et ce qui est chiffré, c'est apprendre à voir le réseau comme le voit un défenseur : une carte de risques vivante plutôt qu'une simple boîte à internet. Ce chapitre ne suppose aucune connaissance préalable en réseaux : nous partons des notions les plus simples, adresse, port, service, et nous montons jusqu'à la chaîne de confiance TLS et la segmentation en réseaux virtuels.

À la fin de cette leçon, vous saurez lire une règle de pare-feu comme on lit une phrase, identifier la source, la destination, le service et l'action, et en écrire en respectant le bon ordre et la bonne politique. Vous saurez vérifier le chiffrement TLS d'un service en interrogeant le certificat, en lisant la version du protocole et le chiffrement négocié, et en interprétant la chaîne de confiance jusqu'à son issue. Vous saurez distinguer les usages d'un VPN : accès distant pour un agent de télétravail, liaison entre deux sites, ou simple filtre de sortie quand un proxy suffit. Le fil rouge du chapitre est le parc informatique de la Médiathèque des Lilas : postes publics, postes de personnel, catalogue en ligne, imprimante partagée, réseau invités et salle technique. Nous prendrons ce décor à chaque section, parce qu'une règle de pare-feu n'a jamais de sens hors contexte : c'est en décidant pour un lieu réel qu'on apprend à raisonner en sécurité.

Une recommandation avant d'entrer dans le vif du sujet. Les exemples de configuration que vous verrez sont des exemples illustratifs de familles de syntaxe : iptables et sa remplaçante nftables côté Linux, les listes de contrôle d'accès des routeurs Cisco, et quelques pseudo-syntaxes neutres inventées pour expliquer un principe. Ils se lisent et se comprennent, ils ne se copient pas : les mots-clés changent d'un fabricant à l'autre, et une règle recopiée sans réflexion peut ouvrir votre réseau au lieu de le fermer. Avant toute modification en production, testez dans un laboratoire, sauvegardez la configuration en place et prévoyez une marche arrière. Le fil rouge reste le parc de la Médiathèque des Lilas, et le chapitre se termine par un mini-projet : sa politique réseau, que vous rédigerez seul à l'exercice pratique.



Un échange réseau se ramène toujours à une question simple : qui parle à qui, sur quel service, et cette conversation est-elle autorisée ? Pour répondre, deux numéros suffisent. L'adresse IP identifie la machine, comme le numéro d'une maison identifie le bâtiment ; le port identifie le service au sein de cette machine, comme le numéro de l'interphone indique le logement. Les ports vont de zéro à soixante-cinq mille cinq cent trente-cinq, et ils se répartissent entre deux protocoles de transport : TCP, qui garantit que rien n'est perdu ni réordonné, et UDP, qui expédie au plus vite sans promesse de livraison. Quand un logiciel attend des connexions, on dit qu'il écoute sur un port ; c'est cette écoute, et rien d'autre, qui crée un point d'entrée potentiel. Un service qui n'écoute nulle part est invisible : personne ne peut lui parler, donc personne ne peut l'exploiter à distance.

Certaines numérotations sont devenues des conventions universelles : le port vingt-deux pour SSH, cinquante-trois pour les noms de domaine, quatre-vingts pour HTTP, quatre cent quarante-trois pour HTTPS, vingt-cinq pour le courrier, trois mille trois cent quatre-vingt-neuf pour le bureau à distance sous Windows, trois mille six pour MySQL. Retenez pourtant une nuance décisive : le numéro d'un port n'est qu'une convention de registre, pas une garantie de sécurité. Rien n'empêche un logiciel mal conçu d'écouter sur le port quatre cent quarante-trois, et un service parfaitement protégé déplacé sur un port exotique reste exposé s'il est joignable. La sécurité ne vient donc jamais du numéro : elle vient de l'état du logiciel, de la qualité de son authentification et des règles qui l'encadrent.

Depuis l'extérieur, un port se trouve dans l'une de trois états, et les distinguer est la première compétence d'analyse. Un port ouvert répond : un service écoute et accepte la connexion. Un port fermé répond aussi, mais par un refus net : rien n'écoute, la machine est joignable mais le service absent. Un port filtré, lui, ne répond rien du tout : le paquet est jeté en route, et l'observateur ne peut même pas savoir si la machine existe derrière. Cette différence a une portée pratique immédiate. Un filtrage silencieux, dit par abandon, ralentit l'explorateur et ne lui donne aucune information ; un refus explicite, plus courtois pour vos utilisateurs légitimes, confirme à l'attaque qu'une adresse est vivante. Les deux attitudes sont défendables, mais elles doivent être choisies et documentées, jamais subies par défaut.

```text
 Poste public             Pare-feu de la médiathèque          Serveur catalogue
 (VLAN 30)                       |                                |
    |                            |                                |
    |--- SYN, port 22 SSH ------>| Règle 1 : depuis VLAN 30,      |
    |                            | SSH interdit -> ABANDON        |
    |<-- pas de réponse ---------|                                |
    |                            |                                |
    |--- SYN, port 443 HTTPS --->| Règle 2 : depuis VLAN 30,      |
    |                            | 443 vers catalogue -> AUTORISER|
    |                            |--- SYN, port 443 ------------->|
    |                            |<-- SYN-ACK ---------------------|
    |<-- échange TLS poursuivi --|                                |
    |                            |                                |
    |--- SYN, port 3306 MySQL -->| Règle 3 : base de données      |
    |                            | jamais exposée -> ABANDON      |
    |<-- pas de réponse ---------|                                |
```

Le schéma ci-dessus résume le filtrage en trois tentatives : l'une est refusée, l'autre autorisée, la troisième refusée, chacune portée par une règle distincte. Pour décider ainsi de son propre terrain, cartographiez-le avec les mêmes outils qu'un attaquant, mais sur votre périmètre et avec une autorisation écrite.

```text
# Illustration d'une sortie d'outil de cartographie, mise en forme pour la leçon.
# Réseau de la médiathèque, plage 192.168.30.0/24, exécuté depuis le poste
# d'administration avec autorisation du responsable du parc.

192.168.30.10   22/tcp    ouvert    ssh      OpenSSH 9.2 (bannière relevée)
192.168.30.10   443/tcp   ouvert    https    serveur web interne
192.168.30.15   80/tcp    ouvert    http     imprimante - interface d'admin
192.168.30.15   9100/tcp  ouvert    jetdirect impression brute
192.168.30.20   445/tcp   ouvert    smb      partage de fichiers
192.168.30.25   3306/tcp  filtré    mysql    aucune réponse (pare-feu)
192.168.30.40   443/tcp   ouvert    https    poste invité inconnu
```

Lecture de ce relevé : deux services attendus, une imprimante qui expose une interface d'administration en HTTP sur tout le réseau, un partage de fichiers ouvert, une base de données correctement filtrée, et surtout un poste invité inconnu qui parle HTTPS. Ce dernier point illustre la notion de surface d'attaque : l'ensemble des points qu'un attaquant peut tester sans avoir franchi aucun obstacle, chaque port ouvert, chaque service exposé, chaque compte par défaut, chaque interface d'administration accessible depuis un réseau non maîtrisé. Réduire cette surface, ce n'est pas supprimer ce qui est utile, c'est supprimer ce qui ne l'est pas : l'imprimante n'a aucune raison d'être atteignable depuis les postes publics, ni son interface d'administration depuis ailleurs que le réseau du personnel.

La réduction de surface se joue en quelques gestes simples, qui coûtent peu et rapportent beaucoup. Inventoriez le parc, y compris les objets connectés que l'on oublie souvent : imprimantes, bornes, caméras, lecteurs de badges. Désactivez les services que personne n'utilise, fermez les ports inutiles, limitez les interfaces de gestion aux seuls réseaux d'administration, remplacez les mots de passe d'usine et mettez à jour les firmwares. Vérifiez qu'un service interne n'est pas publié par erreur sur l'interface exposée à internet. Une fois ce travail fait, votre carte de surface d'attaque devient courte, lisible et vérifiable, et c'est sur cette base seulement que la section suivante pourra écrire des règles de pare-feu utiles plutôt que décoratives.

- Un port identifie un service, une adresse identifie une machine : toute conversation se ramène à ces deux numéros.
- Un port ouvert répond, un port fermé refuse, un port filtré se tait : ces trois états se lisent différemment.
- Le numéro d'un port est une convention, jamais une garantie de sécurité.
- La surface d'attaque est l'ensemble des points testables sans obstacle : ports, services, comptes par défaut.
- Cartographiez votre propre réseau avec autorisation, puis comparez la carte obtenue au périmètre attendu.
- Chaque objet connecté compte : imprimante, borne, caméra et lecteur de badges ont une adresse IP.
- Réduire la surface d'attaque, c'est fermer ce qui n'est pas utile, pas affaiblir ce qui l'est.
$lesson$),
  ('cyb-c3-p2', 'cyb-c3', 2, $lesson$Pare-feu filtrant : politique, règles, ordre et implicites$lesson$, $lesson$
Le pare-feu est la porte de garde du réseau : il examine chaque paquet qui franchit une frontière et décide de le laisser passer ou de le retenir, en s'appuyant sur un ensemble de règles. Le pare-feu d'hôte protège une seule machine et décide ce qu'elle accepte d'écouter et vers quoi elle peut émettre ; le pare-feu de réseau, matériel ou logiciel, protège un périmètre entier, placé devant les serveurs, entre deux réseaux internes ou à la sortie vers internet. On utilise souvent les deux, parce qu'ils ne répondent pas à la même question : l'un empêche un intrus de se propager depuis un poste contaminé, l'autre empêche un service compromis d'être atteint de l'extérieur. C'est la défense en profondeur : une seule erreur ne suffit plus à tout compromettre.

Avant d'écrire la moindre règle, il faut une politique, et c'est le point sur lequel la plupart des installations échouent. Une politique de filtrage est un document court : quelles zones existent, quels flux sont nécessaires au travail, lesquels sont interdits, qui décide des exceptions et à quelle fréquence elle est relue. Elle repose sur deux formules : filtrer par défaut ce qui n'est pas explicitement autorisé, et n'autoriser que le nécessaire, chaque ouverture justifiée par un besoin identifiable. On parle de moindre privilège : un poste de prêt n'a pas besoin d'atteindre le serveur de messagerie, un poste invité pas le catalogue interne. Une règle sans justification écrite est une dette : dans six mois, plus personne ne saura pourquoi elle existe, et tout le monde aura peur de la supprimer.

Une règle se lit comme une phrase, et sa grammaire tient en cinq éléments. La direction indique si l'on examine un paquet entrant ou sortant. La source désigne l'adresse ou le réseau d'origine, la destination l'adresse visée, éventuellement complétée par le port, et le service précise le protocole de transport et son numéro. L'action décide du sort du paquet : accepter, abandonner silencieusement, ou refuser avec un message d'erreur. Une sixième pièce facultative mais précieuse est la journalisation, qui décide si l'événement est noté. Abandonner et refuser méritent d'être assumés : refuser répond immédiatement à l'émetteur, confortable pour l'utilisateur légitime mais qui confirme l'existence d'un service ; abandonner ne répond rien, plus discret mais qui peut faire patienter longtemps un logiciel légitime.

```text
EXEMPLE ILLUSTRATIF - ordre d'évaluation d'un jeu de règles, syntaxe neutre.
Rappel : l'ordre change le résultat, et le premier accord conclu gagne.

RÈGLE 1 | source : 192.168.30.0/24 (postes publics) | vers : 192.168.30.20:445 | ACTION : ABANDON
RÈGLE 2 | source : 192.168.30.10                    | vers : 192.168.30.20:445 | ACTION : AUTORISER
RÈGLE 3 | source : n'importe quelle adresse         | vers : 192.168.30.20:445 | ACTION : ABANDON
RÈGLE 4 | source : 192.168.30.0/24                  | vers : 192.168.30.99:443  | ACTION : AUTORISER
POLITIQUE IMPLICITE | toute autre correspondance                              | ACTION : ABANDON
```

Observez ce qui se passe quand l'ordre est modifié. Si la règle 1 est placée avant la règle 2, le serveur de fichiers refuse le serveur d'impression qui possède l'adresse .10 : le premier accord conclu l'emporte et la règle 2 n'est jamais consultée. Si la règle 3, très générale, arrive en tête, elle avale tout le trafic vers le port 445. Cette mécanique explique deux habitudes : placer les règles les plus spécifiques avant les plus générales, et relire un jeu de règles en cherchant la première règle qui s'applique à un paquet donné. Un test simple : prenez un trafic exemple, un poste du réseau invités qui veut joindre le serveur de catalogue, et faites-le cheminer dans l'ordre jusqu'à la première correspondance.

Il existe toujours, en fin de jeu de règles, une règle qu'on ne voit pas : la politique par défaut, appliquée à tout paquet qu'aucune règle précédente n'a traité. Une politique permissive laisse passer tout ce que rien n'a refusé, ce qui transforme chaque oubli en faille ; une politique restrictive bloque tout ce que rien n'a autorisé, ce qui transforme chaque oubli en incident visible et réparable. L'indice est simple : si vous devez inventer des règles de refus sans fin, votre politique est permissive. Inversez-la, écrivez les autorisations nécessaires, et le reste est couvert par la règle implicite. Certaines familles l'affichent en toutes lettres, par exemple le mot clé deny à la fin d'une liste nommée ; d'autres la laissent implicite.

Une deuxième mécanisme change radicalement le nombre de règles à écrire : le filtrage étatique. Un pare-feu étatique mémorise les connexions en cours et retient qu'une réponse appartient à une requête déjà autorisée : quand un poste ouvre une connexion vers le catalogue sur le port quatre cent quarante-trois, les paquets de retour passent sans règle supplémentaire. On écrit alors une règle unique pour autoriser la connexion et ses retours, au lieu de dupliquer chaque sens. L'écueil classique arrive quand l'état est désactivé ou quand deux pare-feux du chemin appliquent des vues différentes : le trafic de retour est bloqué, l'application semble tomber en panne, et l'on perd des heures à chercher une faute d'application qui est en réalité une règle asymétrique.

La journalisation est la dernière pièce, souvent négligée à tort. Noter les refus permet de repérer un poste qui tente de joindre un service interne, une imprimante qui appelle un serveur inconnu ou un scannage qui traverse le périmètre ; noter les autorisations rares fait apparaître un flux que personne n'avait prévu. Deux précautions s'imposent : limiter le bruit, sinon vous accumulez des lignes identiques jusqu'à saturer le disque, et prévoir qui lit les journaux et quand, car un journal que personne ne consulte ne protège personne. Une règle sans journalisation reste une décision prise dans le noir ; nous reverrons l'exploitation de ces traces dans le chapitre sur la détection et la réponse.

```table
| Règle | Source | Destination et service | Action | Justification |
| --- | --- | --- | --- | --- |
| 1 | Poste de administration | Serveur de catalogue:22 | Autoriser | Maintenance à distance du personnel |
| 2 | Postes publics | Serveur de catalogue:443 | Autoriser | Consultation du catalogue par les usagers |
| 3 | Réseau invités | Serveur de catalogue:443 | Abandon | Accès web public uniquement, pas d'accès interne |
| 4 | Tous les réseaux internes | Serveur de base de données:3306 | Abandon | Service jamais joignable depuis les postes |
| 5 | N'importe quelle source | Interface d'administration des imprimantes:80 | Abandon | Gestion réservée au réseau du personnel |
| 6 | N'importe quelle source | Tout le reste | Abandon | Politique par défaut restrictive |
```

Ce tableau constitue le premier jet de la politique de la médiathèque : six règles seulement, mais qui couvrent l'essentiel, parce qu'elles sont nées d'un inventaire des besoins et non d'un catalogue de possibilités. Notez l'absence volontaire de règles très larges : aucune ligne n'autorise n'importe quelle source vers n'importe quelle destination. C'est cette rigueur qui vous rendra service le jour où un poste public sera compromis : le champ d'action de l'intrus sera borné par les quelques autorisations dont il dispose.

- Écrivez d'abord la politique, puis les règles : des règles sans politique deviennent rapidement contradictoires.
- Une règle se lit en cinq temps : direction, source, destination, service, action.
- Les règles les plus spécifiques passent avant les règles les plus générales, car le premier accord conclu gagne.
- La politique par défaut, permissive ou restrictive, décide du sort de tout ce qu'aucune règle n'a traité.
- Le filtrage étatique autorise les retours des connexions déjà ouvertes, ce qui allège le jeu de règles.
- Abandonner éteint la connexion sans bruit, refuser répond et révèle : choisissez en connaissance de cause.
- Journalisez les refus et les autorisations rares, avec limitation de bruit, et prévoyez qui les relit.
$lesson$),
  ('cyb-c3-p3', 'cyb-c3', 3, $lesson$Exemples de règles commentées$lesson$, $lesson$
Avant toute chose, une mise en garde qui vaut pour toute cette section. Les trois blocs qui suivent sont des exemples illustratifs de familles de syntaxe : iptables et sa remplaçante nftables, et les listes de contrôle d'accès des routeurs Cisco. Ils servent à lire la logique d'une règle, source, destination, service, action et ordre, rien d'autre. Ne les recopiez jamais tels quels : les mots-clés, les options et les effets de bord varient selon le fabricant, la version et la distribution, et une commande exécutée à la mauvaise place peut verrouiller l'accès à votre machine ou ouvrir un service que vous croyiez fermé. Pratiquez sur un laboratoire, lisez la documentation de votre produit et conservez une voie de retour, par exemple une session locale ouverte en parallèle d'une modification à distance. Les adresses utilisées appartiennent aux plages privées réservées à la documentation : elles sont fictives.

```bash
# EXEMPLE ILLUSTRATIF - famille iptables (pare-feu historique de Linux).
# Ceci est un artefact pédagogique à adapter, pas une commande à copier
# sur un serveur réel sans revue ni test préalable.

# 1. La boucle locale n'est jamais filtrée : les processus parlent entre eux.
iptables -A INPUT -i lo -j ACCEPT

# 2. Les réponses des connexions que j'ai moi-même ouvertes sont admises,
#    ainsi que les flux associés à une connexion déjà acceptée.
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 3. SSH n'est ouvert que depuis le réseau du personnel, pas depuis internet.
iptables -A INPUT -p tcp --dport 22 -s 192.168.10.0/24 -j ACCEPT

# 4. Le trafic web vers la machine elle-même est admis.
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 5. Une tentative vers la base de données est abandonnée et journalisée.
iptables -A INPUT -p tcp --dport 3306 -j LOG --log-prefix "REFUS-MYSQL "

# 6. La politique par défaut de la chaîne entrante devient restrictive.
iptables -P INPUT DROP
```

Lisez ce jeu de règles comme une phrase par numéro. La première admet la boucle de retour locale, indispensable au fonctionnement interne des logiciels. La deuxième admet les connexions déjà autorisées et les flux associés : c'est le filtrage étatique vu à la section précédente, résumé en une ligne. La troisième ouvre SSH depuis la seule plage du personnel, ce qui illustre le filtrage par source : depuis internet, la même tentative n'atteindra jamais la règle suivante. La quatrième ouvre le service web public. La cinquième journalise puis abandonne tout essai vers la base de données, et la dernière bascule la politique par défaut de la chaîne en restrictive. L'ordre est donc cohérent : spécifique avant général, exceptions avant politique implicite.

```bash
# EXEMPLE ILLUSTRATIF - famille nftables, successeur moderne d'iptables.
# Même logique, autre vocabulaire : tables, chaînes, règles, politique.
# À adapter impérativement à votre distribution et à votre noyau.

table inet filtre {
  chain entree {
    type filter hook input priority 0; policy drop;

    iif "lo" accept
    ct state established, related accept

    ip saddr 192.168.10.0/24 tcp dport 22 accept
    tcp dport 443 accept

    tcp dport 3306 log prefix "REFUS-MYSQL " limit rate 5/minute
  }

  chain sortie {
    type filter hook output priority 0; policy accept;
    # Politique permissive en sortie : le parc est à confiance modérée,
    # mais un poste compromis pourrait alors exfiltrer des données.
  }
}
```

Cette version montre deux différences de fond avec la précédente. La première est la politique déclarée en tête de chaîne : ici, entrée restrictive, sortie permissive. Elle dispense de la ligne finale mais impose de comprendre où elle s'écrit, parce qu'elle décide du sort de tout ce qu'aucune règle n'a rattrapé. La seconde tient à la chaîne de sortie : laisser le trafic sortant libre convient à un poste de travail, mais sur un serveur sensible on préférera une sortie restrictive. Notez enfin la limitation de fréquence du journal, qui empêche une attaque par saturation de remplir le disque en quelques minutes.

```text
! EXEMPLE ILLUSTRATIF - famille ACL des routeurs Cisco IOS.
! Syntaxe présentée pour sa logique, jamais pour être saisie sans adaptation.

ip access-list standard BUREAU-STAFF
 permit 192.168.10.0 0.0.0.255
 deny   any
!
ip access-list extended VERS-SERVEURS
 permit tcp 192.168.10.0 0.0.0.255 host 192.168.30.10 eq 443
 permit tcp 192.168.20.0 0.0.0.255 host 192.168.30.10 eq 443
 deny   ip any any log
!
interface Vlan30
 description Serveurs du catalogue
 ip access-group VERS-SERVEURS in
```

Trois leçons se dégagent de cette famille. La première tient aux masques : une liste standard compare une adresse source avec un masque inversé, écrit 0.0.0.255 pour désigner vingt-cinq-six adresses contiguës ; confondre ce masque avec le masque de sous-réseau est l'erreur la plus fréquente des débutants. La seconde tient à l'attachement : une liste n'a aucun effet tant qu'elle n'est pas rattachée à une interface et à un sens, entrant ou sortant. La troisième tient au refus final : une liste nommée se termine par un refus implicite qu'il est bon d'écrire en toutes lettres, avec journalisation, pour que l'intention soit visible par qui relira la configuration. Les familles de syntaxe diffèrent, les cinq éléments de la phrase restent identiques partout.

- Ne recopiez jamais un exemple de syntaxe sur un équipement réel : les familles diffèrent, adaptez et testez.
- Lisez une règle comme une phrase, dans l'ordre où le paquet la rencontre.
- Politique par défaut restrictive en entrée, décisions de sortie assumées et documentées.
- Le masque inversé des listes Cisco n'est pas le masque de sous-réseau : c'est la faute la plus fréquente.
- Une liste non rattachée à une interface et à un sens ne filtre rien.
- Datez, annotez et faites relire chaque règle ; sauvegardez avant, testez pendant, consignez après.
$lesson$),
  ('cyb-c3-p4', 'cyb-c3', 4, $lesson$Segmentation : VLAN et DMZ à la médiathèque$lesson$, $lesson$
Imaginez le parc de la Médiathèque des Lilas constitué d'un seul grand réseau plat : postes publics, postes du personnel, serveurs, imprimantes, caméras et bornes Wi-Fi partagent la même plage d'adresses et la même diffusion de paquets. Un seul poste public compromis suffit alors pour joindre le serveur de catalogue, l'imprimante et le bureau du directeur, sans rencontrer le moindre obstacle : le pare-feu a beau être parfaitement réglé sur l'entrée d'internet, il ne voit rien de ce qui se passe à l'intérieur. C'est la faiblesse structurelle du réseau plat, qui fait de la segmentation le second pilier du réseau défensif après le pare-feu : découper le réseau en zones indépendantes, pour qu'une compromission localisée ne se propage pas librement.

Le premier outil de segmentation est le VLAN, pour réseau local virtuel. Un commutateur compatible attribue à chaque port une étiquette, et les paquets qui portent cette étiquette ne circulent qu'entre les ports du même groupe, même s'ils sont câblés sur le même boîtier : le découpage est donc logique. Les machines d'un VLAN ne voient pas celles des autres, sauf si un routeur ou un pare-feu les relie explicitement, et la diffusion de paquets reste confinée dans chaque VLAN. Attention à une nuance décisive : un VLAN est une séparation de trafic, pas une barrière de sécurité absolue ; un commutateur mal configuré ou un lien non étiqueté peuvent rétablir la communication. La règle d'or est simple : si le trafic doit être bloqué, c'est le pare-feu inter-vlan qui doit le bloquer, jamais l'absence de règle.

La DMZ, ou zone démilitarisée, répond à un besoin différent : héberger des services destinés au public sans mettre en danger le réseau interne. Elle se situe entre internet et le réseau privé, derrière un pare-feu qui règle les deux flancs séparément. Les serveurs qui y vivent, site web, serveur de courrier, passerelle de dépôt, sont atteignables de l'extérieur, mais le pare-feu limite strictement ce qu'ils peuvent émettre vers l'intérieur : un serveur public compromis doit pouvoir servir ses clients, pas interroger votre base de données ou vos postes. Pour une médiathèque, la DMZ est l'endroit naturel du catalogue en ligne : visible par tous, sans droit vers les réseaux internes.

```text
                        Internet
                           |
                     [ Pare-feu principal ]
              (règles entre chaque zone : refus par défaut)
                           |
        -------------------+-------------------------
        |                   |                       |
   [ DMZ - VLAN 50 ]   [ Interne - routeur        |
   |                 |   inter-vlan / pare-feu ]   |
   | serveur         |        |          |         |
   | catalogue 443   |   [VLAN 10]   [VLAN 20]     |
   |                 |   personnel   postes de     |
   |                 |   + admin     travail       |
   |                 |        |          |         |
   -------------------   [VLAN 30]   [VLAN 40]     |
                         postes     invités Wi-Fi  |
                         publics    (sortie        |
                                    internet seule)|
                                                   |
```

Le schéma met en évidence deux décisions distinctes : l'accès d'internet vers la DMZ, autorisé sur le seul port quatre cent quarante-trois, et les accès entre zones internes, qui ne sont pas automatiques mais réglés une par une sur l'équipement qui les relie. Chaque besoin exprimé en phrase devient une règle, et l'ensemble constitue la matrice de communication entre zones, résumée dans le tableau suivant.

```table
| Zone | VLAN | Usagers | Ce qui est autorisé | Ce qui est refusé |
| --- | --- | --- | --- | --- |
| Administration | 10 | Équipe technique | Postes, serveurs, imprimantes, gestion | Accès direct à internet non nécessaire |
| Postes de travail | 20 | Personnel d'accueil | Catalogue interne, imprimer, courrier | Postes publics, réseau invités |
| Postes publics | 30 | Usagers sur place | Catalogue public en HTTPS | Tout le reste du réseau interne |
| Invités Wi-Fi | 40 | Visiteurs avec bornes | Internet uniquement, via le pare-feu | Toute adresse privée interne |
| DMZ | 50 | Usagers d'internet | Service public sur 443 | Vers tous les réseaux internes |
```

Ce tableau est un extrait de la matrice que vous rédigerez dans le mini-projet : il tient sur une page et il se vérifie par essai, en tentant depuis un poste du VLAN concerné une communication interdite et en cherchant la trace du refus. La segmentation apporte aussi des bénéfices sans rapport avec la sécurité : la diffusion reste locale, les adresses sont attribuées par zone, la supervision devient lisible, et l'on sait de quelle zone vient un incident. Les contreparties sont un coût matériel, des commutateurs gérés et un plan d'adressage tenu à jour ; dans un petit établissement, on commence souvent par deux ou trois zones plutôt que par six, pour garder une configuration tenable.

- Un réseau plat transforme une compromission locale en incident général : segmentez avant de raffiner les règles.
- Le VLAN découpe le trafic logiquement ; c'est le pare-feu inter-vlan qui garantit réellement le refus.
- La DMZ accueille les services publics sans leur donner accès au réseau interne.
- La matrice de communication entre zones se rédige en phrases simples, puis se traduit en règles.
- La segmentation se vérifie par essai : tentez la communication interdite et recherchez la trace du refus.
- Commencez par peu de zones bien maîtrisées plutôt que par beaucoup de zones mal reliées.
$lesson$),
  ('cyb-c3-p5', 'cyb-c3', 5, $lesson$Le TLS : certificats, chaîne de confiance et TLS 1.3$lesson$, $lesson$
Tout ce que nous avons vu jusqu'ici décide si un paquet circule ou non ; une question commence à peine : une fois le paquet admis, quelqu'un peut-il le lire ou le modifier en route ? C'est le problème que résout le chiffrement, dont le protocole de référence s'appelle TLS, pour sécurité de la couche transport. TLS s'intercale entre le transport et l'application : votre navigateur parle HTTP, mais cette conversation est emballée dans une enveloppe chiffrée que seul le serveur destinataire sait ouvrir. Le serveur et le port restent les mêmes, mais les octets qui circulent ne portent plus de texte lisible, ni d'identifiant, ni de mot de passe. TLS répond donc à deux exigences : le secret, personne d'autre ne lit, et l'intégrité, personne ne peut modifier sans que cela se voie.

Le protocole assemble trois outils cryptographiques complémentaires. Le chiffrement symétrique, reposant sur des algorithmes comme AES en mode authentifié ou ChaCha20 accompagné de Poly1305, chiffre vite de grands volumes avec une clé unique partagée. Le chiffrement asymétrique, fondé sur une paire de clés publique et privée, sert à échanger cette clé secrète et à signer des informations sans jamais la transmettre. Enfin, les fonctions de hachage, comme SHA-256, résument un contenu en une empreinte sensible au moindre changement et vérifient qu'aucun octet n'a été altéré. L'essentiel tient en une formule : TLS chiffre de manière authentifiée, c'est-à-dire qu'il protège contre l'écoute, la falsification et l'usurpation de l'identité du serveur.

Comment un client sait-il à qui il parle ? Par le certificat, et c'est ici que l'analogie document d'identité devient précise. Un certificat est un fichier signé qui contient le nom du site, sa clé publique, la durée de validité, un numéro de série, l'autorité qui l'a émis, et surtout une liste de noms auxquels il s'applique, appelée SAN pour sujet alternatif. C'est cette liste qui compte : si vous allez sur le catalogue d'une médiathèque et que le certificat ne mentionne pas ce nom, le navigateur doit refuser, quelle que soit la beauté du reste. Le certificat ne prouve pas qu'un site est honnête : il prouve qu'une autorité reconnue a vérifié le contrôle du nom de domaine et l'appartenance de la clé publique.

La chaîne de confiance relie ce certificat à votre appareil. Le certificat que le serveur présente est généralement délivré par une autorité intermédiaire, elle-même certifiée par une autorité racine dont le certificat est préinstallé dans votre système ou votre navigateur. Pour valider, le client remonte la chaîne jusqu'à une racine qu'il connaît déjà, vérifie chaque signature, contrôle les dates et le nom demandé ; toute signature invalide, chaîne incomplète ou date dépassée fait afficher l'avertissement. Si une organisation inspecte le trafic chiffré, son propre certificat n'est accepté que si sa racine a été installée sur les postes, ce qui se fait en entreprise mais pas chez un usager. L'existence d'intermédiaires n'est pas un détail : elle permet de renouveler les clés sans remplacer les racines du monde entier.

```text
Établissement d'une connexion TLS 1.3 - vue simplifiée du dialogue

 Client                                              Serveur
   |                                                     |
   | 1. Bonjour, je parle TLS 1.3, voici le nom demandé  |
   |---------------------------------------------------->|
   |                                                     |
   | 2. Bonjour, voici mon certificat et ma signature     |
   |    (négociation des algorithmes, clé éphémère)       |
   |<----------------------------------------------------|
   |                                                     |
   | 3. Je vérifie la chaîne, les dates et le nom ;       |
   |    je calcule puis j'envoie la clé de session        |
   |    protégée par la clé publique du serveur           |
   |---------------------------------------------------->|
   |                                                     |
   | 4. Accusé de réception dérivé de la clé de session   |
   |<----------------------------------------------------|
   |                                                     |
   | 5. Conversation HTTP chiffrée de bout en bout        |
   |<===================================================>|
```

La version 1.3 du protocole, publiée en 2018 et aujourd'hui attendue par défaut, mérite une place à part : elle a retiré les algorithmes vieillissants, imposé un échange de clés éphémères dit à parfaite confidentialité persistante, ce qui signifie que la clé de session n'est réutilisable pour personne même si la clé privée du serveur était volée plus tard, et réduit le dialogue d'établissement à un aller-retour. Un cas limite subsiste, la réutilisation des premières données : la phase qui suit la négociation peut emporter une requête envoyée avant la confirmation complète, ce qui l'expose à un rejeu ; les implémentations modernes limitent cet usage aux requêtes idempotentes. Deux habitudes complètent le tableau : refuser les versions 1.0 et 1.1, et exiger le 1.3 ou, à défaut, un 1.2 récent avec échange de clés éphémère.

- TLS chiffre les échanges, authentifie le serveur et détecte toute altération en transit.
- Le chiffrement symétrique protège le contenu, l'asymétrique sert à échanger les clés et à signer.
- Le certificat associe un nom de domaine à une clé publique, sous la responsabilité d'une autorité.
- La chaîne de confiance remonte du certificat présenté jusqu'à une racine préinstallée sur l'appareil.
- C'est la liste des noms du certificat qui fait foi, pas la simple présence d'un cadenas.
- TLS 1.3 impose l'échange de clés éphémères, supprime les algorithmes obsolètes et gagne un aller-retour.
- Un certificat expiré bloque les usagers : le renouvellement automatique n'est pas une option de confort.
$lesson$),
  ('cyb-c3-p6', 'cyb-c3', 6, $lesson$Vérifier un certificat et le chiffrement pas à pas$lesson$, $lesson$
Le cadenas du navigateur vous donne un verdict, pas un raisonnement. Pour vérifier un service comme le responsable technique de la médiathèque doit le faire, il faut répondre à quatre questions : quel certificat est présenté, qui l'a signé, jusqu'à quand est-il valable, et quelle version du protocole avec quel chiffrement a été négociée ? La réponse se obtient en deux minutes avec OpenSSL, une boîte à outils de référence présente sur la plupart des machines. La commande ci-dessous ouvre une connexion au service, demande son certificat et affiche le détail de la négociation. Considérez-la comme un examen clinique : vous ne changez rien, vous observez, vous notez.

```bash
# EXEMPLE ILLUSTRATIF - examen d'un service TLS avec OpenSSL.
# www.example.com est un nom réservé à la documentation : remplacez-le
# par le nom du service que vous contrôlez réellement.
# La commande reste la même sur Linux, macOS et sous Windows depuis un
# environnement qui fournit openssl ; seuls les retours à la ligne varient.

openssl s_client -connect www.example.com:443 -servername www.example.com
```

L'option de connexion donne l'adresse et le port, l'option de nom permet d'envoyer le nom demandé pendant la négociation, ce qui est indispensable quand'un même serveur héberge plusieurs sites : sans lui, le serveur ne sait pas quel certificat présenter et renvoie souvent un certificat par défaut, source de faux espoirs. La sortie est longue, mais trois blocs suffisent. Le premier décrit le protocole et le chiffrement retenus. Le deuxième donne le résultat de validation de la chaîne, noté par un code numérique accompagné d'une phrase. Le troisième déroule le certificat et les certificats des autorités intermédiaires.

```text
# Exemple de sortie mise en forme pour la leçon (valeurs illustratives).
# Recherchez d'abord le protocole et le chiffrement :
Protocol   : TLSv1.3
Cipher     : TLS_AES_256_GCM_SHA384

# Recherchez ensuite le verdict de validation de la chaîne :
Verify return code: 0 (ok)

# Puis l'identité et la période de validité du certificat présenté :
subject=CN = www.example.com
issuer  = C = US, O = Let's Encrypt, CN = R3
notBefore = Sep 12 00:00:00 2026 GMT
notAfter  = Dec 11 23:59:59 2026 GMT
```

Trois lectures découlent de ces lignes. Le protocole annoncé doit être 1.3, ou à défaut une version 1.2 récente ; un retour en 1.1 ou pire signale un serveur négligé. Le chiffrement annoncé doit être un mode authentifié moderne, gcm ou chacha20 ; les modes historiques de type cbc appartiennent au passé. Le code de retour zéro signifie que la chaîne complète a été vérifiée jusqu'à une racine de confiance ; toute autre valeur appelle un examen, et il ne faut jamais s'habituer à cliquer à travers un avertissement. Vérifiez enfin les dates : un certificat qui expire dans trois jours est un incident en préparation.

Pour aller au-delà de l'en-tête, on interroge le certificat lui-même. Les commandes suivantes extraient le sujet, l'émetteur, les dates et la liste des noms couverts, exactement les éléments qu'un auditeur vous demandera de produire. L'important est de contrôler la liste des noms : un certificat valide pour un autre domaine ne protège pas le vôtre, et un certificat qui couvre le nom court mais pas le nom complet avec sous-domaine produira des avertissements sur une partie du service.

```bash
# EXEMPLE ILLUSTRATIF - extraire les champs utiles d'un certificat.
# Deux approches complémentaires, à adapter selon votre installation.

# 1. Lire directement le certificat que le serveur vient de présenter.
openssl s_client -connect www.example.com:443 -servername www.example.com \
  2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName

# 2. Examiner un fichier de certificat déjà récupéré sur disque.
openssl x509 -in certificat.pem -noout -text
```

La vérification manuelle a une limite : elle examine un instantané d'un serveur et ne teste ni la robustesse de la configuration, ni la qualité de la chaîne complète. Un service d'analyse en ligne fait alors gagner un temps considérable, dont le plus connu est celui de Qualys, à l'adresse https://ssllabs.com. Vous y soumettez un nom de domaine, et l'outil rend une note accompagnée d'un détail lisible : protocoles acceptés, versions refusées, caractéristiques de l'échange de clés, validité de la chaîne. Ce qui compte davantage que la note est la liste des points corrigés d'un passage au suivant. Ce test évalue la configuration du transport, pas la sécurité de l'application derrière.

La plupart des certificats gratuits sont aujourd'hui délivrés par Let's Encrypt, une autorité de certification dont la spécification, appelée ACME, automatise toute la démarche : le service prouve que vous contrôlez le nom de domaine par un défi, émet le certificat, puis le renouvelle automatiquement. La validité est de quatre-vingt-dix jours, ce qui limite la durée d'exposition d'une clé compromise et impose un renouvellement périodique. L'outil le plus répandu pour piloter ce cycle s'appelle certbot, et la séquence ci-dessous en montre le principe.

```bash
# EXEMPLE ILLUSTRATIF - cycle de vie d'un certificat avec certbot et
# Let's Encrypt. Les options dépendent du serveur web utilisé : lisez la
# documentation de votre propre installation avant d'exécuter quoi que ce soit.

# Obtenir un certificat pour un nom de domaine que vous maîtrisez.
sudo certbot --nginx -d www.example.com

# Vérifier que le renouvellement automatique fonctionne réellement.
sudo certbot renew --dry-run

# Consigner la date d'expiration dans votre suivi mensuel.
# (commande de lecture, sans modification de configuration)
```

La ligne la plus importante de ce bloc n'est pas la première, c'est la deuxième : obtenir un certificat est facile, prouver que le renouvellement fonctionnera dans quatre-vingt-dix jours est le vrai travail. Un test périodique associé à une alerte sur les dates d'expiration vous épargnera l'incident le plus courant : un site qui affiche un avertissement de certificat expiré à tous ses usagers un lundi matin. Notez enfin dans votre procédure la date de la dernière vérification, le chiffrement constaté, la date d'expiration et le responsable du suivi.

- Répondez à quatre questions : quel certificat, par qui signé, jusqu'à quand, avec quel chiffrement.
- Le verdict de validation vaut zéro pour une chaîne complète ; toute autre valeur exige un examen.
- Contrôlez la liste des noms couverts, la date de fin et le niveau de chiffrement annoncé.
- Un outil d'analyse en ligne évalue la configuration globale, pas seulement l'instantané d'un serveur.
- Let's Encrypt délivre gratuitement des certificats automatisés, valables quatre-vingt-dix jours.
- Testez le renouvellement avant qu'il ne devienne urgent, et suivez les dates dans un registre.
$lesson$),
  ('cyb-c3-p7', 'cyb-c3', 7, $lesson$HTTP et HTTPS : ce que TLS protège (et ne protège pas)$lesson$, $lesson$
HTTP et HTTPS ne sont pas deux protocoles concurrents : HTTPS est HTTP à l'intérieur de TLS, la seule différence étant l'enveloppe. Ce que l'on appelle sécurité en transit recouvre une promesse précise, et la première compétence consiste à savoir ce qu'elle couvre. TLS garantit trois choses. La confidentialité : un observateur sur le chemin voit des octets illisibles, pas les URLs consultées, ni les formulaires, ni les contenus. L'intégrité : toute modification en route casse la vérification de l'enveloppe et coupe la conversation. L'authentification du serveur : si la chaîne de confiance est valide, vous parlez bien au détenteur du nom de domaine. Sans ces trois piliers, il n'y a pas de HTTPS digne de ce nom, et c'est ce que le cadenas du navigateur résume en une icône.

```text
# Comparaison de ce qui est visible depuis le réseau, valeurs illustratives.

# HTTP - le réseau voit tout, en clair
GET /compte/membre HTTP/1.1
Host: catalogue.mediatheque.local
Cookie: session=abc123
X-Identifiant: numero-de-lecture-4871

# HTTPS - le réseau ne voit que l'enveloppe
17 03 03 01 A4          <- longueur du paquet suivant
2E 9F 4B 11 7C 8A ...   <- fragments chiffrés, illisibles
(voir aussi : adresse IP de destination, port 443, dates, tailles)
```

Cette comparaison appelle la liste de ce que TLS ne protège pas, et elle est plus longue qu'on ne le croit. Le contenu reste lisible par le serveur, ses journaux et ses sauvegardes. Un certificat valide ne prouve pas la bonne foi : un site de fraude peut obtenir un certificat pour son propre nom, et le cadenas ne signifie alors que le nom affiché est bien celui visité. Le poste de l'utilisateur n'est pas protégé non plus : un logiciel espion lira le mot de passe au moment où il est tapé. Enfin, TLS ne répare pas une application vulnérable : injection de requêtes, scripts injectés, défaut de protection des formulaires transitent parfaitement dans un tunnel chiffré, et c'est à la famille OWASP, consultable sur https://owasp.org, qu'il revient de répondre.

Un deuxième ensemble de limites porte sur les métadonnées, ces informations qui accompagnent la conversation sans en faire partie. Le paquet IP révèle l'adresse du serveur visité, le port révèle le type de service, la taille et le rythme des paquets permettent souvent de deviner la nature de l'échange, et le nom demandé pendant la négociation indique le domaine ciblé. Les requêtes de résolution de noms, elles, restent à l'extérieur de TLS tant qu'elles ne sont pas protégées par un mécanisme dédié. TLS protège donc le contenu de la conversation, pas le fait qu'elle ait lieu ni avec qui : une promesse d'anonymat complet fondée sur le seul HTTPS serait mensongère.

Reste la question de la rétrogradation. Un attaquant qui se place sur le chemin peut tenter de vous servir la page en HTTP, en espérant que le navigateur accepte et que l'usager ne remarque pas l'absence de cadenas. Deux parades existent. La première consiste à rediriger systématiquement toute requête non chiffrée vers l'adresse chiffrée. La seconde, l'en-tête HSTS, déclare que le navigateur ne doit jamais accepter la version non chiffrée pour une durée donnée, y compris si l'attaquant essaie de la proposer. Tant que la redirection n'est pas en place, il faut aussi proscrire le contenu mixte, ces pages qui chargent une partie de leurs ressources en HTTP depuis une page HTTPS.

```table
| Ce que TLS garantit | Ce que TLS ne garantit pas |
| --- | --- |
| Le contenu de la conversation est lisible par le destinataire seul | Le serveur ne conserve ni ne revend aucun journal |
| Aucune modification en route ne passe inaperçue | L'application derrière le chiffrement est exempte de failles |
| Le serveur correspond bien au nom de domaine affiché | Le site est honnête, légal ou compétent |
| Le navigateur refuse une chaîne de confiance invalide | L'adresse IP visitée, les tailles et les rythmes restent visibles |
| Les mots de passe ne circulent plus en clair sur le réseau | Le poste de l'utilisateur n'est pas infecté |
```

- HTTPS est HTTP enveloppé dans TLS : la différence tient à l'enveloppe, pas aux requêtes.
- TLS garantit le secret, l'intégrité et l'identité du serveur, sous réserve d'une chaîne valide.
- Un certificat valide prouve le contrôle d'un nom, jamais l'honnêteté du site.
- Les métadonnées, adresses, tailles, rythmes et noms de domaine, restent visibles.
- Une application vulnérable reste vulnérable à l'intérieur d'un tunnel parfaitement chiffré.
- Redirigez tout le HTTP vers le HTTPS et activez HSTS pour fermer la porte à la rétrogradation.
$lesson$),
  ('cyb-c3-p8', 'cyb-c3', 8, $lesson$Le VPN : tunnel, chiffrement et usages légitimes$lesson$, $lesson$
Un VPN, ou réseau privé virtuel, répond à une situation très simple : des personnes ou des sites doivent partager un réseau privé alors que le chemin qui les sépare leur est étranger, l'internet public en tête. Plutôt que de câbler un lien dédié, on creuse un tunnel dans le réseau existant : les paquets du réseau privé sont emballés dans des enveloppes nouvelles, acheminés sur l'infrastructure publique, puis déballés à l'arrivée. L'usager voit un réseau local ; le transporteur du milieu ne voit que des paquets chiffrés dont il ne comprend ni la destination réelle ni le contenu. Ce décalage entre ce que l'on croit voir et ce que le réseau voit est la définition du virtuel dans réseau privé virtuel.

Un tunnel ne vaut que par quatre mécanismes qui fonctionnent ensemble : l'encapsulation met les paquets d'origine dans une nouvelle trame, le chiffrement rend le contenu illisible à quiconque observe le chemin, l'intégrité garantit qu'aucune pièce n'a été modifiée pendant le trajet, souvent par une empreinte calculée à chaque paquet, et l'authentification des extrémités prouve que l'autre bout est bien celui que l'on prétend être. C'est ce dernier point qui distingue un vrai tunnel d'une simple promesse de confidentialité. Les familles de protocoles qui implémentent ces mécanismes sont multiples, par exemple IPsec accompagné de son échange de clés, OpenVPN construit sur TLS, ou WireGuard plus récent et plus concis : nous les citons comme des familles à explorer, pas comme des choix à trancher aveuglément, car leur déploiement dépend du matériel et des compétences disponibles.

```text
                  Réseau privé de la médiathèque
 Poste du personnel                                 Serveur interne
 (chez lui, réseau familial)                        (192.168.10.25)
        |                                                   |
        |  paquet interne vers 192.168.10.25                |
        |                                                   |
        v                                                   |
 [ client VPN ] -- tunnel chiffré et authentifié ------- [ passerelle VPN ]
        |             (vue de l'extérieur :                 |
        |              un unique flux chiffré)              |
        |                                                   |
        +----> routeur domestique --> internet --> [ pare-feu de la médiathèque ]
                                                    (autorise le tunnel,
                                                     puis filtre à l'intérieur)
```

Les usages légitimes tiennent tous dans la même idée : étendre un service privé jusqu'à une personne autorisée, sans étendre le réseau privé jusqu'à tout le monde. Un agent de la médiathèque qui travaille chez lui doit atteindre l'outil de gestion des prêts, inaccessible depuis internet ; le tunnel lui donne cet accès sans exposer l'outil au monde entier. Deux établissements d'un même réseau de bibliothèques peuvent relier leurs réseaux pour partager un catalogue commun, et un administrateur qui intervient depuis son domicile peut emprunter le tunnel plutôt qu'ouvrir SSH sur internet. Dans tous les cas, le VPN est un moyen d'accès contrôlé, pas une fin en soi : quel besoin précis ce tunnel satisfait-il, et qui doit pouvoir l'utiliser ?

L'authentification du tunnel mérite une attention particulière : c'est le point où l'usager rencontre la sécurité. Les implémentations sérieuses combinent un facteur que l'on possède, comme un certificat installé sur le poste, et un facteur que l'on sait, comme un mot de passe robuste, souvent accompagné d'un troisième transmis par une application. Exiger une double authentification pour un accès qui ouvre le réseau interne est un réflexe à prendre dès le départ, et limiter chaque compte aux seules ressources dont il a besoin évite qu'un identifiant volé ne devienne une passe-partout. Reste à choisir entre le tunnel complet, où tout le trafic du poste passe par l'organisation, et le tunnel partiel, où seuls les paquets destinés au réseau privé empruntent le tunnel : le premier supervise davantage, le second est plus léger mais laisse le reste du trafic hors de votre visibilité.

Il faut enfin connaître les limites, pour ne pas vendre au VPN une protection qu'il n'apporte pas. Un VPN ne rend pas anonyme : le fournisseur du tunnel voit les échanges, et le site visité voit toujours votre adresse de sortie. Il ne protège pas le poste : un logiciel malveillant continue de fonctionner à l'intérieur du tunnel et pourra alors atteindre le réseau privé directement. Il transfère une part de responsabilité à l'équipement qui termine le tunnel, devenu une cible de choix, et il ajoute une dépendance : quand le tunnel tombe, le travail s'arrête, ce qui impose de documenter une procédure de secours.

- Un VPN creuse un tunnel authentifié, chiffré et vérifié dans un réseau qui ne vous appartient pas.
- Encapsulation, chiffrement, intégrité et authentification des extrémités forment un tout indivisible.
- Chaque usager du tunnel reçoit l'accès le plus restreint compatible avec sa mission.
- Un VPN ne rend pas anonyme, ne nettoie pas un poste infecté et dépend d'un équipement devenu critique.
$lesson$),
  ('cyb-c3-p9', 'cyb-c3', 9, $lesson$VPN d'accès distant, VPN site-à-site et proxy : trois réponses différentes$lesson$, $lesson$
Le VPN d'accès distant concerne des individus et non des lieux. Chaque poste installe un client qui établit une session avec une passerelle, l'usager s'authentifie, et le réseau privé s'étend jusqu'à lui. C'est la solution du télétravail, de l'administration à distance et de la mobilité. Ses forces sont la souplesse et la granularité : chaque compte peut recevoir ses propres autorisations. Ses contraintes sont la gestion des postes que l'on ne maîtrise pas entièrement, la nécessité d'une double authentification, et la charge de maintenance des comptes, des certificats et des journaux de connexion. Dans la médiathèque, ce dispositif correspond exactement au besoin de l'équipe qui consulte l'outil de gestion depuis chez elle.

Le VPN site-à-site relie des réseaux et non des personnes. Deux passerelles, une dans chaque site, établissent un tunnel permanent ou sur demande, et les machines des deux côtés se parlent comme si elles partageaient le même bâtiment. Aucun client n'est installé sur les postes, ce qui simplifie le quotidien des usagers, mais la configuration appartient tout entière à l'équipe technique, qui doit gérer les plages d'adresses sans chevauchement, le routage, la politique de filtrage à chaque extrémité et le suivi des certificats d'équipement. C'est la solution choisie pour relier une médiathèque annexe au réseau principal, ou pour interconnecter plusieurs établissements d'un même réseau.

Le proxy n'appartient pas à la même famille : il s'interpose dans une conversation déjà en cours, reçoit la requête, la reformule au nom du client, puis renvoie la réponse. Un proxy de niveau application comprend les requêtes web : il peut filtrer par nom de site, mettre en cache des pages, anonymiser partiellement la source ou servir de routeur de sortie contrôlé. Il n'offre pas l'accès à l'ensemble des services d'un réseau, ne crée pas de tunnel chiffré et ne chiffre pas la conversation tant que le protocole de départ n'est pas lui-même chiffré. Un proxy inverse, lui, se place devant les serveurs pour terminer les connexions entrantes ou répartir la charge : il protège le serveur, pas les postes.

```table
Critère | VPN d'accès distant | VPN site-à-site | Proxy
| --- | --- | --- | --- |
| Ce qui se connecte | Une personne, un poste | Deux réseaux entiers | Une requête, un client applicatif
| Où vit la configuration | Client installé et compte utilisateur | Passerelles dédiées | Réglage applicatif ou navigateur
| Authentification | Identifiant, certificat, double authentification | Certificats d'équipement, clés partagées | Aucune, ou authentification d'usager |
| Périmètre couvert | Ressources autorisées pour ce compte | Tout le périmètre convenu entre les sites | Principalement le web, selon les règles
| Chiffrement | Oui, de bout en bout dans le tunnel | Oui, entre les passerelles | Pas par lui-même, sauf si le trafic est déjà chiffré
| Cas typique | Télétravail, intervention à distance | Raccordement d'une annexe, réseau d'établissements | Filage, mise en cache, contrôle de sortie
| Attention | Poste distant mal protégé, comptes à gérer | Chevauchement d'adresses, routage à maintenir | Ne résout ni l'écoute ni l'usurpation
```

Pour la Médiathèque des Lilas, l'arbitrage se fait en trois questions. D'abord, qui doit se connecter : des personnes qui se déplacent, ce qui impose un accès distant, ou des bâtiments qui dialoguent, ce qui impose un lien site-à-site ? Ensuite, quelle surface est acceptable : quelques comptes nominaux et journalisés, ou une interconnexion où tout poste d'un site peut joindre tout poste de l'autre ? Enfin, quel problème résout-on réellement : étendre le réseau, ou seulement contrôler et accélérer la sortie vers internet, auquel cas un proxy reste plus léger et plus lisible. Répondez à ces trois questions par écrit avant d'ouvrir un devis, et le choix s'imposera presque toujours de lui-même.

- Choisissez l'outil à partir du besoin écrit, jamais l'inverse.
- L'accès distant relie des personnes et impose des comptes nominatifs avec double authentification.
- Le lien site-à-site relie des réseaux et transfère la charge vers la planification d'adresses.
- Le proxy interpose un service sur des requêtes existantes : il filtre et met en cache, il ne chiffre pas par lui-même.
- Documentez la décision, ses alternatives écartées et la raison de l'écart : ce document vaut preuve.
$lesson$),
  ('cyb-c3-p10', 'cyb-c3', 10, $lesson$Menaces réseau courantes : interception, DNS piégé et Wi-Fi ouvert$lesson$, $lesson$
L'interception, ou attaque de l'homme du milieu, consiste à se placer silencieusement entre deux interlocuteurs qui croient parler ensemble. Sur un réseau local, la technique la plus courante repose sur la résolution d'adresses : l'attaquant diffuse des messages qui associent son adresse physique à l'adresse de la passerelle, et les postes, qui font confiance à ces annonces, lui envoient désormais tout leur trafic. Une variante attaque le service d'adressage automatique : un faux serveur distribue aux postes une passerelle et un serveur de noms qu'il contrôle, et tous les échanges partent dans la mauvaise direction sans qu'aucun symptôme n'apparaisse. Une troisième variante, fréquente en Wi-Fi, consiste à ouvrir un point d'accès au nom séduisant, puis à faire le relais entre les victimes et internet.

```text
 Schéma d'une interception et d'un nom de domaine piégé, valeurs illustratives

  Poste de la médiathèque        Attaquant sur le même réseau        Vrai serveur
        |                                   |                              |
        | 1. faux message d'adressage :     |                              |
        |    « je suis la passerelle »       |                              |
        |---------------------------------->                              |
        |                                   |                              |
        | 2. « www.banque.example, c'est moi »                              |
        |<----------------------------------|                              |
        |                                   |                              |
        | 3. connexion chiffrée vers le      | faux site, certificat        |
        |    serveur piégé                   | d'un autre nom               |
        |----------------------------------> X                            |
        |                                   |                              |
        | 4. si le navigateur compare le nom demandé au certificat,        |
        |    l'attaque s'arrête ici : l'avertissement apparaît.            |
```

Le nom de domaine piégé mérite d'être détaillé, parce qu'il touche à une couche que l'on oublie souvent : la traduction des noms en adresses. Un attaquant peut falsifier une réponse de résolution, corrompre un cache intermédiaire, modifier le fichier local d'associations ou délivrer un serveur de noms par le faux service d'adressage. La conséquence est toujours la même : votre machine se rend à la mauvaise adresse, et si le site frauduleux possède un certificat valide pour son propre nom, le cadenas s'affiche malgré tout. Les parades sont complémentaires : faire valider les réponses signées ajoute une vérification cryptographique à la résolution, chiffrer la résolution réduit les écoutes, conserver des associations statiques pour les services critiques évite la dépendance, et surveiller les changements de serveur de noms repère l'anomalie.

Le Wi-Fi ouvert, enfin, offre à l'attaquant une position de choix : il est physiquement présent, il observe tout ce qui circule, et il peut injecter des trames. Les risques concrets sont l'écoute des conversations non chiffrées, le détournement de session lorsque des identifiants circulent en clair, l'abus du portail de connexion captif, et l'interception des publicités de présence qui permettent de reconstituer la liste des appareils présents. À cela s'ajoute une contrainte propre aux lieux ouverts : le réseau accueille des gens dont vous ne contrôlez pas les machines. La parade n'est donc jamais technique seule : elle combine chiffrement exigeant, isolation, limitation du périmètre et clarté affichée aux usagers.

- Une interception modifie le chemin ou la résolution, elle ne casse pas le chiffrement.
- De faux messages d'adressage redirigent tout un réseau vers un attaquant présent sur place.
- Un nom de domaine piégé envoie l'usager au mauvais endroit, parfois avec un cadenas valide.
- Faites valider les réponses signées, chiffrez la résolution et gardez des entrées statiques pour l'essentiel.
- Un réseau ouvert est un réseau peuplé d'inconnus : chiffrez, isolez, limitez et affichez les règles.
$lesson$),
  ('cyb-c3-p11', 'cyb-c3', 11, $lesson$Le Wi-Fi de la médiathèque : WPA3 et réseau invités isolé$lesson$, $lesson$
Le Wi-Fi d'un lieu public part d'un désavantage structurel : les ondes franchissent les murs, et la passphrase, même robuste, doit être connue de tous ceux qui la saisissent. Le premier réflexe consiste donc à séparer deux populations. Le réseau du personnel reçoit une configuration exigeante, réservée aux appareils du parc, avec une phrase secrète connue des seuls agents et changée à chaque départ notable. Le réseau invités, lui, est pensé pour être partagé sans être dangereux : son danger n'est pas l'usager malveillant, c'est l'usager ordinaire dont l'appareil pourrait être infecté sans qu'il le sache.

Le chiffrement de ces réseaux doit reposer sur la génération WPA3, qui remplace la négociation ancienne par un échange résistant aux attaques par dictionnaire hors ligne : même capturé, le trafic ne permet plus de tester des milliers de phrases secrètes sans le détecter. Lorsque des appareils très anciens persistent, on autorise une période de transition où les deux générations coexistent, en notant dans le registre la date de fin prévue. Pour le réseau du personnel, l'idéal va plus loin avec une authentification centralisée, où chaque appareil reçoit ses propres identifiants au lieu de partager une phrase secrète commune : plus de phrase à diffuser, plus d'accès à révoquer en masse lors d'un départ, mais un serveur d'authentification à mettre en place.

L'isolement du réseau invités est la pièce maîtresse, et il se joue sur plusieurs plans à la fois. Au niveau du réseau, les postes invités sont placés dans une zone dédiée dont la seule sortie autorisée est internet ; toute tentative vers une adresse privée est abandonnée au pare-feu. Au niveau du point d'accès, l'isolement des clients empêche deux visiteurs de se parler directement, ce qui bloque l'écoute entre pairs. Au niveau du service, un portail de connexion attribue un accès à durée limitée, enregistre le début de session et coupe à l'échéance. S'y ajoutent des mesures de confort utiles à la sécurité : limitation de débit, résolution de noms orientée vers un service fiable, et conservation des journaux limitée dans le temps, parce qu'une trace conservée sans raison est un risque et une charge.

```text
# Arrêté de la politique Wi-Fi - version abrégée pour la leçon.
# Chaque ligne deviendra un réglage vérifiable, pas une intention vague.

RÉSEAU-PERSONNEL | WPA3, phrase secrète à 12 caractères minimum, connue des agents
  isolement       | les postes du personnel se voient entre eux
  sortie          | catalogue interne, imprimente, messagerie

RÉSEAU-INVITES   | WPA3 avec période de transition tant que nécessaire
  portail         | code valable 4 heures, renouvelable à l'accueil
  isolement       | aucun poste invité ne voit un autre poste invité
  sortie          | internet seul, refus de toute adresse privée
  limitation      | débit encadré, aucune ressource interne atteignable
```

Quelques habitudes complètent la configuration. Désactivez les facilités qui ouvrent une porte dérobée, comme l'association rapide au contact ou la gestion à distance des points d'accès depuis internet. Tenez une liste des points d'accès autorisés : un boîtier inconnu émettant un nom proche du vôtre est un signal d'alerte, et la vigilance face aux réseaux aux noms presque identiques doit être expliquée aux agents. Ne réutilisez jamais la phrase secrète du réseau pour un compte d'administration. Enfin, vérifiez par essai : connectez-vous en tant qu'invité, tentez d'atteindre un poste interne, ouvrez une adresse privée, contrôlez que la coupure se fait bien à la date prévue. Une configuration Wi-Fi qui n'a jamais été éprouvée par un visiteur réel n'est qu'une hypothèse.

- Séparez le réseau du personnel du réseau invités : populations, chiffrement et périmètres diffèrent.
- WPA3 résiste aux attaques par dictionnaire hors ligne ; la période de transition se date et se surveille.
- L'isolement des clients invités se vérifie en essayant d'atteindre un autre appareil du même réseau.
- Un portail à durée limitée réduit le temps de présence et rend les accès traçables et révocables.
- Désactivez les raccourcis d'association et la gestion à distance inutile, tenez la liste des points d'accès.
$lesson$),
  ('cyb-c3-p12', 'cyb-c3', 12, $lesson$Mini-projet guidé : la politique réseau de la médiathèque$lesson$, $lesson$
Il est temps d'assembler toutes les pièces dans un livrable unique : la politique réseau de la Médiathèque des Lilas, un document d'une dizaine de pages qui permet à une nouvelle personne arrivée demain de comprendre le réseau, de le vérifier et de le défendre. Ce projet mobilise chacune des sections précédentes : inventaire de surface d'attaque, zones et matrice de communication, jeu de règles justifiées, procédure de vérification TLS, décision d'accès distant argumentée et politique Wi-Fi des invités. Le fil conducteur reste le même depuis le début : rien n'est écrit sans justification, sans responsable, ni sans moyen de vérification.

Commencez par l'inventaire, qui conditionne tout le reste. Listez les zones, les adresses, les services réellement utilisés et les personnes responsables de chacun. Ce travail fastidieux est celui qui fait gagner le plus de temps ensuite : impossible d'écrire une règle pertinente quand on ignore ce qui tourne. Une fois l'inventaire posé, écrivez la matrice de communication entre zones sous forme de phrases, puis traduisez chaque phrase en règle, en conservant le numéro de la justification qui l'a fait naître.

```text
# EXEMPLE ILLUSTRATIF de format de règle commentée, syntaxe neutre.
# Reprenez ce format dans votre document, avec vos propres valeurs.

REGLE 03
  QUAND     : un poste du réseau invités tente d'atteindre 192.168.10.0/24
  ALORS     : abandon du paquet, journalisation du refus
  JUSTIFIER : la matrice n'autorise aucun accès interne depuis les invités
  VERIFIER  : depuis un poste invité, l'adresse du catalogue interne ne répond pas
  DEMANDER  : direction technique, revue semestrielle
```

Ensuite, traitez le chiffrement avec la procédure complète apprise à la section correspondante : ouvrez la connexion TLS du service public, notez la version et le chiffrement, relevez le verdict de validation, extrayez la liste des noms couverts et la date d'expiration, faites passer le service par l'analyse en ligne, puis écrivez la date de la prochaine vérification et le responsable du suivi. Terminez par le test de renouvellement, parce qu'un certificat expiré faute de renouvellement annule tout le travail précédent pour l'usager. Vos constatations se notent dans le document, en clair, avec des dates : c'est cette traçabilité qui transforme une vérification ponctuelle en contrôle périodique.

La décision d'accès distant se rédige de la même manière : d'abord le besoin, identifié par des personnes et des ressources, puis les options envisagées, puis le choix et ses raisons, enfin les mesures d'accompagnement, double authentification, comptes nominatifs, journalisation et révocation à chaque départ. Si vous optez pour un lien site-à-site, ajoutez le plan d'adresses et les flux autorisés entre les deux sites. Si vous optez pour un simple filtre de sortie, écrivez ce que la solution ne protège pas, pour éviter qu'elle ne soit prise à tort pour un tunnel sécurisé.

Le volet Wi-Fi se termine par des réglages vérifiables plutôt que par des intentions : nom du réseau, génération de chiffrement, mode de portail, durée d'accès, isolement confirmé par un essai, limitation de débit et critère d'alerte sur un point d'accès inconnu. Prévoyez enfin la revue : qui relit le document, à quelle fréquence, quel événement déclenche une mise à jour, et où se trouve la version en vigueur. Un document non versionné n'est plus une politique, c'est un souvenir.

```text
# SQUELETTE DU DOCUMENT - à compléter chapitre par chapitre.

1. En-tête            version, date d'approbation, responsable, prochaine revue
2. Inventaire          zones, adresses, services, responsables, objets connectés
3. Matrice             phrases de besoins entre chaque zone
4. Règles              format commenté, justification, moyen de vérification
5. Chiffrement         procédure, résultats, dates, prochaine vérification
6. Accès distant       besoin, options, choix, raisons, accompagnement
7. Wi-Fi               réglages, isolement, portail, alertes
8. Revue               qui, quand, déclencheurs, archivage des versions
```

La dernière étape est le contrôle mutuel. Relisez le document en cherchant les phrases qui contiendraient un mot vague, comme si nécessaire ou selon les besoins, et remplacez-les par un nom, une adresse et une date. Vérifiez que chaque règle possède une ligne de vérification exécutable. Essayez ensuite, depuis un poste public, les trois communications interdites les plus importantes, et consignez le résultat : ce que vous n'avez pas pu tester est un risque, ce que vous avez pu tester est un savoir. Ce document est exactement ce que vous remettrez à l'exercice pratique de cette leçon.

- Rassemblez le chapitre dans un livrable unique : inventaire, matrice, règles, chiffrement, accès, Wi-Fi, revue.
- Chaque règle porte sa justification, son responsable et son moyen de vérification.
- Argumentez le choix d'accès distant en écrivant aussi les options écartées et leurs raisons.
- Versionnez le document, fixez sa revue et remplacez chaque adverbe flou par un fait précis.
$lesson$),
  ('cyb-c3-p13', 'cyb-c3', 13, $lesson$À retenir$lesson$, $lesson$
- La surface d'attaque est l'ensemble des points testables sans obstacle : chaque port ouvert en fait partie. Un port ouvert répond, un port fermé refuse, un port filtré se tait ; le numéro n'a jamais protégé personne.
- Une politique de filtrage précède les règles : filtrer par défaut, n'autoriser que le nécessaire.
- Une règle se lit en cinq temps, direction, source, destination, service, action, et le premier accord conclu gagne ; la politique par défaut tranche le reste.
- Le filtrage étatique reconnaît les réponses d'une connexion déjà autorisée et allège le jeu de règles.
- Les exemples de syntaxe sont illustratifs : ils se lisent, s'adaptent et se testent, jamais ne se copient.
- Un VLAN découpe le trafic, la DMZ héberge les services publics ; c'est le pare-feu inter-vlan qui bloque réellement les communications interdites.
- TLS protège le secret, l'intégrité et l'identité du serveur ; c'est la liste des noms couverts du certificat qui fait foi.
- TLS 1.3 impose l'échange de clés éphémères, retire les algorithmes obsolètes et gagne un aller-retour.
- Ce que TLS ne protège pas est plus long que la liste de ce qu'il protège : métadonnées, serveur, poste, application.
- Un VPN authentifie et chiffre un tunnel ; il ne rend pas anonyme et ne répare pas un poste infecté. Accès distant, site-à-site et proxy répondent à trois questions : personne, réseau, requête.
- Le Wi-Fi invités se protège par le chiffrement, l'isolement des clients, le portail temporaire et la limitation.
$lesson$),
  ('cyb-c3-p14', 'cyb-c3', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : ouvrir un port parce que le numéro correspond au service attendu → Correction : justifiez chaque ouverture par un besoin et vérifiez l'état réel du port par un essai.
- Piège : écrire les règles sans politique, puis empiler des exceptions contradictoires → Correction : rédigez d'abord les zones et la matrice de communication, traduisez ensuite.
- Piège : placer une règle générale de refus avant une règle précise d'autorisation → Correction : hiérarchisez du spécifique vers le général, car le premier accord conclu gagne.
- Piège : oublier la politique par défaut et croire que le pare-feu filtre tout → Correction : écrivez la valeur explicite de la politique par défaut et reliez-la à un journal.
- Piège : déployer un exemple de syntaxe copié sur un équipement de production → Correction : adaptez dans un laboratoire, sauvegardez, testez, puis déployez avec une marche arrière.
- Piège : segmenter en VLAN sans pare-feu inter-vlan, ce qui laisse les zones naturellement reliées → Correction : ajoutez l'équipement de filtrage entre zones et testez les communications interdites.
- Piège : vérifier le cadenas sans regarder les dates ni la liste des noms du certificat → Correction : relevez protocole, chiffrement, verdict de chaîne, noms couverts et expiration.
- Piège : obtenir un certificat automatisé sans jamais tester son renouvellement → Correction : exécutez un renouvellement d'essai et posez une alerte sur la date d'expiration.
- Piège : donner la même phrase secrète au réseau du personnel et au réseau invités → Correction : deux réseaux, deux niveaux d'exigence, et un isolement vérifié par un essai réel.
$lesson$),
  ('cyb-c3-p15', 'cyb-c3', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La référence la plus directe pour approfondir le chiffrement reste la documentation officielle d'OpenSSL, disponible sur https://openssl.org, qui décrit chaque option de commande et chaque champ de certificat avec une précision que les tutoriels n'atteignent généralement pas. Complétez-la par le service d'analyse de https://ssllabs.com : faites passer vos propres services dans la grille d'évaluation, puis lisez le détail des points faibles plutôt que la note, parce que c'est la liste des correctifs qui vous fera progresser. Pour le cycle de vie des certificats, https://letsencrypt.org explique la démarche automatisée et la validité courte, avec une documentation destinée autant aux administrateurs qu'aux développeurs.

Du côté applicatif, https://owasp.org rassemble les recommandations qui manquent au chiffrement : contrôle des entrées, protection des sessions, gestion des formulaires, journaux d'erreurs. Vous y retrouverez le fameux Top 10, qui décrit les failles qui transitaient très bien à l'intérieur d'un tunnel parfaitement chiffré. Une dernière piste, moins technique mais décisive : recopiez votre politique réseau à la main, réécrivez-la avec vos propres mots, puis présentez-la à un collègue qui vous demandera pourquoi chaque ligne existe. Les questions qu'il vous posera révèleront les zones encore floues de votre compréhension.
$lesson$),
  ('cyb-c3-p16', 'cyb-c3', 16, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
Vous disposez maintenant des trois leviers du réseau défensif : fermer ce qui n'est pas utile avec le pare-feu et la segmentation, chiffrer ce qui doit l'être avec TLS et ses certificats, et relier ce qui doit l'être avec des tunnels dont vous connaissez désormais les usages et les limites. La suite logique est l'exercice pratique qui suit cette leçon : vous y rédigerez seul la politique réseau complète de la médiathèque, avec vos règles justifiées, votre procédure de vérification TLS, votre arbitrage d'accès distant et votre politique Wi-Fi, puis vous vous corrigerez à l'aide des listes de contrôle des sections précédentes. Le quiz de quatre questions qui accompagne le chapitre vous permet en parallèle de vérifier les notions essentielles en quelques minutes.

Passé cet exercice, le parcours bascule sur le durcissement d'un système : le réseau bien filtré ne sert à rien si la machine qui vit derrière reste à jour, mal configurée ou ouverte à tous. Vous verrez alors que les réflexes acquis ici, justifier, vérifier, documenter, se retrouvent à l'identique sur un poste ou un serveur, parce que la méthode est la même et seuls changent le périmètre et les commandes. Conservez donc la politique que vous allez produire : elle deviendra le document de référence que vous mettrez à jour à chaque événement, et elle vous servira de gabarit pour écrire celui d'un autre établissement.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('cyb-c4-p1', 'cyb-c4', 1, $lesson$Pourquoi un système par défaut est vulnérable$lesson$, $lesson$
Bienvenue dans le quatrième chapitre du parcours Cybersécurité, un chapitre entièrement consacré au durcissement d'un système, c'est-à-dire à l'ensemble des gestes qui rendent une machine moins fragile une fois qu'elle est installée, branchée au réseau et confiée à des usagers. Jusqu'ici, vous avez appris ce qu'est une vulnérabilité, comment lire une annonce de sécurité et pourquoi certaines failles se propagent si vite. Ce chapitre fait le pas suivant : il vous apprend à agir sur votre propre parc, poste par poste, service par service, journal par journal. Le fil rouge du parcours reste en place : le parc informatique de la Médiathèque des Lilas, une petite structure tout à fait ordinaire avec ses contraintes ordinaires, douze postes publics consultables sans réservation, deux postes de staff derrière le comptoir, un serveur qui héberge le catalogue en ligne et l'imprimante partagée du rez-de-chaussée. Rien d'exotique : c'est exactement le genre d'environnement que vous rencontrerez en poste, et c'est sur lui que vous appliquerez chaque étape de ce chapitre.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées sur des exemples réels. Vous comprendrez pourquoi un système livré par le fabricant est vulnérable par défaut, et vous saurez traduire une annonce de CVE en décision de priorité à l'aide du score CVSS. Vous dresserez l'inventaire complet de ce qui tourne réellement sur un poste ou un serveur, puis vous désactiverez les services inutiles sans rien casser. Vous réduirez les privilèges : comptes nominatifs, groupe des administrateurs, étendue de sudo et droits fichiers POSIX, avec le tableau des permissions rwx sous les yeux. Vous vous appuierez sur des guides de référence publiés par des organismes reconnus plutôt que sur des listes de recettes anonymes, vous chiffrerez le disque et les sauvegardes locales, puis vous installerez une journalisation exploitable : quels journaux, où les stocker, combien de temps les conserver. Vous appànerez à lire ces journaux pour y détecter des connexions répétées, des fichiers modifiés et des comptes créés, à centraliser les journaux avec un horodatage fiable, et à suivre une procédure de réponse en six étapes face à un signalement de malware. Le tout sera assemblé dans un mini-projet guidé : la fiche de durcissement du poste d'accueil de la médiathèque.

Une recommandation sur la manière d'aborder ce chapitre, avant d'entrer dans le vif du sujet. Le durcissement s'apprend comme on apprend un métier de la main : en le pratiquant sur une machine que vous pouvez vous permettre de casser, jamais directement sur la production. Si vous n'avez pas encore de machine de test, une machine virtuelle ou un vieil ordinateur suffisent largement : installez-y une distribution Debian ou Ubuntu, appliquez les commandes de la leçon, redémarrez, et observez ce qui casse. Une session qui ne se connecte plus après un changement dans sudo est une leçon bien plus durable qu'une page de documentation relue d'un bout à l'autre. Les commandes de cette leçon sont illustrées sous Debian ou Ubuntu, une famille de distributions très répandue en collectivité ; les noms de paquets, les chemins de configuration et les outils peuvent différer sur Red Hat, sur SUSE ou sur un système BSD, et il vous faudra les traduire. Nous avancerons par étapes, en alternant explications, extraits de journaux commentés et bonnes pratiques de terrain. Après la leçon, vous rédigerez seul la fiche de durcissement complète du poste d'accueil, puis vous vérifierez vos acquis avec le quiz de quatre questions.



Lorsqu'un poste sort de sa boîte, ou lorsqu'une distribution serveur vient d'être installée, la machine n'est ni bonne ni mauvaise : elle est simplement réglée pour être utile au plus grand nombre dans le plus grand nombre de situations. Or servir tout le monde signifie, concrètement, ouvrir un maximum de fonctionnalités, activer un maximum de services, accepter un maximum de protocoles et laisser les comptes d'administration avec leurs mots de passe d'usine. Le fabricant ne peut pas deviner que ce poste servira uniquement à consulter un catalogue de bibliothèque : il livre donc un système prêt à imprimer, prêt à partager des fichiers, prêt à recevoir des connexions distantes, prêt à se mettre à jour depuis n'importe quel dépôt. Chacune de ces capacités est utile à quelqu'un, et inutile à votre poste d'accueil. Le résultat est un écart permanent entre ce que la machine sait faire et ce dont votre usage a besoin, et cet écart constitue la première porte d'entrée d'un attaquant.

La notion de surface d'attaque sert à mesurer cet écart. Elle désigne l'ensemble des points par lesquels quelqu'un peut tenter d'entrer dans un système : ports réseau à l'écoute, services accessibles, comptes utilisables, logiciels installés, périphériques acceptés, fichiers modifiables. Plus cette surface est grande, plus l'attaquant a de prises, et plus il lui faudra peu de choses pour trouver une ouverture. Un poste qui n'écoute sur aucun port réseau est excessivement difficile à atteindre à distance ; le même poste qui exécute quatre services en écoute, dont un vieil outil de partage jamais mis à jour, devient une cible de choix. Le durcissement consiste précisément à rogner cette surface : supprimer ce qui est inutile, refermer ce qui doit l'être, restreindre ce qui reste.

Cette logique est d'autant plus pertinente dans une médiathèque que les menaces qui visent ce type de structure ne ressemblent pas à celles d'un film d'espionnage. Dans la pratique, la majorité des compromissions viennent de robots qui balayent des plages d'adresses à grande vitesse, à la recherche de mots de passe par défaut, de services obsolètes ou de failles publiées depuis plusieurs semaines. Ces robots ne savent pas que votre poste est le poste d'accueil de la Médiathèque des Lilas : ils testent tout, systématiquement, et repartent dès qu'ils ne trouvent rien. D'autres viennent d'une clé USB trouvée dans le hall, d'un logiciel téléchargé pour convertir un fichier, d'un lien de courriel cliqué par un membre du personnel. La question n'est donc pas de savoir si quelqu'un essaiera, mais combien de fois par jour, et si ces tentatives laissent des traces que vous pourrez lire.

Trois propriétés structurent le raisonnement de sécurité que vous utiliserez tout au long du chapitre. La confidentialité, d'abord, garantit que l'information reste lisible par les seules personnes autorisées : un fichier d'adhésion n'est pas un catalogue public. L'intégrité, ensuite, garantit que l'information n'est pas modifiée sans que personne ne s'en aperçoive : une date d'atelier changée par un inconnu est un problème de confiance autant qu'un problème technique. La disponibilité, enfin, garantit que le service fonctionne quand on en a besoin : un catalogue inaccessible pendant trois jours est déjà un incident de sécurité, même sans aucune donnée volée. Ces trois propriétés, souvent réunies sous le nom d'objectif triptyque, vous serviront de balance pour arbitrer chaque décision de durcissement, parce que tout réglage est un compromis et qu'aucun réglage n'est gratuit.

Enfin, une mise au point sur ce que le durcissement n'est pas. Il ne remplace ni le bon sens ni la maintenance : un système durci et jamais mis à jour reste vulnérable, et un système à jour mais ouvert à tout venant reste exposé. Le durcissement non plus ne vise pas l'excellence absolue, il vise la réduction raisonnable du risque avec les moyens disponibles. Une médiathèque ne peut pas consacrer vingt heures par semaine à la sécurité de douze postes ; elle peut en consacrer deux, de manière régulière, si ces deux heures sont les bonnes. Voici, résumée en une image, la pile de durcissement que ce chapitre va construire, couche par couche, depuis la base jusqu'au sommet.

```text
              pile de durcissement — du sol au sommet

   4.  [ surveillance ]   journaux centralisés, alertes, relectures
   3.  [ détection ]      recherches récurrentes dans les journaux
   2.  [ durcissement ]   comptes, droits, services, configuration
   1.  [ mise à jour ]    correctifs appliqués puis vérifiés
   0.  [ inventaire ]     ce qui tourne, ce qui écoute, qui a les droits
   ----------------------------------------------------------
       le système tel que le fabricant l'a livré
```

Chaque couche s'appuie sur celle du dessous : sans inventaire, vous ne savez pas quoi mettre à jour ; sans mise à jour, le durcissement masque des failles connues ; sans durcissement, les journaux enregistrent trop de bruit ; sans journalisation, vous ne détectez rien ; sans détection, la surveillance n'est qu'un disque qui se remplit. C'est pourquoi nous suivrons l'ordre du bas vers le haut dans toute la leçon, et c'est aussi la façon dont vous procéderez dans le mini-projet, qui reprendra exactement cette séquence.
$lesson$),
  ('cyb-c4-p2', 'cyb-c4', 2, $lesson$Gestion des mises à jour et correctifs$lesson$, $lesson$
La première couche, et de loin la plus rentable, consiste à appliquer les mises à jour de sécurité. Un correctif est une modification du code d'un logiciel publiée par son éditeur pour fermer une faille déjà identifiée. Le rythme des attaques automatisées est tel qu'un intervalle de plusieurs semaines entre la publication d'un correctif et son installation suffit souvent à voir apparaître des scans ciblant précisément la faille corrigée. Dans une petite structure, cette fenêtre est le principal facteur de risque : ce n'est pas l'absence de pare-feu coûteux qui fait perdre un poste, c'est le correctif repoussé trois mois parce que personne n'a eu le temps.

Sous Debian ou Ubuntu, le mécanisme de base est celui des gestionnaires de paquets. Une mise à jour de paquet corrige généralement un défaut de fonctionnement, tandis qu'une mise à niveau peut changer la version majeure d'un logiciel et introduire des incompatibilités. Les annonces de sécurité portent une référence propre : sous Debian, chaque annonce critique est publiée sous la forme d'un bulletin signé que vous retrouverez sur le site officiel debian.org, avec la version corrigée et, souvent, un identifiant CVE. Pour votre poste d'accueil, la consigne pratique tient en deux gestes : récupérer la liste des mises à jour disponibles, puis les appliquer à une heure où une interruption est acceptable, en prévoyant un redémarrage si le noyau lui-même a été touché.

```text
$ sudo apt update
Hit:1 http://deb.debian.org/debian bookworm InRelease
Get:2 http://security.debian.org/debian-security bookworm-security InRelease [48,0 kB]
...
Reading package lists... Done

$ apt list --upgradable 2>/dev/null
openssh-server/stable-security 1:9.2p1-2+deb12u3 amd64 [upgradable from: 1:9.2p1-2+deb12u2]
firefox-esr/stable-security 115.12.0esr-1~deb12u1 amd64 [upgradable from: 115.11.0esr-1~deb12u1]
libc6/stable-security 2.36-9+deb12u4 amd64 [upgradable from: 2.36-9+deb12u3]
```

La ligne de commande ci-dessus est propre à la famille Debian et Ubuntu ; sous Red Hat, la commande équivalente relève de dnf, et la sortie prend un autre aspect. Quel que soit l'outil, l'idée reste la même : distinguer ce qui attend une décision de ce qui tourne déjà correctement, et conserver une trace de ce que vous avez appliqué. Notez que la sortie ci-dessus mélange trois paquets : un serveur distant, un navigateur et une bibliothèque système. Ils n'ont ni la même criticité ni le même niveau d'exposition, et c'est précisément le rôle du score CVSS de vous aider à les départager.

Le Common Vulnerability Scoring System attribue à chaque vulnérabilité publiée une note de base comprise entre zéro et dix, calculée à partir de caractéristiques techniques : difficulté d'exploitation, exigence d'interaction humaine, portée de l'attaque, impact sur la confidentialité, sur l'intégrité et sur la disponibilité. La note ne mesure pas le danger réel pour votre médiathèque, elle mesure le danger intrinsèque de la faille décrite dans son contexte technique idéal pour l'attaquant. C'est une aide à la décision, jamais un verdict : une faille notée neuf sur dix dans un service que vous n'exposez pas au réseau reste moins urgente qu'une faille notée six sur dix sur le moteur du catalogue que tout le monde consulte depuis le hall. Vous trouverez le détail de chaque CVE et son score sur la base publique nvd.nist.gov, tenue par le National Institute of Standards and Technology.

| Plage de score CVSS | Niveau déclaré | Délai à viser sur un poste public | Réaction attendue |
| --- | --- | --- | --- |
| 9,0 à 10,0 | Critique | Sous 48 heures | Appliquer le correctif ou couper l'exposition le temps de le faire |
| 7,0 à 8,9 | Élevé | Sous 7 jours | Planifier l'installation et vérifier le redémarrage |
| 4,0 à 6,9 | Moyen | Sous le cycle mensuel | Regrouper avec les mises à jour ordinaires |
| 0,1 à 3,9 | Faible | Au prochain cycle de maintenance | Traiter avec les corrections de fonctionnement |

Pour transformer ce barème en action, cinq règles suffisent et tiennent dans une routine mensuelle de deux heures. Premièrement : traitez d'abord les correctifs concernant un service réellement exposé, même s'ils sont notés un cran en dessous. Deuxièmement : ne reportez jamais un correctif critique sans motif écrit, parce que l'oubli devient vite la norme. Troisièmement : appliquez les correctifs du noyau et de la bibliothèque système avec un créneau de redémarrage prévu, car un système mis à jour sans redémarrage conserve parfois l'ancienne version en mémoire. Quatrièmement : testez sur un poste de staff avant de déployer sur les douze postes publics. Cinquièmement : consignez la date et la version dans un registre, parce que le jour où un incident surviendra, la première question posée sera de savoir si la machine était à jour.

```text
# Exemple de configuration d'installation automatique sous Debian
# Fichier : /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "resp-info@mediatheque-lilas.example";
```

L'installation automatique des seuls correctifs de sécurité, proposée nativement par Debian et Ubuntu, convient bien à un parc de postes publics que personne ne surveille en permanence. Gardez toutefois le redémarrage manuel : un poste qui redémarre tout seul pendant une séance d'atelier crée un problème d'usage, et un serveur qui redémarre sans prévenir crée un problème de service. Le réglage idéal consiste donc à laisser le correctif s'installer et à programmer le redémarrege à la fenêtre de maintenance hebdomadaire.
$lesson$),
  ('cyb-c4-p3', 'cyb-c4', 3, $lesson$Inventaire : ce qui tourne réellement sur un poste ou un serveur$lesson$, $lesson$
On ne durcit pas ce qu'on ne connaît pas. Avant de désactiver quoi que ce soit, il faut répondre avec précision à trois questions : quels logiciels tournent, quels ports sont ouverts sur le réseau, et qui a le droit de faire quoi. L'inventaire n'est pas une perte de temps préalable au travail réel, il en est la moitié : c'est lui qui vous évitera de couper le service dont dépend le catalogue, et c'est lui qui vous permettra, six mois plus tard, de savoir si la machine a changé depuis la dernière vérification.

Sous Debian ou Ubuntu, quatre commandes suffisent à dessiner le portrait du système. La première liste les connexions réseau actives et, surtout, les programmes qui les écoutent. La seconde liste les services en fonctionnement. La troisième énumère les paquets installés, ce qui donne la base de vos mises à jour. La quatrième montre les processus réellement exécutés, utile pour repérer un programme qui ne vient d'aucun paquet connu. Aucune de ces commandes n'est universelle : les équivalents changent sur d'autres systèmes, et les droits d'observation peuvent nécessiter l'élévation aux privilèges.

```text
$ sudo ss -tulpn
Netid  State   Local Address:Port   Process
tcp    LISTEN  0.0.0.0:22           users:(("sshd",pid=712,fd=3))
tcp    LISTEN  127.0.0.1:631        users:(("cupsd",pid=845,fd=12))
tcp    LISTEN  0.0.0.0:8080         users:(("python3",pid=1204,fd=7))
udp    UNCONN  0.0.0.0:68           users:(("dhclient",pid=601,fd=6))
```

Lisez cette sortie ligne à ligne, et demandez-vous de chaque port : qui en a besoin, et pourquoi. Le port vingt-deux, pour les connexions distantes, se justifie sur le serveur si l'administrateur travaille à distance, et se justifie rarement sur un poste du hall. Le port quatre-vingt-quinze de l'imprimante, absent de cet extrait, apparaîtra chez vous si un service d'impression tourne. L'adresse de bouclage à la gauche signifie que le service n'est joignable que depuis la machine elle-même, ce qui est une protection réelle : c'est le cas de l'imprimante système dans cet exemple. La dernière ligne appartient au client de configuration réseau, normal sur un poste connecté. Un port qui écoute sur toutes les interfaces sans raison documentée doit déclencher une question, pas un clic immédiat.

Une fois le portrait technique dressé, consignez-le dans un document simple, daté, que vous relirez à chaque changement. Ce tableau d'inventaire n'a pas besoin d'outil particulier : un tableur ou un fichier texte convient, à condition d'être à jour. L'essentiel est d'y noter la justification de chaque service, car la justification, et non la présence, est ce qui détermine si le service reste ou part.

```text
Inventaire du poste d'accueil — 2026-10-02 — Debian 12 « bookworm »

Composant          | État         | Port  | Justification
sshd               | actif        | 22    | aucune : intervention sur place uniquement
cups               | actif        | 631   | impression des reçus, en écoute locale
catalogue-client   | actif        | 8080  | consultation du catalogue, exposé au LAN
dhclient           | actif        | 68    | adresse IP du poste
firefox-esr        | installé     | -     | navigation des usagers, correctifs suivis
bluetooth          | désactivé    | -     | aucun périphérique autorisé
```

Deux catégories d'éléments échappent souvent à l'inventaire et méritent une ligne à part. Les tâches planifiées, qui s'exécutent à heure fixe sans intervention : elles peuvent être légitimes, comme une sauvegarde nocturne, ou suspectes, comme un script déposé par un logiciel gratuit. Les comptes, eux, se listent depuis le fichier des comptes système et depuis le groupe des administrateurs, et il est fréquent d'y découvrir un compte créé lors d'un déménagement il y a trois ans, toujours actif et toujours doté d'un mot de passe partagé. Comptez les comptes, comptez les droits, comptez les ports : tout le reste de ce chapitre repose sur ces trois nombres.
$lesson$),
  ('cyb-c4-p4', 'cyb-c4', 4, $lesson$Désactiver les services inutiles$lesson$, $lesson$
Chaque service qui tourne est une porte. La règle la plus simple du durcissement consiste à fermer toutes celles dont personne n'a besoin, et cette règle produit souvent les gains les plus rapides d'un parc entier. Contrairement à ce qu'on croit, désactiver un service ne le supprime pas : il reste installé, consultable, réactivable en une commande si le besoin apparaît réellement. Le risque est donc faible et réversible, à la différence d'une suppression qui demanderait une réinstallation.

Sous Debian ou Ubuntu, la commande de base liste les unités en état d'exécution, puis les services peuvent être arrêtés et empêchés de redémarrer. Trois verbes se distinguent, et les confondre est la première source d'erreur : arrêter couche le service pour la session en cours, empêcher son démarrage automatique au prochain redémarrage, et masquer bloque toute réactivation, y compris par une dépendance qui le réclamerait. Pour un poste public, la séquence prudente est d'abord d'observer, puis d'arrêter, puis de redémarrer la machine, et seulement ensuite de décider s'il faut empêcher le service.

```text
$ systemctl list-units --type=service --state=running
  UNIT                     LOAD   ACTIVE SUB     DESCRIPTION
  ssh.service              loaded active running OpenBSD Secure Shell server
  cups.service             loaded active running CUPS Scheduler
  bluetooth.service        loaded active running Bluetooth service
  gnome-shell.service      loaded active running GNOME Shell
  rsyslog.service          loaded active running System Logging Service

$ sudo systemctl stop bluetooth.service
$ sudo systemctl disable bluetooth.service
$ sudo systemctl mask bluetooth.service
$ sudo reboot
```

Le redémarrage n'est pas un détail de confort : c'est lui qui prouve que votre changement tient dans la durée. Un service qui ne repart pas après un redémarrage vous l'apprend en échouant à démarrer, et il vaut mieux le découvrir sur le poste de staff que le lundi matin sur les douze postes du hall. Après le redémarrage, relancez la commande d'observation des ports : si le service est vraiment éteint, sa ligne a disparu, et c'est cette disparition qui constitue votre preuve, pas votre souvenir d'avoir tapé la commande.

Trois cas méritent une attention particulière dans un parc de médiathèque. Les services de partage de fichiers, utiles sur un serveur documentaire mais rarement sur un poste consulteur, exposeront vos lecteurs à tout le réseau. Les services d'impression, en revanche, sont légitimes à l'accueil, mais ils doivent rester en écoute locale tant que l'imprimante n'a pas besoin d'être partagée au-delà de la machine. Les services distants, enfin, se justifient sur le serveur administré à distance et se justifient rarement sur un poste public : leur présence y signifie presque toujours une installation oubliée. Avant de désactiver quoi que ce soit, vérifiez toujours la liste des dépendances, parce qu'un service apparemment anodin peut être réclamé par le logiciel métier du catalogue.

- Notez avant de changer : l'état initial, la raison du changement et la date.
- Vérifiez les dépendances, un service peut être réclamé par un autre logiciel.
- Arrêtez d'abord, puis redémarrez, et seulement ensuite empêchez le démarrage.
- Conservez un service légitime en écoute locale plutôt que de le supprimer.
- Relancez l'observation des ports après redémarrage : la preuve est la ligne disparue.
- Gardez le masquage pour les services que vous ne voulez jamais voir revenir.
- Testez chaque changement sur un poste de staff avant de le déployer ailleurs.
$lesson$),
  ('cyb-c4-p5', 'cyb-c4', 5, $lesson$Réduire les privilèges : comptes, sudo et droits fichiers$lesson$, $lesson$
La couche suivante porte sur les personnes et sur les fichiers. Le principe est ancien et tient en une phrase : chaque compte doit disposer du minimum de droits qui lui permet de travailler, ni plus. Un compte administrateur utilisé pour consulter le catalogue transforme une simple erreur de clic en modification durable du système, et un mot de passe partagé entre quatre agents rend impossible toute imputation : le jour où quelque chose change, vous ne saurez pas qui l'a changé. La réduction des privilèges n'est donc pas seulement une défense contre l'extérieur, c'est aussi votre seule possibilité de comprendre ce qui se passe à l'intérieur.

Dans le cadre du chapitre, le parc de la Médiathèque des Lilas repose sur trois comptes aux rôles nets. Le compte d'administration, nominatif, est celui de la personne responsable du parc : il installe, met à jour, lit les journaux et ne sert jamais à la consultation. Le compte de staff est celui des agents derrière le comptoir : ils utilisent les logiciels métier, impriment et consultent le catalogue, mais n'installent rien. Le compte usager, éphémère ou partagé selon l'organisation, sert à la consultation publique : session courte, dossier personnel volatile, aucun droit hors du répertoire de navigation. Trois comptes, trois rôles, trois ensembles de droits : c'est cette séparation qui rend la suite du chapitre applicable, puisque sans comptes distincts, ni journal ni restriction n'ont de sens.

La distribution des rôles passe par deux mécanismes distincts. Le premier est l'appartenance aux groupes : sous Debian ou Ubuntu, les membres du groupe sudo sont autorisés à élever leurs privilèges. Le second est le fichier de règles d'élévation, consultable avec la commande dédiée, qui décrit précisément quel utilisateur peut exécuter quelle commande avec quel niveau d'élévation. L'erreur classique consiste à y accorder un interpréteur de commandes avec tous les droits : l'utilisateur n'a alors plus aucune restriction et le fichier de règles ne sert plus à rien. L'erreur opposée consiste à donner le mot de passe d'administration à chacun, ce qui revient au même résultat en moins visible. La bonne pratique accorde des commandes nommées, ou un groupe restreint, et conserve la trace de chaque élévation dans les journaux que vous installerez plus loin.

```text
# Fichier : /etc/sudoers.d/parc-mediatheque — édité avec visudo, jamais avec un éditeur ordinaire
Defaults        env_reset
Defaults        mail_badpass
Defaults        logfile="/var/log/sudo.log"

# L'administrateur du parc exécute tout ce qui est nécessaire à la maintenance
nadia   ALL=(ALL:ALL) ALL

# L'équipe de staff peut redémarrer le service d'impression, et rien d'autre
%sstaff ALL=(root) /usr/bin/systemctl restart cups.service
%sstaff ALL=(root) /usr/bin/systemctl status cups.service

# Aucun accès pour le compte de consultation publique
usager  ALL=(ALL) NOPASSWD: NONE
```

Les droits fichiers constituent le deuxième volet de cette réduction. Sous les systèmes de type Unix, chaque fichier porte trois catégories de permissions, pour son propriétaire, pour son groupe et pour les autres, et chaque catégorie reçoit trois droits : lecture, écriture et exécution. Le tableau suivant résume les neuf cases possibles et leur signification pratique ; c'est le tableau que vous garderez sous les yeux pendant tout le mini-projet.

| Droit | Sur un fichier | Sur un répertoire | Notation symbolique | Notation chiffrée |
| --- | --- | --- | --- | --- |
| lecture | voir le contenu | lister les entrées | r | 4 |
| écriture | modifier le contenu | créer ou supprimer des entrées | w | 2 |
| exécution | lancer le programme | traverser le répertoire | x | 1 |
| propriété | le propriétaire du fichier | le propriétaire du répertoire | u | premier chiffre |
| groupe | les membres du groupe associé | les membres du groupe associé | g | deuxième chiffre |
| autres | tout autre utilisateur | tout autre utilisateur | o | troisième chiffre |

La lecture, l'écriture et l'exécution ne signifient pas la même chose selon qu'on regarde un fichier ou un répertoire, et cette distinction explique la plupart des dysfonctionnements. Exécuter un fichier program veut dire le lancer ; traverser un répertoire veut dire pouvoir accéder à ce qui s'y trouve, ce qui suppose donc l'exécution sur le répertoire lui-même, même sans aucun droit de lecture. Écrire dans un répertoire, enfin, permet d'y créer et d'y supprimer des entrées, indépendamment du propriétaire réel de ces entrées : c'est pourquoi les répertoires partagés d'une équipe se règlent en lecture et écriture pour le groupe, et pourquoi un répertoire de fichiers sensibles reçoit l'autorisation d'exécution réservée aux seuls propriétaires. Sous Debian ou Ubuntu, la commande d'attribution accepte une forme symbolique, commode pour un ajustement ponctuel, et une forme chiffrée, préférable pour une application explicite.

```text
$ ls -l /srv/catalogue/
-rw-r----- 1 nadia staff  4096 oct.  2 09:12 index.html
-rw-rw---- 1 nadia staff 12288 oct.  2 09:15 articles.db
drwxr-x--- 2 nadia staff  4096 oct.  1 18:40 media/

$ sudo chmod 640 /srv/catalogue/articles.db
$ sudo chown nadia:staff /srv/catalogue/articles.db
$ sudo chmod 750 /srv/catalogue/media
$ umask 027
```

Porté à soixante-quarante, le premier fichier reste lisible par son propriétaire et écrit par son groupe, mais devient illisible pour les autres : personne ne pourra récupérer la base des articles depuis un compte de consultation. Porté à soixante-quinze-zéro, le répertoire de médias devient accessible à son propriétaire et à son groupe, fermé à tous les autres, et l'utilisateur devra y entrer pour y accéder. Le masque de création, enfin, applique automatiquement ces règles aux nouveaux fichiers, si bien que vous n'aurez plus à y penser une fois configuré. Réglez l'origine des fichiers, c'est-à-dire le propriétaire et le groupe, avant d'ajuster les permissions : attribuer des droits sur un fichier mal propriétaire ne fait que déplacer le problème.

Au-delà des droits, la politique de mots de passe mérite elle aussi d'être posée par écrit, parce qu'elle est le point où l'humain rencontre la technique. La longueur prime aujourd'hui sur la sophistication : une phrase de plusieurs mots est plus résistante et plus mémorisable qu'un mot de passe court mêlant chiffres et symboles. Interdisez les mots de passe partagés, expirez les comptes dormants plutôt que les mots de passe fréquemment changés, et verrouillez automatiquement le compte après un nombre raisonnable d'échecs, sous Debian ou Ubuntu avec les outils de gestion des comptes fournis par la distribution. Enfin, exigez l'élévation pour toute modification système et vérifiez, dans les journaux, qu'elle est bien enregistrée : un compte de staff qui peut redémarrer un service d'impression doit le pouvoir une fois par mois, pas cent fois par jour.

- Ne vous connectez jamais directement en administrateur : élevez les privilèges à la demande.
- Éditez les règles d'élévation avec l'outil dédié, qui vérifie la syntaxe avant d'enregistrer.
- Accordez des commandes nommées plutôt qu'un interpréteur avec tous les droits.
- Un compte public ne possède aucun droit hors de son répertoire de travail.
- Appliquez le masque de création aux comptes qui produisent des fichiers partagés.
- Relisez chaque trimestre la liste des comptes et celle des membres du groupe sudo.
- Consignez par écrit la politique de mots de passe et la durée de verrouillage.
$lesson$),
  ('cyb-c4-p6', 'cyb-c4', 6, $lesson$Durcissement de configuration : s'appuyer sur des guides de référence$lesson$, $lesson$
À présent que les services sont triés, les correctifs posés et les droits réduits, reste la couche la plus fastidieuse : les options de configuration, celles dont personne ne se soucie jusqu'au jour où elles font défaut. Plutôt que d'inventer votre propre liste, reposez-vous sur des guides publiés par des organismes reconnus. Le Center for Internet Security publit des ensembles de règles de configuration, dits benchmarks, qui décrivent pour chaque système un ensemble de recommandations numérotées. L'Agence nationale de la sécurité des systèmes d'information, l'organisme public français chargé de la cyberdéfense, publie de son côté des guides de durcissement et des recommandations adaptés aux administrations. Les éditeurs de distributions, Debian et Ubuntu en tête, documentent également les bonnes pratiques propres à leur système. Aucun de ces documents n'est à appliquer aveuglément : ils sont à lire, à filtrer, et à adapter.

Un benchmark se lit de la même manière quel que soit son auteur. Chaque recommandation comporte un identifiant stable, une justification qui explique le risque couvert, une commande de vérification qui prouve l'état actuel et une procédure de remédiation. L'ordre de traitement est le vôtre : vous n'appliquerez pas tout, vous appliquerez ce qui correspond à votre modèle de menace et à votre usage. Un poste public du hall n'a pas les mêmes exigences qu'un serveur exposé sur internet, et une recommandation pertinente pour un système bancaire peut être sans effet utile ici. Ce qui est indispensable, en revanche, c'est de consigner les écarts : si vous décidez volontairement de conserver un réglage non conforme, notez la raison et la date, sinon la prochaine personne chargée du contrôle le corrigera sans savoir qu'il s'agissait d'un choix.

Trois domaines concentrent l'essentiel du travail. Le premier est le noyau et ses paramètres réseau : ils décident notamment de ce que la machine accepte comme trafic et de la manière dont elle répond à certaines situations de charge. Le second est le serveur d'accès distant, présent sur le serveur de la médiathèque s'il est administré depuis un bureau : il doit refuser les connexions d'administration directes et limiter les tentatives. Le troisième est la politique de mots de passe au niveau système, qui complète ce que vous avez posé à la section précédente. Sous Debian ou Ubuntu, ces réglages vivent dans des fichiers de configuration éditables en texte, ce qui se prête très bien au versioning et à la comparaison d'une machine à l'autre.

```text
# Fichier : /etc/sysctl.d/90-durcissement.conf
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
kernel.randomize_va_space = 2

# Fichier : /etc/ssh/sshd_config.d/90-durcissement.conf
PermitRootLogin no
MaxAuthTries 3
X11Forwarding no
AllowGroups sudo staff-admin
ClientAliveInterval 300
ClientAliveCountMax 2

$ sudo sshd -t && sudo systemctl reload ssh
```

Chaque ligne de cet extrait mérite qu'on la relise avant de l'appliquer. Les filtres de chemin inversé aident la machine à rejeter les paquets dont l'adresse d'origine paraît falsifiée ; les cookies de synchronisation permettent de résister à certains épuisements de ressources ; les redirections refusées empêchent la machine de se faire le relais involontaire d'un trafic dirigé ailleurs ; l'aléatisation de l'espace d'adressage rend les exploits mémoire sensiblement plus difficiles côté serveur d'accès. La ligne qui limite les groupes autorisés à se connecter est souvent celle qui produit le plus grand gain : elle interdit d'emblée toute connexion au compte d'administration depuis un hôte non prévu, et fait tomber la majorité des tentatives automatisées avant même l'authentification. La dernière commande vérifie la syntaxe avant de recharger, ce qui vous évite d'être déconnecté par une faute de frappe.

Le réglage le plus délicat reste celui qui vous enferme hors de votre propre machine. Une configuration trop stricte appliquée à distance, sur un serveur que vous ne pouvez redémarrer que depuis le local technique, se paie en escaliers et en déplacement. Appliquez donc toujours les changements réseau par étapes : conservez une session ouverte pendant que vous testez la nouvelle, prévoyez une voie d'accès physique, et validez la connexion depuis une seconde machine avant de fermer la première. La prudence vaut aussi pour les mises à jour de configuration : un fichier de réglages modifié pendant trois mois sans version connue est impossible à diagnostiquer, alors versionnez-le ou archivez au moins sa copie précédente.

- Choisissez un guide de référence reconnu et un seul comme base de départ.
- Lisez la justification de chaque recommandation avant d'en appliquer la procédure.
- Vérifiez l'état actuel, appliquez, puis revérifiez avec la commande de contrôle.
- Consignez par écrit chaque écart volontaire, avec sa raison et sa date.
- Testez toute règle d'accès distant depuis une seconde session avant de fermer la première.
- Archivez la version précédente de chaque fichier de configuration modifié.
- Adaptez l'exigence au poste : un consulteur n'a pas les mêmes besoins qu'un serveur.
$lesson$),
  ('cyb-c4-p7', 'cyb-c4', 7, $lesson$Chiffrement du disque et des sauvegardes locales$lesson$, $lesson$
Les sections précédentes ont réduit ce que l'on peut faire sur la machine ; celle-ci réduit ce que l'on peut emporter avec elle. Le chiffrement du disque protège les données au repos, c'est-à-dire celles qui dorment sur le stockage quand la machine est éteinte. Son cas d'usage le plus fréquent dans une médiathèque tient en une ligne : un poste volé ou perdu lors d'un déménagement, un disque retiré d'un serveur réformé, une clé de secours oubliée dans un tiroir. Sans chiffrement, la récupération des fichiers ne demande qu'un câble et un système d'exploitation d'appoint ; avec chiffrement, elle demande la clé, que vous n'avez pas donnée.

Sous Debian ou Ubuntu, le chiffrement de volume repose sur LUKS et sur l'outil associé, qui crée un conteneur chiffré au sein duquel un système de fichiers conventionnel est formaté. Trois décisions accompagnent toujours cette opération. La première est la taille de l'en-tête de clé, qui conditionne le nombre de clés de secours que vous pourrez enregistrer. La seconde est la récupération : prévoyez une clé de secours déposée en lieu sûr, hors de l'établissement, parce qu'un disque chiffré dont la seule clé a été perdue est un disque perdu. La troisième est l'impact sur le redémarrage : une machine à disque chiffré redémarre en demandant une saisie manuelle, ce qui exclut tout redémarrage distant automatique et impose de planifier une présence physique.

```text
# Sur Debian ou Ubuntu : chiffrer une partition de données (opération destructive)
$ sudo cryptsetup luksFormat /dev/sdb2
$ sudo cryptsetup open /dev/sdb2 sauvegarde-chiffree
$ sudo mkfs.ext4 /dev/mapper/sauvegarde-chiffree
$ sudo mount /dev/mapper/sauvegarde-chiffree /srv/sauvegardes

# Sauvegarde chiffrée d'un répertoire de données
$ tar czf - /srv/catalogue | gpg --symmetric --cipher-algo AES256 \
    --output /srv/sauvegardes/catalogue-2026-10-02.tar.gz.gpg

# Vérification : la sauvegarde doit pouvoir être lue avant d'être utile
$ gpg --decrypt --output /dev/null /srv/sauvegardes/catalogue-2026-10-02.tar.gz.gpg
```

L'opération de formatage est irréversible : elle détruit ce qui existait déjà sur la partition visée. C'est pourquoi toute procédure de chiffrement commence par une vérification du nom de périphérique, et pourquoi vous ne l'exécuterez jamais sur un disque dont vous n'avez pas confirmé le contenu. La sauvegarde chiffrée, elle, se justifie indépendamment du chiffrement du poste : les données copiées sur un support de secours hébergent les mêmes informations que l'original et méritent la même protection, sous réserve d'un point important : la clé de déchiffrement ne doit jamais voyager avec les données. Gardez-la sur un autre support, idéalement sous forme imprimée ou sur un dispositif dédié.

Pour la politique de sauvegarde elle-même, retenez la règle des trois exemplaires, deux supports, un exemplaire hors site. Trois exemplaires parce qu'un support mécanique tombe en panne, deux supports parce qu'un incendie ou un vol frappe souvent plusieurs disques rangés ensemble, un exemplaire hors site parce qu'une inondation du local technique emporte tout ce qui s'y trouve. Dans une médiathèque, l'exemplaire hors site peut être une sauvegarde chiffrée confiée une fois par mois à un autre service de la commune, ou un envoi chiffré vers un stockage distant. Quelle que soit la méthode, exécutez une restauration complète au moins une fois par an : une sauvegarde jamais testée est une hypothèse, pas une sauvegarde.

- Chiffrez les volumes de données, pas seulement les sauvegardes : les deux se protègent.
- Déposez la clé de secours hors de l'établissement et notez qui en a connaissance.
- Rappelez que tout disque chiffré exige une présence physique au redémarrage.
- Appliquez la règle des trois exemplaires, deux supports, un exemplaire hors site.
- Conservez la clé de déchiffrement sur un support différent des données.
- Testez une restauration complète au moins une fois par an, avec date consignée.
- Notez dans l'inventaire les périphériques chiffrés et leur procédure d'accès.
$lesson$),
  ('cyb-c4-p8', 'cyb-c4', 8, $lesson$Journalisation : quels journaux, où et combien de temps$lesson$, $lesson$
La dernière couche du socle est la mémoire du système. Une machine sans journalisation est une machine sur laquelle vous ne pouvez répondre à aucune question après coup : s'est-on connecté ? à quelle heure ? depuis quelle adresse ? quel fichier a changé ? lequel des quatre comptes de staff a lancé cette commande ? Le journal ne vous empêche pas d'être attaqué, il vous donne les éléments pour le constater, pour limiter l'impact et pour corriger la cause. C'est aussi la condition de toute amélioration : sans trace, chaque incident repart de zéro et chaque correction reste une opinion.

Sous Debian ou Ubuntu, deux mécanismes coexistent et se complètent. Le journal du système, tenu par l'unité centrale, conserve les messages émis par le noyau, les services et les commandes d'administration, avec un horodatage précis et, pour chaque entrée, l'identité du processus émetteur. Le démon de journalisation traditionnel, lui, écrit les fichiers de texte rangés dans le répertoire des journaux, avec une rotation automatique qui empêche les fichiers de grossir indéfiniment. Par défaut, le journal du système peut n'être conservé qu'en mémoire, ce qui le fait disparaître à chaque redémarrage : pour un poste public dont on veut relire l'historique, il faut opter pour le stockage persistant sur disque.

```text
# Rendre le journal persistant sous Debian ou Ubuntu
$ sudo mkdir -p /var/log/journal
$ sudo systemctl restart systemd-journald
$ journalctl --disk-usage

# Lire le journal : unité, période, priorité, forme suivie
$ journalctl -u ssh --since "2026-10-01 08:00" --until "2026-10-01 18:00"
$ journalctl -p err -b
$ journalctl -f
$ journalctl --list-boots
```

Les quatre commandes de l'exemple couvrent l'essentiel de la lecture quotidienne. La première restreint la lecture à un service et à une plage horaire, ce qui transforme des milliers de lignes en une liste tenable. La seconde n'affiche que les messages d'erreur et au-dessus de la session en cours, ce qui convient à un contrôle rapide du matin. La troisième suit le journal en direct, utile pendant un test que vous êtes en train d'observer. La quatrième liste les sessions de démarrage, ce qui permet de savoir si la machine a redémarré entre deux événements, détail déterminant dans une enquête. Ces commandes relèvent de la famille Debian et Ubuntu ; d'autres systèmes proposent des outils voisins mais différents.

La question du temps de conservation se règle ensuite, et elle oppose deux besoins réels. Conserver trop longtemps fait grossir le disque et finit par coûter de l'espace utile au service ; conserver trop peu efface la preuve au moment précis où elle devient intéressante, car un incident est souvent découvert plusieurs semaines après son commencement. Le bon réglage part de la question à laquelle vous devez pouvoir répondre, puis remonte vers la durée. Pour une médiathèque, une politique simple tient dans le tableau suivant, à adapter à la taille des disques et à la fréquence des incidents.

| Type de journal | Exemples | Durée de conservation | Espace approximatif pour douze postes |
| --- | --- | --- | --- |
| Authentification et droits | connexions, élévations, comptes | 12 mois | quelques centaines de mégaoctets |
| Services métier | catalogue, impression, sauvegardes | 6 mois | quelques centaines de mégaoctets |
| Erreurs système | échecs de démarrage, pannes | 3 mois | quelques dizaines de mégaoctets |
| Journal de debug | détails de fonctionnement | 7 jours | variable, souvent le plus gros |

Deux limites techniques complètent la politique. La rotation des fichiers de texte, déjà en place, s'exprime en taille et en durée : vous fixez un maximum de taille par fichier et un nombre de fichiers conservés, et le système écrase le plus ancien. Le journal du système, de son côté, dispose de plafonds globaux d'espace et d'un âge maximal au-delà duquel les entrées sont purgées. Réglez ces deux valeurs ensemble, vérifiez l'espace consommé réel après une semaine de fonctionnement, puis ajustez : une politique de conservation n'est juste qu'une fois mesurée sur votre propre parc.

- Activez le stockage persistant si vous voulez survivre aux redémarrages.
- Conservez au minimum douze mois les journaux d'authentification et d'élévation.
- Notez la question à laquelle vous devez pouvoir répondre, puis fixez la durée.
- Réglez ensemble la rotation des fichiers et les plafonds du journal du système.
- Vérifiez l'espace réel occupé après une semaine, puis corrigez la politique.
- Datez la dernière vérification de la conservation dans votre registre du parc.
$lesson$),
  ('cyb-c4-p9', 'cyb-c4', 9, $lesson$Détecter dans les journaux : connexions répétées, modifications de fichiers, comptes créés$lesson$, $lesson$
Avoir des journaux ne suffit pas : encore faut-il les lire, et les lire suppose de savoir quoi chercher. Une recherche dans un journal est une hypothèse : vous postulez qu'un événement s'est produit, vous cherchez sa trace, et vous interprétez le résultat. Trois hypothèses reviennent dans la quasi-totalité des incidents de premier niveau, et chacune correspond à une commande simple. La première cherche des tentatives d'authentification répétées, signature d'un balayage automatisé ou d'une personne qui teste plusieurs mots de passe. La seconde cherche des modifications de fichiers sensibles. La troisième cherche la création ou la modification de comptes, qui marque souvent le passage d'une intrusion opportuniste à une installation durable.

Commençons par les connexions répétées. Sous Debian ou Ubuntu, les tentatives d'authentification distante abouties ou refusées sont enregistrées par le service d'accès distant, et chaque ligne indique l'heure, l'adresse d'origine, le compte visé et l'issue. Le motif à repérer tient en peu de mots : un grand nombre de lignes identiques, à quelques secondes d'intervalle, sur un même compte ou sur plusieurs comptes inexistants. L'extrait ci-dessous est typique d'un poste du hall interrogé pendant une nuit : aucune connexion aboutie, mais une dizaine de tentatives par minute, ce qui suffit à déclencher une investigation.

```text
# Extrait : /var/log/auth.log — poste d'accueil, nuit du 1er au 2 octobre
oct.  2 03:12:44 poste-accueil sshd[2411]: Failed password for invalid user admin from 203.0.113.44 port 51234 ssh2
oct.  2 03:12:47 poste-accueil sshd[2413]: Failed password for invalid user admin from 203.0.113.44 port 51240 ssh2
oct.  2 03:12:51 poste-accueil sshd[2415]: Failed password for invalid user root from 203.0.113.44 port 51247 ssh2
oct.  2 03:13:02 poste-accueil sshd[2418]: Failed password for nadia from 203.0.113.44 port 51266 ssh2
oct.  2 03:13:05 poste-accueil sshd[2421]: error: maximum authentication attempts exceeded for invalid user admin from 203.0.113.44 port 51272 ssh2 [preauth]
oct.  2 03:13:05 poste-accueil sshd[2421]: Connection closed by authenticating user root 203.0.113.44 port 51272 [preauth]
```

Trois informations ressortent immédiatement. Les comptes visés, dont deux n'existent pas, montrent que l'attaquant travaille sur une liste de noms courants. L'adresse source unique indique une source unique, ce qui permet de la distinguer d'un balayage massif diffusé depuis mille machines. L'absence de ligne indiquant une session ouverte prouve qu'aucune connexion n'a abouti, ce qui change radicalement la nature de l'événement : ici, il n'y a pas eu intrusion, il y a eu tentative. Cette distinction guide la suite : on consigne, on surveille, on renforce, et on n'enclenche pas pour autant la procédure d'urgence. Sur Debian ou Ubuntu, un outil de la distribution peut automatiser ce comptage et bloquer temporairement une adresse qui dépasse le seuil, mais l'automatisation ne remplace pas la lecture hebdomadaire des mêmes lignes.

```text
# Trois recherches de base et ce qu'elles cherchent à prouver

# 1. Qui a tenté de se connecter, et combien de fois ? (comptage par compte)
$ sudo grep "Failed password" /var/log/auth.log | \
    awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
      41 admin
      12 root
       3 nadia

# 2. Quelles commandes d'administration ont été exécutées, par qui, à quelle heure ?
$ journalctl -u ssh --since "yesterday" | grep -i "session opened"

# 3. Un compte a-t-il été créé ou ajouté à un groupe d'administration ?
$ journalctl --since "2026-09-01" | grep -E "useradd|usermod|adduser"
```

La deuxième hypothèse porte sur les fichiers. Les journaux système n'enregistrent pas chaque écriture : c'est le rôle d'outils dédiés, présents dans les dépôts de Debian et d'Ubuntu, qui surveillent des répertoires et signalent les changements. À défaut d'un tel outil, deux alternatives gratuites existent. La première consiste à lire le journal des commandes d'administration, où chaque élévation indique le compte, le terminal, l'adresse et la commande exacte : voir modifier un fichier de configuration avec un éditeur y laisse une trace explicite. La seconde consiste à comparer les dates de modification des fichiers sensibles avec celles que vous avez consignées dans l'inventaire : une date qui change sans ticket correspondant est un signal. Dans un service web, l'accès log peut lui aussi révéler une tentative, par une série anormale de chemins inconnus renvoyant des erreurs, qui précède souvent une exploitation.

```text
# Commandes d'administration récentes : ce que dit chaque ligne
oct.  1 14:02:11 serveur sudo: nadia : TTY=pts/0 ; PWD=/home/nadia ; \
    USER=root ; COMMAND=/usr/bin/systemctl restart catalogue.service
oct.  1 14:09:37 serveur sudo: nadia : TTY=pts/0 ; PWD=/home/nadia ; \
    USER=root ; COMMAND=/usr/bin/vim /etc/ssh/sshd_config
oct.  2 09:41:02 serveur sudo: inconnu : 3 incorrect password attempts

# Création d'un compte : la trace attendue le jour d'une installation non autorisée
oct.  2 02:55:19 serveur useradd[1902]: new user: name=backup2, UID=1005, \
    GID=1005, home=/home/backup2, shell=/bin/sh, from=203.0.113.44
```

La troisième hypothèse est la plus grave, parce qu'un compte créé en dehors de tout ticket représente une porte installée pour durer. Cherchez les lignes de création, les lignes de modification d'appartenance à un groupe d'administration, et les lignes d'activation d'un compte qui était désactivé. Croisez ensuite chaque résultat avec ce que vous savez : la création du compte de sauvegarde le 2 octobre à deux heures du matin, depuis une adresse qui figure parmi celles qui ont tenté des connexions la veille, forme une chaîne cohérente que le hasard n'explique pas. Ce croisement, plus que la lecture isolée d'une ligne, constitue le cœur du travail d'investigation : chaque indice acquiert son sens par comparaison avec un autre.

- Cherchez d'abord les tentatives répétées, puis les élévations, puis les comptes.
- Distinguez toujours tentative aboutie et tentative refusée : ce ne sont pas deux incidents.
- Rapprochez les adresses, les heures et les comptes : le croisement fait la preuve.
- Notez l'heure exacte du premier indice : elle fixe le point de départ de l'enquête.
- Relisez le journal hebdomadairement, pas seulement après un signalement.
- Comptez les comptes créés depuis la dernière vérification, à chaque contrôle.
$lesson$),
  ('cyb-c4-p10', 'cyb-c4', 10, $lesson$Centralisation des journaux et horodatage$lesson$, $lesson$
Un attaquant qui prend la main sur une machine commence souvent par effacer les traces qu'il y a laissées. C'est la raison d'être de la centralisation : dès qu'un événement a une importance réelle, ses journaux doivent être copiés ailleurs, sur une machine que l'attaquant ne contrôle pas. Le principe tient en une phrase : le poste subit l'incident, le serveur de journaux en garde la mémoire. Pour une médiathèque, un seul petit serveur de stockage suffit, il peut héberger le catalogue et la copie des journaux des quatorze machines du parc, à condition qu'il soit lui-même durci et sauvegardé.

Le mécanisme le plus simple repose sur le protocole de journalisation standard, que les systèmes parlent nativement. Le démon de journalisation local, sous Debian ou Ubuntu, sait envoyer une copie des messages vers un hôte distant ; le récepteur, du côté du serveur, écoute sur le port dédié et écrit chaque machine dans son propre fichier. L'essentiel est de préserver l'adresse d'origine : si les quatorze machines écrivent dans un fichier unique sans identification, vous ne saurez plus quel poste a émis quelle ligne, et le fichier central deviendra illisible. Écrivez chaque hôte dans un répertoire portant son nom, et ne donnez à ce service que le droit d'écrire, jamais celui de lire ou de supprimer.

```text
# Côté poste : /etc/rsyslog.d/50-centralisation.conf
*.* action(type="omfwd" target="journaliers.mediatheque.local" port="514"
           protocol="tcp" queue.type="linkedList" queue.filename="fwd")

# Côté serveur : réception et séparation par machine
module(load="imtcp")
input(type="imtcp" port="514")
template(name="ParHote" type="string" string="/var/log/centralise/%HOSTNAME%/messages.log")
*.* action(type="omfile" dynaFile="ParHote")

# Vérifier que l'horloge est juste, condition de toute corrélation
$ timedatectl
               Local time: jeu. 2026-10-02 10:15:43 CEST
           Universal time: jeu. 2026-10-02 08:15:43 UTC
  Synchronized to time server: yes
```

L'horodatage mérite une attention égale, parce que la corrélation entre machines repose entièrement sur la comparaison des heures. Si le poste affiche dix heures et le serveur dix heures quatre, la recherche par plage horaire manquera l'événement ou en attribuera un mauvais. Synchronisez toutes les machines sur une même source de temps, de préférence locale au réseau, et vérifiez la synchronisation à chaque intervention. Conservez les heures en format standard dans les archives, et notez le décalage horaire d'été quand vous relisez des journaux d'une saison précédente : un décalage d'une heure explique plus d'enquêtes avortées qu'on ne croit.

Trois précautions complètent la mise en place. Premièrement, chiffrez ou protégez le transport si les journaux transitent hors du réseau local, parce qu'un journal en clair donne à un observateur la carte exacte de votre activité. Deuxièmement, dimensionnez : quatorze machines qui émettent quelques milliers de lignes par jour produisent une taille prévisible, mesurez-la après une semaine avant de fixer vos plafonds. Troisièmement, restreignez l'accès au serveur central à la ou deux personnes chargées de la lecture, et journalisez à votre tour les accès à ce serveur : la mémoire du parc doit être surveillée comme un actif à part entière.

- Copiez les journaux importants vers une machine que l'incident ne peut pas atteindre.
- Séparez les journaux par hôte : un fichier unique sans origine est illisible.
- Donnez au service central le droit d'écrire, jamais celui de supprimer.
- Synchronisez toutes les machines sur une même source de temps, et revérifiez-la.
- Mesurez le volume quotidien avant de fixer les plafonds de conservation.
- Protégez l'accès au serveur de journaux et comptez celui-ci dans l'inventaire.
$lesson$),
  ('cyb-c4-p11', 'cyb-c4', 11, $lesson$Réponse à un signalement de malware sur un poste public$lesson$, $lesson$
Tôt ou tard, un signalement arrive : une alerte s'affiche dans le navigateur, une fenêtre propose de payer, un agent du comptoir signale que le poste affiche un contenu inhabituel ou que la souris se déplace seule. Ce moment est celui où la préparation paye, et où l'affolement coûte cher. Une procédure de réponse en six étapes, écrite à l'avance et placée à portée de main, transforme un événement stressant en une suite de gestes méthodiques. Les six étapes sont les suivantes : préparer, isoler, préserver, investiguer, éradiquer et restaurer, puis capitaliser. Elles s'enchaîtent dans cet ordre et ne se sautent jamais.

La préparation est faite avant l'incident : vous disposez de l'inventaire, des journaux centralisés, des comptes nominatifs, du point de contact responsable et de la procédure elle-même. C'est l'étape que vous avez construite avec tout le chapitre. L'isolation consiste à cesser toute communication du poste suspect avec le réseau, en débranchant le câble réseau ou en désactivant l'interface sans fil, sans éteindre la machine. Cette dernière précision est essentielle : les preuves les plus précieuses, les processus en cours, les connexions ouvertes, les fichiers chargés en mémoire, disparaissent à l'extinction. Un poste isolé reste infecté mais cesse de nuire aux autres machines, ce qui suffit dans l'immense majorité des cas.

L'étape de préservation consiste à figer la situation avant d'agir. Notez l'heure exacte du signalement, photographiez l'écran, relevez le nom du compte connecté, copiez les journaux du poste vers le serveur central si la connexion est encore possible avant isolation, et ne nettoyez rien. La tentation d'effacer est forte et toujours mauvaise : elle détruit l'indice qui aurait permis de comprendre comment l'intrusion est entrée, et donc de fermer la porte. Si votre organisation conserve des images de restauration, c'est le moment de s'assurer qu'une image à jour existe : elle raccourcira dramatiquement l'étape de restauration.

```text
 Chronologie type — réponse à un signalement sur un poste public

  T0        T0 + 5 min      T0 + 30 min     T0 + 2 h        T0 + 24 h
   |             |               |               |               |
 signalement  isolation      préservation    investigation   décision
   |          réseau coupé    photos, heures   journaux,       restauration
   |             |            journaux copiés  processus       image connue
   |             |               |               |               |
   +-------------+---------------+---------------+---------------+
        on n'éteint pas, on ne nettoie pas, on ne devine pas

 Etapes : 1 preparer | 2 isoler | 3 preserver | 4 investiguer
          5 eradiquer et restaurer | 6 capitaliser
```

L'investigation répond à trois questions, dans cet ordre : que fait la machine, depuis quand, et comment est-ce entré. Sur le poste suspect, on regarde les processus en cours et leur origine, les programmes lancés automatiquement au démarrage, les extensions du navigateur récemment ajoutées et les fichiers modifiés pendant les heures qui précèdent le signalement. On relit ensuite le journal du service d'accès distant et les commandes d'administration des jours précédents, en cherchant l'entrée légitime qui a précédé l'anomalie : un téléchargement exécuté, un mot de passe deviné, une clé USB ouverte. Cette question de l'entrée est la plus importante de l'enquête, parce que restaurer sans la connaître revient à rouvrir la porte quelques jours plus tard.

L'éradication suit un principe sans exception : on ne répare pas un système compromise, on le reconstruit à partir d'une image de référence connue propre, puis on remet en place les données nécessaires après vérification. On change ensuite tous les mots de passe concernés, depuis une machine non compromise, en commençant par ceux des comptes d'administration. On applique enfin le correctif ou la configuration qui a permis l'entrée, si elle est identifiée. La dernière étape, la capitalisation, consiste à écrire ce qui s'est passé en une page : chronologie, cause, décisions prises, correctifs appliqués, et surtout les trois questions à laquelle cette page doit répondre : que corriger dans le parc, que corriger dans la procédure, que surveiller désormais.

- Isoler en débranchant, jamais en éteignant : la mémoire vive contient les preuves.
- Photographiez l'écran et notez l'heure du signalement avant toute autre action.
- Ne nettoyez rien avant d'avoir identifié le chemin d'entrée.
- Reconstruisez à partir d'une image de référence plutôt que de réparer sur place.
- Changez les mots de passe depuis une machine dont vous êtes certain qu'elle est saine.
- Écrivez une page de retour d'expérience et rangez-la avec la procédure.
$lesson$),
  ('cyb-c4-p12', 'cyb-c4', 12, $lesson$Mini-projet guidé : la fiche de durcissement du poste d'accueil$lesson$, $lesson$
Vous voici arrivé à l'assemblage. Le mini-projet du chapitre consiste à produire un seul document, la fiche de durcissement du poste d'accueil de la Médiathèque des Lilas, qui doit pouvoir être remis à un collègue n'ayant jamais vu la machine et lui permettre de reprendre le travail sans vous. Ce n'est pas un rapport de synthèse : c'est un outil de travail, daté, vérifiable, composé de six parties qui reprennent exactement l'ordre des couches de la pile de durcissement. Prenez le temps d'écrire chaque partie dans l'ordre, parce que chaque réponse s'appuie sur la précédente et que l'ordre révèle lui-même la méthode.

La première partie est l'inventaire. Vous y décrivez le poste tel qu'il est : système d'exploitation et version, logiciels installés, services en fonctionnement, ports à l'écoute et comptes existants avec leur rôle. Les commandes de la section correspondante produisent le matériau brut ; votre travail consiste à le transformer en tableau lisible, avec une justification à côté de chaque service et une colonne de décision. La deuxième partie traite de la désactivation : vous y listez les services retirés, la commande employée, la date, et le résultat du contrôle effectué après redémarrage. Une décision sans preuve de contrôle ne doit pas figurer dans la fiche.

La troisième partie est la matrice de droits des trois comptes. Vous y croisez les trois comptes du parc avec les ressources qu'ils doivent atteindre : les répertoires de travail, les fichiers de configuration, les services qu'ils peuvent redémarrer, les journaux qu'ils peuvent lire. Chaque cellule contient un droit précis et, s'il est refusé, la justification. Cette matrice se lit en trente secondes et remplace avantageusement trois pages de prose : elle montre d'un coup d'œil que le compte de consultation ne peut rien écrire hors de son dossier, que le compte de staff ne touche qu'à l'impression, et que seul le compte d'administration manie les correctifs.

```text
 FICHE DE DURCISSEMENT — poste d'accueil, Médiathèque des Lilas
 Réf. P-07 / version 1 / établie le 2026-10-02 par N. Benali

 1. INVENTAIRE
    Système : Debian 12 « bookworm » (réinstallation du 2026-06-14)
    Services actifs : sshd, cups, catalogue-client, rsyslog
    Ports : 22 (LAN uniquement), 631 (bouclage), 8080 (LAN)
    Comptes : nadia (administration), staff (poste), usager (consultation)

 2. SERVICES DESACTIVES — justification, commande, controle
    bluetooth : aucun peripherique autorise / stop + disable + masque /OK apres reboot
    avahi     : pas d'advertisement réseau necessaire / idem /OK apres reboot

 3. MATRICE DES DROITS
    Ressource          | nadia | staff | usager
    /srv/catalogue     | rw    | r     | r
    /etc/ssh           | rw    | -     | -
    systemctl restart  | tout  | cups  | -
    /var/log           | r     | -     | -

 4. PLAN DE CORRECTIFS — priorite par score CVSS
    Paquet            | CVE           | score | echeance
    openssh-server    | CVE-2026-XXXX | 9,8   | 48 h
    libc6             | CVE-2026-YYYY | 7,5   | 7 jours
    firefox-esr       | CVE-2026-ZZZZ | 6,5   | cycle mensuel

 5. JOURNAUX — politique et recherches
    Persistance activee / auth : 12 mois / erreurs : 3 mois / debug : 7 jours
    Recherche 1 : tentatives echouees repetees (comptage par compte)
    Recherche 2 : commandes d'administration depuis 24 heures
    Recherche 3 : comptes crees ou ajoutes a sudo depuis 30 jours

 6. REPONSE A UN INCIDENT — six etapes
    preparer / isoler / preserver / investiguer / eradiquer-restaurer / capitaliser
```

Les trois dernières parties complètent la fiche. La quatrième liste les correctifs en attente, classés par score de sévérité et par exposition réelle du service, avec une échéance chiffrée pour chacun : c'est ici que le barème de la section mise à jour devient un calendrier. La cinquième décrit la politique de conservation des journaux et consigne, sous forme de commentaires, les trois recherches que vous exécuterez chaque semaine avec leurs résultats attendus. La sixième rappelle la procédure de réponse en six étapes, avec le nom de la personne à prévenir en premier et l'emplacement du serveur central. Une fiche complète se reconnaît à ce détail : elle contient des dates, des noms et des preuves de contrôle, jamais des intentions.

Avant de rendre le document, passez-le à la liste de contrôle suivante. Vérifiez que chaque service listé à l'inventaire porte une décision motivée ; que chaque commande de désactivation est suivie de la mention du contrôle post-redémarrage ; que la matrice ne contient aucune case vide ; que chaque correctif porte un score et une échéance ; que la durée de conservation est chiffrée pour chaque type de journal ; que les trois recherches sont exprimées avec la commande exacte et ce qu'elles doivent trouver ; que la procédure d'incident nomme des personnes et non des rôles abstraits. Relisez enfin le document à voix haute : s'il vous oblige à chercher une information manquante, un collègue perdra le même temps, et il est encore temps de le compléter.

- Établissez la fiche dans l'ordre des couches : inventaire, services, droits, correctifs, journaux, incident.
- Joignez à chaque décision la preuve du contrôle effectué après application.
- Exprimez la matrice des droits en tableau, une ligne par ressource.
- Chaque correctif porte un score de sévérité et une échéance datée.
- Chaque durée de conservation est chiffrée et justifiée par une question à traiter.
- Désignez par leur nom la personne prévenue en premier et celle de secours.
$lesson$),
  ('cyb-c4-p13', 'cyb-c4', 13, $lesson$À retenir$lesson$, $lesson$
- Un système livré par le fabricant est ouvert par conception : l'écart entre ce qu'il sait faire et votre usage constitue votre surface d'attaque.
- La pile de durcissement suit un ordre : inventaire, mise à jour, durcissement, journalisation, détection, surveillance.
- Une CVE identifie une faille ; le score CVSS l'évalue de zéro à dix ; votre décision combine ce score avec l'exposition réelle du service.
- Traitez en priorité les failles critiques sur un service exposé, sous quarante-huit heures, et consignez chaque report motivé.
- On ne durcit pas ce qu'on ne connaît pas : ports à l'écoute, services en fonctionnement, paquets installés, comptes et tâches planifiées.
- Chaque service retiré se vérifie par la disparition de sa ligne après redémarrage, pas par le souvenir de la commande.
- Trois comptes aux rôles distincts rendent possibles la restriction des droits comme l'imputation des actes.
- Les règles d'élévation accordent des commandes nommées, jamais un interpréteur sans restriction, et chaque élévation est journalisée.
- Le tableau rwx distingue lecture, écriture et exécution selon qu'on regarde un fichier ou un répertoire, où l'exécution signifie la traversée.
- Un guide de référence publié par un organisme reconnu vaut mieux qu'une recette anonyme, à condition de consigner ses écarts volontaires.
- Le chiffrement protège les données au repos et impose une présence physique au redémarrage ; la clé ne voyage jamais avec les données.
- La règle des trois exemplaires, deux supports et un exemplaire hors site s'applique à toute sauvegarde, chiffrée elle aussi.
- Activez la persistance du journal, fixez une durée de conservation chiffrée par type de journal et vérifiez l'espace réel consommé.
- Trois recherches hebdomadaires suffisent au premier niveau : tentatives d'authentification, commandes d'administration, comptes créés.
- Centralisez les journaux sur une machine que l'incident ne contrôle pas et synchronisez toutes les horloges.
- La réponse suit six étapes : préparer, isoler, préserver, investiguer, éradiquer et restaurer, capitaliser.
- On isole en débranchant, on ne répare pas un système compromis, on le reconstruit à partir d'une image de référence.
$lesson$),
  ('cyb-c4-p14', 'cyb-c4', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : durcir un poste sans en avoir dressé l'inventaire au préalable. Correction : relevez systématiquement ports, services, paquets et comptes, puis agissez sur ce relevé daté.
- Piège : repousser un correctif critique au motif que la machine fonctionne. Correction : appliquez-le sous quarante-huit heures ou coupez l'exposition du service le temps de l'installer.
- Piège : confondre une mise à jour et une mise à niveau, et provoquer une incompatibilité la veille d'un événement. Correction : testez sur un poste de staff et planifiez sur une fenêtre de maintenance.
- Piège : désactiver un service sans vérifier ses dépendances. Correction : identifiez ce qui le réclame, arrêtez d'abord, redémarrez, puis empêchez le démarrage.
- Piège : s'authentifier en direct avec le compte d'administration pour la consultation quotidienne. Correction : utilisez un compte de staff et élevez les privilèges uniquement pour la tâche concernée.
- Piège : accorder un interpréteur sans restriction dans les règles d'élévation. Correction : nommez les commandes nécessaires et éditez le fichier avec l'outil dédié.
- Piège : appliquer des permissions sans avoir corrigé le propriétaire et le groupe. Correction : corrigez d'abord l'origine, ajustez ensuite les droits, puis fixez un masque de création.
- Piège : copier intégralement un guide de durcissement sans adapter ni justifier. Correction : appliquez les items pertinents pour votre usage et consignez chaque écart avec sa raison.
- Piège : laisser le journal uniquement en mémoire et le perdre au redémarrage. Correction : activez le stockage persistant et vérifiez l'espace disque occupé après une semaine.
- Piège : ne conserver les journaux que quelques jours, alors que l'incident se découvre après plusieurs semaines. Correction : gardez douze mois les journaux d'authentification et d'administration.
- Piège : lire un journal isolément, sans le croiser avec les autres indices. Correction : rapprochez adresses, heures, comptes et commandes avant de conclure.
- Piège : éteindre ou nettoyer un poste suspect dès le signalement. Correction : isolez en débranchant, photographiez, préservez, puis investiguez.
- Piège : réparer un système compromis au lieu de le reconstruire. Correction : restaurez à partir d'une image de référence connue propre, puis changez les mots de passe depuis une machine saine.
- Piège : produire une fiche de durcissement pleine d'intentions mais sans preuves. Correction : joignez à chaque décision la date, la commande et le résultat du contrôle.
$lesson$),
  ('cyb-c4-p15', 'cyb-c4', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La première source à garder en favori reste la base nationale des vulnérabilités, consultable à l'adresse https://nvd.nist.gov : chaque CVE y est décrite avec son score de base, sa chronologie de publication et les références qui l'accompagnent. Prenez l'habitude d'y vérifier un identifiant avant de paniquer à la lecture d'un titre alarmant, et inversement de vérifier qu'un paquet que vous différez ne correspond pas à une faille déjà active. À côté de cette base internationale, suivez les annonces de sécurité de votre distribution : sous Debian, le suivi officiel est publié sur www.debian.org, et sous Ubuntu, les bulletins et le calendrier de publication des correctifs sont disponibles sur ubuntu.com. Ces deux circuits vous disent non seulement ce qui est corrigé, mais quand le correctif est réellement disponible pour votre version.

Deuxième axe d'approfondissement : les guides de durcissement. Les ensembles de règles du Center for Internet Security, référencés sous l'acronyme CIS, structurent chaque recommandation en justification, vérification et remédiation, et constituent le format le plus utile pour construire vos propres fiches. Côté français, les guides publiés par l'Agence nationale de la sécurité des systèmes d'information, souvent désignée par son acronyme ANSSI, détaillent les mesures de durcissement et les politiques de journalisation adaptées aux organisations publiques. Feuilletez-les plutôt que de les lire d'un bout à l'autre, et revenez-y au moment où une question précise se pose sur un poste précis.

Troisième axe, la lecture des journaux : elle s'apprend à force d'exemples. Les dossiers de référencement et de sécurité publient des catalogues de motifs d'attaque décrits en langage naturel, avec les traces que chaque type d'attaque laisse derrière lui ; le projet OWASP, consultable à l'adresse https://owasp.org, reste la référence en matière de listes de risques et de bonnes pratiques, y compris pour ce qui touche aux applications web qui hébergent votre catalogue. Enfin, pratiquez : reprenez un journal de test, inventez une histoire plausible, cherchez les lignes qui la racontent. C'est en cherchant une trace que vous finissez par la voir spontanément, et c'est cette seconde nature qui fait la différence le jour du signalement.
$lesson$),
  ('cyb-c4-p16', 'cyb-c4', 16, $lesson$Et maintenant : transformer la fiche en habitude$lesson$, $lesson$
Vous disposez à présent d'une méthode complète : connaître ce qui tourne, mettre à jour ce qui tourne, restreindre ce qui reste, chiffrer ce qui dort, journaliser ce qui se passe et lire ce qui est écrit. L'exercice pratique qui suit cette leçon vous demandera de rédiger seul la fiche de durcissement du poste d'accueil, sans vous référer à l'exemple guidé : c'est à ce moment-là que vous mesurerez ce que vous avez réellement retenu de la lecture d'un score CVSS, du tableau des permissions et des trois recherches hebdomadaires. Le quiz de quatre questions qui accompagne le chapitre vous permet, en quelques minutes, de vérifier les notions essentielles avant de vous lancer.

Passé cet exercice, deux habitudes valent mieux que toutes les autres, et elles tiennent en deux rendez-vous récurrents. Le premier est mensuel : une heure pour les mises à jour, l'inventaire et les comptes. Le second est hebdomadaire : dix minutes pour relire les trois recherches dans les journaux et vérifier qu'aucune ligne ne dépasse le seuil que vous avez fixé. Un parc durci n'est pas un parc figé, c'est un parc que l'on reprend régulièrement, et la régularité fait plus pour sa sécurité que n'importe quel outil acheté. Le chapitre suivant du parcours vous montrera comment surveiller automatiquement ces mêmes signaux, à l'échelle de tout un réseau, sans dépendre d'une relecture manuelle : la base que vous venez de poser servira exactement à cela.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('cyb-c5-p1', 'cyb-c5', 1, $lesson$L'OWASP Top 10 : ce que c'est et comment s'y repérer$lesson$, $lesson$
Bienvenue dans le cinquième chapitre du parcours Cybersécurité, consacré à la sécurité applicative : tout ce qui peut se passer lorsque vos propres lignes de code deviennent la porte d'entrée d'un visiteur indésirable. Jusqu'ici, votre réflexe portait sur des choses extérieures au programme : un pare-feu mal réglé, un mot de passe trop court, un poste laissé déverrouillé. Désormais, vous tournez le regard vers l'intérieur, vers les fichiers que vous écrivez, les requêtes que vous formez, les champs que vous acceptez sans les relire. La faille n'est alors plus une configuration oubliée : c'est une chaîne concaténée à la va-vite, un tableau de bord dont l'adresse change à peine, une session dont le jeton n'est lié à rien. Le site fonctionne et plaît à vos utilisateurs ; la question du chapitre est de savoir ce qu'il fait quand quelqu'un va plus loin que le parcours normal.

La bonne nouvelle, c'est que tout ce que vous allez apprendre tient dans un nombre limité de mécanismes, et qu'ils se ressemblent tous : un endroit où un programme confond ce qu'il manipule avec ce qu'il exécute, un endroit où l'on fait confiance à quelque chose qui ne la mérite pas. Injection SQL, injection de commandes, XSS, CSRF, validation de saisie, erreurs, mots de passe, fichiers, journaux : chaque cas de ce chapitre est une variante de ces deux phrases. On ne mémorise donc pas des recettes, on se forge un réflexe : devant chaque donnée qui entre, se demander ce qu'un visiteur malveillant pourrait en faire. Nous avancerons par étapes, en alternant explications et exemples commentés défensivement : ils sont réduits pour que vous compreniez le mécanisme, pas pour que vous le répétiez.

Le fil rouge de la leçon est un site concret, celui de la Médiathèque des Lilas, dont vous avez rencontré les pages dans les chapitres précédents du parcours web. Il possède un formulaire d'inscription aux ateliers, un moteur de recherche de titres, un espace de dépôt de documents et un espace administrateur où le personnel valide les inscriptions. C'est un site modeste, exactement le genre que construit la majorité des développeurs, et c'est pour cela qu'il est parfait : il concentre, en quelques écrans, la quasi-totalité des pièges du chapitre. Le formulaire reçoit du texte qui partira en base, la recherche renvoie du texte affiché, le dépôt accepte des fichiers, l'administrateur déclenche des actions sensibles. Chaque section prendra un de ces morceaux, montrera ce qui ne va pas, puis la parade, puis la version corrigée. À la fin, vous auditerez le formulaire d'inscription dans le mini-projet guidé.

Une dernière recommandation avant d'entrer dans le vif du sujet : la sécurité se pratique comme un instrument, pas comme une lecture. Recopiez chaque exemple, modifiez-le, faites-le échouer, puis rétablissez la parade et observez que l'attaque disparaît. Essayez un champ vide, un champ trop long, un champ contenant des guillemets : votre application doit réagir de manière prévisible dans chaque cas. Le moment le plus rentable pour penser sécurité est celui où l'on écrit le code, non celui où l'on répare l'incident. Gardez enfin l'idée qui traverse toutes les sections : ne jamais laisser une donnée changer de rôle entre son entrée et son usage.



L'OWASP signifie Open Web Application Security Project, une association internationale sans but lucratif qui publie gratuitement une documentation produite par une communauté de praticiens, d'auditeurs et de chercheurs. Parmi ses publications, la plus connue est le Top 10, un classement des failles applicatives les plus fréquemment observées dans le monde réel. Ce classement n'est ni une norme, ni une certification : c'est un outil de priorisation et un langage commun. Quand un responsable annonce en réunion qu'un point relève de l'accès contrôlé ou de l'injection, tout le monde sait de quoi on parle, quel que soit le langage utilisé. Le Top 10 sert à créer ce vocabulaire et à indiquer où concentrer l'effort quand le temps manque.

Sa force vient de la méthode de constitution : les catégories sont établies à partir de retours d'expérience anonymisés, d'analyses de correctifs et d'enquêtes menées auprès d'équipes qui corrigent des incidents quotidiennement. Une faible proportion de causes produit la majorité des compromissions, et c'est cette concentration qui rend un tableau de dix entrées utile. Attention toutefois à ce qu'il ne dit pas : le classement ne couvre pas tout et ne remplace pas l'analyse de votre propre modèle de menace. Un projet conforme au Top 10, mais dont les champs sont concaténés dans une requête et les pages d'erreur affichent la trace d'une exception, reste compromettable en quelques secondes.

Les grandes entrées du dernier référentiel publié s'ordonnent autour de thèmes qui vous deviendront familiers au fil du chapitre : le contrôle d'accès insuffisant, c'est-à-dire l'impossibilité de prouver que l'utilisateur est réellement autorisé à l'action demandée ; les défaillances cryptographiques, algorithmes faibles, clés mal protégées, données envoyées en clair ; l'injection, qui regroupe l'injection SQL, l'injection de commandes et les injections vers d'autres interpreteurs ; les failles de conception, apparues quand on n'a jamais imaginé un scénario d'abus ; puis les mauvaises configurations, les composants périmés, les défaillances d'authentification, l'insuffisance des journaux et la falsification de requête côté serveur. Vous reconnaîtrez ces mots-clés dans les sections suivantes.

Comment s'y repérer concrètement, sur votre propre code ? En trois temps. Dressez l'inventaire des points où de l'information extérieure entre dans le programme : champs de formulaire, paramètres d'adresse, en-têtes HTTP, fichiers déposés, appels d'interface. Pour chaque point d'entrée, tracez la donnée jusqu'à sa destination finale, qui est presque toujours l'une de quatre : une requête vers une base, une commande système, un affichage dans une page, un appel vers un autre service. Appliquez enfin la parade correspondante à ce croisement précis. Vous venez de décrire la méthode d'un auditeur professionnel : il ne lit pas tout le code à la recherche d'un bug, il cherche les endroits où une donnée change de nature.

Le tableau suivant résume le croisement entre les points d'entrée, les destinations dangereuses et les parades qui font le cœur de ce chapitre. Gardez-le sous la main pendant votre relecture : il vous servira de filtre chaque fois que vous hésiterez sur la marche à suivre.

| Destination de la donnée | Ce qui peut se passer sans parade | Parade principale |
| --- | --- | --- |
| Requête vers la base de données | Lecture ou modification non autorisée des données | Requêtes paramétrées, liste blanche pour les identifiants |
| Commande système | Exécution d'actions arbitraires sur le serveur | Arguments passés en liste, aucune interpolation dans un shell |
| Affichage dans une page | Exécution de script dans le navigateur d'un autre utilisateur | Échappement adapté au contexte, politique de sécurité de contenu |
| Formulaire soumis par un autre site | Action sensible déclenchée sans consentement | Jeton lié à la session, vérification de l'origine |
| Fichier déposé | Remplacement de fichier, exécution, inclusion distante | Liste blanche d'extensions, nom aléatoire, stockage hors racine |
| Message d'erreur | Fuite de schéma, de chemins et de versions | Message générique côté utilisateur, détail dans les journaux |
| Journal d'activité | Fuite de données personnelles | Masquage des données sensibles, accès restreint |

Le flux normal d'un formulaire d'inscription illustre parfaitement l'enjeu. Voici ce que voit un visiteur honnête, puis ce que voit un attaquant qui remplace la valeur attendue par autre chose, et voici comment le même flux se comporte une fois les parades en place. Les deux schémas suivants, dessinés en texte, montrent le trajet complet d'une donnée de la page du formulaire jusqu'à la table de la base.

```text
SANS PARADE — la donnée et l'instruction sont mélangées

  page du formulaire              serveur                         base
  ------------------              ------                          ----
  champ "nom"  =  saisi librement
        |
        |  POST /inscription
        v
  [ concaténation de chaînes ]  --->  SELECT * FROM inscriptions
        |                              WHERE nom = '<valeur>'
        |                                        |
        |  la valeur peut fermer les quotes      |
        |  et ajouter une instruction            v
        |                              [ exécution de la requête
        |                                telle qu'elle arrive ]
        |
  résultat : le visiteur obtient une page, l'attaquant obtient
  la possibilité d'interroger ou de modifier d'autres tables

AVEC PARADE — la donnée ne peut pas devenir une instruction

  page du formulaire              serveur                         base
  ------------------              ------                          ----
  champ "nom"  =  saisi librement
        |
        |  POST /inscription
        v
  [ validation de type et de longueur ]
        |
        v
  [ requête préparée : instruction fixe ]  --->  instruction SQL
  [ valeur transmise à part ]             --->  paramètre de donnée
                                                    |
                                                    v
                                          [ exécution : la base
                                            traite le paramètre
                                            comme une donnée seule ]
  résultat : quelle que soit la valeur reçue, le programme
  exécute exactement la même instruction SQL
```

Appliquons ce découpage au site de la médiathèque. Le formulaire d'inscription reçoit un nom, une adresse électronique et le choix d'une session : ces valeurs finiront dans une table, donc de la première ligne. La recherche de titres renvoie un mot-clé affiché dans la page de résultats : donc de la troisième ligne. L'espace de dépôt accepte un fichier, donc de la cinquième ; L'espace administrateur modifie l'état du site, donc de la quatrième ligne. En quelques instants, vous avez cartographié l'application : c'est le travail à refaire en tête de chaque nouveau projet.

```text
Cartographie express d'une application web — Médiathèque des Lilas

  point d'entrée                 destination finale           risque dominant
  -------------                  ------------------           ---------------
  /inscription (formulaire)  ->  table inscriptions       ->  injection SQL
  /recherche  (mot-clé)      ->  HTML de la page          ->  XSS
  /admin/valider (action)    ->  modification d'état      ->  CSRF + accès
  /admin (page protégée)     ->  session de l'administrateur -> accès direct
  /depot (fichier)           ->  disque du serveur        ->  upload dangereux
  toute erreur technique     ->  écran de l'utilisateur   ->  fuite d'info
```

Classer ses risques ne les traite pas : la cartographie ci-dessus vous dit où regarder, mais elle ne dit pas ce que votre framework fait déjà à votre place. La seule manière de le savoir est de tester le comportement réel de l'application, en modifiant une valeur à la main et en observant ce qui arrive.
$lesson$),
  ('cyb-c5-p2', 'cyb-c5', 2, $lesson$Injection SQL : mécanisme et parade avec les requêtes paramétrées$lesson$, $lesson$
L'injection SQL est la plus ancienne et la plus redoutable des failles applicatives, parce qu'elle exploite une propriété fondamentale des bases de données : pour le moteur, une requête reçue est un programme, et aucun marqueur ne distingue, dans la chaîne reçue, la partie exécutée de la partie traitée comme une donnée. Si votre programme construit cette chaîne en additionnant des morceaux, vous confiez au visiteur le soin d'écrire une partie de votre programme. Le champ de recherche de la médiathèque est l'exemple canonique : on y écrit un mot, le serveur assemble la requête, la base répond. Le jour où quelqu'un écrit autre chose qu'un mot, l'assemblage continue de la même manière, parce que le programme ne fait qu'une opération mécanique de collage.

Le point essentiel est que la faille ne vient pas d'un bug de la base, mais d'une erreur de conception de votre code : la base exécutera toujours fidèlement l'instruction qu'elle reçoit, et si cette instruction a été modifiée par une valeur venue du visiteur, elle obéit à l'instruction modifiée. D'où l'intuition définitive : le seul moyen robuste de supprimer le risque est d'empêcher toute valeur de participer à la rédaction de l'instruction. C'est ce que fait la requête paramétrée, et c'est la parade à appliquer systématiquement, y compris dans les scripts jetables, parce que les scripts jetables finissent souvent en production.

```python
# Version vulnérable : la valeur est collée dans le texte de la requête.
# Ce que verrait un attaquant : une valeur qui ferme la chaîne et ajoute
# une condition toujours vraie, puis récupère des comptes qu'il n'a pas
# le droit de voir. L'exemple est volontairement réduit et commenté.
motcle = champ_recherche_de_l_utilisateur
requete = "SELECT titre, auteur FROM catalogue WHERE titre LIKE '%" + motcle + "%'"
curseur.execute(requete)

# La parade : l'instruction est fixe et écrite à l'avance, la valeur
# est transmise séparément par l'intermédiaire du moteur de requêtes.
motcle = champ_recherche_de_l_utilisateur
requete = "SELECT titre, auteur FROM catalogue WHERE titre LIKE %s"
curseur.execute(requete, ("%" + motcle + "%",))
```

La différence tient à un argument supplémentaire, et pourtant elle est totale. Dans la première version, la chaîne contient déjà la valeur au moment où elle est envoyée : si elle contient un guillemet, elle rompt la chaîne et tout ce qui suit devient du code exécuté. Dans la seconde, la chaîne envoyée au moteur ne contient qu'un jeton de remplacement, et la valeur part par un canal distinct, dans les métadonnées de la requête. Le moteur la reçoit et la traite, quelle que soit sa teneur, comme une donnée : il n'y a plus de chaîne à rompre, donc plus de confusion possible. Le programme, lui, ne change jamais : la requête est identique à chaque exécution, seule la valeur varie.

Le trajet de la donnée, sans puis avec la parade, se dessine ainsi entre le formulaire et la table :

```text
Formulaire de recherche "titre"  ->  parcours sans parade

  utilisateur ----> [ champ texte ]
                        |
                        v
                 [ concaténation avec le texte SQL ]
                        |
                        v
                 [ envoi d'une chaîne complète ]
                        |
                        v
                   moteur SQL  --->  catalogue / inscriptions / comptes
                        |
                 l'instruction et la donnée
                 sont indiscernables


Formulaire de recherche "titre"  ->  parcours avec requête paramétrée

  utilisateur ----> [ champ texte ]
                        |
                        v
                 [ validation : type texte, longueur maximale ]
                        |
                        v
                 [ instruction SQL fixe, écrite par le développeur ]
                        |
                        +----> valeur ------> canal de données
                        |
                        +----> instruction --> canal d'instruction
                                                |
                                                v
                                           moteur SQL
                                    la valeur reste une donnée,
                                    quelle qu'elle soit
                                                |
                                                v
                                        résultat attendu uniquement
```

Les moteurs et leurs bibliothèques exposent tous ce mécanisme, avec des syntaxes de remplacement différentes : le point d'interrogation dans les connecteurs les plus courants, le signe de dollar suivi d'un numéro pour PostgreSQL, la virgule de nommage dans quelques ORM. Retenez le principe plutôt que la lettre : il existe un séparateur entre le texte de l'instruction et la valeur, et vous devez toujours passer par ce séparateur. Une recherche dans la documentation de votre connecteur confirme la syntaxe exacte ; ce qui ne varie jamais, c'est l'habitude de ne jamais construire une requête par addition de chaînes.

```python
# Placeholders : la même intention, deux syntaxes courantes de connecteurs.
# Le principe ne change jamais : instruction fixe + valeur transmise à part.

# style point d'interrogation
curseur.execute("SELECT id FROM comptes WHERE courriel = ?", (courriel,))

# style nommé
curseur.execute("SELECT id FROM comptes WHERE courriel = :courriel",
                {"courriel": courriel})
```

Il existe un cas où la requête paramétrée ne suffit pas à elle seule, et il est fréquent à la médiathèque : le tri des résultats et la pagination. On ne peut pas transmettre un identifiant de colonne en paramètre de données, car la base doit connaître le nom de la colonne avant de traiter une valeur. La parade est alors la liste blanche : le programme n'accepte que les valeurs qu'il a lui-même définies. Si le visiteur demande le tri par titre, il choisit la colonne titre ; sinon, il retombe sur le tri par défaut. Toute autre approche, y compris le filtrage de mots interdits, est vouée à l'échec : une liste noire ne sera jamais aussi complète que la grammaire du langage de requêtes.

```python
# Identifiant de colonne : impossible à paramétrer, on utilise une liste blanche.
# Ce que verrait un attaquant : un champ de tri qui contient autre chose
# qu'un nom de colonne, par exemple une instruction complète.
tri_demande = requete_get.get("tri", "titre")

COLONNES_AUTORISEES = {
    "titre": "titre",
    "auteur": "auteur",
    "annee": "annee_de_publication",
}

# La parade : la valeur entrante sert uniquement de clé de recherche
# dans un dictionnaire défini par le développeur. Si elle n'y figure pas,
# le programme utilise la valeur par défaut.
colonne = COLONNES_AUTORISEES.get(tri_demande, "titre")
requete = f"SELECT titre, auteur FROM catalogue ORDER BY {colonne} ASC"
```

Deux compléments ferment cette section. Le premier concerne les privilèges du compte de base utilisé par l'application : un compte limité aux tables dont il a réellement besoin rend une injection aboutie beaucoup moins rentable. Le second concerne les messages d'erreur : afficher au visiteur l'erreur du moteur revient à lui livrer le schéma, les noms de colonnes et parfois l'extrait de requête qui a échoué. La base doit parler à vos journaux, jamais à vos écrans.

Enfin, les ORM et les frameworks construisent-ils des requêtes paramétrées à votre place ? Dans la grande majorité des cas, oui, mais la sortie de route reste possible : requêtes brutes exécutées à la main, chaînes formatées passées à une fonction d'exécution, utilitaires qui acceptent des fragments de requête. Vérifiez ce que produit votre couche d'accès aux données en activant la journalisation des requêtes sur un environnement de test, puis regardez si la valeur apparaît dans l'instruction envoyée. Une fois cette différence vue sur votre propre écran, vous ne referez plus jamais autrement.
$lesson$),
  ('cyb-c5-p3', 'cyb-c5', 3, $lesson$Injection de commandes : quand votre code parle au système d'exploitation$lesson$, $lesson$
La deuxième grande famille d'injection se produit lorsque votre application doit accomplir une tâche que le langage ne sait pas faire seul : convertir une image, compresser un dossier, interroger un service externe, exporter un rapport en PDF. On appelle alors souvent le système d'exploitation, qui reçoit lui aussi une instruction sous forme de texte et ne peut pas distinguer, dans celle-ci, la partie que vous avez écrite de la partie qui provient du visiteur. L'injection de commandes est le même mécanisme que l'injection SQL, appliqué à un autre interpreteur, avec une conséquence souvent plus grave : au lieu de toucher aux données, on exécute des actions sur la machine.

En Python, le cas le plus cité est la fonction os.system, qui prend une chaîne de caractères et la confie à l'interpréteur de commandes de la machine : commode pour un script personnel, c'est un piège dès que la chaîne contient une trace de donnée venant de l'extérieur. Le danger vient des métacaractères, ces symboles que l'interpréteur interprète comme des instructions : fin de chaîne, séparation entre commandes, exécution enchaînée, remplacement par la sortie d'une autre commande. Un visiteur qui les maîtrise n'a pas besoin de comprendre votre programme : il lui suffit de fermer la chaîne que vous avez commencée, exactement comme dans le cas SQL.

```python
import os

# Version dangereuse : le nom du fichier fourni par l'utilisateur est collé
# dans une chaîne qui part vers l'interpréteur de commandes.
# Ce que verrait un attaquant : un nom de fichier qui contient un séparateur
# de commandes et fait ainsi exécuter une seconde commande à votre place.
nom = champ_nom_fichier_de_l_utilisateur
os.system("convert --resize 800 " + nom + " /var/www/thumb/" + nom)

# La parade : aucun passage par l'interpréteur de commandes.
# Les arguments sont transmis sous forme de liste, chacun est préservé
# comme une valeur, y compris s'il contient des métacaractères.
import subprocess
subprocess.run(
    ["convert", "--resize", "800", nom, "/var/www/thumb/" + nom],
    check=True,
    shell=False,
)
```

La parade repose sur trois gestes qui se complètent. Ne construisez jamais une commande à partir de fragments : appelez la fonction avec une liste d'arguments séparés, et la bibliothèque transmet chacun d'eux sans qu'aucun symbole ne soit réinterprété. Forcez ensuite l'absence d'interpréteur de commandes ; dès que cette option bascule, votre liste d'arguments est de nouveau traitée comme du texte à interpréter et la parade disparaît. Enfin, ne laissez jamais une valeur entrante désigner un chemin, un nom d'hôte ou un drapeau : un argument qui commence par un tiret devient une option, et un chemin peut viser n'importe quel fichier lisible par le processus.

Il est utile de déplacer la réflexion sur un terrain plus concret, car les injections de commandes se cachent rarement là où on les cherche. Le site de la médiathèque génère une archive d'inscriptions, appelle un outil externe pour produire un rapport PDF, lance un utilitaire de métadonnées sur les photos déposées ou convertit un document reçu. Chacun de ces appels est légitime ; le risque naît du fait que le nom du fichier, le titre de l'atelier ou le chemin du dépôt soit inséré dans la chaîne. Un appel dont tous les éléments sont fixés par le développeur n'est pas vulnérable : c'est l'entrée d'une donnée externe dans la commande qui crée le risque.

Les protections de fond complètent le passage en liste d'arguments. Limitez la durée d'exécution de chaque appel et interrompez ce qui dépasse. Faites tourner ces appels sous un compte dédié, qui ne dispose que des droits nécessaires à la tâche, de sorte qu'un appel détourné ne puisse ni réécrire votre code ni lire la base. Refusez enfin les noms de fichiers qui ne correspondent pas à l'expression simple définie par le programme. Ces mesures ne remplacent pas la parade principale, mais elles transforment un incident potentiellement critique en tentative anodine et détectable.

```python
# Contrôle des entrées avant tout appel système, dans l'esprit du site.
# On valide la forme, on impose une taille, puis on n'utilise jamais
# la valeur pour écrire une commande : seulement comme argument.

import re
import subprocess
from pathlib import Path

NOM_VALIDE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")
RACINE_DEPOT = Path("/var/mediatheque/depots")

def regenerer_vignette(nom_recu: str) -> None:
    if not NOM_VALIDE.fullmatch(nom_recu):
        raise ValueError("nom de fichier invalide")
    source = RACINE_DEPOT / nom_recu
    if not source.resolve().is_relative_to(RACINE_DEPOT.resolve()):
        raise ValueError("chemin hors zone autorisée")
    subprocess.run(
        ["convert", str(source), "-resize", "800x800", str(source) + ".thumb"],
        check=True,
        shell=False,
        timeout=30,
    )
```

Pour repérer ces appels dans un code existant, cherchez les fonctions qui prennent une chaîne et la confient à l'extérieur : elles constituent un point de contrôle prioritaire dans votre relecture, et il n'en faut qu'un seul, dans un script d'administration oublié, pour que tout le site soit concerné.
$lesson$),
  ('cyb-c5-p4', 'cyb-c5', 4, $lesson$XSS : stocké, réfléchi ou DOM, trois variantes d'un même malentendu$lesson$, $lesson$
Le sigle XSS signifie Cross-Site Scripting, ce qui se traduit par exécution de script transverse. Le principe tient en une phrase : votre site affiche un texte que quelqu'un a su modifier pour qu'il contienne du code exécutable par le navigateur. Celui-ci ne distingue pas le script émis par le serveur du site du script glissé dans un champ : les deux arrivent dans la même page, sous la même origine, avec les mêmes droits. Les conséquences sont donc celles du visiteur : lecture du jeton de session, exécution d'actions au nom de la personne connectée, dégradation de la page, redirection. Le XSS n'attaque pas votre base de données, il attaque vos utilisateurs, ce qui le rend grave et difficile à détecter depuis l'extérieur.

On distingue trois variantes, qui se dépistent et se corrigent différemment. Le XSS réfléchi, ou reflected, survient quand une valeur reçue dans la requête est renvoyée dans la réponse sans traitement : la recherche de la médiathèque, qui affiche le mot-clé tapé, est exactement ce cas. Le XSS stocké, ou stored, survient quand la valeur est enregistrée, dans un commentaire, un nom d'atelier ou un profil, puis servie à d'autres personnes : c'est la variante la plus redoutable, car la charge utile attend sa prochaine victime. Le XSS de type DOM, enfin, ne transite pas nécessairement par le serveur : votre code JavaScript lit une valeur dans l'adresse de la page ou le stockage local, puis l'écrit sans la traiter. Le serveur n'y voit rien, et pourtant le script s'exécute.

```html
<!-- Version fragile : le texte du visiteur est inséré dans la page
     tel quel. Ce que verrait un attaquant : un champ de nom ou de
     commentaire contenant une balise de script, qui sera exécutée
     par le navigateur de la prochaine personne ouvrant la page. -->
<h3>Inscription de {{ visiteur.nom }}</h3>

<!-- La parade côté gabarit : échappement automatique activé.
     Le même contenu est alors affiché comme du texte et non
     interprété comme du code. -->
<h3>Inscription de {{ visiteur.nom | escape }}</h3>

<!-- Piège DOM : une valeur lue dans l'adresse puis écrite dans la page
     sans traitement. La parade consiste à écrire du texte, pas du HTML. -->
<script>
  // Fragile : interprète la valeur comme du balisage
  zoneResultat.innerHTML = new URLSearchParams(location.search).get("q");
  // Parade : la même valeur devient un nœud texte, jamais du code
  zoneResultat.textContent = new URLSearchParams(location.search).get("q");
</script>
```

La parade universelle est l'échappement, mais il ne s'écrit pas de la même manière selon l'endroit où la valeur se trouve. C'est le point que la plupart des relectures oublient : remplacer un guillemet par une entité, correct dans un contenu de page, ne suffit pas dans un attribut, dans une chaîne de script ou dans une adresse. Le tableau suivant donne le réflexe à acquérir, contexte par contexte, avec la parade correspondante ; imprimez-le mentalement, il vous servira chaque fois que vous insérerez une donnée entrante dans un gabarit.

| Contexte d'insertion | Ce qui peut se passer | Parade adaptée |
| --- | --- | --- |
| Corps d'un élément HTML | Interprétation du balisage injecté | Échappement des quatre caractères réservés |
| Valeur d'un attribut | Rupture d'attribut et ajout d'événement | Échappement des guillemets, attribut entre guillemets doubles |
| Bloc de script | Fin de chaîne et exécution d'instruction | Ne jamais insérer de donnée ici, serializer en JSON |
| Adresse ou paramètre d'URL | Fabrication de fausses destinations | Encodage des pourcentages, liste blanche des destinations |
| Feuille de style | Affectation d'une URL ou d'une expression | Ne jamais concaténer de donnée dans du style |
| Attribut d'URL type href | Javascript trois points deux points ou fausse destination | Liste blanche des protocoles autorisés |

L'exemple suivant montre l'opération côté serveur : chaque caractère qui pourrait ouvrir du balisage devient sa représentation textuelle, et les gabarits modernes l'appliquent automatiquement tant qu'on ne les a pas désactivés.

```python
from html import escape

# Échappement d'un contenu inséré dans le corps d'un élément.
# Les caractères qui pourraient ouvrir un balisage deviennent
# leur représentation textuelle et perdent tout sens pour le navigateur.
def afficher_nom(nom: str) -> str:
    # On limite aussi la longueur : la sécurité n'empêche pas l'économie
    return escape(nom[:80], quote=True)

# Dans un attribut, le même échappement est complété par des guillemets
# doubles, pour qu'aucune valeur ne puisse rompre l'attribut.
def attribut_titre(titre: str) -> str:
    return escape(titre[:120], quote=True)

# Interdiction : insérer une donnée entrante dans un bloc de script.
# La seule méthode sûre est d'écrire la donnée ailleurs, puis de la
# lire depuis le DOM, ou de la sérialiser en JSON avec sérialisation stricte.
```

La seconde ligne de défense est la politique de sécurité de contenu, ou Content Security Policy, un en-tête HTTP que votre serveur envoie avec chaque page et qui indique au navigateur quels types de ressources il accepte d'exécuter. Elle ne corrige pas l'absence d'échappement, mais elle réduit radicalement la portée d'une faille : un script injecté qui parviendrait à s'insérer dans la page ne s'exécuterait pas, car il ne proviendrait pas d'une source autorisé. L'en-tête suivant illustre une configuration raisonnable pour un site comme celui de la médiathèque : scripts issus de votre seul domaine, avec une marque de session unique renouvelée à chaque requête, aucune ressource externe, aucun modèle en ligne et aucun connecteur de données depuis la page.

```http
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-4f9c1a7d2e6b8053';
  style-src 'self';
  img-src 'self' data:;
  connect-src 'self';
  font-src 'self';
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  frame-ancestors 'none';
  upgrade-insecure-requests;
```

Trois remarques sur cet en-tête. La marque de session, ou nonce, est une valeur aléatoire différente à chaque réponse : le serveur l'inscrit dans l'en-tête et l'ajoute aux balises de script légitimes, de sorte que le navigateur n'exécute que les scripts porteurs de la marque du moment, qu'un script injecté ne peut pas connaître à l'avance. La directive qui interdit les connecteurs de données empêche un script compromis d'envoyer les informations volées vers un autre domaine. Commencez enfin par la directive de rapport, qui signale les violations sans les bloquer, observez quelques jours, puis basculez en application stricte.

Les cookies méritent une place dans la parade, car c'est par eux que le XSS devient vraiment rentable. L'attribut qui rend un cookie inaccessible au script empêche toute lecture depuis une page, y compris compromise ; celui de même site limite l'envoi automatique aux requêtes issues du même site ; l'exigence de transport chiffré interdit l'envoi en clair. Cette combinaison ne supprime pas l'exécution, mais elle retire la récompense immédiate. Ces mêmes attributs serviront dans la section suivante à bloquer une autre famille d'attaque : la sécurité applicative est affaire de couverture croisée.

```python
# Définition d'un cookie de session verrouillé.
# Trois attributs complémentaires, trois attaques rendues plus difficiles.
import secrets
from http.cookies import SimpleCookie

def emettre_session(reponse) -> None:
    jeton = secrets.token_urlsafe(32)
    cookie = SimpleCookie()
    cookie["sid"] = jeton
    morsure = cookie["sid"]
    morsure["httponly"] = True   # illisible depuis le JavaScript de la page
    morsure["samesite"] = "Lax"  # pas envoyé depuis un autre site en POST
    morsure["secure"] = True     # jamais transmis en clair
    morsure["path"] = "/"
    morsure["max-age"] = 1800    # expiration courte, renouvelée à la connexion
    reponse.headers["Set-Cookie"] = morsure.OutputString()
```

Les bibliothèques d'assainissement de balisage restent utiles quand vous devez réellement accepter du HTML riche, mais elles reposent sur des listes d'autorisations à maintenir et à tester : utilisez-les en dernier recours, avec la configuration la plus restrictive possible.
$lesson$),
  ('cyb-c5-p5', 'cyb-c5', 5, $lesson$CSRF : le formulaire trop confiant et les jetons qui le réparent$lesson$, $lesson$
Le CSRF, ou Cross-Site Request Forgery, exploite une propriété si ordinaire du navigateur qu'on la voit passer : lorsque vous demandez une page, le navigateur joint automatiquement les cookies correspondants au domaine appelé. C'est ce qui vous permet de rester connecté, et c'est exactement ce qu'un site tiers utilise contre vous. Si la médiathèque accepte une action sensible sur la seule base du cookie de session, n'importe quelle page consultée ailleurs peut la déclencher à votre insu : le navigateur joint le cookie, le serveur voit un utilisateur authentifié et exécute. L'utilisateur n'a rien vu, l'action a eu lieu.

L'attaque suppose une session maintenue par cookie, une action qui modifie un état et l'absence de preuve quant à l'origine de la requête : trois conditions que l'attaquant remplit en hébergeant une page qui provoque l'envoi. Le schéma suivant décrit le scénario, réduit à l'essentiel, avec la parade correspondante : la même action, mais assortie d'une preuve que seul le formulaire réel de votre site peut fournir.

```text
Sans jeton — l'action part d'un site tiers mais porte votre cookie

  page tenue par un tiers              navigateur                serveur médiathèque
  ------------------------            ----------                -------------------
  <formulaire invisible,              envoie la requête         reçoit le cookie de
   action vers votre site>    --->    automatiquement     --->  session avec la requête
  <script : soumission auto>          (le cookie voyage)        |
                                                                v
                                                            action exécutée
                                                            sans consentement réel

Avec jeton — la preuve ne peut pas être fabriquée par un tiers

  formulaire réel de votre site       navigateur                serveur médiathèque
  --------------------------------    ----------                -------------------
  champ caché portant un jeton   ---> envoie la requête   ---> vérifie : le jeton
  lié à la session, issu du           avec le cookie             correspond à cette
  serveur                                                          session ?
                                                                    |
                                                          +---------+---------+
                                                          |                   |
                                                        valide            rejetée
                                                      exécutée            403
  page tierce : elle peut envoyer le cookie, mais elle ignore
  le jeton, donc elle ne peut pas fabriquer la preuve
```

Le jeton CSRF est une chaîne aléatoire de longueur suffisante, générée par le serveur, associée à la session et renvoyée dans chaque formulaire sensible sous forme de champ caché. À la réception, le serveur compare la valeur reçue à celle conservée pour cette session, puis rejette si elles diffèrent. Trois propriétés font la solidité du mécanisme : la longueur, qui rend toute devinette impossible ; l'association à la session, qui empêche le détournement d'un jeton volé ailleurs ; l'absence de valeur métier, de sorte qu'un jeton fui n'autorise rien sans le cookie correspondant. La comparaison est stricte et à durée constante, pour ne pas trahir l'information par un temps de réponse variable.

```python
import hmac
import secrets

# Création d'un jeton CSRF pour une session donnée.
# Le jeton est aléatoire, il n'est utile que s'il est comparé à la
# valeur conservée côté serveur pour cette session.
def creer_jeton(session: dict) -> str:
    jeton = secrets.token_urlsafe(32)
    session["csrf"] = jeton
    return jeton

# Vérification à la réception d'une requête qui modifie un état.
def verifier_jeton(session: dict, recu: str | None) -> bool:
    attendu = session.get("csrf")
    if not attendu or not recu:
        return False
    # Comparaison à durée constante : pas de fuite par le temps
    return hmac.compare_digest(attendu, recu)

# Côté gabarit, le jeton part dans un champ caché du formulaire.
# Il est régénéré à chaque affichage du formulaire pour limiter sa durée.
```

Le formulaire de la médiathèque devient alors le suivant : un champ caché rempli par le serveur à l'affichage et vérifié à l'envoi, jamais par le JavaScript de la page.

```html
<form action="/inscription" method="post">
  <input type="hidden" name="csrf_token" value="{{ jeton_csrf }}">
  <label for="nom">Nom complet</label>
  <input type="text" id="nom" name="nom" maxlength="80" required>

  <label for="courriel">Adresse électronique</label>
  <input type="email" id="courriel" name="courriel" maxlength="120" required>

  <button type="submit">Confirmer mon inscription</button>
</form>

<!-- À la réception, le serveur compare la valeur du champ caché
     à celle enregistrée pour la session, puis agit en conséquence. -->
```

Parallèlement au jeton, trois mesures complémentaires réduisent la surface. Toute requête qui modifie un état doit utiliser la méthode adaptée, jamais une simple adresse cliquable : un lien ne porte qu'une requête de lecture, et changer un état par lien dans un courriel est un défaut de conception autant qu'une faille. L'attribut de cookie dit stricte supprime l'envoi automatique hors du même site, tandis que la valeur souple l'autorise pour les navigations venues d'un lien tout en bloquant les soumissions d'un autre site : c'est le réglage raisonnable pour un site public. Enfin, comparer l'en-tête d'origine de la requête à votre propre domaine est un filet, pas une preuve : il coexiste avec le jeton, il ne le remplace pas.

Un cas limite mérite une mention : le CSRF de connexion, où l'attaquant vous connecte à son propre compte pour recueillir ce que vous y déposerez par la suite. Il se traite comme les autres, en exigeant un jeton sur le formulaire d'authentification et en régénérant l'identifiant de session après chaque changement de statut, ce qui vide immédiatement les anciens jetons.

Pour les applications à interface riche, où les formulaires sont construits dynamiquement, récupérez le jeton à partir d'une balise réservée du document puis ajoutez-le dans l'en-tête de chaque requête de modification : le serveur accepte les deux formes, à condition de les comparer avec la même rigueur. Ne placez jamais le jeton dans une adresse, car les adresses sont enregistrées par l'historique, transmises par les en-têtes de référent et souvent conservées dans les journaux.
$lesson$),
  ('cyb-c5-p6', 'cyb-c5', 6, $lesson$Validation de saisie côté serveur : le navigateur ne protège jamais$lesson$, $lesson$
Il y a une tentation très répandue et totalement vaine : valider les données dans la page, avec des attributs de saisie et des expressions régulières côté client. C'est utile pour l'ergonomie : le visiteur voit ce qui ne va pas et la page ne se recharge pas pour une faute de forme. En termes de sécurité, cette validation n'existe pas : elle vit dans un programme que l'attaque contrôle entièrement. On peut la désactiver, l'ignorer, ou appeler votre point d'entrée directement sans jamais charger la page qui l'entoure. Votre serveur est la seule frontière réelle, et c'est lui qui doit exiger, contrôler et rejeter.

Une bonne validation serveur combine quatre opérations, dans cet ordre. La normalisation retire les espaces superflus et convertit les caractères vers leur forme canonique, de sorte que deux saisies équivalentes deviennent rigoureusement identiques. Le contrôle de forme vérifie ensuite, par une expression régulière ou une structure définie par le programme, la longueur, le jeu de caractères autorisé et le motif attendu. Puis viennent le type et la plage : une date est réellement une date, un nombre est compris dans les valeurs admissibles, un identifiant existe dans la table. Enfin les règles métier, qui sont de votre ressort : la session choisie est ouverte, les places restantes le permettent, l'adresse n'est pas déjà inscrite. Chaque contrôle rejette avec un message clair, sans divulguer le détail interne.

```python
import re
import unicodedata

COURRIEL = re.compile(r"^[^@\s]{1,64}@[^@\s]{1,190}\.[A-Za-z]{2,24}$")
NOM = re.compile(r"^[A-Za-zÀ-ÖØ-öø-ÿ' -]{2,80}$")

def normaliser(texte: str) -> str:
    # Forme canonique, puis retrait des espaces de bord
    return unicodedata.normalize("NFC", texte.strip())

def valider_inscription(donnees: dict) -> dict:
    erreurs = []

    nom = normaliser(donnees.get("nom", ""))
    if not NOM.fullmatch(nom):
        erreurs.append("nom invalide")

    courriel = normaliser(donnees.get("courriel", "")).lower()
    if not COURRIEL.fullmatch(courriel) or len(courriel) > 190:
        erreurs.append("adresse invalide")

    session = donnees.get("session")
    if session not in ("matin", "aprem"):  # liste blanche, jamais une instruction
        erreurs.append("session inconnue")

    if erreurs:
        # Message générique côté utilisateur, détail côté journal
        raise ValueError("Formulaire incomplet ou invalide")

    return {"nom": nom, "courriel": courriel, "session": session}
```

L'opposition entre liste blanche et liste noire mérite une insistance particulière, car elle revient dans chaque section. Une liste blanche décrit ce qui est accepté et rejette tout le reste ; une liste noire décrit ce qui est interdit et accepte tout le reste. La première est finie et vérifiable, la seconde est ouverte et condamnée à être incomplète, parce que l'inventaire des entrées possibles ne cesse de grandir : nouvelles unités Unicode, nouveaux protocoles, nouvelles façons d'écrire une expression. Devant un champ de nom, écrivez ce qui est admis ; devant une redirection, écrivez les domaines acceptés. Le réflexe inverse, filtrer les mots dangereux, revient à poser un cadenas sur la porte principale en laissant la fenêtre ouverte.

Un deuxième point concerne les messages d'échec. Ils distinguent ce qui relève de la forme, que l'utilisateur peut corriger, de ce qui relève du fond, qu'il ne doit pas explorer. Dire que le mot de passe est trop court est utile et sans danger ; dire que le compte n'existe pas aide à recenser les adresses inscrites ; renvoyer le détail interne de l'échec, chemin compris, revient à ouvrir la porte du système d'information. Dans le formulaire de la médiathèque, les messages restent descriptifs du champ, jamais de l'état de la base, et chaque échec est journalisé en agrégat pour repérer les séries de tentatives anormales.

La couche suivante consiste à refaire les mêmes contrôles là où la donnée est réellement utilisée. Une application a souvent plusieurs portes d'entrée vers la même fonction : formulaire, interface appelée par le navigateur, traitement de lot, script d'administration. Valider à la porte principale sans revérifier dans la fonction métier, c'est laisser une brèche par chaque autre porte. C'est le principe de défense en profondeur : la validation la plus proche de l'usage est celle qui compte, et une fonction sensible doit exiger un argument déjà typé et déjà contrôlé.

Enfin, deux habitudes complètent la validation. Borner la taille des données reçues avant de les examiner : un champ annoncé pour quatre-vingts caractères et un corps de requête limité à quelques kilo-octets suppriment une classe entière de tentatives de déni de service. Puis tester sa propre validation comme on teste une fonction : cas limites, caractères Unicode, chaînes vides, chaînes très longues, valeurs presque valides. Ces tests coûtent peu, se rédigent une fois, et apprendront plus sur votre application qu'une heure de relecture attentive.
$lesson$),
  ('cyb-c5-p7', 'cyb-c5', 7, $lesson$Gestion des erreurs : ne jamais montrer au visiteur ce que le programme sait$lesson$, $lesson$
Une application qui affiche ses exceptions est une application qui publie son plan. Le message d'erreur par défaut de la plupart des frameworks contient, avec une générosité variable mais toujours excessive, le nom du fichier source, le numéro de ligne, le chemin complet sur le serveur, la version de la bibliothèque, parfois la requête exacte qui a échoué, parfois le contenu des variables locales. Tout cela est précieux pour le développeur qui débogue, et tout cela est parfaitement inutile, souvent très dangereux, pour la personne qui vient de provoquer l'échec. L'attaque commence souvent là : une faute de syntaxe volontaire, un identifiant inexistant, une valeur hors plage, pour observer ce que la page raconte.

Le remède tient en un principe simple : la page dit que quelque chose s'est mal passé, le journal dit pourquoi. L'utilisateur reçoit un message neutre, formulé dans sa langue, assorti d'un identifiant de suivi que le développeur retrouvera dans les journaux ; l'équipe reçoit le détail complet, horodaté, avec le contexte nécessaire. Cette séparation a un avantage supplémentaire : elle force à écrire des journaux exploitables, ce qui est la condition de toute détection. Un incident dont personne ne trouve la trace est un incident dont on ne saura jamais quand il a commencé.

```python
import logging
import secrets

journal = logging.getLogger("mediatheque")

# Ce qu'on ne fait JAMAIS : laisser l'exception traverser jusqu'à l'écran.
# Une telle page révèle le chemin d'installation, la version du framework
# et, souvent, la requête exacte qui a échoué.
#
# try:
#     ...
# except Exception as exc:
#     return reponse(f"Erreur : {exc}")
#     return reponse(str(traceback.format_exc()))

# Ce qu'on fait : un identifiant pour l'utilisateur, le détail pour les journaux.
def traiter_requete(fonction):
    try:
        return fonction()
    except Exception as exc:
        reference = secrets.token_hex(4)
        journal.exception(
            "échec_traitement reference=%s type=%s",
            reference,
            type(exc).__name__,
        )
        return (
            f"Une erreur est survenue. Référence à communiquer : {reference}",
            500,
        )
```

Les codes de statut font partie du discours et doivent rester exacts. Un refus d'autorisation n'est pas une erreur système, un envoi malformé n'est pas une absence de ressource, et un doublon n'est pas un crash : des codes corrects aident les navigateurs, les clients et votre propre compréhension des journaux, tandis que des codes systématiquement retournés à deux cents masquent les incidents pendant des mois. Les messages de refus doivent aussi être stables : varier le texte selon que l'adresse est inconnue ou le mot de passe incorrect revient à fournir un service de recensement de comptes. Une formulation identique dans les deux cas supprime cet avantage.

Le mode de développement, enfin, ne doit jamais voyager jusqu'à la production : des variables d'environnement s'en chargent, et vérifier leur valeur au démarrage prend trois secondes. En production, le niveau d'affichage des erreurs est au plus haut, les pages d'erreur personnalisées sont activées et les variables de mise en service sont rejetées. Ajoutez à votre rituel de mise en production un contrôle simple : déclenchez une erreur sur un environnement de recette et regardez ce que l'écran dit. Si vous y lisez un chemin, un nom de module ou une requête, la configuration n'est pas bonne.

Deux cas particuliers méritent d'être cités : l'erreur qui contient une donnée personnelle, qui étend la fuite à toute personne présente sur l'écran, et l'erreur de ressource épuisée, qui doit déclencher une alerte vers l'équipe là où une erreur métier doit rester silencieuse. Bien distinguer ces deux familles, c'est éviter que les vraies alertes se noient dans le bruit.
$lesson$),
  ('cyb-c5-p8', 'cyb-c5', 8, $lesson$Mots de passe : un chiffrement qu'on ne peut pas lire$lesson$, $lesson$
La question revient à chaque réunion : faut-il chiffrer les mots de passe pour pouvoir les récupérer ? Non, et la raison est simple : si vous pouvez les lire, d'autres le pourront un jour, à cause d'une fuite, d'une sauvegarde exposée ou d'un compte compromis. On n'a jamais besoin de connaître un mot de passe, seulement de vérifier que la personne qui se connecte fournit le bon. C'est cette vérification qui définit le bon outil : un calcul à sens unique, irréversible en pratique, appelé fonction de hachage à calcul lent, avec un sel unique pour chaque enregistrement.

La distinction avec le chiffrement doit être nette : un chiffrement est réversible, on lui donne une clé et on récupère le texte d'origine ; un hachage conçu pour les mots de passe ne l'est pas, on lui donne le mot de passe et on obtient une empreinte, mais l'opération inverse n'existe pas. D'où le choix : chiffrer ce qui doit être relu, hacher ce qui doit seulement être comparé. Une adresse postale, un nom d'atelier ou un document sont chiffrés ou protégés autrement ; un mot de passe est haché, toujours. Si votre application doit afficher un mot de passe à un administrateur, c'est qu'un autre besoin existe : envoyez plutôt un lien de réinitialisation.

```python
# Mauvaise pratique : hachage rapide, sans sel, non adapté aux mots de passe.
# Un algorithme conçu pour la vérification d'intégrité tourne des
# milliards de fois par seconde sur une carte graphique.
#
# import hashlib
# empreinte = hashlib.md5(mot_de_passe.encode()).hexdigest()

# Bonne pratique : algorithmes lents et paramétrés, conçus pour ce usage.
import bcrypt
import argon2

# bcrypt : le travail est réglé par le facteur de coût
def enregistrer_bcrypt(mot_de_passe: str) -> str:
    sel = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(mot_de_passe.encode("utf-8"), sel).decode("ascii")

def verifier_bcrypt(mot_de_passe: str, empreinte: str) -> bool:
    return bcrypt.checkpw(mot_de_passe.encode("utf-8"), empreinte.encode("ascii"))

# argon2 : recommandé, réglé sur la mémoire, le temps et le parallélisme
def enregistrer_argon2(mot_de_passe: str) -> str:
    hacheur = argon2.PasswordHasher(
        time_cost=3, memory_cost=65536, parallelism=4
    )
    return hacheur.hash(mot_de_passe)

def verifier_argon2(mot_de_passe: str, empreinte: str) -> bool:
    try:
        return argon2.PasswordHasher().verify(empreinte, mot_de_passe)
    except argon2.exceptions.VerifyMismatchError:
        return False
```

Trois paramètres décident de la robustesse réelle de ce stockage. Le sel est une valeur différente pour chaque enregistrement, jointe au mot de passe avant le calcul et conservée avec l'empreinte : elle rend inutile la fabrication de tables de correspondances et fait que deux personnes ayant le même mot de passe n'ont pas la même empreinte. Le facteur de coût est la quantité de travail demandée au calcul ; il doit rendre une attaque par force brute coûteuse sans dégrader la durée d'une connexion. L'algorithme, enfin, doit être maintenu : d'où bcrypt ou argon2, plutôt qu'une construction maison.

La vérification s'accompagne de deux réflexes. Comparez à durée constante et ne raccourcissez jamais la saisie avant calcul : chaque information de timing est une information de trop. Puis appliquez la remontée de niveau : quand un utilisateur se connecte avec une empreinte calculée selon des paramètres anciens, recalculez et remplacez l'enregistrement, sans migration risquée. Côté politique de saisie, privilégiez la longueur, acceptez les phrases de passe, refusez les listes de mots compromis, et ne poussez pas l'utilisateur vers un mot de passe en majuscule, chiffre et symbole, réutilisé partout.

Enfin, les abords du mot de passe comptent autant que son stockage : ne le journalisez jamais, ne le transmettez jamais en adresse, ne le renvoyez jamais dans une erreur. Les jetons de réinitialisation sont des secrets aléatoires à usage unique, à durée courte, invalidés dès leur emploi : ils se traitent comme des jetons de session, pas comme des questions secrètes dont la réponse est un souvenir d'enfance. Un canal qui reflète le jeton dans un message visible par d'autres personnes reproduit le défaut que vous cherchez à éviter.
$lesson$),
  ('cyb-c5-p9', 'cyb-c5', 9, $lesson$Uploads de fichiers : quand le site accepte des documents$lesson$, $lesson$
Le site de la médiathèque n'accepte pas que du texte : les intervenants déposent une affiche au format image, un programme en format portable, une feuille signée scannée. Chaque dépôt introduit une famille de risques que le formulaire de saisie ne connaissait pas, parce qu'un fichier n'est pas seulement une donnée : c'est un contenu, un nom, une taille, un type déclaré et un type réel, et ces cinq informations peuvent toutes mentir. La première erreur est de faire confiance au nom transmis par le navigateur ; la seconde, au type annoncé dans la requête : tous deux sont écrits par la personne qui envoie.

Les conséquences d'un dépôt mal contrôlé sont variées. Le nom peut contenir un chemin et viser un fichier existant plutôt que le dossier de dépôt, pratique appelée traversée de chemin, ou se terminer par une extension inoffensive suivie d'une extension exécutable. Le contenu peut être un fichier texte qui se fait passer pour une image, ou une image contenant en plus du code exécuté par le navigateur de quiconque l'ouvrira. Une archive peut créer des dossiers hors de la zone prévue, un volume peut saturer le disque, et un fichier déposé peut être servi à un autre utilisateur : c'est alors un vecteur de diffusion.

La parade tient en une liste de règles simples. On vérifie la taille avant tout traitement, puis on extrait l'extension et on la confronte à une liste blanche définie par le développeur. On examine les premiers octets pour confirmer que la structure réelle correspond au type annoncé, puis on recopie ou on ré-encode le fichier, ce qui détruit tout contenu parasite ajouté à la suite. On ignore le nom reçu pour lui substituer un identifiant généré, on stocke en dehors de la racine servie, on limite le nombre de dépôts par compte. Enfin, on sert les fichiers par une route contrôlée qui fixe le type de contenu et le nom affiché, sans jamais laisser le serveur deviner ce qu'il doit faire d'un fichier.

```python
import secrets
import unicodedata
from pathlib import Path

# Dossier de dépôt, hors racine servie directement par le navigateur.
RACINE = Path("/var/mediatheque/depots")
EXTENSIONS = {".pdf", ".jpg", ".jpeg", ".png"}
TAILLE_MAX = 5 * 1024 * 1024
MAGIQUES = {
    ".jpg": (b"\xff\xd8\xff",),
    ".png": (b"\x89PNG\r\n\x1a\n",),
    ".pdf": (b"%PDF-",),
}

def accepter_depot(stream, nom_recu: str) -> Path:
    # 1. Taille, avant toute lecture complète
    donnees = stream.read(TAILLE_MAX + 1)
    if len(donnees) > TAILLE_MAX:
        raise ValueError("fichier trop volumineux")

    # 2. Extension extraite du nom reçu, puis liste blanche
    nom = unicodedata.normalize("NFC", Path(nom_recu).name)
    suffixe = Path(nom).suffix.lower()
    if suffixe not in EXTENSIONS:
        raise ValueError("type de fichier refusé")

    # 3. Structure réelle du contenu, indépendamment du type annoncé
    if not any(donnees.startswith(m) for m in MAGIQUES[suffixe]):
        raise ValueError("contenu incohérent avec l'extension")

    # 4. Nom généré : le nom reçu ne sert jamais de chemin
    destination = RACINE / f"{secrets.token_hex(16)}{suffixe}"
    destination.write_bytes(donnees)
    return destination
```

Deux précisions complètent ces règles. Un fichier vectoriel est du balisage : il peut emporter du code, il doit donc être accepté par conversion contrôlée vers une forme aplatie, jamais servi tel quel. Les métadonnées photographiques, elles, contiennent parfois la position ou le nom du fichier d'origine : les retirer par ré-encode relève à la fois de la confidentialité et de la sécurité. Testez enfin votre chemin de dépôt avec un nom malveillant, un nom vide et un nom contenant un chemin complet : si l'un de ces cas provoque une erreur technique détaillée, vous venez de trouver deux défauts d'un coup.
$lesson$),
  ('cyb-c5-p10', 'cyb-c5', 10, $lesson$Journaliser sans exposer les données personnelles$lesson$, $lesson$
Les journaux d'activité sont le nerf de la détection : sans eux, une intrusion passe inaperçue, une anomalie ne se remarque pas et un incident ne se retrace jamais. Ils sont aussi une copie de vos données, souvent stockée avec moins de soin que la base elle-même, accessible à davantage de personnes et conservée bien après la durée utile. Journaliser est donc un acte de sécurité à double tranchant, et la discipline consiste à écrire ce qui permet de comprendre, jamais ce qui permet de reconstituer. La question pratique est toujours la même : si ce fichier de journaux fuit demain, que peut-on en apprendre ?

Une liste courte suffit à écarter les évidences : ne jamais consigner un mot de passe, même haché, ni un jeton de session, ni un jeton CSRF, ni une clé d'API, ni l'intégralité d'un corps de requête, ni un numéro de carte. Les données personnelles ordinaires, comme l'adresse électronique, ont un usage légitime dans les journaux, mais elles gagnent à être masquées : la forme abrégée conserve l'utilité analytique, sans offrir la valeur complète. Le texte libre doit être neutralisé, car il peut contenir des retours à la ligne qui cassent la structure du journal et permettent d'inventer des entrées fictives : c'est l'injection de journal.

```python
import logging
import re

# Masquage conservant l'analyse sans livrer la valeur complète.
def masquer_courriel(courriel: str) -> str:
    if "@" not in courriel:
        return "***"
    local, domaine = courriel.split("@", 1)
    return f"{local[:2]}***@{domaine}"

# Neutralisation des caractères qui casseraient une ligne de journal.
def ligne_propre(valeur: str) -> str:
    return re.sub(r"[\r\n\t]+", " ", valeur)[:200]

journal = logging.getLogger("mediatheque.inscription")

def tracer_inscription(courriel: str, session: str, ip: str) -> None:
    journal.info(
        "inscription_recue courriel=%s session=%s ip=%s resultat=%s",
        masquer_courriel(courriel),
        ligne_propre(session),
        ligne_propre(ip),
        "acceptee",
    )
    # Ce qui ne figure jamais dans l'appel : mot de passe, jeton,
    # contenu intégral du formulaire, message d'erreur interne.
```

Au-delà du contenu, trois règles de gouvernance font la différence. L'accès : les journaux sont lus par un petit nombre de comptes, en lecture seule, depuis un endroit distinct des machines qui les produisent, de sorte qu'une compromission du serveur n'efface pas la trace de ce qui s'y est passé. La conservation : définissez une durée, quelques mois pour l'activité détaillée et plus longtemps pour les événements de sécurité, puis appliquez-la, car un journal jamais purgé est un risque dormant. La structure : une ligne par événement, au format structuré, avec un identifiant de corrélation partagé de bout en bout, permet de retrouver une opération complète à travers plusieurs services.

Chaque ligne de journal répond à cinq questions : qui a agi, quelle action a été tentée, quand, depuis quelle origine, avec quel résultat et sous quelle référence. C'est suffisant pour reconstruire une séquence, sans recopier la donnée elle-même. Des journaux réduits à des messages vagues, sans identifiant d'acteur ni résultat, sont inutilisables dès le premier incident.
$lesson$),
  ('cyb-c5-p11', 'cyb-c5', 11, $lesson$Tester sa propre application : la checklist de relecture$lesson$, $lesson$
Aucun outil ne remplacera votre relecture, et aucun outil ne sera remplacé par elle : les deux se complètent. Les outils automatiques excellent à repérer des motifs connus, appel système dangereux, hachage faible, configuration oubliée, dépendance obsolète ; ils sont aveugles aux défauts de conception, à l'absence d'autorisation sur une route, au champ de tri qui accepte n'importe quoi, au formulaire sensible sans jeton. Votre relecture, elle, part du flux de données cartographié au début de ce chapitre et demande, point d'entrée par point d'entrée, ce que la destination fait de la valeur reçue. Commencez par la relecture manuelle, puis lancez les outils pour ne rien oublier du déjà connu.

La checklist suivante tient sur une page et couvre l'essentiel du chapitre. Répondez à chaque question par oui ou par non ; un seul non justifie une correction avant mise en production, pas un ticket à remettre plus tard.

| Domaine à vérifier | Question à se poser | Quand |
| --- | --- | --- |
| Accès aux données | Chaque requête est-elle paramétrée, sans assemblage de chaînes ? | À chaque fonction nouvelle |
| Identifiants de colonnes | Tout tri ou filtre passe-t-il par une liste blanche ? | À chaque fonction nouvelle |
| Commandes système | Chaque appel passe-t-il une liste d'arguments sans shell ? | À chaque appel système |
| Affichage | Toute donnée entrante est-elle échappée selon son contexte ? | À chaque gabarit touché |
| Formulaires sensibles | Chaque action de modification porte-t-elle un jeton vérifié ? | À chaque formulaire d'état |
| Validation | Chaque champ est-il contrôlé côté serveur, en type et en longueur ? | À chaque point d'entrée |
| Erreurs | Une page d'erreur contient-elle un chemin, une requête ou une version ? | Avant chaque mise en production |
| Mots de passe | Le stockage utilise-t-il bcrypt ou argon2, avec sel unique ? | À chaque nouveau compte |
| Dépôts de fichiers | Nom généré, extension en liste blanche, stockage hors racine ? | À chaque zone de dépôt |
| Journalisation | Les journaux sont-ils masqués, datés, accessibles en lecture seule ? | Chaque trimestre |

Un script de repérage, même sommaire, fait gagner un temps considérable sur un code existant : il ne prouve rien, mais il oriente la lecture vers les fichiers qui méritent d'être ouverts en premier. Le suivant balaye une arborescence de source et signale quelques motifs dont ce chapitre a parlé, en affichant simplement l'endroit à examiner.

```python
# Balayage heuristique d'une arborescence de source.
# Ce script ne détecte pas des failles : il indique où regarder.
import re
from pathlib import Path

MOTIFS = {
    "appel système direct": re.compile(r"os\.system\(|shell\s*=\s*True"),
    "hachage inadapté": re.compile(r"hashlib\.(md5|sha1)\("),
    "évaluation de code": re.compile(r"\beval\(|\bexec\("),
    "désactivation de vérification": re.compile(r"verify\s*=\s*False"),
    "mode debug actif": re.compile(r"DEBUG\s*=\s*True"),
    "requête concaténée": re.compile(r"(SELECT|INSERT|UPDATE).*(\"|\')\s*\+"),
}

def balayer(racine: Path) -> None:
    for chemin in racine.rglob("*.py"):
        for numero, ligne in enumerate(chemin.read_text("utf-8").splitlines(), 1):
            for libelle, motif in MOTIFS.items():
                if motif.search(ligne):
                    print(f"{chemin}:{numero} — {libelle}")
```

Passez ensuite à la vérification du comportement, qui diffère de la vérification du code. Sur un environnement de recette, déclenchez chaque erreur prévue : champ vide, champ trop long, valeur inconnue, fichier sans extension, requête avec un jeton absent. Confirmez qu'aucun chemin, aucune requête ni aucun nom de module n'apparaît à l'écran, puis vérifiez les en-têtes de réponse, la politique de contenu et les attributs des cookies. Essayez enfin de franchir les limites : demandez une action administrative sans être connecté, puis avec une session ordinaire ; si le refus diffère, un simple changement de cookie suffit.
$lesson$),
  ('cyb-c5-p12', 'cyb-c5', 12, $lesson$Mini-projet guidé : audit du formulaire d'inscription$lesson$, $lesson$
Il est temps d'assembler les pièces du chapitre sur un objet unique : le formulaire d'inscription du site de la médiathèque des Lilas, tel qu'un développeur pressé l'aurait écrit un mardi soir. Le point de départ est le traitement suivant, qui reçoit les trois champs, vérifie très peu, assemble une requête, affiche ce qui a été reçu et fait générer un accusé de dépôt. Chaque ligne y est défendable prise isolément ; c'est l'ensemble qui pose problème.

```python
# Traitemend'inscription tel qu'il a été écrit — version à auditer.
import os
import sqlite3

def inscription(request):
    nom = request.form["nom"]
    courriel = request.form["courriel"]
    session = request.form["session"]

    connexion = sqlite3.connect("/var/mediatheque/base.db")
    curseur = connexion.cursor()
    curseur.execute(
        "INSERT INTO inscriptions (nom, courriel, session) VALUES ('"
        + nom + "', '" + courriel + "', '" + session + "')"
    )
    connexion.commit()

    # Affichage du message de confirmation avec le nom reçu
    page = "<h1>Inscription de " + nom + " enregistrée</h1>"
    page += "<p>Un accusé a été envoyé à " + courriel + "</p>"

    # Génération du document transmis à l'intervenant
    os.system("generate-receipt --name " + nom + " --out /tmp/receipt.pdf")

    return page
```

L'audit se déroule en douze points de contrôle, à noter un par un et à traiter dans l'ordre où ils apparaissent dans le flux. Un, la valeur de chaque champ est-elle lue avant d'être contrôlée, et un champ absent provoque-t-il une erreur technique ? Deux, la longueur est-elle bornée avant toute utilisation ? Trois, la requête d'insertion est-elle construite par concaténation ? Quatre, le nom de la table et les noms de colonnes peuvent-ils être influencés de l'extérieur ? Cinq, la confirmation affiche-t-elle le nom et l'adresse sans traitement ? Six, quel contexte exact chaque insertion occupe-t-elle dans la page produite ? Sept, l'action de soumission est-elle protégée par un jeton vérifié côté serveur ? Huit, la session est-elle créée ou modifiée sans régénérer l'identifiant ? Neuf, l'appel système utilise-t-il une chaîne contenant une valeur entrante ? Dix, les erreurs de la base sont-elles renvoyées à l'écran ? Onze, le fichier de base et les journaux sont-ils accessibles depuis la racine servie ? Douze, un compte administrateur peut-il accomplir la même action par un autre chemin sans contrôle ?

La correction commence par la requête, qui passe d'une instruction fabriquée à une instruction fixe accompagnée de ses paramètres. La valeur n'est plus jamais collée dans le texte : elle est transmise par le connecteur, qui la traite comme une donnée, quelle que soit sa teneur.

```python
# Version corrigée du même traitement, décrite section par section.
import html
import secrets
import sqlite3
import subprocess

TAILLES = {"nom": 80, "courriel": 190, "session": 10}

def inscription(request, session_utilisateur):
    # 1. Contrôle de présence, de type et de longueur, côté serveur
    brut = {clef: (request.form.get(clef) or "").strip()
            for clef in ("nom", "courriel", "session")}
    if any(len(valeur) > TAILLES[clef] for clef, valeur in brut.items()):
        return "Formulaire invalide", 400
    if brut["session"] not in ("matin", "aprem"):
        return "Formulaire invalide", 400

    # 2. Preuve que la requête vient du formulaire réel du site
    if not secrets.compare_digest(
        session_utilisateur.get("csrf", ""), request.form.get("csrf_token", "")
    ):
        return "Requête refusée", 403

    # 3. Instruction fixe, valeurs transmises à part
    connexion = sqlite3.connect("/var/mediatheque/base.db")
    with connexion:
        connexion.execute(
            "INSERT INTO inscriptions (nom, courriel, session) "
            "VALUES (?, ?, ?)",
            (brut["nom"], brut["courriel"], brut["session"]),
        )

    # 4. Affichage : chaque insertion échappée selon son contexte
    nom_affiche = html.escape(brut["nom"][:80], quote=True)
    courriel_affiche = html.escape(brut["courriel"][:190], quote=True)
    page = f"<h1>Inscription de {nom_affiche} enregistrée</h1>"
    page += f"<p>Accusé envoyé à {courriel_affiche}</p>"

    # 5. Appel système : arguments séparés, aucune commande assemblée
    subprocess.run(
        ["generate-receipt", "--name", brut["nom"], "--out", "/tmp/receipt.pdf"],
        check=True,
        shell=False,
        timeout=30,
    )
    return page
```

La politique d'échappement doit être justifiée par le contexte, pas décidée à la louche. Dans la page produite ci-dessus, le nom apparaît dans un élément de titre : il relève du contexte de contenu, où l'on neutralise les caractères qui pourraient ouvrir un balisage. L'adresse figure dans un paragraphe, avec la même règle mais une longueur bornée différemment. Si le nom doit un jour figurer dans un attribut, la règle change : le guillemet employé ne doit pas pouvoir clore l'attribut. S'il devait être écrit dans un bloc de script, la seule réponse correcte serait de ne jamais le faire, mais de placer la donnée ailleurs et de la lire depuis le document. Chaque insertion s'accompagne donc d'une justification, et cette justification fait partie de la relecture.

La conception du jeton CSRF de ce formulaire repose sur cinq décisions explicites. La longueur : au moins trente-deux octets d'aléatoire, qui rend toute devinette hors de portée. La liaison : le jeton est stocké dans la session qu'il protège, il n'a aucun sens ailleurs. La durée : il est régénéré à chaque affichage et, si le framework le permet, n'accepte qu'une seule utilisation. La comparaison : stricte et à durée constante, jamais une égalité simple sur des chaînes de longueur variable. La portée : il protège toute requête qui modifie un état, pas seulement celle-ci. À cela s'ajoutent l'attribut de même site sur le cookie de session et l'absence d'action de modification par adresse cliquable.

La checklist de relecture du code, à exécuter en dix lignes de raisonnement sur la version corrigée comme sur toute autre, prend la forme suivante.

1. Toute donnée qui entre est-elle présente, typée et de longueur bornée avant d'être utilisée ?
2. Chaque requête vers la base est-elle paramétrée, sans aucune concaténation ?
3. Tout identifiant variable passe-t-il par une liste blanche définie dans le programme ?
4. Chaque appel système reçoit-il des arguments séparés, sans interpréteur de commandes ?
5. Chaque valeur affichée est-elle échappée selon le contexte exact où elle apparaît ?
6. Chaque action qui modifie un état exige-t-elle un jeton vérifié à durée constante ?
7. Une page d'erreur contient-elle un chemin, une requête, une version ou une donnée interne ?
8. Les secrets sont-ils hachés avec un algorithme lent et un sel unique, jamais chiffrés ?
9. Les fichiers déposés sont-ils renommés, contrôlés en contenu et stockés hors racine ?
10. Les journaux contiennent-ils l'acteur, l'action, le résultat et la référence, sans donnée secrète ?

Appliquez cette suite de questions au formulaire de la médiathèque, puis au moteur de recherche, puis à l'espace administrateur : le même ordre fonctionne, parce que les mêmes familles de risques se répètent. C'est le véritable objectif du chapitre : moins une liste de correctifs qu'une méthode de lecture que vous emporterez dans tous les projets suivants.
$lesson$),
  ('cyb-c5-p13', 'cyb-c5', 13, $lesson$À retenir$lesson$, $lesson$
- La faille applicative naît toujours d'une donnée qui change de rôle entre l'entrée et l'usage.
- L'OWASP Top 10 sert de langage commun et de priorisation, pas de certification.
- Une requête paramétrée sépare l'instruction fixe de la valeur transmise : c'est la parade à l'injection SQL.
- Les identifiants de colonnes et les noms de table ne se paramétrent pas, ils se choisissent dans une liste blanche.
- Une commande système ne se construit jamais par concaténation : arguments en liste, sans interpréteur de commandes.
- XSS se présente en trois formes, réfléchi, stocké et DOM, et toutes trois viennent du même oubli d'échappement.
- L'échappement dépend du contexte : contenu, attribut, script, adresse et style n'ont pas les mêmes règles.
- La politique de sécurité de contenu réduit la portée d'un XSS même si une faille subsiste.
- Un cookie de session porte trois attributs : inaccessible au script, de même site, réservé au transport chiffré.
- Le CSRF exige une preuve que seul votre formulaire produit : jeton aléatoire, lié à la session, comparé à durée constante.
- Le navigateur ne protège rien : toute validation utile se fait côté serveur, en liste blanche.
- Les messages d'erreur disent que ça a échoué ; les journaux disent pourquoi.
- Un mot de passe se hache avec bcrypt ou argon2, jamais chiffré, jamais haché rapidement.
- Un dépôt de fichier exige taille bornée, extension en liste blanche, contenu vérifié, nom généré, stockage hors racine.
- Journaliser, c'est analyser sans conserver : masquez les données personnelles, limitez l'accès, fixez la durée.
- Relisez d'abord le trajet des données, puis lancez les outils pour ne rien oublier du déjà connu.
$lesson$),
  ('cyb-c5-p14', 'cyb-c5', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : assembler une requête SQL avec des guillemets autour d'une valeur → Correction : instruction fixe et paramètres transmis par le connecteur.
- Piège : filtrer les mots interdits dans une valeur avant de l'insérer dans une requête → Correction : liste blanche, la liste noire sera toujours incomplète.
- Piège : construire une commande système avec la valeur d'un champ → Correction : liste d'arguments, option d'interpréteur de commandes désactivée, chemin généré.
- Piège : échapper partout de la même manière → Correction : adaptez l'échappement au contexte exact : contenu, attribut, adresse, script.
- Piège : désactiver l'échappement automatique du gabarit pour insérer du balisage riche → Correction : conservez-le et autorisez un balisage restreint explicitement.
- Piège : faire confiance au type de fichier annoncé par le navigateur → Correction : extension en liste blanche, vérification des premiers octets, nom généré.
- Piège : afficher l'exception de la base pour comprendre un échec en production → Correction : message générique et référence, détail dans les journaux.
- Piège : valider seulement dans la page avec des attributs de saisie → Correction : rejouez chaque contrôle côté serveur, à chaque porte d'entrée.
- Piège : stocker les mots de passe avec un algorithme rapide ou un chiffrement réversible → Correction : bcrypt ou argon2 avec sel unique et remontée de niveau.
- Piège : protéger les formulaires en exigeant un en-tête d'origine, sans jeton → Correction : gardez le jeton, traitez l'origine comme un filet complémentaire.
- Piège : journaliser le corps complet de la requête pour faciliter le débogage → Correction : enregistrez l'acteur, l'action, le résultat et la référence, jamais les secrets.
- Piège : penser qu'un framework sécurisé dispense de relecture → Correction : vérifiez ce que produit réellement le code, sur votre environnement.
$lesson$),
  ('cyb-c5-p15', 'cyb-c5', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La référence de départ reste le site de l'Open Web Application Security Project, consultable à l'adresse https://owasp.org. Le Top 10 y est publié avec, pour chaque catégorie, une description, des scénarios d'attaque typiques, des conseils de prévention et des liens vers les fiches techniques correspondantes. Ces documents, écrits par la communauté et mis à jour régulièrement, gagnent à être gardés en favori plutôt qu'imprimés : revenez-y quand une décision d'architecture se pose.

Deuxièmement, la documentation de Mozilla sur le web est la meilleure source pour tout ce qui touche au navigateur : XSS, politique de sécurité de contenu, cookies. La page https://developer.mozilla.org/docs/Web/Security rassemble les notions de sécurité côté client, avec des exemples exécutables et des liens vers les pages individuelles des en-têtes étudiés ici. Pour les cookies, la page dédiée décrit les attributs de même site, d'inaccessibilité script et de transport chiffré, et signale ce qui est obsolète. Complétez avec les fiches sur la falsification de requête transverse et sur l'échappement de sortie.
$lesson$),
  ('cyb-c5-p16', 'cyb-c5', 16, $lesson$Et maintenant : appliquer l'audit à votre propre code$lesson$, $lesson$
Vous disposez à présent d'une méthode complète : cartographier les points d'entrée, suivre chaque donnée jusqu'à sa destination, appliquer la parade correspondante, puis relire avec une liste de questions courtes. L'exercice pratique qui suit vous demande d'appliquer cette séquence au formulaire d'inscription de la médiathèque, en réécrivant la requête, en justifiant l'échappement par contexte, en concevant le jeton et en produisant votre checklist. Réessayez seul, sans regarder la correction, puis comparez : les différences que vous découvrirez seront plus instructives que la leçon elle-même. Le quiz de quatre questions vérifie en quelques minutes les notions essentielles, du choix de l'algorithme de hachage jusqu'à la parade adaptée à chaque destination.

Le pas suivant consistera à étendre ce réflexe au-delà d'une seule application : sécurité de la chaîne d'approvisionnement logicielle, dépendances, secrets, intégrité des paquets et suivi des correctifs. Le principe reste le même : ne faites jamais confiance à une donnée qui n'a pas été contrôlée là où elle est utilisée. En attendant, ouvrez le dernier projet livré et appliquez-lui dès aujourd'hui les dix lignes de la checklist de relecture : c'est le geste le plus rentable de tout ce chapitre, et il ne vous coûtera qu'une heure.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('cyb-c6-p1', 'cyb-c6', 1, $lesson$Un événement n'est pas un incident : la distinction qui commande tout$lesson$, $lesson$
Bienvenue dans le sixième chapitre du parcours Cybersécurité, un chapitre entièrement consacré à la détection et à la réponse à incident, c'est-à-dire à tout ce qui se passe après qu'un événement indésirable a commencé à se produire dans un système. Les chapitres précédents ont parlé de prévention : mises à jour, mots de passe, droits, sauvegardes, cloisonnement du réseau. Ces sujets restent essentiels, et aucun d'eux n'est obsolète. Mais aucune organisation, même bien outillée, n'évite indéfiniment les incidents : une configuration oubliée, un compte jamais désactivé, un lien convaincant ouvert par un collègue pressé, un équipement hors maintenance suffisent. La maturité d'une équipe de sécurité ne se mesure donc pas à l'absence d'incidents, elle se mesure à la qualité de la réaction : combien de temps avant de voir ce qui se passe, combien avant d'arrêter la propagation, combien avant de retrouver un service normal, et surtout ce qui a changé ensuite pour que la même défaillance ne se reproduise pas. Ce chapitre vous apprend à travailler dans cet intervalle, entre le premier signal et la reprise de service.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées sur un cas complet. Vous distinguerez un événement banal d'un incident à qualifier, et vous écrirez des critères de déclenchement écrits plutôt que des impressions. Vous choisirez les quatre familles de signaux à surveiller dans un parc de taille moyenne : journaux, fichiers, trafic réseau et comptes. Vous construirez des alertes utiles, c'est-à-dire des alertes qui remontent assez tôt pour agir et peu souvent pour être lues, avec des seuils justifiés et une procédure attachée à chacune. Vous connaîtrez le rôle respectif d'un SIEM, d'un EDR et d'un HIDS sans vous laisser éblouir par les brochures commerciales. Vous appliquerez les six phases classiques de la réponse, de la préparation aux leçons tirées. Vous constituerez une chronologie horodatée qui tient devant un tiers, vous isolerez un système sans détruire les preuves, vous préparerez la restauration à partir des sauvegardes, vous rédigerez une communication interne et un rapport d'incident, puis vous mènerez une rétrospective qui améliore réellement le plan. Le tout sera assemblé dans un mini-projet guidé : le rapport d'incident complet de la médiathèque, que vous récrierez seul juste après la leçon.

Le fil rouge de ce chapitre est le parc informatique de la Médiathèque des Lilas. L'établissement exploite une trentaine de postes publics, deux postes d'accueil, un serveur de fichiers partagé entre les services, une messagerie interne et un réseau administratif partagé avec la mairie. Les sauvegardes sont quotidiennes, la nuit, hors ligne une fois par semaine. Un lundi matin d'octobre, une documentaliste ouvre son poste et constate que les fichiers de son dossier de travail ne s'ouvrent plus : les noms ont changé, le contenu est devenu illisible, et une note texte inconnue apparaît dans le dossier partagé. Le réseau fonctionne, les machines tournent, le service public continue à l'accueil, mais les données du service ne sont plus accessibles. L'incident est fictif ; les réflexes que nous allons déployer sont exactement ceux qu'une équipe informatique applique dans ce genre de matin. Nous resterons à chaque instant du côté défensif : nous observerons, nous qualifierons, nous isolerons, nous restaurerons. Rien de ce chapitre ne vous apprendra à produire un chiffrement malveillant, et rien ne vous apprendra non plus à traiter une demande comme si elle faisait partie d'un plan de reprise : la récupération s'appuie sur les sauvegardes et sur la propreté des systèmes, jamais sur d'éventuelles promesses.

Une dernière recommandation avant d'entrer dans le vif du sujet. La détection et la réponse s'apprennent comme on apprend à conduire : en manipulant les commandes sur un cas simple, pas en mémorisant un tableau. Recopiez les extraits de journaux, retracez la chronologie à la main, relisez la communication interne à voix haute. Une heure sans source ? Écrivez la source manquante au lieu de l'inventer : c'est cette exigence de preuve qui distingue un rapport d'incident d'une conversation d'escalier. Le fil rouge de la médiathèque vous accompagnera dans chaque section, avec des signaux que son serveur de fichiers, son annuaire et son pare-feu produisent déjà, sans que personne ne les lise.



Le premier réflexe à acquérir est lexical, parce que le vocabulaire détermine ce qu'on décide de faire. Un événement est une observation, un fait constaté dans un système : une connexion refusée, un service redémarré, un fichier modifié, une sauvegarde terminée, un pic de charge. Les événements sont légion, ils sont enregistrés en continu et la plupart n'ont aucune conséquence. Une journée ordinaire d'un parc de trente machines en produit des milliers, dont aucun ne mérite qu'on lève quelqu'un de son lit. L'événement est la matière première ; il n'est pas encore un sujet. Un incident, lui, est un événement ou un enchaînement d'événements qui menace réellement, ou menace de manière plausible, la confidentialité, l'intégrité ou la disponibilité d'un système ou des données qu'il contient. La différence n'est pas dans la gravité ressentie, elle est dans l'effet constaté ou pressenti sur ces trois promesses : mes données sont-elles vues par quelqu'un qui ne devrait pas les voir, modifiées sans autorisation, ou devenues inutilisables ?

Reprenons le cas de la médiathèque pour rendre la distinction tangible. Un échec de connexion au poste d'accueil, isolé, à 9 h 15, parce que la collègue a inversé deux touches : c'est un événement. Quarante et un échecs consécutifs sur le même compte à 4 h 30 du matin, suivis d'une réussite, puis une session qui parcourt des dossiers que ce compte n'a jamais consultés : ce n'est plus un événement, c'est un incident soupçonné, parce qu'une personne ou un programme a obtenu un accès qu'il n'aurait pas dû obtenir. De même, la modification d'un document par son auteur pendant une réunion est un événement ; la modification de deux cents documents en quatre-vingt-dix secondes par un compte qui ne devrait pas écrire dans ce dossier est un incident, parce que l'intégrité du corpus est en jeu. Notez bien que la qualification précède toujours la certitude : on déclare un incident soupçonné, on enquête, et l'incident est soit confirmé, soit classé sans suite. Attendre d'être certain avant d'agir est la meilleure façon d'arriver trop tard.

Cette qualification repose sur des critères écrits à l'avance, pas sur l'humeur du matin. Quatre questions suffisent à trancher dans la très grande majorité des cas. Quel est l'impact : un service public est-il arrêté, des données personnelles sont-elles potentiellement exposées, une activité administrative est-elle bloquée ? Quel est le périmètre : un seul poste, un service, l'ensemble du réseau partagé avec la mairie ? Quelles preuves avons-nous : des journaux exploitables, des captures, un fichier suspect conservé, ou rien du tout ? Et enfin, quelle est l'urgence : des signes de propagation sont-ils visibles en ce moment même ? À ces questions répond une échelle de gravité simple, que vous écrirez une fois pour toutes dans votre plan et que vous appliquerez ensuite machinalement : mineur, pour un incident localisé sans donnée sensible et sans service arrêté ; majeur, pour un périmètre plus large ou un service public dégradé ; critique, pour une compromission avérée d'un serveur partagé, une perte de disponibilité durable ou l'exposition de données personnelles. Trois niveaux suffisent, à condition que chacun ait une consigne de notification associée.

```text
FICHE DE QUALIFICATION RAPIDE — incident INC-2026-014
------------------------------------------------------
1. Observation initiale    Fichiers illisibles sur POSTE-ACC-07,
                           note texte inconnue dans /Partage
2. Type d'atteinte         Disponibilité avérée + intégrité soupçonnée
3. Périmètre confirmé      1 poste, 1 dossier partagé en cours d'étude
4. Périmètre pressenti     Serveur de fichiers (les renommages y sont visibles)
5. Niveau retenu          MAJEUR — service public maintenu, données menacées
6. Source de détection     Humaine (documentaliste, 08 h 05) + technique
7. Actions immédiates      Isolement réseau, conservation des journaux
8. Notifier                Référent SI, directeur d'établissement
```

Une distinction mérite d'être soulignée parce qu'elle provoque d'étranges comportements : la source humaine de détection. Dans la très grande majorité des petites structures, le premier indice n'est pas une alerte automatique, c'est un collègue qui téléphone en disant que ça ne tourne pas normal. Cette observation est une source de détection à part entière, au même titre qu'un outil, à trois conditions : elle est horodatée à sa prise, elle est consignée par écrit, et elle est rattachée aux journaux techniques qui la confirment ou l'infirment. L'erreur consiste à la traiter comme une rumeur, ou pire, à laisser chacun enquêter de son côté en déplaçant la machine, en la redémarrant ou en effaçant ce qui semble bizarre. Une détection humaine bien enregistrée vaut mieux qu'une alerte mal réglée, précisément parce qu'elle porte un contexte : qui était là, ce qui a changé, ce que la personne a fait juste avant.

Enfin, déclarer tôt est toujours moins coûteux que déclarer tard. Un incident soupçonné classé sans suite après trente minutes d'analyse a coûté une demi-heure d'équipe. Le même incident non déclaré, découvert huit jours plus tard avec des journaux purgés par leur durée de conservation, coûte des semaines et parfois la perte définitive d'un dossier. Cette asymétrie justifie à elle seule que vous écriviez dans votre plan une phrase du type : toute personne qui soupçonne un incident ouvre une fiche, sans attendre de preuve définitive, et la fiche est refermée motivée si l'enquête conclut à un événement banal. La culture du signalement prévaut toujours sur la culture du silence, et elle ne se décrète pas, elle s'installe par la répétition.

- Un événement est une observation ; un incident menace la confidentialité, l'intégrité ou la disponibilité.
- Qualifier, c'est répondre à quatre questions : impact, périmètre, preuves, urgence.
- Trois niveaux de gravité suffisent : mineur, majeur, critique, avec notification associée.
- Un incident soupçonné se déclare avant d'être prouvé : on enquête ensuite.
- La détection humaine est une source légitime : horodater, consigner, recouper avec les journaux.
$lesson$),
  ('cyb-c6-p2', 'cyb-c6', 2, $lesson$Surveiller : les quatre familles de signaux$lesson$, $lesson$
Surveiller, ce n'est pas installer un maximum d'outils, c'est décider quels faits on veut voir passer devant ses yeux et s'assurer qu'ils sont enregistrés quelque part. Dans un parc de la taille de celui de la médiathèque, quatre familles de signaux couvrent l'essentiel, et chacune raconte une histoire différente. Les journaux d'authentification racontent qui a tenté d'entrer, avec quel compte, à quelle heure et depuis quel équipement. Les journaux de fichiers et d'intégrité racontent ce qui a changé sur les disques : créations, modifications, renommages, suppressions en masse. Le trafic réseau raconte ce qui circule : connexions sortantes, volumes anormaux, destinataires inhabituels. Les comptes et l'annuaire racontent qui dispose de droits, quels droits ont été ajoutés, quels comptes sont nés ou sont morts. Vous remarquerez que ces quatre familles répondent aux quatre questions de la qualification : qui, quoi, d'où, avec quels droits. C'est cette complémentarité qui fait leur force : une famille seule se contredit facilement, quatre familles croisées donnent une image difficile à réfuter.

La première famille, les journaux d'authentification, est la plus rentable à mettre en place parce qu'elle existe presque partout sans investment supplémentaire. Un serveur de fichiers, un annuaire, une messagerie, un pare-feu et une machine d'administration produisent déjà l'essentiel : ouvertures de session, échecs, réinitialisations, modifications de droits. Ce qui manque rarement, ce n'est pas la donnée, c'est la conservation. De nombreux systèmes purgent leurs journaux au bout de quelques jours, par défaut, faute de place disque. La question à poser d'abord est donc brutale : sur combien de jours remonte-t-on, et ce délai couvre-t-il au moins une semaine de vacation ? Deuxième exigence, l'horodatage : tous les systèmes doivent pointer la même heure, alimentée par une source de temps unique, sinon votre chronologie sera un montage approximatif où un fait paraît précéder sa cause. Troisième exigence, la protection : les journaux doivent être écrits sur un emplacement que la machine compromise ne peut pas réécrire, sinon l'attaquant referme la porte derrière lui en effaçant ce qu'il a fait.

La deuxième famille concerne les fichiers, et c'est elle qui parle le plus directement d'un chiffrement massif. Les signaux à surveiller tiennent en peu de mots : un volume anormal de créations, une vague de renommages suivie de suppressions, la modification soudaine d'un très grand nombre de fichiers sur un dossier partagé, l'apparition d'un fichier texte ou d'une archive là où il n'y en a jamais eu. Le chiffrement lui-même se traduit par un patron très lisible pour un outil qui compte : des milliers de fichiers touchés en quelques minutes, tous par le même processus, tous sur un même lecteur. La difficulté n'est pas de détecter ce patron une fois qu'il se produit, elle est de le détecter assez tôt et de ne pas le confondre avec une opération légitime de migration ou d'archivage. Un index d'intégrité, c'est-à-dire une empreinte calculée régulièrement sur les fichiers importants, transforme la question devinette en question chiffrée : si l'empreinte ne correspond plus, le contenu a changé.

```text
# Extrait — serveur de fichiers partage.lilas.local, lundi 6 octobre 2026
# Format : horodatage | source | niveau | message

06:58:12+02:00 fichier INFO  renommage par lot : 214 fichiers dans /Partage/Services/Rentree
06:58:44+02:00 fichier WARN  renommage par lot : 507 fichiers dans /Partage/Services/Rentree
06:59:07+02:00 fichier WARN  renommage par lot : 519 fichiers dans /Partage/Services/Rentree
07:12:31+02:00 fichier WARN  ecriture massive : 3 ordres par seconde depuis POSTE-ACC-07
07:26:03+02:00 partage  INFO  acces lecteur /Sauvegarde - compte stage.accueil - REFUSE
07:26:09+02:00 partage  INFO  acces lecteur /Sauvegarde - compte stage.accueil - REFUSE
08:05:47+02:00 (humain)  signal  documentaliste signale fichiers illisibles — POSTE-ACC-07

# Extrait — journal d'authentification du même matin
07:11:58+02:00 auth  NOTICE ouverture de session stage.accueil depuis POSTE-ACC-07
07:12:04+02:00 auth  NOTICE liste des dossiers ouverts : /Partage, /Partage/Services
07:13:40+02:00 auth  NOTICE ouverture de session stage.accueil depuis POSTE-ACC-07
07:19:22+02:00 auth  NOTICE compte stage.accueil - 38 ecritures en 46 secondes
```

La troisième famille est le réseau. Un poste compromis communique presque toujours : il cherche un serveur, il envoie des données, il reçoit des instructions, il tente d'atteindre des emplacements du réseau interne qu'il n'a pas l'habitude de visiter. Les signaux sont donc de deux ordres. Vers l'extérieur : une connexion vers une destination que vous n'avez jamais vue, un volume sortant sans rapport avec l'activité habituelle de la machine, un protocole inhabituel sur un port inattendu. Vers l'intérieur : un poste d'accueil public qui tente de joindre des postes de direction, un ordinateur qui sonde des plages d'adresses, un accès à un lecteur de sauvegarde refusé plusieurs fois de suite. Le dernier signal figure dans nos extraits de journaux, et il est particulièrement parlant : deux tentatives refusées sur le lecteur de sauvegarde, à 7 h 26, signifient qu'un compte a cherché à atteindre les sauvegardes depuis un poste qui n'y touche jamais. Rien de tout cela ne prouve à lui seul un incident, mais tout cela se corréle.

La quatrième famille, les comptes, est celle qu'on oublie le plus et qui cause les plus mauvaises surprises. Surveillez les créations de comptes, les ajouts de droits d'administration, les comptes dormants qui se réveillent, les mots de passe réinitialisés à un horaire inhabituel, et les comptes temporaires jamais fermés. Le compte stage.accueil de notre exemple appartient exactement à cette dernière catégorie : créé pour un stage de l'été, laissé actif par oubli, il n'appartenait à aucun changement récent et pourtant il était la clé. Un inventaire tenu à jour des comptes et de leurs propriétaires transforme cette question en quelques secondes : qui possède ce compte, que fait-il ici, pourquoi existe-t-il encore. Si la réponse est personne, vous venez de trouver une faiblesse structurelle bien avant d'avoir un incident.

```table
| Source surveillée | Ce qu'elle raconte | Signal utile à configurer |
| --- | --- | --- |
| Journaux d'authentification | Qui entre, avec quel compte | Échecs répétés suivis d'une réussite |
| Journaux de fichiers | Ce qui change sur les disques | Onde de renommage ou de création en rafale |
| Trafic réseau | Ce qui sort et ce qui entre | Destination inconnue ou accès refusé répété |
| Comptes et annuaire | Qui a des droits, depuis quand | Compte dormant qui se réveille ou droits ajoutés |
| Sauvegardes | Ce qui reste pour revenir en arrière | Job échoué, restauration non testée depuis longtemps |
```

- Les quatre familles se croisent : journaux, fichiers, réseau, comptes.
- Vérifiez la durée de conservation des journaux : au moins une semaine, idéalement davantage.
- Uniformisez l'heure de tous les équipements : une chronologie sans horodatage commun ne prouve rien.
- Centralisez la collecte sur un emplacement que le poste suspecté ne peut pas réécrire.
- Comptez les opérations sur les fichiers partagés : le chiffrement se voit comme une rafale.
- Confiez la lecture des journaux à une personne et à un créneau, sinon personne ne les lira.
$lesson$),
  ('cyb-c6-p3', 'cyb-c6', 3, $lesson$Des alertes utiles : signal, seuils et faux positifs$lesson$, $lesson$
Une alerte est un message qui dit : regardez maintenant, quelque chose mérite votre attention. Le danger n'est pas l'absence d'alertes, il est dans leur mauvaise qualité, et le symptôme est facile à reconnaître : quand toutes les alertes sonnent, plus personne n'écoute. On parle de bruit, ou de rapport signal sur bruit : la part du flux qui contient réellement de l'information utile. Si votre boîte reçoit deux cents messages par jour dont trois méritent une action, votre signal utile est de 1,5 %, et le réflexe humain appris en quelques semaines sera de tout filtrer. Le coût d'une alerte mal conçue n'est donc pas seulement du temps perdu, c'est la perte de confiance dans l'ensemble du dispositif. Une alerte que l'on ignore par habitude est plus dangereuse qu'une absence d'alerte, parce qu'elle crée l'illusion d'une surveillance qui ne fonctionne plus.

Écrire une alerte utile commence par répondre à cinq questions, dans cet ordre. Quel fait précis déclenche ce message, formulé en une phrase que n'importe quel collègue comprend sans jargon ? Quelle est la gravité associée, en distinguant clairement ce qui attend le matin de ce qui réveille l'astreinte ? Quel est le périmètre concerné, c'est-à-dire la machine, le compte ou le dossier visé ? Quelle est l'action immédiate attendue, ne serait-ce qu'un paragraphe de trois lignes à joindre au message ? Et enfin, quelle est la procédure complète, ce fameux mode opératoire écrit qui dit quoi vérifier dans quel ordre. Une alerte sans action immédiate est une notification ; une notification sans procédure laisse la personne seule devant son écran à 7 h du matin. Le test est simple : montrez votre alerte à quelqu'un qui n'a jamais vu votre système et demandez-lui ce qu'il ferait. S'il ne sait pas, l'alerte n'est pas prête.

Les seuils sont l'outil simple qui fait passer une règle de la théorie à la pratique. Un échec de connexion isolé n'intéresse personne ; dix échecs sur le même compte en deux minutes intéressent tout le monde ; quarante échecs répartis sur douze heures ne signifient probablement rien. Le seuil est donc une double borne : une quantité et une fenêtre de temps. Faites le raisonnement à rebours, à partir de ce que vous voulez détecter plutôt qu'à partir de ce que l'outil propose. Un chiffrement de dossier partagé se traduit par des centaines de modifications en quelques minutes : votre seuil doit se déclencher bien avant d'atteindre ce volume, par exemple à partir d'un ratio de modifications inhabituelles sur un dossier calme. Une intrusion par compte volé se traduit par des échecs puis une réussite : votre seuil doit couvrir la séquence, pas chaque échec isolé. Écrivez la justification du seuil dans un commentaire à côté de la règle : six mois plus tard, vous comprendrez pourquoi il a été choisi.

```yaml
# Exemple de règles d'alerte — document de configuration commenté
# Chaque règle porte : fait observé, seuil, fenêtre, gravité, action.

- nom: renommage-massif-partage
  fait: ratio renommages/creations sur un dossier partage
  seuil: 50 operations en 10 secondes
  fenetre: 10 secondes
  gravite: HAUTE
  action_immediate: isoler le poste emetteur du reseau, ouvrir une fiche

- nom: echecs-then-reussite
  fait: 5 echecs de session puis une reussite sur un meme compte
  fenetre: 5 minutes
  gravite: HAUTE
  action_immediate: desactiver le compte, verrouiller la session, interpeller le proprietaire

- nom: acces-sauvegarde-refuse
  fait: 2 tentatives refusees sur le lecteur de sauvegarde
  fenetre: 15 minutes
  gravite: MOYENNE
  action_immediate: identifier le compte et le poste, verifier l'integrite des sauvegardes

- nom: compte-dormant-active
  fait: ouverture de session sur un compte inactif depuis plus de 90 jours
  fenetre: 24 heures
  gravite: BASSE
  action_immediate: confirmer la propriete du compte, fermer si personne ne repond
```

Les faux positifs, ces alertes qui sonnent pour rien, font partie du paysage et il faut les traiter en connaissance de cause. Un script de sauvegarde qui modifie massivement des fichiers, une migration de données, un antivirus qui indexe tout le disque : autant de situations parfaitement légitimes qui déclenchent vos règles. Trois attitudes se font face. La première consiste à supprimer la règle dès qu'elle a crié une fois : on gagne du silence et on perd la détection. La seconde consiste à tout accepter : on garde tout et on finit par ne plus rien lire. La troisième, qui est la bonne, consiste à annoter : on ajoute à la règle une liste d'exceptions documentées, par exemple le compte de service de sauvegarde et la fenêtre de 22 h à 23 h 30, puis on mesure. Comptez chaque mois le nombre d'alertes levées et le nombre d'alertes qui ont conduit à une action réelle : ce taux de pertinence est l'indicateur de santé de votre surveillance. En dessous d'un quart, il faut revoir les seuils ; au-dessus des trois quarts, vous êtes peut-être trop étroit et vous risquez de rater l'inhabituel.

- Une alerte répond à cinq questions : fait, gravité, périmètre, action immédiate, procédure.
- Un seuil couple toujours une quantité et une fenêtre de temps, avec une justification écrite.
- Mesurez votre taux d'alertes pertinentes : sous un quart, revoir les seuils ; au-dessus, élargir.
- Traitez les faux positifs par des exceptions documentées, jamais par la suppression de la règle.
- Associez chaque niveau de gravité à un destinataire et à un canal, astreinte comprise.
- Testez la chaîne d'alerte par un exercice trimestriel, sinon elle cassera le jour utile.
$lesson$),
  ('cyb-c6-p4', 'cyb-c6', 4, $lesson$Les outils de référence : SIEM, EDR et HIDS$lesson$, $lesson$
Trois sigles reviennent dans toutes les brochures de cybersécurité, et ils finissent par se confondre dans les conversations : SIEM, EDR, HIDS. Il faut les démêler, parce qu'ils ne répondent pas à la même question et que se tromper d'outil revient à installer une caméra là où il fallait une serrure. Le SIEM répond à la question qu'est-ce qui s'est passé sur l'ensemble de mon système, hier et cette semaine. L'EDR répond à la question que se passe-t-il sur ce poste, en ce moment, processus par processus. Le HIDS répond à la question est-ce que quelqu'un vient de violer une règle que je connais, en modifiant des fichiers ou en exécutant quelque chose d'inhabituel. Un quatrième terme complète le trio quand on parle du réseau : l'inspection de trafic, qui observe ce qui circule entre les machines. Aucun de ces outils ne remplace les sauvegardes, aucun ne remplace les mises à jour, et aucun ne travaille si personne ne lit ses sorties.

Le SIEM, ou système de gestion des journaux et des alertes de sécurité, est une centrale : il collecte les journaux de vos équipements, les range, les corrèle et les présente. Sa force est la vue transverse. C'est le seul endroit où vous pouvez demander ce que faisait ce compte à 7 h 12 et obtenir en une réponse la connexion, les fichiers ouverts, les tentatives refusées et les connexions réseau correspondantes. Il conserve aussi l'historique, ce qui permet de remonter le temps lorsqu'un incident est découvert avec du retard. Sa faiblesse est bien connue : au démarrage, il est bruyant. Les premiers mois se passent à éteindre ce qui sonne pour rien et à affiner, ce qui demande du temps et un peu de méthode. Une structure modeste n'a pas besoin d'une plateforme industrielle pour commencer : un serveur de collecte qui centralise les journaux de dix équipements, conservés plusieurs mois, constitue déjà un SIEM à taille humaine.

L'EDR, ou détection et réponse sur les postes, se déploie sous la forme d'un agent installé sur les machines. Là où un antivirus compare une signature connue, l'EDR observe le comportement : quels programmes se lancent, vers quels fichiers ils écrivent, quelles chaînes de processus s'enchaînent, quels réglages système sont modifiés. Pour notre incident de médiathèque, c'est l'outil qui parle le mieux : une vague de renommages exécutée par un processus né de telle application, sur un dossier ouvert par un compte de stagiaire, c'est exactement le patron que l'agent voit se dessiner. L'EDR apporte en plus une capacité de réaction : isoler un poste du réseau à distance, sans que quiconque ait à traverser la salle, et suspendre un processus en cours. Ses limites sont celles de tout agent : il faut le déployer partout, le régler pour ne pas saturer, et prévoir de la puissance pour héberger ses données.

Le HIDS, ou détection d'intrusion hébergé, travaille lui aussi sur la machine, mais avec une autre méthode : il compare l'état du système à une référence. Il surveille l'intégrité de fichiers critiques, repère l'apparition d'un nouveau service, signale l'ouverture d'un port inhabituel, détecte l'exécution d'une commande inattendue. Un contrôle d'intégrité bien réglé sur les dossiers partagés aurait signalé, dès les premières minutes, que les fichiers du dossier Services ne correspondent plus à leur empreinte d'hier. Son cousin réseau, souvent désigné par la même famille de sigles, inspecte le trafic et applique des règles : connexion vers une destination jamais vue, protocole anormal, balayage d'adresses. Ces outils sont anciens, robustes, et ils restent d'excellents garde-fous pour une organisation qui veut de la détection sans poser un agent sur chaque poste.

```text
VUE DE CORRÉLATION — 6 octobre, 06 h 50 à 08 h 10 — parc Médiathèque des Lilas
================================================================================

[06:58] serveur partage   WARN   renommages en rafale (1 240 fichiers, 55 s)
                                     |
[07:11] journal auth      NOTICE ouverture stage.accueil @ POSTE-ACC-07
                                     |
[07:12] serveur partage   WARN   ecriture massive depuis le meme poste
                                     |
[07:26] serveur partage   INFO   2 acces refuses au lecteur /Sauvegarde
                                     |
                          +---------+----------+
                          |  CORRELATION :     |
                          |  meme compte,      |
                          |  meme poste,       |
                          |  fenetre de 28 min |
                          +---------+----------+
                                     |
                                     v
[08:05] signalement humain : fichiers illisibles sur le meme poste
                                     |
                                     v
                       ALERTE HAUTE — INC-2026-014 ouverte
                       action : isolation + conservation des journaux
```

Il existe aussi des solutions libres très répandues pour les trois familles, ce qui permet de commencer sans budget d'acquisition : des agents de contrôle d'intégrité de fichiers et de collecte de journaux pour le poste et le serveur, des moteurs d'inspection de trafic pour le réseau, et des outils de centralisation pour la corrélation. Citez-les dans votre plan comme des options, pas comme des obligations : l'essentiel est le comportement attendu, collecter, comparer, alerter, conserver, plutôt que la marque du produit. Une solution gratuite bien réglée vaut infiniment mieux qu'une solution chère installée puis oubliée derrière un onglet que personne n'ouvre.

- Le SIEM répond à qu'est-ce qui s'est passé partout ; l'EDR à que se passe-t-il sur ce poste.
- Le HIDS compare l'état actuel du système à une référence et signale les écarts.
- Centraliser les journaux dès le début, même avec un simple serveur dédié, prime sur tout achat.
- Commencez par la journalisation, les sauvegardes testées et l'authentification forte.
- Une solution libre bien réglée vaut mieux qu'un tableau de bord chèrement acheté puis ignoré.
$lesson$),
  ('cyb-c6-p5', 'cyb-c6', 5, $lesson$La réponse en six phases : de la préparation aux leçons$lesson$, $lesson$
Les modèles de gestion de crise convergent tous, quel que soit le référentiel que vous consultez : un incident se traverse en six phases, et ces phases ne sont pas une cérémonie administrative, ce sont des décisions à prendre dans un ordre donné. La première est la préparation, qui a lieu avant tout incident. La deuxième est la détection et la qualification, qui transforme un signal en fiche. La troisième est le confinement, qui arrête l'aggravation. La quatrième est l'éradication, qui supprime la cause. La cinquième est la récupération, qui remet le service en état. La sixième consiste à tirer les leçons et à améliorer le plan. Chaque phase a un livrable identifiable, ce qui permet de savoir, même en pleine nuit, où vous en êtes. Sans cette grille, une équipe se disperse : certains cherchent à comprendre pendant que d'autres réparent, et personne ne décide.

La préparation est la phase la plus rentable et la moins visible, parce qu'elle ne se voit que le jour où elle fait défaut. Elle se résume à cinq choses écrites, quelque part, accessibles hors ligne. Un plan d'incident d'une ou deux pages qui dit qui décide, qui fait quoi et comment on se contacte. Une liste de contacts à jour : direction, référent technique, prestataire, autorité compétente en cas de déclaration obligatoire, assistance. Des rôles nommés : qui a le droit d'isoler un poste, qui a le droit de couper un service, qui parle aux usagers. Un kit de collecte : un support propre pour recueillir les journaux, une procédure de copie, une manière de calculer une empreinte pour vérifier qu'une copie n'a pas été altérée. Et des sauvegardes testées, parce que la seule phase qui échoue réellement dans la plupart des incidents, c'est la récupération, quand on découvre que la dernière restauration datait de deux ans. Un exercice de table, deux heures par an autour d'un scénario comme celui de notre médiathèque, vaut mieux que cent pages de théorie non lues.

```text
                     +----------------------------+
                     |   1. PRÉPARATION           |
                     | plan, rôles, contacts,     |
                     | kit de collecte, sauvegarde|
                     +-------------+--------------+
                                   |
                                   v
              +--------------------+--------------------+
              |  2. DÉTECTION ET QUALIFICATION          |
              | signal + analyse -> fiche horodatée     |
              +--------------------+--------------------+
                                   |
                                   v
              +--------------------+--------------------+
              |  3. CONFINEMENT                         |
              | isoler le périmètre, nouvelle source ---+--> retour en 2
              +--------------------+--------------------+
                                   |
                                   v
              +--------------------+--------------------+
              |  4. ÉRADICATION                         |
              | supprimer la cause, nettoyer, prouver   |
              +--------------------+--------------------+
                                   |
                                   v
              +--------------------+--------------------+
              |  5. RÉCUPÉRATION                        |
              | restaurer, valider, surveillance        |
              +--------------------+--------------------+
                                   |
                                   v
              +--------------------+--------------------+
              |  6. LEÇONS                              |
              | rétrospective -> corrections -> étape 1 |
              +--------------------+--------------------+

Boucle : chaque nouveau signal en cours de phases ramène immédiatement
à la détection, puis au confinement. On ne descend pas une fois pour toutes.
```

```table
| Phase | Objectif principal | Livrable attendu | Question à se poser |
| --- | --- | --- | --- |
| 1. Préparation | Être prêt avant le jour J | Plan écrit, rôles, contacts, sauvegardes testées | Savons-nous qui fait quoi à 3 h du matin ? |
| 2. Détection | Voir et qualifier | Fiche d'incident horodatée et périmètre | Qu'est-ce qui s'est passé, quand et jusqu'où ? |
| 3. Confinement | Arrêter l'aggravation | Périmètre isolé, décisions tracées | Comment stopper sans effacer les traces ? |
| 4. Éradication | Supprimer la cause | Éléments compromis retirés, preuves conservées | Tout est-il propre et vérifié ? |
| 5. Récupération | Remettre en service | Systèmes restaurés, testés, surveillés | Les données reviennent d'où ? |
| 6. Leçons | Progresser | Rapport et plan d'action daté | Que change-t-on pour que ça ne recommence pas ? |
```

Le confinement vise un seul objectif : empêcher l'aggravation pendant que l'on comprend. Il se décompose en deux horizons. Le court terme est souvent brutal et rapide : déconnecter un poste du réseau, suspendre un compte, fermer un accès à distance, basculer un service sur un mode dégradé. Le long terme vient juste après : mettre le poste en quarantaine dans un réseau isolé, conserver son état pour l'analyse, rétablir un service d'accueil sur un poste sain. Les deux se distinguent par leur durée et leur niveau de réflexion, pas par leur urgence. Nous y reviendrons en détail dans la section consacrée au confinement, car c'est le moment où l'on détruit le plus souvent, par précipitation, la capacité de comprendre ce qui s'est passé.

L'éradication supprime la cause : le mécanisme qui a permis la compromission. Il peut s'agir d'un programme à retirer, d'un compte à recréer avec un mot de passe neuf, d'un accès à supprimer, d'une faille à corriger, d'un service mal configuré à remettre en état. Elle se distingue du confinement par un critère simple : le confinement stoppe les effets, l'éradication supprime la raison pour laquelle ils pouvaient se produire. La récupération qui suit restaure les données et les services à partir de sources fiables, teste chaque remise en marche, puis maintient une surveillance renforcée pendant plusieurs jours, parce que les heures qui suivent une remise en service sont celles où une rechute se repère le mieux. La phase de leçons, enfin, clôt la boucle : elle transforme l'incident en modifications concrètes du plan, des alertes et des configurations, avec un responsable et une date pour chacune.

- Six phases : préparation, détection, confinement, éradication, récupération, leçons.
- Chaque phase produit un livrable identifiable, sinon on ne sait pas où on en est.
- La préparation se vérifie avant l'incident : plan, rôles, contacts, kit de collecte, sauvegardes testées.
- Les phases ne sont pas linéaires : tout nouveau signal ramène à la détection et au confinement.
- Le confinement stoppe les effets, l'éradication supprime la cause.
- Les leçons doivent se traduire en actions datées et attribuées, pas en intentions.
$lesson$),
  ('cyb-c6-p6', 'cyb-c6', 6, $lesson$Constituer la chronologie fiable : sources, horodatage et chaîne de preuve$lesson$, $lesson$
La chronologie est l'ossature du rapport d'incident et l'objet le plus précieux que vous produisiez. Elle répond à la question que tout le monde posera, direction comprise : dans quel ordre les choses se sont-elles réellement passées. Une chronologie honnête permet de distinguer ce qui a été observé de ce qui a été déduit, d'identifier le premier signal, de mesurer le temps de détection et le temps de confinement, et de répondre plus tard à un tiers qui examinera le dossier. À l'inverse, une chronologie approximative — quelques heures reconstituées de mémoire — fragilise tout le rapport, même excellent par ailleurs. C'est pourquoi il faut la construire dès les premières minutes, avec une méthode simple, plutôt que de la reconstituer trois semaines plus tard à partir de souvenirs et de courriels.

Commencez par lister vos sources, et pour chacune, notez son niveau de fiabilité. Les journaux des équipements sont la meilleure source, à condition que leur horloge soit fiable et que le fichier n'ait pas pu être modifié. Les journaux centralisés, reçus sur un autre serveur, sont meilleurs encore, parce que la machine suspectée ne peut pas les réécrire. Viennent ensuite les relevés humains : la note prise par la documentaliste à 8 h 07, l'appel téléphonique consigné, la capture d'écran horodatée. Puis les journaux de sauvegarde, qui disent ce qui a été copié et quand. Enfin, les déductions, qui n'ont pas lieu d'être dans la colonne des faits. Une règle de classement simple vous évitera bien des discussions : ce qui provient d'un système avec une horloge synchronisée est un fait ; ce qui provient d'un humain est un témoignage, utile mais daté de sa prise et non de l'événement lui-même ; ce qui provient de votre mémoire est une hypothèse, à écrire comme telle.

```text
CHRONOLOGIE CONSOLIDÉE — INC-2026-014 — Médiathèque des Lilas
Source de temps : UTC+2, synchronisée sur le contrôleur de domaine

HEURE      FAIT OBSERVÉ                                     SOURCE               CONFIANCE
--------   ----------------------------------------------   ------------------   ---------
06:58:12   1re vague de renommages, 214 fichiers            journal serveur      haute
06:59:07   3e vague : 1 240 fichiers touchés au total        journal serveur      haute
07:11:58   Ouverture de session stage.accueil                journal auth         haute
07:12:31   Écriture massive depuis POSTE-ACC-07              journal serveur      haute
07:26:03   Deux accès refusés sur /Sauvegarde, même compte   journal partage      haute
08:05:47   Signalement : fichiers illisibles                 note humaine         moyenne
08:07:10   Première note prise par écrit, poste ouvert       note humaine         moyenne
08:19:10   Poste déconnecté du réseau par le référent SI     registre d'actions   haute
08:40:00   Sauvegarde de 22 h 10 vérifiée, intacte            journal sauvegarde   haute
09:00:00   Ouverture de la fiche INC-2026-014                 registre             haute

Colonnes obligatoires : heure, fait, source, confiance.
Toute lacune est écrite tel quelle : "07:00 - 07:11 : rien, journaux absents ?"
```

Quelques règles d'or rendent la chronologie défendable. Premièrement, transcrivez les valeurs exactes des journaux, heure à la seconde comprise, sans les arrondir à la dizaine de minutes : c'est la précision qui permettra d'apparier un événement réseau avec un événement de fichiers. Deuxièmement, mentionnez systématiquement le fuseau et l'heure d'été ou d'hiver, car une chronologie mixte est inutilisable. Troisièmement, notez les trous : si rien n'est enregistré entre 7 h et 7 h 11, écrivez-le, un vide explicite vaut mieux qu'une ligne inventée. Quatrièmement, séparez soigneusement la colonne des faits de la colonne des interprétations ; le mot selon nous n'a pas sa place dans une chronologie, il a sa place dans l'analyse qui suit. Cinquièmement, datez chaque action de l'équipe : à quelle heure le poste a été isolé, par qui, sur quelle décision. Cette dernière colonne est celle que la direction lira avec le plus d'attention, puisqu'elle mesure votre réactivité.

La chaîne de preuve complète la chronologie : elle raconte qui a manipulé quelle information, à quel moment, et comment vous savez qu'elle n'a pas été altérée. Concrètement, cela tient en quelques pratiques accessibles à tous. Conservez l'original du fichier de journal et travaillez sur une copie ; calculez une empreinte de la copie au moment de la collecte, ce petit résumé numérique unique qui change si un seul octet bouge, et notez cette empreinte dans la chronologie ; inscrivez chaque transfert sur une fiche, avec la date, la personne, le support et la destination ; rangez les éléments dans un dossier unique nommé avec l'identifiant de l'incident. Aucune de ces démarches ne demande de laboratoire, et toutes répondent à la même objection tardive : comment prouver que ce fichier que vous présentez aujourd'hui est bien celui qui existait ce matin-là. Sans cette rigueur, votre rapport racontera une histoire probablement exacte, mais invérifiable.

```text
FICHE DE MANIPULATION D'UNE PREUVE — INC-2026-014
--------------------------------------------------
Objet          copie journal_partage_20261006.log
Origine        serveur partage.lilas.local, /var/log/partage
Copie le       06/10/2026 08 h 24 par N. Ferrand (référent SI)
Support        clé USB scellée, pochette A, rangement coffre
Empreinte      SHA-256 9f2c... (calculée à la copie, notée ci-dessous)
Modifié le     jamais — les analyses se font sur une seconde copie
Transféré à    dossier INC-2026-014, le 06/10/2026 11 h 05
Observations   une ligne manque à 07 h 04 : journal rotation à minuit
```

- Ouvrez la chronologie dès l'ouverture de la fiche, pas à la fin de l'enquête.
- Une ligne = heure à la seconde, fait, source, niveau de confiance.
- Notez les trous et les écarts d'horloge au lieu de les lisser.
- Témoignage humain et fait système restent dans deux colonnes distinctes.
- Travaillez sur copie, calculez une empreinte, consignez chaque transfert.
- Chronométrez le temps de détection et le temps de confinement : ce sont vos indicateurs.
$lesson$),
  ('cyb-c6-p7', 'cyb-c6', 7, $lesson$Confinement : isoler sans détruire les preuves$lesson$, $lesson$
Le confinement est le moment où la vitesse compte et où la précipitation coûte cher. L'objectif est double et ces deux moitiés tirent parfois dans des directions opposées : arrêter l'aggravation au plus vite, et conserver l'état du système suffisamment pour comprendre ce qui s'est passé. Une équipe qui ne pense qu'à la vitesse débranche, redémarre, réinstalle et efface au passage la seule trace qui aurait permis de savoir comment la compromission s'est produite. Une équipe qui ne pense qu'à la compréhension laisse tourner un poste qui continue de chiffrer un dossier partagé pendant que l'on discute. La bonne pratique consiste donc à séparer explicitement deux décisions : ce que l'on arrête maintenant, et ce que l'on préserve pour l'analyse, en notant l'heure et l'auteur de chaque geste.

Les leviers de confinement sont peu nombreux, et il est utile de les connaître à l'avance pour ne pas improviser. Le premier est le réseau : déconnecter un poste du réseau, désactiver son port commutateur, le placer dans un segment isolé. C'est le geste le plus efficace contre la propagation, et il est réversible en quelques secondes. Le deuxième est le compte : suspendre la session ouver, réinitialiser le mot de passe, désactiver le compte suspect. Il est essentiel quand le mouvement a traversé plusieurs machines avec un même identifiant. Le troisième est le service : couper un accès à distance, mettre une file d'attente devant un service exposé, basculer l'accueil sur un poste sain. Le quatrième, enfin, est la machine elle-même : la mettre hors service, en la laissant allumée ou en l'éteignant selon une décision tracée, jamais par habitude.

Cette dernière alternative mérite qu'on s'y attarde, car elle fait l'objet des plus grands malentendus. Laisser la machine allumée mais déconnectée conserve l'état de la mémoire vive, les processus en cours et les fichiers temporaires, autant d'éléments qui racontent ce qui se passait au moment précis de l'intervention. Éteindre la machine arrête net toute opération en cours, ce qui peut être souhaitable si elle détruit encore des données, mais fait disparaître ce que la mémoire contenait. Aucune règle universelle ne tranche : la décision dépend de ce qui se produit encore au moment où vous intervenez. Ce qui est universel, en revanche, c'est la traçabilité : vous écrivez à quelle heure la décision a été prise, par qui, sur quel constat, et quelles informations ont été relevées avant de passer à l'acte. Si vous optez pour la conservation, ajoutez une copie de la mémoire à votre dossier de preuves tant que la machine tourne encore, c'est l'une des rares informations qui disparaissent définitivement à l'extinction.

```text
LISTE DE CONTRÔLE — CONFINEMENT INC-2026-014
=============================================
[ ] 1. Constat écrit : heure de prise, personne, ce qui est observé
[ ] 2. Chronologie ouverte, premières lignes saisies
[ ] 3. Isolation réseau de POSTE-ACC-07 (câble ou port commutateur)
[ ] 4. Compte stage.accueil suspendu, mot de passe réinitialisé
[ ] 5. Session ouverte fermée après relevé des processus en cours
[ ] 6. Fichiers partagés suspects : lecture seule, aucun déplacement
[ ] 7. Note texte inconnue copiée dans le dossier de preuves
[ ] 8. Journaux du serveur de fichiers copiés + empreinte calculée
[ ] 9. Registre d'actions : heure, auteur, décision pour chaque ligne
[ ] 10. Poste taggé "NE PAS UTILISER", état photographié
[ ] 11. Service maintenu : accueil basculé sur poste sain
[ ] 12. Direction informée, fiche INC-2026-014 mise à jour

Une seule règle au-dessus de tout : rien n'est effacé, rien n'est
redémarré, rien n'est réinstallé avant que la collecte soit faite.
```

Le confinement doit aussi prévoir la continuité du service public, ce qui est souvent absent des modèles importés du monde de l'entreprise. Une médiathèque ne peut pas annoncer que l'accueil est fermé pendant deux jours sans prévenir personne. Définissez à l'avance un mode dégradé : prêts et retours sur papier, inscription manuelle, poste de secours isolé du réseau principal, message d'information à l'entrée et sur le site. Ce volet n'est pas cosmétique, il réduit la pression sur l'équipe pendant l'incident : quand le service a un plan B, personne ne pousse l'équipe à rétablir trop vite un système qu'on n'a pas encore vérifié. Ajoutez-y la question des communications : qui informe les usagers, avec quel texte, et surtout qui évite de détailler publiquement ce qui a été trouvé, puisque la transparence totale pendant l'enquête aide souvent ceux qui observent de l'extérieur.

- Confiner, c'est faire deux choses : arrêter l'aggravation et préserver l'état.
- Quatre leviers : réseau, compte, service, machine — choisissez-les à l'avance.
- Décidez explicitement entre conserver la machine allumée ou l'extinction, et tracez la décision.
- Aucun nettoyage, aucune restauration par-dessus, aucune suppression pendant le confinement.
- Tenez le registre d'actions : heure, auteur, décision, motif, pour chaque geste.
- Maintenez un mode dégradé du service pour ne pas subir la pression du rétablissement rapide.
$lesson$),
  ('cyb-c6-p8', 'cyb-c6', 8, $lesson$Éradication et récupération : sauvegardes, réinstallation et validation$lesson$, $lesson$
L'éradication répond à une question précise : pourquoi cela a-t-il pu se produire, et comment je fais pour que ce ne soit plus possible. Elle commence par un inventaire des éléments compromis, écrit ligne à ligne : le poste touché, le compte utilisé, le dossier partagé modifié, le service qui a servi de point d'entrée, la configuration défaillante qui a rendu l'exploitation possible. Cet inventaire conditionne tout le reste : on n'éradique pas ce qu'on n'a pas nommé. Vérifiez aussi ce qui a pu être ajouté sans laisser de trace immédiate : comptes locaux créés, droits accordés, tâches planifiées, programmateurs de tâches, accès distants, clés d'accès. Un incident de chiffrement est souvent la partie visible d'un mouvement plus large, et l'éradication consiste à fermer toutes les portes, pas seulement celle par laquelle on a vu entrer.

Pour les postes, la règle professionnelle est simple et un peu sévère : on repart propre. Une réinstallation à partir de votre image de référence, ou une remise à neuf complète, vaut mieux qu'un nettoyage en place, parce que le nettoyage démonte ce qu'il trouve mais ne prouve jamais l'absence de ce qu'il n'a pas trouvé. La question n'est pas que l'outil ait retiré tel fichier, elle est de savoir si la machine est aujourd'hui exactement ce que vous décrivez dans votre documentation. Pour les comptes, la règle est du même ordre : mots de passe réinitialisés pour tout compte ayant ouvert une session sur le périmètre concerné, sessions en cours fermées, droits revus, et le compte stage.accueil de notre exemple clos définitivement puisqu'il n'avait plus de propriétaire. Pour les partagés, on compare avec une copie connue bonne et on restaure ce qui diffère, après s'être assuré que la source de restauration est elle-même saine.

```text
CHECKLIST DE REMISE EN SERVICE — INC-2026-014
==============================================
ÉTAT DES LIEUX
[ ] Inventaire écrit des éléments compromis (postes, comptes, dossiers, services)
[ ] Cause identifiée et correction appliquée (correctif, configuration, compte)

POSTES
[ ] POSTE-ACC-07 réinstallé à partir de l'image de référence
[ ] Aucun compte local ajouté ne subsiste, aucune tâche inconnue
[ ] Agent de surveillance en place et remontée vérifiée

COMPTES ET DROITS
[ ] stage.accueil clos, mot de passe des comptes exposés changé
[ ] Sessions ouvertes fermées, droits administrateur revalidés

DONNÉES
[ ] Point de restauration choisi : avant 06 h 58, premier signal
[ ] Restauration effectuée dans un environnement propre puis contrôlée
[ ] Échantillon de fichiers ouverts et comparé à l'original
[ ] Fichiers suspects déposés dans le dossier de preuves, jamais écrasés

VALIDATION
[ ] Test fonctionnel complet par le service concerné
[ ] Surveillance renforcée 14 jours, alertes de suivi actives
[ ] Rétablissement progressif des accès, moindre privilège
```

Les sauvegardes sont ici le cœur du sujet, et elles méritent trois précautions que l'on découvre trop tard. La première concerne le point de restauration : il doit être choisi avant le premier signal de l'incident, pas au plus proche de la découverte. Dans notre chronologie, la sauvegarde de 22 h 10 la veille est postérieure à aucune activité suspecte connue, elle constitue donc un point de départ légitime, à condition d'être vérifiée. La deuxième précaution concerne la propreté de la sauvegarde : une copie réalisée pendant la compromission peut contenir l'état abîmé, et restaurer sans vérifier revient à installer le problème à nouveau. D'où l'importance des copies hors ligne ou peu modifiables, que ni la machine compromise ni un compte de gestion standard ne peuvent altérer. La troisième précaution est la plus prosaïque : une sauvegarde jamais restaurée n'est pas une sauvegarde, c'est un espace disque occupé. Un test de restauration périodique, sur un échantillon représentatif, transforme une promesse en capacité démontrable.

- Nommez chaque élément compromis avant de le traiter : on n'éradique pas l'implicite.
- Privilégiez la réinstallation propre d'un poste au nettoyage en place, non vérifiable.
- Choisissez le point de restauration avant le premier signal, jamais au plus proche de la découverte.
- Vérifiez la propreté et la résistance de la sauvegarde avant de vous y fier.
- Testez régulièrement une restauration réelle : sans test, la sauvegarde n'existe qu'en théorie.
- Rétablissez les accès progressivement, au moindre privilège, sous surveillance renforcée.
$lesson$),
  ('cyb-c6-p9', 'cyb-c6', 9, $lesson$Communication : à qui, quand et quoi dire$lesson$, $lesson$
Une réponse technique parfaite mal communiquée produit deux dégâts : la rumeur à l'intérieur, et la perte de confiance à l'extérieur. La communication pendant un incident n'est pas un supplément d'âme, c'est une phase de la réponse, avec ses règles et ses livrables. Elle répond à un besoin simple : pendant que l'équipe travaille, tout le monde cherche à savoir où en est, et dans ce vide s'installent les versions approximatives qui coûtent plus cher que l'incident lui-même. Une direction qui apprend l'incident par un agent inquiet, des usagers devant une porte fermée sans explication : autant de situations évitables par une information brève, régulière et exacte.

La première décision est de nommer un seul porte-parole. Toute demande d'information, interne comme externe, converge vers cette personne, qui relaie à l'équipe technique les questions et à tous les interlocuteurs les réponses validées. Les techniciens, de leur côté, se concentrent sur la réponse et ne commentent pas l'incident parallèlement dans un message instantané ou sur un réseau social : deux versions, même légèrement différentes, suffisent à détruire la crédibilité du suivi. La chaîne hiérarchique se déclare à l'avance : référent technique, direction d'établissement, service intercommunal ou direction des systèmes d'information, puis, selon la nature de l'incident et les obligations applicables, l'autorité compétente ou le point de contact national de sécurité informatique, désigné en clair dans le plan sans jargon. Prévoyez aussi le prestataire d'assistance et, le cas échéant, l'assurance, avec les coordonnées déjà rédigées.

```text
MODÈLE DE COMMUNICATION INTERNE — 6 lignes, envoi à la direction
----------------------------------------------------------------
Objet : INC-2026-014 — point de situation du 6 octobre, 9 h 30
1. Constat : chiffrement constaté ce matin sur un poste d'accueil, découvert à 8 h 05.
2. Périmètre : 1 poste isolé, 1 dossier partagé touché, service public maintenu en mode dégradé.
3. Causes : non établies ; un compte de stagiaire non désactivé est en cours de vérification.
4. Actions : poste isolé à 8 h 19, compte suspendu, journaux conservés, sauvegarde vérifiée.
5. Restauration : envisagée à partir de la copie de la nuit, test préalable en cours.
6. Prochain point : 11 h. Contact unique : référent SI, poste 42.
```

Quoi dire, en pratique, tient en quatre catégories de contenu. Les faits confirmés, avec leurs heures et leurs sources. L'impact réel sur les usagers et sur les services, y compris ce qui continue de fonctionner, car l'absence d'information est toujours comblée par le pire des scénarios. Les actions en cours et celles qui sont déjà prises, ce qui montre que la situation est tenue. Et le canal de contact, c'est-à-dire la personne à qui poser les questions. En dehors de ces catégories, deux silences s'imposent : on ne communique pas les détails techniques d'exploitation tant que l'enquête court, et on ne discute pas publiquement du contenu d'une éventuelle note laissée par les attaquants. Aucune instruction figurant dans un tel document n'est suivie, son contenu n'est pas diffusé, et la récupération repose exclusivement sur les systèmes remis en état et les sauvegardes vérifiées : cette position, écrite à l'avance, évite d'improviser sous pression.

- Un seul porte-parole ; les techniciens ne commentent pas l'incident en parallèle.
- Informez dès la qualification, même avec un périmètre encore flou.
- Annoncez toujours l'heure du prochain point plutôt qu'un délai de résolution incertain.
- Quatre blocs de contenu : faits confirmés, impact, actions en cours, contact.
- Ne divulguez pas les détails d'exploitation pendant l'enquête ni le contenu d'une note.
- Conservez des traces horodatées des communications : elles font partie de la chronologie.
$lesson$),
  ('cyb-c6-p10', 'cyb-c6', 10, $lesson$Le rapport d'incident : structure type$lesson$, $lesson$
Le rapport d'incident est le document qui transforme une matinée chaotique en un acquis durable. Il s'adresse à plusieurs lecteurs à la fois : la direction, qui veut comprendre ce qui s'est passé et ce que cela a coûté ; l'équipe technique, qui veut retrouver les détails ; un tiers, autorité ou assurance, qui examinera le dossier avec un œil extérieur. Ces trois lectures imposent une règle unique : le rapport doit se comprendre sans qu'on ait besoin d'expliquer à voix haute ce que l'auteur voulait dire. Il se rédige après la récupération, mais il se nourrit de tout ce qui a été écrit pendant l'incident : fiche de qualification, chronologie, registre d'actions, communications envoyées. C'est pour cela que la discipline de la journée paie si bien : le rapport n'est alors qu'un assemblage, pas une reconstitution.

La structure type comporte huit parties, dans cet ordre. Un résumé exécutif d'une page, écrit en dernier, qui dit quoi, quand, sur quel périmètre, avec quel impact et quelles mesures ont été prises. Une chronologie complète, issue du travail horodaté. Un périmètre et un impact chiffrés : postes, comptes, dossiers, nombre de fichiers concernés, durée d'indisponibilité, service maintenu ou dégradé. Un récit des actions menées, phase par phase, avec les décisions et leurs motifs. Les causes et les facteurs contributifs, c'est-à-dire non seulement le fait déclenchant mais les conditions qui l'ont rendu possible : compte oublié, sauvegarde non testée, alerte non configurée. Les preuves et sources, avec les empreintes et les emplacements de conservation. Les recommandations, hiérarchisées. Et les annexes : captures, extraits de journaux, modèles utilisés.

```text
GABARIT — RAPPORT D'INCIDENT INC-2026-014
==========================================
1. RÉSUMÉ EXÉCUTIF (1 page, rédigé en dernier)
   Quoi / Quand / Où / Impact / Ce qui a été fait / Ce qui reste à faire

2. CHRONOLOGIE
   Tableau heure / fait / source / confiance + temps de détection, de
   confinement et de restauration

3. PÉRIMÈTRE ET IMPACT
   Postes, comptes, dossiers, fichiers concernés, services dégradés,
   durée d'indisponibilité, données potentiellement exposées

4. ACTIONS MENÉES
   Phase par phase : décisions, auteurs, heures, résultats

5. CAUSES ET FACTEURS CONTRIBUTIFS
   Déclencheur + conditions (compte dormant, sauvegarde, alerte, droit)

6. PREUVES ET SOURCES
   Journaux copiés, empreintes, emplacements, conservation

7. RECOMMANDATIONS
   Mesure | Responsable | Échéance | Indicateur de réussite

8. ANNEXES
   Fiche de qualification, communications envoyées, extraits de journaux
```

Les règles d'écriture font la différence entre un rapport lu et un rapport rangé. Restez factuels : un compte n'a pas été désactivé lors du départ d'un stagiaire, plutôt que tel collaborateur a oublié de le faire. Chiffrez : temps de détection de trente-cinq minutes, mille deux cent quarante fichiers renommés, un poste isolé, quatorze jours de surveillance. Expliquez le jargon en une phrase, parce que le lecteur de direction n'a pas votre vocabulaire. Ne noyez pas : si le lecteur doit chercher, il ne lira pas. Et signalez honnêtement les zones d'ombre : ce que vous n'avez pas pu déterminer, avec la raison, et ce que vous proposez pour le découvrir. Un rapport qui prétend tout savoir perd sa crédibilité dès la première question, alors qu'un rapport qui délimite précisément son savoir est difficile à contester.

- Le rapport suit huit parties : résumé, chronologie, périmètre, actions, causes, preuves, recommandations, annexes.
- Écrivez le résumé exécutif en dernier, une page maximum.
- Chiffrez tout : durées, volumes, nombres de postes et de comptes.
- Restez factuels et attribuez les faits à des systèmes, pas à des personnes.
- Signalez les zones d'ombre et leur cause plutôt que de les masquer.
- Diffusez largement le plan d'action, gardez le rapport complet sous contrôle.
$lesson$),
  ('cyb-c6-p11', 'cyb-c6', 11, $lesson$Rétrospective et amélioration du plan$lesson$, $lesson$
La rétrospective est la sixième phase, celle qu'on saute toujours quand le service est rétabli et que tout le monde est fatigué. C'est pourtant celle qui décide si l'incident se reproduira. Organisez-la dans les jours qui suivent la remise en service, avec les personnes qui ont réellement agi, celles qui ont subi l'incident côté métier, et si possible une personne extérieure à l'équipe qui posera les questions gênantes. La règle d'or de cette réunion est qu'elle ne recherche pas de coupable : chercher qui est fautif produit des récits défensifs et des informations tronquées, alors que chercher ce qui a permis l'incident produit des corrections. Le compte stage.accueil n'a pas de coupable, il a une procédure de départ de stagiaire qui ne prévoyait pas la fermeture des comptes, et c'est exactement cette phrase qui doit finir dans le compte rendu.

Trois questions structurent l'échange. Qu'est-ce qui a bien marché : la détection humaine à 8 h 05, la sauvegarde de la nuit, la procédure d'isolement. Qu'est-ce qui a fait défaut : l'absence d'alerte sur les renommages, le compte dormant, le délai de conservation des journaux. Qu'aurions-nous voulu savoir une heure plus tôt, et comment faire pour que la prochaine fois cette information soit disponible ? Mesurez ensuite avec les indicateurs que la chronologie vous a permis d'établir : temps entre le premier signal et la détection, temps entre la détection et le confinement, temps entre la décision de restauration et le service rétabli, taux d'alertes pertinentes sur le mois. Des chiffres, pas des impressions, sinon l'an prochain vous ne saurez pas si vous avez progressé.

```text
PLAN D'ACTION POST-INCIDENT — INC-2026-014 — arrêté le 13/10/2026
==================================================================
ACTION                                    RESP.      ÉCHÉANCE   INDICATEUR
----------------------------------------  ---------  ---------  --------------------
Alerte renommage massif sur partagé        Réf. SI    20/10     1 test, 1 alerte reçue
Procédure de fermeture des comptes         RH + SI    31/10     0 compte dormant > 30 j
Inventaire trimestriel des comptes         Réf. SI    30/11     Inventaire signé
Test de restauration documenté            Réf. SI    15/11     Restauration de 100 fichiers
Durée des journaux portée à 90 jours       Réf. SI    30/11     Vérification mensuelle
Exercice de crise sur scénario chiffré     Direction  T1 2027   Compte rendu + actions
```

Les corrections doivent ensuite être répercutées là où elles prennent effet, ce qui va au-delà du fichier de compte rendu. Votre plan d'incident est mis à jour : contacts, rôles, procédure d'isolement enrichie de ce que vous avez appris. Vos alertes sont revues : la règle de renommage massif qui a manqué est écrite et testée. Vos procédures métiers changent : la fiche de départ de stagiaire comporte désormais une case désactivation des comptes. Votre budget, s'il y a lieu, est argumenté par des faits datés plutôt que par des craintes. Et vous fixez la date du prochain exercice, idéalement sur ce même scénario, pour vérifier que les six mois qui vont passer n'ont pas effacé les acquis. Une leçon non traduite en action datée reste une anecdote.

- Faites la rétrospective à froid, dans les jours qui suivent la remise en service.
- Cherchez ce qui a permis l'incident, jamais qui est fautif.
- Mesurez temps de détection, de confinement et de restauration, en chiffres.
- Répercutez les leçons dans le plan, les alertes, les procédures métiers et le budget.
- Reprogrammez un exercice sur le scénario vécu pour ancrer les acquis.
$lesson$),
  ('cyb-c6-p12', 'cyb-c6', 12, $lesson$Mini-projet guidé : le rapport d'incident de la médiathèque$lesson$, $lesson$
Il est temps d'assembler toutes les pièces du chapitre dans un document unique : le rapport d'incident de la Médiathèque des Lilas, au fil rouge depuis le début de la leçon. Ce projet mobilise chacune des notions abordées : fiche de qualification, chronologie horodatée, registre d'actions, décisions de confinement tracées, communication de direction en six lignes, contrôle de la restauration, rétrospective et plan d'action. Travaillez sur un fichier texte ou un traitement de texte, nommez-le avec l'identifiant de l'incident, et tenez-vous à la règle qui a gouverné tout le chapitre : chaque affirmation s'appuie sur une source datée, chaque lacune est écrite comme telle, chaque recommandation porte un responsable et une échéance. Vous récrirez ensuite ce rapport seul, dans l'exercice pratique qui suit la leçon, en partant des seuls indices fournis.

Commencez par les éléments que vous avez déjà : la chronologie consolidée, la fiche de qualification, la checklist de remise en service. Recopiez-les, complétez les colonnes manquantes, vérifiez que les heures se suivent sans contradiction. Rédigez ensuite la communication que vous auriez adressée à la direction à 9 h 30, en respectant les six lignes du modèle : constat, périmètre, causes, actions, restauration, prochain point. Passez au périmètre chiffré, en distinguant toujours ce qui est confirmé de ce qui est pressenti : un poste confirmé, un dossier partagé en cours d'étude, un compte suspendu, une sauvegarde vérifiée. Terminez par les recommandations : elles sont l'unique partie que tout le monde lira attentivement, et elles doivent pouvoir être appliquées par quelqu'un qui n'était pas là ce matin-là.

```text
EXTRAIT — RAPPORT INC-2026-014, partie 1 : résumé exécutif
===========================================================
Le 6 octobre 2026 à 8 h 05, une documentaliste signale que les fichiers
de son poste d'accueil ne s'ouvrent plus. L'enquête établit des
renommages massifs sur le dossier partagé Services à partir de 6 h 58,
puis une ouverture de session du compte stage.accueil à 7 h 11 et deux
tentatives d'accès refusées sur le lecteur de sauvegarde à 7 h 26.

Périmètre confirmé : un poste, un compte suspendu, un dossier partagé.
Service public maintenu en mode dégradé. Sauvegarde de la nuit
vérifiée et exploitable, point de restauration retenu avant 6 h 58.

Le poste est isolé à 8 h 19, soit 14 minutes après le signalement et
71 minutes après le premier signal technique. La restauration est
planifiée le lendemain après test de l'échantillon. La cause
contributive principale est un compte de stagiaire jamais fermé.

Recommandations prioritaires : alerte sur renommage massif (20/10),
procédure de fermeture des comptes (31/10), test de restauration
documenté (15/11), exercice de crise sur scénario chiffré (T1 2027).
```

Une liste de contrôle pour conclure le projet. Le rapport contient-il les huit parties prévues, dans l'ordre ? La chronologie comporte-t-elle heure, fait, source et confiance pour chaque ligne, avec les trous assumés ? Les temps de détection, de confinement et de restauration sont-ils chiffrés ? Les actions du registre portent-elles une heure et un auteur ? La communication interne tient-elle en six lignes et annonce-t-elle le prochain point ? Les recommandations ont-elles chacune un responsable, une échéance et un indicateur ? Enfin, relisez le document en cherchant une seule chose : chaque affirmation sans source. Remplacez-la, précisez-la ou supprimez-la. Un rapport qui passe ce test se lit par un tiers sans avoir besoin de vous, et c'est exactement le but.

- Distinguez systématiquement le confirmé du pressenti, le fait de l'hypothèse.
- Rédigez la communication de direction en six lignes, avec l'heure du prochain point.
- Chiffrez le périmètre et les trois temps de réponse.
- Donnez à chaque recommandation un responsable, une échéance et un indicateur.
- Relisez en chassant toute affirmation sans source.
$lesson$),
  ('cyb-c6-p13', 'cyb-c6', 13, $lesson$À retenir$lesson$, $lesson$
- Un événement est une observation ; un incident menace confidentialité, intégrité ou disponibilité.
- Qualifier, c'est répondre à quatre questions : impact, périmètre, preuves, urgence, puis classer en mineur, majeur ou critique.
- Quatre familles de signaux se croisent : journaux, fichiers, réseau, comptes.
- Une alerte utile dit le fait, la gravité, le périmètre, l'action immédiate et renvoie à une procédure.
- Un seuil couple une quantité et une fenêtre de temps, et sa justification est écrite à côté de la règle.
- Le taux d'alertes pertinentes est l'indicateur de santé de la surveillance.
- Le SIEM donne la vue transverse, l'EDR la vue poste, le HIDS la comparaison à une référence.
- La réponse suit six phases : préparation, détection, confinement, éradication, récupération, leçons.
- La chronologie aligne heure, fait, source et confiance, avec les trous et les écarts d'horloge assumés.
- La chaîne de preuve, c'est copie, empreinte, fiche de manipulation et dossier unique.
- Confiner, c'est arrêter l'aggravation tout en préservant l'état : rien n'est effacé ni redémarré.
- La récupération choisit son point de restauration avant le premier signal et valide à trois niveaux.
- Une sauvegarde n'existe que si elle a été restaurée au moins une fois avec succès.
- Un seul porte-parole, l'heure du prochain point, et aucun détail d'exploitation pendant l'enquête.
- Le rapport suit huit parties, chiffre tout et attribue chaque recommandation.
$lesson$),
  ('cyb-c6-p14', 'cyb-c6', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : traiter chaque signal comme un incident et épuiser l'équipe → Correction : qualifiez avec les quatre questions et retenez un niveau de gravité écrit.
- Piège : attendre d'être certain avant d'ouvrir une fiche → Correction : déclarez l'incident soupçonné, classez ensuite, motivé par écrit.
- Piège : laisser les journaux locaux purgés après quelques jours → Correction : centralisez la collecte et fixez une durée de conservation d'au moins une semaine.
- Piège : ne pas synchroniser les horloges des équipements → Correction : source de temps unique, fuseau mentionné, écarts consignés.
- Piège : configurer des alertes sans action associée → Correction : écrivez l'action immédiate et le lien vers la procédure, sinon c'est une notification.
- Piège : acheter une plateforme avant d'avoir les journaux et les sauvegardes → Correction : journaliser, fermer les accès, sauvegarder et tester, puis alerter, puis acheter.
- Piège : débrancher, redémarrer ou nettoyer avant la collecte → Correction : isoler du réseau, relever l'état, copier les journaux, puis seulement agir.
- Piège : restaurer la sauvegarde la plus récente sans vérifier sa propreté → Correction : point de restauration avant le premier signal, sauvegarde contrôlée, échantillon testé.
- Piège : annoncer un délai de résolution avant de le connaître → Correction : donnez l'heure du prochain point et dites ce qui est confirmé.
- Piège : terminer l'incident une fois le service rétabli → Correction : rétrospective, plan daté, alertes corrigées et exercice programmé.
$lesson$),
  ('cyb-c6-p15', 'cyb-c6', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
La première référence à fréquenter est celle des centres de réponse. Le site du CISA, à l'adresse https://www.cisa.gov/, publie des guides de détection et de réponse écrits pour des équipes opérationnelles : on y trouve des fiches consacrées à la qualification d'incident, à la conservation des preuves et aux procédures de récupération après chiffrement de données, le tout rédigé à l'usage de personnels qui doivent agir vite. Côté européen, l'Agence européenne pour la sécurité des réseaux et de l'information, sur le site https://www.enisa.europa.eu/, produit des recommandations et des rapports sur la détection, la notification et la gestion de crise, utiles pour cadrer une démarche institutionnelle. Prenez le temps de feuilleter ces ressources plutôt que de les lire d'un bout à l'autre : revenez-y le jour où une question précise se pose, par exemple le matin où vous devrez décider en dix minutes si votre signal vaut incident.

Deuxièmement, ancrez la pratique dans des référentiels reconnus, que vous citerez dans votre plan. Les modèles de gestion de crise internationaux décrivent les six phases que vous avez appliquées, et les guides nationaux ajoutent des attentes explicites en matière de notification et de traçabilité des décisions ; deux heures passées à comparer un de ces documents à votre plan actuel valent mieux qu'une journée d'achat d'outil. Troisièmement, la communauté OWASP, consultable sur https://owasp.org/, reste une mine pour tout ce qui touche aux applications et aux points d'entrée web que vos services exposent, avec des listes de contrôle directement exploitables par une petite équipe. Enfin, pratiquez : reprenez le scénario de la médiathèque une fois par an, changez une variable, supprimez un signal, mesurez le temps que met votre équipe à qualifier et à confiner. C'est ce rythme d'entraînement, bien plus que le choix d'une marque, qui fait la différence le jour où le constat arrive.
$lesson$),
  ('cyb-c6-p16', 'cyb-c6', 16, $lesson$Et maintenant : passez à l'exercice pratique$lesson$, $lesson$
Vous disposez maintenant de la méthode complète : voir, qualifier, confiner, éradiquer, restaurer, communiquer et tirer les leçons. L'étape suivante est l'exercice pratique qui accompagne ce chapitre : on vous remet les cinq indices de l'incident de la médiathèque — horodatages, extraits de journaux, fichier détecté, compte suspecté et sauvegarde disponible — et vous construisez seul la chronologie, choisissez les trois actions de confinement en justifiant leur ordre, rédigez la communication interne en six lignes et remplissez la structure du rapport. Travaillez sans rouvrir la leçon : c'est dans cet écart entre ce que vous croyez savoir et ce que vous écrivez que la compétence se révèle, puis corrigez avec les modèles fournis.

Le quiz de quatre questions qui accompagne le chapitre vous permet de vérifier en quelques minutes les notions essentielles : la distinction événement et incident, la structure d'une alerte utile, l'ordre des phases de réponse et le rôle respectif des outils de surveillance. Passé cet exercice, poursuivez le parcours Cybersécurité : les chapitres suivants élargiront le champ à d'autres facets de la sécurité des systèmes d'information, et vous mesurerez alors à quel point la discipline acquise ici — source datée, décision tracée, leçon traduite en action — vous servira dans tous les sujets. Gardez le rapport de la médiathèque dans vos dossiers : c'est un modèle que vous pourrez réutiliser tel quel, en changeant les noms, le jour où votre propre matin de lundi ressemblera à celui-ci.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('cyb-c7-p1', 'cyb-c7', 1, $lesson$Pourquoi les politiques existent$lesson$, $lesson$
Bienvenue dans le septième et dernier chapitre du parcours Cybersécurité, un chapitre qui change de registre : il ne s'agit plus d'analyser une attaque, mais d'organiser ce qui doit tenir avant, pendant et après. Le chapitre précédent s'est achevé sur l'incident de la Médiathèque des Lilas : des postes chiffrés par un rançongiciel, un service d'emprunt indisponible plusieurs jours, des sauvegardes dont personne ne savait dire avec certitude si elles étaient complètes, et une équipe qui a improvisé sous pression. Tout a fini par tourner, mais au prix de nuits blanches, de décisions prises au fil de l'eau et d'un doute qui a traîné pendant des semaines sur la date réelle de la dernière copie fiable. Ce chapitre part de ce constat : le problème n'était pas seulement technique, il était organisationnel. On ne répare une discontinuité en achetant pas un disque de plus, on la répare en écrivant ce qui doit être fait, par qui, à quelle fréquence et avec quelles preuves.

À la fin de cette leçon, vous saurez faire trois groupes de choses très concrètes, que vous aurez déjà assemblées dans un dossier complet. Vous saurez écrire une politique de sécurité réellement exploitable : structurer le document, définir sa portée, nommer les rôles, formuler des règles compréhensibles par une personne non technique, prévoir les conséquences d'un manquement et organiser la révision périodique. Vous saurez concevoir et organiser une sauvegarde selon la règle 3-2-1 : inventorier ce qui mérite d'être copié, répartir les copies sur plusieurs supports et plusieurs sites, rendre certaines copies immuables, chiffrer le contenu, protéger les clés, puis écrire et exécuter une procédure de restauration qui prouve que les copies servent à quelque chose. Vous saurez enfin préparer un plan de reprise d'activité : distinguer continuité et reprise, fixer des objectifs mesurables de délai et de perte de données, nommer les déclencheurs et les rôles, dérouler les étapes dans l'ordre et installer un tableau de bord alimenté par des exercices réguliers.

La manière d'aborder ce chapitre mérite une recommandation, comme au début du premier. La conformité et la continuité s'apprennent comme tout le reste du parcours : en rédigeant soi-même les documents, pas en les regardant quelqu'un d'autre rédiger. Rien ne remplace le geste d'ouvrir un traitement de texte, de coller le modèle de politique proposé dans un instant, de remplacer chaque crochet par une réalité de votre organisation, puis de relire la page en vous demandant si un nouvel arrivant comprendrait quoi faire lundi matin. Une phrase vague n'est pas un détail de style, c'est une faille de gouvernance : elle laissera le champ libre à l'improvisation exactement au moment où l'improvisation sera le plus coûteuse. Nous avancerons par étapes, en alternant explications détaillées, modèles commentés, schémas de topologie et procédures numérotées. Le fil rouge reste la Médiathèque des Lilas : après l'incident du chapitre précédent, elle doit structurer durablement sa politique, ses sauvegardes et son plan de reprise, et c'est ce dossier que vous constituerez dans le mini-projet guidé de fin de chapitre.



Une organisation qui n'a pas de règle écrite n'est pas sans règle, elle a des règles implicites, c'est-à-dire des habitudes, des savoir-faire personnels et des compromis tacites qui vivent dans la mémoire de quelques salariés. Tant que rien ne se passe, cette situation semble d'une simplicité admirable : on fait comme on a toujours fait, on sait qui appeler, on connaît les raccourcis. Le problème apparaît quand l'un de ces personnes part, change de service, tombe malade ou se trouve face à un événement qu'il n'a jamais vécu. Ce qui semblait évident pour tout le monde n'était évident que pour trois personnes, et l'organisation découvre, souvent au pire moment, que sa continuité reposait sur une mémoire orale. La politique de sécurité existe précisément pour sortir de cette dépendance : elle transforme l'implicite en explicite, l'habitude en règle, la compétence individuelle en patrimoine collectif.

Le cadre juridique donne à cette exigence une force particulière, sans pour autant dicter le contenu technique de vos choix. Pour une organisation qui traite des données personnelles, comme une médiathèque qui gère des adhérents, des emprunts et parfois des mineurs, plusieurs principes se dégagent et structurent la réflexion. La responsabilité suppose que l'organisation puisse rendre compte de ses pratiques : ce n'est pas seulement l'obligation de faire les choses, c'est l'obligation de pouvoir démontrer qu'on les a faites. La minimisation impose de ne collecter que ce qui est réellement nécessaire au service rendu, ce qui concerne aussi bien les sauvegardes que les journaux d'application. La sécurité des traitements implique de mesures techniques et organisationnelles adaptées au niveau de risque, et la traçabilité impose de conserver la trace des décisions importantes. En France, l'autorité de contrôle chargée de ces questions publie des guides pratiques remarquablement lisibles sur son site, https://www.cnil.fr ; ces documents valent souvent mieux qu'un résumé de seconde main, et ils évitent de bâtir une politique sur des rumeurs de réglementation.

La politique est aussi une preuve. Dans la pratique, on ne demande jamais à une organisation si elle est sérieuse, on lui demande de le démontrer : par un document daté, versionné, approuvé, diffusé ; par des journaux de sauvegarde ; par des comptes rendus d'exercice ; par des comptes rendus de formation. Ce décalage entre l'intention et la preuve est au cœur de la maturité d'une organisation : deux structures aux outils identiques ne réagissent pas de même devant une crise, parce que l'une sait ce qu'elle a décidé et peut le montrer en cinq minutes. La politique n'est donc pas un document décoratif destiné à un audit : c'est l'outil de travail de la direction, le référentiel qui permet de dire à un prestataire, à un nouveau membre ou à un élu local ce qui est attendu, sans improviser une explication différente à chaque fois.

Il faut distinguer nettement la politique, la procédure et le réglage technique. La politique dit ce qui doit être vrai : les sauvegardes sont chiffrées, les mots de passe sont distincts, les accès administrateur sont justifiés. La procédure dit comment on y arrive, étape par étape, avec des noms, des fréquences et des critères de réussite. Le réglage technique incarne le tout dans un outil : rétention d'un mois sur le serveur, verrouillage après cinq minutes, copie quotidienne à deux heures du matin. Confondre ces trois niveaux produit deux échecs classiques. Le premier est la politique-chapeau, composée de principes si généraux qu'elle n'interdit rien et n'oblige personne : on y lit que la sécurité est importante, ce que tout le monde savait déjà. Le second est la politique-manuel, qui noie le lecteur dans des détails d'interface et devient obsolète dès qu'un logiciel change de version. Gardez une règle de proportion : la politique tient en quelques pages, les procédures tiennent chacune sur une à deux pages, et les réglages vivent dans la documentation technique.

- Une organisation sans règle écrite dépend de la mémoire de quelques personnes.
- La responsabilité impose de pouvoir démontrer ses pratiques, pas seulement de les pratiquer.
- Une politique se prouve par des documents datés et par des journaux, pas par des intentions.
- Distinguez la politique, ce qui doit être vrai, de la procédure et du réglage technique.
- La politique reste courte, la procédure reste actionnable, le réglage vit dans l'outil.
- Une règle vague ne protège personne : elle laisse décider celui qui sera le plus pressé.
- Diffuser et relire le document fait partie intégrante du travail de rédaction.
$lesson$),
  ('cyb-c7-p2', 'cyb-c7', 2, $lesson$Une politique qui se lit : structure, destinataires, révision$lesson$, $lesson$
Un document qui ne se lit pas n'existe pas. C'est la première exigence de rédaction, et elle en élimine beaucoup d'autres. La longueur moyenne d'une politique rédigée en un seul bloc, sans sommaire, sans titres et sans phrases courtes, dépasse largement ce qu'un lecteur est prêt à absorber : le directeur en scanne la première page, le prestataire cherche la clause qui le concerne, le nouvel arrivant cherche ce qui lui est demandé dès demain. Si ces trois personnes doivent remonter vingt pages pour trouver leur réponse, elles renonceront. La structure n'est donc pas un souci de typographie, c'est la condition d'usage du document.

Commencez par une page de tête qui donne le contexte en quelques lignes, puis un sommaire cliquable si le document est numérique. Chaque grande partie porte un titre explicite, et chaque paragraphe ne développe qu'une seule idée. Les listes à puces sont vos alliées pour les règles concrètes : une règle par ligne, formulée à l'impératif ou au présent, sans subordonnée qui court sur trois lignes. Évitez le vocabulaire technique non défini ; si vous employez un terme précis, donnez-lui sa définition dans un court glossaire placé en fin de document ou en annexe. Préférez des exemples aux abstractions : plutôt que dire que les mots de passe doivent être robustes, donnez la règle de longueur minimale, l'interdiction de réutilisation et le recours à un gestionnaire de mots de passe. Le lecteur doit pouvoir passer de la lecture à l'action sans traduction.

```text
POLITIQUE DE SÉCURITÉ — MÉDIATHÈQUE DES LILAS
Version 1.0 — Approuvée le 12 janvier 2026 — Prochaine révision : janvier 2027
Propriétaire du document : la direction

1. OBJET
   La présente politique définit les règles applicables à la protection des
   systèmes, des données et des accès de la médiathèque.

2. PORTÉE
   Elle s'applique à l'ensemble du personnel permanent et temporaire, aux
   bénévoles, aux prestataires intervenant sur les systèmes et aux
   espaces numériques ouverts au public.

3. DÉFINITIONS
   Donnée personnelle, compte nominatif, sauvegarde, accès privilégié,
   incident de sécurité.

4. RÔLES ET RESPONSABILITÉS
   Direction, référent sécurité, administrateur système, personnel
   d'accueil, prestataires.

5. RÈGLES
   5.1 Comptes et authentification
   5.2 Appareils et postes de travail
   5.3 Sauvegardes et restauration
   5.4 Messagerie et pièces jointes
   5.5 Télétravail et réseaux externes
   5.6 Prestataires et accès à distance

6. SIGNALEMENT D'UN INCIDENT
   À qui écrire, à quel délai, avec quelles informations.

7. NON-CONFORMITÉ
   Mesures graduées, procédure d'avertissement.

8. SANCTIONS
   Conséquences prévues par le règlement intérieur et le droit du travail.

9. ENTRÉE EN VIGUEUR ET RÉVISION
   Date, périodicité annuelle, révision après incident majeur.
```

Le deuxième destinataire à avoir en tête est la diversité des lecteurs. Une même page s'adresse simultanément à la direction, qui veut des garanties et des indicateurs, au personnel non technique, qui veut savoir quoi faire concrètement, et aux prestataires, qui doivent connaître leurs obligations contractuelles. Il est inutile d'écrire trois documents différents : une structure claire avec des titres explicites permet à chacun de sauter directement à sa partie. Ce qui est indispensable, en revanche, c'est d'écrire pour le lecteur le moins technique, parce que la personne qui devra appliquer la règle à trois heures du matin sera rarement celle qui a rédigé le document. Testez la lisibilité en demandant à une personne qui n'a pas participé à la rédaction de trouver, en une minute, la marche à suivre en cas de courriel suspect.

La question des destinataires impose aussi de traiter les cas particuliers. Les bénévoles, par exemple, n'ont pas le statut de salarié mais accèdent aux mêmes systèmes ; les prestataires de maintenance, eux, disposent d'accès temporaires et souvent distants ; les adhérents, enfin, sont des personnes concernées par les données plutôt que des appliquants de la règle, mais ils ont leur part d'obligations, comme la protection de leur compte de réservation. Une politique qui oublie l'une de ces catégories crée un angle mort : on applique scrupuleusement la règle aux salariés pendant qu'un intervenant externe conserve un accès oublié. Listez explicitement les populations couvertes, et ajoutez une clause précisant que tout accès est nominatif, justifié, limité dans le temps et révoqué en fin de mission.

La révision est la pièce que l'on oublie le plus souvent, et pourtant elle décide de la longévité du document. Trois éléments doivent y figurer : une date d'approbation, une date de prochaine révision planifiée et un propriétaire identifié, c'est-à-dire une personne ou un fonction responsable de tenir le document à jour. Sans propriétaire, la politique devient orpheline et personne ne la relira. Sans date, elle devient ancienne sans que personne le sache. La périodicité annuelle est un minimum raisonnable, à compléter par une révision extraordinaire après un incident majeur, un changement d'outil important ou une évolution réglementaire significative. Versionnez simplement : numéro incrémenté, date, auteur du changement, résumé d'une ligne de ce qui a bougé. Ce journal court rassure le lecteur qui se demande s'il tient le bon document.

Enfin, prévoyez l'approbation et la diffusion. Une politique non approuvée reste un projet ; un paraphe de direction, une date et une diffusion datée en font une règle. Conservez la preuve : un courriel de diffusion, une réunion dont le compte rendu mentionne la présentation, une attestation de lecture pour les populations sensibles. Ces éléments prennent dix minutes à rassembler et valent beaucoup le jour où l'on vous demandera ce qui était en vigueur à une date donnée.

- Ouvrez par une page de contexte, un sommaire et des titres explicites.
- Une idée par paragraphe, une règle par puce, un impératif clair.
- Définissez vos termes : un lexique court évite les malentendus durables.
- Listez les populations couvertes, bénévoles et prestataires compris.
- Nommez un propriétaire du document et une date de prochaine révision.
- Versionnez à chaque changement avec un résumé d'une ligne.
- Faites approuver, datiez et diffusez : un projet ne protège personne.
$lesson$),
  ('cyb-c7-p3', 'cyb-c7', 3, $lesson$Les éléments d'une politique de sécurité$lesson$, $lesson$
La portée est la première partie à écrire, parce qu'elle décide de tout le reste. Elle répond à quatre questions : quoi, qui, où et quand. Quoi : quels systèmes, quels espaces, quelles données sont couverts — postes, serveur, réseau, application de réservation, archives, coffre-fort des identifiants. Qui : quelles personnes, y compris les externes. Où : les locaux professionnels, le télétravail, les espaces publics, les appareils mobiles. Quand : de manière permanente, ou seulement pour certaines situations comme le travail à distance. Une portée trop étroite laisse des zones hors règle, une portée trop large devient invraisemblable et perd toute crédibilité. Dites ce que vous couvrez et, tout aussi important, ce que vous ne couvrez pas encore, avec l'échéance prévue : la franchise honnête est mieux reçue que le silence.

Vient ensuite l'attribution des rôles. Une politique sans nommage écrit laisse croire que la sécurité est l'affaire de tout le monde, ce qui revient dans les faits à dire qu'elle est l'affaire de personne. Trois rôles suffisent pour une structure de taille moyenne. La direction porte la décision et les moyens : elle approuve, arbitre les priorités et rend compte. Le référent sécurité coordonne : il tient l'inventaire des actifs, suit les sauvegardes, anime les exercices, centralise les signalements et fait le lien avec l'externe. L'administrateur, qu'il soit interne ou prestataire, exécute : comptes, mises à jour, sauvegardes, journaux. À ces rôles s'ajoutent des obligations pour chacun : la direction valide la politique une fois par an, le référent produit un tableau de bord, l'administrateur fournit les preuves. Écrivez aussi le mandat de remplaçant : qui couvre le rôle pendant les congés, qui est appelé en cas d'incident de nuit.

```table
Rubrique | Question à laquelle elle répond | Exemple de formulation
--- | --- | ---
Portée | Quoi, qui, où, quand ? | La politique couvre les postes, le serveur, l'application de réservation et les sauvegardes.
Rôles | Qui décide, qui coordonne, qui exécute ? | La direction approuve, le référent coordonne, l'administrateur exécute.
Règles | Que doit-on faire concrètement ? | Chaque compte est nominatif, protégé par un mot de passe distinct et un second facteur.
Preuves | Qu'est-ce qui prouve l'application ? | Journal des sauvegardes, registre des comptes, comptes rendus d'exercice.
Sanctions | Que se passe-t-il en cas de manquement ? | Avertissement, retrait d'accès, mesures disciplinaires du règlement intérieur.
Révision | Quand le document est-il relu ? | Une fois par an, après un incident majeur ou un changement d'outil majeur.
```

Les règles constituent le cœur du document et méritent le plus de soin. Elles doivent être suffisamment précises pour être vérifiables, et suffisamment peu nombreuses pour être mémorisables. Cinq à dix règles fortes valent mieux que cinquante prescriptions diluées. On y range en général : l'authentification, avec l'interdiction des comptes partagés, la longueur minimale des mots de passe, le second facteur pour les comptes sensibles et l'interdiction de réutiliser un mot de passe personnel ; la gestion des accès, avec la création sur demande motivée, la revue périodique et la suppression immédiate au départ ; les appareils, avec verrouillage automatique, chiffrement du disque et mise à jour ; la messagerie, avec méfiance envers les pièces jointes inattendues et vérification de l'adresse réelle de l'expéditeur ; les sauvegardes, avec fréquence, rétention, chiffrement et test trimestriel ; le signalement, avec un canal identifié et un délai court. Chaque règle se formule ainsi : énoncé, raison en une phrase, preuve attendue.

La partie sur les sanctions et la non-conformité demande de la nuance. Une politique qui ne parle que de répression pousse au sous-signalement : quand déclencher un incident en sachant qu'on sera sanctionné pour avoir cliqué ? La bonne approche distingue la faute et la négligence répétée de l'erreur isolée signalée spontanément. Prévoyez une graduation cohérente : rappel de la règle et formation dans le cas d'une première erreur signalée, avertissement formel en cas de manquement avéré, retrait des accès en cas de comportement grave, et renvoi aux procédures disciplinaires du règlement intérieur pour les cas les plus sérieux. Mentionnez le principe de bienveillance envers le signalement : personne ne doit craindre de déclarer un clic hasardeux, car le silence coûte infiniment plus cher que l'erreur. Enfin, précisez que les sanctions s'inscrivent dans le cadre du droit du travail et du règlement intérieur, sans prétendre à des mécanismes propres à la politique.

La preuve mérite une rubrique à part entière, souvent absente des modèles trouvés en ligne. À chaque règle, associez l'artefact qui démontre son application : le registre des comptes pour la gestion des accès, le journal de sauvegarde pour la règle 3-2-1, la liste des mises à jour pour la gestion des postes, le compte rendu de l'exercice pour la préparation à la crise. C'est cette colonne qui transforme un texte en dispositif pilotable, et c'est elle que l'on demandera à produire le jour d'un contrôle. Tenez un petit dossier unique, daté, qui contient ces preuves : il vous évitera de reconstituer l'historique dans l'urgence.

- Ouvrez par une portée explicite, y compris ce qui n'est pas encore couvert.
- Nommez trois rôles : direction qui décide, référent qui coordonne, exécutant qui applique.
- Écrivez cinq à dix règles vérifiables plutôt qu'une liste indigeste.
- Associez à chaque règle une raison courte et une preuve attendue.
- Séparez l'erreur signalée du manquement répété avant de parler de sanctions.
- Prévoyez un canal de signalement où personne ne craint d'intervenir.
- Rassemblez les preuves dans un dossier daté, tenu à jour.
$lesson$),
  ('cyb-c7-p4', 'cyb-c7', 4, $lesson$La règle 3-2-1 expliquée$lesson$, $lesson$
La règle 3-2-1 est la formulation la plus connue de la discipline des sauvegardes, et sa popularité se mérite : elle tient en un chiffre par élément et se vérifie en une minute. Trois copies des données existent, dont la production elle-même. Ces copies reposent sur deux supports différents. Et au moins une d'entre elles est conservée hors du site principal. L'idée sous-jacente est simple : aucun incident local ne doit pouvoir détruire simultanément tous les exemplaires d'un même contenu. Incendie, inondation, vol, chiffrement par rançongiciel, erreur d'administration, disque qui lâche : chacun de ces scénarios détruit ou rend inaccessible une partie de l'espace, mais rarement la totalité si les copies sont correctement séparées.

Détaillons chaque chiffre, car il est facile de cocher la règle sans la respecter vraiment. Les trois copies signifient que vous disposez de la donnée en production et de deux copies indépendantes ; une copie sur le même disque, même en double dossier, n'est pas une copie, c'est le même point de défaillance écrit deux fois. Les deux supports signifient que les copies ne partagent pas la même technologie ni le même mode de panne : un disque dur et un stockage en réseau, une bande et un serveur de fichiers, un poste local et un service distant. Si les trois exemplaires vivent sur le même automate, une panne de l'automate les emporte toutes. Le site distant, enfin, doit être physiquement distinct : un autre bâtiment, un autre bâtiment de rattachement, un prestataire situé ailleurs. La proximité offerte par un cloud est un atout, à condition que le compte distant soit cloisonné, protégé par une authentification forte et des identifiants distincts de ceux du site principal.

```text
        SITE PRINCIPAL — Médiathèque des Lilas
  +-----------------------------------------------+
  |  Postes + serveur local                      |
  |    |                                         |
  |    +--> [1] Copie locale quotidienne         |
  |            disque externe du serveur         |
  |            (rétention : 30 jours)            |
  |                                              |
  |    +--> [2] Copie vers NAS séparé            |
  |            chiffrement activé                |
  |            (rétention : 90 jours)            |
  +-----------------------------------------------+
                    |
                    |  transfert chiffré, hors site
                    v
        SITE DISTANT — localité séparée
  +-----------------------------------------------+
  |  [3] Copie sur bande ou service cloud        |
  |       copie IMMUEBLE, rétention 12 mois      |
  |       identifiants dédiés, clé hors ligne     |
  +-----------------------------------------------+

  Vérification : 3 copies / 2 supports / 1 site distant
  + test de restauration documenté chaque trimestre
```

Les variantes de la règle méritent d'être connues sans devenir un prétexte à la complexité. On voit parfois 3-2-1-1-0 : un dernier chiffre pour une copie immuable, protégée contre la suppression même par un compte administrateur compromis, puis un zéro visant l'objectif d'erreur tolérée sur les tests. Une autre extension ajoute une copie hors ligne, déconnectée physiquement du réseau pendant la majeure partie du temps, ce qui la rend insensible à une attaque en réseau. Ces compléments sont excellents pour les organisations matures, mais ils ne remplacent pas la règle de base. Si vous n'avez pas encore trois copies réellement séparées, commencez par là ; la sophistication viendra ensuite, une fois les fondations acquises.

Ce que la règle ne dit pas est tout aussi important. Elle ne dit pas quoi sauvegarder, ni à quelle fréquence, ni combien de temps conserver, ni comment chiffrer, ni surtout comment restaurer. Une organisation qui satisfait littéralement la règle 3-2-1 avec des sauvegardes jamais testées peut être parfaitement conforme sur le papier et totalement démunie le jour où elle doit réellement restaurer. La règle porte sur la redondance physique ; la fiabilité du dispositif vient de trois compléments : l'inventaire de ce qui doit être copié, le chiffrement assorti d'une gestion des clés séparée, et le test de restauration avec un résultat écrit. C'est l'addition de ces quatre couches qui fait la différence entre un schéma décoratif et un dispositif de reprise.

Un mot sur la granularité et la fréquence, parce qu'elle conditionne la perte acceptable de données. Copier une fois par semaine signifie que vous acceptez de perdre jusqu'à une semaine de travail en cas d'incident ; copier toutes les heures réduit ce risque mais augmente le volume à conserver et le temps de restauration. En pratique, on différencie : sauvegarde continue ou horaire pour les données critiques et mutateurs, quotidienne pour l'essentiel, hebdomadaire pour les données stables, et un cycle plus long pour les archives. Définissez la fréquence à partir de la question inverse : combien de travail pouvez-vous vous permettre de perdre et combien de temps pouvez-vous vous permettre d'être à l'arrêt ? Vous verrez dans la section sur le RTO et le RPO que cette question a un nom et une valeur chiffrée.

Enfin, tenez compte du coût d'exploitation : trois copies signifient trois consommations d'espace et trois vérifications. Un inventaire réaliste évite de sauvegarder deux fois des données que personne n'utilise plus. Prévoyez un nettoyage des anciennes versions et une surveillance des jobs : une copie silencieusement en échec depuis six mois ne se voit qu'au moment de la restauration.

- Trois copies, dont la donnée en production, jamais trois dossiers sur le même disque.
- Deux supports réellement différents, aux modes de panne distincts.
- Un site distant, physiquement séparé et protégé par des identifiants dédiés.
- La règle porte sur la redondance : le test et le chiffrement sont vos compléments.
- Chiffrez les copies et gardez la clé ailleurs que les données.
- Variante 3-2-1-1-0 : copie immuable, puis objectif d'erreur nulle sur les tests.
- Calibrez la fréquence à partir de la perte de données que vous acceptez.
$lesson$),
  ('cyb-c7-p5', 'cyb-c7', 5, $lesson$Ce qu'il faut sauvegarder (et ce qu'on oublie : configurations, secrets, identifiants)$lesson$, $lesson$
L'erreur de méthode la plus répandue consiste à partir du stockage pour définir la sauvegarde : on regarde les disques disponibles, on remplit ce qui reste, puis on découvre le jour du sinistre que le service le plus critique n'était pas dans la liste. La bonne démarche inverse l'ordre : on part des services que l'organisation doit maintenir, on remonte jusqu'aux données qui les font vivre, puis on décide de la copie, de la fréquence et de la rétention pour chacune. Pour une médiathèque, la liste est plus courte qu'on ne le croit : la base d'adhérents et d'emprunts, l'application de réservation et son contenu, les documents de gestion et les contrats, les archives de la politique des acquisitions, les contenus numériques produits localement, et la comptabilité. Chaque entrée reçoit une fiche, une fréquence et un responsable, et l'inventaire devient la pièce maîtresse du dossier de continuité.

Ce que l'on oublie presque toujours est plus coûteux que les données elles-mêmes, parce que sa perte empêche même de démarrer la restauration. Premier oubli : les configurations. Paramètres du serveur, réglages du réseau, fichiers de configuration de l'application, certificats, listes de droits, scripts d'installation, procédures de déploiement. Sans eux, vous restaurez des données dans un environnement que vous devez reconstruire à la main, et chaque heure passée à reconstituer la configuration s'ajoute directement à votre temps d'indisponibilité. Deuxième oubli : les secrets. Mots de passe de service, clés d'accès aux services distants, jetons d'API, certificats privés. Ils ne doivent pas traîner dans un fichier texte copié avec le reste ; ils vivent dans un gestionnaire de secrets dont la sauvegarde est elle-même chiffrée, avec une clé protégée séparément. Troisième oubli : les identifiants de l'identifiant, c'est-à-dire ce qui vous permet de vous reconnecter au service de sauvegarde et aux comptes d'administration. Si l'incident vous fait perdre ces éléments, vous vous retrouvez devant des copies auxquelles vous ne pouvez pas accéder.

Un quatrième oubli concerne la connaissance, pas la technique : la documentation opérationnelle, les comptes rendus de réunion utiles, les schémas d'architecture, la liste des prestataires avec leurs contacts, les contrats de licence et leurs clés d'activation. C'est le corpus qui permet à une personne nouvelle de comprendre le système sans le deviner. Un dernier point, inverse : certaines choses ne méritent pas d'être sauvegardées, et les sauvegarder augmente inutilement le volume, le coût et l'empreinte des données personnelles. Les caches, les fichiers temporaires, les anciennes installations remplacées, les doublons de fichiers déjà archivés relèvent de l'élimination, pas de la copie. Limitez aussi la durée de conservation des données qui n'ont plus d'usage : sauvegarder indéfiniment une base d'adhérents cessés, c'est multiplier les copies d'une donnée que la règle de minimisation vous invite justement à effacer.

```table
Objet à sauvegarder | Exemple concret | Fréquence | Rétention | Preuve attendue
--- | --- | --- | --- | ---
Base d'adhérents et d'emprunts | Sauvegarde de la base applicative | Quotidienne, avec incrément horaire | 30 jours | Journal de job et compte rendu mensuel
Application de réservation | Base, pièces jointes, règles métier | Quotidienne | 30 jours | Journal de job
Documents de gestion | Contrats, comptes rendus, budgets | Quotidienne | 90 jours | Journal de job
Configurations et scripts | Serveur, réseau, déploiement | À chaque changement + hebdomadaire | 12 mois | Historique des versions
Secrets et certificats | Gestionnaire de secrets, certificats | À chaque rotation | Selon la durée de validité | Registre des rotations
Connaissance opérationnelle | Schémas, contacts, procédures | À chaque version | Dernière version + archive | Registre des versions
Contenus numériques locaux | Fichiers produits, médias numériques | Hebdomadaire | 6 mois | Journal de job
```

Pour éviter que cet inventaire ne vieillisse, donnez-lui une forme technique simple et tenable. Un fichier unique, versionné dans votre dépôt de documents, suffit : il décrit pour chaque objet sa source, sa destination, sa fréquence, sa rétention, son chiffrement et son responsable. Prenez l'habitude de le relire à chaque changement d'outil ou de service : un nouveau prestataire de paiement, un nouveau lecteur de badges, une migration de messagerie ajoutent toujours une entrée qu'on aurait oubliée.

```yaml
# extrait du manifeste de sauvegarde — médiathèque des lilas
objet: base_emprunts
source: serveur-app-01/postgres:emprunts
destination_primaire: nas-interne/sauvegardes/emprunts
destination_secondaire: bande-hors-site/emprunts
frequence: "0 2 * * *"        # quotidienne à 02 h 00
increment: "0 * * * *"        # incrément horaire
retention_jours: 30
chiffrement: "aes-256, cle hors ligne"
immutable: true
responsable: referent.securite
verification: "restauration partielle chaque mois"
```

Enfin, distinguez la sauvegarde de l'archive. La sauvegarde sert à revenir en arrière après un incident, elle est donc volatile, testée et dimensionnée pour un coût raisonnable. L'archive sert à conserver une trace à long terme, souvent pour des raisons légales ou patrimoniales, elle n'a pas vocation à être restaurée vite mais doit rester intègre et lisible des années plus tard. Mêler les deux produit le pire des deux mondes : des archives qui encombrent les sauvegardes quotidiennes et des sauvegardes réduites à une durée de rétention incompatible avec la restitution d'un dossier ancien. Séparez-les clairement dans l'inventaire, avec des politiques de conservation distinctes.

- Partez des services à maintenir, pas des disques disponibles.
- Sauvegardez les configurations : elles conditionnent la durée de reconstruction.
- Protégez les secrets dans un gestionnaire, avec une clé gardée ailleurs.
- Préservez les identifiants d'accès aux sauvegardes, sinon les copies sont inutiles.
- Documentez la connaissance opérationnelle : schémas, contacts, procédures.
- Éliminez ce qui n'a plus d'usage plutôt que de le copier indéfiniment.
- Tenez l'inventaire dans un manifeste versionné et relu à chaque changement.
$lesson$),
  ('cyb-c7-p6', 'cyb-c7', 6, $lesson$Copies immuables, chiffrement des sauvegardes, hors site$lesson$, $lesson$
L'immuabilité est la réponse directe à la menace la plus courante : la suppression ou la modification des copies par un compte d'administration compromis. Une sauvegarde classique, effaçable par un compte administrateur, ne résiste pas à un attaquant qui a pris le contrôle de ce compte : il suffit de purger le catalogue, de vider le stockage ou de faire tourner une commande d'effacement avec une balayette large. Rendre une copie immuable, c'est interdire sa suppression et sa modification pendant une durée déterminée, y compris pour les comptes d'administration. Ce verrou se concrétise différemment selon l'outil : verrouillage de rétention sur un stockage objet, mode d'écriture une fois non modifiable sur un système de fichiers, journalisation protégée, ou support physique dont on retire la possibilité d'effacement. Choisissez la durée en fonction du risque : elle doit au minimum couvrir la période pendant laquelle un attaquant pourrait rester indétecté, ce qui se compte généralement en mois plutôt qu'en jours.

L'immuabilité a un coût qu'il faut assumer volontairement : vous ne pourrez plus libérer l'espace à votre guise, et une mauvaise sauvegarde restera visible jusqu'à l'expiration du verrou. C'est précisément le prix de la garantie. Prévoyez donc la capacité en conséquence, surveillez la consommation, et dimensionnez les verrous pour qu'ils couvrent une durée de rétention utile tout en évitant d'engorger le stockage. Une organisation qui n'a pas les moyens de financer l'immuabilité complète peut la réserver aux sauvegardes les plus critiques, celles sans lesquelles rien ne repart, et conserver le reste en rétention classique. Le progrès se mesure alors au nombre d'objets protégés, pas à la perfection du schéma.

Le chiffrement intervient sur deux plans et doit être traité séparément sur chacun. Le chiffrement au repos protège les données quand elles reposent sur un disque, une bande ou un stockage distant : sans lui, la perte physique d'un support ou l'accès non autorisé à un stockage suffit à exposer tout l'historique. Le chiffrement en transit protège le transfert entre le site de production et la destination : une copie envoyée en clair sur un réseau partagé est une fuite en puissance. Les deux se combinent, et aucun ne remplace l'autre. Attention à un point souvent négligé : chiffrer la sauvegarde ne sert à rien si la clé vit dans le même fichier que les données. La clé doit être conservée séparément, idéalement hors ligne ou dans un coffre de secrets distinct, avec un accès plus restreint que celui des données elles-mêmes.

La gestion des clés mérite à elle seule quelques lignes, parce qu'elle comporte deux écueils symétriques. Le premier : la clé introuvable, qui transforme des mois de sauvegardes en données illisibles. Le second : la clé trop accessible, qui annule tout le bénéfice du chiffrement. Tenez un registre minimal qui indique où vit chaque clé, qui y a accès, comment elle est récupérée en cas d'absence, et depuis quand elle n'a pas été testée. Faites vérifier la récupération au moins une fois par an sur un support réel : une clé qu'on n'a jamais utilisée depuis sa création est une clé dont on ignore si elle fonctionne. Prévoyez également la rotation, c'est-à-dire le changement périodique de clé, en conservant la possibilité de lire les anciennes copies, sans quoi la rotation détruirait votre propre historique.

Le site distant est la troisième jambe, et il doit l'être vraiment. Un second emplacement physique répond à des risques locaux que la technique ne peut pas compenser : incendie, dégât des eaux, vol, coupure longue d'alimentation, coupure réseau. Le prérequis est un cloisonnement rigoureux. Les identifiants du compte de stockage distant doivent être distincts de ceux du site principal, protégés par un second facteur, et ne jamais être synchronisés depuis l'annuaire d'identité interne : un attaquant qui compromise l'annuaire hériterait sinon de l'accès aux copies. Limitez les droits de ce compte à l'écriture et à la lecture des seuls contenus de sauvegarde, désactivez la suppression non conforme au verrou de rétention, et interdisez l'accès depuis les réseaux inattendus. Un compte de sauvegarde distant doté de tous les droits d'administration est la porte dérobée préférée des attaquants.

```bash
#!/usr/bin/env bash
# verification-sauvegarde.sh — contrôle hebdomadaire illustratif
# Affiche l'état des dernières copies et signale un retard anormal.
SEUIL_HEURES=26
DOSSIER="/mnt/nas/sauvegardes/emprunts"

derniere=$(ls -1t "$DOSSIER"/*.tar.gz 2>/dev/null | head -n 1)
if [ -z "$derniere" ]; then
  echo "ALERTE : aucune sauvegarde trouvée dans $DOSSIER"
  exit 2
fi

age=$(( ($(date +%s) - $(stat -c %Y "$derniere")) / 3600 ))
echo "Dernière copie : $derniere"
echo "Âge : $age heure(s)"

if [ "$age" -gt "$SEUIL_HEURES" ]; then
  echo "ALERTE : copie trop ancienne, le job a peut-être échoué"
  exit 1
fi

echo "Empreinte de la copie :"
sha256sum "$derniere"
echo "Contrôle OK — pensez au test de restauration du trimestre"
```

La vérification automatique illustre une distinction importante : surveiller la réussite d'un job ne garantit pas la restaurabilité du contenu. Un job peut aboutir avec un fichier vide, tronqué, chiffré avec une clé désormais perdue ou corrompu en cours d'écriture. Le script ci-dessus ne vérifie donc que l'existence, la fraîcheur et l'intégrité d'un objet ; la restauration reste un test à part entière, doté de sa propre procédure. Ne confondez pas la télémétrie, qui vous dit que quelque chose a été écrit, et la preuve fonctionnelle, qui vous dit que quelque chose peut être relu par un humain qui en a besoin.

- L'immuabilité interdit suppression et modification pendant une durée choisie.
- Dimensionnez le verrou de rétention au risque, pas à la commodité du stockage.
- Chiffrez au repos et en transit, et gardez la clé ailleurs que les données.
- Tenez un registre des clés et testez la récupération au moins une fois par an.
- Cloisonnez le compte distant : identifiants dédiés, second facteur, droits minimaux.
- Jamais de synchronisation des identifiants de sauvegarde depuis l'annuaire interne.
- Un job réussi prouve une écriture, pas une restauration.
$lesson$),
  ('cyb-c7-p7', 'cyb-c7', 7, $lesson$TESTER une restauration : procédure et fréquence$lesson$, $lesson$
La restauration est le seul moment où la sauvegarde révèle sa valeur réelle. Tout le reste, les jobs verts, les graphiques d'utilisation, les rapports quotidiens, mesure l'activité du système de sauvegarde ; la restauration mesure la capacité de l'organisation à retrouver son travail. Les incidents les plus douloureux ne sont pas ceux où la sauvegarde manque, ce sont ceux où elle existe et ne se déroule pas : format inconnu, mot de passe d'archive oublié, version de l'application différente, certificat périmé, procédure écrite pour un scénario qui n'est plus le bon. C'est pourquoi le test n'est pas une activité de confort réservée aux organisations matures : c'est la condition pour que la règle 3-2-1 cesse d'être une promesse.

La fréquence de test doit être établie à l'avance, inscrite à l'agenda et associée à un responsable, sinon elle sera repoussée indéfiniment au profit des urgences. Un rythme simple et tenable tient en quatre niveaux. Une vérification automatique quotidienne ou hebdomadaire, qui contrôle la fraîcheur, la taille et l'intégrité des copies. Une restauration partielle mensuelle : on tire un échantillon, une table, un dossier de fichiers, et on vérifie qu'il est lisible et cohérent. Un exercice de restauration complète trimestriel, où l'on reconstruit un service entier sur un environnement isolé et où l'on chronomètre l'opération. Enfin, un test déclenché, c'est-à-dire un exercice complet après tout changement majeur : nouvelle version, migration, changement de solution de sauvegarde. Chaque niveau produit un écrit, aussi court soit-il.

```text
PROCÉDURE DE TEST DE RESTAURATION — TRIMESTRIELLE
Durée estimée : 2 h à 4 h — Responsable : référent sécurité + administrateur

1. CADRAGE
   Choisir le service à reconstruire et la date. Annoncer l'exercice.
   Préparer l'environnement isolé : machine vide, réseau séparé,
   aucun accès à la production.

2. RETRAIT D'UNE COPIE
   Identifier la copie à tester dans le manifeste.
   Noter sa date, son horodatage et son empreinte de contrôle.

3. PRÉPARATION DES ACCÈS
   Récupérer les identifiants et la clé de chiffrement hors ligne.
   Vérifier que les certificats et secrets nécessaires sont disponibles.

4. RESTAURATION
   Restaurer sur l'environnement isolé.
   Démarrer les services dans l'ordre documenté.
   Consigner chaque étape, chaque erreur et chaque durée.

5. VÉRIFICATION MÉTIER
   Compter les enregistrements et comparer à la source.
   Ouvrir un dossier récent, vérifier une pièce jointe, imprimer un bordereau.
   Demander à un utilisateur métier de valider deux opérations réelles.

6. MESURE
   Chronométrer le temps total et le temps de retour au service.
   Comparer aux objectifs RTO et RPO de la fiche de service.

7. RÉSULTAT
   Remplir la ligne du journal. Classer : conforme, à corriger, non conforme.
   Ouvrir une action corrective avec un responsable et une échéance.

8. CLÔTURE
   Détruire l'environnement de test et les copies temporaires.
   Archiver le compte rendu dans le dossier de continuité.
```

L'environnement de test mérite une attention particulière, car il est à l'origine de la majorité des faux positifs. Tester sur la machine de production, avec ses réglages actuels, ne prouve presque rien : vous vérifiez que l'outil sait écrire là où il écrit déjà. Le test crédible se fait sur une machine vide, avec une adresse réseau différente, sans accès au service d'annuaire, afin que seules les sauvegardes et votre documentation servent à reconstruire. C'est dans cet environnement dépouillé que réapparaissent les dépendances oubliées : le nom d'hôte attendu par l'application, la résolution de nom, le certificat serveur, le mot de passe du compte de service, le lecteur de bande dont le pilote n'est pas installé. Chacune de ces découvertes est une information précieuse, et chacune doit finir dans la documentation, pas dans un souvenir.

La vérification métier est l'étape que l'on saute le plus souvent, et pourtant elle seule répond à la question posée. Un service qui démarre n'est pas forcément un service juste. Comparez des compteurs : nombre d'adhérents actifs, dernier emprunt enregistré, date de la dernière réservation, montant du dernier versement, présence des pièces jointes d'un dossier récent. Ouvrez ensuite deux ou trois objets réellement utilisés par le personnel, avec quelqu'un qui les connaît, et demandez si ce qu'il voit est cohérent. Dix minutes de validation métier valent mieux que trois heures de contrôle technique, parce qu'elles détectent la corruption logique, les tables non recopiées et les synchronisations interrompues, que la signature d'archive ne voit pas.

Le journal de test est la pièce qui manque dans la plupart des organisations. Il ne s'agit pas d'un rapport épais, mais d'une ligne par exercice, datée, signée, avec un verdict et, le cas échéant, une action corrective. Tenez-le sur plusieurs exercices : la valeur apparaît dans la lecture transversale, quand on voit que le temps de restauration augmente, qu'une même anomalie revient deux trimestres de suite ou qu'un service n'a jamais été testé. Ce tableau est aussi le document que l'on présente à la direction : il transforme une activité technique en pilotage compréhensible, avec des faits datés plutôt que des assurances.

```text
JOURNAL DES TESTS DE RESTAURATION — MÉDIATHÈQUE DES LILAS
---------------------------------------------------------------------------
Date      | Service testé      | Type      | Durée | Verdict   | Action
----------|--------------------|-----------|-------|-----------|------------------
15/01/26  | Emprunt            | Partielle | 45 mn | Conforme  | aucune
12/04/26  | Emprunt            | Complète  | 3 h 10| À corriger| clé récupérée en
          |                    |           |       |           | 40 mn, registre à
          |                    |           |       |           | revoir
18/07/26  | Réservation        | Complète  | 2 h 05| Conforme  | procédure mise à
          |                    |           |       |           | jour
20/09/26  | Gestion            | Partielle | 35 mn | Non conf. | job de 02 h en
          |                    |           |       |           | échec depuis le 12
---------------------------------------------------------------------------
Fréquence cible : automatique hebdo, partielle mensuelle, complète trimestrielle.
```

- Un job réussi prouve une écriture ; seule la restauration prouve une capacité.
- Vérification automatique hebdo, restauration partielle mensuelle, complète trimestrielle.
- Testez toujours sur un environnement isolé, vide et sans accès à la production.
- Chronométrez et comparez aux objectifs de délai et de perte de données.
- Faites valider par une personne métier : elle détecte ce que la technique ignore.
- Tenez un journal daté, avec verdict et action corrective numérotée.
- Préparez le test à l'avance : un créneau bloqué, un modèle de compte rendu et un jeu de données prêts à l'emploi.
$lesson$),
  ('cyb-c7-p8', 'cyb-c7', 8, $lesson$Menaces aux sauvegardes : le rançongiciel vise d'abord les copies$lesson$, $lesson$
Une organisation qui ne dispose que de sauvegardes faciles à atteindre offre à l'attaquant un scénario très simple : chiffrer les données de production, puis détruire les copies pour rendre la rançon inévitable. La chaîne de compromission suit presque toujours le même ordre. L'intrusion commence par un courriel piégé ou un accès distant exposé, puis l'attaquant observe : il cherche le plan de réseau, les comptes d'administration, les outils de supervision et, en priorité, la solution de sauvegarde. Il s'agit souvent du logiciel le moins spectaculaire de l'environnement et souvent du moins protégé, parce qu'il bénéficie d'un accès très large pour remplir sa mission. Une fois identifié le catalogue et les comptes qui le pilotent, la destruction des copies devient une opération de quelques minutes.

Ce que visent précisément les attaquants se liste utilement. Les instantanés de machines virtuelles, ces images qui permettent de remonter en arrière en un clic, sont supprimés en premier : ils constituent la voie de restauration la plus rapide. Viennent les journaux et catalogues de sauvegarde, dont la suppression rend les copies présentes techniquement indisponibles puisqu'on ne sait plus ce qu'elles contiennent ni comment les lire. Puis les supports externes connectés en permanence, les lecteurs de bandes restés montés, les comptes de stockage distant disposant du droit de suppression. Enfin, la documentation : effacer la procédure de restauration et les registres de clés ajoute une couche d'incertitude supplémentaire. À chaque étape, l'objectif est le même : augmenter le temps de retour au service au-delà du seuil que l'organisation juge acceptable.

La pression morale s'ajoute à la pression technique. Une médiathèque dont les adhérents ne peuvent plus emprunter et dont la comptabilité est figée subit une double contrainte : le service public interrompu et l'attente des usagers. L'attaquant mise sur cette urgence pour pousser à la décision rapide, précisément au moment où l'organisation est le moins capable d'évaluer ses options. C'est là que la préparation change tout : une organisation qui sait, chiffres à l'appui, que son service peut repartir en quatre heures conserve sa liberté de décision. Celle qui ignore si ses copies existent n'a plus que la fuite comme option.

```text
CHRONOLOGIE TYPE D'UNE ATTAQUE CONTRE LES SAUVEGARDES
=====================================================

J+0  08 h 12   Ouverture d'une pièce jointe piégée sur un poste
J+0  08 h 40   Vol d'un compte d'administration distant (accès exposé)
J+0  09 h 05   Déplacement latéral vers le serveur de sauvegarde
J+0  09 h 22   Récolte des identifiants du catalogue de sauvegarde
J+0  21 h 47   Effacement des instantanés et des journaux
J+0  22 h 03   Chiffrement des postes et du serveur de fichiers
J+1  06 h 15   Découverte par le personnel, déclenchement du PRA
J+1  06 h 40   Activation des copies immuables hors site
J+1  10 h 30   Restauration d'un service partiel en environnement isolé
J+2  09 h 00   Retour du service principal sur copies vérifiées
=====================================================
Points de bascule : cloisonnement des comptes, immuabilité, test trimestriel.
```

Les menaces ne se limitent pas à l'attaque externe. L'erreur humaine reste une cause majeure : suppression accidentelle d'un dossier partagé, formatage du mauvais disque, script d'expurgation mal calibré, purge d'une base avec une condition trop large. Ces événements n'ont pas besoin d'auteur malveillant et sont au moins aussi fréquents que les intrusions. La sauvegarde immuable et le versionnement y répondent efficacement, à condition que la durée de rétention dépasse le délai de détection de l'erreur, c'est-à-dire souvent plusieurs semaines. Une rétention de sept jours ne protège pas contre une erreur repérée le onzième jour.

Viennent ensuite les risques liés à l'accès distant et aux services en ligne. Un compte de stockage dans le cloud, doté d'un identifiant unique partagé et sans second facteur, se compromet aussi facilement qu'un mot de passe réutilisé. Une solution de sauvegarde en tant que service dont l'éditeur subit une compromission peut voir ses journaux altérés. Un prestataire qui repousse ses propres copies dans le même centre de données que le vôtre ne vous offre pas de site distant. Ces scénarios se traitent par des clauses contractuelles, des preuves d'indépendance, une authentification forte et des contrôles périodiques des droits : la confiance ne se présume pas, elle se vérifie.

Une dernière famille de menaces concerne la gouvernance elle-même. Les sauvegardes accumulent des données personnelles sur des années, souvent au-delà de ce qui est nécessaire : copies de bases d'adhérents, historiques de réservation, exports de fiches. Lister ces contenus, limiter la rétention et tracer les accès réduit simultanément l'impact d'une fuite et le coût d'une restauration. Pensez aussi aux sauvegardes orphelines : les disques externes dans un tiroir, les comptes d'un ancien prestataire, les exports oubliés sur un poste. Ils font partie de la surface d'attaque au même titre que le serveur principal, et leur inventaire doit figurer dans le manifeste.

- La solution de sauvegarde est une cible prioritaire : protégez ses comptes comme le domaine administrateur.
- Les instantanés et catalogues sont supprimés avant les données de production.
- L'immuabilité neutralise la destruction des copies, y compris par un compte volé.
- Une rétention plus courte que le délai de détection de l'erreur ne protège de rien.
- Cloisonnez comptes, réseaux et annuaires entre production et sauvegarde.
- Vérifiez les preuves d'indépendance de vos services et prestataires distants.
- Inscrivez les copies orphelines dans l'inventaire pour pouvoir les éliminer.
$lesson$),
  ('cyb-c7-p9', 'cyb-c7', 9, $lesson$Continuité et reprise : RTO, RPO, niveau de service$lesson$, $lesson$
Continuité et reprise sont deux mots souvent employés l'un pour l'autre alors qu'ils désignent deux objectifs distincts, et les distinguer est la première étape d'un plan crédible. La continuité d'activité désigne ce que vous maintenez pendant l'incident : un service réduit, une procédure manuelle d'exception, un accueil physique dégradé, une alternative temporaire. Elle s'exprime en jours et en périmètre : pendant quarante-huit heures, les emprunts sont traités sur papier et les retours sont acceptés sans réservation. La reprise, elle, désigne le retour aux conditions normales sur les systèmes restaurés : on y parle en heures, en étapes et en preuves de contrôle. Une organisation mature prépare les deux, parce qu'un incident se traverse autant qu'il se répare.

Trois mesures structurent cette préparation. Le temps de reprise, noté RTO pour Recovery Time Objective, exprime la durée maximale acceptable d'indisponibilité d'un service : au-delà, les conséquences opérationnelles deviennent inacceptables. Ce n'est pas une estimation optimiste de ce que l'équipe pourra faire, c'est une décision d'activité, prise par la direction avec les responsables de service, qui engage des moyens. La perte de données admissible, notée RPO pour Recovery Point Objective, exprime le volume maximal de travail que l'organisation accepte de perdre, mesuré en temps écoulé depuis la dernière copie : un RPO d'une heure signifie qu'au pire, une heure de saisie disparaît. Elle se traduit directement en fréquence de sauvegarde, ce qui en fait la mesure la plus concrète du dispositif.

À ces deux mesures s'ajoutent la durée tolérable d'interruption, qui fixe le plafond au-delà duquel l'activité est considérée comme sérieusement compromise, et le niveau de service, c'est-à-dire la promesse formalisée de performance, avec son périmètre, ses exclusions et son mode de calcul. On parle aussi de seuil minimal de service pour ce qui doit absolument tourner pendant la crise. Ces notions forment un ensemble cohérent : la durée tolérable borne les RTO, le RPO sert de cible aux sauvegardes, le niveau de service rend le tout vérifiable. Sans cette cohérence, on se retrouve avec un RTO de deux heures et des sauvegardes quotidiennes, ce qui est un objectif sans aucun moyen de l'atteindre.

```table
Service | Scénario de référence | RTO cible | RPO cible | Conséquence pour la sauvegarde | Niveau de service
--- | --- | --- | --- | --- | ---
Emprunt en accueil public | Perte du serveur applicatif | 4 heures | 1 heure | Sauvegarde incrément toutes les heures + copie hors site | Service restauré le jour même, mode manuel dès J+0
Réservation en ligne | Chiffrement du site et de sa base | 8 heures | 15 minutes | Base en continu, restauration testée chaque trimestre | Site inaccessible au plus une demi-journée
Gestion administrative et courriels | Corruption de la messagerie | 24 heures | 4 heures | Exports horaires, rétention 30 jours, journaux conservés | Repartir sous deux jours avec perte limitée
Archives et contenus numériques | Vol ou destruction d'un support | 72 heures | 24 heures | Copie hebdomadaire hors site, rétention longue | Retour sous trois jours, priorité secondaire
```

Le tableau ci-dessus illustre une règle de proportionnalité essentielle : les objectifs varient selon la criticité, et il serait aussi coûteux qu'absurde d'imposer un RPO de quinze minutes à tous les services. Pour décider, posez trois questions à chaque responsable de service. Quelle perte de données rend le travail recommencé incomplet ? Combien de temps l'activité peut-elle tenir en mode dégradé avant que le préjudice devient grave, financier, juridique ou d'image ? Quel est le coût d'une minute d'indisponibilité, en euros ou en missions non remplies ? Les réponses donnent l'ordre de grandeur, et l'ordre de grandeur donne l'architecture : un RTO court impose des copies prêtes à démarrer et un environnement de repli préparé à l'avance, un RPO court impose une fréquence de copie élevée.

Relisez ensuite vos objectifs à l'aune de ce que le dispositif permet réellement. Un RPO d'une heure n'est atteignable que si la sauvegarde tourne effectivement toutes les heures et que le job est surveillé : sinon, votre objectif n'existe que sur le papier. Un RTO de quatre heures n'est tenable que si la procédure de restauration a été chronométrée, si les identifiants et les clés sont accessibles immédiatement et si l'environnement cible est dimensionné pour accueillir le service. C'est le point de jonction entre ce chapitre et le précédent : le test de restauration fournit la mesure réelle, l'objectif fournit la cible, et l'écart entre les deux mesure votre exposition.

Enfin, notez que les objectifs évoluent avec l'organisation. Une nouvelle plateforme de réservation, l'ouverture d'un service en ligne, la collecte de nouvelles données personnelles ou l'augmentation du volume d'emprunts déplacent la criticité. Revoyez les RTO et RPO au moins une fois par an, avec les responsables concernés, et après chaque incident majeur. Documentez les décisions, y compris celles qui acceptent explicitement un risque : un RPO de vingt-quatre heures assumé et signé est une décision de direction ; le même RPO subi parce que personne n'y a pensé est une négligence.

- La continuité gère le service pendant l'incident ; la reprise rend le service normal.
- Le RTO fixe la durée d'indisponibilité acceptable ; il s'exprime en heures.
- Le RPO fixe la perte de données admissible ; il se traduit en fréquence de copie.
- Les objectifs se règlent par service, selon la criticité réelle, pas uniformément.
- Un objectif sans moyen vérifiable est un souhait : reliez-le à un job surveillé.
- Mesurez le temps réel de restauration et comparez-le à la cible chaque trimestre.
- Revoyez les objectifs annuellement et après tout incident majeur.
$lesson$),
  ('cyb-c7-p10', 'cyb-c7', 10, $lesson$Plan de reprise d'activité : déclencheurs, rôles et étapes$lesson$, $lesson$
Un plan de reprise d'activité n'a de valeur que s'il tient sur quelques pages, s'il se lit sous stress et s'il contient des décisions déjà prises. Un document de cent pages, rédigé par un cabinet et rangé dans un tiroir, ne servira jamais, parce qu'aucune personne paniquée ne l'ouvrira. Commencez donc par les déclencheurs, c'est-à-dire les conditions objectives qui transforment un incident ordinaire en activation du plan : indisponibilité d'un service au-delà d'un seuil, perte de données avérée, suspicion de compromission d'un compte d'administration, chiffrement constaté sur un poste ou un partage, alerte officielle concernant un service que vous utilisez. Chaque déclencheur est associé à une décision et à une personne : le plan ne dit pas seulement quoi faire, il dit qui a le droit d'activer quoi, et à quelle heure au plus tard.

Les rôles se définissent avant l'incident, avec un nom et un remplaçant pour chacun. La direction tranche les arbitrages : priorité des services à restaurer, décision de communication, éventuel renvoi à l'assurance ou à l'autorité. Le référent sécurité coordonne le temps, tient le journal des décisions et veille à ne pas détruire les preuves. L'administrateur exécute techniquement la reprise. Le responsable du service métier valide le contenu restauré, car personne d'autre ne sait si les données sont justes. Une personne distincte assure l'information des usagers, responsabilité qu'on oublie souvent alors qu'elle conditionne la sérénité de l'accueil dès le premier jour. Pour chaque rôle, écrivez le nom, le remplaçant, le numéro à joindre et la première action attendue.

Les étapes, enfin, suivent un ordre qui se dérobe si on l'improvise. Constat et qualification, avec l'heure notée. Confinement : on isole, on ne réinstalle rien, on ne formate rien, on préserve les journaux. Activation du plan et convocation des rôles. Choix de la source de restauration, qui n'est pas toujours la copie la plus récente : une copie faite avant la compromission vaut mieux qu'une copie postérieure potentiellement empoisonnée. Restauration en environnement contrôlé, vérification technique puis validation métier. Remise en service progressive, service par service, avec une personne qui surveille. Communication. Enfin, retour d'expérience daté, avec les actions correctives et la mise à jour du plan.

```text
EXTRAIT DU PLAN DE REPRISE — MÉDIATHÈQUE DES LILAS (page 1 sur 4)

DÉCLENCHEURS
  D1  Service principal indisponible plus de 2 heures            -> référent
  D2  Chiffrement ou corruption constaté sur un partage          -> direction
  D3  Compte d'administration volé ou usage anormal              -> direction
  D4  Perte involontaire de données validée par le service       -> référent
  Dans les 30 minutes : confinement + journal d'incident ouvert.

RÔLES
  Direction          : arbitrage, communication officielle, assurance
  Référent sécurité  : coordination, journal, contact des prestataires
  Administrateur     : confinement, restauration, journaux techniques
  Responsable métier : validation du contenu restauré, reprise en charge
  Information usagers: message d'accueil, site web, réseau social

ÉTAPES
  1  Constat, heure, qualification (sans détruire de preuve)
  2  Confinement : isolation, coupure ciblée, rien n'est réinstallé
  3  Activation, convocation, répartition des rôles
  4  Choix de la copie saine et décision de restauration
  5  Restauration puis vérification technique
  6  Validation métier puis remise en service progressive
  7  Communication aux usagers et aux partenaires
  8  Retour d'expérience sous 5 jours ouvrés, plan mis à jour
```

La chronologie ci-dessous illustre un scénario de reprise compatible avec les objectifs d'un service dont le RTO vaut quatre heures. Elle n'est pas un engagement de performance, c'est un ordre de grandeur qui permet de discuter : si l'une des étapes dépasse son créneau, c'est le plan ou les moyens qu'il faut revoir, pas l'équipe. Notez que la décision du choix de la copie est placée tôt : c'est le moment où une hésitation coûte le plus cher, et c'est celui qu'il faut avoir préparé en amont, avec un critère écrit plutôt qu'une opinion improvisée.

```text
CHRONOLOGIE DE REPRISE — SERVICE D'EMPRUNT (RTO : 4 heures)
------------------------------------------------------------
T+00:00  Constat par le personnel d'accueil, heure notée
T+00:15  Confinement du segment touché, journal d'incident ouvert
T+00:30  Activation du plan, convocation des cinq rôles
T+00:45  Choix de la copie saine (dernière copie non compromise)
T+01:00  Restauration sur environnement isolé
T+02:30  Vérification technique : intégrité, services, certificats
T+03:00  Validation métier : comptes, emprunts récents, pièces jointes
T+03:30  Remise en service progressive, surveillance dédiée
T+04:00  Service de retour, message aux usagers
J+5      Retour d'expérience et mise à jour du plan
------------------------------------------------------------
Toute étape au-delà de son créneau déclenche un arbitrage de direction.
```
$lesson$),
  ('cyb-c7-p11', 'cyb-c7', 11, $lesson$Tableau de bord et exercice de crise$lesson$, $lesson$
Ce que l'on ne pilote pas ne s'améliore pas, et la continuité échappe rarement à cette règle : les sauvegardes tournent, les rapports s'accumulent, et personne ne regarde si le résultat correspond aux objectifs. Un tableau de bord utile tient en une page et une dizaine d'indicateurs, mis à jour à une fréquence annoncée et revus en réunion trimestrielle. Choisissez des indicateurs qui déclenchent une action : l'âge de la dernière copie, le pourcentage de tests réalisés à date, l'écart entre le temps de restauration mesuré et le RTO, la perte observée au dernier test comparée au RPO. Un indicateur sans cible et sans responsable devient de la décoration : mieux vaut huit indicateurs qui comptent que trente qui rassurent.

```table
Indicateur | Définition | Fréquence | Cible | Responsable
--- | --- | --- | --- | ---
Âge de la dernière copie | Heures écoulées depuis la copie aboutie | Quotidienne | Moins de 26 heures | Administrateur
Sauvegardes conformes | Jobs aboutis sur jobs planifiés | Mensuelle | 100 % | Administrateur
Tests réalisés à date | Exercices menés sur exercices prévus | Trimestrielle | 100 % | Référent sécurité
Temps de restauration mesuré | Durée du dernier exercice complet | Trimestrielle | Inférieur au RTO | Référent sécurité
Perte observée | Écart entre dernière copie et source au test | Trimestrielle | Inférieure au RPO | Administrateur
Revue des accès | Comptes privilégiés vérifiés | Trimestrielle | 100 % | Direction
Délai de signalement | Temps entre constat et déclaration | Par incident | Moins de 30 minutes | Direction
```

L'exercice de crise complète ce tableau en mobilisant les personnes plutôt que les outils. Une fois par an, réunissez les rôles du plan pour une séance d'une heure et demie, sans machine, autour d'un scénario écrit : poste chiffré un lundi matin, base de données injoignable, courriel d'extorsion découvert. Le déroulé est simple : lecture du scénario par un animateur neutre, puis tour de table où chacun annonce ce qu'il ferait, dans quel ordre et en contactant qui. L'animateur injecte des complications, par exemple l'absence du référent ou l'échec de la copie locale, et note les hésitations. La séance ne cherche pas des coupables, elle cherche les trous du plan : un numéro qui ne répond pas, une étape sans responsable, une décision dont personne ne sait qui la prend.

Le débriefing clôt l'exercice et doit produire un écrit en une page : ce qui a fonctionné, ce qui a été improvisé, les trois actions correctives avec un responsable et une échéance, et la mise à jour du plan si nécessaire. Conservez ces comptes rendus ensemble : trois exercices annuels alignés montrent une trajectoire bien plus convaincante qu'une promesse.
$lesson$),
  ('cyb-c7-p12', 'cyb-c7', 12, $lesson$Mini-projet guidé : le dossier de continuité de la médiathèque$lesson$, $lesson$
Il est temps d'assembler les pièces du chapitre dans un livrable unique, le dossier de continuité de la Médiathèque des Lilas, qui reprend l'organisation après l'incident vécu au chapitre précédent. Ce dossier contient cinq documents courts : la politique de sécurité d'une page, le manifeste des sauvegardes avec le schéma 3-2-1, la procédure de test de restauration, le plan de reprise d'activité en quatre pages, et le journal des tests. Aucun de ces documents n'est nouveau s'il a été rédigé au fil des sections : le mini-projet consiste surtout à les relier, à les rendre cohérents entre eux et à les rendre utilisables par quelqu'un d'autre que vous.

```text
DOSSIER-CONTINUITE-MEDIATHEQUE/
  01-politique-securite.txt          1 page, versionnée, approuvée
  02-manifeste-sauvegardes.yaml      inventaire, fréquences, rétentions
  03-schema-3-2-1.txt                topologie commentée, sites, supports
  04-procedure-restauration.txt      8 étapes, rôles, critères de validité
  05-plan-reprise.txt                déclencheurs, rôles, étapes, contacts
  06-journal-tests.txt               une ligne par exercice, verdict
  preuves/
    diffusion-politique.txt          date, destinataires
    comptes-rendus-exercices.txt     3 exercices annuels archivés
    registre-cles.txt                emplacement des clés, test de récupération
```

Procédez en cinq passes pour ne pas vous disperser. Première passe : le manifeste, parce que l'inventaire décide de tout le reste ; listez les objets, les fréquences, les rétentions et les responsables. Deuxième passe : le schéma 3-2-1, en dessinant la topologie réelle de votre organisation, supports compris, avec la mention explicite du site distant. Troisième passe : les RTO et RPO, service par service, en justifiant chaque valeur par une conséquence opérationnelle plutôt que par un chiffre rond. Quatrième passe : la procédure de test et le plan de reprise, en y écrivant des noms et des numéros réels. Cinquième passe : la politique, qui referme le dispositif en énonçant les règles dont tout le reste est la preuve.

Pour vérifier que votre dossier est réellement exploitable, appliquez la liste de contrôle suivante. Un lecteur extérieur doit pouvoir répondre, en dix minutes et sans vous demander d'explication : que doit-on sauvegarder, à quelle fréquence, où vivent les copies, comment sait-on qu'elles sont bonnes, que faire le lundi matin si le serveur ne répond plus, qui décide, qui restaure, qui valide, qui prévient les usagers. Si l'une de ces réponses n'existe pas, elle manque encore ; si elle existe mais qu'elle n'est écrite nulle part, elle n'existe pas.

- Assemblez cinq documents courts plutôt qu'un rapport monolithique.
- Commencez par l'inventaire : il commande les fréquences, les rétentions et les coûts.
- Reliez chaque objectif de service à une copie réellement testée.
- Écrivez des noms, des numéros et des remplaçants, jamais des postes abstraits.
- Vérifiez le dossier avec une personne qui n'a pas participé à sa rédaction.
- Datez, versionnez et annulez les versions antérieures pour éviter les doublons.
$lesson$),
  ('cyb-c7-p13', 'cyb-c7', 13, $lesson$À retenir$lesson$, $lesson$
- Une règle écrite remplace la mémoire orale, qui disparaît avec les personnes.
- La politique dit ce qui doit être vrai, la procédure dit comment, l'outil applique.
- Structure en neuf rubriques : objet, portée, définitions, rôles, règles, signalement, non-conformité, sanctions, révision.
- Une portée honnête précise aussi ce qui n'est pas encore couvert.
- Trois rôles suffisent : direction qui décide, référent qui coordonne, exécutant qui applique.
- Chaque règle se vérifie : elle a un énoncé, une raison courte et une preuve attendue.
- La règle 3-2-1 : trois copies dont la production, deux supports, un site distant.
- L'immuabilité interdit la suppression, y compris pour un compte d'administration volé.
- Chiffrez au repos et en transit, et gardez la clé hors de portée des données.
- Sauvegardez les configurations, les secrets et les procédures, pas seulement les données.
- Un job réussi prouve une écriture ; seule la restauration prouve une capacité.
- Test mensuel partiel, test trimestriel complet, test déclenché après tout changement majeur.
- Le RTO fixe le délai d'indisponibilité acceptable, le RPO la perte de données admissible.
- Les objectifs se règlent par service, selon la criticité, et se comparent aux mesures réelles.
- Le plan de reprise commence par des déclencheurs objectifs et des rôles nommés.
- On pilote la continuité avec un tableau de bord court et un exercice de crise annuel.
$lesson$),
  ('cyb-c7-p14', 'cyb-c7', 14, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : rédiger une politique de principes si généraux qu'elle n'interdit rien → Correction : cinq à dix règles vérifiables, chacune assortie d'une preuve attendue.
- Piège : publier un document sans date, sans version ni propriétaire → Correction : datez, versionnez, nommez le propriétaire et prévoyez la prochaine révision.
- Piège : oublier bénévoles, stagiaires et prestataires dans la portée → Correction : listez explicitement toutes les populations et leurs obligations d'accès.
- Piège : sauvegarder trois fois le même contenu sur un même automate → Correction : exigez deux supports réellement distincts et un site physiquement séparé.
- Piège : ne pas sauvegarder les configurations et perdre une journée à reconstruire → Correction : ajoutez serveur, réseau, scripts, certificats et documentation à l'inventaire.
- Piège : garder la clé de chiffrement dans le même fichier que les sauvegardes → Correction : clé hors ligne ou coffre séparé, registre des clés et test annuel de récupération.
- Piège : se contenter de jaunes dans le rapport de sauvegarde → Correction : programmez une restauration partielle mensuelle et un exercice complet trimestriel.
- Piège : tester la restauration sur la machine de production → Correction : reconstruisez sur un environnement isolé, vide et sans accès au service d'annuaire.
- Piège : reprendre la copie la plus récente sans vérifier qu'elle précède la compromission → Correction : arbitrez la source de restauration avec un critère écrit dans le plan.
- Piège : fixer un RTO de deux heures sans vérifier que la restauration prend six heures → Correction : chronométrez le test réel et rapprochez l'objectif de la mesure.
- Piège : ranger le plan de reprise dans un tiroir après sa rédaction → Correction : exercez-le chaque année et publiez les actions correctives qui en sortent.
- Piège : traiter la communication aux usagers comme une formalité de fin de crise → Correction : nommez la personne qui informe dès la première heure et préparez un message type.
$lesson$),
  ('cyb-c7-p15', 'cyb-c7', 15, $lesson$Pour aller plus loin$lesson$, $lesson$
Les ressources officielles francophones se lisent sans formation préalable. Le site de la CNIL, https://www.cnil.fr, publie les guides de conformité et les modèles de documents utiles à la rédaction d'une politique de sécurité et à la gestion des données personnelles contenues dans vos sauvegardes. La plateforme cybermalveillance.gouv.fr, à l'adresse https://www.cybermalveillance.gouv.fr, propose des fiches opérationnelles conçues pour les petites structures : prévention, détection, réaction à un rançongiciel, avec des check-lists directement réutilisables dans votre plan de reprise. Prenez l'habitude d'y revenir avant d'écrire, plutôt qu'après l'incident.

Côté international, le site du NIST, https://www.nist.gov, rassemble les référentiels de gestion des risques et de continuité utilisés partout dans le monde, dont le cadre de cybersécurité et les documents consacrés à la continuité des activités. Ils sont plus formels que les guides français, mais ils vous apprendront le vocabulaire exact des objectifs de reprise et vous permettront de dialoguer à armes égales avec un prestataire ou un assureur. Gardez ces adresses en favori, et revenez-y au moment précis où une question se pose.
$lesson$),
  ('cyb-c7-p16', 'cyb-c7', 16, $lesson$Et maintenant : consolider et transmettre$lesson$, $lesson$
Vous arrivez au terme du parcours Cybersécurité avec les trois jambes du dispositif : comprendre les attaques, les préparer et organiser ce qui doit durer. La suite immédiate est l'exercice pratique qui accompagne ce chapitre : vous y rédigerez seul le dossier de continuité de la médiathèque, en partant de la politique d'une page, du schéma 3-2-1 avec son inventaire et ses fréquences, des RTO et RPO de trois services, de la procédure de test trimestrielle et du plan de reprise en huit étapes. Travaillez d'abord sans les modèles de la leçon, puis reprenez-les pour comparer : c'est dans l'écart entre vos deux versions que vous mesurerez ce qui reste à consolider. Le quiz de quatre questions vous donne en parallèle un contrôle rapide des notions essentielles.

Le geste qui suit mérite d'être pris au sérieux : transmettre. Un dossier de continuité n'a de valeur que s'il circule et se pratique par d'autres que son auteur. Présentez-le à votre direction, faites-le relire par une personne d'accueil, testez-le avec le remplaçant de votre administrateur, et inscrivez le premier exercice au calendrier avant de refermer le sujet. C'est ainsi qu'un document devient une capacité d'organisation, et qu'un incident vécu se transforme en leçon apprise plutôt qu'en simple souvenir.
$lesson$);
