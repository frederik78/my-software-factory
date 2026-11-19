---
id: 006-02
titre: Trois prompts de relecteurs, brief commun et section du rapport d'un relecteur
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: En cours
depend_de: []
criteres: [CA-05, CA-06, CA-07, CA-08, CA-09, CA-10, CS-03, CS-06]
branche: feat/006-02-prompts-relecteurs-et-brief
commits: []
revue:
---

## Objectif
Les trois relecteurs (conformité et tests, qualité, sécurité) ont chacun leur prompt, leur périmètre et leur brief, sans droit d'écriture.

## Périmètre
- Dans : Prompts `code-reviewer-conformite`, `code-reviewer-qualite`, `code-reviewer-securite`, brief commun, section du rapport d'un relecteur dans `report-format.md` ; `code-reviewer.md` et `briefs/reviewer.md` inchangés (mode `unique`).
- Hors : la configuration (006-01), l'orchestration de la skill `deliver` (006-03).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-02` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-19 : brief commun nommé `factory/prompts/briefs/relecteurs.md` (nom non fixé par le PRD) ; `code-reviewer.md` et `briefs/reviewer.md` contrôlés octet pour octet par empreinte SHA-256 dans `run.sh`.
- 2026-11-19 : section « Rapport d'un relecteur (revue parallèle) » ajoutée en fin de `report-format.md` (le reste du fichier, dont la section du reviewer, est inchangé, contrôlé par empreinte) ; limite 80 lignes écrite dans cette section, pas dans les règles générales.
- 2026-11-19 : conformité et qualité disent aussi qu'une vulnérabilité OWASP avérée aperçue est BLOQUANTE (CS-06 vise les trois prompts) ; seule la sécurité parcourt A01 à A10.
- 2026-11-19 : suite `run.sh` 1686 -> 1780 vérifications (+94) ; RED constaté avant les prompts (39 échecs sur 81 nouveaux cas, les autres sont des gardes d'absence ou d'inchangé).
