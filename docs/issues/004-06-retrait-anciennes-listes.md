---
id: 004-06
titre: Retrait des anciennes listes et règles de statut
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: En cours
depend_de: [004-01, 004-02, 004-03, 004-04, 004-05]
criteres: [CA-38, CA-39, CA-40, CA-41]
branche: feat/004-06-retrait-anciennes-listes
commits: []
revue:
---

## Objectif
Une fois le contrôle livré, le code mort qui énumère ou change les statuts disparaît : listes codées en dehors de la table unique, valeurs en dur, règles de transition répétées en prose, tests qui ne gardaient que l'ancienne duplication ; un garde-fou empêche leur retour, sans changement de comportement visible.

## Périmètre
- Dans : inventaire puis suppression des listes et valeurs de statut en dur, de la prose de transition (`AGENTS.md`, son modèle, skill `deliver`) remplacée par un renvoi à la table, des tests de duplication ; garde-fou par recherche d'absence ; comportement identique avant / après (dashboard, `etat-issues.sh`). Exceptions (`fin-issue.sh`, textes du catalogue, commentaires, données de test) justifiées une par une dans les Notes.
- Hors : tout nouveau comportement (issues 004-01 à 004-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Inventaire avant, recherche d'absence après (commande et sortie), dashboard et `etat-issues.sh` identiques avant / après sur les fixtures, suite verte.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
