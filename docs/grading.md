# Modello di valutazione

Ogni esame tecnico vale **20 punti**. Le domande aperte valgono **10 punti** complessivi.

## Development

Il grader di riferimento assegna punti a:

- applicazione avviabile;
- GET funzionante;
- POST valido;
- validazione input non valido;
- persistenza in memoria dell'elemento inserito;
- frontend presente e servito;
- JavaScript che usa le API richieste.

Totale: 20 punti.

## Infrastructure

Il grader di riferimento controlla:

- IIS installato;
- sito con nome corretto;
- physical path corretto;
- binding/porta corretti;
- sito raggiungibile;
- firewall;
- utente locale;
- cartella dati;
- ACL richieste;
- Scheduled Task.

Totale: 20 punti.

## Domande aperte - versione iniziale

Per il framework di riferimento non viene ancora valutata semanticamente la risposta. La regola temporanea è volutamente semplice:

- `domanda1.txt`: almeno 200 caratteri non vuoti = 5 punti, altrimenti 0;
- `domanda2.txt`: almeno 200 caratteri non vuoti = 5 punti, altrimenti 0.

In produzione questo modulo sarà sostituibile con la valutazione AI concordata, mantenendo invariato il contratto 0-10.

## Test dei grader

Ogni grader deve essere testato almeno con:

1. soluzione corretta -> punteggio pieno;
2. soluzione incompleta/errata -> punteggio inferiore al massimo;
3. input o configurazione mancante -> errore leggibile o punteggio coerente, mai falso positivo.