# Esame-Terza-Lezione-3 — Portale Formazione

**Parte pratica: 20 punti. Le due domande aperte sono corrette manualmente dal docente e non rientrano nel punteggio automatico.**

1. Operare su una VM Windows Server 2019, 2022 o 2025 a 64 bit, non configurata come controller di dominio.
2. Installare IIS con strumenti di gestione, scripting e funzionalità Registrazione HTTP. Avviare il servizio `W3SVC`.
3. Creare e avviare il pool di applicazioni `FormazioneLabPool`, con runtime No Managed Code e identità `ApplicationPoolIdentity`.
4. Pubblicare `website\index.html` nel sito IIS `ITS-FormazioneLab`, percorso `C:\LabWeb\Formazione`. Associare il sito a `FormazioneLabPool`, avviarlo e utilizzare `index.html` come documento predefinito.
5. Configurare HTTP su tutte le interfacce (`*`), porta `8149`, nome host vuoto. Ottenere HTTP 200 e il testo `FORMAZIONE ITS - ONLINE` all'indirizzo `http://localhost:8149/`.
6. Creare la regola firewall `ITS Formazione HTTP 8149`: abilitata, Inbound, Allow, TCP, porta locale `8149`, tutti i profili, ambito senza restrizioni. Mantenere il firewall attivo.
7. Abilitare i log IIS per sito. Per `ITS-FormazioneLab` impostare formato `W3C`, directory `C:\TrainingLab\LogIIS`, destinazione File e nuovo file ogni giorno.
8. Creare e abilitare gli utenti locali `train_editor` e `train_reader`. `train_reader` non deve essere amministratore.
9. Creare i gruppi locali `TrainingEditors` e `TrainingReaders`. Aggiungere direttamente `train_editor` a `TrainingEditors` e `train_reader` a `TrainingReaders`. `train_reader` non deve appartenere a `TrainingEditors`.
10. Creare `C:\TrainingLab\Dati`. Assegnare autorizzazioni esplicite Allow su cartella, sottocartelle e file: `TrainingEditors` con Modify (Modifica), `TrainingReaders` con Read and Execute (Lettura ed esecuzione). In questa cartella non assegnare autorizzazioni direttamente ai due utenti e non concedere diritti aggiuntivi ai gruppi.
11. Creare `C:\TrainingLab\Personale`. Assegnare direttamente a `train_editor` un'autorizzazione esplicita Allow con Modify (Modifica) su cartella, sottocartelle e file, senza diritti aggiuntivi per l'utente.
12. Creare `C:\TrainingLab\Materiali` e copiarvi il file fornito `materiali\index.html`.
13. Nel sito `ITS-FormazioneLab` creare la directory virtuale con alias `materiali`, collegata a `C:\TrainingLab\Materiali`. Ottenere HTTP 200 e il testo `MATERIALI FORMAZIONE - OK` all'indirizzo `http://localhost:8149/materiali/`.
14. Creare `contatti.html` in `C:\LabWeb\Formazione`, contenente il testo `CONTATTI FORMAZIONE - OK`. Ottenere HTTP 200 all'indirizzo `http://localhost:8149/contatti.html`.
15. Creare e abilitare la Scheduled Task `FormazioneBackup`: giornaliera alle `18:20`, copia della homepage in `C:\TrainingLab\Dati\homepage-backup.html`.
16. Creare e abilitare la Scheduled Task `FormazioneReport`: giornaliera alle `18:35`, generazione di `C:\TrainingLab\Dati\report-giornaliero.txt` con il testo `FORMAZIONE REPORT OK`.
17. Per entrambi i task usare la radice della libreria, account `SYSTEM`, privilegi più elevati, un solo trigger ogni 1 giorno, data iniziale odierna o precedente, nessuna scadenza, ripetizione aggiuntiva o ritardo casuale. Configurare una sola azione con i rispettivi valori di `TASK-VALORI.txt`; lasciare vuoto Avvia in.
18. Eseguire entrambi i task almeno una volta. Ottenere risultato `0x0`, il backup identico alla homepage e il report con il testo richiesto.
19. Rispondere nei file `domanda1.txt` e `domanda2.txt`.
20. Lasciare la VM pronta per la valutazione. Non modificare `.exam-id`, `exam-config.json` o i file della cartella `grader`.
