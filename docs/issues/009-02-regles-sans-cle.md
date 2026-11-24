---
id: 009-02
titre: Règles de l'orchestrateur : règles sans clé dans AGENTS.md et deliver
prd: docs/prd/009-regles-orchestrateur-dans-la-factory.md
besoin: F-14
statut: Fait
depend_de: []
criteres: [CA-05, CA-06, CA-07, CA-08, CA-09, CS-06, CS-08]
branche: feat/009-02-regles-sans-cle
commits: [a4ea2b8, 344ece9, 831f9ce, 1912c9a, a705a9c]
revue: APPROUVÉ (itération 1, docs/reviews/009-02.md)
---

## Objectif
Règles sans clé (1, 2, 6, 7, 8) : section Orchestration d'`AGENTS.md` et du modèle (les huit puces, clés nommées), skill `deliver`.

## Périmètre
- Dans : Règles sans clé (1, 2, 6, 7, 8) : section Orchestration d'`AGENTS.md` et du modèle (les huit puces, clés nommées), skill `deliver`.
- Hors : les autres issues du PRD 009 (voir le découpage de sa section 9).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 009-02` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-24 : les huit règles sont des puces `- Règle N, …` (une ligne chacune, renvoi à `factory/skills/deliver/SKILL.md`) sous « **Règles de l'orchestrateur** », entre « Principes » et « Séquence d'un besoin », identiques dans `AGENTS.md` et son modèle.
- 2026-11-24 : l'étape 6 d'`AGENTS.md` et du modèle devient conditionnelle (`BESOIN_FAIT_AUTO=oui` seulement, défaut `non` : proposer) sans second paragraphe ; la procédure des règles 3, 4 et 5 dans `deliver` reste à l'issue 009-03.
- 2026-11-24 : la ligne `config-factory.sh` d'`AGENTS.md` et du modèle cite déjà les trois options (CA-05) ; elles n'existent dans le script qu'avec l'issue 009-01.
- 2026-11-24 : les cas ca07 (creer en conteneur bare et en dépôt classique) et ca08 (lecture du fichier abaissé) vérifient un comportement existant : ils passent dès leur écriture (non-régression, pas de RED) ; leur partie texte est RED.
- 2026-11-24 : `scripts/statuts.sh` signale E07 (besoin F-14 « Spécifié » en retard, issue 009-01 démarrée) : `backlog.md` n'est pas touché par cette issue, à traiter par la session.
- FIN-ISSUE : voir la dernière ligne de `scripts/fin-issue.sh 009-02` dans le rapport.
- 2026-11-24 Clôture : revue 1 APPROUVÉ ; FIN-ISSUE OK 009-02 1c7d998 : 2098 tests, 0 échec, 0 ignoré (relancé par la session). Fusionnée dans develop.
