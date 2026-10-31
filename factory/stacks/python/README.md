# Stack `python`

Python 3.12, tests `unittest` dans `tests/`. Remplacer par pytest ou `pip install` si le projet a des dépendances. Aucun scan de dépendances par défaut : ajouter `pip-audit` au besoin.

Fichiers copiés par `./factory/init-projet.sh --stack python` (jamais par-dessus un fichier existant) : `.github/workflows/ci.yml`, `.github/dependabot.yml`, lignes ajoutées au `.gitignore` (`gitignore.append`), `.factory-verify` (commande de vérification lue par `scripts/verify-clean.sh`).
