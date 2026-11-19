---
id: 007-02
titre: Avis A17 de statuts.sh : issue démarrée sans champ branche
prd: docs/prd/007-champ-branche-renseigne.md
besoin: F-06
statut: À faire
depend_de: [007-01]
criteres: [CA-06, CA-07, CA-08, CA-09, CA-10, CA-11, CA-12, CA-13, CA-14, CS-01, CS-02, CS-03]
branche: feat/007-02-avis-a17-statuts
commits: []
revue:
---

## Objectif
`scripts/statuts.sh` signale en avis (jamais en erreur) une issue démarrée et non terminée dont `branche:` est vide.

## Périmètre
- Dans : Avis A17 : condition, formes de champ vide, statut effectif lu dans la table, indépendance d'A08, classement et dashboard, sorties de référence, coût Git inchangé et lecture seule, valeurs hostiles, bornes.
- Hors : le modèle et les README (007-01), la reprise, la documentation et la version (007-03).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 007-02` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
