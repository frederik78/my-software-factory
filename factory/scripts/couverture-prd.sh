#!/usr/bin/env bash
# Couverture d'un PRD par ses issues : chaque critère défini dans le PRD doit être couvert par EXACTEMENT une issue.
#
# Convention du PRD : un critère est défini par une ligne qui commence par `- **CA-10**` ou `- **CS-07**` (liste à puces, identifiant en gras).
# Une issue appartient au PRD si son champ `prd:` pointe vers ce fichier. Les identifiants sont comparés sans zéros de tête (CA-03 = CA-3).
#
# Usage : scripts/couverture-prd.sh <docs/prd/NNN-module.md>
# Rapporte : critères sans issue, critères portés par plusieurs issues, critères d'issue inconnus du PRD. Code 1 s'il y en a, 64 en cas d'usage.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"

prd="${1:-}"
if [ -z "$prd" ] || [ ! -f "$prd" ]; then
  echo "Usage : $0 <docs/prd/NNN-module.md>" >&2
  exit 64
fi

normaliser() { # CA-03 -> CA-3 (une ligne par appel)
  printf '%s\n' "$1" | sed -E 's/^([A-Za-z]+)[-_ ]*0*([0-9]+).*/\1-\2/' | tr 'a-z' 'A-Z'
}

definis="$(sed -nE 's/^[[:space:]]*[-*][[:space:]]+\*\*(C[AS]-?[0-9]+)\*\*.*/\1/p' "$prd" | while read -r c; do normaliser "$c"; done | sort -u)"
if [ -z "$definis" ]; then
  echo "ERREUR : aucun critère défini dans $prd (attendu : lignes « - **CA-xx** … »)" >&2
  exit 1
fi

portes=""   # lignes « critère issue »
while IFS= read -r f; do
  [ "$(issue_champ "$f" prd)" = "$prd" ] || continue
  id="$(issue_champ "$f" id)"
  while IFS= read -r c; do
    [ -n "$c" ] && portes="${portes}$(normaliser "$c") ${id}"$'\n'
  done < <(issue_liste "$f" criteres)
done < <(issue_fichiers)

echec=0
for c in $definis; do
  n="$(printf '%s' "$portes" | awk -v c="$c" '$1 == c' | wc -l | tr -d ' ')"
  if [ "$n" -eq 0 ]; then
    echo "SANS ISSUE  $c"; echec=1
  elif [ "$n" -gt 1 ]; then
    echo "EN DOUBLE   $c : $(printf '%s' "$portes" | awk -v c="$c" '$1 == c {print $2}' | paste -sd' ' -)"; echec=1
  fi
done
for c in $(printf '%s' "$portes" | awk 'NF {print $1}' | sort -u); do
  printf '%s\n' "$definis" | grep -qx "$c" || { echo "INCONNU DU PRD  $c ($(printf '%s' "$portes" | awk -v c="$c" '$1 == c {print $2}' | paste -sd' ' -))"; echec=1; }
done

total="$(printf '%s\n' "$definis" | wc -l | tr -d ' ')"
[ "$echec" -eq 0 ] && echo "OK  $prd : $total critère(s), chacun couvert par une seule issue"
exit "$echec"
