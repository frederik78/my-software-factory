# Backlog : My Software Factory

Vue d'ensemble des besoins. Il appartient à l'utilisateur, qui peut l'éditer librement.
Le détail (exigences, règles, critères d'acceptation) vit dans le PRD du module, `docs/prd/` ; le suivi de la livraison dans `docs/issues/`.
L'orchestrateur ne met à jour ici que les statuts et les décisions ; il ne reformule jamais un besoin sans accord.

**Statuts** : `À faire` -> `En clarification` -> `Spécifié` -> `En cours` -> `En revue` -> `Fait`
**Priorités** : `P1` indispensable, `P2` important, `P3` souhaitable

## Contexte et contraintes globales
- Utilisateurs cibles :
- Volume attendu :
- Langue(s) :
- Contraintes réglementaires ou fiscales :
- Sécurité : OWASP Top 10 intégral, voir la skill `owasp-check`
- Périmètre actuel :

## Besoins fonctionnels

| ID | Besoin | Priorité | Statut | PRD | Décisions |
|----|--------|----------|--------|-----|-----------|
| F-01 | Chaque rapport de revue commence par un verdict lisible par machine (`VERDICT: PASS` ou `VERDICT: CHANGES`) ; une issue bloquée en revue porte une carte « pour l'humain » (décision à prendre, fichiers à lire, vérification suggérée) ; `AGENTS.md` liste les sujets d'escalade obligatoire (secrets, authentification, dépendances, déploiement, contrat externe, licence) | P1 | En cours | `docs/prd/001-verdict-revue.md` | Traité en premier, seul ; clôture de 001-01 bloquée par F-05 (2026-11-16) ; cadrage validé le 2026-11-16 : D-02 à D-05 (les valeurs du verdict sont celles de D-02, pas `PASS`/`CHANGES`) |
| F-02 | La revue d'une issue est faite par plusieurs relecteurs en parallèle, la sécurité (OWASP) séparée sur un modèle plus fort ; chacun écrit son rapport avec son verdict | P2 | À faire | | Dépend de F-01 ; coût en appels au modèle à trancher au cadrage |
| F-03 | Le dashboard affiche, sur une issue « En revue », le verdict du dernier tour de revue et le numéro du tour | P3 | À faire | | Dépend de F-01 (lecture du champ `revue:` de l'en-tête de l'issue) |
| F-04 | Le dashboard affiche les issues au statut `Abandonnée` dans leur propre regroupement, au lieu de « (autre) » | P3 | À faire | | Constaté sur le dashboard de gestion-chalet |
| F-05 | Le contrôle des critères sans test reconnaît les tests écrits en bash, dans un dossier de tests configurable, pour que `fin-issue.sh` puisse clôturer une issue de la factory elle-même | P1 | En cours | `docs/prd/002-criteres-tests-bash.md` | Découvert à la livraison de 001-01 (`criteres-sans-test.sh` ne lit que Java, Kotlin, Python, JS/TS et cherche `src/test`) ; cadrage : D-06 à D-08 ; à livrer avant la clôture de 001-01 |
| F-06 | À la création des issues (`/to-tickets`), le champ `branche:` de chaque en-tête est rempli avec la branche prévue (`feat/<id>-<slug>`), pour que le dashboard rattache une issue en cours à sa branche et à son worktree avant sa fusion | P2 | À faire | | Constaté le 2026-11-16 : sans ce champ lu dans le dossier de l'utilisateur, 001-01 et 002-01 apparaissent « à faire » alors qu'elles sont `En cours` sur leur branche ; option 1 choisie (D-09) ; les 12 issues existantes sont à compléter |

## Besoins non fonctionnels

| ID | Besoin | Statut |
|----|--------|--------|
| NF-01 | Sécurité OWASP Top 10, vérifiée à chaque revue | À faire |

## Décisions prises

| ID | Date | Décision | Besoin |
|----|------|----------|--------|
| D-01 | | Les besoins sont suivis ici ; le détail est dans les PRD de `docs/prd/` et les issues de `docs/issues/` | tous |
| D-02 | 2026-11-16 | Verdict de revue : première ligne du rapport, `VERDICT: APPROUVÉ` ou `VERDICT: CHANGEMENTS DEMANDÉS` ; un script lit cette ligne et répond `APPROUVÉ`, `CHANGEMENTS DEMANDÉS` ou `INCONNU` (codes de sortie 0, 1, 64), avec ses tests ; `/deliver` l'appelle après chaque revue et relance une fois le reviewer sur `INCONNU` ; `fin-issue.sh` et le dashboard ne changent pas ; anciennes revues non migrées | F-01 |
| D-03 | 2026-11-16 | Carte « pour l'humain » : rédigée par la session, seulement pour une issue bloquée en revue après `MAX_ITERATIONS_REVUE` ; trois rubriques (décision à prendre, fichiers à lire, vérification suggérée) ; section `## Pour l'humain` du fichier de revue et corps du courriel de `notifier.sh` | F-01 |
| D-04 | 2026-11-16 | Liste d'escalade dans `AGENTS.md` (le modèle et celui de ce dépôt), pour tous les rôles : secrets et identifiants, authentification et autorisation, dépendance et licence, déploiement et CI, contrat d'un service externe, écart avec le PRD ; l'agent s'arrête et le range dans `## QUESTIONS` ou `## À trancher par l'utilisateur` | F-01 |
| D-05 | 2026-11-16 | Pas d'ADR pour F-01 (conventions de documentation et petit script) ; propagation : format dans `report-format.md` et le prompt du reviewer, mention dans `factory/README.md`, CHANGELOG, version 1.21.0, migration « remplacer `factory/` » | F-01 |
| D-06 | 2026-11-16 | Un test bash est un appel à une fonction dont le premier argument entre guillemets commence par l'identifiant du critère (`ca10_…`, `cs01_…`) ; les noms de fonctions sont fixés en configuration (par défaut `verifier`, `verdict_cas`) ; commentaires et chaînes de texte ignorés, comme pour les autres langages | F-05 |
| D-07 | 2026-11-16 | `DOSSIER_TESTS` devient une clé de `.factory.conf` ; ce dépôt la règle sur `factory/scripts/tests` ; comportement actuel (`src/test`, `tests`, `test`) inchangé par défaut | F-05 |
| D-08 | 2026-11-16 | F-05 est livré avant la clôture de 001-01 ; 001-01 reste `En cours`, code livré et tests verts, sans passer `Fait` ni en revue d'ici là ; pas d'ADR | F-05, F-01 |
| D-09 | 2026-11-16 | Le champ `branche:` est rempli dès la création des issues (option 1) plutôt que d'exploiter seulement la section « Autres travaux » du dashboard | F-06 |
