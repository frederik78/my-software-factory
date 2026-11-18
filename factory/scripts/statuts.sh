#!/usr/bin/env bash
# Statuts des besoins (backlog.md) et des issues (docs/issues/) : table unique et contrôle en lecture seule (PRD 004).
#
# Usage : scripts/statuts.sh            contrôle de l'état courant : statuts inconnus (E05 besoin, E10 issue), backlog illisible (E01, E02, E03, E04),
#                                       fichiers d'issue illisibles (E14) ou sans identifiant (E11) ; les autres contrôles du PRD 004 viennent avec les issues suivantes
#         scripts/statuts.sh --table    affiche les statuts (dans l'ordre) et les transitions légales (de, vers, déclencheur, preuve) de chaque entité ; code 0
# Sortie : une ligne par constat « <ERREUR|AVIS> <CODE> <objet> : <texte> » (erreurs avant avis, puis objet, puis code), puis « STATUTS : <e> erreur(s), <a> avis ».
# Les valeurs lues dans les fichiers sont des données : jamais évaluées, neutralisées dans les messages (lib-constats.sh). Aucun fichier n'est écrit.
# Les statuts et les transitions sont définis une seule fois, dans factory/scripts/statuts.table (lue par lib-issues.sh).
# Code de sortie : 0 aucune erreur (les avis sont permis), 1 au moins une erreur ou table des statuts illisible, 64 usage (un seul argument est permis : --table).
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

# Taille maximale (octets) d'un fichier d'issue lu : au-delà, le fichier est refusé (E14). Une issue fait quelques ko.
ISSUE_OCTETS_MAX=1048576

# issue_illisible <fichier> : met dans $motif_e14 le motif E14 du fichier (lien symbolique, plus de 1 Mio, lecture impossible, en-tête YAML absent ou non fermé), vide s'il est lisible.
# Le fichier n'est ouvert qu'une fois ces vérifications faites : un lien symbolique n'est jamais suivi, un gros fichier jamais lu.
issue_illisible() {
  local taille
  motif_e14=""
  if [ -L "$1" ]; then motif_e14="lien symbolique"
  elif [ ! -f "$1" ] || [ ! -r "$1" ]; then motif_e14="lecture impossible"
  elif ! taille="$(wc -c < "$1" 2>/dev/null)"; then motif_e14="lecture impossible"
  elif [ "$((taille + 0))" -gt "$ISSUE_OCTETS_MAX" ]; then motif_e14="plus de 1 Mio"
  elif ! awk 'NR == 1 { if ($0 != "---") exit 1; next } $0 == "---" { fin = 1; exit } END { exit fin ? 0 : 1 }' "$1" 2>/dev/null; then motif_e14="en-tête YAML absent ou non fermé"
  fi
}

# controle_issues : E14 (fichier illisible), E11 (identifiant absent ou en double), E10 (statut inconnu) pour les fichiers de docs/issues/.
# Un fichier en erreur n'émet pas d'autre constat. Ordre des vérifications d'un fichier : E14, E11 (absent), E10, E11 (en double).
controle_issues() {
  local f id statut rang=0 attendus chemin liste_ids="" doublons i
  local fichiers=() ids=() statuts=() etats=() rangs=()
  table_statuts_de issue; attendus="$statuts_de"
  while IFS= read -r f; do
    rang=$((rang + 1)); fichiers+=("$f"); rangs+=("$rang")
    constat_neutraliser "$f"; chemin="$neutre"
    issue_illisible "$f"
    if [ -n "$motif_e14" ]; then
      ids+=(""); statuts+=(""); etats+=(ignoree)
      constat_ajouter ERREUR E14 2 "$rang" "fichier $chemin" "fichier d'issue illisible ($motif_e14)"; continue
    fi
    id="$(issue_champ "$f" id)"; table_nettoyer "$id"; id="$nettoye"
    statut="$(issue_champ "$f" statut)"; table_nettoyer "$statut"; statut="$nettoye" # espaces à l'intérieur de guillemets de bord : « " Fait " » est lu Fait
    ids+=("$id"); statuts+=("$statut")
    if [ -z "$id" ]; then
      etats+=(ignoree); constat_ajouter ERREUR E11 2 "$rang" "fichier $chemin" "identifiant d'issue absent"; continue
    fi
    etats+=(lue); liste_ids="$liste_ids$id"$'\n'
  done < <(issue_fichiers)
  doublons=$'\n'"$(printf '%s' "$liste_ids" | LC_ALL=C sort | uniq -d)"$'\n'
  for i in "${!fichiers[@]}"; do
    [ "${etats[$i]}" = lue ] || continue
    id="${ids[$i]}"
    constat_neutraliser "$id"; id="$neutre"
    if ! table_statut_connu issue "${statuts[$i]}"; then
      constat_neutraliser "${statuts[$i]}"
      constat_ajouter ERREUR E10 2 "${rangs[$i]}" "issue $id" "statut inconnu « $neutre » (attendus : $attendus)"
    else
      case "$doublons" in
        *$'\n'"${ids[$i]}"$'\n'*)
          constat_neutraliser "${fichiers[$i]}"
          constat_ajouter ERREUR E11 2 "${rangs[$i]}" "fichier $neutre" "identifiant d'issue en double : $id" ;;
      esac
    fi
  done
}

# besoins_lire : lit le premier tableau de backlog.md dont l'en-tête a les colonnes ID, Statut et PRD (RG-04), colonnes repérées par leur nom, cellules sans espaces de bord,
# « \| » = barre littérale. Une ligne par enregistrement, champs séparés par CONSTAT_SEP :
#   N                           aucun tableau reconnu
#   L <id>                      ligne dont le nombre de colonnes diffère de l'en-tête
#   R <id> <statut> <doublon>   ligne lisible ; doublon = 1 sur la première ligne d'un identifiant qui revient
# Une ligne sans identifiant n'est pas un besoin (comme dans le dashboard). Les valeurs ne sont qu'imprimées : jamais évaluées ni utilisées comme motif.
besoins_lire() {
  awk -v OFS="$CONSTAT_SEP" '
    function trim(x) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", x); return x }
    function cellules(ligne,   k) {
      gsub(/\\\|/, "\001", ligne)
      sub(/^[[:space:]]*\|/, "", ligne); sub(/\|[[:space:]]*$/, "", ligne)
      nc = split(ligne, c, "|")
      for (k = 1; k <= nc; k++) { c[k] = trim(c[k]); gsub(/\001/, "|", c[k]) }
    }
    etat == 1 && $0 !~ /^[[:space:]]*\|/ { exit }
    $0 ~ /^[[:space:]]*\|/ {
      cellules($0)
      if (etat == 0) {
        ii = 0; is = 0; ip = 0
        for (k = 1; k <= nc; k++) { if (c[k] == "ID") ii = k; if (c[k] == "Statut") is = k; if (c[k] == "PRD") ip = k }
        if (ii && is && ip) { etat = 1; ncol = nc }
        next
      }
      sep = 1; for (k = 1; k <= nc; k++) if (c[k] !~ /^:?-+:?$/) sep = 0
      if (sep) next
      id = (ii <= nc ? c[ii] : ""); if (id == "") next
      n++; rtype[n] = (nc == ncol ? "R" : "L"); rid[n] = id; rst[n] = (is <= nc ? c[is] : "")
      if (nc == ncol) fois[id]++
    }
    END {
      if (etat == 0) { print "N"; exit }
      for (k = 1; k <= n; k++) {
        if (rtype[k] == "L") { print "L", rid[k]; continue }
        dup = (fois[rid[k]] > 1 && !(rid[k] in vu)) ? 1 : 0; vu[rid[k]] = 1
        print "R", rid[k], rst[k], dup
      }
    }
  ' backlog.md
}

# controle_besoins : E02 (aucun tableau), E03 (ligne illisible), E04 (identifiant en double), E05 (statut inconnu) pour les besoins de backlog.md.
controle_besoins() {
  local typ id statut dup rang=0 attendus
  table_statuts_de besoin; attendus="$statuts_de"
  while IFS="$CONSTAT_SEP" read -r typ id statut dup; do
    if [ "$typ" = N ]; then
      constat_ajouter ERREUR E02 0 0 backlog "tableau des besoins introuvable (colonnes ID, Statut, PRD attendues)"; continue
    fi
    rang=$((rang + 1))
    constat_neutraliser "$id"; id="$neutre"
    if [ "$typ" = L ]; then
      constat_ajouter ERREUR E03 1 "$rang" "besoin $id" "ligne illisible (nombre de colonnes différent de l'en-tête)"; continue
    fi
    [ "$dup" != 1 ] || constat_ajouter ERREUR E04 1 "$rang" "besoin $id" "identifiant en double dans le backlog"
    table_statut_connu besoin "$statut" && continue
    constat_neutraliser "$statut"
    constat_ajouter ERREUR E05 1 "$rang" "besoin $id" "statut inconnu « $neutre » (attendus : $attendus)"
  done < <(besoins_lire)
}

# controle : backlog.md absent ou illisible = la seule erreur est E01 ; sinon les besoins puis les issues.
controle() {
  if [ ! -f backlog.md ] || [ ! -r backlog.md ]; then
    constat_ajouter ERREUR E01 0 0 backlog "backlog.md absent ou illisible"
  else
    controle_besoins; controle_issues
  fi
  constats_rendre
}

if [ $# -eq 0 ]; then table_exiger; controle
elif [ $# -eq 1 ] && [ "$1" = "--table" ]; then table_exiger; afficher_table
else usage
fi
