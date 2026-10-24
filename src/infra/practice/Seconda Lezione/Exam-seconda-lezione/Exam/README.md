# Facsimile Infrastructure — Portale ITS

**Punteggio tecnico: 20 punti.**

1. Operare su una VM Windows Server 2019, 2022 o 2025 a 64 bit, non configurata come controller di dominio.
2. Installare IIS 
3. Pubblicare il file fornito `website\index.html` nel sito IIS `ITS-PortalLab`, con percorso fisico `C:\InfraLab\PortaleWeb`. Il sito deve essere avviato e utilizzare `index.html` come documento predefinito.
4. Configurare il binding HTTP su tutte le interfacce (`*`), porta `8093`. 
5. Creare la regola firewall `ITS Portal HTTP 8093`.
6. Creare e abilitare l'utente locale `portal_operator`.
7. Creare il gruppo locale `PortalEditors` e aggiungervi direttamente `portal_operator`.
8. Creare la cartella NTFS `C:\InfraData\Portale`.
9. Assegnare al gruppo `PortalEditors` un'autorizzazione esplicita Allow con permesso Modify su questa cartella, sottocartelle e file.
10. Creare e abilitare la Scheduled Task `PortaleDailyReport`  Impostare un solo trigger giornaliero ogni 1 giorno alle `18:30`, ora locale della VM, con data iniziale odierna o precedente, senza scadenza, ripetizioni aggiuntive o ritardi casuali. Configurare una sola azione, con programma e argomenti definiti in `exam-config.json`.
11. Lasciare la VM pronta per la valutazione. Non modificare `.exam-id`, `exam-config.json` o i file della cartella `grader`.