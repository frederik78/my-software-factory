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

# notes_lire <fichier> <id> : lit la section « ## Notes » du fichier (de son titre au titre suivant de niveau 1 ou 2 ; l'en-tête YAML n'en fait pas partie) et met dans
#   $notes_fin_ok   1 si une de ses lignes contient « FIN-ISSUE OK <id> » suivi d'une espace (texte littéral, casse comprise), sinon 0 ;
#   $notes_abandon  1 si une de ses lignes à puce (- * +) contient le mot « Abandonnée », sinon 0.
# Un seul passage awk en octets (LC_ALL=C) ; l'identifiant arrive par l'environnement (ENVIRON : aucune interprétation des barres obliques inverses), jamais comme motif.
notes_lire() {
  local sortie
  sortie="$(NOTES_ID="$2" LC_ALL=C awk '
    BEGIN { cible = "FIN-ISSUE OK " ENVIRON["NOTES_ID"] " " }
    NR == 1 { entete = 1; next }
    entete { if ($0 == "---") entete = 0; next }
    /^#[[:space:]]/ || /^##[[:space:]]/ { notes = ($0 ~ /^##[[:space:]]+Notes[[:space:]]*$/); next }
    notes {
      if (index($0, cible)) fin = 1
      if ($0 ~ /^[[:space:]]*[-*+][[:space:]]/ && index($0, "Abandonnée")) abandon = 1
    }
    END { printf "%d%d", fin, abandon }' "$1" 2>/dev/null)"
  notes_fin_ok="${sortie:0:1}"; notes_abandon="${sortie:1:1}"
  [ -n "$notes_fin_ok" ] || { notes_fin_ok=0; notes_abandon=0; }
}

# Commits déclarés de toutes les issues Fait, vérifiés en un seul appel Git (preuves_commits_verifier) : tableaux parallèles remplis par preuves_commits.
commits_noms=(); commits_rangs=(); commits_ids=()

# commit_hexadecimal <valeur> : vrai si la valeur est hexadécimale, de 7 à 40 caractères (RG-22) : seule forme soumise à Git, jamais une option ni une révision.
commit_hexadecimal() {
  case "$1" in ''|*[!0123456789abcdefABCDEF]*) return 1 ;; esac
  [ "${#1}" -ge 7 ] && [ "${#1}" -le 40 ]
}

# preuves_commits <rang> <fichier> <id> : A05 (aucun commit déclaré) et A06 immédiat pour une valeur non hexadécimale (sans appel Git) ;
# les valeurs hexadécimales sont mises en attente pour preuves_commits_verifier.
preuves_commits() {
  local rang="$1" commit nb=0
  while IFS= read -r commit; do
    nb=$((nb + 1))
    if commit_hexadecimal "$commit"; then
      commits_noms+=("$commit"); commits_rangs+=("$rang"); commits_ids+=("$3")
    else
      constat_neutraliser "$commit"; commits_signaler "$rang" "$3" "$neutre"
    fi
  done < <(issue_liste "$2" commits)
  if [ "$nb" -eq 0 ]; then
    constat_neutraliser "$3"
    constat_ajouter AVIS A05 2 "$rang" "issue $neutre" "Fait sans commit déclaré"
  fi
}

# commits_signaler <rang> <id> <valeur neutralisée> : A06.
commits_signaler() {
  constat_neutraliser "$2"
  constat_ajouter AVIS A06 2 "$1" "issue $neutre" "commit déclaré introuvable : $3"
}

# preuves_commits_verifier : un seul appel « git cat-file --batch-check » pour tous les commits en attente (aucun s'il n'y en a pas) ; A06 pour chacun qui n'est pas un commit.
# Les noms sont passés en minuscules sur l'entrée standard (jamais comme argument). Git résout une abréviation aussi par un nom de branche : le commit trouvé doit
# donc commencer par la valeur déclarée, sinon elle est tenue pour introuvable. Lecture seule : cat-file ne touche ni l'index ni les refs.
preuves_commits_verifier() {
  local nom oid type k=0 minuscules=() trouves=()
  [ "${#commits_noms[@]}" -gt 0 ] || return 0
  while IFS= read -r nom; do minuscules+=("$nom"); done < <(printf '%s\n' "${commits_noms[@]}" | LC_ALL=C tr 'A-F' 'a-f')
  while IFS=' ' read -r oid type _; do
    if [ "$type" = commit ]; then case "$oid" in "${minuscules[$k]}"*) trouves[$k]=1 ;; esac; fi
    k=$((k + 1))
  done < <(printf '%s\n' "${minuscules[@]}" | git cat-file --batch-check 2>/dev/null)
  for k in "${!commits_noms[@]}"; do
    [ "${trouves[$k]:-0}" -eq 1 ] && continue
    constat_neutraliser "${commits_noms[$k]}"; commits_signaler "${commits_rangs[$k]}" "${commits_ids[$k]}" "$neutre"
  done
}

# preuves_fait <rang> <fichier> <id> : avis A01 à A06 d'une issue dont le statut local est Fait.
preuves_fait() {
  local rang="$1" fichier="$2" id="$3" revue objet chemin
  constat_neutraliser "$id"; objet="issue $neutre"
  revue="$(issue_champ "$fichier" revue)"
  if [ -z "$revue" ]; then
    constat_ajouter AVIS A01 2 "$rang" "$objet" "Fait sans champ revue renseigné"
  else
    revue_examiner "$revue" 1
    if [ "$revue_lisible" -eq 0 ]; then
      constat_neutraliser "${revue_chemin:-$revue}"
      constat_ajouter AVIS A02 2 "$rang" "$objet" "Fait : fichier de revue introuvable ou illisible ($neutre)"
    elif [ "$revue_ligne" != "APPROUVÉ" ]; then
      constat_neutraliser "$revue_chemin"; chemin="$neutre"
      constat_ajouter AVIS A03 2 "$rang" "$objet" "Fait : la dernière ligne de $chemin n'est pas APPROUVÉ"
    fi
  fi
  notes_lire "$fichier" "$id"
  [ "$notes_fin_ok" -eq 1 ] || constat_ajouter AVIS A04 2 "$rang" "$objet" "Fait sans ligne « FIN-ISSUE OK ${objet#issue } » dans les Notes"
  preuves_commits "$rang" "$fichier" "$id"
}

# preuves_en_revue <rang> <fichier> <id> : avis A07 d'une issue dont le statut local est En revue et dont le champ revue ne désigne aucun fichier de revue lisible
# (quelle que soit sa dernière ligne : le verdict n'est exigé qu'à Fait). Un champ vide s'affiche entre parenthèses vides.
preuves_en_revue() {
  local revue valeur
  revue="$(issue_champ "$2" revue)"
  revue_examiner "$revue" 0
  [ "$revue_lisible" -eq 0 ] || return 0
  constat_neutraliser "${revue_chemin:-$revue}"; valeur="$neutre"
  constat_neutraliser "$3"
  constat_ajouter AVIS A07 2 "$1" "issue $neutre" "En revue sans fichier de revue ($valeur)"
}

# preuves_branche <rang> <id> <statut effectif> <branches ambiguës> : avis A08 d'une issue En cours ou En revue (statut effectif) dont aucune branche n'est retenue
# (aucune, ou plusieurs qui conviennent par convention de nommage : la liste « a, b » vient de lib-issues.sh, vide sinon). Les noms de branche sont des données non fiables.
preuves_branche() {
  local statut
  constat_neutraliser "$2"; statut="issue $neutre"
  if [ -n "$4" ]; then
    constat_neutraliser "$4"
    constat_ajouter AVIS A08 2 "$1" "$statut" "$3 : branche ambiguë : $neutre"
  else
    constat_ajouter AVIS A08 2 "$1" "$statut" "$3 sans branche retenue"
  fi
}
