-- easyLearn — seed des pages numérotées du Cours (678 pages, 44 chapitres)
-- Chaque section « ## » d'une leçon devient une page titrée.
-- Idempotent : remplace les pages des chapitres listés.
-- Généré par scripts/generate-pages-migration.mjs — ne pas éditer à la main.
-- Prérequis : 202610040004_chapter_pages.sql (table chapter_pages).



insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('web-c6-p1', 'web-c6', 1, $lesson$Pourquoi React : l'interface comme fonction de l'état$lesson$, $lesson$
Bienvenue dans le sixième chapitre du parcours Développement web moderne : celui où votre rapport avec l'interface change de nature. Jusqu'ici, la page de l'atelier de la Médiathèque des Lilas a été construite comme le fait la majorité du web : un fichier HTML décrit la structure, une feuille de style l'habille, et un fichier JavaScript prend la main sur le document pour le modifier quand quelque chose se passe. Dans le chapitre consacré au DOM, vous avez sélectionné des éléments, vous avez écrit du texte à l'intérieur de ces éléments, vous avez branché des boutons avec des gestionnaires d'événements. Ce fonctionnement, dit impératif, décrit pas à pas comment transformer l'écran. React propose un renversement : vous décrivez à quoi l'interface doit ressembler pour un état donné des données, et c'est React qui se charge de mettre l'écran à jour. L'interface devient le résultat d'une fonction dont les données sont l'argument. Cette phrase est la clé de voûte du chapitre, et tout ce qui suit ne fait que la détailler, l'illustrer et la mettre en pratique sur un vrai projet.

À la fin de cette leçon, vous saurez faire un ensemble de choses très concrètes, et vous les aurez déjà manipulées dans du code JSX complet. Vous découpererez une page en composants autonomes, chacun responsable d'une région visible que vous connaissez déjà pour l'avoir écrite en HTML : bandeau, programme, carte d'inscription, pied de page. Vous passerez des données d'un composant à l'autre avec les propriétés, souvent appelées props, et vous comprendrez pourquoi ces données descendent toujours de haut en bas dans l'arbre des composants. Vous déclencherez des mises à jour d'écran avec le hook useState, en gardant une règle simple en tête : chaque composant possède son propre état, et l'état qui concerne plusieurs composants remonte vers leur ancêtre commun. Vous afficherez des listes avec map et des clés stables, vous alternerez des contenus selon des conditions, vous traiterez des événements de clic et de saisie, et vous écrirez au moins un composant réutilisable, un bouton paramétrable, que vous emploierez à plusieurs endroits. Le tout sera assemblé dans un mini-projet guidé : le site de l'atelier, réécrit en composants React.

Deux prérequis, avant d'entrer dans le vif du sujet. Le premier est JavaScript lui-même : les fonctions fléchées, la décomposition d'objets, les tableaux et leurs méthodes map et filter, les opérateurs conditionnels, tout cela a été vu dans les chapitres précédents et va servir à chaque exemple. Le deuxième est npm, abordé dans le chapitre cinq : React s'installe comme une dépendance, et le code JSX a besoin d'un outil de transformation pour devenir du JavaScript que le navigateur sait exécuter. Ce point mérite d'être dit franchement, parce qu'il conditionne la manière dont vous allez pratiquer ici : les exemples de cette leçon sont écrits en JSX, la syntaxe que vous utiliserez réellement dans un projet React ; l'exercice pratique, lui, s'exécute dans un environnement qui ne dispose ni de bundler ni d'installateur de paquets, et repose donc sur un squelette en JavaScript classique qui reproduit fidèlement les mêmes mécanismes. Cette différence est annoncée sans détour dans la consigne de l'exercice, et vous verrez que les analogies sont assez précises pour que votre travail de l'exercice reste directement transférable à un vrai projet React.

Une recommandation sur la manière d'aborder ce chapitre, comme pour les précédents : le code s'apprend en l'écrivant soi-même. Recopiez chaque exemple dans votre éditeur, observez ce qu'il affiche, changez une valeur, supprimez une propriété, remettez un état à zéro et regardez ce que l'écran devient. Une interface qui ne se met pas à jour comme prévu n'est pas un échec, c'est une information : elle vous dit exactement où votre donnée ne circule pas. Nous avancerons par étapes, en alternant explications détaillées, exemples commentés et pièges rencontrés en pratique. Le fil rouge reste le site de l'atelier de la Médiathèque des Lilas : chaque section du chapitre y pioche un morceau, et le mini-projet final assemble tout.



Repartons d'un besoin que vous avez déjà rencontré : afficher le nombre de places restantes pour l'atelier et le faire baisser quand quelqu'un s'inscrit. En JavaScript classique, la logique s'écrit comme une suite d'ordres. On cherche le nœud du document qui contient le chiffre, on écrit une nouvelle valeur dedans, on branche un bouton qui décrémente une variable, puis on recopie cette variable dans le nœud. L'ordre des opérations compte, chaque étape vise une cible précise du document, et la moindre modification de la structure HTML oblige à relire tout le cheminement.

```html
<p id="restantes">12 places restantes</p>
<button id="moins">Retirer une place</button>

<script>
  let restantes = 12;
  const zone = document.getElementById("restantes");
  const bouton = document.getElementById("moins");

  function afficher() {
    zone.textContent = restantes + " places restantes";
  }

  bouton.addEventListener("click", function () {
    if (restantes > 0) {
      restantes = restantes - 1;
      afficher();
    }
  });
</script>
```

Ce code fonctionne, et vous seriez capable de l'écrire seul. Il présente pourtant trois faiblesses qui deviennent pénibles dès que la page grossit. La première : la valeur réelle du compteur est dispersée entre une variable JavaScript et le texte affiché à l'écran, deux endroits qu'il faut garder en cohérence à la main. La deuxième : la logique de mise à jour est émiettée à travers plusieurs fonctions et plusieurs cibles du document ; ajouter un deuxième compteur, par exemple le nombre de places déjà prises, oblige à dupliquer ce cheminement. La troisième : le code décrit des gestes plutôt que le résultat ; il dit comment faire, pas ce que l'on veut obtenir. Si quelqu'un modifie la structure HTML sans toucher au script, le script cesse de trouver ses cibles et se tait, souvent sans message d'erreur explicite.

React inverse complètement la direction. Vous écrivez une fonction qui reçoit les données courantes et renvoie l'apparence de l'interface correspondante. React appelle cette fonction, observe le résultat, compare avec ce qui est déjà affiché et n'applique que les différences. On résume souvent cette approche par une formule : l'interface est une fonction de l'état. Les données passent en entrée, l'image de l'écran sort en sortie, et la mise à jour n'est plus une opération que vous déclenchez, c'est une conséquence que React produit.

```jsx
function CartePlaces({ restantes }) {
  return <p>{restantes} places restantes</p>;
}

function Application() {
  const [restantes, setRestantes] = useState(12);

  function retirerUnePlace() {
    if (restantes > 0) {
      setRestantes(restantes - 1);
    }
  }

  return (
    <div>
      <CartePlaces restantes={restantes} />
      <button onClick={retirerUnePlace}>Retirer une place</button>
    </div>
  );
}
```

Comparez les deux blocs. Le second ne contient aucune recherche dans le document, aucune cible à atteindre, aucune instruction du type insérer du texte ici. Il déclare : voici la carte des places, voici le bouton, voici la valeur actuelle. Quand setRestantes est appelée avec une nouvelle valeur, React relance la fonction de l'application, obtient une nouvelle description, compare et remplace uniquement le chiffre qui a changé. Vous ne gérez plus le document objet, vous gérez des données.

Cette déclaration a des conséquences pratiques qu'il vaut mieux poser dès maintenant. L'état devient la source unique de vérité : il n'y a plus de copie du compteur à synchroniser, parce qu'il n'y a qu'une variable et que l'écran n'est qu'une projection de cette variable. La logique se regroupe au même endroit, dans la fonction du composant, au lieu d'être émiettée entre plusieurs écouteurs. Et la lisibilité s'en trouve transformée : un nouveau lecteur du fichier voit immédiatement quelles données existent et comment elles se traduisent en interface, sans avoir à reconstituer une chaîne d'ordres impératifs.

Soyons précis sur ce que React ne fait pas. Ce n'est pas un langage : vous écrivez du JavaScript, avec ses fonctions, ses tableaux, ses objets. Ce n'est pas non plus une application complète qui imposerent une structure de projet : React se concentre sur la couche d'affichage, et l'on ajoute autour, si besoin, un routeur pour la navigation, un outil de requêtes pour les données distantes, un gestionnaire d'état global pour les cas complexes. Le modèle mental à conserver tient en une phrase : vous donnez des données à un composant, le composant vous rend une description de l'écran, et React se charge de la partie fastidieuse.

- L'approche impérative décrit des gestes sur le document ; l'approche React décrit le résultat attendu.
- L'état est la source unique de vérité, l'écran n'en est qu'une projection.
- Quand l'état change, React recalcule la description et n'applique que les différences.
- Un composant ne modifie jamais directement le document objet.
- La logique de mise à jour se regroupe dans le composant qui possède l'état.
- React reste une bibliothèque d'affichage : langage, données et outillage restent à choisir à côté.
$lesson$),
  ('web-c6-p2', 'web-c6', 2, $lesson$JSX : syntaxe et différences avec le HTML$lesson$, $lesson$
Le JSX est une extension de syntaxe JavaScript qui permet d'écrire de l'apparence d'interface directement dans du code. Il apparaît dans des fichiers d'extension jsx, ou parfois dans des fichiers JavaScript lorsque l'outil de projet l'accepte. À la lecture, il ressemble à du HTML ; en réalité, il s'agit de JavaScript : chaque morceau de JSX est transformé, avant exécution, en appels de fonctions qui construisent des objets descriptifs. Retenez cette idée, elle lèvera plusieurs malentendus : le JSX n'est pas du texte que l'on colle dans la page, c'est une manière compacte d'écrire des appels de fonctions.

```jsx
function Bandeau({ titre, sousTitre }) {
  const date = "samedi 18 octobre";
  const places = 12;

  return (
    <header className="bandeau">
      <h1>{titre}</h1>
      <p>{sousTitre} — atelier du {date}</p>
      <p>{places} places ouvertes</p>
    </header>
  );
}
```

Dans ce bloc, tout ce qui est entre accolades est du JavaScript évalué : une variable, une expression, un appel de fonction. Tout ce qui est en dehors des accolaves est du texte ou une balise décrite. Les accolades ouvrent une fenêtre vers le langage, et cette fenêtre fonctionne partout où une valeur a du sens : dans le contenu d'une balise, dans la valeur d'un attribut, dans le tableau renvoyé par une boucle map. Si vous oubliez les accolades, le texte des accolades s'affiche littéralement, ce qui est l'erreur de débutant la plus fréquente en JSX.

Les différences avec le HTML méritent d'être énumérées sans ambiguïté, car elles sont peu nombreuses mais systématiques. D'abord, certains noms d'attributs changent parce qu'ils entreraient en conflit avec des mots réservés du langage ou parce que la convention JavaScript utilise la casse de type chameau. Ensuite, les balises qui ne contiennent rien doivent être fermées explicitement avec une barre oblique finale. Ensuite, les expressions dynamiques s'écrivent entre accolades, jamais dans des guillemets. Enfin, un morceau de JSX renvoie toujours une seule valeur, comme une fonction JavaScript : quand plusieurs éléments doivent être frères, on les enveloppe dans un conteneur ou dans un fragment.

| Écriture en HTML | Écriture en JSX | Raison |
| --- | --- | --- |
| classe d'un élément | attribut className | classe est un mot réservé du langage |
| étiquette d'un lien de formulaire | attribut htmlFor | for est un mot réservé du langage |
| attributs en minuscules | attributs en casse de chameau | tabindex devient tabIndex, http-equiv devient httpEquiv |
| balise image sans fermeture | balise fermée avec une barre oblique | le JSX décrit des éléments, tous ont une fin |
| style écrit dans une chaîne | objet JavaScript entre accolades | la mise en forme est donnée comme une donnée |
| texte entre guillemets pour variable | expression entre accolades | les guillemets décrivent du texte fixe |

Trois règles d'écriture complètent ce tableau. La première concerne les chaînes : un attribut dont la valeur ne bouge jamais s'écrit entre guillemets, comme le libellé d'une balise img ou l'adresse d'une balise a. Dès que la valeur dépend d'une donnée, on passe entre accolades. La deuxième concerne les valeurs booléennes : écrire l'attribut sans valeur signifie true, de sorte qu'un attribut de type aria-pressed peut être omis ou présent selon un état. La troisième concerne le style : le JSX accepte un objet dont les noms de propriétés suivent la casse de chameau, parce que la propriété de style en JavaScript n'est pas le nom de la propriété CSS.

```jsx
const saison = "automne";
const informations = { salle: "salle 2", duree: "3 heures" };

const apercu = (
  <section className={"apercu " + saison}>
    <img src="atelier.jpg" alt="Participants devant un écran" />
    <p style={{ fontWeight: 700 }}>{informations.salle}</p>
    <p>Durée : {informations.duree}</p>
    <button disabled>Complet</button>
  </section>
);
```

Un dernier point rassurant : le JSX échappe automatiquement tout ce qui n'est pas balise. Un texte qui contient des chevrons, une accolade ou une esperluette s'affiche tel quel, sans risque d'être interprété comme du balisage. Cette protection est l'une des raisons pour lesquelles React a rendu les injections de code dans l'interface beaucoup plus rares qu'à l'époque où l'on concaténait des chaînes pour fabriquer du HTML. Écrivez du contenu, il sera traité comme du contenu.

- Le JSX s'écrit dans du JavaScript et est transformé en appels de fonctions avant exécution.
- Les accolades ouvrent une expression JavaScript ; sans elles, le texte s'affiche littéralement.
- Utilisez className pour la classe et htmlFor pour l'étiquette d'un lien de formulaire.
- Fermez chaque balise vide avec une barre oblique.
- Un morceau de JSX a un seul élément racine : un conteneur ou un fragment.
- Les guillemets portent une valeur fixe, les accolades portent une valeur calculée.
- Le JSX échappe le contenu textuel : il n'est pas interprété comme du balisage.
$lesson$),
  ('web-c6-p3', 'web-c6', 3, $lesson$Composants fonctionnels$lesson$, $lesson$
Le composant est l'unité de base d'une interface React : un morceau d'écran que l'on nomme, que l'on réutilise et que l'on peut raisonner séparément du reste. Sa forme la plus simple est une fonction JavaScript qui renvoie du JSX. Rien de plus : pas de classe obligatoire, pas de méthode spéciale, pas de configuration. La fonction reçoit des données, elle renvoie une description de l'apparence correspondante.

```jsx
function Bandeau() {
  return (
    <header>
      <h1>Médiathèque des Lilas</h1>
      <p>Ateliers gratuits, sur inscription</p>
    </header>
  );
}

function PiedDePage() {
  return <footer>© 2026 Médiathèque des Lilas</footer>;
}

function Application() {
  return (
    <div>
      <Bandeau />
      <PiedDePage />
    </div>
  );
}
```

Trois conventions se dégagent de cet exemple et tiennent à elles seules une bonne partie de la lisibilité d'un projet React. La première : le nom d'un composant commence par une majuscule. Cette capitale n'est pas décorative, elle distingue un composant d'une balise HTML ordinaire dans la syntaxe du JSX. Écrivez bandeau en minuscules et le JSX cherchera une balise nommée bandeau ; écrivez Bandeau et il cherchera la fonction correspondante. La deuxième convention : un composant occupe une zone cohérente de l'écran, en général une région que vous auriez déjà isolée en HTML, comme un en-tête, une liste de séances ou une carte d'inscription. La troisième : le composant est nommé d'après ce qu'il représente, jamais d'après ce qu'il est censé faire au passage, ce qui vous évite des noms du type BlocMilieuBas.

Le rendu, lui, suit un mécanisme simple à décrire : pour afficher un composant, React appelle la fonction, récupère le JSX qu'elle renvoie, le transforme en éléments de l'écran et les place à la bonne position. Si l'état ou les propriétés du composant changent, React l'appelle une deuxième fois, compare avec ce qui s'affichait et applique la différence. Chaque appel de fonction produit donc une image complète de ce que ce composant doit montrer à cet instant. Cette idée explique pourquoi il ne faut jamais chercher à modifier l'écran en cours de route depuis l'intérieur du composant : la fonction doit rester un portrait fidèle des données, pas un lieu d'ordres données à la volée.

```jsx
function Séance({ heure, titre, intervenant }) {
  return (
    <li className="seance">
      <strong>{heure}</strong> — {titre}
      <span> {intervenant}</span>
    </li>
  );
}

function Programme({ titre, seances }) {
  return (
    <section>
      <h2>{titre}</h2>
      <ul>
        {seances.map((seance) => (
          <Séance
            key={seance.id}
            heure={seance.heure}
            titre={seance.titre}
            intervenant={seance.intervenant}
          />
        ))}
      </ul>
    </section>
  );
}
```

Cette définition permet une distinction fondamentale entre deux notions que l'on confond souvent. Un composant est une description, une recette, un modèle écrit une seule fois dans le fichier. Une instance est l'un de ses emplois concrets à l'écran. Le même composant Séance peut apparaître cinq fois dans la page, avec cinq jeux de données différents ; chaque apparition reçoit ses propres propriétés et, s'il en possède, son propre état. Quand vous modifiez la fonction, toutes les instances se mettent à jour ensemble, parce qu'elles ne sont que cinq lectures de la même recette.

L'organisation d'un projet React suit une pente naturelle issue de cette définition : un composant par fichier, le nom du fichier reprenant le nom du composant, et un export nommé ou par défaut qui rend le composant accessible aux autres fichiers. Cette convention n'a rien d'obligatoire, mais elle transforme la navigation dans le code : chercher Bandeau revient à chercher le fichier bandeau.jsx. Elle facilite aussi le travail en équipe, puisque deux personnes peuvent modifier deux composants différents sans jamais ouvrir les mêmes fichiers.

Enfin, retenez que les composants s'imbriquent pour former un arbre. L'application est la racine, ses enfants sont les grandes régions, et chacune de ces régions a ses propres enfants. Cet arbre n'est pas qu'une métaphore : il décrit à la fois la structure de l'écran, le chemin emprunté par les données, qui descendent toujours, et le chemin empronté par les événements, qui remontent. Toute la suite du chapitre se lit à la lumière de cette image.

- Un composant est une fonction JavaScript qui renvoie du JSX.
- Le nom d'un composant commence par une majuscule, ce qui le distingue d'une balise.
- Une instance est un emploi concret du composant ; le fichier n'en décrit qu'un seul modèle.
- React appelle la fonction à chaque mise à jour et n'applique que la différence.
- Un composant doit décrire les données qu'on lui donne, pas modifier l'écran lui-même.
- Un fichier par composant, nommé d'après lui, rend le projet navigable.
- Les composants imbriqués forment un arbre : données vers le bas, événements vers le haut.
$lesson$),
  ('web-c6-p4', 'web-c6', 4, $lesson$Props : les données en entrée$lesson$, $lesson$
Si un composant est une fonction, ses données d'entrée sont ses paramètres. En React, ces paramètres sont rassemblés dans un objet unique appelé propriétés, ou props dans le vocabulaire courant. On les transmet en écrivant le nom de la propriété suivi d'un signe égal et d'une valeur, exactement comme on écrit un attribut dans une balise, mais avec des accolades dès que la valeur est dynamique. Le composant reçoit l'objet complet et lit ce dont il a besoin.

```jsx
function CarteEvenement({ titre, date, lieu, places }) {
  const complet = places <= 0;

  return (
    <article className="carte">
      <h3>{titre}</h3>
      <p>{date} — {lieu}</p>
      <p>{complet ? "Complet" : places + " places disponibles"}</p>
    </article>
  );
}

function Application() {
  return (
    <CarteEvenement
      titre="Atelier React"
      date="Samedi 18 octobre, 14 h"
      lieu="Salle 2, Médiathèque des Lilas"
      places={12}
    />
  );
}
```

La première règle des props, celle qui gouverne tout le reste, est qu'elles sont en lecture seule. Un composant reçoit ses données, les utilise pour fabriquer un rendu, mais ne les modifie jamais. Cette contrainte peut sembler restrictive, elle est en fait libératrice : puisque personne ne modifie les données en les traversant, vous pouvez lire n'importe quel composant et savoir qu'il n'altère rien de ce qu'il reçoit. Si une donnée doit changer, c'est l'état de celui qui possède cette donnée qui change, et la nouvelle valeur redescend par les props. On parle de flux descendant.

La décomposition d'objet, vue dans les chapitres précédents, est la forme habituelle de réception. Elle offre deux avantages : le nom de chaque paramètre devient explicite dans la signature, et l'ordre des propriétés à l'appel n'a plus aucune importance. C'est aussi le moment d'installer des valeurs par défaut, non pas avec un mécanisme particulier au JSX, mais avec la fonctionnalité native des paramètres de fonction : une propriété non fournie prend alors la valeur indiquée après le signe égal.

```jsx
function Séance({ heure, titre, intervenant = "Animateur de l'atelier" }) {
  return (
    <li>
      <b>{heure}</b> {titre} — {intervenant}
    </li>
  );
}

function Bandeau({ titre, children }) {
  return (
    <header className="bandeau">
      <h1>{titre}</h1>
      {children}
    </header>
  );
}

function Application() {
  return (
    <div>
      <Bandeau titre="Atelier du samedi">
        <p>Inscription obligatoire, entrée gratuite.</p>
        <nav>Accueil — Programme — Inscription</nav>
      </Bandeau>
      <Séance heure="14 h" titre="Composants et props" />
    </div>
  );
}
```

La propriété enfants mérite une section à part tant elle est centrale. Elle contient tout ce qui s'écrit entre la balise d'ouverture et la balise de fermeture du composant, sous forme de valeurs transmit à l'appel. Concrètement, elle transforme un composant en conteneur : Bandeau décrit l'ossature d'un en-tête, et chaque emploi de Bandeau décide du contenu qui ira dedans. C'est le mécanisme qui permet de réutiliser une structure sans la figer, et vous y reviendrez dans la section sur les composants réutilisables.

Les props ne se limitent pas au texte. Un nombre s'écrit entre accolades, un tableau ou un objet également, un booléen peut s'écrire par simple présence de l'attribut, et surtout une fonction peut être transmise comme n'importe quelle donnée. Cette dernière possibilité est ce qui permet à un composant enfant d'informer son parent qu'un événement s'est produit, sans jamais toucher aux données de ce parent : l'enfant appelle la fonction reçue, le parent décide de la suite. Vous verrez ce mécanisme en détail dans la section sur la remontée des événements.

Une habitude professionnelle, pour finir : nommez les props d'après ce qu'elles représentent dans le monde de l'application, pas d'après leur apparence. Une prop nommée couleurTexteGras oblige à changer le nom dès que le style évolue, alors que primaire ou secondaire décrit une intention qui traverse les changements de design. Quand un composant reçoit un nombre important de propriétés, c'est souvent le signe qu'il en fait trop et qu'il serait plus clair de le découper en deux composants plus petits, chacun avec un contrat de données lisible en une ligne.

- Les props sont l'objet des paramètres d'un composant, transmis à l'appel.
- Elles sont en lecture seule : on les utilise, on ne les modifie pas.
- Les données descendent : du parent vers l'enfant, jamais l'inverse.
- La décomposition d'objet rend l'ordre indifférent et le nom explicite.
- Les valeurs par défaut s'écrivent comme des paramètres de fonction.
- La propriété enfants accueille le contenu écrit entre les balises du composant.
- Une fonction transmise en prop permet à un enfant d'informer son parent.
$lesson$),
  ('web-c6-p5', 'web-c6', 5, $lesson$Décomposer une page en composants : l'exemple de l'atelier$lesson$, $lesson$
Le découpage n'est pas un geste arbitraire : c'est la transposition, en React, d'une compétence que vous possédez déjà. Dans le premier chapitre du parcours, vous avez appris à décrire une page avec header, nav, main, section, article, aside et footer. Chacune de ces régions désignait un rôle, une frontière visible, une partie que l'on pouvait nommer. La décomposition en composants demande exactement le même réflexe, avec une question supplémentaire : est-ce que cette région a des données qui lui sont propres, ou est-elle réutilisable ailleurs ? Si la réponse est oui à l'une des deux questions, elle mérite son composant.

Observons la page de l'atelier telle que vous l'avez écrite en HTML. Elle contient un bandeau d'identification, une zone de navigation, un article qui présente l'événement, une liste de séances, une fiche d'inscription avec un compteur de places, un encart d'informations pratiques et un pied de page. Chacun de ces blocs correspond à un composant parfaitement naturel. Le fil conducteur du découpage tient en trois questions à poser, dans cet ordre. Premièrement : quelles données ce bloc affiche-t-il ? Deuxièmement : est-ce que ces données changent au cours de la vie de la page ? Troisièmement : ce bloc apparaît-il plusieurs fois, ou pourrait-il apparaître dans un autre écran ?

```text
Application
|-- Bandeau
|-- Navigation
|-- Programme
|   |-- Séance (14 h)
|   |-- Séance (14 h 30)
|   +-- Séance (16 h 30)
|-- CarteInscription
|   +-- Bouton
+-- PiedDePage
```

Cet arbre, écrit en texte brut, est la première chose qu'il vaut la peine de produire avant d'ouvrir l'éditeur. Il fixe les noms, les hiérarchies et les frontières, et il vous évite la dérive la plus courante : commencer à coder un composant avant de savoir où il se loge. Notez que les feuilles, les séances, sont elles-mêmes des composants, et non des fragments de texte dupliqués. Notez aussi que la carte d'inscription contient un bouton, qui sera lui-même un composant réutilisé plus bas dans la page. Un bon arbre montre ces deux phénomènes : la répétition d'un même composant et son imbriquation dans un autre.

La deuxième étape consiste à faire l'inventaire des données, indépendamment de l'affichage. Listez ce qui est fixe, comme le titre de l'atelier, la date et le nom de la salle ; ce qui est variable, comme le nombre de places restantes ; et ce qui provient de l'utilisateur, comme les champs du formulaire d'inscription. Cette liste détermine immédiatement l'emplacement de chaque donnée. Les données fixes s'écrivent directement là où elles servent, ou mieux, dans un fichier de données que plusieurs composants importent. Les données variables deviennent de l'état, et l'état se place dans le composant le plus bas qui les utilise toutes. Les données saisies par l'utilisateur appartiennent au formulaire, jusqu'au moment où un autre composant en a besoin.

```jsx
function Application() {
  const seances = [
    { id: "s1", heure: "14 h", titre: "Composants et props" },
    { id: "s2", heure: "14 h 30", titre: "État et événements" },
    { id: "s3", heure: "16 h 30", titre: "Listes et conditions" },
  ];

  return (
    <div className="page">
      <Bandeau titre="Atelier React du samedi" />
      <Navigation liens={["Accueil", "Programme", "Inscription"]} />
      <main>
        <Programme titre="Programme de la journée" seances={seances} />
        <CarteInscription places={12} />
        <Encart titre="Informations pratiques" />
      </main>
      <PiedDePage />
    </div>
  );
}
```

Le composant Application ne contient aucune logique : il assemble. Il déclare le tableau de données, le transmet au composant Programme, et laisse chacun des enfants produire sa part d'écran. Cette séparation des rôles est précieuse. Le parent orchestre, les enfants décrivent. Si le titre de l'atelier change, une seule ligne bouge ; si la présentation d'une séance change, un seul fichier change. Si demain vous remplacez la carte d'inscription par un formulaire complet, aucun autre composant n'a à en savoir quoi que ce soit, à condition de respecter le contrat de props que vous avez défini.

Trois habitudes rendent ce travail durable. La première consiste à nommer les composants avant de les implémenter : si vous peinez à trouver un nom, c'est souvent que le bloc est trop large ou qu'il mélange deux responsabilités. La deuxième consiste à refuser les propriétés qui duplient une donnée : si le titre affiché dans le bandeau et le titre de la page sont la même information, elle n'existe qu'une fois et elle redescend par les props. La troisième consiste à garder les composants courts : un composant qui dépasse une centaine de lignes devient difficile à lire, et presque toujours, une extraction de sous-composant allège les deux fichiers qui en résultent.

- Décomposez d'abord en regions nommées, comme vous l'avez fait en HTML.
- Posez trois questions : quelles données, données fixes ou variables, réutilisable ou unique.
- Produisez l'arbre des composants avant d'écrire le moindre JSX.
- L'état vit dans le composant le plus bas qui utilise toutes ces données.
- Le parent assemble et transmet ; les enfants décrivent et n'imposent rien.
- Refusez toute prop qui duplique une donnée existante ailleurs.
- Un nom impossible à trouver annonce un découpage à revoir.
$lesson$),
  ('web-c6-p6', 'web-c6', 6, $lesson$État local avec useState$lesson$, $lesson$
Certaines données d'une interface bougent : un compteur décroît, un champ se remplit, un menu s'ouvre, un message d'erreur apparaît. En React, cette donnée qui vit et qui déclenche un affichage s'appelle l'état, et on le déclare avec une fonction nommée useState, fournie par la bibliothèque. Cette fonction s'appelle hook, ce qui se traduit par crochet : un point d'accrochage qui permet à une fonction de composant d'utiliser une capacité particulière de React, ici la mémoire persistante et la capacité de déclencher un rendu.

```jsx
import { useState } from "react";

function CarteInscription({ placesInitiales }) {
  const [restantes, setRestantes] = useState(placesInitiales);

  function retirer() {
    if (restantes > 0) {
      setRestantes(restantes - 1);
    }
  }

  function ajouter() {
    if (restantes < placesInitiales) {
      setRestantes(restantes + 1);
    }
  }

  return (
    <section className="inscription">
      <p>{restantes} places restantes</p>
      <button onClick={retirer}>Retirer une place</button>
      <button onClick={ajouter}>Remettre une place</button>
    </section>
  );
}
```

L'appel useState renvoie un tableau de deux éléments, et cette écriture en décomposition n'est pas un ornement : le premier élément est la valeur courante de l'état, le second est la fonction qui demande une nouvelle valeur. Le nom que vous donnez à ces deux éléments est libre, à condition qu'il décrive bien la donnée. On écrit couramment un nom singulier pour la valeur et le même nom précédé de l'impératif ou du verbe set pour le mutateur, par exemple compteur et setCompteur, ou bien ouvert et setOuvert.

Le fonctionnement de la fonction de mise à jour mérite d'être compris précisément, parce qu'il explique la moitié des bugs de débutant. Appeler setRestantes ne modifie pas la variable restantes devant vous : cette variable appartient au rendu en cours et reste figée. L'appel indique à React qu'une nouvelle valeur existe pour le prochain rendu, puis React relance la fonction du composant avec cette nouvelle valeur. C'est pourquoi la ligne suivante, dans la même fonction, lit encore l'ancienne valeur. Si vous appelez le mutateur deux fois dans la même exécution avec la même valeur de base, vous obtiendrez deux fois le même résultat, et non une double incrémentation.

Quand la nouvelle valeur dépend de l'ancienne, React propose une seconde écriture, dans laquelle vous recevez la valeur la plus récente et vous renvoyez la suivante. Cette forme est indispensable dès que deux mises à jour peuvent être enchaînées rapidement, par exemple lors d'un double-clic ou d'un événement répété.

```jsx
function CompteurClics() {
  const [clics, setClics] = useState(0);

  function doubler() {
    setClics((valeurPrecedente) => valeurPrecedente + 1);
    setClics((valeurPrecedente) => valeurPrecedente + 1);
  }

  return <button onClick={doubler}>{clics} clics</button>;
}
```

Quatre règles gouvernent l'usage de l'état, et il est préférable de les apprendre par cœur dès maintenant. Première règle : l'état appartient à l'instance du composant, pas au fichier ; si le même composant apparaît trois fois à l'écran, il possède trois états indépendants. Deuxième règle : on ne modifie jamais l'objet ou le tableau de l'état directement, on demande une nouvelle valeur, sinon React ne détecte aucun changement. Troisième règle : la déclaration de useState se fait toujours au début du corps du composant, jamais dans une condition ni dans une boucle, parce que l'ordre des appels doit rester identique à chaque rendu. Quatrième règle : l'état doit servir à décrire, pas à recopier ; si une valeur se déduit d'autres données, elle n'a pas besoin d'être un état, il suffit de la calculer dans le corps du composant.

Un cas d'école utile, parce qu'il revient dans presque chaque application : l'état vide. Le compteur des places peut atteindre zéro, et l'interface doit alors dire autre chose que zéro place restantes si vous le souhaitez, ou désactiver un bouton, ou afficher un message d'inscription close. Ce n'est pas une propriété du composant, c'est une conséquence de l'état, et on l'exprime avec une condition. Vous verrez dans la section consacrée aux éléments conditionnels plusieurs manières de l'écrire proprement ; l'important est d'ores et déjà le principe : l'état change, le rendu change avec lui, sans aucune instruction d'actualisation écrite à la main.

- useState déclare une donnée qui déclenche un rendu quand elle change.
- Il renvoie un couple valeur et fonction de mise à jour, par décomposition.
- Appeler le mutateur ne change pas la variable courante, elle prépare le prochain rendu.
- Pour une mise à jour dépendante de la précédente, utilisez la forme fonctionnelle.
- L'état est propre à chaque instance du composant.
- Ne modifiez jamais directement l'objet ou le tableau stocké dans l'état.
- Déclarez l'état toujours au même endroit, en haut du corps du composant.
$lesson$),
  ('web-c6-p7', 'web-c6', 7, $lesson$État contre props et remontée des événements$lesson$, $lesson$
Vous savez faire descendre des données et vous savez déclencher une mise à jour. La question qui se pose maintenant est celle de la frontière : quelle donnée doit être une prop et quelle donnée doit être un état ? La confusion est fréquente, et une distinction nette évite la majorité des architectures bancales.

| Critère | Propriétés transmises | État local déclaré |
| --- | --- | --- |
| Propriétaire | le parent, qui les fournit | le composant lui-même, qui les déclare |
| Mutabilité | lecture seule pour l'enfant | modifiable par l'enfant avec son mutateur |
| Durée de vie | aussi longtemps que le parent les fournit | conservé entre deux rendus du composant |
| Portée | visible par l'enfant qui les reçoit | invisible du reste de l'arbre |
| Cas d'usage | titre, date, tableau de séances, rappel d'action | compteur de places, champ en cours de saisie, ouverture d'un menu |
| Source de vérité | une, chez le parent | une, dans le composant qui la déclare |

La règle tient en une phrase : les propriétés descendent, les événements remontent. Un enfant reçoit ce dont il a besoin pour peindre son écran, et informe son parent quand quelque chose se passe, sans jamais toucher aux données de ce parent. Si l'enfant avait laissé son état à zéro alors que le parent croyait à douze, vous auriez deux vérités concurrentes, c'est-à-dire exactement le problème que React était censé résoudre.

```jsx
function CarteInscription({ restantes, placesTotales, onRetirer, onAjouter }) {
  const complet = restantes <= 0;

  return (
    <section>
      <p>{complet ? "Atelier complet" : restantes + " places restantes"}</p>
      <Bouton libelle="Retirer une place" desactive={complet} onClick={onRetirer} />
      <Bouton libelle="Remettre une place" onClick={onAjouter} />
      <p>Total ouvert : {placesTotales} places</p>
    </section>
  );
}

function Application() {
  const [restantes, setRestantes] = useState(12);
  const placesTotales = 12;

  function retirer() {
    setRestantes((valeur) => (valeur > 0 ? valeur - 1 : 0));
  }

  function ajouter() {
    setRestantes((valeur) => (valeur < placesTotales ? valeur + 1 : valeur));
  }

  return (
    <CarteInscription
      restantes={restantes}
      placesTotales={placesTotales}
      onRetirer={retirer}
      onAjouter={ajouter}
    />
  );
}
```

Le composant Application possède l'état parce qu'il est l'ancêtre commun de tout ce qui en a besoin : la carte affiche le nombre, le bouton doit être désactivé quand le compteur arrive à zéro, et un futur encart de récapitulatif demandera le même chiffre. On dit que l'état a été remonté. Ce mouvement, la remontée d'état, n'est pas un arrangement d'urgence : c'est la conséquence logique du flux descendant. Quand deux composants frères doivent connaître la même donnée variable, cette donnée monte jusqu'à leur ancêtre commun, et redescend vers chacun sous forme de propriétés.

La conséquence la plus utile de ce principe est la suivante : ne copiez jamais l'état dans des propriétés. Une valeur qui se déduit de l'état, comme le pourcentage de places prises ou le libellé complet ou complet, se calcule dans le corps du composant, à chaque rendu, avec une simple constante. Créer un second état pour la recopier, puis penser à le synchroniser à chaque mise à jour, c'est réintroduire manuellement la double source de vérité que l'on essaie précisément d'éviter.

Les rappels d'action, ces fonctions transmises en propriétés, suivent une convention de nommage qui vaut la peine d'être installée tout de suite. On les nomme avec la préposition on suivie du verbe qui correspond à l'événement : onValider, onSupprimer, onChanger. Ce nom se lit comme une intention depuis le point de vue de l'enfant : le parent m'a dit de le valider. À l'intérieur, la fonction reçue est simplement appelée, sans arguments si l'enfant n'a rien à préciser, ou avec des informations utiles comme la valeur d'un champ. L'enfant ignore comment le parent traite l'information : il l'annonce, c'est tout.

Une dernière précision sur la profondeur. Remonter l'état a un coût de lisibilité si l'on s'y prend au hasard : plus les propriétés transitent loin, plus la liste des attributs s'allonge, et plus il devient difficile de suivre une donnée. Le réflexe professionnel consiste à déclarer l'état au point le plus bas qui regroupe tous les utilisateurs concernés, et à ne pas hésiter à remonter d'un cran quand un nouveau composant réclame la même information. Le découpage idéal tient dans un équilibre : assez haut pour que la donnée soit unique, assez bas pour que la transmission reste courte.

- Les propriétés descendent, les événements remontent : c'est tout le contrat.
- L'état vit dans l'ancêtre commun de tous les composants qui en ont besoin.
- On ne recopie jamais une donnée dérivée dans un second état.
- Une fonction reçue en propriété et appelée par l'enfant informe le parent sans le modifier.
- Nommez les rappels avec la préposition on suivie du verbe d'action.
- L'enfant ignore comment le parent utilise l'information qu'il lui transmet.
- Déclarez l'état au point le plus bas qui regroupe ses utilisateurs.
$lesson$),
  ('web-c6-p8', 'web-c6', 8, $lesson$Rendus, clés et listes$lesson$, $lesson$
La plupart des interfaces réelles sont des listes : un programme de séances, une galerie, un panier, un journal d'activités. En JSX, une liste s'obtient en transformant un tableau de données en un tableau d'éléments avec la méthode map, qui retourne un nouvel tableau sans modifier l'original. Chaque entrée devient un composant, et le JSX se contente d'insérer le résultat entre accolades.

```jsx
function Programme({ seances }) {
  return (
    <section>
      <h2>Programme de la journée</h2>
      <ul>
        {seances.map((seance) => (
          <li key={seance.id} className="seance">
            <b>{seance.heure}</b> — {seance.titre}
          </li>
        ))}
      </ul>
    </section>
  );
}

const seances = [
  { id: "s1", heure: "14 h", titre: "Composants et props" },
  { id: "s2", heure: "14 h 30", titre: "État et événements" },
  { id: "s3", heure: "16 h 30", titre: "Listes et conditions" },
];
```

La propriété key attire l'attention dès le premier énoncé de liste, et elle n'est pas décorative. Quand une liste change, React doit associer chaque élément du nouveau rendu avec celui du rendu précédent, exactement comme on met à jour un tableau en conservant les lignes existantes. La clé est cette identité. Sans elle, React se fie à la position : la première ligne de l'ancien rendu correspond à la première du nouveau. Cela fonctionne tant que l'ordre ne bouge jamais, et provoque des comportements étranges dès qu'on insère, supprime ou réordonne, parce que l'état local de chaque ligne suit la position et non la donnée.

Le choix d'une clé suit deux règles simples. Première règle : la clé doit être stable, unique et idéale à la source des données, l'identifiant de la séance par exemple, un identifiant de base de données ou une référence. Deuxième règle : l'index du tableau, obtenu avec le deuxième paramètre de map, n'est acceptable que pour une liste strictement statique qui ne sera jamais réordonnée ni filtrée. Si vous filtrez une liste de séances en supprimant la deuxième entrée, chaque clé d'index désignera désormais une séance différente, et React conservera l'état visuel de l'ancienne entrée sur la nouvelle.

```jsx
function Programme({ seances, onSupprimer }) {
  if (seances.length === 0) {
    return <p>Aucune séance programmée pour l'instant.</p>;
  }

  return (
    <ul>
      {seances.map((seance, position) => (
        <li key={seance.id}>
          {seance.heure} — {seance.titre}
          <button onClick={() => onSupprimer(seance.id)}>
            Retirer la séance n° {position + 1}
          </button>
        </li>
      ))}
    </ul>
  );
}
```

La clé n'optimise rien : elle identifie. C'est une confusion répandue de croire qu'ajouter des clés accélère l'affichage. Ce qu'elle garantit, c'est la cohérence entre données et écran, et surtout la conservation de l'état local de chaque élément, ce qui devient critique dès qu'une ligne contient un champ de saisie, un menu ouvert ou une case cochée.

Il reste une habitude d'écriture à prendre, celle de ne jamais muter le tableau de l'état. Pour ajouter une séance, vous créez un nouveau tableau qui contient l'ancien plus la nouvelle entrée ; pour en retirer une, vous filtrez. La méthode push à l'intérieur du tableau d'état modifie bien le même objet, mais React compare par référence : elle verrait le même tableau et ne déclencherait aucun rendu. La création d'un nouveau tableau n'est donc pas un gaspillage, c'est le signal même du changement.

- Transformez les données en éléments avec map, puis insérez le tableau entre accolades.
- La clé identifie une entrée entre deux rendus ; elle ne sert pas à l'affichage.
- Préférez toujours l'identifiant fourni par la donnée à la position dans le tableau.
- L'index n'est toléré que pour une liste qui ne sera jamais filtrée ni réordonnée.
- Une liste vide se traite par une condition placée avant le retour, avec un message explicite.
- Ne modifiez jamais le tableau de l'état : créez-en un nouveau à chaque mise à jour.
- Ajouter ou retirer une entrée se fait par concatenation ou filtrage, jamais par push.
$lesson$),
  ('web-c6-p9', 'web-c6', 9, $lesson$Éléments conditionnels$lesson$, $lesson$
Une interface change de forme selon la situation : un bouton se désactive quand plus rien n'est disponible, un message remplace une liste vide, un formulaire affiche ses erreurs une fois validé. Le JSX ne contient pas de structure conditionnelle, parce qu'il n'est qu'une expression : on ne peut pas écrire une instruction de condition à l'intérieur d'une description. La condition s'écrit donc en dehors, ou avec les opérateurs de forme expression que JavaScript fournit déjà.

```jsx
function CarteInscription({ restantes, ouvert }) {
  const complet = restantes <= 0;

  if (!ouvert) {
    return <p>Les inscriptions sont closes.</p>;
  }

  return (
    <section>
      <h2>Inscription</h2>
      {complet ? (
        <p>L'atelier est complet, inscrivez-vous à la liste d'attente.</p>
      ) : (
        <p>{restantes} places encore disponibles.</p>
      )}
      <button disabled={complet}>Confirmer ma place</button>
      {!complet && <a href="#form">Aller au formulaire</a>}
    </section>
  );
}
```

Trois formes se partagent l'essentiel des usages. L'opérateur ternaire convient quand il y a deux branches alternatives, une à afficher et l'autre non, et il a l'avantage d'être une expression complète, ce qui permet de l'utiliser directement à l'intérieur du JSX. L'opérateur logique de conjonction convient pour un rendu facultatif : si la condition est vraie, on affiche le bloc, sinon rien n'est rendu du tout. Enfin, la sortie anticipée, placée avant le mot return, convient aux cas où toute une branche de l'interface n'a aucun sens tant qu'une condition n'est pas remplie, par exemple un formulaire d'inscription quand les inscriptions sont closes.

Le piège le plus classique de la conjonction concerne les valeurs numériques. L'opérateur logique renvoie l'une de ses deux valeurs, pas forcément un booléen : si la condition est fausse, il renvoie l'opérande de droite, et si elle est vraie, l'opérande de gauche. Quand vous écrivez une expression qui peut valoir zéro, le JSX affichera réellement ce zéro à l'écran, parce que zéro est une valeur rendable. La parade consiste soit à faire précéder la valeur d'une opération de comparaison, soit à envelopper le tout dans un ternaire avec une branche vide.

```jsx
function ListeSeances({ seances }) {
  const vide = seances.length === 0;

  return (
    <div>
      {vide && <p>Aucune séance pour le moment.</p>}

      {!vide && (
        <ul>
          {seances.map((seance) => (
            <li key={seance.id}>{seance.titre}</li>
          ))}
        </ul>
      )}

      {seances.length > 0 ? (
        <p>{seances.length} séances au programme</p>
      ) : null}
    </div>
  );
}
```

Au-delà de la syntaxe, une discipline rend le code plus lisible. Déplacez les conditions un peu longues juste avant le return, dans des constantes nommées qui racontent l'intention : complet, inscriptionsOuvertes, aucuneInscription. Le JSX reste alors court et se lit comme une phrase, tandis que la logique se lit en haut, là où on l'attend. Une condition qui commence à faire plusieurs lignes à l'intérieur du JSX est presque toujours le signal de l'extraire.

- Toute condition est une expression : pas d'instruction de condition dans le JSX.
- Le ternaire gère deux branches ; la conjonction gère un bloc facultatif.
- La sortie anticipée convient quand une branche entière n'a aucun sens.
- Attention aux valeurs numériques : zéro s'affiche réellement si on le rend.
- Nommez les conditions dans des constantes placées avant le retour.
- Une condition trop longue se déplace hors du JSX, pour rester testable.
- Alternez message de vide et liste pour que chaque état soit explicite.
$lesson$),
  ('web-c6-p10', 'web-c6', 10, $lesson$Événements React$lesson$, $lesson$
Un bouton qui ne fait rien est un rectangle. Toute la valeur interactive d'une interface vient des événements : clic, frappe, soumission, survol. Le JSX attache un gestionnaire à une balise en utilisant un nom d'attribut en casse de chameau, préfixé par on suivi du nom de l'événement. Cette convention est la même partout dans la bibliothèque, ce qui rend la lecture d'un composant immédiatement prévisible : en voyant onClick, vous savez qu'un clic est attendu ; en voyant onChange, vous savez qu'une saisie est observée.

```jsx
function FormulaireInscription({ places, onInscrire }) {
  const [nom, setNom] = useState("");
  const [courriel, setCourriel] = useState("");
  const [erreur, setErreur] = useState("");

  function envoyer(evenement) {
    evenement.preventDefault();
    if (nom.trim() === "" || !courriel.includes("@")) {
      setErreur("Renseignez un nom et une adresse électronique valides.");
      return;
    }
    setErreur("");
    onInscrire({ nom, courriel });
    setNom("");
    setCourriel("");
  }

  return (
    <form onSubmit={envoyer}>
      <label htmlFor="nom">Nom complet</label>
      <input id="nom" value={nom} onChange={(e) => setNom(e.target.value)} />

      <label htmlFor="courriel">Adresse électronique</label>
      <input
        id="courriel"
        value={courriel}
        onChange={(e) => setCourriel(e.target.value)}
      />

      {erreur && <p role="alert">{erreur}</p>}
      <button type="submit" disabled={places <= 0}>
        Confirmer ma place
      </button>
    </form>
  );
}
```

Trois règles d'écriture gouvernent ce type de code. La première, et la plus fréquente à enfreindre, concerne la référence à la fonction : on transmet le nom du gestionnaire, sans parenthèses. Écrire le nom suivi de parenthèses revient à appeler la fonction pendant le rendu et à passer son résultat comme gestionnaire, ce qui déclenche l'action à l'affichage au lieu de l'attendre. Quand la fonction doit recevoir un argument, on enveloppe l'appel dans une fonction fléchée, qui sera appelée à son tour au bon moment.

La deuxième règle concerne l'objet événement. React normalise les différences entre navigateurs et vous fournit un objet unique avec les informations utiles : la cible qui a déclenché, la valeur courante d'un champ, la méthode qui empêche le comportement par défaut. Dans le formulaire ci-dessus, preventDefault évite le rechargement de la page à la soumission, exactement comme vous le faisiez en JavaScript classique, à cette différence près que la soumission est annoncée par un attribut onSubmit et non par un écouteur branché après coup.

La troisième règle concerne les champs contrôlés. Un champ contrôlé puise sa valeur dans l'état : value vient de l'état, onChange écrit dans l'état. L'avantage est la source unique de vérité déjà évoquée, et un bénéfice pratique immédiat : vous pouvez à tout moment lire, valider, formater ou limiter la saisie, puisque la valeur réelle du champ est dans une variable, pas dans le document. L'inverse existe, un champ non contrôlé qui lit le DOM au moment de la soumission, mais il perd cet avantage et se justifie seulement pour des formulaires très simples.

Les gestionnaires en ligne sont acceptés et même pratiques quand ils doivent recevoir des données de contexte, comme l'identifiant de la ligne qu'on retire. Gardez-les courts : une expression d'un seul appel se lit bien sur place, plusieurs lignes de logique se nomment en haut du composant et se transmettent par référence. Le critère de décision tient en une question : est-ce que ce gestionnaire sert à un seul endroit ? S'il ne sert qu'à un seul appel, il peut vivre sur place ; s'il porte une logique réutilisable ou testable, il mérite son nom.

- Les gestionnaires s'écrivent en casse de chameau, avec le préfixe `on`.
- Transmettez la fonction par référence, sans parenthèses.
- Pour passer un argument, enveloppez l'appel dans une fonction fléchée.
- Appelez preventDefault dans un gestionnaire de soumission de formulaire.
- Un champ contrôlé lit son value dans l'état et écrit avec onChange.
- L'objet événement normalisé donne la cible et la valeur courante.
- Nommez les gestionnaires qui portent une logique, gardez en ligne l'essentiel.
$lesson$),
  ('web-c6-p11', 'web-c6', 11, $lesson$Un composant qui se réutilise : bouton, carte, formulaire$lesson$, $lesson$
La promesse de React tient dans ce chapitre : écrire une fois, employer plusieurs fois. Un composant réutilisable n'est pas un composant complexe, c'est un composant dont le contrat de données est assez net pour survivre à des contextes différents. Le bouton est l'exemple le plus pédagogique parce qu'il paraît trivial, jusqu'au moment où l'on en crée le sixième et où l'on copie-colle pour la sixième fois la même classe, le même état désactivé et le même gestionnaire.

```jsx
function Bouton({ libelle, variante = "primaire", desactive = false, onClick }) {
  const classe = "bouton bouton-" + variante;

  return (
    <button className={classe} disabled={desactive} onClick={onClick} type="button">
      {libelle}
    </button>
  );
}

function CarteInscription({ restantes, onRetirer, onAjouter }) {
  const complet = restantes <= 0;

  return (
    <article className="carte-inscription">
      <h2>Inscription à l'atelier</h2>
      {complet ? <p>L'atelier est complet.</p> : <p>{restantes} places restantes</p>}
      <Bouton libelle="Retirer une place" desactive={complet} onClick={onRetirer} />
      <Bouton libelle="Remettre une place" variante="secondaire" onClick={onAjouter} />
    </article>
  );
}
```

Trois décisions de conception méritent d'être commentées. D'abord, les valeurs par défaut : le bouton a une variante et un état désactivé qui prennent des valeurs raisonnables, de sorte que l'appel le plus fréquent reste bref. Ensuite, la responsabilité unique : le composant Bouton ne sait rien de l'atelier, des places ni des inscriptions ; il sait afficher un bouton stylé, désactivé si on le lui demande, et annoncer un clic. Cette ignorance volontaire est ce qui lui permettra de servir dans la navigation, dans le formulaire et dans l'encart de récapitulatif. Enfin, le nom du rappel reçu : onClick est un contrat général, pas un nom propre à un écran.

Quand la configuration se multiplie, le JSX ouvre une porte que la configuration ne donne pas : la composition. Plutôt que d'ajouter des propriétés pour décrire des variantes de contenu, on laisse le contenu être transmis. La propriété enfants, déjà rencontrée, en est la forme la plus simple, et un nommage explicite, pour des emplacements multiples, en est la variante avancée.

```jsx
function Carte({ titre, children, actions }) {
  return (
    <article className="carte">
      <h3>{titre}</h3>
      <div className="carte-contenu">{children}</div>
      <div className="carte-actions">{actions}</div>
    </article>
  );
}

function Page({ children }) {
  return (
    <div className="page">
      <Bandeau titre="Atelier de la Médiathèque des Lilas" />
      <main>{children}</main>
      <PiedDePage />
    </div>
  );
}

function Application() {
  return (
    <Page>
      <Carte
        titre="Informations pratiques"
        actions={<Bouton libelle="Voir le plan" variante="secondaire" />}
      >
        <p>Samedi 18 octobre, de 14 h à 17 h, salle 2.</p>
        <p>Entrée gratuite, sur inscription.</p>
      </Carte>
    </Page>
  );
}
```

Le composant Carte décrit une structure répétée, avec un titre, un corps et une zone d'actions, et laisse à chaque emploi le soin de remplir ces emplacements. Le composant Page impose l'ossature commune de l'écran, bandeau et pied de page, et accepte n'importe quel contenu pour sa partie centrale : la page d'accueil, la page de programme et la page de résultat passeront toutes par là sans dupliquer la structure. Ces deux exemples illustrent une règle de conception devenue classique : préférez la composition à la configuration quand une propriété ne ferait que choisir parmi des variantes de structure.

Un avertissement, toutefois, contre l'excès inverse. Un composant qui accepte quinze propriétés, dont certaines ne servent que rarement, devient plus coûteux à comprendre qu'à coder. Le test est simple : décrivez le contrat à voix haute. Si la phrase contient plusieurs et, ou des tournures du type sauf quand, le composant mélange probablement deux responsabilités. Un formulaire réutilisable, par exemple, doit recevoir des champs et un rappel de soumission, pas la logique métier de validation d'un atelier précis.

- Un composant réutilisable ignore le contexte dans lequel on l'emploie.
- Les valeurs par défaut rendent l'appel courant aussi bref que possible.
- La responsabilité unique se vérifie en décrivant le contrat à voix haute.
- La propriété enfants transforme un composant en conteneur générique.
- Des emplacements nommés conviennent aux structures à plusieurs zones.
- Préférez la composition à la configuration pour les variantes de structure.
- Refusez les composants à quinze propriétés : découpez-les en deux.
$lesson$),
  ('web-c6-p12', 'web-c6', 12, $lesson$Composer et imbriquer : l'arbre de composants$lesson$, $lesson$
Vous avez désormais tous les gestes : un composant, des propriétés, un état, des événements, des listes et des conditions. La question qui reste est celle de l'assemblage, et elle se résout en observant la forme de votre application comme un arbre, avec à chaque nœud une règle de circulation. Les données descendent d'un nœud vers ses enfants, les événements remontent d'un nœud vers son parent, et personne ne saute d'une branche à l'autre sans passer par l'ancêtre commun.

```jsx
function Application() {
  const [restantes, setRestantes] = useState(12);
  const [seances, setSeances] = useState(SEANCES);

  function retirer() {
    setRestantes((v) => (v > 0 ? v - 1 : 0));
  }

  function ajouter() {
    setRestantes((v) => Math.min(v + 1, 12));
  }

  function retirerSeance(id) {
    setSeances((liste) => liste.filter((seance) => seance.id !== id));
  }

  return (
    <Page>
      <Programme seances={seances} onSupprimer={retirerSeance} />
      <CarteInscription restantes={restantes} onRetirer={retirer} onAjouter={ajouter} />
      <EncartRestantes restantes={restantes} />
    </Page>
  );
}
```

Dans cet arbre, l'état des places est déclaré au plus haut niveau parce que trois composants différents en dépendent : la carte qui l'affiche, le bouton qui doit se désactiver, l'encart qui le rappelle. Aucun de ces trois n'a besoin de posséder la donnée, et aucun ne doit la recopier. Le même raisonnement s'applique à la liste des séances : elle est nécessaire au programme et au compteur de séances affiché sous la liste, donc elle remonte au composant qui les deux contient. On déplace une donnée vers le haut chaque fois qu'un deuxième consommateur apparaît, et on la redescend vers le bas chaque fois qu'un seul composant en est responsable.

Le second apprentissage de cette section est la manière de découper un grand écran en pages composées. Plutôt que de dupliquer le bandeau et le pied de page dans chaque écran, on crée un composant de mise en page qui les contient une fois, et on lui transmet le contenu variable par la propriété enfants. C'est exactement le rôle du composant Page vu dans la section précédente. Ce patron se généralise : un conteneur de mise en page, des conteneurs de section, puis des composants de contenu, chacun ne connaissant que son niveau.

Trois signes indiquent qu'un découpage mérite d'être revu. Le premier est une liste de propriétés qui s'allonge sans fin entre deux composants : la donnée circule, mais lisible elle ne l'est plus, et il vaut mieux déplacer le composant qui les reçoit vers le haut. Le deuxième est un composant qui reçoit une fonction et la transmet tel quel à un enfant, sans rien y ajouter : c'est un tuyau inutile, le composant intermédiaire peut être supprimé. Le troisième est un fichier qui contient deux régions visibles distinctes : presque toujours, une extraction en deux composants rend les deux plus courts et plus faciles à tester.

```text
Page
|-- Bandeau
|-- main
|   |-- Programme
|   |   +-- Séance (répété n fois)
|   |-- CarteInscription
|   |   +-- Bouton (répété deux fois)
|   +-- EncartRestantes
+-- PiedDePage
```

Cet arbre final se lit comme le plan d'une maison. Chaque ligne est une pièce, chaque indentation est une porte. Quand vous reviendrez sur le projet dans trois semaines, ce schéma, que vous pouvez noter dans un commentaire en tête de fichier, vous rendra la main bien plus vite que la lecture du code complet.

- Les données descendent, les événements remontent, personne ne saute de branche.
- Une donnée consommée par plusieurs frères est déclarée chez leur ancêtre commun.
- Un composant de mise en page reçoit la variable par la propriété enfants.
- Un composant qui ne fait que relayer des propriétés est supprimable.
- Deux régions visibles dans un même fichier annoncent un découpage à faire.
- Notez l'arbre des composants en tête de fichier : il reste lisible des mois durant.
$lesson$),
  ('web-c6-p13', 'web-c6', 13, $lesson$Mini-projet guidé : refaire l'atelier en composants$lesson$, $lesson$
Il est temps d'assembler toutes les pièces. Le projet reprend la page de l'atelier que vous avez construite en HTML, en CSS et en JavaScript dans les chapitres précédents, mais réécrite en composants React. Les données sont les mêmes : le titre de l'atelier, la date, le lieu, trois séances au programme, un compteur de places et un pied de page. Ce qui change, c'est la façon de les traiter : plus une ligne de manipulation du document, seulement des composants, des propriétés et un état.

La première étape est un travail d'écriture, pas de code : reprenez l'arbre du début du chapitre et listez les données à côté de chaque feuille. Le titre et la date sont fixes ; le tableau des séances est fixe ici, mais il peut être animé plus tard ; le nombre de places est variable et modifiable par l'utilisateur ; les liens de navigation sont fixes. Cette colonne de données est le cahier des charges de votre application, et chaque ligne deviendra soit une constante, soit une propriété, soit un état.

```jsx
const SEANCES = [
  { id: "s1", heure: "14 h", titre: "Composants et props" },
  { id: "s2", heure: "14 h 30", titre: "État et événements" },
  { id: "s3", heure: "16 h 30", titre: "Listes et conditions" },
];

function Bandeau({ titre, sousTitre }) {
  return (
    <header className="bandeau">
      <h1>{titre}</h1>
      <p>{sousTitre}</p>
    </header>
  );
}

function Programme({ seances }) {
  if (seances.length === 0) {
    return (
      <section>
        <h2>Programme</h2>
        <p>Le programme sera publié prochainement.</p>
      </section>
    );
  }

  return (
    <section>
      <h2>Programme</h2>
      <ul>
        {seances.map((seance) => (
          <li key={seance.id}>
            <b>{seance.heure}</b> — {seance.titre}
          </li>
        ))}
      </ul>
    </section>
  );
}

function PiedDePage() {
  return <footer>© 2026 Médiathèque des Lilas</footer>;
}
```

La deuxième étape introduit l'état de l'application. La carte d'inscription possède le compteur des places, avec les deux boutons d'ajustement et la gestion du cas limite : quand le compteur arrive à zéro, le bouton de retrait se désactive et l'interface annonce que l'atelier est complet. Quand il remonte jusqu'à la jauge initiale, l'ajout se bloque. Ces deux garde-fous sont des conditions sur l'état, écrites une fois, appliquées à chaque rendu.

```jsx
function CarteInscription({ placesTotales }) {
  const [restantes, setRestantes] = useState(placesTotales);

  const complet = restantes <= 0;
  const plein = restantes >= placesTotales;

  function retirer() {
    if (restantes > 0) {
      setRestantes(restantes - 1);
    }
  }

  function ajouter() {
    if (restantes < placesTotales) {
      setRestantes(restantes + 1);
    }
  }

  return (
    <article className="carte-inscription">
      <h2>Inscription</h2>
      {complet ? (
        <p role="status">Atelier complet, liste d'attente ouverte.</p>
      ) : (
        <p>{restantes} places restantes sur {placesTotales}</p>
      )}

      <Bouton libelle="Retirer une place" desactive={complet} onClick={retirer} />
      <Bouton libelle="Ajouter une place" desactive={plein} onClick={ajouter} />
    </article>
  );
}
```

La troisième étape fournit le bouton réutilisable que ce composant appelle deux fois, puis l'assemblage final. Notez le rôle du composant Application : il ne contient aucune logique métier, seulement la déclaration des données et l'enchaînement des composants. C'est volontaire : l'endroit où l'on décide des valeurs n'est pas l'endroit où l'on décrit les écrans.

```jsx
function Bouton({ libelle, desactive = false, onClick }) {
  return (
    <button className="bouton" disabled={desactive} onClick={onClick} type="button">
      {libelle}
    </button>
  );
}

function Application() {
  return (
    <div className="page">
      <Bandeau
        titre="Atelier React du samedi"
        sousTitre="Médiathèque des Lilas — gratuit, sur inscription"
      />
      <main>
        <Programme seances={SEANCES} />
        <CarteInscription placesTotales={12} />
        <Encart titre="Informations pratiques" />
      </main>
      <PiedDePage />
    </div>
  );
}
```

Avant de considérer le projet comme terminé, exécutez la liste de contrôle suivante. Changez une donnée en haut de l'arbre et vérifiez qu'elle se répercute partout où elle est affichée. Retirez toutes les places jusqu'à zéro : le message de complet doit apparaître et le bouton doit se griser. Remettez douze : le blocage doit céder. Supprimez une séance du tableau et confirmez que les autres lignes restent stables et que la clé ne bouge pas. Remplacez le tableau des séances par un tableau vide et vérifiez que le message de programme à venir prend le relais sans erreur. Enfin, relisez chaque composant à part, en vous demandant quelles données il reçoit et ce qu'il annonce : si la réponse tient en une phrase, le découpage est bon.

- Listez les données avant d'écrire le moindre composant.
- Les valeurs fixes deviennent des constantes, les valeurs variables deviennent de l'état.
- Encadrez le compteur avec deux conditions : vide et complet.
- Le bouton réutilisable ignore tout de l'atelier, il affiche et il annonce.
- Application assemble et ne décide de rien d'autre que de l'assemblage.
- Testez les cas limites : zéro, maximum, liste vide, liste normale.
- Relisez chaque composant isolément et formulez son contrat en une phrase.
$lesson$),
  ('web-c6-p14', 'web-c6', 14, $lesson$À retenir$lesson$, $lesson$
- Un composant est une fonction JavaScript qui renvoie du `JSX`.
- Le nom d'un composant commence par une majuscule, ce qui le distingue d'une balise.
- Le `JSX` ressemble au `HTML` mais s'écrit dans du `JavaScript` et se transforme avant exécution.
- Les accolades ouvrent une expression ; sans elles, le texte s'affiche littéralement.
- Utilisez `className` et `htmlFor`, et fermez chaque balise vide avec une barre oblique.
- Les propriétés sont l'objet des paramètres d'un composant et elles sont en lecture seule.
- Les données descendent par les propriétés, les événements remontent par les fonctions reçues.
- La propriété enfants contient tout ce qui s'écrit entre les balises d'un composant.
- L'hook `useState` déclare l'état local et déclenche un rendu quand il change.
- Appeler un mutateur prépare le prochain rendu, il ne modifie pas la variable courante.
- Une mise à jour dépendante de la précédente s'écrit avec la forme fonctionnelle.
- L'état appartient à l'instance : trois emplois d'un composant signifient trois états.
- L'état partagé se déclare chez l'ancêtre commun et redescend sous forme de propriétés.
- On ne recopie jamais une valeur dérivée dans un second état.
- Une liste se construit avec `map`, et sa clé identifie une entrée entre deux rendus.
- La clé provient de la donnée, jamais de la position dans le tableau.
- Ne modifiez jamais le tableau ou l'objet de l'état : créez-en un nouveau.
- Les conditions sont des expressions : ternaire, conjonction ou sortie anticipée.
- Les gestionnaires s'écrivent en casse de chameau et se transmettent sans parenthèses.
- Un champ contrôlé lit sa valeur dans l'état et l'écrit avec `onChange`.
- Préférez la composition à la configuration quand une propriété décrit une structure.
$lesson$),
  ('web-c6-p15', 'web-c6', 15, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : écrire le nom d'un composant en minuscules et se demander pourquoi rien ne s'affiche → Correction : une majuscule initiale signale au JSX qu'il s'agit d'un composant et non d'une balise.
- Piège : oublier les accolades autour d'une expression, ou au contraire entourer un texte fixe → Correction : les accolades portent une valeur calculée, tout le reste est du texte affiché tel quel.
- Piège : modifier directement une propriété reçue en params → Correction : les propriétés sont en lecture seule ; demandez au parent une nouvelle valeur par un rappel.
- Piège : appeler un mutateur puis lire la variable dans la même fonction en s'attendant à la nouvelle valeur → Correction : la variable appartient au rendu courant ; utilisez la forme fonctionnelle pour enchaîner.
- Piège : déclarer useState dans une condition ou après un return → Correction : déclarez tous les états en tête de composant, dans le même ordre à chaque rendu.
- Piège : stocker dans l'état une valeur qui se déduit d'autres données → Correction : calculez-la dans le corps du composant, une simple constante suffit.
- Piège : donner la position comme clé dans une liste filtrée ou réordonnable → Correction : utilisez un identifiant stable de la donnée.
- Piège : pousser un élément dans le tableau de l'état et ne voir aucun changement → Correction : créez un nouveau tableau par concaténation ou filtrage.
- Piège : écrire des parenthèses après le nom d'un gestionnaire transmis → Correction : transmettez la référence, enveloppez l'appel dans une fonction fléchée si un argument est nécessaire.
- Piège : afficher zéro à l'écran avec une conjonction sur un compteur → Correction : utilisez un ternaire ou forcez la conversion en booléen avant de rendre.
- Piège : duplier une donnée variable dans deux composants frères → Correction : remontez l'état chez l'ancêtre commun et redescendez-le par les propriétés.
- Piège : construire une chaîne de caractères pour fabriquer du balisage → Correction : décrivez la structure en JSX, le contenu textuel est échappé automatiquement.
$lesson$),
  ('web-c6-p16', 'web-c6', 16, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation officielle de React est aujourd'hui la meilleure porte d'entrée, et elle se lit dans un ordre particulièrement bien pensé pour qui vient de terminer ce chapitre. Commencez par https://react.dev/learn, qui organise les notions autour d'articles courts et d'exemples exécutables : votre première composant, la lecture du JSX, la pensée par composants, puis la gestion de l'état. Chaque page se suffit à elle-même et contient un banc d'essai où l'on peut modifier le code en ligne, ce qui convient parfaitement à l'habitude que nous prônons depuis le début du parcours : changer une valeur et observer la conséquence. Revenez ensuite à https://react.dev/reference/react/useState pour la référence complète du hook que vous avez utilisé dans ce chapitre : y sont détaillées la forme fonctionnelle de mise à jour, l'initialisation paresseuse et les comportements de comparaison que l'on rencontre en pratique.

Un second bloc de lecture complète utilement le tableau. Les fonctions fléchées et la décomposition d'objets, largement employées dans tous les exemples, sont décrites avec précision sur https://developer.mozilla.org/docs/Web/JavaScript, la référence de Mozilla qui reste la plus fiable pour le langage lui-même. Le modèle du document objet, que React épargne d'écrire mais qu'il utilise en coulisses, se trouve sur https://developer.mozilla.org/docs/Web/API/Document_Object_Model : savoir comment un navigateur organise sa représentation d'une page vous aidera à comprendre ce que fait exactement React quand il met l'écran à jour. Prenez le temps de feuilleter ces pages plutôt que de les lire d'un bout à l'autre, et revenez-y au moment où une question précise se pose.
$lesson$),
  ('web-c6-p17', 'web-c6', 17, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
Vous disposez à présent du vocabulaire complet des fondations : découper une interface en composants nommés, faire descendre les données par les propriétés, faire remonter les événements par les rappels, déclarer un état local, afficher des listes avec des clés stables, alterner des contenus selon des conditions et écrire des composants réutilisables. L'exercice pratique qui suit cette leçon vous fait réécrire seul le site de l'atelier sous cette forme, en partant du squelette fourni et en respectant la consigne : le compteur de places doit être piloté par un état, les boutons d'ajustement doivent fonctionner dans les deux sens, et le cas d'un compteur vide doit être géré explicitement. Le quiz de quatre questions qui accompagne le chapitre vérifie en quelques minutes les notions qui reviennent le plus souvent.

Passé cet exercice, la suite du parcours attaque les cas qui font d'une démonstration une application : la navigation entre plusieurs écrans, les formulaires entièrement contrôlés et la récupération de données distantes avec fetch, que vous connaissez déjà et que vous remettrez au service de React. Vous constaterez alors que la discipline apprise ici, une source unique de vérité et un flux de données descendant, n'était pas une contrainte d'introduction mais le principe qui rend ces sujets avancés gérables. Conservez le fichier de l'atelier : vous le ferez évoluer à chaque chapitre restant, et la comparaison entre sa forme d'aujourd'hui et sa forme finale mesurera tout le chemin parcouru.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('web-c7-p1', 'web-c7', 1, $lesson$Structurer une application multi-pages$lesson$, $lesson$
Bienvenue dans le septième chapitre du parcours Développement web moderne, le chapitre où votre site de l'atelier cesse d'être une collection de fichiers pour devenir une véritable application. Jusqu'ici, chaque page que vous avez écrite vivait de manière indépendante : le navigateur demandait un fichier, recevait un document complet, l'affichait, puis l'oubliait dès que l'utilisateur cliquait sur un autre lien. Cette architecture, dite multi-pages, a fait ses preuves pendant vingt ans et reste parfaitement valide, mais elle impose un rechargement à chaque déplacement et perd systématiquement ce que l'utilisateur avait en cours. React propose une autre lecture du problème : un seul document reste chargé dans le navigateur, et c'est un routeur, une partie du code chargée de lire l'adresse, qui décide quel composant afficher à la place du précédent. L'URL ne désigne plus un fichier, elle désigne un écran. Cette inversion est le sujet du chapitre, et elle commande tout le reste : la navigation, les formulaires et le chargement des données distantes.

À la fin de cette leçon, vous saurez faire trois groupes de choses très concrètes, que vous aurez déjà manipulées dans du code complet. Vous saurez structurer une navigation avec un routeur : déclarer une table de routes, créer des liens qui ne rechargent pas la page, lire un paramètre d'URL, afficher une page 404, imbriquer des routes dans un composant de disposition commun et signaler le lien actif à la fois visuellement et pour les technologies d'assistance. Vous saurez lier un formulaire à l'état du composant : maintenir chaque saisie dans une variable d'état, la refléter dans le champ, valider une adresse électronique avant l'envoi, relier un message d'erreur au champ qui l'a provoqué, gérer les états envoyé, en erreur et confirmé, puis réinitialiser proprement. Vous saurez enfin charger des données au montage d'un composant avec useEffect : déclarer un effet qui se déclenche une fois, comprendre le tableau des dépendances, écrire la fonction asynchronesans provoquer de race condition, annuler un effet qui ne doit plus parler, et faire varier l'affichage entre chargement, erreur, liste vide et succès. Le tout sera rassemblé dans un mini-projet guidé : le formulaire d'inscription de l'atelier relié à la liste des inscrits.

La manière d'aborder ce chapitre mérite une recommandation, comme au début du premier. React s'apprend comme apprend tout le reste du parcours : en recopiant les exemples, en les cassant, en observant ce qui se passe. Rien ne remplace le geste d'ouvrir un éditeur, de coller un composant, d'enregistrer et de regarder le navigateur. Une route qui affiche une page vide n'est pas un échec, c'est une information : elle vous dit que le chemin déclaré et le chemin cliqué ne sont pas écrits de la même façon. Nous avancerons par étapes, en alternant explications, exemples commentés et mises en garde issues de pratique, et le fil rouge restera le même depuis le début du parcours : le site de l'atelier de la Médiathèque des Lilas. Chaque notion sera d'abord montrée dans un composant isolé, puis réutilisée dans le mini-projet de la fin, de sorte que vous puissiez le relire seul et comprendre chaque ligne.



Le premier réflexe, quand on quitte les pages statiques, consiste à garder la logique ancienne et à l'habiller de composants : un fichier par écran, un lien par fichier, et React qui s'exécute au milieu. Cela fonctionne, mais vous perdez l'essentiel, puisque le navigateur rechargera le document à chaque clic et repartira donc de zéro : le composant est démonté, l'état est effacé, la mémoire vidée. Une application React structurée inverse la hiérarchie. Le document HTML unique, celui que le serveur renvoie une seule fois, contient un point d'ancrage, généralement une balise d'ancrage avec un identifiant que le script occupera, et c'est un routeur, monté à cet endroit, qui reçoit la responsabilité d'afficher le bon composant en fonction de l'adresse courante. Le document n'est plus rechargé ; seuls les composants changent.

Cette différence se comprend mieux avec une image simple. Dans le modèle multi-pages, l'adresse postale désigne une maison : le facteur va d'une maison à l'autre, et chaque déplacement est un voyage. Dans le modèle applicatif, une seule maison est habitée en permanence, et l'adresse désigne la pièce où l'on se trouve : changer de pièce ne fait pas déménager. Concrètement, cela signifie que l'en-tête du site, la navigation, les préférences de l'utilisateur et les données déjà chargées survivent au déplacement. L'utilisateur peut revenir en arrière avec la touche dédiée, rafraîchir la page, copier l'adresse dans un message : dans les trois cas, il retrouve exactement le même écran, parce que l'adresse est restée la source de vérité. Une application qui décide de l'affichage sans passer par l'URL casse cette promesse et punit l'utilisateur dès qu'il partage un lien.

Le choix de l'adresse se fait en deux familles, et il faut trancher tôt parce qu'il conditionne le déploiement. La première famille écrit des chemins réels : slash programme, slash inscription. C'est la forme la plus propre, mais elle exige que le serveur soit configuré pour renvoyer, vers n'importe quel chemin inconnu, le même document de départ ; sans cette configuration, un rafraîchissement sur slash inscription renvoie une erreur quatre cent quatre. La deuxième famille écrit le chemin après une almohadille : almohadille slash programme. Le navigateur n'envoie rien au serveur au-delà du document principal, l'adresse est lue par le script, et le rafraîchissement fonctionne partout, y compris ouvert depuis un simple fichier local. Pour un projet sans outil de compilation, c'est cette seconde forme que nous utiliserons tout au long du chapitre.

```text
index.html  (chargé une seule fois)
  |
  +-- script: le routeur lit location.hash
  |
  +-- #/            -> page Accueil
  +-- #/programme   -> page Programme
  +-- #/inscription -> page Inscription (formulaire)
  +-- n'importe quoi d'autre -> page Introuvable
```

L'organisation des fichiers suit la même logique que les adresses. On crée un dossier pour les écrans, un dossier pour les composants partagés et un fichier unique pour la table des routes. Chaque écran devient un composant, chaque composant tient dans un fichier, et le nom du fichier ressemble au chemin qu'il sert : programme point jsx pour la route slash programme. Cette symétrie n'est pas une règle de la bibliothèque, c'est une règle de lisibilité : quand un bug se produit sur une adresse, votre recherche dans l'arborescence doit aboutir en une seconde. Évitez surtout le piège inverse, qui consiste à écrire un composant géant avec une condition par adresse : vous obtenez alors un fichier illisible qui reproduit ce que le routeur fait déjà pour vous.

La dernière décision de structure porte sur ce qui est commun à tous les écrans. Le bandeau, la navigation et le pied de page ne doivent pas être réécrits dans chaque page : ils sont déclarés une fois, dans un composant de disposition, et l'écran courant vient s'y insérer à un emplacement réservé. Le routeur matérialise cet emplacement avec un composant prévu à cet effet, souvent nommé Outlet, que vous placerez entre la navigation et le pied de page. Le résultat est exactement celui d'un gabarit de document : la structure ne bouge pas, seul le contenu central change. C'est ce qui rend la navigation instantanée : le navigateur ne reconstruit pas le bandeau, il le conserve et ne remplace qu'un sous-arbre.

- Une application React garde un seul document chargé ; le routeur choisit l'écran d'après l'URL.
- L'URL reste la source de vérité : rafraîchir, partager et revenir en arrière doivent donner le même écran.
- Le chemin après l'almohadille fonctionne sans serveur configuré ni outil de compilation.
- Un écran par fichier, un nom de fichier qui ressemble au chemin qu'il sert.
- Le bandeau, la navigation et le pied de page vivent dans un composant de disposition unique.
- L'emplacement réservé au contenu courant est marqué par le composant de gabarit du routeur.
$lesson$),
  ('web-c7-p2', 'web-c7', 2, $lesson$Le routeur : routes, liens, paramètres d'URL et page 404$lesson$, $lesson$
Un routeur se décrit comme une table : à gauche une adresse, à droite le composant à afficher. Vous la déclarez une fois, au sommet de l'application, puis vous n'y pensez plus. Les bibliothèques de routes de l'écosystème React se ressemblent toutes sur ce point : elles exposent un composant racine qui reçoit la table, un composant de lien qui ne déclenche aucun rechargement, et des fonctions de secours pour lire l'adresse courante. Attention à un détail de packaging qui embroule souvent les débutants : le nom du paquet dépend de la version. Les versions historiques s'importaient depuis un paquet dédié, tandis que les versions récentes regroupent tout dans un paquet unique. Vérifiez toujours le nom indiqué par la documentation officielle avant de coller un exemple trouvé ailleurs, car un import faux ne produit pas d'erreur pédagogique, seulement un écran blanc.

```jsx
import { Routes, Route, Link } from "react-router";
import Accueil from "./pages/Accueil";
import Programme from "./pages/Programme";
import Inscription from "./pages/Inscription";
import Introuvable from "./pages/Introuvable";

export default function Application() {
  return (
    <div>
      <nav>
        <Link to="/">Accueil</Link>
        <Link to="/programme">Programme</Link>
        <Link to="/inscription">Inscription</Link>
      </div>
      <main>
        <Routes>
          <Route path="/" element={<Accueil />} />
          <Route path="/programme" element={<Programme />} />
          <Route path="/inscription" element={<Inscription />} />
          <Route path="*" element={<Introuvable />} />
        </Routes>
      </main>
    </div>
  );
}
```

Trois éléments de ce tableau méritent d'être lus lentement. Le premier est la racine : le chemin slash désigne l'écran d'accueil, et il est obligatoire d'en déclarer un, sinon l'application s'ouvre sur une page vide. Le deuxième est le composant de lien. Contrairement à l'ancre classique, il ne demande pas au navigateur de charger un nouveau document ; il intercepte le clic, modifie l'adresse, déclenche le routeur et laisse le reste de la page intacte. Le troisième est la ligne réservée aux adresses inconnues : le chemin étoile attrape tout ce qui n'a pas été déclaré ailleurs et y affiche la page quatre cent quatre. Sans cette ligne, une faute de frappe dans l'adresse ne produit rien du tout, ni erreur ni écran, et l'utilisateur croit à une panne.

Les paramètres d'URL permettent d'aller plus loin : une route peut porter un segment variable, écrit avec deux-points suivi d'un nom, qui accepte n'importe quelle valeur. C'est le mécanisme des fiches individuelles, des profils ou des articles : l'adresse slash atelier slash deux points identifiant désigne la même page pour tous les identifiants, et c'est le composant qui lit la valeur pour charger la bonne fiche. La lecture se fait avec une fonction de secours fournie par le routeur, qui renvoie un objet contenant tous les paramètres de l'adresse courante. Cette séparation est essentielle : le routeur décide quel écran afficher, l'écran décide quoi faire du segment qu'on lui a donné.

```jsx
<Route path="/atelier/:identifiant" element={<FicheAtelier />} />

function FicheAtelier() {
  const { identifiant } = useParams();
  return <p>Fiche numéro : {identifiant}</p>;
}
```

L'adresse peut aussi porter une question, c'est-à-dire une suite de paires nom et valeur après le point d'interrogation. Les paramètres de chemin sont obligatoires et participent à l'identité de la ressource ; les paramètres de requête sont facultatifs et décrivent un réglage, comme une page, un tri ou un mot recherché. On les lit avec la même famille de fonctions, ou directement avec l'objet URLSearchParams du navigateur, qui fonctionne également hors de React. Gardez cette distinction en tête : mettre un identifiant dans la question revient à cacher la ressource que l'on affiche, et le partage d'adresse devient alors faux.

La page quatre cent quatre mérite enfin qu'on la traite comme un écran à part entière, pas comme un simple message d'erreur. Elle doit dire ce qui s'est passé, proposer un lien de retour vers l'accueil et, si c'est utile, suggérer les écrans les plus proches. Côté code, elle est un composant ordinaire ; côté route, elle est la ligne qui attrape tout. Pensez-y dès la première ligne de votre table de routes : prévenir l'inconnu coûte une ligne et protège l'ensemble de l'expérience.

```jsx
function Introuvable() {
  const navigate = useNavigate();
  return (
    <section>
      <h1>Page introuvable</h1>
      <p>L'adresse demandée n'existe pas ou plus.</p>
      <button onClick={() => navigate("/")}>Revenir à l'accueil</button>
    </section>
  );
}
```

Pour les déplacements qui ne naissent pas d'un clic sur un lien, comme après une validation réussie ou un bouton annuler, le routeur fournit une fonction de programmation. Elle reçoit la destination et déclenche le même changement d'adresse qu'un lien. Deux précautions d'usage : ne l'appelez pas directement pendant le rendu du composant, mais dans un gestionnaire d'événement ou un effet, sinon vous demandez au routeur de changer de page au milieu du dessin de l'écran ; et préférez le chemin relatif quand vous restez dans la même branche, par exemple programme, plutôt que de réécrire la racine complète à chaque fois.

- Déclarez la table des routes une seule fois, au sommet de l'application.
- Le composant de lien intercepte le clic : aucun document n'est rechargé.
- Le chemin étoile capture les adresses inconnues et les renvoie vers la page quatre cent quatre.
- Un segment variable, écrit avec deux-points, porte l'identifiant ; l'écran le lit avec la fonction de paramètres.
- Le paramètre de chemin identifie une ressource ; la question décrit un réglage facultatif.
- Les déplacements programmatiques s'appellent depuis un gestionnaire ou un effet, jamais pendant le rendu.
$lesson$),
  ('web-c7-p3', 'web-c7', 3, $lesson$Navigation imbriquée, mise en forme des liens actifs$lesson$, $lesson$
Les vraies applications n'ont pas trois routes égales : elles ont un gabarit commun et, à l'intérieur de celui-ci, des branches entières qui possèdent leur propre sous-navigation. Prenons le site de l'atelier : le bandeau et le menu principal sont constants, la section inscription contient elle-même trois étapes, et chacune de ces étapes devrait pouvoir être atteinte par une adresse directe. Le routeur gère ce cas avec l'imbrication : une route parente désigne un composant de disposition, et ses routes filles sont déclarées à l'intérieur. Quand l'adresse correspond à une fille, le routeur monte le parent, puis place la fille dans l'emplacement réservé que le parent a laissé libre.

```jsx
<Routes>
  <Route element={<Disposition />}>
    <Route path="/" element={<Accueil />} />
    <Route path="/programme" element={<Programme />} />
    <Route path="/inscription" element={<Inscription />}>
      <Route index element={<FormulaireInscription />} />
      <Route path="confirmation" element={<Confirmation />} />
      <Route path="liste" element={<ListeInscrits />} />
    </Route>
    <Route path="*" element={<Introuvable />} />
  </Route>
</Routes>
```

Lisez attentivement la route d'inscription : elle ne porte pas de composant propre, seulement une disposition, et ses filles viennent s'y greffer. La route sans chemin, marquée par l'index, désigne l'écran affiché quand on atteint le parent exactement, ici slash inscription sans rien après. Ses sœurs ajoutent un segment : slash inscription slash confirmation, slash inscription slash liste. Le résultat est une arborescence d'adresses qui reflète l'arborescence des écrans, ce qui rend le code prévisible et les adresses compréhensibles par un humain qui les lit dans la barre du navigateur.

La deuxième tâche de cette section est visuelle : dire à l'utilisateur où il se trouve. Un menu de trois liens dont aucun ne se distingue laisse la personne deviner. Le composant de lien amélioré du routeur, dit lien de correspondance, compare sa destination à l'adresse courante et applique automatiquement une classe quand elles correspondent. Cette comparaison gère par défaut le cas des adresses imbriquées : sur la page slash inscription slash liste, le lien vers slash inscription reste marqué comme actif, parce qu'il décrit effectivement la branche courante. Sans ce comportement, un menu imbriqué s'éteint dès qu'on entre dans une sous-page, et l'utilisateur perd la notion de section.

```jsx
<NavLink
  to="/programme"
  className={({ isActive }) => (isActive ? "lien-actif" : "lien")}
  end
>
  Programme
</NavLink>
```

L'attribut de précision, marqué end dans l'exemple, sert à un cas subtil : sans lui, le lien vers la racine correspond à toutes les adresses, puisque toutes commencent par la racine. On l'ajoute donc sur les liens qui doivent correspondre exactement, et on l'oublie sur les liens de branche. Une erreur fréquente consiste à penser que la classe suffit : si votre style repose uniquement sur la couleur, une personne qui ne distingue pas les teintes, ou qui lit la page au lecteur d'écran, ne profite pas de l'information. Ajoutez donc un attribut d'état sémantique lorsque la bibliothèque ne l'ajoute pas elle-même, et complétez par une différence d'apparence durable, comme une bordure ou un gras.

```table
Outil | Quand l'utiliser | Ce qu'il apporte
| --- | --- |
Lien simple | Destination statique connue à l'avance | Navigue sans recharger le document
Lien de correspondance | Élément de menu principal | Marque automatiquement la branche active
Fonction de déplacement | Après une action, un envoi, une annulation | Déplace depuis le code
Ancre classique | Saut vers une cible de la même page | Défile jusqu'à l'identifiant visé
```

La navigation au clavier impose une dernière discipline. Après un changement d'écran, le focus, c'est-à-dire la position de la tabulation, reste souvent sur l'élément qui a disparu, et l'utilisateur se retrouve sans rien pouvoir faire sans y penser. Deux réflexes corrigent le défaut : donner un titre de niveau un unique à chaque écran, et déplacer le focus sur le conteneur principal lors du changement de route. Cette seconde opération peut se faire dans un effet qui observe l'adresse : à chaque changement, on rend la zone de contenu focalisable et on y place le focus. Vingt lignes de code, une différence considérable pour toute personne qui pilote la page sans souris.

- Une route parente porte un composant de disposition ; ses filles viennent s'y insérer.
- La route sans chemin désigne l'écran par défaut d'une branche.
- Le lien de correspondance applique automatiquement une classe à la branche active.
- La précision exacte sert surtout pour le lien vers la racine du site.
- Un état actif doit se voir et s'entendre, pas seulement se colorier.
- Après chaque changement d'écran, renvoyez le focus sur le contenu principal.
$lesson$),
  ('web-c7-p4', 'web-c7', 4, $lesson$Formulaires contrôlés : une valeur, un état$lesson$, $lesson$
Un formulaire React repose sur un renversement complet de responsabilité. Dans un formulaire ordinaire, le navigateur détient la valeur de chaque champ et la rend sur demande ; dans un formulaire contrôlé, c'est votre état qui détient la valeur, et le champ ne fait que l'afficher. Chaque saisie devient un événement, chaque événement met à jour une variable d'état, chaque mise à jour déclenche un nouveau rendu, et le nouveau rendu écrit la valeur dans le champ. La boucle est fermée : ce que l'utilisateur tape arrive dans l'état, ce que contient l'état revient dans le champ. Tant que cette boucle est intacte, le champ et l'application ne peuvent pas diverger.

```jsx
function FormulaireAccueil() {
  const [courriel, setCourriel] = useState("");

  function changerCourriel(evenement) {
    setCourriel(evenement.target.value);
  }

  return (
    <form>
      <label htmlFor="courriel">Adresse électronique</label>
      <input
        id="courriel"
        type="email"
        value={courriel}
        onChange={changerCourriel}
      />
      <p>Valeur actuelle : {courriel}</p>
    </form>
  );
}
```

Les trois pièces de ce composant sont strictement nécessaires et chacune a son rôle. La variable d'état est la mémoire unique du champ. L'attribut de valeur donne au champ son contenu à l'écran : si vous l'omettez, le champ redevient libre, l'application n'apprend plus rien et le formulaire n'est plus contrôlé. L'attribut de changement est l'oreille du composant : il reçoit chaque frappe, en extrait la chaîne de caractères et l'enregistre. Notez que l'événement n'est utilisable que pendant l'appel : le routeur du navigateur le recycle immédiatement après le gestionnaire, si bien que toute tentative de le conserver pour plus tard échoue silencieusement. Copiez ce dont vous avez besoin, tout de suite.

Pour un formulaire à plusieurs champs, la tentation est d'ouvrir une variable d'état par champ, et elle fonctionne tant que le formulaire tient dans trois lignes. Dès que les champs se multiplient, ou qu'ils partagent un sort commun lors de la validation et de la remise à zéro, préférez un objet unique : un nom par champ dans l'objet, une fonction de mise à jour qui recopie l'objet précédent en écrasant la seule clé modifiée. L'écriture utilise pour cela la forme fonctionnelle de la mise à jour, celle qui reçoit l'état précédent, parce que vous ne disposez pas forcément de la valeur courante au moment de l'appel. Cette discipline a un effet secondaire précieux : la remise à zéro devient un seul appel qui restaure l'objet de départ.

```jsx
const valeursInitiales = { nom: "", courriel: "", places: "1" };
const [valeurs, setValeurs] = useState(valeursInitiales);

function changer(champ, evenement) {
  const valeur = evenement.target.value;
  setValeurs((etatPrecedent) => ({ ...etatPrecedent, [champ]: valeur }));
}

function reinitialiser() {
  setValeurs(valeursInitiales);
}
```

On objecte souvent que le formulaire contrôlé est plus verbeux que son équivalent libre. C'est vrai, et ce coût est volontaire : il est le prix de la maîtrise. Parce que la valeur passe par votre état, vous pouvez la vérifier à chaque frappe, bloquer un caractère interdit, normaliser la casse, proposer une auto-complétion, calculer un total, activer ou désactiver un bouton d'envoi, ou encore conserver les valeurs saisies quand l'écran change puis revient. Aucune de ces possibilités n'existe tant que le navigateur est seul propriétaire du champ. Le formulaire contrôlé n'est pas une mode : c'est la condition de tout ce que la suite du chapitre va construire.

- La valeur de chaque champ vit dans l'état du composant, pas seulement dans le navigateur.
- Sans attribut de valeur, le champ redevient libre et l'application cesse d'apprendre.
- L'événement de changement n'est valide que pendant l'appel : extrayez-en la valeur immédiatement.
- Un objet unique pour tous les champs simplifie la validation et la remise à zéro.
- Mettez à jour avec la forme fonctionnelle pour lire l'état précédent sans le figer.
- Le formulaire contrôlé coûte quelques lignes de plus et achète toute la maîtrise de la saisie.
$lesson$),
  ('web-c7-p5', 'web-c7', 5, $lesson$Validation : un message par champ, relié à ce qu'il explique$lesson$, $lesson$
La validation n'est pas une couche supplémentaire posée sur le formulaire : dans un formulaire contrôlé, elle découle mécaniquement de l'état. Puisque vous possédez déjà la valeur de chaque champ, vous pouvez dériver de ces valeurs une collection d'erreurs, la même façon dont une facture découle d'une liste d'articles. L'important est de choisir un endroit unique où cette dérivation a lieu. Deux écoles s'affrontent. La première valide à chaque frappe et affiche l'erreur dès que la deuxième lettre est tapée ; la seconde attend la soumission, puis maintient la vérification active tant que le formulaire reste invalide. La deuxième est préférable dans la plupart des cas : elle évite d'aggreser l'utilisateur qui compose lentement une adresse et qui, en route, passe obligatoirement par un état incomplet.

```jsx
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function valider(valeurs) {
  const erreurs = {};
  if (valeurs.nom.trim().length < 2) {
    erreurs.nom = "Indiquez au moins deux caractères pour le nom.";
  }
  if (!EMAIL.test(valeurs.courriel)) {
    erreurs.courriel = "Saisissez une adresse électronique valide, par exemple prenom@domaine.fr.";
  }
  if (Number(valeurs.places) < 1 || Number(valeurs.places) > 4) {
    erreurs.places = "Entre une et quatre places par inscription.";
  }
  return erreurs;
}
```

Cette fonction est volontairement pure : elle ne modifie rien, elle prend des valeurs et renvoie un objet dont les clés correspondent aux noms des champs. Cette propriété change tout, parce qu'elle vous permet de l'appeler à trois moments différents sans jamais désynchroniser l'affichage : au moment de la soumission pour décider d'envoyer ou non, après la soumission pour décider s'il faut continuer à afficher les erreurs, et pendant le rendu pour savoir si le champ doit porter un message. Une seule source de vérité, trois usages, aucune contradiction possible entre ce que vous affichez et ce que vous envoyez.

L'adresse électronique mérite une mise en garde particulière. La vérification par expression régulière reste un modèle simple, suffisant pour filtrer les fautes de frappe, mais elle ne peut pas prouver qu'une adresse existe : elle vérifie la forme, jamais la boîte aux lettres. Ne cherchez donc pas la perfection, cherchez la clarté. Toute expression régulière un peu sophistiquée finit par rejeter des adresses parfaitement valides au profit d'une fausse sécurité. Le champ de saisie est également de type courriel, ce qui donne au navigateur et au clavier mobile leur propre vérification : la validation native et votre validation se complètent, elles ne se remplacent pas.

Afficher le message est une question d'accessibilité autant que d'apparence. Trois attributs font toute la différence sur le champ fautif. Le premier, d'état invalide, signale au lecteur d'écran que le champ est en erreur. Le second relie le champ au message par une référence à l'identifiant du paragraphe d'erreur : l'outil de lecture annonce alors automatiquement l'explication quand le champ prend le focus. Le troisième porte sur le message lui-même et lui donne un rôle d'alerte, de sorte qu'il soit annoncé dès qu'il apparaît, sans que la personne ait besoin de chercher. Sans ces trois liens, votre message reste un carré rouge que seuls les utilisateurs voyants perçoivent.

```jsx
<label htmlFor="courriel">Adresse électronique</label>
<input
  id="courriel"
  type="email"
  value={valeurs.courriel}
  onChange={(e) => changer("courriel", e)}
  aria-invalid={Boolean(erreurs.courriel) || undefined}
  aria-describedby={erreurs.courriel ? "erreur-courriel" : undefined}
/>
{erreurs.courriel && (
  <p id="erreur-courriel" role="alert">
    {erreurs.courriel}
  </p>
)}
```

Reste la question du bouton d'envoi. L'instinct veut le désactiver tant que le formulaire est invalide, et l'exemple est partout. Le problème est pédagogique autant que technique : un bouton muet ne dit pas pourquoi il ne répond pas, la personne clique, il ne se passe rien, et elle abandonne. Préférez un bouton toujours actif qui, au clic, valide, affiche les messages et déplace le focus sur le premier champ fautif. Une exception justifie le désactivation : pendant l'envoi réel, où empêcher un double clic protège à la fois de la duplication des inscriptions et des réponses qui s'entrecroisent. Désactiver pendant l'envoi, pas avant la saisie.

- Validez à chaque soumission, puis gardez la vérification active tant que le formulaire reste invalide.
- Écrivez une fonction de validation pure, appelable autant de fois que nécessaire sans effet de bord.
- Vérifiez la forme d'une adresse, jamais son existence réelle : méfiezsez des expressions régulières trop clever.
- Reliez le champ à son message avec l'attribut d'état invalide et celui qui référence le message.
- Donnez au message un rôle d'alerte pour qu'il soit annoncé dès son apparition.
- Gardez le bouton actif et expliquez l'erreur ; désactivez-le seulement pendant l'envoi.
$lesson$),
  ('web-c7-p6', 'web-c7', 6, $lesson$Soumission : les états envoyé, en erreur et confirmé$lesson$, $lesson$
La soumission est le moment où un formulaire cesse d'être local. Tant que l'utilisateur tape, tout se passe dans le composant ; au clic, l'application contacte un autre système, une base, un service, un fichier, et ce système peut répondre de trois manières : vite et bien, lentement, ou mal. Un formulaire professionnel décrit ces trois issues explicitement, et pour cela il porte un état supplémentaire, distinct des valeurs saisies, que l'on peut voir comme la position du formulaire dans un petit automate à trois ou quatre positions. Tant que rien n'a été tenté, le formulaire est au repos. Pendant l'envoi, il est occupé. Puis il bascule soit vers la confirmation, soit vers l'échec.

```jsx
const [statut, setStatut] = useState("repos"); // repos | envoi | succes | echec
const [message, setMessage] = useState("");

async function soumettre(evenement) {
  evenement.preventDefault();
  const erreurs = valider(valeurs);
  setErreurs(erreurs);
  if (Object.keys(erreurs).length > 0) {
    setStatut("echec");
    setMessage("Le formulaire comporte des champs à corriger.");
    return;
  }

  setStatut("envoi");
  setMessage("Envoi de votre inscription…");
  try {
    await envoyerInscription(valeurs);
    setStatut("succes");
    setMessage("Votre inscription est enregistrée.");
    setValeurs(valeursInitiales);
    setErreurs({});
  } catch (erreur) {
    setStatut("echec");
    setMessage("L'envoi a échoué. Vos données sont conservées, réessayez.");
  }
}
```

Quatre détails de cet exemple méritent d'être relevés. Le premier est la toute première ligne : la soumission par défaut du navigateur recharge la page et efface tout. Interceptar cet événement est la condition de survie du formulaire, et l'oublier produit l'erreur la plus déroutante du débutant, un écran qui clignote et revient à la même page. Le deuxième est l'ordre des états : on passe à l'état occupé avant l'appel asynchrone, jamais après, sinon il existe une fenêtre pendant laquelle l'utilisateur croit que rien ne se passe et réclique. Le troisième est la remise à zéro, réalisée uniquement dans le succès : en cas d'échec, les saisies sont précieuses, les conserver évite à la personne de tout retaper. Le quatrième est le message d'échec, qui promet exactement ce qui est vrai, à savoir que les données sont toujours là.

L'erreur et le succès ne se traitent pas de la même façon, et la différence est humaine plus que technique. L'échec doit être réparable : il indique ce qui s'est passé, il conserve la saisie, il propose un bouton pour réessayer, et il ne blâme pas l'utilisateur. La confirmation, elle, doit marquer une coupure : le formulaire peut disparaître au profit d'un récapitulatif, ou se vider et revenir au repos avec un message explicite. Dans les deux cas, déplacez le focus sur le message affiché, sinon une personne qui navigue au clavier reste sur un bouton dont le sens vient de changer. Enfin, si l'envoi peut échouer deux fois de suite, évitez les messages vagues comme une erreur est survenue : nommez l'étape, par exemple l'envoi vers le service d'inscription, et la reprise devient imaginable.

Il existe une dernière catégorie d'erreur, souvent négligée : celle qui survient pendant que le formulaire est affiché mais avant tout clic, par exemple une connexion qui tombe. Attendre le clic pour la découvrir est légitime, à condition de réagir avec le même soin. Et si l'utilisateur change d'avis en plein envoi, proposez un bouton d'annulation qui déclenche l'annulation de l'appel, ce que la section sur les effets va vous apprendre à faire proprement. Un formulaire qui sait dire non, attendre, échouer et réussir est un formulaire terminé ; un formulaire qui ne sait que réussir est une démonstration.

```table
Statut | Ce que dit l'écran | Ce que doit faire l'utilisateur
| --- | --- |
repos | Champs vierges, bouton prêt | Saisir puis envoyer |
envoi | Bouton inactif, message d'attente | Patienter sans récliquer |
echec | Message expliquant l'échec, saisie conservée | Corriger ou réessayer |
succes | Confirmation, formulaire vidé ou remplacé | Poursuivre vers la suite |
```

- Interceptez la soumission par défaut : sinon la page se recharge et tout est perdu.
- Passez à l'état occupé avant l'appel, pas après.
- Ne videz les champs que lorsque l'envoi a réellement réussi.
- En cas d'échec, conservez la saisie et proposez un bouton de réessai.
- Déplacez le focus sur le message affiché après chaque changement de statut.
- Décrivez l'étape qui a échoué, jamais une genericité qui décourage.
$lesson$),
  ('web-c7-p7', 'web-c7', 7, $lesson$Charger des données au montage avec useEffect$lesson$, $lesson$
Jusqu'ici, les composants affichaient ce qu'on leur donnait. Une application réelle doit aussi demander ses données elle-même, au moment où un écran apparaît. C'est le rôle d'un effet : une fonction qui dit à React, une fois le rendu terminé, de faire quelque chose qui dépasse le dessin du composant — mettre le focus, abonner un écouteur, lire le local stockage, ou encore aller chercher une liste. Le mot est important : un rendu décrit l'état d'un instant, un effet observe ce qui se passe autour. Conflit n'existe donc pas tant que chaque responsabilité reste chez elle.

L'effet s'exprime avec une fonction que vous passez à useEffect. Elle s'exécute après le rendu, jamais pendant, et retourne éventuellement une autre fonction chargée du nettoyage. La particularité qui nous occupe ici est le tableau de dépendances : deuxième argument de l'appel, il liste les valeurs extérieures dont l'effet se sert. Un tableau vide signifie que l'effet ne dépend de rien qui puisse changer, donc qu'il ne doit se déclencher qu'une fois, à l'apparition du composant. C'est précisément la définition du chargement au montage.

```jsx
function ListeInscrits() {
  const [inscrits, setInscrits] = useState([]);

  useEffect(() => {
    chargerInscrits().then((liste) => setInscrits(liste));
  }, []);

  return (
    <ul>
      {inscrits.map((personne) => (
        <li key={personne.id}>{personne.nom}</li>
      ))}
    </ul>
  );
}
```

Cet extrait tient en peu de lignes, mais chacune compte. L'état démarre avec une liste vide, si bien que le premier rendu montre un écran sans contenu, ce que nous corrigerons dans la section suivante avec un état de chargement. La promesse est résolue dans un gestionnaire qui met à jour l'état, ce qui déclenche un second rendu avec les données. Et l'identifiant fourni par la bibliothèque, placé sur chaque élément de liste, ne sert pas au style : il dit à React quel nœud réutiliser quand la liste change, et son absence provoque des avertissements puis des comportements erratiques lors du tri ou du filtrage. Un identifiant doit être stable et unique, jamais l'index dans le tableau si celui-ci peut être réordonné.

Un effet ne doit jamais tenter de modifier l'état pendant le rendu. La raison est structurelle : pendant le rendu, React prépare le prochain affichage, et une mise à jour inattendue l'obligerait à recommencer, parfois indéfiniment. C'est d'ailleurs l'origine de l'erreur la plus célèbre de l'effet, celle où une mise à jour déclenche l'effet qui redéclenche une mise à jour, à l'infini. Le tableau de dépendances vide est souvent la cause de ce cycle, soit parce qu'une valeur qui change a été oubliée, soit parce que l'effet met à jour une valeur qui fait partie de sa propre dépendance. Quand vous voyez cette erreur, comptez les étapes : la boucle est presque toujours dans votre code, pas dans la bibliothèque.

Trois usages du montage complètent le chargement et méritent d'être connus. Le premier est la mise en forme initiale : placer le focus sur le premier champ quand un formulaire s'ouvre, ou faire défiler vers un titre quand une fenêtre modale apparaît. Le deuxième est l'abonnement : enregistrer un écouteur d'événement globale, comme le changement d'adresse ou la taille de fenêtre, et le retirer au démontage pour ne pas accumuler des écouteurs fantômes. Le troisième est la lecture d'une préférence, par exemple le thème choisi lors de la visite précédente, à appliquer avant que l'utilisateur ne perçoive un clignotement. Dans les trois cas, la logique est la même : observer le monde extérieur après le rendu, puis revenir à l'état.

```text
Cycle de vie d'un effet

montage du composant
   |
   v
rendu (React dessine l'arbre)
   |
   v
effet : la fonction du useEffect s'exécute
   |
   +--> elle déclenche une mise a jour d'etat
   |         |
   |         v
   |    re-rendu (sans rappeler l'effet : le tableau est vide)
   |
   v
démontage (l'utilisateur quitte l'écran)
   |
   v
nettoyage : la fonction renvoyée par l'effet s'exécute
```

- Un effet s'exécute après le rendu et retourne éventuellement une fonction de nettoyage.
- Un tableau de dépendances vide signifie : une seule fois, au montage du composant.
- Jamais de mise à jour d'état pendant le rendu : c'est la porte des boucles infinies.
- Chaque élément de liste porte un identifiant stable fourni par la donnée.
- Le montage sert aussi au focus, aux abonnements et à la lecture des préférences.
- Un effet ne décrit pas l'affichage ; il observe ce qui entoure l'affichage.
$lesson$),
  ('web-c7-p8', 'web-c7', 8, $lesson$Dépendances de l'effet et fonctions asynchrones$lesson$, $lesson$
Le tableau des dépendances est la pièce la plus délicate de useEffect, et la source de la quasi-totalité des bugs liés aux effets. Sa règle tient en une phrase : tout ce qui provient de l'extérieur de l'effet et qui peut changer doit figurer dans le tableau. Une constante locale écrite au-dessus de l'appel n'a pas à y être, une valeur d'état ou de props s'y trouve, une fonction définie dans le composant aussi, puisqu'elle est recréée à chaque rendu. Si vous vous fiez à votre mémoire, vous oublierez des dépendances ; c'est pourquoi les outils de lint intègrent une règle d'exhaustivité qui signale toute valeur omise, et il faut l'activer dès le premier projet plutôt que de la subir en fin de développement.

```jsx
function RechercheInscrits({ atelierId }) {
  const [mot, setMot] = useState("");
  const [resultats, setResultats] = useState([]);

  useEffect(() => {
    let ignore = false;
    async function chercher() {
      const liste = await chargerInscrits(atelierId);
      if (!ignore) {
        setResultats(liste.filter((p) => p.nom.includes(mot)));
      }
    }
    chercher();
    return () => {
      ignore = true;
    };
  }, [atelierId, mot]);

  return <p>{resultats.length} résultat(s)</p>;
}
```

Cet exemple contient trois enseignements. Le premier : l'effet dépend de deux valeurs, l'identifiant de l'atelier et le mot recherché, et se relance dès que l'une ou l'autre change. Le deuxième : la variable ignore est la protection contre une réponse tardive. Si l'utilisateur tape trois lettres en une seconde, trois appels partent en parallèle et peuvent rentrer dans le désordre ; le premier lancé, qui arrive le dernier, écrirait un résultat obsolète. La variable, mise à jour par le nettoyage, dit à chaque réponse qu'elle est devenue caduque. Le troisième : la fonction de nettoyage est rendue immédiatement après le lancement, ce qui garantit qu'elle s'exécutera avant le prochain tour, quel que soit le motif du redémarrage.

La question des fonctions asynchrones appelle une précision indispensable : une fonction d'effet ne peut pas elle-même être asynchrone. Si vous marquez la fonction comme asynchrone, elle renvoie immédiatement une promesse, que React prend pour une fonction de nettoyage, et le nettoyage devient inutilisable. La forme correcte définit une fonction asynchrone à l'intérieur de l'effet, puis l'appelle. Cette fonction interne peut utiliser await tranquillement, attraper ses erreurs avec un bloc try catch, et son échec n'empêche pas le reste de l'application de vivre. L'erreur attrapée doit d'ailleurs se transformer en état d'erreur visible, jamais laissée silencieuse dans la console.

```jsx
useEffect(() => {
  let ignore = false;

  async function charger() {
    setStatut("chargement");
    try {
      const liste = await chargerInscrits();
      if (!ignore) {
        setInscrits(liste);
        setStatut("succes");
      }
    } catch (erreur) {
      if (!ignore) {
        setStatut("erreur");
      }
    }
  }

  charger();
  return () => {
    ignore = true;
  };
}, []);
```

L'ordre des affectations d'état à l'intérieur de cette fonction n'est pas anodis. L'état de chargement est posé avant l'appel, pour que l'écran change immédiatement ; les états de succès ou d'erreur ne sont posés qu'après la résolution, et uniquement si l'effet est toujours d'actif. Cette discipline élimine une classe entière de bugs, celle où un écran qui a été quitté continue d'écrire dans des états qui n'appartiennent plus à personne. Si vous préférez l'annulation formelle à la simple variable de drapeau, la section suivante montre comment annuler l'appel lui-même avec l'objet d'annulation fourni par l'API de fetch.

Un mot enfin sur la tentation d'empiler les effets. Quand un composant doit charger A, puis avec A charger B, la réponse n'est presque jamais d'écrire un second effet qui dépend de A : elle consiste à faire la séquence dans un seul effet, ou à extraire la logique dans une fonction appelée par ce seul effet. Chaque effet supplémentaire ajoute un ordre d'exécution à coordonner et multiplie les occasions de réponse tardive. Gardez un effet par responsabilité réelle, mais ne morcelez pas une seule logique en plusieurs effets qui doivent se parler.

- Tout ce qui peut changer et qui sert à l'effet figure dans le tableau des dépendances.
- Activez la règle d'exhaustivité des dépendances dans vos outils de lint dès le début.
- Une fonction d'effet ne peut pas être asynchrone : définissez la fonction asynchrone à l'intérieur, puis appelez-la.
- Attrapez les erreurs à l'intérieur de cette fonction et transformez-les en état d'erreur visible.
- Protégez chaque réponse avec un drapeau d'ignoré ou avec une annulation réelle.
- Une seule logique, un seul effet : ne morcelez pas une séquence en effets qui se parlent.
$lesson$),
  ('web-c7-p9', 'web-c7', 9, $lesson$Annuler un effet et éviter les fuites$lesson$, $lesson$
Une fuite se produit quand quelque chose que vous avez créé continue d'exister alors que plus personne ne s'en sert : un écouteur jamais retiré, un minuteur qui met encore à jour un écran parti, une requête qui revient déposer ses données dans un composant démonté. Le symptôme est discret — un avertissement en développement, parfois un comportement bizarre quelques secondes après un changement d'écran rapide — mais la cause est toujours la même : vous avez commencé quelque chose dans un effet sans prévoir comment l'arrêter. La fonction renvoyée par l'effet est exactement ce plan de sortie, et elle doit être écrite en même temps que le départ, pas réfléchie après le bug.

Le moment où le nettoyage s'exécute est fixé par une règle simple : avant chaque nouvelle exécution de l'effet, et au démontage du composant. Concrètement, si l'effet démarre un minuteur et rend une fonction qui l'éteint, alors chaque changement de dépendance éteint l'ancien minuteur avant d'en allumer un nouveau, et le départ de l'écran éteint le dernier. Sans cette fonction, chaque passage laisse derrière lui un minuteur qui continue de courir : au bout de dix passages, dix minuteurs s'affolent en parallèle, et le composant, lui, n'est plus là pour les arrêter. Ce phénomène, c'est la fuite, et la fonction de nettoyage la transforme en simple interruption.

```jsx
useEffect(() => {
  const minuteur = setInterval(() => {
    setSecondes((s) => s + 1);
  }, 1000);

  return () => clearInterval(minuteur);
}, []);
```

Pour les appels réseau, l'annulation se fait avec un contrôleur d'annulation, objet fourni par la plateforme et compris par l'API de fetch. On le crée au début de l'effet, on le transmet à l'appel via l'option prévue à cet effet, et on l'annule dans la fonction de nettoyage. La requête annulée ne produit pas une erreur à signaler : elle se termine par un rejet spécial que l'on distingue, en l'attrapant et en vérifiant que l'annulation était bien intentionnelle. C'est la forme professionnelle du chargement, celle qui garantit qu'aucune réponse ne peut plus jamais écrire dans un écran disparu.

```jsx
useEffect(() => {
  const controleur = new AbortController();

  async function charger() {
    try {
      const reponse = await fetch("/api/inscrits", {
        signal: controleur.signal,
      });
      const donnees = await reponse.json();
      setInscrits(donnees);
    } catch (erreur) {
      if (erreur.name !== "AbortError") {
        setErreur("Impossible de charger la liste des inscrits.");
      }
    }
  }

  charger();
  return () => controleur.abort();
}, []);
```

Quand la source de données est locale, comme la fonction asynchrone `chargerInscriptions()` posée dans le chapitre sur les promesses, qui résout une valeur après un délai avec `resolveApres()`, le contrôleur ne sert à rien puisqu'aucun appel réseau n'est émis. Le drapeau d'ignoré suffit alors : il ne peut pas annuler le délai en cours, mais il décide que son résultat n'aura plus le droit d'écrire. Les deux approches répondent à la même question, à savoir que faire d'une réponse qui arrive trop tard, et vous choisirez selon la nature de la source. Retenez la logique, pas la syntaxe : chaque départ d'effet possède son retour, et chaque retour ferme la porte que l'effet vient d'ouvrir.

```text
Effet avec annulation, chronologie

t0  rendu avec atelierId = "a1"
t1  effet : controleur cree, appel lance
t2  l'utilisateur change de filtre
t3  nettoyage : controleur.annule(), la reponse est refusee
t4  effet : nouveau controleur, nouvel appel
t5  la reponse de t4 arrive, elle est acceptee

si le composant disparait entre t4 et t5 :
t6  demontage -> nettoyage -> la reponse est refusee
```

Un dernier réflexe complète ces mécanismes : ne conservez jamais une référence vers un composant démonté. Cela signifie qu'un écouteur global enregistré au montage doit être retiré au démontage, qu'un abonnement à un flux doit être fermé, et qu'une promesse en attente doit être signalée comme caduque. Vérifiez-le en simulant le pire scénario : cliquez trois fois de suite sur un lien qui charge une page, puis revenez en arrière. Si l'écran final montre les données de la première tentative, votre protection est incomplète. Ce test d'abus coûte dix secondes et détecte la majorité des fuites bien avant la mise en production.

- La fonction rendue par l'effet s'exécute avant chaque nouvelle exécution et au démontage.
- Chaque minuteur, écouteur ou abonnement créé dans un effet est détruit dans sa fonction de nettoyage.
- Une requête réseau s'annule avec le contrôleur d'annulation transmis à fetch.
- Une annulation n'est pas une erreur : attrapez-la et distinguez-la des vrais échecs.
- Pour une source locale, un drapeau d'ignoré suffit à invalider la réponse tardive.
- Testez en cliquant vite et en revenant en arrière : les données affichées doivent être les dernières.
$lesson$),
  ('web-c7-p10', 'web-c7', 10, $lesson$Gérer les états de la donnée : chargement, erreur, vide, succès$lesson$, $lesson$
Une liste qui arrive d'un système distant peut se présenter de quatre manières, et un écran qui n'en décrit que deux est un écran incomplet. Pendant que la donnée voyage, elle n'existe pas encore : afficher un tableau vide à cet instant laisse l'utilisateur croire que l'atelier n'a inscrit personne. Si le système distant tombe, l'absence de donnée ressemble exactement à l'absence de résultat, alors que les deux situations appellent des réactions opposées. Et même quand tout se passe bien, une liste réellement vide n'est pas une erreur : c'est un cas normal qui mérite son message et, souvent, son appel à l'action. La solution consiste à ne plus considérer la donnée comme existante ou inexistante, mais à donner au composant un état d'affichage qui décrit la situation courante.

```text
Etats possibles d'un ecran qui affiche une liste

        +--> [chargement] --+
        |                   |
[repos] |                   v
        |               [succes avec liste]
        |                   |
        |                   +--> [succes, liste vide]
        |
        +--> [erreur] -----> [chargement]  (apres le bouton reessayer)
```

L'implémentation utilise un seul état de statut, dont la valeur désigne la branche courante, complété par les données proprement dites. L'avantage d'un statut unique est qu'il rend les combinaisons impossibles : on ne peut pas être à la fois en erreur et en chargement, puisque la variable ne porte qu'une valeur. À l'inverse, trois booléens séparés, en chargement, en erreur, réussi, produisent des combinaisons absurdes que rien ne vous empêche d'écrire. Le rendu se lit alors comme une ramification : chaque statut renvoie à son affichage, et le cas non prévu tombe sur un état par défaut sûr plutôt que sur du vide.

```jsx
function PageInscrits() {
  const [statut, setStatut] = useState("chargement");
  const [inscrits, setInscrits] = useState([]);
  const [erreur, setErreur] = useState(null);

  useEffect(() => {
    let ignore = false;
    async function charger() {
      setStatut("chargement");
      try {
        const liste = await chargerInscrits();
        if (!ignore) {
          setInscrits(liste);
          setStatut(liste.length === 0 ? "vide" : "succes");
        }
      } catch (e) {
        if (!ignore) {
          setErreur(e);
          setStatut("erreur");
        }
      }
    }
    charger();
    return () => {
      ignore = true;
    };
  }, []);

  if (statut === "chargement") return <p>Chargement des inscrits…</p>;
  if (statut === "erreur")
    return (
      <div>
        <p role="alert">La liste n'a pas pu être chargée.</p>
        <button onClick={reessayer}>Réessayer</button>
      </div>
    );
  if (statut === "vide")
    return <p>Aucune inscription pour le moment. Soyez le premier.</p>;
  return (
    <ul>
      {inscrits.map((p) => (
        <li key={p.id}>{p.nom}</li>
      ))}
    </ul>
  );
}
```

L'état vide mérite qu'on s'y attarde, parce qu'il est celui qu'on oublie toujours. Dire qu'il n'y a rien, c'est utile ; dire quoi faire ensuite, c'est mieux. Sur le site de l'atelier, une liste d'inscrits vide appelle un lien vers le formulaire d'inscription ; une liste de recherches vide appelle un conseil de reformulation ; une liste vide parce que le filtre est trop restrictif appelle un bouton pour réinitialiser le filtre. Chaque écran vide devrait répondre à la question que le visiteur se pose, à savoir que faire ici. Le bouton de réessai, lui, appartient à l'état d'erreur et pas au vide : réessayer une requête qui a réussi n'a aucun sens.

```table
Statut | Ce que voit l'utilisateur | Ce que fait le composant
| --- | --- |
chargement | Message d'attente ou squelette | Effet lancé, données absentes |
erreur | Explication + bouton réessayer | Nouveau tour de l'effet |
vide | Message et action de relance | Liste présente mais sans élément |
succes | Liste complète | Rendu normal depuis l'état |
```

Une dernière discipline porte sur la conservation des données d'un affichage précédent. Si l'utilisateur change de filtre pendant que la nouvelle réponse voyage, vous pouvez choisir d'effacer l'ancienne liste, au prix d'un écran qui clignote, ou de la conserver et de signaler la mise à jour, au prix d'un écran momentanément périmé. La seconde option est souvent préférable quand les données sont longues à venir : conservez l'ancien contenu, affichez un indicateur discret de rafraîchissement, puis remplacez le contenu quand la réponse arrive. Quelle que soit la décision, elle doit être prise consciemment et appliquée partout de la même façon.

- Donnez à l'écran un statut unique : chargement, erreur, vide ou succès.
- Un statut unique interdit les combinaisons impossibles que trois booléens autorisent.
- Le vide n'est pas une erreur : il propose une action de relance.
- L'erreur propose un bouton réessayer qui relance réellement l'effet.
- Prévoyez un rendu par défaut pour le cas non prévu plutôt qu'un écran noir.
- Conservez ou effacez l'ancien contenu pendant le rafraîchissement, mais choisissez-le une fois pour toutes.
$lesson$),
  ('web-c7-p11', 'web-c7', 11, $lesson$Un mini-client REST : GET et POST avec fetch$lesson$, $lesson$
Passer du chargement local à l'appel d'un vrai service ne change presque rien si vous acceptez une seule idée : la fonction que vous appelez depuis vos composants ne doit pas être fetch elle-même. fetch est un outil brut : elle ne connaît ni vos adresses, ni vos formats d'erreur, ni vos en-têtes, et elle ne rejette pas quand le serveur répond par un code d'échec. Enfermez-la dans un petit module qui expose, pour chaque opération métier, une fonction nommée d'après ce qu'elle fait. Le composant demande à inscrire quelqu'un, la fonction s'occupe du reste, et si le format du service change un jour, une seule ligne se retrouve à modifier.

```javascript
// mini-client.js — la seule porte d'entrée vers le réseau
export async function getInscrits() {
  const reponse = await fetch("/api/inscrits");
  if (!reponse.ok) {
    throw new Error("Requête refusée : " + reponse.status);
  }
  return reponse.json();
}

export async function ajouterInscription(donnees) {
  const reponse = await fetch("/api/inscrits", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(donnees),
  });
  if (!reponse.ok) {
    throw new Error("Envoi refusé : " + reponse.status);
  }
  return reponse.json();
}
```

Trois détails de ce module sont professionnels. Le premier est le contrôle du code de réponse : contrairement à ce que laisse croire le nom, l'appel se résout aussi bien quand le serveur répond avec un code quatre cent quatre ou cinq cents ; seul le reseau en panne provoque un rejet. Sans ce contrôle, un formulaire afficherait un succès à partir d'une page d'erreur. Le deuxième est la conversion automatique en objet JavaScript, à appeler explicitement puisque la réponse est d'abord un flux d'octets. Le troisième est la sérialisation du corps : les données partent en texte structuré, accompagnées de l'en-tête qui annonce ce format au serveur.

Le POST comporte une contrainte supplémentaire : le serveur peut refuser la demande parce que les données sont invalides, en renvoyant par exemple un code quatre cent deux avec la liste des champs fautifs. Cette erreur est précieuse : elle vous dispense de deviner la règle métier. Attrapez-la, lisez le corps de la réponse, affichez les messages renvoyés champ par champ, et laissez les autres échecs, réseau ou serveur indisponible, dans votre état d'erreur général. Distinguer ainsi l'erreur de saisie de l'erreur de système est ce qui sépare un formulaire qui culpabilise d'un formulaire qui aide.

Le chapitre sur les fonctions asynchrones a posé une fonction locale, `chargerInscriptions()`, qui résout une promesse après un court délai grâce à `resolveApres()` et qui possède exactement la même forme que ces deux méthodes. Elle tient lieu de service pendant tout le parcours : l'exercice qui suit cette leçon lui donne le nom `getInscrits()` et conserve le même contrat, une promesse, un délai, des valeurs raisonnables et aucune adresse réseau. Cette substitution est possible parce que le composant ignore toujours la source : il attend une promesse, il reçoit une promesse. Vous pouvez donc développer toute l'interface, navigation, validation et états d'affichage, avant même d'avoir un serveur, puis basculer sur le mini-client réel en changeant l'import d'un seul fichier.

```javascript
// Version locale utilisée pendant tout le parcours, sans réseau.
const base = [{ id: 1, nom: "Amina", courriel: "amina@exemple.fr" }];

function attendre(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function getInscrits() {
  await attendre(400);
  return [...base];
}

export async function ajouterInscription(donnees) {
  await attendre(300);
  if (!donnees.courriel.includes("@")) {
    throw new Error("Adresse invalide refusée par le service.");
  }
  const inscription = { id: base.length + 1, ...donnees };
  base.push(inscription);
  return inscription;
}
```

Notez le soin apporté à la copie du tableau : renvoyer le tableau interne directement laisserait le composant modifier l'état du mini-client sans en informer personne, et les prochains chargements verraient une liste altérée. Copiez toujours ce que vous partagez, renvoyez des nouvelles instances à chaque appel, et gardez la source intacte. C'est la même discipline que la règle d'or des mises à jour d'état, appliquée cette fois à la frontière entre deux modules.

- Enfermez fetch dans un module qui expose des fonctions nommées d'après le métier.
- Vérifiez le code de réponse : l'appel se résout aussi quand le serveur refuse.
- Annoncez le format JSON dans l'en-tête de la requête envoyée.
- Distinguez l'erreur de saisie, renvoyée par le service, des pannes de système.
- Remplacez la source locale par le mini-client réel en changeant un seul import.
- Copiez les listes que vous partagez : ne rendez jamais votre état interne modifiable de l'extérieur.
$lesson$),
  ('web-c7-p12', 'web-c7', 12, $lesson$Récapitulatif des états d'une page$lesson$, $lesson$
Assemblons maintenant la vue d'ensemble. Une page qui reçoit ses données d'ailleurs traverse une trajectoire que l'on peut dessiner en entier, et la connaître évite d'écrire des rendus au cas par cas découverts en cours de route. La page démarre, son effet part, elle affiche l'attente, puis elle bascule vers l'une des trois issues. Deux d'entre elles, erreur et vide, appellent une action ; la troisième, la liste remplie, laisse la place à l'interaction proprement dite. Quand l'utilisateur agit, par exemple en validant le formulaire d'inscription, la page revient au chargement avant de repartir vers le succès. Ce cycle, répété, constitue la totalité de la vie d'un écran applicatif.

Ce récapitulatif a une utilité pratique : il sert de grille de relecture. Parcourez votre composant et demandez-vous, pour chaque état, qui l'affiche, qui en sort, et ce que l'utilisateur peut faire à ce moment-là. Si une réponse manque, il manque un rendu. Les trous les plus fréquents sont l'absence de message pendant l'attente, l'absence de bouton après un échec, et l'absence de retour à l'accueil depuis la page quatre cent quatre. Chacun se comble en quelques lignes, mais chacun se remarque aussi au premier test avec une connexion lente ou un service coupé.

```jsx
function Affichage({ statut, inscrits, erreur, onReessayer, onSinscrire }) {
  switch (statut) {
    case "chargement":
      return <p role="status">Chargement en cours…</p>;
    case "erreur":
      return (
        <div>
          <p role="alert">{erreur.message}</p>
          <button onClick={onReessayer}>Réessayer</button>
        </div>
      );
    case "vide":
      return (
        <div>
          <p>Aucune inscription pour le moment.</p>
          <button onClick={onSinscrire}>S'inscrire à l'atelier</button>
        </div>
      );
    default:
      return (
        <ul>
          {inscrits.map((personne) => (
            <li key={personne.id}>{personne.nom}</li>
          ))}
        </ul>
      );
  }
}
```

Ce composant présente une propriété qui vaut la peine d'être nommée : il ne décide de rien. Il reçoit le statut et des rappels, et il transforme en affichage la décision prise ailleurs. Cette séparation vous permet de tester chaque branche sans simuler de réseau, de modifier les textes sans toucher à la logique, et de réutiliser le même affichage dans plusieurs pages. Elle correspond exactement à la frontière que tout le chapitre cherche à tracer : d'un côté, la logique qui décide, de l'autre, le rendu qui montre.

- Dessinez la trajectoire complète d'un écran avant d'écrire son rendu.
- Chaque statut possède un affichage, une sortie et une action proposée.
- Séparez le composant qui décide du composant qui affiche.
- Relisez chaque composant avec la grille : qui affiche, qui sort, que peut faire l'utilisateur ?
- Les trous se voient surtout avec une connexion lente ou un service coupé.
$lesson$),
  ('web-c7-p13', 'web-c7', 13, $lesson$Mini-projet guidé : inscription et liste des inscrits$lesson$, $lesson$
Il est temps d'assembler le chapitre dans une application unique, qui prolonge le site de l'atelier de la Médiathèque des Lilas. L'écran d'accueil présente l'événement, l'écran programme détaille le déroulement, l'écran inscription contient le formulaire contrôlé validé, et l'écran liste affiche les inscrits avec leurs quatre états. Toutes les routes sont écrites après une almohadille, si bien que le fichier fonctionne ouvert depuis un simple dossier, sans serveur ni compilation. Nous procéderons dans l'ordre habituel : d'abord le squelette de navigation, puis le formulaire, ensuite la liste, enfin la couture entre les deux.

```jsx
export default function Application() {
  return (
    <HashRouter>
      <header>
        <h1>Atelier de la Médiathèque des Lilas</h1>
        <nav>
          <NavLink to="/">Accueil</NavLink>
          <NavLink to="/programme">Programme</NavLink>
          <NavLink to="/inscription">Inscription</NavLink>
          <NavLink to="/liste">Liste des inscrits</NavLink>
        </nav>
      </header>
      <main>
        <Routes>
          <Route path="/" element={<Accueil />} />
          <Route path="/programme" element={<Programme />} />
          <Route path="/inscription" element={<Inscription />} />
          <Route path="/liste" element={<ListeInscrits />} />
          <Route path="*" element={<Introuvable />} />
        </Routes>
      </main>
      <footer>Atelier du samedi 18 octobre — Médiathèque des Lilas</footer>
    </HashRouter>
  );
}
```

La navigation est déclarée une fois, le lien de correspondance marque la branche active, et la route étoile ferme la porte des adresses inconnues. Vérifiez immédiatement les trois gestes qui détectent les erreurs de base : cliquez sur chaque lien, l'adresse change sans rechargement et l'écran avec ; rafraîchissez la page, vous restez sur le même écran ; tapez une adresse absente, la page quatre cent quatre apparaît avec un chemin de retour. Si l'un des trois échoue, le problème est dans la table des routes, jamais dans les composants.

Le formulaire constitue la pièce centrale. Il combine l'objet de valeurs, la fonction de validation, l'état de statut d'envoi et l'affichage relié par les attributs d'accessibilité. Écrivez-le entièrement, puis testez-le dans l'ordre : d'abord l'envoi avec un champ vide, le message doit apparaître et le focus doit partir dessus ; ensuite une adresse mal formée, le même parcours ; enfin une saisie correcte, qui doit déclencher l'état d'envoi puis la confirmation, sans jamais recharger la page.

```jsx
function Inscription() {
  const [valeurs, setValeurs] = useState(valeursInitiales);
  const [erreurs, setErreurs] = useState({});
  const [statut, setStatut] = useState("repos");
  const navigate = useNavigate();

  function changer(champ, evenement) {
    const valeur = evenement.target.value;
    setValeurs((etatPrecedent) => ({ ...etatPrecedent, [champ]: valeur }));
    if (statut === "echec") {
      setErreurs(valider({ ...valeurs, [champ]: valeur }));
    }
  }

  async function soumettre(evenement) {
    evenement.preventDefault();
    const trouvees = valider(valeurs);
    setErreurs(trouvees);
    if (Object.keys(trouvees).length > 0) {
      setStatut("echec");
      return;
    }
    setStatut("envoi");
    try {
      await ajouterInscription(valeurs);
      setStatut("succes");
      setValeurs(valeursInitiales);
      setTimeout(() => navigate("/liste"), 600);
    } catch (e) {
      setStatut("echec");
      setErreurs({ global: e.message });
    }
  }

  return (
    <form onSubmit={soumettre} noValidate>
      {erreurs.global && <p role="alert">{erreurs.global}</p>}
      <label htmlFor="nom">Nom complet</label>
      <input
        id="nom"
        value={valeurs.nom}
        onChange={(e) => changer("nom", e)}
        aria-invalid={Boolean(erreurs.nom) || undefined}
        aria-describedby={erreurs.nom ? "erreur-nom" : undefined}
      />
      {erreurs.nom && <p id="erreur-nom" role="alert">{erreurs.nom}</p>}

      <label htmlFor="courriel">Adresse électronique</label>
      <input
        id="courriel"
        type="email"
        value={valeurs.courriel}
        onChange={(e) => changer("courriel", e)}
        aria-invalid={Boolean(erreurs.courriel) || undefined}
        aria-describedby={erreurs.courriel ? "erreur-courriel" : undefined}
      />
      {erreurs.courriel && (
        <p id="erreur-courriel" role="alert">{erreurs.courriel}</p>
      )}

      <button type="submit" disabled={statut === "envoi"}>
        {statut === "envoi" ? "Envoi en cours…" : "Envoyer mon inscription"}
      </button>
      {statut === "succes" && <p role="status">Inscription enregistrée.</p>}
    </form>
  );
}
```

La liste referme le cycle. Son effet se déclenche au montage, protège ses réponses avec un drapeau d'ignoré, distingue les quatre états et propose le bouton de réessai dans le seul cas qui le justifie. Notez que le rechargement se fait aussi après un envoi réussi : l'écran liste se relance à chaque arrivée, ce qui suffit ici ; si la liste devait se rafraîchir sans quitter l'écran, vous extrairiez une fonction de reprise appelée par le bouton et par l'effet de montage, plutôt que de dupliquer le code.

```jsx
function ListeInscrits() {
  const [statut, setStatut] = useState("chargement");
  const [inscrits, setInscrits] = useState([]);

  useEffect(() => {
    let ignore = false;
    async function charger() {
      setStatut("chargement");
      try {
        const liste = await getInscrits();
        if (!ignore) {
          setInscrits(liste);
          setStatut(liste.length === 0 ? "vide" : "succes");
        }
      } catch (e) {
        if (!ignore) setStatut("erreur");
      }
    }
    charger();
    return () => {
      ignore = true;
    };
  }, []);

  if (statut === "chargement") return <p role="status">Chargement…</p>;
  if (statut === "erreur")
    return (
      <div>
        <p role="alert">La liste n'a pas pu être chargée.</p>
        <button onClick={() => setStatut("chargement")}>Réessayer</button>
      </div>
    );
  if (statut === "vide") return <p>Aucune inscription pour le moment.</p>;
  return (
    <ul>
      {inscrits.map((p) => (
        <li key={p.id}>
          {p.nom} — {p.courriel}
        </li>
      ))}
    </ul>
  );
}
```

Voici la liste de contrôle à exécuter avant de considérer le projet comme terminé. Frappez chaque adresse à la main dans la barre du navigateur, y compris une fausse : les quatre cas doivent donner un écran. Soumettez le formulaire vide, puis mal formé, puis correct, et confirmez que la page ne se recharge jamais. Chargez la liste avec une source qui échoue, par exemple en modifiant la fonction locale pour qu'elle rejette, et vérifiez que le message et le bouton réessai apparaissent. Parcourez enfin toute l'application au clavier : les liens actifs se distinguent, les messages d'erreur sont annoncés, et le focus reste utilisable après chaque changement d'écran.

- Assemblez d'abord la table des routes et testez les quatre cas d'adresse.
- Écrivez le formulaire avec l'objet de valeurs, la validation pure et l'état d'envoi.
- Reliez chaque message à son champ par l'attribut de description associée.
- Protégez le chargement de la liste avec un drapeau d'ignoré et un bouton réessai.
- Testez le pire cas, une source qui échoue, avant de tester le meilleur.
- Parcourez l'ensemble au clavier avant de déclarer le projet fini.
$lesson$),
  ('web-c7-p14', 'web-c7', 14, $lesson$À retenir$lesson$, $lesson$
- Une application React garde un seul document chargé ; le routeur décide de l'écran d'après l'URL.
- L'URL reste la source de vérité : partager, rafraîchir et revenir en arrière donnent le même écran.
- Le chemin après l'almohadille fonctionne sans serveur configuré ni outil de compilation.
- La table des routes se déclare une fois ; le chemin étoile absorbe les adresses inconnues.
- Un segment variable porte l'identifiant ; l'écran le lit avec la fonction de paramètres.
- Une route parente porte un composant de disposition et accueille ses routes filles.
- Le lien de correspondance marque la branche active, visuellement et pour les technologies d'assistance.
- Un formulaire contrôlé range chaque valeur dans l'état, la reflète dans le champ et la reçoit par l'événement de changement.
- Un objet unique pour toutes les valeurs simplifie validation, comparaison et remise à zéro.
- La validation est une fonction pure, appelable à la soumission, après la soumission et pendant le rendu.
- Un champ en erreur porte l'état invalide, référence son message et lui donne un rôle d'alerte.
- Le bouton reste actif pour expliquer, et se désactive seulement pendant l'envoi réel.
- La soumission commence par intercepter le rechargement par défaut, puis bascule dans l'état occupé.
- Les données ne sont vidées qu'après un envoi réussi ; un échec conserve la saisie.
- Un effet s'exécute après le rendu, avec un tableau de dépendances vide au montage.
- Une fonction d'effet ne peut pas être asynchrone : on définit la fonction asynchrone à l'intérieur puis on l'appelle.
- Chaque effet rend une fonction de nettoyage qui s'exécute avant le tour suivant et au démontage.
- Une réponse tardive est annulée par un contrôleur d'annulation ou invalide par un drapeau d'ignoré.
- Un écran décrit quatre états : chargement, erreur, vide, succès, chacun avec son affichage et son action.
- fetch ne rejette pas quand le serveur refuse : vérifiez le code de réponse avant de convertir le corps.
- Enfermez le réseau dans un mini-client aux fonctions nommées d'après le métier, remplaçable sans toucher aux écrans.
$lesson$),
  ('web-c7-p15', 'web-c7', 15, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : écrire des liens qui pointent vers des fichiers séparés et recharger la page à chaque clic → Correction : utilisez le composant de lien du routeur, qui change l'adresse sans recharger le document.
- Piège : oublier la route étoile et obtenir un écran blanc sur une adresse fautive → Correction : ajoutez la route qui attrape tout et renvoie vers la page quatre cent quatre.
- Piège : oublier l'écran d'accueil dans la table des routes → Correction : déclarez explicitement le chemin racine, sinon l'application s'ouvre sur rien.
- Piège : appeler la fonction de déplacement pendant le rendu du composant → Correction : appelez-la depuis un gestionnaire d'événement ou un effet.
- Piège : laisser un champ sans attribut de valeur et croire que le formulaire est contrôlé → Correction : la valeur vient toujours de l'état, l'événement ne fait que la rapporter.
- Piège : conserver l'événement de changement pour l'utiliser plus tard → Correction : extrayez la valeur immédiatement, l'événement est recyclé après l'appel.
- Piège : désactiver le bouton d'envoi tant que le formulaire est invalide → Correction : gardez-le actif, validez au clic et affichez les messages reliés aux champs.
- Piège : marquer la fonction d'effet comme asynchrone → Correction : définissez une fonction asynchrone à l'intérieur de l'effet et appelez-la.
- Piège : oublier une dépendance dans le tableau et observer un rendu périmé → Correction : listez toute valeur extérieure qui peut changer et activez la règle d'exhaustivité.
- Piège : laisser un minuteur ou un écouteur tourner après le départ de l'écran → Correction : rendez une fonction de nettoyage qui détruit tout ce que l'effet a créé.
- Piège : laisser une réponse réseau écrire dans un composant démonté → Correction : annulez la requête avec le contrôleur d'annulation ou invalidez la réponse avec un drapeau.
- Piège : traiter le vide comme une erreur ou afficher du vide pendant le chargement → Correction : distinguez les quatre états et donnez à chacun son message et son action.
- Piège : faire confiance à la promesse de fetch sans regarder le code de réponse → Correction : vérifiez le code, puis convertissez le corps en objet.
- Piège : renvoyer un état interne partagé et laisser le composant le modifier → Correction : copiez les listes renvoyées et mettez toujours à jour l'état par recopie.
$lesson$),
  ('web-c7-p16', 'web-c7', 16, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation du routeur est la première adresse à conserver. Elle décrit la table des routes, les liens de correspondance, les paramètres d'URL, la navigation programmatique et le chargement de données, avec pour chaque page un exemple exécutable et les points d'attention d'accessibilité. Commencez par https://reactrouter.com et suivez le guide de démarrage avant de plonger dans les pages de référence : la lecture sera bien plus efficace si vous avez d'abord écrit une application complète avec les notions du chapitre.

La documentation officielle de React reste la seconde pièce maîtresse. Les pages consacrées aux effets décrivent le tableau des dépendances, la fonction de nettoyage, la façon de synchroniser un composant avec un système externe et les pièges à éviter ; les pages sur les formulaires montrent la gestion de l'état, la remise à zéro et la validation. On les trouve sur https://react.dev, avec en particulier la section des guides et la référence des hooks, qui signale systématiquement les cas où un effet n'est pas la bonne solution. Relisez cette référence au moins une fois après avoir écrit votre premier effet : beaucoup de détails n'ont de sens qu'après coup.

Enfin, le réseau mérite sa documentation propre. L'API de fetch, ses promesses, son contrôleur d'annulation et la notion de réponse exploitable seulement après vérification du code sont détaillées sur https://developer.mozilla.org, dans la rubrique des références du Web. Prenez aussi quelques minutes pour lire la page consacrée à la gestion des adresses et des paramètres d'URL, qui vous sera utile dès que votre application devra conserver un filtre ou une page dans l'adresse. Comme pour les chapitres précédents, gardez ces adresses sous la main et revenez-y au moment où une question précise se pose, plutôt que de les parcourir d'un bout à l'autre.
$lesson$),
  ('web-c7-p17', 'web-c7', 17, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
Vous disposez maintenant du trio qui fait fonctionner une application : une navigation déclarée et testable, des formulaires reliés à l'état et validés avant l'envoi, des données chargées au montage puis protégées contre les réponses tardives. L'exercice qui accompagne ce chapitre vous demande de réécrire cette application sans outil de compilation, avec un routeur de fragments d'adresse, un état global et des fonctions de rendu : les commentaires du squelette relèvent explicitement chaque étape à la notion React correspondante, de sorte que vous puissiez comparer ligne à ligne ce que le routeur fait pour vous et ce que vous écrivez à la main quand il n'y a pas de routeur. C'est dans cet écart que la compréhension se fixe. Le quiz de quatre questions, lui, vérifie en quelques minutes les règles les plus souvent oubliées.

Passé cet exercice, deux directions s'ouvrent à vous. La première consiste à consolider la qualité : mémoriser les états d'un écran, les fermer dans un seul composant de rendu, écrire systématiquement la fonction de nettoyage, et tester d'abord le chemin du plomb. La seconde consiste à aller plus loin dans l'architecture : extraire les hooks personnalisés pour réutiliser le chargement d'une liste sur plusieurs écrans, ajouter la persistance pour que les inscriptions survivent à un rafraîchissement, puis relier le mini-client à un vrai service. Dans les deux cas, gardez le projet de la Médiathèque des Lilas sous la main : c'est lui qui vous dira, par un écran qui se remplit enfin ou un message d'erreur qui s'affiche au bon moment, que la leçon est réellement acquise.
$lesson$);

insert into public.chapter_pages (id, chapter_id, position, title, content) values
  ('web-c8-p1', 'web-c8', 1, $lesson$Du prototype au produit : ce qui change$lesson$, $lesson$
Vous arrivez au dernier chapitre du parcours Développement web moderne, et celui-ci a une couleur particulière : celle du passage de l'atelier à la vitrine. Tout ce que vous avez construit jusqu'ici servait à apprendre ; ce chapitre sert à livrer. La différence paraît immense, et pourtant elle se joue sur un nombre étonnamment restreint de détails : des métadonnées bien écrites, des images d'un poids raisonnable, un fichier de consignes pour les robots, un certificat actif, une commande de déploiement, et une liste de vérifications que vous exécutez dans le même ordre à chaque fois. Aucune de ces étapes n'exige une nouvelle technologie ; toutes exigent une discipline. C'est précisément cette discipline qui sépare un projet d'entraînement d'un site réellement en ligne, accessible à des personnes que vous ne connaîtrez pas, sur des appareils que vous n'avez pas, à des heures où vous dormirez.

Le fil rouge vous accompagne depuis le premier jour : le site de l'atelier de la Médiathèque des Lilas. Au chapitre précédent du parcours, vous en avez écrit le squelette sémantique : un en-tête, une navigation, un contenu principal, des sections titrées, des images décrites, un formulaire accessible. Puis vous l'avez habillé de styles, vous lui avez donné du comportement avec le DOM, vous lui avez fait absorber des données, vous avez appris à versionner vos fichiers avec Git, à partager votre travail, à installer des bibliothèques avec npm, et enfin à reconstruire certaines parties de l'interface en React. Le site fonctionne sur votre machine : vous double-cliquez sur un fichier, ou vous lancez un serveur de développement, et tout semble prêt. Il reste pourtant un gouffre entre cette page qui marche pour vous et une page qui marche pour tout le monde, en permanence, sans votre ordinateur. Ce chapitre est le pont sur ce gouffre.

Les objectifs sont au nombre de trois, et vous les verrez dans cet ordre. Le premier consiste à préparer la mise en production : transformer un prototype tolérant en un produit exigeant, en le passant au crible d'une liste de contrôle qui ne laisse rien passer. Le deuxième consiste à améliorer les performances et le référencement : rendre la page rapide à ouvrir, compréhensible par les moteurs de recherche et visible dans les résultats, sans recourir à des techniques obscures. Le troisième consiste à déployer le projet en ligne, c'est-à-dire à le mettre à la disposition du public sur une adresse réelle, avec un certificat de sécurité, un nom de domaine, et une procédure de mise à jour que vous pourrez rejouer sans trembler.

La manière d'aborder ce chapitre mérite un mot, parce qu'elle diffère des précédents. Ici, peu de concepts neufs : la plupart des règles que vous allez lire sont anciennes, simples et vérifiables en quelques secondes. Ce qui change, c'est la sommet de rigueur attendue. On ne vous demandera pas de comprendre une nouveauté, on vous demandera de ne rien oublier. C'est pour cela que ce chapitre est truffé de listes de contrôle, de tableaux et de fichiers de configuration à copier : un site se livre avec des checklists, un peu comme un pilote décolle avec une check-list, non parce qu'il a oublié comment piloter, mais parce que la régularité vaut mieux que la mémoire. Gardez ce réflexe sous la main : le fichier de vérification que vous construirez dans les pages qui suivent vous servira longtemps après la fin du parcours, sur chacun de vos futurs projets.



Un prototype est un outil de démonstration : il prouve qu'une idée fonctionne, dans les conditions que vous avez choisies. Un produit est un service : il répond à des personnes qui n'ont rien demandé de particulier, qui arrivent par hasard, qui utilisent un appareil modeste, une connexion irrégulière, un navigateur mis à jour il y a deux ans, et qui partiront définitivement si la page met trois secondes à afficher quoi que ce soit. Le code peut être identique dans les deux cas ; ce qui change, c'est le contrat. En local, votre contrat est tacite : vous savez où sont les fichiers, vous savez lancer le serveur, vous savez ouvrir la console quand quelque chose cloche. En production, ce contrat disparaît : personne ne saura que la feuille de style s'appelle autrement que par son chemin, personne n'aura votre console, personne ne corrigera le fichier à votre place.

Le premier écart concret est l'environnement d'exécution. En développement, beaucoup de projets s'ouvrent directement depuis le disque, ou sur une adresse réservée à votre machine ; certains navigateurs acceptent alors des raccourcis qui ne fonctionnent nulle part ailleurs. En ligne, tout passe par le protocole sécurisé, depuis une adresse publique, vers un dossier précis du serveur, avec des droits d'accès définis. Les chemins qui fonctionnaient chez vous, parce que les fichiers étaient voisins, deviennent des chemins cassés dès que la structure du dossier diffère. La règle d'or reste celle que vous avez apprise au premier chapitre : les liens internes sont relatifs, les adresses externes sont complètes, et les noms de fichiers sont écrits sans accent, sans espace, en minuscules, parce qu'un serveur Linux fait la différence entre majuscules et minuscules là où votre ordinateur ne la fait pas.

Le deuxième écart est celui des données. Votre prototype lit probablement un fichier local, une liste codée en dur ou un service simulé. Un produit doit décider d'où viennent ses données, comment elles sont validées, que faire quand le service distant ne répond pas, et comment afficher un message compréhensible plutôt qu'une page blanche. Le chapitre sur les données vous a montré comment récupérer une ressource distante ; ce chapitre vous rappelle qu'une ressource distante peut échouer, et qu'un site qui affiche une erreur technique à un lecteur n'est pas un site livré. Prévoyez systématiquement une alternative : un message de secours, une donnée de repli, un état vide soigné.

Le troisième écart est celui des secrets. En local, une clé d'accès à un service de test copiée dans un fichier pose peu de problèmes. Dès que le dépôt devient public, ou que le dossier du site est téléchargeable, cette même clé donne à n'importe qui un accès à votre compte, à vos données, parfois à celles de vos utilisateurs. La règle est sans appel : aucun secret ne vit jamais dans un fichier destiné à être publié. Les clés vivent dans des variables d'environnement, référencées par nom dans le code, renseignées séparément sur chaque machine et sur la plateforme d'hébergement.

Le quatrième écart est la maintenance. Un projet personnel n'a pas d'avenir prévu ; un produit en a un. Quelqu'un devra corriger une coquille dans trois mois, ajouter une date d'atelier, remplacer une image, corriger un lien mort. Si la seule personne qui sait où se trouve l'information, c'est vous, et si le site n'a pas de dépôt versionné, cette corrigera sera un calvaire. C'est la raison profonde pour laquelle Git fait partie du parcours : le dépôt n'est pas un exercice scolaire, c'est la mémoire du projet.

Un dernier écart, plus subtil, est celui de la tolérance aux erreurs. Votre navigateur de développement affiche un avertissement jaune quand un identifiant est dupliqué ; le lecteur final ne voit rien et subit simplement un comportement étrange. En local, une image oubliée se remplace par une icône ; en production, elle se remplace par un trou dans la page et par une description absente pour les personnes qui n'utilisent pas l'écran. Pensez à votre site comme à un objet qui doit survivre à vos absences : si une pièce manque, l'ensemble doit rester utilisable.

- En local, vous connaissez les fichiers ; en ligne, seuls les chemins publics existent.
- Liens internes relatifs, noms de fichiers sans accent ni espace, sensibilité à la casse respectée.
- Toute donnée distante peut échouer : prévoyez un état de repli lisible.
- Aucun secret dans le dépôt ni dans le dossier publié : utilisez des variables d'environnement.
- Un site livré est un site maintenable : dépôt versionné, structure prévisible, commentaires utiles.
- Testez sur un appareil qui n'est pas le vôtre, avec un réseau ralenti volontairement.
$lesson$),
  ('web-c8-p2', 'web-c8', 2, $lesson$La checklist avant livraison$lesson$, $lesson$
Il existe une idée reçue tenace selon laquelle un développeur expérimenté n'a pas besoin de liste de contrôle, parce qu'il connaît toutes les étapes par cœur. L'expérience des industries où l'erreur coûte cher, l'aviation et la médecine notamment, a montré exactement l'inverse : plus la tâche est familière, plus la checklist protège, parce que le cerveau d'un expert passe en pilote automatique et saute les étapes qu'il juges évidentes. Votre site n'aura pas la gravité d'un atterrissage, mais le principe est le même : relire systématiquement, dans le même ordre, transforme une inspection anxieuse en une procédure calme et reproductible.

Une checklist de livraison se compose de familles de points, et chaque famille correspond à une promesse faite à un type d'utilisateur. La famille structure et contenu promet au lecteur qu'il trouvera une page cohérente, titrée, sans texte de remplissage. La famille performance promet au visiteur pressé qu'il verra quelque chose rapidement, même sur une connexion moyenne. La famille accessibilité promet aux personnes qui utilisent un clavier ou un lecteur d'écran qu'elles pourront réellement accomplir la tâche pour laquelle elles sont venues. La famille référencement technique promet au moteur de recherche qu'il pourra comprendre, explorer et présenter la page. La famille sécurité promet à tout le monde que la connexion est chiffrée et que rien de sensible ne fuit. Enfin, la famille projet promet à votre futur vous-même que l'ensemble est reproductible et versionné.

Le tableau ci-dessous constitue le squelette de cette checklist pour le site de l'atelier. Recopiez-le dans un fichier de votre dépôt, par exemple au format Markdown, et complétez-le au fil des chapitres : chaque ligne doit être vérifiable objectivement, sans interprétation, de sorte que la réponse soit toujours oui ou non.

| Domaine | Point à vérifier | Comment le vérifier |
| --- | --- | --- |
| Structure | Un seul titre principal et aucun niveau de titre sauté | Parcourir l'arbre des titres de chaque page |
| Métadonnées | Titre, description et langue présents sur chaque page | Lire le code source de l'en-tête technique |
| Contenu | Aucun texte de remplissage ni lien du type cliquez ici | Relecture intégrale page par page |
| Images | Dimensions déclarées et chargement différé hors écran | Inspecter les attributs des images |
| Performance | Page d'accueil légère et affichage initial rapide | Mesurer avec un outil de performance |
| Accessibilité | Parcours complet au clavier avec focus visible | Débrancher la souris et tout refaire |
| Accessibilité | Contrastes suffisants sur le texte et les boutons | Vérifier avec un calculateur de contraste |
| Référencement | Fichier de consignes, plan du site et lien canonique en place | Lire les fichiers techniques et l'en-tête |
| Sécurité | Protocole sécurisé actif, en-têtes définis, aucun secret publié | Inspecter les en-têtes réseau et le dépôt |
| Projet | Aucune erreur dans la console et liens internes valides | Naviguer manuellement sur l'ensemble |

L'usage de cette checklist mérite trois conseils concrets. Premièrement, exécutez-la dans l'ordre, toujours le même, parce que l'ordre crée de la mémoire musculaire et évite les allers-retours. Deuxièmement, séparez ce qui est automatisable de ce qui ne l'est pas : le poids des images, les en-têtes de sécurité et la présence des métadonnées se contrôlent en quelques secondes avec des outils, tandis que le parcours au clavier, la compréhension des libellés et la clarté du contenu exigent un humain. Troisièmement, ne cochez jamais une ligne que vous n'avez pas vérifiée : une checklist bâclée est pire qu'aucune, car elle crée une confiance injustifiée.

Un réflexe complémentaire, souvent négligé, consiste à conserver les résultats des mesures à côté de la checklist. Notez le poids de la page d'accueil, la date du dernier passage de l'outil de performance et le nombre d'alertes restantes. Ces chiffres ne servent pas à se juger, ils servent à détecter une régression : si votre page passe de 900 kilo-octets à 2,4 mégaoctets après l'ajout d'une nouvelle photographie, vous le verrez immédiatement, alors que la sensation subjective de lenteur, elle, arrive toujours trop tard.

- Exécutez la checklist avant chaque mise en ligne, dans le même ordre à chaque fois.
- Chaque ligne répond par oui ou non : aucune zone grise, aucun peut-être.
- Automatisez le mesurable, gardez l'humain pour le clavier, les contrastes et le contenu.
- Conservez les mesures passées pour repérer les régressions.
- Versionnez la checklist dans le dépôt : elle fait partie du projet.
- Ajoutez une ligne seulement quand vous avez déjà oublié ce qu'elle demandait.
$lesson$),
  ('web-c8-p3', 'web-c8', 3, $lesson$Performances : poids des images, format moderne, chargement différé$lesson$, $lesson$
La performance d'une page web se résume d'abord à une question de poids et d'ordre : combien d'octets le visiteur doit-il télécharger, et dans quel ordre il les reçoit-il avant de voir quelque chose d'utile. Sur un réseau filaire, ces questions paraissent triviales ; sur un téléphone en déplacement, elles deviennent décisives. La majorité des pages que vous consultez chaque jour transportent des images, et les images représentent dans la pratique la plus grande part du poids d'une page. Un visuel d'affiche exporté depuis un appareil photo peut peser plusieurs mégaoctets alors qu'il ne s'affiche que sur une largeur de 400 pixels : le visiteur paie une qualité qu'il ne verra jamais, sur un réseau qu'il paie lui aussi.

Quatre techniques, à appliquer dans cet ordre, résolvent l'essentiel. La première est la compression : réduisez la qualité de l'image jusqu'à ce que la différence soit invisible à l'écran, en surveillant le poids obtenu. La deuxième est le format : le JPEG et le PNG restent universels, mais des formats modernes comme le WebP offrent un poids nettement inférieur à qualité égale, et sont désormais acceptés partout ; l'AVIF va encore plus loin pour les photographies. Le plus simple est de fournir les deux et de laisser le navigateur choisir, grâce à la balise de contenu picture. La troisième est la déclaration des dimensions, qui ne réduit pas le poids mais empêche le décalage du texte pendant le chargement. La quatrième est le chargement différé, qui ordonne au navigateur de ne télécharger l'image que lorsqu'elle s'approche de la zone visible.

```html
<figure class="visuel-vedette">
  <picture>
    <source type="image/webp"
            srcset="images/atelier-480.webp 480w,
                    images/atelier-960.webp 960w"
            sizes="(max-width: 700px) 100vw, 720px">
  <img src="images/atelier-960.jpg"
       srcset="images/atelier-480.jpg 480w,
               images/atelier-960.jpg 960w"
       sizes="(max-width: 700px) 100vw, 720px"
       width="960" height="600"
       loading="lazy" decoding="async"
       alt="Douze participants devant un écran de projection">
  <figcaption>Atelier précédent, salle informatique.</figcaption>
</figure>
```

L'attribut de chargement différé comporte une exception importante : il ne doit pas s'appliquer à l'image de tête, c'est-à-dire au visuel que le visiteur doit voir dès l'arrivée sur la page. Cette image-là a intérêt à être précoce, petite, et à déclarer ses dimensions pour que l'espace lui soit réservé immédiatement. Pour tout le reste, images de galerie, portraits d'intervenants, captures d'écran, le chargement différé est votre allié : sur une longue page illustrée, la différence se compte en mégaoctets évités et en secondes gagnées.

Au-delà des images, deux postes de poids méritent votre attention. Les feuilles de style et les scripts sont le second poste : une feuille de style minifiée, débarrassée des commentaires et des espaces inutiles, pèse moins et se transmet plus vite ; un script placé dans l'en-tête bloque l'analyse du document, alors que la même feuille ou le même script différé laisse le contenu s'afficher sans attendre. Le troisième poste est la bibliothèque que vous avez installée pour résoudre un problème rencontré une seule fois et qui accompagnera désormais chaque page. Posez la question pour chaque dépendance, pour chaque image et pour chaque police : ai-je réellement besoin de cet élément, à cette taille, dès cet instant ?

- Identifiez d'abord le plus gros fichier de la page : c'est souvent une image.
- Fournissez un format moderne avec repli, grâce à la balise picture et à ses sources.
- Déclarez toujours largeur et hauteur pour éviter le décalage du texte.
- Chargez en différé tout ce qui se trouve sous la ligne de flottaison, sauf l'image de tête.
- Retardez les scripts non essentiels et supprimez les dépendances inutiles.
- Mesurez avant et après chaque optimisation : une amélioration non mesurée est une opinion.
$lesson$),
  ('web-c8-p4', 'web-c8', 4, $lesson$Le rendu : CSS critique, polices, mise en cache$lesson$, $lesson$
Afficher une page n'est pas un geste instantané : le navigateur doit analyser le document, construire son arbre, calculer le style de chaque élément, disposer les blocs, puis peindre les pixels à l'écran. Chacune de ces étapes dépend du contenu qu'il a déjà reçu. Tant que la feuille de style principale n'est pas arrivée, le navigateur affiche le contenu brut, sans mise en forme, puis la feuille arrive et tout saute d'un coup : c'est ce qu'on appelle le flash de contenu non stylé, une expérience familière qui donne l'impression d'un site bâclé, même quand il est parfaitement construit.

Le remède porte un nom : le CSS critique. Il consiste à identifier les styles nécessaires au rendu du haut de page, c'est-à-dire la partie visible immédiatement sans défilement, à les écrire directement dans l'en-tête technique, puis à charger le reste de la feuille de style de manière différée. Le visiteur voit donc une page correctement habillée dès les premiers instants, sans attendre le fichier externe complet. Pour un site statique comme celui de l'atelier, le CSS critique tient en quelques règles : couleurs, typographie de base, largeur du contenu, espacement de l'en-tête et apparence des boutons.

```html
<head>
  <meta charset="utf-8">
  <title>Ateliers de la Médiathèque des Lilas</title>
  <style>
    :root { --encre: #1a1a2e; --papier: #ffffff; --accent: #005f73; }
    body { margin: 0; font-family: system-ui, sans-serif; color: var(--encre);
           background: var(--papier); line-height: 1.6; }
    .bandeau { padding: 1rem; background: var(--accent); color: #fff; }
    main { max-width: 46rem; margin: 0 auto; padding: 1rem; }
    a:focus-visible, button:focus-visible { outline: 3px solid #e07a00; }
  </style>
  <link rel="stylesheet" href="styles/site.css" media="print" onload="this.media='all'">
</head>
```

Les polices méritent une attention particulière, parce qu'elles sont souvent la seconde source d'attente après les images. Trois réflexes suffisent. Le premier est le sous-ensemble : une police latine complète contient des milliers de caractères, dont vous n'utilisez qu'une fraction ; restreindre la police aux caractères réellement employés réduit son poids de moitié. Le deuxième est la déclaration d'intention : dire au navigateur que la police sera probablement utilisée, grâce à la préconnexion, lui fait gagner le temps de négocier la connexion avant d'en avoir besoin. Le troisième est l'affichage de secours : pendant que la police se charge, le navigateur affiche une police système, de sorte que le texte est toujours lisible plutôt qu'invisible.

```html
<link rel="preconnect" href="https://fonts.example.org" crossorigin>
<link rel="preload" as="style" href="polices/atelier-display.woff2">
<style>
  @font-face {
    font-family: "Atelier Display";
    src: url("polices/atelier-display.woff2") format("woff2");
    font-weight: 700;
    font-display: swap;
  }
  h1 { font-family: "Atelier Display", system-ui, sans-serif; }
</style>
```

La mise en cache constitue le troisième levier, et c'est celui dont le visiteur ressent le plus nettement l'effet lors d'une seconde visite. Lorsqu'un fichier arrive avec des en-têtes qui autorisent son stockage, le navigateur le conserve ; à la visite suivante, il le relit du disque local au lieu de le redemander au serveur, et la page s'affiche presque instantanément. Trois conditions rendent cette mécanique fiable. Premièrement, les fichiers qui changent doivent changer de nom, ou du moins d'adresse : tant que l'adresse reste identique, un navigateur conservateur peut servir une version périmée. Deuxièmement, les ressources stables, polices et images dont le contenu ne varie pas, peuvent être gardées longtemps. Troisièmement, les réponses du serveur doivent déclarer une durée de validité, sinon le navigateur ne garde rien.

Un piège fréquent mérite d'être signalé : la mise en cache aidant, vous corrigerez parfois une erreur qui refuse de disparaître. Avant de soupçonner votre code, pensez à recharger la page en contournant le cache, puis à vérifier ce que dit réellement le serveur sur les en-têtes de réponse. Beaucoup de débutants perdent une heure entière à corriger un fichier déjà corrigé, dont la version obsolète était simplement relue dans le stockage local du navigateur.

- Identifiez les styles du haut de page et intégrez-les dans l'en-tête technique.
- Chargez la feuille de style principale de manière différée, sans bloquer le rendu.
- Restreignez les polices aux caractères utilisés et autorisez l'affichage de secours.
- Préconnectez les domaines distants avant d'en avoir besoin.
- Faites varier l'adresse d'un fichier modifié pour invalider le cache.
- Déclarez des durées de validité sur les ressources stables.
$lesson$),
  ('web-c8-p5', 'web-c8', 5, $lesson$SEO : titres, descriptions, données structurées, sitemap$lesson$, $lesson$
Le référencement organique n'a rien de magique : c'est la conséquence d'un document que la machine sait lire. Un robot d'indexation reçoit votre page, l'analyse, en extrait la langue, le titre, la hiérarchie des idées, les liens, puis range le résultat dans un catalogue. Plus votre document est limpide, plus la restitution est fidèle. La première pierre est le titre de page, celui qui apparaît dans l'onglet du navigateur et dans le résultat de recherche. Il doit être unique sur le site, dire de quoi parle la page avec les mots que l'utilisateur emploie, et tenir dans une longueur raisonnable : un titre tronqué par le moteur ou un titre identique sur trente pages annule son utilité.

La description mérite le même soin, avec une différence de nature : alors que le titre classe, la description convainc. Elle est affichée sous le titre dans les résultats, et c'est elle qui décide, dans neuf cas sur dix, d'un clic ou d'un passage au résultat suivant. Écrivez-la comme une phrase d'accueil, avec une promesse concrète et un appel à l'action naturel, en évitant la répétition mécanique des mêmes mots que dans le titre. Elle n'affecte pas directement le classement, mais elle affecte directement le taux de clic, et le moteur observe ce taux.

```html
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ateliers numériques — Médiathèque des Lilas</title>
  <meta name="description" content="Ateliers gratuits de prise en main de l'ordinateur et du web, chaque samedi à la Médiathèque des Lilas. Inscription en ligne.">
  <meta name="robots" content="index, follow">
  <meta name="author" content="Médiathèque des Lilas">
  <link rel="canonical" href="https://mediatheque-des-lilas.example/ateliers/">
</head>
```

La seconde pierre est la donnée structurée, un mécanisme qui permet de décrire le contenu avec un vocabulaire compris par les moteurs, sous forme de paires clé-valeur insérées dans la page. Concrètement, on écrit un bloc de données au format JSON, déclaré par un script, qui raconte ce que la page contient : un événement avec sa date, son lieu et son organisateur ; une organisation avec son nom et son adresse ; une page d'article avec son auteur. Ces informations ne changent pas l'affichage, mais elles permettent au moteur d'afficher une fiche enrichie dans les résultats, ce qui augmente la visibilité et réduit le risque d'incompréhension.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "Atelier : créer sa première page web",
  "startDate": "2026-10-17T14:00",
  "endDate": "2026-10-17T17:00",
  "eventStatus": "https://schema.org/EventScheduled",
  "location": {
    "@type": "Place",
    "name": "Médiathèque des Lilas",
    "address": "1 rue Gabriel Péri, 93260 Les Lilas"
  },
  "organizer": {
    "@type": "Organization",
    "name": "Médiathèque des Lilas"
  }
}
</script>
```

La troisième pierre est le plan du site, un fichier qui liste les adresses publiques de votre site pour aider le robot à les découvrir toutes, surtout lorsqu'une page n'est reliée par aucun lien. Il se rédige dans un format très simple : pour chaque adresse, la priorité d'exploration et la fréquence de mise à jour estimées. Ce fichier se déclare enfin dans le fichier de consignes que vous verrez plus bas, afin que le robot sache où le trouver. Notez qu'un plan du site ne remplace pas les liens internes : il complète un maillage que la structure du site doit déjà assurer.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://mediatheque-des-lilas.example/</loc>
    <lastmod>2026-10-04</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://mediatheque-des-lilas.example/ateliers/</loc>
    <lastmod>2026-10-04</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
```

Derrière ces techniques se tient une vérité simple que ce parcours a martelée depuis le premier chapitre : la structure sémantique que vous avez écrite est elle-même du référencement. Les titres hiérarchisés, les descriptions d'images, les libellés de liens précis, les régions nommées, tout cela est lu et apprécie. Aucune astuce ne compensera un contenu pauvre ou dupliqué ; en revanche, un contenu utile, organisé clairement et correctement décrit, se classe naturellement avec le temps. Le rôle du référencement technique est d'ôter les obstacles, pas de fabriquer du mérite.

- Un titre unique et explicite par page, écrit avec les mots du public.
- Une description rédigée à la main qui donne envie de cliquer.
- Des données structurées pour les événements, l'organisation et les articles.
- Un plan du site à jour, déclaré dans le fichier de consignes.
- Des liens internes cohérents : le plan du site ne les remplace pas.
- Le contenu utile et la structure sémantique restent la base : l'optimisation retire des obstacles.
$lesson$),
  ('web-c8-p6', 'web-c8', 6, $lesson$Accessibilité : audit clavier, lecteur d'écran, contrastes$lesson$, $lesson$
L'accessibilité a ceci de particulier qu'elle ne se décrète pas : elle se vérifie, sur le site réel, avec les gestes de la personne à qui elle est destinée. Un site qui paraît parfaitement accessible à la souris peut s'avérer totalement infranchissable au clavier, et c'est l'une des découvertes les plus fréquentes des premiers audits. La raison tient à la construction même de l'interface : un gestionnaire d'événements qui réagit au clic n'a aucun équivalent automatique pour la touche d'activation, un style qui met en évidence un élément survolé ne s'applique pas à l'élément atteint au clavier, et une zone de contenu qui apparaît par-dessus la page peut capturer le focus sans offrir aucun moyen de s'en échapper.

L'audit au clavier est simple à mener et ne demande aucun outil. Débranchez la souris, rechargez la page, puis appuyez sur la touche de tabulation à partir du tout début. Chaque appui doit faire apparaître un indicateur de focus net, visible sur la couleur de fond que l'élément rencontre, et faire avancer la sélection dans l'ordre logique du visuel : d'abord le lien d'évitement, puis la navigation, puis le contenu principal, puis le pied de page. La touche d'activation doit ouvrir les menus, déplier les listes, soumettre les formulaires. Si la sélection disparaît, si elle saute une zone entière, si elle revient en haut de page sans raison, un utilisateur qui ne voit pas l'écran subira exactement le même trajet.

```css
/* Lien d'évitement : visible dès qu'il reçoit le focus */
.saut-contenu {
  position: absolute;
  left: -9999px;
  top: 0;
  background: #005f73;
  color: #ffffff;
  padding: 0.75rem 1rem;
  z-index: 100;
}
.saut-contenu:focus {
  left: 0;
}

/* Indicateur de focus franc, quel que soit le fond rencontré */
a:focus-visible,
button:focus-visible,
input:focus-visible,
summary:focus-visible {
  outline: 3px solid #e07a00;
  outline-offset: 2px;
}

/* Jamais de focus supprimé sans remplacement */
:focus:not(:focus-visible) {
  outline: none;
}
```

Le lecteur d'écran constitue le second temps de l'audit, et il est plus accessible qu'on ne le croit : tous les systèmes d'exploitation en fournissent un intégré, activable en permanence, désactivable tout aussi vite. Le geste le plus rentable consiste à écouter votre page plutôt qu'à la regarder. Annonce-t-on la langue, les régions, les titres dans l'ordre, le nombre d'éléments de chaque liste, le nom de chaque image, l'étiquette de chaque champ ? Une page dont la navigation se lit comme une suite de phrases compréhensibles est une page bien construite ; une page où l'on entend des adresses de fichiers et des bouts de phrases révèle des descriptions manquantes ou des libellés muets. Pour le site de l'atelier, écoutez surtout le formulaire d'inscription et la checklist interactive : ce sont les deux endroits où la parole compte vraiment.

Le contraste est le troisième volet, et c'est souvent celui où le design fait défaut. La règle de référence impose un rapport d'au moins quatre virgule cinq pour un texte courant, et trois pour un texte de grande taille ainsi que pour les composants d'interface comme les bordures de champs ou les boutons. L'œil fatigué, l'écran en plein soleil, le vieillissement de la vue : autant de situations où un gris clair sur fond blanc rend un texte illisible alors qu'il semblait élégant à l'écran de votre bureau. Vérifiez les couleurs avant de les arrêter, et non après, parce que corriger une palette entière une fois le site assemblé est un travail considérable.

Il faut enfin garder une idée juste de ce que les outils automatiques peuvent faire. Un analyseur d'accessibilité détecte en quelques secondes les images sans description, les champs sans étiquette, les contrastes manifestement insuffisants, les titres manquants. En revanche, il ne dira jamais si le contenu se comprend, si l'ordre de tabulation a du sens, si un message d'erreur est explicite, si un bouton porte le bon nom. Comptez sur l'automatique pour le dépistage, comptez sur l'humain pour le jugement : les deux sont nécessaires, aucun des deux ne suffit seul.

- Débranchez la souris et parcourez toute la page avec la touche de tabulation.
- Vérifiez que le focus reste visible sur chaque fond de couleur rencontré.
- Écoutez la page avec un lecteur d'écran, en commençant par le formulaire.
- Contrôlez le rapport de contraste du texte courant, des boutons et des champs.
- Ne supprimez jamais un indicateur de focus sans lui en substituer un autre.
- Combinez analyse automatique et vérification humaine à chaque livraison.
$lesson$),
  ('web-c8-p7', 'web-c8', 7, $lesson$Référencement technique : robots.txt, canonical, Open Graph$lesson$, $lesson$
Le référencement technique s'occupe des fichiers et des balises qui orientent les robots et les réseaux sociaux, sans jamais toucher au contenu visible. Le premier de ces fichiers est le fichier de consignes destiné aux robots, qui se place à la racine du site et porte le nom robots.txt. Son rôle est d'indiquer aux explorateurs ce qu'ils ont le droit de parcourir et où trouver le plan du site. Attention à une confusion répandue : ce fichier donne des instructions, il ne protège rien. Une adresse que vous y excluez reste accessible à qui tape l'adresse directement ; si une page doit réellement être tenue à l'écart, elle doit être protégée autrement.

```txt
# Fichier de consignes pour les robots — https://mediatheque-des-lilas.example/robots.txt
User-agent: *
Disallow: /brouillon/
Disallow: /admin/
Allow: /

Sitemap: https://mediatheque-des-lilas.example/sitemap.xml
```

Le second outil est le lien canonique, qui répond à un problème de duplication. Une même page peut être atteinte sous plusieurs adresses distinctes : avec ou sans barre finale, en protocole non sécurisé comme en protocole sécurisé, avec des paramètres d'adresse ajoutés par une campagne de communication. Pour un moteur, ce sont autant d'adresses qui semblent présenter le même contenu, ce qui disperse l'attention et retarde l'indexation. Déclarer une adresse canonique unique dans l'en-tête de chaque page tranche la question : elle indique quelle adresse fait foi, et toutes les variantes renvoient vers elle.

Le troisième outil est l'ensemble de métadonnées de partage, qui décrit la façon dont la page apparaît lorsqu'un internaute la publie dans un message. Ces balises ne modifient ni le classement ni l'affichage de la page elle-même ; elles déterminent le titre, le résumé, l'image et l'adresse qui accompagneront le lien. Sans elles, le réseau social choisit au hasard une image de la page, souvent un visuel recadré ou une vignette de logo, et le résumé se réduit à une phrase coupée en plein milieu. Pour un site d'atelier, où l'image d'affiche porte l'essentiel de l'information, cette différence se voit immédiatement.

```html
<head>
  <meta charset="utf-8">
  <title>Ateliers numériques — Médiathèque des Lilas</title>
  <meta name="description" content="Ateliers gratuits de prise en main de l'ordinateur et du web, chaque samedi à la Médiathèque des Lilas.">
  <link rel="canonical" href="https://mediatheque-des-lilas.example/ateliers/">

  <meta property="og:type" content="website">
  <meta property="og:locale" content="fr_FR">
  <meta property="og:site_name" content="Médiathèque des Lilas">
  <meta property="og:title" content="Ateliers numériques — Médiathèque des Lilas">
  <meta property="og:description" content="Trois heures pour écrire sa première page web, en accès gratuit.">
  <meta property="og:url" content="https://mediatheque-des-lilas.example/ateliers/">
  <meta property="og:image" content="https://mediatheque-des-lilas.example/images/affiche-atelier.png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">

  <meta name="twitter:card" content="summary_large_image">
</head>
```

Trois vérifications terminent ce volet, toutes exécutables en moins d'une minute après la mise en ligne. Premièrement, ouvrez l'adresse du fichier de consignes depuis le domaine public et confirmez qu'il s'affiche bien, avec la bonne adresse de plan du site : un fichier resté sur votre machine n'existe pas pour le robot. Deuxièmement, vérifiez que chaque page principale déclare son adresse canonique complète et définitive, en protocole sécurisé, exactement telle qu'elle sera partagée. Troisièmement, soumettez l'adresse à l'outil de prévisualisation de partage du réseau social que vous visez : vous verrez en un instant la carte réelle, image et résumé compris, telle qu'elle apparaîtra.

- Le fichier de consignes s'instruit, il ne protège pas : c'est une orientation, pas une clé.
- Déclarez le plan du site dans ce même fichier, sous la forme Sitemap suivie de l'adresse.
- Une adresse canonique unique par page, en protocole sécurisé et sans variante.
- Renseignez les métadonnées de partage : titre, résumé, image de format paysage, adresse.
- Donnez à l'image de partage des dimensions stables pour éviter tout recadrage subtil.
- Contrôlez les trois points depuis le domaine public, jamais depuis votre machine.
$lesson$),
  ('web-c8-p8', 'web-c8', 8, $lesson$Sécurité de base : HTTPS, en-têtes, ne jamais publier de secrets$lesson$, $lesson$
La sécurité d'un site statique se joue sur un petit nombre de décisions, et aucune n'exige d'être spécialiste. La première est le chiffrement de la connexion. Sans certificat actif, tout le trajet entre le visiteur et le serveur circule en clair : mots de passe, adresses électroniques, contenu de formulaire. Le navigateur affiche alors un avertissement qui fait fuir une grande partie du public, et les moteurs signalent le site comme non sécurisé. Aujourd'hui, un certificat valide s'obtient gratuitement, soit directement par la plateforme d'hébergement, soit auprès d'une autorité de certification reconnue, et la plupart des services le renouvellent automatiquement. La seule règle à retenir est que le protocole sécurisé doit être obligatoire : toute tentative d'accès en clair doit rediriger vers l'adresse chiffrée, sinon deux adresses coexistent pour une seule page.

La deuxième décision porte sur les en-têtes de réponse, ces informations que le serveur joint à chaque page et qui restreignent ce que le navigateur autorise. Ils ne changent rien à l'apparence, mais ils réduisent nettement la surface d'attaque. L'en-tête de politique de contenu définit les ressources qu'une page a le droit de charger, ce qui bloque l'exécution d'un script injecté. L'option de types de contenu empêche le navigateur de deviner la nature d'un fichier ambigu. La politique de référement contrôle ce qui est transmis quand un lien sortant est suivi. Enfin, la politique de permissions désactive les fonctionnalités que votre site n'utilise pas, comme la caméra ou le micro.

```nginx
# Exemple d'en-têtes de sécurité — serveur Nginx, bloc listen 443 ssl
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), camera=(), microphone=()" always;
add_header Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'" always;
```

La troisième décision est la plus importante, et elle ne coûte rien : ne jamais publier de secret. Un secret, c'est une clé d'accès à un service de messagerie, un jeton d'API, un mot de passe de base de données, un identifiant de paiement. Toute information contenue dans un fichier livré au navigateur est publique par définition, même si elle est minifiée, même si elle est cachée dans une variable : l'inspecteur de code la révèle en un clic. La seule place légitime pour un secret est le serveur, ou les variables d'environnement de la plateforme, référencées par nom dans votre code et renseignées hors du dépôt.

```gitignore
# Fichiers et dossiers jamais versionnés
.env
.env.local
*.pem
*.key
node_modules/
dist/
.DS_Store

# Variables d'attendues sur la plateforme, jamais écrites ici :
# MAIL_API_TOKEN=
# SUPABASE_URL=
# SUPABASE_SECRET_KEY=
```

Cette discipline a une contrepartie qu'il faut anticiper : si votre code a besoin d'une variable, quelqu'un devra la renseigner sur la machine qui construit le site. Documentez les noms attendus, avec un fichier d'exemple qui donne la structure sans aucune valeur réelle, et testez la configuration sur un environnement de préproduction avant la mise en ligne. Si une clé se retrouve malgré tout publiée, la seule réaction correcte est de la révoquer immédiatement et à en émettre une nouvelle : supprimer la ligne du dépôt ne suffit pas, puisque la valeur a pu être lue et conservée.

Un dernier réflexe concerne les formulaires du site de l'atelier. N'envoyez jamais de donnée personnelle dans une adresse : les paramètres d'adresse restent dans l'historique du navigateur, dans les journaux du serveur et dans les journaux des réseaux. Faites transiter les informations par la requête, limitez les champs au strict nécessaire, et annoncez clairement, dans les mentions, ce que vous conservez et pourquoi. La confiance du visiteur fait partie de la qualité perçue du site.

- Le certificat est obligatoire et la redirection vers le protocole sécurisé aussi.
- Définissez les en-têtes de sécurité : politique de contenu, types de contenu, référement, permissions.
- Aucun secret dans le code livré au navigateur : tout ce qui y figure est public.
- Référencez les variables par nom et renseignez-les sur la plateforme, hors du dépôt.
- Gardez un fichier d'exemple sans valeur réelle pour documenter la configuration.
- Une clé publiée par erreur se révoque immédiatement, elle ne se cache pas.
$lesson$),
  ('web-c8-p9', 'web-c8', 9, $lesson$Préparer le build (et ses limites sans outil)$lesson$, $lesson$
Le mot build désigne l'étape pendant laquelle le contenu de votre dépôt est transformé en un ensemble de fichiers prêt à être servi. Pour un site entièrement statique, cette transformation peut sembler superflue : vos pages fonctionnent déjà telles quelles. En réalité, même le site le plus simple gagne à distinguer deux espaces : le dossier de travail, qui contient les sources, les commentaires, les brouillons, les fichiers de configuration, et le dossier de publication, qui ne contient que ce que le visiteur doit recevoir. Publier un dossier de travail revient à livrer un atelier avec les caisses de matériel encore emballées et les notices au sol : tout fonctionne, mais rien n'est présentable.

Sans outil, une préparation manuelle reste parfaitement légitime pour un petit site, à condition d'être suivie avec rigueur. La méthode tient en quelques gestes : créez un dossier de publication vide, copiez-y uniquement les pages, les feuilles de style, les scripts et les images réellement utiles, vérifiez que les chemins relatifs fonctionnent depuis cette nouvelle position, supprimez les fichiers de test, les brouillons et les notes internes, puis ouvrez le résultat depuis le dossier de publication pour le dernier contrôle. Si la page s'affiche correctement depuis cet emplacement, elle s'affichera correctement sur le serveur.

```json
{
  "name": "site-atelier-mediatheque",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "verifier": "node scripts/verifier.js",
    "optimiser": "node scripts/optimiser-images.js",
    "build": "node scripts/build.js",
    "publier": "npm run build && git push origin main"
  },
  "devDependencies": {
    "html-validate": "^9.0.0"
  }
}
```

Le fichier de configuration ci-dessus illustre l'étape suivante : confier la préparation à une commande. Un script de publication peut créer le dossier de publication, copier les fichiers autorisés, contrôler la présence des métadonnées obligatoires sur chaque page, refuser le démarrage s'il manque une description, et signaler les images non dimensionnées. L'intérêt n'est pas la vitesse, c'est la répétabilité : la même commande produit le même résultat, ce soir comme demain matin, par vous comme par votre collègue. Une étape manuelle oubliée une fois sur dix devient une étape impossible à oublier.

Les limites de l'approche sans outil doivent être connues pour être acceptées sereinement. Aucune optimisation automatique : ni minification des feuilles de style et des scripts, ni regroupement des fichiers, ni versionnement des adresses pour la mise en cache, ni conversion des images vers des formats modernes. Aucune détection non plus : rien n'empêche de publier une page dont la description manque ou dont une image pèse trois mégaoctets, si la vérification humaine faiblit. Enfin, la reproduction d'une publication antérieure repose entièrement sur vos souvenirs, ce qui devient vite périlleux dès que le projet grandit.

Le point de vigilance supplémentaire concerne les fichiers de configuration : la préparation du dossier de publication doit s'effectuer sans jamais y placer de variable d'environnement, de note interne ou de document non destiné au public. Un fichier copié par réflexe peut contenir une adresse de courrier d'administration, une liste de participants ou un jeton oublié dans un commentaire. Relisez l'inventaire final du dossier de publication, ligne par ligne, avant de le transférer : c'est la dernière occasion de découvrir qu'un fichier ne devrait pas partir.

- Séparez les sources, que vous modifiez, du dossier de publication, que le visiteur reçoit.
- Sans outil, appliquez la même procédure manuelle dans le même ordre à chaque fois.
- Confiez la préparation à une commande dès que la tâche se répète.
- Sachez ce que l'approche sans outil ne fait pas : optimisation, détection, traçabilité.
- Contrôlez l'inventaire complet du dossier de publication avant tout transfert.
- Jamais de variable d'environnement ni de note interne dans les fichiers publiés.
$lesson$),
  ('web-c8-p10', 'web-c8', 10, $lesson$Déployer : hébergement statique, domaine, déploiement continu$lesson$, $lesson$
Le déploiement est l'acte de mettre les fichiers publiables à l'endroit d'où le public pourra les récupérer. Pour un site statique, l'opération est d'une simplicité déconcertante : transmettre un dossier à un serveur, ou laisser une plateforme le faire pour vous à chaque validation. Le choix de l'hébergement se juge à trois critères : la fiabilité, c'est-à-dire la probabilité que la page réponde ; la facilité de mise à jour, c'est-à-dire le nombre de gestes nécessaires pour publier une correction ; et le coût, souvent nul pour un projet de cette taille. Les services d'hébergement de dépôt offrent une publication statique gratuite, adaptée au site de l'atelier, de même que les plateformes de déploiement continues.

Quelle que soit la solution retenue, le parcours de livraison reste le même, et il vaut la peine de le visualiser comme une chaîne dont chaque maillon a une responsabilité précise. Vos fichiers vivent sur votre machine ; ils sont versionnés dans un dépôt ; une étape automatique les vérifie et les assemble ; le résultat est copié vers la destination publique. Chaque flèche du schéma représente un transfert, et chaque transfert est un endroit où une erreur de chemin peut se glisser.

```text
   POSTE DE TRAVAIL              DÉPÔT VERSIONNÉ           INTÉGRATION           PRODUCTION
  +------------------+          +------------------+       +----------------+     +-------------------+
  | sources locales  |  commit  | branche principale| push | vérification    |copy| dossier public    |
  | *.html, css, js  +--------->| historique complet+----->| assemblage      +--->| https:// domaine  |
  | brouillons, notes|          | issues, tags      |      | publication     |    | certificat actif  |
  +------------------+          +------------------+       +----------------+     +-------------------+
        éditeur                       git                    service             hébergeur
                                                                  |
                                                           aperçu avant mise
                                                           en ligne (préproduction)
```

Concrètement, la publication la plus simple consiste à indiquer à la plateforme quel dépôt servir et quelle branche représenter le site en ligne. Dès que vous validez une modification sur cette branche, la plateforme récupère les derniers fichiers, exécute la commande de préparation si vous en avez définie une, et remplace le contenu public. Vous n'avez plus à copier quoi que ce soit à la main : votre geste quotidien, valider une modification, devient votre geste de mise en ligne. Les instructions officielles de ce service sont rassemblées sur la page https://pages.github.com, et celles de l'alternative équivalente sur https://vercel.com.

```yaml
# .github/workflows/publier.yml — publication automatique à chaque validation
name: Publier le site
on:
  push:
    branches: [main]
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  construire:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Vérifier les pages
        run: npm run verifier
      - name: Préparer le dossier public
        run: npm run build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: dist
  publier:
    needs: construire
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

Le domaine arrive en dernier, parce qu'il suppose que le site est déjà joignable. Attaché à l'hébergement par une entrée technique qui traduit le nom en adresse, il transforme une adresse de service en identité durable : le nom de l'atelier se retient, se dicte au téléphone, s'imprime sur une affiche. Vérifiez alors deux choses : que le certificat couvre bien le domaine choisi, et que la redirection de l'ancienne adresse de service vers le domaine canonique est en place, afin d'éviter deux adresses concurrentes. Après le premier déploiement, refermez la boucle en rejouant la checklist de livraison depuis le domaine public : ouvrez chaque page, testez le formulaire, écoutez une page au lecteur d'écran, confirmez la présence du fichier de consignes et du plan du site, puis partagez l'adresse dans un message pour voir la carte de partage réelle.

- Choisissez l'hébergement sur trois critères : fiabilité, simplicité de mise à jour, coût.
- Versionnez d'abord, publiez ensuite : le dépôt est la source de vérité.
- Automatisez la chaîne complète : vérification, assemblage, mise en ligne.
- Conservez une adresse d'aperçu pour vérifier avant de rendre public.
- Attachez le domaine en dernier et faites rediriger les adresses concurrentes.
- Rejouez la checklist depuis le domaine public après chaque mise en ligne.
$lesson$),
  ('web-c8-p11', 'web-c8', 11, $lesson$Mesurer après le lancement : les Core Web Vitals$lesson$, $lesson$
Mettre un site en ligne ne clôt pas le travail, cela l'ouvre. Jusqu'ici, vos vérifications portaient sur des fichiers que vous pouviez ouvrir et corriger ; désormais, elles porteront sur une expérience vécue par des personnes dont vous ne connaissez ni l'appareil, ni la connexion, ni le moment de la visite. Mesurer après le lancement sert à deux objectifs distincts. Le premier est détectif : savoir ce qui coince réellement, plutôt que de deviner à partir de votre propre machine, qui est presque toujours plus rapide et plus stable que la moyenne. Le second est préventif : disposer d'une référence pour constater qu'une modification a amélioré ou dégradé la page, au lieu d'opérer à l'aveugle.

Les indicateurs consacrés à cela portent le nom de indicateurs vitaux du web, et trois d'entre eux suffisent pour une lecture complète. Le premier évalue le moment où le contenu principal devient visible : au-delà de deux virgule cinq secondes, le visiteur commence à se demander si la page répond. Le second évalue la réactivité, c'est-à-dire le délai entre un geste, un clic sur un bouton d'inscription par exemple, et la prise en compte effective de ce geste ; il a remplacé l'ancien indicateur de première interaction, qui mesurait seulement le tout premier clic. Le troisième évalue la stabilité visuelle : un texte qui saute au moment où une image ou une bannière finit par arriver force le visiteur à viser à nouveau, et provoque des clics malheureux.

| Mesure | Ce qu'elle évalue | Seuil correct | Où la lire |
| --- | --- | --- | --- |
| Affichage du contenu principal | Moment où le visuel principal devient visible | Moins de 2,5 secondes | Outil de mesure en laboratoire |
| Fluidité des interactions | Délai entre un geste et sa prise en compte | Moins de 200 millisecondes | Outil de mesure en laboratoire |
| Stabilité de la mise en page | Déplacements de contenu pendant le chargement | Moins de 0,1 | Outil de mesure en laboratoire |
| Poids total de la page | Volume téléchargé par le visiteur | Environ 1,5 mégaoctet | Onduleur réseau |
| Temps de réponse du serveur | Délai avant la première réponse utile | Moins de 600 millisecondes | Onduleur réseau |
| Erreurs de console | Problèmes détectés au chargement | Aucune | Console du navigateur |

Une distinction méthodologique mérite d'être assimilée avant d'interpréter un seul chiffre : la mesure de laboratoire et la mesure sur le terrain ne disent pas la même chose. La première reproduit vos conditions à un instant donné, sur un profil d'appareil simulé ; elle est parfaite pour comparer deux versions l'une à l'autre, mais elle ne reflète pas la diversité réelle du public. La seconde agrège les expériences de vrais visiteurs sur plusieurs semaines ; elle fait autorité pour juger la qualité perçue, mais elle évolue lentement et manque de détails sur une page récente. Utilisez la première pour décider d'une correction, et la seconde pour confirmer son effet.

```sh
# Vérifier les en-têtes réellement renvoyés par le serveur public
curl -I https://mediatheque-des-lilas.example/ateliers/

# Mesurer la page en conditions de laboratoire, sur mobile
npx lighthouse https://mediatheque-des-lilas.example/ --preset=perf --output=html

# Contrôler que le fichier de consignes est bien servi
curl https://mediatheque-des-lilas.example/robots.txt
```

Le dernier réflexe à installer est celui de la boucle d'amélioration continue. Un relevé produit une liste d'alertes ; chaque alerte est un candidat à la correction ; une correction est validée par un nouveau relevé. Réalisez-en une seule à la fois : si vous modifiez simultanément le format des images, la feuille de style et l'ordre des scripts, vous ne saurez jamais lequel des trois a produit l'amélioration, ou pire, vous attribuerez le mérite d'une régression à une optimisation. Gardez la date et les chiffres de chaque relevé à côté de votre checklist : c'est cette série, et non un score isolé, qui raconte l'histoire réelle du site.

- Mesurez avant d'optimiser, puis mesurez à nouveau après chaque modification.
- Retenez trois indicateurs : affichage, réactivité, stabilité visuelle.
- Distinguez la mesure de laboratoire, pour décider, de la mesure terrain, pour conclure.
- Corrigez une seule chose à la fois et reliez chaque chiffre à une modification.
- Conservez l'historique des relevés à côté de la checklist de livraison.
- Une alerte n'est pas un échec : c'est la liste ordonnée de votre prochain travail.
$lesson$),
  ('web-c8-p12', 'web-c8', 12, $lesson$Mini-projet guidé : livrer le site de l'atelier$lesson$, $lesson$
Il est temps d'appliquer l'ensemble du chapitre au projet que vous portez depuis le premier jour : le site de l'atelier de la Médiathèque des Lilas. L'objectif de ce mini-projet n'est pas d'écrire du nouveau code, mais de transformer ce qui existe en un livrable. Vous allez donc travailler en huit gestes, dans cet ordre, en cochant chaque ligne de votre checklist au fur et à mesure. Commencez par inventorier les fichiers réellement publics : pages, feuilles de style, scripts, images, polices éventuelles. Écartez tout ce qui sert uniquement au développement, les brouillons, les notes, les fichiers de configuration, et confirmez que le dossier ainsi dégagé s'ouvre correctement depuis une autre position du disque.

Le deuxième geste est la passe d'en-tête technique, page par page. Chaque page doit porter son propre titre et sa propre description, la langue de la racine, la mise à l'échelle mobile, son adresse canonique et ses métadonnées de partage. Le titre et la description ne se copient pas d'une page à l'autre : une page d'atelier parle d'un atelier, la page d'accueil présente le site. Le troisième geste porte sur les images : reformatez-les, réduisez-les, déclarez leurs dimensions, appliquez le chargement différé à tout ce qui se trouve sous la ligne de flottaison. Le quatrième ajoute les fichiers techniques à la racine : le fichier de consignes pour les robots et le plan du site, tous deux avec des adresses en protocole sécurisé.

```text
site-atelier/
  index.html
  ateliers.html
  horaires.html
  mentions.html
  robots.txt
  sitemap.xml
  styles/
    site.css
  scripts/
    checklist.js
  images/
    affiche-atelier.webp
    atelier-480.webp
    atelier-960.webp
    logo.svg
  polices/
    atelier-display.woff2
```

Le cinquième geste est la constitution du dépôt. Créez-le, placez-y le dossier tel que vous venez de le décrire, ajoutez le fichier d'exclusion qui garde hors du dépôt les variables d'environnement et les fichiers de travail, puis écrivez un premier message de validation qui décrit l'état du projet. Le sixième geste est la définition de la commande de publication : une commande unique qui vérifie les métadonnées, contrôle le poids des images, puis produit le dossier à transmettre. Même si cette commande se résume à quelques lignes, elle vous protège de l'oubli, et c'est exactement ce qu'apporte la rigueur.

Le septième geste est le déploiement lui-même. Reliez le dépôt à la plateforme choisie, indiquez la branche correspondant au site en ligne, déclenchez la première publication, puis ouvrez l'adresse publique dans un navigateur que vous n'avez pas utilisé pendant le développement. Le huitième et dernier geste est le retour complet de la checklist depuis cette adresse publique : structure, métadonnées, images, performance, clavier, lecteur d'écran, contrastes, fichiers techniques, sécurité, absence d'erreur. Ce dernier passage, souvent escamoté, est celui qui transforme un site déposé en un site livré.

```html
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ateliers numériques — Médiathèque des Lilas</title>
  <meta name="description" content="Ateliers gratuits de prise en main de l'ordinateur et du web, chaque samedi à la Médiathèque des Lilas. Inscription en ligne.">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="https://mediatheque-des-lilas.example/ateliers/">
  <link rel="icon" href="images/logo.svg" type="image/svg+xml">

  <meta property="og:type" content="website">
  <meta property="og:locale" content="fr_FR">
  <meta property="og:title" content="Ateliers numériques — Médiathèque des Lilas">
  <meta property="og:description" content="Trois heures pour écrire sa première page web, en accès gratuit.">
  <meta property="og:url" content="https://mediatheque-des-lilas.example/ateliers/">
  <meta property="og:image" content="https://mediatheque-des-lilas.example/images/affiche-atelier.webp">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">

  <link rel="preconnect" href="https://fonts.example.org" crossorigin>
  <style>
    body { font-family: system-ui, sans-serif; color: #1a1a2e; line-height: 1.6; }
    a:focus-visible, button:focus-visible { outline: 3px solid #e07a00; }
  </style>
  <link rel="stylesheet" href="styles/site.css" media="print" onload="this.media='all'">
</head>
```

Un mot sur ce que vous ne ferez pas dans ce mini-projet, pour rester dans un périmètre tenable. Vous n'intégrerez pas de base de données distante, vous n'ajouterez pas de système de comptes, vous ne relierez pas de service de paiement. Le site de l'atelier reste un site d'information : pages stables, formulaire de contact, contenu éditorial. Les techniques du chapitre s'appliquent intégralement à ce périmètre, et c'est précisément parce qu'il est restreint que vous pourrez les appliquer toutes, jusqu'au bout, sans rien survoler.

- Inventoriez les fichiers publics, puis écartez tout ce qui sert au développement.
- Passez chaque page à la loup d'en-tête : titre, description, canonique, partage.
- Optimisez les images et déclarez leurs dimensions, en réservant l'image de tête.
- Ajoutez le fichier de consignes et le plan du site à la racine du domaine.
- Versionnez, définissez une commande unique de publication, automatisez-la.
- Rejouez la checklist en entier depuis l'adresse publique, appareil inconnu à la main.
$lesson$),
  ('web-c8-p13', 'web-c8', 13, $lesson$Le projet final : périmètre et critères de réussite$lesson$, $lesson$
Le projet final du parcours est la synthèse de vos huit chapitres : un site complet, accessible en ligne, construit avec les technologies que vous avez manipulées, de la structure sémantique jusqu'au déploiement. Sa valeur pédagogique réside moins dans l'ambition du contenu que dans l'exigence de la livraison : vous devez être capable d'expliquer chaque décision, de la balise à l'en-tête de sécurité, et de rejouer la mise en ligne devant quelqu'un d'autre. C'est ce qui distingue un projet que vous avez suivi pas à pas d'un projet que vous savez réellement refaire seul.

Le périmètre se définit d'abord par exclusions, ce qui est la manière la plus sûre de terminer. Sont exclus : tout système de comptes utilisateurs, tout paiement, toute donnée personnelle conservée, toute fonctionnalité qui supposerait un serveur d'application écrit par vous. Sont inclus : un ensemble cohérent d'au moins quatre pages, une navigation commune, un contenu réellement rédigé, au moins un formulaire fonctionnel côté interface, une part d'interface construite en React si vous souhaitez mobiliser le dernier chapitre, et l'ensemble des fichiers techniques vus dans ce chapitre. Ce périmètre tient dans un projet d'étudiant sérieux comme dans un site réel d'association, ce qui n'est pas un hasard : les contraintes sont les mêmes.

Les critères de réussite se lisent en trois registres. Le registre fonctionnel demande que chaque page s'ouvre depuis l'adresse publique, que la navigation mène partout, que le formulaire s'affiche correctement sur un téléphone comme sur un écran large, et qu'aucune erreur n'apparaisse dans la console. Le registre qualité demande l'application effective des règles des chapitres précédents : hiérarchie de titres, images décrites et dimensionnées, contraste et focus visibles, parcours au clavier complet. Le registre livraison demande la preuve du processus : un dépôt versionné dont l'historique se lit, une commande de publication reproductible, une checklist cochée et une mesure de performance archivée.

Une astuce de planification vous fera gagner du temps : avancez par jalons datés plutôt que par liste de tâches. Un jalon dit : à telle date, le site est navigable depuis l'adresse publique, même si le contenu est encore partiel. Un autre dit : à telle date, la checklist complète est cochée. Chaque jalon se vérifie par un fait observable, jamais par une impression. Si un jalon est manqué, vous savez exactement ce qui reste, et vous pouvez réduire le périmètre plutôt que de voir la date de livraison glisser sans préavis.

- Définissez le périmètre par exclusions : ce que le projet ne fera pas.
- Au moins quatre pages, une navigation commune, du contenu réellement rédigé.
- Interface complète sur mobile, parcours au clavier, aucun avertissement en console.
- Dépôt versionné lisible, commande de publication unique et reproductible.
- Checklist cochée et mesure de performance archivée à côté du projet.
- Progressez par jalons datés vérifiables par un fait observable.
$lesson$),
  ('web-c8-p14', 'web-c8', 14, $lesson$À retenir$lesson$, $lesson$
- Un prototype prouve une idée ; un produit sert des inconnus, en permanence, sans votre machine.
- Liens internes relatifs, noms de fichiers sans accent ni espace, sensibilité à la casse respectée.
- Toute donnée distante peut échouer : prévoyez un état de repli lisible plutôt qu'un écran vide.
- Aucun secret dans le dépôt ni dans le dossier publié : les variables d'environnement vivent hors ligne.
- La checklist se vérifie dans le même ordre, chaque ligne répondant par oui ou par non.
- Les images pèsent l'essentiel d'une page : compression, format moderne, dimensions déclarées, chargement différé.
- Le chargement différé s'applique à tout, sauf au visuel visible dès l'arrivée sur la page.
- Le CSS critique habille le haut de page immédiatement, le reste de la feuille arrive ensuite.
- Les polices se sous-ensemble, se préconnectent et laissent un affichage de secours.
- La mise en cache suppose des adresses qui changent quand le contenu change.
- Titre unique, description rédigée à la main, données structurées, plan du site : les quatre piliers du référencement.
- Le fichier de consignes pour les robots oriente, il ne protège rien.
- Une seule adresse canonique par page, en protocole sécurisé, telle qu'elle sera partagée.
- Les métadonnées de partage décident de l'apparence du lien dans un message.
- Le certificat est obligatoire, la redirection vers le protocole sécurisé aussi, les en-têtes de sécurité par-dessus.
- Séparez sources et dossier de publication, et confiez la préparation à une commande.
- Déployer, c'est versionner puis publier ; automatiser la chaîne, puis rejouer la checklist depuis le domaine public.
$lesson$),
  ('web-c8-p15', 'web-c8', 15, $lesson$Erreurs fréquentes$lesson$, $lesson$
- Piège : publier le dossier de travail complet, brouillons et configuration compris → Correction : construisez un dossier de publication neuf, rempli uniquement des fichiers utiles au visiteur.
- Piège : laisser des liens qui ne fonctionnent que depuis votre machine → Correction : testez le dossier publié depuis un autre emplacement avant tout transfert.
- Piège : charger une photographie de plusieurs mégaoctets telle quelle → Correction : compressez, convertissez au format moderne, déclarez les dimensions et différez le chargement.
- Piège : appliquer le chargement différé à l'image de tête → Correction : réservez l'espace et chargez immédiatement le visuel visible sans défilement.
- Piège : donner le même titre et la même description à toutes les pages → Correction : écrivez pour chaque page un titre et un résumé qui parlent de cette page.
- Piège : croire que le fichier de consignes empêche l'accès à une page → Correction : ce fichier oriente les robots ; pour protéger une page, utilisez un autre mécanisme.
- Piège : recopier une adresse canonique approximative, avec variante ou protocole non sécurisé → Correction : déclarez l'adresse exacte, définitive et chiffrée, sans barre finale ambiguë.
- Piège : placer une clé dans le code livré au navigateur en se disant qu'elle est cachée → Correction : tout ce qui est livré est public ; sortez la clé vers une variable d'environnement côté serveur.
- Piège : supprimer l'indicateur de focus pour faire plus propre → Correction : remplacez toujours l'indicateur supprimé par un contour net et contrasté.
- Piège : corriger trois choses à la fois après une mesure → Correction : une modification à la fois, puis nouvelle mesure pour attribuer l'effet.
- Piège : considérer la première mise en ligne comme l'arrivée → Correction : rejouez la checklist depuis le domaine public et archivez la mesure initiale.
- Piège : oublier de versionner avant de déployer → Correction : le dépôt est la source de vérité : validez d'abord, publiez ensuite.
$lesson$),
  ('web-c8-p16', 'web-c8', 16, $lesson$Pour aller plus loin$lesson$, $lesson$
La documentation de Mozilla reste le point de départ le plus fiable pour approfondir les aspects techniques vus ici : https://developer.mozilla.org rassemble les guides sur la performance, les métadonnées, les en-têtes de réponse et l'accessibilité, avec la même exigence de mise à jour continue que celle que vous avez rencontrée dans les chapitres précédents. Prenez l'habitude d'y revenir dès qu'un doute se présente sur une balise ou un en-tête, plutôt que de reprendre un extrait de code trouvé ailleurs et qui peut dater d'une autre époque du web.

Côté performance et mesure, la plateforme https://web.dev publie des guides pratiques ainsi qu'un ensemble d'outils d'analyse dont les seuils correspondent exactement aux indicateurs de la section précédente. Pour le référencement, la documentation officielle rassemblée sur https://developers.google.com/search explique comment les robots découvrent les pages, ce qu'est une adresse canonique et pourquoi les métadonnées de partage comptent. Enfin, pour la mise en ligne elle-même, https://pages.github.com décrit pas à pas la publication statique depuis un dépôt, tandis que https://vercel.com présente l'alternative équivalente avec déploiement automatique à chaque validation. Feuilletez ces ressources sans chercher à tout absorber : revenez-y au moment précis où vous préparerez une livraison réelle.
$lesson$),
  ('web-c8-p17', 'web-c8', 17, $lesson$Et maintenant : les prochaines étapes$lesson$, $lesson$
Vous disposez désormais de l'ensemble du cheminement : une structure sémantique que vous avez écrite, des styles que vous avez composés, des comportements que vous avez programmés, des données que vous avez récupérées, un projet versionné, une interface reconstruite en React, et maintenant une procédure complète pour mettre le tout en ligne. Les prochaines étapes sont d'abord concrètes. Réalisez l'exercice pratique qui accompagne ce chapitre : l'audit de mise en production du site de l'atelier, avec ses métadonnées complètes, ses images dimensionnées, ses contrastes, son fichier de consignes et la déclaration de ses étapes de déploiement. Ce travail vous obligera à lire votre propre code avec les yeux d'un relecteur impatient, et vous verrez apparaître, dans votre propre projet, les défauts que vous auriez su repérer chez les autres.

Le quiz de quatre questions qui suit vous permet de vérifier en quelques minutes les notions essentielles : ce qui sépare un prototype d'un produit, ce que mesure un indicateur d'affichage, ce que fait et ce que ne fait pas un fichier de consignes, et l'endroit où un secret a le droit de vivre. Ensuite vient le projet final, dont vous connaissez à présent le périmètre et les critères : un site complet, accessible, rapide, documenté, versionné et réellement en ligne. Traitez-le comme une première livraison professionnelle, c'est-à-dire avec une checklist, des jalons datés et une mesure archivée, plutôt qu'avec la seule envie de terminer.

Une fois le site publié, gardez un dernier réflexe : continuer à construire. Un projet personnel que l'on maintient vivant, qu'on y ajoute une page, qu'on y corrige un défaut repéré par un visiteur, qu'on y refait une mesure tous les quelques mois, est la meilleure école qui soit, parce qu'il vous oblige à retrouver vos propres décisions six mois plus tard, avec un dépôt pour mémoire. Le parcours vous a donné les gestes ; c'est en les répétant sur des projets réels, à votre rythme, que vous en ferez un métier.
$lesson$);
