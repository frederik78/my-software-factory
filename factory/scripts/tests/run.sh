#!/usr/bin/env bash
# Tests des scripts de la factory (sans dépendance : bash, git, rsync). À lancer depuis n'importe où :
#     factory/scripts/tests/run.sh
# Chaque cas travaille dans un dépôt jetable ; rien n'est écrit dans le dépôt courant. Compatible bash 3.2 (macOS).
set -uo pipefail
# Isolement de l'environnement appelant : verify-clean.sh donne la priorité à COMMANDE_VERIFY, et les bouchons lisent STUB_CODE ;
# hérités (par exemple quand cette suite est elle-même lancée par verify-clean.sh avec COMMANDE_VERIFY), ils fausseraient les cas.
unset COMMANDE_VERIFY STUB_CODE

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
printf '@Test void ca10_x() {}\n// CS-07\n' > src/test/A.java
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
rm -rf src/test; mkdir tests; printf 'ca10 CS-07\n' > tests/t.py
verifier "dossier de tests détecté automatiquement (tests/)" 0 "OK .*2 critère" scripts/criteres-sans-test.sh 001-01
rm -rf tests; verifier "dossier de tests absent = 64" 64 "introuvable" scripts/criteres-sans-test.sh 001-01

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
rm -f generation-en-cours; scripts/dashboard.sh --boucle 1 >/dev/null 2>&1 & pid=$!
n=0; while [ ! -e generation-en-cours ] && [ "$n" -lt 50 ]; do sleep 0.1; n=$((n + 1)); done
kill -TERM "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
restes="$(ls dashboard.html.* 2>/dev/null)"
[ -e generation-en-cours ] && [ -z "$restes" ] && ok "interruption pendant la génération : aucun fichier temporaire résiduel" || ko "fichier temporaire résiduel après interruption" "$restes"
cp "$racine_tmp/etat-issues.sh.orig" factory/scripts/etat-issues.sh; rm -f generation-en-cours dashboard.html*

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
echo 'echo "$#" > args.txt && cat args.txt && echo "Ran 5 tests in 0s"' > .factory-verify
verifier "syntaxe shell (&&) acceptée, arguments transmis" 0 "Ran 5 tests" scripts/verify-clean.sh -- -a -b
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
[ "$(cat .gitignore)" = "mon-gitignore" ] && ok ".gitignore existant intact" || ko ".gitignore existant intact"
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
for ci in "$factory/../.github/workflows/ci.yml" "$factory"/stacks/*/.github/workflows/ci.yml; do
  declencheurs="$(awk '/^on:/ { dans = 1; next } dans && /^[^ ]/ { exit } dans { print }' "$ci")"
  [ "$(printf '%s\n' "$declencheurs" | grep -A1 '^  push:$' | sed -n 2p)" = "    branches: [main, develop]" ] && [ "$(grep -c 'branches:' "$ci")" -eq 1 ] && printf '%s\n' "$declencheurs" | grep -q '^  pull_request:$' && ok "CI : push sur main et develop, toute PR (même empilée), sans filtre de branche : ${ci#"$factory"/../}" || ko "CI : push main/develop et PR sans filtre : $ci" "$(printf '%s' "$declencheurs" | tr '\n' '|')"
done

echo "CI et vérification de ce dépôt (racine)"
ci_racine="$factory/../.github/workflows/ci.yml"
! grep -qE 'mvnw|setup-java|NVD|maven' "$ci_racine" && ok "CI racine : ni mvnw, ni setup-java, ni Maven, ni NVD" || ko "CI racine sans Java ni Maven" "$(grep -nE 'mvnw|setup-java|NVD|maven' "$ci_racine" | head -3 | tr '\n' '|')"
grep -qE '^ +- run: \./scripts/verify-clean\.sh$' "$ci_racine" && ok "CI racine : le job verify lance ./scripts/verify-clean.sh" || ko "CI racine : appel de ./scripts/verify-clean.sh"
[ "$(grep -E 'uses:' "$ci_racine" | sed 's/^ *- *//' | sort -u)" = "$(grep -E 'uses:' "$factory/stacks/aucune/.github/workflows/ci.yml" | sed 's/^ *- *//' | sort -u)" ] && ok "CI racine : mêmes actions et empreintes que le modèle aucune" || ko "CI racine : actions épinglées comme le modèle aucune" "$(grep -E 'uses:' "$ci_racine" | tr '\n' '|')"
[ -f "$factory/../.factory-verify" ] && [ "$(head -1 "$factory/../.factory-verify")" = "factory/scripts/tests/run.sh" ] && ok ".factory-verify racine : désigne factory/scripts/tests/run.sh" || ko ".factory-verify racine" "$(head -1 "$factory/../.factory-verify" 2>&1)"
dependabot_racine="$factory/../.github/dependabot.yml"
! grep -q 'package-ecosystem: maven' "$dependabot_racine" && grep -q 'package-ecosystem: github-actions' "$dependabot_racine" && ok "dependabot racine : github-actions seulement, pas de maven" || ko "dependabot racine" "$(grep -n 'package-ecosystem' "$dependabot_racine" | tr '\n' '|')"

echo "noms de fichiers *.md en anglais"
p="$(mktemp -d "$racine_tmp/n.XXXXXX")"; mkdir "$p/depot"; cp -R "$factory" "$p/depot/factory"; rm -rf "$p/depot/factory/scripts/tests"; cd "$p/depot" || exit 1
git init -q .; export HOME="$p/home"; mkdir -p "$HOME"
./factory/init-projet.sh >/dev/null 2>&1
[ -f docs/lessons.md ] && [ -f docs/issues/_template.md ] && ok "init : docs/lessons.md et docs/issues/_template.md créés" || ko "init : docs/lessons.md et docs/issues/_template.md créés"
[ ! -e docs/lecons.md ] && [ ! -e docs/issues/_modele.md ] && ok "init : aucun ancien nom créé" || ko "init : aucun ancien nom créé"
anciens='lecons|_modele|LECONS|DEMARRER-UN-PROJET|MISE-A-JOUR'
# Les anciens noms ne subsistent que dans l'historique (CHANGELOG), la migration (init-projet.sh) et ce test.
restes="$(git -C "$factory/.." grep -nE "$anciens" -- . ':!factory/CHANGELOG.md' ':!factory/init-projet.sh' ':!factory/scripts/tests/run.sh' 2>/dev/null | head -5 | tr '\n' '|')"
[ -z "$restes" ] && ok "aucun ancien nom de fichier .md dans le dépôt (hors CHANGELOG, migration et test)" || ko "aucun ancien nom de fichier .md dans le dépôt" "$restes"
# Renommage 1.8.0 (dashboard) : l'ancien nom ne subsiste que dans le CHANGELOG (historique et migration) et ce test.
restes="$(git -C "$factory/.." grep -n -i -E "tableau.de.bord" -- . ':!factory/CHANGELOG.md' ':!factory/scripts/tests/run.sh' 2>/dev/null | head -5 | tr '\n' '|')"
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

echo
if [ "$echecs" -eq 0 ]; then echo "TESTS OK : $total vérifications"; else echo "TESTS EN ECHEC : $echecs sur $total"; fi
[ "$echecs" -eq 0 ]
