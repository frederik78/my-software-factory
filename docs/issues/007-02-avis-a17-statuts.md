---
id: 007-02
titre: Avis A17 de statuts.sh : issue démarrée sans champ branche
prd: docs/prd/007-champ-branche-renseigne.md
besoin: F-06
statut: En revue
depend_de: [007-01]
criteres: [CA-06, CA-07, CA-08, CA-09, CA-10, CA-11, CA-12, CA-13, CA-14, CS-01, CS-02, CS-03]
criteres_justification: Douze critères sur un seul script (statuts.sh) et un seul avis (A17) : condition, formes de champ vide, cas hostiles, coût et dashboard se testent sur les mêmes dépôts jetables ; les séparer ferait tester deux fois la même condition dans deux issues.
branche: feat/007-02-avis-a17-statuts
commits: [c1bc766, 1caf38e, 0b29ebb, b9b436f, ab9c624]
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
- 2026-11-24 : écart de la mesure CA-14 : à champs remplis (branche déclarée absente) statuts.sh fait 2 appels Git de plus par issue (résolution de la branche déclarée, coût existant, étranger à A17) ; la comparaison « champ vide / champ rempli » n'est donc pas à iso-situation. Le test compare à la référence mesurée avant l'avis (1 appel pour 3, 12 et 50 issues En cours à champ vide) et exige 50 A17 pour 50 champs vides.
- 2026-11-24 : CA-13, cas réécrits (seules les lignes A17 ajoutées, récapitulatif compris) : ca16_branche (3 cas : 004-71/74/76, 004-71 hostile, 004-60), ca31_dashboard (2 cas : 004-73), ca38_statuts (004-91 Relue), référence tests/golden/ca41-sorties.txt (001-02, 001-06, 004-73 ; diff = 12 lignes ajoutées ou récapitulatifs, aucune autre).
- 2026-11-24 : le seuil lit la table par le rang (`statut_depuis` « En cours » puis « Fait ») sans modifier `statut_en_travail` (A08 inchangé) ; un statut ajouté après Fait ne donne pas A17.
- 2026-11-24 : l'échec ca19 « docs/reviews/README.md identique à son modèle » existait déjà sur develop (avant ce travail) ; docs/reviews/README.md est réaligné sur son modèle par un commit docs: distinct (ab9c624) pour obtenir FIN-ISSUE OK.
- FIN-ISSUE OK 007-02 ab9c624 : 2383 tests, 0 échec, 0 ignoré.
