#!/usr/bin/env bash
# Statuts des besoins (backlog.md) et des issues (docs/issues/) : table unique et contrôle en lecture seule (PRD 004).
#
# Usage : scripts/statuts.sh            contrôle de l'état courant : statuts inconnus (E05 besoin, E10 issue), backlog illisible (E01, E02, E03, E04),
#                                       fichiers d'issue illisibles (E14) ou sans identifiant (E11), preuves d'une issue (A01 à A07 : revue, FIN-ISSUE OK, commits ;
#                                       lib-preuves.sh), branche retenue d'une issue démarrée (A08), raison d'une issue Abandonnée (E13), dépendances (A09 à A11) ;
#                                       besoins (lib-besoins.sh, lib-fusion.sh) : issue sans besoin connu (E12), besoin sans PRD (E06), en retard (E07), en avance (A12), Fait non
#                                       justifié par la fusion dans la branche locale develop (E08, A13), Abandonnée (E09, A15), PRD d'une issue (A14)
#         scripts/statuts.sh --table    affiche les statuts (dans l'ordre) et les transitions légales (de, vers, déclencheur, preuve) de chaque entité ; code 0
# Sortie : une ligne par constat « <ERREUR|AVIS> <CODE> <objet> : <texte> » (erreurs avant avis, puis objet, puis code), puis « STATUTS : <e> erreur(s), <a> avis ».
# Les valeurs lues dans les fichiers sont des données : jamais évaluées, neutralisées dans les messages (lib-constats.sh). Aucun fichier n'est écrit.
# Coût : les en-têtes de toutes les issues sont lus en un seul passage (lib-issues.sh, issues_en_tetes_charger), les fichiers trop gros listés par un seul find par dossier,
# le verdict d'une revue lu sans processus par fichier (lib-verdict.sh) : de l'ordre de la seconde par centaine d'issues (mesuré par le test cs04_volumes).
# Les statuts et les transitions sont définis une seule fois, dans factory/scripts/statuts.table (lue par lib-issues.sh).
# Code de sortie : 0 aucune erreur (les avis sont permis), 1 au moins une erreur ou table des statuts illisible, 64 usage (un seul argument est permis : --table).
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"
# shellcheck source=lib-constats.sh
. "$(dirname "$0")/lib-constats.sh"
# shellcheck source=lib-verdict.sh
. "$(dirname "$0")/lib-verdict.sh" # lecture stricte du verdict d'une revue (RG-10 b), jamais dupliquée ici
# shellcheck source=lib-preuves.sh
. "$(dirname "$0")/lib-preuves.sh"
# shellcheck source=lib-dependances.sh
. "$(dirname "$0")/lib-dependances.sh"
# shellcheck source=lib-fusion.sh
. "$(dirname "$0")/lib-fusion.sh"
# shellcheck source=lib-besoins.sh
. "$(dirname "$0")/lib-besoins.sh"

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

# Issues de docs/issues/ (une entrée par fichier, dans l'ordre) : tableaux parallèles remplis par controle_issues.
#   iss_etats : ignoree (E14, E11 absent), lue (id lu), controlee (id unique et statut connu : seules les issues contrôlées reçoivent les autres constats)
iss_fichiers=(); iss_ids=(); iss_statuts=(); iss_etats=(); iss_rangs=()

# controle_issues : E14 (fichier illisible), E11 (identifiant absent ou en double), E10 (statut inconnu), puis les preuves des issues contrôlées.
# Un fichier en erreur E14 ou E11 (absent) n'émet pas d'autre constat ; un identifiant en double donne E11 et, si le statut est inconnu, E10 sur le fichier.
controle_issues() {
  local f id statut rang=0 attendus chemin liste_ids="" doublons i objet double motif_e14
  iss_fichiers=(); iss_ids=(); iss_statuts=(); iss_etats=(); iss_rangs=()
  table_statuts_de issue; attendus="$statuts_de"
  issues_en_tetes_charger # tous les en-têtes en un seul passage : les valeurs ci-dessous et celles des preuves, des dépendances et des besoins viennent de là
  gros_charger docs/reviews # les fichiers de revue de plus de 1 Mio, listés une fois
  for i in "${!ent_fichiers[@]}"; do
    f="${ent_fichiers[$i]}"
    rang=$((rang + 1)); iss_fichiers+=("$f"); iss_rangs+=("$rang")
    constat_neutraliser "$f"; chemin="$neutre"
    motif_e14="${ent_refus[$i]}"
    [ -n "$motif_e14" ] || [ "${ent_ok[$i]}" -eq 1 ] || motif_e14="en-tête YAML absent ou non fermé"
    if [ -n "$motif_e14" ]; then
      iss_ids+=(""); iss_statuts+=(""); iss_etats+=(ignoree)
      constat_ajouter ERREUR E14 2 "$rang" "fichier $chemin" "fichier d'issue illisible ($motif_e14)"; continue
    fi
    table_nettoyer "${ent_ids[$i]}"; id="$nettoye"
    table_nettoyer "${ent_statuts[$i]}"; statut="$nettoye" # espaces à l'intérieur de guillemets de bord : « " Fait " » est lu Fait
    iss_ids+=("$id"); iss_statuts+=("$statut")
    if [ -z "$id" ]; then
      iss_etats+=(ignoree); constat_ajouter ERREUR E11 2 "$rang" "fichier $chemin" "identifiant d'issue absent"; continue
    fi
    iss_etats+=(lue); liste_ids="$liste_ids$id"$'\n'
  done
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
  controle_dependances
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
    ref="$(issue_ref_branche "${iss_fichiers[$i]}" "$i")"
    iss_refs[$i]="$ref"; iss_effectifs[$i]="$(issue_statut_effectif "${iss_fichiers[$i]}" "$ref" "${iss_statuts[$i]}")"
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
        [ -n "${iss_refs[$i]}" ] || preuves_branche "${iss_rangs[$i]}" "${iss_ids[$i]}" "${iss_effectifs[$i]}" "${rat_ambigues[$i]:-}" ;;
    esac
    case "${iss_statuts[$i]}" in
      Fait) preuves_fait "${iss_rangs[$i]}" "$i" "${iss_ids[$i]}" ;;
      "En revue") preuves_en_revue "${iss_rangs[$i]}" "$i" "${iss_ids[$i]}" ;;
      Abandonnée) preuves_abandon "${iss_rangs[$i]}" "$i" "${iss_ids[$i]}" ;;
    esac
  done
}

# dependance_signaler <rang> <id de l'issue> <dépendance> <état> : A09 (dépendance Abandonnée), A10 (dépendance inconnue) ou A11 (issue Fait dont une dépendance n'est pas terminée).
# <état> : S<statut effectif de la dépendance>, U (identifiant inutilisable, aucun avis : l'erreur E10 ou E11 le dit déjà) ou X (aucune issue de cet identifiant).
dependance_signaler() {
  local objet dep
  constat_neutraliser "$2"; objet="issue $neutre"
  constat_neutraliser "$3"; dep="$neutre"
  if [ "${iss_statuts[$1]}" = Fait ]; then # une issue Fait n'a d'avis que A11 ; une dépendance inconnue, Fait ou Abandonnée ne lui est pas reprochée
    case "$4" in SFait|SAbandonnée|U|X) ;; S*) constat_ajouter AVIS A11 2 "${iss_rangs[$1]}" "$objet" "Fait alors que la dépendance $dep n'est pas terminée" ;; esac
  else
    case "$4" in
      X) constat_ajouter AVIS A10 2 "${iss_rangs[$1]}" "$objet" "dépend de $dep, issue inconnue" ;;
      SAbandonnée) constat_ajouter AVIS A09 2 "${iss_rangs[$1]}" "$objet" "dépend de l'issue Abandonnée $dep" ;;
    esac
  fi
}

# controle_dependances : A09, A10, A11 (RG-13). Concerne les issues Fait (statut local) et celles dont le statut effectif n'est ni Fait ni Abandonnée ; les dépendances sont
# résolues en un seul passage (dependances_resoudre) sur le statut effectif des issues contrôlées. Une dépendance n'est jamais levée par ces avis (comportement du dashboard inchangé).
controle_dependances() {
  local i dep flux=() rang etat
  for i in "${!iss_fichiers[@]}"; do
    case "${iss_ids[$i]}" in *"$CONSTAT_SEP"*|'') continue ;; esac
    if [ "${iss_etats[$i]}" = controlee ]; then flux+=("I$CONSTAT_SEP${iss_ids[$i]}$CONSTAT_SEP${iss_effectifs[$i]}")
    elif [ "${iss_etats[$i]}" = lue ]; then flux+=("U$CONSTAT_SEP${iss_ids[$i]}")
    fi
  done
  for i in "${!iss_fichiers[@]}"; do
    [ "${iss_etats[$i]}" = controlee ] || continue
    [ "${iss_statuts[$i]}" = Fait ] || case "${iss_effectifs[$i]}" in Fait|Abandonnée) continue ;; esac
    ent_elements "${ent_dependances[$i]}"
    for dep in "${ent_items[@]+"${ent_items[@]}"}"; do
      case "$dep" in
        *"$CONSTAT_SEP"*) dependance_signaler "$i" "${iss_ids[$i]}" "$dep" X ;; # ne peut pas désigner une issue : jamais transmis au séparateur de flux
        *) flux+=("D$CONSTAT_SEP$i$CONSTAT_SEP$dep") ;;
      esac
    done
  done
  [ "${#flux[@]}" -gt 0 ] || return 0
  while IFS="$CONSTAT_SEP" read -r rang dep etat; do
    dependance_signaler "$rang" "${iss_ids[$rang]}" "$dep" "$etat"
  done < <(printf '%s\n' "${flux[@]}" | dependances_resoudre)
}

# controle : backlog.md absent ou illisible = la seule erreur est E01 ; sinon les besoins puis les issues.
controle() {
  if [ ! -f backlog.md ] || [ ! -r backlog.md ]; then
    constat_ajouter ERREUR E01 0 0 backlog "backlog.md absent ou illisible"
  else
    controle_besoins; controle_issues; besoins_coherence
  fi
  constats_rendre
}

if [ $# -eq 0 ]; then table_exiger; controle
elif [ $# -eq 1 ] && [ "$1" = "--table" ]; then table_exiger; afficher_table
else usage
fi
