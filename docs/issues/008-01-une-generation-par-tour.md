---
id: 008-01
titre: Boucle du dashboard : une génération par tour depuis le disque
prd: docs/prd/008-boucle-dashboard-code-a-jour.md
besoin: F-11
statut: En revue
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-06, CS-01, CS-02]
branche: feat/008-01-une-generation-par-tour
commits: []
revue: APPROUVÉ (itération 1, docs/reviews/008-01.md)
---

## Objectif
Une génération par tour relancée du disque, options fixées, validation au lancement, mode une génération inchangé, arguments et script relancé non interprétés.

## Périmètre
- Dans : Une génération par tour relancée du disque, options fixées, validation au lancement, mode une génération inchangé, arguments et script relancé non interprétés.
- Hors : les autres issues du PRD 008 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 008-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-19 : RED constaté (cf353d9) : 13 cas en échec sur 21 (ca01 à ca04, cs01, cs02) ; ca05 et ca06 passaient déjà (comportement existant conservé).
- 2026-11-19 : test corrigé (34acc30) : `test "$(b8_generations)"` était évalué une seule fois avant le sondage (toujours 0) ; remplacé par `b8_au_moins`, évalué à chaque essai.
- 2026-11-19 : la boucle relance `$dossier_scripts/$(basename $0)` (chemin absolu fixé au démarrage) avec `--sortie`, `--attente` et `--theme` résolus au démarrage, sortie standard de la génération écartée (RG-01 à RG-03) ; le traitement d'une génération en erreur reste celui de l'issue 008-02 
