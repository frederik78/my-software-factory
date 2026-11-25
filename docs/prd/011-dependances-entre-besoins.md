# PRD 011 : la colonne « Dépend de » du backlog est contrôlée par la machine à états et visible sur la carte du besoin

## En clair
*Lecture sans contexte : ce bloc résume le document ; les règles et critères qui suivent sont destinés aux tests.*

**Le problème.** Depuis le 2026-11-18, le tableau des besoins de `backlog.md` a une colonne « Dépend de » (les besoins à terminer avant celui-ci). Elle est écrite à la main et rien ne la contrôle : une faute de frappe (`F-99`), une dépendance circulaire ou un besoin démarré dont une dépendance n'est pas terminée passent inaperçus. Le dashboard n'affiche pas ces liens ; il lit les colonnes du backlog par position (confirmé à la lecture de `scripts/dashboard.sh`, lecture des champs 2 à 7 d'une ligne découpée sur `|`), donc la nouvelle colonne prend la place de « Décisions » dans la description de la carte du besoin.

**Ce que ce besoin change**
1. **Une erreur E15 quand le graphe est cassé** : une dépendance vers un besoin qui n'existe pas, ou en cycle (un besoin qui dépend de lui-même, deux ou trois besoins qui se renvoient l'un à l'autre). Code de sortie 1.
2. **Un avis A18 quand l'ordre n'est pas respecté** : un besoin `En cours` ou `En revue` dont une dépendance n'est pas `Fait`. Avis seulement : l'empilement de branches permet parfois de commencer avant. Code de sortie inchangé.
3. **Le dashboard affiche les liens** : la carte du besoin montre « dépend de F-xx (statut) » pour chaque dépendance ; les colonnes du backlog y sont lues par leur nom.
4. **Sûr, sans surprise** : la colonne est une donnée non fiable (vide, `-`, virgules, identifiant inconnu, cycle, très longue, caractères de contrôle, HTML) ; le contrôle reste en lecture seule, sans appel Git de plus, et son coût est borné.

**Hors de ce besoin** : modifier `backlog.md` (le contrôle ne corrige rien), les dépendances entre issues (`depend_de`, PRD 004 A09 à A11, inchangées), tout effet sur `etat-issues.sh --prochaine` (D-53), refuser ou retarder un besoin (lien d'ordre seulement), reconstruire l'ordre de livraison, les besoins non fonctionnels.

**Comment lire la suite** : section 2, les règles (RG-xx) et les messages ; section 5, les 22 critères CA et section 6, les 4 critères CS ; section 7, les décisions ; section 8, la question tranchée ; section 9, le découpage en 3 issues.

Besoin : F-15 (`backlog.md`). Décisions de cadrage reprises telles quelles : D-48 (dépendance inconnue ou en cycle = erreur ; besoin démarré dont une dépendance n'est pas `Fait` = avis ; carte « dépend de F-xx (statut) ») et D-53 (`--prochaine` ignore les dépendances entre besoins). Ce PRD ne les rouvre pas.
Préalable : le PRD 004 (F-09) est livré : le contrôle prolonge `scripts/statuts.sh` (tables de statuts, lecture du tableau des besoins RG-04, forme de sortie RG-20, neutralisation RG-21, lecture seule RG-24, coût RG-25, catalogue RG-23). Le « produit » est la factory elle-même (scripts bash, Markdown) : les noms de commande, de code et de message sont des contrats ; aucune structure de code n'est décrite.
**Amendement du catalogue RG-23 du PRD 004 (à signaler)** : ce PRD ajoute E15 et A18, comme les PRD 005 (A16) et 007 (A17) l'ont fait ; l'amendement est répercuté par la session, pas par ce PRD. A17 est réservé par le PRD 007 (branche `docs/f-06-cadrage`, non fusionnée) ; E15 et A18 sont libres à la date de rédaction (à revérifier avant la livraison : les codes se tiennent dans l'ordre de livraison).

## 1. Contexte et besoin

### Acteurs
- **Utilisateur** : tient `backlog.md` (y compris « Dépend de »), lit le dashboard, décide des statuts de besoin.
- **Session orchestrateur** : lance le contrôle à chaque changement de statut (`/deliver`) ; ne modifie pas la colonne.
- **Mainteneur de la factory** : ses tests sont en bash (`factory/scripts/tests/run.sh`).

### Existant (observé)
- Le tableau des besoins a pour colonnes `ID | Besoin | Priorité | Statut | PRD | Dépend de | Décisions`. Convention du backlog : identifiants séparés par une virgule, `-` si aucun ; l'en-tête du backlog dit « lien d'ordre, pas encore contrôlé par la machine à états ». Exemples réels : `-`, `F-01`, `F-01, F-08, F-02`.
- `scripts/statuts.sh` lit le tableau par le nom des colonnes `ID`, `Statut`, `PRD`, `Décisions` (RG-04) ; il ne lit pas « Dépend de ». Dernier code d'erreur : E14 ; avis : A15 (A16 réservé au PRD 005, A17 au PRD 007).
- Le dashboard lit les six premières colonnes après `ID` par position : `Besoin`, `Priorité`, `Statut`, `PRD`, puis la cinquième (aujourd'hui « Dépend de », hier « Décisions ») ; la carte d'un besoin affiche priorité, avancement, « à vérifier », PRD et ce dernier texte comme description.
- Les dépendances entre issues (`depend_de`) sont déjà contrôlées (A09 à A11, PRD 004) ; celles entre besoins ne le sont pas.
- État du backlog au 2026-11-19 : aucune dépendance inconnue ni circulaire ; `F-02` et `F-12` (`En cours`) ne dépendent que de besoins `Fait` (`F-01`, `F-09`).

### Besoin
Que la machine à états lise « Dépend de » : signaler un graphe cassé (inconnu, cycle) et un besoin démarré avant ses dépendances, afficher les liens sur la carte du besoin, sans jamais modifier `backlog.md`.

## 2. Exigences fonctionnelles et règles de gestion

Vocabulaire : **dépendance d'un besoin** = un identifiant listé dans sa cellule « Dépend de » ; **besoin source** = besoin contrôlé (identifiant unique, statut connu, ligne lisible : mêmes lignes que les autres contrôles de besoin, PRD 004 RG-23, note finale) ; **besoin démarré** = statut `En cours` ou `En revue`, tel que la table des statuts les classe (« en travail ») ; **dépendance terminée** = son statut au backlog est le dernier du cycle des besoins (`Fait`, selon la table). Les statuts viennent de la table unique, jamais d'une liste recopiée (PRD 004 RG-01).

### 2.1 Lecture de la colonne (D-48)
- **RG-01 (colonne par son nom)** La colonne est repérée par son nom d'en-tête exact `Dépend de`, comme les autres colonnes (PRD 004 RG-04), quelle que soit sa position. Sans cette colonne, aucune dépendance n'est lue et rien n'est signalé (un backlog plus ancien reste valide, aucune erreur). Si le nom revient, la première colonne est lue.
- **RG-02 (forme de la cellule)** Une cellule vide ou valant exactement `-` (espaces de bord retirés) n'a aucune dépendance. Sinon la cellule est une liste d'identifiants séparés par des virgules ; chaque identifiant est lu sans espaces de bord ; un élément vide (`F-01,,F-02`, virgule finale) est ignoré ; un identifiant répété n'est compté qu'une fois ; l'ordre de la cellule est conservé. Aucun autre séparateur n'existe : `F-01 F-02`, `F-01;F-02` ou `-, F-01` donnent des éléments qui ne sont l'identifiant d'aucun besoin (RG-04).
- **RG-03 (comparaison exacte)** Un identifiant est comparé comme du texte littéral, sensible à la casse (`F-1` n'est pas `F-10`, `f-01` n'est pas `F-01`), à l'identifiant d'une ligne du tableau. Il n'est jamais un motif, une option, une expression ni un chemin.
- **RG-04 (cibles)** Une dépendance désigne un besoin connu si son identifiant est celui d'une ligne du tableau, quelle que soit la lisibilité ou le statut de cette ligne (une ligne en E03, E04 ou E05 existe). Sinon le besoin est inconnu.
- **RG-05 (sources)** Seule la cellule d'un besoin source est lue pour les contrôles de ce PRD : une ligne illisible (E03), à identifiant en double (E04) ou à statut inconnu (E05) est signalée par son propre code et ne produit ni E15 ni A18 (échec sûr : une ligne douteuse ne se juge pas).
- **RG-06 (limite)** Au plus 64 identifiants sont examinés par cellule (comme les chemins de PRD, PRD 004 RG-04) ; au-delà, E15 « plus de 64 identifiants » (RG-09) et les suivants ne sont pas examinés ; les 64 premiers sont examinés et leurs dépendances inconnues signalées (RG-07, D-61). Aucune autre limite que la taille du backlog.

### 2.2 Erreur E15 : graphe cassé (D-48)
- **RG-07 (dépendance inconnue)** Pour chaque dépendance (RG-02) qui désigne un besoin inconnu (RG-04), une erreur E15 sur le besoin source, dans l'ordre de la cellule.
- **RG-08 (cycle)** Un besoin appartient à un cycle s'il peut s'atteindre lui-même en suivant ses dépendances (un besoin qui dépend de lui-même, deux besoins qui se renvoient l'un à l'autre, trois en boucle, etc.). Chaque besoin source d'un cycle reçoit une erreur E15 qui cite les besoins du cycle (ceux qui s'atteignent mutuellement, dans l'ordre du tableau, séparés par `, `, 10 au plus puis `, …`, D-61). Un besoin qui dépend d'un cycle sans en faire partie ne reçoit rien de ce chef. Le statut du besoin est sans effet : un besoin `Fait` ou `Abandonnée` en cycle est signalé.
- **RG-09 (cellule trop longue)** Une cellule de plus de 64 identifiants (RG-06) donne une erreur E15 sur le besoin source.
- **RG-09 bis (ordre et caractère NUL, D-61)** Les E15 d'un même besoin sont émises dans cet ordre : dépendances inconnues (ordre de la cellule), puis « plus de 64 identifiants », puis cycle. Un caractère NUL dans une ligne du backlog coupe la ligne : elle est illisible (E03, comportement existant de la lecture du backlog), sans E15.
- **RG-10 (gravité)** E15 est une erreur : code de sortie 1 (PRD 004 RG-20). Les autres constats sur le besoin restent émis.

### 2.3 Avis A18 : besoin démarré avant ses dépendances (D-48)
- **RG-11 (règle)** Pour un besoin source démarré (`En cours` ou `En revue`), chaque dépendance connue (RG-04) dont le statut au backlog est un statut connu autre que le dernier du cycle (donc `À faire`, `En clarification`, `Spécifié`, `En cours`, `En revue` ou `Abandonnée`) donne un avis A18, dans l'ordre de la cellule. Avis, jamais erreur : l'empilement de branches permet de commencer avant la fin d'une dépendance, et le code de sortie n'est pas modifié.
- **RG-12 (hors règle)** Aucun avis A18 pour un besoin `À faire`, `En clarification`, `Spécifié`, `Fait` ou `Abandonnée` (pas démarré, ou fini : un besoin `Fait` dont une dépendance ne l'est pas relève de la décision de l'utilisateur) ; aucun pour une dépendance inconnue (E15 le dit déjà), à ligne illisible ou à statut inconnu (E03, E04, E05 le disent déjà). Une dépendance `Abandonnée` n'est jamais levée : A18, comme A09 pour les issues.
- **RG-13 (le statut du backlog)** Le statut d'une dépendance est celui de sa ligne du backlog, jamais recalculé à partir de ses issues (le statut d'un besoin reste décidé par l'utilisateur, PRD 004).
- **RG-14 (effet sur les issues, D-53)** Aucun. `etat-issues.sh --prochaine`, les cartes d'issues et les statuts effectifs sont inchangés ; le lien entre besoins est un contrôle (avis A18), pas une règle d'ordonnancement.

### 2.4 Dashboard (D-48)
- **RG-15 (carte du besoin)** La carte d'un besoin affiche une ligne « dépend de <id> (<statut>) » par dépendance (RG-02, 64 au plus, dans l'ordre de la cellule), où `<statut>` est le statut de la dépendance au backlog tel que la table le connaît, ou `inconnu` si l'identifiant ne désigne aucun besoin ou si son statut n'est pas dans la table. Rien n'est affiché pour un besoin sans dépendance (RG-02) ni sans colonne (RG-01). Texte échappé en HTML, valeurs neutralisées (PRD 004 RG-21).
- **RG-16 (colonnes par leur nom)** Le dashboard lit les colonnes du tableau des besoins par leur nom d'en-tête, comme le contrôle : la description de la carte est la colonne « Décisions », jamais « Dépend de ». Les colonnes, cartes, ordre et avancement des besoins ne changent pas autrement. Le code de sortie du dashboard ne dépend pas du résultat du contrôle (PRD 004 RG-26).
- **RG-17 (section de contrôle)** La section « Contrôle des statuts » affiche E15 et A18 comme les autres constats (PRD 004 RG-26).

### 2.5 Sortie, messages (PRD 004 RG-20, RG-21, RG-23)
- **RG-18 (catalogue, ajout à RG-23)** Le texte est un contrat (`<…>` = valeur neutralisée) :

| Code | Gravité | Objet | Texte |
|---|---|---|---|
| E15 | erreur | `besoin <id>` | `dépend de « <valeur> », besoin inconnu du backlog` \| `dépendance en cycle (<liste des besoins du cycle>)` \| `colonne « Dépend de » : plus de 64 identifiants` |
| A18 | avis | `besoin <id>` | `statut <statut> alors que la dépendance <id> est <statut de la dépendance>` |

  Forme, tri (objet besoin : ordre du tableau, puis code, puis ordre d'émission), récapitulatif et codes de sortie : PRD 004 RG-20, inchangés. `<statut de la dépendance>` est un statut de la table (lu au backlog) : jamais une valeur libre.
- **RG-19 (valeurs insérées)** Les identifiants et le texte de la cellule insérés dans un message sont neutralisés et tronqués à 120 caractères (PRD 004 RG-21). Aucune valeur n'est évaluée, exécutée, utilisée comme motif ou option.

### 2.6 Lecture seule, coût
- **RG-20 (lecture seule)** Aucune écriture dans `backlog.md`, une issue, un PRD, les refs, l'index, l'arbre de travail ni les worktrees (PRD 004 RG-24, D-21) ; aucun verrou d'index.
- **RG-21 (coût)** Aucun appel Git de plus : les statuts de besoins sont déjà lus (le plafond de 3 appels de PRD 004 RG-25 n'est pas consommé). Le coût du contrôle est borné par le nombre de besoins et de dépendances lus (un seul passage sur le tableau, résolution des identifiants par table de hachage, détection des cycles en temps linéaire, au plus 64 dépendances par besoin) ; il ne croît ni avec le nombre d'issues ni avec le nombre de branches.

### 2.7 Documentation, version
- **RG-22 (documentation)** `factory/README.md` (catalogue des messages : E15 et A18 avec leur texte exact ; mention de la colonne dans la section du contrôle et du dashboard), l'en-tête de `scripts/statuts.sh` et de `scripts/dashboard.sh`, les plages de codes citées (`AGENTS.md`, `factory/templates/AGENTS.md`, README), la phrase de `backlog.md` « pas encore contrôlé par la machine à états » (propriété de l'utilisateur : proposée, pas modifiée). L'amendement du PRD 004 est signalé (en tête de ce PRD).
- **RG-23 (version)** Version suivante libre à la livraison, fixée dans l'issue de documentation (pas écrite ici) ; entrée du `CHANGELOG.md` et section `UPGRADE` (migration « remplacer `factory/` » ; aucune migration de données : une colonne absente ou en `-` ne change rien). Pas d'ADR.

## 3. Modèle de données (point de vue métier)
- **Besoin** (PRD 004) + **dépendances** : 0 à 64 identifiants, dans l'ordre de la cellule, sans doublon ; chacune est *connue* (avec le statut au backlog de sa cible) ou *inconnue*.
- **Cycle** : ensemble de besoins qui s'atteignent mutuellement par leurs dépendances (un besoin seul s'il dépend de lui-même).
- **Constat** : inchangé (gravité, code, objet, texte) ; deux codes de plus.

## 4. Contrats externes
- `scripts/statuts.sh` : sans argument, contrôle ; options, usage et codes inchangés (0, 1, 64) ; deux codes de plus (RG-18). `--table` inchangé.
- `scripts/dashboard.sh` : options, codes et colonnes inchangés ; ligne « dépend de » sur la carte du besoin ; description de carte lue dans « Décisions » par nom.
- Source lue : la colonne « Dépend de » du tableau des besoins de `backlog.md`, rien d'autre (aucun appel Git).
- Format : voir RG-02. Le backlog ne change pas de format.

## 5. Critères d'acceptation
Format `CA-xx` (convention de `scripts/couverture-prd.sh`). Les tests créent des dépôts Git jetables (copie des scripts, `git init`, `backlog.md` et issues de fixtures), `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM` et `HOME` isolés, sans réseau ; un `git` de comptage en tête de `PATH` quand un critère mesure les appels. Le nom d'un test est de la forme `ca01_…`. Dans les fixtures, `F-02` dépend de `F-01` quand rien d'autre n'est dit.

### Lecture de la colonne et erreur E15
- **CA-01** Given un backlog dont la colonne « Dépend de » est en sixième, puis en troisième position, avec une cellule vide, une cellule `-` et une cellule `F-01`, When on lance `statuts.sh`, Then la colonne est lue par son nom (même résultat aux deux positions), les cellules vide et `-` ne donnent aucun constat ; Given un backlog sans cette colonne, Then aucune dépendance n'est lue, aucun constat E15 ou A18, et la sortie est identique à celle d'avant la livraison.
- **CA-02** Given une cellule `F-01, F-08` (espaces de bord), `F-01,,F-08`, `F-01,`, `F-01, F-01`, When on lance `statuts.sh`, Then chaque cellule donne les dépendances `F-01` et `F-08` (ou `F-01` seul), les éléments vides sont ignorés, un identifiant répété compte une fois ; Given `F-1` face à un besoin `F-10` seul, ou `f-01` face à `F-01`, Then la dépendance est inconnue (E15).
- **CA-03** Given une cellule `F-99`, `F-01 F-08`, `F-01;F-08`, `-, F-01`, `$(touch marque)`, `*`, When on lance `statuts.sh`, Then `ERREUR E15 besoin <id> : dépend de « <valeur> », besoin inconnu du backlog` pour chaque identifiant inconnu (un message par identifiant, dans l'ordre de la cellule), le code est 1, et un identifiant valide voisin n'est pas signalé ; Given une dépendance vers un besoin dont la ligne est en E03, E04 ou E05, Then aucun E15 (le besoin existe).
- **CA-04** Given un besoin qui dépend de lui-même, deux besoins qui dépendent l'un de l'autre, trois besoins en boucle (`F-01` vers `F-02` vers `F-03` vers `F-01`), When on lance `statuts.sh`, Then chaque besoin du cycle a une ligne `ERREUR E15 besoin <id> : dépendance en cycle (<liste>)` où la liste est celle du cycle dans l'ordre du tableau (un seul besoin pour l'auto-dépendance) ; un besoin qui dépend du cycle sans en faire partie n'a aucun E15 ; un cycle de 12 besoins affiche 10 identifiants puis `…` ; un besoin `Fait` ou `Abandonnée` en cycle est signalé ; le code est 1.
- **CA-05** Given un besoin dont la ligne est illisible (E03), à identifiant en double (E04) ou à statut inconnu (E05) et dont la cellule « Dépend de » contient `F-99` ou un cycle, When on lance `statuts.sh`, Then seul le code propre à la ligne est émis, aucun E15 ni A18 de son chef ; Given une dépendance d'un besoin valide vers cette ligne, Then aucune erreur de dépendance inconnue (CA-03).
- **CA-06** Given une cellule de 64 identifiants valides, puis de 65 dont le dernier est inconnu, When on lance `statuts.sh`, Then 64 identifiants sont examinés sans constat ; avec 65, `ERREUR E15 besoin <id> : colonne « Dépend de » : plus de 64 identifiants`, le 65e identifiant n'est pas examiné (aucun E15 « inconnu » pour lui).
- **CA-07** Given un backlog reproduisant les lignes du 2026-11-19 (F-01 à F-16 et leurs colonnes), When on lance `statuts.sh`, Then aucun E15 et seulement les A18 attendus d'après les statuts de ces lignes (aucun si chaque besoin démarré n'a que des dépendances `Fait`) ; Given des E15 et des constats d'autres codes, Then les lignes ont la forme `ERREUR E15 besoin <id> : …`, les erreurs précèdent les avis, le tri est celui de PRD 004 RG-20, le récapitulatif compte E15 et A18, et le code de sortie est 1 s'il y a au moins une erreur.

### Avis A18
- **CA-08** Given un besoin `En cours` puis `En revue` dont une dépendance est `À faire`, `En clarification`, `Spécifié`, `En cours`, `En revue` ou `Abandonnée`, When on lance `statuts.sh`, Then `AVIS A18 besoin <id> : statut <statut> alors que la dépendance <id> est <statut de la dépendance>` pour chacune ; avec cet avis seul, le code est 0.
- **CA-09** Given une dépendance `Fait`, Then aucun A18 ; Given un besoin `À faire`, `En clarification`, `Spécifié`, `Fait` ou `Abandonnée` dont une dépendance n'est pas `Fait`, Then aucun A18.
- **CA-10** Given un besoin `En cours` dont la dépendance est inconnue (CA-03), a une ligne illisible, en double ou à statut inconnu, Then aucun A18 (E15, E03, E04 ou E05 seul).
- **CA-11** Given un besoin `En revue` à trois dépendances (`F-01` Fait, `F-05` `En cours`, `F-09` `À faire`), Then deux A18, dans l'ordre de la cellule, aucun pour `F-01` ; la cellule `F-05, F-05` n'en donne qu'un.
- **CA-12** Given une copie jetable dont la table des statuts de besoin reçoit un statut factice entre `En cours` et `En revue`, When on lance `statuts.sh`, Then un besoin à ce statut avec une dépendance non terminée donne A18 (il est « démarré » selon la table) ; Given le statut retiré, Then E05 ; Given une copie où la table renomme le dernier statut du cycle, Then A18 suit ; et le garde-fou de PRD 004 (CA-38, CA-39) reste vert (aucune liste de statuts dans le code ajouté).
- **CA-13** Given un dépôt de fixtures riche (cycles, inconnus, avis), When on lance `statuts.sh` (avec et sans `--table`) puis le dashboard, Then `backlog.md`, les fichiers de `docs/issues/`, `docs/reviews/` et `docs/prd/`, les refs, l'index, l'arbre de travail et la liste des worktrees sont identiques avant et après, sans `index.lock` ; Given des dépôts jetables de 3, 12 puis 50 issues, avec et sans colonne « Dépend de » remplie (20 puis 200 besoins), When on compte les appels Git, Then ils sont identiques (aucun appel de plus du chef des dépendances).
- **CA-14** Given `backlog.md` absent, un backlog sans tableau reconnu, une ligne de besoin coupée avant la colonne « Dépend de », Then `statuts.sh` termine sans message d'erreur de shell : E01 seul pour le premier, E02 sans E15 ni A18 pour le deuxième, E03 pour la ligne coupée.

### Dashboard, documentation, version
- **CA-15** Given un besoin de dépendances `F-01, F-09` au statut `Fait`, When on génère le dashboard, Then sa carte contient « dépend de F-01 (Fait) » et « dépend de F-09 (Fait) », une ligne chacune, dans l'ordre de la cellule, le statut étant celui de la ligne du backlog de la dépendance ; Given `-`, une cellule vide ou un backlog sans la colonne, Then aucune ligne « dépend de ».
- **CA-16** Given une dépendance vers `F-99` (absent), vers un besoin dont le statut n'est pas dans la table, ou vers un besoin `Abandonnée`, When on génère le dashboard, Then la carte affiche « dépend de F-99 (inconnu) », « dépend de <id> (inconnu) » et « dépend de <id> (Abandonnée) » ; aucune valeur libre de statut n'est affichée.
- **CA-17** Given le backlog réel (colonnes `… | PRD | Dépend de | Décisions`), When on génère le dashboard, Then la description de chaque carte de besoin est le texte de « Décisions » (jamais celui de « Dépend de »), et la priorité, le PRD, l'avancement et l'ordre des cartes sont identiques à ceux d'avant la livraison ; Given les mêmes colonnes dans un autre ordre, Then le résultat est le même.
- **CA-18** Given des erreurs E15 et des avis A18, When on génère le dashboard, Then la section « Contrôle des statuts » contient chaque constat avec son code et son texte exacts de RG-18, le code de sortie du dashboard reste 0, un cycle ne le fait ni boucler ni échouer, et une cellule de plus de 64 identifiants n'affiche que 64 lignes « dépend de ».
- **CA-19** Given la documentation (RG-22), When on la lit après livraison, Then `factory/README.md` donne E15 et A18 avec leur texte exact de RG-18 et décrit la colonne (contrôle et carte), l'en-tête de `scripts/statuts.sh` et de `scripts/dashboard.sh` aussi, les plages de codes citées incluent E15 et A18, et aucun fichier de propriété de l'utilisateur (`backlog.md`) n'est modifié par la livraison.
- **CA-20** Given le dépôt après livraison, When on lit `factory/VERSION`, `CHANGELOG.md`, la section `UPGRADE` et `factory/README.md`, Then la version est la suivante libre (supérieure à toute version déjà livrée), le CHANGELOG décrit le changement, la migration « remplacer `factory/` » et l'absence de migration de données, et le README mentionne la nouveauté.
- **CA-21** Given `factory/scripts/tests/run.sh`, When on le lance, Then les cas CA-01 à CA-22 et CS-01 à CS-04 y figurent, leur nom contient l'identifiant (`ca01_…`), ils passent avec des dépôts jetables isolés (`GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM`, `HOME`), et `scripts/criteres-sans-test.sh` répond OK pour les trois issues.
- **CA-22** Given des dépôts dont les colonnes « Dépend de » sont absentes ou ne contiennent que `-`, When on lance la suite existante de `run.sh`, `statuts.sh`, `etat-issues.sh` (sans option et `--prochaine`), `dashboard.sh` (hors section de contrôle, date et durées) et `fin-issue.sh` sur une issue, Then tout passe comme avant ce besoin (mêmes sorties et codes) ; `scripts/fin-issue.sh` n'a aucune ligne modifiée ; `etat-issues.sh --prochaine` est identique avec et sans dépendances de besoins non terminées (RG-14, D-53).

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : intégrité de ce que l'utilisateur lit (un faux « graphe sain », un lien affiché faussé) ; sûreté du poste (le dashboard tourne en boucle sans surveillance) ; aucune donnée hors dépôt.
- **Acteurs** : une PR ou un collaborateur qui écrit une cellule « Dépend de » hostile ; un agent qui édite le backlog.
- **Point d'entrée** : la cellule « Dépend de » (et les cellules de statut qu'elle désigne). C'est une **donnée non fiable** : lue comme du texte, jamais exécutée ni interprétée.

### Catégories
- **A01 Contrôle d'accès / traversée** : lecture seule ; aucun chemin dérivé d'une valeur de la colonne ; aucun fichier hors dépôt lu.
- **A02, A07, A10** : non applicables (aucun secret, aucune identité, aucune requête sortante).
- **A03 Injection** : les identifiants sont des clés de comparaison de texte, jamais des motifs, options, commandes ni expressions (RG-03, CS-02) ; sortie neutralisée (CS-01) ; échappement HTML dans la carte et dans la section de contrôle (CS-03) ; le caractère de séparation interne des enregistrements dans une cellule ne peut pas se faire passer pour un enregistrement valide (traité comme inconnu).
- **A04 Conception** : échec sûr : dépendance inconnue, cycle, cellule trop longue = erreur ; ligne douteuse = pas de jugement (RG-05) ; un besoin démarré avant ses dépendances = avis, jamais un blocage ; aucun statut recopié (table unique).
- **A05 Configuration** : aucun réglage ajouté ; pas de trace ni de chemin hors dépôt dans les messages.
- **A06, A08** : aucune dépendance ajoutée ; le contrôle reste un indicateur (une cellule modifiée à la main peut tromper le contrôle ; la fusion par l'utilisateur est le filet).
- **A09 Journalisation** : pas de journal ; valeurs neutralisées et tronquées dans la sortie.

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| Cellule « Dépend de » | vide, `-`, ou liste d'identifiants séparés par des virgules, 64 au plus | E15 |
| Identifiant de dépendance | égal (texte littéral) à l'identifiant d'une ligne du tableau | E15 |
| Cycle de dépendances | aucun besoin ne s'atteint lui-même | E15 |
| Statut de la dépendance | un statut de la table, sinon ni A18 ni valeur affichée (`inconnu`) | E05 |
| Valeur insérée dans un message ou une carte | contrôle neutralisé, 120 caractères au plus, échappée en HTML | tronquée |

### Critères d'acceptation de sécurité
- **CS-01** Given une cellule « Dépend de » contenant retour chariot, saut de ligne, tabulation, `ESC[31m`, `NUL`, caractères de contrôle, une valeur de plus de 120 caractères et un texte imitant un constat (`F-99 ERREUR E15 besoin F-01 : …`), When on lance `statuts.sh`, Then chaque constat tient sur une seule ligne, sans caractère de contrôle (hors saut de ligne final), aucune ligne ne contrefait un constat, la valeur longue est tronquée avec `…`.
- **CS-02** Given des identifiants `$(touch${IFS}marque)`, ``` `touch${IFS}marque` ```, `;touch${IFS}marque`, `-rf`, `--help`, `*`, `[a-z]`, `.*`, `__proto__` et un identifiant contenant le séparateur interne des enregistrements dans la cellule, When on lance `statuts.sh` et le dashboard, Then le fichier `marque` n'existe pas, aucune valeur n'est interprétée comme motif (`*` ne désigne pas tous les besoins), option ou expression, chaque valeur est signalée comme inconnue (E15) et les dépendances valides voisines sont contrôlées normalement.
- **CS-03** Given des valeurs `<img src=x onerror=alert(1)>`, `"><script>alert(1)</script>`, `&amp;'` dans la cellule « Dépend de » et dans les statuts des besoins désignés, When on génère le dashboard, Then aucune balise ni attribut issu d'une valeur n'apparaît brut dans les cartes ni dans la section « Contrôle des statuts » : `&`, `<`, `>`, `"` et `'` sont échappés partout où une valeur est écrite.
- **CS-04** Given un backlog de 5 000 besoins formant une chaîne de dépendances (chacun dépend du précédent), 5 000 besoins formant un seul cycle, une cellule de 1 Mio de plus de 100 000 identifiants et 2 000 fichiers d'issue, When on lance `statuts.sh` puis le dashboard, Then ils terminent sans échec de mémoire, dans la borne du test de volume existant (40 s, mesuré et consigné par le test) ; le temps du contrôle des dépendances croît linéairement avec le nombre de besoins (doubler les besoins ne fait pas plus que doubler ce temps, à la marge près) et une cellule trop longue est tronquée dans les messages.

## 7. Décisions reflétées
| Décision | Contenu | Reflété dans |
|---|---|---|
| D-48 | dépendance inconnue ou en cycle = erreur ; besoin démarré dont une dépendance n'est pas `Fait` = avis ; carte « dépend de F-xx (statut) » | RG-07 à RG-12, RG-15, RG-18, CA-03, CA-04, CA-08, CA-15, CA-16 |
| D-61 | Quatre comportements de 011-01 inscrits : liste d'un cycle séparée par `, ` puis `, …` au-delà de 10 ; ordre des E15 d'un même besoin (inconnus, plus de 64, cycle) ; NUL dans une ligne : E03, pas E15 ; au-delà de 64 identifiants, les 64 premiers sont examinés (décision de l'utilisateur, 2026-11-25) | RG-06, RG-08, RG-09 bis |
| D-53 | `etat-issues.sh --prochaine` ne tient pas compte des dépendances entre besoins : l'avis A18 suffit (réponse de l'utilisateur à Q-01, 2026-11-19) | RG-14, CA-22 |
| D-21 (PRD 004) | le contrôle lit l'état courant, en lecture seule, sans rien corriger | RG-20, RG-21, CA-13, CS-04 |

## 8. Questions
- **Q-01** (RG-14, F-15) `--prochaine` doit-il tenir compte des dépendances entre besoins ? Réponse de l'utilisateur : option (a), non, l'avis A18 suffit (D-53). Appliquée en RG-14 et CA-22.

## QUESTIONS : aucune

## 9. Découpage en issues (indicatif)
Chaque critère est couvert par exactement une issue ; dépendances : 011-01, puis 011-02, puis 011-03. Aucune issue ne dépasse 9 critères.

| Issue | Contenu | Critères |
|---|---|---|
| 011-01 | Lecture de la colonne « Dépend de » (par son nom), erreur E15 (inconnu, cycle, cellule trop longue), forme de la sortie, sûreté des valeurs | CA-01 à CA-07, CS-01, CS-02 |
| 011-02 | Avis A18, piloté par la table, lecture seule, aucun appel Git de plus, fichiers absents, volume borné | CA-08 à CA-14, CS-04 |
| 011-03 | Dashboard (lien sur la carte, colonnes lues par leur nom, section de contrôle, échappement), documentation, version, CHANGELOG, tests regroupés, non-régression | CA-15 à CA-22, CS-03 |
