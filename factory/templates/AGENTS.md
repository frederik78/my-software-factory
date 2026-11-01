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
- `scripts/criteres-sans-test.sh <issue>` : critères CA/CS d'une issue qu'aucun test ne mentionne
- `scripts/couverture-prd.sh <prd>` : chaque critère du PRD est couvert par exactement une issue
- `scripts/etat-issues.sh [--prochaine]` : état des issues (lu dans leurs en-têtes)
- `scripts/dashboard.sh [--sortie <fichier>] [--attente <s>] [--boucle <s>]` : dashboard HTML statique (`dashboard.html`, non versionné) des besoins et des issues par statut ; sans modèle ni dépendance
- `scripts/worktree-issue.sh creer|nettoyer|lister` : une issue dans son propre dossier de travail (`git worktree`)
- `scripts/config-factory.sh [--max-iterations]` : configuration effective de la factory (`.factory.conf`, `.factory.local.conf` non versionné, variables `FACTORY_*`)
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
- <Règles métier transverses du projet : unités, devises, configuration plutôt que constantes, validation, etc.>

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
- Jamais de travail sur `main` ni sur `develop` (voir « Modèle de branches »). Pas de deux agents qui écrivent dans le même dossier : un `git worktree` par agent pour des issues parallèles (`scripts/worktree-issue.sh`).
- Un agent prouve son travail, il ne l'affirme pas : état avant / après (test qui échoue puis réussit, chiffres mesurés, captures) dans son rapport et dans la PR ; l'utilisateur relit la preuve plus que le code.
- Les écarts de contrat externe, de licence, de dépendance ou de PRD se décident avec l'utilisateur, pas seul.

**Séquence d'un besoin** (traiter les besoins désignés par l'utilisateur, sinon ceux à `À faire` par priorité)
0. Passer le besoin à `En clarification`.
1. **Cadrage** : interview (`grill-me` / `grill-with-docs`) pour le glossaire et les contraintes ; si le module apporte une décision structurante (architecture, stockage, fournisseur, dépendance majeure), proposer un ADR `proposé` et le faire valider AVANT tout code.
2. **PRD** : agent `spec-writer`. S'il rend un bloc `## QUESTIONS`, poser les questions à l'utilisateur (groupées, avec options et recommandation), consigner les réponses dans le PRD, relancer le rôle jusqu'à `## QUESTIONS : aucune`. Faire valider le PRD ; besoin à `Spécifié`.
3. **Issues** : `/to-tickets` dans `docs/issues/`, découpage approuvé par l'utilisateur, `scripts/couverture-prd.sh <prd>` à `OK` (chaque critère couvert par exactement une issue).
4. **Livraison**, issue par issue dans l'ordre des dépendances : `/deliver` (développeur, vérifications de la session, reviewer, corrections en `MAX_ITERATIONS_REVUE` itérations au plus (5 par défaut, voir `.factory.conf` ; au-delà, le blocage est remonté à l'utilisateur, avec un courriel par `scripts/notifier.sh` s'il reste au moins un BLOQUANT), définition de fini). Besoin à `En cours` puis `En revue`.
5. **Revue indépendante** de la branche (`/code-review`) avant la fusion ; ses constats bloquants repartent au développeur, puis nouvelle revue ; la même limite de `MAX_ITERATIONS_REVUE` itérations (et la même règle d'arrêt au-delà) vaut pour ces corrections.
6. **Clôture** : besoin à `Fait` quand toutes ses issues le sont et que l'utilisateur a fusionné ; lister les passages du PRD, du backlog et des ADR devenus faux et les proposer à l'utilisateur ; ajouter les leçons du cycle à `docs/lessons.md` ; rapport final court.

## Agent skills
Les skills de la factory lisent leur configuration ici :
- **Issue tracker** : issues et specs en fichiers locaux (`docs/issues/`, `docs/prd/`). Voir `docs/agents/issue-tracker.md`.
- **Domain docs** : un seul contexte ; glossaire `GLOSSARY.md` (racine), ADR dans `docs/adr/`. Voir `docs/agents/domain.md`.

## Contexte métier
Voir `GLOSSARY.md` (racine).
