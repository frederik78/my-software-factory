---
id: 004-01
titre: Table unique des statuts et lecture du backlog et des en-têtes
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: Fait
depend_de: [003-05]
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-06, CA-07, CA-08, CA-09]
branche: feat/004-01-table-unique-lecture
commits: [d9fad3f, 92a148f, 56c7631, b750ce0, e77973d, 4cf4691, a068ade, 770677b]
revue: docs/reviews/004-01.md (APPROUVÉ, itération 3/3)
---

## Objectif
Une table unique définit les statuts et transitions des besoins et des issues (affichable par `scripts/statuts.sh --table`) ; le dashboard, la bibliothèque des issues et `etat-issues.sh` la lisent au lieu de répéter les listes ; `scripts/statuts.sh` lit `backlog.md` et les en-têtes d'issue, rejette un statut inconnu et rend sa sortie et ses codes.

## Périmètre
- Dans : la table des statuts et transitions (une par entité), `--table`, la source unique pour les lecteurs existants, statuts inconnus, lecture du backlog et des en-têtes d'issue, forme de la sortie, codes de sortie.
- Hors : preuves d'une issue (004-02), cohérence des besoins (004-03), lecture seule, coût, fichiers hostiles (004-04), dashboard, `/deliver`, documentation, version (004-05), retrait des anciennes listes (004-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère sur des dépôts jetables, qui échoue puis réussit ; vérifications de `run.sh` avant / après.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 : revue 1 CHANGEMENTS DEMANDÉS (1 BLOQUANT : 0x1F dans une cellule du backlog ; 5 IMPORTANT), revue 2 CHANGEMENTS DEMANDÉS (1 IMPORTANT : neutralisation quadratique sous bash 3.2), revue 3 APPROUVÉ ; `FIN-ISSUE OK 004-01 de28055 : 1139 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après le dernier commit de code).
- Décisions de l'utilisateur (2026-11-18, « Oui à tout », recommandations de l'orchestrateur) : les caractères C1 (U+0080-009F) et bidi (U+200E/F, U+202A-202E, U+2066-2069) sont retirés par la neutralisation ; deux fichiers de même `id:` donnent chacun E11 et, si le statut est inconnu, E10 avec l'objet `fichier <chemin>`. Choix acceptés : ordre de tri entre groupes (backlog, besoins, issues), ligne de backlog sans identifiant ignorée sans E03, un seul E04 par identifiant en double, pas de retrait des guillemets sur les cellules du backlog, E01 pour dossier ou fichier non lisible (lien symbolique valide lu).
- Passages du PRD 004 à préciser par l'utilisateur : ligne 148 (« n'émet aucun autre constat » pour E10/E11/E14, faux pour un doublon d'identifiant) ; RG-06 (guillemets de bord des cellules du backlog non retirés) ; RG-21 (C1 et bidi retirés, 0x1F remplacé par U+FFFD, 120 caractères UTF-8 indépendants de la locale) ; RG-20 (ordre de tri entre groupes de même gravité).
- Mineurs ouverts : ligne de backlog à id vide ignorée sans E03 ; message `towc` d'awk sur un octet invalide dans un en-tête (code antérieur, `issue_champ`) ; valeur non ASCII imprimable : 3 processus par valeur (5 000 statuts inconnus accentués = 20 s contre 2 s) ; seul le BSD awk de macOS a été testé (gawk, mawk absents).
