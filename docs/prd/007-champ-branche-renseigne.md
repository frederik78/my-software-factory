# PRD 007 : le champ `branche:` d'une issue est rempli dès sa création, et son oubli est signalé

## En clair
*Lecture sans contexte : ce bloc résume le document ; les règles et critères qui suivent sont destinés aux tests.*

**Le problème.** Chaque issue (`docs/issues/<id>-<slug>.md`) a un champ `branche:` dans son en-tête. Le modèle d'issue le laisse vide, donc les issues créées par le découpage d'un PRD l'ont vide : le dashboard doit alors deviner la branche par convention de nommage (F-08, PRD 003). Cela marche, mais la déduction échoue s'il y a deux branches candidates (« branche ambiguë »), et rien ne dit à l'utilisateur qu'un champ a été oublié. Constaté le 2026-11-19 : trois issues (005-01, 005-02, 005-03) ont le champ vide.

**Ce que ce besoin change**
1. **Le champ est rempli à la création.** Le modèle d'issue, son jumeau livré aux projets et le README des issues disent de renseigner `branche:` avec la branche prévue, `feat/<id>-<slug>` (le nom du fichier sans `.md`, préfixé par `feat/`). La branche n'a pas à exister encore.
2. **Un avis nomme l'oubli.** `scripts/statuts.sh` émet un nouvel avis, A17, pour une issue démarrée (statut `En cours` ou `En revue`) dont le champ est vide. Jamais une erreur : le code de sortie ne change pas.
3. **Les issues existantes sont complétées** d'après l'historique, avec des noms de branche vérifiés (D-43), preuve à l'appui.
4. **La skill `/to-tickets` n'est pas modifiée** (bibliothèque externe, réservée à l'utilisateur) : la consigne passe par le modèle et le README, le filet est l'avis.

**Hors de ce besoin** : vérifier que la branche déclarée existe ou que son nom est bien formé (le champ rempli l'emporte, PRD 003 RG-01), corriger le champ automatiquement, modifier `/to-tickets`, `dashboard.sh`, `etat-issues.sh`, `fin-issue.sh` ou la skill `deliver`, rendre l'oubli bloquant.

**Comment lire la suite** : section 2, les règles (RG-xx) et le message de l'avis A17 ; section 5, les critères (« Given… When… Then… » : une situation, une action, un résultat) ; section 7, les décisions déjà prises ; section 8, le point à trancher ; section 9, le découpage en 3 issues.

Besoin : F-06 (`backlog.md`). Décisions de cadrage reprises telles quelles : D-09 (le champ est rempli dès la création), D-42 (périmètre réduit : modèle, README, avis ; `/to-tickets` intact), D-43 (reprise des issues existantes). Ce PRD ne les rouvre pas. **L'avis A17 amende le catalogue des messages du PRD 004 (RG-23) : à faire valider par l'utilisateur.**
Le « produit » est la factory elle-même (scripts bash, Markdown). Les noms de commande, de message et de fichier visibles par les utilisateurs sont des contrats ; aucune structure de code n'est décrite.
Préalable : F-08 (PRD 003 : branche retenue, déduction par convention) et F-09 (PRD 004 : `statuts.sh`, catalogue RG-23, table des statuts) sont livrés. A16 est réservé au PRD 005 : le code libre suivant est **A17**.

## 1. Contexte et besoin

### Acteurs
- **Utilisateur** : approuve le découpage des issues, lit `statuts.sh` et le dashboard, valide les amendements de catalogue.
- **Session orchestrateur / agent qui découpe** : crée les fichiers d'issue (avec `/to-tickets`, qu'on ne modifie pas), exécute `/deliver`.
- **Mainteneur de la factory** : ses tests sont en bash (`factory/scripts/tests/run.sh`).

### Existant (observé)
- Le modèle `docs/issues/_template.md` et son jumeau `factory/templates/docs/issues/_template.md` ont la ligne `branche:` vide ; le README des issues (de ce dépôt et du modèle) cite `branche` (`feat/<prd>-<nn>-<slug>`) sans dire quand le remplir.
- Parmi les 33 fichiers d'issue de `docs/issues/` relevés le 2026-11-19 (hors modèle), 3 (005-01, 005-02, 005-03) ont `branche:` vide ; toutes les autres sont remplies.
- La skill `deliver` écrit déjà `branche:` dans l'issue au démarrage (sur la branche de l'issue) ; le fichier de `develop` garde donc le champ vide jusqu'à la fusion si l'issue avait été créée vide.
- Le dashboard et `etat-issues.sh` déduisent la branche d'un champ vide (`<type>/<id>-…`), la marquent « (déduite) », ou signalent « branche ambiguë » (PRD 003 RG-01 à RG-09). `statuts.sh` émet A08 quand aucune branche n'est retenue (PRD 004 RG-13) : un champ vide avec une branche déduite ne donne aucun signal.
- Le statut d'une issue vient de la table `factory/scripts/statuts.table` (`scripts/statuts.sh --table`) ; les règles « démarrée » et « en travail » s'y lisent par l'ordre (PRD 004 CA-38).

### Besoin
Que le rattachement d'une issue à sa branche ne repose plus sur la déduction par défaut : le champ est rempli dès la création, et un champ resté vide sur une issue démarrée est signalé, sans jamais bloquer.

## 2. Exigences fonctionnelles et règles de gestion

Vocabulaire : **champ vide** = voir RG-07 ; **issue démarrée et non terminée** = statut effectif (PRD 003) dont le rang dans la table est celui de `En cours` ou après lui, et avant `Fait` (aujourd'hui `En cours` et `En revue`) ; **branche prévue** = RG-02.

### 2.1 Remplir le champ à la création (D-09, D-42)
- **RG-01 (modèles)** Dans `docs/issues/_template.md` et `factory/templates/docs/issues/_template.md`, la ligne du champ est `branche: feat/<prd>-<nn>-<slug>` (jamais vide). Rien d'autre ne change dans ces deux fichiers, qui restent identiques entre eux.
- **RG-02 (branche prévue)** La branche prévue d'une issue est `<type>/<id>-<slug>` où `<id>-<slug>` est le nom du fichier d'issue sans `.md`. `<type>` est `feat` par défaut ; un autre préfixe du modèle de branches de `AGENTS.md` (`fix`, `docs`, `refactor`, `test`, `build`) si le travail est de ce type. C'est le nom que `/deliver` donne à la branche de l'issue. La valeur est **prévue** : la branche n'a pas à exister à la création.
- **RG-03 (README des issues)** Le README des issues (ce dépôt et le modèle) dit : (a) `branche` est renseigné **à la création** de l'issue, avec la branche prévue (RG-02) ; (b) s'il reste vide, le dashboard déduit la branche par convention et `statuts.sh` signale l'oubli (A17) dès que l'issue est démarrée ; (c) le champ rempli l'emporte sur la déduction.
- **RG-04 (`/to-tickets` intact)** La skill `to-tickets` n'est pas modifiée (D-42). La consigne de remplissage est portée par le modèle et le README ; le découpage proposé à l'utilisateur n'est pas contraint, l'avis A17 est le filet.

### 2.2 Avis A17 de `scripts/statuts.sh` (D-42)
- **RG-05 (condition)** Une issue **démarrée et non terminée** dont le champ `branche:` est **vide** donne l'avis A17. Le statut est le statut **effectif** (une issue `À faire` dans `develop` dont le fichier est `En cours` sur sa branche retenue est concernée) ; le champ lu est celui du **fichier local** de l'issue, là où le dashboard le lit.
- **RG-06 (hors condition)** Aucun A17 pour une issue `À faire` ou `Abandonnée` (elle n'est pas démarrée), ni pour une issue dont le champ est rempli, quelle que soit sa valeur. Une issue `Fait` : aucun A17 (D-44). Une issue en erreur E10, E11 ou E14 n'émet aucun autre constat (PRD 004, après RG-23) donc aucun A17.
- **RG-07 (champ vide)** Le champ est vide s'il est absent de l'en-tête ou si sa valeur, une fois retirés les espaces, tabulations, retour chariot de bord et les guillemets de bord (PRD 004 RG-06), est vide. Seul l'en-tête YAML (entre les deux lignes `---`) compte : une ligne `branche: …` dans le corps (Notes) ne remplit rien. A17 ne juge pas la valeur : `null`, `[]`, un nom de branche absent, un nom invalide comptent comme « renseigné » (le champ rempli l'emporte, PRD 003 RG-01).
- **RG-08 (indépendance d'A08 et du dashboard)** A17 s'ajoute aux avis existants sans les modifier : une issue `En cours`, champ vide et aucune branche trouvée donne A08 **et** A17 ; champ vide et branche déduite donne A17 seul ; champ rempli désignant une branche absente donne A08 seul (PRD 004 RG-13). Le dashboard et `etat-issues.sh` ne changent pas (déduction, « (déduite) », « ambiguë » inchangés).
- **RG-09 (lecture seule, coût)** Le contrôle lit seulement le champ déjà lu dans l'en-tête : aucun appel Git de plus (PRD 004 RG-25), aucune écriture (RG-24), aucun fichier supplémentaire lu. La valeur du champ n'est jamais recopiée dans un message.
- **RG-10 (aucune liste en dur)** Le seuil « démarrée » et « non terminée » se lit dans la table des statuts (rang de `En cours`, rang de `Fait`), jamais dans une liste de noms écrite à part : ajouter un statut dans la table suffit pour qu'il soit traité selon son rang (garde-fou CA-38 et CA-39 du PRD 004 respecté).
- **Message (contrat)** Ajout d'une ligne au catalogue (RG-23 du PRD 004) :

| Code | Gravité | Objet | Texte |
|---|---|---|---|
| A17 | avis | `issue <id>` | `<statut> sans champ branche renseigné` |

  `<statut>` est le statut effectif (valeur de la table), `<id>` une valeur neutralisée (RG-21 du PRD 004). Exemple : `AVIS A17 issue 009-02 : En cours sans champ branche renseigné`. Classement de RG-20 (avis après les erreurs, par objet, puis par code : A17 après A16 et après A08). Le dashboard l'affiche comme tout avis, sans changement de `dashboard.sh`. Un avis seul laisse le code de sortie à 0.

### 2.3 Reprise des issues existantes (D-43)
- **RG-11 (reprise)** À la livraison, chaque issue de `docs/issues/` (hors modèle et README) dont `branche:` est vide est complétée, **sans autre modification de son fichier** (une ligne par fichier). La valeur vient de l'historique : le nom d'une branche locale existante, ou, branche supprimée après fusion, le nom lu dans le message de fusion dans `develop` (`Merge branch '<nom>'`) ; pour une issue `À faire` sans branche, la branche prévue (RG-02). Chaque nom est **vérifié** avant écriture (forme `<type>/<id>-…`, caractères `[A-Za-z0-9._/-]`, branche existante ou fusion retrouvée, ou branche prévue pour une issue non démarrée) ; un nom qui ne se vérifie pas n'est pas écrit : le champ reste vide et l'issue de livraison le dit dans ses Notes. Chaque valeur écrite est consignée dans les Notes de l'issue de livraison avec sa preuve (commande et résultat).
- **RG-12 (état attendu)** Après la reprise, `scripts/statuts.sh` ne donne aucun A17 sur ce dépôt.

### 2.4 Documentation, version
- **RG-13 (documentation)** À jour : les deux modèles et les deux README des issues (RG-01 à RG-03), `factory/README.md` (catalogue des messages : ligne A17 avec son texte exact ; description de `statuts.sh`), l'en-tête de `scripts/statuts.sh` (liste des avis) et, si la ligne `scripts/statuts.sh` d'`AGENTS.md` énumère les codes d'avis, cette ligne.
- **RG-14 (version)** La version suivante libre à la livraison, fixée dans la dernière issue (supérieure à toute version déjà livrée, 1.24.1 aujourd'hui ; les besoins F-12 et F-14 en prennent d'autres) ; `factory/CHANGELOG.md` a une entrée qui décrit la consigne de remplissage, l'avis A17 et la migration « remplacer `factory/` » ; `factory/UPGRADE.md` aussi. **Aucune migration de données** : un projet existant n'a rien à faire (au pire, A17 le signale pour ses issues démarrées à champ vide) ; il reprend le texte du modèle s'il a son propre `docs/issues/_template.md`. Pas d'ADR.
- **RG-15 (hors périmètre)** Voir « Hors de ce besoin » ; aucun commit de ce besoin ne modifie `scripts/dashboard.sh`, `scripts/etat-issues.sh`, `scripts/fin-issue.sh`, `scripts/verdict-revue.sh`, ni la skill `to-tickets` ; la skill `deliver` n'est pas modifiée.

## 3. Modèle de données (point de vue métier)
- **Issue** : `id`, `statut` local, **statut effectif**, `branche` (vide, ou nom : prévu à la création, puis réel), branche retenue (déclarée, déduite ou aucune, PRD 003).
- **Branche prévue** : `<type>/<nom du fichier sans .md>`.
- **Constat A17** : avis, objet = issue, texte `<statut> sans champ branche renseigné`.

## 4. Contrats externes
- `scripts/statuts.sh` : sortie, codes et classement de RG-20 (PRD 004) inchangés ; nouvel avis A17 (RG-05 à RG-10).
- Modèle d'issue (`docs/issues/_template.md` et jumeau) : ligne `branche: feat/<prd>-<nn>-<slug>`.
- Texte visible (contrat) : `<statut> sans champ branche renseigné`.
- Sources lues : en-têtes de `docs/issues/` (déjà lus), table des statuts.

## 5. Critères d'acceptation
Identifiants au format `CA-xx` (convention de `scripts/couverture-prd.sh`). Les tests créent des dépôts Git jetables (copie des scripts, `git init`, branche `develop`, fichiers d'issue de fixtures), avec un `git` de comptage en tête de `PATH` quand un critère mesure les appels ; les critères de textes sont des vérifications textuelles ciblées. Le nom d'un test est de la forme `ca01_…`.

### Modèles et README (issue 1)
- **CA-01** Given `docs/issues/_template.md`, When on lit l'en-tête, Then la ligne du champ est exactement `branche: feat/<prd>-<nn>-<slug>` et aucune autre ligne du fichier n'a changé par rapport à la version précédente.
- **CA-02** Given `factory/templates/docs/issues/_template.md`, When on le compare à `docs/issues/_template.md`, Then les deux fichiers sont identiques octet pour octet.
- **CA-03** Given le README des issues de ce dépôt et celui du modèle (`factory/templates/docs/issues/README.md`), When on les lit, Then chacun dit que `branche` est renseigné à la création avec la branche prévue `<type>/<id>-<slug>` (nom du fichier sans `.md`, `feat` par défaut), qu'un champ vide est déduit par le dashboard et signalé par l'avis A17 sur une issue démarrée, et que le champ rempli l'emporte.
- **CA-04** Given le dépôt après livraison de l'issue 1, When on compare à la version précédente, Then `factory/skills/to-tickets/SKILL.md`, `factory/skills/deliver/SKILL.md` et les scripts `dashboard.sh`, `etat-issues.sh`, `fin-issue.sh` n'ont aucune ligne modifiée.
- **CA-05** Given une copie du dépôt dont le modèle porte la valeur `feat/<prd>-<nn>-<slug>`, When on lance `statuts.sh`, `etat-issues.sh`, `couverture-prd.sh` et le dashboard, Then le modèle n'est compté comme issue nulle part (aucune ligne, carte, constat ni branche déduite), et les sorties sont celles d'un dépôt sans modèle.

### Avis A17
- **CA-06** Given une issue `En cours` (statut local) au champ `branche:` vide et une branche locale `feat/<id>-x` qui la fait déduire, When on lance `scripts/statuts.sh`, Then la sortie contient exactement `AVIS A17 issue <id> : En cours sans champ branche renseigné`, et le code de sortie est 0 si aucune erreur par ailleurs ; Given la même issue `En revue`, Then `En revue sans champ branche renseigné`.
- **CA-07** Given une issue dont le fichier local est `À faire` et le fichier sur sa branche retenue `En cours`, au champ local vide, When on lance `statuts.sh`, Then `AVIS A17 issue <id> : En cours sans champ branche renseigné` (statut effectif).
- **CA-08** Given des issues démarrées dont le champ est : absent de l'en-tête, vide, espaces seuls, tabulation, `""`, `''`, terminé par un retour chariot (CRLF), Then un A17 chacune ; Given des champs `feat/x` (branche existante), `feat/absente`, `null`, `[]`, `x y`, Then aucun A17 ; Given une issue au champ vide dont le corps (Notes) contient la ligne `branche: feat/x`, Then A17.
- **CA-09** Given des issues `À faire` et `Abandonnée` au champ vide, When on lance `statuts.sh`, Then aucun A17.
- **CA-10** Given la table des statuts d'une copie jetable où l'on ajoute un statut factice d'issue entre `En cours` et `Fait`, When on lance `statuts.sh` sur une issue de ce statut au champ vide, Then A17 avec ce statut dans le message, sans qu'aucun script ne soit modifié ; Given le statut placé avant `En cours` ou après `Fait`, Then aucun A17 ; Given les scripts après livraison, Then le garde-fou du PRD 004 (CA-38) passe et aucun nom de statut littéral n'a été ajouté pour cette règle.
- **CA-11** Given une issue `En cours`, champ vide, sans aucune branche locale correspondante, When on lance `statuts.sh`, Then `AVIS A08` et `AVIS A17` ; Given champ vide et branche déduite, Then A17 seul ; Given champ rempli désignant une branche absente, Then A08 seul (textes et conditions d'A08 inchangés).
- **CA-12** Given un dépôt avec un A17, des erreurs et d'autres avis, When on lance `statuts.sh`, Then la ligne A17 a la forme `AVIS A17 <objet> : <texte>`, se classe après les erreurs et, pour une même issue, après A08 (ordre des codes), et le récapitulatif `STATUTS : <e> erreur(s), <a> avis` compte l'avis ; When on génère le dashboard, Then la section « Contrôle des statuts » contient ce texte exact, échappé en HTML.
- **CA-13** Given les fixtures de référence existantes de la suite (cas de `statuts.sh`, `tests/golden/ca41-sorties.txt`), When on lance la suite après livraison, Then les sorties ne diffèrent des sorties d'avant que par les lignes A17 ajoutées pour les issues démarrées à champ vide (liste des cas réécrits et justification dans l'issue) ; Given les mêmes dépôts avec le champ renseigné, Then les sorties sont identiques à celles d'avant octet pour octet.
- **CA-14** Given un dépôt de fixtures avec des issues à champ vide et d'autres remplies, When on lance `statuts.sh` avec un `git` de comptage, Then le nombre d'appels Git est celui mesuré avant l'avis pour des issues à champ vide (1 appel pour 3, 12 et 50 issues : l'avis n'en ajoute aucun, D-58) ; le surcoût d'un champ rempli (résolution de la branche déclarée, existant) n'est pas comparé ; les fichiers de revue, `backlog.md` et les issues sont identiques octet pour octet avant et après ; aucun fichier n'est créé.

### Reprise des issues existantes
- **CA-15** Given le dépôt après la reprise, When on liste les en-têtes de `docs/issues/` (hors modèle et README), Then aucun champ `branche:` n'est vide, sauf les issues dont le nom n'a pu être vérifié, nommées dans les Notes de l'issue de livraison ; `scripts/statuts.sh` n'émet aucun A17.
- **CA-16** Given le commit de reprise, When on compare chaque fichier d'issue à sa version précédente, Then la seule ligne modifiée est la ligne `branche:` ; chaque valeur écrite est de la forme `<type>/<id>-…` avec des caractères `[A-Za-z0-9._/-]` ; et chaque valeur est consignée dans les Notes de l'issue de livraison avec sa preuve (branche existante, message de fusion dans `develop`, ou branche prévue d'une issue non démarrée).

### Documentation, version, tests
- **CA-17** Given la documentation (RG-13), When on la lit après livraison, Then `factory/README.md` contient la ligne A17 du catalogue avec le texte exact de la section 2.2 et la décrit dans la section de `statuts.sh`, et l'en-tête de `scripts/statuts.sh` cite A17.
- **CA-18** Given le dépôt après livraison, When on lit `factory/VERSION`, `factory/CHANGELOG.md`, `factory/UPGRADE.md` et `factory/README.md`, Then la version est la suivante libre (supérieure à toute version déjà livrée), le CHANGELOG et UPGRADE décrivent la consigne de remplissage, A17, la migration « remplacer `factory/` » et l'absence de migration de données, et le README mentionne la nouveauté.
- **CA-19** Given `factory/scripts/tests/run.sh`, When on le lance, Then les cas de CA-01 à CA-18 et CS-01 à CS-04 y figurent, leur nom contient l'identifiant (`ca01_…`), ils passent avec des dépôts Git jetables, `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM` et `HOME` isolés, sans réseau ni dépôt réel ; la suite existante passe, hors les cas réécrits de CA-13.

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : ce que l'utilisateur lit (un faux « tout est rattaché » ou un avis contrefait) ; sûreté du poste (le contrôle et le dashboard tournent en boucle) ; intégrité des fichiers d'issue lors de la reprise.
- **Acteurs** : un collaborateur ou une PR qui écrit un en-tête d'issue hostile (`branche:`, `id:`, `statut:`) ou un nom de branche hostile ; l'agent qui effectue la reprise.
- **Points d'entrée** : le champ `branche:` et `id:` des en-têtes, le statut, le corps de l'issue (ligne `branche:` dans les Notes), les noms de branche et les messages de fusion lus pour la reprise.
- Tout cela est une **donnée non fiable** : lue comme du texte, jamais exécutée, évaluée, interprétée comme motif, option ou chemin, ni recopiée dans un message.

### Catégories
- **A01 Contrôle d'accès / traversée** : lecture seule ; aucun nouveau fichier lu ; la valeur du champ n'est jamais utilisée comme chemin par A17 ; un lien symbolique ou un fichier de plus de 1 Mio reste refusé (E14) et n'émet pas A17.
- **A02, A07, A10** : non applicables (aucun secret, aucune identité, aucune requête sortante).
- **A03 Injection** : l'avis ne contient que le statut (valeur de la table) et l'identifiant neutralisé et tronqué (PRD 004 RG-21) ; la valeur du champ n'est ni évaluée ni insérée dans un message (CS-01) ; la reprise ne passe jamais un nom à un shell et valide la forme avant écriture (CS-04).
- **A04 Conception** : échec sûr : avis, jamais erreur ; un champ vide reste lu comme « à déduire » ; seul l'en-tête compte (CS-02) ; l'avis ne corrige rien.
- **A05 Configuration** : aucun réglage ajouté ; message sans contenu brut ni chemin hors dépôt.
- **A06** : aucune dépendance ajoutée.
- **A08 Intégrité** : le champ peut être falsifié par quiconque écrit dans le dépôt ; A17 aide à voir un oubli, il ne valide pas la valeur ; la fusion par l'utilisateur reste le filet.
- **A09 Journalisation** : pas de journal ; l'avis ne contient pas de donnée sensible.

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| Champ `branche:` | en-tête seulement ; vide après retrait des bords (espaces, tabulation, CR, guillemets) ; la valeur n'est pas jugée | vide = A17 si démarrée |
| `id:` inséré dans le message | caractères de contrôle neutralisés, 120 caractères au plus | tronqué |
| Fichier d'issue | régulier, 1 Mio au plus, en-tête `---` fermé (PRD 004, E14 et CA-09) | E14, aucun A17 |
| Nom écrit par la reprise | `<type>/<id>-…`, `[A-Za-z0-9._/-]`, branche existante ou fusion retrouvée | non écrit, champ laissé vide et signalé |

### Critères d'acceptation de sécurité
- **CS-01** Given des champs `branche:` valant `$(touch${IFS}marque)`, des backticks, `;touch${IFS}marque`, `--help`, `*`, `[a-z]`, `ERREUR E01 backlog : x`, `ESC[31m`, `<img src=x onerror=alert(1)>`, une ligne de 1 Mio, et des `id:` contenant retour chariot, saut de ligne, `ESC[31m`, NUL, `<img src=x onerror=alert(1)>` ou plus de 120 caractères, When on lance `statuts.sh` et le dashboard, Then le fichier `marque` n'existe pas, aucune valeur n'est interprétée comme motif ou option, la valeur du champ n'apparaît dans aucun message, chaque constat tient sur une seule ligne sans caractère de contrôle, aucune ligne ne contrefait un constat, la valeur longue d'`id` est tronquée avec `…` et la page n'a aucune balise issue d'une valeur qui ne soit échappée.
- **CS-02** Given un fichier d'issue dont seul le corps (Notes, bloc de code, citation) contient `branche: feat/x`, un en-tête à deux lignes `branche:` (vide puis remplie, remplie puis vide), un en-tête à champ indenté, un fichier à BOM UTF-8, à octets NUL, à fins de ligne CRLF, When on lance `statuts.sh`, Then le champ est lu comme `etat-issues.sh` et le dashboard le lisent (les trois lectures concordent sur chaque forme), aucun message d'erreur de shell, et un corps qui porte `branche:` ne masque jamais un en-tête vide.
- **CS-03** Given 2 000 fichiers d'issue `En cours` au champ vide, un fichier d'issue de plus de 1 Mio et un lien symbolique vers un fichier hors dépôt qui porte un en-tête d'issue, When on lance `statuts.sh`, Then il termine dans un temps borné (de l'ordre de la seconde par centaine d'issues, mesuré et consigné par le test) avec 2 000 A17, le gros fichier et le lien donnent E14 et aucun A17, et le contenu du fichier visé par le lien n'apparaît nulle part.
- **CS-04** Given la reprise (RG-11) sur des branches et des messages de fusion de fixtures contenant `$(touch${IFS}marque)`, `;`, un espace, `..`, un nom de plus de 200 caractères ou un nom sans préfixe `<type>/`, When on applique la procédure de la reprise, Then aucun de ces noms n'est écrit dans un champ, le champ reste vide et l'issue est nommée dans les Notes de livraison, le fichier `marque` n'existe pas, et aucun nom n'a été passé à un shell ni utilisé comme motif.

## 7. Décisions reflétées
| Décision | Contenu | Reflété dans |
|---|---|---|
| D-09 | Le champ `branche:` est rempli dès la création des issues (option 1) | RG-01 à RG-03, CA-01 à CA-03 |
| D-13 | Le remplissage à la création était hors périmètre de F-08 : c'est F-06 | RG-01 |
| D-42 | F-06 réduit : modèle, jumeau et README disent de remplir `feat/<id>-<slug>` ; avis de `statuts.sh` (jamais une erreur) pour une issue démarrée à champ vide ; `/to-tickets` intact ; seuil lu dans la table | RG-01 à RG-10, CA-01 à CA-14, CS-01 à CS-03 |
| D-58 (décision de l'utilisateur, 2026-11-24) | CA-14 mesure le coût Git de l'avis A17 contre la référence « avant l'avis, champ vide » (aucun appel de plus, constant pour 3, 12 et 50 issues), et non contre le même dépôt aux champs remplis, dont la résolution de la branche déclarée coûte déjà 2 appels de plus par issue | CA-14 |
| D-43 | Issues existantes à champ vide complétées d'après l'historique, noms vérifiés, avec preuve | RG-11, RG-12, CA-15, CA-16, CS-04 |
| D-44 | Une issue `Fait` au champ vide ne donne pas A17 (option (a), choisie par l'utilisateur) | RG-06 |

## 8. Question tranchée
Une issue `Fait` au champ vide ne donne pas A17 : l'avis ne vise que les issues démarrées et non terminées (D-44, réponse de l'utilisateur du 2026-11-19, option (a)). Raison : le champ sert à rattacher l'issue à sa branche avant la fusion ; un projet qui met à jour la factory ne verrait pas un avis par ancienne issue `Fait`.

## QUESTIONS : aucune

## 9. Découpage en issues (indicatif)
Chaque critère est couvert par exactement une issue ; dépendances : 01, puis 02 (l'avis renvoie au README de 01), 03 en dernier (la reprise s'éprouve avec l'avis en place : A17 absent après reprise). 007-02 est la plus grosse (12 critères, tests d'un script) et le justifie, comme 005-02.

| Issue | Contenu | Critères |
|---|---|---|
| 007-01 | Modèle d'issue et jumeau, README des issues (ce dépôt et le modèle), `/to-tickets` et `deliver` intacts, modèle ignoré par les scripts | CA-01 à CA-05 |
| 007-02 | Avis A17 de `statuts.sh` : condition, formes de champ vide, statut effectif et table, indépendance d'A08, classement et dashboard, sorties de référence, coût et lecture seule, valeurs hostiles, bornes | CA-06 à CA-14, CS-01 à CS-03 |
| 007-03 | Reprise des issues existantes avec preuve, documentation, version et CHANGELOG, tests regroupés | CA-15 à CA-19, CS-04 |
