# Prova 007 — Film preferiti

**Tipo:** simulazione didattica pubblica fittizia (NON esame finale reale).
**Livello:** DELETE e pulsanti per riga.
**Tempo indicativo:** 60–90 minuti.
**Stack:** .NET 10, C#, Minimal API, HTML, CSS, JavaScript vanilla, JSON.

## Scenario

Devi completare una piccola web app per gestire **film preferiti**. Ricevi lo scheletro pronto, con un record di esempio e il GET funzionante. Modifica `Program.cs` e `wwwroot/app.js`, oltre agli interventi richiesti in `wwwroot/index.html` e `wwwroot/style.css`. Non usare database o framework frontend.

## Requisiti

1. `GET /api/movies` (già fornito): HTTP 200 con array JSON, campo `id`, campo `title`.
2. `POST /api/movies`: riceve `{"title":"Arrival"}`, elimina gli spazi iniziali/finali, valida i dati, assegna un ID progressivo e salva in memoria.
3. Un valore vuoto, nullo o costituito solo da spazi nel campo `title` deve produrre HTTP 400 con JSON `{"error":"..."}`.
4. Un POST valido deve restituire HTTP 201 con JSON contenente il nuovo record. Una GET successiva deve mostrarlo.
5. Nel browser, caricare e visualizzare l'elenco usando `fetch`, `response.json()`, `document.createElement` e `textContent`.
6. Il form invia il POST con `Content-Type: application/json` senza ricaricare la pagina. Mostrare conferma o errore e aggiornare la lista.

### Funzioni aggiuntive

- **DELETE `/api/movies/{id}`**: rimuovere il record, rispondere `204 No Content`; se l'ID non esiste, `404 Not Found`. Inserire un pulsante **Elimina** per riga sul frontend.

### Parte HTML e CSS

Aggiungere **in `index.html`** un paragrafo informativo con `id="helper"` e `class="helper"`. In **`style.css`** creare le regole `.helper` (messaggio evidenziato) e `.entry-card` (allineamento testo/pulsanti).

## Cosa consegnare

L'intera cartella `candidate`, compresi `domanda1.txt`, `domanda2.txt` e il marker `.exam-id` da non modificare. I dati possono andare persi al riavvio del processo.

## Verifiche manuali consigliate

- Avvia `dotnet run` e apri l'indirizzo localhost mostrato.
- Prova GET, POST valido e POST con `{"title":"   "}`.
- Controlla con DevTools → Network i codici HTTP, le richieste e le risposte.
- Prova anche DELETE con un ID valido e uno inesistente.
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
| Comportamento DELETE e stato dei dati | 3 |
| Modifiche HTML e CSS richieste | 2 |
| **Totale tecnico** | **20** |

Le due domande aperte aggiungono **10 punti**, per un totale di **30**. Il correttore pubblico valuta la loro lunghezza come test tecnico; la valutazione delle risposte in una prova formativa deve considerare la correttezza concettuale.
