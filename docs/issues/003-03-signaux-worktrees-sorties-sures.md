---
id: 003-03
titre: Signaux de worktree et sorties sûres pour une branche déduite
prd: docs/prd/003-dashboard-a-jour.md
besoin: F-08
statut: En revue
depend_de: [003-02]
criteres: [CA-21, CA-22, CS-01, CS-02, CS-04]
branche: feat/003-03-signaux-worktrees-sorties-sures
commits: []
revue:
---

## Objectif
Les signaux Git d'un worktree et l'encart « Autres travaux » suivent la branche retenue, y compris déduite ; un nom de branche hostile n'est jamais exécuté et toujours échappé ; la génération ne modifie rien dans le dépôt.

## Périmètre
- Dans : signaux de worktree sur l'issue d'une branche déduite, « Autres travaux » (une branche déduite n'y figure plus, une branche ambiguë y reste), échappement HTML des noms de branche, absence d'exécution de commande, lecture seule du dépôt.
- Hors : la règle de rattachement (003-01), le statut effectif (003-02).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère (noms de branche hostiles, comparaison avant / après des refs, de l'index et de l'arbre) qui échoue puis réussit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-17 : développeur : `FIN-ISSUE OK 003-03 57db718 : 919 tests, 0 échec, 0 ignoré` (906 avant, +13). CA-21 et CA-22 : RED constaté (2 échecs sur 4) ; CS-01, CS-02, CS-04 déjà vrais avec le code existant (pas de RED naturel), utilité prouvée par 4 mutations détectées par le développeur.
- Choix du développeur : colonne « branche déclarée » gardée dans `issues_dossier` (non lue par les signaux) ; une branche déclarée mais inexistante ou invalide n'est pas « retenue » (sans signal, sans exclusion de « Autres travaux »).
- Conflit possible à la fusion avec 003-04 : `dashboard.sh` (`carte_issue`, `encart_en_cours`, `encart_autres_travaux`, en-tête l.16-18) et fin de `run.sh`.
