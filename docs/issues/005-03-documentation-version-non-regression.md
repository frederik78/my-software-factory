---
id: 005-03
titre: Documentation, version 1.25.0 et non-régression
prd: docs/prd/005-format-revue-consolide.md
besoin: F-12
statut: En cours
depend_de: [005-02]
criteres: [CA-19, CA-20, CA-21, CA-22]
branche:
commits: []
revue:
---

## Objectif
La factory passe en version 1.25.0 : le CHANGELOG et le guide de migration décrivent le changement, la documentation est à jour, et rien d'autre n'a changé.

## Périmètre
- Dans : fichier de version, CHANGELOG, UPGRADE, guide `factory/README.md`, tests regroupés, non-régression.
- Hors : tout le contenu fonctionnel (005-01, 005-02).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère qui échoue puis réussit.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- Version 1.25.0 attendue (suivante libre après 1.24.0 de F-09) ; à confirmer au moment de la livraison.
- 2026-11-19 Version : 1.25.0 confirmée (la version courante au départ était 1.24.1, livrée par 004-06 ; aucune autre version prise depuis).
- 2026-11-19 Cas de lecture de textes réécrits (CA-22), liste justifiée : (1) `ca35` (UPGRADE : « la section 1.24.0 est la première ») devient « suivie de la section 1.23.0 », car la section 1.25.0 passe devant ; (2) `ca41` (« le CHANGELOG mentionne le retrait ») lit désormais l'entrée 1.24.1 et non la première entrée ; (3) `ca09_report_format_la_section_du_code_reviewer_est_inchangee` (PRD 006) : empreinte de la section « Rapport du reviewer » mise à jour, car CA-19 impose de réécrire son dernier paragraphe (la session écrit la ligne de tête). Aucun autre cas existant n'est modifié.
- 2026-11-19 `docs/reviews/README.md` est rendu identique à son modèle (CA-19) ; aucun fichier de revue (`docs/reviews/<id>.md`) n'est touché. Les motifs « A01 à A15 » du CHANGELOG (entrée 1.24.0) et de l'UPGRADE (section 1.24.0) sont de l'historique exact de cette version et exigés par `ca35` : ils restent ; la version courante dit A01 à A16 (catalogue de `factory/README.md`, entrée 1.25.0).
- 2026-11-19 Les avis A16 attendus sur les revues d'avant F-01 sont une décision de l'utilisateur en attente : mentionnés au CHANGELOG, non corrigés.
- 2026-11-19 Non-régression CA-22 : base = commit du PRD 005 (57b96dd) ; commits de F-12 repérés par leur sujet (`005-01` à `005-03`), comme pour F-01 (`ca17`) ; limite : un commit de F-12 sans cette mention échappe au contrôle.
- 2026-11-19 Revue 1, constat 1 (CA-22) : la plage de la branche n'est pas utilisable proprement (les commits de F-12 sont mêlés à ceux de 004-06 et de F-02 entre `94c66a8^` et la pointe, dont certains touchent `dashboard.sh`), donc les commits de F-12 restent repérés par leur sujet, élargi à `005-0[1-9]`. Limite consignée : un commit de F-12 sans « 005-0x » dans son message n'est pas attribué à F-12. Un cas sur dépôt jetable prouve la détection (commit « 005-05 » touchant `fin-issue.sh` et une revue existante) et borne la limite (commit sans identifiant touchant `dashboard.sh`). Le RED de ce cas n'a pas été constaté à part : l'élargissement du motif est dans le même commit.
- 2026-11-19 Constat 2 : la référence des revues existantes est l'état juste avant le premier commit de F-12 (`94c66a8^`).
- 2026-11-19 Constat 3 : `AGENTS.md` et `factory/templates/AGENTS.md` (ligne `scripts/statuts.sh`) disent « avis A01 à A16 » ; le cas `ca34` (motif de cette ligne) attend A01 à A16 (RED constaté par la modification du cas avant celle des fichiers : ce cas échoue sur le commit de test).
