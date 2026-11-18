---
id: 001-06
titre: Version 1.23.0 et non-régression
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: Fait
depend_de: [001-02, 001-03, 001-04, 001-05]
criteres: [CA-17, CA-18]
branche: feat/001-06-version-et-non-regression
commits: [008c9bb, 948b806, 3992e98, 7a05138, b95c816, 6e377f7, bd20742, 9905628]
revue: docs/reviews/001-06.md (2 itérations, APPROUVÉ)
---

## Objectif
La factory passe en version 1.23.0 (D-27 : 1.22.0 est prise par F-08) : le CHANGELOG décrit le changement et la migration (« remplacer `factory/` »), le guide d'utilisation décrit la commande de lecture du verdict, la carte et la liste d'escalade, et rien d'autre n'a changé : `fin-issue.sh`, le dashboard et les revues existantes sont identiques à la version 1.21.0.

## Périmètre
- Dans : le fichier de version, le CHANGELOG, le guide `factory/README.md`, la vérification que `fin-issue.sh`, le dashboard, leurs tests et les revues de `docs/reviews/` sont inchangés.
- Hors : tout le contenu fonctionnel (issues 001-01 à 001-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca17_…`, `ca18_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit ; pour CA-17, une comparaison à la version 1.21.0 montrant l'absence de différence, avec la commande qui la produit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 : FIN-ISSUE OK 001-06 bb9fe2d : 1372 tests, 0 échec, 0 ignoré. En plus, `bash factory/scripts/tests/run.sh` lancé directement dans le worktree (avec `.git`) : TESTS OK, 1376 vérifications, car ca17 (historique Git) ne tourne pas dans la copie sans `.git` de fin-issue/verify-clean.
- Revue 1 : CHANGEMENTS DEMANDÉS (BLOQUANT : ca17 comptait comme faute les revues créées pendant F-01 puis reformatées) ; corrigé (`git cat-file -e` sur la base de F-01, D-30) ; revue 2 : APPROUVÉ.
- Limites acceptées de ca17 (documentées dans run.sh) : absent de verify-clean/fin-issue (pas d'historique) ; attribution des commits de F-01 par le sujet « 001-0[1-6] » ; lignes `ca17_` exclues de la 2e comparaison.
- Décisions : D-27 (version 1.23.0), D-30 (interprétation de CA-17).
- Mineur ouvert : scripts de F-09 absents du tableau du README (à traiter en 004-05).
- Passages du PRD 001 à amender (par l'utilisateur) : RG-19, CA-17, CA-18, contexte « version actuelle 1.20.1 » (devenue 1.22.0 puis 1.23.0), décisions des issues 001-02/03/04 (200 octets, 1 Mio, séparateurs, \r interne, doublon cité).
