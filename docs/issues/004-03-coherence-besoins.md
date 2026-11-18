---
id: 004-03
titre: Cohérence des besoins avec leurs issues
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: À faire
depend_de: [004-02]
criteres: [CA-19, CA-20, CA-21, CA-22, CA-23, CA-24, CA-25, CA-26, CA-27]
branche: feat/004-03-coherence-besoins
commits: []
revue:
---

## Objectif
Le contrôle compare le statut de chaque besoin à celui de ses issues : issue sans besoin connu, besoin sans PRD, besoin en retard (erreur) ou en avance (avis), `Fait` justifié par la fusion de toutes les branches dans `develop` lue dans Git, besoin réparti sur plusieurs PRD, besoin `Abandonnée`.

## Périmètre
- Dans : les règles de RG-14 à RG-18 (besoin), la lecture de la fusion dans Git, les messages d'erreur et d'avis des besoins.
- Hors : preuves d'une issue (004-02), lecture seule, coût, fichiers hostiles (004-04), dashboard, documentation, version (004-05), nettoyage (004-06).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère, sur des dépôts Git jetables avec branches fusionnées et non fusionnées, qui échoue puis réussit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
