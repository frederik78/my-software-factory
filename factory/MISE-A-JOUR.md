# Mettre à jour la factory dans un projet

La factory est un dossier `factory/` copié (ou ajouté en sous-module git) dans chaque projet. Le fichier `.factory-version` à la racine du projet dit avec
quelle version il a été initialisé ; `factory/VERSION` donne celle du dossier présent.

1. Lire `factory/CHANGELOG.md` entre les deux versions. Une montée de version majeure change une convention : lire ses notes de migration.
2. Remplacer le dossier `factory/` par la nouvelle version (ou mettre à jour le sous-module). Les modifications locales des skills copiés sont notées dans
   `factory/skills/SOURCES.md` : les reporter à la main.
3. Relancer `./factory/init-projet.sh` : il ne remplace aucun fichier existant, crée ceux qui manquent (nouveaux modèles), lie les nouveaux scripts, régénère les agents et
   met à jour `.factory-version`.
4. Comparer les fichiers du projet issus des modèles avec leur nouvelle version (`diff -r factory/templates/ .` en ignorant les fichiers propres au projet) pour
   reprendre à la main ce qui vous intéresse : `AGENTS.md`, `.claude/settings.json`, `docs/agents/*`, et pour la stack du projet `diff -r factory/stacks/<stack>/.github .github` (CI, Dependabot).
5. Lancer `factory/scripts/tests/run.sh`, puis `scripts/verify-clean.sh`.
