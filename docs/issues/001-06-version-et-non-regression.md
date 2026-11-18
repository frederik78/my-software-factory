---
id: 001-06
titre: Version 1.23.0 et non-régression
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: En revue
depend_de: [001-02, 001-03, 001-04, 001-05]
criteres: [CA-17, CA-18]
branche: feat/001-06-version-et-non-regression
commits: []
revue:
---

## Objectif
La factory passe en version 1.23.0 (D-27 : 1.22.0 est prise par F-08) : le CHANGELOG décrit le changement et la migration (« remplacer `factory/` »), le guide d'utilisation décrit la commande de lecture du verdict, la carte et la liste d'escalade, et rien d'autre n'a changé : `fin-issue.sh`, le dashboard et les revues existantes sont identiques à la version 1.21.0.

## Périmètre
- Dans : le fichier de version, le CHANGELOG, le guide `factory/README.md`, la vérification que `fin-issue.sh`, le dashboard, leurs tests et les revues de `docs/reviews/` sont inchangés.
- Hors : tout le contenu fonctionnel (issues 001-01 à 001-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca17_…`, `ca18_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit ; pour CA-17, une comparaison à la version 1.21.0 montrant l'absence de différence, avec la commande qui la produit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
