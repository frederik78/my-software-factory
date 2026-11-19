---
id: 009-02
titre: Règles de l'orchestrateur : règles sans clé dans AGENTS.md et deliver
prd: docs/prd/009-regles-orchestrateur-dans-la-factory.md
besoin: F-14
statut: À faire
depend_de: []
criteres: [CA-05, CA-06, CA-07, CA-08, CA-09, CS-06, CS-08]
branche: feat/009-02-regles-sans-cle
commits: []
revue:
---

## Objectif
Règles sans clé (1, 2, 6, 7, 8) : section Orchestration d'`AGENTS.md` et du modèle (les huit puces, clés nommées), skill `deliver`.

## Périmètre
- Dans : Règles sans clé (1, 2, 6, 7, 8) : section Orchestration d'`AGENTS.md` et du modèle (les huit puces, clés nommées), skill `deliver`.
- Hors : les autres issues du PRD 009 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 009-02` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
