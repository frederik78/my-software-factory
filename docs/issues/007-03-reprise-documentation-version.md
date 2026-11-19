---
id: 007-03
titre: Reprise des issues existantes, documentation, version et tests réunis
prd: docs/prd/007-champ-branche-renseigne.md
besoin: F-06
statut: À faire
depend_de: [007-01, 007-02]
criteres: [CA-15, CA-16, CA-17, CA-18, CA-19, CS-04]
branche: feat/007-03-reprise-documentation-version
commits: []
revue:
---

## Objectif
Les issues existantes à champ vide sont complétées d'après l'historique, avec preuve ; la documentation, la version et le CHANGELOG décrivent F-06.

## Périmètre
- Dans : Reprise des issues à `branche:` vide (noms vérifiés, nom non vérifié laissé vide), documentation, version suivante libre, CHANGELOG et UPGRADE, tests regroupés dans `run.sh`.
- Hors : tout nouveau comportement (007-01 et 007-02).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 007-03` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
