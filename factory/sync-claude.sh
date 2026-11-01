#!/usr/bin/env bash
# PROPRE À CLAUDE CODE : expose la factory à Claude Code. Utilisable seul, ou appelé par factory/sync.sh.
#  - skills : lien symbolique .claude/skills -> ../factory/skills
#  - rôles  : enveloppes .claude/agents/*.md générées depuis les en-têtes YAML de factory/prompts/*.md.
#             Source unique : l'en-tête du prompt (name, description, tools, skills, model et effort facultatifs). Un prompt sans `name:` n'a pas
#             d'enveloppe (l'orchestrateur n'a pas de prompt : c'est la session principale, décrite dans AGENTS.md).
#             Modèle et effort : en-tête du prompt, sinon AGENT_MODELE et AGENT_EFFORT (voir lib-config.sh) ; valeur vide = champ absent, l'agent hérite de la session.
#  - suivi de progression : si le plugin savvy-progress est installé, son outil est ajouté aux agents et leur consigne l'utilise.
#
# Noms d'outils : le champ `tools:` d'un prompt est recopié tel quel dans l'enveloppe ; ses valeurs (Read, Write, Edit, Glob, Grep, Bash,
# mcp__savvy-progress__step...) sont donc des NOMS D'OUTILS DE CLAUDE CODE. Pour un autre outil, ce champ est ignoré (le texte du prompt
# reste valable) et il faut traduire ces noms dans la configuration de l'outil.
set -euo pipefail
cd "$(dirname "$0")/.."

[ "$#" -eq 0 ] || { echo "Usage : factory/sync-claude.sh (sans option)" >&2; exit 64; }

# shellcheck source=scripts/lib-config.sh
. factory/scripts/lib-config.sh
modele_defaut="$(config_valeur AGENT_MODELE "$AGENT_MODELE_DEFAUT")"
effort_defaut="$(config_valeur AGENT_EFFORT "$AGENT_EFFORT_DEFAUT")"
# Ces valeurs sont écrites dans un en-tête YAML : une valeur hors format pourrait y ajouter un champ, par exemple des outils.
if ! [[ "$modele_defaut" =~ ^([a-z0-9][a-z0-9.-]*)?$ ]]; then
  echo "AGENT_MODELE invalide : minuscules, chiffres, points et tirets, ou vide attendu (voir .factory.conf, .factory.local.conf, FACTORY_AGENT_MODELE)." >&2; exit 64
fi
case "$effort_defaut" in
  ''|low|medium|high|xhigh|max) ;;
  *) echo "AGENT_EFFORT invalide : low, medium, high, xhigh, max ou vide attendu (voir .factory.conf, .factory.local.conf, FACTORY_AGENT_EFFORT)." >&2; exit 64 ;;
esac

mkdir -p .claude
ln -sfn ../factory/skills .claude/skills

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
  modele="$(champ "$prompt" model)"; [ -n "$modele" ] || modele="$modele_defaut"
  effort="$(champ "$prompt" effort)"; [ -n "$effort" ] || effort="$effort_defaut"
  [ -n "$desc" ] && [ -n "$outils" ] || { echo "En-tête incomplet (description et tools requis) : $prompt" >&2; exit 1; }
  [ "$progression" -eq 1 ] && outils="$outils, mcp__savvy-progress__step"
  {
    echo "---"
    echo "name: $nom"
    echo "description: $desc"
    echo "tools: $outils"
    [ -n "$modele" ] && echo "model: $modele"
    [ -n "$effort" ] && echo "effort: $effort"
    if [ -n "$skills" ]; then
      echo "skills:"
      for s in $skills; do echo "  - $s"; done
    fi
    echo "---"
    echo "<!-- Généré par factory/sync-claude.sh. Ne pas éditer : modifier l'en-tête et le texte de factory/prompts/$nom.md -->"
    echo "Lis et applique intégralement \`factory/prompts/$nom.md\` (ignore son en-tête YAML)."
    echo "Ton rapport de fin de mission suit \`factory/prompts/report-format.md\`."
    if [ "$progression" -eq 1 ]; then
      echo
      echo "Suivi de progression : dès que tu as lu ta consigne, appelle \`mcp__savvy-progress__step\` avec \`total\`"
      echo "(le nombre d'étapes de ton plan, établi selon la mission, sans plancher ni plafond) et \`done: 0\`."
      echo "Une étape = un résultat vérifiable (un cycle RED/GREEN/REFACTOR, une série de fichiers modifiés, une vérification) :"
      echo "ni une étape par commande, ni un découpage si grossier que la barre n'avance plus."
      echo "Rappelle l'outil à chaque étape terminée (\`done\`, et \`note\` en quelques mots) ; si le plan change, ajuste \`total\`"
      echo "en gardant \`done\` cohérent. Si l'outil est indisponible ou renvoie une erreur, ignore-le et poursuis."
    fi
  } > ".claude/agents/$nom.md"
  generes+=("$nom")
done

echo "Alias créés : .claude/skills ; agents : ${generes[*]:-aucun} ; suivi de progression : $([ "$progression" -eq 1 ] && echo oui || echo non)"
