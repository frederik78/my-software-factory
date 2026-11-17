---
id: 002-01
titre: Reconnaître un test bash
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: Fait
depend_de: []
criteres: [CA-01, CA-02, CA-04, CA-08, CA-09, CA-17, CA-18, CS-01, CS-05]
branche: feat/002-01-reconnaitre-test-bash
commits: []
revue:
---

## Objectif
Le contrôle des critères sans test reconnaît un test écrit en bash : un appel à une fonction de test dont le premier argument entre guillemets commence par l'identifiant du critère, dans les fichiers `.sh` d'un dossier de tests, sans jamais exécuter ni modifier ce qu'il lit, et sans rien changer pour les langages déjà reconnus.

## Périmètre
- Dans : la forme reconnue avec la liste de fonctions par défaut (`verifier`, `verdict_cas`) ; les formes ignorées (autres fonctions, argument sans guillemets, ligne de définition, commentaire) ; un dossier sans appel reconnu ; l'union de plusieurs fichiers `.sh` et de sous-dossiers, les autres extensions ignorées ; la cohabitation avec un fichier Java ; la non-régression des langages existants ; le contenu des fichiers de tests comme entrée non fiable (rien n'est évalué), et aucun fichier du dépôt créé ou modifié par le contrôle.
- Hors : l'appel en milieu de ligne, les documents ici et les tolérances d'écriture de l'identifiant (issue 002-02) ; la configuration de la liste de fonctions (issue 002-03) ; le dossier de tests configurable (issue 002-04).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca01_…`, `cs01_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit, avec la sortie de `factory/scripts/tests/run.sh` avant et après ; pour CA-17, les cas existants des quatre langages passent sans modification.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-16 : revue 1/3 CHANGEMENTS DEMANDÉS (voir docs/reviews/002-01.md). IMPORTANT 1 (test CS-05 vacueux) et IMPORTANT 2 (guillemets simples de RG-01) renvoyés au développeur.
- 2026-11-16 : relais pour 002-02 : l'identifiant est cherché n'importe où dans le premier argument (D-06 / RG-03 / CA-05 demandent « commence par »), à resserrer dans 002-02.
- 2026-11-16 : mineurs ouverts (non corrigés d'office) : emplacement de `fonctions_bash` dans le script, commentaire à ajouter sur le helper `verdict_cas` de run.sh, mutation équivalente sur la ligne de définition.
- 2026-11-16 : le décompte annoncé par le développeur (625) venait d'une mesure à un autre état ; le nombre exact est 626 (verify-clean et revue).
- 2026-11-16 : revue 2/3 APPROUVÉ (docs/reviews/002-01.md). `verify-clean.sh` : 628 vérifications, VERIFY OK.
- 2026-11-16 : `scripts/fin-issue.sh 002-01` ne peut pas donner `FIN-ISSUE OK` avant 002-05 : sans configuration, « Dossier de tests introuvable : src/test » ; avec `DOSSIER_TESTS=factory/scripts/tests` dans l'environnement, le contrôle des critères répond OK mais la variable fuit dans la suite de tests (`run.sh` ne la neutralise pas) : TESTS EN ECHEC 121 sur 628, donc build en échec. Voir la dérogation ci-dessous.
- 2026-11-17 : DÉROGATION UNIQUE d'amorçage, décidée par l'utilisateur (option 1) : 002-01 passe `Fait` sans `FIN-ISSUE OK`. Preuves : revue 2 APPROUVÉ, `verify-clean.sh` TESTS OK 628, `criteres-sans-test.sh` OK (9 critères) avec `DOSSIER_TESTS=factory/scripts/tests`. À faire après la livraison de 002-05 : relancer `scripts/fin-issue.sh 002-01` et en inscrire le résultat ici. À corriger dans 002-04/002-06 : `run.sh` doit neutraliser `DOSSIER_TESTS`.
