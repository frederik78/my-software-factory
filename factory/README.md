# Software Factory : guide d'utilisation

La factory est un dossier `factory/` que l'on copie dans un projet. Elle fournit une chaîne de travail complète, de l'idée au code fusionné, avec des agents (développeur, reviewer, analyste), des skills, des scripts de contrôle et des modèles de fichiers. Tout est en Markdown et en shell : rien ne dépend d'un éditeur ou d'un fournisseur, sauf ce qui est propre à Claude Code (`sync-claude.sh`, `.claude/settings.json`, `CLAUDE.md` : voir § 9).

Version courante : voir `factory/VERSION` ; historique : `CHANGELOG.md`.

**Sommaire** : 1 En deux minutes · 2 Prérequis · 3 Démarrer un projet · 4 Cycle d'un besoin · 5 Commandes et scripts · 6 Règles à retenir · 7 Contenu du dossier · 8 Choisir ou adapter la stack · 9 Indépendance du fournisseur · 10 Permissions et limites ·
11 Dépannage · 12 Mettre à jour la factory · 13 Arborescence d'un projet · 14 Formats de référence · 15 Exemple de session · 16 Cas courants · 17 Étendre la factory · 18 Glossaire · 19 Ce qui est éprouvé

## 1. En deux minutes

```
idée -> cadrage (/grill-with-docs) -> ADR (architecture, stack) -> PRD (agent spec-writer) -> issues (/to-tickets)
     -> pour chaque issue : /deliver  (developer TDD <-> code-reviewer, contrôles de la session)
     -> /code-review de la branche -> fusion dans develop par vous (git merge --no-ff) -> clôture (documents à jour, leçons)
```

Les rôles de chacun :

| Qui | Fait | Ne fait jamais |
|---|---|---|
| **Vous** | Cadrage, validation de l'ADR et du PRD, décisions de fond, fusion | |
| **Session principale** (Claude Code) | Joue l'orchestrateur (section « Orchestration » d'`AGENTS.md`) : lance les agents, recoupe leurs rapports avec le dépôt, décide des corrections | Coder elle-même, pousser, fusionner |
| **`spec-writer`** | Rédige le PRD (comportement, contrats, critères, sécurité) | Coder, vous interviewer |
| **`developer`** | Code en TDD, commits atomiques, rapport | Pousser, fusionner |
| **`code-reviewer`** | Relit en lecture seule, avec la checklist OWASP, mutations des tests | Modifier le code |

Les quatre **phases** d'une issue, comme une chaîne de fabrication. Ce sont des repères, **pas des agents** : les trois seuls agents sont
`spec-writer`, `developer` et `code-reviewer` ; chaque phase est réalisée par un agent, par la session principale, par un script, ou par vous. Les « étapes » numérotées du § 4 décrivent, elles, le cycle d'un besoin entier.

| Phase | Ce qui se passe | Réalisée par | Nature | Où dans la factory |
|---|---|---|---|---|
| **Isoler** | L'issue a sa branche et, si d'autres agents travaillent en même temps, son propre dossier de travail ; rien n'est construit sur `main` ni sur `develop` | La session principale | Script et consigne de `/deliver` | `scripts/worktree-issue.sh`, `/deliver` étape 0 |
| **Construire** | Le développeur code en TDD, dans une structure lisible par quelqu'un sans contexte | Agent `developer` | Agent | `prompts/developer.md`, `AGENTS.md`, ADR |
| **Prouver** | Preuve avant / après, tests de garde-fous prouvés par mutation, rapports recoupés avec le dépôt, relecture | `developer` (fournit la preuve), `code-reviewer` (la vérifie), la session (recoupe) | Agents, session et scripts | `report-format.md`, `scripts/*.sh` |
| **Livrer** | Définition de fini, PR avec sa preuve, retour de revue externe facultatif, fusion | La session principale, puis vous (fusion) | Skill `/deliver` et décision humaine | `/deliver` étapes 4 bis et 5, `.github/pull_request_template.md` |

## 2. Prérequis
- Un dépôt Git, **bash**, **rsync** (macOS ou Linux ; les scripts fonctionnent avec le bash 3.2 de macOS).
- Claude Code pour les agents et les skills. D'autres outils peuvent lire les prompts et les skills (voir § 9).
- Une stack au choix : modèles fournis pour `java-maven`, `python` et `node`, squelette neutre pour toute autre (`aucune`) ; voir § 3 et § 8.

## 3. Démarrer un projet (une fois)

1. Copiez le dossier `factory/` dans votre dépôt (ou partez d'un dépôt qui le contient déjà).
2. Lancez, depuis la racine du dépôt :
   ```
   ./factory/init-projet.sh --nom "Nom du projet" --stack java-maven     # ou python, node, aucune (défaut)
   ```
   Cela crée, **sans jamais rien écraser** (relançable) : `README.md`, `AGENTS.md`, `CLAUDE.md`, `GLOSSARY.md`, `backlog.md`, `docs/` (adr, prd, issues, reviews, agents, `lessons.md`), les fichiers de la stack (CI, Dependabot, `.factory-verify`, lignes du `.gitignore`),
   `.claude/settings.json` (refus de permissions), `.gitignore`, `.factory-version`, les liens `scripts/`, puis les alias de skills et les agents.
3. Ouvrez le projet dans Claude Code : les skills (`/deliver`, `/grill-with-docs`, `/to-tickets`…) et les agents sont disponibles.
4. Si les agents n'apparaissent pas (après un clone par exemple) : `./factory/sync.sh`.

La checklist détaillée du démarrage (garde-fous à mettre en place avant la première issue) est dans `START-A-PROJECT.md`.

## 4. Cycle d'un besoin

### Vue d'ensemble du cycle : qui fait quoi

L'**orchestrateur** n'est ni un agent ni un skill : c'est le **rôle de la session principale** (Claude Code où vous travaillez), décrit dans la section « Orchestration » d'`AGENTS.md`. Le skill `/deliver` n'en est qu'une partie, la boucle de livraison d'*une* issue.
Les trois seuls agents sont `spec-writer`, `developer` et `code-reviewer`. La session reste l'orchestrateur parce que seule elle peut vous poser des questions (les sous-agents n'ont pas d'outil de question) et recouper les rapports avec le dépôt (§ 10).

| # | Étape | Qui / quoi | Votre rôle |
|---|---|---|---|
| 1 | **Cadrage** : glossaire, contraintes, ADR de stack et d'architecture | Skill `/grill-with-docs` | Vous répondez, vous validez l'ADR |
| 2 | **PRD** | Agent `spec-writer` | Vous répondez à ses `## QUESTIONS`, vous validez le PRD |
| 3 | **Découpage en issues** | Skill `/to-tickets`, puis `scripts/couverture-prd.sh` | Vous approuvez le découpage |
| 4 | **Livraison**, une issue après l'autre | Skill `/deliver` (qui lance `developer` et `code-reviewer`) | Vous tranchez les décisions de fond |
| 5 | **Revue de la branche** | `/code-review` | |
| 6 | **Fusion et clôture** | Vous (`git merge --no-ff` dans `develop`) | Vous fusionnez |

Ce n'est donc pas « `spec-writer` puis `/deliver` » : le cadrage vient avant (sans lui, `spec-writer` n'a ni glossaire ni ADR, et il ne vous interroge pas), et le découpage vient entre les deux (sans lui, `/deliver` n'a pas d'issue à livrer).
Vous n'avez pas à retenir cette suite : la session la lit dans `AGENTS.md` à chaque démarrage. Vous pouvez dire « Traite le besoin F-01 » ; les commandes à taper vous-même sont `/grill-with-docs`, `/to-tickets` et `/deliver`.

### Étape 1 : cadrer (avec vous, avant tout code)
1. Remplissez `backlog.md` : contexte, contraintes, besoins (`F-01`…).
2. Lancez `/grill-with-docs` (ou `/grill-me`) : une interview qui produit le glossaire (`GLOSSARY.md`) et des ADR.
3. Rédigez et faites valider **l'ADR d'architecture et de stack** (`docs/adr/0001-…`, format `0000-template.md`), puis complétez `AGENTS.md`. L'architecture ne change plus sans nouvel ADR : la changer après coup coûte un refactor de tout le code.

### Étape 2 : spécifier
Demandez : « Utilise l'agent spec-writer pour écrire le PRD du besoin F-01 ». Il produit `docs/prd/NNN-module.md` :
comportement, contrats, règles de gestion, critères d'acceptation `- **CA-01** Given … When … Then …`, critères de sécurité `- **CS-01**`, section sécurité (OWASP).
- Le PRD décrit le QUOI, jamais la structure du code (aucun nom de package ni de classe).
- Il ne vous interroge pas : il marque les lacunes `[À CLARIFIER Q-xx]` et les liste dans un bloc `## QUESTIONS`. La session principale vous les pose ; vous répondez, il corrige. Vous validez le PRD.

### Étape 3 : découper en issues
Lancez `/to-tickets` : une issue par fichier dans `docs/issues/` (format de `_template.md`), avec ses critères (`criteres`), ses dépendances (`depend_de`) et un statut. Puis :
```
scripts/couverture-prd.sh docs/prd/NNN-module.md
```
doit répondre `OK` : chaque critère du PRD est couvert par exactement une issue. Vous approuvez le découpage.

### Étape 4 : livrer chaque issue
```
/deliver 001-01          # ou : /deliver (la prochaine issue prête : scripts/etat-issues.sh --prochaine)
```
La session principale :
1. vérifie les dépendances, crée la branche `feat/<prd>-<nn>-<slug>`, passe l'issue `En cours` ;
2. lance le **developer** avec un brief complet (TDD, un test RED avant chaque code, tests nommés d'après les critères) ;
3. **recoupe** son rapport : `git log`, arbre propre, `scripts/verify-clean.sh`, `scripts/criteres-sans-test.sh` ;
4. lance le **code-reviewer** (build en copie propre, mutations des tests, OWASP), et archive son rapport dans `docs/reviews/<issue>.md` ;
5. renvoie les points BLOQUANT et IMPORTANT au développeur (`MAX_ITERATIONS_REVUE` itérations au plus, 5 par défaut, voir `.factory.conf`) ; vous consulte pour les décisions de fond ; au-delà, s'arrête et vous remonte le blocage, avec un courriel par `scripts/notifier.sh` (si configuré) seulement s'il reste au moins un BLOQUANT ;
6. passe l'issue à `Fait` si la définition de fini est remplie, puis vous fait un compte rendu court (commits, résultats chiffrés, décisions en attente).

Détail : `skills/deliver/SKILL.md`. Les décisions que le PRD ne fixait pas sont listées dans les Notes de l'issue : vous les tranchez, puis elles entrent dans le PRD.

### Étape 5 : clôturer
1. `/code-review` sur la branche entière (standards et conformité) ; ses constats bloquants repartent au développeur, avec la même limite de `MAX_ITERATIONS_REVUE` itérations.
2. **Vous fusionnez** dans `develop` : `git merge --no-ff feat/…` (les agents ne poussent ni ne fusionnent). La PR a pour base `develop`. Pour publier une release, vous fusionnez `develop` dans `main` (`git merge --no-ff develop`) puis vous taguez `vX.Y.Z`.
3. Passez le besoin à `Fait` dans `backlog.md` ; mettez à jour les passages du PRD, du backlog et des ADR devenus faux ; ajoutez les leçons à `docs/lessons.md`.

## 5. Commandes et scripts

| Commande | Rôle |
|---|---|
| `/grill-with-docs`, `/grill-me` | Cadrage par interview |
| `/to-tickets` | Découpage du PRD en issues |
| `/deliver [issue]` | Livraison d'une issue (développement, revue, corrections) |
| `/code-review` | Revue de la branche (standards et conformité à l'issue) |
| `/tdd`, `/diagnosing-bugs`, `/research`, `/prototype` | À la demande |
| `scripts/verify-clean.sh [--keep]` | Build complet dans une copie propre, hors IDE, limitée aux fichiers vus par Git |
| `scripts/criteres-sans-test.sh <issue>` | Critères d'une issue qu'aucun test ne mentionne (`--tous` : toutes les issues commencées) |
| `scripts/couverture-prd.sh <prd>` | Chaque critère du PRD couvert par une seule issue |
| `scripts/etat-issues.sh [--statut S] [--prochaine]` | État des issues lu dans leurs en-têtes ; prochaine issue prête |
| `scripts/dashboard.sh [--sortie F] [--attente S] [--boucle S]` | Page HTML en Kanban des besoins du `backlog.md` et des issues (une colonne par statut, une carte par élément, encart « En cours », marqueurs « prochaine » et « bloquée ») ; `--boucle` la régénère en continu |
| `scripts/worktree-issue.sh creer\|nettoyer\|lister <issue>` | Une issue dans son propre dossier de travail (`git worktree`), sur sa branche ; `nettoyer` après la fusion |
| `scripts/config-factory.sh [--max-iterations]` | Configuration effective de la factory (`.factory.conf`, `.factory.local.conf`, variables `FACTORY_*`) ; `--max-iterations` : limite des revues |
| `scripts/notifier.sh --sujet S [--corps-fichier F] \| --test` | Courriel par la commande configurée (issue bloquée après `MAX_ITERATIONS_REVUE` revues) ; `--test` : message d'essai |
| `factory/scripts/tests/run.sh` | Tests des scripts de la factory (247 vérifications) |
| `./factory/sync.sh [--claude\|--sans-claude]` | Recrée le lien `.agents/skills` (neutre) puis, si le projet a un `CLAUDE.md` (le seul dossier `.claude/` ne suffit pas), appelle `sync-claude.sh` |
| `./factory/sync-claude.sh` | Propre à Claude Code : lien `.claude/skills` et agents générés depuis les en-têtes de `factory/prompts/` |
| `./factory/init-projet.sh [--sans-claude]` | Initialise un projet (sans rien écraser) ; `--sans-claude` : ni `CLAUDE.md` ni `.claude/` |

### Détail des scripts
Quatorze scripts, en trois groupes : mise en place (3), contrôle et suivi d'une livraison (8), outils internes (3). Les `scripts/*.sh` à la racine d'un projet sont des liens vers `factory/scripts/` : la source est unique.

**Mise en place (vous les lancez)**

| Script | À quoi il sert | Quand |
|---|---|---|
| `factory/init-projet.sh` | Prépare un projet : `README.md`, `AGENTS.md`, `backlog.md`, `docs/`, modèle de PR, `.factory.conf` (rappelle de renseigner `.factory.local.conf` pour les notifications ; signale la ligne `.factory.local.conf` à ajouter à un `.gitignore` existant), et les fichiers de la stack choisie (CI, Dependabot, `.factory-verify`, lignes du `.gitignore`). Ne remplace jamais un fichier existant ; lie les scripts dans `scripts/` (un lien mort vers un script retiré ou renommé est signalé « à supprimer » avec la commande `rm`, jamais supprimé), écrit `.factory-version`, appelle `sync.sh`. Les scripts `factory/*.sh` ne sont pas liés dans `scripts/` : ils se lancent depuis `factory/`. Option `--stack java-maven\|python\|node\|aucune` ; `--sans-claude` ne crée ni `CLAUDE.md` ni rien sous `.claude/` et lance `sync.sh --sans-claude` (option inconnue = code 64). | Au départ, puis après une mise à jour de la factory |
| `factory/sync.sh` | Neutre : crée le lien `.agents/skills`, puis appelle `sync-claude.sh` si le projet a un `CLAUDE.md`, pas sur le seul dossier `.claude/` (`--claude` force l'appel, `--sans-claude` l'interdit ; autre option = code 64). | Après un clone, ou après modification d'un prompt |
| `factory/sync-claude.sh` | Propre à Claude Code, utilisable seul : lien `.claude/skills` et **génération des agents** (`spec-writer`, `developer`, `code-reviewer`) depuis l'en-tête YAML de `factory/prompts/`. N'ajoute le suivi de progression que si le plugin est installé : l'agent fixe lui-même le nombre d'étapes selon la mission (une étape = un résultat vérifiable, sans plancher ni plafond) et peut ajuster `total` en cours de route. Les valeurs de `tools:` sont des noms d'outils de Claude Code. | Après un clone, ou après modification d'un prompt |

**Contrôle et suivi d'une livraison (la session et les agents les lancent pendant `/deliver` ; `dashboard.sh` aussi, par vous, à tout moment)**

| Script | Question à laquelle il répond | Résultat |
|---|---|---|
| `scripts/verify-clean.sh` | « Le build est-il vert hors IDE ? » Copie le dépôt (fichiers vus par Git seulement), y lance la commande de vérification (`COMMANDE_VERIFY`, sinon `.factory-verify`, sinon `./mvnw` ou `./gradlew`), supprime la copie. `--keep` conserve la copie. | Tests lancés, analyse statique, `VERIFY OK` ou `VERIFY ECHEC` ; code de sortie = celui du build |
| `scripts/criteres-sans-test.sh <issue>` | « Chaque critère de l'issue a-t-il un test qui le nomme ? » (`--tous` : toutes les issues commencées) | `OK` ou la liste des critères sans test ; une issue sans aucun critère est une erreur |
| `scripts/couverture-prd.sh <prd>` | « Chaque critère du PRD est-il couvert par exactement une issue ? » | `OK`, ou critères sans issue, en double, ou inconnus du PRD |
| `scripts/etat-issues.sh` | « Où en sont les issues ? » Lit leurs en-têtes ; `--statut S` filtre ; `--prochaine` donne la première issue prête (toutes ses dépendances sont `Fait`) | Tableau Markdown, ou un identifiant |
| `scripts/dashboard.sh` | « Où en est le projet, d'un coup d'œil ? » Écrit `dashboard.html` (à ouvrir dans un navigateur, rafraîchi toutes les 30 s ; `--attente S` change le délai) en Kanban : un encart « En cours » en haut (issues `En cours` et `En revue`, référence et titre), puis les besoins et les issues en colonnes, une par statut du cycle dans l'ordre (en-tête coloré « Statut (n) », « — » si la colonne est vide, colonne « (autre) » seulement pour un statut hors cycle) ; une carte d'issue montre la référence, le titre, le besoin `F-xx`, les dépendances et les marqueurs « prochaine » (issue de `etat-issues.sh --prochaine`) et « bloquée » (`À faire` avec une dépendance pas `Fait`) ; une carte de besoin, l'ID, le libellé, la priorité et le PRD. Mise en page CSS seule (colonnes de largeur égale, défilement horizontal sur écran étroit, impression lisible) ; `--sortie F` change le fichier (son dossier doit exister, sinon code 64) ; `--boucle S` régénère toutes les S secondes jusqu'à Ctrl-C. Aucun modèle, aucun JavaScript, tout texte lu est échappé HTML | Fichier HTML (non versionné) |
| `scripts/worktree-issue.sh creer\|nettoyer\|lister` | « Comment isoler une issue ? » `creer` fait un `git worktree` sur la branche de l'issue (option `--base` pour des branches empilées) ; `nettoyer` le supprime une fois la branche fusionnée (option `--branche`) | Dossier, branche et base |
| `scripts/config-factory.sh` | « Quelle configuration s'applique ? » Sans option : `CLÉ=valeur` pour chaque clé connue (rien d'autre) ; `--max-iterations` : la limite des revues (`/deliver` la lit au départ) | Valeurs ; code 64 si `MAX_ITERATIONS_REVUE` n'est pas un entier >= 1 |
| `scripts/notifier.sh` | « Comment prévenir l'utilisateur d'une issue bloquée ? » Construit le message (From si renseigné, To, Subject encodé RFC 2047 s'il n'est pas ASCII, corps) et le passe sur l'entrée standard de `NOTIFICATION_COMMANDE`, destinataire en dernier argument ; `--test` envoie un essai | Code 0 envoyé, 3 non configuré, 4 échec de la commande, 64 usage |

**Outils internes**

| Script | Rôle |
|---|---|
| `scripts/lib-issues.sh` | Bibliothèque partagée (à sourcer, pas à lancer) : lit l'en-tête YAML des issues (listes sur une ou plusieurs lignes) et reconnaît les identifiants de critères sous toutes leurs formes (`CA-10`, `ca10`, `ca_10`) |
| `scripts/lib-config.sh` | Bibliothèque partagée (à sourcer) : `config_valeur <clé> <défaut>` lit la configuration de la factory ligne à ligne, sans jamais sourcer ni évaluer les fichiers |
| `factory/scripts/tests/run.sh` | Les vérifications des scripts ci-dessus, dans des dépôts jetables ; à relancer après toute modification d'un script |

**Qui lance quoi** : vous, `init-projet.sh`, `sync.sh` et `nettoyer` après une fusion ; la session principale pendant `/deliver`, `etat-issues.sh`, `dashboard.sh`, `couverture-prd.sh`, `verify-clean.sh`, `criteres-sans-test.sh` et `worktree-issue.sh creer` ;
les agents, `verify-clean.sh` (le développeur en fin de travail, le relecteur pour confirmer) et `criteres-sans-test.sh`.
**Pourquoi des scripts** : ce qui se vérifie mécaniquement est confié à des scripts testés, pas au jugement d'un modèle ; la session ne croit jamais un rapport d'agent sans le recouper avec eux.

### Configuration du projet : limite des revues et notification
Trois niveaux, du moins au plus prioritaire : `.factory.conf` (versionné, créé par `init-projet.sh`, jamais écrasé), `.factory.local.conf` (mêmes clés, **ignoré par git** : vos valeurs personnelles), variables d'environnement `FACTORY_<CLÉ>`.
Une clé présente avec une valeur **vide** l'emporte aussi sur les niveaux inférieurs : c'est le moyen de désactiver localement un réglage commun (`NOTIFICATION_COMMANDE=` dans `.factory.local.conf`, ou `FACTORY_NOTIFICATION_COMMANDE=` dans l'environnement, coupe la notification).

| Clé | Défaut | Rôle |
|---|---|---|
| `MAX_ITERATIONS_REVUE` | 5 | Allers-retours développeur <-> relecteur pour une issue (`/deliver`, et corrections après `/code-review`) ; au-delà, arrêt, notification, blocage remonté |
| `NOTIFICATION_COMMANDE` | vide | Commande d'envoi (`msmtp -a <compte>`, `sendmail -oi`, ou le chemin d'un script qui appelle une API avec curl ; jamais l'option `-t` de sendmail ou de mail, qui selon l'implémentation ignore ou double le destinataire passé en argument) ; reçoit le message sur son entrée standard et le destinataire en dernier argument |
| `NOTIFICATION_DESTINATAIRE` | vide | Votre adresse (dans `.factory.local.conf`) |
| `NOTIFICATION_EXPEDITEUR` | vide | Facultatif : en-tête From |

Les fichiers sont lus comme des lignes `CLÉ=valeur` (clés connues seulement, espaces tolérés autour de `=`), jamais exécutés. Les secrets (mot de passe SMTP, clé d'API) restent dans la configuration de l'outil d'envoi (`~/.msmtprc`, trousseau), jamais dans le dépôt.
Vérifier : `scripts/config-factory.sh`, puis `scripts/notifier.sh --test`.

## 6. Règles à retenir
- **Git** : une branche et une PR par issue, commits atomiques conventionnels (`feat:`, `fix:`, `test:`…). Seul l'utilisateur pousse et fusionne, avec `git merge --no-ff`.
- **Modèle de branches** : `main` = releases seulement (tags `vX.Y.Z`, personne n'y commite ; l'utilisateur y fusionne `develop` puis tague) ; `develop` = intégration, base de toutes les branches de travail (`feat/…`, `fix/…`, `docs/…`, `refactor/…`, `test/…`, `build/…`) et cible des PR ; `hotfix/<slug>` part de `main` et est fusionné dans `main` PUIS dans `develop` par l'utilisateur ; branches empilées inchangées (base = pointe de la branche dont l'issue dépend). Les agents ne travaillent jamais directement sur `main` ni sur `develop`.
- **Rapports** : format imposé (`prompts/report-format.md`) ; la session ne croit jamais un rapport sans le recouper avec le dépôt.
- **Traçabilité** : le nom d'un test contient l'identifiant du critère couvert (`test_ca10_…`, `cs07_…`).
- **Tests de garde-fous** : message d'erreur vérifié par égalité exacte, borne testée par sa valeur (limite acceptée, limite + 1 refusée), tests prouvés par mutation.
- **Pas d'abstraction « au cas où »** : une interface n'existe que pour une frontière externe à doubler ou avec deux implémentations réelles.
- **Questions** : seule la session principale peut interroger l'utilisateur ; les agents posent leurs questions dans un bloc `## QUESTIONS`, d'où l'importance du cadrage (§ 4, étape 1).
- **Documents** : `backlog.md` et le PRD sont à vous ; la session ne modifie que les statuts du backlog et liste les passages devenus faux.
- **Parallélisme et isolation** : jamais de travail sur `main` ni sur `develop` ; un `git worktree` par agent (`scripts/worktree-issue.sh`) ; jamais deux agents dans le même dossier.
- **Preuve** : un agent prouve (avant / après : test qui échoue puis réussit, chiffres mesurés, captures), il n'affirme pas ; la PR reprend cette preuve (`.github/pull_request_template.md`).
- **Lisibilité** : le code doit être compréhensible par un développeur ou un agent sans contexte (pas de duplication, pas de code mort) ; le relecteur le contrôle.

## 7. Contenu du dossier `factory/`

| Chemin | Rôle |
|---|---|
| `skills/` | Skills (source de vérité) ; `owasp-check` et `deliver` sont propres à la factory, les autres viennent de mattpocock/skills (`skills/SOURCES.md`) |
| `prompts/` | Prompts des trois agents (`spec-writer`, `developer`, `code-reviewer`), `report-format.md`, `briefs/` ; l'en-tête YAML alimente les agents ; le rôle d'orchestrateur est décrit dans `AGENTS.md` (« Orchestration ») |
| `scripts/` | Scripts de contrôle (§ 5) et leurs tests |
| `templates/` | Fichiers de départ d'un projet (indépendants de la stack), copiés par `init-projet.sh` |
| `stacks/` | Fichiers propres à une stack, copiés par `init-projet.sh --stack` : `java-maven`, `python`, `node`, `aucune` (CI, Dependabot, `.factory-verify`, `.gitignore`) |
| `init-projet.sh`, `sync.sh`, `sync-claude.sh` | Initialisation du projet ; alias de skills (neutre) ; lien et agents de Claude Code |
| `LESSONS.md`, `START-A-PROJECT.md` | Retour d'expérience ; checklist de démarrage |
| `VERSION`, `CHANGELOG.md`, `UPGRADE.md` | Version (marquée dans `.factory-version` du projet), historique, procédure de mise à jour |

Les skills `to-spec`, `implement` et `setup-matt-pocock-skills` de l'amont ont été retirés : leur rôle est tenu par `spec-writer`, `deliver` et `init-projet.sh`.

## 8. Choisir ou adapter la stack
- `--stack` copie les fichiers de `factory/stacks/<stack>/` : CI épinglée, Dependabot, `.factory-verify` (la commande de vérification), lignes du `.gitignore`.
- Autre stack : `--stack aucune`, puis créez `.factory-verify` (une ligne, syntaxe shell permise, ex. `python3 -m unittest discover -s tests -t .` ou `npm ci && npm test`) et ajoutez l'installation de l'outil de build au job `verify` de `.github/workflows/ci.yml`. Vous pouvez créer votre propre dossier `factory/stacks/<stack>/` sur le modèle des autres.
- `verify-clean.sh` cherche la commande dans `COMMANDE_VERIFY`, puis `.factory-verify`, puis un wrapper `./mvnw` ou `./gradlew`, sinon il s'arrête en demandant de la créer. Il reconnaît la sortie de Maven, d'unittest et de pytest pour le résumé chiffré.
- `owasp-check` est indépendant de la stack ; l'annexe `JAVA.md` complète pour Java/Spring Boot. Ajoutez une annexe `<STACK>.md` pour une autre technologie.
- Dossier de tests : `scripts/criteres-sans-test.sh` détecte `src/test`, `tests` ou `test` (sinon variable `DOSSIER_TESTS`).

## 9. Indépendance du fournisseur

| Neutre (fonctionne avec tout outil) | Propre à Claude Code | À reproduire pour un autre outil |
|---|---|---|
| Prompts (`factory/prompts/`, corps du texte), skills (`factory/skills/`, exposés par `.agents/skills`), scripts (`scripts/`), `AGENTS.md`, `backlog.md`, `docs/` ; mode « Sans sous-agents » de la skill `deliver` (rôles joués à la suite dans des sessions neuves) | `factory/sync-claude.sh` (`.claude/skills`, `.claude/agents/`), `.claude/settings.json` (refus de permissions), `CLAUDE.md`, noms d'outils du champ `tools:` des prompts (`Read`, `Bash`...), plugin savvy-progress (`mcp__savvy-progress__step`) | Les refus de permissions d'`.claude/settings.json` dans la configuration de l'outil ; la lecture de `AGENTS.md` et des prompts de rôle (l'en-tête YAML s'ignore) ; la traduction des noms d'outils ; le lancement des rôles (sous-agents ou sessions neuves) |

`./factory/init-projet.sh --sans-claude` et `./factory/sync.sh --sans-claude` n'écrivent rien de propre à Claude Code. Un projet existant obtient `sync-claude.sh` en remplaçant `factory/` (le script fait partie du dossier) ; relancer ensuite `./factory/init-projet.sh` met à jour `.factory-version` et les liens, et crée `CLAUDE.md` et `.claude/` s'ils manquent : un projet sans Claude Code relance `./factory/init-projet.sh --sans-claude`.

## 10. Permissions et limites des agents
`.claude/settings.json` refuse aux agents : `git push`, `reset --hard`, `clean`, `branch -D`, `checkout --`, `restore`, la lecture de `.env` et de `secrets/`. Limites : le « lecture seule » du reviewer est une consigne (il a `Bash` pour lancer le build) ;
vérifiez avec `/permissions` que les règles s'appliquent aussi aux sous-agents dans votre version.
Seule la session principale peut interroger l'utilisateur : les sous-agents n'ont pas d'outil de question, même déclaré. C'est pourquoi l'orchestrateur est un prompt joué par la session principale et non un agent
(un agent orchestrateur autonome a été essayé : il fonctionne, mais ses questions ne remontent qu'en fin de rapport ; voir `LESSONS.md` n° 17).

## 11. Dépannage

| Symptôme | Cause et remède |
|---|---|
| `verify-clean.sh` : « Aucune commande de vérification » | Ni `.factory-verify`, ni `COMMANDE_VERIFY`, ni wrapper `./mvnw` / `./gradlew` : créer `.factory-verify` (§ 8). |
| `verify` échoue dans le dépôt avec des erreurs de classes générées, IDE ouvert | Le serveur Java de l'IDE recompile des classes générées sans leur processeur d'annotations. Utiliser `scripts/verify-clean.sh`. |
| Les agents n'existent pas après un clone | `.claude/agents/` est généré et non versionné : lancer `./factory/sync.sh` (ou `sync-claude.sh`). |
| `criteres-sans-test.sh` signale un critère qui a pourtant un test | Le nom du test ne contient pas l'identifiant du critère : le renommer (`test_ca10_…`). |
| `criteres-sans-test.sh` : « aucun critère déclaré » | Le champ `criteres` de l'issue est vide ou illisible ; il accepte `[CA-01, CS-02]` ou une liste à tirets. |
| `couverture-prd.sh` : « aucun critère défini » | Les critères du PRD doivent commencer par `- **CA-10**` (puce, identifiant en gras). |
| `verify-clean.sh` : « Tests : inconnu » | La sortie du build n'est pas reconnue (ni Maven, ni unittest, ni pytest, ni la suite de la factory) ; le code de sortie reste fiable. |
| Un agent rend un rapport vide | La session le relance (le format de rapport l'interdit) ; voir `LESSONS.md` n° 5. |
| Une branche empilée relit les commits de l'issue précédente | La base est la pointe de la branche dont l'issue dépend (skill `deliver`, étape 0). |

## 12. Mettre à jour la factory
Procédure dans `UPGRADE.md` : remplacer `factory/`, relancer `./factory/init-projet.sh` (met à jour `.factory-version`, régénère les agents ; `--sans-claude` pour un projet sans Claude Code, sinon il crée `CLAUDE.md` et `.claude/` s'ils manquent), puis `factory/scripts/tests/run.sh`.
Les skills sont copiés, pas liés : modifiables, mais notez les écarts dans `skills/SOURCES.md`. Les langues : prompts, docs et messages en français ; les skills de mattpocock/skills restent en anglais.

## 13. Arborescence d'un projet initialisé

```
mon-projet/
├── README.md  AGENTS.md  CLAUDE.md  GLOSSARY.md  backlog.md      # à vous (la factory ne modifie que les statuts du backlog)
├── .factory-version  .factory-verify                             # version de la factory ; commande de vérification du projet
├── .factory.conf  .factory.local.conf                            # configuration de la factory (versionnée) ; vos valeurs personnelles (ignoré par git)
├── .claude/settings.json                                         # refus de permissions (agents/ et skills/ y sont générés par sync-claude.sh)
├── .github/workflows/ci.yml  .github/dependabot.yml              # selon la stack
├── docs/
│   ├── adr/       décisions d'architecture et de stack (0000-template.md, 0001-…)
│   ├── prd/       un PRD par module : NNN-module.md
│   ├── issues/    une issue par fichier : NNN-NN-slug.md (+ _template.md)
│   ├── reviews/   un rapport de revue par issue : NNN-NN.md
│   ├── agents/    configuration lue par les skills (tracker d'issues, docs du domaine)
│   └── lessons.md leçons du projet
├── scripts/       liens vers factory/scripts/ (verify-clean, criteres-sans-test, couverture-prd, etat-issues, dashboard, config-factory, notifier)
└── factory/       la factory (skills, prompts, scripts, modèles, stacks)
```

## 14. Formats de référence

**Critère du PRD** (une ligne à puce, identifiant en gras ; un numéro n'est jamais réutilisé) :
```
- **CA-07** Given les montants 1234 et 5 (cents), When `formater` les met en forme, Then les résultats sont « 12,34 $ » et « 0,05 $ ».
- **CS-01** Given une saisie non numérique, When elle est convertie, Then une erreur est levée sans recopier la saisie dans son message.
```

**En-tête d'une issue** (`docs/issues/001-03-formatage.md`) :
```
---
id: 001-03
titre: Formatage d'un montant en dollars
prd: docs/prd/001-pourboire.md
besoin: F-01
statut: À faire          # À faire -> En cours -> En revue -> Fait
depend_de: [001-01]      # ou une liste à tirets ; ids d'issues qui doivent être « Fait »
criteres: [CA-07, CA-08] # ou une liste à tirets
branche:                 # feat/001-03-formatage, renseignée par /deliver
commits: []              # renseigné à la fin
revue:                   # docs/reviews/001-03.md, renseigné à la fin
---
```
Le corps contient Objectif, Périmètre (dans / hors), Critères d'acceptation (renvoi au PRD) et Notes (décisions et écarts datés, décisions en attente de votre part).

**Statuts du backlog** : `À faire` -> `En clarification` -> `Spécifié` -> `En cours` -> `En revue` -> `Fait`. Un besoin passe `Fait` seulement quand toutes ses issues le sont et que vous avez fusionné.

**Statuts d'un ADR** : `proposé` -> `accepté` -> `remplacé par NNNN`.

**Branches et commits** : branche `feat/<prd>-<nn>-<slug>` (ex. `feat/001-03-formatage`) créée depuis `develop` (`fix/…`, `docs/…`, etc. de même ; `hotfix/<slug>` depuis `main`) ; commits atomiques `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `build:`, `chore:`, avec un message qui dit le *pourquoi*. Un test et son code peuvent être deux commits (`test:` puis `feat:`).

**Rapports des agents** : voir `prompts/report-format.md` (développeur : résumé, vérification chiffrée, commits, critères couverts, décisions, à trancher, non fait ; reviewer : verdict, build, constats classés, remarques de la revue précédente, documents devenus faux).

## 15. Exemple de session

Messages indicatifs à écrire dans Claude Code, dans l'ordre (adaptez les noms) :

| # | Vous écrivez | Ce qui se passe |
|---|---|---|
| 1 | `./factory/init-projet.sh --nom "MonProjet" --stack java-maven` (dans le terminal) | Fichiers de départ créés, agents générés |
| 2 | « Lance /grill-with-docs sur le besoin F-01 : extraire les données d'un ticket de caisse » | Interview ; `GLOSSARY.md` et ADR proposés |
| 3 | « Rédige l'ADR 0001 de stack et d'architecture d'après nos décisions » | `docs/adr/0001-…` en statut `proposé` ; vous le validez, puis vous complétez `AGENTS.md` |
| 4 | « Utilise l'agent spec-writer pour écrire le PRD du besoin F-01 » | `docs/prd/001-…md` avec critères et section sécurité, plus un bloc `## QUESTIONS` |
| 5 | Vous répondez aux questions posées par la session | Le PRD est corrigé ; vous le validez |
| 6 | « /to-tickets docs/prd/001-….md » | Découpage proposé ; vous l'approuvez ; fichiers dans `docs/issues/` |
| 7 | « scripts/couverture-prd.sh docs/prd/001-….md » | `OK` : chaque critère est couvert par une seule issue |
| 8 | « /deliver 001-01 » | Branche, développeur, vérification, reviewer, corrections, issue à `Fait` ; compte rendu court |
| 9 | « /deliver » (puis `scripts/etat-issues.sh --prochaine` pour voir laquelle) | Issue suivante ; répétez jusqu'à la dernière |
| 10 | « /code-review » | Revue de la branche entière |
| 11 | `git merge --no-ff feat/001-01-…` (dans le terminal, vous, sur `develop`) | Fusion dans `develop`, branche par branche, dans l'ordre des dépendances |
| 12 | « Clôture le besoin F-01 : documents à jour et leçons » | Passages devenus faux listés, leçons ajoutées à `docs/lessons.md` |

## 16. Cas courants

| Situation | Que faire |
|---|---|
| **Bug découvert après livraison** | `/diagnosing-bugs` pour trouver la cause ; écrire d'abord le test qui reproduit le bug et constater qu'il échoue ; corriger (`fix:`). Un bug important mérite une issue (`/deliver`) pour avoir revue et traçabilité. |
| **Un besoin change ou s'ajoute** | Vous modifiez `backlog.md` et le PRD (ou demandez à `spec-writer`) ; les nouveaux critères prennent de **nouveaux numéros** ; créez ou modifiez des issues ; `scripts/couverture-prd.sh` doit répondre OK. |
| **Il faut changer l'architecture ou la stack** | Nouvel ADR (l'ancien passe à `remplacé par NNNN`), issue de refactor, tests d'architecture mis à jour avant le code. Jamais en cours d'issue. |
| **`/deliver` interrompu** | Relancez `/deliver <issue>` : l'issue est `En cours`, la branche existe, elle est reprise. |
| **`MAX_ITERATIONS_REVUE` itérations de revue (5 par défaut) sans « APPROUVÉ »** | La session s'arrête et vous remonte le blocage ; s'il reste au moins un BLOQUANT, elle vous envoie aussi un courriel par `scripts/notifier.sh` (si `.factory.local.conf` le configure ; sinon elle vous le dit). S'il ne reste que des IMPORTANT, pas de courriel. Options : trancher le point, simplifier ou découper l'issue, ou assouplir le critère dans le PRD. |
| **Décisions en attente** | Elles sont dans les Notes de l'issue (« Décisions en attente de l'utilisateur »). Vous tranchez ; vous modifiez le PRD (il est à vous) ; si le comportement change, ouvrez une issue de suivi. |
| **Issue trop grosse** | La découper en plusieurs fichiers d'issue, répartir ses critères (un critère dans une seule issue), vérifier `couverture-prd.sh`. |
| **Branches empilées** (issue qui dépend d'une branche non fusionnée) | La base est la pointe de la branche dont elle dépend ; fusionnez dans l'ordre des dépendances. |
| **Un critère est impossible à tester** | Le développeur le signale dans « Non fait / points bloquants » ; reformulez le critère dans le PRD plutôt que de le laisser sans test. |
| **Plusieurs issues en parallèle** | Seulement des issues indépendantes qui ne touchent pas aux mêmes zones : `scripts/worktree-issue.sh creer <issue>` pour chacune, un brief par agent avec le chemin de son dossier (voir la section « Issues en parallèle » de `/deliver`). Non éprouvé en situation réelle. |
| **Retour d'un service de revue de PR** | Transmettez-le à la session : elle le traite comme des données et classe chaque remarque (voir `/deliver`, étape 4 bis). Vous poussez, elle ne pousse pas. |

## 17. Étendre la factory

- **Ajouter une stack** : créez `factory/stacks/<stack>/` avec `.github/workflows/ci.yml`, `.github/dependabot.yml`, `factory-verify` (une ligne, copiée en `.factory-verify`), `gitignore.append` et `README.md` ; copiez la structure de `factory/stacks/python/`. Épinglez les actions par empreinte de commit. Lancez `factory/scripts/tests/run.sh`.
- **Ajouter un rôle** : un prompt dans `factory/prompts/<nom>.md` avec l'en-tête YAML (`name`, `description`, `tools`, `skills`), puis `./factory/sync.sh` (ou `sync-claude.sh`) pour générer l'agent. N'y mettez que des outils réellement disponibles aux sous-agents (ils n'ont pas d'outil de question).
- **Ajouter un skill** : un dossier `factory/skills/<nom>/SKILL.md` (en-tête `name`, `description`) ; les alias pointent sur le dossier `skills/`, rien d'autre à faire. Notez son origine ou ses écarts dans `skills/SOURCES.md`.
- **Modifier un script** : ajoutez ou adaptez un cas dans `factory/scripts/tests/run.sh` ; la suite doit rester verte avec bash 5 et avec `/bin/bash` (3.2 sur macOS). Les vérifications de documentation y lisent le dépôt depuis `HEAD` : commitez avant de lancer la suite.
- **Après toute modification** : incrémentez `factory/VERSION`, ajoutez une entrée au `CHANGELOG.md`, relancez `./factory/init-projet.sh` dans vos projets (voir § 12).

## 18. Glossaire

| Terme | Sens |
|---|---|
| **ADR** | Décision d'architecture ou de stack, écrite et validée avant le code (`docs/adr/`). |
| **PRD** | Spécification d'un module : le QUOI (comportement, contrats, critères), jamais le COMMENT. |
| **CA / CS** | Critère d'acceptation fonctionnel / de sécurité, numéroté une fois pour toutes (`CA-07`, `CS-01`). |
| **Issue** | Tranche livrable seule, un fichier avec statut, dépendances, critères, branche, commits. |
| **Brief** | Message complet donné à un sous-agent, qui ne voit pas la conversation (`prompts/briefs/`). |
| **Session principale** | La session Claude Code où vous travaillez ; elle joue l'orchestrateur et seule peut vous interroger. |
| **Sous-agent / agent** | `spec-writer`, `developer`, `code-reviewer` : lancés par la session, ils rendent un rapport. |
| **`main` / `develop`** | `main` : releases seulement (tags `vX.Y.Z`) ; `develop` : intégration, base et cible des branches de travail. |
| **Base** | Commit de départ d'une livraison (`git log <base>..HEAD`) ; la pointe de la branche précédente pour des branches empilées. |
| **Définition de fini** | Liste de contrôle de `/deliver` (build vert en copie propre, critères couverts, revue APPROUVÉ, commits atomiques, documents à jour). |
| **Mutation** | Casser volontairement le code (retirer une borne, recopier l'entrée dans un message) pour vérifier qu'un test échoue. |
| **Copie propre** | Copie temporaire du dépôt limitée aux fichiers vus par Git, où tourne `verify-clean.sh`. |

## 19. Ce qui est éprouvé, ce qui ne l'est pas

- **Éprouvé** : la boucle `/deliver` (développeur, vérification, reviewer, corrections, clôture) sur un petit projet Python de trois issues, dont une avec une itération de correction ; les scripts (247 vérifications) ;
  l'initialisation d'un projet par stack.
- **Pas encore éprouvé en situation réelle** : le cadrage (`/grill-with-docs`), la rédaction du PRD par `spec-writer`, `/code-review` sur une branche entière, la reprise d'une issue interrompue, le mode « sans sous-agents », les règles de permissions sur les sous-agents,
  les stacks `node` et `java-maven` de bout en bout avec cette version de la factory, les issues en parallèle (worktrees), le retour d'une revue externe et les preuves avant / après sur une interface.
- Si l'une de ces étapes se passe mal, notez-le dans `docs/lessons.md` : c'est ainsi que cette factory s'améliore.
