# Guida per le lezioni preparatorie

Questa guida è destinata ai docenti che preparano gli studenti all'esame. Lo scopo è allineare la preparazione alle competenze richieste senza anticipare le tracce finali.

## Struttura generale della prova

La prova tecnica viene valutata su 20 punti. Le due risposte aperte valgono complessivamente 10 punti.

Esistono due famiglie di prova:

- Development: piccola web application .NET 8 con Minimal API e frontend HTML/CSS/JavaScript;
- Infrastructure: macchina Windows Server con IIS e configurazioni di sistema.

I casi presenti in `src/dev/sample` e `src/infra/sample` sono esempi didattici pubblici e non coincidono con gli esami finali.

## Preparazione Development

Gli studenti devono saper lavorare su un progetto già predisposto, non costruire un'applicazione complessa da zero.

Durante le lezioni è sufficiente esercitarsi su:

- leggere la struttura di un progetto .NET 8 semplice;
- capire il ruolo di `Program.cs` e `wwwroot`;
- completare piccoli TODO nel backend e nel frontend;
- creare e comprendere endpoint GET e POST;
- leggere e produrre JSON;
- validare un input e restituire un errore comprensibile;
- usare `fetch()` dal JavaScript;
- aggiornare il DOM con dati ricevuti dall'API;
- leggere un messaggio di errore e fare troubleshooting elementare;
- avviare il progetto e verificare il comportamento nel browser.

Non è necessario approfondire database, autenticazione, framework JavaScript, architetture enterprise o pattern avanzati.

### Esercitazione consigliata

Usare `src/dev/sample/candidate` come simulazione:

1. far leggere prima la traccia e la struttura del progetto;
2. far completare l'app senza mostrare la soluzione;
3. verificare GET, POST e validazione;
4. confrontare successivamente con `src/dev/sample/solution`;
5. usare il grader pubblico per mostrare come viene osservato il comportamento reale.

L'obiettivo didattico è che lo studente sappia riconoscere i componenti e completare una piccola applicazione end-to-end.

## Preparazione Infrastructure

Gli studenti devono saper configurare e verificare un semplice servizio web Windows.

Durante le lezioni è opportuno esercitarsi su:

- concetto di web server e ruolo di IIS;
- installazione/abilitazione di IIS;
- creazione o modifica di un sito IIS;
- physical path;
- binding e porte HTTP;
- verifica locale tramite browser o richiesta HTTP;
- Windows Firewall e regole inbound;
- creazione di un utente locale;
- creazione di cartelle;
- permessi NTFS/ACL di base;
- Scheduled Task semplice;
- troubleshooting progressivo: servizio, path, porta, firewall, permessi;
- differenza tra "funziona su localhost" e "è raggiungibile dalla rete".

Non serve trasformare la preparazione in un corso avanzato di amministrazione Windows Server. La prova deve restare accessibile e misurare soprattutto capacità operative e di diagnosi di base.

### Esercitazione consigliata

Usare `src/infra/sample/candidate` e una VM Windows di laboratorio:

1. predisporre il sito fittizio;
2. far configurare IIS;
3. verificare il sito localmente;
4. aggiungere firewall, utente e ACL;
5. introdurre volontariamente uno o due errori semplici e farli diagnosticare;
6. usare il grader pubblico per mostrare che ogni requisito è verificabile in modo oggettivo.

## Domande aperte

Le due domande finali sono uguali per tutti e servono a verificare comprensione e capacità di spiegazione.

Durante la preparazione gli studenti devono allenarsi a:

- descrivere in modo semplice i componenti utilizzati;
- spiegare il flusso generale di una richiesta;
- raccontare un problema incontrato, come è stato individuato e come è stato risolto;
- scrivere risposte complete e comprensibili nei file `domanda1.txt` e `domanda2.txt`.

Nel framework pubblico il controllo delle domande è volutamente semplificato e assegna 5 punti a una risposta sufficientemente lunga. Nell'esame reale la valutazione potrà essere effettuata semanticamente tramite AI usando una griglia comune.

## Cosa NON comunicare agli studenti

I docenti della preparazione non devono avere bisogno delle tracce finali. Non devono essere condivisi:

- temi o domini delle varianti reali;
- ID e token reali;
- soluzioni finali;
- grader finali;
- configurazioni esatte delle VM finali;
- porte, utenti, path o errori intenzionali delle prove finali.

La preparazione deve essere basata sulle competenze e sui casi SAMPLE pubblici.

## Criterio didattico

La prova non vuole mettere in difficoltà artificialmente gli studenti. Un candidato che ha seguito le esercitazioni e sa svolgere le operazioni fondamentali deve poter raggiungere la sufficienza. Gli elementi più completi, il troubleshooting ordinato e le configurazioni aggiuntive servono a distinguere chi merita il punteggio massimo.

## Checklist per il docente

Prima di terminare il percorso preparatorio verificare che ogni studente sappia:

- avviare e leggere una piccola applicazione .NET;
- completare una chiamata GET/POST e una semplice validazione;
- usare il frontend per chiamare l'API;
- configurare un sito IIS a partire da una cartella già pronta;
- verificare porta e firewall;
- gestire un utente/cartella/permessi di base;
- fare troubleshooting con una sequenza logica;
- scrivere due risposte tecniche comprensibili in file TXT.

Se questi punti sono coperti, la preparazione è allineata alla struttura dell'esame senza necessità di conoscere le tracce reali.