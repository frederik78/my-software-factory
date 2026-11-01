#!/usr/bin/env bash
# Envoie une notification (courriel) par une COMMANDE configurée, sans dépendre d'un fournisseur : msmtp, sendmail, mail, curl vers une API...
# Sert à prévenir l'utilisateur qu'une issue reste bloquée après MAX_ITERATIONS_REVUE revues (skill /deliver).
#
# Usage : scripts/notifier.sh --sujet <sujet> [--corps-fichier <fichier>]   (sans --corps-fichier, le corps est lu sur l'entrée standard)
#         scripts/notifier.sh --test                                         (message d'essai, pour vérifier la configuration)
#
# Configuration (lib-config.sh : .factory.conf, .factory.local.conf, variables FACTORY_*) :
#   NOTIFICATION_COMMANDE      commande d'envoi, découpée en mots sur les espaces (pas de guillemets ni de syntaxe shell ; pour une commande
#                              plus riche, écrire un petit script et donner son chemin) ;
#   NOTIFICATION_DESTINATAIRE  adresse du destinataire (sans espace, ne commençant pas par « - ») ;
#   NOTIFICATION_EXPEDITEUR    facultatif : en-tête From.
# Contrat avec la commande : elle reçoit le message complet sur son entrée standard (en-têtes From si l'expéditeur est renseigné, To, Subject,
# MIME-Version, Content-Type text/plain UTF-8, ligne vide, corps) et le destinataire en DERNIER argument.
#   Exemples : « msmtp -a compte » lance `msmtp -a compte dest@example.com` ; « sendmail -oi » lance `sendmail -oi dest@example.com` (jamais -t, de sendmail ou de mail : selon l'implémentation, il ignore ou double le destinataire passé en argument).
# Les secrets (mot de passe SMTP, clé d'API) restent dans la configuration de l'outil d'envoi (~/.msmtprc, trousseau), jamais dans le dépôt.
# Sécurité : la commande est exécutée comme un tableau de mots, jamais par eval ni sh -c ; les retours à la ligne et caractères de contrôle
# du sujet et de l'expéditeur sont remplacés (aucun en-tête injecté).
# Encodage : un sujet non ASCII est émis en mots encodés RFC 2047 (=?UTF-8?B?…?=, pliés en lignes de 76 caractères au plus) ; idem pour le nom de l'expéditeur
# de forme « Nom <adresse> ». Un sujet ASCII est transmis tel quel.
# Codes de sortie : 0 envoyé ; 3 non configuré (ou destinataire invalide) ; 4 échec de la commande ; 64 usage.
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
dossier_scripts="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "Usage : $0 --sujet <sujet> [--corps-fichier <fichier>] (corps sur l'entrée standard sinon) | $0 --test" >&2; exit 64; }

sujet=""; a_sujet=0; corps_fichier=""; essai=0
while [ $# -gt 0 ]; do
  case "$1" in
    --sujet) [ $# -ge 2 ] || usage; sujet="$2"; a_sujet=1; shift ;;
    --corps-fichier) [ $# -ge 2 ] || usage; corps_fichier="$2"; shift ;;
    --test) essai=1 ;;
    *) usage ;;
  esac
  shift
done
if [ "$essai" -eq 1 ]; then
  [ "$a_sujet" -eq 0 ] && [ -z "$corps_fichier" ] || usage
  sujet="[factory] Notification d'essai"
else
  [ "$a_sujet" -eq 1 ] || usage
  if [ -n "$corps_fichier" ]; then
    [ -f "$corps_fichier" ] && [ -r "$corps_fichier" ] || { echo "Fichier de corps introuvable : $corps_fichier" >&2; exit 64; }
  elif [ -t 0 ]; then
    echo "Corps attendu sur l'entrée standard ou par --corps-fichier." >&2; usage
  fi
fi
# Chemin relatif de --corps-fichier : résolu avant de passer à la racine du projet.
if [ -n "$corps_fichier" ]; then corps_fichier="$(cd "$(dirname "$corps_fichier")" && pwd)/$(basename "$corps_fichier")"; fi

cd "$racine" || exit 1
# shellcheck source=lib-config.sh
. "$dossier_scripts/lib-config.sh"
commande="$(config_valeur NOTIFICATION_COMMANDE "")"
destinataire="$(config_valeur NOTIFICATION_DESTINATAIRE "")"
expediteur="$(config_valeur NOTIFICATION_EXPEDITEUR "")"

mots=()
read -r -a mots <<< "$commande"
manquantes=""
[ "${#mots[@]}" -gt 0 ] || manquantes="NOTIFICATION_COMMANDE"
[ -n "$destinataire" ] || manquantes="${manquantes:+$manquantes, }NOTIFICATION_DESTINATAIRE"
if [ -n "$manquantes" ]; then
  echo "Notification non envoyée : configuration incomplète (renseignez $manquantes dans .factory.local.conf)." >&2; exit 3
fi
case "$destinataire" in
  -*|*[[:space:]]*|*[[:cntrl:]]*)
    echo "Notification non envoyée : NOTIFICATION_DESTINATAIRE invalide (une adresse sans espace, ne commençant pas par « - ») ; corrigez-le dans .factory.local.conf." >&2; exit 3 ;;
esac

en_tete() { # en_tete <valeur> : une seule ligne (CR, LF et tabulations remplacés par des espaces, autres caractères de contrôle retirés)
  printf '%s' "$1" | tr '\r\n\t' '   ' | tr -d '[:cntrl:]'
}

non_ascii() { printf '%s' "$1" | LC_ALL=C grep -q '[^ -~]'; } # non_ascii <texte> : vrai si un octet n'est pas ASCII imprimable

# rfc2047 <texte> <préfixe> : texte ASCII inchangé ; sinon mots encodés =?UTF-8?B?…?= pliés (saut de ligne + espace), chaque ligne
# faisant 76 caractères au plus (RFC 2047 §2) : la première compte les <préfixe> caractères qui la précèdent (« Subject: » = 9), les
# suivantes leur espace initial. Coupure sur des caractères UTF-8 entiers. Indépendant de la locale : travaille sur les octets (od).
LIGNE_MAX=76
octets_par_mot() { echo $(( (LIGNE_MAX - $1 - 12) / 4 * 3 )); } # octets_par_mot <caractères avant le mot> : 12 = « =?UTF-8?B? » + « ?= »
rfc2047() {
  if ! non_ascii "$1"; then printf '%s' "$1"; return; fi
  local h n=0 taille morceau="" sortie="" sep="" limite
  limite="$(octets_par_mot "$2")"
  for h in $(printf '%s' "$1" | od -An -v -tx1); do
    case "$h" in
      [0-7]?) taille=1 ;; [c-d]?) taille=2 ;; e?) taille=3 ;; f?) taille=4 ;; *) taille=0 ;; # 8x-bx : octet de continuation
    esac
    if [ "$taille" -gt 0 ] && [ $((n + taille)) -gt "$limite" ]; then
      sortie="$sortie$sep=?UTF-8?B?$(printf '%b' "$morceau" | base64 | tr -d '\n')?="; sep=$'\n '; morceau=""; n=0
      limite="$(octets_par_mot 1)"
    fi
    morceau="$morceau\\x$h"; n=$((n + 1))
  done
  printf '%s' "$sortie$sep=?UTF-8?B?$(printf '%b' "$morceau" | base64 | tr -d '\n')?="
}

# expediteur_encode <valeur> : forme « Nom <adresse> » avec nom non ASCII -> nom encodé RFC 2047 (après « From: »), l'adresse sur la même
# ligne si elle tient dans les 76 caractères, sinon sur une ligne pliée ; toute autre forme inchangée.
expediteur_encode() {
  local nom adresse encode derniere
  case "$1" in
    *' <'*'>')
      adresse="<${1##*<}"; nom="${1% <*}"
      case "$adresse" in *' '*) printf '%s' "$1"; return ;; esac
      encode="$(rfc2047 "$nom" 6)"
      case "$encode" in *$'\n'*) derniere="${encode##*$'\n'}" ;; *) derniere="From: $encode" ;; esac
      if [ $(( ${#derniere} + 1 + ${#adresse} )) -le "$LIGNE_MAX" ]; then printf '%s %s' "$encode" "$adresse"; else printf '%s\n %s' "$encode" "$adresse"; fi ;;
    *) printf '%s' "$1" ;;
  esac
}

message() {
  [ -n "$expediteur" ] && printf 'From: %s\n' "$(expediteur_encode "$(en_tete "$expediteur")")"
  printf 'To: %s\n' "$destinataire"
  printf 'Subject: %s\n' "$(rfc2047 "$(en_tete "$sujet")" 9)"
  printf 'MIME-Version: 1.0\nContent-Type: text/plain; charset=UTF-8\nContent-Transfer-Encoding: 8bit\n\n'
  if [ "$essai" -eq 1 ]; then
    printf "Message d'essai envoyé par scripts/notifier.sh pour le projet %s.\n" "$(basename "$racine")"
    printf 'Si vous le lisez, les notifications de la factory fonctionnent.\n'
  elif [ -n "$corps_fichier" ]; then
    cat "$corps_fichier"
  else
    cat
  fi
}

# Message complet écrit d'abord dans un fichier temporaire (0600, dans TMPDIR), puis donné à la commande par redirection : pas de tube,
# donc ni SIGPIPE ni « write error: Broken pipe » quand la commande se termine sans lire le message (une commande qui réussit sans
# tout lire n'est pas un échec). Le fichier est supprimé à la sortie, y compris en cas d'échec ou d'interruption.
fichier_message=""
trap '[ -z "$fichier_message" ] || rm -f "$fichier_message"' EXIT
trap 'exit 129' HUP; trap 'exit 130' INT; trap 'exit 143' TERM
fichier_message="$(umask 077 && mktemp "${TMPDIR:-/tmp}/notifier.XXXXXX")" && message > "$fichier_message" \
  || { echo "Notification non envoyée : impossible de préparer le message dans un fichier temporaire." >&2; exit 4; }
"${mots[@]}" "$destinataire" < "$fichier_message" >&2
code=$?
if [ "$code" -ne 0 ]; then
  echo "Notification non envoyée : la commande NOTIFICATION_COMMANDE a échoué (code $code)." >&2; exit 4
fi
echo "Notification envoyée à $destinataire."
