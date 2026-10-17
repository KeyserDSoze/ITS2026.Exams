var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Movie> { new(1, "Interstellar") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/movies", () => Results.Ok(entries));

app.MapPost("/api/movies", (CreateMovie request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Title.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.MapDelete("/api/movies/{id:int}", (int id) =>
{
    // TODO: cercare l'id; se non esiste -> HTTP 404.
    // TODO: cancellare il record e rispondere HTTP 204 (NoContent).
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Movie(int Id, string Title);
record CreateMovie(string? Title);
