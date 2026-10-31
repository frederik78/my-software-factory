#!/usr/bin/env bash
# Tests des scripts de la factory (sans dépendance : bash, git, rsync). À lancer depuis n'importe où :
#     factory/scripts/tests/run.sh
# Chaque cas travaille dans un dépôt jetable ; rien n'est écrit dans le dépôt courant. Compatible bash 3.2 (macOS).
set -uo pipefail

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
mkdir -p "$HOME/.claude/plugins"; echo '{"plugins":{"savvy-progress@x":[]}}' > "$HOME/.claude/plugins/installed_plugins.json"
./factory/sync.sh >/dev/null && grep -q 'mcp__savvy-progress__step' .claude/agents/developer.md && ok "suivi de progression ajouté si le plugin est installé" || ko "suivi de progression ajouté"
printf -- '---\nname: casse\ntools: Read\n---\n' > factory/prompts/casse.md
verifier "en-tête incomplet (sans description) = erreur" 1 "En-tête incomplet" ./factory/sync.sh
rm factory/prompts/casse.md

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

echo
if [ "$echecs" -eq 0 ]; then echo "TESTS OK : $total vérifications"; else echo "TESTS EN ECHEC : $echecs sur $total"; fi
[ "$echecs" -eq 0 ]
