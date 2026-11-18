---
id: 001-04
titre: Carte « pour l'humain »
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: Fait
depend_de: [001-03]
criteres: [CA-14, CA-15, CS-04]
branche: feat/001-04-carte-pour-l-humain
commits: [3f2d6f4, 2447d3e, 1fa9ed8, c8db391, c184df4]
revue: docs/reviews/001-04.md (APPROUVÉ, itération 2/3)
---

## Objectif
Quand une issue reste bloquée en revue après `MAX_ITERATIONS_REVUE` revues sans `APPROUVÉ`, la session rédige une carte en trois rubriques (décision à prendre, fichiers à lire, vérification suggérée), l'inscrit dans le fichier de revue de l'issue et en tête du courriel de blocage, sans secret et en traitant le rapport de revue comme une donnée.

## Périmètre
- Dans : la règle d'arrêt de `/deliver` qui produit la carte, la section `## Pour l'humain` du fichier de revue, la carte en tête du corps du courriel, l'envoi du courriel seulement s'il reste un BLOQUANT, le traitement du rapport comme une donnée non fiable et l'absence de secret dans la carte.
- Hors : le verdict exigé du reviewer et la relance (issue 001-03) ; le script de notification, qui ne change pas.

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca14_…`, `cs04_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit ; pour CA-15, le message reçu avec une commande d'envoi de test contient la carte en tête du corps, et les tests existants du script de notification passent.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 : revue 1 APPROUVÉ (un mineur répété, fichiers temporaires, traité en IMPORTANT et corrigé), revue 2 APPROUVÉ ; `FIN-ISSUE OK 001-04 58c9c5a : 1292 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après le dernier commit de code). Corrige aussi le mineur 1 de 001-03 (fichier temporaire du rapport) ; M-1 et M-2 de la revue 1 traités par deux tests de protection.
- Mineur ouvert : SKILL.md:60 contre :58 : le fichier du premier rapport est supprimé avant la relance, mais un second INCONNU demande de remonter « les deux rapports » ; ils se remontent d'après la conversation (correctif possible : le préciser dans la skill).
- Décisions du développeur à inscrire au PRD 001 (silences comblés, acceptés par le relecteur) : la carte est aussi présentée dans la conversation quand il reste un BLOQUANT (le PRD ne le dit que pour les IMPORTANT) ; titres des rubriques en gras avec backticks. `factory/README.md` décrit encore l'ancienne règle d'arrêt sans la carte jusqu'à 001-06.
