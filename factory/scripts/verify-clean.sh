#!/usr/bin/env bash
# Lance la vérification complète du projet dans une COPIE propre du dépôt (hors IDE, comme la CI).
#
# Pourquoi : le serveur Java de VS Code (compilation automatique) peut recompiler les classes générées (par exemple par
# MapStruct) sans le processeur d'annotations et casser le build dans le dépôt.
# Ce qui est copié : exactement ce que Git voit (fichiers suivis + fichiers non suivis non ignorés, `git ls-files -co --exclude-standard`).
# Les fichiers ignorés (.env, data/, target/, clés locales...) ne sont donc jamais recopiés. Hors dépôt Git, repli sur une liste d'exclusions.
#
# Usage : scripts/verify-clean.sh [--keep] [-- <arguments supplémentaires pour la commande de build>]
#   --keep   conserve la copie (affiche son chemin) pour inspecter target/ ; sinon elle est supprimée.
# Commande de build, dans cet ordre : variable COMMANDE_VERIFY ; première ligne du fichier `.factory-verify` à la racine du projet (écriture shell permise : `npm ci && npm test`) ;
# à défaut, le wrapper du projet s'il existe (`./mvnw -B clean verify`, `./gradlew --no-daemon clean build`) ; sinon le script s'arrête (code 64) en demandant de créer `.factory-verify`.
# Les arguments passés après `--` sont ajoutés à la commande (disponibles comme "$@").
# Le résumé chiffré reconnaît la sortie de Maven (« Tests run: n, Failures: … »), celle de unittest/pytest (« Ran n tests »), de jest et de node:test et celle de la suite de la factory (« TESTS OK : n vérifications », « TESTS EN ECHEC : x sur n »).
# Code de sortie : celui du build (0 = tout est vert). Dernière ligne : « VERIFY OK » ou « VERIFY ECHEC (code n) ».
set -uo pipefail

keep=0
mvn_args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --keep) keep=1 ;;
    --) shift; mvn_args=("$@"); break ;;
    *) echo "Argument inconnu : $1" >&2; exit 64 ;;
  esac
  shift
done

depot="$(cd "$(dirname "$0")/.." && pwd)"
copie="$(mktemp -d "${TMPDIR:-/tmp}/verify-clean.XXXXXX")"
journal="$copie/verify.log"

nettoyer() {
  if [ "$keep" -eq 1 ]; then
    echo "Copie conservée : $copie"
  else
    rm -rf "$copie"
  fi
}
trap nettoyer EXIT

mkdir "$copie/src"
if git -C "$depot" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  liste="$copie/fichiers.lst"
  # Chemins existants seulement (un fichier suivi puis supprimé figure encore dans l'index).
  git -C "$depot" ls-files -z -co --exclude-standard | while IFS= read -r -d '' f; do
    if [ -e "$depot/$f" ] || [ -L "$depot/$f" ]; then printf '%s\0' "$f"; fi
  done > "$liste"
  rsync -a --from0 --files-from="$liste" "$depot/" "$copie/src/"
else
  rsync -a \
    --exclude 'target/' --exclude '.git/' --exclude '.env' --exclude '.env.*' --exclude 'data/' \
    --exclude '*.pem' --exclude '*.key' --exclude '.vscode/' --exclude '.idea/' --exclude '.DS_Store' \
    "$depot/" "$copie/src/"
fi

cd "$copie/src" || exit 1
commande="${COMMANDE_VERIFY:-}"
if [ -z "$commande" ] && [ -f .factory-verify ]; then commande="$(head -1 .factory-verify)"; fi
if [ -z "$commande" ] && [ -x ./mvnw ]; then commande='./mvnw -B clean verify "$@"'; fi
if [ -z "$commande" ] && [ -x ./gradlew ]; then commande='./gradlew --no-daemon clean build "$@"'; fi
if [ -z "$commande" ]; then
  echo "Aucune commande de vérification : créez .factory-verify (une ligne, ex. « python3 -m unittest discover -s tests -t . ») ou définissez COMMANDE_VERIFY." >&2
  exit 64
fi
# La commande est interprétée par un shell ; les arguments supplémentaires y sont disponibles sous la forme "$@" (ajoutés à la fin si elle ne l'utilise pas).
case "$commande" in *'"$@"'*|*'$@'*) ;; *) commande="$commande \"\$@\"" ;; esac
bash -c "$commande" verify-clean ${mvn_args[@]+"${mvn_args[@]}"} >"$journal" 2>&1
code=$?

# Plusieurs lanceurs enchaînés (pytest unit && pytest integ) : chaque résumé compte. Un seul : recopié tel quel.
additionner() { # additionner <préfixe> : somme les « n mot » de l'entrée standard
  awk -v pre="$1" '
    { une = $0; nb++
      for (i = 1; i < NF; i++) if ($i ~ /^[0-9]+$/) {
        m = $(i + 1); gsub(/[^a-z]/, "", m); if (m == "error") m = "errors"
        if (!(m in n)) ordre[++k] = m
        n[m] += $i
      } }
    END {
      if (!nb) exit
      if (nb == 1) { print une; exit }
      l = pre; for (j = 1; j <= k; j++) l = l (j > 1 ? ", " : "") n[ordre[j]] " " ordre[j]
      print l
    }'
}

# Maven : une ligne de total par module et par greffon (surefire, failsafe) ; on les additionne pour qu'aucun test ignoré ne se perde.
tests="$(grep -E '^\[(INFO|ERROR|WARNING)\] Tests run: [0-9]+, Failures: [0-9]+, Errors: [0-9]+, Skipped: [0-9]+$' "$journal" | sed -E 's/[^0-9]+/ /g' | awk 'NF { t += $1; f += $2; e += $3; s += $4; n = 1 } END { if (n) printf "Tests run: %d, Failures: %d, Errors: %d, Skipped: %d\n", t, f, e, s }')"
if [ -z "$tests" ]; then
  # unittest : une ligne « Ran n tests » et un verdict par suite ; tout est additionné pour ne perdre aucun ignoré. Verdicts manquants : nombre d'ignorés non annoncé.
  tests="$(grep -E '^(Ran [0-9]+ tests? in |(OK|FAILED)( \(.*\))?$)' "$journal" | awk '
    function nb(cle,   r) { r = $0; if (match(r, cle "=[0-9]+")) { r = substr(r, RSTART, RLENGTH); sub(/.*=/, "", r); return r + 0 } return 0 }
    /^Ran / { t += $2; ran++; next }
    { v++; if ($1 == "FAILED") { rouge = 1; if ($0 !~ /=/) e++ } f += nb("failures"); e += nb("errors"); s += nb("skipped") + nb("expected failures") }
    END {
      if (!ran) exit
      l = "Ran " t " tests"
      if (v == ran) {
        if (rouge) l = l " ; FAILED (failures=" f ", errors=" e ", skipped=" s ")"
        else if (s) l = l " ; OK (skipped=" s ")"
        else l = l " ; OK"
      }
      print l
    }')"
  [ -z "$tests" ] && tests="$(grep -E '^=+ .*(passed|failed).* =+$|^[0-9]+ (passed|failed)' "$journal" | additionner "")"
  # jest : « Tests: 1 skipped, 5 passed, 6 total ». node:test : compteurs « tests 5 », « pass 4 »... précédés de ℹ ou #.
  [ -z "$tests" ] && tests="$(grep -E '^Tests: +.*[0-9]+ total$' "$journal" | sed -E 's/^Tests: +/Tests: /' | additionner "Tests: ")"
  [ -z "$tests" ] && tests="$(grep -E '^(ℹ|#) (tests|pass|fail|cancelled|skipped|todo) [0-9]+$' "$journal" | awk '{ n[$2] += $3 } END { if (length(n)) printf "node:test tests %d, pass %d, fail %d, cancelled %d, skipped %d, todo %d\n", n["tests"], n["pass"], n["fail"], n["cancelled"], n["skipped"], n["todo"] }')"
  [ -z "$tests" ] && tests="$(grep -E '^TESTS (OK : [0-9]+ vérifications|EN ECHEC : [0-9]+ sur [0-9]+)$' "$journal" | tail -1)"
fi
spotbugs="$(grep -E 'BugInstance size is [0-9]+' "$journal" | tail -1 | sed -E 's/.*(BugInstance size is [0-9]+).*/\1/')"

if [ "$code" -ne 0 ]; then
  echo "--- Fin du journal du build (60 dernières lignes) ---"
  tail -60 "$journal"
fi
echo "Tests : ${tests:-inconnu}"
[ -n "$spotbugs" ] && echo "Analyse statique : $spotbugs"
if [ "$code" -eq 0 ]; then
  echo "VERIFY OK"
else
  echo "VERIFY ECHEC (code $code)"
fi
exit "$code"
