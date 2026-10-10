# -*- coding: utf-8 -*-
"""Module de pretraitement des contributions citoyennes.

Responsabilites :
- chargement du corpus (CSV)
- nettoyage Unicode et suppression des caracteres parasites
- anonymisation basique (telephone, emails, noms courants)
- filtrage des contributions non pertinentes
"""

import re
import unicodedata

import pandas as pd

# Patterns de donnees personnelles a masquer
PHONE_RE = re.compile(r"(\+?243|0)?[\s.-]?[0-9]{2,3}[\s.-]?[0-9]{3}[\s.-]?[0-9]{3,4}")
EMAIL_RE = re.compile(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
LONG_NAME_RE = re.compile(
    r"\b([A-Z][a-z]{2,}\s+){1,2}[A-Z][a-z]{2,}\b"
)  # "Jean-Pierre Kalala" -> masque (approx.)

EMOJI_RE = re.compile(
    "["
    "\U0001F600-\U0001F64F"
    "\U0001F300-\U0001F5FF"
    "\U0001F680-\U0001F6FF"
    "\U0001F1E0-\U0001F1FF"
    "\u2600-\u26FF"
    "\u2700-\u27BF"
    "]+",
    flags=re.UNICODE,
)

NOISE_RE = re.compile(r"[^\w\sàâäéèêëïîôöùûüçœ'-]", re.UNICODE)


def load_corpus(csv_path: str) -> pd.DataFrame:
    """Charge un CSV de contributions (colonnes : id, date, quartier, texte)."""
    df = pd.read_csv(csv_path, encoding="utf-8")
    required = {"texte"}
    if not required.issubset(set(c.lower() for c in df.columns)):
        raise ValueError("Le CSV doit contenir au moins une colonne 'texte'.")
    df.columns = [c.strip().lower() for c in df.columns]
    if "id" not in df.columns:
        df["id"] = range(1, len(df) + 1)
    return df


def anonymize(text: str) -> str:
    """Masque les donnees personnelles identifiables dans un texte."""
    text = PHONE_RE.sub("[TELEPHONE]", text)
    text = EMAIL_RE.sub("[EMAIL]", text)
    # Noms propres en debut de phrase seulement (heuristique prudente)
    text = re.sub(r"^([A-Z][a-z]{2,}\s+){1,2}[A-Z][a-z]{2,}", "[NOM]", text)
    return text


def clean_text(text: str) -> str:
    """Nettoyage courant : Unicode, emoji, caracteres parasites."""
    if not isinstance(text, str):
        return ""
    text = unicodedata.normalize("NFKC", text)
    text = EMOJI_RE.sub(" ", text)
    text = NOISE_RE.sub(" ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def preprocess_corpus(df: pd.DataFrame) -> pd.DataFrame:
    """Applique le pipeline de pretraitement complet."""
    df = df.copy()
    df["texte_clean"] = df["texte"].astype(str).apply(clean_text)
    df["texte_anonymise"] = df["texte_clean"].apply(anonymize)
    df["nb_mots"] = df["texte_anonymise"].apply(lambda t: len(t.split()))

    # Contribution trop courte -> marque "trop_courte"
    df["trop_courte"] = df["nb_mots"] < 5

    # Doublons exacts apres nettoyage
    df["doublon"] = df["texte_clean"].duplicated(keep="first")

    # Filtrage final
    df["exploitable"] = (~df["doublon"]) & (df["nb_mots"] > 0)
    return df


def corpus_stats(df: pd.DataFrame) -> dict:
    """Retourne des statistiques simples sur le corpus pretraite."""
    total = len(df)
    exploitables = int(df["exploitable"].sum())
    courts = int(df["trop_courte"].sum())
    doublons = int(df["doublon"].sum())
    ecartes = total - exploitables
    return {
        "total": total,
        "exploitables": exploitables,
        "trop_courts": courts,
        "doublons": doublons,
        "ecartes": ecartes,
        "taux_exploitation": round(100 * exploitables / total, 1) if total else 0.0,
    }


if __name__ == "__main__":
    # Petit test autonome
    exemple = pd.DataFrame(
        {"id": [1, 2, 3], "texte": [
            "Les routes de notre quartier sont catastrophiques, il faut intervenir !!!",
            "Contactez moi au 0998123456 pour plus d'infos",
            "",
        ]}
    )
    out = preprocess_corpus(exemple)
    print(out[["id", "texte_clean", "texte_anonymise", "nb_mots", "trop_courte", "exploitable"]])
