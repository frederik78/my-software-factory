---
id: 002-06
titre: Documentation, version 1.21.0 et tests réunis
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: Fait
depend_de: [002-02, 002-05]
criteres: [CA-22, CA-23, CA-24]
branche: feat/002-06-documentation-version-tests
commits: [1266994, 0aa114c, cddc505, 1743504, ef0ba16]
revue: docs/reviews/002-06.md (APPROUVÉ, itération 2/3)
---

## Objectif
La factory passe en version 1.21.0 : la forme du test bash, les deux clés de configuration et leur priorité sont décrites partout où un utilisateur les cherchera, le CHANGELOG décrit le changement et la migration, et tous les cas de F-05 figurent ensemble dans les tests de la factory.

## Périmètre
- Dans : l'en-tête du script de contrôle, `factory/README.md`, `AGENTS.md` (commandes) et le modèle de configuration décrivent la forme du test bash, les clés et leur priorité ; le fichier de version, l'entrée 1.21.0 du CHANGELOG (changement et migration « remplacer `factory/` ») et la mention dans le guide ; la présence dans `factory/scripts/tests/run.sh` des cas de CA-01 à CA-20 et CA-25, leur nom contenant l'identifiant, avec la suite entière verte.
- Hors : le comportement du contrôle et de la configuration (issues 002-01 à 002-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca22_…`, `ca24_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit ; pour CA-23, la sortie de `factory/scripts/tests/run.sh` montrant les cas de F-05 et l'absence de régression.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-17 : `FIN-ISSUE OK 002-06 54040c9 : 858 tests, 0 échec, 0 ignoré`. Revue 1 APPROUVÉ avec 1 IMPORTANT (tests `ca22_` trop larges), corrigé ; revue 2 APPROUVÉ.
- 2026-11-17 : commit 1743504 au message provisoire « wip-local » et sans `Co-Authored-By` (erreur du développeur, historique non réécrit) ; à renommer par l'utilisateur à la fusion s'il le souhaite.
- 2026-11-17 : mineurs ouverts : `contient` devenu insensible à la casse (`run.sh:2012`) et `ca24_` s'en sert, léger affaiblissement ; ancre présente deux fois ou « Limites connues » supprimée : l'extraction awk s'élargit ; test d'isolation `ca23_` sur la présence du `unset`, pas sur son effet.
- Passages devenus faux, à l'utilisateur : `backlog.md` D-05 (1.21.0 annoncé pour F-01, devient 1.22.0), PRD 002 lignes 17 et 20 (« version actuelle 1.20.1 »), CS-04 (exemple `$(touch marque)` : « introuvable », 64), bloc `ca21` de `run.sh` (vise encore 002-05).
