# PRD 003 : le dashboard donne l'état réel du travail avant la fusion

## En clair
*Lecture sans contexte : ce bloc résume le document ; les règles et critères qui suivent sont destinés aux tests.*

**Le problème.** Le dashboard lit l'état du travail dans `develop`. Une issue terminée sur sa branche, non encore fusionnée, y reste « À faire », et la suivante y reste « bloquée ». Exemple réel : 002-04 était « Fait » sur sa branche et apparaissait « À faire ».

**Ce que ce besoin change**
1. **La branche est retrouvée toute seule.** Si le champ `branche:` d'une issue est vide, le dashboard cherche la branche locale dont le nom commence par le numéro de l'issue (`002-04` → `feat/002-04-…`) et l'indique « (déduite) ». Le champ rempli l'emporte. Si plusieurs branches conviennent, aucune n'est choisie : « branche ambiguë : … ».
2. **Les issues suivantes se débloquent.** Une issue dont les dépendances sont « Fait » sur leur branche n'est plus « bloquée » : elle affiche « empilée sur <branche> ». La commande `etat-issues.sh --prochaine` suit la même règle.
3. **L'avancement des besoins est visible.** La carte d'un besoin affiche le compte de ses issues (« 5/6 Fait · 1 En cours ») et « à vérifier : … » si le statut du backlog diverge. Le dashboard ne modifie jamais `backlog.md`.
4. **Sûr et rapide.** Un nom de branche est une donnée non fiable : jamais exécuté, toujours échappé. Une génération du dashboard fait au plus un appel Git de plus qu'avant.

**Hors de ce besoin** : remplir `branche:` à la création des issues (F-06), afficher le verdict de revue (F-03), lancer la boucle de régénération automatiquement.

**Comment lire la suite** : section 2, les règles (RG-xx) ; section 5, les 33 critères (« Given… When… Then… » : une situation, une action, un résultat) ; section 7, les décisions déjà prises avec l'utilisateur ; section 9, le découpage en 5 issues.

Besoin : F-08 (`backlog.md`). Décisions de cadrage reprises telles quelles : D-10 à D-17. Ce PRD ne les rouvre pas ; D-09 (champ `branche:` rempli à la création) relève de F-06 et complète ce besoin sans en dépendre.
Le « produit » est la factory elle-même (scripts bash, Markdown). Les noms de commande, de message et de fichier visibles par les utilisateurs sont des contrats ; aucune structure de code n'est décrite.

## 1. Contexte et besoin

### Acteurs
- **Utilisateur** : lit le dashboard (`scripts/dashboard.sh`) et le tableau de `scripts/etat-issues.sh` pour savoir où en est le travail.
- **Session orchestrateur** et **developer** : s'appuient sur « la prochaine issue prête » (`scripts/etat-issues.sh --prochaine`).
- **Mainteneur de la factory** : ses tests sont en bash (`factory/scripts/tests/run.sh`).

### Existant (observé)
- Le dashboard lit les en-têtes d'issues dans `docs/issues/` du dossier où il tourne (en pratique `develop`). Le **statut effectif** d'une issue est le plus avancé, dans le cycle `À faire` < `En cours` < `En revue` < `Fait`, du statut local et de celui du même fichier d'issue sur la branche **nommée par le champ `branche:` de l'en-tête**, à condition que ce champ soit rempli et nomme une branche locale existante. Sinon : le statut local. Fichier absent sur la branche, statut inconnu d'un côté : le statut local.
- Le nom de branche vient d'un fichier, donc n'est pas fiable : il est validé par Git, jamais passé à un shell, toujours préfixé `refs/heads/`.
- Une dépendance ne compte `Fait` que **localement** : une issue terminée sur sa branche, non fusionnée, bloque encore les suivantes (carte « bloquée »). `etat-issues.sh --prochaine` applique la même règle (statut local des dépendances) et exige en plus que l'issue elle-même soit `À faire` en statut effectif.
- La carte d'un besoin reprend telle quelle la ligne de `backlog.md` (statut, priorité, PRD, décisions) ; aucune information sur ses issues.
- Les signaux Git des worktrees (fichiers non commités, activité) sont rattachés à une issue par **égalité** entre la branche du worktree et le champ `branche:` ; l'encart « Autres travaux » liste les worktrees dont la branche n'est le champ `branche:` d'aucune issue (hors `develop`, `main`, HEAD détaché).
- `etat-issues.sh` affiche en tableau le statut **local** et le champ `branche:` tel quel.
- Constat du 2026-11-17 : 8 issues sur 12 ont `branche:` vide ; 002-02, 002-04 et 002-05 (Fait sur leur branche) apparaissent « À faire » et 002-06 « bloquée ».
- Le dashboard n'est à jour que si `--boucle` tourne (sinon une seule génération).

### Besoin
Que le dashboard et `etat-issues.sh` donnent l'état réel sans attendre la fusion ni le remplissage du champ `branche:` : rattacher l'issue à sa branche par convention de nommage, lever une dépendance terminée sur sa branche, et afficher l'avancement des issues sur la carte du besoin sans jamais changer son statut du backlog.

## 2. Exigences fonctionnelles et règles de gestion

Vocabulaire : **branche retenue** d'une issue = la branche dont le dashboard lit le statut et les signaux (déclarée ou déduite) ; **statut effectif** = règle de l'existant, appliquée à la branche retenue.

### 2.1 Rattachement d'une issue à sa branche (D-10, D-16)
- **RG-01** Si le champ `branche:` est **rempli**, il l'emporte toujours, comme aujourd'hui : aucune déduction, même si le champ nomme une branche absente ou invalide (statut local seul, sans signalement : une branche supprimée après fusion n'est pas une anomalie, D-16).
- **RG-02** Si `branche:` est **vide**, l'issue est rattachée par convention à la branche **locale** dont le nom est `<type>/<id>-<suffixe>`, où `<type>` est un segment unique non vide (tout type : `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `hotfix`, un autre), `<id>` est l'identifiant de l'issue (champ `id:` de son en-tête), comparé comme du texte littéral, et `<suffixe>` est non vide. L'identifiant doit être **suivi d'un tiret** : `002-1` ne reconnaît pas `feat/002-10-x`, `feat/002-1` ni `feat/002-1-`.
- **RG-03** Seules les branches locales (`refs/heads/`) sont considérées : ni branches de suivi distant, ni étiquettes, ni autre dépôt.
- **RG-04** Plusieurs branches correspondent à la même issue : **aucune n'est retenue** ; l'issue garde son statut local, sans dernier commit ni signal, et sa carte porte `branche ambiguë : <liste>` (noms triés par ordre d'octets, séparés par `, `). Ces branches restent dans « Autres travaux » si un worktree les porte (RG-17).
- **RG-05** Une branche **déclarée** dans le champ `branche:` d'une autre issue n'est jamais déduite pour une issue différente.
- **RG-06** Une branche qui correspond aux identifiants de plusieurs issues par préfixe (`feat/002-01-b-x` pour `002-01` et `002-01-b`) est attribuée à l'issue dont l'identifiant est le **plus long** (Q-09).
- **RG-07** Pas de déduction si l'identifiant est absent, vide, contient un caractère hors `[A-Za-z0-9._-]`, ou est partagé par plusieurs issues (Q-10). Aucune erreur ; l'issue reste traitée comme aujourd'hui (champ vide : statut local).
- **RG-08** Les noms de branche ne sont jamais interprétés comme motif : le `.`, `*`, `?`, `[` d'un identifiant ou d'un nom sont des caractères littéraux. Un nom de plus de 200 caractères ou invalide pour Git est ignoré (Q-12).
- **RG-09** La carte d'une issue dont la branche est **déduite** affiche `branche : <nom> (déduite)` ; une branche déclarée n'ajoute aucune mention (comportement actuel). Une branche retenue fournit, comme aujourd'hui, le dernier commit et les signaux du worktree.

### 2.2 Statut effectif et dépendances (D-11)
- **RG-10** Le statut effectif d'une issue suit la règle existante (le plus avancé du statut local et de celui de son fichier sur la branche retenue ; fichier absent ou illisible sur la branche, statut inconnu d'un côté : le statut local), que la branche soit déclarée ou déduite. Le fichier lu sur la branche est toujours **le même chemin que le fichier local de l'issue**, jamais un chemin tiré du nom de la branche. Un statut lu sur une branche n'est retenu que s'il figure dans le cycle.
- **RG-11** Une dépendance est **levée** dès que son statut effectif est `Fait`, même sur une branche non fusionnée. Une dépendance dont l'identifiant n'existe pas, ou dont le statut effectif n'est pas `Fait`, n'est pas levée.
- **RG-12** Une issue `À faire` (statut effectif) dont une dépendance n'est pas levée est **bloquée** (marqueur `bloquée`, comme aujourd'hui).
- **RG-13** Une issue `À faire` dont **toutes** les dépendances sont levées, dont au moins une est `Fait` uniquement sur sa branche (statut local différent de `Fait`), porte la mention `empilée sur <branche>` (plusieurs : noms de branche séparés par `, `, sans doublon, ordre des dépendances) et **non** `bloquée`. Si toutes les dépendances sont `Fait` localement, aucune des deux mentions.
- **RG-14** `scripts/etat-issues.sh --prochaine` et la ligne « Prochaine issue prête » du dashboard (et son marqueur sur la carte) appliquent la même règle : la première issue, dans l'ordre des fichiers, dont le statut effectif est `À faire` et dont toutes les dépendances sont levées (RG-11). Seul changement pour `etat-issues.sh` : les dépendances comptent sur leur statut effectif, et non plus local (Q-11 : décision retenue provisoirement). Sa sortie (identifiant, code 0 ; code 1 sans issue prête) est inchangée par ailleurs.
- **RG-15** Le tableau de `etat-issues.sh` (sans option) garde ses colonnes. La colonne `Statut` et le filtre `--statut` restent sur le statut local (Q-11). La colonne `Branche` affiche le champ s'il est rempli (inchangé) ; sinon `<nom> (déduite)` pour une branche déduite, `ambiguë : <liste>` pour une ambiguïté, vide sinon.

### 2.3 Avancement des besoins (D-12)
- **RG-16** Une issue appartient à un besoin quand son champ `besoin:` est égal à l'identifiant du besoin (texte littéral). La carte d'un besoin ayant au moins une issue affiche une ligne d'avancement : `<f>/<n> Fait` suivi, pour chaque autre statut effectif présent, de ` · <k> <statut>` (cycle d'abord : `À faire`, `En cours`, `En revue`, puis les statuts hors cycle dans l'ordre d'apparition ; les statuts à zéro sont omis). Exemple : `5/6 Fait · 1 En cours` ; `0/2 Fait · 2 À faire`. Un besoin sans issue n'affiche **aucun** compte. Une issue sans `besoin:`, ou dont le besoin est absent du backlog, n'apparaît sur aucune carte de besoin.
- **RG-17 (divergence)** Le statut du backlog reste affiché tel quel. S'il diverge des statuts effectifs, la carte ajoute `à vérifier : <motif>`, avec exactement ces motifs :

| Statut du backlog | Divergence si | Motif |
|---|---|---|
| `À faire`, `En clarification`, `Spécifié` | au moins une issue `En cours`, `En revue` ou `Fait` | `des issues sont déjà démarrées` |
| `En cours` | toutes les issues `Fait` | `toutes les issues sont Fait` |
| `En cours`, `En revue` | toutes les issues `À faire` | `aucune issue démarrée` |
| `Fait` | au moins une issue qui n'est pas `Fait` (statut hors cycle compris, Q-13) | `1 issue non Fait` / `<k> issues non Fait` |

  Aucun motif dans les autres cas, notamment `En revue` avec toutes les issues `Fait` (en attente de fusion) et un statut du backlog hors cycle (compte seul).
- **RG-18** Le dashboard ne modifie jamais `backlog.md` ni aucun fichier d'issue : sa seule écriture est son fichier de sortie.

### 2.4 Cohérence des encarts et des signaux (D-16)
- **RG-19** Les signaux Git d'un worktree (fichiers non commités, activité) sont rattachés à l'issue par sa **branche retenue**, déclarée ou déduite, sur la carte et dans l'encart « En cours ».
- **RG-20** L'encart « Autres travaux » exclut les worktrees dont la branche est la branche **retenue** d'une issue (déclarée ou déduite). Une branche ambiguë ou non retenue (RG-04, RG-06, RG-07) y figure. `develop`, `main` et HEAD détaché restent exclus.

### 2.5 Coût (D-17)
- **RG-21** Une génération du dashboard fait **au plus un appel Git de plus qu'avant**, quel que soit le nombre d'issues et de branches : la liste des branches locales est lue **une seule fois** (jamais une recherche par issue), y compris pour la prochaine issue prête. Aucun appel supplémentaire si aucune issue n'a `branche:` vide. `etat-issues.sh`, seul, fait au plus un appel de plus qu'avant.

### 2.6 Compatibilité, documentation, version (D-13, D-14, D-15)
- **RG-22** Hors périmètre : remplir `branche:` à la création des issues (F-06), verdict et tour de revue sur la carte (F-03), regroupement des `Abandonnée` (F-04), démarrage automatique de la boucle, alerte « page périmée », modification de `scripts/worktree-issue.sh`.
- **RG-23** Aucune régression hors des règles ci-dessus : mêmes pages, mêmes sorties, mêmes codes pour un dépôt où chaque issue a `branche:` rempli ou ne correspond à aucune branche, et sans issue liée à un besoin sauf la ligne d'avancement. Seuls les cas existants qui assertent l'ancienne règle « une dépendance ne compte Fait que localement » sont modifiés.
- **RG-24** Documentation : en-tête de `scripts/dashboard.sh` (règle de rattachement, de dépendance, avancement des besoins), documentation de `etat-issues.sh`, `factory/README.md` (section dashboard : rattachement par convention, `empilée sur`, `à vérifier`, et **rappel que `--boucle` doit tourner pour que la page reste à jour**), `AGENTS.md` (ligne `scripts/dashboard.sh`) et tout texte qui décrit le champ `branche:` comme seule source.
- **RG-25** Version : la **version suivante libre** à la livraison, fixée dans la dernière issue ; `CHANGELOG.md` a une entrée qui décrit le changement et la migration « remplacer `factory/` » (sans action requise : un dépôt sans changement se comporte comme avant ; les branches se rattachent d'elles-mêmes). Pas d'ADR (D-15).

## 3. Modèle de données (point de vue métier)
- **Issue** : `id`, `statut`, `depend_de`, `besoin`, `branche` (vide ou nom), plus la **branche retenue** (déclarée, déduite ou aucune) et le **statut effectif**.
- **Rattachement** : déclaré | déduit | ambigu (liste triée) | aucun.
- **Avancement d'un besoin** : nombre d'issues par statut effectif ; divergence = motif ou aucune.

## 4. Contrats externes
- `scripts/dashboard.sh` : options, codes (0, 64) et sortie inchangés ; contenu de la page enrichi (RG-09, RG-13, RG-16, RG-17).
- `scripts/etat-issues.sh` : options inchangées ; `--prochaine` selon RG-14 ; colonne `Branche` selon RG-15.
- Textes visibles (contrats) : `branche : <nom> (déduite)`, `branche ambiguë : <liste>`, `empilée sur <liste>`, `bloquée`, `<f>/<n> Fait · …`, `à vérifier : <motif>`.
- Sources lues : en-têtes de `docs/issues/`, `backlog.md`, liste des branches locales, fichier d'issue sur la branche retenue.

## 5. Critères d'acceptation
Identifiants au format `CA-xx` (convention de `scripts/couverture-prd.sh`). Les tests créent des dépôts Git jetables (copie des scripts, `git init`, branches et fichiers d'issue de fixtures), avec un `git` de comptage placé en tête de `PATH` quand un critère mesure les appels. Le nom d'un test est de la forme `ca01_…`.

- **CA-01** Given un dépôt dont l'issue `002-02` a `branche:` vide et une branche locale `feat/002-02-x` où son fichier est `Fait` (local `À faire`), When on génère le dashboard, Then la carte est dans la colonne `Fait`, affiche `branche : feat/002-02-x (déduite)` et le dernier commit de cette branche.
- **CA-02** Given les branches `fix/`, `docs/`, `refactor/`, `test/`, `build/`, `hotfix/` et `zz/` suivies de `<id>-x` (une par issue), Then chacune est rattachée à son issue (aucune restriction de type).
- **CA-03** Given `branche: feat/a` rempli (existante) et une autre branche `feat/<id>-b`, Then `feat/a` est la branche retenue, sans « (déduite) » ni ambiguïté ; Given une branche déclarée par l'issue A et dont le nom suit `<type>/<id de B>-…`, Then elle n'est pas déduite pour B.
- **CA-04** Given `branche:` rempli avec une branche absente ou invalide (supprimée après fusion, `-x`, `a..b`), When on génère, Then statut local seul, aucune déduction, aucun signalement ; Given une branche déduite supprimée entre deux générations, Then l'issue retrouve son statut local sans message.
- **CA-05** Given `feat/002-02-x` et `fix/002-02-y` pour la même issue, Then aucune n'est retenue (statut local, ni dernier commit ni signal) et la carte affiche `branche ambiguë : feat/002-02-x, fix/002-02-y` (tri par ordre d'octets).
- **CA-06** Given les issues `002-1` et `002-10` et les branches `feat/002-10-x`, `feat/002-1`, `feat/002-1-`, `feat/002-11-x`, Then `feat/002-10-x` est celle de `002-10` seulement et `002-1` n'a aucune branche ; Given `feat/002-1-x`, Then elle est celle de `002-1`.
- **CA-07** Given les noms `002-02-x` (sans type), `a/b/002-02-x` (deux segments), `refs/tags/…` et une étiquette `feat/002-02-t`, une branche de suivi distant `origin/feat/002-02-r`, Then aucun n'est retenu ; Given la branche locale `origin/002-02-x`, Then elle est retenue (le type est un segment quelconque).
- **CA-08** Given des issues dont l'`id:` est absent, vide, `0*`, `002.02`, `a b`, `.*`, ou partagé par deux fichiers, et des branches `feat/002-02-x`, `feat/002x02-x`, `feat/0-x`, Then aucune déduction n'a lieu pour elles, sans erreur ni message d'exécution, et le reste de la page est généré.
- **CA-09** Given les issues `002-01` et `002-01-b` et la branche `feat/002-01-b-x`, Then elle est retenue par `002-01-b` seulement ; la branche `feat/002-01-x` reste celle de `002-01`.
- **CA-10** Given une branche retenue (déclarée ou déduite), Then le statut effectif est : le plus avancé du local et de celui de la branche ; le local si la branche est en retard (local `Fait`, branche `À faire`) ; le local si le fichier d'issue est absent sur la branche ; le local si le statut de la branche est hors cycle (`Abandonnée`, texte libre, vide) ; le local si le statut local est hors cycle.
- **CA-11** Given `002-06` (`À faire`) dépendant de `002-05` (`Fait` seulement sur sa branche `feat/002-05-x`, déclarée ou déduite), Then sa carte n'est pas `bloquée`, affiche `empilée sur feat/002-05-x`, et plusieurs dépendances de ce type listent leurs branches séparées par `, ` ; Given toutes les dépendances `Fait` en local, Then ni `empilée` ni `bloquée`.
- **CA-12** Given une dépendance `À faire`, `En cours`, `En revue`, hors cycle, ou d'identifiant inexistant, ou `Fait` mais non retenue pour cause d'ambiguïté (statut local autre que `Fait`), Then l'issue dépendante `À faire` est `bloquée`, sans `empilée` ; Given deux dépendances dont une seulement est levée, Then `bloquée`.
- **CA-13** Given les fixtures de CA-11 et CA-12, When on lance `scripts/etat-issues.sh --prochaine`, Then il affiche la première issue `À faire` dont toutes les dépendances sont levées (par exemple `002-06` après CA-11), code 0 ; une issue `Fait` sur sa branche n'est pas rendue ; sans issue prête : code 1, rien affiché.
- **CA-14** Given les mêmes fixtures, Then l'identifiant de « Prochaine issue prête » du dashboard et la carte marquée `prochaine` sont ceux de `etat-issues.sh --prochaine` (et « Aucune issue prête. » quand il rend le code 1).
- **CA-15** Given une issue à branche déduite, déclarée, ambiguë et sans branche, When on lance `scripts/etat-issues.sh`, Then la colonne `Branche` vaut respectivement `<nom> (déduite)`, le champ tel quel, `ambiguë : <liste>`, vide ; la colonne `Statut` et le filtre `--statut` restent sur le statut local ; les autres colonnes et le format du tableau sont inchangés.
- **CA-16** Given le besoin `F-05` avec 6 issues effectivement 5 `Fait` et 1 `En cours`, Then sa carte affiche `5/6 Fait · 1 En cours` ; avec 2 `À faire` : `0/2 Fait · 2 À faire` ; avec 1 `En revue`, 1 `Fait` et 1 `Abandonnée` : `1/3 Fait · 1 En revue · 1 Abandonnée` ; les statuts comptent sur le statut **effectif** (branche comprise).
- **CA-17** Given un besoin sans aucune issue, Then sa carte n'a aucun compte ni « à vérifier » ; Given une issue sans `besoin:` ou liée à un besoin absent du backlog, Then elle n'est comptée sur aucune carte et la page est générée ; Given `F-1` et `F-10`, Then les issues de l'un ne sont pas comptées pour l'autre.
- **CA-18** Given chaque ligne du tableau de RG-17 (besoin `En cours` avec toutes les issues `Fait` ; `En cours` ou `En revue` avec toutes `À faire` ; `Fait` avec 1 puis 2 issues non `Fait`, dont une hors cycle ; `Spécifié` avec une issue `En cours`), Then la carte porte `à vérifier : ` suivi du motif exact, et le statut du backlog reste affiché inchangé.
- **CA-19** Given `En cours` avec une issue `En cours`, `En revue` avec toutes `Fait`, `Fait` avec toutes `Fait`, `Spécifié` avec toutes `À faire`, et un statut du backlog hors cycle, Then aucune mention `à vérifier`.
- **CA-20** Given un dépôt de fixtures, When on génère le dashboard (une fois, puis en `--boucle`, arrêtée après deux générations), Then `backlog.md` et chaque fichier de `docs/issues/` sont identiques octet pour octet (somme de contrôle) et le seul fichier écrit est la sortie.
- **CA-21** Given un worktree sur `feat/002-02-x` retenue par `002-02` par déduction et un autre sur `feat/zz-autre`, Then « Autres travaux » liste seulement `feat/zz-autre` ; Given une branche ambiguë portée par un worktree, Then elle figure dans « Autres travaux » ; `develop` et `main` restent exclus.
- **CA-22** Given un worktree sur une branche déduite avec 2 fichiers non commités, Then la carte de l'issue et l'encart « En cours » affichent `2 fichiers non commités · activité il y a …` ; Given une branche ambiguë, Then aucun signal sur la carte.
- **CA-23** Given deux dépôts jetables identiques à la différence des champs `branche:` (A : remplis avec la branche que B déduit ; B : vides) avec 3 puis 12 issues et 1 puis 50 branches locales, When on génère avec un `git` qui compte ses appels, Then (appels de B) moins (appels de A) est ≤ 1 dans les quatre cas, et il y a exactement un appel de listage des branches dans B ; Given aucune issue à `branche:` vide, Then aucun appel de listage ; Given `etat-issues.sh --prochaine` et le tableau, seuls, la différence est ≤ 1.
- **CA-24** Given un dépôt dont chaque issue a `branche:` rempli (existante) ou sans correspondance, et sans liaison de besoin, When on compare la page (hors date et durées) et les sorties de `etat-issues.sh` avec celles produites avant la livraison sur les mêmes fixtures, Then elles sont identiques ; les cas existants de `factory/scripts/tests/run.sh` passent, seuls ceux de l'ancienne règle de dépendance sont réécrits.
- **CA-25** Given `factory/scripts/tests/run.sh`, When on le lance, Then les cas de CA-01 à CA-24 et CS-01 à CS-06 y figurent, leur nom contient l'identifiant (`ca01_…`), ils passent avec des dépôts Git jetables, `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM` et `HOME` isolés, sans réseau ni dépôt réel.
- **CA-26** Given la documentation (RG-24), When on la lit après livraison, Then elle décrit le rattachement par convention (type quelconque, identifiant suivi d'un tiret, champ rempli prioritaire, ambiguïté), la dépendance levée sur branche (`empilée sur`), l'avancement et `à vérifier`, et rappelle que `--boucle` doit tourner pour que la page reste à jour.
- **CA-27** Given le dépôt après livraison, When on lit `factory/VERSION`, `CHANGELOG.md` et `factory/README.md`, Then la version est la suivante libre (supérieure à toute version déjà livrée), le CHANGELOG a une entrée qui décrit le changement et la migration « remplacer `factory/` » (sans action requise), et le README mentionne la nouveauté.

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : intégrité de ce que l'utilisateur lit (un faux statut `Fait` fait lever une dépendance à tort) ; sûreté du poste (le dashboard tourne en boucle, sans surveillance).
- **Acteurs** : un dépôt, une PR ou un collaborateur qui crée une branche locale ou un fichier d'issue hostile ; un agent qui nomme une branche.
- **Points d'entrée** : noms de branches locales (hostiles : `<`, `>`, `"`, `'`, `&`, `$()`, `;`, `|`, backtick, très longs), champ `branche:`, champ `id:`, fichier d'issue présent sur une branche (contenu, lien symbolique).
- Un nom de branche et le contenu d'un fichier lu sur une branche sont des **données non fiables** : lus comme du texte, jamais exécutés, interprétés ni passés à un shell.

### Catégories
- **A01 Contrôle d'accès / traversée** : lecture seule, uniquement des refs locales ; le fichier lu sur une branche est le chemin de l'issue elle-même, jamais construit depuis le nom de la branche ni suivi comme lien symbolique (CS-06) ; rien hors des branches locales (RG-03).
- **A02, A07, A10** : non applicables (aucun secret, aucune identité, aucune requête sortante).
- **A03 Injection** : sortie HTML échappée pour tout nom de branche et tout texte tiré des fichiers (CS-01) ; aucun nom de branche ou d'identifiant dans une commande construite, une évaluation ou un motif (CS-02, RG-08) ; nom toujours préfixé `refs/heads/` (CS-03).
- **A04 Conception** : échec sûr : tout ce qui est ambigu, invalide ou hors cycle retombe sur le statut local (RG-01, RG-04, RG-07, RG-10) ; le dashboard n'écrit jamais dans le backlog (RG-18) ; bornes (RG-08, CS-05).
- **A05 Configuration** : défauts inchangés ; aucun nouveau réglage ; pas de trace dans la page.
- **A06** : aucune dépendance ajoutée.
- **A08 Intégrité** : une branche locale peut être créée par quiconque a le dépôt et faire passer une issue `Fait` ; le dashboard est un indicateur, la fusion et les vérifications de fin d'issue restent les filets.
- **A09 Journalisation** : pas de journal ; un nom invalide est ignoré sans message exploitable.

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| Nom de branche local | valide pour Git, au plus 200 caractères, forme `<type>/<id>-<suffixe>` | ignoré |
| `id:` (issue) | non vide, `[A-Za-z0-9._-]+`, unique | pas de déduction |
| `branche:` (champ) | nom de branche local valide et existant, préfixé `refs/heads/` | statut local |
| Statut lu sur une branche | un des 4 statuts du cycle | statut local |

### Critères d'acceptation de sécurité
- **CS-01** Given des branches `feat/002-02-<img-src=x-onerror=alert(1)>`, `feat/002-02-"><script>alert(1)</script>`, `…&amp;'` (déduite, ambiguë, dans `empilée sur`, dans « Autres travaux », et un `branche:` de même forme), When on génère, Then aucune balise ni attribut issu d'un nom n'apparaît brut dans la page : `&`, `<`, `>`, `"` et `'` sont échappés partout où un nom est écrit.
- **CS-02** Given des branches `feat/002-02-$(touch${IFS}marque)`, `feat/002-02-;touch${IFS}marque`, ``feat/002-02-`touch${IFS}marque` ``, `feat/002-02-|a&&b`, des identifiants `$(…)` ou `a;b`, When on génère le dashboard et on lance `etat-issues.sh`, Then aucune commande du contenu n'est exécutée (le fichier `marque` n'existe pas) et les noms valides sont traités comme du texte.
- **CS-03** Given un `branche:` valant `-x`, `--help`, `HEAD`, `develop^`, `main..develop`, `@{1}` ou le nom d'une étiquette sans branche du même nom, When on génère, Then aucun de ces noms n'est lu comme une option, une révision ou une étiquette : statut local, aucune branche retenue. Given une étiquette et une branche de même nom `feat/002-02-x`, Then c'est la branche qui est lue.
- **CS-04** Given n'importe quelle entrée, When on génère ou lance `etat-issues.sh`, Then les refs (liste et valeurs), l'index, l'arbre de travail et la liste des worktrees sont identiques avant et après, aucune commande n'a pris de verrou d'index.
- **CS-05** Given 500 branches locales (dont une de plus de 200 caractères correspondant à une issue) et 12 issues, When on génère, Then la page est produite, la branche trop longue est ignorée, et le listage reste unique (CA-23).
- **CS-06** Given un fichier d'issue qui, sur la branche, est un lien symbolique vers un fichier hors dépôt contenant `statut: Fait`, ou un fichier de très grande taille, ou un en-tête sans `---`, Then le statut effectif est le statut local, le contenu du fichier ciblé n'apparaît nulle part dans la page, et aucun fichier hors du dépôt n'est lu.

## 7. Décisions reflétées
| Q | Décision | Reflété dans |
|---|---|---|
| Q-01 | D-10 : rattachement par convention `<type>/<id>-…`, champ rempli prioritaire, ambiguïté sans choix | RG-01 à RG-05, CA-01 à CA-05, CA-15 |
| Q-02 | D-11 : dépendance levée dès `Fait` sur branche ; `empilée sur` ; prochaine issue cohérente | RG-11 à RG-14, CA-11 à CA-14 |
| Q-03 | D-12 : avancement par statut effectif et `à vérifier`, backlog jamais modifié | RG-16 à RG-18, CA-16 à CA-20 |
| Q-04 | D-13 : hors périmètre ; rappel `--boucle` dans le README | RG-22, RG-24, CA-26 |
| Q-05 | D-14 : version suivante libre, CHANGELOG, migration | RG-25, CA-27 |
| Q-06 | D-15 : pas d'ADR | RG-25 |
| Q-07 | D-16 : branche supprimée = statut local, « (déduite) », nom non fiable | RG-01, RG-08, RG-09, CA-04, CS-01 à CS-03 |
| Q-08 | D-17 : un seul appel Git de listage, plafond ≤ 1 appel de plus, compteur dans un test | RG-21, CA-23, CS-05 |

## 8. Questions
Réponses de l'utilisateur du 2026-11-17 : les cinq choix proposés (recommandation (a) ou 200) sont confirmés, tels qu'appliqués dans les règles ci-dessus.

- **Q-09** (RG-06) Nom de branche commençant par deux identifiants (`002-01` et `002-01-b`) : l'identifiant le plus long l'emporte. Confirmé.
- **Q-10** (RG-07) Identifiant partagé par plusieurs issues : aucune déduction pour elles. Confirmé.
- **Q-11** (RG-14, RG-15) `etat-issues.sh` : `--prochaine` en statut effectif des dépendances ; le tableau garde le statut local, seule la colonne `Branche` est enrichie. Confirmé.
- **Q-12** (RG-08) Nom de branche : 200 caractères au plus, au-delà ignoré. Confirmé.
- **Q-13** (RG-17) Statuts hors cycle (`Abandonnée`, F-04) : comptés, traités comme « non Fait » pour un besoin `Fait`, jusqu'à F-04. Confirmé.

## QUESTIONS : aucune

## 9. Découpage en issues (indicatif)
Chaque critère est couvert par exactement une issue ; dépendances : 01, puis 02, puis 03 et 04 (indépendantes entre elles), 05 en dernier.

| Issue | Contenu | Critères |
|---|---|---|
| 003-01 | Rattachement par convention (déduction, ambiguïté, identifiants, bornes, noms hostiles) | CA-01 à CA-09, CS-03, CS-05 |
| 003-02 | Statut effectif, dépendance levée, `empilée sur`, prochaine issue prête (dashboard et `etat-issues.sh`), tableau | CA-10 à CA-15, CS-06 |
| 003-03 | Signaux de worktree, « Autres travaux », sorties échappées et sûres, lecture seule | CA-21, CA-22, CS-01, CS-02, CS-04 |
| 003-04 | Avancement des besoins et divergence, backlog intact | CA-16 à CA-20 |
| 003-05 | Coût mesuré, non-régression, tests regroupés, documentation, version | CA-23 à CA-27 |
