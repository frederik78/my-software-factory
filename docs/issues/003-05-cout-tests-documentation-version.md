---
id: 003-05
titre: Coût mesuré, tests réunis, documentation et version
prd: docs/prd/003-dashboard-a-jour.md
besoin: F-08
statut: Fait
depend_de: [003-03, 003-04]
criteres: [CA-23, CA-24, CA-25, CA-26, CA-27]
branche: feat/003-05-cout-tests-documentation-version
commits: [dd3924e, 6116658, 11b0767, cbb81ee, b87b529, ef98513, 1cb9bbd, 9d6e1b8, b84fd30, 0f0e667, b2f4c5d]
revue: docs/reviews/003-05.md (APPROUVÉ, itération 2/3)
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
- 2026-11-18 : revue 1 CHANGEMENTS DEMANDÉS (1 IMPORTANT : ca27 strict contre les étiquettes Git), corrigé ; revue 2 APPROUVÉ ; `FIN-ISSUE OK 003-05 b23e8b8 : 1078 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après le dernier commit de code).
- Version 1.22.0 pour F-08 (D-27) ; F-01 passe à 1.23.0 (PRD 001 RG-19/CA-18 et issue 001-06 à corriger à sa livraison). Coût de `--prochaine` par dépendance : F-10 (D-28).
- Mineurs ouverts : ca25 ne vérifie que la présence de la chaîne `caNN_` ; comparaison au CHANGELOG de ca27 non éprouvée par un cas rouge (mutation M3 survit) ; skill `deliver` l.15 (dépendance « Fait » locale) reporté à F-09.
- Passages devenus faux, à l'utilisateur : PRD 003 ligne 33 (dépassée par RG-19/RG-20) ; PRD 002 lignes 17 et 20 (version 1.20.1), CS-04 (`$(touch marque)` donne « introuvable », code 64), bloc `ca21` ; backlog D-05 (1.21.0 pour F-01).
