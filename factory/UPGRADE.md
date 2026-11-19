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

## Fichier de revue consolidé et avis A16 (1.25.0)
Remplacez `factory/` : aucune migration de données, les fichiers de `docs/reviews/` existants ne sont pas touchés et aucun nouveau lien n'est requis dans `scripts/`. Les nouvelles revues ont pour première ligne `VERDICT: <valeur>` (seule ligne `VERDICT:` du fichier) et des sections `## Itération <n> (<date>)` qui commencent par `Verdict de l'itération : <valeur>` ; la session, seule, les écrit (skill `deliver`).
À faire à la main : si votre projet a son propre `docs/reviews/README.md`, reprenez-y le texte du modèle (`factory/templates/docs/reviews/README.md`). Un fichier de revue en cours de livraison qui a encore plusieurs lignes de verdict est corrigé à la main (une seule ligne de tête, celle de la dernière itération), sinon `scripts/statuts.sh` donne l'avis A16 (et A03). Les revues d'avant le format de ligne de verdict ne donnent pas d'A16.

## Contrôle des statuts, table unique et statut Abandonnée (1.24.0)
Remplacez `factory/`, puis relancez `./factory/init-projet.sh` : il crée dans le projet les liens `scripts/statuts.sh`, `scripts/lib-constats.sh`, `scripts/lib-preuves.sh`, `scripts/lib-dependances.sh`, `scripts/lib-besoins.sh`, `scripts/lib-fusion.sh` et `scripts/lib-verdict.sh` qui manquent (sans eux, `scripts/statuts.sh` et le dashboard ne trouvent pas leurs bibliothèques ; la table `statuts.table` reste dans `factory/scripts/`). Aucune migration de données : `Abandonnée` est un ajout, vos issues et besoins gardent leur statut, et une issue terminée sans preuves donne des avis, jamais d'erreur.
Nouveautés à connaître : `scripts/statuts.sh` (lecture seule, code 1 s'il y a une erreur) ; la section « Contrôle des statuts » du dashboard (sans effet sur son code de sortie) ; `/deliver` lance le contrôle à chaque changement de statut. `scripts/verdict-revue.sh` partage désormais `scripts/lib-verdict.sh` avec `statuts.sh` (comportement inchangé). `dashboard.sh` et `etat-issues.sh` refusent un fichier d'issue de plus de 1 Mio. Si votre `AGENTS.md` est le vôtre, reprenez à la main la commande `scripts/statuts.sh` et le renvoi à la table dans « Séquence d'un besoin » (modèle : `factory/templates/AGENTS.md`) ; ajoutez `Abandonnée` à la ligne « Statuts » de votre `backlog.md` si vous l'utilisez.

## Verdict de revue, carte « pour l'humain » et liste d'escalade (1.23.0)
Remplacez `factory/` : sans action requise (les revues déjà écrites restent telles quelles ; une revue sans ligne `VERDICT:` se lit `INCONNU`, ce qui est attendu). Les nouvelles revues commencent par `VERDICT: APPROUVÉ` ou `VERDICT: CHANGEMENTS DEMANDÉS` ; `/deliver` les lit avec `scripts/verdict-revue.sh` (relancez `./factory/init-projet.sh` pour créer le lien `scripts/verdict-revue.sh` dans le projet). Si votre `AGENTS.md` est le vôtre, ajoutez-y à la main la section « Sujets à remonter à l'utilisateur » (modèle : `factory/templates/AGENTS.md`) : six sujets sur lesquels aucun rôle ne décide seul.

## Dashboard à jour avant la fusion (1.22.0)
Remplacez `factory/` : sans action requise. Un dépôt dont chaque issue a `branche:` rempli se comporte comme avant. Un champ `branche:` vide est désormais complété par la branche locale `<type>/<id>-…` (rattachement par convention), et une dépendance `Fait` seulement sur sa branche lève la suivante (« empilée sur <branche> »). Pour que la page reste à jour, laissez tourner `scripts/dashboard.sh --boucle <secondes>`.

## Tests bash reconnus par le contrôle des critères (1.21.0)
Remplacez `factory/` : sans action si votre `.factory.conf` reste inchangé (le contrôle se comporte comme avant). Pour que `criteres-sans-test.sh` et `fin-issue.sh` reconnaissent des tests bash, ajoutez à `.factory.conf` (modèle : `factory/templates/.factory.conf`) `DOSSIER_TESTS=<dossier des .sh>` et, au besoin, `TESTS_BASH_FONCTIONS=<noms des fonctions de test>` (défaut `verifier verdict_cas`). Un test déclare son critère par `verifier "ca10_x" …` en début de ligne. Un `DOSSIER_TESTS` absolu ou contenant `..` est refusé par `fin-issue.sh` (code 64).

## Agents actifs dans le dashboard (1.15.0)
`./factory/sync.sh` installe les hooks des sous-agents dans `.claude/settings.local.json` (non versionné). Si ce fichier a déjà une clé `hooks`, il n'est pas modifié : copiez le bloc affiché par l'avertissement. Relancez ensuite la session Claude Code. Sans hooks (ou sans sous-agent lancé depuis l'installation), le bandeau dit « journal absent » ; les signaux Git des worktrees fonctionnent sans eux.

## Modèle et effort des agents par défaut (1.14.0)
Les défauts passent de `opus` / `low` à `sonnet` / `medium`. Un projet dont `.factory.conf` (ou `.factory.local.conf`, ou `FACTORY_AGENT_*`) définit `AGENT_MODELE` et `AGENT_EFFORT` garde sa configuration : rien à faire. Sans ces clés, il adopte les nouveaux défauts au prochain `./factory/sync.sh` ; pour garder l'ancien comportement, y écrire `AGENT_MODELE=opus` et `AGENT_EFFORT=low`.

## Taille d'une issue (1.14.0)
Règle pour les prochains découpages : environ 10 critères au plus par issue ; une issue plus grosse se découpe, ou justifie sa taille dans le découpage proposé à l'utilisateur et par le champ `criteres_justification:` de son en-tête. Ce chiffre est un ordre de grandeur, pas une mesure ; `scripts/couverture-prd.sh` avertit au-delà de `MAX_CRITERES_ISSUE`, sans échouer. Les issues existantes d'un projet ne sont pas à modifier : le code de sortie ne change pas, l'avertissement reste une information. Ajouter `MAX_CRITERES_ISSUE=10` à `.factory.conf` est facultatif : c'est la valeur par défaut.

## Passer à la structure bare (1.14.0)
`scripts/worktree-issue.sh initialiser <source> <conteneur>` crée le clone bare, règle `origin` et la refspec de suivi, puis fait un fetch, sans toucher à la source. Les fichiers non suivis (`.env`, `.factory.local.conf`) ne sont pas copiés : recréez-les vous-même. Ensuite, un worktree par issue, même seule.
