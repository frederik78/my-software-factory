---
id: 006-03
titre: Skill deliver : lancement ensemble, verdicts et format du fichier de revue
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: Fait
depend_de: [006-01, 006-02]
criteres: [CA-11, CA-12, CA-13, CA-14, CA-15, CA-16, CA-17, CS-04, CS-07]
branche: feat/006-03-deliver-lancement-et-verdicts
commits: [989f50a, 33e54fe, 93ece6a]
revue: APPROUVÉ (itération 3, docs/reviews/006-03.md)
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
- 2026-11-19 : choix du développeur (à trancher par l'utilisateur) : un `VERDICT: APPROUVÉ` d'un relecteur dont le rapport contient un constat BLOQUANT ou IMPORTANT ouvert est consigné `CHANGEMENTS DEMANDÉS` en verdict global (la session prime), alors que `Verdict du relecteur` garde la valeur du script ; le PRD ne le prévoit pas (RG-09), choix le plus sûr.
- 2026-11-19 : la skill ajoute une étape « 3 bis » (mode parallèle) entre les étapes 3 et 4 ; l'étape 3 n'est pas réécrite (chaque ligne d'avant le besoin est gardée, fixture `golden/ca12-deliver-etapes-3-4-unique.txt`). Les itérations suivantes, le tour final, le suivi fusionné et l'arrêt du mode parallèle restent à 006-04.
- 2026-11-19 : CA-12 « octet pour octet » est vérifié par la conservation de chaque ligne des étapes 3 et 4 du mode `unique` et les empreintes de `code-reviewer.md` et `briefs/reviewer.md`, pas par l'exécution de la skill (impossible en test).
- FIN-ISSUE OK 006-03 79bf689 : 2005 tests, 0 échec, 0 ignoré (revue 3 APPROUVÉ).
