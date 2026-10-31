#!/usr/bin/env bash
# Dashboard : page HTML statique en Kanban : besoins du backlog.md et issues de docs/issues/, une colonne par statut, une carte par élément.
# Aucun appel à un modèle, aucune dépendance (bash, awk, sed) ; pas de JavaScript. La page se rafraîchit seule (balise meta).
# Tout texte lu dans les fichiers est échappé HTML avant d'être écrit (&, <, >, ", ').
#
# Usage : scripts/dashboard.sh [--sortie <fichier>] [--attente <secondes>] [--boucle <secondes>]
#   --sortie   fichier généré (défaut : dashboard.html à la racine du projet)
#   --attente  délai de rafraîchissement automatique de la page (défaut : 30)
#   --boucle   régénère le fichier toutes les <secondes> jusqu'à Ctrl-C (sinon une seule génération)
# Code de sortie : 0 ; 64 si les arguments sont invalides ou si le dossier de --sortie n'existe pas (il n'est pas créé).
set -uo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"
dossier_scripts="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "Usage : $0 [--sortie <fichier>] [--attente <secondes>] [--boucle <secondes>]" >&2; exit 64; }

sortie="dashboard.html"; attente=30; boucle=""
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

# Statuts du cycle, dans l'ordre des colonnes : besoins (backlog.md) et issues (docs/issues/README.md).
statuts_besoins=("À faire" "En clarification" "Spécifié" "En cours" "En revue" "Fait")
statuts_issues=("À faire" "En cours" "En revue" "Fait")
classes=(afaire clarification specifie encours enrevue fait) # une par statut de besoin (liste fermée, jamais le texte brut)
# Rang du champ « statut » dans les lignes produites par besoins_backlog et issues_dossier.
RANG_STATUT_BESOIN=4; RANG_STATUT_ISSUE=3
sep=$'\037' # séparateur de champs non blanc : les champs vides ne sont pas fusionnés par read

echappe() { # echappe <texte> : échappement HTML
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}
classe() { # classe <statut> : nom de classe CSS, « inconnu » hors du cycle des besoins
  local i
  for i in "${!statuts_besoins[@]}"; do [ "${statuts_besoins[$i]}" = "$1" ] && { echo "${classes[$i]}"; return; }; done
  echo inconnu
}
parmi() { # parmi <valeur> <liste...> : vrai si la valeur figure dans la liste
  local v="$1" x; shift
  for x in "$@"; do [ "$x" = "$v" ] && return 0; done
  return 1
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

issues_dossier() { # lignes « id SEP titre SEP statut SEP dépendances SEP besoin (F-xx) » lues dans les en-têtes, dans l'ordre des fichiers
  local f deps
  while IFS= read -r f; do
    deps="$(issue_liste "$f" depend_de | paste -sd, - | sed 's/,/, /g')"
    printf '%s%s%s%s%s%s%s%s%s\n' "$(issue_champ "$f" id)" "$sep" "$(issue_champ "$f" titre)" "$sep" "$(issue_champ "$f" statut)" "$sep" "$deps" "$sep" "$(issue_champ "$f" besoin)"
  done < <(issue_fichiers)
}

carte_besoin() { # carte_besoin <ligne de besoins_backlog>
  local id libelle priorite statut prd
  IFS="$sep" read -r id libelle priorite statut prd <<< "$1"
  printf '<div class="carte"><strong>%s</strong> <span class="titre">%s</span>' "$(echappe "$id")" "$(echappe "$libelle")"
  [ -z "$priorite" ] || printf '<span class="detail">%s</span>' "$(echappe "$priorite")"
  [ -z "$prd" ] || printf '<span class="detail">PRD : %s</span>' "$(echappe "$prd")"
  printf '</div>\n'
}

# Contexte des cartes d'issues, rempli par generer : issue prête (etat-issues.sh --prochaine) et statut de chaque id.
prochaine=""; ids_issues=(); statuts_lus=()
statut_issue() { # statut_issue <id> : statut lu, vide si l'issue n'existe pas
  local i=0
  while [ "$i" -lt "${#ids_issues[@]}" ]; do
    [ "${ids_issues[$i]}" = "$1" ] && { printf '%s' "${statuts_lus[$i]}"; return; }
    i=$((i + 1))
  done
}
bloquee() { # bloquee <statut> <dépendances « a, b »> : vrai si l'issue est À faire et qu'une dépendance n'est pas Fait
  local dep
  [ "$1" = "À faire" ] || return 1
  while IFS= read -r dep; do
    [ -n "$dep" ] && [ "$(statut_issue "$dep")" != "Fait" ] && return 0
  done < <(printf '%s\n' "$2" | tr ',' '\n' | sed 's/^ *//; s/ *$//')
  return 1
}
carte_issue() { # carte_issue <ligne de issues_dossier>
  local id titre statut deps besoin marques="" etats=""
  IFS="$sep" read -r id titre statut deps besoin <<< "$1"
  if [ -n "$prochaine" ] && [ "$id" = "$prochaine" ]; then
    etats=" prochaine"; marques='<span class="marqueur marqueur-prochaine">prochaine</span>'
  fi
  if bloquee "$statut" "$deps"; then
    etats="$etats bloquee"; marques="$marques"'<span class="marqueur marqueur-bloquee">bloquée</span>'
  fi
  printf '<div class="carte%s"><strong>%s</strong> <span class="titre">%s</span>%s' "$etats" "$(echappe "$id")" "$(echappe "$titre")" "$marques"
  [ -z "$besoin" ] || printf '<span class="detail">%s</span>' "$(echappe "$besoin")"
  [ -z "$deps" ] || printf '<span class="detail">dépend de : %s</span>' "$(echappe "$deps")"
  printf '</div>\n'
}

dans_colonne() { # dans_colonne <statut lu> <colonne> <statuts du cycle...> : la colonne « (autre) » reçoit les statuts hors du cycle
  local statut="$1" colonne="$2"; shift 2
  if [ "$colonne" = "(autre)" ]; then ! parmi "$statut" "$@"; else [ "$statut" = "$colonne" ]; fi
}
kanban() { # kanban <lignes> <rang du statut> <fonction de carte> <statuts du cycle...> : une colonne par statut, plus « (autre) » si besoin
  local lignes="$1" rang="$2" carte="$3"; shift 3
  local ligne s i n autre=0
  local -a liste=() statuts_liste=() colonnes=("$@")
  while IFS= read -r ligne; do
    [ -n "$ligne" ] || continue
    s="$(printf '%s' "$ligne" | cut -d "$sep" -f "$rang")"
    liste+=("$ligne"); statuts_liste+=("$s")
    parmi "$s" "$@" || autre=1
  done <<< "$lignes"
  [ "$autre" -eq 0 ] || colonnes+=("(autre)")
  printf '<div class="kanban">\n'
  for s in "${colonnes[@]}"; do
    n=0; i=0
    while [ "$i" -lt "${#liste[@]}" ]; do dans_colonne "${statuts_liste[$i]}" "$s" "$@" && n=$((n + 1)); i=$((i + 1)); done
    printf '<div class="colonne">\n<h3 class="statut-%s">%s (%s)</h3>\n' "$(classe "$s")" "$(echappe "$s")" "$n"
    i=0
    while [ "$i" -lt "${#liste[@]}" ]; do dans_colonne "${statuts_liste[$i]}" "$s" "$@" && "$carte" "${liste[$i]}"; i=$((i + 1)); done
    [ "$n" -gt 0 ] || printf '<p class="vide">—</p>\n'
    printf '</div>\n'
  done
  printf '</div>\n'
}

encart_en_cours() { # encart_en_cours <lignes de issues_dossier> : issues En cours et En revue, ou « Aucune issue en cours. »
  local id titre statut deps besoin n=0
  printf '<section id="en-cours">\n<h2>En cours</h2>\n'
  while IFS="$sep" read -r id titre statut deps besoin; do
    parmi "$statut" "En cours" "En revue" || continue
    [ "$n" -gt 0 ] || printf '<ul>\n'
    n=$((n + 1))
    printf '<li><strong>%s</strong> %s <span class="etiquette statut-%s">%s</span></li>\n' "$(echappe "$id")" "$(echappe "$titre")" "$(classe "$statut")" "$(echappe "$statut")"
  done <<< "$1"
  if [ "$n" -gt 0 ]; then printf '</ul>\n'; else printf '<p>Aucune issue en cours.</p>\n'; fi
  printf '</section>\n'
}

generer() { # page complète sur la sortie standard
  local b i id statut
  b="$(besoins_backlog)"; i="$(issues_dossier)"
  prochaine="$("$dossier_scripts/etat-issues.sh" --prochaine 2>/dev/null)"
  ids_issues=(); statuts_lus=()
  while IFS="$sep" read -r id _ statut _; do
    [ -n "$id" ] || continue
    ids_issues+=("$id"); statuts_lus+=("$statut")
  done <<< "$i"
  cat <<HTML
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="$attente">
<title>Dashboard</title>
<style>
body { font-family: system-ui, sans-serif; margin: 2rem; color: #222; }
.kanban { display: grid; grid-auto-flow: column; grid-auto-columns: minmax(12rem, 1fr); gap: .8rem; overflow-x: auto; padding-bottom: .5rem; }
.colonne { background: #f9fafb; border: 1px solid #e5e7eb; border-radius: .4rem; min-width: 0; }
.colonne h3 { margin: 0; padding: .4rem .6rem; font-size: 1rem; border-radius: .4rem .4rem 0 0; }
.carte { background: #fff; border: 1px solid #d1d5db; border-left: 4px solid #9ca3af; border-radius: .3rem; margin: .5rem; padding: .4rem .5rem; overflow-wrap: anywhere; break-inside: avoid; }
.carte.prochaine { border-left-color: #2563eb; } .carte.bloquee { border-left-color: #dc2626; }
.marqueur { display: inline-block; margin-left: .3rem; padding: 0 .4rem; border-radius: .6rem; font-size: .75rem; color: #fff; }
.marqueur-prochaine { background: #2563eb; } .marqueur-bloquee { background: #dc2626; }
.detail { display: block; font-size: .85rem; color: #555; }
.vide { margin: .5rem; text-align: center; color: #9ca3af; }
.etiquette { padding: 0 .4rem; border-radius: .6rem; font-size: .8rem; }
.statut-afaire { background: #e5e7eb; } .statut-clarification { background: #fde68a; }
.statut-specifie { background: #bfdbfe; } .statut-encours { background: #fdba74; }
.statut-enrevue { background: #ddd6fe; } .statut-fait { background: #bbf7d0; }
.statut-inconnu { background: #fecaca; }
@media print {
  body { margin: 0; } * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  .kanban { grid-auto-flow: row; grid-template-columns: repeat(auto-fit, minmax(9rem, 1fr)); overflow: visible; }
}
</style>
</head>
<body>
<h1>Dashboard</h1>
<p>Généré le $(date '+%Y-%m-%d à %H:%M:%S'), rafraîchi toutes les ${attente} s.</p>
$(encart_en_cours "$i")
<section id="besoins">
<h2>Besoins</h2>
$(kanban "$b" "$RANG_STATUT_BESOIN" carte_besoin "${statuts_besoins[@]}")
</section>
<section id="issues">
<h2>Issues</h2>
<p>$(if [ -n "$prochaine" ]; then printf 'Prochaine issue prête : <strong>%s</strong>' "$(echappe "$prochaine")"; else printf 'Aucune issue prête.'; fi)</p>
$(kanban "$i" "$RANG_STATUT_ISSUE" carte_issue "${statuts_issues[@]}")
</section>
</body>
</html>
HTML
}

# Fichier temporaire en cours d'écriture : supprimé à la sortie, y compris sur erreur ou interruption (Ctrl-C en --boucle).
tmp=""
trap '[ -z "$tmp" ] || rm -f "$tmp"' EXIT
trap 'exit 130' INT; trap 'exit 143' TERM; trap 'exit 129' HUP
droits_umask="$(printf '%o' $(( 0666 & ~0$(umask) )))" # mktemp crée en 0600 : la page doit être lisible comme tout fichier créé

ecrire() { # écriture atomique : un navigateur ne lit jamais une page à moitié écrite
  tmp="$(mktemp "${sortie}.XXXXXX")" || exit 1
  chmod "$droits_umask" "$tmp" && generer > "$tmp" && mv "$tmp" "$sortie" || exit 1
  tmp=""
}

if [ -n "$boucle" ]; then
  echo "Régénération de $sortie toutes les ${boucle} s (Ctrl-C pour arrêter)."
  while true; do ecrire; sleep "$boucle"; done
fi
ecrire
echo "$sortie"
