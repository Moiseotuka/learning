# -*- coding: utf-8 -*-
"""Backend API du prototype CitizenSynth (FastAPI).

Expose le pipeline d'analyse via une API REST consommee par l'application Flutter.

Lancement :
    pip install fastapi uvicorn python-multipart
    uvicorn api_fastapi:app --host 0.0.0.0 --port 8000
"""

import os
import sys
from io import BytesIO
from typing import Optional

import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "modules"))

from config import DEFAULT_CSV, OLLAMA_MODEL, POSITIONS, THEME_LABELS  # noqa: E402
from pretraitement import load_corpus, preprocess_corpus, corpus_stats  # noqa: E402
from analyse import analyze_corpus, build_llm_client  # noqa: E402
from synthese import generer_syntheses, formater_texte, generer_rapport_global  # noqa: E402

app = FastAPI(
    title="CitizenSynth API",
    description="Analyse automatique des contributions citoyennes par LLM.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # en production : restreindre aux domaines de l'app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Cache simple en memoire pour eviter de reanalyser a chaque appel
_CACHE: dict[str, dict] = {}


def _analyze_to_dict(df: pd.DataFrame, use_llm: bool) -> dict:
    """Lance le pipeline et serialise le resultat en dictionnaire JSON-safe."""
    df = preprocess_corpus(df)
    df = analyze_corpus(df, use_llm=use_llm)
    stats = corpus_stats(df)
    syntheses = generer_syntheses(df)

    contributions = []
    for _, row in df.iterrows():
        contributions.append({
            "id": int(row["id"]) if pd.notna(row.get("id")) else None,
            "texte": row.get("texte_anonymise", ""),
            "themes": row.get("themes") or [],
            "themePrincipal": row.get("theme_principal"),
            "position": row.get("position", "indeterminee"),
            "arguments": row.get("arguments") or [],
            "proposition": row.get("proposition"),
            "confiance": float(row.get("confiance", 0.0) or 0.0),
            "methode": row.get("methode_analyse", ""),
        })

    # serialisation des syntheses (tuples cles -> str)
    syn_serial = {}
    for theme, s in syntheses.items():
        syn_serial[theme] = {
            "theme": s["theme"],
            "libelle": s["libelle"],
            "totalContributions": s["total_contributions"],
            "distributionPositions": s["distribution_positions"],
            "pointsBlocage": s["points_blocage"],
            "propositions": s["propositions"],
            "verbatims": s["verbatims"],
            "confianceMoyenne": s["confiance_moyenne"],
        }

    # distribution des themes
    theme_counts = {}
    for c in contributions:
        for t in c["themes"]:
            label = THEME_LABELS.get(t, t)
            theme_counts[label] = theme_counts.get(label, 0) + 1

    # distribution des positions
    pos_counts = {}
    for c in contributions:
        p = c["position"]
        pos_counts[p] = pos_counts.get(p, 0) + 1

    return {
        "stats": stats,
        "themeDistribution": theme_counts,
        "positionDistribution": pos_counts,
        "syntheses": syn_serial,
        "contributions": contributions,
        "rapport": generer_rapport_global(df, syntheses),
    }


@app.get("/health")
def health():
    client = build_llm_client()
    return {
        "status": "ok",
        "llm": OLLAMA_MODEL if client else "indisponible (mode heuristique)",
    }


@app.post("/analyser")
async def analyser(
    file: Optional[UploadFile] = File(None),
    use_llm: bool = True,
):
    """Analyse un CSV de contributions (colonne 'texte' obligatoire).
    Si aucun fichier n'est fourni, utilise le corpus de demonstration."""
    cache_key = "demo" if file is None else file.filename

    try:
        if file is not None:
            content = await file.read()
            df = pd.read_csv(BytesIO(content))
            df.columns = [c.strip().lower() for c in df.columns]
            if "texte" not in df.columns:
                raise HTTPException(400, "Le CSV doit contenir une colonne 'texte'.")
            if "id" not in df.columns:
                df["id"] = range(1, len(df) + 1)
        else:
            df = load_corpus(DEFAULT_CSV)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(400, f"Erreur de lecture du CSV : {e}")

    result = _analyze_to_dict(df, use_llm=use_llm)
    _CACHE[cache_key] = result
    return JSONResponse(content=result)


@app.get("/resultats-demo")
def resultats_demo():
    """Retourne les resultats en cache (demo) ou les recalcule."""
    if "demo" in _CACHE:
        return _CACHE["demo"]
    df = load_corpus(DEFAULT_CSV)
    result = _analyze_to_dict(df, use_llm=True)
    _CACHE["demo"] = result
    return JSONResponse(content=result)


@app.get("/themes")
def themes():
    from config import THEMES
    return {
        "themes": [{"id": t, "libelle": THEME_LABELS[t]} for t in THEMES],
        "positions": POSITIONS,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
