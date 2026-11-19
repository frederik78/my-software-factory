---
id: 005-02
titre: Avis A16 : fichier de revue mal formé
prd: docs/prd/005-format-revue-consolide.md
besoin: F-12
statut: En cours
depend_de: [005-01, 004-06]
criteres: [CA-09, CA-10, CA-11, CA-12, CA-13, CA-14, CA-15, CA-16, CS-01, CS-02, CS-03, CS-04, CS-05]
criteres_justification: Treize critères sur un seul avis (A16) : définition, périmètre, bornes et valeurs hostiles se testent sur la même fonction ; les scinder ferait couvrir un même code par deux issues.
branche:
commits: []
revue:
---

## Objectif
`scripts/statuts.sh` signale par l'avis A16 un fichier de revue consolidé mal formé (plus d'une ligne `VERDICT:`, ou première ligne qui n'est pas le verdict), en nommant le fichier et la cause.

## Périmètre
- Dans : la définition de la ligne de verdict (la même que `verdict-revue.sh`), le périmètre (issues `Fait` et `En revue`), l'indépendance d'A03, la lecture seule et le coût (aucun appel Git de plus), les valeurs hostiles, les bornes (1 Mio), CRLF, liens symboliques.
- Hors : le format lui-même (005-01), la documentation et la version (005-03), la modification du texte d'A03 (relève de F-01, D-30).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère sur dépôts jetables qui échoue puis réussit ; le critère CS-01 compare la lecture d'A16 à celle de `verdict-revue.sh` sur toutes les formes.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- Dépend de 004-06 : même table, mêmes bibliothèques et même catalogue que F-09 (backlog : F-12 dépend de F-09).
- Amendement du PRD 004 à faire par l'utilisateur : ligne A16 au catalogue RG-23 et RG-11 élargie (cadrage Q-03, 2026-11-18).
- 2026-11-19 : écart avec le PRD (CA-12, à trancher par l'utilisateur) : les revues réelles 002-01 et 003-01 ne sont pas « sans ligne de verdict » (002-01 en a deux, 003-01 une au milieu). Selon RG-08 elles sont mal formées : `scripts/statuts.sh` du dépôt émet donc A16 pour 8 issues Fait (001-05, 002-01 à 002-03, 002-05, 002-06, 003-01, 003-03). Le test ca12 utilise des copies privées de leurs lignes de verdict ; RG-08 est appliquée telle quelle, sans exception.
- 2026-11-19 : décompte des lignes de verdict de A16 : pour une issue Fait, dans le passage awk déjà fait pour la dernière ligne (aucun processus de plus, borne cs04 tenue : 30 s mesurés sous charge contre 37 s avec un grep de plus par revue) ; pour une issue En revue, un grep (`verdict_forme`, lib-verdict.sh, même motif et mêmes options que `verdict_lire`).
- 2026-11-19 : cas existants réécrits parce que leurs fixtures sont désormais des fichiers mal formés (A16 attendu en plus) : ca11_preuves (004-74), ca11_verdict (004-64, 004-68), et le motif « A01 à A16 » de l'en-tête de statuts.sh (ca34). La ligne du catalogue de factory/README.md est ajoutée ; le reste de la documentation relève de 005-03.

