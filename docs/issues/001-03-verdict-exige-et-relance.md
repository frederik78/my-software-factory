---
id: 001-03
titre: Verdict exigé du reviewer et relance
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: Fait
depend_de: [001-02]
criteres: [CA-12, CA-13]
branche: feat/001-03-verdict-exige-et-relance
commits: [9e7b104, fbfd76e, afc4c91]
revue: docs/reviews/001-03.md (APPROUVÉ, itération 1/3)
---

## Objectif
Le reviewer écrit en première ligne de son rapport `VERDICT: APPROUVÉ` ou `VERDICT: CHANGEMENTS DEMANDÉS`, la section `## Verdict` reprenant la même valeur ; après chaque revue, `/deliver` lit ce verdict avec la commande et relance une fois le reviewer si la réponse est `INCONNU`.

## Périmètre
- Dans : le format exigé dans le format de rapport commun et dans le prompt du reviewer ; l'appel de la commande par `/deliver` sur le rapport de l'itération avant son ajout au fichier de revue ; la relance unique hors compte de `MAX_ITERATIONS_REVUE`, puis l'arrêt avec remontée à l'utilisateur.
- Hors : la carte « pour l'humain » (issue 001-04), la lecture elle-même du verdict (issues 001-01 et 001-02).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca12_…`).

## Preuve attendue
Un test de lecture des documents concernés par critère, qui échoue avant la modification puis réussit après, avec la commande qui le produit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 : revue 1 APPROUVÉ sans constat bloquant ni important ; `FIN-ISSUE OK 001-03 aaab880 : 1271 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après le dernier commit de code).
- Mineurs ouverts : (1) le fichier temporaire du rapport n'est supprimé qu'après l'ajout au fichier de revue (SKILL.md:61) : « supprime les fichiers temporaires dans tous les cas » ; (2) le test ca13 « hors compte » (run.sh:2236) laisse passer « ne compte pas pour » ; (3) « rien au-dessus » de code-reviewer.md non testé ; (4) le gabarit de report-format.md:71 montre `VERDICT: APPROUVÉ|CHANGEMENTS DEMANDÉS` avec une barre verticale : un reviewer qui le recopie obtient INCONNU et une relance inutile (correctif rapide proposé : un exemple à valeur unique).
- Décisions du développeur à inscrire au PRD 001 (silences comblés, acceptés par le relecteur) : après une relance réussie, le rapport de la relance (et non le premier, invalide) est ajouté à docs/reviews/<id>.md ; au second INCONNU rien n'est ajouté, les deux rapports et le message du script sont remontés ; un code 64 du script est une erreur de la session, sans relance ; fichier temporaire par `mktemp`.
