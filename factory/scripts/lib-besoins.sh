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
