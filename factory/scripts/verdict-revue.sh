#!/usr/bin/env bash
# Lit le verdict d'un rapport de revue : première ligne « VERDICT: APPROUVÉ » ou « VERDICT: CHANGEMENTS DEMANDÉS ».
#
# Usage : scripts/verdict-revue.sh [--] <fichier-de-revue>
# Sortie standard : une seule ligne, APPROUVÉ, CHANGEMENTS DEMANDÉS ou INCONNU. Sortie d'erreur : une ligne d'explication pour INCONNU.
# Code de sortie : 0 valeur valide ; 1 INCONNU (ligne absente, fichier vide, absent ou illisible) ; 64 usage.
#
# Le fichier est une donnée non fiable : sa première ligne est comparée comme du texte (égalité stricte), jamais évaluée ni passée à une
# commande, et jamais recopiée dans les messages. Lecture seule, aucun fichier temporaire. Un chemin commençant par « - » s'écrit après « -- » ou « ./ ».
# Ce script ne tolère ni casse, ni espaces, ni doublon : seule la comparaison stricte de la première ligne y est faite.
set -uo pipefail
export LC_ALL=C

usage() { echo "Usage : $0 [--] <fichier-de-revue>" >&2; exit 64; }
inconnu() { echo "INCONNU"; echo "$1" >&2; exit 1; }

options=1
if [ "${1:-}" = "--" ]; then options=0; shift; fi
[ $# -eq 1 ] || usage
if [ "$options" -eq 1 ]; then case "$1" in -*) usage ;; esac; fi

fichier="$1"
{ [ -f "$fichier" ] && [ -r "$fichier" ]; } || inconnu "verdict-revue : fichier de revue absent ou illisible"

# Au plus 100 octets de la première ligne : plus long que toute valeur valide, donc jamais égal à l'une d'elles une fois tronqué.
premiere="$(head -n 1 < "$fichier" | head -c 100)"

case "$premiere" in
  "VERDICT: APPROUVÉ") echo "APPROUVÉ" ;;
  "VERDICT: CHANGEMENTS DEMANDÉS") echo "CHANGEMENTS DEMANDÉS" ;;
  *) inconnu "verdict-revue : première ligne différente de « VERDICT: APPROUVÉ » et de « VERDICT: CHANGEMENTS DEMANDÉS » (ligne VERDICT absente ou invalide)" ;;
esac
