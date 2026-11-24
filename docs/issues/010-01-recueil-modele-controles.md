---
id: 010-01
titre: Constats récurrents : le recueil, son modèle et ses contrôles
prd: docs/prd/010-constats-recurrents.md
besoin: F-13
statut: En revue
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CS-02, CS-03, CS-05]
branche: feat/010-01-recueil-modele-controles
commits: [e9c1053, 68e2538, 69d5bda, b111064, 957bf2f]
revue: APPROUVÉ (itération 1, docs/reviews/010-01.md)
---

## Objectif
Le recueil : fichier amorcé, modèle, introduction, contrôle de forme et de borne par test, aucun secret.

## Périmètre
- Dans : Le recueil : fichier amorcé, modèle, introduction, contrôle de forme et de borne par test, aucun secret.
- Hors : les autres issues du PRD 010 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 010-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-24 : contrôles dans `factory/scripts/tests/run.sh` (section « constats récurrents », fonctions `rc_*`) ; le recueil et le modèle y sont lus depuis HEAD (`lire_depot`), comme les autres vérifications de documentation.
- 2026-11-24 : amorçage = les 8 lignes de PRD 3.2, reformulées pour tenir en 300 caractères (ligne 4 : fin de règle raccourcie ; lignes 2, 6, 7, 8 : exemples abrégés) ; les 8 origines ont un fichier `docs/reviews/<id>.md`.
- 2026-11-24 : la longueur d'une ligne se compte en caractères (perl UTF-8), pas en octets ; un cas le prouve (240 « é »).
- 2026-11-24 : « aucune consigne adressée à un agent » (RG-14) n'est pas détectable par forme : le test refuse le texte hors ligne de règle, les lignes `VERDICT:`, `#`, clôtures et la forme à trois champs ; une règle qui commencerait par « ignore… » reste à la charge de la session et de la relecture de PR.
- 2026-11-24 : les mutations de test n'utilisent pas l'adresse sed `0,/re/` (GNU seulement) : la suite doit passer sous macOS, bash 3.2.
