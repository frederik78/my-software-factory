# Garde-fou de recherche d'absence (PRD 004, CA-38 et CA-39) : signale, sans rien modifier, les listes et règles de statut écrites hors de la table unique.
# Les noms de statut ne sont pas écrits ici : ils viennent de la table (variable noms, séparés par « | »), donc un statut ajouté à la table est gardé aussitôt.
# Usage : awk -v noms="À faire|Fait|…" -v mode=script|doc -f garde-statuts.awk <fichiers...> ; une ligne « fichier:ligne: motif : texte » par trouvaille, rien si tout est conforme.
#   mode=script : scripts de la factory. Signale une ligne qui cite trois statuts ou plus, une déclaration de tableau qui contient un statut, une alternative de statuts d'un « case »
#                 (a|b) et un appel de « parmi » avec un statut littéral. Ignore les commentaires et les lignes qui portent un texte du catalogue (constat_ajouter, RG-23).
#   mode=doc    : AGENTS.md, son modèle, skill deliver. Signale trois statuts ou plus sur une ligne, deux statuts ou plus reliés par une flèche, et une phrase de règle de transition
#                 (verbe de changement de statut et statut sur la même ligne).
function est_lettre(c) { return c ~ /^[A-Za-z0-9_]$/ || c >= "\200" }
function presente(l, nom,   p, avant, apres, reste, dec) {
  reste = l; dec = 0
  while ((p = index(reste, nom)) > 0) {
    avant = (p + dec > 1) ? substr(l, p + dec - 1, 1) : " "
    apres = substr(l, p + dec + length(nom), 1); if (apres == "") apres = " "
    if (!est_lettre(avant) && !est_lettre(apres)) return 1
    dec += p + length(nom) - 1; reste = substr(reste, p + length(nom))
  }
  return 0
}
BEGIN { n = split(noms, N, "|") }
FNR == 1 { fichier = FILENAME }
{
  l = $0
  if (l ~ /^[[:space:]]*#/) next
  if (mode == "script") { if (l ~ /constat_ajouter/) next; sub(/[[:space:]]#[[:space:]].*$/, "", l) }
  k = 0; liste = ""
  for (i = 1; i <= n; i++) if (presente(l, N[i])) { k++; liste = liste N[i] "," }
  if (k == 0) next
  motif = ""
  if (k >= 3) motif = "trois statuts ou plus sur une ligne"
  else if (mode == "script") {
    if (l ~ /[A-Za-z_]+=\(.*[A-Za-z]/ && l ~ /=\(/ ) motif = "déclaration de tableau avec un statut"
    for (i = 1; i <= n && motif == ""; i++) for (j = 1; j <= n; j++) {
      a = N[i]; b = N[j]
      if (index(l, a "\"|\"" b) || index(l, a "\"|" b) || index(l, a "|\"" b) || index(l, a "|" b)) { motif = "alternative de statuts (case)"; break }
    }
    if (motif == "" && l ~ /parmi .*"/) motif = "appartenance à une liste de statuts (parmi)"
  } else {
    if (k >= 2 && (index(l, "->") || index(l, "→"))) motif = "chaîne de statuts reliés par une flèche"
    else if (l ~ /([Pp]asse|[Pp]asser|[Pp]assage (à|en)|[Rr]epasse|[Mm]ets|[Mm]ettre|[Rr]emets|[Rr]emettre|besoin à|statut:)/) motif = "règle de transition (verbe de changement de statut et statut)"
  }
  if (motif != "") printf "%s:%d: %s : %s\n", fichier, FNR, motif, substr(l, 1, 160)
}
