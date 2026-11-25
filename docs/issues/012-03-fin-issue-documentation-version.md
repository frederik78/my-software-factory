---
id: 012-03
titre: Échecs identifiables : bloc répété par fin-issue.sh, documentation, version et non-régression
prd: docs/prd/012-echecs-identifiables.md
besoin: F-17
statut: À faire
depend_de: [012-02]
criteres: [CA-09, CA-10, CA-11, CA-12, CA-13, CA-14, CS-07]
branche: feat/012-03-fin-issue-documentation-version
commits: []
revue:
---

## Objectif
Bloc répété par `fin-issue.sh` avant sa dernière ligne, faux bloc ignoré, coût, documentation, version, non-régression.

## Périmètre
- Dans : Bloc répété par `fin-issue.sh` avant sa dernière ligne, faux bloc ignoré, coût, documentation, version, non-régression.
- Hors : les autres issues du PRD 012 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 012-03` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
