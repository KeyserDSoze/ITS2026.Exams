# Guida docente — 002 Registro segnalazioni

**Obiettivo:** GET, POST e messaggi frontend. I file nella cartella [candidate](candidate/README.md) sono da completare; in [solution](solution/) c'è il codice funzionante. Non distribuire la soluzione insieme alla traccia.

## Sequenza consigliata

1. **Orientamento (10 min):** aprire `ExamApp.csproj` (`net10.0`), `Program.cs` (Minimal API), `wwwroot/index.html`, `wwwroot/app.js` e `wwwroot/style.css`. Avviare `dotnet run`, provare `GET /api/tickets`.
2. **Backend POST (15 min):** mostrare il percorso `CreateTicket` → `Trim()` → `IsNullOrWhiteSpace()` → `Results.BadRequest` (400). Assegnare `entries.Max(e => e.Id) + 1`, aggiungere alla lista e restituire `Results.Created` (201) con l'oggetto JSON.
3. **Frontend (15 min):** leggere con `fetch('/api/tickets')`, convertire la risposta con `response.json()`, creare righe con `createElement`, inserire testo con `textContent`. Il form deve usare `event.preventDefault()`, body `JSON.stringify(...)` e aggiornare la lista dopo il POST.
9. **Verifica (10 min):** controllare GET 200, POST 201, POST vuoto/spazi 400, persistenza durante la sessione e form; poi gli endpoint aggiuntivi e le due risposte TXT.

## Esecuzione della soluzione

Dalla radice del repository:

```powershell
dotnet run --project ./src/dev/practice/002_registro_segnalazioni/solution/ExamApp.csproj
```

Correzione tecnica della soluzione:

```powershell
./src/dev/practice/002_registro_segnalazioni/grader/grade.ps1 -ExamRoot ./src/dev/practice/002_registro_segnalazioni/solution
```

**Atteso: 20/20.** Lo scheletro candidato deve ricevere un punteggio inferiore.

## Domande finali

Chiedere allo studente di spiegare perché usa HTTP 400, 201 e gli eventuali 204/404/200; chiedere inoltre come verificherebbe errori con browser DevTools, `dotnet run` e una richiesta HTTP.
