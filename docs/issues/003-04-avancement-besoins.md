---
id: 003-04
titre: Avancement des besoins et alerte de divergence
prd: docs/prd/003-dashboard-a-jour.md
besoin: F-08
statut: Fait
depend_de: [003-02]
criteres: [CA-16, CA-17, CA-18, CA-19, CA-20]
branche: feat/003-04-avancement-besoins
commits: [00157f6, 8de4a0a]
revue: docs/reviews/003-04.md (APPROUVÉ, itération 1/3)
---

## Objectif
La carte d'un besoin affiche le compte de ses issues par statut effectif et la mention « à vérifier : … » quand le statut du backlog diverge ; le dashboard ne modifie jamais `backlog.md`.

## Périmètre
- Dans : compte par statut effectif, motifs de divergence du tableau de RG-17, besoin sans issue, statuts hors cycle comptés comme « non Fait », `backlog.md` intact (génération unique et boucle).
- Hors : le calcul du statut effectif (003-02), le verdict de revue (F-03).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue (carte de besoin sans compte) puis réussit ; contrôle que `backlog.md` est identique avant et après une génération.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-17 : développeur : `FIN-ISSUE OK 003-04 8de4a0a : 924 tests, 0 échec, 0 ignoré` (906 avant, +18). RED constaté : 14 échecs sur 924 (ca16 ×5, ca17 ×2, ca18 ×5, ca19 ×1, ca20 ×1) ; les tests négatifs de CA-17, CA-19, CA-20 prouvés par 2 mutations (divergence à tort ; écriture dans backlog.md).
- Choix du développeur : lignes « avancement » et « à vérifier » en `<span class="detail">` après la priorité, sans CSS propre (limiter les conflits avec 003-03) ; statut d'issue vide compté comme un statut hors cycle d'étiquette vide, sans cas particulier.
- Conflits possibles à la fusion avec 003-03 : boucle de lecture de `generer` (ajout de `besoin_issue`) et insertion de la section de tests avant le résumé final de `run.sh`.
- 2026-11-18 : revue 1 APPROUVÉ sans constat bloquant ni important, 8 mutations sur 8 détectées ; `FIN-ISSUE OK 003-04 4e00cee : 924 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après le dernier commit de code).
- Mineurs ouverts : (1) `dashboard.sh:367` appelle `mapfile`, absent de `/bin/bash` 3.2 (code des issues 003-01/02, hors diff) ; (2) un statut d'issue vide laisse une espace finale dans le compte (effet connu de la décision prise).
