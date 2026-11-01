#!/usr/bin/env bash
# Expose la factory aux outils d'agents, de façon neutre vis-à-vis du fournisseur de LLM.
#  - skills : lien symbolique .agents/skills -> ../factory/skills (Codex et autres outils lisant .agents/).
#  - Claude Code : si le projet lui est destiné (présence de CLAUDE.md), appelle factory/sync-claude.sh
#    (lien .claude/skills, enveloppes d'agents, suivi de progression), qui est propre à Claude Code et utilisable seul.
#    Le seul dossier .claude/ ne suffit pas : init-projet.sh le crée (settings.json) et d'autres outils peuvent en avoir un.
# Options : --sans-claude (n'appelle jamais sync-claude.sh) ; --claude (l'appelle même sans CLAUDE.md).
set -euo pipefail
cd "$(dirname "$0")/.."

usage() { echo "Usage : factory/sync.sh [--claude | --sans-claude]" >&2; exit 64; }
mode=auto
for arg in "$@"; do
  case "$arg" in
    --claude)      [ "$mode" != sans ] || usage; mode=claude ;;
    --sans-claude) [ "$mode" != claude ] || usage; mode=sans ;;
    *) usage ;;
  esac
done

mkdir -p .agents
ln -sfn ../factory/skills .agents/skills
echo "Alias créés : .agents/skills"

if [ "$mode" = auto ] && [ -f CLAUDE.md ]; then mode=claude; fi
if [ "$mode" = claude ]; then
  ./factory/sync-claude.sh
fi
