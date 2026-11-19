---
id: 004-04
titre: Lecture seule, coût mesuré et fichiers hostiles
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: En revue
depend_de: [004-03]
criteres: [CA-28, CA-29, CA-30, CS-01, CS-02, CS-03, CS-04]
branche: feat/004-04-lecture-seule-cout-hostiles
commits: []
revue:
---

## Objectif
Le contrôle ne modifie jamais le dépôt (arbre, index, refs, `backlog.md`, issues), reste dans le plafond d'appels Git du PRD, et traite les fichiers absents, illisibles ou hostiles (valeurs forgées dans les en-têtes et le backlog) sans rien évaluer, avec une sortie neutralisée.

## Périmètre
- Dans : lecture seule vérifiable avant / après, plafond d'appels Git (compteur dans un test), fichiers absents ou illisibles, valeurs hostiles, neutralisation de la sortie (caractères de contrôle).
- Hors : règles de cohérence (004-02, 004-03), dashboard (échappement HTML, 004-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère (comparaison de l'arbre, de l'index et des refs avant / après ; comptage d'appels Git ; valeurs hostiles) qui échoue puis réussit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
