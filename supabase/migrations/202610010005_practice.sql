-- easyLearn — étape pratique : outils de pratique par catégorie + code par chapitre
-- Phase 1 (sans exécution serveur) : éditeur Python en lecture/solution,
-- playground HTML exécuté uniquement dans le navigateur, checklists maison.
-- Idempotent : peut être réappliqué sans effet de bord.

-- 1. Outil de pratique par catégorie ----------------------------------------

create table if not exists public.practice_tools (
  id text primary key,
  category_id text not null unique references public.categories (id) on delete cascade,
  kind text not null default 'lab_checklist'
    check (kind in ('code_editor', 'html_playground', 'lab_checklist', 'terminal_simule', 'aucun')),
  label text not null default '',
  config jsonb not null default '{}',
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists practice_tools_set_updated_at on public.practice_tools;
create trigger practice_tools_set_updated_at
  before update on public.practice_tools
  for each row execute function public.set_updated_at();

-- 2. Code de départ et solution par chapitre --------------------------------

alter table public.chapters
  add column if not exists starter_code text not null default '',
  add column if not exists code_language text not null default '',
  add column if not exists solution_code text not null default '';

-- 3. État pratique dans la progression de l'apprenant ------------------------

alter table public.chapter_progress
  add column if not exists practice_done boolean not null default false,
  add column if not exists solution_viewed boolean not null default false;

-- 4. Row Level Security ------------------------------------------------------

alter table public.practice_tools enable row level security;

drop policy if exists "practice_tools_select" on public.practice_tools;
create policy "practice_tools_select" on public.practice_tools
  for select to authenticated
  using (enabled or public.is_admin());

drop policy if exists "practice_tools_admin_write" on public.practice_tools;
create policy "practice_tools_admin_write" on public.practice_tools
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- 5. Seed : un outil par catégorie (10) --------------------------------------
-- prog / ai : éditeur Python sans exécution (code de départ + solution).
-- web : playground HTML/CSS/JS exécuté uniquement dans le navigateur.
-- Les autres sont créés désactivés : leur contenu arrive en phase 2.

insert into public.practice_tools (id, category_id, kind, label, config, enabled) values
  ('tool-prog', 'prog', 'code_editor', 'Éditeur Python', '{"language":"python"}', true),
  ('tool-ai', 'ai', 'code_editor', 'Éditeur Python (data)', '{"language":"python"}', true),
  ('tool-web', 'web', 'html_playground', 'Atelier HTML / CSS / JS', '{"language":"html"}', true),
  ('tool-cyber', 'cyber', 'terminal_simule', 'Terminal de sécurité', '{}', false),
  ('tool-net', 'net', 'lab_checklist', 'Laboratoire réseau', '{"items":[]}', false),
  ('tool-embedded', 'embedded', 'lab_checklist', 'Banc d''essai embarqué', '{"items":[]}', false),
  ('tool-electronics', 'electronics', 'lab_checklist', 'Établi électronique', '{"items":[]}', false),
  ('tool-physics', 'physics', 'lab_checklist', 'Banc de mesure', '{"items":[]}', false),
  ('tool-mecha', 'mecha', 'lab_checklist', 'Atelier mécatronique', '{"items":[]}', false),
  ('tool-cloud', 'cloud', 'terminal_simule', 'Terminal Cloud / DevOps', '{}', false)
on conflict (id) do nothing;

-- 6. Seed : code de départ + solution des 8 chapitres Python ----------------
-- Déduits des exercices du parcours Python (migrations 0002). N'écrase jamais
-- une saisie déjà remplie (starter_code <> '') : réapplication sans effet.

update public.chapters set
  code_language = 'python',
  starter_code =
'# Demande l''âge, calcule l''âge dans 10 ans, gère une saisie invalide.

saisie = input("Votre âge : ")

# 1. Convertissez la saisie en entier (attrapez le cas invalide).

# 2. Affichez : "Dans 10 ans, vous aurez X ans."
',
  solution_code =
'try:
    age = int(input("Votre âge : "))
except ValueError:
    print("Saisie invalide")
else:
    print(f"Dans 10 ans, vous aurez {age + 10} ans.")
'
where id = 'py-c1' and starter_code = '';

update public.chapters set
  code_language = 'python',
  starter_code =
'import random

secret = random.randint(1, 50)
essais = 0

while True:
    proposition = int(input("Votre proposition : "))
    essais += 1
    # Comparez avec secret : affichez "Plus !" ou "Moins !",
    # et terminez avec break en affichant le nombre d''essais.
',
  solution_code =
'import random

secret = random.randint(1, 50)
essais = 0

while True:
    proposition = int(input("Votre proposition : "))
    essais += 1
    if proposition < secret:
        print("Plus !")
    elif proposition > secret:
        print("Moins !")
    else:
        print(f"Bravo, trouvé en {essais} essais !")
        break
'
where id = 'py-c2' and starter_code = '';

update public.chapters set
  code_language = 'python',
  starter_code =
'def moyenne(notes):
    # Retournez la moyenne de la liste (0 si elle est vide).
    pass

def mention(moy):
    # "A" au-dessus de 16, "B" au-dessus de 14, "C" au-dessus de 12, sinon "D".
    pass

notes = [12, 15, 8, 17, 14]
# Affichez la moyenne puis sa mention.
',
  solution_code =
'def moyenne(notes):
    if not notes:
        return 0
    return sum(notes) / len(notes)

def mention(moy):
    if moy > 16:
        return "A"
    if moy > 14:
        return "B"
    if moy > 12:
        return "C"
    return "D"

notes = [12, 15, 8, 17, 14]
moy = moyenne(notes)
print(f"Moyenne : {moy:.1f} — mention {mention(moy)}")
'
where id = 'py-c3' and starter_code = '';

update public.chapters set
  code_language = 'python',
  starter_code =
'classe = [
    {"nom": "Amina", "note": 14},
    {"nom": "Patrick", "note": 9},
    {"nom": "Grace", "note": 17},
    {"nom": "Eric", "note": 12},
]

# 1. La moyenne de la classe
# 2. La note maximale
# 3. Les noms au-dessus de la moyenne, tries par ordre alphabetique
',
  solution_code =
'classe = [
    {"nom": "Amina", "note": 14},
    {"nom": "Patrick", "note": 9},
    {"nom": "Grace", "note": 17},
    {"nom": "Eric", "note": 12},
]

notes = [etudiant["note"] for etudiant in classe]
moyenne = sum(notes) / len(notes)
maximum = max(notes)
au_dessus = sorted(e["nom"] for e in classe if e["note"] > moyenne)

print(f"Moyenne : {moyenne:.1f}")
print(f"Note maximale : {maximum}")
print("Au-dessus de la moyenne :", ", ".join(au_dessus))
'
where id = 'py-c4' and starter_code = '';

update public.chapters set
  code_language = 'python',
  starter_code =
'import csv

# notes.csv contient les colonnes nom,note

# 1. Lisez le fichier avec csv.DictReader (encoding="utf-8")

# 2. Calculez la moyenne et la note maximale

# 3. Ecrivez rapport.txt : moyenne, note max et mentions obtenues
',
  solution_code =
'import csv

with open("notes.csv", encoding="utf-8") as fichier:
    lignes = list(csv.DictReader(fichier))

notes = [float(ligne["note"]) for ligne in lignes]
moyenne = sum(notes) / len(notes)
maximum = max(notes)

def mention(note):
    if note > 16:
        return "A"
    if note > 14:
        return "B"
    if note > 12:
        return "C"
    return "D"

mentions = sorted(mention(note) for note in notes)

with open("rapport.txt", "w", encoding="utf-8") as rapport:
    rapport.write(f"Moyenne : {moyenne:.1f}\n")
    rapport.write(f"Note maximale : {maximum}\n")
    rapport.write("Mentions : " + ", ".join(mentions) + "\n")
'
where id = 'py-c5' and starter_code = '';

update public.chapters set
  code_language = 'python',
  starter_code =
'def moyenne_validee(notes):
    # Chaque note doit etre entre 0 et 20, sinon levez
    # ValueError("note hors bornes").
    pass

notes = [12, 15, 25]

# Entourez l''appel d''un try/except qui affiche un message clair.
',
  solution_code =
'def moyenne_validee(notes):
    for note in notes:
        if note < 0 or note > 20:
            raise ValueError("note hors bornes")
    return sum(notes) / len(notes)

notes = [12, 15, 25]

try:
    print(f"Moyenne : {moyenne_validee(notes):.1f}")
except ValueError as erreur:
    print(f"Impossible de calculer : {erreur}")
'
where id = 'py-c6' and starter_code = '';

update public.chapters set
  code_language = 'python',
  starter_code =
'# calc.py
def moyenne(notes):
    return sum(notes) / len(notes)

def mention(moy):
    # A completer (regle du chapitre 3).
    pass

# main.py
# 1. Importez moyenne et mention depuis calc.
# 2. Protegez l''affichage avec if __name__ == "__main__":.
# 3. Ajoutez requirements.txt avec une dependance reellement utilisee.
',
  solution_code =
'# calc.py
def moyenne(notes):
    return sum(notes) / len(notes)

def mention(moy):
    if moy > 16:
        return "A"
    if moy > 14:
        return "B"
    if moy > 12:
        return "C"
    return "D"

# main.py
# from calc import moyenne, mention
#
# if __name__ == "__main__":
#     notes = [12, 15, 8]
#     moy = moyenne(notes)
#     print(moy, mention(moy))
'
where id = 'py-c7' and starter_code = '';

update public.chapters set
  code_language = 'python',
  starter_code =
'import argparse
import csv

def charger(chemin):
    # Lisez le CSV et retournez la liste des etudiants.
    pass

def statistiques(etudiants):
    # Retournez moyenne, mediane, top 3 et mentions.
    pass

def main():
    parser = argparse.ArgumentParser(description="Analyseur de notes")
    parser.add_argument("--csv", default="notes.csv")
    args = parser.parse_args()

    # 1. Chargez les donnees (gerez le fichier absent)

    # 2. Affichez les statistiques

    # 3. Ecrivez rapport.txt

if __name__ == "__main__":
    main()
',
  solution_code =
'import argparse
import csv

def charger(chemin):
    with open(chemin, encoding="utf-8") as fichier:
        return list(csv.DictReader(fichier))

def mention(note):
    if note > 16:
        return "A"
    if note > 14:
        return "B"
    if note > 12:
        return "C"
    return "D"

def statistiques(etudiants):
    notes = sorted(float(e["note"]) for e in etudiants)
    moyenne = sum(notes) / len(notes)
    milieu = len(notes) // 2
    mediane = (
        notes[milieu]
        if len(notes) % 2
        else (notes[milieu - 1] + notes[milieu]) / 2
    )
    top3 = sorted(etudiants, key=lambda e: float(e["note"]), reverse=True)[:3]
    mentions = [mention(float(e["note"])) for e in etudiants]
    return moyenne, mediane, top3, mentions

def main():
    parser = argparse.ArgumentParser(description="Analyseur de notes")
    parser.add_argument("--csv", default="notes.csv")
    args = parser.parse_args()

    try:
        etudiants = charger(args.csv)
    except FileNotFoundError:
        print(f"Fichier introuvable : {args.csv}")
        return

    moyenne, mediane, top3, mentions = statistiques(etudiants)
    print(f"Moyenne : {moyenne:.1f} - Mediane : {mediane:.1f}")
    for rang, etudiant in enumerate(top3, start=1):
        nom = etudiant["nom"]
        note = etudiant["note"]
        print(f"{rang}. {nom} : {note}")

    with open("rapport.txt", "w", encoding="utf-8") as rapport:
        rapport.write(f"Moyenne : {moyenne:.1f}\n")
        rapport.write(f"Mediane : {mediane:.1f}\n")

if __name__ == "__main__":
    main()
'
where id = 'py-c8' and starter_code = '';
