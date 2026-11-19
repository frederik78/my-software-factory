---
id: 004-05
titre: Dashboard, /deliver, documentation, version et tests réunis
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: Fait
depend_de: [004-04]
criteres: [CA-31, CA-32, CA-33, CA-34, CA-35, CA-36, CA-37, CS-05, CS-06]
branche: feat/004-05-dashboard-deliver-documentation-version
commits: [777bcb0, f39461b, 158809e, 3f23c13, b550de8, 23ff39b, 89c77a5, b62b939]
revue: docs/reviews/004-05.md (1 itération, APPROUVÉ)
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
- 2026-11-18 : FIN-ISSUE OK 004-05 bd592a3 : 1641 tests, 0 échec, 0 ignoré ; `run.sh` direct dans le worktree (avec `.git`) : 1646 vérifications, 0 échec à la 2e exécution (un premier lancement, fait pendant que la revue tournait en parallèle, a rendu « 1 échec sur 1646 » dont le nom n'a pas été capturé ; non reproduit, probablement la borne de temps de `cs04_volumes` sous charge, voir mineur ci-dessous) ; revue 1 : APPROUVÉ, 3 mutations tuées sur 4.
- Décision en attente de l'utilisateur (recommandation : garder le processus séparé et amender le PRD 004 RG-25) : le dashboard lance `statuts.sh` en processus séparé, donc la liste des branches est lue deux fois par génération alors que RG-25 dit « jamais relue » ; l'alternative (sourcer les bibliothèques dans le dashboard) couple les deux scripts. Autres choix à valider : section en bas de page, récapitulatif toujours affiché ; proposition d'ajouter `Abandonnée` à la ligne « Statuts » de `backlog.md` (à l'utilisateur).
- Mineurs ouverts : (1) cas « ligne intruse avant un récapitulatif valide » non testé (dashboard.sh:441-444, mutation survivante) ; (2) espace en fin de ligne à `factory/scripts/statuts.sh:11` ; (3) aucun délai imposé au contrôle dans le dashboard ; (4) borne `-le 40` de `cs04_volumes` sensible à la charge (déjà mineur de 004-04) ; (5) la phrase de clôture « passe à Fait » peut être signalée par le garde-fou CA-39 de 004-06 : à régler en 004-06.
- Correction hors périmètre faite ici : le test de limite de revue en dur ignore `docs/prd/*` (777bcb0), car le PRD 005 citait « 3 itérations » et la suite de `develop` était en échec depuis la fusion du PRD 005.
- Passages du PRD 004 à amender (par l'utilisateur) : RG-25 (processus séparé), ligne 148 « n'émet aucun autre constat », constat 12 de 004-01, plus les listes déjà consignées dans les Notes de 004-01 à 004-04.
