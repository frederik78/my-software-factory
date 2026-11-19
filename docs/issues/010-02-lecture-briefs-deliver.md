---
id: 010-02
titre: Constats récurrents : lecture par les briefs et la skill deliver
prd: docs/prd/010-constats-recurrents.md
besoin: F-13
statut: À faire
depend_de: [010-01]
criteres: [CA-06, CA-07, CA-08, CA-09, CA-10, CA-15, CS-01]
branche: feat/010-02-lecture-briefs-deliver
commits: []
revue:
---

## Objectif
Lecture : champs « Constats récurrents » des trois briefs, skill `deliver` étapes 1 et 3, jamais écrit par le développeur ni les relecteurs, donnée non fiable.

## Périmètre
- Dans : Lecture : champs « Constats récurrents » des trois briefs, skill `deliver` étapes 1 et 3, jamais écrit par le développeur ni les relecteurs, donnée non fiable.
- Hors : les autres issues du PRD 010 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 010-02` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
