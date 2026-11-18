#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : preuves d'une issue pour scripts/statuts.sh (PRD 004, RG-10 à RG-12 et RG-15).
# Compatible bash 3.2 (macOS). Suppose lib-issues.sh (issue_champ, issue_liste) et lib-constats.sh (constat_neutraliser, constat_ajouter) déjà sourcées.
# Tout ce qui est lu (champs de l'en-tête, fichier de revue, Notes) est une donnée non fiable : jamais évaluée, jamais utilisée comme motif ou comme option,
# neutralisée avant d'entrer dans un message. Aucun fichier n'est écrit.
#
# Une issue Fait (statut local) donne des AVIS A01 à A06 si une preuve manque (jamais une erreur : les issues terminées avant ce contrôle n'en ont pas toutes).
# Une issue En revue donne l'avis A07 sans fichier de revue lisible. Une issue Abandonnée sans raison dans ses Notes donne l'erreur E13.

# Taille maximale (octets) d'un fichier lu (fichier d'issue, fichier de revue) : au-delà, le fichier est refusé et n'est jamais lu.
PREUVES_OCTETS_MAX=1048576

# fichier_motif_refus <fichier> : met dans $motif_refus pourquoi le fichier n'est pas lu (« lien symbolique », « lecture impossible », « plus de 1 Mio »), vide s'il peut l'être.
# Le fichier n'est ouvert qu'après ces vérifications : un lien symbolique n'est jamais suivi, un gros fichier ni un fichier spécial jamais lu.
fichier_motif_refus() {
  local taille
  motif_refus=""
  if [ -L "$1" ]; then motif_refus="lien symbolique"
  elif [ ! -f "$1" ] || [ ! -r "$1" ]; then motif_refus="lecture impossible"
  elif ! taille="$(wc -c < "$1" 2>/dev/null)"; then motif_refus="lecture impossible"
  elif [ "$((taille + 0))" -gt "$PREUVES_OCTETS_MAX" ]; then motif_refus="plus de 1 Mio"
  fi
}

# revue_chemin <valeur du champ revue> : met dans $revue_chemin la première occurrence de « docs/reviews/<nom>.md » (<nom> : [A-Za-z0-9._-] seulement), vide s'il n'y en a pas (RG-11).
# L'occurrence ne doit être ni précédée ni suivie d'un caractère de chemin ([A-Za-z0-9._/-]) : ni chemin absolu, ni « ../ », ni sous-dossier, ni nom plus long.
# Un seul passage awk (coût linéaire), la valeur arrive par l'entrée standard.
revue_chemin() {
  revue_chemin="$(printf '%s\n' "$1" | LC_ALL=C awk '
    {
      if (match($0, "(^|[^A-Za-z0-9._/-])docs/reviews/[A-Za-z0-9._-]+\\.md([^A-Za-z0-9._-]|$)")) {
        m = substr($0, RSTART, RLENGTH); m = substr(m, index(m, "docs/reviews/"))
        if (substr(m, length(m)) != "d") m = substr(m, 1, length(m) - 1)
        printf "%s", m
      }
      exit
    }')"
}

# revue_derniere_ligne <fichier> : met dans $revue_ligne la dernière ligne non vide du fichier, sans retour chariot ni espaces de fin.
revue_derniere_ligne() {
  revue_ligne="$(LC_ALL=C awk '{ sub(/[[:space:]]+$/, "") } $0 != "" { derniere = $0 } END { printf "%s", derniere }' "$1" 2>/dev/null)"
}

# revue_examiner <valeur du champ revue> <lire la dernière ligne : 0|1> : met dans $revue_lisible 1 si le champ désigne un fichier de revue lisible (RG-11), sinon 0 ;
# $revue_chemin (vide si le champ n'a pas la forme attendue) et, si demandé, $revue_ligne.
# Un lien symbolique (le fichier, docs ou docs/reviews), un fichier de plus de 1 Mio ou non lisible équivaut à un fichier introuvable.
revue_examiner() {
  revue_lisible=0; revue_ligne=""
  revue_chemin "$1"
  [ -n "$revue_chemin" ] || return 0
  [ ! -L docs ] && [ ! -L docs/reviews ] || return 0
  fichier_motif_refus "$revue_chemin"
  [ -z "$motif_refus" ] || return 0
  revue_lisible=1
  [ "$2" -eq 0 ] || revue_derniere_ligne "$revue_chemin"
}

# preuves_fait <rang> <fichier> <id> : avis A01 à A03 d'une issue dont le statut local est Fait (les autres preuves : voir la suite de ce fichier).
preuves_fait() {
  local rang="$1" fichier="$2" id="$3" revue objet chemin
  constat_neutraliser "$id"; objet="issue $neutre"
  revue="$(issue_champ "$fichier" revue)"
  if [ -z "$revue" ]; then
    constat_ajouter AVIS A01 2 "$rang" "$objet" "Fait sans champ revue renseigné"
    return 0
  fi
  revue_examiner "$revue" 1
  if [ "$revue_lisible" -eq 0 ]; then
    constat_neutraliser "${revue_chemin:-$revue}"
    constat_ajouter AVIS A02 2 "$rang" "$objet" "Fait : fichier de revue introuvable ou illisible ($neutre)"
  elif [ "$revue_ligne" != "APPROUVÉ" ]; then
    constat_neutraliser "$revue_chemin"; chemin="$neutre"
    constat_ajouter AVIS A03 2 "$rang" "$objet" "Fait : la dernière ligne de $chemin n'est pas APPROUVÉ"
  fi
}
