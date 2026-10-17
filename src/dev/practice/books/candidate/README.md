# Traccia 01 — Catalogo libri

**Simulazione didattica fittizia in .NET 10** — durata indicativa: 60-75 minuti. Parte tecnica 20 punti, due domande aperte 10.

## Scenario

Una piccola biblioteca vuole registrare i libri e mostrarli a video. Ricevi un progetto ASP.NET Core Minimal API funzionante nelle parti iniziali, e il frontend in HTML/CSS/JavaScript. Completa i TODO di `Program.cs` e `wwwroot/app.js`. Non usare database, framework frontend o pacchetti aggiuntivi.

## Requisiti obbligatori

1. `GET /api/books` (già presente) deve restituire HTTP 200 con una lista JSON di elementi che hanno `id` e `title`.
2. `POST /api/books` accetta `{"title":"Clean Code"}`, rimuove gli spazi ai bordi, inserisce l'elemento in una lista C# in memoria con ID progressivo e restituisce HTTP **201** con l'oggetto JSON creato.
3. Valori nulli, vuoti o composti di soli spazi devono essere rifiutati con HTTP **400** e un messaggio JSON `{"error":"..."}`.
4. Dopo il POST, il nuovo elemento deve essere presente nel successivo GET (persistenza in memoria, non su disco).
5. La pagina deve visualizzare la lista attraverso `fetch()` e `response.json()`.
6. Il form deve inviare POST JSON senza ricaricare la pagina, mostrare errori/conferme e aggiornare la lista.
7. Usare `textContent` per inserire nel DOM il testo fornito dall'utente.

## Test minimi prima di consegnare

- Avvia con `dotnet run` nella cartella candidata e apri l'URL indicato in console.
- Verifica il GET iniziale e poi un POST valido con HTTP 201.
- Invia `{"title":"   "}` e controlla HTTP 400.
- Conferma che GET e lista nel browser mostrino il nuovo dato senza ricaricare manualmente.
- Compila le due risposte aperte; non modificare `.exam-id`.

## Griglia di valutazione

| Verifica tecnica | Punti |
| --- | ---: |
| Applicazione avviabile | 2 |
| GET e dati JSON | 3 |
| POST corretto: HTTP 201 e oggetto JSON | 4 |
| Validazione: HTTP 400 su vuoto/spazi | 3 |
| Nuovo elemento recuperabile nel GET | 3 |
| Frontend HTML servito | 2 |
| JavaScript fetch GET/POST, JSON e form | 3 |
| **Totale** | **20** |

Due domande aperte in `domanda1.txt` e `domanda2.txt`: fino a **10 punti** aggiuntivi. Nel framework pubblico la correzione delle domande è provvisoriamente basata sulla lunghezza, non sulla qualità del contenuto.

**Esercitazione guidata:** una soluzione e una guida docente sono disponibili separatamente (non consegnarle insieme allo skeleton).
