---
id: 011-01
titre: Dépendances entre besoins : lecture de la colonne et erreur E15
prd: docs/prd/011-dependances-entre-besoins.md
besoin: F-15
statut: À faire
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-06, CA-07, CS-01, CS-02]
branche: feat/011-01-lecture-colonne-erreur-e15
commits: []
revue:
---

## Objectif
Lecture de la colonne « Dépend de » (par son nom), erreur E15 (inconnu, cycle, cellule trop longue), forme de la sortie, sûreté des valeurs.

## Périmètre
- Dans : Lecture de la colonne « Dépend de » (par son nom), erreur E15 (inconnu, cycle, cellule trop longue), forme de la sortie, sûreté des valeurs.
- Hors : les autres issues du PRD 011 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 011-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
