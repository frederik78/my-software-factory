# PRD 012 : un test en échec est nommé là où on le lit

## En clair
*Lecture sans contexte : ce bloc résume le document ; les règles et critères qui suivent sont destinés aux tests.*

**Le problème.** La suite de tests de la factory (`factory/scripts/tests/run.sh`) écrit environ 2 600 lignes ; chaque échec y est une ligne `  ECHEC <nom>` suivie de sa raison, perdue au milieu des succès. `scripts/verify-clean.sh` lance cette suite dans une copie propre et, en échec, n'affiche que les 60 dernières lignes du journal puis le résumé `Tests : TESTS EN ECHEC : x sur n`. `scripts/fin-issue.sh` recopie cette sortie et finit par `FIN-ISSUE ECHEC : build en échec (code 1) ; …`. Aucun de ces endroits ne nomme le test en échec : le 2026-11-25, le cas `ca03` de 008-01 n'apparaissait nulle part dans la sortie lue.

**Ce que ce besoin change**
1. **La suite récapitule ses échecs** : juste avant sa ligne de résumé, une ligne par test en échec (nom et raison), dans l'ordre où ils ont échoué.
2. **`verify-clean.sh` recopie ce récapitulatif** juste avant sa ligne `Tests : …`, borné (20 tests au plus, 300 caractères par ligne) et neutralisé (aucun caractère de contrôle).
3. **`fin-issue.sh` le recopie aussi**, juste avant sa dernière ligne, avec les mêmes bornes.
4. **Rien d'autre ne bouge** : la ligne de résumé de la suite, les lignes `Tests : …`, `VERIFY …` et `FIN-ISSUE …`, et tous les codes de sortie restent identiques ; une suite sans échec a la même sortie qu'avant.

**Hors de ce besoin** : nommer les échecs des autres outils de test (Maven, Gradle, unittest, pytest, jest, node:test : section 2.4) ; lire le nombre d'échecs de `TESTS EN ECHEC : x sur n` dans la dernière ligne de `fin-issue.sh` (Q-04) ; compter les échecs survenus dans un sous-processus de la suite (non comptés aujourd'hui, toujours non comptés) ; changer les lignes `  ECHEC` de la suite.

**Comment lire la suite** : section 2, les règles (RG-xx) ; section 4, le catalogue des messages ; section 5, 14 critères ; section 6, 7 critères de sécurité ; section 7, décisions ; section 8, les questions ouvertes ; section 9, le découpage en 3 issues.

Besoin : F-17 (`backlog.md`, demandé par l'utilisateur le 2026-11-25 : « circuit besoin, PRD court, issues »). Aucune décision D-xx n'est encore prise pour F-17.
Le « produit » est la factory elle-même (scripts bash, Markdown). Les noms de commande et les textes de sortie sont des contrats ; aucune structure de code n'est décrite.
Contraintes de plateforme : bash 3.2 de macOS (pas d'options GNU) ; aucune dépendance ajoutée. Pas d'ADR.

## 1. Contexte et besoin

### Acteurs
- **Session orchestrateur, developer, reviewer** : lisent la sortie de `scripts/verify-clean.sh` et de `scripts/fin-issue.sh` (souvent seulement la fin) pour décider de la suite.
- **Mainteneur de la factory** : lance `factory/scripts/tests/run.sh` directement.
- **Projet qui utilise la factory** : sa propre commande de build (Maven, pytest…), non concernée (RG-14).

### Existant (observé à la lecture des scripts)
- **Suite** (`run.sh`) : un succès écrit `  ok   <nom>` ; un échec écrit deux lignes, `  ECHEC <nom>` puis la raison indentée de 8 espaces (vide si l'appel n'en donne pas). La raison contient souvent un extrait de sortie de commande (5 premières lignes jointes par `|`), donc des caractères quelconques, y compris ESC ou retour chariot. La dernière ligne est `TESTS OK : <n> vérifications` ou `TESTS EN ECHEC : <x> sur <n>` ; code 0 ou 1. Rien n'est écrit après.
- **`verify-clean.sh`** : la sortie du build va dans un journal (supprimé à la fin, sauf `--keep`). Sur code non nul : `--- Fin du journal du build (60 dernières lignes) ---` puis ces 60 lignes. Ensuite toujours `Tests : <résumé>` (dernier résumé de la suite reconnu par une ligne qui commence exactement par `TESTS OK : ` ou `TESTS EN ECHEC : `), éventuellement `Analyse statique : …`, puis `VERIFY OK` ou `VERIFY ECHEC (code <n>)`. Plusieurs types de résumé dans un journal donnent `Tests : plusieurs types de résumé (…)`. Les motifs de résumé sont ancrés en début de ligne.
- **`fin-issue.sh`** : recopie toute la sortie de `verify-clean.sh`, puis celle du contrôle des critères, puis sa dernière ligne `FIN-ISSUE OK …` ou `FIN-ISSUE ECHEC : <raisons>`. Il lit le résumé dans la dernière ligne qui commence par `Tests : `. Pour `TESTS EN ECHEC : x sur n`, il ne lit ni total ni ignorés : raison « nombre de tests ignorés illisible dans le résumé (« TESTS EN ECHEC : x sur n »), aucun succès annoncé » (voir Q-04).
- **Tests qui figent ces sorties** (`run.sh`) : « résumé de la suite de la factory reconnu (succès) » et « (échec) » (`Tests : TESTS OK : 142 vérifications`, `Tests : TESTS EN ECHEC : 2 sur 145`, journal sans récapitulatif) ; cas `fin-issue` sur la suite de la factory (`FIN-ISSUE OK 001-01 … : 9 tests, 0 échec, 0 ignoré`) ; cas de lecture des résumés Maven, unittest, pytest, jest, node:test et « plusieurs types ». Ils doivent passer sans modification (CA-14).

### Besoin
Qu'un lecteur de la fin de sortie de la suite, de `verify-clean.sh` ou de `fin-issue.sh` voie le nom et la raison de chaque test en échec (dans la limite des bornes), sans que les lignes et codes lus par les machines changent.

## 2. Exigences fonctionnelles et règles de gestion

Vocabulaire : **échec** = une vérification comptée dans le `x` de `TESTS EN ECHEC : x sur n` ; **nom** = le libellé de la vérification (celui de la ligne `  ECHEC <nom>`) ; **raison** = le texte de la ligne indentée qui la suit ; **récapitulatif** = les lignes de la règle RG-01 ; **bloc** = ce que `verify-clean.sh` et `fin-issue.sh` en recopient (RG-07) ; **neutraliser** = remplacer retour chariot, saut de ligne et tabulation par une espace et retirer les autres caractères de contrôle (codes 0 à 31 et 127), comme la règle RG-21 du PRD 004.

### 2.1 Récapitulatif de la suite (F-17, exigence 1)
- **RG-01 (forme)** Si la suite compte au moins un échec, elle écrit, après le dernier cas et juste avant sa ligne de résumé : une ligne `Récapitulatif des échecs (<x>) :`, puis exactement `<x>` lignes `  - <nom> : <raison>`, une par échec, dans l'ordre où les échecs se sont produits. La ligne de résumé suit immédiatement et reste la dernière ligne.
- **RG-02 (contenu)** Un même nom en échec plusieurs fois donne autant de lignes. Une raison vide donne `(raison non précisée)`. Tout échec compté figure, qu'il vienne d'une vérification ordinaire ou d'un échec enregistré directement par la suite.
- **RG-03 (une ligne par échec)** Nom et raison sont neutralisés dans le récapitulatif : chaque échec y tient sur une seule ligne, sans caractère de contrôle. Ils ne sont pas tronqués dans la suite (l'information complète reste dans son propre journal) [À CLARIFIER Q-02 : lecture retenue, pas de borne de longueur dans la suite].
- **RG-04 (inchangé)** Sans échec, rien n'est ajouté : la sortie est identique à celle de la version précédente. Avec échec, les lignes `  ECHEC <nom>` et leur raison restent écrites au fil de l'eau comme aujourd'hui ; la ligne de résumé, son format et le code de sortie (0 ou 1) sont inchangés.

### 2.2 `verify-clean.sh` (F-17, exigence 2)
- **RG-05 (quand)** Le bloc est écrit si et seulement si la ligne `Tests : …` que le script écrit est `Tests : TESTS EN ECHEC : <x> sur <n>` (la suite de la factory seule, RG-15). Il est écrit après la section « Fin du journal » (si elle existe) et immédiatement avant la ligne `Tests : …`. Le code de sortie du build n'entre pas dans la condition.
- **RG-06 (lecture du récapitulatif)** Le récapitulatif lu est celui qui précède immédiatement la dernière ligne de résumé de la suite dans le journal : une ligne `Récapitulatif des échecs (<x>) :` avec le même `<x>` que ce résumé, suivie d'exactement `<x>` lignes commençant par `  - `, sans autre ligne entre elles et le résumé. Tout autre cas (suite d'une version précédente sans récapitulatif, nombre différent, ligne intercalée, en-tête absent) donne l'en-tête « illisible » seul (catalogue, section 4) ; rien d'autre du journal n'est recopié.
- **RG-07 (contenu du bloc)** En-tête `--- Tests en échec de la suite de la factory (<x>) ---`, puis, pour les 20 premiers échecs du récapitulatif dans leur ordre, une ligne `ECHEC <nom> : <raison>` ; si `<x>` dépasse 20, une dernière ligne `… et <x-20> autre(s) test(s) en échec non recopié(s)` [À CLARIFIER Q-02 : 20].
- **RG-08 (bornes et neutralisation)** Chaque ligne du bloc est neutralisée (le journal est une donnée non fiable, même si la suite a déjà neutralisé), puis limitée à 300 caractères, suffixe `…` compris, sans jamais couper un caractère multioctet [À CLARIFIER Q-02 : 300]. Le bloc compte donc au plus 22 lignes.
- **RG-09 (inchangé)** La section « Fin du journal » (60 dernières lignes, brutes, comme aujourd'hui), la ligne `Tests : …`, la ligne `Analyse statique : …`, la ligne `VERIFY OK` ou `VERIFY ECHEC (code <n>)` et le code de sortie sont identiques à ceux de la version précédente pour le même journal. Aucune ligne du récapitulatif ni du bloc ne crée, ne modifie ni ne masque un type de résumé reconnu.
- **RG-10 (coût)** Au plus une lecture supplémentaire du journal, de durée proportionnelle à sa taille ; aucun autre fichier lu ou écrit.

### 2.3 `fin-issue.sh` (F-17, exigence 2)
- **RG-11 (quand et où)** Si le résumé lu dans la sortie de `verify-clean.sh` est `TESTS EN ECHEC : …`, `fin-issue.sh` recopie le bloc de `verify-clean.sh` (de la dernière ligne qui commence par `--- Tests en échec de la suite de la factory ` jusqu'à la ligne qui précède la dernière ligne `Tests : `) immédiatement avant sa dernière ligne, quelle qu'elle soit (`FIN-ISSUE ECHEC : …`, ou `FIN-ISSUE OK …` si une autorisation le permet). Sinon rien n'est ajouté [À CLARIFIER Q-01 : lecture retenue, recopie avant la dernière ligne].
- **RG-12 (bornes)** Le bloc recopié compte au plus 22 lignes ; chaque ligne est neutralisée et limitée à 300 caractères comme en RG-08 (sans effet sur un bloc déjà conforme).
- **RG-13 (inchangé)** La dernière ligne (`FIN-ISSUE OK …` ou `FIN-ISSUE ECHEC : <raisons>`) est identique octet pour octet à celle de la version précédente pour les mêmes entrées, ainsi que le code de sortie (0, 1, 64), la lecture du résumé et le reste de la sortie. Arrêt avant `verify-clean.sh` (arbre sale, fichiers marqués) ou `verify-clean.sh` en code 64 : rien n'est ajouté.

### 2.4 Autres outils de test (exclus)
- **RG-14 (exclusion explicite)** Pour Maven, Gradle, unittest, pytest, jest et node:test, rien ne change : aucun bloc, sortie de `verify-clean.sh` et de `fin-issue.sh` identique octet pour octet. Raison : chacun écrit déjà son propre récapitulatif d'échecs en fin de sortie (surefire « Failures: » et la liste des tests en échec, pytest « short test summary info », jest « Summary of all failing tests », node:test « failing tests: »), en général visible dans les 60 dernières lignes ; leur extraction serait un autre besoin [À CLARIFIER Q-03].
- **RG-15 (plusieurs types de résumé)** Quand le journal contient la suite de la factory et un autre outil (`Tests : plusieurs types de résumé (…)`), aucun bloc n'est écrit, même si la suite a échoué.

### 2.5 Documentation, version
- **RG-16** L'en-tête de `run.sh`, de `verify-clean.sh` et de `fin-issue.sh` dit en une phrase ce qui est ajouté (récapitulatif, bloc borné, exclusion des autres outils) ; `factory/README.md` aussi s'il décrit ces sorties. Version suivante libre, entrée dans `factory/CHANGELOG.md` et `factory/UPGRADE.md` (comportement, migration « remplacer `factory/` », aucune donnée migrée). Pas d'ADR.

## 3. Modèle de données (point de vue métier)
- **Échec** : nom (texte), raison (texte, éventuellement vide), rang d'apparition.
- **Récapitulatif** : en-tête avec le nombre d'échecs, une ligne par échec ; lisible (conforme à RG-06) ou illisible.
- **Bloc** : en-tête, 0 à 20 lignes d'échec, ligne de dépassement éventuelle ; 22 lignes et 300 caractères par ligne au plus.

## 4. Contrats externes et catalogue des messages
`<x>`, `<n>`, `<r>` sont des entiers ; `<nom>` et `<raison>` sont des valeurs neutralisées.

| Émetteur | Texte exact | Quand |
|---|---|---|
| suite | `Récapitulatif des échecs (<x>) :` | au moins un échec (RG-01) |
| suite | `  - <nom> : <raison>` | une par échec (RG-01, RG-02) |
| suite | `(raison non précisée)` | à la place d'une raison vide (RG-02) |
| `verify-clean.sh`, `fin-issue.sh` | `--- Tests en échec de la suite de la factory (<x>) ---` | récapitulatif lisible (RG-06, RG-07) |
| `verify-clean.sh`, `fin-issue.sh` | `--- Tests en échec de la suite de la factory : récapitulatif absent ou illisible ---` | résumé `TESTS EN ECHEC` sans récapitulatif lisible (RG-06) |
| `verify-clean.sh`, `fin-issue.sh` | `ECHEC <nom> : <raison>` | une par échec, 20 au plus (RG-07) |
| `verify-clean.sh`, `fin-issue.sh` | `… et <r> autre(s) test(s) en échec non recopié(s)` | plus de 20 échecs (RG-07) |

Inchangés : `TESTS OK : <n> vérifications`, `TESTS EN ECHEC : <x> sur <n>`, `--- Fin du journal du build (60 dernières lignes) ---`, `Tests : …`, `Analyse statique : …`, `VERIFY OK`, `VERIFY ECHEC (code <n>)`, `FIN-ISSUE OK …`, `FIN-ISSUE ECHEC : …` ; codes de sortie des trois scripts.

Ordre de la fin de sortie avec échecs de la suite :
- suite : `… cas …`, `Récapitulatif des échecs (2) :`, `  - ca03_x : code 1 au lieu de 0 ; sortie : …`, `  - cs01_y : (raison non précisée)`, `TESTS EN ECHEC : 2 sur 2600` ;
- `verify-clean.sh` : section « Fin du journal », `--- Tests en échec de la suite de la factory (2) ---`, `ECHEC ca03_x : …`, `ECHEC cs01_y : (raison non précisée)`, `Tests : TESTS EN ECHEC : 2 sur 2600`, `VERIFY ECHEC (code 1)` ;
- `fin-issue.sh` : sortie de `verify-clean.sh`, sortie du contrôle des critères, le bloc (3 lignes), `FIN-ISSUE ECHEC : build en échec (code 1) ; …` (inchangée).

## 5. Critères d'acceptation
Les tests sont dans `factory/scripts/tests/run.sh`, nommés `ca01_…`, `cs01_…`. Seams : pour la suite, une exécution de la suite sur des cas factices dans un projet jetable (la garde contre la relance récursive reste active) ; pour `verify-clean.sh` et `fin-issue.sh`, un projet jetable dont la commande de build (`.factory-verify`) écrit un journal fabriqué, comme les cas existants. Non-régression « identique à la version précédente » : comparaison avec la sortie du script de la version précédente (copie tirée de l'historique ou sortie figée dans le test) sur le même journal.

### Suite
- **CA-01** Given une suite factice avec des succès et deux échecs (l'un avec raison, l'autre sans), When on la lance, Then les quatre dernières lignes sont `Récapitulatif des échecs (2) :`, `  - <nom1> : <raison1>`, `  - <nom2> : (raison non précisée)`, `TESTS EN ECHEC : 2 sur <n>`, le code est 1, et les lignes `  ECHEC <nom>` écrites au fil de l'eau sont inchangées.
- **CA-02** Given une suite factice sans échec, When on la lance, Then sa sortie est identique à celle de la version précédente (aucune ligne `Récapitulatif`), la dernière ligne est `TESTS OK : <n> vérifications`, code 0.
- **CA-03** Given une suite factice où un même nom échoue deux fois et un échec est enregistré directement sans raison, When on la lance, Then le récapitulatif a 3 lignes dans l'ordre des échecs et son nombre égale le `x` du résumé.

### `verify-clean.sh`
- **CA-04** Given un journal qui contient un récapitulatif de 3 échecs suivi de `TESTS EN ECHEC : 3 sur 10` (code 1), When on lance `verify-clean.sh`, Then la sortie contient la section « Fin du journal », puis l'en-tête `--- Tests en échec de la suite de la factory (3) ---`, les 3 lignes `ECHEC <nom> : <raison>` dans l'ordre, puis `Tests : TESTS EN ECHEC : 3 sur 10` et `VERIFY ECHEC (code 1)` en dernière ligne, code 1.
- **CA-05** Given un récapitulatif de 25 échecs, When on lance `verify-clean.sh`, Then le bloc a l'en-tête (25), les 20 premiers échecs dans l'ordre et la ligne `… et 5 autre(s) test(s) en échec non recopié(s)`.
- **CA-06** Given un journal `TESTS EN ECHEC : 2 sur 145` sans récapitulatif (cas existant), puis un récapitulatif annonçant 3 échecs pour un résumé de 2, puis un récapitulatif séparé du résumé par une autre ligne, When on lance `verify-clean.sh`, Then le bloc est le seul en-tête « récapitulatif absent ou illisible », et les lignes `Tests : …`, `VERIFY …` et le code sont ceux de la version précédente.
- **CA-07** Given un journal où la suite tourne deux fois (un premier récapitulatif et résumé en échec, puis un second), When on lance `verify-clean.sh`, Then le bloc ne reprend que le récapitulatif du dernier résumé.
- **CA-08** Given des journaux de succès de la suite, de succès et d'échec Maven, unittest, pytest, jest et node:test, et un journal « plusieurs types de résumé » où la suite échoue, When on lance `verify-clean.sh`, Then la sortie et le code sont identiques octet pour octet à ceux de la version précédente (aucun bloc).

### `fin-issue.sh`
- **CA-09** Given un projet dont le build écrit un récapitulatif de 2 échecs et `TESTS EN ECHEC : 2 sur 9` (code 1), When on lance `fin-issue.sh 001-01`, Then le bloc (en-tête et 2 lignes) apparaît immédiatement avant la dernière ligne, après la sortie du contrôle des critères, la dernière ligne est identique à celle de la version précédente et le code est 1.
- **CA-10** Given les cas existants de `fin-issue.sh` (succès de la suite, Maven, pytest, unittest, ignorés, illisible, arbre sale, code 64), When on les relance, Then leur sortie, leur dernière ligne et leur code sont identiques à ceux de la version précédente.
- **CA-11** Given `FIN_ISSUE_IGNORES_AUTORISES=inconnu` et un build qui écrit un récapitulatif et `TESTS EN ECHEC : 1 sur 3` puis rend 0, When on lance `fin-issue.sh`, Then le bloc précède la dernière ligne, et cette dernière ligne et le code sont ceux de la version précédente.

### Coût, documentation, tests
- **CA-12** Given un journal de 10 000 échecs (noms de 300 caractères) et le même journal sous la version précédente, When on mesure `verify-clean.sh` puis `fin-issue.sh`, Then chacun ajoute au plus 22 lignes à sa sortie et son surcoût mesuré est inférieur à 5 s ; la suite sans échec n'écrit aucune ligne de plus.
- **CA-13** Given le dépôt livré, When on lit les en-têtes de `run.sh`, `verify-clean.sh`, `fin-issue.sh`, `factory/VERSION`, `factory/CHANGELOG.md` et `factory/UPGRADE.md`, Then ils décrivent le récapitulatif, le bloc borné et l'exclusion des autres outils (RG-16), à la version suivante libre.
- **CA-14** Given `run.sh`, When on le lance, Then les cas CA-01 à CA-13 et CS-01 à CS-07 y figurent avec leur identifiant, dans des projets jetables isolés (`GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM`, `HOME`), sans réseau, à durée bornée, et les tests existants qui figent ces sorties passent sans modification (toute modification est listée et justifiée dans l'issue).

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : le terminal du lecteur (aucune séquence de contrôle injectée), la fiabilité des lignes lues par les machines (`Tests : …`, `VERIFY …`, `FIN-ISSUE …`), le code de sortie.
- **Acteurs** : un test dont le nom ou la sortie (donc la raison) contient du texte hostile ; une commande de build qui écrit dans le journal des lignes qui imitent un résumé ou un bloc.
- **Points d'entrée** : le journal du build (données non fiables, lues comme du texte), la sortie de `verify-clean.sh` lue par `fin-issue.sh`.

### Catégories
- **A01, A02, A07, A10** : non applicables (aucune ressource par utilisateur, aucun secret, aucune identité, aucune requête sortante). Le journal reste dans la copie temporaire, supprimée comme aujourd'hui.
- **A03 Injection** : noms et raisons recopiés comme du texte, jamais évalués, jamais utilisés comme motif, format d'impression ou option (CS-06) ; neutralisation des caractères de contrôle (CS-01, CS-02) ; préfixes fixes (`  - `, `ECHEC `) qui empêchent une ligne recopiée d'imiter un résumé (CS-05).
- **A04 Conception** : la condition d'écriture du bloc est le résumé retenu, pas le contenu du journal ; le bloc est toujours écrit après le journal brut, donc un faux bloc dans le journal n'est jamais pris pour le vrai (CS-07) ; bornes de taille (CS-03, CS-04).
- **A05 Configuration** : aucun réglage ajouté (bornes fixes, Q-02).
- **A06** : aucune dépendance ajoutée.
- **A08 Intégrité** : les lignes lues par les machines et les codes de sortie sont inchangés (RG-09, RG-13).
- **A09 Journalisation** : le bloc est un extrait borné ; il n'ajoute aucun contenu que le journal ne contenait pas.

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| Récapitulatif du journal | forme exacte de RG-06 | en-tête « illisible », rien d'autre recopié |
| Nom, raison | texte quelconque, neutralisé, 300 caractères par ligne au plus | aucun : tronqué avec `…` |
| Nombre d'échecs | entier du résumé, identique à celui de l'en-tête | en-tête « illisible » |

### Critères d'acceptation de sécurité
- **CS-01** Given une suite factice dont un nom et une raison contiennent `ESC[31m`, retour chariot, saut de ligne, tabulation, BEL et DEL, When on la lance, Then le récapitulatif a exactement une ligne par échec et aucune de ses lignes ne contient de caractère de contrôle (`LC_ALL=C grep '[[:cntrl:]]'`).
- **CS-02** Given un journal fabriqué dont les lignes de récapitulatif contiennent `ESC[31m`, retour chariot, BEL et DEL, When on lance `verify-clean.sh` puis `fin-issue.sh`, Then aucune ligne de leurs blocs ne contient de caractère de contrôle et le nombre de lignes du bloc est celui attendu.
- **CS-03** Given un échec dont le nom fait 10 000 caractères `é` et la raison 100 000 caractères, When on lance `verify-clean.sh` et `fin-issue.sh`, Then chaque ligne de leurs blocs fait au plus 300 caractères et finit par `…`, et la sortie est de l'UTF-8 valide (aucun caractère coupé).
- **CS-04** Given 10 000 échecs, When on lance `verify-clean.sh` et `fin-issue.sh`, Then chaque bloc fait 22 lignes (en-tête, 20 échecs, `… et 9980 autre(s) …`), les dernières lignes et les codes sont ceux de la version précédente, dans la borne de durée de CA-12.
- **CS-05** Given des noms d'échec égaux à `TESTS OK : 999 vérifications`, `[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0`, `Ran 3 tests in 0.1s`, `= 3 passed in 0.1s =`, `Tests: 3 passed, 3 total`, `# tests 3`, `# pass 3`, `Tests : TESTS OK : 1 vérifications`, `VERIFY OK`, `FIN-ISSUE OK 001-01 abc : 1 tests, 0 échec, 0 ignoré`, `Récapitulatif des échecs (1) :` et `--- Tests en échec de la suite de la factory (1) ---`, précédés ou non d'un saut de ligne, When on lance la suite factice, `verify-clean.sh` puis `fin-issue.sh`, Then la ligne `Tests : …` et les types de résumé sont ceux du même journal sans ces noms, aucune ligne `plusieurs types de résumé` n'apparaît, et les dernières lignes `VERIFY …` et `FIN-ISSUE …` et les codes sont inchangés.
- **CS-06** Given des noms et raisons contenant `$(touch marque)`, des backticks, `%s%n`, `\n` littéral et une barre oblique inverse finale, When on lance la suite factice, `verify-clean.sh` et `fin-issue.sh`, Then ces textes apparaissent littéralement dans le récapitulatif et les blocs, et le fichier `marque` n'existe pas.
- **CS-07** Given un build Maven en échec, puis une suite qui réussit, dont le journal se termine par `--- Tests en échec de la suite de la factory (1) ---` et `ECHEC faux : x`, puis une suite en échec dont le journal contient plus haut ce faux bloc, When on lance `verify-clean.sh` et `fin-issue.sh`, Then dans les deux premiers cas aucun bloc n'est écrit par `verify-clean.sh` ni recopié par `fin-issue.sh`, et dans le troisième seul le vrai bloc est recopié avant la dernière ligne.

## 7. Décisions reflétées
| Décision | Contenu | Reflété dans |
|---|---|---|
| Backlog F-17 (2026-11-25) | Récapitulatif de la suite avant son résumé ; recopie bornée et neutralisée par `verify-clean.sh` et `fin-issue.sh` ; dernière ligne `FIN-ISSUE` et codes de sortie inchangés ; résumé toujours reconnu | RG-01 à RG-13, CA-01 à CA-14, CS-01 à CS-07 |
| Brief du 2026-11-25 | Autres outils traités ou exclus explicitement ; coût, non-régression et cas hostiles couverts | RG-14, RG-15, CA-08, CA-12, CS-01 à CS-07 |
| PRD 004 RG-21 | Règle de neutralisation reprise | Vocabulaire de la section 2 |

## 8. Questions
Ouvertes (rapport du spec-writer, 2026-11-25) : Q-01 à Q-04, lectures provisoires marquées `[À CLARIFIER]`.

## 9. Découpage en issues (indicatif)
Chaque critère est couvert par exactement une issue ; dépendances : 01, puis 02, puis 03 (même suite de tests, format du récapitulatif lu par 02, bloc lu par 03).

| Issue | Contenu | Critères |
|---|---|---|
| 012-01 | Récapitulatif de la suite, neutralisé, sortie inchangée sans échec | CA-01 à CA-03, CS-01 |
| 012-02 | Bloc de `verify-clean.sh` : lecture stricte, bornes, neutralisation, autres outils inchangés | CA-04 à CA-08, CS-02 à CS-06 |
| 012-03 | Recopie par `fin-issue.sh`, faux bloc ignoré, coût, documentation, version, non-régression | CA-09 à CA-14, CS-07 |

## QUESTIONS
- **Q-01** (F-17) Où `fin-issue.sh` recopie-t-il les échecs ? A : le bloc est répété juste avant la dernière ligne, en plus de la sortie de `verify-clean.sh` qu'il recopie déjà (lisible dans les dernières lignes) ; B : rien de plus, le bloc est déjà dans la sortie recopiée de `verify-clean.sh`, mais suivi de la sortie du contrôle des critères ; C : la dernière ligne nomme les tests (contraire à l'exigence). Recommandation : A.
- **Q-02** (F-17) Bornes : A : 20 échecs et 300 caractères par ligne dans les blocs, aucune borne dans la suite ; B : 10 et 200 ; C : 50 et 500 ; D : A plus une borne de 1 000 caractères par ligne dans la suite. Recommandation : A (22 lignes au plus lisibles d'un coup, la suite garde l'information complète).
- **Q-03** (F-17) Autres outils (Maven, Gradle, unittest, pytest, jest, node:test) : A : exclus, sortie inchangée (ils ont leur propre récapitulatif) ; B : extraire aussi les lignes `FAILED`/`ERROR` de pytest ; C : un bloc pour chaque outil, dans un besoin séparé. Recommandation : A, avec C noté au backlog si l'utilisateur le souhaite.
- **Q-04** (F-17, écart constaté) `fin-issue.sh` ne lit pas `TESTS EN ECHEC : x sur n` : sa dernière ligne dit « nombre de tests ignorés illisible … » au lieu de « x test(s) en échec », et avec `FIN_ISSUE_IGNORES_AUTORISES=inconnu` un build qui rend 0 malgré ce résumé donne `FIN-ISSUE OK`. A : hors de ce besoin (l'exigence fige la dernière ligne), nouveau besoin au backlog ; B : corriger ici (la dernière ligne change pour ce cas) ; C : laisser tel quel. Recommandation : A.
