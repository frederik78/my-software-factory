# __NOM_PROJET__

<Une phrase : ce que fait l'application et pour qui.>

Projet construit avec la Software Factory (`factory/`). Les règles de travail, la stack et l'architecture sont dans [`AGENTS.md`](AGENTS.md) (standard ouvert, source de vérité pour tout agent de code).

## Démarrage rapide
- **Prérequis** : <langage et version, outil de build, base de données…>
- **Tests** : `<commande de tests>` (voir `AGENTS.md`, section Commandes)
- **Vérification complète** : `scripts/verify-clean.sh` (tests et analyses dans une copie propre du dépôt, hors IDE ; c'est ce que lance la CI)
- **Lancer l'application** : `<commande>`
- **Après un clone** : `./factory/sync.sh` (recrée les alias de skills et les agents, générés et non versionnés)

## Où trouver quoi

| Besoin | Fichier |
|---|---|
| Règles du projet, stack, commandes, architecture | [`AGENTS.md`](AGENTS.md) |
| Besoins, priorités, statuts, décisions | [`backlog.md`](backlog.md) |
| Vocabulaire du métier | [`GLOSSARY.md`](GLOSSARY.md) |
| Décisions d'architecture (ADR) | [`docs/adr/`](docs/adr/) |
| Spécifications : comportement, contrats, critères (PRD) | [`docs/prd/`](docs/prd/) |
| Suivi des issues (statut, dépendances, commits) | [`docs/issues/`](docs/issues/) (état : `scripts/etat-issues.sh`) |
| Revues de code archivées | [`docs/reviews/`](docs/reviews/) |
| Leçons du projet | [`docs/lecons.md`](docs/lecons.md) |

## Travailler avec la Software Factory
Le cycle d'un besoin, du cadrage à la fusion :

```
cadrage (/grill-with-docs) -> ADR -> PRD (agent spec-writer) -> issues (/to-tickets)
   -> pour chaque issue : /deliver (développeur TDD <-> reviewer) -> /code-review -> fusion par vous (git merge --no-ff)
```

- Guide complet, commandes, règles et dépannage : [`factory/README.md`](factory/README.md).
- Démarrage d'un projet (garde-fous à mettre en place avant la première issue) : [`factory/DEMARRER-UN-PROJET.md`](factory/DEMARRER-UN-PROJET.md).
- Les agents ne poussent ni ne fusionnent : vous fusionnez, branche par branche, avec `git merge --no-ff`.

## Contribuer
Une branche et une PR par issue (`feat/<prd>-<nn>-<slug>`), commits atomiques au format conventionnel (`feat:`, `fix:`, `test:`, `docs:`…), TDD (un test qui échoue avant chaque code),
le nom de chaque test contient l'identifiant du critère qu'il couvre. Détail dans `AGENTS.md`.

## Version de la factory
Voir `.factory-version` (historique : [`factory/CHANGELOG.md`](factory/CHANGELOG.md)).
