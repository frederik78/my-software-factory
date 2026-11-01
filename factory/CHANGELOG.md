# Historique des versions

## 1.7.0
- `sync.sh` devient neutre vis-à-vis de l'outil : il crée seulement `.agents/skills`, puis appelle `factory/sync-claude.sh` si le projet a un `CLAUDE.md` (le seul dossier `.claude/`, que `init-projet.sh` crée, ne suffit pas). Options `--claude` (force l'appel), `--sans-claude` (l'interdit) ; option inconnue ou combinaison des deux : usage sur stderr, code 64.
- Nouveau `factory/sync-claude.sh`, propre à Claude Code et utilisable seul : lien `.claude/skills`, enveloppes `.claude/agents/*.md` (même format, seul le commentaire « Généré par » cite désormais `sync-claude.sh`), outil du plugin savvy-progress. Son en-tête explique que les valeurs de `tools:` des prompts sont des noms d'outils de Claude Code.
- Documentation : § 9 du README de la factory remplacé par un tableau « Indépendance du fournisseur » ; README, `AGENTS.md` et modèles mis à jour.
- Suivi de progression : la consigne ajoutée aux agents ne fixe plus « 3 à 8 étapes » ; l'agent établit le nombre d'étapes selon la mission (une étape = un résultat vérifiable, sans plancher ni plafond, ni trop fin ni trop grossier) et ajuste `total` si le plan change.
- `init-projet.sh --sans-claude` : ne copie ni `CLAUDE.md` ni rien sous `.claude/` et lance `sync.sh --sans-claude` ; sans l'option, comportement inchangé ; option inconnue : usage, code 64.
- `sync-claude.sh` : ne plante plus sous `set -u` en bash 3.2 quand aucun agent n'est généré.
- `scripts/tableau-de-bord.sh` : le fichier temporaire est supprimé en cas d'erreur ou d'interruption (Ctrl-C en `--boucle`) ; la page est écrite avec les droits de l'umask (plus 0600).
- `scripts/worktree-issue.sh` : le message « Aucune base trouvée » cite `origin/develop`.
- CI (dépôt et stacks) : plus de filtre `branches:` sous `pull_request:` (les PR empilées vers une branche `feat/` ont la CI) ; `push` reste limité à `main` et `develop`.
- Skill `deliver` : cas du correctif urgent (`hotfix/<slug>` depuis `main`, base `git merge-base HEAD main`, PR vers `main`, puis fusion dans `develop` par l'utilisateur).
- Dépôt de la factory (sans effet sur les projets) : `.github/workflows/ci.yml` racine propre à ce dépôt (job `verify` = `./scripts/verify-clean.sh`, job `secrets` gitleaks, mêmes empreintes que le modèle `aucune`) au lieu du modèle java-maven hérité ; `.github/dependabot.yml` racine limité à `github-actions` ; nouveau `.factory-verify` racine (`factory/scripts/tests/run.sh`) ; la suite des scripts neutralise `COMMANDE_VERIFY` et `STUB_CODE` hérités de l'environnement appelant. Les CI de `factory/stacks/*` sont inchangées par ce point.
- CI (dépôt et stacks) : chaque `actions/checkout` a `persist-credentials: false` (aucun job ne pousse ; le jeton ne reste pas dans `.git/config`), job gitleaks compris (il garde `fetch-depth: 0`). Empreintes inchangées.
- `scripts/verify-clean.sh` : le résumé reconnaît aussi la sortie de la suite de la factory (« TESTS OK : n vérifications », « TESTS EN ECHEC : x sur n ») au lieu de « Tests : inconnu ».
- Suite des scripts : la vérification « aucun ancien nom de fichier `.md` » ne passe plus à vide hors dépôt git (copie de `verify-clean.sh`, donc la CI) : repli sur `grep -r` avec les mêmes exclusions.
- Tests : 154 vérifications (45 nouvelles depuis 1.6.1).
- Migration : remplacer `factory/` (`sync-claude.sh` arrive avec le dossier), puis relancer `./factory/init-projet.sh` (met à jour `.factory-version` et les liens ; sans option, il crée `CLAUDE.md` et `.claude/` s'ils manquent, donc les agents de Claude Code). Projet sans Claude Code : relancer `./factory/init-projet.sh --sans-claude` à la place. Reporter la ligne `sync.sh` des Commandes dans l'`AGENTS.md` du projet. CI : retirer le filtre `branches:` sous `pull_request:` et ajouter `with: persist-credentials: false` à chaque `actions/checkout` (voir `factory/stacks/<stack>/.github/workflows/ci.yml`).

## 1.6.1
- Noms de fichiers `*.md` uniformisés en anglais (le contenu reste en français) : `docs/lecons.md` -> `docs/lessons.md`, `docs/issues/_modele.md` -> `docs/issues/_template.md` (et leurs modèles dans `factory/templates/`), `factory/LECONS.md` -> `factory/LESSONS.md`, `factory/DEMARRER-UN-PROJET.md` -> `factory/START-A-PROJECT.md`, `factory/MISE-A-JOUR.md` -> `factory/UPGRADE.md`. Références mises à jour partout (AGENTS.md et modèle, README, skills, prompts, `init-projet.sh`). Scripts, dossiers et stacks inchangés.
- `init-projet.sh` : si un projet a encore `docs/lecons.md` ou `docs/issues/_modele.md` sans le nouveau fichier, il affiche `à migrer` avec la commande `git mv` à lancer ; il ne renomme jamais seul et ne crée pas de doublon.
- Tests : 109 vérifications (11 nouvelles).
- Migration (projets déjà initialisés) :
  1. remplacer `factory/` et relancer `./factory/init-projet.sh` ;
  2. lancer les commandes `git mv` qu'il indique : `git mv docs/lecons.md docs/lessons.md` et `git mv docs/issues/_modele.md docs/issues/_template.md` ;
  3. dans `AGENTS.md` du projet, remplacer `docs/lecons.md` par `docs/lessons.md` (idem dans `docs/agents/issue-tracker.md` et `docs/issues/README.md` pour `_modele.md`) ;
  4. relancer `./factory/init-projet.sh` : plus aucun message `à migrer`.

## 1.6.0
- Modèle de branches standardisé : `main` = releases seulement (tags `vX.Y.Z`, l'utilisateur y fusionne `develop` avec `--no-ff`) ; `develop` = intégration, base et cible de toutes les branches de travail (`feat/`, `fix/`, `docs/`, `refactor/`, `test/`, `build/`) ; `hotfix/<slug>` part de `main` et est fusionné dans `main` puis dans `develop`. Les agents ne travaillent jamais sur `main` ni sur `develop`. Branches empilées inchangées. Règle « Modèle de branches » ajoutée à `AGENTS.md` (et son modèle), mentions dans les README, `DEMARRER-UN-PROJET.md`, le skill `deliver` (base = `git merge-base HEAD develop`) et les modèles de PR.
- `scripts/worktree-issue.sh` : base par défaut `develop` si elle existe, sinon `origin/develop`, sinon comportement précédent (`origin/HEAD`, `main`, `master`) ; `--base` reste prioritaire ; `nettoyer` vérifie la fusion dans cette base.
- CI (dépôt et stacks) : déclenchée sur push et pull request vers `main` et `develop`.
- `init-projet.sh` : rappelle le modèle de branches et la création de `develop` (il ne crée ni dépôt ni branche).
- Tests : 98 vérifications (10 nouvelles).
- Migration (projets déjà initialisés) :
  1. créer `develop` depuis `main` (`git branch develop main`) et la publier ;
  2. la définir comme branche par défaut sur GitHub (Settings > Branches) ;
  3. mettre à jour les règles de protection : `main` et `develop` protégées (PR et CI verte exigées, pas de commit direct) ;
  4. relancer `./factory/init-projet.sh` (met à jour `.factory-version`, rappelle le modèle) et reporter à la main la règle « Modèle de branches » dans `AGENTS.md` ainsi que la base `develop` dans `.github/pull_request_template.md` ;
  5. adapter la CI : `on.push.branches` et `on.pull_request.branches` à `[main, develop]` (voir `factory/stacks/<stack>/.github/workflows/ci.yml`) ;
  6. les PR ouvertes ciblant `main` sont à rebaser sur `develop`.

## 1.5.0
- Ajout de `scripts/tableau-de-bord.sh` : génère une page HTML statique (`tableau-de-bord.html`, ajoutée au `.gitignore`) des besoins du `backlog.md` et des issues de `docs/issues/`, par statut, avec compteurs, prochaine issue prête et rafraîchissement automatique. Options `--sortie`, `--attente`, `--boucle`. Sans modèle, sans dépendance, sans JavaScript ; texte échappé HTML.
- Migration : relancer `./factory/init-projet.sh` (lie le nouveau script) ; ajouter `tableau-de-bord.html` au `.gitignore` du projet.
