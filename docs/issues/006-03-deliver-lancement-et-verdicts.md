---
id: 006-03
titre: Skill deliver : lancement ensemble, verdicts et format du fichier de revue
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: À faire
depend_de: [006-01, 006-02]
criteres: [CA-11, CA-12, CA-13, CA-14, CA-15, CA-16, CA-17, CS-04, CS-07]
branche: feat/006-03-deliver-lancement-et-verdicts
commits: []
revue:
---

## Objectif
`/deliver` lit le mode, lance les trois relecteurs ensemble, lit leurs verdicts et écrit le fichier de revue consolidé ; le mode `unique` reste identique.

## Périmètre
- Dans : Skill `deliver` : lecture du mode, `unique` inchangé, lancement ensemble, calcul du verdict global par `verdict-revue.sh`, `INCONNU` refait, format du fichier de revue, lecture par les scripts existants.
- Hors : le suivi et les itérations (006-04), `/code-review` (006-05 et 006-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-03` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
