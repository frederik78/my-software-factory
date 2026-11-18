---
id: 004-05
titre: Dashboard, /deliver, documentation, version et tests réunis
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: À faire
depend_de: [004-04]
criteres: [CA-31, CA-32, CA-33, CA-34, CA-35, CA-36, CA-37, CS-05, CS-06]
branche: feat/004-05-dashboard-deliver-documentation-version
commits: []
revue:
---

## Objectif
Le dashboard affiche le résultat du contrôle (échappé), `/deliver` le lance à chaque changement de statut, la documentation et la version (la suivante libre) sont à jour, tous les cas de F-09 figurent dans les tests de la factory sans régression.

## Périmètre
- Dans : section de contrôle du dashboard et échappement, appel par `/deliver`, documentation, version, CHANGELOG et migration « remplacer `factory/` », tests regroupés, non-régression, proposition d'ajouter `Abandonnée` à la ligne « Statuts » de `backlog.md` (à l'utilisateur).
- Hors : le contrôle lui-même (004-01 à 004-04), le retrait des anciennes listes et règles (004-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit ; suite entière verte ; page du dashboard avant / après sur les fixtures.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 (consigne de l'orchestrateur, à intégrer à la documentation de cette issue) : dans `factory/skills/deliver/SKILL.md` et `AGENTS.md` (Orchestration, clôture), après chaque fusion demandée par l'utilisateur, lancer `scripts/statuts.sh` et passer à `Fait` dans `backlog.md` (branche `docs/`, sans fusionner) tout besoin signalé « en retard : toutes les issues sont Fait et fusionnées dans develop (attendu : Fait) » ; demandé par l'utilisateur le 2026-11-18. Tester la phrase comme les autres textes de la skill.
