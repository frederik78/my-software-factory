---
id: 006-07
titre: Documentation, version, tests réunis et non-régression
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: À faire
depend_de: [006-01, 006-02, 006-03, 006-04, 006-05, 006-06, 006-08]
criteres: [CA-25, CA-26, CA-27, CA-28, CA-29, CA-30, CA-31, CA-32, CA-33, CA-50]
branche: feat/006-07-documentation-version-non-regression
commits: []
revue:
---

## Objectif
La documentation, la version et le CHANGELOG décrivent la revue parallèle ; la suite regroupe les cas de CA-01 à CA-41 et le mode `unique` reproduit l'ancien comportement.

## Périmètre
- Dans : `AGENTS.md` et son modèle (renvoi, sans recopie), READMEs, `.factory.conf`, version suivante libre et CHANGELOG / UPGRADE, tests regroupés dans `run.sh`, non-régression du mode `unique`.
- Hors : tout nouveau comportement (006-01 à 006-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-07` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
