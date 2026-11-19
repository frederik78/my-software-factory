---
id: 006-01
titre: `MODE_REVUE`, six clés de modèle et d'effort et enveloppes d'agents
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: À faire
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CS-01, CS-02]
branche: feat/006-01-configuration-mode-revue-et-enveloppes
commits: []
revue:
---

## Objectif
Le mode de revue se règle (`unique` ou `parallele`, défaut `parallele`), le modèle et l'effort de chaque relecteur aussi, et les trois enveloppes d'agents sont générées.

## Périmètre
- Dans : `MODE_REVUE`, `config-factory.sh --mode-revue` (code 64 si invalide, vide compris), six clés `AGENT_MODELE_<ROLE>` / `AGENT_EFFORT_<ROLE>` qui l'emportent sur l'en-tête, `lib-config.sh`, `sync-claude.sh` (trois enveloppes sans outil d'écriture).
- Hors : les prompts et le brief (006-02), la skill `deliver` (006-03 et 006-04), la documentation (006-07).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
