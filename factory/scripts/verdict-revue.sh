#!/usr/bin/env bash
# Lit le verdict d'un rapport de revue : première ligne « VERDICT: APPROUVÉ » ou « VERDICT: CHANGEMENTS DEMANDÉS ».
#
# Usage : scripts/verdict-revue.sh [--] <fichier-de-revue>
# Sortie standard : une seule ligne, APPROUVÉ, CHANGEMENTS DEMANDÉS ou INCONNU. Sortie d'erreur : une ligne d'explication pour INCONNU.
# Code de sortie : 0 valeur valide ; 1 INCONNU (ligne absente, en double, pas en première ligne, valeur inconnue, fichier vide, absent,
# illisible ou hors bornes) ; 64 usage.
#
# Le fichier est une donnée non fiable : sa première ligne est comparée comme du texte, jamais évaluée ni passée à une commande, et jamais
# recopiée dans les messages. Lecture seule, aucun fichier temporaire. Un chemin commençant par « - » s'écrit après « -- » ou « ./ ».
#
# Règles de lecture : la première ligne est la seule référence (la section « ## Verdict » du rapport n'est pas lue) ; toute autre ligne
# commençant par « VERDICT: » (quelle que soit la casse, espaces de bord permis) rend le verdict ambigu, donc INCONNU. Sont tolérés : la casse,
# les espaces ou tabulations de bord et autour des deux-points, une fin de ligne CRLF. Les accents sont exigés (« APPROUVE » est inconnu) ;
# la valeur doit être égale à l'une des deux valeurs, pas seulement la contenir.
# Bornes : première ligne de 200 octets au plus, fichier de 1 Mio au plus (au-delà : INCONNU, jamais une lecture partielle).
set -uo pipefail
export LC_ALL=C
# shellcheck source=lib-verdict.sh
. "$(dirname "$0")/lib-verdict.sh" # les règles de lecture sont écrites une seule fois, dans cette bibliothèque (partagée avec statuts.sh)

usage() { echo "Usage : $0 [--] <fichier-de-revue>" >&2; exit 64; }

options=1
if [ "${1:-}" = "--" ]; then options=0; shift; fi
[ $# -eq 1 ] || usage
if [ "$options" -eq 1 ]; then case "$1" in -*) usage ;; esac; fi

verdict_lire "$1" || { echo "INCONNU"; echo "$verdict_motif" >&2; exit 1; }
echo "$verdict"
