# Format des rapports de fin de mission

Commun au développeur et au reviewer. L'orchestrateur ne peut pas fouiller dans ton travail : ton rapport est sa seule vue, et il le
recoupe avec le dépôt (`git log`, `git status`, `scripts/verify-clean.sh`). Un rapport vide, un « placeholder » ou une affirmation sans
preuve est un échec de mission : il sera relancé.

Règles
- Court : 60 lignes au plus pour le développeur, 80 pour le reviewer. Le détail est dans les commits et les tests, pas dans le rapport.
- Factuel : chaque affirmation chiffrée vient d'une commande que tu as lancée ; cite la commande. N'écris jamais « tout passe » sans nombre.
- Distingue ce que tu as **vérifié** de ce que tu **supposes** ou **n'as pas pu faire**. Un point non fait est listé, jamais omis.
- Aucune donnée sensible (jeton, clé, données réelles de l'utilisateur).

## Rapport du développeur

```
## Résumé
2 à 4 lignes : ce qui est livré et ce qui ne l'est pas.

## Vérification
- Commande : scripts/verify-clean.sh
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

## Décisions et écarts
- Choix de conception faits seul (une ligne chacun, avec la raison).
- Écarts avec le PRD ou l'issue.
- Dépendances ajoutées : nom, version, origine, licence (A06).

## À trancher par l'utilisateur
- Comportements non fixés par le PRD que tu as choisis seul (valeur, raison, alternative), à inscrire au PRD. « aucun » si rien.

## Non fait / points bloquants
- … (ou « aucun »)
```

## Rapport du reviewer

```
## Verdict
APPROUVÉ | CHANGEMENTS DEMANDÉS (+ une phrase)

## Build
- Commande, résultat chiffré (tests, analyse statique si elle existe), copie propre utilisée : oui/non.

## Preuve
La preuve avant / après du développeur est-elle présente, vérifiable (tu as relancé la commande) et suffisante pour chaque critère ? Sinon, constat IMPORTANT.

## Constats
BLOQUANT / IMPORTANT / MINEUR : une ligne chacun, `fichier:ligne`, la catégorie OWASP entre crochets si sécurité ([A05]),
le scénario d'échec concret, et la correction attendue.

## Remarques de la revue précédente
Une ligne par point : corrigé / non corrigé / partiellement, avec la preuve (test ou ligne).

## Documents devenus faux
PRD, backlog, ADR, AGENTS.md : passages à mettre à jour, sans les modifier toi-même.
```

L'orchestrateur sauvegarde le rapport du reviewer tel quel dans `docs/reviews/<id-issue>.md` (une section par itération).
