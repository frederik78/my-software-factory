---
id: 006-08
titre: Rôles propres à Claude Code hors des prompts (roles.conf)
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: En revue
depend_de: [006-01, 006-02, 006-03]
criteres: [CA-03, CA-05, CA-12, CA-43, CA-44, CA-45, CA-46, CA-47, CA-48, CA-49, CS-02]
criteres_justification: bascule atomique (D-60) : en-têtes réduits, factory/claude/roles.conf créé et sync-claude.sh modifié dans un même état, sinon les enveloppes changent
branche: refactor/006-08-roles-claude-hors-prompts
commits: []
revue:
---

## Objectif
Les prompts de `factory/prompts/` ne portent plus que `name`, `description` et `skills` ; les outils, le modèle et l'effort de chaque rôle vivent dans `factory/claude/roles.conf`, lu seulement par `factory/sync-claude.sh` (D-60). Les enveloppes générées restent identiques, hors leur ligne de commentaire.

## Périmètre
- Dans : `factory/claude/roles.conf`, en-têtes des prompts, `factory/sync-claude.sh` (lecture, précédence, cohérence, lecture seule des relecteurs, validation), tests dans `factory/scripts/tests/run.sh`.
- Hors : documentation, CHANGELOG et note de migration (006-07, CA-50 et CA-29).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, enveloppes de référence comparées avant / après, `scripts/criteres-sans-test.sh 006-08` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
