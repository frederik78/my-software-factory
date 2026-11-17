---
id: 002-02
titre: Lecture précise des tests bash
prd: docs/prd/002-criteres-tests-bash.md
besoin: F-05
statut: Fait
depend_de: [002-01]
criteres: [CA-05, CA-06, CA-07]
branche: feat/002-02-lecture-precise-tests-bash
commits: [9017d28, 8486f8c, 7a5b0af, f2d05d5, 950e6a7]
revue: APPROUVÉ (itération 3 sur 3, docs/reviews/002-02.md)
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
- 2026-11-17 : revue 1 CHANGEMENTS DEMANDÉS (3 IMPORTANT : deux documents ici sur une ligne, `<<\EOF` et `<<$'EOF'`, CRLF et `<<<` sans test), revue 2 CHANGEMENTS DEMANDÉS (1 IMPORTANT : `"$(cat <<EOF` ignoré par `dans_chaine`, effet de bord d'une correction), revue 3 APPROUVÉ. `verify-clean.sh` 705 OK ; `criteres-sans-test.sh` OK avec `DOSSIER_TESTS=factory/scripts/tests`.
- 2026-11-17 : `scripts/fin-issue.sh 002-02` échoue (attendu, dérogation d'amorçage étendue par l'utilisateur à toutes les issues de F-05 jusqu'à 002-05) : `Dossier de tests introuvable : src/test`. À relancer après 002-05.
- Mineurs ouverts, à documenter dans l'en-tête de `criteres-sans-test.sh` (issue 002-06) : faux MANQUE (`<<"E F"`, `echo "a <<x"`, `$((a<<b))`, chaîne multiligne contenant `<<X`, `"$(date) <<EOF"` dans un titre) ; faux OK rares (guillemet ou apostrophe échappé hors chaîne `echo l\'a; cat <<EOF`, chaîne multiligne refermée sur la ligne du document ici) ; règle « en cas de doute, ouvrir » ; `critere_motif_debut` dépend du texte de `critere_motif`.
- Décisions du développeur à confirmer par l'utilisateur (à inscrire au PRD) : en bash l'identifiant commence le premier argument sans retrait du préfixe `test` (`"test_ca10"` non reconnu) ; document ici jamais refermé : le reste du fichier est ignoré ; tout `<<MOT` précédé de `$(` ou d'une apostrophe inverse sur la ligne ouvre un document ; faux MANQUE préféré à faux OK.
- 2026-11-17 : rattrapage de la dérogation d'amorçage F-05, `scripts/fin-issue.sh 002-02` lancé depuis la branche de 002-05 (HEAD 569954a, qui contient le code de 002-01 à 002-05) : `FIN-ISSUE OK 002-02 569954a : 783 tests, 0 échec, 0 ignoré`.
