# Origine des skills

Copiés depuis https://github.com/mattpocock/skills (licence MIT, voir LICENSE-mattpocock-skills).
Commit : a496f5513d4a4cf889bc48e189e579f4b0bdf6aa  
Date de copie : 2026-10-29

Pour mettre à jour : recloner le repo, recopier les dossiers voulus, mettre à jour le commit ci-dessus.
Les skills peuvent être modifiés localement (ils sont copiés, pas liés) ; noter ici les écarts.

## Skills propres à la factory (non issus de mattpocock/skills)
- `owasp-check` : checklist OWASP Top 10, reprise d'un projet antérieur puis généralisée (indépendante de la stack) ; les éléments propres à Java/Spring Boot sont dans l'annexe `JAVA.md`.
- `deliver` : boucle de livraison d'une issue (développer, vérifier, relire, corriger) pilotée par l'orchestrateur ; s'appuie sur `docs/issues/`, `factory/prompts/report-format.md`, `factory/prompts/briefs/`
  et `scripts/verify-clean.sh`.

## Écarts aux skills copiés de mattpocock/skills
- `to-spec`, `implement` et `setup-matt-pocock-skills` ont été retirés (remplacés par le rôle `spec-writer`, la skill `deliver` et `factory/init-projet.sh`).
- `to-tickets` et `code-review` : deux phrases modifiées (renvoi à `./factory/init-projet.sh` et à `docs/agents/issue-tracker.md` à la place de `/setup-matt-pocock-skills`).
- Convention de tickets locaux : `docs/issues/` (et non `.scratch/`) ; glossaire `GLOSSARY.md` à la racine, comme dans `domain-modeling`.
