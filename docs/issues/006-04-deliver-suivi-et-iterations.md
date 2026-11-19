---
id: 006-04
titre: Skill deliver : suivi fusionné, itérations, tour final et arrêt
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: À faire
depend_de: [006-03]
criteres: [CA-18, CA-19, CA-20, CA-21, CA-22, CA-23, CA-24, CS-05, CS-08]
branche: feat/006-04-deliver-suivi-et-iterations
commits: []
revue:
---

## Objectif
`/deliver` fusionne les constats des relecteurs, tranche ou remonte leurs contradictions, relance les seuls relecteurs concernés, fait le tour final et applique la règle d'arrêt.

## Périmètre
- Dans : Skill `deliver` : suivi fusionné, contradictions, itérations, tour final compté dans `MAX_ITERATIONS_REVUE`, arrêt, corrections, mode sans sous-agents, rapports hostiles.
- Hors : le lancement et les verdicts (006-03), `/code-review` (006-05 et 006-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-04` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
