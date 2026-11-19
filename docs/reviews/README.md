# Revues

Rapports du rôle `code-reviewer`, un fichier par issue : `docs/reviews/<id-issue>.md` (ex. `001-03.md`), une section `## Itération <n> (<date>)`
par passage. L'orchestrateur (skill `/deliver`) seul écrit ce fichier ; le relecteur reste en lecture seule. Chaque rapport suit `factory/prompts/report-format.md`.
Ils servent de piste d'audit (qui a vu quoi, ce qui a été corrigé) et permettent de retrouver les points mineurs laissés ouverts.

## Format du fichier
- **Première ligne** : `VERDICT: <valeur>` (`APPROUVÉ` ou `CHANGEMENTS DEMANDÉS`), le verdict de la dernière itération. C'est la seule ligne `VERDICT:` du fichier : aucune ligne autre que la première ne commence par `VERDICT:` (y compris dans une citation ou un bloc de code). La session la met à jour à chaque itération avec la valeur rendue par `scripts/verdict-revue.sh`.
- Ensuite : un titre, le tableau « Suivi des constats », puis une section `## Itération <n> (<date>)` par revue. Chaque section commence par `Verdict de l'itération : <valeur>` : cette ligne remplace la ligne `VERDICT:` du rapport, le reste du rapport est recopié tel quel. `n` est le rang de la revue (1, 2, 3…) ; une relance sur `INCONNU` ne crée pas d'itération.

## Suivi des constats
Le fichier d'une issue porte, en tête, un tableau tenu par l'orchestrateur : `# | Gravité | Constat | Statut (ouvert / corrigé / refusé + raison) | Itération`. C'est la mémoire de l'issue : le développeur le lit en entier avant de corriger et répond à chaque constat ouvert (section « Réponse à la revue » de son rapport) ; le relecteur suivant s'en sert pour confirmer chaque point. Les mineurs ouverts y restent visibles d'une itération à l'autre.

## Lire une revue sans contexte
Chaque itération s'ouvre par un bloc « En clair » (l'issue, le verdict, le sens de chaque critère, les constats, les mutations). Le reste est le détail technique.
- **Verdict** : première ligne du fichier, `VERDICT: APPROUVÉ` ou `VERDICT: CHANGEMENTS DEMANDÉS` (lue par `scripts/verdict-revue.sh`) ; chaque section d'itération redit sa valeur dans `Verdict de l'itération : …` ; `APPROUVÉ` (rien de bloquant, l'issue peut avancer) ou `CHANGEMENTS DEMANDÉS` (corrections à faire, puis nouvelle revue).
- **BLOQUANT** : empêche la livraison (défaut grave, vulnérabilité OWASP avérée). **IMPORTANT** : à corriger avant d'approuver. **MINEUR** : amélioration, consignée sans bloquer.
- **CA-xx / CS-xx** : critère d'acceptation (comportement attendu) / critère de sécurité, définis dans le PRD de l'issue.
- **RED / GREEN** : le test échoue avant le code (RED), puis réussit après (GREEN) ; preuve que le test vérifie vraiment quelque chose.
- **Mutation** : le relecteur casse volontairement un garde-fou dans une copie jetable et relance les tests. *Tuée* : un test devient rouge, le garde-fou est protégé. *Survivante* : tout reste vert, le test est trop faible. *Équivalente* : la casse ne change aucun comportement.
- **OWASP A01 à A10** : catégories de risques de sécurité (skill `owasp-check`).
- **Copie propre** : le build tourne dans une copie du dépôt (`scripts/verify-clean.sh`), indépendante de l'IDE et des fichiers non versionnés.
- **Pour l'humain** : section `## Pour l'humain` écrite par la session (jamais par le relecteur), seulement quand l'issue reste bloquée après `MAX_ITERATIONS_REVUE` revues sans `APPROUVÉ`, à la fin de la section de la dernière itération, sans aucune ligne `VERDICT:`. Trois rubriques : `**Décision à prendre**`, `**Fichiers à lire**`, `**Vérification suggérée**`. La même carte ouvre le courriel de blocage.
