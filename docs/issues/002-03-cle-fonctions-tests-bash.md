---
id: 002-03
titre: Clé TESTS_BASH_FONCTIONS
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: En revue
depend_de: [002-01]
criteres: [CA-03, CA-14, CA-15, CS-02, CS-04, CS-06]
branche: feat/002-03-cle-fonctions-tests-bash
commits: []
revue:
---

## Objectif
La liste des fonctions de test reconnues se règle dans la configuration de la factory : elle remplace la liste par défaut, elle est validée avant tout usage, elle suit la priorité des autres clés, et le fichier de configuration n'est jamais exécuté ni évalué.

## Périmètre
- Dans : la clé `TESTS_BASH_FONCTIONS` (noms séparés par des espaces, qui remplacent le défaut) ; sa validation (noms limités à `[A-Za-z_][A-Za-z0-9_]*`, 64 caractères et 20 noms au plus, jamais vide), refusée avec le code 64 et un message clair ; sa priorité (variable, fichier local, fichier versionné, défaut) ; sa lecture sans jamais sourcer ni évaluer le fichier ; l'entrée de configuration comme donnée non fiable (valeurs hostiles, caractères de contrôle neutralisés dans les messages).
- Hors : la clé du dossier de tests et l'affichage de la configuration (issue 002-04), la lecture de la configuration par `fin-issue.sh` (issue 002-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca03_…`, `cs02_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit, avec la sortie de `factory/scripts/tests/run.sh` avant et après ; pour CS-02, CS-04 et CS-06, des valeurs hostiles dont aucune n'exécute de commande.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-17 : revue 1 APPROUVÉ (docs/reviews/002-03.md). `verify-clean.sh` 674 OK ; critères OK avec `DOSSIER_TESTS=factory/scripts/tests`. `scripts/fin-issue.sh 002-03` échoue (attendu, bootstrap F-05, lecture de la configuration en 002-05). Passage à `Fait` en attente de l'accord de l'utilisateur, la dérogation accordée pour 002-01 étant « unique ».
- Mineurs ouverts : `|| return 64` mort dans `lib-config.sh:64` ; pas de cas dédié aux doublons ni à la tabulation entre noms valides.
- Choix du développeur à confirmer : espaces multiples tolérés, doublons acceptés, tabulation refusée ; message sans la valeur ; clé en dernier dans l'affichage de `config-factory.sh` (à confirmer en 002-04).
