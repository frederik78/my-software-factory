#!/usr/bin/env bash
# Prépare un nouveau projet autour de la factory : fichiers de départ (AGENTS.md, backlog, docs/...), fichiers propres à la stack (CI, Dependabot,
# .gitignore, commande de vérification), scripts, alias de skills et d'agents.
# À lancer depuis la racine d'un dépôt qui contient le dossier factory/ (copié ou cloné) :
#     ./factory/init-projet.sh [--nom "Nom du projet"] [--stack java-maven|python|node|aucune]
# --stack choisit le dossier factory/stacks/<stack>/ (défaut : aucune = squelette indépendant de la stack ; voir factory/stacks/*/README.md).
# N'écrase JAMAIS un fichier existant : chaque fichier déjà présent est conservé et signalé. Relançable sans risque.
set -euo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine"
nom="$(basename "$racine")"
stack="aucune"
usage() { echo "Usage : $0 [--nom \"Nom du projet\"] [--stack $(ls factory/stacks 2>/dev/null | paste -sd'|' -)]" >&2; exit 64; }
while [ $# -gt 0 ]; do
  case "$1" in
    --nom) nom="${2:?--nom attend une valeur}"; shift ;;
    --stack) stack="${2:?--stack attend une valeur}"; shift ;;
    *) usage ;;
  esac
  shift
done

modeles="factory/templates"
[ -d "$modeles" ] || { echo "Modèles introuvables : $modeles" >&2; exit 1; }
[ -d "factory/stacks/$stack" ] || { echo "Stack inconnue : $stack" >&2; usage; }

nom_sed="$(printf '%s' "$nom" | sed -e 's/[\/&|]/\\&/g')"
crees=0; gardes=0

copier() { # copier <source> <destination relative> : sans jamais écraser ; le nom du projet remplace __NOM_PROJET__
  local src="$1" rel="$2"
  if [ -e "$rel" ]; then
    echo "conservé   $rel"; gardes=$((gardes + 1)); return 0
  fi
  mkdir -p "$(dirname "$rel")"
  sed "s|__NOM_PROJET__|${nom_sed}|g" "$src" > "$rel"
  echo "créé       $rel"; crees=$((crees + 1))
}

# 1. Tronc commun
gitignore_cree=0; [ -e .gitignore ] || gitignore_cree=1
while IFS= read -r -d '' src; do
  copier "$src" "${src#"$modeles"/}"
done < <(find "$modeles" -type f ! -name '.DS_Store' -print0 | sort -z)

# 2. Fichiers propres à la stack
pile="factory/stacks/$stack"
while IFS= read -r -d '' src; do
  rel="${src#"$pile"/}"
  case "$rel" in
    README.md|gitignore.append|factory-verify) continue ;;
  esac
  copier "$src" "$rel"
done < <(find "$pile" -type f ! -name '.DS_Store' -print0 | sort -z)
if [ -f "$pile/factory-verify" ]; then copier "$pile/factory-verify" .factory-verify; fi
if [ -f "$pile/gitignore.append" ]; then
  if [ "$gitignore_cree" -eq 1 ]; then
    cat "$pile/gitignore.append" >> .gitignore; echo "complété   .gitignore (lignes de la stack $stack)"
  else
    echo "à faire    .gitignore existait déjà : ajoutez-y les lignes de $pile/gitignore.append"
  fi
fi

# 3. Scripts de la factory, exposés par des liens symboliques (la source reste factory/scripts/).
mkdir -p scripts
for s in factory/scripts/*.sh; do
  cible="scripts/$(basename "$s")"
  if [ -e "$cible" ] || [ -L "$cible" ]; then
    echo "conservé   $cible"
  else
    ln -s "../$s" "$cible"
    echo "lié        $cible"
  fi
done

# 4. Version de la factory utilisée par ce projet (marqueur, mis à jour à chaque exécution).
version=""; [ -f factory/VERSION ] && version="$(tr -d '[:space:]' < factory/VERSION)"
if [ -n "$version" ]; then
  precedente=""; [ -f .factory-version ] && precedente="$(tr -d '[:space:]' < .factory-version)"
  if [ -z "$precedente" ]; then
    echo "$version" > .factory-version; echo "créé       .factory-version ($version)"
  elif [ "$precedente" != "$version" ]; then
    echo "$version" > .factory-version; echo "mis à jour .factory-version ($precedente -> $version) : lire factory/CHANGELOG.md et factory/MISE-A-JOUR.md"
  fi
fi

./factory/sync.sh

echo
echo "$crees fichier(s) créé(s), $gardes conservé(s) (stack : $stack). Étapes suivantes : voir factory/DEMARRER-UN-PROJET.md"
if [ ! -f .factory-verify ] && [ ! -x ./mvnw ] && [ ! -x ./gradlew ] && [ -z "${COMMANDE_VERIFY:-}" ]; then
  echo "À faire : créer .factory-verify (une ligne : la commande de vérification complète) ; scripts/verify-clean.sh et la CI en ont besoin."
fi
