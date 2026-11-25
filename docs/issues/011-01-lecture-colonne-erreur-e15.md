---
id: 011-01
titre: Dépendances entre besoins : lecture de la colonne et erreur E15
prd: docs/prd/011-dependances-entre-besoins.md
besoin: F-15
statut: Fait
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-06, CA-07, CS-01, CS-02]
branche: feat/011-01-lecture-colonne-erreur-e15
commits: [95e6692, 8722cfd]
revue: APPROUVÉ (itération 1, docs/reviews/011-01.md)
---

## Objectif
Lecture de la colonne « Dépend de » (par son nom), erreur E15 (inconnu, cycle, cellule trop longue), forme de la sortie, sûreté des valeurs.

## Périmètre
- Dans : Lecture de la colonne « Dépend de » (par son nom), erreur E15 (inconnu, cycle, cellule trop longue), forme de la sortie, sûreté des valeurs.
- Hors : les autres issues du PRD 011 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 011-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-24 : RED constaté (11 des 20 vérifications de la section échouent avant le code), puis GREEN (20 sur 20) ; mutations tuées : limite 64 -> 65, sans dédoublonnage, auto-dépendance ignorée, liste de cycle à 11, sans retrait des espaces de bord.
- 2026-11-24 : non fixés par le PRD (à inscrire) : liste d'un cycle séparée par « , » avec « , … » au-delà de 10 ; ordre d'émission sur un même besoin : inconnus (ordre de la cellule), puis « plus de 64 identifiants », puis cycle ; un NUL dans une cellule coupe la ligne (E03, comportement existant de la lecture du backlog), pas d'E15.
- 2026-11-24 : coût mesuré (cycle de 5 000 besoins : 3 s, chaîne de 5 000 : 4 s, cellule de 1,2 Mio : 0 s ; bash 3.2 identique). Un échec isolé et non reproduit de « git log en échec » (dashboard, PRD 003) vu une fois sur trois exécutions de la suite complète.
- 2026-11-24 Clôture : revue 1 APPROUVÉ ; FIN-ISSUE OK 011-01 50fdc30 : 1998 tests, 0 échec, 0 ignoré (relancé par la session). Fusionnée dans develop.
