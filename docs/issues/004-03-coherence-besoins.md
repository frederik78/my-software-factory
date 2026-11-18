---
id: 004-03
titre: Cohérence des besoins avec leurs issues
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: Fait
depend_de: [004-02]
criteres: [CA-19, CA-20, CA-21, CA-22, CA-23, CA-24, CA-25, CA-26, CA-27]
branche: feat/004-03-coherence-besoins
commits: [1f2f01e, c4ffee2, c491e86, 71cda66, 3d532fb, da1b1c1, a7bf725, 5ec6763, a2d0945, f0d18d3, 3ed8417]
revue: docs/reviews/004-03.md (1 itération, APPROUVÉ)
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
- 2026-11-18 : FIN-ISSUE OK 004-03 93de76c : 1348 tests, 0 échec, 0 ignoré ; `run.sh` direct dans le worktree (avec `.git`) : 1348 vérifications, 0 échec ; revue 1 : APPROUVÉ, 6 mutations tuées.
- Décisions confirmées par l'utilisateur (à inscrire au PRD 004 : catalogue RG-23 et RG-14 à RG-18) : E06 sans chemin valide = `fichier absent : <cellule>` (second motif) ; A14 « non listé » et « introuvable » peuvent se cumuler ; PRD ou dossier `docs/prd` en lien symbolique compté absent (cohérent E14 / CA-09) ; au-delà de 64 chemins dans une cellule, le surplus est ignoré ; E09 sensible à la casse (RG-18) ; A15 un avis par issue ouverte (RG-18).
- Mineurs ouverts : (1) `docs/prd/<nom>.md` défini deux fois dans lib-besoins.sh ; (2) liste de statuts en dur hors de la table (lib-besoins.sh:184, :297), à ranger en 004-06 (CA-38) ; (3) parcours `case "$pertinents"` par issue Fait, coût à mesurer en 004-04.
- À aligner en 004-05/06 : `avancement_besoin` du dashboard duplique une part de RG-17 (non modifié, CA-37). Seul l'awk BSD de macOS a été exercé.
