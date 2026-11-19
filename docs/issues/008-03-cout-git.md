---
id: 008-03
titre: Coût (Git)
prd: docs/prd/008-boucle-dashboard-code-a-jour.md
besoin: F-11
statut: À faire
depend_de: [008-01, 008-02]
criteres: [CA-11, CA-12, CA-13, CA-14, CA-15, CA-16]
branche: feat/008-03-cout-git
commits: []
revue:
---

## Objectif
Coût (Git), documentation, version, CHANGELOG et UPGRADE, tests regroupés à durée bornée, non-régression.

## Périmètre
- Dans : Coût (Git), documentation, version, CHANGELOG et UPGRADE, tests regroupés à durée bornée, non-régression.
- Hors : les autres issues du PRD 008 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 008-03` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
