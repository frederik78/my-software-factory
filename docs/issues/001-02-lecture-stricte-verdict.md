---
id: 001-02
titre: Lecture stricte du verdict
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: En cours
depend_de: [001-01]
criteres: [CA-06, CA-07, CA-08, CA-09, CA-10, CA-19]
branche: feat/001-02-lecture-stricte-verdict
commits: []
revue:
---

## Objectif
La commande de lecture du verdict refuse toute ambiguïté (ligne en double, ligne qui n'est pas la première, valeur inconnue), tolère la casse, les espaces de bord et les fins de ligne CRLF, et considère la première ligne comme seule référence. Ses tests figurent dans les tests de la factory.

## Périmètre
- Dans : doublon, ligne mal placée, casse et espaces tolérés avec accents exigés, valeurs inconnues ou vides, divergence avec la section `## Verdict` (la première ligne fait foi), présence dans les tests de la factory des tests de CA-01 à CA-11 sans régression.
- Hors : les cas nominaux, l'usage et la sécurité du script (issue 001-01), l'appel depuis `/deliver` (issue 001-03).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca06_…`, `ca19_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit, et la sortie de `factory/scripts/tests/run.sh` montrant les tests de CA-01 à CA-11 et l'absence de régression.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
