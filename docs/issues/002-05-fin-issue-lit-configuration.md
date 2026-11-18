---
id: 002-05
titre: fin-issue.sh lit la configuration
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: Fait
depend_de: [002-04]
criteres: [CA-19, CA-20, CA-21, CA-25]
branche: feat/002-05-fin-issue-lit-configuration
commits: [def6ed6, 95805ba]
revue: APPROUVÉ (itération 1 sur 3, docs/reviews/002-05.md)
---

## Objectif
Le contrôle de fin d'issue applique la configuration du dépôt à l'extraction de `HEAD` où il vérifie les critères : une issue dont chaque critère a son cas bash obtient `FIN-ISSUE OK`, et ce dépôt règle son dossier de tests. Une fois cette issue livrée, l'issue 001-01 peut être clôturée.

## Périmètre
- Dans : l'extraction de `HEAD` reçoit la lecture de configuration et utilise le `.factory.conf` du commit ; le `.factory.local.conf` non versionné y est ignoré ; le refus de `DOSSIER_TESTS` absolu ou contenant `..` pour les quatre sources (variable, `FACTORY_DOSSIER_TESTS`, `.factory.local.conf`, `.factory.conf`) ; le réglage de ce dépôt (`DOSSIER_TESTS=factory/scripts/tests` dans `.factory.conf`) et le contrôle d'une issue de ce dépôt dont les critères ont leurs cas bash.
- Hors : la reconnaissance et la configuration elles-mêmes (issues 002-01 à 002-04), la documentation et la version (issue 002-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca19_…`, `ca25_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit, avec la sortie de `factory/scripts/tests/run.sh` avant et après ; pour CA-21, `scripts/criteres-sans-test.sh` sur une issue de ce dépôt rend `OK`.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-17 : `scripts/fin-issue.sh 002-05` : `FIN-ISSUE OK 002-05 95805ba : 783 tests, 0 échec, 0 ignoré` (lancé après le dernier commit de code, rejoué par l'orchestrateur). C'est le premier contrôle de fin d'issue réussi sans régler `DOSSIER_TESTS` à la main : la dérogation d'amorçage F-05 prend fin avec cette issue.
- 2026-11-17 : revue 1 APPROUVÉ (7 mutations sur 7 détectées, dont 3 prouvant que CA-19 et CA-25, sans test rouge préalable car déjà verts avant l'issue, sont discriminants).
- Branche empilée : feat/002-02, puis feat/002-04, puis celle-ci. À fusionner dans cet ordre (le `.factory.conf` de cette branche suppose la clé de 002-04).
- À faire maintenant que `fin-issue.sh` fonctionne ici : relancer `scripts/fin-issue.sh` sur 002-01, 002-02, 002-03 et 002-04 (dérogation d'amorçage) et inscrire les résultats dans leurs issues.
- Mineurs ouverts : `FACTORY_DOSSIER_TESTS=` définie mais vide ne déclenche pas de refus (traitée comme non définie, sans effet de sécurité) ; le test CA-25 « variable FACTORY_ s'applique » ne distingue pas le motif d'échec d'une autre cause (le motif de sortie est contrôlé) ; lien symbolique versionné vers l'extérieur : limite déjà documentée en tête de `fin-issue.sh`.
- Choix du développeur acceptés (à inscrire au PRD) : refus appliqué aux quatre sources même masquées ; message identique pour les quatre sources, sans nommer la source ni recopier la valeur ; variable définie mais vide = non définie.
