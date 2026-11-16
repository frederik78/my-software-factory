---
id: 002-05
titre: fin-issue.sh lit la configuration
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: À faire
depend_de: [002-04]
criteres: [CA-19, CA-20, CA-21, CA-25]
branche:
commits: []
revue:
---

## Objectif
Le contrôle de fin d'issue applique la configuration du dépôt à l'extraction de `HEAD` où il vérifie les critères : une issue dont chaque critère a son cas bash obtient `FIN-ISSUE OK`, et ce dépôt règle son dossier de tests. Une fois cette issue livrée, l'issue 001-01 peut être clôturée.

## Périmètre
- Dans : l'extraction de `HEAD` reçoit la lecture de configuration et utilise le `.factory.conf` du commit ; le `.factory.local.conf` non versionné y est ignoré ; le refus de `DOSSIER_TESTS` absolu ou contenant `..` pour les quatre sources (variable, `FACTORY_DOSSIER_TESTS`, `.factory.local.conf`, `.factory.conf`) ; le réglage de ce dépôt (`DOSSIER_TESTS=factory/scripts/tests` dans `.factory.conf`) et le contrôle d'une issue de ce dépôt dont les critères ont leurs cas bash.
- Hors : la reconnaissance et la configuration elles-mêmes (issues 002-01 à 002-04), la documentation et la version (issue 002-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca19_…`, `ca25_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit, avec la sortie de `factory/scripts/tests/run.sh` avant et après ; pour CA-21, `scripts/criteres-sans-test.sh` sur une issue de ce dépôt rend `OK`.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
