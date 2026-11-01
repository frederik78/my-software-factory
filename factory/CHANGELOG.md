# Historique des versions

## 1.9.2
- Correctif : `factory/scripts/tests/run.sh` passe dans un projet. Les 5 vérifications de la racine (CI, `.factory-verify`, Dependabot) ne s'exécutent que dans le dépôt de la factory, repéré par le fichier `.factory-depot`, qui n'est jamais copié dans un projet.
- `LESSONS.md` : leçon n° 24.
- Tests : 252 vérifications dans le dépôt de la factory (3 de plus) ; un projet en exécute 5 de moins, et le signale.
- Migration : remplacer `factory/` ; rien d'autre à faire.

## 1.9.1
- Correctif : la CI de la stack `java-maven` n'échoue plus avant l'issue socle. Sans `pom.xml`, `setup-java` et `./mvnw` sont ignorés et le job l'indique par une notice. Le job `securite` suit la même règle.
- `LESSONS.md` : leçon n° 23.
- Tests : 249 vérifications (2 de plus).
- Migration : remplacer `factory/`. Un projet existant reprend le changement à la main (`diff -r factory/stacks/java-maven/.github .github`), inutile s'il a déjà son `pom.xml`.

## 1.9.0
- Architecture par défaut : des couches de services, avec des interfaces seulement aux frontières externes à doubler. Un autre style se justifie dans l'ADR (`START-A-PROJECT.md`, `templates/AGENTS.md`).
- Architecture de référence pour Spring Boot dans `stacks/java-maven/README.md` : structure, droits d'accès entre couches, règles ArchUnit, tests par couche.
- `LESSONS.md` : leçons n° 18 à 22, issues du cadrage d'un deuxième projet ; seule la n° 20 est appliquée dans cette version.
- Migration : remplacer `factory/` ; un projet existant garde son ADR, et le modèle d'`AGENTS.md` ne le remplace pas.

## 1.8.1
- Correctif : `scripts/notifier.sh` n'émet plus « write error: Broken pipe » quand la commande d'envoi échoue sans lire le message (CI rouge sous Linux, où SIGPIPE est ignoré). Le message complet est écrit dans un fichier temporaire (`mktemp` dans `TMPDIR`, droits 0600, supprimé à la sortie, y compris après un échec ou une interruption), puis donné à la commande par redirection, sans tube. Codes de sortie, en-têtes, encodage RFC 2047 et exécution sans `eval` inchangés ; nouveau cas d'échec (code 4) si le fichier temporaire ne peut pas être préparé.
- Tests : 247 vérifications (6 de plus). Le cas « commande en échec » est rendu déterministe : commande qui se termine sans lire, corps de 1,1 Mo (plus grand que le tampon d'un tube) et SIGPIPE ignoré comme sur GitHub Actions ; il échouait avant le correctif sur macOS comme sous Linux. Fichier temporaire : un seul, en 0600, pendant l'envoi ; aucun après un envoi réussi, un échec ou un SIGTERM.
- Migration : remplacer `factory/` ; rien d'autre à faire.

## 1.8.0
- Le tableau de bord devient le « dashboard » : `factory/scripts/dashboard.sh` (lien `scripts/dashboard.sh`) écrit par défaut `dashboard.html`, titrée « Dashboard » ; `.gitignore` du modèle et documentation mis à jour. `init-projet.sh` signale tout lien mort de `scripts/` vers `factory/scripts/` (script retiré ou renommé) par « à supprimer <lien> … : rm <lien> », sans rien supprimer.
- `scripts/dashboard.sh` affiche un Kanban qui identifie les issues au lieu de les compter : un encart « En cours » en haut de page (issues `En cours` et `En revue`, référence et titre, ou « Aucune issue en cours. ») ; sections « Besoins » et « Issues » en colonnes, une par statut du cycle dans l'ordre (backlog : À faire, En clarification, Spécifié, En cours, En revue, Fait ; issues : À faire, En cours, En revue, Fait), en-tête coloré « Statut (n) », « — » pour une colonne vide, colonne « (autre) » seulement si un statut est hors cycle.
- Carte d'issue : référence en gras, titre, besoin `F-xx`, « dépend de : … », marqueur « prochaine » (issue désignée par `etat-issues.sh --prochaine`) et « bloquée » (issue `À faire` dont une dépendance n'est pas `Fait`) ; cartes dans l'ordre des fichiers. Carte de besoin : ID, libellé, priorité, « PRD : … » s'il est renseigné.
- Les compteurs et les tables disparaissent (redondants avec les en-têtes de colonnes) ; la ligne « Prochaine issue prête » est conservée. Mise en page CSS seule (grid, colonnes de largeur égale, défilement horizontal de la section sur écran étroit, impression en grille repliée), toujours sans JavaScript ni ressource externe, tout texte échappé HTML. Options, codes de sortie, écriture atomique et droits inchangés.
- Limite des allers-retours développeur <-> relecteur : `MAX_ITERATIONS_REVUE` (5 par défaut, au lieu de 3 écrit en dur) dans `/deliver` (revue interne et revue externe), `AGENTS.md` et son modèle (étape 4, et étape 5 : même limite pour les corrections après `/code-review`), le README et le brief du reviewer (« itération n sur max »). Au-delà, la session s'arrête et remonte le blocage ; s'il reste au moins un BLOQUANT, elle envoie aussi un courriel par `scripts/notifier.sh` (sujet « [factory] <issue> bloquée après N revues », corps : constats bloquants restants, branche, chemin de `docs/reviews/`), s'il ne reste que des IMPORTANT, pas de courriel ; si la notification n'est pas configurée (code 3) ou échoue (code 4), elle le dit dans la conversation.
- Configuration de la factory à trois niveaux : `.factory.conf` (versionné, créé par `init-projet.sh` depuis le modèle, jamais écrasé), `.factory.local.conf` (mêmes clés, ignoré par git : ajouté au `.gitignore` du modèle et de ce dépôt), variables `FACTORY_<CLÉ>`. Clés : `MAX_ITERATIONS_REVUE`, `NOTIFICATION_COMMANDE`, `NOTIFICATION_DESTINATAIRE`, `NOTIFICATION_EXPEDITEUR`. Une clé présente avec une valeur vide l'emporte sur les niveaux inférieurs (moyen de désactiver localement un réglage commun). Les fichiers ne sont jamais sourcés : lus ligne à ligne (`CLÉ=valeur`, clés connues seulement, indentation et espaces autour de `=` tolérés, valeur sans ses espaces de bord) par `factory/scripts/lib-config.sh` (`config_valeur <clé> <défaut>`).
- Nouveau `scripts/config-factory.sh` : configuration effective (clés connues seulement) ; `--max-iterations` affiche la limite (entier >= 1, sinon code 64).
- Nouveau `scripts/notifier.sh --sujet S [--corps-fichier F]` (corps sur l'entrée standard sinon) et `--test` : passe le message (From si renseigné, To, Subject, en-têtes MIME UTF-8, corps) sur l'entrée standard de `NOTIFICATION_COMMANDE` (ex. `msmtp -a <compte>`, `sendmail -oi`, script curl ; jamais l'option `-t` de sendmail ou de mail, qui selon l'implémentation ignore ou double le destinataire passé en argument), destinataire en dernier argument ; commande découpée en mots et exécutée sans `eval` ni `sh -c` ; CR/LF du sujet et de l'expéditeur neutralisés ; destinataire avec espace, caractère de contrôle ou « - » initial refusé. Sujet non ASCII encodé RFC 2047 (`=?UTF-8?B?…?=`, pliés en lignes de 76 caractères au plus, « Subject: » compris, coupés sur des caractères UTF-8 entiers), de même que le nom non ASCII d'un expéditeur « Nom <adresse> » ; sujet ASCII inchangé. Codes : 0 envoyé, 3 non configuré, 4 échec de la commande, 64 usage. Les secrets restent dans la configuration de l'outil d'envoi.
- `init-projet.sh` : crée `.factory.conf`, rappelle de renseigner `.factory.local.conf` tant que la notification n'est pas configurée, et signale la ligne `.factory.local.conf` à ajouter à un `.gitignore` existant (sans le modifier).
- Tests : 241 vérifications (87 de plus que les 154 de la 1.7.0 : dashboard Kanban et renommage, configuration, notification dont RFC 2047, initialisation et documentation). Les vérifications de documentation de la suite lisent ce dépôt depuis `HEAD` quand c'est un dépôt git (une modification non commitée n'y est pas vue ; commitez avant de lancer la suite), sinon les fichiers (copie de `verify-clean.sh`) : la suite ne dépend plus d'un fichier modifié pendant son exécution.
- Migration : remplacer `factory/`, puis relancer `./factory/init-projet.sh` (crée `.factory.conf` et lie `scripts/config-factory.sh`, `scripts/notifier.sh`, `scripts/lib-config.sh` ; lie `scripts/dashboard.sh` et signale l'ancien lien, devenu mort : supprimez-le avec `rm scripts/tableau-de-bord.sh`). Dans le `.gitignore` du projet, remplacer `tableau-de-bord.html` par `dashboard.html`, et supprimer un éventuel ancien `tableau-de-bord.html` (`rm tableau-de-bord.html`). Un outil qui analysait les tables de la page doit lire les cartes (`<div class="carte">`). Ajouter `.factory.local.conf` au `.gitignore` du projet, y renseigner `NOTIFICATION_COMMANDE` et `NOTIFICATION_DESTINATAIRE`, puis `scripts/notifier.sh --test`. Dans l'`AGENTS.md` du projet, remplacer « 3 itérations au plus » (étapes 4 et 5 de la Séquence) et ajouter les deux scripts aux Commandes (voir `factory/templates/AGENTS.md`).

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
