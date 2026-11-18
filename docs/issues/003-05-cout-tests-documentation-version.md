---
id: 003-05
titre: Coût mesuré, tests réunis, documentation et version
prd: docs/prd/003-dashboard-a-jour.md
besoin: F-08
statut: À faire
depend_de: [003-03, 003-04]
criteres: [CA-23, CA-24, CA-25, CA-26, CA-27]
branche: feat/003-05-cout-tests-documentation-version
commits: []
revue:
---

## Objectif
Une génération du dashboard fait au plus un appel Git de plus qu'avant, quel que soit le nombre d'issues et de branches ; tous les cas de F-08 figurent dans les tests de la factory ; la documentation et la version (la suivante libre) sont à jour.

## Périmètre
- Dans : mesure du nombre d'appels Git (deux dépôts jetables identiques, comptage par un `git` en tête de `PATH`), non-régression sans branche à déduire, présence de CA-01 à CA-24 et CS-01 à CS-06 dans `run.sh`, documentation (en-tête de `scripts/dashboard.sh`, README du dashboard avec le rappel `--boucle`, modèle d'AGENTS.md si concerné), `factory/VERSION`, CHANGELOG, migration « remplacer `factory/` ».
- Hors : le comportement de rattachement, de statut et d'avancement (003-01 à 003-04).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Le comptage d'appels Git avant / après (chiffres et commande) ; un test par critère de documentation et de version qui échoue puis réussit ; suite entière verte.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
