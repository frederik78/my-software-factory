#!/usr/bin/env bash
# Traçabilité critères -> tests : liste les critères d'acceptation (CA-xx / CS-xx) d'une issue qu'aucun test ne mentionne.
#
# Un critère est « couvert » si le nom d'une classe, d'une méthode ou un @DisplayName de test contient son identifiant, quelle que soit la forme :
# CA-10, ca10, ca_10, "CA 10" (insensible à la casse, zéros de tête ignorés, CA-1 ne se confond pas avec CA-10).
#
# Usage : scripts/criteres-sans-test.sh <issue>        <issue> = chemin du fichier, ou id (ex. 001-03)
#         scripts/criteres-sans-test.sh --tous         toutes les issues dont le statut n'est pas « À faire »
# Variable : DOSSIER_TESTS (défaut : le premier dossier existant parmi src/test, tests, test)
# Une issue sans AUCUN critère est une erreur (jamais un « tout couvert » silencieux).
# Code de sortie : 0 si tout est couvert, 1 sinon, 64 en cas d'erreur d'usage.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"
tests="${DOSSIER_TESTS:-}"
if [ -z "$tests" ]; then
  for d in src/test tests test; do [ -d "$d" ] && { tests="$d"; break; }; done
  tests="${tests:-src/test}"
fi

if [ ! -d "$tests" ]; then
  echo "Dossier de tests introuvable : $tests" >&2
  exit 64
fi

fichiers_issues=()
case "${1:-}" in
  "") echo "Usage : $0 <issue|--tous>" >&2; exit 64 ;;
  --tous)
    while IFS= read -r f; do
      [ "$(issue_champ "$f" statut)" = "À faire" ] || fichiers_issues+=("$f")
    done < <(issue_fichiers) ;;
  *)
    if [ -f "$1" ]; then
      fichiers_issues+=("$1")
    else
      while IFS= read -r f; do fichiers_issues+=("$f"); done < <(issue_fichiers "$1")
    fi ;;
esac

if [ "${#fichiers_issues[@]}" -eq 0 ]; then
  echo "Aucune issue trouvée pour : ${1:-}" >&2
  exit 64
fi

echec=0
for issue in "${fichiers_issues[@]}"; do
  criteres=()
  while IFS= read -r c; do [ -n "$c" ] && criteres+=("$c"); done < <(issue_liste "$issue" criteres)
  if [ "${#criteres[@]}" -eq 0 ]; then
    echo "ERREUR $(basename "$issue"): aucun critère déclaré (champ « criteres » vide ou illisible)"
    echec=1
    continue
  fi
  sans=()
  for c in "${criteres[@]}"; do
    if ! grep -rIiEq "$(critere_motif "$c")" "$tests"; then
      sans+=("$c")
    fi
  done
  if [ "${#sans[@]}" -eq 0 ]; then
    echo "OK     $(basename "$issue"): ${#criteres[@]} critère(s), tous couverts"
  else
    echec=1
    echo "MANQUE $(basename "$issue"): ${#sans[@]}/${#criteres[@]} sans test : ${sans[*]}"
  fi
done

exit "$echec"
