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

# critere_motif <identifiant> : expression régulière (grep -E, insensible à la casse) reconnaissant CA-10, ca10, ca_10, « CA 10 ».
critere_motif() {
  local lettres numero
  lettres="$(printf '%s' "$1" | sed -E 's/^([A-Za-z]+).*/\1/' | tr 'A-Z' 'a-z')"
  numero="$(printf '%s' "$1" | sed -E 's/^[A-Za-z]+[-_ ]*0*([0-9]+).*/\1/')"
  printf '(^|[^a-z])%s[-_ ]?0*%s([^0-9]|$)' "$lettres" "$numero"
}
