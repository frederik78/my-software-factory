# Annexe Java / Spring Boot

Compléments de `SKILL.md` pour une application Java (Spring Boot, JPA, Maven).

## Motifs de revue
- [A01] Chercher tout `findById(` / `getById(` sans filtre de propriétaire.
- [A03] Grep de `+` près de `SELECT`, `createQuery`, `createNativeQuery`, `Statement`, `Runtime.exec`, `ProcessBuilder`. Requêtes Spring Data dérivées ou `@Query` avec paramètres nommés uniquement.
- [A03] URL JDBC ou de service construites depuis une propriété : refuser `?`, `#` et tout caractère inattendu.
- [A08] Aucun `ObjectInputStream`, aucune désérialisation polymorphe (`enableDefaultTyping`) ; le vérifier par un test d'architecture.

## Outils
- [A06] Analyse des dépendances : `./mvnw org.owasp:dependency-check-maven:check` (clé NVD requise, secret `NVD_API_KEY` en CI) ou le profil Maven `security` du projet.
- Analyse statique de sécurité : SpotBugs avec Find Security Bugs, branchée sur `verify` (le build échoue sur une faille). Toute exclusion est ciblée (classe et motif) et justifiée par écrit.
- Règles d'architecture exécutées par ArchUnit (pas de logique métier ni d'accès aux données dans la couche web, pas de dépendance interdite).

## Spring Boot / Spring Security
- Chaîne de filtres explicite (`SecurityFilterChain`), refus par défaut (`anyRequest().authenticated()`), seules les routes publiques listées une à une.
- API sans cookie ni session : sessions `STATELESS`, CSRF désactivé avec justification et exclusion SpotBugs ciblée.
- En-têtes de sécurité (`nosniff`, CSP, HSTS en HTTPS, `Cache-Control: no-store` pour les réponses sensibles), erreurs génériques (aucune trace de pile, de classe ni de chemin).
- Les requêtes rejetées avant l'application (pare-feu HTTP de Spring Security, serveur) doivent porter les mêmes en-têtes et un corps d'erreur générique : les tester sur serveur réel (port aléatoire).
- Derrière un proxy : `server.forward-headers-strategy`, ordre de `ForwardedHeaderFilter` avant les filtres de sécurité ; le proxy écrase `X-Forwarded-*`.
- Comparaison de secrets en temps constant (`MessageDigest.isEqual` sur des condensés).
