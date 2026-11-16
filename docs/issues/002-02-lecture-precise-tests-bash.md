---
id: 002-02
titre: Lecture précise des tests bash
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: À faire
depend_de: [002-01]
criteres: [CA-05, CA-06, CA-07]
branche:
commits: []
revue:
---

## Objectif
Le contrôle ne se laisse pas tromper par un appel qui n'est pas un vrai test (identifiant ailleurs que dans le premier argument, appel en milieu de ligne, ligne dans un document ici) et accepte les écritures usuelles d'un même identifiant sans confondre deux critères voisins.

## Périmètre
- Dans : l'identifiant cité ailleurs que dans le premier argument, dans un commentaire final ou dans un appel en milieu de ligne, ignoré ; les quatre formes de document ici (`<<'EOF'`, `<<EOF`, `<<"EOF"`, `<<-EOF` à délimiteur indenté par tabulation), ignorées, et un appel identique hors document ici reconnu ; les écritures `CA-10`, `ca10`, `ca_10`, `CA 10`, `Ca010` sans casse, et l'absence de confusion entre `ca1` et `ca100`.
- Hors : la reconnaissance de base (issue 002-01), la configuration (issues 002-03 et 002-04), la documentation (issue 002-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca05_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit, avec la sortie de `factory/scripts/tests/run.sh` avant et après.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
