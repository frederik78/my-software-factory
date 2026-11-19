#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : preuves d'une issue pour scripts/statuts.sh (PRD 004, RG-10 à RG-12 et RG-15).
# Compatible bash 3.2 (macOS). Suppose lib-issues.sh (fichier_motif_refus, en-têtes lus par issues_en_tetes_charger) et lib-constats.sh (constat_neutraliser, constat_ajouter) déjà sourcées.
# Tout ce qui est lu (champs de l'en-tête, fichier de revue, Notes) est une donnée non fiable : jamais évaluée, jamais utilisée comme motif ou comme option,
# neutralisée avant d'entrer dans un message. Aucun fichier n'est écrit.
#
# Une issue Fait (statut local) donne des AVIS A01 à A06 si une preuve manque (jamais une erreur : les issues terminées avant ce contrôle n'en ont pas toutes).
# Une issue En revue donne l'avis A07 sans fichier de revue lisible. Une issue Abandonnée sans raison dans ses Notes donne l'erreur E13.

# revue_chemin <valeur du champ revue> : met dans $revue_chemin la première occurrence de « docs/reviews/<nom>.md » (<nom> : [A-Za-z0-9._-] seulement), vide s'il n'y en a pas (RG-11).
# L'occurrence ne doit être ni précédée ni suivie d'un caractère de chemin ([A-Za-z0-9._/-]) : ni chemin absolu, ni « ../ », ni sous-dossier, ni nom plus long.
# Sans processus externe (une valeur par issue Fait) ; la valeur est comparée à une expression régulière fixe, jamais construite avec elle.
revue_chemin() {
  local LC_ALL=C re='(^|[^A-Za-z0-9._/-])docs/reviews/[A-Za-z0-9._-]+\.md([^A-Za-z0-9._-]|$)' m
  revue_chemin=""
  [[ "$1" =~ $re ]] || return 0
  m="${BASH_REMATCH[0]}"; m="docs/reviews/${m#*docs/reviews/}"
  case "$m" in *d) ;; *) m="${m%?}" ;; esac # retire le caractère qui suit le nom (le « d » de « .md » est le dernier de la valeur quand rien ne suit)
  revue_chemin="$m"
}

# revue_derniere_ligne <fichier> : met dans $revue_ligne la dernière ligne non vide du fichier, sans retour chariot ni espaces de fin (64 octets au plus : une ligne plus longue
# ne peut pas valoir « APPROUVÉ »), dans $revue_verdict 1 si sa première ligne a la forme d'une ligne « VERDICT: » (clé seule, la valeur est lue par verdict-revue.sh), sinon 0,
# et dans $revue_nb le nombre de lignes de verdict du fichier (même définition que verdict_lire, lib-verdict.sh : un seul passage, pas de processus de plus par revue pour l'avis A16).
revue_derniere_ligne() {
  local sortie reste
  sortie="$(LC_ALL=C awk '{ m = ($0 ~ /^[ \t]*[Vv][Ee][Rr][Dd][Ii][Cc][Tt][ \t]*:/) } NR == 1 { v = m } { n += m; sub(/[[:space:]]+$/, "") } $0 != "" { derniere = substr($0, 1, 64) } END { printf "%d %d\n%s", v, n, derniere }' "$1" 2>/dev/null)"
  revue_verdict="${sortie:0:1}"; reste="${sortie#* }"; revue_nb="${reste%%
*}"; revue_ligne="${reste#*
}"
}

# revue_examiner <valeur du champ revue> <lire la dernière ligne : 0|1> : met dans $revue_lisible 1 si le champ désigne un fichier de revue lisible (RG-11), sinon 0 ;
# $revue_chemin (vide si le champ n'a pas la forme attendue) et, si demandé, $revue_ligne.
# Un lien symbolique (le fichier ou le dossier docs/reviews), un fichier de plus de 1 Mio ou non lisible équivaut à un fichier introuvable.
revue_examiner() {
  revue_lisible=0; revue_ligne=""; revue_verdict=0; revue_nb=""
  revue_chemin "$1"
  [ -n "$revue_chemin" ] || return 0
  [ ! -L docs/reviews ] || return 0
  fichier_motif_refus "$revue_chemin"
  [ -z "$motif_refus" ] || return 0
  revue_lisible=1
  [ "$2" -eq 0 ] || revue_derniere_ligne "$revue_chemin"
}

# revue_approuvee : vrai si le fichier de revue examiné (après revue_examiner ... 1) est approuvé : sa première ligne est un verdict « VERDICT: APPROUVÉ » au sens de
# lib-verdict.sh (lu seulement si la première ligne a cette forme, sur un fichier déjà borné : régulier, non lien, au plus 1 Mio), ou, sans verdict lisible (revues d'avant F-01),
# sa dernière ligne non vide est exactement « APPROUVÉ ». Un verdict CHANGEMENTS DEMANDÉS n'est jamais approuvé.
revue_approuvee() {
  if [ "$revue_verdict" = 1 ]; then
    verdict_lire "$revue_chemin" 1
    [ "$verdict" = "APPROUVÉ" ] && return 0
    [ "$verdict" = "CHANGEMENTS DEMANDÉS" ] && return 1
  fi
  [ "$revue_ligne" = "APPROUVÉ" ]
}

# Commits déclarés de toutes les issues Fait, vérifiés en un seul appel Git (preuves_commits_verifier) : tableaux parallèles remplis par preuves_commits.
commits_noms=(); commits_rangs=(); commits_ids=()

# commit_hexadecimal <valeur> : vrai si la valeur est hexadécimale, de 7 à 40 caractères (RG-22) : seule forme soumise à Git, jamais une option ni une révision.
commit_hexadecimal() {
  case "$1" in ''|*[!0123456789abcdefABCDEF]*) return 1 ;; esac
  [ "${#1}" -ge 7 ] && [ "${#1}" -le 40 ]
}

# preuves_commits <rang> <indice> <id> : A05 (aucun commit déclaré) et A06 immédiat pour une valeur non hexadécimale (sans appel Git) ;
# les valeurs hexadécimales sont mises en attente pour preuves_commits_verifier. <indice> : rang de l'issue dans les en-têtes lus (ent_commits).
preuves_commits() {
  local rang="$1" commit
  ent_elements "${ent_commits[$2]}"
  for commit in "${ent_items[@]+"${ent_items[@]}"}"; do
    if commit_hexadecimal "$commit"; then
      commits_noms+=("$commit"); commits_rangs+=("$rang"); commits_ids+=("$3")
    else
      constat_neutraliser "$commit"; commits_signaler "$rang" "$3" "$neutre"
    fi
  done
  if [ "${#ent_items[@]}" -eq 0 ]; then
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

# revue_forme_signaler <rang> <objet neutralisé> : avis A16 si le fichier de revue examiné (revue_examiner a donné revue_lisible = 1) est mal formé (RG-08 à RG-11 du PRD 005) :
# plus d'une ligne de verdict, ou première ligne qui n'est pas une ligne de verdict alors qu'il en a une (un fichier sans ligne de verdict, d'avant F-01, ne l'est jamais). Un avis au plus
# par issue (la cause « plus d'une » l'emporte). Cause = texte fixe, jamais un morceau du fichier. Décompte : celui de revue_derniere_ligne, ou un seul grep (verdict_forme, lib-verdict.sh) sans lui ; aucun appel Git.
revue_forme_signaler() {
  local chemin
  if [ -n "$revue_nb" ]; then # décompte déjà fait par revue_derniere_ligne (revue_examiner ... 1)
    if [ "$revue_nb" -gt 1 ]; then verdict_forme_cause=plus; elif [ "$revue_nb" -eq 1 ] && [ "$revue_verdict" -eq 0 ]; then verdict_forme_cause=premiere; else verdict_forme_cause=""; fi
  else
    verdict_forme "$revue_chemin"
  fi
  [ -n "$verdict_forme_cause" ] || return 0
  constat_neutraliser "$revue_chemin"; chemin="$neutre"
  case "$verdict_forme_cause" in
    plus) constat_ajouter AVIS A16 2 "$1" "$2" "fichier de revue mal formé $chemin : plus d'une ligne VERDICT:" ;;
    *) constat_ajouter AVIS A16 2 "$1" "$2" "fichier de revue mal formé $chemin : la première ligne n'est pas la ligne VERDICT:" ;;
  esac
}

# preuves_fait <rang> <indice> <id> : avis A01 à A06 d'une issue dont le statut local est Fait. <indice> : rang de l'issue dans les en-têtes lus (issues_en_tetes_charger).
preuves_fait() {
  local rang="$1" indice="$2" id="$3" revue objet chemin
  constat_neutraliser "$id"; objet="issue $neutre"
  revue="${ent_revues[$indice]}"
  if [ -z "$revue" ]; then
    constat_ajouter AVIS A01 2 "$rang" "$objet" "Fait sans champ revue renseigné"
  else
    revue_examiner "$revue" 1
    if [ "$revue_lisible" -eq 0 ]; then
      constat_neutraliser "${revue_chemin:-$revue}"
      constat_ajouter AVIS A02 2 "$rang" "$objet" "Fait : fichier de revue introuvable ou illisible ($neutre)"
    else
      if ! revue_approuvee; then
        constat_neutraliser "$revue_chemin"; chemin="$neutre"
        constat_ajouter AVIS A03 2 "$rang" "$objet" "Fait : la dernière ligne de $chemin n'est pas APPROUVÉ"
      fi
      revue_forme_signaler "$rang" "$objet"
    fi
  fi
  [ "${ent_fin_ok[$indice]}" -eq 1 ] || constat_ajouter AVIS A04 2 "$rang" "$objet" "Fait sans ligne « FIN-ISSUE OK ${objet#issue } » dans les Notes"
  preuves_commits "$rang" "$indice" "$id"
}

# preuves_en_revue <rang> <indice> <id> : avis A07 d'une issue dont le statut local est En revue et dont le champ revue ne désigne aucun fichier de revue lisible
# (quelle que soit sa dernière ligne : le verdict n'est exigé qu'à Fait). Un champ vide s'affiche entre parenthèses vides.
preuves_en_revue() {
  local revue valeur
  revue="${ent_revues[$2]}"
  revue_examiner "$revue" 0
  if [ "$revue_lisible" -eq 1 ]; then
    constat_neutraliser "$3"; revue_forme_signaler "$1" "issue $neutre"
    return 0
  fi
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

# preuves_abandon <rang> <indice> <id> : erreur E13 d'une issue Abandonnée dont la section Notes n'a aucune ligne à puce contenant le mot « Abandonnée » (la raison).
# La qualité de la raison n'est pas jugée.
preuves_abandon() {
  [ "${ent_abandon[$2]}" -eq 0 ] || return 0
  constat_neutraliser "$3"
  constat_ajouter ERREUR E13 2 "$1" "issue $neutre" "statut Abandonnée sans raison dans les Notes"
}
