---
id: 004-04
titre: Lecture seule, coût mesuré et fichiers hostiles
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: Fait
depend_de: [004-03]
criteres: [CA-28, CA-29, CA-30, CS-01, CS-02, CS-03, CS-04]
branche: feat/004-04-lecture-seule-cout-hostiles
commits: [b8247aa, a576214, 5042623, 14424f2]
revue: docs/reviews/004-04.md (1 itération, APPROUVÉ)
---

## Objectif
Le contrôle ne modifie jamais le dépôt (arbre, index, refs, `backlog.md`, issues), reste dans le plafond d'appels Git du PRD, et traite les fichiers absents, illisibles ou hostiles (valeurs forgées dans les en-têtes et le backlog) sans rien évaluer, avec une sortie neutralisée.

## Périmètre
- Dans : lecture seule vérifiable avant / après, plafond d'appels Git (compteur dans un test), fichiers absents ou illisibles, valeurs hostiles, neutralisation de la sortie (caractères de contrôle).
- Hors : règles de cohérence (004-02, 004-03), dashboard (échappement HTML, 004-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère (comparaison de l'arbre, de l'index et des refs avant / après ; comptage d'appels Git ; valeurs hostiles) qui échoue puis réussit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 : FIN-ISSUE OK 004-04 db75496 : 1459 tests, 0 échec, 0 ignoré ; `run.sh` direct dans le worktree (avec `.git`) : 1463 vérifications, 0 échec ; revue 1 : APPROUVÉ, 5 mutations tuées.
- Seul CS-04 était rouge (plus de 120 s pour 2 000 issues, maintenant 27 s) ; les six autres critères étaient verts et sont prouvés par mutation. Lecture groupée des en-têtes (awk) et `lib-verdict.sh` (lecture du verdict partagée avec `verdict-revue.sh`, comportement F-01 inchangé sur 32 cas).
- Décisions en attente de l'utilisateur (recommandation : les garder, à inscrire au PRD 004) : (1) CA-29 « le dashboard n'exécute le contrôle qu'une fois » : accepte 0 ou 1 exécution tant que le dashboard n'appelle pas `statuts.sh`, à resserrer à « exactement 1 » en 004-05 ; (2) borne de CS-04 : 2 s par centaine d'issues (40 s pour 2 000), mesuré 1,35 s, à écrire dans le PRD ; (3) un NUL dans un en-tête coupe la valeur (limite de bash/awk) ; (4) `rattachements_charger` refuse les fichiers d'issue de plus de 1 Mio, y compris pour le dashboard et `etat-issues.sh` (cohérent avec E14).
- Mineurs ouverts : borne `-le 40` de `cs04_volumes` pouvant échouer sur machine lente ; fixture CS-04 à 95 % de Fait (250 issues En cours à branche déclarée coûtent 40 s de plus : 3 appels Git par issue du calcul du statut effectif du PRD 003, non modifié) ; limite 004-03 (c) : `cat-file --batch` lit un fichier d'issue géant de `develop` en entier ; mineur 004-03 n°3 mesuré (2 s) et non corrigé.
- Documentation à faire en 004-05 : `scripts/lib-verdict.sh` et les nouveaux liens/libs absents du README, CHANGELOG, UPGRADE.
