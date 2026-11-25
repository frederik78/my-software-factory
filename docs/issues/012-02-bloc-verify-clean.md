---
id: 012-02
titre: Échecs identifiables : bloc de verify-clean.sh
prd: docs/prd/012-echecs-identifiables.md
besoin: F-17
statut: À faire
depend_de: [012-01]
criteres: [CA-04, CA-05, CA-06, CA-07, CA-08, CS-02, CS-03, CS-04, CS-05, CS-06]
branche: feat/012-02-bloc-verify-clean
commits: []
revue:
---

## Objectif
Bloc des échecs dans la sortie de `verify-clean.sh` : lecture stricte, bornes, neutralisation, autres outils de test inchangés.

## Périmètre
- Dans : Bloc des échecs dans la sortie de `verify-clean.sh` : lecture stricte, bornes, neutralisation, autres outils de test inchangés.
- Hors : les autres issues du PRD 012 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 012-02` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
