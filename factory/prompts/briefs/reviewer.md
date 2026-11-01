# Brief : lancer le reviewer sur une issue

Modèle de message à donner au sous-agent `code-reviewer` (il ne voit pas la conversation). Remplacer les `{{…}}`.

```
Répertoire de travail : {{chemin absolu du projet}} (fais `cd` dedans ; lecture seule ; une mutation se fait dans une copie jetable hors du projet, supprimée ensuite).
Mission : relire l'issue {{id}} « {{titre}} » ({{prd}}), itération {{n}} sur {{max}} (`scripts/config-factory.sh --max-iterations`). Lecture seule : tu ne modifies ni le code ni le dépôt.

Plage de commits : {{base}}..HEAD sur la branche {{branche}} ({{git log --oneline de la plage}}).

À lire d'abord : AGENTS.md, {{prd}}, docs/issues/{{fichier d'issue}}, les ADR {{adr concernés}}.

Preuve avant / après du développeur : relance sa commande et dis si elle est suffisante pour chaque critère. Lisibilité : duplications, code mort, structure.
Critères de l'issue : {{CA-xx, CS-xx}}. Lance scripts/criteres-sans-test.sh {{id}} et rapporte son résultat.
Remarques de la revue précédente à confirmer une par une (corrigé / non corrigé, avec la preuve) : {{liste, ou « première itération »}}
Points d'attention propres à cette issue : {{zones de risque : sécurité, concurrence, contrat externe, migration…}}
Décisions déjà prises que tu ne dois pas remettre en cause : {{liste}}

Mutations : pour chaque test de garde-fou, vérifie par mutation (délai max. `perl -e 'alarm 20; exec @ARGV' …` sous macOS) qu'il échoue proprement.
Build : scripts/verify-clean.sh (copie propre) ; rapporte les nombres. Ne lance pas le build directement dans le dépôt.
Règles : factory/prompts/code-reviewer.md et skill owasp-check ; toute vulnérabilité OWASP avérée est BLOQUANTE.

Rapport : factory/prompts/report-format.md (section reviewer), 80 lignes au plus, avec fichier:ligne et un scénario d'échec concret pour chaque constat.
```
