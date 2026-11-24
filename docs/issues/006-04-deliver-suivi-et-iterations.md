---
id: 006-04
titre: Skill deliver : suivi fusionné, itérations, tour final et arrêt
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: En revue
depend_de: [006-03]
criteres: [CA-18, CA-19, CA-20, CA-21, CA-22, CA-23, CA-24, CA-42, CS-05, CS-08]
branche: feat/006-04-deliver-suivi-et-iterations
commits: []
revue:
---

## Objectif
`/deliver` fusionne les constats des relecteurs, tranche ou remonte leurs contradictions, relance les seuls relecteurs concernés, fait le tour final et applique la règle d'arrêt.

## Périmètre
- Dans : Skill `deliver` : suivi fusionné, contradictions, itérations, tour final compté dans `MAX_ITERATIONS_REVUE`, arrêt, corrections, mode sans sous-agents, rapports hostiles.
- Hors : le lancement et les verdicts (006-03), `/code-review` (006-05 et 006-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-04` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-24 : nouvelle étape `3 ter` de la skill `deliver` (suivi, contradictions, itérations, tour final, arrêt, corrections, rapports hostiles) placée avant l'étape 4 pour ne pas toucher le golden du mode `unique` ; l'étape 4 reçoit une seule ligne d'aiguillage déclarée (filtrée par le test du golden), comme l'étape 3 en 006-03.
- 2026-11-24 : reports de la revue 006-03 fermés : 3 bis renvoie à 3 ter (plus de saut à l'étape 5), l'étape 4 dit qu'elle décrit le mode `unique`, un relecteur abaissé est relancé (CA-20, CA-42) ; « verdict retenu » remplace « dernier verdict connu » ; motif d'unanimité ancré en début de ligne et sur la règle entière.
- 2026-11-24 : CA-42 : les fixtures calculent le verdict retenu avec `verdict-revue.sh` plus la lecture des titres de gravité de `## Constats` ; le suivi de la skill par un agent n'est pas exécutable en test, la règle est donc aussi ancrée en texte exact avec mutations.
- 2026-11-24 : le test `ca21_deliver_l_etape_3_bis_renvoie_a_l_etape_3_ter…` était déjà vert au RED (le renvoi a été posé avec le commit du slice 1) ; les tests `cs08_verdict_revue_sh_…` couvrent un comportement existant (vérifié par CS-08 du PRD).
