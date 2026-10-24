# Esame-Seconda-Lezione-3 — Portale Progetti

**Punteggio tecnico: 20 punti.**

1. Operare su una VM Windows Server 2019, 2022 o 2025 a 64 bit, non configurata come controller di dominio.
2. Installare IIS con strumenti di gestione e scripting.
3. Creare il pool di applicazioni `ProgettiLabPool` e avviarlo.
4. Pubblicare `website\index.html` nel sito IIS `ITS-ProgettiLab`, percorso `C:\LabApps\ProgettiWeb`. Associare il sito al pool `ProgettiLabPool`, avviarlo e utilizzare `index.html` come documento predefinito.
5. Configurare HTTP su tutte le interfacce (`*`), porta `8113`, nome host vuoto. Ottenere HTTP 200 e il testo `PROGETTI ITS - ONLINE`.
6. Creare la regola firewall `ITS Progetti HTTP 8113`: abilitata, Inbound, Allow, TCP, porta locale `8113`, tutti i profili, ambito senza restrizioni. Mantenere il firewall attivo.
7. Creare e abilitare gli utenti locali `proj_editor` e `proj_reader`. `proj_reader` non deve essere amministratore.
8. Creare i gruppi locali `ProjectEditors` e `ProjectReaders`. Aggiungere direttamente `proj_editor` a `ProjectEditors` e `proj_reader` a `ProjectReaders`. `proj_reader` non deve appartenere a `ProjectEditors`.
9. Creare `C:\InfraOps\Dati`. Assegnare autorizzazioni esplicite Allow: `ProjectEditors` con Modify (Modifica), `ProjectReaders` con Read and Execute (Lettura ed esecuzione), su sottocartelle. Non assegnare autorizzazioni direttamente agli utenti e non concedere diritti aggiuntivi a `ProjectReaders`.
10. Creare e abilitare la Scheduled Task `ProgettiBackup` nella radice della libreria, eseguita come `SYSTEM` con i privilegi più elevati. Impostare un solo trigger giornaliero ogni 1 giorno alle `19:40`, ora locale della VM, con data iniziale odierna o precedente, senza scadenza, ripetizioni aggiuntive o ritardi casuali. Configurare una sola azione con i valori di `TASK-VALORI.txt`; lasciare vuoto Avvia in.
11. Eseguire il task almeno una volta. Ottenere risultato `0x0` e il file `C:\InfraOps\Dati\homepage-backup.html`, identico alla pagina pubblicata.
12. Lasciare la VM pronta per la valutazione. Non modificare `.exam-id`, `exam-config.json` o i file della cartella `grader`.
