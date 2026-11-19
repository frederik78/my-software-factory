---
id: 010-03
titre: Écriture par la session à la clôture (critère de récurrence
prd: docs/prd/010-constats-recurrents.md
besoin: F-13
statut: À faire
depend_de: [010-01, 010-02]
criteres: [CA-11, CA-12, CA-13, CA-14, CA-16, CA-17, CA-18, CA-19, CA-20, CS-04]
branche: feat/010-03-ecriture-par-la-session-a-la-cloture-critere-de
commits: []
revue:
---

## Objectif
Écriture par la session à la clôture (critère de récurrence, doublons, borne, neutralisation), documentation, version, non-régression, tests regroupés.

## Périmètre
- Dans : Écriture par la session à la clôture (critère de récurrence, doublons, borne, neutralisation), documentation, version, non-régression, tests regroupés.
- Hors : les autres issues du PRD 010 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 010-03` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
