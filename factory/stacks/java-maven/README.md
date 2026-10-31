# Stack `java-maven`

Java 25 et Maven (wrapper `./mvnw`). Hypothèses : le profil Maven `security` lance OWASP Dependency-Check (secret CI `NVD_API_KEY`) ; adapter `java-version` à l'ADR de stack.

Fichiers copiés par `./factory/init-projet.sh --stack java-maven` (jamais par-dessus un fichier existant) : `.github/workflows/ci.yml`, `.github/dependabot.yml`, lignes ajoutées au `.gitignore` (`gitignore.append`), `.factory-verify` (commande de vérification lue par `scripts/verify-clean.sh`).
