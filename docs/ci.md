# Strategia CI

La pipeline deve verificare sia gli esercizi sia i correttori, compreso il flusso reale dalla pennetta USB.

## Development

Su runner Linux con .NET 8:

1. compila la soluzione di riferimento;
2. avvia davvero la Minimal API;
3. esegue il grader;
4. verifica che la soluzione prenda 20/20;
5. esegue il grader sullo skeleton candidato e verifica che non prenda 20/20.

## Infrastructure

Sono previsti due livelli.

### Livello 1 - simulazione deterministica

Il grader Infrastructure accetta uno `state.json` che rappresenta lo stato della VM. La CI parte da una fixture 20/20 e disabilita singolarmente ogni requisito, verificando che vengano sottratti esattamente i punti previsti. In questo modo la logica di scoring è testata in maniera deterministica.

### Livello 2 - Windows reale

Un job `windows-latest` usa Windows PowerShell 5.1 per configurare realmente IIS, sito, binding, firewall, utente, cartella, ACL e Scheduled Task tramite `Apply-Solution.ps1`, quindi esegue il grader senza fixture.

Questo è preferibile a un container Windows: un container non rappresenta bene una VM Windows Server completa per feature come IIS, firewall, utenti locali, servizi e Scheduled Task.

Quando sarà disponibile l'immagine VirtualBox definitiva, è consigliato aggiungere o usare un runner **self-hosted Windows Server** basato sulla stessa immagine per il collaudo finale.

## Test end-to-end della pennetta

La CI crea un progetto Development funzionante in una posizione casuale annidata sotto `C:\`, aggiunge `.exam-id` e le due risposte, quindi avvia realmente `tools/CORREZIONE.cmd`.

Il test passa solo se:

- il launcher trova il progetto;
- il grader corretto viene selezionato;
- la parte tecnica produce 20/20;
- le domande producono 10/10;
- viene scritto il file JSON di risultato.

## Pacchetti distribuibili

Solo dopo il successo di tutti i job precedenti, il job `Build distributable packages` genera:

- `DEV-SAMPLE-CANDIDATO.zip`;
- `INFRA-SAMPLE-CANDIDATO.zip`;
- `USB-CORRETTORE.zip`.

I tre file vengono pubblicati come artifact GitHub Actions `exam-reference-packages`. In questo modo i file distribuiti derivano sempre da una build verificata.

## Definizione di verde

La pipeline è verde solo se:

- la soluzione DEV ottiene 20/20;
- la soluzione DEV incompleta non ottiene 20/20;
- ogni singolo requisito INFRA modifica il punteggio come previsto;
- il test reale Windows/IIS ottiene 20/20;
- il discovery `.exam-id` funziona;
- il vero `CORREZIONE.cmd` funziona end-to-end;
- il grader delle domande assegna 0 o 5 secondo la soglia prevista;
- gli ZIP finali vengono creati con successo.

Prima della giornata d'esame resta comunque obbligatorio uno smoke test sulla VM VirtualBox definitiva.