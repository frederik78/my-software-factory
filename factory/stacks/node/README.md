# Stack `node`

Node 22 et npm (`package-lock.json` requis pour `npm ci`). `npm audit` à niveau élevé ou critique dans le job `securite`.

Fichiers copiés par `./factory/init-projet.sh --stack node` (jamais par-dessus un fichier existant) : `.github/workflows/ci.yml`, `.github/dependabot.yml`, lignes ajoutées au `.gitignore` (`gitignore.append`), `.factory-verify` (commande de vérification lue par `scripts/verify-clean.sh`).
