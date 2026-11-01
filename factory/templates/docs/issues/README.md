# Issues

Une issue = un fichier `docs/issues/<prd>-<nn>-<slug>.md` : une tranche verticale livrable seule, issue du découpage d'un PRD
(skill `to-tickets`). `<prd>` est le numéro du PRD, `<nn>` le rang de l'issue. Le PRD décrit le comportement attendu ; l'issue porte le **suivi**
(statut, dépendances, branche, commits, revue). Modèle : `_template.md`. La skill `deliver` lit et met à jour ces fichiers.

## Format
En-tête YAML : `id`, `titre`, `prd`, `besoin`, `statut` (`À faire` -> `En cours` -> `En revue` -> `Fait`), `depend_de` (ids d'issues qui doivent être
`Fait`), `criteres` (CA-xx / CS-xx du PRD), `branche` (`feat/<prd>-<nn>-<slug>`), `commits`, `revue` (`docs/reviews/<id>.md`).
Corps : Objectif, Périmètre (dans / hors), Critères d'acceptation (renvoi au PRD, sans les recopier), Notes (décisions et écarts datés).

## Règles
- `Fait` seulement si la définition de fini de la skill `deliver` est remplie (build vert en copie propre, critères couverts par des tests nommés,
  revue `APPROUVÉ`, commits atomiques).
- Les identifiants CA/CS restent ceux du PRD (source de vérité) ; un numéro n'est jamais réutilisé.
- Le statut d'un besoin du backlog passe `Fait` seulement quand TOUTES ses issues le sont.
- Une issue ne décrit pas la structure des packages (c'est `AGENTS.md` et les ADR).

## État
Pas d'index à tenir à la main (il dériverait) : l'état se lit dans les en-têtes avec `scripts/etat-issues.sh` (tableau Markdown ; `--statut "À faire"`
pour filtrer ; `--prochaine` donne la première issue prête, dépendances `Fait`). `scripts/couverture-prd.sh <prd>` vérifie que chaque critère du PRD est
couvert par exactement une issue ; `scripts/criteres-sans-test.sh <issue>` que chaque critère d'une issue a un test. `scripts/dashboard.sh` écrit une page HTML (`dashboard.html`, non versionnée) de l'état des besoins et des issues.
