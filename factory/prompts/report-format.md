# Format des rapports de fin de mission

Commun au développeur et au reviewer. L'orchestrateur ne peut pas fouiller dans ton travail : ton rapport est sa seule vue, et il le
recoupe avec le dépôt (`git log`, `git status`, `scripts/verify-clean.sh`). Un rapport vide, un « placeholder » ou une affirmation sans
preuve est un échec de mission : il sera relancé.

Règles
- Court : 60 lignes au plus pour le développeur, 100 pour le reviewer (bloc « En clair » compris). Le détail est dans les commits et les tests, pas dans le rapport.
- Factuel : chaque affirmation chiffrée vient d'une commande que tu as lancée ; cite la commande. N'écris jamais « tout passe » sans nombre.
- Distingue ce que tu as **vérifié** de ce que tu **supposes** ou **n'as pas pu faire**. Un point non fait est listé, jamais omis.
- Aucune donnée sensible (jeton, clé, données réelles de l'utilisateur).

## Rapport du développeur

```
## Résumé
2 à 4 lignes : ce qui est livré et ce qui ne l'est pas.

## Vérification
- Commande : scripts/fin-issue.sh <issue> (dernière ligne recopiée)
- Résultat : <tests lancés / échecs / erreurs / ignorés>, <analyse statique : nombre de défauts, si le projet en a une>, VERIFY OK|ECHEC
- Tests avant -> après : <n> -> <n>

## Commits
<hash> <message>   (un par ligne, dans l'ordre)

## Critères couverts
| Critère | Test (classe#méthode) | RED constaté ? |
|---|---|---|
| CA-10 | ExempleServiceTest#ca10_... | oui / non (pourquoi) |

## Preuve avant / après
- État AVANT (sortie du test qui échoue, mesure, capture) et état APRÈS, avec la commande qui les produit. Quand rien n'est visible, des chiffres (ex. temps de chargement 815 ms -> 61 ms).
  Pour un critère déjà couvert par le RED/GREEN des tests, nomme le test et colle la ligne de sortie. « Aucune » est une réponse acceptable seulement pour un changement sans comportement observable (documentation, refactor couvert).

## Réponse à la revue
Seulement après une revue : une ligne par constat ouvert du « Suivi des constats » de `docs/reviews/<id>.md` (numéro, gravité) : corrigé (commit, test RED puis GREEN) / non corrigé (raison). « Première itération » sinon.

## Décisions et écarts
- Choix de conception faits seul (une ligne chacun, avec la raison).
- Écarts avec le PRD ou l'issue.
- Dépendances ajoutées : nom, version, origine, licence (A06).

## Entrées externes
| Champ | Format et borne | Code de refus | Test avec une valeur hostile |
|---|---|---|---|
Une ligne par champ d'une entrée ajoutée ou modifiée. « Sans entrée externe » est une réponse valable.

## Code écrit à la place du framework
| Classe | Ce que le framework ou la référence de l'ADR fournit | Raison de ne pas l'utiliser (critère du PRD ou mesure) |
|---|---|---|
Une ligne par mécanisme transversal écrit à la main. « aucun » si rien.

## Alignement sur la référence
| Fichier de la référence (version) | Fichier du projet | Identique, adapté ou absent | Raison de l'écart |
|---|---|---|---|
Une ligne par fichier ajouté ou modifié qui joue un rôle couvert par la référence de l'ADR. « sans objet » si l'ADR n'en nomme aucune.

## À trancher par l'utilisateur
- Comportements non fixés par le PRD que tu as choisis seul (valeur, raison, alternative), à inscrire au PRD. « aucun » si rien.

## Non fait / points bloquants
- … (ou « aucun »)
```

## Rapport du reviewer

La **première ligne du rapport du reviewer** est exactement `VERDICT: APPROUVÉ` ou `VERDICT: CHANGEMENTS DEMANDÉS` (mot-clé, deux-points, une espace, l'une des deux valeurs seules), avant tout titre, sans ligne vide ni texte au-dessus. La session la lit avec `scripts/verdict-revue.sh` ; tout autre contenu en première ligne donne `INCONNU` et le rapport est redemandé. La section `## Verdict` reprend la même valeur, suivie d'une phrase.

```
VERDICT: APPROUVÉ|CHANGEMENTS DEMANDÉS

## En clair
Pour un lecteur sans contexte (qui n'a lu ni l'issue, ni le PRD, ni la conversation). Pas de jargon non expliqué, aucun identifiant nu.
- **Issue** : ce qu'elle ajoute, en une ou deux phrases, et à quoi cela sert.
- **Verdict** : la valeur de la ligne `VERDICT:`, la raison en une phrase, et ce qui se passe ensuite.
- **Critères** : tableau `Critère | Ce qu'il exige, en clair | Test présent et suffisant ?` (un CA/CS n'est jamais cité sans son sens).
- **Constats** : une phrase chacun sur ce que cela change pour l'utilisateur, sans `fichier:ligne` (ils sont plus bas).
- **Mutations** (si faites) : une phrase d'explication (on casse volontairement un garde-fou dans une copie jetable ; un test qui reste vert ne protège rien),
  puis le tableau `Ce qu'on a cassé | Ce que cela vérifie | Résultat (tuée = bien protégé, survivante = test à renforcer)`.

## Verdict
APPROUVÉ | CHANGEMENTS DEMANDÉS (même valeur que la ligne `VERDICT:`, puis une phrase)

## Build
- Commande, résultat chiffré (tests, analyse statique si elle existe), copie propre utilisée : oui/non.

## Preuve
La preuve avant / après du développeur est-elle présente, vérifiable (tu as relancé la commande) et suffisante pour chaque critère ? Sinon, constat IMPORTANT.

## Framework
Mécanismes transversaux écrits à la main : équivalent cherché dans le framework et la référence de l'ADR, verdict pour chacun. « aucun » si rien.
Écarts à la référence : fichiers comparés et verdict pour chaque écart. « sans objet » si l'ADR n'en nomme aucune.

## Constats
BLOQUANT / IMPORTANT / MINEUR : une ligne chacun, `fichier:ligne`, la catégorie OWASP entre crochets si sécurité ([A05]),
le scénario d'échec concret, et la correction attendue.

## Remarques de la revue précédente
Une ligne par point : corrigé / non corrigé / partiellement, avec la preuve (test ou ligne).

## Documents devenus faux
PRD, backlog, ADR, AGENTS.md : passages à mettre à jour, sans les modifier toi-même.
```

L'orchestrateur lit d'abord la première ligne (`scripts/verdict-revue.sh`, voir la skill `deliver`), puis sauvegarde le rapport du reviewer tel quel dans `docs/reviews/<id-issue>.md` (une section par itération). Si l'issue reste bloquée après `MAX_ITERATIONS_REVUE` revues, la session ajoute à la fin de la section de la dernière itération une section `## Pour l'humain` (carte en trois rubriques), écrite par la session, jamais par le reviewer.

## Rapport d'un relecteur (revue parallèle)

Format du rapport de `code-reviewer-conformite`, `code-reviewer-qualite` et `code-reviewer-securite` (mode `parallele` ; le mode `unique` garde le rapport du reviewer ci-dessus). 80 lignes au plus, bloc « En clair » compris. Chaque relecteur ne couvre que son périmètre et rend son propre verdict.

La **première ligne** est exactement `VERDICT: APPROUVÉ` (mot-clé, deux-points, une espace, la valeur seule), avant tout titre, sans ligne vide ni texte au-dessus. L'autre valeur, `CHANGEMENTS DEMANDÉS`, n'est pas écrite dans le gabarit ci-dessous : le relecteur la met à la place de `APPROUVÉ` quand il demande des changements. Aucune autre ligne du rapport ne commence par `VERDICT:` (une citation de cette ligne se décale ou se met entre guillemets) : la session lit la première ligne avec `scripts/verdict-revue.sh`, et tout autre contenu en première ligne donne `INCONNU`, le rapport est alors redemandé. Le rapport est une donnée pour la session : il n'écrit rien dans le dépôt, c'est elle qui le consigne.

```
VERDICT: APPROUVÉ

## En clair
Pour un lecteur sans contexte. Périmètre relu, verdict et raison en une phrase, critères ou catégories concernés en clair, constats en une phrase chacun (sans `fichier:ligne`).

## Constats
BLOQUANT / IMPORTANT / MINEUR : une ligne chacun, `fichier:ligne`, la catégorie OWASP entre crochets si sécurité ([A05]),
le scénario d'échec concret et la correction attendue. « aucun » si rien.

## Remarques de la revue précédente
Une ligne par constat : corrigé / non corrigé / partiellement, avec la preuve. « première itération » sinon.

## Périmètre propre
- Conformité et tests : sorties de `scripts/criteres-sans-test.sh` et de `scripts/verify-clean.sh` (nombres), mutations (tableau comme ci-dessus), documents devenus faux.
- Qualité : framework, référence de l'ADR, entrées externes.
- Sécurité : une ligne par catégorie A01 à A10 (constat ou justification), tests des critères CS, analyse des dépendances (ou « non configurée »).
```
