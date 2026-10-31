# Issue tracker : fichiers locaux dans `docs/issues/`

Les issues et specs de ce dépôt sont des fichiers Markdown versionnés (pas de tracker externe). Convention propre à cette factory, qui remplace
le dossier `.scratch/` que les skills upstream utilisent par défaut pour un tracker local.

- La spec d'un module est son PRD : `docs/prd/<numéro>-<module>.md`.
- Les tickets sont des issues : un fichier par ticket, `docs/issues/<prd>-<nn>-<slug>.md`, au format de `docs/issues/_modele.md`
  (en-tête YAML : statut, `depend_de` = arêtes de blocage, `criteres`, branche, commits, revue).
- Quand une skill dit « publier au tracker » : crée le fichier dans `docs/issues/` (ou `docs/prd/` pour une spec).
- Quand une skill dit « récupérer le ticket » : lis le fichier ; l'utilisateur donne en général le numéro (« issue 2 »), à rapprocher du PRD en cours.
- Le statut est le champ `statut:` de l'en-tête. Commentaires et historique : section Notes, une ligne datée chacun.
- Vocabulaire de triage : `ready-for-agent` = statut `À faire` avec dépendances `Fait`.
