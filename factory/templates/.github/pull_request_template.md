> Base de la PR : `develop` (jamais `main`, réservée aux releases ; un correctif urgent `hotfix/…` vise `main`).

## Issue
`<id>` : <titre>  ·  PRD : `<docs/prd/…>`  ·  Revue archivée : `docs/reviews/<id>.md`

## Ce que fait cette PR
<Deux ou trois lignes.>

## Critères couverts
| Critère | Test |
|---|---|
| CA-xx | `<classe#méthode>` |

## Preuve avant / après
<Test qui échoue puis réussit (sorties), chiffres mesurés avant et après avec la commande, ou captures. À défaut, « Aucune » avec la raison.>

## Vérification
`scripts/verify-clean.sh` : <tests lancés, échecs, résultat>

## Décisions en attente de l'utilisateur
<Comportements que le PRD ne fixait pas, à inscrire au PRD. « Aucune » sinon.>

## Retour de revue externe (facultatif)
<Score ou synthèse et nombre d'itérations, si un service de revue de PR est utilisé.>
