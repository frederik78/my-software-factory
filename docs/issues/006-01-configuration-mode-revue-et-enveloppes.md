---
id: 006-01
titre: `MODE_REVUE`, six clés de modèle et d'effort et enveloppes d'agents
prd: docs/prd/006-revue-parallele.md
besoin: F-02
statut: Fait
depend_de: []
criteres: [CA-01, CA-02, CA-03, CA-04, CS-01, CS-02]
branche: feat/006-01-configuration-mode-revue-et-enveloppes
commits: [7a2d54d, 7605edd, 5ba0ea0, faebcff, 11cb2b7, 78383cf]
revue: APPROUVÉ (itération 2, docs/reviews/006-01.md)
---

## Objectif
Le mode de revue se règle (`unique` ou `parallele`, défaut `parallele`), le modèle et l'effort de chaque relecteur aussi, et les trois enveloppes d'agents sont générées.

## Périmètre
- Dans : `MODE_REVUE`, `config-factory.sh --mode-revue` (code 64 si invalide, vide compris), six clés `AGENT_MODELE_<ROLE>` / `AGENT_EFFORT_<ROLE>` qui l'emportent sur l'en-tête, `lib-config.sh`, `sync-claude.sh` (trois enveloppes sans outil d'écriture).
- Hors : les prompts et le brief (006-02), la skill `deliver` (006-03 et 006-04), la documentation (006-07).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit (RED constaté), suite verte, `scripts/criteres-sans-test.sh 006-01` à OK.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-19 : `sync-claude.sh` retire `Write` et `Edit` du champ `tools:` des trois relecteurs même si leur prompt les déclare (RG-04, CA-04 testé avec des prompts jetables qui les déclarent).
- 2026-11-19 : les modèles (`AGENT_MODELE` compris) sont limités à 64 caractères (CS-02 : valeur de 10 000 caractères refusée) ; message de `AGENT_MODELE` inchangé.
- 2026-11-19 : les six clés sont validées en entier avant toute écriture, même si le prompt du rôle est absent ; un saut de ligne final de la valeur la rend invalide (`config_valeur_exacte`).
- 2026-11-19 : ordre de `CONFIG_CLES` : les six clés après `AGENT_EFFORT`, puis `MODE_REVUE` ; le test « sans option » de `run.sh` est mis à jour en conséquence.
- 2026-11-19 : `sync-claude.sh` retire des relecteurs Write, Edit, MultiEdit et NotebookEdit, casse indifférente (revue 1, constats 1 et 2) ; pas de liste blanche (l'outil de progression est ajouté aux enveloppes).
- 2026-11-19 : divergence de lecture de CS-02 : `ultra` est exclu des cas de `AGENT_MODELE_SECURITE` (nom de modèle valide selon la règle de `AGENT_MODELE`), il reste hostile pour `AGENT_EFFORT_SECURITE` (revue 1, constat 4).
- 2026-11-19 Clôture : revue 2 APPROUVÉ (revue 1 : un IMPORTANT corrigé). `FIN-ISSUE OK 006-01 cf4f4e1 : 1768 tests, 0 échec, 0 ignoré` ; `run.sh` direct (relecteur) 1773 OK. Mineur reporté à 006-07 : le README doit dire que la lecture seule d'un relecteur repose sur son prompt pour `Bash`. Limite de la revue 2 : les trois mutations du filtre n'ont été rejouées que sur la commande awk (permission de copie refusée), l'échec réel de la suite n'a pas été observé. Décisions acceptées à l'itération 1 : borne de 64 caractères commune à tous les noms de modèle (comportement de `AGENT_MODELE` étendu) ; validation des six clés même sans prompt de rôle ; `sync-claude.sh` retire de force Write, Edit, MultiEdit et NotebookEdit des relecteurs.
