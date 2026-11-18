---
id: 001-01
titre: Lecture d'un verdict
prd: docs/prd/001-verdict-revue.md
besoin: F-01
statut: Fait
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CA-05, CA-11, CS-01, CS-02, CS-03]
branche: feat/001-01-lecture-verdict
commits: [f6c8b6c, 18a2ed2, f71bc7b, 560626c]
revue: docs/reviews/001-01.md (APPROUVÉ, itération 2/3)
---

## Objectif
Une commande `scripts/verdict-revue.sh <fichier>` lit le verdict d'un rapport de revue et répond `APPROUVÉ`, `CHANGEMENTS DEMANDÉS` ou `INCONNU`, avec un code de sortie fiable, sans jamais exécuter ni recopier le contenu du fichier.

## Périmètre
- Dans : la lecture d'une première ligne valide, `INCONNU` pour un fichier sans ligne `VERDICT:` ou absent, le code 64 pour un mauvais usage, la sortie à une seule ligne et le fichier lu inchangé, la résistance à un contenu hostile (le chemin et le contenu sont des entrées externes : leurs contrôles naissent ici).
- Hors : les doublons, la ligne mal placée, la tolérance de casse et d'espaces, les valeurs inconnues, l'ajout des tests au fichier de tests de la factory pour CA-01 à CA-11 (issue 001-02).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test dont le nom contient son identifiant (ex. `ca01_…`, `cs01_…`).

## Preuve attendue
Un test par critère qui échoue sans le script puis réussit avec lui, avec la sortie de `factory/scripts/tests/run.sh` avant et après.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 : revue 1 CHANGEMENTS DEMANDÉS (1 BLOQUANT : octets NUL supprimés avant comparaison, 2 IMPORTANT : test cs03 vacu, cas de chemin non testés), corrigés ; revue 2 APPROUVÉ ; `FIN-ISSUE OK 001-01 8c83e25 : 1114 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après le dernier commit de code, après fusion de `develop` dans la branche).
- Mineur ouvert : sous bash 5, l'avertissement « ignored null byte » (verdict-revue.sh:26) s'ajoute au message d'erreur d'un fichier avec NUL ; non corrigé. NUL au-delà de 100 octets et NUL final sans saut de ligne vérifiés à la main, sans test dédié.
