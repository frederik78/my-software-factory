#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : résolution des dépendances (depend_de) des issues pour scripts/statuts.sh (PRD 004, RG-13).
# Compatible bash 3.2 (macOS). Les identifiants lus dans les fichiers sont des données non fiables : comparés comme du texte littéral (clés de tableau awk), jamais comme motif.

# dependances_resoudre : résout toutes les dépendances en un seul passage (coût linéaire, quel que soit le nombre d'issues). Lit sur l'entrée standard, séparés par CONSTAT_SEP :
#   I <id> <statut effectif>     issue contrôlée
#   U <id>                       identifiant connu mais inutilisable (statut inconnu, doublon)
#   D <rang> <dépendance>        une dépendance à résoudre (<rang> : numéro de l'issue qui la déclare)
# et écrit, pour chaque ligne D, « <rang> <dépendance> <état> » où état vaut S<statut effectif> (issue contrôlée), U (inutilisable) ou X (aucune issue de cet identifiant).
# Aucune valeur ne contient CONSTAT_SEP (l'appelant écarte les autres).
dependances_resoudre() {
  LC_ALL=C awk 'BEGIN { FS = OFS = "\037" }
    $1 == "I" { connu[$2] = 1; statut[$2] = $3; next }
    $1 == "U" { inutilisable[$2] = 1; next }
    $1 == "D" { if ($3 in connu) etat = "S" statut[$3]; else if ($3 in inutilisable) etat = "U"; else etat = "X"; print $2, $3, etat }'
}
