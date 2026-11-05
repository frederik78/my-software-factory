# Mettre à jour la factory dans un projet

La factory est un dossier `factory/` copié (ou ajouté en sous-module git) dans chaque projet. Le fichier `.factory-version` à la racine du projet dit avec
quelle version il a été initialisé ; `factory/VERSION` donne celle du dossier présent.

1. Lire `factory/CHANGELOG.md` entre les deux versions. Une montée de version majeure change une convention : lire ses notes de migration.
2. Remplacer le dossier `factory/` par la nouvelle version (ou mettre à jour le sous-module). Les modifications locales des skills copiés sont notées dans
   `factory/skills/SOURCES.md` : les reporter à la main.
3. Relancer `./factory/init-projet.sh` : il ne remplace aucun fichier existant, crée ceux qui manquent (nouveaux modèles), lie les nouveaux scripts, régénère les agents (`sync.sh`, puis `sync-claude.sh` pour un projet Claude Code) et
   met à jour `.factory-version`. Sans option, les fichiers manquants incluent `CLAUDE.md` et `.claude/` : un projet sans Claude Code relance
   `./factory/init-projet.sh --sans-claude` à chaque mise à jour ; un projet qui veut Claude Code mais n'a pas encore de `CLAUDE.md` le relance sans option, ce qui le crée.
4. Comparer les fichiers du projet issus des modèles avec leur nouvelle version (`diff -r factory/templates/ .` en ignorant les fichiers propres au projet) pour
   reprendre à la main ce qui vous intéresse : `AGENTS.md`, `.claude/settings.json`, `docs/agents/*`, et pour la stack du projet `diff -r factory/stacks/<stack>/.github .github` (CI, Dependabot).
5. Lancer `factory/scripts/tests/run.sh`, puis `scripts/verify-clean.sh`.

## Agents actifs dans le dashboard (1.15.0)
`./factory/sync.sh` installe les hooks des sous-agents dans `.claude/settings.local.json` (non versionné). Si ce fichier a déjà une clé `hooks`, il n'est pas modifié : copiez le bloc affiché par l'avertissement. Relancez ensuite la session Claude Code. Sans hooks, le bandeau dit « journal absent » ; les signaux Git des worktrees fonctionnent sans eux.

## Modèle et effort des agents par défaut (1.14.0)
Les défauts passent de `opus` / `low` à `sonnet` / `medium`. Un projet dont `.factory.conf` (ou `.factory.local.conf`, ou `FACTORY_AGENT_*`) définit `AGENT_MODELE` et `AGENT_EFFORT` garde sa configuration : rien à faire. Sans ces clés, il adopte les nouveaux défauts au prochain `./factory/sync.sh` ; pour garder l'ancien comportement, y écrire `AGENT_MODELE=opus` et `AGENT_EFFORT=low`.

## Taille d'une issue (1.14.0)
Règle pour les prochains découpages : environ 10 critères au plus par issue ; une issue plus grosse se découpe, ou justifie sa taille dans le découpage proposé à l'utilisateur et par le champ `criteres_justification:` de son en-tête. Ce chiffre est un ordre de grandeur, pas une mesure ; `scripts/couverture-prd.sh` avertit au-delà de `MAX_CRITERES_ISSUE`, sans échouer. Les issues existantes d'un projet ne sont pas à modifier : le code de sortie ne change pas, l'avertissement reste une information. Ajouter `MAX_CRITERES_ISSUE=10` à `.factory.conf` est facultatif : c'est la valeur par défaut.

## Passer à la structure bare (1.14.0)
`scripts/worktree-issue.sh initialiser <source> <conteneur>` crée le clone bare, règle `origin` et la refspec de suivi, puis fait un fetch, sans toucher à la source. Les fichiers non suivis (`.env`, `.factory.local.conf`) ne sont pas copiés : recréez-les vous-même. Ensuite, un worktree par issue, même seule.
