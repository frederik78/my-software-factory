---
id: 002-06
titre: Documentation, version 1.21.0 et tests réunis
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: En cours
depend_de: [002-02, 002-05]
criteres: [CA-22, CA-23, CA-24]
branche: feat/002-06-documentation-version-tests
commits: []
revue:
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
