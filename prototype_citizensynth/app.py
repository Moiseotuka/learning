# -*- coding: utf-8 -*-
"""Interface web du prototype CitizenSynth (Streamlit).

Lancement :
    streamlit run app.py

Puis ouvrir http://localhost:8501 dans le navigateur.
"""

import os
import sys

import pandas as pd
import streamlit as st

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "modules"))

from config import DEFAULT_CSV, OLLAMA_MODEL, POSITIONS, THEME_LABELS  # noqa: E402
from pretraitement import load_corpus, preprocess_corpus, corpus_stats  # noqa: E402
from analyse import analyze_corpus, build_llm_client  # noqa: E402
from synthese import generer_syntheses, formater_texte, generer_rapport_global  # noqa: E402

st.set_page_config(
    page_title="CitizenSynth — Analyse des avis citoyens",
    page_icon="🗳️",
    layout="wide",
)

# ------------------------------------------------------------------
# Sidebar
# ------------------------------------------------------------------
with st.sidebar:
    st.title("CitizenSynth")
    st.caption("Analyse assistee par IA des contributions citoyennes")
    st.divider()

    use_llm = st.toggle("Utiliser le LLM (Ollama)", value=True)
    if use_llm:
        client = build_llm_client()
        if client:
            st.success(f"LLM connecte : {OLLAMA_MODEL}")
        else:
            st.warning("LLM indisponible — secours heuristique actif.")

    st.divider()
    st.subheader("Donnees")
    uploaded = st.file_uploader("Charger un CSV (colonne 'texte')", type=["csv"])
    use_demo = st.checkbox("Utiliser le corpus de demonstration", value=uploaded is None)

    st.divider()
    st.caption(
        "Confidentialite : le LLM s'execute en local (Ollama). "
        "Aucune contribution n'est envoyee vers un serveur externe."
    )

# ------------------------------------------------------------------
# Chargement + analyse
# ------------------------------------------------------------------
@st.cache_data(show_spinner=False)
def run_pipeline(file_bytes, demo: bool, llm: bool):
    if file_bytes is not None:
        from io import BytesIO
        df = pd.read_csv(BytesIO(file_bytes))
        df.columns = [c.strip().lower() for c in df.columns]
        if "id" not in df.columns:
            df["id"] = range(1, len(df) + 1)
    else:
        df = load_corpus(DEFAULT_CSV)
    df = preprocess_corpus(df)
    df = analyze_corpus(df, use_llm=llm)
    return df


file_bytes = uploaded.read() if uploaded is not None else None
demo_mode = use_demo and file_bytes is None

with st.spinner("Analyse du corpus en cours..."):
    try:
        df = run_pipeline(file_bytes, demo_mode, use_llm)
    except Exception as e:
        st.error(f"Erreur lors du pipeline : {e}")
        st.stop()

stats = corpus_stats(df)
syntheses = generer_syntheses(df)

# ------------------------------------------------------------------
# Onglets
# ------------------------------------------------------------------
tab1, tab2, tab3, tab4 = st.tabs(
    ["Tableau de bord", "Syntheses par theme", "Verbatims", "Rapport exportable"]
)

# ---- Tab 1 : tableau de bord ----
with tab1:
    st.header("Consultation : Budget participatif — Commune X (Kinshasa)")
    st.caption(
        f"{stats['exploitables']} contributions exploitees sur {stats['total']} "
        f"| Analyse : {'LLM (' + OLLAMA_MODEL + ')' if use_llm else 'heuristique'}"
    )

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Contributions", stats["total"])
    c2.metric("Themes detectes", len(syntheses))
    pos_counts = df["position"].value_counts()
    major_pos = pos_counts.idxmax() if len(pos_counts) else "—"
    major_pct = round(100 * pos_counts.max() / len(df), 0) if len(pos_counts) else 0
    c3.metric("Position majoritaire", f"{major_pos} : {major_pct:.0f}%" if len(pos_counts) else "—")
    n_bloc = sum(1 for s in syntheses.values() if s.get("points_blocage"))
    c4.metric("Themes avec blocages", n_bloc)

    st.subheader("Distribution des themes")
    theme_counts = {}
    for themes in df["themes"]:
        for t in themes or []:
            theme_counts[THEME_LABELS.get(t, t)] = theme_counts.get(THEME_LABELS.get(t, t), 0) + 1
    if theme_counts:
        chart_df = pd.DataFrame(
            {"Theme": list(theme_counts.keys()), "Contributions": list(theme_counts.values())}
        ).sort_values("Contributions", ascending=True)
        st.bar_chart(chart_df.set_index("Theme"))
    else:
        st.info("Aucun theme detecte.")

    st.subheader("Distribution des positions")
    if len(pos_counts):
        pos_df = pd.DataFrame(
            {"Position": pos_counts.index, "Nombre": pos_counts.values}
        )
        st.bar_chart(pos_df.set_index("Position"))

# ---- Tab 2 : syntheses ----
with tab2:
    st.header("Fiches de synthese par theme")
    if not syntheses:
        st.info("Aucune synthese disponible.")
    for theme, syn in syntheses.items():
        with st.expander(f"{syn['libelle']} — {syn['total_contributions']} contributions"):
            cols = st.columns(4)
            for i, (pos, info) in enumerate(syn["distribution_positions"].items()):
                cols[i].metric(pos, f"{info['part']} %")
            st.markdown("**Points de blocage**")
            if syn["points_blocage"]:
                for b in syn["points_blocage"]:
                    st.markdown(f"- {b}")
            else:
                st.caption("Aucun blocage marque.")
            st.markdown("**Propositions constructives**")
            if syn["propositions"]:
                for p in syn["propositions"]:
                    st.markdown(f"- {p}")
            else:
                st.caption("Aucune proposition explicite.")
            st.markdown("**Verbatims d'appui (tracabilite)**")
            for pos, verbs in syn["verbatims"].items():
                for v in verbs:
                    st.markdown(f"> [{pos} | id={v['id']}] {v['texte'][:200]}")
            st.caption(f"Confiance moyenne du modele : {syn['confiance_moyenne']}")

# ---- Tab 3 : verbatims ----
with tab3:
    st.header("Consultation des verbatims analyses")
    f_theme = st.selectbox(
        "Filtrer par theme",
        ["Tous"] + [THEME_LABELS.get(t, t) for t in syntheses.keys()],
    )
    f_pos = st.selectbox("Filtrer par position", ["Toutes"] + list(POSITIONS))
    view = df.copy()
    if f_theme != "Tous":
        theme_key = [k for k, v in THEME_LABELS.items() if v == f_theme]
        if theme_key:
            view = view[view["themes"].apply(lambda ts: theme_key[0] in (ts or []))]
    if f_pos != "Toutes":
        view = view[view["position"] == f_pos]
    st.caption(f"{len(view)} contribution(s)")
    for _, row in view.head(50).iterrows():
        st.markdown(
            f"**ID {row['id']}** — {', '.join(THEME_LABELS.get(t, t) for t in row['themes'] or []) or 'sans theme'} "
            f"| **{row['position']}** | confiance {row['confiance']:.2f}"
        )
        st.write(row["texte_anonymise"])
        if row.get("proposition"):
            st.caption(f"Proposition : {row['proposition']}")
        st.divider()

# ---- Tab 4 : rapport ----
with tab4:
    st.header("Rapport global exportable")
    rapport = generer_rapport_global(df, syntheses)
    st.text_area("Rapport", rapport, height=400)
    st.download_button(
        "Telecharger le rapport (.txt)",
        rapport,
        file_name="rapport_global.txt",
        mime="text/plain",
    )
    st.download_button(
        "Telecharger les analyses detaillees (.csv)",
        df[["id", "texte_anonymise", "themes", "position", "confiance"]].to_csv(index=False),
        file_name="analyses_detaillees.csv",
        mime="text/csv",
    )
    for theme, syn in syntheses.items():
        st.download_button(
            f"Fiche {syn['libelle']} (.txt)",
            formater_texte(syn),
            file_name=f"fiche_{theme}.txt",
            mime="text/plain",
            key=f"dl_{theme}",
        )
