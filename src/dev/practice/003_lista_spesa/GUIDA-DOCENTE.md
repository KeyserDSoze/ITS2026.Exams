# Guida docente — 003 Lista della spesa

**Obiettivo:** GET/POST e primo intervento HTML/CSS. I file nella cartella [candidate](candidate/README.md) sono da completare; in [solution](solution/) c'è il codice funzionante. Non distribuire la soluzione insieme alla traccia.

## Sequenza consigliata

1. **Orientamento (10 min):** aprire `ExamApp.csproj` (`net10.0`), `Program.cs` (Minimal API), `wwwroot/index.html`, `wwwroot/app.js` e `wwwroot/style.css`. Avviare `dotnet run`, provare `GET /api/shopping-items`.
2. **Backend POST (15 min):** mostrare il percorso `CreateShoppingItem` → `Trim()` → `IsNullOrWhiteSpace()` → `Results.BadRequest` (400). Assegnare `entries.Max(e => e.Id) + 1`, aggiungere alla lista e restituire `Results.Created` (201) con l'oggetto JSON.
3. **Frontend (15 min):** leggere con `fetch('/api/shopping-items')`, convertire la risposta con `response.json()`, creare righe con `createElement`, inserire testo con `textContent`. Il form deve usare `event.preventDefault()`, body `JSON.stringify(...)` e aggiornare la lista dopo il POST.
8. **HTML/CSS (10 min):** aggiungere `#helper.helper`, la regola CSS `.helper`, stilizzare le righe con `.entry-card`.
9. **Verifica (10 min):** controllare GET 200, POST 201, POST vuoto/spazi 400, persistenza durante la sessione e form; poi gli endpoint aggiuntivi e le due risposte TXT.

## Esecuzione della soluzione

Dalla radice del repository:

```powershell
dotnet run --project ./src/dev/practice/003_lista_spesa/solution/ExamApp.csproj
```

Correzione tecnica della soluzione:

```powershell
./src/dev/practice/003_lista_spesa/grader/grade.ps1 -ExamRoot ./src/dev/practice/003_lista_spesa/solution
```

**Atteso: 20/20.** Lo scheletro candidato deve ricevere un punteggio inferiore.

## Domande finali

Chiedere allo studente di spiegare perché usa HTTP 400, 201 e gli eventuali 204/404/200; chiedere inoltre come verificherebbe errori con browser DevTools, `dotnet run` e una richiesta HTTP.
