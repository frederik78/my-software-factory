#!/usr/bin/env bash
# État des issues de docs/issues/ lu directement dans leur en-tête (remplace un index tenu à la main, qui dériverait).
#
# Usage : scripts/etat-issues.sh [--statut "À faire"]     (tableau Markdown, une ligne par issue)
#         scripts/etat-issues.sh --prochaine              (id de la première issue « À faire » dont toutes les dépendances sont « Fait »)
# Code de sortie : 0 ; en mode --prochaine : 1 s'il n'y a aucune issue prête.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"

mode="tableau"; filtre=""
while [ $# -gt 0 ]; do
  case "$1" in
    --prochaine) mode="prochaine" ;;
    --statut) filtre="${2:?--statut attend une valeur}"; shift ;;
    *) echo "Usage : $0 [--statut <statut>] [--prochaine]" >&2; exit 64 ;;
  esac
  shift
done

ids=(); statuts=(); fichiers=()
while IFS= read -r f; do
  fichiers+=("$f"); ids+=("$(issue_champ "$f" id)"); statuts+=("$(issue_champ "$f" statut)")
done < <(issue_fichiers)

statut_de() { # statut_de <id>
  local i
  for i in "${!ids[@]}"; do [ "${ids[$i]}" = "$1" ] && { printf '%s' "${statuts[$i]}"; return; }; done
}

if [ "$mode" = "prochaine" ]; then
  for i in "${!ids[@]}"; do
    [ "${statuts[$i]}" = "À faire" ] || continue
    pret=1
    while IFS= read -r dep; do
      [ -n "$dep" ] && [ "$(statut_de "$dep")" != "Fait" ] && pret=0
    done < <(issue_liste "${fichiers[$i]}" depend_de)
    if [ "$pret" -eq 1 ]; then echo "${ids[$i]}"; exit 0; fi
  done
  exit 1
fi

echo "| Id | Titre | Statut | Dépend de | Branche |"
echo "|---|---|---|---|---|"
for i in "${!ids[@]}"; do
  [ -z "$filtre" ] || [ "${statuts[$i]}" = "$filtre" ] || continue
  deps="$(issue_liste "${fichiers[$i]}" depend_de | paste -sd, - | sed 's/,/, /g')"
  echo "| ${ids[$i]} | $(issue_champ "${fichiers[$i]}" titre) | ${statuts[$i]} | ${deps:-:} | $(issue_champ "${fichiers[$i]}" branche) |"
done
