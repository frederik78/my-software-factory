---
id: 009-04
titre: Règles de l'orchestrateur : aucun droit nouveau, documentation, version et non-régression
prd: docs/prd/009-regles-orchestrateur-dans-la-factory.md
besoin: F-14
statut: À faire
depend_de: [009-01, 009-02, 009-03]
criteres: [CA-14, CA-15, CA-16, CA-17, CA-18, CA-19, CA-20, CS-05, CS-09]
branche: feat/009-04-aucun-droit-documentation-version
commits: []
revue:
---

## Objectif
Aucun droit nouveau, garde-statuts et garde-fous prouvés, README, version, CHANGELOG, UPGRADE, tests regroupés, non-régression.

## Périmètre
- Dans : Aucun droit nouveau, garde-statuts et garde-fous prouvés, README, version, CHANGELOG, UPGRADE, tests regroupés, non-régression.
- Hors : les autres issues du PRD 009 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 009-04` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
