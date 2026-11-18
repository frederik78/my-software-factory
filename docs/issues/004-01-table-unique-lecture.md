---
id: 004-01
titre: Table unique des statuts et lecture du backlog et des en-têtes
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: À faire
depend_de: [003-05]
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-06, CA-07, CA-08, CA-09]
branche: feat/004-01-table-unique-lecture
commits: []
revue:
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
