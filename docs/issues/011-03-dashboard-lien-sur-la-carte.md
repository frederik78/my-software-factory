---
id: 011-03
titre: Dashboard (lien sur la carte
prd: docs/prd/011-dependances-entre-besoins.md
besoin: F-15
statut: À faire
depend_de: [011-02]
criteres: [CA-15, CA-16, CA-17, CA-18, CA-19, CA-20, CA-21, CA-22, CS-03]
branche: feat/011-03-dashboard-lien-sur-la-carte
commits: []
revue:
---

## Objectif
Dashboard (lien sur la carte, colonnes lues par leur nom, section de contrôle, échappement), documentation, version, CHANGELOG, tests regroupés, non-régression.

## Périmètre
- Dans : Dashboard (lien sur la carte, colonnes lues par leur nom, section de contrôle, échappement), documentation, version, CHANGELOG, tests regroupés, non-régression.
- Hors : les autres issues du PRD 011 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 011-03` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
