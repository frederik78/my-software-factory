#!/usr/bin/env bash
# Traçabilité critères -> tests : liste les critères d'acceptation (CA-xx / CS-xx) d'une issue qu'aucune déclaration de test ne nomme.
# Une issue à `criteres: []` est une erreur, sauf si son champ `criteres_justification:` est rempli (refactorisation sans changement de comportement) : `OK … aucun critère, justifié`.
#
# Un critère est « couvert » si son identifiant figure dans le nom ou le titre d'une déclaration de test, quelle que soit la forme :
# CA-10, ca10, ca_10, "CA 10" (insensible à la casse, zéros de tête ignorés, CA-1 ne se confond pas avec CA-10).
# Déclarations reconnues (une seule ligne, commençant par la déclaration, éventuellement précédée d'annotations et de modificateurs) :
#   .java .kt          class Ca10Test ; void ca10_x( ; fun ca10_x( ; fun `CA-10 x`( ; @DisplayName("CA-10 x")
#   .py                def test_ca10 ; async def test_ca10 ; class TestCa10
#   .js .jsx .mjs .cjs .ts .tsx .mts .cts
#                      it(, test(, describe( et leurs formes .each, .only, .concurrent, avec leur titre entre ' " ou `
# Rien d'autre ne compte : commentaire, docstring, message d'assertion, chaîne quelconque, autre type de fichier.
# Limites assumées : préférer un faux MANQUE (visible, corrigé en renommant le test) à un faux OK (silencieux).
#   Le corps n'est pas lu : `describe('CA-10', () => {})` vide répond OK.
#   Faux MANQUE : titre sur la ligne suivante, autre langage. Faux OK : déclaration recopiée dans un bloc de commentaire ou une
#   docstring, sans « * » en tête de ligne ; classe auxiliaire ou méthode Java non privée qui porte l'identifiant sans être un test ; test désactivé.
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

# noms_de_tests : un nom ou un titre de test par ligne. Chaque motif s'ancre en début de ligne : un commentaire ne peut donc pas correspondre.
# sed plutôt que grep pour ne garder que le nom : le reste de la ligne (message d'assertion, commentaire final) ne compte pas.
# Crochets écrits }{ et non {} : GNU find refuse un second {} dans les arguments de -exec ... +.
# LC_ALL=C : un octet hors UTF-8 dans un fichier de tests ferait échouer sed sous macOS ; les noms acceptent les lettres accentuées (Java, Kotlin, Python). Le préfixe test est retiré pour lire TestCa10 et testCa10.
noms_de_tests() {
  local jvm='^[[:space:]]*((@[A-Za-z0-9_.]+(\([^)]*\))?|public|protected|internal|static|final|abstract|open|sealed|override|suspend|data|inner)[[:space:]]+)*'
  local node='^[[:space:]]*(await[[:space:]]+)?((it|test|describe)(\.(describe|only|concurrent|parallel|serial))*(\.each(\([^()]*\)|`[^`]*`))?|\]\))\('
  {
    find "$tests" -type f \( -name '*.java' -o -name '*.kt' \) -exec env LC_ALL=C sed -nE \
      -e h \
      -e "s/${jvm}class[[:space:]]+([^[:space:]()}{:<]+).*/\\4/p" -e g \
      -e "s/${jvm}(void|fun)[[:space:]]+([^[:space:]()}{.\`]+)[[:space:]]*\\(.*/\\5/p" -e g \
      -e "s/${jvm}fun[[:space:]]+\`([^\`]*)\`.*/\\4/p" -e g \
      -e "s/${jvm}@DisplayName\\(\"([^\"]*)\".*/\\4/p" {} +
    find "$tests" -type f -name '*.py' -exec env LC_ALL=C sed -nE \
      -e 's/^[[:space:]]*(async[[:space:]]+)?def[[:space:]]+(test[^[:space:](:]*).*/\2/p' \
      -e 's/^[[:space:]]*class[[:space:]]+(Test[^[:space:](:]*).*/\1/p' {} +
    find "$tests" -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \
      -o -name '*.ts' -o -name '*.tsx' -o -name '*.mts' -o -name '*.cts' \) -exec env LC_ALL=C sed -nE \
      -e "s/${node}'([^']*)'.*/\\8/p" \
      -e "s/${node}\"([^\"]*)\".*/\\8/p" \
      -e "s/${node}\`([^\`]*)\`.*/\\8/p" {} +
  } | LC_ALL=C sed -E 's/^[Tt]est//'
}

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

noms="$(noms_de_tests)"
echec=0
for issue in "${fichiers_issues[@]}"; do
  criteres=()
  while IFS= read -r c; do [ -n "$c" ] && criteres+=("$c"); done < <(issue_liste "$issue" criteres)
  if [ "${#criteres[@]}" -eq 0 ] && [ -n "$(issue_champ "$issue" criteres_justification | tr -d '[:space:]')" ]; then
    # Issue sans critère du PRD (refactorisation sans changement de comportement) : légitime quand l'en-tête en donne la raison.
    echo "OK     $(basename "$issue"): aucun critère, justifié (criteres_justification)"
    continue
  fi
  if [ "${#criteres[@]}" -eq 0 ]; then
    echo "ERREUR $(basename "$issue"): aucun critère déclaré (champ « criteres » vide ou illisible)"
    echec=1
    continue
  fi
  sans=()
  for c in "${criteres[@]}"; do
    if ! grep -iEq "$(critere_motif "$c")" <<< "$noms"; then
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
