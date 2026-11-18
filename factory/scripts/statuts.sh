#!/usr/bin/env bash
# Statuts des besoins (backlog.md) et des issues (docs/issues/) : table unique et contrôle en lecture seule (PRD 004).
#
# Usage : scripts/statuts.sh            contrôle (à venir dans cette issue)
#         scripts/statuts.sh --table    affiche les statuts (dans l'ordre) et les transitions légales (de, vers, déclencheur, preuve) de chaque entité ; code 0
# Les statuts et les transitions sont définis une seule fois, dans factory/scripts/statuts.table (lue par lib-issues.sh).
# Code de sortie : 0, 1 (table illisible), 64 usage (option inconnue ou argument superflu ; un seul argument est permis : --table).
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"
# shellcheck source=lib-constats.sh
. "$(dirname "$0")/lib-constats.sh"

usage() { echo "Usage : $0 [--table]" >&2; exit 64; }

# afficher_table : les deux tables (statuts dans l'ordre, puis transitions légales), lues dans la table unique.
afficher_table() {
  local entite article i
  for entite in issue besoin; do
    case "$entite" in issue) article="d'une issue" ;; *) article="d'un besoin" ;; esac
    printf "Statuts %s (dans l'ordre) :\n" "$article"
    for i in "${!table_nom[@]}"; do
      [ "${table_entite[$i]}" = "$entite" ] || continue
      if [ "${table_portee[$i]}" = cycle ]; then printf '  %s\n' "${table_nom[$i]}"; else printf '  %s (hors cycle)\n' "${table_nom[$i]}"; fi
    done
    printf "Transitions légales %s :\n" "$article"
    for i in "${!tr_de[@]}"; do
      [ "${tr_entite[$i]}" = "$entite" ] || continue
      printf '  %s -> %s | déclencheur : %s | preuve : %s\n' "${tr_de[$i]}" "${tr_vers[$i]}" "${tr_declencheur[$i]}" "${tr_preuve[$i]}"
    done
  done
}

# controle_issues : un constat E10 par issue dont le statut n'est pas dans la table.
controle_issues() {
  local f id statut rang=0 attendus
  table_statuts_de issue; attendus="$statuts_de"
  while IFS= read -r f; do
    rang=$((rang + 1))
    id="$(issue_champ "$f" id)"; statut="$(issue_champ "$f" statut)"
    table_nettoyer "$statut"; statut="$nettoye" # espaces à l'intérieur de guillemets de bord : « " Fait " » est lu Fait
    table_statut_connu issue "$statut" && continue
    constat_neutraliser "$id"; id="$neutre"; constat_neutraliser "$statut"
    constat_ajouter ERREUR E10 2 "$rang" "issue $id" "statut inconnu « $neutre » (attendus : $attendus)"
  done < <(issue_fichiers)
}

# controle_besoins : un constat E05 par besoin du tableau de backlog.md dont le statut n'est pas dans la table.
controle_besoins() {
  local id statut rang=0 attendus
  table_statuts_de besoin; attendus="$statuts_de"
  while IFS="$CONSTAT_SEP" read -r id statut; do
    rang=$((rang + 1))
    table_statut_connu besoin "$statut" && continue
    constat_neutraliser "$id"; id="$neutre"; constat_neutraliser "$statut"
    constat_ajouter ERREUR E05 1 "$rang" "besoin $id" "statut inconnu « $neutre » (attendus : $attendus)"
  done < <(awk -v FS='|' -v OFS="$CONSTAT_SEP" '
    /^## / { actif = ($0 ~ /^## Besoins fonctionnels/); next }
    actif && /^\|/ {
      gsub(/\\\|/, "\001")
      for (i = 2; i <= 7; i++) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); gsub(/\001/, "|", $i) }
      if ($2 == "ID" || $2 ~ /^[-: ]+$/ || $2 == "") next
      print $2, $5
    }
  ' backlog.md)
}

case "${1:-}" in
  --table) [ $# -eq 1 ] || usage; table_exiger; afficher_table ;;
  "") table_exiger; controle_besoins; controle_issues; constats_rendre ;;
  *) usage ;;
esac
