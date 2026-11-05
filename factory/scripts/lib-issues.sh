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

# issue_ref_branche <fichier> : refs/heads/<nom> si le champ « branche » nomme une branche locale existante, sinon rien.
# Le nom vient d'un fichier, donc non fiable : validé par git, jamais passé à un shell, toujours préfixé (ni option, ni intervalle).
issue_ref_branche() {
  local b ref
  b="$(issue_champ "$1" branche)"
  [ -n "$b" ] || return 0
  ref="refs/heads/$b"
  git check-ref-format "$ref" 2>/dev/null || return 0
  git rev-parse --verify -q "$ref^{commit}" >/dev/null 2>&1 || return 0
  printf '%s' "$ref"
}

# issue_statut_effectif <fichier> : le plus avancé dans le cycle du statut local et de celui de la branche de l'issue.
# Branche absente, fichier absent sur la branche ou statut inconnu d'un côté : le statut local.
issue_statut_effectif() {
  local local_ ref distant r_local r_distant
  local_="$(issue_champ "$1" statut)"
  ref="$(issue_ref_branche "$1")"
  if [ -n "$ref" ]; then
    distant="$(git show "$ref:./$1" -- 2>/dev/null | issue_champ /dev/stdin statut)"
    if r_local="$(issue_rang_statut "$local_")" && r_distant="$(issue_rang_statut "$distant")" && [ "$r_distant" -gt "$r_local" ]; then
      local_="$distant"
    fi
  fi
  printf '%s' "$local_"
}

# issue_dernier_commit <fichier> : « <hash court> du <date> » du dernier commit de la branche de l'issue, vide sans branche.
issue_dernier_commit() {
  local ref
  ref="$(issue_ref_branche "$1")"
  [ -z "$ref" ] || git log -1 --date=short --format='%h du %ad' "$ref" -- 2>/dev/null
}

# critere_motif <identifiant> : expression régulière (grep -E, insensible à la casse) reconnaissant CA-10, ca10, ca_10, « CA 10 ».
critere_motif() {
  local lettres numero
  lettres="$(printf '%s' "$1" | sed -E 's/^([A-Za-z]+).*/\1/' | tr 'A-Z' 'a-z')"
  numero="$(printf '%s' "$1" | sed -E 's/^[A-Za-z]+[-_ ]*0*([0-9]+).*/\1/')"
  printf '(^|[^a-z])%s[-_ ]?0*%s([^0-9]|$)' "$lettres" "$numero"
}
