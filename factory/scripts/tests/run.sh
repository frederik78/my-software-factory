#!/usr/bin/env bash
# Tests des scripts de la factory (sans dépendance : bash, git, rsync). À lancer depuis n'importe où :
#     factory/scripts/tests/run.sh
# Chaque cas travaille dans un dépôt jetable ; rien n'est écrit dans le dépôt courant. Compatible bash 3.2 (macOS).
set -uo pipefail
# Isolement de l'environnement appelant : verify-clean.sh donne la priorité à COMMANDE_VERIFY, et les bouchons lisent STUB_CODE ;
# hérités (par exemple quand cette suite est elle-même lancée par verify-clean.sh avec COMMANDE_VERIFY), ils fausseraient les cas.
unset COMMANDE_VERIFY STUB_CODE
# Idem pour la configuration de la factory (lue par config-factory.sh et notifier.sh) : une valeur personnelle ne doit pas fausser les cas.
unset FACTORY_AGENT_MODELE FACTORY_AGENT_EFFORT FACTORY_MAX_ITERATIONS_REVUE FACTORY_NOTIFICATION_COMMANDE FACTORY_NOTIFICATION_DESTINATAIRE FACTORY_NOTIFICATION_EXPEDITEUR

ici="$(cd "$(dirname "$0")" && pwd)"
factory="$(cd "$ici/../.." && pwd)"
racine_tmp="$(mktemp -d "${TMPDIR:-/tmp}/factory-tests.XXXXXX")"
trap 'rm -rf "$racine_tmp"' EXIT

total=0; echecs=0
ok()  { total=$((total + 1)); printf '  ok   %s\n' "$1"; }
ko()  { total=$((total + 1)); echecs=$((echecs + 1)); printf '  ECHEC %s\n        %s\n' "$1" "${2:-}"; }
# verifier <description> <code attendu> <sortie attendue (motif grep -E, vide = ignoré)> <commande...>
verifier() {
  local desc="$1" attendu="$2" motif="$3"; shift 3
  local sortie code
  sortie="$("$@" 2>&1)"; code=$?
  if [ "$code" -ne "$attendu" ]; then ko "$desc" "code $code au lieu de $attendu ; sortie : $(printf '%s' "$sortie" | head -5 | tr '\n' '|')"; return; fi
  if [ -n "$motif" ] && ! printf '%s' "$sortie" | grep -Eq "$motif"; then ko "$desc" "motif « $motif » absent ; sortie : $(printf '%s' "$sortie" | head -5 | tr '\n' '|')"; return; fi
  ok "$desc"
}
# verifier_exact <description> <code attendu> <sortie exacte attendue (stdout et stderr mêlés)> <commande...>
verifier_exact() {
  local desc="$1" attendu="$2" texte="$3"; shift 3
  local sortie code
  sortie="$("$@" 2>&1)"; code=$?
  if [ "$code" -ne "$attendu" ] || [ "$sortie" != "$texte" ]; then ko "$desc" "code $code (attendu $attendu) ; sortie : $(printf '%s' "$sortie" | head -5 | tr '\n' '|')"; return; fi
  ok "$desc"
}

# Vérifications de documentation sur ce dépôt (racine de la factory) : elles lisent le dépôt par lire_depot / chercher_depot.
# Dépôt git : lecture depuis HEAD, pour que la suite ne dépende pas de l'arbre de travail (un agent qui modifie un fichier ou change
# de branche pendant la suite ne la fait plus échouer au hasard). Conséquence voulue : une modification NON COMMITÉE d'un fichier
# n'est pas vue par ces vérifications ; commitez avant de lancer la suite. Hors dépôt git (copie de verify-clean.sh, sans .git) :
# lecture des fichiers de la copie.
depot="$(cd "$factory/.." && pwd)"
depot_git() { # depot_git <racine> : vrai si <racine> est la racine d'un dépôt git qui a un HEAD
  local haut; haut="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || return 1
  [ "$(cd "$haut" && pwd -P)" = "$(cd "$1" && pwd -P)" ] && git -C "$1" rev-parse -q --verify HEAD >/dev/null
}
est_depot_factory() { [ -f "$1/.factory-depot" ]; } # le marqueur est à la racine, hors de factory/ : un projet ne le reçoit jamais
lire_depot() { # lire_depot <racine> <chemin relatif> : contenu du fichier (HEAD ou fichier, voir ci-dessus)
  if depot_git "$1"; then git -C "$1" show "HEAD:$2" 2>/dev/null; else cat "$1/$2" 2>/dev/null; fi
  return 0
}
chercher_depot() { # chercher_depot <racine> [-i] <motif grep -E> [chemins exclus (motifs de chemin)...] : lignes « fichier:ligne:texte »
  local racine="$1" casse="" motif x; shift
  if [ "$1" = "-i" ]; then casse="-i"; shift; fi
  motif="$1"; shift
  if depot_git "$racine"; then
    local specs=(.); for x in "$@"; do specs+=(":!$x"); done
    git -C "$racine" grep -n -I -E $casse -e "$motif" HEAD -- "${specs[@]}" 2>/dev/null
  else
    (cd "$racine" && find . -type f ! -path './.git/*' | sed 's|^\./||' | while IFS= read -r f; do
      for x in "$@"; do case "$f" in $x) continue 2 ;; esac; done
      grep -n -I -E $casse -e "$motif" "$f" 2>/dev/null | awk -v f="$f" '{ print f ":" $0 }'
    done)
  fi
  return 0
}

# Dépôt jetable avec les scripts liés comme dans un vrai projet.
nouveau_projet() {
  local d; d="$(mktemp -d "$racine_tmp/p.XXXXXX")"
  mkdir -p "$d/factory" "$d/scripts" "$d/docs/issues" "$d/src/test"
  cp -R "$factory/scripts" "$d/factory/scripts"; rm -rf "$d/factory/scripts/tests"
  local s; for s in "$d"/factory/scripts/*.sh; do ln -s "../factory/scripts/$(basename "$s")" "$d/scripts/$(basename "$s")"; done
  printf '%s' "$d"
}
issue_id() { # issue_id <projet> <id> <statut> <prd> <criteres> <depend_de>
  printf -- '---\nid: %s\ntitre: T%s\nprd: %s\nstatut: %s\ndepend_de: %s\ncriteres: %s\nbranche:\n---\n' "$2" "$2" "$4" "$3" "$6" "$5" > "$1/docs/issues/$2-x.md"
}

echo "criteres-sans-test.sh"
p="$(nouveau_projet)"; cd "$p" || exit 1
printf '@Test void ca10_x() {}\n@Test void cs07_y() {}\n' > src/test/A.java
issue_id "$p" 001-01 "En cours" docs/prd/001-m.md "[CA-10, CS-07]" "[]"
verifier "liste en ligne couverte" 0 "OK .*2 critère" scripts/criteres-sans-test.sh 001-01
issue_id "$p" 001-02 "En cours" docs/prd/001-m.md "
  - CA-10
  - \"CS-07\"" "[]"
verifier "liste YAML sur plusieurs lignes lue (pas de faux OK à 0)" 0 "OK .*2 critère" scripts/criteres-sans-test.sh 001-02
issue_id "$p" 001-03 "En cours" docs/prd/001-m.md "[]" "[]"
verifier "aucun critère = erreur, jamais un faux OK" 1 "ERREUR .*aucun critère" scripts/criteres-sans-test.sh 001-03
issue_id "$p" 001-04 "En cours" docs/prd/001-m.md "[CA-1, CA-11]" "[]"
verifier "CA-1 ne se confond pas avec CA-10 / CA-11 sans test" 1 "MANQUE .*2/2" scripts/criteres-sans-test.sh 001-04
issue_id "$p" 001-05 "À faire" docs/prd/001-m.md "[CA-99]" "[]"
verifier "--tous ignore les issues « À faire »" 1 "" scripts/criteres-sans-test.sh --tous
out="$(scripts/criteres-sans-test.sh --tous 2>&1)"; printf '%s' "$out" | grep -q "001-05" && ko "--tous ne liste pas 001-05" "$out" || ok "--tous ne liste pas 001-05"
verifier "sans argument = usage (64)" 64 "Usage" scripts/criteres-sans-test.sh
verifier "issue inconnue = 64" 64 "Aucune issue" scripts/criteres-sans-test.sh 999
rm -rf src/test; mkdir tests; printf 'def test_ca10_x():\n    pass\ndef test_cs07_y():\n    pass\n' > tests/t.py
verifier "dossier de tests détecté automatiquement (tests/)" 0 "OK .*2 critère" scripts/criteres-sans-test.sh 001-01
rm -rf tests; verifier "dossier de tests absent = 64" 64 "introuvable" scripts/criteres-sans-test.sh 001-01

echo "criteres-sans-test.sh : seule une déclaration de test couvre un critère"
p="$(nouveau_projet)"; cd "$p" || exit 1
issue_id "$p" 001-01 "En cours" docs/prd/001-m.md "[CA-10]" "[]"
# critere_fichier <description> <code attendu> <fichier de tests> : le contenu du fichier vient de l'entrée standard.
critere_fichier() {
  rm -rf src/test; mkdir -p "$(dirname "src/test/$3")"; cat > "src/test/$3"
  if [ "$2" -eq 0 ]; then verifier "$1" 0 "OK .*1 critère" scripts/criteres-sans-test.sh 001-01
  else verifier "$1" 1 "MANQUE .*1/1 sans test : CA-10" scripts/criteres-sans-test.sh 001-01; fi
}
critere_fichier "mention : commentaire //" 1 A.java <<'EOF'
// CA-10
@Test void autre() {}
EOF
critere_fichier "mention : Javadoc /** */" 1 A.java <<'EOF'
/** Couvre ca10_x, voir CA-10. */
class A {
  /**
   * CA-10
   * void ca10_x() {
   */
  @Test void autre() {}
}
EOF
critere_fichier "mention : commentaire #" 1 t.py <<'EOF'
# CA-10
def test_autre():
    pass
EOF
critere_fichier "mention : docstring Python sur plusieurs lignes" 1 t.py <<'EOF'
def test_autre():
    """Vérifie un cas.

    CA-10 : ca10_x
    """
EOF
critere_fichier "mention : message d'assertion Java" 1 A.java <<'EOF'
@Test void autre() { assertEquals(1, x, "CA-10"); }
EOF
critere_fichier "mention : message d'assertion Python" 1 t.py <<'EOF'
def test_autre():
    assert x == 1, "CA-10"
EOF
critere_fichier "mention : message d'assertion sur la ligne d'un test Node" 1 a.test.js <<'EOF'
it('autre', () => expect(x, 'CA-10').toBe(1));
EOF
critere_fichier "mention : chaîne de test ordinaire" 1 a.test.ts <<'EOF'
const id = "CA-10";
foo('ca10');
EOF
critere_fichier "mention : chaîne qui contient une déclaration" 1 A.java <<'EOF'
String s = "void ca10_x() {";
log("@DisplayName(\"CA-10\")");
EOF
critere_fichier "mention : commentaire en fin de déclaration" 1 A.java <<'EOF'
@Test void autre() {} // CA-10
EOF
critere_fichier "mention : fichier .md du dossier de tests" 1 notes.md <<'EOF'
void ca10_x() {
def test_ca10():
it('CA-10', x)
EOF
critere_fichier "mention : fichier .json du dossier de tests" 1 data.json <<'EOF'
{ "critere": "CA-10", "test": "void ca10_x(" }
EOF
critere_fichier "ligne commentée : // void ca10_x() {" 1 A.java <<'EOF'
// void ca10_x() {
EOF
critere_fichier "ligne commentée : /* class Ca10Test" 1 A.java <<'EOF'
/* class Ca10Test {
EOF
critere_fichier "ligne commentée : * @DisplayName" 1 A.java <<'EOF'
 * @DisplayName("CA-10")
EOF
critere_fichier "ligne commentée : # def test_ca10" 1 t.py <<'EOF'
    # def test_ca10():
EOF
critere_fichier "ligne commentée : // it('CA-10')" 1 a.test.js <<'EOF'
  // it('CA-10', () => {});
EOF
critere_fichier "non déclaration : méthode Java privée (auxiliaire, jamais un test)" 1 A.java <<'EOF'
private void ca10_x() {}
EOF
critere_fichier "non déclaration : fonction Python sans préfixe test" 1 t.py <<'EOF'
def ca10_aide():
    pass
EOF
critere_fichier "non déclaration : classe Python sans préfixe Test" 1 t.py <<'EOF'
class Ca10Aide:
    pass
EOF
critere_fichier "non déclaration : it.todo et it.skip" 1 a.test.js <<'EOF'
it.todo('CA-10');
it.skip('CA-10', () => {});
EOF
critere_fichier "déclaration : classe Java" 0 Ca10Test.java <<'EOF'
public final class Ca10Test {
EOF
critere_fichier "déclaration : méthode Java" 0 A.java <<'EOF'
    void ca10_x() {
EOF
critere_fichier "déclaration : méthode Java annotée, sur une ligne" 0 A.java <<'EOF'
    @Test @Timeout(value = 5) public void CA_10_x() throws Exception {
EOF
critere_fichier "déclaration : @DisplayName" 0 A.java <<'EOF'
    @DisplayName("CA-10 : la somme") 
EOF
critere_fichier "déclaration : @DisplayName devant la méthode" 0 A.java <<'EOF'
    @DisplayName("CA 10") @Test void autre() {}
EOF
critere_fichier "déclaration : méthode après un @DisplayName sur la même ligne" 0 A.java <<'EOF'
    @DisplayName("autre") @Test void ca10_x() {}
EOF
critere_fichier "déclaration : classe Kotlin" 0 A.kt <<'EOF'
internal class Ca10Test {
EOF
critere_fichier "déclaration : fonction Kotlin" 0 A.kt <<'EOF'
    @Test fun ca10_x() = runTest {
EOF
critere_fichier "déclaration : fonction Kotlin entre backticks" 0 A.kt <<'EOF'
    fun `CA-10 la somme est juste`() {
EOF
critere_fichier "déclaration : @DisplayName en Kotlin" 0 A.kt <<'EOF'
    @DisplayName("ca10 la somme")
EOF
critere_fichier "déclaration : def test_ Python" 0 t.py <<'EOF'
def test_ca10_x():
EOF
critere_fichier "déclaration : async def test_ Python indenté" 0 t.py <<'EOF'
    async def test_ca_10(self):
EOF
critere_fichier "déclaration : def testCa10 Python" 0 t.py <<'EOF'
    def testCa10(self):
EOF
critere_fichier "déclaration : class TestCa10 Python" 0 t.py <<'EOF'
class TestCa10:
EOF
critere_fichier "déclaration : class TestCa10 Python avec parent" 0 t.py <<'EOF'
class TestCa10Somme(unittest.TestCase):
EOF
critere_fichier "déclaration : it, guillemets simples" 0 a.test.js <<'EOF'
  it('CA-10 : la somme', () => {});
EOF
critere_fichier "déclaration : test, guillemets doubles" 0 a.test.ts <<'EOF'
test("ca10 la somme", async () => {});
EOF
critere_fichier "déclaration : describe, backticks" 0 a.spec.mjs <<'EOF'
describe(`CA 10`, () => {});
EOF
critere_fichier "déclaration : it.each sur une ligne" 0 a.test.tsx <<'EOF'
it.each([1, 2])('CA-10 %s', (n) => {});
EOF
critere_fichier "déclaration : test.each, table entre backticks" 0 a.test.js <<'EOF'
test.each`a${1}`("CA-10 $a", () => {});
EOF
critere_fichier "déclaration : it.each sur plusieurs lignes" 0 a.test.js <<'EOF'
it.each([
  [1],
])(`CA-10 %s`, (n) => {});
EOF
critere_fichier "déclaration : test.describe, await" 0 a.spec.ts <<'EOF'
await test.describe('CA-10', () => {});
EOF
critere_fichier "déclaration : méthode Java au nom accentué" 0 A.java <<'EOF'
    void ca10_leJsonDuReçuEstComplet() {
EOF
critere_fichier "déclaration : classe Java au nom accentué" 0 A.java <<'EOF'
class ReçuTest_ca10 extends Base {
EOF
critere_fichier "déclaration : fonction Python au nom accentué" 0 t.py <<'EOF'
def test_reçu_ca10():
EOF
critere_fichier "motif : zéros de tête ignorés (ca010)" 0 A.java <<'EOF'
void ca010_x() {
EOF
critere_fichier "motif : CA-1 n'est pas CA-10" 1 A.java <<'EOF'
void ca1_x() {
void ca100_x() {
void xca10_x() {
EOF

echo "etat-issues.sh"
p="$(nouveau_projet)"; cd "$p" || exit 1
issue_id "$p" 001-01 "Fait" docs/prd/001-m.md "[CA-01]" "[]"
issue_id "$p" 001-02 "À faire" docs/prd/001-m.md "[CA-02]" "[001-01]"
issue_id "$p" 001-03 "À faire" docs/prd/001-m.md "[CA-03]" "
  - 001-02"
verifier "tableau Markdown" 0 "\| 001-02 \| T001-02 \| À faire \| 001-01 \|" scripts/etat-issues.sh
verifier "filtre par statut" 0 "001-01" scripts/etat-issues.sh --statut Fait
verifier "prochaine issue prête = 001-02" 0 "^001-02$" scripts/etat-issues.sh --prochaine
issue_id "$p" 001-02 "Fait" docs/prd/001-m.md "[CA-02]" "[001-01]"
verifier "puis 001-03 (dépendance en liste multi-lignes)" 0 "^001-03$" scripts/etat-issues.sh --prochaine
issue_id "$p" 001-03 "Fait" docs/prd/001-m.md "[CA-03]" "[001-02]"
verifier "plus aucune issue prête = code 1" 1 "" scripts/etat-issues.sh --prochaine

echo "dashboard.sh"
p="$(nouveau_projet)"; cd "$p" || exit 1
cat > backlog.md <<'EOF'
# Backlog
## Besoins fonctionnels

| ID | Besoin | Priorité | Statut | PRD | Décisions |
|----|--------|----------|--------|-----|-----------|
| F-01 | Export <script>alert(1)</script> & "co" | P1 | Fait | docs/prd/001-m.md | |
| F-02 | Import des données | P2 | En cours | | |
| F-03 | | P1 | À faire | | |
| F-04 | Recherche | P3 | À faire | | |

## Besoins non fonctionnels

| ID | Besoin | Statut |
|----|--------|--------|
| NF-01 | Ne doit pas apparaître | À faire |
EOF
issue_id "$p" 001-01 "Fait" docs/prd/001-m.md "[CA-01]" "[]"
issue_id "$p" 001-02 "À faire" docs/prd/001-m.md "[CA-02]" "[001-01]"
issue_id "$p" 001-03 "À faire" docs/prd/001-m.md "[CA-03]" "[001-02]"
verifier "génère dashboard.html à la racine" 0 "dashboard.html" scripts/dashboard.sh
[ -f dashboard.html ] && ok "le fichier HTML existe" || ko "le fichier HTML existe"
grep -qx '<title>Dashboard</title>' dashboard.html && grep -qx '<h1>Dashboard</h1>' dashboard.html && ok "titre de la page : « Dashboard »" || ko "titre Dashboard" "$(grep -n '<title>\|<h1>' dashboard.html)"
grep -q '<meta http-equiv="refresh" content="30">' dashboard.html && ok "rafraîchissement automatique à 30 s par défaut" || ko "rafraîchissement par défaut"
grep -q 'F-02' dashboard.html && grep -q 'Import des données' dashboard.html && ok "les besoins du backlog sont affichés" || ko "besoins affichés"
! grep -q 'F-03' dashboard.html && ok "ligne vide (ID sans besoin) ignorée" || ko "ligne vide ignorée"
! grep -q 'NF-01' dashboard.html && ok "besoins non fonctionnels non listés" || ko "besoins non fonctionnels"
grep -q '001-02' dashboard.html && grep -q 'T001-02' dashboard.html && ok "les issues sont affichées" || ko "issues affichées"
grep -q 'Prochaine issue prête : <strong>001-02</strong>' dashboard.html && ok "prochaine issue prête = 001-02" || ko "prochaine issue prête"
! grep -q '<script' dashboard.html && grep -q '&lt;script&gt;alert(1)&lt;/script&gt; &amp; &quot;co&quot;' dashboard.html && ok "cs01_ texte du backlog échappé (pas de <script>)" || ko "cs01_ échappement du backlog" "$(grep -n 'script' dashboard.html | head -3)"
# Kanban : en-têtes « Statut (n) » d'une section, dans l'ordre de la page, séparés par « | ».
colonnes() { awk -v id="$1" 'index($0, "<section id=\"" id "\"") { dedans = 1 } dedans && /<\/section>/ { dedans = 0 } dedans && /<h3/ { gsub(/<[^>]*>/, ""); printf "%s|", $0 }' dashboard.html; }
carte() { grep -F "<strong>$1</strong>" dashboard.html | grep -F 'class="carte'; } # carte <id> : la ligne de la carte
[ "$(colonnes besoins)" = "À faire (1)|En clarification (0)|Spécifié (0)|En cours (1)|En revue (0)|Fait (1)|" ] && ok "kanban besoins : une colonne par statut du backlog, dans l'ordre, avec le nombre (pas de (autre) inutile)" || ko "colonnes des besoins" "$(colonnes besoins)"
[ "$(colonnes issues)" = "À faire (2)|En cours (0)|En revue (0)|Fait (1)|" ] && ok "kanban issues : une colonne par statut du cycle des issues, dans l'ordre (pas de (autre) inutile)" || ko "colonnes des issues" "$(colonnes issues)"
grep -q '<h3 class="statut-fait">Fait (1)</h3>' dashboard.html && grep -q '<h3 class="statut-afaire">À faire (2)</h3>' dashboard.html && ok "en-tête de colonne coloré selon le statut" || ko "couleur des en-têtes" "$(grep -n '<h3' dashboard.html | head -5)"
[ "$(carte F-01)" = '<div class="carte"><strong>F-01</strong> <span class="titre">Export &lt;script&gt;alert(1)&lt;/script&gt; &amp; &quot;co&quot;</span><span class="detail">P1</span><span class="detail">PRD : docs/prd/001-m.md</span></div>' ] && ok "carte de besoin : ID, libellé, priorité, PRD en texte" || ko "carte de besoin" "$(carte F-01)"
[ "$(carte F-02)" = '<div class="carte"><strong>F-02</strong> <span class="titre">Import des données</span><span class="detail">P2</span></div>' ] && ok "carte de besoin sans PRD : pas de mention PRD" || ko "carte de besoin sans PRD" "$(carte F-02)"
carte 001-02 | grep -q 'class="carte prochaine".*<span class="marqueur marqueur-prochaine">prochaine</span>' && ! carte 001-02 | grep -q 'bloquée' && ok "marqueur « prochaine » sur l'issue de etat-issues.sh --prochaine (dépendance Fait : pas bloquée)" || ko "marqueur prochaine" "$(carte 001-02)"
carte 001-03 | grep -q 'class="carte bloquee".*<span class="marqueur marqueur-bloquee">bloquée</span>' && ! carte 001-03 | grep -q '>prochaine<' && ok "marqueur « bloquée » sur une issue À faire dont une dépendance n'est pas Fait" || ko "marqueur bloquée" "$(carte 001-03)"
[ "$(carte 001-01)" = '<div class="carte"><strong>001-01</strong> <span class="titre">T001-01</span></div>' ] && ok "carte d'issue Fait sans besoin ni dépendance : ni marqueur ni ligne vide" || ko "carte d'issue minimale" "$(carte 001-01)"
awk '/<section id="issues"/ { s = 1 } s && /<h3[^>]*>En cours \(0\)<\/h3>/ { getline; print; exit }' dashboard.html | grep -qx '<p class="vide">—</p>' && ok "colonne vide : « — » discret" || ko "colonne vide" "$(grep -n -A1 'En cours (0)' dashboard.html | head -4)"
awk '/<section id="issues"/ { s = 1 } s && /class="carte/ { sub(/.*<strong>/, ""); sub(/<\/strong>.*/, ""); printf "%s ", $0 }' dashboard.html | grep -qx '001-02 001-03 001-01 ' && ok "cartes dans l'ordre des fichiers, par colonne" || ko "ordre des cartes" "$(grep -n 'class="carte' dashboard.html)"
grep -A2 '<section id="en-cours">' dashboard.html | grep -q 'Aucune issue en cours.' && [ "$(grep -n '<section id="en-cours">' dashboard.html | cut -d: -f1)" -lt "$(grep -n '<section id="besoins">' dashboard.html | cut -d: -f1)" ] && ok "encart En cours en haut de page : « Aucune issue en cours. »" || ko "encart sans issue en cours" "$(grep -n -A3 'en-cours' dashboard.html)"
! grep -q 'class="compteur' dashboard.html && ! grep -q '<table' dashboard.html && ok "plus de compteurs ni de tables (redondants avec les en-têtes de colonnes)" || ko "compteurs ou tables restants"
grep -q 'grid-auto-columns: minmax' dashboard.html && grep -q 'overflow-x: auto' dashboard.html && ! grep -Eqi '<script|<link|src=|@import|url\(' dashboard.html && ok "mise en page CSS seule (grid, défilement horizontal), aucune ressource externe ni JavaScript" || ko "CSS seule"
issue_id "$p" 001-04 "À faire" docs/prd/001-m.md "[CA-04]" "[]"
sed -i.bak "s/^titre: T001-04/titre: <img src=x onerror=1> l'a/" docs/issues/001-04-x.md; rm -f docs/issues/*.bak
scripts/dashboard.sh >/dev/null
! grep -q '<img' dashboard.html && grep -q '&lt;img src=x onerror=1&gt; l&#39;a' dashboard.html && ok "cs02_ titre d'issue échappé" || ko "cs02_ échappement des issues" "$(grep -n 'img' dashboard.html | head -3)"
verifier "--sortie écrit dans le fichier demandé" 0 "autre.html" scripts/dashboard.sh --sortie autre.html
[ -f autre.html ] && ok "fichier de --sortie créé" || ko "fichier de --sortie créé"
scripts/dashboard.sh --attente 5 >/dev/null
grep -q 'content="5"' dashboard.html && ok "--attente change le rafraîchissement" || ko "--attente"
verifier "--attente non numérique = 64" 64 "Usage" scripts/dashboard.sh --attente abc
verifier "argument inconnu = 64" 64 "Usage" scripts/dashboard.sh --bad
rm -f dashboard.html
{ perl -e 'alarm 4; exec @ARGV' scripts/dashboard.sh --boucle 1 >/dev/null 2>&1; } 2>/dev/null; code=$?
[ -f dashboard.html ] && [ "$code" -ne 0 ] && ok "--boucle régénère en continu (arrêté par signal)" || ko "--boucle" "code $code"
rm -rf docs/issues backlog.md dashboard.html; mkdir -p docs/issues
cat > backlog.md <<'EOF'
## Besoins fonctionnels

| ID | Besoin | Priorité | Statut | PRD | Décisions |
|----|--------|----------|--------|-----|-----------|
| F-05 | a \| b | P2 | En revue | docs/prd/005-m.md | |
| F-06 | Statut inventé | P2 | Inconnu | | |
EOF
printf -- '---\nid: 009-01\ntitre: Titre\nprd: docs/prd/zzz-prd.md\nbesoin: F-09\nstatut: À faire\ndepend_de: []\n---\n' > docs/issues/009-01-x.md
printf -- '---\nid: 009-02\ntitre: <script>x</script> & y\nbesoin: F-09\nstatut: En cours\ndepend_de: [009-01, 009-03]\n---\n' > docs/issues/009-02-x.md
printf -- '---\nid: 009-03\ntitre: Relue\nbesoin: F-09\nstatut: En revue\ndepend_de: []\n---\n' > docs/issues/009-03-x.md
printf -- '---\nid: 009-04\ntitre: Hors cycle\nbesoin: F-09\nstatut: Spécifié\ndepend_de: []\n---\n' > docs/issues/009-04-x.md
scripts/dashboard.sh >/dev/null
carte 009-01 | grep -q '<span class="detail">F-09</span>' && ! grep -q 'zzz-prd' dashboard.html && ok "issues : besoin lu dans le champ besoin (pas prd)" || ko "besoin des issues" "$(grep -n 'F-09\|zzz' dashboard.html | head -3)"
[ "$(carte F-05)" = '<div class="carte"><strong>F-05</strong> <span class="titre">a | b</span><span class="detail">P2</span><span class="detail">PRD : docs/prd/005-m.md</span></div>' ] && ok "\\| dans une cellule du backlog ne décale pas les champs" || ko "\\| dans une cellule" "$(carte F-05)"
[ "$(colonnes besoins)" = "À faire (0)|En clarification (0)|Spécifié (0)|En cours (0)|En revue (1)|Fait (0)|(autre) (1)|" ] && grep -q '<h3 class="statut-inconnu">(autre) (1)</h3>' dashboard.html && awk '/<h3[^>]*>\(autre\) \(1\)</ { getline; print; exit }' dashboard.html | grep -q '<strong>F-06</strong>' && ok "besoin à statut inconnu : colonne (autre) en dernier" || ko "colonne (autre) des besoins" "$(colonnes besoins)"
[ "$(colonnes issues)" = "À faire (1)|En cours (1)|En revue (1)|Fait (0)|(autre) (1)|" ] && carte 009-04 | grep -q 'Hors cycle' && ok "issue hors du cycle des issues (Spécifié) : colonne (autre)" || ko "colonne (autre) des issues" "$(colonnes issues)"
[ "$(carte 009-02)" = '<div class="carte"><strong>009-02</strong> <span class="titre">&lt;script&gt;x&lt;/script&gt; &amp; y</span><span class="detail">F-09</span><span class="detail">dépend de : 009-01, 009-03</span></div>' ] && ok "cs03_ carte d'issue : id, titre échappé, besoin, dépendances (pas de marqueur hors À faire)" || ko "cs03_ carte d'issue" "$(carte 009-02)"
! grep -qi '<script' dashboard.html && ok "cs03_ aucune balise <script> dans la page" || ko "cs03_ <script> dans la page" "$(grep -n -i '<script' dashboard.html)"
encart="$(awk '/<section id="en-cours">/ { s = 1 } s { print } s && /<\/section>/ { exit }' dashboard.html)"
printf '%s' "$encart" | grep -qF '<li><strong>009-02</strong> &lt;script&gt;x&lt;/script&gt; &amp; y' && printf '%s' "$encart" | grep -qF '<li><strong>009-03</strong> Relue' && ! printf '%s' "$encart" | grep -q '009-01\|009-04\|Aucune issue' && ok "encart En cours : issues En cours et En revue (référence + titre), seulement elles" || ko "encart avec issues en cours" "$encart"
err="$(scripts/dashboard.sh --sortie absent/x.html 2>&1 >/dev/null)"; code=$?
{ [ "$code" -eq 64 ] && [ "$err" = "Erreur : le dossier de sortie « $PWD/absent » n'existe pas." ] && [ ! -e absent ]; } && ok "--sortie vers un dossier inexistant : message clair, code 64, dossier non créé" || ko "--sortie dossier inexistant" "code $code ; $err"
rm -rf docs/issues backlog.md dashboard.html; mkdir -p docs/issues
verifier "sans backlog ni issue : page générée sans erreur" 0 "dashboard.html" scripts/dashboard.sh
droits() { ls -l "$1" | cut -c1-10; }
rm -f dashboard.html; (umask 022 && scripts/dashboard.sh >/dev/null)
[ "$(droits dashboard.html)" = "-rw-r--r--" ] && ok "page lisible selon l'umask (022 : -rw-r--r--, pas 0600)" || ko "page lisible selon l'umask 022" "$(droits dashboard.html)"
rm -f dashboard.html; (umask 027 && scripts/dashboard.sh >/dev/null)
[ "$(droits dashboard.html)" = "-rw-r-----" ] && ok "droits de la page tirés de l'umask (027 : -rw-r-----)" || ko "page selon l'umask 027" "$(droits dashboard.html)"
# Génération bloquée (etat-issues.sh lent) puis interrompue par un signal : le fichier temporaire ne doit pas rester.
cp factory/scripts/etat-issues.sh "$racine_tmp/etat-issues.sh.orig"
printf '#!/bin/sh\ntouch "%s/generation-en-cours"\nsleep 2\n' "$p" > factory/scripts/etat-issues.sh
# Le cas --boucle plus haut est tué par SIGALRM : il a laissé son temporaire 2 fois sur 250 (mesure), par un mécanisme non identifié. À retirer ici, sinon ce cas échoue au hasard.
rm -f generation-en-cours dashboard.html.*; scripts/dashboard.sh --boucle 1 >/dev/null 2>&1 & pid=$!
n=0; while [ ! -e generation-en-cours ] && [ "$n" -lt 50 ]; do sleep 0.1; n=$((n + 1)); done
kill -TERM "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
restes="$(ls dashboard.html.* 2>/dev/null)"
[ -e generation-en-cours ] && [ -z "$restes" ] && ok "interruption pendant la génération : aucun fichier temporaire résiduel" || ko "fichier temporaire résiduel après interruption" "$restes"
cp "$racine_tmp/etat-issues.sh.orig" factory/scripts/etat-issues.sh; rm -f generation-en-cours dashboard.html*

echo "dashboard.sh : statut lu sur la branche de l'issue"
p="$(nouveau_projet)"; cd "$p" || exit 1
git init -q -b develop .; printf 'dashboard.html\n' > .gitignore; rm -f docs/issues/[0-9]*.md
gd_() { git -c user.name=t -c user.email=t@t "$@"; }
issue_b() { # issue_b <id> <statut> <branche> [dépendances] : écrit l'issue
  printf -- '---\nid: %s\ntitre: T%s\nbesoin: F-01\nstatut: %s\nbranche: %s\ndepend_de: [%s]\n---\n' "$1" "$1" "$2" "$3" "${4:-}" > "${DOSSIER_B:-docs/issues}/$1-x.md"
}
sur_branche() { # sur_branche <branche> <id> <statut> <branche de l'en-tête> : crée la branche avec ce statut d'issue
  git branch "$1" >/dev/null || return 1
  git worktree add -q "$racine_tmp/wt-$2" "$1" >/dev/null 2>&1
  DOSSIER_B="$racine_tmp/wt-$2/docs/issues" issue_b "$2" "$3" "$4"
  gd_ -C "$racine_tmp/wt-$2" add -A; gd_ -C "$racine_tmp/wt-$2" commit -qm "statut $2"
  git worktree remove --force "$racine_tmp/wt-$2"
}
H1='feat/$(touch${IFS}pwn1)<script>alert(1)</script>'
H2='a b $(touch pwn2) <script>alert(2)</script>'
for ligne in "002-01|feat/a" "002-02|feat/absente" "002-03|feat/c" "002-04|feat/d" "002-05|feat/e" "002-06|$H1" "002-07|$H2" "002-08|--output=pwn3" "002-09|develop..feat/a" "002-10|feat/f" ; do
  issue_b "${ligne%%|*}" "À faire" "${ligne#*|}"
done
issue_b 002-03 "En revue" feat/c
issue_b 002-11 "À faire" "" 002-10
gd_ add -A; gd_ commit -qm init
sur_branche feat/a 002-01 "En cours" feat/a
sur_branche feat/c 002-03 "À faire" feat/c
git branch feat/d >/dev/null; git worktree add -q "$racine_tmp/wt-d" feat/d >/dev/null 2>&1; git -C "$racine_tmp/wt-d" rm -q docs/issues/002-04-x.md; gd_ -C "$racine_tmp/wt-d" commit -qm retire; git worktree remove --force "$racine_tmp/wt-d"
sur_branche feat/e 002-05 '<b>Inventé</b>' feat/e
sur_branche "$H1" 002-06 "En revue" "$H1"
sur_branche feat/f 002-10 "Fait" feat/f
colonne_de() { awk -v id="<strong>$1</strong>" '/<section id="issues"/ { s = 1 } s && /<h3/ { c = $0; sub(/<\/h3>.*/, "", c); sub(/.*>/, "", c); sub(/ \([0-9]+\)$/, "", c) } s && /class="carte/ && index($0, id) { print c; exit }' "$2"; }
carte_de() { grep -F "<strong>$1</strong>" "$2" | grep -F 'class="carte'; }
sortie_b="$racine_tmp/branche.html"
verifier_exact "branche : aucune erreur, noms hostiles compris" 0 "$sortie_b" scripts/dashboard.sh --sortie "$sortie_b"
[ "$(colonne_de 002-01 "$sortie_b")" = "En cours" ] && ok "branche : statut plus avancé sur la branche affiché" || ko "branche : statut plus avancé" "$(colonne_de 002-01 "$sortie_b")"
grep -A3 '<section id="en-cours">' "$sortie_b" | grep -q '002-01' && ok "branche : l'encart En cours compte aussi ce statut" || ko "branche : encart En cours"
attendu_a="$(git log -1 --format='%h' feat/a) du $(git log -1 --format='%cs' feat/a)"
carte_de 002-01 "$sortie_b" | grep -qF "dernier commit : $attendu_a" && ok "branche : dernier commit (hash court et date) sur la carte" || ko "branche : dernier commit" "$(carte_de 002-01 "$sortie_b")"
[ "$(colonne_de 002-02 "$sortie_b")" = "À faire" ] && ! carte_de 002-02 "$sortie_b" | grep -q 'dernier commit' && ok "branche absente : statut local, sans commit" || ko "branche absente"
[ "$(colonne_de 002-03 "$sortie_b")" = "En revue" ] && ok "branche : statut local plus avancé conservé" || ko "statut local plus avancé" "$(colonne_de 002-03 "$sortie_b")"
[ "$(colonne_de 002-04 "$sortie_b")" = "À faire" ] && carte_de 002-04 "$sortie_b" | grep -q 'dernier commit' && ok "fichier absent sur la branche : statut local, commit affiché" || ko "fichier absent sur la branche"
[ "$(colonne_de 002-05 "$sortie_b")" = "À faire" ] && ! grep -q 'Inventé' "$sortie_b" && ok "statut inconnu sur la branche : statut local, valeur non écrite" || ko "statut inconnu sur la branche"
[ "$(colonne_de 002-06 "$sortie_b")" = "En revue" ] && ok "branche au nom hostile mais valide : lue comme une donnée" || ko "branche hostile valide" "$(colonne_de 002-06 "$sortie_b")"
[ "$(colonne_de 002-07 "$sortie_b")" = "À faire" ] && [ "$(colonne_de 002-08 "$sortie_b")" = "À faire" ] && [ "$(colonne_de 002-09 "$sortie_b")" = "À faire" ] && ! carte_de 002-09 "$sortie_b" | grep -q 'dernier commit' && ok "espaces, option ou intervalle dans le nom : statut local" || ko "noms invalides"
[ ! -e pwn1 ] && [ ! -e pwn2 ] && [ ! -e pwn3 ] && [ ! -e '=pwn3' ] && ok "cs_ nom de branche hostile : rien n'est exécuté" || ko "cs_ exécution depuis un nom de branche"
! grep -q 'alert' "$sortie_b" && ! grep -Eq '<script|<b>' "$sortie_b" && ok "cs_ nom de branche hostile : aucun HTML injecté" || ko "cs_ HTML injecté"
carte_de 002-11 "$sortie_b" | grep -q 'marqueur-bloquee' && ok "dépendance Fait sur sa branche seule, pas fusionnée : reste bloquée" || ko "dépendance non fusionnée" "$(carte_de 002-11 "$sortie_b")"
verifier_exact "etat-issues --prochaine : une issue En cours sur sa branche n'est pas prête" 0 "002-02" scripts/etat-issues.sh --prochaine
git worktree add -q "$racine_tmp/wt-classique" -b wt-classique >/dev/null 2>&1
"$racine_tmp/wt-classique/scripts/dashboard.sh" --sortie "$racine_tmp/wt.html" >/dev/null 2>&1
[ "$(colonne_de 002-01 "$racine_tmp/wt.html")" = "En cours" ] && ok "worktree d'un dépôt classique : branche lue" || ko "worktree classique"
git worktree remove --force "$racine_tmp/wt-classique"
git clone -q --bare . "$racine_tmp/nu.git" >/dev/null 2>&1; git -C "$racine_tmp/nu.git" worktree add -q "$racine_tmp/wt-nu" develop >/dev/null 2>&1
"$racine_tmp/wt-nu/scripts/dashboard.sh" --sortie "$racine_tmp/nu.html" >/dev/null 2>&1
[ "$(colonne_de 002-01 "$racine_tmp/nu.html")" = "En cours" ] && [ -n "$(carte_de 002-01 "$racine_tmp/nu.html" | grep 'dernier commit')" ] && ok "worktree d'un clone bare : branche lue" || ko "worktree de clone bare"
lire_depot "$depot" factory/scripts/dashboard.sh | grep -q "ne dit pas si un agent tourne encore" && lire_depot "$depot" factory/README.md | grep -q "ne dit pas si un agent tourne encore" && ok "limite du statut écrite (en-tête et README)" || ko "limite du statut absente"

echo "fin-issue.sh"
p="$(nouveau_projet)"; cd "$p" || exit 1
fin_projet() { # dépôt git propre ; .factory-verify = <commande> ; un test ca10 dans src/test
  printf '%s\n' "$1" > .factory-verify; printf 'void ca10_x() {}\n' > src/test/A.java
  git add -A >/dev/null; git -c user.name=t -c user.email=t@t commit -qm "etat $RANDOM" --allow-empty
}
git init -q .; printf 'args.txt\n' > .gitignore
issue_id "$p" 001-01 "En cours" docs/prd/001-m.md "[CA-10]" "[]"
issue_id "$p" 001-02 "En cours" docs/prd/001-m.md "[CA-99]" "[]"
maven() { printf "echo '[INFO] Tests run: %s, Failures: 0, Errors: 0, Skipped: %s'" "$1" "$2"; }
fin_projet "$(maven 7 0)"; court="$(git rev-parse --short HEAD)"
verifier_exact "fin-issue : dernière ligne de succès" 0 "FIN-ISSUE OK 001-01 $court : 7 tests, 0 échec, 0 ignoré" sh -c 'scripts/fin-issue.sh 001-01 2>&1 | tail -1; exit $(scripts/fin-issue.sh 001-01 >/dev/null 2>&1; echo $?)'
verifier "fin-issue : commit vérifié complet affiché" 0 "Commit vérifié : $(git rev-parse HEAD)" scripts/fin-issue.sh 001-01
verifier "fin-issue : critère manquant" 1 "FIN-ISSUE ECHEC : .*critère" scripts/fin-issue.sh 001-02
verifier "fin-issue : issue inconnue = 64" 64 "Aucune issue" scripts/fin-issue.sh 999
verifier "fin-issue : sans argument = 64" 64 "Usage" scripts/fin-issue.sh
verifier "fin-issue : argument après l'issue sans -- = 64" 64 "Usage" scripts/fin-issue.sh 001-01 x
fin_projet "exit 3"
verifier "fin-issue : build rouge" 1 "FIN-ISSUE ECHEC : .*build" scripts/fin-issue.sh 001-01
fin_projet "$(maven 7 6)"
verifier "fin-issue : tests ignorés = échec" 1 "FIN-ISSUE ECHEC : 6 test\(s\) ignoré" scripts/fin-issue.sh 001-01
printf 'FIN_ISSUE_IGNORES_AUTORISES=6\n' > .factory.conf; git add -A; git -c user.name=t -c user.email=t@t commit -qm conf
verifier "fin-issue : ignorés autorisés par la configuration" 0 "FIN-ISSUE OK 001-01 .* : 7 tests, 0 échec, 6 ignorés \(autorisés\)" scripts/fin-issue.sh 001-01
printf 'FIN_ISSUE_IGNORES_AUTORISES=5\n' > .factory.conf; git add -A; git -c user.name=t -c user.email=t@t commit -qm conf
verifier "fin-issue : plus d'ignorés que l'autorisation = échec (borne)" 1 "FIN-ISSUE ECHEC : 6 test\(s\) ignoré" scripts/fin-issue.sh 001-01
printf 'FIN_ISSUE_IGNORES_AUTORISES=abc\n' > .factory.conf; git add -A; git -c user.name=t -c user.email=t@t commit -qm conf
verifier "fin-issue : autorisation invalide = 64" 64 "FIN_ISSUE_IGNORES_AUTORISES invalide" scripts/fin-issue.sh 001-01
git rm -qf .factory.conf; git -c user.name=t -c user.email=t@t commit -qm conf
fin_projet "echo bonjour"
verifier "fin-issue : nombre illisible = échec dit clairement" 1 "FIN-ISSUE ECHEC : nombre de tests ignorés illisible" scripts/fin-issue.sh 001-01
printf 'FIN_ISSUE_IGNORES_AUTORISES=inconnu\n' > .factory.conf; git add -A; git -c user.name=t -c user.email=t@t commit -qm conf
verifier "fin-issue : illisible autorisé explicitement" 0 "FIN-ISSUE OK 001-01 .* : tests non comptés, ignorés inconnus \(autorisé\)" scripts/fin-issue.sh 001-01
git rm -qf .factory.conf; git -c user.name=t -c user.email=t@t commit -qm conf
fin_projet "$(maven 0 0)"
verifier "fin-issue : zéro test = échec" 1 "FIN-ISSUE ECHEC : aucun test" scripts/fin-issue.sh 001-01
fin_projet "echo '= 5 passed, 2 skipped in 0.1s ='"
verifier "fin-issue : ignorés lus chez pytest" 1 "FIN-ISSUE ECHEC : 2 test\(s\) ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo 'Ran 4 tests in 0.1s'; echo 'OK (skipped=1)'"
verifier "fin-issue : ignorés lus chez unittest" 1 "FIN-ISSUE ECHEC : 1 test\(s\) ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo 'Ran 4 tests in 0.1s'; echo OK"
verifier "fin-issue : unittest sans ignoré" 0 "FIN-ISSUE OK 001-01 .* : 4 tests, 0 échec, 0 ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo 'TESTS OK : 9 vérifications'"
verifier "fin-issue : suite de la factory" 0 "FIN-ISSUE OK 001-01 .* : 9 tests, 0 échec, 0 ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo '[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 2'; echo '[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0'"
verifier "verify-clean : Maven, les résumés de plusieurs modules sont additionnés" 0 "Tests : Tests run: 8, Failures: 0, Errors: 0, Skipped: 2" scripts/verify-clean.sh
verifier "fin-issue : ignorés d'un premier module vus" 1 "FIN-ISSUE ECHEC : 2 test\(s\) ignoré" scripts/fin-issue.sh 001-01
ecrit="$p/args.txt"
fin_projet "printf '[%s]\n' \"\$@\" > '$ecrit'; $(maven 1 0)"
verifier "fin-issue : argument avec espaces après --" 0 "FIN-ISSUE OK" scripts/fin-issue.sh 001-01 -- "-Dessai.chrome=/A B/Google Chrome"
[ "$(cat args.txt)" = "[-Dessai.chrome=/A B/Google Chrome]" ] && ok "fin-issue : l'argument arrive entier" || ko "fin-issue : l'argument arrive entier" "$(cat args.txt)"
printf 'FIN_ISSUE_ARGUMENTS=-Dx=/A B/C D|-Pessai\n' > .factory.local.conf; printf '.factory.local.conf\n' >> .gitignore; git add -A; git -c user.name=t -c user.email=t@t commit -qm conf
verifier "fin-issue : arguments de la configuration" 0 "FIN-ISSUE OK" scripts/fin-issue.sh 001-01 -- -Z
[ "$(cat args.txt)" = "[-Dx=/A B/C D]
[-Pessai]
[-Z]" ] && ok "fin-issue : configuration découpée sur |, espaces gardés, puis arguments de --" || ko "fin-issue : configuration découpée" "$(cat args.txt)"
# Revue, itération 1
: > .factory.local.conf; gc_() { git -c user.name=t -c user.email=t@t "$@"; }
fin_projet "echo '[ERROR] Tests run: 5, Failures: 2, Errors: 1, Skipped: 0'"
verifier "fin-issue : échecs Maven avec un build au code 0" 1 "FIN-ISSUE ECHEC : 3 test\(s\) en échec" scripts/fin-issue.sh 001-01
fin_projet "echo '= 3 failed, 2 passed in 0.1s ='"
verifier "fin-issue : échecs pytest avec un build au code 0" 1 "FIN-ISSUE ECHEC : 3 test\(s\) en échec" scripts/fin-issue.sh 001-01
fin_projet "echo '= 1 error, 2 passed in 0.1s ='"
verifier "fin-issue : erreur pytest" 1 "FIN-ISSUE ECHEC : 1 test\(s\) en échec" scripts/fin-issue.sh 001-01
fin_projet "echo '= 5 passed, 2 deselected, 1 xfailed in 0.1s ='"
verifier "fin-issue : pytest deselected et xfailed comptés comme ignorés" 1 "FIN-ISSUE ECHEC : 3 test\(s\) ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo 'Ran 4 tests in 0.1s'; echo 'OK (skipped=2)'; echo 'Ran 4 tests in 0.1s'; echo OK"
verifier "verify-clean : suites unittest additionnées" 0 "Tests : Ran 8 tests ; OK \(skipped=2\)" scripts/verify-clean.sh
verifier "fin-issue : ignorés de la première suite unittest vus" 1 "FIN-ISSUE ECHEC : 2 test\(s\) ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo 'Ran 4 tests in 0.1s'; echo 'FAILED (failures=1, errors=2)'"
verifier "fin-issue : échecs unittest avec un build au code 0" 1 "FIN-ISSUE ECHEC : 3 test\(s\) en échec" scripts/fin-issue.sh 001-01
fin_projet "echo 'Tests:       1 skipped, 2 failed, 5 passed, 8 total'"
verifier "fin-issue : jest, échecs lus" 1 "FIN-ISSUE ECHEC : 2 test\(s\) en échec" scripts/fin-issue.sh 001-01
fin_projet "echo 'Tests:       1 skipped, 5 passed, 6 total'"
verifier "fin-issue : jest, ignorés lus" 1 "FIN-ISSUE ECHEC : 1 test\(s\) ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo 'Tests:       5 passed, 5 total'"
verifier "fin-issue : jest, succès" 0 "FIN-ISSUE OK 001-01 .* : 5 tests, 0 échec, 0 ignoré" scripts/fin-issue.sh 001-01
fin_projet "printf 'ℹ tests 5\nℹ pass 4\nℹ fail 0\nℹ cancelled 0\nℹ skipped 1\nℹ todo 0\n'"
verifier "fin-issue : node:test, ignorés lus" 1 "FIN-ISSUE ECHEC : 1 test\(s\) ignoré" scripts/fin-issue.sh 001-01
fin_projet "printf '# tests 5\n# pass 3\n# fail 1\n# cancelled 1\n# skipped 0\n# todo 0\n'"
verifier "fin-issue : node:test en TAP, échecs lus" 1 "FIN-ISSUE ECHEC : 2 test\(s\) en échec" scripts/fin-issue.sh 001-01
fin_projet "printf '# tests 5\n# pass 5\n# fail 0\n# cancelled 0\n# skipped 0\n# todo 0\n'"
verifier "fin-issue : node:test, succès" 0 "FIN-ISSUE OK 001-01 .* : 5 tests, 0 échec, 0 ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo '[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0'; true"
verifier "fin-issue : arguments de ligne de commande signalés" 0 "FIN-ISSUE OK .* ; arguments : -Dtest=Seul \(ligne de commande\)" scripts/fin-issue.sh 001-01 -- -Dtest=Seul
printf 'FIN_ISSUE_ARGUMENTS=-Pessai\n' > .factory.local.conf
verifier "fin-issue : arguments de configuration signalés" 0 "FIN-ISSUE OK .* ; arguments : -Pessai \(configuration\)" scripts/fin-issue.sh 001-01
: > .factory.local.conf
fin_projet "echo '[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 1'"
verifier "fin-issue : autorisation venue de l'environnement signalée" 0 "FIN-ISSUE OK .* ; autorisation d'ignorés venue de l'environnement" env FACTORY_FIN_ISSUE_IGNORES_AUTORISES=1 scripts/fin-issue.sh 001-01
fin_projet "echo '[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0'"
touch cache-invisible; git -c status.showUntrackedFiles=no status --porcelain >/dev/null; git config status.showUntrackedFiles no
verifier "fin-issue : non suivi vu malgré status.showUntrackedFiles=no" 1 "FIN-ISSUE ECHEC : arbre Git non propre" scripts/fin-issue.sh 001-01
git config --unset status.showUntrackedFiles; : > .gitignore.tmp; /bin/rm -f cache-invisible .gitignore.tmp
printf 'marque\n' > marque.txt; git add marque.txt; gc_ commit -qm marque; git update-index --skip-worktree marque.txt; printf 'x\n' >> marque.txt
verifier "fin-issue : fichier skip-worktree refusé" 1 "FIN-ISSUE ECHEC : fichiers marqués" scripts/fin-issue.sh 001-01
git update-index --no-skip-worktree marque.txt; git update-index --assume-unchanged marque.txt
verifier "fin-issue : fichier assume-unchanged refusé" 1 "FIN-ISSUE ECHEC : fichiers marqués" scripts/fin-issue.sh 001-01
git update-index --no-assume-unchanged marque.txt; git checkout -q -- marque.txt 2>/dev/null || printf 'marque\n' > marque.txt
printf 'void ca77_x() {}\n' > src/test/Ignore.java; printf 'src/test/Ignore.java\n' >> .gitignore; git add .gitignore; gc_ commit -qm ignore
issue_id "$p" 001-03 "En cours" docs/prd/001-m.md "[CA-77]" "[]"; git add -A; gc_ commit -qm i3
verifier "fin-issue : test dans un fichier ignoré, critère manquant" 1 "FIN-ISSUE ECHEC : .*critère sans test" scripts/fin-issue.sh 001-03
fin_projet "touch '$p/pendant.txt'; echo '[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0'"
verifier "fin-issue : arbre modifié pendant la vérification" 1 "FIN-ISSUE ECHEC : arbre Git modifié pendant" scripts/fin-issue.sh 001-01
/bin/rm -f pendant.txt
fin_projet "echo 'Ran 3 tests in 0.1s'; echo 'FAILED (unexpected successes=1)'"
verifier "fin-issue : verdict FAILED sans échec compté" 1 "FIN-ISSUE ECHEC : .*verdict FAILED" scripts/fin-issue.sh 001-01
fin_projet "echo 'Tests:       1 skipped, 5 passed, 6 total'; echo 'Tests:       2 passed, 2 total'"
verifier "fin-issue : jest, ignorés du premier résumé vus" 1 "FIN-ISSUE ECHEC : 1 test\\(s\\) ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo '= 1 failed, 1 passed in 0.1s ='; echo '= 2 passed in 0.1s ='"
verifier "fin-issue : pytest unit puis integ, échec du premier vu" 1 "FIN-ISSUE ECHEC : 1 test\\(s\\) en échec" scripts/fin-issue.sh 001-01
fin_projet "echo '= 3 passed in 0.1s ='; echo '= 2 passed, 1 skipped in 0.1s ='"
verifier "verify-clean : résumés pytest additionnés" 0 "Tests : 5 passed, 1 skipped" scripts/verify-clean.sh
fin_projet "printf '# tests 2\\n# pass 1\\n# fail 1\\n# cancelled 0\\n# skipped 0\\n# todo 0\\n# tests 3\\n# pass 3\\n# fail 0\\n# cancelled 0\\n# skipped 0\\n# todo 0\\n'"
verifier "fin-issue : deux blocs node:test, échec du premier vu" 1 "FIN-ISSUE ECHEC : 1 test\\(s\\) en échec" scripts/fin-issue.sh 001-01
fin_projet "touch '$p/cree.txt'; echo '[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0'"; git config status.showUntrackedFiles no
verifier "fin-issue : fichier créé par le build vu malgré status.showUntrackedFiles=no" 1 "FIN-ISSUE ECHEC : arbre Git modifié pendant" scripts/fin-issue.sh 001-01
git config --unset status.showUntrackedFiles; /bin/rm -f cree.txt
fin_projet "echo '[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0'"
verifier "fin-issue : DOSSIER_TESTS absolu refusé" 64 "FIN-ISSUE ECHEC : DOSSIER_TESTS" env DOSSIER_TESTS="$p/src/test" scripts/fin-issue.sh 001-01
verifier "fin-issue : DOSSIER_TESTS avec .. refusé" 64 "FIN-ISSUE ECHEC : DOSSIER_TESTS" env DOSSIER_TESTS="src/../../x" scripts/fin-issue.sh 001-01
verifier "fin-issue : DOSSIER_TESTS relatif admis" 0 "FIN-ISSUE OK" env DOSSIER_TESTS="src/test" scripts/fin-issue.sh 001-01
# Plusieurs types de résumé : un seul serait lu, les ignorés ou échecs des autres se perdraient.
MELANGE='FIN-ISSUE ECHEC : nombre de tests ignorés illisible dans le résumé \(« plusieurs types de résumé'
M_OK="echo '[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0'"
fin_projet "$M_OK && echo 'Tests: 4 skipped, 5 passed, 9 total'"
verifier "fin-issue : Maven puis jest = résumé illisible" 1 "$MELANGE \(Maven, jest\)" scripts/fin-issue.sh 001-01
verifier "verify-clean : Maven puis jest, code du build gardé" 0 "VERIFY OK" scripts/verify-clean.sh
fin_projet "echo 'Ran 1 test in 0.001s'; echo OK; echo '2 passed, 4 skipped'"
verifier "fin-issue : unittest puis pytest = résumé illisible" 1 "$MELANGE \(unittest, pytest\)" scripts/fin-issue.sh 001-01
fin_projet "echo '= 1 passed in 0.1s ='; echo 'Tests: 4 skipped, 1 passed, 5 total'"
verifier "fin-issue : pytest puis jest = résumé illisible" 1 "$MELANGE \(pytest, jest\)" scripts/fin-issue.sh 001-01
fin_projet "echo 'Tests: 1 failed, 1 passed, 2 total'; echo '= 3 passed in 0.1s ='"
verifier "fin-issue : échec jest avant pytest, enchaînés par ; = résumé illisible" 1 "$MELANGE \(pytest, jest\)" scripts/fin-issue.sh 001-01
fin_projet "$M_OK; echo 'Tests: 4 skipped, 5 passed, 9 total'"
verifier "fin-issue : FIN_ISSUE_IGNORES_AUTORISES=inconnu tolère aussi ce résumé, et le dit" 0 "FIN-ISSUE OK 001-01 .* : tests non comptés, ignorés inconnus \(autorisé\)" env FACTORY_FIN_ISSUE_IGNORES_AUTORISES=inconnu scripts/fin-issue.sh 001-01
# Une ligne de journal qui ressemble à un résumé n'en est pas un.
fin_projet "echo '=== build failed ==='; echo '3 passed checks'; echo 'Ran 3 tests in the previous phase'; echo 'Tests: compiled 3 total'; echo '# tests 5'; echo '2 failed logins'; $M_OK"
verifier "fin-issue : Maven et lignes de journal ordinaires, pas de faux échec" 0 "FIN-ISSUE OK 001-01 .* : 1 tests, 0 échec, 0 ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo 'Ran 3 tests in the previous phase'; echo '= 2 passed in 0.1s ='"
verifier "fin-issue : pytest et « Ran n tests in » de journal, pas de faux échec" 0 "FIN-ISSUE OK 001-01 .* : 2 tests, 0 échec, 0 ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo '=== build failed ==='; echo 'Tests: 2 passed, 2 total'"
verifier "fin-issue : jest et ligne « build failed », pas de faux échec" 0 "FIN-ISSUE OK 001-01 .* : 2 tests, 0 échec, 0 ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo '= 3 passed in 0.1s ='; echo '= 2 passed in 0.1s ='"
verifier "fin-issue : un seul lanceur répété reste additionné" 0 "FIN-ISSUE OK 001-01 .* : 5 tests, 0 échec, 0 ignoré" scripts/fin-issue.sh 001-01
fin_projet "echo '[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0'"
out="$(env TMPDIR="$p/absent" scripts/fin-issue.sh 001-01 2>&1)"; code=$?; [ "$code" -eq 1 ] && [ "$(printf '%s\n' "$out" | tail -1 | cut -c1-15)" = "FIN-ISSUE ECHEC" ] && ok "fin-issue : mktemp en échec, dernière ligne écrite" || ko "fin-issue : mktemp en échec, dernière ligne écrite" "$code $out"
touch nouveau.txt
verifier "fin-issue : fichier non suivi = échec (il serait testé sans être dans le commit)" 1 "FIN-ISSUE ECHEC : arbre Git non propre" scripts/fin-issue.sh 001-01
: > nouveau.txt; git add nouveau.txt
verifier "fin-issue : modification non commitée = échec" 1 "FIN-ISSUE ECHEC : arbre Git non propre" scripts/fin-issue.sh 001-01
git -c user.name=t -c user.email=t@t commit -qm n
: > .factory.local.conf # sans argument : la commande de build ci-dessous les recopierait dans la ligne de résumé
fin_projet "git -C '$p' -c user.name=t -c user.email=t@t commit -q --allow-empty -m pendant; $(maven 1 0)"
verifier "fin-issue : commit pendant la vérification = échec" 1 "FIN-ISSUE ECHEC : HEAD a changé" scripts/fin-issue.sh 001-01

echo "worktree-issue.sh : structure bare"
p="$(nouveau_projet)"; cd "$p" || exit 1
reel="$(mktemp -d "$racine_tmp/reel.XXXXXX")/reel.git"
gc() { git -c user.name=t -c user.email=t@t "$@"; }
git init -q -b main .; printf '.env\n.factory.local.conf\n.agents/\n' > .gitignore
printf '#!/bin/sh\nmkdir -p "$(dirname "$0")/../.agents"; touch "$(dirname "$0")/../.agents/sync-lance"\n' > factory/sync.sh; chmod +x factory/sync.sh
issue_id "$p" 001-01 "À faire" docs/prd/1.md "[CA-1]" "[]"; issue_id "$p" 001-02 "À faire" docs/prd/1.md "[CA-2]" "[]"
git add -A; gc commit -qm init; git branch develop; printf 'SECRET=x\n' > .env
git clone -q --bare . "$reel"; git remote add origin "$reel"; git fetch -q origin
c="$(dirname "$reel")/conteneur"
avant="$(git rev-parse HEAD) $(git remote get-url origin) $(git status --porcelain | tr -d '\n')"
verifier "initialiser : conversion, fichiers non suivis rappelés" 0 "non suivis .*\.env" scripts/worktree-issue.sh initialiser "$p" "$c"
[ "$(git --git-dir="$c/.git" remote get-url origin)" = "$reel" ] && ok "initialiser : origin vise l'URL réelle" || ko "initialiser : origin vise l'URL réelle" "$(git --git-dir="$c/.git" remote get-url origin)"
[ "$(git --git-dir="$c/.git" config remote.origin.fetch)" = "+refs/heads/*:refs/remotes/origin/*" ] && git --git-dir="$c/.git" show-ref --verify --quiet refs/remotes/origin/develop && ok "initialiser : refspec de suivi et fetch faits" || ko "initialiser : refspec de suivi et fetch faits"
[ "$(git --git-dir="$c/.git" config --bool core.bare)" = true ] && [ ! -e "$c/.env" ] && [ -z "$(git --git-dir="$c/.git" grep -l SECRET HEAD 2>/dev/null)" ] && ok "initialiser : clone bare, .env non copié" || ko "initialiser : clone bare, .env non copié"
[ "$(git rev-parse HEAD) $(git remote get-url origin) $(git status --porcelain | tr -d '\n')" = "$avant" ] && ok "initialiser : source inchangée" || ko "initialiser : source inchangée"
verifier "initialiser : conteneur existant refusé" 1 "existe déjà" scripts/worktree-issue.sh initialiser "$p" "$c"
verifier "initialiser : source qui n'est pas un dépôt = 64" 64 "Pas un dépôt" scripts/worktree-issue.sh initialiser "$racine_tmp" "$c-2"
verifier "initialiser : arguments manquants = 64" 64 "" scripts/worktree-issue.sh initialiser "$p"
git --git-dir="$c/.git" worktree add -q "$c/develop" develop; cd "$c/develop" || exit 1
d1="$(cd "$c" && pwd -P)/feat-001-01-x"; d2="$(cd "$c" && pwd -P)/feat-001-02-x"
sortie_bare="$(scripts/worktree-issue.sh creer 001-01 2>&1)"; code=$?
[ "$code" -eq 0 ] && [ -d "$c/feat-001-01-x" ] && printf '%s' "$sortie_bare" | grep -q "dossier : .*/feat-001-01-x" && ok "bare creer : dossier au même niveau que .git" || ko "bare creer : dossier au même niveau que .git" "$sortie_bare"
printf '%s' "$sortie_bare" | grep -q "recommand" && ko "bare creer : pas d'avertissement" "$sortie_bare" || ok "bare creer : pas d'avertissement"
[ "$(git -C "$c/feat-001-01-x" rev-parse HEAD)" = "$(git rev-parse develop)" ] && ok "bare creer : branche partie de la base" || ko "bare creer : branche partie de la base"
[ -e "$c/feat-001-01-x/.agents/sync-lance" ] && ok "bare creer : sync.sh lancé dans le nouveau dossier" || ko "bare creer : sync.sh lancé dans le nouveau dossier"
cd "$c/feat-001-01-x" || exit 1
verifier "bare creer depuis un worktree de branche : pas d'imbrication" 0 "dossier : .*/conteneur/feat-001-02-x" scripts/worktree-issue.sh creer 001-02
[ -d "$c/feat-001-02-x" ] && [ ! -e "$c/feat-001-01-x/feat-001-02-x" ] && ok "bare : le dossier est dans le conteneur" || ko "bare : le dossier est dans le conteneur"
verifier "bare lister : worktrees du conteneur" 0 "feat-001-02-x" scripts/worktree-issue.sh lister
cd "$c/develop" || exit 1
gc -C "$c/feat-001-01-x" commit -q --allow-empty -m travail
verifier "bare nettoyer : refusé si non fusionné" 1 "n'est pas fusionnée" scripts/worktree-issue.sh nettoyer 001-01
[ -d "$c/feat-001-01-x" ] && ok "bare nettoyer refusé : dossier conservé" || ko "bare nettoyer refusé : dossier conservé"
gc merge -q --no-ff -m m feat/001-01-x
verifier "bare nettoyer : accepté après fusion" 0 "supprimé" scripts/worktree-issue.sh nettoyer 001-01 --branche
[ ! -e "$c/feat-001-01-x" ] && ok "bare nettoyer : dossier retiré" || ko "bare nettoyer : dossier retiré"
# Revue, itération 1
git --git-dir="$c/.git" config branch.develop.remote >/dev/null && [ "$(git --git-dir="$c/.git" config branch.develop.merge)" = refs/heads/develop ] && ok "initialiser : suivi amont des branches locales" || ko "initialiser : suivi amont des branches locales"
cd "$c/develop" || exit 1
issue_id "$c/develop" 001-04 "À faire" docs/prd/1.md "[CA-4]" "[]"; issue_id "$c/develop" 001-05 "À faire" docs/prd/1.md "[CA-5]" "[]"; issue_id "$c/develop" 001-06 "À faire" docs/prd/1.md "[CA-6]" "[]"; issue_id "$c/develop" 001-07 "À faire" docs/prd/1.md "[CA-7]" "[]"; git add -A; gc commit -qm issues
verifier "creer : préfixe ambigu refusé" 64 "Issue introuvable" scripts/worktree-issue.sh creer 00
scripts/worktree-issue.sh creer 001-04 >/dev/null 2>&1
git -C "$c/feat-001-04-x" checkout -q --detach; gc -C "$c/feat-001-04-x" commit -q --allow-empty -m perdu; git merge-base --is-ancestor feat/001-04-x develop || gc merge -q feat/001-04-x
verifier "nettoyer : HEAD détaché refusé" 1 "n'est pas sur la branche" scripts/worktree-issue.sh nettoyer 001-04
git -C "$c/feat-001-04-x" checkout -q feat/001-04-x
printf 'S=1\n' > "$c/feat-001-04-x/.env"; mkdir -p "$c/feat-001-04-x/.agents/cache"
sortie_n="$(scripts/worktree-issue.sh nettoyer 001-04 2>&1)"; code=$?
[ "$code" -eq 1 ] && printf '%s' "$sortie_n" | grep -q '\.env' && ! printf '%s' "$sortie_n" | grep -q 'S=1' && [ -f "$c/feat-001-04-x/.env" ] && ok "nettoyer : .env ignoré, refus et liste sans contenu" || ko "nettoyer : .env ignoré" "$sortie_n"
/bin/rm -f "$c/feat-001-04-x/.env"
verifier "nettoyer : artefacts connus admis" 0 "supprimé" scripts/worktree-issue.sh nettoyer 001-04
scripts/worktree-issue.sh creer 001-05 >/dev/null 2>&1; printf 'S=1\n' > "$c/feat-001-05-x/.env"
verifier "nettoyer --force passe outre les fichiers ignorés" 0 "supprimé" scripts/worktree-issue.sh nettoyer 001-05 --force
git push -q origin develop
scripts/worktree-issue.sh creer 001-06 >/dev/null 2>&1; gc -C "$c/feat-001-06-x" commit -q --allow-empty -m travail; git -C "$c/feat-001-06-x" push -q origin feat/001-06-x
distant="$(mktemp -d "$racine_tmp/dist.XXXXXX")"; git clone -q "$reel" "$distant/w"; gc -C "$distant/w" checkout -q develop; gc -C "$distant/w" merge -q --no-ff -m m origin/feat/001-06-x; git -C "$distant/w" push -q origin develop
verifier "nettoyer : fusion faite sur le distant reconnue" 0 "supprimé" scripts/worktree-issue.sh nettoyer 001-06
verifier "creer : develop en retard averti" 0 "develop a .* commit.* de retard" scripts/worktree-issue.sh creer 001-07
git -C "$c/feat-001-07-x" status >/dev/null
git --git-dir="$c/.git" remote set-url origin "$racine_tmp/absent.git"
issue_id "$c/develop" 001-08 "À faire" docs/prd/1.md "[CA-8]" "[]"; git add -A; gc commit -qm i8
verifier "creer : hors réseau, averti sans bloquer" 0 "fetch impossible" scripts/worktree-issue.sh creer 001-08
git --git-dir="$c/.git" remote set-url origin "$reel"
cd "$p" || exit 1
c2="$(dirname "$reel")/rel"; (cd "$(dirname "$reel")" && "$p/scripts/worktree-issue.sh" initialiser "$p" rel >/dev/null 2>&1); [ -d "$c2/.git" ] && ok "initialiser : chemin relatif résolu depuis le dossier d'appel" || ko "initialiser : chemin relatif résolu depuis le dossier d'appel"
verifier "initialiser : conteneur dans la source refusé" 64 "dans la source" scripts/worktree-issue.sh initialiser "$p" "$p/dedans"
git remote set-url origin "https://tok:SECRET@$(basename "$reel").invalid/x.git"
out="$(scripts/worktree-issue.sh initialiser "$p" "$c-m" 2>&1)"; printf '%s' "$out" | grep -q SECRET && ko "initialiser : identifiants masqués" "$out" || ok "initialiser : identifiants masqués"
git remote set-url origin "$reel"
s2="$(mktemp -d "$racine_tmp/so.XXXXXX")"; git init -q "$s2"; gc -C "$s2" commit -q --allow-empty -m a
verifier "initialiser : sans origin, avertissement" 0 "origin vise le chemin local" scripts/worktree-issue.sh initialiser "$s2" "$s2-c"
verifier "initialiser : conteneur dans un parent absent de la source refusé" 64 "dans la source" scripts/worktree-issue.sh initialiser "$p" "$p/a/b"
out="$(scripts/worktree-issue.sh danser 2>&1)"; printf '%s' "$out" | grep -q 'set -uo' && ko "usage : en-tête seul" "$out" || ok "usage : en-tête seul"
printf '%s' "$out" | grep -q 'Code de sortie' && ok "usage : en-tête complet" || ko "usage : en-tête complet" "$out"
sortie_cl="$(scripts/worktree-issue.sh creer 001-01 2>&1)"; code=$?
nomp="$(basename "$p")"
[ "$code" -eq 0 ] && [ -d "../$nomp-001-01" ] && [ ! -e "../$nomp-001-01/.agents/sync-lance" ] && printf '%s' "$sortie_cl" | grep -q "structure bare recommand" && ok "dépôt classique : emplacement inchangé, sans sync, avec avertissement" || ko "dépôt classique" "$sortie_cl"

echo "couverture-prd.sh"
p="$(nouveau_projet)"; cd "$p" || exit 1
mkdir -p docs/prd
printf '# PRD\n- **CA-01** Given x\n- **CA-02** Given y\n- **CS-03** Given z\n' > docs/prd/001-m.md
issue_id "$p" 001-01 "À faire" docs/prd/001-m.md "[CA-01, CA-2]" "[]"
issue_id "$p" 001-02 "À faire" docs/prd/001-m.md "[CA-02, CS-03]" "[]"
verifier "CA-2 (001-01) et CA-02 (001-02) sont le même critère : en double" 1 "EN DOUBLE +CA-2" scripts/couverture-prd.sh docs/prd/001-m.md
issue_id "$p" 001-01 "À faire" docs/prd/001-m.md "[CA-01]" "[]"
issue_id "$p" 001-02 "À faire" docs/prd/001-m.md "[CS-03]" "[]"
verifier "CA-02 sans issue" 1 "SANS ISSUE +CA-2" scripts/couverture-prd.sh docs/prd/001-m.md
issue_id "$p" 001-02 "À faire" docs/prd/001-m.md "[CA-02, CS-03, CA-77]" "[]"
verifier "critère d'issue inconnu du PRD" 1 "INCONNU DU PRD +CA-77" scripts/couverture-prd.sh docs/prd/001-m.md
issue_id "$p" 001-02 "À faire" docs/prd/001-m.md "[CA-02, CS-03]" "[]"
verifier "couverture exacte" 0 "OK .*3 critère" scripts/couverture-prd.sh docs/prd/001-m.md
printf '# PRD sans critère\n' > docs/prd/002-v.md
verifier "PRD sans critère défini = erreur" 1 "aucun critère défini" scripts/couverture-prd.sh docs/prd/002-v.md
verifier "sans argument = usage (64)" 64 "Usage" scripts/couverture-prd.sh

echo "verify-clean.sh"
[ -z "${COMMANDE_VERIFY+x}" ] && [ -z "${STUB_CODE+x}" ] && ok "suite isolée de l'environnement appelant : ni COMMANDE_VERIFY ni STUB_CODE hérités" || ko "suite isolée de l'environnement appelant" "COMMANDE_VERIFY=${COMMANDE_VERIFY-<absent>} STUB_CODE=${STUB_CODE-<absent>}"
p="$(nouveau_projet)"; cd "$p" || exit 1
git init -q . && printf '.env\ntarget/\n' > .gitignore && echo "SECRET" > .env && echo "x" > fichier.txt
cat > mvnw <<'EOF'
#!/bin/sh
[ -e .env ] && { echo "FUITE: .env copié"; exit 3; }
[ -e fichier.txt ] || { echo "fichier suivi absent"; exit 4; }
echo "[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0"
echo "BugInstance size is 0"
exit "${STUB_CODE:-0}"
EOF
chmod +x mvnw
export TMPDIR="$racine_tmp/tmp"; mkdir -p "$TMPDIR"
verifier "build vert : résumé chiffré et VERIFY OK" 0 "Tests : Tests run: 3.*" scripts/verify-clean.sh
verifier "un fichier ignoré (.env) n'est pas recopié" 0 "VERIFY OK" scripts/verify-clean.sh
[ -z "$(ls "$TMPDIR")" ] && ok "la copie est supprimée" || ko "la copie est supprimée" "$(ls "$TMPDIR")"
STUB_CODE=1 verifier "build rouge : code propagé et VERIFY ECHEC" 1 "VERIFY ECHEC \(code 1\)" scripts/verify-clean.sh
verifier "argument inconnu = 64" 64 "inconnu" scripts/verify-clean.sh --bad
verifier "--keep conserve la copie" 0 "Copie conservée" scripts/verify-clean.sh --keep
printf 'echo "Ran 7 tests in 0.01s"; exit "${STUB_CODE:-0}"\n' > .factory-verify-stub.sh; echo "sh .factory-verify-stub.sh" > .factory-verify; rm mvnw
git add -A >/dev/null 2>&1
verifier "commande de build lue dans .factory-verify + résumé unittest" 0 "Tests : Ran 7 tests" scripts/verify-clean.sh
# Détection du build, syntaxe shell et arguments supplémentaires
q="$(nouveau_projet)"; cd "$q" || exit 1
git init -q . && echo x > fichier.txt
verifier "aucune commande ni wrapper = 64 avec message" 64 "créez .factory-verify" scripts/verify-clean.sh
printf '#!/bin/sh\necho "gradlew: $*"; echo "Ran 2 tests in 0.1s"\n' > gradlew; chmod +x gradlew
verifier "wrapper ./gradlew détecté" 0 "Tests : Ran 2 tests" scripts/verify-clean.sh
rm gradlew
echo 'echo "$#" > args.txt && cat args.txt && echo "Ran 5 tests in 0s" && : "$@"' > .factory-verify
verifier "syntaxe shell (&&) acceptée, arguments transmis" 0 "Ran 5 tests" scripts/verify-clean.sh -- -a -b
echo 'echo "  ok   un cas"; echo "TESTS OK : 142 vérifications"' > .factory-verify
verifier "résumé de la suite de la factory reconnu (succès)" 0 "^Tests : TESTS OK : 142 vérifications$" scripts/verify-clean.sh
echo 'echo "TESTS EN ECHEC : 2 sur 145"; exit 1' > .factory-verify
verifier "résumé de la suite de la factory reconnu (échec)" 1 "^Tests : TESTS EN ECHEC : 2 sur 145$" scripts/verify-clean.sh
git add -A >/dev/null 2>&1
unset TMPDIR

echo "sync.sh et init-projet.sh"
p="$(mktemp -d "$racine_tmp/s.XXXXXX")"; mkdir "$p/depot"; cp -R "$factory" "$p/depot/factory"; rm -rf "$p/depot/factory/scripts/tests"; cd "$p/depot" || exit 1
git init -q .
export HOME="$p/home"; mkdir -p "$HOME"
verifier "init : crée les fichiers" 0 "créé +AGENTS.md" ./factory/init-projet.sh --nom 'A&B/C | x'
[ -f .github/pull_request_template.md ] && ok "init : modèle de PR créé" || ko "init : modèle de PR créé"
[ -f README.md ] && head -1 README.md | grep -qF '# A&B/C | x' && ok "init : README.md racine créé avec le nom du projet" || ko "init : README.md racine créé" "$(head -1 README.md 2>&1)"
head -1 AGENTS.md | grep -qF '# A&B/C | x' && ok "nom du projet substitué (caractères spéciaux)" || ko "nom du projet substitué" "$(head -1 AGENTS.md)"
[ "$(cat .factory-version 2>/dev/null)" = "$(tr -d '[:space:]' < factory/VERSION)" ] && ok "init : .factory-version écrit" || ko "init : .factory-version écrit"
echo "0.0.1" > .factory-version
verifier "init : version différente signalée et mise à jour" 0 "mis à jour .factory-version \(0.0.1 ->" ./factory/init-projet.sh
echo "MODIFIÉ" >> AGENTS.md
verifier "init : relance sans rien écraser" 0 "conservé +AGENTS.md" ./factory/init-projet.sh
tail -1 AGENTS.md | grep -q MODIFIÉ && ok "AGENTS.md modifié est conservé" || ko "AGENTS.md modifié est conservé"
[ -f .claude/agents/developer.md ] && grep -q '^tools: Read, Write, Edit, Glob, Grep, Bash$' .claude/agents/developer.md && ok "agent généré avec les outils de l'en-tête (sans suivi de progression)" || ko "agent généré" "$(cat .claude/agents/developer.md 2>&1 | head -6)"
[ ! -e factory/prompts/orchestrator.md ] && [ ! -e .claude/agents/orchestrator.md ] && ok "pas de prompt ni d'agent orchestrateur (rôle de la session principale)" || ko "pas de prompt ni d'agent orchestrateur"
[ -L scripts/dashboard.sh ] && [ "$(readlink scripts/dashboard.sh)" = "../factory/scripts/dashboard.sh" ] && [ -x scripts/dashboard.sh ] && ok "init : scripts/dashboard.sh lié (lien relatif vers factory/scripts/)" || ko "init : lien scripts/dashboard.sh" "$(ls -l scripts/ 2>&1 | tr '\n' '|')"
grep -qx 'dashboard.html' .gitignore && ok "init : dashboard.html dans le .gitignore créé" || ko "init : dashboard.html dans le .gitignore" "$(grep -n html .gitignore)"
[ -f .factory.conf ] && grep -qx 'MAX_ITERATIONS_REVUE=3' .factory.conf && grep -qx 'NOTIFICATION_COMMANDE=' .factory.conf && grep -qx 'NOTIFICATION_DESTINATAIRE=' .factory.conf && grep -qx 'NOTIFICATION_EXPEDITEUR=' .factory.conf && ok "init : .factory.conf créé (3 itérations, notification vide)" || ko "init : .factory.conf créé" "$(cat .factory.conf 2>&1 | grep -v '^#' | tr '\n' '|')"
grep -qx '.factory.local.conf' .gitignore && ok "init : .factory.local.conf dans le .gitignore créé" || ko "init : .factory.local.conf dans le .gitignore"
rappel="Notifications : renseignez NOTIFICATION_COMMANDE et NOTIFICATION_DESTINATAIRE dans .factory.local.conf (non versionné) pour être prévenu d'une issue bloquée en revue."
printf '%s\n' "$(./factory/init-projet.sh 2>&1)" | grep -qxF "$rappel" && ok "init : rappel de renseigner .factory.local.conf" || ko "init : rappel .factory.local.conf"
printf 'NOTIFICATION_COMMANDE=sendmail\nNOTIFICATION_DESTINATAIRE=moi@example.com\n' > .factory.local.conf
printf '%s\n' "$(./factory/init-projet.sh 2>&1)" | grep -qF "Notifications :" && ko "init : plus de rappel une fois la notification configurée" || ok "init : plus de rappel une fois la notification configurée"
rm .factory.local.conf
# Migration 1.8.0 : l'ancien lien du script renommé est mort ; init-projet.sh le signale avec la commande, sans rien supprimer.
ln -s ../factory/scripts/tableau-de-bord.sh scripts/tableau-de-bord.sh
out="$(./factory/init-projet.sh 2>&1)"
printf '%s\n' "$out" | grep -qxF "à supprimer scripts/tableau-de-bord.sh : lien mort (script retiré ou renommé), supprimez-le : rm scripts/tableau-de-bord.sh" && [ -L scripts/tableau-de-bord.sh ] && ok "migration : lien mort dans scripts/ signalé avec la commande rm, jamais supprimé" || ko "migration : lien mort signalé" "$(printf '%s' "$out" | grep -n 'scripts/' | tr '\n' '|')"
rm scripts/tableau-de-bord.sh
out="$(./factory/init-projet.sh 2>&1)"; printf '%s' "$out" | grep -q 'à supprimer' && ko "migration : plus de message une fois le lien mort supprimé" "$out" || ok "migration : plus de message une fois le lien mort supprimé"
mkdir -p "$HOME/.claude/plugins"; echo '{"plugins":{"savvy-progress@x":[]}}' > "$HOME/.claude/plugins/installed_plugins.json"
./factory/sync.sh >/dev/null && grep -q 'mcp__savvy-progress__step' .claude/agents/developer.md && ok "suivi de progression ajouté si le plugin est installé" || ko "suivi de progression ajouté"
! grep -q '3 à 8' .claude/agents/developer.md && grep -q 'selon la mission' .claude/agents/developer.md && grep -q 'ajuste' .claude/agents/developer.md && grep -q 'sans plancher ni plafond' .claude/agents/developer.md && grep -q 'ignore-le et poursuis' .claude/agents/developer.md && ok "suivi de progression : nombre d'étapes dynamique (plus de « 3 à 8 »), garde-fous conservés" || ko "suivi de progression dynamique" "$(grep -n 'étape' .claude/agents/developer.md)"
printf -- '---\nname: casse\ntools: Read\n---\n' > factory/prompts/casse.md
verifier "en-tête incomplet (sans description) = erreur" 1 "En-tête incomplet" ./factory/sync.sh
rm factory/prompts/casse.md

echo "sync.sh (neutre) et sync-claude.sh (Claude Code)"
depot_sync() { # depot_sync <nom> : copie de la factory dans un dépôt vide
  local d="$p/$1"; mkdir "$d"; cp -R "$factory" "$d/factory"; rm -rf "$d/factory/scripts/tests"; git -C "$d" init -q .; printf '%s' "$d"
}
instantane() { (cd "$1" && find .claude .agents -type l -exec sh -c 'printf "L %s -> %s\n" "$1" "$(readlink "$1")"' _ {} \; 2>/dev/null; find .claude/agents -type f -exec sh -c 'echo "F $1"; cat "$1"' _ {} \; 2>/dev/null | cat) | sort; }
d="$(depot_sync s-sans)"; cd "$d" || exit 1; touch CLAUDE.md
verifier "sync.sh --sans-claude : réussit" 0 "" ./factory/sync.sh --sans-claude
[ -L .agents/skills ] && [ "$(readlink .agents/skills)" = "../factory/skills" ] && ok "--sans-claude : .agents/skills créé" || ko "--sans-claude : .agents/skills créé"
[ ! -e .claude/skills ] && [ ! -e .claude/agents ] && ok "--sans-claude : ni .claude/skills ni .claude/agents (malgré CLAUDE.md)" || ko "--sans-claude : rien de Claude" "$(ls -A .claude 2>&1)"
d="$(depot_sync s-avec)"; cd "$d" || exit 1; touch CLAUDE.md
./factory/sync.sh >/dev/null 2>&1; instantane "$d" > "$d/apres-sync.txt"
rm -rf .claude; ./factory/sync-claude.sh >/dev/null 2>&1; ln -sfn ../factory/skills .agents/skills; instantane "$d" > "$d/apres-claude.txt"
[ -s "$d/apres-sync.txt" ] && cmp -s "$d/apres-sync.txt" "$d/apres-claude.txt" && grep -q '^F .claude/agents/developer.md' "$d/apres-sync.txt" && grep -q '^L .claude/skills' "$d/apres-sync.txt" && ok "sync.sh avec CLAUDE.md : mêmes agents et liens que sync-claude.sh seul" || ko "sync.sh avec CLAUDE.md = sync-claude.sh" "$(diff "$d/apres-sync.txt" "$d/apres-claude.txt" 2>&1 | head -5)"
d="$(depot_sync s-dossier)"; cd "$d" || exit 1; mkdir .claude
./factory/sync.sh >/dev/null 2>&1; [ ! -e .claude/skills ] && [ ! -e .claude/agents ] && ok "dossier .claude/ seul (sans CLAUDE.md) : pas de mode Claude" || ko "dossier .claude/ seul : pas de mode Claude" "$(ls -A .claude 2>&1 | tr '\n' ' ')"
d="$(depot_sync s-nu)"; cd "$d" || exit 1
verifier "projet sans CLAUDE.md ni .claude : sync.sh réussit" 0 "" ./factory/sync.sh
[ -L .agents/skills ] && [ ! -e .claude ] && ok "projet sans CLAUDE.md ni .claude : rien de Claude créé" || ko "projet sans CLAUDE.md ni .claude" "$(ls -A 2>&1 | tr '\n' ' ')"
./factory/sync.sh --claude >/dev/null 2>&1; [ -L .claude/skills ] && [ -f .claude/agents/spec-writer.md ] && ok "--claude force l'appel de sync-claude.sh" || ko "--claude force l'appel"
d="$(depot_sync s-seul)"; cd "$d" || exit 1
verifier "sync-claude.sh seul : réussit et annonce ses agents" 0 "developer" ./factory/sync-claude.sh
[ -L .claude/skills ] && [ -f .claude/agents/code-reviewer.md ] && [ ! -e .agents ] && ok "sync-claude.sh seul : .claude/skills et agents, pas .agents" || ko "sync-claude.sh seul"
verifier "sync.sh : option inconnue = 64 et usage" 64 "Usage" ./factory/sync.sh --bidon
verifier "sync-claude.sh : option inconnue = 64 et usage" 64 "Usage" ./factory/sync-claude.sh --bidon
verifier "sync.sh : --claude et --sans-claude ensemble = 64" 64 "Usage" ./factory/sync.sh --claude --sans-claude
d="$(depot_sync s-vide)"; cd "$d" || exit 1
rm -f factory/prompts/*.md; printf '# Prompt sans en-tête\n' > factory/prompts/libre.md
bash_ancien=/bin/bash; [ -x "$bash_ancien" ] || bash_ancien="$BASH"
verifier "sync-claude.sh sans aucun agent à générer, sous $("$bash_ancien" -c 'echo "bash $BASH_VERSION"') (set -u)" 0 "agents :" "$bash_ancien" ./factory/sync-claude.sh

echo "sync-claude.sh : modèle et effort des agents"
d="$(depot_sync s-modele)"; cd "$d" || exit 1
entete_agent() { sed -n '/^---$/,/^---$/p' ".claude/agents/$1.md"; }
a_champ() { entete_agent "$1" | grep -qx "$2"; }
./factory/sync-claude.sh >/dev/null 2>&1
a_champ developer 'model: opus' && a_champ code-reviewer 'model: opus' && a_champ spec-writer 'model: opus' && ok "sans configuration : modèle opus pour chaque agent" || ko "modèle par défaut"
a_champ developer 'effort: low' && a_champ code-reviewer 'effort: low' && a_champ spec-writer 'effort: low' && ok "sans configuration : effort low pour chaque agent" || ko "effort par défaut"
printf 'AGENT_MODELE=sonnet\nAGENT_EFFORT=high\n' > .factory.conf; ./factory/sync-claude.sh >/dev/null 2>&1
a_champ developer 'model: sonnet' && a_champ developer 'effort: high' && ok ".factory.conf choisit le modèle et l'effort" || ko ".factory.conf modèle et effort"
printf 'AGENT_EFFORT=medium\n' > .factory.local.conf; ./factory/sync-claude.sh >/dev/null 2>&1
a_champ developer 'effort: medium' && ok ".factory.local.conf l'emporte sur .factory.conf" || ko ".factory.local.conf effort"
FACTORY_AGENT_MODELE=claude-opus-5-5 FACTORY_AGENT_EFFORT=max ./factory/sync-claude.sh >/dev/null 2>&1
a_champ developer 'model: claude-opus-5-5' && a_champ developer 'effort: max' && ok "FACTORY_AGENT_* l'emporte sur les fichiers" || ko "FACTORY_AGENT_*"
rm -f .factory.local.conf; printf 'AGENT_MODELE=\nAGENT_EFFORT=\n' > .factory.conf; ./factory/sync-claude.sh >/dev/null 2>&1
! entete_agent developer | grep -qE '^(model|effort):' && ok "valeur vide : champ absent, l'agent hérite de la session" || ko "valeur vide"
printf 'AGENT_MODELE=opus\nAGENT_EFFORT=low\n' > .factory.conf; ./factory/sync-claude.sh >/dev/null 2>&1; cp .claude/agents/developer.md "$p/developer-avant.md"
printf 'AGENT_EFFORT=extreme\n' > .factory.conf
verifier_exact "effort hors liste refusé (64, sans recopier la valeur)" 64 "AGENT_EFFORT invalide : low, medium, high, xhigh, max ou vide attendu (voir .factory.conf, .factory.local.conf, FACTORY_AGENT_EFFORT)." ./factory/sync-claude.sh
printf 'AGENT_MODELE=opus\ntools: Bash\n' > .factory.conf; printf 'AGENT_MODELE=opus tools: Bash\n' > .factory.local.conf
verifier_exact "cs_config modèle avec espace et deux-points refusé : aucun champ injecté dans l'en-tête" 64 "AGENT_MODELE invalide : minuscules, chiffres, points et tirets, ou vide attendu (voir .factory.conf, .factory.local.conf, FACTORY_AGENT_MODELE)." ./factory/sync-claude.sh
cmp -s .claude/agents/developer.md "$p/developer-avant.md" && ok "valeur refusée : enveloppes inchangées" || ko "enveloppe modifiée malgré une valeur refusée"
rm -f .factory.local.conf .factory.conf
awk 'NR==2{print; print "model: haiku"; print "effort: high"; next}1' factory/prompts/developer.md > "$p/dev.md" && cp "$p/dev.md" factory/prompts/developer.md
./factory/sync-claude.sh >/dev/null 2>&1
a_champ developer 'model: haiku' && a_champ developer 'effort: high' && a_champ code-reviewer 'model: opus' && ok "l'en-tête d'un prompt l'emporte pour ce rôle seulement" || ko "en-tête de prompt"
config_liste="$(bash factory/scripts/config-factory.sh 2>/dev/null)"
printf '%s\n' "$config_liste" | grep -qx 'AGENT_MODELE=opus' && printf '%s\n' "$config_liste" | grep -qx 'AGENT_EFFORT=low' && ok "config-factory.sh affiche les valeurs par défaut du modèle et de l'effort" || ko "config-factory.sh modèle et effort" "$config_liste"

echo "init-projet.sh --sans-claude"
d="$(depot_sync i-sans)"; cd "$d" || exit 1
verifier "init --sans-claude : réussit" 0 "créé +AGENTS.md" ./factory/init-projet.sh --sans-claude
[ ! -e CLAUDE.md ] && [ ! -e .claude ] && ok "init --sans-claude : ni CLAUDE.md ni dossier .claude/" || ko "init --sans-claude : rien de Claude" "$(ls -A 2>&1 | tr '\n' ' ')"
[ -L .agents/skills ] && [ -f AGENTS.md ] && [ -f .github/workflows/ci.yml ] && ok "init --sans-claude : .agents/skills, AGENTS.md et CI créés" || ko "init --sans-claude : fichiers neutres"
verifier "init --sans-claude relancé : toujours rien de Claude" 0 "" ./factory/init-projet.sh --sans-claude
[ ! -e CLAUDE.md ] && [ ! -e .claude ] && ok "init --sans-claude relancé : ni CLAUDE.md ni .claude/" || ko "init --sans-claude relancé" "$(ls -A 2>&1 | tr '\n' ' ')"
verifier "init : option inconnue = 64 et usage citant --sans-claude" 64 "Usage.*--sans-claude" ./factory/init-projet.sh --bidon

echo "init-projet.sh --stack"
mkdir "$p/stackpy"; cp -R "$factory" "$p/stackpy/factory"; rm -rf "$p/stackpy/factory/scripts/tests"; cd "$p/stackpy" || exit 1
git init -q .
verifier "stack inconnue = 64" 64 "Stack inconnue" ./factory/init-projet.sh --stack cobol
verifier "stack python : CI Python créée" 0 "créé +\.github/workflows/ci.yml" ./factory/init-projet.sh --stack python
grep -q 'setup-python' .github/workflows/ci.yml && ! grep -q 'mvnw' .github/workflows/ci.yml && ok "ci.yml de la stack python (sans Maven)" || ko "ci.yml de la stack python"
grep -q 'package-ecosystem: pip' .github/dependabot.yml && ok "dependabot pip" || ko "dependabot pip"
[ "$(cat .factory-verify)" = "python3 -m unittest discover -s tests -t ." ] && ok ".factory-verify de la stack python" || ko ".factory-verify de la stack python" "$(cat .factory-verify 2>&1)"
grep -q '__pycache__' .gitignore && ! grep -q 'maven' .gitignore && ok ".gitignore complété pour python (sans Maven)" || ko ".gitignore complété pour python"
mkdir "$p/stackj"; cp -R "$factory" "$p/stackj/factory"; rm -rf "$p/stackj/factory/scripts/tests"; cd "$p/stackj" || exit 1
git init -q .; printf 'mon-gitignore\n' > .gitignore
verifier "stack java-maven avec .gitignore existant : lignes à ajouter signalées" 0 "à faire +\.gitignore existait déjà" ./factory/init-projet.sh --stack java-maven
out="$(cat .gitignore)"; [ "$out" = "mon-gitignore" ] && ok ".gitignore existant intact" || ko ".gitignore existant intact"
printf '%s\n' "$(./factory/init-projet.sh --stack java-maven 2>&1)" | grep -qxF "à faire    .gitignore : ajoutez la ligne .factory.local.conf (configuration personnelle, à ne pas versionner)" && ok ".gitignore existant sans .factory.local.conf : ligne à ajouter signalée" || ko ".gitignore existant : .factory.local.conf signalé"
grep -q 'mvnw' .github/workflows/ci.yml && ok "ci.yml de la stack java-maven" || ko "ci.yml de la stack java-maven"
mkdir "$p/stackn"; cp -R "$factory" "$p/stackn/factory"; rm -rf "$p/stackn/factory/scripts/tests"; cd "$p/stackn" || exit 1
git init -q .
verifier "sans --stack : squelette et rappel de créer .factory-verify" 0 "créer .factory-verify" ./factory/init-projet.sh
grep -q 'scripts/verify-clean.sh' .github/workflows/ci.yml && ! grep -q 'uses: actions/setup-' .github/workflows/ci.yml && [ ! -e .factory-verify ] && ok "stack aucune : CI neutre, pas de .factory-verify imposé" || ko "stack aucune"

echo "worktree-issue.sh"
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=t@example.com
w="$(nouveau_projet)"; cd "$w" || exit 1
git init -q -b main . && issue_id "$w" 001-01 "À faire" docs/prd/p.md "[CA-01]" "[]" && issue_id "$w" 001-02 "À faire" docs/prd/p.md "[CA-02]" "[001-01]"
git add -A >/dev/null && git commit -qm "socle"
nomw="$(basename "$w")"; dossier1="$(dirname "$w")/$nomw-001-01"; dossier2="$(dirname "$w")/$nomw-001-02"
verifier "creer : dossier, branche et base affichés" 0 "branche : feat/001-01-x" scripts/worktree-issue.sh creer 001-01
[ -d "$dossier1" ] && [ "$(git -C "$dossier1" rev-parse --abbrev-ref HEAD)" = "feat/001-01-x" ] && ok "le worktree est sur la branche de l'issue" || ko "le worktree est sur la branche de l'issue"
verifier "creer deux fois : refusé" 1 "existe déjà" scripts/worktree-issue.sh creer 001-01
verifier "creer : issue inconnue = 64" 64 "Issue introuvable" scripts/worktree-issue.sh creer 999
echo "travail" > "$dossier1/f.txt" && git -C "$dossier1" add -A && git -C "$dossier1" commit -qm "feat: travail"
verifier "creer --base (branches empilées)" 0 "branche : feat/001-02-x" scripts/worktree-issue.sh creer 001-02 --base feat/001-01-x
[ -f "$dossier2/f.txt" ] && ok "la branche empilée contient le travail de la précédente" || ko "la branche empilée contient le travail de la précédente"
verifier "nettoyer : refusé tant que la branche n'est pas fusionnée" 1 "n'est pas fusionnée" scripts/worktree-issue.sh nettoyer 001-01
git merge -q --no-ff feat/001-01-x -m "Merge feat/001-01-x" >/dev/null
verifier "nettoyer --branche après fusion" 0 "supprimé" scripts/worktree-issue.sh nettoyer 001-01 --branche
[ ! -d "$dossier1" ] && ! git show-ref --verify --quiet refs/heads/feat/001-01-x && ok "dossier et branche supprimés" || ko "dossier et branche supprimés"
verifier "lister" 0 "$nomw-001-02" scripts/worktree-issue.sh lister
verifier "commande inconnue = 64" 64 "" scripts/worktree-issue.sh danser

echo "modèle de branches (develop)"
w="$(nouveau_projet)"; cd "$w" || exit 1
git init -q -b main . && issue_id "$w" 002-01 "À faire" docs/prd/p.md "[CA-01]" "[]" && issue_id "$w" 002-02 "À faire" docs/prd/p.md "[CA-02]" "[]" && issue_id "$w" 002-03 "À faire" docs/prd/p.md "[CA-03]" "[]"
git add -A >/dev/null && git commit -qm "socle"
nomw="$(basename "$w")"
verifier "creer sans develop : retombe sur main" 0 "\(main\)" scripts/worktree-issue.sh creer 002-01
git checkout -q -b develop && echo "d" > d.txt && git add -A >/dev/null && git commit -qm "chore: develop"
verifier "creer avec develop : la base par défaut est develop" 0 "\(develop\)" scripts/worktree-issue.sh creer 002-02
[ -f "$(dirname "$w")/$nomw-002-02/d.txt" ] && ok "la branche d'issue part de develop" || ko "la branche d'issue part de develop"
verifier "creer --base reste prioritaire sur develop" 0 "\(main\)" scripts/worktree-issue.sh creer 002-03 --base main
d2="$(dirname "$w")/$nomw-002-02"; echo "t" > "$d2/t.txt" && git -C "$d2" add -A && git -C "$d2" commit -qm "feat: travail"
git checkout -q main && git merge -q --no-ff feat/002-02-x -m "fusion dans main seulement" >/dev/null
verifier "nettoyer vérifie la fusion dans develop (pas main)" 1 "n'est pas fusionnée dans develop" scripts/worktree-issue.sh nettoyer 002-02
w="$(nouveau_projet)"; cd "$w" || exit 1
git init -q -b main . && issue_id "$w" 004-01 "À faire" docs/prd/p.md "[CA-01]" "[]"
git add -A >/dev/null && git commit -qm "socle"
distant="$(mktemp -d "$racine_tmp/distant.XXXXXX")"; git clone -q "$w" "$distant/d" && git -C "$distant/d" checkout -q -b develop && echo r > "$distant/d/r.txt" && git -C "$distant/d" add -A && git -C "$distant/d" commit -qm "chore: develop distante"
git remote add origin "$distant/d" && git fetch -q origin
! git show-ref --verify --quiet refs/heads/develop && verifier "creer sans develop locale : repli sur origin/develop" 0 "\(origin/develop\)" scripts/worktree-issue.sh creer 004-01 || ko "develop absente localement (préparation du test)"
[ -f "$(dirname "$w")/$(basename "$w")-004-01/r.txt" ] && ok "la branche d'issue part de origin/develop" || ko "la branche d'issue part de origin/develop"
w="$(nouveau_projet)"; cd "$w" || exit 1
git init -q -b tronc . && issue_id "$w" 005-01 "À faire" docs/prd/p.md "[CA-01]" "[]"
git add -A >/dev/null && git commit -qm "socle"
verifier "creer sans aucune base : message citant origin/develop" 64 "^Aucune base trouvée \(develop, origin/develop, origin/HEAD, main, master\) : passez --base\.$" scripts/worktree-issue.sh creer 005-01
for ci in .github/workflows/ci.yml $(cd "$depot" && ls factory/stacks/*/.github/workflows/ci.yml); do
  contenu="$(lire_depot "$depot" "$ci")"
  declencheurs="$(printf '%s\n' "$contenu" | awk '/^on:/ { dans = 1; next } dans && /^[^ ]/ { exit } dans { print }')"
  [ "$(printf '%s\n' "$declencheurs" | grep -A1 '^  push:$' | sed -n 2p)" = "    branches: [main, develop]" ] && [ "$(printf '%s\n' "$contenu" | grep -c 'branches:')" -eq 1 ] && printf '%s\n' "$declencheurs" | grep -q '^  pull_request:$' && ok "CI : push sur main et develop, toute PR (même empilée), sans filtre de branche : $ci" || ko "CI : push main/develop et PR sans filtre : $ci" "$(printf '%s' "$declencheurs" | tr '\n' '|')"
done

# [A05] Aucune étape actions/checkout ne laisse le jeton dans .git/config : persist-credentials: false (aucun job ne pousse).
for ci in "$factory/../.github/workflows/ci.yml" "$factory"/stacks/*/.github/workflows/ci.yml; do
  bilan="$(awk '
    /^ *$/ { next }
    /- uses: actions\/checkout@/ { if (dans && !vu) manque++; n++; dans = 1; vu = 0; ind = index($0, "-"); next }
    dans { match($0, /[^ ]/); if (RSTART <= ind) { if (!vu) manque++; dans = 0 } else if ($0 ~ /^ +persist-credentials: false$/) vu = 1 }
    END { if (dans && !vu) manque++; print n + 0, manque + 0 }' "$ci")"
  [ "${bilan% *}" -gt 0 ] && [ "${bilan#* }" -eq 0 ] && ok "CI : chaque actions/checkout a persist-credentials: false : ${ci#"$factory"/../}" || ko "CI : persist-credentials: false sur chaque checkout : $ci" "étapes checkout / sans l'option : $bilan"
done

# Avant l'issue socle, un projet Java n'a pas de pom.xml : setup-java (cache: maven) et ./mvnw échoueraient sur chaque push.
ci_java="$factory/stacks/java-maven/.github/workflows/ci.yml"
etapes_java="$(grep -cE 'uses: actions/setup-java@|run: \./mvnw' "$ci_java")"
gardes_java="$(grep -cF "hashFiles('pom.xml') != ''" "$ci_java")"
[ "$etapes_java" -gt 0 ] && [ "$gardes_java" -eq "$etapes_java" ] && ok "CI java-maven : setup-java et mvnw ne s'exécutent que si pom.xml existe" || ko "CI java-maven : garde pom.xml manquante" "$gardes_java garde(s) pour $etapes_java étape(s)"
grep -qF "hashFiles('pom.xml') == ''" "$ci_java" && grep -q '::notice::' "$ci_java" && ok "CI java-maven : sans pom.xml, le job signale que la vérification est ignorée" || ko "CI java-maven : aucun signalement sans pom.xml"

echo "Mise à jour d'un projet sans Claude Code"
grep -q '\./factory/init-projet\.sh --sans-claude' "$factory/UPGRADE.md" && ok "UPGRADE.md : relancer init-projet.sh --sans-claude pour un projet sans Claude Code" || ko "UPGRADE.md cite init-projet.sh --sans-claude"
migration_170="$(awk '/^## 1\.7\.0$/ { dans = 1; next } dans && /^## / { exit } dans && /^- Migration/ { print }' "$factory/CHANGELOG.md")"
printf '%s' "$migration_170" | grep -q 'init-projet\.sh --sans-claude' && ! printf '%s' "$migration_170" | grep -q 'sync\.sh --claude' && ok "CHANGELOG 1.7.0 : migration avec init-projet.sh --sans-claude, sans le conseil sync.sh --claude" || ko "CHANGELOG 1.7.0 : ligne Migration" "$migration_170"

echo "CI et vérification de ce dépôt (racine)"
# Ces règles visent le dépôt de la factory : la racine d'un projet a sa propre stack, sa CI et son Dependabot.
if est_depot_factory "$depot"; then
  ci_racine="$(lire_depot "$depot" .github/workflows/ci.yml)"
  [ -n "$ci_racine" ] && ! printf '%s\n' "$ci_racine" | grep -qE 'mvnw|setup-java|NVD|maven' && ok "CI racine : ni mvnw, ni setup-java, ni Maven, ni NVD" || ko "CI racine sans Java ni Maven" "$(printf '%s\n' "$ci_racine" | grep -nE 'mvnw|setup-java|NVD|maven' | head -3 | tr '\n' '|')"
  printf '%s\n' "$ci_racine" | grep -qE '^ +- run: \./scripts/verify-clean\.sh$' && ok "CI racine : le job verify lance ./scripts/verify-clean.sh" || ko "CI racine : appel de ./scripts/verify-clean.sh"
  [ "$(printf '%s\n' "$ci_racine" | grep -E 'uses:' | sed 's/^ *- *//' | sort -u)" = "$(lire_depot "$depot" factory/stacks/aucune/.github/workflows/ci.yml | grep -E 'uses:' | sed 's/^ *- *//' | sort -u)" ] && ok "CI racine : mêmes actions et empreintes que le modèle aucune" || ko "CI racine : actions épinglées comme le modèle aucune" "$(printf '%s\n' "$ci_racine" | grep -E 'uses:' | tr '\n' '|')"
  [ "$(lire_depot "$depot" .factory-verify | head -1)" = "factory/scripts/tests/run.sh" ] && ok ".factory-verify racine : désigne factory/scripts/tests/run.sh" || ko ".factory-verify racine" "$(lire_depot "$depot" .factory-verify | head -1)"
  dependabot_racine="$(lire_depot "$depot" .github/dependabot.yml)"
  ! printf '%s\n' "$dependabot_racine" | grep -q 'package-ecosystem: maven' && printf '%s\n' "$dependabot_racine" | grep -q 'package-ecosystem: github-actions' && ok "dependabot racine : github-actions seulement, pas de maven" || ko "dependabot racine" "$(printf '%s\n' "$dependabot_racine" | grep -n 'package-ecosystem' | tr '\n' '|')"
else
  echo "  ignoré : ce dépôt est un projet, pas le dépôt de la factory"
fi

echo "Dépôt de la factory ou projet"
est_depot_factory "$(nouveau_projet)"; [ $? -eq 1 ] && ok "un projet n'est pas le dépôt de la factory" || ko "un projet pris pour le dépôt de la factory"
[ ! -e "$factory/templates/.factory-depot" ] && ok "le marqueur .factory-depot n'est pas copié dans les projets" || ko "marqueur .factory-depot dans les modèles"
# Les deux signaux se gardent l'un l'autre : perdre le marqueur ne doit pas désactiver en silence les vérifications de la racine.
if [ "$(lire_depot "$depot" .factory-verify | head -1)" = "factory/scripts/tests/run.sh" ]; then
  est_depot_factory "$depot"; [ $? -eq 0 ] && ok "dépôt de la factory : marqueur .factory-depot présent" || ko "dépôt de la factory sans marqueur .factory-depot"
fi

echo "noms de fichiers *.md en anglais"
p="$(mktemp -d "$racine_tmp/n.XXXXXX")"; mkdir "$p/depot"; cp -R "$factory" "$p/depot/factory"; rm -rf "$p/depot/factory/scripts/tests"; cd "$p/depot" || exit 1
git init -q .; export HOME="$p/home"; mkdir -p "$HOME"
./factory/init-projet.sh >/dev/null 2>&1
[ -f docs/lessons.md ] && [ -f docs/issues/_template.md ] && ok "init : docs/lessons.md et docs/issues/_template.md créés" || ko "init : docs/lessons.md et docs/issues/_template.md créés"
[ ! -e docs/lecons.md ] && [ ! -e docs/issues/_modele.md ] && ok "init : aucun ancien nom créé" || ko "init : aucun ancien nom créé"
anciens='lecons|_modele|LECONS|DEMARRER-UN-PROJET|MISE-A-JOUR'
# Les anciens noms ne subsistent que dans l'historique (CHANGELOG), la migration (init-projet.sh) et ce test.
restes_anciens_noms() { chercher_depot "$1" "$anciens" factory/CHANGELOG.md factory/init-projet.sh factory/scripts/tests/run.sh; }
restes="$(restes_anciens_noms "$depot" | head -5 | tr '\n' '|')"
[ -z "$restes" ] && ok "aucun ancien nom de fichier .md dans le dépôt (hors CHANGELOG, migration et test)" || ko "aucun ancien nom de fichier .md dans le dépôt" "$restes"
# Mutation : la vérification doit aussi mordre hors dépôt git (copie de verify-clean.sh, donc la CI), avec les mêmes exclusions.
copie_sans_git="$(mktemp -d "$racine_tmp/s.XXXXXX")"; mkdir -p "$copie_sans_git/factory/scripts/tests" "$copie_sans_git/docs"
for exclu in factory/CHANGELOG.md factory/init-projet.sh factory/scripts/tests/run.sh; do echo "docs/lecons.md" > "$copie_sans_git/$exclu"; done
[ -z "$(restes_anciens_noms "$copie_sans_git")" ] && ok "hors dépôt git : CHANGELOG, init-projet.sh et run.sh restent exclus" || ko "hors dépôt git : exclusions" "$(restes_anciens_noms "$copie_sans_git" | head -3 | tr '\n' '|')"
echo "voir docs/lecons.md" > "$copie_sans_git/docs/README.md"
restes_anciens_noms "$copie_sans_git" | grep -q '^docs/README.md:1:voir docs/lecons.md$' && ok "hors dépôt git : un ancien nom est détecté (pas de vérification à vide)" || ko "hors dépôt git : un ancien nom est détecté" "$(restes_anciens_noms "$copie_sans_git" | head -3 | tr '\n' '|')"
git -C "$copie_sans_git" init -q && git -C "$copie_sans_git" add -A && git -C "$copie_sans_git" -c user.name=t -c user.email=t@example.com commit -qm "chore: copie"
restes_anciens_noms "$copie_sans_git" | grep -q '^HEAD:docs/README.md:1:voir docs/lecons.md$' && ok "dépôt git : un ancien nom commité est détecté (lecture depuis HEAD)" || ko "dépôt git : un ancien nom commité est détecté" "$(restes_anciens_noms "$copie_sans_git" | head -3 | tr '\n' '|')"
# Renommage 1.8.0 (dashboard) : l'ancien nom ne subsiste que dans le CHANGELOG (historique et migration) et ce test.
restes="$(chercher_depot "$depot" -i "tableau.de.bord" factory/CHANGELOG.md factory/scripts/tests/run.sh | head -5 | tr '\n' '|')"
[ -z "$restes" ] && ok "plus aucune mention de l'ancien nom du dashboard (hors CHANGELOG et ce test)" || ko "mentions de l'ancien nom du dashboard" "$restes"
[ -f "$factory/LESSONS.md" ] && [ -f "$factory/START-A-PROJECT.md" ] && [ -f "$factory/UPGRADE.md" ] && ok "factory/LESSONS.md, START-A-PROJECT.md et UPGRADE.md existent" || ko "fichiers de factory/ renommés"
p="$(mktemp -d "$racine_tmp/m.XXXXXX")"; mkdir "$p/depot"; cp -R "$factory" "$p/depot/factory"; rm -rf "$p/depot/factory/scripts/tests"; cd "$p/depot" || exit 1
git init -q .; mkdir -p docs/issues; echo "mes leçons" > docs/lecons.md; echo "mon modèle" > docs/issues/_modele.md
verifier "migration : l'ancien docs/lecons.md reçoit un message git mv" 0 "git mv docs/lecons.md docs/lessons.md" ./factory/init-projet.sh
verifier "migration : l'ancien _modele.md reçoit un message git mv" 0 "git mv docs/issues/_modele.md docs/issues/_template.md" ./factory/init-projet.sh
[ ! -e docs/lessons.md ] && [ ! -e docs/issues/_template.md ] && ok "migration : aucun doublon créé" || ko "migration : aucun doublon créé"
[ "$(cat docs/lecons.md)" = "mes leçons" ] && ok "migration : l'ancien fichier est intact" || ko "migration : l'ancien fichier est intact"
mv docs/lecons.md docs/lessons.md && mv docs/issues/_modele.md docs/issues/_template.md
out="$(./factory/init-projet.sh 2>&1)"; printf '%s' "$out" | grep -q 'git mv' && ko "migration : plus de message après renommage" "$out" || ok "migration : plus de message après renommage"
p="$(nouveau_projet)"; cd "$p" || exit 1
cp "$factory/templates/docs/issues/_template.md" docs/issues/_template.md 2>/dev/null; issue_id "$p" 003-01 "À faire" docs/prd/p.md "[CA-01]" "[]"
out="$(scripts/etat-issues.sh 2>&1)"; printf '%s' "$out" | grep -q '003-01' && ! printf '%s' "$out" | grep -q '_template' && ok "etat-issues.sh ignore _template.md" || ko "etat-issues.sh ignore _template.md" "$out"
verifier "couverture-prd.sh et criteres-sans-test.sh lisent les issues avec _template.md présent" 1 "" scripts/criteres-sans-test.sh 003-01

echo "config-factory.sh (configuration du projet : .factory.conf, .factory.local.conf, variables FACTORY_*)"
p="$(nouveau_projet)"; cd "$p" || exit 1
invalide="MAX_ITERATIONS_REVUE invalide : entier >= 1 attendu (voir .factory.conf, .factory.local.conf, FACTORY_MAX_ITERATIONS_REVUE)."
verifier_exact "sans aucune configuration : 3 itérations par défaut" 0 "3" scripts/config-factory.sh --max-iterations
printf '# Commentaire\n\n  # commentaire indenté\nMAX_ITERATIONS_REVUE=7\nNOTIFICATION_COMMANDE=\n' > .factory.conf
verifier_exact ".factory.conf lu (commentaires et lignes vides ignorés)" 0 "7" scripts/config-factory.sh --max-iterations
printf 'MAX_ITERATIONS_REVUE=2\n' > .factory.local.conf
verifier_exact ".factory.local.conf l'emporte sur .factory.conf" 0 "2" scripts/config-factory.sh --max-iterations
verifier_exact "FACTORY_MAX_ITERATIONS_REVUE l'emporte sur les deux fichiers" 0 "9" env FACTORY_MAX_ITERATIONS_REVUE=9 scripts/config-factory.sh --max-iterations
verifier_exact "borne : 1 accepté" 0 "1" env FACTORY_MAX_ITERATIONS_REVUE=1 scripts/config-factory.sh --max-iterations
verifier_exact "borne : 0 refusé (code 64, message exact, sans recopier la valeur)" 64 "$invalide" env FACTORY_MAX_ITERATIONS_REVUE=0 scripts/config-factory.sh --max-iterations
verifier_exact "valeur non numérique (abc) refusée (64)" 64 "$invalide" env FACTORY_MAX_ITERATIONS_REVUE=abc scripts/config-factory.sh --max-iterations
printf 'MAX_ITERATIONS_REVUE=-3\n' > .factory.local.conf
verifier_exact "valeur négative dans un fichier refusée (64)" 64 "$invalide" scripts/config-factory.sh --max-iterations
printf 'MAX_ITERATIONS_REVUE=4\r\n' > .factory.local.conf
verifier_exact "fin de ligne CRLF tolérée" 0 "4" scripts/config-factory.sh --max-iterations
printf '  MAX_ITERATIONS_REVUE = 2  \n' > .factory.local.conf
verifier_exact "ligne indentée, espaces autour de « = » et en fin de valeur acceptés" 0 "2" scripts/config-factory.sh --max-iterations
printf 'MAX_ITERATIONS_REVUEX=3\nMAX_ITERATIONS_REVUE_BIS=3\n' > .factory.local.conf
verifier_exact "clé seulement préfixe d'une autre (MAX_ITERATIONS_REVUEX) : non reconnue" 0 "7" scripts/config-factory.sh --max-iterations
printf 'MAX_ITERATIONS_REVUE = 3; touch pwned5\n' > .factory.local.conf
verifier_exact "cs_config avec espaces autour de « = » : toujours jamais sourcé, valeur refusée" 64 "$invalide" scripts/config-factory.sh --max-iterations
[ ! -e pwned5 ] && ok "cs_config « CLÉ = valeur; commande » n'exécute rien" || ko "cs_config commande exécutée (espaces autour de =)"
printf 'MAX_ITERATIONS_REVUE=5; touch pwned1\n' > .factory.local.conf
verifier_exact "cs_config fichier jamais sourcé : « 5; touch pwned1 » refusée comme invalide" 64 "$invalide" scripts/config-factory.sh --max-iterations
printf 'MAX_ITERATIONS_REVUE=$(touch pwned2)\n' > .factory.local.conf
verifier_exact "cs_config fichier jamais sourcé : « \$(touch pwned2) » refusée comme invalide" 64 "$invalide" scripts/config-factory.sh --max-iterations
printf 'touch pwned3\nMAX_ITERATIONS_REVUE=`touch pwned4`\nSECRET_INCONNU=abc\n' > .factory.local.conf
scripts/config-factory.sh >/dev/null 2>&1; scripts/config-factory.sh --max-iterations >/dev/null 2>&1
[ ! -e pwned1 ] && [ ! -e pwned2 ] && [ ! -e pwned3 ] && [ ! -e pwned4 ] && ok "cs_config aucune commande des fichiers de configuration n'est exécutée" || ko "cs_config commande exécutée depuis la configuration" "$(ls pwned* 2>&1 | tr '\n' ' ')"
printf 'MAX_ITERATIONS_REVUE=6\nNOTIFICATION_DESTINATAIRE=moi@example.com\nSECRET_INCONNU=abc\n' > .factory.local.conf
verifier_exact "sans option : configuration effective, clés connues seulement (dans l'ordre)" 0 "AGENT_MODELE=opus
AGENT_EFFORT=low
MAX_ITERATIONS_REVUE=6
NOTIFICATION_COMMANDE=
NOTIFICATION_DESTINATAIRE=moi@example.com
NOTIFICATION_EXPEDITEUR=
FIN_ISSUE_ARGUMENTS=
FIN_ISSUE_IGNORES_AUTORISES=" scripts/config-factory.sh
verifier "option inconnue = 64 et usage" 64 "^Usage" scripts/config-factory.sh --bidon
printf 'NOTIFICATION_DESTINATAIRE=commun@example.com\nNOTIFICATION_COMMANDE=sendmail -oi\n' >> .factory.conf; printf 'NOTIFICATION_DESTINATAIRE=\n' > .factory.local.conf
out="$(scripts/config-factory.sh)"; printf '%s\n' "$out" | grep -qx 'NOTIFICATION_DESTINATAIRE=' && ok "valeur vide dans .factory.local.conf : efface la valeur de .factory.conf (désactivation locale)" || ko "valeur vide locale prioritaire" "$(scripts/config-factory.sh | tr '\n' '|')"
out="$(env FACTORY_NOTIFICATION_COMMANDE= scripts/config-factory.sh)"; printf '%s\n' "$out" | grep -qx 'NOTIFICATION_COMMANDE=' && ok "variable FACTORY_* définie mais vide : efface la valeur des fichiers" || ko "variable vide prioritaire" "$(env FACTORY_NOTIFICATION_COMMANDE= scripts/config-factory.sh | tr '\n' '|')"

echo "notifier.sh (courriel par commande paramétrable)"
p="$(nouveau_projet)"; cd "$p" || exit 1
mkdir outils; printf 'Constat bloquant restant\nBranche : feat/x\n' > corps.txt
cat > outils/faux-envoi.sh <<'FIN'
#!/bin/sh
# Commande d'envoi factice : écrit ses arguments (un par ligne) et son entrée standard à côté d'elle.
: > "$(dirname "$0")/args.txt"; for a in "$@"; do printf '%s\n' "$a" >> "$(dirname "$0")/args.txt"; done
cat > "$(dirname "$0")/message.txt"
FIN
chmod +x outils/faux-envoi.sh
verifier "sans argument = usage (64), même non configuré" 64 "^Usage" scripts/notifier.sh
verifier "option inconnue = 64" 64 "^Usage" scripts/notifier.sh --bidon
verifier "--sujet sans valeur = 64" 64 "^Usage" scripts/notifier.sh --sujet
verifier "--test et --sujet ensemble = 64" 64 "^Usage" scripts/notifier.sh --test --sujet s
verifier_exact "non configuré : code 3 et message exact" 3 "Notification non envoyée : configuration incomplète (renseignez NOTIFICATION_COMMANDE, NOTIFICATION_DESTINATAIRE dans .factory.local.conf)." scripts/notifier.sh --sujet s --corps-fichier corps.txt
printf 'NOTIFICATION_COMMANDE=%s -a compte\n' "$p/outils/faux-envoi.sh" > .factory.local.conf
verifier_exact "destinataire seul manquant : code 3, message ne citant que lui" 3 "Notification non envoyée : configuration incomplète (renseignez NOTIFICATION_DESTINATAIRE dans .factory.local.conf)." scripts/notifier.sh --sujet s --corps-fichier corps.txt
printf 'NOTIFICATION_DESTINATAIRE=-oQ/tmp/x\n' >> .factory.local.conf
verifier_exact "cs_notif destinataire commençant par « - » refusé (pas d'option injectée dans la commande)" 3 "Notification non envoyée : NOTIFICATION_DESTINATAIRE invalide (une adresse sans espace, ne commençant pas par « - ») ; corrigez-le dans .factory.local.conf." scripts/notifier.sh --sujet s --corps-fichier corps.txt
[ ! -e outils/args.txt ] && ok "cs_notif commande non lancée quand le destinataire est invalide" || ko "commande lancée malgré un destinataire invalide"
printf 'NOTIFICATION_COMMANDE=%s -a compte\nNOTIFICATION_DESTINATAIRE=dest@example.com\nNOTIFICATION_EXPEDITEUR=Factory <factory@example.com>\n' "$p/outils/faux-envoi.sh" > .factory.local.conf
verifier_exact "envoi : code 0 et confirmation" 0 "Notification envoyée à dest@example.com." scripts/notifier.sh --sujet "[factory] 001-02 bloquée après 5 revues" --corps-fichier corps.txt
[ "$(cat outils/args.txt 2>/dev/null)" = "$(printf -- '-a\ncompte\ndest@example.com')" ] && ok "commande découpée en mots, destinataire en dernier argument" || ko "arguments de la commande" "$(tr '\n' '|' < outils/args.txt 2>&1)"
printf 'From: Factory <factory@example.com>\nTo: dest@example.com\nSubject: =?UTF-8?B?W2ZhY3RvcnldIDAwMS0wMiBibG9xdcOpZSBhcHLDqHMgNSByZXZ1?=\n =?UTF-8?B?ZXM=?=\nMIME-Version: 1.0\nContent-Type: text/plain; charset=UTF-8\nContent-Transfer-Encoding: 8bit\n\nConstat bloquant restant\nBranche : feat/x\n' > attendu.txt
cmp -s attendu.txt outils/message.txt && ok "message sur l'entrée standard : From, To, Subject (RFC 2047, valeur connue), en-têtes MIME, ligne vide, corps" || ko "message transmis" "$(diff attendu.txt outils/message.txt 2>&1 | head -6 | tr '\n' '|')"
printf 'NOTIFICATION_COMMANDE=%s\nNOTIFICATION_DESTINATAIRE=dest@example.com\n' "$p/outils/faux-envoi.sh" > .factory.local.conf
printf 'corps lu sur stdin\n' | scripts/notifier.sh --sujet "Essai" >/dev/null 2>&1
[ "$(head -1 outils/message.txt)" = "To: dest@example.com" ] && [ "$(tail -1 outils/message.txt)" = "corps lu sur stdin" ] && ok "sans expéditeur : pas d'en-tête From ; corps lu sur l'entrée standard" || ko "sans expéditeur / corps sur stdin" "$(tr '\n' '|' < outils/message.txt)"
scripts/notifier.sh --sujet "$(printf 'a\r\nBcc: espion@example.com')" --corps-fichier corps.txt >/dev/null 2>&1
! grep -q '^Bcc:' outils/message.txt && grep -qx 'Subject: a  Bcc: espion@example.com' outils/message.txt && [ "$(grep -c '^Subject:' outils/message.txt)" -eq 1 ] && ok "cs_notif CR/LF du sujet neutralisés : aucun en-tête injecté" || ko "injection d'en-tête par le sujet" "$(tr '\n' '|' < outils/message.txt)"
env FACTORY_NOTIFICATION_EXPEDITEUR="$(printf 'x@example.com\r\nBcc: y@example.com')" scripts/notifier.sh --sujet s --corps-fichier corps.txt >/dev/null 2>&1
! grep -q '^Bcc:' outils/message.txt && grep -qx 'From: x@example.com  Bcc: y@example.com' outils/message.txt && [ "$(grep -c '^From:' outils/message.txt)" -eq 1 ] && ok "cs_notif CR/LF de l'expéditeur neutralisés : From sur une seule ligne, aucun en-tête injecté" || ko "injection d'en-tête par l'expéditeur" "$(tr '\r\n' '^|' < outils/message.txt)"
# Sujet RFC 2047 : mots encodés de l'en-tête Subject (pliage compris), un par ligne ; decoder_mot <mot> : texte décodé.
mots_sujet() { awk '/^Subject:/ { sub(/^Subject: /, ""); print; s = 1; next } s && /^ / { sub(/^ /, ""); print; next } { s = 0 }' outils/message.txt; }
lignes_entete() { awk -v n="$1" 'index($0, n ": ") == 1 { print; s = 1; next } s && /^ / { print; next } { s = 0 }' outils/message.txt; } # lignes brutes (pliage compris)
plus_longue() { lignes_entete "$1" | awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }'; }
decoder_mot() { local b="${1#=?UTF-8?B?}"; printf '%s' "${b%?=}" | base64 --decode; }
scripts/notifier.sh --sujet "[factory] 001-02 bloquée après 5 revues" --corps-fichier corps.txt >/dev/null 2>&1
grep -qx 'Subject: =?UTF-8?B?W2ZhY3RvcnldIDAwMS0wMiBibG9xdcOpZSBhcHLDqHMgNSByZXZ1?=' outils/message.txt && grep -qx ' =?UTF-8?B?ZXM=?=' outils/message.txt && [ "$(mots_sujet | while IFS= read -r m; do decoder_mot "$m"; done)" = "[factory] 001-02 bloquée après 5 revues" ] && ok "sujet non ASCII encodé RFC 2047 (=?UTF-8?B?…?=) et décodable" || ko "sujet RFC 2047" "$(grep '^Subject' outils/message.txt)"
printf 'NOTIFICATION_COMMANDE=%s\nNOTIFICATION_DESTINATAIRE=dest@example.com\n' "$p/outils/faux-envoi.sh" > .factory.local.conf
scripts/notifier.sh --sujet "[factory] Essai ASCII 1" --corps-fichier corps.txt >/dev/null 2>&1
grep -qx 'Subject: \[factory\] Essai ASCII 1' outils/message.txt && ok "sujet ASCII pur : inchangé" || ko "sujet ASCII" "$(grep '^Subject' outils/message.txt)"
# 38 octets ASCII puis « é » (2 octets) : la limite du premier mot (39 octets, « Subject: » compris dans les 76 caractères de la ligne)
# tombe au milieu de ce caractère, qui doit passer entier au mot suivant.
long="[factory] 001-02 bloquee apres 5 rev: éèàçô sur la branche feat/001-02-créer 🙂 et encore des accents ÉÈÀ fin"
scripts/notifier.sh --sujet "$long" --corps-fichier corps.txt >/dev/null 2>&1
n=0; trop_long=0; mal_forme=0; decode=""
while IFS= read -r m; do
  n=$((n + 1)); [ "${#m}" -le 75 ] || trop_long=1
  printf '%s' "$m" | LC_ALL=C grep -Eqx '=\?UTF-8\?B\?[A-Za-z0-9+/=]+\?=' || mal_forme=1
  decoder_mot "$m" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1 || mal_forme=1
  decode="$decode$(decoder_mot "$m")"
done <<FIN
$(mots_sujet)
FIN
[ "$n" -ge 2 ] && [ "$trop_long" -eq 0 ] && [ "$mal_forme" -eq 0 ] && [ "$decode" = "$long" ] && ok "sujet long : $n mots encodés de 75 caractères au plus, caractères UTF-8 entiers, décodage concaténé = sujet" || ko "sujet long RFC 2047" "n=$n trop_long=$trop_long mal_forme=$mal_forme ; $(mots_sujet | tr '\n' '|')"
[ "$(plus_longue Subject)" -le 76 ] && [ "$(plus_longue Subject)" -ge 60 ] && ok "sujet long : chaque ligne pliée de l'en-tête Subject fait 76 caractères au plus (RFC 2047 §2), « Subject: » compris" || ko "longueur des lignes Subject" "$(lignes_entete Subject | awk '{ print length($0) }' | tr '\n' ' ')"
nom_long="Fabrique logicielle très spéciale de l'équipe qualité, édition « été »"
env FACTORY_NOTIFICATION_EXPEDITEUR="$nom_long <f@example.com>" scripts/notifier.sh --sujet s --corps-fichier corps.txt >/dev/null 2>&1
nom_decode="$(lignes_entete From | sed -e 's/^From: //' -e 's/^ //' | tr ' ' '\n' | grep '^=?UTF-8?B?' | while IFS= read -r m; do decoder_mot "$m"; done)"
[ "$(plus_longue From)" -le 76 ] && [ "$(lignes_entete From | wc -l | tr -d ' ')" -ge 2 ] && [ "$nom_decode" = "$nom_long" ] && lignes_entete From | grep -q '<f@example.com>$' && ok "expéditeur au nom long : lignes From de 76 caractères au plus, nom décodé intact, adresse conservée" || ko "expéditeur au nom long" "$(lignes_entete From | tr '\n' '|')"
env FACTORY_NOTIFICATION_EXPEDITEUR="Fabrique é <f@example.com>" scripts/notifier.sh --sujet s --corps-fichier corps.txt >/dev/null 2>&1
de="$(grep '^From:' outils/message.txt)"; nom="${de#From: }"; nom="${nom% <f@example.com>}"
[ "${de% <f@example.com>}" != "$de" ] && [ "$(decoder_mot "$nom")" = "Fabrique é" ] && ok "expéditeur : nom non ASCII encodé RFC 2047, adresse intacte" || ko "expéditeur RFC 2047" "$de"
env FACTORY_NOTIFICATION_EXPEDITEUR="Factory <factory@example.com>" scripts/notifier.sh --sujet s --corps-fichier corps.txt >/dev/null 2>&1
grep -qx 'From: Factory <factory@example.com>' outils/message.txt && ok "expéditeur ASCII : inchangé" || ko "expéditeur ASCII" "$(grep '^From:' outils/message.txt)"
rm -f outils/args.txt outils/message.txt
verifier_exact "cs_notif destinataire avec retour à la ligne refusé (code 3)" 3 "Notification non envoyée : NOTIFICATION_DESTINATAIRE invalide (une adresse sans espace, ne commençant pas par « - ») ; corrigez-le dans .factory.local.conf." env FACTORY_NOTIFICATION_DESTINATAIRE="$(printf 'a@example.com\nBcc: x@example.com')" scripts/notifier.sh --sujet s --corps-fichier corps.txt
[ ! -e outils/args.txt ] && [ ! -e outils/message.txt ] && ok "cs_notif destinataire avec retour à la ligne : rien transmis à la commande" || ko "commande lancée malgré un destinataire avec retour à la ligne"
verifier_exact "cs_notif destinataire avec espace refusé (code 3)" 3 "Notification non envoyée : NOTIFICATION_DESTINATAIRE invalide (une adresse sans espace, ne commençant pas par « - ») ; corrigez-le dans .factory.local.conf." env FACTORY_NOTIFICATION_DESTINATAIRE="a@example.com b@example.com" scripts/notifier.sh --sujet s --corps-fichier corps.txt
[ ! -e outils/args.txt ] && ok "cs_notif destinataire avec espace : commande non lancée" || ko "commande lancée malgré un destinataire avec espace"
verifier_exact "--test : message d'essai envoyé" 0 "Notification envoyée à dest@example.com." scripts/notifier.sh --test
grep -qx "Subject: \[factory\] Notification d'essai" outils/message.txt && grep -q "^Message d'essai" outils/message.txt && ok "--test : sujet et corps d'essai" || ko "--test : sujet et corps" "$(tr '\n' '|' < outils/message.txt)"
verifier_exact "commande en échec : code 4 et message" 4 "Notification non envoyée : la commande NOTIFICATION_COMMANDE a échoué (code 1)." env FACTORY_NOTIFICATION_COMMANDE=false scripts/notifier.sh --sujet s --corps-fichier corps.txt
# Commande qui échoue sans lire le message, corps de 1,1 Mo (plus grand que le tampon d'un tube) et SIGPIPE ignoré comme sur les
# exécuteurs GitHub Actions : une écriture vers la commande ne peut alors que finir en « write error: Broken pipe », sur toute machine.
printf '#!/bin/sh\nexit 1\n' > outils/echec-sans-lire.sh; chmod +x outils/echec-sans-lire.sh
head -c 1100000 /dev/zero | tr '\0' 'x' > gros-corps.txt
sans_sigpipe() { (trap '' PIPE; exec "$@"); }
verifier_exact "commande en échec sans lire un gros message (SIGPIPE ignoré) : code 4, message exact, aucun « Broken pipe »" 4 "Notification non envoyée : la commande NOTIFICATION_COMMANDE a échoué (code 1)." sans_sigpipe env FACTORY_NOTIFICATION_COMMANDE="$p/outils/echec-sans-lire.sh" scripts/notifier.sh --sujet s --corps-fichier gros-corps.txt
# Fichier temporaire du message : créé dans TMPDIR (ici un dossier dédié), droits 0600, supprimé après un envoi, un échec ou une interruption.
# Les commandes espions listent TMPDIR pendant l'envoi (preuve que le fichier existait, donc que le dossier vide après n'est pas un faux positif).
mkdir tmp-notif
printf '#!/bin/sh\nls -l "$TMPDIR" > "$(dirname "$0")/tmp-pendant.txt"\ncat > /dev/null\nexit "${ESPION_CODE:-0}"\n' > outils/espion.sh
printf '#!/bin/sh\nls -l "$TMPDIR" > "$(dirname "$0")/tmp-pendant.txt"\necho $$ > "$(dirname "$0")/lent.pid"\nexec sleep 30\n' > outils/espion-lent.sh
chmod +x outils/espion.sh outils/espion-lent.sh
# Droits lus par ls -l : « @ » (attributs étendus, macOS), « . » ou « + » (contexte de sécurité, ACL) peuvent suivre les 10 caractères.
un_fichier_0600() { [ "$(grep -c '^[-dl]' outils/tmp-pendant.txt 2>/dev/null)" = "1" ] && grep -Eq '^-rw-------[@.+ ]' outils/tmp-pendant.txt; }
tmp_vide() { [ -z "$(ls -A tmp-notif)" ]; }
rm -f outils/tmp-pendant.txt
verifier_exact "fichier temporaire : envoi réussi (code 0)" 0 "Notification envoyée à dest@example.com." env TMPDIR="$p/tmp-notif" FACTORY_NOTIFICATION_COMMANDE="$p/outils/espion.sh" scripts/notifier.sh --sujet s --corps-fichier corps.txt
un_fichier_0600 && tmp_vide && ok "fichier temporaire : un seul fichier 0600 pendant l'envoi, aucun après un envoi réussi" || ko "fichier temporaire après envoi réussi" "pendant : $(tr '\n' '|' < outils/tmp-pendant.txt 2>&1) ; après : $(ls -A tmp-notif | tr '\n' ' ')"
rm -f outils/tmp-pendant.txt
verifier_exact "fichier temporaire : commande en échec (code 4)" 4 "Notification non envoyée : la commande NOTIFICATION_COMMANDE a échoué (code 1)." env TMPDIR="$p/tmp-notif" ESPION_CODE=1 FACTORY_NOTIFICATION_COMMANDE="$p/outils/espion.sh" scripts/notifier.sh --sujet s --corps-fichier corps.txt
un_fichier_0600 && tmp_vide && ok "fichier temporaire : aucun après un échec de la commande (code 4)" || ko "fichier temporaire après échec" "pendant : $(tr '\n' '|' < outils/tmp-pendant.txt 2>&1) ; après : $(ls -A tmp-notif | tr '\n' ' ')"
rm -f outils/tmp-pendant.txt outils/lent.pid
env TMPDIR="$p/tmp-notif" FACTORY_NOTIFICATION_COMMANDE="$p/outils/espion-lent.sh" scripts/notifier.sh --sujet s --corps-fichier corps.txt >/dev/null 2>&1 &
pid_notif=$!; n=0
while [ ! -s outils/lent.pid ] && [ "$n" -lt 100 ]; do sleep 0.1; n=$((n + 1)); done
kill -TERM "$pid_notif" 2>/dev/null; [ -s outils/lent.pid ] && kill -TERM "$(cat outils/lent.pid)" 2>/dev/null
wait "$pid_notif"; code_notif=$?
[ "$code_notif" -ne 0 ] && un_fichier_0600 && tmp_vide && ok "fichier temporaire : aucun après une interruption (SIGTERM pendant l'envoi, code $code_notif)" || ko "fichier temporaire après interruption" "code $code_notif ; pendant : $(tr '\n' '|' < outils/tmp-pendant.txt 2>&1) ; après : $(ls -A tmp-notif | tr '\n' ' ')"
verifier "commande introuvable : code 4" 4 "a échoué" env FACTORY_NOTIFICATION_COMMANDE="$p/outils/absente.sh" scripts/notifier.sh --sujet s --corps-fichier corps.txt
verifier "--corps-fichier introuvable = 64" 64 "introuvable" scripts/notifier.sh --sujet s --corps-fichier absent.txt
printf 'NOTIFICATION_COMMANDE=%s ; touch pwned $(touch pwned2)\nNOTIFICATION_DESTINATAIRE=dest@example.com\n' "$p/outils/faux-envoi.sh" > .factory.local.conf
scripts/notifier.sh --sujet s --corps-fichier corps.txt >/dev/null 2>&1
[ ! -e pwned ] && [ ! -e pwned2 ] && [ "$(cat outils/args.txt)" = "$(printf ';\ntouch\npwned\n$(touch\npwned2)\ndest@example.com')" ] && ok "cs_notif commande ni évaluée ni passée à un shell : « ; » et « \$( ) » restent des arguments" || ko "commande évaluée par un shell" "$(ls pwned* 2>&1) $(tr '\n' '|' < outils/args.txt)"

echo "lecture du dépôt pour les vérifications de documentation (HEAD si dépôt git, sinon fichiers)"
d="$(mktemp -d "$racine_tmp/doc.XXXXXX")"; mkdir "$d/git" "$d/copie"
printf 'commité MAX_ITERATIONS_REVUE\n' > "$d/git/AGENTS.md"; printf 'motif-commite\n' > "$d/git/a.md"
git -C "$d/git" init -q . && git -C "$d/git" add -A && git -C "$d/git" -c user.name=t -c user.email=t@example.com commit -qm socle
printf 'non commité\n' > "$d/git/AGENTS.md"; printf 'motif-local\n' > "$d/git/a.md"; printf 'motif-local\n' > "$d/git/nouveau.md"
[ "$(lire_depot "$d/git" AGENTS.md)" = "commité MAX_ITERATIONS_REVUE" ] && ok "dépôt git : lecture depuis HEAD, une modification non commitée ne change rien" || ko "lire_depot depuis HEAD" "$(lire_depot "$d/git" AGENTS.md)"
[ -n "$(chercher_depot "$d/git" 'motif-commite')" ] && [ -z "$(chercher_depot "$d/git" 'motif-local')" ] && ok "dépôt git : recherche dans HEAD (ni fichier modifié ni fichier non suivi)" || ko "chercher_depot dans HEAD" "$(chercher_depot "$d/git" 'motif-')"
printf 'fichier\n' > "$d/copie/AGENTS.md"; mkdir "$d/copie/docs"; printf 'motif-copie\n' > "$d/copie/docs/x.md"; printf 'motif-copie\n' > "$d/copie/docs/exclu.md"
[ "$(lire_depot "$d/copie" AGENTS.md)" = "fichier" ] && [ "$(chercher_depot "$d/copie" 'motif-copie' docs/exclu.md | wc -l | tr -d ' ')" = "1" ] && chercher_depot "$d/copie" 'motif-copie' docs/exclu.md | grep -q 'docs/x.md' && ok "hors dépôt git (copie de verify-clean.sh) : lecture et recherche dans les fichiers, exclusions respectées" || ko "lecture hors dépôt git" "$(chercher_depot "$d/copie" 'motif-copie' docs/exclu.md | tr '\n' '|')"

echo "limite des itérations de revue (documentation)"
restes="$(chercher_depot "$depot" -i "3 itérations|trois itérations" factory/CHANGELOG.md factory/scripts/tests/run.sh | head -5 | tr '\n' '|')"
deliver="$(lire_depot "$depot" factory/skills/deliver/SKILL.md)"; conf_modele="$(lire_depot "$depot" factory/templates/.factory.conf)"
[ -z "$restes" ] && ok "plus aucune limite « 3 itérations » écrite en dur (hors CHANGELOG et ce test)" || ko "limite « 3 itérations » écrite en dur" "$restes"
printf '%s\n' "$deliver" | grep -q 'scripts/config-factory.sh --max-iterations' && printf '%s\n' "$deliver" | grep -q 'scripts/notifier.sh' && ok "/deliver : limite lue par config-factory.sh, blocage notifié par notifier.sh" || ko "/deliver : limite et notification"
printf '%s\n' "$deliver" | grep -q "au moins un BLOQUANT" && printf '%s\n' "$deliver" | grep -q "IMPORTANT.*sans courriel" && ok "/deliver : courriel seulement s'il reste au moins un BLOQUANT (IMPORTANT seuls : remontés sans courriel)" || ko "/deliver : courriel réservé aux BLOQUANT"
printf '%s\n' "$conf_modele" | grep -qx 'NOTIFICATION_COMMANDE=' && printf '%s\n' "$conf_modele" | grep -q 'NOTIFICATION_COMMANDE=sendmail -oi' && [ -z "$(chercher_depot "$depot" -i '(sendmail|mail) +-t([^a-z]|$)' factory/CHANGELOG.md factory/scripts/tests/run.sh)" ] && ok "exemple sendmail -oi (destinataire en argument), aucun exemple avec -t (sendmail ou mail)" || ko "exemple avec -t" "$(chercher_depot "$depot" -i '(sendmail|mail) +-t([^a-z]|$)' factory/CHANGELOG.md factory/scripts/tests/run.sh | head -5 | tr '\n' '|')"
[ "$(lire_depot "$depot" AGENTS.md | grep -c 'MAX_ITERATIONS_REVUE')" -ge 2 ] && [ "$(lire_depot "$depot" factory/templates/AGENTS.md | grep -c 'MAX_ITERATIONS_REVUE')" -ge 2 ] && ok "AGENTS.md et son modèle : limite MAX_ITERATIONS_REVUE aux étapes 4 et 5" || ko "AGENTS.md : MAX_ITERATIONS_REVUE aux étapes 4 et 5"
adresses="$({ printf '%s\n' "$conf_modele"; lire_depot "$depot" .factory.conf; } | grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+' | grep -v '@example\.com$' | tr '\n' ' ')"
[ -n "$conf_modele" ] && [ -z "$adresses" ] && ok "modèle .factory.conf : aucune adresse réelle (example.com seulement)" || ko "adresses du modèle .factory.conf" "$adresses"
lire_depot "$depot" .gitignore | grep -qx '.factory.local.conf' && lire_depot "$depot" factory/templates/.gitignore | grep -qx '.factory.local.conf' && ok ".factory.local.conf ignoré par git (dépôt et modèle)" || ko ".factory.local.conf dans les .gitignore"

echo "règle du framework d'abord (documentation)"
for f in factory/prompts/code-reviewer.md factory/prompts/report-format.md factory/prompts/briefs/developer.md factory/prompts/briefs/reviewer.md factory/skills/deliver/SKILL.md factory/stacks/java-maven/README.md; do
  lire_depot "$depot" "$f" | grep -qi "framework" && ok "$f parle du framework d'abord" || ko "$f : règle du framework absente"
done
lire_depot "$depot" factory/prompts/developer.md | grep -q "Le framework d'abord" && ok "developer.md : règle du framework d'abord" || ko "developer.md : règle du framework absente"
lire_depot "$depot" factory/prompts/report-format.md | grep -q "^## Code écrit à la place du framework$" && lire_depot "$depot" factory/skills/deliver/SKILL.md | grep -q "Code écrit à la place du framework" && ok "section du rapport contrôlée par /deliver" || ko "section du rapport non contrôlée par /deliver"
lire_depot "$depot" factory/prompts/code-reviewer.md | grep -q "écrit à la main.*constat IMPORTANT" && ok "reviewer : équivalent injustifié = IMPORTANT" || ko "reviewer : gravité du constat framework"
lire_depot "$depot" factory/templates/AGENTS.md | grep -q "Le framework d'abord" && lire_depot "$depot" factory/templates/docs/adr/0000-template.md | grep -q "Mécanismes du framework" && ok "modèles AGENTS.md et ADR : règle présente" || ko "modèles AGENTS.md et ADR : règle absente"

echo "référence de code (documentation)"
guide_java=$(lire_depot "$depot" factory/stacks/java-maven/README.md)
for motif in "Spring d'abord, JHipster comme modèle" "raw.githubusercontent.com/jhipster/.*/v[0-9]" "Pas de générateur, pas de clone" "Sans frontend" "| Angular |" "| React |" "| Vue |" "Session et CSRF" "jhipster-framework"; do
  printf '%s\n' "$guide_java" | grep -q "$motif" && ok "guide java : $motif" || ko "guide java : $motif absent"
done
lire_depot "$depot" factory/templates/AGENTS.md | grep -q "La référence de code" && lire_depot "$depot" factory/templates/docs/adr/0000-template.md | grep -q "^### Référence de code$" && ok "modèles AGENTS.md et ADR : référence de code" || ko "modèles AGENTS.md et ADR : référence de code absente"
lire_depot "$depot" factory/prompts/developer.md | grep -q "factory/stacks/<stack>/README.md" && ok "developer.md renvoie au guide de la stack" || ko "developer.md : renvoi au guide de la stack absent"
lire_depot "$depot" factory/prompts/report-format.md | grep -q "^## Alignement sur la référence$" && lire_depot "$depot" factory/skills/deliver/SKILL.md | grep -q "Alignement sur la référence" && ok "alignement du rapport contrôlé par /deliver" || ko "alignement du rapport non contrôlé par /deliver"
lire_depot "$depot" factory/prompts/code-reviewer.md | grep -q "sans raison est un constat IMPORTANT" && ok "reviewer : écart à la référence sans raison = IMPORTANT" || ko "reviewer : gravité de l'écart à la référence"
for f in factory/prompts/briefs/developer.md factory/prompts/briefs/reviewer.md; do
  lire_depot "$depot" "$f" | grep -q "Référence" && ok "$f : champ référence" || ko "$f : champ référence absent"
done

echo "langue du code (documentation)"
for f in factory/templates/AGENTS.md factory/prompts/developer.md factory/prompts/code-reviewer.md factory/stacks/java-maven/README.md; do
  lire_depot "$depot" "$f" | grep -q "classes techniques sont impérativement en anglais" && ok "$f : classes techniques en anglais" || ko "$f : règle de langue absente"
done

echo
if [ "$echecs" -eq 0 ]; then echo "TESTS OK : $total vérifications"; else echo "TESTS EN ECHEC : $echecs sur $total"; fi
[ "$echecs" -eq 0 ]
