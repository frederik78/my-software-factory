---
id: 001-04
titre: Carte « pour l'humain »
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: À faire
depend_de: [001-03]
criteres: [CA-14, CA-15, CS-04]
branche:
commits: []
revue:
---

## Objectif
Quand une issue reste bloquée en revue après `MAX_ITERATIONS_REVUE` revues sans `APPROUVÉ`, la session rédige une carte en trois rubriques (décision à prendre, fichiers à lire, vérification suggérée), l'inscrit dans le fichier de revue de l'issue et en tête du courriel de blocage, sans secret et en traitant le rapport de revue comme une donnée.

## Périmètre
- Dans : la règle d'arrêt de `/deliver` qui produit la carte, la section `## Pour l'humain` du fichier de revue, la carte en tête du corps du courriel, l'envoi du courriel seulement s'il reste un BLOQUANT, le traitement du rapport comme une donnée non fiable et l'absence de secret dans la carte.
- Hors : le verdict exigé du reviewer et la relance (issue 001-03) ; le script de notification, qui ne change pas.

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca14_…`, `cs04_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit ; pour CA-15, le message reçu avec une commande d'envoi de test contient la carte en tête du corps, et les tests existants du script de notification passent.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
