---
id: 001-02
titre: Lecture stricte du verdict
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: Fait
depend_de: [001-01]
criteres: [CA-06, CA-07, CA-08, CA-09, CA-10, CA-19]
branche: feat/001-02-lecture-stricte-verdict
commits: [575a5ed]
revue: docs/reviews/001-02.md (APPROUVÉ, itération 1/3)
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
- 2026-11-18 : revue 1 APPROUVÉ sans constat bloquant ni important ; `FIN-ISSUE OK 001-02 61afb09 : 1188 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après le dernier commit de code). Mutations : 20 lancées par le développeur (toutes tuées) ; le relecteur n'a pas pu en lancer (copie jetable refusée par le système).
- Mineurs ouverts : (1) une ligne commençant par un NUL ou contenant un `\r` interne n'est pas comptée comme doublon (verdict-revue.sh:50), risque faible ; (2) le fichier est lu trois fois (course hors modèle de menace).
- Décisions en attente de l'utilisateur (à inscrire au PRD 001, silences du PRD comblés dans le sens de l'échec sûr) : (1) première ligne limitée à 200 octets ; (2) fichier limité à 1 Mio ; (3) séparateurs tolérés = espaces et tabulations (pas d'insécables, pas d'espaces internes multiples) ; (4) un `\r` interne donne INCONNU, seul un `\r` final est toléré. Recommandation : accepter (acceptés par l'utilisateur le 2026-11-18 « j'accepte ta recommandation »). (5) un doublon `VERDICT:` est refusé même indenté ou cité dans un bloc de code (un rapport qui cite `VERDICT:` en début de ligne donne INCONNU puis la relance de RG-07) : recommandation accepter, réponse de l'utilisateur à confirmer.
