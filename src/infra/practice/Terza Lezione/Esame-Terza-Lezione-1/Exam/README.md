# Esame-Terza-Lezione-1 — Inventario IT

**Parte pratica: 20 punti. Le due domande aperte sono corrette manualmente dal docente e non rientrano nel punteggio automatico.**

1. Operare su una VM Windows Server 2019, 2022 o 2025 a 64 bit, non configurata come controller di dominio.
2. Installare IIS con strumenti di gestione, scripting e funzionalità Registrazione HTTP.
3. Creare e avviare il pool di applicazioni `InventarioLabPool`, con runtime No Managed Code e identità `ApplicationPoolIdentity`.
4. Pubblicare `website\index.html` nel sito IIS `ITS-InventarioLab`, percorso `C:\LabWeb\Inventario`. Associare il sito a `InventarioLabPool`, avviarlo e utilizzare `index.html` come documento predefinito.
5. Configurare HTTP su tutte le interfacce (`*`), porta `8121`, nome host vuoto. Ottenere HTTP 200 e il testo `INVENTARIO ITS - ONLINE`.
6. Creare la regola firewall `ITS Inventario HTTP 8121`: abilitata, Inbound, Allow, TCP, porta locale `8121`, tutti i profili, ambito senza restrizioni. Mantenere il firewall attivo.
7. Abilitare la registrazione IIS con un file di log per sito. Per `ITS-InventarioLab` impostare formato `W3C`, directory `C:\AssetLab\LogIIS`, destinazione File e creazione di un nuovo file ogni giorno.
8. Creare e abilitare gli utenti locali `asset_editor` e `asset_reader`. `asset_reader` non deve essere amministratore.
9. Creare i gruppi locali `AssetEditors` e `AssetReaders`. Aggiungere direttamente `asset_editor` a `AssetEditors` e `asset_reader` a `AssetReaders`. `asset_reader` non deve appartenere a `AssetEditors`.
10. Creare `C:\AssetLab\Dati`. Assegnare autorizzazioni esplicite Allow su cartella, sottocartelle e file: `AssetEditors` con Modify (Modifica), `AssetReaders` con Read and Execute (Lettura ed esecuzione). Non assegnare autorizzazioni direttamente agli utenti e non concedere diritti aggiuntivi a `AssetReaders`.
11. Creare e abilitare la Scheduled Task `InventarioBackup` nella radice della libreria, eseguita come `SYSTEM` con i privilegi più elevati. Impostare un solo trigger giornaliero ogni 1 giorno alle `18:10`, ora locale della VM, con data iniziale odierna o precedente, senza scadenza, ripetizioni aggiuntive o ritardi casuali. Configurare una sola azione con i valori di `TASK-VALORI.txt`; lasciare vuoto Avvia in.
12. Eseguire il task almeno una volta. Ottenere risultato `0x0` e il file `C:\AssetLab\Dati\inventario-backup.html`, identico alla homepage pubblicata.
13. Rispondere alle domande nei file `domanda1.txt` e `domanda2.txt`.
14. Lasciare la VM pronta per la valutazione. Non modificare `.exam-id`, `exam-config.json` o i file della cartella `grader`.