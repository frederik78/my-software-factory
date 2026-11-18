#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : constats d'un contrôle (erreurs et avis), leur tri et leur sortie (PRD 004, RG-20 et RG-21).
# Compatible bash 3.2 (macOS). Un constat est une ligne « <GRAVITÉ> <CODE> <objet> : <texte> » ; GRAVITÉ = ERREUR ou AVIS.
# Usage : constat_neutraliser <valeur lue dans un fichier> (met la valeur sûre dans $neutre), puis constat_ajouter <ERREUR|AVIS> <code> <groupe> <rang> <objet> <texte>,
#         puis constats_rendre (écrit les lignes triées et le récapitulatif ; code 1 s'il y a au moins une erreur, 0 sinon).
# Tri : erreurs avant avis, puis par groupe (0 backlog, 1 besoin, 2 issue ou fichier), puis par rang dans le groupe (ordre du tableau ou des fichiers), puis par code.
# Une valeur lue dans un fichier est une donnée non fiable : jamais évaluée ; neutralisée avant d'entrer dans un message (retours à la ligne, tabulations, caractères de contrôle).

CONSTAT_VALEUR_MAX=120
CONSTAT_SEP=$'\037'
constats=(); constats_erreurs=0; constats_avis=0

# constat_neutraliser <valeur> : $neutre = la valeur sur une seule ligne, sans caractère de contrôle, tronquée à CONSTAT_VALEUR_MAX caractères (suffixe « … »).
constat_neutraliser() {
  neutre="$1"
  neutre="${neutre//$'\r'/ }"; neutre="${neutre//$'\n'/ }"; neutre="${neutre//$'\t'/ }"
  case "$neutre" in *[[:cntrl:]]*) neutre="$(printf '%s' "$neutre" | LC_ALL=C tr -d '\000-\037\177')" ;; esac
  [ "${#neutre}" -le "$CONSTAT_VALEUR_MAX" ] || neutre="${neutre:0:$CONSTAT_VALEUR_MAX}…"
}

# constat_ajouter <ERREUR|AVIS> <code> <groupe> <rang> <objet> <texte> : objet et texte sont déjà neutralisés par l'appelant.
constat_ajouter() {
  case "$1" in
    ERREUR) constats_erreurs=$((constats_erreurs + 1)); constats+=("0$CONSTAT_SEP$3$CONSTAT_SEP$4$CONSTAT_SEP$2$CONSTAT_SEP$1 $2 $5 : $6") ;;
    AVIS) constats_avis=$((constats_avis + 1)); constats+=("1$CONSTAT_SEP$3$CONSTAT_SEP$4$CONSTAT_SEP$2$CONSTAT_SEP$1 $2 $5 : $6") ;;
  esac
}

# constats_rendre : les constats triés, puis « STATUTS : <e> erreur(s), <a> avis » ; code 1 s'il y a au moins une erreur.
constats_rendre() {
  if [ "${#constats[@]}" -gt 0 ]; then
    printf '%s\n' "${constats[@]}" | LC_ALL=C sort -s -t "$CONSTAT_SEP" -k1,1n -k2,2n -k3,3n -k4,4 | cut -d "$CONSTAT_SEP" -f5-
  fi
  printf 'STATUTS : %d erreur(s), %d avis\n' "$constats_erreurs" "$constats_avis"
  [ "$constats_erreurs" -eq 0 ]
}
