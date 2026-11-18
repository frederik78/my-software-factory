#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : besoins de backlog.md pour scripts/statuts.sh (PRD 004, RG-04, RG-06, RG-08 et RG-14 à RG-19).
# Compatible bash 3.2 (macOS). Suppose lib-issues.sh (table des statuts) et lib-constats.sh (constat_neutraliser, constat_ajouter) déjà sourcées.
# Tout ce qui est lu (cellules du backlog) est une donnée non fiable : jamais évaluée, jamais utilisée comme motif ou comme option, neutralisée avant d'entrer dans un message.

# Besoins lus dans backlog.md (tableaux parallèles remplis par controle_besoins, un élément par ligne du tableau, dans l'ordre ; rang = indice + 1) :
#   bes_types      R (ligne lisible) ou L (nombre de colonnes différent de l'en-tête)
#   bes_ids, bes_statuts, bes_prds (cellule PRD), bes_decisions, bes_chemins (chemins docs/prd/<nom>.md de la cellule PRD, séparés par une espace)
#   bes_etats      controlee (identifiant unique, statut connu : seules ces lignes reçoivent les autres constats) ou ignoree
bes_table=0; bes_types=(); bes_ids=(); bes_statuts=(); bes_prds=(); bes_decisions=(); bes_chemins=(); bes_etats=()

# besoins_lire : lit le premier tableau de backlog.md dont l'en-tête a les colonnes ID, Statut et PRD (RG-04), colonnes repérées par leur nom, cellules sans espaces de bord,
# « \| » = barre littérale. Une ligne par enregistrement, champs séparés par CONSTAT_SEP :
#   N                                                       aucun tableau reconnu
#   L <id>                                                  ligne dont le nombre de colonnes diffère de l'en-tête
#   R <id> <statut> <doublon> <PRD> <Décisions> <chemins>   ligne lisible ; doublon = 1 sur la première ligne d'un identifiant qui revient, 2 sur les suivantes ;
#                                                           chemins = les chemins docs/prd/<nom>.md de la cellule PRD (64 au plus), séparés par une espace
# Une ligne sans identifiant n'est pas un besoin (comme dans le dashboard). Les valeurs ne sont qu'imprimées : jamais évaluées ni utilisées comme motif.
# Un chemin de PRD est une suite maximale de caractères [A-Za-z0-9._/-] de la forme docs/prd/<nom>.md : ni précédée ni suivie d'un caractère de chemin (comme RG-11).
besoins_lire() {
  LC_ALL=C awk -v OFS="$CONSTAT_SEP" '
    function trim(x) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", x); return x }
    function cellules(ligne,   k) {
      gsub(/\037/, "\357\277\275", ligne) # 0x1F est le séparateur des enregistrements : une cellule qui en contient ne peut pas passer pour valide (U+FFFD à la place)
      gsub(/\\\|/, "\001", ligne)
      sub(/^[[:space:]]*\|/, "", ligne); sub(/\|[[:space:]]*$/, "", ligne)
      nc = split(ligne, c, "|")
      for (k = 1; k <= nc; k++) { c[k] = trim(c[k]); gsub(/\001/, "|", c[k]) }
    }
    function chemins(cellule,   mots, nm, k, liste, nl) {
      nm = split(cellule, mots, "[^A-Za-z0-9._/-]+"); liste = ""; nl = 0
      for (k = 1; k <= nm && nl < 64; k++)
        if (mots[k] ~ /^docs\/prd\/[A-Za-z0-9._-]+\.md$/) { liste = liste (nl ? " " : "") mots[k]; nl++ }
      return liste
    }
    etat == 1 && $0 !~ /^[[:space:]]*\|/ { exit }
    $0 ~ /^[[:space:]]*\|/ {
      cellules($0)
      if (etat == 0) {
        ii = 0; is = 0; ip = 0; id_ = 0
        for (k = 1; k <= nc; k++) { if (c[k] == "ID") ii = k; if (c[k] == "Statut") is = k; if (c[k] == "PRD") ip = k; if (c[k] == "Décisions") id_ = k }
        if (ii && is && ip) { etat = 1; ncol = nc }
        next
      }
      sep = 1; for (k = 1; k <= nc; k++) if (c[k] !~ /^:?-+:?$/) sep = 0
      if (sep) next
      id = (ii <= nc ? c[ii] : ""); if (id == "") next
      n++; rtype[n] = (nc == ncol ? "R" : "L"); rid[n] = id; rst[n] = (is <= nc ? c[is] : "")
      rprd[n] = (ip <= nc ? c[ip] : ""); rdec[n] = (id_ && id_ <= nc ? c[id_] : ""); rchem[n] = chemins(rprd[n])
      if (nc == ncol) fois[id]++
    }
    END {
      if (etat == 0) { print "N"; exit }
      for (k = 1; k <= n; k++) {
        if (rtype[k] == "L") { print "L", rid[k]; continue }
        dup = (fois[rid[k]] > 1) ? ((rid[k] in vu) ? 2 : 1) : 0; vu[rid[k]] = 1
        print "R", rid[k], rst[k], dup, rprd[k], rdec[k], rchem[k]
      }
    }
  ' backlog.md
}

# controle_besoins : E02 (aucun tableau), E03 (ligne illisible), E04 (identifiant en double), E05 (statut inconnu) pour les besoins de backlog.md ; remplit les tableaux bes_*.
controle_besoins() {
  local typ id statut dup prd decisions chemins rang=0 attendus etat
  bes_table=0; bes_types=(); bes_ids=(); bes_statuts=(); bes_prds=(); bes_decisions=(); bes_chemins=(); bes_etats=()
  table_statuts_de besoin; attendus="$statuts_de"
  while IFS="$CONSTAT_SEP" read -r typ id statut dup prd decisions chemins; do
    if [ "$typ" = N ]; then
      constat_ajouter ERREUR E02 0 0 backlog "tableau des besoins introuvable (colonnes ID, Statut, PRD attendues)"; continue
    fi
    bes_table=1; rang=$((rang + 1)); etat=ignoree
    bes_types+=("$typ"); bes_ids+=("$id"); bes_statuts+=("${statut:-}"); bes_prds+=("${prd:-}"); bes_decisions+=("${decisions:-}"); bes_chemins+=("${chemins:-}")
    constat_neutraliser "$id"; id="$neutre"
    if [ "$typ" = L ]; then
      bes_etats+=(ignoree)
      constat_ajouter ERREUR E03 1 "$rang" "besoin $id" "ligne illisible (nombre de colonnes différent de l'en-tête)"; continue
    fi
    [ "$dup" != 1 ] || constat_ajouter ERREUR E04 1 "$rang" "besoin $id" "identifiant en double dans le backlog"
    if table_statut_connu besoin "$statut"; then
      [ "$dup" != 0 ] || etat=controlee
    else
      constat_neutraliser "$statut"
      constat_ajouter ERREUR E05 1 "$rang" "besoin $id" "statut inconnu « $neutre » (attendus : $attendus)"
    fi
    bes_etats+=("$etat")
  done < <(besoins_lire)
}

# --- Cohérence des besoins avec leurs issues (RG-05, RG-09, RG-17) -------------------------------------------------------------------------------
# Suppose les tableaux d'issues de statuts.sh (iss_fichiers, iss_ids, iss_rangs, iss_etats, iss_statuts, iss_effectifs, iss_refs) remplis par controle_issues.
# Valeurs lues de l'en-tête de chaque issue contrôlée (indice des tableaux d'issues) : besoin, prd et branche déclarée, sans espaces de bord.
iss_besoins=(); iss_prds=(); iss_branches=()

# besoins_issues_lire : remplit iss_besoins, iss_prds et iss_branches (un passage awk par issue contrôlée).
besoins_issues_lire() {
  local i out b p br
  iss_besoins=(); iss_prds=(); iss_branches=()
  for i in "${!iss_fichiers[@]}"; do
    iss_besoins+=(""); iss_prds+=(""); iss_branches+=("")
    [ "${iss_etats[$i]}" = controlee ] || continue
    out="$(issue_champs "${iss_fichiers[$i]}" besoin prd branche)"
    { IFS= read -r b; IFS= read -r p; IFS= read -r br; } <<< "$out"
    table_nettoyer "$b"; iss_besoins[$i]="$nettoye"
    table_nettoyer "$p"; iss_prds[$i]="$nettoye"
    table_nettoyer "$br"; iss_branches[$i]="$nettoye"
  done
}

# issue_classe <statut effectif> : met dans $classe la classe de l'issue pour le rapprochement avec son besoin : T (pas commencée), D (démarrée, pas terminée),
# F (terminée), A (abandonnée, écartée de tous les comptes).
issue_classe() {
  case "$1" in
    "En cours"|"En revue") classe=D ;;
    Fait) classe=F ;;
    Abandonnée) classe=A ;;
    *) classe=T ;;
  esac
}

# besoins_flux : le flux d'entrée de besoins_agreger, une ligne par enregistrement, champs séparés par CONSTAT_SEP :
#   K <id>                                              identifiant d'une ligne du tableau (lisible ou non)
#   B <rang> <id>                                       besoin contrôlé (rang = rang de sa ligne)
#   I <indice> <besoin> <classe> <ref> <existe> <fait>  issue contrôlée (indice dans les tableaux d'issues, classe : issue_classe, ref = branche retenue refs/heads/<nom> ou vide,
#                                                       existe = 0 si la branche déclarée est absente (la fusion se lit alors dans le fichier), fait = 1 si son fichier est Fait
#                                                       dans develop, lu seulement sans branche retenue) ; un besoin qui contient CONSTAT_SEP est envoyé vide (il ne peut désigner
#                                                       aucune ligne)
besoins_flux() {
  local i classe besoin
  for i in "${!bes_ids[@]}"; do
    printf 'K%s%s\n' "$CONSTAT_SEP" "${bes_ids[$i]}"
    [ "${bes_etats[$i]}" != controlee ] || printf 'B%s%s%s%s\n' "$CONSTAT_SEP" "$((i + 1))" "$CONSTAT_SEP" "${bes_ids[$i]}"
  done
  for i in "${!iss_fichiers[@]}"; do
    [ "${iss_etats[$i]}" = controlee ] || continue
    issue_classe "${iss_effectifs[$i]}"
    besoin="${iss_besoins[$i]}"; case "$besoin" in *"$CONSTAT_SEP"*) besoin="" ;; esac
    printf 'I%s%s%s%s%s%s%s%s%s%s%s%s\n' "$CONSTAT_SEP" "$i" "$CONSTAT_SEP" "$besoin" "$CONSTAT_SEP" "$classe" "$CONSTAT_SEP" "${iss_fusion_refs[$i]}" "$CONSTAT_SEP" "${iss_fusion_existe[$i]}" \
      "$CONSTAT_SEP" "${iss_fusion_fait[$i]}"
  done
}

# besoins_agreger : rapproche les issues des besoins en un seul passage (coût linéaire ; les valeurs sont des clés de tableau, jamais des motifs). Lit les refs fusionnées dans develop
# (fus_refs, précédées d'une ligne « # » pour que le fichier ne soit jamais vide) puis le flux de besoins_flux. Écrit, séparés par CONSTAT_SEP :
#   X <indice>                          issue dont le besoin n'est l'identifiant d'aucune ligne du tableau
#   Y <indice> <rang>                   issue rattachée au besoin contrôlé de ce rang
#   S <rang> <n> <fait> <démarrées> <première démarrée> <première non terminée> <première non fusionnée> <fusion inconnue>
#                                       un état par besoin contrôlé : issues non abandonnées, terminées, démarrées (y compris terminées), indice de la première démarrée,
#                                       de la première ni terminée ni abandonnée et de la première terminée non fusionnée dans l'ordre des fichiers (vides s'il n'y en a pas),
#                                       nombre d'issues terminées dont la fusion n'est pas vérifiable (develop absente)
besoins_agreger() {
  LC_ALL=C awk -v connue="$fus_connue" 'BEGIN { FS = OFS = "\037" }
    FNR == NR { fusionnee[$0] = 1; next }
    $1 == "K" { connu[$2] = 1; next }
    $1 == "B" { nb++; ordre[nb] = $2; rang_de[$3] = $2; next }
    $1 == "I" {
      if (!($3 in connu)) { print "X", $2; next }
      if (!($3 in rang_de)) next
      r = rang_de[$3]; classe = $4
      print "Y", $2, r
      if (classe != "A") n[r]++
      if (classe == "F") fait[r]++
      if (classe == "D" || classe == "F") { dem[r]++; if (!(r in premiere)) premiere[r] = $2 }
      if ((classe == "T" || classe == "D") && !(r in nonterm)) nonterm[r] = $2
      if (classe == "F") {
        if (!connue) inconnue[r]++
        else if (((($5 != "") && ($6 != 0)) ? !($5 in fusionnee) : $7 != 1) && !(r in nonfus)) nonfus[r] = $2
      }
    }
    END { for (k = 1; k <= nb; k++) { r = ordre[k]; print "S", r, n[r] + 0, fait[r] + 0, dem[r] + 0, premiere[r], nonterm[r], nonfus[r], inconnue[r] + 0 } }' \
    <(printf '#\n%s\n' "$fus_refs") <(besoins_flux)
}

# prd_present <chemin docs/prd/<nom>.md> : vrai si le PRD est un fichier régulier, ni lien symbolique ni dans un dossier docs/prd en lien (jamais ouvert : sa présence seule compte).
prd_present() { [ -f "$1" ] && [ ! -L "$1" ] && [ ! -L docs/prd ]; }

# besoins_prd : E06 (RG-08). Un besoin Spécifié, En cours, En revue ou Fait liste au moins un chemin docs/prd/<nom>.md et chaque chemin désigne un fichier présent ;
# la cellule PRD vide s'appelle « colonne PRD vide », une cellule sans aucun chemin de cette forme est citée comme le fichier absent. Un seul constat par besoin (le premier chemin absent).
besoins_prd() {
  local i statut id chemins p motif
  for i in "${!bes_ids[@]}"; do
    [ "${bes_etats[$i]}" = controlee ] || continue
    statut="${bes_statuts[$i]}"
    case "$statut" in Spécifié|"En cours"|"En revue"|Fait) ;; *) continue ;; esac
    chemins="${bes_chemins[$i]}"; motif=""
    if [ -z "$chemins" ]; then
      if [ -z "${bes_prds[$i]}" ]; then motif="colonne PRD vide"; else constat_neutraliser "${bes_prds[$i]}"; motif="fichier absent : $neutre"; fi
    else
      for p in $chemins; do prd_present "$p" || { motif="fichier absent : $p"; break; }; done
    fi
    [ -n "$motif" ] || continue
    constat_neutraliser "${bes_ids[$i]}"; id="$neutre"
    constat_ajouter ERREUR E06 1 $((i + 1)) "besoin $id" "statut $statut sans PRD valide ($motif)"
  done
}

# besoins_fusion_preparer : lit dans Git la fusion des issues Fait (statut effectif) des besoins pour lesquels elle compte (En cours, En revue, Fait) : la liste des branches fusionnées
# dans develop (un appel), puis une sonde par lot (un appel) : existence de la branche déclarée d'une issue Fait locale, fichier d'issue tel qu'il est dans develop pour une issue
# sans branche retenue. Aucun appel Git s'il n'y a aucune telle issue. Remplit, par indice d'issue, la branche retenue (iss_fusion_refs), l'existence de la branche déclarée
# (iss_fusion_existe : 0 ou vide) et iss_fusion_fait (1 ou 0, vide si non lu) ; avis A13 si develop est absente.
# La branche retenue d'une issue dont le statut local n'est pas Fait vient du calcul du statut effectif (iss_refs) ; pour une issue Fait locale, c'est la branche déclarée
# (existante), sinon la branche déduite (rattachements_charger) ; une branche ambiguë ou absente ne retient rien.
iss_fusion_refs=(); iss_fusion_existe=(); iss_fusion_fait=()
besoins_fusion_preparer() {
  local i j k pertinents=$'\n' besoin utile=0 noms=() cibles=() jeton ref declaree
  iss_fusion_refs=(); iss_fusion_existe=(); iss_fusion_fait=(); fus_connue=0; fus_refs=""
  for i in "${!bes_ids[@]}"; do
    [ "${bes_etats[$i]}" = controlee ] || continue
    case "${bes_statuts[$i]}" in "En cours"|"En revue"|Fait) pertinents="$pertinents${bes_ids[$i]}"$'\n' ;; esac
  done
  for i in "${!iss_fichiers[@]}"; do
    iss_fusion_refs+=(""); iss_fusion_existe+=(""); iss_fusion_fait+=("")
    [ "${iss_etats[$i]}" = controlee ] && [ "${iss_effectifs[$i]}" = Fait ] || continue
    besoin="${iss_besoins[$i]}"; [ -n "$besoin" ] || continue
    case "$pertinents" in *$'\n'"$besoin"$'\n'*) ;; *) continue ;; esac
    utile=1
    ref="${iss_refs[$i]}"; declaree=0
    if [ -z "$ref" ] && [ "${iss_statuts[$i]}" = Fait ]; then
      if [ -z "${iss_branches[$i]}" ]; then
        [ -z "${rat_deduites[$i]:-}" ] || ref="refs/heads/${rat_deduites[$i]}"
      elif fusion_nom_sur "${iss_branches[$i]}"; then
        ref="refs/heads/${iss_branches[$i]}"; noms+=("$ref"); cibles+=("e$i"); declaree=1 # existence à sonder : absente, la fusion se lit dans le fichier
      fi
    fi
    iss_fusion_refs[$i]="$ref"
    if [ -z "$ref" ] || [ "$declaree" -eq 1 ]; then noms+=("$FUSION_REF:${iss_fichiers[$i]}"); cibles+=("f$i"); fi
  done
  [ "$utile" -eq 1 ] || return 0
  fusion_charger
  if [ "$fus_connue" -eq 0 ]; then
    constat_ajouter AVIS A13 0 0 backlog "branche develop absente : fusion non vérifiable"; return 0
  fi
  [ "${#noms[@]}" -gt 0 ] || return 0
  k=0
  while IFS= read -r jeton; do
    j="${cibles[$k]}"
    case "$j" in e*) [ "$jeton" = 1 ] || iss_fusion_existe[${j#e}]=0 ;; f*) iss_fusion_fait[${j#f}]="$jeton" ;; esac
    k=$((k + 1))
  done < <(fusion_sonder "${noms[@]}")
}

# prd_chemin_valide <valeur> : vrai si la valeur est exactement un chemin docs/prd/<nom>.md, <nom> ne contenant que [A-Za-z0-9._-] (RG-08).
prd_chemin_valide() {
  local LC_ALL=C nom="${1#docs/prd/}"
  [ "$nom" != "$1" ] || return 1
  case "$nom" in ''|*[!A-Za-z0-9._-]*|.md) return 1 ;; *.md) return 0 ;; esac
  return 1
}

# besoin_issue <indice d'issue> <rang du besoin> : pour une issue rattachée à un besoin contrôlé, A14 (PRD de l'issue non listé dans la colonne PRD du besoin, ou introuvable ;
# les deux peuvent se cumuler) et A15 (besoin Abandonnée alors que l'issue est À faire, En cours ou En revue).
besoin_issue() {
  local prd="${iss_prds[$1]}" chemins="${bes_chemins[$(($2 - 1))]}" besoin objet statut
  constat_neutraliser "${bes_ids[$(($2 - 1))]}"; besoin="$neutre"
  constat_neutraliser "${iss_ids[$1]}"; objet="issue $neutre"
  if [ -n "$prd" ]; then
    constat_neutraliser "$prd"
    if prd_chemin_valide "$prd"; then
      case " $chemins " in *" $prd "*) ;; *) constat_ajouter AVIS A14 2 "${iss_rangs[$1]}" "$objet" "PRD $neutre non listé dans le backlog pour le besoin $besoin" ;; esac
      prd_present "$prd" || constat_ajouter AVIS A14 2 "${iss_rangs[$1]}" "$objet" "PRD $neutre introuvable"
    else
      constat_ajouter AVIS A14 2 "${iss_rangs[$1]}" "$objet" "PRD $neutre introuvable"
    fi
  fi
  statut="${iss_effectifs[$1]}"
  if [ "${bes_statuts[$(($2 - 1))]}" = Abandonnée ]; then
    case "$statut" in "À faire"|"En cours"|"En revue") constat_ajouter AVIS A15 1 "$2" "besoin $besoin" "Abandonnée alors que l'issue ${objet#issue } est $statut" ;; esac
  fi
}

# besoins_abandon : E09 (RG-18) : un besoin Abandonnée a le mot « Abandonn » (casse comprise) dans sa colonne Décisions.
besoins_abandon() {
  local i id
  for i in "${!bes_ids[@]}"; do
    [ "${bes_etats[$i]}" = controlee ] && [ "${bes_statuts[$i]}" = Abandonnée ] || continue
    case "${bes_decisions[$i]}" in *Abandonn*) continue ;; esac
    constat_neutraliser "${bes_ids[$i]}"; id="$neutre"
    constat_ajouter ERREUR E09 1 $((i + 1)) "besoin $id" "statut Abandonnée sans raison dans la colonne Décisions"
  done
}

# besoin_ecart <rang> <n> <fait> <démarrées> <première démarrée> <première non terminée> <première non fusionnée> <fusion inconnue> : l'écart entre le statut du besoin et l'état
# de ses issues (RG-17), au plus un constat par besoin.
besoin_ecart() {
  local statut id issue
  statut="${bes_statuts[$(($1 - 1))]}"
  constat_neutraliser "${bes_ids[$(($1 - 1))]}"; id="besoin $neutre"
  case "$statut" in
    "À faire"|"En clarification"|Spécifié)
      [ "$4" -eq 0 ] || { constat_neutraliser "${iss_ids[$5]}"; constat_ajouter ERREUR E07 1 "$1" "$id" "statut $statut en retard : l'issue $neutre est démarrée"; } ;;
    "En cours"|"En revue")
      if [ "$2" -gt 0 ] && [ "$3" -eq "$2" ]; then # toutes les issues (hors Abandonnée) sont Fait
        if [ -z "$7" ] && [ "$8" -eq 0 ]; then constat_ajouter ERREUR E07 1 "$1" "$id" "statut $statut en retard : toutes les issues sont Fait et fusionnées dans develop (attendu : Fait)"
        elif [ "$statut" = "En cours" ]; then constat_ajouter ERREUR E07 1 "$1" "$id" "statut $statut en retard : toutes les issues sont Fait (attendu : En revue)"
        fi
      elif [ "$statut" = "En revue" ]; then constat_ajouter AVIS A12 1 "$1" "$id" "statut $statut en avance : toutes les issues ne sont pas Fait"
      elif [ "$4" -eq 0 ]; then constat_ajouter AVIS A12 1 "$1" "$id" "statut $statut en avance : aucune issue démarrée"
      fi ;;
    Fait)
      if [ "$3" -eq 0 ]; then constat_ajouter ERREUR E08 1 "$1" "$id" "statut Fait non justifié : aucune issue Fait"
      elif [ -n "$6" ]; then constat_neutraliser "${iss_ids[$6]}"; constat_ajouter ERREUR E08 1 "$1" "$id" "statut Fait non justifié : l'issue $neutre n'est ni Fait ni Abandonnée"
      elif [ -n "$7" ]; then constat_neutraliser "${iss_ids[$7]}"; constat_ajouter ERREUR E08 1 "$1" "$id" "statut Fait non justifié : la branche de l'issue $neutre n'est pas fusionnée dans develop"
      fi ;;
  esac
}

# besoins_coherence : E06 (besoin sans PRD), E09 (besoin abandonné sans raison) et, pour les issues contrôlées, E12 (issue sans besoin connu), A14 et A15 (PRD de l'issue, besoin
# abandonné), l'écart entre chaque besoin et ses issues (E07, E08, A12) et A13 (develop absente). Ne fait rien sans tableau des besoins (E02).
besoins_coherence() {
  local t a b c d e f g h objet
  [ "$bes_table" -eq 1 ] || return 0
  besoins_prd
  besoins_abandon
  besoins_issues_lire
  besoins_fusion_preparer
  while IFS="$CONSTAT_SEP" read -r t a b c d e f g h; do
    case "$t" in
      X)
        constat_neutraliser "${iss_ids[$a]}"; objet="issue $neutre"
        constat_neutraliser "${iss_besoins[$a]}"
        constat_ajouter ERREUR E12 2 "${iss_rangs[$a]}" "$objet" "besoin « $neutre » inconnu du backlog" ;;
      Y) besoin_issue "$a" "$b" ;;
      S) besoin_ecart "$a" "$b" "$c" "$d" "$e" "$f" "$g" "$h" ;;
    esac
  done < <(besoins_agreger)
}
