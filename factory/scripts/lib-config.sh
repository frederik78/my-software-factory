#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : configuration de la factory pour le projet courant (répertoire courant = racine du projet).
# Trois niveaux, du moins au plus prioritaire :
#   1. .factory.conf        versionné, créé par init-projet.sh (valeurs communes à l'équipe) ;
#   2. .factory.local.conf  ignoré par git (valeurs personnelles : adresse de notification...) ;
#   3. variable d'environnement FACTORY_<CLÉ> (ex. FACTORY_MAX_ITERATIONS_REVUE).
# Un niveau qui définit une clé l'emporte, même avec une valeur vide (une variable d'environnement compte dès qu'elle est définie).
# SÉCURITÉ : ces fichiers ne sont JAMAIS sourcés ni évalués. Ils sont lus comme des lignes « CLÉ=valeur » : seules les clés connues
# (CONFIG_CLES) sont prises, lignes vides et commentaires (#) ignorés. Indentation et espaces autour de « = » tolérés (« CLÉ = valeur ») :
# une ligne mal formatée ne doit pas être ignorée en silence. Valeur = ce qui suit le premier « = », sans ses espaces de bord ni le retour
# chariot final (fichier édité sous Windows), sinon telle quelle (pas de guillemets retirés, aucune expansion de $(...), `...` ni de variable).
# Si une clé apparaît plusieurs fois, la dernière gagne.
# Compatible bash 3.2 (macOS).

CONFIG_CLES="AGENT_MODELE AGENT_EFFORT MAX_ITERATIONS_REVUE MAX_CRITERES_ISSUE NOTIFICATION_COMMANDE NOTIFICATION_DESTINATAIRE NOTIFICATION_EXPEDITEUR FIN_ISSUE_ARGUMENTS FIN_ISSUE_IGNORES_AUTORISES AGENTS_SILENCE_MINUTES AGENTS_RETRAIT_MINUTES DASHBOARD_THEME TESTS_BASH_FONCTIONS DOSSIER_TESTS"

AGENT_MODELE_DEFAUT=sonnet
AGENT_EFFORT_DEFAUT=medium
AGENTS_SILENCE_MINUTES_DEFAUT=5   # bandeau « Agents actifs » de dashboard.sh
AGENTS_RETRAIT_MINUTES_DEFAUT=60
DASHBOARD_THEME_DEFAUT=clair      # thème de dashboard.sh : clair, sombre ou auto
TESTS_BASH_FONCTIONS_DEFAUT="verifier verdict_cas"   # fonctions dont un appel déclare un test dans les .sh (criteres-sans-test.sh)
DOSSIER_TESTS_DEFAUT=             # dossier des tests (criteres-sans-test.sh) ; vide = détection automatique (src/test, tests, test)

# config_fichier_valeur <fichier> <clé> : affiche la valeur de la clé dans le fichier ; code 1 si le fichier ou la clé est absent.
config_fichier_valeur() {
  [ -f "$1" ] || return 1
  awk -v k="$2" '
    { sub(/\r$/, "") }
    /^[[:space:]]*(#|$)/ { next }
    {
      l = $0; sub(/^[[:space:]]+/, "", l)
      if (index(l, k) != 1) next
      r = substr(l, length(k) + 1)
      if (r !~ /^[[:space:]]*=/) next
      sub(/^[[:space:]]*=[[:space:]]*/, "", r); sub(/[[:space:]]+$/, "", r)
      v = r; trouve = 1
    }
    END { if (trouve) print v; exit !trouve }
  ' "$1"
}

# config_valeur <clé> <défaut> : valeur effective de la clé (variable FACTORY_<clé>, sinon .factory.local.conf, sinon .factory.conf, sinon le défaut).
# Code 64 (message sur stderr) si la clé n'est pas une clé connue.
config_valeur() {
  local cle="$1" defaut="$2" variable="FACTORY_$1"
  case " $CONFIG_CLES " in
    *" $cle "*) ;;
    *) echo "Clé de configuration inconnue : $cle" >&2; return 64 ;;
  esac
  if [ -n "${!variable+x}" ]; then printf '%s\n' "${!variable}"; return 0; fi
  config_fichier_valeur .factory.local.conf "$cle" && return 0
  config_fichier_valeur .factory.conf "$cle" && return 0
  printf '%s\n' "$defaut"
}

# config_tests_bash_fonctions : affiche les noms de fonctions de test bash (TESTS_BASH_FONCTIONS), un par ligne, validés.
# La valeur est une donnée non fiable : elle n'est ni évaluée ni recopiée dans le message. Elle est validée AVANT tout usage, au caractère près
# (aucune coupure sur les sauts de ligne ou tabulations) : 1 à 20 noms séparés par des espaces, chacun [A-Za-z_][A-Za-z0-9_]* de 64 caractères au plus.
# Code 64 (message sur stderr) sinon ; la valeur remplace le défaut, elle ne s'y ajoute pas.
config_tests_bash_fonctions() {
  local LC_ALL=C brut valeur nom noms n=0 refus
  refus="TESTS_BASH_FONCTIONS invalide : 1 à 20 noms séparés par des espaces, chacun de 64 caractères au plus parmi A-Z a-z 0-9 _ et ne commençant pas par un chiffre (voir .factory.conf, .factory.local.conf, FACTORY_TESTS_BASH_FONCTIONS)."
  # Sentinelle « x » : la substitution de commande ne retire pas les sauts de ligne finaux de la valeur (ils la rendent invalide).
  brut="$(config_valeur TESTS_BASH_FONCTIONS "$TESTS_BASH_FONCTIONS_DEFAUT"; printf x)" || return 64
  valeur="${brut%x}"; valeur="${valeur%$'\n'}"
  case "$valeur" in *[!A-Za-z0-9_\ ]*) echo "$refus" >&2; return 64 ;; esac
  noms=()
  IFS=' ' read -r -a noms <<< "$valeur"
  for nom in ${noms[@]+"${noms[@]}"}; do
    n=$((n + 1))
    case "$nom" in [0-9]*) echo "$refus" >&2; return 64 ;; esac
    [ "${#nom}" -le 64 ] || { echo "$refus" >&2; return 64; }
  done
  { [ "$n" -ge 1 ] && [ "$n" -le 20 ]; } || { echo "$refus" >&2; return 64; }
  printf '%s\n' "${noms[@]}"
}

# config_dossier_tests : affiche le dossier des tests (DOSSIER_TESTS), vide si rien n'est réglé (= détection automatique, faite par l'appelant).
# Ordre, du plus fort au plus faible : variable DOSSIER_TESTS (sans préfixe, historique ; vide = non définie), FACTORY_DOSSIER_TESTS,
# .factory.local.conf, .factory.conf, détection. Ailleurs qu'ici une valeur vide d'une source l'emporte (config_valeur) : la variable
# non préfixée fait exception pour qu'un usage existant (DOSSIER_TESTS= vide) ne change pas. La valeur est un chemin, jamais évalué.
config_dossier_tests() {
  if [ -n "${DOSSIER_TESTS:-}" ]; then printf '%s\n' "$DOSSIER_TESTS"; return 0; fi
  config_valeur DOSSIER_TESTS "$DOSSIER_TESTS_DEFAUT"
}
