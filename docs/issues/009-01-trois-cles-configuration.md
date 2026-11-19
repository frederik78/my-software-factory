---
id: 009-01
titre: Règles de l'orchestrateur : trois clés de configuration
prd: docs/prd/009-regles-orchestrateur-dans-la-factory.md
besoin: F-14
statut: En revue
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CS-01, CS-03]
branche: feat/009-01-trois-cles-configuration
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
- 2026-11-19 : les trois clés sont placées après `MAX_CRITERES_ISSUE` dans `CONFIG_CLES` (donc dans la liste sans option) ; défaut `non` porté par `lib-config.sh` (`<CLÉ>_DEFAUT`), relu par `config-factory.sh`.
- 2026-11-19 : validation unique `config_oui_non` (lib-config.sh), calquée sur `config_mode_revue` : comparaison textuelle, saut de ligne final conservé, message sans la valeur, code 64.
- 2026-11-19 : les commentaires de `.factory.conf` et de son modèle sont identiques (seule la valeur change) ; les tests ancrent leurs phrases exactes.
