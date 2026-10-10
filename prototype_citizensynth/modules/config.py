# -*- coding: utf-8 -*-
"""Configuration globale du prototype CitizenSynth."""

import os

# Chemins
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
OUTPUT_DIR = os.path.join(BASE_DIR, "output")

os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Fichier de donnees par defaut
DEFAULT_CSV = os.path.join(DATA_DIR, "contributions_demo.csv")

# Configuration du LLM (Ollama - execution locale, confidentialite des donnees)
OLLAMA_MODEL = os.environ.get("CITIZENSYNTH_MODEL", "mistral:7b")
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
LLM_BATCH_SIZE = 20  # nombre de contributions par requete LLM
LLM_TEMPERATURE = 0.2  # faible temperature = sorties plus stables

# Themes predefinis (budget participatif)
THEMES = [
    "voirie",
    "assainissement",
    "eclairage_public",
    "eau_potable",
    "securite",
    "marches",
    "education",
    "sante",
]

THEME_LABELS = {
    "voirie": "Voirie",
    "assainissement": "Assainissement",
    "eclairage_public": "Eclairage public",
    "eau_potable": "Eau potable",
    "securite": "Securite",
    "marches": "Marches",
    "education": "Education",
    "sante": "Sante",
}

# Positions possibles
POSITIONS = ["favorable", "defavorable", "nuancee", "indeterminee"]

# Seuils
MIN_WORDS = 5  # en dessous : contribution "indeterminee"
MIN_CONFIDENCE_THEME = 0.35
