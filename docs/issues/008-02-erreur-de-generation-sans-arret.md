---
id: 008-02
titre: Erreur de génération sans arrêt
prd: docs/prd/008-boucle-dashboard-code-a-jour.md
besoin: F-11
statut: À faire
depend_de: [008-01]
criteres: [CA-07, CA-08, CA-09, CA-10, CS-03, CS-04, CS-05]
branche: feat/008-02-erreur-de-generation-sans-arret
commits: []
revue:
---

## Objectif
Erreur de génération sans arrêt, signaux, page atomique, pas de boucle serrée, sortie d'erreur et temporaires.

## Périmètre
- Dans : Erreur de génération sans arrêt, signaux, page atomique, pas de boucle serrée, sortie d'erreur et temporaires.
- Hors : les autres issues du PRD 008 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 008-02` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
