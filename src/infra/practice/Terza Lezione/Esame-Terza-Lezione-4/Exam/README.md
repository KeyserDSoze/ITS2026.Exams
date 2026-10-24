# Esame-Terza-Lezione-4 — Portale Segreteria

**13 attività. Punteggio tecnico automatico: 20 punti.**

Operare su una VM Windows Server 2019, 2022 o 2025 a 64 bit, non configurata come controller di dominio.

1. Installare IIS, inclusi gli strumenti di gestione e scripting. Avviare il servizio `W3SVC`.
2. Creare e avviare il sito IIS `ITS-SegreteriaLab`, percorso `C:\LabWeb\Segreteria`. Pubblicarvi il file fornito `website\index.html` e impostare `index.html` come documento predefinito.
3. Configurare il binding HTTP su tutte le interfacce (`*`), porta `8157`, nome host vuoto.
4. Creare la regola firewall `ITS Segreteria HTTP 8157`: abilitata, Inbound, Allow, TCP, porta locale `8157`, tutti i profili, ambito senza restrizioni. Mantenere il firewall attivo.
5. Rendere raggiungibile `http://localhost:8157/` con risposta HTTP 200 e testo `SEGRETERIA ITS - ONLINE`.
6. Creare e abilitare l'utente locale `segr_operator`.
7. Creare il gruppo locale `SegreteriaOperators`.
8. Aggiungere direttamente `segr_operator` al gruppo `SegreteriaOperators`.
9. Creare la cartella `C:\SegreteriaLab\Dati`.
10. Assegnare al gruppo `SegreteriaOperators` un'autorizzazione esplicita Allow con Modify (Modifica) su questa cartella, sottocartelle e file. Non assegnare autorizzazioni direttamente all'utente e non concedere al gruppo diritti aggiuntivi oltre Modify.
11. Creare e abilitare la Scheduled Task `SegreteriaBackup`, giornaliera alle `18:00`, con le impostazioni e l'azione riportate in `TASK-VALORI.txt`.
12. Eseguire il task almeno una volta. Ottenere risultato `0x0` e il file `C:\SegreteriaLab\Dati\homepage-backup.html`, identico alla homepage pubblicata.
13. Rispondere nei file `domanda1.txt` e `domanda2.txt` e lasciare la VM pronta per la valutazione. Non modificare `.exam-id`, `exam-config.json` o i file della cartella `grader`.

Le due domande aperte sono corrette manualmente e non modificano il punteggio automatico su 20.
