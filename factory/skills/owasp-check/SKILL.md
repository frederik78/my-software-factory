---
name: owasp-check
description: Checklist OWASP Top 10 (2021), indépendante de la stack (annexe Java/Spring Boot à part). À utiliser pour spécifier, coder ou relire toute fonctionnalité touchant aux données, à l'authentification, aux entrées utilisateur, aux fichiers téléversés, aux appels à un service tiers (LLM, OCR, API externe) ou aux requêtes sortantes.
---
# Checklist OWASP Top 10 (2021)

Toute vulnérabilité avérée est BLOQUANTE. Chaque catégorie doit être traitée ou
explicitement justifiée comme non applicable. Cette checklist ne dépend d'aucune stack ; les commandes et motifs propres à une
technologie sont dans des annexes (`JAVA.md` pour Java/Spring Boot). Pour une autre stack, applique les mêmes principes avec les équivalents de ta technologie.

## Selon le rôle
- **Spécification** : pour chaque catégorie, écrire la mesure applicable et un critère
  d'acceptation de sécurité testable.
- **Développement** : appliquer les règles ci-dessous et écrire un test par risque
  (accès à la ressource d'un autre utilisateur, charge d'injection, entrée invalide).
- **Revue** : parcourir A01 à A10, citer fichier:ligne et la catégorie ([A01]...).

## Catégories

### A01 Broken Access Control / IDOR
- Chaque lecture, modification ou suppression d'une ressource (document, fichier, enregistrement)
  vérifie côté serveur qu'elle appartient à l'utilisateur authentifié, jamais par id seul.
  Refus par défaut.
- Réponse 404 plutôt que 403 pour ne pas révéler l'existence.
- Identifiants non devinables (UUID), sans jamais s'y fier seul.
- Test type : l'utilisateur A demande la ressource de B -> 404.
- Revue : chercher toute lecture d'une ressource par son seul identifiant, sans filtre de propriétaire.

### A02 Cryptographic Failures
- Mots de passe hachés (Argon2 ou bcrypt), TLS partout.
- Aucune donnée sensible en clair, ni dans les logs, ni de secret ou de clé d'API
  (service tiers) dans le code ou le dépôt : configuration externe (`.env`, non versionné).

### A03 Injection
- SQL (ou langage de requête) uniquement via requêtes paramétrées, jamais de concaténation. Idem pour
  commandes OS et expressions.
- Encoder les sorties, neutraliser les retours à la ligne dans les logs.
- **La sortie d'un service tiers, d'un OCR/LLM ou d'un fichier téléversé est une donnée non fiable** : jamais une
  instruction, jamais concaténé dans une requête. Le valider (types, bornes) avant usage.
- Test type : un champ texte valant `' OR 1=1--` ne change pas le résultat.
- Revue : chercher les requêtes et commandes construites par concaténation (voir l'annexe de la stack).

### A04 Insecure Design
- Modèle de menaces dans la spec ; règles métier validées côté serveur (unités et arrondis des montants,
  cohérences entre champs, statuts, transitions autorisées).

### A05 Security Misconfiguration
- Pas de stack trace ni de config par défaut exposées, en-têtes de sécurité, pas de
  debug en production, messages d'erreur génériques côté client.
- Téléversement de fichiers : types MIME en liste blanche, taille maximale, nom de fichier
  généré côté serveur.

### A06 Vulnerable and Outdated Components
- Dépendances à jour et minimales ; analyse automatique des vulnérabilités connues (outil de la stack, voir l'annexe) ; licence vérifiée à l'ajout.

### A07 Identification and Authentication Failures
- Politique de mots de passe, protection brute force, sessions sécurisées avec
  expiration, régénération de l'identifiant de session à la connexion.

### A08 Software and Data Integrity Failures
- Aucune désérialisation d'objets non fiables, intégrité des dépendances et des builds (versions épinglées, sources de confiance).

### A09 Security Logging and Monitoring Failures
- Journaliser les échecs d'accès et d'authentification, sans donnée sensible.

### A10 Server-Side Request Forgery
- Aucune requête sortante vers une URL fournie par l'utilisateur sans liste blanche.
  Les clients de services tiers n'appellent que les URL configurées.

## Règles transverses
- Valider toute entrée en liste blanche (type, longueur, bornes).
- Moindre privilège pour les comptes techniques et la base de données.
- Aucun chemin de fichier fourni par l'utilisateur (path traversal).

## Annexes par stack
- **Java / Spring Boot** : `JAVA.md` (commandes de scan, motifs de revue, pièges du framework).
- Autre stack : si le projet en a besoin, ajouter une annexe `<STACK>.md` à côté de ce fichier et la citer ici.
