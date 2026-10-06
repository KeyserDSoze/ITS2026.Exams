# Confine del repository pubblico

Questo repository contiene esclusivamente il **framework di riferimento** per preparare, verificare e correggere gli esami.

## Cosa può stare nel repository pubblico

- casi fittizi `DEV-SAMPLE` e `INFRA-SAMPLE`;
- struttura dei pacchetti candidato;
- grader generici e script operativi;
- CI/CD e test automatici;
- criteri di punteggio di esempio;
- documentazione del processo;
- strumenti per report HTML e riepilogo CSV.

## Cosa non deve stare nel repository pubblico

- tracce finali assegnate ai candidati;
- nomi, temi o requisiti specifici delle varianti reali;
- token/marker delle prove finali;
- soluzioni delle prove reali;
- fixture che rivelino configurazioni o errori intenzionali delle prove reali;
- prompt finali di correzione se contengono dettagli specifici dell'esame.

Le prove finali devono essere generate e mantenute fuori dal repository pubblico, riutilizzando la stessa interfaccia prevista dai casi `SAMPLE`.

## Contratto minimo per una prova privata

Una prova privata deve mantenere:

- `.exam-id` nel formato `EXAM-ID|TOKEN`;
- `domanda1.txt` e `domanda2.txt`;
- un grader tecnico che restituisca JSON compatibile con `grade-exam.ps1`;
- punteggio tecnico massimo pari a 20;
- compatibilità con il correttore USB.

In questo modo il framework pubblico resta testabile e trasparente senza pubblicare il contenuto dell'esame reale.
