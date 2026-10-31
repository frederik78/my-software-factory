---
id: <prd>-<nn>
titre: <titre court>
prd: docs/prd/<prd>-<module>.md
besoin: F-xx
statut: À faire
depend_de: []
criteres: [CA-xx, CS-xx]
branche:
commits: []
revue:
---

## Objectif
Une ou deux phrases : ce que la tranche apporte, de façon observable.

## Périmètre
- Dans : …
- Hors : … (renvoyer à l'issue qui s'en charge)

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom ou le `@DisplayName` contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Comment le développeur prouvera chaque critère (avant / après) : test qui échoue puis réussit, chiffres mesurés avec leur commande, captures. Une ligne.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
