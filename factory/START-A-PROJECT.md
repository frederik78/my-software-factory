# Démarrer un projet avec la factory

Dépôt vide (ou nouveau dépôt) contenant le dossier `factory/` : copie-le, ou ajoute-le en sous-module git.

## 1. Initialiser
Choisissez la stack (dossiers `factory/stacks/<stack>/`) :

| Stack | Ce que `--stack` ajoute |
|---|---|
| `java-maven` | CI Java/Maven (`./mvnw`, analyse des dépendances optionnelle), Dependabot Maven, lignes `.gitignore`, `.factory-verify` = `./mvnw -B clean verify` |
| `python` | CI Python (`unittest`), Dependabot pip, lignes `.gitignore`, `.factory-verify` = `python3 -m unittest discover -s tests -t .` |
| `node` | CI Node (`npm ci`, `npm test`, `npm audit`), Dependabot npm, lignes `.gitignore`, `.factory-verify` = `npm ci && npm test` |
| `aucune` (défaut) | Squelette neutre : CI qui lance `scripts/verify-clean.sh`, Dependabot des actions ; à vous de créer `.factory-verify` |

```
./factory/init-projet.sh --nom "Nom du projet" --stack java-maven
```
Crée, sans jamais rien écraser : `README.md`, `AGENTS.md`, `CLAUDE.md`, `GLOSSARY.md`, `backlog.md`, `.claude/settings.json` (refus de permissions), `.factory-version`, `docs/` (adr, prd, issues, reviews, agents, `lessons.md`),
`.gitignore`, les fichiers de la stack (CI, Dependabot, `.factory-verify`), les liens `scripts/`, puis lance `factory/sync.sh` (alias de skills ; avec `CLAUDE.md`, aussi les agents de Claude Code via `sync-claude.sh`).
Projet sans Claude Code : `--sans-claude` ne crée ni `CLAUDE.md` ni rien sous `.claude/`, et lance `sync.sh --sans-claude` ; garder l'option à chaque relance (mise à jour de la factory), sinon `init-projet.sh` crée `CLAUDE.md` et `.claude/` qui manquent. Le mode Claude de `sync.sh` ne dépend que de `CLAUDE.md` (pas du dossier `.claude/`).
Relançable sans risque. Une autre stack que celles-ci : choisir `aucune`, puis § 3 et `factory/README.md` § 8.

## 2. Cadrer (avec l'utilisateur, avant tout code)
1. Remplir `backlog.md` : contexte, contraintes, premiers besoins (F-xx).
2. Interview `/grill-with-docs` : glossaire (`GLOSSARY.md`, à la racine) et vocabulaire du métier.
3. **ADR d'architecture et de stack** (`docs/adr/0001-…`, format `0000-template.md`), validés par l'utilisateur : langage, framework, base de données,
   structure des packages et sens des dépendances, authentification, gestion du schéma, fournisseurs externes. Ne pas commencer à coder avant.
   **Architecture par défaut : des couches de services**, avec des interfaces seulement aux frontières externes à doubler. Partir de la référence de la stack quand elle en a une (`factory/stacks/java-maven/README.md`) et consigner chaque écart ; un autre style, comme l'hexagone, se justifie dans l'ADR.
4. Compléter `AGENTS.md` (stack, commandes, architecture, règles métier) à partir des ADR. N'y mettre que le **flux de travail et les contraintes que le code ne montre pas** : l'agent lit lui-même l'arborescence et les fichiers ; y recopier ce qu'il peut lire dans le code ne lui apprend rien et se périme.

## 3. Mettre en place les garde-fous AVANT la première issue
Ces éléments appartiennent à une première issue « socle » (`000-01`). Ils sont décrits par leur **fonction** ; entre parenthèses, un exemple par stack. Le dossier `factory/stacks/<stack>/` fournit la CI, Dependabot et la commande de vérification ; le reste est à choisir selon l'ADR de stack.
- [ ] **Commande de vérification unique** dans `.factory-verify` (créée par `--stack`, sinon à écrire) : tests + analyses ci-dessous ; `scripts/verify-clean.sh` et la CI la lancent.
- [ ] **Tests d'architecture** : couches, sens des dépendances, règles d'`AGENTS.md`, chacune avec un test qui échoue sur une violation volontaire
      (Java : ArchUnit ; Python : import-linter ; Node : dependency-cruiser).
- [ ] **Analyse statique de sécurité** qui fait échouer le build (Java : SpotBugs + Find Security Bugs ; Python : bandit ; Node : eslint-plugin-security).
- [ ] **Analyse des dépendances vulnérables** en CI (Java : OWASP Dependency-Check, secret `NVD_API_KEY` ; Python : pip-audit ; Node : `npm audit`, déjà dans le modèle).
- [ ] **Couverture** avec un seuil, et **mutation testing sur le domaine et les services** avec un seuil de score : la mesure objective de la qualité des tests, que la revue ne peut pas faire seule
      (Java : JaCoCo + PIT ; Python : coverage + mutmut ; Node : c8 + Stryker). Vérifier les versions et la compatibilité avec la version du langage.
- [ ] **Un test de contrat sur serveur réel** (port aléatoire) du premier endpoint exposé, y compris requêtes malformées et en-têtes de sécurité.
- [ ] **CI** : actions épinglées par empreinte, détection de secrets (gitleaks) et Dependabot déjà en place dans les modèles ; ajouter les secrets nécessaires (`GITLEAKS_LICENSE` pour une organisation,
      `NVD_API_KEY` pour Java) ; vérifier que le job `verify` correspond à la stack.
- [ ] **Branches** : `develop` créée depuis `main` et définie comme branche par défaut sur GitHub ; `main` et `develop` protégées (pas de commit direct, PR et CI verte exigées) ; la CI se déclenche sur les deux.
- [ ] **Modèle de PR** (`.github/pull_request_template.md`, créé par `init-projet.sh`) en place : il reprend la preuve avant / après et les décisions en attente.
- [ ] **Licence** de chaque dépendance ajoutée vérifiée.
- [ ] **Limite des revues et notification** : `MAX_ITERATIONS_REVUE` dans `.factory.conf` (5 par défaut) ; chaque personne renseigne `NOTIFICATION_COMMANDE` et `NOTIFICATION_DESTINATAIRE` dans `.factory.local.conf` (ignoré par git),
      secrets dans l'outil d'envoi (`~/.msmtprc`, trousseau), puis vérifie avec `scripts/notifier.sh --test`.
- [ ] `scripts/verify-clean.sh` vert sur le socle ; `factory/scripts/tests/run.sh` vert.
- [ ] Pour Java : relire l'annexe `factory/skills/owasp-check/JAVA.md`.

## 4. Un module
1. `spec-writer` : PRD (`docs/prd/NNN-module.md`) : comportement, contrats, critères CA/CS, section sécurité. Pas de noms de packages ni de classes.
2. Découpage en issues (`to-tickets`) dans `docs/issues/`, validé par l'utilisateur.
3. Pour chaque issue, dans l'ordre : `/deliver <issue>`.
4. `/code-review` sur la branche, fusion dans `develop` par l'utilisateur (`git merge --no-ff`), clôture (dérive documentaire, leçons).

## 5. Entre deux cycles
- Relire `docs/lessons.md` et `factory/LESSONS.md` ; ajuster les prompts ou skills si une leçon le justifie (les écarts aux skills copiés de Matt Pocock
  sont notés dans `factory/skills/SOURCES.md`).
- `./factory/sync.sh` après toute modification d'un en-tête de prompt.
