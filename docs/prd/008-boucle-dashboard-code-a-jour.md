# PRD 008 : la boucle du dashboard utilise toujours le code à jour de la factory

## En clair
*Lecture sans contexte : ce bloc résume le document ; les règles et critères qui suivent sont destinés aux tests.*

**Le problème.** `scripts/dashboard.sh --boucle` régénère la page du dashboard en continu. Bash lit un script au fur et à mesure et la boucle garde en mémoire le code lu au démarrage : après une mise à jour de la factory (ou la livraison d'une issue qui change le dashboard), la boucle déjà lancée continue d'exécuter l'ancienne version. Constaté le 2026-11-18 : la boucle lancée le 2026-11-17 à 20 h 36 exécutait encore le code d'avant F-08. Aujourd'hui l'utilisateur doit penser à l'arrêter et à la relancer.

**Ce que ce besoin change (D-45)**
1. **Chaque tour relit le code sur le disque.** À chaque tour, la boucle relance le script depuis le disque, dans un processus séparé, pour une seule génération : le script et ses bibliothèques sont donc relus à chaque fois.
2. **Une erreur n'arrête pas la boucle.** Si une génération échoue (par exemple pendant qu'une mise à jour remplace les fichiers), la page précédente reste en place, l'erreur est écrite sur la sortie d'erreur, et la boucle réessaie au tour suivant. Seul Ctrl-C l'arrête.
3. **Les options sont fixées au lancement.** `--sortie`, `--attente` et `--theme` (et `--boucle`) gardent leur valeur de départ, y compris le thème issu de la configuration (D-50) ; seul le code est rechargé. Pour les changer, on relance.
4. **La page reste écrite de façon atomique** : la page précédente n'est jamais tronquée, y compris sur erreur ou Ctrl-C.
5. **Le rappel du README** « relancez la boucle après une mise à jour » est remplacé par une phrase qui dit que la boucle recharge le code à chaque tour, sauf ses propres options.

**Hors de ce besoin** : recharger les options ou la configuration en cours de boucle (y compris le thème issu de la configuration, D-50), changer le contenu de la page, le mode une génération, le calcul des statuts, l'ajout d'un délai maximal de génération (bash 3.2 de macOS n'a pas de commande de délai), tout nouveau coût Git.

**Comment lire la suite** : section 2, les règles (RG-xx) ; section 5, 16 critères ; section 6, 5 critères de sécurité ; section 7, décisions reprises ; section 8, question tranchée ; section 9, le découpage en 3 issues.

Besoin : F-11 (`backlog.md`). Décisions de cadrage reprises telles quelles : D-45 et D-50. Principe voisin : D-26 (pas de duplication de code mort ; ici, pas d'ancien code qui survit). Ce PRD ne rouvre aucune de ces décisions.
Le « produit » est la factory elle-même (scripts bash, Markdown). Les noms de commande, d'option et de message visibles par les utilisateurs sont des contrats ; aucune structure de code n'est décrite.
Contraintes de plateforme : bash 3.2 de macOS (pas de commande de délai, pas d'options GNU) ; aucune dépendance ajoutée.

## 1. Contexte et besoin

### Acteurs
- **Utilisateur** : lance `scripts/dashboard.sh --boucle <s>` et laisse la page à jour ; met à jour la factory (remplacement de `factory/`) ou fusionne des issues pendant que la boucle tourne.
- **Mainteneur de la factory** : ses tests sont en bash (`factory/scripts/tests/run.sh`).

### Existant (observé)
- Sans `--boucle`, le script génère la page une fois, écrit le nom du fichier sur la sortie et rend 0 (ou 64 sur mauvais usage ou configuration invalide, 1 sur échec d'écriture).
- Avec `--boucle <s>`, il affiche « Régénération de <sortie> toutes les <s> s (Ctrl-C pour arrêter). », puis boucle : écriture atomique (fichier temporaire dans le dossier de la sortie, déplacé sur la page), attente de `<s>` secondes. Une génération en échec termine aujourd'hui tout le script (code 1). Ctrl-C, TERM et HUP terminent avec 130, 143 et 129 et suppriment le temporaire.
- Le code est relu de façon incrémentale par bash : le corps de la boucle et les fonctions déjà définies restent ceux du démarrage ; les bibliothèques déjà chargées aussi.
- Le README dit que `--boucle` « doit tourner pour que la page reste à jour » et demande de relancer après une mise à jour (rappel actuel).
- Tests existants de la boucle : arrêt par signal (alarme), arrêt après deux générations avec une commande d'attente doublée (empreintes identiques, cs06), un contrôle de statuts par génération (ca29 de 004-05).

### Besoin
Qu'une boucle laissée tourner pendant une mise à jour exécute, au tour suivant, le code à jour, sans intervention, et qu'une erreur passagère ne l'arrête pas.

## 2. Exigences fonctionnelles et règles de gestion

Vocabulaire : **tour** = une génération de la page suivie de l'attente de `<s>` secondes ; **génération** = l'exécution complète du script en mode une génération ; **options de lancement** = `--sortie`, `--attente`, `--boucle`, `--theme` tels que reçus au démarrage.

### 2.1 Rechargement (D-45)
- **RG-01 (une génération par tour, relue du disque)** À chaque tour, la génération est une exécution du script **telle qu'il est sur le disque à cet instant**, dans un processus séparé de celui de la boucle, pour une seule génération (équivalente à un lancement sans `--boucle` avec les mêmes options de lancement). Le script et ses bibliothèques sont relus à chaque tour.
- **RG-02 (le script lancé est celui de la factory)** Le script relancé est le fichier même qui a démarré la boucle (son emplacement au démarrage), jamais un script trouvé par le répertoire courant ou le `PATH` au moment du tour.
- **RG-03 (options fixées, D-45 et D-50)** Les options de lancement (valeurs et défauts résolus au démarrage) sont les mêmes à tous les tours : une modification du code ou de la configuration pendant la boucle ne change ni la sortie, ni le délai d'attente de la page, ni l'intervalle de la boucle, ni le thème. Le thème est la valeur **résolue au démarrage** (option `--theme`, sinon `DASHBOARD_THEME` de la configuration, sinon le défaut), transmise à chaque tour ; une modification de `DASHBOARD_THEME` en cours de boucle n'est pas prise en compte (D-50).
- **RG-04 (validation au lancement)** Les options sont validées au démarrage comme aujourd'hui (usage ou dossier de sortie inexistant : message et code 64, la boucle ne démarre pas). Ce n'est pas une « génération en erreur ».
- **RG-05 (message de démarrage)** Le message « Régénération de <sortie> toutes les <s> s (Ctrl-C pour arrêter). » est conservé tel quel.

### 2.2 Erreur et arrêt (D-45)
- **RG-06 (génération en erreur)** Si une génération se termine en erreur (code non nul, ou script ou bibliothèque absent ou illisible, par exemple en cours de remplacement), la boucle : (a) **garde la page précédente octet pour octet** (aucune page partielle, aucune suppression) ; (b) écrit l'erreur sur la **sortie d'erreur** (le message de la génération, puis une ligne de la boucle `Génération en erreur (code <n>) : nouvel essai dans <s> s.`) ; (c) **réessaie au tour suivant**, après l'attente. Sans page précédente (première génération en échec), aucune page n'est créée.
- **RG-07 (la boucle ne s'arrête que sur signal)** Seuls Ctrl-C (INT), TERM et HUP arrêtent la boucle, avec les codes 130, 143 et 129 comme aujourd'hui. Aucun nombre d'erreurs consécutives ne l'arrête.
- **RG-08 (pas de boucle serrée)** Après une génération, réussie ou non, la boucle attend `<s>` secondes avant la suivante : une erreur permanente produit au plus un message par tour.
- **RG-09 (signal pendant une génération)** Un signal pendant une génération termine la génération en cours et la boucle ; le processus de génération n'est pas laissé orphelin ; la page est soit la précédente soit la nouvelle, complète (RG-10) ; aucun fichier temporaire ne reste.
- **RG-10 (page atomique)** La page n'est jamais lue à moitié écrite ni tronquée : la génération écrit dans un temporaire du même dossier puis le déplace sur la page (comportement actuel, conservé), y compris sur erreur et signal.

### 2.3 Inchangé
- **RG-11 (mode une génération)** Sans `--boucle`, le comportement, la sortie standard, la page et les codes de sortie (0, 1, 64) sont inchangés.
- **RG-12 (coût)** Aucun nouvel appel Git, aucun nouveau fichier lu ou écrit hors la page et son temporaire : un tour coûte une génération (un contrôle de statuts, les mêmes appels Git qu'une génération seule). Le démarrage d'un processus par tour est accepté.

### 2.4 Documentation, version
- **RG-13 (documentation)** `factory/README.md` : la phrase actuelle sur la boucle est remplacée, dans les deux endroits où elle apparaît (table des scripts et paragraphe du dashboard), par une phrase qui dit que **la boucle recharge le code à chaque tour, sauf ses propres options** (`--sortie`, `--attente`, `--boucle`, `--theme`, à relancer pour les changer), et que le rappel « relancez après une mise à jour » est supprimé. L'en-tête de `scripts/dashboard.sh` et `AGENTS.md` (et son modèle) disent la même chose en une phrase s'ils parlent de la boucle.
- **RG-14 (version)** La version suivante libre à la livraison, fixée dans la dernière issue (supérieure à toute version déjà livrée) ; `factory/CHANGELOG.md` a une entrée (comportement, absence de migration de données, migration « remplacer `factory/` ») ; `factory/UPGRADE.md` aussi. Une boucle lancée avant cette version doit être relancée **une fois** pour profiter du rechargement. Pas d'ADR.

## 3. Modèle de données (point de vue métier)
- **Page** : un fichier HTML ; état : absente, précédente (complète), nouvelle (complète). Jamais partielle.
- **Boucle** : options de lancement fixes ; état : en attente, en génération, arrêtée (signal).
- **Tour** : génération réussie ou en erreur (code), puis attente.

## 4. Contrats externes
- `scripts/dashboard.sh` : usage inchangé ; sortie standard du démarrage inchangée ; **nouvelle ligne sur la sortie d'erreur** `Génération en erreur (code <n>) : nouvel essai dans <s> s.` (précédée du message de la génération) ; codes : mode une génération 0, 1, 64 ; boucle 64 au démarrage, 130, 143 ou 129 sur signal, jamais 1 pour une erreur de génération.
- Texte du README : la boucle recharge le code à chaque tour, sauf ses propres options.

## 5. Critères d'acceptation
Identifiants au format `CA-xx` (convention de `scripts/couverture-prd.sh`). Les tests créent des projets jetables (copie des scripts, `git init`, fixtures), lancent la boucle en processus d'arrière-plan avec une attente courte (1 s), modifient les fichiers du projet jetable pendant qu'elle tourne, et l'arrêtent par signal ; chaque attente est bornée (sondage avec délai maximal de l'ordre de 20 s, sans attendre 30 s), tout processus est tué et nettoyé en fin de cas. Le nom d'un test est de la forme `ca01_…`.

### Rechargement
- **CA-01** Given une boucle (`--boucle 1`) lancée dans un projet jetable, When le script est modifié sur le disque (une marque lisible dans la page) pendant qu'elle tourne, Then la page produite au plus deux tours plus tard contient la marque, sans relancer la boucle.
- **CA-02** Given la même boucle, When une bibliothèque `lib-*` chargée par le script est modifiée de la même façon, Then la page produite au tour suivant reflète la nouvelle bibliothèque.
- **CA-03** Given une boucle arrêtée après N générations, When on compte les exécutions du contrôle de statuts et les processus de génération (script de comptage dans le projet jetable), Then il y en a exactement une par tour, chacune dans un processus distinct de celui de la boucle.
- **CA-04** Given une boucle lancée avec `--sortie`, `--attente 7` et `--theme sombre`, puis une autre lancée sans `--theme` avec `DASHBOARD_THEME` valant `sombre` dans la configuration, When le code et la configuration (`DASHBOARD_THEME` mis à `clair`, `.factory.local.conf`) sont modifiés pendant la boucle, Then chaque page produite a le même fichier de sortie, le même délai de rafraîchissement (7) et le thème sombre (valeur résolue au démarrage, D-50).
- **CA-05** Given des options invalides (délai non numérique, dossier de sortie inexistant), When on lance `--boucle`, Then message d'usage ou d'erreur et code 64 immédiat, aucune boucle, aucune page.
- **CA-06** Given une boucle valide, When elle démarre, Then la sortie standard commence par `Régénération de <sortie> toutes les <s> s (Ctrl-C pour arrêter).` ; Given aucun `--boucle`, Then sortie, page et codes de sortie (0 ; 64 sur usage ; 1 sur échec d'écriture) sont identiques à ceux de la version précédente, les tests existants du mode une génération passant sans modification.

### Erreur et arrêt
- **CA-07** Given une boucle dont une page valide existe, When le script est remplacé par une version qui échoue (code 3), Then la page reste identique octet pour octet à la précédente, la sortie d'erreur contient le message de la génération puis `Génération en erreur (code 3) : nouvel essai dans 1 s.`, et la boucle tourne encore ; When le script est rétabli, Then le tour suivant produit une nouvelle page.
- **CA-08** Given une boucle dont la première génération échoue (script ou bibliothèque absent ou illisible, puis rétabli), When elle tourne plusieurs tours, Then aucune page ni temporaire n'existe pendant l'échec, la boucle ne s'arrête pas, et la page est produite dès que le code est rétabli.
- **CA-09** Given une boucle pendant l'attente, puis pendant une génération (script de génération lent par une commande doublée), When on envoie INT, TERM ou HUP, Then le code de sortie est 130, 143 ou 129, aucun processus de génération ne survit, aucun temporaire ne reste, et la page est complète (précédente ou nouvelle) ou absente si aucune n'existait.
- **CA-10** Given une boucle en cours de plusieurs tours, dont certains en erreur, When un lecteur relit la page en continu (au moins 50 lectures), Then chaque lecture est une page HTML complète (se termine par `</html>`), jamais vide ni tronquée.

### Coût
- **CA-11** Given une boucle arrêtée après N générations, When on compte les appels Git avec un `git` de comptage, Then leur nombre est N fois celui d'une génération seule (mesuré dans le même projet), et seules la page et son temporaire sont écrits : `backlog.md`, issues, références, index et worktrees identiques octet pour octet (garde cs06 existante inchangée).

### Documentation, version, tests
- **CA-12** Given `factory/README.md`, When on le lit, Then la phrase du rappel « relancez … après une mise à jour » n'existe plus, et une phrase dit que la boucle recharge le code à chaque tour, sauf ses propres options, aux deux endroits qui parlent de la boucle ; l'en-tête de `scripts/dashboard.sh` dit la même chose.
- **CA-13** Given le dépôt après livraison, When on lit `factory/VERSION`, `factory/CHANGELOG.md` et `factory/UPGRADE.md`, Then la version est la suivante libre, le CHANGELOG et UPGRADE décrivent le comportement, la migration « remplacer `factory/` » et la relance unique d'une boucle ancienne ; et les compteurs ou listes du README qui citent la version ou le nombre de vérifications sont à jour.
- **CA-14** Given `factory/scripts/tests/run.sh`, When on le lance, Then les cas de CA-01 à CA-11 et CS-01 à CS-05 y figurent, leur nom contient l'identifiant, ils passent avec des projets jetables, `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM` et `HOME` isolés, sans réseau, et leur durée totale est bornée (boucle à 1 s, sondage borné, aucun cas n'attend 30 s).
- **CA-15** Given le dépôt avant et après, When on exécute la suite complète, Then elle passe, et seuls changent les cas de lecture de textes qui citaient l'ancienne phrase du README (liste justifiée dans l'issue).
- **CA-16** Given la boucle livrée, When on la compare à la version précédente, Then le contenu de la page, les statuts, `statuts.sh`, `etat-issues.sh` et les autres scripts n'ont aucune ligne modifiée, hors ceux que RG-13 désigne.

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : la page (intégrité et lisibilité), la machine de l'utilisateur (aucune exécution de contenu non voulu), la lisibilité de la sortie d'erreur.
- **Acteurs** : un collaborateur ou un dépôt qui fournit un nom de fichier, un argument ou un fichier de configuration ou d'issue hostile ; un script placé dans le répertoire courant ou le `PATH`.
- **Points d'entrée** : les arguments (`--sortie`, `--attente`, `--boucle`, `--theme`), le chemin du script relancé, les fichiers lus par la génération (backlog, issues, configuration), la sortie d'erreur de la génération.
- Fichiers et arguments sont des **données non fiables** : lus comme du texte, jamais évalués ni interprétés comme commande ou option.

### Catégories
- **A01 Contrôle d'accès / traversée** : le fichier de sortie est celui des options de lancement, dossier existant exigé ; la boucle n'écrit rien d'autre que la page et son temporaire (CA-11).
- **A02, A07, A10** : non applicables (aucun secret, aucune identité, aucune requête sortante).
- **A03 Injection** : les options sont transmises à chaque génération comme des arguments distincts, sans passer par une évaluation de texte ni un interpréteur de commandes (CS-01) ; le message d'erreur de la boucle est un texte fixe et un code numérique ; la sortie d'erreur d'une génération n'est pas réinterprétée (CS-03).
- **A04 Conception** : échec sûr : une génération en erreur ne détruit ni ne tronque la page (CA-07, CA-10) ; pas de boucle serrée (CS-05).
- **A05 Configuration** : aucun réglage ajouté ; la génération relancée n'hérite que de l'environnement du lanceur.
- **A06** : aucune dépendance ajoutée.
- **A08 Intégrité** : le code relancé est le fichier du dépôt qui a démarré la boucle, pas un autre trouvé par le `PATH` ou le répertoire courant (CS-02) ; l'intégrité de ce fichier relève du dépôt (revue de PR).
- **A09 Journalisation** : l'erreur va sur la sortie d'erreur, sans contenu de fichier brut ajouté par la boucle ; pas de journal persistant.

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| `--attente`, `--boucle` | entier selon la règle actuelle du script | usage, code 64 au démarrage |
| `--theme` | `clair`, `sombre` ou `auto` | code 64 au démarrage |
| `--sortie` | dossier existant ; tout nom autorisé comme donnée (espaces, tiret initial, `$`, guillemets, saut de ligne) | code 64 si le dossier n'existe pas |
| Chemin du script relancé | emplacement fixé au démarrage | jamais recherché dans le `PATH` ni le répertoire courant |

### Critères d'acceptation de sécurité
- **CS-01** Given `--sortie` valant un nom avec espaces, un tiret initial (`-x.html` précédé de `./`), `$(touch${IFS}marque).html`, des backticks, `; touch marque`, des guillemets, un saut de ligne, et `--theme`, `--attente` aux valeurs usuelles, When la boucle tourne deux tours, Then chaque page est écrite sous ce nom exact (une seule page, aucun autre fichier), le fichier `marque` n'existe pas, et les options passent identiques au deuxième tour.
- **CS-02** Given un script nommé `dashboard.sh` (et un `scripts/dashboard.sh` factice) dans le répertoire courant ou en tête du `PATH` qui écrit un fichier `marque`, When la boucle est lancée depuis un autre répertoire puis relancée plusieurs tours, Then seul le script de démarrage est exécuté, `marque` n'existe pas.
- **CS-03** Given une génération en erreur dont le message contient des caractères de contrôle (`ESC[31m`), des sauts de ligne et `$(touch marque)`, When la boucle la rapporte, Then la ligne de la boucle est le texte fixe avec le code numérique, rien n'est évalué (`marque` n'existe pas), et le message de la génération apparaît tel qu'émis, sans être réinjecté dans la page.
- **CS-04** Given une boucle interrompue de toutes les façons testées (INT, TERM, HUP, pendant l'attente et pendant la génération, génération en échec), When on liste le dossier de sortie, Then aucun temporaire résiduel (`<sortie>.*`) n'existe, la page garde les droits du mode une génération (selon `umask`), et un lien symbolique placé à la place de la page n'est pas suivi pour écrire hors du dossier.
- **CS-05** Given une génération qui échoue immédiatement en permanence, When la boucle tourne 5 tours (attente 1 s, durée bornée), Then le nombre de lancements et de messages d'erreur est au plus 6 (un par tour), sans accumulation de processus, ni fichier ni sortie de taille croissante hors ces messages.

## 7. Décisions reflétées
| Décision | Contenu | Reflété dans |
|---|---|---|
| D-45 | Une génération par tour relancée depuis le disque en processus séparé ; erreur : page gardée, message sur la sortie d'erreur, nouvel essai ; options fixées au lancement ; README remplacé | RG-01 à RG-14, CA-01 à CA-16, CS-01 à CS-05 |
| D-50 | Q-01 (2026-11-19), option A : le thème issu de la configuration est la valeur résolue au démarrage, fixée comme les options ; une modification de `DASHBOARD_THEME` en cours de boucle n'est pas prise en compte | RG-03, CA-04 |
| Cadrage (2026-11-19) | Page atomique, jamais tronquée, y compris sur erreur ou Ctrl-C ; aucun nouveau coût Git ; code de sortie du mode une génération inchangé ; tests à durées bornées | RG-10, RG-11, RG-12, CA-06, CA-10, CA-11, CA-14 |

## 8. Questions
Tranchée par l'utilisateur le 2026-11-19 (Q-01, réponse consignée en section 7, D-50).

## 9. Découpage en issues (indicatif)
Chaque critère est couvert par exactement une issue ; dépendances : 01, puis 02 (le rechargement existe avant la gestion d'erreur), 03 en dernier.

| Issue | Contenu | Critères |
|---|---|---|
| 008-01 | Une génération par tour relancée du disque, options fixées, validation au lancement, mode une génération inchangé, arguments et script relancé non interprétés | CA-01 à CA-06, CS-01, CS-02 |
| 008-02 | Erreur de génération sans arrêt, signaux, page atomique, pas de boucle serrée, sortie d'erreur et temporaires | CA-07 à CA-10, CS-03 à CS-05 |
| 008-03 | Coût (Git), documentation, version, CHANGELOG et UPGRADE, tests regroupés à durée bornée, non-régression | CA-11 à CA-16 |

## QUESTIONS : aucune
