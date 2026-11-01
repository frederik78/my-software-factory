#!/usr/bin/env bash
# Configuration effective de la factory pour ce projet (lue par lib-config.sh : .factory.conf, .factory.local.conf, variables FACTORY_*).
#
# Usage : scripts/config-factory.sh                    (affiche « CLÉ=valeur » pour chaque clé connue, rien d'autre)
#         scripts/config-factory.sh --max-iterations   (nombre maximal d'itérations développeur <-> relecteur ; 5 par défaut)
# Code de sortie : 0 ; 64 si l'option est inconnue ou si MAX_ITERATIONS_REVUE n'est pas un entier >= 1.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
dossier_scripts="$(cd "$(dirname "$0")" && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-config.sh
. "$dossier_scripts/lib-config.sh"

MAX_ITERATIONS_DEFAUT=5
defaut() { # defaut <clé> : valeur par défaut d'une clé connue
  case "$1" in MAX_ITERATIONS_REVUE) echo "$MAX_ITERATIONS_DEFAUT" ;; *) echo "" ;; esac
}

case "${1:-}" in
  "")
    for cle in $CONFIG_CLES; do printf '%s=%s\n' "$cle" "$(config_valeur "$cle" "$(defaut "$cle")")"; done ;;
  --max-iterations)
    [ $# -eq 1 ] || { echo "Usage : $0 [--max-iterations]" >&2; exit 64; }
    valeur="$(config_valeur MAX_ITERATIONS_REVUE "$MAX_ITERATIONS_DEFAUT")"
    case "$valeur" in
      ''|0*|*[!0-9]*) echo "MAX_ITERATIONS_REVUE invalide : entier >= 1 attendu (voir .factory.conf, .factory.local.conf, FACTORY_MAX_ITERATIONS_REVUE)." >&2; exit 64 ;;
    esac
    printf '%s\n' "$valeur" ;;
  *) echo "Usage : $0 [--max-iterations]" >&2; exit 64 ;;
esac
