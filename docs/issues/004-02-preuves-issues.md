---
id: 004-02
titre: Preuves d'une issue, branche retenue, Abandonnée et dépendances
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: En cours
depend_de: [004-01]
criteres: [CA-10, CA-11, CA-12, CA-13, CA-14, CA-15, CA-16, CA-17, CA-18]
branche: feat/004-02-preuves-issues
commits: []
revue:
---

## Objectif
Le contrôle vérifie qu'une issue est cohérente avec ses preuves (revue approuvée, FIN-ISSUE OK, commits pour `Fait` ; revue pour `En revue`), sur le statut effectif de sa branche, gère `Abandonnée` (raison écrite) et signale les dépendances incohérentes, avec les messages d'erreur et d'avis du catalogue.

## Périmètre
- Dans : preuves des statuts `Fait` et `En revue`, branche retenue (PRD 003), `Abandonnée` et sa raison, dépendances (dont dépendance `Abandonnée` non levée, avis), avis pour les issues déjà `Fait` avant F-09.
- Hors : cohérence des besoins (004-03), lecture seule, coût, fichiers hostiles (004-04), dashboard et documentation (004-05), nettoyage (004-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue (incohérence non signalée) puis réussit ; messages à égalité exacte avec le catalogue.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
