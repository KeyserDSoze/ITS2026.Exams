# ITS2026.Exams

Framework pubblico di riferimento per la preparazione, verifica automatica e collaudo CI degli esami ITS 2026.

> Questo repository contiene **solo casi fittizi e tooling generico**. Le tracce e le soluzioni degli esami finali reali devono restare fuori dal repository pubblico.

## Cosa contiene

- un caso Development fittizio completo di traccia, skeleton candidato, soluzione, grader e test;
- un caso Infrastructure fittizio Windows/IIS completo di traccia, soluzione, grader, fixture simulate e integration test reale;
- `tools/CORREZIONE.cmd` e `tools/grade-exam.ps1` per il discovery automatico tramite `.exam-id`;
- supporto a grader privati esterni in `private-graders/<EXAM-ID>/grade.ps1`, senza pubblicare gli esami reali;
- `tools/PREPARE-EXAM.ps1` per validare il pacchetto e rendere il marker Hidden + ReadOnly;
- report automatici JSON e HTML con dettaglio PASS/FAIL;
- `tools/grade-batch.ps1` per correggere più consegne e produrre un riepilogo CSV;
- `tools/build-private-usb.ps1` per costruire offline la chiavetta con i grader reali;
- scoring temporaneo delle due risposte aperte basato sulla lunghezza del testo;
- GitHub Actions che verifica automaticamente framework, grader, IIS reale, launcher USB, report, batch e contratto dei grader privati;
- generazione automatica degli ZIP pubblici di riferimento solo dopo il successo della CI.

## Struttura

```text
docs/
src/
  dev/sample/
  infra/sample/
tools/
  CORREZIONE.cmd
  grade-exam.ps1
  grade-questions.ps1
  PREPARE-EXAM.ps1
  grade-batch.ps1
  build-private-usb.ps1
tests/
.github/workflows/ci.yml
```

Le cartelle `private-graders/` e `dist-private/` sono escluse da Git.

## Punteggi di riferimento

- parte tecnica Development o Infrastructure: **0-20**;
- due domande aperte: **0-10**;
- totale del singolo pacchetto: **0-30**.

## Output della correzione

La correzione singola produce:

- `RISULTATO-<ID>-<timestamp>.json`;
- `RISULTATO-<ID>-<timestamp>.html`.

La correzione batch produce inoltre:

- `RIEPILOGO-<timestamp>.csv`.

## Principio CI

Una prova/framework è considerata pronta quando la pipeline dimostra che:

1. la soluzione DEV di riferimento prende il massimo;
2. una configurazione DEV incompleta non prende il massimo;
3. ogni requisito Infrastructure incide sul punteggio previsto;
4. il launcher trova correttamente il progetto ed esegue davvero `CORREZIONE.cmd`;
5. `PREPARE-EXAM.ps1` prepara correttamente il marker;
6. vengono generati report JSON/HTML e riepilogo CSV;
7. il contratto dei grader privati funziona con un ID fittizio creato solo durante la CI;
8. i grader sono sintatticamente validi;
9. per Infrastructure viene eseguito anche un test reale su Windows/IIS;
10. vengono generati gli artifact pubblici `DEV-SAMPLE-CANDIDATO.zip`, `INFRA-SAMPLE-CANDIDATO.zip` e `USB-CORRETTORE.zip`.

La regola operativa è: **se la GitHub Action non è verde, il framework non è pronto per la distribuzione**.

Consulta:

- `docs/approach.md` per l'architettura;
- `docs/grading.md` per il modello di valutazione;
- `docs/ci.md` per la strategia di test;
- `docs/operations.md` per l'uso operativo;
- `docs/public-boundary.md` per cosa può e non può essere pubblicato;
- `docs/private-graders.md` per collegare gli esami reali senza committarli.
