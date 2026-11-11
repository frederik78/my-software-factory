# Historique des versions

## 1.20.1
- `dashboard.sh` : un Kanban qui grossit ne rallonge plus la page. Chaque Kanban tient dans un viewport de 70 % de la hauteur de la fenêtre, avec ascenseurs vertical et horizontal, et les en-têtes de colonnes restent visibles pendant le défilement. À l'impression, la page s'étend comme avant.
- Colonne « Fait » triée de la plus récente à la moins récente : date du dernier commit du fichier de l'issue (à défaut, sa date de modification) ; pour un besoin, date de sa dernière issue. À date égale, l'ordre d'origine. Les autres colonnes gardent l'ordre des fichiers.
- Nouveauté, aucun changement de comportement incompatible.
- Migration : remplacer `factory/`.

## 1.20.0
- `criteres-sans-test.sh`, donc `fin-issue.sh` : une issue à `criteres: []` est acceptée quand son champ `criteres_justification:` est rempli (refactorisation sans changement de comportement) : `OK … aucun critère, justifié`. Tous les autres contrôles de `fin-issue.sh` restent (arbre propre, build, tests ignorés). Une liste vide sans justification reste une erreur, et une justification n'excuse jamais un critère déclaré sans test (leçon 36).
- `worktree-issue.sh creer` et `nettoyer` prennent la branche dans le champ `branche:` de l'issue, et le dossier en dérive (`refactor/001-22-x` donne `refactor-001-22-x`) ; s'il est vide, la branche reste `feat/<fichier d'issue>`. Un nom invalide (format Git, `..`, tiret initial) est refusé, code 64 (leçon 35).
- **Changement de comportement** : une issue dont le champ `branche:` diffère de `feat/<fichier>` reçoit désormais la branche de son en-tête. Le dashboard et `etat-issues.sh` suivaient déjà ce champ.
- Migration : remplacer `factory/`. Une issue de refactorisation à `criteres: []` ajoute `criteres_justification:` à son en-tête. Un worktree déjà créé sous l'ancien nom garde sa branche : renommez-la (`git branch -m`) pour qu'elle corresponde à l'en-tête, ou nettoyez-le avec `--force`.

## 1.19.1
- Correctif : depuis 1.19.0, l'encart « Autres travaux » de `dashboard.sh` répétait les worktrees des issues du Kanban, et l'encart des issues en cours perdait leur signal d'activité. Le descriptif ajouté aux lignes d'issue était lu comme une partie du nom de branche. Un worktree sur la branche d'une issue n'apparaît de nouveau que dans le Kanban.
- `LESSONS.md` : leçons 34 (champ ajouté à un format sans le remplir dans les tests), 35 (`worktree-issue.sh` ne lit pas le champ `branche:` de l'issue) et 36 (`fin-issue.sh` refuse une issue de refactorisation à `criteres: []`). Les correctifs des leçons 35 et 36 viendront dans une version suivante.
- Migration : remplacer `factory/`.

## 1.19.0
- `dashboard.sh` : les cartes du Kanban expliquent leur raison d'être. Une carte d'issue montre le premier paragraphe de la section `## Objectif` de son fichier ; une carte de besoin montre sa colonne « Décisions » du `backlog.md`. Texte échappé HTML, limité à 3 lignes (déplié au survol), absent si la source est vide : les cartes sans descriptif restent identiques.
- Nouveauté, aucun changement de comportement incompatible.
- Migration : remplacer `factory/`.

## 1.18.0
- `dashboard.sh` : thème `clair` (défaut, rendu inchangé), `sombre` ou `auto` (suit `prefers-color-scheme`), par la clé `DASHBOARD_THEME` (`.factory.conf`, `.factory.local.conf`, `FACTORY_DASHBOARD_THEME`) ou l'option `--theme` ; valeur invalide = code 64. Couleurs en variables CSS (deux palettes), `data-theme` de Pico et `color-scheme` suivent le thème ; impression toujours claire ; toujours aucune ressource externe ni JavaScript.
- Nouveauté, aucun changement de comportement incompatible. Seul écart visible : la page par défaut porte désormais `data-theme="light"`, pour que Pico ne passe pas en sombre tout seul sous un OS sombre.
- Migration : remplacer `factory/` ; facultatif : ajouter `DASHBOARD_THEME=clair|sombre|auto` à `.factory.conf`.

## 1.17.0
- `dashboard.sh` : mise en forme par Pico CSS (classless 2.0.6, licence MIT), embarqué dans la page depuis `factory/assets/pico.classless.min.css` (déclarations `url()` retirées) ; fond gris clair, titres de section soulignés, ombres légères sur cartes, colonnes et encarts, thème clair forcé. Toujours aucune ressource externe ni JavaScript, page lisible hors ligne ; si le fichier manque, la page garde son style d'origine.
- Nouveauté, aucun changement de comportement incompatible. La page grossit d'environ 70 Ko.
- Migration : remplacer `factory/` (le dossier `factory/assets/` est nouveau).

## 1.16.0
- `dashboard.sh` : encart « Autres travaux » après les issues. Une ligne par worktree dont la branche n'est le champ `branche:` d'aucune issue (`refactor/…`, `fix/…`, `docs/…`), avec `n fichiers non commités · activité il y a …` ; rien pour `develop`, `main` ni un HEAD détaché ; « Aucun autre travail. » s'il n'y en a pas. Ordre de `git worktree list`. Réutilise les signaux déjà calculés (aucun appel git de plus, jamais de verrou), git en échec = « état Git illisible », nom de branche échappé HTML. Sans modèle, sans JavaScript.
- Nouveauté, aucun changement de comportement incompatible.
- Migration : remplacer `factory/`.

## 1.15.1
- Correctif : `/deliver` ne prévoyait aucune étape pour le statut `En revue`, qui existait pourtant (cycle des issues, colonne du dashboard). L'orchestrateur passe maintenant l'issue à `En revue` (commit `docs: issue <id> en revue`) avant la première relecture, la remet `En cours` quand les corrections repartent au développeur (revue interne ou retour de revue externe), puis `En revue` avant la relecture suivante ; après la règle d'arrêt, l'issue reste `En revue`. Aucun script ne change.
- Migration : remplacer `factory/` ; une issue en cours de livraison reprend le cycle à sa prochaine relecture.

## 1.15.0
- `dashboard.sh` montre ce qui se passe en ce moment, sans modèle ni dépendance. Bandeau « Agents actifs » en haut de page : chaque sous-agent commencé et non terminé, avec son rôle, sa description et `depuis 12 min`, ou `sans nouvelles depuis 45 min` au-delà de `AGENTS_SILENCE_MINUTES` (5) sans preuve d'activité ; retiré au-delà de `AGENTS_RETRAIT_MINUTES` (60). Sur chaque issue qui a un worktree : `3 fichiers non commités · activité il y a 2 min` (`git status` sans verrou optionnel : jamais l'`index.lock` d'un agent).
- **Changement de comportement** : `sync-claude.sh` installe les hooks `SubagentStart` et `SubagentStop` (`factory/hook-agents-claude.sh`) dans `.claude/settings.local.json`, jamais dans `settings.json` versionné. Fusion prudente : une clé `hooks` déjà présente ou un fichier inexploitable n'est pas modifié, un avertissement donne le bloc à ajouter à la main. Sa dernière ligne annonce `agents actifs : oui|non`.
- Journal : `<git-common-dir>/factory-agents.log`, non versionné et commun à tous les worktrees ; format documenté en tête du hook et de `dashboard.sh`. La description vient de `subagents/agent-<id>.meta.json`, fichier non documenté par Anthropic : s'il manque ou change de forme, le bandeau affiche le rôle seul.
- Limites : une ligne `fin` écrite pendant la rotation du journal (plus de 2000 lignes réduites à 1000) peut être perdue, l'agent reste alors « sans nouvelles » jusqu'au retrait (60 min par défaut) ; l'âge d'activité d'un worktree ne voit pas la modification d'un fichier existant dans un dossier entièrement non suivi (`dir/` pour git status, `-uall` serait trop coûteux) ; git en échec s'affiche « état Git illisible ». `AGENTS_SILENCE_MINUTES` supérieur ou égal à `AGENTS_RETRAIT_MINUTES` est permis : l'état « sans nouvelles » n'existe alors pas.
- `sync-claude.sh` conserve le mode du `settings.local.json` existant et ne remplace jamais un lien symbolique (avertissement avec le bloc à ajouter).
- Une valeur invalide de `AGENTS_SILENCE_MINUTES` ou `AGENTS_RETRAIT_MINUTES` (entier entre 1 et 999999) arrête `dashboard.sh` en code 64.
- Migration : remplacer `factory/`, relancer `./factory/init-projet.sh` si besoin, lancer `./factory/sync.sh`, ajouter `AGENTS_SILENCE_MINUTES=5` et `AGENTS_RETRAIT_MINUTES=60` à `.factory.conf` (facultatif : ce sont les défauts), vérifier que `.claude/settings.local.json` est ignoré par git, puis relancer la session Claude Code pour qu'elle lise les hooks.
- `LESSONS.md` : leçon n° 33.

## 1.14.0
- Correctif : `criteres-sans-test.sh` répondait `OK` pour n'importe quelle mention dans le dossier de tests. Une Javadoc citant un critère masquait le retrait de son seul test. Seuls comptent maintenant le nom ou le titre d'une déclaration de test en Java, Kotlin, Python ou Node ; les limites restantes sont dans l'en-tête du script.
- **Changement de comportement** : un critère cité seulement dans un commentaire, une chaîne ou un fichier de données passe à `MANQUE`, et le script répond 1 ; une fonction Python sans préfixe `test` ou une méthode Java privée aussi. Un projet dans un autre langage voit tous ses critères à `MANQUE`.
- `LESSONS.md` : leçon n° 29.
- `scripts/fin-issue.sh <issue> [-- <arguments>]` : contrôle exécuté en fin d'issue, exigé par `/deliver` avant `Fait`, sur un arbre propre et le commit affiché. Un test ignoré sans décision, un nombre illisible ou un fichier non suivi non ignoré est un échec. Clés `FIN_ISSUE_ARGUMENTS` et `FIN_ISSUE_IGNORES_AUTORISES`.
- `verify-clean.sh` : additionne les résumés Maven (plusieurs modules ou greffons, seul le dernier était lu) et ajoute le verdict de unittest au résumé.
- `MAX_ITERATIONS_REVUE` passe de 5 à 3 par défaut, car 5 relectures prennent trop de temps. Un projet existant garde la valeur de son `.factory.conf` ; pour adopter 3, il la change lui-même.
- Vitesse : le relecteur ne mute que les garde-fous nouveaux ou modifiés de la passe, 8 au plus, et liste les autres ; le développeur lance des tests ciblés avant chaque commit intermédiaire, et `fin-issue.sh` complet avant son rapport.
- Un worktree par issue, même seule, de préférence sur un clone bare : `worktree-issue.sh initialiser <source> <conteneur>` (clone bare, `origin`, refspec, fetch ; conteneur existant refusé) ; `creer` place le dossier dans `<conteneur>/<branche avec / remplacé par ->` et lance `factory/sync.sh`. Dépôt classique : emplacement inchangé, avec un avertissement.
- `fin-issue.sh` et `verify-clean.sh`, après revue : échecs contrôlés même avec un build au code 0 ; arguments signalés dans la ligne `OK` ; non suivis vus quelle que soit la configuration de git, fichiers `skip-worktree` et `assume-unchanged` refusés ; critères lus dans le commit ; suites unittest additionnées ; jest et node:test lus. Vitest et mocha : `inconnu`.
- `worktree-issue.sh`, après revue : `nettoyer` protège un HEAD détaché et les fichiers ignorés hors artefacts ; `initialiser` règle le suivi amont, masque les identifiants de l'URL, refuse un conteneur dans la source ; un identifiant d'issue doit être exact.
- Sécurité : une entrée externe naît avec ses contrôles (`to-tickets`) ; tableau des entrées externes au rapport ; pièges Java dans `owasp-check` ; risque reporté décidé par l'utilisateur, au backlog ; revue finale sans la liste des mineurs.
- Correctif : `verify-clean.sh` ne lisait que le premier type de résumé. Maven puis jest, ou jest en échec puis pytest enchaînés par `;`, donnaient `FIN-ISSUE OK`. Plusieurs types de résumé rendent maintenant le résumé illisible, donc `fin-issue.sh` en échec ; le code de `verify-clean.sh` reste celui du build. Un même lanceur répété s'additionne toujours.
- **Changement de comportement** : un projet qui enchaîne deux lanceurs dans `.factory-verify` passe à `FIN-ISSUE ECHEC`, sauf `FIN_ISSUE_IGNORES_AUTORISES=inconnu`. Les motifs de résumé sont aussi plus stricts : une ligne de journal comme `=== build failed ===` n'est plus lue comme un résumé.
- `dashboard.sh` lit aussi le statut de chaque issue sur sa branche locale (champ `branche:`), garde le plus avancé du cycle et affiche le dernier commit de la branche : depuis `develop`, une issue en livraison ne reste plus à `À faire`. `etat-issues.sh --prochaine` ne propose plus une issue commencée sur sa branche. Une dépendance ne compte `Fait` qu'une fois fusionnée. Limite : le statut ne dit pas si un agent tourne encore, et le travail non commité n'est pas vu.
- `MAX_CRITERES_ISSUE` (10 par défaut, `scripts/config-factory.sh --max-criteres`) : `couverture-prd.sh` avertit pour une issue plus grosse sans changer son code de sortie, sauf champ `criteres_justification:` non vide. Une valeur invalide donne le code 64. Règle dans `to-tickets`, `spec-writer.md` et `UPGRADE.md` : environ 10 critères, ordre de grandeur et non mesure.
- **Changement de comportement** : les agents passent par défaut à `sonnet` avec l'effort `medium` (`AGENT_MODELE`, `AGENT_EFFORT`), au lieu de `opus` et `low`. Un projet dont `.factory.conf` ou `.factory.local.conf` fixe ces clés (le modèle les y écrit) garde sa valeur ; un projet qui ne les définit pas passe à `sonnet` et `medium` après la mise à jour de `factory/` et `sync-claude.sh`.
- Correctif : `verify-clean.sh` ne vérifiait pas `mktemp` ; avec un dossier temporaire inutilisable, la copie valait `/src` et, sous root dans un conteneur où `/src` est un dépôt, le build relançait la suite de la factory en boucle. Il s'arrête maintenant (code 1, « Copie temporaire impossible »). `tests/run.sh` refuse en outre de se relancer lui-même (`FACTORY_TESTS_EN_COURS`).
- `LESSONS.md` : leçons n° 30 à 32.
- Migration : remplacer `factory/`, lancer `scripts/criteres-sans-test.sh --tous`, renommer les tests signalés, relancer `./factory/init-projet.sh` (lien `scripts/fin-issue.sh`), ajouter les clés `FIN_ISSUE_*` à `.factory.conf`, ignorer ou commiter les fichiers non suivis (`.vscode/` par exemple), reprendre les lignes `criteres-sans-test`, `fin-issue` et `worktree-issue` dans `AGENTS.md`, puis, si vous adoptez la structure bare, lancer `initialiser` et recréer les fichiers non suivis dans chaque worktree.

## 1.13.0
- Règle « Langue du code » : les classes techniques sont impérativement en anglais. Dans `AGENTS.md`, `developer.md` et le guide java ; en revue, une classe technique dans une autre langue est un constat IMPORTANT.
- `LESSONS.md` : leçon n° 28.
- Migration : remplacer `factory/`, relancer `./factory/init-projet.sh`, puis reprendre la ligne « Langue du code » dans `AGENTS.md`.

## 1.12.0
- Applications Spring Boot : dépendances Spring d'abord, JHipster comme modèle pour l'emplacement, les noms et la forme du code. `stacks/java-maven/README.md` dit quel exemple et quels fichiers lire selon l'authentification et le frontend (aucun, Angular, React, Vue), un fichier à la fois, sans générateur ni clone.
- Règle générale « La référence de code » : l'ADR fixe un projet et sa version ; chaque écart a une raison. Section « Alignement sur la référence » du rapport, contrôlée par `/deliver` ; écart sans raison = constat IMPORTANT en revue ; champ dans les briefs et le modèle d'ADR.
- `LESSONS.md` : leçon n° 27.
- Migration : remplacer `factory/`, relancer `./factory/init-projet.sh`, reprendre la ligne « La référence de code » dans `AGENTS.md` et fixer la référence dans l'ADR d'architecture.

## 1.11.0
- Règle « Le framework d'abord » : avant d'écrire un mécanisme transversal, chercher ce que fournit le framework dans la version utilisée et lire le code de la référence nommée par l'ADR. Un équivalent à la main se justifie par un critère du PRD ou une mesure.
- Contrôle à chaque étape : section « Code écrit à la place du framework » du rapport du développeur, vérifiée par `/deliver` ; section « Framework » de la revue, où un équivalent injustifié est un constat IMPORTANT ; champ dans les briefs ; rubrique dans le modèle d'ADR.
- `stacks/java-maven/README.md` : table des mécanismes Spring et de la référence JHipster à consulter.
- `LESSONS.md` : leçon n° 26.
- Tests : 273 vérifications.
- Migration : remplacer `factory/`, relancer `./factory/init-projet.sh`, puis reprendre la ligne « Le framework d'abord » dans `AGENTS.md` (`diff factory/templates/AGENTS.md AGENTS.md`), qui n'est pas écrasé.

## 1.10.0
- Modèle et effort des agents configurables : `AGENT_MODELE` (`opus` par défaut) et `AGENT_EFFORT` (`low` par défaut), aux trois niveaux habituels (`.factory.conf`, `.factory.local.conf`, `FACTORY_*`). `sync-claude.sh` les écrit dans les enveloppes `.claude/agents/`. Valeur vide : l'agent hérite de la session. L'en-tête d'un prompt l'emporte pour son rôle.
- Sécurité : une valeur hors format est refusée (code 64), sans modifier les enveloppes, pour qu'elle n'ajoute aucun champ à l'en-tête YAML.
- **Changement de comportement** : sans configuration, les agents ne suivent plus le modèle de la session, ils passent en Opus avec un effort faible. Pour garder l'ancien comportement : `AGENT_MODELE=` et `AGENT_EFFORT=`.
- `LESSONS.md` : leçon n° 25.
- Tests : 263 vérifications.
- Migration : remplacer `factory/`, relancer `./factory/init-projet.sh`, puis ajouter si besoin les deux clés à `.factory.conf` ; il n'est pas écrasé.

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
