#!/usr/bin/env bash
# Contrôle de fin d'issue : une seule commande, une seule ligne de résultat, à lancer après le dernier commit de code.
# Enchaîne : arbre Git propre, verify-clean.sh (build complet dans une copie propre), criteres-sans-test.sh, contrôle des tests ignorés.
#
# Usage : scripts/fin-issue.sh <issue> [-- <arguments pour la commande de build>]
#         <issue> = chemin du fichier, ou id (ex. 001-03)
# Configuration (lib-config.sh, jamais exécutée) :
#   FIN_ISSUE_ARGUMENTS           arguments de build propres au poste, séparés par « | », espaces gardés ; placés avant ceux de la ligne de commande
#   FIN_ISSUE_IGNORES_AUTORISES   vide : aucun test ignoré admis ; n : au plus n ; inconnu : tolère un résumé sans nombre lisible
# Arbre propre exigé, fichiers non suivis non ignorés compris : verify-clean.sh les copie, ils seraient testés sans être dans le commit annoncé.
# Tests ignorés lus dans la ligne « Tests : … » de verify-clean.sh : Maven, pytest, unittest, suite de la factory. Autre résumé : illisible, donc échec.
# Dernière ligne : « FIN-ISSUE OK <id> <commit> : … » ou « FIN-ISSUE ECHEC : <raisons> ».
# Code de sortie : 0 succès, 1 échec, 64 erreur d'usage ou de configuration.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
dossier_scripts="$(cd "$(dirname "$0")" && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$dossier_scripts/lib-issues.sh"
# shellcheck source=lib-config.sh
. "$dossier_scripts/lib-config.sh"

usage() { echo "Usage : $0 <issue> [-- <arguments de build>]" >&2; exit 64; }
echec() { echo "FIN-ISSUE ECHEC : $1"; exit 1; }

[ $# -ge 1 ] || usage
case "$1" in -*) usage ;; esac
issue_arg="$1"; shift
args=()
if [ $# -gt 0 ]; then
  [ "$1" = "--" ] || usage
  shift; args=("$@")
fi

if [ -f "$issue_arg" ]; then
  fichier="$issue_arg"
else
  trouves=()
  while IFS= read -r f; do trouves+=("$f"); done < <(issue_fichiers "$issue_arg")
  if [ "${#trouves[@]}" -ne 1 ]; then echo "Aucune issue trouvée pour : $issue_arg (${#trouves[@]} fichier(s))" >&2; exit 64; fi
  fichier="${trouves[0]}"
fi
id="$(issue_champ "$fichier" id)"; id="${id:-$issue_arg}"

autorises="$(config_valeur FIN_ISSUE_IGNORES_AUTORISES "")"
case "$autorises" in
  ''|inconnu) ;;
  *[!0-9]*) echo "FIN_ISSUE_IGNORES_AUTORISES invalide : vide, entier >= 0 ou « inconnu » attendu." >&2; exit 64 ;;
esac
conf="$(config_valeur FIN_ISSUE_ARGUMENTS "")"
conf_args=()
[ -z "$conf" ] || IFS='|' read -r -a conf_args <<< "$conf"

git rev-parse --verify -q HEAD >/dev/null 2>&1 || echec "pas de commit à vérifier (dépôt Git requis)"
sale="$(git status --porcelain)"
if [ -n "$sale" ]; then
  printf '%s\n' "$sale"
  echec "arbre Git non propre : commitez ou ignorez ces fichiers (verify-clean.sh testerait ce qui n'est pas dans le commit)"
fi
commit="$(git rev-parse HEAD)"; court="$(git rev-parse --short HEAD)"
echo "Commit vérifié : $commit"

sortie="$("$dossier_scripts/verify-clean.sh" -- ${conf_args[@]+"${conf_args[@]}"} ${args[@]+"${args[@]}"} 2>&1)"; code=$?
printf '%s\n' "$sortie"
[ "$code" -ne 64 ] || { echo "FIN-ISSUE ECHEC : vérification impossible à lancer"; exit 64; }

"$dossier_scripts/criteres-sans-test.sh" "$fichier"; code_criteres=$?

raisons=""
ajoute() { raisons="${raisons:+$raisons ; }$1"; }
[ "$code" -eq 0 ] || ajoute "build en échec (code $code)"
[ "$code_criteres" -eq 0 ] || ajoute "critère sans test"

# Résumé de verify-clean.sh -> total, echecs, ignores (vides si illisibles).
resume="$(printf '%s\n' "$sortie" | sed -n 's/^Tests : //p' | tail -1)"
total=""; echecs=""; ignores=""
nombre_avant() { printf '%s\n' "$resume" | sed -nE "s/.*[^0-9]([0-9]+) $1.*/\\1/p;s/^([0-9]+) $1.*/\\1/p" | head -1; }
case "$resume" in
  "Tests run: "*)
    total="$(printf '%s\n' "$resume" | sed -E 's/^Tests run: ([0-9]+).*/\1/')"
    f="$(printf '%s\n' "$resume" | sed -E 's/.*Failures: ([0-9]+).*/\1/')"; e="$(printf '%s\n' "$resume" | sed -E 's/.*Errors: ([0-9]+).*/\1/')"
    echecs=$((f + e))
    ignores="$(printf '%s\n' "$resume" | sed -E 's/.*Skipped: ([0-9]+).*/\1/')" ;;
  "Ran "*)
    total="$(printf '%s\n' "$resume" | sed -E 's/^Ran ([0-9]+).*/\1/')"; echecs=0
    case "$resume" in
      *skipped=*) ignores="$(printf '%s\n' "$resume" | sed -E 's/.*skipped=([0-9]+).*/\1/')" ;;
      *"; OK") ignores=0 ;;
    esac ;;
  "TESTS OK : "*)
    total="$(printf '%s\n' "$resume" | sed -E 's/^TESTS OK : ([0-9]+).*/\1/')"; echecs=0; ignores=0 ;; # cette suite n'ignore aucun cas
  *passed*|*failed*)
    p_="$(nombre_avant passed)"; echecs="$(nombre_avant failed)"; echecs="${echecs:-0}"
    ignores="$(nombre_avant skipped)"; ignores="${ignores:-0}"
    total=$(( ${p_:-0} + echecs + ignores )) ;;
esac

if [ -z "$ignores" ]; then
  [ "$autorises" = "inconnu" ] || ajoute "nombre de tests ignorés illisible dans le résumé (« ${resume:-rien} »), aucun succès annoncé"
elif [ "$total" -eq 0 ]; then
  ajoute "aucun test exécuté"
elif [ "$ignores" -gt 0 ]; then
  case "$autorises" in
    ''|inconnu) ajoute "$ignores test(s) ignoré(s), non autorisé(s) par FIN_ISSUE_IGNORES_AUTORISES" ;;
    *) [ "$ignores" -le "$autorises" ] || ajoute "$ignores test(s) ignoré(s), $autorises autorisé(s)" ;;
  esac
fi

[ "$(git rev-parse HEAD)" = "$commit" ] || ajoute "HEAD a changé pendant la vérification"
[ -z "$(git status --porcelain)" ] || ajoute "arbre Git modifié pendant la vérification"
[ -z "$raisons" ] || echec "$raisons"

if [ -z "$ignores" ]; then
  echo "FIN-ISSUE OK $id $court : tests non comptés, ignorés inconnus (autorisé)"
elif [ "$ignores" -gt 1 ]; then
  echo "FIN-ISSUE OK $id $court : $total tests, $echecs échec, $ignores ignorés (autorisés)"
elif [ "$ignores" -eq 1 ]; then
  echo "FIN-ISSUE OK $id $court : $total tests, $echecs échec, 1 ignoré (autorisé)"
else
  echo "FIN-ISSUE OK $id $court : $total tests, $echecs échec, 0 ignoré"
fi
