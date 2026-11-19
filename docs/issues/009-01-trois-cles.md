---
id: 009-01
titre: Trois clés
prd: docs/prd/009-regles-orchestrateur-dans-la-factory.md
besoin: F-14
statut: À faire
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CS-01, CS-03]
branche: feat/009-01-trois-cles
commits: []
revue:
---

## Objectif
Trois clés : liste des clés, défauts, options de `config-factory.sh`, validation et code 64, `.factory.conf` et modèle.

## Périmètre
- Dans : Trois clés : liste des clés, défauts, options de `config-factory.sh`, validation et code 64, `.factory.conf` et modèle.
- Hors : les autres issues du PRD 009 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 009-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
