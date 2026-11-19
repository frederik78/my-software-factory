---
id: 006-06
titre: Fichier de revue de branche écrit par la session
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: À faire
depend_de: [006-05]
criteres: [CA-39, CA-40, CA-41, CS-11, CS-12]
branche: feat/006-06-fichier-revue-de-branche
commits: []
revue:
---

## Objectif
En mode `parallele`, `/code-review` consigne un fichier `docs/reviews/branche-<branche>.md` au format consolidé, lisible par les outils existants.

## Périmètre
- Dans : Nom assaini à partir de la branche, écriture par la session seule, format consolidé, lecture par `verdict-revue.sh` et `statuts.sh`, noms et cibles hostiles (liens symboliques, collisions).
- Hors : l'agrégation des relecteurs (006-05), la documentation (006-07).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-06` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
