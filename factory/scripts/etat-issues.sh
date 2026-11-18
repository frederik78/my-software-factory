#!/usr/bin/env bash
# État des issues de docs/issues/ lu directement dans leur en-tête (remplace un index tenu à la main, qui dériverait).
#
# Usage : scripts/etat-issues.sh [--statut "À faire"]     (tableau Markdown, une ligne par issue)
#         scripts/etat-issues.sh --prochaine              (id de la première issue dont le statut effectif est « À faire » et dont toutes les dépendances sont levées,
#                                                          c'est-à-dire « Fait » ici ou sur leur branche retenue, déclarée ou déduite ; le tableau garde le statut local)
#         Colonne Branche : le champ « branche » tel quel s'il est rempli ; sinon `<nom> (déduite)` (branche locale `<type>/<id>-<suffixe>` trouvée par convention de nommage),
#         `ambiguë : <liste>` si plusieurs branches conviennent, vide sans correspondance.
# Code de sortie : 0 ; en mode --prochaine : 1 s'il n'y a aucune issue prête.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"
table_exiger # la table unique des statuts (factory/scripts/statuts.table) fixe l'ordre du cycle utilisé pour le statut effectif

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
rattachements_charger

# Statut effectif (branche retenue comprise) de l'issue de rang i, calculé une fois (variable globale, pas de sous-shell : la mémoire serait perdue).
effectifs=()
effectif_de_rang() { # effectif_de_rang <rang> : met le résultat dans $effectif
  if [ -z "${effectifs[$1]+x}" ]; then
    if [ "${statuts[$1]}" = "Fait" ]; then effectifs[$1]="Fait" # le plus avancé du cycle : aucune lecture de branche
    else effectifs[$1]="$(issue_statut_effectif "${fichiers[$1]}")"; fi
  fi
  effectif="${effectifs[$1]}"
}
statut_effectif_de() { # statut_effectif_de <id> : met le statut effectif de l'issue d'identifiant <id> dans $effectif (vide si elle n'existe pas)
  local i
  effectif=""
  for i in "${!ids[@]}"; do [ "${ids[$i]}" = "$1" ] && { effectif_de_rang "$i"; return; }; done
}

# Règle de la prochaine issue prête dupliquée dans dashboard.sh (prochaine_issue) : modifier les deux ensemble ; garde : ca14.
if [ "$mode" = "prochaine" ]; then
  for i in "${!ids[@]}"; do
    [ "${statuts[$i]}" = "À faire" ] || continue
    pret=1
    while IFS= read -r dep; do
      if [ -n "$dep" ]; then statut_effectif_de "$dep"; [ "$effectif" = "Fait" ] || pret=0; fi
    done < <(issue_liste "${fichiers[$i]}" depend_de)
    effectif_de_rang "$i"; [ "$effectif" = "À faire" ] || pret=0
    if [ "$pret" -eq 1 ]; then echo "${ids[$i]}"; exit 0; fi
  done
  exit 1
fi

branche_de() { # branche_de <fichier> : champ « branche » tel quel ; sinon « <nom> (déduite) » ou « ambiguë : <liste> » (RG-15)
  local b
  b="$(issue_champ "$1" branche)"
  if [ -z "$b" ]; then
    b="$(issue_branche_deduite "$1")"
    if [ -n "$b" ]; then b="$b (déduite)"
    else b="$(issue_branches_ambigues "$1")"; [ -z "$b" ] || b="ambiguë : $b"; fi
  fi
  printf '%s' "$b"
}

echo "| Id | Titre | Statut | Dépend de | Branche |"
echo "|---|---|---|---|---|"
for i in "${!ids[@]}"; do
  [ -z "$filtre" ] || [ "${statuts[$i]}" = "$filtre" ] || continue
  deps="$(issue_liste "${fichiers[$i]}" depend_de | paste -sd, - | sed 's/,/, /g')"
  echo "| ${ids[$i]} | $(issue_champ "${fichiers[$i]}" titre) | ${statuts[$i]} | ${deps:-:} | $(branche_de "${fichiers[$i]}") |"
done
