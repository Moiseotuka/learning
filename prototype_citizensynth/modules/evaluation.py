# -*- coding: utf-8 -*-
"""Module d'evaluation du prototype.

Mesures :
- precision, rappel, F1 par theme et pour la position
- F1 macro
- analyse des erreurs
"""

from collections import defaultdict

import pandas as pd


def _prf(tp: int, fp: int, fn: int) -> dict:
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    rappel = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    f1 = (2 * precision * rappel / (precision + rappel)) if (precision + rappel) > 0 else 0.0
    return {
        "precision": round(precision, 3),
        "rappel": round(rappel, 3),
        "f1": round(f1, 3),
        "support": tp + fn,
    }


def evaluer_themes(df: pd.DataFrame, themes_ref: list[str]) -> dict:
    """Evalue la classification thematique (multi-label)."""
    resultats = {}
    for theme in themes_ref:
        tp = fp = fn = tn = 0
        for _, row in df.iterrows():
            ref = theme in (row.get("themes_reference") or [])
            pred = theme in (row.get("themes") or [])
            if ref and pred:
                tp += 1
            elif not ref and pred:
                fp += 1
            elif ref and not pred:
                fn += 1
            else:
                tn += 1
        resultats[theme] = _prf(tp, fp, fn)
    # F1 macro
    f1s = [r["f1"] for r in resultats.values()]
    resultats["_macro"] = {"f1_macro": round(sum(f1s) / len(f1s), 3) if f1s else 0.0}
    return resultats


def evaluer_positions(df: pd.DataFrame) -> dict:
    """Evalue la classification de position (multi-classe)."""
    positions = sorted(set(df["position_reference"].dropna().unique()) |
                       set(df["position"].dropna().unique()))
    resultats = {}
    for pos in positions:
        tp = fp = fn = 0
        for _, row in df.iterrows():
            ref = row.get("position_reference")
            pred = row.get("position")
            if ref == pos and pred == pos:
                tp += 1
            elif ref != pos and pred == pos:
                fp += 1
            elif ref == pos and pred != pos:
                fn += 1
        resultats[pos] = _prf(tp, fp, fn)
    # accuracy globale
    total = len(df)
    correct = int((df["position"] == df["position_reference"]).sum())
    resultats["_accuracy"] = round(correct / total, 3) if total else 0.0
    return resultats


def analyse_erreurs(df: pd.DataFrame, max_exemples: int = 10) -> list[dict]:
    """Retourne des exemples d'erreurs pour analyse qualitative."""
    erreurs = []
    for _, row in df.iterrows():
        ref_themes = set(row.get("themes_reference") or [])
        pred_themes = set(row.get("themes") or [])
        ref_pos = row.get("position_reference")
        pred_pos = row.get("position")
        if ref_themes != pred_themes or ref_pos != pred_pos:
            erreurs.append({
                "id": row.get("id"),
                "texte": (row.get("texte_anonymise") or "")[:150],
                "themes_reference": list(ref_themes),
                "themes_predits": list(pred_themes),
                "position_reference": ref_pos,
                "position_predite": pred_pos,
                "nb_mots": row.get("nb_mots"),
                "methode": row.get("methode_analyse"),
            })
        if len(erreurs) >= max_exemples:
            break
    return erreurs


def rapport_evaluation(themes_res: dict, pos_res: dict) -> str:
    """Formate un rapport d'evaluation lisible."""
    lines = [
        "RAPPORT D'EVALUATION DU PROTOTYPE",
        "=" * 40,
        "",
        "1. Classification thematique :",
    ]
    for theme, r in themes_res.items():
        if theme.startswith("_"):
            continue
        lines.append(
            f"  - {theme:20s}  P={r['precision']:.2f}  R={r['rappel']:.2f}  "
            f"F1={r['f1']:.2f}  (n={r['support']})"
        )
    macro = themes_res.get("_macro", {}).get("f1_macro", 0.0)
    lines.append(f"  F1-score macro : {macro:.2f}")
    lines.append("")
    lines.append("2. Analyse des positions :")
    for pos, r in pos_res.items():
        if pos.startswith("_"):
            continue
        lines.append(
            f"  - {pos:15s}  P={r['precision']:.2f}  R={r['rappel']:.2f}  F1={r['f1']:.2f}"
        )
    lines.append(f"  Accuracy globale : {pos_res.get('_accuracy', 0.0):.2f}")
    return "\n".join(lines)


if __name__ == "__main__":
    demo = pd.DataFrame({
        "id": [1, 2, 3, 4],
        "themes": [["voirie"], ["voirie"], ["eau_potable"], ["securite"]],
        "themes_reference": [["voirie"], ["voirie"], ["eau_potable"], ["education"]],
        "position": ["favorable", "defavorable", "favorable", "favorable"],
        "position_reference": ["favorable", "defavorable", "favorable", "defavorable"],
        "texte_anonymise": ["a", "b", "c", "d"],
        "nb_mots": [10, 12, 8, 15],
        "methode_analyse": ["llm"] * 4,
    })
    tr = evaluer_themes(demo, ["voirie", "eau_potable", "securite", "education"])
    pr = evaluer_positions(demo)
    print(rapport_evaluation(tr, pr))
