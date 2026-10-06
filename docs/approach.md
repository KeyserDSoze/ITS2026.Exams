# Approccio

Il repository contiene un **framework di riferimento** per costruire gli esami finali.

## Obiettivi

- 4 varianti Development e 2 varianti Infrastructure con difficoltà equivalente.
- Ogni pacchetto candidato contiene un marker `.exam-id` univoco.
- La correzione tecnica è automatica e vale **0-20**.
- Le due risposte aperte sono in `domanda1.txt` e `domanda2.txt` e valgono **0-10** complessivi.
- Un launcher da USB cerca il marker sul disco, identifica la prova ed esegue il grader corretto.
- Ogni grader deve avere test positivi e negativi: non basta dimostrare che la soluzione corretta passa, bisogna dimostrare che una soluzione rotta perde punti.
- La GitHub Action verde indica che framework, casi di riferimento e verificatori sono coerenti.

## Layout

```text
docs/
  approach.md
  grading.md
  ci.md
src/
  dev/sample/
    candidate/
    solution/
    grader/
    tests/
  infra/sample/
    candidate/
    solution/
    grader/
    tests/
tools/
  CORREZIONE.cmd
  grade-exam.ps1
  grade-questions.ps1
.github/workflows/ci.yml
```

## Marker

Ogni root d'esame contiene `.exam-id`, ad esempio:

```text
DEV-SAMPLE|REFERENCE-DEV-001
```

Il file potrà essere marcato Hidden + ReadOnly quando si preparano le postazioni. Non è considerato un meccanismo di sicurezza: serve per discovery e per evitare modifiche accidentali.

## Regola di progettazione

La valutazione deve osservare il **comportamento reale** quando possibile. Per Development si avvia davvero la web app e si chiamano gli endpoint. Per Infrastructure il grader legge lo stato reale di Windows/IIS; la stessa logica può ricevere fixture JSON per essere testata rapidamente in CI.