---
id: 004-06
titre: Retrait des anciennes listes et règles de statut
prd: docs/prd/004-machines-a-etats-statuts.md
besoin: F-09
statut: En cours
depend_de: [004-01, 004-02, 004-03, 004-04, 004-05]
criteres: [CA-38, CA-39, CA-40, CA-41]
branche: feat/004-06-retrait-anciennes-listes
commits: []
revue:
---

## Objectif
Une fois le contrôle livré, le code mort qui énumère ou change les statuts disparaît : listes codées en dehors de la table unique, valeurs en dur, règles de transition répétées en prose, tests qui ne gardaient que l'ancienne duplication ; un garde-fou empêche leur retour, sans changement de comportement visible.

## Périmètre
- Dans : inventaire puis suppression des listes et valeurs de statut en dur, de la prose de transition (`AGENTS.md`, son modèle, skill `deliver`) remplacée par un renvoi à la table, des tests de duplication ; garde-fou par recherche d'absence ; comportement identique avant / après (dashboard, `etat-issues.sh`). Exceptions (`fin-issue.sh`, textes du catalogue, commentaires, données de test) justifiées une par une dans les Notes.
- Hors : tout nouveau comportement (issues 004-01 à 004-05).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Inventaire avant, recherche d'absence après (commande et sortie), dashboard et `etat-issues.sh` identiques avant / après sur les fixtures, suite verte.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-18 Inventaire AVANT (recherche d'absence `tests/garde-statuts.awk` sur les scripts de 1.24.0, noms de statut lus dans la table) : 9 trouvailles dans 4 fichiers, toutes retirées. `dashboard.sh` : 190 (suite de trois statuts de besoin « motif de divergence »), 398 (appel de `parmi` avec deux statuts), plus quatre compteurs en dur par statut (`case` lignes 172-175) et leur recomposition (187-189) ; `lib-besoins.sh` : 112 (classe d'une issue), 182 (E06 : quatre statuts de besoin), 209 (besoins pertinents : trois statuts), 295 et 297 (écart d'un besoin) et 273 (A15 : trois statuts d'issue) ; `statuts.sh` : 131 (preuves de branche, deux statuts) et 170 (deux statuts terminaux). Documents : 19 lignes (chaînes ou listes de statuts, phrases « passe à … »/« mets `statut: …` ») dans `AGENTS.md`, son modèle et `skill deliver`.
- 2026-11-18 Remplacement : `lib-issues.sh` fournit `statut_rang`, `statut_depuis`, `statut_en_travail` et `statut_avant_travail`, qui lisent l'ordre du cycle dans la table ; le dashboard compte les statuts d'un besoin dans l'ordre de la table. Sorties inchangées : référence `tests/golden/ca41-sorties.txt`, prise sur les scripts de 1.24.0 avant toute modification, comparée octet pour octet (cas `ca41_…`).
- 2026-11-18 Exception (fin-issue.sh) : `scripts/fin-issue.sh` n'est pas modifié (RG-24, PRD 004) ; il lit le statut `Fait` de l'issue et n'énumère aucune liste.
- 2026-11-18 Exception (textes du catalogue RG-23) : les lignes qui portent `constat_ajouter` (`lib-besoins.sh`, `lib-preuves.sh`, `statuts.sh`) citent des statuts dans le texte exact des messages (par exemple « statut <s> en retard : toutes les issues sont Fait … (attendu : En revue) ») ; ces textes sont fixés par le PRD, le garde-fou les ignore.
- 2026-11-18 Exception (commentaires) : les lignes de commentaire citent des noms de statut pour expliquer une règle ; elles n'ont aucun effet et le garde-fou les ignore.
- 2026-11-18 Exception (références ponctuelles, un seul statut par test) : `= "Fait"`, `= "À faire"`, `Abandonnée` comparés un par un (`etat-issues.sh` 38-57 : issue prête = `À faire` dont les dépendances sont `Fait` ; `dashboard.sh` 232-249 et 387 : même règle, tri de la colonne `Fait` par date ; `lib-besoins.sh` : classes `Fait`/`Abandonnée`, E08, E09, A15 ; `statuts.sh` : une arme `case` par statut pour les preuves, A09 à A11 ; `criteres-sans-test.sh` 150 ; `lib-issues.sh` 168 : raison d'abandon dans les Notes ; `lib-fusion.sh` 46 : « l'issue est `Fait` sur la branche ») : ce sont des règles qui visent un statut précis, pas une liste ni un ordre ; l'ordre de la table n'y change rien.
- 2026-11-18 Exception (données de test) : `tests/run.sh` écrit des statuts en dur dans ses dépôts jetables, ses attendus (`ATTENDUS_I`, `ATTENDUS_B`, sorties de `statuts.sh`) et la référence `tests/golden/` : ce sont des valeurs attendues indépendantes du code, voulues ainsi par le guide des tests.
- 2026-11-18 Tests retirés ou remplacés (raison : ils ne gardaient que le texte de l'ancienne prose de transition) : (1) `/deliver : l'issue passe En revue au lancement …` cherchait les chaînes `statut: En revue` et `remets `statut: En cours`` ; remplacé par la recherche des transitions de la table et des messages de commit `docs: issue <id> en revue` / `… en cours` ; (2) dans `ca33_skill deliver, section « Contrôle des statuts »`, les motifs ``au passage `En revue` `` et ``pour `Fait` `` deviennent `au passage en revue` et `à la clôture`. Aucun autre test ne vérifiait l'égalité ou la présence d'une liste de statuts recopiée (recherche dans `tests/run.sh` : les listes restantes sont des valeurs attendues de sorties).
- 2026-11-18 Correction hors périmètre : le test de limite de revue en dur ignore aussi `docs/issues/*` et `docs/reviews/*` (une note de 004-05 cite l'ancienne valeur) : la suite était en échec sur `develop` (1 échec sur 1646 avant ce travail).
- 2026-11-18 Choix : version 1.24.1 (retrait sans nouveau comportement, patch après 1.24.0) ; aucune entrée dans UPGRADE (remplacer `factory/`, aucune migration). Passages du PRD 004 devenus faux : D-26 et RG-32 (« une fois F-09 fini » : le retrait est fait), la ligne 316 du tableau des issues (004-06 à `Fait` après fusion) et CA-36 (« CA-38 à CA-41 relèvent de 004-06 » : désormais couverts par la suite).
