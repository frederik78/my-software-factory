#!/usr/bin/env bash
# PROPRE À CLAUDE CODE : expose la factory à Claude Code. Utilisable seul, ou appelé par factory/sync.sh.
#  - skills : lien symbolique .claude/skills -> ../factory/skills
#  - rôles  : une enveloppe .claude/agents/<rôle>.md par prompt de factory/prompts/ ayant un `name:` (l'orchestrateur n'a pas de prompt : c'est la
#             session principale, décrite dans AGENTS.md). L'en-tête du prompt, indépendant de l'outil, ne porte que name, description et skills ;
#             outils, modèle et effort du rôle sont dans son entrée de factory/claude/roles.conf (PRD 006, D-60), que seul ce script lit.
#             Modèle et effort : entrée du rôle, sinon AGENT_MODELE et AGENT_EFFORT (voir lib-config.sh) ; valeur vide = champ absent, l'agent hérite de la session.
#             Exception : les trois relecteurs (code-reviewer-conformite, -qualite, -securite) ont chacun deux clés (AGENT_MODELE_<RÔLE>, AGENT_EFFORT_<RÔLE>)
#             qui l'emportent sur leur entrée ; leurs enveloppes n'ont jamais Write, Edit, MultiEdit ni NotebookEdit, quel que soit MODE_REVUE.
#             Les outils ne se règlent que dans roles.conf (aucune clé de configuration). Toute incohérence entre roles.conf et les prompts (code 1)
#             et toute valeur invalide (code 64) arrêtent le script avant la moindre écriture.
#  - suivi de progression : si le plugin savvy-progress est installé, son outil est ajouté aux agents et leur consigne l'utilise.
#  - agents actifs : hooks SubagentStart / SubagentStop (factory/hook-agents-claude.sh) dans .claude/settings.local.json, lus par scripts/dashboard.sh.
#
# Noms d'outils : les outils d'une entrée de roles.conf sont recopiés dans l'enveloppe ; ce sont des NOMS D'OUTILS DE CLAUDE CODE (Read, Write,
# Edit, Glob, Grep, Bash, mcp__savvy-progress__step...). Un autre outil ignore roles.conf (le texte du prompt reste valable) et traduit ces noms
# dans sa propre configuration.
set -euo pipefail
cd "$(dirname "$0")/.."

[ "$#" -eq 0 ] || { echo "Usage : factory/sync-claude.sh (sans option)" >&2; exit 64; }

# shellcheck source=scripts/lib-config.sh
. factory/scripts/lib-config.sh
# Ces valeurs sont écrites dans un en-tête YAML : une valeur hors format pourrait y ajouter un champ, par exemple des outils.
modele_forme() { [[ "$1" =~ ^([a-z0-9][a-z0-9.-]*)?$ ]] && [ "${#1}" -le 64 ]; } # minuscules, chiffres, points, tirets, 64 caractères au plus, ou vide
effort_forme() { case "$1" in ''|low|medium|high|xhigh|max) return 0 ;; esac; return 1; }
modele_valide() { # modele_valide <clé> <valeur> : sinon code 64 sans recopier la valeur
  modele_forme "$2" && return 0
  echo "$1 invalide : minuscules, chiffres, points et tirets, ou vide attendu (voir .factory.conf, .factory.local.conf, FACTORY_$1)." >&2; exit 64
}
effort_valide() { # effort_valide <clé> <valeur>
  effort_forme "$2" && return 0
  echo "$1 invalide : low, medium, high, xhigh, max ou vide attendu (voir .factory.conf, .factory.local.conf, FACTORY_$1)." >&2; exit 64
}
modele_defaut="$(config_valeur AGENT_MODELE "$AGENT_MODELE_DEFAUT")"
effort_defaut="$(config_valeur AGENT_EFFORT "$AGENT_EFFORT_DEFAUT")"
modele_valide AGENT_MODELE "$modele_defaut"
effort_valide AGENT_EFFORT "$effort_defaut"
# Les six clés des relecteurs (PRD 006) : validées toutes, avant toute écriture, même si le prompt du rôle est absent ; valeur vide = pas de surcharge.
# Lues sans perdre un saut de ligne final (config_valeur_exacte) : « opus » suivi d'un saut de ligne reste invalide.
for role in CONFORMITE QUALITE SECURITE; do
  config_valeur_exacte "AGENT_MODELE_$role" ""; modele_valide "AGENT_MODELE_$role" "$CONFIG_VALEUR"; printf -v "modele_surcharge_$role" '%s' "$CONFIG_VALEUR"
  config_valeur_exacte "AGENT_EFFORT_$role" ""; effort_valide "AGENT_EFFORT_$role" "$CONFIG_VALEUR"; printf -v "effort_surcharge_$role" '%s' "$CONFIG_VALEUR"
done

# Valeur d'un champ de l'en-tête YAML (entre les deux premières lignes `---`).
champ() { # champ <fichier> <clé>
  awk -v k="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && index($0, k ":") == 1 { sub("^" k ":[[:space:]]*", ""); print; exit }
  ' "$1"
}
# Premier champ de l'en-tête qui n'a plus cours depuis D-60 (tools, model, effort : ils sont dans roles.conf), vide s'il n'y en a pas.
champ_obsolete() { # champ_obsolete <fichier>
  awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1 && /^(tools|model|effort):/ { sub(/:.*/, ""); print; exit }' "$1"
}

# Un relecteur est en lecture seule : ni Write, Edit, MultiEdit ni NotebookEdit (casse indifférente), quel que soit le mode de revue et même si son entrée les déclare.
sans_ecriture() { # sans_ecriture <outils séparés par des virgules>
  printf '%s' "$1" | awk -v RS=, '{ gsub(/^[ \t]+|[ \t]+$/, "") } $0 != "" && tolower($0) !~ /^(write|edit|multiedit|notebookedit)$/ { printf "%s%s", (n++ ? ", " : ""), $0 }'
}
relecteur() { # relecteur <rôle> : suffixe des clés du relecteur (CONFORMITE, QUALITE, SECURITE), vide pour un autre rôle
  case "$1" in code-reviewer-conformite) echo CONFORMITE ;; code-reviewer-qualite) echo QUALITE ;; code-reviewer-securite) echo SECURITE ;; esac
}

# --- factory/claude/roles.conf : outils, modèle et effort de chaque rôle (RG-31). Donnée non fiable : chaque champ est validé en liste blanche et
# jamais évalué ; un message d'erreur cite au plus le numéro de ligne, jamais la valeur. Tout est vérifié avant la première écriture.
roles_conf=factory/claude/roles.conf
blancs=$' \t'
sans_blancs() { # sans_blancs <valeur> : range dans SANS_BLANCS la valeur sans espaces ni tabulations de bord
  SANS_BLANCS="${1#"${1%%[!$blancs]*}"}"; SANS_BLANCS="${SANS_BLANCS%"${SANS_BLANCS##*[!$blancs]}"}"
}
roles_refus() { echo "Erreur : $roles_conf, ligne $1 : $2" >&2; exit 64; } # roles_refus <numéro de ligne> <règle>
roles_incoherent() { echo "Erreur : $1" >&2; exit 1; }
if [ -L "$roles_conf" ] || { [ -e "$roles_conf" ] && [ ! -f "$roles_conf" ]; }; then
  roles_incoherent "$roles_conf n'est pas un fichier régulier (dossier ou lien symbolique refusé)."
fi
[ -f "$roles_conf" ] || roles_incoherent "$roles_conf introuvable : il décrit les outils, le modèle et l'effort de chaque rôle."
[ "$(wc -c < "$roles_conf" | tr -d ' ')" -le 65536 ] || roles_incoherent "$roles_conf dépasse 64 Kio."
ligne_invalide="ligne invalide (1024 caractères au plus, aucun caractère de contrôle autre que la tabulation)."
nb_roles=0; numero=0
while IFS= read -r ligne || [ -n "$ligne" ]; do
  numero=$((numero + 1))
  sans_blancs "$ligne"; case "$SANS_BLANCS" in ''|'#'*) continue ;; esac
  [ "${#ligne}" -le 1024 ] || roles_refus "$numero" "$ligne_invalide"
  case "${ligne//$'\t'/}" in *[[:cntrl:]]*) roles_refus "$numero" "$ligne_invalide" ;; esac
  separateurs="${ligne//[!|]/}"
  [ "${#separateurs}" -eq 3 ] || roles_refus "$numero" "quatre champs séparés par | attendus (rôle | outils | modèle | effort)."
  sans_blancs "${ligne%%|*}"; role="$SANS_BLANCS"; reste="${ligne#*|}"
  liste="${reste%%|*}"; reste="${reste#*|}"
  sans_blancs "${reste%%|*}"; modele="$SANS_BLANCS"
  sans_blancs "${reste#*|}"; effort="$SANS_BLANCS"
  [[ "$role" =~ ^[a-z0-9][a-z0-9-]*$ ]] && [ "${#role}" -le 64 ] \
    || roles_refus "$numero" "rôle invalide (minuscules, chiffres et tirets, commence par une minuscule ou un chiffre, 64 caractères au plus)."
  outils=; reste="$liste,"
  while [ -n "$reste" ]; do
    sans_blancs "${reste%%,*}"; reste="${reste#*,}"
    [[ "$SANS_BLANCS" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]] && [ "${#SANS_BLANCS}" -le 64 ] \
      || roles_refus "$numero" "outils invalides (liste non vide de noms séparés par des virgules ; un nom commence par une lettre, puis lettres, chiffres, _ ou -, 64 caractères au plus)."
    outils="${outils:+$outils, }$SANS_BLANCS"
  done
  modele_forme "$modele" || roles_refus "$numero" "modèle invalide (minuscules, chiffres, points et tirets, 64 caractères au plus, ou vide)."
  effort_forme "$effort" || roles_refus "$numero" "effort invalide (low, medium, high, xhigh, max ou vide)."
  if [ -n "$(relecteur "$role")" ]; then
    outils="$(sans_ecriture "$outils")"
    [ -n "$outils" ] || roles_refus "$numero" "outils invalides pour un relecteur (aucun outil hors Write, Edit, MultiEdit et NotebookEdit)."
  fi
  noms_roles[nb_roles]="$role"; outils_roles[nb_roles]="$outils"; modeles_roles[nb_roles]="$modele"; efforts_roles[nb_roles]="$effort"; pris_roles[nb_roles]=
  nb_roles=$((nb_roles + 1))
done < "$roles_conf"
entree_du_role() { # entree_du_role <rôle> : range dans ENTREE l'indice de l'entrée du rôle ; code 1 s'il n'en a pas
  ENTREE=0
  while [ "$ENTREE" -lt "$nb_roles" ]; do [ "${noms_roles[ENTREE]}" = "$1" ] && return 0; ENTREE=$((ENTREE + 1)); done
  return 1
}
i=0
while [ "$i" -lt "$nb_roles" ]; do
  entree_du_role "${noms_roles[i]}"; [ "$ENTREE" -eq "$i" ] || roles_incoherent "$roles_conf : deux entrées pour le rôle ${noms_roles[i]}."
  i=$((i + 1))
done

# --- Prompts : chacun à `name:` a une description, aucun champ obsolète et une entrée de rôle ; chaque entrée est le `name:` d'un prompt (RG-32, RG-34).
nb_agents=0
for prompt in factory/prompts/*.md; do
  [ -f "$prompt" ] || continue
  nom="$(champ "$prompt" name)"
  [ -n "$nom" ] || continue
  obsolete="$(champ_obsolete "$prompt")"
  [ -z "$obsolete" ] || roles_incoherent "en-tête de $prompt : le champ $obsolete n'a plus cours ; les outils, le modèle et l'effort d'un rôle se règlent dans $roles_conf."
  desc="$(champ "$prompt" description)"
  [ -n "$desc" ] || { echo "En-tête incomplet (description requise) : $prompt" >&2; exit 1; }
  entree_du_role "$nom" || roles_incoherent "$prompt n'a pas d'entrée de rôle dans $roles_conf."
  pris_roles[ENTREE]=oui
  agents_entree[nb_agents]="$ENTREE"; agents_desc[nb_agents]="$desc"; agents_skills[nb_agents]="$(champ "$prompt" skills)"
  nb_agents=$((nb_agents + 1))
done
i=0
while [ "$i" -lt "$nb_roles" ]; do
  [ -n "${pris_roles[i]}" ] || roles_incoherent "$roles_conf : le rôle ${noms_roles[i]} n'est le name: d'aucun prompt de factory/prompts/."
  i=$((i + 1))
done

mkdir -p .claude
ln -sfn ../factory/skills .claude/skills

progression=0
if grep -qs 'savvy-progress' "${HOME}/.claude/plugins/installed_plugins.json" 2>/dev/null; then
  progression=1
fi

mkdir -p .claude/agents
generes=()
a=0
while [ "$a" -lt "$nb_agents" ]; do
  e="${agents_entree[a]}"; nom="${noms_roles[e]}"; desc="${agents_desc[a]}"; skills="${agents_skills[a]}"; outils="${outils_roles[e]}"
  # Précédence d'un relecteur : sa clé de configuration, puis son entrée de roles.conf, puis AGENT_MODELE / AGENT_EFFORT (exception à « l'entrée l'emporte »).
  modele="${modeles_roles[e]}"; effort="${efforts_roles[e]}"; role="$(relecteur "$nom")"
  if [ -n "$role" ]; then
    surcharge="modele_surcharge_$role"; [ -z "${!surcharge}" ] || modele="${!surcharge}"
    surcharge="effort_surcharge_$role"; [ -z "${!surcharge}" ] || effort="${!surcharge}"
  fi
  [ -n "$modele" ] || modele="$modele_defaut"
  [ -n "$effort" ] || effort="$effort_defaut"
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
    echo "<!-- Généré par factory/sync-claude.sh. Ne pas éditer : modifier le texte de factory/prompts/$nom.md et l'entrée du rôle $nom dans factory/claude/roles.conf -->"
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
  a=$((a + 1))
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
