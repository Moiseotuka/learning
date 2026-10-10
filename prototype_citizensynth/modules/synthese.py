# -*- coding: utf-8 -*-
"""Module de generation des syntheses par theme.

Produit pour chaque theme :
- distribution des positions
- points de blocage (arguments negatifs recurrants)
- propositions constructives
- verbatims d'appui lies (tracabilite)
"""

from collections import Counter, defaultdict

import pandas as pd

from config import POSITIONS, THEME_LABELS, THEMES


def _most_common_phrases(arguments: list[str], top_n: int = 3) -> list[str]:
    """Retire les phrases d'arguments frequentes (approximation par prefixe)."""
    prefixes = [a.strip().lower()[:40] for a in arguments if a]
    counts = Counter(prefixes)
    seen = set()
    result = []
    for arg in arguments:
        p = arg.strip().lower()[:40]
        if p in counts and counts[p] >= 2 and p not in seen:
            seen.add(p)
            result.append(arg.strip())
        if len(result) >= top_n:
            break
    # complete avec les plus longues si peu de recurrences
    if len(result) < top_n:
        for arg in sorted(arguments, key=len, reverse=True):
            if arg.strip() not in result:
                result.append(arg.strip())
            if len(result) >= top_n:
                break
    return result[:top_n]


def synthese_theme(df_theme: pd.DataFrame, theme: str) -> dict:
    """Genere la synthese structuree pour un theme donne."""
    total = len(df_theme)
    if total == 0:
        return {}

    # Distribution des positions
    pos_counts = df_theme["position"].value_counts().to_dict()
    distribution = {
        p: {
            "part": round(100 * pos_counts.get(p, 0) / total, 1),
            "nb": pos_counts.get(p, 0),
        }
        for p in POSITIONS
    }

    # Arguments pour / contre
    args_fav = []
    args_def = []
    args_nua = []
    for _, row in df_theme.iterrows():
        position = row.get("position", "indeterminee")
        for arg in row.get("arguments") or []:
            if position == "favorable":
                args_fav.append(arg)
            elif position == "defavorable":
                args_def.append(arg)
            elif position == "nuancee":
                args_nua.append(arg)

    # Points de blocage : arguments defavorables + nuances (conditions)
    blocages = _most_common_phrases(args_def + args_nua, top_n=3)

    # Propositions constructives
    propositions = [
        row["proposition"]
        for _, row in df_theme.iterrows()
        if isinstance(row.get("proposition"), str) and row["proposition"].strip()
    ]
    # doublons approximatifs
    seen = set()
    prop_uniques = []
    for p in propositions:
        key = p.strip().lower()[:50]
        if key not in seen:
            seen.add(key)
            prop_uniques.append(p.strip())

    # Verbatims d'appui : 3 verbatims par position majeure (tracabilite)
    verbatims = {}
    for pos in ["favorable", "defavorable", "nuancee"]:
        subset = df_theme[df_theme["position"] == pos].head(3)
        verbatims[pos] = [
            {"id": int(row["id"]) if "id" in row else i, "texte": row["texte_anonymise"]}
            for i, (_, row) in enumerate(subset.iterrows())
        ]

    # Confiance moyenne
    conf = float(df_theme["confiance"].mean()) if "confiance" in df_theme else 0.0

    return {
        "theme": theme,
        "libelle": THEME_LABELS.get(theme, theme),
        "total_contributions": total,
        "distribution_positions": distribution,
        "points_blocage": blocages,
        "propositions": prop_uniques[:5],
        "verbatims": verbatims,
        "confiance_moyenne": round(conf, 2),
    }


def generer_syntheses(df: pd.DataFrame) -> dict:
    """Genere les syntheses pour tous les themes presents dans le corpus."""
    syntheses = {}
    for theme in THEMES:
        subset = df[df["themes"].apply(lambda ts: theme in (ts or []))]
        if len(subset) > 0:
            syntheses[theme] = synthese_theme(subset, theme)
    return syntheses


def formater_texte(synthese: dict) -> str:
    """Formate une synthese en texte lisible (pour export / affichage)."""
    if not synthese:
        return "(Aucune contribution pour ce theme.)"
    lines = [
        f"FICHE DE SYNTHESE — {synthese['libelle'].upper()}",
        f"Contributions analysees : {synthese['total_contributions']}",
        f"Confiance moyenne du modele : {synthese['confiance_moyenne']}",
        "",
        "Distribution des positions :",
    ]
    for pos, info in synthese["distribution_positions"].items():
        lines.append(f"  - {pos} : {info['part']} % ({info['nb']} contributions)")
    lines.append("")
    lines.append("Points de blocage identifies :")
    if synthese["points_blocage"]:
        for i, b in enumerate(synthese["points_blocage"], 1):
            lines.append(f"  {i}. {b}")
    else:
        lines.append("  (aucun blocage marque detecte)")
    lines.append("")
    lines.append("Propositions constructives :")
    if synthese["propositions"]:
        for i, p in enumerate(synthese["propositions"], 1):
            lines.append(f"  {i}. {p}")
    else:
        lines.append("  (aucune proposition explicite)")
    lines.append("")
    lines.append("Verbatims d'appui (tracabilite) :")
    for pos, verbs in synthese["verbatims"].items():
        for v in verbs:
            excerpt = v["texte"][:120] + ("..." if len(v["texte"]) > 120 else "")
            lines.append(f"  [{pos} | id={v['id']}] {excerpt}")
    return "\n".join(lines)


def generer_rapport_global(df: pd.DataFrame, syntheses: dict) -> str:
    """Rapport global synthetique pour le decideur."""
    lines = [
        "RAPPORT GLOBAL D'ANALYSE DES CONTRIBUTIONS CITOYENNES",
        "=" * 55,
        f"Total de contributions analysees : {len(df)}",
        f"Themes identifies : {len(syntheses)}",
        "",
        "Resume par theme :",
    ]
    # tri par volume
    ordered = sorted(syntheses.values(), key=lambda s: s["total_contributions"], reverse=True)
    for s in ordered:
        top_pos = max(s["distribution_positions"].items(), key=lambda kv: kv[1]["nb"])
        lines.append(
            f"  - {s['libelle']} : {s['total_contributions']} contributions "
            f"(position majoritaire : {top_pos[0]}, {top_pos[1]['part']} %)"
        )
    lines.append("")
    lines.append("Alertes (points de blocage multi-themes) :")
    any_blocage = False
    for s in ordered:
        if s["points_blocage"]:
            any_blocage = True
            lines.append(f"  * {s['libelle']} : {s['points_blocage'][0]}")
    if not any_blocage:
        lines.append("  (aucune alerte majeure)")
    lines.append("")
    lines.append("Note : toute synthese doit etre validee par un humain avant diffusion officielle.")
    return "\n".join(lines)


if __name__ == "__main__":
    demo = pd.DataFrame({
        "id": [1, 2, 3],
        "texte_anonymise": ["Routes catastrophe", "Routes bien faites", "Routes ok mais lents"],
        "themes": [["voirie"], ["voirie"], ["voirie"]],
        "position": ["defavorable", "favorable", "nuancee"],
        "arguments": [["catastrophe"], ["bien"], ["lents"]],
        "proposition": [None, None, "Accelerer les travaux"],
        "confiance": [0.8, 0.9, 0.7],
    })
    s = generer_syntheses(demo)
    for th, syn in s.items():
        print(formater_texte(syn))
        print()
