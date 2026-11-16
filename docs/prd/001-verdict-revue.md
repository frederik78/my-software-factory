# PRD 001 : verdict de revue lisible par machine, carte « pour l'humain », liste d'escalade

Besoin : F-01 (`backlog.md`). Décisions de cadrage reprises telles quelles : D-02 (verdict), D-03 (carte), D-04 (escalade), D-05 (propagation, pas d'ADR). Ce PRD ne les rouvre pas.
Le « produit » est la factory elle-même (scripts bash, prompts et skills Markdown). Les noms de commande et de fichier visibles par les utilisateurs sont des contrats ; aucune structure de code n'est décrite.

## 1. Contexte et besoin

### Acteurs
- **Utilisateur** de la factory : seul à pousser et fusionner ; lit la conversation et le courriel.
- **Session orchestrateur** : lance les rôles, tient `docs/reviews/<id-issue>.md`, applique la règle d'arrêt de `/deliver`.
- **Agents** : `developer`, `code-reviewer`, `spec-writer`.

### Existant (observé)
- Le reviewer rend un rapport dont la section `## Verdict` contient « APPROUVÉ | CHANGEMENTS DEMANDÉS (+ une phrase) » (`factory/prompts/report-format.md`). Son prompt (`factory/prompts/code-reviewer.md`) se termine par « Conclus par APPROUVÉ ou CHANGEMENTS DEMANDÉS » et renvoie au format de `report-format.md`.
- `/deliver` (étapes 3 et 4) écrit le rapport tel quel dans `docs/reviews/<id-issue>.md` (une section datée « Itération n »), puis lit le verdict **à la main** pour décider de la suite. Après `MAX_ITERATIONS_REVUE` revues sans `APPROUVÉ`, il s'arrête ; avec au moins un BLOQUANT il écrit un corps de notification (constats, branche, chemin de la revue) et lance `scripts/notifier.sh --sujet … --corps-fichier …` (codes 0 envoyé, 3 non configuré, 4 échec, 64 usage).
- `fin-issue.sh` et le dashboard ne lisent pas le verdict. `AGENTS.md` (modèle et dépôt) ne liste aucun sujet d'escalade obligatoire : seule la règle « les écarts de contrat externe, de licence, de dépendance ou de PRD se décident avec l'utilisateur, pas seul » (section Orchestration) et l'interdiction de lire les fichiers de secrets. Les sous-agents posent leurs questions dans `## QUESTIONS` (`AGENTS.md`) ; le rapport du développeur a une section `## À trancher par l'utilisateur`.
- Version actuelle de la factory : 1.20.1 (`factory/VERSION`).

### Besoin
1. Un verdict de revue **lisible par machine** et un script qui le lit, pour que `/deliver` ne dépende plus d'une lecture libre du texte.
2. Une **carte « pour l'humain »** sur une issue bloquée en revue, pour que l'utilisateur sache en 30 secondes quoi décider.
3. Une **liste d'escalade** commune à tous les rôles : sujets sur lesquels un agent ne décide jamais seul.

## 2. Exigences fonctionnelles et règles de gestion

### 2.1 Ligne de verdict (D-02)
- **RG-01** La **première ligne** du rapport du reviewer est exactement `VERDICT: APPROUVÉ` ou `VERDICT: CHANGEMENTS DEMANDÉS` (mot-clé `VERDICT`, deux-points, une espace, valeur).
- **RG-02** La section `## Verdict` du rapport reprend la **même valeur** (suivie d'une phrase). La ligne `VERDICT:` fait foi pour la machine ; la section est pour le lecteur (décision Q-04).
- **RG-03** Les valeurs valides sont deux seulement. Toute autre valeur (`PASS`, `CHANGES`, vide, autre texte) est inconnue.
- **RG-04** Les anciennes revues de `docs/reviews/` ne sont **pas migrées** : une revue sans ligne `VERDICT:` donne `INCONNU`, ce qui est le comportement attendu.
- **RG-05** `fin-issue.sh` et le dashboard ne changent pas et ne lisent pas la ligne.

### 2.2 Script `scripts/verdict-revue.sh` (D-02)
Usage : `scripts/verdict-revue.sh <fichier-de-revue>` ; le chemin est un argument, jamais lu dans le contenu du fichier.
- **Entrée** : un fichier contenant le rapport d'**une** revue (une itération), dont la première ligne est lue (décision Q-01).
- **Sortie standard** : une seule ligne, `APPROUVÉ`, `CHANGEMENTS DEMANDÉS` ou `INCONNU`, rien d'autre.
- **Sortie d'erreur** : en cas d'`INCONNU` ou de fichier absent, une explication d'une ligne (voir CS-03).
- **Codes de sortie** : `0` valeur valide (APPROUVÉ ou CHANGEMENTS DEMANDÉS) ; `1` `INCONNU`, ou fichier absent/illisible ; `64` usage (aucun argument, plus d'un argument, option inconnue), avec le message d'usage sur la sortie d'erreur.
- Lecture seule : le script ne modifie aucun fichier et n'exécute jamais le contenu lu.
- Le script a ses tests dans `factory/scripts/tests/` (lancés par `factory/scripts/tests/run.sh`) ; il est listé dans `AGENTS.md` (commandes, modèle et dépôt) et décrit dans `factory/README.md`.

### 2.3 Cas limites de la lecture
| Cas | Résultat |
|---|---|
| Fichier absent ou illisible | `INCONNU` sur la sortie standard, code 1, message sur la sortie d'erreur (distinct du cas « ligne absente ») |
| Fichier vide | `INCONNU`, code 1 |
| Ligne `VERDICT:` absente (ancienne revue) | `INCONNU`, code 1 |
| Ligne `VERDICT:` présente mais **pas en première ligne** (précédée d'une ligne, même vide) | `INCONNU`, code 1 (Q-02) |
| Ligne `VERDICT:` en double (deux lignes commençant par `VERDICT:`) | `INCONNU`, code 1 : ambiguïté refusée (Q-02) |
| Casse (`verdict: approuvé`), espaces de bord ou autour des deux-points, fin de ligne CRLF | tolérés ; accents **exigés** (`APPROUVE` est inconnu) (Q-03) |
| Valeur inconnue (`VERDICT: PASS`, `VERDICT: APPROUVÉ SOUS RÉSERVE`) | `INCONNU`, code 1 (RG-03) : la valeur doit être égale à l'une des deux, pas seulement la contenir |
| Ligne `VERDICT:` valide mais `## Verdict` de valeur différente | la ligne fait foi ; aucune comparaison (Q-04) |

### 2.4 Intégration dans `/deliver` (D-02)
- **RG-06** Après chaque revue (étape 3), `/deliver` enregistre le rapport de l'itération dans un fichier à part (hors dépôt), appelle `scripts/verdict-revue.sh` sur ce fichier, puis ajoute le rapport à `docs/reviews/<id-issue>.md` ; il décide d'après la sortie du script, pas d'après sa propre lecture du texte (Q-01).
- **RG-07** Sur `INCONNU`, `/deliver` **relance une fois** le reviewer en lui demandant de corriger le format de la première ligne. Cette relance ne compte pas comme une itération de `MAX_ITERATIONS_REVUE` (confirmé par l'utilisateur). Si le second rapport est encore `INCONNU`, la session s'arrête et remonte le cas à l'utilisateur (l'issue reste `En revue`) ; elle ne devine pas le verdict.
- **RG-08** `APPROUVÉ` mène à la définition de fini (étape 5) ; `CHANGEMENTS DEMANDÉS` mène aux corrections (étape 4), selon les règles existantes. La définition de fini (« dernière revue `APPROUVÉ` ») s'entend de la sortie du script.

### 2.5 Carte « pour l'humain » (D-03)
- **RG-09** Elle est rédigée **par la session orchestrateur** (pas par le reviewer), **seulement** pour une issue bloquée en revue après `MAX_ITERATIONS_REVUE` itérations sans `APPROUVÉ` (règle d'arrêt de `/deliver`). Aucune carte pour une issue approuvée ni en cours de boucle.
- **RG-10** Trois rubriques, dans cet ordre, sous les titres exacts :
  1. **Décision à prendre** : la question à trancher, avec les options et la recommandation de la session ;
  2. **Fichiers à lire** : chemins relatifs au dépôt (revue, issue, fichiers en cause), au plus une dizaine, avec une demi-ligne de raison chacun ;
  3. **Vérification suggérée** : la ou les commandes à lancer et le résultat attendu.
- **RG-11** La carte figure à deux endroits, avec le même contenu : une section `## Pour l'humain` ajoutée à la fin de la section de la dernière itération dans `docs/reviews/<id-issue>.md` ; le **corps** du courriel envoyé par `scripts/notifier.sh --corps-fichier`, en tête, avant les constats bloquants restants, la branche et le chemin de la revue (corps existant conservé).
- **RG-12** Le courriel reste conditionné comme aujourd'hui : il part s'il reste au moins un BLOQUANT. S'il ne reste que des IMPORTANT, la carte est écrite dans le fichier de revue et présentée dans la conversation, sans courriel (Q-05). Les codes 3 et 4 de `notifier.sh` sont remontés comme aujourd'hui. `notifier.sh` lui-même ne change pas.

### 2.6 Liste d'escalade (D-04)
- **RG-13** `AGENTS.md` du modèle (`factory/templates/AGENTS.md`) **et** `AGENTS.md` de ce dépôt contiennent une section avec la liste suivante, valable pour **tous les rôles** (session, developer, code-reviewer, spec-writer) :
  1. secrets et identifiants ;
  2. authentification et autorisation ;
  3. dépendance et licence ;
  4. déploiement et CI ;
  5. contrat d'un service externe ;
  6. écart avec le PRD.
- **RG-14** Sur l'un de ces sujets, l'agent **s'arrête et ne décide pas seul** : il range le point dans `## QUESTIONS` (spec-writer) ou `## À trancher par l'utilisateur` (developer, reviewer) de son rapport ; la session le relaie à l'utilisateur. Le reviewer ne le classe pas « mineur ».
- **RG-15** La liste complète les règles existantes sans les contredire (interdiction de lire les secrets, règle « les écarts de contrat externe, de licence, de dépendance ou de PRD se décident avec l'utilisateur »).

### 2.7 Propagation (D-05)
- **RG-16** `factory/prompts/report-format.md` : rapport du reviewer, première ligne `VERDICT: …`, section `## Verdict` de même valeur ; mention de la section `## Pour l'humain` écrite par la session.
- **RG-17** `factory/prompts/code-reviewer.md` : consigne de commencer le rapport par la ligne `VERDICT:` (deux valeurs seules) ; sa dernière phrase (« Conclus par APPROUVÉ ou CHANGEMENTS DEMANDÉS ») est alignée.
- **RG-18** `factory/README.md` : description du script, de la ligne de verdict, de la carte et de la liste d'escalade ; version affichée mise à jour.
- **RG-19** `CHANGELOG.md` : entrée 1.22.0 ; `factory/VERSION` : `1.22.0`.
- **RG-20** Migration « remplacer `factory/` » : documentée (README/CHANGELOG) ; les projets ayant leur propre `AGENTS.md` y ajoutent la section d'escalade à la main ; leurs anciennes revues restent telles quelles. Pas d'ADR (D-05).
- **RG-21** `factory/skills/deliver` : étapes 3 et 4 mises à jour (RG-06 à RG-12) ; alias régénérés par `factory/sync.sh`, sans éditer `.claude/skills`.

## 3. Modèle de données (point de vue métier)
- **Ligne de verdict** : texte `VERDICT: <valeur>`, valeur dans {`APPROUVÉ`, `CHANGEMENTS DEMANDÉS`}. Résultat de lecture : {`APPROUVÉ`, `CHANGEMENTS DEMANDÉS`, `INCONNU`}.
- **Carte** : trois rubriques ordonnées (décision, fichiers, vérification), texte libre court, sans donnée sensible.

## 4. Contrats externes
- Script : `scripts/verdict-revue.sh <fichier>` (voir 2.2).
- Format du rapport du reviewer : voir 2.1, 2.7.
- Corps du courriel : carte, puis constats, branche, chemin (texte brut UTF-8, comme aujourd'hui).
- Section `## Pour l'humain` : titre exact, trois rubriques en gras `**Décision à prendre**`, `**Fichiers à lire**`, `**Vérification suggérée**`.

## 5. Critères d'acceptation
Les identifiants suivent la convention de `scripts/couverture-prd.sh` (`CA-xx`) ; le nom d'un test est de la forme `ca01_…`.

- **CA-01** Given un fichier dont la première ligne est `VERDICT: APPROUVÉ`, When on lance `scripts/verdict-revue.sh <fichier>`, Then la sortie standard est `APPROUVÉ` et le code est 0.
- **CA-02** Given un fichier dont la première ligne est `VERDICT: CHANGEMENTS DEMANDÉS`, When on lance le script, Then la sortie est `CHANGEMENTS DEMANDÉS` et le code est 0.
- **CA-03** Given un fichier sans ligne `VERDICT:` (ancienne revue), When on lance le script, Then la sortie est `INCONNU`, le code 1.
- **CA-04** Given un chemin de fichier qui n'existe pas, When on lance le script, Then la sortie est `INCONNU`, le code 1 et un message d'erreur sur la sortie d'erreur.
- **CA-05** Given aucun argument, plus d'un argument ou une option inconnue, When on lance le script, Then le code est 64 et l'usage est affiché sur la sortie d'erreur.
- **CA-06** Given une ligne `VERDICT:` en double, When on lance le script, Then `INCONNU`, code 1.
- **CA-07** Given une ligne `VERDICT:` qui n'est pas la première (ligne vide ou titre avant), When on lance le script, Then `INCONNU`, code 1.
- **CA-08** Given `verdict:   approuvé  ` (casse différente, espaces de bord) ou une fin de ligne CRLF, When on lance le script, Then `APPROUVÉ`, code 0 ; Given `VERDICT: APPROUVE` (sans accent), Then `INCONNU`.
- **CA-09** Given `VERDICT: PASS`, `VERDICT:` (vide) ou `VERDICT: APPROUVÉ SOUS RÉSERVE`, When on lance le script, Then `INCONNU`, code 1.
- **CA-10** Given une ligne de verdict valide suivie d'une section `## Verdict` de valeur différente, When on lance le script, Then la valeur de la première ligne est rendue.
- **CA-11** Given n'importe quelle entrée, When le script s'exécute, Then la sortie standard contient exactement une ligne parmi les trois valeurs et le fichier lu est inchangé.
- **CA-12** Given le prompt du reviewer et `report-format.md`, When on les lit, Then ils exigent la première ligne `VERDICT: APPROUVÉ|CHANGEMENTS DEMANDÉS` et la section `## Verdict` de même valeur.
- **CA-13** Given la skill `deliver`, When on la lit, Then elle appelle `scripts/verdict-revue.sh` sur le rapport de l'itération avant son ajout au fichier de revue, décide d'après sa sortie, et prescrit **une** relance du reviewer sur `INCONNU` (hors compte de `MAX_ITERATIONS_REVUE`) puis l'arrêt avec remontée à l'utilisateur si le second rapport est `INCONNU`.
- **CA-14** Given la skill `deliver`, When on lit la règle d'arrêt, Then la session rédige la carte « pour l'humain » (trois rubriques dans l'ordre) uniquement après `MAX_ITERATIONS_REVUE` revues sans `APPROUVÉ`, l'inscrit en section `## Pour l'humain` de `docs/reviews/<id-issue>.md`, et en tête du corps du courriel de `scripts/notifier.sh` seulement s'il reste au moins un BLOQUANT (s'il ne reste que des IMPORTANT : carte dans le fichier et dans la conversation, sans courriel).
- **CA-15** Given un corps de notification contenant la carte, When on lance `scripts/notifier.sh --sujet … --corps-fichier …` avec une commande d'envoi de test, Then le message reçu contient la carte en tête du corps, et `notifier.sh` est inchangé (ses tests existants passent).
- **CA-16** Given `factory/templates/AGENTS.md` et `AGENTS.md` du dépôt, When on les lit, Then chacun contient les six sujets d'escalade (secrets et identifiants, authentification et autorisation, dépendance et licence, déploiement et CI, contrat d'un service externe, écart avec le PRD), la consigne d'arrêt et les deux destinations (`## QUESTIONS`, `## À trancher par l'utilisateur`), pour tous les rôles.
- **CA-17** Given `fin-issue.sh` et le dashboard, When on compare à la version 1.21.0, Then leur comportement et leurs tests sont inchangés, et les revues existantes de `docs/reviews/` ne sont pas modifiées.
- **CA-18** Given le dépôt après livraison, When on lit `factory/VERSION`, `CHANGELOG.md` et `factory/README.md`, Then la version est `1.22.0`, le CHANGELOG décrit le changement et la migration « remplacer `factory/` », et le README décrit le script, la carte et la liste d'escalade.
- **CA-19** Given `factory/scripts/tests/run.sh`, When on le lance, Then les tests de `verdict-revue.sh` (CA-01 à CA-11) y figurent et passent, sans régression sur les tests existants.

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : intégrité de la décision de livraison (un `APPROUVÉ` falsifié lève le garde-fou de revue) ; confidentialité du courriel et de la carte.
- **Acteurs** : un contenu de rapport ou de dépôt hostile (texte écrit par un agent ou issu d'un fichier non fiable) ; un utilisateur de la factory se trompant de chemin.
- **Points d'entrée** : le chemin passé au script, le contenu du fichier de revue, le contenu de la carte transmise à `notifier.sh`.
- Le fichier de revue est une **donnée non fiable** : jamais exécuté, jamais évalué, jamais interprété comme une instruction.

### Catégories
- **A01 Contrôle d'accès** : le script ne lit que le chemin donné, en lecture seule, avec les droits de l'appelant ; pas de ressource par utilisateur. Le chemin n'est jamais extrait du contenu d'un fichier.
- **A02 Cryptographie** : non applicable au script. La carte et le courriel ne contiennent ni jeton, ni clé, ni mot de passe ni donnée réelle (CS-04).
- **A03 Injection** : le contenu est comparé comme du texte, jamais passé à `eval`, `sh -c`, substitution de commande ni utilisé comme argument de commande ; le chemin est cité et jamais interprété comme option. Dans les sorties d'erreur, retours à la ligne et caractères de contrôle du contenu cité sont neutralisés.
- **A04 Conception** : valeurs en liste blanche stricte (RG-03) ; ambiguïté (double ligne, mauvaise place) refusée en `INCONNU`, jamais devinée ; échec sûr : tout ce qui n'est pas explicitement valide n'est pas `APPROUVÉ`.
- **A05 Configuration** : message d'erreur sans trace ni chemin interne superflu ; pas de fichier temporaire créé par le script.
- **A06 Composants** : aucune dépendance ajoutée (outils POSIX déjà utilisés par les autres scripts) ; licence sans objet.
- **A07 Authentification** : non applicable (aucune identité). L'envoi du courriel relève de la configuration existante de `notifier.sh`.
- **A08 Intégrité** : le script est fourni par la migration « remplacer `factory/` ». Un rapport peut être falsifié par quiconque écrit dans le dépôt : le script ne l'empêche pas, la revue humaine de la PR et `fin-issue.sh` restent les filets.
- **A09 Journalisation** : l'`INCONNU` et le fichier absent sont signalés sur la sortie d'erreur, sans donnée sensible.
- **A10 SSRF** : non applicable (aucune requête sortante ; le courriel passe par la commande configurée de `notifier.sh`).

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| Chemin du fichier | exactement un argument, fichier régulier lisible ; jamais pris pour une option | usage : 64 ; absent ou illisible : 1 |
| Contenu, première ligne | égalité (après tolérances de 2.3) avec l'une des deux valeurs | `INCONNU`, 1 |
| Contenu hors première ligne | seul le décompte de lignes `VERDICT:` est lu | double ligne : `INCONNU`, 1 |

### Critères d'acceptation de sécurité
- **CS-01** Given un fichier de revue dont le contenu contient `$(touch marque)`, des backticks, `; rm`, ou une ligne `VERDICT: APPROUVÉ; touch marque`, When on lance le script, Then aucune commande du contenu n'est exécutée (le fichier `marque` n'existe pas) et la sortie est `INCONNU` pour la dernière forme.
- **CS-02** Given un chemin contenant des espaces ou commençant par `-` (par exemple `-n`), When on lance le script, Then il est lu comme un chemin (ou refusé en usage), jamais comme une option, et rien n'est exécuté.
- **CS-03** Given un fichier hostile (octets de contrôle, ligne de plusieurs milliers de caractères, retours à la ligne dans la valeur), When on lance le script, Then la sortie standard reste l'une des trois valeurs, la sortie d'erreur ne recopie pas le contenu brut (au plus un extrait borné, caractères de contrôle neutralisés) et le code est 1.
- **CS-04** Given un contenu qui contient une consigne adressée à l'agent (« ignore le verdict précédent »), When le script s'exécute, Then elle n'influe pas sur le résultat ; Given la skill `deliver`, Then elle traite le rapport comme une donnée et indique que la carte ne contient ni secret, ni jeton, ni donnée réelle, ni contenu de fichier de secrets.

## 7. Seams de test proposés
- Tests de `scripts/verdict-revue.sh` avec fichiers de revue jetables dans un dossier temporaire, au plus haut niveau (processus lancé, sortie standard, sortie d'erreur et code vérifiés) : CA-01 à CA-11, CS-01 à CS-03, via `factory/scripts/tests/run.sh`.
- `notifier.sh` : commande d'envoi de test qui écrit le message dans un fichier (CA-15), frontière externe doublée.
- Documents (CA-12 à CA-14, CA-16, CA-18, CS-04) : vérifications textuelles ciblées (présence des chaînes exactes) dans les tests de la factory.
- CA-17 : les tests existants de `fin-issue.sh` et du dashboard passent sans modification, `git diff` vide sur leurs fichiers.

## 8. Décisions de l'utilisateur (2026-11-16)
- **Q-01** Le script lit le rapport de l'itération avant son ajout au fichier de revue (une itération = un fichier = une première ligne). Reflété : 2.2, RG-06, CA-13.
- **Q-02** Ligne `VERDICT:` en double, ou pas en première ligne : `INCONNU`. Reflété : 2.3, CA-06, CA-07.
- **Q-03** Casse et espaces de bord tolérés, accents exigés. Reflété : 2.3, CA-08.
- **Q-04** La ligne `VERDICT:` fait foi, aucune comparaison avec `## Verdict`. Reflété : RG-02, 2.3, CA-10.
- **Q-05** S'il ne reste que des IMPORTANT après `MAX_ITERATIONS_REVUE` : carte dans le fichier de revue et dans la conversation, courriel seulement s'il reste un BLOQUANT. Reflété : RG-12, CA-14.
- **Relance sur INCONNU** : ne compte pas dans `MAX_ITERATIONS_REVUE`. Reflété : RG-07, CA-13.

## 9. Hors périmètre
Migration des anciennes revues ; changement de `fin-issue.sh` ou du dashboard (F-03 lira un champ `revue:` plus tard) ; revue parallèle (F-02) ; ADR.
