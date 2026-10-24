# Esame-Seconda-Lezione-2 — Sportello IT

**Punteggio tecnico: 20 punti.**

1. Operare su una VM Windows Server 2019, 2022 o 2025 a 64 bit, non configurata come controller di dominio.
2. Creare e abilitare l'utente locale `desk_operator`.
3. Creare il gruppo locale `DeskOperators` e aggiungervi direttamente `desk_operator`.
4. Creare la cartella `C:\ServiceDesk\Dati`.
5. Assegnare al gruppo `DeskOperators` un'autorizzazione esplicita Allow con permesso Modify sulla sottocartella. Non assegnare autorizzazioni direttamente all'utente.
6. Creare e abilitare la Scheduled Task `ServiceDeskBackup` nella radice della libreria, eseguita come `SYSTEM` con i privilegi più elevati. Impostare un solo trigger giornaliero, ogni 1 giorno alle `17:15`, ora locale della VM, con data iniziale odierna o precedente, senza scadenza, ripetizioni aggiuntive o ritardi casuali. L'attività deve copiare la homepage in `C:\ServiceDesk\Dati\homepage-backup.html`. Configurare una sola azione, con programma e argomenti definiti in `TASK-VALORI.txt`; lasciare vuoto il campo Avvia in.
7. Installare IIS, inclusi gli strumenti di gestione e scripting. Il servizio `W3SVC` deve essere avviato.
8. Pubblicare il file fornito in `website\index.html` nel sito IIS `ITS-ServiceDesk`, con percorso fisico `C:\LabWeb\ServiceDesk`. Il sito deve essere avviato e utilizzare `index.html` come documento predefinito.
9. Configurare il binding HTTP su tutte le interfacce (`*`), porta `8107`, nome host vuoto. Il sito deve rispondere con HTTP 200 e mostrare `SERVICE DESK ITS - OK`.
10. Creare e abilitare la regola firewall `ITS ServiceDesk HTTP 8107`: Inbound, Allow, TCP, porta locale `8107`, tutti i profili, ambito senza restrizioni. Mantenere il firewall attivo.
11. Lasciare la VM pronta per la valutazione. Non modificare `.exam-id`, `exam-config.json` o i file della cartella `grader`.