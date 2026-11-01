#!/usr/bin/env bash
# Bibliothèque partagée (à sourcer, pas à exécuter) : configuration de la factory pour le projet courant (répertoire courant = racine du projet).
# Trois niveaux, du moins au plus prioritaire :
#   1. .factory.conf        versionné, créé par init-projet.sh (valeurs communes à l'équipe) ;
#   2. .factory.local.conf  ignoré par git (valeurs personnelles : adresse de notification...) ;
#   3. variable d'environnement FACTORY_<CLÉ> (ex. FACTORY_MAX_ITERATIONS_REVUE).
# Un niveau qui définit une clé l'emporte, même avec une valeur vide (une variable d'environnement compte dès qu'elle est définie).
# SÉCURITÉ : ces fichiers ne sont JAMAIS sourcés ni évalués. Ils sont lus comme des lignes « CLÉ=valeur » : seules les clés connues
# (CONFIG_CLES) sont prises, lignes vides et commentaires (#) ignorés. Indentation et espaces autour de « = » tolérés (« CLÉ = valeur ») :
# une ligne mal formatée ne doit pas être ignorée en silence. Valeur = ce qui suit le premier « = », sans ses espaces de bord ni le retour
# chariot final (fichier édité sous Windows), sinon telle quelle (pas de guillemets retirés, aucune expansion de $(...), `...` ni de variable).
# Si une clé apparaît plusieurs fois, la dernière gagne.
# Compatible bash 3.2 (macOS).

CONFIG_CLES="MAX_ITERATIONS_REVUE NOTIFICATION_COMMANDE NOTIFICATION_DESTINATAIRE NOTIFICATION_EXPEDITEUR"

# config_fichier_valeur <fichier> <clé> : affiche la valeur de la clé dans le fichier ; code 1 si le fichier ou la clé est absent.
config_fichier_valeur() {
  [ -f "$1" ] || return 1
  awk -v k="$2" '
    { sub(/\r$/, "") }
    /^[[:space:]]*(#|$)/ { next }
    {
      l = $0; sub(/^[[:space:]]+/, "", l)
      if (index(l, k) != 1) next
      r = substr(l, length(k) + 1)
      if (r !~ /^[[:space:]]*=/) next
      sub(/^[[:space:]]*=[[:space:]]*/, "", r); sub(/[[:space:]]+$/, "", r)
      v = r; trouve = 1
    }
    END { if (trouve) print v; exit !trouve }
  ' "$1"
}

# config_valeur <clé> <défaut> : valeur effective de la clé (variable FACTORY_<clé>, sinon .factory.local.conf, sinon .factory.conf, sinon le défaut).
# Code 64 (message sur stderr) si la clé n'est pas une clé connue.
config_valeur() {
  local cle="$1" defaut="$2" variable="FACTORY_$1"
  case " $CONFIG_CLES " in
    *" $cle "*) ;;
    *) echo "Clé de configuration inconnue : $cle" >&2; return 64 ;;
  esac
  if [ -n "${!variable+x}" ]; then printf '%s\n' "${!variable}"; return 0; fi
  config_fichier_valeur .factory.local.conf "$cle" && return 0
  config_fichier_valeur .factory.conf "$cle" && return 0
  printf '%s\n' "$defaut"
}
