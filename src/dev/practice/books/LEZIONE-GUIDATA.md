# Lezione guidata — Catalogo libri

Questa è la **prima esercitazione pubblica** con la soluzione, per spiegare ogni passaggio. Prima di iniziare mostrare soltanto [candidate/README.md](candidate/README.md).

## 1. Leggere e avviare il progetto (10 min)

`ExamApp.csproj` imposta `net10.0`. `Program.cs` definisce server e API, `wwwroot/index.html` contiene form e lista, `wwwroot/app.js` deve gestire le chiamate HTTP. Eseguire `dotnet run` dalla cartella `candidate`, aprire l'URL localhost scritto in console, provare `GET /api/books`. Il GET funziona; il POST incompleto restituisce HTTP 501.

## 2. Validare il POST (10 min)

Nel handler `app.MapPost` sostituire i primi TODO:

```csharp
var title = request.Title?.Trim();
if (string.IsNullOrWhiteSpace(title))
    return Results.BadRequest(new { error = "Titolo obbligatorio." });
```

Spiegare `?.`, `Trim()`, `IsNullOrWhiteSpace`, HTTP 400 e serializzazione JSON.

## 3. Salvare in memoria e restituire 201 (10 min)

Proseguire nel POST:

```csharp
var nextId = books.Count == 0 ? 1 : books.Max(b => b.Id) + 1;
var book = new Book(nextId, title);
books.Add(book);
return Results.Created($"/api/books/{book.Id}", book);
```

Provare un POST con body `{"title":"Clean Code"}`, quindi una nuova GET. Mostrare che l'ID aumenta e il dato scompare al riavvio.

## 4. Leggere i dati dal browser (10 min)

Dentro `loadBooks()`:

```javascript
const response = await fetch('/api/books');
if (!response.ok) throw new Error('Errore caricamento.');
const books = await response.json();
list.replaceChildren();
for (const book of books) {
  const li = document.createElement('li');
  li.textContent = book.title;
  list.appendChild(li);
}
```

Spiegare `fetch`, `await`, `response.json()`, DOM e sicurezza di `textContent`.

## 5. Inviare il form (10 min)

Nel listener dopo `event.preventDefault()`:

```javascript
const response = await fetch('/api/books', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ title: input.value })
});
if (!response.ok) {
  const problem = await response.json().catch(() => ({}));
  message.textContent = problem.error || 'Errore.';
  return;
}
input.value = '';
message.textContent = 'Libro aggiunto.';
await loadBooks();
```

La [soluzione completa](solution/wwwroot/app.js) aggiunge anche `try/catch` per problemi di rete. Confrontare il codice con il proprio e analizzare le richieste in DevTools → Network.

## 6. Validare e valutare (10-15 min)

Controllare POST valido (201), POST spazi (400), GET successivo, caricamento della pagina, aggiornamento automatico della lista. Rispondere a entrambe le domande. Da root:

```powershell
./src/dev/practice/books/grader/grade.ps1 -ExamRoot ./src/dev/practice/books/solution
```

La soluzione di riferimento deve ottenere 20/20. Per la seconda esercitazione distribuire soltanto [tickets/candidate](../tickets/candidate/): il lavoro sarà individuale.
