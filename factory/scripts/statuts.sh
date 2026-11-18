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
# shellcheck source=lib-preuves.sh
. "$(dirname "$0")/lib-preuves.sh"

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

# issue_illisible <fichier> : met dans $motif_e14 le motif E14 du fichier (lien symbolique, plus de 1 Mio, lecture impossible, en-tête YAML absent ou non fermé), vide s'il est lisible.
issue_illisible() {
  fichier_motif_refus "$1"; motif_e14="$motif_refus"
  [ -n "$motif_e14" ] || awk 'NR == 1 { if ($0 != "---") exit 1; next } $0 == "---" { fin = 1; exit } END { exit fin ? 0 : 1 }' "$1" 2>/dev/null \
    || motif_e14="en-tête YAML absent ou non fermé"
}

# Issues de docs/issues/ (une entrée par fichier, dans l'ordre) : tableaux parallèles remplis par controle_issues.
#   iss_etats : ignoree (E14, E11 absent), lue (id lu), controlee (id unique et statut connu : seules les issues contrôlées reçoivent les autres constats)
iss_fichiers=(); iss_ids=(); iss_statuts=(); iss_etats=(); iss_rangs=()

# controle_issues : E14 (fichier illisible), E11 (identifiant absent ou en double), E10 (statut inconnu), puis les preuves des issues contrôlées.
# Un fichier en erreur E14 ou E11 (absent) n'émet pas d'autre constat ; un identifiant en double donne E11 et, si le statut est inconnu, E10 sur le fichier.
controle_issues() {
  local f id statut rang=0 attendus chemin liste_ids="" doublons i objet double
  iss_fichiers=(); iss_ids=(); iss_statuts=(); iss_etats=(); iss_rangs=()
  table_statuts_de issue; attendus="$statuts_de"
  while IFS= read -r f; do
    rang=$((rang + 1)); iss_fichiers+=("$f"); iss_rangs+=("$rang")
    constat_neutraliser "$f"; chemin="$neutre"
    issue_illisible "$f"
    if [ -n "$motif_e14" ]; then
      iss_ids+=(""); iss_statuts+=(""); iss_etats+=(ignoree)
      constat_ajouter ERREUR E14 2 "$rang" "fichier $chemin" "fichier d'issue illisible ($motif_e14)"; continue
    fi
    id="$(issue_champ "$f" id)"; table_nettoyer "$id"; id="$nettoye"
    statut="$(issue_champ "$f" statut)"; table_nettoyer "$statut"; statut="$nettoye" # espaces à l'intérieur de guillemets de bord : « " Fait " » est lu Fait
    iss_ids+=("$id"); iss_statuts+=("$statut")
    if [ -z "$id" ]; then
      iss_etats+=(ignoree); constat_ajouter ERREUR E11 2 "$rang" "fichier $chemin" "identifiant d'issue absent"; continue
    fi
    iss_etats+=(lue); liste_ids="$liste_ids$id"$'\n'
  done < <(issue_fichiers)
  doublons=$'\n'"$(printf '%s' "$liste_ids" | LC_ALL=C sort | uniq -d)"$'\n'
  for i in "${!iss_fichiers[@]}"; do
    [ "${iss_etats[$i]}" = lue ] || continue
    constat_neutraliser "${iss_ids[$i]}"; id="$neutre"
    constat_neutraliser "${iss_fichiers[$i]}"; chemin="$neutre"
    objet="issue $id"; double=0
    case "$doublons" in *$'\n'"${iss_ids[$i]}"$'\n'*) double=1; objet="fichier $chemin" ;; esac # deux fichiers de même id : l'objet est le fichier, pour les distinguer
    if ! table_statut_connu issue "${iss_statuts[$i]}"; then
      constat_neutraliser "${iss_statuts[$i]}"
      constat_ajouter ERREUR E10 2 "${iss_rangs[$i]}" "$objet" "statut inconnu « $neutre » (attendus : $attendus)"
    elif [ "$double" -eq 0 ]; then
      iss_etats[$i]=controlee
    fi
    [ "$double" -eq 0 ] || constat_ajouter ERREUR E11 2 "${iss_rangs[$i]}" "fichier $chemin" "identifiant d'issue en double : $id"
  done
  controle_preuves
  preuves_commits_verifier
}

# issues_effectifs_calculer : branche retenue (iss_refs : refs/heads/<nom>, vide si aucune) et statut effectif (iss_effectifs) de chaque issue contrôlée, comme le dashboard (PRD 003).
# Un statut hors cycle ou le dernier du cycle ne lit aucune branche (le statut local est déjà le résultat).
iss_refs=(); iss_effectifs=()
issues_effectifs_calculer() {
  local i rang ref dernier=$((${#statuts_issues[@]} - 1))
  rattachements_charger # une seule lecture des branches locales
  for i in "${!iss_fichiers[@]}"; do
    iss_refs+=(""); iss_effectifs+=("${iss_statuts[$i]}")
    [ "${iss_etats[$i]}" = controlee ] || continue
    rang="$(issue_rang_statut "${iss_statuts[$i]}")" && [ "$rang" -lt "$dernier" ] || continue
    ref="$(issue_ref_branche "${iss_fichiers[$i]}")"
    iss_refs[$i]="$ref"; iss_effectifs[$i]="$(issue_statut_effectif "${iss_fichiers[$i]}" "$ref")"
  done
}

# controle_preuves : les preuves de chaque issue contrôlée, selon son statut local (lib-preuves.sh), et la branche retenue des issues démarrées (statut effectif).
controle_preuves() {
  local i
  issues_effectifs_calculer
  for i in "${!iss_fichiers[@]}"; do
    [ "${iss_etats[$i]}" = controlee ] || continue
    case "${iss_effectifs[$i]}" in
      "En cours"|"En revue")
        [ -n "${iss_refs[$i]}" ] || preuves_branche "${iss_rangs[$i]}" "${iss_ids[$i]}" "${iss_effectifs[$i]}" "$(issue_branches_ambigues "${iss_fichiers[$i]}")" ;;
    esac
    case "${iss_statuts[$i]}" in
      Fait) preuves_fait "${iss_rangs[$i]}" "${iss_fichiers[$i]}" "${iss_ids[$i]}" ;;
      "En revue") preuves_en_revue "${iss_rangs[$i]}" "${iss_fichiers[$i]}" "${iss_ids[$i]}" ;;
    esac
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
      gsub(/\037/, "\357\277\275", ligne) # 0x1F est le séparateur des enregistrements : une cellule qui en contient ne peut pas passer pour valide (U+FFFD à la place)
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
