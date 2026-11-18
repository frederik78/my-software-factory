#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : fusion des branches dans la branche locale develop, pour scripts/statuts.sh (PRD 004, RG-14 et RG-25).
# Compatible bash 3.2 (macOS). Suppose lib-issues.sh (ISSUE_BRANCHE_OCTETS_MAX) déjà sourcée.
# La fusion se lit relativement à la branche locale develop (nom fixe), jamais à la branche courante. Lecture seule : for-each-ref et cat-file ne touchent ni l'index
# ni les refs, ne rafraîchissent rien et n'exécutent aucun programme configuré. Au plus deux appels Git (la liste des branches fusionnées, puis la sonde par lot), quel que soit le nombre d'issues et de branches.
# Tout ce qui est lu (noms de branche, contenu des fichiers d'issue de develop) est une donnée non fiable : jamais évaluée, jamais passée à un shell.

FUSION_REF="refs/heads/develop"
fus_connue=0   # 1 si la branche develop existe (la liste des branches fusionnées a pu être lue)
fus_refs=""    # les refs refs/heads/<nom> fusionnées dans develop (develop comprise), une par ligne

# fusion_charger : un seul appel, qui sert aussi de test d'existence de develop (il échoue si la branche est absente).
fusion_charger() {
  fus_refs=""; fus_connue=0
  fus_refs="$(git for-each-ref --merged="$FUSION_REF" --format='%(refname)' refs/heads 2>/dev/null)" && fus_connue=1
  return 0
}

# fusion_nom_sur <nom de branche> : vrai si le nom n'a que des caractères [A-Za-z0-9._/-] et n'est pas vide. Le nom est transmis à Git sous la forme refs/heads/<nom> (jamais lu comme
# une option) : sans ces seuls caractères il ne peut pas être lu comme une révision (@{, ^, ~, :, espace). Un nom invalide pour Git (« .. », « // ») désigne simplement une branche absente.
fusion_nom_sur() {
  local LC_ALL=C
  case "$1" in ''|*[!A-Za-z0-9._/-]*) return 1 ;; esac
}

# fusion_sonder <nom d'objet>... : un seul appel « git cat-file --batch » (les noms sur l'entrée standard, jamais en argument) ; écrit un jeu de 1 ou 0 par nom, dans l'ordre :
#   nom d'un commit (refs/heads/<nom>) : 1 si la branche existe ;
#   nom d'un fichier (refs/heads/develop:<fichier d'issue>) : 1 si le fichier tel qu'il est dans develop a le statut « Fait » (même lecture de l'en-tête que issue_champ), 0 s'il est absent
#   de develop, trop gros (ISSUE_BRANCHE_OCTETS_MAX) ou sans en-tête ; tout autre type d'objet : 0.
# Les octets du flux sont comptés pour suivre le découpage de Git (LC_ALL=C) : un découpage perdu arrête la lecture, les noms restants comptent pour 0 (échec sûr).
# Aucun nom ne contient de saut de ligne (les chemins viennent de issue_fichiers, qui lit ligne à ligne ; les noms de branche passent par fusion_nom_sur).
fusion_sonder() {
  local nom
  for nom in "$@"; do printf '%s\n' "$nom"; done | git cat-file --batch 2>/dev/null | LC_ALL=C awk -v max="$ISSUE_BRANCHE_OCTETS_MAX" '
    function nettoie(x) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", x); return x }
    attente == 0 {
      if ($0 ~ /^[0-9a-f]+ (blob|commit|tree|tag) [0-9]+$/) { type = $2; taille = $3 + 0; reste = taille + 1; attente = 1; ligne = 0; entete = 0; fait = 0; lu = 0; next }
      if ($0 ~ / (missing|ambiguous)$/) { print 0; next }
      exit
    }
    {
      reste -= length($0) + 1; ligne++
      if (type == "blob" && taille <= max && !lu) {
        if (ligne == 1) { if ($0 == "---") entete = 1; else lu = 1 }
        else if (entete && $0 == "---") lu = 1
        else if (entete && index($0, "statut:") == 1) { v = $0; sub(/^statut:[[:space:]]*/, "", v); gsub(/^["\047]|["\047]$/, "", v); fait = (nettoie(v) == "Fait"); lu = 1 }
      }
      if (reste < 0) exit
      if (reste == 0) { print (type == "commit") ? 1 : fait; attente = 0 }
    }'
}
