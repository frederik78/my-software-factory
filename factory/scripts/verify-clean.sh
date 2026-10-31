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
# Le résumé chiffré reconnaît la sortie de Maven (« Tests run: n, Failures: … ») et celle de unittest/pytest (« Ran n tests »).
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

tests="$(grep -E '^\[(INFO|ERROR|WARNING)\] Tests run: [0-9]+, Failures: [0-9]+, Errors: [0-9]+, Skipped: [0-9]+$' "$journal" | tail -1 | sed -E 's/^\[[A-Z]+\] //')"
if [ -z "$tests" ]; then
  tests="$(grep -E '^Ran [0-9]+ tests? in ' "$journal" | tail -1)"
  [ -z "$tests" ] && tests="$(grep -E '^=+ .*(passed|failed).* =+$|^[0-9]+ (passed|failed)' "$journal" | tail -1)"
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
