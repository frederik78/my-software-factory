#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : lecture stricte du verdict d'un rapport de revue (RG-10 b), pour scripts/verdict-revue.sh et scripts/statuts.sh.
# Compatible bash 3.2 (macOS). Les règles de lecture sont décrites en tête de verdict-revue.sh ; elles ne sont écrites qu'ici.
# Le fichier est une donnée non fiable : sa première ligne est comparée comme du texte, jamais évaluée ni passée à une commande, et jamais recopiée dans les messages.
# Un seul processus externe par fichier (grep) : statuts.sh lit une revue par issue Fait, et une dizaine de processus par revue coûtaient des dizaines de secondes (PRD 004, CS-04).

# verdict_rogner <texte> : REPLY = texte sans espaces ni tabulations de bord.
verdict_rogner() {
  REPLY="$1"
  REPLY="${REPLY#"${REPLY%%[![:blank:]]*}"}"
  REPLY="${REPLY%"${REPLY##*[![:blank:]]}"}"
}

# verdict_refuser <motif> : $verdict = INCONNU, $verdict_motif = le motif ; code 1.
verdict_refuser() { verdict="INCONNU"; verdict_motif="$1"; return 1; }

# verdict_lire <fichier> [1] : met dans $verdict « APPROUVÉ », « CHANGEMENTS DEMANDÉS » ou « INCONNU » et, pour INCONNU, la phrase d'explication dans $verdict_motif ;
# code 0 si le verdict est l'une des deux premières valeurs, 1 sinon. Le second argument 1 dit que l'appelant a déjà vérifié que le fichier est régulier, lisible
# et de 1 Mio au plus (fichier_motif_refus de lib-issues.sh) : ces vérifications ne sont pas refaites.
verdict_lire() {
  local LC_ALL=C fichier="$1" premiere="" taille debut="" nb ligne
  verdict=""; verdict_motif=""
  if [ "${2:-0}" -ne 1 ]; then
    { [ -f "$fichier" ] && [ -r "$fichier" ]; } || { verdict_refuser "verdict-revue : fichier de revue absent ou illisible"; return 1; }
    taille="$(wc -c < "$fichier")"
    [ "${taille//[[:space:]]/}" -le 1048576 ] || { verdict_refuser "verdict-revue : fichier de revue trop volumineux (plus de 1 Mio, ligne VERDICT non vérifiable)"; return 1; }
  fi

  # Première ligne (le retour à la ligne exclu) : une ligne de plus de 200 octets est refusée (sinon des espaces de bord pourraient cacher du texte au-delà de la tranche lue).
  IFS= read -r premiere < "$fichier"
  [ "${#premiere}" -le 200 ] || { verdict_refuser "verdict-revue : première ligne trop longue (plus de 200 octets, ligne VERDICT invalide)"; return 1; }

  # La lecture d'une ligne et la substitution de commande suppriment les octets NUL : « VERDICT: APPR<NUL>OUVÉ » deviendrait « VERDICT: APPROUVÉ ».
  # On cherche donc un NUL dans les 201 premiers octets (la lecture jusqu'au NUL rend ce qui le précède) : s'il précède le premier retour à la ligne, il est dans la première ligne.
  if IFS= read -r -d '' -n 201 debut < "$fichier" && [ "${#debut}" -le 200 ] && [ "${debut//$'\n'/}" = "$debut" ]; then
    verdict_refuser "verdict-revue : première ligne contenant un octet NUL (ligne VERDICT invalide)"; return 1
  fi

  # Décompte des lignes « VERDICT: » de tout le fichier (la casse ne compte pas, les espaces de bord non plus) : une seule est permise.
  nb="$(grep -a -i -c -E '^[[:blank:]]*verdict[[:blank:]]*:' -- "$fichier")"
  [ "${nb//[[:space:]]/}" -le 1 ] || { verdict_refuser "verdict-revue : ligne VERDICT en double (verdict ambigu)"; return 1; }

  verdict_rogner "${premiere%$'\r'}"; ligne="$REPLY"
  verdict_rogner "${ligne%%:*}" # sans deux-points, la clé est la ligne entière : elle ne peut valoir « verdict » suivie d'une valeur
  case "$REPLY" in
    [Vv][Ee][Rr][Dd][Ii][Cc][Tt]) ;;
    *) verdict_refuser "verdict-revue : la première ligne n'est pas une ligne VERDICT (ligne VERDICT absente ou pas en première ligne)"; return 1 ;;
  esac
  verdict_rogner "${ligne#*:}"
  # Comparaison par motifs de casse explicites : la mise en minuscules de É/é dépend de la locale et de la version de bash, pas un motif.
  case "$REPLY" in
    [Aa][Pp][Pp][Rr][Oo][Uu][Vv]"É"|[Aa][Pp][Pp][Rr][Oo][Uu][Vv]"é") verdict="APPROUVÉ" ;;
    [Cc][Hh][Aa][Nn][Gg][Ee][Mm][Ee][Nn][Tt][Ss]" "[Dd][Ee][Mm][Aa][Nn][Dd]"É"[Ss]|[Cc][Hh][Aa][Nn][Gg][Ee][Mm][Ee][Nn][Tt][Ss]" "[Dd][Ee][Mm][Aa][Nn][Dd]"é"[Ss]) verdict="CHANGEMENTS DEMANDÉS" ;;
    *) verdict_refuser "verdict-revue : valeur de la ligne VERDICT différente de « APPROUVÉ » et de « CHANGEMENTS DEMANDÉS » (ligne VERDICT invalide)"; return 1 ;;
  esac
}

# verdict_forme <fichier> : met dans $verdict_forme_cause « plus » (plus d'une ligne VERDICT:), « premiere » (au moins une ligne VERDICT: et la première ligne n'en est pas une)
# ou « » (bien formé, ou aucune ligne de verdict : revue d'avant F-01). Même définition de la ligne de verdict que verdict_lire (même motif, mêmes options de grep), lue en une seule
# passe : grep s'arrête à la deuxième ligne trouvée (m = 2), la première est reconnue à son numéro. Appelant : fichier déjà admis (régulier, non lien, 1 Mio au plus).
# Aucun contenu du fichier n'est conservé : seuls les numéros de ligne sont lus.
verdict_forme() {
  local LC_ALL=C trouvees
  verdict_forme_cause=""
  trouvees="$(grep -a -i -n -m 2 -o -E '^[[:blank:]]*verdict[[:blank:]]*:' -- "$1" 2>/dev/null)"
  case "$trouvees" in
    '') ;;
    *$'\n'*) verdict_forme_cause="plus" ;;
    1:*) ;;
    *) verdict_forme_cause="premiere" ;;
  esac
}
