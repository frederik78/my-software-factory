# PRD 004 : les statuts des besoins et des issues suivent une machine à états définie une seule fois et contrôlée

## En clair
*Lecture sans contexte : ce bloc résume le document ; les règles et critères qui suivent sont destinés aux tests.*

**Le problème.** Les statuts du travail (besoins dans `backlog.md`, issues dans `docs/issues/`) sont écrits à la main et leurs règles de passage ne sont que de la prose (`AGENTS.md`, skill `deliver`). Les listes de statuts sont recopiées dans plusieurs scripts (6 statuts de besoin dans le dashboard, 4 statuts d'issue dans la bibliothèque des issues). Rien ne vérifie qu'un statut correspond à la réalité. Deux oublis réels l'ont montré : un besoin resté « Spécifié » alors que sa livraison avait démarré, un autre resté « En cours » alors que toutes ses issues étaient fusionnées.

**Ce que ce besoin change**
1. **Une table unique.** Les statuts de chaque entité et leurs transitions légales (avec le déclencheur et la preuve de chacune) sont définis une fois. Le dashboard, la bibliothèque des issues, `AGENTS.md` et la skill `deliver` s'y réfèrent au lieu de la recopier. Un nouveau statut `Abandonnée` entre dans les deux machines.
2. **Un contrôle en lecture seule : `scripts/statuts.sh`.** Il lit `backlog.md`, `docs/issues/`, les fichiers de revue et Git, puis signale des **erreurs** (le statut contredit la réalité : code de sortie 1) et des **avis** (une preuve manque, à regarder : code 0). Il vérifie l'**état courant** (un statut est-il cohérent avec ses preuves ?), jamais l'historique. Il ne modifie jamais `backlog.md` ni une issue.
3. **Le résultat est visible.** Le dashboard affiche les erreurs et les avis ; `/deliver` lance le contrôle à chaque changement de statut.
4. **Sûr, sans surprise.** Aucune valeur lue dans un fichier n'est évaluée ; la sortie est neutralisée des caractères de contrôle et échappée en HTML dans le dashboard ; le nombre d'appels Git ne dépend pas du nombre d'issues.
5. **Nettoyage final.** Une fois tout livré, les anciennes listes de statuts, les valeurs de statut écrites en dur, les règles de transition répétées en prose et les tests qui ne vérifiaient que cette duplication sont supprimés, avec un garde-fou qui empêche leur retour. Rien ne change pour l'utilisateur.

**Hors de ce besoin** : regrouper les issues `Abandonnée` dans leur propre colonne du dashboard (F-04), afficher le verdict de revue (F-03), corriger automatiquement un statut, détecter une transition illégale dans l'historique Git, détecter les dépendances circulaires, juger la qualité d'une raison d'abandon, migrer des données.

**Comment lire la suite** : section 2, les tables de statuts et de transitions, les règles (RG-xx) et la liste complète des messages ; section 5, les 47 critères (« Given… When… Then… » : une situation, une action, un résultat) ; section 7, les décisions déjà prises avec l'utilisateur ; section 8, les points à trancher ; section 9, le découpage en 6 issues.

Besoin : F-09 (`backlog.md`). Décisions de cadrage reprises telles quelles : D-18 à D-26 ; D-12 (le statut d'un besoin reste décidé par l'utilisateur) et D-24 (F-09 après F-08) en découlent. Ce PRD ne les rouvre pas. D-26 (retrait du code mort, ajoutée par l'utilisateur) est reprise ici ; `backlog.md` la consignera.
Le « produit » est la factory elle-même (scripts bash, Markdown). Les noms de commande, de message et de fichier visibles par les utilisateurs sont des contrats ; aucune structure de code n'est décrite.
Préalable : le PRD 003 (F-08) est livré : le contrôle raisonne sur le **statut effectif** d'une issue (le plus avancé du statut local et de celui de son fichier sur sa branche retenue, branche déclarée ou déduite) et sur la **branche retenue**, tels que définis par ce PRD (RG-01 à RG-10).

## 1. Contexte et besoin

### Acteurs
- **Utilisateur** : décide des statuts de besoin (`backlog.md` lui appartient), lit le dashboard, fusionne dans `develop`.
- **Session orchestrateur** et **developer** : changent les statuts d'issue et de besoin pendant `/deliver` ; lancent le contrôle.
- **Mainteneur de la factory** : ses tests sont en bash (`factory/scripts/tests/run.sh`).

### Existant (observé)
- **Issues** (`docs/issues/NNN-NN-*.md`) : en-tête YAML avec `id`, `besoin`, `statut`, `depend_de`, `prd`, `criteres`, `branche`, `commits`, `revue`, puis des sections dont `## Notes`. La bibliothèque des issues connaît 4 statuts dans l'ordre `À faire` < `En cours` < `En revue` < `Fait`.
- **Besoins** (tableau « Besoins fonctionnels » de `backlog.md`, colonnes `ID | Besoin | Priorité | Statut | PRD | Décisions`) : le dashboard connaît 6 statuts (`À faire`, `En clarification`, `Spécifié`, `En cours`, `En revue`, `Fait`), une colonne par statut plus « (autre) » pour tout statut inconnu. La ligne « Statuts » de `backlog.md` en donne la même liste.
- **Transitions** : prose dans `AGENTS.md` (« Séquence d'un besoin »), le modèle `factory/templates/AGENTS.md` et la skill `deliver` (l'issue passe `En cours` au départ, `En revue` avant la première relecture, `En cours` pendant les corrections, `Fait` après `FIN-ISSUE OK`). Aucun contrôle.
- **Preuves d'une issue terminée**, telles qu'elles existent dans le dépôt : un fichier de revue `docs/reviews/<id>.md` dont la dernière ligne est le verdict (`APPROUVÉ`) ; une ligne `FIN-ISSUE OK <id> <commit> : …` recopiée dans les Notes ; le champ `commits:` ; le champ `revue:`. Le champ `revue:` n'a **pas de forme unique** : vide (002-01, 002-03), `docs/reviews/003-01.md (APPROUVÉ, itération 1/3)`, `APPROUVÉ (itération 2 sur 2, docs/reviews/002-04.md)`. Le contrôle doit donc retrouver le chemin dans le texte du champ.
- Les issues terminées avant ce besoin n'ont pas toutes ces preuves (002-01 et 002-03 : `revue:` vide).
- Le dashboard affiche tout statut hors cycle dans « (autre) ».
- `scripts/fin-issue.sh` contrôle la fin d'une issue (arbre propre, build, critères, tests ignorés) ; il ne lit pas les statuts de besoin.

### Besoin
Définir chaque machine à états une seule fois, contrôler qu'un statut est cohérent avec ses preuves, afficher le résultat, et pouvoir ainsi repérer à temps un statut oublié ou prématuré, sans jamais écrire dans `backlog.md` ni dans une issue ; puis retirer tout ce que cette table rend inutile.

## 2. Exigences fonctionnelles et règles de gestion

Vocabulaire : **issue démarrée** = statut effectif `En cours`, `En revue` ou `Fait` ; **issue terminée** = statut effectif `Fait` ; **fusionnée** = voir RG-14 ; **objet** d'un message = l'issue, le besoin ou le fichier visé.

### 2.1 Les tables (D-18, D-19, D-20, D-24)

**Statuts d'une issue** : `À faire`, `En cours`, `En revue`, `Fait` (cycle, dans cet ordre), `Abandonnée` (hors cycle, final). `Fait` est final : un défaut trouvé plus tard fait une nouvelle issue.

**Transitions légales d'une issue** (toute autre est illégale : `À faire` vers `En revue` ou `Fait`, `En cours` vers `Fait`, tout départ de `Fait` ou d'`Abandonnée`, tout retour vers `À faire`)

| De | Vers | Déclencheur | Preuve exigée | Vérifiée par le contrôle |
|---|---|---|---|---|
| `À faire` | `En cours` | `/deliver` démarre l'issue (commit `docs: issue <id> en cours` sur sa branche) | une branche retenue pour l'issue | oui, avis A08 |
| `En cours` | `En revue` | le developer a livré, vérification de la session faite, avant la première relecture | la branche porte les commits de code ; le fichier de revue existe ou va être créé | fichier de revue : oui, avis A07 |
| `En revue` | `En cours` | la revue demande des corrections (BLOQUANT ou IMPORTANT) | constats ouverts dans le fichier de revue | non |
| `En revue` | `Fait` | `/deliver` §5 « définition de fini », après `FIN-ISSUE OK` | D-22 : champ `revue:` non vide ; fichier de revue dont la dernière ligne est `APPROUVÉ` ; ligne `FIN-ISSUE OK <id> …` dans les Notes ; au moins un commit | oui, avis A01 à A06 |
| `À faire`, `En cours`, `En revue` | `Abandonnée` | décision de l'utilisateur | raison écrite dans les Notes de l'issue | oui, erreur E13 |

**Statuts d'un besoin** : `À faire`, `En clarification`, `Spécifié`, `En cours`, `En revue`, `Fait` (cycle, dans cet ordre), `Abandonnée` (hors cycle, final).

**Transitions légales d'un besoin** (toute autre est illégale ; un retour en arrière n'a lieu que sur décision de l'utilisateur, consignée dans la colonne Décisions ; le contrôle voit l'état, pas la décision : un retour en arrière incompatible avec les issues reste signalé)

| De | Vers | Déclencheur | Preuve exigée | Vérifiée par le contrôle |
|---|---|---|---|---|
| `À faire` | `En clarification` | l'orchestrateur ouvre le cadrage | aucune | non |
| `En clarification` | `Spécifié` | l'utilisateur valide le PRD | colonne PRD renseignée, fichier présent | oui, erreur E06 |
| `Spécifié` | `En cours` | la première issue du besoin passe `En cours` | au moins une issue démarrée | oui, erreur E07 |
| `En cours` | `En revue` | toutes les issues sont `Fait` (les `Abandonnée` ne comptent pas, au moins une `Fait`) | idem | oui, erreurs E07, avis A12 |
| `En revue` | `Fait` | l'utilisateur a fusionné : la branche de chaque issue `Fait` est fusionnée dans `develop` | lu dans Git (RG-14) | oui, erreurs E07, E08 |
| tout statut sauf `Fait` | `Abandonnée` | décision de l'utilisateur | raison écrite dans la colonne Décisions | oui, erreur E09 |

- **RG-01 (source unique)** Les statuts et les transitions des deux tables ci-dessus sont définis en **un seul endroit** de la factory. `scripts/dashboard.sh`, la bibliothèque des issues, `scripts/etat-issues.sh`, `scripts/statuts.sh`, `AGENTS.md`, `factory/templates/AGENTS.md` et la skill `deliver` s'y réfèrent et ne recopient aucune liste. Ajouter un statut dans la table suffit pour que le dashboard (colonne), l'ordre du cycle et le contrôle le connaissent. `scripts/statuts.sh --table` affiche les deux tables (statuts dans l'ordre, puis chaque transition : de, vers, déclencheur, preuve) ; code 0.
- **RG-02 (`Abandonnée` n'est pas dans le cycle)** `Abandonnée` est hors cycle : le statut effectif d'une issue (PRD 003) ne change pas (un statut hors cycle d'un côté donne le statut local). Le dashboard garde pour elle la colonne « (autre) » jusqu'à F-04 (D-20) ; sa mise en page n'est pas modifiée par ce besoin.

### 2.2 Ce que le contrôle lit et comment (D-21, D-23)
- **RG-03 (état courant)** Le contrôle ne lit que l'état présent du dossier où il tourne : `backlog.md`, `docs/issues/`, `docs/reviews/`, `docs/prd/`, les branches locales et leurs fichiers d'issue, `develop`. Il ne lit jamais l'historique des statuts. Il n'écrit nulle part (RG-24).
- **RG-04 (besoins)** Il lit le premier tableau de `backlog.md` dont l'en-tête contient les colonnes `ID`, `Statut` et `PRD`. Les colonnes sont repérées par leur nom d'en-tête ; les cellules sont lues sans espaces de bord. Le tableau des besoins non fonctionnels (sans colonne PRD) est hors périmètre.
- **RG-05 (issues et appartenance)** Une issue appartient au besoin dont l'identifiant est égal (texte littéral) à son champ `besoin:`, quel que soit son champ `prd:`. Les issues viennent de `docs/issues/` (hors modèle et README, comme `etat-issues.sh`).
- **RG-06 (comparaison exacte)** Les statuts, le verdict et `FIN-ISSUE OK` sont comparés **octet pour octet, sensibles à la casse et aux accents**, après retrait des espaces de bord et des guillemets de bord du champ (comme la lecture actuelle des en-têtes). `fait`, `FAIT`, `Fini`, un texte vide, `A faire` (sans accent) et un `À faire` en forme décomposée (lettre puis accent séparé) sont des statuts **inconnus** : erreur E05 ou E10, jamais de correction ni de suggestion automatique (D-23).
- **RG-07 (statut effectif)** Les règles sur les issues d'un besoin (démarrée, terminée, tous `Fait`) utilisent le **statut effectif** (PRD 003) ; les preuves d'une issue `Fait` (RG-10) ne sont contrôlées que quand son statut **local** est `Fait` (son fichier est présent dans le dossier de travail) : un `Fait` visible seulement sur sa branche est compté comme terminé, ses preuves sont contrôlées là où il sera fusionné.
- **RG-08 (besoin sans PRD)** Un besoin `Spécifié`, `En cours`, `En revue` ou `Fait` doit avoir au moins un PRD : la colonne PRD contient au moins un chemin de la forme `docs/prd/<nom>.md` (plusieurs permis, repérés dans le texte de la cellule) et **chaque** chemin désigne un fichier présent. Sinon erreur E06. `À faire`, `En clarification` et `Abandonnée` n'exigent rien.
- **RG-09 (issue sans besoin connu)** Une issue dont `besoin:` est vide, n'est pas l'identifiant d'une ligne du tableau, ou contient plusieurs valeurs : erreur E12. Elle n'est comptée pour aucun besoin.

### 2.3 Preuves d'une issue (D-22, D-23)
- **RG-10 (issue `Fait`, statut local)** Quatre preuves, chacune signalée par un **avis** si elle manque, jamais par une erreur : (a) champ `revue:` non vide (A01) ; (b) un fichier de revue lisible (A02) dont la dernière ligne non vide, une fois retirés le retour chariot et les espaces de fin, est exactement `APPROUVÉ` (A03) ; (c) dans la section `## Notes`, une ligne contenant `FIN-ISSUE OK <id> ` (texte littéral, `<id>` = identifiant exact de l'issue, suivi d'une espace) (A04) ; (d) champ `commits:` non vide (A05) dont chaque identifiant existe dans le dépôt (A06). Une issue terminée avant ce besoin sans ces preuves n'est donc jamais une erreur ; le code de sortie 1 ne vient que des erreurs.
- **RG-11 (chemin du fichier de revue)** Le chemin est la **première** occurrence dans le champ `revue:` de `docs/reviews/<nom>.md` où `<nom>` ne contient que `[A-Za-z0-9._-]`. Pas d'autre forme : aucun chemin absolu, aucun `..`, aucun sous-dossier. Un champ rempli sans chemin de cette forme équivaut à un fichier introuvable. Un lien symbolique, un fichier de plus de 1 Mio ou un fichier non lisible équivaut à un fichier introuvable. Un fichier de revue est lu seulement par sa dernière ligne.
- **RG-12 (issue `En revue`)** Si le champ `revue:` ne désigne aucun fichier de revue lisible (RG-11), avis A07 (D-23).
- **RG-13 (issue démarrée sans branche, dépendances)** Une issue `En cours` ou `En revue` (statut effectif) sans branche retenue (aucune, ou ambiguë selon le PRD 003) : avis A08. Pour une issue qui n'est pas `Fait` ni `Abandonnée` : une dépendance (`depend_de`) `Abandonnée` donne l'avis A09 (la dépendance n'est jamais levée : l'issue reste « bloquée » pour le dashboard et `etat-issues.sh --prochaine`, inchangés ; c'est à l'utilisateur de modifier `depend_de` ; lecture retenue : avis, dépendance non levée) ; une dépendance d'identifiant inexistant : avis A10. Une issue `Fait` (local) dont une dépendance n'est ni `Fait` ni `Abandonnée` (statut effectif) : avis A11.
- **RG-15 (issue `Abandonnée`)** Sa section `## Notes` contient au moins une ligne à puce contenant le mot `Abandonnée` (la raison, datée comme les autres notes) ; sinon erreur E13.

### 2.4 État d'un besoin (D-19, D-20)
- **RG-14 (fusionnée)** La fusion se lit dans Git, relativement à la branche locale `develop` (nom fixe) et non à la branche courante. Une issue `Fait` est **fusionnée** si sa branche retenue (PRD 003 : déclarée existante, ou déduite) est fusionnée dans `develop` (sa pointe en est un ancêtre). Sans branche retenue (branche supprimée après fusion, jamais créée, ou ambiguë), l'issue est fusionnée si son fichier, **tel qu'il est dans `develop`**, porte `statut: Fait`. Si `develop` n'existe pas, la fusion n'est pas vérifiable : avis A13, et la condition de fusion n'est pas reprochée (ni E07 ni E08 de ce chef).
- **RG-16 (première issue `En cours`)** « Première issue En cours » = au moins une issue démarrée (statut effectif), lu comme dans le PRD 003, donc y compris une issue `En cours` seulement sur sa branche, non encore fusionnée.
- **RG-17 (cohérence d'un besoin avec ses issues)** Les issues `Abandonnée` sont écartées des comptes. Le contrôle déduit des issues un état implicite (*aucune démarrée*, *démarrée mais pas toutes terminées*, *toutes terminées*, *toutes terminées et fusionnées*), puis, selon le statut du backlog :

| Statut du backlog | Écart | Gravité | Message |
|---|---|---|---|
| `À faire`, `En clarification`, `Spécifié` | une issue est démarrée | erreur (en retard) | E07 |
| `En cours` | toutes terminées | erreur (en retard, attendu `En revue`) | E07 |
| `En cours`, `En revue` | toutes terminées et fusionnées | erreur (en retard, attendu `Fait`) | E07 |
| `En cours` | aucune issue démarrée (y compris aucune issue) | avis (en avance) | A12 |
| `En revue` | toutes les issues ne sont pas terminées (ou aucune issue) | avis (en avance) | A12 |
| `Fait` | aucune issue `Fait`, ou une issue ni `Fait` ni `Abandonnée`, ou une issue `Fait` non fusionnée | erreur | E08 |

  un statut de besoin *en retard* est une erreur, *en avance* un avis, sauf `Fait` injustifié, erreur. Un besoin `En clarification` ou `Spécifié` sans issue est normal (avant le découpage). Aucun écart, aucun message, dans tous les autres cas.
- **RG-18 (besoin `Abandonnée`)** La colonne Décisions contient le mot `Abandonn` (début de `Abandonnée`) ; sinon erreur E09. Si une issue du besoin est `À faire`, `En cours` ou `En revue` : avis A15. Un besoin dont toutes les issues sont `Abandonnée` ne peut pas être `Fait` (E08, aucune issue `Fait`) : il est `Abandonnée`.
- **RG-19 (plusieurs PRD)** Les issues d'un besoin peuvent relever de plusieurs PRD (l'appartenance suit `besoin:`, pas `prd:`). Toutes comptent dans l'état du besoin. Le chemin du PRD d'une issue (`prd:`) qui n'est pas listé dans la colonne PRD du besoin, ou qui désigne un fichier absent : avis A14.

### 2.5 Sortie, codes, messages (D-21, D-22)
- **RG-20 (forme)** Une ligne par constat : `<GRAVITÉ> <CODE> <objet> : <texte>`, avec `GRAVITÉ` = `ERREUR` ou `AVIS`, `objet` = `issue <id>`, `besoin <id>`, `backlog` ou `fichier <chemin>`. Classement : erreurs avant avis, puis par objet (ordre des fichiers pour les issues, ordre du tableau pour les besoins), puis par code. Dernière ligne : `STATUTS : <e> erreur(s), <a> avis` (toujours). Rien d'autre n'est écrit sur la sortie standard. Codes de sortie : 0 aucune erreur (avis permis), **1 au moins une erreur**, 64 usage (option inconnue ou argument superflu). Un seul argument est permis : `--table`.
- **RG-21 (valeurs insérées)** Toute valeur lue dans un fichier et insérée dans un message est neutralisée : retour chariot, saut de ligne et tabulation remplacés par une espace, autres caractères de contrôle retirés (comme `scripts/notifier.sh`), puis tronquée à 120 caractères (suffixe `…`). Aucune valeur n'est évaluée, exécutée, utilisée comme motif ou comme option (RG-22).
- **RG-22 (rien n'est évalué)** Les valeurs lues (statuts, identifiants, chemins, noms de branche, identifiants de commit, texte des cellules) sont des données. Les identifiants de commit doivent être hexadécimaux de 7 à 40 caractères pour être soumis à Git ; sinon l'avis A06 est émis sans appel Git. Les noms de branche sont traités comme dans le PRD 003 (validés, préfixés `refs/heads/`, jamais passés à un shell).
- **RG-23 (catalogue des messages)** Liste **exhaustive** ; le texte est un contrat (`<…>` = valeur neutralisée) :

| Code | Gravité | Objet | Texte |
|---|---|---|---|
| E01 | erreur | `backlog` | `backlog.md absent ou illisible` (aucun autre constat n'est émis ; code 1) |
| E02 | erreur | `backlog` | `tableau des besoins introuvable (colonnes ID, Statut, PRD attendues)` (les constats sur les issues restent émis, sauf E12) |
| E03 | erreur | `besoin <id>` | `ligne illisible (nombre de colonnes différent de l'en-tête)` |
| E04 | erreur | `besoin <id>` | `identifiant en double dans le backlog` |
| E05 | erreur | `besoin <id>` | `statut inconnu « <valeur> » (attendus : <liste>)` |
| E06 | erreur | `besoin <id>` | `statut <statut> sans PRD valide (<colonne PRD vide \| fichier absent : <chemin>>)` |
| E07 | erreur | `besoin <id>` | `statut <statut> en retard : <motif>` ; motifs : `l'issue <id> est démarrée`, `toutes les issues sont Fait (attendu : En revue)`, `toutes les issues sont Fait et fusionnées dans develop (attendu : Fait)` |
| E08 | erreur | `besoin <id>` | `statut Fait non justifié : <motif>` ; motifs : `aucune issue Fait`, `l'issue <id> n'est ni Fait ni Abandonnée`, `la branche de l'issue <id> n'est pas fusionnée dans develop` |
| E09 | erreur | `besoin <id>` | `statut Abandonnée sans raison dans la colonne Décisions` |
| E10 | erreur | `issue <id>` (ou `fichier <chemin>`) | `statut inconnu « <valeur> » (attendus : <liste>)` |
| E11 | erreur | `fichier <chemin>` | `identifiant d'issue absent` \| `identifiant d'issue en double : <id>` (un message par fichier concerné) |
| E12 | erreur | `issue <id>` | `besoin « <valeur> » inconnu du backlog` |
| E13 | erreur | `issue <id>` | `statut Abandonnée sans raison dans les Notes` |
| E14 | erreur | `fichier <chemin>` | `fichier d'issue illisible (<motif>)` ; motifs : `lien symbolique`, `plus de 1 Mio`, `en-tête YAML absent ou non fermé`, `lecture impossible` |
| A01 | avis | `issue <id>` | `Fait sans champ revue renseigné` |
| A02 | avis | `issue <id>` | `Fait : fichier de revue introuvable ou illisible (<chemin ou champ>)` |
| A03 | avis | `issue <id>` | `Fait : la dernière ligne de <chemin> n'est pas APPROUVÉ` |
| A04 | avis | `issue <id>` | `Fait sans ligne « FIN-ISSUE OK <id> » dans les Notes` |
| A05 | avis | `issue <id>` | `Fait sans commit déclaré` |
| A06 | avis | `issue <id>` | `commit déclaré introuvable : <valeur>` |
| A07 | avis | `issue <id>` | `En revue sans fichier de revue (<chemin ou champ>)` |
| A08 | avis | `issue <id>` | `<statut> sans branche retenue` ou `<statut> : branche ambiguë : <liste>` |
| A09 | avis | `issue <id>` | `dépend de l'issue Abandonnée <id>` |
| A10 | avis | `issue <id>` | `dépend de <id>, issue inconnue` |
| A11 | avis | `issue <id>` | `Fait alors que la dépendance <id> n'est pas terminée` |
| A12 | avis | `besoin <id>` | `statut <statut> en avance : <motif>` ; motifs : `aucune issue démarrée`, `toutes les issues ne sont pas Fait` |
| A13 | avis | `backlog` | `branche develop absente : fusion non vérifiable` |
| A14 | avis | `issue <id>` | `PRD <chemin> non listé dans le backlog pour le besoin <id>` \| `PRD <chemin> introuvable` |
| A15 | avis | `besoin <id>` | `Abandonnée alors que l'issue <id> est <statut>` |

  Un fichier d'issue en erreur E10, E11 ou E14 n'est comptée pour aucun besoin (sa propre ligne l'indique) et n'émet aucun autre constat. Une valeur inconnue est une erreur, pas un avis, parce qu'elle fausse tous les comptes. Les textes de ce catalogue citent des noms de statut : ils sont des messages (contrats), pas des listes (RG-32).

### 2.6 Cas limites
- **Fichiers absents** : `backlog.md` absent ou illisible : E01. `docs/issues/` absent ou vide : aucune issue, pas d'erreur (les besoins sont contrôlés sans issue). Fichier de revue ou PRD absent : A02, A07, E06 ou A14 selon le cas. Le dossier `docs/reviews/` absent revient à « fichier de revue introuvable ».
- **Comparaison** : voir RG-06. Les identifiants d'issue et de besoin sont comparés comme du texte littéral (`F-1` n'est pas `F-10`).
- **Plusieurs PRD** : voir RG-19. **Issue `Abandonnée` dans `depend_de`** : voir RG-13. **Besoin sans issue** : voir RG-17. **Valeurs hostiles** : voir RG-21, RG-22 et la section 6.

### 2.7 Lecture seule, coût (D-21)
- **RG-24 (lecture seule)** Le contrôle ne modifie jamais `backlog.md`, une issue, un fichier de revue, un PRD, les refs, l'index, l'arbre de travail ni la liste des worktrees, et ne prend aucun verrou d'index (il n'utilise aucune commande qui rafraîchit l'index ou exécute un programme configuré).
- **RG-25 (coût)** Le contrôle ajoute **au plus 3 appels Git** à ceux du calcul du statut effectif (PRD 003), quel que soit le nombre d'issues, de besoins et de branches : un listage des branches fusionnées dans `develop` (avec test d'existence de `develop`), une lecture groupée des fichiers d'issue tels qu'ils sont dans `develop`, une vérification groupée des identifiants de commit déclarés. La liste des branches locales est partagée avec le PRD 003 (jamais relue). Aucun appel Git si aucune issue `Fait` n'est à vérifier. La génération du dashboard exécute le contrôle une seule fois.

### 2.8 Intégration, documentation, version (D-21, D-24, D-25)
- **RG-26 (dashboard)** Le dashboard exécute le contrôle à chaque génération et affiche une section « Contrôle des statuts » : le récapitulatif, puis chaque erreur et chaque avis (texte échappé en HTML) ; « Aucune incohérence. » s'il n'y a ni erreur ni avis ; « Contrôle indisponible » (sans détail brut) si le contrôle n'a pas pu s'exécuter. Le code de sortie du dashboard ne dépend pas du résultat du contrôle. Les colonnes, cartes et ordre existants ne changent pas (RG-02).
- **RG-27 (`/deliver`)** La skill `deliver` lance `scripts/statuts.sh` à **chaque changement de statut** d'issue (début, passage en revue, retour en corrections, `Fait`) et à chaque proposition de changement de statut de besoin. Une erreur qui vise l'issue traitée ou son besoin arrête le passage et est remontée à la session ; les autres constats sont reportés dans le rapport. Le contrôle ne corrige rien.
- **RG-28 (`fin-issue.sh`)** `scripts/fin-issue.sh` est inchangé (D-21).
- **RG-29 (documentation)** `AGENTS.md` (commande `scripts/statuts.sh`, « Séquence d'un besoin » : renvoi à la table au lieu de la prose), `factory/templates/AGENTS.md` (idem), la skill `deliver` (renvoi à la table, appel du contrôle), `factory/README.md` (section scripts : `scripts/statuts.sh`, messages, section du dashboard), `docs/issues/README.md` si elle liste les statuts, l'en-tête de `scripts/statuts.sh`. La ligne « Statuts » de `backlog.md` (propriété de l'utilisateur, `Abandonnée` à y ajouter) est **proposée** à l'utilisateur, pas modifiée.
- **RG-30 (version)** La version suivante libre à la livraison, fixée dans l'issue de documentation et de version (pas écrite ici) ; `CHANGELOG.md` a une entrée avec la migration « remplacer `factory/` » ; aucune migration de données (`Abandonnée` est un ajout ; une issue ou un besoin existant garde son statut ; les issues sans preuves donnent des avis, jamais d'erreur). L'issue de retrait (RG-32) ajoute une ligne à la même entrée. Pas d'ADR (D-25).
- **RG-31 (hors périmètre)** Colonne dédiée aux `Abandonnée` (F-04), verdict de revue (F-03), correction automatique, contrôle de l'historique des transitions, dépendances circulaires, qualité de la raison d'abandon, besoins non fonctionnels, modification de `fin-issue.sh`.

### 2.9 Retrait du code mort (D-26)
- **RG-32 (plus aucun doublon)** Après la livraison de toutes les autres issues de ce besoin, une dernière issue supprime ce que la table unique rend inutile, sans aucun changement de comportement visible :
  (a) **listes de statuts** : plus aucune liste de statuts de besoin ou d'issue en dehors de la table (dashboard, bibliothèque des issues, `etat-issues.sh`, tout autre script de la factory) ; plus de valeur de statut écrite en dur pour énumérer, ordonner ou classer. Exceptions admises, listées et justifiées une à une dans l'issue : `scripts/fin-issue.sh` (inchangé, RG-28), les textes des messages du catalogue (RG-23), les commentaires, les données de test ;
  (b) **prose de transition** : `AGENTS.md`, `factory/templates/AGENTS.md` et la skill `deliver` ne répètent plus de règle de transition ni de chaîne de statuts (`À faire → En clarification → …`) ; ils renvoient à la table (`scripts/statuts.sh --table`). Ils gardent l'enchaînement des étapes du travail, sans les statuts exhaustifs ;
  (c) **tests** : aucun test ne vérifie seulement l'ancienne duplication (par exemple l'égalité de deux listes recopiées) ; ils sont supprimés ou remplacés par les tests de source unique (CA-02) ; aucun critère des autres issues ne perd son test ;
  (d) **garde-fou** : un test de la suite échoue si une liste de statuts ou une chaîne de transitions revient hors de la table (recherche d'absence), et il est lui-même éprouvé sur une copie où un doublon est réintroduit.
  La ligne « Statuts » de `backlog.md` n'est pas touchée (propriété de l'utilisateur, proposée en RG-29).

## 3. Modèle de données (point de vue métier)
- **Besoin** : `id`, `statut` (7 valeurs), `PRD` (0 à n chemins), `Décisions` (texte), ses issues (par `besoin:`), son **état implicite** (aucune démarrée | en cours | toutes terminées | toutes fusionnées).
- **Issue** : `id`, `besoin`, `statut` local, **statut effectif** et **branche retenue** (PRD 003), `depend_de`, `prd`, `commits`, `revue` (texte libre contenant un chemin), Notes.
- **Constat** : gravité (erreur | avis), code, objet, texte.
- **Table des statuts** : par entité, statuts ordonnés (cycle, hors cycle) et transitions (de, vers, déclencheur, preuve).

## 4. Contrats externes
- `scripts/statuts.sh` : sans argument, contrôle ; `--table`, affiche les tables ; sortie et codes selon RG-20 ; en cas d'option inconnue, message d'usage sur la sortie d'erreur et code 64.
- `scripts/dashboard.sh` : options, codes et colonnes inchangés ; section « Contrôle des statuts » ajoutée (RG-26).
- `scripts/fin-issue.sh`, `scripts/etat-issues.sh` : comportement inchangé (sauf lecture de la table pour la liste des statuts).
- Sources lues : `backlog.md`, `docs/issues/`, `docs/reviews/`, `docs/prd/`, branches locales, fichiers d'issue sur `develop`.

## 5. Critères d'acceptation
Identifiants au format `CA-xx` (convention de `scripts/couverture-prd.sh`). Les tests créent des dépôts Git jetables (copie des scripts, `git init`, branche `develop`, branches de travail, `backlog.md` et fichiers d'issue de fixtures), avec un `git` de comptage en tête de `PATH` quand un critère mesure les appels. Le nom d'un test est de la forme `ca01_…`.

### Table, source unique, lecture des fichiers
- **CA-01** Given le dépôt, When on lance `scripts/statuts.sh --table`, Then le code est 0 et la sortie donne 5 statuts d'issue (`À faire`, `En cours`, `En revue`, `Fait`, `Abandonnée`) et 7 de besoin dans l'ordre de la section 2.1, et chaque transition légale des deux tables avec son déclencheur et sa preuve, et aucune transition qui n'y figure pas (par exemple pas de `À faire` vers `Fait` pour une issue).
- **CA-02** Given une copie jetable où l'on ajoute un statut factice dans la table des issues, When on lance le dashboard, `etat-issues.sh` et `statuts.sh` sur une issue portant ce statut, Then le dashboard le place dans le cycle (colonne propre, ordre), la bibliothèque le classe, et `statuts.sh` n'émet pas E10 ; Given le statut retiré de la table, Then `statuts.sh` émet E10 pour cette issue ; Given le même essai pour un statut de besoin, Then la colonne du dashboard et E05 suivent de même.
- **CA-03** Given un dépôt de fixtures sans issue `Abandonnée`, When on génère le dashboard et lance `etat-issues.sh` (sans option, `--prochaine`), Then la page (hors section de contrôle, date et durées) et les sorties sont identiques à celles d'avant la livraison ; Given une issue `Abandonnée`, Then sa carte est dans la colonne « (autre) » et son statut effectif reste `Abandonnée`.
- **CA-04** Given des issues dont le statut vaut `fait`, `FAIT`, `Fini`, vide, `A faire`, ou `À faire` en forme décomposée, When on lance `statuts.sh`, Then une ligne `ERREUR E10 issue <id> : statut inconnu « <valeur> » (attendus : …)` par issue, la liste des attendus est celle de la table, aucune correction ni suggestion, code 1, et ces issues ne sont comptées pour aucun besoin ; Given `Fait` entouré d'espaces ou de guillemets, Then il est lu comme `Fait`.
- **CA-05** Given un besoin dont le statut du backlog vaut `Specifie`, `en cours`, `Fini`, vide, Then `ERREUR E05 besoin <id> : statut inconnu « <valeur> » (attendus : …)`, aucune autre vérification de ce besoin, code 1.
- **CA-06** Given `backlog.md` absent, Then la seule ligne d'erreur est E01, puis la ligne de récapitulatif, code 1 ; Given un backlog sans tableau reconnu, Then E02 et les contrôles des issues (sauf E12) sont émis ; Given une ligne de besoin dont le nombre de colonnes diffère de l'en-tête, Then E03 pour cette ligne seule et les autres lignes sont contrôlées ; Given deux lignes de même identifiant, Then E04 ; Given un tableau des besoins non fonctionnels, Then il n'est pas lu.
- **CA-07** Given un dépôt cohérent, When on lance `statuts.sh`, Then la sortie est la seule ligne `STATUTS : 0 erreur(s), 0 avis` et le code 0 ; Given des constats, Then les lignes ont la forme `<GRAVITÉ> <CODE> <objet> : <texte>`, les erreurs précèdent les avis, le tri est celui de RG-20, et la dernière ligne est le récapitulatif exact ; Given un avis seul, Then code 0 ; Given une option inconnue ou un argument superflu, Then usage sur la sortie d'erreur et code 64, rien sur la sortie standard.
- **CA-08** Given une issue sans `id:` ou vide, Then `ERREUR E11 fichier <chemin> : identifiant d'issue absent` ; Given deux fichiers de même `id:`, Then un E11 `identifiant d'issue en double : <id>` pour chacun ; ces issues sont ignorées des comptes, les autres sont contrôlées.
- **CA-09** Given un fichier d'issue sans ligne `---` d'ouverture ou de fermeture, ou plus gros que 1 Mio, ou lien symbolique (même vers un fichier de la même arborescence), ou illisible (droits retirés), Then `ERREUR E14 fichier <chemin> : fichier d'issue illisible (<motif>)` avec le motif de RG-23, le fichier est ignoré, les autres sont contrôlés, et le contenu du fichier visé n'est reproduit nulle part.

### Preuves d'une issue
- **CA-10** Given une issue `Fait` avec `revue:` renseigné, fichier de revue dont la dernière ligne est `APPROUVÉ`, ligne `FIN-ISSUE OK <id> …` dans les Notes et un `commits:` existant, When on lance `statuts.sh`, Then aucun constat sur cette issue, pour chacune des trois formes réelles du champ (`docs/reviews/<id>.md`, `docs/reviews/<id>.md (APPROUVÉ, itération 1/3)`, `APPROUVÉ (itération 2 sur 2, docs/reviews/<id>.md)`), avec lignes vides, retour chariot ou espaces en fin de fichier de revue.
- **CA-11** Given une issue `Fait` dont `revue:` est vide, Then `AVIS A01` ; dont le chemin désigne un fichier absent, un lien symbolique, un fichier de plus de 1 Mio ou n'a pas la forme `docs/reviews/<nom>.md` (`../x.md`, chemin absolu, sous-dossier), Then `AVIS A02` ; dont la dernière ligne est `CHANGEMENTS DEMANDÉS`, `approuvé`, `APPROUVÉ.`, `VERDICT: APPROUVÉ`, ou dont `APPROUVÉ` n'est présent qu'en première ligne, Then `AVIS A03` ; le code reste 0 si aucune erreur.
- **CA-12** Given une issue `Fait` dont les Notes n'ont pas de ligne `FIN-ISSUE OK <id> `, ou n'en ont qu'une pour une autre issue, ou `FIN-ISSUE ECHEC`, ou une `FIN-ISSUE OK <id>` située avant la section `## Notes`, ou `FIN-ISSUE OK <id>` sans espace après l'identifiant (préfixe d'un autre identifiant), Then `AVIS A04` ; avec la ligne dans une note à puce, entre accents graves, Then aucun avis.
- **CA-13** Given une issue `Fait` avec `commits: []`, Then `AVIS A05` ; avec un identifiant hexadécimal absent du dépôt, Then `AVIS A06` ; avec une valeur non hexadécimale (`zzz`, `$(x)`, `--help`, 41 caractères), Then `AVIS A06` sans appel Git sur cette valeur ; avec un commit existant, Then aucun avis.
- **CA-14** Given les issues réelles terminées avant ce besoin (`revue:` vide, sans `FIN-ISSUE OK`), When on lance `statuts.sh` sur une copie du dépôt, Then elles ne produisent que des avis, aucune erreur de leur chef, et le code de sortie est celui des seules erreurs.
- **CA-15** Given une issue `En revue` dont `revue:` est vide ou désigne un fichier absent, Then `AVIS A07` ; avec un fichier de revue lisible (quelle que soit sa dernière ligne), Then aucun avis ; Given une issue `À faire` ou `En cours` avec un `revue:` renseigné, Then aucun avis.
- **CA-16** Given une issue `En cours` ou `En revue` (statut effectif) sans branche retenue, Then `AVIS A08 … sans branche retenue` ; avec une branche ambiguë (PRD 003), Then `AVIS A08 … branche ambiguë : <liste>` ; avec une branche retenue, une issue `Fait` sans branche (branche supprimée après fusion) ou une issue `À faire`, Then aucun avis A08.
- **CA-17** Given une issue `Abandonnée` dont les Notes n'ont aucune ligne à puce contenant le mot `Abandonnée`, Then `ERREUR E13` et le code 1 ; avec une telle ligne, Then aucun constat ; Given une issue locale `Abandonnée` dont le fichier est `Fait` sur sa branche, Then son statut effectif reste `Abandonnée` (jamais promu) ; Given une issue `Fait` local dont le fichier est `Abandonnée` sur la branche, Then elle reste `Fait`.
- **CA-18** Given une issue `À faire`, `En cours` ou `En revue` dont `depend_de` contient une issue `Abandonnée`, Then `AVIS A09 … dépend de l'issue Abandonnée <id>`, `scripts/etat-issues.sh --prochaine` ne la rend pas et le dashboard la marque « bloquée » (inchangés) ; une dépendance inexistante, Then `AVIS A10` ; une issue `Fait` dont une dépendance est `En cours`, Then `AVIS A11` ; une issue `Fait` dont une dépendance est `Abandonnée`, Then aucun avis.

### Cohérence des besoins
- **CA-19** Given une issue dont `besoin:` est vide, vaut `F-99` absent du backlog, ou `F-01, F-02`, Then `ERREUR E12 issue <id> : besoin « <valeur> » inconnu du backlog`, et elle n'est comptée pour aucun besoin ; `F-1` ne se confond pas avec `F-10`.
- **CA-20** Given un besoin `Spécifié`, `En cours`, `En revue` ou `Fait` dont la colonne PRD est vide, ou cite un fichier absent (parmi plusieurs), Then `ERREUR E06 besoin <id> : statut <statut> sans PRD valide (…)` ; Given `À faire`, `En clarification` ou `Abandonnée` sans PRD, Then aucune erreur ; Given un besoin `Spécifié` avec PRD présent et sans issue, Then aucun constat.
- **CA-21** Given un besoin `À faire`, `En clarification` ou `Spécifié` dont une issue est `En cours` (statut local), ou `Fait` seulement sur sa branche (statut effectif), Then `ERREUR E07 besoin <id> : statut <statut> en retard : l'issue <id> est démarrée`, code 1 ; Given les mêmes issues `Abandonnée` ou `À faire`, Then aucune erreur.
- **CA-22** Given un besoin `En cours` dont toutes les issues (hors `Abandonnée`, au moins une `Fait`) sont `Fait` et non fusionnées, Then `ERREUR E07 … en retard : toutes les issues sont Fait (attendu : En revue)` ; avec toutes fusionnées dans `develop`, Then `… toutes les issues sont Fait et fusionnées dans develop (attendu : Fait)` ; Given un besoin `En revue` avec toutes les issues `Fait` non fusionnées, Then aucun constat ; avec toutes fusionnées, Then l'erreur `attendu : Fait` ; avec une issue `En cours`, Then `AVIS A12` (en avance), pas d'erreur.
- **CA-23** Given un besoin `Fait` sans aucune issue `Fait`, ou avec une issue `À faire`, `En cours` ou `En revue`, ou avec une issue `Fait` non fusionnée, Then `ERREUR E08` avec le motif exact de RG-23 (premier motif dans l'ordre : `aucune issue Fait`, puis l'issue concernée par identifiant, puis la branche non fusionnée) ; Given des issues `Fait` fusionnées et `Abandonnée` avec au moins une `Fait`, Then aucun constat ; Given toutes les issues `Abandonnée`, Then E08 `aucune issue Fait`.
- **CA-24** Given `develop` et trois issues `Fait` : branche déclarée fusionnée, branche déduite non fusionnée (un commit de plus que `develop`), branche supprimée dont le fichier est `Fait` dans `develop`, Then elles sont respectivement fusionnée, non fusionnée, fusionnée ; Given une branche ambiguë, Then traitée comme sans branche retenue ; Given une branche au même commit que `develop`, Then fusionnée ; Given l'absence de la branche `develop`, Then `AVIS A13 backlog : branche develop absente : fusion non vérifiable`, et ni E07 ni E08 pour cause de fusion ; la branche courante n'intervient pas (même résultat depuis une autre branche).
- **CA-25** Given un besoin `En cours` sans issue démarrée (ou sans issue), Then `AVIS A12 … en avance : aucune issue démarrée` ; un besoin `En revue` dont une issue n'est pas `Fait` (ou sans issue), Then `AVIS A12 … toutes les issues ne sont pas Fait` ; aucun code 1 de ce chef.
- **CA-26** Given un besoin dont les issues relèvent de deux PRD, dont l'un est dans la colonne PRD du backlog et l'autre non, Then toutes ses issues comptent dans son état, et l'issue du PRD non listé donne `AVIS A14 … PRD <chemin> non listé dans le backlog pour le besoin <id>` ; un `prd:` d'issue absent du dépôt, Then `AVIS A14 … introuvable` ; une colonne PRD à deux chemins, Then les deux sont exigés présents (E06 sinon).
- **CA-27** Given un besoin `Abandonnée` dont la colonne Décisions ne contient pas `Abandonn`, Then `ERREUR E09` ; avec le mot, Then aucun constat ; avec une issue `En cours`, Then `AVIS A15 … Abandonnée alors que l'issue <id> est En cours` ; avec des issues `Fait` ou `Abandonnée` seules, Then aucun constat ; Given un besoin `Fait` ayant une issue `Abandonnée` et une `Fait` fusionnée, Then aucun constat.

### Sûreté d'exécution
- **CA-28** Given un dépôt de fixtures riche (erreurs, avis, branches, worktrees), When on lance `statuts.sh` (avec et sans `--table`) puis le dashboard, Then `backlog.md`, chaque fichier de `docs/issues/`, `docs/reviews/` et `docs/prd/` sont identiques octet pour octet (somme de contrôle), et les refs (liste et valeurs), l'index, l'arbre de travail (`git status` identique), la liste des worktrees sont identiques avant et après, sans verrou d'index (aucun `index.lock` observé pendant l'exécution), et aucun fichier n'est créé hors de la sortie du dashboard.
- **CA-29** Given des dépôts jetables sans branche à retenir avec 3, 12 puis 50 issues dont 1, 6 puis 25 `Fait` et un `git` de comptage, When on lance `statuts.sh`, Then le nombre d'appels Git est le même pour 3, 12 et 50 issues et au plus 6 ; Given des issues à branches déclarées, Then le nombre d'appels du contrôle dépasse d'au plus 3 celui du calcul du statut effectif seul (PRD 003) sur le même dépôt, et la différence ne croît pas avec le nombre d'issues ; Given aucune issue `Fait`, Then aucun appel de fusion ni de vérification de commit ; Given le dashboard, Then le contrôle n'est exécuté qu'une fois.
- **CA-30** Given `docs/issues/` absent ou vide, `docs/reviews/` absent, `docs/prd/` absent, un fichier de revue en lecture interdite, Then `statuts.sh` termine sans message d'erreur de shell, avec les constats attendus de la section 2.6 et le code 1 seulement si une erreur est émise.

### Intégration, documentation, version
- **CA-31** Given un dépôt avec des erreurs et des avis, When on génère le dashboard, Then la section « Contrôle des statuts » contient le récapitulatif et chaque constat avec son code et son texte exacts de RG-23 ; Given un dépôt cohérent, Then « Aucune incohérence. » ; Given une génération dont le contrôle ne peut s'exécuter (script absent), Then « Contrôle indisponible » sans chemin ni détail brut.
- **CA-32** Given des erreurs de contrôle, When on lance le dashboard, Then son code de sortie reste 0 (ou 64 pour un mauvais usage, comme avant) et les cartes, colonnes et ordre sont inchangés (CA-03).
- **CA-33** Given la skill `deliver`, When on la lit après livraison, Then elle impose `scripts/statuts.sh` à chaque changement de statut d'issue (début, revue, corrections, `Fait`) et de besoin, dit qu'une erreur visant l'issue ou son besoin arrête le passage, renvoie à la table, et `scripts/fin-issue.sh` n'a aucune ligne modifiée par ce besoin.
- **CA-34** Given la documentation (RG-29), When on la lit après livraison, Then `AGENTS.md` (commande `scripts/statuts.sh` et « Séquence d'un besoin » qui renvoie à la table), `factory/templates/AGENTS.md`, `factory/README.md` (commande, messages, section du dashboard) et l'en-tête de `scripts/statuts.sh` décrivent le contrôle, ses codes, sa lecture seule et `Abandonnée`.
- **CA-35** Given le dépôt après livraison, When on lit `factory/VERSION`, `CHANGELOG.md` et `factory/README.md`, Then la version est la suivante libre (supérieure à toute version déjà livrée), le CHANGELOG a une entrée qui décrit le changement, la migration « remplacer `factory/` » et l'absence de migration de données, et le README mentionne la nouveauté.
- **CA-36** Given `factory/scripts/tests/run.sh`, When on le lance, Then les cas de CA-01 à CA-41 et CS-01 à CS-06 y figurent, leur nom contient l'identifiant (`ca01_…`), ils passent avec des dépôts Git jetables, `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM` et `HOME` isolés, sans réseau ni dépôt réel.
- **CA-37** Given des dépôts sans `Abandonnée`, When on lance la suite existante de `run.sh` et `scripts/fin-issue.sh` sur une issue, Then tout passe comme avant ce besoin (mêmes sorties et codes de `fin-issue.sh`, `etat-issues.sh`, `dashboard.sh` hors section de contrôle).

### Retrait du code mort (D-26)
- **CA-38** Given les scripts de la factory (dont le dashboard, la bibliothèque des issues, `etat-issues.sh`, `statuts.sh`) après livraison, When on cherche par motif une déclaration de liste ou de tableau de statuts de besoin ou d'issue, une suite de trois statuts ou plus d'une même entité, ou une valeur de statut littérale servant à énumérer ou ordonner, Then il n'y en a aucune hors la table, `scripts/fin-issue.sh`, les textes du catalogue RG-23, les commentaires et les données de test, et chaque exception est listée et justifiée dans l'issue.
- **CA-39** Given `AGENTS.md`, `factory/templates/AGENTS.md` et la skill `deliver` après livraison, When on les cherche par motif, Then aucune chaîne de trois statuts ou plus reliés par une flèche ou `->`, aucune liste des statuts d'une entité, aucune phrase de règle de transition (« passe à … quand … ») hors du renvoi à la table ; chacun contient un renvoi à `scripts/statuts.sh --table` ; le fichier garde l'enchaînement des étapes du travail.
- **CA-40** Given la suite `factory/scripts/tests/run.sh` après retrait, When on la lance, Then elle est verte ; aucun test ne vérifie seulement l'égalité ou la présence de listes de statuts recopiées ; les tests retirés sont énumérés dans l'issue avec leur raison ; chaque critère CA-01 à CA-37 et CS-01 à CS-06 garde au moins un test (`scripts/criteres-sans-test.sh` à OK pour les issues 004-01 à 004-05).
- **CA-41** Given les fixtures de CA-03, CA-07 et CA-31, When on génère le dashboard et lance `etat-issues.sh`, `etat-issues.sh --prochaine` et `statuts.sh` avant puis après le retrait, Then les sorties (page hors date et durées, tableaux, codes) sont identiques octet pour octet ; Given une copie où l'on réintroduit une liste de statuts hors de la table, Then le garde-fou de CA-38 échoue ; l'entrée du CHANGELOG mentionne le retrait.

## 6. Sécurité (owasp-check)

### Modèle de menaces succinct
- **Actifs** : intégrité de ce que l'utilisateur lit (un faux « tout est cohérent » ou un faux `Fait` accepté) ; sûreté du poste (le dashboard tourne en boucle, sans surveillance) ; secrets du poste (aucun fichier hors dépôt ne doit être lu).
- **Acteurs** : une PR, une branche ou un collaborateur qui écrit un fichier d'issue, un fichier de revue, une cellule de backlog ou un nom de branche hostile ; un agent qui rédige des notes.
- **Points d'entrée** : `statut`, `id`, `besoin`, `depend_de`, `prd`, `commits`, `revue`, `branche` (en-têtes d'issues), section Notes, cellules du backlog (statut, PRD, Décisions), contenu des fichiers de revue (dernière ligne), noms de branches locales, contenu de `develop`.
- Tout cela est une **donnée non fiable** : lue comme du texte, jamais exécutée, évaluée, interprétée comme motif, option ou chemin libre.

### Catégories
- **A01 Contrôle d'accès / traversée** : lecture seule ; le chemin d'un fichier de revue ne peut être que `docs/reviews/<nom>.md` avec `<nom>` dans `[A-Za-z0-9._-]` (RG-11) ; un chemin de PRD ne peut être que `docs/prd/<nom>.md` ; liens symboliques refusés ; gros fichiers refusés ; aucun fichier hors dépôt lu ni son contenu reproduit (CS-03).
- **A02, A07, A10** : non applicables (aucun secret, aucune identité, aucune requête sortante).
- **A03 Injection** : aucune valeur lue n'est évaluée, exécutée, passée à un shell ni utilisée comme motif ou option (RG-22, CS-02) ; sortie neutralisée des caractères de contrôle (CS-01) ; échappement HTML dans le dashboard (CS-05) ; identifiants de commit validés avant tout appel Git (CA-13).
- **A04 Conception** : échec sûr : statut inconnu, ligne illisible, fichier illisible = erreur, sans correction ; un manque de preuve sur l'ancien = avis, jamais erreur (D-22) ; tables de transitions explicites et uniques (RG-01, RG-32) ; le contrôle ne décide de rien (le statut d'un besoin reste à l'utilisateur, D-12).
- **A05 Configuration** : aucun réglage ajouté ; aucune trace, message d'erreur sans chemin hors dépôt ni contenu brut de fichier ; pas de commande Git qui exécute un programme configuré.
- **A06** : aucune dépendance ajoutée.
- **A08 Intégrité** : un `Fait` dans une issue ou une branche locale créée à la main peut tromper le contrôle ; il reste un indicateur, la fusion par l'utilisateur et `fin-issue.sh` sont les filets. Le contrôle ne valide pas la qualité d'une revue ni d'une raison d'abandon. Le retrait du code mort (RG-32) ne supprime aucun contrôle de sécurité : les tests de la section 6 restent.
- **A09 Journalisation** : pas de journal ; la sortie ne contient pas de donnée sensible (valeurs neutralisées et tronquées).

### Validation des entrées
| Entrée | Règle | Refus |
|---|---|---|
| Statut (issue, besoin) | égal à une valeur de la table, comparaison exacte | E05 / E10 |
| `id` d'issue | non vide, unique | E11 |
| `besoin:` | égal à l'identifiant d'une ligne du backlog | E12 |
| Chemin de revue | première occurrence de `docs/reviews/<[A-Za-z0-9._-]+>.md`, fichier régulier non lien, au plus 1 Mio | A02 / A07 |
| Chemin de PRD | `docs/prd/<[A-Za-z0-9._-]+>.md`, fichier présent | E06 / A14 |
| Identifiant de commit | hexadécimal, 7 à 40 caractères, avant tout appel Git | A06 |
| Fichier d'issue | régulier, au plus 1 Mio, en-tête `---` fermé | E14 |
| Valeur insérée dans un message | caractères de contrôle neutralisés, 120 caractères au plus | tronquée |

### Critères d'acceptation de sécurité
- **CS-01** Given des valeurs contenant retour chariot, saut de ligne, tabulation, échappement de terminal (`ESC[31m`), `NUL` et caractères de contrôle dans un statut d'issue, un identifiant, un `besoin:`, une cellule de statut de besoin, un identifiant de commit et un chemin de revue, When on lance `statuts.sh`, Then chaque constat tient sur **une seule ligne**, ne contient aucun caractère de contrôle (hors saut de ligne final), aucune ligne ne contrefait un constat (`ERREUR …` injecté dans une valeur) et toute valeur de plus de 120 caractères est tronquée avec `…`.
- **CS-02** Given des valeurs `$(touch${IFS}marque)`, ``` `touch${IFS}marque` ```, `;touch${IFS}marque`, `-rf`, `--help`, `*`, `[a-z]`, `.*` dans les statuts, identifiants, `besoin:`, `depend_de`, `commits:`, `revue:`, `branche:`, cellules du backlog et noms de branches, When on lance `statuts.sh` et le dashboard, Then le fichier `marque` n'existe pas, aucune valeur n'est interprétée comme motif (`*` ne correspond pas à tous les besoins), option ou révision, et les valeurs valides voisines sont contrôlées normalement.
- **CS-03** Given un champ `revue:` valant `docs/reviews/../../etc/hostname`, `/etc/hostname`, `docs/reviews/x/../y.md`, un lien symbolique `docs/reviews/<id>.md` vers un fichier hors dépôt contenant `APPROUVÉ`, un PRD et un fichier d'issue de même nature, When on lance `statuts.sh`, Then aucun fichier hors dépôt n'est lu (le lien n'est pas suivi ; `APPROUVÉ` du fichier ciblé n'est pas pris en compte), l'avis ou l'erreur attendus sont émis, et le contenu du fichier ciblé n'apparaît nulle part.
- **CS-04** Given un backlog de 5 000 lignes de besoins, 2 000 fichiers d'issue, une ligne de 1 Mio dans une cellule et un fichier de revue de plusieurs Mio, When on lance `statuts.sh`, Then il termine sans échec de mémoire, dans un temps borné (de l'ordre de la seconde par centaine d'issues, mesuré et consigné par le test), les fichiers de revue trop gros sont refusés (A02) et une cellule trop longue est tronquée dans les messages.
- **CS-05** Given des valeurs `<img src=x onerror=alert(1)>`, `"><script>alert(1)</script>`, `&amp;'` dans les statuts, identifiants, cellules PRD, chemins de revue et noms de branche, When on génère le dashboard, Then aucune balise ni attribut issu d'une valeur n'apparaît brut dans la section « Contrôle des statuts » ni ailleurs : `&`, `<`, `>`, `"` et `'` sont échappés partout où une valeur est écrite.
- **CS-06** Given une génération du dashboard avec le contrôle, une fois puis en `--boucle` (arrêtée après deux générations), Then `backlog.md` et chaque fichier de `docs/issues/` sont identiques octet pour octet, et le seul fichier écrit est la sortie du dashboard.

## 7. Décisions reflétées
| Décision | Contenu | Reflété dans |
|---|---|---|
| D-18 | machine des issues, `Fait` final, toute autre transition illégale | 2.1, CA-01, CA-14 à CA-18 |
| D-19 | machine des besoins, fusion lue dans Git | 2.1, RG-14 à RG-17, CA-21 à CA-25 |
| D-20 | `Abandonnée` dans les deux machines, raison écrite, besoin `Fait` avec au moins une `Fait`, F-04 hors périmètre | RG-02, RG-15, RG-18, RG-31, CA-03, CA-17, CA-23, CA-27 |
| D-21 | état courant, `scripts/statuts.sh`, code 1, dashboard, `/deliver`, `fin-issue.sh` inchangé, lecture seule | RG-03, RG-20, RG-24, RG-26 à RG-28, CA-07, CA-28, CS-06 |
| D-22 | preuves d'une issue `Fait`, avis jamais erreur | RG-10, RG-11, CA-10 à CA-14 |
| D-23 | issue sans besoin, besoin sans PRD, `En revue` sans revue, statut inconnu | RG-06, RG-08, RG-09, RG-12, CA-04, CA-05, CA-15, CA-19, CA-20 |
| D-24 | après F-08 (statut effectif), table seule source | RG-01, RG-07, CA-02 |
| D-25 | pas d'ADR, version suivante libre, CHANGELOG, migration, aucune migration de données | RG-30, CA-35 |
| D-26 | retrait du code mort une fois F-09 fini : listes de statuts, valeurs en dur, prose de transition, tests de la duplication ; garde-fou ; aucun changement visible | RG-32, CA-38 à CA-41, issue 004-06 |

## 8. Questions
Réponses de l'utilisateur du 2026-11-17 : les six lectures retenues par défaut sont toutes confirmées (recommandation (a) à chaque fois), telles qu'appliquées dans les règles ci-dessus.

- **Q-01** (RG-01, F-09) Une transition illégale (ex. `En cours` vers `Fait` pour une issue) ne se voit pas dans l'état courant. Faut-il une commande de vérification d'un changement prévu ? Lecture retenue : non, la table est la référence écrite et le contrôle ne vérifie que les états.
- **Q-02** (2.1, D-20) `Abandonnée` est-elle finale, comme `Fait` ? Lecture retenue : oui (final dans les deux machines ; rouvrir = nouvelle issue, ou retour en arrière du besoin sur décision de l'utilisateur).
- **Q-03** (RG-17) Gravité des écarts entre le statut d'un besoin et ses issues. Lecture retenue : *en retard* = erreur, *en avance* = avis, `Fait` injustifié = erreur.
- **Q-04** (RG-13) Une dépendance `Abandonnée` est-elle levée ? Lecture retenue : non (avis A09, issue « bloquée » comme avant).
- **Q-05** (RG-14) Nom de la branche d'intégration. Lecture retenue : `develop`, fixe (aucune clé de configuration ajoutée).
- **Q-06** (RG-15, RG-18) Contrôle de la raison d'un abandon. Lecture retenue : présence du mot `Abandonnée` dans une note de l'issue (ligne à puce) ou `Abandonn` dans la colonne Décisions du besoin ; absence = erreur ; la qualité n'est pas jugée.

## QUESTIONS : aucune

## 9. Découpage en issues (indicatif)
Chaque critère est couvert par exactement une issue ; dépendances : 01, puis 02, puis 03 ; 04 après 03 ; 05 après 04 ; **06 en dernier, après toutes les autres** (01 à 05). Aucune issue ne dépasse 9 critères.

| Issue | Contenu | Critères |
|---|---|---|
| 004-01 | Table unique et `--table` ; source unique pour le dashboard, la bibliothèque et `etat-issues.sh` ; statuts inconnus ; lecture du backlog et des en-têtes ; forme de la sortie et codes | CA-01 à CA-09 |
| 004-02 | Preuves d'une issue (`Fait`, `En revue`), branche retenue, `Abandonnée`, dépendances | CA-10 à CA-18 |
| 004-03 | Cohérence des besoins : issue sans besoin, PRD, retard / avance, `Fait` et fusion lue dans Git, plusieurs PRD, besoin `Abandonnée` | CA-19 à CA-27 |
| 004-04 | Lecture seule, coût mesuré, fichiers absents ou hostiles, sortie neutralisée | CA-28 à CA-30, CS-01 à CS-04 |
| 004-05 | Dashboard (section de contrôle, échappement), `/deliver`, documentation, version et CHANGELOG, tests regroupés, non-régression | CA-31 à CA-37, CS-05, CS-06 |
| 004-06 | Retrait des anciennes listes et règles de statut : inventaire et suppression des listes et valeurs en dur, de la prose de transition, des tests de duplication ; garde-fou contre leur retour ; comportement identique avant / après | CA-38 à CA-41 |
