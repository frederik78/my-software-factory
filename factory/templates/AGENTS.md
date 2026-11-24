# __NOM_PROJET__

<Une phrase : ce que fait l'application et pour qui.>

Ce fichier (standard ouvert AGENTS.md) est la source de vérité pour tout agent de code (Claude Code, Codex, Cursor, Copilot, etc.).
Il ne contient rien de propre à un outil. `CLAUDE.md` l'importe et n'ajoute que des directives propres à Claude Code.
Périmètre actuel : <backend uniquement ? frontend ?>.

## Stack
<Langage et version, framework, outil de build, base de données. Les choix structurants sont dans docs/adr/.>
Package racine : `<...>`.

## Commandes (toujours via le wrapper du build)
- `<commande de tests>` : tests
- `<commande de vérification complète>` : tests (dont tests d'architecture) + analyse statique de sécurité ; c'est exactement ce que lance la CI
- `scripts/verify-clean.sh` : la même vérification dans une copie propre du dépôt, hors IDE (à utiliser par les agents et chaque fois qu'un IDE est ouvert)
- `scripts/fin-issue.sh <issue> [-- <arguments de build>]` : contrôle de fin d'issue, après le dernier commit de code : arbre propre, build en copie propre, critères, tests ignorés ; dernière ligne `FIN-ISSUE OK …` ou `FIN-ISSUE ECHEC : …`
- `scripts/criteres-sans-test.sh <issue>` : critères CA/CS d'une issue qu'aucune déclaration de test ne nomme (un commentaire ou une chaîne ne compte pas)
  Un test bash se déclare par une ligne qui commence par `verifier "ca10_x" …` (ou `verdict_cas "…"`) : le titre entre guillemets contient l'identifiant du critère. Deux clés (`.factory.conf`) : `DOSSIER_TESTS` (dossier des tests, relatif ; défaut : détection de `src/test`, `tests`, `test`) et `TESTS_BASH_FONCTIONS` (noms des fonctions de test ; défaut : `verifier verdict_cas`, remplacé par la valeur réglée). Ordre de priorité : variable (`DOSSIER_TESTS`), `FACTORY_<CLÉ>` (`FACTORY_DOSSIER_TESTS`, `FACTORY_TESTS_BASH_FONCTIONS`), `.factory.local.conf`, `.factory.conf`, défaut.
- `scripts/couverture-prd.sh <prd>` : chaque critère du PRD est couvert par exactement une issue
- `scripts/etat-issues.sh [--prochaine]` : état des issues (lu dans leurs en-têtes)
- `scripts/statuts.sh [--table]` : contrôle de l'état courant des statuts de besoin (`backlog.md`) et d'issue (`docs/issues/`), en lecture seule (il ne corrige rien, n'écrit aucun fichier) : une ligne par constat `ERREUR|AVIS <code> <objet> : <texte>` (erreurs E01 à E14, avis A01 à A16), puis `STATUTS : <e> erreur(s), <a> avis` ; code 1 s'il y a au moins une erreur, 0 sinon (les avis sont permis), 64 pour un mauvais usage ; `--table` affiche les statuts (dont `Abandonnée`, hors cycle) et les transitions légales, définis une seule fois dans `factory/scripts/statuts.table`
- `scripts/dashboard.sh [--sortie <fichier>] [--attente <s>] [--boucle <s>]` : dashboard HTML statique (`dashboard.html`, non versionné) des besoins et des issues par statut, section « Contrôle des statuts » (résultat de `scripts/statuts.sh`, sans effet sur le code de sortie), agents actifs (hooks de `factory/sync-claude.sh`) et signaux Git des worktrees ; branche de chaque issue retrouvée par convention de nommage (`<type>/<id>-…`), avancement des besoins ; `--boucle` doit tourner pour que la page reste à jour ; sans modèle ni dépendance
- `scripts/worktree-issue.sh creer|nettoyer|lister|initialiser` : une issue dans son propre dossier de travail (`git worktree`) ; `initialiser <source> <conteneur>` crée la structure bare
- `scripts/config-factory.sh [--max-iterations|--nettoyage-apres-fusion|--besoin-fait-auto|--demarrage-auto]` : configuration effective de la factory (`.factory.conf`, `.factory.local.conf` non versionné, variables `FACTORY_*`)
- `scripts/notifier.sh --sujet <s> [--corps-fichier <f>] | --test` : courriel par la commande configurée (issue bloquée en revue)
- `factory/scripts/tests/run.sh` : tests des scripts de la factory
- `./factory/sync.sh` : recrée les alias de skills (`.agents/skills`) ; avec `CLAUDE.md` (le seul dossier `.claude/` ne suffit pas), appelle `factory/sync-claude.sh` (propre à Claude Code : `.claude/skills` et enveloppes d'agents). Options `--claude`, `--sans-claude`

Ne jamais appeler directement un outil propre à un fournisseur dans le code applicatif.

## Architecture
La structure est décidée dans un ADR (`docs/adr/0001-architecture.md`) AVANT le premier code, et appliquée par des tests d'architecture qui
échouent à la moindre violation. Elle ne change pas sans nouvel ADR.
<Par défaut, des couches de services (référence Java : `factory/stacks/java-maven/README.md`) ; un autre style se justifie dans l'ADR. Arborescence des packages, rôle de chaque couche, sens des dépendances. N'écrire ici que ce que le code ne montre pas (flux de travail, contraintes, décisions) : l'agent lit le reste lui-même dans le code.>

## Règles
- **INTERDIT** aux agents : pousser, fusionner, réécrire l'historique (`git push`, `reset --hard`, `clean`, `branch -D`, `checkout --`, `restore`) ; lire ou copier les fichiers de secrets. Seul l'utilisateur
  pousse et fusionne. Claude Code l'applique par `.claude/settings.json` (règles de refus) ; pour un autre outil, reprendre cette règle dans sa propre configuration de permissions.
- **Modèle de branches** : `main` ne reçoit que les releases (états livrables, tags `vX.Y.Z`) ; personne n'y commite, seul l'utilisateur y fusionne `develop` (`git merge --no-ff develop`) puis tague. `develop` est la branche d'intégration : toute branche de travail (`feat/<prd>-<nn>-<slug>`, `fix/…`, `docs/…`, `refactor/…`, `test/…`, `build/…`) en part et y revient par PR (base = `develop`). Correctif urgent sur une release : `hotfix/<slug>` partant de `main`, fusionné dans `main` PUIS dans `develop` par l'utilisateur. Branches empilées : base = pointe de la branche dont l'issue dépend. Les agents ne travaillent jamais directement sur `main` ni sur `develop`.
- **INTERDIT** : un test qui dépend d'un service externe réel ; toujours doubler la frontière externe.
- Pas d'interface « au cas où » : une abstraction n'existe que pour une frontière externe à doubler ou s'il y a deux implémentations réelles.
- Le framework d'abord : un mécanisme transversal (session, authentification, CSRF, en-têtes, erreurs, validation, configuration) utilise ce que le framework fournit ; un équivalent écrit à la main se justifie par un critère du PRD ou une mesure.
- La référence de code : la structure et la mise en œuvre se calent sur le projet que l'ADR nomme, lu fichier par fichier ; tout écart de nom ou de forme a une raison. <Application Spring Boot : dépendances Spring d'abord, JHipster comme modèle, voir `factory/stacks/java-maven/README.md`. Sinon : le projet nommé par l'ADR, ou « aucune ».>
- **Langue du code** : les classes techniques sont impérativement en anglais.
- <Règles métier transverses du projet : unités, devises, configuration plutôt que constantes, validation, etc.>

## Sujets à remonter à l'utilisateur
Valable pour tous les rôles (session, developer, code-reviewer, spec-writer). Sur l'un de ces sujets, l'agent ne tranche pas seul :
1. secrets et identifiants
2. authentification et autorisation
3. dépendance et licence
4. déploiement et CI
5. contrat d'un service externe
6. écart avec le PRD

Sur l'un de ces sujets, l'agent s'arrête et ne décide pas seul : il range le point dans `## QUESTIONS` (spec-writer) ou `## À trancher par l'utilisateur` (developer, code-reviewer) de son rapport ; la session le relaie à l'utilisateur. Le code-reviewer ne le classe jamais « mineur ».
Cette liste complète les règles existantes sans les contredire (interdiction de lire les secrets ; les écarts de contrat externe, de licence, de dépendance ou de PRD se décident avec l'utilisateur).

## Tests (TDD obligatoire)
Pas de code de production sans un test RED préalable qui échoue. Cycle : RED, GREEN (code minimal), REFACTOR.
- Le nom de chaque test (ou son `@DisplayName`) contient l'identifiant du critère d'acceptation qu'il couvre (`ca10_…`, `cs07_…`).
- Correction de bug : écrire d'abord le test qui reproduit le bug, vérifier qu'il échoue, puis corriger.
- Un commit = un changement atomique, message au format conventionnel (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `build:`).
- Une branche et une PR par issue (`feat/<prd>-<nn>-<slug>`, base = `develop`) ; l'utilisateur fusionne avec `git merge --no-ff`.

## Processus (factory)
Les besoins sont inventoriés dans `backlog.md` (statuts, priorités, décisions) ; le détail est dans `docs/prd/` (le QUOI : comportement, contrats,
critères) ; le suivi dans `docs/issues/` (une issue = un fichier) ; les revues dans `docs/reviews/` ; les leçons dans `docs/lessons.md`.
Voir `factory/README.md`. Idée, puis cadrage (grill-me), ADR, PRD, issues, `/deliver` (TDD, revue, corrections, vérification), PR.
Rôles : `spec-writer`, `developer`, `code-reviewer` (prompts dans `factory/prompts/`), coordonnés par la session principale (voir « Orchestration » ci-dessous).
Sécurité : la checklist `owasp-check` (`factory/skills/`) s'applique à chaque rôle ; toute vulnérabilité OWASP avérée est BLOQUANTE.

## Orchestration (rôle de la session principale)
La session principale joue l'orchestrateur : elle coordonne `spec-writer`, `developer` et `code-reviewer`, ne code pas elle-même, et seule peut interroger l'utilisateur (les sous-agents n'ont pas d'outil de question :
ils posent leurs questions dans un bloc `## QUESTIONS` de leur rapport, qu'elle relaie). Elle ne modifie `backlog.md` que pour les statuts et les décisions, et ne reformule jamais un besoin sans accord.

**Principes**
- Ne jamais croire un rapport sans le recouper avec le dépôt (`git log`, `git status`, `scripts/verify-clean.sh`). Format des rapports : `factory/prompts/report-format.md`.
- L'architecture se décide avant le code, dans un ADR validé, et s'applique par des tests d'architecture ; elle ne change pas sans nouvel ADR.
- Le PRD décrit le comportement, jamais la structure du code (aucun nom de package, de classe ni de couche).
- Une branche et une PR par issue (base = `develop`) ; l'agent ne pousse ni ne fusionne, l'utilisateur fusionne avec `git merge --no-ff`.
- Jamais de travail sur `main` ni sur `develop` (voir « Modèle de branches »). Chaque issue se réalise dans son propre `git worktree`, même seule (`scripts/worktree-issue.sh`) ; le dossier de l'utilisateur et de son IDE n'est jamais celui d'un agent.
- Un agent prouve son travail, il ne l'affirme pas : état avant / après (test qui échoue puis réussit, chiffres mesurés, captures) dans son rapport et dans la PR ; l'utilisateur relit la preuve plus que le code.
- Les écarts de contrat externe, de licence, de dépendance ou de PRD se décident avec l'utilisateur, pas seul.

**Règles de l'orchestrateur** (procédure détaillée de chacune : `factory/skills/deliver/SKILL.md` ; aucune ne donne le droit de pousser ni de fusionner)
- Règle 1, constats sérieux : un BLOQUANT ou IMPORTANT sans choix de conception repart au developer sans consulter l'utilisateur ; un choix de conception, un sujet de « Sujets à remonter à l'utilisateur » ou une décision déjà prise par l'utilisateur se décide avec lui (`factory/skills/deliver/SKILL.md`, étape 4).
- Règle 2, worktrees : un worktree par issue (`scripts/worktree-issue.sh creer`), en dossier frère dans un conteneur unique (structure bare) ; la conversion d'un dépôt se fait sur demande explicite, jamais pendant une livraison (`factory/skills/deliver/SKILL.md`, étape 0).
- Règle 3, besoin clos : clé `BESOIN_FAIT_AUTO` (défaut `non`) ; la clôture après fusion est l'étape 6 ci-dessous, appliquée seulement avec `oui`, sinon proposée à l'utilisateur (`factory/skills/deliver/SKILL.md`).
- Règle 4, nettoyage : clé `NETTOYAGE_APRES_FUSION` (défaut `non`) ; avec `oui`, la session supprime le worktree et la branche d'une issue après une fusion demandée et vérifiée, sinon elle le propose (`factory/skills/deliver/SKILL.md`).
- Règle 5, démarrage : clé `DEMARRAGE_AUTO` (défaut `non`) ; avec `oui`, la session démarre les issues démarrables dès que leurs dépendances le permettent, 2 ou 3 au plus, sinon elle indique l'étape suivante (`factory/skills/deliver/SKILL.md`).
- Règle 6, verdict : un verdict APPROUVÉ est incompatible avec un constat BLOQUANT ou IMPORTANT ouvert ; la session consigne alors CHANGEMENTS DEMANDÉS, jamais l'inverse (`factory/skills/deliver/SKILL.md`, étape 3).
- Règle 7, consignation : la session seule écrit le verdict et le fichier de revue ; developer et relecteurs n'y écrivent jamais (`factory/skills/deliver/SKILL.md`, étape 3).
- Règle 8, fin d'issue : `scripts/fin-issue.sh` est lancé par la session après le dernier commit de code, avant la clôture de l'issue ; sans `FIN-ISSUE OK` l'issue n'est pas close (`factory/skills/deliver/SKILL.md`, étape 5).

**Séquence d'un besoin** (traiter les besoins désignés par l'utilisateur, sinon ceux à `À faire` par priorité)
Les statuts d'un besoin et d'une issue, leur ordre et les transitions légales sont dans la table (`scripts/statuts.sh --table`) ; `/deliver` lance `scripts/statuts.sh` à chaque changement de statut d'issue ou de besoin, et une erreur qui vise l'issue traitée ou son besoin arrête le passage.
0. Ouvrir le cadrage du besoin (première transition du besoin dans la table).
1. **Cadrage** : interview (`grill-me` / `grill-with-docs`) pour le glossaire et les contraintes ; si le module apporte une décision structurante (architecture, stockage, fournisseur, dépendance majeure), proposer un ADR `proposé` et le faire valider AVANT tout code.
2. **PRD** : agent `spec-writer`. S'il rend un bloc `## QUESTIONS`, poser les questions à l'utilisateur (groupées, avec options et recommandation), consigner les réponses dans le PRD, relancer le rôle jusqu'à `## QUESTIONS : aucune`. Faire valider le PRD.
3. **Issues** : `/to-tickets` dans `docs/issues/`, découpage approuvé par l'utilisateur, `scripts/couverture-prd.sh <prd>` à `OK` (chaque critère couvert par exactement une issue).
4. **Livraison**, issue par issue dans l'ordre des dépendances : `/deliver` (développeur, vérifications de la session, reviewer, corrections, puis `scripts/fin-issue.sh` à `FIN-ISSUE OK` avant de clore l'issue ; corrections en `MAX_ITERATIONS_REVUE` itérations au plus (3 par défaut, voir `.factory.conf` ; au-delà, le blocage est remonté à l'utilisateur, avec un courriel par `scripts/notifier.sh` s'il reste au moins un BLOQUANT), définition de fini). Le statut du besoin suit l'avancement de ses issues, transition par transition (`scripts/statuts.sh --table`).
5. **Revue indépendante** de la branche (`/code-review`) avant la fusion ; ses constats bloquants repartent au développeur, puis nouvelle revue ; la même limite de `MAX_ITERATIONS_REVUE` itérations (et la même règle d'arrêt au-delà) vaut pour ces corrections.
6. **Clôture** : après chaque fusion demandée par l'utilisateur, lancer `scripts/statuts.sh` : tout besoin qu'il signale « en retard : toutes les issues sont Fait et fusionnées dans develop (attendu : Fait) » est clos dans `backlog.md` selon la table (branche `docs/…` ; on ne la fusionne pas sans demande de l'utilisateur), avec `BESOIN_FAIT_AUTO=oui` seulement (défaut `non` : le proposer à l'utilisateur) ; lister les passages du PRD, du backlog et des ADR devenus faux et les proposer à l'utilisateur ; ajouter les leçons du cycle à `docs/lessons.md` ; rapport final court.

## Agent skills
Les skills de la factory lisent leur configuration ici :
- **Issue tracker** : issues et specs en fichiers locaux (`docs/issues/`, `docs/prd/`). Voir `docs/agents/issue-tracker.md`.
- **Domain docs** : un seul contexte ; glossaire `GLOSSARY.md` (racine), ADR dans `docs/adr/`. Voir `docs/agents/domain.md`.

## Contexte métier
Voir `GLOSSARY.md` (racine).
