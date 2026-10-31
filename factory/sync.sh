#!/usr/bin/env bash
# Expose la factory à chaque outil d'agent.
#  - skills : liens symboliques vers factory/skills (Claude Code, Codex, etc.)
#  - rôles  : enveloppes .claude/agents/*.md générées depuis les en-têtes YAML de factory/prompts/*.md (Claude Code).
#             Source unique : l'en-tête du prompt (name, description, tools, skills, model facultatif). Un prompt sans `name:` n'a pas
#             d'enveloppe (l'orchestrateur n'a pas de prompt : c'est la session principale, décrite dans AGENTS.md).
#  - suivi de progression : si le plugin savvy-progress est installé, son outil est ajouté aux agents et leur consigne l'utilise.
set -euo pipefail
cd "$(dirname "$0")/.."

for dir in .claude .agents; do
  mkdir -p "$dir"
  ln -sfn ../factory/skills "$dir/skills"
done

# Valeur d'un champ de l'en-tête YAML (entre les deux premières lignes `---`).
champ() { # champ <fichier> <clé>
  awk -v k="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && index($0, k ":") == 1 { sub("^" k ":[[:space:]]*", ""); print; exit }
  ' "$1"
}

progression=0
if grep -qs 'savvy-progress' "${HOME}/.claude/plugins/installed_plugins.json" 2>/dev/null; then
  progression=1
fi

mkdir -p .claude/agents
generes=()
for prompt in factory/prompts/*.md; do
  nom="$(champ "$prompt" name)"
  [ -n "$nom" ] || continue
  desc="$(champ "$prompt" description)"
  outils="$(champ "$prompt" tools)"
  skills="$(champ "$prompt" skills)"
  modele="$(champ "$prompt" model)"
  [ -n "$desc" ] && [ -n "$outils" ] || { echo "En-tête incomplet (description et tools requis) : $prompt" >&2; exit 1; }
  [ "$progression" -eq 1 ] && outils="$outils, mcp__savvy-progress__step"
  {
    echo "---"
    echo "name: $nom"
    echo "description: $desc"
    echo "tools: $outils"
    [ -n "$modele" ] && echo "model: $modele"
    if [ -n "$skills" ]; then
      echo "skills:"
      for s in $skills; do echo "  - $s"; done
    fi
    echo "---"
    echo "<!-- Généré par factory/sync.sh. Ne pas éditer : modifier l'en-tête et le texte de factory/prompts/$nom.md -->"
    echo "Lis et applique intégralement \`factory/prompts/$nom.md\` (ignore son en-tête YAML)."
    echo "Ton rapport de fin de mission suit \`factory/prompts/report-format.md\`."
    if [ "$progression" -eq 1 ]; then
      echo
      echo "Suivi de progression : dès que tu as lu ta consigne, appelle \`mcp__savvy-progress__step\` avec \`total\`"
      echo "(ton plan en 3 à 8 étapes) et \`done: 0\`, puis rappelle-le à chaque étape terminée (\`done\`, et \`note\`"
      echo "en quelques mots). Si l'outil est indisponible ou renvoie une erreur, ignore-le et poursuis."
    fi
  } > ".claude/agents/$nom.md"
  generes+=("$nom")
done

echo "Alias créés : .claude/skills, .agents/skills ; agents : ${generes[*]} ; suivi de progression : $([ "$progression" -eq 1 ] && echo oui || echo non)"
