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

usage() { echo "Usage : $0 [--] <fichier-de-revue>" >&2; exit 64; }
inconnu() { echo "INCONNU"; echo "$1" >&2; exit 1; }

options=1
if [ "${1:-}" = "--" ]; then options=0; shift; fi
[ $# -eq 1 ] || usage
if [ "$options" -eq 1 ]; then case "$1" in -*) usage ;; esac; fi

fichier="$1"
{ [ -f "$fichier" ] && [ -r "$fichier" ]; } || inconnu "verdict-revue : fichier de revue absent ou illisible"

taille="$(wc -c < "$fichier")"
[ "${taille//[[:space:]]/}" -le 1048576 ] || inconnu "verdict-revue : fichier de revue trop volumineux (plus de 1 Mio, ligne VERDICT non vérifiable)"

# Première ligne, lue sur 201 octets au plus : une ligne plus longue que 200 octets est refusée (sinon des espaces de bord pourraient cacher
# du texte au-delà de la tranche lue).
premiere="$(head -n 1 < "$fichier" | head -c 201)"
[ "${#premiere}" -le 200 ] || inconnu "verdict-revue : première ligne trop longue (plus de 200 octets, ligne VERDICT invalide)"

# La substitution de commande supprime les octets NUL : « VERDICT: APPR<NUL>OUVÉ » deviendrait « VERDICT: APPROUVÉ ». On les compte donc
# sur la même tranche d'octets, et tout NUL rend le verdict INCONNU.
nuls="$(head -n 1 < "$fichier" | head -c 201 | tr -dc '\000' | wc -c)"
[ "${nuls//[[:space:]]/}" = "0" ] || inconnu "verdict-revue : première ligne contenant un octet NUL (ligne VERDICT invalide)"

rogner() { # rogner <texte> : REPLY = texte sans espaces ni tabulations de bord
  REPLY="$1"
  REPLY="${REPLY#"${REPLY%%[![:blank:]]*}"}"
  REPLY="${REPLY%"${REPLY##*[![:blank:]]}"}"
}

# Décompte des lignes « VERDICT: » de tout le fichier (la casse ne compte pas, les espaces de bord non plus) : une seule est permise.
lignes_verdict="$(head -c 1048577 < "$fichier" | grep -a -i -c -E '^[[:blank:]]*verdict[[:blank:]]*:')"
[ "${lignes_verdict//[[:space:]]/}" -le 1 ] || inconnu "verdict-revue : ligne VERDICT en double (verdict ambigu)"

rogner "${premiere%$'\r'}"; ligne="$REPLY"
rogner "${ligne%%:*}" # sans deux-points, la clé est la ligne entière : elle ne peut valoir « verdict » suivie d'une valeur
case "$REPLY" in
  [Vv][Ee][Rr][Dd][Ii][Cc][Tt]) ;;
  *) inconnu "verdict-revue : la première ligne n'est pas une ligne VERDICT (ligne VERDICT absente ou pas en première ligne)" ;;
esac
rogner "${ligne#*:}"
# Comparaison par motifs de casse explicites : la mise en minuscules de É/é dépend de la locale et de la version de bash, pas un motif.
case "$REPLY" in
  [Aa][Pp][Pp][Rr][Oo][Uu][Vv]"É"|[Aa][Pp][Pp][Rr][Oo][Uu][Vv]"é") echo "APPROUVÉ" ;;
  [Cc][Hh][Aa][Nn][Gg][Ee][Mm][Ee][Nn][Tt][Ss]" "[Dd][Ee][Mm][Aa][Nn][Dd]"É"[Ss]|[Cc][Hh][Aa][Nn][Gg][Ee][Mm][Ee][Nn][Tt][Ss]" "[Dd][Ee][Mm][Aa][Nn][Dd]"é"[Ss]) echo "CHANGEMENTS DEMANDÉS" ;;
  *) inconnu "verdict-revue : valeur de la ligne VERDICT différente de « APPROUVÉ » et de « CHANGEMENTS DEMANDÉS » (ligne VERDICT invalide)" ;;
esac
