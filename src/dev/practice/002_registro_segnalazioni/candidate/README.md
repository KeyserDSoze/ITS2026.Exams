# Prova 002 — Registro segnalazioni

**Tipo:** simulazione didattica pubblica fittizia (NON esame finale reale).
**Livello:** GET, POST e messaggi frontend.
**Tempo indicativo:** 60–90 minuti.
**Stack:** .NET 10, C#, Minimal API, HTML, CSS, JavaScript vanilla, JSON.

## Scenario

Devi completare una piccola web app per gestire **registro segnalazioni**. Ricevi lo scheletro pronto, con un record di esempio e il GET funzionante. Modifica `Program.cs` e `wwwroot/app.js`. Non usare database o framework frontend.

## Requisiti

1. `GET /api/tickets` (già fornito): HTTP 200 con array JSON, campo `id`, campo `description`.
2. `POST /api/tickets`: riceve `{"description":"Monitor spento"}`, elimina gli spazi iniziali/finali, valida i dati, assegna un ID progressivo e salva in memoria.
3. Un valore vuoto, nullo o costituito solo da spazi nel campo `description` deve produrre HTTP 400 con JSON `{"error":"..."}`.
4. Un POST valido deve restituire HTTP 201 con JSON contenente il nuovo record. Una GET successiva deve mostrarlo.
5. Nel browser, caricare e visualizzare l'elenco usando `fetch`, `response.json()`, `document.createElement` e `textContent`.
6. Il form invia il POST con `Content-Type: application/json` senza ricaricare la pagina. Mostrare conferma o errore e aggiornare la lista.

## Cosa consegnare

L'intera cartella `candidate`, compresi `domanda1.txt`, `domanda2.txt` e il marker `.exam-id` da non modificare. I dati possono andare persi al riavvio del processo.

## Verifiche manuali consigliate

- Avvia `dotnet run` e apri l'indirizzo localhost mostrato.
- Prova GET, POST valido e POST con `{"description":"   "}`.
- Controlla con DevTools → Network i codici HTTP, le richieste e le risposte.
- Verifica il form, la lista e lo stile dal browser.

## Valutazione

| Controllo | Punti |
| --- | ---: |
| Applicazione .NET 10 avviabile | 2 |
| GET con array JSON valido | 2 |
| POST valido: HTTP 201 e JSON con ID | 3 |
| Validazione con HTTP 400 (stringa vuota e spazi) | 2 |
| Oggetto inserito visibile nel GET successivo | 2 |
| Pagina HTML servita dal backend | 2 |
| JavaScript `fetch` GET e POST JSON | 2 |
| Lista renderizzata in modo sicuro dal JavaScript | 3 |
| File HTML/CSS presenti | 2 |
| **Totale tecnico** | **20** |

Le due domande aperte aggiungono **10 punti**, per un totale di **30**. Il correttore pubblico valuta la loro lunghezza come test tecnico; la valutazione delle risposte in una prova formativa deve considerare la correttezza concettuale.
