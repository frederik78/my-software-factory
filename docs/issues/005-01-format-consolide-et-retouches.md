---
id: 005-01
titre: Format de revue consolidé et retouches de F-01
prd: docs/prd/005-format-revue-consolide.md
besoin: F-12
statut: À faire
depend_de: [004-05]
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-06, CA-07, CA-08, CA-17, CA-18, CS-06]
criteres_justification: Onze critères sur une seule règle (le format consolidé) et ses deux retouches de textes voisines ; les séparer ferait couvrir un même fichier de gabarit par deux issues.
branche:
commits: []
revue:
---

## Objectif
Un fichier de revue qui regroupe plusieurs itérations n'a qu'une seule ligne `VERDICT:`, en tête, mise à jour par la session ; les sections d'itération écrivent « Verdict de l'itération : … » ; les deux retouches de textes de F-01 sont faites.

## Périmètre
- Dans : la skill `deliver` (étape 3, numérotation des itérations), le modèle `factory/templates/docs/reviews/README.md`, le gabarit de `factory/prompts/report-format.md` (exemple à valeur unique), la précision « d'après la conversation » pour le premier rapport supprimé avant la relance, la lecture du verdict (`verdict-revue.sh` inchangé), la session seule écrivante, tests de texte et de lecture.
- Hors : l'avis A16 de `statuts.sh` (005-02), la documentation, la version et le CHANGELOG (005-03).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit ; pour la lecture, `verdict-revue.sh` rend `APPROUVÉ` sur un fichier consolidé de plusieurs itérations et `INCONNU` sur un doublon cité.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- Dépend de 004-05 : mêmes fichiers (`factory/skills/deliver/SKILL.md`, `AGENTS.md`), pour éviter les conflits (backlog : F-12 dépend de F-09).
