# Rôles de la factory

Prompts des trois agents, sans dépendance à un outil. L'orchestrateur n'a pas de prompt ici : c'est la session principale, et son rôle est décrit dans `AGENTS.md` (section « Orchestration »). Chacun se lit tel quel dans n'importe quel agent de code (l'en-tête YAML peut être ignoré).

| Rôle | Fichier | Produit |
|---|---|---|
| Analyste | `spec-writer.md` | `docs/prd/<numéro>-<module>.md` (QUOI + sécurité), puis le découpage en issues |
| Développeur | `developer.md` | Code + tests (TDD), commits atomiques, rapport |
| Reviewer | `code-reviewer.md` | Rapport BLOQUANT / IMPORTANT / MINEUR, puis APPROUVÉ ou CHANGEMENTS DEMANDÉS |
| (commun) | `report-format.md` | Format obligatoire des rapports du développeur et du reviewer |
| (modèles) | `briefs/developer.md`, `briefs/reviewer.md` | Briefs types donnés aux sous-agents par la skill `deliver` |

La boucle d'une issue (développer, vérifier, relire, corriger) est la skill `deliver` (`factory/skills/deliver/`).
Les trois rôles chargent la skill `owasp-check` ; le développeur charge aussi `tdd`.

## En-tête YAML (source unique des agents)
Un prompt qui définit un agent commence par un en-tête :
```
---
name: developer
description: <quand l'utiliser, une phrase>
tools: Read, Write, Edit, Glob, Grep, Bash
skills: owasp-check tdd          # séparés par des espaces
model: <facultatif : modèle de l'agent ; sinon il hérite de la session>
---
```
`./factory/sync-claude.sh` (appelé par `sync.sh` pour un projet Claude Code) génère `.claude/agents/<name>.md` à partir de cet en-tête ; les valeurs de `tools:` sont des noms d'outils de Claude Code. Un prompt sans `name:` (l'orchestrateur) n'a pas d'enveloppe.
Ne jamais éditer les enveloppes générées : modifier le prompt, puis relancer `sync.sh` (ou `sync-claude.sh`).

**Relecture par un autre modèle** : un modèle relit souvent mieux le code d'un autre (duplications, code mort, structure) que le sien. Si votre outil permet de choisir le modèle d'un agent, ajoutez `model: <modèle>` à l'en-tête de `code-reviewer.md` avec un modèle différent de celui qui écrit le code, puis relancez `sync.sh`. Non imposé : sans ce champ, l'agent hérite du modèle de la session.
