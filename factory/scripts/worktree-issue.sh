#!/usr/bin/env bash
# Isolation d'une issue dans un `git worktree` (un dossier de travail à part, sur sa propre branche) : plusieurs agents peuvent travailler
# en parallèle sans se marcher dessus, et rien n'est jamais construit sur la branche principale.
#
# Usage : scripts/worktree-issue.sh creer <issue> [--base <référence>]
#         scripts/worktree-issue.sh nettoyer <issue> [--branche] [--force]
#         scripts/worktree-issue.sh lister
#   <issue> = id (ex. 001-03) ; la branche est `feat/<nom du fichier d'issue sans .md>` (ex. feat/001-03-formatage).
#   creer     crée `../<dépôt>-<id>` sur une branche neuve partant de la base (défaut : origin/HEAD si elle existe, sinon main, sinon master ;
#             pour des branches empilées, `--base feat/001-01-…`). Affiche le dossier, la branche et la base (borne de `git log <base>..HEAD`).
#   nettoyer  supprime le dossier de travail une fois la branche FUSIONNÉE dans la base (refus sinon, sauf --force) ; `--branche` supprime
#             aussi la branche (`git branch -d`, sûr : refuse une branche non fusionnée). À lancer par l'utilisateur après sa fusion.
#   lister    liste les worktrees du dépôt.
# Code de sortie : 0 ; 1 si l'opération est refusée ; 64 en cas d'erreur d'usage.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$(dirname "$0")/lib-issues.sh"

usage() { sed -n 2,17p "$0" | sed 's/^# \{0,1\}//' >&2; exit 64; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Pas un dépôt Git." >&2; exit 64; }

commande="${1:-}"; [ -n "$commande" ] || usage
shift

base_par_defaut() {
  local ref
  ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -n "$ref" ]; then echo "$ref"; return; fi
  for ref in main master; do
    if git show-ref --verify --quiet "refs/heads/$ref"; then echo "$ref"; return; fi
  done
  return 1
}

branche_de() { # branche_de <id> : feat/<nom du fichier d'issue>
  local f
  f="$(issue_fichiers "$1" | head -1)"
  [ -n "$f" ] || return 1
  printf 'feat/%s' "$(basename "$f" .md)"
}

dossier_de() { # dossier_de <id>
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
    base="${base:-$(base_par_defaut)}" || { echo "Aucune base trouvée (origin/HEAD, main, master) : passez --base." >&2; exit 64; }
    git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "Base inconnue : $base" >&2; exit 64; }
    if [ "$(git rev-parse --abbrev-ref HEAD)" = "$branche" ] || git show-ref --verify --quiet "refs/heads/$branche"; then
      echo "La branche $branche existe déjà : reprenez-la (git worktree add <dossier> $branche) ou supprimez-la." >&2; exit 1
    fi
    dossier="$(dossier_de "$id")"
    [ ! -e "$dossier" ] || { echo "Le dossier existe déjà : $dossier" >&2; exit 1; }
    git worktree add -q -b "$branche" "$dossier" "$base" || exit 1
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
    dossier="$(dossier_de "$id")"
    base="$(base_par_defaut)" || { echo "Aucune base trouvée : impossible de vérifier la fusion." >&2; exit 64; }
    if ! git merge-base --is-ancestor "$branche" "$base" 2>/dev/null && [ "$force" -ne 1 ]; then
      echo "La branche $branche n'est pas fusionnée dans $base : rien n'est supprimé (--force pour passer outre)." >&2; exit 1
    fi
    if [ -d "$dossier" ]; then
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
