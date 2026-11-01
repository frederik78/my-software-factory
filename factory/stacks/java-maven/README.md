# Stack `java-maven`

Java 25 et Maven (wrapper `./mvnw`). Hypothèses : le profil Maven `security` lance OWASP Dependency-Check (secret CI `NVD_API_KEY`) ; adapter `java-version` à l'ADR de stack.

Fichiers copiés par `./factory/init-projet.sh --stack java-maven` (jamais par-dessus un fichier existant) : `.github/workflows/ci.yml`, `.github/dependabot.yml`, lignes ajoutées au `.gitignore` (`gitignore.append`), `.factory-verify` (commande de vérification lue par `scripts/verify-clean.sh`).

## Architecture de référence : couches de services
Point de départ de l'ADR d'architecture pour une application Spring Boot, éprouvé sur un projet réel après l'abandon d'un hexagone (`factory/LESSONS.md`, n° 1 et n° 3). Elle s'adapte : chaque écart est consigné dans l'ADR avec sa raison. Une autre architecture reste possible si l'ADR la justifie, par exemple un hexagone quand un domaine riche a plusieurs implémentations réelles de ses frontières.

```text
src/main/java/<package racine>/
├── config/       configuration Spring et propriétés
├── domain/       entités JPA, types et règles métier, erreurs métier
├── repository/   dépôts Spring Data, stockage local
├── service/      cas d'utilisation ; service/dto, service/mapper
├── client/       interfaces des services externes et leurs implémentations
├── security/     authentification et garde-fous
└── web/rest/     XxxResource ; web/rest/errors
src/main/resources/config/liquibase/   master.xml et changelogs
```

| Couche | Accessible par |
|---|---|
| `config` | personne |
| `web` | `config` |
| `service` | `web`, `config` |
| `security` | `config`, `service`, `web` |
| `repository` | `service`, `security`, `config` |
| `client` | `service`, `config` |
| `domain` | toutes les autres |

**Règles, exécutées par des tests ArchUnit qui échouent sur une violation volontaire**
- **Web** : une `XxxResource` valide l'entrée et délègue à un `XxxService`, sans logique métier ni accès aux données.
- **Domaine** : annotations `jakarta.persistence` permises ; aucune dépendance à `web`, à l'API Servlet, à Spring MVC ou à Spring Security. Tout emprunt à Spring ou à Hibernate est une exception nommée et justifiée.
- **Interfaces** : seulement dans `client/`, pour une frontière externe à doubler. Le dépôt, le stockage local et l'authentification restent des classes concrètes.
- **Entité** : pas de setter public ; l'état change par des fabriques et des transitions. Une donnée dérivée, comme un statut, n'est jamais lue d'une source non fiable.
- **DTO** : le JSON est un record `XxxDTO` projeté par MapStruct ; une entité n'est jamais sérialisée.
- **Schéma** : Liquibase seul gère le schéma (`ddl-auto=validate`) ; un changeset appliqué n'est jamais modifié.
- **Nommage** : `XxxResource`, `XxxService`, `XxxRepository`, `XxxDTO`, `XxxMapper`, `XxxTest`.

**Tests par couche**
- `domain/`, `service/` : tests unitaires, collaborateurs doublés ; l'entité se teste sans Spring.
- `web/rest/` : contrat JSON avec `@WebMvcTest` ; sécurité avec sa configuration importée.
- `repository/` : `@DataJpaTest` avec le schéma appliqué par l'outil de migration.
- `client/` : implémentations testées sans service réel.

Le choix d'authentification dépend du client : un jeton Bearer sans état convient à une API sans frontend, une session avec CSRF actif à une application web servie au navigateur.
