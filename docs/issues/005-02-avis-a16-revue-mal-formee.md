---
id: 005-02
titre: Avis A16 : fichier de revue mal formé
prd: docs/prd/005-format-revue-consolide.md
besoin: F-12
statut: À faire
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
