# Documentazione

Questa cartella contiene tutta la documentazione pubblica del framework d'esame.

## Da dove partire

Per chi deve fare le lezioni preparatorie:

1. leggere `instructor-preparation.md`;
2. usare `src/dev/sample/` e `src/infra/sample/` come esercitazioni pubbliche;
3. leggere `grading.md` per capire cosa viene valutato;
4. leggere `approach.md` per capire la struttura generale della prova.

Per chi deve gestire tecnicamente gli esami:

1. `operations.md` - preparazione pacchetti, marker, USB, report e batch;
2. `ci.md` - pipeline di test e regola "verde = framework pronto";
3. `private-graders.md` - come collegare grader privati senza pubblicare gli esami reali;
4. `public-boundary.md` - cosa può stare nel repository pubblico e cosa deve restare privato.

## Principio importante

Questo repository contiene solo linee guida, casi fittizi e tooling generico. Le tracce finali, le soluzioni finali, i token e i grader reali non devono essere committati qui.