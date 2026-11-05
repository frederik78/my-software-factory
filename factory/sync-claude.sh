#!/usr/bin/env bash
# PROPRE À CLAUDE CODE : expose la factory à Claude Code. Utilisable seul, ou appelé par factory/sync.sh.
#  - skills : lien symbolique .claude/skills -> ../factory/skills
#  - rôles  : enveloppes .claude/agents/*.md générées depuis les en-têtes YAML de factory/prompts/*.md.
#             Source unique : l'en-tête du prompt (name, description, tools, skills, model et effort facultatifs). Un prompt sans `name:` n'a pas
#             d'enveloppe (l'orchestrateur n'a pas de prompt : c'est la session principale, décrite dans AGENTS.md).
#             Modèle et effort : en-tête du prompt, sinon AGENT_MODELE et AGENT_EFFORT (voir lib-config.sh) ; valeur vide = champ absent, l'agent hérite de la session.
#  - suivi de progression : si le plugin savvy-progress est installé, son outil est ajouté aux agents et leur consigne l'utilise.
#  - agents actifs : hooks SubagentStart / SubagentStop (factory/hook-agents-claude.sh) dans .claude/settings.local.json, lus par scripts/dashboard.sh.
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

# Hooks des agents actifs, dans .claude/settings.local.json et PAS dans settings.json : worktree-issue.sh creer lance sync.sh dans chaque
# worktree, et modifier un fichier versionné y salirait l'arbre, ce qui ferait échouer fin-issue.sh.
# Sans jq : fusion prudente et idempotente. Fichier absent : créé. Hooks déjà là : rien. Objet JSON sans clé "hooks" : clé insérée juste après
# la première accolade, le reste à l'identique. Autre cas (clé "hooks" déjà présente, fichier inexploitable) : rien n'est modifié, avertissement.
reglages=.claude/settings.local.json
commande_hook() { # commande_hook <debut|fin> : commande du hook, échappée pour une chaîne JSON
  printf '\\"$CLAUDE_PROJECT_DIR\\"/factory/hook-agents-claude.sh %s 2>/dev/null || true' "$1"
}
bloc_hooks() { # bloc_hooks : valeur de la clé "hooks", indentée sous un objet de premier niveau
  printf '{\n    "SubagentStart": [{"hooks": [{"type": "command", "command": "%s"}]}],\n    "SubagentStop": [{"hooks": [{"type": "command", "command": "%s"}]}]\n  }' "$(commande_hook debut)" "$(commande_hook fin)"
}
avertir_hooks() { # avertir_hooks <raison>
  { echo "Avertissement : $reglages $1 : hooks des agents actifs non installés, à ajouter à la main dans l'objet de premier niveau :"
    printf '  "hooks": %s\n' "$(bloc_hooks)"; } >&2
}
agents_actifs=non
if [ ! -e "$reglages" ] && [ ! -L "$reglages" ]; then
  printf '{\n  "hooks": %s\n}\n' "$(bloc_hooks)" > "$reglages" && agents_actifs=oui
elif grep -q 'SubagentStart' "$reglages" 2>/dev/null && grep -q 'hook-agents-claude.sh' "$reglages" 2>/dev/null; then
  agents_actifs=oui # installés : le nom du script seul (une permission, par exemple) ne le prouve pas
elif [ -L "$reglages" ]; then
  avertir_hooks "est un lien symbolique (non remplacé par un fichier)"
elif grep -Eq '"hooks"[[:space:]]*:' "$reglages"; then
  avertir_hooks "a déjà une clé \"hooks\""
else
  # Première passe : le premier caractère non blanc est-il « { », et l'objet est-il vide ? Seconde passe : insertion après cette accolade.
  forme="$(awk '
    { for (i = 1; i <= length($0); i++) { c = substr($0, i, 1); if (c ~ /[[:space:]]/) continue
        if (!vu) { vu = 1; if (c != "{") { print "autre"; exit } continue }
        print (c == "}" ? "vide" : "objet"); exit } }' "$reglages")"
  case "$forme" in
    vide|objet)
      # Mode d'origine conservé (stat GNU puis BSD), jamais plus large : à défaut de le lire, 0600.
      mode_reglages="$(stat -c %a "$reglages" 2>/dev/null || stat -f %Lp "$reglages" 2>/dev/null)"
      case "$mode_reglages" in ''|*[!0-7]*) mode_reglages=600 ;; esac
      tmp_reglages="$(mktemp "$reglages.XXXXXX")" && [ -f "$tmp_reglages" ] || { echo "Erreur : fichier temporaire impossible à côté de $reglages" >&2; exit 1; }
      # Valeurs passées par l'environnement : awk -v interpréterait les barres obliques inverses du JSON.
      if BLOC="$(bloc_hooks)" SUITE="$([ "$forme" = vide ] || echo ",")" awk '
          !fait && match($0, /[^[:space:]]/) { fait = 1
            printf "%s{\n  \"hooks\": %s%s", substr($0, 1, RSTART - 1), ENVIRON["BLOC"], ENVIRON["SUITE"]
            reste = substr($0, RSTART + 1)
            if (ENVIRON["SUITE"] == "") { sub(/^[[:space:]]*/, "", reste); if (reste != "") reste = "\n" reste }
            print reste; next }
          { print }' "$reglages" > "$tmp_reglages" && chmod "$mode_reglages" "$tmp_reglages" && mv "$tmp_reglages" "$reglages"; then
        agents_actifs=oui
      else
        rm -f "$tmp_reglages"; avertir_hooks "n'a pas pu être réécrit"
      fi ;;
    *) avertir_hooks "n'est pas un objet JSON exploitable" ;;
  esac
fi
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && ! git check-ignore -q "$reglages"; then
  echo "Avertissement : $reglages n'est pas ignoré par git : ajoutez la ligne .claude/settings.local.json au .gitignore (réglages propres au poste)." >&2
fi

echo "Alias créés : .claude/skills ; agents : ${generes[*]:-aucun} ; suivi de progression : $([ "$progression" -eq 1 ] && echo oui || echo non) ; agents actifs : $agents_actifs"
