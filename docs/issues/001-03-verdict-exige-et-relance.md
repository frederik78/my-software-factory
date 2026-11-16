---
id: 001-03
titre: Verdict exigé du reviewer et relance
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: À faire
depend_de: [001-02]
criteres: [CA-12, CA-13]
branche:
commits: []
revue:
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
