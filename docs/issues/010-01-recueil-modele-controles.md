---
id: 010-01
titre: Constats récurrents : le recueil, son modèle et ses contrôles
prd: docs/prd/010-constats-recurrents.md
besoin: F-13
statut: En cours
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CS-02, CS-03, CS-05]
branche: feat/010-01-recueil-modele-controles
commits: []
revue:
---

## Objectif
Le recueil : fichier amorcé, modèle, introduction, contrôle de forme et de borne par test, aucun secret.

## Périmètre
- Dans : Le recueil : fichier amorcé, modèle, introduction, contrôle de forme et de borne par test, aucun secret.
- Hors : les autres issues du PRD 010 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 010-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
