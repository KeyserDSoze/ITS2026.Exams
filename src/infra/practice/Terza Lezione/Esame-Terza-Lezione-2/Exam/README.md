# Esame-Terza-Lezione-2 — Biblioteca digitale

**Parte pratica: 20 punti. Le due domande aperte sono corrette manualmente dal docente e non rientrano nel punteggio automatico.**

1. Operare su una VM Windows Server 2019, 2022 o 2025 a 64 bit, non configurata come controller di dominio.
2. Installare IIS con strumenti di gestione, scripting e funzionalità Registrazione HTTP. Avviare il servizio `W3SVC`.
3. Creare e avviare il pool di applicazioni `BibliotecaLabPool`, con runtime No Managed Code e identità `ApplicationPoolIdentity`.
4. Pubblicare `website\index.html` nel sito IIS `ITS-BibliotecaLab`, percorso `C:\LabWeb\Biblioteca`. Associare il sito a `BibliotecaLabPool`, avviarlo e utilizzare `index.html` come documento predefinito.
5. Configurare HTTP su tutte le interfacce (`*`), porta `8137`, nome host vuoto. Ottenere HTTP 200 e il testo `BIBLIOTECA ITS - ONLINE`.
6. Creare la regola firewall `ITS Biblioteca HTTP 8137`: abilitata, Inbound, Allow, TCP, porta locale `8137`, tutti i profili, ambito senza restrizioni. Mantenere il firewall attivo.
7. Abilitare la registrazione IIS con un file di log per sito. Per `ITS-BibliotecaLab` impostare formato `W3C`, directory `C:\LibraryLab\LogIIS`, destinazione File e creazione di un nuovo file ogni giorno.
8. Creare e abilitare gli utenti locali `biblio_editor` e `biblio_reader`. `biblio_reader` non deve essere amministratore.
9. Creare i gruppi locali `LibraryEditors` e `LibraryReaders`. Aggiungere direttamente `biblio_editor` a `LibraryEditors` e `biblio_reader` a `LibraryReaders`. `biblio_reader` non deve appartenere a `LibraryEditors`.
10. Creare `C:\LibraryLab\Dati`. Assegnare autorizzazioni esplicite Allow su cartella, sottocartelle e file: `LibraryEditors` con Modify (Modifica), `LibraryReaders` con Read and Execute (Lettura ed esecuzione). Non assegnare autorizzazioni direttamente agli utenti e non concedere diritti aggiuntivi a `LibraryReaders`.
11. Creare e abilitare la Scheduled Task `BibliotecaBackup` nella radice della libreria, eseguita come `SYSTEM` con i privilegi più elevati. Impostare un solo trigger giornaliero ogni 1 giorno alle `17:35`, ora locale della VM, con data iniziale odierna o precedente, senza scadenza, ripetizioni aggiuntive o ritardi casuali. Configurare una sola azione con i valori di `TASK-VALORI.txt`; lasciare vuoto Avvia in.
12. Eseguire il task almeno una volta. Ottenere risultato `0x0` e il file `C:\LibraryLab\Dati\catalogo-backup.html`, identico alla homepage pubblicata.
13. Creare `C:\LibraryLab\Catalogo` e copiarvi il file fornito `catalogo\index.html`.
14. Nel sito `ITS-BibliotecaLab` creare una directory virtuale con alias `catalogo`, collegata a `C:\LibraryLab\Catalogo`. L'indirizzo `http://localhost:8137/catalogo/` deve rispondere con HTTP 200 e mostrare `CATALOGO BIBLIOTECA - OK`.
15. Creare la pagina HTML `orari.html` in `C:\LabWeb\Biblioteca`, contenente il testo `ORARI BIBLIOTECA - OK`. La pagina deve essere raggiungibile all'indirizzo `http://localhost:8137/orari.html`, con risposta HTTP 200.
16. Rispondere alle domande nei file `domanda1.txt` e `domanda2.txt`.
17. Lasciare la VM pronta per la valutazione. Non modificare `.exam-id`, `exam-config.json` o i file della cartella `grader`.