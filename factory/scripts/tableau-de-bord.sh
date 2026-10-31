#!/usr/bin/env bash
# Tableau de bord HTML statique : besoins du backlog.md et issues de docs/issues/, regroupés par statut.
# Aucun appel à un modèle, aucune dépendance (bash, awk, sed) ; pas de JavaScript. La page se rafraîchit seule (balise meta).
# Tout texte lu dans les fichiers est échappé HTML avant d'être écrit (&, <, >, ", ').
#
# Usage : scripts/tableau-de-bord.sh [--sortie <fichier>] [--attente <secondes>] [--boucle <secondes>]
#   --sortie   fichier généré (défaut : tableau-de-bord.html à la racine du projet)
#   --attente  délai de rafraîchissement automatique de la page (défaut : 30)
#   --boucle   régénère le fichier toutes les <secondes> jusqu'à Ctrl-C (sinon une seule génération)
# Code de sortie : 0 ; 64 si les arguments sont invalides ou si le dossier de --sortie n'existe pas (il n'est pas créé).
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
dossier_scripts="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "Usage : $0 [--sortie <fichier>] [--attente <secondes>] [--boucle <secondes>]" >&2; exit 64; }

sortie="tableau-de-bord.html"; attente=30; boucle=""
nombre() { case "$1" in ''|*[!0-9]*) return 1 ;; esac; [ "$1" -ge 1 ]; }
while [ $# -gt 0 ]; do
  case "$1" in
    --sortie) [ $# -ge 2 ] || usage; sortie="$2"; shift ;;
    --attente) [ $# -ge 2 ] && nombre "$2" || usage; attente="$2"; shift ;;
    --boucle) [ $# -ge 2 ] && nombre "$2" || usage; boucle="$2"; shift ;;
    *) usage ;;
  esac
  shift
done
case "$sortie" in /*) ;; *) sortie="$PWD/$sortie" ;; esac
if [ ! -d "$(dirname "$sortie")" ]; then
  echo "Erreur : le dossier de sortie « $(dirname "$sortie") » n'existe pas." >&2; exit 64
fi

cd "$racine" || exit 1
# shellcheck source=lib-issues.sh
. "$dossier_scripts/lib-issues.sh"

# Statuts du cycle (même ordre que backlog.md) et classes CSS correspondantes (liste fermée, jamais le texte brut).
statuts=("À faire" "En clarification" "Spécifié" "En cours" "En revue" "Fait")
classes=(afaire clarification specifie encours enrevue fait)
# Rang de la colonne « statut » dans les lignes produites par besoins_backlog et issues_dossier.
RANG_STATUT_BESOIN=4; RANG_STATUT_ISSUE=3
sep=$'\037' # séparateur de champs non blanc : les champs vides ne sont pas fusionnés par read

echappe() { # echappe <texte> : échappement HTML
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}
classe() { # classe <statut> : nom de classe CSS, « inconnu » hors du cycle
  local i
  for i in "${!statuts[@]}"; do [ "${statuts[$i]}" = "$1" ] && { echo "${classes[$i]}"; return; }; done
  echo inconnu
}

besoins_backlog() { # lignes « id SEP besoin SEP priorité SEP statut SEP prd » du tableau « Besoins fonctionnels »
  [ -f backlog.md ] || return 0
  awk -v FS='|' -v OFS="$sep" '
    /^## / { actif = ($0 ~ /^## Besoins fonctionnels/); next }
    actif && /^\|/ {
      gsub(/\\\|/, "\001")  # « \| » est un « | » littéral dans la cellule, pas un séparateur
      for (i = 2; i <= 6; i++) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); gsub(/\001/, "|", $i) }
      if ($2 == "ID" || $2 ~ /^[-: ]+$/ || $2 == "" || $3 == "") next
      print $2, $3, $4, $5, $6
    }
  ' backlog.md
}

issues_dossier() { # lignes « id SEP titre SEP statut SEP dépendances SEP besoin (F-xx) » lues dans les en-têtes
  local f deps
  while IFS= read -r f; do
    deps="$(issue_liste "$f" depend_de | paste -sd, - | sed 's/,/, /g')"
    printf '%s%s%s%s%s%s%s%s%s\n' "$(issue_champ "$f" id)" "$sep" "$(issue_champ "$f" titre)" "$sep" "$(issue_champ "$f" statut)" "$sep" "$deps" "$sep" "$(issue_champ "$f" besoin)"
  done < <(issue_fichiers)
}

compteurs() { # compteurs <lignes> <rang du statut> : un compteur par statut
  local s n reste
  reste="$(printf '%s\n' "$1" | awk 'NF { n++ } END { print n + 0 }')"
  for s in "${statuts[@]}"; do
    n="$(printf '%s\n' "$1" | awk -v FS="$sep" -v c="$2" -v s="$s" '$c == s { n++ } END { print n + 0 }')"
    reste=$((reste - n))
    printf '<span class="compteur statut-%s">%s : %s</span>\n' "$(classe "$s")" "$(echappe "$s")" "$n"
  done
  printf '<span class="compteur statut-inconnu">(autre) : %s</span>\n' "$reste"
}

tableau() { # tableau <lignes> <rang du statut> <titres de colonnes séparés par SEP> : une table par statut, dans l'ordre du cycle
  local s ligne champ n rang_stat="$2" statut_ligne
  for s in "${statuts[@]}" "(autre)"; do
    n=0
    while IFS= read -r ligne; do
      [ -n "$ligne" ] || continue
      statut_ligne="$(printf '%s' "$ligne" | awk -v FS="$sep" -v c="$rang_stat" '{ print $c }')"
      if [ "$s" = "(autre)" ]; then
        [ "$(classe "$statut_ligne")" = inconnu ] || continue
      else
        [ "$statut_ligne" = "$s" ] || continue
      fi
      if [ "$n" -eq 0 ]; then
        printf '<h3 class="statut-%s">%s</h3>\n<table class="statut-%s"><thead><tr>' "$(classe "$statut_ligne")" "$(echappe "$s")" "$(classe "$statut_ligne")"
        while IFS= read -r champ; do printf '<th>%s</th>' "$(echappe "$champ")"; done < <(printf '%s\n' "$3" | tr "$sep" '\n')
        printf '</tr></thead>\n<tbody>\n'
      fi
      n=$((n + 1))
      printf '<tr>'
      while IFS= read -r champ; do printf '<td>%s</td>' "$(echappe "$champ")"; done < <(printf '%s' "$ligne" | awk -v FS="$sep" -v OFS='\n' '{ $1 = $1; print }')
      printf '</tr>\n'
    done <<< "$1"
    [ "$n" -gt 0 ] && printf '</tbody></table>\n'
  done
  return 0
}

generer() { # page complète sur la sortie standard
  local b i prochaine
  b="$(besoins_backlog)"; i="$(issues_dossier)"
  prochaine="$("$dossier_scripts/etat-issues.sh" --prochaine 2>/dev/null)"
  cat <<HTML
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="$attente">
<title>Tableau de bord</title>
<style>
body { font-family: system-ui, sans-serif; margin: 2rem; color: #222; }
table { border-collapse: collapse; margin-bottom: 1rem; width: 100%; }
th, td { border: 1px solid #ccc; padding: .3rem .6rem; text-align: left; }
.compteur { display: inline-block; padding: .2rem .7rem; margin: 0 .4rem .4rem 0; border-radius: 1rem; }
.statut-afaire { background: #e5e7eb; } .statut-clarification { background: #fde68a; }
.statut-specifie { background: #bfdbfe; } .statut-encours { background: #fdba74; }
.statut-enrevue { background: #ddd6fe; } .statut-fait { background: #bbf7d0; }
.statut-inconnu { background: #fecaca; }
h3 { padding: .2rem .6rem; border-radius: .3rem; }
</style>
</head>
<body>
<h1>Tableau de bord</h1>
<p>Généré le $(date '+%Y-%m-%d à %H:%M:%S'), rafraîchi toutes les ${attente} s.</p>
<h2>Besoins</h2>
<p>
$(compteurs "$b" "$RANG_STATUT_BESOIN")
</p>
$(tableau "$b" "$RANG_STATUT_BESOIN" "ID${sep}Besoin${sep}Priorité${sep}Statut${sep}PRD")
<h2>Issues</h2>
<p>$(if [ -n "$prochaine" ]; then printf 'Prochaine issue prête : <strong>%s</strong>' "$(echappe "$prochaine")"; else printf 'Aucune issue prête.'; fi)</p>
<p>
$(compteurs "$i" "$RANG_STATUT_ISSUE")
</p>
$(tableau "$i" "$RANG_STATUT_ISSUE" "Id${sep}Titre${sep}Statut${sep}Dépend de${sep}Besoin")
</body>
</html>
HTML
}

ecrire() { # écriture atomique : un navigateur ne lit jamais une page à moitié écrite
  local tmp; tmp="$(mktemp "${sortie}.XXXXXX")" || exit 1
  generer > "$tmp" && mv "$tmp" "$sortie" || { rm -f "$tmp"; exit 1; }
}

if [ -n "$boucle" ]; then
  echo "Régénération de $sortie toutes les ${boucle} s (Ctrl-C pour arrêter)."
  while true; do ecrire; sleep "$boucle"; done
fi
ecrire
echo "$sortie"
