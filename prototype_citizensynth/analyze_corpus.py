#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CitizenSynth — Analyse automatique des contributions citoyennes.

Usage :
    python analyze_corpus.py --input data/contributions_demo.csv
    python analyze_corpus.py --input fichier.csv --no-llm
    python analyze_corpus.py --input fichier.csv --annotate fichier_annotes.csv

Le fichier CSV d'entree doit contenir au moins la colonne 'texte'.
Colonnes optionnelles : id, date, quartier.
Pour l'evaluation, fournir un CSV de reference avec colonnes :
    id, themes_reference (separes par |), position_reference
"""

import argparse
import json
import os
import sys
import time

import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "modules"))

from config import DEFAULT_CSV, OUTPUT_DIR, THEMES  # noqa: E402
from pretraitement import load_corpus, preprocess_corpus, corpus_stats  # noqa: E402
from analyse import analyze_corpus  # noqa: E402
from synthese import generer_syntheses, formater_texte, generer_rapport_global  # noqa: E402
from evaluation import evaluer_themes, evaluer_positions, rapport_evaluation  # noqa: E402


def parse_args():
    parser = argparse.ArgumentParser(
        description="Analyse des contributions citoyennes par LLM."
    )
    parser.add_argument(
        "--input", "-i", default=DEFAULT_CSV,
        help="Chemin vers le CSV des contributions (colonne 'texte' obligatoire)."
    )
    parser.add_argument(
        "--output", "-o", default=OUTPUT_DIR,
        help="Dossier de sortie pour les resultats."
    )
    parser.add_argument(
        "--no-llm", action="store_true",
        help="Desactive le LLM (secours heuristique/embeddings uniquement)."
    )
    parser.add_argument(
        "--annotate", default=None,
        help="CSV d'annotation de reference pour l'evaluation (id, themes_reference, position_reference)."
    )
    return parser.parse_args()


def main():
    args = parse_args()
    out_dir = args.output
    os.makedirs(out_dir, exist_ok=True)

    print("=" * 55)
    print(" CitizenSynth — Analyse des contributions citoyennes")
    print("=" * 55)

    # [1/5] Chargement
    print(f"[1/5] Chargement du corpus : {args.input}")
    try:
        df = load_corpus(args.input)
    except Exception as e:
        print(f"  ERREUR : impossible de charger le CSV ({e})")
        sys.exit(1)
    print(f"        {len(df)} contributions chargees")

    # [2/5] Pretraitement
    print("[2/5] Pretraitement : nettoyage + anonymisation ...")
    df = preprocess_corpus(df)
    stats = corpus_stats(df)
    print(
        f"        exploitables : {stats['exploitables']}/{stats['total']} "
        f"({stats['taux_exploitation']} %) | trop courts : {stats['trop_courts']} | "
        f"doublons : {stats['doublons']}"
    )

    # [3/5] Analyse
    t0 = time.time()
    use_llm = not args.no_llm
    if use_llm:
        print(f"[3/5] Analyse thematique LLM (batchs) ...")
    else:
        print("[3/5] Analyse heuristique (LLM desactive) ...")
    df = analyze_corpus(df, use_llm=use_llm)
    dt = time.time() - t0
    classes = int((df["theme_principal"].notna()).sum())
    indet = int((df["position"] == "indeterminee").sum())
    print(f"        contributions classees : {classes}/{len(df)}")
    print(f"        indeterminees : {indet}")
    print(f"        duree : {dt:.1f}s")

    # [4/5] Syntheses
    print("[4/5] Generation des syntheses + fiches de themes ...")
    syntheses = generer_syntheses(df)
    for theme, syn in syntheses.items():
        path = os.path.join(out_dir, f"fiche_{theme}.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(formater_texte(syn))
    rapport = generer_rapport_global(df, syntheses)
    rapport_path = os.path.join(out_dir, "rapport_global.txt")
    with open(rapport_path, "w", encoding="utf-8") as f:
        f.write(rapport)
    print(f"        {len(syntheses)} fiches de themes generees")
    print(f"        rapport global : {rapport_path}")

    # Export CSV detaille
    export_cols = [
        "id", "texte_anonymise", "themes", "theme_principal", "position",
        "arguments", "proposition", "confiance", "methode_analyse",
    ]
    if "date" in df.columns:
        export_cols.insert(1, "date")
    export_path = os.path.join(out_dir, "analyses_detaillees.csv")
    df_out = df[[c for c in export_cols if c in df.columns]].copy()
    df_out["themes"] = df_out["themes"].apply(lambda ts: "|".join(ts or []))
    df_out.to_csv(export_path, index=False, encoding="utf-8")
    print(f"        analyses detaillees : {export_path}")

    # Export JSON des syntheses (pour interface / reutilisation)
    syn_json_path = os.path.join(out_dir, "syntheses.json")
    with open(syn_json_path, "w", encoding="utf-8") as f:
        json.dump(syntheses, f, ensure_ascii=False, indent=2)

    # [5/5] Evaluation (si reference fournie)
    if args.annotate:
        print(f"[5/5] Evaluation contre la reference : {args.annotate}")
        ref = pd.read_csv(args.annotate, encoding="utf-8")
        ref.columns = [c.strip().lower() for c in ref.columns]
        merged = df.merge(ref, on="id", how="inner", suffixes=("", "_ref"))
        # normalisation des listes de themes reference
        if "themes_reference" in merged.columns:
            merged["themes_reference"] = merged["themes_reference"].apply(
                lambda s: [t.strip() for t in str(s).split("|") if t.strip()]
                if pd.notna(s) else []
            )
        if "position_reference" in merged.columns:
            merged["position_reference"] = merged["position_reference"].astype(str).str.strip().str.lower()

        themes_res = evaluer_themes(merged, THEMES)
        pos_res = evaluer_positions(merged) if "position_reference" in merged.columns else {}
        eval_txt = rapport_evaluation(themes_res, pos_res)
        print(eval_txt)
        with open(os.path.join(out_dir, "rapport_evaluation.txt"), "w", encoding="utf-8") as f:
            f.write(eval_txt)
        with open(os.path.join(out_dir, "evaluation.json"), "w", encoding="utf-8") as f:
            json.dump({"themes": themes_res, "positions": pos_res}, f, ensure_ascii=False, indent=2)
    else:
        print("[5/5] Pas de reference fournie — evaluation quantitative passee.")
        print("      Astuce : utilisez --annotate fichier_annotes.csv pour evaluer.")

    print("")
    print("Termine. Resultats dans :", out_dir)


if __name__ == "__main__":
    main()
