#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : lecture de l'en-tête YAML des issues de docs/issues/.
# Compatible bash 3.2 (macOS). Formats de liste acceptés pour un champ :
#   criteres: [CA-01, CS-02]          criteres: []          criteres:
#                                                             - CA-01
#                                                             - CS-02

# issue_champ <fichier> <clé> : valeur scalaire de l'en-tête (sans guillemets ni espaces de bord).
issue_champ() {
  awk -v k="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    index($0, k ":") == 1 {
      sub("^" k ":[[:space:]]*", ""); gsub(/^["'\'']|["'\'']$/, ""); sub(/[[:space:]]+$/, ""); print; exit
    }
  ' "$1"
}

# issue_champs <fichier> <clé>... : comme issue_champ pour plusieurs clés en un seul passage : une ligne par clé, dans l'ordre demandé (vide si la clé est absente).
issue_champs() {
  local fichier="$1"; shift
  awk -v ks="$*" '
    BEGIN { n = split(ks, cle, " ") }
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    { for (i = 1; i <= n; i++) if (!(i in val) && index($0, cle[i] ":") == 1) {
        v = $0; sub("^" cle[i] ":[[:space:]]*", "", v); gsub(/^["'\'']|["'\'']$/, "", v); sub(/[[:space:]]+$/, "", v); val[i] = v } }
    END { for (i = 1; i <= n; i++) print val[i] }
  ' "$fichier"
}

# issue_liste <fichier> <clé> : éléments de la liste, un par ligne (forme en ligne ou en tirets).
issue_liste() {
  awk -v k="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    capture {
      if ($0 ~ /^[[:space:]]*-[[:space:]]+/) { s = $0; sub(/^[[:space:]]*-[[:space:]]+/, "", s); gsub(/["'\'']|[[:space:]]+$/, "", s); sub(/[[:space:]]*#.*$/, "", s); print s; next }
      if ($0 ~ /^[[:space:]]*($|#)/) next
      capture = 0
    }
    index($0, k ":") == 1 {
      v = $0; sub("^" k ":[[:space:]]*", "", v)
      if (v ~ /^\[/) {
        gsub(/^\[|\][[:space:]]*$/, "", v); n = split(v, a, /[[:space:]]*,[[:space:]]*/)
        for (i = 1; i <= n; i++) { gsub(/["'\'']|^[[:space:]]+|[[:space:]]+$/, "", a[i]); if (a[i] != "") print a[i] }
      } else if (v == "" || v ~ /^#/) { capture = 1 }
    }
  ' "$1"
}

# issue_fichiers [motif d'id] : chemins des issues (hors modèle et README), triés.
issue_fichiers() {
  local f
  if [ -z "${1:-}" ]; then
    for f in docs/issues/[0-9]*.md; do [ -e "$f" ] && printf '%s\n' "$f"; done
  else
    for f in docs/issues/"$1"*.md; do [ -e "$f" ] && printf '%s\n' "$f"; done
  fi
  return 0
}

# --- Fichiers lus : refus et lecture groupée des en-têtes (PRD 004, RG-21, CS-04) ---------------------------------------------------------------
# Taille maximale (octets) d'un fichier lu (fichier d'issue, fichier de revue) : au-delà, le fichier est refusé et n'est jamais lu.
FICHIER_OCTETS_MAX=1048576
# Fichiers de plus de FICHIER_OCTETS_MAX octets des dossiers déjà examinés par gros_charger (un find par dossier au lieu d'un wc par fichier).
gros_dossiers=$'\n'; gros_liste=$'\n'

# gros_charger <dossier> : liste en un seul appel les fichiers du dossier (sans sous-dossier) de plus de FICHIER_OCTETS_MAX octets ; fichier_motif_refus les connaît ensuite sans lancer wc.
gros_charger() {
  local trouves
  trouves="$(find "$1" -maxdepth 1 -type f -size +"$FICHIER_OCTETS_MAX"c 2>/dev/null)"
  gros_dossiers="$gros_dossiers$1"$'\n'
  [ -z "$trouves" ] || gros_liste="$gros_liste$trouves"$'\n'
}

# fichier_motif_refus <fichier> : met dans $motif_refus pourquoi le fichier n'est pas lu (« lien symbolique », « lecture impossible », « plus de 1 Mio »), vide s'il peut l'être.
# Le fichier n'est ouvert qu'après ces vérifications : un lien symbolique n'est jamais suivi, un gros fichier ni un fichier spécial jamais lu.
fichier_motif_refus() {
  local taille
  motif_refus=""
  if [ -L "$1" ]; then motif_refus="lien symbolique"
  elif [ ! -f "$1" ] || [ ! -r "$1" ]; then motif_refus="lecture impossible"
  else
    case "$gros_dossiers" in
      *$'\n'"${1%/*}"$'\n'*) # dossier listé par gros_charger
        case "$gros_liste" in *$'\n'"$1"$'\n'*) motif_refus="plus de 1 Mio" ;; esac ;;
      *)
        if ! taille="$(wc -c < "$1" 2>/dev/null)"; then motif_refus="lecture impossible"
        elif [ "$((taille + 0))" -gt "$FICHIER_OCTETS_MAX" ]; then motif_refus="plus de 1 Mio"
        fi ;;
    esac
  fi
}

# En-têtes de toutes les issues (docs/issues/), lus en UN SEUL passage awk par issues_en_tetes_charger : tableaux parallèles dans l'ordre d'issue_fichiers.
#   ent_refus       motif d'un fichier refusé (fichier_motif_refus), vide s'il est lu ; un fichier refusé n'est pas ouvert : ses autres valeurs sont vides
#   ent_ok          1 si l'en-tête YAML s'ouvre et se ferme (ligne « --- » avant et après), sinon 0
#   ent_ids, ent_statuts, ent_besoins, ent_prds, ent_branches, ent_revues   valeurs scalaires, lues comme issue_champ (guillemets de bord et espaces de fin retirés)
#   ent_dependances, ent_commits   éléments des listes depend_de et commits, lus comme issue_liste ; chaque élément est suivi de ENT_FIN_ELEMENT (voir ent_elements)
#   ent_fin_ok      1 si la section « ## Notes » a une ligne contenant « FIN-ISSUE OK <id> » suivi d'une espace (texte littéral, casse comprise)
#   ent_abandon     1 si une ligne à puce (- * +) de cette section contient le mot « Abandonnée »
# Les valeurs sont des données non fiables, jamais évaluées. Les caractères 0x1E et 0x1F (séparateurs de ce flux) y sont remplacés par 0x01 (un contrôle, retiré des messages).
# Coût : un processus quel que soit le nombre d'issues (un awk par issue et par champ coûtait plusieurs secondes par centaine d'issues).
ENT_SEP=$'\037'; ENT_FIN_ELEMENT=$'\036'
ent_charge=0
ent_fichiers=(); ent_refus=(); ent_ok=(); ent_ids=(); ent_statuts=(); ent_besoins=(); ent_prds=(); ent_branches=(); ent_revues=()
ent_dependances=(); ent_commits=(); ent_fin_ok=(); ent_abandon=()

issues_en_tetes_charger() {
  local f liste="" ok id statut besoin prd branche revue dep commits fin ab _
  ent_charge=1
  ent_fichiers=(); ent_refus=(); ent_ok=(); ent_ids=(); ent_statuts=(); ent_besoins=(); ent_prds=(); ent_branches=(); ent_revues=()
  ent_dependances=(); ent_commits=(); ent_fin_ok=(); ent_abandon=()
  gros_charger docs/issues
  while IFS= read -r f; do
    ent_fichiers+=("$f")
    fichier_motif_refus "$f"; ent_refus+=("$motif_refus")
    if [ -n "$motif_refus" ]; then liste="$liste"$'\n'; else liste="$liste$f"$'\n'; fi # une ligne vide pour un fichier refusé : l'enregistrement reste vide
  done < <(issue_fichiers)
  [ "${#ent_fichiers[@]}" -gt 0 ] || return 0
  while IFS="$ENT_SEP" read -r ok id statut besoin prd branche revue dep commits fin ab _; do
    ent_ok+=("$ok"); ent_ids+=("$id"); ent_statuts+=("$statut"); ent_besoins+=("$besoin"); ent_prds+=("$prd"); ent_branches+=("$branche"); ent_revues+=("$revue")
    ent_dependances+=("$dep"); ent_commits+=("$commits"); ent_fin_ok+=("$fin"); ent_abandon+=("$ab")
  done < <(printf '%s' "$liste" | LC_ALL=C awk '
    function valeur(l, cle,   v) { v = l; sub("^" cle ":[[:space:]]*", "", v); gsub(/^["\047]|["\047]$/, "", v); sub(/[[:space:]]+$/, "", v); return v }
    BEGIN {
      SEP = "\037"; FIN = "\036"
      nc = split("id statut besoin prd branche revue", cle, " ")
      nl = split("depend_de commits", lcle, " ")
    }
    {
      f = $0
      if (f == "") { print "0" SEP SEP SEP SEP SEP SEP SEP SEP SEP "0" SEP "0" SEP "."; next }
      split("", val); split("", pris); split("", cap); split("", lst)
      ln = 0; ok = 0; entete = 0; notes = 0; fin = 0; ab = 0; cible = ""
      while ((getline l < f) > 0) {
        ln++
        gsub("[\036\037]", "\001", l)
        if (ln == 1) { if (l != "---") break; entete = 1; continue }
        if (entete) {
          if (l == "---") {
            entete = 0; ok = 1
            ident = val[1]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", ident); cible = "FIN-ISSUE OK " ident " "
            continue
          }
          for (k = 1; k <= nc; k++) if (!(k in pris) && index(l, cle[k] ":") == 1) { val[k] = valeur(l, cle[k]); pris[k] = 1 }
          for (j = 1; j <= nl; j++) {
            fait = 0
            if (cap[j]) {
              if (l ~ /^[[:space:]]*-[[:space:]]+/) { s = l; sub(/^[[:space:]]*-[[:space:]]+/, "", s); gsub(/["\047]|[[:space:]]+$/, "", s); sub(/[[:space:]]*#.*$/, "", s); lst[j] = lst[j] s FIN; fait = 1 }
              else if (l ~ /^[[:space:]]*($|#)/) fait = 1
              else cap[j] = 0
            }
            if (!fait && index(l, lcle[j] ":") == 1) {
              v = l; sub("^" lcle[j] ":[[:space:]]*", "", v)
              if (v ~ /^\[/) {
                gsub(/^\[|\][[:space:]]*$/, "", v); m = split(v, a, /[[:space:]]*,[[:space:]]*/)
                for (q = 1; q <= m; q++) { gsub(/["\047]|^[[:space:]]+|[[:space:]]+$/, "", a[q]); if (a[q] != "") lst[j] = lst[j] a[q] FIN }
              } else if (v == "" || v ~ /^#/) cap[j] = 1
            }
          }
          continue
        }
        if (l ~ /^#[[:space:]]/ || l ~ /^##[[:space:]]/) { notes = (l ~ /^##[[:space:]]+Notes[[:space:]]*$/); continue }
        if (notes) {
          if (index(l, cible)) fin = 1
          if (l ~ /^[[:space:]]*[-*+][[:space:]]/ && index(l, "Abandonnée")) ab = 1
        }
      }
      close(f)
      print ok SEP val[1] SEP val[2] SEP val[3] SEP val[4] SEP val[5] SEP val[6] SEP lst[1] SEP lst[2] SEP fin SEP ab SEP "."
    }')
}

# ent_elements <liste> : met dans le tableau ent_items les éléments d'une liste de l'en-tête (ent_dependances, ent_commits), un élément vide compris.
ent_items=()
ent_elements() {
  local reste="$1"
  ent_items=()
  while [ -n "$reste" ]; do
    ent_items+=("${reste%%"$ENT_FIN_ELEMENT"*}")
    reste="${reste#*"$ENT_FIN_ELEMENT"}"
  done
}

# --- Table unique des statuts (PRD 004, RG-01) --------------------------------------------------------------------------------------------
# Les statuts et les transitions des besoins et des issues sont définis une seule fois, dans factory/scripts/statuts.table (format décrit en tête de ce fichier),
# lu comme du texte (jamais sourcé ni évalué). Le chemin est relatif à la racine du projet, où chaque script se place avant de sourcer cette bibliothèque.
# Chargé une fois, au moment où la bibliothèque est sourcée ; en cas d'échec, table_erreur porte le motif et les tableaux restent vides (table_exiger l'impose).
# Tableaux indexés parallèles (bash 3.2) :
#   table_entite, table_nom, table_portee, table_classe : un élément par statut, dans l'ordre de la table (entité « issue » ou « besoin », portée « cycle » ou « hors-cycle »)
#   tr_entite, tr_de, tr_vers, tr_declencheur, tr_preuve : un élément par transition légale (une transition par statut de départ)
#   statuts_issues, statuts_besoins, statuts_classes_issues, statuts_classes_besoins : les statuts du CYCLE (sans les statuts hors cycle), dans l'ordre, avec leur classe CSS
STATUTS_TABLE="factory/scripts/statuts.table"
table_entite=(); table_nom=(); table_portee=(); table_classe=()
tr_entite=(); tr_de=(); tr_vers=(); tr_declencheur=(); tr_preuve=()
statuts_issues=(); statuts_besoins=(); statuts_classes_issues=(); statuts_classes_besoins=()
table_erreur=""

# table_nettoyer <texte> : met le texte sans espaces de bord dans $nettoye (sans sous-shell : la table est lue à chaque lancement de script).
table_nettoyer() {
  nettoye="$1"
  nettoye="${nettoye#"${nettoye%%[![:space:]]*}"}"
  nettoye="${nettoye%"${nettoye##*[![:space:]]}"}"
}

# statuts_table_charger : remplit les tableaux ci-dessus ; code 1 et table_erreur renseigné si la table est absente ou mal formée (tableaux alors vides).
statuts_table_charger() {
  local type entite a b c d n=0 morceaux=() de
  table_erreur=""
  table_entite=(); table_nom=(); table_portee=(); table_classe=()
  tr_entite=(); tr_de=(); tr_vers=(); tr_declencheur=(); tr_preuve=()
  statuts_issues=(); statuts_besoins=(); statuts_classes_issues=(); statuts_classes_besoins=()
  if [ ! -f "$STATUTS_TABLE" ] || [ ! -r "$STATUTS_TABLE" ]; then table_erreur="table des statuts introuvable ($STATUTS_TABLE)"; return 1; fi
  while IFS='|' read -r type entite a b c d || [ -n "$type" ]; do
    n=$((n + 1))
    table_nettoyer "$type"; type="$nettoye"
    case "$type" in ''|'#'*) continue ;; esac
    table_nettoyer "$entite"; entite="$nettoye"
    case "$entite" in issue|besoin) ;; *) table_erreur="$STATUTS_TABLE ligne $n : entité inconnue (issue ou besoin attendu)"; break ;; esac
    table_nettoyer "$a"; a="$nettoye"; table_nettoyer "$b"; b="$nettoye"; table_nettoyer "$c"; c="$nettoye"; table_nettoyer "$d"; d="$nettoye"
    case "$type" in
      statut)
        case "$b" in cycle|hors-cycle) ;; *) b="" ;; esac
        if [ -z "$a" ] || [ -z "$b" ]; then table_erreur="$STATUTS_TABLE ligne $n : statut sans nom ou sans portée (cycle ou hors-cycle)"; break; fi
        table_entite+=("$entite"); table_nom+=("$a"); table_portee+=("$b"); table_classe+=("$c") ;;
      transition)
        if [ -z "$a" ] || [ -z "$b" ] || [ -z "$c" ] || [ -z "$d" ]; then table_erreur="$STATUTS_TABLE ligne $n : transition incomplète (de, vers, déclencheur, preuve attendus)"; break; fi
        IFS=',' read -r -a morceaux <<< "$a"
        for de in "${morceaux[@]}"; do
          table_nettoyer "$de"
          tr_entite+=("$entite"); tr_de+=("$nettoye"); tr_vers+=("$b"); tr_declencheur+=("$c"); tr_preuve+=("$d")
        done ;;
      *) table_erreur="$STATUTS_TABLE ligne $n : type d'enregistrement inconnu (statut ou transition attendu)"; break ;;
    esac
  done < "$STATUTS_TABLE"
  if [ -z "$table_erreur" ] && [ "${#table_nom[@]}" -eq 0 ]; then table_erreur="$STATUTS_TABLE ne définit aucun statut"; fi
  if [ -n "$table_erreur" ]; then
    table_entite=(); table_nom=(); table_portee=(); table_classe=(); tr_entite=(); tr_de=(); tr_vers=(); tr_declencheur=(); tr_preuve=()
    return 1
  fi
  n=0
  while [ "$n" -lt "${#table_nom[@]}" ]; do
    if [ "${table_portee[$n]}" = cycle ]; then
      case "${table_entite[$n]}" in
        issue) statuts_issues+=("${table_nom[$n]}"); statuts_classes_issues+=("${table_classe[$n]}") ;;
        besoin) statuts_besoins+=("${table_nom[$n]}"); statuts_classes_besoins+=("${table_classe[$n]}") ;;
      esac
    fi
    n=$((n + 1))
  done
}

# table_exiger : arrête le script (code 1, message sur la sortie d'erreur) si la table n'a pas pu être chargée. À appeler par les scripts qui classent ou contrôlent des statuts.
table_exiger() {
  [ -z "$table_erreur" ] || { echo "Erreur : $table_erreur." >&2; exit 1; }
}

# table_statut_connu <issue|besoin> <statut> : vrai si le statut figure dans la table de l'entité (cycle ou hors cycle), comparaison exacte octet pour octet.
table_statut_connu() {
  local i=0
  while [ "$i" -lt "${#table_nom[@]}" ]; do
    [ "${table_entite[$i]}" = "$1" ] && [ "${table_nom[$i]}" = "$2" ] && return 0
    i=$((i + 1))
  done
  return 1
}

# table_statuts_de <issue|besoin> : met dans $statuts_de les statuts de l'entité dans l'ordre de la table, séparés par « , ».
table_statuts_de() {
  local i=0
  statuts_de=""
  while [ "$i" -lt "${#table_nom[@]}" ]; do
    [ "${table_entite[$i]}" = "$1" ] && statuts_de="${statuts_de:+$statuts_de, }${table_nom[$i]}"
    i=$((i + 1))
  done
}

statuts_table_charger

# issue_rang_statut <statut> : rang dans le cycle ; code 1 et rien d'écrit pour un statut inconnu.
issue_rang_statut() {
  local i=0
  while [ "$i" -lt "${#statuts_issues[@]}" ]; do
    [ "${statuts_issues[$i]}" = "$1" ] && { echo "$i"; return 0; }
    i=$((i + 1))
  done
  return 1
}

# Rattachement par convention : une issue dont le champ « branche » est vide est rattachée à la branche LOCALE nommée <type>/<id>-<suffixe>
# (<type> : un segment, <id> : champ « id » de l'issue, comparé comme texte littéral et suivi d'un tiret, <suffixe> non vide).
# Les noms de branche sont des données non fiables : comparés par préfixe littéral (jamais de motif construit avec un nom ou un identifiant),
# jamais passés à un shell. Un seul appel git (for-each-ref) par chargement, et aucun s'il n'y a pas d'issue à champ vide.
# Tableaux indexés parallèles (bash 3.2) : à remplir par rattachements_charger dans le shell principal, puis lisibles par les sous-shells.
BRANCHE_LONGUEUR_MAX=200
rat_fichiers=(); rat_deduites=(); rat_ambigues=()

# issue_id_deductible <id> : vrai si l'identifiant est non vide et ne contient que [A-Za-z0-9._-].
issue_id_deductible() {
  case "$1" in ''|*[!A-Za-z0-9._-]*) return 1 ;; esac
}

# rattachements_charger : calcule, pour chaque issue de docs/issues/, sa branche déduite (rat_deduites) ou la liste de ses branches
# ambiguës « a, b » (rat_ambigues), triée par ordre d'octets (ordre de for-each-ref). À appeler une fois par génération.
rattachements_charger() {
  local f ids=() brs=() i j b type reste id suffixe proprio n vide=0 deduction
  rat_fichiers=(); rat_deduites=(); rat_ambigues=()
  [ "$ent_charge" -eq 1 ] || issues_en_tetes_charger # en-têtes lus une seule fois (et partagés avec le contrôle des statuts)
  for i in "${!ent_fichiers[@]}"; do
    rat_fichiers+=("${ent_fichiers[$i]}"); rat_deduites+=(""); rat_ambigues+=("")
    # Un lien symbolique, un fichier spécial, illisible ou trop gros n'est jamais ouvert (statuts.sh le signale, E14) : identifiant et branche vides, aucune branche à lui rattacher.
    if [ -n "${ent_refus[$i]}" ]; then ids+=(""); brs+=(""); continue; fi
    ids+=("${ent_ids[$i]}"); brs+=("${ent_branches[$i]}")
    [ -n "${ent_branches[$i]}" ] || vide=1
  done
  [ "$vide" -eq 1 ] || return 0
  local candidats=() n_candidats=()
  for i in "${!rat_fichiers[@]}"; do candidats+=(""); n_candidats+=(0); done
  while IFS= read -r b; do
    b="${b#refs/heads/}"
    [ "${#b}" -le "$BRANCHE_LONGUEUR_MAX" ] || continue
    type="${b%%/*}"; reste="${b#*/}"
    [ -n "$type" ] && [ "$type" != "$b" ] || continue
    case "$reste" in */*) continue ;; esac
    # Propriétaire : l'issue dont l'identifiant (valide) est le plus long préfixe « <id>- » de <reste> avec un suffixe non vide.
    proprio=-1; n=0
    for i in "${!rat_fichiers[@]}"; do
      id="${ids[$i]}"
      issue_id_deductible "$id" || continue
      suffixe="${reste#"$id"-}"
      [ "$suffixe" != "$reste" ] && [ -n "$suffixe" ] || continue
      if [ "${#id}" -gt "$n" ]; then n="${#id}"; proprio="$i"; fi
    done
    [ "$proprio" -ge 0 ] || continue
    # Identifiant partagé (même texte pour plusieurs issues) ou issue au champ rempli : pas de déduction, la branche n'est à personne d'autre.
    id="${ids[$proprio]}"; deduction=1
    [ -z "${brs[$proprio]}" ] || deduction=0
    for j in "${!rat_fichiers[@]}"; do [ "$j" -ne "$proprio" ] && [ "${ids[$j]}" = "$id" ] && deduction=0; done
    # Une branche déclarée dans le champ d'une issue n'est jamais déduite pour une autre.
    for j in "${!rat_fichiers[@]}"; do [ "${brs[$j]}" = "$b" ] && deduction=0; done
    [ "$deduction" -eq 1 ] || continue
    candidats[$proprio]="${candidats[$proprio]:+${candidats[$proprio]}, }$b"
    n_candidats[$proprio]=$((${n_candidats[$proprio]} + 1))
  done < <(git for-each-ref --format='%(refname)' refs/heads 2>/dev/null)
  for i in "${!rat_fichiers[@]}"; do
    case "${n_candidats[$i]}" in
      0) ;;
      1) rat_deduites[$i]="${candidats[$i]}" ;;
      *) rat_ambigues[$i]="${candidats[$i]}" ;;
    esac
  done
}

# rat_index <fichier> : rang de l'issue dans les tableaux de rattachement ; code 1 si elle n'y figure pas (tableaux non chargés).
rat_index() {
  local i
  for i in "${!rat_fichiers[@]}"; do [ "${rat_fichiers[$i]}" = "$1" ] && { printf '%s' "$i"; return 0; }; done
  return 1
}

# issue_branche_deduite <fichier> : nom de la branche déduite, rien sinon (champ rempli, ambiguïté, aucune correspondance).
issue_branche_deduite() {
  local i
  i="$(rat_index "$1")" || return 0
  printf '%s' "${rat_deduites[$i]}"
}

# issue_branches_ambigues <fichier> : « a, b » si plusieurs branches conviennent (aucune n'est retenue), rien sinon.
issue_branches_ambigues() {
  local i
  i="$(rat_index "$1")" || return 0
  printf '%s' "${rat_ambigues[$i]}"
}

# issue_ref_branche <fichier> [<indice>] : refs/heads/<nom> de la branche retenue, sinon rien. Le champ « branche » rempli l'emporte (branche locale existante
# exigée, sans repli sur la déduction) ; champ vide : la branche déduite. Le nom est non fiable : validé par git, jamais passé à un shell, toujours préfixé.
# <indice> (rang de l'issue dans les tableaux de lecture groupée, quand les en-têtes sont chargés) évite de relire le fichier et de chercher l'issue dans les tableaux de rattachement.
issue_ref_branche() {
  local b ref
  if [ -n "${2:-}" ] && [ "$ent_charge" -eq 1 ]; then
    b="${ent_branches[$2]}"
    [ -n "$b" ] || b="${rat_deduites[$2]:-}"
  else
    b="$(issue_champ "$1" branche)"
    [ -n "$b" ] || b="$(issue_branche_deduite "$1")"
  fi
  [ -n "$b" ] || return 0
  ref="refs/heads/$b"
  git check-ref-format "$ref" 2>/dev/null || return 0
  git rev-parse --verify -q "$ref^{commit}" >/dev/null 2>&1 || return 0
  printf '%s' "$ref"
}

# Taille maximale (octets) du fichier d'issue lu sur une branche : au-delà, le fichier est écarté (statut local). Une issue fait quelques ko.
ISSUE_BRANCHE_OCTETS_MAX=65536

# issue_statut_distant <ref> <fichier> : statut du fichier de l'issue (MÊME chemin que le local) sur la branche, rien s'il est absent, trop grand
# ou sans en-tête. Un lien symbolique n'est jamais suivi : git show rend le chemin cible comme texte, qui n'a pas d'en-tête. Contenu non fiable : lu comme du texte.
issue_statut_distant() {
  local LC_ALL=C contenu
  contenu="$(git show "$1:./$2" -- 2>/dev/null | head -c $((ISSUE_BRANCHE_OCTETS_MAX + 1)); printf x)"
  contenu="${contenu%x}"
  [ "${#contenu}" -le "$ISSUE_BRANCHE_OCTETS_MAX" ] || return 0
  issue_champ /dev/stdin statut <<< "$contenu"
}

# issue_statut_effectif <fichier> [<ref> [<statut local>]] : le plus avancé dans le cycle du statut local et de celui de la branche retenue de l'issue.
# Branche absente, fichier absent ou illisible sur la branche, statut hors cycle d'un côté : le statut local.
# <ref> (refs/heads/<nom> ou vide) évite de recalculer la branche retenue quand l'appelant l'a déjà ; <statut local> évite de relire le fichier.
issue_statut_effectif() {
  local local_ ref distant r_local r_distant
  local_="${3-$(issue_champ "$1" statut)}"
  ref="${2-$(issue_ref_branche "$1")}"
  if [ -n "$ref" ]; then
    distant="$(issue_statut_distant "$ref" "$1")"
    if r_local="$(issue_rang_statut "$local_")" && r_distant="$(issue_rang_statut "$distant")" && [ "$r_distant" -gt "$r_local" ]; then
      local_="$distant"
    fi
  fi
  printf '%s' "$local_"
}

# issue_dernier_commit <fichier> [<ref>] : « <hash court> du <date> » du dernier commit de la branche de l'issue, vide sans branche.
issue_dernier_commit() {
  local ref
  ref="${2-$(issue_ref_branche "$1")}"
  [ -z "$ref" ] || git log -1 --date=short --format='%h du %ad' "$ref" -- 2>/dev/null
}

# critere_motif_debut <identifiant> : comme critere_motif, mais l'identifiant doit COMMENCER le texte (premier argument d'un test bash).
critere_motif_debut() {
  critere_motif "$1" | sed -E 's/^\(\^\|\[\^a-z\]\)/^/'
}

# critere_motif <identifiant> : expression régulière (grep -E, insensible à la casse) reconnaissant CA-10, ca10, ca_10, « CA 10 ».
critere_motif() {
  local lettres numero
  lettres="$(printf '%s' "$1" | sed -E 's/^([A-Za-z]+).*/\1/' | tr 'A-Z' 'a-z')"
  numero="$(printf '%s' "$1" | sed -E 's/^[A-Za-z]+[-_ ]*0*([0-9]+).*/\1/')"
  printf '(^|[^a-z])%s[-_ ]?0*%s([^0-9]|$)' "$lettres" "$numero"
}
