---
id: 002-04
titre: Clé DOSSIER_TESTS
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: Fait
depend_de: [002-03]
criteres: [CA-10, CA-11, CA-12, CA-13, CA-16, CS-03]
branche: feat/002-04-cle-dossier-tests
commits: [107a57d, 35baec2, 6546774]
revue: APPROUVÉ (itération 2 sur 2, docs/reviews/002-04.md)
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
- 2026-11-17 : branche empilée sur feat/002-02-lecture-precise-tests-bash (base ff49ffa) : à fusionner APRÈS 002-02. Ne pas livrer seule : le modèle `.factory.conf` annonce un refus par `fin-issue.sh` des chemins absolus et `..`, vrai seulement après 002-05.
- 2026-11-17 : revue 1 CHANGEMENTS DEMANDÉS (1 IMPORTANT [A03] : le message « Dossier de tests introuvable » recopiait la valeur brute, séquences d'échappement et ligne `FIN-ISSUE OK` forgeable ; cas CS-06 non listé dans l'issue, traité quand même), revue 2 APPROUVÉ. `verify-clean.sh` 754 OK ; `criteres-sans-test.sh` OK avec `DOSSIER_TESTS=factory/scripts/tests`.
- 2026-11-17 : `scripts/fin-issue.sh 002-04` échoue (attendu : `Dossier de tests introuvable : src/test`, dérogation d'amorçage étendue par l'utilisateur aux issues de F-05 jusqu'à 002-05). À relancer après 002-05.
- Décisions en attente de l'utilisateur (à inscrire au PRD) : (1) PRD CS-04 cite `DOSSIER_TESTS=$(touch marque)` comme ligne « ignorée » ; avec la clé réelle elle donne « introuvable » (64), jamais évaluée : texte du PRD à ajuster ; (2) `config-factory.sh` affiche la valeur effective de `DOSSIER_TESTS`, variable non préfixée non vide comprise ; (3) une valeur de fichier faite d'espaces seuls est ramenée à vide (comportement existant de `lib-config.sh`) donc détection automatique et non « introuvable » ; (4) CS-06 (neutralisation du message) appliqué à 002-04 bien que l'issue ne le liste pas.
- Mineurs ouverts : octet 0x9B isolé non retiré du message (locale), U+2028 conservé, `config-factory.sh` affiche toutes les valeurs brutes (diagnostic, hors périmètre), mention « refusé par fin-issue.sh » du modèle valable après 002-05.
- 2026-11-17 : rattrapage de la dérogation d'amorçage F-05, `scripts/fin-issue.sh 002-04` lancé depuis la branche de 002-05 (HEAD 569954a, qui contient le code de 002-01 à 002-05) : `FIN-ISSUE OK 002-04 569954a : 783 tests, 0 échec, 0 ignoré`.
