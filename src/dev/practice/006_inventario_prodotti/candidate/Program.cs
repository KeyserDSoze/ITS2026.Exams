var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Product> { new(1, "Tastiera") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/products", () => Results.Ok(entries));

app.MapPost("/api/products", (CreateProduct request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Name.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.MapDelete("/api/products/{id:int}", (int id) =>
{
    // TODO: cercare l'id; se non esiste -> HTTP 404.
    // TODO: cancellare il record e rispondere HTTP 204 (NoContent).
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Product(int Id, string Name);
record CreateProduct(string? Name);
