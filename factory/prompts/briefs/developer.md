# Brief : lancer le développeur sur une issue

Modèle de message à donner au sous-agent `developer` (il ne voit pas la conversation : le brief doit se suffire à lui-même). Remplacer les `{{…}}`.
Ne pas résumer l'issue de mémoire : coller ses champs.

```
Répertoire de travail : {{chemin absolu du projet}} (fais `cd` dedans ; tous les chemins ci-dessous y sont relatifs ; n'écris rien en dehors).
Mission : livrer l'issue {{id}} « {{titre}} » de {{prd}}.

Branche : {{branche}} (déjà créée et active ; ne change pas de branche). Base : {{base}}.

À lire d'abord : AGENTS.md, {{prd}}, docs/issues/{{fichier d'issue}}, les ADR {{adr concernés}}, et le code de {{zones existantes}}.

Objectif : {{objectif de l'issue}}
Dans le périmètre : {{périmètre}}   Hors périmètre : {{hors périmètre, avec l'issue qui s'en charge}}
Critères à couvrir : {{CA-xx, CS-xx, avec leur texte exact du PRD}}
Preuve attendue (section « Preuve attendue » de l'issue) : {{test qui échoue puis réussit | chiffres avant / après avec la commande | captures}}

Décisions déjà prises (ne les remets pas en cause) : {{décisions de l'utilisateur et de l'orchestrateur}}
Points ouverts à traiter ou à ne pas traiter : {{remarques de revue précédentes, mineurs reportés}}
Comportements non fixés par le PRD : choisis le plus sûr et cohérent avec l'existant, et liste-le dans « À trancher par l'utilisateur » de ton rapport.

Règles : factory/prompts/developer.md (TDD strict, RED constaté, nom des tests avec l'identifiant du critère, commits atomiques conventionnels, pas de push, pas
de fusion). Vérification finale : scripts/verify-clean.sh (jamais le build directement dans le dépôt). Aucune dépendance sans me la signaler avec sa licence.

Rapport : factory/prompts/report-format.md, complet, 60 lignes au plus. Un rapport vide ou sans preuve sera refusé et la mission relancée.
```
