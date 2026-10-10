# -*- coding: utf-8 -*-
"""Module d'analyse thematique et d'extraction des positions.

Deux strategies :
1. Analyse par LLM (Ollama, execution locale) - principale
2. Classification de secours par mots-cles + embeddings (sans LLM)

Sortie : pour chaque contribution -> themes, position, arguments, confiance
"""

import json
import re
from typing import Optional

import numpy as np
import pandas as pd

try:
    import ollama
    HAS_OLLAMA = True
except ImportError:
    HAS_OLLAMA = False

try:
    from sentence_transformers import SentenceTransformer, util
    HAS_ST = True
except ImportError:
    HAS_ST = False

from config import (
    LLM_BATCH_SIZE,
    LLM_TEMPERATURE,
    MIN_CONFIDENCE_THEME,
    MIN_WORDS,
    OLLAMA_HOST,
    OLLAMA_MODEL,
    POSITIONS,
    THEMES,
)

# ----------------------------------------------------------------------
# Mots-cles de secours (utilises si LLM ou embeddings indisponibles)
# ----------------------------------------------------------------------
KEYWORDS = {
    "voirie": ["route", "rue", "chaussee", "voirie", "piste", "tranchee",
               "bitume", "asphalte", "nid-de-poussiere", "poussiere", "boue",
               "glissement", "accident", "pieton", "circulation"],
    "assainissement": ["egout", "caniveau", "drainage", "assainissement",
                       "inondation", "fange", "deversement", "evacuation",
                       "eaux-usees", "puits", "fosses"],
    "eclairage_public": ["eclairage", "lampadaire", "lampe", "lumiere",
                         "electricite", "sonner", "tenebre", "nuit",
                         "safety-light", "poteau"],
    "eau_potable": ["eau", "robinet", "puits", "forage", "nappe", "soif",
                    "eau-potable", "distribution-eau", "borne-fontaine"],
    "securite": ["securite", "vol", "cambriolage", "brigade", "police",
                 "poste-de-police", "milice", "insécurite", "insécurite",
                 "brigade-mobile", "alarme", "vigie"],
    "marches": ["marche", "etal", "etallage", "vendeur", "commercant",
                "etale", "produits", "approvisionnement", "marche-central"],
    "education": ["ecole", "college", "lycee", "scolaire", "eleve", "enseignant",
                  "classe", "frais-scolaires", "bursier", "universite"],
    "sante": ["sante", "hopital", "centro-de-sante", "dispensaire", "medecin",
              "infirmier", "medicament", "vaccination", "maternite", "maladie"],
}

POSITION_PATTERNS = {
    "favorable": [
        r"\b(favorable|d accord|daccord|bravo|merci|excellent|bonne initiative|"
        r"soutenons|approuvons|oui pour|il faut continuer|reussite|felicitations)\b"
    ],
    "defavorable": [
        r"\b(defavorable|contre|opposition|mauvais|catastroph|n importe quoi|"
        r"nimporte quoi|arnaque|vol|gaspillage|inutile|jamais|echec|honte|"
        r"promesses? non tenues?|toujours pas|encore rien)\b"
    ],
    "nuancee": [
        r"\b(cependant|toutefois|mais|sauf|si .{0,40}alors|a condition|"
        r"partiellement|d accord mais|oui mais|favorable si|acceptable si)\b"
    ],
}


def keyword_classify(text: str) -> list[str]:
    """Classement heuristique par mots-cles (secours / baseline)."""
    text_l = text.lower()
    scores = {}
    for theme, kws in KEYWORDS.items():
        score = sum(1 for kw in kws if kw in text_l)
        if score > 0:
            scores[theme] = score
    if not scores:
        return []
    max_score = max(scores.values())
    return [t for t, s in scores.items() if s >= max_score and s >= 1]


def keyword_position(text: str) -> str:
    """Detection heuristique de la position."""
    text_l = text.lower()
    score_pos = sum(1 for p in POSITION_PATTERNS["favorable"] if re.search(p, text_l))
    score_neg = sum(1 for p in POSITION_PATTERNS["defavorable"] if re.search(p, text_l))
    score_nua = sum(1 for p in POSITION_PATTERNS["nuancee"] if re.search(p, text_l))
    if score_nua > 0 and (score_pos > 0 or score_neg > 0):
        return "nuancee"
    if score_pos > score_neg:
        return "favorable"
    if score_neg > score_pos:
        return "defavorable"
    return "indeterminee"


# ----------------------------------------------------------------------
# Analyse par LLM (Ollama)
# ----------------------------------------------------------------------
PROMPT_TEMPLATE = """Tu es un assistant d'analyse de consultations citoyennes en RDC.
A partir du texte de la contribution ci-dessous, retourne UNIQUEMENT un objet JSON valide
avec exactement ces cles :
{{
  "themes": ["un ou plusieurs parmi : voirie, assainissement, eclairage_public, eau_potable, securite, marches, education, sante"],
  "position": "favorable" | "defavorable" | "nuancee" | "indeterminee",
  "arguments": ["phrase-cle 1", "phrase-cle 2"],
  "proposition": "texte de la proposition constructive si presente, sinon null",
  "confiance": nombre entre 0 et 1
}}
Ne produis aucun texte hors du JSON.

Contribution :
{texte}
"""


def build_llm_client():
    """Retourne un client Ollama ou None."""
    if not HAS_OLLAMA:
        return None
    try:
        client = ollama.Client(host=OLLAMA_HOST)
        client.list()  # test de connexion
        return client
    except Exception:
        return None


def parse_llm_json(raw: str) -> Optional[dict]:
    """Extrait un JSON robuste de la sortie du LLM."""
    if not raw:
        return None
    # tente d'abord un JSON direct
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        pass
    # cherche un bloc { ... }
    m = re.search(r"\{.*\}", raw, re.DOTALL)
    if m:
        try:
            return json.loads(m.group(0))
        except json.JSONDecodeError:
            return None
    return None


def normalize_theme(t: str) -> Optional[str]:
    t = t.strip().lower().replace(" ", "_").replace("-", "_")
    aliases = {
        "eclairage": "eclairage_public",
        "electricite": "eclairage_public",
        "securite_publique": "securite",
        "marche": "marches",
        "ecoles": "education",
        "hopital": "sante",
        "sante_publique": "sante",
    }
    t = aliases.get(t, t)
    return t if t in THEMES else None


def analyze_with_llm(client, texts: list[str], batch_size: int = LLM_BATCH_SIZE) -> list[dict]:
    """Analyse une liste de textes par le LLM, par lots."""
    results = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        for text in batch:
            prompt = PROMPT_TEMPLATE.format(texte=text)
            try:
                resp = client.generate(
                    model=OLLAMA_MODEL,
                    prompt=prompt,
                    options={"temperature": LLM_TEMPERATURE},
                    stream=False,
                )
                data = parse_llm_json(resp.get("response", ""))
            except Exception:
                data = None

            if data is None:
                # secours heuristique
                results.append({
                    "themes": keyword_classify(text),
                    "position": keyword_position(text),
                    "arguments": [],
                    "proposition": None,
                    "confiance": 0.0,
                    "methode": "heuristique",
                })
                continue

            themes = [normalize_theme(t) for t in data.get("themes", [])]
            themes = [t for t in themes if t]
            position = data.get("position", "indeterminee")
            if position not in POSITIONS:
                position = "indeterminee"
            conf = data.get("confiance", 0.5)
            try:
                conf = float(conf)
            except (TypeError, ValueError):
                conf = 0.5
            results.append({
                "themes": themes,
                "position": position,
                "arguments": data.get("arguments", []) or [],
                "proposition": data.get("proposition"),
                "confiance": max(0.0, min(1.0, conf)),
                "methode": "llm",
            })
    return results


# ----------------------------------------------------------------------
# Classification de secours par embeddings (optionnel)
# ----------------------------------------------------------------------
_EMB_MODEL = None


def _get_embedder():
    global _EMB_MODEL
    if not HAS_ST:
        return None
    if _EMB_MODEL is None:
        try:
            _EMB_MODEL = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
        except Exception:
            return None
    return _EMB_MODEL


THEME_EXAMPLES = {
    "voirie": "Il faut reparer les routes et les caniveaux de notre quartier qui sont en tres mauvais etat.",
    "assainissement": "Les eaux usees se deversent dans la rue a cause du manque de drainage et de caniveaux obstrues.",
    "eclairage_public": "Il n'y a aucun lampadaire fonctionnel, la nuit notre rue est totalement sombre et dangereuse.",
    "eau_potable": "Nous n'avons pas d'eau potable, le robinet est seche depuis des mois et nous devons acheter de l'eau.",
    "securite": "La securite s'est degradee, il y a des vols frequentes et aucun poste de police a proximite.",
    "marches": "Le marche a besoin d'etals convenables et d'un approvisionnement regular en produits de base.",
    "education": "L'ecole du quartier manque de salles de classe et les enseignants ne sont pas payes.",
    "sante": "Le centre de sante n'a pas de medicaments ni de medecin, les habitants souffrent sans soins.",
}


def embed_classify(text: str, embedder) -> list[str]:
    """Classement par similarite cosine avec des exemples de themes."""
    ex_texts = list(THEME_EXAMPLES.values())
    ex_themes = list(THEME_EXAMPLES.keys())
    emb_ex = embedder.encode(ex_texts, convert_to_tensor=True)
    emb_txt = embedder.encode([text], convert_to_tensor=True)
    cos = util.cos_sim(emb_txt, emb_ex)[0].cpu().numpy()
    best = int(np.argmax(cos))
    if cos[best] >= MIN_CONFIDENCE_THEME:
        return [ex_themes[best]]
    return []


# ----------------------------------------------------------------------
# Point d'entree principal
# ----------------------------------------------------------------------
def analyze_corpus(df: pd.DataFrame, use_llm: bool = True) -> pd.DataFrame:
    """Analyse l'ensemble du corpus et ajoute les colonnes d'analyse."""
    df = df.copy()
    client = build_llm_client() if use_llm else None
    embedder = _get_embedder()

    analyses = []
    texts = df["texte_anonymise"].tolist()
    trop_courtes = df["trop_courte"].tolist()

    if client is not None:
        print(f"[Analyse] LLM actif : {OLLAMA_MODEL} ({len(texts)} contributions)")
        analyses = analyze_with_llm(client, texts)
    else:
        print("[Analyse] LLM indisponible -> secours heuristique / embeddings")
        for text, court in zip(texts, trop_courtes):
            if court:
                analyses.append({
                    "themes": [], "position": "indeterminee",
                    "arguments": [], "proposition": None,
                    "confiance": 0.0, "methode": "court",
                })
                continue
            themes = embed_classify(text, embedder) if embedder else []
            if not themes:
                themes = keyword_classify(text)
            analyses.append({
                "themes": themes,
                "position": keyword_position(text),
                "arguments": [],
                "proposition": None,
                "confiance": 0.5,
                "methode": "embeddings" if embedder else "heuristique",
            })

    # Contributions marquees trop courtes : force indeterminee
    for i, court in enumerate(trop_courtes):
        if court:
            analyses[i]["position"] = "indeterminee"
            analyses[i]["confiance"] = 0.0

    df["themes"] = [a["themes"] for a in analyses]
    df["position"] = [a["position"] for a in analyses]
    df["arguments"] = [a["arguments"] for a in analyses]
    df["proposition"] = [a["proposition"] for a in analyses]
    df["confiance"] = [a["confiance"] for a in analyses]
    df["methode_analyse"] = [a["methode"] for a in analyses]
    df["theme_principal"] = df["themes"].apply(lambda ts: ts[0] if ts else None)
    return df


if __name__ == "__main__":
    demo = pd.DataFrame({
        "id": [1],
        "texte": ["Il faut enfin reparer les routes de notre quartier, c'est une honte."],
    })
    from pretraitement import preprocess_corpus
    demo = preprocess_corpus(demo)
    out = analyze_corpus(demo, use_llm=False)
    print(out[["id", "themes", "position", "methode_analyse"]])
