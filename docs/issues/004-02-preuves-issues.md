---
id: 004-02
titre: Preuves d'une issue, branche retenue, Abandonnée et dépendances
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: Fait
depend_de: [004-01]
criteres: [CA-10, CA-11, CA-12, CA-13, CA-14, CA-15, CA-16, CA-17, CA-18]
branche: feat/004-02-preuves-issues
commits: [156248e, 846543e, 2846954, a434ddc, 4a83687, 4e35c32, 152a025, 223ab4c, df59a28, b1b741d, 438f568, 7feb27d, b4ad675]
revue: docs/reviews/004-02.md (APPROUVÉ, itération 1/3)
---

## Objectif
Le contrôle vérifie qu'une issue est cohérente avec ses preuves (revue approuvée, FIN-ISSUE OK, commits pour `Fait` ; revue pour `En revue`), sur le statut effectif de sa branche, gère `Abandonnée` (raison écrite) et signale les dépendances incohérentes, avec les messages d'erreur et d'avis du catalogue.

## Périmètre
- Dans : preuves des statuts `Fait` et `En revue`, branche retenue (PRD 003), `Abandonnée` et sa raison, dépendances (dont dépendance `Abandonnée` non levée, avis), avis pour les issues déjà `Fait` avant F-09.
- Hors : cohérence des besoins (004-03), lecture seule, coût, fichiers hostiles (004-04), dashboard et documentation (004-05), nettoyage (004-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue (incohérence non signalée) puis réussit ; messages à égalité exacte avec le catalogue.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 : revue 1 APPROUVÉ sans constat bloquant ni important ; `FIN-ISSUE OK 004-02 e66ef2a : 1280 tests, 0 échec, 0 ignoré` (lancé par l'orchestrateur après le dernier commit de code). Mutations : nombreuses, lancées par le développeur (toutes tuées) ; le relecteur n'en a lancé aucune.
- Défaut trouvé par l'orchestrateur avant la revue et corrigé : `scripts/statuts.sh` échouait (liens `scripts/lib-preuves.sh` et `scripts/lib-dependances.sh` manquants, tests lancés sur `factory/scripts/`) ; test par le lien du dépôt ajouté (commits 7feb27d, b4ad675).
- Décisions de l'utilisateur (2026-11-18, « Oui à tout, avec tes recommandations ») : RG-10 (b) accepte deux formes de verdict (première ligne `VERDICT: APPROUVÉ` au sens de verdict-revue.sh, ou dernière ligne non vide `APPROUVÉ` pour les revues d'avant F-01) ; A07 lu sur le statut local ; A09/A10 sur le statut effectif, A11 sur le Fait local ; dépendance inconnue d'une issue Fait : aucun avis ; dépendance vers E10/E11 : aucun avis, vers E14 : A10 ; `revue:` vide : A01 seul ; chemin suivi d'un point ou précédé de `./` : A02 ; « ligne à puce » = `-`, `*`, `+` ; fin de section Notes = titre `#` ou `##` ; « Abandonnée » = sous-chaîne exacte.
- Décisions encore ouvertes chez l'utilisateur : texte de l'avis A03 (catalogue RG-23 : « la dernière ligne … n'est pas APPROUVÉ », trompeur depuis les deux formes) ; revues consolidées à plusieurs lignes `VERDICT:` donnant A03 (option A recommandée : une seule ligne `VERDICT:` en tête par fichier, les itérations suivantes écrivent « Verdict de l'itération : … »).
- Mineurs ouverts : lien symbolique d'issue ignoré sans déduction de branche (lib-issues.sh:176) ; message brut si statuts.sh est lancé hors du wrapper ; coût par issue (7 lectures awk, 14 s pour 300 issues Fait sous bash 3.2) à optimiser en 004-04 ; seul le BSD awk de macOS testé ; les fixtures de 004-03 devront tenir compte des avis A01/A04/A05 sur les issues Fait sans preuves.
- Passages du PRD 004 à préciser par l'utilisateur : RG-10 (deux formes de verdict) ; texte de A03 dans RG-23 ; ligne 148 (E10/E11 coexistent pour un doublon d'identifiant).
