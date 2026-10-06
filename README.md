# ITS2026.Exams

Framework di riferimento per la preparazione, verifica automatica e collaudo CI degli esami ITS 2026.

## Cosa contiene

- un caso Development fittizio completo di traccia, skeleton candidato, soluzione, grader e test;
- un caso Infrastructure fittizio Windows/IIS completo di traccia, soluzione, grader, fixture simulate e integration test reale;
- `tools/CORREZIONE.cmd` e `tools/grade-exam.ps1` per il discovery automatico tramite `.exam-id`;
- scoring temporaneo delle due risposte aperte basato sulla lunghezza del testo;
- GitHub Actions che verifica automaticamente framework, soluzioni, grader e launcher USB;
- generazione automatica degli ZIP distribuibili solo dopo il successo della CI.

## Struttura

```text
docs/
src/
  dev/sample/
  infra/sample/
tools/
tests/
.github/workflows/ci.yml
```

## Punteggi di riferimento

- parte tecnica Development o Infrastructure: **0-20**;
- due domande aperte: **0-10**;
- totale del singolo pacchetto: **0-30**.

## Principio CI

Una prova è considerata pronta quando la pipeline dimostra che:

1. la soluzione corretta prende il massimo;
2. una configurazione incompleta non prende il massimo;
3. ogni requisito Infrastructure incide sul punteggio previsto;
4. il launcher trova correttamente il progetto ed esegue davvero `CORREZIONE.cmd`;
5. i grader sono sintatticamente validi;
6. per Infrastructure viene eseguito anche un test reale su Windows/IIS;
7. vengono generati gli artifact `DEV-SAMPLE-CANDIDATO.zip`, `INFRA-SAMPLE-CANDIDATO.zip` e `USB-CORRETTORE.zip`.

La regola operativa è: **se la GitHub Action non è verde, l'esame non è pronto per la distribuzione**.

Consulta `docs/approach.md`, `docs/grading.md` e `docs/ci.md` per i dettagli.
