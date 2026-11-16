---
id: 001-05
titre: Liste d'escalade
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: À faire
depend_de: []
criteres: [CA-16]
branche:
commits: []
revue:
---

## Objectif
Les consignes de tous les agents énumèrent les six sujets qu'ils doivent remonter à l'utilisateur sans trancher seuls (secrets et identifiants, authentification et autorisation, dépendance et licence, déploiement et CI, contrat d'un service externe, écart avec le PRD), avec la consigne de s'arrêter et de les ranger dans `## QUESTIONS` ou `## À trancher par l'utilisateur`.

## Périmètre
- Dans : la liste, la consigne d'arrêt et les deux destinations, à l'identique dans le modèle d'`AGENTS.md` fourni aux nouveaux projets et dans `AGENTS.md` de ce dépôt.
- Hors : la version, le CHANGELOG et la mention dans le guide d'utilisation (issue 001-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca16_…`).

## Preuve attendue
Un test de lecture des deux fichiers qui échoue avant la modification puis réussit après, avec la commande qui le produit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
