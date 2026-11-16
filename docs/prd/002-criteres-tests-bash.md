# PRD 002 : le contrôle des critères sans test reconnaît les tests bash et un dossier de tests configurable

Besoin : F-05 (`backlog.md`). Décisions de cadrage reprises telles quelles : D-06 (forme d'un test bash), D-07 (`DOSSIER_TESTS` en configuration), D-08 (livré avant la clôture de 001-01, pas d'ADR). Ce PRD ne les rouvre pas.
Le « produit » est la factory elle-même (scripts bash, prompts et skills Markdown). Les noms de commande, de clé de configuration et de fichier visibles par les utilisateurs sont des contrats ; aucune structure de code n'est décrite.

## 1. Contexte et besoin

### Acteurs
- **Utilisateur** de la factory : lit les messages `OK` / `MANQUE` / `FIN-ISSUE ECHEC`.
- **Session orchestrateur** et **developer** : lancent `scripts/fin-issue.sh` avant de passer une issue à `Fait`.
- **Mainteneur de la factory** : ses propres tests sont en bash (`factory/scripts/tests/run.sh`).

### Existant (observé)
- `scripts/criteres-sans-test.sh <issue|--tous>` liste les critères `CA-xx` / `CS-xx` d'une issue qu'aucune **déclaration de test** ne nomme. Il ne lit que Java, Kotlin (`.java`, `.kt`), Python (`.py`), JS/TS (`.js .jsx .mjs .cjs .ts .tsx .mts .cts`). Rien d'autre ne compte : commentaire, docstring, message d'assertion, chaîne quelconque, autre type de fichier. Préférence assumée pour un faux MANQUE plutôt qu'un faux OK.
- L'identifiant est reconnu sous les formes `CA-10`, `ca10`, `ca_10`, `CA 10` (insensible à la casse, zéros de tête ignorés ; `CA-1` ne se confond pas avec `CA-10`).
- Le dossier de tests est la variable d'environnement `DOSSIER_TESTS` (vide = non définie), sinon le premier dossier existant parmi `src/test`, `tests`, `test`. Dossier absent : message « introuvable », code 64. Codes : 0 tout couvert, 1 manque, 64 usage ou dossier introuvable.
- Les clés de `.factory.conf` sont lues par `factory/scripts/lib-config.sh` (jamais sourcé ni évalué) avec la priorité, du plus faible au plus fort : valeur par défaut, `.factory.conf`, `.factory.local.conf` (non versionné), variable `FACTORY_<CLÉ>` ; une clé présente avec une valeur vide l'emporte sur les niveaux plus faibles. `scripts/config-factory.sh` affiche la configuration effective.
- `scripts/fin-issue.sh` refuse un `DOSSIER_TESTS` absolu ou sortant du dépôt (code 64), puis lance `criteres-sans-test.sh` sur une **extraction du commit** (`git archive HEAD`) ; seuls `criteres-sans-test.sh` et `lib-issues.sh` y sont copiés (pas `lib-config.sh`). Un code de sortie non nul du contrôle donne `FIN-ISSUE ECHEC : … critère sans test`.
- Les tests de la factory sont en bash : `factory/scripts/tests/run.sh` appelle `verifier "<description>" <code> "<motif>" <commande…>` et `verifier_exact`, et le futur `verdict_cas` (cas de `verdict-revue.sh`, issue 001-01). Aucun n'est un test reconnu : `fin-issue.sh` répond « critère sans test » alors que chaque critère a son cas (découvert à la livraison de 001-01).
- Version actuelle de la factory : 1.20.1 (`factory/VERSION`).

### Besoin
Que le contrôle reconnaisse les cas de test bash et un dossier de tests réglé en configuration, pour que `fin-issue.sh` puisse clôturer une issue de la factory elle-même, sans rien changer au comportement pour les langages et dossiers déjà reconnus.

## 2. Exigences fonctionnelles et règles de gestion

### 2.1 Test bash reconnu (D-06)
- **RG-01** Dans les fichiers `.sh` du dossier de tests (récursif), un **test bash** est une ligne qui, après son indentation éventuelle, commence par le nom d'une fonction de test listée en configuration, suivi d'au moins une espace ou tabulation, puis d'un premier argument entre guillemets (`"` ou `'`) dont le texte **commence par** l'identifiant du critère.
  Exemple reconnu : `verifier "ca10_première ligne vide" 1 "INCONNU" scripts/verdict-revue.sh f` (couvre `CA-10`). Exemple reconnu : `verdict_cas "cs01_contenu hostile" …`.
- **RG-02** Seul ce premier argument compte : le reste de la ligne (autres arguments, commentaire final) est ignoré, comme le message d'assertion pour les autres langages.
- **RG-03** Le texte du premier argument commence par l'identifiant : `"ca10_x"` couvre `CA-10` ; `"cas : ca10"` ou `"voir ca10"` ne le couvre pas (Q-03).
- **RG-04** Formes d'identifiant : celles des autres langages (`CA-10`, `ca10`, `ca_10`, `CA 10`, insensible à la casse, zéros de tête ignorés) ; `CA-1` ne se confond pas avec `CA-10` (Q-03).
- **RG-05** Ne comptent **pas** : une fonction non listée (`ok "ca10_x"`, `echo "ca10"`) ; une ligne de commentaire (`# verifier "ca10_x"`) ; un appel dont le premier argument n'est pas une chaîne entre guillemets (`verifier ca10_x`, `verifier "$nom"`) ; la ligne de définition de la fonction (`verifier() {`) ; un appel qui n'est pas en début de ligne (après `;`, `&&`, `$(`), faux MANQUE assumé (Q-04).
- **RG-06** Commentaires et chaînes de texte sont ignorés, y compris les **documents ici** : toutes les lignes entre l'ouverture `<<MOT`, `<<'MOT'`, `<<"MOT"`, `<<-MOT` et la ligne qui ne contient que `MOT` (précédée de tabulations pour `<<-`) sont ignorées, même si elles ressemblent à un appel reconnu. Les lignes qui suivent le délimiteur final sont de nouveau lues.
- **RG-07** Le corps de la fonction n'est pas lu (comme pour les autres langages) : un cas peut être faux ou vide. Limites assumées : faux OK pour un appel dans une chaîne multiligne entre guillemets (hors document ici) ou dans une fonction jamais appelée ; faux MANQUE pour un premier argument sur la ligne suivante (continuation `\`).
- **RG-08** Fins de ligne CRLF tolérées. Fichiers non `.sh` du dossier ignorés, `.bash` compris (Q-08). Plusieurs fichiers `.sh`, y compris en sous-dossiers : les couvertures s'additionnent. Aucun appel reconnu dans aucun fichier : tous les critères sont `MANQUE` (message et code 1 existants), jamais une erreur ni un faux OK.

### 2.2 Clés de configuration (D-06, D-07)
| Clé | Valeur | Défaut | Rôle |
|---|---|---|---|
| `DOSSIER_TESTS` | chemin relatif au dépôt | vide (= détection automatique) | dossier de tests |
| `TESTS_BASH_FONCTIONS` | noms séparés par des espaces | `verifier verdict_cas` | fonctions dont l'appel est un test bash (Q-02) |

- **RG-09** Les deux clés sont des clés connues de `lib-config.sh` : lues dans `.factory.conf`, `.factory.local.conf` et `FACTORY_<CLÉ>`, avec la priorité existante (variable, puis local, puis fichier versionné, puis défaut). Elles figurent dans `scripts/config-factory.sh` (affichage `CLÉ=valeur`) et dans le modèle `factory/templates/.factory.conf`.
- **RG-10** `DOSSIER_TESTS` garde en plus sa variable d'environnement actuelle, **sans préfixe** : elle est la plus prioritaire. Ordre complet, du plus fort au plus faible (Q-01) : `DOSSIER_TESTS`, `FACTORY_DOSSIER_TESTS`, `.factory.local.conf`, `.factory.conf`, détection automatique. Un usage existant (`DOSSIER_TESTS=… scripts/criteres-sans-test.sh`) ne change pas.
- **RG-10b (valeur vide)** Une valeur **vide** de la variable non préfixée `DOSSIER_TESTS` équivaut à « non définie » (comportement actuel) : elle laisse la main aux sources plus faibles. Une valeur vide dans `FACTORY_DOSSIER_TESTS` (définie), `.factory.local.conf` ou `.factory.conf` suit la règle de `lib-config.sh` : la clé présente l'emporte sur les sources plus faibles, et une valeur finale vide donne la détection automatique (RG-11), jamais une erreur.
- **RG-11** Sans valeur effective, le dossier est le premier existant parmi `src/test`, `tests`, `test` : comportement actuel inchangé. Avec une valeur, le dossier est celui-là ; s'il n'existe pas, message « Dossier de tests introuvable : … » et code 64 (pas de repli sur la détection).
- **RG-12** `TESTS_BASH_FONCTIONS` **remplace** la liste par défaut (elle ne s'y ajoute pas). Un nom valide est `[A-Za-z_][A-Za-z0-9_]*`, 64 caractères au plus (Q-07). Une liste vide, un nom hors de ce jeu (tiret, point, deux-points, `$`, backtick, guillemet, `;`, `*`, `/`, saut de ligne, nom commençant par un chiffre ou par `-`) ou plus de 20 noms donne un message `TESTS_BASH_FONCTIONS invalide` sur la sortie d'erreur et le code 64, avant toute lecture des tests.
- **RG-13** Les noms sont comparés comme du texte littéral : un nom n'est jamais interprété comme une expression régulière (`.` ne remplace pas un caractère).
- **RG-14** Ce dépôt règle `DOSSIER_TESTS=factory/scripts/tests` dans son `.factory.conf` et garde la liste par défaut.

### 2.3 Effet sur `scripts/fin-issue.sh`
- **RG-15** Pour une issue de la factory dont chaque critère a un cas `verifier`/`verdict_cas` dans `factory/scripts/tests`, `fin-issue.sh` ne répond plus « critère sans test » (le reste du contrôle est inchangé : arbre propre, build, tests ignorés).
- **RG-16** La configuration est lue **dans l'extraction du commit** (comme les critères) : `.factory.conf` versionné s'applique, les variables d'environnement s'appliquent, `.factory.local.conf` (non versionné) n'existe pas dans l'extraction et est donc ignoré (Q-05). Pour cela `fin-issue.sh` copie `lib-config.sh` dans l'extraction avec les deux scripts déjà copiés ; sans lui le contrôle ne pourrait pas lire `.factory.conf`.
- **RG-17** Avant tout build, `fin-issue.sh` refuse (code 64, message « DOSSIER_TESTS doit être un chemin relatif à l'intérieur du dépôt ») une valeur de `DOSSIER_TESTS` absolue, égale à `..` ou contenant un segment `..`, **quelle que soit sa source** : variable `DOSSIER_TESTS`, `FACTORY_DOSSIER_TESTS`, `.factory.local.conf` ou `.factory.conf`. Le refus s'applique aussi à une valeur de `.factory.local.conf`, même si l'extraction l'ignorerait ensuite.

### 2.4 Compatibilité
- **RG-18** Aucune régression : mêmes déclarations reconnues et mêmes résultats pour Java, Kotlin, Python, JS/TS ; mêmes messages et codes (0, 1, 64) ; les cas existants de `factory/scripts/tests/run.sh` sur `criteres-sans-test.sh`, `fin-issue.sh` et la configuration passent sans modification de leurs attentes.
- **RG-19** Un dossier de tests qui mêle bash et un autre langage couvre les critères par l'union des deux.

### 2.5 Propagation et version
- **RG-20** Documentation : en-tête de `criteres-sans-test.sh` (formes reconnues, clés), `factory/README.md`, `factory/templates/.factory.conf`, `AGENTS.md` (ligne `scripts/criteres-sans-test.sh`).
- **RG-21** Version : F-05 est livré en **1.21.0** (Q-06). `factory/VERSION` vaut `1.21.0` ; `CHANGELOG.md` a une entrée 1.21.0 qui décrit le changement et la migration « remplacer `factory/` » (sans action pour les projets qui ne changent rien : un `.factory.conf` existant sans les nouvelles clés se comporte comme avant ; pour reconnaître des tests bash, y ajouter `DOSSIER_TESTS` et, au besoin, `TESTS_BASH_FONCTIONS`) ; `factory/README.md` mentionne la nouveauté. La livraison de F-01 (PRD 001) passe en **1.22.0**.
- **RG-22** Hors périmètre : modifier le contenu fonctionnel des six issues de F-01 (seul le numéro de version 1.21.0, devenu 1.22.0, est reporté dans le PRD 001 et l'issue 001-06) ; changer le format des tests existants de `run.sh` ; reconnaître d'autres langages ; lire le corps des fonctions ou exécuter un test ; ajouter une clé pour le suffixe des fichiers (`.sh` seul).

## 3. Modèle de données (point de vue métier)
- **Test bash** : ligne `<fonction> "<identifiant>…" …` au début d'une ligne, hors commentaire et hors document ici.
- **Liste de fonctions** : 1 à 20 noms, jeu `[A-Za-z0-9_]`.
- **Dossier de tests** : chemin relatif au dépôt, ou détection automatique.

## 4. Contrats externes
- Commande inchangée : `scripts/criteres-sans-test.sh <issue|--tous>` ; sorties `OK` / `MANQUE` / `ERREUR` et codes 0, 1, 64 inchangés.
- Nouvelles clés : `DOSSIER_TESTS`, `TESTS_BASH_FONCTIONS` (voir 2.2) ; sortie de `config-factory.sh` : deux lignes `CLÉ=valeur` de plus.
- Message d'erreur de configuration : `TESTS_BASH_FONCTIONS invalide : …` (stderr, code 64).
- Version : `factory/VERSION` = `1.21.0`.

## 5. Critères d'acceptation
Identifiants au format `CA-xx` (convention de `scripts/couverture-prd.sh`) ; le nom d'un test est de la forme `ca01_…`.

- **CA-01** Given un dossier de tests contenant un fichier `.sh` avec la ligne `verifier "ca10_x" 0 "OK" cmd`, When on lance le contrôle sur une issue de critère `CA-10`, Then `OK`, code 0 ; de même `verdict_cas "cs01_x" …` couvre `CS-01`.
- **CA-02** Given la liste par défaut, When un fichier contient `ok "ca10_x"` ou `echo "ca10_x"` ou `verifier ca10_x` (sans guillemets) ou `verifier() {`, Then `CA-10` est `MANQUE`, code 1.
- **CA-03** Given `TESTS_BASH_FONCTIONS="cas"` et une ligne `cas "ca10_x"`, Then `CA-10` est couvert ; Given la même clé et une ligne `verifier "ca10_x"`, Then `MANQUE` (la liste remplace le défaut).
- **CA-04** Given la ligne `# verifier "ca10_x" …` (avec ou sans indentation), Then `CA-10` est `MANQUE`.
- **CA-05** Given `verifier "voir ca10_x"`, ou `verifier "autre" 0 "ca10_x"`, ou `ca10` seulement dans un commentaire final, ou un appel en milieu de ligne (`rm -rf d; verifier "ca10_x"`), Then `CA-10` est `MANQUE`.
- **CA-06** Given une ligne `verifier "ca10_x" …` à l'intérieur d'un document ici (`<<'EOF'`, `<<EOF`, `<<"EOF"`, `<<-EOF` avec délimiteur indenté par tabulation), Then `CA-10` est `MANQUE` ; Given le même appel après la ligne du délimiteur final, Then il est couvert.
- **CA-07** Given `verifier "CA-10 x"`, `"ca_10"`, `"CA 10"`, `"Ca010"`, Then `CA-10` est couvert ; Given seulement `"ca1_x"` ou `"ca100_x"`, Then `CA-10` est `MANQUE` (et `CA-1` n'est couvert que par `ca1…`).
- **CA-08** Given un dossier de tests sans aucun appel reconnu, When le contrôle est lancé, Then tous les critères sont `MANQUE`, code 1, sans erreur d'exécution.
- **CA-09** Given plusieurs `.sh` dont des sous-dossiers, Then les critères couverts sont l'union de tous ; Given des fichiers non `.sh` (`.md`, `.txt`, `.bash`) contenant des appels, Then ils sont ignorés.
- **CA-10** Given `DOSSIER_TESTS=factory/scripts/tests` dans `.factory.conf`, When on lance le contrôle, Then ce dossier est lu (pas `src/test`, `tests`, `test`).
- **CA-11** Given des valeurs non vides différentes (dossiers distincts, chacun couvrant un critère différent) dans les cinq sources, When on retire la source la plus forte l'une après l'autre, Then le dossier lu suit l'ordre : variable `DOSSIER_TESTS`, `FACTORY_DOSSIER_TESTS`, `.factory.local.conf`, `.factory.conf`, détection. Given une variable `DOSSIER_TESTS` vide, Then elle est ignorée et la source suivante s'applique. Given `FACTORY_DOSSIER_TESTS=` (vide, définie) ou `DOSSIER_TESTS=` vide dans un fichier de configuration, alors qu'une source plus faible a une valeur, Then la valeur vide l'emporte et la détection automatique s'applique (pas d'erreur, pas la valeur plus faible).
- **CA-12** Given aucune configuration de `DOSSIER_TESTS`, When `src/test`, `tests` ou `test` existe, Then le premier existant dans cet ordre est lu comme avant.
- **CA-13** Given `DOSSIER_TESTS` configuré vers un dossier absent, Then « Dossier de tests introuvable », code 64, sans repli sur la détection.
- **CA-14** Given `TESTS_BASH_FONCTIONS` vide, ou contenant un nom invalide (`a-b`, `a.b`, `1a`, `-a`, `a;b`, `$(x)`, `a*`, nom de 65 caractères), ou plus de 20 noms, Then `TESTS_BASH_FONCTIONS invalide` sur stderr, code 64, aucun fichier de tests lu.
- **CA-15** Given les clés lues dans `.factory.conf`, `.factory.local.conf` et `FACTORY_TESTS_BASH_FONCTIONS`, Then la priorité est la même que celle des autres clés (variable > local > versionné > défaut).
- **CA-16** Given `scripts/config-factory.sh`, Then il affiche `DOSSIER_TESTS=` (vide par défaut) et `TESTS_BASH_FONCTIONS=verifier verdict_cas`, et `factory/templates/.factory.conf` documente les deux clés.
- **CA-17** Given une fixture Java, Kotlin, Python et JS/TS identique à celle des cas existants, When on lance le contrôle après la livraison, Then les résultats, messages et codes sont identiques ; la suite `factory/scripts/tests/run.sh` passe sans changer les attentes des cas existants.
- **CA-18** Given un dossier mêlant un fichier Java (`ca10_x`) et un `.sh` (`verifier "cs01_y"`), Then `CA-10` et `CS-01` sont tous deux couverts.
- **CA-19** Given un dépôt dont `.factory.conf` (commité) règle `DOSSIER_TESTS` sur le dossier des tests bash, et une issue dont chaque critère a son cas, When on lance `scripts/fin-issue.sh <issue>` (build bouchonné vert), Then la ligne finale est `FIN-ISSUE OK …` et la raison « critère sans test » est absente ; Given un critère sans cas, Then `FIN-ISSUE ECHEC : … critère sans test`.
- **CA-20** Given un `DOSSIER_TESTS` absolu, `..`, `../x`, `a/../b` ou `x/..`, venant de la variable, de `FACTORY_DOSSIER_TESTS`, de `.factory.local.conf` ou de `.factory.conf`, When on lance `fin-issue.sh`, Then `FIN-ISSUE ECHEC : DOSSIER_TESTS doit être un chemin relatif …`, code 64, sans build lancé (une combinaison par source).
- **CA-21** Given ce dépôt, When on lit `.factory.conf`, Then il contient `DOSSIER_TESTS=factory/scripts/tests` ; When on lance `scripts/criteres-sans-test.sh` sur une issue de ce dépôt dont les critères ont un `verifier "caNN_…"` dans `run.sh`, Then `OK`.
- **CA-22** Given la documentation (en-tête du script, `factory/README.md`, `AGENTS.md`, modèle `.factory.conf`), When on les lit après livraison, Then ils décrivent la forme du test bash, les deux clés, leurs défauts et la priorité.
- **CA-23** Given `factory/scripts/tests/run.sh`, When on le lance, Then les cas de CA-01 à CA-20 et CA-25 y figurent, leur nom contient l'identifiant (`ca01_…`) et ils passent, avec les variables `FACTORY_DOSSIER_TESTS`, `FACTORY_TESTS_BASH_FONCTIONS` et `DOSSIER_TESTS` isolées de l'environnement appelant.
- **CA-24** Given le dépôt après livraison, When on lit `factory/VERSION`, `CHANGELOG.md` et `factory/README.md`, Then la version est `1.21.0`, le CHANGELOG a une entrée 1.21.0 qui décrit le changement et la migration « remplacer `factory/` » (sans action si la configuration reste inchangée ; ajout des deux clés pour reconnaître des tests bash), et le README mentionne la reconnaissance des tests bash et les deux clés.
- **CA-25** Given `fin-issue.sh` lancé dans un dépôt dont `.factory.conf` commité règle `DOSSIER_TESTS` et dont `.factory.local.conf` (non versionné) en règle un autre, When le contrôle des critères s'exécute, Then il lit la valeur de `.factory.conf` du commit (jamais celle du fichier local), grâce à `lib-config.sh` copié dans l'extraction, et une variable `FACTORY_DOSSIER_TESTS` définie dans l'environnement s'applique dans l'extraction.

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : intégrité du contrôle « chaque critère a un test » (un faux OK lève un garde-fou de fin d'issue) ; système de fichiers de l'utilisateur.
- **Acteurs** : un dépôt ou une PR hostile (`.factory.conf`, fichiers de tests) ; un agent qui écrit des fichiers de tests contenant du texte piégé.
- **Points d'entrée** : valeur de `DOSSIER_TESTS`, valeur de `TESTS_BASH_FONCTIONS` (fichiers, variables), contenu des fichiers `.sh` de tests.
- Valeurs de configuration et contenu des fichiers de tests sont des **données non fiables** : lues comme du texte, jamais sourcées, évaluées ni exécutées ; les fichiers `.sh` de tests ne sont jamais exécutés par le contrôle.

### Catégories
- **A01 Contrôle d'accès / traversée** : `DOSSIER_TESTS` ne doit pas sortir du dépôt dans `fin-issue.sh`, quelle que soit la source (RG-17, CA-20) ; lecture seule. Pour une exécution directe du contrôle, le chemin vient de l'utilisateur lui-même (comportement actuel inchangé).
- **A02** : non applicable (aucun secret manipulé ; les valeurs affichées ne sont pas sensibles).
- **A03 Injection** : noms de fonctions limités à `[A-Za-z0-9_]` avant tout usage (RG-12) ; comparaison littérale (RG-13), jamais d'expression régulière construite depuis une valeur non validée ; aucun `eval`, `source`, `sh -c`, substitution de commande sur une valeur de configuration ou une ligne de test ; chemin cité, jamais pris pour une option (`--` ou chemin préfixé).
- **A04 Conception** : échec sûr : tout ce qui n'est pas reconnu explicitement ne couvre pas (faux MANQUE préféré) ; configuration invalide = 64, jamais un repli silencieux.
- **A05 Configuration** : défauts sûrs (liste `verifier verdict_cas`, détection actuelle) ; messages d'erreur courts, sans trace.
- **A06** : aucune dépendance ajoutée (outils POSIX déjà employés) ; licence sans objet.
- **A07, A10** : non applicables (ni identité ni requête sortante).
- **A08 Intégrité** : un fichier de tests peut être falsifié par quiconque écrit dans le dépôt (appel vide ou jamais exécuté) ; le contrôle ne le détecte pas (RG-07) ; la revue de PR et les tests verts de `fin-issue.sh` restent les filets. `lib-config.sh` copié dans l'extraction vient du dossier des scripts de la factory, pas du commit contrôlé.
- **A09 Journalisation** : configuration invalide et dossier introuvable signalés sur stderr, sans donnée sensible ; les caractères de contrôle des valeurs citées sont neutralisés.

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| `TESTS_BASH_FONCTIONS` | 1 à 20 noms de 1 à 64 caractères `[A-Za-z_][A-Za-z0-9_]*`, séparés par des espaces | 64, message, aucun test lu |
| `DOSSIER_TESTS` (via `fin-issue.sh`) | relatif, sans `..`, existant | 64 |
| `DOSSIER_TESTS` (direct) | dossier existant ; un chemin préfixé par `-` n'est jamais une option | 64 si introuvable |
| Contenu des `.sh` | texte ; seules les lignes de forme RG-01 comptent | sans objet (jamais d'erreur ; non reconnu = non couvert) |

### Critères d'acceptation de sécurité
- **CS-01** Given un fichier de tests contenant `$(touch marque)`, des backticks, `; touch marque`, ou `verifier "ca10_x" $(touch marque)`, et un `.factory.conf` dont des valeurs contiennent les mêmes motifs, When on lance le contrôle ou `fin-issue.sh`, Then aucune commande du contenu n'est exécutée (le fichier `marque` n'existe pas).
- **CS-02** Given `TESTS_BASH_FONCTIONS` valant `verifier;touch marque`, `$(touch marque)`, `` `touch marque` ``, `.*`, `a|b`, `a b;c`, `-x`, une valeur avec saut de ligne ou une valeur vide, Then code 64, message `TESTS_BASH_FONCTIONS invalide`, `marque` absent, et le motif `.*` ne couvre jamais un critère.
- **CS-03** Given `DOSSIER_TESTS` valant `-n`, `--help`, `a b` ou un chemin à espaces, When on lance le contrôle, Then la valeur est lue comme un chemin (introuvable : 64), jamais comme une option, et rien n'est exécuté.
- **CS-04** Given `.factory.conf` contenant des lignes `DOSSIER_TESTS=$(touch marque)` et `AUTRE=…`, When le contrôle lit la configuration, Then le fichier n'est jamais sourcé ni évalué, les clés inconnues sont ignorées et `marque` n'existe pas.
- **CS-05** Given n'importe quelle entrée, When le contrôle s'exécute, Then aucun fichier du dépôt n'est créé ni modifié par le contrôle (hors comportement actuel de `fin-issue.sh` pour son extraction temporaire, supprimée à la sortie), et les fichiers `.sh` lus ne sont jamais exécutés.
- **CS-06** Given une valeur de configuration invalide contenant des caractères de contrôle (retour chariot, séquence d'échappement), When le message d'erreur est écrit, Then ces caractères sont neutralisés (une seule ligne, aucun code d'échappement brut).

## 7. Décisions de l'utilisateur (2026-11-16)
- **Q-01** Priorité de `DOSSIER_TESTS` : `DOSSIER_TESTS` > `FACTORY_DOSSIER_TESTS` > `.factory.local.conf` > `.factory.conf` > détection. Reflété : RG-10, RG-10b, CA-11.
- **Q-02** `TESTS_BASH_FONCTIONS` : noms séparés par des espaces, qui remplacent le défaut. Reflété : 2.2, RG-12, CA-03, CA-14.
- **Q-03** Identifiant : mêmes tolérances de forme que les autres langages (`CA-10`, `ca10`, `ca_10`, `CA 10`, insensible à la casse), ancré au début du premier argument. Reflété : RG-03, RG-04, CA-07.
- **Q-04** Un appel qui n'est pas en début de ligne n'est pas reconnu. Reflété : RG-05, CA-05.
- **Q-05** `.factory.local.conf` est ignoré dans l'extraction de `fin-issue.sh` ; la règle d'équipe est dans `.factory.conf`. Reflété : RG-16, CA-25.
- **Q-06** Version : F-05 prend 1.21.0, F-01 passe à 1.22.0. Reflété : RG-21, CA-24 ; PRD 001 (RG-19, CA-18) et issue 001-06 mis à jour.
- **Q-07** Bornes : 20 noms, 64 caractères par nom. Reflété : RG-12, CA-14.
- **Q-08** Seul `.sh` est lu. Reflété : RG-08, CA-09.
