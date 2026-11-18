#!/usr/bin/env bash
# Traçabilité critères -> tests : liste les critères d'acceptation (CA-xx / CS-xx) d'une issue qu'aucune déclaration de test ne nomme.
# Une issue à `criteres: []` est une erreur, sauf si son champ `criteres_justification:` est rempli (refactorisation sans changement de comportement) : `OK … aucun critère, justifié`.
#
# Un critère est « couvert » si son identifiant figure dans le nom ou le titre d'une déclaration de test, quelle que soit la forme :
# CA-10, ca10, ca_10, "CA 10" (insensible à la casse, zéros de tête ignorés, CA-1 ne se confond pas avec CA-10).
# Déclarations reconnues (une seule ligne, commençant par la déclaration, éventuellement précédée d'annotations et de modificateurs) :
#   .java .kt          class Ca10Test ; void ca10_x( ; fun ca10_x( ; fun `CA-10 x`( ; @DisplayName("CA-10 x")
#   .py                def test_ca10 ; async def test_ca10 ; class TestCa10
#   .sh                verifier "ca10_x" … ; verdict_cas "cs01_x" … (appel en début de ligne, premier argument entre guillemets " ou ')
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
# Configuration (lib-config.sh, jamais exécutée) : TESTS_BASH_FONCTIONS = noms des fonctions de test bash, séparés par des espaces (défaut : verifier verdict_cas).
#   Elle REMPLACE le défaut ; validée avant toute lecture des tests (invalide : message sur stderr, code 64).
# Une issue sans AUCUN critère est une erreur (jamais un « tout couvert » silencieux).
# Code de sortie : 0 si tout est couvert, 1 sinon, 64 en cas d'erreur d'usage.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"
# shellcheck source=lib-config.sh
. "$(dirname "$0")/lib-config.sh"
# Fonctions de test bash : validées d'abord (RG-12). Les noms ne contiennent que [A-Za-z0-9_] : l'alternance construite ici est littérale.
noms_fonctions="$(config_tests_bash_fonctions)" || exit 64
fonctions_bash="$(printf '%s' "$noms_fonctions" | tr '\n' '|')"
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

# Programme awk : copie les fichiers reçus sans les lignes d'un document ici (<<MOT, <<'MOT', <<"MOT", <<\MOT, <<$'MOT', <<-MOT : de la ligne qui suit
# l'ouverture jusqu'à la ligne du délimiteur final incluse ; pour <<-, le délimiteur peut être précédé de tabulations). La ligne
# d'ouverture est gardée : elle peut être un vrai appel. Lecture seule, rien n'est évalué. CRLF toléré. <<< (chaîne ici) n'ouvre rien.
read -r -d '' sans_documents_ici <<'AWK'
# dans_chaine(texte) : vrai si la fin de texte se trouve à l'intérieur d'une chaîne entre guillemets " ou ' non refermée.
function dans_chaine(texte,    i, c, q) {
  q = ""
  for (i = 1; i <= length(texte); i++) {
    c = substr(texte, i, 1)
    if (q == "" && (c == "\"" || c == "'")) q = c
    else if (q == "\"" && c == "\\") i++
    else if (c == q) q = ""
  }
  return q != ""
}
FNR == 1 { nb = 0; cur = 1 }
{ ligne = $0; sub(/\r$/, "", ligne) }
cur <= nb {
  if (tabs[cur]) sub(/^\t+/, "", ligne)
  if (ligne == delim[cur]) cur++
  next
}
{
  print
  # Tous les documents ouverts sur la ligne (<<A <<B) sont mis en file et se referment dans l'ordre.
  # Un << dans une chaîne entre guillemets (titre d'un test, par exemple) n'ouvre rien, sauf si la ligne contient $( ou ` avant lui.
  nb = 0; cur = 1; reste = ligne; decalage = 0
  while (match(reste, /(^|[^<])<<-?[ \t]*(\\|\$?["'])?[A-Za-z_][A-Za-z0-9_]*["']?/)) {
    mot = substr(reste, RSTART, RLENGTH)
    fin = RSTART + RLENGTH
    avant = substr(ligne, 1, decalage + RSTART)
    # Dans le doute on ouvre : un $( ou une apostrophe inverse avant le << peut faire de ce << du code (out="$(cat <<EOF").
    en_chaine = dans_chaine(avant) && avant !~ /\$\(|`/
    decalage += fin - 1
    reste = substr(reste, fin)
    if (en_chaine) continue
    sub(/^[^<]*<</, "", mot)
    nb++
    tabs[nb] = (substr(mot, 1, 1) == "-")
    gsub(/^-?[ \t]*(\\|\$?["'])?|["']$/, "", mot)
    delim[nb] = mot
  }
}
AWK

# noms_de_tests_bash : le premier argument de chaque appel `fonction "texte …"` en début de ligne des .sh, hors documents ici, un par ligne.
# Seul ce premier argument entre guillemets (" ou ') compte. Un commentaire, la ligne de définition `verifier() {`, un argument sans
# guillemets, un appel en milieu de ligne ne correspondent pas. Lecture seule : le contenu n'est jamais évalué ni exécuté.
noms_de_tests_bash() {
  find "$tests" -type f -name '*.sh' -exec env LC_ALL=C awk "$sans_documents_ici" {} + | LC_ALL=C sed -nE \
    -e "s/^[[:space:]]*(${fonctions_bash})[[:space:]]+\"([^\"]*)\".*/\2/p" \
    -e "s/^[[:space:]]*(${fonctions_bash})[[:space:]]+'([^']*)'.*/\2/p"
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
noms_bash="$(noms_de_tests_bash)"
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
    # Autres langages : l'identifiant figure n'importe où dans le nom ; bash : il COMMENCE le premier argument (RG-03).
    if ! grep -iEq "$(critere_motif "$c")" <<< "$noms" && ! grep -iEq "$(critere_motif_debut "$c")" <<< "$noms_bash"; then
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
