---
id: 003-02
titre: Statut effectif, dépendance levée et prochaine issue prête
prd: docs/prd/003-dashboard-a-jour.md
besoin: F-08
statut: Fait
depend_de: [003-01]
criteres: [CA-10, CA-11, CA-12, CA-13, CA-14, CA-15, CS-06]
branche: feat/003-02-statut-effectif-dependances
commits: [2414398]
revue: docs/reviews/003-02.md (APPROUVÉ, itération 1/3)
---

## Objectif
Le statut d'une issue est le plus avancé entre `develop` et sa branche retenue ; une dépendance « Fait » sur sa branche est levée et la carte suivante affiche « empilée sur <branche> » ; `etat-issues.sh --prochaine` et le dashboard désignent la même issue.

## Périmètre
- Dans : statut effectif sur la branche retenue (déclarée ou déduite), dépendances levées, mention « empilée sur », « Prochaine issue prête » du dashboard et de `etat-issues.sh --prochaine`, colonne Branche du tableau, fichier d'issue invalide ou lien symbolique sur la branche.
- Hors : le rattachement lui-même (003-01), l'avancement des besoins (003-04).

## Critères d'acceptation
Les critères listés dans l'en-tête (`criteres`), tels que définis dans le PRD. Chaque critère doit être couvert par au moins un test
dont le nom contient son identifiant (ex. `ca10_…`, `cs07_…`).

## Preuve attendue
Un test par critère sur des dépôts Git jetables, qui échoue (issue suivante encore « bloquée ») puis réussit ; réécriture des cas de `run.sh` qui testent l'ancienne règle de dépendance (RG-23), expliquée dans le rapport.

## Notes
Décisions et écarts survenus pendant la livraison (une ligne chacun, datée).
- 2026-11-17 : développeur : `FIN-ISSUE OK 003-02 2414398 : 906 tests, 0 échec, 0 ignoré` (882 avant, +24) ; un cas existant réécrit (RG-23) : « dépendance Fait sur sa branche seule : reste bloquée » devient « empilée sur feat/f ».
- Décisions en attente de l'utilisateur (à inscrire au PRD 003) : borne de lecture d'un fichier d'issue sur branche chiffrée à 65536 octets (CS-06) ; un blob en mode lien symbolique dont le contenu est un en-tête valide est lu comme un fichier ordinaire (seul le statut affiché peut être trompé, rien d'extérieur n'est lu ; détecter le mode coûterait un appel Git de plus par issue) ; « empilée sur » rendu comme un marqueur coloré comme « bloquée ».
- 2026-11-17 : revue 1 APPROUVÉ sans constat bloquant ni important ; `FIN-ISSUE OK 003-02 099b7d3 : 906 tests, 0 échec, 0 ignoré` (relancé par l'orchestrateur après le dernier commit de code).
- Mineurs ouverts : (1) coût RG-21 : `etat-issues.sh --prochaine` calcule le statut effectif de chaque dépendance non Fait local (3 appels Git chacune) : 16 appels avant, 19 après sur 12 issues en chaîne ; le listage des branches reste unique ; à mesurer et trancher en 003-05 ; (2) passages de documentation devenus faux, à traiter en 003-05 : `factory/README.md` l.127, 155, 156, `docs/issues/README.md` l.21, `docs/agents/issue-tracker.md` l.12 (« ready-for-agent = dépendances Fait »).
- À inscrire au PRD 003 par l'utilisateur : borne de lecture 65536 octets (CS-06) ; blob en mode lien symbolique dont le contenu est un en-tête valide lu comme fichier ordinaire (gravité faible : même résultat par une simple branche locale forgée ; aucune lecture extérieure ; la fusion et `fin-issue.sh` restent les filets) ; « empilée sur » rendu en marqueur coloré ; Q-11 « provisoirement » à confirmer.
