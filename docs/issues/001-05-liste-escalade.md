---
id: 001-05
titre: Liste d'escalade
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: Fait
depend_de: []
criteres: [CA-16]
branche: feat/001-05-liste-escalade
commits: [17df2d5, 719f80a, 0ba9e0b, 42f8654]
revue: APPROUVÉ (itération 2 sur 3, docs/reviews/001-05.md)
---

## Objectif
Les consignes de tous les agents énumèrent les six sujets qu'ils doivent remonter à l'utilisateur sans trancher seuls (secrets et identifiants, authentification et autorisation, dépendance et licence, déploiement et CI, contrat d'un service externe, écart avec le PRD), avec la consigne de s'arrêter et de les ranger dans `## QUESTIONS` ou `## À trancher par l'utilisateur`.

## Périmètre
- Dans : la liste, la consigne d'arrêt et les deux destinations, à l'identique dans le modèle d'`AGENTS.md` fourni aux nouveaux projets et dans `AGENTS.md` de ce dépôt.
- Hors : la version, le CHANGELOG et la mention dans le guide d'utilisation (issue 001-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca16_…`).

## Preuve attendue
Un test de lecture des deux fichiers qui échoue avant la modification puis réussit après, avec la commande qui le produit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-17 : revue 1 CHANGEMENTS DEMANDÉS (2 IMPORTANT : le test ca16_ cherchait dans tout le fichier au lieu de la section, et RG-14 / RG-15 non testées), revue 2 APPROUVÉ. `verify-clean.sh` 676 OK ; `criteres-sans-test.sh` OK avec `DOSSIER_TESTS=factory/scripts/tests`.
- 2026-11-17 : `scripts/fin-issue.sh 001-05` échoue (`Dossier de tests introuvable : src/test`, DOSSIER_TESTS non réglé dans ce dépôt avant 002-05). Statut laissé `En revue` : la dérogation d'amorçage accordée par l'utilisateur couvre les issues de F-05, pas celles de F-01 (D-08 garde 001-01 `En cours` pour la même raison). Passage à `Fait` en attente de son accord, ou de 002-05.
- Mineurs ouverts : diff des deux sections de l'AGENTS.md absent du test ; redite « ne tranche pas seul » / « ne décide pas seul » dans la section ; titre de section en double non détecté.
- Choix du développeur acceptés par la revue (à confirmer au PRD) : titre « Sujets à remonter à l'utilisateur », emplacement avant « Tests (TDD obligatoire) », « code-reviewer » pour « reviewer ».
- 2026-11-18 : `FIN-ISSUE OK 001-05 c1c80cf : 1080 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après la fusion de `develop` dans la branche, qui apporte `DOSSIER_TESTS` de 002-05). La dérogation d'amorçage n'est plus nécessaire ; l'issue passe à Fait.
