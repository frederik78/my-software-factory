#!/usr/bin/env bash
# PROPRE À CLAUDE CODE : hook SubagentStart / SubagentStop, installé par factory/sync-claude.sh dans .claude/settings.local.json.
# Inscrit le début et la fin de chaque sous-agent dans un journal que lit scripts/dashboard.sh (bandeau « Agents actifs »).
#
# Usage : factory/hook-agents-claude.sh debut|fin   (entrée de Claude Code sur stdin : une ligne JSON)
# Sort TOUJOURS en code 0, sans rien écrire sur stdout ni stderr (hors dépôt git, journal non inscriptible, JSON invalide, argument inconnu) :
# il ne doit jamais faire échouer ni ralentir l'agent.
#
# Journal : <git-common-dir>/factory-agents.log (git rev-parse --git-common-dir depuis le dossier de ce script, rendu absolu) ; hors de
# l'arbre de travail, donc jamais versionné, et commun à tous les worktrees, clone bare compris.
# Format, SEUL CONTRAT avec dashboard.sh : une ligne par événement, champs séparés par une tabulation, aucun champ ne contient de tabulation
# ni de retour à la ligne :
#   debut<TAB>epoch<TAB>agent_id<TAB>rôle<TAB>chemin du journal de l'agent
#   description<TAB>epoch<TAB>agent_id<TAB>texte (120 caractères au plus)
#   fin<TAB>epoch<TAB>agent_id
# agent_id : [A-Za-z0-9_-] seulement, sinon rien n'est écrit. Au début, un journal de plus de 2000 lignes est réduit aux 1000 dernières.
# Limite connue : une ligne `fin` écrite pendant la rotation peut être perdue (lecture puis remplacement du journal) ; l'agent concerné
# reste alors affiché « sans nouvelles » jusqu'au retrait (AGENTS_RETRAIT_MINUTES, 60 min par défaut), puis disparaît.
#
# Description : Claude Code ne la passe pas au hook. Elle est lue dans <transcript_path sans .jsonl>/subagents/agent-<agent_id>.meta.json,
# fichier NON DOCUMENTÉ par Anthropic qui n'existe pas encore au début : un sous-processus détaché l'attend (15 s au plus).
# S'il manque ou change de forme, aucune ligne description : le dashboard affiche le rôle seul.
# JSON lu sans jq, par expressions régulières (sed -E) tolérant les échappements ; \" et \\ décodés, caractères de contrôle remplacés par une espace.
# Compatible bash 3.2 (macOS) et Linux.

exec >/dev/null 2>&1
trap 'exit 0' EXIT

mode="${1:-}"
case "$mode" in debut|fin) ;; *) exit 0 ;; esac

entree="$(head -c 1048576)" # borne de lecture : 1 Mio (un gros champ avant agent_id ne doit pas faire perdre l'écriture)
dossier="$(cd "$(dirname "$0")" && pwd)" || exit 0
commun="$(cd "$dossier" && git rev-parse --git-common-dir)" && [ -n "$commun" ] || exit 0
commun="$(cd "$dossier" && cd "$commun" && pwd)" || exit 0
journal="$commun/factory-agents.log"

# json_champ <clé> <json> : valeur texte de la PREMIÈRE occurrence de la clé, décodée et assainie (une ligne, sans tabulation ni caractère de contrôle).
# Une clé citée dans une autre valeur y est échappée (\"clé\") : elle ne répond pas au motif. En deux temps : la première occurrence est
# repérée par une marque, puis la valeur est lue jusqu'à son guillemet fermant (une regex gloutonne prendrait la dernière occurrence).
marque=$'\001' # remplace provisoirement « \\\\ » pendant le décodage
debut_valeur=$'\002' # marque la première occurrence de la clé
json_champ() {
  printf '%s' "$2" | LC_ALL=C tr '\n\r' '  ' \
    | LC_ALL=C sed -E 's/"'"$1"'"[[:space:]]*:[[:space:]]*"/'"$debut_valeur"'/' \
    | LC_ALL=C sed -nE 's/^[^'"$debut_valeur"']*'"$debut_valeur"'((\\.|[^"\\])*)".*$/\1/p' \
    | LC_ALL=C sed -e 's/\\\\/'"$marque"'/g' -e 's/\\"/"/g' -e 's/\\[nrtbf]/ /g' -e 's/\\\//\//g' -e 's/'"$marque"'/\\/g' \
    | LC_ALL=C tr '\000-\037\177' ' '
}
# tronque <texte> : 120 premiers caractères UTF-8, jamais un caractère coupé (octets comptés en locale C).
tronque() {
  printf '%s' "$1" | LC_ALL=C sed -E $'s/^(([\x01-\x7f]|[\xc0-\xff][\x80-\xbf]*|[\x80-\xbf]){0,120}).*$/\\1/'
}

agent_id="$(json_champ agent_id "$entree")"
case "$agent_id" in ''|*[!A-Za-z0-9_-]*) exit 0 ;; esac
[ "${#agent_id}" -le 128 ] || exit 0
maintenant="$(date +%s)"

if [ "$mode" = fin ]; then
  printf 'fin\t%s\t%s\n' "$maintenant" "$agent_id" >> "$journal"
  exit 0
fi

# Rotation, avant l'inscription : écriture atomique dans le même dossier ; un échec laisse le journal intact.
if [ -f "$journal" ] && [ "$(wc -l < "$journal")" -gt 2000 ]; then
  tmp="$(mktemp "$journal.XXXXXX")" && [ -f "$tmp" ] && {
    tail -n 1000 "$journal" > "$tmp" && mv "$tmp" "$journal" || rm -f "$tmp"
  }
fi

role="$(tronque "$(json_champ agent_type "$entree")")"
transcript="$(json_champ transcript_path "$entree")"
sous_agents=""; chemin=""
case "$transcript" in
  *.jsonl) sous_agents="${transcript%.jsonl}/subagents"; chemin="$sous_agents/agent-$agent_id.jsonl" ;;
esac
printf 'debut\t%s\t%s\t%s\t%s\n' "$maintenant" "$agent_id" "$role" "$chemin" >> "$journal" || exit 0

[ -n "$sous_agents" ] || exit 0
meta="$sous_agents/agent-$agent_id.meta.json"
(
  trap '' HUP
  n=0
  while [ ! -f "$meta" ] && [ "$n" -lt 15 ]; do sleep 1; n=$((n + 1)); done
  [ -f "$meta" ] || exit 0
  description="$(tronque "$(json_champ description "$(head -c 65536 "$meta")")")"
  [ -n "$description" ] || exit 0
  printf 'description\t%s\t%s\t%s\n' "$(date +%s)" "$agent_id" "$description" >> "$journal"
) </dev/null >/dev/null 2>&1 &
exit 0
