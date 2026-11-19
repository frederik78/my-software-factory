---
id: 005-03
titre: Documentation, version 1.25.0 et non-régression
prd: docs/prd/005-format-revue-consolide.md
besoin: F-12
statut: En cours
depend_de: [005-02]
criteres: [CA-19, CA-20, CA-21, CA-22]
branche:
commits: []
revue:
---

## Objectif
La factory passe en version 1.25.0 : le CHANGELOG et le guide de migration décrivent le changement, la documentation est à jour, et rien d'autre n'a changé.

## Périmètre
- Dans : fichier de version, CHANGELOG, UPGRADE, guide `factory/README.md`, tests regroupés, non-régression.
- Hors : tout le contenu fonctionnel (005-01, 005-02).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- Version 1.25.0 attendue (suivante libre après 1.24.0 de F-09) ; à confirmer au moment de la livraison.
