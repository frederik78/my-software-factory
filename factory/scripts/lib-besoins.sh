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
# Valeurs lues de l'en-tête de chaque issue contrôlée (indice des tableaux d'issues) : besoin et prd, sans espaces de bord.
iss_besoins=(); iss_prds=()

# besoins_issues_lire : remplit iss_besoins et iss_prds (un passage awk par issue contrôlée).
besoins_issues_lire() {
  local i out b p
  iss_besoins=(); iss_prds=()
  for i in "${!iss_fichiers[@]}"; do
    iss_besoins+=(""); iss_prds+=("")
    [ "${iss_etats[$i]}" = controlee ] || continue
    out="$(issue_champs "${iss_fichiers[$i]}" besoin prd)"
    case "$out" in *$'\n'*) b="${out%%$'\n'*}"; p="${out#*$'\n'}" ;; *) b="$out"; p="" ;; esac
    table_nettoyer "$b"; iss_besoins[$i]="$nettoye"
    table_nettoyer "$p"; iss_prds[$i]="$nettoye"
  done
}

# besoins_flux : le flux d'entrée de besoins_agreger, une ligne par enregistrement, champs séparés par CONSTAT_SEP :
#   K <id>                       identifiant d'une ligne du tableau (lisible ou non)
#   I <indice> <besoin>          issue contrôlée (indice dans les tableaux d'issues) ; un besoin qui contient CONSTAT_SEP est envoyé vide (il ne peut désigner aucune ligne)
besoins_flux() {
  local i
  for i in "${!bes_ids[@]}"; do printf 'K%s%s\n' "$CONSTAT_SEP" "${bes_ids[$i]}"; done
  for i in "${!iss_fichiers[@]}"; do
    [ "${iss_etats[$i]}" = controlee ] || continue
    case "${iss_besoins[$i]}" in
      *"$CONSTAT_SEP"*) printf 'I%s%s%s\n' "$CONSTAT_SEP" "$i" "$CONSTAT_SEP" ;;
      *) printf 'I%s%s%s%s\n' "$CONSTAT_SEP" "$i" "$CONSTAT_SEP" "${iss_besoins[$i]}" ;;
    esac
  done
}

# besoins_agreger : lit le flux de besoins_flux et rapproche les issues des besoins en un seul passage (coût linéaire ; les valeurs sont des clés de tableau, jamais des motifs).
# Écrit, séparés par CONSTAT_SEP : « X <indice> » pour une issue dont le besoin n'est l'identifiant d'aucune ligne du tableau.
besoins_agreger() {
  LC_ALL=C awk 'BEGIN { FS = OFS = "\037" }
    $1 == "K" { connu[$2] = 1; next }
    $1 == "I" { if (!($3 in connu)) print "X", $2 }'
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

# besoins_coherence : E06 (besoin sans PRD) et, pour les issues contrôlées, E12 (issue sans besoin connu). Ne fait rien sans tableau des besoins (E02).
besoins_coherence() {
  local t a objet
  [ "$bes_table" -eq 1 ] || return 0
  besoins_prd
  besoins_issues_lire
  while IFS="$CONSTAT_SEP" read -r t a; do
    case "$t" in
      X)
        constat_neutraliser "${iss_ids[$a]}"; objet="issue $neutre"
        constat_neutraliser "${iss_besoins[$a]}"
        constat_ajouter ERREUR E12 2 "${iss_rangs[$a]}" "$objet" "besoin « $neutre » inconnu du backlog" ;;
    esac
  done < <(besoins_flux | besoins_agreger)
}
