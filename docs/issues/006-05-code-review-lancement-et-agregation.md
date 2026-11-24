---
id: 006-05
titre: Skill code-review : lecture du mode, trois relecteurs et agrégation
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: En cours
depend_de: [006-02, 006-03]
criteres: [CA-34, CA-35, CA-36, CA-37, CA-38, CS-09, CS-10]
branche: feat/006-05-code-review-lancement-et-agregation
commits: []
revue:
---

## Objectif
`/code-review` suit `MODE_REVUE` : en `unique` il est inchangé et n'écrit aucun fichier ; en `parallele` il lance les trois relecteurs et agrège leurs verdicts.

## Périmètre
- Dans : Skill `code-review` : lecture du mode, `unique` inchangé, trois relecteurs, agrégation, itérations, point fixe hostile.
- Hors : le fichier de revue de branche (006-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-05` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
