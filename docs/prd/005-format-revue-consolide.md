# PRD 005 : un fichier de revue qui regroupe plusieurs itérations a une seule ligne de verdict, en tête

## En clair
*Lecture sans contexte : ce bloc résume le document ; les règles et critères qui suivent sont destinés aux tests.*

**Le problème.** Un fichier de revue (`docs/reviews/<issue>.md`) regroupe les rapports de toutes les itérations d'une issue. Or chaque rapport du relecteur commence par une ligne `VERDICT: …`, et la skill `deliver` les recopie « tels quels » : un fichier à deux itérations a donc deux lignes `VERDICT:`. Le script `verdict-revue.sh` refuse ce cas (verdict ambigu, `INCONNU`), et `scripts/statuts.sh` signale alors l'avis A03 (« n'est pas approuvé ») pour une revue pourtant approuvée. Constaté le 2026-11-18 sur 001-01, 003-05 et 004-01, corrigés à la main.

**Ce que ce besoin change**
1. **Une seule ligne `VERDICT:` par fichier, en tête.** Elle porte le verdict de la dernière itération et est mise à jour à chaque itération. Les sections d'itération écrivent « Verdict de l'itération : … » (sans le mot-clé `VERDICT:`).
2. **C'est la session qui l'écrit.** Elle lit le rapport du relecteur avec `verdict-revue.sh` (comme aujourd'hui), recopie dans le fichier la valeur rendue par le script (jamais le texte du rapport), et tient la ligne de tête. Le relecteur reste en lecture seule et n'écrit jamais dans le fichier de revue.
3. **Le doublon reste refusé.** Une ligne `VERDICT:` en double dans un rapport (par exemple citée dans un constat) donne toujours `INCONNU` et la relance du relecteur. Le script ne change pas.
4. **Un avis nomme le problème.** `scripts/statuts.sh` émet un nouvel avis, A16, pour un fichier de revue mal formé (plus d'une ligne `VERDICT:`, ou première ligne qui n'est pas la ligne de verdict), avec le chemin du fichier et la cause. **Cet avis amende le catalogue des messages du PRD 004 (RG-23) : à faire valider par l'utilisateur.**
5. **Deux retouches de textes de F-01**, dans les mêmes fichiers : le gabarit du rapport du relecteur donne un exemple à valeur unique (`VERDICT: APPROUVÉ`) au lieu de la barre verticale, et la skill précise que le premier rapport supprimé avant la relance est restitué « d'après la conversation ».

**Hors de ce besoin** : migrer les fichiers de revue d'avant F-01 (ils restent tels quels), modifier `verdict-revue.sh`, `fin-issue.sh`, `etat-issues.sh` ou le dashboard, la revue en parallèle (F-02), l'affichage du verdict dans le dashboard (F-03), corriger automatiquement un fichier mal formé.

**Comment lire la suite** : section 2, les règles (RG-xx) et le message de l'avis A16 ; section 5, les 28 critères (« Given… When… Then… » : une situation, une action, un résultat) ; section 7, les décisions déjà prises avec l'utilisateur ; section 8, les points à trancher ; section 9, le découpage en 3 issues.

Besoin : F-12 (`backlog.md`). Décisions de cadrage reprises telles quelles : D-29, et les quatre décisions du 2026-11-18 de la section 7 (à consigner au backlog par l'utilisateur). D-30 (texte neutre de l'avis A03) relève de F-01 : ce PRD n'y touche pas. Ce PRD ne rouvre aucune de ces décisions.
Le « produit » est la factory elle-même (scripts bash, Markdown). Les noms de commande, de message et de fichier visibles par les utilisateurs sont des contrats ; aucune structure de code n'est décrite.
Préalable : F-01 (PRD 001, ligne `VERDICT:`, `verdict-revue.sh`, relance sur `INCONNU`) et F-09 (PRD 004, `statuts.sh`, catalogue RG-23) sont livrés.

## 1. Contexte et besoin

### Acteurs
- **Utilisateur** : lit les fichiers de revue et le résultat de `statuts.sh` / du dashboard ; valide les amendements de contrat.
- **Session orchestrateur** : exécute `/deliver`, écrit et tient `docs/reviews/<id-issue>.md`.
- **Relecteur** (`code-reviewer`) : produit un rapport, en lecture seule.
- **Mainteneur de la factory** : ses tests sont en bash (`factory/scripts/tests/run.sh`).

### Existant (observé)
- Le rapport du relecteur commence par `VERDICT: APPROUVÉ` ou `VERDICT: CHANGEMENTS DEMANDÉS` (PRD 001, RG-01). Le gabarit de `factory/prompts/report-format.md` écrit cette première ligne `VERDICT: APPROUVÉ|CHANGEMENTS DEMANDÉS` (barre verticale).
- `/deliver` (étape 3) écrit le rapport dans un fichier temporaire hors dépôt, lit son verdict avec `scripts/verdict-revue.sh`, puis l'ajoute « tel quel » au fichier de revue dans une section « Itération n » ; l'étape 4 demande de numéroter les itérations. Sur `INCONNU`, une seule relance (hors `MAX_ITERATIONS_REVUE`) ; au second `INCONNU`, la session remonte « les deux rapports » alors que le fichier du premier est supprimé avant la relance.
- `verdict-revue.sh` compte dans **tout le fichier** (jusqu'à 1 Mio) les lignes qui commencent, espaces de bord permis et casse indifférente, par `verdict` suivi d'espaces ou tabulations éventuels puis `:` ; plus d'une ligne, ou une première ligne qui n'est pas celle-là, donne `INCONNU`. Une ligne « Verdict de l'itération : … » ou une puce « - **Verdict** : … » n'est pas comptée (le mot n'est pas suivi des deux-points).
- `statuts.sh` (PRD 004) lit un fichier de revue désigné par le champ `revue:` d'une issue (chemin `docs/reviews/<nom>.md`, fichier régulier, non lien, 1 Mio au plus) ; pour une issue `Fait` il émet A03 si la revue n'est pas approuvée (verdict de la première ligne selon `verdict-revue.sh`, ou, pour un fichier sans ligne de verdict, dernière ligne `APPROUVÉ`). Il ne lit un fichier de revue que par sa première et sa dernière ligne.
- Forme réelle d'un fichier consolidé correct (001-06, 004-03) : ligne 1 `VERDICT: <valeur>`, ligne vide, titre `# Revue <id>`, puis `## Itération n (<date>)` dont la première ligne de corps est `Verdict de l'itération : <valeur>. …`.

### Besoin
Que le format d'un fichier de revue consolidé soit défini une fois (une ligne de verdict de tête, tenue par la session), que les textes de la factory le disent sans ambiguïté, et qu'un fichier mal formé soit signalé par une cause précise plutôt que par un A03 trompeur.

## 2. Exigences fonctionnelles et règles de gestion

Vocabulaire : **fichier consolidé** = `docs/reviews/<id-issue>.md` écrit selon ce PRD ; **ligne de verdict** = une ligne qui commence, espaces ou tabulations de bord permis, casse indifférente, par `verdict`, espaces ou tabulations éventuels, `:` (définition de `verdict-revue.sh`, reprise telle quelle) ; **ligne de tête** = la première ligne du fichier ; **valeur canonique** = `APPROUVÉ` ou `CHANGEMENTS DEMANDÉS`, telle que rendue par `verdict-revue.sh`.

### 2.1 Format du fichier consolidé (D-29, cadrage 1 et 2)
- **RG-01 (une seule ligne de tête)** La **première ligne** du fichier est `VERDICT: <valeur canonique>`, avant le titre et le tableau « Suivi des constats ». Aucune autre ligne du fichier n'est une ligne de verdict (y compris dans un bloc de code ou une citation en retrait). Sa valeur est le verdict de la **dernière itération** écrite.
- **RG-02 (section d'itération)** Chaque itération est une section `## Itération <n> (<date>)` dont la première ligne de corps est `Verdict de l'itération : <valeur canonique>`. Cette ligne **remplace** la ligne `VERDICT:` du rapport du relecteur : le reste du rapport est recopié tel quel. La ligne « Verdict de l'itération » ne contient pas le mot-clé `VERDICT:` en début de ligne.
- **RG-03 (la session tient la ligne de tête)** Après chaque rapport lu par `verdict-revue.sh` dont la sortie est une valeur canonique, la session écrit la section de l'itération et met la ligne de tête à cette valeur (elle crée le fichier à la première itération). La valeur écrite est **la sortie du script**, jamais le texte du rapport (un rapport dont la première ligne est `verdict:  approuvé ` donne `VERDICT: APPROUVÉ`). Sur `INCONNU`, rien n'est écrit dans le fichier de revue (relance et arrêt selon RG-07 et RG-08 du PRD 001).
- **RG-04 (relecteur en lecture seule)** Le relecteur n'écrit jamais dans le fichier de revue et ne reçoit aucune consigne d'y écrire ou d'y modifier la ligne de tête. Son rapport garde la forme de `report-format.md` (première ligne `VERDICT:`).
- **RG-05 (numérotation)** `n` est le rang de la revue : 1, 2, 3… dans l'ordre, sans trou ni réutilisation. La relance sur `INCONNU` ne crée pas d'itération : le rapport de la relance prend le rang de celui qu'il remplace. La colonne « Itération » du tableau « Suivi des constats » désigne ces numéros.
- **RG-06 (carte « pour l'humain »)** La section `## Pour l'humain` (PRD 001, RG-09 à RG-12) reste à la fin de la section de la dernière itération, écrite par la session, et ne contient aucune ligne de verdict.

### 2.2 Lecture du verdict (D-29, cadrage 1)
- **RG-07 (`verdict-revue.sh` inchangé)** Le script ne change ni de comportement ni de tests : un fichier consolidé conforme donne la valeur de la ligne de tête ; un doublon de ligne de verdict, y compris cité dans un rapport, reste `INCONNU` (code 1), ce qui déclenche la relance de PRD 001 RG-07. Les fichiers de revue d'avant F-01 ne sont pas migrés.

### 2.3 Avis A16 de `scripts/statuts.sh` (cadrage 4)
- **RG-08 (définition)** Un fichier de revue est **mal formé** s'il contient au moins une ligne de verdict et que : (a) il en contient **plus d'une**, ou (b) sa première ligne n'est **pas** une ligne de verdict. Un fichier sans aucune ligne de verdict (revue d'avant F-01) n'est jamais mal formé. Un fichier dont la seule ligne de verdict est la première n'est pas mal formé, quelle que soit sa valeur (une valeur invalide relève de A03). Le décompte est celui de `verdict-revue.sh` (même définition de la ligne de verdict).
- **RG-09 (périmètre)** Le contrôle porte sur le fichier désigné par le champ `revue:` (chemin selon RG-11 du PRD 004) d'une issue dont le statut local est `Fait` ou `En revue`, quand ce fichier est lisible. Une issue `À faire`, `En cours` ou `Abandonnée` n'est pas concernée. Un fichier désigné par plusieurs issues donne un avis par issue. Un avis au plus par issue : si (a) et (b) sont vraies, la cause est (a).
- **RG-10 (indépendance de A03)** A16 s'ajoute à A03 sans le remplacer ni le modifier : un fichier à deux lignes de verdict dont la première est valide donne A16 **et** A03 (le script rend `INCONNU`). Le texte et la condition d'A03 ne changent pas dans ce PRD.
- **RG-11 (lecture)** Pour le décompte, le contrôle lit le fichier **en entier**, mais seulement un fichier déjà admis par le PRD 004 (RG-11 : régulier, non lien symbolique, 1 Mio au plus, chemin `docs/reviews/<nom>.md`) ; un fichier refusé donne A02 et jamais A16. Aucun appel Git supplémentaire, aucune écriture, aucun contenu du fichier recopié dans un message.
- **Message (contrat)** Ajout d'une ligne au catalogue :

| Code | Gravité | Objet | Texte |
|---|---|---|---|
| A16 | avis | `issue <id>` | `fichier de revue mal formé <chemin> : <cause>` ; causes : `plus d'une ligne VERDICT:`, `la première ligne n'est pas la ligne VERDICT:` |

  `<chemin>` et `<id>` sont des valeurs neutralisées (RG-21 du PRD 004) ; la cause est un texte fixe. Exemple : `AVIS A16 issue 005-01 : fichier de revue mal formé docs/reviews/005-01.md : plus d'une ligne VERDICT:`. Le classement est celui de RG-20 (avis après les erreurs, par objet, puis par code : A16 après A15) ; le dashboard l'affiche comme tout avis, sans changement de `dashboard.sh`.

### 2.4 Retouches de textes de F-01 (cadrage 3)
- **RG-12** (a) Le gabarit du rapport du relecteur dans `factory/prompts/report-format.md` donne en première ligne un exemple à **valeur unique**, `VERDICT: APPROUVÉ`, et dit juste après, hors du bloc, que l'autre valeur est `VERDICT: CHANGEMENTS DEMANDÉS` ; la barre verticale disparaît de cette ligne. (b) L'étape 3 de la skill `deliver` précise, pour le second `INCONNU`, que le premier rapport (dont le fichier temporaire est supprimé avant la relance) est restitué **d'après la conversation**.

### 2.5 Documentation, version (cadrage 3)
- **RG-13 (documentation)** À jour avec le format : skill `deliver` (étape 3 : lecture du verdict, écriture de la section et de la ligne de tête par la session, numérotation ; étape 4 : renvoi à RG-05 pour la numérotation), `factory/templates/docs/reviews/README.md` et `docs/reviews/README.md` de ce dépôt (format du fichier, rôle de la ligne de tête, ligne « Verdict de l'itération », qui l'écrit), `factory/prompts/report-format.md` (dernier paragraphe : la session écrit la ligne de tête et remplace la ligne `VERDICT:` du rapport par « Verdict de l'itération »), `factory/README.md` (format consolidé, avis A16 avec son texte). `factory/prompts/code-reviewer.md` et le brief du relecteur n'ont pas à changer (le rapport garde sa forme) ; ils ne disent jamais d'écrire dans le fichier de revue.
- **RG-14 (version)** La version suivante libre à la livraison, fixée dans la dernière issue (1.25.0 attendue après 1.24.0 de F-09 ; F-14, prévue ensuite, prendra la suivante) ; `factory/CHANGELOG.md` a une entrée qui décrit le format, A16, les retouches et la migration « remplacer `factory/` » ; `factory/UPGRADE.md` aussi. Aucune migration de données : les fichiers existants ne sont pas touchés ; un fichier consolidé encore à plusieurs lignes de verdict (livraison en cours) est corrigé à la main (une seule ligne de tête), sinon A16 et A03 le signalent ; un projet qui a son propre `docs/reviews/README.md` y reprend le texte du modèle. Pas d'ADR.
- **RG-15 (hors périmètre)** Voir « Hors de ce besoin » ; en particulier aucun commit de ce besoin ne modifie `verdict-revue.sh`, `fin-issue.sh`, `etat-issues.sh`, `dashboard.sh`, leurs tests propres, ni un fichier de revue existant.

## 3. Modèle de données (point de vue métier)
- **Fichier de revue consolidé** : ligne de tête `VERDICT: <valeur>` ; titre ; tableau « Suivi des constats » ; n sections d'itération (`## Itération <n> (<date>)`, `Verdict de l'itération : <valeur>`, rapport) ; éventuellement `## Pour l'humain` à la fin de la dernière.
- **Fichier mal formé** : au moins une ligne de verdict et (plus d'une, ou première ligne autre). Cause : (a) ou (b).
- **Constat A16** : avis, objet = issue, chemin du fichier, cause.

## 4. Contrats externes
- `scripts/verdict-revue.sh` : inchangé (usage, sortie, codes 0, 1, 64).
- `scripts/statuts.sh` : sortie et codes de RG-20 du PRD 004 inchangés ; nouvel avis A16 (RG-08 à RG-11) ; un avis seul laisse le code à 0 (ou 1 si une erreur existe par ailleurs).
- Format du fichier consolidé : RG-01 à RG-06.
- Textes visibles (contrats) : `Verdict de l'itération : <valeur>`, `fichier de revue mal formé <chemin> : <cause>`, le gabarit `VERDICT: APPROUVÉ`.

## 5. Critères d'acceptation
Identifiants au format `CA-xx` (convention de `scripts/couverture-prd.sh`). Les tests créent des dépôts Git jetables (copie des scripts, `git init`, fichiers de revue et d'issue de fixtures) ; les critères de textes (skill, modèles, README) sont des vérifications textuelles ciblées (présence ou absence de chaînes exactes). Le nom d'un test est de la forme `ca01_…`.

### Format du fichier consolidé
- **CA-01** Given la skill `deliver`, When on lit l'étape 3, Then elle prescrit que la session, après avoir lu le verdict du rapport avec `scripts/verdict-revue.sh`, crée le fichier de revue (première itération) ou met à jour sa première ligne à `VERDICT: <valeur>` (la valeur rendue par le script) à chaque itération, et n'écrit rien dans le fichier quand le script rend `INCONNU`.
- **CA-02** Given la skill `deliver` et `factory/templates/docs/reviews/README.md`, When on les lit, Then ils disent que chaque section `## Itération <n> (<date>)` commence par `Verdict de l'itération : <valeur>`, que cette ligne remplace la ligne `VERDICT:` du rapport, et qu'aucune ligne autre que la première du fichier ne commence par `VERDICT:`.
- **CA-03** Given la skill `deliver`, `factory/prompts/code-reviewer.md` et `factory/prompts/briefs/reviewer.md`, When on les lit, Then la skill dit que la session seule écrit et met à jour le fichier de revue et que le relecteur reste en lecture seule, et ni le prompt ni le brief du relecteur ne contiennent de consigne d'écrire ou de modifier le fichier de revue ni sa ligne de tête.
- **CA-04** Given la skill `deliver` (étapes 3 et 4), When on lit la numérotation, Then `n` est le rang de la revue (1, 2, 3…), la relance sur `INCONNU` ne crée pas d'itération (le rapport de la relance prend le rang du premier), et l'étape 4 renvoie à cette règle.
- **CA-05** Given la skill `deliver` et le modèle de README, When on lit la carte « pour l'humain », Then elle reste à la fin de la section de la dernière itération, écrite par la session, et n'a aucune ligne de verdict.

### Lecture du verdict
- **CA-06** Given un fichier consolidé conforme à 1, 2 puis 3 itérations (ligne de tête, sections avec `Verdict de l'itération : …`, puis une section `## Verdict` et une puce `- **Verdict** : …` dans les rapports), dont la ligne de tête vaut `APPROUVÉ` alors que l'itération 1 dit `CHANGEMENTS DEMANDÉS`, When on lance `scripts/verdict-revue.sh`, Then la sortie est la valeur de la ligne de tête et le code 0 ; avec la ligne de tête `CHANGEMENTS DEMANDÉS`, Then cette valeur.
- **CA-07** Given le même fichier avec une seconde ligne `VERDICT: APPROUVÉ` dans une section d'itération (le constat du 2026-11-18), When on lance le script, Then `INCONNU`, code 1 ; et les tests existants de `verdict-revue.sh` (doublon, pas en première ligne) passent sans modification.
- **CA-08** Given un rapport du relecteur dont la première ligne est valide et dont un constat cite en début de ligne `VERDICT: APPROUVÉ`, When on lance le script sur ce rapport, Then `INCONNU` ; Given la skill `deliver`, Then elle prescrit toujours la relance unique sur `INCONNU` (hors `MAX_ITERATIONS_REVUE`) puis l'arrêt avec remontée si le second rapport est `INCONNU`.

### Avis A16
- **CA-09** Given un dépôt dont les issues `Fait` ont chacune un fichier consolidé conforme (1, 2, 3 itérations), de verdict `APPROUVÉ` et de verdict `CHANGEMENTS DEMANDÉS`, When on lance `scripts/statuts.sh`, Then aucun A16 ; Given les trois fichiers corrigés à la main (001-01, 003-05, 004-01 du dépôt, copiés), Then aucun A16.
- **CA-10** Given une issue `Fait` dont le fichier de revue a deux lignes de verdict (la première en tête, la seconde dans une section), When on lance `statuts.sh`, Then la sortie contient exactement `AVIS A16 issue <id> : fichier de revue mal formé docs/reviews/<id>.md : plus d'une ligne VERDICT:` ; avec trois lignes, Then un seul A16 ; le code reste 0 si aucune erreur.
- **CA-11** Given une issue `Fait` dont le fichier a pour première ligne un titre (ou une ligne vide) et une seule ligne de verdict plus bas, When on lance `statuts.sh`, Then `AVIS A16 issue <id> : fichier de revue mal formé docs/reviews/<id>.md : la première ligne n'est pas la ligne VERDICT:` ; Given un fichier dont la première ligne est la seule ligne de verdict, Then aucun A16.
- **CA-12** Given des fichiers de revue d'avant F-01 (copies de `docs/reviews/002-01.md`, `003-01.md`, sans ligne de verdict, dernière ligne `APPROUVÉ` ou non), When on lance `statuts.sh`, Then aucun A16 (seuls les avis existants, selon le PRD 004, subsistent), et ces fichiers ne sont pas modifiés.
- **CA-13** Given des issues `Fait`, `En revue`, `En cours`, `À faire` et `Abandonnée` dont le champ `revue:` désigne chacune un fichier mal formé, When on lance `statuts.sh`, Then un A16 pour chaque issue `Fait` et `En revue`, aucun pour les autres ; Given deux issues qui désignent le même fichier mal formé, Then un A16 par issue ; Given un fichier à la fois à deux lignes de verdict et à première ligne autre, Then un seul A16 de cause `plus d'une ligne VERDICT:`.
- **CA-14** Given une issue `Fait` dont le fichier a `VERDICT: APPROUVÉ` en tête puis une seconde ligne de verdict, When on lance `statuts.sh`, Then A16 **et** A03 (texte d'A03 inchangé par ce besoin) ; Given un fichier conforme de verdict `CHANGEMENTS DEMANDÉS`, Then A03 seul ; Given un fichier conforme et approuvé, Then ni l'un ni l'autre.
- **CA-15** Given un dépôt avec un A16 et d'autres constats, When on lance `statuts.sh`, Then la ligne A16 a la forme `AVIS A16 <objet> : <texte>`, se classe après les erreurs et, pour une même issue, après A15 ou A03 dans l'ordre des codes, et le récapitulatif compte l'avis ; When on génère le dashboard, Then la section « Contrôle des statuts » contient ce texte exact, échappé en HTML, et `dashboard.sh` est inchangé.
- **CA-16** Given un dépôt de fixtures avec fichiers mal formés et conformes, When on lance `statuts.sh` avec un `git` de comptage, Then le nombre d'appels Git est identique à celui du même dépôt sans fichier mal formé (aucun appel de plus) ; les fichiers de revue, `backlog.md` et les issues sont identiques octet pour octet avant et après ; Given un fichier de plus de 1 Mio, un lien symbolique ou un chemin hors de la forme `docs/reviews/<nom>.md` avec deux lignes de verdict, Then A02 et jamais A16.

### Retouches de textes de F-01
- **CA-17** Given `factory/prompts/report-format.md`, When on lit le gabarit du rapport du relecteur, Then sa première ligne est exactement `VERDICT: APPROUVÉ`, le texte qui suit nomme l'autre valeur `VERDICT: CHANGEMENTS DEMANDÉS`, et aucune ligne de gabarit commençant par `VERDICT:` ne contient `|` ; la règle de PRD 001 RG-01 (deux valeurs seules, première ligne) y est toujours dite.
- **CA-18** Given la skill `deliver`, When on lit le cas du second `INCONNU`, Then le premier rapport est dit restitué « d'après la conversation » (son fichier temporaire est supprimé avant la relance), avec le second rapport et le message du script.

### Documentation, version, tests
- **CA-19** Given la documentation (RG-13), When on la lit après livraison, Then `docs/reviews/README.md` et `factory/templates/docs/reviews/README.md` décrivent le format (ligne de tête unique, « Verdict de l'itération », écrit par la session), `factory/prompts/report-format.md` (dernier paragraphe) le dit, et `factory/README.md` décrit le format et l'avis A16 avec son texte exact.
- **CA-20** Given le dépôt après livraison, When on lit `factory/VERSION`, `factory/CHANGELOG.md`, `factory/UPGRADE.md` et `factory/README.md`, Then la version est la suivante libre (supérieure à toute version déjà livrée), le CHANGELOG et UPGRADE décrivent le format, A16, les retouches, la migration « remplacer `factory/` » et l'absence de migration de données, et le README mentionne la nouveauté.
- **CA-21** Given `factory/scripts/tests/run.sh`, When on le lance, Then les cas de CA-01 à CA-19 et CS-01 à CS-06 y figurent, leur nom contient l'identifiant (`ca01_…`), ils passent avec des dépôts Git jetables, `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM` et `HOME` isolés, sans réseau ni dépôt réel.
- **CA-22** Given le dépôt après livraison et la version précédente, When on compare, Then `scripts/verdict-revue.sh`, `scripts/fin-issue.sh`, `scripts/etat-issues.sh`, `scripts/dashboard.sh`, leurs tests propres et les fichiers de `docs/reviews/` existants n'ont aucune ligne modifiée par les commits de ce besoin, et la suite existante de `run.sh` passe, avec ses seuls cas de lecture de textes réécrits si une chaîne de texte change (liste justifiée dans l'issue).

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : intégrité de la décision de livraison (une ligne de verdict forgée ne doit ni faire passer un fichier pour approuvé, ni cacher un fichier mal formé) ; fiabilité de ce que l'utilisateur lit.
- **Acteurs** : un rapport de relecteur, un constat ou un fichier de revue hostile (texte cité contenant des lignes `VERDICT:`) ; un collaborateur qui écrit un `revue:` ou un `id:` hostile.
- **Points d'entrée** : le contenu d'un fichier de revue (lignes de verdict, taille, fins de ligne, octets), le champ `revue:`, l'`id:` d'une issue (inséré dans le message), le rapport lu par la session.
- Tout cela est une **donnée non fiable** : lue comme du texte, jamais exécutée, évaluée, interprétée comme motif ou option, ni recopiée dans un message.

### Catégories
- **A01 Contrôle d'accès / traversée** : le chemin du fichier suit RG-11 du PRD 004 (`docs/reviews/<nom>.md`, non lien, 1 Mio au plus) ; aucun fichier hors dépôt n'est lu ni son contenu reproduit (CS-05).
- **A02, A07, A10** : non applicables (aucun secret, aucune identité, aucune requête sortante).
- **A03 Injection** : même définition de la ligne de verdict que `verdict-revue.sh`, donc aucune divergence exploitable entre ce que le script lit et ce que l'avis compte (CS-01) ; valeurs insérées neutralisées et tronquées (CS-02) ; le contenu du fichier n'est jamais dans un message ; la session écrit la sortie du script, pas le texte du rapport (CS-06).
- **A04 Conception** : échec sûr : un fichier ambigu reste `INCONNU` (jamais deviné) ; la ligne de tête n'est jamais écrite sur `INCONNU` ; les fichiers d'avant F-01 ne sont pas jugés mal formés ; l'avis ne corrige rien.
- **A05 Configuration** : aucun réglage ajouté ; message sans contenu brut ni chemin hors dépôt.
- **A06** : aucune dépendance ajoutée.
- **A08 Intégrité** : un rapport ou un fichier de revue peut être falsifié par quiconque écrit dans le dépôt ; A16 aide à le voir, il ne l'empêche pas ; la revue humaine de la PR et `fin-issue.sh` restent les filets.
- **A09 Journalisation** : pas de journal ; l'avis ne contient pas de donnée sensible.

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| Chemin de revue | `docs/reviews/<[A-Za-z0-9._-]+>.md`, fichier régulier non lien, 1 Mio au plus | A02, aucun A16 |
| Ligne de verdict | définition de `verdict-revue.sh` (espaces et tabulations de bord, casse, CRLF) ; rien d'autre | non comptée |
| `id:` inséré dans le message | caractères de contrôle neutralisés, 120 caractères au plus | tronqué |
| Valeur de la ligne de tête écrite par la session | sortie de `verdict-revue.sh` (deux valeurs) | rien d'écrit |

### Critères d'acceptation de sécurité
- **CS-01** Given des fichiers de revue dont la deuxième ligne de verdict prend les formes `  verdict : APPROUVÉ`, `Verdict: x`, `VERDICT:` seul, `	VERDICT: APPROUVÉ` (tabulation), `VERDICT: APPROUVÉ` suivi de CRLF, et dans un bloc de code ou une liste indentée par des espaces, et des formes non comptées par le script (`> VERDICT: APPROUVÉ`, `- VERDICT: APPROUVÉ`, `Verdict de l'itération : …`, `VERDICT` sans deux-points, espace insécable avant le mot), When on lance `verdict-revue.sh` et `statuts.sh` sur chacun, Then pour chaque fichier A16 est émis exactement quand le script rend `INCONNU` pour cause de doublon, jamais autrement : les deux lectures ne divergent sur aucune forme.
- **CS-02** Given un `id:` contenant retour chariot, saut de ligne, échappement de terminal (`ESC[31m`), NUL, `<img src=x onerror=alert(1)>` ou plus de 120 caractères, et un fichier de revue contenant `$(touch${IFS}marque)`, des backticks, `; rm`, `ERREUR E01 backlog : …` en début de ligne et des séquences `ESC[31m`, When on lance `statuts.sh` et le dashboard, Then chaque constat tient sur une seule ligne sans caractère de contrôle, aucune ligne ne contrefait un constat, le contenu du fichier n'apparaît nulle part, le fichier `marque` n'existe pas, la valeur longue est tronquée avec `…`, et la page n'a aucune balise issue d'une valeur qui ne soit échappée.
- **CS-03** Given un fichier de revue de 1 Mio exactement (100 000 lignes de verdict), un autre de 1 Mio + 1 octet, une ligne unique de plusieurs Mio, When on lance `statuts.sh`, Then il termine sans échec de mémoire dans un temps borné (de l'ordre de la seconde, mesuré et consigné par le test) ; le premier donne A16 (cause `plus d'une ligne VERDICT:`), les deux autres A02.
- **CS-04** Given un fichier à fins de ligne CRLF, un fichier dont la ligne de tête est précédée d'espaces ou de tabulations, un fichier commençant par un BOM UTF-8, un fichier contenant des octets NUL, un fichier vide, When on lance `statuts.sh`, Then les deux premiers sont lus comme des lignes de verdict (comme par le script), les autres ne font émettre aucun A16 faux ni message d'erreur de shell, et le comportement d'A02/A03 existant est inchangé ; un fichier à BOM seul (une ligne de verdict masquée, que le script rend `INCONNU`) donne A03 et pas A16.
- **CS-05** Given un champ `revue:` valant `docs/reviews/../../etc/hostname`, `/etc/hostname`, `docs/reviews/x/../y.md`, et un lien symbolique `docs/reviews/<id>.md` vers un fichier hors dépôt contenant deux lignes de verdict, When on lance `statuts.sh`, Then aucun fichier hors dépôt n'est lu (le lien n'est pas suivi), A02 est émis, aucun A16, et le contenu visé n'apparaît nulle part.
- **CS-06** Given la skill `deliver`, When on la lit, Then elle traite le rapport comme une donnée non fiable : la valeur écrite en ligne de tête et en « Verdict de l'itération » est celle que rend `verdict-revue.sh` (valeur canonique), jamais une portion du texte du rapport ; elle n'écrit aucune ligne `VERDICT:` autre que la première du fichier, y compris dans une citation d'un constat ni dans la carte ; Given un rapport dont la première ligne est `verdict:   approuvé  ` (tolérée), Then la ligne de tête écrite est `VERDICT: APPROUVÉ`.

## 7. Décisions reflétées
| Décision | Contenu | Reflété dans |
|---|---|---|
| D-29 | Option A : une seule ligne `VERDICT:` en tête, « Verdict de l'itération : … » ensuite ; doublon cité refusé (`INCONNU`, relance) ; fichiers d'avant F-01 non migrés | RG-01, RG-02, RG-07, RG-08, CA-02, CA-06 à CA-08, CA-12 |
| Cadrage 1 (2026-11-18) | Reprise de D-29 telle quelle | idem |
| Cadrage 2 (2026-11-18) | La ligne de tête est mise à jour par la session, qui écrit le rapport dans une section « Itération n » ; le relecteur reste en lecture seule | RG-03, RG-04, CA-01, CA-03, CS-06 |
| Cadrage 3 (2026-11-18) | Les deux retouches de textes de F-01 restent dans F-12 (mêmes fichiers : une version, un CHANGELOG) | RG-12, RG-14, CA-17, CA-18, CA-20 |
| Cadrage 4 (2026-11-18) | Un avis de `statuts.sh` pour un fichier consolidé mal formé, qui nomme le fichier et la cause ; ajout au catalogue RG-23 du PRD 004, à valider | RG-08 à RG-11, A16, CA-09 à CA-16, CS-01 à CS-05 |
| D-30 | Texte neutre d'A03 : relève de F-01, non repris ici | RG-10, RG-15 |
| Q-01 à Q-04 (2026-11-18) | Q-01 : A16 contrôle les issues `Fait` et `En revue` ; Q-02 : A16 s'ajoute à A03 sans le modifier ; Q-03 : ajout d'A16 au catalogue RG-23 et RG-11 élargie (première et dernière ligne, et lecture entière, 1 Mio au plus, pour compter les lignes de verdict) validés, amendement du PRD 004 par l'utilisateur ; Q-04 : la ligne `## Verdict` du gabarit reste inchangée | RG-09, RG-10, RG-11, RG-12 |

## 8. Questions
Toutes tranchées par l'utilisateur le 2026-11-18 (réponses consignées en section 7).

## QUESTIONS : aucune

## 9. Découpage en issues (indicatif)
Chaque critère est couvert par exactement une issue ; dépendances : 01, puis 02 (le format est défini avant son contrôle), 03 en dernier. 005-02 est la plus grosse (13 critères, tests d'un script) et le justifie.

| Issue | Contenu | Critères |
|---|---|---|
| 005-01 | Format du fichier consolidé dans la skill `deliver`, le modèle de README et le gabarit ; lecture du verdict (script inchangé) ; deux retouches de F-01 ; session seule écrivante | CA-01 à CA-08, CA-17, CA-18, CS-06 |
| 005-02 | Avis A16 de `statuts.sh` : définition, périmètre, indépendance d'A03, lecture seule et coût, valeurs hostiles, bornes, CRLF, liens | CA-09 à CA-16, CS-01 à CS-05 |
| 005-03 | Documentation, version et CHANGELOG, tests regroupés, non-régression | CA-19 à CA-22 |
