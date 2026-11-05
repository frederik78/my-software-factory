#!/usr/bin/env bash
# Configuration effective de la factory pour ce projet (lue par lib-config.sh : .factory.conf, .factory.local.conf, variables FACTORY_*).
#
# Usage : scripts/config-factory.sh                    (affiche « CLÉ=valeur » pour chaque clé connue, rien d'autre)
#         scripts/config-factory.sh --max-iterations   (nombre maximal d'itérations développeur <-> relecteur ; 3 par défaut)
#         scripts/config-factory.sh --max-criteres     (nombre de critères au-delà duquel couverture-prd.sh signale une issue ; 10 par défaut)
# Code de sortie : 0 ; 64 si l'option est inconnue ou si la limite demandée n'est pas un entier >= 1.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
dossier_scripts="$(cd "$(dirname "$0")" && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-config.sh
. "$dossier_scripts/lib-config.sh"

MAX_ITERATIONS_DEFAUT=3
MAX_CRITERES_DEFAUT=10
defaut() { # defaut <clé> : valeur par défaut d'une clé connue
  case "$1" in
    MAX_ITERATIONS_REVUE) echo "$MAX_ITERATIONS_DEFAUT" ;;
    MAX_CRITERES_ISSUE) echo "$MAX_CRITERES_DEFAUT" ;;
    AGENT_MODELE) echo "$AGENT_MODELE_DEFAUT" ;;
    AGENT_EFFORT) echo "$AGENT_EFFORT_DEFAUT" ;;
    AGENTS_SILENCE_MINUTES) echo "$AGENTS_SILENCE_MINUTES_DEFAUT" ;;
    AGENTS_RETRAIT_MINUTES) echo "$AGENTS_RETRAIT_MINUTES_DEFAUT" ;;
    *) echo "" ;;
  esac
}

usage() { echo "Usage : $0 [--max-iterations | --max-criteres]" >&2; exit 64; }
limite() { # limite <clé> : valeur de la clé, entier >= 1, sinon code 64
  local valeur
  valeur="$(config_valeur "$1" "$(defaut "$1")")"
  case "$valeur" in
    ''|0*|*[!0-9]*) echo "$1 invalide : entier >= 1 attendu (voir .factory.conf, .factory.local.conf, FACTORY_$1)." >&2; exit 64 ;;
  esac
  printf '%s\n' "$valeur"
}

case "${1:-}" in
  "")
    for cle in $CONFIG_CLES; do printf '%s=%s\n' "$cle" "$(config_valeur "$cle" "$(defaut "$cle")")"; done ;;
  --max-iterations) [ $# -eq 1 ] || usage; limite MAX_ITERATIONS_REVUE ;;
  --max-criteres) [ $# -eq 1 ] || usage; limite MAX_CRITERES_ISSUE ;;
  *) usage ;;
esac
