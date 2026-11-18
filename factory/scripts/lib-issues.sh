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

# Statuts d'une issue, dans l'ordre du cycle (docs/issues/README.md).
statuts_issues=("À faire" "En cours" "En revue" "Fait")

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
  while IFS= read -r f; do
    rat_fichiers+=("$f"); ids+=("$(issue_champ "$f" id)"); brs+=("$(issue_champ "$f" branche)")
    rat_deduites+=(""); rat_ambigues+=("")
    [ -n "${brs[${#brs[@]}-1]}" ] || vide=1
  done < <(issue_fichiers)
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

# issue_ref_branche <fichier> : refs/heads/<nom> de la branche retenue, sinon rien. Le champ « branche » rempli l'emporte (branche locale existante
# exigée, sans repli sur la déduction) ; champ vide : la branche déduite. Le nom est non fiable : validé par git, jamais passé à un shell, toujours préfixé.
issue_ref_branche() {
  local b ref
  b="$(issue_champ "$1" branche)"
  [ -n "$b" ] || b="$(issue_branche_deduite "$1")"
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

# issue_statut_effectif <fichier> [<ref>] : le plus avancé dans le cycle du statut local et de celui de la branche retenue de l'issue.
# Branche absente, fichier absent ou illisible sur la branche, statut hors cycle d'un côté : le statut local.
# <ref> (refs/heads/<nom> ou vide) évite de recalculer la branche retenue quand l'appelant l'a déjà.
issue_statut_effectif() {
  local local_ ref distant r_local r_distant
  local_="$(issue_champ "$1" statut)"
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
