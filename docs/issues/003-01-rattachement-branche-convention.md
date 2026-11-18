---
id: 003-01
titre: Rattachement d'une issue à sa branche par convention
prd: docs/prd/003-dashboard-a-jour.md
besoin: F-08
statut: Fait
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-06, CA-07, CA-08, CA-09, CS-03, CS-05]
criteres_justification: Plus de 10 critères : ils portent tous sur une seule règle (le rattachement), et la scinder ferait couvrir un même cas par deux issues.
branche: feat/003-01-rattachement-branche-convention
commits: [ee55706]
revue: docs/reviews/003-01.md (APPROUVÉ, itération 1/3)
---

## Objectif
Quand le champ `branche:` d'une issue est vide, le dashboard retrouve sa branche locale par le nom `<type>/<id>-…` ; le champ rempli l'emporte ; deux branches possibles ou un identifiant partagé ne donnent aucune branche retenue.

## Périmètre
- Dans : la règle de rattachement (déduction, ambiguïté, identifiant le plus long, identifiant partagé, bornes de nom, noms invalides ou hostiles) pour le dashboard et la colonne Branche de `etat-issues.sh` ; la mention « (déduite) » et « branche ambiguë : … » sur les cartes.
- Hors : le statut effectif et les dépendances (003-02), l'avancement des besoins (003-04), les signaux de worktree (003-03), le coût mesuré et la documentation (003-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère, écrit sur des dépôts Git jetables, qui échoue (branche non déduite) puis réussit ; nombre de vérifications de `run.sh` avant / après.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-17 : développeur interrompu puis repris ; livré en un commit `ee55706`, `FIN-ISSUE OK 003-01 ee55706 : 882 tests, 0 échec, 0 ignoré` (858 avant, +24).
- Décision en attente de l'utilisateur (hors PRD, à inscrire au PRD) : si l'identifiant le plus long d'une branche est partagé par deux issues, ou si l'issue qui le porte a un `branche:` rempli, la branche n'est déduite pour personne, pas même pour l'issue au préfixe plus court (choix le plus sûr, recommandation : le garder).
- À traiter en 003-05 (non bloquant ici) : `dashboard.sh` lance `etat-issues.sh --prochaine` dans un autre processus, donc deux listages de branches par génération au lieu d'un (RG-21, CA-23) ; unifier le chargement.
- À traiter en 003-03 : signaux de worktree et « Autres travaux » lisent encore le champ `branche:` déclaré.
- Note : `mapfile` dans `kanban` (code existant) n'est pas compatible bash 3.2 ; non touché, hors périmètre.
- 2026-11-17 : revue 1 APPROUVÉ sans constat bloquant ni important ; `FIN-ISSUE OK 003-01 79185e7 : 882 tests, 0 échec, 0 ignoré` (relancé par l'orchestrateur après le dernier commit de code).
- Mineurs ouverts : 3 garde-fous non mutés par la revue (type non vide ; priorité du champ rempli dans le rattachement ; mention « (déduite) » de `etat-issues.sh`) ; le tableau de `etat-issues.sh` recopie le nom de branche brut dans son texte de terminal, comme le champ déclaré avant (échappement HTML complet : 003-03).
