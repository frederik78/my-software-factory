---
id: 006-05
titre: Skill code-review : lecture du mode, trois relecteurs et agrégation
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: En revue
depend_de: [006-02, 006-03]
criteres: [CA-34, CA-35, CA-36, CA-37, CA-38, CS-09, CS-10]
branche: feat/006-05-code-review-lancement-et-agregation
commits: [61288e9, 1a7712a, 17279ac, 7af8b99, 65e1289]
revue:
---

## Objectif
`/code-review` suit `MODE_REVUE` : en `unique` il est inchangé et n'écrit aucun fichier ; en `parallele` il lance les trois relecteurs et agrège leurs verdicts.

## Périmètre
- Dans : Skill `code-review` : lecture du mode, `unique` inchangé, trois relecteurs, agrégation, itérations, point fixe hostile.
- Hors : le fichier de revue de branche (006-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-05` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-24 `scripts/fin-issue.sh 006-05` : `FIN-ISSUE OK 006-05 f02147c : 2462 tests, 0 échec, 0 ignoré`.
- 2026-11-24 Décision : le mode `unique` est gardé par un golden (`factory/scripts/tests/golden/ca34-code-review-unique.txt`, la skill d'avant) ; la skill privée de l'étape 1 bis et de la section « Mode parallèle » (seuls ajouts) lui est identique, ligne à ligne et dans l'ordre.
- 2026-11-24 Décision : le contrôle du point fixe est une fonction bash (`controle_point_fixe`) écrite dans la skill et rejouée telle quelle par les tests sur un dépôt jetable (forme en liste blanche, 200 caractères au plus, référence commit, différence non vide, messages fixes sans la valeur brute, code 64). S'applique aux deux modes (ajout, aucune ligne existante modifiée).
- 2026-11-24 Écart : « le chemin du fichier de revue de branche » de la ligne de synthèse est cité sans que la skill l'écrive ; l'écriture et le format du fichier sont à 006-06 (hors périmètre).
- 2026-11-24 Reprise du commit 0e1d7f6 de 006-04 (cherry-pick f02147c) : `docs/reviews/README.md` différait de son modèle (échec préexistant sur develop, cassé depuis 006-03) et empêchait `FIN-ISSUE OK`.
- 2026-11-24 `AGENTS.md` et `factory/templates/AGENTS.md` (étape 5) : phrase ajoutée sur le mode parallèle (CA-38).
