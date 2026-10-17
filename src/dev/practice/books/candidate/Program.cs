var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.UseDefaultFiles();
app.UseStaticFiles();
var books = new List<Book> { new(1, "Il nome della rosa") };

app.MapGet("/api/books", () => Results.Ok(books));
app.MapPost("/api/books", (CreateBook request) =>
{
    // TODO 1: rimuovere gli spazi con Trim e validare request.Title.
    // TODO 2: titolo vuoto o soli spazi => HTTP 400 con JSON di errore.
    // TODO 3: aggiungere il libro con un ID progressivo.
    // TODO 4: rispondere HTTP 201 con JSON del libro creato.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});
app.Run();
record Book(int Id, string Title);
record CreateBook(string? Title);
