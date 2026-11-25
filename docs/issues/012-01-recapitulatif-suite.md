---
id: 012-01
titre: Échecs identifiables : récapitulatif de la suite
prd: docs/prd/012-echecs-identifiables.md
besoin: F-17
statut: À faire
depend_de: []
criteres: [CA-01, CA-02, CA-03, CS-01]
branche: feat/012-01-recapitulatif-suite
commits: []
revue:
---

## Objectif
Récapitulatif des tests en échec à la fin de la suite de la factory, neutralisé ; sortie inchangée sans échec.

## Périmètre
- Dans : Récapitulatif des tests en échec à la fin de la suite de la factory, neutralisé ; sortie inchangée sans échec.
- Hors : les autres issues du PRD 012 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 012-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
