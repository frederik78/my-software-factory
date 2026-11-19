---
id: 009-03
titre: Règles à clé (3
prd: docs/prd/009-regles-orchestrateur-dans-la-factory.md
besoin: F-14
statut: À faire
depend_de: [009-01, 009-02]
criteres: [CA-10, CA-11, CA-12, CA-13, CS-02, CS-04, CS-07]
branche: feat/009-03-regles-a-cle-3
commits: []
revue:
---

## Objectif
Règles à clé (3, 4, 5) dans `deliver`, protection des branches de `worktree-issue.sh` et son en-tête.

## Périmètre
- Dans : Règles à clé (3, 4, 5) dans `deliver`, protection des branches de `worktree-issue.sh` et son en-tête.
- Hors : les autres issues du PRD 009 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 009-03` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
