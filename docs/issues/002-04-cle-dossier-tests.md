---
id: 002-04
titre: Clé DOSSIER_TESTS
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: En cours
depend_de: [002-03]
criteres: [CA-10, CA-11, CA-12, CA-13, CA-16, CS-03]
branche: feat/002-04-cle-dossier-tests
commits: []
revue:
---

## Objectif
Le dossier des tests se règle dans la configuration de la factory, avec une priorité claire entre les cinq sources, sans changer le comportement des projets qui ne la règlent pas, et l'affichage de la configuration montre les deux clés.

## Périmètre
- Dans : la clé `DOSSIER_TESTS` dans `.factory.conf` (en plus de la variable d'environnement actuelle) ; l'ordre des cinq sources, testé en retirant la plus forte une à une, une valeur vide d'une source de configuration l'emportant sur une source plus faible ; la détection actuelle (`src/test`, `tests`, `test`) inchangée par défaut ; un dossier configuré absent donne « Dossier de tests introuvable » et le code 64, sans repli ; l'affichage de `DOSSIER_TESTS=` et de `TESTS_BASH_FONCTIONS=` par `config-factory.sh` ; la documentation des deux clés dans le modèle `.factory.conf` ; la valeur lue comme un chemin, jamais comme une option (`-n`, `--help`, chemin à espaces).
- Hors : la clé des fonctions (issue 002-03), la lecture par `fin-issue.sh` et le réglage de ce dépôt (issue 002-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca10_…`, `cs03_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit, avec la sortie de `factory/scripts/tests/run.sh` avant et après ; pour CA-11, une exécution par source retirée.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
