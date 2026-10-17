var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Book> { new(1, "Il nome della rosa") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/books", () => Results.Ok(entries));

app.MapPost("/api/books", (CreateBook request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Title.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Book(int Id, string Title);
record CreateBook(string? Title);
