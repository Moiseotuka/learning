-- easyLearn — étape 4 : espace apprenant (chapitres, quiz, progression)
-- Idempotent : peut être réappliqué sans effet de bord.

-- 1. Seuil de réussite du quiz par parcours -------------------------------

alter table public.tracks
  add column if not exists passing_score integer not null default 70;

-- 2. Chapitres --------------------------------------------------------------

create table if not exists public.chapters (
  id text primary key,
  track_id text not null references public.tracks (id) on delete cascade,
  level text not null check (level in ('debutant', 'intermediaire', 'avance', 'projet')),
  slug text not null unique,
  title text not null,
  summary text not null default '',
  objectives text[] not null default '{}',
  video_url text,
  content text not null default '',
  exercise text not null default '',
  resources jsonb not null default '[]',
  position integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists chapters_track_position_idx
  on public.chapters (track_id, position);

drop trigger if exists chapters_set_updated_at on public.chapters;
create trigger chapters_set_updated_at
  before update on public.chapters
  for each row execute function public.set_updated_at();

-- 3. Questions de quiz ------------------------------------------------------
-- Jamais lisible par le client : les réponses voyagent uniquement côté serveur.

create table if not exists public.quiz_questions (
  id text primary key,
  chapter_id text not null references public.chapters (id) on delete cascade,
  question text not null,
  choices jsonb not null default '[]',
  answer_index integer not null,
  explanation text not null default '',
  position integer not null default 0
);

create index if not exists quiz_questions_chapter_position_idx
  on public.quiz_questions (chapter_id, position);

-- 4. Progression de l'apprenant --------------------------------------------

create table if not exists public.chapter_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  chapter_id text not null references public.chapters (id) on delete cascade,
  track_id text not null references public.tracks (id) on delete cascade,
  attempts integer not null default 0,
  best_score integer check (best_score between 0 and 100),
  status text not null default 'in_progress' check (status in ('in_progress', 'completed')),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, chapter_id)
);

create index if not exists chapter_progress_user_track_idx
  on public.chapter_progress (user_id, track_id);

drop trigger if exists chapter_progress_set_updated_at on public.chapter_progress;
create trigger chapter_progress_set_updated_at
  before update on public.chapter_progress
  for each row execute function public.set_updated_at();

-- 5. Row Level Security -----------------------------------------------------

alter table public.chapters enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.chapter_progress enable row level security;

drop policy if exists "chapters_select" on public.chapters;
create policy "chapters_select" on public.chapters
  for select to authenticated
  using (published or public.is_admin());

drop policy if exists "chapters_admin_write" on public.chapters;
create policy "chapters_admin_write" on public.chapters
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "progress_select_own" on public.chapter_progress;
create policy "progress_select_own" on public.chapter_progress
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "progress_insert_own" on public.chapter_progress;
create policy "progress_insert_own" on public.chapter_progress
  for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "progress_update_own" on public.chapter_progress;
create policy "progress_update_own" on public.chapter_progress
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Accès client retiré aux questions : seuls le serveur (service role) et le
-- back-office peuvent les lire.
revoke all on table public.quiz_questions from anon;
revoke all on table public.quiz_questions from authenticated;
grant select on table public.quiz_questions to service_role;

-- 6. Seed : « Python : du premier script au projet complet » ---------------

update public.tracks
set passing_score = 70
where id = 'python-developpeur';

insert into public.chapters
  (id, track_id, level, slug, title, summary, objectives, video_url, content, exercise, resources, position, published)
values
(
  'py-c1', 'python-developpeur', 'debutant', 'premiers-pas-variables',
  'Premiers pas en Python : variables et types',
  'Exécuter son premier script, créer des variables et manipuler les types de base.',
  array[
    'Exécuter un script Python et afficher du texte',
    'Créer des variables et identifier leur type',
    'Convertir une saisie utilisateur en nombre'
  ],
  null,
  'Python est un langage interprété : vous écrivez des instructions dans un fichier .py, puis l''interpréteur les exécute une par une. Pour afficher un résultat, on utilise print(). C''est souvent la première fonction que l''on apprend, et elle reste utile tout au long du débogage.

Une variable est un nom qui pointe vers une valeur. Python ne déclare pas le type : il le déduit. Le type str stocke du texte, int des entiers, float des décimaux et bool les valeurs True/False. La fonction type() affiche le type d''une valeur, ce qui aide à comprendre ce que fait réellement votre code.

Les saisies clavier arrivent toujours sous forme de texte via input(). Pour faire des calculs, il faut convertir avec int() ou float(). Inversement, str() transforme un nombre en texte pour l''afficher ou le concaténer.

Une bonne pratique : donner des noms explicites (age, prix_total) plutôt que des lettres isolées, et respecter la convention snake_case. Un code lisible est un code que vous pourrez encore comprendre dans trois mois.',
  'Écrivez un programme qui demande son âge à l''utilisateur, calcule l''âge qu''il aura dans 10 ans et affiche la phrase complète. Si la saisie n''est pas un nombre valide, affichez « Saisie invalide » au lieu de planter.',
  '[{"label":"Tutoriel officiel Python (fr)","url":"https://docs.python.org/fr/3/tutorial/"},{"label":"Types built-in","url":"https://docs.python.org/fr/3/library/stdtypes.html"}]',
  1, true
),
(
  'py-c2', 'python-developpeur', 'debutant', 'conditions-boucles',
  'Conditions et boucles : décider et répéter',
  'if / elif / else pour choisir, for et while pour répéter, break et continue pour contrôler.',
  array[
    'Écrire une condition if / elif / else',
    'Parcourir une séquence avec une boucle for',
    'Répéter jusqu''à un état avec while et sortir avec break'
  ],
  null,
  'Les conditions traduisent des décisions : si le stock est négatif, alors on alerte. L''instruction if teste une expression, elif ajoute des cas alternatifs et else couvre le reste. Les opérateurs ==, !=, <, >, in et les mots and, or, not permettent de composer des tests précis.

La boucle for parcourt une séquence : range() pour des compteurs, une liste pour des éléments, un dictionnaire pour ses clés. C''est la boucle la plus fréquente car elle évite de gérer soi-même l''index.

La boucle while répète tant qu''une condition reste vraie. Elle convient aux attentes et aux boucles à durée inconnue, à condition de faire évoluer la condition de sortie à chaque tour, sinon la boucle tourne à l''infini.

break interrompt la boucle en cours, continue saute à l''itération suivante. Utilisés avec parcimonie, ils rendent la lecture plus claire ; abusés, ils rendent le flux difficile à suivre.',
  'Implémentez le jeu « devinez le nombre » : le programme choisit un nombre entre 1 et 50, l''utilisateur propose, la boucle affiche « plus » ou « moins » et s''arrête dès la bonne réponse en affichant le nombre d''essais.',
  '[{"label":"Contrôle de flux (if, for, while)","url":"https://docs.python.org/fr/3/tutorial/controlflow.html"}]',
  2, true
),
(
  'py-c3', 'python-developpeur', 'debutant', 'fonctions',
  'Fonctions : découper son code',
  'Définir des fonctions, passer des paramètres et retourner un résultat.',
  array[
    'Définir une fonction avec def et la documenter',
    'Passer des paramètres et des arguments par défaut',
    'Retourner un résultat avec return'
  ],
  null,
  'Une fonction regroupe un bloc réutilisable derrière un nom. On la définit avec def, on l''appelle ensuite comme une fonction built-in : print() n''est finalement qu''une fonction fournie par Python.

Les paramètres sont les noms prévus dans la définition, les arguments les valeurs envoyées à l''appel. Une valeur par défaut (def saluer(nom="ami")) évite de multiplier les variantes de la même fonction.

return envoie un résultat à l''appelant et termine la fonction. Sans return, la fonction renvoie None. Attention à ne pas confondre l''affichage (print) et le retour (return) : la première montre, la seconde transmet.

Une fonction qui fait une seule chose se teste, se corrige et se réutilise facilement. Signez-la avec un docstring court : vous vous en remercierez plus tard.',
  'Écrivez trois fonctions : moyenne(notes) qui renvoie la moyenne, mention(moyenne) qui renvoie « A » au-dessus de 16, « B » au-dessus de 14, « C » au-dessus de 12 sinon « D », et un petit main() qui les utilise sur une liste de notes saisie en dur.',
  '[{"label":"Définir des fonctions","url":"https://docs.python.org/fr/3/tutorial/controlflow.html#defining-functions"}]',
  3, true
),
(
  'py-c4', 'python-developpeur', 'debutant', 'listes-dictionnaires',
  'Listes, dictionnaires et boucler sur les données',
  'Structurer des données en listes et dictionnaires, puis les parcourir efficacement.',
  array[
    'Ajouter, trier et filtrer les éléments d''une liste',
    'Accéder et mettre à jour un dictionnaire par clé',
    'Écrire une compréhension de liste lisible'
  ],
  null,
  'La liste est une collection ordonnée et modifiable : append() ajoute, insert() insère, remove() supprime, sort() trie et len() compte. Une liste peut contenir n''importe quel type, y compris d''autres listes.

Le dictionnaire associe une clé à une valeur : on lit et écrit avec d["nom"], on teste une présence avec "nom" in d, et on parcourt avec .items(). C''est la structure idéale pour décrire un objet : {"nom": "Amina", "notes": [14, 15]}.

Les compréhensions condensent une boucle et un filtre en une ligne : [n * 2 for n in notes if n >= 10]. Elles sont rapides à écrire et, bien lues, plus claires qu''une boucle avec variable d''accumulation.

Attention à la référence de liste : copier avec list() ou une compréhension crée une nouvelle liste, alors que a = b partage le même objet.',
  'À partir d''une liste de dictionnaires [{"nom": "Amina", "note": 14}, ...], écrivez : la moyenne de la classe, la note maximale, et la liste des noms des étudiants au-dessus de la moyenne, triée par ordre alphabétique.',
  '[{"label":"Structures de données","url":"https://docs.python.org/fr/3/tutorial/datastructures.html"}]',
  4, true
),
(
  'py-c5', 'python-developpeur', 'intermediaire', 'fichiers',
  'Lire et écrire des fichiers',
  'Ouvrir des fichiers en toute sécurité, lire du texte et produire des exports.',
  array[
    'Ouvrir un fichier avec with et le bon encodage',
    'Lire, écrire et ajouter du contenu',
    'Parcourir un fichier CSV avec le module csv'
  ],
  null,
  'Le module open() prend un chemin et un mode : "r" pour lire, "w" pour écrire (écrase), "a" pour ajouter. Le bloc with ferme le fichier automatiquement, même en cas d''erreur : c''est la forme à retenir par cœur.

Lire avec .read() charge tout le fichier, .readline() une ligne, et itérer sur le fichier parcourt ligne à ligne en mémoire minimale — préférable pour les gros fichiers. Pensez à préciser encoding="utf-8" pour éviter les surprises d''accents.

Écrire revient à appeler .write() ou .writelines(). En mode "w", le contenu précédent disparaît : utilisez "a" pour compléter un journal.

Le module csv.DictReader traite chaque ligne comme un dictionnaire, ce qui rend les exports et imports beaucoup plus simples qu''à la main.',
  'Écrivez un script qui lit un fichier notes.csv (colonnes nom,note), calcule la moyenne, puis écrit un fichier rapport.txt contenant la moyenne, la note max et la liste des mentions obtenues.',
  '[{"label":"Lire et écrire des fichiers","url":"https://docs.python.org/fr/3/tutorial/inputoutput.html#reading-and-writing-files"},{"label":"Module csv","url":"https://docs.python.org/fr/3/library/csv.html"}]',
  5, true
),
(
  'py-c6', 'python-developpeur', 'intermediaire', 'erreurs-exceptions',
  'Erreurs et exceptions : anticiper les pannes',
  'Comprendre les tracebacks, attraper les erreurs attendues et lever les siennes.',
  array[
    'Lire un traceback pour localiser une erreur',
    'Encadrer un code avec try / except ciblé',
    'Lever une erreur explicite avec raise'
  ],
  null,
  'Une exception interrompt le programme et produit un traceback : il indique la ligne fautive, la chaîne d''appels et le type d''erreur. Le lire de bas en haut est la compétence la plus rentable du débogueur débutant.

Le bloc try exécute le code risqué ; except attrape l''erreur attendue. On attrache toujours un type précis (except ValueError) : un except vide masque les vrais bugs. finally s''exécute toujours, idéal pour libérer une ressource.

Ne pas attraper une erreur conduit à l''arrêt ; l''attraper trop largement conduit au silence. On protège donc les points d''entrée externes (saisie, fichier, réseau) et on laisse les incohérences de logique exploser.

raise ValueError("note hors bornes") crée une erreur métier explicite. Dans une fonction, c''est souvent mieux que de renvoyer None et de faire deviner l''appelant.',
  'Reprenez le calcul de moyenne : acceptez des notes entre 0 et 20, levez une ValueError hors bornes, et écrivez un try/except qui affiche une phrase compréhensible à l''utilisateur sans perdre le traceback en mode debug.',
  '[{"label":"Erreurs et exceptions","url":"https://docs.python.org/fr/3/tutorial/errors.html"}]',
  6, true
),
(
  'py-c7', 'python-developpeur', 'intermediaire', 'modules-pip',
  'Modules, packages et pip',
  'Organiser son projet en modules et réutiliser les bibliothèques de la communauté.',
  array[
    'Importer un module et choisir une convention d''import',
    'Découper un projet en plusieurs fichiers Python',
    'Installer et figer des dépendances avec pip'
  ],
  null,
  'Un module est un fichier .py réutilisable. import math donne accès à math.sqrt, tandis que from math import sqrt importe directement la fonction. Les alias (import numpy as np) allègent le code.

Le __name__ == "__main__" permet d''exécuter le code d''un fichier seulement quand il est lancé directement, pas lorsqu''il est importé : indispensable pour tester vos modules.

Un package est un dossier avec un __init__.py, qui rassemble des modules apparentés. Une structure claire (models.py, services.py, cli.py) réduit vite les fichiers de 2000 lignes.

pip installe les bibliothèques, pip freeze > requirements.txt fige les versions pour reproduire l''environnement ailleurs. Évitez d''installer à la volée : une dépendance est un engagement de maintenance.',
  'Découpe votre analyseur de notes en deux fichiers : calc.py (fonctions de calcul) et main.py (saisie et affichage). Ajoutez un requirements.txt avec une dépendance que vous utilisez réellement, par exemple rich pour l''affichage.',
  '[{"label":"Gestion des modules","url":"https://docs.python.org/fr/3/tutorial/modules.html"},{"label":"Guide pip","url":"https://pip.pypa.io/en/stable/"}]',
  7, true
),
(
  'py-c8', 'python-developpeur', 'intermediaire', 'projet-analyseur-notes',
  'Mini-projet : analyseur de notes',
  'Assembler tout le parcours : fichier, calculs, modules et rapport.',
  array[
    'Structurer un petit projet en modules',
    'Calculer moyenne, rang et mentions',
    'Générer un rapport lisible à partir d''un fichier'
  ],
  null,
  'Le projet final réunit les chapitres précédents : lire un fichier, valider les données, calculer, afficher. Commencez par écrire le flux en pseudo-code avant d''ouvrir l''éditeur.

Séparez les responsabilités : un module de chargement, un module de calcul, un module de rendu. Chaque fonction devient testable indépendamment, et le main.py ne fait qu''orchestrer.

La robustesse se joue sur les bords : colonnes manquantes, note vide, doublon, encoding inconnu. Chaque cas limite mérite un message clair plutôt qu''un stacktrace.

Terminez par le livrable : un rapport.txt que vous pourriez envoyer à un formateur. Produire un résultat exploitable est ce qui distingue un exercice d''un projet.',
  'Livrez l''analyseur complet : il lit notes.csv, affiche le top 3, la moyenne, la médiane, la mention de chaque étudiant, puis écrit rapport.txt. Ajoutez une option en ligne de commande (--csv chemin) et une gestion d''erreur si le fichier manque.',
  '[{"label":"Exemples de la documentation","url":"https://docs.python.org/fr/3/tutorial/index.html"}]',
  8, true
)
on conflict (id) do nothing;

insert into public.quiz_questions
  (id, chapter_id, question, choices, answer_index, explanation, position)
values
('py-c1-q1', 'py-c1', 'Quelle fonction affiche du texte dans la sortie standard ?',
 '["display()", "input()", "print()", "echo()"]', 2,
 'print() écrit une valeur dans la sortie ; input() sert à lire une saisie utilisateur.', 1),
('py-c1-q2', 'py-c1', 'Quel type Python est déduit pour la valeur 3.14 ?',
 '["int", "float", "str", "decimal"]', 1,
 'Un littéral avec une virgule décimale est un float ; int ne stocke que des entiers.', 2),
('py-c1-q3', 'py-c1', 'Que renvoie input() ?',
 '["Une chaîne de caractères", "Toujours un entier", "Un booléen", "None"]', 0,
 'input() renvoie toujours du texte : il faut convertir avec int() ou float() pour calculer.', 3),
('py-c1-q4', 'py-c1', 'Quelle conversion appliquer avant de concaténer un âge (entier) à du texte ?',
 '["float(age)", "int(age)", "Aucune, Python le fait", "str(age)"]', 3,
 'On ne peut pas additionner un int et un str : il faut convertir l''entier avec str().', 4),

('py-c2-q1', 'py-c2', 'Quelle instruction permet d''ajouter un cas alternatif à une condition ?',
 '["elif", "else if", "elseif", "except"]', 0,
 'Python utilise elif (contraction de else if) ; else ne porte aucune condition.', 1),
('py-c2-q2', 'py-c2', 'Que produit range(3) dans une boucle for ?',
 '["1, 2, 3", "0, 1, 2", "0, 1, 2, 3", "3"]', 1,
 'range(n) va de 0 jusqu''à n exclu : 3 itérations pour range(3).', 2),
('py-c2-q3', 'py-c2', 'Qu''est-ce qui interrompt immédiatement la boucle en cours ?',
 '["continue", "pass", "break", "return"]', 2,
 'break sort de la boucle ; continue saute à l''itération suivante.', 3),
('py-c2-q4', 'py-c2', 'Quand while True risque-t-il de bloquer le programme ?',
 '["Si la boucle contient un print", "Si on utilise des entiers", "Jamais", "Si la condition de sortie manque ou n''est jamais atteinte"]', 3,
 'Une boucle infinie survient lorsque rien ne modifie l''état vers la sortie.', 4),

('py-c3-q1', 'py-c3', 'Quel mot-clé définit une fonction ?',
 '["def", "function", "func", "fun"]', 0,
 'En Python, une fonction se déclare avec def nom(parametres):', 1),
('py-c3-q2', 'py-c3', 'Que renvoie une fonction sans instruction return ?',
 '["0", "None", "Une chaîne vide", "Elle ne peut pas être appelée"]', 1,
 'Sans return, la fonction renvoie implicitement None.', 2),
('py-c3-q3', 'py-c3', 'Quelle est la différence entre paramètre et argument ?',
 '["Aucune", "L''argument est toujours optionnel", "Le paramètre est le nom dans la définition, l''argument la valeur à l''appel", "Le paramètre est local, l''argument global"]', 2,
 'def saluer(nom) : nom est le paramètre ; saluer("Amina") : "Amina" est l''argument.', 3),
('py-c3-q4', 'py-c3', 'Pourquoi séparer le calcul de l''affichage dans deux fonctions ?',
 '["C''est obligatoire en Python", "Pour ralentir le programme", "Pour éviter les imports", "Pour tester le calcul sans affichage et réutiliser ailleurs"]', 3,
 'Une fonction qui fait une seule chose se teste et se réutilise plus facilement.', 4),

('py-c4-q1', 'py-c4', 'Quelle méthode ajoute un élément à la fin d''une liste ?',
 '["append()", "add()", "push()", "insert()"]', 0,
 'append() ajoute en fin ; insert() permet de préciser la position.', 1),
('py-c4-q2', 'py-c4', 'Comment parcourir les couples clé/valeur d''un dictionnaire ?',
 '["d.values()", "d.items()", "d.keys()", "d.pairs()"]', 1,
 'items() renvoie des tuples (clé, valeur) ; keys() et values() ne donnent qu''une face.', 2),
('py-c4-q3', 'py-c4', 'Que fait la compréhension [n for n in notes if n >= 10] ?',
 '["Affiche les notes", "Trie les notes", "Filtre les notes >= 10 dans une nouvelle liste", "Modifie les notes"]', 2,
 'La condition if filtre, la partie avant for construit la nouvelle liste.', 3),
('py-c4-q4', 'py-c4', 'Après b = a sur une liste, que se passe-t-il si on fait b.append(1) ?',
 '["Une erreur est levée", "Les deux listes sont copiées", "Seul b change", "a contient aussi 1"]', 3,
 'a et b référencent le même objet ; il faut list(a) pour copier.', 4),

('py-c5-q1', 'py-c5', 'Pourquoi utiliser with open(...) plutôt que open() suivi de close() ?',
 '["Le fichier se ferme automatiquement, même en cas d''erreur", "C''est plus rapide", "C''est obligatoire", "Cela compresse le fichier"]', 0,
 'Le bloc with garantit la fermeture, donc libère le descripteur même si une exception survient.', 1),
('py-c5-q2', 'py-c5', 'Que fait le mode "a" ?',
 '["Écrase le fichier", "Ajoute à la fin du fichier", "Crée un dossier", "Lit en binaire"]', 1,
 '"a" conserve le contenu existant et écrit à la fin ; "w" écrase.', 2),
('py-c5-q3', 'py-c5', 'Quel objet est le plus adapté pour lire un CSV ?',
 '["str.split()", "json.load()", "csv.DictReader", "os.walk()"]', 2,
 'DictReader transforme chaque ligne en dictionnaire selon les en-têtes.', 3),
('py-c5-q4', 'py-c5', 'Quelle pratique évite les problèmes d''accents à l''écriture ?',
 '["Ouvrir sans paramètre", "Utiliser le mode w", "Passer en binaire", "Préciser encoding utf-8"]', 3,
 'Sans encodage explicite, Python choisit l''encodage du système : précisez utf-8.', 4),

('py-c6-q1', 'py-c6', 'Que montre un traceback ?',
 '["La chaîne d''appels jusqu''à la ligne fautive", "La sortie du programme", "Le temps d''exécution", "La mémoire utilisée"]', 0,
 'Le traceback liste les appels empilés et se termine par le type d''exception.', 1),
('py-c6-q2', 'py-c6', 'Pourquoi éviter un except nu ?',
 '["Il est interdit", "Il masque les erreurs inattendues et rend le débogage difficile", "Il ralentit le code", "Il écrit dans un journal"]', 1,
 'Attraper tout sans distinguer empêche de voir les vrais bugs ; visez un type précis.', 2),
('py-c6-q3', 'py-c6', 'Que fait finally ?',
 '["Interrompt le programme", "Relance l''exception", "Exécute le bloc quoi qu''il arrive", "Exécute le bloc seulement en cas d''erreur"]', 2,
 'finally s''exécute toujours : fermeture de fichier, nettoyage, journalisation.', 3),
('py-c6-q4', 'py-c6', 'Quelle instruction crée une erreur métier explicite ?',
 '["print(msg)", "return None", "assert", "raise ValueError(msg)"]', 3,
 'raise déclenche l''exception choisie avec un message compréhensible.', 4),

('py-c7-q1', 'py-c7', 'Quelle différence entre import math et from math import sqrt ?',
 '["Le premier nomme le module math.sqrt, le second importe directement sqrt", "Aucune", "Le second est interdit", "Le premier est plus rapide"]', 0,
 'La forme d''import décrit comment accéder au symbole ensuite.', 1),
('py-c7-q2', 'py-c7', 'À quoi sert if __name__ == "__main__": ?',
 '["À déclarer une constante", "À exécuter le bloc seulement si le fichier est lancé directement", "À importer un package", "À définir le point d''entrée HTTP"]', 1,
 'Ce garde de port permet d''importer le module sans exécuter son code de démonstration.', 2),
('py-c7-q3', 'py-c7', 'Que contient requirements.txt ?',
 '["Les résultats des tests", "Les mots de passe", "Les dépendances et leurs versions", "Le code compilé"]', 2,
 'Ce fichier fige l''environnement pour pouvoir le reproduire ailleurs.', 3),
('py-c7-q4', 'py-c7', 'Que signifie un package Python ?',
 '["Un fichier .zip", "Un exécutable", "Un gestionnaire de dépendances", "Un dossier contenant des modules et un __init__.py"]', 3,
 'Le dossier devient importable grâce à __init__.py.', 4),

('py-c8-q1', 'py-c8', 'Quelle structure de projet limite les fichiers géants ?',
 '["Découper par responsabilités : calcul, chargement, rendu", "Un seul main.py", "Un fichier par variable", "Ne pas de modules"]', 0,
 'Séparer les rôles rend chaque module testable et réutilisable.', 1),
('py-c8-q2', 'py-c8', 'Qu''est-ce qu''une donnée « cas limite » à prévoir ?',
 '["Une note de 20", "Une note vide ou un fichier absent", "Un nom en majuscules", "Un fichier UTF-8"]', 1,
 'Les bords (valeurs manquantes, fichier absent) provoquent la majorité des incidents.', 2),
('py-c8-q3', 'py-c8', 'Comment gérer l''absence du fichier CSV ?',
 '["Créer un fichier vide silencieusement", "Ignorer", "Crasher volontairement", "Attraper FileNotFoundError et afficher un message clair"]', 3,
 'L''utilisateur doit comprendre ce qui manque et comment corriger.', 3),
('py-c8-q4', 'py-c8', 'Qu''apporte le port --csv chemin en ligne de commande ?',
 '["Accélère le calcul", "Sécurise le mot de passe", "Permet de tester avec différents fichiers sans modifier le code", "Rien d''utile"]', 2,
 'Paramétrer le chemin rend le script réutilisable et testable.', 4)
on conflict (id) do nothing;
