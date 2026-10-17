import { cn } from "@/lib/utils";

/**
 * Graphiques du tableau de bord, dessinés à la main en SVG et en CSS.
 *
 * Aucun serveur de statistiques n'est appelé, donc rien ne part vers un tiers et la page reste
 * légère sur une connexion 3G. Les valeurs restent dans le DOM : un lecteur d'écran ou un
 * enregistrement d'écran montre les mêmes chiffres que le dessin.
 */

export type Serie = { nom: string; points: number[]; classe: string };

const LARGEUR = 640;
const HAUTEUR = 220;
const MARGE = { haut: 12, droite: 12, bas: 26, gauche: 34 };

function echelle(valeurs: number[]): number {
  const max = Math.max(1, ...valeurs);
  // Arrondi au palier lisibles le plus proche : 7 → 10, 42 → 50, 130 → 150.
  const paliers = [1, 2, 5, 10, 20, 50, 100, 150, 200, 500, 1000, 2000, 5000, 10000, 50000];
  return paliers.find((p) => p >= max) ?? Math.ceil(max / 50000) * 50000;
}

/** Courbe multi-séries : visites, visiteurs uniques et inscriptions sur la même période. */
export function Courbe({
  series,
  etiquettes,
  legende,
}: {
  series: Serie[];
  etiquettes: string[];
  legende?: string;
}) {
  const max = echelle(series.flatMap((s) => s.points));
  const utile = LARGEUR - MARGE.gauche - MARGE.droite;
  const hauteurUtile = HAUTEUR - MARGE.haut - MARGE.bas;

  const coordonnees = (points: number[]) =>
    points.map((valeur, index) => {
      const x = MARGE.gauche + (index / Math.max(1, points.length - 1)) * utile;
      const y = MARGE.haut + hauteurUtile - (valeur / max) * hauteurUtile;
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    });

  return (
    <figure className="m-0">
      <svg
        viewBox={`0 0 ${LARGEUR} ${HAUTEUR}`}
        className="h-auto w-full"
        role="img"
        aria-label={legende ?? "graphique"}
      >
        {[0, 0.5, 1].map((fraction) => {
          const y = MARGE.haut + hauteurUtile * (1 - fraction);
          return (
            <g key={fraction}>
              <line
                x1={MARGE.gauche}
                x2={LARGEUR - MARGE.droite}
                y1={y}
                y2={y}
                className="stroke-hairline"
                strokeWidth={1}
              />
              <text
                x={MARGE.gauche - 6}
                y={y + 3}
                textAnchor="end"
                className="fill-current text-[9px] text-muted-foreground"
              >
                {Math.round(max * fraction)}
              </text>
            </g>
          );
        })}

        {series.map((serie) => {
          const pts = coordonnees(serie.points);
          return (
            <g key={serie.nom} className={serie.classe}>
              <polyline
                points={pts.join(" ")}
                fill="none"
                stroke="currentColor"
                strokeWidth={2}
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <title>{`${serie.nom} : ${serie.points.reduce((s, v) => s + v, 0)}`}</title>
              </polyline>
              {pts.length ? (
                <circle
                  cx={pts[pts.length - 1].split(",")[0]}
                  cy={pts[pts.length - 1].split(",")[1]}
                  r={3}
                  fill="currentColor"
                />
              ) : null}
            </g>
          );
        })}

        {etiquettes.map((etiquette, index) => {
          const tousLesX = Math.ceil(etiquettes.length / 6);
          if (index % tousLesX !== 0 && index !== etiquettes.length - 1) return null;
          const x =
            MARGE.gauche + (index / Math.max(1, etiquettes.length - 1)) * utile;
          return (
            <text
              key={`${etiquette}-${index}`}
              x={x}
              y={HAUTEUR - 8}
              textAnchor="middle"
              className="fill-current text-[9px] text-muted-foreground"
            >
              {etiquette}
            </text>
          );
        })}
      </svg>

      <figcaption className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
        {series.map((serie) => (
          <span key={serie.nom} className={cn("inline-flex items-center gap-1.5", serie.classe)}>
            <span aria-hidden className="size-2 rounded-full bg-current" />
            <span className="text-foreground">{serie.nom}</span>
          </span>
        ))}
      </figcaption>
    </figure>
  );
}

/** Barres horizontales en CSS : la largeur est proportionnelle, le nombre reste du texte. */
export function Barres({
  lignes,
  cle,
  valeur,
  secondaires,
}: {
  lignes: Record<string, string | number>[];
  cle: string;
  valeur: string;
  secondaires?: { cle: string; libelle: string }[];
}) {
  const max = Math.max(1, ...lignes.map((l) => Number(l[valeur]) || 0));

  return (
    <ul className="space-y-2.5">
      {lignes.map((ligne, index) => {
        const titree = String(ligne[cle] ?? "—");
        const nombre = Number(ligne[valeur]) || 0;

        return (
          <li key={`${titree}-${index}`}>
            <div className="flex items-baseline justify-between gap-3 text-xs">
              <span className="truncate font-medium text-foreground">{titree}</span>
              <span className="shrink-0 tabular-nums text-muted-foreground">
                {nombre}
                {secondaires
                  ? secondaires
                      .map((s) => ` · ${ligne[s.cle] ?? 0} ${s.libelle}`)
                      .join("")
                  : ""}
              </span>
            </div>
            <div
              className="mt-1 h-1.5 overflow-hidden rounded-full bg-muted"
              role="presentation"
            >
              <div
                className="h-full rounded-full bg-electric"
                style={{ width: `${Math.max(2, (nombre / max) * 100)}%` }}
              />
            </div>
          </li>
        );
      })}
      {lignes.length === 0 ? (
        <li className="text-xs text-muted-foreground">Aucune donnée sur la période.</li>
      ) : null}
    </ul>
  );
}

/* Une seule famille : le vert, décliné en profondeurs. La dernière teinte est neutre
   pour les statuts résiduels (« autres »), jamais une couleur ajoutée. */
const TEINTES = [
  "text-electric",
  "text-emerald-500",
  "text-emerald-300",
  "text-forest",
  "text-emerald-700",
  "text-muted-foreground",
];

/** Anneau de répartition : ici, les statuts de paiement, qui sont la question du patron. */
export function Anneau({
  parts,
  centre,
  libelleCentre,
}: {
  parts: { nom: string; valeur: number }[];
  centre: string;
  libelleCentre: string;
}) {
  const total = parts.reduce((somme, p) => somme + p.valeur, 0);
  const rayon = 52;
  const tour = 2 * Math.PI * rayon;

  // Décalage cumulé calculé d'avance : rien n'est muté pendant le rendu.
  let cumul = 0;
  const segments = parts.map((part, index) => {
    const longueur = (part.valeur / Math.max(1, total)) * tour;
    const segment = {
      ...part,
      index,
      longueur,
      decale: -cumul,
      teinte: TEINTES[index % TEINTES.length],
    };
    cumul += longueur;
    return segment;
  });

  return (
    <div className="flex flex-wrap items-center gap-5">
      <svg viewBox="0 0 140 140" className="size-32 shrink-0" role="img" aria-label={libelleCentre}>
        <circle
          cx="70"
          cy="70"
          r={rayon}
          fill="none"
          strokeWidth="14"
          className="stroke-current text-muted"
        />
        {total > 0
          ? segments.map((segment) => (
              <circle
                key={`${segment.nom}-${segment.index}`}
                cx="70"
                cy="70"
                r={rayon}
                fill="none"
                strokeWidth="14"
                stroke="currentColor"
                strokeDasharray={`${segment.longueur} ${tour - segment.longueur}`}
                strokeDashoffset={segment.decale}
                transform="rotate(-90 70 70)"
                className={segment.teinte}
              >
                <title>{`${segment.nom} : ${segment.valeur}`}</title>
              </circle>
            ))
          : null}
        <text
          x="70"
          y="66"
          textAnchor="middle"
          className="fill-current text-[20px] font-semibold text-foreground"
        >
          {centre}
        </text>
        <text x="70" y="82" textAnchor="middle" className="fill-current text-[9px] text-muted-foreground">
          {libelleCentre}
        </text>
      </svg>

      <ul className="min-w-40 flex-1 space-y-1.5 text-xs">
        {parts.map((part, index) => (
          <li key={`${part.nom}-${index}`} className="flex items-center justify-between gap-3">
            <span className="inline-flex items-center gap-2 text-foreground">
              <span
                aria-hidden
                className={cn("size-2 rounded-full bg-current", TEINTES[index % TEINTES.length])}
              />
              {part.nom}
            </span>
            <span className="tabular-nums text-muted-foreground">
              {part.valeur}
              {total > 0 ? ` · ${Math.round((part.valeur / total) * 100)} %` : ""}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}

/** Carte d'indicateur : le chiffre d'abord, sa variation ensuite, la source en note. */
export function Kpi({
  titre,
  valeur,
  variation,
  note,
  Icon,
}: {
  titre: string;
  valeur: string;
  variation?: { valeur: number; libelle: string } | null;
  note?: string;
  Icon?: React.ComponentType<{ className?: string; "aria-hidden"?: boolean }>;
}) {
  const monte = (variation?.valeur ?? 0) >= 0;

  return (
    <div className="rounded-2xl border border-hairline bg-card p-4">
      <p className="flex items-center gap-1.5 text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
        {Icon ? <Icon className="size-3.5 text-electric" aria-hidden /> : null}
        {titre}
      </p>
      <p className="mt-1.5 text-2xl font-semibold tabular-nums text-foreground">{valeur}</p>
      {variation ? (
        <p
          className={cn(
            "mt-1 text-xs font-medium tabular-nums",
            monte ? "text-emerald-500" : "text-destructive",
          )}
        >
          {monte ? "+" : ""}
          {variation.valeur} {variation.libelle}
        </p>
      ) : null}
      {note ? <p className="mt-1 text-[11px] text-muted-foreground">{note}</p> : null}
    </div>
  );
}
