---
id: 003-01
titre: Rattachement d'une issue à sa branche par convention
prd: docs/prd/003-dashboard-a-jour.md
besoin: F-08
statut: En cours
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-06, CA-07, CA-08, CA-09, CS-03, CS-05]
criteres_justification: Plus de 10 critères : ils portent tous sur une seule règle (le rattachement), et la scinder ferait couvrir un même cas par deux issues.
branche: feat/003-01-rattachement-branche-convention
commits: []
revue:
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
