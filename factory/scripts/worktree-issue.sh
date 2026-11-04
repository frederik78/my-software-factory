#!/usr/bin/env bash
# Isolation d'une issue dans un `git worktree` (un dossier de travail à part, sur sa propre branche) : plusieurs agents peuvent travailler
# en parallèle sans se marcher dessus, et rien n'est jamais construit sur `main` ni sur `develop`.
#
# Usage : scripts/worktree-issue.sh creer <issue> [--base <référence>]
#         scripts/worktree-issue.sh nettoyer <issue> [--branche] [--force]
#         scripts/worktree-issue.sh lister
#         scripts/worktree-issue.sh initialiser <source> <conteneur>
#   <issue> = id (ex. 001-03) ; la branche est `feat/<nom du fichier d'issue sans .md>` (ex. feat/001-03-formatage).
#   Structure recommandée : clone bare dans <conteneur>/.git et un worktree par issue, au même niveau, dans <conteneur>/<branche avec / remplacé par -> ;
#   `creer` y lance aussi factory/sync.sh. Dépôt classique : `../<dépôt>-<id>`, sans sync.sh, avec un avertissement.
#   initialiser  crée le conteneur depuis un dépôt existant (clone bare, origin vers l'URL de la source, refspec de suivi, fetch). Refuse un conteneur existant ;
#             ne modifie jamais la source. Les fichiers non suivis (.env, .factory.local.conf) ne sont ni lus ni copiés.
#   creer     crée le dossier sur une branche neuve partant de la base (défaut : develop si elle existe, sinon origin/develop, sinon origin/HEAD, sinon main, sinon master ;
#             pour des branches empilées, `--base feat/001-01-…`). Affiche le dossier, la branche et la base (borne de `git log <base>..HEAD`).
#   nettoyer  supprime le dossier de travail une fois la branche FUSIONNÉE dans la base (refus sinon, sauf --force) ; `--branche` supprime
#             aussi la branche (`git branch -d`, sûr : refuse une branche non fusionnée). À lancer par l'utilisateur après sa fusion.
#   lister    liste les worktrees du dépôt.
#   creer fait un fetch si possible et avertit si la base locale est en retard ; nettoyer reconnaît une fusion faite sur origin.
#   nettoyer refuse, sauf --force, un dossier sorti de sa branche ou contenant des fichiers ignorés hors artefacts connus (liste affichée, contenu jamais lu).
# Code de sortie : 0 ; 1 si l'opération est refusée ; 64 en cas d'erreur d'usage.
set -uo pipefail

dossier_appel="$PWD"
racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"

usage() { sed -n 2,23p "$0" | sed 's/^# \{0,1\}//' >&2; exit 64; }
if [ "${1:-}" = "initialiser" ]; then
  [ $# -eq 3 ] || usage
  absolu() { case "$1" in /*) printf '%s' "$1" ;; *) printf '%s/%s' "$dossier_appel" "$1" ;; esac; }
  source_depot="$(absolu "$2")"; conteneur="$(absolu "$3")"
  git -C "$source_depot" rev-parse --git-dir >/dev/null 2>&1 || { echo "Pas un dépôt Git : $2" >&2; exit 64; }
  [ ! -e "$conteneur" ] || { echo "Le conteneur existe déjà : $conteneur" >&2; exit 1; }
  source_abs="$(cd "$source_depot" && pwd -P)"
  parent="$(dirname "$conteneur")"
  if [ -d "$parent" ]; then
    parent_abs="$(cd "$parent" && pwd -P)"
    case "$parent_abs/" in "$source_abs"/*) echo "Le conteneur ne peut pas être dans la source : $conteneur" >&2; exit 64 ;; esac
  fi
  if url="$(git -C "$source_abs" remote get-url origin 2>/dev/null)"; then sans_origin=0; else url="$source_abs"; sans_origin=1; fi
  git clone -q --bare "$source_abs" "$conteneur/.git" || exit 1
  git --git-dir="$conteneur/.git" remote set-url origin "$url" || exit 1
  git --git-dir="$conteneur/.git" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' || exit 1
  url_affichee="$(printf '%s' "$url" | sed -E 's#://[^/@]+@#://***@#')"
  git --git-dir="$conteneur/.git" fetch -q origin 2>/dev/null || { echo "Clone créé, mais git fetch a échoué depuis $url_affichee : relancez-le." >&2; exit 1; }
  # Suivi amont : git pull fonctionne dans un worktree de ces branches.
  git --git-dir="$conteneur/.git" for-each-ref --format='%(refname:short)' refs/heads | while IFS= read -r b; do
    if git --git-dir="$conteneur/.git" show-ref --verify --quiet "refs/remotes/origin/$b"; then
      git --git-dir="$conteneur/.git" config "branch.$b.remote" origin
      git --git-dir="$conteneur/.git" config "branch.$b.merge" "refs/heads/$b"
    fi
  done
  echo "conteneur : $conteneur"
  echo "origin    : $url_affichee"
  [ "$sans_origin" -eq 0 ] || echo "Avertissement : la source n'a pas d'origin ; origin vise le chemin local $url_affichee. Corrigez-le : git --git-dir=\"$conteneur/.git\" remote set-url origin <URL>."
  echo "Les fichiers non suivis (.env, .factory.local.conf...) ne sont pas copiés : recréez-les vous-même dans chaque worktree qui en a besoin."
  echo "Premier dossier : git --git-dir=\"$conteneur/.git\" worktree add \"$conteneur/develop\" develop"
  exit 0
fi
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Pas un dépôt Git." >&2; exit 64; }

commande="${1:-}"; [ -n "$commande" ] || usage
shift

base_par_defaut() {
  local ref
  # Modèle de branches : develop est la base des branches de travail (main ne reçoit que les releases).
  if git show-ref --verify --quiet refs/heads/develop; then echo develop; return; fi
  if git show-ref --verify --quiet refs/remotes/origin/develop; then echo origin/develop; return; fi
  ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -n "$ref" ]; then echo "$ref"; return; fi
  for ref in main master; do
    if git show-ref --verify --quiet "refs/heads/$ref"; then echo "$ref"; return; fi
  done
  return 1
}

branche_de() { # branche_de <id> : feat/<nom du fichier d'issue>
  local f
  f="$(issue_fichiers "$1" | grep -E "/$1(-[^/]*)?\.md$")"
  # Identifiant exact : un préfixe (« 00 ») pourrait viser une autre issue.
  [ -n "$f" ] && [ "$(printf '%s\n' "$f" | wc -l)" -eq 1 ] || return 1
  printf 'feat/%s' "$(basename "$f" .md)"
}

# Fonctionne depuis n'importe quel worktree : le conteneur se déduit du dossier Git commun, jamais de $racine.
conteneur_bare() { # affiche le conteneur si la structure est bare ; code 1 sinon
  local commun
  commun="$(cd "$(git rev-parse --git-common-dir)" && pwd -P)" || return 1
  [ "$(basename "$commun")" = ".git" ] && [ "$(git config --bool core.bare)" = "true" ] || return 1
  dirname "$commun"
}

mise_a_jour() { # fetch si possible, sans bloquer hors réseau
  git remote get-url origin >/dev/null 2>&1 || return 0
  GIT_TERMINAL_PROMPT=0 git fetch -q origin 2>/dev/null || echo "Avertissement : fetch impossible, références distantes peut-être anciennes." >&2
}

avertir_retard() { # avertir_retard <branche locale>
  local retard
  git show-ref --verify --quiet "refs/heads/$1" && git show-ref --verify --quiet "refs/remotes/origin/$1" || return 0
  retard="$(git rev-list --count "$1..origin/$1")"
  [ "$retard" -eq 0 ] || echo "Avertissement : $1 a $retard commit(s) de retard sur origin/$1 ; mettez-la à jour (git pull dans son worktree)." >&2
}

# Fichiers ignorés hors artefacts régénérables : leurs noms seulement, jamais leur contenu.
ignores_a_proteger() { # ignores_a_proteger <dossier>
  git -C "$1" ls-files -oi --exclude-standard --directory | grep -vE '(^|/)(target|build|node_modules|dist|\.claude|\.agents|__pycache__|\.pytest_cache|\.mypy_cache|\.ruff_cache|\.gradle|\.venv|coverage|\.cache)(/|$)'
}

dossier_de() { # dossier_de <id> <branche>
  local c
  if c="$(conteneur_bare)"; then printf '%s/%s' "$c" "$(printf '%s' "$2" | tr '/' '-')"; return; fi
  printf '%s/%s-%s' "$(dirname "$racine")" "$(basename "$racine")" "$1"
}

case "$commande" in
  creer)
    id="${1:-}"; [ -n "$id" ] || usage; shift
    base=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --base) base="${2:?--base attend une référence}"; shift ;;
        *) usage ;;
      esac
      shift
    done
    branche="$(branche_de "$id")" || { echo "Issue introuvable : $id" >&2; exit 64; }
    mise_a_jour
    base="${base:-$(base_par_defaut)}" || { echo "Aucune base trouvée (develop, origin/develop, origin/HEAD, main, master) : passez --base." >&2; exit 64; }
    git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "Base inconnue : $base" >&2; exit 64; }
    if [ "$(git rev-parse --abbrev-ref HEAD)" = "$branche" ] || git show-ref --verify --quiet "refs/heads/$branche"; then
      echo "La branche $branche existe déjà : reprenez-la (git worktree add <dossier> $branche) ou supprimez-la." >&2; exit 1
    fi
    dossier="$(dossier_de "$id" "$branche")"
    [ ! -e "$dossier" ] || { echo "Le dossier existe déjà : $dossier" >&2; exit 1; }
    avertir_retard "$base"
    git worktree add -q -b "$branche" "$dossier" "$base" || exit 1
    if conteneur_bare >/dev/null; then
      if [ -x "$dossier/factory/sync.sh" ]; then
        "$dossier/factory/sync.sh" >/dev/null || { echo "factory/sync.sh a échoué dans $dossier." >&2; exit 1; }
      else
        echo "Pas de factory/sync.sh exécutable dans $dossier : alias non créés." >&2
      fi
    else
      echo "Avertissement : structure bare recommandée (scripts/worktree-issue.sh initialiser <source> <conteneur>)." >&2
    fi
    echo "dossier : $dossier"
    echo "branche : $branche"
    echo "base    : $(git rev-parse "$base")  ($base)"
    ;;
  nettoyer)
    id="${1:-}"; [ -n "$id" ] || usage; shift
    avec_branche=0; force=0
    while [ $# -gt 0 ]; do
      case "$1" in
        --branche) avec_branche=1 ;;
        --force) force=1 ;;
        *) usage ;;
      esac
      shift
    done
    branche="$(branche_de "$id")" || { echo "Issue introuvable : $id" >&2; exit 64; }
    dossier="$(dossier_de "$id" "$branche")"
    base="$(base_par_defaut)" || { echo "Aucune base trouvée : impossible de vérifier la fusion." >&2; exit 64; }
    mise_a_jour
    fusionnee=0
    git merge-base --is-ancestor "$branche" "$base" 2>/dev/null && fusionnee=1
    git merge-base --is-ancestor "$branche" "origin/${base#origin/}" 2>/dev/null && fusionnee=1
    if [ "$fusionnee" -ne 1 ] && [ "$force" -ne 1 ]; then
      echo "La branche $branche n'est pas fusionnée dans $base : rien n'est supprimé (--force pour passer outre)." >&2; exit 1
    fi
    if [ -d "$dossier" ]; then
      if [ "$force" -ne 1 ]; then
        tete="$(git -C "$dossier" symbolic-ref -q --short HEAD || echo détaché)"
        if [ "$tete" != "$branche" ]; then
          echo "Le dossier $dossier n'est pas sur la branche $branche ($tete) : ses commits seraient perdus, rien n'est supprimé (--force pour passer outre)." >&2; exit 1
        fi
        proteges="$(ignores_a_proteger "$dossier")"
        if [ -n "$proteges" ]; then
          { echo "Fichiers ignorés qui disparaîtraient, rien n'est supprimé (--force pour passer outre) :"; printf '%s\n' "$proteges"; } >&2; exit 1
        fi
      fi
      if [ "$force" -eq 1 ]; then git worktree remove --force "$dossier" || exit 1; else git worktree remove "$dossier" || exit 1; fi
      echo "supprimé : $dossier"
    else
      echo "Pas de dossier de travail pour $id ($dossier)."
    fi
    if [ "$avec_branche" -eq 1 ]; then
      git branch -d "$branche" || exit 1
    fi
    ;;
  lister)
    git worktree list
    ;;
  *) usage ;;
esac
