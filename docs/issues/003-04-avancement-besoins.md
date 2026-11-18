---
id: 003-04
titre: Avancement des besoins et alerte de divergence
prd: docs/prd/003-dashboard-a-jour.md
besoin: F-08
statut: À faire
depend_de: [003-02]
criteres: [CA-16, CA-17, CA-18, CA-19, CA-20]
branche: feat/003-04-avancement-besoins
commits: []
revue:
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
