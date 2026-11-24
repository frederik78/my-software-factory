---
id: 007-01
titre: Modèle d'issue et README des issues : champ branche rempli à la création
prd: docs/prd/007-champ-branche-renseigne.md
besoin: F-06
statut: En revue
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05]
branche: feat/007-01-modele-issue-et-readme
commits: []
revue: APPROUVÉ (itération 1, docs/reviews/007-01.md)
---

## Objectif
Le modèle d'issue et les README disent de remplir `branche:` à la création avec `feat/<prd>-<nn>-<slug>`.

## Périmètre
- Dans : `docs/issues/_template.md` et son jumeau `factory/templates/docs/issues/_template.md` (identiques), README des issues (ce dépôt et le modèle), `/to-tickets` et `deliver` intacts, modèle ignoré par les scripts
- Hors : l'avis de `statuts.sh` (007-02), la reprise des issues existantes, la documentation et la version (007-03).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 007-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-19 : CA-02 et CA-04 sont des invariants (verts dès le départ, RED impossible) ; leurs tests ont été éprouvés par mutation exécutée. CA-04 lit l'historique (commits citant 007-01) et se déclare non vérifiable hors dépôt git. Les deux README gardent leurs différences existantes ; seules trois lignes identiques y sont ajoutées.
