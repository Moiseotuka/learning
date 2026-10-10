import { writeFileSync } from "node:fs";

const exercise =
  "Vous recevez un mandat d'analyse de vulnérabilités pour le réseau de test 192.168.56.0/24, autorisé du lundi 20 h au vendredi 6 h, techniques limitées au scan et à l'énumération sans exploitation. Produisez un inventaire complet et reproductible. Livrables : un script bash inventory.sh qui exécute une découverte d'hôtes, un scan SYN des 1 000 ports courants si vous êtes administrateur ou un scan CONNECT sinon, une détection de versions avec -sV, et l'énumération web des serveurs HTTP découverts via les scripts http-enum et http-headers ; chaque exécution écrit ses résultats horodatés dans un dossier daté du type inventaire/AAAA-MM-JJ/ au format XML et texte. Ensuite, rédigez un rapport findings.md contenant un résumé d'une page, un tableau de synthèse des findings prioritaires avec identifiant, sévérité contextuelle et hôte, et une fiche détaillée par finding comportant la preuve, le cas échéant la CVE et le score CVSS obtenus auprès d'une base publique, la recommandation et le délai de correction justifié. Documentez également vos faux positifs écartés et les commandes exactes permettant de reproduire chaque constat.";

const starter = `#!/usr/bin/env bash
# Inventaire de vulnérabilités — réseau 192.168.56.0/24
# Mandat : scan et énumération uniquement, sans exploitation.
set -euo pipefail

# TODO : définir le périmètre et le dossier de sortie daté
CIBLE="192.168.56.0/24"
DATE=$(date +%F)
SORTIE="inventaire/$DATE"
mkdir -p "$SORTIE"

# TODO : choisir le mode de scan selon vos privilèges
# - sS avec sudo si disponible
# - sT sinon
if [ "$(id -u)" -eq 0 ]; then
  MODE="-sS"
else
  # TODO : affecter ici le mode adapté aux droits insuffisants
  MODE=""
fi

# TODO : découverte des hôtes actifs (ping sweep), résultats dans SORTIE
# Indice : utiliser nmap -sn avec -oA pour écrire XML, greppable et normal

# TODO : scan des 1000 ports courants sur chaque hôte actif, timing prudent (-T2)
# Indice : récupérer la liste des hôtes actifs depuis le fichier greppable généré

# TODO : détection de versions (-sV) sur les ports ouverts, même dossier de sortie

# TODO : pour chaque serveur web détecté, exécuter http-enum et http-headers
# Indice : boucler sur les hôtes dont les ports 80/443/8080 sont ouverts

# TODO : générer à la fin un récapitulatif à l'écran (hôtes, ports ouverts, bannières)

# TODO : rappeler dans un commentaire le moyen de relancer proprement l'inventaire
# et la commande de comparaison entre deux dates pour mesurer l'évolution`;

const solution = `#!/usr/bin/env bash
# Inventaire de vulnérabilités — réseau 192.168.56.0/24
# Mandat : scan et énumération uniquement, sans exploitation.
set -euo pipefail

CIBLE="192.168.56.0/24"
DATE=$(date +%F)
SORTIE="inventaire/$DATE"
mkdir -p "$SORTIE"

if [ "$(id -u)" -eq 0 ]; then
  MODE="-sS"
else
  MODE="-sT"
fi

echo "[1/4] Découverte des hôtes actifs..."
nmap -sn "$CIBLE" -oA "$SORTIE/hotes"

HOTES=$(awk '/^Host: / && / Up$/{print $2}' "$SORTIE/hotes.gnmap" || true)

if [ -z "$HOTES" ]; then
  echo "Aucun hôte actif détecté dans le périmètre."
  exit 0
fi

echo "[2/4] Scan des ports courants (mode $MODE, timing -T2)..."
nmap $MODE -T2 --max-hostgroup 4 --max-parallelism 8 \\
  -p 21,22,25,53,80,110,135,139,143,443,445,993,995,1433,3306,3389,5432,5900,6379,8080,8443,27017 \\
  $HOTES -oA "$SORTIE/ports"

echo "[3/4] Détection de versions sur les ports ouverts..."
nmap -sV -T2 -p 22,80,443,3306,6379,8080 $HOTES -oA "$SORTIE/versions"

echo "[4/4] Énumération web des serveurs détectés..."
for h in $HOTES; do
  for p in 80 443 8080; do
    if grep -q "$p/tcp open" "$SORTIE/ports.nmap" 2>/dev/null; then
      protocole="http"
      [ "$p" = 443 ] && protocole="https"
      nmap --script http-enum,http-headers -p "$p" \\
        "$protocole://$h" -oA "$SORTIE/web-$h-$p" || true
    fi
  done
done

echo
echo "=== Récapitulatif ==="
grep -E "^(Nmap scan report|PORT|.*open)" "$SORTIE/ports.nmap" || true

echo
echo "Pour comparer deux inventaires :"
echo "  diff inventaire/DATE-1/ports.nmap inventaire/DATE-2/ports.nmap"
echo "Relancez inventory.sh pour actualiser l'inventaire du jour."`;

const obj = {
  exercise,
  resources: [
    {
      label: "Wikipédia FR — Nmap, présentation de l'outil de scan réseau",
      url: "https://fr.wikipedia.org/wiki/Nmap",
    },
    {
      label: "Manuel officiel de Nmap — référence complète des options et états de port",
      url: "https://nmap.org/book/man.html",
    },
    {
      label: "Calculateur FIRST CVSS 3.1 — calcul officiel des scores de sévérité",
      url: "https://www.first.org/cvss/calculator/3.1",
    },
  ],
  code_language: "bash",
  starter_code: starter,
  solution_code: solution,
};

writeFileSync("content/chapters/off-c2.json", JSON.stringify(obj, null, 2), "utf8");
console.log("written");
