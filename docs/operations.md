# Flusso operativo

Il repository pubblico usa esclusivamente i casi fittizi `DEV-SAMPLE` e `INFRA-SAMPLE`. Gli stessi strumenti sono pensati per essere riutilizzati, senza modifiche strutturali, sui pacchetti reali mantenuti fuori dal repository.

## 1. Preparazione del pacchetto candidato

Dopo aver estratto un pacchetto:

```powershell
.\tools\PREPARE-EXAM.ps1 -ExamRoot C:\percorso\esame
```

Lo script:

1. verifica la presenza di `.exam-id`, `README.md`, `domanda1.txt` e `domanda2.txt`;
2. valida il formato del marker `EXAM-ID|TOKEN`;
3. rimuove eventuali blocchi Windows dai file estratti;
4. imposta `.exam-id` come Hidden + ReadOnly.

## 2. Correzione singola da USB

Dalla cartella `tools` della chiavetta:

```text
CORREZIONE.cmd
```

Il correttore cerca `.exam-id`, identifica la prova e produce nella cartella `RISULTATI`:

- un report JSON, adatto ad automazioni e archiviazione;
- un report HTML leggibile dal docente con punteggio e dettaglio PASS/FAIL.

Per test e manutenzione è possibile specificare una root:

```powershell
.\grade-exam.ps1 -SearchRoot C:\Exam -ExamId DEV-SAMPLE
```

## 3. Correzione batch

Per correggere più cartelle contenenti un singolo esame ciascuna:

```powershell
.\tools\grade-batch.ps1 -SearchRoot C:\Consegne
```

Lo script individua tutti i marker, corregge ogni pacchetto e crea:

- report JSON/HTML individuali;
- `RIEPILOGO-<timestamp>.csv` con una riga per consegna.

Il CSV contiene cartella studente, ID prova, percorso, punteggio tecnico, punteggio domande e totale.

## 4. Punteggio domande nel framework pubblico

La regola attuale è volutamente semplice e serve solo a collaudare il flusso:

- risposta con almeno 200 caratteri: 5 punti;
- risposta più corta: 0 punti.

Nel sistema finale questo componente potrà essere sostituito da una valutazione AI mantenendo invariata l'interfaccia 0-10.

## 5. CI

Una build è verde solo se passano:

- parsing di tutti gli script PowerShell;
- discovery marker e scoring domande;
- test comportamentali del caso DEV;
- test simulati e test reale IIS del caso INFRA;
- test end-to-end di `CORREZIONE.cmd`;
- generazione report JSON e HTML;
- `PREPARE-EXAM.ps1`;
- correzione batch e CSV;
- generazione e verifica degli ZIP pubblici di riferimento.
