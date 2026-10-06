# Strategia CI

La pipeline deve verificare sia gli esercizi sia i correttori.

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

Il grader Infrastructure accetta uno `state.json` che rappresenta lo stato della VM. La CI prova fixture `pass` e `fail`. In questo modo possiamo testare sempre la logica di scoring senza dipendere dal sistema operativo.

### Livello 2 - Windows reale

Un job `windows-latest` prova a configurare realmente IIS, sito, binding, firewall, utente, cartella, ACL e Scheduled Task tramite `Apply-Solution.ps1`, quindi esegue il grader senza fixture.

Questo è preferibile a un container Windows: un container non rappresenta bene una VM Windows Server completa per feature come IIS, firewall, utenti locali, servizi e Scheduled Task.

Se in futuro i runner GitHub hosted non permettessero una delle feature richieste, il medesimo job va spostato su un runner **self-hosted Windows Server** costruito dalla stessa immagine usata per gli esami.

## Definizione di verde

La pipeline è verde solo se:

- la soluzione DEV ottiene 20/20;
- la soluzione DEV incompleta non ottiene 20/20;
- le fixture INFRA positive/negative producono il risultato atteso;
- il test reale Windows/IIS ottiene 20/20;
- il discovery `.exam-id` funziona;
- il grader delle domande assegna 0 o 5 secondo la soglia prevista.

Questa pipeline certifica il framework e il caso di riferimento. Prima della giornata d'esame resta comunque consigliato un smoke test sulla VM VirtualBox definitiva.