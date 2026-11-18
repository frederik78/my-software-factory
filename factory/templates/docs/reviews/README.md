# Revues

Rapports du rôle `code-reviewer`, un fichier par issue : `docs/reviews/<id-issue>.md` (ex. `001-03.md`), une section datée « Itération n »
par passage. L'orchestrateur (skill `/deliver`) les écrit tels que reçus, au format de `factory/prompts/report-format.md`.
Ils servent de piste d'audit (qui a vu quoi, ce qui a été corrigé) et permettent de retrouver les points mineurs laissés ouverts.

## Suivi des constats
Le fichier d'une issue porte, en tête, un tableau tenu par l'orchestrateur : `# | Gravité | Constat | Statut (ouvert / corrigé / refusé + raison) | Itération`. C'est la mémoire de l'issue : le développeur le lit en entier avant de corriger et répond à chaque constat ouvert (section « Réponse à la revue » de son rapport) ; le relecteur suivant s'en sert pour confirmer chaque point. Les mineurs ouverts y restent visibles d'une itération à l'autre.

## Lire une revue sans contexte
Chaque itération s'ouvre par un bloc « En clair » (l'issue, le verdict, le sens de chaque critère, les constats, les mutations). Le reste est le détail technique.
- **Verdict** : première ligne de chaque rapport, `VERDICT: APPROUVÉ` ou `VERDICT: CHANGEMENTS DEMANDÉS` (lue par `scripts/verdict-revue.sh`, reprise dans la section `## Verdict`) ; `APPROUVÉ` (rien de bloquant, l'issue peut avancer) ou `CHANGEMENTS DEMANDÉS` (corrections à faire, puis nouvelle revue).
- **BLOQUANT** : empêche la livraison (défaut grave, vulnérabilité OWASP avérée). **IMPORTANT** : à corriger avant d'approuver. **MINEUR** : amélioration, consignée sans bloquer.
- **CA-xx / CS-xx** : critère d'acceptation (comportement attendu) / critère de sécurité, définis dans le PRD de l'issue.
- **RED / GREEN** : le test échoue avant le code (RED), puis réussit après (GREEN) ; preuve que le test vérifie vraiment quelque chose.
- **Mutation** : le relecteur casse volontairement un garde-fou dans une copie jetable et relance les tests. *Tuée* : un test devient rouge, le garde-fou est protégé. *Survivante* : tout reste vert, le test est trop faible. *Équivalente* : la casse ne change aucun comportement.
- **OWASP A01 à A10** : catégories de risques de sécurité (skill `owasp-check`).
- **Copie propre** : le build tourne dans une copie du dépôt (`scripts/verify-clean.sh`), indépendante de l'IDE et des fichiers non versionnés.
